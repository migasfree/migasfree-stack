#!/bin/bash
set -e

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

function send_message {
    point="http://localhost:8001/services/message"
    data="{ \"text\":\"$1\", \"service\":\"$SERVICE\" ,\"node\":\"$NODE\",\"container\":\"$HOSTNAME\" }"
    until [ $(curl -s -o /dev/null  -w '%{http_code}' -d "$data" -H "Content-Type: application/json" -X POST $point) = "200" ]
    do
        sleep .5
    done
}

get_mount_paths
env

# If not certificate, haproxy don't start and/or certbot can't challenge complete
# Create a self-certificate to init
[ ! -f "/usr/local/etc/haproxy/certificates/${FQDN}.pem" ] && \
  {
    echo "INFO: Creating self certificates..."
    install-certs
  }

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]
then
    set -- haproxy "$@"
fi

# services page
# ================
cd /usr/share/services/
/usr/bin/python3 services.py 8001 >/dev/null &
cd -

while [ ! -f /etc/haproxy/haproxy.cfg ]
do
    echo "Checking HA Proxy conf"
    sleep 1
done
echo "HA Proxy conf OK"

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

        migasfree BALANCER
        $(haproxy -v | head -1)
        Container: $HOSTNAME
        Time zome: $TZ $(date)
        Processes: $(nproc)

"

# load balancer
# =============
mkdir -p /var/run/haproxy/

haproxy -W -db -S /var/run/haproxy-master-socket -f /etc/haproxy/haproxy.cfg \
    -p /var/run/haproxy.pid
