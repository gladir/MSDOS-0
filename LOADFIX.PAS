{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7)
}

Program LOADFIX;

Uses Dos;

Const
 BUFFER_SIZE=64*1024;  { 64 Ko }

Type
 TExecRec = record
  EnvStr: PChar;
  CmdLine: string;
  FCB1,
  FCB2: array[1..37] of Byte;
 End;

Var
 ExecPath:String;
 ExecParams:String;
 MemBlock:Pointer;

Procedure BuildCommandLine;
Var
 i:Integer;
Begin
 ExecPath:='';
 ExecParams:='';
 If ParamCount=0 Then Exit;
 ExecPath:=ParamStr(1);
 For i:=2 to ParamCount do ExecParams:=ExecParams+' '+ParamStr(i);
End;

Function AllocateBuffer:Boolean;
Var
 Regs:Registers;
 MaxMem:Word;
Begin
 AllocateBuffer:=False;
  { Obtient la taille maximale de m‚moire disponible }
 FillChar(Regs, SizeOf(Regs), 0);
 Regs.AH:=$48;
 Regs.BX:=$FFFF;
 Intr($21,Regs);
 MaxMem:=Regs.BX;  { Taille max en paragraphes }
  { Essaie d'allouer au-dessus de 64K }
 Repeat
  FillChar(Regs, SizeOf(Regs), 0);
  Regs.AH:=$48;  { Allocate memory }
  Regs.BX:=BUFFER_SIZE div 16;  { En paragraphes }
  Intr($21,Regs);
  If(Regs.Flags and 1)=0 Then Begin
   If Regs.AX>=$1000 Then Begin  { Au-dessus de 64K (4096) }
    MemBlock := Ptr(Regs.AX, 0);  { Segment:Offset }
    AllocateBuffer := True;
    Break;
   End;
    { LibŠre la m‚moire si trop basse }
   FillChar(Regs, SizeOf(Regs), 0);
   Regs.AH:=$49;  { LibŠre la m‚moire }
   Regs.ES:=Regs.AX;
   Intr($21,Regs);
  End;
 Until MaxMem<=(BUFFER_SIZE div 16);  { Plus assez de m‚moire }
End;

Procedure FreeBuffer;
Var
 Regs:Registers;
Begin
 If MemBlock<>NIL Then Begin
  FillChar(Regs,SizeOf(Regs),0);
  Regs.AH:=$49;  { LibŠre la m‚moire }
  Regs.ES:=Seg(MemBlock^);
  Intr($21,Regs);
 End;
End;

Function ExecuteProgram:Integer;
Var
 ExecRec:TExecRec;
Begin
 FillChar(ExecRec, SizeOf(ExecRec),0);
 With ExecRec do Begin
  EnvStr:=NIL;
  CmdLine:=ExecParams;
  {$I-}
  SwapVectors;
  Exec(ExecPath, ExecParams);
  SwapVectors;
  {$I+}
 End;
 ExecuteProgram:=DosError;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('LOADFIX - Cette commande permet de fixer le chargement au dessus du 64 Ko');
  WriteLn('Syntaxe: LOADFIX [drive:][path]filename [program-parameters] [/?]');
  WriteLn;
  WriteLn('  filename            Programme a charger');
  WriteLn('  program-parameters  Parametres du programme');
  WriteLn('  /?                  Affiche cette aide');
  Halt;
 End;
 BuildCommandLine;
 If Not(AllocateBuffer)Then Begin
  WriteLn('Erreur: Impossible d''allouer la memoire tampon');
  Halt(1);
 End;
  { Le tampon est allou‚, ce qui force le programme … charger au-dessus de 64 Ko }
 If ExecuteProgram<>0 Then WriteLn('Erreur lors de l''ex‚cution de ',ExecPath);
 FreeBuffer;
END.