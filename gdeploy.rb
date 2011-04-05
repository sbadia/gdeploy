#!/usr/bin/ruby -w

# = gDeploy
# :title: Glite Deployment on Grid'5000
# https://www.grid5000.fr/
#
#begin
  require 'yaml'
  require 'optparse'
  require 'ostruct'
  require 'net/scp'
  require 'net/ssh'
  require 'net/ssh/multi'
  require 'misc/progressbar'
#rescue LoadError

#end

### Global
$cfg = OpenStruct::new
$cfg.confnodes = []
$cfg.gnodes = []
$cfg.debug = false
$cfg.ssh_user = ENV['SSH_USER'] || 'root'
$cfg.ssh_password = ENV['SSH_PASSWORD'] || 'grid5000'
$cfg.ssh_keyfile = "#{ENV['HOME']}/.ssh/authorized_keys"
$cfg.user = ENV['USER']
$cfg.config = false
$cfg.sendconf = false
$cfg.verbose = false
$cfg.pbar = false

$tstart = Time::now
DIR = File.expand_path(File.dirname(__FILE__))


# Nodes from file
def nodes_file(file)
  begin
    return IO::read(file).split("\n").sort.uniq
  rescue
    return []
  end
end

if defined?($PROGRAM_NAME)
  progname = File::basename($PROGRAM_NAME)
else
  progname = "gdeploy"
end

opts = OptionParser::new do |opts|
  opts.version = "#{progname} v0.2 2011-03-07 12:02:09 sbadia"
  opts.release = nil
  opts.program_name = progname
  opts.banner = "Usage: #{progname} [options]"
  opts.separator 'Contact: Sebastien Badia <sebastien.badia@inria.fr>'
  opts.separator ''
  opts.separator 'General options:'
  opts.on('-m', '--machine MACHINE', 'Node to run on') { |n| $cfg.confnodes << n }
  opts.on('-f', '--file MACHINELIST', 'Files containing list of nodes')  { |f| $cfg.confnodes = nodes_file(f) }
  opts.on('-c', '--config', 'Create config files') { $cfg.config = true }
  opts.on('-s', '--send', 'Send and configure nodes') { $cfg.sendconf = true }
  opts.on('-v', '--verbose', 'Verbose mode') { $cfg.verbose = true }
  opts.on('-p', '--pbar', 'Use progressbar') { $cfg.pbar = true }
  opts.on('-g', '--glite', 'Select gLite entities') { |g| $cfg.gnodes << g }
  opts.separator ''
end

begin
  opts.parse!(ARGV)
rescue OptionParser::ParseError => pe
  opts.warn pe
  puts opts
  exit 1
end

extinction = Proc.new{
  puts "Received extinction request..."
}

%w{INT TERM}.each do |signal|
  Signal.trap( signal ) do
      extinction.call
    exit(1)
  end
end

def send_jabber(message)
  Restfully::Session.new(:base_uri => "https://api.grid5000.fr/2.0/grid5000") do |root, session|
  session.post("/sid/notifications",
	{:body => "Gdeploy: on #{SITE} launched by #{$cfg.user} : #{message}",
	 :to => ["xmpp:#{$cfg.user}@jabber.grid5000.fr"]},
	 :headers => {:content_type => 'application/json'}
  )
  end
end

## Go!
if $cfg.confnodes.empty?
  if ENV['OAR_NODE_FILE'].nil?
    puts "No nodes/$OAR_NODE_FILE ?"
    exit(1)
  else
    $nodes = nodes_file(ENV['OAR_NODE_FILE'])
  end
else
  $nodes = $cfg.confnodes
end

if $nodes.empty?
  puts "No nodes ?"
  puts "See help -h"
  exit(1)
end

# Site name
sname = $nodes.first.split('.').fetch(1)

# Autres clusters dans la vo
def clusters(nodes)
  cluster = []
  nodes.each do |n|
    cluster << n.gsub(/-.*/,'').upcase
    cluster << "|"
end
  return cluster.uniq
end

# Attribution des noeuds
if $nodes.length < 4 :
  if $nodes.length < 2 :
    puts "Min 2 nodes"
    exit(0)
  else
    bdii = cehost = batch = se = $nodes[0]
    wn = $nodes[1]
  end
elsif $nodes.length > 4 :
  bdii = $nodes[0]
  cehost = $nodes[1]
  batch = $nodes[2]
  se = $nodes[3]
  wn = $nodes.last($nodes.length - 4)
else
  wn = $nodes.first($nodes.length - 1)
  bdii = cehost = batch = se = $nodes.last
end

if $cfg.verbose == true :
  puts "Nodes :\t#{$nodes.length}"
  puts "Bdii host :\t#{bdii}"
  puts "Batch server :\t#{batch}"
  puts "Ce host :\t#{cehost}"
  puts "Se host :\t#{se}"
  puts "Workers Nodes:"
  wn.each{|n| puts "\t\t#{n}\n" }
else
  puts "\tNo visual"
end

serv = { "bdii" => bdii, "batch" => batch, "cehost" => cehost, "se" => se }
utils = [ 'users', 'groups', 'wn-list' ]

if $cfg.config == true :
begin
 Dir::mkdir("#{DIR}/conf/", 0755)
rescue
end
end

def conf_bdii(bdii, sname, cehost)
  f = File.new("#{DIR}/site-info-bdii.def", "w")
  f.puts <<-EOF
## Site-info.def Bdii
SITE_BDII_HOST="#{bdii}"
SITE_NAME=#{sname}
SITE_LOC="#{sname.capitalize}, France"
SITE_WEB="https://www.grid5000.fr/"
SITE_LAT="48,7"
SITE_LONG="6,2"
SITE_EMAIL=root@localhost
SITE_SECURITY_EMAIL=root@localhost
SITE_SUPPORT_EMAIL=root@localhost
SITE_DESC="Grid5000 School - gLite"
SITE_OTHER_GRID="#{clusters($nodes)}"
CE_HOST="#{cehost}"
BDII_REGIONS="CE SITE_BDII"
BDII_CE_URL="ldap://#{cehost}:2170/mds-vo-name=resource,o=grid"
BDII_SITE_BDII_URL="ldap://#{bdii}:2170/mds-vo-name=resource,o=grid"
EOF
  f.close
end

def conf_batch(batch, cehost, sname)
  f = File.new("#{DIR}/site-info-batch.def", "w")
  f.puts <<-EOF
## Site-info.def Batch
BATCH_SERVER="#{batch}"
CE_HOST="#{cehost}"
CE_SMPSIZE=`grep -c processor /proc/cpuinfo`
VOS="#{sname}"
QUEUES="default"
DEFAULT_GROUP_ENABLE="#{sname}"
USERS_CONF=/opt/glite/yaim/etc/conf/users.conf
GROUPS_CONF=/opt/glite/yaim/etc/conf/groups.conf
WN_LIST=/opt/glite/yaim/etc/conf/wn-list.conf
CONFIG_MAUI="yes"
EOF
  f.close
end

def conf_wn(bdii, se, sname, batch, cehost)
  f = File.new("#{DIR}/site-info-wn.def", "w")
  f.puts <<-EOF
## Site-info.def Batch
BDII_HOST="#{bdii}"
SE_LIST="#{se}"
SITE_NAME=#{sname}
USERS_CONF=/opt/glite/yaim/etc/conf/users.conf
GROUPS_CONF=/opt/glite/yaim/etc/conf/groups.conf
WN_LIST=/opt/glite/yaim/etc/conf/wn-list.conf
VOS=#{sname}
BATCH_SERVER=#{batch}
CE_HOST=#{cehost}
CE_SMPSIZE=`grep -c processor /proc/cpuinfo`
VO_#{sname.upcase}_SW_DIR=/opt/vo_software/#{sname}
VO_#{sname.upcase}_VOMS_CA_DN="/C=FR/O=Grid5000/CN=G5k-CA"
VO_#{sname.upcase}_VOMSES="#{sname} glite-io.grid5000.fr 15000 /C=FR/O=Grid5000/OU=#{sname} SCAI/CN=host/glite-io.grid5000.fr #{sname}"
EOF
  f.close
end

def conf_cehost(sname, cehost, batch, se)
  f = File.new("#{DIR}/site-info-ce.def", "w")
  f.puts <<-EOF
## Site-info.def Ce
SITE_NAME=#{sname}
CE_HOST="#{cehost}"
BATCH_SERVER="#{batch}"
USERS_CONF=/opt/glite/yaim/etc/conf/users.conf
GROUPS_CONF=/opt/glite/yaim/etc/conf/groups.conf
WN_LIST=/opt/glite/yaim/etc/conf/wn-list.conf
JAVA_LOCATION=/usr/java/default
JOB_MANAGER=pbs
CE_BATCH_SYS=pbs
BATCH_VERSION=torque-2.3.6-2
BATCH_BIN_DIR=/usr/bin
BATCH_LOG_DIR=/var/spool/pbs/
BATCH_SPOOL_DIR=/var/spool/pbs/
CREAM_CE_STATE="Special"
BLPARSER_HOST=#{cehost}
BLAH_JOBID_PREFIX="cream_"
BLPARSER_WITH_UPDATER_NOTIFIER="false"
MYSQL_PASSWORD=koala
APEL_DB_PASSWORD="APELDB_PWD"
APEL_MYSQL_HOST="#{cehost}"
CE_OS_ARCH=x86_64  # uname -i
CE_OS=`lsb_release -i | cut -f2`
CE_OS_RELEASE=`lsb_release -r | cut -f2`
CE_OS_VERSION=`lsb_release -c | cut -f2`
CE_CPU_MODEL=Xeon
CE_CPU_VENDOR=GenuineIntel
CE_CPU_SPEED=2000  # grep MHz /proc/cpuinfo
CE_MINPHYSMEM=16000          # grep MemTotal /proc/meminfo
CE_MINVIRTMEM=4096          # grep SwapTotal /proc/meminfo
CE_OUTBOUNDIP=TRUE
CE_INBOUNDIP=FALSE
CE_RUNTIMEENV="
  GLITE-3_2_0
  R-GMA"
CE_CAPABILITY="none"
CE_OTHERDESCR="Cores=4" #grep -c physical id.*: 0 /proc/cpuinfo
CE_PHYSCPU=2      #grep -c core id.*: 0 /proc/cpuinfo
CE_LOGCPU=1       #grep -c processor /proc/cpuinfo
CE_SMPSIZE=1      #grep -c processor /proc/cpuinfo
CE_SI00=1592
CE_SF00=1927
CE_OTHER_DESCR="Cores=1, Benchmark=1.11-HEP-SPEC06"
SE_LIST="#{se}"
SE_MOUNT_INFO_LIST="none"
VOS="#{sname}"
QUEUES="default"
DEFAULT_GROUP_ENABLE="#{sname}"
ACCESS_BY_DOMAIN=false
CREAM_DB_USER=creamdb
CREAM_DB_PASSWORD="secretPassword"
BLPARSER_HOST=#{cehost}
BLP_PORT=33333
CREAM_PORT=56565
CEMON_HOST=#{cehost}
EOF
  f.close
end

# <user_id>:<username>:<group_id>:<group_name>:<vo_name>:<special_user_type>:
def conf_users(group,sname)
  f = File.new("#{DIR}/conf/users.conf", "w")
  3.times { |a| f.write "#{a + 10410}:sgm#{sname}#{a +1}:1390,1395:#{group}sgm,#{group}:#{sname}:sgm:\n" }
  10.times { |x| f.write "#{x + 10420}:#{sname}00#{x + 1}:1395:#{group}:#{sname}::\n" }
  f.close
end

# "/<vo>"::::
# "/<vo>/<group>"::::
# "/<vo>/<group>/ROLE=<role>::::
# "/<vo>/<group>/ROLE=<role>:::<special_user_type>:
def conf_groups(sname)
  f = File.new("#{DIR}/conf/groups.conf", "w")
  f.puts <<-EOF
"/#{sname}"::::
"/#{sname}/ROLE=#{sname.upcase}"::::
"/#{sname}/ROLE=VO-Admin":::sgm:
EOF
  f.close
end

def list_wn(wn)
  f = File.new("#{DIR}/conf/wn-list.conf", "w")
    for i in wn
      f.write "#{i}\n"
    end
  f.close
end

def export_nfs()
  f = File.new("#{DIR}/export", "w")
  f.puts <<-EOF
/var/spool/pbs/server_priv/accounting    *(rw,async,no_root_squash)
/var/spool/pbs/server_logs               *(rw,async,no_root_squash)
EOF
  f.close
end

def queue_config()
  f = File.new("#{DIR}/queue.conf", "w")
  f.puts <<-EOF
#!/bin/sh
qmgr << EOF
set server scheduling = True
set server acl_hosts = #{batch}
#{$nodes.each do |node| "set server acl_host += #{node}"end}
set server managers = root@`hostname -f`
set server operators = root@`hostname -f`
set server default_queue = default
set server scheduler_iteration = 600
set server node_check_rate = 150
set server tcp_timeout = 12
set server poll_jobs = False
set server log_level = 3\nEOF
EOF
  f.close
end

def create_conf()
 conf_bdii(bdii, sname, cehost)
 conf_batch(batch, cehost, sname)
 conf_wn(bdii, se, sname, batch, cehost)
 conf_users(sname,sname)
 conf_groups(sname)
 list_wn(wn)
end

if $cfg.config == true :
  if $cfg.pbar == true :
    pbar = ProgressBar.new("Conf", 7)
    pbar.inc
    conf_bdii(bdii, sname, cehost)
    pbar.inc
    conf_batch(batch, cehost, sname)
    pbar.inc
    conf_wn(bdii, se, sname, batch, cehost)
    pbar.inc
    conf_users(sname,sname)
    pbar.inc
    conf_groups(sname)
    pbar.inc
    list_wn(wn)
    pbar.finish
  elsif $cfg.verbose == true :
    puts "\t\tgLite conf\t->\t[Ok]\n\n"
    if $cfg.gnodes.include?("bdii") == true:
      conf_bdii(bdii, sname, cehost)
    elsif $cfg.gnodes.include?("batch") == true:
      conf_batch(batch, cehost, sname)
    elsif $cfg.gnodes.include?("wn") == true:
      conf_wn(bdii, se, sname, batch, cehost)
    else
#      create_conf()
       conf_bdii(bdii, sname, cehost)
       conf_batch(batch, cehost, sname)
       conf_wn(bdii, se, sname, batch, cehost)
       conf_users(sname,sname)
       conf_groups(sname)
       list_wn(wn)
       conf_cehost(sname, cehost, batch, se)
    end
  end
else
  puts "\tNo config created\n"
end

if $cfg.sendconf == true :
  if $cfg.pbar == true:
    pbarc = ProgressBar.new("Maj", 5)
  end

  #puts $nodes
  Net::SSH::Multi.start do |session|
    session.on_error = :warn
    $nodes.each do |node|
      session.use "root@#{node}" #if $nodes[node].nil?
      if $cfg.verbose == true:
        puts "*** Update #{node}"
      elsif $cfg.pbar == true :
        pbarc.inc
      end
    end
    session.exec('mkdir -p /root/yaim && rm -f /etc/yum.repos.d/dag.repo* && wget -P /etc/yum.repos.d/ http://public.nancy.grid5000.fr/~sbadia/glite/repo/dag.repo -q && yum update -q -y')
    session.exec("uptime")
    session.loop
  end

  if $cfg.pbar == true:
    pbarc.finish
    pbarb = ProgressBar.new("Bdii", 4)
  end

### Bdii
#
  Net::SSH.start(serv.fetch("bdii"), 'root') do |ssh|
    if $cfg.verbose == true:
      puts "*** intall bdii"
    elsif $cfg.pbar == true :
      pbarb.inc
    end
    ssh.exec!('wget -P /etc/yum.repos.d/ http://public.nancy.grid5000.fr/~sbadia/glite/repo/glite-BDII.repo -q && yum install glite-BDII -q -y')
  if $cfg.pbar == true:
    pbarb.inc
  end
    ssh.scp.upload!("#{DIR}/site-info-bdii.def","/root/yaim/site-info.def") do |ch, name, sent, total|
      #print "\r#{name}: #{(sent.to_f * 100 / total.to_f).to_i}%\n"
    end
    if $cfg.verbose == true:
      puts "*** configure"
    elsif $cfg.pbar == true :
      pbarb.inc
    end
    ssh.exec!('chmod -R 600 /root/yaim && /opt/glite/yaim/bin/yaim -c -s /root/yaim/site-info.def -n glite-BDII_site -d 1')
  end
   if $cfg.pbar == true:
    pbarb.finish
    pbaro = ProgressBar.new("Batch", 9)
   elsif $cfg.verbose == true:
     puts "*** intall batch"
   end

#### Batch
#
  Net::SSH.start(serv.fetch("batch"), 'root') do |ssh|
    if $cfg.pbar == true:
      pbaro.inc
    end
    ssh.exec!('wget -P /etc/yum.repos.d/ http://public.nancy.grid5000.fr/~sbadia/glite/repo/glite-TORQUE_server.repo -q && yum install glite-TORQUE_server -q -y')
    ssh.scp.upload!("#{DIR}/site-info-batch.def","/root/yaim/site-info.def") do |ch, name, sent, total|
      #print "\r#{name}: #{(sent.to_f * 100 / total.to_f).to_i}%\n"
    end
    if $cfg.verbose == true:
      puts "*** configure"
    elsif $cfg.pbar == true:
      pbaro.inc
    end
  end
  begin
    Net::SCP.start(serv.fetch("batch"), 'root') do |scp|
      scp.upload!("#{DIR}/conf", "/opt/glite/yaim/etc", :recursive => true)
    end
  rescue
    puts "Erreur scp conf batch"
    puts serv.fetch("batch")
  end
  Net::SSH.start(serv.fetch("batch"), 'root') do |ssh|
    ssh.exec!('chmod -R 600 /root/yaim && /opt/glite/yaim/bin/yaim -c -s /root/yaim/site-info.def -n glite-TORQUE_server -d 1')
  end

  if $cfg.pbar == true:
    pbaro.finish
  end

### Worker nodes
#

  puts wn
  Net::SSH::Multi.start do |session|
    session.on_error = :warn
    wn.each do |node|
      session.use "root@#{node}" #if $nodes[node].nil?
      if $cfg.verbose == true:
        puts "*** Install #{node}"
      elsif $cfg.pbar == true :
        pbarc.inc
      end
    end
    session.exec("wget -P /etc/yum.repos.d/ http://public.nancy.grid5000.fr/~sbadia/glite/repo/glite-WN.repo -q && wget -P /etc/yum.repos.d/ http://public.nancy.grid5000.fr/~sbadia/glite/repo/glite-TORQUE_client.repo -q && wget -P /etc/yum.repos.d/ http://public.nancy.grid5000.fr/~sbadia/glite/repo/lcg-CA.repo -q  && yum groupinstall glite-WN -q -y && yum install glite-TORQUE_client lcg-CA -q -y --nogpgcheck && sed '1iexit 0' -i /usr/sbin/fetch-crl")
    session.exec("uptime")
    # Hack immonde pour la fct_crl (certif revocation leak)
    #session.exec("sed '1iexit 0' -i /usr/sbin/fetch-crl")
    session.loop
  end


  wn.each do |wo|
    Net::SSH.start(wo, 'root') do |ssh|
      ssh.scp.upload!("#{DIR}/site-info-wn.def","/root/yaim/site-info.def")
    end
    if $cfg.pbar == true:
      pbaro.inc
    end
    if $cfg.verbose == true:
      puts "*** configure"
    end
    begin
      Net::SCP.start("#{wo}", 'root') do |scp|
        scp.upload!("#{DIR}/conf/", "/opt/glite/yaim/etc/", :recursive => true)
      end
    rescue
      puts "Erreur scp conf wn : #{wo}"
    end
  end
  Net::SSH::Multi.start do |session|
    session.on_error = :warn
    wn.each do |node|
      session.use "root@#{node}"
    end
    session.exec('chmod -R 600 /root/yaim && /opt/glite/yaim/bin/yaim -c -s /root/yaim/site-info.def -n glite-WN -n TORQUE_client -d 1')
  end
  if $cfg.verbose == true:
   puts "*** intall wn ok."
  end

### Computing element
#
  Net::SSH.start(serv.fetch("cehost"), 'root') do |ssh|
    if $cfg.pbar == true:
      pbaro.inc
    end
    ssh.exec!('wget -P /etc/yum.repos.d/ http://public.nancy.grid5000.fr/~sbadia/glite/repo/glite-CREAM.repo -q && wget -P /etc/yum.repos.d/ http://public.nancy.grid5000.fr/~sbadia/glite/repo/glite-TORQUE_utils.repo -q && wget -P /etc/yum.repos.d/ http://public.nancy.grid5000.fr/~sbadia/glite/repo/lcg-CA.repo -q')
    ssh.exec!('yum install glite-CREAM glite-TORQUE_utils lcg-CA -q -y --nogpgcheck')
    ssh.scp.upload!("#{DIR}/site-info-batch.def","/root/yaim/site-info.def") do |ch, name, sent, total|
      #print "\r#{name}: #{(sent.to_f * 100 / total.to_f).to_i}%\n"
    end
    if $cfg.verbose == true:
      puts "*** configure"
    elsif $cfg.pbar == true:
      pbaro.inc
    end
  end
  begin
    Net::SCP.start(serv.fetch("cehost"), 'root') do |scp|
      scp.upload!("#{DIR}/conf", "/opt/glite/yaim/etc", :recursive => true)
    end
  rescue
    puts "Erreur scp conf Ce"
    puts serv.fetch("cehost")
  end
  Net::SSH.start(serv.fetch("cehost"), 'root') do |ssh|
    ssh.exec!('mkdir -p /var/spool/pbs/server_priv/accounting')
    ssh.exec!("mount #{serv.fetch("batch")}:/var/spool/pbs/server_priv/accounting /var/spool/pbs/server_priv/accounting")
    ssh.exec!("mount #{serv.fetch("batch")}:/var/spool/pbs/server_logs /var/spool/pbs/server_logs")
    ssh.exec!('chmod -R 600 /root/yaim && /opt/glite/yaim/bin/yaim -c -s /root/yaim/site-info.def -n glite-creamCE -n glite-TORQUE_utils -d 1')
    ssh.exec!('/opt/glite/yaim/bin/yaim -f -s /root/yaim/site-info.def -f config_cream_blparser')
  end

  if $cfg.pbar == true:
    pbaro.finish
  end

### Ui
#

### Lfc se
#

else
  puts "\tNo send\n"
end
