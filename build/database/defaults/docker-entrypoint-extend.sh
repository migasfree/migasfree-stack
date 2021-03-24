#!/bin/bash
set -e


function set_TZ {
    if [ -z "$TZ" ]; then
      TZ="Europe/Madrid"
    fi
    # /etc/timezone for TZ setting
    ln -fs /usr/share/zoneinfo/$TZ /etc/localtime || :
}

function cron_init
{
    if [ -z "$POSTGRES_CRON" ]; then
        POSTGRES_CRON="0 0 * * *"
    fi
    CRON=$(echo "$POSTGRES_CRON" |tr -d "'") # remove single quote
    echo "$CRON /usr/bin/backup" > /tmp/cron
    crontab /tmp/cron
    rm /tmp/cron

    #start daemond crond
    crond
}


if ! [ -f /etc/migasfree-server/settings.py ] ; then
    cat <<EOF>> /etc/migasfree-server/settings.py
DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.postgresql_psycopg2',
            'NAME': '$POSTGRES_DB',
            'USER': '$POSTGRES_USER',
            'PASSWORD': '',
            'HOST': '$POSTGRES_HOST',
            'PORT': '$POSTGRES_PORT',
        }
    }
EOF
fi



#set_TZ
cron_init

echo "

        migasfree DATABASE
        $(postgres -V)
        Container: $HOSTNAME
        Time zome: $TZ  $(date)
        Processes: $(nproc)
               -------O--
              \\         o \\
               \\           \\
                \\           \\
                  -----------


"

# Run docker-entrypoint.sh (from postgres image)
/usr/local/bin/docker-entrypoint.sh postgres
