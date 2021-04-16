#!/bin/bash

# Start transaction
echo -e "set ssl cert /usr/local/etc/haproxy/certificates/${DOMAIN}.pem <<\n$(cat /etc/certificates/${DOMAIN}.pem)\n" | socat tcp-connect:core_loadbalancer:9999 -

# Commit transaction
echo "commit ssl cert /usr/local/etc/haproxy/certificates/${DOMAIN}.pem" | socat tcp-connect:core_loadbalancer:9999 -

# Show certification info (not essential)
echo "show ssl cert /usr/local/etc/haproxy/certificates/${DOMAIN}.pem" | socat tcp-connect:core_loadbalancer:9999 -