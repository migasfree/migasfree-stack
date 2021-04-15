#!/bin/bash
set -e
#install-certs
#watch-certs &
#LETSENCRYPT_CERT="$(cat /certs/cert.pem)"
#export DEFAULT_SSL_CERT="${DEFAULT_SSL_CERT:-$LETSENCRYPT_CERT}"
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