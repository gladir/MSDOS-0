{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program XCopy;

Uses Crt,DOS;

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 Option:Set Of (_A,_P,_W);
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

Function IsWildCard(Path:String):Boolean;Begin
 IsWildCard:=(Pos('*',Path)>0)or(Pos('?',Path)>0)
End;

Procedure TruncAfterSemicolon(Var S:String);
Var
 I:Byte;
Begin
 For I:=1to Length(S)do If S[I]=';'Then Begin
  S[0]:=Chr(I-1);
  Exit;
 End;
End;

Function GetCurrentDisk:Char;
Var
 CurrentDir:String;
Begin
 GetDir(0,CurrentDir);
 GetCurrentDisk:=CurrentDir[1];
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

Function Path2Name(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2Name:=N;
End;

Function Path2Ext(Const Path:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 Path2Ext:=E;
End;

Function DirExist(Dir:String):Boolean;
Var
 Rec:SearchRec;
Begin
 If Length(Dir)=0Then DirExist:=True
  Else
 Begin
  TruncAfterSemicolon(Dir);
  If Dir[Length(Dir)]='\'Then Dir:=Dir+'*.*' Else
  If IsWildCard(Dir)Then Dir:=Path2Dir(Dir)+'*.*';
  FindFirst(Dir,Directory,Rec);
  DirExist:=DosError=0
 End;
End;

Function SetPath4AddFile(Path:String):String;Begin
 If Path=''Then GetDir(0,Path);
 If Path[Length(Path)]<>'\'Then Path:=Path+'\';
 SetPath4AddFile:=Path;
End;

Function Src2Target(Source,Target:String):String;
Var
 D:DirStr;
 SN,N:NameStr;
 SE,E:ExtStr;
 Path:String;
 I:Byte;
Begin
 If Target=''Then Begin
  FSplit(Source,D,N,E);
  Target:=N+E;
  Exit;
 End;
 If Path2Ext(Target)=''Then Begin{Destination seulement avec R'pertoire?}
  Target:=SetPath4AddFile(Target);
  FSplit(Source,D,N,E);
  Src2Target:=FExpand(Target+N+E);
  Exit;
 End;
 SN:=Path2Name(Source);SE:=Path2Ext(Source);
 FSplit(Target,D,N,E);
 If E='*'Then E:=Path2Ext(Source);
 If N='*'Then N:=Path2Name(Source);
  {Name *}
 I:=Pos('*',N);
 If I>0Then N:=Copy(N,I-1,255)+Copy(SN,I,255);
  { Name ? }
 Repeat
  I:=Pos('?',N);
  If I>0Then N[I]:=SN[I]
 Until I=0;
  { Extension * }
 I:=Pos('*',E);
 If I>0Then N:=Copy(E,I-1,255)+Copy(SE,I,255);
  { Extension ? }
 Repeat
  I:=Pos('?',E);
  If I>0Then E[I]:=SE[I]
 Until I=0;
 Path:=SetPath4AddFile(D)+N+E;
 If(Length(Path)>=1)and(Path[1]='\')Then Path:=GetCurrentDisk+':'+Path;
 Src2Target:=Path;
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

Function CopyFiles(Source,Target:String):Boolean;
Var
 Rec:SearchRec;
 TSource,TTarget:String;
Begin
 Source:=FExpand(Source);
 Target:=FExpand(Target);
 If Not DirExist(Target)Then Begin
  {$I-}
  MkDir(Target);
  If IoResult<>0Then Begin
   WriteLn('Erreur de creation de repertoire');
   CopyFiles:=False;
   Exit;
  End;
  {$I+}
 End;
 If IsWildCard(Source)Then Begin
  FindFirst(Source,AnyFile,Rec);
  While DosError=0do Begin
   TSource:=Path2Dir(Source)+Rec.Name;
   TTarget:=Src2Target(TSource,Target);
   If(Rec.Attr and Directory=Directory)Then Begin
    If Not((Rec.Name='.')or(Rec.Name='..')or(Rec.Name=''))Then Begin
     If Not CopyFiles(SetPath4AddFile(Path2Dir(Source)+Rec.Name)+'*.*',
               SetPath4AddFile(Target)+Rec.Name)Then Begin
      CopyFiles:=False;
      Exit;
     End;
    End;
   End
    Else
   Begin
    If(_A in Option)and(Rec.Attr<>Archive)Then Begin
     WriteLn('Le fichier ',TSource,' n''est pas un archive');
    End
     Else
    If(_P in Option)Then Begin
     Write('Copier ',TSource,' vers ',TTarget,' (O/N) ? ');
     If ReadKey in['Y','y','O','o']Then Begin
      WriteLn('Oui');
      CopyFile(TSource,TTarget);
     End
      Else
     WriteLn('Non');
    End
     Else
    Begin
     WriteLn(TSource,' -> ',TTarget);
     CopyFile(TSource,TTarget);
    End;
   End;
   FindNext(Rec);
  End;
 End
  Else
 CopyFile(Source,Target);
End;

BEGIN
 Language:=_French;
 TmpLanguage:=GetEnv('LANGUAGE');
 If TmpLanguage<>''Then Begin
  If TmpLanguage[1]='"'Then TmpLanguage:=Copy(TmpLanguage,2,255);
  If StrToUpper(Copy(TmpLanguage,1,2))='EN'Then Language:=_English Else
  If StrToUpper(Copy(TmpLanguage,1,2))='GR'Then Language:=_Germany Else
  If StrToUpper(Copy(TmpLanguage,1,2))='IT'Then Language:=_Italian Else
  If StrToUpper(Copy(TmpLanguage,1,2))='SP'Then Language:=_Spain;
 End;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  Case Language of
   _Germany:Begin
    WriteLn('Kopiert Dataien (auáer versteckten u. Systemdateien) und Verzeichnisstrukturen.');
    WriteLn;
    WriteLn('XCOPY Quelle [Ziel] [/A] [/P] [/W]');
    WriteLn;
    WriteLn('Quelle      Zu kopierende Dateien.');
    WriteLn('Ziel        Position und/oder Name der neuen Dateien.');
    WriteLn('/A          Kopiert Dateien mit gesetztem Archivattribut, ');
    WriteLn('            „ndert das Attribut nicht.');
    WriteLn('/P          Fragt vor dem Erstellen jeder Zeildatei nach.');
    WriteLn('/W          Fordert vor dem Beginn des Kopierens zu einum Tastendruck auf.');
   End;
   _English:Begin
    WriteLn('Copies files (except hidden and system files) and directory trees.');
    WriteLn;
    WriteLn('XCOPY source [destination] [/A] [/P] [/W]');
    WriteLn;
    WriteLn('source       Specifies the file(s) to copy.');
    WriteLn('destination  Specifies the location and/or name of new files.');
    WriteLn('/A           Copies files with the archive attribute set,');
    WriteLn('             doesn''t change the attribute.');
    WriteLn('/P           Prompts you before creating each destination file.');
    WriteLn('/W           Prompts you to press a key before copying.');
   End;
   Else Begin
    WriteLn('XCOPY : Cette commande permet de copier des fichiers.');
    WriteLn;
    WriteLn('Syntaxe : XCOPY source destination [/A] [/P] [/W]');
    WriteLn;
    WriteLn('    /A     Copie uniquement les fichiers d''attribut archive');
    WriteLn('    /P     Demande une confirmation avant chaque fichier');
    WriteLn('    /W     Affiche un message avant de commencer la copie');
   End;
  End;
 End
  Else
 If ParamCount>=2Then Begin
  Option:=[];
  Source:='';
  Target:='';
  For I:=1 to ParamCount do Begin
   If StrToUpper(ParamStr(I))='/A'Then Include(Option,_A) Else
   If StrToUpper(ParamStr(I))='/P'Then Include(Option,_P) Else
   If StrToUpper(ParamStr(I))='/W'Then Include(Option,_W) Else
   If Source<>''Then Target:=ParamStr(I)
                Else Source:=ParamStr(I);
  End;
  If(_W in Option)Then Begin
   WriteLn('Appuyez sur une touche pour lancer la copie des fichiers');
   ReadKey;
  End;
  If Not CopyFiles(Source,Target)Then Begin
   WriteLn('Erreur de copie du fichier.');
  End;
 End
  Else
 WriteLn('Nombre de parametre invalide');
END.
