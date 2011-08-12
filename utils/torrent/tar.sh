#!/bin/bash
sed -e 's/keepcache=0/keepcache=1/' -i /etc/yum.conf
cd /etc/yum.repos.d/
rm -rf *.repo
cd
cp cache.tgz /
cd /
tar xzf cache.tgz
