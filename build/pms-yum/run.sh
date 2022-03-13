

mount |grep "^192.168.92.100:/export/migasfree" >/dev/null
if ! [ $? = 0 ]
then
    mount -t nfs 192.168.92.100:/export/migasfree /var/lib/migasfree
fi


docker run --rm -ti  \
  -v "/var/lib/migasfree/192.168.92.100/public:/var/migasfree/repo" \
  -v "/var/lib/migasfree/192.168.92.100/keys:/usr/share/migasfree-server" \
  migasfree/apt:latest \
  su -c "/app/repository-create 1" - www-data





mkdir /var/migasfree;chown 890:890 /var/migasfree
su -c "/app/repository-create 1" www-data

