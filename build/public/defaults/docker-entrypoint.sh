function wait {
    local _SERVER=$1
    local _PORT=$2
    local counter=0
    until [ $counter -gt 5 ]
    do
        nc -z $_SERVER $_PORT 2> /dev/null
       if  [ $? = 0 ]
       then
           echo "$_SERVER:$_PORT is running."
           return
       else
           echo "$_SERVER:$_PORT is not running after $counter seconds."
           sleep 1
       fi
       ((counter++))
    done
    echo "Rebooting container"
    exit
}

function reload_loadbalancer {
    curl -d "" -X POST http://loadbalancer:8001/services/reconfigure &> /dev/null
}


_CONTAINER=$(hostname)
sed -i "s/@container@/$_CONTAINER/g" /var/migasfree/404.html
sed -i "s/@container@/$_CONTAINER/g" /var/migasfree/50x.html


# TODO: Remove link. Warning!!! Afect to symbolic links of packages in REPOSITORIES.
# ¿Changes MIGASFREE_PUBLIC_DIR = '/var/migasfree/repo' in source?
ln -s /var/migasfree/public /var/migasfree/repo 

wait backend 8080

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

reload_loadbalancer
nginx -g 'daemon off;'
