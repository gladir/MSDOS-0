{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal)
}

Program MEM;

Uses DOS;

Type 
 XMSRegs=Record                    
  AX,BX,DX,SI,Segment:Word;
 End;
 
Var 
 XMSPtr:Pointer;
 XMSErr:Byte;
 Used:Integer;
 TotalSize,TotalUsed,TotalFree:LongInt;

Function GetConvMemory:Word;
Var
 Regs:Registers;
Begin
 Regs.AX:=0;
 Intr($12,Regs);
 GetConvMemory:=Regs.AX;
End;

Function XMSInit:Boolean;
Var 
 Regs:Registers;
 xr:XMSRegs;
Begin
 Regs.AX:=$4300;             
 Intr($2F,Regs);
 If(Regs.AL=$80)Then Begin 
  Regs.AX:=$4310;               
  Intr($2F,Regs);
  XMSPtr:=Ptr(Regs.ES,Regs.BX);  
  XMSErr:=0;
  XMSInit:=True;             
 End
  Else                               
 XMSInit:=False;
End;

Procedure XMSCall(NumFonc:Byte;Var XRegs:XMSRegs);Begin
 Inline ( $8C / $D9 /                          { mov    cx,ds        *}
           $51 /                                { push   cx           *}
           $C5 / $BE / $04 / $00 /              { lds    di,[bp+0004] *}
           $8A / $66 / $08 /                    { mov    ah,[bp+0008] *}
           $8B / $9D / $02 / $00 /              { mov    bx,[di+0002] *}
           $8B / $95 / $04 / $00 /              { mov    dx,[di+0004] *}
           $8B / $B5 / $06 / $00 /              { mov    si,[di+0006] *}
           $8E / $5D / $08 /                    { mov    ds,[di+08]   *}
           $8E / $C1 /                          { mov    es,cx        *}
           $26 / $FF / $1E / XMSPtr /           { call   es:[XMSPtr]  *}
           $8C / $D9 /                          { mov    cx,ds        *}
           $C5 / $7E / $04 /                    { lds    di,[bp+04]   *}
           $89 / $05 /                          { mov    [di],ax      *}
           $89 / $5D / $02 /                    { mov    [di+02],bx   *}
           $89 / $55 / $04 /                    { mov    [di+04],dx   *}
           $89 / $75 / $06 /                    { mov    [di+06],si   *}
           $89 / $4D / $08 /                    { mov    [di+08],cx   *}
           $1F                                  { pop    ds           *}
        );
 If(XRegs.AX = 0)and(XRegs.BX >= 128)Then Begin
  XMSErr:=Lo(XRegs.BX)             
 End
  else
 XMSErr:=0;
End;

Function XMSUsed:Integer;
Var
 Used:Integer;
 Handle:Word;
 Xr:XMSRegs;                  
Begin
 Used:=0;
 For Handle:=0 to 65520 do Begin
  Xr.DX:=Handle;
  XmsCall(14,Xr);
  If Xr.AX=0 Then Break;
  Inc(Used,Xr.DX);
 End;
 XMSUsed:=Used;
End;

Function XMSFree:Integer;
Var 
 Xr:XMSRegs;                 
Begin
 XmsCall(8,Xr);                            
 XMSFree:=Xr.AX;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('MEM : Cette commande permet d''afficher les informations sur la mémoire.');
  WriteLn;
  WriteLn('Syntaxe : MEM');
 End
  Else
 Begin
   TotalSize:=0;TotalUsed:=0;TotalFree:=0;
   WriteLn('Type de memoire         Total = Utilise +    Libre');
   WriteLn('------------------- ---------   -------   --------- ');
   Inc(TotalSize,GetConvMemory);
   Inc(TotalUsed,GetConvMemory-(MemAvail shr 10));
   Inc(TotalFree,MemAvail shr 10);
   WriteLn('Conventionnel          ',GetConvMemory:5,'K',GetConvMemory-(MemAvail shr 10):9,'K',MemAvail shr 10:11,'K');
   If(XMSInit)Then Begin
    Used:=XMSUsed;
    Inc(TotalSize,Used+XMSFree);
    Inc(TotalUsed,Used);
    Inc(TotalFree,XMSFree);	
    WriteLn('Etendue (XMS)          ',Used+XMSFree:5,'K',Used:9,'K',XMSFree:11,'K');
   End;
   WriteLn('------------------- ---------   -------   --------- ');
   WriteLn('Memoire total          ',TotalSize:5,'K',TotalUsed:9,'K',TotalFree:11,'K');
  
 End;
END.