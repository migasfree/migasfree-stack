# https://ilhicas.com/2018/04/07/Haproxy-ssl-termination-jekyll.html
FROM haproxy:lts-alpine3.16 as builder
LABEL maintainer="Alberto Gacías <alberto@migasfree.org>"

USER root

ENV LIVE_CERT_FOLDER="/etc/letsencrypt/live" \
    BUILD_DEPENDS='py3-pip' \
    RUNTIME_DEPENDS='bash tzdata inotify-tools openssl ca-certificates socat curl bind-tools python3 curl' \
    RUNTIME_PIP='web.py jinja2'


RUN apk add --update --no-cache $BUILD_DEPENDS $RUNTIME_DEPENDS && \
    pip3 install --no-cache-dir $RUNTIME_PIP && \
    #apk del $BUILD_DEPENDS && \
    rm -rf /var/cache/apk/*


COPY defaults/usr/share/services /usr/share/services
COPY defaults/usr/bin /usr/bin
COPY defaults/etc/haproxy /etc/haproxy
COPY defaults/docker-entrypoint.sh /docker-entrypoint.sh


ENTRYPOINT ["/docker-entrypoint.sh"]
