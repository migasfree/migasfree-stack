#!/bin/sh
trap exit TERM

function send_message {
    point="http://loadbalancer:8001/services/message"
    data="{ \"text\":\"$1\", \"service\":\"$SERVICE\" ,\"node\":\"$NODE\",\"container\":\"$HOSTNAME\" }"
    until [ $(curl -s -o /dev/null  -w '%{http_code}' -d "$data" -H "Content-Type: application/json" -X POST $point) = "200" ]
    do
       sleep 2
    done
}

while :;
do
    send_message "renew certificate letsencript" 
    [ "${HTTPSMODE}" = "auto" ] && . /usr/bin/renew-certificates.sh
    send_message ""
    sleep 12h & wait ${!}
done
