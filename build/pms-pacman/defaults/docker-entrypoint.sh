QUEUES="pms-pacman"
BROKER_URL=redis://datastore:6379/0
BACKEND_URL=$BROKER_URL
export MIGASFREE_FQDN=$FQDN
export MIGASFREE_SECRET_DIR=/var/run/secrets

function wait {
    local _SERVER=$1
    local _PORT=$2
    local counter=0
    until [ $counter -gt 5 ]
    do
        nc -z $_SERVER $_PORT 2> /dev/null
        if [ $? = 0 ]
        then
            echo "$_SERVER:$_PORT is running."
            return
        else
            echo "$_SERVER:$_PORT is not running after $counter seconds."
            sleep 1
        fi
        ((counter++))
    done
    echo "Rebooting container"
    exit
}

function send_message {
    point="http://loadbalancer:8001/services/message"
    data="{ \"text\":\"$1\", \"service\":\"$SERVICE\" ,\"node\":\"$NODE\",\"container\":\"$HOSTNAME\" }"
    until [ $(curl -s -o /dev/null  -w '%{http_code}' -d "$data" -H "Content-Type: application/json" -X POST $point) = "200" ]
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
    for _M in $(mount | grep '^:/' )
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

        migasfree PMS-PACMAN
        celery $(celery --version)
        Container: $HOSTNAME
        Time zome: $TZ  $(date)
        Processes: $(nproc)

"

cd /pms
reload_loadbalancer
send_message ""
celery -A migasfree.core.tasks -b $BROKER_URL --result-backend=$BROKER_URL \
    worker -l INFO --uid=890 -Q $QUEUES --concurrency=1
