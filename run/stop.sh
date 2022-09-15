#/bin/bash

source ../config/env/general

docker stack rm mf
while docker ps | grep "mf_" > /dev/null
do
    echo -n "."
    sleep 1
done
echo

docker stack rm core
while docker ps | grep "core_" > /dev/null
do
    echo -n "."
    sleep 1
done
echo

docker stop nfsserver
docker rm nfsserver

_DEV=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)')
ip addr del ${NFS_SERVER}/24 dev $_DEV

docker system prune -f