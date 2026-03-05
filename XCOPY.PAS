{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program XCopy;

Uses Crt,DOS;

Var
 Language:(_French,_English,_Germany,_Italian,_Spain,_Albanian,_Portuguese,_Swedish,_Danish,_Japanese);
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
  If StrToUpper(Copy(TmpLanguage,1,2))='SP'Then Language:=_Spain Else
  If StrToUpper(Copy(TmpLanguage,1,2))='AL'Then Language:=_Albanian Else
  If StrToUpper(Copy(TmpLanguage,1,2))='PT'Then Language:=_Portuguese Else
  If StrToUpper(Copy(TmpLanguage,1,2))='SV'Then Language:=_Swedish Else
  If StrToUpper(Copy(TmpLanguage,1,2))='DA'Then Language:=_Danish Else
  If StrToUpper(Copy(TmpLanguage,1,2))='JA'Then Language:=_Japanese;
 End;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  Case Language of
   _Germany:Begin
    WriteLn('Kopiert Dataien (au�er versteckten u. Systemdateien) und Verzeichnisstrukturen.');
    WriteLn;
    WriteLn('XCOPY Quelle [Ziel] [/A] [/P] [/W]');
    WriteLn;
    WriteLn('Quelle      Zu kopierende Dateien.');
    WriteLn('Ziel        Position und/oder Name der neuen Dateien.');
    WriteLn('/A          Kopiert Dateien mit gesetztem Archivattribut, ');
    WriteLn('            �ndert das Attribut nicht.');
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
   _Italian:Begin
    WriteLn('Copia file (eccetto file nascosti e di sistema) e strutture di directory.');
    WriteLn;
    WriteLn('XCOPY origine [destinazione] [/A] [/P] [/W]');
    WriteLn;
    WriteLn('origine      Specifica i file da copiare.');
    WriteLn('destinazione Specifica la posizione e/o nome dei nuovi file.');
    WriteLn('/A           Copia file con attributo archivio impostato,');
    WriteLn('             non cambia l''attributo.');
    WriteLn('/P           Chiede conferma prima di creare ogni file di destinazione.');
    WriteLn('/W           Chiede di premere un tasto prima di copiare.');
   End;
   _Spain:Begin
    WriteLn('Copia archivos (excepto archivos ocultos y del sistema) y árboles de directorios.');
    WriteLn;
    WriteLn('XCOPY origen [destino] [/A] [/P] [/W]');
    WriteLn;
    WriteLn('origen       Especifica los archivos a copiar.');
    WriteLn('destino      Especifica la ubicación y/o nombre de los nuevos archivos.');
    WriteLn('/A           Copia archivos con el atributo de archivo establecido,');
    WriteLn('             no cambia el atributo.');
    WriteLn('/P           Pide confirmación antes de crear cada archivo de destino.');
    WriteLn('/W           Pide presionar una tecla antes de copiar.');
   End;
   _Albanian:Begin
    WriteLn('Kopjon skedarë (përveç skedarëve të fshehur dhe sistemit) dhe pemët e drejtorive.');
    WriteLn;
    WriteLn('XCOPY burimi [destinacioni] [/A] [/P] [/W]');
    WriteLn;
    WriteLn('burimi       Specifikon skedarët për të kopjuar.');
    WriteLn('destinacioni Specifikon vendndodhjen dhe/ose emrin e skedarëve të rinj.');
    WriteLn('/A           Kopjon skedarë me atributin e arkivit të vendosur,');
    WriteLn('             nuk ndryshon atributin.');
    WriteLn('/P           Kërkon konfirmim para se të krijojë çdo skedar destinacion.');
    WriteLn('/W           Kërkon të shtypni një çelës para se të kopjoni.');
   End;
   _Portuguese:Begin
    WriteLn('Copia arquivos (exceto arquivos ocultos e do sistema) e árvores de diretórios.');
    WriteLn;
    WriteLn('XCOPY origem [destino] [/A] [/P] [/W]');
    WriteLn;
    WriteLn('origem       Especifica os arquivos a serem copiados.');
    WriteLn('destino      Especifica a localização e/ou nome dos novos arquivos.');
    WriteLn('/A           Copia arquivos com o atributo de arquivo definido,');
    WriteLn('             não altera o atributo.');
    WriteLn('/P           Solicita confirmação antes de criar cada arquivo de destino.');
    WriteLn('/W           Solicita pressionar uma tecla antes de copiar.');
   End;
   _Swedish:Begin
    WriteLn('Kopierar filer (utom dolda och systemfiler) och katalogträd.');
    WriteLn;
    WriteLn('XCOPY källa [mål] [/A] [/P] [/W]');
    WriteLn;
    WriteLn('källa        Anger filerna som ska kopieras.');
    WriteLn('mål          Anger platsen och/eller namnet på nya filer.');
    WriteLn('/A           Kopierar filer med arkivattributet inställt,');
    WriteLn('             ändrar inte attributet.');
    WriteLn('/P           Frågar innan varje målfil skapas.');
    WriteLn('/W           Frågar att trycka på en tangent innan kopiering.');
   End;
   _Danish:Begin
    WriteLn('Kopierer filer (undtagen skjulte og systemfiler) og mappestrukturer.');
    WriteLn;
    WriteLn('XCOPY kilde [destination] [/A] [/P] [/W]');
    WriteLn;
    WriteLn('kilde        Angiver filerne der skal kopieres.');
    WriteLn('destination  Angiver placeringen og/eller navnet på nye filer.');
    WriteLn('/A           Kopierer filer med arkivattributten sat,');
    WriteLn('             ændrer ikke attributten.');
    WriteLn('/P           Spørger før hver destinationsfil oprettes.');
    WriteLn('/W           Spørger om at trykke på en tast før kopiering.');
   End;
   _Japanese:Begin
    WriteLn('Fairu (kakureta fairu to shisutemu fairu ijo) to direkutori tsuri wo kopi shimasu.');
    WriteLn;
    WriteLn('XCOPY gensen [mokutekichi] [/A] [/P] [/W]');
    WriteLn;
    WriteLn('gensen       Kopi suru fairu wo shitei shimasu.');
    WriteLn('mokutekichi  Atarashi fairu no basho oyobi/mata wa namae wo shitei shimasu.');
    WriteLn('/A           Akaibu zokusei ga setto sareta fairu wo kopi shimasu,');
    WriteLn('             zokusei wa kaemasen.');
    WriteLn('/P           Kakaku mokuteki fairu wo sakusei suru mae ni kakunin wo motomemasu.');
    WriteLn('/W           Kopi mae ni kii wo osu you ni motomemasu.');
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
