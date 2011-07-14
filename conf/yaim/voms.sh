#!/bin/sh
export TERM="xterm"
export SHELL="/bin/bash"
export SSH_TTY="/dev/pts/0"
chmod -R 600 /root/yaim
/opt/glite/yaim/bin/yaim -c -s /root/yaim/site-info.def -n VOMS
