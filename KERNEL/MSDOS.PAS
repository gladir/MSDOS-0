{ @description: Le MS Operating System est un systeme d'exploitation remplacant le DOS traditionnel.

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
  - 0Bh : Lire l'etat d'entree
  - 0Ch : Vider le tampon et appeler la fonction d'entree
  - 0Dh : Reinitialisation du disque
  - 0Eh : Selectionne le lecteur courant
  - 19h : Demande le lecteur courant
  - 25h : Fixe le vecteur d'interruption
  - 2Ah : Lire la date
  - 2Bh : Fixe la date
  - 33h : Multi-fonction
  - 34h : Demande l'adresse du drapeau InDos
  - 35h : Demande le vecteur d'interruption

  @author: Developpe selon les specifications MS-DOS
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
End;

Procedure BEGIN_KERNEL;Assembler;ASM
END;

Procedure Data;Assembler;ASM
 DB 0          { Key:   Touche }
 DB 0          { InDos: Dans l'Interruption DOS? }
 DB 0          { CurrDisk: Disque courant }
END;

Procedure Intr21;Interrupt;Assembler;ASM
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
 DW @Xit { Fonction 0Fh - a developper }
 DW @Xit { Fonction 10h - a developper }
 DW @Xit { Fonction 11h - a developper }
 DW @Xit { Fonction 12h - a developper }
 DW @Xit { Fonction 13h - a developper }
 DW @Xit { Fonction 14h - a developper }
 DW @Xit { Fonction 15h - a developper }
 DW @Xit { Fonction 16h - a developper }
 DW @Xit { Fonction 17h - a developper }
 DW @Xit { Fonction 18h - a developper }
 DW @19h { Fonction 19h - Demande le lecteur courant }
 DW @Xit { Fonction 1Ah - a developper }
 DW @Xit { Fonction 1Bh - a developper }
 DW @Xit { Fonction 1Ch - a developper }
 DW @Xit { Fonction 1Dh - a developper }
 DW @Xit { Fonction 1Eh - a developper }
 DW @Xit { Fonction 1Fh - a developper }
 DW @Xit { Fonction 20h - a developper }
 DW @Xit { Fonction 21h - a developper }
 DW @Xit { Fonction 22h - a developper }
 DW @Xit { Fonction 23h - a developper }
 DW @Xit { Fonction 24h - a developper }
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

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 19h: Demande le lecteur courant }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@19h:
 MOV AL,Data.DataMOS.CurrDisk
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

Procedure Intr25h;Interrupt;Assembler;ASM
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

Procedure END_KERNEL;Begin
End;

END.
