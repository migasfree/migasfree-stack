#!/bin/sh
trap exit TERM
while :;
do
    /usr/bin/renew-certificates.sh
    sleep 12h & wait ${!}
done