{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/corail)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program DISKPC;

{$A-}
{$R-}
{$M 65520,0,655360}

Uses DOS;

Const
 SectorSize=512;

Type
 TSector=Array[0..SectorSize-1]of Byte;

Var
 Img:File;
 ImgName:String;
 Sec:TSector;
 BytesPerSector:Word;
 SectorsPerCluster:Byte;
 ReservedSectors:Word;
 NumFATs:Byte;
 RootEntries:Word;
 TotalSectors:LongInt;
 SectorsPerFAT:LongInt;
 PartitionStart:LongInt;
 FATStart,RootStart,DataStart:LongInt;
 RootDirSectors:LongInt;
 ClusterCount:LongInt;
 FATType:Integer;
 RootCluster:LongInt;
 BPBOffset:Integer;
 { Support VHD/VMDK. ImgKind : 0=raw, 1=VHD fixe, 2=VHD dynamique,
   3=VMDK sparse. Pour 2/3 : VHDBlockSizeSec = secteurs par bloc/grain,
   VHDBitmapSecs = secteurs de bitmap precedant chaque bloc (VHD seulement),
   VHDBATFileOfs = offset dans le fichier de la BAT (ou GD pour VMDK),
   VMDKGTEsPerGT = entrees par grain-table (VMDK).
   VirtDiskSec = nombre total de secteurs virtuels. }
 ImgKind:Byte;
 VirtDiskSec:LongInt;
 VHDBlockSizeSec:LongInt;
 VHDBitmapSecs:LongInt;
 VHDBATFileOfs:LongInt;
 VMDKGTEsPerGT:LongInt;
 FATCachedLBA:LongInt;
 FATCachedBuf:TSector;

Function UpStr(S:String):String;
Var
 I:Integer;
Begin
 For I:=1 to Length(S)do
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 UpStr:=S;
End;

Function BaseName(S:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(S,D,N,E);
 BaseName:=N+E;
End;

Function LE16(Off:Integer):Word;
Begin
 LE16:=Word(Sec[Off])or(Word(Sec[Off+1])shl 8);
End;

Function LE32(Off:Integer):LongInt;
Begin
 LE32:=LongInt(Sec[Off])+
       LongInt(Sec[Off+1])*256+
       LongInt(Sec[Off+2])*65536+
       LongInt(Sec[Off+3])*16777216;
End;

Procedure PutLE16(Off:Integer;V:Word);
Begin
 Sec[Off]:=Byte(V and $FF);
 Sec[Off+1]:=Byte((V shr 8)and $FF);
End;

Procedure PutLE32(Off:Integer;V:LongInt);
Begin
 Sec[Off]:=Byte(V and $FF);
 Sec[Off+1]:=Byte((V shr 8)and $FF);
 Sec[Off+2]:=Byte((V shr 16)and $FF);
 Sec[Off+3]:=Byte((V shr 24)and $FF);
End;

Procedure ReadSector(LBA:LongInt);
Var
 R:Word;
 Ofs,BlockIdx,OfsInBlock,BATEntry,GrainNum,GTIdx,GTOff,GTSec,GrainSec:LongInt;
 Buf4:Array[0..3]of Byte;
Begin
 If(ImgKind=0)or(ImgKind=1)Then Ofs:=LBA*SectorSize Else
 If ImgKind=2 Then Begin
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

Function LBAToFileOfs(LBA:LongInt):LongInt;
Var
 R:Word;
 BlockIdx,OfsInBlock,BATEntry,GrainNum,GTIdx,GTOff,GTSec,GrainSec:LongInt;
 Buf4:Array[0..3]of Byte;
Begin
 LBAToFileOfs:=-1;
 If(ImgKind=0)or(ImgKind=1)Then Begin
  LBAToFileOfs:=LBA*SectorSize;
  Exit;
 End;
 If ImgKind=2 Then Begin
  BlockIdx:=LBA Div VHDBlockSizeSec;
  OfsInBlock:=LBA Mod VHDBlockSizeSec;
  Seek(Img,VHDBATFileOfs+BlockIdx*4);
  BlockRead(Img,Buf4,4,R);
  If R<>4 Then Exit;
  BATEntry:=(LongInt(Buf4[0])Shl 24)Or(LongInt(Buf4[1])Shl 16)
           Or(LongInt(Buf4[2])Shl 8)Or LongInt(Buf4[3]);
  If BATEntry=-1 Then Exit;
  LBAToFileOfs:=(BATEntry+VHDBitmapSecs)*512+OfsInBlock*512;
  Exit;
 End;
 If ImgKind=3 Then Begin
  GrainNum:=LBA Div VHDBlockSizeSec;
  GTIdx:=GrainNum Div VMDKGTEsPerGT;
  GTOff:=GrainNum Mod VMDKGTEsPerGT;
  OfsInBlock:=LBA Mod VHDBlockSizeSec;
  Seek(Img,VHDBATFileOfs+GTIdx*4);
  BlockRead(Img,Buf4,4,R);
  If R<>4 Then Exit;
  GTSec:=LongInt(Buf4[0])Or(LongInt(Buf4[1])Shl 8)
        Or(LongInt(Buf4[2])Shl 16)Or(LongInt(Buf4[3])Shl 24);
  If GTSec=0 Then Exit;
  Seek(Img,GTSec*512+GTOff*4);
  BlockRead(Img,Buf4,4,R);
  If R<>4 Then Exit;
  GrainSec:=LongInt(Buf4[0])Or(LongInt(Buf4[1])Shl 8)
        Or(LongInt(Buf4[2])Shl 16)Or(LongInt(Buf4[3])Shl 24);
  If GrainSec=0 Then Exit;
  LBAToFileOfs:=GrainSec*512+OfsInBlock*512;
 End;
End;

Procedure WriteSector(LBA:LongInt);
Var
 W:Word;
 Ofs:LongInt;
Begin
 Ofs:=LBAToFileOfs(LBA);
 If Ofs<0 Then Begin
  WriteLn('Ecriture impossible : bloc non alloue dans l''image ',
          'VHD dynamique/VMDK sparse (LBA ',LBA,').');
  WriteLn('Cette commande supporte les ecritures sur images brutes ',
          'et VHD fixes uniquement.');
  Halt(1);
 End;
 Seek(Img,Ofs);
 BlockWrite(Img,Sec,SectorSize,W);
 If W<>SectorSize Then Begin
  WriteLn('Ecriture secteur impossible: ',LBA);
  Halt(1);
 End;
End;

Function VirtualSectors:LongInt;
Begin
 If VirtDiskSec>0 Then VirtualSectors:=VirtDiskSec
                  Else VirtualSectors:=FileSize(Img)div SectorSize;
End;

Procedure DecodeTeleDisk;
{ Decode une image TeleDisk *.TD0 non compressee (signature 'TD' en
  majuscules) vers un fichier brut <image>.tdraw, puis rouvre Img sur
  ce fichier. Comme DISKPC modifie l'image, le .tdraw est conserve
  apres execution (l'original .TD0 reste intact). }
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
 I,K:Integer;
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
   If(SecID<1)or(SecID>63)or((Flags and $40)<>0)Then Continue;
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
 WriteLn('Format TeleDisk decode vers ',NewName,' (image .TD0 inchangee).');
 ImgName:=NewName;
 Assign(Img,ImgName);
 {$I-}Reset(Img,1);{$I+}
 If IoResult<>0 Then Begin
  WriteLn('Impossible de rouvrir le fichier decode ',ImgName);
  Halt(1);
 End;
End;

Procedure DetectImageFormat;
Var
 Raw:TSector;
 R:Word;
 FSize,FtrOfs,DT,CurSz:LongInt;
 HdrOfs,BAToff,BlockSz:LongInt;
 Capacity,GrainSize,GDOffset,NumGTEs:LongInt;
 I,J,K:LongInt;
 S,Line,FlatName,Token:String;
 FlatOfs:LongInt;
 ValCode:Integer;
 Ch:Char;
 NewName:String;

 Function ReadLE32At(Pos:LongInt):LongInt;
 Var
  Buf:Array[0..3]of Byte;
  RR:Word;
 Begin
  Seek(Img,Pos);
  BlockRead(Img,Buf,4,RR);
  ReadLE32At:=LongInt(Buf[0])Or(LongInt(Buf[1])Shl 8)
             Or(LongInt(Buf[2])Shl 16)Or(LongInt(Buf[3])Shl 24);
 End;

Begin
 ImgKind:=0;
 VirtDiskSec:=0;
 FSize:=FileSize(Img);
 If FSize<512 Then Exit;
 Seek(Img,0);
 BlockRead(Img,Raw,SectorSize,R);
 If R<512 Then Begin
  { Tres petit fichier : essayons quand meme texte descriptor }
 End;
 { TeleDisk : signature 'TD' ou 'td' a l'offset 0 }
 If((Raw[0]=Ord('T'))and(Raw[1]=Ord('D')))or
   ((Raw[0]=Ord('t'))and(Raw[1]=Ord('d')))Then Begin
  DecodeTeleDisk;
  Exit;
 End;
 { VMDK sparse : 'KDMV' a l'offset 0 }
 If(Raw[0]=$4B)and(Raw[1]=$44)and(Raw[2]=$4D)and(Raw[3]=$56)Then Begin
  Capacity:=ReadLE32At(12);
  GrainSize:=ReadLE32At(20);
  GDOffset:=ReadLE32At(56);
  NumGTEs:=ReadLE32At(44);
  If(GrainSize>0)and(NumGTEs>0)and(GDOffset>0)Then Begin
   ImgKind:=3;
   VirtDiskSec:=Capacity;
   VHDBlockSizeSec:=GrainSize;
   VMDKGTEsPerGT:=NumGTEs;
   VHDBATFileOfs:=GDOffset*512;
   WriteLn('Format detecte : VMDK sparse (',VirtDiskSec,' secteurs virtuels).');
   Exit;
  End;
 End;
 { VMDK descriptor texte }
 S:='';
 For I:=0 to 511 do
  If Raw[I]<>0 Then S:=S+Chr(Raw[I]);
 If(Pos('# Disk DescriptorFile',S)>0)or(Pos('createType=',S)>0)or
   (Pos('# Disk Descriptor',S)>0)Then Begin
  { Cherche ligne 'RW <N> FLAT "name" <offset>' }
  I:=Pos(' FLAT ',S);
  If I>0 Then Begin
   J:=I;
   While(J>1)and(S[J]<>Chr(10))and(S[J]<>Chr(13))do Dec(J);
   K:=I;
   While(K<=Length(S))and(S[K]<>Chr(10))and(S[K]<>Chr(13))do Inc(K);
   Line:=Copy(S,J+1,K-J-1);
   I:=Pos('"',Line);
   If I>0 Then Begin
    J:=Pos('"',Copy(Line,I+1,Length(Line)));
    If J>0 Then Begin
     FlatName:=Copy(Line,I+1,J-1);
     Token:='';
     K:=I+J+1;
     While(K<=Length(Line))and(Line[K]=' ')do Inc(K);
     While(K<=Length(Line))and(Line[K]<>' ')and
          (Line[K]<>Chr(13))and(Line[K]<>Chr(10))do Begin
      Token:=Token+Line[K];
      Inc(K);
     End;
     Val(Token,FlatOfs,ValCode);
     If ValCode<>0 Then FlatOfs:=0;
     { Reouverture sur le fichier flat }
     Close(Img);
     NewName:=FlatName;
     { Si chemin relatif, prefixer avec repertoire de l'image }
     If(Pos(':',NewName)=0)and(NewName<>'')and
       (NewName[1]<>'\')and(NewName[1]<>'/')Then Begin
      I:=Length(ImgName);
      While(I>0)and(ImgName[I]<>'\')and(ImgName[I]<>'/')do Dec(I);
      If I>0 Then NewName:=Copy(ImgName,1,I)+FlatName;
     End;
     WriteLn('VMDK descripteur : redirige vers ',NewName);
     Assign(Img,NewName);
     {$I-}Reset(Img,1);{$I+}
     If IoResult<>0 Then Begin
      WriteLn('Impossible d''ouvrir le fichier flat ',NewName);
      Halt(1);
     End;
     ImgName:=NewName;
     DetectImageFormat;
     Exit;
    End;
   End;
  End;
 End;
 { VHD footer (512 derniers octets) }
 If FSize>=1024 Then Begin
  FtrOfs:=FSize-512;
  Seek(Img,FtrOfs);
  BlockRead(Img,Raw,512,R);
  If(R=512)and(Raw[0]=$63)and(Raw[1]=$6F)and(Raw[2]=$6E)and
    (Raw[3]=$65)and(Raw[4]=$63)and(Raw[5]=$74)and(Raw[6]=$69)and
    (Raw[7]=$78)Then Begin
   { Big-endian : DiskType @60, CurrentSize @48 }
   DT:=(LongInt(Raw[60])Shl 24)Or(LongInt(Raw[61])Shl 16)
       Or(LongInt(Raw[62])Shl 8)Or LongInt(Raw[63]);
   CurSz:=(LongInt(Raw[48])Shl 24)Or(LongInt(Raw[49])Shl 16)
         Or(LongInt(Raw[50])Shl 8)Or LongInt(Raw[51]);
   { Note: CurSz est sur 8 octets (40..47=high, 48..55=low). On suppose
     que la partie haute est nulle pour les disques <4Go. Pour les
     disques plus grands, on calcule depuis FSize. }
   If CurSz<=0 Then CurSz:=(FSize-512);
   VirtDiskSec:=CurSz Div 512;
   If DT=2 Then Begin
    ImgKind:=1;
    WriteLn('Format detecte : VHD fixe (',VirtDiskSec,' secteurs virtuels).');
    Exit;
   End;
   If(DT=3)or(DT=4)Then Begin
    { Dynamic. Lire entete dynamique (offset = LongLong @16 BE). }
    HdrOfs:=(LongInt(Raw[20])Shl 24)Or(LongInt(Raw[21])Shl 16)
           Or(LongInt(Raw[22])Shl 8)Or LongInt(Raw[23]);
    Seek(Img,HdrOfs);
    BlockRead(Img,Raw,512,R);
    If(R=512)and(Raw[0]=$63)and(Raw[1]=$78)and(Raw[2]=$73)and
      (Raw[3]=$70)and(Raw[4]=$61)and(Raw[5]=$72)and(Raw[6]=$73)and
      (Raw[7]=$65)Then Begin
     { BAT offset @16 BE (8 octets, partie basse @20) }
     BAToff:=(LongInt(Raw[20])Shl 24)Or(LongInt(Raw[21])Shl 16)
            Or(LongInt(Raw[22])Shl 8)Or LongInt(Raw[23]);
     BlockSz:=(LongInt(Raw[32])Shl 24)Or(LongInt(Raw[33])Shl 16)
             Or(LongInt(Raw[34])Shl 8)Or LongInt(Raw[35]);
     VHDBlockSizeSec:=BlockSz Div 512;
     VHDBATFileOfs:=BAToff;
     VHDBitmapSecs:=(VHDBlockSizeSec Div 4096);
     If VHDBitmapSecs<1 Then VHDBitmapSecs:=1;
     ImgKind:=2;
     WriteLn('Format detecte : VHD dynamique (',VirtDiskSec,
             ' secteurs virtuels).');
     Exit;
    End;
   End;
  End;
 End;
End;

Function LooksLikeBPB:Boolean;
Var
 BPS:Word;
 SPC:Byte;
 OK:Boolean;
Begin
 BPBOffset:=0;
 BPS:=LE16(11);
 SPC:=Sec[13];
 OK:=(BPS=512)and(SPC<>0)and(Sec[16]<>0)and
  (LE16(14)<>0)and((LE16(17)<>0)or((LE16(22)=0)and(LE32(36)<>0)));
 If OK Then Begin LooksLikeBPB:=True; Exit; End;
 BPS:=Word(Sec[12])or(Word(Sec[13])shl 8);
 SPC:=Sec[14];
 OK:=(BPS=512)and(SPC<>0)and(Sec[17]<>0)and
  ((Word(Sec[15])or(Word(Sec[16])shl 8))<>0);
 If OK Then BPBOffset:=1;
 LooksLikeBPB:=OK;
End;

Function IsFATPartitionType(T:Byte):Boolean;
Begin
 IsFATPartitionType:=T in[$01,$04,$06,$0B,$0C,$0E,$11,$14,$16,$1B,$1C,$1E];
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
 If(Sec[510]<>$55)or(Sec[511]<>$AA)Then Begin
  FindPartitionStart:=-1;
  Exit;
 End;
 For I:=0 to 3 do Begin
  O:=446+I*16;
  T:=Sec[O+4];
  LBA:=LE32(O+8);
  SZ:=LE32(O+12);
  If IsFATPartitionType(T)and(LBA>0)and(SZ>0)Then Begin
   FindPartitionStart:=LBA;
   Exit;
  End;
 End;
 WriteLn('Aucune partition FAT primaire trouvee.');
 Halt(1);
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
 WriteLn('FAT12 sans BPB standard, format deduit par taille.');
 InferFloppyBySize:=True;
End;

Procedure ReadBoot;
Var
 TS16:Word;
 TS32:LongInt;
 SPF16:Word;
Begin
 PartitionStart:=FindPartitionStart;
 If PartitionStart<0Then Begin
  If InferFloppyBySize Then Exit;
  WriteLn('Image PC invalide: ni FAT direct ni MBR.');
  Halt(1);
 End;
 ReadSector(PartitionStart);
 If Not LooksLikeBPB Then Begin
  WriteLn('Secteur de demarrage FAT invalide.');
  Halt(1);
 End;
 BytesPerSector:=Word(Sec[11+BPBOffset])or(Word(Sec[12+BPBOffset])shl 8);
 If BytesPerSector<>SectorSize Then Begin
  WriteLn('Seuls les secteurs de 512 octets sont supportes.');
  Halt(1);
 End;
 SectorsPerCluster:=Sec[13+BPBOffset];
 ReservedSectors:=Word(Sec[14+BPBOffset])or(Word(Sec[15+BPBOffset])shl 8);
 NumFATs:=Sec[16+BPBOffset];
 RootEntries:=Word(Sec[17+BPBOffset])or(Word(Sec[18+BPBOffset])shl 8);
 TS16:=Word(Sec[19+BPBOffset])or(Word(Sec[20+BPBOffset])shl 8);
 TS32:=LongInt(Sec[32+BPBOffset])+
       LongInt(Sec[33+BPBOffset])*256+
       LongInt(Sec[34+BPBOffset])*65536+
       LongInt(Sec[35+BPBOffset])*16777216;
 If TS16<>0Then TotalSectors:=TS16 Else TotalSectors:=TS32;
 SPF16:=Word(Sec[22+BPBOffset])or(Word(Sec[23+BPBOffset])shl 8);
 If SPF16<>0Then SectorsPerFAT:=SPF16
             Else SectorsPerFAT:=LongInt(Sec[36+BPBOffset])+
                LongInt(Sec[37+BPBOffset])*256+
                LongInt(Sec[38+BPBOffset])*65536+
                LongInt(Sec[39+BPBOffset])*16777216;
 If SectorsPerFAT=0Then Begin
  WriteLn('Taille FAT invalide.');
  Halt(1);
 End;
 If RootEntries=0Then RootCluster:=LongInt(Sec[44+BPBOffset])+
       LongInt(Sec[45+BPBOffset])*256+
       LongInt(Sec[46+BPBOffset])*65536+
       LongInt(Sec[47+BPBOffset])*16777216
 Else RootCluster:=0;
 RootDirSectors:=(LongInt(RootEntries)*32+SectorSize-1)div SectorSize;
 FATStart:=PartitionStart+ReservedSectors;
 RootStart:=FATStart+LongInt(NumFATs)*SectorsPerFAT;
 DataStart:=RootStart+RootDirSectors;
 ClusterCount:=(TotalSectors-(ReservedSectors+
  LongInt(NumFATs)*SectorsPerFAT+RootDirSectors))div SectorsPerCluster;
 If ClusterCount<4085Then FATType:=12
  Else If ClusterCount<65525Then FATType:=16
  Else FATType:=32;
 If(FATType=32)and(RootCluster<2)Then RootCluster:=2;
 WriteLn('FAT',FATType,'  cluster=',SectorsPerCluster,
  '  debut partition=',PartitionStart);
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
  SavedSec:=Sec;
  ReadSector(LBA);
  FATCachedBuf:=Sec;
  Sec:=SavedSec;
  FATCachedLBA:=LBA;
 End;
 FATByte:=FATCachedBuf[Within];
End;

Procedure SetFATByte(Offset:LongInt;B:Byte);
Var
 F:Integer;
 LBA:LongInt;
 Within:Word;
 SavedSec:TSector;
Begin
 Within:=Word(Offset Mod SectorSize);
 For F:=0 to NumFATs-1 do Begin
  LBA:=FATStart+LongInt(F)*SectorsPerFAT+(Offset Div SectorSize);
  SavedSec:=Sec;
  ReadSector(LBA);
  Sec[Within]:=B;
  WriteSector(LBA);
  If F=0 Then Begin
   FATCachedBuf:=Sec;
   FATCachedLBA:=LBA;
  End;
  Sec:=SavedSec;
 End;
End;

Function NextCluster(Cl:LongInt):LongInt;
Var
 O,V:LongInt;
Begin
 If FATType=12Then Begin
  O:=Cl+(Cl div 2);
  V:=LongInt(FATByte(O))or(LongInt(FATByte(O+1))shl 8);
  If(Cl and 1)<>0Then V:=V shr 4 Else V:=V and $0FFF;
  NextCluster:=V;
 End
  Else If FATType=16Then Begin
  O:=Cl*2;
  NextCluster:=LongInt(FATByte(O))or(LongInt(FATByte(O+1))shl 8);
 End
  Else Begin
  O:=Cl*4;
  V:=LongInt(FATByte(O))or(LongInt(FATByte(O+1))shl 8)or
    (LongInt(FATByte(O+2))shl 16)or(LongInt(FATByte(O+3))shl 24);
  NextCluster:=V and $0FFFFFFF;
 End;
End;

Function IsEOC(Cl:LongInt):Boolean;
Begin
 If FATType=12Then IsEOC:=Cl>=$0FF8
  Else If FATType=16Then IsEOC:=Cl>=$FFF8
  Else IsEOC:=Cl>=$0FFFFFF8;
End;

Procedure SetClusterValue(Cl,Val:LongInt);
Var
 O,V:LongInt;
Begin
 If FATType=12Then Begin
  O:=Cl+(Cl div 2);
  V:=LongInt(FATByte(O))or(LongInt(FATByte(O+1))shl 8);
  If(Cl and 1)<>0Then V:=(V and $000F)or((Val and $0FFF)shl 4)
                 Else V:=(V and $F000)or(Val and $0FFF);
  SetFATByte(O,Byte(V and $FF));
  SetFATByte(O+1,Byte((V shr 8)and $FF));
 End
  Else If FATType=16Then Begin
  O:=Cl*2;
  SetFATByte(O,Byte(Val and $FF));
  SetFATByte(O+1,Byte((Val shr 8)and $FF));
 End
  Else Begin
  O:=Cl*4;
  Val:=Val and $0FFFFFFF;
  SetFATByte(O,Byte(Val and $FF));
  SetFATByte(O+1,Byte((Val shr 8)and $FF));
  SetFATByte(O+2,Byte((Val shr 16)and $FF));
  SetFATByte(O+3,Byte((Val shr 24)and $0F));
 End;
End;

Function EOCValue:LongInt;
Begin
 If FATType=12Then EOCValue:=$0FFF
  Else If FATType=16Then EOCValue:=$FFFF
  Else EOCValue:=$0FFFFFFF;
End;

Function ClusterSector(Cl:LongInt):LongInt;
Begin
 ClusterSector:=DataStart+(Cl-2)*SectorsPerCluster;
End;

Function FindFreeCluster(Start:LongInt):LongInt;
Var
 C:LongInt;
Begin
 For C:=Start to ClusterCount+1 do
  If NextCluster(C)=0Then Begin
   FindFreeCluster:=C;
   Exit;
  End;
 FindFreeCluster:=0;
End;

Procedure ClearCluster(Cl:LongInt);
Var
 I:Integer;
Begin
 FillChar(Sec,SizeOf(Sec),0);
 For I:=0 to SectorsPerCluster-1 do WriteSector(ClusterSector(Cl)+I);
End;

Procedure CopyCluster(FromCl,ToCl:LongInt);
Var
 I:Integer;
Begin
 For I:=0 to SectorsPerCluster-1 do Begin
  ReadSector(ClusterSector(FromCl)+I);
  WriteSector(ClusterSector(ToCl)+I);
 End;
End;

Function EntryFirstCluster(Off:Integer):LongInt;
Var
 Cl:LongInt;
Begin
 Cl:=LongInt(LE16(Off+26));
 If FATType=32Then
  Cl:=Cl+LongInt(LE16(Off+20))*65536;
 EntryFirstCluster:=Cl;
End;

Procedure PutEntryFirstCluster(Off:Integer;Cl:LongInt);
Begin
 If FATType=32Then PutLE16(Off+20,Word((Cl shr 16)and $FFFF))
               Else PutLE16(Off+20,0);
 PutLE16(Off+26,Word(Cl and $FFFF));
End;

Function FindPredCluster(Target:LongInt):LongInt;
Var
 C:LongInt;
Begin
 For C:=2 to ClusterCount+1 do
  If NextCluster(C)=Target Then Begin
   FindPredCluster:=C;
   Exit;
  End;
 FindPredCluster:=0;
End;

Function UpdateDirChainReference(StartCl,Target,NewCl:LongInt):Boolean;Forward;

Function UpdateDirSectorReference(LBA,Target,NewCl:LongInt):Boolean;
Var
 I,O:Integer;
 A:Byte;
 FC:LongInt;
Begin
 UpdateDirSectorReference:=False;
 ReadSector(LBA);
 For I:=0 to 15 do Begin
  O:=I*32;
  If Sec[O]=0Then Continue;
  If Sec[O]=$E5Then Continue;
  A:=Sec[O+11];
  If(A and $0F)=$0FThen Continue;
  FC:=EntryFirstCluster(O);
  If FC=Target Then Begin
   PutEntryFirstCluster(O,NewCl);
   WriteSector(LBA);
   UpdateDirSectorReference:=True;
   Exit;
  End;
  If((A and $10)<>0)and(FC>=2)and(Sec[O]<>Ord('.'))Then Begin
   If UpdateDirChainReference(FC,Target,NewCl)Then Begin
    UpdateDirSectorReference:=True;
    Exit;
   End;
   ReadSector(LBA);
  End;
 End;
End;

Function UpdateDirChainReference(StartCl,Target,NewCl:LongInt):Boolean;
Var
 Cur,S,J:LongInt;
Begin
 UpdateDirChainReference:=False;
 Cur:=StartCl;
 While(Cur>=2)and(Not IsEOC(Cur))do Begin
  S:=ClusterSector(Cur);
  For J:=0 to SectorsPerCluster-1 do
   If UpdateDirSectorReference(S+J,Target,NewCl)Then Begin
    UpdateDirChainReference:=True;
    Exit;
   End;
  Cur:=NextCluster(Cur);
 End;
End;

Function UpdateDirReference(Target,NewCl:LongInt):Boolean;
Var
 S:LongInt;
Begin
 UpdateDirReference:=False;
 If FATType=32Then Begin
  UpdateDirReference:=UpdateDirChainReference(RootCluster,Target,NewCl);
  Exit;
 End;
 For S:=0 to RootDirSectors-1 do
  If UpdateDirSectorReference(RootStart+S,Target,NewCl)Then Begin
   UpdateDirReference:=True;
   Exit;
  End;
End;

Procedure RelocateCluster(Target,ReserveEnd:LongInt);
Var
 NewCl,Pred,Val:LongInt;
Begin
 Val:=NextCluster(Target);
 If Val=0 Then Exit;
 NewCl:=FindFreeCluster(ReserveEnd+1);
 If NewCl=0 Then Begin
  WriteLn('Espace insuffisant pour deplacer le cluster ',Target,'.');
  Halt(1);
 End;
 CopyCluster(Target,NewCl);
 SetClusterValue(NewCl,Val);
 Pred:=FindPredCluster(Target);
 If Pred<>0 Then SetClusterValue(Pred,NewCl)
 Else If Not UpdateDirReference(Target,NewCl)Then Begin
  SetClusterValue(NewCl,0);
  SetClusterValue(Target,0);
  WriteLn('Cluster ',Target,' alloue sans entree de repertoire, reutilise.');
  Exit;
 End;
 SetClusterValue(Target,0);
End;

Procedure ReserveSystemClusters(Need:LongInt);
Var
 C,ReserveEnd:LongInt;
Begin
 If Need<=0 Then Exit;
 If FATType=32 Then Begin
  WriteLn('/SYS est supporte seulement sur FAT12/FAT16.');
  Halt(1);
 End;
 If Need>ClusterCount Then Begin
  WriteLn('Fichier systeme trop grand pour cette image.');
  Halt(1);
 End;
 ReserveEnd:=Need+1;
 For C:=2 to ReserveEnd do RelocateCluster(C,ReserveEnd);
End;

Function ValidDOSChar(C:Char):Boolean;
Begin
 ValidDOSChar:=C in['A'..'Z','0'..'9','$','%','''','-','_','@','~','`','!','(',
   ')','{','}','^','#','&'];
End;

Procedure Make83(Source:String;Var Raw:Array of Byte);
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
 S:String;
 I,J:Integer;
 C:Char;
Begin
 FSplit(Source,D,N,E);
 N:=UpStr(N);
 E:=UpStr(E);
 If(Length(E)>0)and(E[1]='.')Then Delete(E,1,1);
 For I:=0 to 10 do Raw[I]:=32;
 J:=0;
 For I:=1 to Length(N)do Begin
  C:=N[I];
  If ValidDOSChar(C)Then Begin
   If J<8Then Begin Raw[J]:=Ord(C); Inc(J); End;
  End;
 End;
 J:=8;
 For I:=1 to Length(E)do Begin
  C:=E[I];
  If ValidDOSChar(C)Then Begin
   If J<11Then Begin Raw[J]:=Ord(C); Inc(J); End;
  End;
 End;
 If Raw[0]=32Then Begin
  S:='FILE';
  For I:=1 to Length(S)do Raw[I-1]:=Ord(S[I]);
 End;
End;

Function NameMatches(Off:Integer;Var Raw:Array of Byte):Boolean;
Var
 I:Integer;
Begin
 NameMatches:=True;
 For I:=0 to 10 do If Sec[Off+I]<>Raw[I]Then Begin
  NameMatches:=False;
  Exit;
 End;
End;

Function FindRootEntry(Var Raw:Array of Byte;Var EntrySector:LongInt;
  Var EntryOff:Integer):Boolean;
Var
 S,J:LongInt;
 Cur:LongInt;
 I:Integer;
Begin
 FindRootEntry:=False;
 If FATType=32Then Begin
  Cur:=RootCluster;
  While(Cur>=2)and(Not IsEOC(Cur))do Begin
   S:=ClusterSector(Cur);
   For J:=0 to SectorsPerCluster-1 do Begin
    ReadSector(S+J);
    For I:=0 to 15 do Begin
     If NameMatches(I*32,Raw)Then Begin
      WriteLn('Le fichier existe deja dans l''image.');
      Halt(1);
     End;
     If(Sec[I*32]=0)or(Sec[I*32]=$E5)Then Begin
      EntrySector:=S+J;
      EntryOff:=I*32;
      FindRootEntry:=True;
      Exit;
     End;
    End;
   End;
   Cur:=NextCluster(Cur);
  End;
 End
  Else Begin
  For S:=0 to RootDirSectors-1 do Begin
   ReadSector(RootStart+S);
   For I:=0 to 15 do Begin
    If NameMatches(I*32,Raw)Then Begin
     WriteLn('Le fichier existe deja dans l''image.');
     Halt(1);
    End;
    If(Sec[I*32]=0)or(Sec[I*32]=$E5)Then Begin
     EntrySector:=RootStart+S;
     EntryOff:=I*32;
     FindRootEntry:=True;
     Exit;
    End;
   End;
  End;
 End;
End;

Procedure WriteDirectoryEntry(EntrySector:LongInt;EntryOff:Integer;
 Var Raw:Array of Byte;FirstCluster:LongInt;Size:LongInt;Stamp:LongInt;
 Attr:Byte);
Var
 I:Integer;
 T,D:Word;
Begin
 ReadSector(EntrySector);
 For I:=0 to 31 do Sec[EntryOff+I]:=0;
 For I:=0 to 10 do Sec[EntryOff+I]:=Raw[I];
 Sec[EntryOff+11]:=Attr;
 T:=Word(Stamp and $FFFF);
 D:=Word((Stamp shr 16)and $FFFF);
 PutLE16(EntryOff+14,T);
 PutLE16(EntryOff+16,D);
 PutLE16(EntryOff+22,T);
 PutLE16(EntryOff+24,D);
 If FATType=32Then PutLE16(EntryOff+20,Word((FirstCluster shr 16)and $FFFF));
 PutLE16(EntryOff+26,Word(FirstCluster and $FFFF));
 PutLE32(EntryOff+28,Size);
 WriteSector(EntrySector);
End;

Procedure CopyFileToImage(SourceName:String;SysMode:Boolean);
Var
 Src:File;
 Raw:Array[0..10]of Byte;
 EntrySector:LongInt;
 EntryOff:Integer;
 Size,Remain,Need,ClusterBytes:LongInt;
 Cl,FirstCl,PrevCl,NextFree:LongInt;
 I:Integer;
 R:Word;
 Stamp:LongInt;
Begin
 Make83(BaseName(SourceName),Raw);
 If Not FindRootEntry(Raw,EntrySector,EntryOff)Then Begin
  WriteLn('Repertoire racine plein.');
  Halt(1);
 End;
 Assign(Src,SourceName);
 FileMode:=0;
 {$I-}Reset(Src,1);{$I+}
 If IoResult<>0Then Begin
  WriteLn('Impossible d''ouvrir ',SourceName);
  Halt(1);
 End;
 Size:=FileSize(Src);
 GetFTime(Src,Stamp);
 ClusterBytes:=LongInt(SectorsPerCluster)*SectorSize;
 Remain:=Size;
 FirstCl:=0;
 PrevCl:=0;
 If SysMode Then Begin
  Need:=(Size+ClusterBytes-1)div ClusterBytes;
  ReserveSystemClusters(Need);
  Cl:=2;
  While Remain>0 do Begin
   If FirstCl=0 Then FirstCl:=Cl;
   If Remain>ClusterBytes Then SetClusterValue(Cl,Cl+1)
    Else SetClusterValue(Cl,EOCValue);
   For I:=0 to SectorsPerCluster-1 do Begin
    FillChar(Sec,SizeOf(Sec),0);
    If Remain>0 Then Begin
     BlockRead(Src,Sec,SectorSize,R);
     Dec(Remain,R);
    End;
    WriteSector(ClusterSector(Cl)+I);
   End;
   Inc(Cl);
  End;
  If Size=0 Then FirstCl:=0;
  Close(Src);
  WriteDirectoryEntry(EntrySector,EntryOff,Raw,FirstCl,Size,Stamp,$27);
  WriteLn(SourceName,' -> image (/SYS)');
  Exit;
 End;
 NextFree:=2;
 While Remain>0 do Begin
  Cl:=FindFreeCluster(NextFree);
  If Cl=0Then Begin
   Close(Src);
   WriteLn('Espace insuffisant dans l''image.');
   Halt(1);
  End;
  NextFree:=Cl+1;
  If FirstCl=0Then FirstCl:=Cl;
  If PrevCl<>0Then SetClusterValue(PrevCl,Cl);
  SetClusterValue(Cl,EOCValue);
  For I:=0 to SectorsPerCluster-1 do Begin
   FillChar(Sec,SizeOf(Sec),0);
   If Remain>0Then Begin
    BlockRead(Src,Sec,SectorSize,R);
    Dec(Remain,R);
   End;
   WriteSector(ClusterSector(Cl)+I);
  End;
  PrevCl:=Cl;
 End;
 Close(Src);
 If Size=0Then FirstCl:=0;
 WriteDirectoryEntry(EntrySector,EntryOff,Raw,FirstCl,Size,Stamp,$20);
 WriteLn(SourceName,' -> image');
End;

Procedure Help;Begin
 WriteLn('DISKPC : Cette commande permet de copier des fichiers ',
         'dans une image disque PC FAT.');
 WriteLn;
 WriteLn('Syntaxe : DISKPC image.img fichier1 [fichier2 ...] [/SYS:fichier]');
 WriteLn;
 WriteLn('Ajoute les fichiers dans la racine de la premiere partition FAT.');
 WriteLn('/SYS:fichier place un fichier systeme au debut de la zone donnees');
 WriteLn('FAT12/FAT16 et deplace les clusters occupes si necessaire.');
 WriteLn('Supporte FAT12, FAT16 et FAT32. Noms longs VFAT non crees.');
End;

Function IsSysParam(S:String):Boolean;
Var
 U:String;
Begin
 U:=UpStr(S);
 IsSysParam:=(Copy(U,1,5)='/SYS:')or(Copy(U,1,5)='-SYS:');
End;

Function HasWildcard(S:String):Boolean;
Var
 I:Integer;
Begin
 HasWildcard:=False;
 For I:=1 to Length(S)do
  If(S[I]='*')or(S[I]='?')Then Begin
   HasWildcard:=True;
   Exit;
  End;
End;

Procedure ExpandAndCopy(Pattern:String;SysMode:Boolean);
Var
 SR:SearchRec;
 Dir:String;
 I:Integer;
 FullName:String;
 Found:Boolean;
Begin
 Dir:='';
 For I:=Length(Pattern)downto 1 do
  If(Pattern[I]='\')or(Pattern[I]='/')or(Pattern[I]=':')Then Begin
   Dir:=Copy(Pattern,1,I);
   Break;
  End;
 Found:=False;
 FindFirst(Pattern,AnyFile,SR);
 While DosError=0 do Begin
  If(SR.Attr and Directory)=0 Then Begin
   FullName:=Dir+SR.Name;
   CopyFileToImage(FullName,SysMode);
   Found:=True;
   If SysMode Then Begin
    {$IFDEF FPC}
     FindClose(SR);
    {$ENDIF}
    Exit;
   End;
  End;
  FindNext(SR);
 End;
 {$IFDEF FPC}
 FindClose(SR);
 {$ENDIF}
 If Not Found Then Begin
  WriteLn('Aucun fichier ne correspond a ',Pattern);
  Halt(1);
 End;
End;

Var
 I:Integer;
 P:String;
 SysSeen:Boolean;
Begin
 If(ParamCount<2)or(ParamStr(1)='/?')or(ParamStr(1)='-h')or
   (ParamStr(1)='--help')Then Begin
  Help;
  Halt;
 End;
 ImgName:=ParamStr(1);
 Assign(Img,ImgName);
 {$I-}Reset(Img,1);{$I+}
 If IoResult<>0Then Begin
  WriteLn('Impossible d''ouvrir ',ImgName);
  Halt(1);
 End;
 FATCachedLBA:=-1;
 DetectImageFormat;
 ReadBoot;
 SysSeen:=False;
 For I:=2 to ParamCount do Begin
  P:=ParamStr(I);
  If IsSysParam(P)Then Begin
   If SysSeen Then Begin
    WriteLn('Un seul parametre /SYS:fichier est supporte.');
    Halt(1);
   End;
   SysSeen:=True;
   P:=Copy(P,6,Length(P)-5);
   If HasWildcard(P)Then ExpandAndCopy(P,True)
                    Else CopyFileToImage(P,True);
  End
   Else If HasWildcard(P)Then ExpandAndCopy(P,False)
   Else CopyFileToImage(P,False);
 End;
 Close(Img);
End.
