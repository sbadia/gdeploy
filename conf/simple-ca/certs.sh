#!/bin/sh
# A lancer sur le voms
#set -x
#set -e
CE_HOST=$1
UI_HOST=$2
export PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin:$PATH"
export GLOBUS_LOCATION="/opt/globus"
export GPT_LOCATION="/opt/gpt"
export TERM="xterm"
sleep 2
cd /etc/grid-security/
mv -f host* voms
echo "--> hostcert ce ($CE_HOST)"
cd /root
$GLOBUS_LOCATION/bin/grid-cert-request -host $CE_HOST
cd /etc/grid-security/
$GLOBUS_LOCATION/bin/grid-ca-sign -in hostcert_request.pem -out hostsigned.pem -passin pass:toto
mv -f hostsigned.pem hostcert.pem
openssl x509 -text -noout -in hostcert.pem
mkdir ce
mv host* ce
echo "--> hostcert voms ($UI_HOST)"
cd /root
$GLOBUS_LOCATION/bin/grid-cert-request -host $UI_HOST
cd /etc/grid-security/
$GLOBUS_LOCATION/bin/grid-ca-sign -in hostcert_request.pem -out hostsigned.pem -passin pass:toto
mv -f hostsigned.pem hostcert.pem
openssl x509 -text -noout -in hostcert.pem
mkdir ui
mv host* ui
cp -f voms/host* /etc/grid-security/
cd /root
#echo "--> usercert nancy001"
#$GLOBUS_LOCATION/bin/grid-cert-request
#cd /root/.globus/
#$GLOBUS_LOCATION/bin/grid-ca-sign -in usercert_request.pem -out signed.pem -passin pass:toto
#mv signed.pem usercert.pem
echo "--> prepare export"
cd /etc/grid-security/
tar czf ui.tgz ui/*
tar czf ce.tgz ce/*
mv *.tgz /root/
echo "--> do some clean for next site"
rm -rf ./ui/
rm -rf ./ce/
#cd /root/.globus/
#tar cvzf nancy001.tgz user*
#mv *.tgz /root/
exit 0
