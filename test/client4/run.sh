cp ../../config/certs/ca.crt defaults/usr/share/ca-certificates/ca.crt
docker build . -t migasfree/client:4.20
docker run --rm \
	-e TZ="Europe/Madrid" \
	-e MIGASFREE_CLIENT_SERVER=192.168.1.105:443 \
	-e MIGASFREE_CLIENT_PROJECT=acme \
    -e MIGASFREE_CLIENT_PROTOCOL=https \
	-e MIGASFREE_CLIENT_PORT= \
    -e USER=root \
	-ti migasfree/client:4.20 bash 
