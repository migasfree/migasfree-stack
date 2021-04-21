. ../config/env/globals

DB_V5=$(docker ps |grep ${STACK}_database|awk '{print $1}')
BE_V5=$(docker ps |grep ${STACK}_backend|awk '{print $1}')


OLD_HOST=$1
OLD_PORT=$2
OLD_DB=$3
OLD_USER=$4
OLD_PWD=$5


function help {
  echo "Sintax: migrate-db OLD_HOST OLD_PORT [OLD_DB] [OLD_USER] [OLD_PWD]"
  echo
  echo "Samples:"
  echo "    migrate-db 192.168.1.105 5555"
  echo "    migrate_db 172.16.17.20 5432 migasfree migasfree mipass"
  exit 1
}

if [ -z $OLD_HOST ] ;
then
   help 
fi

if [ -z $OLD_PORT ] ;
then
   help 
fi

if [ -z $OLD_DB ];
then
   OLD_DB=migasfree
fi

if [ -z $OLD_USER ];
then
   OLD_USER=migasfree
fi

if [ -z $OLD_PWD ];
then
   OLD_PWD=migasfree
fi

echo
echo "WARNING !!!!"
read -p "This process import the database from the v4 instance: $OLD_HOST:$OLD_PORT. Are you sure [yes/N]?"
echo
if [[ $REPLY = "yes" ]] ; then

    # MIGRATE DATABASE FROM V4 TO V5
    # ==============================
    time docker exec ${DB_V5} bash -c "echo yes| bash /usr/share/migration/migrate_from_v4 $OLD_HOST  $OLD_PORT $OLD_DB $OLD_USER $OLD_PWD"

    # SUMMARIZE SYNCS 
    # ================
    # TODO: django-admin refresh_redis_syncs está consumiendo toda la RAM. Por ahora deshabilito.  
    #time docker exec ${BE_V5} bash -c "django-admin refresh_redis_syncs"

fi