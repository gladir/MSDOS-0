{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program _APPEND;

Uses DOS;

Var
 Regs:Registers;
 I:Integer;
 C:Char;

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
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('APPEND : Cette commande permet d''ouvrir des fichiers ',
          'quelques se trouvant dans les rÇpertoires spÇcifiÇs ',
          'comme s''il s''agissait du rÇpertoire courant.');
  WriteLn;
  WriteLn('Syntaxe : APPEND [/E] [/PATH:ON|OFF] [/X:ON|OFF]');
 End
  Else
 If ParamCount>0 Then Begin
  For I:=1 to ParamCount do Begin
   If StrToUpper(ParamStr(I))='/E'Then Begin
    Regs.AX:=$B700;
    Intr($2F,Regs);
    Regs.AX:=$B707;
    Regs.BX:=Regs.BX or (1 shl 14);
    Intr($2F,Regs);
   End
    Else
   If StrToUpper(ParamStr(I))='/PATH:OFF'Then Begin
    Regs.AX:=$B700;
    Intr($2F,Regs);
    Regs.AX:=$B707;
    Regs.BX:=Regs.BX and Not(1 shl 13);
    Intr($2F,Regs);
   End
    Else
   If StrToUpper(ParamStr(I))='/PATH:ON'Then Begin
    Regs.AX:=$B700;
    Intr($2F,Regs);
    Regs.AX:=$B707;
    Regs.BX:=Regs.BX or (1 shl 13);
    Intr($2F,Regs);
   End
    Else
   If StrToUpper(ParamStr(I))='/X:OFF'Then Begin
    Regs.AX:=$B700;
    Intr($2F,Regs);
    Regs.AX:=$B707;
    Regs.BX:=Regs.BX and Not(1 shl 15);
    Intr($2F,Regs);
   End
    Else
   If StrToUpper(ParamStr(I))='/X:ON'Then Begin
    Regs.AX:=$B700;
    Intr($2F,Regs);
    Regs.AX:=$B707;
    Regs.BX:=Regs.BX or (1 shl 15);
    Intr($2F,Regs);
   End
    Else
   Begin
    WriteLn('Le paramätre ',ParamStr(I),' n''est pas reconnu.');
    Halt;
   End;
  End;
 End
  Else
 Begin
  Regs.AX:=$B704;
  Intr($2F,Regs);
  If(Regs.ES=0)and(Regs.DI=0)Then Begin
   WriteLn('Aucun chemin de recherche pour APPEND');
  End
   Else
  Begin
   {$IFNDEF FPC}
    I:=0;
    Repeat
     C:=Char(Mem[Regs.ES:Regs.DI+I]);
     Write(C);
     Inc(I);
    Until C=#0;
   {$ENDIF}
   WriteLn;
  End;
 End;
END.