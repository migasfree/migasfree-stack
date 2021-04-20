FROM debian:buster-slim as builder
LABEL maintainer="Alberto Gacías <alberto@migasfree.org>"

COPY VERSION /VERSION

# Quitados  dpkg-dev rpm createrepo   de _DEPENDS -> pms-apt

ENV TERM=xterm \
    DEBIAN_FRONTEND=noninteractive \
    USER=root \
    LANG=en_US.UTF-8 \
    DJANGO_SETTINGS_MODULE=migasfree.settings.production \
    _UID=890 \
    _GID=890 \
    _BUILD_DEPENDS='git python3-dev libgpgme11-dev python3-all python3-all-dev debhelper unzip g++ gcc-8 libcairo2-dev libjpeg62-turbo-dev libxml2-dev libxslt1-dev libpq-dev' \
    _DEPENDS='libzmq5 gnupg rng-tools curl  apt-utils bzip2 xz-utils libgpgme11 python3 python3-minimal python3-pip p7zip-full vim wget postgresql-client netcat-openbsd logrotate wait-for-it' \
   _PIP_DEPENDS='daphne==3.0.2'
   # _PIP_DEPENDS='gunicorn==20.0.4 uvicorn==0.13.4 uvloop==0.15.2 httptools==0.1.1 daphne==3.0.2'

RUN _TAG=$(cat /VERSION) && \
    #sed --in-place "s/deb.debian.org/softlibre.unizar.es/g" /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends apt-utils && \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    apt-get install -y --no-install-recommends locales && \
    dpkg-reconfigure locales && \
    update-locale LANG=$LANG && \
    apt-get install -y --no-install-recommends ntp coreutils && \
    service ntp start && \
    update-rc.d ntp defaults && \
    apt-get install -y --no-install-recommends $_BUILD_DEPENDS  && \
    apt-get install -y --no-install-recommends $_DEPENDS && \
    python3 -m pip install --no-cache-dir  --upgrade pip && \
    python3 -m pip install --no-cache-dir  --upgrade setuptools wheel && \
    pip install --no-cache-dir  $_PIP_DEPENDS  
    
   
RUN cd / && \
    git clone  https://github.com/migasfree/migasfree-backend  &&\
    cd migasfree-backend &&\
    pip install  --no-cache-dir  -r  requirements/production.txt &&\
    python3 setup.py install && \
    rm -rf /migasfree-backend 
    
    # explicity set user/group IDs to www-data && \
RUN usermod -u $_UID www-data && \
    groupmod -g $_GID www-data && \
    #django-admin collectstatic --noinput && \
    apt-get -y --auto-remove purge $_BUILD_DEPENDS && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/pip_build_root && \
    rm -rf /root/.cache


COPY defaults/docker-entrypoint.sh /docker-entrypoint.sh


FROM scratch
LABEL maintainer="Alberto Gacías <alberto@migasfree.org>"

ENV TERM=xterm \
    DEBIAN_FRONTEND=noninteractive \
    USER=root \
    LANG=en_US.UTF-8 \
    DJANGO_SETTINGS_MODULE=migasfree.settings.production \
    _UID=890 \
    _GID=890 

COPY  --from=builder /  /

ENTRYPOINT ["/bin/bash", "/docker-entrypoint.sh"]
EXPOSE 80