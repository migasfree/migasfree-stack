#https://github.com/sjiveson/nfs-server-alpine

mkdir -p /exports/migasfree/database
mkdir -p /exports/migasfree/dump
mkdir -p /exports/migasfree/datastore
mkdir -p /exports/migasfree/conf
mkdir -p /exports/migasfree/public
mkdir -p /exports/migasfree/keys


chown 70:70 /exports/migasfree/database
chown 70:70 /exports/migasfree/dump
chown 999:999 /exports/migasfree/datastore
chown 890:890  /exports/migasfree/conf
chown 890:890  /exports/migasfree/public
chown 890:890  /exports/migasfree/keys


if ! [ -f /exports/migasfree/conf/settings.py ];
then
    cp ../config/conf/settings.py  /exports/migasfree/conf/
    chown 890:890  /exports/migasfree/conf/settings
fi


docker run --restart=always -d \
    --name nfsserver \
    -p 2049:2049 \
    --privileged \
     -v /exports/migasfree/:/migasfree \
     -e SHARED_DIRECTORY=/migasfree \
     itsthenetwork/nfs-server-alpine:latest

