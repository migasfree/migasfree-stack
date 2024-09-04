#!/bin/bash

QUEUES="pms-apt"
BROKER_URL=redis://datastore:6379/0
export MIGASFREE_FQDN=$FQDN
export MIGASFREE_SECRET_DIR=/var/run/secrets
export CELERY_BROKER_URL=$BROKER_URL

function wait {
    local _SERVER=$1
    local _PORT=$2
    local _COUNTER=0
    until [ $_COUNTER -gt 5 ]
    do
        nc -z $_SERVER $_PORT 2> /dev/null
        if [ $? = 0 ]
        then
            echo "$_SERVER:$_PORT is running."
            return
        else
            echo "$_SERVER:$_PORT is not running after $_COUNTER seconds."
            sleep 1
        fi
        ((_COUNTER++))
    done
    echo "Rebooting container"
    exit 1
}

function send_message {
    local _POINT="http://loadbalancer:8001/services/message"
    local _DATA="{ \"text\":\"$1\", \"service\":\"$SERVICE\" ,\"node\":\"$NODE\",\"container\":\"$HOSTNAME\" }"

    until [ $(curl -s -o /dev/null  -w '%{http_code}' -d "$_DATA" -H "Content-Type: application/json" -X POST $_POINT) = "200" ]
    do
        sleep 2
    done
}

function reload_loadbalancer {
    curl -d "" -X POST http://loadbalancer:8001/services/reconfigure &> /dev/null
}

# ENVIRONMENT VARIABLES FOR VOLUMES
function get_mount_paths {
    IFS=$'\n'
    for _M in $(mount | grep '^:/')
    do
        local _KEY=$(echo -n "$_M" | awk '{print $1}')
        _KEY=${_KEY:2}
        _KEY=${_KEY^^}
        local _VALUE=$(echo -n "$_M" | awk '{print $3}')
        export MIGASFREE_${_KEY}_DIR=${_VALUE}
    done
    IFS=""
}

send_message "starting ${SERVICE:(${#STACK})+1}"

send_message "waiting backend"
wait backend 8080

get_mount_paths

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

        migasfree service: ${SERVICE}
        queues: ${QUEUES}

        celery $(celery --version)
        Container: $HOSTNAME
        Time zome: $TZ $(date)
        Processes: $(nproc)

"

cd /pms
reload_loadbalancer

send_message ""
celery -A migasfree.core.pms.tasks -b $BROKER_URL --result-backend=$BROKER_URL \
    worker -l INFO --uid=890 -Q $QUEUES --concurrency=1
