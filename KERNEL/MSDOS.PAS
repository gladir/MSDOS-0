{ @description: Le MS Operating System est un systeme d'exploitation remplacant le DOS traditionnel.

  Fonctions DOS implementees :
  - 01h : Entree de caractere avec echo
  - 02h : Sortie de caractere
  - 03h : Entree de caractere depuis AUX (port serie)
  - 04h : Sortie de caractere vers AUX (port serie)
  - 05h : Sortie de caractere vers PRN (imprimante)
  - 06h : Entree/sortie directe de console
  - 07h : Entree de caractere directe sans sortie
  - 08h : Entree de caractere sans sortie (avec Ctrl+C)
  - 0Bh : Lire l'etat d'entree
  - 0Ch : Vider le tampon et appeler la fonction d'entree
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
END;

Procedure Intr21;Interrupt;Assembler;ASM
 INC Data.DataMOS.InDos
 MOV BL,AH
@CallFunc:
 XOR BH,BH
 SHL BX,1
 JMP @Label.Word[BX]
@Label:
 DW @00h { Fonction 00h }
 DW @01h { Fonction 01h - Entr�e de caract�re avec �cho }
 DW @02h { Fonction 02h - Sortie de caract�re }
 DW @03h { Fonction 03h - Entr�e de caract�re depuis AUX }
 DW @04h { Fonction 04h - Sortie de caract�re vers AUX }
 DW @05h { Fonction 05h - Sortie de caract�re vers PRN }
 DW @06h { Fonction 06h - Entr�e/sortie directe de console }
 DW @07h { Fonction 07h - Entr�e de caract�re directe sans sortie }
 DW @08h { Fonction 08h - Entr�e de caract�re sans sortie}
 DW @Xit { Fonction 09h - � d�velopper }
 DW @Xit { Fonction 0Ah - � d�velopper }
 DW @0Bh { Fonction 0Bh - Lire l'�tat d'entr�e}
 DW @0Ch { Fonction 0Ch - Vider le tampon et appeler la fonction d'entr�e }
 DW @Xit { Fonction 0Dh - � d�velopper }
 DW @0Eh { Fonction 0Eh - S�lectionne le disque courant }
 DW @Xit { Fonction 0Fh - � d�velopper }
 DW @Xit { Fonction 10h - � d�velopper }
 DW @Xit { Fonction 11h - � d�velopper }
 DW @Xit { Fonction 12h - � d�velopper }
 DW @Xit { Fonction 13h - � d�velopper }
 DW @Xit { Fonction 14h - � d�velopper }
 DW @Xit { Fonction 15h - � d�velopper }
 DW @Xit { Fonction 16h - � d�velopper }
 DW @Xit { Fonction 17h - � d�velopper }
 DW @Xit { Fonction 18h - � d�velopper }
 DW @19h { Fonction 19h - Demande le lecteur courant }
 DW @Xit { Fonction 1Ah - � d�velopper }
 DW @Xit { Fonction 1Bh - � d�velopper }
 DW @Xit { Fonction 1Ch - � d�velopper }
 DW @Xit { Fonction 1Dh - � d�velopper }
 DW @Xit { Fonction 1Eh - � d�velopper }
 DW @Xit { Fonction 1Fh - � d�velopper }
 DW @Xit { Fonction 20h - � d�velopper }
 DW @Xit { Fonction 21h - � d�velopper }
 DW @Xit { Fonction 22h - � d�velopper }
 DW @Xit { Fonction 23h - � d�velopper }
 DW @Xit { Fonction 24h - � d�velopper }
 DW @25h { Fonction 25h - Fixe le vecteur d'Interruption}
 DW @Xit { Fonction 26h - � d�velopper }
 DW @Xit { Fonction 27h - � d�velopper }
 DW @Xit { Fonction 28h - � d�velopper }
 DW @Xit { Fonction 29h - � d�velopper }
 DW @2Ah { Fonction 2Ah - Lire la date }
 DW @2Bh { Fonction 2Bh - Fixe la date }
 DW @Xit { Fonction 2Ch - � d�velopper }
 DW @Xit { Fonction 2Dh - � d�velopper }
 DW @Xit { Fonction 2Eh - � d�velopper }
 DW @Xit { Fonction 2Fh - � d�velopper }
 DW @Xit { Fonction 30h - � d�velopper }
 DW @Xit { Fonction 31h - � d�velopper }
 DW @Xit { Fonction 32h - � d�velopper }
 DW @33h { Fonction 33h - Multi-fonction }
 DW @34h { Fonction 34h - Demande l'adresse du drapeau "InDos" }
 DW @35h { Fonction 35h - Demande le vecteur d'Interruption}
@00h:
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 01h: Entr�e de caract�re avec �cho              }
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
 PUSH AX                    { Sauver le caract�re }
 MOV DL,AL
 MOV AH,02h                 { Fonction 02h - Sortie caract�re }
 INT 21h
 POP AX                     { Restaurer le caract�re }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 02h: Sortie de caract�re                        }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@02h:
 MOV AL,DL
 MOV AH,0Eh                 { BIOS - Sortie caract�re }
 XOR BX,BX                  { Page 0, couleur par d�faut }
 INT 10h
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 03h: Entr�e de caract�re depuis AUX             }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@03h:
 MOV AH,02h                 { BIOS - Lire caract�re s�rie }
 XOR DX,DX                  { Port COM1 }
 INT 14h
 TEST AH,80h                { V�rifier timeout }
 JZ @03NoError
 MOV AL,1Ah                 { Code EOF si erreur }
@03NoError:
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 04h: Sortie de caract�re vers AUX               }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@04h:
 MOV AL,DL
 MOV AH,01h                 { BIOS - �crire caract�re s�rie }
 XOR DX,DX                  { Port COM1 }
 INT 14h
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 05h: Sortie de caract�re vers PRN (imprimante)  }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@05h:
 MOV AL,DL
 XOR AH,AH                  { BIOS - Imprimer caract�re }
 XOR DX,DX                  { Port LPT1 }
 INT 17h
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 06h: Entr�e/sortie directe de console           }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@06h:
 CMP DL,0FFh                { Fonction d'entr�e ? }
 JNE @06Output
 { Fonction d'entr�e }
 MOV AL,Data.DataMOS.Key
 OR  AL,AL
 JE  @06CheckKeyboard
 MOV AH,0
 MOV Data.DataMOS.Key,0     { Effacer la touche }
 CMP AL,0                   { Zero Flag = 0 si caract�re disponible }
 JMP @Xit
@06CheckKeyboard:
 MOV AH,01h                 { BIOS - V�rifier si touche disponible }
 INT 16h
 JZ  @06NoKey              { Pas de touche }
 XOR AX,AX                  { Lire la touche }
 INT 16h
 MOV Data.DataMOS.Key,AH    { Sauver scan code }
 TEST AL,AL                 { Zero Flag = 0 si caract�re valide }
 JMP @Xit
@06NoKey:
 XOR AL,AL                  { Pas de caract�re - Zero Flag = 1 }
 JMP @Xit
@06Output:
 { Fonction de sortie }
 MOV AL,DL
 MOV AH,0Eh                 { BIOS - Sortie caract�re }
 XOR BX,BX                  { Page 0, couleur par d�faut }
 INT 10h
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 07h: Entr�e de caract�re directe sans sortie }
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
 { Interruption 21h - Fonction 08h: Entr�e de caract�re sans sortie }
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
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 0Bh: Lire l'�tat d'entr�e }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - -}
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
 { Interruption 21h - Fonction 0Ch: Vider le tampon et appeler la fonction d'entr�e }
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
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 0Eh: S�lectionne le lecteur courant }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@0Eh:
 MOV AL,26 { Nombre d'unit� install� }
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
  { Conversion des pistes et cylindres en secteur absolue � faire ...}
 INT 13h
END;

Procedure Intr26h;Interrupt;Assembler;ASM
END;

Procedure Intr28h;Interrupt;Assembler;ASM
 { Vide - Ex�cuter � temps perdu! }
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
