#!/bin/bash
. ../../config/env/globals

cp ../../config/certs/ca.crt defaults/usr/share/ca-certificates/ca.crt
docker build . -t migasfree/client:5.0
docker run --rm \
	-e TZ="Europe/Madrid" \
	-e MIGASFREE_CLIENT_SERVER=${FQDN} \
	-e MIGASFREE_CLIENT_PROJECT=acme \
    -e MIGASFREE_CLIENT_PROTOCOL=https \
	-e MIGASFREE_CLIENT_PORT= \
    -e USER=root \
	-ti migasfree/client:5.0 bash 
