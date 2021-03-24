BROKER_URL=redis://datastore:6379/0
BACKEND_URL=$BROKER_URL
QUEUES="repository"

# ENVIRONMENT VARIABLES FOR VOLUMES  
function get_mount_paths {
    IFS=$'\n'
    for _M in $(mount|grep '^:/' )
    do
        local _KEY=$(echo -n "$_M"|awk '{print $1}')
        _KEY=${_KEY:2}
        _KEY=${_KEY^^} 
        local _VALUE=$(echo -n "$_M"|awk '{print $3}')
        export PATH_${_KEY}=${_VALUE}
    done
    IFS=""
}
get_mount_paths 

wait-for-it -h datastore -p 6379
wait-for-it -h backend -p 8080

echo "

        migasfree PMS-APT
        celery $(celery --version)
        Container: $HOSTNAME
        Time zome: $TZ  $(date)
        Processes: $(nproc)
               -------O--
              \\         o \\
               \\           \\
                \\           \\
                  -----------


"

cd /pms_apt
celery -A migasfree.core.tasks -b $BROKER_URL --result-backend=$BROKER_URL  worker -l INFO --uid=890 -Q $QUEUES

