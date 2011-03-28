#!/usr/bin/ruby -w

def fct(type ,msg)
	if "#{type}" == "alert" then
	  puts "Alerte fonction : #{msg}"
	else
	  puts "Message fonction : #{msg}"
	end
end

puts "Hello World !"
fct('alert','Scientific Linux Deploy')
fct('msg','Ça marche')
puts "Toto"
