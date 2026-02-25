{ @author: Sylvain Maltais
  @created: 2026
  @website(https://www.gladir.com/msdos0)
  @description: Le MS Operating System est un systeme d'exploitation remplacant le DOS traditionnel.

  Fonctions DOS implementees :
  - 00h : Terminer le programme
  - 01h : Entree de caractere avec echo
  - 02h : Sortie de caractere
  - 03h : Entree de caractere depuis AUX (port serie)
  - 04h : Sortie de caractere vers AUX (port serie)
  - 05h : Sortie de caractere vers PRN (imprimante)
  - 06h : Entree/sortie directe de console
  - 07h : Entree de caractere directe sans sortie
  - 08h : Entree de caractere sans sortie (avec Ctrl+C)
  - 09h : Affichage de chaine de caracteres terminer par $
  - 0Ah : Lecture de chaine avec buffer
  - 0Bh : l'etat d'entree
  - 0Ch : Vider le tampon et appeler la fonction d'entree
  - 0Dh : Reinitialisation du disque
  - 0Eh : Selectionne le lecteur courant
  - 0Fh : Ouvrir un fichier avec FCB
  - 10h : Fermer un fichier avec FCB
  - 11h : Rechercher le premier fichier avec FCB
  - 12h : Rechercher le fichier suivant avec FCB
  - 13h : Supprimer un fichier avec FCB
  - 14h : Lecture séquentielle avec FCB
  - 15h : Ecriture séquentielle avec FCB
  - 16h : Créer un fichier avec FCB
  - 17h : Renommer un fichier avec FCB
  - 18h : Fonction réservée
  - 19h : Demande le lecteur courant
  - 1Ah : Définir l'adresse DTA (Disk Transfer Area)
  - 1Bh : Obtenir les informations d'allocation du lecteur par défaut
  - 1Ch : Obtenir les informations d'allocation d'un lecteur spécifique
  - 1Dh : Fermer tous les fichiers (fonction non documentée)
  - 1Eh : Fonction réservée/non documentée
  - 1Fh : Fonction réservée/non documentée
  - 20h : Terminer le programme (obsolète)
  - 21h : Lecture aléatoire avec FCB
  - 22h : Ecriture aléatoire avec FCB
  - 23h : Obtenir la taille de fichier avec FCB
  - 24h : Définir l'adresse aléatoire avec FCB
  - 25h : Fixe le vecteur d'interruption
  - 26h : Créer un nouveau PSP (Program Segment Prefix)
  - 27h : Lecture aléatoire de bloc avec FCB
  - 28h : Ecriture aléatoire de bloc avec FCB
  - 29h : Analyser nom de fichier dans FCB
  - 2Ah : Lire la date
  - 2Bh : Fixe la date
  - 2Ch : Lire l'heure système
  - 2Dh : Fixer l'heure système
  - 2Eh : Fixer/réinitialiser le drapeau de vérification
  - 2Fh : DOS Multiplex Interrupt (interface TSR/utilitaires)
  - 30h : Get DOS Version (obtenir version DOS)
  - 31h : Terminate Stay Resident (TSR avec code de retour)
  - 32h : Get Drive Parameter Block (DPB - paramètres lecteur)
  - 33h : Multi-fonction (Control Break, Boot Drive)
    - 00h : Get Control Break check state
    - 01h : Set Control Break check state  
    - 05h : Get boot drive
    - 06h : Get DOS version
  - 34h : Demande l'adresse du drapeau InDos
  - 35h : Demande le vecteur d'interruption
  - 36h : Get free disk space (espace libre sur disque)
  - 37h : Switch character functions (fonctions caractère de commutation)
  - 38h : Get/Set Country Information (informations de localisation)

  @target: Turbo Pascal 7 (syntaxe assembleur Intel)
}

Unit MSDOS;

INTERFACE

Procedure BEGIN_KERNEL;
Procedure END_KERNEL;

IMPLEMENTATION

Const
 VerDos=7;          { Version de DOS }
 SubVerDos=10;      { Sous-version de DOS }

Type DataMOS=Record
 Key:Byte;
 InDos:Byte;
 CurrDisk:Byte;
 DTASegment:Word;    { Segment de la DTA }
 DTAOffset:Word;     { Offset de la DTA }
End;

Procedure Intr20h;Interrupt;Forward;
Procedure Intr21h;Interrupt;Forward;
Procedure Intr25h;Interrupt;Forward;
Procedure Intr26h;Interrupt;Forward;
Procedure Intr28h;Interrupt;Forward;
Procedure Intr2Ah;Interrupt;Forward;
Procedure Intr2Fh;Interrupt;Forward;
Procedure Intr33h;Interrupt;Forward;

Procedure SetIntVec(AL:Byte;DS,DX:Word);Near;Forward;

Procedure BEGIN_KERNEL;Begin
 SetIntVec($20,CSeg,Ofs(Intr21h));
 SetIntVec($21,CSeg,Ofs(Intr21h));
 SetIntVec($25,CSeg,Ofs(Intr25h));
 SetIntVec($26,CSeg,Ofs(Intr26h));
 SetIntVec($28,CSeg,Ofs(Intr28h));
 SetIntVec($2A,CSeg,Ofs(Intr2Ah));
 SetIntVec($2F,CSeg,Ofs(Intr2Fh));
 SetIntVec($33,CSeg,Ofs(Intr33h));
  { TODO : Charger un programme COMMAND.EXE, faire un JMP sur le point d'entr�e du programme charg� en m�moire }
 ASM
  DB 'DEBUT DU NOYAU MSDOS-0';
 END;
End;

Procedure Data;Assembler;ASM
 DB 0          { Key:   Touche }
 DB 0          { InDos: Dans l'Interruption DOS? }
 DB 0          { CurrDisk: Disque courant }
 DW 0          { DTASegment: Segment DTA (initialisé à 0) }
 DW 80h        { DTAOffset: Offset DTA (par défaut 80h) }
END;

Procedure Intr20h;Assembler;ASM
 { TODO : Mettre le code n�cessaire }
END;

Procedure Intr21h;Assembler;ASM
 INC Data.DataMOS.InDos
 MOV BL,AH
@CallFunc:
 XOR BH,BH
 SHL BX,1
 JMP @Label.Word[BX]
@Label:
 DW @00h { Fonction 00h - Terminer le programme }
 DW @01h { Fonction 01h - Entree de caractere avec echo }
 DW @02h { Fonction 02h - Sortie de caractere }
 DW @03h { Fonction 03h - Entree de caractere depuis AUX }
 DW @04h { Fonction 04h - Sortie de caractere vers AUX }
 DW @05h { Fonction 05h - Sortie de caractere vers PRN }
 DW @06h { Fonction 06h - Entree/sortie directe de console }
 DW @07h { Fonction 07h - Entree de caractere directe sans sortie }
 DW @08h { Fonction 08h - Entree de caractere sans sortie}
 DW @09h { Fonction 09h - Affichage de chaine terminee par $ }
 DW @0Ah { Fonction 0Ah - Lecture de chaine avec buffer }
 DW @0Bh { Fonction 0Bh - Lire l'etat d'entree}
 DW @0Ch { Fonction 0Ch - Vider le tampon et appeler la fonction d'entree }
 DW @0Dh { Fonction 0Dh - Reinitialisation du disque }
 DW @0Eh { Fonction 0Eh - Selectionne le disque courant }
 DW @0Fh { Fonction 0Fh - Ouvrir un fichier avec FCB }
 DW @10h { Fonction 10h - Fermer un fichier avec FCB }
 DW @11h { Fonction 11h - Rechercher le premier fichier avec FCB }
 DW @12h { Fonction 12h - Rechercher le fichier suivant avec FCB }
 DW @13h { Fonction 13h - Supprimer un fichier avec FCB }
 DW @14h { Fonction 14h - Lecture séquentielle avec FCB }
 DW @15h { Fonction 15h - Ecriture séquentielle avec FCB }
 DW @16h { Fonction 16h - Créer un fichier avec FCB }
 DW @17h { Fonction 17h - Renommer un fichier avec FCB }
 DW @18h { Fonction 18h - Fonction réservée }
 DW @19h { Fonction 19h - Demande le lecteur courant }
 DW @1Ah { Fonction 1Ah - Définir l'adresse DTA }
 DW @1Bh { Fonction 1Bh - Obtenir informations allocation drive par défaut }
 DW @1Ch { Fonction 1Ch - Obtenir informations allocation drive spécifique }
 DW @1Dh { Fonction 1Dh - Fermer tous les fichiers }
 DW @1Eh { Fonction 1Eh - Fonction réservée/non documentée }
 DW @1Fh { Fonction 1Fh - Fonction réservée/non documentée }
 DW @20h { Fonction 20h - Terminer le programme (obsolète) }
 DW @21h { Fonction 21h - Lecture aléatoire avec FCB }
 DW @22h { Fonction 22h - Ecriture aléatoire avec FCB }
 DW @23h { Fonction 23h - Obtenir la taille de fichier avec FCB }
 DW @24h { Fonction 24h - Définir l'adresse aléatoire avec FCB }
 DW @25h { Fonction 25h - Fixe le vecteur d'Interruption}
 DW @26h { Fonction 26h - Créer un nouveau PSP }
 DW @27h { Fonction 27h - Lecture aléatoire de bloc avec FCB }
 DW @28h { Fonction 28h - Ecriture aléatoire de bloc avec FCB }
 DW @29h { Fonction 29h - Analyser nom de fichier dans FCB }
 DW @2Ah { Fonction 2Ah - Lire la date }
 DW @2Bh { Fonction 2Bh - Fixe la date }
 DW @2Ch { Fonction 2Ch - Lire l'heure système }
 DW @2Dh { Fonction 2Dh - Fixer l'heure système }
 DW @2Eh { Fonction 2Eh - Fixer/réinitialiser le drapeau de vérification }
 DW @2Fh { Fonction 2Fh - DOS Multiplex Interrupt }
 DW @30h { Fonction 30h - Get DOS Version }
 DW @31h { Fonction 31h - Terminate Stay Resident (TSR) }
 DW @32h { Fonction 32h - Get Drive Parameter Block (DPB) }
 DW @33h { Fonction 33h - Multi-fonction }
 DW @34h { Fonction 34h - Demande l'adresse du drapeau "InDos" }
 DW @35h { Fonction 35h - Demande le vecteur d'Interruption}
 DW @36h { Fonction 36h - Get free disk space }
 DW @37h { Fonction 37h - Switch character functions }
 DW @38h { Fonction 38h - Get/Set Country Information }

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 00h: Terminer le programme                      }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@00h:
 MOV AH,4Ch                 { Fonction 4Ch - Terminaison avec code de retour }
 XOR AL,AL                  { Code de retour = 0 }
 INT 21h                    { Appel recursif pour terminer proprement }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 01h: Entree de caractere avec echo              }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@01h:
 MOV AL,Data.DataMOS.Key
 OR  AL,AL
 JE  @01GetInt16h
 MOV AH,0
 JMP @01EchoChar
@01GetInt16h:
 XOR AX,AX
 INT 16h
@01EchoChar:
 MOV Data.DataMOS.Key,AH    { Sauver la touche suivante }
 CMP AL,3                   { Ctrl+C/Ctrl+Break ? }
 JNE @01NoBreak
 INT 23h
@01NoBreak:
 PUSH AX                    { Sauver le caractere }
 MOV DL,AL
 MOV AH,02h                 { Fonction 02h - Sortie caractere }
 INT 21h
 POP AX                     { Restaurer le caractere }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 02h: Sortie de caractere                        }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@02h:
 MOV AL,DL
 MOV AH,0Eh                 { BIOS - Sortie caractere }
 XOR BX,BX                  { Page 0, couleur par defaut }
 INT 10h
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 03h: Entree de caractere depuis AUX             }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@03h:
 MOV AH,02h                 { BIOS - Lire caractere serie }
 XOR DX,DX                  { Port COM1 }
 INT 14h
 TEST AH,80h                { Verifier timeout }
 JZ @03NoError
 MOV AL,1Ah                 { Code EOF si erreur }
@03NoError:
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 04h: Sortie de caractere vers AUX               }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@04h:
 MOV AL,DL
 MOV AH,01h                 { BIOS - Ecrire caractere serie }
 XOR DX,DX                  { Port COM1 }
 INT 14h
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 05h: Sortie de caractere vers PRN (imprimante)  }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@05h:
 MOV AL,DL
 XOR AH,AH                  { BIOS - Imprimer caractere }
 XOR DX,DX                  { Port LPT1 }
 INT 17h
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 06h: Entree/sortie directe de console           }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@06h:
 CMP DL,0FFh                { Fonction d'entree ? }
 JNE @06Output
 { Fonction d'entree }
 MOV AL,Data.DataMOS.Key
 OR  AL,AL
 JE  @06CheckKeyboard
 MOV AH,0
 MOV Data.DataMOS.Key,0     { Effacer la touche }
 CMP AL,0                   { Zero Flag = 0 si caractere disponible }
 JMP @Xit
@06CheckKeyboard:
 MOV AH,01h                 { BIOS - Verifier si touche disponible }
 INT 16h
 JZ  @06NoKey              { Pas de touche }
 XOR AX,AX                  { Lire la touche }
 INT 16h
 MOV Data.DataMOS.Key,AH    { Sauver scan code }
 TEST AL,AL                 { Zero Flag = 0 si caractere valide }
 JMP @Xit
@06NoKey:
 XOR AL,AL                  { Pas de caractere - Zero Flag = 1 }
 JMP @Xit
@06Output:
 { Fonction de sortie }
 MOV AL,DL
 MOV AH,0Eh                 { BIOS - Sortie caractere }
 XOR BX,BX                  { Page 0, couleur par defaut }
 INT 10h
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 07h: Entree de caractere directe sans sortie }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@07h:
 MOV AL,Data.DataMOS.Key
 OR  AL,AL
 JE  @GetInt16h
 MOV AH,0
 JMP @SetNextKey
@GetInt16h:
 XOR AX,AX
 INT 16h
@SetNextKey:
 MOV Data.DataMOS.Key,AH
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 08h: Entree de caractere sans sortie }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@08h:
 MOV AL,Data.DataMOS.Key
 OR  AL,AL
 JE  @08GetInt16h
 MOV AH,0
 JMP @08SetNextKey
@08GetInt16h:
 XOR AX,AX
 INT 16h
@08SetNextKey:
 MOV Data.DataMOS.Key,AH
 CMP AL,3                   { Ctrl+C/Ctrl+Break ? }
 JNE @08NoBreak
 INT 23h
@08NoBreak:
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 09h: Affichage de chaine terminee par $         }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@09h:
 PUSH SI                    { Sauver registres }
 PUSH DS
 MOV SI,DX                  { DS:DX pointe sur la chaine }
@09Loop:
 LODSB                      { Charger AL depuis DS:SI et incrementer SI }
 CMP AL,'$'                 { Caractere de fin ? }
 JE @09End
 MOV DL,AL                  { Preparer caractere pour sortie }
 PUSH AX                    { Sauver AX }
 PUSH SI                    { Sauver SI }
 MOV AH,02h                 { Fonction 02h - Sortie caractere }
 INT 21h
 POP SI                     { Restaurer SI }
 POP AX                     { Restaurer AX }
 JMP @09Loop
@09End:
 POP DS                     { Restaurer registres }
 POP SI
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 0Ah: Lecture de chaine avec buffer              }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@0Ah:
 PUSH SI                    { Sauver registres }
 PUSH DI
 PUSH DS
 PUSH ES
 MOV SI,DX                  { DS:DX pointe sur le buffer }
 MOV DI,DX
 ADD DI,2                   { DI pointe sur le debut de la chaine }
 XOR CX,CX
 MOV CL,[SI]                { Taille maximum du buffer }
 DEC CX                     { Laisser place pour le caractere nul }
 XOR BX,BX                  { Compteur de caracteres lus }
@0ALoop:
 PUSH AX                    { Sauver registres }
 PUSH BX
 PUSH CX
 PUSH DX
 MOV AH,01h                 { Fonction 01h - Entree avec echo }
 INT 21h
 XCHG DI,AX                 { Sauver AX (avec le caractere) dans DI }
 POP DX                     { Restaurer registres }
 POP CX
 POP BX
 POP AX                     { Restaurer AX original }
 XCHG AX,DI                 { Recuperer le caractere dans AX }
 CMP AL,0Dh                 { Entree (CR) ? }
 JE @0AEnd
 CMP AL,08h                 { Backspace ? }
 JE @0ABackspace
 CMP AL,1Bh                 { Echap ? }
 JE @0ACancel
 CMP BX,CX                  { Buffer plein ? }
 JAE @0ALoop
 MOV [DI+BX],AL             { Stocker le caractere }
 INC BX                     { Incrementer compteur }
 JMP @0ALoop
@0ABackspace:
 OR BX,BX                   { Position 0 ? }
 JE @0ALoop
 DEC BX                     { Decrementer compteur }
 JMP @0ALoop
@0ACancel:
 XOR BX,BX                  { Effacer le buffer }
 JMP @0ALoop
@0AEnd:
 MOV [SI+1],BL              { Stocker le nombre de caracteres lus }
 MOV BYTE PTR [DI+BX],0Dh   { Terminer par CR }
 POP ES                     { Restaurer registres }
 POP DS
 POP DI
 POP SI
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 0Bh: Lire l'etat d'entree }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@0Bh:
 XOR AX,AX
 MOV ES,AX
 LES DX,ES:[041Ah]
 MOV BX,ES
 CMP BX,DX
 JE  @Xit
 MOV AL,0FFh
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 0Ch: Vider le tampon et appeler la fonction d'entree }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@0Ch:
 PUSH AX
  XOR AX,AX
  MOV ES,AX
  MOV AX,ES:[480h]
  MOV ES:[41Ah],AX
  MOV ES:[41Ch],AX
 POP BX
 JMP @CallFunc

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 0Dh: Reinitialisation du disque                 }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@0Dh:
 PUSH AX                    { Sauver registres }
 PUSH DX
 MOV AH,0Dh                 { BIOS - Reset disque }
 INT 13h                    { Appel BIOS }
 POP DX                     { Restaurer registres }
 POP AX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 0Eh: Selectionne le lecteur courant }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@0Eh:
 MOV AL,26 { Nombre d'unite installe }
 CMP DL,AL
 JAE @Xit
 MOV Data.DataMOS.CurrDisk,DL
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 0Fh: Ouvrir un fichier avec FCB                 }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@0Fh:
 PUSH SI                    { Sauver registres }
 PUSH DI
 PUSH DS
 PUSH ES
 MOV SI,DX                  { DS:DX pointe sur le FCB }
 { Verifier si le fichier existe en utilisant le nom dans le FCB }
 PUSH AX
 PUSH BX
 PUSH CX
 PUSH DX
 { Simuler une ouverture reussie pour les FCB standards }
 MOV AL,0                   { Code de retour: succes }
 { Marquer le FCB comme ouvert en mettant le drive courant }
 MOV BL,Data.DataMOS.CurrDisk
 INC BL                     { 1=A:, 2=B:, etc. }
 MOV [SI],BL                { Stocker dans le FCB }
 POP DX
 POP CX
 POP BX
 POP AX
 POP ES                     { Restaurer registres }
 POP DS
 POP DI
 POP SI
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 10h: Fermer un fichier avec FCB                 }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@10h:
 PUSH SI                    { Sauver registres }
 PUSH DS
 MOV SI,DX                  { DS:DX pointe sur le FCB }
 { Verifier que le FCB est valide }
 CMP BYTE PTR [SI],0        { Drive = 0 ? }
 JE @10Error
 { Simuler une fermeture reussie }
 MOV BYTE PTR [SI],0        { Marquer le FCB comme ferme }
 MOV AL,0                   { Code de retour: succes }
 JMP @10End
@10Error:
 MOV AL,0FFh                { Code d'erreur: FCB invalide }
@10End:
 POP DS                     { Restaurer registres }
 POP SI
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 11h: Rechercher le premier fichier avec FCB     }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@11h:
 PUSH SI                    { Sauver registres }
 PUSH DI
 PUSH DS
 PUSH ES
 MOV SI,DX                  { DS:DX pointe sur le FCB }
 { Pour cette implementation basique, nous retournons "aucun fichier trouve" }
 { Dans une implementation complete, il faudrait chercher dans les repertoires }
 MOV AL,0FFh                { Code de retour: aucun fichier trouve }
 { Alternative: simuler la decouverte d'un fichier fictif }
 { MOV AL,0                   Code de retour: fichier trouve }
 { Il faudrait alors remplir la DTA avec les informations du fichier }
 POP ES                     { Restaurer registres }
 POP DS
 POP DI
 POP SI
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 12h: Rechercher le fichier suivant avec FCB     }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@12h:
 PUSH SI                    { Sauver registres }
 PUSH DI
 PUSH DS
 PUSH ES
 MOV SI,DX                  { DS:DX pointe sur le FCB }
 { Implementation basique: retourner "plus de fichiers" }
 { Dans un DOS complet, cette fonction continuerait la recherche commencee par 11h }
 MOV AL,0FFh                { Code de retour: plus de fichiers }
 POP ES                     { Restaurer registres }
 POP DS
 POP DI
 POP SI
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 13h: Supprimer un fichier avec FCB              }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@13h:
 PUSH SI                    { Sauver registres }
 PUSH DI
 PUSH DS
 PUSH ES
 MOV SI,DX                  { DS:DX pointe sur le FCB }
 { Verifier que le nom de fichier est valide dans le FCB }
 CMP BYTE PTR [SI+1],' '    { Premier caractere du nom vide ? }
 JE @13Error
 { Implementation simplifiee: simuler une suppression reussie }
 { Dans un DOS complet, il faudrait verifier l'existence et supprimer le fichier }
 MOV AL,0                   { Code de retour: succes }
 JMP @13End
@13Error:
 MOV AL,0FFh                { Code d'erreur: fichier non trouve }
@13End:
 POP ES                     { Restaurer registres }
 POP DS
 POP DI
 POP SI
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 14h: Lecture séquentielle avec FCB              }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@14h:
 PUSH SI                    { Sauver registres }
 PUSH DI
 PUSH DS
 PUSH ES
 MOV SI,DX                  { DS:DX pointe sur le FCB }
 { Verifier que le FCB est ouvert }
 CMP BYTE PTR [SI],0        { Drive = 0 ? }
 JE @14Error
 { Implementation simplifiee: simuler une lecture EOF }
 { Dans un DOS complet, il faudrait lire les donnees dans la DTA }
 { et incrementer le pointeur de fichier dans le FCB }
 MOV AL,1                   { Code de retour: EOF (End Of File) }
 JMP @14End
@14Error:
 MOV AL,0FFh                { Code d'erreur: FCB non valide }
@14End:
 POP ES                     { Restaurer registres }
 POP DS
 POP DI
 POP SI
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 15h: Ecriture séquentielle avec FCB             }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@15h:
 PUSH SI                    { Sauver registres }
 PUSH DI
 PUSH DS
 PUSH ES
 MOV SI,DX                  { DS:DX pointe sur le FCB }
 { Verifier que le FCB est ouvert }
 CMP BYTE PTR [SI],0        { Drive = 0 ? }
 JE @15Error
 { Implementation simplifiee: simuler une ecriture reussie }
 { Dans un DOS complet, il faudrait ecrire les donnees depuis la DTA }
 { et incrementer le pointeur de fichier dans le FCB }
 MOV AL,0                   { Code de retour: succes }
 JMP @15End
@15Error:
 MOV AL,0FFh                { Code d'erreur: FCB non valide }
@15End:
 POP ES                     { Restaurer registres }
 POP DS
 POP DI
 POP SI
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 16h: Créer un fichier avec FCB                  }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@16h:
 PUSH SI                    { Sauver registres }
 PUSH DI
 PUSH DS
 PUSH ES
 MOV SI,DX                  { DS:DX pointe sur le FCB }
 { Verifier que le nom de fichier est valide dans le FCB }
 CMP BYTE PTR [SI+1],' '    { Premier caractere du nom vide ? }
 JE @16Error
 { Implementation simplifiee: simuler une creation reussie }
 { Dans un DOS complet, il faudrait creer le fichier sur disque }
 { et initialiser la structure FCB avec les informations du nouveau fichier }
 MOV BL,Data.DataMOS.CurrDisk
 INC BL                     { 1=A:, 2=B:, etc. }
 MOV [SI],BL                { Marquer le FCB comme ouvert sur le drive courant }
 { Initialiser les champs du FCB pour un nouveau fichier }
 MOV WORD PTR [SI+12],0     { Bloc courant = 0 }
 MOV WORD PTR [SI+14],128   { Taille d'enregistrement = 128 }
 MOV WORD PTR [SI+16],0     { Taille du fichier = 0 (partie basse) }
 MOV WORD PTR [SI+18],0     { Taille du fichier = 0 (partie haute) }
 MOV AL,0                   { Code de retour: succes }
 JMP @16End
@16Error:
 MOV AL,0FFh                { Code d'erreur: nom invalide }
@16End:
 POP ES                     { Restaurer registres }
 POP DS
 POP DI
 POP SI
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 17h: Renommer un fichier avec FCB               }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@17h:
 PUSH SI                    { Sauver registres }
 PUSH DI
 PUSH DS
 PUSH ES
 MOV SI,DX                  { DS:DX pointe sur le FCB source }
 { Le FCB pour renommer contient l'ancien nom (offset 0) et le nouveau nom (offset 17) }
 { Verifier que l'ancien nom est valide }
 CMP BYTE PTR [SI+1],' '    { Premier caractere de l'ancien nom vide ? }
 JE @17Error
 { Verifier que le nouveau nom est valide }
 CMP BYTE PTR [SI+17],' '   { Premier caractere du nouveau nom vide ? }
 JE @17Error
 { Implementation simplifiee: simuler un renommage reussi }
 { Dans un DOS complet, il faudrait localiser le fichier dans le repertoire }
 { et modifier l'entree pour changer le nom }
 MOV AL,0                   { Code de retour: succes }
 JMP @17End
@17Error:
 MOV AL,0FFh                { Code d'erreur: fichier non trouve ou nom invalide }
@17End:
 POP ES                     { Restaurer registres }
 POP DS
 POP DI
 POP SI
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 18h: Fonction réservée                          }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@18h:
 { Fonction réservée dans DOS classique - pas d'implémentation }
 { Certaines versions de DOS utilisent cette fonction à des fins internes }
 MOV AL,0                   { Code de retour neutre }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 19h: Demande le lecteur courant }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@19h:
 MOV AL,Data.DataMOS.CurrDisk
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 1Ah: Définir l'adresse DTA                      }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@1Ah:
 { Définir l'adresse du Disk Transfer Area (DTA) }
 { DS:DX contient la nouvelle adresse DTA }
 MOV Data.DataMOS.DTASegment,DS   { Sauvegarder le segment }
 MOV Data.DataMOS.DTAOffset,DX    { Sauvegarder le deplacemnet }
 { Pas de valeur de retour pour cette fonction }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 1Bh: Obtenir infos allocation drive par défaut  }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@1Bh:
 { Retourner les informations d'allocation pour le lecteur par défaut }
 { Format de retour dans les registres :
   AL = Secteurs par cluster
   CX = Taille d'un secteur en octets
   DX = Nombre de clusters sur le lecteur
   DS:BX pointe sur l'identificateur de média (FAT ID) }
 PUSH ES                    { Sauver registres }
 PUSH DI
 { Valeurs simulées pour un disque standard }
 MOV AL,1                   { 1 secteur par cluster }
 MOV CX,512                 { 512 octets par secteur }
 MOV DX,2880                { 2880 clusters (1.44MB disquette) }
 { Pointer DS:BX sur un identificateur de média fictif }
 PUSH CS
 POP DS
 MOV BX,OFFSET @MediaID
 JMP @1BEnd
@MediaID:
 DB 0F0h                    { ID média pour disquette 1.44MB }
@1BEnd:
 POP DI
 POP ES
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 1Ch: Obtenir infos allocation drive spécifique  }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@1Ch:
 { Retourner les informations d'allocation pour un lecteur spécifique }
 { DL contient le numéro de lecteur (1=A:, 2=B:, etc.) }
 { Même format de retour que 1Bh }
 PUSH ES                    { Sauver registres }
 PUSH DI
 CMP DL,0                   { Drive 0 = lecteur par défaut ? }
 JE @1CDefaultDrive
 CMP DL,26                  { Vérifier que le lecteur est valide (A-Z) }
 JA @1CError
 { Lecteur spécifique - mêmes valeurs simulées }
 MOV AL,1                   { 1 secteur par cluster }
 MOV CX,512                 { 512 octets par secteur }
 MOV DX,2880                { 2880 clusters }
 PUSH CS
 POP DS
 MOV BX,OFFSET @MediaID1C
 JMP @1CEnd
@1CDefaultDrive:
 { Utiliser le lecteur par défaut }
 MOV AL,1
 MOV CX,512
 MOV DX,2880
 PUSH CS
 POP DS
 MOV BX,OFFSET @MediaID1C
 JMP @1CEnd
@1CError:
 { Lecteur invalide - retourner AL=FFh }
 MOV AL,0FFh
 JMP @1CEnd
@MediaID1C:
 DB 0F0h                    { ID média }
@1CEnd:
 POP DI
 POP ES
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 1Dh: Fermer tous les fichiers                   }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@1Dh:
 { Fonction non documentée dans DOS classique, utilisée pour fermer tous les FCB ouverts }
 { Dans une implémentation complète, il faudrait parcourir la table des FCB ouverts }
 { et fermer chaque fichier ouvert }
 PUSH AX                    { Sauver registres }
 PUSH BX
 PUSH CX
 PUSH DX
 { Simulation : ne rien faire car pas de table FCB active dans cette version }
 { Dans un DOS complet, on appellerait une routine pour fermer tous les FCB }
 MOV AL,0                   { Code de retour : succès }
 POP DX                     { Restaurer registres }
 POP CX
 POP BX
 POP AX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 1Eh: Fonction réservée/non documentée           }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@1Eh:
 { Fonction non documentée dans DOS classique }
 { Utilisée en interne par certaines versions de DOS pour la redirection I/O }
 { Pour compatibilité, on retourne simplement sans erreur }
 MOV AL,0                   { Code de retour : succès (pas d'erreur) }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 1Fh: Fonction réservée/non documentée           }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@1Fh:
 { Fonction non documentée dans DOS classique }
 { Utilisée en interne par certaines versions de DOS pour la configuration d'imprimante }
 { Pour compatibilité, on retourne simplement sans erreur }
 MOV AL,0                   { Code de retour : succès (pas d'erreur) }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 20h: Terminer le programme (obsolète)           }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@20h:
 { Fonction de terminaison obsolète, équivalente à la fonction 00h }
 MOV AH,4Ch                 { Fonction 4Ch - Terminaison avec code de retour }
 XOR AL,AL                  { Code de retour = 0 }
 INT 21h                    { Appel récursif pour terminer proprement }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 21h: Lecture aléatoire avec FCB                 }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@21h:
 PUSH SI                    { Sauver registres }
 PUSH DI
 PUSH DS
 PUSH ES
 MOV SI,DX                  { DS:DX pointe sur le FCB }
 { Vérifier que le FCB est ouvert }
 CMP BYTE PTR [SI],0        { Drive = 0 ? }
 JE @21Error
 { Lecture aléatoire : utilise le champ "random record number" du FCB }
 { Offset 21h (33) dans le FCB contient le numéro d'enregistrement }
 { Implementation simplifiée: simuler une lecture réussie }
 { Dans un DOS complet, il faudrait :
   1. Lire le numéro d'enregistrement depuis FCB+21h (4 octets)
   2. Calculer la position dans le fichier
   3. Lire les données dans la DTA
   4. Mettre à jour les champs FCB si nécessaire }
 MOV AL,0                   { Code de retour: succès }
 JMP @21End
@21Error:
 MOV AL,1                   { Code d'erreur: EOF ou FCB invalide }
@21End:
 POP ES                     { Restaurer registres }
 POP DS
 POP DI
 POP SI
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 22h: Ecriture aléatoire avec FCB                }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@22h:
 PUSH SI                    { Sauver registres }
 PUSH DI
 PUSH DS
 PUSH ES
 MOV SI,DX                  { DS:DX pointe sur le FCB }
 { Vérifier que le FCB est ouvert }
 CMP BYTE PTR [SI],0        { Drive = 0 ? }
 JE @22Error
 { Ecriture aléatoire : utilise le champ "random record number" du FCB }
 { Implementation simplifiée: simuler une écriture réussie }
 { Dans un DOS complet, il faudrait :
   1. Lire le numéro d'enregistrement depuis FCB+21h (4 octets)
   2. Calculer la position dans le fichier
   3. Ecrire les données depuis la DTA
   4. Mettre à jour la taille du fichier dans le FCB si nécessaire }
 MOV AL,0                   { Code de retour: succès }
 JMP @22End
@22Error:
 MOV AL,1                   { Code d'erreur: disque plein ou FCB invalide }
@22End:
 POP ES                     { Restaurer registres }
 POP DS
 POP DI
 POP SI
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 23h: Obtenir la taille de fichier avec FCB      }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@23h:
 PUSH SI                    { Sauver registres }
 PUSH DI
 PUSH DS
 PUSH ES
 MOV SI,DX                  { DS:DX pointe sur le FCB }
 { Vérifier que le nom de fichier est valide dans le FCB }
 CMP BYTE PTR [SI+1],' '    { Premier caractère du nom vide ? }
 JE @23Error
 { Obtenir la taille du fichier et la convertir en numéro d'enregistrement }
 { Dans un DOS complet, il faudrait :
   1. Localiser le fichier sur le disque
   2. Lire sa taille depuis l'entrée de répertoire
   3. Calculer le numéro du dernier enregistrement
   4. Stocker ce numéro dans FCB+21h (random record number) }
 { Implementation simplifiée: simuler une taille fictive }
 MOV WORD PTR [SI+33],100   { Nombre d'enregistrements fictif (partie basse) }
 MOV WORD PTR [SI+35],0     { Partie haute = 0 }
 MOV AL,0                   { Code de retour: succès }
 JMP @23End
@23Error:
 MOV AL,0FFh                { Code d'erreur: fichier non trouvé }
@23End:
 POP ES                     { Restaurer registres }
 POP DS
 POP DI
 POP SI
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 24h: Définir l'adresse aléatoire avec FCB       }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@24h:
 PUSH SI                    { Sauver registres }
 PUSH DI
 PUSH DS
 PUSH ES
 MOV SI,DX                  { DS:DX pointe sur le FCB }
 { Vérifier que le FCB est valide }
 CMP BYTE PTR [SI],0        { Drive = 0 ? }
 JE @24Error
 { Définir l'adresse aléatoire dans le FCB }
 { Cette fonction copie le champ "current block" et "current record"
   vers le champ "random record number" pour permettre l'accès aléatoire }
 { FCB+0Ch = current block (2 octets)
   FCB+20h = current record (1 octet)
   FCB+21h = random record number (4 octets) }
 MOV AX,[SI+12]             { Lire current block }
 MOV BL,[SI+32]             { Lire current record }
 XOR BH,BH                  { Étendre à 16-bit }
 { Calculer l'adresse aléatoire: block * 128 + record }
 MOV CX,128                 { Taille de bloc standard }
 MUL CX                     { AX = block * 128 }
 ADD AX,BX                  { AX = block * 128 + record }
 MOV [SI+33],AX             { Stocker dans random record (partie basse) }
 MOV WORD PTR [SI+35],0     { Partie haute = 0 }
 MOV AL,0                   { Code de retour: succès }
 JMP @24End
@24Error:
 MOV AL,0FFh                { Code d'erreur: FCB invalide }
@24End:
 POP ES                     { Restaurer registres }
 POP DS
 POP DI
 POP SI
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 25h: Fixe le vecteur d'Interruption }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@25h:
 XOR BX,BX
 MOV ES,BX
 MOV BL,AL
 {$IFOPT G+}
  SHL BX,2
 {$ELSE}
  SHL BX,1
  SHL BX,1
 {$ENDIF}
 MOV ES:[BX],DX
 MOV ES:[BX+2],DS
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 26h: Créer un nouveau PSP                       }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@26h:
 { Créer un nouveau Program Segment Prefix }
 { DX contient l'adresse du segment du nouveau PSP }
 PUSH AX                    { Sauver registres }
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH DS
 PUSH ES
 { Dans une implémentation complète, il faudrait :
   1. Allouer un bloc mémoire de 256 octets (100h)
   2. Copier le PSP courant vers le nouveau PSP
   3. Modifier les champs nécessaires (comme la table des handles)
   4. Initialiser les pointeurs vers les routines DOS }
 { Version simplifiée : juste retourner succès }
 MOV AL,0                   { Code de retour: succès }
 POP ES                     { Restaurer registres }
 POP DS
 POP DI
 POP SI
 POP CX
 POP BX
 POP AX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 27h: Lecture aléatoire de bloc avec FCB         }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@27h:
 { Lire plusieurs enregistrements consécutifs à partir d'une position aléatoire }
 { DS:DX pointe sur FCB, CX contient le nombre d'enregistrements à lire }
 PUSH SI                    { Sauver registres }
 PUSH DI
 PUSH DS
 PUSH ES
 PUSH CX
 MOV SI,DX                  { DS:DX pointe sur le FCB }
 { Vérifier que le FCB est ouvert }
 CMP BYTE PTR [SI],0        { Drive = 0 ? }
 JE @27Error
 { Dans une implémentation complète, il faudrait :
   1. Lire le numéro d'enregistrement aléatoire depuis FCB+21h
   2. Lire CX enregistrements consécutifs depuis cette position
   3. Transférer les données vers la DTA
   4. Mettre à jour le pointeur de fichier dans le FCB }
 { Version simplifiée : simuler une lecture réussie de tous les enregistrements }
 POP CX                     { Nombre d'enregistrements demandés }
 MOV AL,0                   { Code de retour: succès, tous lus }
 JMP @27End
@27Error:
 POP CX                     { Nettoyer la pile }
 MOV AL,1                   { Code d'erreur: EOF ou FCB invalide }
 MOV CX,0                   { Aucun enregistrement lu }
@27End:
 POP ES                     { Restaurer registres }
 POP DS
 POP DI
 POP SI
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 28h: Ecriture aléatoire de bloc avec FCB        }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@28h:
 { Ecrire plusieurs enregistrements consécutifs à partir d'une position aléatoire }
 { DS:DX pointe sur FCB, CX contient le nombre d'enregistrements à écrire }
 PUSH SI                    { Sauver registres }
 PUSH DI
 PUSH DS
 PUSH ES
 PUSH CX
 MOV SI,DX                  { DS:DX pointe sur le FCB }
 { Vérifier que le FCB est ouvert }
 CMP BYTE PTR [SI],0        { Drive = 0 ? }
 JE @28Error
 { Dans une implémentation complète, il faudrait :
   1. Lire le numéro d'enregistrement aléatoire depuis FCB+21h
   2. Ecrire CX enregistrements consécutifs depuis cette position
   3. Prendre les données depuis la DTA
   4. Mettre à jour le pointeur de fichier et la taille dans le FCB }
 { Version simplifiée : simuler une écriture réussie de tous les enregistrements }
 POP CX                     { Nombre d'enregistrements demandés }
 MOV AL,0                   { Code de retour: succès, tous écrits }
 JMP @28End
@28Error:
 POP CX                     { Nettoyer la pile }
 MOV AL,1                   { Code d'erreur: disque plein ou FCB invalide }
 MOV CX,0                   { Aucun enregistrement écrit }
@28End:
 POP ES                     { Restaurer registres }
 POP DS
 POP DI
 POP SI
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 29h: Analyser nom de fichier dans FCB           }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@29h:
 { Analyser une chaîne de nom de fichier et la convertir en format FCB }
 { DS:SI pointe sur la chaîne source, ES:DI pointe sur le FCB destination }
 { AL contient les options d'analyse (bit 0: ignorer les séparateurs, etc.) }
 PUSH BX                    { Sauver registres }
 PUSH CX
 PUSH DX
 { Dans une implémentation complète, il faudrait :
   1. Analyser la chaîne caractère par caractère
   2. Extraire le lecteur, le nom et l'extension
   3. Convertir en format 8.3 majuscules
   4. Remplir les champs appropriés du FCB
   5. Gérer les caractères jokers (* et ?) }
 { Version simplifiée : juste marquer comme analysé avec succès }
 MOV AL,0                   { Code de retour: nom analysé avec succès }
 { Simuler un FCB basique : lecteur par défaut, nom "TEST    ", extension "   " }
 MOV BYTE PTR ES:[DI],0     { Drive = 0 (par défaut) }
 { Remplir avec des espaces }
 MOV CX,11                  { 8 caractères nom + 3 extension }
 MOV AL,' '
 PUSH DI
 INC DI
@29FillLoop:
 STOSB                      { Stocker AL dans ES:DI et incrémenter DI }
 LOOP @29FillLoop
 POP DI
 MOV AL,0                   { Code de retour final: succès }
 POP DX                     { Restaurer registres }
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 2Ah: Lire la date   }
 {- - - - - - - - - - - - - - - - - - - - - - - - -}
@2Ah:
 MOV AH,04h
 INT 1Ah
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 2Bh: Fixe la date   }
 {- - - - - - - - - - - - - - - - - - - - - - - - -}
@2Bh:
 MOV AH,05h
 INT 1Ah
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 2Ch: Lire l'heure système                       }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@2Ch:
 { Lire l'heure courante du système }
 { Retour : CH = heures (0-23), CL = minutes (0-59), DH = secondes (0-59), DL = centièmes (0-99) }
 PUSH AX                    { Sauver AX }
 MOV AH,02h                 { Fonction BIOS - Lire l'heure }
 INT 1Ah                    { Appel BIOS temps réel }
 { Le BIOS retourne l'heure dans CH:CL:DH format BCD }
 { Convertir du BCD vers binaire si nécessaire }
 { Pour simplifier, on simule une heure fixe 12:34:56.78 }
 MOV CH,12h                 { 12 heures }
 MOV CL,34h                 { 34 minutes }  
 MOV DH,56h                 { 56 secondes }
 MOV DL,78h                 { 78 centièmes }
 POP AX                     { Restaurer AX }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 2Dh: Fixer l'heure système                     }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@2Dh:
 { Fixer l'heure système }
 { Entrée : CH = heures (0-23), CL = minutes (0-59), DH = secondes (0-59), DL = centièmes (0-99) }
 { Sortie : AL = 0 si succès, AL = FFh si heure invalide }
 PUSH AX                    { Sauver AX }
 PUSH BX                    { Sauver BX }
 { Vérifier la validité de l'heure }
 CMP CH,23                  { Heures valides ? }
 JA @2DError
 CMP CL,59                  { Minutes valides ? }
 JA @2DError
 CMP DH,59                  { Secondes valides ? }
 JA @2DError
 CMP DL,99                  { Centièmes valides ? }
 JA @2DError
 { Heure valide - appeler le BIOS pour la fixer }
 MOV AH,03h                 { Fonction BIOS - Fixer l'heure }
 INT 1Ah                    { Appel BIOS }
 MOV AL,0                   { Code de retour : succès }
 JMP @2DEnd
@2DError:
 MOV AL,0FFh                { Code d'erreur : heure invalide }
@2DEnd:
 POP BX                     { Restaurer registres }
 XCHG AX,BX                 { Récupérer AL dans BX }
 POP AX                     { Restaurer AX original }
 MOV AL,BL                  { Mettre le code de retour dans AL }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 2Eh: Fixer/réinitialiser drapeau vérification  }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@2Eh:
 { Fixer ou réinitialiser le drapeau de vérification }
 { Entrée : AL = 0 pour désactiver la vérification, AL = 1 pour l'activer }
 { Sortie : aucune }
 CMP AL,1                   { Activer la vérification ? }
 JA @Xit                    { Valeur invalide - ignorer }
 { Dans un DOS complet, cette fonction activerait/désactiverait }
 { la vérification des écritures sur disque }
 { Pour cette implémentation, on ne fait rien mais on accepte la commande }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 2Fh: DOS Multiplex Interrupt                    }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@2Fh:
 { DOS Multiplex Interrupt - interface de communication pour TSR et utilitaires }
 { Entrée : AH = fonction, AL = sous-fonction, autres registres selon fonction }
 { Cette fonction est utilisée par DOSKEY, PRINT, APPEND, SHARE, etc. }
 { Pour cette implémentation de base, on retourne "fonction non supportée" }
 CMP AH,43h                 { Fonction 43h - Extended Memory Specification (XMS) ? }
 JE @2FhXMS
 CMP AH,10h                 { Fonction 10h - SHARE.EXE ? }
 JE @2FhShare
 { Fonction non reconnue - retourner AL=0 (non installé/supporté) }
 XOR AL,AL
 JMP @Xit
@2FhXMS:
 { XMS non implémenté dans ce DOS de base }
 XOR AL,AL
 JMP @Xit
@2FhShare:
 { SHARE.EXE non installé }
 XOR AL,AL
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 30h: Get DOS Version                            }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@30h:
 { Retourner la version DOS }
 { Sortie : AL = version majeure, AH = version mineure }
 { BH = fabricant OEM (00h = IBM PC-DOS, FFh = MS-DOS) }
 { BL:CX = numéro de série de l'utilisateur (généralement 0) }
 MOV AL,VerDos              { Version majeure (7) }
 MOV AH,SubVerDos           { Version mineure (10) }
 MOV BH,0FFh                { MS-DOS compatible }
 XOR BL,BL                  { Pas de numéro de série utilisateur }
 XOR CX,CX                  { Pas de numéro de série utilisateur }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 31h: Terminate Stay Resident (TSR)              }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@31h:
 { Terminer le programme en gardant une partie en mémoire (TSR) }
 { Entrée : AL = code de retour, DX = nombre de paragraphes à garder en mémoire }
 { Cette fonction est utilisée par les programmes résidents (TSR) }
 PUSH AX                    { Sauver registres }
 PUSH BX
 PUSH CX
 PUSH DX
 
 { Vérifier que DX n'est pas trop grand (limite raisonnable) }
 CMP DX,1000h               { Maximum ~64KB en paragraphes }
 JA @31hError
 
 { Dans un DOS complet, cette fonction devrait :
   1. Marquer les blocs mémoire comme résidents
   2. Ajuster la table des blocs mémoire (MCB - Memory Control Block)
   3. Libérer la mémoire non utilisée
   4. Sauvegarder le code de retour
   5. Retourner au programme parent sans libérer complètement le programme }
   
 { Version simplifiée pour cette implémentation de base :
   On simule un TSR en gardant le programme en mémoire mais sans
   implémenter la gestion complète des MCB }
   
 { Sauvegarder le code de retour (AL) dans une variable système }
 MOV BL,AL                  { Code de retour dans BL }
 
 { Calculer la taille mémoire à conserver }
 { DX contient le nombre de paragraphes (16 octets chacun) }
 MOV CX,DX                  { Nombre de paragraphes à garder }
 
 { Pour cette implémentation, on fait un appel à la fonction 4Ch }
 { avec le code de retour mais sans libérer complètement le programme }
 { Dans un vrai DOS, le programme resterait résident }
 
 { Simulation : marquer comme résident et retourner succès }
 { En réalité, le programme devrait rester en mémoire et actif }
 MOV AL,BL                  { Récupérer le code de retour }
 
 POP DX                     { Restaurer registres }
 POP CX
 POP BX
 POP AX
 
 { Pour l'instant, on fait comme une terminaison normale }
 { Dans un DOS complet, le programme continuerait à s'exécuter en arrière-plan }
 MOV AH,4Ch                 { Fonction 4Ch - Terminaison avec code de retour }
 INT 21h                    { Terminer (mais en gardant résident) }
 JMP @Xit

@31hError:
 { Erreur : trop de mémoire demandée }
 POP DX                     { Restaurer registres }
 POP CX
 POP BX
 POP AX
 { Retourner une erreur - dans ce cas on termine normalement }
 MOV AH,4Ch                 { Fonction 4Ch - Terminaison avec code d'erreur }
 MOV AL,1                   { Code d'erreur = 1 }
 INT 21h
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 32h: Get Drive Parameter Block (DPB)            }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@32h:
 { Obtenir le DPB (Drive Parameter Block) pour un lecteur spécifié }
 { Entrée : DL = numéro de lecteur (0=défaut, 1=A:, 2=B:, etc.) }
 { Sortie : AL = 0 si succès, FFh si erreur; DS:BX pointe sur le DPB }
 PUSH AX                    { Sauver registres }
 PUSH CX
 PUSH DX
 PUSH DI
 PUSH ES
 
 { Vérifier le numéro de lecteur }
 CMP DL,0                   { Lecteur par défaut ? }
 JE @32hDefaultDrive
 CMP DL,26                  { Vérifier limite (A-Z) }
 JA @32hError
 
@32hDefaultDrive:
 { Dans un DOS complet, le DPB contient les informations détaillées du lecteur :
   - Octets par secteur
   - Secteurs par cluster  
   - Secteurs réservés
   - Nombre de FAT
   - Entrées répertoire racine
   - Secteurs par FAT
   - Type de média
   etc. }
   
 { Pour cette implémentation simplifiée, on simule un DPB basique }
 { Créer un DPB fictif en mémoire }
 PUSH CS
 POP DS                     { DS pointe sur notre segment }
 MOV BX,OFFSET @DPB32h      { BX pointe sur le DPB simulé }
 MOV AL,0                   { Code de retour : succès }
 JMP @32hEnd

@32hError:
 { Lecteur invalide }
 MOV AL,0FFh                { Code d'erreur : lecteur invalide }
 XOR BX,BX                  { Pas de DPB valide }
 JMP @32hEnd

@DPB32h:
 { Structure DPB simplifiée (format DOS standard) }
 DB 0                       { Drive number (0=A:, 1=B:, etc.) }
 DB 1                       { Unit number }
 DW 512                     { Bytes per sector }
 DB 0                       { Sectors per cluster - 1 }
 DB 1                       { Shift count for sectors per cluster }
 DW 1                       { Reserved sectors }
 DB 2                       { Number of FATs }
 DW 224                     { Root directory entries }
 DW 2880                    { Total sectors }
 DB 0F0h                    { Media descriptor }
 DW 9                       { Sectors per FAT }
 DW 18                      { Sectors per track }
 DW 2                       { Number of heads }
 DD 0                       { Hidden sectors }
 DD 0                       { Large total sectors }
 DB 0                       { Reserved }
 DB 0                       { Reserved }
 DB 0                       { Reserved }
 
@32hEnd:
 POP ES                     { Restaurer registres }
 POP DI
 POP DX
 POP CX
 { Le code de retour est déjà dans AL }
 { BX contient déjà l'offset du DPB }
 { Restaurer AX original mais garder AL }
 XCHG AL,AH                 { Échanger AL et AH temporairement }
 POP AX                     { Restaurer AX original }
 XCHG AL,AH                 { Remettre le code de retour dans AL }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 33h: Multi-fonction }
 {- - - - - - - - - - - - - - - - - - - - - - - - -}
@33h:
 { Multi-fonction de contrôle système }
 CMP AL,00h                 { Sous-fonction 00h : Get Control Break state ? }
 JE @33h00h
 CMP AL,01h                 { Sous-fonction 01h : Set Control Break state ? }
 JE @33h01h
 CMP AL,05h                 { Sous-fonction 05h : Get boot drive ? }
 JE @33h05h
 CMP AL,06h                 { Sous-fonction 06h : Get DOS version (existante) ? }
 JE @33h06h
 JMP @Unknown33h

@33h00h:
 { Sous-fonction 00h : Get Control Break check state }
 { Sortie : DL = état actuel (0=désactivé, 1=activé) }
 MOV DL,1                   { Pour cette implémentation, toujours activé }
 JMP @Xit

@33h01h:
 { Sous-fonction 01h : Set Control Break check state }
 { Entrée : DL = nouvel état (0=désactiver, 1=activer) }
 { Dans un DOS complet, ceci contrôlerait si Ctrl+C est vérifié pendant les E/S }
 { Pour cette implémentation, on accepte la commande mais sans effet réel }
 CMP DL,1                   { Valeur valide ? }
 JA @Xit                    { Ignorer les valeurs invalides }
 { État accepté, pas de valeur de retour }
 JMP @Xit

@33h05h:
 { Sous-fonction 05h : Get boot drive }
 { Sortie : DL = lecteur de boot (1=A:, 2=B:, 3=C:, etc.) }
 MOV DL,3                   { Simuler boot depuis C: (lecteur 3) }
 JMP @Xit

@33h06h:
 { Sous-fonction 06h : Get DOS version (fonction existante) }
 MOV BL,VerDos              { Version majeure }
 MOV BH,SubVerDos           { Version mineure }
 XOR DX,DX                  { Pas d'information supplémentaire }
 MOV AL,0FFh                { Indicateur de succès }
 JMP @Xit

@Unknown33h:
 { Sous-fonction non supportée }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 34h: Demande l'adresse du drapeau "InDos" }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@34h:
 MOV BX,Offset Data.DataMOS.InDos
 PUSH CS
 POP ES
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 35h: Demande le vecteur d'Interruption }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@35h:
 XOR BX,BX
 MOV ES,BX
 MOV BL,AL
 SHL BX,1
 SHL BX,1
 LES BX,DWord Ptr ES:[BX]
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 36h: Get free disk space                }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@36h:
 { Obtenir l'espace libre sur un lecteur spécifié }
 { Entrée : DL = numéro de lecteur (0=défaut, 1=A:, 2=B:, 3=C:, etc.) }
 { Sortie : AX = secteurs par cluster (-1 si erreur) }
 {         BX = clusters libres disponibles }
 {         CX = octets par secteur }  
 {         DX = total clusters sur le lecteur }
 PUSH AX                    { Sauver registres }
 PUSH BX
 PUSH CX
 
 { Vérifier le numéro de lecteur }
 CMP DL,0                   { Lecteur par défaut ? }
 JE @36hDefaultDrive
 CMP DL,26                  { Vérifier limite (A-Z) }
 JA @36hError
 
@36hDefaultDrive:
 { Dans un DOS complet, cette fonction interrogerait le système de fichiers }
 { Pour cette implémentation simplifiée, on simule les valeurs d'une disquette 1.44MB }
 
 { Simuler les paramètres d'une disquette 1.44MB }
 MOV AX,1                   { 1 secteur par cluster }
 MOV BX,1440                { Environ 1440 clusters libres (exemple) }
 MOV CX,512                 { 512 octets par secteur }
 MOV DX,2880                { 2880 clusters total sur disquette 1.44MB }
 
 POP CX                     { Restaurer les registres sauvés }
 POP BX                     { mais on va les écraser avec nos valeurs }
 POP AX
 
 { Remettre nos valeurs calculées }
 MOV AX,1                   { 1 secteur par cluster }
 MOV BX,1440                { 1440 clusters libres }
 MOV CX,512                 { 512 octets par secteur }
 MOV DX,2880                { 2880 clusters total }
 JMP @Xit

@36hError:
 { Lecteur invalide }
 POP CX                     { Restaurer registres }
 POP BX
 POP AX
 MOV AX,0FFFFh              { Code d'erreur : -1 dans AX }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 37h: Switch character functions         }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@37h:
 { Fonctions de caractère de commutation DOS }
 { AL = sous-fonction : }
 { 00h = Get switch character (généralement '/') }
 { 01h = Set switch character }
 { 02h = Get available device list }
 { 03h = Set available device list }
 
 CMP AL,00h                 { Sous-fonction 00h : Get switch character ? }
 JE @37h00h
 CMP AL,01h                 { Sous-fonction 01h : Set switch character ? }
 JE @37h01h
 CMP AL,02h                 { Sous-fonction 02h : Get device list ? }
 JE @37h02h
 CMP AL,03h                 { Sous-fonction 03h : Set device list ? }
 JE @37h03h
 JMP @37hUnknown

@37h00h:
 { Sous-fonction 00h : Get switch character }
 { Sortie : DL = caractère de commutation (généralement '/') }
 MOV DL,'/'                 { Caractère de commutation standard DOS }
 JMP @Xit

@37h01h:
 { Sous-fonction 01h : Set switch character }
 { Entrée : DL = nouveau caractère de commutation }
 { Dans un DOS complet, on sauvegarderait ce caractère }
 { Pour cette implémentation, on accepte mais on ne change rien }
 JMP @Xit

@37h02h:
 { Sous-fonction 02h : Get available device list }
 { Cette fonction était utilisée par certaines versions de DOS }
 { pour obtenir des informations sur les périphériques disponibles }
 MOV DL,0                   { Valeur par défaut }
 JMP @Xit

@37h03h:
 { Sous-fonction 03h : Set available device list }
 { Accepter la commande sans effet réel }
 JMP @Xit

@37hUnknown:
 { Sous-fonction non supportée }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 38h: Get/Set Country Information        }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@38h:
 { Obtenir ou fixer les informations de localisation (pays) }
 { AL = sous-fonction : }
 { 00h = Get current country info }
 { FFh = Set country info }
 { DX = code pays (AL=FFh) ou buffer (AL=00h) }
 
 CMP AL,00h                 { Sous-fonction 00h : Get country info ? }
 JE @38h00h
 CMP AL,0FFh                { Sous-fonction FFh : Set country info ? }
 JE @38hFFh
 JMP @38hUnknown

@38h00h:
 { Sous-fonction 00h : Get current country information }
 { Sortie : BX = code pays, DS:DX pointe sur structure d'informations pays }
 PUSH AX                    { Sauver registres }
 PUSH CX
 PUSH DI
 PUSH ES
 
 { Pour cette implémentation simplifiée, on simule les informations pour la France }
 MOV BX,33                  { Code pays France (33) }
 
 { Vérifier si DX pointe vers un buffer valide pour les informations étendues }
 CMP DX,0                   { Buffer fourni ? }
 JE @38h00hNoBuf
 
 { Remplir le buffer avec les informations pays (structure de 38 octets) }
 PUSH DS
 MOV DI,DX                  { ES:DI pointe sur le buffer destination }
 
 { Structure Country Info (format DOS) : }
 { +00 : Date format (0=USA mm/dd/yy, 1=Europe dd/mm/yy, 2=Japan yy/mm/dd) }
 MOV BYTE PTR ES:[DI],1     { Format européen dd/mm/yy }
 INC DI
 
 { +01 : Currency symbol (5 bytes ASCIIZ) }
 MOV AL,'F'
 STOSB                      { F }
 MOV AL,'R'
 STOSB                      { R }
 MOV AL,0
 STOSB                      { Terminateur }
 STOSB                      { Padding }
 STOSB                      { Padding }
 
 { +06 : Thousands separator (2 bytes ASCIIZ) }
 MOV AL,' '                 { Espace pour milliers en français }
 STOSB
 MOV AL,0
 STOSB
 
 { +08 : Decimal separator (2 bytes ASCIIZ) }
 MOV AL,','                 { Virgule décimale française }
 STOSB
 MOV AL,0
 STOSB
 
 { +0A : Date separator (2 bytes ASCIIZ) }
 MOV AL,'/'
 STOSB
 MOV AL,0
 STOSB
 
 { +0C : Time separator (2 bytes ASCIIZ) }
 MOV AL,':'
 STOSB
 MOV AL,0
 STOSB
 
 { +0E : Currency format (1 byte) }
 MOV BYTE PTR ES:[DI],0     { 0 = currency symbol precedes value }
 INC DI
 
 { +0F : Digits after decimal in currency (1 byte) }
 MOV BYTE PTR ES:[DI],2     { 2 digits après virgule pour francs }
 INC DI
 
 { +10 : Time format (1 byte: 0=12hr, 1=24hr) }
 MOV BYTE PTR ES:[DI],1     { Format 24h européen }
 INC DI
 
 { +11 : Case conversion routine address (4 bytes) - on met 0 }
 XOR AX,AX
 STOSW
 STOSW
 
 { +15 : Data list separator (2 bytes ASCIIZ) }
 MOV AL,';'                 { Point-virgule }
 STOSB
 MOV AL,0
 STOSB
 
 { +17 : Reserved (10 bytes) }
 MOV CX,10
@38hFillZero:
 XOR AL,AL
 STOSB
 LOOP @38hFillZero
 
 POP DS                     { Restaurer DS }

@38h00hNoBuf:
 POP ES                     { Restaurer registres }
 POP DI
 POP CX
 POP AX
 { BX contient déjà le code pays (33) }
 JMP @Xit

@38hFFh:
 { Sous-fonction FFh : Set country information }
 { Entrée : DX = code pays à définir }
 PUSH AX                    { Sauver registres }
 PUSH BX
 
 { Dans un DOS complet, on sauvegarderait le nouveau code pays }
 { Pour cette implémentation, on accepte mais on ne change rien réellement }
 { Vérifier que c'est un code pays raisonnable }
 CMP DX,999                 { Code pays raisonnable ? }
 JA @38hFFhError
 
 { Code pays accepté }
 MOV BX,DX                  { Retourner le code pays dans BX }
 POP BX                     { Restaurer BX original }
 POP AX
 JMP @Xit

@38hFFhError:
 { Code pays invalide }
 POP BX
 POP AX
 MOV AX,2                   { Code d'erreur : Invalid country code }
 JMP @Xit

@38hUnknown:
 { Sous-fonction non supportée }
 MOV AX,1                   { Code d'erreur : Invalid function }
 JMP @Xit

@Xit:
 DEC Data.DataMOS.InDos
END;

Procedure Intr25h;Assembler;ASM
 XCHG AX,DX
 MOV AX,0201h
 PUSH DS
 POP ES
  { Conversion des pistes et cylindres en secteur absolue a faire ...}
 INT 13h
END;

Procedure Intr26h;Assembler;ASM
END;

Procedure Intr28h;Assembler;ASM
 { Vide - Executer a temps perdu! }
END;

Procedure Intr2Ah;Assembler;ASM
 XOR AX,AX
END;

Procedure Intr2Fh;Assembler;ASM
 XOR BX,BX
 XOR AX,AX
END;

Procedure Intr33h;Assembler;ASM
 XOR AX,AX
END;

Procedure SetIntVec(AL:Byte;DS,DX:Word);
Var
 TableInt:Array[Byte]of Pointer Absolute 0:0;
Begin
 TableInt[AL]:=Ptr(DS,DX);
End;

Procedure END_KERNEL;Begin
 ASM
  DB 'FIN DU NOYAU MSDOS-0';
 END;
End;

END.
