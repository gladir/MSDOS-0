{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program SYS;

{$A-}

Uses DOS,Strings;

Const
 SECTOR_SIZE=512;
 MAX_PATH=64;
 IMG_DRIVE_SENTINEL=$FE;  { Code "lecteur" interne pour l'image }
 VMDK_DESC_SIG='# Disk DescriptorFile';
 MAX_SYSFILES=3;
 { Identifiants de famille DOS }
 DOS_MSDOS  = 0;
 DOS_PCDOS  = 1;
 DOS_DRDOS  = 2;
 DOS_FREEDOS= 3;
 DOS_RXDOS  = 4;
 DOS_WIN95  = 5;
 DOS_PTSDOS = 6;
 DOS_OS2    = 7;
 DOS_WINNT  = 8;

Type
 TSector=Array[0..SECTOR_SIZE-1] of Byte;
 TFatEntry=Word;

 TBootSector=Record
  JumpCode:Array[0..2] of Byte;
  OEMName:Array[0..7] of Char;
  BytesPerSector:Word;
  SectorsPerCluster:Byte;
  ReservedSectors:Word;
  NumberOfFATs:Byte;
  RootEntries:Word;
  TotalSectors:Word;
  MediaDescriptor:Byte;
  SectorsPerFAT:Word;
  SectorsPerTrack:Word;
  NumberOfHeads:Word;
  HiddenSectors:LongInt;
  TotalSectorsBig:LongInt;
 End;

 TDirEntry=Record
  Name:Array[0..7] of Char;
  Ext:Array[0..2] of Char;
  Attr:Byte;
  Reserved:Array[0..9] of Byte;
  Time:Word;
  Date:Word;
  StartCluster:Word;
  Size:LongInt;
 End;

 { BPB et layout FAT calculés a partir de l'image }
 TBPB = Record
  BytesPerSec:Word;
  SecPerClus:Byte;
  ReservedSec:Word;
  NumFATs:Byte;
  RootEntries:Word;
  Media:Byte;
  SecPerFAT:Word;
  HiddenSec:LongInt;
  TotalSec:LongInt;
  PartLBA:LongInt;       { LBA absolu du début de la partition }
  FAT1LBA:LongInt;       { LBA absolu de la 1ere FAT }
  RootDirLBA:LongInt;    { LBA absolu du répertoire racine }
  RootDirSec:Word;       { Nombre de secteurs du répertoire racine }
  DataLBA:LongInt;       { LBA absolu du cluster 2 }
  TotalClusters:LongInt;
  FATBits:Byte;          { 12 ou 16 }
 End;

Const
 MAX_FAT_BYTES=65520;

Type
 PFATBuf=^TFATBuf;
 TFATBuf=Array[0..MAX_FAT_BYTES-1] of Byte;

Var
 SourceDrive,DestDrive:Char;
 BootSector:TBootSector;
 ErrorCode:Integer;
 i:Integer;
 Success:Boolean;
 CurrParam:String;
 { Support /IMG:file - destination dans un fichier image disque }
 UseImg:Boolean;          { True si /IMG:file actif }
 NoBoot:Boolean;          { True si /NOBOOT : ne pas reecrire le secteur de boot }
 InfoOnly:Boolean;        { True si /INFO : seulement analyser }
 ActiveReq:Byte;          { 0=non touche, 1..4 = numero de partition a activer }
 ImgPath:String;          { Chemin du fichier image }
 ImgFile:File;            { Handle vers l'image }
 ImgKind:Byte;            { 0 = raw IMG, 1 = VHD fixe }
 BPB:TBPB;
 FATBuf:PFATBuf;          { Alloue sur le tas (jusqu'a 64 Ko) }
 FATBytes:LongInt;
 ImgDt,ImgTm:Word;
 ImgAttr:Byte;
 ImgSrcPath:String;
 FormatReq:Byte;          { 0=non, 12=FAT12, 16=FAT16 }
 DosFamily:Byte;          { DOS_MSDOS, DOS_PCDOS, ... }
 SysFiles:Array[1..MAX_SYSFILES] of String;
 SysFileCount:Integer;

Function DrvCode(D:Char):Byte;
Begin
 If D='@' Then DrvCode:=IMG_DRIVE_SENTINEL
 Else DrvCode:=Ord(D)-Ord('A');
End;

Function ImgReadLBA(LBA:LongInt;Var Buffer;Count:Word):Boolean;
Var Got:Word; ByteCount:Word;
Begin
 ImgReadLBA:=False;
 ByteCount:=Count*SECTOR_SIZE;
 {$I-} Seek(ImgFile,LBA*LongInt(SECTOR_SIZE)); {$I+}
 If IOResult<>0 Then Exit;
 {$I-} BlockRead(ImgFile,Buffer,ByteCount,Got); {$I+}
 If IOResult<>0 Then Exit;
 ImgReadLBA:=(Got=ByteCount);
End;

Function ImgWriteLBA(LBA:LongInt;Var Buffer;Count:Word):Boolean;
Var Wrote:Word; ByteCount:Word;
Begin
 ImgWriteLBA:=False;
 ByteCount:=Count*SECTOR_SIZE;
 {$I-} Seek(ImgFile,LBA*LongInt(SECTOR_SIZE)); {$I+}
 If IOResult<>0 Then Exit;
 {$I-} BlockWrite(ImgFile,Buffer,ByteCount,Wrote); {$I+}
 If IOResult<>0 Then Exit;
 ImgWriteLBA:=(Wrote=ByteCount);
End;

Function ReadSector(Drive:Byte;Sector:LongInt;Var Buffer;Count:Word):Boolean;
Var
 Regs:Registers;
Begin
 If Drive=IMG_DRIVE_SENTINEL Then Begin
  ReadSector:=ImgReadLBA(Sector,Buffer,Count);
  Exit;
 End;
 Regs.AH:=02;  { Lecture de secteurs }
 Regs.AL:=Count;
 Regs.CH:=(Sector shr 8) and $FF;
 Regs.CL:=(Sector and $3F) or ((Sector shr 2) and $C0);
 Regs.DH:=(Sector shr 8) and 1;
 Regs.DL:=Drive;
 Regs.ES:=Seg(Buffer);
 Regs.BX:=Ofs(Buffer);
 Intr($13,Regs);
 ReadSector:=(Regs.Flags and 1) = 0;
End;

Function WriteSector(Drive:Byte;Sector:LongInt;Var Buffer;Count:Word):Boolean;
Var
 Regs:Registers;
Begin
 If Drive=IMG_DRIVE_SENTINEL Then Begin
  WriteSector:=ImgWriteLBA(Sector,Buffer,Count);
  Exit;
 End;
 Regs.AH:=$03;  { �criture de secteurs }
 Regs.AL:=Count;
 Regs.CH:=(Sector shr 8) and $FF;
 Regs.CL:=(Sector and $3F) or ((Sector shr 2) and $C0);
 Regs.DH:=(Sector shr 8) and 1;
 Regs.DL:=Drive;
 Regs.ES:=Seg(Buffer);
 Regs.BX:=Ofs(Buffer);
 Intr($13,Regs);
 WriteSector:=(Regs.Flags and 1) = 0;
End;

Function TrimRight(Const S:String):String;
Var
 i:Integer;
Begin
 i:=Length(S);
 While(i > 0)and(S[i] = ' ')do Dec(i);
 TrimRight:=Copy(S, 1, i);
End;

Function GetFileCluster(Drive:Char;Const FileName:String):Word;
Var
 DirSector:TSector;
 DirEntry:Array[0..31] of Byte;
 i:Integer;
Begin
 GetFileCluster:=0;
  { Lire le r�pertoire racine }
 If Not ReadSector(DrvCode(Drive), 19, DirSector, 1)Then Exit;
  { Chercher le fichier }
 For i:=0 to 15 do Begin
  Move(DirSector[i * 32], DirEntry, 32);
  If(DirEntry[0]<>0)and(DirEntry[0] <> $E5)and
    (Copy(FileName,1,8)=TrimRight(StrPas(@DirEntry[0])))Then Begin
   GetFileCluster := DirEntry[26] + (DirEntry[27] shl 8);
   Exit;
  End;
 End;
End;

Function GetFileInfo(Drive:Char;Const FileName:String;Var Entry:TDirEntry):Boolean;
Var
 DirSector:TSector;
 i:Integer;
Begin
 GetFileInfo:=False;
 If Not ReadSector(DrvCode(Drive),19,DirSector,1)Then Exit;
 For i:=0 to (SECTOR_SIZE div SizeOf(TDirEntry))-1 do Begin
  Move(DirSector[i * SizeOf(TDirEntry)],Entry,SizeOf(TDirEntry));
  If(Entry.Name[0]<>#0)and(Entry.Name[0]<>Chr($E5))and
    (Copy(FileName,1,8)=TrimRight(StrPas(@Entry.Name)))Then Begin
   GetFileInfo := True;
   Exit;
  End;
 End;
End;

Function CopySystemFile(Const FileName:String;SourceDrv,DestDrv:Char):Boolean;
Var
 Entry:TDirEntry;
 SourceSector,DestSector:LongInt;
 Buffer:TSector;
 SectorsToRead:LongInt;
 CurrentSector:LongInt;
Begin
 CopySystemFile:=False;
  { Obtenir les informations du fichier source }
 If Not GetFileInfo(SourceDrv,FileName,Entry)Then Exit;

  { Calculer le nombre de secteurs à copier }
 SectorsToRead:=(Entry.Size+SECTOR_SIZE-1) div SECTOR_SIZE;

  { Calculer les secteurs de départ }
 SourceSector:=33+(Entry.StartCluster-2);
 DestSector:=33; { Pour IO.SYS et MSDOS.SYS }

  { Pour COMMAND.COM, on écrit ailleurs }
 If FileName='COMMAND.COM'Then DestSector:=50;

  { Copier les secteurs }
 For CurrentSector:=0 to SectorsToRead-1 do Begin
  If Not ReadSector(DrvCode(SourceDrv),SourceSector+CurrentSector,Buffer,1)Then Exit;
  If Not WriteSector(DrvCode(DestDrv),DestSector+CurrentSector,Buffer,1)Then Exit;
 End;
 CopySystemFile := True;
End;

Function ReserveFATSpace(Drive:Char):Boolean;
Var
 Sector:TSector;
 i:Integer;
Begin
 ReserveFATSpace:=False;
  { Lire le premier secteur de la FAT }
 If Not ReadSector(DrvCode(Drive),1,Sector,1)Then Exit;
  { R�server les premiers unit�s d'allocations }
 For i:=2 to 16 do Sector[i]:=$FF;
  { �crire la FAT mise � jour }
 ReserveFATSpace:=WriteSector(DrvCode(Drive),1,Sector,1);
End;

Function UpperStr(Const S:String):String;
Var i:Integer; R:String;
Begin
 R:=S;
 For i:=1 to Length(R) do
  If(R[i]>='a')and(R[i]<='z')Then R[i]:=Chr(Ord(R[i])-32);
 UpperStr:=R;
End;

Function StartsWith(Const S,Prefix:String):Boolean;
Begin
 StartsWith:=(Length(S)>=Length(Prefix))and
             (UpperStr(Copy(S,1,Length(Prefix)))=UpperStr(Prefix));
End;

Function BE32(Const Buf;Ofs:LongInt):LongInt;
Var P:^Byte; B0,B1,B2,B3:LongInt;
Begin
 P:=@Buf; Inc(P,Ofs);
 B0:=P^; Inc(P); B1:=P^; Inc(P); B2:=P^; Inc(P); B3:=P^;
 BE32:=(B0 shl 24) or (B1 shl 16) or (B2 shl 8) or B3;
End;

Function OpenImage(Const FN:String):Boolean;
Var
 Hdr:Array[0..511] of Byte;
 Footer:Array[0..511] of Byte;
 Got:Word;
 FSize:LongInt;
 DiskType:LongInt;
 TextSig:Boolean;
 SigStr:String;
 i:Integer;
Begin
 OpenImage:=False;
 Assign(ImgFile,FN);
 FileMode:=2; { lecture/ecriture }
 {$I-} Reset(ImgFile,1); {$I+}
 If IOResult<>0 Then Begin
  WriteLn('Erreur: Impossible d''ouvrir l''image "',FN,'" en lecture/ecriture.');
  Exit;
 End;
 FSize:=FileSize(ImgFile);
 If FSize<SECTOR_SIZE Then Begin
  WriteLn('Erreur: Image trop petite.');
  Close(ImgFile); Exit;
 End;
 { Lire l'entete pour detection TeleDisk/VMDK }
 {$I-} Seek(ImgFile,0); BlockRead(ImgFile,Hdr,512,Got); {$I+}
 If IOResult<>0 Then Begin Close(ImgFile); Exit; End;

 { TeleDisk : 'TD' (non comprime) ou 'td' (comprime LZHUF) }
 If((Hdr[0]=Ord('T'))and(Hdr[1]=Ord('D')))or
   ((Hdr[0]=Ord('t'))and(Hdr[1]=Ord('d')))Then Begin
  WriteLn('Erreur: Image TeleDisk (TD0) en ecriture non supportee.');
  WriteLn('  Convertir d''abord vers une image brute (.IMG) avec UNDISKPC ou similaire.');
  Close(ImgFile); Exit;
 End;

 { VMDK sparse : signature 'KDMV' }
 If(Hdr[0]=Ord('K'))and(Hdr[1]=Ord('D'))and
   (Hdr[2]=Ord('M'))and(Hdr[3]=Ord('V'))Then Begin
  WriteLn('Erreur: Image VMDK sparse (VMware) en ecriture non supportee.');
  WriteLn('  Convertir d''abord vers VMDK plat ou IMG brute.');
  Close(ImgFile); Exit;
 End;

 { VMDK descripteur texte : '# Disk DescriptorFile' }
 TextSig:=True;
 SigStr:=VMDK_DESC_SIG;
 For i:=1 to Length(SigStr) do
  If Hdr[i-1]<>Ord(SigStr[i])Then Begin TextSig:=False; Break; End;
 If TextSig Then Begin
  WriteLn('Erreur: Descripteur VMDK texte detecte; ouvrir directement le fichier -flat.vmdk.');
  Close(ImgFile); Exit;
 End;

 { VHD : signature 'conectix' dans le footer (derniers 512 octets) }
 ImgKind:=0;
 If FSize>=1024 Then Begin
  {$I-} Seek(ImgFile,FSize-512); BlockRead(ImgFile,Footer,512,Got); {$I+}
  If(IOResult=0)and
    (Footer[0]=Ord('c'))and(Footer[1]=Ord('o'))and(Footer[2]=Ord('n'))and
    (Footer[3]=Ord('e'))and(Footer[4]=Ord('c'))and(Footer[5]=Ord('t'))and
    (Footer[6]=Ord('i'))and(Footer[7]=Ord('x'))Then Begin
   { Disk Type @offset 60, big-endian: 2=fixed, 3=dynamic, 4=differencing }
   DiskType:=BE32(Footer,60);
   If DiskType=2 Then Begin
    ImgKind:=1; { VHD fixe : ecriture supportee, payload aux LBA 0..(FSize-512)/512 }
   End Else
   If DiskType=3 Then Begin
    WriteLn('Erreur: Image VHD dynamique en ecriture non supportee (allocation BAT requise).');
    WriteLn('  Convertir d''abord vers VHD fixe ou IMG brute.');
    Close(ImgFile); Exit;
   End Else
   If DiskType=4 Then Begin
    WriteLn('Erreur: Image VHD differentielle non supportee.');
    Close(ImgFile); Exit;
   End Else Begin
    WriteLn('Erreur: Type VHD inconnu (',DiskType,').');
    Close(ImgFile); Exit;
   End;
  End;
 End;
 OpenImage:=True;
End;

{ =========================================================================
  Mode /IMG: lecture du BPB, allocation FAT12/16, ecriture entree racine,
  copie des fichiers source depuis le filesystem, secteur de boot minimal.
  ========================================================================= }

Function GetLE16Buf(Var Buf;Ofs:Word):Word;
Var P:^Byte; B0,B1:Word;
Begin
 P:=@Buf; Inc(P,Ofs); B0:=P^; Inc(P); B1:=P^;
 GetLE16Buf:=B0 or (B1 shl 8);
End;

Function GetLE32Buf(Var Buf;Ofs:Word):LongInt;
Var P:^Byte; R:LongInt; J:Integer;
Begin
 P:=@Buf; Inc(P,Ofs); R:=0;
 For J:=0 to 3 do Begin
  R:=R or (LongInt(P^) shl (J*8));
  Inc(P);
 End;
 GetLE32Buf:=R;
End;

Procedure PutLE16Buf(Var Buf;Ofs:Word;Val:Word);
Var P:^Byte;
Begin
 P:=@Buf; Inc(P,Ofs);
 P^:=Byte(Val and $FF); Inc(P);
 P^:=Byte((Val shr 8) and $FF);
End;

Procedure PutLE32Buf(Var Buf;Ofs:Word;Val:LongInt);
Var P:^Byte; J:Integer;
Begin
 P:=@Buf; Inc(P,Ofs);
 For J:=0 to 3 do Begin
  P^:=Byte(Val and $FF);
  Val:=Val shr 8;
  Inc(P);
 End;
End;

Procedure PackDOSDateTime(Var Dt,Tm:Word);
Var Y,Mo,D,DOW,H,Mi,Se,S100:Word;
Begin
 GetDate(Y,Mo,D,DOW);
 GetTime(H,Mi,Se,S100);
 Dt:=((Y-1980) shl 9) or (Mo shl 5) or D;
 Tm:=(H shl 11) or (Mi shl 5) or (Se div 2);
End;

{ Calcule la geometrie BPB pour formater une partition de TotalSec secteurs
  en FAT12 ou FAT16. Renvoie False si impossible. }
Function ComputeBPB(FATBitsReq:Byte;TotalSec:LongInt;Var BP:TBPB):Boolean;
Var
 SPC:Byte;
 RootEnt:Word;
 ReservedSec:Word;
 NumFATs:Byte;
 DataSec,Clusters,FATSec:LongInt;
 SPCTry:Byte;
 Trial:Integer;
Begin
 ComputeBPB:=False;
 BP.BytesPerSec:=512;
 ReservedSec:=1;
 NumFATs:=2;
 If FATBitsReq=12 Then RootEnt:=224 Else RootEnt:=512;
 { Choisir SecPerClus selon la taille }
 If FATBitsReq=12 Then SPC:=1
 Else Begin
  If TotalSec<=32680 Then SPC:=2          { ~16 Mo }
  Else If TotalSec<=262144 Then SPC:=4    { ~128 Mo }
  Else If TotalSec<=524288 Then SPC:=8    { ~256 Mo }
  Else If TotalSec<=1048576 Then SPC:=16  { ~512 Mo }
  Else If TotalSec<=2097152 Then SPC:=32  { ~1 Go }
  Else SPC:=64;                           { jusqu'a ~2 Go }
 End;
 { Iterer pour converger sur SecPerFAT }
 For Trial:=1 to 30 do Begin
  DataSec:=TotalSec-ReservedSec-LongInt(RootEnt)*32 div 512;
  Clusters:=DataSec div SPC;
  If FATBitsReq=12 Then
   FATSec:=((Clusters+2)*3+1023) div 1024
  Else
   FATSec:=((Clusters+2)*2+511) div 512;
  DataSec:=TotalSec-ReservedSec-NumFATs*FATSec-(LongInt(RootEnt)*32 div 512);
  Clusters:=DataSec div SPC;
  If FATBitsReq=12 Then
   BP.SecPerFAT:=Word(((Clusters+2)*3+1023) div 1024)
  Else
   BP.SecPerFAT:=Word(((Clusters+2)*2+511) div 512);
  If BP.SecPerFAT=FATSec Then Break;
 End;
 { Verifier limites }
 If FATBitsReq=12 Then Begin
  If Clusters<1 Then Exit;
  If Clusters>=4085 Then Begin
   { Trop gros pour FAT12 : tenter avec SPC plus grand }
   SPCTry:=SPC;
   While(Clusters>=4085)and(SPCTry<64)do Begin
    SPCTry:=SPCTry shl 1;
    DataSec:=TotalSec-ReservedSec-NumFATs*BP.SecPerFAT-(LongInt(RootEnt)*32 div 512);
    Clusters:=DataSec div SPCTry;
   End;
   If Clusters>=4085 Then Begin
    WriteLn('Erreur: Volume trop gros pour FAT12 (',Clusters,' clusters >= 4085).');
    WriteLn('  Utiliser /FORMAT:FAT16 pour les volumes > ~3 Mo.');
    Exit;
   End;
   SPC:=SPCTry;
  End;
 End Else Begin
  If Clusters<4085 Then Begin
   WriteLn('Avertissement: Volume petit, FAT12 serait plus approprie (',Clusters,' clusters).');
  End;
  If Clusters>=65525 Then Begin
   WriteLn('Erreur: Volume trop gros pour FAT16 (',Clusters,' clusters >= 65525).');
   WriteLn('  FAT32 n''est pas supporte par SYS.');
   Exit;
  End;
 End;
 BP.SecPerClus:=SPC;
 BP.ReservedSec:=ReservedSec;
 BP.NumFATs:=NumFATs;
 BP.RootEntries:=RootEnt;
 BP.TotalSec:=TotalSec;
 If TotalSec<2880 Then BP.Media:=$F0 Else BP.Media:=$F8;
 BP.FATBits:=FATBitsReq;
 BP.TotalClusters:=Clusters;
 BP.RootDirSec:=(LongInt(RootEnt)*32+511) div 512;
 ComputeBPB:=True;
End;

{ Ecrit un BPB DOS standard + signature 55AA dans un secteur de boot. }
Procedure BuildBootSector(Var Buf:TSector;Const BP:TBPB);
Var FATName:String;
Begin
 FillChar(Buf,512,0);
 { JMP courte vers offset $3E + NOP }
 Buf[0]:=$EB; Buf[1]:=$3C; Buf[2]:=$90;
 { OEM "CORAILSY" }
 Buf[3]:=Ord('C'); Buf[4]:=Ord('O'); Buf[5]:=Ord('R'); Buf[6]:=Ord('A');
 Buf[7]:=Ord('I'); Buf[8]:=Ord('L'); Buf[9]:=Ord('S'); Buf[10]:=Ord('Y');
 PutLE16Buf(Buf,11,BP.BytesPerSec);
 Buf[13]:=BP.SecPerClus;
 PutLE16Buf(Buf,14,BP.ReservedSec);
 Buf[16]:=BP.NumFATs;
 PutLE16Buf(Buf,17,BP.RootEntries);
 If BP.TotalSec<65536 Then PutLE16Buf(Buf,19,Word(BP.TotalSec))
 Else PutLE16Buf(Buf,19,0);
 Buf[21]:=BP.Media;
 PutLE16Buf(Buf,22,BP.SecPerFAT);
 PutLE16Buf(Buf,24,63);    { Sec/Track }
 PutLE16Buf(Buf,26,16);    { Heads }
 PutLE32Buf(Buf,28,BP.PartLBA); { HiddenSec }
 If BP.TotalSec>=65536 Then PutLE32Buf(Buf,32,BP.TotalSec)
 Else PutLE32Buf(Buf,32,0);
 { Extended BPB (DOS 4.0+) }
 Buf[36]:=$80;             { drive number }
 Buf[37]:=0;
 Buf[38]:=$29;             { boot signature }
 PutLE32Buf(Buf,39,$12345678); { serial }
 { Label "NO NAME    " }
 Buf[43]:=Ord('N'); Buf[44]:=Ord('O'); Buf[45]:=Ord(' '); Buf[46]:=Ord('N');
 Buf[47]:=Ord('A'); Buf[48]:=Ord('M'); Buf[49]:=Ord('E'); Buf[50]:=Ord(' ');
 Buf[51]:=Ord(' '); Buf[52]:=Ord(' '); Buf[53]:=Ord(' ');
 { FS type }
 If BP.FATBits=12 Then FATName:='FAT12   '
 Else FATName:='FAT16   ';
 Buf[54]:=Ord(FATName[1]); Buf[55]:=Ord(FATName[2]);
 Buf[56]:=Ord(FATName[3]); Buf[57]:=Ord(FATName[4]);
 Buf[58]:=Ord(FATName[5]); Buf[59]:=Ord(FATName[6]);
 Buf[60]:=Ord(FATName[7]); Buf[61]:=Ord(FATName[8]);
 { Stub minimal "Non-system disk" }
 Buf[$3E]:=$FA; Buf[$3F]:=$31; Buf[$40]:=$C0;
 Buf[$41]:=$8E; Buf[$42]:=$D8; Buf[$43]:=$8E; Buf[$44]:=$C0;
 Buf[$45]:=$BE; Buf[$46]:=$5D; Buf[$47]:=$7C;
 Buf[$48]:=$AC; Buf[$49]:=$08; Buf[$4A]:=$C0; Buf[$4B]:=$74; Buf[$4C]:=$09;
 Buf[$4D]:=$B4; Buf[$4E]:=$0E; Buf[$4F]:=$BB; Buf[$50]:=$07; Buf[$51]:=$00;
 Buf[$52]:=$CD; Buf[$53]:=$10; Buf[$54]:=$EB; Buf[$55]:=$F2;
 Buf[$56]:=$30; Buf[$57]:=$E4; Buf[$58]:=$CD; Buf[$59]:=$16; Buf[$5A]:=$CD; Buf[$5B]:=$19;
 Buf[$5C]:=$0D; Buf[$5D]:=$0A;
 Buf[$5E]:=Ord('N'); Buf[$5F]:=Ord('o'); Buf[$60]:=Ord('n');
 Buf[$61]:=Ord('-'); Buf[$62]:=Ord('s'); Buf[$63]:=Ord('y'); Buf[$64]:=Ord('s');
 Buf[$65]:=Ord('t'); Buf[$66]:=Ord('e'); Buf[$67]:=Ord('m');
 Buf[$68]:=Ord(' '); Buf[$69]:=Ord('d'); Buf[$6A]:=Ord('i'); Buf[$6B]:=Ord('s'); Buf[$6C]:=Ord('k');
 Buf[$6D]:=$0D; Buf[$6E]:=$0A; Buf[$6F]:=0;
 Buf[510]:=$55; Buf[511]:=$AA;
End;

Function FormatImage(FATBitsReq:Byte):Boolean;
Var
 Sec0,Sec:TSector;
 ImgSecCount,PartStart,PartSize:LongInt;
 PartType:Byte;
 HasMBR:Boolean;
 J:LongInt;
 ZeroSec:TSector;
 ImgBytes:LongInt;
Begin
 FormatImage:=False;
 ImgBytes:=FileSize(ImgFile);
 If ImgKind=1 Then Dec(ImgBytes,512); { footer VHD }
 ImgSecCount:=ImgBytes div 512;
 If ImgSecCount<8 Then Begin
  WriteLn('Erreur: Image trop petite pour formater.'); Exit;
 End;
 { Lire secteur 0 pour decider du layout }
 If Not ImgReadLBA(0,Sec0,1)Then Begin
  WriteLn('Erreur: Lecture secteur 0.'); Exit;
 End;
 HasMBR:=(Sec0[510]=$55)and(Sec0[511]=$AA)and
         (GetLE16Buf(Sec0,11)<>512); { signature MBR mais pas un BPB direct }
 If HasMBR Then Begin
  { Recuperer la premiere partition }
  PartType:=Sec0[$1BE+4];
  PartStart:=GetLE32Buf(Sec0,$1BE+8);
  PartSize:=GetLE32Buf(Sec0,$1BE+12);
  If(PartType=0)or(PartStart=0)or(PartSize=0)Then HasMBR:=False;
 End;
 If Not HasMBR Then Begin
  { Image vide ou non partitionnee : creer un MBR + 1 partition }
  WriteLn('Image sans partition valide : creation d''un MBR.');
  FillChar(Sec0,512,0);
  PartStart:=63;
  If PartStart>=ImgSecCount Then PartStart:=1;
  PartSize:=ImgSecCount-PartStart;
  If FATBitsReq=12 Then PartType:=$01
  Else If PartSize<65536 Then PartType:=$04
  Else PartType:=$06;
  { Entree de table de partition }
  Sec0[$1BE+0]:=$80;     { bootable }
  Sec0[$1BE+1]:=1; Sec0[$1BE+2]:=1; Sec0[$1BE+3]:=0;  { CHS start 0/1/1 }
  Sec0[$1BE+4]:=PartType;
  Sec0[$1BE+5]:=$FE; Sec0[$1BE+6]:=$FF; Sec0[$1BE+7]:=$FF; { CHS end maxed }
  PutLE32Buf(Sec0,$1BE+8,PartStart);
  PutLE32Buf(Sec0,$1BE+12,PartSize);
  Sec0[510]:=$55; Sec0[511]:=$AA;
  If Not ImgWriteLBA(0,Sec0,1)Then Begin
   WriteLn('Erreur: Ecriture MBR.'); Exit;
  End;
 End Else Begin
  WriteLn('MBR existant : reutilisation de la partition #1.');
  { Adapter le type si demande change la categorie }
  If FATBitsReq=12 Then Sec0[$1BE+4]:=$01
  Else If PartSize<65536 Then Sec0[$1BE+4]:=$04
  Else Sec0[$1BE+4]:=$06;
  If Not ImgWriteLBA(0,Sec0,1)Then Begin
   WriteLn('Erreur: Mise a jour MBR.'); Exit;
  End;
 End;

 BPB.PartLBA:=PartStart;
 If Not ComputeBPB(FATBitsReq,PartSize,BPB)Then Exit;
 BPB.FAT1LBA:=BPB.PartLBA+BPB.ReservedSec;
 BPB.RootDirLBA:=BPB.FAT1LBA+LongInt(BPB.NumFATs)*BPB.SecPerFAT;
 BPB.DataLBA:=BPB.RootDirLBA+BPB.RootDirSec;
 FATBytes:=LongInt(BPB.SecPerFAT)*512;
 If FATBytes>MAX_FAT_BYTES Then Begin
  WriteLn('Erreur: FAT trop grande (',FATBytes,' octets > ',MAX_FAT_BYTES,').');
  Exit;
 End;

 WriteLn('Formatage FAT', BPB.FATBits, ' : ', BPB.TotalClusters,
         ' clusters, ', BPB.SecPerClus, ' sec/cluster, FAT=', BPB.SecPerFAT, ' sec.');

 { Ecrire secteur de boot de la partition }
 BuildBootSector(Sec,BPB);
 If Not ImgWriteLBA(BPB.PartLBA,Sec,1)Then Begin
  WriteLn('Erreur: Ecriture secteur de boot partition.'); Exit;
 End;

 { Initialiser les FATs (cluster 0 = media|FF FF, cluster 1 = EOC) }
 FillChar(ZeroSec,512,0);
 For J:=0 to LongInt(BPB.NumFATs)*BPB.SecPerFAT-1 do
  If Not ImgWriteLBA(BPB.FAT1LBA+J,ZeroSec,1)Then Exit;
 { Premier secteur de chaque FAT : entrees reservees }
 FillChar(ZeroSec,512,0);
 ZeroSec[0]:=BPB.Media; ZeroSec[1]:=$FF; ZeroSec[2]:=$FF;
 If BPB.FATBits=16 Then ZeroSec[3]:=$FF;
 For J:=0 to BPB.NumFATs-1 do
  If Not ImgWriteLBA(BPB.FAT1LBA+J*LongInt(BPB.SecPerFAT),ZeroSec,1)Then Exit;

 { Zerer le repertoire racine }
 FillChar(ZeroSec,512,0);
 For J:=0 to BPB.RootDirSec-1 do
  If Not ImgWriteLBA(BPB.RootDirLBA+J,ZeroSec,1)Then Exit;

 FormatImage:=True;
End;

Function LoadBPB:Boolean;
Var
 Sec0,Sec1:TSector;
 PartType:Byte;
 PartStart:LongInt;
 J:Integer;
 BPS:Word;
 SPC:Byte;
Begin
 LoadBPB:=False;
 If Not ImgReadLBA(0,Sec0,1)Then Begin
  WriteLn('Erreur: Lecture secteur 0 echouee.'); Exit;
 End;
 BPS:=GetLE16Buf(Sec0,11);
 SPC:=Sec0[13];
 If(BPS=512)and(SPC<>0)and((SPC and (SPC-1))=0)Then Begin
  BPB.PartLBA:=0;
  Move(Sec0,Sec1,512);
 End Else Begin
  If(Sec0[510]<>$55)or(Sec0[511]<>$AA)Then Begin
   WriteLn('Erreur: Pas de BPB ni de signature MBR 55AA valide.');
   Exit;
  End;
  PartStart:=0; PartType:=0;
  For J:=0 to 3 do Begin
   PartType:=Sec0[$1BE+J*16+4];
   PartStart:=GetLE32Buf(Sec0,$1BE+J*16+8);
   If(PartType<>0)and(PartStart<>0)Then Break;
   PartType:=0;
  End;
  If(PartType=0)or(PartStart=0)Then Begin
   WriteLn('Erreur: Aucune partition trouvee dans le MBR.'); Exit;
  End;
  If Not((PartType=$01)or(PartType=$04)or(PartType=$06)or
        (PartType=$0B)or(PartType=$0C)or(PartType=$0E))Then Begin
   WriteLn('Erreur: Type partition $',PartType,' non supporte. FAT12/16 requise.');
   Exit;
  End;
  BPB.PartLBA:=PartStart;
  If Not ImgReadLBA(PartStart,Sec1,1)Then Begin
   WriteLn('Erreur: Lecture secteur de boot partition echouee.'); Exit;
  End;
  BPS:=GetLE16Buf(Sec1,11);
  SPC:=Sec1[13];
  If(BPS<>512)or(SPC=0)Then Begin
   WriteLn('Erreur: BPB invalide dans la partition.'); Exit;
  End;
 End;
 BPB.BytesPerSec:=GetLE16Buf(Sec1,11);
 BPB.SecPerClus:=Sec1[13];
 BPB.ReservedSec:=GetLE16Buf(Sec1,14);
 BPB.NumFATs:=Sec1[16];
 BPB.RootEntries:=GetLE16Buf(Sec1,17);
 BPB.TotalSec:=GetLE16Buf(Sec1,19);
 BPB.Media:=Sec1[21];
 BPB.SecPerFAT:=GetLE16Buf(Sec1,22);
 BPB.HiddenSec:=GetLE32Buf(Sec1,28);
 If BPB.TotalSec=0 Then BPB.TotalSec:=GetLE32Buf(Sec1,32);
 If BPB.SecPerFAT=0 Then Begin
  WriteLn('Erreur: SecPerFAT=0 (FAT32). FAT32 non supportee par SYS.'); Exit;
 End;
 If(BPB.NumFATs=0)or(BPB.RootEntries=0)Then Begin
  WriteLn('Erreur: BPB incoherent (NumFATs ou RootEntries=0).'); Exit;
 End;
 BPB.FAT1LBA:=BPB.PartLBA+BPB.ReservedSec;
 BPB.RootDirLBA:=BPB.FAT1LBA+LongInt(BPB.NumFATs)*BPB.SecPerFAT;
 BPB.RootDirSec:=(LongInt(BPB.RootEntries)*32+511) div 512;
 BPB.DataLBA:=BPB.RootDirLBA+BPB.RootDirSec;
 BPB.TotalClusters:=(BPB.TotalSec-(BPB.DataLBA-BPB.PartLBA)) div BPB.SecPerClus;
 If BPB.TotalClusters<4085 Then BPB.FATBits:=12
 Else If BPB.TotalClusters<65525 Then BPB.FATBits:=16
 Else Begin
  WriteLn('Erreur: Volume FAT32 detecte (',BPB.TotalClusters,' clusters).'); Exit;
 End;
 FATBytes:=LongInt(BPB.SecPerFAT)*512;
 If FATBytes>MAX_FAT_BYTES Then Begin
  WriteLn('Erreur: FAT trop grande (',FATBytes,' octets > ',MAX_FAT_BYTES,').');
  Exit;
 End;
 LoadBPB:=True;
End;

Function LoadFAT:Boolean;
Var J:LongInt; Buf:TSector;
Begin
 LoadFAT:=False;
 For J:=0 to BPB.SecPerFAT-1 do Begin
  If Not ImgReadLBA(BPB.FAT1LBA+J,Buf,1)Then Exit;
  Move(Buf,FATBuf^[J*512],512);
 End;
 LoadFAT:=True;
End;

Function SaveFAT:Boolean;
Var J,K:LongInt; Buf:TSector;
Begin
 SaveFAT:=False;
 For K:=0 to BPB.NumFATs-1 do
  For J:=0 to BPB.SecPerFAT-1 do Begin
   Move(FATBuf^[J*512],Buf,512);
   If Not ImgWriteLBA(BPB.FAT1LBA+K*LongInt(BPB.SecPerFAT)+J,Buf,1)Then Exit;
  End;
 SaveFAT:=True;
End;

Function GetEOC:Word;
Begin
 If BPB.FATBits=12 Then GetEOC:=$FFF Else GetEOC:=$FFFF;
End;

Function GetFATEntry(N:Word):Word;
Var Idx:LongInt; B0,B1:Byte;
Begin
 If BPB.FATBits=12 Then Begin
  Idx:=LongInt(N)+(LongInt(N) shr 1);
  B0:=FATBuf^[Idx]; B1:=FATBuf^[Idx+1];
  If(N and 1)=0 Then GetFATEntry:=B0 or ((B1 and $0F) shl 8)
  Else GetFATEntry:=(B0 shr 4) or (Word(B1) shl 4);
 End Else Begin
  Idx:=LongInt(N)*2;
  GetFATEntry:=FATBuf^[Idx] or (Word(FATBuf^[Idx+1]) shl 8);
 End;
End;

Procedure SetFATEntry(N:Word;V:Word);
Var Idx:LongInt; B0,B1:Byte;
Begin
 If BPB.FATBits=12 Then Begin
  Idx:=LongInt(N)+(LongInt(N) shr 1);
  B0:=FATBuf^[Idx]; B1:=FATBuf^[Idx+1];
  If(N and 1)=0 Then Begin
   FATBuf^[Idx]:=Byte(V and $FF);
   FATBuf^[Idx+1]:=(B1 and $F0) or Byte((V shr 8) and $0F);
  End Else Begin
   FATBuf^[Idx]:=(B0 and $0F) or Byte((V and $0F) shl 4);
   FATBuf^[Idx+1]:=Byte((V shr 4) and $FF);
  End;
 End Else Begin
  Idx:=LongInt(N)*2;
  FATBuf^[Idx]:=Byte(V and $FF);
  FATBuf^[Idx+1]:=Byte((V shr 8) and $FF);
 End;
End;

Function AllocCluster:Word;
Var K:LongInt;
Begin
 For K:=2 to BPB.TotalClusters+1 do
  If GetFATEntry(K)=0 Then Begin
   SetFATEntry(K,GetEOC);
   AllocCluster:=K; Exit;
  End;
 AllocCluster:=0;
End;

Procedure FreeClusterChain(StartClus:Word);
Var C,Nxt:Word;
Begin
 C:=StartClus;
 While(C>=2)and(C<GetEOC)do Begin
  Nxt:=GetFATEntry(C);
  SetFATEntry(C,0);
  C:=Nxt;
 End;
End;

Function PadName83(Const N:String):String;
Var Dot:Integer; Nm,Xt,Res:String; J:Integer;
Begin
 Dot:=Pos('.',N);
 If Dot=0 Then Begin Nm:=N; Xt:=''; End
 Else Begin Nm:=Copy(N,1,Dot-1); Xt:=Copy(N,Dot+1,3); End;
 While Length(Nm)<8 do Nm:=Nm+' ';
 While Length(Xt)<3 do Xt:=Xt+' ';
 Res:=Copy(Nm,1,8)+Copy(Xt,1,3);
 For J:=1 to 11 do
  If(Res[J]>='a')and(Res[J]<='z')Then Res[J]:=Chr(Ord(Res[J])-32);
 PadName83:=Res;
End;

Function DeleteRootEntry(Const Name11:String):Boolean;
Var S:LongInt; Buf:TSector; Slot,J:Integer; EntryOfs:Word;
    Match:Boolean; OldClus:Word; Dirty:Boolean;
Begin
 DeleteRootEntry:=False;
 For S:=0 to BPB.RootDirSec-1 do Begin
  If Not ImgReadLBA(BPB.RootDirLBA+S,Buf,1)Then Exit;
  Dirty:=False;
  For Slot:=0 to 15 do Begin
   EntryOfs:=Slot*32;
   If Buf[EntryOfs]=0 Then Begin
    If Dirty Then If Not ImgWriteLBA(BPB.RootDirLBA+S,Buf,1)Then Exit;
    DeleteRootEntry:=True; Exit;
   End;
   If Buf[EntryOfs]=$E5 Then Continue;
   { Ignorer VFAT (attr $0F) }
   If Buf[EntryOfs+11]=$0F Then Continue;
   Match:=True;
   For J:=0 to 10 do
    If Buf[EntryOfs+J]<>Ord(Name11[J+1])Then Begin Match:=False; Break; End;
   If Match Then Begin
    OldClus:=GetLE16Buf(Buf,EntryOfs+26);
    If OldClus>=2 Then FreeClusterChain(OldClus);
    Buf[EntryOfs]:=$E5;
    Dirty:=True;
   End;
  End;
  If Dirty Then If Not ImgWriteLBA(BPB.RootDirLBA+S,Buf,1)Then Exit;
 End;
 DeleteRootEntry:=True;
End;

Function WriteRootEntry(Const Name83:String;Attr:Byte;StartClus:Word;
                         Sz:LongInt;Dt,Tm:Word):Boolean;
Var
 S:LongInt; Buf:TSector;
 Slot,J:Integer; EntryOfs:Word;
 Padded:String;
Begin
 WriteRootEntry:=False;
 Padded:=PadName83(Name83);
 For S:=0 to BPB.RootDirSec-1 do Begin
  If Not ImgReadLBA(BPB.RootDirLBA+S,Buf,1)Then Exit;
  For Slot:=0 to 15 do Begin
   EntryOfs:=Slot*32;
   If(Buf[EntryOfs]=0)or(Buf[EntryOfs]=$E5)Then Begin
    FillChar(Buf[EntryOfs],32,0);
    For J:=1 to 11 do Buf[EntryOfs+J-1]:=Ord(Padded[J]);
    Buf[EntryOfs+11]:=Attr;
    PutLE16Buf(Buf,EntryOfs+22,Tm);
    PutLE16Buf(Buf,EntryOfs+24,Dt);
    PutLE16Buf(Buf,EntryOfs+26,StartClus);
    PutLE32Buf(Buf,EntryOfs+28,Sz);
    If Not ImgWriteLBA(BPB.RootDirLBA+S,Buf,1)Then Exit;
    WriteRootEntry:=True; Exit;
   End;
  End;
 End;
 WriteLn('  Erreur: Repertoire racine plein.');
End;

Function CopySrcFileToImage(Const SrcPath,DestName:String;Attr:Byte;
                              Dt,Tm:Word):Boolean;
Var
 F:File;
 Got:Word;
 FSize:LongInt;
 ClusterSec:Byte;
 TotalSec:LongInt;
 ClustersNeeded:LongInt;
 FirstClus,PrevClus,CurClus:Word;
 SecBuf:TSector;
 SecIdx,SecInClus:LongInt;
 LBA:LongInt;
 Name11:String;
Begin
 CopySrcFileToImage:=False;
 Assign(F,SrcPath); FileMode:=0;
 {$I-} Reset(F,1); {$I+}
 If IOResult<>0 Then Begin
  WriteLn('  Fichier source introuvable: ',SrcPath); Exit;
 End;
 FSize:=FileSize(F);
 ClusterSec:=BPB.SecPerClus;
 TotalSec:=(FSize+511) div 512;
 ClustersNeeded:=(TotalSec+ClusterSec-1) div ClusterSec;

 { Effacer entree existante du meme nom }
 Name11:=PadName83(DestName);
 If Not DeleteRootEntry(Name11)Then Begin
  WriteLn('  Erreur: Lecture repertoire racine.'); Close(F); Exit;
 End;

 { Allouer la chaine de clusters }
 FirstClus:=0; PrevClus:=0;
 While ClustersNeeded>0 do Begin
  CurClus:=AllocCluster;
  If CurClus=0 Then Begin
   WriteLn('  Erreur: Plus d''unites d''allocation libres.'); Close(F); Exit;
  End;
  If FirstClus=0 Then FirstClus:=CurClus
  Else SetFATEntry(PrevClus,CurClus);
  PrevClus:=CurClus;
  Dec(ClustersNeeded);
 End;
 If FirstClus<>0 Then SetFATEntry(PrevClus,GetEOC);

 { Ecrire les donnees secteur par secteur }
 CurClus:=FirstClus; SecInClus:=0;
 SecIdx:=0;
 While SecIdx<TotalSec do Begin
  FillChar(SecBuf,512,0);
  {$I-} BlockRead(F,SecBuf,512,Got); {$I+}
  If IOResult<>0 Then Begin
   WriteLn('  Erreur: Lecture fichier source.'); Close(F); Exit;
  End;
  LBA:=BPB.DataLBA+(LongInt(CurClus)-2)*ClusterSec+SecInClus;
  If Not ImgWriteLBA(LBA,SecBuf,1)Then Begin
   WriteLn('  Erreur: Ecriture unite d''allocation image.'); Close(F); Exit;
  End;
  Inc(SecIdx);
  Inc(SecInClus);
  If SecInClus>=ClusterSec Then Begin
   SecInClus:=0;
   CurClus:=GetFATEntry(CurClus);
  End;
 End;
 Close(F);

 If Not WriteRootEntry(DestName,Attr,FirstClus,FSize,Dt,Tm)Then Exit;
 CopySrcFileToImage:=True;
End;

Function WriteMinimalBootSector:Boolean;
Const
 BootStub:Array[0..49] of Byte = (
  $FA,                                 { cli }
  $31,$C0,                             { xor ax,ax }
  $8E,$D8,                             { mov ds,ax }
  $8E,$C0,                             { mov es,ax }
  $BE,$5D,$7C,                         { mov si,7C5D (msg) }
  $AC,                                 { lodsb }
  $08,$C0,                             { or al,al }
  $74,$09,                             { jz halt (offset +9 -> 0x57) }
  $B4,$0E,                             { mov ah,0Eh }
  $BB,$07,$00,                         { mov bx,0007 }
  $CD,$10,                             { int 10h }
  $EB,$F2,                             { jmp short loop }
  $30,$E4,                             { xor ah,ah }
  $CD,$16,                             { int 16h (wait key) }
  $CD,$19,                             { int 19h (reboot) }
  $0D,$0A,
  $4E,$6F,$6E,$2D,$73,$79,$73,$74,$65,$6D,$20,
  $64,$69,$73,$6B,
  $0D,$0A,$00
 );
Var Buf:TSector; J:Integer;
Begin
 WriteMinimalBootSector:=False;
 If Not ImgReadLBA(BPB.PartLBA,Buf,1)Then Exit;
 { JMP a l'offset 0x3F (cf BPB FAT16: stub apres offset 0x3E) }
 Buf[0]:=$EB; Buf[1]:=$3C; Buf[2]:=$90;
 For J:=0 to 49 do Buf[$3F+J]:=BootStub[J];
 Buf[510]:=$55; Buf[511]:=$AA;
 WriteMinimalBootSector:=ImgWriteLBA(BPB.PartLBA,Buf,1);
End;

Function BuildSourcePath(Const FN:String):String;
Begin
 If(SourceDrive=#0)or(SourceDrive='@')Then BuildSourcePath:=FN
 Else BuildSourcePath:=SourceDrive+':\'+FN;
End;

Function PartTypeName(T:Byte):String;
Begin
 Case T of
  $00: PartTypeName:='Vide';
  $01: PartTypeName:='FAT12';
  $04: PartTypeName:='FAT16 (<32 Mo)';
  $05: PartTypeName:='Etendue CHS';
  $06: PartTypeName:='FAT16';
  $07: PartTypeName:='HPFS/NTFS/exFAT';
  $0B: PartTypeName:='FAT32 CHS';
  $0C: PartTypeName:='FAT32 LBA';
  $0E: PartTypeName:='FAT16 LBA';
  $0F: PartTypeName:='Etendue LBA';
  $82: PartTypeName:='Linux swap';
  $83: PartTypeName:='Linux';
  $A5: PartTypeName:='FreeBSD';
  $EE: PartTypeName:='GPT protective';
 Else
  PartTypeName:='Inconnu';
 End;
End;

Function DetectOSFromBootSec(Var Buf:TSector):String;
Var OEM:String; J:Integer;
Begin
 OEM:='';
 For J:=3 to 10 do
  If(Buf[J]>=32)and(Buf[J]<127)Then OEM:=OEM+Chr(Buf[J])
  Else OEM:=OEM+' ';
 { Detection par OEM string }
 If Pos('MSDOS5.0',OEM)>0 Then DetectOSFromBootSec:='MS-DOS 5.0+/Win9x'
 Else If Pos('MSWIN4.1',OEM)>0 Then DetectOSFromBootSec:='Windows 98/ME'
 Else If Pos('MSWIN4.0',OEM)>0 Then DetectOSFromBootSec:='Windows 95'
 Else If Pos('MSDOS',OEM)>0 Then DetectOSFromBootSec:='MS-DOS'
 Else If Pos('IBM',OEM)>0 Then DetectOSFromBootSec:='PC-DOS/IBM'
 Else If Pos('FRDOS',OEM)>0 Then DetectOSFromBootSec:='FreeDOS'
 Else If Pos('DRDOS',OEM)>0 Then DetectOSFromBootSec:='DR-DOS'
 Else If(Pos('NTFS',OEM)>0)Then DetectOSFromBootSec:='Windows NT/2000/XP+ (NTFS)'
 Else If(Pos('EXFAT',OEM)>0)Then DetectOSFromBootSec:='Windows (exFAT)'
 Else If(Pos('OS2',OEM)>0)or(Pos('HPFS',OEM)>0)Then DetectOSFromBootSec:='OS/2 (HPFS)'
 Else If(Pos('CORAILSY',OEM)>0)Then DetectOSFromBootSec:='Corail SYS (genere)'
 Else If(Pos('MTOOL',OEM)>0)or(Pos('mkfs',OEM)>0)Then DetectOSFromBootSec:='Linux mkfs/mtools'
 Else DetectOSFromBootSec:='Inconnu (OEM "'+OEM+'")';
End;

Function DetectFATFiles(Var Buf:TSector;Var FoundDOS:String):Boolean;
{ Buf = secteur du repertoire racine. Detecte les fichiers systeme presents. }
Var Slot,J:Integer; EntryOfs:Word; Nm:String;
    HasIO,HasMSDOS,HasIBMBIO,HasIBMDOS,HasKERNEL,HasPTSBIO,HasRXDOSBIO,HasCMD:Boolean;
    HasOS2BOOT,HasOS2LDR,HasOS2KRNL:Boolean;
    HasNTLDR,HasNTDETECT,HasBOOTINI:Boolean;
Begin
 HasIO:=False; HasMSDOS:=False; HasIBMBIO:=False; HasIBMDOS:=False;
 HasKERNEL:=False; HasPTSBIO:=False; HasRXDOSBIO:=False; HasCMD:=False;
 HasOS2BOOT:=False; HasOS2LDR:=False; HasOS2KRNL:=False;
 HasNTLDR:=False; HasNTDETECT:=False; HasBOOTINI:=False;
 For Slot:=0 to 15 do Begin
  EntryOfs:=Slot*32;
  If Buf[EntryOfs]=0 Then Break;
  If Buf[EntryOfs]=$E5 Then Continue;
  If Buf[EntryOfs+11]=$0F Then Continue;
  Nm:='';
  For J:=0 to 7 do If Buf[EntryOfs+J]<>$20 Then Nm:=Nm+Chr(Buf[EntryOfs+J]);
  Nm:=Nm+'.';
  For J:=8 to 10 do If Buf[EntryOfs+J]<>$20 Then Nm:=Nm+Chr(Buf[EntryOfs+J]);
  If(Length(Nm)>0)and(Nm[Length(Nm)]='.')Then Nm:=Copy(Nm,1,Length(Nm)-1);
  If Nm='IO.SYS' Then HasIO:=True;
  If Nm='MSDOS.SYS' Then HasMSDOS:=True;
  If Nm='IBMBIO.COM' Then HasIBMBIO:=True;
  If Nm='IBMDOS.COM' Then HasIBMDOS:=True;
  If Nm='KERNEL.SYS' Then HasKERNEL:=True;
  If Nm='PTSBIO.SYS' Then HasPTSBIO:=True;
  If Nm='RXDOSBIO.SYS' Then HasRXDOSBIO:=True;
  If Nm='OS2BOOT' Then HasOS2BOOT:=True;
  If Nm='OS2LDR' Then HasOS2LDR:=True;
  If Nm='OS2KRNL' Then HasOS2KRNL:=True;
  If Nm='NTLDR' Then HasNTLDR:=True;
  If Nm='NTDETECT.COM' Then HasNTDETECT:=True;
  If Nm='BOOT.INI' Then HasBOOTINI:=True;
  If Nm='COMMAND.COM' Then HasCMD:=True;
 End;
 FoundDOS:='';
 If HasNTLDR and HasNTDETECT Then Begin
  FoundDOS:='Windows NT/2000/XP';
  DetectFATFiles:=True;
  Exit;
 End;
 If HasOS2LDR and HasOS2KRNL Then Begin
  FoundDOS:='OS/2';
  DetectFATFiles:=True;
  Exit;
 End;
 If HasIO and HasMSDOS Then FoundDOS:='MS-DOS / Windows 9x'
 Else If HasIBMBIO and HasIBMDOS Then FoundDOS:='PC-DOS ou DR-DOS'
 Else If HasKERNEL Then FoundDOS:='FreeDOS'
 Else If HasPTSBIO Then FoundDOS:='PTS-DOS'
 Else If HasRXDOSBIO Then FoundDOS:='RxDOS';
 DetectFATFiles:=(FoundDOS<>'')and HasCMD;
End;

Procedure AnalyzeImage;
Var
 Sec0,SecBoot,RootSec:TSector;
 J:Integer;
 HasMBR,HasBPB:Boolean;
 PartType:Byte;
 PartStart,PartSize:LongInt;
 BPS:Word;
 SPC:Byte;
 OSGuess,DOSGuess:String;
 BootSig:Boolean;
 RootLBA:LongInt;
 TmpBPB:TBPB;
 FATBits:Byte;
 TotalCl:LongInt;
Begin
 WriteLn;
 WriteLn('=== Analyse de l''image ',ImgPath,' ===');
 Case ImgKind of
  0: WriteLn('Format conteneur : IMG brute');
  1: WriteLn('Format conteneur : VHD fixe');
 End;
 WriteLn('Taille image     : ',FileSize(ImgFile),' octets (',
         FileSize(ImgFile) div 512,' secteurs)');

 If Not ImgReadLBA(0,Sec0,1)Then Begin
  WriteLn('Erreur: Lecture secteur 0.'); Exit;
 End;
 BootSig:=(Sec0[510]=$55)and(Sec0[511]=$AA);
 WriteLn('Signature 55AA   : ',BootSig);

 BPS:=GetLE16Buf(Sec0,11);
 SPC:=Sec0[13];
 HasBPB:=(BPS=512)and(SPC<>0)and((SPC and (SPC-1))=0);
 HasMBR:=BootSig and(Not HasBPB);

 If HasBPB Then Begin
  WriteLn('Layout           : BPB direct (style disquette, pas de MBR)');
  PartStart:=0;
  PartSize:=FileSize(ImgFile) div 512;
  PartType:=$00;
  Move(Sec0,SecBoot,512);
 End Else If HasMBR Then Begin
  WriteLn('Layout           : MBR + table de partition');
  WriteLn;
  WriteLn('Partitions :');
  For J:=0 to 3 do Begin
   PartType:=Sec0[$1BE+J*16+4];
   PartStart:=GetLE32Buf(Sec0,$1BE+J*16+8);
   PartSize:=GetLE32Buf(Sec0,$1BE+J*16+12);
   If(PartType<>0)or(PartStart<>0)Then Begin
    WriteLn('  #',J+1,' Type=$',PartType,' (',PartTypeName(PartType),')');
    WriteLn('       Boot=',Sec0[$1BE+J*16]=$80,
            '  LBA=',PartStart,'  Taille=',PartSize,' sec (',
            PartSize div 2,' Ko)');
   End;
  End;
  { Analyser la premiere partition }
  PartType:=Sec0[$1BE+4];
  PartStart:=GetLE32Buf(Sec0,$1BE+8);
  PartSize:=GetLE32Buf(Sec0,$1BE+12);
  If(PartType<>0)and(PartStart<>0)Then Begin
   If Not ImgReadLBA(PartStart,SecBoot,1)Then Begin
    WriteLn('Erreur: Lecture secteur de boot partition #1.'); Exit;
   End;
  End Else Begin
   WriteLn;
   WriteLn('Aucune partition active : disque non partitionne ou vide.');
   Exit;
  End;
 End Else Begin
  WriteLn('Layout           : Aucun BPB ni MBR valide.');
  WriteLn('Verdict          : Image vide ou non formatee.');
  WriteLn('Action suggeree  : SYS /IMG:',ImgPath,' /FORMAT:FAT12 (ou FAT16) /DOS:MS-DOS');
  Exit;
 End;

 { Analyser le BPB de la partition (ou de l'image directement) }
 WriteLn;
 WriteLn('--- Secteur de boot partition ---');
 BPS:=GetLE16Buf(SecBoot,11);
 SPC:=SecBoot[13];
 BootSig:=(SecBoot[510]=$55)and(SecBoot[511]=$AA);
 WriteLn('Signature 55AA   : ',BootSig);
 WriteLn('BytesPerSec      : ',BPS);
 WriteLn('SecPerClus       : ',SPC);
 If(BPS<>512)or(SPC=0)or((SPC and (SPC-1))<>0)Then Begin
  WriteLn('Verdict          : Partition non formatee (BPB invalide).');
  WriteLn('Action suggeree  : SYS /IMG:',ImgPath,' /FORMAT:FAT12 (ou FAT16)');
  Exit;
 End;
 WriteLn('ReservedSec      : ',GetLE16Buf(SecBoot,14));
 WriteLn('NumFATs          : ',SecBoot[16]);
 WriteLn('RootEntries      : ',GetLE16Buf(SecBoot,17));
 WriteLn('SecPerFAT        : ',GetLE16Buf(SecBoot,22));
 OSGuess:=DetectOSFromBootSec(SecBoot);
 WriteLn('OEM/OS detecte   : ',OSGuess);

 { Reconstituer un BPB pour lire la racine }
 TmpBPB.PartLBA:=PartStart;
 TmpBPB.BytesPerSec:=BPS;
 TmpBPB.SecPerClus:=SPC;
 TmpBPB.ReservedSec:=GetLE16Buf(SecBoot,14);
 TmpBPB.NumFATs:=SecBoot[16];
 TmpBPB.RootEntries:=GetLE16Buf(SecBoot,17);
 TmpBPB.SecPerFAT:=GetLE16Buf(SecBoot,22);
 TmpBPB.TotalSec:=GetLE16Buf(SecBoot,19);
 If TmpBPB.TotalSec=0 Then TmpBPB.TotalSec:=GetLE32Buf(SecBoot,32);
 If(TmpBPB.NumFATs=0)or(TmpBPB.RootEntries=0)or(TmpBPB.SecPerFAT=0)Then Begin
  WriteLn('Verdict          : BPB FAT32 ou non-FAT (NumFATs/RootEntries/SecPerFAT nul).');
  Exit;
 End;
 RootLBA:=TmpBPB.PartLBA+TmpBPB.ReservedSec+
          LongInt(TmpBPB.NumFATs)*TmpBPB.SecPerFAT;
 { Estimer FAT12 vs FAT16 par compte de clusters }
 TotalCl:=(TmpBPB.TotalSec-(RootLBA-TmpBPB.PartLBA)-
          (LongInt(TmpBPB.RootEntries)*32 div 512)) div TmpBPB.SecPerClus;
 If TotalCl<4085 Then FATBits:=12
 Else If TotalCl<65525 Then FATBits:=16
 Else FATBits:=32;
 WriteLn('Type FAT estime  : FAT',FATBits,' (',TotalCl,' unites d''allocation de donnees)');

 If FATBits=32 Then Begin
  WriteLn('Verdict          : Volume FAT32 (non supporte par SYS).');
  Exit;
 End;

 { Lire le premier secteur du repertoire racine et y chercher les fichiers DOS }
 If Not ImgReadLBA(RootLBA,RootSec,1)Then Begin
  WriteLn('Erreur: Lecture repertoire racine.'); Exit;
 End;
 WriteLn;
 WriteLn('--- Repertoire racine ---');
 If DetectFATFiles(RootSec,DOSGuess)Then Begin
  WriteLn('Fichiers systeme : presents');
  WriteLn('DOS installe     : ',DOSGuess);
  WriteLn('Verdict          : Disque amorcable (',DOSGuess,').');
 End Else If DOSGuess<>''Then Begin
  WriteLn('Fichiers systeme : partiels (',DOSGuess,' sans COMMAND.COM)');
  WriteLn('Verdict          : Disque incomplet.');
 End Else Begin
  WriteLn('Fichiers systeme : aucun fichier DOS reconnu');
  WriteLn('Verdict          : Volume formate mais sans systeme.');
  WriteLn('Action suggeree  : SYS /IMG:',ImgPath,' /DOS:MS-DOS (ou autre)');
 End;
End;

Procedure SetupDosFamily(Fam:Byte);
Begin
 DosFamily:=Fam;
 Case Fam of
  DOS_MSDOS: Begin
   SysFiles[1]:='IO.SYS';
   SysFiles[2]:='MSDOS.SYS';
   SysFiles[3]:='COMMAND.COM';
   SysFileCount:=3;
  End;
  DOS_PCDOS: Begin
   SysFiles[1]:='IBMBIO.COM';
   SysFiles[2]:='IBMDOS.COM';
   SysFiles[3]:='COMMAND.COM';
   SysFileCount:=3;
  End;
  DOS_DRDOS: Begin
   SysFiles[1]:='IBMBIO.COM';
   SysFiles[2]:='IBMDOS.COM';
   SysFiles[3]:='COMMAND.COM';
   SysFileCount:=3;
  End;
  DOS_FREEDOS: Begin
   SysFiles[1]:='KERNEL.SYS';
   SysFiles[2]:='COMMAND.COM';
   SysFiles[3]:='';
   SysFileCount:=2;
  End;
  DOS_RXDOS: Begin
   SysFiles[1]:='RXDOSBIO.SYS';
   SysFiles[2]:='RXDOS.SYS';
   SysFiles[3]:='COMMAND.COM';
   SysFileCount:=3;
  End;
  DOS_WIN95: Begin
   { Windows 95 / MS-DOS 7 : IO.SYS contient le noyau, MSDOS.SYS est texte }
   SysFiles[1]:='IO.SYS';
   SysFiles[2]:='MSDOS.SYS';
   SysFiles[3]:='COMMAND.COM';
   SysFileCount:=3;
  End;
  DOS_PTSDOS: Begin
   SysFiles[1]:='PTSBIO.SYS';
   SysFiles[2]:='PTSDOS.SYS';
   SysFiles[3]:='COMMAND.COM';
   SysFileCount:=3;
  End;
  DOS_OS2: Begin
   { OS/2 (HPFS ou FAT) : amorceur OS2BOOT, loader OS2LDR, noyau OS2KRNL }
   SysFiles[1]:='OS2BOOT';
   SysFiles[2]:='OS2LDR';
   SysFiles[3]:='OS2KRNL';
   SysFileCount:=3;
  End;
  DOS_WINNT: Begin
   { Windows NT/2000/XP : NTLDR charge le noyau via boot.ini, NTDETECT.COM
     enumere le materiel. Sur FAT/FAT32 partition systeme. }
   SysFiles[1]:='NTLDR';
   SysFiles[2]:='NTDETECT.COM';
   SysFiles[3]:='BOOT.INI';
   SysFileCount:=3;
  End;
 End;
End;

Function DosFamilyName:String;
Begin
 Case DosFamily of
  DOS_MSDOS:   DosFamilyName:='MS-DOS';
  DOS_PCDOS:   DosFamilyName:='PC-DOS';
  DOS_DRDOS:   DosFamilyName:='DR-DOS';
  DOS_FREEDOS: DosFamilyName:='FreeDOS';
  DOS_RXDOS:   DosFamilyName:='RxDOS';
  DOS_WIN95:   DosFamilyName:='Windows 95 (MS-DOS 7)';
  DOS_PTSDOS:  DosFamilyName:='PTS-DOS';
  DOS_OS2:     DosFamilyName:='OS/2';
  DOS_WINNT:   DosFamilyName:='Windows NT/2000/XP';
 Else
  DosFamilyName:='?';
 End;
End;

Function ParseDosFamily(Const S:String;Var Fam:Byte):Boolean;
Var U:String;
Begin
 ParseDosFamily:=True;
 U:=UpperStr(S);
 If(U='MS-DOS')or(U='MSDOS')or(U='MS')Then Fam:=DOS_MSDOS
 Else If(U='PC-DOS')or(U='PCDOS')or(U='PC')or(U='IBM')Then Fam:=DOS_PCDOS
 Else If(U='DR-DOS')or(U='DRDOS')or(U='DR')Then Fam:=DOS_DRDOS
 Else If(U='FREEDOS')or(U='FREE')or(U='FDOS')Then Fam:=DOS_FREEDOS
 Else If(U='RXDOS')or(U='RX')Then Fam:=DOS_RXDOS
 Else If(U='WIN95')or(U='WIN9X')or(U='W95')or(U='MSDOS7')or(U='MS-DOS7')or(U='WINDOWS95')Then Fam:=DOS_WIN95
 Else If(U='PTS-DOS')or(U='PTSDOS')or(U='PTS')Then Fam:=DOS_PTSDOS
 Else If(U='OS/2')or(U='OS2')or(U='IBMOS2')Then Fam:=DOS_OS2
 Else If(U='NT')or(U='WINNT')or(U='WIN-NT')or(U='WINDOWS-NT')or(U='WINNT4')or
   (U='WIN2K')or(U='W2K')or(U='WINXP')or(U='XP')or(U='WIN2000')Then Fam:=DOS_WINNT
 Else ParseDosFamily:=False;
End;

{ Marque la partition PartNum (1..4) comme active dans la table de partition
  du MBR, et desactive les trois autres. Necessite un MBR valide (signature
  55AA + au moins une entree non vide). Retourne True si succes. }
Function SetActivePartition(PartNum:Byte):Boolean;
Var
 Sec0:TSector;
 K:Integer;
 Ofs:Word;
 PT:Byte;
Begin
 SetActivePartition:=False;
 If(PartNum<1)or(PartNum>4)Then Begin
  WriteLn('Erreur: /ACTIVE numero de partition invalide.');
  Exit;
 End;
 If Not ImgReadLBA(0,Sec0,1)Then Begin
  WriteLn('Erreur: lecture du MBR.');
  Exit;
 End;
 If(Sec0[510]<>$55)or(Sec0[511]<>$AA)Then Begin
  WriteLn('Erreur: pas de signature MBR (55AA), impossible d''activer une partition.');
  Exit;
 End;
 Ofs:=$1BE+(LongInt(PartNum)-1)*16;
 PT:=Sec0[Ofs+4];
 If PT=0 Then Begin
  WriteLn('Erreur: la partition #',PartNum,' est vide (type=0).');
  Exit;
 End;
 { Desactiver toutes les partitions, puis activer celle demandee }
 For K:=0 to 3 do Sec0[$1BE+K*16]:=$00;
 Sec0[Ofs]:=$80;
 If Not ImgWriteLBA(0,Sec0,1)Then Begin
  WriteLn('Erreur: ecriture du MBR.');
  Exit;
 End;
 WriteLn('Partition #',PartNum,' marquee active (bootable).');
 SetActivePartition:=True;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('SYS : Cette commande permet de transferer les fichiers systemes.');
  WriteLn;
  WriteLn('Syntaxe : SYS [source:] [destination:] [/IMG:fichier]');
  WriteLn('              [/FORMAT:FAT12|FAT16] [/DOS:famille]');
  WriteLn('              [/NOBOOT] [/ACTIVE[:N]] [/INFO]');
  WriteLn;
  WriteLn(' source:        Lecteur source des fichiers systeme (defaut: rep. courant)');
  WriteLn(' destination:   Lecteur cible (omis si /IMG: est specifie)');
  WriteLn(' /IMG:fichier   Ecrit les fichiers systeme dans une image disque');
  WriteLn('                au lieu d''un lecteur reel. Formats acceptes :');
  WriteLn('                  - Image brute .IMG (lecture/ecriture)');
  WriteLn('                  - VHD fixe VirtualBox (lecture/ecriture)');
  WriteLn('                Les formats TeleDisk (.TD0), VHD dynamique et');
  WriteLn('                VMDK sparse ne sont supportes qu''en lecture par');
  WriteLn('                UNDISKPC; les convertir vers .IMG brute au prealable.');
  WriteLn(' /FORMAT:FAT12  Formate la partition cible en FAT12 avant transfert.');
  WriteLn(' /FORMAT:FAT16  Formate la partition cible en FAT16 avant transfert.');
  WriteLn('                Si l''image n''a pas de MBR, un MBR avec une seule');
  WriteLn('                partition couvrant toute l''image est cree.');
  WriteLn(' /DOS:famille   Selectionne la famille DOS (defaut: MS-DOS). Valeurs :');
  WriteLn('                  MS-DOS   -> IO.SYS, MSDOS.SYS, COMMAND.COM');
  WriteLn('                  PC-DOS   -> IBMBIO.COM, IBMDOS.COM, COMMAND.COM');
  WriteLn('                  DR-DOS   -> IBMBIO.COM, IBMDOS.COM, COMMAND.COM');
  WriteLn('                  FreeDOS  -> KERNEL.SYS, COMMAND.COM');
  WriteLn('                  RxDOS    -> RXDOSBIO.SYS, RXDOS.SYS, COMMAND.COM');
  WriteLn('                  Win95    -> IO.SYS, MSDOS.SYS, COMMAND.COM (MS-DOS 7)');
  WriteLn('                  PTS-DOS  -> PTSBIO.SYS, PTSDOS.SYS, COMMAND.COM');
  WriteLn('                  OS/2     -> OS2BOOT, OS2LDR, OS2KRNL');
  WriteLn('                  WinNT    -> NTLDR, NTDETECT.COM, BOOT.INI (NT/2K/XP)');
  WriteLn(' /NOBOOT        Ne pas reecrire le secteur de boot de l''image apres');
  WriteLn('                le transfert (le /FORMAT en cree deja un correct).');
  WriteLn(' /ACTIVE[:N]    Marque la partition N (1..4, defaut 1) comme active');
  WriteLn('                (bootable) dans le MBR, et desactive les autres. Utile');
  WriteLn('                pour les images de disque dur multi-partitions.');
  WriteLn(' /INFO          Analyse l''image et affiche le type de partition,');
  WriteLn('                le secteur de boot, le BPB, le type FAT et le DOS');
  WriteLn('                installe. Aucune ecriture n''est effectuee.');
  WriteLn;
  WriteLn('En mode /IMG:, les fichiers IO.SYS, MSDOS.SYS et COMMAND.COM sont');
  WriteLn('lus depuis le repertoire courant (ou source: si specifie) puis ecrits');
  WriteLn('dans le repertoire racine FAT12/FAT16 de l''image, avec allocation');
  WriteLn('correcte des unites d''allocation et mise a jour de toutes les copies de ');
  WriteLn('la FAT.');
  Halt;
 End;

 { Premiere passe : detecter /IMG:fichier et collecter parametres positionnels }
 UseImg:=False; ImgPath:=''; ImgKind:=0; NoBoot:=False; InfoOnly:=False;
 ActiveReq:=0;
 FormatReq:=0; { 0=non, 12=FAT12, 16=FAT16 }
 SetupDosFamily(DOS_MSDOS);  { Defaut : MS-DOS }
 SourceDrive:=#0; DestDrive:=#0;
 For i:=1 to ParamCount do Begin
  CurrParam:=ParamStr(i);
  If StartsWith(CurrParam,'/IMG:')Then ImgPath:=Copy(CurrParam,6,Length(CurrParam)-5)
  Else
  If StartsWith(CurrParam,'-IMG:')Then ImgPath:=Copy(CurrParam,6,Length(CurrParam)-5)
  Else
  If StartsWith(CurrParam,'--IMG:')Then ImgPath:=Copy(CurrParam,7,Length(CurrParam)-6)
  Else
  If StartsWith(CurrParam,'/DOS:')Then Begin
   If Not ParseDosFamily(Copy(CurrParam,6,Length(CurrParam)-5),DosFamily)Then Begin
    WriteLn('Erreur: famille DOS inconnue : ',Copy(CurrParam,6,Length(CurrParam)-5));
    WriteLn('  Valeurs acceptees: MS-DOS, PC-DOS, DR-DOS, FreeDOS, RxDOS.');
    Halt(1);
   End;
   SetupDosFamily(DosFamily);
  End
  Else
  If StartsWith(CurrParam,'-DOS:')Then Begin
   If Not ParseDosFamily(Copy(CurrParam,6,Length(CurrParam)-5),DosFamily)Then Halt(1);
   SetupDosFamily(DosFamily);
  End
  Else
  If StartsWith(CurrParam,'--DOS:')Then Begin
   If Not ParseDosFamily(Copy(CurrParam,7,Length(CurrParam)-6),DosFamily)Then Halt(1);
   SetupDosFamily(DosFamily);
  End
  Else
  If(UpperStr(CurrParam)='/FORMAT:FAT12')or(UpperStr(CurrParam)='-FORMAT:FAT12')or
    (UpperStr(CurrParam)='--FORMAT:FAT12')Then FormatReq:=12
  Else
  If(UpperStr(CurrParam)='/FORMAT:FAT16')or(UpperStr(CurrParam)='-FORMAT:FAT16')or
    (UpperStr(CurrParam)='--FORMAT:FAT16')Then FormatReq:=16
  Else
  If(UpperStr(CurrParam)='/NOBOOT')or(UpperStr(CurrParam)='-NOBOOT')or
    (UpperStr(CurrParam)='--NOBOOT')Then NoBoot:=True
  Else
  If(UpperStr(CurrParam)='/INFO')or(UpperStr(CurrParam)='-INFO')or
    (UpperStr(CurrParam)='--INFO')or(UpperStr(CurrParam)='/ANALYZE')or
    (UpperStr(CurrParam)='/ANALYSE')Then InfoOnly:=True
  Else
  If(UpperStr(CurrParam)='/ACTIVE')or(UpperStr(CurrParam)='-ACTIVE')or
    (UpperStr(CurrParam)='--ACTIVE')Then ActiveReq:=1
  Else
  If(Length(CurrParam)>=8)and
    ((Copy(UpperStr(CurrParam),1,8)='/ACTIVE:')or
     (Copy(UpperStr(CurrParam),1,8)='-ACTIVE:'))Then Begin
   Val(Copy(CurrParam,9,Length(CurrParam)-8),ActiveReq,ErrorCode);
   If(ErrorCode<>0)or(ActiveReq<1)or(ActiveReq>4)Then Begin
    WriteLn('Erreur: /ACTIVE attend un numero de partition entre 1 et 4.');
    Halt(1);
   End;
  End
  Else
  If(Length(CurrParam)>=9)and(Copy(UpperStr(CurrParam),1,9)='--ACTIVE:')Then Begin
   Val(Copy(CurrParam,10,Length(CurrParam)-9),ActiveReq,ErrorCode);
   If(ErrorCode<>0)or(ActiveReq<1)or(ActiveReq>4)Then Begin
    WriteLn('Erreur: /ACTIVE attend un numero de partition entre 1 et 4.');
    Halt(1);
   End;
  End
  Else
  If(Length(CurrParam)>0)and(CurrParam[1]<>'/')and(CurrParam[1]<>'-')Then Begin
   If SourceDrive=#0 Then SourceDrive:=CurrParam[1]
   Else If DestDrive=#0 Then DestDrive:=CurrParam[1];
  End;
 End;

 If ImgPath<>''Then Begin
  { Mode image : la "destination" est le fichier image }
  UseImg:=True;
  If(SourceDrive<>#0)and(DestDrive<>#0)Then
   WriteLn('Avertissement: parametre destination ignore car /IMG: est specifie.');
  DestDrive:='@'; { sentinel }
  If Not OpenImage(ImgPath)Then Halt(1);
  Case ImgKind of
   0: WriteLn('Image: ',ImgPath,' (IMG brute)');
   1: WriteLn('Image: ',ImgPath,' (VHD fixe)');
  End;
  If InfoOnly Then Begin
   AnalyzeImage;
   Close(ImgFile);
   Halt;
  End;
  GetMem(FATBuf,MAX_FAT_BYTES);
  If FATBuf=Nil Then Begin
   WriteLn('Erreur: Memoire insuffisante pour la FAT.');
   Close(ImgFile); Halt(1);
  End;
  FillChar(FATBuf^,MAX_FAT_BYTES,0);
  If FormatReq<>0 Then Begin
   If Not FormatImage(FormatReq)Then Begin
    FreeMem(FATBuf,MAX_FAT_BYTES); Close(ImgFile); Halt(1);
   End;
   { FormatImage a deja rempli BPB; pas besoin de LoadBPB }
  End Else Begin
   If Not LoadBPB Then Begin
    WriteLn('Astuce: utilisez /FORMAT:FAT12 ou /FORMAT:FAT16 pour formater l''image.');
    FreeMem(FATBuf,MAX_FAT_BYTES); Close(ImgFile); Halt(1);
   End;
   WriteLn('  FAT', BPB.FATBits, ': ', BPB.TotalClusters,
           ' unites d''allocation, ', BPB.SecPerClus, ' secteur(s)/unite d''allocation, ',
           BPB.RootEntries, ' entrees racine.');
  End;
  If Not LoadFAT Then Begin
   WriteLn('Erreur: Lecture de la FAT.');
   FreeMem(FATBuf,MAX_FAT_BYTES); Close(ImgFile); Halt(1);
  End;
  Success:=True;
  PackDOSDateTime(ImgDt,ImgTm);
  WriteLn('Famille DOS : ',DosFamilyName);
  For i:=1 to SysFileCount do Begin
   ImgSrcPath:=BuildSourcePath(SysFiles[i]);
   Write('Copiage de ', SysFiles[i], ' depuis ', ImgSrcPath, '... ');
   If SysFiles[i]='COMMAND.COM' Then ImgAttr:=$20
   Else ImgAttr:=$27;  { read-only + hidden + system + archive }
   If CopySrcFileToImage(ImgSrcPath,SysFiles[i],ImgAttr,ImgDt,ImgTm)
    Then WriteLn('OK')
   Else Begin Success:=False; Break; End;
  End;
  If Success Then Begin
   If Not SaveFAT Then Begin
    WriteLn('Erreur: Ecriture de la FAT.'); Success:=False;
   End Else If Not NoBoot Then Begin
    If WriteMinimalBootSector Then WriteLn('Secteur de boot minimal ecrit.')
    Else WriteLn('Avertissement: Ecriture du secteur de boot echouee.');
   End;
   If Success and(ActiveReq>0)Then Begin
    If Not SetActivePartition(ActiveReq)Then Success:=False;
   End;
  End;
  Close(ImgFile);
  FreeMem(FATBuf,MAX_FAT_BYTES);
  If Success Then WriteLn('Systeme transfere dans l''image.')
             Else WriteLn('Echec du transfert du systeme.');
 End
 Else Begin
  { Mode lecteur classique (DOS uniquement, peu fiable hors DOS) }
  If(SourceDrive=#0)and(DestDrive=#0)Then Begin
   WriteLn('Erreur: Aucun lecteur destination specifie.');
   Halt(1);
  End;
  If DestDrive=#0 Then Begin
   DestDrive:=SourceDrive;
   SourceDrive:='C';
  End;
  If Not ReserveFATSpace(DestDrive)Then Begin
   WriteLn('Erreur: Impossible de mettre a jour la FAT dans la destination');
   Halt(1);
  End;
  Success:=True;
  For i:=1 to SysFileCount do Begin
   Write('Copiage de ', SysFiles[i], '... ');
   If CopySystemFile(SysFiles[i], SourceDrive, DestDrive)Then WriteLn('OK')
   Else Begin
    WriteLn('echec'); Success:=False; Break;
   End;
  End;
  If Success Then WriteLn('Systeme transfere')
             Else WriteLn('Echec du transfert du systeme');
 End;
END.
