{$M 4096,0,0}
Program TCFG;
Uses DOS;
Var R:Registers; H:Array[1..30] of Word; N,I:Integer; T:String;
Begin
 N:=0;
 For I:=1 to 30 do Begin
  R.AX:=$3D00; R.DS:=Seg(T); R.DX:=Ofs(T)+1;
  T:='LISEZ.TXT'#0;
  Intr($21,R);
  If (R.Flags And 1)<>0 Then Break;
  H[I]:=R.AX; Inc(N);
 End;
 WriteLn('ouverts=',N);
 For I:=1 to N do Begin R.AH:=$3E; R.BX:=H[I]; Intr($21,R); End;
 R.AX:=$0E02; R.DX:=2; Intr($21,R);
 WriteLn('lecteurs=',R.AX And $FF);
 WriteLn('queue=[',ParamStr(1),']');
 WriteLn('COMSPEC=',GetEnv('COMSPEC'));
End.
