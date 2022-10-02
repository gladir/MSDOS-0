{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program Choice;

Uses Crt,DOS;

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 StartTime,EndTime,CurrTime:LongInt;
 OptionFlag:(_None,_C);
 NoPrompt,Found,CheckCase:Boolean;
 I,nn:Integer;
 Err:Word;
 C,defaultChar:Char;
 ChoiceString,TextString,CurrParam:String;

Function GetCurrTime:LongInt;
Var
 Hour,Min,Sec,Sec100:Word;
Begin
 GetTime(Hour,Min,Sec,Sec100);
 GetCurrTime:=Sec100+(Sec*100)+(Min*60*100)+(Hour*60*60*100);
End;

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
  If StrToUpper(Copy(TmpLanguage,1,2))='GR'Then Language:=_Germany Else
  If StrToUpper(Copy(TmpLanguage,1,2))='IT'Then Language:=_Italian Else
  If StrToUpper(Copy(TmpLanguage,1,2))='SP'Then Language:=_Spain;
 End;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  Case Language of
   _Germany:Begin
    WriteLn('Wartet auf die Answahl des Benutzers der angeigten Optionen.');
    WriteLn;
    WriteLn('CHOICE [/C[:]Tasten] [/N] [/S] [/T[:]c,nn] [Text]');
    WriteLn;
    WriteLn('/C[:]Tasten  Angabe der zul„ssigen Tasten. Standard ist JN.');
    WriteLn('/N           Keine Anzeigne eines ?-Zeichens am Ende der Meldung.');
    WriteLn('/S           Groá-/Kleinschreibung fšr Tasten wird beachtet.');
    WriteLn('/T[:]c,nn    Nach nn Sekunden wird Standardausahl c ausgefšhrt.');
    WriteLn('Text         Meldung, die angezeigt wird.');
   End;
   _English:Begin
    WriteLn('CHOICE : Waits for you to choose one of a set of choices.');
    WriteLn;
    WriteLn('Formats: CHOICE [/C[:]choices] [/N] [/S] [/T[:]c,nn]');
    WriteLn;
    WriteLn('/C[:]choices  Specifies allowable keys. Default is YN.');
    WriteLn('/N            Does not display choices and ? at end of prompt string.');
    WriteLn('/S            Treats choice keys as case sensitive.');
   End;
   Else Begin
    WriteLn('CHOICE : Cette commande permet de faire un choix.');
    WriteLn;
    WriteLn('Syntaxe : CHOICE [/C[:]choix] [/N] [/S] [/T[:]c,nn]');
    WriteLn;
    WriteLn('/C[:]touches  Indique la liste des touches accept‚es comme r‚ponse');

   End;
  End;
 End
  Else
 Begin
  nn:=-1;defaultChar:=#0;
  NoPrompt:=False;
  CheckCase:=False;
  OptionFlag:=_None;
  ChoiceString:='';
  TextString:='';
  For I:=1 to ParamCount do Begin
   If OptionFlag<>_None Then Begin
    Case OptionFlag of
     _C:ChoiceString:=ParamStr(I);
    End;
    OptionFlag:=_None;
   End
    Else
   If Copy(StrToUpper(ParamStr(I)),1,2)='/T'Then Begin
    CurrParam:=StrToUpper(ParamStr(I));
    If CurrParam[3]=':'Then Begin
     defaultChar:=CurrParam[4];
     If CurrParam[5]<>','Then Begin
      Write('Virgule attendu');
      Halt;
     End;
     Val(Copy(CurrParam,6,255),nn,Err);
    End
     Else
    Begin
     defaultChar:=CurrParam[3];
     If CurrParam[4]<>','Then Begin
      Write('Virgule attendu');
      Halt;
     End;
     Val(Copy(CurrParam,5,255),nn,Err);
    End;
   End
    Else
   If StrToUpper(ParamStr(I))='/S'Then CheckCase:=True Else
   If StrToUpper(ParamStr(I))='/N'Then NoPrompt:=True Else
   If StrToUpper(ParamStr(I))='/C'Then OptionFlag:=_C Else
   If StrToUpper(Copy(ParamStr(I),1,3))='/C:'Then Begin
    ChoiceString:=Copy(ParamStr(I),4,255);
   End
    Else
   Begin
    TextString:=TextString+' '+ParamStr(I);
    OptionFlag:=_None;
   End;
  End;
  If ChoiceString=''Then Begin
   Case Language of
    _English:ChoiceString:='YN';
    _Germany:ChoiceString:='JN';
    Else ChoiceString:='ON';
   End;
  End;
  If Not(NoPrompt)Then Begin
   Write('[');
   For I:=1 to Length(ChoiceString)do Begin
    If I<>1Then Write(',');
    Write(ChoiceString[I]);
   End;
   Write(']?');
  End;
  Found:=False;
  Repeat
   If nn<>-1 Then Begin
    StartTime:=GetCurrTime;
    EndTime:=StartTime+nn*100;
    C:=DefaultChar;
    Repeat
     CurrTime:=GetCurrTime;
     If(KeyPressed)Then Begin
      C:=ReadKey;
      If C=#0 Then ReadKey;
      Break;
     End;
    Until CurrTime>EndTime;
   End
    Else
   C:=ReadKey;
   If(CheckCase)Then Begin
    For I:=1 to Length(ChoiceString)do If C=ChoiceString[I]Then Begin
     Found:=True;
     Halt(I);
     Break;
    End;
   End
    Else
   Begin
    For I:=1 to Length(ChoiceString)do If UpCase(C)=UpCase(ChoiceString[I])Then Begin
     Found:=True;
     Halt(I);
     Break;
    End;
   End;
  Until Found;
 End;
END.
