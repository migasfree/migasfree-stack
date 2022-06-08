#!/bin/bash

function wait {
    local _SERVER=$1
    local _PORT=$2
    local counter=0
    until [ $counter -gt 5 ]
    do
        nc -z $_SERVER $_PORT 2> /dev/null
        if [ $? = 0 ]
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

function send_message {
    point="http://loadbalancer:8001/services/message"
    data="{ \"text\":\"$1\", \"service\":\"$SERVICE\" ,\"node\":\"$NODE\",\"container\":\"$HOSTNAME\" }"
    until [ $(curl -s -o /dev/null  -w '%{http_code}' -d "$data" -H "Content-Type: application/json" -X POST $point) = "200" ]
    do
        sleep 2
    done
}

function reload_loadbalancer {
    curl -d "" -X POST http://loadbalancer:8001/services/reconfigure &> /dev/null
}

# Configure ngnix
cat << EOF > /etc/nginx/conf.d/default.conf
server {
    listen       80;
    server_name  localhost 127.0.0.1 frontend $(hostname);

    #charset koi8-r;
    #access_log  /var/log/nginx/host.access.log  main;

    access_log  /dev/stdout  main;
    error_log /dev/stderr warn;

    #location / {
    #    root   /usr/share/nginx/html;
    #    index  index.html index.htm;
    #}

    # mode history: https://router.vuejs.org/guide/essentials/history-mode.html#example-server-configurations
    location / {
        root   /usr/share/nginx/html;
        try_files \$uri \$uri/ /index.html;
    }

    #error_page  404              /404.html;

    # redirect server error pages to the static page /50x.html
    #
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}
EOF

send_message "starting ${SERVICE:(${#STACK})+1}"

# Hacking enviroment variable MIGASFREE_SERVER for production
_FILES=$(grep -l __FQDN__ /usr/share/nginx/html/js/*)
for _FILE in $_FILES
do
    sed -i "s/__FQDN__/$FQDN/g" $_FILE
done

send_message "waiting backend"
wait backend 8080

echo "


                   ●                          ●●
                                             ●
         ●●● ●●    ●    ●●     ●●●     ●●●  ●●●●  ●●●  ●●●    ●●● 
        ●   ●  ●   ●   ●  ●       ●   ●      ●   ●    ●   ●  ●   ●
        ●   ●  ●   ●   ●  ●    ●●●●    ●●    ●   ●    ●●●●   ●●●● 
        ●   ●  ●   ●   ●  ●   ●   ●      ●   ●   ●    ●      ●
        ●   ●  ●   ●    ●●●    ●●●    ●●●    ●   ●     ●●●    ●●●
                          ●
                        ●●

        migasfree FRONTEND
        $(nginx -v 2>&1)
        Container: $HOSTNAME
        Time zome: $TZ  $(date)
        Processes: $(nproc)

"

echo "daemon off;" >> /etc/nginx/nginx.conf
reload_loadbalancer
send_message ""
nginx
