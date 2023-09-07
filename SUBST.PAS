{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program SUBST;

Uses DOS;

Function ResolvePath(Var S:String):Boolean;
Var
 Regs:Registers;
 X:Byte;
Begin
 ResolvePath:=False;
 S:=S+#0;
 Regs.DS:=Seg(S);
 Regs.SI:=Word(Ofs(S))+1;
 Regs.ES:=Seg(S);
 Regs.DI:=Word(Ofs(S))+1;
 Regs.AH:=$60;
 Intr($21,Regs);
 If Regs.Flags and 1 = 1 Then Exit; { Si CF est fix‚ alors }
 ResolvePath:=True;
 X:=0;
 While(S[X+1]<>#0)and(X<128)do Inc(X);
 S[0]:=Chr(X);
End;

Var
 DriveName:String;
 C:Char;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('SUBST : Cette commande permet de cr‚er un disque virtuel ',
                    '… partir d''un r‚pertoire.');
  WriteLn;
  WriteLn('Syntaxe : SUBST [/?]');
  WriteLn;
  WriteLn('/?  Affiche l''aide sur cette commande.');
 End
  Else
 Begin
  For C:='A' to 'Z'do Begin
   DriveName:=C;
   If(ResolvePath(DriveName))Then Writeln(C,': => ',DriveName);
  End;
 End;
END.