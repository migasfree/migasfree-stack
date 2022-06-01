#/bin/bash


docker stack rm mf
while docker ps|grep "mf_" > /dev/null
do 
   echo -n "."
   sleep 1
done
echo
 

docker stack rm core
while docker ps|grep "core_" > /dev/null
do 
   echo -n "."
   sleep 1
done
echo 

docker stop nfsserver
docker rm nfsserver



echo "y" | docker system prune
