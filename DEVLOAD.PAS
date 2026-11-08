{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7)
  Charge un pilote de peripherique (commande DEVICE= de CONFIG.SYS) : le noyau lance
  DEVLOAD.EXE avec le chemin du pilote suivi de ses arguments.
}

Program DEVLOAD;

{$M 4096,0,0}

Uses DOS;

Type
 TRequest=Record
  Len,UnitNo,Cmd:Byte;
  Status:Word;
  Reserved:Array[0..7] of Byte;
  Units:Byte;
  BreakOfs,BreakSeg:Word;
  ArgOfs,ArgSeg:Word;
  Drive:Byte;
 End;

Var
 Req:TRequest;
 Line:Array[0..127] of Char;
 F:File;
 Regs:Registers;
 DrvSeg,Paras,Got,Chunk,N,Brk:Word;
 Size,Left:LongInt;
 I,L,S:Integer;
 Path:String;
 P:^Byte;
 LoLSeg,LoLOfs,NulSeg,NulOfs:Word;

{ Appel eloigne d'un point d'entree de pilote : ES:BX = requete }
Procedure CallDriver(DevSeg,EntryOfs,ReqSeg,ReqOfs:Word);Assembler;
ASM
 PUSH DS
 PUSH ES
 PUSH SI
 PUSH DI
 PUSH BP
 MOV AX,ReqSeg
 MOV BX,ReqOfs
 MOV CX,DevSeg
 MOV DX,EntryOfs
 PUSH CS
 MOV SI,OFFSET @Back
 PUSH SI
 PUSH CX
 PUSH DX
 MOV ES,AX
 RETF
@Back:
 POP BP
 POP DI
 POP SI
 POP ES
 POP DS
END;

Begin
 If ParamCount=0 Then Begin
  WriteLn('DEVLOAD : charge un pilote de peripherique.');
  WriteLn('Syntaxe : DEVLOAD pilote.sys [arguments]');
  Halt(1);
 End;
 { ligne de commande transmise au pilote : "chemin arguments" suivie de CR }
 L:=Mem[PrefixSeg:$80];
 S:=0;
 If (L>0) And (Mem[PrefixSeg:$81]=32) Then S:=1;
 I:=0;
 While (S<L) And (I<126) Do Begin
  Line[I]:=Chr(Mem[PrefixSeg:$81+S]);
  Inc(I);
  Inc(S);
 End;
 Line[I]:=#13;
 Path:=ParamStr(1);
 Assign(F,Path);
 {$I-}
 FileMode:=0;
 Reset(F,1);
 {$I+}
 If IOResult<>0 Then Begin
  WriteLn('Pilote introuvable : ',Path);
  Halt(1);
 End;
 Size:=FileSize(F);
 If (Size<18) Or (Size>60000) Then Begin
  Close(F);
  WriteLn('Pilote invalide : ',Path);
  Halt(1);
 End;
 Paras:=Word((Size+15) Div 16)+64;
 Regs.AH:=$48;
 Regs.BX:=Paras;
 MsDos(Regs);
 If (Regs.Flags And 1)<>0 Then Begin
  Close(F);
  WriteLn('Memoire insuffisante pour le pilote');
  Halt(1);
 End;
 DrvSeg:=Regs.AX;
 { le bloc appartient au systeme : il survit a la fin de DEVLOAD }
 MemW[DrvSeg-1:1]:=8;
 Left:=Size;
 N:=0;
 While Left>0 Do Begin
  If Left>8192 Then Chunk:=8192 Else Chunk:=Word(Left);
  P:=Ptr(DrvSeg+N*512,0);
  BlockRead(F,P^,Chunk,Got);
  If Got=0 Then Break;
  Dec(Left,Got);
  Inc(N);
 End;
 Close(F);
 { liste des listes : l'en-tete du pilote NUL est en LoL+22h, tete de la chaine }
 Regs.AH:=$52;
 MsDos(Regs);
 LoLSeg:=Regs.ES;
 LoLOfs:=Regs.BX;
 NulSeg:=LoLSeg;
 NulOfs:=LoLOfs+$22;
 { requete INIT }
 FillChar(Req,SizeOf(Req),0);
 Req.Len:=23;
 Req.BreakSeg:=DrvSeg+Paras;
 Req.ArgOfs:=Ofs(Line);
 Req.ArgSeg:=Seg(Line);
 Req.Drive:=3;
 CallDriver(DrvSeg,MemW[DrvSeg:6],Seg(Req),Ofs(Req));
 CallDriver(DrvSeg,MemW[DrvSeg:8],Seg(Req),Ofs(Req));
 If ((Req.Status And $8000)<>0) Or ((MemW[DrvSeg:4] And $8000)=0) Then Begin
  Regs.AH:=$49;
  Regs.ES:=DrvSeg;
  MsDos(Regs);
  If (Req.Status And $8000)<>0 Then WriteLn('Echec de l''initialisation du pilote : ',Path)
                               Else WriteLn('Pilote de bloc non pris en charge : ',Path);
  Halt(1);
 End;
 { taille residente : jusqu'a l'adresse de rupture rendue par INIT }
 If Req.BreakSeg>=DrvSeg Then Begin
  Brk:=Req.BreakSeg-DrvSeg+((Req.BreakOfs+15) Shr 4);
  If (Brk<>0) And (Brk<Paras) Then Begin
   Regs.AH:=$4A;
   Regs.ES:=DrvSeg;
   Regs.BX:=Brk;
   MsDos(Regs);
  End;
 End;
 { insertion dans la chaine, juste apres le pilote NUL }
 MemW[DrvSeg:0]:=MemW[NulSeg:NulOfs];
 MemW[DrvSeg:2]:=MemW[NulSeg:NulOfs+2];
 MemW[NulSeg:NulOfs]:=0;
 MemW[NulSeg:NulOfs+2]:=DrvSeg;
End.
