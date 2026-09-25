{ @author: Sylvain Maltais (support@gladir.com)
 @created: 2022
 @website(https://www.gladir.com/corail)
 @website(https://www.gladir.com/dev-cools)
 @abstract(Target: Turbo Pascal, Free Pascal) }

Program FORMAT;

{$A-,F-,O-}

Uses DOS;

Const
 MaxFormatFATBytes=65520;
 FS_AUTO=0;
 FS_FAT12=12;
 FS_FAT16=16;
 FS_FAT32=32;
 FS_EXFAT=40;
 FS_NTFS=50;
 FS_HPFS=60;
 DOS_MSDOS=0;
 DOS_PCDOS=1;
 DOS_DRDOS=2;
 DOS_FREEDOS=3;
 DOS_RXDOS=4;
 DOS_WIN95=5;
 DOS_PTSDOS=6;
 DOS_OS2=7;
 DOS_WINNT=8;
 {Adresse d'assembleur pour le micro-processeur Intel (Cpu Intel)}
 ciBXnSI=$00;
{"[BX+SI]",88+}
 ciBXnDI=$01;
{"[BX+DI]",88+}
 ciBPnSI=$02;
{"[BP+SI]",88+}
 ciBPnDI=$03;
{"[BP+DI]",88+}
 ciSI=$04;
{"[SI]",88+}
 ciDI=$05;
{"[DI]",88+}
 ciBP=$06;
{"[BP]",88+}
 ciBX=$07;
{"[BX]",88+}
 {Instruction d'assembleur pour le micro-processeur Intel (Cpu Intel)}
 ciAAA=$37;
{"AAA",88+}
 ciAAD_=$D5;
{"AAD",88+}
 ciAAM_=$D4;
{"AAM",88+}
 ciAAS=$3F;
{"AAS",88+}
 ciAdcAL_=$14;
{"ADC AL,??h",286+}
 ciAdcAX_=$15;
{"ADC AX,????h",286+}
 ciAddAL_=$04;
{"ADD AL,??h",286+}
 ciAddAX_=$05;
{"ADD AX,????h",286+}
 ciAndAL_=$24;
{"AND AL,??h",286+}
 ciAndAX_=$25;
{"AND AX,????h",286+}
 ciCallFarAbs=$9A;
{"CALL FAR ????h:????h",88+}
 ciCBW=$98;
{"CBW",88+}
 ciCC=$CC;
{"INT 03h"(Code Special CCh),88+}
 ciCLC=$F8;
{"CLC",88+}
 ciCLD=$FC;
{"CLD",88+}
 ciCLI=$FA;
{"CLI",88+}
 ciCMC=$F5;
{"CMC",88+}
 ciCmpAL_=$3C;
{"CMP AL,??h",286+}
 ciCmpAX_=$3D;
{"CMP AX,????h",286+}
 ciCmpSB=$A6;
{"CMPSB",88+}
 ciCmpSW=$A7;
{"CMPSW",88+}
 ciCS=$2E;
{"CS",88+}
 ciCWD=$99;
{"CWD",88+}
 ciDAA=$27;
{"DAA",88+}
 ciDAS=$2F;
{"DAS",88+}
 ciDecAX=$48;
{"DEC AX",88+}
 ciDecBP=$4D;
{"DEC BP",88+}
 ciDecBX=$4B;
{"DEC BX",88+}
 ciDecCX=$49;
{"DEC CX",88+}
 ciDecDI=$4F;
{"DEC DI",88+}
 ciDecDX=$4A;
{"DEC DX",88+}
 ciDecSI=$4E;
{"DEC SI",88+}
 ciDecSP=$4C;
{"DEC SP",88+}
 ciDS=$3E;
{"DS",88+}
 ciES=$26;
{"ES",88+}
 ciFS=$64;
{"FS",386+}
 ciGS=$65;
{"GS",386+}
 ciHLT=$F4;
{"HLT",88+}
 ciIncAX=$40;
{"INC AX",88+}
 ciIncBP=$45;
{"INC BP",88+}
 ciIncBX=$43;
{"INC BX",88+}
 ciIncCX=$41;
{"INC CX",88+}
 ciIncDI=$47;
{"INC DI",88+}
 ciIncDX=$42;
{"INC DX",88+}
 ciIncSI=$46;
{"INC SI",88+}
 ciIncSP=$44;
{"INC SP",88+}
 ciInsB=$6C;
{"INSB",88+}
 ciInsW=$6D;
{"INSW",88+}
 ciInt=$CD;
{"INT ??h",88+}
 ciIntO=$CE;
{"INTO",88+}
 ciIRet=$CF;
{"IRET",88+}
 ciJBE=$76;
{"JBE ?",88+}
 ciJC=$72;
{"JC ?",88+}
 ciJG=$7E;
{"JG ?",88+}
 ciJL=$7C;
{"JL ?",88+}
 ciJMP_Word=$E9;
{"JMP ????",88+}
 ciJNBE=$77;
{"JNBE ?",88+}
 ciJNC=$73;
{"JNC ?",88+}
 ciJNG=$7F;
{"JNG ?",88+}
 ciJNL=$7D;
{"JNL ?",88+}
 ciJNO=$71;
{"JNO ?",88+}
 ciJNP=$7B;
{"JNP ?",88+}
 ciJNS=$79;
{"JNS ?",88+}
 ciJNZ=$75;
{"JNZ ?",88+}
 ciJO=$70;
{"JO ?",88+}
 ciJP=$7A;
{"JP ?",88+}
 ciJS=$78;
{"JS ?",88+}
 ciJZ=$74;
{"JZ ?",88+}
 ciLAHF=$9F;
{"LAHF",88+}
 ciLAR=$020F;
{"LAR",386+}
 ciLeave=$C9;
{"LEAVE",286+}
 ciLDS=$C5;
{"LDS reg,mem",88+}
 ciLES=$C4;
{"LES reg,mem",88+}
 ciLFS=$B40F;
{"LFS reg,mem",386+}
 ciLGS=$B50F;
{"LGS reg,mem",386+}
 ciLock=$F0;
{"LOCK ?",88+}
 ciLODSB=$AC;
{"LODSB",88+}
 ciLODSD=$AD66;
{"LODSD",386+}
 ciLODSW=$AD;
{"LODSW",88+}
 ciLSL=$030F;
{"LSL ?",386+}
 ciLSS=$B20F;
{"LSS reg,mem",386+}
 ciMovAL_=$A0;
{"MOV AL,[addr]",286+}
 ciMovAL_Byte=$B0;
{"MOV AL,??",88+}
 ciMovAX_=$A1;
{"MOV AX,[addr]",286+}
 ciMovAX_Word=$B8;
{"MOV AX,????", 88+}
 ciMovAH_AL=$E08A;
{"MOV AH,AL",88+}
 ciMovBP_SP=$EC8B;
{"MOV BP,SP",88+}
 ciMovBX_CX=$D98B;
{"MOV BX,CX",88+}
 ciMovCX_BX=$CB8B;
{"MOV CX,BX",88+}
 ciMovDX_Word=$BA;
{"MOV DX,????",88+}
 ciMovEAX_ES_DI=$058B6626;
{"MOV EAX,ES:[DI]",386+}
 ciMovES_DI_EAX=$05896626;
{"MOV ES:[DI],EAX",386+}
 ciMovSB=$A4;
{"MOVSB",88+}
 ciMovSD=$A566;
{"MOVSD",386+}
 ciMovSW=$A5;
{"MOVSW",88+}
 ciNOP=$90;
{"NOP"»,88+}
 ciOutDX_AL=$EE;
{"OUT DX,AL",88+}
 ciOutDX_AX=$EF;
{"OUT DX,AX",88+}
 ciOutSB=$6E;
{"OUTSB",286+}
 ciOutSD=$6F66;
{"OUTSD",386+}
 ciOutSW=$6F;
{┬«OUTSW┬»,286+}
 ciPopAX=$58;
{┬«POP AX┬»,88+}
 ciPopBP=$5D;
{┬«POP BP┬»,88+}
 ciPopBX=$5B;
{┬«POP BX┬»,88+}
 ciPopCX=$59;
{┬«POP CX┬»,88+}
 ciPopDX=$5A;
{┬«POP DX┬»,88+}
 ciPopDI=$5F;
{┬«POP DI┬»,88+}
 ciPopDS=$1F;
{┬«POP DS┬»,88+}
 ciPopEAX=$5866;
{┬«POP EAX┬»,386+}
 ciPopEBX=$5B66;
{┬«POP EBX┬»,386+}
 ciPopECX=$5966;
{┬«POP ECX┬»,386+}
 ciPopEDI=$66+(ciPopDI shl 8);
{┬«PUSH EDI┬»,386+}
 ciPopEDX=$5A66;
{┬«POP EDX┬»,386+}
 ciPopFS=$A10F;
{┬«PUSH FS┬»,386+}
 ciPopGS=$A90F;
{┬«PUSH GS┬»,386+}
 ciPopES=$07;
{┬«POP ES┬»,88+}
 ciPopSI=$5E;
{┬«POP SI┬»,88+}
 ciPopSP=$5C;
{┬«POP SP┬»,88+}
 ciPopSS=$17;
{┬«POP SS┬»,88+}
 ciPopA=$61;
{┬«POPA┬»,286+}
 ciPopF=$9D;
{┬«POPF┬»,88+}
 ciPushA=$60;
{┬«PUSHA┬»,286+}
 ciPushAX=$50;
{┬«PUSH AX┬»,88+}
 ciPushBP=$55;
{┬«PUSH BP┬»,88+}
 ciPushBX=$53;
{┬«PUSH BX┬»,88+}
 ciPushCS=$0E;
{┬«PUSH CS┬»,88+}
 ciPushCX=$51;
{┬«PUSH CX┬»,88+}
 ciPushDI=$57;
{┬«PUSH DI┬»,88+}
 ciPushDS=$1E;
{┬«PUSH DS┬»,88+}
 ciPushDX=$52;
{┬«PUSH DX┬»,88+}
 ciPushEAX=$5066;
{┬«PUSH EAX┬»,386+}
 ciPushEBX=$5366;
{┬«PUSH EBX┬»,386+}
 ciPushECX=$5166;
{┬«PUSH ECX┬»,386+}
 ciPushEDX=$5266;
{┬«PUSH EDX┬»,386+}
 ciPushEDI=$66+(ciPushDI shl 8);
{┬«PUSH EDI┬»,386+}
 ciPushES=$06;
{┬«PUSH ES┬»,88+}
 ciPushFS=$A00F;
{┬«PUSH FS┬»,386+}
 ciPushGS=$A80F;
{┬«PUSH GS┬», 386+}
 ciPushMemB=$6A;
{┬«PUSH ??┬», 286+}
 ciPushSI=$56;
{┬«PUSH SI┬»,88+}
 ciPushSP=$54;
{┬«PUSH SP┬»,88+}
 ciPushSS=$16;
{┬«PUSH SS┬»,88+}
 ciPushF=$9C;
{┬«PUSHF┬»,88+}
 ciRepNZ=$F2;
{┬«REPNZ ?┬»,88+}
 ciRep=$F3;
{┬«REP ?┬»,88+}
 ciRetF=$CB;
{┬«RETF┬»,88+}
 ciRetN=$C3;
{┬«RETN┬»,88+}
 ciRet=ciRetN;
{┬«RETN┬»ou┬«RETF┬»,88+}
 ciSAHF=$9E;
{┬«SAHF┬»,88+}
 ciSbbAL_=$1C;
{┬«SBB AL,??h┬»,286+}
 ciSbbAX_=$1D;
{┬«SBB AX,????h┬»,286+}
 ciSCASB=$AE;
{┬«SCASB┬»,88+}
 ciSCASD=$AF66;
{┬«SCASS┬»,386+}
 ciSCASW=$AF;
{┬«SCASW┬»,88+}
 ciSHR_AX_=$E8C1;
{┬«SHR AX,?┬»,88+}
 ciSHR_CX_=$E9C1;
{┬«SHR CX,?┬»,88+}
 ciSubAL_=$2C;
{ ┬«SUB AL,??h┬»,286+}
 ciSubAX_=$2D;
{┬«SUB AX,????h┬»,286+}
 ciSS=$36;
{┬«SS┬»,88+}
 ciSTC=$F9;
{┬«STC┬»,88+}
 ciSTD=$FD;
{┬«STD┬»,88+}
 ciSTI=$FB;
{┬«STI┬»,88+}
 ciSTOSB=$AA;
{┬«STOSB┬»,88+}
 ciSTOSD=$AB66;
{┬«STOSD┬»,386+}
 ciSTOSW=$AB;
{┬«STOSW┬»,88+}
 ciXchgAXnBP=$95;
{┬«XCHG AX,BP┬»,88+}
 ciXchgAXnBX=$93;
{┬«XCHG AX,BX┬»,88+}
 ciXchgAXnCX=$91;
{┬«XCHG AX,CX┬»,88+}
 ciXchgAXnDI=$97;
{┬«XCHG AX,DI┬»,88+}
 ciXchgAXnDX=$92;
{┬«XCHG AX,DX┬»,88+}
 ciXchgAXnSI=$96;
{┬«XCHG AX,SI┬»,88+}
 ciXchgAXnSP=$94;
{┬«XCHG AX,SP┬»,88+}
 ciXchgEAX_DS_SI=$048B663E;
{┬«XCHG EAX,DS:[SI]┬»,386+}
 ciXlat=$D7;
{┬«XLAT┬»,88+}
 ciXOR_=$81;
{┬«XOR ?,?┬»,88+}
 ciXOR_AL_=$34;
{┬«XOR AL,??h┬»,286+}
 ciXOR_AX_=$35;
{┬«XOR AX,????h┬»,286+}

Const
 {Constante de type de disque (Interruption 13h)}
 dtNoDrive=0;
{Lecteur introuvable}
 dtDD525=1;
{Lecteur: 5,25" Double DensitΓÇÜ}
 dtHD525=2;
{Lecteur: 5,25" Haute DensitΓÇÜ}
 dtDD35=3;
{Lecteur: 3,5" Double DensitΓÇÜ}
 dtHD35=4;
{Lecteur: 3,5" Haute DensitΓÇÜ}
 {Officieusement...}
 dTryMax=5;
{Nombre d'essais maximal}

Type
 {Structure pour une piste double densitΓÇÜ}
 DdptType=Array[0..10]of Byte;
 DdptPtr=^DdptType;
 {Param┼átres physiques de formatage}
 PhysDataType=Record
 Faces,        {Nombre de faces demandΓÇÜ}
 Tracks,       {Nombre Pistes par Face}
 Sec:Byte;
     {Secteurs par Piste}
 DDPT:DdptPtr;
 {Pointeur sur table param┼átres du lecteur de disquette}
End;

Type
 {Param┼átres de formatage DOS}
 LogDataType=Record
 Media,Cluster,{Octet de support/Nombre Secteurs par Cluster}
 FAT,RootSize:Word;
{Nombre Secteurs pour la FAT/EntrΓÇÜes dans le rΓÇÜpertoire racine}
End;
 {Structure d'un tampon d'une piste logique de format DOS}
TrackBufType=Array[1..36,0..511]of Byte;
{Tampon par piste}
TFatBuffer=Array[0..MaxFormatFATBytes-1]of Byte;
PFatBuffer=^TFatBuffer;
TSectorBuffer=Array[0..511]of Byte;
 (*Fonctions et Procedures:*)
{$IFDEF FPC}

 Procedure DskReset;Begin
 End;

 Function GetCurrentDOSDrive:Byte;Begin
  GetCurrentDOSDrive:=0
 End;
{$ELSE}

 Procedure DskReset;
 Assembler;ASM
 MOV AH,00h
 MOV DL,0
 INT 13h
 End;

 Function GetCurrentDOSDrive:Byte;
 Assembler;ASM
 MOV AH,19h
 INT 21h
 XOR AH,AH
 End;
{$ENDIF}
{$IFDEF FPC}

 Function GetDrvType(Drive:Byte):Byte;Begin
 End;
{$ELSE}

 Function GetDrvType(Drive:Byte):Byte;
 Assembler;ASM
 MOV AH,08h
 MOV DL,Drive
 INT 13h
 JNC @Ok
 MOV BL,dtDD525
 @Ok:
 XCHG AX,BX
 End;
{$ENDIF}

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
 ciInt,$19);
            { 0064   INT     19      }
 BootMsg:String=#13#10'FORMAT - corail'#13#10+
 #13#10'Disquette non systeme ou defectueuse!'#13#10+
 'Veuillez changer de disquette et taper une touche'#13#10;
 DDPT360:DdptType=($DF,$02,$25,$02,$09,$2A,$FF,$50,$F6,$0F,$08);
 DDPT160:DdptType=($DF,$02,$25,$02,$08,$2A,$FF,$50,$F6,$0F,$08);
 DDPT180:DdptType=($DF,$02,$25,$02,$09,$2A,$FF,$50,$F6,$0F,$08);
 DDPT320:DdptType=($DF,$02,$25,$02,$08,$2A,$FF,$50,$F6,$0F,$08);
 DDPT1200:DdptType=($DF,$02,$25,$02,$0F,$1B,$FF,$54,$F6,$0F,$08);
 DDPT720:DdptType=($DF,$02,$25,$02,$09,$2A,$FF,$50,$F6,$0F,$08);
 DDPT1440:DdptType=($DF,$02,$25,$02,$12,$1B,$FF,$6C,$F6,$0F,$08);
 DDPT2880:DdptType=($DF,$02,$25,$02,$24,$1B,$FF,$54,$F6,$0F,$08);
 LOG160:LogDataType=(Media:$FE;
 Cluster:1;
 FAT:1;
 RootSize:$40);
 LOG180:LogDataType=(Media:$FC;
 Cluster:1;
 FAT:2;
 RootSize:$40);
 LOG320:LogDataType=(Media:$FF;
 Cluster:2;
 FAT:1;
 RootSize:$70);
 LOG360:LogDataType=(Media:$FD;
 Cluster:2;
 FAT:2;
 RootSize:$70);
 LOG1200:LogDataType=(Media:$F9;
 Cluster:1;
 FAT:7;
 RootSize:$E0);
 LOG720:LogDataType=(Media:$F9;
 Cluster:2;
 FAT:3;
 RootSize:$70);
 LOG1440:LogDataType=(Media:$F0;
 Cluster:1;
 FAT:9;
 RootSize:$E0);
 LOG2880:LogDataType=(Media:$F0;
 Cluster:2;
 FAT:9;
 RootSize:$E0);
 PHYS160:PhysDataType=(Faces:1;
 Tracks:40;
 Sec:8;
 DDPT:@DDPT160);
 PHYS180:PhysDataType=(Faces:1;
 Tracks:40;
 Sec:9;
 DDPT:@DDPT180);
 PHYS320:PhysDataType=(Faces:2;
 Tracks:40;
 Sec:8;
 DDPT:@DDPT320);
 PHYS360:PhysDataType=(Faces:2;
 Tracks:40;
 Sec:9;
 DDPT:@DDPT360);
 PHYS1200:PhysDataType=(Faces:2;
 Tracks:80;
 Sec:15;
 DDPT:@DDPT1200);
 PHYS1440:PhysDataType=(Faces:2;
 Tracks:80;
 Sec:18;
 DDPT:@DDPT1440);
 PHYS720:PhysDataType=(Faces:2;
 Tracks:80;
 Sec:9;
 DDPT:@DDPT720);
 PHYS2880:PhysDataType=(Faces:2;
 Tracks:80;
 Sec:36;
 DDPT:@DDPT2880);

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 AktDrv:Byte;
       { Numero de l'unite de disque a formater 0, 1 }
 AktDrvType:Byte;
   { Type du lecteur de disquettes courant }
 PData:PhysDataType;
{ Informations physiques de formatage }
 LData:LogDataType;
 { Informations logiques de formatage }
 AncDDPT:Pointer;
   { Pointeur sur ancien DDPT }
 Ok:Boolean;
        { Drapeau pour execution du programme }
 EndCode:Word;
      { Valeur retournee au process appele }
 Param:String;
      { pour evaluation de la ligne de commande }
 ImageName:String;
 FileImg:File;
 InFile:Boolean;
 HardDiskMode:Boolean;
 VolumeTotalSectors,VolumeHiddenSectors:LongInt;
 KS:Word;
 VolumeLabel:String;
 ForceFormat,NoVerify,UnconditionalFormat,QuickFormat,TracksSpecified,
 SectorsSpecified:Boolean;
 RequestedTracks,RequestedSectors:Byte;
 SystemTransfer:Boolean;
 ExistingQuickImage:Boolean;
 SingleSide,Format360In1200,EightSectors,BootReserve:Boolean;
 DosFamily,SysFileCount:Byte;
 SysFiles:Array[1..3]of String;
 RequestedFileSystem,ActiveFATBits:Byte;
 Confirmation:String;
 CreateImage:Boolean;
 ImageTypeSpecified:Boolean;
 CreateSizeMB:LongInt;
 AllocationSizeSpecified:Boolean;
 RequestedAllocationSize:LongInt;
 ImageDataOffset,ImageVolumeStart,ImageVirtualSectors:LongInt;
 ExFatFatOffset,ExFatFatLength,ExFatHeapOffset,ExFatClusterCount:LongInt;
 NtfsClusterSectors,NtfsClusterCount,NtfsMFTCluster,NtfsMFTMirrCluster:LongInt;
 ImageContainer:(IC_RAW,IC_VDI);

Function StrToUpper(S:String):String;
Var
 I:Byte;
 SLen:Byte Absolute S;
Begin
 For I:=1to(SLen)do S[I]:=UpCase(S[I]);
 StrToUpper:=S;
End;

Function SetVolumeLabel(S:String):Boolean;
Var
 I:Byte;
Begin
 SetVolumeLabel:=False;
 If Length(S)>11Then Begin
  WriteLn('Le nom de volume ne peut pas depasser 11 caracteres.');Exit
 End;
 If S=''Then Begin
  WriteLn('Le nom de volume ne peut pas etre vide.');Exit
 End;
 For I:=1to Length(S)do Begin
  If(Ord(S[I])<32)or(S[I]in['"','*','+',',','.','/',':',';','<','=','>','?','[','\',']',
  '|'])Then Begin
   WriteLn('Caractere interdit dans le nom de volume: ',S[I]);Exit
  End;
  S[I]:=UpCase(S[I])
 End;
 While Length(S)<11do S:=S+' ';
 VolumeLabel:=S;SetVolumeLabel:=True
End;

Procedure SetupSystemFamily(Family:Byte);Begin
 DosFamily:=Family;SysFiles[1]:='';SysFiles[2]:='';SysFiles[3]:='';
 Case Family of
 DOS_MSDOS,DOS_WIN95:
 Begin
  SysFiles[1]:='IO.SYS';SysFiles[2]:='MSDOS.SYS';SysFiles[3]:='COMMAND.COM';
  SysFileCount:=3
 End;
 DOS_PCDOS,DOS_DRDOS:
 Begin
  SysFiles[1]:='IBMBIO.COM';SysFiles[2]:='IBMDOS.COM';SysFiles[3]:='COMMAND.COM';
  SysFileCount:=3
 End;
 DOS_FREEDOS:
 Begin
  SysFiles[1]:='KERNEL.SYS';SysFiles[2]:='COMMAND.COM';SysFileCount:=2
 End;
 DOS_RXDOS:
 Begin
  SysFiles[1]:='RXDOSBIO.SYS';SysFiles[2]:='RXDOS.SYS';SysFiles[3]:='COMMAND.COM';
  SysFileCount:=3
 End;
 DOS_PTSDOS:
 Begin
  SysFiles[1]:='PTSBIO.SYS';SysFiles[2]:='PTSDOS.SYS';SysFiles[3]:='COMMAND.COM';
  SysFileCount:=3
 End;
 DOS_OS2:
 Begin
  SysFiles[1]:='OS2BOOT';SysFiles[2]:='OS2LDR';SysFiles[3]:='OS2KRNL';SysFileCount:=3
 End;
 DOS_WINNT:
 Begin
  SysFiles[1]:='NTLDR';SysFiles[2]:='NTDETECT.COM';SysFiles[3]:='BOOT.INI';SysFileCount:=3
 End
End
End;

Function ParseSystemFamily(S:String):Boolean;
Var
 U:String;
Begin
 U:=StrToUpper(S);ParseSystemFamily:=True;
 If(U='MS-DOS')or(U='MSDOS')or(U='MS')Then SetupSystemFamily(DOS_MSDOS)
 Else If(U='PC-DOS')or(U='PCDOS')or(U='PC')or(U='IBM')Then SetupSystemFamily(DOS_PCDOS)
 Else If(U='DR-DOS')or(U='DRDOS')or(U='DR')Then SetupSystemFamily(DOS_DRDOS)
 Else If(U='FREEDOS')or(U='FREE')or(U='FDOS')Then SetupSystemFamily(DOS_FREEDOS)
 Else If(U='RXDOS')or(U='RX')Then SetupSystemFamily(DOS_RXDOS)
 Else If(U='WIN95')or(U='WIN9X')or(U='W95')or(U='MSDOS7')or(U='MS-DOS7')
 Then  SetupSystemFamily(DOS_WIN95)
 Else If(U='PTS-DOS')or(U='PTSDOS')or(U='PTS')Then SetupSystemFamily(DOS_PTSDOS)
 Else If(U='OS/2')or(U='OS2')or(U='IBMOS2')Then SetupSystemFamily(DOS_OS2)
 Else If(U='NT')or(U='WINNT')or(U='WIN-NT')or(U='WIN2K')or(U='W2K')or
 (U='WINXP')or(U='XP')or(U='WIN2000')Then SetupSystemFamily(DOS_WINNT)
 Else ParseSystemFamily:=False
End;

Function SystemFamilyName:String;Begin
 Case DosFamily of
 DOS_MSDOS:SystemFamilyName:='MS-DOS';DOS_PCDOS:SystemFamilyName:='PC-DOS';
 DOS_DRDOS:SystemFamilyName:='DR-DOS';DOS_FREEDOS:SystemFamilyName:='FreeDOS';
 DOS_RXDOS:SystemFamilyName:='RxDOS';DOS_WIN95:SystemFamilyName:='Win95';
 DOS_PTSDOS:SystemFamilyName:='PTS-DOS';DOS_OS2:SystemFamilyName:='OS/2';
 DOS_WINNT:SystemFamilyName:='WinNT';Else SystemFamilyName:='?'
End
End;

Function ParseOptions(First:Integer;Var FormatSize:String):Boolean;
Var
 I,Code,NumericValue:Integer;
 CreateValue:LongInt;
 S,U,N:String;
Begin
 ParseOptions:=False;FormatSize:='';ForceFormat:=False;NoVerify:=False;VolumeLabel:='';
 UnconditionalFormat:=False;QuickFormat:=False;TracksSpecified:=False;RequestedTracks:=0;
 SectorsSpecified:=False;RequestedSectors:=0;SystemTransfer:=False;
 SingleSide:=False;Format360In1200:=False;EightSectors:=False;BootReserve:=False;
 SetupSystemFamily(DOS_MSDOS);
 CreateImage:=False;CreateSizeMB:=0;ImageContainer:=IC_RAW;ImageTypeSpecified:=False;
 AllocationSizeSpecified:=False;RequestedAllocationSize:=0;
 RequestedFileSystem:=FS_AUTO;ActiveFATBits:=12;
 For I:=First to ParamCount do Begin
  S:=ParamStr(I);U:=StrToUpper(S);
  If Copy(U,1,3)='/A:'Then Begin
   N:=Copy(U,4,255);Val(N,CreateValue,Code);
   If(Code<>0)or(CreateValue<512)or(CreateValue>32768)or
   ((CreateValue mod 512)<>0)or
   ((CreateValue and(CreateValue-1))<>0)Then Begin
    WriteLn('/A doit etre une puissance de deux entre 512 et 32768 octets.');Exit
   End;
   AllocationSizeSpecified:=True;RequestedAllocationSize:=CreateValue
  End Else If U='/CREATE'Then CreateImage:=True
  Else If Copy(U,1,8)='/CREATE:'Then Begin
   N:=Copy(U,9,255);
   If(Length(N)>0)and(N[Length(N)]='M')Then Delete(N,Length(N),1);
   Val(N,CreateValue,Code);
   If(Code<>0)or(CreateValue<1)or(CreateValue>2047)Then Begin
    WriteLn('La taille /CREATE doit etre comprise entre 1 et 2047 Mo.');Exit
   End;
   CreateImage:=True;CreateSizeMB:=CreateValue
  End Else If Copy(U,1,6)='/TYPE:'Then Begin
   N:=Copy(U,7,255);
   If N='RAW'Then ImageContainer:=IC_RAW
   Else If(N='VDI')or(N='VIRTUALBOX')Then ImageContainer:=IC_VDI
   Else
   Begin
    WriteLn('Type d''image inconnu: ',N);Exit
   End
   ;ImageTypeSpecified:=True
  End Else If Copy(U,1,4)='/FS:'Then Begin
   N:=Copy(U,5,255);
   If N='FAT'Then RequestedFileSystem:=FS_AUTO
   Else If N='FAT12'Then RequestedFileSystem:=FS_FAT12
   Else If N='FAT16'Then RequestedFileSystem:=FS_FAT16
   Else If N='FAT32'Then RequestedFileSystem:=FS_FAT32
   Else If N='EXFAT'Then RequestedFileSystem:=FS_EXFAT
   Else If N='NTFS'Then RequestedFileSystem:=FS_NTFS
   Else If N='HPFS'Then RequestedFileSystem:=FS_HPFS
   Else
   Begin
    WriteLn('Systeme de fichiers inconnu: ',N);Exit
   End
  End Else If Copy(U,1,3)='/V:'Then Begin
   If not SetVolumeLabel(Copy(S,4,255))Then Exit
  End Else If Copy(U,1,3)='/T:'Then Begin
   N:=Copy(S,4,255);Val(N,NumericValue,Code);
   If(Code<>0)or(NumericValue<1)or(NumericValue>255)Then Begin
    WriteLn('Le nombre de pistes doit etre compris entre 1 et 255.');Exit
   End;
   If TracksSpecified Then Begin
    WriteLn('Le nombre de pistes est indique plusieurs fois.');Exit
   End;
   TracksSpecified:=True;RequestedTracks:=NumericValue
  End Else If Copy(U,1,3)='/N:'Then Begin
   N:=Copy(S,4,255);Val(N,NumericValue,Code);
   If(Code<>0)or(NumericValue<1)or(NumericValue>36)Then Begin
    WriteLn('Le nombre de secteurs par piste doit etre compris entre 1 et 36.');Exit
   End;
   If SectorsSpecified Then Begin
    WriteLn('Le nombre de secteurs est indique plusieurs fois.');Exit
   End;
   SectorsSpecified:=True;RequestedSectors:=NumericValue
  End Else If U='/U'Then UnconditionalFormat:=True
  Else If U='/Q'Then QuickFormat:=True
  Else If U='/1'Then SingleSide:=True
  Else If U='/4'Then Begin
   If InFile or HardDiskMode Then Begin
    WriteLn('/4 est reserve aux unites de disquette.');Exit
   End;
   Format360In1200:=True
  End
  Else If U='/8'Then EightSectors:=True
  Else If U='/B'Then BootReserve:=True
  Else If Copy(U,1,3)='/S:'Then Begin
   If not ParseSystemFamily(Copy(S,4,255))Then Begin
    WriteLn('Famille de systeme inconnue: ',Copy(S,4,255));Exit
   End;SystemTransfer:=True
  End Else If U='/S'Then SystemTransfer:=True
  Else If Copy(U,1,3)='/F:'Then Begin
   If InFile or HardDiskMode Then Begin
    WriteLn('/F:taille est reserve aux unites de disquette.');Exit
   End;
   N:=Copy(U,4,255);
   If not((N='160')or(N='180')or(N='320')or(N='360')or(N='720')or
   (N='1200')or(N='1440')or(N='2880'))Then Begin
    WriteLn('Taille /F inconnue: ',N);Exit
   End;
   If FormatSize<>''Then Begin
    WriteLn('Le format est indique plusieurs fois.');Exit
   End;
   FormatSize:=N;ForceFormat:=True
  End
  Else If U='/F'Then ForceFormat:=True
  Else If U='NV'Then NoVerify:=True
  Else If(U='160')or(U='180')or(U='320')or(U='360')or(U='720')or
  (U='1200')or(U='1440')or(U='2880')Then Begin
   If FormatSize<>''Then Begin
    WriteLn('Le format est indique plusieurs fois.');Exit
   End;
   FormatSize:=U
  End Else
  Begin
   WriteLn('Parametre inconnu: ',S);Exit
  End
 End;
 If QuickFormat and UnconditionalFormat Then Begin
  WriteLn('Les options /Q et /U sont incompatibles.');Exit
 End;
 If HardDiskMode and(TracksSpecified or SectorsSpecified or SingleSide or
 EightSectors or Format360In1200)Then Begin
  WriteLn('/T, /N, /1, /4 et /8 sont reserves aux disquettes.');Exit
 End;
 If(RequestedFileSystem=FS_NTFS)and not(InFile or HardDiskMode)Then Begin
  WriteLn('NTFS est reserve aux partitions et aux images de disque dur.');Exit
 End;
 If(RequestedFileSystem=FS_NTFS)and(SystemTransfer or BootReserve)Then Begin
  WriteLn('/S et /B ne sont pas disponibles pour NTFS.');Exit
 End;
 If(RequestedFileSystem=FS_EXFAT)and not(InFile or HardDiskMode)Then Begin
  WriteLn('exFAT est reserve aux partitions et aux images de disque dur.');Exit
 End;
 If(RequestedFileSystem=FS_EXFAT)and(SystemTransfer or BootReserve)Then Begin
  WriteLn('/S et /B ne sont pas encore disponibles pour exFAT.');Exit
 End;
 If(RequestedFileSystem=FS_HPFS)and not(InFile or HardDiskMode)Then Begin
  WriteLn('HPFS est reserve aux partitions et aux images de disque dur.');Exit
 End;
 If(RequestedFileSystem=FS_FAT32)and not(InFile or HardDiskMode)Then Begin
  WriteLn('FAT32 est reserve aux partitions et aux images de disque dur.');Exit
 End;
 If(RequestedFileSystem=FS_FAT32)and(SystemTransfer or BootReserve)Then Begin
  WriteLn('/S et /B ne sont pas encore disponibles pour FAT32.');Exit
 End;
 If(RequestedFileSystem=FS_HPFS)and(SystemTransfer or BootReserve)Then Begin
  WriteLn('/S et /B ne sont pas disponibles pour HPFS.');Exit
 End;
 If(RequestedFileSystem=FS_HPFS)and AllocationSizeSpecified and
 (RequestedAllocationSize<>512)Then Begin
  WriteLn('HPFS utilise des unites d''allocation de 512 octets.');Exit
 End;
 If BootReserve and SystemTransfer Then Begin
  WriteLn('Les options /B et /S sont incompatibles.');Exit
 End;
 If Format360In1200 Then Begin
  If(FormatSize<>'')and(FormatSize<>'360')Then Begin
   WriteLn('/4 exige le format 360 Ko.');Exit
  End;
  FormatSize:='360';ForceFormat:=True
 End;
 If EightSectors or BootReserve Then Begin
  If SectorsSpecified and(RequestedSectors<>8)Then Begin
   WriteLn('/8 ou /B est incompatible avec /N:',RequestedSectors);Exit
  End;
  SectorsSpecified:=True;RequestedSectors:=8;
  If FormatSize=''Then Begin
   FormatSize:='320';ForceFormat:=True
  End
 End;
 ParseOptions:=True
End;

Function ConfigureFileSystem(PData:PhysDataType;Var LData:LogDataType):Boolean;
Var
 TotalSectors,RootSectors,DataSectors,Clusters,FatSectors,OldFat:LongInt;
 I:Byte;
Begin
 ConfigureFileSystem:=False;
 If VolumeTotalSectors>0Then TotalSectors:=VolumeTotalSectors
 Else TotalSectors:=LongInt(PData.Tracks)*PData.Faces*PData.Sec;
 If RequestedFileSystem=FS_HPFS Then Begin
  If TotalSectors<8192Then Begin
   WriteLn('HPFS exige une partition d''au moins 4 Mo.');Exit
  End;
  ConfigureFileSystem:=True;Exit
 End;
 If RequestedFileSystem=FS_EXFAT Then Begin
  LData.Media:=$F8;LData.RootSize:=0;
  If AllocationSizeSpecified Then LData.Cluster:=RequestedAllocationSize div 512
  Else LData.Cluster:=8;
  ExFatFatOffset:=24;ExFatFatLength:=1;ExFatHeapOffset:=32;
  For I:=1to 32do Begin
   ExFatHeapOffset:=ExFatFatOffset+ExFatFatLength;
   ExFatHeapOffset:=((ExFatHeapOffset+LData.Cluster-1)div LData.Cluster)*LData.Cluster;
   ExFatClusterCount:=(TotalSectors-ExFatHeapOffset)div LData.Cluster;
   OldFat:=ExFatFatLength;
   ExFatFatLength:=((ExFatClusterCount+2)*4+511)div 512;
   If ExFatFatLength=OldFat Then Break
  End;
  ExFatHeapOffset:=ExFatFatOffset+ExFatFatLength;
  ExFatHeapOffset:=((ExFatHeapOffset+LData.Cluster-1)div LData.Cluster)*LData.Cluster;
  ExFatClusterCount:=(TotalSectors-ExFatHeapOffset)div LData.Cluster;
  If(ExFatClusterCount<3)or(ExFatClusterCount>$0FFFFFF5)or
   (ExFatFatLength>65535)Then Begin
   WriteLn('La geometrie ne convient pas a exFAT.');Exit
  End;
  LData.FAT:=ExFatFatLength;ActiveFATBits:=64;ConfigureFileSystem:=True;Exit
 End;
 If RequestedFileSystem=FS_NTFS Then Begin
  If TotalSectors<8192Then Begin
   WriteLn('NTFS exige une partition d''au moins 4 Mo.');Exit
  End;
  If AllocationSizeSpecified Then NtfsClusterSectors:=RequestedAllocationSize div 512
  Else NtfsClusterSectors:=8;
  NtfsClusterCount:=TotalSectors div NtfsClusterSectors;
  NtfsMFTCluster:=4;
  If NtfsClusterCount>64Then NtfsMFTCluster:=NtfsClusterCount div 8;
  NtfsMFTMirrCluster:=NtfsClusterCount div 2;
  If(NtfsMFTCluster<1)or(NtfsMFTMirrCluster<=NtfsMFTCluster+4)Then Begin
   WriteLn('La geometrie ne convient pas a NTFS.');Exit
  End;
  LData.Media:=$F8;LData.Cluster:=NtfsClusterSectors;LData.FAT:=0;
  LData.RootSize:=0;ActiveFATBits:=50;ConfigureFileSystem:=True;Exit
 End;
 If RequestedFileSystem=FS_FAT32 Then Begin
  LData.Media:=$F8;LData.RootSize:=0;
  If AllocationSizeSpecified Then LData.Cluster:=RequestedAllocationSize div 512
  Else
  Begin
   LData.Cluster:=1;
   If TotalSectors>532480Then LData.Cluster:=8
  End;
  FatSectors:=1;
  For I:=1to 32do Begin
   DataSectors:=TotalSectors-32-FatSectors*2;
   Clusters:=DataSectors div LData.Cluster;OldFat:=FatSectors;
   FatSectors:=((Clusters+2)*4+511)div 512;
   If FatSectors=OldFat Then Break
  End;
  DataSectors:=TotalSectors-32-FatSectors*2;
  Clusters:=DataSectors div LData.Cluster;
  If(Clusters<65525)or(Clusters>$0FFFFFF5)or(FatSectors>65535)Then Begin
   WriteLn('La geometrie ne convient pas a FAT32 (au moins 65525 clusters requis).');Exit
  End;
  LData.FAT:=FatSectors;ActiveFATBits:=32;ConfigureFileSystem:=True;Exit
 End;
If AllocationSizeSpecified Then LData.Cluster:=RequestedAllocationSize div 512;
ActiveFATBits:=12;
If RequestedFileSystem=FS_FAT16 Then ActiveFATBits:=16
Else If RequestedFileSystem=FS_AUTO Then Begin
 If(VolumeTotalSectors>0)and(TotalSectors>=8192)Then ActiveFATBits:=16
 Else
 Begin
  RootSectors:=(LongInt(LData.RootSize)*32+511)div 512;
  Clusters:=(TotalSectors-1-LongInt(LData.FAT)*2-RootSectors)div LData.Cluster;
  If Clusters>=4085Then ActiveFATBits:=16
 End
End;
If ActiveFATBits=16 Then Begin
 LData.Media:=$F8;If not AllocationSizeSpecified Then LData.Cluster:=1;
 If HardDiskMode Then LData.RootSize:=512 Else LData.RootSize:=$E0;
 Repeat
 FatSectors:=1;
 For I:=1to 16do Begin
  RootSectors:=(LongInt(LData.RootSize)*32+511)div 512;
  DataSectors:=TotalSectors-1-FatSectors*2-RootSectors;
  Clusters:=DataSectors div LData.Cluster;OldFat:=FatSectors;
  FatSectors:=((Clusters+2)*2+511)div 512;
  If FatSectors=OldFat Then Break
 End;
 If(Clusters<65525)and(FatSectors<=65535)Then Break;
 If AllocationSizeSpecified Then Break;
 LData.Cluster:=LData.Cluster*2
 Until LData.Cluster>64;
 If(Clusters<4085)or(Clusters>=65525)or(FatSectors>65535)Then Begin
  WriteLn('La geometrie ne convient pas a FAT16 (4085 a 65524 clusters requis).');Exit
 End;LData.FAT:=FatSectors
End;
ConfigureFileSystem:=True
End;

Function ApplyTrackOption(Var PData:PhysDataType;Var LData:LogDataType):Boolean;
Var
 TotalSectors,RootSectors,DataSectors,Clusters,FatEntries:LongInt;
Begin
 ApplyTrackOption:=False;
 If TracksSpecified Then PData.Tracks:=RequestedTracks;
 If SectorsSpecified Then Begin
  PData.Sec:=RequestedSectors;PData.DDPT^[4]:=RequestedSectors
 End;
 If SingleSide Then PData.Faces:=1;
 If(PData.Tracks=40)and(PData.Sec=8)Then Begin
  If PData.Faces=1Then LData:=LOG160 Else LData:=LOG320
 End Else If(PData.Tracks=40)and(PData.Sec=9)and(PData.Faces=1)Then LData:=LOG180;
 If not ConfigureFileSystem(PData,LData)Then Exit;
 If VolumeTotalSectors>0Then TotalSectors:=VolumeTotalSectors
 Else TotalSectors:=LongInt(PData.Tracks)*PData.Faces*PData.Sec;
 RootSectors:=(LongInt(LData.RootSize)*32+511)div 512;
 DataSectors:=TotalSectors-1-LongInt(LData.FAT)*2-RootSectors;
 If DataSectors<1Then Begin
  WriteLn('Le nombre de pistes ne laisse aucune zone de donnees.');Exit
 End;
 Clusters:=(DataSectors+LData.Cluster-1)div LData.Cluster;
 If ActiveFATBits=12 Then FatEntries:=(LongInt(LData.FAT)*512*2)div 3-2
 Else FatEntries:=LongInt(LData.FAT)*512 div 2-2;
 If Clusters>FatEntries Then Begin
  WriteLn('Le nombre de pistes depasse la capacite de la FAT12 de ce format.');Exit
 End;
 If TotalSectors>65535Then Begin
  WriteLn('Le disque depasse 65535 secteurs.');Exit
 End;
 ApplyTrackOption:=True
End;
Function Get4matParam(S:String;DrvType:Byte;Var PData:PhysDataType;

Var LData:LogDataType):Boolean;Begin
 Get4matParam:=true;
 If S='160'Then  If(DrvType=dtHD525)or(DrvType=dtDD525)or ForceFormat Then Begin
  PData:=PHYS160;LData:=LOG160
 End
 Else Get4matParam:=False
 Else If S='180'Then  If(DrvType=dtHD525)or(DrvType=dtDD525)or ForceFormat Then Begin
  PData:=PHYS180;LData:=LOG180
 End
 Else Get4matParam:=False
 Else If S='320'Then  If(DrvType=dtHD525)or(DrvType=dtDD525)or ForceFormat Then Begin
  PData:=PHYS320;LData:=LOG320
 End
 Else Get4matParam:=False
 Else If S='1200'Then  If(DrvType=dtHD525)Then Begin
  PData:=PHYS1200;LData:=LOG1200;
 End
 Else If ForceFormat Then Begin
  PData:=PHYS1200;LData:=LOG1200
 End Else Get4matParam:=false
 Else
 If S='360'Then  If(DrvType=dtHD525)or(DrvType=dtDD525)or ForceFormat Then Begin
  PData:=PHYS360; LData:=LOG360;
 End
 Else Get4matParam:=false
 Else
 If S='1440'Then  If(DrvType=dtHD35)or ForceFormat Then Begin
  PData:=PHYS1440;
  LData:=LOG1440;
 End
 Else
 Get4matParam:=false
 Else
 If S='720'Then Begin
  If ForceFormat Then Begin
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
 If S='2880'Then  If(DrvType=dtHD35)or ForceFormat Then Begin
  PData:=PHYS2880;LData:=LOG2880
 End
 Else Get4matParam:=False
 Else
 Get4matParam:=false;
End;

Procedure InitDsk(Drive:Byte;PData:PhysDataType);
Var
 _CH,_CL:Byte;
Begin
 {$IFDEF FPC}
 {$ELSE}
  _CH:=PData.Tracks-1; _CL:=PData.Sec;
  ASM
  MOV AH,$18;
  MOV CL,_CL;
  MOV CH,_CH;
  MOV DL,Drive;
  INT $13;
 End;
{$ENDIF}
End;

Function FormatTrack(Drv,Face,Track,Nm:Byte):Byte;
Type
 FormatTyp=Record
 DTrack,DFace,DI,DLen:Byte;
End;
Var
 Regs:Registers;
 AreaData:Array[1..36]of FormatTyp;
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

Type
 TAbsoluteDiskPacket=Packed Record
 FirstSector:LongInt;
 SectorCount:Word;
 BufferOffset,BufferSegment:Word
End;
Function AbsoluteDiskIO(WriteOperation:Boolean;Drive:Byte;SectorNumber:LongInt;
Var Buffer):Boolean;
{$IFDEF FPC}
 Begin
  AbsoluteDiskIO:=False
 End;
{$ELSE}

 Var
  Regs:Registers;
  Packet:TAbsoluteDiskPacket;
  IntNumber:Byte;
 Begin
  FillChar(Regs,SizeOf(Regs),0);
  If WriteOperation Then IntNumber:=$26 Else IntNumber:=$25;
  Regs.AX:=Drive;
  If SectorNumber<=65535Then Begin
   Regs.CX:=1;Regs.DX:=Word(SectorNumber);
   Regs.DS:=Seg(Buffer);Regs.BX:=Ofs(Buffer)
  End Else
  Begin
   Packet.FirstSector:=SectorNumber;Packet.SectorCount:=1;
   Packet.BufferOffset:=Ofs(Buffer);Packet.BufferSegment:=Seg(Buffer);
   Regs.CX:=$FFFF;Regs.DS:=Seg(Packet);Regs.BX:=Ofs(Packet)
  End;
  Intr(IntNumber,Regs);
 { INT 25h/26h laissent volontairement un mot FLAGS sur la pile. }
  Inline($9D); { POPF, obligatoire sous DOS apres l'appel absolu. }
  AbsoluteDiskIO:=(Regs.Flags and fCarry)=0
 End;
{$ENDIF}

Procedure PutWordLE(Var Buffer:TSectorBuffer;Offset,Value:Word);Begin
 Buffer[Offset]:=Lo(Value);Buffer[Offset+1]:=Hi(Value)
End;

Procedure PutLongLE(Var Buffer:TSectorBuffer;Offset:Word;Value:LongInt);Begin
 Buffer[Offset]:=Byte(Value);Buffer[Offset+1]:=Byte(Value shr 8);
 Buffer[Offset+2]:=Byte(Value shr 16);Buffer[Offset+3]:=Byte(Value shr 24)
End;

Procedure PutWordRaw(Var Buffer;Offset,Value:Word);
Var
 B:Array[0..2047]of Byte Absolute Buffer;
Begin
 B[Offset]:=Lo(Value);B[Offset+1]:=Hi(Value)
End;

Procedure PutLongRaw(Var Buffer;Offset:Word;Value:LongInt);
Var
 B:Array[0..2047]of Byte Absolute Buffer;
Begin
 B[Offset]:=Byte(Value);B[Offset+1]:=Byte(Value shr 8);
 B[Offset+2]:=Byte(Value shr 16);B[Offset+3]:=Byte(Value shr 24)
End;
Function GetLongLE(Var Buffer:TSectorBuffer;Offset:Word):LongInt;Forward;

Function ImageSectorOffset(SectorNumber:LongInt):LongInt;Begin
 ImageSectorOffset:=ImageDataOffset+(ImageVolumeStart+SectorNumber)*512
End;

Function DetectFixedVDI:Boolean;
Var
 Header:TSectorBuffer;
 Got:Word;
 DiskBytes:LongInt;
Begin
 DetectFixedVDI:=False;ImageDataOffset:=0;ImageVirtualSectors:=0;
 Seek(FileImg,0);BlockRead(FileImg,Header,512,Got);
 If(Got<>512)or(IOResult<>0)Then Exit;
 If(Header[64]<>$7F)or(Header[65]<>$10)or(Header[66]<>$DA)or
 (Header[67]<>$BE)Then Exit;
 If GetLongLE(Header,76)<>2Then Begin
  WriteLn('Seules les images VDI fixes sont actuellement prises en charge.');Exit
 End;
 ImageDataOffset:=GetLongLE(Header,344);
 If GetLongLE(Header,372)<>0Then Begin
  WriteLn('Cette image VDI depasse la limite de 2 Gio de Turbo Pascal.');Exit
 End;
 DiskBytes:=GetLongLE(Header,368);
 If(ImageDataOffset<512)or(DiskBytes<512)Then Exit;
 ImageVirtualSectors:=DiskBytes div 512;ImageContainer:=IC_VDI;
 DetectFixedVDI:=True
End;

Function CreateDiskImageContainer(SizeMB:LongInt):Boolean;
Const
 VDIBlockSize=1048576;
Var
 Header,MBR:TSectorBuffer;
 ZeroBlock:TSectorBuffer;
 Blocks,I,MapBytes,Written:LongInt;
 DataBytes,Remaining:LongInt;
 Count:Word;
 Y,Mo,D,Dow,H,Mi,Se,S100:Word;
 Signature:String;
Begin
 CreateDiskImageContainer:=False;
 If SizeMB<1Then Exit;
 DataBytes:=SizeMB*1024*1024;ImageVirtualSectors:=DataBytes div 512;
 If ImageVirtualSectors<=63Then Begin
  WriteLn('Image trop petite pour contenir une partition de disque dur.');Exit
 End;
 Rewrite(FileImg,1);If IOResult<>0Then Exit;
 ImageDataOffset:=0;
 If ImageContainer=IC_VDI Then Begin
  FillChar(Header,SizeOf(Header),0);
  Signature:='<<< Oracle VM VirtualBox Disk Image >>>'+#10;
  For I:=1to Length(Signature)do Header[I-1]:=Ord(Signature[I]);
  PutLongLE(Header,64,LongInt($BEDA107F));PutLongLE(Header,68,$00010001);
  PutLongLE(Header,72,400);PutLongLE(Header,76,2);
  Blocks:=(DataBytes+VDIBlockSize-1)div VDIBlockSize;
  MapBytes:=Blocks*4;ImageDataOffset:=512+((MapBytes+511)div 512)*512;
  PutLongLE(Header,340,512);PutLongLE(Header,344,ImageDataOffset);
  PutLongLE(Header,348,ImageVirtualSectors div(16*63));PutLongLE(Header,352,16);
  PutLongLE(Header,356,63);PutLongLE(Header,360,512);
  PutLongLE(Header,368,DataBytes);PutLongLE(Header,372,0);
  PutLongLE(Header,376,VDIBlockSize);PutLongLE(Header,384,Blocks);
  PutLongLE(Header,388,Blocks);
  GetDate(Y,Mo,D,Dow);GetTime(H,Mi,Se,S100);Randomize;
  For I:=0to 15do Header[392+I]:=Byte(Random(256));
  Header[398]:=(Header[398]and $0F)or $40;Header[400]:=(Header[400]and $3F)or $80;
  BlockWrite(FileImg,Header,512,Count);If(Count<>512)or(IOResult<>0)Then Begin
   Close(FileImg);Exit
  End;
  For I:=0to Blocks-1do Begin
   PutLongLE(Header,0,I);BlockWrite(FileImg,Header,4,Count);
   If(Count<>4)or(IOResult<>0)Then Begin
    Close(FileImg);Exit
   End
  End;
  FillChar(Header,SizeOf(Header),0);
  While FilePos(FileImg)<ImageDataOffset do Begin
   Written:=ImageDataOffset-FilePos(FileImg);If Written>512Then Written:=512;
   BlockWrite(FileImg,Header,Written,Count);
   If Count<>Written Then Begin
    Close(FileImg);Exit
   End
  End
 End;
 FillChar(ZeroBlock,SizeOf(ZeroBlock),0);Remaining:=DataBytes;
 While Remaining>0do Begin
  Written:=SizeOf(ZeroBlock);If Remaining<Written Then Written:=Remaining;
  BlockWrite(FileImg,ZeroBlock,Written,Count);
  If(Count<>Written)or(IOResult<>0)Then Begin
   Close(FileImg);Exit
  End;
  Dec(Remaining,Written)
 End;
 FillChar(MBR,SizeOf(MBR),0);MBR[446]:=$80;
 MBR[447]:=1;MBR[448]:=1;MBR[449]:=0;
 If RequestedFileSystem in[FS_HPFS,FS_EXFAT,FS_NTFS]Then MBR[450]:=$07
 Else If RequestedFileSystem=FS_FAT32 Then MBR[450]:=$0C
 Else If RequestedFileSystem=FS_FAT12 Then MBR[450]:=$01
 Else If SizeMB<32Then MBR[450]:=$04 Else MBR[450]:=$06;
 MBR[451]:=15;MBR[452]:=$FF;MBR[453]:=$FF;
 PutLongLE(MBR,454,63);PutLongLE(MBR,458,ImageVirtualSectors-63);
 MBR[510]:=$55;MBR[511]:=$AA;
 Seek(FileImg,ImageDataOffset);BlockWrite(FileImg,MBR,512,Count);
 If(Count<>512)or(IOResult<>0)Then Begin
  Close(FileImg);Exit
 End;
 ImageVolumeStart:=63;VolumeHiddenSectors:=63;
 VolumeTotalSectors:=ImageVirtualSectors-63;
 CreateDiskImageContainer:=True
End;
Function PrepareOpenedHardDiskImage(Var PData:PhysDataType;

Var LData:LogDataType):Boolean;
Var
 MBR:TSectorBuffer;
 Got:Word;
 PartStart,PartSize:LongInt;
Begin
 PrepareOpenedHardDiskImage:=False;
 Seek(FileImg,ImageDataOffset);BlockRead(FileImg,MBR,512,Got);
 If(Got<>512)or(IOResult<>0)or(MBR[510]<>$55)or(MBR[511]<>$AA)Then Begin
  WriteLn('L''image de disque dur ne contient pas un MBR valide.');Exit
 End;
 PartStart:=GetLongLE(MBR,454);PartSize:=GetLongLE(MBR,458);
 If(PartStart<1)or(PartSize<1)or(PartStart+PartSize>ImageVirtualSectors)Then Begin
  WriteLn('La premiere partition de l''image est absente ou invalide.');Exit
 End;
 ImageVolumeStart:=PartStart;VolumeHiddenSectors:=PartStart;
 VolumeTotalSectors:=PartSize;
 PData:=PHYS1440;PData.Sec:=63;PData.Faces:=16;PData.Tracks:=1;
 LData:=LOG1440;LData.Media:=$F8;LData.RootSize:=512;
 PrepareOpenedHardDiskImage:=True
End;

Function UpdateImagePartitionType(PartitionType:Byte):Boolean;
Var
 Written:Word;
Begin
 Seek(FileImg,ImageDataOffset+450);
 If IOResult<>0Then Begin
  UpdateImagePartitionType:=False;Exit
 End;
 BlockWrite(FileImg,PartitionType,1,Written);
 UpdateImagePartitionType:=(Written=1)and(IOResult=0)
End;

Function ReadLogicalSector(SectorNumber:LongInt;Var Buffer):Boolean;
Var
 Got:Word;
Begin
 If InFile Then Begin
  Seek(FileImg,ImageSectorOffset(SectorNumber));
  If IOResult<>0Then Begin
   ReadLogicalSector:=False;Exit
  End;
  BlockRead(FileImg,Buffer,512,Got);
  ReadLogicalSector:=(Got=512)and(IOResult=0)
 End Else If HardDiskMode Then  ReadLogicalSector:=AbsoluteDiskIO(False,AktDrv,
 SectorNumber,Buffer)
 Else ReadLogicalSector:=False
End;

Function GetWordLE(Var Buffer:TSectorBuffer;Offset:Word):Word;Begin
 GetWordLE:=Word(Buffer[Offset])or(Word(Buffer[Offset+1])shl 8)
End;

Function GetLongLE(Var Buffer:TSectorBuffer;Offset:Word):LongInt;Begin
 GetLongLE:=LongInt(GetWordLE(Buffer,Offset))or
 (LongInt(GetWordLE(Buffer,Offset+2))shl 16)
End;
Function PrepareHardDisk(Drive:Byte;Var PData:PhysDataType;

Var LData:LogDataType):Boolean;
Var
 Boot:TSectorBuffer;
 Total:LongInt;
 GeometryValue:Word;
 ExistingExFAT,ExistingNTFS:Boolean;
Begin
 PrepareHardDisk:=False;
 If not ReadLogicalSector(0,Boot)Then Begin
  WriteLn('Impossible de lire le secteur de demarrage de ',Chr(Drive+65),':.');Exit
 End;
 ExistingExFAT:=(Boot[3]=Ord('E'))and(Boot[4]=Ord('X'))and
 (Boot[5]=Ord('F'))and(Boot[6]=Ord('A'))and(Boot[7]=Ord('T'))and
 (Boot[8]=Ord(' '))and(Boot[9]=Ord(' '))and(Boot[10]=Ord(' '));
 ExistingNTFS:=(Boot[3]=Ord('N'))and(Boot[4]=Ord('T'))and
 (Boot[5]=Ord('F'))and(Boot[6]=Ord('S'))and(Boot[7]=Ord(' '))and
 (Boot[8]=Ord(' '))and(Boot[9]=Ord(' '))and(Boot[10]=Ord(' '));
 If(not ExistingExFAT)and(GetWordLE(Boot,11)<>512)Then Begin
  WriteLn(
  'La partition doit d''abord etre creee par FDISK avec des secteurs de 512 octets.');Exit
 End;
 If ExistingExFAT Then Begin
  If(Boot[108]<>9)or(GetLongLE(Boot,76)<>0)Then Begin
   WriteLn('Le volume exFAT doit utiliser des secteurs de 512 octets et faire moins de 2 Go.');
   Exit
  End;
  Total:=GetLongLE(Boot,72);VolumeHiddenSectors:=GetLongLE(Boot,64)
 End Else If ExistingNTFS Then Begin
  If GetLongLE(Boot,44)<>0Then Begin
   WriteLn('Le volume NTFS fait plus de 2 Go et depasse les limites de cette version.');Exit
  End;
  Total:=GetLongLE(Boot,40);VolumeHiddenSectors:=GetLongLE(Boot,28)
 End Else Begin
  Total:=GetWordLE(Boot,19);If Total=0Then Total:=GetLongLE(Boot,32);
  VolumeHiddenSectors:=GetLongLE(Boot,28)
 End;
 If Total<1Then Begin
  WriteLn('Le BPB ne contient pas une taille de partition valide.');Exit
 End;
 VolumeTotalSectors:=Total;
 If not(RequestedFileSystem in[FS_HPFS,FS_FAT32,FS_EXFAT,FS_NTFS])and
 ((GetWordLE(Boot,17)=0)or(GetWordLE(Boot,22)=0))Then Begin
  WriteLn('Cette partition utilise FAT32 ou un BPB non pris en charge.');
  WriteLn('Seules les partitions FAT12/FAT16 existantes peuvent etre reformatees.');Exit
 End;
 PData:=PHYS1440;
 If ExistingExFAT Then GeometryValue:=63 Else GeometryValue:=GetWordLE(Boot,24);
 If GeometryValue>255Then GeometryValue:=255;PData.Sec:=GeometryValue;
 If ExistingExFAT Then GeometryValue:=16 Else GeometryValue:=GetWordLE(Boot,26);
 If GeometryValue>255Then GeometryValue:=255;PData.Faces:=GeometryValue;
 If PData.Sec=0Then PData.Sec:=63;
 If PData.Faces=0Then PData.Faces:=16;
 PData.Tracks:=1;PData.DDPT:=@DDPT1440;
 If ExistingExFAT Then Begin
  LData.Media:=$F8;LData.Cluster:=1 shl Boot[109];
  LData.FAT:=0;LData.RootSize:=512
 End Else If ExistingNTFS Then Begin
  LData.Media:=$F8;LData.Cluster:=Boot[13];LData.FAT:=0;LData.RootSize:=0
 End Else Begin
  LData.Media:=Boot[21];If LData.Media=0Then LData.Media:=$F8;
  LData.Cluster:=Boot[13];If LData.Cluster=0Then LData.Cluster:=1;
  LData.FAT:=GetWordLE(Boot,22);LData.RootSize:=GetWordLE(Boot,17)
 End;
 If LData.RootSize=0Then LData.RootSize:=512;
 PrepareHardDisk:=True
End;
Function WriteLogicalSector(PData:PhysDataType;SectorNumber:LongInt;
Var Buffer):Boolean;Forward;

Function WriteVolumeLabel(PData:PhysDataType;LData:LogDataType):Boolean;
Var
 RootSector,Remaining:Word;
 Track,Face,Sector,I,Status:Byte;
 Buffer:Array[0..511]of Byte;
 Written:Word;
Begin
 If VolumeLabel=''Then Begin
  WriteVolumeLabel:=True;Exit
 End;
 FillChar(Buffer,SizeOf(Buffer),0);
 For I:=1to 11do Buffer[I-1]:=Ord(VolumeLabel[I]);
 Buffer[11]:=$08; { Entree de repertoire FAT: attribut volume. }
 RootSector:=1+2*LData.FAT;
 If HardDiskMode Then  WriteVolumeLabel:=WriteLogicalSector(PData,RootSector,Buffer)
 Else If InFile Then Begin
  Seek(FileImg,ImageSectorOffset(RootSector));
  If IOResult<>0Then Begin
   WriteVolumeLabel:=False;Exit
  End;
  BlockWrite(FileImg,Buffer,32,Written);
  WriteVolumeLabel:=(Written=32)and(IOResult=0)
 End Else
 Begin
  Track:=RootSector div(Word(PData.Sec)*PData.Faces);
  Remaining:=RootSector mod(Word(PData.Sec)*PData.Faces);
  Face:=Remaining div PData.Sec;Sector:=Remaining mod PData.Sec+1;
  Status:=WriteTrack(AktDrv,Face,Track,Sector,1,Buffer);
  WriteVolumeLabel:=Status=0
 End
End;

Function WriteLogicalSector(PData:PhysDataType;SectorNumber:LongInt;Var Buffer):Boolean;
Var
 Remaining:LongInt;
 Track,Face,Sector,Status:Byte;
 Written:Word;
Begin
 If InFile Then Begin
  Seek(FileImg,ImageSectorOffset(SectorNumber));
  If IOResult<>0Then Begin
   WriteLogicalSector:=False;Exit
  End;
  BlockWrite(FileImg,Buffer,512,Written);
  WriteLogicalSector:=(Written=512)and(IOResult=0)
 End Else If HardDiskMode Then  WriteLogicalSector:=AbsoluteDiskIO(True,AktDrv,
 SectorNumber,Buffer)
 Else
 Begin
  Track:=SectorNumber div(LongInt(PData.Sec)*PData.Faces);
  Remaining:=SectorNumber mod(LongInt(PData.Sec)*PData.Faces);
  Face:=Remaining div PData.Sec;Sector:=Remaining mod PData.Sec+1;
  Status:=WriteTrack(AktDrv,Face,Track,Sector,1,Buffer);
  WriteLogicalSector:=Status=0
 End
End;

Procedure SetFAT12Entry(FAT:PFatBuffer;Cluster,Value:Word);
Var
 Offset:Word;
 V:Word;
Begin
 Offset:=Cluster+(Cluster div 2);
 V:=FAT^[Offset]or(Word(FAT^[Offset+1])shl 8);
 If(Cluster and 1)=0Then V:=(V and $F000)or(Value and $0FFF)
 Else V:=(V and $000F)or((Value and $0FFF)shl 4);
 FAT^[Offset]:=Lo(V);FAT^[Offset+1]:=Hi(V)
End;

Procedure SetFATEntry(FAT:PFatBuffer;Cluster,Value:Word);
Var
 Offset:Word;
Begin
 If ActiveFATBits=12 Then SetFAT12Entry(FAT,Cluster,Value)
 Else
 Begin
  Offset:=Cluster*2;FAT^[Offset]:=Lo(Value);FAT^[Offset+1]:=Hi(Value)
 End
End;

Procedure PutDirectoryName(Var Entry;Const Name:String);
Var
 P:^Byte;
 I,Dot:Byte;
 Base,Ext:String;
Begin
 P:=@Entry;
 For I:=0to 10do Begin
  P^:=Ord(' ');Inc(P)
 End;
 Dot:=Pos('.',Name);If Dot=0Then Begin
  Base:=Name;Ext:=''
 End
 Else
 Begin
  Base:=Copy(Name,1,Dot-1);Ext:=Copy(Name,Dot+1,3)
 End;
 P:=@Entry;
 For I:=1to Length(Base)do If I<=8Then Begin
  P^:=Ord(UpCase(Base[I]));Inc(P)
 End;
 P:=@Entry;Inc(P,8);
 For I:=1to Length(Ext)do If I<=3Then Begin
  P^:=Ord(UpCase(Ext[I]));Inc(P)
 End
End;

Function SystemFilesAvailable:Boolean;
Var
 F:File;
 I,RequiredCount:Byte;
Begin
 SystemFilesAvailable:=False;
 If BootReserve Then Begin
  RequiredCount:=SysFileCount;If RequiredCount>2Then RequiredCount:=2
 End
 Else RequiredCount:=SysFileCount;
 For I:=1to RequiredCount do Begin
  Assign(F,SysFiles[I]);Reset(F,1);
  If IOResult<>0Then Begin
   WriteLn('Fichier de demarrage introuvable: ',SysFiles[I]);Exit
  End;
  Close(F);If IOResult<>0Then Begin
   WriteLn('Erreur de lecture: ',SysFiles[I]);Exit
  End
 End;
 SystemFilesAvailable:=True
End;

Function TransferSystemFiles(PData:PhysDataType;LData:LogDataType):Boolean;
Var
 FAT:PFatBuffer;
 Root,Buffer:TSectorBuffer;
 Src:File;
 I,J,K,CopyNumber,FilesToInstall:Integer;
 Got:Word;
 FileSizeValue,Remaining,ClusterBytes:LongInt;
 RootSectors,DataStart,SectorNumber,TotalSectors,MaximumClusters:LongInt;
 ClustersNeeded:Word;
 FirstCluster,CurrentCluster,NextCluster:Word;
 EntryOffset:Word;
 Y,Mo,D,Dow,H,Mi,Se,S100,DirDate,DirTime:Word;
 Attr:Byte;
Begin
 TransferSystemFiles:=False;
 If not SystemFilesAvailable Then Exit;
 If LongInt(LData.FAT)*512>MaxFormatFATBytes Then Begin
  WriteLn('La FAT est trop grande pour le tampon de transfert systeme Turbo Pascal.');Exit
 End;
 If BootReserve Then WriteLn('Reservation pour le systeme ',SystemFamilyName,'.')
 Else WriteLn('Transfert du systeme ',SystemFamilyName,'.');
 GetMem(FAT,MaxFormatFATBytes);If FAT=Nil Then Begin
  WriteLn('Memoire insuffisante pour la FAT.');Exit
 End;
 FillChar(FAT^,MaxFormatFATBytes,0);FillChar(Root,SizeOf(Root),0);
 FAT^[0]:=LData.Media;FAT^[1]:=$FF;FAT^[2]:=$FF;
 If ActiveFATBits=16 Then FAT^[3]:=$FF;
 If VolumeLabel<>''Then Begin
  For I:=1to 11do Root[I-1]:=Ord(VolumeLabel[I]);Root[11]:=$08;K:=1
 End Else K:=0;
 GetDate(Y,Mo,D,Dow);GetTime(H,Mi,Se,S100);
 If Y<1980Then Y:=1980;
 DirDate:=((Y-1980)shl 9)or(Mo shl 5)or D;
 DirTime:=(H shl 11)or(Mi shl 5)or(Se div 2);
 RootSectors:=(LongInt(LData.RootSize)*32+511)div 512;
 DataStart:=1+LongInt(LData.FAT)*2+RootSectors;
 TotalSectors:=LongInt(PData.Tracks)*PData.Faces*PData.Sec;
 MaximumClusters:=(TotalSectors-DataStart)div LData.Cluster;
 ClusterBytes:=LongInt(LData.Cluster)*512;NextCluster:=2;
 FilesToInstall:=SysFileCount;If BootReserve and(FilesToInstall>2)Then FilesToInstall:=2;
 For I:=1to FilesToInstall do Begin
  Assign(Src,SysFiles[I]);Reset(Src,1);
  If IOResult<>0Then Begin
   FreeMem(FAT,MaxFormatFATBytes);Exit
  End;
  FileSizeValue:=FileSize(Src);
  ClustersNeeded:=(FileSizeValue+ClusterBytes-1)div ClusterBytes;
  If((ActiveFATBits=12)and(LongInt(NextCluster)+ClustersNeeded>4085))or
  ((ActiveFATBits=16)and(LongInt(NextCluster)+ClustersNeeded>65525))or
  (LongInt(NextCluster-2)+ClustersNeeded>MaximumClusters)Then Begin
   Close(Src);FreeMem(FAT,MaxFormatFATBytes);
   WriteLn('Espace FAT12 insuffisant pour ',SysFiles[I]);Exit
  End;
  If ClustersNeeded=0 Then FirstCluster:=0 Else FirstCluster:=NextCluster;
  Remaining:=FileSizeValue;
  For J:=0to ClustersNeeded-1do Begin
   CurrentCluster:=NextCluster;Inc(NextCluster);
   If J=ClustersNeeded-1Then Begin
    If ActiveFATBits=12 Then SetFATEntry(FAT,CurrentCluster,$FFF)
    Else SetFATEntry(FAT,CurrentCluster,$FFFF)
   End Else SetFATEntry(FAT,CurrentCluster,NextCluster);
   For CopyNumber:=0to LData.Cluster-1do Begin
    FillChar(Buffer,SizeOf(Buffer),0);Got:=0;
    If Remaining>0Then Begin
     If BootReserve Then Begin
      Got:=512;If Remaining<512Then Got:=Remaining
     End
     Else
     Begin
      BlockRead(Src,Buffer,512,Got);If IOResult<>0Then Got:=0
     End
    End;
    If(Got=0)and(Remaining>0)Then Begin
     Close(Src);FreeMem(FAT,MaxFormatFATBytes);WriteLn('Erreur de lecture: ',SysFiles[I]);
     Exit
    End;
    SectorNumber:=DataStart+LongInt(CurrentCluster-2)*LData.Cluster+CopyNumber;
    If not WriteLogicalSector(PData,SectorNumber,Buffer)Then Begin
     Close(Src);FreeMem(FAT,MaxFormatFATBytes);
     WriteLn('Erreur d''ecriture de ',SysFiles[I]);Exit
    End;
    Dec(Remaining,Got)
   End
  End;
  Close(Src);If IOResult<>0Then Begin
   FreeMem(FAT,MaxFormatFATBytes);Exit
  End;
  EntryOffset:=K*32;PutDirectoryName(Root[EntryOffset],SysFiles[I]);
  If StrToUpper(SysFiles[I])='COMMAND.COM'Then Attr:=$20 Else Attr:=$27;
  Root[EntryOffset+11]:=Attr;
  Root[EntryOffset+22]:=Lo(DirTime);Root[EntryOffset+23]:=Hi(DirTime);
  Root[EntryOffset+24]:=Lo(DirDate);Root[EntryOffset+25]:=Hi(DirDate);
  Root[EntryOffset+26]:=Lo(FirstCluster);Root[EntryOffset+27]:=Hi(FirstCluster);
  Root[EntryOffset+28]:=Byte(FileSizeValue);
  Root[EntryOffset+29]:=Byte(FileSizeValue shr 8);
  Root[EntryOffset+30]:=Byte(FileSizeValue shr 16);
  Root[EntryOffset+31]:=Byte(FileSizeValue shr 24);
  Inc(K)
 End;
 For CopyNumber:=0to 1do
 For I:=0to LData.FAT-1do Begin
  SectorNumber:=1+LongInt(CopyNumber)*LData.FAT+I;
  If not WriteLogicalSector(PData,SectorNumber,FAT^[I*512])Then Begin
   FreeMem(FAT,MaxFormatFATBytes);WriteLn('Erreur d''ecriture de la FAT.');Exit
  End
 End;
 If not WriteLogicalSector(PData,1+LongInt(LData.FAT)*2,Root)Then Begin
  FreeMem(FAT,MaxFormatFATBytes);WriteLn('Erreur d''ecriture du repertoire racine.');Exit
 End;
 FreeMem(FAT,MaxFormatFATBytes);TransferSystemFiles:=True
End;

Function Phys4mat(Drv:Byte;PData:PhysDataType;Verify:Boolean):Boolean;
Var
 Try,T,F,Status:Byte;
Begin
 For T:=0to PData.Tracks-1do
 For F:=0to PData.Faces-1do Begin
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

Function ExFatChecksumStep(Value:LongInt;B:Byte):LongInt;Begin
 ExFatChecksumStep:=LongInt((Value shr 1)+((Value and 1)shl 31)+B)
End;

Function FormatNTFS(PData:PhysDataType;LData:LogDataType):Boolean;
Type
 TMFTRecord=Array[0..1023]of Byte;
Var
 Sec:TSectorBuffer;
 Rec:TMFTRecord;
 Total,MFTSector,MirrorSector,BitmapSector,BitmapBytes,K,BitmapClusters,
 MFTClusters,MirrorClusters,ClusterBytes:LongInt;
 I,J,AttrPos,AttrLen,NameLen:Word;
 Serial:LongInt;
 Name:String;
 MetaNames:Array[0..11]of String[12];

 Procedure PutRecWord(Offset,Value:Word);Begin
  Rec[Offset]:=Lo(Value);Rec[Offset+1]:=Hi(Value)
 End;

 Procedure PutRecLong(Offset:Word;Value:LongInt);Begin
  PutRecWord(Offset,Word(Value and $FFFF));
  PutRecWord(Offset+2,Word((Value shr 16)and $FFFF))
 End;

 Procedure PutResidentAttribute(AttrType:LongInt;ValueLength:Word);
 Var AttributeLength:Word;
 Begin
  AttributeLength:=(24+ValueLength+7)and $FFF8;
  PutRecLong(AttrPos,AttrType);PutRecLong(AttrPos+4,AttributeLength);
  Rec[AttrPos+8]:=0;Rec[AttrPos+9]:=0;PutRecWord(AttrPos+10,0);
  PutRecWord(AttrPos+12,0);PutRecWord(AttrPos+14,AttrPos);
  PutRecLong(AttrPos+16,ValueLength);PutRecWord(AttrPos+20,24);
  Rec[AttrPos+22]:=0;Rec[AttrPos+23]:=0;AttrLen:=AttributeLength
 End;

 Procedure PutNonResidentData(FirstCluster,ClusterLength,DataLength:LongInt);
 Var AllocatedLength:LongInt;
 Begin
  AttrLen:=80;PutRecLong(AttrPos,$80);PutRecLong(AttrPos+4,AttrLen);
  Rec[AttrPos+8]:=1;PutRecWord(AttrPos+10,0);PutRecWord(AttrPos+12,0);
  PutRecLong(AttrPos+16,0);PutRecLong(AttrPos+20,0);
  PutRecLong(AttrPos+24,ClusterLength-1);PutRecLong(AttrPos+28,0);
  PutRecWord(AttrPos+32,72);PutRecWord(AttrPos+34,0);
  AllocatedLength:=ClusterLength*NtfsClusterSectors*512;
  PutRecLong(AttrPos+40,AllocatedLength);PutRecLong(AttrPos+44,0);
  PutRecLong(AttrPos+48,DataLength);PutRecLong(AttrPos+52,0);
  PutRecLong(AttrPos+56,DataLength);PutRecLong(AttrPos+60,0);
  Rec[AttrPos+72]:=$41;Rec[AttrPos+73]:=Byte(ClusterLength);
  PutRecLong(AttrPos+74,FirstCluster);Rec[AttrPos+78]:=0
 End;

 Procedure BuildMFTRecord(Number:Word;FileName:String;Directory:Boolean);
 Var
  P,N:Word;
  FileFlags:LongInt;
  LabelValue:String;
 Begin
  FillChar(Rec,SizeOf(Rec),0);
  Rec[0]:=Ord('F');Rec[1]:=Ord('I');Rec[2]:=Ord('L');Rec[3]:=Ord('E');
  PutRecWord(4,$30);PutRecWord(6,3);PutRecWord(16,1);PutRecWord(18,1);
  PutRecWord(20,$38);If Directory Then PutRecWord(22,3)Else PutRecWord(22,1);
  PutRecLong(28,1024);PutRecWord(40,3);PutRecLong(44,Number);
  PutRecWord($30,$A55A);PutRecWord($32,0);PutRecWord($34,0);
  AttrPos:=$38;PutResidentAttribute($10,48);Inc(AttrPos,AttrLen);
  If FileName<>''Then Begin
   NameLen:=Length(FileName);PutResidentAttribute($30,66+NameLen*2);
   P:=AttrPos+24;PutRecLong(P,5);PutRecWord(P+6,1);
   If Directory Then FileFlags:=$10000000 Else FileFlags:=$00000006;
   PutRecLong(P+56,FileFlags);Rec[P+64]:=Byte(NameLen);Rec[P+65]:=3;
   For N:=1to NameLen do PutRecWord(P+64+N*2,Ord(FileName[N]));
   Inc(AttrPos,AttrLen)
  End;
  If Number=0Then Begin
   PutNonResidentData(NtfsMFTCluster,MFTClusters,16384);Inc(AttrPos,AttrLen);
   PutResidentAttribute($B0,8);Rec[AttrPos+24]:=$FF;Rec[AttrPos+25]:=$FF;
   Inc(AttrPos,AttrLen)
  End Else If Number=1Then Begin
   PutNonResidentData(NtfsMFTMirrCluster,MirrorClusters,4096);Inc(AttrPos,AttrLen)
  End Else If Number=3Then Begin
   LabelValue:=VolumeLabel;While(Length(LabelValue)>0)and
    (LabelValue[Length(LabelValue)]=' ')do Delete(LabelValue,Length(LabelValue),1);
   If LabelValue<>''Then Begin
    PutResidentAttribute($60,Length(LabelValue)*2);P:=AttrPos+24;
    For N:=1to Length(LabelValue)do PutRecWord(P+(N-1)*2,Ord(LabelValue[N]));
    Inc(AttrPos,AttrLen)
   End;
   PutResidentAttribute($70,12);P:=AttrPos+24;Rec[P+8]:=3;Rec[P+9]:=1;
   Inc(AttrPos,AttrLen)
  End Else If Number=5Then Begin
   PutResidentAttribute($90,48);P:=AttrPos+24;PutRecLong(P,$30);
   PutRecLong(P+4,1);PutRecLong(P+8,4096);Rec[P+12]:=1;
   PutRecLong(P+16,16);PutRecLong(P+20,32);PutRecLong(P+24,32);
   PutRecWord(P+40,16);PutRecWord(P+42,0);PutRecWord(P+44,2);
   Inc(AttrPos,AttrLen)
  End Else If Number=6Then Begin
   PutNonResidentData((BitmapSector div NtfsClusterSectors),
    (BitmapBytes+NtfsClusterSectors*512-1)div(NtfsClusterSectors*512),BitmapBytes);
   Inc(AttrPos,AttrLen)
  End Else If Number=7Then Begin
   PutNonResidentData(0,1,NtfsClusterSectors*512);Inc(AttrPos,AttrLen)
  End;
  PutRecLong(AttrPos,LongInt($FFFFFFFF));Inc(AttrPos,4);
  PutRecLong(24,AttrPos);PutRecWord(510,$A55A);PutRecWord(1022,$A55A)
 End;

 Function WriteMFTRecord(FirstSector:LongInt;Number:Word):Boolean;
 Var N:Word;
 Begin
  For N:=0to 511do Sec[N]:=Rec[N];
  If not WriteLogicalSector(PData,FirstSector+LongInt(Number)*2,Sec)Then Begin
   WriteMFTRecord:=False;Exit
  End;
  For N:=0to 511do Sec[N]:=Rec[N+512];
  WriteMFTRecord:=WriteLogicalSector(PData,FirstSector+LongInt(Number)*2+1,Sec)
 End;

Begin
 FormatNTFS:=False;Total:=VolumeTotalSectors;
 If Total=0Then Total:=LongInt(PData.Tracks)*PData.Faces*PData.Sec;
 ClusterBytes:=NtfsClusterSectors*512;
 MFTClusters:=(16384+ClusterBytes-1)div ClusterBytes;
 MirrorClusters:=(4096+ClusterBytes-1)div ClusterBytes;
 MFTSector:=NtfsMFTCluster*NtfsClusterSectors;
 MirrorSector:=NtfsMFTMirrCluster*NtfsClusterSectors;
 BitmapSector:=(NtfsMFTCluster+MFTClusters)*NtfsClusterSectors;
 BitmapBytes:=(NtfsClusterCount+7)div 8;
 BitmapClusters:=(BitmapBytes+NtfsClusterSectors*512-1)div
  (NtfsClusterSectors*512);
 If(BitmapSector+((BitmapBytes+511)div 512)>=Total-1)Then Begin
  WriteLn('Volume NTFS trop petit pour les metadonnees.');Exit
 End;

 FillChar(Sec,SizeOf(Sec),0);Sec[0]:=$EB;Sec[1]:=$52;Sec[2]:=$90;
 Name:='NTFS    ';For I:=1to 8do Sec[2+I]:=Ord(Name[I]);
 PutWordLE(Sec,11,512);Sec[13]:=Byte(NtfsClusterSectors);PutWordLE(Sec,14,0);
 Sec[16]:=0;PutWordLE(Sec,17,0);PutWordLE(Sec,19,0);Sec[21]:=$F8;
 PutWordLE(Sec,22,0);PutWordLE(Sec,24,63);PutWordLE(Sec,26,16);
 PutLongLE(Sec,28,VolumeHiddenSectors);PutLongLE(Sec,40,Total);
 PutLongLE(Sec,44,0);PutLongLE(Sec,48,NtfsMFTCluster);PutLongLE(Sec,52,0);
 PutLongLE(Sec,56,NtfsMFTMirrCluster);PutLongLE(Sec,60,0);
 Sec[64]:=$F6;If ClusterBytes>=4096Then Sec[68]:=1 Else Sec[68]:=$F4;
 Serial:=LongInt(Total xor $5346544E);
 PutLongLE(Sec,72,Serial);PutLongLE(Sec,76,LongInt(not Serial));
 Sec[510]:=$55;Sec[511]:=$AA;
 If not WriteLogicalSector(PData,0,Sec)Then Exit;
 If not WriteLogicalSector(PData,Total-1,Sec)Then Exit;

 FillChar(Sec,SizeOf(Sec),0);
 For I:=1to Word(NtfsClusterSectors)-1do
  If not WriteLogicalSector(PData,I,Sec)Then Exit;
 For I:=0to 11do MetaNames[I]:='';
 MetaNames[0]:='$MFT';MetaNames[1]:='$MFTMirr';MetaNames[2]:='$LogFile';
 MetaNames[3]:='$Volume';MetaNames[4]:='$AttrDef';MetaNames[5]:='.';
 MetaNames[6]:='$Bitmap';MetaNames[7]:='$Boot';MetaNames[8]:='$BadClus';
 MetaNames[9]:='$Secure';MetaNames[10]:='$UpCase';MetaNames[11]:='$Extend';
 For I:=0to 15do Begin
  If I<=11Then Name:=MetaNames[I]Else Name:='';
  BuildMFTRecord(I,Name,(I=5)or(I=11));
  If not WriteMFTRecord(MFTSector,I)Then Exit
 End;
 For I:=0to 3do Begin
  BuildMFTRecord(I,MetaNames[I],False);
  If not WriteMFTRecord(MirrorSector,I)Then Exit
 End;

 For I:=0to Word((BitmapBytes+511)div 512)-1do Begin
  FillChar(Sec,SizeOf(Sec),0);
  For J:=0to 4095do Begin
   K:=LongInt(I)*4096+J;
   If K>=NtfsClusterCount Then Sec[J div 8]:=Sec[J div 8]or Byte(1shl(J and 7))
   Else If(K=0)or(K=NtfsClusterCount-1)or
    ((K>=NtfsMFTCluster)and(K<NtfsMFTCluster+MFTClusters))or
    ((K>=BitmapSector div NtfsClusterSectors)and
     (K<BitmapSector div NtfsClusterSectors+BitmapClusters))or
    ((K>=NtfsMFTMirrCluster)and(K<NtfsMFTMirrCluster+MirrorClusters))Then
     Sec[J div 8]:=Sec[J div 8]or Byte(1shl(J and 7))
  End;
  If not WriteLogicalSector(PData,BitmapSector+I,Sec)Then Exit
 End;
 FormatNTFS:=True
End;

Function FormatExFAT(PData:PhysDataType;LData:LogDataType):Boolean;
Var
 Sec:TSectorBuffer;
 Total,ClusterBytes,BitmapBytes,BitmapClusters,UpCaseClusters:LongInt;
 BitmapFirst,UpCaseFirst,RootCluster,UsedClusters,DataSector:LongInt;
 BootChecksum,UpCaseChecksum:LongInt;
 I,J,K,EntryIndex:LongInt;
 Shift:Byte;
 LabelText,Signature:String;

 Procedure PutQWordLow(Var B:TSectorBuffer;Offset:Word;Value:LongInt);Begin
  PutLongLE(B,Offset,Value);PutLongLE(B,Offset+4,0)
 End;

 Procedure AddBootSectorToChecksum(Var B:TSectorBuffer;SectorIndex:Byte);
 Var N:Word;
 Begin
  For N:=0to 511do
   If not((SectorIndex=0)and((N=106)or(N=107)or(N=112)))Then
    BootChecksum:=ExFatChecksumStep(BootChecksum,B[N])
 End;

Begin
 FormatExFAT:=False;Total:=VolumeTotalSectors;
 If Total=0Then Total:=LongInt(PData.Tracks)*PData.Faces*PData.Sec;
 ClusterBytes:=LongInt(LData.Cluster)*512;
 BitmapBytes:=(ExFatClusterCount+7)div 8;
 BitmapClusters:=(BitmapBytes+ClusterBytes-1)div ClusterBytes;
 UpCaseClusters:=(60+ClusterBytes-1)div ClusterBytes;
 BitmapFirst:=2;UpCaseFirst:=BitmapFirst+BitmapClusters;
 RootCluster:=UpCaseFirst+UpCaseClusters;UsedClusters:=RootCluster-1;
 If UsedClusters>ExFatClusterCount Then Begin WriteLn('Volume exFAT trop petit.');Exit End;

 FillChar(Sec,SizeOf(Sec),0);BootChecksum:=0;
 Sec[0]:=$EB;Sec[1]:=$76;Sec[2]:=$90;Signature:='EXFAT   ';
 For I:=1to 8do Sec[2+I]:=Ord(Signature[I]);
 PutQWordLow(Sec,64,VolumeHiddenSectors);PutQWordLow(Sec,72,Total);
 PutLongLE(Sec,80,ExFatFatOffset);PutLongLE(Sec,84,ExFatFatLength);
 PutLongLE(Sec,88,ExFatHeapOffset);PutLongLE(Sec,92,ExFatClusterCount);
 PutLongLE(Sec,96,RootCluster);PutLongLE(Sec,100,LongInt(Total xor $54414658));
 PutWordLE(Sec,104,$0100);PutWordLE(Sec,106,0);Sec[108]:=9;
 Shift:=0;K:=LData.Cluster;While K>1do Begin Inc(Shift);K:=K div 2 End;
 Sec[109]:=Shift;Sec[110]:=1;Sec[111]:=$80;
 Sec[112]:=Byte((UsedClusters*100)div ExFatClusterCount);
 Sec[510]:=$55;Sec[511]:=$AA;AddBootSectorToChecksum(Sec,0);
 If not WriteLogicalSector(PData,0,Sec)Then Exit;
 If not WriteLogicalSector(PData,12,Sec)Then Exit;
 For I:=1to 10do Begin
  FillChar(Sec,SizeOf(Sec),0);
  If I<=8Then Begin Sec[510]:=$55;Sec[511]:=$AA End;
  AddBootSectorToChecksum(Sec,I);
  If not WriteLogicalSector(PData,I,Sec)Then Exit;
  If not WriteLogicalSector(PData,I+12,Sec)Then Exit
 End;
 FillChar(Sec,SizeOf(Sec),0);
 For I:=0to 127do PutLongLE(Sec,I*4,BootChecksum);
 If not WriteLogicalSector(PData,11,Sec)Then Exit;
 If not WriteLogicalSector(PData,23,Sec)Then Exit;

 FillChar(Sec,SizeOf(Sec),0);
 For I:=24to ExFatFatOffset-1do
  If not WriteLogicalSector(PData,I,Sec)Then Exit;
 For I:=0to ExFatFatLength-1do Begin
  FillChar(Sec,SizeOf(Sec),0);
  For J:=0to 127do Begin
   EntryIndex:=I*128+J;
   If EntryIndex=0Then PutLongLE(Sec,J*4,LongInt($FFFFFFF8))
   Else If EntryIndex=1Then PutLongLE(Sec,J*4,LongInt($FFFFFFFF))
   Else If(EntryIndex>=2)and(EntryIndex<=RootCluster)Then Begin
    If(EntryIndex=BitmapFirst+BitmapClusters-1)or
     (EntryIndex=UpCaseFirst+UpCaseClusters-1)or
     (EntryIndex=RootCluster)Then PutLongLE(Sec,J*4,LongInt($FFFFFFFF))
    Else PutLongLE(Sec,J*4,EntryIndex+1)
   End
  End;
  If not WriteLogicalSector(PData,ExFatFatOffset+I,Sec)Then Exit
 End;
 FillChar(Sec,SizeOf(Sec),0);
 For I:=ExFatFatOffset+ExFatFatLength to ExFatHeapOffset-1do
  If not WriteLogicalSector(PData,I,Sec)Then Exit;

 For I:=0to BitmapClusters*LData.Cluster-1do Begin
  FillChar(Sec,SizeOf(Sec),0);
  If I=0Then For J:=0to UsedClusters-1do
   Sec[J div 8]:=Sec[J div 8]or Byte(1shl(J and 7));
  DataSector:=ExFatHeapOffset+I;
  If not WriteLogicalSector(PData,DataSector,Sec)Then Exit
 End;

 FillChar(Sec,SizeOf(Sec),0);K:=0;
 PutWordLE(Sec,K,$FFFF);Inc(K,2);PutWordLE(Sec,K,$0061);Inc(K,2);
 For I:=Ord('A')to Ord('Z')do Begin PutWordLE(Sec,K,I);Inc(K,2) End;
 PutWordLE(Sec,K,$FFFF);Inc(K,2);PutWordLE(Sec,K,$FF85);Inc(K,2);
 UpCaseChecksum:=0;For I:=0to K-1do
  UpCaseChecksum:=ExFatChecksumStep(UpCaseChecksum,Sec[I]);
 DataSector:=ExFatHeapOffset+(UpCaseFirst-2)*LData.Cluster;
 If not WriteLogicalSector(PData,DataSector,Sec)Then Exit;
 FillChar(Sec,SizeOf(Sec),0);
 For I:=1to UpCaseClusters*LData.Cluster-1do
  If not WriteLogicalSector(PData,DataSector+I,Sec)Then Exit;

 FillChar(Sec,SizeOf(Sec),0);Sec[0]:=$81;Sec[1]:=0;
 PutLongLE(Sec,20,BitmapFirst);PutQWordLow(Sec,24,BitmapBytes);
 Sec[32]:=$82;PutLongLE(Sec,36,UpCaseChecksum);
 PutLongLE(Sec,52,UpCaseFirst);PutQWordLow(Sec,56,60);
 If VolumeLabel<>''Then Begin
  LabelText:=VolumeLabel;While(Length(LabelText)>0)and
   (LabelText[Length(LabelText)]=' ')do Delete(LabelText,Length(LabelText),1);
  Sec[64]:=$83;Sec[65]:=Length(LabelText);
  For I:=1to Length(LabelText)do PutWordLE(Sec,64+I*2,Ord(LabelText[I]))
 End;
 DataSector:=ExFatHeapOffset+(RootCluster-2)*LData.Cluster;
 If not WriteLogicalSector(PData,DataSector,Sec)Then Exit;
 FillChar(Sec,SizeOf(Sec),0);
 For I:=1to LData.Cluster-1do
  If not WriteLogicalSector(PData,DataSector+I,Sec)Then Exit;
 FormatExFAT:=True
End;

Function FormatFAT32(PData:PhysDataType;LData:LogDataType):Boolean;
Var
 Sec:TSectorBuffer;
 Total,DataSectors,Clusters,FreeClusters,DataStart,SectorNumber:LongInt;
 CopyNo,I:LongInt;
 LabelText,FSSignature:String;
Begin
 FormatFAT32:=False;Total:=VolumeTotalSectors;
 If Total=0Then Total:=LongInt(PData.Tracks)*PData.Faces*PData.Sec;
 DataStart:=32+LongInt(LData.FAT)*2;
 DataSectors:=Total-DataStart;Clusters:=DataSectors div LData.Cluster;
 If Clusters<65525Then Begin
  WriteLn('Volume trop petit pour FAT32.');Exit
 End;
 FillChar(Sec,SizeOf(Sec),0);
 For SectorNumber:=0to 31do  If not WriteLogicalSector(PData,SectorNumber,Sec)Then Exit;
 Sec[0]:=$EB;Sec[1]:=$58;Sec[2]:=$90;
 FSSignature:='MSWIN4.1';
 For I:=1to 8do Sec[2+I]:=Ord(FSSignature[I]);
 PutWordLE(Sec,11,512);Sec[13]:=LData.Cluster;PutWordLE(Sec,14,32);
 Sec[16]:=2;PutWordLE(Sec,17,0);PutWordLE(Sec,19,0);Sec[21]:=$F8;
 PutWordLE(Sec,22,0);PutWordLE(Sec,24,PData.Sec);PutWordLE(Sec,26,PData.Faces);
 PutLongLE(Sec,28,VolumeHiddenSectors);PutLongLE(Sec,32,Total);
 PutLongLE(Sec,36,LData.FAT);PutWordLE(Sec,40,0);PutWordLE(Sec,42,0);
 PutLongLE(Sec,44,2);PutWordLE(Sec,48,1);PutWordLE(Sec,50,6);
 Sec[64]:=$80;Sec[66]:=$29;PutLongLE(Sec,67,LongInt(Total xor $32415446));
 If VolumeLabel=''Then LabelText:='NO NAME    'Else LabelText:=VolumeLabel;
 While Length(LabelText)<11do LabelText:=LabelText+' ';
 For I:=1to 11do Sec[70+I]:=Ord(LabelText[I]);
 FSSignature:='FAT32   ';
 For I:=1to 8do Sec[82+I]:=Ord(FSSignature[I]);
 Sec[510]:=$55;Sec[511]:=$AA;
 If not WriteLogicalSector(PData,0,Sec)Then Exit;
 If not WriteLogicalSector(PData,6,Sec)Then Exit;
 FillChar(Sec,SizeOf(Sec),0);PutLongLE(Sec,0,$41615252);
 PutLongLE(Sec,484,$61417272);FreeClusters:=Clusters-1;
 PutLongLE(Sec,488,FreeClusters);PutLongLE(Sec,492,3);
 Sec[508]:=0;Sec[509]:=0;Sec[510]:=$55;Sec[511]:=$AA;
 If not WriteLogicalSector(PData,1,Sec)Then Exit;
 If not WriteLogicalSector(PData,7,Sec)Then Exit;
 For CopyNo:=0to 1do Begin
  For I:=0to LData.FAT-1do Begin
   FillChar(Sec,SizeOf(Sec),0);
   If I=0Then Begin
    PutLongLE(Sec,0,$0FFFFFF8);PutLongLE(Sec,4,LongInt($FFFFFFFF));
    PutLongLE(Sec,8,$0FFFFFFF)
   End;
   If not WriteLogicalSector(PData,32+CopyNo*LData.FAT+I,Sec)Then Exit
  End
 End;
 FillChar(Sec,SizeOf(Sec),0);
 If VolumeLabel<>''Then Begin
  For I:=1to 11do Sec[I-1]:=Ord(LabelText[I]);Sec[11]:=$08
 End;
 If not WriteLogicalSector(PData,DataStart,Sec)Then Exit;
 FillChar(Sec,SizeOf(Sec),0);
 For I:=1to LData.Cluster-1do  If not WriteLogicalSector(PData,DataStart+I,Sec)Then Exit;
 FormatFAT32:=True
End;

Function FormatHPFS(PData:PhysDataType):Boolean;
Const
 HPFSBandSectors=16384;
Var
 Sec:TSectorBuffer;
 Bitmap,DNode:Array[0..2047]of Byte;
 Total,BandCount,BitmapDirStart,BitmapDirSectors:LongInt;
 BadBlockStart,HotfixStart,DirBandStart,DirBandEnd,DirBandSectors:LongInt;
 DirBitmap,RootFNode,RootDNode,MapSector:LongInt;
 Band,I,J,ValidBits,BitNo:LongInt;
 LabelText,HPFSSignature:String;

Function BitmapSectorForBand(B:LongInt):LongInt;
Var
 BandStart,BandEnd:LongInt;
Begin
 BandStart:=B*HPFSBandSectors;
 BandEnd:=BandStart+HPFSBandSectors;
 If BandEnd>Total Then BandEnd:=Total;
 If B=0Then BitmapSectorForBand:=18
 Else If(B and 1)=0Then BitmapSectorForBand:=BandStart
 Else BitmapSectorForBand:=BandEnd-4
End;

Function RangesOverlap(A1,A2,B1,B2:LongInt):Boolean;Begin
 RangesOverlap:=(A1<=B2)and(B1<=A2)
End;

Function IsAllocated(S:LongInt):Boolean;
Var
 K,M:LongInt;
Begin
 IsAllocated:=True;
 If(S<0)or(S>=Total)Then Exit;
 If S<=39Then Exit;
 If(S>=BitmapDirStart)and(S<BitmapDirStart+BitmapDirSectors)Then Exit;
 If(S>=BadBlockStart)and(S<BadBlockStart+4)Then Exit;
 If(S>=HotfixStart)and(S<HotfixStart+4)Then Exit;
 If(S=RootFNode)or((S>=DirBitmap)and(S<DirBitmap+4))or
 ((S>=DirBandStart)and(S<=DirBandEnd))Then Exit;
 For K:=0to BandCount-1do Begin
  M:=BitmapSectorForBand(K);
  If(S>=M)and(S<M+4)Then Exit
 End;
 IsAllocated:=False
End;

Procedure ClearBitmapBit(Var B;N:LongInt);
Var
 A:Array[0..2047]of Byte Absolute B;
Begin
 A[N div 8]:=A[N div 8]and not(Byte(1shl(N and 7)))
End;

Function WriteFour(StartSector:LongInt;Var B):Boolean;
Var
 K:Integer;
 A:Array[0..2047]of Byte Absolute B;
Begin
 WriteFour:=False;
 For K:=0to 3do   If not WriteLogicalSector(PData,StartSector+K,A[K*512])Then Exit;
 WriteFour:=True
End;
Begin
 FormatHPFS:=False;Total:=VolumeTotalSectors;
 If Total=0Then Total:=LongInt(PData.Tracks)*PData.Faces*PData.Sec;
 If Total<8192Then Begin
  WriteLn('Volume trop petit pour HPFS.');Exit
 End;
 BandCount:=(Total+HPFSBandSectors-1)div HPFSBandSectors;
 BitmapDirStart:=22;BitmapDirSectors:=(BandCount*4+511)div 512;
 BadBlockStart:=BitmapDirStart+BitmapDirSectors;
 If BadBlockStart<24Then BadBlockStart:=24;
 HotfixStart:=BadBlockStart+4;
 DirBandSectors:=256;
 If Total<32768Then DirBandSectors:=128;
 DirBandStart:=((Total div 2-DirBandSectors div 2)div 4)*4;
 If DirBandStart<128Then DirBandStart:=128;
 Repeat
 DirBandEnd:=DirBandStart+DirBandSectors-1;
 J:=0;
 For I:=0to BandCount-1do Begin
  MapSector:=BitmapSectorForBand(I);
  If RangesOverlap(DirBandStart-5,DirBandEnd,MapSector,MapSector+3)Then J:=1
 End;
 If J<>0Then Inc(DirBandStart,16)
 Until J=0;
 DirBandEnd:=DirBandStart+DirBandSectors-1;
 If DirBandEnd>=Total-8Then Begin
  WriteLn('Disposition HPFS impossible sur ce volume.');Exit
 End;
 DirBitmap:=DirBandStart-4;RootFNode:=DirBandStart-5;RootDNode:=DirBandStart;
 FillChar(Sec,SizeOf(Sec),0);Sec[0]:=$EB;Sec[1]:=$3C;Sec[2]:=$90;
 Sec[3]:=Ord('I');Sec[4]:=Ord('B');Sec[5]:=Ord('M');Sec[6]:=Ord(' ');
 Sec[7]:=Ord('H');Sec[8]:=Ord('P');Sec[9]:=Ord('F');Sec[10]:=Ord('S');
 PutWordLE(Sec,11,512);Sec[13]:=0;PutWordLE(Sec,14,0);Sec[16]:=0;
 PutWordLE(Sec,17,0);PutWordLE(Sec,19,0);Sec[21]:=$F8;PutWordLE(Sec,22,0);
 PutWordLE(Sec,24,PData.Sec);PutWordLE(Sec,26,PData.Faces);
 PutLongLE(Sec,28,VolumeHiddenSectors);PutLongLE(Sec,32,Total);
 Sec[36]:=$80;Sec[38]:=$29;PutLongLE(Sec,39,LongInt(Total xor $48504653));
 If VolumeLabel=''Then LabelText:='NO NAME    'Else LabelText:=VolumeLabel;
 HPFSSignature:='HPFS    ';
 While Length(LabelText)<11do LabelText:=LabelText+' ';
 For I:=1to 11do Sec[42+I]:=Ord(LabelText[I]);
 For I:=1to 8do Sec[53+I]:=Ord(HPFSSignature[I]);
 Sec[510]:=$55;Sec[511]:=$AA;
 If not WriteLogicalSector(PData,0,Sec)Then Exit;
 FillChar(Sec,SizeOf(Sec),0);
 For I:=1to 15do If not WriteLogicalSector(PData,I,Sec)Then Exit;
 FillChar(Sec,SizeOf(Sec),0);
 PutLongLE(Sec,0,LongInt($F995E849));PutLongLE(Sec,4,LongInt($FA53E9C5));
 Sec[8]:=2;Sec[9]:=2;PutLongLE(Sec,12,RootFNode);PutLongLE(Sec,16,Total);
 PutLongLE(Sec,24,BitmapDirStart);PutLongLE(Sec,32,BadBlockStart);
 PutLongLE(Sec,48,DirBandSectors);PutLongLE(Sec,52,DirBandStart);
 PutLongLE(Sec,56,DirBandEnd);PutLongLE(Sec,60,DirBitmap);
 For I:=1to Length(LabelText)do If I<=32Then Sec[63+I]:=Ord(LabelText[I]);
 PutLongLE(Sec,96,32);
 If not WriteLogicalSector(PData,16,Sec)Then Exit;
 FillChar(Sec,SizeOf(Sec),0);
 PutLongLE(Sec,0,LongInt($F9911849));PutLongLE(Sec,4,LongInt($FA5229C5));
 PutLongLE(Sec,12,HotfixStart);
 If QuickFormat Then Sec[8]:=$20;
 If not WriteLogicalSector(PData,17,Sec)Then Exit;
 FillChar(Sec,SizeOf(Sec),0);
 For I:=0to BitmapDirSectors-1do Begin
  For J:=0to 127do Begin
   Band:=I*128+J;
   If Band<BandCount Then PutLongLE(Sec,J*4,BitmapSectorForBand(Band))
  End;
  If not WriteLogicalSector(PData,BitmapDirStart+I,Sec)Then Exit;
  FillChar(Sec,SizeOf(Sec),0)
 End;
 For I:=0to 7do  If not WriteLogicalSector(PData,BadBlockStart+I,Sec)Then Exit;
 For Band:=0to BandCount-1do Begin
  FillChar(Bitmap,SizeOf(Bitmap),$FF);
  ValidBits:=Total-Band*HPFSBandSectors;
  If ValidBits>HPFSBandSectors Then ValidBits:=HPFSBandSectors;
  For BitNo:=ValidBits to HPFSBandSectors-1do ClearBitmapBit(Bitmap,BitNo);
  For BitNo:=0to ValidBits-1do   If IsAllocated(Band*HPFSBandSectors+BitNo)
  Then ClearBitmapBit(Bitmap,BitNo);
  If not WriteFour(BitmapSectorForBand(Band),Bitmap)Then Exit
 End;
 FillChar(Bitmap,SizeOf(Bitmap),$FF);ClearBitmapBit(Bitmap,0);
 For BitNo:=DirBandSectors div 4to HPFSBandSectors-1do  ClearBitmapBit(Bitmap,BitNo);
 If not WriteFour(DirBitmap,Bitmap)Then Exit;
 FillChar(Sec,SizeOf(Sec),0);
 PutLongLE(Sec,0,LongInt($F7E40AAE));Sec[12]:=1;Sec[13]:=Ord('\');
 PutLongLE(Sec,28,RootFNode);PutWordLE(Sec,54,$0100);
 Sec[56]:=$20;Sec[60]:=7;Sec[61]:=1;PutWordLE(Sec,62,20);
 PutLongLE(Sec,64,0);PutLongLE(Sec,68,4);PutLongLE(Sec,72,RootDNode);
 PutWordLE(Sec,184,196);
 If not WriteLogicalSector(PData,RootFNode,Sec)Then Exit;
 FillChar(DNode,SizeOf(DNode),0);PutLongRaw(DNode,0,LongInt($77E40AAE));
 PutLongRaw(DNode,4,86);DNode[8]:=1;PutLongRaw(DNode,12,RootFNode);
 PutLongRaw(DNode,16,RootDNode);
 PutWordRaw(DNode,20,34);DNode[22]:=$01;DNode[23]:=$10;
 PutLongRaw(DNode,24,RootFNode);DNode[50]:=2;DNode[51]:=1;DNode[52]:=1;
 PutWordRaw(DNode,54,32);DNode[56]:=$08;DNode[84]:=1;DNode[85]:=$FF;
 If not WriteFour(RootDNode,DNode)Then Exit;
 FormatHPFS:=True
End;

Function Logical4mat(Drive:Byte;PData:PhysDataType;LData:LogDataType):Boolean;
Var
 Status:Byte;
 NmSec:Word;
 TotalLong,MetaSectors,SectorNumber:LongInt;
 I,AktSec,AktSide,AktTrack:Byte;
 Nm:Integer;
 TrackBuf:TrackBufType;
 ByteWrited:Word;
Begin
 If RequestedFileSystem=FS_NTFS Then Begin
  Logical4mat:=FormatNTFS(PData,LData);Exit
 End;
 If RequestedFileSystem=FS_EXFAT Then Begin
  Logical4mat:=FormatExFAT(PData,LData);Exit
 End;
 If RequestedFileSystem=FS_FAT32 Then Begin
  Logical4mat:=FormatFAT32(PData,LData);Exit
 End;
 If RequestedFileSystem=FS_HPFS Then Begin
  Logical4mat:=FormatHPFS(PData);Exit
 End;
 If HardDiskMode or(InFile and(ImageVolumeStart>0))Then FillChar(TrackBuf,512,0)
 Else FillChar(TrackBuf,Word(PData.Sec)*512,0); { Vide tampon }
  { Secteur de demarrage: Partie fixe }
 System.Move(Maskboot,TrackBuf,102);
 System.Move(BootMsg[1],TrackBuf[1,103],Byte(BootMsg[0]));
 TrackBuf[1,511]:=$55;
 TrackBuf[2,0]:=$AA;
 TrackBuf[1,510]:=$55;
 TrackBuf[1,511]:=$AA;
  { Secteur de demarrage: Partie variable }
 If VolumeTotalSectors>0Then TotalLong:=VolumeTotalSectors
 Else TotalLong:=LongInt(PData.Tracks)*PData.Sec*PData.Faces;
 If TotalLong<=65535Then NmSec:=TotalLong Else NmSec:=0;
 TrackBuf[1,12]:=Lo(512);
 TrackBuf[1,13]:=Hi(512);
 TrackBuf[1,14]:=LData.Cluster;  { Longueur de l'unite d'allocation }
 TrackBuf[1,18]:=LData.RootSize; { Nombre Entrees dans r├⌐pertoires }
 TrackBuf[1,20]:=lo(NmSec);      { Nombre total de secteur }
 TrackBuf[1,21]:=hi(NmSec);      { sur la disquette }
 TrackBuf[1,22]:=LData.Media;    { Descripteur support }
 TrackBuf[1,23]:=LData.FAT;      { Longueur des FAT }
 TrackBuf[1,25]:=PData.Sec;      { Secteurs par piste }
 TrackBuf[1,27]:=PData.Faces;    { Nombre de faces }
 { Reecriture du BPB aux offsets DOS reels (0-based). }
 TrackBuf[1,11]:=Lo(512);TrackBuf[1,12]:=Hi(512);
 TrackBuf[1,13]:=LData.Cluster;
 TrackBuf[1,14]:=1;TrackBuf[1,15]:=0;TrackBuf[1,16]:=2;
 TrackBuf[1,17]:=Lo(LData.RootSize);TrackBuf[1,18]:=Hi(LData.RootSize);
 TrackBuf[1,19]:=Lo(NmSec);TrackBuf[1,20]:=Hi(NmSec);
 TrackBuf[1,21]:=LData.Media;
 TrackBuf[1,22]:=Lo(LData.FAT);TrackBuf[1,23]:=Hi(LData.FAT);
 TrackBuf[1,24]:=Lo(PData.Sec);TrackBuf[1,25]:=Hi(PData.Sec);
 TrackBuf[1,26]:=Lo(PData.Faces);TrackBuf[1,27]:=Hi(PData.Faces);
 TrackBuf[1,28]:=Byte(VolumeHiddenSectors);
 TrackBuf[1,29]:=Byte(VolumeHiddenSectors shr 8);
 TrackBuf[1,30]:=Byte(VolumeHiddenSectors shr 16);
 TrackBuf[1,31]:=Byte(VolumeHiddenSectors shr 24);
 If NmSec=0Then Begin
  TrackBuf[1,32]:=Byte(TotalLong);TrackBuf[1,33]:=Byte(TotalLong shr 8);
  TrackBuf[1,34]:=Byte(TotalLong shr 16);TrackBuf[1,35]:=Byte(TotalLong shr 24)
 End;
  { Creer FAT et sa copie (contient 00) }
 TrackBuf[2,1]:=LData.Media;
 TrackBuf[2,2]:=$FF;
 TrackBuf[2,3]:=$FF;
 If LData.FAT+2<=PData.Sec Then Begin
  TrackBuf[LData.FAT+2,1]:=LData.Media;
  TrackBuf[LData.FAT+2,2]:=$FF;
  TrackBuf[LData.FAT+2,3]:=$FF
 End;
 { Premiers descripteurs FAT aux offsets reels de chaque copie. }
 TrackBuf[2,0]:=LData.Media;TrackBuf[2,1]:=$FF;TrackBuf[2,2]:=$FF;
 If LData.FAT+2<=PData.Sec Then Begin
  TrackBuf[LData.FAT+2,0]:=LData.Media;
  TrackBuf[LData.FAT+2,1]:=$FF;TrackBuf[LData.FAT+2,2]:=$FF
 End;
 If ActiveFATBits=16 Then Begin
  TrackBuf[2,3]:=$FF;
  If LData.FAT+2<=PData.Sec Then TrackBuf[LData.FAT+2,3]:=$FF
 End;
 If HardDiskMode or(InFile and(ImageVolumeStart>0))Then Begin
  If WriteLogicalSector(PData,0,TrackBuf[1,0])Then Status:=0 Else Status:=1
 End
 Else If(InFile)Then Begin
  Seek(FileImg,0);
  BlockWrite(FileImg,TrackBuf,Word(PData.Sec)*512,ByteWrited);
  If ByteWrited=(Word(PData.Sec)*512)Then Status:=0
  Else Status:=1;
 End
 Else
 Status:=WriteTrack(Drive,0,0,1,PData.Sec,TrackBuf);
 If Status<>0Then Logical4mat:=false
 else
 Begin
  FillChar(TrackBuf,512,0);
  If HardDiskMode or(InFile and(ImageVolumeStart>0))Then Begin
   MetaSectors:=1+LongInt(LData.FAT)*2+
   (LongInt(LData.RootSize)*32+511)div 512;
   SectorNumber:=1;
   While(SectorNumber<MetaSectors)and(Status=0)do Begin
    If not WriteLogicalSector(PData,SectorNumber,TrackBuf)Then Status:=1;
    Inc(SectorNumber)
   End;
   Nm:=0
  End Else
  Begin
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
   If(InFile)Then Begin
    BlockWrite(FileImg,TrackBuf,512,ByteWrited);
    If ByteWrited=512 Then Status:=0
    Else Status:=1;
   End
   Else
   Status:=WriteTrack(Drive,AktSide,AktTrack,AktSec,1,TrackBuf);
   Inc(i);
   Until(i>Nm)or(Status<>0);
  End;
  If Status=0Then Begin
   FillChar(TrackBuf,512,0);TrackBuf[1,0]:=LData.Media;
   TrackBuf[1,1]:=$FF;TrackBuf[1,2]:=$FF;
   If ActiveFATBits=16 Then TrackBuf[1,3]:=$FF;
   If not WriteLogicalSector(PData,1,TrackBuf)Then Status:=1
   Else If not WriteLogicalSector(PData,1+LData.FAT,TrackBuf)Then Status:=1
  End;
  If Status=0Then Logical4mat:=WriteVolumeLabel(PData,LData)
  Else Logical4mat:=False;
 End;
End;

BEGIN
 HardDiskMode:=False;VolumeTotalSectors:=0;VolumeHiddenSectors:=0;
 Language:=_French;
 TmpLanguage:=GetEnv('LANGUAGE');
 If TmpLanguage<>''Then Begin
  If TmpLanguage[1]='"'Then TmpLanguage:=Copy(TmpLanguage,2,255);
  If StrToUpper(Copy(TmpLanguage,1,2))='EN'Then Language:=_English Else
  If(StrToUpper(Copy(TmpLanguage,1,2))='DE')or
   (StrToUpper(Copy(TmpLanguage,1,2))='GR')Then Language:=_Germany Else
  If StrToUpper(Copy(TmpLanguage,1,2))='IT'Then Language:=_Italian Else
  If StrToUpper(Copy(TmpLanguage,1,2))='SP'Then Language:=_Spain;
 End;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
 (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  Case Language of
  _Germany:
  Begin
   WriteLn('Formatiert einen Datentraeger fuer die Verwendung unter DOS.');
   WriteLn;
   WriteLn('Syntax: FORMAT Laufwerk: [Format] [NV] [/F:Groesse] [/V:Name]');
   WriteLn('               [/T:n] [/N:n] [/Q] [/U] [/S]');
   WriteLn('        FORMAT Datei [160|180|320|360|720|1200|1440|2880] [Optionen]');
   WriteLn('        FORMAT Platte.img /CREATE:GroesseMB [/TYPE:RAW|VDI] [/FS:FAT16]');
   WriteLn;
   WriteLn(' Datei        Verwendet die angegebene Datei als Diskettenabbild');
   WriteLn(' C: bis Z:    Formatiert unter echtem DOS eine FAT12/FAT16/FAT32-');
   WriteLn('              oder HPFS-Partition; das aktive Laufwerk wird abgelehnt');
   WriteLn(' NV           Deaktiviert die Ueberpruefung');
   WriteLn(' /1           Formatiert nur eine Diskettenseite');
   WriteLn(' /4           Formatiert 360 KB in einem 1,2-MB-Laufwerk');
   WriteLn(' /8           Verwendet acht Sektoren pro Spur');
   WriteLn(' /A:Groesse   Groesse der Zuordnungseinheit: 512 bis 32768 Byte');
   WriteLn(' /B           Reserviert zusammenhaengenden Platz fuer Startdateien');
   WriteLn('              und kann nicht gemeinsam mit /S verwendet werden');
   WriteLn(' /CREATE      Erstellt ein neues Diskettenabbild');
   WriteLn(' /CREATE:MB   Erstellt ein Festplattenabbild mit MBR und Partition');
   WriteLn(' /F           Erzwingt das angegebene Diskettenformat');
   WriteLn(' /F:Groesse   160, 180, 320, 360, 720, 1200, 1440 oder 2880 KB');
   WriteLn(' /FS:System   FAT, FAT12, FAT16, FAT32, exFAT, NTFS oder HPFS');
   WriteLn('              FAT32, exFAT, NTFS und HPFS benoetigen eine Festplatte/Abbild');
   WriteLn(' /N:n         Anzahl der Sektoren pro Spur');
   WriteLn(' /Q           Schnellformatierung der Dateisystemtabellen');
   WriteLn(' /S           Kopiert IO.SYS, MSDOS.SYS und COMMAND.COM');
   WriteLn(' /S:Familie   Waehlt die DOS-Familie (Vorgabe: MS-DOS):');
   WriteLn('               MS-DOS   -> IO.SYS, MSDOS.SYS, COMMAND.COM');
   WriteLn('               PC-DOS   -> IBMBIO.COM, IBMDOS.COM, COMMAND.COM');
   WriteLn('               DR-DOS   -> IBMBIO.COM, IBMDOS.COM, COMMAND.COM');
   WriteLn('               FreeDOS  -> KERNEL.SYS, COMMAND.COM');
   WriteLn('               RxDOS    -> RXDOSBIO.SYS, RXDOS.SYS, COMMAND.COM');
   WriteLn('               Win95    -> IO.SYS, MSDOS.SYS, COMMAND.COM');
   WriteLn('               PTS-DOS  -> PTSBIO.SYS, PTSDOS.SYS, COMMAND.COM');
   WriteLn('               OS/2     -> OS2BOOT, OS2LDR, OS2KRNL');
   WriteLn('               WinNT    -> NTLDR, NTDETECT.COM, BOOT.INI');
   WriteLn(' /T:n         Anzahl der Spuren');
   WriteLn(' /TYPE:VDI    Erstellt ein festes VirtualBox-VDI-Abbild');
   WriteLn(' /TYPE:RAW    Erstellt ein RAW-Abbild (Vorgabe)');
   WriteLn(' /U           Vollstaendige, nicht rueckgaengige Formatierung');
   WriteLn(' /V:Name      Datentraegername mit hoechstens 11 Zeichen');
  End;
  _English:
  Begin
   WriteLn('Formats a disk for use with DOS.');
   WriteLn;
   WriteLn(
   'Syntax: FORMAT drive: [format] [NV] [/F:size] [/V:label] [/T:n] [/N:n] [/Q] [/U] [/S]');
   WriteLn(
   '        FORMAT file [360|720|1200|1440] [/V:label] [/T:n] [/N:n] [/Q] [/U] [/S]');
   WriteLn('        FORMAT disk.img /CREATE:sizeMB [/TYPE:RAW|VDI] [/FS:FAT16]');
   WriteLn('  C:..Z:    Under real DOS, logically formats an existing FAT12/FAT16');
   WriteLn('             partition. The active DOS drive is always refused.');
   WriteLn('  /1        Formats one side only.');
   WriteLn('  /4        Formats a 360 KB disk in a 1.2 MB drive.');
   WriteLn('  /8        Uses eight sectors per track.');
   WriteLn('  /A:size   Specifies the allocation-unit size: 512 to 32768 bytes.');
   WriteLn('  /B        Reserves contiguous space for the two system files.');
   WriteLn('  /CREATE[:MB] Creates a new floppy image or hard-disk image.');
   WriteLn('  /F:size   Selects floppy size: 160, 180, 320, 360, 720,');
   WriteLn('             1200, 1440 or 2880 KB (floppy drives only).');
   WriteLn('  /FS:name  Selects FAT, FAT12, FAT16, FAT32, exFAT, NTFS or HPFS.');
   WriteLn('             FAT32, exFAT, NTFS and HPFS require a hard-disk image.');
   WriteLn('  /N:n      Specifies the number of sectors per track.');
   WriteLn('  /Q        Performs a quick format of filesystem tables only.');
   WriteLn('  /S        Copies IO.SYS, MSDOS.SYS and COMMAND.COM.');
   WriteLn('  /S:family Selects MS-DOS, PC-DOS, DR-DOS, FreeDOS, RxDOS,');
   WriteLn('             Win95, PTS-DOS, OS/2 or WinNT.');
   WriteLn('  /T:n      Specifies the number of tracks.');
   WriteLn('  /TYPE:VDI Creates a fixed VirtualBox VDI image; RAW is the default.');
   WriteLn('  /U        Performs an unconditional full format.');
   WriteLn('  /V:label  Specifies the volume label (11 characters maximum).');
  End;
  Else
  Begin
   WriteLn('FORMAT - Cette commande permet de formater un unit'+#130+' de disquette.');
   WriteLn;
   WriteLn(
   'Syntaxe: FORMAT unite: [format] [NV] [/F:taille] [/V:nom] [/T:n] [/N:n] [/Q] [/U] [/S]');
   WriteLn(
   '         FORMAT fichier [360|720|1200|1440] [/V:nom] [/T:n] [/N:n] [/Q] [/U] [/S]');
   WriteLn('         FORMAT disque.img /CREATE:tailleMo [/TYPE:RAW|VDI] [/FS:FAT16]');
   WriteLn;
   WriteLn('fichier       Utiliser le fichier sp'+#130+'cifi'+#130+' comme disquette');
   WriteLn(' C: a Z:      Sous DOS reel, formate logiquement une partition FAT12/FAT16');
   WriteLn('              existante; le lecteur DOS actif est toujours refuse');
   WriteLn('  NV          Pas de v'+#130+'rification');
   WriteLn(' /1           Formate une seule face de la disquette');
   WriteLn(' /4           Formate une disquette 360 Ko dans un lecteur 1,2 Mo');
   WriteLn(' /8           Utilise huit secteurs par piste');
   WriteLn(' /A:taille    Taille d''unite d''allocation: 512 a 32768 octets');
   WriteLn(' /B           Reserve des clusters contigus pour les deux fichiers');
   WriteLn('              de demarrage; cette option est incompatible avec /S');
   WriteLn(' /CREATE      Cree explicitement une nouvelle image de disquette');
   WriteLn(' /CREATE:Mo   Cree une image de disque dur avec MBR et partition FAT');
   WriteLn(' /F           Force a utiliser ce format');
   WriteLn(' /F:taille    Format de disquette: 160, 180, 320, 360, 720,');
   WriteLn('              1200, 1440 ou 2880 Ko (lecteur seulement)');
   WriteLn(' /FS:systeme  FAT, FAT12, FAT16, FAT32, exFAT, NTFS ou HPFS');
   WriteLn('              FAT32, exFAT, NTFS et HPFS exigent un disque dur ou une image');
   WriteLn(' /N:n         Indique le nombre de secteurs par piste');
   WriteLn(' /Q           Reinitialise rapidement le secteur de demarrage, les FAT');
   WriteLn('              et le repertoire racine sans parcourir toutes les pistes');
   WriteLn(' /S           Copie IO.SYS, MSDOS.SYS et COMMAND.COM');
   WriteLn(' /S:famille   S'+#130+'lectionne la famille DOS (defaut: MS-DOS) :');
   WriteLn('               MS-DOS   -> IO.SYS, MSDOS.SYS, COMMAND.COM');
   WriteLn('               PC-DOS   -> IBMBIO.COM, IBMDOS.COM, COMMAND.COM');
   WriteLn('               DR-DOS   -> IBMBIO.COM, IBMDOS.COM, COMMAND.COM');
   WriteLn('               FreeDOS  -> KERNEL.SYS, COMMAND.COM');
   WriteLn('               RxDOS    -> RXDOSBIO.SYS, RXDOS.SYS, COMMAND.COM');
   WriteLn('               Win95    -> IO.SYS, MSDOS.SYS, COMMAND.COM');
   WriteLn('               PTS-DOS  -> PTSBIO.SYS, PTSDOS.SYS, COMMAND.COM');
   WriteLn('               OS/2     -> OS2BOOT, OS2LDR, OS2KRNL');
   WriteLn('               WinNT    -> NTLDR, NTDETECT.COM, BOOT.INI');
   WriteLn(' /T:n         Indique  le nombre de pistes du disque');
   WriteLn(' /TYPE:VDI    Cree une image VDI fixe compatible VirtualBox');
   WriteLn(' /TYPE:RAW    Cree une image disque brute (valeur par defaut)');
   WriteLn(' /U           Effectue un formatage complet et inconditionnel');
   WriteLn(' /V:nom       Indique le nom du volume (11 caracteres maximum)');
  End;
 End;
End
 Else
If ParamStr(1)='--version'Then Begin
 WriteLn('FORMAT 1.0 - Clone Pascal de MSDOS-0, PCDOS-0, ',
         'OS2-0, DEV-COOLS et corail ');
 WriteLn('Licence MIT');
 WriteLn;
 WriteLn('�crit par Sylvain Maltais');
End
 Else
If ParamCount>=1Then Begin
 InFile:=False;
 Param:=ParamStr(1);
 If(Length(Param)=2)and(Param[2]=':')Then Begin
  AktDrv:=Byte(UpCase(Param[1]))-65;
  If AktDrv>=2Then Begin
   HardDiskMode:=True;
   {$IFDEF FPC}
    WriteLn('Le formatage direct de C: a Z: est disponible uniquement sous DOS reel');
    WriteLn('avec la version compilee par Turbo Pascal.');
    Halt(3)
   {$ELSE}
    If GetCurrentDOSDrive=AktDrv Then Begin
     WriteLn('Refus de formater le lecteur DOS actif ',Chr(AktDrv+65),':.');
     WriteLn('Demarrez depuis une autre unite pour formater cette partition.');Halt(5)
    End;
    If not ParseOptions(2,Param)Then Halt(4);
    If(Param<>'')or ForceFormat Then Begin
     WriteLn('Les tailles et formats physiques ne s''appliquent pas aux disques durs.');
     Halt(4)
    End;
    If not PrepareHardDisk(AktDrv,PData,LData)Then Halt(3);
    If not ConfigureFileSystem(PData,LData)Then Halt(4);
    If(SystemTransfer or BootReserve)and not SystemFilesAvailable Then Halt(6);
    WriteLn('ATTENTION: toutes les donnees de ',Chr(AktDrv+65),
    ': seront perdues (',VolumeTotalSectors,' secteurs).');
    Write('Tapez OUI pour confirmer: ');ReadLn(Confirmation);
    If StrToUpper(Confirmation)<>'OUI'Then Begin
     WriteLn('Formatage annule.');Halt(5)
    End;
    If QuickFormat Then WriteLn('Formatage logique rapide de la partition.')
    Else WriteLn('Formatage logique DOS de la partition (aucun formatage physique).');
    Ok:=Logical4mat(AktDrv,PData,LData);
    If Ok and(SystemTransfer or BootReserve)Then Ok:=TransferSystemFiles(PData,LData);
    If not Ok Then Begin
     WriteLn('Une erreur a interrompu le formatage du disque dur.');Halt(1)
    End;
    WriteLn('Formatage termine.');Halt(0)
   {$ENDIF}
  End;
  HardDiskMode:=False;VolumeTotalSectors:=0;VolumeHiddenSectors:=0;
  AktDrvType:=GetDrvType(AktDrv);
  If AktDrvType>0Then Begin
   If not ParseOptions(2,Param)Then Halt(4);
   If Param=''Then Case AktDrvType of
   dtDD525:Param:='360';dtHD525:Param:='1200';dtDD35:Param:='720';dtHD35:Param:='1440'
  End;
  If Format360In1200 and(AktDrvType<>dtHD525)Then Begin
   WriteLn('/4 exige un lecteur 5 1/4 de 1,2 Mo.');Halt(4)
  End;
  If Get4matParam(Param,AktDrvType,PData,LData)and ApplyTrackOption(PData,LData)Then Begin
   If(SystemTransfer or BootReserve)and not SystemFilesAvailable Then Halt(6);
   If UnconditionalFormat Then WriteLn('Formatage complet et inconditionnel.');
   InitDsk(AktDrv,PData);
   GetIntVec($1E,AncDDPT);
   SetIntVec($1E,PData.DDPT);
   If QuickFormat Then Begin
    WriteLn('Formatage rapide des tables du disque.');Ok:=True
   End
   Else Ok:=Phys4mat(AktDrv,PData,not NoVerify);
   If(Ok)Then Begin
    WriteLn;
    Writeln('Ecriture du secteur de demarrage et des FAT ');
    Ok:=Logical4mat(AktDrv,PData,LData);
    If Ok and(SystemTransfer or BootReserve)Then Ok:=TransferSystemFiles(PData,LData)
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
  End;
 End
 Else
 Begin
  WriteLn('Le lecteur de disquettes demande n''existe pas');
  Halt(3);
 End
End
Else
Begin
 InFile:=True;
 HardDiskMode:=False;VolumeTotalSectors:=0;VolumeHiddenSectors:=0;
 KS:=1440;
 ImageName:=Param;
 If not ParseOptions(2,Param)Then Halt(4);
 If not ImageTypeSpecified Then  If StrToUpper(Copy(ImageName,Length(ImageName)-3,4))=
 '.VDI'Then ImageContainer:=IC_VDI;
 If(SystemTransfer or BootReserve)and not SystemFilesAvailable Then Halt(6);
 WriteLn('Formatage du fichier d''image : ',ImageName);
 ImageDataOffset:=0;ImageVolumeStart:=0;ImageVirtualSectors:=0;
 If(ImageContainer=IC_VDI)and(CreateImage)and(CreateSizeMB=0)Then Begin
  WriteLn('/CREATE:taille_en_Mo est obligatoire pour creer une image VDI.');Halt(4)
 End;
 If CreateSizeMB>0Then Begin
  {$I-}Assign(FileImg,ImageName);Reset(FileImg,1);{$I+}
  If IOResult=0Then Begin
   Close(FileImg);WriteLn('Le fichier existe deja; /CREATE refuse de l''ecraser.');Halt(5)
  End;
  Assign(FileImg,ImageName);
  If not CreateDiskImageContainer(CreateSizeMB)Then Begin
   WriteLn('Impossible de creer le conteneur d''image.');Halt(5)
  End;
  PData:=PHYS1440;PData.Sec:=63;PData.Faces:=16;PData.Tracks:=1;
  LData:=LOG1440;LData.Media:=$F8;LData.RootSize:=512;
  If not ConfigureFileSystem(PData,LData)Then Begin
   Close(FileImg);Halt(4)
  End;
  WriteLn('Image de disque dur creee: ',CreateSizeMB,' Mo, conteneur ',
  StrToUpper(Copy(ImageName,Length(ImageName)-3,4)),'.');
  Ok:=Logical4mat(AktDrv,PData,LData);
  If Ok and(SystemTransfer or BootReserve)Then Ok:=TransferSystemFiles(PData,LData);
  Close(FileImg);
  If not Ok Then Begin
   WriteLn('Erreur pendant le formatage de l''image.');Halt(1)
  End;
  WriteLn('Image creee et formatee.');Halt(0)
 End;
 If(ImageContainer=IC_VDI)and not CreateImage Then Begin
  {$I-}Assign(FileImg,ImageName);FileMode:=2;Reset(FileImg,1);{$I+}
  If IOResult<>0Then Begin
   WriteLn('Impossible d''ouvrir l''image VDI.');Halt(5)
  End;
  If not DetectFixedVDI or not PrepareOpenedHardDiskImage(PData,LData)Then Begin
   Close(FileImg);Halt(4)
  End;
  If not ConfigureFileSystem(PData,LData)Then Begin
   Close(FileImg);Halt(4)
  End;
  If(RequestedFileSystem=FS_HPFS)and not UpdateImagePartitionType($07)Then Begin
   Close(FileImg);WriteLn('Impossible de modifier le type de partition HPFS.');Halt(5)
  End;
  If(RequestedFileSystem=FS_FAT32)and not UpdateImagePartitionType($0C)Then Begin
   Close(FileImg);WriteLn('Impossible de modifier le type de partition FAT32.');Halt(5)
  End;
  If(RequestedFileSystem=FS_EXFAT)and not UpdateImagePartitionType($07)Then Begin
   Close(FileImg);WriteLn('Impossible de modifier le type de partition exFAT.');Halt(5)
  End;
  If(RequestedFileSystem=FS_NTFS)and not UpdateImagePartitionType($07)Then Begin
   Close(FileImg);WriteLn('Impossible de modifier le type de partition NTFS.');Halt(5)
  End;
  Ok:=Logical4mat(AktDrv,PData,LData);
  If Ok and(SystemTransfer or BootReserve)Then Ok:=TransferSystemFiles(PData,LData);
  Close(FileImg);
  If not Ok Then Begin
   WriteLn('Erreur pendant le formatage VDI.');Halt(1)
  End;
  WriteLn('Image VDI formatee.');Halt(0)
 End;
 If(ImageContainer=IC_RAW)and not CreateImage Then Begin
  {$I-}Assign(FileImg,ImageName);FileMode:=2;Reset(FileImg,1);{$I+}
  If IOResult=0Then Begin
   If FileSize(FileImg)>LongInt(2880)*1024Then Begin
    ImageVirtualSectors:=FileSize(FileImg)div 512;
    If not PrepareOpenedHardDiskImage(PData,LData)Then Begin
     Close(FileImg);Halt(4)
    End;
    If not ConfigureFileSystem(PData,LData)Then Begin
     Close(FileImg);Halt(4)
    End;
    If(RequestedFileSystem=FS_HPFS)and not UpdateImagePartitionType($07)Then Begin
     Close(FileImg);WriteLn('Impossible de modifier le type de partition HPFS.');Halt(5)
    End;
    If(RequestedFileSystem=FS_FAT32)and not UpdateImagePartitionType($0C)Then Begin
     Close(FileImg);WriteLn('Impossible de modifier le type de partition FAT32.');Halt(5)
    End;
    If(RequestedFileSystem=FS_EXFAT)and not UpdateImagePartitionType($07)Then Begin
     Close(FileImg);WriteLn('Impossible de modifier le type de partition exFAT.');Halt(5)
    End;
    If(RequestedFileSystem=FS_NTFS)and not UpdateImagePartitionType($07)Then Begin
     Close(FileImg);WriteLn('Impossible de modifier le type de partition NTFS.');Halt(5)
    End;
    Ok:=Logical4mat(AktDrv,PData,LData);
    If Ok and(SystemTransfer or BootReserve)Then Ok:=TransferSystemFiles(PData,LData);
    Close(FileImg);
    If not Ok Then Begin
     WriteLn('Erreur pendant le formatage RAW.');Halt(1)
    End;
    WriteLn('Image RAW de disque dur formatee.');Halt(0)
   End;
   Close(FileImg)
  End
 End;
 ExistingQuickImage:=False;
   {$I-}Assign(FileImg,ImageName);
 If QuickFormat Then Begin
  FileMode:=2;Reset(FileImg,1);
  If IOResult=0Then ExistingQuickImage:=True Else Rewrite(FileImg,1)
 End Else Rewrite(FileImg,1);{$I+}
 If IOResult<>0Then Begin
  WriteLn('Impossible de creer le fichier image.');Halt(5)
 End;
 PData:=PHYS1440;
 LData:=LOG1440;
 If Param<>''Then Begin
  If Param='160'Then Begin
   PData:=PHYS160;LData:=LOG160;KS:=160
  End
  Else If Param='180'Then Begin
   PData:=PHYS180;LData:=LOG180;KS:=180
  End
  Else If Param='320'Then Begin
   PData:=PHYS320;LData:=LOG320;KS:=320
  End
  Else If Param='360'Then Begin
   PData:=PHYS360;
   LData:=LOG360;
   KS:=360;
  End
  Else
  If Param='720'Then Begin
   PData:=PHYS720;
   LData:=LOG720;
   KS:=720;
  End
  Else
  If Param='1200'Then Begin
   PData:=PHYS1200;
   LData:=LOG1200;
   KS:=1200;
  End
  Else
  If Param='1440'Then Begin
   PData:=PHYS1440;
   LData:=LOG1440;
   KS:=1440;
  End
  Else
  If Param='2880'Then Begin
   PData:=PHYS2880;LData:=LOG2880;KS:=2880;
  End
 End;
 If not ApplyTrackOption(PData,LData)Then Begin
  Close(FileImg);Halt(4)
 End;
 KS:=LongInt(PData.Tracks)*PData.Faces*PData.Sec div 2;
 If ExistingQuickImage and(FileSize(FileImg)<>LongInt(KS)*1024)Then Begin
  WriteLn('La taille de l''image existante ne correspond pas a la geometrie /T et /N.');
  Close(FileImg);Halt(4)
 End;
 If QuickFormat Then WriteLn('Formatage rapide des tables de l''image.');
 If UnconditionalFormat Then WriteLn('Formatage complet et inconditionnel.');
 Seek(FileImg,0);
 WriteLn('Ecriture du secteur de d'+#130+'marrage et des FAT');
 Ok:=Logical4mat(AktDrv,PData,LData);
 If Ok and(SystemTransfer or BootReserve)Then Ok:=TransferSystemFiles(PData,LData);
 Seek(FileImg,KS*1024);
 Truncate(FileImg);
 Close(FileImg);
 If not Ok Then Begin
  WriteLn('Une erreur a interrompu le formatage ou le transfert systeme.');Halt(1)
 End;
End;
End
Else
WriteLn('Parametre requis !')
END.
