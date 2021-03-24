docker pull dpage/pgadmin4

docker run -p 5050:80 \
    -e 'PGADMIN_DEFAULT_EMAIL=alberto@migasfree.org' \
    -e 'PGADMIN_DEFAULT_PASSWORD=SuperSecret' \
    -d dpage/pgadmin4