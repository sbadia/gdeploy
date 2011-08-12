#!/bin/sh
cd /etc/yum.repos.d/
rm -rf dag.repo* glite-* lcg-*
wget http://public.nancy.grid5000.fr/~sbadia/glite/repo.tgz -q
tar xzf repo.tgz
mv -f repo/* ./
rm -rf repo*
rm -f adobe.repo
yum update -q -y
yum install bittorrent -q -y
cd
wget http://fgrimoire.nancy.grid5000.fr/cache.tgz.torrent -q
bittorrent-console --max_upload_rate 0 cache.tgz.torrent > /tmp/debug.torrent
