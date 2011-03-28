#!/usr/bin/ruby -w
#

begin
  require 'getoptlong'
rescue LoadError
end

#puts "Deploy Glite on Grid5000"
	opts = GetoptLong.new(
		[ '--help', '-h', GetoptLong::NO_ARGUMENT ],
		[ '--cream', '-c', GetoptLong::REQUIRED_ARGUMENT ],
		[ '--lfc', '-l', GetoptLong::REQUIRED_ARGUMENT ],
		[ '--bdii', '-d', GetoptLong::REQUIRED_ARGUMENT ],
		[ '--storage', '-s', GetoptLong::REQUIRED_ARGUMENT ],
		[ '--ui', '-u', GetoptLong::REQUIRED_ARGUMENT ],
		[ '--wn', '-w', GetoptLong::REQUIRED_ARGUMENT ],
		[ '--batch', '-b', GetoptLong::REQUIRED_ARGUMENT ]
	)

ce = lfc = se = bdii = batch = ui = wn = ''

opts.each do |opt, arg|
	case opt
		when '--help'
			puts("\nDeploy Glite on Grid'5000")
			puts("----------------------------------")
			puts("This script deploy a basic glite platform on Grid5000.\n")
			puts("The deployment include :\n")
			puts("\t - Bdii (slapd) host")
			puts("\t - Batch System Server host")
			puts("\t - Cream Computing Element")
			puts("\t - User Interface host")
			puts("\t - Lfc host")
			puts("\t - Workers Nodes")
			puts("----------------------------------")
			puts("Usage :\n")
			puts("\t gdeploy.rb -c <ce> -l <lfc> -s <se> -b <batch> -u <ui> -w <list wn>")
			puts("\nOptions :\n")
			puts("\t-c <ce> : Ce Host.")
			puts("\t-l <lfc> : Lfc Host.\n")
			puts("\t-s <se> : Se Host.\n")
			puts("\t-d <bdii> : Bdii Host.\n")
			puts("\t-b <batch> : Batch Host.\n")
			puts("\t-u <ui> : Ui Host.\n")
			puts("\t-w <wn> : Workers Nodes.\n")
			puts("\t-h        : This help.\n")
			puts("\nAuthors :\n\t<sebastien.badia@loria.fr>\t<sebastien@badia.fr>\n")
			puts("\nGrid5000 - 2010")
		exit!(1)

		when '--cream'
			ce = arg
		when '--lfc'
			lfc = arg
		when '--storage'
			se = arg
		when '--batch'
			batch = arg
		when '--ui'
			ui =arg
		when '--wn'
			wn = arg
		when '--bdii'
			bdii =arg
	end
end

if ce.empty? || lfc.empty? || se.empty? || batch.empty? || ui.empty? || wn.empty? || bdii.empty? then
	puts "Erreur arguments"
	puts "Consultez l'aide"
	exit!(1)
end
puts "variables"+" "+ce+" "+lfc+" "+se+" "+batch+" "+ui+" "+wn+" "+bdii
puts "Hello"
