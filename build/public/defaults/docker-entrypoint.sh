

function send_message {
    curl -d "text=$1;container=$(hostname);service=$SERVICE;node=$NODE" -X POST http://loadbalancer:8001/services/message &> /dev/null
}

function reload_loadbalancer {
    curl -d "" -X POST http://loadbalancer:8001/services/reconfigure &> /dev/null
}


send_message "starting $SERVICE"


_CONTAINER=$(hostname)
sed -i "s/@container@/$_CONTAINER/g" /var/migasfree/404.html
sed -i "s/@container@/$_CONTAINER/g" /var/migasfree/50x.html


# TODO: Remove link. Warning!!! Afect to symbolic links of packages in REPOSITORIES.
# ¿Changes MIGASFREE_PUBLIC_DIR = '/var/migasfree/repo' in source?
ln -s /var/migasfree/public /var/migasfree/repo 


reload_loadbalancer
send_message ""

echo "

        migasfree PUBLIC
        $(nginx -v 2>&1)
        Container: $HOSTNAME
        Time zome: $TZ  $(date)
        Processes: $(nproc)
               -------O--
              \\         o \\
               \\           \\
                \\           \\
                  -----------


"

nginx -g 'daemon off;'
