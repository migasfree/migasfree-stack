. ../config/env/globals

export FQDN

export NFS_SERVER

export STACK

export CERTBOT_TAG=$(cat ../build/loadbalancer/VERSION)

export LOADBALANCER_TAG=$(cat ../build/loadbalancer/VERSION)

export BACKEND_TAG=$(cat ../build/backend/VERSION)

export FRONTEND_TAG=$(cat ../build/frontend/VERSION)

export PUBLIC_TAG=$(cat ../build/public/VERSION)

export PMS_APT_TAG=$(cat ../build/pms-apt/VERSION)

export DATABASE_TAG=$(cat ../build/database/VERSION)

export DATASTORE_TAG=$(cat ../build/datastore/VERSION)


# NETWORK
docker network ls | grep ${STACK}_network
if ! [ $? = 0 ]
then
    docker network create --driver=overlay --attachable ${STACK}_network
fi


docker stack deploy --compose-file core.yml core

docker stack deploy --compose-file migasfree.yml ${STACK}
