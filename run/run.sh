#source ../config/env/general
source ../config/env/stack

# NETWORK
docker network ls | grep ${STACK}_network
if ! [ $? = 0 ]
then
    docker network create --driver=overlay --attachable ${STACK}_network
fi


# Generates core.yml  & migasfree.yml from templates
./templates/process

docker stack deploy --compose-file core.yml core

docker stack deploy --compose-file migasfree.yml ${STACK}
