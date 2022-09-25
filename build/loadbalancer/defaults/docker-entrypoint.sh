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

get_mount_paths

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

message "Initial configuration"

echo "Checking configuration"
haproxy -c -f /etc/haproxy/haproxy.cfg

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

message ""

haproxy -W -db -S /var/run/haproxy/haproxy-master-socket -f /etc/haproxy/haproxy.cfg \
    -p /var/run/haproxy/haproxy.pid
