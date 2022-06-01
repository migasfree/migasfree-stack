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


IMAGES="$1"
if [ -z "${IMAGES}" ]
then
   IMAGES="loadbalancer certbot datastore database backend frontend public pms-apt pms-yum pms-winget pms-pacman"
fi

for IMAGE in $IMAGES
do
   build $IMAGE
done
