#!/bin/bash

function build
{
    local _CONTEXT="$1"
    pushd "$_CONTEXT" > /dev/null
    local _TAG=$(cat VERSION)
    echo
    echo
    echo "BUILD: ${_CONTEXT}:${_TAG}"
    echo "============================================================================"
    docker build . -t "migasfree/${_CONTEXT}:${_TAG}"
    popd > /dev/null
}

_IMAGES="$1"
if [ -z "${_IMAGES}" ]
then
    _IMAGES="loadbalancer certbot datastore database backend frontend public pms-apt pms-yum pms-winget pms-pacman"
fi

for _IMAGE in ${_IMAGES}
do
    build "${_IMAGE}"
done
