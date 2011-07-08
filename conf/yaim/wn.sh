#!/bin/sh
TERM=xterm
chmod -R 600 /root/yaim
/opt/glite/yaim/bin/yaim -c -s /root/yaim/site-info.def -n glite-WN -n TORQUE_client
