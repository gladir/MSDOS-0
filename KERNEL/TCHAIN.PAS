{$M 4096,0,0}
Program TCHAIN;
Uses DOS;
Var R:Registers; S,O,NS,NO:Word; I:Integer; C:Char;
Begin
 R.AH:=$52; MsDos(R);
 S:=R.ES; O:=R.BX+$22;
 Repeat
  Write('pilote ');
  For I:=0 to 7 do Write(Chr(Mem[S:O+10+I]));
  WriteLn(' attr=',MemW[S:O+4],' seg=',S);
  NS:=MemW[S:O+2]; NO:=MemW[S:O];
  S:=NS; O:=NO;
 Until (S=$FFFF) Or (S=0);
End.
