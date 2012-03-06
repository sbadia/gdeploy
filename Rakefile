# Author:: Sebastien Badia (<sebastien.badia@inria.fr>)
# Date:: Tue Jul 05 15:00:46 +0200 2011
require 'rubygems'

SITE = "nancy"

version = "0.1.3"

desc "Upload to #{SITE}"
task :up do
  sh "ssh local 'rm -rf gdeploy'"
  sh "scp -r ~/dev/edge/gdeploy/ local:"
end

desc "Download from #{SITE}"
task :down do
  sh "scp -r local:gdeloy/ /tmp"
end

desc "New release (tag and push)"
task :release do
  sh "git tag #{version} -m \"New release : #{version}\""
  sh "git push --tag"
end

desc "Clean conf files"
task :clean do
  sh "rm -f ./conf/exports ~/public/config-glite-42.tgz"
  sh "rm -f ./g5k.yaml ./nodes"
  sh "rm -rf ./conf/{grid5000,orsay,lille,nancy,lyon,grenoble,sophia,bordeaux,rennes,toulouse,luxembourg,reims}"
end

desc "Gen confs"
task :conf do
  sh "cat $OAR_NODE_FILE |uniq > nodes"
  sh "ruby list2yaml.rb -g nodes > g5k.yaml"
  sh "ruby config-glite.rb g5k.yaml"
end

desc "List rake"
task :list do
  sh "rake -T"
end

task :default => :list
