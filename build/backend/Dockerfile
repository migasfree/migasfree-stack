FROM debian:bullseye-slim AS builder
LABEL maintainer="Alberto Gacías <alberto@migasfree.org>"

COPY VERSION /VERSION

ENV TERM=xterm \
    DEBIAN_FRONTEND=noninteractive \
    USER=root \
    LANG=en_US.UTF-8 \
    DJANGO_SETTINGS_MODULE=migasfree.settings.production \
    _UID=890 \
    _GID=890 \
    _BUILD_DEPENDS='git python3-dev libgpgme11-dev python3-all python3-all-dev unzip g++ gcc-9 libcairo2-dev libjpeg62-turbo-dev libxml2-dev libxslt1-dev libpq-dev swig' \
    _DEPENDS='libzmq5 gnupg rng-tools curl apt-utils bzip2 xz-utils libgpgme11 python3 python3-venv python3-minimal python3-pip p7zip-full vim wget postgresql-client netcat libmagic1' \
    _PIP_DEPENDS='uvicorn[standard]==0.18.3'

RUN _TAG=$(cat /VERSION) && \
    apt-get update && \
    apt-get install -y --no-install-recommends apt-utils && \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    echo "es_ES.UTF-8 UTF-8" >> /etc/locale.gen && \
    apt-get install -y --no-install-recommends locales && \
    dpkg-reconfigure locales && \
    update-locale LANG=$LANG && \
    apt-get install -y --no-install-recommends ntp coreutils && \
    service ntp start && \
    update-rc.d ntp defaults && \
    apt-get install -y --no-install-recommends $_BUILD_DEPENDS  && \
    apt-get install -y --no-install-recommends $_DEPENDS && \
    python3 -m venv /venv &&\
    . /venv/bin/activate  &&\
    python3 -m pip install --no-cache-dir --upgrade pip && \
    python3 -m pip install --no-cache-dir --upgrade setuptools wheel && \
    pip install --no-cache-dir $_PIP_DEPENDS

RUN cd / && \
    . /venv/bin/activate &&\
    git clone https://github.com/migasfree/migasfree-backend && \
    cd migasfree-backend &&\
    pip install --no-cache-dir -r requirements/production.txt && \
    pip install --no-cache-dir requests_toolbelt && \
    python3 setup.py install && \
    rm -rf /migasfree-backend

RUN . /venv/bin/activate && \
    # Symbolic links to be copied from other containers && \
    # MIGASFREE MODULE && \
    MIGASFREE_MODULE_PATH=$(python3 -c "import migasfree;print(migasfree.__path__[0])") && \
    ln -s $MIGASFREE_MODULE_PATH /migasfree && \
    # STATIC FILES && \
    mkdir /static && \
    STATIC_DJANGO=$(python3 -c "import django;print(django.__path__[0])") && \
    ln -s ${STATIC_DJANGO}/contrib/admin/static/admin /static/admin && \
    STATIC_REST_FRAMEWORK=$(python3 -c "import rest_framework;print(rest_framework.__path__[0])") && \
    ln -s ${STATIC_REST_FRAMEWORK}/static/rest_framework /static/rest_framework && \
    STATIC_DRF_YASG=$(python3 -c "import drf_yasg;print(drf_yasg.__path__[0])") && \
    ln -s ${STATIC_DRF_YASG}/static/drf-yasg /static/drf-yasg

# explicity set user/group IDs to www-data && \
RUN usermod -u $_UID www-data && \
    groupmod -g $_GID www-data && \
    chsh -s /bin/bash www-data && \
    #. /venv/bin/activate &&\
    #django-admin collectstatic --noinput && \
    apt-get -y --auto-remove purge $_BUILD_DEPENDS && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/pip_build_root && \
    rm -rf /root/.cache

COPY defaults/usr /usr
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

COPY --from=builder / /

ENTRYPOINT ["/bin/bash", "/docker-entrypoint.sh"]
EXPOSE 80
