#!/bin/bash

_FILE_LOCK=/etc/migasfree-server/.init-server

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
    curl -d "text=$1" -X POST http://loadbalancer:8001/maintenance/message &> /dev/null
}


function reload_loadbalancer {
    curl -d "" -X POST http://loadbalancer:8001/maintenance/reconfigure &> /dev/null
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
    if ! [ -f /etc/migasfree-server/settings.py ]
    then
        echo "
def get_secret_pass():
    password = ''
    with open('/run/secret/password','r') as f:
        password = f.read()
    return password

DATABASES['default']['HOST'] = os.getenv('POSTGRES_HOST', 'database')
DATABASES['default']['PORT'] = int(os.getenv('POSTGRES_PORT', '5432'))
DATABASES['default']['NAME'] = os.getenv('POSTGRES_DB', 'migasfree')
DATABASES['default']['USER'] = os.getenv('POSTGRES_USER', 'migasfree')
DATABASES['default']['PASSWORD'] = get_secret_pass()
" > /etc/migasfree-server/settings.py
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
    _USER=www-data

    # owner for repositories
 #   _REPO_PATH=$(get_migasfree_setting MIGASFREE_PUBLIC_DIR)
 #   owner $_REPO_PATH $_USER

    # owner for keys
    _KEYS_PATH=$(get_migasfree_setting MIGASFREE_KEYS_DIR)
    owner $_KEYS_PATH $_USER
    chmod 700 $_KEYS_PATH

    # owner for migasfree.log
    _TMP_DIR=$(get_migasfree_setting MIGASFREE_TMP_DIR)
    touch "$_TMP_DIR/migasfree.log"
    owner "$_TMP_DIR/migasfree.log" $_USER

}

function run_as_www-data
{
    su - www-data -s /bin/bash -c "$1"
}

function create_keys
{
    send_message "creating keys"
    run_as_www-data 'export GPG_TTY=$(tty);DJANGO_SETTINGS_MODULE=migasfree.settings.production python3 -c "import django; django.setup(); from migasfree.server.secure import create_server_keys; create_server_keys()"'
}

function is_db_empty()
{
    send_message "cheching is empty database"
    _RET=$(PGPASSWORD=$_PASSWORD psql -h $_HOST -p $_PORT -U $_USER $_NAME -tAc "SELECT count(id) from auth_user;")
    test $_RET -eq "$(echo "0")"
}


function is_db_exists()
{
    send_message "cheching is exists database "
    PGPASSWORD=$_PASSWORD psql -h $_HOST -p $_PORT -U $_USER -tAc "SELECT 1 from pg_database WHERE datname='$_NAME'" 2>/dev/null | grep -q 1
    test $? -eq 0
}


function is_user_exists()
{
    send_message "cheching user in database"
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


function set_circus_numprocesses() {
    sed -ri "s/^#?(numprocesses\s*=\s*)\S+/\1$(nproc)/" "/etc/circus/circusd.ini"
}


function wait_postgresql {
    send_message "waiting postgresql"
    wait-for-it -h $_HOST -p $_PORT
}


function migrate {
    send_message "running database migrations"
    if [ "$1" = "fake-initial" ]
    then
        django-admin migrate --fake-initial
    else
        django-admin migrate
    fi
}


function apply_fixtures
{
    send_message "applying fixtures"
    python3 - << EOF
import django
django.setup()
from migasfree.server.fixtures import create_initial_data, sequence_reset
create_initial_data()
sequence_reset()
EOF
}


function lock_server {
    send_message "expect other servers to start"
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

    rm /tmp/migasfree.log || :

    is_user_exists || create_user

    is_db_empty && echo yes | cat - | migrate "fake-initial" || (

        django-admin showmigrations | grep "\[ \]" >/dev/null
        if [ $? = 0 ] # we have pending migrations
        then
            migrate ""
            apply_fixtures
        fi

    )

    unlock_server

}


# START
# =====

set_TZ

get_settings

update_ca_certificates

migasfree_init

echo "


        Container: $HOSTNAME
        Time zome: $TZ  $(date)
        Processes: $(nproc)
               -------O--
              \\         o \\
               \\           \\
                \\           \\
                  -----------


"

send_message ""

reload_loadbalancer

#cd /usr/local/lib/python2.7/dist-packages

rm /tmp/migasfree.log || :

gunicorn --user=$_UID --group=$_GID \
         --log-level=info  --error-logfile=- --access-logfile=- \
         --timeout=3600 \
         --worker-tmp-dir=/dev/shm \
         --workers=$((2* $(nproc) + 1 ))  --worker-connections=1000 \
         --bind=0.0.0.0:8080 \
         migasfree.wsgi