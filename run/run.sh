source ../config/env/general
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
echo -n "waiting core " 
while true 
do
    _STATUS=$(curl --write-out '%{http_code}' --silent --output /dev/null ${FQDN}/services/status)
    if [ "${_STATUS}" = "200" ]
    then
        echo
        break
    fi
    echo -n "."
    sleep 1
done

docker stack deploy --compose-file migasfree.yml ${STACK}
