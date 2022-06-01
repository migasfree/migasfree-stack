FROM debian:buster-slim
LABEL maintainer="Alberto Gacías <alberto@migasfree.org>"

COPY VERSION /VERSION

ENV TERM=xterm \
    DEBIAN_FRONTEND=noninteractive \
    USER=root \
    LANGUAGE=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    LC_CTYPE=C.UTF-8 \
    LANG=C.UTF-8 \
    _UID=890 \
    _GID=890 

RUN _TAG=$(cat /VERSION) && \
    _BUILD_DEPENDS=' python3-setuptools python3-pip wget' && \
    _DEPENDS='gnupg dpkg-dev gzip python3 netcat curl' && \
    _PIP_DEPENDS='requests celery[redis]' && \
    usermod -u $_UID www-data && \
    groupmod -g $_GID www-data && \
    chsh -s /bin/bash www-data && \
    apt-get update && \
    apt-get install -y --no-install-recommends  $_DEPENDS && \
    apt-get install -y --no-install-recommends  $_BUILD_DEPENDS && \
    pip3 install $_PIP_DEPENDS && \
    mkdir /pms && \
    apt-get -y purge $_BUILD_DEPENDS && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* 

COPY --from=migasfree/backend:master /migasfree /pms/migasfree

RUN chown -R $_UID:$_GID /pms

COPY defaults/docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/bin/bash", "/docker-entrypoint.sh"]
