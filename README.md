# MSDOS-0
Clone de MS-DOS en langage de programmation Pascal (Turbo Pascal ou Free Pascal) avec un support de la langue française, allemande et anglaise.

MSDOS-0 est un projet de développement d'un système d'exploitation inspiré de MS-DOS, entièrement conçu autour du langage de programmation Pascal, principalement à l'aide de Turbo Pascal et Free Pascal. Son objectif est de recréer et de réinterpréter les fonctionnalités des systèmes d'exploitation DOS traditionnels, tout en explorant les mécanismes fondamentaux de leur fonctionnement. Le projet s'inscrit dans une démarche à la fois technique, éducative et historique, visant à démontrer les possibilités du langage Pascal dans le développement de logiciels système de bas niveau.

Contrairement à une simple collection d'utilitaires reproduisant les commandes de MS-DOS, MSDOS-0 possède son propre noyau développé en Pascal et peut être véritablement démarré à partir d'une disquette ou d'une image disque amorçable. Cette particularité constitue l'un des aspects les plus importants du projet, puisqu'elle permet d'aborder directement des concepts fondamentaux tels que le démarrage d'un ordinateur, les interactions avec le matériel, la gestion des disques, les fichiers et l'exécution des commandes du système d'exploitation.

Le projet comprend également une vaste collection de commandes et d'utilitaires inspirés de différentes générations de MS-DOS et de PC-DOS. On y retrouve notamment des outils de manipulation de fichiers, de gestion des répertoires, de formatage, de partitionnement, de récupération de données, de diagnostic du matériel et de gestion de la mémoire. Plusieurs applications historiques sont également revisitées, notamment les éditeurs de texte, les interpréteurs BASIC, les outils de débogage et l'environnement graphique DOS Shell. Certaines commandes proposent des fonctionnalités supplémentaires par rapport à leurs équivalents historiques, particulièrement en matière de manipulation et de traitement des images de disques.

MSDOS-0 accorde également une place importante à l'internationalisation, en proposant une prise en charge de plusieurs langues, notamment le français, l'anglais et l'allemand. Cette approche vise à rendre l'environnement DOS plus accessible tout en conservant la philosophie des systèmes d'exploitation classiques : simplicité, légèreté, fonctionnement en ligne de commande et maîtrise directe des ressources informatiques.

Au-delà de la reproduction des fonctionnalités de MS-DOS, MSDOS-0 constitue un laboratoire de programmation système et d'expérimentation informatique. Il permet d'étudier les principes de fonctionnement des systèmes d'exploitation compatibles avec l'architecture PC, les interfaces logicielles historiques, les structures des fichiers exécutables, les systèmes de fichiers et les mécanismes d'amorçage. Chaque composant représente une occasion d'explorer les technologies qui ont marqué les débuts de l'informatique personnelle et de les réinterpréter au moyen du langage Pascal.

Le projet est en constante évolution et ne prétend pas reproduire intégralement toutes les fonctionnalités ou garantir une compatibilité parfaite avec les différentes versions de MS-DOS. Il s'adresse principalement aux passionnés d'informatique rétro, aux développeurs Pascal et aux personnes souhaitant comprendre les mécanismes internes des systèmes d'exploitation historiques.

MSDOS-0 : _faire revivre l'univers du DOS, du secteur d'amorçage jusqu'à la ligne de commande, une ligne de Pascal à la fois._

<img width="640" height="370" alt="image" src="https://github.com/user-attachments/assets/be0125ce-fbab-4cf0-9392-d8d4a0315b33" />

![image](https://user-images.githubusercontent.com/11842176/194548244-bede424b-5d85-4808-9cf4-ff997c3ebb16.png)

![image](https://user-images.githubusercontent.com/11842176/178615847-519f70fe-ed5a-44ff-aeb1-eb1a1c55933e.png)

![image](https://github.com/user-attachments/assets/6391ac0e-afd7-48e0-afea-cd560ba4b231)


<h2>Images disque amorcables</h2>

Le dossier [IMAGE](IMAGE/LISEZMOI.TXT) contient `DOS144A.IMG` (disquette 1,44 Mo amorcable : noyau + commandes), `DOS144B.IMG` (suite des commandes), `DOSCD.ISO` (CD-ROM amorcable) et `INSTALL.IMG` / `INSTALL2.IMG` (disquettes d'installation de MSDOS-0 sur disque dur, voir `INSTALL.PAS`). Le programme `TOOLS\MAKEDISK.PAS` permet de créer des images de disquette (réparties sur plusieurs disquettes si nécessaire), de disque dur ou de CD-ROM à l'aide de `FORMAT`, `SYS`, `DISKPC` et `UNDISKPC`.

Pour l'installation, il faut utiliser l'image INSTALL.IMG : 

<table>
	<tr>
		<td><img width="320" height="240" alt="image" src="https://github.com/user-attachments/assets/3bf8600c-e6e9-40d7-ad18-09474393675b" /></td>
		<td><img width="320" height="240" alt="image" src="https://github.com/user-attachments/assets/43906b50-dac8-43ae-8173-551d64ea219e" /></td>
	</tr>
	<tr>
		<td><img width="320" height="240" alt="image" src="https://github.com/user-attachments/assets/e5460c88-4027-4a08-a480-41e22de3553f" /></td>
	</tr>
</table>



<h2>Liste des fichiers</h2>

Voici la liste des différents fichiers proposés dans MSDOS-0 :

<table>
		<tr>
			<th>Nom</th>
			<th>Description</th>	
		</tr>
		<tr>
		 	<td><b>APPEND.PAS</b></td>
			<td>Cette commande permet d'ouvrir des fichiers quelconque se trouvant dans les répertoires spécifiés comme s'il s'agissait du répertoire courant.</td>
		</tr>
		<tr>
			<td><b>ASSIGN.PAS</b></td>
			<td>Cette commande permet de créer un disque virtuel à partir d'un autre disque.</td>
		</tr>
		<tr>
			<td><b>ATTRIB.PAS</b></td>
			<td>Cette commande permet de demander ou de changer les attributs d'un fichier.</td>
		</tr>
	        <tr>
			<td><b>BACKUP.PAS</b></td>
			<td>Cette commande permet de créer une copie de sauvegarde.</td>
		</tr>
	        <tr>
			<td><b>BASIC.PAS</b></td>
			<td>Cette commande permet de lancer l'interpréteur de langage de programmation BASIC.</td>
		</tr>
		<tr>
			<td><b>CHKDSK.PAS</b></td>
			<td>Cette commande permet de vérifier le disque. Cette commande est inspiré du DOS.</td>
		</tr>			
	        <tr>
			<td><b>CHOICE.PAS</b></td>
			<td>Cette commande permet de faire une choix.</td>
		</tr>
		<tr>
			<td><b>COMMAND.PAS</b></td>
			<td>Logiciel clone d'un <i>COMMAND.COM</i> du système d'exploitation <a href="https://www.gladir.com/OS/DOS/intro.htm"><i>DOS</i></a>.</td>
		</tr>
		<tr>
			<td><b>COMP.PAS</b></td>
			<td>Cette commande permet de comparer deux fichiers. Cette commande est un equivalent du <a href="https://www.gladir.com/OS/PCDOS/intro.htm">PC-DOS</a> ou <a href="https://www.gladir.com/OS/MSDOS/intro.htm">MS-DOS</a>.</td>
		</tr>	
		<tr>
			<td><b>CREF.PAS</b></td>
			<td>Cette commande permet de produire une liste de symboles croisés.</td>
		</tr>
		<tr>
			 <td><b>DEBUG.PAS</b></td>
			 <td>Cette commande permet de deboguer un programme.</td>
		</tr>
		<tr>
			<td><b>DELTREE.PAS</b></td>
			<td>Cette commande permet d'effectuer la suppression d'un répertoire avec tous ses fichiers et répertoires inclusivement sur une unité de disque. Cette commande est un équivalent de la commande <a href="https://www.gladir.com/OS/MSDOS/deltree.htm">DELTREE</a> du MS-DOS.</td>
		</tr>
		<tr>
			<td><b>DISKCOMP.PAS</b></td>
			<td>Cette commande permet de comparer des disquettes ou des images.</td>
		</tr>
  		<tr>
		    	<td><b>DISKCOPY.PAS</b></td>
		    	<td>Cette commande permet de copier des disquettes ou des images.</td>
		</tr>
	        <tr>
			<td><b>DOSKEY.PAS</b></td>
			<td>Cette commande permet de charger le programme DOSKEY.</td>
		</tr>
		<tr>
			<td><b>DOSSHELL.PAS</b></td>
			<td>Cette commande permet de lancer un clone du MS-DOS Shell.</td>
		</tr>
		<tr>
			<td><b>EDIT.PAS</b></td>
			<td>Cette commande permet d'éditer un fichier texte ASCII.</td>
		</tr>
		<tr>
			<td><b>EDLIN.PAS</b></td>
			<td>Cette commande permet de lancer l'éditeur en ligne de commande.</td>
		</tr>
		<tr>
			<td><b>EMM386.PAS</b></td>
			<td>Cette commande permet de gérer la mémoire paginée (EMS 4.0), de fournir des blocs de mémoire haute (UMB) et le support VCPI à partir de la mémoire étendue (XMS), en basculant le processeur en mode virtuel 8086. Cette commande est inspirée de <i>EMM386.EXE</i> de MS-DOS 6.0.</td>
		</tr>
		<tr>
			<td><b>EXE2BIN.PAS</b></td>
			<td>Cette commande permet de convertir un fichier EXE en binaire (COM).</td>
		</tr>
		<tr>
			<td><b>FASTHELP.PAS</b></td>
			<td>Cette commande permet d'afficher une aide rapide sur une commande spécifié.</td>
		</tr>
		<tr>
			<td><b>FASTOPEN.PAS</b></td>
			<td>Cette commande permet d'accélérer les accès fichiers.</td>
		</tr>
		<tr>
			<td><b>FC.PAS</b></td>
			<td>Cette commande permet de comparer deux fichiers.</td>
		</tr>
		<tr>
			<td><b>FDISK.PAS</b></td>
			<td>Cette commande permet d'effectuer la gestion des partitions d'un disque dur.</td>
		</tr>
		<tr>
			<td><b>FIND.PAS</b></td>
			<td>Cette commande permet de rechercher une chaine de caractères dans des fichiers. Cette commande est un équivalent du DOS.</td>
		</tr>
		<tr>
			<td><b>FORMAT.PAS</b></td>
			<td>Cette commande permet de formater un unite de disquette.</td>
		</tr>
	        <tr>
			<td><b>GRAFTABL.PAS</b></td>
			<td>Cette commande permet d'effectuer le chargement en mémoire conventionnelle d'une table de police de caractères pour les modes graphiques.</td>
		</tr>
		<tr>
			<td><b>GWBASIC.PAS</b></td>
			<td>Cette commande permet de lancer un interpréteur BASIC étant un clone du GWBASIC.</td>
		</tr>
		<tr>
			<td><b>INSTALL.PAS</b></td>
			<td>Cette commande permet d'installer MSDOS-0 sur un disque dur : écrans bleus dans le style de l'installation de MS-DOS 6.22, copie des fichiers depuis les disquettes d'installation (<code>IMAGE\INSTALL.IMG</code>), disque amorçable (secteur de boot, MBR), <i>CONFIG.SYS</i> et <i>AUTOEXEC.BAT</i>.</td>
		</tr>
		<tr>
			<td><b>INTERLNK.PAS</b></td>
			<td>Cette commande permet de relier deux ordinateurs par un câble série ou parallèle afin de rediriger les lecteurs de disque et les imprimantes de l'autre ordinateur (serveur). Cette commande est inspirée de <i>INTERLNK.EXE</i> de MS-DOS 6.0.</td>
		</tr>
		<tr>
			<td><b>INTERSVR.PAS</b></td>
			<td>Cette commande permet de partager les lecteurs de disque et les imprimantes de cet ordinateur (serveur) avec un autre ordinateur (client) relié par un câble série ou parallèle et exécutant INTERLNK. Cette commande est inspirée de <i>INTERSVR.EXE</i> de MS-DOS 6.0.</td>
		</tr>
		<tr>
			<td><b>JOIN.PAS</b></td>
			<td>Cette commande permet de créer un disque virtuel à partir d'un répertoire.</td>
		</tr>
		<tr>
			<td><b>LABEL.PAS</b></td>
			<td>Cette commande permet de changer le nom d'un volume.</td>
		</tr>
		<tr>
			<td><b>LINK.PAS</b></td>
			<td>Cette commande permet de lancer le fabricant de liaison.</td>
		</tr>
		<tr>
			<td><b>LOADFIX.PAS</b></td> 
			<td>Cette commande permet d'effectuer un chargement au dessus du 64 Ko.</td>
		</tr>
	        <tr>
			<td><b>MEM.PAS</b></td>
			<td>Cette commande permet d'afficher les informations sur la mémoire. Cette commande est un clone de la commande MS-DOS ou PC-DOS.</td>
		</tr>
		<tr>
			<td><b>MIRROR.PAS</b></td>
			<td>Cette commande permet de sauvegarder ou de restaurer le secteur de démarrage.</td>
		</tr>
		<tr>
			<td><b>MODE.PAS</b></td>
			<td>Cette commande permet d'effectuer la gestion des paramètres d'un périphérique.</td>
		</tr>	
		<tr>
			<td><b>MORE.PAS</b></td>
			<td>Cette commande permet de recevoir l'entrée puis l'affichage sur un périphérique un écran à la fois.</td>
		</tr>
	        <tr>
			<td><b>MOVE.PAS</td>
			<td>Cette commande permet de déplacer un fichier.</td>
		</tr>
		<tr>
			<td><b>MSD.PAS</td>
			<td>Cette commande permet de fournir des informations techniques à propos de votre ordinateur.</td>
		</tr>
		<tr>
			<td><b>MSMOUSE.PAS</b></td>
			<td>Cette commande permet de charger le pilote souris pour les applications MS-DOS.</td>
		</tr>
		<tr>
			<td><b>NLSFUNC.PAS</b></td>
			<td>Cette commande permet d'effectuer la gestion du pays et des conventions internationales du système d'exploitation.</td>
		</tr>
		<tr>
			<td><b>POWER.PAS</b></td>
			<td>Cette commande permet de fixer ou de demander les paramètres d'économiseur d'énergie du système d'exploitation.</td>
		</tr>
		<tr>
			<td><b>PRINT.PAS</b></td>
			<td>Cette commande permet d'effectuer la gestion des traitements d'impressions du système d'exploitation.</td>
		</tr>
		<tr>
			<td><b>PRINTFIX.PAS</td>
			<td>Cette commande permet d'installer la correction des erreurs d'imprimantes parallèle sous MS-DOS 5.x.</td>
		</tr>
		<tr>
			<td><b>RECOVER.PAS</b></td>
			<td>Cette commande permet de récupérer des fichiers d'un disque endommagé.</td>
		</tr>
		<tr>
			<td><b>REPLACE.PAS</b></td>
			<td>Cette commande permet de remplacer un fichier. Cette commande est un équivalent du DOS.</td>
		</tr>
		<tr>
			<td><b>RESTORE.PAS</b></td>
			<td>Cette commande permet d'effectuer une récupération de fichiers d'une copie de sécurités.</td>
		</tr>
		<tr>
			<td><b>SCANDISK.PAS</b></td>
			<td>Cette commande permet de lancer l'utilitaire de diagnostic et réparation de disque.</td>
		</tr>
		<tr>
			<td><b>SETVER.PAS</b></td>
			<td>Cette commande permet de fixer la version pour un programme.</td>
		</tr>
		<tr>
			<td><b>SHARE.PAS</b></td>
			<td>Cette commande permet d'effectuer la gestion du partage des fichiers entre logiciel et programme multitâche.</td>
		</tr>
		<tr>
			<td><b>SORT.PAS</b></td>
			<td>Cette commande permet de trier une fichier texte ASCII et de retourner le résultat. Cette commande est un équivalent de la commande du DOS.</td>
		</tr>
		<tr>
			<td><b>SUBST.PAS</b></td>
			<td>Cette commande permet de créer un disque virtuel à partir d'un répertoire.</td>
		</tr>
		<tr>
			<td><b>SYS.PAS</b></td>
			<td>Cette commande permet de transférer les fichiers systèmes.</td>
		</tr>
		<tr>
			<td><b>TREE.PAS</b></td>
			<td>Cette commande permet d'afficher un arbre de répertoire.</td>
		</tr>
		<tr>
			<td><b>TYPE.PAS</b></td>
			<td>Cette commande permet d'afficher le contenu d'un fichier.</td>
		</tr>				
		<tr>
			<td><b>UNDELETE.PAS</b></td>
			<td>Cette commande permet de récupérer des fichiers supprimés.</td>
		</tr>
		<tr>
			<td><b>VSAFE.PAS</b></td>
			<td>Cette commande permet de gérer la protection virus.</td>
		</tr>
		 <tr>
			<td><b>XCOPY.PAS</b></td>
			<td>Cette commande permet d'effectuer la copie étendue avec sous-répertoire de fichier(s) vers un nouvel emplacement.</td>
		</tr>
	</table>

<h2>Langage humain</h3>

Pour changer la langue des commandes, vous devez fixer la valeur de la variable d'environnement LANGUAGE, par exemple, pour passer à l'allemand :

SET LANGUAGE=GR

Un autre exemple, pour supporter l'albanais :

SET LANGUAGE=SQ

<h2>Remarques</h3>
<ul>
	<li>Les commandes DISKCOMP, DISKCOPY, FDISK, RECOVER, SCANDISK et FORMAT on été amélioré par rapport à la version originale de Microsoft en proposant d'appliquer les changements sur un fichier d'image disque plutôt que directement sur un unité de disque.</li>
	<li>Une commande externe TYPE (mais pas la commande dans COMMAND.COM) a été bonifié du paramètre /GWBASIC afin de permettre l'affichage des fichiers compressés sauvegarder par le GWBASIC.</li>
	<li>La commande "SYS" a été bonifié des paramètres /DOS:famille et /IMG:fichier afin d'etre compatibilité à la plupart des DOS et offre la possibilité d'installer les fichiers de démarrage directement sur une image disque.</li>
</ul>

<h2>Compilation</h2>
	
Les fichiers Pascal n'ont aucune dépendances, il suffit de télécharger le fichier désiré et de le compiler avec Free Pascal avec la syntaxe de commande  :

<pre><b>fpc</b> <i>LEFICHIER.PAS</i></pre>
	
Sinon, vous pouvez également le compiler avec le Turbo Pascal à l'aide de la syntaxe de commande suivante :	

<pre><b>tpc</b> <i>LEFICHIER.PAS</i></pre>
	
Par exemple, si vous voulez compiler COMMAND.PAS, vous devrez tapez la commande suivante :

<pre><b>fpc</b> COMMAND.PAS</pre>

<h2>Licence</h2>
<ul>
 <li>Le code source est publié sous la licence <a href="https://github.com/gladir/MSDOS-0/blob/main/LICENSE">MIT</a>.</li>
 <li>Le paquet original est publié sous la licence <a href="https://github.com/gladir/MSDOS-0/blob/main/LICENSE">MIT</a>.</li>
</ul>
