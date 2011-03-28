#!/usr/bin/env ruby
#
require "rubygems"
require "restfully"
require "json"
require "yaml"
require "facter"
require "pp"
require "net/scp"
require "net/ssh"

extinction = Proc.new{
	puts "Received extinction request..."
}

%w{INT TERM}.each do |signal|
  Signal.trap( signal ) do
		extinction.call
    exit(1)
  end
end

SITE = Facter.domain.split('.').first
USER = ENV['USER']
@myjob = nil
@mydeploy = nil

begin
	Restfully::Session.new(:base_uri => "https://api.grid5000.fr/2.0/grid5000", :username => USER)do |root, session|
		@myjob = root.sites[:"#{SITE}"].jobs[:"#{ENV['OAR_JOBID']}"].reload
		puts "--> Job nodes :"
		puts @myjob['assigned_nodes']
		puts "--> Start deployment"
		@mydeploy = @myjob.parent.deployments.submit(:environment => "lenny-x64-base", :nodes => @myjob['assigned_nodes'], :key => File.read(File.expand_path("~/.ssh/id_dsa.pub")), :notifications =>  ["xmpp:#{USER}@jabber.grid5000.fr"])
		puts @mydeploy.inspect
	end

	begin
		Timeout.timeout(60*10) do
			until @mydeploy["status"] == "terminated" do
				puts "Waiting for the end of deployment... (check every 30s)"
				sleep 30
				@mydeploy.reload
			end
		end
	rescue Timeout::Error => e
		puts "Error: timeout reach during deployment."
	end

	if  @mydeploy["status"] != "terminated"
		@mydeploy.delete
	else
		Net::SSH.start(@myjob['assigned_nodes'].first, "root") do |ssh|
			ssh.exec!("touch /root/toto && echo 'done' > /root/toto")
		end
		Net::SCP.download!(@myjob['assigned_nodes'].first, "root", "/root/toto", "/home/#{USER}")

		Restfully::Session.new(:base_uri => "https://api.grid5000.fr/2.0/grid5000") do |root, session|
			session.post("/sid/notifications", {:body => "Environment on frontend.#{SITE}.grid5000.fr:~#{USER}/glite.tgz is ready", :to => ["xmpp:#{USER}@jabber.grid5000.fr"]}, :headers => {:content_type => 'application/json'})
		end
	end

rescue Exception => e
	puts "Catched unexpected exception #{e.class.name}: #{e.message} - #{e.backtrace.join("\n")}"
	extinction.call
	exit(1)
end
