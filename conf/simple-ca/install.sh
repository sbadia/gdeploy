#!/bin/sh
export PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin:$PATH"
export GLOBUS_LOCATION="/opt/globus"
export GPT_LOCATION="/opt/gpt"
$GPT_LOCATION/sbin/gpt-build /root/ca.tgz gcc32dbg
$GPT_LOCATION/sbin/gpt-postinstall
$GLOBUS_LOCATION/setup/globus_simple_ca_*_setup/setup-gsi -default
