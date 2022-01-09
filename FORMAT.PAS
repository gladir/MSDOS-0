{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/msdos-0)
  @abstract(Target: Turbo Pascal)
}

Program Format;

{$A-,F-,O-}

Uses DOS;

Const
 {Adresse d'assembleur pour le micro-processeur Intel (Cpu Intel)}
 ciBXnSI=$00;{®[BX+SI]¯,88+}
 ciBXnDI=$01;{®[BX+DI]¯,88+}
 ciBPnSI=$02;{®[BP+SI]¯,88+}
 ciBPnDI=$03;{®[BP+DI]¯,88+}
 ciSI=$04;{®[SI]¯,88+}
 ciDI=$05;{®[DI]¯,88+}
 ciBP=$06;{®[BP]¯,88+}
 ciBX=$07;{®[BX]¯,88+}
 {Instruction d'assembleur pour le micro-processeur Intel (Cpu Intel)}
 ciAAA=$37;{®AAA¯,88+}
 ciAAD_=$D5;{®AAD¯,88+}
 ciAAM_=$D4;{®AAM¯,88+}
 ciAAS=$3F;{®AAS¯,88+}
 ciAdcAL_=$14;{®ADC AL,??h¯,286+}
 ciAdcAX_=$15;{®ADC AX,????h¯,286+}
 ciAddAL_=$04;{®ADD AL,??h¯,286+}
 ciAddAX_=$05;{®ADD AX,????h¯,286+}
 ciAndAL_=$24;{®AND AL,??h¯,286+}
 ciAndAX_=$25;{®AND AX,????h¯,286+}
 ciCallFarAbs=$9A;{®CALL FAR ????h:????h¯,88+}
 ciCBW=$98;{®CBW¯,88+}
 ciCC=$CC;{®INT 03h¯(Code Sp‚cial CCh),88+}
 ciCLC=$F8;{®CLC¯,88+}
 ciCLD=$FC;{®CLD¯,88+}
 ciCLI=$FA;{®CLI¯,88+}
 ciCMC=$F5;{®CMC¯,88+}
 ciCmpAL_=$3C;{®CMP AL,??h¯,286+}
 ciCmpAX_=$3D;{®CMP AX,????h¯,286+}
 ciCmpSB=$A6;{®CMPSB¯,88+}
 ciCmpSW=$A7;{®CMPSW¯,88+}
 ciCS=$2E;{®CS¯,88+}
 ciCWD=$99;{®CWD¯,88+}
 ciDAA=$27;{®DAA¯,88+}
 ciDAS=$2F;{®DAS¯,88+}
 ciDecAX=$48;{®DEC AX¯,88+}
 ciDecBP=$4D;{®DEC BP¯,88+}
 ciDecBX=$4B;{®DEC BX¯,88+}
 ciDecCX=$49;{®DEC CX¯,88+}
 ciDecDI=$4F;{®DEC DI¯,88+}
 ciDecDX=$4A;{®DEC DX¯,88+}
 ciDecSI=$4E;{®DEC SI¯,88+}
 ciDecSP=$4C;{®DEC SP¯,88+}
 ciDS=$3E;{®DS¯,88+}
 ciES=$26;{®ES¯,88+}
 ciFS=$64;{®FS¯,386+}
 ciGS=$65;{®GS¯,386+}
 ciHLT=$F4;{®HLT¯,88+}
 ciIncAX=$40;{®INC AX¯,88+}
 ciIncBP=$45;{®INC BP¯,88+}
 ciIncBX=$43;{®INC BX¯,88+}
 ciIncCX=$41;{®INC CX¯,88+}
 ciIncDI=$47;{®INC DI¯,88+}
 ciIncDX=$42;{®INC DX¯,88+}
 ciIncSI=$46;{®INC SI¯,88+}
 ciIncSP=$44;{®INC SP¯,88+}
 ciInsB=$6C;{®INSB¯,88+}
 ciInsW=$6D;{®INSW¯,88+}
 ciInt=$CD;{®INT ??h¯,88+}
 ciIntO=$CE;{®INTO¯,88+}
 ciIRet=$CF;{®IRET¯,88+}
 ciJBE=$76;{®JBE ?¯,88+}
 ciJC=$72;{®JC ?¯,88+}
 ciJG=$7E;{®JG ?¯,88+}
 ciJL=$7C;{®JL ?¯,88+}
 ciJMP_Word=$E9;{®JMP ????¯,88+}
 ciJNBE=$77;{®JNBE ?¯,88+}
 ciJNC=$73;{®JNC ?¯,88+}
 ciJNG=$7F;{®JNG ?¯,88+}
 ciJNL=$7D;{®JNL ?¯,88+}
 ciJNO=$71;{®JNO ?¯,88+}
 ciJNP=$7B;{®JNP ?¯,88+}
 ciJNS=$79;{®JNS ?¯,88+}
 ciJNZ=$75;{®JNZ ?¯,88+}
 ciJO=$70;{®JO ?¯,88+}
 ciJP=$7A;{®JP ?¯,88+}
 ciJS=$78;{®JS ?¯,88+}
 ciJZ=$74;{®JZ ?¯,88+}
 ciLAHF=$9F;{®LAHF¯,88+}
 ciLAR=$020F;{®LAR¯,386+}
 ciLeave=$C9;{®LEAVE¯,286+}
 ciLDS=$C5;{®LDS reg,mem¯,88+}
 ciLES=$C4;{®LES reg,mem¯,88+}
 ciLFS=$B40F;{®LFS reg,mem¯,386+}
 ciLGS=$B50F;{®LGS reg,mem¯,386+}
 ciLock=$F0;{®LOCK ?¯,88+}
 ciLODSB=$AC;{®LODSB¯,88+}
 ciLODSD=$AD66;{®LODSD¯,386+}
 ciLODSW=$AD;{®LODSW¯,88+}
 ciLSL=$030F;{®LSL ?¯,386+}
 ciLSS=$B20F;{®LSS reg,mem¯,386+}
 ciMovAL_=$A0;{®MOV AL,[addr]¯,286+}
 ciMovAL_Byte=$B0;{®MOV AL,??¯,88+}
 ciMovAX_=$A1;{®MOV AX,[addr]¯,286+}
 ciMovAX_Word=$B8;{®MOV AX,????¯, 88+}
 ciMovAH_AL=$E08A;{®MOV AH,AL¯,88+}
 ciMovBP_SP=$EC8B;{®MOV BP,SP¯,88+}
 ciMovBX_CX=$D98B;{®MOV BX,CX¯,88+}
 ciMovCX_BX=$CB8B;{®MOV CX,BX¯,88+}
 ciMovDX_Word=$BA;{®MOV DX,????¯,88+}
 ciMovEAX_ES_DI=$058B6626;{®MOV EAX,ES:[DI]¯,386+}
 ciMovES_DI_EAX=$05896626;{®MOV ES:[DI],EAX¯,386+}
 ciMovSB=$A4;{®MOVSB¯,88+}
 ciMovSD=$A566;{®MOVSD¯,386+}
 ciMovSW=$A5;{®MOVSW¯,88+}
 ciNOP=$90;{®NOP¯,88+}
 ciOutDX_AL=$EE;{®OUT DX,AL¯,88+}
 ciOutDX_AX=$EF;{®OUT DX,AX¯,88+}
 ciOutSB=$6E;{®OUTSB¯,286+}
 ciOutSD=$6F66;{®OUTSD¯,386+}
 ciOutSW=$6F;{®OUTSW¯,286+}
 ciPopAX=$58;{®POP AX¯,88+}
 ciPopBP=$5D;{®POP BP¯,88+}
 ciPopBX=$5B;{®POP BX¯,88+}
 ciPopCX=$59;{®POP CX¯,88+}
 ciPopDX=$5A;{®POP DX¯,88+}
 ciPopDI=$5F;{®POP DI¯,88+}
 ciPopDS=$1F;{®POP DS¯,88+}
 ciPopEAX=$5866;{®POP EAX¯,386+}
 ciPopEBX=$5B66;{®POP EBX¯,386+}
 ciPopECX=$5966;{®POP ECX¯,386+}
 ciPopEDI=$66+(ciPopDI shl 8);{®PUSH EDI¯,386+}
 ciPopEDX=$5A66;{®POP EDX¯,386+}
 ciPopFS=$A10F;{®PUSH FS¯,386+}
 ciPopGS=$A90F;{®PUSH GS¯,386+}
 ciPopES=$07;{®POP ES¯,88+}
 ciPopSI=$5E;{®POP SI¯,88+}
 ciPopSP=$5C;{®POP SP¯,88+}
 ciPopSS=$17;{®POP SS¯,88+}
 ciPopA=$61;{®POPA¯,286+}
 ciPopF=$9D;{®POPF¯,88+}
 ciPushA=$60;{®PUSHA¯,286+}
 ciPushAX=$50;{®PUSH AX¯,88+}
 ciPushBP=$55;{®PUSH BP¯,88+}
 ciPushBX=$53;{®PUSH BX¯,88+}
 ciPushCS=$0E;{®PUSH CS¯,88+}
 ciPushCX=$51;{®PUSH CX¯,88+}
 ciPushDI=$57;{®PUSH DI¯,88+}
 ciPushDS=$1E;{®PUSH DS¯,88+}
 ciPushDX=$52;{®PUSH DX¯,88+}
 ciPushEAX=$5066;{®PUSH EAX¯,386+}
 ciPushEBX=$5366;{®PUSH EBX¯,386+}
 ciPushECX=$5166;{®PUSH ECX¯,386+}
 ciPushEDX=$5266;{®PUSH EDX¯,386+}
 ciPushEDI=$66+(ciPushDI shl 8);{®PUSH EDI¯,386+}
 ciPushES=$06;{®PUSH ES¯,88+}
 ciPushFS=$A00F;{®PUSH FS¯,386+}
 ciPushGS=$A80F;{®PUSH GS¯, 386+}
 ciPushMemB=$6A;{®PUSH ??¯, 286+}
 ciPushSI=$56;{®PUSH SI¯,88+}
 ciPushSP=$54;{®PUSH SP¯,88+}
 ciPushSS=$16;{®PUSH SS¯,88+}
 ciPushF=$9C;{®PUSHF¯,88+}
 ciRepNZ=$F2;{®REPNZ ?¯,88+}
 ciRep=$F3;{®REP ?¯,88+}
 ciRetF=$CB;{®RETF¯,88+}
 ciRetN=$C3;{®RETN¯,88+}
 ciRet=ciRetN;{®RETN¯ou®RETF¯,88+}
 ciSAHF=$9E;{®SAHF¯,88+}
 ciSbbAL_=$1C;{®SBB AL,??h¯,286+}
 ciSbbAX_=$1D;{®SBB AX,????h¯,286+}
 ciSCASB=$AE;{®SCASB¯,88+}
 ciSCASD=$AF66;{®SCASS¯,386+}
 ciSCASW=$AF;{®SCASW¯,88+}
 ciSHR_AX_=$E8C1;{®SHR AX,?¯,88+}
 ciSHR_CX_=$E9C1;{®SHR CX,?¯,88+}
 ciSubAL_=$2C;{ ®SUB AL,??h¯,286+}
 ciSubAX_=$2D;{®SUB AX,????h¯,286+}
 ciSS=$36;{®SS¯,88+}
 ciSTC=$F9;{®STC¯,88+}
 ciSTD=$FD;{®STD¯,88+}
 ciSTI=$FB;{®STI¯,88+}
 ciSTOSB=$AA;{®STOSB¯,88+}
 ciSTOSD=$AB66;{®STOSD¯,386+}
 ciSTOSW=$AB;{®STOSW¯,88+}
 ciXchgAXnBP=$95;{®XCHG AX,BP¯,88+}
 ciXchgAXnBX=$93;{®XCHG AX,BX¯,88+}
 ciXchgAXnCX=$91;{®XCHG AX,CX¯,88+}
 ciXchgAXnDI=$97;{®XCHG AX,DI¯,88+}
 ciXchgAXnDX=$92;{®XCHG AX,DX¯,88+}
 ciXchgAXnSI=$96;{®XCHG AX,SI¯,88+}
 ciXchgAXnSP=$94;{®XCHG AX,SP¯,88+}
 ciXchgEAX_DS_SI=$048B663E;{®XCHG EAX,DS:[SI]¯,386+}
 ciXlat=$D7;{®XLAT¯,88+}
 ciXOR_=$81;{®XOR ?,?¯,88+}
 ciXOR_AL_=$34;{®XOR AL,??h¯,286+}
 ciXOR_AX_=$35;{®XOR AX,????h¯,286+}
 
Const
 {Constante de type de disque (Interruption 13h)}
 dtNoDrive=0;{Lecteur introuvable}
 dtDD525=1;{Lecteur: 5,25" Double Densit‚}
 dtHD525=2;{Lecteur: 5,25" Haute Densit‚}
 dtDD35=3;{Lecteur: 3,5" Double Densit‚}
 dtHD35=4;{Lecteur: 3,5" Haute Densit‚}

 {Officieusement...}
 dTryMax=5;{Nombre d'essais maximal}
 
Type
 {Structure pour une piste double densit‚}
 DdptType=Array[0..10]of Byte;
 DdptPtr=^DdptType;
 {ParamŠtres physiques de formatage}
 PhysDataType=Record
  Faces,        {Nombre de faces demand‚}
  Tracks,       {Nombre Pistes par Face}
  Sec:Byte;     {Secteurs par Piste}
  DDPT:DdptPtr; {Pointeur sur table paramŠtres du lecteur de disquette}
 End;
 
Type
 {ParamŠtres de formatage DOS}
 LogDataType=Record
  Media,Cluster,{Octet de support/Nombre Secteurs par Cluster}
  FAT,RootSize:Byte;{Nombre Secteurs pour la FAT/Entr‚es dans le r‚pertoire racine}
 End;

 {Structure d'un tampon d'une piste logique de format DOS}
 TrackBufType=Array[1..18,0..511]of Byte;{Tampon par piste}

 (*Fonctions et Procedures:*)
Procedure DskReset;Assembler;ASM
 MOV AH,00h
 MOV DL,0
 INT 13h
END;

Function GetDrvType(Drive:Byte):Byte;Assembler;ASM
 MOV AH,08h
 MOV DL,Drive
 INT 13h
 JNC @Ok
 MOV BL,dtDD525
@Ok:
 XCHG AX,BX
END;

Const
  fCarry=$0001;
  fParity=$0004;
  fAuxiliary=$0010;
  fZero=$0040;
  fSign=$0080;
  fOverflow=$0800;

Const

  MaskBoot:Array[1..102]of Byte=
   ($EB,$35,                { 0000   JMP 0037        }
    ciNOP,                  { 0002   NOP             }
  {-- Donnees des BPB --------------------------------}
    $50,$43,$2D,$4D,$41,$4C,$54,$45,
    $00,$00,$00,$01,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,
  {-- Programme de chargement ----------------------}
    ciCLI,                 { 0037   CLI             }
    $B8,$30,$00,           { 0038   MOV     AX,0030 }
    $8E,$D0,               { 003B   MOV     SS,AX   }
    $BC,$FC,$00,           { 003D   MOV     SP,00FC }
    ciSTI,                 { 0040   STI             }
    ciPushCS,              { 0041   PUSH    CS      }
    ciPopDS,               { 0042   POP     DS      }
    $BE,$66,$7C,           { 0043   MOV     SI,7C66 }
    $B4,$0E,               { 0046   MOV     AH,0E   }
    ciCLD,                 { 0048   CLD             }
    ciLODSB,               { 0049   LODSB           }
    $0A,$C0,               { 004A   OR      AL,AL   }
    $74,$04,               { 004C   JZ      0052    }
    ciInt,$10,             { 004E   INT     10      }
    $EB,$F7,               { 0050   JMP     0049    }
    $B4,$01,               { 0052   MOV     AH,01   }
    ciInt,$16,             { 0054   INT     16      }
    $74,$06,               { 0056   JZ      005E    }
    $B4,$00,               { 0058   MOV     AH,00   }
    ciInt,$16,             { 005A   INT     16      }
    $EB,$F4,               { 005C   JMP     0052    }
    $B4,$00,               { 005E   MOV     AH,00   }
    ciInt,$16,             { 0060   INT     16      }
    $33,$D2,               { 0062   XOR     DX,DX   }
    ciInt,$19);            { 0064   INT     19      }

 BootMsg:String=#13#10'FORMAT - corail'#13#10+
       #13#10'Disquette non systeme ou defectueuse!'#13#10+
       'Veuillez changer de disquette et taper une touche'#13#10;

Var AktDrv:Byte;       { Numero de l'unite de disque a formater 0, 1 }
    AktDrvType:Byte;   { Type du lecteur de disquettes courant }
    PData:PhysDataType;{ Informations physiques de formatage }
    LData:LogDataType; { Informations logiques de formatage }
    AncDDPT:Pointer;   { Pointeur sur ancien DDPT }
    Ok:Boolean;        { Drapeau pour execution du programme }
    EndCode:Word;      { Valeur retournee au process appele }
    Param:String;      { pour evaluation de la ligne de commande }

Function StrToUpper(S:String):String;
Var
 I:Byte;
 SLen:Byte Absolute S;
Begin
 For I:=1to(SLen)do S[I]:=UpCase(S[I]);
 StrToUpper:=S;
End;

Function Get4matParam(S:String;DrvType:Byte;Var PData:PhysDataType;Var LData:LogDataType):Boolean;
Const
 DDPT360:DdptType=($DF,$02,$25,$02,$09,$2A,$FF,$50,$F6,$0F,$08);
 DDPT1200:DdptType=($DF,$02,$25,$02,$0F,$1B,$FF,$54,$F6,$0F,$08);
 DDPT720:DdptType=($DF,$02,$25,$02,$09,$2A,$FF,$50,$F6,$0F,$08);
 DDPT1440:DdptType=($DF,$02,$25,$02,$12,$1B,$FF,$6C,$F6,$0F,$08);
 LOG360:LogDataType=(Media:$FD;Cluster:2;FAT:2;RootSize:$70);
 LOG1200:LogDataType=(Media:$F9;Cluster:1;FAT:7;RootSize:$E0);
 LOG720:LogDataType=(Media:$F9;Cluster:2;FAT:3;RootSize:$70);
 LOG1440:LogDataType=(Media:$F0;Cluster:1;FAT:9;RootSize:$E0);
 PHYS360:PhysDataType=(Faces:2;Tracks:40;Sec:9;DDPT:@DDPT360);
 PHYS1200:PhysDataType=(Faces:2;Tracks:80;Sec:15; DDPT:@DDPT1200);
 PHYS1440:PhysDataType=(Faces:2;Tracks:80;Sec:18; DDPT:@DDPT1440);
 PHYS720:PhysDataType=(Faces:2;Tracks:80;Sec:9;DDPT:@DDPT720);
Begin
 Get4matParam:=true;
 If S='1200'Then
  If(DrvType=dtHD525)Then Begin PData:=PHYS1200;LData:=LOG1200;End
		     Else Get4matParam:=false
  Else
 If S='360'Then
  If(DrvType=dtHD525)or(DrvType=dtDD525)Then Begin PData:=PHYS360; LData:=LOG360; End
					Else Get4matParam:=false
  Else
 If S='1440'Then
  If(DrvType=dtHD35)Then Begin
   PData:=PHYS1440;
   LData:=LOG1440;
  End
   Else
  Get4matParam:=false
  Else
 If S='720'Then
 Begin
  If StrToUpper(ParamStr(3))='/F'Then Begin
   PData:=PHYS720;
   LData:=LOG720;
  End
   Else
  If(DrvType=dtHD35)or(DrvType=dtDD35)Then Begin
   PData:=PHYS720;
   LData:=LOG720;
  End
   Else
  Get4matParam:=False
 End
  Else
 Get4matParam:=false;
End;

Procedure InitDsk(Drive:Byte;PData:PhysDataType);
Var
 _CH,_CL:Byte;
Begin
 _CH:=PData.Tracks-1; _CL:=PData.Sec;
 ASM
  MOV AH,$18;
  MOV CL,_CL;
  MOV CH,_CH;
  MOV DL,Drive;
  INT $13;
 END;
End;

Function FormatTrack(Drv,Face,Track,Nm:Byte):Byte;
Type
 FormatTyp=Record
  DTrack,DFace,DI,DLen:Byte;
 End;
Var
 Regs:Registers;
 AreaData:Array[1..18]of FormatTyp;
 I,Try:Byte;
Begin
 For I:=1to(Nm)do With AreaData[I]do Begin
  DTrack:=Track;DFace:=Face;DI:=I;DLen:=2;
 End;
 Try:=dTryMax;
 Repeat
  With Regs do Begin
   ah:=5;
   al:=Nm;
   es:=Seg(AreaData);
   bx:=Ofs(AreaData);
   dh:=Face;
   dl:=Drv;
   ch:=Track;
  End;
  Intr($13,Regs);
  If Regs.flags and fcarry=1Then DskReset;
  Dec(Try);
 Until(Regs.flags and fcarry=0)or(Try=0);
 Formattrack:=Regs.ah;
End;

Function VerifyTrack(Lecteur,Face,Piste,Secteurs:Byte):Byte;
Var
 Try:Byte;
 Regs:Registers;
 TamponPiste:TrackBufType;
Begin
 Try:=dTryMax;
 Repeat
  With Regs do Begin
   ah:=$04;              { Numero de fonction pour appel interruption }
   al:=Secteurs;         { Nombre Secteurs par Piste }
   ch:=Piste;            { Numero de Piste }
   cl:=1;                { Commencer par le secteur 1 }
   dl:=Lecteur;          { Numero de lecteur }
   dh:=Face;             { Numero de la face }
   es:=Seg(TamponPiste); { Adresse du tampon }
   bx:=Ofs(TamponPiste);
  End;
  Intr($13,Regs);
  If Regs.flags and fcarry=1Then DskReset;
  Dec(Try);
 Until(Regs.flags and fcarry=0)or(Try=0);
 VerifyTrack:=Regs.ah;
End;

Function WriteTrack(Lecteur,Face,Piste,Start,Nombre:Byte;Var Buffer):Byte;
Var
 Essais:Byte;
 Regs:Registers;
Begin
 essais:=dTryMax;
 Repeat
  With Regs do Begin
   ah:=$03;        { Numero de fonction pour appel interruption }
   al:=Nombre;     { Nombre Secteurs par Piste }
   ch:=Piste;      { Numero de Piste }
   cl:=Start;      { Commencer par le secteur 1 }
   dl:=Lecteur;    { Numero de lecteur }
   dh:=Face;       { Numero de la face }
   es:=Seg(Buffer);{ Adresse pour tampon }
   bx:=Ofs(Buffer);
  End;
  Intr($13,Regs);
  If Regs.flags and fcarry=1Then DskReset;
  Dec(essais);
 Until(Regs.flags and fcarry=0)or(Essais=0);
 WriteTrack:=Regs.ah;
End;

Function Phys4mat(Drv:Byte;PData:PhysDataType;Verify:Boolean):Boolean;
Var
 Try,T,F,Status:Byte;
Begin
 For T:=0to PData.Tracks-1do For F:=0to PData.Faces-1do Begin
  Write(#13'Piste : ',T:2,'  Face : ',F:2);
  Try:=dTryMax;
  Repeat
   Status:=FormatTrack(Drv,F,T,PData.Sec);
   If Status=3Then Begin
    Phys4mat:=false;
    WriteLn;
    WriteLn('Disquette protegee contre l''ecriture');
    Exit;
   End;
   If(Status=0)and Verify Then Status:=VerifyTrack(Drv,F,T,PData.Sec);
   Dec(Try);
   If Status>0Then DskReset;
  Until(Status=0)or(Try=0);
  If Status>0Then Begin
   Phys4mat:=false;
   WriteLn;
   WriteLn('Erreur de piste ?');
   Exit;
  End;
 End;
 Phys4mat:=true;
End;

Function Logical4mat(Drive:Byte;PData:PhysDataType;LData:LogDataType):Boolean;
Var
 Status:Byte;
 NmSec:Word;
 I,AktSec,AktSide,AktTrack:Byte;
 Nm:Integer;
 TrackBuf:TrackBufType;
Begin
 FillChar(TrackBuf,Word(PData.Sec)*512,0); { Vide tampon }
  { Secteur de demarrage: Partie fixe }
 System.Move(Maskboot,TrackBuf,102);
 System.Move(BootMsg[1],TrackBuf[1,103],Byte(BootMsg[0]));
 TrackBuf[1,511]:=$55;
 TrackBuf[2,0]:=$AA;
  { Secteur de demarrage: Partie variable }
 NmSec:=PData.Tracks*PData.Sec*Pdata.Faces;
 TrackBuf[1,12]:=Lo(512);
 TrackBuf[1,13]:=Hi(512);
 TrackBuf[1,14]:=LData.Cluster;  { Longueur de l'unite d'allocation }
 TrackBuf[1,18]:=LData.RootSize; { Nombre Entrees dans répertoires }
 TrackBuf[1,20]:=lo(NmSec);      { Nombre total de secteur }
 TrackBuf[1,21]:=hi(NmSec);      { sur la disquette }
 TrackBuf[1,22]:=LData.Media;    { Descripteur support }
 TrackBuf[1,23]:=LData.FAT;      { Longueur des FAT }
 TrackBuf[1,25]:=PData.Sec;      { Secteurs par piste }
 TrackBuf[1,27]:=PData.Faces;    { Nombre de faces }
  { Creer FAT et sa copie (contient 00) }
 TrackBuf[2,1]:=LData.Media;
 TrackBuf[2,2]:=$FF;
 TrackBuf[2,3]:=$FF;
 TrackBuf[LData.FAT+2,1]:=LData.Media;
 TrackBuf[LData.FAT+2,2]:=$FF;
 TrackBuf[LData.FAT+2,3]:=$FF;
 Status:=WriteTrack(Drive,0,0,1,PData.Sec,TrackBuf);
 If Status<>0Then Logical4mat:=false
  else
 Begin
  FillChar(TrackBuf,512,0);
  AktSec:=PData.Sec; AktTrack:=0; AktSide:=0;
  Nm:=LData.FAT*2+(LData.Rootsize*32div 512)+1-PData.Sec; I:=1;
  Repeat
   Inc(AktSec);
   If(AktSec>PData.Sec)Then Begin
    AktSec:=1; Inc(AktSide);
    If(AktSide=PData.Faces)Then Begin
     AktSide:=0;
     Inc(AktTrack);
    End;
   End;
   Status:=WriteTrack(Drive,AktSide,AktTrack,AktSec,1,TrackBuf);
   Inc(i);
  Until(i>Nm)or(Status<>0);
  Logical4mat:=Status=0;
 End;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('FORMAT - Cette commande permet de formater un unite de disquette.');
  WriteLn;
  Writeln('Syntaxe: FORMAT [A:|B:] [360|720|1200|1440] [NV] [/F]');
  WriteLn;
  Writeln('         NV  Pas de verification');
  Writeln('         /F  Force a utiliser ce format');
 End
  Else
 If ParamCount>=1Then Begin
  Param:=ParamStr(1);
  AktDrv:=Byte(UpCase(Param[1]))-65;
  AktDrvType:=GetDrvType(AktDrv);
  If AktDrvType>0Then Begin
   If Get4matParam(ParamStr(2),AktDrvType,PData,LData)Then Begin
    InitDsk(AktDrv,PData);
    GetIntVec($1E,AncDDPT);
    SetIntVec($1E,PData.DDPT);
    Param:=ParamStr(3);
    Ok:=Phys4mat(AktDrv,PData,UpCase(Param[1])<>'N');
    If(Ok)Then Begin
     WriteLn;
     Writeln('Ecriture du secteur de demarrage et des FAT ');
     Ok:=Logical4mat(AktDrv,PData,LData)
    End;
    If(Ok)Then Begin
     WriteLn;
     WriteLn('Formatage S.V.P.');
    End
     else
    Begin
     WriteLn;
     WriteLn('Une erreur a interrompu le formatage');
     Halt(1);
    End;
    SetIntVec($1E,AncDDPT);
   End
    else
   Begin
    WriteLn('Le format demande ne peut etre utilise sur cette unite de disque !');
    Halt(2);
   End
  End
   else
  Begin
   WriteLn('Le lecteur de disquettes demande n''existe pas');
   Halt(3);
  End
 End
  else
 WriteLn('Parametre requis !')
END.