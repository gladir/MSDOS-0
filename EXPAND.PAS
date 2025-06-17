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
 BUFFER_SIZE=16384;  { Augmenté pour plus de sécurité }
 DICT_SIZE=4096;
 MAX_DICT_SIZE=DICT_SIZE-1;
 SZDD_SIGNATURE:Array[0..3]of Char='SZDD';
 KWAJ_SIGNATURE:Array[0..3]of Char='KWAJ';

 KWAJ_METHOD_NONE = 0;
 KWAJ_METHOD_LZ77 = 1;
 KWAJ_METHOD_LZ77_RLE = 2;
 KWAJ_METHOD_HUFFMAN = 3;
 KWAJ_METHOD_MSCOMP = $88;  { Ajout de la méthode 136 }

Type
 TDictEntry=Record
  Prefix:Word;
  Suffix:Byte;
 End;

 TDictBuffer = array[0..MAX_DICT_SIZE] of Byte;

 TKWAJHeader=Record
  Signature:Array[0..3] of Char;  { 'KWAJ' }
  Method:Byte;                    { M�thode de compression }
  DictionarySize:Byte;            { Taille du dictionaire }
  Flags:Word;                     { Drapeaux de compression }
  OriginalSize:LongInt;           { Taille des donn�es d�compress�s }
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
 HeaderSZDD:TSZDDHeader;
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
 BlockRead(f,HeaderSZDD,SizeOf(HeaderSZDD));
 If(HeaderSZDD.Signature='SZDD')Then Begin
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
   While NewCode < 256 do Begin
    OutBuf[OutSize]:=Dictionary[NewCode].suffix;
    Inc(OutSize);
    If OutSize=BUFFER_SIZE Then Begin
     BlockWrite(Dest, OutBuf, OutSize);
     OutSize:=0;
    End;
    NewCode:=Dictionary[NewCode].prefix;
   End;
  End;
  If OldCode <> $FFFF Then Begin
    { Ajout d'une entr�e dans le dictionnaire }
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
    If InPos>=InSize Then Break;  { V�rification de s�curit� }
     Offset:=Offset+InBuf[InPos];
     Inc(InPos);
      { Protection contre les d�bordements }
     If(Offset>DictPos)or(Offset>MAX_DICT_SIZE)Then Offset:=DictPos;
     For i:=0 to Len-1 do Begin
      If OutPos >= BUFFER_SIZE then Break;  { Protection de tampon de sortie }
       { S�curisation de l'acc�s au dictionnaire }
      If(DictPos - Offset + i) >= 0 Then
       OutBuf[OutPos]:=Dictionary[(DictPos - Offset + i) and MAX_DICT_SIZE]
      Else
       OutBuf[OutPos]:=0;
       { Protection �criture dictionnaire }
      If DictPos<=MAX_DICT_SIZE Then Dictionary[DictPos]:=OutBuf[OutPos];
      Inc(DictPos);
      DictPos := DictPos and MAX_DICT_SIZE;
      Inc(OutPos);
     End;
    End
     else
    Begin
        Len := Control + 1;

        { Protection contre débordement de buffer }
        if Len > (InSize - InPos) then
          Len := InSize - InPos;

        for i := 0 to Len-1 do
        begin
          if (OutPos >= BUFFER_SIZE) or (InPos >= InSize) then Break;

          OutBuf[OutPos] := InBuf[InPos];

          { Protection écriture dictionnaire }
          if DictPos <= MAX_DICT_SIZE then
            Dictionary[DictPos] := InBuf[InPos];

          Inc(InPos);
          Inc(DictPos);
          DictPos := DictPos and MAX_DICT_SIZE;
          Inc(OutPos);
        end;
      end;

      { Écriture du buffer quand il est presque plein }
      if OutPos >= BUFFER_SIZE - 512 then
      begin
        BlockWrite(Dest, OutBuf, OutPos);
        OutPos := 0;
      end;
    end;

    if OutPos > 0 then
      BlockWrite(Dest, OutBuf, OutPos);
  end;
end;

Procedure DecompressHuffman(Var Source,Dest:File);Begin
 WriteLn('Erreur: Compression Huffman n''est pas impl�ment�');
 Halt(9);
End;

Procedure DecompressKWAJ(Var Source,Dest:File);Begin
 BlockRead(Source, KWAJHeader,SizeOf(KWAJHeader));
 Case KWAJHeader.Method of
  KWAJ_METHOD_NONE:
   CopyUncompressed(Source, Dest);
  KWAJ_METHOD_LZ77,
  KWAJ_METHOD_LZ77_RLE,
  KWAJ_METHOD_MSCOMP:  { Ajout du cas 0x88 }
   DecompressLZ77(Source, Dest);
  KWAJ_METHOD_HUFFMAN:
   DecompressHuffman(Source, Dest);
  Else WriteLn('Erreur: M�thode de compression non-support�: ', KWAJHeader.Method);
 End;
End;

Procedure DecompressSZDD(Var Source,Dest:File);
Var
 InBuf,OutBuf:Array[0..BUFFER_SIZE-1] of Byte;
 InPos,OutPos:LongInt;
 InSize:Word;
 Control,Len,Offset:Byte;
 i:Integer;
Begin
 BlockRead(Source,HeaderSZDD,SizeOf(HeaderSZDD)); { Saute l'ent�te }
 While Not Eof(Source) do Begin
  BlockRead(Source, InBuf, BUFFER_SIZE, InSize);
  If InSize=0 Then Break;
  InPos:=0;
  OutPos:=0;
  While InPos<InSize do Begin
   Control := InBuf[InPos];
   Inc(InPos);
   If Control=$FF Then Begin { Octet lit�ral }
    OutBuf[OutPos] := InBuf[InPos];
    Inc(InPos);
    Inc(OutPos);
   End
    Else { S�quence de compression }
   Begin
    Len:=(Control and $0F)+3;
    Offset:=Control shr 4;
     { Copie de la sortie du tampon avec le d�placement }
    For i:=0 to Len-1 do Begin
     OutBuf[OutPos]:=OutBuf[OutPos-Offset-1];
     Inc(OutPos);
    End;
   End;
   If OutPos>=BUFFER_SIZE Then Begin
    BlockWrite(Dest, OutBuf, OutPos);
    OutPos := 0;
   End;
  End;
  If OutPos>0 Then BlockWrite(Dest,OutBuf,OutPos);
 End;
End;

Var
 SourceName,DestName:String;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('EXPAND : Cette commande permet d''effectuer la d�compression d''un fichier.');
  WriteLn;
  WriteLn('Syntaxe : EXPAND source [destination]');
  WriteLn;
  WriteLn(' source      Indique le fichier compress�');
  WriteLn(' destination Indique le fichier � cr�er');
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
  WriteLn('Erreur: Fichier source n''est pas compress�.');
  Close(SourceFile);
  Halt(4);
 End;
 {$I-}Assign(DestFile, DestName);
 Rewrite(DestFile,1);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Erreur: Impossible de cr�er le fichier de destination');
  Close(SourceFile);
  Halt(2);
 End;
 Case DecompressMethod of
  methodKWAJ:DecompressKWAJ(SourceFile,DestFile);
  methodDict:ExpandFile(SourceFile,DestFile);
  methodSZDD:DecompressSZDD(SourceFile,DestFile);
  Else Begin
   WriteLn('M�thode de compression non reconnu');
   Halt(3);
  End;
 End;
 Close(SourceFile);
 Close(DestFile);
 WriteLn('Expension du fichier r�ussis');
END.
