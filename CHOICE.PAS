{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program Choice;

Uses Crt;

Var
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
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  Write('CHOICE : Cette commande permet de faire un choix.');
  WriteLn;
  WriteLn('Syntaxe : CHOICE [/C[:]choix] [/N]');
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