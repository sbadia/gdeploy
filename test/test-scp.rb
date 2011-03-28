#!/usr/bin/ruby -w
require 'net/scp'

fichier = ["users","groups","wn-list"]
puts fichier
fichier.each{|f|
Net::SCP.start("local", "sbadia") do |scp|
  scp.upload!("/home/sbadia/#{f}.conf", "/home/sbadia/") do |ch, name, sent, total|
    puts "#{name}: #{sent}/#{total}"
  end
end
}
