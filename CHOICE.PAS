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
 OptionFlag:(_None,_C);
 NoPrompt,Found,CheckCase:Boolean;
 I:Integer;
 C:Char;
 ChoiceString,TextString:String;

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
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  Case Language of
   _English:Begin
    WriteLn('CHOICE : Waits for you to choose one of a set of choices.');
    WriteLn;
    WriteLn('Formats: CHOICE [/C[:]choices] [/N] [/S]');
    WriteLn;
    WriteLn('/C[:]choices  Specifies allowable keys. Default is YN.');
    WriteLn('/N            Does not display choices and ? at end of prompt string.');
    WriteLn('/S            Treats choice keys as case sensitive.');
   End;
   Else Begin
    WriteLn('CHOICE : Cette commande permet de faire un choix.');
    WriteLn;
    WriteLn('Syntaxe : CHOICE [/C[:]choix] [/N] [/S]');
   End;
  End;
 End
  Else
 Begin
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
  If ChoiceString=''Then ChoiceString:='ON';
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
