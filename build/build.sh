
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

for IMAGE in loadbalancer certbot datastore database backend frontend public pms-apt pms-yum pms-winget pms-pacman
do
   build $IMAGE
done
