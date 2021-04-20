#!/bin/sh
trap exit TERM

[ "${HTTPSMODE}" != "auto" ] && exit 0

while :;
do
    . /usr/bin/renew-certificates.sh
    sleep 12h & wait ${!}
done
