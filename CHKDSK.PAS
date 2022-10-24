{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program CHKDSK;

{$A-}

Uses DOS;

Type
 {Structure de lecture pour le disque }
 SecPosType=Record
  Head:Byte;
  Sector:Byte;
  Track:Byte;
 End;

 {Structure de partition}
 PartEntry=Record
  Status:Byte;
  StartSec:SecPosType;
  PartType:Byte;
  EndSec:SecPosType;
  SecOfs,NumSec:LongInt;
 End;

 PartSec=Record { dÇcrit le secteur de partition }
  BootCode:Array[0..$1BD]of Byte;    { Code de dÇmarrage du disque dur }
  PartTable:Array[0..3]of PartEntry; { Table des partitions de disque dur }
  IdCode:Word;                       { Signature: AA55h }
 End;

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage,CurrParam,FileName:String;
 FileSource:File;
 ByteReaded:Integer;
 InfoLabel:SearchRec;
 DateLabel:DateTime;
 CurrDisk:Byte;
 I:Integer;
 Erreur:Word;
 StartPos,NumberHiddenFile:LongInt;
 BufferLoaded:Boolean;
 BufferSector0,Buffer:Array[0..511]of Byte;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function PadZeroLeft(Value:Integer;Space:Byte):String;
Var
 S:String;
Begin
 Str(Value,S);
 While Length(S)<Space do S:='0'+S;
 PadZeroLeft:=S;
End;

Function LTrim(s:String):String;
Var
 i:Integer;
Begin
 i:=1;
 While(i<=Length(s)) and (s[i] in [#9,' ']) do Inc(i);
 Delete(s,1,i-1);
 LTrim:=s;
End;

Function RTrim(s:String):String;
Var
 i:Integer;
Begin
 i:=Length(s);
 While (i>0)and(s[i]in[#9,' '])do Dec(i);
 s[0]:=Chr(i);
 RTrim:=S;
End;

Function Trim(s:String):String;Begin
 Trim:=LTrim(RTrim(s));
End;

Function ByteHex2Str(value:Byte):String;
Const
 matrix:Array[0..15]of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
 ByteHex2Str:=matrix[(value shr 4) and $0F]+matrix[value and $F];
End;

Function HexWord2Str(value:Word):String;Begin
 HexWord2Str:=ByteHex2Str(Hi(value))+ByteHex2Str(Lo(value));
End;

Function LongHex2Str(value:LongInt):String;
Begin
 LongHex2Str:=ByteHex2Str((value shr 24)and $FF)+
              ByteHex2Str((value shr 16)and $FF)+
              ByteHex2Str((value shr 8)and $FF)+
              ByteHex2Str(value and $FF);
End;

Function GetConvMemory:Word;
Var
 Regs:Registers;
Begin
 Regs.AX:=0;
 Intr($12,Regs);
 GetConvMemory:=Regs.AX;
End;

Function GetFreeMemory:LongInt;
Var
 Regs:Registers;
Begin
 Regs.AH:=$48;
 Regs.BX:=$FFFF;
 Intr($21,Regs);
 GetFreeMemory:=LongInt(Regs.AX)*16;
End;

Function GetCurrentDisk:Char;
Var
 CurrentDir:String;
Begin
 GetDir(0,CurrentDir);
 GetCurrentDisk:=CurrentDir[1];
End;

Function GetDiskLabel(Dsk:Byte):String;
Var
 CurrentDir:String;
Begin
 If Dsk=0Then GetDir(0,CurrentDir)
         Else CurrentDir:=Char(Dsk+64);
 FindFirst(CurrentDir[1]+':\*.*',VolumeID,InfoLabel);
 While DosError=0do Begin
  If(InfoLabel.Attr = VolumeID)Then Begin
   GetDiskLabel:=InfoLabel.Name;
   Exit;
  End;
  FindNext(InfoLabel);
 End;
 GetDiskLabel:=''
End;

Function SizeHiddenFile(Dsk:Byte):LongInt;
Var
 Info:SearchRec;
 HiddenSize:LongInt;
 CurrentDir:String;
Begin
 HiddenSize:=0;
 NumberHiddenFile:=0;
 If Dsk=0Then GetDir(0,CurrentDir)
         Else CurrentDir:=Char(Dsk+64);
 FindFirst(CurrentDir[1]+':\*.*',Hidden,Info);
 While DosError=0do Begin
  If((Info.Attr and Hidden)=Hidden)Then Begin
   HiddenSize:=HiddenSize+Info.Size;
   Inc(NumberHiddenFile);
   Exit;
  End;
  FindNext(Info);
 End;
 SizeHiddenFile:=HiddenSize;
End;

Function TwoByteToWord(A,B:Byte):Word;Begin
 TwoByteToWord:=B*256+A;
End;

Function FourByteToLongInt(A,B,C,D:Byte):LongInt;Begin
 FourByteToLongInt:=D*16777216+C*65536+B*256+A;
End;

Procedure FindStartSector;
Var
 ByteReaded:Integer;
 Partition:PartSec;
Begin
 Seek(FileSource,0);
 BlockRead(FileSource,Partition,512,ByteReaded);
 If Partition.IdCode=$AA55 Then Begin
  If Partition.PartTable[0].SecOfs<>-1 Then Begin
   If FileSize(FileSource)>Partition.PartTable[0].SecOfs Then Begin
    StartPos:=Partition.PartTable[0].SecOfs*512;
   End;
  End;
 End;
End;

{$IFDEF Windows}
 Procedure Int25h(Drive:Byte;LSN,Sects:Word;Var Buffer;Var Erreur:Word);Begin
  FillChar(Buffer,512,0);
 End;
{$ELSE}
 Var Data:Record
  LSN:LongInt;
  Sects:Word;
  Buffer:Pointer;
 End;

 Procedure Int25h(Drive:Byte;LSN,Sects:Word;Var Buffer;Var Erreur:Word);
 Assembler;
 Const __POPF = $9D;
 ASM
  PUSH BP;
  PUSH DS;
   MOV AL,Drive;
   MOV DX,LSN;
   MOV CX,Sects;
   LDS BX,Buffer;
   INT $25;
   JB  @@Suite;
   XOR AX,AX;
@@Suite:
   DB __POPF;
  POP DS;
  POP BP;
  LES DI,Erreur;
  MOV ES:[DI],AX;
  CMP AX,519;
  JNE @@No32Bits;
  PUSH BP;
  PUSH DS;
   MOV AL,Drive;
   MOV DX,LSN;
   MOV CX,Sects;
   MOV BX,Offset Data;
   MOV DS:[BX],DX;
   MOV DS:[BX+2].Word,0;
   MOV DS:[BX+4],CX;
   LES DI,Buffer;
   MOV DS:[BX+6],DI;
   MOV DS:[BX+8],ES;
   MOV CX,$FFFF;
   INT $25;
   JB  @@Suite2;
   XOR AX,AX;
@@Suite2:
   DB __POPF;
  POP DS;
  POP BP;
  LES DI,Erreur;
  MOV ES:[DI],AX;
@@No32Bits:
 End;
{$ENDIF}

Function GetClusterSize:LongInt;
Var
 BytesPSecteur:Word;
Begin
 BytesPSecteur:=TwoByteToWord(BufferSector0[$0B],BufferSector0[$0C]);
 If BytesPSecteur=0Then BytesPSecteur:=512;
 GetClusterSize:=BufferSector0[$0D]*BytesPSecteur;
End;

Function GetNumberCluster:LongInt;
Var
 NbrDeFats:Byte;
 SectsPRoot,PremRoot,PremData,TotPistes,TempLong,TotSects,TotClusters:LongInt;
 SectsPFat,SectsReserves,MaxEntrees,BytesPSecteur,SectsPPiste,NbrTetes:Word;
Begin
 BytesPSecteur:=TwoByteToWord(BufferSector0[$0B],BufferSector0[$0C]);
 If BytesPSecteur=0Then BytesPSecteur:=512;
  NbrDeFats:=BufferSector0[$10];
  If NbrDeFats=0Then NbrDeFats:=2;
 TotSects:=TwoByteToWord(BufferSector0[$13],BufferSector0[$14]);
 If TotSects=0Then TotSects:=FourByteToLongInt(BufferSector0[$20],
                          BufferSector0[$21],BufferSector0[$22],
                          BufferSector0[$23]);
 NbrTetes:=TwoByteToWord(BufferSector0[$1A],BufferSector0[$1B]);
 MaxEntrees:=TwoByteToWord(BufferSector0[$11],BufferSector0[$12]);
 SectsPRoot:=(MaxEntrees*32)div BytesPSecteur;
 SectsReserves:=TwoByteToWord(BufferSector0[$0E],BufferSector0[$0F]);
 SectsPFat:=TwoByteToWord(BufferSector0[$16],BufferSector0[$17]);
 PremRoot:=SectsReserves+(NbrDeFats*SectsPFat);
 PremData:=PremRoot+SectsPRoot;
 SectsPPiste:=TwoByteToWord(BufferSector0[$18],BufferSector0[$19]);
 If (LongInt(NbrTetes)*LongInt(SectsPPiste))=0Then Begin
  TempLong:=0
 End
  Else
 Begin
  TempLong:=TempLong div (LongInt(NbrTetes)*LongInt(SectsPPiste));
 End;
 TotPistes:=TempLong;
 If(TempLong-TotPistes > 0)Then Inc(TotPistes);
 If BufferSector0[$0D]=0Then TempLong:=0
                        Else TempLong:=(LongInt(TotSects)-LongInt(PremData)) div LongInt(BufferSector0[$0D]);
 TotClusters:=TempLong;
 GetNumberCluster:=TotClusters;
End;

Function GetDiskSize:LongInt;
Var
 TotSects:LongInt;
 BytesPSecteur:Word;
Begin
 BytesPSecteur:=TwoByteToWord(BufferSector0[$0B],BufferSector0[$0C]);
 If BytesPSecteur=0Then BytesPSecteur:=512;
 TotSects:=TwoByteToWord(BufferSector0[$13],BufferSector0[$14]);
 If TotSects=0Then TotSects:=FourByteToLongInt(BufferSector0[$20],
                      BufferSector0[$21],BufferSector0[$22],BufferSector0[$23]);
 GetDiskSize:=BytesPSecteur*TotSects;
End;

Function GetSectorSize:Word;Begin
 GetSectorSize:=TwoByteToWord(BufferSector0[$0B],BufferSector0[$0C]);
End;

Function GetFATPos:LongInt;Begin
 GetFATPos:=TwoByteToWord(BufferSector0[$0E],BufferSector0[$0F]);
End;

Function GetDiskFree:LongInt;
Var
 FatPOS,FreeSize:LongInt;
 BufWord:Array[0..255]of Word Absolute Buffer;
 I:Byte;
 NumFATSector,J:LongInt;
Begin
 FreeSize:=0;
 If BufferLoaded Then Begin
  NumFATSector:=(GetNumberCluster shl 1)shr 9;
  FatPOS:=GetFATPos;
  If(GetNumberCluster>0)and(NumFATSector>0)Then For J:=0 to NumFATSector-1 do Begin
   If FileName<>''Then Begin
    {$I-}Assign(FileSource,FileName);
    Reset(FileSource,1);{$I+}
    If IoResult=0Then Begin
     Seek(FileSource,StartPos+(FatPOS+J)*512);
     BlockRead(FileSource,Buffer,SizeOf(Buffer),ByteReaded);
     Close(FileSource);
    End
    End
    Else
   If CurrDisk=0 Then Begin
    Int25h(Ord(UpCase(GetCurrentDisk))-(Ord('A')-1),FatPOS+J,1,Buffer,Erreur);
   End
     Else
   Begin
    Int25h(CurrDisk+1,FatPOS+J,1,Buffer,Erreur);
   End;
   For I:=0 to 255 do Begin
    If BufWord[I]=0 Then Inc(FreeSize,GetClusterSize);
   End;
  End;
 End;
 GetDiskFree:=FreeSize;
End;

Function GetSerialNumber:String;Begin
 GetSerialNumber:=ByteHex2Str(BufferSector0[$27])+ByteHex2Str(BufferSector0[$28])+'-'+
                  ByteHex2Str(BufferSector0[$29])+ByteHex2Str(BufferSector0[$2A]);
End;

Function GetDirectDiskLabel:String;
Var
 S:String;
Begin
 S:='';
 If BufferSector0[$2B]<32 Then Begin
  For I:=1 to 11 do If BufferSector0[$2B+I]<>0 Then S:=S+Char(BufferSector0[$2B+I]);
 End
  Else
 Begin
  For I:=0 to 10 do If BufferSector0[$2B+I]<>0 Then S:=S+Char(BufferSector0[$2B+I]);
 End;
 GetDirectDiskLabel:=S;
End;

BEGIN
 Language:=_French;
 TmpLanguage:=GetEnv('LANGUAGE');
 If TmpLanguage<>''Then Begin
  If TmpLanguage[1]='"'Then TmpLanguage:=Copy(TmpLanguage,2,255);
  If StrToUpper(Copy(TmpLanguage,1,2))='EN'Then Language:=_English Else
  If StrToUpper(Copy(TmpLanguage,1,2))='GR'Then Language:=_Germany Else
  If StrToUpper(Copy(TmpLanguage,1,2))='IT'Then Language:=_Italian Else
  If StrToUpper(Copy(TmpLanguage,1,2))='SP'Then Language:=_Spain;
 End;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  Case Language of
   _Germany:Begin
    WriteLn('öberprÅft einen DatentrÑger und zeigt einen Statusbericht an.');
    WriteLn;
    WriteLn('CHKDSK [Laufwerk:]');
    WriteLn('CHKDSK [/IMAGE:Dateiname]');
   End;
   _English:Begin
    WriteLn('Checks a disk and displays a status report.');
    WriteLn;
    WriteLn('CHKDSK [drive:]');
    WriteLn('CHKDSK [/IMAGE:file]');
   End;
   Else Begin
    WriteLn('CHKDSK : Cette commande permet de vÇrifier le disque');
    WriteLn;
    WriteLn('Syntaxe : CHKDSK [disque:]');
    WriteLn('          CHKDSK [/IMAGE:fichier]');
    WriteLn;
    WriteLn('disque:  Indique la lettre de l''unitÇ de disque');
    WriteLn('/IMAGE   Indique le nom du fichier a utiliser comme disque');
   End;
  End;
 End
  Else
 Begin
  StartPos:=0;
  BufferLoaded:=False;
  CurrDisk:=0;
  FileName:='';
  If ParamCount>0 Then Begin
   For I:=1 to ParamCount do Begin
    CurrParam:=ParamStr(I);
    If Copy(StrToUpper(CurrParam),1,7)='/IMAGE:'Then Begin
     FileName:=Copy(CurrParam,8,255);
    End
     Else
    If(Length(CurrParam)=2)and(CurrParam[2]=':')Then Begin
     CurrDisk:=Ord(UpCase(CurrParam[1]))-(Ord('A')-1);
    End
     Else
    Begin
     WriteLn('Paramätre invalide');
     Halt;
    End;
   End;
  End;
  If FileName<>''Then Begin
   {$I-}Assign(FileSource,FileName);
   Reset(FileSource,1);{$I+}
   If IoResult=0Then Begin
    FindStartSector;
    Seek(FileSource,StartPos);
    BlockRead(FileSource,BufferSector0,SizeOf(BufferSector0),ByteReaded);
    BufferLoaded:=True;
    Close(FileSource);
   End
    Else
   Begin
    WriteLn('Erreur de lecture du fichier d''image');
    Halt;
   End;
  End
   Else
  If CurrDisk=0 Then Begin
   Int25h(Ord(UpCase(GetCurrentDisk))-(Ord('A')-1),0,1,BufferSector0,Erreur);
   {$IFNDEF Windows}
    BufferLoaded:=True;
   {$ENDIF}
  End
   Else
  Begin
   Int25h(CurrDisk+1,0,1,BufferSector0,Erreur);
   {$IFNDEF Windows}
    BufferLoaded:=True;
   {$ENDIF}
  End;
  Case Language of
   _Germany:Write('DataentrÑger ');
   Else Write('Volume ');
  End;
  If(BufferLoaded)Then Begin
   If Trim(GetDirectDiskLabel)=''Then Write('Pas d''Çtiquette')
                                 Else Write(GetDirectDiskLabel)
  End
   Else
  If GetDiskLabel(CurrDisk)=''Then Write('Pas d''Çtiquette')
                              Else Write(GetDiskLabel(CurrDisk));
  Case Language of
   _Germany:Write(' erzeugt ');
   _English:Write(' created ');
   Else Write(' crÇe le ');
  End;
  UnpackTime(InfoLabel.Time,DateLabel);
  Write(DateLabel.Year:4,'-',PadZeroLeft(DateLabel.Month,2),'-',
        PadZeroLeft(DateLabel.Day,2));
  WriteLn(' ',DateLabel.Hour:2,':',PadZeroLeft(DateLabel.Min,2));
  Case Language of
   _Germany:Write('DatentrÑgernummer: ');
   _English:Write('Volume Serial Number is ');
   Else Write('Le numÇro de sÇrie du volume est ');
  End;
  If(BufferLoaded)Then WriteLn(GetSerialNumber)
                  Else WriteLn('0000-0000');
  WriteLn;
  If(BufferLoaded)Then Write(GetDiskSize:13)
                  Else Write(DiskSize(CurrDisk):13);
  Case Language of
   _Germany:WriteLn(' Byte Speicherplatz auf dem DatentrÑger insgesamt');
   _English:WriteLn(' bytes total disk space');
   Else WriteLn(' octets d''espace disque total');
  End;
  If(BufferLoaded)Then Begin
   Case Language of
    _Germany:Begin
     WriteLn(0:13,' Byte in ',NumberHiddenFile,' versteckten Dateien');
    End;
    _English:Begin
     WriteLn(0:13,' bytes in ',NumberHiddenFile,
                  ' file(s) hidden(s)');
    End;
    Else Begin
     WriteLn(0:13,' octets dans ',NumberHiddenFile,
             ' fichier(s) cachÇ(s)');
    End;
   End;
  End
   Else
  Case Language of
   _Germany:Begin
    WriteLn(SizeHiddenFile(CurrDisk):13,'Byte in ',NumberHiddenFile,' versteckten Dateien');
   End;
   _English:Begin
    WriteLn(SizeHiddenFile(CurrDisk):13,' bytes in ',NumberHiddenFile,
                 ' file(s) hidden(s)');
   End;
   Else Begin
    WriteLn(SizeHiddenFile(CurrDisk):13,' octets dans ',NumberHiddenFile,
          ' fichier(s) cachÇ(s)');
   End;
  End;
  Case Language of
   _Germany:WriteLn(0:13,' byte in n Verzeichnissen');
   _English:WriteLn(0:13,' bytes n directories');
   Else WriteLn(0:13,' octets n rÇpertoire(s)');
  End;
  Case Language of
   _Germany:WriteLn(0:13,' Byte in x Benutzerdateien');
   _English:WriteLn(0:13,' bytes in x user files');
   Else WriteLn(0:13,' octets dans x fichier(s) utilisateur');
  End;
  If(BufferLoaded)Then Write(GetDiskFree:13)
                  Else Write(DiskFree(CurrDisk):13);
  Case Language of
   _Germany:WriteLn(' Byte auf dem DatentrÑger verfÅgbar');
   _English:WriteLn(' bytes available on disk');
   Else WriteLn(' octets disponibles sur le disque');
  End;
  WriteLn;
  Write(GetClusterSize:13);
  Case Language of
   _Germany:WriteLn(' Byte in jeder Zuordnungseinheit');
   _English:WriteLn(' bytes in each allocation units');
   Else WriteLn(' octets dans chaque unitÇ d''allocation');
  End;
  Write(GetNumberCluster:13);
  Case Language of
   _Germany:WriteLn(' Zuordnungseinheiten auf dem DatentrÑger insgesamt');
   _English:WriteLn(' total allocation units on disk');
   Else WriteLn(' unitÇs d''allocation sur le disque');
  End;
  Write(0:13);
  Case Language of
   _Germany:WriteLn(' Zuordnungseinheiten auf dem DatentrÑger verfÅgbar');
   _English:WriteLn(' available allocation units on disk');
   Else WriteLn(' unitÇs d''allocation disponible sur le disque');
  End;
  WriteLn;
  Write(GetConvMemory shl 9:13);
  Case Language of
   _Germany:WriteLn(' Byte konventioneller Arbeitsspeicher');
   _English:WriteLn(' total bytes memory');
   Else WriteLn(' octets de mÇmoire totale');
  End;
  Write(GetFreeMemory:13);
  Case Language of
   _Germany:WriteLn(' Byte frei');
   _English:WriteLn(' bytes free');
   Else WriteLn(' octets libres');
  End;
 End;
END.