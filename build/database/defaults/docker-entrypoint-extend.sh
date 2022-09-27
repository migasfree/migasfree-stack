#!/bin/bash

set -e

function capture_message {
    local _LAST="database system is ready to accept connections"

    if [[ "$1" == *"$_LAST"* ]]
    then
        send_message ""
    else
        send_message "$1"
    fi
}

function send_message {
    local _POINT="http://loadbalancer:8001/services/message"
    local _DATA="{ \"text\":\"$1\", \"service\":\"$SERVICE\" ,\"node\":\"$NODE\",\"container\":\"$HOSTNAME\" }"

    until [ $(curl -s -o /dev/null  -w '%{http_code}' -d "$_DATA" -H "Content-Type: application/json" -X POST $_POINT) = "200" ]
    do
       sleep 2
    done
}

function set_TZ {
    if [ -z "$TZ" ]
    then
        TZ="Europe/Madrid"
    fi
    # /etc/timezone for TZ setting
    ln -fs /usr/share/zoneinfo/$TZ /etc/localtime || :
}

function cron_init {
    if [ -z "$POSTGRES_CRON" ]
    then
        POSTGRES_CRON="0 0 * * *"
    fi
    echo "$(echo "$POSTGRES_CRON" | tr -d '"') /usr/bin/backup" > /tmp/cron
    crontab /tmp/cron
    rm /tmp/cron

    crond -l 2 -f > /dev/stdout 2> /dev/stderr &
}

if ! [ -f /etc/migasfree-server/settings.py ]
then
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

send_message "starting ${SERVICE:(${#STACK})+1}"
#set_TZ
cron_init

echo "


                   ●                          ●●
                                             ●
         ●●● ●●    ●    ●●     ●●●     ●●●  ●●●●  ●●●  ●●●    ●●●
        ●   ●  ●   ●   ●  ●       ●   ●      ●   ●    ●   ●  ●   ●
        ●   ●  ●   ●   ●  ●    ●●●●    ●●    ●   ●    ●●●●   ●●●●
        ●   ●  ●   ●   ●  ●   ●   ●      ●   ●   ●    ●      ●
        ●   ●  ●   ●    ●●●    ●●●    ●●●    ●   ●     ●●●    ●●●
                          ●
                        ●●

        migasfree DATABASE
        $(postgres -V)
        Container: $HOSTNAME
        Time zome: $TZ $(date)
        Processes: $(nproc)

"

# Run docker-entrypoint.sh (from postgres image)
#/usr/local/bin/docker-entrypoint.sh postgres

# Capture stdout line by line
stdbuf -oL bash /usr/local/bin/docker-entrypoint.sh postgres |
    while IFS= read -r _LINE
    do
        capture_message "$_LINE"
    done
