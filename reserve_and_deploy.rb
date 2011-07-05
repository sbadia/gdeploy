#!/usr/bin/env ruby

require 'rubygems'        # or: export RUBYOPT="-rubygems"
require 'restfully'       # gem install restfully
require 'net/ssh/gateway' # gem install net-ssh-gateway
require 'json'            # gem install json
require 'yaml'
require 'ruote'
require 'pp'
require 'ipaddress'
require 'colorize'

#TODO : change the pubkey configuration
PUBLIC_KEY = Dir[File.expand_path("~/.ssh/*.pub")][0]
fail "No public key available in ~/.ssh !" if PUBLIC_KEY.nil?
PUB_KEY = File.read(PUBLIC_KEY)

CONFIG = YAML.load_file(File.expand_path("~/.restfully/api.grid5000.fr.yml"))

TIMEOUT_JOB  = 2*60 # 2 minutes
TIMEOUT_DEPLOYMENT = 15*60 # 15 minutes

@@jobs = []
@@deployed_nodes = []

Restfully::Session.new( :base_uri => CONFIG['base_uri'], :username => CONFIG['username'], :password => CONFIG['password']) do |root, session|
	clusters_list = %w[edel adonis chinqchint chirloute graphene talc stremi parapluie parapide]
	root.sites.each do |site|
		site.clusters.each do |cluster|
			cluster_name = cluster['uid']
			if(clusters_list.include?(cluster_name)) then 
				new_job = site.jobs.submit(
				:resources => "cluster=#{cluster_name}/nodes=1,walltime=00:20:00",
				:command => "sleep 1200",
				:types => ["deploy"],
				:name => "Xtrem Programming"
				) rescue nil
				@@jobs.push(new_job) unless new_job.nil?
				pp new_job
				if new_job.nil? then
					puts "Impossible d'obtenir le job sur le site"
				end
				# Timeout
				begin
					Timeout.timeout(TIMEOUT_JOB) do
						if(!new_job.nil?) then
							while ( new_job.reload['state'] != 'running' ) do
								puts "Some jobs are not running on site #{site_name}. Waiting before checking again..."
								sleep TIMEOUT_JOB/30
							end
						end
					end
				rescue Timeout::Error => e
					puts "Error : timeout reached while trying to get a job"
				end # /begin
			end
		end # site.clusters.each 
	end #root.sites.each

	@@jobs.each do |job|
		site = job.parent['uid']
		puts "site du déploiement : #{site}"
		if job.reload['state'] == 'running' then
			new_deployment = job.parent.deployments.submit( :environment => "http://public.nancy.grid5000.fr/~sbadia/sl55-ahci.dsc", :nodes => job['assigned_nodes'], :key => PUB_KEY)
		end
    # Wait until all deployments are no longer processing.
		begin
			Timeout.timeout(TIMEOUT_DEPLOYMENT) do
				while ( new_deployment.reload['status'] == 'processing' ) do
					puts "Deployment in progress on site "+site
					sleep TIMEOUT_DEPLOYMENT/30
				end
			end
		rescue Timeout::Error => e
			puts "One of the deployments is still not terminated, it will be discarded."
		end # /begin
	# Check if the every nodes are correctly deployed
		new_deployment['nodes'].each do |node|
			if (new_deployment['result'][node]['state'] == "OK") then
				@@deployed_nodes.push(node)
			end
		end
	end #@@jobs.each
	pp @@jobs
	pp @@deployed_nodes
end #main loop

