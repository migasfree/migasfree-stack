
function send_message {
    curl -d "text=$1;container=$(hostname);service=$SERVICE;node=$NODE" -X POST http://loadbalancer:8001/services/message &> /dev/null
}

function reload_loadbalancer {
    curl -d "" -X POST http://loadbalancer:8001/services/reconfigure &> /dev/null
}

send_message "starting $SERVICE"


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



# Hacking enviroment variable MIGASFREE_SERVER for production
_FILES=$(grep -l __FQDN__ /usr/share/nginx/html/js/*)
for _FILE in $_FILES
do
    sed -i "s/__FQDN__/$FQDN/g" $_FILE 
done


reload_loadbalancer
send_message ""

echo "

        migasfree FRONTEND
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


# forward request and error logs to docker log collector
#ln -sf /dev/stdout /var/log/nginx/access.log
#ln -sf /dev/stderr /var/log/nginx/error.log

echo "daemon off;" >> /etc/nginx/nginx.conf
nginx 