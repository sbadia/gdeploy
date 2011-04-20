#!/usr/bin/ruby -w

# ssh -NL 3443:api.grid5000.fr:443 lille.userl
#
require 'rubygems'
require 'restfully' # gem install restfully

USER = ENV['USER']

logger = Logger.new(STDERR)
logger.level = Logger::WARN
sites = ["nancy","grenoble","lille"]
sites.each do |s|
  Restfully::Session.new(:logger => logger, :base_uri => 'https://localhost:3443/sid/grid5000') do |root, session|
    begin
      job_to_submit = {
        :command => "sleep 3600",
        :types => ["deploy"],
        :name => 'demo-g5ks',
        :project => 'gLite on Grid5000'
      }
      puts "*** Submitting the following job: #{job_to_submit.inspect}"
      job = root.sites[:"#{s}"].jobs.submit(job_to_submit)
      while job.reload['state'] != 'running'
        puts "Waiting for the job##{job['uid']} to be running..."
        sleep 3
      end
      deployment_to_submit = {
        :nodes => job['assigned_nodes'],
        :environment => 'http://public.nancy.grid5000.fr/~sbadia/sl55-ahci.dsc',
        :key => 'http://public.nancy.grid5000.fr/~sbadia/id_dsa.pub',
        :notifications =>  ["xmpp:#{USER}@jabber.grid5000.fr"]
      }
      puts "OK"
      puts "*** Launching the following deployment: #{deployment_to_submit.inspect}"
      deployment = root.sites[:"#{s}"].deployments.submit(deployment_to_submit)
      while deployment.reload['status'] == 'processing'
        puts "Waiting for the deployment##{deployment['uid']} to be terminated..."
        sleep 30
      end
      puts "OK: #{deployment.inspect}"
    rescue => e
      puts "Error: #{e.class.name}, #{e.message}"
    end
  end
end
