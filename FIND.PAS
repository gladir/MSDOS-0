{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program FIND(Input,Output);

Uses DOS;

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 Option:Set of (NoCaseSensitive,NotInLine,ShowLine);
 I:Integer;
 LineNumber:LongInt;
 Found:Boolean;
 FileFind:Text;
 Info:SearchRec;
 FindStr,FindInFile,CurrLine:String;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
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
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  Case Language of
   _Germany:Begin
    WriteLn('Sucht in einer oder mehreren Dateien nach einer Zeichenfolge.');
    WriteLn;
    WriteLn('FIND [/V] [/N] [/I] "Zeichenfolge" [[Laufwerk:][Pad]Dateiname[...]]');
    WriteLn;
    WriteLn('Zeichenfolge Die zu suchende Zeichenfolge.');
    WriteLn(' /I          Ignoriert Groá-/Kleinschreibung bei der Suche.');
    WriteLn(' /N          Zeigt die Zeilen mit ihren Zeilennummern an.');
    WriteLn(' /V          Zeigt alle Zeilen an, die die Zeichenfolge NICHT enthalten.');
   End;
   _English:Begin
    WriteLn('Searches for a text string in a file or files.');
    WriteLn;
    WriteLn('FIND [/V] [/N] [/I] "string" [[drive:][[path]filename[...]]');
    WriteLn;
    WriteLn('"string" Specifies the text string to find.');
    WriteLn('/I       Ignores the case of characters when searching for the string.');
    WriteLn('/N       Displays line numbers with the displayed lines.');
    WriteLn('/V       Display all lines NOT containing the specified string.');
   End;
   Else Begin
    WriteLn('FIND : Cette commande permet de rechercher une chaine de caractŠres dans des fichiers.');
    WriteLn;
    WriteLn('Syntaxe : FIND "chaine" [fichier] [/I] [/N] [/V]');
    WriteLn;
    WriteLn('"chaine"  Indique la chaŒne de caractŠres … rechercher dans les fichiers.');
    WriteLn('/I        Il ne faut pas effectuer de distinction entre les majuscules et minuscules.');
    WriteLn('/N        Affiche le num‚ro contenant la chaŒne de caractŠres trouv‚s.');
    WriteLn('/V        Affiche toutes les lignes ne contenant pas la chaŒne de caractŠres recherch‚s.');
   End;
  End;
 End
  Else
 If ParamCount>0Then Begin
  Option:=[];
  FindStr:='';
  FindInFile:='';
  For I:=1 to ParamCount do Begin
   If Copy(ParamStr(I),1,1)='"'Then FindStr:=Copy(ParamStr(I),2,Length(ParamStr(I))-2) Else
   If StrToUpper(ParamStr(I))='/I'Then Include(Option,NoCaseSensitive) Else
   If StrToUpper(ParamStr(I))='/N'Then Include(Option,ShowLine) Else
   If StrToUpper(ParamStr(I))='/V'Then Include(Option,NotInLine)
    Else
   Begin
    If FindStr=''Then FindStr:=ParamStr(I)
                 Else FindInFile:=ParamStr(I);
   End;
  End;
  If FindStr=''Then Begin
   WriteLn('Chaine de caracteres de recherche requis !');
  End
   Else
  If FindInFile=''Then Begin
   LineNumber:=1;
   Repeat
    ReadLn(CurrLine);
    If NoCaseSensitive in Option Then Begin
     If NotInLine in Option Then Begin
      If Pos(StrToUpper(FindStr),StrToUpper(CurrLine))=0 Then Begin
       If ShowLine in Option Then WriteLn('[',LineNumber,']',' ':4,CurrLine)
                             Else WriteLn(CurrLine);
      End
     End
      Else
     If Pos(StrToUpper(FindStr),StrToUpper(CurrLine))>0 Then Begin
      If ShowLine in Option Then WriteLn('[',LineNumber,']',' ':4,CurrLine)
                            Else WriteLn(CurrLine);
     End;
    End
     Else
    If NotInLine in Option Then Begin
     If Pos(FindStr,CurrLine)=0 Then Begin
      If ShowLine in Option Then WriteLn('[',LineNumber,']',' ':4,CurrLine)
                            Else WriteLn(CurrLine);
     End;
    End
     Else
    If Pos(FindStr,CurrLine)>0 Then Begin
     If ShowLine in Option Then WriteLn('[',LineNumber,']',' ':4,CurrLine)
                           Else WriteLn(CurrLine);
    End;
    Inc(LineNumber);
   Until Eof(Input);
  End
   Else
  Begin
   FindFirst(FindInFile,AnyFile,Info);
   Found:=False;
   While DOSError=0 do Begin
    LineNumber:=1;
    WriteLn('-------- ',Info.Name);
    Assign(FileFind,Info.Name);
    Reset(FileFind);
    While Not EOF(FileFind)do Begin
     ReadLn(FileFind,CurrLine);
     If NoCaseSensitive in Option Then Begin
      If NotInLine in Option Then Begin
       If Pos(StrToUpper(FindStr),StrToUpper(CurrLine))=0 Then Begin
        If ShowLine in Option Then WriteLn('[',LineNumber,']',' ':4,CurrLine)
                              Else WriteLn(CurrLine);
        Found:=True;
       End;
      End
       Else
      If Pos(StrToUpper(FindStr),StrToUpper(CurrLine))>0 Then Begin
       If ShowLine in Option Then WriteLn('[',LineNumber,']',' ':4,CurrLine)
                             Else WriteLn(CurrLine);
       Found:=True;
      End;
     End
      Else
     If NotInLine in Option Then Begin
      If Pos(FindStr,CurrLine)=0 Then Begin
       If ShowLine in Option Then WriteLn('[',LineNumber,']',' ':4,CurrLine)
                             Else WriteLn(CurrLine);
       Found:=True;
      End;
     End
      Else
     If Pos(FindStr,CurrLine)>0 Then Begin
      If ShowLine in Option Then WriteLn('[',LineNumber,']',' ':4,CurrLine)
                            Else WriteLn(CurrLine);
      Found:=True;
     End;
     Inc(LineNumber);
    End;
    Close(FileFind);
    FindNext(Info);
    WriteLn;
   End;
   If Not(Found)Then WriteLn('Aucun resultat de trouve');
  End;
 End
  Else
 WriteLn('Parametre requis !');
END.
