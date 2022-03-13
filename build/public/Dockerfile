FROM nginx:alpine
LABEL maintainer="Alberto Gacías <alberto@migasfree.org>"

# change uid and gid for nginx user
RUN apk --no-cache add bind-tools curl shadow && \
    usermod -u 890 nginx && \
    groupmod -g 890 nginx && \
    apk del shadow

COPY defaults/var/migasfree /var/migasfree

# STATIC FILES
COPY --from=migasfree/backend:master /static/admin  /var/migasfree/static/admin
COPY --from=migasfree/backend:master /static/drf-yasg /var/migasfree/static/drf-yasg
COPY --from=migasfree/backend:master /static/rest_framework /var/migasfree/static/rest_framework

RUN chown -R 890:890 /var/migasfree/

COPY defaults/etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf
COPY defaults/docker-entrypoint.sh /docker-entrypoint.sh

CMD [""]

ENTRYPOINT ["/bin/sh", "/docker-entrypoint.sh"]

