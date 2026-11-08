Program TUP;
Var L:String; I:Byte; N:Word;
Begin
 N:=0;
 While Not Eof(Input) Do Begin
  ReadLn(L);
  For I:=1 To Length(L) Do L[I]:=UpCase(L[I]);
  Inc(N);
  WriteLn(N,': ',L);
 End;
 WriteLn('fin');
End.
