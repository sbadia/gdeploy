#!/usr/bin/ruby

=begin

G5kjobs, a tool for reserve ressources on Grid'5000 (Using g5k api).
For more information see <http://github.com/sbadia/gdeploy/>
Copyright (C) 2011  Lucas Nussbaum

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=end

# ruby g5kjobs.rb > nodes
# kadeploy3 -f nodes --multi-server -a http://public.nancy.grid5000.fr/~sbadia/sl55-ahci.dsc -k ~/.ssh/id_dsa.pub -o ~/dnodes
# ruby list2yaml.rb -g dnodes > g5k.yaml
# time ruby config-glite.rb g5k.yaml

require 'rubygems'
require 'restclient'
require 'json'
require 'pp'
require 'logger'

CLUSTERS = %w[edel adonis chinqchint chirloute graphene talc stremi parapluie parapide]
CLUSTERS_LIST = "cluster in ('" + CLUSTERS.join('\', \'') + "')"
START_TIMEOUT = 60
WALLTIME=2

#RestClient.log = Logger.new(STDERR)
api = RestClient::Resource.new('https://api.grid5000.fr/', :timeout => 5)

jobs = {}
#job = {:resources => "nodes=1,walltime=0:01", :command => "sleep 86400", :name => "gLite", :project => "gLite", :properties => CLUSTERS_LIST }
job = {:resources => "nodes=BEST,walltime=#{WALLTIME}", :command => "sleep 86400", :name => "gLite", :project => "gLite", :types => ["deploy"], :properties => CLUSTERS_LIST }
['grenoble', 'lille', 'nancy', 'rennes'].each do |site|
  STDERR.puts "Reserving on #{site}"
  api["/sid/grid5000/sites/#{site}/jobs"].post(job.to_json, :accept => :json, :content_type => :json) do |response, request, result|
    case response.code
    when 201
      # Follow the link to get the job's details
      jobs[response.headers[:location]] = false
      full_job = JSON.parse api[response.headers[:location]].get(:accept => :json).body
      STDERR.puts "Job submitted: #{full_job['uid']}"
    else
      STDERR.puts "Cannot submit the job: #{response.code} - #{JSON.parse response.body}"
      exit 1
    end
  end
end
tstart = Time::now
STDERR.puts "Giving some time for all jobs to start ..."
while Time::now - tstart < START_TIMEOUT and not jobs.select { |k,v| not v }.empty?
  jobs.select { |k,v| not v }.each do |k,v|
    full_job = JSON.parse api[k].get(:accept => :json).body
    if full_job['state'] == "running"
      STDERR.puts "#{k} running"
      jobs[k] = true
    end
    sleep 1
  end
end
STDERR.puts "Deleting unsuccessful jobs"
jobs.select { |k, v| not v }.each do |k, v|
  STDERR.puts "#{k} ..."
  api[k].delete do |response, request, result|
    case response.code
    when 202
      STDERR.puts "OK, deleted."
    else
      STDERR.puts "Cannot delete the job: #{response.code} - #{JSON.parse response.body}"
    end
  end
end
STDERR.puts "Getting list of nodes"
nodes = []
jobs.select { |k, v| v }.each do |k, v|
  STDERR.puts "#{k} ..."
  full_job = JSON.parse api[k].get(:accept => :json).body
  nodes += full_job['assigned_nodes']
end
puts nodes
