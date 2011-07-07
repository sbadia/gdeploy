#!/bin/sh
set -x
set -e
export PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin:$PATH"
export GLOBUS_LOCATION="/opt/globus"
export GPT_LOCATION="/opt/gpt"
HASH=`cat /root/hash`
cd /root
$GPT_LOCATION/sbin/gpt-build globus_simple_ca_${HASH}_setup-0.18.tar.gz gcc32dbg
$GPT_LOCATION/sbin/gpt-postinstall
$GLOBUS_LOCATION/setup/globus_simple_ca_${HASH}_setup/setup-gsi -default
