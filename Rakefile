# Author:: Sebastien Badia (<sebastien.badia@inria.fr>)
# Date:: Tue Jul 05 15:00:46 +0200 2011
require 'rubygems'

version = "0.1.3"

desc "Upload to nancy"
task :up do
  sh "ssh local 'rm -rf gdeploy'"
  sh "scp -r /home/sbadia/dev/gdeploy/ local:"
end

desc "Download from nancy"
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
  sh "rm -f ./conf/exports"
  sh "rm -f ./g5k.yaml"
  sh "rm -rf ./conf/{orsay,lille,nancy,lyon,grenoble,sophia,bordeaux,rennes,toulouse,luxembourg,reims}"
end

desc "Gen confs"
task :conf do
  sh "ruby list2yaml.rb -g $OAR_NODE_FILE > g5k.yaml"
  sh "ruby config-glite.rb g5k.yaml"
end

desc "List rake"
task :list do
  sh "rake -T"
end

task :default => :list
