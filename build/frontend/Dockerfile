FROM node:18-alpine AS build-stage
LABEL maintainer="Alberto Gacías <alberto@migasfree.org>"
COPY VERSION /VERSION
RUN _TAG=$(cat /VERSION) && \
    apk add git && \
    git clone https://github.com/migasfree/migasfree-frontend && \
    cd migasfree-frontend && \
    git checkout $_TAG && \
    echo 'MIGASFREE_SERVER=https://__FQDN__' > /migasfree-frontend/.env

RUN cd migasfree-frontend && \
    cp package*.json /app && \
    yarn global add @quasar/cli && \
    yarn && \
    quasar build --debug

FROM nginx:1.17.5-alpine AS production-stage
LABEL maintainer="Alberto Gacías <alberto@migasfree.org>"
COPY VERSION /VERSION
RUN _TAG=$(cat /VERSION) && \
    apk add curl

# Copy application
COPY --from=build-stage /migasfree-frontend/dist/spa /usr/share/nginx/html

COPY defaults/docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/bin/sh", "/docker-entrypoint.sh"]

EXPOSE 80
