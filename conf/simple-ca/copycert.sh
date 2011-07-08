#!/bin/sh
SITE=$1
TYPE=$2
cp -r /opt/glite/yaim/etc/conf/$SITE/$TYPE.tgz /etc/grid-security
cd /etc/grid-security/
tar xzf $TYPE.tgz
mv $TYPE/* ./
rm -rf $TYPE
rm -f $TYPE.tgz
