{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program COMP;

Uses Crt,DOS;

Var
 Language:(_Albanian,_Danish,_French,_English,_Germany,_Italian,_Spain,_Swedish);
 TmpLanguage:String;
 Finish,Diff:Boolean;
 Option:Set of (_CaseIgnore);
 Output:(_Hex,_Dec,_Char);
 OutputStatus:(_Offset,_Line);
 I:Integer;
 FileName1,FileName2,FileNameResult:String;
 FileComp1,FileComp2:File;
 FileResult:Text;
 Buffer1,Buffer2:Array[0..255]of Byte;
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
  If StrToUpper(Copy(TmpLanguage,1,2))='DK'Then Language:=_Danish Else
  If StrToUpper(Copy(TmpLanguage,1,2))='GR'Then Language:=_Germany Else
  If StrToUpper(Copy(TmpLanguage,1,2))='IT'Then Language:=_Italian Else
  If StrToUpper(Copy(TmpLanguage,1,2))='SE'Then Language:=_Swedish Else
  If StrToUpper(Copy(TmpLanguage,1,2))='SP'Then Language:=_Spain Else
  If(StrToUpper(Copy(TmpLanguage,1,2))='SQ')or
    (StrToUpper(Copy(TmpLanguage,1,3))='ALB')Then Language:=_Albanian;
 End;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  Case Language of
   _English:Begin
    WriteLn('COMP : This command compares the contents of two files or sets ');
    WriteLn('       of files byte-by-byte.');
    WriteLn;
    WriteLn('Syntax : COMP file1 file2 [/A] [/C] [/D] [/L] [/M]');
    WriteLn;
    WriteLn('  file1     First file to compare');
    WriteLn('  file2     Second file to compare');
    WriteLn('  /A        Displays differences as characters.');
    WriteLn('  /C        Performs a comparison that is not case-sensitive.');
    WriteLn('  /D        Displays differences in decimal format.');
    WriteLn('            (The default format is hexadecimal)');
    WriteLn('  /L        Displays the number of the line where a difference occurs, ');
    WriteLn('            instead of displaying the byte offset.');
    WriteLn('  /M        Do not ask for further comparisons');
    WriteLn(' --version  Output version information and exit');
   End;
   Else Begin
    WriteLn('COMP : Cette commande permet de comparer deux fichiers.');
    WriteLn;
    WriteLn('Syntaxe : COMP fichier1 fichier2 [/A] [/C] [/D] [/L] [/M]');
    WriteLn;
    WriteLn('  fichier1  Premier fichier Ö comparer');
    WriteLn('  fichier2  Deuxiäme fichier Ö comparer');
    WriteLn('  /A        Affiche la diffÇrence en ASCII');
    WriteLn('  /C        Affiche la diffÇrence en Caractäre');
    WriteLn('  /D        Affiche la diffÇrence en dÇcimale');
    WriteLn('  /L        Affiche le numÇro de ligne plutìt que le dÇplacement');
    WriteLn('  /M        Ne pas poser de question pour d''autres comparaisons');
    WriteLn(' --version  Demande la version de la commande');
   End;
  End;
 End
  Else
 If ParamStr(1)='--version'Then Begin
  WriteLn('COMP 1.0.1 - Clone Pascal de MSDOS-0, PCDOS-0, OS2-0 ou Corail');
  WriteLn('Licence MIT');
  WriteLn;
  WriteLn('êcrit par Sylvain Maltais');
 End
  Else
 If ParamCount>0Then Begin
  Finish:=False;
  Output:=_Hex;
  OutputStatus:=_Offset;
  FileName1:='';
  FileName2:='';
  FileNameResult:='';
  For I:=1 to ParamCount do Begin
   If(ParamStr(I)='/A')or(ParamStr(I)='/a')Then Output:=_Char Else
   If(ParamStr(I)='/C')or(ParamStr(I)='/c')Then Include(Option,_CaseIgnore) Else
   If(ParamStr(I)='/D')or(ParamStr(I)='/d')Then Output:=_Dec Else
   If(ParamStr(I)='/L')or(ParamStr(I)='/l')Then OutputStatus:=_Line Else
   If(ParamStr(I)='/M')or(ParamStr(I)='/m')Then Finish:=True Else
   If FileName1=''Then FileName1:=ParamStr(I) Else
   If FileName2=''Then FileName2:=ParamStr(I)
                  Else FileNameResult:=ParamStr(I);
  End;
  Repeat
   If(FileName1='')or(FileName2='')Then Begin
    Case Language of
     _English:WriteLn('2 file names are required!');
     Else WriteLn('2 noms de fichiers sont requis !');
    End;
   End
    Else
   Begin
    CurrPos:=0;
    CurrLineCount:=1;
    {$I-}Assign(FileComp1,FileName1);
    Reset(FileComp1,1);{$I+}
    {$I-}Assign(FileComp2,FileName2);
    Reset(FileComp2,1);{$I+}
    If FileNameResult<>''Then Begin
     {$I-}Assign(FileResult,FileNameResult);
     Rewrite(FileResult);{$I+}
    End;
    While Not EOF(FileComp1)do Begin
     BlockRead(FileComp1,Buffer1,SizeOf(Buffer1),ByteReaded1);
     BlockRead(FileComp2,Buffer2,SizeOf(Buffer2),ByteReaded2);
     If ByteReaded2=0Then Begin
      Case Language of
       _English:WriteLn('Second shorter file!');
       Else WriteLn('Deuxiäme fichier plus court !');
      End;
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
       If FileNameResult<>''Then Begin
        Case OutputStatus of
         _Offset:WriteLn(FileResult,'Erreur de comparaison au dÇplacement ',HexWord2Str(CurrPos+I));
         _Line:WriteLn(FileResult,'Erreur de comparaison Ö la ligne ',CurrLineCount);
        End;
        Case Output of
         _Hex:Begin
          Case Language of
          _English:Begin
            WriteLn(FileResult,'file1 = ',ByteHex2Str(Buffer1[I]));
            WriteLn(FileResult,'file2 = ',ByteHex2Str(Buffer2[I]));
           End;
           Else Begin
            WriteLn(FileResult,'fichier1 = ',ByteHex2Str(Buffer1[I]));
            WriteLn(FileResult,'fichier2 = ',ByteHex2Str(Buffer2[I]));
           End;
          End;
         End;
         _Dec:Begin
          Case Language of
           _English:Begin
            WriteLn(FileResult,'file1 = ',Buffer1[I]);
            WriteLn(FileResult,'file2 = ',Buffer2[I]);
           End;
           Else Begin
            WriteLn(FileResult,'fichier1 = ',Buffer1[I]);
            WriteLn(FileResult,'fichier2 = ',Buffer2[I]);
           End;
          End;
         End;
         _Char:Begin
          Case Language of
           _English:Begin
            WriteLn(FileResult,'file1 = ',Char(Buffer1[I]));
            WriteLn(FileResult,'file2 = ',Char(Buffer2[I]));
           End;
           Else Begin
            WriteLn(FileResult,'fichier1 = ',Char(Buffer1[I]));
            WriteLn(FileResult,'fichier2 = ',Char(Buffer2[I]));
           End;
          End;
         End;
        End;
       End
        Else
       Begin
        Case OutputStatus of
         _Offset:WriteLn('Erreur de comparaison au dÇplacement ',HexWord2Str(CurrPos+I));
         _Line:WriteLn('Erreur de comparaison Ö la ligne ',CurrLineCount);
        End;
        Case Output of
         _Hex:Begin
          Case Language of
          _English:Begin
            WriteLn('file1 = ',ByteHex2Str(Buffer1[I]));
            WriteLn('file2 = ',ByteHex2Str(Buffer2[I]));
           End;
           Else Begin
            WriteLn('fichier1 = ',ByteHex2Str(Buffer1[I]));
            WriteLn('fichier2 = ',ByteHex2Str(Buffer2[I]));
           End;
          End;
         End;
         _Dec:Begin
          Case Language of
           _English:Begin
            WriteLn('file1 = ',Buffer1[I]);
            WriteLn('file2 = ',Buffer2[I]);
           End;
           Else Begin
            WriteLn('fichier1 = ',Buffer1[I]);
            WriteLn('fichier2 = ',Buffer2[I]);
           End;
          End;
         End;
         _Char:Begin
          Case Language of
           _English:Begin
            WriteLn('file1 = ',Char(Buffer1[I]));
            WriteLn('file2 = ',Char(Buffer2[I]));
           End;
           Else Begin
            WriteLn('fichier1 = ',Char(Buffer1[I]));
            WriteLn('fichier2 = ',Char(Buffer2[I]));
           End;
          End;
         End;
        End;
       End;
      End;
     End;
     Inc(CurrPos,ByteReaded1);
    End;
    If FileNameResult<>''Then Close(FileResult);
    Close(FileComp1);
    Close(FileComp2);
   End;
   If Not(Finish)Then Begin
    Case Language of
     _English:Write('Compare more files (Y/N) ? ');
     Else Write('Comparer d''autres fichiers (O/N) ? ');
    End;
    Case ReadKey of
     'O','o','Y','y':Begin
      Case Language of
       _English:Begin
        WriteLn('Yes');
        Write('Name of the first file to compare: ');
       End;
       Else Begin
        WriteLn('Oui');
        Write('Nom du premier fichier a comparer : ');
       End;
      End;
      ReadLn(FileName1);
      Case Language of
       _English:Write('Name of the second file to compare:');
       Else Write('Nom du deuxiäme fichier a comparer : ');
      End;
      ReadLn(FileName2);
     End;
     Else Begin
      Case Language of
       _English:WriteLn('No');
       Else WriteLn('Non');
      End;
      Finish:=True;
     End;
    End;
   End;
  Until Finish;
 End
  Else
 Begin
  Case Language of
   _English:WriteLn('Missing parameter!');
   Else WriteLn('Paramätre requis !');
  End;
  Halt(2);
 End;
END.
