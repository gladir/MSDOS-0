{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program SUBST;

Uses DOS;

Var
 CurrentDrive:String;
 DriveName:String;
 C:Char;

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

Procedure SubstituteDrive(Drive:Char;Path:String);
Var
 Regs:Registers;
 DriveNum:Byte;
Begin
 Path:=Path+#0;
 DriveNum:=Ord(UpCase(Drive))-Ord('A');
 Regs.AX:=$71AA;
 Regs.BX:=DriveNum;
 Regs.DS:=Seg(Path[1]);
 Regs.SI:=Ofs(Path[1]);
 Regs.CX:=Length(Path);
 Regs.DL:=0;
 Intr($21,Regs);
 If Regs.Flags and FCarry<>0Then WriteLn('Erreur lors de la substitution de lecteur.')
                            Else WriteLn('Substitution de l''unit‚ de disque r‚ussie : ',Drive,' -> ',Path);
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('SUBST : Cette commande permet de cr‚er un disque virtuel ',
                    '… partir d''un r‚pertoire.');
  WriteLn;
  WriteLn('Syntaxe : SUBST [/?]');
  WriteLn('          SUBST drive1: [drive2:]path');
  WriteLn;
  WriteLn('  /?            Affiche l''aide sur cette commande.');
  WriteLn(' drive1:        Unit‚ de disque … associ‚');
  WriteLn(' drive2:[path]  Chemin … associ‚');
 End
  Else
 If ParamCount=2 Then Begin
  CurrentDrive:=ParamStr(1);
  If(Length(CurrentDrive)>2)or(Copy(CurrentDrive,2,1)<>':')Then Begin
   WriteLn('Unit‚ de disque de format invalide !');
   Halt(1);
  End;
  SubstituteDrive(UpCase(CurrentDrive[1]),ParamStr(2));
 End
  Else
 Begin
  For C:='A' to 'Z'do Begin
   DriveName:=C;
   If(ResolvePath(DriveName))Then Writeln(C,': => ',DriveName);
  End;
 End;
END.
