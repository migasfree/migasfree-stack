#!/bin/sh
trap exit TERM

while :;
do
    [ "${HTTPSMODE}" = "auto" ] && . /usr/bin/renew-certificates.sh
    sleep 12h & wait ${!}
done
