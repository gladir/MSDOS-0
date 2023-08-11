{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program FASTHELP;

Var
 I:Integer;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('FASTHELP: Cette commande permet d''afficher une aide ',
                     'rapide sur une commande sp‚cifi‚.');
  WriteLn;
  WriteLn('Syntaxe: FASTHELP [command]');
  WriteLn;
  WriteLn('command  Ce paramŠtre permet d''indiquer la commande.');
 End
  Else
 If ParamCount>0Then For I:=1 to ParamCount do Begin
  If StrToUpper(ParamStr(I))='APPEND'Then Begin
   WriteLn('APPEND : Cette commande permet d''ouvrir des fichiers ',
                'quelques se trouvant dans les r‚pertoires sp‚cifi‚s ',
          'comme s''il s''agissait du r‚pertoire courant.');
   WriteLn;
   WriteLn('Syntaxe : APPEND [/E] [/PATH:ON|OFF] [/X:ON|OFF]');
   WriteLn;
   WriteLn(' /E         Il faut associ‚ la liste des r‚pertoires … une variable');
   WriteLn('            d''environnement se nommant ®APPEND¯.');
   WriteLn(' /PATH:OFF  Il ne faut pas rechercher dans la liste des r‚pertoires');
   WriteLn('            ajout‚s lors de la recherche de fichiers de donn‚es.');
   WriteLn(' /PATH:ON   Il faut rechercher dans la liste des r‚pertoires ajout‚s');
   WriteLn('            lors de la recherche de fichiers de donn‚es.');
   WriteLn(' /X:OFF     Il ne faut pas rechercher dans la liste des r‚pertoires');
   WriteLn('            ajout‚s lors de l''ex‚cution d''un programme.');
   WriteLn(' /X:ON      Il faut rechercher dans la liste des r‚pertoires ajout‚s');
   WriteLn('            lors de l''ex‚cution d''un programme.');
  End
   Else
  If StrToUpper(ParamStr(I))='ATTRIB'Then Begin
   WriteLn('ATTRIB - Cette commande permet de demander ou changer l''attribut d''un fichier');
   WriteLn;
   WriteLn('Syntaxe : ATTRIB nomdufichier [+R|-R] [+A|-A] [+S|-S] [+H|-H]');
   WriteLn;
   WriteLn(' -A   Enleve de l''attribut d''archive');
   WriteLn(' +A   Ajout de l''attribut d''archive');
   WriteLn(' -H   EnlŠve de l''attribut cach‚');
   WriteLn(' +H   Ajout de l''attribut cach‚');
   WriteLn(' -R   Enleve de l''attribut de lecture seulement');
   WriteLn(' +R   Ajout de l''attribut de lecture seulement');
   WriteLn(' -S   Enleve de l''attribut de systeme');
   WriteLn(' +S   Ajout de l''attribut de systeme');
   WriteLn;
   WriteLn(' /S   Applique le changement dans les sous-repertoires recursivement');
  End
   Else
  If StrToUpper(ParamStr(I))='BASIC'Then Begin
   WriteLn('BASIC - Cette commande permet de lancer l''interpreteur de BASIC.');
   WriteLn;
   WriteLn('Syntaxe : BASIC [fichier]');
  End
   Else
  If StrToUpper(ParamStr(I))='CHKDSK'Then Begin
   WriteLn('CHKDSK : Cette commande permet de v‚rifier le disque');
   WriteLn;
   WriteLn('Syntaxe : CHKDSK [disque:]');
   WriteLn('          CHKDSK [/IMAGE:fichier]');
   WriteLn;
   WriteLn('disque:  Indique la lettre de l''unit‚ de disque');
   WriteLn('/IMAGE   Indique le nom du fichier a utiliser comme disque');
  End
   Else
  If StrToUpper(ParamStr(I))='CHOICE'Then Begin
   WriteLn('CHOICE : Cette commande permet de faire un choix.');
   WriteLn;
   WriteLn('Syntaxe : CHOICE [/C[:]choix] [/N] [/S] [/T[:]c,nn]');
   WriteLn;
   WriteLn('/C[:]touches  Indique la liste des touches accept‚es comme r‚ponse');
  End
   Else
  If StrToUpper(ParamStr(I))='COMMAND'Then Begin
   WriteLn('COMMAND : Cette commande permet de lancer l''interpreteur de commande.');
   WriteLn;
   WriteLn('Syntaxe : COMMAND [/C command]');
  End
   Else
  If StrToUpper(ParamStr(I))='COMP'Then Begin
   WriteLn('COMP : Cette commande permet de comparer deux fichiers.');
   WriteLn;
   WriteLn('Syntaxe : COMP fichier1 fichier2 [/A] [/C] [/D] [/L] [/M]');
   WriteLn;
   WriteLn('  fichier1 Premier fichier a comparer');
   WriteLn('  fichier2 Deuxieme fichier a comparer');
   WriteLn('  /A       Affiche la difference en ASCII');
   WriteLn('  /C       Affiche la difference en Caractere');
   WriteLn('  /D       Affiche la difference en decimale');
   WriteLn('  /L       Affiche le numero de ligne plutot que le deplacement');
   WriteLn('  /M       Ne pas poser de question pour d''autres comparaisons');
  End
   Else
  If StrToUpper(ParamStr(I))='DEBUG'Then Begin
   WriteLn('DEBUG : Cette commande permet de deboguer des programmes.');
   WriteLn;
   WriteLn('Syntaxe : DEBUG');
  End
   Else
  If StrToUpper(ParamStr(I))='DELTREE'Then Begin
   Write('DELTREE : Cette commande permet de supprimer un repertoire ',
         'avec ses fichiers et repertoire.');
   WriteLn;
   WriteLn('Syntaxe : DELTREE repertoire [/Y]');
  End
   Else
  If StrToUpper(ParamStr(I))='DISKCOMP'Then Begin
   WriteLn('DISKCOMP : Cette commande permet de comparer des disquettes ou des images.');
   WriteLn;
   WriteLn('Syntaxe : DISKCOMP disque: fichier');
   WriteLn('          DISKCOMP fichier fichier');
   WriteLn('          DISKCOMP fichier disque:');
  End
   Else
  If StrToUpper(ParamStr(I))='DISKCOPY'Then Begin
   WriteLn('DISKCOPY : Cette commande permet de copier des disquettes ou des images.');
   WriteLn;
   WriteLn('Syntaxe : DISKCOPY disque: fichier');
   WriteLn('          DISKCOPY fichier fichier');
   WriteLn('          DISKCOPY fichier disque:');
  End
   Else
  If StrToUpper(ParamStr(I))='DOSKEY'Then Begin
   WriteLn('DOSKEY : Cette commande permet de charger le programme DOSKEY.');
   WriteLn;
   WriteLn('Syntaxe : DOSKEY /SHELL');
   WriteLn;
   WriteLn(' /SHELL   Lance l''interpr‚teur de commande');
  End
   Else
  If StrToUpper(ParamStr(I))='DOSSHELL'Then Begin
   WriteLn('DOSSHELL : Cette commande permet de lancer DOSSHELL.');
   WriteLn;
   WriteLn('Syntaxe : DOSSHELL [/ASCII128]');
   WriteLn;
   WriteLn(' /ASCII128   Ce parametre permet de lancer en mode compatibilite 128 caracteres seulement.');
  End
   Else
  If StrToUpper(ParamStr(I))='EDIT'Then Begin
   WriteLn('EDIT : Cette commande permet d''editer un fichier texte ASCII.');
   WriteLn;
   WriteLn('Syntaxe : EDIT nomdufichier');
  End
   Else
  If StrToUpper(ParamStr(I))='EDLIN'Then Begin
   WriteLn('EDLIN : Cette commande permet d''editer un fichier texte ASCII.');
   WriteLn;
   WriteLn('Syntaxe : EDLIN [nomdufichier]');
  End
   Else
  If StrToUpper(ParamStr(I))='EXE2BIN'Then Begin
   WriteLn('EXE2BIN : Cette commande permet de convertir un fichier EXE en binaire (COM).');
   WriteLn;
   WriteLn('Syntaxe : EXE2BIN fichier.exe [fichier.bin]');
  End
   Else
  If StrToUpper(ParamStr(I))='FASTHELP'Then Begin
   WriteLn('FASTHELP: Cette commande permet d''afficher une aide ',
                      'rapide sur une commande sp‚cifi‚.');
   WriteLn;
   WriteLn('Syntaxe: FASTHELP [command]');
   WriteLn;
   WriteLn('command  Ce paramŠtre permet d''indiquer la commande.');
  End
   Else
  If StrToUpper(ParamStr(I))='FC'Then Begin
   WriteLn('FC : Cette commande permet de comparer deux fichiers.');
   WriteLn;
   WriteLn('Syntaxe : FC fichier1 fichier2 [/B] [/C] [/L]');
   WriteLn;
   WriteLn('  fichier1 Premier fichier a comparer');
   WriteLn('  fichier2 Deuxieme fichier a comparer');
   WriteLn('  /B       Comparaison binaire');
   WriteLn('  /C       Sans distinction minuscule/majuscule');
   WriteLn('  /L       Comparaison ASCII ligne par ligne');
  End
   Else
  If StrToUpper(ParamStr(I))='FDISK'Then Begin
   WriteLn('FDISK : Cette commande permet d''effectuer la gestion d''un disque dur.');
   WriteLn;
   WriteLn('Syntaxe : FDISK [fichier]');
  End
   Else
  If StrToUpper(ParamStr(I))='FIND'Then Begin
   WriteLn('FIND : Cette commande permet de rechercher une chaine de caractŠres dans des fichiers.');
   WriteLn;
   WriteLn('Syntaxe : FIND "chaine" [fichier] [/I] [/N] [/V]');
   WriteLn;
   WriteLn('"chaine"  Indique la chaŒne de caractŠres … rechercher dans les fichiers.');
   WriteLn('/I        Il ne faut pas effectuer de distinction entre les majuscules et minuscules.');
   WriteLn('/N        Affiche le num‚ro contenant la chaŒne de caractŠres trouv‚s.');
   WriteLn('/V        Affiche toutes les lignes ne contenant pas la chaŒne de caractŠres recherch‚s.');
  End
   Else
  If StrToUpper(ParamStr(I))='FORMAT'Then Begin
   WriteLn('FORMAT - Cette commande permet de formater un unit‚ de disquette.');
   WriteLn;
   WriteLn('Syntaxe: FORMAT [A:|B:] [360|720|1200|1440] [NV] [/F]');
   WriteLn('         FORMAT fichier');
   WriteLn;
   WriteLn('fichier  Utiliser le fichier sp‚cifi‚ comme disquette');
   WriteLn('     NV  Pas de v‚rification');
   WriteLn('     /F  Force a utiliser ce format');
  End
   Else
  If StrToUpper(ParamStr(I))='GRAFTABL'Then Begin
   WriteLn('GRAFTABL : Cette commande permet d''effectuer le chargement en memoire conventionnel ',
                       'd''une table de police de caracteres pour les modes graphiques.');
   WriteLn;
   WriteLn('Syntaxe : GRAFTABL [/STA|/STATUS]');
  End
   Else
  If StrToUpper(ParamStr(I))='GWBASIC'Then Begin
   WriteLn('GWBASIC : Cette commande permet de lancer l''interpreteur de GWBASIC.');
   WriteLn;
   WriteLn('Syntaxe : GWBASIC [fichier]');
  End
   Else
  If StrToUpper(ParamStr(I))='LABEL'Then Begin
   WriteLn('LABEL : Cette commande permet de changer le nom du volume');
   WriteLn;
   WriteLn('Syntaxe: LABEL [unite: [nouveaunom]]');
   WriteLn;
   WriteLn(' unite:      Indique l''unit‚ que vous souhaitez trait‚');
   WriteLn(' nouveaunom  Indique le nouveau du volume');
   WriteLn;
   WriteLn('NB: Si le nouveaunom n''est pas d‚finit, il retournera le nom courant');
  End
   Else
  If StrToUpper(ParamStr(I))='MEM'Then Begin
   WriteLn('MEM : Cette commande permet d''afficher les informations sur la m‚moire.');
   WriteLn;
   WriteLn('Syntaxe : MEM');
  End
   Else
  If StrToUpper(ParamStr(I))='MODE'Then Begin
   WriteLn('MODE - Cette commande permet d''effectuer la gestion des parametres d''un peripherique');
   WriteLn;
   WriteLn('MODE [/?]');
   WriteLn('MODE [MONO|BW40|CO40|BW80|CO80] [/GS]');
   WriteLn('MODE CON[:] RATE=taux DELAY=delai');
   WriteLn;
   WriteLn(' MONO         Mode texte monochrome 80x25');
   WriteLn(' BW40         Mode texte noir et blanc 40x25');
   WriteLn(' CO40         Mode texte couleur 40x25');
   WriteLn(' BW80         Mode texte noir et blanc 80x25');
   WriteLn(' CO80         Mode texte couleur 80x25');
   WriteLn(' RATE=taux    Taux de repetition du clavier (1 a 32)');
   WriteLn(' DELAY=delai  Delai entre les repetitions (1 a 4)');
   WriteLn(' /GS          Force a s''appliquer en fonction d''une Graphics Solution d''ATI');
  End
   Else
  If StrToUpper(ParamStr(I))='MORE'Then Begin
   WriteLn('MORE : Cette commande permet de recevoir l''entree puis ',
           'l''affiche sur un peripherique de sortie un ecran a la fois.');
   WriteLn;
   WriteLn('Syntaxe : MORE source');
  End
   Else
  If StrToUpper(ParamStr(I))='MOVE'Then Begin
   WriteLn('MOVE : Cette commande permet de deplacer un fichier.');
   WriteLn;
   WriteLn('Syntaxe : MOVE source destination');
  End
   Else
  If StrToUpper(ParamStr(I))='MSD'Then Begin
   WriteLn('MSD : Cette commande permet de fournir des informations ',
           'techniques … propos de votre ordinateur');
   WriteLn;
   WriteLn('Syntaxe : MSD [/ASCII128]');
   WriteLn;
   WriteLn(' /ASCII128   Ce parametre permet de lancer en mode compatibilite 128 caracteres seulement.');
  End
   Else
  If StrToUpper(ParamStr(I))='REPLACE'Then Begin
   WriteLn('REPLACE : Cette commande permet de remplacer un fichier.');
   WriteLn;
   WriteLn('Syntaxe : REPLACE source destination [/P]');
   WriteLn;
   WriteLn('  /P   Demande une confirmation avant de remplacer');
  End
   Else
  If StrToUpper(ParamStr(I))='SORT'Then Begin
   WriteLn('SORT : Cette commande permet de trier un fichier texte ASCII.');
   WriteLn;
   WriteLn('Syntaxe : SORT [/R] fichier');
   WriteLn;
   WriteLn('fichier  Indique le fichier … trier.');
   WriteLn('/+n      Trie l''entr‚e par les caractŠres de la colonne n.');
   WriteLn('/R       Tri dans le sens inverse');
  End
   Else
  If StrToUpper(ParamStr(I))='TREE'Then Begin
   WriteLn('TREE : Cette commande permet d''afficher un arbre de repertoire.');
   WriteLn;
   WriteLn('Syntaxe : TREE [repertoire]');
   WriteLn;
  End
   Else
  If StrToUpper(ParamStr(I))='XCOPY'Then Begin
   WriteLn('XCOPY : Cette commande permet de copier des fichiers.');
   WriteLn;
   WriteLn('Syntaxe : XCOPY source destination [/P] [/W]');
   WriteLn;
   WriteLn('    /A     Copie uniquement les fichiers d''attribut archive');
   WriteLn('    /P     Demande une confirmation avant chaque fichier');
   WriteLn('    /W     Affiche un message avant de commencer la copie');
  End
   Else
  Begin
   WriteLn('Pas d''aide de disponible sur cette commande.');
   Halt;
  End;
 End;
END.