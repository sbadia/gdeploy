gDeploy
=============

Glite Deployment on [Grid'5000](https://www.grid5000.fr/).

Description
-------

[gDeploy](http://sbadia.github.com/gdeploy/) est un petit [script](http://dev.sebian.fr/redmine/projects/gdeploy) écrit en ruby, dans le but de déployer
et de configurer les services de base du midleware de grilles de calcul [gLite](http://glite.cern.fr/).

gDeploy utilise les classes ruby net/ssh,scp.

L'environnement utilisé pour le déploiement est un système [Scientific
Linux](http://www.scientificlinux.org/) 5.5, et la version de [gLite](http://glite.cern.fr/) est la 3.2

Dépendances
-------
Pour fonctionner gdeploy a besoin de trois tgz, il va les chercher
directement dans le public home de sbadia.

* hostkeys.tgz les certificats de la grille crée.
* repo.tgz le définitions des repo gLite.
* ssh-keys.tgz les clés ssh de la grille.

Voir [http://public.nancy.grid5000.fr/~sbadia/glite/](http://public.nancy.grid5000.fr/~sbadia/glite/) depuis g5k.

Licence
-------
Ce script est sous licence GPLv2.

Contacts
-------
* Lucas Nussbaum (<lucas.nussbaum@loria.fr>)
* Sebastien Badia (<sebastien.badia@inria.fr>)

Utilisation
-------
1. Rapatrier l'archive sur g5K.
2. Lancez g5kjobs.rb pour réserver les noeuds `ruby g5kjobs.rb > nodes`
3. Kadeployez le tout `kadeploy3 -f nodes --multi-server -a http://public.nancy.grid5000.fr/~sbadia/sl55-ahci.dsc -k ~/.ssh/id_dsa.pub -o ~/dnodes`
4. Générez la description de la plateforme `ruby list2yaml.rb -g dnodes > g5k.yaml`
5. Lancer la configuration `time ruby config-glite.rb g5k.yaml`.

Lexique
-------

* CE = Computing Element (Cluster).
* SE = Stockage Element (Baie). Gsiftp transfert intégral, Rfio accès direct API Posix Like.
* FTS = File Transfert Service.
* WMS = Workload Management System (meta-scheduler). -> Condor-G.
* BDII = Système d'Information (Publication des ressources et inforamtions diverses (stats dynamiques).
* VOMS = Virtual Organisation Membership Service.
* LFC = File Catalog (non distribué).
* VO = Virtual Organisation.
* EGEE = Enabling Grids for E-sciencE.
* UI = User Interface (pas GUI) mais client de la grille.
* SRM = Storage Ressource Manager.
* ROC = Regional Operation Center.
* RC = Replica Catalog.
* GOC = Grid Operations Center.
* WN = Working Node.
* LB = Logging & Brokekeeping.
* JSS = Job Submission Service.
* RB = Ressources Broker.
* IS = Information System.

Deployments
-------
Image new (ahci):

* Graphene
*  Adonis
*  Edel
*  Chinqchint
*  Chirloute
*  Parapide
*  Parapluie

Image previous (ata_piix):

* Genepi
* Griffon
* Paradent
