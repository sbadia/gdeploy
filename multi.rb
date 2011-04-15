#!/usr/bin/ruby -w

begin
  require 'optparse'
  require 'ostruct'
  require 'net/scp'
  require 'net/ssh'
  require 'net/ssh/multi'
rescue LoadError
end

# Configuration globale au script
#
$cfg = OpenStruct::new
$cfg.confnodes = []
$cfg.debug = false
$cfg.user = ENV['USER']
$cfg.verbose = false

DIR = File.expand_path(File.dirname(__FILE__))


# Récupération d'une liste de noeuds en fonction de la méthode
# de collecte choisie.
#
def nodes_file(file)
  begin
    return IO::read(file).split("\n").sort.uniq
  rescue
    return []
  end
end

if defined?($PROGRAM_NAME)
  progname = File::basename($PROGRAM_NAME)
else
  progname = "mutli-gdeploy"
end

# Options
# pour une utilisation standard lancer
# $ ruby gdeploy.rb -vcs
# Le script fetch alors la variable $OAR_NODE_FILE, crée la configuration (c),
# l'envoie sur les nodes (s) et affiche les résultats (v).
#
opts = OptionParser::new do |opts|
  opts.version = "#{progname} v0.2 2011-03-07 12:02:09 sbadia"
  opts.release = nil
  opts.program_name = progname
  opts.banner = "Usage: #{progname} [options]"
  opts.separator 'Contact: Sebastien Badia <sebastien.badia@inria.fr>'
  opts.separator ''
  opts.separator 'General options:'
  opts.on('-m', '--machine MACHINE', 'Node to run on') { |n| $cfg.confnodes << n }
  opts.on('-f', '--file MACHINELIST', 'Files containing list of nodes')  { |f| $cfg.confnodes = nodes_file(f) }
  opts.separator ''
end

begin
  opts.parse!(ARGV)
rescue OptionParser::ParseError => pe
  opts.warn pe
  puts opts
  exit 1
end

# Pour intercepter une commande d'extinction et afficher le message.
#
extinction = Proc.new{
  puts "Received extinction request..."
}
%w{INT TERM}.each do |signal|
  Signal.trap( signal ) do
      extinction.call
    exit(1)
  end
end

if $cfg.confnodes.empty?
  if ENV['OAR_NODE_FILE'].nil?
    jputs("No nodes","$OAR_NODE_FILE ?")
    exit(1)
  else
    $nodes = nodes_file(ENV['OAR_NODE_FILE'])
  end
else
  $nodes = $cfg.confnodes
end

if $nodes.empty?
  jputs("No nodes","See help -h")
  exit(1)
end

# Nom du site à traiter.
# sites($nodes)
#
def sites(nodes)
  sites = []
  nodes.each do |n|
    sites << n.split('.').fetch(1)
end
  return sites.uniq
end

sites($nodes).each do |s|
  begin
    Net::SCP.start(s, $cfg.user) do |scp|
      scp.upload!("/home/#{$cfg.user}/gdeploy", "/home/#{$cfg.user}", :recursive => true)
    end
  rescue
    puts "Erreur Scp gDeploy sur #{s}"
  end
end

Net::SSH::Multi.start do |session|
  session.on_error = :warn
  sites($nodes).each do |site|
    session.use "#{$cfg.user}@#{site}" #if $nodes[node].nil?
  end
  session.exec("cd /home/#{$cfg.user}/gdeploy/ && ruby gdeploy.rb -vcs -f ./conf/#{site}")
  session.loop
end
