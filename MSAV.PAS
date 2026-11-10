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
{ Signatures de virus : stockees chiffrees (XOR + decalage selon la
  position) pour que le programme ne contienne aucune signature en clair ;
  elles sont dechiffrees uniquement au moment de l'analyse }
 SigCount=5;
 SigKey=$A5;
 SigLength:Array[0..SigCount-1]of Byte=(12,12,6,6,5);
 SigData:Array[0..40]of Byte=(
  $E1,$ED,$C5,$C5,$99,$C1,$25,$D3,$23,$23,$2E,$3A,
  $04,$01,$00,$14,$10,$66,$1A,$76,$76,$7D,$43,$55,
  $5B,$5D,$5E,$AE,$B7,$A9,$80,$88,$8A,$90,$96,$9C,
  $F7,$E9,$F9,$C3,$CE);

Const
 MenuCount=5;
 MenuText:Array[0..4]of String[24]=('Detecter','Detecter & Nettoyer',
  'Selectionner un lecteur','Options','Quitter');
 MenuDesc:Array[0..4]of String[40]=('Recherche des fichiers infectes',
  'Detecte et isole les fichiers infectes','Choisit le lecteur a examiner',
  'Modifie les options de l''analyse','Retourne au DOS');

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
 ReportDos:Boolean;
 CleanMode:Boolean;
 MenuSel:Integer;
 Isolated:LongInt;

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
 D:DirStr;N:NameStr;E:ExtStr;
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
 GotoXY(34,1);Write('MS Anti-Virus');
 TextBackground(7);TextColor(0);
 GotoXY(1,3);Write(RepeatChar(' ',80));
 GotoXY(33,3);Write('Menu Express');
 GotoXY(1,25);TextBackground(1);TextColor(15);
 Write('F1 Aide   F2 Lecteur   F3 Quitter   F4 Detecter   F5 Options');
 TextBackground(7);TextColor(0);
End;

{ Menu de gauche (element choisi en surbrillance) et description a droite }
Procedure DrawMenu;
Var
 I:Integer;
Begin
 For I:=0 to MenuCount-1 do Begin
  GotoXY(3,5+I*2);
  If I=MenuSel Then Begin TextColor(15);TextBackground(1);End
               Else Begin TextColor(0);TextBackground(7);End;
  Write(PadRight(MenuText[I],24));
 End;
 TextBackground(7);TextColor(0);
 GotoXY(38,5);TextColor(15);TextBackground(1);
 Write(PadRight(MenuText[MenuSel],30));
 TextBackground(7);TextColor(0);
 GotoXY(38,7);Write(PadRight(MenuDesc[MenuSel],39));
End;

Procedure DrawScreen;
Begin
 DrawHeader;
 Window(2,4,78,23);
 TextBackground(7);TextColor(0);ClrScr;
 Window(1,1,80,25);
 TextBackground(7);TextColor(0);
 DrawMenu;
 GotoXY(38,9);Write('Lecteur examine : ',RootPath);
 GotoXY(38,10);Write('Dernier fichier :');
 GotoXY(38,11);Write('Derniere action : Pret a commencer');
 GotoXY(38,13);Write('Fichiers trouves : ',ScanState.Files:6);
 GotoXY(38,14);Write('Fichiers examines: ',ScanState.Scanned:6);
 GotoXY(38,15);Write('Resultats        : ',ScanState.Infected:6,' alerte(s)');
 GotoXY(38,17);Write('Progression :');
 DrawBar(38,18,35,ScanState.Scanned,ScanState.Files);
 GotoXY(3,20);TextColor(4);Write('MS');
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
 GotoXY(3,23);Write(PadRight('Repertoire : '+Copy(ScanState.CurrentDirectory,1,
   68),76));
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

{ Dechiffre la signature numero Index (0..SigCount-1) }
Function GetSignature(Index:Byte):String;
Var
 I,Start,Pos:Word;
 S:String;
Begin
 Start:=0;
 For I:=0 to Index-1 do Inc(Start,SigLength[I]);
 S:='';
 For I:=0 to SigLength[Index]-1 do Begin
  Pos:=Start+I;
  S:=S+Chr(Byte((SigData[Pos]xor SigKey)-Byte(Pos*7)));
 End;
 GetSignature:=S;
End;

Function ScanFile(FileName:String):Byte;
Var
 F:File;
 Buffer:Array[1..ScanBufferSize]of Char;
 ReadCount,TotalRead:Word;
 Header:String;
 SigIndex:Byte;
 Found:Boolean;
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
 Found:=False;
 For SigIndex:=0 to SigCount-1 do
  If ContainsText(Header,GetSignature(SigIndex))Then Found:=True;
 If Found Then ScanFile:=2
  Else
 If
   IsDOSProgram(FileName)and(TotalRead>=
     2)and(Header[1]='M')and(Header[2]='Z')Then
  ScanFile:=1;
End;

{ Isole un fichier infecte : renomme en .VIR (reversible) }
Procedure IsolateFile(FileName:String);
Var
 F:File;
 D:DirStr;
 N:NameStr;
 E:ExtStr;
 NewName:String;
Begin
 FSplit(FileName,D,N,E);
 NewName:=D+N+'.VIR';
 Assign(F,FileName);
 {$I-}SetFAttr(F,0);Rename(F,NewName);{$I+}
 If IOResult=0 Then Begin
  Inc(Isolated);
  UpdateScreen('Fichier isole : '+N+'.VIR');
 End
  Else UpdateScreen('Isolement impossible');
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
    If(ResultCode=1)and(Not ReportDos)Then ResultCode:=0;
    If ResultCode=2 Then Begin
     Inc(ScanState.Infected);
     UpdateScreen('Alerte : signature suspecte');
     If CleanMode Then IsolateFile(Child);
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
 WriteLn('MSAV - MS Anti-Virus pour DOS');
 TextBackground(7);TextColor(0);
 WriteLn;
   WriteLn('Analyse en lecture seule des fichiers du repertoire courant.');
 WriteLn;WriteLn('MSAV [chemin] [/S]');
 WriteLn;WriteLn('  chemin  Repertoire de depart, courant par defaut.');
 WriteLn('  /S      Parcourt aussi les sous-repertoires.');
 WriteLn;WriteLn('Echap interrompt l''analyse. Les alertes sont heuristiques.');
 WriteLn;WriteLn('Appuyez sur une touche pour continuer...');
 ReadKey;
End;

{ Lecture d'une touche : les touches etendues (fleches, F1..F5) donnent
  256 + code de balayage }
Function GetKey:Word;
Var
 C:Char;
Begin
 C:=ReadKey;
 If C=#0 Then GetKey:=256+Ord(ReadKey)
         Else GetKey:=Ord(C);
End;

Procedure DrawPopup(X1,Y1,X2,Y2:Byte;Title:String);
Var
 Y:Byte;
Begin
 TextBackground(1);TextColor(15);
 For Y:=Y1 to Y2 do Begin
  GotoXY(X1,Y);Write(RepeatChar(' ',X2-X1+1));
 End;
 GotoXY(X1+((X2-X1+1-Length(Title))div 2),Y1);Write(Title);
End;

Procedure ShowKeysHelp;
Begin
 DrawPopup(10,6,70,19,'Aide de MS Anti-Virus');
 GotoXY(12,8);Write('F1  Aide          Affiche cette aide');
 GotoXY(12,9);Write('F2  Lecteur       Choisit le lecteur a examiner');
 GotoXY(12,10);Write('F3  Quitter       Quitte MS Anti-Virus');
 GotoXY(12,11);Write('F4  Detecter      Recherche les virus connus');
 GotoXY(12,12);Write('F5  Options       Modifie les options de l''analyse');
 GotoXY(12,14);Write('Haut/Bas + Entree : choisit une commande du menu.');
 GotoXY(12,15);Write('Echap : quitte, ou interrompt une analyse.');
 GotoXY(12,16);Write('Detecter & Nettoyer renomme les fichiers infectes en');
 GotoXY(12,17);Write('.VIR (ils ne sont jamais effaces).');
 GotoXY(12,19);Write('Appuyez sur une touche pour continuer.');
 GetKey;
End;

Procedure ChooseDrive;
Var
 D:Byte;
 Line:String;
 K:Word;
 Ok:Boolean;
Begin
 DrawPopup(20,8,60,15,'Selectionner un lecteur');
 Line:='';
 For D:=1 to 26 do
  If DiskSize(D)>=0 Then Line:=Line+Chr(64+D)+': ';
 GotoXY(22,10);Write('Lecteurs disponibles : ',Line);
 GotoXY(22,12);Write('Tapez la lettre du lecteur.');
 GotoXY(22,13);Write('Echap annule.');
 Repeat
  K:=GetKey;
  Ok:=False;
  If(K>=Ord('a'))and(K<=Ord('z'))Then Dec(K,32);
  If(K>=Ord('A'))and(K<=Ord('Z'))Then
   If DiskSize(K-64)>=0 Then Begin
    RootPath:=Chr(K)+':\';
    Ok:=True;
   End;
 Until Ok or(K=27);
End;

Procedure ShowOptions;
Var
 Sel:Integer;
 K:Word;
Begin
 Sel:=0;
 DrawPopup(15,8,65,15,'Options');
 Repeat
  TextBackground(1);TextColor(15);
  GotoXY(17,10);If Sel=0 Then TextColor(14);
  Write('[',Chr(32+Ord(Recursive)*56),'] Examiner les sous-repertoires    ');
  TextColor(15);
  GotoXY(17,11);If Sel=1 Then TextColor(14);
  Write('[',Chr(32+Ord(ReportDos)*56),'] Signaler les programmes DOS       ');
  TextColor(15);
  GotoXY(17,13);Write('Haut/Bas : choisir   Espace : changer   Echap : fin');
  K:=GetKey;
  If(K=$148)or(K=$150)Then Sel:=1-Sel
  Else If(K=32)or(K=13)Then Begin
   If Sel=0 Then Recursive:=Not Recursive
            Else ReportDos:=Not ReportDos;
  End;
 Until(K=27)or(K=$13F)or(K=$13D);
End;

Procedure RunScan(Clean:Boolean);
Begin
 CleanMode:=Clean;
 FillChar(ScanState,SizeOf(ScanState),0);
 Isolated:=0;
 DrawScreen;
 GotoXY(38,11);Write('Comptage des fichiers...   ');
 CountFiles(RootPath);
 UpdateScreen('Analyse en cours');
 ScanFiles(RootPath);
 GotoXY(38,20);
 If ScanState.Stop Then Write('Analyse interrompue.') Else
   Write('Analyse terminee.');
 GotoXY(38,21);Write(ScanState.Infected,' alerte(s), ',ScanState.Suspicious,
   ' programme(s) DOS.');
 If Clean Then Begin
  GotoXY(38,22);Write(Isolated,' fichier(s) isole(s).');
 End;
 GotoXY(38,23);Write('Une touche : retour au menu.');
 GetKey;
End;

Procedure MainLoop;
Var
 K:Word;
 Item:Integer;
 Done:Boolean;
Begin
 Done:=False;
 MenuSel:=0;
 DrawScreen;
 Repeat
  K:=GetKey;
  Item:=-1;
  Case K of
   $148:Begin
    If MenuSel>0 Then Dec(MenuSel) Else MenuSel:=MenuCount-1;
    DrawMenu;
   End;
   $150:Begin
    If MenuSel<MenuCount-1 Then Inc(MenuSel) Else MenuSel:=0;
    DrawMenu;
   End;
   13:Item:=MenuSel;
   $13B:Begin ShowKeysHelp;DrawScreen;End;
   $13C:Item:=2;
   $13D,27:Item:=4;
   $13E:Item:=0;
   $13F:Item:=3;
  End;
  Case Item of
   0:Begin MenuSel:=0;RunScan(False);DrawScreen;End;
   1:Begin MenuSel:=1;RunScan(True);DrawScreen;End;
   2:Begin MenuSel:=2;ChooseDrive;DrawScreen;End;
   3:Begin MenuSel:=3;ShowOptions;DrawScreen;End;
   4:Done:=True;
  End;
 Until Done;
End;

Procedure ReadParameters;
Var
 I:Byte;
 P:String;
Begin
 Recursive:=True;ReportDos:=True;RootPath:='';
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
 MainLoop;
 TextBackground(0);TextColor(7);ClrScr;
End.