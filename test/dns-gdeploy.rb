#!/usr/bin/env ruby
# Author:: Sebastien Badia (<sebastien.badia@inria.fr>)
# Date:: Tue Jun 21 16:36:33 +0200 2011
# Little basic script to generate dns conf for gLite

begin
  require 'optparse'
  require 'ostruct'
rescue LoadError
end

DIR = File.expand_path(File.dirname(__FILE__))

$cfg = OpenStruct::new
$cfg.nodes = []
$cfg.verbose = false


if defined?($PROGRAM_NAME)
  progname = File::basename($PROGRAM_NAME)
else
  progname = "dns-gdeploy"
end

def nodes_file(file)
  begin
    return IO::read(file).split("\n").sort.uniq
  rescue
    return []
  end
end

opts = OptionParser::new do |opts|
  opts.version = "#{progname} v0.1 2011-06-21 16:36:33 sbadia"
  opts.release = nil
  opts.program_name = progname
  opts.banner = "Usage: #{progname} [options]"
  opts.separator 'Contact: Sebastien Badia <sebastien.badia@inria.fr>'
  opts.separator ''
  opts.separator 'General options:'
  opts.on('-v', '--verbose', 'Verbose mode') { verbose = true }
  opts.on('-f', '--file', 'File nodes') { |f| $cfg.nodes = nodes_file(f) }
  opts.separator ''
end

begin
  opts.parse!(ARGV)
rescue OptionParser::ParseError => pe
  opts.warn pe
  puts opts
  exit 1
end

if $cfg.nodes.empty?
  if ENV['OAR_NODE_FILE'].nil?
    jputs("No nodes","$OAR_NODE_FILE ?")
    exit(1)
  else
    $nodes = nodes_file(ENV['OAR_NODE_FILE'])
  end
else
  $nodes = $cfg.nodes
end

if $nodes.empty?
  jputs("No nodes","See help -h")
  exit(1)
end

if $nodes.length < 6 :
  if $nodes.length < 2 :
    rputs("Err","Min 2 nodes")
    exit(0)
  else
    bdii = cehost = batch = se = $nodes[0]
    wn = $nodes[1]
  end
elsif $nodes.length > 6 :
  bdii = $nodes[0]
  cehost = $nodes[1]
  batch = $nodes[2]
  se = $nodes[3]
  voms = $nodes[4]
  ui = $nodes[5]
  wn = $nodes.last($nodes.length - 6)
else
  wn = $nodes.first($nodes.length - 1)
  bdii = cehost = batch = se = $nodes.last
end

sname = $nodes.first.split('.').fetch(1)

def ip(node)
  host = `/usr/bin/host #{node} 2>/dev/null`
  if host =~/([0-9]{1,3}.){3}([0-9]{1,3})/
    return "#{$~}"
  end
end # def:: ip(node)

def conf_mararc(bdii,sname)
  f = File.new("#{DIR}/../conf/mararc", "w")
  f.puts <<-EOF
csv2 = {}
ipv4_bind_addresses = "#{ip(bdii)}"
ipv4_alias = {}
hide_disclaimer = "YES"
chroot_dir = "/etc/maradns"
recursive_acl = "#{ip(bdii).split('.').fetch(0)}.#{ip(bdii).split('.').fetch(1)}.#{ip(bdii).split('.').fetch(2)}.0/16"
ipv4_alias["G5KDNS"] = "131.254.203.235"
upstream_servers = {}
upstream_servers["."] = "G5KDNS"
csv2["#{sname}.fr."] = "db.#{sname}.fr"
EOF
  f.close
end # def:: conf_mararc(bdii,sname)

def conf_zone(bdii,cehost,batch,se,voms,ui,wn,sname)
  f = File.new("#{DIR}/../conf/db.#{sname}.fr", "w")
  f.puts <<-EOF
bdii.#{sname}.fr. A #{ip(bdii)}
bdii.#{sname}.fr. FQDN4 #{ip(bdii)}
ce.#{sname}.fr. A #{ip(cehost)}
ce.#{sname}.fr. FQDN4 #{ip(cehost)}
batch.#{sname}.fr. A #{ip(batch)}
batch.#{sname}.fr. FQDN4 #{ip(batch)}
se.#{sname}.fr. A #{ip(se)}
se.#{sname}.fr. FQDN4 #{ip(se)}
voms.#{sname}.fr. A #{ip(voms)}
voms.#{sname}.fr. FQDN4 #{ip(voms)}
ui.#{sname}.fr. A #{ip(ui)}
ui.#{sname}.fr. FQDN4 #{ip(ui)}
#{sname}.fr. A #{ip(ui)}
#{sname}.fr. FQDN4 #{ip(ui)}
#{(wn.length - 1).times { |a|
"node-#{a}.#{sname}.fr A #{
	for i in wn
	  "#{ip(i)}"
	end
}"
"node-#{a}.#{sname}.fr FQDN4 #{
	for i in wn
	  "#{ip(i)}"
	end
}"
}}
EOF
  f.close
end # def:: conf_zone(bdii,cehost,batch,se,voms,ui,wn,sname)


conf_mararc(bdii,sname)
conf_zone(bdii,cehost,batch,se,voms,ui,wn,sname)
