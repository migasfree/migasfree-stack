#!/bin/bash

_FILE_LOCK=/var/lib/migasfree-backend/conf/.init-server
_SETTINGS=/var/lib/migasfree-backend/conf/settings.py


function set_TZ {
    send_message "setting the time zone"
    if [ -z "$TZ" ]; then
      TZ="Europe/Madrid"
    fi
    # /etc/timezone for TZ setting
    ln -fs /usr/share/zoneinfo/$TZ /etc/localtime || :
}


function update_ca_certificates {
    send_message "updating the certificates"
    update-ca-certificates
}


function get_migasfree_setting()
{
    echo -n $(DJANGO_SETTINGS_MODULE=migasfree.settings.production python3 -c "from django.conf import settings; print(settings.$1)")
}


function send_message {
    curl -d "text=$1;container=$(hostname);service=$SERVICE;node=$NODE" -X POST http://loadbalancer:8001/services/message &> /dev/null
}


function reload_loadbalancer {
    curl -d "" -X POST http://loadbalancer:8001/services/reconfigure &> /dev/null
}


# owner resource user
function owner()
{
    if [ ! -f "$1" -a ! -d "$1" ]
    then
        mkdir -p "$1"
    fi

    _OWNER=$(stat -c %U "$1" 2>/dev/null)
    if [ "$_OWNER" != "$2" ]
    then
        chown -R $2:$2 "$1"
    fi
}

function get_settings
{
    send_message "reading settings"
    if ! [ -f $_SETTINGS ]
    then
        echo "
def get_secret_pass():
    password = ''
    with open('/run/secret/password_database','r') as f:
        password = f.read()
    return password

DATABASES['default']['HOST'] = os.getenv('POSTGRES_HOST', 'database')
DATABASES['default']['PORT'] = int(os.getenv('POSTGRES_PORT', '5432'))
DATABASES['default']['NAME'] = os.getenv('POSTGRES_DB', 'migasfree')
DATABASES['default']['USER'] = os.getenv('POSTGRES_USER', 'migasfree')
DATABASES['default']['PASSWORD'] = get_secret_pass()

# NECESSARY FOR SWAGGER AND REST-FRAMEWORK
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')


" > $_SETTINGS
    fi

    _HOST=$(get_migasfree_setting "DATABASES['default']['HOST']")
    _PORT=$(get_migasfree_setting "DATABASES['default']['PORT']")
    _USER=$(get_migasfree_setting "DATABASES['default']['USER']")
    _NAME=$(get_migasfree_setting "DATABASES['default']['NAME']")
    _PASSWORD=$(get_migasfree_setting "DATABASES['default']['PASSWORD']")

}

function set_permissions()
{
    send_message "setting permissions"
    local _USER=www-data

    # owner for repositories
    _PUBLIC_PATH=$(get_migasfree_setting MIGASFREE_PUBLIC_DIR)    #  '/var/lib/migasfree-backend/public'
    owner $_PUBLIC_PATH $_USER

    # owner for keys
    _KEYS_PATH=$(get_migasfree_setting MIGASFREE_KEYS_DIR)
    owner $_KEYS_PATH $_USER
    chmod 700 $_KEYS_PATH


}

function run_as_www-data
{
    su  www-data -s /bin/bash -c "$1"
}

function create_keys
{
    send_message "checking keys"
    run_as_www-data 'export GPG_TTY=$(tty);DJANGO_SETTINGS_MODULE=migasfree.settings.production python3 -c "import django; django.setup(); from migasfree.secure import create_server_keys; create_server_keys()"'
}

function is_db_empty()
{
    send_message "checking database is empty"
    #_RET=$(PGPASSWORD=$_PASSWORD psql -h $_HOST -p $_PORT -U $_USER $_NAME -tAc "SELECT count(id) from auth_user;")
    _RET=$(PGPASSWORD=$_PASSWORD psql -h $_HOST -p $_PORT -U $_USER $_NAME -tAc "SELECT count(*) FROM information_schema.tables WHERE table_type='BASE TABLE' and table_schema='$_NAME ' ; ")   
    test $_RET -eq "$(echo "0")"
}


function is_db_exists()
{
    send_message "checking is exists database "
    PGPASSWORD=$_PASSWORD psql -h $_HOST -p $_PORT -U $_USER -tAc "SELECT 1 from pg_database WHERE datname='$_NAME'" 2>/dev/null | grep -q 1
    test $? -eq 0
}


function is_user_exists()
{
    send_message "checking user exists in database"
    PGPASSWORD=$_PASSWORD psql -h $_HOST -p $_PORT -U $_USER -tAc "SELECT 1 FROM pg_roles WHERE rolname='$_USER';" | grep -q 1
    test $? -eq 0
}


function create_user()
{
    send_message "creating user in database"
    PGPASSWORD=$_PASSWORD psql -h $_HOST -p $_PORT -U $_USER -tAc "CREATE USER $_USER WITH CREATEDB ENCRYPTED PASSWORD '$_PASSWORD';"
    test $? -eq 0
}


function create_database()
{
    send_message "creating database"
    PGPASSWORD=$_PASSWORD psql -h $_HOST -p $_PORT -U $_USER -tAc "CREATE DATABASE $_NAME WITH OWNER = $_USER ENCODING='UTF8';"
    test $? -eq 0
}


function wait_postgresql {
    send_message "waiting database"
    wait-for-it -h $_HOST -p $_PORT
}


function migrate {
    send_message "running database migrations"
        su -c "DJANGO_SETTINGS_MODULE=migasfree.settings.production django-admin migrate auth" www-data
    if [ "$1" = "fake-initial" ]
    then
        su -c "DJANGO_SETTINGS_MODULE=migasfree.settings.production django-admin migrate --fake-inicitial" www-data
    else
        su -c "DJANGO_SETTINGS_MODULE=migasfree.settings.production django-admin migrate" www-data
    fi
}


function apply_fixtures
{
    send_message "applying fixtures to database"
    python3 - << EOF
import django
django.setup()
from migasfree.fixtures import create_initial_data, sequence_reset
create_initial_data()
sequence_reset()
EOF
}


function lock_server {
    send_message "expect other backend to start"
    while [ -f  $_FILE_LOCK ] ; do
        _CONTAINER_LOCKING=$(cat $_FILE_LOCK)
        wait-for-it -h $_CONTAINER_LOCKING -p 8080
        if ! [ $? = 0 ]
        then
            break
        fi
        sleep 1
    done
    echo $(hostname) > $_FILE_LOCK
}

function unlock_server {
    rm $_FILE_LOCK
}


function migasfree_init
{

    set_permissions

    create_keys

    wait_postgresql

    lock_server

    is_db_exists || create_database

    is_user_exists || create_user

    #is_db_empty && echo yes | cat - | migrate "fake-initial" || (
    #    su -c "django-admin showmigrations | grep '\[ \]' " www-data >/dev/null
    #    if [ $? = 0 ] # we have pending migrations
    #    then
    #        migrate 
    #        apply_fixtures
    #    fi
    #)

    unlock_server

}


# START
# =====

set_TZ

send_message "starting $SERVICE"

get_settings

update_ca_certificates

migasfree_init

reload_loadbalancer
send_message ""

echo "

        migasfree BACKEND
        $(gunicorn -v)
        Container: $HOSTNAME
        Time zome: $TZ  $(date)
        Processes: $(nproc)
               -------O--
              \\         o \\
               \\           \\
                \\           \\
                  -----------


"


# CELERY BEAT
# ===========
DJANGO_SETTINGS_MODULE=migasfree.settings.production celery beat -A migasfree --logfile=/var/tmp/celery-beat.log --uid=890 --pidfile /var/tmp/celery.pid --schedule /var/tmp/celerybeat-schedule &

# CELERY WORKER
# ==============
DJANGO_SETTINGS_MODULE=migasfree.settings.production celery --without-gossip --concurrency=10 --logfile=/dev/null --app=migasfree.celery.app worker -Q default -B --uid 890 &


#touch /tmp/migasfree-celery.log
#chown $_UID:$_GID /tmp/migasfree-celery.log


gunicorn --forwarded-allow-ips="loadbalancer,pms-apt,frontend,public,backend" \
        --user=$_UID --group=$_GID \
         --log-level=info  --error-logfile=- --access-logfile=- \
         --timeout=3600 \
         --worker-tmp-dir=/dev/shm \
         --workers=$((2* $(nproc) + 1 ))  --worker-connections=1000 \
         --bind=0.0.0.0:8080 \
         migasfree.asgi:application -k uvicorn.workers.UvicornWorker