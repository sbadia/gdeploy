#!/bin/sh
# tests pki gLite (propre ca).

mkdir -m 0755 /etc/pki_glite
mkdir -m 0755 \
     /etc/pki_glite/myCA \
     /etc/pki_glite/myCA/private \
     /etc/pki_glite/myCA/certs \
     /etc/pki_glite/myCA/newcerts \
     /etc/pki_glite/myCA/crl

cp /etc/pki/tls/openssl.cnf /etc/pki_glite/myCA/openssl.my.cnf
chmod 0600 /etc/pki_glite/myCA/openssl.my.cnf
touch /etc/pki_glite/myCA/index.txt
echo '01' > /etc/pki_glite/myCA/serial
cd /etc/pki_glite/myCA/
openssl req -config openssl.my.cnf -new -x509 -extensions v3_ca -keyout private/myca.key -out certs/myca.crt -days 1825 -subj '/C=FR/O=Grid5000/CN=fnancy.nancy.grid5000.fr'
chmod 0400 /etc/pki_glite/myCA/private/myca.key
# file (exemple)
sed -e 's/..\/..\/CA/./'\
      -e 's/cacert.pem/certs\/myca.crt/'\
	-e 's/cakey.pem/myca.key/'\
      -i /etc/pki_glite/myCA/openssl.my.cnf
cd /etc/pki_glite/myCA/
openssl req -config openssl.my.cnf -new -nodes -keyout private/server.key -out server.csr -days 365 -subj "/C=FR/O=Grid5000/OU=gLite G5K/CN=griffon-1.nancy.grid5000.fr"
chown root.root /etc/pki_glite/myCA/private/server.key
chmod 0400 /etc/pki_glite/myCA/private/server.key
cd /etc/pki_glite/myCA/
openssl ca -config openssl.my.cnf -policy policy_anything -out certs/server.crt -infiles server.csr
rm -f /etc/pki_glite/myCA/server.csr
# verif
openssl x509 -subject -issuer -enddate -noout -in /etc/pki_glite/myCA/certs/server.crt
openssl x509 -in certs/server.crt -noout -text
openssl verify -purpose sslserver -CAfile /etc/pki_glite/myCA/certs/myca.crt /etc/pki_glite/myCA/certs/server.crt
# un seul pem
cat certs/server.crt private/server.key > private/server-key-cert.pem
