Certificados AUTOFIRMADOS de haproxy
=================================

cert.pem 
------------
Lo utiliza haproxy para hacer el SSL

ca.crt
-------
Certificado de la Autoridad Certificadora Fake.

Debe copiarse en los clientes: 
    cp ca.crt /usr/share/ca-certificates/ca.crt
    ln -s /usr/share/ca-certificates/ca.crt /usr/local/share/ca-certificates/ca.crt && \
    update-ca-certificates



