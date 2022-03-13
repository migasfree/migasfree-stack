FROM archlinux:latest
LABEL maintainer="Alberto Gacías <alberto@migasfree.org>"

COPY VERSION /VERSION

ENV TERM=xterm \
    USER=root \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LC_CTYPE=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    _UID=890 \
    _GID=890 

RUN _TAG=$(cat /VERSION) && \
    _BUILD_DEPENDS='python-setuptools python-pip python-distro wget' && \
    _DEPENDS='gnupg gzip python netcat' && \
    _PIP_DEPENDS='requests celery[redis]' && \
    useradd www-data &&\
    usermod -u $_UID www-data && \
    groupmod -g $_GID www-data && \
    patched_glibc=glibc-linux4-2.33-4-x86_64.pkg.tar.zst && \
    curl -LO "https://raw.githubusercontent.com/sickcodes/Docker-OSX/master/${patched_glibc}" && \
    bsdtar -C / -xvf "${patched_glibc}"  && \
    chsh -s /bin/bash www-data  && \
    pacman -Sy  && \
    pacman --noconfirm --sync  $_DEPENDS  && \
    pacman --noconfirm --sync  $_BUILD_DEPENDS && \
    pip install $_PIP_DEPENDS && \
    mkdir /pms && \
    rm -rf /var/tmp/* /usr/share/man/* /var/cache/pacman/pkg/* /var/lib/pacman/sync/*

COPY --from=migasfree/backend:master /migasfree /pms/migasfree

RUN chown -R $_UID:$_GID /pms

COPY defaults/docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/bin/bash", "/docker-entrypoint.sh"]
