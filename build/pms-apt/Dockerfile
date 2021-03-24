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
    _DEPENDS='gnupg dpkg-dev gzip python3 wait-for-it' && \
    _PIP_DEPENDS='requests celery[redis]' && \
    usermod -u $_UID www-data && \
    groupmod -g $_GID www-data && \
    chsh -s /bin/bash www-data && \
    #sed --in-place "s/httpredir.debian.org/softlibre.unizar.es/g" /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends  $_DEPENDS && \
    apt-get install -y --no-install-recommends  $_BUILD_DEPENDS && \
    pip3 install $_PIP_DEPENDS && \
    mkdir /pms_apt && \
    wget --no-check-certificate https://raw.githubusercontent.com/migasfree/migasfree-sdk/master/migasfree_sdk/api.py -O /pms_apt/api.py && \
    apt-get -y purge $_BUILD_DEPENDS && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* 


COPY defaults/pms_apt /pms_apt
COPY defaults/usr/bin/repository-metadata /usr/bin/repository-metadata 

RUN chown -R $_UID:$_GID /pms_apt && \
    chown $_UID:$_GID /usr/bin/repository-metadata

COPY defaults/docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/bin/bash", "/docker-entrypoint.sh"]
