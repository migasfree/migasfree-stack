#!/bin/bash
set -e

# ENVIRONMENT VARIABLES FOR VOLUMES  
function get_mount_paths {
    IFS=$'\n'
    for _M in $(mount|grep '^:/' )
    do
        local _KEY=$(echo -n "$_M"|awk '{print $1}')
        _KEY=${_KEY:2}
        _KEY=${_KEY^^} 
        local _VALUE=$(echo -n "$_M"|awk '{print $3}')
        #export PATH_${_KEY}=${_VALUE}
        export MIGASFREE_${_KEY}_DIR=${_VALUE}
    done
    IFS=""
}

function send_message {
    curl -d "text=$1;container=$(hostname);service=$SERVICE;node=$NODE" -X POST http://loadbalancer:8001/services/message &> /dev/null
}

get_mount_paths
env

# If not certificate, haproxy don't start and/or certbot can't challenge complete
# Create a self-certificate to init
[ ! -f "/usr/local/etc/haproxy/certificates/${FQDN}.pem" ] && \
  { echo "INFO: Creating self certificates..."; install-certs; }

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
    set -- haproxy "$@"
fi


# services page
# ================
cd /usr/share/services/
/usr/bin/python3 services.py 8001 >/dev/null &
cd -

sleep 1
reconfigure || :

echo "

        migasfree BALANCER
        $(haproxy -v | head -1)
        Container: $HOSTNAME
        Time zome: $TZ  $(date)
        Processes: $(nproc)
               -------O--
              \\         o \\
               \\           \\
                \\           \\
                  -----------


"



# load balancer
# =============
#haproxy -W -S /var/run/haproxy-master-socket -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -sf $(cat /run/haproxy.pid) -x /var/run/haproxy.sock


haproxy -W -S /var/run/haproxy-master-socket -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -sf $(cat /run/haproxy.pid)