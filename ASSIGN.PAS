{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7)
}

Program _ASSIGN;

Uses DOS;

Var
 Language:(_Albanian,_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage,CurrParam:String;
 I,Offset:Integer;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function AssignIsInstalled:Boolean;
Var
 Regs:Registers;
Begin
 Regs.AX:=$0600;
 Intr($2F,Regs);
 AssignIsInstalled:=(Regs.Flags and 1=0)and(Regs.AL=$FF);
End;

Function GetSegmentAssign:Word;
Var
 Regs:Registers;
Begin
 Regs.AX:=$0601;
 Intr($2F,Regs);
 GetSegmentAssign:=Regs.ES;
End;

Function SetLetter(DriveX,DriveY:Integer):Boolean;Begin
 SetLetter:=False;
 If(DriveX<1)or(DriveX>26)Then Exit;
 If(DriveY<1)or(DriveY>26)Then Exit;
 {$IFDEF FPC}
  WriteLn('Non impl‚ment‚ en Free Pascal');
 {$ELSE}
  Mem[GetSegmentAssign:$102+DriveX]:=DriveY;
 {$ENDIF}
 SetLetter:=True;
End;

BEGIN
 Language:=_French;
 TmpLanguage:=GetEnv('LANGUAGE');
 If TmpLanguage<>''Then Begin
  If TmpLanguage[1]='"'Then TmpLanguage:=Copy(TmpLanguage,2,255);
  If StrToUpper(Copy(TmpLanguage,1,2))='EN'Then Language:=_English Else
  If StrToUpper(Copy(TmpLanguage,1,2))='GR'Then Language:=_Germany Else
  If StrToUpper(Copy(TmpLanguage,1,2))='IT'Then Language:=_Italian Else
  If StrToUpper(Copy(TmpLanguage,1,2))='SP'Then Language:=_Spain Else
  If(StrToUpper(Copy(TmpLanguage,1,2))='SQ')or
    (StrToUpper(Copy(TmpLanguage,1,3))='ALB')Then Language:=_Albanian;
 End;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  Case Language of
   _Albanian:Begin
    WriteLn('ASSIGN : Kjo komand‰ ju lejon t‰ krijoni nj‰ disk virtual ',
                      'nga nj‰ disk tjet‰r.');
    WriteLn;
    WriteLn('Sintaksa: ASSIGN [/STATUS|/A] [x=y] [x:=y:]');
    WriteLn;
    WriteLn(' x         Disku virtual');
    WriteLn(' y         Disk i v‰rtet‰');
    WriteLn(' /STATUS   Shfaq list‰n e detyrave t‰ disqeve');
   End;
   Else Begin
    WriteLn('ASSIGN : Cette commande permet de cr‚er un disque virtuel ',
                      '… partir d''un autre disque.');
    WriteLn;
    WriteLn('Syntaxe : ASSIGN [/STATUS|/A] [x=y] [x:=y:]');
    WriteLn;
    WriteLn(' x        Unit‚ de disque virtuelle');
    WriteLn(' y        Unit‚ de disque r‚el');
    WriteLn(' /STATUS  Affiche la liste des affectations d''unit‚s de disque');
   End;
  End;
 End
  Else
 If ParamCount>0 Then Begin
  For I:=1 to ParamCount do Begin
   CurrParam:=ParamStr(I);
   If(Length(CurrParam)=3)and
     (CurrParam[1]in['A'..'Z','a'..'z'])and
     (CurrParam[2]='=')and
     (CurrParam[3]in['A'..'Z','a'..'z'])Then Begin
    SetLetter(Byte(CurrParam[1])-64,Byte(CurrParam[3])-64);
   End
    Else
   If(Length(CurrParam)=5)and
     (CurrParam[1]in['A'..'Z','a'..'z'])and
     (CurrParam[2]=':')and
     (CurrParam[3]='=')and
     (CurrParam[4]in['A'..'Z','a'..'z'])and
     (CurrParam[5]=':')Then Begin
    SetLetter(Byte(CurrParam[1])-64,Byte(CurrParam[4])-64);
   End
    Else
   If(StrToUpper(CurrParam)='/STATUS')or
     (StrToUpper(CurrParam)='/A')Then Begin
    If(AssignIsInstalled)Then Begin
     For Offset:=1 to 26 do Begin
      {$IFDEF FPC}
       WriteLn('Non impl‚ment‚ en Free Pascal');
      {$ELSE}
       If(Mem[GetSegmentAssign:$102+Offset]=I)Then Begin
        WriteLn(Chr(64+I),': => ',Chr(64+Mem[GetSegmentAssign:$102+Offset]),':');
       End;
      {$ENDIF}
     End;
    End
     Else
    WriteLn('ASSIGN non-install‚');
   End
    Else
   Begin
   End;
  End;
 End
  Else
 WriteLn('ParamŠtre attendu');
END.
