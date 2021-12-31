{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program DELTREE;

Uses Crt,DOS;

Var
 Question:Boolean;
 I:Integer;

Procedure DeleteFile(FileName:String);
Var
 F:File;
Begin
 {$I-}Assign(F,FileName);
 Erase(F);
 {$I+}
End;

Procedure DeleteTree(Dir:String);
Var
 Info:SearchRec;
Begin
 FindFirst(Dir+'\*.*',AnyFile,Info);
 While DOSError=0do Begin
  If Info.Attr and Directory=Directory Then Begin
   If(Info.Name<>'.')and(Info.Name<>'..')Then DeleteTree(Dir+'\'+Info.Name);
  End
   Else
  Begin
   If(Question)Then Begin
    Write('Supprimer ',Info.Name,' (O/N) ? ');
    Case ReadKey of
     #27:Exit;
     'O','o':Begin
      DeleteFile(Dir+'\'+Info.Name);
      Write('Oui');
     End;
     Else Write('Non');
    End;
    WriteLn;
   End
    Else
   DeleteFile(Dir+'\'+Info.Name);
  End;
  FindNext(Info);
 End;
 {$I-}RmDir(Dir);{$I+}
END;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  Write('DELTREE : Cette commande permet de supprimer un repertoire ',
        'avec ses fichiers et repertoire.');
  WriteLn;
  WriteLn('Syntaxe : DELTREE repertoire [/Y]');
 End
  Else
 If ParamCount>0Then Begin
  Question:=False;
  For I:=1 to ParamCount do Begin
   If(ParamStr(I)='/Y')or(ParamStr(I)='/y')Then Question:=True;
  End;
  For I:=1 to ParamCount do Begin
   If Not((ParamStr(I)='/Y')or(ParamStr(I)='/y'))Then DeleteTree(ParamStr(I));
  End;
 End
  Else
 WriteLn('Parametre requis !');
END.