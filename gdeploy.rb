#!/usr/bin/ruby -w

#begin
  require 'yaml'
  require 'optparse'
  require 'ostruct'
  require 'net/scp'
  require 'net/ssh'
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
 Dir::mkdir("/home/#{$cfg.user}/conf/", 0755)
rescue
end
end

def conf_bdii(bdii, sname, cehost)
  f = File.new("/home/#{$cfg.user}/site-info-bdii.def", "w")
  f.write "## Site-info.def Bdii\n"
  f.write "SITE_BDII_HOST=\"#{bdii}\"\n"
  f.write "SITE_NAME=#{sname}\n"
  f.write "SITE_LOC=\"#{sname.capitalize}, France\"\n"
  f.write "SITE_WEB=\"https://www.grid5000.fr/\"\n"
  f.write "SITE_LAT=\"48,7\"\n"
  f.write "SITE_LONG=\"6,2\"\n"
  f.write "SITE_EMAIL=root@localhost\n"
  f.write "SITE_SECURITY_EMAIL=root@localhost\n"
  f.write "SITE_SUPPORT_EMAIL=root@localhost\n"
  f.write "SITE_DESC=\"Grid5000 School - gLite\"\n"
  f.write "SITE_OTHER_GRID=\"#{clusters($nodes)}\"\n\n"
  f.write "CE_HOST=\"#{cehost}\"\n"
  f.write "BDII_REGIONS=\"CE SITE_BDII\"\n"
  f.write "BDII_CE_URL=\"ldap://#{cehost}:2170/mds-vo-name=resource,o=grid\"\n"
  f.write "BDII_SITE_BDII_URL=\"ldap://#{bdii}:2170/mds-vo-name=resource,o=grid\"\n"
  f.close
end

def conf_batch(batch, cehost, sname)
  f = File.new("/home/#{$cfg.user}/site-info-batch.def", "w")
  f.write "## Site-info.def Batch\n"
  f.write "BATCH_SERVER=\"#{batch}\"\n"
  f.write "CE_HOST=\"#{cehost}\"\n"
  f.write "CE_SMPSIZE=`grep -c processor /proc/cpuinfo`\n"
  f.write "VOS=\"#{sname}\"\n"
  f.write "QUEUES=\"default\"\n"
  f.write "DEFAULT_GROUP_ENABLE=\"#{sname}\"\n"
  f.write "USERS_CONF=/opt/glite/yaim/etc/conf/users.conf\n"
  f.write "GROUPS_CONF=/opt/glite/yaim/etc/conf/groups.conf\n"
  f.write "WN_LIST=/opt/glite/yaim/etc/conf/wn-list.conf\n"
  f.write "CONFIG_MAUI=\"yes\"\n"
  f.close
end

def conf_wn(bdii, se, sname, batch, cehost)
  f = File.new("/home/#{$cfg.user}/site-info-wn.def", "w")
  f.write "## Site-info.def Batch\n"
  f.write "BDII_HOST=\"#{bdii}\"\n"
  f.write "SE_LIST=\"#{se}\"\n"
  f.write "SITE_NAME=#{sname}\n"
  f.write "USERS_CONF=/opt/glite/yaim/etc/conf/users.conf\n"
  f.write "GROUPS_CONF=/opt/glite/yaim/etc/conf/groups.conf\n"
  f.write "WN_LIST=/opt/glite/yaim/etc/conf/wn-list.conf\n"
  f.write "VOS=#{sname}\n"
  f.write "BATCH_SERVER=#{batch}\n"
  f.write "CE_HOST=#{cehost}\n"
  f.write "CE_SMPSIZE=`grep -c processor /proc/cpuinfo`\n"
  f.write "VO_#{sname.upcase}_SW_DIR=/opt/vo_software/#{sname}\n"
  f.write "VO_#{sname.upcase}_VOMS_CA_DN=\"/C=FR/O=Grid5000/CN=G5k-CA\"\n"
  f.write "VO_#{sname.upcase}_VOMSES=\"#{sname} glite-io.grid5000.fr 15000 /C=FR/O=Grid5000/OU=#{sname} SCAI/CN=host/glite-io.grid5000.fr #{sname}\"\n"
  f.close
end

def conf_cehost(sname, cehost, batch, se)
  f = File.new("/home/#{$cfg.user}/site-info-ce.def", "w")
  f.write "## Site-info.def Ce\n"
  f.write "SITE_NAME=#{sname}\n"
  f.write "CE_HOST=\"#{cehost}\"\n"
  f.write "BATCH_SERVER=\"#{batch}\"\n"
  f.write "USERS_CONF=/opt/glite/yaim/etc/conf/users.conf\n"
  f.write "GROUPS_CONF=/opt/glite/yaim/etc/conf/groups.conf\n"
  f.write "WN_LIST=/opt/glite/yaim/etc/conf/wn-list.conf\n"
  f.write "JAVA_LOCATION=/usr/java/default\n"
  f.write "JOB_MANAGER=pbs\n"
  f.write "CE_BATCH_SYS=pbs\n"
  f.write "BATCH_VERSION=torque-2.3.6-2\n"
  f.write "BATCH_BIN_DIR=/usr/bin\n"
  f.write "BATCH_LOG_DIR=/var/spool/pbs/\n"
  f.write "BATCH_SPOOL_DIR=/var/spool/pbs/\n"
  f.write "CREAM_CE_STATE=\"Special\"\n"
  f.write "BLPARSER_HOST=#{cehost}\n"
  f.write "BLAH_JOBID_PREFIX=\"cream_\"\n"
  f.write "BLPARSER_WITH_UPDATER_NOTIFIER=\"false\"\n"
  f.write "MYSQL_PASSWORD=koala\n"
  f.write "APEL_DB_PASSWORD=\"APELDB_PWD\"\n"
  f.write "APEL_MYSQL_HOST=\"#{cehost}\"\n"
  f.write "CE_OS_ARCH=x86_64  # uname -i\n"
  f.write "CE_OS=`lsb_release -i | cut -f2`\n"
  f.write "CE_OS_RELEASE=`lsb_release -r | cut -f2`\n"
  f.write "CE_OS_VERSION=`lsb_release -c | cut -f2`\n"
  f.write "CE_CPU_MODEL=Xeon\n"
  f.write "CE_CPU_VENDOR=GenuineIntel\n"
  f.write "CE_CPU_SPEED=2000  # grep MHz /proc/cpuinfo\n"
  f.write "CE_MINPHYSMEM=16000          # grep MemTotal /proc/meminfo\n"
  f.write "CE_MINVIRTMEM=4096          # grep SwapTotal /proc/meminfo\n"
  f.write "CE_OUTBOUNDIP=TRUE\n"
  f.write "CE_INBOUNDIP=FALSE\n"
  f.write "CE_RUNTIMEENV=\"\nGLITE-3_2_0\nR-GMA\n\"\n"
  f.write "CE_CAPABILITY=\"none\"\n"
  f.write "CE_OTHERDESCR=\"Cores=4\" #grep -c physical id.*: 0 /proc/cpuinfo\n"
  f.write "CE_PHYSCPU=2      #grep -c core id.*: 0 /proc/cpuinfo\n"
  f.write "CE_LOGCPU=1       #grep -c processor /proc/cpuinfo\n"
  f.write "CE_SMPSIZE=1      #grep -c processor /proc/cpuinfo\n"
  f.write "CE_SI00=1592\n"
  f.write "CE_SF00=1927\n"
  f.write "CE_OTHER_DESCR=\"Cores=1, Benchmark=1.11-HEP-SPEC06\"\n"
  f.write "SE_LIST=\"#{se}\"\n"
  f.write "SE_MOUNT_INFO_LIST=\"none\"\n"
  f.write "VOS=\"#{sname}\"\n"
  f.write "QUEUES=\"default\"\n"
  f.write "DEFAULT_GROUP_ENABLE=\"#{sname}\"\n"
  f.write "ACCESS_BY_DOMAIN=false\n"
  f.write "CREAM_DB_USER=creamdb\n"
  f.write "CREAM_DB_PASSWORD=\"secretPassword\"\n"
  f.write "BLPARSER_HOST=#{cehost}\n"
  f.write "BLP_PORT=33333\n"
  f.write "CREAM_PORT=56565\n"
  f.write "CEMON_HOST=#{cehost}\n"
  f.close
end

# <user_id>:<username>:<group_id>:<group_name>:<vo_name>:<special_user_type>:
def conf_users(group,sname)
  f = File.new("/home/#{$cfg.user}/conf/users.conf", "w")
  3.times { |a| f.write "#{a + 10410}:adm#{sname}#{a +1}:1390,1395:#{group}adm,#{group}:#{sname}:adm:\n" }
  10.times { |x| f.write "#{x + 10420}:#{sname}00#{x + 1}:1395:#{group}:#{sname}::\n" }
  f.close
end

# "/<vo>"::::
# "/<vo>/<group>"::::
# "/<vo>/<group>/ROLE=<role>::::
# "/<vo>/<group>/ROLE=<role>:::<special_user_type>:
def conf_groups(sname)
  f = File.new("/home/#{$cfg.user}/conf/groups.conf", "w")
  f.write "\"/#{sname}\"::::\n"
  f.write "\"/#{sname}/ROLE=#{sname.upcase}\"::::\n"
  f.write "\"/#{sname}/ROLE=VO-Admin\":::adm:\n"
  f.close
end

def list_wn(wn)
  f = File.new("/home/#{$cfg.user}/conf/wn-list.conf", "w")
    for i in wn
      f.write "#{i}\n"
    end
  f.close
end

def export_nfs()
  f = File.new("/home/#{$cfg.user}/export", "w")
  f.write "/var/spool/pbs/server_priv/accounting    *(rw,async,no_root_squash)"
  f.write "/var/spool/pbs/server_logs               *(rw,async,no_root_squash)"
  f.close
end

def queue_config()
  f = File.new("/home/#{$cfg.user}/queue.conf", "w")
  f.write "#!/bin/sh"
  f.write "qmgr"
  f.write "set server scheduling = True"
  f.write "set server acl_hosts = localhost"
  f.write "set server acl_hosts += <other hosts allowed to submit jobs>"
  f.write "set server managers = <e-mail of batch system manager>"
  f.write "set server operators = <e-mail of batch system operator>"
  f.write "set server default_queue = <queuename>"
  f.write "set server scheduler_iteration = 600"
  f.write "set server node_check_rate = 150"
  f.write "set server tcp_timeout = 12"
  f.write "set server poll_jobs = False"
  f.write "set server log_level = 3"
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
  #serv.each_value{|service|
  $nodes.each{|service|
    Net::SSH.start(service, 'root') do |ssh|
      if $cfg.verbose == true:
        puts "*** yaim on #{service}"
      elsif $cfg.pbar == true :
        pbarc.inc
      end
      ssh.exec!('mkdir -p /root/yaim && rm -f /etc/yum.repos.d/dag.repo* && wget -P /etc/yum.repos.d/ http://apt.grid5000.fr/glite/repo/dag.repo -q && yum update -q -y')
    end
  }
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
    ssh.exec!('wget -P /etc/yum.repos.d/ http://apt.grid5000.fr/glite/repo/glite-BDII.repo -q && yum install glite-BDII -q -y')
  if $cfg.pbar == true:
    pbarb.inc
  end
    ssh.scp.upload!("/home/#{$cfg.user}/site-info-bdii.def","/root/yaim/site-info.def") do |ch, name, sent, total|
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
    ssh.exec!('wget -P /etc/yum.repos.d/ http://apt.grid5000.fr/glite/repo/glite-TORQUE_server.repo -q && yum install glite-TORQUE_server -q -y')
    ssh.scp.upload!("/home/#{$cfg.user}/site-info-batch.def","/root/yaim/site-info.def") do |ch, name, sent, total|
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
      scp.upload!("/home/#{$cfg.user}/conf", "/opt/glite/yaim/etc", :recursive => true)
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

wn.each {|wo|
  Net::SSH.start(wo, 'root') do |ssh|
    if $cfg.verbose == true:
      puts "*** intall worker #{wo}"
    end
    ssh.exec!('wget -P /etc/yum.repos.d/ http://apt.grid5000.fr/glite/repo/glite-WN.repo -q && wget -P /etc/yum.repos.d/ http://apt.grid5000.fr/glite/repo/glite-TORQUE_client.repo -q && wget -P /etc/yum.repos.d/ http://apt.grid5000.fr/glite/repo/lcg-CA.repo -q  && yum groupinstall glite-WN -q -y && yum install glite-TORQUE_client lcg-CA -q -y --nogpgcheck')
    ssh.scp.upload!("/home/#{$cfg.user}/site-info-wn.def","/root/yaim/site-info.def") do |ch, name, sent, total|
      #print "\r#{name}: #{(sent.to_f * 100 / total.to_f).to_i}%\n"
    end
    if $cfg.pbar == true:
      pbaro.inc
    end
    if $cfg.verbose == true:
      puts "*** configure"
    end
  end
  begin
    Net::SCP.start("#{wo}", 'root') do |scp|
      scp.upload!("/home/#{$cfg.user}/conf/", "/opt/glite/yaim/etc/", :recursive => true)
    end
  rescue
    puts "Erreur scp conf wn : #{wo}"
  end
  Net::SSH.start(wo, 'root') do |ssh|
    ssh.exec!('chmod -R 600 /root/yaim && /opt/glite/yaim/bin/yaim -c -s /root/yaim/site-info.def -n glite-WN -n TORQUE_client -d 1')
  end
  if $cfg.verbose == true:
   puts "*** intall #{wo} ok."
  end
}

### Computing element
#

### Ui
#

### Lfc se
#

else
  puts "\tNo send\n"
end
