FROM nginx:alpine
LABEL maintainer="Alberto Gacías <alberto@migasfree.org>"

# change uid and gid for nginx user
RUN apk --no-cache add bind-tools curl shadow && \
    usermod -u 890 nginx && \
    groupmod -g 890 nginx && \
    apk del shadow

COPY defaults/var/migasfree /var/migasfree

# Django admin STATIC
COPY --from=migasfree/backend:master /venv/lib64/python3.7/site-packages/django/contrib/admin/static/ /var/migasfree/static

# Rest-framework STATIC
COPY --from=migasfree/backend:master /venv/lib64/python3.7/site-packages/rest_framework/static /var/migasfree/static

# Swagger STATIC
COPY --from=migasfree/backend:master /venv/lib64/python3.7/site-packages/drf_yasg/static /var/migasfree/static

RUN chown -R 890:890 /var/migasfree/


COPY defaults/etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf
COPY defaults/docker-entrypoint.sh /docker-entrypoint.sh

CMD [""]

ENTRYPOINT ["/bin/sh", "/docker-entrypoint.sh"]

