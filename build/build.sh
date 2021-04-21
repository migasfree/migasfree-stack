
function build
{
    CONTEXT="$1"
    cd $CONTEXT
    TAG=$(cat VERSION)
    echo
    echo
    echo "BUILD: ${IMAGE}:${TAG}"
    echo "============================================================================"
    docker build . -t "migasfree/$CONTEXT:$TAG"
    cd - >/dev/null
}

for IMAGE in loadbalancer datastore database backend frontend public pms-apt certbot
#for IMAGE in loadbalancer
do
   build $IMAGE
done
