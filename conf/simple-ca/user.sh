#!/bin/sh
# A lancer sur l'ui, sert à configurer automatiquement le cert utilisateur.
# user.sh <voms>
#set -x
#set -e
VOMS_HOST=$1
export PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin:$PATH"
export GLOBUS_LOCATION="/opt/globus"
export GPT_LOCATION="/opt/gpt"
export TERM="xterm"
echo "--> usercert toto1"
adduser toto1
su -c "$GLOBUS_LOCATION/bin/grid-cert-request -nopw -cn toto1" -l toto1
cd /home/toto1/.globus/
echo "--> prepare export and sign"
scp -o StrictHostKeyChecking=no -o BatchMode=yes user* root@$VOMS_HOST:
ssh -o StrictHostKeyChecking=no -o BatchMode=yes root@$VOMS_HOST "export GLOBUS_LOCATION='/opt/globus' && $GLOBUS_LOCATION/bin/grid-ca-sign -in usercert_request.pem -out signed.pem -passin pass:toto"
ssh -o StrictHostKeyChecking=no -o BatchMode=yes root@$VOMS_HOST "mv signed.pem usercert.pem"
ssh -o StrictHostKeyChecking=no -o BatchMode=yes root@$VOMS_HOST "/opt/glite/sbin/voms-db-deploy.py add-admin --vo grid5000 --cert usercert.pem"
rm -rf user*
scp -o StrictHostKeyChecking=no -o BatchMode=yes root@$VOMS_HOST:user* ./
chown -R toto1:toto1 /home/toto1
chmod 600 userkey.pem
echo 'toto1' | passwd --stdin toto1
exit 0
