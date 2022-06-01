# https://hub.docker.com/_/redis/
FROM redis:6.2.5-alpine
LABEL maintainer="Alberto Gacías <alberto@migasfree.org>"

RUN apk add coreutils curl

COPY defaults/docker-entrypoint.sh  /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 6379
CMD ["redis-server"]