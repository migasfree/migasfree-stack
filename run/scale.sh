_SERVICE=$1
_NUM=$2

docker service scale ${_SERVICE}=${_NUM}


_CMD="echo '@master reload' | socat /var/run/haproxy-master-socket stdio"


_BALANCER=$(docker ps |grep loadbalancer|awk '{print $1}')

docker exec $_BALANCER reconfigure
