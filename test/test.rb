#!/usr/bin/ruby -w

require 'net/ssh/multi'

$nodes = ["graphene-109.nancy.grid5000.fr","graphene-107.nancy.grid5000.fr"]
puts $nodes

Net::SSH::Multi.start do |session|
  session.on_error = :warn
  $nodes.each do |node|
    session.use "root@#{node}" if $nodes[node].nil?
  end
  session.exec("mkdir -p /root/yaim && rm -f /etc/yum.repos.d/dag.repo* && wget -P /etc/yum.repos.d/ http://public.nancy.grid5000.fr/~sbadia/glite/repo/dag.repo -q && yum update -q -y")
  session.exec("uptime")
  session.loop
end
