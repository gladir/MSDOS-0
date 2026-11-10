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
 HeadSize=512;
 TailSize=1024;
 ScanBufferSize=1024;
{ Signatures de virus : stockees chiffrees (XOR + decalage selon la
  position) pour que le programme ne contienne aucune signature en clair ;
  elles ne sont dechiffrees qu'en memoire, au demarrage de l'analyse.
  Base de noms et de messages caracteristiques de virus DOS connus, cherches
  dans les fichiers programmes : l'analyse est heuristique. }
 SigCount=142;
 SigKey=$A5;
 SigLength:Array[0..SigCount-1]of Byte=(
  12,12,9,7,6,6,13,7,5,5,5,8,9,7,5,6,
  8,8,9,8,7,6,6,6,10,11,10,6,9,11,8,8,
  5,6,7,7,6,12,14,7,6,11,12,11,6,11,8,9,
  9,8,9,15,7,7,8,9,9,7,5,8,6,7,8,8,
  6,10,8,5,9,9,9,9,6,8,5,9,6,12,13,9,
  9,10,11,15,10,13,11,4,6,7,12,7,8,7,13,5,
  12,6,11,5,7,10,5,9,8,9,4,5,4,4,6,11,
  10,7,11,22,20,21,15,11,4,11,8,10,14,8,11,10,
  9,6,10,7,7,8,10,7,4,6,7,6,5,8);
 SigData:Array[0..1210]of Byte=(
  $E1,$ED,$C5,$C5,$99,$C1,$25,$D3,$23,$23,$2E,$3A,
  $04,$01,$00,$14,$10,$66,$1A,$76,$76,$7D,$43,$55,
  $57,$51,$AD,$B7,$B2,$A9,$BB,$BB,$88,$8F,$8A,$ED,
  $9A,$E1,$EB,$F3,$CB,$CD,$CE,$DE,$27,$D9,$30,$38,
  $3A,$00,$06,$0C,$60,$11,$6D,$69,$68,$71,$13,$44,
  $56,$5F,$53,$A0,$A0,$BE,$B6,$83,$94,$89,$93,$97,
  $9B,$F4,$F0,$F4,$C6,$C0,$D4,$D9,$DD,$25,$29,$23,
  $05,$31,$08,$15,$13,$11,$33,$60,$60,$72,$7D,$7F,
  $4B,$5E,$52,$47,$5A,$B5,$BC,$81,$BC,$88,$9F,$93,
  $9C,$F6,$E2,$EF,$CF,$C9,$D4,$C3,$CA,$D1,$28,$34,
  $28,$04,$3C,$07,$14,$15,$63,$1B,$77,$45,$74,$42,
  $54,$54,$48,$5C,$58,$B4,$AF,$AB,$8D,$B9,$80,$9E,
  $9C,$E1,$E6,$EC,$F0,$FD,$9F,$CC,$CC,$24,$DF,$24,
  $28,$29,$3A,$0D,$0B,$0E,$17,$1B,$6B,$15,$76,$7F,
  $78,$52,$4E,$4A,$AC,$A7,$AD,$BB,$B8,$BC,$8F,$8F,
  $96,$9E,$EC,$F1,$F9,$F4,$F2,$CC,$D5,$DB,$DC,$2D,
  $29,$2E,$36,$06,$D9,$0F,$0E,$60,$18,$62,$62,$7C,
  $45,$4F,$42,$49,$5D,$59,$A9,$A8,$80,$B0,$89,$8F,
  $89,$9D,$9C,$E7,$F5,$E9,$C5,$F8,$CC,$CF,$DD,$D3,
  $DA,$2B,$CF,$06,$04,$0A,$13,$17,$63,$63,$66,$73,
  $7C,$47,$7A,$5A,$54,$5B,$5A,$BF,$BD,$84,$BE,$95,
  $92,$93,$E4,$EE,$EC,$ED,$FF,$FF,$C1,$C9,$D4,$DC,
  $21,$21,$33,$3A,$06,$0B,$1E,$10,$1C,$1C,$66,$72,
  $45,$49,$43,$4F,$5E,$54,$A0,$AE,$B4,$A9,$BC,$82,
  $8C,$9E,$98,$99,$EE,$F0,$F8,$F9,$C0,$C5,$D7,$24,
  $DC,$2B,$22,$CC,$34,$01,$08,$0F,$0B,$11,$62,$63,
  $7F,$44,$7A,$54,$5D,$5D,$A4,$A2,$BD,$B6,$AA,$86,
  $84,$9F,$AF,$EE,$98,$E5,$F7,$EB,$C7,$FA,$D5,$DD,
  $D8,$D9,$29,$35,$3D,$31,$0B,$13,$1F,$15,$61,$69,
  $7F,$75,$7A,$7E,$40,$5C,$6B,$43,$56,$B7,$B9,$85,
  $8D,$85,$9B,$98,$90,$E8,$EE,$F8,$CC,$92,$C5,$D1,
  $DE,$22,$2F,$23,$33,$06,$32,$01,$16,$1C,$67,$60,
  $64,$7F,$47,$7B,$48,$5D,$4A,$A4,$A4,$A8,$A8,$48,
  $81,$8F,$95,$95,$E5,$EC,$E6,$FC,$FE,$C0,$C6,$C7,
  $DE,$D5,$2F,$DB,$37,$CE,$31,$0B,$02,$1F,$1B,$13,
  $6F,$69,$78,$7C,$1D,$56,$4E,$5C,$5C,$5B,$B4,$B3,
  $86,$95,$94,$94,$9E,$93,$E0,$F0,$EC,$FD,$E6,$C8,
  $C0,$DC,$23,$DB,$2B,$3E,$2A,$3D,$0D,$0D,$1B,$66,
  $1C,$67,$6E,$6A,$70,$7B,$48,$58,$A7,$A3,$AD,$AF,
  $AA,$82,$8C,$96,$9B,$95,$9C,$F5,$E8,$FC,$F6,$CA,
  $C6,$D3,$DE,$27,$37,$29,$3C,$38,$3C,$16,$10,$1A,
  $6F,$61,$71,$68,$70,$41,$50,$51,$5D,$5C,$A2,$A7,
  $B3,$8C,$BE,$8A,$96,$AE,$91,$EB,$E2,$C4,$F6,$C0,
  $C9,$CD,$D3,$DF,$23,$36,$3D,$37,$04,$0F,$11,$18,
  $10,$66,$66,$6E,$7E,$44,$46,$41,$4C,$A3,$52,$AE,
  $AD,$B5,$81,$BB,$97,$9F,$9B,$EB,$E4,$F0,$EE,$FB,
  $FF,$D1,$D7,$CB,$27,$DB,$22,$2F,$07,$01,$3A,$09,
  $14,$12,$6C,$6A,$69,$7B,$4C,$40,$5C,$5C,$A3,$5B,
  $B7,$AE,$B8,$8C,$59,$8D,$8E,$E0,$98,$F4,$F6,$C7,
  $C3,$CE,$CF,$27,$26,$28,$26,$32,$35,$3A,$0C,$12,
  $19,$61,$6D,$6D,$7C,$7B,$4C,$47,$56,$5F,$6B,$43,
  $55,$53,$B8,$B8,$82,$90,$82,$9D,$93,$E2,$E6,$E9,
  $FE,$92,$CE,$D1,$DF,$D2,$DE,$3F,$2F,$3B,$0E,$0E,
  $02,$11,$65,$65,$05,$6C,$6A,$44,$4D,$40,$5A,$58,
  $5A,$A5,$BD,$B3,$B0,$8C,$80,$94,$E7,$E5,$F4,$FC,
  $FC,$F1,$C8,$C1,$D2,$D0,$D9,$27,$2C,$3B,$3F,$0D,
  $15,$0E,$12,$6D,$62,$06,$70,$7F,$41,$4E,$4E,$5A,
  $5F,$A8,$AE,$A8,$B4,$95,$5B,$9C,$91,$9D,$BF,$97,
  $9E,$C6,$FB,$C1,$C9,$DF,$20,$28,$C5,$2C,$38,$01,
  $15,$09,$1D,$62,$64,$77,$6A,$6A,$45,$45,$67,$53,
  $54,$A0,$AF,$AB,$85,$82,$83,$83,$AD,$93,$9A,$EA,
  $F5,$FD,$FE,$D4,$F4,$D0,$D8,$F0,$20,$34,$3B,$3A,
  $08,$07,$17,$17,$10,$68,$74,$69,$41,$43,$45,$4F,
  $5B,$76,$4E,$56,$B9,$B2,$83,$80,$96,$95,$E5,$E7,
  $FD,$F2,$C5,$FF,$C5,$C1,$DB,$25,$2F,$2A,$3D,$39,
  $0D,$0F,$2A,$18,$67,$69,$74,$7D,$70,$71,$4D,$64,
  $59,$5D,$58,$A7,$B3,$BB,$B6,$83,$95,$93,$E4,$EC,
  $E4,$E1,$F3,$C0,$C5,$9A,$CD,$D9,$26,$2A,$30,$3B,
  $3B,$3E,$3A,$1B,$1A,$6D,$6F,$63,$7F,$0A,$49,$43,
  $53,$A5,$A0,$A9,$B0,$BC,$B2,$8E,$8A,$9C,$88,$B4,
  $88,$88,$93,$C5,$C8,$CB,$D3,$CB,$D8,$F2,$25,$3F,
  $36,$02,$06,$0B,$14,$16,$6F,$6A,$60,$44,$72,$40,
  $49,$49,$A5,$AC,$B6,$B7,$52,$BC,$BC,$8E,$89,$E6,
  $98,$E8,$F2,$F9,$98,$ED,$EB,$F3,$26,$C5,$CE,$D1,
  $3A,$32,$32,$0C,$0C,$66,$62,$74,$64,$45,$6A,$44,
  $44,$58,$5C,$5B,$5F,$AD,$AE,$AA,$83,$B9,$8E,$92,
  $B5,$E8,$E2,$F2,$C4,$C3,$C5,$D5,$DF,$D9,$C6,$36,
  $28,$38,$02,$09,$16,$19,$1E,$6D,$65,$77,$78,$73,
  $79,$46,$4A,$57,$71,$A2,$AE,$BA,$B0,$8F,$90,$8F,
  $9D,$93,$EC,$EB,$E8,$8A,$CF,$C9,$E1,$DA,$DF,$DB,
  $C5,$2E,$06,$06,$06,$0D,$1C,$1A,$65,$65,$73,$78,
  $48,$1E,$41,$57,$A7,$AE,$A3,$AC,$A8,$89,$5F,$8E,
  $92,$E7,$9B,$E3,$F8,$FF,$C2,$CE,$E5,$D2,$D4,$F0,
  $20,$33,$CF,$3A,$02,$13,$23,$65,$6D,$6F,$75,$6B,
  $71,$7E,$42,$5D,$69,$59,$A8,$44,$B2,$B8,$BE,$58,
  $89,$89,$9B,$9A,$E3,$FC,$F8,$FC,$CE,$E6,$D3,$DF,
  $2B,$21,$3C,$3E,$0C,$03,$02,$08,$10,$1D,$77,$68,
  $09,$71,$4D,$4D,$48,$5E,$52,$AE,$AE,$B5,$BB,$BF,
  $A5,$BC,$9E,$9F,$E6,$E1,$8F,$F0,$F8,$C5,$DF,$D0,
  $D3,$22,$34,$3D,$31,$15,$DB,$19,$08,$60,$69,$6F,
  $72,$44,$4C,$49,$5C,$5A,$5F,$5B,$AB,$AE,$84,$B8,
  $B8,$8B,$8A,$B4,$EB,$ED,$FD,$C7,$C2,$CB,$CB,$DD,
  $22,$F2,$31,$2B,$3B,$0D,$08,$0A,$12,$1A,$06,$76,
  $68,$78,$42,$49,$55,$59,$A5,$A0,$AD,$AD,$B5,$B8,
  $84,$8A,$A3,$E6,$98,$E8,$F2,$F9,$F4,$C6,$FA,$C2,
  $C8,$25,$DE,$27,$33,$06,$3B,$0A,$00,$66,$11,$1F,
  $77,$7C,$78,$4C,$44,$53,$5C,$A0,$A5,$A1,$BD,$48,
  $82,$81,$83,$8B,$E5,$E5,$F3,$EF,$FD,$96,$EE,$CA,
  $D4,$D8,$D2,$31,$20,$3C,$33,$3B,$17,$16,$0A,$6A,
  $18,$70,$7A,$41,$79,$4D,$48,$51,$5C,$A8,$A2,$B3,
  $B8,$85,$86,$97,$96,$B6,$F5,$EF,$FF,$C1,$CC);

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
 Sigs:Array[0..SigCount-1]of String[24];
 Buffer:Array[0..ScanBufferSize-1]of Char;
 FoundName:String[24];
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

{ Dechiffre toute la base de signatures en memoire }
Procedure LoadSignatures;
Var
 I,J,Pos:Word;
 S:String;
Begin
 Pos:=0;
 For I:=0 to SigCount-1 do Begin
  S:='';
  For J:=0 to SigLength[I]-1 do Begin
   S:=S+Chr(Byte((SigData[Pos]xor SigKey)-Byte(Pos*7)));
   Inc(Pos);
  End;
  Sigs[I]:=S;
 End;
End;

{ Cherche une signature dans Buffer[0..Len-1] ; renvoie son numero ou -1 }
Function FindSignature(Len:Word):Integer;
Var
 Start,N,I:Word;
 Chunk:String;
 Sig:Integer;
 Last:Boolean;
Begin
 FindSignature:=-1;
 Start:=0;
 Last:=False;
 While(Start<Len)and(Not Last)do Begin
  N:=Len-Start;
  If N>255 Then N:=255;
  Chunk[0]:=Chr(N);
  For I:=1 to N do Begin
   Chunk[I]:=Buffer[Start+I-1];
   If Chunk[I]in['a'..'z']Then Chunk[I]:=Chr(Ord(Chunk[I])-32);
  End;
  For Sig:=0 to SigCount-1 do
   If Pos(Sigs[Sig],Chunk)>0 Then Begin
    FindSignature:=Sig;
    Exit;
   End;
  If Start+N>=Len Then Last:=True Else Inc(Start,N-24);
 End;
End;

{ Les outils de detection (MSAV, VSAFE) contiennent des noms de virus dans
  leurs messages : ils ne sont pas analyses par signature }
Function IsSecurityTool(FileName:String):Boolean;
Var
 D:DirStr;N:NameStr;E:ExtStr;
Begin
 FSplit(FileName,D,N,E);
 N:=StrToUpper(N);
 IsSecurityTool:=(N='MSAV')or(N='VSAFE');
End;

Function ScanFile(FileName:String):Byte;
Var
 F:File;
 ReadCount:Word;
 FileLen:LongInt;
 Sig:Integer;
 H0,H1:Char;
 Exec:Boolean;
begin
 ScanFile:=0;
 FoundName:='';
 Assign(F,FileName);
 {$I-}Reset(F,1);{$I+}
 If IOResult<>0 Then Exit;
 FileLen:=FileSize(F);
 Exec:=IsDOSProgram(FileName)or(Pos('.BAT',StrToUpper(FileName))>0);
 If IsSecurityTool(FileName)Then Exec:=False;
 { debut du fichier }
 BlockRead(F,Buffer,HeadSize,ReadCount);
 H0:=#0;H1:=#0;
 If ReadCount>=2 Then Begin H0:=Buffer[0];H1:=Buffer[1];End;
 Sig:=-1;
 If Exec and(ReadCount>0)Then Sig:=FindSignature(ReadCount);
 { fin du fichier : les virus s'y ajoutent le plus souvent }
 If(Sig<0)and Exec and(FileLen>HeadSize)Then Begin
  If FileLen-HeadSize>TailSize Then Seek(F,FileLen-TailSize)
                               Else Seek(F,HeadSize);
  BlockRead(F,Buffer,TailSize,ReadCount);
  If ReadCount>0 Then Sig:=FindSignature(ReadCount);
 End;
 Close(F);
 If Sig>=0 Then Begin
  FoundName:=Sigs[Sig];
  ScanFile:=2;
 End
  Else
 If IsDOSProgram(FileName)and(H0='M')and(H1='Z')Then
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
     UpdateScreen('Alerte : '+FoundName);
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
 LoadSignatures;
 FillChar(ScanState,SizeOf(ScanState),0);
 MainLoop;
 TextBackground(0);TextColor(7);ClrScr;
End.