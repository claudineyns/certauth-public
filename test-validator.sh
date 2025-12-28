#!/bin/sh

rm -f acme.key
rm -f acme.crt

openssl req -x509 -newkey rsa:2048 -nodes -keyout acme.key -out acme.crt -days 1 \
 -subj "/C=AQ/ST=Antarctica/L=Antarctica/O=ACME Corporation/OU=ACME Certificate Authority/CN=Client Application/emailAddress=client@example.com" \
 -addext "subjectAltName = DNS:localhost, IP:127.0.0.1" \
 -addext "extendedKeyUsage = clientAuth"

chmod 400 acme.key
chmod 400 acme.crt

curl --cert acme.crt --key acme.key https://mtls.certauth.dev
