{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program FDISK;

{$A-}

Uses Crt,DOS;

Type
 {Structure de lecture pour le disque }
 SecPosType=Record
  Head:Byte;
  SectTrack:Word;
 End;

 {Structure de partition}
 PartEntry=Record
  Status:Byte;
  StartSec:SecPosType;
  PartType:Byte;
  EndSec:SecPosType;
  SecOfs,NumSec:LongInt;
 End;

 PartSec=Record { d‚crit le secteur de partition }
  BootCode:Array[0..$1BD]of Byte;    { Code de d‚marrage du disque dur }
  PartTable:Array[0..3]of PartEntry; { Table des partitions de disque dur }
  IdCode:Word;                       { Signature: AA55h }
 End;

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 CurrentDisk:Byte;
 IsDisk:Boolean;
 FileName:String;
 Buffer:Array[0..1023]of Byte;
 CliI:Byte;
 CliJ,CliCode:Integer;
 { Format d'image detecte : raw, VHD fixe, VHD dynamique ou VMDK sparse. }
 VHDKind:(_VHDNone,_VHDFixed,_VHDDynamic,_VMDKSparse);
 VHDDiskSec:LongInt;        { Taille virtuelle en secteurs }
 VHDBlockSizeSec:LongInt;   { Sectors per block (VHD dyn) / per grain (VMDK) }
 VHDBitmapSecs:LongInt;     { Secteurs occupes par le bitmap (VHD dyn) }
 VHDBATFileOfs:LongInt;     { Offset fichier de la BAT (VHD) / GD (VMDK) }
 VMDKGTEsPerGT:LongInt;     { Nombre d'entrees par grain table (VMDK) }
 FsHint:Byte;               { Hint dernier ParsePartType : 0=none 1=NTFS 2=HPFS }

Procedure DiskReset;
{$IFDEF Windows}
 Begin
  WriteLn('Cette operation n''est pas mise en oeuvre.');
  Halt;
 End;
{$ElSE}
 Var
  Regs:Registers;
 Begin
  Regs.AH:=$00;
  Regs.DL:=0;
  Intr($13,Regs);
 End;
{$ENDIF}

Function ReadTrack(Lecteur,Face,Piste,Start,Nombre:Byte;Var Buffer):Byte;
{$IFDEF Windows}
 Begin
  WriteLn('Cette operation n''est pas mise en oeuvre.');
  Halt;
 End;
{$ElSE}
 Var
  Essais:Byte;
  Regs:Registers;
 Begin
  essais:=5;
  Repeat
   WriteLn(Essais);
   Regs.AH:=$02;        { Numero de fonction pour appel interruption }
   Regs.AL:=Nombre;     { Nombre Secteurs par Piste }
   Regs.CH:=Piste;      { Numero de Piste }
   Regs.CL:=Start;      { Commencer par le secteur 1 }
   Regs.DL:=Lecteur;    { Numero de lecteur }
   Regs.DH:=Face;       { Numero de la face }
   Regs.ES:=Seg(Buffer);{ Adresse pour tampon }
   Regs.BX:=Ofs(Buffer);
   Intr($13,Regs);
   If Regs.flags and fcarry=1Then DiskReset;
   Dec(essais);
  Until(Regs.flags and fcarry=0)or(Essais=0);
  ReadTrack:=Regs.AH;
 End;
{$ENDIF}

Function WriteTrack(Lecteur,Face,Piste,Start,Nombre:Byte;Var Buffer):Byte;
{$IFDEF Windows}
 Begin
  WriteLn('Cette operation n''est pas mise en oeuvre.');
  Halt;
 End;
{$ElSE}
 Var
  Essais:Byte;
  Regs:Registers;
 Begin
  essais:=5;
  Repeat
   Regs.AH:=$03;        { Numero de fonction pour appel interruption }
   Regs.AL:=Nombre;     { Nombre Secteurs par Piste }
   Regs.CH:=Piste;      { Numero de Piste }
   Regs.CL:=Start;      { Commencer par le secteur 1 }
   Regs.DL:=Lecteur;    { Numero de lecteur }
   Regs.DH:=Face;       { Numero de la face }
   Regs.ES:=Seg(Buffer);{ Adresse pour tampon }
   Regs.BX:=Ofs(Buffer);
   Intr($13,Regs);
   If Regs.flags and fcarry=1Then DiskReset;
   Dec(essais);
  Until(Regs.flags and fcarry=0)or(Essais=0);
  WriteTrack:=Regs.AH;
 End;
{$ENDIF}

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
End;

Procedure WriteLnCenter(S:String);Begin
 GotoXY((((Lo(WindMax)-Lo(WindMin))-Length(S))shr 1),WhereY);
 WriteLn(S);
End;

{ Detecte le format de l'image (raw, VHD fixe, VHD dynamique, VMDK sparse,
  ou VMDK descripteur texte). A appeler apres chaque changement de FileName. }
{$R-}
Procedure DetectImageFormat;
Var
 F:File;
 Sec:Array[0..511]of Byte;
 BR:Word;
 Sz,BlockSize,BAToff,CurSize:LongInt;
 DiskType:LongInt;
 I,J,K:Integer;
 S,ExtName,DescDir:String;
 ExtSecs,ExtOfs:LongInt;
 Code:Integer;

 Function ReadLE32(Ofs:Integer):LongInt;
 Begin
  ReadLE32:=LongInt(Sec[Ofs])
           Or(LongInt(Sec[Ofs+1])Shl 8)
           Or(LongInt(Sec[Ofs+2])Shl 16)
           Or(LongInt(Sec[Ofs+3])Shl 24);
 End;

Begin
 VHDKind:=_VHDNone;
 VHDDiskSec:=0;
 VHDBlockSizeSec:=0;
 VHDBitmapSecs:=0;
 VHDBATFileOfs:=0;
 VMDKGTEsPerGT:=0;
 If FileName='' Then Exit;
 {$I-}Assign(F,FileName);Reset(F,1);{$I+}
 If IOResult<>0 Then Exit;
 { Lecture du secteur 0 pour detection VMDK ou descripteur texte. }
 FillChar(Sec,SizeOf(Sec),0);
 {$I-}BlockRead(F,Sec,512,BR);{$I+}
 If IOResult<>0 Then Begin Close(F); Exit; End;
 { Tolere BR<512 pour les fichiers descripteurs courts }
 If BR=0 Then Begin Close(F); Exit; End;

 { ===== VMDK sparse : magic 'KDMV' (0x564D444B little-endian) ===== }
 If(Sec[0]=$4B)And(Sec[1]=$44)And(Sec[2]=$4D)And(Sec[3]=$56)Then Begin
  { Capacity @ +12 (8 LE, low 32 @ +12..+15) }
  VHDDiskSec:=ReadLE32(12);
  { GrainSize @ +20 (8 LE, low 32 @ +20..+23) }
  VHDBlockSizeSec:=ReadLE32(20);
  If(VHDBlockSizeSec<=0)Then Begin Close(F); Exit; End;
  { NumGTEsPerGT @ +44 (4 LE) }
  VMDKGTEsPerGT:=ReadLE32(44);
  If(VMDKGTEsPerGT<=0)Then Begin Close(F); Exit; End;
  { GDOffset @ +56 (8 LE) -- offset en SECTEURS }
  BAToff:=ReadLE32(56);
  If BAToff<=0 Then BAToff:=ReadLE32(48); { fallback : RGDOffset }
  If BAToff<=0 Then Begin Close(F); Exit; End;
  VHDBATFileOfs:=BAToff*512;
  VHDKind:=_VMDKSparse;
  Close(F);
  Exit;
 End;

 { ===== VMDK descripteur texte : commence par '# Disk DescriptorFile'
   ou contient 'createType=' et lignes 'RW <N> FLAT "..."' ===== }
 If(Sec[0]=$23)Or((Sec[0]>=Ord('A'))And(Sec[0]<=Ord('z')))Then Begin
  { Construire chaine depuis le secteur (jusqu'a 511 chars) }
  S:='';
  For I:=0 To 511 Do
   If(Sec[I]>=32)Or(Sec[I]=10)Or(Sec[I]=13)Or(Sec[I]=9)Then
    S:=S+Chr(Sec[I])
   Else
    S:=S+' ';
  { Cherche un marqueur 'Disk DescriptorFile' ou 'createType' }
  I:=Pos('DescriptorFile',S);
  If I=0 Then I:=Pos('createType',S);
  If I=0 Then I:=Pos('# Disk',S);
  If I>0 Then Begin
   { Cherche ligne 'RW <N> FLAT "nom"' }
   I:=Pos('RW ',S);
   If(I>0)And(Pos('FLAT',S)>I)Then Begin
    { Extraire nombre apres 'RW ' }
    K:=I+3;
    While(K<=Length(S))And(S[K]=' ')Do Inc(K);
    ExtName:='';
    While(K<=Length(S))And(S[K] in['0'..'9'])Do Begin
     ExtName:=ExtName+S[K]; Inc(K);
    End;
    Val(ExtName,ExtSecs,Code);
    If Code<>0 Then ExtSecs:=0;
    { Trouver '"' ouvrante apres FLAT }
    I:=Pos('FLAT',S);
    K:=I+4;
    While(K<=Length(S))And(S[K]<>'"')Do Inc(K);
    If(K<Length(S))And(S[K]='"')Then Begin
     Inc(K);
     ExtName:='';
     While(K<=Length(S))And(S[K]<>'"')Do Begin
      ExtName:=ExtName+S[K]; Inc(K);
     End;
     { Offset (apres '"') }
     If S[K]='"' Then Inc(K);
     While(K<=Length(S))And(S[K]=' ')Do Inc(K);
     DescDir:='';
     While(K<=Length(S))And(S[K] in['0'..'9'])Do Begin
      DescDir:=DescDir+S[K]; Inc(K);
     End;
     Val(DescDir,ExtOfs,Code);
     If Code<>0 Then ExtOfs:=0;
     Close(F);
     { Resoudre chemin relatif a la position du descripteur }
     DescDir:=FileName;
     J:=Length(DescDir);
     While(J>0)And(DescDir[J]<>'\')And(DescDir[J]<>'/')And(DescDir[J]<>':')Do Dec(J);
     DescDir:=Copy(DescDir,1,J);
     { Si ExtName n'a pas de chemin absolu, prefixer }
     If(Pos(':',ExtName)=0)And(Length(ExtName)>0)And
       (ExtName[1]<>'\')And(ExtName[1]<>'/')Then
      ExtName:=DescDir+ExtName;
     { Bascule sur le fichier d'extension brut (raw flat) }
     FileName:=ExtName;
     VHDDiskSec:=ExtSecs;
     { Re-detection au cas ou l'extension serait elle-meme VHD/VMDK }
     DetectImageFormat;
     Exit;
    End;
   End;
   Close(F);
   Exit;
  End;
 End;

 { ===== VHD : footer 'conectix' aux 512 derniers octets ===== }
 Sz:=FileSize(F);
 If(Sz<1024)Or(Sz<0)Then Begin Close(F); Exit; End;
 {$I-}Seek(F,Sz-512);{$I+}
 If IOResult<>0 Then Begin Close(F); Exit; End;
 {$I-}BlockRead(F,Sec,512,BR);{$I+}
 If(IOResult<>0)Or(BR<>512)Then Begin Close(F); Exit; End;
 { Cookie 'conectix' }
 If(Sec[0]<>$63)Or(Sec[1]<>$6F)Or(Sec[2]<>$6E)Or(Sec[3]<>$65)Or
   (Sec[4]<>$63)Or(Sec[5]<>$74)Or(Sec[6]<>$69)Or(Sec[7]<>$78)Then Begin
  Close(F); Exit;
 End;
 { DiskType (4 BE) @ +60 : 2=fixe, 3=dynamique, 4=differencing }
 DiskType:=(LongInt(Sec[60])Shl 24)Or(LongInt(Sec[61])Shl 16)
          Or(LongInt(Sec[62])Shl 8)Or LongInt(Sec[63]);
 { CurrentSize (8 BE) @ +48 : on prend les 32 bits bas (offset +52..+55) }
 CurSize:=(LongInt(Sec[52])Shl 24)Or(LongInt(Sec[53])Shl 16)
         Or(LongInt(Sec[54])Shl 8)Or LongInt(Sec[55]);
 VHDDiskSec:=CurSize Div 512;
 Case DiskType Of
  2:Begin VHDKind:=_VHDFixed; Close(F); Exit; End;
  3,4:Begin
   { Dynamic header @ offset 512 }
   {$I-}Seek(F,512);{$I+}
   If IOResult<>0 Then Begin Close(F); Exit; End;
   {$I-}BlockRead(F,Sec,512,BR);{$I+}
   If(IOResult<>0)Or(BR<>512)Then Begin Close(F); Exit; End;
   { Cookie 'cxsparse' }
   If(Sec[0]<>$63)Or(Sec[1]<>$78)Or(Sec[2]<>$73)Or(Sec[3]<>$70)Or
     (Sec[4]<>$61)Or(Sec[5]<>$72)Or(Sec[6]<>$73)Or(Sec[7]<>$65)Then Begin
    Close(F); Exit;
   End;
   { TableOffset (8 BE) @ +16, low 32 bits @ +20..+23 }
   BAToff:=(LongInt(Sec[20])Shl 24)Or(LongInt(Sec[21])Shl 16)
          Or(LongInt(Sec[22])Shl 8)Or LongInt(Sec[23]);
   { BlockSize (4 BE) @ +32 (typique : 2 MB = 2097152) }
   BlockSize:=(LongInt(Sec[32])Shl 24)Or(LongInt(Sec[33])Shl 16)
             Or(LongInt(Sec[34])Shl 8)Or LongInt(Sec[35]);
   If(BlockSize=0)Or(BlockSize Mod 512<>0)Then Begin Close(F); Exit; End;
   VHDBlockSizeSec:=BlockSize Div 512;
   { Bitmap = block_size/512 bits, rounded up to secteur entier }
   VHDBitmapSecs:=((VHDBlockSizeSec Div 8)+511)Div 512;
   If VHDBitmapSecs<1 Then VHDBitmapSecs:=1;
   VHDBATFileOfs:=BAToff;
   VHDKind:=_VHDDynamic;
   Close(F); Exit;
  End;
 End;
 Close(F);
End;
{$R+}

{ Traduit un LBA virtuel en offset fichier (octets) selon le format.
  Pour un bloc VHD dynamique non alloue : retourne -1 (lecture = zeros). }
Function VHDFileOffset(LBA:LongInt):LongInt;
Var
 F:File;
 BR:Word;
 BlockIdx,OfsInBlock,BATEntry:LongInt;
 GrainNum,GTIdx,GTOff,GTSec,GrainSec:LongInt;
 BATBuf:Array[0..3]of Byte;
Begin
 If(VHDKind=_VHDNone)Or(VHDKind=_VHDFixed)Then Begin
  VHDFileOffset:=LBA*512;
  Exit;
 End;
 VHDFileOffset:=-1;
 If VHDKind=_VMDKSparse Then Begin
  { Lookup 2-niveaux : GrainDir -> GrainTable -> grain
    GrainNum = LBA / GrainSize ; GTIdx = GrainNum / GTEsPerGT
    GTOff = GrainNum mod GTEsPerGT. Toutes les entrees sont en
    sectors LE 32-bit. 0 = non alloue. }
  GrainNum:=LBA Div VHDBlockSizeSec;
  GTIdx:=GrainNum Div VMDKGTEsPerGT;
  GTOff:=GrainNum Mod VMDKGTEsPerGT;
  OfsInBlock:=LBA Mod VHDBlockSizeSec;
  {$I-}Assign(F,FileName);Reset(F,1);{$I+}
  If IOResult<>0 Then Exit;
  { Lire GD[GTIdx] (4 octets LE) }
  {$I-}Seek(F,VHDBATFileOfs+GTIdx*4);{$I+}
  If IOResult<>0 Then Begin Close(F); Exit; End;
  {$I-}BlockRead(F,BATBuf,4,BR);{$I+}
  If(IOResult<>0)Or(BR<>4)Then Begin Close(F); Exit; End;
  GTSec:=LongInt(BATBuf[0])Or(LongInt(BATBuf[1])Shl 8)
        Or(LongInt(BATBuf[2])Shl 16)Or(LongInt(BATBuf[3])Shl 24);
  If GTSec=0 Then Begin Close(F); Exit; End;
  { Lire GT[GTOff] }
  {$I-}Seek(F,GTSec*512+GTOff*4);{$I+}
  If IOResult<>0 Then Begin Close(F); Exit; End;
  {$I-}BlockRead(F,BATBuf,4,BR);{$I+}
  Close(F);
  If(BR<>4)Then Exit;
  GrainSec:=LongInt(BATBuf[0])Or(LongInt(BATBuf[1])Shl 8)
           Or(LongInt(BATBuf[2])Shl 16)Or(LongInt(BATBuf[3])Shl 24);
  If GrainSec=0 Then Exit;
  VHDFileOffset:=GrainSec*512+OfsInBlock*512;
  Exit;
 End;
 { VHD dynamique }
 BlockIdx:=LBA Div VHDBlockSizeSec;
 OfsInBlock:=LBA Mod VHDBlockSizeSec;
 {$I-}Assign(F,FileName);Reset(F,1);{$I+}
 If IOResult<>0 Then Exit;
 {$I-}Seek(F,VHDBATFileOfs+BlockIdx*4);{$I+}
 If IOResult<>0 Then Begin Close(F); Exit; End;
 {$I-}BlockRead(F,BATBuf,4,BR);{$I+}
 Close(F);
 If(BR<>4)Then Exit;
 BATEntry:=(LongInt(BATBuf[0])Shl 24)Or(LongInt(BATBuf[1])Shl 16)
          Or(LongInt(BATBuf[2])Shl 8)Or LongInt(BATBuf[3]);
 If BATEntry=-1 Then Exit;   { bloc non alloue }
 VHDFileOffset:=(BATEntry+VHDBitmapSecs)*512+OfsInBlock*512;
End;

{ Lit un secteur (512 octets) depuis l'image fichier.
  Retourne True si OK. Buf doit contenir au moins 512 octets. }
Function ReadImgSector(LBA:LongInt;Var Buf):Boolean;
Var
 F:File;
 BR:Word;
 FileOfs:LongInt;
Begin
 ReadImgSector:=False;
 If FileName='' Then Exit;
 FileOfs:=VHDFileOffset(LBA);
 If FileOfs=-1 Then Begin
  { VHD dynamique : bloc non alloue, secteur virtuel = zeros }
  FillChar(Buf,512,0);
  ReadImgSector:=True;
  Exit;
 End;
 {$I-}Assign(F,FileName);Reset(F,1);{$I+}
 If IOResult<>0 Then Exit;
 {$I-}Seek(F,FileOfs);{$I+}
 If IOResult<>0 Then Begin Close(F);Exit;End;
 {$I-}BlockRead(F,Buf,512,BR);{$I+}
 Close(F);
 ReadImgSector:=(IOResult=0)And(BR=512);
End;

{ Ecrit un secteur (512 octets) dans l'image fichier.
  Pour VHD dynamique : echoue si le bloc n'est pas alloue (allocation
  non implementee). Retourne True si OK. }
Function WriteImgSector(LBA:LongInt;Var Buf):Boolean;
Var
 F:File;
 BW:Word;
 FileOfs:LongInt;
Begin
 WriteImgSector:=False;
 If FileName='' Then Exit;
 FileOfs:=VHDFileOffset(LBA);
 If FileOfs=-1 Then Exit;  { bloc VHD non alloue : ne pas reecrire }
 {$I-}Assign(F,FileName);Reset(F,1);{$I+}
 If IOResult<>0 Then Exit;
 {$I-}Seek(F,FileOfs);{$I+}
 If IOResult<>0 Then Begin Close(F);Exit;End;
 {$I-}BlockWrite(F,Buf,512,BW);{$I+}
 Close(F);
 WriteImgSector:=(IOResult=0)And(BW=512);
End;

Procedure ReadPartitionRecord;
Var
 Partition:File;
 ByteReaded:Word;
Begin
 If(IsDisk)Then Begin
  ReadTrack($80+CurrentDisk-1,0,0,1,1,Buffer);
 End
  Else
 If FileName<>''Then Begin
  { VHD ou raw : passer par ReadImgSector qui gere la traduction }
  If VHDKind<>_VHDNone Then Begin
   ReadImgSector(0,Buffer);
   Exit;
  End;
  {$I-}Assign(Partition,FileName);
  Reset(Partition,1);{$I+}
  If IOResult=0 Then Begin
   BlockRead(Partition,Buffer,512,ByteReaded);
   Close(Partition);
  End;
 End;
End;

Procedure WritePartitionRecord;
Var
 Partition:File;
 ByteReaded:Word;
Begin
 If(IsDisk)Then Begin
  WriteTrack($80+CurrentDisk-1,0,0,1,1,Buffer);
 End
  Else
 If FileName<>''Then Begin
  { VHD ou raw : passer par WriteImgSector qui gere la traduction }
  If VHDKind<>_VHDNone Then Begin
   If Not WriteImgSector(0,Buffer)Then
    WriteLn('Erreur : ecriture VHD echouee (bloc non alloue ?).');
   Exit;
  End;
  {$I-}Assign(Partition,FileName);
  Reset(Partition,1);{$I+}
  If IOResult=0 Then Begin
   BlockWrite(Partition,Buffer,512,ByteReaded);
   Close(Partition);
  End;
 End;
End;

{ Geometrie du disque physique courant (caches une fois lue). }
Var
 GeoValid:Boolean;
 GeoHeads,GeoSPT:Word;

{$IFNDEF Windows}
Procedure FetchGeometry;
Var Regs:Registers;
Begin
 If GeoValid Then Exit;
 Regs.AH:=$08;
 Regs.DL:=$80+CurrentDisk-1;
 Intr($13,Regs);
 If(Regs.Flags and FCarry)=0 Then Begin
  GeoHeads:=Regs.DH+1;
  GeoSPT:=Regs.CL and $3F;
  If(GeoHeads>0)And(GeoSPT>0)Then GeoValid:=True;
 End;
End;
{$ENDIF}

{ Lit un secteur (512 octets) en LBA depuis le disque physique courant.
  Retourne True si OK. }
Function ReadDiskLBA(LBA:LongInt;Var Buf):Boolean;
{$IFDEF Windows}
 Begin ReadDiskLBA:=False; End;
{$ELSE}
Var
 Cyl,Head,Sect:Word;
 Tmp:LongInt;
 Status:Byte;
Begin
 ReadDiskLBA:=False;
 FetchGeometry;
 If Not GeoValid Then Exit;
 { LBA = ((Cyl*Heads) + Head) * SPT + Sect - 1 }
 Sect:=Word(LBA Mod GeoSPT)+1;
 Tmp:=LBA Div GeoSPT;
 Head:=Word(Tmp Mod GeoHeads);
 Cyl:=Word(Tmp Div GeoHeads);
 If Cyl>1023 Then Exit;  { au-dela de la limite CHS BIOS }
 Status:=ReadTrack($80+CurrentDisk-1,Head,Byte(Cyl),Byte(Sect),1,Buf);
 ReadDiskLBA:=(Status=0);
End;
{$ENDIF}

{ Lit un secteur depuis l'image OU le disque selon le mode courant. }
Function ReadSector(LBA:LongInt;Var Buf):Boolean;
Begin
 If FileName<>'' Then ReadSector:=ReadImgSector(LBA,Buf)
 Else ReadSector:=ReadDiskLBA(LBA,Buf);
End;

{ Ecrit un secteur (512 octets) en LBA sur le disque physique courant. }
Function WriteDiskLBA(LBA:LongInt;Var Buf):Boolean;
{$IFDEF Windows}
 Begin WriteDiskLBA:=False; End;
{$ELSE}
Var
 Cyl,Head,Sect:Word;
 Tmp:LongInt;
 Status:Byte;
Begin
 WriteDiskLBA:=False;
 FetchGeometry;
 If Not GeoValid Then Exit;
 Sect:=Word(LBA Mod GeoSPT)+1;
 Tmp:=LBA Div GeoSPT;
 Head:=Word(Tmp Mod GeoHeads);
 Cyl:=Word(Tmp Div GeoHeads);
 If Cyl>1023 Then Exit;
 Status:=WriteTrack($80+CurrentDisk-1,Head,Byte(Cyl),Byte(Sect),1,Buf);
 WriteDiskLBA:=(Status=0);
End;
{$ENDIF}

{ Ecrit un secteur dans l'image OU sur le disque selon le mode courant. }
Function WriteSector(LBA:LongInt;Var Buf):Boolean;
Begin
 If FileName<>'' Then WriteSector:=WriteImgSector(LBA,Buf)
 Else WriteSector:=WriteDiskLBA(LBA,Buf);
End;

{ Recupere le nom de volume d'une partition FAT12/16/32, HPFS ou NTFS.
  Retourne une chaine vide si introuvable. }
Function GetVolumeLabel(Const PE:PartEntry):String;
Var
 Sec:Array[0..511] of Byte;
 BytesPerSec,RsvdSec,RootEntCnt,SecPerClus:Word;
 SecPerFAT,TotSec:LongInt;
 NumFATs:Byte;
 FATType:Byte;
 DataSec,TotClus,RootStart,RootSecs:LongInt;
 RootClus:LongInt;
 FirstDataSec:LongInt;
 I,J,K,LblOfs:Word;
 Lbl:String;
 Found:Boolean;
 MftLCN,RecSize,MftLBA:LongInt;
 ClPerRec:ShortInt;
 RecSizeSec:LongInt;
 UsaOfs,AttrOfs,ContentOfs,ContentLen:Word;
 AttrLen:Word;
 AttrType:LongInt;
 NonRes,C:Byte;
Begin
 GetVolumeLabel:='';
 If Not ReadSector(PE.SecOfs,Sec) Then Exit;

 { ----- NTFS : signature 'NTFS    ' a l'offset 3 ----- }
 If(Sec[3]=$4E)And(Sec[4]=$54)And(Sec[5]=$46)And(Sec[6]=$53)Then Begin
  BytesPerSec:=Word(Sec[11])Or(Word(Sec[12])Shl 8);
  SecPerClus:=Sec[13];
  If(BytesPerSec=0)Or(SecPerClus=0)Then Exit;
  { MFT LCN @ offset 48 (8 octets, on prend les 32 bits bas) }
  MftLCN:=LongInt(Sec[48])Or(LongInt(Sec[49])Shl 8)
        Or(LongInt(Sec[50])Shl 16)Or(LongInt(Sec[51])Shl 24);
  { Octets/clusters par enregistrement MFT @ offset 64 (octet signe) }
  ClPerRec:=ShortInt(Sec[64]);
  If ClPerRec>=0 Then
   RecSize:=LongInt(ClPerRec)*SecPerClus*BytesPerSec
  Else
   RecSize:=LongInt(1)Shl(-ClPerRec);
  If(RecSize<512)Or(BytesPerSec=0)Then Exit;
  RecSizeSec:=RecSize Div BytesPerSec;
  { Enregistrement MFT n3 = $Volume }
  MftLBA:=PE.SecOfs+MftLCN*SecPerClus+3*RecSizeSec;
  If Not ReadSector(MftLBA,Sec) Then Exit;
  { Magic 'FILE' }
  If(Sec[0]<>$46)Or(Sec[1]<>$49)Or(Sec[2]<>$4C)Or(Sec[3]<>$45)Then Exit;
  { Fixup du 1er secteur : USA @ offset 4 (word) ; remplacer les 2 derniers
    octets du secteur par USA[1] (les 2 octets juste apres le USN). }
  UsaOfs:=Word(Sec[4])Or(Word(Sec[5])Shl 8);
  If UsaOfs+4<=510 Then Begin
   Sec[510]:=Sec[UsaOfs+2];
   Sec[511]:=Sec[UsaOfs+3];
  End;
  { Premier attribut @ offset $14 (word) }
  AttrOfs:=Word(Sec[$14])Or(Word(Sec[$15])Shl 8);
  While AttrOfs+8<512 Do Begin
   AttrType:=LongInt(Sec[AttrOfs])Or(LongInt(Sec[AttrOfs+1])Shl 8)
           Or(LongInt(Sec[AttrOfs+2])Shl 16)Or(LongInt(Sec[AttrOfs+3])Shl 24);
   If AttrType=-1 Then Exit;  { fin de la liste d'attributs }
   AttrLen:=Word(Sec[AttrOfs+4])Or(Word(Sec[AttrOfs+5])Shl 8);
   If AttrLen=0 Then Exit;
   If AttrType=$60 Then Begin
    { $VOLUME_NAME : resident attendu }
    NonRes:=Sec[AttrOfs+8];
    If NonRes=0 Then Begin
     ContentLen:=Word(Sec[AttrOfs+16])Or(Word(Sec[AttrOfs+17])Shl 8);
     ContentOfs:=Word(Sec[AttrOfs+20])Or(Word(Sec[AttrOfs+21])Shl 8);
     { Contenu = UTF-16LE, on prend seulement le byte bas (ASCII) }
     Lbl:='';
     I:=0;
     While(I<ContentLen)And(AttrOfs+ContentOfs+I+1<512)Do Begin
      C:=Sec[AttrOfs+ContentOfs+I];
      If C>=32 Then Lbl:=Lbl+Chr(C);
      Inc(I,2);
     End;
     GetVolumeLabel:=Lbl;
    End;
    Exit;
   End;
   Inc(AttrOfs,AttrLen);
  End;
  Exit;
 End;

 { ----- HPFS : signature au superbloc, LBA partition + 16 ----- }
 If ReadSector(PE.SecOfs+16,Sec) Then Begin
  If(Sec[0]=$49)And(Sec[1]=$E8)And(Sec[2]=$95)And(Sec[3]=$F9)Then Begin
   { SuperBlock HPFS, volume name @ offset $0C, 32 octets max, null-term }
   Lbl:='';
   For I:=$0C To $0C+31 Do Begin
    If Sec[I]=0 Then Break;
    Lbl:=Lbl+Chr(Sec[I]);
   End;
   While(Length(Lbl)>0)And(Lbl[Length(Lbl)]=' ')Do
    Lbl:=Copy(Lbl,1,Length(Lbl)-1);
   GetVolumeLabel:=Lbl;
   Exit;
  End;
 End;

 { Relire le boot sector FAT }
 If Not ReadSector(PE.SecOfs,Sec) Then Exit;
 If(Sec[510]<>$55)Or(Sec[511]<>$AA)Then Exit;
 BytesPerSec:=Word(Sec[11])Or(Word(Sec[12])Shl 8);
 SecPerClus:=Sec[13];
 RsvdSec:=Word(Sec[14])Or(Word(Sec[15])Shl 8);
 NumFATs:=Sec[16];
 RootEntCnt:=Word(Sec[17])Or(Word(Sec[18])Shl 8);
 TotSec:=Word(Sec[19])Or(Word(Sec[20])Shl 8);
 If TotSec=0 Then
  TotSec:=LongInt(Sec[32])Or(LongInt(Sec[33])Shl 8)
        Or(LongInt(Sec[34])Shl 16)Or(LongInt(Sec[35])Shl 24);
 SecPerFAT:=Word(Sec[22])Or(Word(Sec[23])Shl 8);
 If SecPerFAT=0 Then
  SecPerFAT:=LongInt(Sec[36])Or(LongInt(Sec[37])Shl 8)
           Or(LongInt(Sec[38])Shl 16)Or(LongInt(Sec[39])Shl 24);
 If(BytesPerSec<>512)Or(SecPerClus=0)Or(NumFATs=0)Or(SecPerFAT=0)Then Exit;
 DataSec:=TotSec-(RsvdSec+LongInt(NumFATs)*SecPerFAT
                  +((LongInt(RootEntCnt)*32+BytesPerSec-1)Div BytesPerSec));
 If DataSec<=0 Then Exit;
 TotClus:=DataSec Div SecPerClus;
 If TotClus<4085 Then FATType:=12
 Else If TotClus<65525 Then FATType:=16
 Else FATType:=32;

 { 1) Essayer le label de l'extended BPB }
 If FATType=32 Then LblOfs:=71 Else LblOfs:=43;
 { Verifier la signature etendue BS_BootSig=$29 }
 If((FATType=32)And(Sec[66]=$29))Or
   ((FATType<>32)And(Sec[38]=$29))Then Begin
  Lbl:='';
  For I:=LblOfs To LblOfs+10 Do Lbl:=Lbl+Chr(Sec[I]);
  While(Length(Lbl)>0)And(Lbl[Length(Lbl)]=' ')Do
   Lbl:=Copy(Lbl,1,Length(Lbl)-1);
  If(Lbl<>'')And(Lbl<>'NO NAME')Then Begin
   GetVolumeLabel:=Lbl;
   Exit;
  End;
 End;

 { 2) Scanner le repertoire racine pour une entree avec attr=$08 }
 If FATType=32 Then Begin
  RootClus:=LongInt(Sec[44])Or(LongInt(Sec[45])Shl 8)
          Or(LongInt(Sec[46])Shl 16)Or(LongInt(Sec[47])Shl 24);
  FirstDataSec:=RsvdSec+LongInt(NumFATs)*SecPerFAT;
  RootStart:=PE.SecOfs+FirstDataSec+(RootClus-2)*SecPerClus;
  RootSecs:=SecPerClus;  { un seul cluster suffit pour l'entree volume }
 End Else Begin
  RootStart:=PE.SecOfs+RsvdSec+LongInt(NumFATs)*SecPerFAT;
  RootSecs:=(LongInt(RootEntCnt)*32+BytesPerSec-1)Div BytesPerSec;
 End;
 Found:=False;
 J:=0;
 While(J<RootSecs)And Not Found Do Begin
  If Not ReadSector(RootStart+J,Sec) Then Exit;
  K:=0;
  While(K<512)And Not Found Do Begin
   If Sec[K]=0 Then Exit;   { fin du repertoire }
   { attr=$08 (volume), pas $0F (LFN), pas supprime ($E5) }
   If(Sec[K+11]=$08)And(Sec[K]<>$E5)Then Begin
    Lbl:='';
    For I:=0 To 10 Do Lbl:=Lbl+Chr(Sec[K+I]);
    While(Length(Lbl)>0)And(Lbl[Length(Lbl)]=' ')Do
     Lbl:=Copy(Lbl,1,Length(Lbl)-1);
    If Lbl<>'' Then Begin
     GetVolumeLabel:=Lbl;
     Found:=True;
    End;
   End;
   Inc(K,32);
  End;
  Inc(J);
 End;
End;

{ Calcule le % UTILISE d'une partition FAT en parcourant sa FAT.
  Renvoie -1 si impossible (type non supporte, lecture echouee, etc.). }
Function PartUsagePct(Const PE:PartEntry):Integer;
Var
 Sec:Array[0..511] of Byte;
 BytesPerSec,RsvdSec,RootEntCnt,SecPerClus:Word;
 SecPerFAT,TotSec:LongInt;
 NumFATs:Byte;
 FATType:Byte;       { 12, 16 ou 32 }
 DataSec,TotClus:LongInt;
 FATStart:LongInt;
 BytesInFAT:LongInt;
 FATBuf:Array[0..511] of Byte;
 CurFATSec:LongInt;
 LastFATSec:LongInt;
 ClusIdx:LongInt;
 Ofs:LongInt;
 V12:Word;
 V16:Word;
 V32:LongInt;
 Free:LongInt;
 Used:LongInt;
Begin
 PartUsagePct:=-1;
 If Not ReadSector(PE.SecOfs,Sec) Then Exit;
 { Verifier signature de boot sector }
 If(Sec[510]<>$55)Or(Sec[511]<>$AA)Then Exit;
 BytesPerSec:=Word(Sec[11])Or(Word(Sec[12])Shl 8);
 SecPerClus:=Sec[13];
 RsvdSec:=Word(Sec[14])Or(Word(Sec[15])Shl 8);
 NumFATs:=Sec[16];
 RootEntCnt:=Word(Sec[17])Or(Word(Sec[18])Shl 8);
 TotSec:=Word(Sec[19])Or(Word(Sec[20])Shl 8);
 If TotSec=0 Then
  TotSec:=LongInt(Sec[32])Or(LongInt(Sec[33])Shl 8)
        Or(LongInt(Sec[34])Shl 16)Or(LongInt(Sec[35])Shl 24);
 SecPerFAT:=Word(Sec[22])Or(Word(Sec[23])Shl 8);
 If SecPerFAT=0 Then
  SecPerFAT:=LongInt(Sec[36])Or(LongInt(Sec[37])Shl 8)
           Or(LongInt(Sec[38])Shl 16)Or(LongInt(Sec[39])Shl 24);
 If(BytesPerSec<>512)Or(SecPerClus=0)Or(NumFATs=0)Or(SecPerFAT=0)Then Exit;
 { Calcul du nombre de clusters de donnees }
 DataSec:=TotSec-(RsvdSec+LongInt(NumFATs)*SecPerFAT
                  +((LongInt(RootEntCnt)*32+BytesPerSec-1)Div BytesPerSec));
 If DataSec<=0 Then Exit;
 TotClus:=DataSec Div SecPerClus;
 If TotClus<4085 Then FATType:=12
 Else If TotClus<65525 Then FATType:=16
 Else FATType:=32;
 FATStart:=PE.SecOfs+RsvdSec;
 BytesInFAT:=LongInt(SecPerFAT)*BytesPerSec;
 { Scanner FAT, compter clusters libres (entree=0) }
 CurFATSec:=-1;
 LastFATSec:=-1;
 Free:=0;
 { Clusters valides : 2..TotClus+1 }
 For ClusIdx:=2 To TotClus+1 Do Begin
  Case FATType Of
   12:Ofs:=ClusIdx+(ClusIdx Shr 1);
   16:Ofs:=ClusIdx Shl 1;
   Else Ofs:=ClusIdx Shl 2;
  End;
  If Ofs>=BytesInFAT Then Break;
  CurFATSec:=FATStart+(Ofs Div BytesPerSec);
  If CurFATSec<>LastFATSec Then Begin
   If Not ReadSector(CurFATSec,FATBuf) Then Exit;
   LastFATSec:=CurFATSec;
  End;
  Ofs:=Ofs Mod BytesPerSec;
  Case FATType Of
   12:Begin
    { Cas frontiere : entree de 12 bits a cheval sur deux secteurs }
    If Ofs=BytesPerSec-1 Then Begin
     V12:=FATBuf[Ofs];
     If Not ReadSector(CurFATSec+1,FATBuf) Then Exit;
     LastFATSec:=CurFATSec+1;
     V12:=V12 Or(Word(FATBuf[0])Shl 8);
    End Else
     V12:=Word(FATBuf[Ofs])Or(Word(FATBuf[Ofs+1])Shl 8);
    If(ClusIdx And 1)=0 Then V12:=V12 And $0FFF
                        Else V12:=V12 Shr 4;
    If V12=0 Then Inc(Free);
   End;
   16:Begin
    V16:=Word(FATBuf[Ofs])Or(Word(FATBuf[Ofs+1])Shl 8);
    If V16=0 Then Inc(Free);
   End;
   Else Begin
    V32:=LongInt(FATBuf[Ofs])Or(LongInt(FATBuf[Ofs+1])Shl 8)
        Or(LongInt(FATBuf[Ofs+2])Shl 16)Or(LongInt(FATBuf[Ofs+3])Shl 24);
    V32:=V32 And $0FFFFFFF;
    If V32=0 Then Inc(Free);
   End;
  End;
 End;
 Used:=TotClus-Free;
 If Used<0 Then Used:=0;
 If TotClus>0 Then
  PartUsagePct:=Integer((Used*100+TotClus Div 2)Div TotClus)
 Else
  PartUsagePct:=0;
End;

Procedure WriteListPartition;
Var
 Partition:PartSec Absolute Buffer;
 I:Byte;
 Letter:Char;
 TypeName:String;
 TotSec:LongInt;
 Pct:Integer;
 Buffer2:Array[0..511]of Byte;
Begin
 Write(' ':2,'Lecteur de disque dur en cours : ');
 HighVideo;
 If FileName<>''Then WriteLn(FileName)
                Else WriteLn(CurrentDisk);
 LowVideo;
 WriteLn;
 WriteLn(' ':2,'Partition    Etat   Type   Nom du volume    Mo  SystŠme    Utilis‚');
 ReadPartitionRecord;
 { Verifie la signature MBR $55AA. Sinon, image disquette ou secteur non
   partitionne : ne rien afficher pour eviter erreurs d'overflow. }
 If(Buffer[510]<>$55)Or(Buffer[511]<>$AA)Then Begin
  WriteLn;
  WriteLn(' ':2,'Aucune table de partition (image disquette ou secteur vide ?).');
  Exit;
 End;
 { Detection d'un secteur de boot FAT (commence par JMP EB/E9) : ce n'est
   pas un MBR meme si la signature $55AA est presente. }
 If(Buffer[0]=$EB)Or(Buffer[0]=$E9)Then Begin
  WriteLn;
  WriteLn(' ':2,'Aucune table de partition (secteur de boot FAT detecte).');
  Exit;
 End;
 { Total des secteurs occupes par toutes les partitions = taille du disque.
   Filtre les entrees aberrantes (PartType inconnu et NumSec absurde). }
 TotSec:=0;
 For I:=0 to 3 do
  If Partition.PartTable[I].PartType<>0Then
   Inc(TotSec,Partition.PartTable[I].NumSec);
 Letter:='C';
 For I:=0 to 3 do If Partition.PartTable[I].PartType<>0Then Begin
  Write(' ':3);
  If Partition.PartTable[I].PartType in[$04,$05,$06,$07,$0B,$0C]Then Begin
   Write(Letter,': ');
   Letter:=Succ(Letter);
  End
   Else
  Write(' ':3);
  HighVideo;
  Write(I+1,' ':9);
  LowVideo;
  If Partition.PartTable[I].Status=$80 Then Write('A')
                                       Else Write(' ');
  Write(' ':4);
  { Colonne Type : PRI/EXT + nature du systeme (DOS, non-DOS ou autre) }
  Case Partition.PartTable[I].PartType Of
   $05,$0F:Write('EXT     ');     { Partition etendue }
   $01,$04,$06,$0B,$0C,
   $0E,$11,$12,$14,$16,
   $1B,$1C,$1E,$24:Write('PRI DOS ');   { DOS/FAT }
   Else Write('PRI     ');                 { Autre OS / non-DOS }
  End;
  { Nom de volume : lu via FAT BPB/racine ou HPFS }
  TypeName:=GetVolumeLabel(Partition.PartTable[I]);
  If TypeName='' Then TypeName:='NOLABEL';
  Write(PadRight(TypeName,14));
  { Taille en Mo = NumSec * 512 / (1024*1024) = NumSec / 2048 }
  Write((Partition.PartTable[I].NumSec + 1024) Div 2048:6,' ':3);
  Case Partition.PartTable[I].PartType of
   $00:TypeName:='Entrï¿½e vide';
   $01:TypeName:='FAT12';
   $02:TypeName:='XENIX root';
   $03:TypeName:='XENIX /usr';
   $04,$05,$06:TypeName:='FAT16';
   $07:Begin
    { Type $07 : NTFS, HPFS, exFAT ou IFS. Distinguer via le boot sector
      de la partition (offset +3 : OEM name pour NTFS/exFAT,
      ou offset +54 : FileSystemType pour HPFS FAT-like BPB). }
    TypeName:='IFS';
    If ReadSector(Partition.PartTable[I].SecOfs,Buffer2) Then Begin
     { 'NTFS    ' a offset 3 ? }
     If(Buffer2[3]=$4E)And(Buffer2[4]=$54)And(Buffer2[5]=$46)And
       (Buffer2[6]=$53)Then TypeName:='NTFS' Else
     { 'EXFAT   ' a offset 3 ? }
     If(Buffer2[3]=$45)And(Buffer2[4]=$58)And(Buffer2[5]=$46)And
       (Buffer2[6]=$41)And(Buffer2[7]=$54)Then TypeName:='exFAT' Else
     { 'HPFS    ' a offset 54 (BPB FAT-like) ? }
     If(Buffer2[54]=$48)And(Buffer2[55]=$50)And(Buffer2[56]=$46)And
       (Buffer2[57]=$53)Then TypeName:='HPFS';
    End;
   End;
   $08:TypeName:='D‚marrage AIX';
   $09:TypeName:='Donn‚es AIX';
   $0A:TypeName:='OS/2 Boot Manager';
   $0B,$0C:TypeName:='FAT32';
   $0D:TypeName:='SILICON SAFE';
   $0E,$0F:TypeName:='FAT16/WIN95';
   $11,$14,$16:TypeName:='FAT12 cach‚';
   $12:TypeName:='Partition de configuration';
   $17:TypeName:='IFS cach‚';
   $18:TypeName:='AST SmartSleep';
   $1B:TypeName:='FAT32 cach‚';
   $1C:TypeName:='FAT32';
   $1E:TypeName:='FAT16/WIN95';
   $24:TypeName:='NEC DOS';
   $27:TypeName:='MirOS';
   $2A:TypeName:='AtheOS';
   $2B:TypeName:='SylStor';
   $32:TypeName:='NOS';
   $35:TypeName:='JFS';
   Else TypeName:='Inconnu';
  End;
  Write(PadRight(TypeName,11));
  { % d'occupation reel via scan FAT (image fichier ou disque physique) }
  Pct:=PartUsagePct(Partition.PartTable[I]);
  If Pct<0 Then
   { Fallback : % du disque physique occupe par cette partition.
     NumSec peut etre > 21M (>=10 Go), donc NumSec*100 deborde LongInt.
     On divise d'abord par 1024 pour rester dans la plage. }
   If TotSec>0 Then
    Write(Integer((LongInt(Partition.PartTable[I].NumSec Shr 10)*100
                  +(TotSec Shr 10)Div 2)
                  Div(TotSec Shr 10)),'%')
   Else
    Write('  ? ')
  Else
   Write(Pct,'%');
  WriteLn;
 End;
End;

{ ===== Creation de partition ============================================ }

Function HexByteStr(B:Byte):String;
Const HC:Array[0..15]of Char='0123456789ABCDEF';
Begin
 HexByteStr:=HC[B Shr 4]+HC[B And $0F];
End;

{ Taille totale (en secteurs) du support : fichier image ou disque physique. }
Function TotalSectors:LongInt;
Var
 F:File;
 Sz:LongInt;
Begin
 TotalSectors:=0;
 If FileName<>'' Then Begin
  { VHD : utiliser la taille virtuelle, pas la taille du fichier hote }
  If VHDDiskSec>0 Then Begin
   TotalSectors:=VHDDiskSec;
   Exit;
  End;
  {$I-}Assign(F,FileName);Reset(F,1);{$I+}
  If IOResult=0 Then Begin
   Sz:=FileSize(F);
   Close(F);
   TotalSectors:=Sz Div 512;
  End;
 End Else Begin
{$IFNDEF Windows}
  FetchGeometry;
  If GeoValid Then
   { On suppose 1024 cylindres (limite CHS classique). Approximation. }
   TotalSectors:=LongInt(1024)*GeoHeads*GeoSPT;
{$ENDIF}
 End;
End;

{ Convertit un LBA en CHS pour stockage dans la table de partition.
  Si le LBA depasse la limite CHS (cyl>1023), stocke (1023,254,63). }
Procedure LBAtoCHS(LBA:LongInt;Var SP:SecPosType);
Var
 Cyl,Head,Sect:Word;
 Tmp:LongInt;
 H,S:Word;
Begin
 H:=255; S:=63;   { defauts si geometrie inconnue }
{$IFNDEF Windows}
 If(FileName='')Then Begin
  FetchGeometry;
  If GeoValid Then Begin H:=GeoHeads; S:=GeoSPT; End;
 End;
{$ENDIF}
 Sect:=Word(LBA Mod S)+1;
 Tmp:=LBA Div S;
 If(Tmp Div H)>1023 Then Begin
  Cyl:=1023; Head:=H-1; Sect:=S;
 End Else Begin
  Head:=Word(Tmp Mod H);
  Cyl:=Word(Tmp Div H);
 End;
 SP.Head:=Byte(Head);
 SP.SectTrack:=(Sect And $3F)Or((Cyl And $300)Shr 2)Or((Cyl And $FF)Shl 8);
End;

Function ReadIntLine(Default:LongInt):LongInt;
Var
 S:String;
 V,Code:Integer;
 L:LongInt;
Begin
 ReadLn(S);
 If S='' Then Begin ReadIntLine:=Default; Exit; End;
 Val(S,L,Code);
 If Code<>0 Then Begin
  Val(S,V,Code);
  If Code=0 Then L:=V Else L:=Default;
 End;
 ReadIntLine:=L;
End;

{ ----- Operations non-interactives (utilisables en CLI) ----------------- }

{ Cree une partition primaire dans le premier slot libre.
  SizeMB = taille demandee, ou 0/-1 = utiliser tout l'espace libre.
  PType  = type de partition ($01,$04,$06,$0B,$0C, etc.).
  Retourne True si la partition a ete creee et ecrite sur disque/image. }
Function DoCreatePartition(SizeMB:LongInt;PType:Byte;Verbose:Boolean):Boolean;
Var
 Partition:PartSec Absolute Buffer;
 I,Slot:Byte;
 FreeStart,UsedEnd,Tot,MaxMB,NumSec,SecOfs:LongInt;
 PE:PartEntry;
 BootSec:Array[0..511]of Byte;
 LocalHint:Byte;
Begin
 DoCreatePartition:=False;
 LocalHint:=FsHint;   { FsHint peut etre ecrase par d'autres appels }
 ReadPartitionRecord;
 Slot:=255;
 For I:=0 To 3 Do
  If(Partition.PartTable[I].PartType=0)And(Slot=255)Then Slot:=I;
 If Slot=255 Then Begin
  If Verbose Then WriteLn('Erreur : aucun emplacement libre.');
  Exit;
 End;
 UsedEnd:=0;
 For I:=0 To 3 Do
  If Partition.PartTable[I].PartType<>0 Then Begin
   FreeStart:=Partition.PartTable[I].SecOfs+Partition.PartTable[I].NumSec;
   If FreeStart>UsedEnd Then UsedEnd:=FreeStart;
  End;
 If UsedEnd=0 Then UsedEnd:=63;
 SecOfs:=UsedEnd;
 Tot:=TotalSectors;
 If Tot<=SecOfs Then Begin
  If Verbose Then WriteLn('Erreur : espace insuffisant (total=',Tot,').');
  Exit;
 End;
 MaxMB:=(Tot-SecOfs) Div 2048;
 If MaxMB<1 Then MaxMB:=1;
 If SizeMB<=0 Then SizeMB:=MaxMB;
 If SizeMB>MaxMB Then SizeMB:=MaxMB;
 NumSec:=SizeMB*2048;
 If SecOfs+NumSec>Tot Then NumSec:=Tot-SecOfs;
 If PType=0 Then PType:=$0B;
 FillChar(PE,SizeOf(PE),0);
 PE.Status:=$00;
 PE.PartType:=PType;
 PE.SecOfs:=SecOfs;
 PE.NumSec:=NumSec;
 LBAtoCHS(SecOfs,PE.StartSec);
 LBAtoCHS(SecOfs+NumSec-1,PE.EndSec);
 Partition.PartTable[Slot]:=PE;
 Partition.IdCode:=$AA55;
 WritePartitionRecord;
 { Si l'utilisateur a demande NTFS ou HPFS, ecrire un boot sector minimal
   contenant la signature systeme pour que la detection fonctionne. }
 If(PType=$07)And(LocalHint in[1,2])Then Begin
  FillChar(BootSec,SizeOf(BootSec),0);
  { BPB minimal commun }
  BootSec[0]:=$EB; BootSec[1]:=$52; BootSec[2]:=$90;   { JMP court }
  BootSec[11]:=$00; BootSec[12]:=$02;                  { BytesPerSec=512 }
  BootSec[13]:=8;                                      { SecPerClus=8 }
  BootSec[510]:=$55; BootSec[511]:=$AA;
  If LocalHint=1 Then Begin
   { NTFS : 'NTFS    ' a offset 3 }
   BootSec[3]:=$4E; BootSec[4]:=$54; BootSec[5]:=$46; BootSec[6]:=$53;
   BootSec[7]:=$20; BootSec[8]:=$20; BootSec[9]:=$20; BootSec[10]:=$20;
  End Else Begin
   { HPFS : 'HPFS    ' a offset 54 (FileSystemType FAT-like BPB) }
   BootSec[54]:=$48; BootSec[55]:=$50; BootSec[56]:=$46; BootSec[57]:=$53;
   BootSec[58]:=$20; BootSec[59]:=$20; BootSec[60]:=$20; BootSec[61]:=$20;
  End;
  If Not WriteSector(SecOfs,BootSec)And Verbose Then
   WriteLn('Avertissement : ecriture du marqueur de systeme echouee.');
 End;
 If Verbose Then
  WriteLn('Partition ',Slot+1,' creee : LBA ',SecOfs,'..',SecOfs+NumSec-1,
          ' (',SizeMB,' Mo, type $',HexByteStr(PType),')');
 DoCreatePartition:=True;
End;

{ Supprime la partition du slot indique (1..4). }
Function DoDeletePartition(Slot:Byte;Verbose:Boolean):Boolean;
Var
 Partition:PartSec Absolute Buffer;
Begin
 DoDeletePartition:=False;
 If(Slot<1)Or(Slot>4)Then Begin
  If Verbose Then WriteLn('Erreur : numero de partition invalide (1..4).');
  Exit;
 End;
 ReadPartitionRecord;
 If Partition.PartTable[Slot-1].PartType=0 Then Begin
  If Verbose Then WriteLn('Erreur : partition ',Slot,' vide.');
  Exit;
 End;
 FillChar(Partition.PartTable[Slot-1],SizeOf(PartEntry),0);
 Partition.IdCode:=$AA55;
 WritePartitionRecord;
 If Verbose Then WriteLn('Partition ',Slot,' supprimee.');
 DoDeletePartition:=True;
End;

{ Marque la partition Slot (1..4) comme active (bootable). }
Function DoActivatePartition(Slot:Byte;Verbose:Boolean):Boolean;
Var
 Partition:PartSec Absolute Buffer;
 I:Byte;
Begin
 DoActivatePartition:=False;
 If(Slot<1)Or(Slot>4)Then Begin
  If Verbose Then WriteLn('Erreur : numero de partition invalide (1..4).');
  Exit;
 End;
 ReadPartitionRecord;
 If Partition.PartTable[Slot-1].PartType=0 Then Begin
  If Verbose Then WriteLn('Erreur : partition ',Slot,' vide.');
  Exit;
 End;
 For I:=0 To 3 Do Partition.PartTable[I].Status:=$00;
 Partition.PartTable[Slot-1].Status:=$80;
 Partition.IdCode:=$AA55;
 WritePartitionRecord;
 If Verbose Then WriteLn('Partition ',Slot,' marquee active.');
 DoActivatePartition:=True;
End;

{ Efface la table de partitions (4 entrees a zero) et ecrit la signature. }
Function DoInitMBR(Verbose:Boolean):Boolean;
Var
 Partition:PartSec Absolute Buffer;
 I:Byte;
Begin
 ReadPartitionRecord;
 For I:=0 To 3 Do FillChar(Partition.PartTable[I],SizeOf(PartEntry),0);
 Partition.IdCode:=$AA55;
 WritePartitionRecord;
 If Verbose Then WriteLn('Table de partitions reinitialisee.');
 DoInitMBR:=True;
End;

{ Cree un fichier d'image disque de SizeMB Mo, rempli de zeros, avec un MBR
  vide (table de partitions a zero + signature $AA55). FName est le nom du
  fichier a creer. Si Overwrite=False et le fichier existe deja, echoue.
  Retourne True si OK. }
Function DoCreateImage(FName:String;SizeMB:LongInt;
                       Overwrite,Verbose:Boolean):Boolean;
Var
 F:File;
 Sec:Array[0..511]of Byte;
 TotalSec,I:LongInt;
 HasExt:Boolean;
 K:Byte;
Begin
 DoCreateImage:=False;
 If FName='' Then Begin
  If Verbose Then WriteLn('Erreur : nom de fichier vide.');
  Exit;
 End;
 { Ajouter l'extension .IMG si aucune extension n'est presente.
   On cherche un point apres le dernier separateur de chemin. }
 HasExt:=False;
 For K:=Length(FName) DownTo 1 Do Begin
  If(FName[K]='\')Or(FName[K]='/')Or(FName[K]=':')Then Break;
  If FName[K]='.' Then Begin HasExt:=True; Break; End;
 End;
 If Not HasExt Then FName:=FName+'.IMG';
 If SizeMB<1 Then Begin
  If Verbose Then WriteLn('Erreur : taille invalide (Mo>=1 requis).');
  Exit;
 End;
 If Not Overwrite Then Begin
  {$I-}Assign(F,FName);Reset(F,1);{$I+}
  If IOResult=0 Then Begin
   Close(F);
   If Verbose Then WriteLn('Erreur : le fichier "',FName,'" existe deja.');
   Exit;
  End;
 End;
 {$I-}Assign(F,FName);Rewrite(F,512);{$I+}
 If IOResult<>0 Then Begin
  If Verbose Then WriteLn('Erreur : impossible de creer "',FName,'".');
  Exit;
 End;
 FillChar(Sec,SizeOf(Sec),0);
 TotalSec:=SizeMB*2048;  { 1 Mo = 2048 secteurs de 512 octets }
 { Premier secteur : MBR vide avec signature $AA55 }
 Sec[510]:=$55;
 Sec[511]:=$AA;
 {$I-}BlockWrite(F,Sec,1);{$I+}
 If IOResult<>0 Then Begin Close(F);Exit;End;
 FillChar(Sec,SizeOf(Sec),0);
 For I:=2 To TotalSec Do Begin
  {$I-}BlockWrite(F,Sec,1);{$I+}
  If IOResult<>0 Then Begin Close(F);Exit;End;
 End;
 Close(F);
 If Verbose Then
  WriteLn('Image "',FName,'" creee : ',SizeMB,' Mo (',TotalSec,' secteurs).');
 { Bascule sur la nouvelle image }
 FileName:=FName;
 IsDisk:=False;
 DetectImageFormat;
 DoCreateImage:=True;
End;

{ Convertit une chaine en type de partition (1..5 ou $XX hexa ou XX decimal). }
Function ParsePartType(S:String;Default:Byte):Byte;
Var
 V,Code:Integer;
 L:LongInt;
 U:String;
Begin
 ParsePartType:=Default;
 FsHint:=0;
 If S='' Then Exit;
 If(S[1]='$')Or(S[1]='x')Or(S[1]='X')Then S[1]:=' ';
 If(Length(S)>=2)And(S[1]='0')And((S[2]='x')Or(S[2]='X'))Then Begin
  S[1]:=' '; S[2]:=' ';
 End;
 While(Length(S)>0)And(S[1]=' ')Do Delete(S,1,1);
 If S='1' Then Begin ParsePartType:=$01; Exit; End;
 If S='2' Then Begin ParsePartType:=$04; Exit; End;
 If S='3' Then Begin ParsePartType:=$06; Exit; End;
 If S='4' Then Begin ParsePartType:=$0B; Exit; End;
 If S='5' Then Begin ParsePartType:=$0C; Exit; End;
 If S='6' Then Begin ParsePartType:=$07; FsHint:=1; Exit; End;  { NTFS }
 If S='7' Then Begin ParsePartType:=$07; FsHint:=2; Exit; End;  { HPFS }
 If S='8' Then Begin ParsePartType:=$0A; Exit; End;  { OS/2 Boot Manager }
 If S='9' Then Begin ParsePartType:=$02; Exit; End;  { XENIX root }
 If S='10'Then Begin ParsePartType:=$03; Exit; End;  { XENIX /usr }
 If S='11'Then Begin ParsePartType:=$08; Exit; End;  { AIX boot }
 If S='12'Then Begin ParsePartType:=$09; Exit; End;  { AIX data }
 If S='13'Then Begin ParsePartType:=$24; Exit; End;  { NEC DOS }
 If S='14'Then Begin ParsePartType:=$35; Exit; End;  { JFS }
 U:=StrToUpper(S);
 If U='NTFS'     Then Begin ParsePartType:=$07; FsHint:=1; Exit; End;
 If U='HPFS'     Then Begin ParsePartType:=$07; FsHint:=2; Exit; End;
 If U='OS2BM'    Then Begin ParsePartType:=$0A; Exit; End;
 If U='OS/2BM'   Then Begin ParsePartType:=$0A; Exit; End;
 If U='XENIX'    Then Begin ParsePartType:=$02; Exit; End;
 If U='XENIXUSR' Then Begin ParsePartType:=$03; Exit; End;
 If U='AIX'      Then Begin ParsePartType:=$08; Exit; End;
 If U='AIXDATA'  Then Begin ParsePartType:=$09; Exit; End;
 If U='NECDOS'   Then Begin ParsePartType:=$24; Exit; End;
 If U='JFS'      Then Begin ParsePartType:=$35; Exit; End;
 Val('$'+S,L,Code);
 If Code=0 Then Begin
  If(L>=1)And(L<=255)Then ParsePartType:=Byte(L);
  Exit;
 End;
 Val(S,V,Code);
 If(Code=0)And(V>=1)And(V<=255)Then ParsePartType:=Byte(V);
End;

{ Convertit une chaine taille (Mo ou 'MAX'/'ALL') en Mo. 0 = MAX. }
Function ParseSizeMB(S:String):LongInt;
Var
 V,Code:Integer;
 L:LongInt;
 U:String;
Begin
 U:=StrToUpper(S);
 If(U='MAX')Or(U='ALL')Or(U='*')Or(U='')Then Begin ParseSizeMB:=0; Exit; End;
 Val(S,L,Code);
 If Code=0 Then Begin ParseSizeMB:=L; Exit; End;
 Val(S,V,Code);
 If Code=0 Then ParseSizeMB:=V Else ParseSizeMB:=-1;
End;

Procedure CreatePartition;
Var
 Partition:PartSec Absolute Buffer;
 I,Slot:Byte;
 FreeStart,UsedEnd:LongInt;
 Tot,MaxMB,SizeMB,NumSec,SecOfs:LongInt;
 PType:Byte;
 PE:PartEntry;
 TypeS:String;
 BootSec:Array[0..511]of Byte;
 LocalHint:Byte;
Begin
 ClrScr;
 WriteLn;
 WriteLnCenter('Creation d''une partition primaire DOS');
 WriteLn;
 ReadPartitionRecord;
 WriteListPartition;
 WriteLn;

 { Trouver le premier slot libre }
 Slot:=255;
 For I:=0 To 3 Do
  If(Partition.PartTable[I].PartType=0)And(Slot=255)Then Slot:=I;
 If Slot=255 Then Begin
  WriteLn('Aucun emplacement libre. Appuyez sur une touche.');
  ReadKey;
  Exit;
 End;

 { Calculer le debut de l'espace libre = max(EndLBA des partitions existantes)+1 }
 UsedEnd:=0;
 For I:=0 To 3 Do
  If Partition.PartTable[I].PartType<>0 Then Begin
   FreeStart:=Partition.PartTable[I].SecOfs+Partition.PartTable[I].NumSec;
   If FreeStart>UsedEnd Then UsedEnd:=FreeStart;
  End;
 If UsedEnd=0 Then UsedEnd:=63;  { laisser la 1re piste pour MBR }
 SecOfs:=UsedEnd;

 Tot:=TotalSectors;
 If Tot<=SecOfs Then Begin
  WriteLn('Espace insuffisant. Appuyez sur une touche.');
  ReadKey;
  Exit;
 End;
 MaxMB:=(Tot-SecOfs) Div 2048;
 If MaxMB<1 Then MaxMB:=1;

 WriteLn('Emplacement libre : ',Slot+1);
 WriteLn('Debut LBA         : ',SecOfs);
 WriteLn('Taille maximale   : ',MaxMB,' Mo');
 WriteLn;
 Write('Taille de la partition en Mo [',MaxMB,'] : ');
 SizeMB:=ReadIntLine(MaxMB);
 If SizeMB<1 Then SizeMB:=1;
 If SizeMB>MaxMB Then SizeMB:=MaxMB;
 NumSec:=SizeMB*2048;
 If SecOfs+NumSec>Tot Then NumSec:=Tot-SecOfs;

 WriteLn;
 WriteLn('Type de partition :');
 WriteLn('   1. FAT12               8. OS/2 Boot Manager');
 WriteLn('   2. FAT16 (<32 Mo)      9. XENIX root');
 WriteLn('   3. FAT16 (BIGDOS)     10. XENIX /usr');
 WriteLn('   4. FAT32              11. AIX boot');
 WriteLn('   5. FAT32 LBA          12. AIX data');
 WriteLn('   6. NTFS               13. NEC DOS');
 WriteLn('   7. HPFS               14. JFS');
 Write('Choix [4], Q/X/E pour annuler : ');
 ReadLn(TypeS);
 { Annulation : touches Q, X, E (quit/exit) }
 If(TypeS<>'')Then Begin
  TypeS:=StrToUpper(TypeS);
  If(TypeS='Q')Or(TypeS='X')Or(TypeS='E')Or
    (TypeS='QUIT')Or(TypeS='EXIT')Or(TypeS='ANNULER')Then Begin
   WriteLn;
   WriteLn('Creation annulee.');
   Write('Appuyez sur une touche...');
   ReadKey;
   Exit;
  End;
 End;
 If TypeS='' Then Begin PType:=$0B; LocalHint:=0; End
 Else Begin PType:=ParsePartType(TypeS,$0B); LocalHint:=FsHint; End;

 { Construire l'entree }
 FillChar(PE,SizeOf(PE),0);
 PE.Status:=$00;
 PE.PartType:=PType;
 PE.SecOfs:=SecOfs;
 PE.NumSec:=NumSec;
 LBAtoCHS(SecOfs,PE.StartSec);
 LBAtoCHS(SecOfs+NumSec-1,PE.EndSec);

 Partition.PartTable[Slot]:=PE;
 Partition.IdCode:=$AA55;

 WritePartitionRecord;
 { Marqueur NTFS/HPFS dans le boot sector de la nouvelle partition. }
 If(PType=$07)And(LocalHint in[1,2])Then Begin
  FillChar(BootSec,SizeOf(BootSec),0);
  BootSec[0]:=$EB; BootSec[1]:=$52; BootSec[2]:=$90;
  BootSec[11]:=$00; BootSec[12]:=$02;
  BootSec[13]:=8;
  BootSec[510]:=$55; BootSec[511]:=$AA;
  If LocalHint=1 Then Begin
   BootSec[3]:=$4E; BootSec[4]:=$54; BootSec[5]:=$46; BootSec[6]:=$53;
   BootSec[7]:=$20; BootSec[8]:=$20; BootSec[9]:=$20; BootSec[10]:=$20;
  End Else Begin
   BootSec[54]:=$48; BootSec[55]:=$50; BootSec[56]:=$46; BootSec[57]:=$53;
   BootSec[58]:=$20; BootSec[59]:=$20; BootSec[60]:=$20; BootSec[61]:=$20;
  End;
  If Not WriteSector(SecOfs,BootSec)Then
   WriteLn('Avertissement : ecriture du marqueur de systeme echouee.');
 End;
 WriteLn;
 WriteLn('Partition ',Slot+1,' creee : LBA ',SecOfs,'..',SecOfs+NumSec-1,
         ' (',SizeMB,' Mo, type $',HexByteStr(PType),')');
 Write('Appuyez sur une touche...');
 ReadKey;
End;

Procedure ActivePartition;
Var
 Partition:PartSec Absolute Buffer;
 CurrActive,I,ActiveX,ActiveY:Byte;
Begin
 ClrScr;
 WriteLn;
 WriteLn;
 WriteLn;
 WriteLnCenter('Activation de la partition de la partition');
 WriteLn;
 WriteListPartition;
 WriteLn;
 WriteLn;
 WriteLn;
 Write(' ':2,'Entrez le num‚ro de la partition que vous voulez activer...: ');
 HighVideo;
 CurrActive:=0;
 For I:=0 to 3 do Begin
  If Partition.PartTable[I].Status=$80 Then CurrActive:=I+1;
 End;
 Write('[');
 ActiveX:=WhereX;
 ActiveY:=WhereY;
 WriteLn(CurrActive,']');
 GotoXY(1,25);
 LowVideo;
 Write(' ':2,'Appuyez sur ');
 HighVideo;
 Write('ECHAP');
 LowVideo;
 Write(' pour quitter FDISK');
 Repeat
  HighVideo;
  GotoXY(ActiveX,ActiveY);
  Write(CurrActive);
  GotoXY(ActiveX,ActiveY);
  LowVideo;
  Case ReadKey of
   '1':If Partition.PartTable[0].PartType<>0Then CurrActive:=1;
   '2':If Partition.PartTable[1].PartType<>0Then CurrActive:=2;
   '3':If Partition.PartTable[2].PartType<>0Then CurrActive:=3;
   '4':If Partition.PartTable[3].PartType<>0Then CurrActive:=4;
   #13:Begin
    Partition.PartTable[0].Status:=0;
    Partition.PartTable[1].Status:=0;
    Partition.PartTable[2].Status:=0;
    Partition.PartTable[3].Status:=0;
    Partition.PartTable[CurrActive-1].Status:=$80;
    WritePartitionRecord;
    Exit;
   End;
   #27:Exit;
  End;
 Until False;
End;

Procedure DeletePartition;
Var
 Partition:PartSec Absolute Buffer;
 I,Count,Slot:Byte;
 Ch:Char;
 Confirm:String;
Begin
 ClrScr;
 WriteLn;
 WriteLnCenter('Suppression d''une partition primaire DOS');
 WriteLn;
 ReadPartitionRecord;
 WriteListPartition;
 WriteLn;
 Count:=0;
 For I:=0 To 3 Do
  If Partition.PartTable[I].PartType<>0 Then Inc(Count);
 If Count=0 Then Begin
  WriteLn(' ':2,'Aucune partition a supprimer.');
  Write(' ':2,'Appuyez sur ');
  HighVideo; Write('ECHAP'); LowVideo;
  Write(' pour quitter FDISK');
  ReadKey;
  Exit;
 End;
 Write(' ':2,'Entrez le numero de la partition a supprimer (1-4, ECHAP=annuler) : ');
 Repeat
  Ch:=ReadKey;
  If Ch=#27 Then Exit;
  If Ch In['1'..'4']Then Begin
   Slot:=Ord(Ch)-Ord('1');
   If Partition.PartTable[Slot].PartType<>0 Then Break;
  End;
 Until False;
 WriteLn(Ch);
 WriteLn;
 Write(' ':2,'Confirmez la suppression de la partition ',Slot+1,
       ' en tapant son numero : ');
 ReadLn(Confirm);
 If Confirm<>Chr(Ord('1')+Slot)Then Begin
  WriteLn(' ':2,'Suppression annulee.');
  Write(' ':2,'Appuyez sur une touche...');
  ReadKey;
  Exit;
 End;
 FillChar(Partition.PartTable[Slot],SizeOf(PartEntry),0);
 Partition.IdCode:=$AA55;
 WritePartitionRecord;
 WriteLn;
 WriteLn(' ':2,'Partition ',Slot+1,' supprimee.');
 Write(' ':2,'Appuyez sur une touche...');
 ReadKey;
End;

Procedure ShowPartition;Begin
 ClrScr;
 WriteLn;
 WriteLn;
 WriteLn;
 WriteLnCenter('Affichage des informations sur les partitions');
 WriteLn;
 WriteListPartition;
 GotoXY(1,25);
 Write(' ':2,'Appuyez sur ');
 HighVideo;
 Write('ECHAP');
 LowVideo;
 Write(' pour quitter FDISK');
 ReadKey;
End;

{ Compte les disques durs physiques presents via Int 13h AH=08h.
  Retourne 0 sous Windows (stub) ou si BIOS indisponible. }
Function CountFixedDisks:Byte;
{$IFDEF Windows}
 Begin CountFixedDisks:=0; End;
{$ELSE}
Var
 Regs:Registers;
 D,N:Byte;
Begin
 N:=0;
 For D:=0 To 7 Do Begin
  Regs.AH:=$08;
  Regs.DL:=$80+D;
  Regs.ES:=0;
  Regs.DI:=0;
  Intr($13,Regs);
  If(Regs.Flags and FCarry)<>0 Then Break;
  Inc(N);
 End;
 CountFixedDisks:=N;
End;
{$ENDIF}

Procedure SelectFixedDisk;
Var
 NumDisks:Byte;
Begin
 ClrScr;
 WriteLn;
 WriteLnCenter('Selection du prochain disque dur fixe');
 WriteLn;
 If FileName<>'' Then Begin
  WriteLn(' ':2,'FDISK travaille sur le fichier image : ',FileName);
  WriteLn(' ':2,'La selection de disque n''est disponible que pour les');
  WriteLn(' ':2,'disques physiques (sans argument fichier).');
  WriteLn;
  Write(' ':2,'Appuyez sur une touche...');
  ReadKey;
  Exit;
 End;
{$IFDEF Windows}
 WriteLn(' ':2,'Acces BIOS Int 13h indisponible sous Windows.');
 WriteLn(' ':2,'Cette fonction n''est utilisable qu''en DOS reel.');
 WriteLn;
 Write(' ':2,'Appuyez sur une touche...');
 ReadKey;
{$ELSE}
 NumDisks:=CountFixedDisks;
 If NumDisks<=1 Then Begin
  WriteLn(' ':2,'Un seul disque dur fixe detecte (disque ',CurrentDisk,').');
  WriteLn(' ':2,'Aucun autre disque a selectionner.');
  WriteLn;
  Write(' ':2,'Appuyez sur une touche...');
  ReadKey;
  Exit;
 End;
 WriteLn(' ':2,NumDisks,' disques durs fixes detectes.');
 WriteLn(' ':2,'Disque courant : ',CurrentDisk);
 { Passer au disque suivant en boucle (1..NumDisks) }
 If CurrentDisk>=NumDisks Then CurrentDisk:=1
                          Else Inc(CurrentDisk);
 { Invalider la geometrie cachee, elle sera relue au prochain acces }
 GeoValid:=False;
 GeoHeads:=0;
 GeoSPT:=0;
 WriteLn(' ':2,'Nouveau disque actif : ',CurrentDisk);
 WriteLn;
 Write(' ':2,'Appuyez sur une touche...');
 ReadKey;
{$ENDIF}
End;

Procedure CreateDiskImage;
Var
 FName:String;
 SizeMB:LongInt;
 Overwrite:Boolean;
 F:File;
 Ch:Char;
Begin
 ClrScr;
 WriteLn;
 WriteLnCenter('Creation d''un fichier image de disque');
 WriteLn;
 Write(' ':2,'Nom du fichier image a creer : ');
 ReadLn(FName);
 If FName='' Then Exit;
 Write(' ':2,'Taille en Mo [10] : ');
 SizeMB:=ReadIntLine(10);
 If SizeMB<1 Then Begin
  WriteLn(' ':2,'Taille invalide.');
  ReadKey;
  Exit;
 End;
 Overwrite:=True;
 {$I-}Assign(F,FName);Reset(F,1);{$I+}
 If IOResult=0 Then Begin
  Close(F);
  Write(' ':2,'Le fichier existe deja. Ecraser ? (O/N) : ');
  Ch:=ReadKey;
  WriteLn(Ch);
  If(Ch<>'o')And(Ch<>'O')Then Begin
   WriteLn(' ':2,'Annule.');
   ReadKey;
   Exit;
  End;
 End;
 If DoCreateImage(FName,SizeMB,Overwrite,True)Then
  WriteLn(' ':2,'FDISK travaille maintenant sur cette image.');
 WriteLn;
 Write(' ':2,'Appuyez sur une touche...');
 ReadKey;
End;

Function ShowMainMenu:Byte;
Var
 Choice:Char;
 ChoiceX,ChoiceY:Byte;
Begin
 ShowMainMenu:=0;
 Choice:='4';
 TextBackground(0);
 TextColor(7);
 ClrScr;
 WriteLnCenter('FDISK');
 WriteLn;
 HighVideo;
 Case Language of
  _English: WriteLnCenter('Fixed Disk Setup Program');
  Else WriteLnCenter('Options de FDISK');
 End;
 WriteLn;
 LowVideo;
 Case Language of
  _English:Write(' ':4,'Current Fixed Disk Drive: ');
  Else Write(' ':4,'Lecteur de disque dur en cours : ');
 End;
 HighVideo;
 If FileName<>''Then WriteLn(FileName)
                Else WriteLn(CurrentDisk);
 LowVideo;
 WriteLn;
 Case Language of
  _English:WriteLn(' ':4,'Choose one of the following: ');
  Else WriteLn(' ':4,'Choisissez parmi ce qui suit : ');
 End;
 WriteLn;
 HighVideo;
 Write(' ':4,'1. ');
 LowVideo;
 Case Language of
  _English: WriteLn('Create DOS Partition');
  Else WriteLn('Cr‚ation d''une partition ou lecteur logique DOS');
 End;
 HighVideo;
 Write(' ':4,'2. ');
 LowVideo;
 Case Language of
  _English:WriteLn('Change Active partition');
  Else WriteLn('Activation d''une partition');
 End;
 HighVideo;
 Write(' ':4,'3. ');
 LowVideo;
 Case Language of
  _English:WriteLn('Delete DOS partition');
  Else WriteLn('Suppression d''une partition ou lecteur logique DOS');
 End;
 HighVideo;
 Write(' ':4,'4. ');
 LowVideo;
 Case Language of
  _English:WriteLn('Display Partition Data');
  Else WriteLn('Affichage des informations sur les partitions');
 End;
 HighVideo;
 Write(' ':4,'5. ');
 LowVideo;
 Case Language of
  _English:WriteLn('Select Next Fixed Disk Drive');
  Else WriteLn('S‚lectionne le prochain unit‚ de disque dur');
 End;
 HighVideo;
 Write(' ':4,'6. ');
 LowVideo;
 Case Language of
  _English:WriteLn('Create Disk Image File');
  Else WriteLn('Crï¿½ation d''un fichier image de disque');
 End;
 WriteLn;
 WriteLn;
 Case Language of
  _English:Write(' ':4,'Entrer choice: ');
  Else Write(' ':4,'Entrez votre choix : ');
 End;
 HighVideo;
 Write('[');
 ChoiceX:=WhereX;
 ChoiceY:=WhereY;
 WriteLn(Choice,']');
 LowVideo;
 WriteLn;
 WriteLn;
 WriteLn;
 Case Language of
  _English:Begin
   Write(' ':4,'Press ');
   HighVideo;
   Write('Esc');
   LowVideo;
   Write(' to return to DOS');
  End;
  Else Begin
   Write(' ':4,'Appuyez sur ');
   HighVideo;
   Write('ECHAP');
   LowVideo;
   Write(' pour quitter FDISK');
  End;
 End;
 Repeat
  GotoXY(ChoiceX,ChoiceY);
  Write(Choice);
  GotoXY(ChoiceX,ChoiceY);
  Case ReadKey of
   #0:ReadKey;
   #13:Begin
    Case Choice of
     '1':ShowMainMenu:=1;
     '2':ShowMainMenu:=2;
     '3':ShowMainMenu:=3;
     '4':ShowMainMenu:=4;
     '5':ShowMainMenu:=5;
     '6':ShowMainMenu:=6;
    End;
    Exit;
   End;
   #27:Exit;
   '1':Choice:='1';
   '2':Choice:='2';
   '3':Choice:='3';
   '4':Choice:='4';
   '5':Choice:='5';
   '6':Choice:='6';
  End;
 Until False;
End;

BEGIN
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ENDIF}
 {$ENDIF}
 Language:=_French;
 TmpLanguage:=GetEnv('LANGUAGE');
 If TmpLanguage<>''Then Begin
  If TmpLanguage[1]='"'Then TmpLanguage:=Copy(TmpLanguage,2,255);
  If StrToUpper(Copy(TmpLanguage,1,2))='EN'Then Language:=_English Else
  If StrToUpper(Copy(TmpLanguage,1,2))='GR'Then Language:=_Germany Else
  If StrToUpper(Copy(TmpLanguage,1,2))='IT'Then Language:=_Italian Else
  If StrToUpper(Copy(TmpLanguage,1,2))='SP'Then Language:=_Spain;
 End;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('FDISK : Cette commande permet d''effectuer la gestion des partitions d''un disque dur.');
  WriteLn;
  WriteLn('Syntaxe : FDISK [fichier] [commande [arguments...]]');
  WriteLn;
  WriteLn('Sans commande : interface menu interactive.');
  WriteLn;
  WriteLn('Commandes (non-interactives) :');
  WriteLn('  list                       Liste les partitions et quitte.');
  WriteLn('  create [taille] [type]     Cree une partition primaire.');
  WriteLn('                             taille : Mo (defaut/MAX = espace libre).');
  WriteLn('                             type   : 1=FAT12 2=FAT16<32M 3=BIGDOS');
  WriteLn('                                      4=FAT32 (defaut) 5=FAT32LBA');
  WriteLn('                                      6=NTFS 7=HPFS 8=OS/2BM');
  WriteLn('                                      9=XENIX 10=XENIX/usr');
  WriteLn('                                      11=AIX 12=AIXdata');
  WriteLn('                                      13=NECDOS 14=JFS');
  WriteLn('                                      ou $XX hexa (ex. $07 NTFS).');
  WriteLn('  delete <n>                 Supprime la partition n (1..4).');
  WriteLn('  activate <n>               Marque la partition n comme active.');
  WriteLn('  init                       Efface la table de partitions.');
  WriteLn('  image <fichier> <Mo>       Cree un fichier image disque vide.');
  WriteLn;
  WriteLn('Exemples :');
  WriteLn('  FDISK image disk.img 100         Cree image vide de 100 Mo.');
  WriteLn('  FDISK disk.img create 64 4       Cree FAT32 de 64 Mo.');
  WriteLn('  FDISK disk.img create MAX 6      Utilise tout l''espace, BIGDOS.');
  WriteLn('  FDISK disk.img activate 1');
  WriteLn('  FDISK disk.img list');
 End
  Else
 Begin
  If SizeOf(PartSec)<>512 Then Begin
   WriteLn('Mauvaise directive de compilation. Les enregistrements ne doivent pas ˆtre align‚s');
   Halt;
  End;
  FileName:='';
  CurrentDisk:=1;
  IsDisk:=True;
  TmpLanguage:=ParamStr(1);
  If(TmpLanguage<>'')And(TmpLanguage[1]<>'-')And(TmpLanguage[1]<>'/')Then Begin
   { Si ParamStr(1) est une commande connue, on travaille sur disque physique. }
   TmpLanguage:=StrToUpper(TmpLanguage);
   If(TmpLanguage<>'CREATE')And(TmpLanguage<>'DELETE')And
     (TmpLanguage<>'ACTIVATE')And(TmpLanguage<>'LIST')And
     (TmpLanguage<>'INIT')And(TmpLanguage<>'IMAGE')Then Begin
    FileName:=ParamStr(1);
    IsDisk:=False;
    DetectImageFormat;
   End;
  End;
  { Determiner l'index du parametre commande }
  If FileName='' Then CliI:=1 Else CliI:=2;
  TmpLanguage:=StrToUpper(ParamStr(CliI));
  If TmpLanguage<>'' Then Begin
   { Mode CLI non-interactif }
   If TmpLanguage='LIST' Then Begin
    ReadPartitionRecord;
    WriteListPartition;
   End Else
   If TmpLanguage='CREATE' Then Begin
    If Not DoCreatePartition(ParseSizeMB(ParamStr(CliI+1)),
                             ParsePartType(ParamStr(CliI+2),$0B),
                             True)Then Halt(1);
   End Else
   If TmpLanguage='DELETE' Then Begin
    Val(ParamStr(CliI+1),CliJ,CliCode);
    If(CliCode<>0)Or Not DoDeletePartition(Byte(CliJ),True)Then Halt(1);
   End Else
   If TmpLanguage='ACTIVATE' Then Begin
    Val(ParamStr(CliI+1),CliJ,CliCode);
    If(CliCode<>0)Or Not DoActivatePartition(Byte(CliJ),True)Then Halt(1);
   End Else
   If TmpLanguage='INIT' Then Begin
    If Not DoInitMBR(True)Then Halt(1);
   End Else
   If TmpLanguage='IMAGE' Then Begin
    { FDISK image <fichier> <Mo> }
    If Not DoCreateImage(ParamStr(CliI+1),ParseSizeMB(ParamStr(CliI+2)),
                         True,True)Then Halt(1);
   End Else Begin
    WriteLn('Commande inconnue : ',ParamStr(CliI));
    WriteLn('Utilisez FDISK /? pour l''aide.');
    Halt(1);
   End;
  End Else Begin
   { Mode menu interactif }
   Repeat
    Case ShowMainMenu of
     0:Break;
     1:CreatePartition;
     2:ActivePartition;
     3:DeletePartition;
     4:ShowPartition;
     5:SelectFixedDisk;
     6:CreateDiskImage;
    End;
   Until False;
   ClrScr;
  End;
 End;
END.
