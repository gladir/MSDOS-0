{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program EXPAND;

Uses
 DOS;

const
 BUFFER_SIZE=8192;
 DICT_SIZE=4096;

Type
 TDictEntry=Record
  prefix:Word;
  suffix:Byte;
 End;

Var
 SourceFile,DestFile:File;
 Buffer:Array[0..BUFFER_SIZE-1] of Byte;
 Dictionary:Array[0..DICT_SIZE-1] of TDictEntry;
 DictCount:Word;

Function IsCompressed(Var f:File):Boolean;
Var
 Signature:Word;
Begin
 BlockRead(f,Signature,2);
 IsCompressed:=(Signature=$4D53); { Signature 'MS' }
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
 SourceName:=ParamStr(1);
 If ParamCount=2 Then DestName := ParamStr(2)
                 Else DestName := SourceName + '.EXP';
 {$I-} Assign(SourceFile,SourceName);
 Reset(SourceFile,1);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Erreur: Impossible d''ouvrir le fichier');
  Exit;
 End;
 If Not IsCompressed(SourceFile)Then Begin
  WriteLn('Erreur: Fichier source n''est pas compress‚.');
  Close(SourceFile);
  Exit;
 End;
 {$I-}Assign(DestFile, DestName);
 Rewrite(DestFile, 1);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Erreur: Impossible de cr‚er le fichier de destination');
  Close(SourceFile);
  Exit;
 End;
 ExpandFile(SourceFile,DestFile);
 Close(SourceFile);
 Close(DestFile);
 WriteLn('Expension du fichier r‚ussis');
END.