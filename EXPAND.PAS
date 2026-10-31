{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program EXPAND;

{$A-}
{$M 32768,0,640000}

Uses
 DOS;

Const
 BUFFER_SIZE=16384;
 DICT_SIZE=4096;
 MAX_DICT_SIZE=DICT_SIZE-1;
 SZDD_SIGNATURE:Array[0..3]of Char='SZDD';
 KWAJ_SIGNATURE:Array[0..3]of Char='KWAJ';

 KWAJ_METHOD_NONE = 0;
 KWAJ_METHOD_LZ77 = 1;
 KWAJ_METHOD_LZ77_RLE = 2;
 KWAJ_METHOD_HUFFMAN = 3;
 KWAJ_METHOD_MSCOMP = $88;  { Ajout de la m‚thode 136 }

Type
 TDictEntry=Record
  Prefix:Word;
  Suffix:Byte;
 End;

 TDictBuffer=Array[0..MAX_DICT_SIZE] of Byte;

 TKWAJHeader=Record
  Signature:Array[0..3] of Char;  { 'KWAJ' }
  Method:Byte;                    { M‚thode de compression }
  DictionarySize:Byte;            { Taille du dictionaire }
  Flags:Word;                     { Drapeaux de compression }
  OriginalSize:LongInt;           { Taille des donnï¿½es dï¿½compressï¿½s }
 End;

 TSZDDHeader=Record
  Signature:Array[0..3] of Char;
  Algorithm:Byte;
  DollarChar:Char;
 End;

Var
 DecompressMethod:(methodNone,methodDict,methodSZDD,methodKWAJ);
 SourceFile,DestFile:File;
 KWAJHeader:TKWAJHeader;
 SZDDHeader:TSZDDHeader;
 DictCount:Word;
 Dictionary:Array[0..DICT_SIZE-1] of TDictEntry;
 Buffer:Array[0..BUFFER_SIZE-1] of Byte Absolute Dictionary;

Function IsCompressedMS(Var f:File):Boolean;
Var
 Signature:Word;
Begin
 IsCompressedMS:=False;
 Seek(f,0);
 BlockRead(f,Signature,2);
 If(Signature=$4D53)Then Begin { Signature 'MS' }
  IsCompressedMS:=True;
  DecompressMethod:=methodDict;
 End;
 Seek(f,0);
End;

Function IsCompressedSZDD(Var f:File):Boolean;Begin
 IsCompressedSZDD:=False;
 Seek(f,0);
 BlockRead(f,SZDDHeader,SizeOf(SZDDHeader));
 If(SZDDHeader.Signature='SZDD')Then Begin
  IsCompressedSZDD:=True;
  DecompressMethod:=methodSZDD;
 End;
 Seek(f,0);
End;

Function IsCompressedKWAJ(Var f:File):Boolean;
Var
 Signature:Array[0..3] of Char;
Begin
 IsCompressedKWAJ:=False;
 Seek(f,0);
 BlockRead(f,Signature, 4);
 If(Signature='KWAJ')Then Begin
  IsCompressedKWAJ:=True;
  DecompressMethod:=methodKWAJ;
 End;
 Seek(f,0);
End;

Procedure InitDictionary;
Var
 i:Word;
Begin
 DictCount:=256;
 For i:=0 to 255 do Begin
  Dictionary[i].prefix:=$FFFF;
  Dictionary[i].suffix:=i;
 End;
End;

Procedure ExpandFile(Var Source,Dest:File);
Var
 InBuf,OutBuf:Array[0..BUFFER_SIZE-1] of Byte;
 InSize,OutSize:Word;
 Code,OldCode,NewCode:Word;
 Char:Byte;
Begin
 InitDictionary;
 BlockRead(Source,InBuf,2); { Saute la signature }
 While Not Eof(Source) do Begin
  BlockRead(Source,Code,2,InSize);
  If InSize=0 Then Break;
  If Code<DictCount Then Begin
    { Code existes dans le dictionaire }
   NewCode:=Code;
   While NewCode<256 do Begin
    OutBuf[OutSize]:=Dictionary[NewCode].suffix;
    Inc(OutSize);
    If OutSize=BUFFER_SIZE Then Begin
     BlockWrite(Dest, OutBuf, OutSize);
     OutSize:=0;
    End;
    NewCode:=Dictionary[NewCode].prefix;
   End;
  End;
  If OldCode<>$FFFF Then Begin
    { Ajout d'une entr‚e dans le dictionnaire }
   Dictionary[DictCount].prefix:=OldCode;
   Dictionary[DictCount].suffix:=Char;
   Inc(DictCount);
  End;
  OldCode:=Code;
  Char:=Dictionary[Code].suffix;
 End;
 If OutSize>0 Then BlockWrite(Dest,OutBuf,OutSize);
End;

Procedure CopyUncompressed(Var Source,Dest:File);
Var
 Buffer:Array[0..BUFFER_SIZE-1] of Byte;
 BytesRead:Word;
Begin
 While Not Eof(Source)do Begin
  BlockRead(Source,Buffer,BUFFER_SIZE,BytesRead);
  If BytesRead>0 Then BlockWrite(Dest,Buffer,BytesRead);
 End;
End;

Procedure DecompressLZ77(Var Source,Dest:file);
Var
 InBuf:Array[0..BUFFER_SIZE-1] of Byte;
 OutBuf:Array[0..BUFFER_SIZE-1] of Byte;
 Dictionary:TDictBuffer;
 InPos,OutPos:LongInt;
 DictPos:Word;
 InSize:Word;
 Control:Byte;
 Len,Offset:LongInt;
 i:LongInt;
Begin
 DictPos := 0;
 While not Eof(Source)do Begin
  BlockRead(Source, InBuf, BUFFER_SIZE, InSize);
  If InSize = 0 Then Break;
  InPos:=0;
  OutPos:=0;
  While InPos < InSize do Begin
   Control := InBuf[InPos];
   Inc(InPos);
   If Control and $80<>0 Then Begin
    Len:=((Control and $7F) shr 4) + 3;
    Offset:=((Control and $0F) shl 8);
    If InPos>=InSize Then Break;  { V‚rification de s‚curit‚ }
    Offset:=Offset+InBuf[InPos];
    Inc(InPos);
     { Protection contre les d‚bordements }
    If(Offset>DictPos)or(Offset>MAX_DICT_SIZE)Then Offset:=DictPos;
    For i:=0 to Len-1 do Begin
     If OutPos >= BUFFER_SIZE then Break;  { Protection de tampon de sortie }
      { S‚curisation de l'accŠs au dictionnaire }
     If(DictPos - Offset + i) >= 0 Then
      OutBuf[OutPos]:=Dictionary[(DictPos - Offset + i) and MAX_DICT_SIZE]
     Else
      OutBuf[OutPos]:=0;
      { Protection ‚criture dictionnaire }
     If DictPos<=MAX_DICT_SIZE Then Dictionary[DictPos]:=OutBuf[OutPos];
     Inc(DictPos);
     DictPos := DictPos and MAX_DICT_SIZE;
     Inc(OutPos);
    End;
   End
    else
   Begin
    Len:=Control+1;
     { Protection contre d‚bordement de tampon }
    If Len>(InSize-InPos)Then Len:=InSize-InPos;
    For i:=0 to Len-1 do Begin
     If(OutPos>=BUFFER_SIZE)or(InPos>=InSize)Then Break;
     OutBuf[OutPos]:=InBuf[InPos];
      { Protection ‚criture dictionnaire }
     If DictPos<=MAX_DICT_SIZE Then Dictionary[DictPos]:=InBuf[InPos];
     Inc(InPos);
     Inc(DictPos);
     DictPos := DictPos and MAX_DICT_SIZE;
     Inc(OutPos);
    End;
   End;

    { ‚criture du tampon quand il est presque plein }
   If OutPos >= BUFFER_SIZE-512 Then Begin
    BlockWrite(Dest, OutBuf, OutPos);
    OutPos := 0;
   End;
  End;
  If OutPos>0 Then BlockWrite(Dest,OutBuf,OutPos);
 End;
End;

{ ------------------------------------------------------------------ }
{ Decompression KWAJ (methodes 0 a 3) et SZDD                        }
{                                                                    }
{ En-tete KWAJ : 'KWAJ',$88,$F0,$27,$D1, methode:Word,               }
{ decalage des donnees:Word, indicateurs:Word, champs facultatifs.    }
{  0 = copie, 1 = OU exclusif avec $FF, 2 = LZSS (comme SZDD),        }
{  3 = LZ (fenetre de 4096 octets) + codes de Huffman, 4 = MSZIP.      }
{ ------------------------------------------------------------------ }

Const
 KW_IN_SIZE=4096;
 KW_OUT_SIZE=8192;

Type
 TKwHuff=Record
  Cnt:Array[0..15] of Integer;
  Sym:Array[0..255] of Integer;
 End;
 TKwLens=Array[0..255] of Byte;

Var
 KwIn:Array[0..KW_IN_SIZE-1] of Byte;
 KwInLen,KwInPos:Word;
 KwBitBuf,KwBitCnt:Byte;
 KwEnd,KwBad:Boolean;
 KwOut:Array[0..KW_OUT_SIZE-1] of Byte;
 KwOutPos:Word;
 KwWin:Array[0..4095] of Byte;
 KwTotal:LongInt;

{ Lit un octet de la source ; retourne -1 en fin de fichier }
Function KwGetByte:Integer;
Begin
 If KwInPos>=KwInLen Then Begin
  KwInPos:=0;
  KwInLen:=0;
  If Not Eof(SourceFile)Then BlockRead(SourceFile,KwIn,KW_IN_SIZE,KwInLen);
  If KwInLen=0 Then Begin
   KwGetByte:=-1;
   Exit;
  End;
 End;
 KwGetByte:=KwIn[KwInPos];
 Inc(KwInPos);
End;

{ Lit un bit, poids fort en premier ; apres la fin des donnees, retourne 0
  et positionne KwEnd }
Function KwGetBit:Word;
Var B:Integer;
Begin
 If KwBitCnt=0 Then Begin
  B:=KwGetByte;
  If B<0 Then Begin
   KwEnd:=True;
   KwGetBit:=0;
   Exit;
  End;
  KwBitBuf:=B;
  KwBitCnt:=8;
 End;
 Dec(KwBitCnt);
 KwGetBit:=(KwBitBuf Shr KwBitCnt)And 1;
End;

Function KwGetBits(N:Byte):Word;
Var V:Word;
    I:Byte;
Begin
 V:=0;
 For I:=1 to N do V:=(V Shl 1)Or KwGetBit;
 KwGetBits:=V;
End;

Procedure KwFlush;Begin
 If KwOutPos>0 Then BlockWrite(DestFile,KwOut,KwOutPos);
 KwOutPos:=0;
End;

Procedure KwPut(B:Byte);Begin
 If KwOutPos>=KW_OUT_SIZE Then KwFlush;
 KwOut[KwOutPos]:=B;
 Inc(KwOutPos);
 Inc(KwTotal);
End;

Procedure KwInit;Begin
 KwInLen:=0;
 KwInPos:=0;
 KwBitCnt:=0;
 KwBitBuf:=0;
 KwEnd:=False;
 KwBad:=False;
 KwOutPos:=0;
 KwTotal:=0;
End;

{ Code de Huffman canonique : codes croissants par longueur puis par symbole }
Procedure KwBuild(Var H:TKwHuff;Var L:TKwLens;N:Integer);
Var I,Len:Integer;
    Offs:Array[0..16] of Integer;
Begin
 For I:=0 to 15 do H.Cnt[I]:=0;
 For I:=0 to N-1 do Inc(H.Cnt[L[I]And 15]);
 H.Cnt[0]:=0;
 Offs[1]:=0;
 For Len:=1 to 15 do Offs[Len+1]:=Offs[Len]+H.Cnt[Len];
 For I:=0 to N-1 do
  If(L[I]And 15)<>0 Then Begin
   H.Sym[Offs[L[I]And 15]]:=I;
   Inc(Offs[L[I]And 15]);
  End;
End;

Function KwSym(Var H:TKwHuff):Integer;
Var Code,First,Index:LongInt;
    Len:Integer;
Begin
 Code:=0;
 First:=0;
 Index:=0;
 For Len:=1 to 15 do Begin
  Code:=Code Or KwGetBit;
  If Code-H.Cnt[Len]<First Then Begin
   KwSym:=H.Sym[Index+(Code-First)];
   Exit;
  End;
  Index:=Index+H.Cnt[Len];
  First:=(First+H.Cnt[Len])Shl 1;
  Code:=Code Shl 1;
 End;
 KwBad:=True;
 KwSym:=0;
End;

{ Lecture des longueurs de codes d'une table (4 modes de codage) }
Procedure KwReadLens(Typ:Integer;N:Integer;Var L:TKwLens);
Var I,C,Sel:Integer;
Begin
 C:=0;
 Case Typ of
  0:Begin
   Case N of
    16:C:=4;
    32:C:=5;
    64:C:=6;
    256:C:=8;
   End;
   For I:=0 to N-1 do L[I]:=C;
  End;
  1:Begin
   C:=KwGetBits(4);
   L[0]:=C;
   For I:=1 to N-1 do Begin
    If KwGetBit=0 Then L[I]:=C
     Else Begin
      If KwGetBit=0 Then Begin
       Inc(C);
       L[I]:=C;
      End
       Else Begin
        C:=KwGetBits(4);
        L[I]:=C;
       End;
     End;
   End;
  End;
  2:Begin
   C:=KwGetBits(4);
   L[0]:=C;
   For I:=1 to N-1 do Begin
    Sel:=KwGetBits(2);
    If Sel=3 Then C:=KwGetBits(4)
             Else C:=C+Sel-1;
    L[I]:=C And 15;
   End;
  End;
  Else For I:=0 to N-1 do L[I]:=KwGetBits(4);
 End;
End;

{ Methode 3 : alternance de correspondances (distance sur 12 bits, longueur
  de 3 a 17) et de series de litteraux ; pas de marqueur de fin : la fin des
  donnees arrete le decodage }
Procedure KwajLZH;
Var Types:Array[0..5] of Integer;
    L1,L2,L3,L4,L5:TKwLens;
    H1,H2,H3,H4,H5:TKwHuff;
    I,Len,Offset,Pos,Sym,LitRun:Integer;
Begin
 FillChar(KwWin,SizeOf(KwWin),32);
 For I:=0 to 5 do Types[I]:=KwGetBits(4);
 KwReadLens(Types[0],16,L1);  KwBuild(H1,L1,16);
 KwReadLens(Types[1],16,L2);  KwBuild(H2,L2,16);
 KwReadLens(Types[2],32,L3);  KwBuild(H3,L3,32);
 KwReadLens(Types[3],64,L4);  KwBuild(H4,L4,64);
 KwReadLens(Types[4],256,L5); KwBuild(H5,L5,256);
 Pos:=0;
 LitRun:=0;
 While Not KwBad do Begin
  If LitRun<>0 Then Len:=KwSym(H2)
               Else Len:=KwSym(H1);
  If KwEnd Then Break;
  If Len>0 Then Begin
   Inc(Len,2);
   LitRun:=0;
   Offset:=KwSym(H4)Shl 6;
   Offset:=Offset Or KwGetBits(6);
   If KwEnd Then Break;
   While Len>0 do Begin
    KwWin[Pos]:=KwWin[(Pos+4096-Offset)And 4095];
    KwPut(KwWin[Pos]);
    Pos:=(Pos+1)And 4095;
    Dec(Len);
   End;
  End
   Else
  Begin
   Len:=KwSym(H3)+1;
   If KwEnd Then Break;
   If Len=32 Then LitRun:=0
             Else LitRun:=1;
   While Len>0 do Begin
    Sym:=KwSym(H5);
    If KwEnd Then Break;
    KwWin[Pos]:=Sym;
    KwPut(Sym);
    Pos:=(Pos+1)And 4095;
    Dec(Len);
   End;
   If KwEnd Then Break;
  End;
 End;
 KwFlush;
 If KwBad Then Begin
  WriteLn('Erreur: donnees KWAJ invalides');
  Halt(9);
 End;
End;

{ LZSS de SZDD (et de KWAJ methode 2) : fenetre de 4096 octets garnie de
  blancs, ecriture a partir de la position 4080, octet de controle lu de
  droite a gauche (1 = litteral, 0 = copie : position:12 bits,
  longueur-3:4 bits) }
Procedure KwSzddBody(MaxSize:LongInt);
Var Control,B1,B2,Bit:Integer;
    Pos,Src,Len,I:Integer;
Begin
 FillChar(KwWin,SizeOf(KwWin),32);
 Pos:=4096-16;
 While(MaxSize<0)or(KwTotal<MaxSize)do Begin
  Control:=KwGetByte;
  If Control<0 Then Break;
  For Bit:=0 to 7 do Begin
   If(MaxSize>=0)and(KwTotal>=MaxSize)Then Break;
   If(Control And(1 Shl Bit))<>0 Then Begin
    B1:=KwGetByte;
    If B1<0 Then Break;
    KwWin[Pos]:=B1;
    KwPut(B1);
    Pos:=(Pos+1)And 4095;
   End
    Else
   Begin
    B1:=KwGetByte;
    B2:=KwGetByte;
    If(B1<0)or(B2<0)Then Break;
    Src:=B1 Or((B2 And $F0)Shl 4);
    Len:=(B2 And $0F)+3;
    For I:=0 to Len-1 do Begin
     KwWin[Pos]:=KwWin[(Src+I)And 4095];
     KwPut(KwWin[Pos]);
     Pos:=(Pos+1)And 4095;
    End;
   End;
  End;
 End;
 KwFlush;
End;

Procedure DecompressKWAJ(Var Source,Dest:File);
Var Hdr:Array[0..13] of Byte;
    Method,DataOff,B:Integer;
Begin
 Seek(Source,0);
 BlockRead(Source,Hdr,14);
 Method:=Hdr[8]+256*Hdr[9];
 DataOff:=Hdr[10]+256*Hdr[11];
 Seek(Source,DataOff);
 KwInit;
 Case Method of
  0:Begin
   Repeat
    B:=KwGetByte;
    If B>=0 Then KwPut(B);
   Until B<0;
   KwFlush;
  End;
  1:Begin
   Repeat
    B:=KwGetByte;
    If B>=0 Then KwPut(B Xor $FF);
   Until B<0;
   KwFlush;
  End;
  2:KwSzddBody(-1);
  3:KwajLZH;
  Else Begin
   WriteLn('Erreur: methode KWAJ non supportee: ',Method);
   Halt(9);
  End;
 End;
End;

Procedure DecompressSZDD(Var Source,Dest:File);
Var Hdr:Array[0..13] of Byte;
    Size:LongInt;
Begin
 Seek(Source,0);
 BlockRead(Source,Hdr,14);
 Size:=Hdr[10]+LongInt(Hdr[11])*256+LongInt(Hdr[12])*65536+LongInt(Hdr[13])*16777216;
 KwInit;
 KwSzddBody(Size);
End;

Var
 SourceName,DestName:String;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('EXPAND : Cette commande permet d''effectuer la d‚compression d''un fichier.');
  WriteLn;
  WriteLn('Syntaxe : EXPAND source [destination]');
  WriteLn;
  WriteLn(' source      Indique le fichier compress‚');
  WriteLn(' destination Indique le fichier … cr‚er');
  Halt;
 End;
 DecompressMethod:=methodNone;
 SourceName:=ParamStr(1);
 If ParamCount=2 Then DestName:=ParamStr(2)
                 Else DestName:=SourceName + '.EXP';
 {$I-} Assign(SourceFile,SourceName);
 Reset(SourceFile,1);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Erreur: Impossible d''ouvrir le fichier');
  Exit;
 End;
 If Not(IsCompressedMS(SourceFile)or
        IsCompressedSZDD(SourceFile)or
        IsCompressedKWAJ(SourceFile))Then Begin
  WriteLn('Erreur: Fichier source n''est pas compress‚.');
  Close(SourceFile);
  Halt(4);
 End;
 {$I-}Assign(DestFile, DestName);
 Rewrite(DestFile,1);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Erreur: Impossible de cr‚er le fichier de destination');
  Close(SourceFile);
  Halt(2);
 End;
 Case DecompressMethod of
  methodKWAJ:DecompressKWAJ(SourceFile,DestFile);
  methodDict:ExpandFile(SourceFile,DestFile);
  methodSZDD:DecompressSZDD(SourceFile,DestFile);
  Else Begin
   WriteLn('Mï¿½thode de compression non reconnu');
   Halt(3);
  End;
 End;
 Close(SourceFile);
 Close(DestFile);
 WriteLn('Expension du fichier r‚ussis');
END.
