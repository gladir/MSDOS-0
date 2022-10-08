{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Free Pascal, Turbo Pascal)
}

Program MORE(Input,Output);

Uses Crt,DOS;

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 I:Byte;
 S:String;
 FileRead:Text;
 Regs:Registers;

Function StrToUpper(S:String):String;
Var
 I:Byte; { Compteur de boucle attribue a la chaine de caracteres }
Begin
 For I:=1to Length(S)do S[I]:=UpCase(S[I]);
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
 If ParamStr(1)='/?'Then Begin
  Case Language of
   _Germany:Begin
    WriteLn('Zeigt Daten seitenweise auf dem Bildschirm an.');
    WriteLn;
    WriteLn('MORE [Laufwerk:][Pfad]Dateiname');
   End;
   _English:Begin
    WriteLn('Displays output one screen at a time.');
    WriteLn;
    WriteLn('MORE source');
   End;
   Else Begin
    WriteLn('MORE : Cette commande permet de recevoir l''entree puis ',
            'l''affiche sur un peripherique de sortie un ecran a la fois.');
    WriteLn;
    WriteLn('Syntaxe : MORE source');
   End;
  End;
 End
  Else
 If ParamCount>0Then Begin
  Assign(FileRead,ParamStr(1));
  Reset(FileRead);
  I:=0;
  While Not(EOF(FileRead))do Begin
   Inc(I);
   ReadLn(FileRead,S);
   WriteLn(S);
   If I=Hi(WindMax)Then Begin
    WriteLn(Output,'Presse une touche pour continuer...');
    ReadKey;
    I:=0;
   End;
  End;
  Close(FileRead);
 End
  Else
 Begin
  I:=0;
  Repeat
   Inc(I);
   ReadLn(Input,S);
   WriteLn(Output,S);
   If I=Hi(WindMax)Then Begin
    WriteLn(Output,'Presse une touche pour continuer...');
    Regs.AH := $0C;
    Regs.AL := $07;
    MsDos(Regs);
    I:=0;
   End;
  Until Eof;
 End;
END.
