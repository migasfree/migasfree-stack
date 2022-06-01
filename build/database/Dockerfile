FROM postgres:13.2-alpine
LABEL maintainer="Alberto Gacías <alberto@migasfree.org>"

RUN apk add curl coreutils

COPY defaults/usr /usr
COPY defaults/etc/pam.d/cron /etc/pam.d/cron
COPY defaults/docker-entrypoint-extend.sh /docker-entrypoint-extend.sh

ENTRYPOINT ["/docker-entrypoint-extend.sh"]

