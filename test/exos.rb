## TP1 Exo1
#!/usr/bin/ruby -w
puts "Intro Ruby calcul de périmètre"

puts "Quelle est la valeur de x ? :"
x = gets.strip

puts "Quelle est la valeur de y ? :"
y = gets.strip

puts "Périmetre: ",2*x.to_i+2*y.to_i;

# puts "Périmètre est de #{2*(x.to_i+y.to_i))}"

## Exo 2
#!/usr/bin/ruby -w
puts "Calcul de la moyenne de 10 notes !"
puts "Entrez les notes :"

somme = 0

10.times do
	somme += gets.to_i
end

puts "La moyenne des 10 notes entées est de : #{somme/10}"

## Exo 3
#!/usr/bin/ruby -w
puts "Programme qui affiche la moyenne, et les notes dans l'ordre croissant"
puts "Entrez les notes :"

a = 0
total = []
moyenne = 0

10.times do |a|
	total[a]=gets.to_i
	moyenne+=total[a]
end

puts total.sort
puts "Moyenne :",moyenne/3

#Correction
#!/usr/bin/ruby -w
#tab = []

#10.times {tab << gets.strip.to_f }
#	tab.sort.each { |i| puts i }
#	somme = tab.inject(0) { |somme, i| somme + i}

#puts "La moyenne est de :  #{somme/tab.length}"

## Exo 4
#!/usr/bin/ruby -w
exec("ps aux | wc -l")

## Exo 5
#!/usr/bin/ruby -w

20.times { |x| puts x + 1 }

for i in 1..20
	puts i
end

## Exo 6
#!/usr/bin/ruby -w

class Array; def sum; inject( nil ) { |sum,x| sum ? sum+x : x }; end; end
class Array; def mean; sum / size; end; end 
tableau=[];
a=0;
file = File.open("Temperatures", "r")

file.each do |line|
   tableau[a]=line.to_i;
   a+=1;
end

puts tableau.max;
puts tableau.min;
puts tableau.mean;

## Exo 7
#!/usr/bin/ruby -w

tab = { }

# Overture du fichier et lecture
File.open('Annuaire','r') do |file|
	file.each_line do |line|
		infos = line.split(':')
		tab[infos[0].strip] = infos[1].strip
	end
end

#Affichage annuaire
puts "L' annuaire"
tab.each { |cle,valeur| puts "#{cle} -> #{valeur}" }

print "\nQuel nom recherché ?"
nom = gets.strip
puts "Le numéro correspondant est #{ tab[nom] }"

#!/usr/bin/ruby -w

puts "Saisir un nom : "
nom = gets.chomp
noms = {}

File.open("repertoire", "r") do |file|
        file.each_line do |line|
                leNom, leTel = line.split(" : ")
                noms[leNom] = leTel
        end
end

unless (i = noms.keys.select { |x| x =~ /#{nom}/i }).empty?
        print i.map { |x| noms[x] }
else
        puts "non trouvé"
end

## Exo 7 bis
#!/usr/bin/ruby -w

tab= {}

File.open('Annuaire','r') do |file|
	file.each_line do |line|
		infos=line.split(':')
		tab[infos[0].strip]=infos[1].strip
	end
end

tab.each {|cle,valeur| puts "#{cle} -> #{valeur}"}
nom=gets.strip
puts "le nom correstpondant est #{tab[nom]}"

## Temperatures
12
1
5
7
3

## Annuaire
Seb : 1234567890
Luc : 9876543210
Ju : 1245653298
Tutu: 1346795623

## TP2 Exo 1
#!/usr/bin/ruby -w
#
# Appel du scipt avec nom du srt en argument 1 et le décalage en argument 2 (1000 pour 1 sec)
#
inputfile=ARGV[0];
delay=ARGV[1];

if ARGV.length !=2
	puts "Erreur il vous manque des arguments"
	puts "Notice:\n - Argument 1: nom du srt\n - Argument 2: décalage en millième de secondes (1000 pour 1 sec)"
end

outfile = File.open('Final.srt','w')

if File.file?(inputfile)&&File.writable?(inputfile)
	puts "Fichier Ok !\nDébut du traitement..."
	File.open(inputfile,'r') do |file|
		file.each_line do |line|
			if line =~ /(\d{2}:\d{2}:)(\d{2}),(\d{3})( --> \d{2}:\d{2}:)(\d{2}),(\d{3})/
			
				new_start="#{$2}#{$3}".to_i+delay.to_i
				new_end="#{$5}#{$6}".to_i+delay.to_i
				
				while new_start.to_s.length<5
					new_start="0#{new_start}"
				end

				while new_end.to_s.length<5
					new_end="0#{new_end}"
				end
				
				new_start= new_start.to_s.insert(-4, ',')
				new_end=new_end.to_s.insert(-4, ',')
				
				line = "#{$1}"+new_start.to_s+"#{$4}"+new_end.to_s
				outfile.write line+"\n"
			else
				outfile.write line
			end
		end
	end
		puts "Conversion Terminée avec Succès !"
else
	puts "Erreur sur le fichier"
end

## Exo 1 Ju
#!/usr/bin/ruby -w
#
# Scipt de Julien, en transformant le parse en objet de type time
#

require 'time.rb'

def decal(h, m, s, ms, d)
	t = Time.mktime(2000, 1, 2, h, m, s, ms.to_i * 1000)
	t += d
	return t.strftime('%H:%M:%S,') + sprintf('%03d', (t.usec / 1000))
end

if ARGV.length != 2
	puts "Usage: #{$0} <filename> <shift in seconds (float)>"
	exit
end

if !File.readable?(ARGV[0])
	puts "Je ne peux pas lire le fichier #{ARGV[0]} !"
	exit 4
end

d = ARGV[1].to_f
File.open(ARGV[0], 'r' do |file|
	file.each_line do |line|
		if line =~ /(\d\d):(\d\d):(\d\d),(\d\d\d) --> (\d\d):(\d\d):(\d\d),(\d\d\d)/
			print decal($1, $2, $3, $4, d), ' --> ', decal($5, $6, $7, $8, d), "\n"
		else
			puts line
		end
	end
end

## Exo 2
#!/usr/bin/ruby -w
#
# Afficher par ordre alphabetique tous les utilisateurs du system
#

utils = Array.new
File.open("/etc/passwd", 'r') do |file|
	file.each_line do |line|
		line.gsub(/^([^:]*)/) { |nom| utils << nom }
	end
end

utils.sort!.each { |u| puts u }

## Exo 3
#!/usr/bin/ruby -w

users = Array.new
IO.read("/etc/passwd").gsub(/^([^:]*)/) {|nom| users << nom}

users.sort!.each do |u|
	print u
	puts (File.exist?("/home/" + u))? "***** a un home" : "n'en a pas"
end

## Exo 3 bis
#!/usr/bin/ruby -w

if ARGV.length != 1
	puts "Usage #{$0} <quotat>"
	exit
end

octets = ARGV[0].to_i
utils = Array.new

IO.read("/etc/passwd").gsub(/^([^:]*)/) {|nom| utils << nom if File.exist?("/home/" + nom)}

utils.sort!.each do

## TP3 Exo 1
#!/usr/bin/ruby -w

1.upto(4) do
	fork do
		t=Time.now
		puts "[#{t.strftime("%H:%M:%S")},#{"%06d" % t.usec.to_i}]
		Bonjour je suis  le Processus : #{Process.pid}"
		exit(1)
	end
end

1.upto(4) do
	pid=Process.wait
	t=Time.now
	puts "[#{t.strftime("%H:%M:%S")},#{"%06d" % t.usec.to_i}] Mon fils
	#{pid} est terminé avec le code #{$?.exitstatus}!"
end

# Pére Exo 2
#!/usr/bin/ruby -w

# Définitions des variables utilisés
#
nbProcess=5
repSource='/usr/bin/'
listeFich='listeFich'
nomFils='./ex3.rb'
repDest='.'
fichMsg='messages.log'
lockfile="/tmp/lockfile"

# On crée la liste des fichiers à traiter
#
File.open(listeFich,"w") do |f| 
    Dir.open(repSource) do |rep|
        rep.each do |nom|
            f << nom << "\n" if File.lstat(repSource+nom).file?
        end 
    end 
end

# On initialise les logs et les verrous
#
`touch #{fichMsg}`
`touch #{lockfile}`

# Lancement des différents fils
#
1.upto(nbProcess) do
    fork do
        exec(nomFils, listeFich, repDest, fichMsg,lockfile)
    end 
end

# Attente de la fin des fils
#
1.upto(nbProcess) do
    pid=Process.wait
    puts "Mon fils #{pid} est terminé avec le code de retour #{$?.exitstatus}"
end

# On fait le ménage
#
`rm #{lockfile}`
`rm #{listeFich}`

## Fils Exo 3
#!/usr/bin/ruby -w

listeFich = ARGV[0]
repDest = ARGV[1]
fichMsg = ARGV[2]
lockfile = ARGV[3]

puts "je suis le fils #{Process.pid}"
commande= "echo coucou"

while !File.zero?(listeFich) do
    line = ""
    puts "#{Process.pid} en attente de verrou"
    lf=File.new(lockfile)
    lf.flock(File::LOCK_EX)
    puts "verrou en place"
    
    File.open(listeFich,"r") do |f| 
    if !File.zero?(listeFich) 
    	line=f.gets
    end 
end

# Supprime la première ligne
#
`sed -i 1d #{listeFich}`

# Libère le verrou
#
puts "#{Process.pid} va liberer le verrou"

lf.flock(File::LOCK_UN)
lf.close

puts "#{Process.pid} unlocked !"

# Traitement
#
if line !=""
    puts "#{Process.pid} traite : #{line}"
end
`#{commande} #{fichMsg}`

sleep(1)
end

## Test Processus
#!/usr/bin/ruby -w

1.upto(4) do |i|
	if fork != nil
		puts "pid = #{Process.pid}, ppid = #{Process.ppid}, i = #{i}"
	else
		break
	end
end
puts "Pid #{Process.pid}: terminé"

################ Interfaces Graphiques
#!/usr/bin/ruby -w
require 'Qt4'
 
Qt::Application.new(ARGV) do
    Qt::Widget.new do
 
        self.window_title = 'Hello QtRuby v1.0'
        resize(200, 100)
 
        button = Qt::PushButton.new('Quit') do
            connect(SIGNAL :clicked) { Qt::Application.instance.quit }
        end
 
        label = Qt::Label.new('<big>Hello Qt in the Ruby way!</big>')
 
        self.layout = Qt::VBoxLayout.new do
            add_widget(label, 0, Qt::AlignCenter)
            add_widget(button, 0, Qt::AlignRight)
        end
 
        show
    end
 
    exec
end

#!/usr/bin/ruby -w
require 'Qt4'
# installer le paquet qt ruby "libqt4-ruby"
a = Qt::Application.new(ARGV)
hello = Qt::PushButton.new("Hello World!")
hello.resize(100, 30)
hello.show
a.exec

#!/usr/bin/ruby -w
require 'Qt4'
a = Qt::Application.new(ARGV)

class Test < Qt::Object
	slots 'myslot()'

  def myslot()
    puts 'Coucou'
  end
end

class ExecutionState < Qt::CheckBox
	slots 'process(bool)'
	def initialize(text, parent, name, state)
	  super(text, parent)
	  checked = state
  	  @name = name
	  connect(self, SIGNAL('toggled(bool)'),self, SLOT('process(bool)'))
	end

	def process(state)
	  if state
		`chmod a+x #{@name}`
	  else
		`chmod a-x #{@name}`
	  end
	end
end

# Argument
#
name = ARGV[0]
if File.exist?(name)

# Window Création
#
window = Qt::Widget.new()
window.resize(300, 200)

# Widget Création
#
file = Qt::Label.new("Fichier : " + name, window)
file.setGeometry(10, 10, 250, 30)
change = Qt::PushButton.new("Changer", window)
change.setGeometry(10, 40, 100, 30)
right = ExecuteState.new("Droits d'execution", window, name, state)
right.setGeometry(10, 70, 250, 30)

# Communication
#
t = Test.new
Qt::Object.connect(change, SIGNAL('clicked()', t, SLOT('myslot()'))

# Affichage
#
window.show
a.exec

#!/usr/bin/ruby -w
require 'Qt4'

Qt::Application.new(ARGV) do
	Qt::Widget.new do
		
		self.window_title = 'Super ExecFich'
		resize(500, 300)

		fichier = Qt::PushButton.new('Fichier') do
			connect(SIGNAL :clicked) {
				puts("coucou")
			}
		end
		button = Qt::PushButton.new('Quit') do
			connect(SIGNAL :clicked) { Qt::Application.instance.quit }
		end
		
		label = Qt::Label.new('<big>Super Activateur</big>')
		self.layout = Qt::VBoxLayout.new do
			add_widget(label, 0, Qt::AlignCenter)
			add_widget(fichier, 0, Qt::AlignRight)
			add_widget(button, 0, Qt::AlignRight)
		end
		
		show
	end
	exec
end
