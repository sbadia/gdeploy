#!/bin/bash
# Little basic script to generate certs
# If ca doesn't exist the script create a ca cert.
# certif-ca.sh user Sebastien-BADIA /tmp
# certif-ca.sh server griffon-10.nancy.grid5000.fr /tmp

TYPE=$1
CN=$2
OUTDIR=$3

cd $OUTDIR

echo -e "\nType: \t$TYPE"
echo -e "CN: \t$CN"
echo -e "Out: \t$OUTDIR\n"

if [ ! -f ./cle-CA.key ]; then
  openssl genrsa -out cle-CA.key 1024
  openssl req -new -key cle-CA.key -subj '/C=FR/O=CaCertG5k/CN=G5K-CA' -out demande-CA.csr
  openssl x509 -in demande-CA.csr -out certif-CA.crt -req -signkey cle-CA.key -days 3650
  #touch index.txt
  #echo 'O1' > CA.srl
fi

if [ ! -f ./cle-Fncy.key ]; then
  openssl genrsa -out cle-Fncy.key 1024
  openssl req -new -key cle-Fncy.key -subj '/C=FR/O=Grid5000/CN=fnancy.nancy.grid5000.fr' -out demande-Fncy.csr
  openssl x509 -req -in demande-Fncy.csr -out certif-Fncy.crt -CA certif-CA.crt -CAkey cle-CA.key -CAcreateserial -CAserial CA.srl
fi

if [ $TYPE == "server" ]; then
  if [ ! -f ./cle-ssl.key ]; then
    openssl genrsa -out cle-ssl.key 1024
    openssl req -new -key cle-ssl.key -subj "/C=FR/O=Grid5000/OU=gLite G5K/CN=$CN" > demande-ssl.csr
  else
    echo "---> nothing to do !"
  fi
elif [ $TYPE == "user" ]; then
  if [ ! -f ./cle-user-sigca.key ]; then
    openssl genrsa -out cle-user-sigca.key 1024
    openssl req -new -key cle-user-sigca.key -subj "/C=FR/O=GRID5000/OU=PEOPLE/CN=$CN" -out demande-ssl.csr
  else
    echo "---> nothing to do !"
  fi
else
  echo $1 $2
fi

if [ -f ./demande-ssl.csr ]; then
  #openssl x509 -req -in demande-ssl.csr -out certif-ssl.crt -CA certif-CA.crt -CAkey cle-CA.key -CAcreateserial -CAserial CA.srl
  openssl x509 -req -in demande-ssl.csr -out certif-ssl.crt -CA certif-Fncy.crt -CAkey cle-Fncy.key -CAcreateserial -CAserial Fncy.srl
  mkdir $CN

  if [ $TYPE == "server" ]; then
    mv certif-ssl.crt ./$CN/hostcert.pem
    mv cle-ssl.key ./$CN/hostkey.pem
  elif [ $TYPE == "user" ]; then
    mv certif-ssl.crt ./$CN/usercert.pem
    mv cle-user-sigca.key ./$CN/userkey.pem
  else
    echo "soucis server/user"
  fi
fi
rm -f demande-ssl.csr
#if [ -f ./cle-CA.key ]; then
#  mkdir CA
#  # mode 600 -> /etc/ssl/private/
#  cp cle-CA.key ./CA/ca-cert-glite.key
#  # mode 644 -> /etc/ssl/certs/
#  cp certif-CA.crt ./CA/ca-cert-glite.cert
#fi
