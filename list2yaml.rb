#!/usr/bin/ruby -w

require 'pp'
require 'yaml'
require 'optparse'

g5k = false

optparse = OptionParser.new do|opts|
  opts.on( '-g', '--g5k', 'Match G5K sites') do
  g5k = true
  end
end
optparse.parse!

if ARGV.length != 1
  puts "list2yaml [OPTIONS] LISTOFNODES"
  exit 1
end

if not g5k
  puts "Not implemented"
  exit 1
end

nodes = IO::readlines(ARGV[0]).map { |l| l.chomp }

d = {}
d['VOs'] = { 'grid5000' => { 'voms' => nodes.shift } }
d['sites'] = {}
if g5k
  nodes.sort.group_by { |n| n.gsub(/.*\.([a-z]+)\.grid5000.fr$/, '\1') }.each_pair do |site, nodes_site|
    d['sites'][site] = {}
    if nodes_site.length < 6
      puts "less than 6 nodes on #{site}, skipping"
      next
    end
    d['sites'][site]['bdii'] = nodes_site.shift
    d['sites'][site]['batch'] = nodes_site.shift
    d['sites'][site]['ce'] = nodes_site.shift
    d['sites'][site]['ui'] = nodes_site.shift
    d['sites'][site]['clusters'] = {}
    nodes_site.sort.group_by { |n| n.gsub(/^([a-z]+)-.*/, '\1') }.each_pair do |cluster, nodes_cluster|
      d['sites'][site]['clusters'][cluster] = { 'nodes' => nodes_cluster }
    end
  end
end

YAML::dump(d, STDOUT)
