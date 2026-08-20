{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program MSAV;

{$M 16384,0,65536}

Uses Crt,DOS;

Const
 MaxPathLength=79;
 ScanBufferSize=512;
 ScanLimit=255;

Type
 TScanState=Record
  Files:LongInt;
  Scanned:LongInt;
  Infected:LongInt;
  Suspicious:LongInt;
  CurrentFile:String[79];
  CurrentDirectory:String[79];
  Stop:Boolean;
 End;

Var
 ScanState:TScanState;
 RootPath:String;
 Recursive:Boolean;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do
  If S[I]in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 StrToUpper:=S;
End;

Function PadRight(S:String;Space:Byte):String;
Begin
 While Length(S)<Space do S:=S+' ';
 If Length(S)>Space Then S:=Copy(S,1,Space);
 PadRight:=S;
End;

Function RepeatChar(C:Char;Count:Byte):String;
Var
 I:Byte;
 S:String;
Begin
 S:='';
 For I:=1 to Count do S:=S+C;
 RepeatChar:=S;
End;

Function JoinPath(Directory,Name:String):String;
Begin
 If(Directory<>'')and(Directory[Length(Directory)]<>'\')Then
  Directory:=Directory+'\';
 JoinPath:=Directory+Name;
End;

Function IsDOSProgram(Name:String):Boolean;
Var
 D,N,E:String;
Begin
 FSplit(Name,D,N,E);
 E:=StrToUpper(E);
 IsDOSProgram:=(E='.COM')or(E='.EXE')or(E='.SYS')or(E='.OVL');
End;

Function ContainsText(Buffer:String;Text:String):Boolean;
Begin
 ContainsText:=Pos(StrToUpper(Text),StrToUpper(Buffer))>0;
End;

Procedure DrawBar(X,Y,Width:Byte;Done,Total:LongInt);
Var
 Filled:Byte;
Begin
 GotoXY(X,Y);
 If Total>0 Then Filled:=Byte((Done*Width)div Total) Else Filled:=0;
 If Filled>Width Then Filled:=Width;
 TextColor(15);TextBackground(1);
 Write('[',RepeatChar(#219,Filled),RepeatChar(' ',Width-Filled),']');
 TextColor(0);TextBackground(7);
End;

Procedure DrawHeader;
Begin
 TextBackground(1);TextColor(15);ClrScr;
 GotoXY(1,1);Write(RepeatChar(' ',80));
 GotoXY(28,1);Write('Microsoft Anti-Virus');
 TextBackground(7);TextColor(0);
 GotoXY(1,3);Write(RepeatChar(' ',80));
 GotoXY(33,3);Write('Menu Express');
 GotoXY(1,25);TextBackground(1);TextColor(15);
 Write('F1 Aide   F2 Lecteur   F3 Quitter   F4 Detecter   F5 Options');
 TextBackground(7);TextColor(0);
End;

Procedure DrawScreen;
Begin
 DrawHeader;
 Window(2,4,78,23);
 TextBackground(7);TextColor(0);ClrScr;
 Window(1,1,80,25);
 TextBackground(7);TextColor(0);
 GotoXY(3,5);Write('Detecter');
 GotoXY(3,7);Write('Detecter & Nettoyer');
 GotoXY(3,9);Write('Selectionner un lecteur');
 GotoXY(3,11);Write('Options');
 GotoXY(3,13);Write('Quitter');
 TextColor(15);TextBackground(1);
 GotoXY(38,5);Write('Detecter');
 TextBackground(7);TextColor(0);
 GotoXY(38,7);Write('Recherche recursive des fichiers DOS');
 GotoXY(38,9);Write('Lecteur examine : ',RootPath);
 GotoXY(38,10);Write('Dernier fichier :');
 GotoXY(38,11);Write('Derniere action : Pret a commencer');
 GotoXY(38,13);Write('Fichiers trouves : ',ScanState.Files:6);
 GotoXY(38,14);Write('Fichiers examines: ',ScanState.Scanned:6);
 GotoXY(38,15);Write('Resultats        : ',ScanState.Infected:6,' alerte(s)');
 GotoXY(38,17);Write('Progression :');
 DrawBar(38,18,35,ScanState.Scanned,ScanState.Files);
 GotoXY(3,20);TextColor(4);Write('Microsoft');
 GotoXY(3,21);Write('Anti-Virus');
 TextColor(0);
End;

Procedure UpdateScreen(Action:String);
Begin
 GotoXY(38,10);Write(PadRight(Copy(ScanState.CurrentFile,1,39),39));
 GotoXY(38,11);Write(PadRight(Copy(Action,1,39),39));
 GotoXY(38,13);Write('Fichiers trouves : ',ScanState.Files:6);
 GotoXY(38,14);Write('Fichiers examines: ',ScanState.Scanned:6);
 GotoXY(38,15);Write('Resultats        : ',ScanState.Infected:6,' alerte(s)');
 DrawBar(38,18,35,ScanState.Scanned,ScanState.Files);
 GotoXY(3,23);Write(PadRight('Repertoire : '+Copy(ScanState.CurrentDirectory,1,68),76));
End;

Procedure CountFiles(DirPath:String);
Var
 Info:SearchRec;
 Child:String;
Begin
 FindFirst(JoinPath(DirPath,'*.*'),AnyFile,Info);
 While DOSERROR=0 do Begin
  If(Info.Name<>'.')and(Info.Name<>'..')Then Begin
  Child:=JoinPath(DirPath,Info.Name);
   If(Info.Attr and Directory<>0)Then Begin
    If Recursive Then CountFiles(Child);
   End
    Else Inc(ScanState.Files);
  End;
  FindNext(Info);
 End;
End;

Function ScanFile(FileName:String):Byte;
Var
 F:File;
 Buffer:Array[1..ScanBufferSize]of Char;
 ReadCount,TotalRead:Word;
 Header:String;
begin
 ScanFile:=0;
 Assign(F,FileName);
 {$I-}Reset(F,1);{$I+}
 If IOResult<>0 Then Exit;
 TotalRead:=0;Header:='';
 BlockRead(F,Buffer,ScanLimit,ReadCount);
 If ReadCount>0 Then Begin
  Header:=RepeatChar(#0,ReadCount);
  Move(Buffer,Header[1],ReadCount);
  TotalRead:=ReadCount;
 End;
 Close(F);
 If ContainsText(Header,'DARK AVENGER')or
    ContainsText(Header,'MICHELANGELO')or
    ContainsText(Header,'VIENNA')or
    ContainsText(Header,'STONED')or
    ContainsText(Header,'VIRUS')Then ScanFile:=2
  Else
 If IsDOSProgram(FileName)and(TotalRead>=2)and(Header[1]='M')and(Header[2]='Z')Then
  ScanFile:=1;
End;

Procedure ScanFiles(DirPath:String);
Var
 Info:SearchRec;
 Child:String;
 ResultCode:Byte;
 Key:Char;
Begin
 FindFirst(JoinPath(DirPath,'*.*'),AnyFile,Info);
 While(DOSERROR=0)and(Not ScanState.Stop)do Begin
  If(Info.Name<>'.')and(Info.Name<>'..')Then Begin
  Child:=JoinPath(DirPath,Info.Name);
   If(Info.Attr and Directory<>0)Then Begin
    If Recursive Then ScanFiles(Child);
   End
    Else Begin
    ScanState.CurrentFile:=Info.Name;
    ScanState.CurrentDirectory:=DirPath;
    ResultCode:=ScanFile(Child);
    Inc(ScanState.Scanned);
    If ResultCode=2 Then Begin
     Inc(ScanState.Infected);
     UpdateScreen('Alerte : signature suspecte');
    End
     Else
    If ResultCode=1 Then Begin
     Inc(ScanState.Suspicious);
     UpdateScreen('Programme DOS examine');
    End
     Else UpdateScreen('Fichier examine');
    If KeyPressed Then Begin
     Key:=ReadKey;
     If Key=#27 Then ScanState.Stop:=True;
    End;
   End;
  End;
  FindNext(Info);
 End;
End;

Procedure ShowHelp;
Begin
 ClrScr;TextColor(15);TextBackground(1);
 WriteLn('MSAV - Microsoft Anti-Virus pour DOS');
 TextBackground(7);TextColor(0);
 WriteLn;WriteLn('Analyse en lecture seule des fichiers du repertoire courant.');
 WriteLn;WriteLn('MSAV [chemin] [/S]');
 WriteLn;WriteLn('  chemin  Repertoire de depart, courant par defaut.');
 WriteLn('  /S      Parcourt aussi les sous-repertoires.');
 WriteLn;WriteLn('Echap interrompt l''analyse. Les alertes sont heuristiques.');
 WriteLn;WriteLn('Appuyez sur une touche pour continuer...');
 ReadKey;
End;

Procedure ReadParameters;
Var
 I:Byte;
 P:String;
Begin
 Recursive:=True;RootPath:='';
 For I:=1 to ParamCount do Begin
  P:=ParamStr(I);
  If(P='/?')or(StrToUpper(P)='-H')or(StrToUpper(P)='--HELP')or
    (StrToUpper(P)='/H')Then Begin ShowHelp;Halt;End;
  If StrToUpper(P)='/S' Then Recursive:=True Else
  If RootPath='' Then RootPath:=P;
 End;
 If RootPath='' Then GetDir(0,RootPath);
 RootPath:=FExpand(RootPath);
End;

Begin
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ENDIF}
 {$ENDIF}
 ReadParameters;
 FillChar(ScanState,SizeOf(ScanState),0);
 DrawScreen;
 GotoXY(38,11);Write('Comptage des fichiers...');
 CountFiles(RootPath);
 UpdateScreen('Analyse en cours');
 ScanFiles(RootPath);
 GotoXY(38,20);
 If ScanState.Stop Then Write('Analyse interrompue.') Else Write('Analyse terminee.');
 GotoXY(38,21);Write(ScanState.Infected,' alerte(s), ',ScanState.Suspicious,' programme(s) DOS.');
 GotoXY(38,23);Write('Appuyez sur une touche pour quitter.');
 ReadKey;
 TextBackground(0);TextColor(7);ClrScr;
End.