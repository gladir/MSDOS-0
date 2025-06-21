{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program CREF;

Uses DOS;

Const
 MAX_SYMBOLS=100;
 MAX_REFS_PER_SYMBOL=50;

Type
 TReference=Record
  LineNumber:Word;
  DefinedHere:Boolean;
 End;

 TSymbol=Record
  Name:String[31];
  RefCount:Integer;
  References:Array[1..MAX_REFS_PER_SYMBOL] of TReference;
 End;

Var
 Symbols:Array[1..MAX_SYMBOLS] of TSymbol;
 SymbolCount:Integer;
 CRFFile,REFFile:Text;
 CRFName,REFName:String;

Function AddSymbol(Const Name:String):Integer;
Var
 i:Integer;
Begin
 { Rechercher si le symbole existe d‚j… }
 For i:=1 to SymbolCount do If Symbols[i].Name=Name Then Begin
  AddSymbol:=i;
  Exit;
 End;
  { Ajouter nouveau symbole }
 If SymbolCount<MAX_SYMBOLS Then Begin
  Inc(SymbolCount);
  With Symbols[SymbolCount] do Begin
   Name:=Name;
   RefCount:=0;
  End;
  AddSymbol:=SymbolCount;
 End
  Else
 AddSymbol:=0;
End;

Procedure AddReference(SymbolIndex:Integer;LineNum:Word;IsDefined:Boolean);Begin
 With Symbols[SymbolIndex] do If RefCount < MAX_REFS_PER_SYMBOL Then Begin
  Inc(RefCount);
  References[RefCount].LineNumber:=LineNum;
  References[RefCount].DefinedHere:=IsDefined;
 End;
End;

Procedure SortSymbols;
Var
 i,j:Integer;
 Temp:TSymbol;
Begin
 For i:=1 to SymbolCount-1 do For j:=i+1 to SymbolCount do
  If Symbols[i].Name>Symbols[j].Name Then Begin
   Temp:=Symbols[i];
   Symbols[i]:=Symbols[j];
   Symbols[j]:=Temp;
  End;
End;

Procedure ProcessCRFFile;
Var
 Line:String;
 SymbolName:String;
 LineNum:Word;
 SymIndex:Integer;
 IsDefined:Boolean;
 Err:Word;
Begin
 While Not Eof(CRFFile) do Begin
  ReadLn(CRFFile,Line);
  If Length(Line)>0 Then Begin
    { Format typique: SYMBOLE 0001:D 0002 0003 }
    { o— D indique une d‚finition }
   SymbolName:=Copy(Line,1,Pos(' ',Line)-1);
   SymIndex:=AddSymbol(SymbolName);
    { Traiter chaque r‚f‚rence sur la ligne }
   While Length(Line)>0 do Begin
    Line:=Copy(Line,Pos(' ',Line)+1,Length(Line));
    If Length(Line)=0 Then Break;
    IsDefined:=Pos('D',Line)>0;
    Val(Copy(Line,1,4),LineNum,Err);
    If SymIndex>0 Then AddReference(SymIndex,LineNum,IsDefined);
   End;
  End;
 End;
End;

Procedure WriteREFFile;
Var
 i,j:Integer;
 Symbol:TSymbol;
Begin
 WriteLn(REFFile, 'Liste de r‚f‚rence crois‚');
 WriteLn(REFFile, '-------------------------');
 WriteLn(REFFile);
 For i:=1 to SymbolCount do Begin
  Symbol:=Symbols[i];
  Write(REFFile,Symbol.Name:20);
  For j:=1 to Symbol.RefCount do With Symbol.References[j] do Begin
   If DefinedHere Then Write(REFFile,' #',LineNumber:4)
                  Else Write(REFFile, ' ', LineNumber:4);
  End;
  WriteLn(REFFile);
 End;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('CREF - Cette commande permet de produire une liste de symboles crois‚s');
  WriteLn;
  WriteLn('Syntaxe : CREF crf_file[,ref_file]');
  WriteLn;
  WriteLn(' crf_file  Fichier d''entr‚e (extension par d‚faut .CRF)');
  WriteLn(' ref_file  Fichier de sortie (extension par d‚faut .REF)');
  Halt;
 End;
  { Obtenir les noms de fichiers }
 CRFName:=ParamStr(1);
 If Pos('.',CRFName)=0 Then CRFName:=CRFName+'.CRF';
 If ParamCount>1 Then REFName:=ParamStr(2)
                 Else REFName:=Copy(CRFName,1,Length(CRFName)-4)+'.REF';
  { Ouvrir les fichiers }
 {$I-}
 Assign(CRFFile, CRFName);
 Reset(CRFFile);
 If IOResult<>0 Then Begin
  WriteLn('Erreur: Impossible d''ouvrir le fichier d''entr‚e');
  Exit;
 End;
 Assign(REFFile,REFName);
 Rewrite(REFFile);
 If IOResult<>0 then Begin
  WriteLn('Erreur: Impossible de cr‚er le fichier de sortie.');
  Close(CRFFile);
  Halt(1);
 End;
 {$I+}

  { Initialiser }
 SymbolCount := 0;
  { Traiter le fichier CRF }
 ProcessCRFFile;
  { Trier les symboles }
 SortSymbols;
  { G‚n‚rer le fichier REF }
 WriteREFFile;
  { Fermer les fichiers }
 Close(CRFFile);
 Close(REFFile);
 WriteLn('R‚f‚rence crois‚ cr‚e : ', REFName);
END.
