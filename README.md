# Tests de Packer by HashiCorp

## Intro

Quelques tests du framework Packer pour créer des VM multiprovider (VirtualBox, VMWare, AWS AMI,...) ou encapsuler cela dans des box Vagrant.

Site officiel => [Packer](https://www.packer.io/)

Premiers pas inspirés par la documentation et les exemples suivant :
- https://github.com/luciusbono/Packer-Windows10/
- https://github.com/StefanScherer/packer-windows/
- https://github.com/geerlingguy/packer-boxes/
- https://github.com/chef/bento/tree/master/packer_templates


_Pré-requis_:
- Installer [Packer](https://www.packer.io/downloads/) - testé sur la 1.5.6 (Mai 2020)
- Installer [Vagrant](https://www.vagrantup.com/downloads.html) - testé sur la version 2.2.7 (Janvier 2020)
- Installer [VirtualBox](https://www.virtualbox.org/wiki/Downloads) - testé sur la 6.0.18

## Windows 10

### Script Packer

_But_ : 
- Créer une VM VirtualBox et/ou une box Vagrant à partir de l'iso windows 10 du site Microsoft 
- Passser automatiquement les configurations (création d'un utilisateur, configuration des disques, langues, ...)
- Installer les outils VirtualBox additionnels
- Activer WinRM (pour que Packer commence par provisionner la machine/lancer des commandes à distance puis pour une utilisation future d'Ansible pour du provisionning plus poussé)

_Pré-requis spécifique_:
- L'iso de [windows 10](https://www.microsoft.com/fr-fr/software-download/windows10) - testé avec un W10 Pro - version 1909 (Mars 2020)

_Lignes de commandes_ :

- `packer inspect windows10.json` pour obtenir des infos sur la conf packer (variable, builders, provisionners,...) 
- `packer validate windows10.json` pour valider le script (syntaxe et références)
- `packer build -var 'iso_path=[path to iso]' windows10.json` en précisant le lien vers l'iso windows à installer.

**Note** : Pour ne pas générer la box Vagrant (et garder la VM VirtualBox créé, ajouter le paramètre `-except vagrant`.
Un warning existe sur la vérification du hash de l'iso que j'ai désactivé (l'iso est récupéré directement via l'outil de Microsoft et aucun site officiel donne le hash à obtenir). Possiblité de le calculer sur son poste avec powershell mais on vérifie alors pas grand chose :).

Quelques explications sur le déroulement (visualisable dans la console lors du lancement du build) :
1. Packer créé une VM VirtualBox avec l'iso windows monté
2. La présence d'un fichier _Autounattend.xml_ dans le lecteur de disquette (floppy_files) déclenche automatiquement le passage de l'installation sans intervention humaine (sauf mauvaise conf)
3. Suite au premier redémarrage, Windows exécute la partie "oobeSystem" du fichier Autounattend.xml avec la connexion automatique (AutoLogon obligatoire) puis le lancement des scripts _FirstLogonCommands_
4. Ces scripts permettent d'activer winRM
5. Suite à cela, Packer qui était en attente active sur la connexion WinRM reprend la main.
6. Packer lance les différents _provisionners_ déclarés (le script exécutant l'installation des outils Vbox pour l'instant qui est attaché sur le lecteur F - l'upload wia winRM est problématique à cause de [ce soucis](https://github.com/hashicorp/packer/issues/2648))
7. Packer ferme proprement la VM (toujours sous le format OVF)
8. Packer exécute les post-processors notamment celui de Vagrant qui transforme la VM OVF en box Vagrant (possibilité de garder la VM d'origine avec keep_input_artifact = true)

Quelques ressources intéressantes qui m'ont servis :
[vboxmanage-modifyvm](https://www.virtualbox.org/manual/ch08.html#vboxmanage-modifyvm),
[windows-commands](https://docs.microsoft.com/fr-fr/windows-server/administration/windows-commands/windows-commands)

### Answer file Wndows 10

Quelques liens utiles pour la création du fichier Autounattend.xml :

+ [Introduction très intéressante](https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/how-configuration-passes-work)
+ [Commandes disponibles](https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/components-b-unattend)
+ [Outil web de création rapide de la base](https://www.windowsafg.com/win10x86_x64.html)

## Ubuntu 20.04

### Script Packer

De façon similaire à la partie windows 10, le but de ce template Packer est de :
- Créer une VM VirtualBox et/ou une box Vagrant à partir de l'iso Ubuntu 20.04 LTS 
- Créer la configuration minimal de l'OS (utilisateurs, langues, disques...)
- Installer les outils VirtualBox additionnels
- Activer l'accès SSH (pour packer puis faire du provisionning un peu plus poussé dans un second temp avec ansible par exemple)

_Pré-requis spécifique_:
- L'iso de [Ubuntu 20.04](http://cdimage.ubuntu.com/ubuntu-legacy-server/releases/20.04/release/) - testé avec la version serveur du 2020-04-23 07:47

Toujours mieux de télécharger avant le fichier iso en local et changer le path dans le script. Si le fichier n'est pas trouvé par Packer, celui-ci le télécharge automatiquement sur le site d'Ubuntu.

**Note** : : Bien prendre un legacy server d'ubuntu et pas la distribution "live server" qui ne s'installe pas de la même manière...

_Lignes de commandes_ :

- `packer inspect ubuntu20.json` pour obtenir des infos sur la conf packer (variable, builders, provisionners,...) 
- `packer validate ubuntu20.json` pour valider le script (syntaxe et références)
- `packer build ubuntu20.json` avec la possibilité d'écraser les variables iso_local et iso_md5 si besoin

**Note** : Pour ne pas générer la box Vagrant (et garder la VM VirtualBox créé, ajouter le paramètre `-except vagrant`.

### Preseed Ubuntu/Debian

La boot_command est un peu plus compliquée que sur windows, les premières instructions permettent de sortir de l'installer en mode graphique qui est lancé automatiquement au démarrage et de passer en ligne de commande :
````
 "<esc>",
 "<esc>",
 "<enter>"
````

Puis la séquence est entrée par packer en spécifiant le fichier preseed.cfg à utiliser. La ligne est réduite au minimum par rapport aux exemples de geerlingguy ou des équipes de chef.io notamment pour :
- Eviter de [spécifier la langue et le clavier avant](https://www.debian.org/releases/stretch/amd64/apbs02.html.fr#preseed-auto) en utilisant l'option auto=true (l'alias "auto" ne marchant pas)
- Passer le [pb Hostname](https://bugs.launchpad.net/ubuntu/+source/preseed/+bug/1452202) en utilisant priority=critical qui supprime les questions "superflues").

Quelques liens intéressants pour créer le preseed.cfg Debian :
- https://www.debian.org/releases/stretch/amd64/apbs04.html.fr
- https://wiki.debian.org/DebianInstaller/Preseed

## VM OVF

Si on exclut le post-processor vagrant ou si l'on conserve la VM d'origine, le fichier ovf présent dans `.\output-virtualbox-iso` peut être utilisé pour lancer directement des nouvelles VMs dans Virtualbox (possibilté de reconfigurer certains paramètres à l'import dans VB comme mémoire, CPU, network,...).

## Vagrant

Sinon Packer génère un fichier `.box`.

Pour l'utiliser:
- `vagrant box add --name "trebuac/windows10" .\build\virtualbox_windows-10.box` référence votre box dans votre repo vagrant local
- `vagrant box list` pour vérifier la bonne insertion de la box.
- `vagrant init "trebuac/windows10"` dans le dossier de votre choix pour générer le fichier de conf vagrant lié à cette box (et sauvegarder les fichiers). Pour info, certains paramètre sont par défaut dans la box (fichier `vagrantfile.template` insérer par Packer)

- `vagrant up` pour lancer la VM et enjoy :)

Note : La fermeture de la gui lancé n'éteint pas toujours la VM côté Vagrant. Voir `vagrant global-status` et utiliser `vagrant  reload/suspend/halt/destroy`

Plus de tests dans le projet [vagrant](https://github.com/Trebuac/Vagrant).