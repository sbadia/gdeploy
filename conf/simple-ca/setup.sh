#!/bin/sh
# A lancer sur le voms
export PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin:$PATH"
export GLOBUS_LOCATION="/opt/globus"
export GPT_LOCATION="/opt/gpt"
source /root/yaim/site-info.def
echo "--> run gpt-postinstall"
$GPT_LOCATION/sbin/gpt-postinstall
echo "--> install simple-ca"
cp -f /opt/glite/yaim/etc/conf/simple-ca/setup-simple-ca $GLOBUS_LOCATION/setup/globus/setup-simple-ca
chmod +x $GLOBUS_LOCATION/setup/globus/setup-simple-ca
cp -f /opt/glite/yaim/etc/conf/simple-ca/globus_simple_ca_setup_template.tar.gz $GLOBUS_LOCATION/setup/globus/globus_simple_ca_setup_template.tar.gz
echo "--> run simple-ca"
$GLOBUS_LOCATION/setup/globus/setup-simple-ca -pass toto
HASH=`openssl x509 -noout -hash -in /root/.globus/simpleCA/cacert.pem`
echo "--> install it ($HASH)"
$GPT_LOCATION/sbin/gpt-build /root/.globus/simpleCA/globus_simple_ca_${HASH}_setup-0.18.tar.gz
$GPT_LOCATION/sbin/gpt-postinstall
$GLOBUS_LOCATION/setup/globus_simple_ca_${HASH}_setup/setup-gsi -default
echo "--> hostcert voms ($VOMS_HOST)"
$GLOBUS_LOCATION/bin/grid-cert-request -host $VOMS_HOST
cp -f /opt/glite/yaim/etc/conf/simple-ca/grid-ca-sign $GLOBUS_LOCATION/bin/grid-ca-sign
chmod +x $GLOBUS_LOCATION/bin/grid-ca-sign
cd /etc/grid-security/
$GLOBUS_LOCATION/bin/grid-ca-sign -in hostcert_request.pem -out hostsigned.pem -passin pass:toto
mv -f hostsigned.pem hostcert.pem
openssl x509 -text -noout -in hostcert.pem
mkdir voms
mv host* voms
echo "--> hostcert ce ($CE_HOST)"
$GLOBUS_LOCATION/bin/grid-cert-request -host $CE_HOST
cd /etc/grid-security/
$GLOBUS_LOCATION/bin/grid-ca-sign -in hostcert_request.pem -out hostsigned.pem -passin pass:toto
mv -f hostsigned.pem hostcert.pem
openssl x509 -text -noout -in hostcert.pem
mkdir ce
mv host* ce
echo "--> hostcert voms ($UI_HOST)"
$GLOBUS_LOCATION/bin/grid-cert-request -host $UI_HOST
cd /etc/grid-security/
$GLOBUS_LOCATION/bin/grid-ca-sign -in hostcert_request.pem -out hostsigned.pem -passin pass:toto
mv -f hostsigned.pem hostcert.pem
openssl x509 -text -noout -in hostcert.pem
mkdir ui
mv host* ui
cp -f voms/host* /etc/grid-security/
cd /root
echo "--> usercert nancy001"
$GLOBUS_LOCATION/bin/grid-cert-request
cd /root/.globus/
$GLOBUS_LOCATION/bin/grid-ca-sign -in usercert_request.pem -out signed.pem -passin pass:toto
mv signed.pem usercert.pem
echo "--> prepare export"
cd /etc/grid-security/
tar czf ui.tgz ui/*
tar czf ce.tgz ce/*
mv *.tgz /root/
cd /root/.globus/
tar cvzf nancy001.tgz user*
mv *.tgz /root/
cp /root/.globus/simpleCA/globus_simple_ca_${HASH}_setup-0.18.tar.gz /root/ca.tgz
cd /root/
scp ui.tgz root@$UI_HOST:
scp ca.tgz root@$UI_HOST:
# SET GPT_LOCATION and GLOBUS_LOCATION
ssh root@$UI_HOST "/opt/gpt/sbin/gpt-build /root/ca.tgz gcc32dbg"
ssh root@$UI_HOST "/opt/gpt/sbin/gpt-postinstall"
ssh root@$UI_HOST "/opt/globus/setup/globus_simple_ca_${HASH}_setup/setup-gsi -default"
scp ui.tgz root@$CE_HOST:
scp ca.tgz root@$CE_HOST:
ssh root@$CE_HOST "/opt/gpt/sbin/gpt-build /root/ca.tgz gcc32dbg"
ssh root@$CE_HOST "/opt/gpt/sbin/gpt-postinstall"
ssh root@$CE_HOST "/opt/globus/setup/globus_simple_ca_${HASH}_setup/setup-gsi -default"
