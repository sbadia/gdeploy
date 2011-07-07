#!/usr/bin/ruby -w

require 'pp'
require 'yaml'
require 'optparse'
require 'net/scp'
require 'net/ssh'
require 'net/ssh/multi'

if ARGV.length < 1
  puts "config-glite YAMLCONFIG 1 (for install)"
  exit 1
end

install = 1
$d = YAML::load(IO::read(ARGV[0]))
puts "\033[1;32m####\033[0m Loaded config file #{ARGV[0]}"

DIR = File.expand_path(File.dirname(__FILE__))

extinction = Proc.new{
  puts "Received extinction request..."
}
%w{INT TERM}.each do |signal|
  Signal.trap( signal ) do
      extinction.call
    exit(1)
  end
end

def conf_site(vo, bdii, sname, cehost, batch, voms, ui, clusters)
  f = File.new("#{DIR}/conf/#{sname}/site-info.def", "w")
  clusters_string = clusters.keys.map { |c| c.upcase }.join('|')
  f.puts <<-EOF
## Site-info.def Bdii
SITE_BDII_HOST="#{bdii}"
SITE_NAME=#{sname}
SITE_LOC="#{sname.capitalize}, France"
SITE_WEB="https://www.grid5000.fr/mediawiki/index.php/#{sname.capitalize}:Home"
SITE_LAT="48,7"
SITE_LONG="6,2"
SITE_EMAIL=root@localhost
SITE_SECURITY_EMAIL=sbadia@f#{sname}.#{sname}.grid5000.fr
SITE_SUPPORT_EMAIL=sbadia@f#{sname}.#{sname}.grid5000.fr
SITE_DESC="Grid5000 - gLite"
SITE_OTHER_GRID="#{clusters_string}"
BDII_REGIONS="CE SITE_BDII BDII WMS"
BDII_CE_URL="ldap://#{cehost}:2170/mds-vo-name=resource,o=grid"
BDII_SITE_BDII_URL="ldap://#{bdii}:2170/mds-vo-name=resource,o=grid"
BDII_WMS_URL="ldap://#{voms}:2170/mds-vo-name=resource,o=grid"
BDII_BDII_URL="ldap://#{bdii}:2170/mds-vo-name=resource,o=grid"

## Site-info.def Batch
BATCH_SERVER="#{batch}"
CE_HOST="#{cehost}"
CE_SMPSIZE=`grep -c processor /proc/cpuinfo`
VOS="#{vo}"
QUEUES="default"
DEFAULT_GROUP_ENABLE="#{vo}"
USERS_CONF=/opt/glite/yaim/etc/conf/users.conf
GROUPS_CONF=/opt/glite/yaim/etc/conf/groups.conf
WN_LIST=/opt/glite/yaim/etc/conf/wn-list.conf
CONFIG_MAUI="yes"

## Site-info.def Batch
BDII_HOST="#{bdii}"
VO_#{vo.upcase}_SW_DIR=/opt/vo_software/#{vo}
VO_#{vo.upcase}_VOMS_CA_DN="/O=Grid/OU=GlobusTest/OU=simpleCA-#{voms}/CN=Globus Simple CA"
VO_#{vo.upcase}_VOMSES="#{vo} #{voms} 15000 /O=Grid/OU=GlobusTest/OU=simpleCA-#{voms}/CN=host/#{voms} #{vo}"
VO_#{vo.upcase}_VOMS_SERVERS="vomss://#{voms}:8443/voms/#{vo}?/#{vo}/"

## Site-info.def Ce
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
CE_SI00=1592
CE_SF00=1927
CE_OTHER_DESCR="Cores=1, Benchmark=1.11-HEP-SPEC06"
SE_MOUNT_INFO_LIST="none"
ACCESS_BY_DOMAIN=false
CREAM_DB_USER=creamdb
CREAM_DB_PASSWORD="secretPassword"
BLPARSER_HOST=#{cehost}
BLP_PORT=33333
CREAM_PORT=56565
CEMON_HOST=#{cehost}

## site-info.def voms
MYSQL_PASSWORD="superpass"
VOMS_HOST=#{voms}
VOMS_DB_HOST=#{voms}
VO_#{vo.upcase}_MYSQL_VOMS_PORT=15000
VO_#{vo.upcase}_MYSQL_VOMS_DB_USER=#{vo}u
VO_#{vo.upcase}_MYSQL_VOMS_DB_PASS="superpass"
VO_#{vo.upcase}_MYSQL_VOMS_DB_NAME=#{vo}db
VO_#{vo.upcase}_VOMS_PORT=15000
VO_#{vo.upcase}_VOMS_DB_USER=#{vo}u
VO_#{vo.upcase}_VOMS_DB_PASS="superpass"
VO_#{vo.upcase}_VOMS_DB_NAME=#{vo}db
VOMS_ADMIN_SMTP_HOST=mail.#{sname}.grid5000.fr
VOMS_ADMIN_MAIL=#{ENV['user']}@f#{sname}.#{sname}.grid5000.fr

## site-info.def ui
PX_HOST=#{voms}
RB_HOST=#{voms}
UI_HOST=#{ui}
EOF
  f.close
end # def:: conf_site(bdii, sname, cehost, batch, se, voms)

# <user_id>:<username>:<group_id>:<group_name>:<vo_name>:<special_user_type>:
def conf_users(sname ,vo)
  f = File.new("#{DIR}/conf/#{sname}/users.conf", "w")
  3.times { |a| f.write "#{a + 10410}:sgm#{a +1}:1390,1395:sgm,#{vo}:#{vo}:sgm:\n" }
  3.times { |x| f.write "#{x + 10420}:toto#{x + 1}:1395:#{vo}:#{vo}::\n" }
  f.close
end

# "/<vo>"::::
# "/<vo>/<group>"::::
# "/<vo>/<group>/ROLE=<role>::::
# "/<vo>/<group>/ROLE=<role>:::<special_user_type>:
def conf_groups(sname, vo)
  f = File.new("#{DIR}/conf/#{sname}/groups.conf", "w")
  f.puts <<-EOF
"/#{vo}"::::
"/#{vo}/ROLE=#{vo.upcase}"::::
"/#{vo}/ROLE=VO-Admin":::sgm:
EOF
  f.close
end

def export_nfs()
  f = File.new("#{DIR}/conf/exports", "w")
  f.puts <<-EOF
/var/spool/pbs/server_priv/accounting    *(rw,async,no_root_squash)
/var/spool/pbs/server_logs               *(rw,async,no_root_squash)
EOF
  f.close
end

def queue_config(sname, wn)
  f = File.new("#{DIR}/conf/#{sname}/queue.conf", "w")
  p wn
  f.puts <<-EOF
#!/bin/sh
qmgr << EOF
set server scheduling = True
set server acl_hosts = *.grid5000.fr
set server managers = root@`hostname -f`
set server operators = root@`hostname -f`
set server default_queue = default
set server scheduler_iteration = 600
set server node_check_rate = 150
set server tcp_timeout = 12
set server poll_jobs = False
set server log_level = 3
set queue default Priority = 100
set queue default max_queuable = 100
set queue default max_running = 100
set queue default resources_max.nodect = #{wn.length - 1}
set server query_other_jobs = True
set server resources_default.cput = 01:00:00
set server resources_default.neednodes = 1
set server resources_default.nodect = #{wn.length - 1}
set server resources_default.nodes = 1
set server default_node = 1#shared
set queue default resources_default.nodes = nodes=1:ppn=1\nEOF
EOF
  f.close
end

$nodes = []

$d['VOs'].each_pair do |name, conf|
  $my_vo = name
  $my_voms = conf['voms']
  $nodes << conf['voms']
end

puts "\033[1;36m###\033[0m Create conf files"
$d['sites'].each_pair do |sname, sconf|
  puts "\033[1;33m==>\033[0m Generate conf::#{sname}"
    Dir::mkdir("#{DIR}/conf/#{sname}/", 0755)
    conf_site($my_vo, sconf['bdii'], sname, sconf['ce'], sconf['batch'], $my_voms, sconf['ui'], sconf['clusters'])
    $nodes << sconf['bdii']
    $nodes << sconf['ce']
    $nodes << sconf['batch']
    $nodes << sconf['ui']
    conf_users(sname ,$my_vo)
    conf_groups(sname, $my_vo)
    export_nfs()
  sconf['clusters'].each_pair do |cname, cconf|
    queue_config(sname, cconf['nodes'])
    File.open("#{DIR}/conf/#{sname}/wn-list.conf", "w") do |fd|
      #fd.puts cconf['nodes'].join(":#{cname}\n")
      fd.puts cconf['nodes'].join("\n")
    end
    $nodes += cconf['nodes']
  end
end
p $nodes
if install == 1:
  puts "\033[1;36m###\033[0m Update distrib"
  Net::SSH::Multi.start do |session|
    $nodes.each do |node|
      session.use "root@#{node}"
    end
      session.exec('mkdir -p /root/yaim && mkdir -p /opt/glite/yaim/etc && cd /etc/yum.repos.d/ && rm -rf dag.repo* glite-* lcg-* && wget http://public.nancy.grid5000.fr/~sbadia/glite/repo.tgz -q && tar xzf repo.tgz && yum update -q -y')
      session.exec("echo 'mkdir -p /root/yaim && mkdir -p /opt/glite/yaim/etc && cd /etc/yum.repos.d/ && rm -rf dag.repo* glite-* lcg-* && wget http://public.nancy.grid5000.fr/~sbadia/glite/repo.tgz -q && tar xzf repo.tgz && yum update -q -y' >> /root/install.log")
      session.exec("echo 'In Progress'")
      session.exec("cd /root/ && wget http://public.nancy.grid5000.fr/~sbadia/glite/scp-ssh.tgz -q && tar xzf scp-ssh.tgz && chown -R root:root /root/.ssh/")
      session.loop
  end
  $nodes.each do |node|
    Net::SSH.start(node, 'root') do |ssh|
      begin
       Net::SCP.start(node, 'root') do |scp|
         scp.upload!("#{DIR}/conf", "/opt/glite/yaim/etc", :recursive => true)
       end
      rescue
       puts "\033[1;31mErreur\033[0m scp on #{node}"
      end
    end
  end

  puts "\033[1;36m###\033[0m Configuring VOs"
  $d['VOs'].each_pair do |name, conf|
    first_site = $d['sites'].keys.first
    puts "\033[1;33m==>\033[0m Configuring VO=#{name} on VOMS=#{conf['voms']}"
    Net::SSH.start(conf['voms'], 'root') do |ssh|
      ssh.exec!("cp -r /opt/glite/yaim/etc/conf/#{first_site}/site-info.def /root/yaim/site-info.def")
      ssh.exec!("yum install mysql-server glite-VOMS_mysql -q -y --nogpgcheck > /dev/null 2>&1")
      system("ssh root@#{conf['voms']} -o BatchMode=yes 'cd /opt/glite/yaim/etc/conf/simple-ca/ && chmod +x setup.sh && /bin/bash setup.sh'")
      ssh.exec!("/etc/init.d/mysqld start > /dev/null 2>&1")
      ssh.exec!("sed -e 's/VOMS_DB_HOST=#{conf['voms']}/VOMS_DB_HOST=localhost/' -i /root/yaim/site-info.def")
      ssh.exec!("chmod 766 /etc/bdii/bdii-slapd.conf && touch /var/log/bdii/bdii-update.log && chmod 777 /var/log/bdii/bdii-update.log")
      ssh.exec!("/usr/bin/mysqladmin -u root password superpass && chmod 777 /var/log/bdii")
      ssh.exec!('chmod -R 600 /root/yaim && /opt/glite/yaim/bin/yaim -c -s /root/yaim/site-info.def -n VOMS -d 1')
      ssh.exec!('echo -e "\ngLite VOMS - (VOMS MySQL)\n" >> /etc/motd')
    end
    # Distri
    Dir::mkdir("#{DIR}/conf/#{$my_voms}/", 0755)
    system("scp -o BatchMode=yes root@#{conf['voms']}:*.tgz /#{DIR}/conf/#{$my_voms}/")
    system("scp -o BatchMode=yes root@#{conf['voms']}:hash /#{DIR}/conf/#{$my_voms}/")
    $nodes.each do |node|
      Net::SCP.start(node, 'root') do |scp|
       scp.upload!("#{DIR}/conf/#{$my_voms}/", "/opt/glite/yaim/etc/conf", :recursive => true)
      end
    end
  end

  puts "\033[1;36m###\033[0m Configuring sites"
  $d['sites'].each_pair do |sname, sconf|
    puts "\033[1;33m==>\033[0m Configuring site=#{sname}"
    puts "\033[1;35m=>\033[0m Create certificats for (#{sconf['ce']},#{sconf['ui']}"
      system("ssh root@#{$my_voms} -o BatchMode=yes 'cd /opt/glite/yaim/etc/conf/simple-ca/ && chmod +x certs.sh && /bin/bash certs.sh #{sconf['ce']} #{sconf['ui']}'")
      system("scp -o BatchMode=yes root@#{$my_voms}:ui.tgz /#{DIR}/conf/#{sname}/")
      system("scp -o BatchMode=yes root@#{$my_voms}:ce.tgz /#{DIR}/conf/#{sname}/")
      system("ssh root@#{$my_voms} -o BatchMode=yes 'rm -f /root/ui.tgz && rm -f /root/ce.tgz'"
      $nodes.each do |node|
        Net::SCP.start(node, 'root') do |scp|
         scp.upload!("#{DIR}/conf/#{sname}/", "/opt/glite/yaim/etc/conf", :recursive => true)
        end
      end
    puts "\033[1;35m=>\033[0m BDII on #{sconf['bdii']}"
      Net::SSH.start(sconf['bdii'], 'root') do |ssh|
       ssh.exec!("cp -r /opt/glite/yaim/etc/conf/#{sname}/site-info.def /root/yaim/site-info.def")
       ssh.exec!('yum install glite-BDII -q -y')
       ssh.exec!('chmod -R 600 /root/yaim && /opt/glite/yaim/bin/yaim -c -s /root/yaim/site-info.def -n glite-BDII_site -d 1 && echo -e "\ngLite Bdii - (Ldap Berkley database index)\n" >> /etc/motd')
      end
    puts "\033[1;35m=>\033[0m Batch on #{sconf['batch']}"
      Net::SSH.start(sconf['batch'], 'root') do |ssh|
       ssh.exec!("cp -r /opt/glite/yaim/etc/conf/#{sname}/site-info.def /root/yaim/site-info.def")
       ssh.exec!('yum install glite-TORQUE_server -q -y')
       ssh.exec!('cd / && wget http://public.nancy.grid5000.fr/~sbadia/glite/ssh-keys.tgz -q && tar xzf ssh-keys.tgz && rm -f ssh-keys.tgz')
       ssh.exec!('mkdir -p /var/spool/pbs/server_logs && mkdir -p /var/spool/pbs/server_priv/accounting')
       ssh.exec!('chmod -R 600 /root/yaim && /opt/glite/yaim/bin/yaim -c -s /root/yaim/site-info.def -n glite-TORQUE_server -d 1')
       ssh.exec!('cat /opt/glite/yaim/etc/conf/exports >> /etc/exports && /etc/init.d/nfs restart')
       ssh.exec!('/opt/glite/yaim/bin/yaim -r -s /root/yaim/site-info.def -f config_maui_cfg')
       ssh.exec!('sh /opt/glite/yaim/etc/conf/queue.conf && /etc/init.d/maui restart && echo -e "\ngLite Batch\n" >> /etc/motd')
      end
    puts "\033[1;33m==>\033[0m Configuring #{sname}'s clusters"
    sconf['clusters'].each_pair do |cname, cconf|
      puts "\033[1;35m=>\033[0m Cluster #{cname} on #{cconf['nodes'].join(' ')}"
      Net::SSH::Multi.start do |session|
       cconf['nodes'].each do |n|
        session.use "root@#{n}"
       end
       session.exec("cp -r /opt/glite/yaim/etc/conf/#{sname}/site-info.def /root/yaim/site-info.def")
       session.exec("yum groupinstall glite-WN -q -y > /dev/null 2>&1 && yum install glite-TORQUE_client lcg-CA -q -y --nogpgcheck > /dev/null 2>&1 && sed '1iexit 0' -i /usr/sbin/fetch-crl && cd / && wget http://public.nancy.grid5000.fr/~sbadia/glite/ssh-keys.tgz -q && tar xzf ssh-keys.tgz && rm -f ssh-keys.tgz")
       session.exec('chmod -R 600 /root/yaim && /opt/glite/yaim/bin/yaim -c -s /root/yaim/site-info.def -n glite-WN -n TORQUE_client -d 1 > /dev/null 2>&1 && echo -e "\ngLite WN - (WorkerNode)\n" >> /etc/motd')
       session.loop
      end
    end
    puts "\033[1;33m==>\033[0m Configuring site=#{sname}"
    puts "\033[1;35m=>\033[0m CE on #{sconf['ce']}"
      Net::SSH.start(sconf['ce'], 'root') do |ssh|
       ssh.exec!("cp -r /opt/glite/yaim/etc/conf/#{sname}/site-info.def /root/yaim/site-info.def")
       ssh.exec!("cp -r /opt/glite/yaim/etc/conf/#{$my_vo}/* /root/ && cd /opt/glite/yaim/etc/conf/simple-ca/ && chmod +x install.sh")
       ssh.exec!("cp -r /opt/glite/yaim/etc/conf/#{sname}/ce.tgz /etc/grid-security/ && cd /etc/grid-security/ && tar xzf ce.tgz")
       ssh.exec!("yum install glite-CREAM glite-TORQUE_utils lcg-CA -q -y --nogpgcheck > /dev/null 2>&1 && sed '1iexit 0' -i /usr/sbin/fetch-crl && cd / && wget http://public.nancy.grid5000.fr/~sbadia/glite/ssh-keys.tgz -q && tar xzf ssh-keys.tgz && rm -f ssh-keys.tgz")
       ssh.exec!('mkdir -p /var/spool/pbs/server_priv/accounting && mkdir -p /var/spool/pbs/server_logs')
       ssh.exec!("echo '#{sconf['batch']}:/var/spool/pbs/server_priv/accounting /var/spool/pbs/server_priv/accounting nfs     rw,nfsvers=3,hard,intr,async,noatime,nodev,nosuid,auto,rsize=32768,wsize=32768  0' >> /etc/fstab")
       system("ssh root@#{sconf['ce']} -o BatchMode=yes 'cd /opt/glite/yaim/etc/conf/simple-ca/ && /bin/bash install.sh'")
       ssh.exec!("mount -a")
       ssh.exec!('chmod -R 600 /root/yaim && /opt/glite/yaim/bin/yaim -c -s /root/yaim/site-info.def -n glite-creamCE -n glite-TORQUE_utils -d 1')
       ssh.exec!('echo -e "\ngLite CE - (Computing Element)\n" >> /etc/motd')
     end
    puts "\033[1;35m=>\033[0m UI on #{sconf['ui']}"
      Net::SSH.start(sconf['ui'], 'root') do |ssh|
       ssh.exec("cp -r /opt/glite/yaim/etc/conf/#{sname}/site-info.def /root/yaim/site-info.def")
       ssh.exec!("cp -r /opt/glite/yaim/etc/conf/#{$my_vo}/* /root/ && cd /opt/glite/yaim/etc/conf/simple-ca/ && chmod +x install.sh")
       ssh.exec!("cp -r /opt/glite/yaim/etc/conf/#{sname}/ui.tgz /etc/grid-security/ && cd /etc/grid-security/ && tar xzf ui.tgz")
       ssh.exec!("yum groupinstall glite-UI -q -y && yum install lcg-CA -q -y --nogpgcheck > /dev/null 2>&1 && sed '1iexit 0' -i /usr/sbin/fetch-crl")
       ssh.exec!("chmod 766 /etc/bdii/bdii-slapd.conf && touch /var/log/bdii/bdii-update.log && chmod 766 /var/log/bdii/bdii-update.log")
       system("ssh root@#{sconf['ui']} -o BatchMode=yes 'cd /opt/glite/yaim/etc/conf/simple-ca/ && /bin/bash install.sh'")
       ssh.exec!('yum install gcc -q -y && chmod -R 600 /root/yaim && /opt/glite/yaim/bin/yaim -c -s /root/yaim/site-info.def -n glite-UI -d 1')
       ssh.exec!('echo -e "\ngLite UI - (User Interface)\n" >> /etc/motd')
      end
  end
else
  puts "\033[1;31m==> No install\033[0m"
end
