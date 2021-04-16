#!/bin/sh
trap exit TERM

# Si no existe ningún certificado de partida, haproxy no quiere arrancar
#  Se debe crear uno para que haproxy pueda arrancar y entonces poder dar servicio a certbot (responda al challenge)
# En el caso de que no se realice, no podrá contiuar (pescadilla que se muerde la cola)
#  Lo creamos mejor en haproxy...

while :;
do
    . /usr/bin/renew-certificates.sh
    sleep 12h & wait ${!}
done
