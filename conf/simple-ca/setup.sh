#!/bin/sh
# A lancer sur le voms configuration du ca et preparation export
#set -x
#set -e
VOMS_HOST=`hostname -f`
export PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin:$PATH"
export GLOBUS_LOCATION="/opt/globus"
export GPT_LOCATION="/opt/gpt"
export TERM="xterm"
echo "--> run gpt-postinstall"
sleep 2
$GPT_LOCATION/sbin/gpt-postinstall
echo "--> install simple-ca"
cp -f /opt/glite/yaim/etc/conf/simple-ca/setup-simple-ca $GLOBUS_LOCATION/setup/globus/setup-simple-ca
chmod +x $GLOBUS_LOCATION/setup/globus/setup-simple-ca
cp -f /opt/glite/yaim/etc/conf/simple-ca/globus_simple_ca_setup_template.tar.gz $GLOBUS_LOCATION/setup/globus/globus_simple_ca_setup_template.tar.gz
echo "--> run simple-ca"
$GLOBUS_LOCATION/setup/globus/setup-simple-ca -pass toto
HASH=`openssl x509 -noout -hash -in /root/.globus/simpleCA/cacert.pem`
echo "--> install it ($HASH)"
cd /root/.globus/simpleCA/
$GPT_LOCATION/sbin/gpt-build globus_simple_ca_${HASH}_setup-0.18.tar.gz
$GPT_LOCATION/sbin/gpt-postinstall
$GLOBUS_LOCATION/setup/globus_simple_ca_${HASH}_setup/setup-gsi -default
echo "--> hostcert voms ($VOMS_HOST)"
cd /root
$GLOBUS_LOCATION/bin/grid-cert-request -host $VOMS_HOST
cp -f /opt/glite/yaim/etc/conf/simple-ca/grid-ca-sign $GLOBUS_LOCATION/bin/grid-ca-sign
chmod +x $GLOBUS_LOCATION/bin/grid-ca-sign
cd /etc/grid-security/
$GLOBUS_LOCATION/bin/grid-ca-sign -in hostcert_request.pem -out hostsigned.pem -passin pass:toto
mv -f hostsigned.pem hostcert.pem
openssl x509 -text -noout -in hostcert.pem
mkdir voms
cp -f host* voms
cp -f /root/.globus/simpleCA/globus_simple_ca_${HASH}_setup-0.18.tar.gz /root/globus_simple_ca_${HASH}_setup-0.18.tar.gz
cd /root
echo $HASH > hash
openssl ca -config /root/.globus/simpleCA/grid-ca-ssl.conf -gencrl -crldays 365 -out /etc/grid-security/certificates/${HASH}.r0 -key toto
exit 0
