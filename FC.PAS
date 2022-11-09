{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program FC;

Uses DOS;

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 Diff:Boolean;
 Option:Set of (_CaseIgnore);
 SourceInput:(_Binary,_ASCII);
 OutputStatus:(_Offset,_Line);
 I:Integer;
 FileName1,FileName2:String;
 FileComp1,FileComp2:File;
 ASCIIComp1,ASCIIComp2:Text;
 Buffer1,Buffer2:Array[0..255]of Byte;
 Line1,Line2:String;
 ByteReaded1,ByteReaded2:Integer;
 CurrPos,CurrLineCount:LongInt;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
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
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  Case Language of
   _Germany:Begin
    WriteLn('Vergleich zwei Dateien oder zwei S„tze von Dateien und zeigt die');
    WriteLn('Untershiede zwischen Ihnen an.');
    WriteLn;
    WriteLn('FC Dateiname1 Dateiname2 [/B] [/C] [/L]');
    WriteLn;
    WriteLn('  /B       Fhrt einen bin„ren Vergleich durch.');
    WriteLn('  /C       Vergleich ohne Rcksicht auf Gross-/Kleinschreibung');
    WriteLn('  /L       Vergleich Dateien als ASCII-Text.');
   End;
   _English:Begin
    WriteLn('Compares two files or sets of files and displays the differences between them.');
    WriteLn;
    WriteLn('FC filename1 filename2 [/B] [/C] [/L]');
    WriteLn;
    WriteLn('  /B       Performs a binary comparison.');
    WriteLn('  /C       Disregards the case of letters.');
    WriteLn('  /L       Compare files as ASCII text.');
   End;
   Else Begin
    WriteLn('FC : Cette commande permet de comparer deux fichiers.');
    WriteLn;
    WriteLn('Syntaxe : FC fichier1 fichier2 [/B] [/C] [/L]');
    WriteLn;
    WriteLn('  fichier1 Premier fichier a comparer');
    WriteLn('  fichier2 Deuxieme fichier a comparer');
    WriteLn('  /B       Comparaison binaire');
    WriteLn('  /C       Sans distinction minuscule/majuscule');
    WriteLn('  /L       Comparaison ASCII ligne par ligne');
   End;
  End;
 End
  Else
 If ParamCount>0Then Begin
  SourceInput:=_ASCII;
  OutputStatus:=_Offset;
  FileName1:='';
  FileName2:='';
  For I:=1 to ParamCount do Begin
   If StrToUpper(ParamStr(I))='/B'Then SourceInput:=_Binary Else
   If StrToUpper(ParamStr(I))='/C'Then Include(Option,_CaseIgnore) Else
   If StrToUpper(ParamStr(I))='/L'Then SourceInput:=_ASCII Else
   If FileName1=''Then FileName1:=ParamStr(I)
                  Else FileName2:=ParamStr(I);
 End;
  If(FileName1='')or(FileName2='')Then Begin
   WriteLn('2 noms de fichiers sont requis !');
  End
   Else
  If SourceInput=_ASCII Then Begin
   CurrPos:=0;
   CurrLineCount:=1;
   Assign(ASCIIComp1,FileName1);
   Reset(ASCIIComp1);
   Assign(ASCIIComp2,FileName2);
   Reset(ASCIIComp2);
   While Not EOF(ASCIIComp1)do Begin
    ReadLn(ASCIIComp1,Line1);
    ReadLn(ASCIIComp2,Line2);
    If _CaseIgnore in(Option)Then Begin
     If StrToUpper(Line1)<>StrToUpper(Line2)Then Begin
      WriteLn('----------',FileName1);
      WriteLn(Line1);
      WriteLn('----------',FileName2);
      WriteLn(Line2);
     End;
    End
     Else
    Begin
     If Line1<>Line2 Then Begin
      WriteLn('----------',FileName1);
      WriteLn(Line1);
      WriteLn('----------',FileName2);
      WriteLn(Line2);
     End;
    End;
   End;
   Close(ASCIIComp1);
   Close(ASCIIComp2);
  End
   Else
  Begin
   CurrPos:=0;
   CurrLineCount:=1;
   Assign(FileComp1,FileName1);
   Reset(FileComp1,1);
   Assign(FileComp2,FileName2);
   Reset(FileComp2,1);
   WriteLn('--ADDRS----F1---F2--');
   While Not EOF(FileComp1)do Begin
    BlockRead(FileComp1,Buffer1,SizeOf(Buffer1),ByteReaded1);
    BlockRead(FileComp2,Buffer2,SizeOf(Buffer2),ByteReaded2);
    If ByteReaded2=0Then Begin
     WriteLn('Deuxieme fichier plus court !');
     Break;
    End;
    For I:=0 to High(Buffer1)do Begin
     If(Buffer1[I]=13)Then Inc(CurrLineCount);
     If _CaseIgnore in(Option)Then Begin
      Diff:=(UpCase(Char(Buffer1[I]))<>UpCase(Char(Buffer2[I])));
     End
      Else
     Begin
      Diff:=(Char(Buffer1[I])<>Char(Buffer2[I]));
     End;
     If(Diff)Then Begin
      Case OutputStatus of
       _Offset:Begin
        WriteLn(LongHex2Str(CurrPos+I),' ':3,
                ByteHex2Str(Buffer1[I]),' ':3,
                ByteHex2Str(Buffer2[I]));
       End;
       _Line:WriteLn('Erreur de comparaison a la ligne ',CurrLineCount);
      End;
     End;
    End;
    Inc(CurrPos,ByteReaded1);
   End;
   Close(FileComp1);
   Close(FileComp2);
  End;
 End
  Else
 WriteLn('Parametre requis !');
END.
