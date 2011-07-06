# Author:: Sebastien Badia (<sebastien.badia@inria.fr>)
# Date:: Tue Jul 05 15:00:46 +0200 2011
require 'rubygems'

version = "0.1.3"

desc "Upload to nancy"
task :upload do
  sh "ssh local 'rm -rf gdeploy'"
  sh "scp -r /home/sbadia/dev/gdeploy/ local:"
end

desc "New release (tag and push)"
task :release do
  sh "git tag #{version} -m \"New release : #{version}\""
  sh "git push --tag"
end

desc "Clean conf files"
task :clean do
  sh "rm -f ./conf/exports"
  sh "rm -rf ./conf/{orsay,lille,nancy,lyon,grenoble,sophia,bordeaux,rennes,toulouse,luxembourg,reims}"
end

task :default => :upload
