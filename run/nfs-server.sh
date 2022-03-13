#https://github.com/sjiveson/nfs-server-alpine

source ../config/env/general
#source ../config/env/stack

mkdir -p /exports/migasfree/database
mkdir -p /exports/migasfree/dump
mkdir -p /exports/migasfree/datastore
mkdir -p /exports/migasfree/conf/locations.d
mkdir -p /exports/migasfree/public
mkdir -p /exports/migasfree/keys
mkdir -p /exports/migasfree/tmp
mkdir -p /exports/migasfree/plugins
mkdir -p /exports/migasfree/certificates


chown 70:70 /exports/migasfree/database
chown 70:70 /exports/migasfree/dump
chown 999:999 /exports/migasfree/datastore
chown -R 890:890  /exports/migasfree/conf
chown 890:890  /exports/migasfree/public
chown 890:890  /exports/migasfree/keys
chown 890:890  /exports/migasfree/tmp
chown 890:890 /exports/migasfree/plugins
chown root:root /exports/migasfree/certificates


if ! [ -f /exports/migasfree/conf/settings.py ];
then
    cp ../config/conf/settings.py  /exports/migasfree/conf/
    chown 890:890  /exports/migasfree/conf/settings
fi

if ! [ -f /exports/migasfree/plugins/__init__.py ]
then
    touch /exports/migasfree/plugins/__init__.py
    chown 890:890 /exports/migasfree/plugins/__init__.py
fi



_DEV=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)')
ip addr add ${NFS_SERVER}/24 dev $_DEV

docker run --restart=always -d \
    --name nfsserver \
    -p ${NFS_SERVER}:2049:2049 \
    --privileged \
     -v /exports/migasfree/:/migasfree \
     -e SHARED_DIRECTORY=/migasfree \
     itsthenetwork/nfs-server-alpine:latest

