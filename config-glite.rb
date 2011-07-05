#!/usr/bin/ruby -w

require 'pp'
require 'yaml'
require 'optparse'

if ARGV.length != 1
  puts "config-glite YAMLCONFIG"
  exit 1
end

$d = YAML::load(IO::read(ARGV[0]))
puts "## Loaded config file #{ARGV[0]}"

puts "## Configuring VOs"
$d['VOs'].each_pair do |name, conf|
  puts "## Configuring VO=#{name} on VOMS=#{conf['voms']}"
  $my_vo = name
  $my_voms = conf['voms']
  # FIXME
end

puts "## Configuring sites"
$d['sites'].each_pair do |name, conf|
  puts "## Configuring site=#{name}"
  puts "# BDII on #{conf['bdii']}"
  # FIXME
  puts "# Batch on #{conf['batch']}"
  # FIXME
  puts "# CE on #{conf['ce']}"
  # FIXME
  puts "# UI on #{conf['ui']}"
  # FIXME
  puts "## Configuring #{name}'s clusters"
  conf['clusters'].each_pair do |name, conf|
    puts "# Cluster #{name} on #{conf['nodes'].join(' ')}"
    conf['nodes'].each do |n|
      puts "#{n} ..."
      # FIXME
    end
  end
end
