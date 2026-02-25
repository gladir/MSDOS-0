{ @description: Le ®MS Operating System¯ est un systŠme d'exploitation rempla‡ant le DOS traditionnel.
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
 DW @Xit { Fonction 01h - … d‚velopper }
 DW @Xit { Fonction 02h - … d‚velopper }
 DW @Xit { Fonction 03h - … d‚velopper }
 DW @Xit { Fonction 04h - … d‚velopper }
 DW @Xit { Fonction 05h - … d‚velopper }
 DW @Xit { Fonction 06h - … d‚velopper }
 DW @07h { Fonction 07h - Entr‚e de caractŠre directe sans sortie }
 DW @08h { Fonction 08h - Entr‚e de caractŠre sans sortie}
 DW @Xit { Fonction 09h - … d‚velopper }
 DW @Xit { Fonction 0Ah - … d‚velopper }
 DW @0Bh { Fonction 0Bh - Lire l'‚tat d'entr‚e}
 DW @0Ch { Fonction 0Ch - Vider le tampon et appeler la fonction d'entr‚e }
 DW @Xit { Fonction 0Dh - … d‚velopper }
 DW @0Eh { Fonction 0Eh - S‚lectionne le disque courant }
 DW @Xit { Fonction 0Fh - … d‚velopper }
 DW @Xit { Fonction 10h - … d‚velopper }
 DW @Xit { Fonction 11h - … d‚velopper }
 DW @Xit { Fonction 12h - … d‚velopper }
 DW @Xit { Fonction 13h - … d‚velopper }
 DW @Xit { Fonction 14h - … d‚velopper }
 DW @Xit { Fonction 15h - … d‚velopper }
 DW @Xit { Fonction 16h - … d‚velopper }
 DW @Xit { Fonction 17h - … d‚velopper }
 DW @Xit { Fonction 18h - … d‚velopper }
 DW @19h { Fonction 19h - Demande le lecteur courant }
 DW @Xit { Fonction 1Ah - … d‚velopper }
 DW @Xit { Fonction 1Bh - … d‚velopper }
 DW @Xit { Fonction 1Ch - … d‚velopper }
 DW @Xit { Fonction 1Dh - … d‚velopper }
 DW @Xit { Fonction 1Eh - … d‚velopper }
 DW @Xit { Fonction 1Fh - … d‚velopper }
 DW @Xit { Fonction 20h - … d‚velopper }
 DW @Xit { Fonction 21h - … d‚velopper }
 DW @Xit { Fonction 22h - … d‚velopper }
 DW @Xit { Fonction 23h - … d‚velopper }
 DW @Xit { Fonction 24h - … d‚velopper }
 DW @25h { Fonction 25h - Fixe le vecteur d'Interruption}
 DW @Xit { Fonction 26h - … d‚velopper }
 DW @Xit { Fonction 27h - … d‚velopper }
 DW @Xit { Fonction 28h - … d‚velopper }
 DW @Xit { Fonction 29h - … d‚velopper }
 DW @2Ah { Fonction 2Ah - Lire la date }
 DW @2Bh { Fonction 2Bh - Fixe la date }
 DW @Xit { Fonction 2Ch - … d‚velopper }
 DW @Xit { Fonction 2Dh - … d‚velopper }
 DW @Xit { Fonction 2Eh - … d‚velopper }
 DW @Xit { Fonction 2Fh - … d‚velopper }
 DW @Xit { Fonction 30h - … d‚velopper }
 DW @Xit { Fonction 31h - … d‚velopper }
 DW @Xit { Fonction 32h - … d‚velopper }
 DW @33h { Fonction 33h - Multi-fonction }
 DW @34h { Fonction 34h - Demande l'adresse du drapeau "InDos" }
 DW @35h { Fonction 35h - Demande le vecteur d'Interruption}
@00h:
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 07h: Entr‚e de caractŠre directe sans sortie }
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
 { Interruption 21h - Fonction 08h: Entr‚e de caractŠre sans sortie }
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
 { Interruption 21h - Fonction 0Bh: Lire l'‚tat d'entr‚e }
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
 { Interruption 21h - Fonction 0Ch: Vider le tampon et appeler la fonction d'entr‚e }
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
 { Interruption 21h - Fonction 0Eh: S‚lectionne le lecteur courant }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@0Eh:
 MOV AL,26 { Nombre d'unit‚ install‚ }
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
  { Conversion des pistes et cylindres en secteur absolue … faire ...}
 INT 13h
END;

Procedure Intr26h;Interrupt;Assembler;ASM
END;

Procedure Intr28h;Interrupt;Assembler;ASM
 { Vide - Ex‚cuter … temps perdu! }
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
