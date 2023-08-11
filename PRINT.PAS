{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program PRINT;

Uses DOS;

Var
 Mode:(_None,_C);
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

Procedure SubmitFileForPrinting(S:String);
Var
 Buffer:Record
  Level:Byte;
  P:Pointer;
 End;
 PBuffer:Array[0..257]of Char;
 Regs:Registers;
Begin
 FillChar(PBuffer,SizeOf(PBuffer),0);
 Move(S[1],PBuffer,Length(S));
 Buffer.Level:=0;
 Buffer.P:=@PBuffer;
 Regs.AX:=$0101;
 Regs.DS:=Seg(Buffer);
 Regs.DX:=Ofs(Buffer);
 Intr($2F,Regs);
End;

Procedure RemoveFileFromPrintQueue(S:String);
Var
 PBuffer:Array[0..257]of Char;
 Regs:Registers;
Begin
 FillChar(PBuffer,SizeOf(PBuffer),0);
 Move(S[1],PBuffer,Length(S));
 Regs.AX:=$0102;
 Regs.DS:=Seg(PBuffer);
 Regs.DX:=Ofs(PBuffer);
 Intr($2F,Regs);
End;

Procedure CancelAllFilesInQueue;
Var
 Regs:Registers;
Begin
 Regs.AX:=$0103;
 Intr($2F,Regs);
End;

BEGIN
 Mode:=_None;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('PRINT: Cette commande permet d''effectuer la gestion des ',
                 'traitements d''impressions du systŠme d''exploitation.');
  WriteLn;
  WriteLn('Syntaxe: PRINT [/C] [/T] [fichier]');
  WriteLn;
  WriteLn('/T  Ce paramŠtre permet d''annuler toutes les impressions.');
 End
  Else
 If ParamCount>0Then For I:=1 to ParamCount do Begin
  If StrToUpper(ParamStr(I))='/C'Then Mode:=_C Else
  If StrToUpper(ParamStr(I))='/T'Then Begin
   CancelAllFilesInQueue;
  End
   Else
  Begin
   If Mode=_C Then RemoveFileFromPrintQueue(ParamStr(I))
              Else SubmitFileForPrinting(ParamStr(I));
  End;
 End;
END.