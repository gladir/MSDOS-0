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
 BUFFER_SIZE=8192;
 DICT_SIZE=4096;
 SZDD_SIGNATURE:Array[0..3]of Char='SZDD';
 KWAJ_SIGNATURE:Array[0..3]of Char='KWAJ';

Type
 TDictEntry=Record
  prefix:Word;
  suffix:Byte;
 End;

 TKWAJHeader=Record
  Signature:Array[0..3] of Char;  { 'KWAJ' }
  Method:Byte;                    { M‚thode de compression }
  DictionarySize:Byte;            { Taille du dictionaire }
  Flags:Word;                     { Drapeaux de compression }
  OriginalSize:LongInt;           { Taille des donn‚es d‚compress‚s }
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
    { Ajout d'une entrï¿½e dans le dictionnaire }
   Dictionary[DictCount].prefix:=OldCode;
   Dictionary[DictCount].suffix:=Char;
   Inc(DictCount);
  End;
  OldCode:=Code;
  Char:=Dictionary[Code].suffix;
 End;
 If OutSize>0 Then BlockWrite(Dest,OutBuf,OutSize);
End;

Procedure DecompressKWAJ(Var Source,Dest:File);
Var
 InBuf,OutBuf,Dictionary:Array[0..BUFFER_SIZE-1] of Byte;
 InPos,OutPos,DictPos:Word;
 InSize,OutSize:Word;
 Control:Byte;
 Len,Offset:LongInt;
 i:Integer;
Begin
 BlockRead(Source,KWAJHeader,SizeOf(KWAJHeader));
 DictPos:=0;
 While Not Eof(Source) do Begin
  BlockRead(Source, InBuf,BUFFER_SIZE,InSize);
  If InSize=0 Then Break;
  InPos:=0;
  OutPos:=0;
  While InPos<InSize do Begin
   Control:=InBuf[InPos];
   Inc(InPos);
   If Control and $80<>0 Then Begin { Bloc compressï¿½ }
    Len:=((Control and $7F) shr 4)+3;
    Offset:=((Control and $0F) shl 8);
    If InPos<InSize Then Offset:=Offset+InBuf[InPos];
    Inc(InPos);

    { S‚curisation du d‚placement }
    If Offset>DictPos Then Offset:=DictPos;

    { Copie du dictionaire avec v‚rifications des limites }
    For i:=0 to Len-1 do Begin
      If (DictPos - Offset + i) >= 0 Then
        OutBuf[OutPos]:= Dictionary[(DictPos - Offset + i) and $FFF]
      Else
        OutBuf[OutPos]:= 0;  { Protection contre les d‚bordements n‚gatifs }

     Dictionary[DictPos]:= OutBuf[OutPos];
     Inc(DictPos);
     DictPos:=DictPos and $FFF;
     Inc(OutPos);

     If OutPos >= BUFFER_SIZE Then Begin
      BlockWrite(Dest, OutBuf, OutPos);
      OutPos:=0;
     End;
    End;
   End
    Else { Octet lit‚ral }
   Begin
    Len:=Control+1;
    For i:=0 to Len-1 do Begin
     If OutPos>=SizeOf(OutBuf)Then Begin
      WriteLn('D‚compression KWAJ impossible : D‚bordement du tampon de sortie');
      Halt(6);
     End;
     If InPos>=SizeOf(InBuf)Then Begin
      WriteLn('D‚compression KWAJ impossible : D‚bordement du tampon d''entr‚e');
      Halt(7);
     End;
     OutBuf[OutPos]:=InBuf[InPos];
     Dictionary[DictPos]:=InBuf[InPos];
     Inc(InPos);
     Inc(DictPos);
     DictPos:=DictPos and $FFF;
     Inc(OutPos);
    End;
   End;
   If OutPos>=BUFFER_SIZE-256 Then Begin
    BlockWrite(Dest, OutBuf, OutPos);
    OutPos := 0;
   End;
  End;
  If OutPos>0 Then BlockWrite(Dest,OutBuf,OutPos);
 End;
End;

Procedure DecompressSZDD(Var Source,Dest:File);
Var
 InBuf,OutBuf:Array[0..BUFFER_SIZE-1] of Byte;
 InPos,OutPos:Word;
 InSize,OutSize:Word;
 Control,Len,Offset:Byte;
 i:Integer;
Begin
 BlockRead(Source,HeaderSZDD,SizeOf(HeaderSZDD)); { Saute l'entˆte }
 While Not Eof(Source) do Begin
  BlockRead(Source, InBuf, BUFFER_SIZE, InSize);
  If InSize=0 Then Break;
  InPos:=0;
  OutPos:=0;
  While InPos<InSize do Begin
   Control := InBuf[InPos];
   Inc(InPos);
   If Control=$FF Then Begin { Octet lit‚ral }
    OutBuf[OutPos] := InBuf[InPos];
    Inc(InPos);
    Inc(OutPos);
   End
    Else { S‚quence de compression }
   Begin
    Len:=(Control and $0F)+3;
    Offset:=Control shr 4;
     { Copie de la sortie du tampon avec le d‚placement }
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
   WriteLn('M‚thode de compression non reconnu');
   Halt(3);
  End;
 End;
 Close(SourceFile);
 Close(DestFile);
 WriteLn('Expension du fichier r‚ussis');
END.
