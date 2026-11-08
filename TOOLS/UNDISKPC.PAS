{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program UNDISKPC;

{$A-}
{$R-}
{$Q-}
{$M 65520,0,655360}

Uses DOS;

Const
 SectorSize=512;
 MaxPathLen=128;

Type
 TSector=Array[0..SectorSize-1]of Byte;

Var
 Img:File;
 ImgName,DestDir:String;
 Sec:TSector;
 BytesPerSector:Word;
 SectorsPerCluster:Byte;
 ReservedSectors:Word;
 NumFATs:Byte;
 RootEntries:Word;
 TotalSectors:LongInt;
 SectorsPerFAT:LongInt;
 RootCluster:LongInt;
 PartitionStart:LongInt;
 FATStart,RootStart,DataStart:LongInt;
 RootDirSectors:LongInt;
 ClusterCount:LongInt;
 FATType:Integer;
 BPBOffset:Integer;
 FilesExtracted,DirsCreated:LongInt;
 RootEntriesSeen:LongInt;
 IsHardDiskImage:Boolean;
 { Translation d'image VHD / VMDK. ImgKind = 0 raw, 1 VHD fixe,
   2 VHD dynamique, 3 VMDK sparse. }
 ImgKind:Byte;
 VirtDiskSec:LongInt;
 VHDBlockSizeSec:LongInt;
 VHDBitmapSecs:LongInt;
 VHDBATFileOfs:LongInt;
 VMDKGTEsPerGT:LongInt;
 FATCachedLBA:LongInt;
 FATCachedBuf:TSector;
 TempImgName:String;
 Verbose:Boolean;
 ArgIdx:Integer;
 ArgStr:String;

Function UpStr(S:String):String;
Var
 I:Integer;
Begin
 For I:=1 to Length(S)do
  If S[I] in['a'..'z'] Then S[I]:=Chr(Ord(S[I])-32);
 UpStr:=S;
End;

Function Path2Name(S:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(S,D,N,E);
 If N=''Then N:='DISK';
 Path2Name:=N;
End;

Function PathDir(S:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(S,D,N,E);
 PathDir:=D;
End;

Function HexDigit(N:Byte):Char;
Begin
 If N<10Then HexDigit:=Chr(Ord('0')+N)
        Else HexDigit:=Chr(Ord('A')+N-10);
End;

Function HexByte(B:Byte):String;
Begin
 HexByte:=HexDigit((B shr 4)and 15)+HexDigit(B and 15);
End;

Function JoinPath(A,B:String):String;
Begin
 If A=''Then JoinPath:=B
  Else If A[Length(A)] in['\','/'] Then JoinPath:=A+B
  Else JoinPath:=A+'\'+B;
End;

Procedure MakePath(P:String);
Var
 I:Integer;
 S:String;
Begin
 If P=''Then Exit;
 S:='';
 For I:=1 to Length(P)do Begin
  S:=S+P[I];
  If(P[I]='\')or(P[I]='/') Then Begin
   If Length(S)>1 Then Begin
    {$I-}MkDir(S);{$I+}
    If IoResult<>0 Then Begin End;
   End;
  End;
 End;
 {$I-}MkDir(P);{$I+}
 If IoResult=0 Then Inc(DirsCreated);
End;

Function LE16(Off:Integer):Word;
Begin
 LE16:=Word(Sec[Off])or(Word(Sec[Off+1])shl 8);
End;

Function LE16At(Off:Integer):Word;
Begin
 LE16At:=Word(Sec[Off])or(Word(Sec[Off+1])shl 8);
End;

Function LE32At(Off:Integer):LongInt;
Begin
 LE32At:=LongInt(Sec[Off])+
       LongInt(Sec[Off+1])*256+
       LongInt(Sec[Off+2])*65536+
       LongInt(Sec[Off+3])*16777216;
End;

Function LE32(Off:Integer):LongInt;
Begin
 LE32:=LongInt(Sec[Off])+
       LongInt(Sec[Off+1])*256+
       LongInt(Sec[Off+2])*65536+
       LongInt(Sec[Off+3])*16777216;
End;

{ Detection format d'image (raw, VHD fixe, VHD dynamique, VMDK sparse,
  ou VMDK descripteur texte). Peut reassigner Img si descripteur ->
  fichier flat. Met a jour ImgKind, VirtDiskSec, etc. }
Function VirtualSectors:LongInt;
Begin
 If VirtDiskSec>0 Then VirtualSectors:=VirtDiskSec
                  Else VirtualSectors:=FileSize(Img)Div SectorSize;
End;

Procedure DecodeTeleDisk;
{ Decode une image TeleDisk *.TD0 (signature 'TD' non compressee) vers
  un fichier temporaire brut, puis reouvre Img sur ce fichier. La
  signature 'td' minuscule (LZHUF) n'est pas supportee. }
Var
 Hdr:Array[0..11]of Byte;
 R,W:Word;
 Stepping:Byte;
 Sides,Heads:Byte;
 CmtHdr:Array[0..9]of Byte;
 CommentLen:LongInt;
 Skipped:LongInt;
 ChunkLen:Integer;
 SkipBuf:Array[0..255]of Byte;
 TrackHdr:Array[0..3]of Byte;
 SecHdr:Array[0..5]of Byte;
 NumSec,Cyl,Head,SecID,SizeCode,Flags:Byte;
 SecSize:Word;
 DataLen:Word;
 Method:Byte;
 EncBuf:Array[0..16383]of Byte;
 DecBuf:Array[0..16383]of Byte;
 TmpF:File;
 SPT:Byte;
 LBA:LongInt;
 I:Integer;
 K:Integer;
 P,Q,Cnt:LongInt;
 BlockSize:Integer;
 Code,PatLen:Byte;
 NewName:String;
Begin
 Seek(Img,0);
 BlockRead(Img,Hdr,12,R);
 If R<12 Then Exit;
 If(Hdr[0]=Ord('t'))and(Hdr[1]=Ord('d'))Then Begin
  WriteLn('TeleDisk compresse (signature "td" minuscule, LZHUF) non supporte.');
  WriteLn('Convertir d''abord en TD0 non compresse (signature "TD") avec ',
          'WTELEDSK ou WTD2IMG.');
  Halt(1);
 End;
 If Not((Hdr[0]=Ord('T'))and(Hdr[1]=Ord('D')))Then Exit;
 Stepping:=Hdr[7];
 Sides:=Hdr[9];
 If(Sides=0)or(Sides>2)Then Sides:=2;
 Heads:=Sides;
 If(Stepping and $80)<>0 Then Begin
  BlockRead(Img,CmtHdr,10,R);
  If R<10 Then Exit;
  CommentLen:=LongInt(CmtHdr[2])or(LongInt(CmtHdr[3])shl 8);
  Skipped:=0;
  While Skipped<CommentLen do Begin
   If CommentLen-Skipped>SizeOf(SkipBuf)Then ChunkLen:=SizeOf(SkipBuf)
                                        Else ChunkLen:=CommentLen-Skipped;
   BlockRead(Img,SkipBuf,ChunkLen,R);
   If R=0 Then Break;
   Inc(Skipped,R);
  End;
 End;
 NewName:=ImgName+'.tdraw';
 Assign(TmpF,NewName);
 {$I-}Rewrite(TmpF,1);{$I+}
 If IoResult<>0 Then Begin
  WriteLn('Impossible de creer le fichier temporaire ',NewName);
  Halt(1);
 End;
 SPT:=0;
 While True do Begin
  BlockRead(Img,TrackHdr,4,R);
  If R<4 Then Break;
  NumSec:=TrackHdr[0];
  If NumSec=$FF Then Break;
  Cyl:=TrackHdr[1];
  Head:=TrackHdr[2] and $7F;
  For I:=1 to NumSec do Begin
   BlockRead(Img,SecHdr,6,R);
   If R<6 Then Begin Close(TmpF); Exit; End;
   SecID:=SecHdr[2];
   SizeCode:=SecHdr[3];
   Flags:=SecHdr[4];
   If SizeCode>4 Then SizeCode:=2;
   SecSize:=128;
   For K:=1 to SizeCode do SecSize:=SecSize shl 1;
   FillChar(DecBuf,SizeOf(DecBuf),0);
   If(Flags and $30)=0 Then Begin
    BlockRead(Img,EncBuf,2,R);
    If R<2 Then Begin Close(TmpF); Exit; End;
    DataLen:=Word(EncBuf[0])or(Word(EncBuf[1])shl 8);
    If DataLen=0 Then Continue;
    BlockRead(Img,Method,1,R);
    If R<1 Then Begin Close(TmpF); Exit; End;
    If DataLen-1>SizeOf(EncBuf)Then Begin
     Close(TmpF);
     WriteLn('Bloc TeleDisk trop grand : ',DataLen-1);
     Halt(1);
    End;
    BlockRead(Img,EncBuf,DataLen-1,R);
    If R<DataLen-1 Then Begin Close(TmpF); Exit; End;
    Case Method of
     0:Begin
        If SecSize<=R Then Move(EncBuf,DecBuf,SecSize)
                      Else Move(EncBuf,DecBuf,R);
       End;
     1:Begin
        Cnt:=Word(EncBuf[0])or(Word(EncBuf[1])shl 8);
        Q:=0;
        For K:=1 to Cnt do Begin
         If Q+1<SecSize Then Begin
          DecBuf[Q]:=EncBuf[2];
          DecBuf[Q+1]:=EncBuf[3];
         End;
         Inc(Q,2);
        End;
       End;
     2:Begin
        P:=0; Q:=0;
        While(Q<SecSize)and(P<LongInt(DataLen)-1)do Begin
         Code:=EncBuf[P]; Inc(P);
         If Code=0 Then Begin
          PatLen:=EncBuf[P]; Inc(P);
          If Q+PatLen<=SecSize Then Move(EncBuf[P],DecBuf[Q],PatLen);
          Inc(P,PatLen); Inc(Q,PatLen);
         End Else Begin
          PatLen:=EncBuf[P]; Inc(P);
          BlockSize:=1;
          For K:=1 to Code do BlockSize:=BlockSize shl 1;
          For K:=1 to PatLen do Begin
           If Q+BlockSize<=SecSize Then Move(EncBuf[P],DecBuf[Q],BlockSize);
           Inc(Q,BlockSize);
          End;
          Inc(P,BlockSize);
         End;
        End;
       End;
    End;
   End;
   { Ignorer secteurs fantomes : ID hors plage usuelle ou flag 0x40
     ("no data, no ID"). Le bloc de donnees a deja ete lu et passe;
     on saute juste l'ecriture dans l'image. }
   If(SecID<1)or(SecID>63)or((Flags and $40)<>0)Then Continue;
   { Sur la premiere piste (Cyl=0, Head=0), apprendre le vrai SPT en
     prenant le max des SecID valides. }
   If(Cyl=0)and(Head=0)and(SecID>SPT)Then SPT:=SecID;
   If SPT=0 Then SPT:=1;
   LBA:=(LongInt(Cyl)*Heads+Head)*LongInt(SPT)+(LongInt(SecID)-1);
   If LBA>=0 Then Begin
    Seek(TmpF,LBA*512);
    BlockWrite(TmpF,DecBuf,SecSize,W);
   End;
  End;
 End;
 Close(TmpF);
 Close(Img);
 TempImgName:=NewName;
 ImgName:=NewName;
 Assign(Img,ImgName);
 {$I-}Reset(Img,1);{$I+}
 If IoResult<>0 Then Begin
  WriteLn('Impossible de rouvrir le fichier decode ',ImgName);
  Halt(1);
 End;
 WriteLn('Format detecte : TeleDisk (decode, ',
         FileSize(Img)Div 512,' secteurs).');
End;

Procedure DetectImageFormat;
Var
 Raw:Array[0..511]of Byte;
 R:Word;
 Sz,DiskType,BlockSize,BAToff,CurSize,ExtSecs,ExtOfs:LongInt;
 I,J,K,Code:Integer;
 S,ExtName,DescDir,Num:String;

 Function ReadLE32At(Ofs:Integer):LongInt;
 Begin
  ReadLE32At:=LongInt(Raw[Ofs])Or(LongInt(Raw[Ofs+1])Shl 8)
             Or(LongInt(Raw[Ofs+2])Shl 16)Or(LongInt(Raw[Ofs+3])Shl 24);
 End;

Begin
 ImgKind:=0; VirtDiskSec:=0; VHDBlockSizeSec:=0;
 VHDBitmapSecs:=0; VHDBATFileOfs:=0; VMDKGTEsPerGT:=0;
 Sz:=FileSize(Img);
 If Sz<512 Then Exit;
 FillChar(Raw,SizeOf(Raw),0);
 Seek(Img,0);
 BlockRead(Img,Raw,512,R);
 If R=0 Then Exit;

 { ===== TeleDisk : signature 'TD' ou 'td' a l'offset 0 ===== }
 If((Raw[0]=Ord('T'))and(Raw[1]=Ord('D')))or
   ((Raw[0]=Ord('t'))and(Raw[1]=Ord('d')))Then Begin
  DecodeTeleDisk;
  Exit;
 End;

 { ===== VMDK sparse : magic 'KDMV' (0x564D444B little-endian) ===== }
 If(Raw[0]=$4B)And(Raw[1]=$44)And(Raw[2]=$4D)And(Raw[3]=$56)Then Begin
  VirtDiskSec:=ReadLE32At(12);          { Capacity low 32 bits }
  VHDBlockSizeSec:=ReadLE32At(20);      { GrainSize }
  VMDKGTEsPerGT:=ReadLE32At(44);
  BAToff:=ReadLE32At(56);               { GDOffset (en secteurs) }
  If BAToff<=0 Then BAToff:=ReadLE32At(48);
  If(BAToff<=0)Or(VHDBlockSizeSec<=0)Or(VMDKGTEsPerGT<=0)Then Exit;
  VHDBATFileOfs:=BAToff*512;
  ImgKind:=3;
  Exit;
 End;

 { ===== VMDK descripteur texte ===== }
 If(Raw[0]=$23)Or((Raw[0]>=Ord('A'))And(Raw[0]<=Ord('z')))Then Begin
  S:='';
  For I:=0 To 511 Do
   If(Raw[I]>=32)Or(Raw[I]=10)Or(Raw[I]=13)Or(Raw[I]=9)Then
    S:=S+Chr(Raw[I])
   Else
    S:=S+' ';
  I:=Pos('DescriptorFile',S);
  If I=0 Then I:=Pos('createType',S);
  If I>0 Then Begin
   I:=Pos('RW ',S);
   If(I>0)And(Pos('FLAT',S)>I)Then Begin
    K:=I+3;
    While(K<=Length(S))And(S[K]=' ')Do Inc(K);
    Num:='';
    While(K<=Length(S))And(S[K] in['0'..'9'])Do Begin
     Num:=Num+S[K]; Inc(K);
    End;
    Val(Num,ExtSecs,Code);
    If Code<>0 Then ExtSecs:=0;
    I:=Pos('FLAT',S);
    K:=I+4;
    While(K<=Length(S))And(S[K]<>'"')Do Inc(K);
    If(K<Length(S))And(S[K]='"')Then Begin
     Inc(K);
     ExtName:='';
     While(K<=Length(S))And(S[K]<>'"')Do Begin
      ExtName:=ExtName+S[K]; Inc(K);
     End;
     If S[K]='"' Then Inc(K);
     While(K<=Length(S))And(S[K]=' ')Do Inc(K);
     Num:='';
     While(K<=Length(S))And(S[K] in['0'..'9'])Do Begin
      Num:=Num+S[K]; Inc(K);
     End;
     Val(Num,ExtOfs,Code);
     If Code<>0 Then ExtOfs:=0;
     { Resoudre chemin relatif. ExtOfs n'est pas utilise (offset
       dans le flat, on suppose 0). }
     DescDir:=ImgName;
     J:=Length(DescDir);
     While(J>0)And(DescDir[J]<>'\')And(DescDir[J]<>'/')And(DescDir[J]<>':')Do
       Dec(J);
     DescDir:=Copy(DescDir,1,J);
     If(Pos(':',ExtName)=0)And(Length(ExtName)>0)And
       (ExtName[1]<>'\')And(ExtName[1]<>'/')Then
      ExtName:=DescDir+ExtName;
     Close(Img);
     ImgName:=ExtName;
     Assign(Img,ImgName);
     {$I-}Reset(Img,1);{$I+}
     If IoResult<>0 Then Begin
      WriteLn('Impossible d''ouvrir l''extension VMDK : ',ImgName);
      Halt(1);
     End;
     VirtDiskSec:=ExtSecs;
     DetectImageFormat;   { re-detection au cas ou l'extension est VHD }
     Exit;
    End;
   End;
   Exit;
  End;
 End;

 { ===== VHD : footer 'conectix' aux 512 derniers octets ===== }
 If Sz<1024 Then Exit;
 Seek(Img,Sz-512);
 BlockRead(Img,Raw,512,R);
 If R<>512 Then Exit;
 If(Raw[0]<>$63)Or(Raw[1]<>$6F)Or(Raw[2]<>$6E)Or(Raw[3]<>$65)Or
   (Raw[4]<>$63)Or(Raw[5]<>$74)Or(Raw[6]<>$69)Or(Raw[7]<>$78)Then Exit;
 DiskType:=(LongInt(Raw[60])Shl 24)Or(LongInt(Raw[61])Shl 16)
          Or(LongInt(Raw[62])Shl 8)Or LongInt(Raw[63]);
 CurSize:=(LongInt(Raw[52])Shl 24)Or(LongInt(Raw[53])Shl 16)
         Or(LongInt(Raw[54])Shl 8)Or LongInt(Raw[55]);
 VirtDiskSec:=CurSize Div 512;
 Case DiskType Of
  2:Begin ImgKind:=1; Exit; End;
  3,4:Begin
   Seek(Img,512);
   BlockRead(Img,Raw,512,R);
   If R<>512 Then Exit;
   If(Raw[0]<>$63)Or(Raw[1]<>$78)Or(Raw[2]<>$73)Or(Raw[3]<>$70)Or
     (Raw[4]<>$61)Or(Raw[5]<>$72)Or(Raw[6]<>$73)Or(Raw[7]<>$65)Then Exit;
   BAToff:=(LongInt(Raw[20])Shl 24)Or(LongInt(Raw[21])Shl 16)
          Or(LongInt(Raw[22])Shl 8)Or LongInt(Raw[23]);
   BlockSize:=(LongInt(Raw[32])Shl 24)Or(LongInt(Raw[33])Shl 16)
             Or(LongInt(Raw[34])Shl 8)Or LongInt(Raw[35]);
   If(BlockSize=0)Or(BlockSize Mod 512<>0)Then Exit;
   VHDBlockSizeSec:=BlockSize Div 512;
   VHDBitmapSecs:=((VHDBlockSizeSec Div 8)+511)Div 512;
   If VHDBitmapSecs<1 Then VHDBitmapSecs:=1;
   VHDBATFileOfs:=BAToff;
   ImgKind:=2;
   Exit;
  End;
 End;
End;

Procedure ReadSector(LBA:LongInt);
Var
 R:Word;
 Ofs,BlockIdx,OfsInBlock,BATEntry,GrainNum,GTIdx,GTOff,GTSec,GrainSec:LongInt;
 Buf4:Array[0..3]of Byte;
Begin
 { Translation virtuelle pour VHD / VMDK. ImgKind=0 ou 1 (fixe) :
   offset = LBA*512. Sinon lookup BAT/GD. }
 If(ImgKind=0)Or(ImgKind=1)Then Ofs:=LBA*SectorSize Else
 If ImgKind=2 Then Begin
  { VHD dynamique }
  BlockIdx:=LBA Div VHDBlockSizeSec;
  OfsInBlock:=LBA Mod VHDBlockSizeSec;
  Seek(Img,VHDBATFileOfs+BlockIdx*4);
  BlockRead(Img,Buf4,4,R);
  If R<>4 Then Begin FillChar(Sec,SectorSize,0); Exit; End;
  BATEntry:=(LongInt(Buf4[0])Shl 24)Or(LongInt(Buf4[1])Shl 16)
           Or(LongInt(Buf4[2])Shl 8)Or LongInt(Buf4[3]);
  If BATEntry=-1 Then Begin FillChar(Sec,SectorSize,0); Exit; End;
  Ofs:=(BATEntry+VHDBitmapSecs)*512+OfsInBlock*512;
 End Else
 If ImgKind=3 Then Begin
  { VMDK sparse : GrainDir -> GrainTable -> grain }
  GrainNum:=LBA Div VHDBlockSizeSec;
  GTIdx:=GrainNum Div VMDKGTEsPerGT;
  GTOff:=GrainNum Mod VMDKGTEsPerGT;
  OfsInBlock:=LBA Mod VHDBlockSizeSec;
  Seek(Img,VHDBATFileOfs+GTIdx*4);
  BlockRead(Img,Buf4,4,R);
  If R<>4 Then Begin FillChar(Sec,SectorSize,0); Exit; End;
  GTSec:=LongInt(Buf4[0])Or(LongInt(Buf4[1])Shl 8)
        Or(LongInt(Buf4[2])Shl 16)Or(LongInt(Buf4[3])Shl 24);
  If GTSec=0 Then Begin FillChar(Sec,SectorSize,0); Exit; End;
  Seek(Img,GTSec*512+GTOff*4);
  BlockRead(Img,Buf4,4,R);
  If R<>4 Then Begin FillChar(Sec,SectorSize,0); Exit; End;
  GrainSec:=LongInt(Buf4[0])Or(LongInt(Buf4[1])Shl 8)
           Or(LongInt(Buf4[2])Shl 16)Or(LongInt(Buf4[3])Shl 24);
  If GrainSec=0 Then Begin FillChar(Sec,SectorSize,0); Exit; End;
  Ofs:=GrainSec*512+OfsInBlock*512;
 End Else Ofs:=LBA*SectorSize;
 Seek(Img,Ofs);
 BlockRead(Img,Sec,SectorSize,R);
 If R<>SectorSize Then Begin
  WriteLn('Lecture secteur impossible: ',LBA);
  Halt(1);
 End;
End;

Function LooksLikeBPB:Boolean;
Var
 BPS:Word;
 SPC:Byte;
 OK:Boolean;
Begin
 BPBOffset:=0;
 BPS:=LE16At(11);
 SPC:=Sec[13];
 OK:=(BPS=512)and(SPC<>0)and(Sec[16]<>0)and
  (LE16At(14)<>0)and((LE16At(17)<>0)or
  ((LE16At(22)=0)and(LE32At(36)<>0)));
 If OK Then Begin LooksLikeBPB:=True; Exit; End;
 BPS:=LE16At(12);
 SPC:=Sec[14];
 OK:=(BPS=512)and(SPC<>0)and(Sec[17]<>0)and
  (LE16At(15)<>0)and((LE16At(18)<>0)or
  ((LE16At(23)=0)and(LE32At(37)<>0)));
 If OK Then BPBOffset:=1;
 LooksLikeBPB:=OK;
End;

Function FindPartitionStart:LongInt;
Var
 I,O:Integer;
 T:Byte;
 LBA,SZ:LongInt;
Begin
 FindPartitionStart:=0;
 ReadSector(0);
 If LooksLikeBPB Then Exit;
 If(Sec[510]<>$55)or(Sec[511]<>$AA) Then Begin
  FindPartitionStart:=-1;
  Exit;
 End;
 For I:=0 to 3 do Begin
  O:=446+I*16;
  T:=Sec[O+4];
  LBA:=LE32(O+8);
  SZ:=LE32(O+12);
  If(T<>0)and(LBA>0)and(SZ>0) Then Begin
   FindPartitionStart:=LBA;
   Exit;
  End;
 End;
 WriteLn('Aucune partition FAT trouvee dans le MBR.');
 Halt(1);
End;

Function IsFATPartitionType(T:Byte):Boolean;
Begin
 IsFATPartitionType:=T in[$01,$04,$06,$0B,$0C,$0E,$11,$14,$16,$1B,$1C,$1E];
End;

Function IsExtendedPartitionType(T:Byte):Boolean;
Begin
 IsExtendedPartitionType:=T in[$05,$0F,$85];
End;

Function IsHPFSPartitionType(T:Byte):Boolean;
Begin
 IsHPFSPartitionType:=T=$07;
End;

Function InferFloppyBySize:Boolean;
Var
 Sectors:LongInt;
Begin
 InferFloppyBySize:=False;
 Sectors:=VirtualSectors;
 PartitionStart:=0;
 BytesPerSector:=SectorSize;
 ReservedSectors:=1;
 NumFATs:=2;
 TotalSectors:=Sectors;
 RootCluster:=0;
 Case Sectors of
  720:Begin
       SectorsPerCluster:=2;
       RootEntries:=112;
       SectorsPerFAT:=2;
      End;
  1440:Begin
       SectorsPerCluster:=2;
       RootEntries:=112;
       SectorsPerFAT:=3;
      End;
  2400:Begin
       SectorsPerCluster:=1;
       RootEntries:=224;
       SectorsPerFAT:=7;
      End;
  2880:Begin
       SectorsPerCluster:=1;
       RootEntries:=224;
       SectorsPerFAT:=9;
      End;
 Else
  Exit;
 End;
 RootDirSectors:=(LongInt(RootEntries)*32+SectorSize-1)div SectorSize;
 FATStart:=PartitionStart+ReservedSectors;
 RootStart:=FATStart+LongInt(NumFATs)*SectorsPerFAT;
 DataStart:=RootStart+RootDirSectors;
 ClusterCount:=(TotalSectors-(ReservedSectors+
  LongInt(NumFATs)*SectorsPerFAT+RootDirSectors))div SectorsPerCluster;
 FATType:=12;
 WriteLn('FAT12 sans BPB standard, format deduit par taille (',
  LongInt(VirtualSectors)*SectorSize,' octets virtuels).');
 InferFloppyBySize:=True;
End;

Procedure ReadBootAt(StartLBA:LongInt);
Var
 TS16:Word;
 TS32:LongInt;
 SPF16:Word;
Begin
 PartitionStart:=StartLBA;
 ReadSector(PartitionStart);
 If Not LooksLikeBPB Then Begin
  WriteLn('Secteur de demarrage FAT invalide.');
  Halt(1);
 End;
 BytesPerSector:=LE16At(11+BPBOffset);
 If BytesPerSector<>SectorSize Then Begin
  WriteLn('Seuls les secteurs de 512 octets sont supportes.');
  Halt(1);
 End;
 SectorsPerCluster:=Sec[13+BPBOffset];
 ReservedSectors:=LE16At(14+BPBOffset);
 NumFATs:=Sec[16+BPBOffset];
 RootEntries:=LE16At(17+BPBOffset);
 TS16:=LE16At(19+BPBOffset);
 TS32:=LE32At(32+BPBOffset);
 If TS16<>0 Then TotalSectors:=TS16 Else TotalSectors:=TS32;
 SPF16:=LE16At(22+BPBOffset);
 If SPF16<>0 Then SectorsPerFAT:=SPF16
             Else SectorsPerFAT:=LE32At(36+BPBOffset);
 If SectorsPerFAT=0 Then Begin
  WriteLn('Taille FAT invalide.');
  Halt(1);
 End;
 If RootEntries=0 Then RootCluster:=LE32At(44+BPBOffset)
                  Else RootCluster:=0;
 RootDirSectors:=(LongInt(RootEntries)*32+SectorSize-1)div SectorSize;
 FATStart:=PartitionStart+ReservedSectors;
 RootStart:=FATStart+LongInt(NumFATs)*SectorsPerFAT;
 DataStart:=RootStart+RootDirSectors;
 ClusterCount:=(TotalSectors-(ReservedSectors+
  LongInt(NumFATs)*SectorsPerFAT+RootDirSectors))div SectorsPerCluster;
 If ClusterCount<4085 Then FATType:=12
  Else If ClusterCount<65525 Then FATType:=16
  Else FATType:=32;
 If(FATType=32)and(RootCluster<2)Then RootCluster:=2;
 If Verbose Then
  WriteLn('FAT',FATType,'  secteurs=',TotalSectors,
   '  cluster=',SectorsPerCluster,'  racine=',RootEntries);
End;

Procedure ReadBoot;
Begin
 PartitionStart:=FindPartitionStart;
 If PartitionStart<0 Then Begin
  If InferFloppyBySize Then Exit;
  WriteLn('Image disque PC invalide: ni BPB FAT ni MBR.');
  Halt(1);
 End;
 ReadBootAt(PartitionStart);
End;

Function FATByte(Offset:LongInt):Byte;
Var
 LBA:LongInt;
 Within:Word;
 SavedSec:TSector;
Begin
 LBA:=FATStart+(Offset Div SectorSize);
 Within:=Word(Offset Mod SectorSize);
 If LBA<>FATCachedLBA Then Begin
  { Preserver Sec (utilise par l'appelant pour le repertoire en cours) }
  SavedSec:=Sec;
  ReadSector(LBA);
  FATCachedBuf:=Sec;
  Sec:=SavedSec;
  FATCachedLBA:=LBA;
 End;
 FATByte:=FATCachedBuf[Within];
End;

Function NextCluster(Cl:LongInt):LongInt;
Var
 O:LongInt;
 B1,B2:Byte;
 V:LongInt;
Begin
 If FATType=12 Then Begin
  O:=LongInt(Cl)+(LongInt(Cl)div 2);
  B1:=FATByte(O);
  B2:=FATByte(O+1);
  V:=Word(B1)or(Word(B2)shl 8);
  If(Cl and 1)<>0 Then V:=V shr 4 Else V:=V and $0FFF;
  NextCluster:=V;
 End
  Else If FATType=32 Then Begin
  O:=LongInt(Cl)*4;
  V:=LongInt(FATByte(O))or(LongInt(FATByte(O+1))shl 8)or
     (LongInt(FATByte(O+2))shl 16)or(LongInt(FATByte(O+3))shl 24);
  NextCluster:=V and $0FFFFFFF;
 End
  Else
 Begin
  O:=LongInt(Cl)*2;
  NextCluster:=Word(FATByte(O))or(Word(FATByte(O+1))shl 8);
 End;
End;

Function IsEOC(Cl:LongInt):Boolean;
Begin
 If FATType=12 Then IsEOC:=Cl>=$0FF8
  Else If FATType=16 Then IsEOC:=Cl>=$FFF8
  Else IsEOC:=Cl>=$0FFFFFF8;
End;

Function ClusterSector(Cl:LongInt):LongInt;
Begin
 ClusterSector:=DataStart+LongInt(Cl-2)*SectorsPerCluster;
End;

Function CleanChar(C:Char):Char;
Begin
 If C in['A'..'Z','a'..'z','0'..'9','$','%','''','-','_','@','~','`','!','(',
   ')','{','}','^','#','&'] Then
  CleanChar:=C
 Else CleanChar:='_';
End;

Function ValidNameChar(B:Byte):Boolean;
Var
 C:Char;
Begin
 C:=Chr(B);
 ValidNameChar:=(B=32)or
  (C in['A'..'Z','a'..'z','0'..'9','$','%','''','-','_','@','~','`','!','(',')',
    '{','}','^','#','&']);
End;

Function ValidDirEntry(Off:Integer):Boolean;
Var
 I:Integer;
 Attr:Byte;
Begin
 ValidDirEntry:=False;
 If(Sec[Off]=$00)or(Sec[Off]=$E5)Then Exit;
 If Not ValidNameChar(Sec[Off])or(Sec[Off]=32)Then Exit;
 For I:=0 to 10 do If Not ValidNameChar(Sec[Off+I])Then Exit;
 Attr:=Sec[Off+11];
 If(Attr and $C0)<>0Then Exit;
 ValidDirEntry:=True;
End;

Function EntryName(Off:Integer):String;
Var
 I:Integer;
 N,E:String;
Begin
 N:='';
 For I:=0 to 7 do If Sec[Off+I]<>32 Then N:=N+CleanChar(Chr(Sec[Off+I]));
 E:='';
 For I:=8 to 10 do If Sec[Off+I]<>32 Then E:=E+CleanChar(Chr(Sec[Off+I]));
 If E<>''Then EntryName:=N+'.'+E Else EntryName:=N;
End;

Procedure SetFileDate(P:String;T,D:Word);
Var
 F:File;
 Stamp:LongInt;
 R:Integer;
Begin
 Assign(F,P);
 {$I-}Reset(F,1);{$I+}
 R:=IoResult;
 If R<>0 Then Exit;
 Stamp:=(LongInt(D)shl 16)or T;
 SetFTime(F,Stamp);
 Close(F);
End;

Procedure ExtractFile(Cl:LongInt;Size:LongInt;OutName:String;T,D:Word);
Var
 F:File;
 W:Word;
 ToWrite:Word;
 S,I:LongInt;
 Cur:LongInt;
Begin
 MakePath(PathDir(OutName));
 Assign(F,OutName);
 {$I-}Rewrite(F,1);{$I+}
 If IoResult<>0 Then Begin
  WriteLn('Impossible de creer ',OutName);
  Halt(1);
 End;
 Cur:=Cl;
 While(Size>0)and(Cur>=2)and(Not IsEOC(Cur))do Begin
  S:=ClusterSector(Cur);
  For I:=0 to SectorsPerCluster-1 do Begin
   If Size<=0 Then Break;
   ReadSector(S+I);
   If Size>SectorSize Then ToWrite:=SectorSize Else ToWrite:=Word(Size);
   BlockWrite(F,Sec,ToWrite,W);
   If W<>ToWrite Then Begin
    Close(F);
    WriteLn('Erreur ecriture ',OutName);
    Halt(1);
   End;
   Dec(Size,ToWrite);
  End;
  Cur:=NextCluster(Cur);
 End;
 Close(F);
 SetFileDate(OutName,T,D);
 Inc(FilesExtracted);
 If Verbose Then WriteLn(OutName);
End;

Procedure ProcessDir(StartCl:LongInt;Path:String;IsRoot:Boolean);Forward;

Procedure HandleEntry(Off:Integer;Path:String);
Var
 Attr:Byte;
 Name,OutName:String;
 Cl:LongInt;
 Size:LongInt;
 T,D:Word;
Begin
 If Not ValidDirEntry(Off)Then Exit;
 Inc(RootEntriesSeen);
 Attr:=Sec[Off+11];
 If(Attr and $0F)=$0F Then Exit;      { nom long VFAT }
 If(Attr and $08)<>0 Then Exit;       { volume label }
 Name:=EntryName(Off);
 If(Name='')or(Name='.')or(Name='..') Then Exit;
 Cl:=LE16(Off+26);
 If FATType=32 Then Cl:=Cl+(LongInt(LE16(Off+20))shl 16);
 Size:=LE32(Off+28);
 T:=LE16(Off+22);
 D:=LE16(Off+24);
 OutName:=JoinPath(Path,Name);
 If(Attr and $10)<>0 Then Begin
  MakePath(OutName);
  If Cl>=2 Then ProcessDir(Cl,OutName,False);
 End
  Else ExtractFile(Cl,Size,OutName,T,D);
End;

Procedure ProcessRoot(Path:String);
Var
 S:LongInt;
 I:Integer;
 Entry:LongInt;
 Done:Boolean;
Begin
 Done:=False;
 Entry:=0;
 For S:=0 to RootDirSectors-1 do Begin
  If Done Then Break;
  ReadSector(RootStart+S);
  For I:=0 to 15 do Begin
   If Entry>=RootEntries Then Begin Done:=True; Break; End;
   If Sec[I*32]=$00 Then Begin Done:=True; Break; End;
   HandleEntry(I*32,Path);
   ReadSector(RootStart+S);
   Inc(Entry);
  End;
 End;
End;

Procedure ProcessDir(StartCl:LongInt;Path:String;IsRoot:Boolean);
Var
 Cur:LongInt;
 S,I,J:LongInt;
 Done:Boolean;
Begin
 If IsRoot Then Begin
  ProcessRoot(Path);
  Exit;
 End;
 Cur:=StartCl;
 Done:=False;
 While(Cur>=2)and(Not IsEOC(Cur))and(Not Done)do Begin
  S:=ClusterSector(Cur);
  For I:=0 to SectorsPerCluster-1 do Begin
   If Done Then Break;
   ReadSector(S+I);
   For J:=0 to 15 do Begin
    If Sec[J*32]=$00 Then Begin Done:=True; Break; End;
    HandleEntry(J*32,Path);
    ReadSector(S+I);
   End;
  End;
  Cur:=NextCluster(Cur);
 End;
End;

Procedure Help;Begin
 WriteLn('UNDISKPC : Cette commande permet d''extraire les fichiers ',
         'd''une image disque PC (FAT12, FAT16, FAT32 ou HPFS).');
 WriteLn;
 WriteLn('Syntaxe : UNDISKPC image.img [destination] [/V]');
 WriteLn;
 WriteLn(' images.img     Ce paramŠtre permet d''indiquer l''image ',
         'disque (Brute IMG, TeleDisk (TD0,...), VirtualBox ou VMWare)');
 WriteLn(' destination    Ce paramŠtre permet d''indiquer le r‚pertoire cible');
 WriteLn(' /V             Mode verbeux : affiche chaque fichier extrait,');
 WriteLn('                le format d‚tect‚, les partitions, le BPB FAT et');
 WriteLn('                le dump diagnostique du r‚pertoire racine HPFS.');
 WriteLn;
 WriteLn('Supporte les images disquette FAT12 et les disques avec MBR/FAT.');
 WriteLn('Les noms longs VFAT sont ignor‚s; les noms 8.3 DOS sont utilis‚s.');
 WriteLn('Les partitions HPFS (OS/2, type $07) sont aussi extraites en ' +
   'lecture.');
End;

{ ===== Support HPFS (lecture seule) ===== }
{ Lit les fichiers d'une partition OS/2 HPFS (type $07 si la signature
  SuperBlock $F995E849 est presente au LBA partition+16). Ne supporte
  pas l'ecriture, les EA, ni les ACL. Les fichiers tres fragmentes
  (au-dela de MaxHPFSRuns runs apres expansion de l'arbre B+) sont
  tronques avec avertissement. }

Const
 MaxHPFSRuns=4096;

Type
 THPFSRun=Record
  DiskSec:LongInt;
  Length:LongInt;
 End;

Var
 HPFSPartLBA:LongInt;
 HPFSPartSize:LongInt;
 HPFSRuns:Array[0..MaxHPFSRuns-1]of THPFSRun;
 HPFSRunCount:Integer;
 HPFSRunOverflow:Boolean;
 HPFSProcessed:Boolean;
 HPFSDepth:Integer;

Procedure ReadSectorBuf(LBA:LongInt;Var Buf:TSector);
Var
 SaveSec:TSector;
Begin
 SaveSec:=Sec;
 ReadSector(LBA);
 Buf:=Sec;
 Sec:=SaveSec;
End;

Function GetLE32B(Var Buf;Off:LongInt):LongInt;
Var
 B:Array[0..16383]of Byte Absolute Buf;
Begin
 GetLE32B:=LongInt(B[Off])
   Or(LongInt(B[Off+1])Shl 8)
   Or(LongInt(B[Off+2])Shl 16)
   Or(LongInt(B[Off+3])Shl 24);
End;

Function GetLE16B(Var Buf;Off:LongInt):Word;
Var
 B:Array[0..16383]of Byte Absolute Buf;
Begin
 GetLE16B:=Word(B[Off])Or(Word(B[Off+1])Shl 8);
End;

Function HPFSScanForDirBlk(Var Buf;StartOff,EndOff:Integer):LongInt;
{ Cherche dans Buf[StartOff..EndOff] un U32 LE qui, interprete comme LBA
  partition-relatif, pointe vers un secteur ayant la signature DIRBLK
  (octets AE 0A E4 77). Scanne octet par octet. Retourne le LBA trouve ou 0. }
Var
 B:Array[0..16383]of Byte Absolute Buf;
 I:Integer;
 Cand:LongInt;
 SubSec:TSector;
Begin
 HPFSScanForDirBlk:=0;
 I:=StartOff;
 While I<=EndOff-3 do Begin
  Cand:=LongInt(B[I])Or(LongInt(B[I+1])Shl 8)
       Or(LongInt(B[I+2])Shl 16)Or(LongInt(B[I+3])Shl 24);
  If(Cand>0)And(Cand<HPFSPartSize)Then Begin
   ReadSectorBuf(HPFSPartLBA+Cand,SubSec);
   If(SubSec[0]=$AE)And(SubSec[1]=$0A)And
     (SubSec[2]=$E4)And(SubSec[3]=$77)Then Begin
    HPFSScanForDirBlk:=Cand;
    Exit;
   End;
  End;
  Inc(I);
 End;
End;

Procedure HPFSAddAllocBplus(Var Buf;HdrOff:Integer);
{ Analyse un en-tete B+tree d'allocation HPFS a HdrOff dans Buf.
  En-tete bplus (8 oct) : flags:u8, fill[3]:u8, n_free:u8, n_used:u8,
  first_free:u16. Entrees a HdrOff+8.
  Feuille (alleaf, 12 oct) : file_secno:u32, length:u32, disk_secno:u32.
  Interne (alnode, 8 oct)  : file_secno:u32, down:u32 vers ALSEC
  (magic $37E40AAE) dont l'en-tete bplus est a l'offset 12. }
Var
 B:Array[0..16383]of Byte Absolute Buf;
 Flags:Byte;
 NUsed:Integer;
 EntryOff,I,EntLen:Integer;
 IsLeaf:Boolean;
 RunLen,RunDisk,DownLBA:LongInt;
 SubSec:TSector;
Begin
 Flags:=B[HdrOff];
 IsLeaf:=(Flags And $80)=0;
 NUsed:=B[HdrOff+5];
 If NUsed>100 Then NUsed:=100;
 If IsLeaf Then EntLen:=12 Else EntLen:=8;
 EntryOff:=HdrOff+8;
 For I:=0 to NUsed-1 do
  If IsLeaf Then Begin
   RunLen:=GetLE32B(Buf,EntryOff+I*EntLen+4);
   RunDisk:=GetLE32B(Buf,EntryOff+I*EntLen+8);
   If RunLen>0 Then Begin
    If HPFSRunCount<MaxHPFSRuns Then Begin
     HPFSRuns[HPFSRunCount].DiskSec:=RunDisk;
     HPFSRuns[HPFSRunCount].Length:=RunLen;
     Inc(HPFSRunCount);
    End
     Else HPFSRunOverflow:=True;
   End;
  End
  Else Begin
   DownLBA:=GetLE32B(Buf,EntryOff+I*EntLen+4);
   If DownLBA>0 Then Begin
    ReadSectorBuf(HPFSPartLBA+DownLBA,SubSec);
    If(SubSec[0]=$AE)And(SubSec[1]=$0A)And(SubSec[2]=$E4)And(SubSec[3]=$37)Then
     HPFSAddAllocBplus(SubSec,12);
   End;
  End;
End;

Function SanitizeHPFSName(N:String):String;
Var
 I:Integer;
 R:String;
 C:Char;
 HasNonSpace:Boolean;
Begin
 R:='';
 HasNonSpace:=False;
 For I:=1 to Length(N)do Begin
  C:=N[I];
  Case C Of
   '\','/',':','*','?','"','<','>','|':C:='_';
  End;
  If Ord(C)<32 Then C:='_';
  If(C<>' ')And(C<>'_')Then HasNonSpace:=True;
  If Length(R)<200 Then R:=R+C;
 End;
 While(Length(R)>0)And(R[Length(R)]=' ')do Dec(R[0]);
 If Not HasNonSpace Then R:='';
 SanitizeHPFSName:=R;
End;

Procedure HPFSExtractFile(FNodeLBA,Size:LongInt;OutName:String);
Var
 FNodeBuf:TSector;
 SecBuf:TSector;
 F:File;
 RunI:Integer;
 SecLeft,ChunkStart,BytesWritten:LongInt;
 ToWrite:Word;
 W:Word;
 IoErr:Integer;
Begin
 ReadSectorBuf(HPFSPartLBA+FNodeLBA,FNodeBuf);
 If(FNodeBuf[0]<>$AE)Or(FNodeBuf[1]<>$0A)Or
   (FNodeBuf[2]<>$E4)Or(FNodeBuf[3]<>$F7)Then Begin
  Exit;
 End;
 HPFSRunCount:=0;
 HPFSRunOverflow:=False;
 HPFSAddAllocBplus(FNodeBuf,56);
 Assign(F,OutName);
 {$I-}Rewrite(F,1);{$I+}
 IoErr:=IoResult;
 If IoErr<>0 Then Begin
  WriteLn('Creation impossible: ',OutName);
  Exit;
 End;
 BytesWritten:=0;
 RunI:=0;
 While(RunI<HPFSRunCount)And(BytesWritten<Size)do Begin
  ChunkStart:=HPFSRuns[RunI].DiskSec;
  SecLeft:=HPFSRuns[RunI].Length;
  While(SecLeft>0)And(BytesWritten<Size)do Begin
   ReadSectorBuf(HPFSPartLBA+ChunkStart,SecBuf);
   If Size-BytesWritten>512 Then ToWrite:=512
                            Else ToWrite:=Size-BytesWritten;
   BlockWrite(F,SecBuf,ToWrite,W);
   Inc(BytesWritten,W);
   Inc(ChunkStart);
   Dec(SecLeft);
  End;
  Inc(RunI);
 End;
 Close(F);
 If HPFSRunOverflow Then
  WriteLn('Avert: ',OutName,' depasse ',MaxHPFSRuns,
    ' runs (peut etre tronque).');
 Inc(FilesExtracted);
 If Verbose Then WriteLn(OutName);
End;

Procedure HPFSProcessDirBlk(DirBlkLBA:LongInt;Path:String);Forward;

Procedure HPFSProcessDirFNode(FNodeLBA:LongInt;Path:String);
Var
 FBuf:TSector;
 FirstRun:LongInt;
Begin
 ReadSectorBuf(HPFSPartLBA+FNodeLBA,FBuf);
 If(FBuf[0]<>$AE)Or(FBuf[1]<>$0A)Or(FBuf[2]<>$E4)Or(FBuf[3]<>$F7)Then Exit;
 FirstRun:=HPFSScanForDirBlk(FBuf,55,200);
 If FirstRun=0 Then Exit;
 HPFSProcessDirBlk(FirstRun,Path);
End;

Procedure HPFSProcessDirBlk(DirBlkLBA:LongInt;Path:String);
Var
 DBuf:Array[0..2047]of Byte;
 Sec1:TSector;
 I,J:Integer;
 Off:LongInt;
 RecLen:Word;
 Flags1,Attr:Byte;
 FNodeLBA,DownLBA,FSize:LongInt;
 NameLen:Byte;
 Name,SafeName,FullPath:String;
 IsDir,IsSpecial,HasDown,IsLast:Boolean;
Begin
 If HPFSDepth>32 Then Exit;
 Inc(HPFSDepth);
 For I:=0 to 3 do Begin
  ReadSectorBuf(HPFSPartLBA+DirBlkLBA+I,Sec1);
  Move(Sec1,DBuf[I*512],512);
 End;
 If(DBuf[0]<>$AE)Or(DBuf[1]<>$0A)Or(DBuf[2]<>$E4)Or(DBuf[3]<>$77)Then Begin
  If Verbose Then WriteLn('DIRBLK invalide @',DirBlkLBA);
  Dec(HPFSDepth);
  Exit;
 End;
 If Verbose And(HPFSDepth=1)Then Begin
  WriteLn('DIRBLK @',DirBlkLBA,' (premier 256 oct) :');
  For I:=0 to 15 do Begin
   Write('  ',I*16:3,': ');
   For J:=0 to 15 do Write(HexByte(DBuf[I*16+J]),' ');
   Write(' | ');
   For J:=0 to 15 do
    If(DBuf[I*16+J]>=32)And(DBuf[I*16+J]<127)Then Write(Chr(DBuf[I*16+J]))
                                                Else Write('.');
   WriteLn;
  End;
 End;
 Off:=20;
 While Off<2040 do Begin
  RecLen:=GetLE16B(DBuf,Off);
  If(RecLen<32)Or(LongInt(Off)+LongInt(RecLen)>2048)Then Begin
   Dec(HPFSDepth); Exit;
  End;
  Flags1:=DBuf[Off+2];
  Attr:=DBuf[Off+3];
  FNodeLBA:=GetLE32B(DBuf,Off+4);
  FSize:=GetLE32B(DBuf,Off+12);
  NameLen:=DBuf[Off+30];
  IsSpecial:=(Flags1 And $01)<>0;
  IsDir:=(Attr And $10)<>0;
  HasDown:=(Flags1 And $04)<>0;
  IsLast:=(Flags1 And $08)<>0;
  If(Not IsSpecial)And(NameLen>0)And(NameLen<=200)Then Begin
   Name:='';
   For J:=0 to NameLen-1 do
    If Off+31+J<2048 Then Name:=Name+Chr(DBuf[Off+31+J]);
   SafeName:=SanitizeHPFSName(Name);
   If(Name<>'')And(SafeName<>'')And(SafeName<>'.')And(SafeName<>'..')And
     (FNodeLBA>0)And(FNodeLBA<HPFSPartSize)Then Begin
    FullPath:=JoinPath(Path,SafeName);
    If IsDir Then Begin
     MakePath(FullPath);
     HPFSProcessDirFNode(FNodeLBA,FullPath);
    End
     Else HPFSExtractFile(FNodeLBA,FSize,FullPath);
   End;
  End;
  If HasDown Then Begin
   DownLBA:=GetLE32B(DBuf,Off+RecLen-4);
   If(DownLBA>0)And(DownLBA<>DirBlkLBA)And(DownLBA<HPFSPartSize)Then
    HPFSProcessDirBlk(DownLBA,Path);
  End;
  If IsLast Then Begin Dec(HPFSDepth); Exit; End;
  Inc(Off,RecLen);
 End;
 Dec(HPFSDepth);
End;

Function IsHPFSVolume(PartLBA:LongInt):Boolean;
Var
 SBBuf:TSector;
Begin
 ReadSectorBuf(PartLBA+16,SBBuf);
 IsHPFSVolume:=(SBBuf[0]=$49)And(SBBuf[1]=$E8)And
               (SBBuf[2]=$95)And(SBBuf[3]=$F9);
End;

Procedure ExtractHPFSVolume(PartLBA:LongInt;DestPath:String);
Var
 SBBuf:TSector;
 RootFNode:LongInt;
Begin
 HPFSPartLBA:=PartLBA;
 HPFSProcessed:=True;
 ReadSectorBuf(PartLBA+16,SBBuf);
 If(SBBuf[0]<>$49)Or(SBBuf[1]<>$E8)Or
   (SBBuf[2]<>$95)Or(SBBuf[3]<>$F9)Then Begin
  WriteLn('SuperBlock HPFS introuvable a LBA=',PartLBA+16);
  Exit;
 End;
 RootFNode:=GetLE32B(SBBuf,12);
 If Verbose Then
  WriteLn('Volume HPFS (Root FNode LBA partition-relatif=',RootFNode,').');
 MakePath(DestPath);
 HPFSProcessDirFNode(RootFNode,DestPath);
End;

Procedure ExtractCurrentVolume(Path:String);
Begin
 MakePath(Path);
 If FATType=32 Then ProcessDir(RootCluster,Path,False)
               Else ProcessDir(0,Path,True);
End;

Procedure ExtractHardDiskImage;
Var
 I,O:Integer;
 PType:Array[0..3]of Byte;
 PLBA,PSZ:Array[0..3]of LongInt;
 PartPath:String;
 S:String;
 Any:Boolean;

 Procedure ExtractPartition(N:Integer;LBA,SZ:LongInt;T:Byte);
 Begin
  Str(N,S);
  PartPath:=JoinPath(DestDir,'PART'+S);
  If Verbose Then
   WriteLn('Partition ',N,' type=$',HexByte(T),' LBA=',LBA,' secteurs=',SZ);
  If IsHPFSPartitionType(T)And IsHPFSVolume(LBA)Then Begin
   HPFSPartSize:=SZ;
   ExtractHPFSVolume(LBA,PartPath);
   Exit;
  End;
  ReadBootAt(LBA);
  ExtractCurrentVolume(PartPath);
 End;

 Procedure ProcessExtended(ExtBase:LongInt;Var NextNo:Integer);
 Var
  EBR:LongInt;
  T1,T2:Byte;
  L1,S1,L2,S2:LongInt;
  Guard:Integer;
 Begin
  EBR:=ExtBase;
  Guard:=0;
  While(EBR>0)and(Guard<128)do Begin
   Inc(Guard);
   ReadSector(EBR);
   If(Sec[510]<>$55)or(Sec[511]<>$AA)Then Exit;
   T1:=Sec[446+4];
   L1:=LE32(446+8);
   S1:=LE32(446+12);
   If IsFATPartitionType(T1)and(S1>0)Then Begin
    ExtractPartition(NextNo,EBR+L1,S1,T1);
    Inc(NextNo);
    Any:=True;
   End
    Else If IsHPFSPartitionType(T1)and(S1>0)And IsHPFSVolume(EBR+L1)Then Begin
    ExtractPartition(NextNo,EBR+L1,S1,T1);
    Inc(NextNo);
    Any:=True;
   End;
   T2:=Sec[446+16+4];
   L2:=LE32(446+16+8);
   S2:=LE32(446+16+12);
   If IsExtendedPartitionType(T2)and(S2>0)Then EBR:=ExtBase+L2
    Else EBR:=0;
  End;
 End;

Var
 NextNo:Integer;
Begin
 ReadSector(0);
 If(Sec[510]<>$55)or(Sec[511]<>$AA)Then Begin
  WriteLn('MBR invalide.');
  Halt(1);
 End;
 For I:=0 to 3 do Begin
  O:=446+I*16;
  PType[I]:=Sec[O+4];
  PLBA[I]:=LE32(O+8);
  PSZ[I]:=LE32(O+12);
 End;
 Any:=False;
 NextNo:=1;
 For I:=0 to 3 do Begin
  If IsFATPartitionType(PType[I])and(PLBA[I]>0)and(PSZ[I]>0)Then Begin
   Any:=True;
   ExtractPartition(NextNo,PLBA[I],PSZ[I],PType[I]);
   Inc(NextNo);
  End
   Else If IsHPFSPartitionType(PType[I])and(PLBA[I]>0)and(PSZ[I]>0)
                                       And IsHPFSVolume(PLBA[I])Then Begin
   Any:=True;
   ExtractPartition(NextNo,PLBA[I],PSZ[I],PType[I]);
   Inc(NextNo);
  End
   Else If IsExtendedPartitionType(PType[I])and(PLBA[I]>0)and(PSZ[I]>0)Then
     Begin
   ProcessExtended(PLBA[I],NextNo);
  End;
 End;
 If Not Any Then Begin
  WriteLn('Aucune partition FAT primaire trouvee.');
  Halt(1);
 End;
End;

Begin
 Verbose:=False;
 ImgName:='';
 DestDir:='';
 For ArgIdx:=1 to ParamCount do Begin
  ArgStr:=ParamStr(ArgIdx);
  If(ArgStr='/?')or(ArgStr='-h')or(ArgStr='--help')Then Begin Help; Halt; End
   Else If(UpStr(ArgStr)='/V')or(UpStr(ArgStr)='-V')or
          (UpStr(ArgStr)='--VERBOSE')Then Verbose:=True
   Else If ImgName=''Then ImgName:=ArgStr
   Else If DestDir=''Then DestDir:=ArgStr;
 End;
 If ImgName=''Then Begin Help; Halt; End;
 If DestDir=''Then DestDir:=Path2Name(ImgName);
 Assign(Img,ImgName);
 FileMode:=0;
 {$I-}Reset(Img,1);{$I+}
 If IoResult<>0 Then Begin
  WriteLn('Impossible d''ouvrir ',ImgName);
  Halt(1);
 End;
 FilesExtracted:=0;
 DirsCreated:=0;
 RootEntriesSeen:=0;
 FATCachedLBA:=-1;
 TempImgName:='';
 HPFSProcessed:=False;
 HPFSDepth:=0;
 DetectImageFormat;
 If Verbose Then
  Case ImgKind Of
   1:WriteLn('Format detecte : VHD fixe (',VirtualSectors,
     ' secteurs virtuels).');
   2:WriteLn('Format detecte : VHD dynamique (',VirtualSectors,
     ' secteurs virtuels).');
   3:WriteLn('Format detecte : VMDK sparse (',VirtualSectors,
     ' secteurs virtuels).');
  End;
 MakePath(DestDir);
 ReadSector(0);
 IsHardDiskImage:=(VirtualSectors>16)and
  (Sec[510]=$55)and(Sec[511]=$AA)and(Not LooksLikeBPB);
 If IsHardDiskImage Then ExtractHardDiskImage
  Else Begin
  ReadBoot;
  ExtractCurrentVolume(DestDir);
 End;
 Close(Img);
 If FilesExtracted=0 Then Begin
  If HPFSProcessed Then Begin
   WriteLn('Aucun fichier trouve dans le(s) volume(s) HPFS.');
  End
   Else If RootEntriesSeen=0 Then Begin
   WriteLn('Aucun fichier trouve dans le repertoire racine FAT.');
   WriteLn('Note: le MBR/FDISK peut etre valide meme si la partition FAT est ' +
     'vide.');
   WriteLn('Racine LBA=',RootStart,'  FAT LBA=',FATStart,
    '  donnees LBA=',DataStart);
  End
   Else
  WriteLn('Entrees trouvees dans la racine, mais aucun fichier regulier ' +
    'extrait.');
 End;
 WriteLn(FilesExtracted,' fichier(s) extrait(s), ',
  DirsCreated,' repertoire(s) cree(s).');
 If TempImgName<>'' Then Begin
  Assign(Img,TempImgName);
  {$I-}Erase(Img);{$I+}
  If IoResult<>0 Then;
 End;
End.
