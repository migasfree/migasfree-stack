#/bin/bash


#cd ../build
#bash build.sh loadbalancer
#cd -

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


echo "y" | docker system prune
bash run.sh
