{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7)
}

Program POWER;

Var
 I:Integer;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function SetAPMMode(Mode:Word):Boolean;Assembler;ASM
  { Connecter l'interface RM }
 MOV AX,5301h
 XOR BX,BX
 INT 15h
  { Active le pilote APM 1.1 }
 MOV AX,530Eh
 XOR BX,BX
 MOV CX,0101h
 INT 15h
  { Active l'APM }
 MOV AX,5308h
 MOV BX,1
 MOV CX,BX
 INT 15h
  { Demande la mode spÇcifier }
 MOV AX,5307h
 mov BX,1
 MOV CX,Mode
 INT 15h
 MOV AL,0
 JC  @Error
 MOV AL,True
@Error:
@End:
END;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('POWER: Cette commande permet de fixer ou de ',
                  'demander les paramätres d''Çconomiseur ',
                  'd''Çnergie du systäme d''exploitation.');
  WriteLn;
  WriteLn('Syntaxe: POWER ADV:MAX|MIN|OFF|REG|STD');
  WriteLn;
  WriteLn('OFF  Ce paramätre permet d''Çteindre l''ordinateur.');
 End
  Else
 If ParamCount>0 Then Begin
  For I:=1 to ParamCount do Begin
   If StrToUpper(ParamStr(I))='ADV:MIN'Then SetAPMMode(2)Else
   If StrToUpper(ParamStr(I))='ADV:OFF'Then SetAPMMode(3)Else
   If StrToUpper(ParamStr(I))='ADV:MAX'Then SetAPMMode(0)Else
   If StrToUpper(ParamStr(I))='ADV:REG'Then SetAPMMode(0)Else
   If StrToUpper(ParamStr(I))='ADV:STD'Then SetAPMMode(0)
    Else
   Begin
    WriteLn('Paramätre inconnu ',ParamStr(I),'!');
    Halt;
   End;
  End;
 End;
END.