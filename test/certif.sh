#!/bin/sh

read num

openssl genrsa -out cle-ssl.key 1024
openssl req -new -key cle-ssl.key -subj "/C=FR/O=Grid5000/OU=gLite G5K/CN=griffon-$num.nancy.grid5000.fr" > demande-ssl.csr

if [ ! -f ./cle-CA.key ]; then
  openssl genrsa -out cle-CA.key 1024
  openssl req -new -key cle-CA.key -subj '/C=FR/O=Grid5000/CN=G5K-CA' -out demande-CA.csr
  openssl x509 -in demande-CA.csr -out certif-CA.crt -req -signkey cle-CA.key -days 3650
fi

openssl x509 -req -in demande-ssl.csr -out certif-ssl.crt -CA certif-CA.crt -CAkey cle-CA.key -CAcreateserial -CAserial CA.srl

mkdir griffon-$num
cp certif-ssl.crt ./griffon-$num/hostcert.pem
cp cle-ssl.key ./griffon-$num/hostkey.pem

rm certif-ssl.crt cle-ssl.key demande-ssl.csr
