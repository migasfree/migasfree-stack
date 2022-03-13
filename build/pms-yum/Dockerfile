FROM fedora:34
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
    _BUILD_DEPENDS='python3-pip wget' && \
    _DEPENDS='gnupg createrepo gzip python3 netcat util-linux-user' && \
    _PIP_DEPENDS='requests celery[redis] setuptools' && \
    useradd www-data && \
    usermod -u $_UID www-data && \
    groupmod -g $_GID www-data && \
    #lchsh -s /bin/bash www-data && \
    yum -y update && \
    yum -y install $_DEPENDS && \
    yum -y install $_BUILD_DEPENDS && \
    pip3 install $_PIP_DEPENDS && \
    mkdir /pms && \
    yum -y remove $_BUILD_DEPENDS && \
    yum -y  clean all  

COPY --from=migasfree/backend:master /migasfree /pms/migasfree

RUN chown -R $_UID:$_GID /pms

COPY defaults/docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/bin/bash", "/docker-entrypoint.sh"]
