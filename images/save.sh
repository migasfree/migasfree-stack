#!/bin/bash

_VERSION=5.0
for _IMG in loadbalancer public database datastore client certbot pms-apt pms-yum pms-winget pms-pacman
do
    docker save --output ./migasfree-${_IMG}-${_VERSION}.tar migasfree/${_IMG}:${_VERSION}
done

_VERSION=master
for _IMG in frontend backend
do
    docker save --output ./migasfree-${_IMG}-${_VERSION}.tar migasfree/${_IMG}:${_VERSION}
done

_VERSION=4.20
for _IMG in client
do
    docker save --output ./migasfree-${_IMG}-${_VERSION}.tar migasfree/${_IMG}:${_VERSION}
done

chmod -R 644 ./*.tar
