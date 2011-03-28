#!/usr/bin/ruby -w
#
# YAML TO HTML (LATENCY FLOW TESTS)
# 	With great colors !
# 
# OPTIONS : Voir -h
#
# AUTEURS : <julien@vaubourg.com>
#           <seb@sebian.fr> <badia.seb@gmail.com>
#
# 2010, pour Grid5000
#

# Ce script a pour but de transformer le fichier d'export yaml du programme 'latency_flow_test'
# en un tableau html, avec des couleurs. (faisant ressortir les min/max ainsi que les quartiles)

# Utilise la classe yaml, il sera peut etre necessaire de l'installer
require 'yaml'
require 'getoptlong'
    
    # Les options -i pour input et -o pour output sont indispensables.
    opts = GetoptLong.new(
      [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
      [ '--yaml', '-i', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--html', '-o', GetoptLong::REQUIRED_ARGUMENT ]
    )

fileyaml = html = ''

opts.each do |opt, arg|
  case opt
        when '--help'
		puts("\nYAML TO HTML")
		puts("----------------------------------")
		puts("This script allows the conversion of YAML file")
		puts("(output file of latency_flow_test) into an HTML table.")
		puts("An HTML table was easily viewable on a website.\n")
		puts("The color code allows to visualize at once the most low knots,")
		puts("and those them more successful")
		puts("----------------------------------")
		puts("Usage :\n")
		puts("\t toYaml.rb -i <yaml file> -o <html file>")
		puts("\nOptions :\n")
		puts("\t-i <file> : Yaml input.")
		puts("\t-o <file> : Html output.\n")
		puts("\t-h        : This help.\n")
		puts("\nLegend of HTML Table :\n")
		puts("\tRed background : \tlowest latency/flow")
		puts("\tGreen background : \thigher latency/flow")
		puts("\tGreen write : \t\tFirst quartile")
		puts("\tRed write : \t\tLast quartile\n")
		puts("\nAuthors :\n\t<julien@vaubourg.com>\n\t<sebastien.badia@gmail.com>\t<seb@sebian.fr>\n")
		puts("\nAsrall 2010 for Grid5000")
	  exit!(1)

        when '--yaml'
		fileyaml = arg

        when '--html'
            	html = arg
  
  end
end

# Verification d'usage, les options ont elles ete passees
if fileyaml.empty? || html.empty?  then
        puts "Veuillez preciser des arguments (fichier d'import et d'export)"
        puts "Consultez l'aide (Option -h)"
        exit!(1)
end

# Parse directement le fichier yaml, en reconnait l'arborescence, et fait un tableau avec celle-ci.
benchResults = YAML.load_file(fileyaml)

# Creation des tableaux de initialisation de l'ecc, ecc pour effectif cumule croissant
flows = []
latencys = []
eccFlow = eccLatency = sumLatency = sumFlow = 0

benchResults.each do |sender, recvers|
	recvers.each do |recver, results|
		# manque de pointeurs...
		latencys << {
			:sender => sender,
			:recver => recver,
			:latency => results['latency']
		}

		flows << {
			:sender => sender,
			:recver => recver,
			:flow => results['flow']
		}

		sumLatency += results['latency']
		sumFlow += results['flow']
	end
end

latencys.sort! { |a, b| a[:latency] <=> b[:latency] }
flows.sort! { |a, b| a[:flow] <=> b[:flow] }

# Cumul des latences et des débits
(0...flows.size).each do |i|
	eccLatency = latencys[i][:ecc] = latencys[i][:latency] + eccLatency
	eccFlow = flows[i][:ecc] = flows[i][:flow] + eccFlow
end

# Calcul des quartiles
q1Latency = latencys.last[:ecc] / 4
q3Latency = q1Latency * 3
q1Flow = flows.last[:ecc] / 4
q3Flow = q1Flow * 3

# On cree un varaiable 'matrix' dans laquelle on concatenera tout le html genere
matrix = "<tr><th></th><th class=\"bot\">#{ benchResults.keys.join('</th><th class="bot">') }</th><th class=\"bot\"></th></tr>"
line = 0

benchResults.each do |sender, recvers|
	matrix += '<tr><th class="right' + (line == benchResults.size - 1 ? " bot" : "")  + '" rowspan="2">' + sender + '</th>'
	# On rempli la matrix avec tout les debits
	column = 0
	recvers.each do |recver, results|
		matrix += '<td></td>' if line == column
		column += 1

		matrix += <<-HTML
		<td class="flow#{
			case results['flow']
				when flows.first[:flow]
					" min"
				when flows.last[:flow]
					" max"
				else
					case flows[flows.index { |x| x[:sender] == sender && x[:recver] == recver }][:ecc]
						when 0..q1Flow
							" low"
						when q3Flow..flows.last[:ecc]
							" high"
					end
			end
		}">#{results['flow']}</td>
HTML
	end

	matrix += (line == benchResults.size - 1 ? "<td></td>" : "") + '<td class="unite flow">MB/s</td></tr><tr>'

	column = 0
	recvers.each do |recver, results|
		matrix += '<td class="empty"></td>' if line == column
		column += 1
		# Mise en place des latences dans la matrice
		matrix += <<-HTML
		<td class="latency#{
			case results['latency']
				when latencys.first[:latency]
					" min"
				when latencys.last[:latency]
					" max"
				else
					case latencys[latencys.index { |x| x[:sender] == sender && x[:recver] == recver }][:ecc]
						when 0..q1Latency
							" low"
						when q3Latency..latencys.last[:ecc]
							" high"
					end
			end
		}">#{results['latency']}</td>
HTML
	end
	
	matrix += (line == benchResults.size - 1 ? '<td class="empty"></td>' : "") + '<td class="unite latency">&micro;s</td></tr>'
	line += 1
end

# Ecriture du fichier de sortie html, avec la CSS et la matrix prealablement remplie
File.open(html,'w') do |fo|
 fo << <<-HTML
	<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
	<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
	<head>
	<title>Flow Latency Tests - Matrix</title>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
	<style type="text/css">
	<!--
		body {
			background-color: #EEE;
			font-family: sans-serif;
		}

		h1, h2 {
			text-align: center;
			font-size: 30px;
			margin: 5px;
		}

		h2 { font-size: 20px}

		table {
			border: 1px solid #000;
			border-bottom: 0;
			text-align: center;
			margin: 30px auto;
		}

		th {
			background-color: #BBB;
			padding: 5px;
		}

		th.bot { border-bottom: 1px solid #000 }
		th.right { border-right: 1px solid #000 }

		td {
			background-color: #AAA;
			padding: 10px;
		}

		td.latency {
			background-color: #EEE;
			border-bottom: 1px solid #000;
		}

		td.flow { background-color: #CCC }

		td.min, td.max {
			background-color: red;
			font-weight: bold;
			color: white;
		}

		td.max { background-color: green }

		td.high { color: green }
		td.low { color: red }

		td.empty { border-bottom: 1px solid #000 }
		td.unite { font-weight: bold }

		address {
			text-align: center;
			font-size: 10px;
		}
	-->
	</style>
	</head>

	<body>
	<h1>Latency flow tests</h1>
	<h2>(with nice colors)</h2>
	
	<table cellpadding="0" cellspacing="0">
	#{matrix}
	</table>

	<address>&copy; ASRALL 2010 - All rights reserved (watch it pay)</address>
	</body>
	</html>

HTML
end
