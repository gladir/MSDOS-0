Program TVER;
Uses DOS;
Var R:Registers; V:Boolean;
Begin
 R.AH:=$54; MsDos(R); WriteLn('avant AL=',R.AL);
 R.AH:=$2E; R.AL:=1; R.DL:=0; MsDos(R); WriteLn('apres set AL=',R.AL);
 R.AH:=$54; MsDos(R); WriteLn('relu AL=',R.AL);
 GetVerify(V); WriteLn(V);
 SetVerify(True); GetVerify(V); WriteLn(V);
End.
