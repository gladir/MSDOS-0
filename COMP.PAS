{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program COMP;

Uses Crt,DOS;

Const
 kbNoKey=0;{Pas de touche}
 kbDn=$5000;{Fleche Bas}
 kbEnter=$1C0D;{Enter}
 kbEsc=$011B;{Escape}
 kbShiftTab=$0F00;{Shift+Tabulation}
 kbTab=$0F09;{Tabulation}
 kbUp=$4800;{Fleche Haut}

Var
 Language:(_Albanian,_Danish,_French,_English,_Germany,_Italian,_Spain,_Swedish);
 TmpLanguage:String;
 CurrDialog:Byte;
 Ok:Boolean;
 ShowASCII128:Boolean;
 K:Word;
 GUI,Finish,Diff:Boolean;
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

{$IFNDEF FPC}
 Procedure CursorOff;
 Var
  Regs:Registers;
 Begin
  Regs.AH:=1;
  Regs.CH:=32;
  Regs.CL:=0;
  Intr($10,Regs);
 End;

 Procedure CursorOn;
 Var
  Regs:Registers;
 Begin
  Regs.AX:=$0100;
  Regs.CX:=(7 shl 8)+9;
  Intr($10,Regs);
 End;
{$ENDIF}

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

Function DuplicateString(C:Char;Num:Integer):String;
Var
 I:Byte;
 S:String;
Begin
 S:='';
 For I:=1 to Num do S:=S+C;
 DuplicateString:=S;
End;

Procedure SetASCII128(X:Boolean);Begin
 ShowASCII128:=X;
End;

Function GetASCII128:Boolean;Begin
 GetASCII128:=ShowASCII128;
End;

Procedure Box(X1,Y1,X2,Y2,Couleur:Byte);Begin
 Window(X1,Y1,X2,Y2);
 TextBackground((Couleur shr 4)and 15);
 {$IFDEF FPC}
  If Couleur and $80=$80 Then Begin
   TextColor((Couleur and 15)+BLINK);
  End
   Else
  TextColor(Couleur and 15);
 {$ELSE}
  TextColor(Couleur and 15);
 {$ENDIF}
 ClrScr;
 Window(1,1,80,25);
End;

Procedure FrameEmpty(X1,Y1,X2,Y2,Couleur:Byte);
Var
 I:Byte;
 ChrHori,ChrVert:Char;
 Chr218,Chr192,Chr191,Chr217:Char;
Begin
 TextBackground((Couleur shr 4)and 15);
 {$IFDEF FPC}
  If Couleur and $80=$80 Then Begin
   TextColor((Couleur and 15)+BLINK);
  End
   Else
  TextColor(Couleur and 15);
 {$ELSE}
  TextColor(Couleur and 15);
 {$ENDIF}
 If(ShowASCII128)Then Begin
  ChrHori:='-';
  ChrVert:='|';
  Chr218:='+';
  Chr192:='+';
  Chr191:='+';
  Chr217:='+';
 End
  Else
 Begin
  ChrHori:=#$C4;
  ChrVert:=#$B3;
  Chr218:=#218;
  Chr192:=#192;
  Chr191:=#191;
  Chr217:=#217;
  End;
 For I:=Y1+1 to Y2-1 do Begin
  GotoXY(X1,I);
  Write(ChrVert);
  GotoXY(X2,I);
  Write(ChrVert);
 End;
 GotoXY(X1+1,Y1);
 Write(DuplicateString(ChrHori,X2-X1-1));
 GotoXY(X1+1,Y2);
 Write(DuplicateString(ChrHori,X2-X1-1));
 GotoXY(X1,Y1);
 Write(Chr218);
 GotoXY(X1,Y2);
 Write(Chr192);
 GotoXY(X2,Y1);
 Write(Chr191);
 GotoxY(X2,Y2);
 Write(Chr217);
End;

Procedure DialogBox(X1,Y1,X2,Y2,Couleur:Byte);Begin
 Box(X1,Y1,X2,Y2,Couleur);
 FrameEmpty(X1,Y1,X2,Y2,Couleur);
 TextAttr:=Couleur;
End;

Function ReadLine(Var S:String):Word;
Var
 Rec:SearchRec;
 K:Char;
 X,Y,I:Byte;
 CurrHistory:Integer;
Begin
 ReadLine:=0;
 X:=WhereX;
 Y:=WhereY;
 Repeat
  GotoXY(X,Y);
  Write(S);
  ClrEol;
  K:=ReadKey;
  Case K of
   #0:Case ReadKey of
    #72:Begin
     ReadLine:=kbUp;
     Exit;
    End;
    #80:Begin
     ReadLine:=kbDn;
     Exit;
    End;
   End;
   #8:Begin
    If S<>''Then S:=Copy(S,1,Length(S)-1);
   End;
   #9:Begin
    ReadLine:=kbTab;
    Exit;
   End;
   #13:Begin
    ReadLine:=kbEnter;
   End;
   #27:Begin
    ReadLine:=kbEsc;
    Exit;
   End;
   Else S:=S+K;
  End;
  If S[Length(S)]=#13Then Begin
   S:=Copy(S,1,Length(S)-1);
   K:=#13;
  End;
 Until K=#13;
 GotoXY(X,Y);
 WriteLn(S);
End;

Function ReadLineInBox(X1,Y1,X2,Y2:Byte;Var S:String):Word;Begin
 Window(X1,Y1,X2,Y2);
 ReadLineInBox:=ReadLine(S);
 Window(1,1,80,25);
End;

Procedure SetDialogTextColor;Begin
 TextBackground(CurrDialog shr 4);
 TextColor(CurrDialog and$F);
End;

Procedure SetButtonColor;Begin
 TextBackground(Cyan);
 TextColor(0);
End;

Procedure SetSelectedButtonColor;Begin
 TextBackground(Cyan);
 TextColor(Yellow);
End;

Procedure ShowButton(ButtonList:String;PosButton:Byte);
Var
 I,CurrPosButton:Integer;
 First:Boolean;
 CurrButton:String;
Begin
 CurrButton:='';
 First:=True;
 CurrPosButton:=0;
 For I:=1 to Length(ButtonList)do Begin
  If ButtonList[I]='|'Then Begin
   SetDialogTextColor;
   If Not(First)Then Write('  ');
   If(PosButton=CurrPosButton)Then SetSelectedButtonColor
                              Else SetButtonColor;
   Write('  ',CurrButton,'  ');
   SetDialogTextColor;
   CurrButton:='';
   First:=False;
   Inc(CurrPosButton);
  End
   Else
  CurrButton:=CurrButton+ButtonList[I];
 End;
 SetDialogTextColor;
 If Not(First)Then Write('  ');
 If(PosButton=CurrPosButton)Then SetSelectedButtonColor
                            Else SetButtonColor;
 Write('  ',CurrButton,'  ');
End;

Function LengthButton(ButtonList:String):Integer;
Var
 I,CurrPosButton,LenButton:Integer;
 First:Boolean;
 CurrButton:String;
Begin
 LengthButton:=0;
 LenButton:=0;
 CurrButton:='';
 First:=True;
 CurrPosButton:=0;
 For I:=1 to Length(ButtonList)do Begin
  If ButtonList[I]='|'Then Begin
   If Not(First)Then Inc(LenButton,Length('  '));
   Inc(LenButton,Length('  '+CurrButton+'  '));
   CurrButton:='';
   First:=False;
   Inc(CurrPosButton);
  End
   Else
  CurrButton:=CurrButton+ButtonList[I];
 End;
 If Not(First)Then Inc(LenButton,Length('  '));
 Inc(LenButton,Length('  '+CurrButton+'  '));
 LengthButton:=LenButton;
End;

Function ReadHorizontalButton(ButtonList:String):Word;
Var
 X,Y:Byte;
 K:Char;
 I,NumButton,CurrButton:Integer;
Begin
 CurrDialog:=TextAttr;
 CursorOff;
 ReadHorizontalButton:=kbEsc;
 CurrButton:=0;
 NumButton:=1;
 X:=WhereX;
 Y:=WhereY;
 For I:=1 to Length(ButtonList)do If ButtonList[I]='|'Then Inc(NumButton);
 ShowButton(ButtonList,0);
 Repeat
  K:=ReadKey;
  Case K of
   #0:Case ReadKey of
    #15:Begin { Shift+Tab }
     If(CurrButton>0)Then Begin
      Dec(CurrButton);
      GotoXY(X,Y);
      ShowButton(ButtonList,CurrButton);
     End
      Else
     Begin
      ReadHorizontalButton:=kbShiftTab;
      Break;
     End;
    End;
    #75:Begin { Gauche }
     If(CurrButton>0)Then Dec(CurrButton)
                     Else CurrButton:=NumButton-1;
     GotoXY(X,Y);
     ShowButton(ButtonList,CurrButton);
    End;
    #77:Begin { Droite }
     If(CurrButton+1>=NumButton)Then CurrButton:=0
                                Else Inc(CurrButton);
     GotoXY(X,Y);
     ShowButton(ButtonList,CurrButton);
    End;
   End;
   #9:Begin
    If(CurrButton+1>=NumButton)Then Begin
     ReadHorizontalButton:=kbTab;
     Break;
    End
     Else
    Begin
     Inc(CurrButton);
     GotoXY(X,Y);
     ShowButton(ButtonList,CurrButton);
    End;
   End;
   #13:ReadHorizontalButton:=CurrButton;
   #27:ReadHorizontalButton:=kbEsc;
  End;
 Until K in[#13,#27];
 SetDialogTextColor;
 CursorOn;
End;

Procedure ShowHorizontalCenterButton(Y:Byte;S:String);Begin
 GotoXY((80-LengthButton(S)) shr 1,Y);
 ShowButton(S,$FF);
End;

Function ReadHorizontalCenterButton(Y:Byte;S:String):Word;Begin
 GotoXY((80-LengthButton(S)) shr 1,Y);
 ReadHorizontalCenterButton:=ReadHorizontalButton(S);
End;

Procedure WriteCenter(Y:Byte;Phrase:String;Color:Byte);Begin
 GotoXY(40-Length(Phrase) div 2,Y);
 TextBackground(Color shr 4);
 TextColor(Color and$F);
 Write(Phrase);
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
    WriteLn('Syntax : COMP file1 file2 [file3] [/A] [/C] [/D] [/L] [/M] [/GUI]');
    WriteLn;
    WriteLn('  file1     First file to compare');
    WriteLn('  file2     Second file to compare');
    WriteLn('  file3     File containing the results of the analysis');
    WriteLn('  /A        Displays differences as characters.');
    WriteLn('  /C        Performs a comparison that is not case-sensitive.');
    WriteLn('  /D        Displays differences in decimal format.');
    WriteLn('            (The default format is hexadecimal)');
    WriteLn('  /GUI      Use a GUI to enter the two files to compare');
    WriteLn('  /L        Displays the number of the line where a difference occurs, ');
    WriteLn('            instead of displaying the byte offset.');
    WriteLn('  /M        Do not ask for further comparisons');
    WriteLn(' --version  Output version information and exit');
   End;
   _Germany:Begin
    WriteLn('COMP : Vergleicht den Inhalt von zwei Dateien oder SÑtzen ');
    WriteLn('       von Dateien Byte fÅr Byte.');
    WriteLn;
    WriteLn('Syntax : COMP file1 file2 [file3] [/A] [/C] [/D] [/L] [/M] [/GUI]');
    WriteLn;
    WriteLn('  file1     Gibt den Speicherort und den Namen der ersten Datei ');
    WriteLn('            oder des Dateisatzes an.');
    WriteLn('  file2     Gibt den Speicherort und den Namen der zweiten Datei ');
    WriteLn('            oder des Dateisatzes an.');
    WriteLn('  file3     Datei mit den Ergebnissen der Analyse');
    WriteLn('  /A        Zeigt Unterschiede als Zeichen an. ');
    WriteLn('  /C        FÅhrt einen Vergleich aus, bei dem die Gro·-/Kleinschreibung ');
    WriteLn('            nicht beachtet wird.');
    WriteLn('  /D        Zeigt Unterschiede im Dezimalformat an.');
    WriteLn('            (Das Standardformat ist hexadezimal.)');
    WriteLn('  /GUI      Verwenden Sie eine GUI, um die beiden zu vergleichenden ');
    WriteLn('            Dateien einzugeben');
    WriteLn('  /L        Affiche le numÇro de la ligne oó une diffÇrence se produit ');
    WriteLn('            au lieu d''afficher le dÇcalage d''octet.');
    WriteLn('  /M        Fordern Sie keine weiteren Vergleiche an');
    WriteLn(' --version  Versionsinformationen ausgeben und beenden');
   End;
   Else Begin
    WriteLn('COMP : Cette commande permet de comparer deux fichiers.');
    WriteLn;
    WriteLn('Syntaxe : COMP fichier1 fichier2 [fichier3] [/A] [/C] [/D] [/L] [/M] [/GUI]');
    WriteLn;
    WriteLn('  fichier1  Premier fichier Ö comparer');
    WriteLn('  fichier2  Deuxiäme fichier Ö comparer');
    WriteLn('  fichier3  Fichier allant contenir les rÇsultats de l''analyse');
    WriteLn('  /A        Affiche la diffÇrence en ASCII');
    WriteLn('  /C        Affiche la diffÇrence en Caractäre');
    WriteLn('  /D        Affiche la diffÇrence en dÇcimale');
    WriteLn('  /GUI      Utiliser un GUI pour entrez les deux fichiers Ö comparer');
    WriteLn('  /L        Affiche le numÇro de ligne plutìt que le dÇplacement');
    WriteLn('  /M        Ne pas poser de question pour d''autres comparaisons');
    WriteLn(' --version  Demande la version de la commande');
   End;
  End;
 End
  Else
 If ParamStr(1)='--version'Then Begin
  WriteLn('COMP 1.0.2 - Clone Pascal de COMP, MSDOS-0, PCDOS-0, OS2-0 ou Corail');
  WriteLn('Licence MIT');
  WriteLn;
  WriteLn('êcrit par Sylvain Maltais');
 End
  Else
 If ParamCount>0Then Begin
  GUI:=False;
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
   If(StrToUpper(ParamStr(I))='/GUI')Then GUI:=True Else
   If(ParamStr(I)='/L')or(ParamStr(I)='/l')Then OutputStatus:=_Line Else
   If(ParamStr(I)='/M')or(ParamStr(I)='/m')Then Finish:=True Else
   If FileName1=''Then FileName1:=ParamStr(I) Else
   If FileName2=''Then FileName2:=ParamStr(I)
                  Else FileNameResult:=ParamStr(I);
  End;
  Repeat
   If(GUI)Then Begin
    Finish:=True;
    CurrDialog:=$70;
    DialogBox(3,6,76,17,$70);
    WriteCenter(6,' Comparaison ',$70);
    GotoxY(7,7);
    Case Language of
     _English:Write('Enter the name of the first file:');
     Else Write('Entrez le nom du premier fichier :');
    End;
    GotoxY(7,11);
    Case Language of
     _English:Write('Enter the name of the second file:');
     Else Write('Entrez le nom du deuxiäme fichier :');
    End;
    Ok:=False;
    Box(7,13,72,13,$30);
    Repeat
     Case Language of
      _English:ShowHorizontalCenterButton(15,'Compare|Cancel');
      Else ShowHorizontalCenterButton(15,'Comparer|Annuler');
     End;
     Repeat
      TextColor(Black);
      TextBackground(LightCyan);
      K:=ReadLineInBox(7,9,72,9,FileName1);
      If(K=kbEsc)Then Begin
       TextColor(LightGray);
       TextBackground(Black);
       ClrScr;
       Halt(1);
      End;
     Until(K=kbTab)or(K=kbEnter);
     Repeat
      TextColor(Black);
      TextBackground(LightCyan);
      K:=ReadLineInBox(7,13,72,13,FileName2);
      If(K=kbEsc)Then Begin
       TextColor(LightGray);
       TextBackground(Black);
       ClrScr;
       Halt(1);
       End;
     Until(K=kbTab)or(K=kbEnter);
     TextColor(0);
     TextBackground(LightGray);
     Case Language of
      _English:K:=ReadHorizontalCenterButton(15,'Compare|Cancel');
      Else K:=ReadHorizontalCenterButton(15,'Comparer|Annuler');
     End;
     If(K=1)or(K=kbEsc)Then Begin
      TextColor(LightGray);
      TextBackground(Black);
      ClrScr;
      Halt(1);
      Exit;
     End;
     If(K=0)Then OK:=True;
    Until Ok;
    TextColor(LightGray);
    TextBackground(Black);
    ClrScr;
   End;
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
    If IOResult<>0 Then Begin
     WriteLn('Erreur de lecture du premier fichier');
     Halt(4);
    End;
    {$I-}Assign(FileComp2,FileName2);
    Reset(FileComp2,1);{$I+}
    If IOResult<>0 Then Begin
     WriteLn('Erreur de lecture du deuxiäme fichier');
     Halt(5);
    End;
    If FileNameResult<>''Then Begin
     {$I-}Assign(FileResult,FileNameResult);
     Rewrite(FileResult);{$I+}
    End;
    If IOResult<>0 Then Begin
     WriteLn('Erreur d''Çcriture du fichier de rÇsultat');
     Halt(6);
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
     _Germany:Write('Weitere Dateien vergleichen (J/N)?');
     Else Write('Comparer d''autres fichiers (O/N) ? ');
    End;
    Case ReadKey of
     'O','o','Y','y','J','j','S','s':Begin
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
       _Germany:WriteLn('Nein');
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