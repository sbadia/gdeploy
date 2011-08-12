#!/usr/bin/ruby -w

require 'pp'
require 'yaml'
require 'optparse'
require 'net/scp'
require 'net/ssh'
require 'net/ssh/multi'
require 'misc/peach'

$tlaunch = Time::now

if ARGV.length < 1
  puts "config-glite YAMLCONFIG 1 (for install)"
  exit 1
end


def time_elapsed
	return (Time::now - $tlaunch).to_i
end # def:: time_elapsed

install = 0
$d = YAML::load(IO::read(ARGV[0]))
puts "\033[1;32m####\033[0m Loaded config file #{ARGV[0]}"

DIR = File.expand_path(File.dirname(__FILE__))

extinction = Proc.new{
  puts "Received extinction request..."
}
%w{INT TERM}.each do |signal|
  Signal.trap( signal ) do
      extinction.call
    exit(1)
  end
end

$nodes = []

$d['VOs'].each_pair do |name, conf|
  $nodes << conf['voms']
end

$d['sites'].each_pair do |sname, sconf|
   $nodes << sconf['bdii']
   $nodes << sconf['ce']
   $nodes << sconf['batch']
   $nodes << sconf['ui']
  sconf['clusters'].each_pair do |cname, cconf|
   $nodes += cconf['nodes']
  end
end

if install == 1:
  puts "\033[1;36m###\033[0m {#{time_elapsed}} -- Launch bt client"
  Net::SSH::Multi.start do |session|
    $nodes.each do |node|
      session.use "root@#{node}"
    end
      session.exec("wget http://fgrimoire.nancy.grid5000.fr/tar.sh -q && sh tar.sh")
      session.loop
  end
  puts "\033[1;36m###\033[0m {#{time_elapsed / 60} min}"
else
  puts "\033[1;31m==> No install\033[0m"
end
