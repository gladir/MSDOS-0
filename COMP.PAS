{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Free Pascal)
}

Program COMP;

Uses Crt;

Var
 Finish,Diff:Boolean;
 Option:Set of (_CaseIgnore);
 Output:(_Hex,_Dec,_Char);
 OutputStatus:(_Offset,_Line);
 I:Integer;
 FileName1,FileName2:String;
 FileComp1,FileComp2:File of Byte;
 Buffer1,Buffer2:Array[0..255]of Byte;
 ByteReaded1,ByteReaded2:Integer;
 CurrPos,CurrLineCount:LongInt;

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
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('COMP : Cette commande permet de comparer deux fichiers.');
  WriteLn;
  WriteLn('Syntaxe : COMP fichier1 fichier2 [/A] [/C] [/D] [/L] [/M]');
  WriteLn;
  WriteLn('  fichier1 Premier fichier a comparer');
  WriteLn('  fichier2 Deuxieme fichier a comparer');
  WriteLn('  /A       Affiche la difference en ASCII');
  WriteLn('  /C       Affiche la difference en Caractere');
  WriteLn('  /D       Affiche la difference en decimale');
  WriteLn('  /L       Affiche le numero de ligne plutot que le deplacement');
  WriteLn('  /M       Ne pas poser de question pour d''autres comparaisons');
 End
  Else
 If ParamCount>0Then Begin
  Finish:=False;
  Output:=_Hex;
  OutputStatus:=_Offset;
  FileName1:='';
  FileName2:='';
  For I:=1 to ParamCount do Begin
   If(ParamStr(I)='/A')or(ParamStr(I)='/a')Then Output:=_Char Else
   If(ParamStr(I)='/C')or(ParamStr(I)='/c')Then Include(Option,_CaseIgnore) Else
   If(ParamStr(I)='/D')or(ParamStr(I)='/d')Then Output:=_Dec Else
   If(ParamStr(I)='/L')or(ParamStr(I)='/l')Then OutputStatus:=_Line Else
   If(ParamStr(I)='/M')or(ParamStr(I)='/m')Then Finish:=True Else
   If FileName1=''Then FileName1:=ParamStr(I)
                  Else FileName2:=ParamStr(I);
  End;
  Repeat
   If(FileName1='')or(FileName2='')Then Begin
    WriteLn('2 noms de fichiers sont requis !');
   End
    Else
   Begin
    CurrPos:=0;
    CurrLineCount:=1;
    Assign(FileComp1,FileName1);
    Reset(FileComp1);
    Assign(FileComp2,FileName2);
    Reset(FileComp2);
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
        _Offset:WriteLn('Erreur de comparaison au deplacement ',HexWord2Str(CurrPos+I));
        _Line:WriteLn('Erreur de comparaison a la ligne ',CurrLineCount);
       End;
       Case Output of
        _Hex:Begin
         WriteLn('fichier1 = ',ByteHex2Str(Buffer1[I]));
         WriteLn('fichier2 = ',ByteHex2Str(Buffer2[I]));
        End;
        _Dec:Begin
         WriteLn('fichier1 = ',Buffer1[I]);
         WriteLn('fichier2 = ',Buffer2[I]);
        End;
        _Char:Begin
         WriteLn('fichier1 = ',Char(Buffer1[I]));
         WriteLn('fichier2 = ',Char(Buffer2[I]));
        End;
       End;
      End;
     End;
     Inc(CurrPos,ByteReaded1);
    End;
    Close(FileComp1);
    Close(FileComp2);
   End;
   If Not(Finish)Then Begin
    Write('Comparer d''autres fichiers (O/N) ? ');
    Case ReadKey of
     'O','o':Begin
      WriteLn('Oui');
      Write('Nom du premier fichier a comparer : ');
      ReadLn(FileName1);
      Write('Nom du deuxieme fichier a comparer : ');
      ReadLn(FileName2);
     End;
     Else Begin
      WriteLn('Non');
      Finish:=True;
     End;
    End;
   End;
  Until Finish;
 End
  Else
 WriteLn('Parametre requis !');
END.