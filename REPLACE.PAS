{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program Replace;

Uses Crt,DOS;

Var
 Option:Set Of (_P);
 YesReplace:Boolean;
 I:Integer;
 Source,Target:String;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function FileExist(Name:String):Boolean;
Var
 Rec:SearchRec;
Begin
 FindFirst(Name,AnyFile,Rec);
 FileExist:=DosError=0;
End;

Function DeleteFile(Name:String):Boolean;
Var
 F:File;
Begin
 {$I-}
 Assign(F,Name);
 Erase(F);
 {$I+}
 DeleteFile:=IoResult=0;
End;

Function SplitFileName(s:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(S,D,N,E);
 Splitfilename:=N+E;
End;

Function CopyFile(Source,Target:String):Boolean;
Var
 SourceFile,TargetFile:File;
 RecordsRead:Integer;
 Buffer:Array[1..1000]of Byte;
Begin
 CopyFile:=False;
 Assign(SourceFile,Source);
 {$I-}Reset(SourceFile,1);{$I+}
 If IOResult<>0Then Begin
  WriteLn('Fichier source introuvable ',Source);
  Exit;
 End;
 Assign(TargetFile,Target);
 {$I-}Rewrite(TargetFile,1);
 BlockRead(SourceFile,Buffer,SizeOf(Buffer),RecordsRead);
 While RecordsRead>0 do Begin
  BlockWrite(TargetFile,Buffer,RecordsRead);
  BlockRead(SourceFile,Buffer,SizeOf(Buffer),RecordsRead);
 End;
 Close(SourceFile);
 Close(TargetFile);
 {$I+}
 CopyFile:=True;
End;

Function MoveFile(Source,Target:String):Boolean;
Var
 F:File;
Begin
 If(Source='')or(Target='')Then Begin
  MoveFile:=False;
  Exit;
 End;
 Source:=FExpand(Source);
 Target:=FExpand(Target);
 If(Source[1]<>Target[1])and(Source[2]=':')Then Begin { Unite de disque different ?}
   { Copie le fichier }
  MoveFile:=CopyFile(Source,Target);
   { Supprime le fichier }
  {$I-}Assign(F,Source);
  Erase(F);
  {$I+}
 End
  Else
 Begin
  {$I-}
  Assign(F,Source);
  Rename(F,Target);
  MoveFile:=IOResult=0;
  {$I+}
 End;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('REPLACE : Cette commande permet de remplacer un fichier.');
  WriteLn;
  WriteLn('Syntaxe : REPLACE source destination [/P]');
  WriteLn;
  WriteLn('  /P   Demande une confirmation avant de remplacer');
 End
  Else
 If ParamCount>=2Then Begin
  Option:=[];
  Source:='';
  Target:='';
  For I:=1 to ParamCount do Begin
   If StrToUpper(ParamStr(I))='/P'Then Include(Option,_P) Else
   If Source<>''Then Target:=FExpand(ParamStr(I))
                Else Source:=FExpand(ParamStr(I));
  End;
  YesReplace:=True;
  If FileExist(Target)Then Begin
   If(_P in Option)Then Begin
    Write('Remplacer ',Target,' (O/N) ? ');
    If ReadKey in['Y','y','O','o']Then Begin
     WriteLn('Oui');
     If Not DeleteFile(Target)Then Begin
      WriteLn('Impossible de remplacer le fichier cible : ',Target);
      Halt;
     End;
    End
     Else
    Begin
     YesReplace:=False;
     WriteLn('Non');
    End;
   End;
  End;
  If(YesReplace)Then Begin
   If Not MoveFile(Source,Target)Then Begin
    WriteLn('Erreur de remplacement du fichier.');
   End;
  End;
 End
  Else
 WriteLn('Nombre de parametre invalide');
END.