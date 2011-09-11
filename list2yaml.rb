#!/usr/bin/ruby -w

=begin

List2yaml a tool for convert list of nodes to a gLite infrastructure
description, in order to deploy it on Grid'5000.
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
