{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program Tree;

Uses DOS;

Var
 LevelState:Array[0..255]of Boolean;
 I:Byte;

Function SetPath4AddFile(Path:String):String;Begin
 If Path=''Then GetDir(0,Path);
 If Path[Length(Path)]<>'\'Then Path:=Path+'\';
 SetPath4AddFile:=Path;
End;

Function Path2Dir(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 Path2Dir:='';
 If Path=''Then Exit;
 FSplit(Path,D,N,E);
 If E=''Then Begin
  If D[Length(D)]<>'\'Then D:=D+'\';
  D:=D+E;
 End;
 If D=''Then Path2Dir:='' Else
 If D[Length(D)]<>'\'Then D:=D+'\';
 Path2Dir:=D;
End;

Function FindCount(CurrDir:String):Word;
Var
 I:Integer;
 Rec:SearchRec;
Begin
 I:=0;
 FindFirst(CurrDir,Directory,Rec);
 While DosError=0do Begin
  If(Rec.Attr and Directory=Directory)Then Begin
   If Not((Rec.Name='.')or(Rec.Name='..')or(Rec.Name=''))Then Begin
    Inc(I);
   End;
  End;
  FindNext(Rec);
 End;
 FindCount:=I;
End;

Procedure ShowTree(Position:Byte;CurrDir:String);
Var
 I,CurrEntry,Count:Integer;
 Rec:SearchRec;
Begin
 Count:=FindCount(CurrDir);
 CurrEntry:=0;
 FindFirst(CurrDir,Directory,Rec);
 While DosError=0do Begin
  LevelState[Position]:=CurrEntry+1<Count;
   If(Rec.Attr and Directory=Directory)Then Begin
   If Not((Rec.Name='.')or(Rec.Name='..')or(Rec.Name=''))Then Begin
    Inc(CurrEntry);
    For I:=1 to Position do Begin
     If LevelState[I]Then Write('    |')
                     Else Write(' ':4);
    End;
    If(CurrEntry>=Count)Then WriteLn('+---',Rec.Name)
                        Else WriteLn('---',Rec.Name);
    ShowTree(Position+1,SetPath4AddFile(Path2Dir(CurrDir)+Rec.Name)+'*.*');
   End;
  End;
  FindNext(Rec);

 End;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('TREE : Cette commande permet d''afficher un arbre de repertoire.');
  WriteLn;
  WriteLn('Syntaxe : TREE [repertoire]');
  WriteLn;
 End
  Else
 Begin
  For I:=0 to 255 do LevelState[I]:=False;
  If ParamCount>1Then WriteLn('Trop de parametre')Else
  If ParamCount=1Then Begin
   WriteLn(FExpand(ParamStr(1)));
   ShowTree(1,FExpand(ParamStr(1)+'*.*'));
  End
   Else
  Begin
   WriteLn(FExpand(''));
   ShowTree(1,FExpand('*.*'));
  End;
 End;
END.