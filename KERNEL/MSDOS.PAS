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
  - 09h : Affichage de chaine terminee par $
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
  - 20h : Terminer le programme (obsolète)
  - 21h : Lecture aléatoire avec FCB
  - 22h : Ecriture aléatoire avec FCB
  - 23h : Obtenir la taille de fichier avec FCB
  - 24h : Définir l'adresse aléatoire avec FCB
  - 25h : Fixe le vecteur d'interruption
  - 2Ah : Lire la date
  - 2Bh : Fixe la date
  - 33h : Multi-fonction
  - 34h : Demande l'adresse du drapeau InDos
  - 35h : Demande le vecteur d'interruption

  @target: Turbo Pascal 7 (syntaxe assembleur Intel)
}

Unit MSDOS;

INTERFACE

Procedure BEGIN_KERNEL;
Procedure END_KERNEL;

Procedure Intr21h;Interrupt;

IMPLEMENTATION

Const
 VerDos=7;          { Version de DOS }
 SubVerDos=10;      { Sous-version de DOS }

Type DataMOS=Record
 Key:Byte;
 InDos:Byte;
 CurrDisk:Byte;
End;

Procedure Intr25h;Interrupt;Forward;

Procedure SetIntVec(AL:Byte;DS,DX:Word);Near;Forward;

Procedure BEGIN_KERNEL;Begin
 SetIntVec($21,CSeg,Ofs(Intr21h));
 SetIntVec($25,CSeg,Ofs(Intr25h));
  { TODO : Charger un programme COMMAND.EXE, faire un JMP sur le point d'entr�e du programme charg� en m�moire }
 ASM
  DB 'DEBUT DU NOYAU MSDOS-0';
 END;
End;

Procedure Data;Assembler;ASM
 DB 0          { Key:   Touche }
 DB 0          { InDos: Dans l'Interruption DOS? }
 DB 0          { CurrDisk: Disque courant }
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
 DW @Xit { Fonction 1Ah - a developper }
 DW @Xit { Fonction 1Bh - a developper }
 DW @Xit { Fonction 1Ch - a developper }
 DW @Xit { Fonction 1Dh - a developper }
 DW @Xit { Fonction 1Eh - a developper }
 DW @Xit { Fonction 1Fh - a developper }
 DW @20h { Fonction 20h - Terminer le programme (obsolète) }
 DW @21h { Fonction 21h - Lecture aléatoire avec FCB }
 DW @22h { Fonction 22h - Ecriture aléatoire avec FCB }
 DW @23h { Fonction 23h - Obtenir la taille de fichier avec FCB }
 DW @24h { Fonction 24h - Définir l'adresse aléatoire avec FCB }
 DW @25h { Fonction 25h - Fixe le vecteur d'Interruption}
 DW @Xit { Fonction 26h - a developper }
 DW @Xit { Fonction 27h - a developper }
 DW @Xit { Fonction 28h - a developper }
 DW @Xit { Fonction 29h - a developper }
 DW @2Ah { Fonction 2Ah - Lire la date }
 DW @2Bh { Fonction 2Bh - Fixe la date }
 DW @Xit { Fonction 2Ch - a developper }
 DW @Xit { Fonction 2Dh - a developper }
 DW @Xit { Fonction 2Eh - a developper }
 DW @Xit { Fonction 2Fh - a developper }
 DW @Xit { Fonction 30h - a developper }
 DW @Xit { Fonction 31h - a developper }
 DW @Xit { Fonction 32h - a developper }
 DW @33h { Fonction 33h - Multi-fonction }
 DW @34h { Fonction 34h - Demande l'adresse du drapeau "InDos" }
 DW @35h { Fonction 35h - Demande le vecteur d'Interruption}

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

 {- - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 33h: Multi-fonction }
 {- - - - - - - - - - - - - - - - - - - - - - - - -}
@33h:
 CMP AL,06h
 JNE @Unknown33h
 MOV BL,VerDos
 MOV BH,SubVerDos
 XOR DX,DX
 MOV AL,0FFh
 JMP @Xit
@Unknown33h:
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

Procedure Intr26h;Interrupt;Assembler;ASM
END;

Procedure Intr28h;Interrupt;Assembler;ASM
 { Vide - Executer a temps perdu! }
END;

Procedure Intr2Ah;Interrupt;Assembler;ASM
 XOR AX,AX
END;

Procedure Intr2Fh;Interrupt;Assembler;ASM
 XOR BX,BX
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
