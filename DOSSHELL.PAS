{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program DOSSHELL;

{$M 8192,0,65536}

Uses Crt,DOS;

Const
 MainMenu:Array[0..4]of String[10]=(
  'Fichier','Options','Affichage','Arbre','Aide'
 );
 MainMenuEnglish:Array[0..4]of String[10]=(
  'File','Options','View','Tree','Help'
 );
 MainMenuGermany:Array[0..4]of String[12]=(
  'Datei','Optionen','Anzeige','Verzeichnis','Hilfe'
 );

 SubMenuFile:Array[0..18]of String[25]=(
  'Ouvrir',
  'ExÇcuter...',
  'Imprimer',
  'Associer...',
  'Rechercher...',
  'Afficher le contenu',
  '',
  'DÇplacer...',
  'Copier...',
  'Supprimer...',
  'Renommer...',
  'Change les attributs...',
  '',
  'CrÇer un rÇpertoire...',
  '',
  'SÇlectionner tout',
  'DÇselectionner tout',
  '',
  'Quitter'
 );

 SubMenuFileEnglish:Array[0..18]of String[20]=(
  'Open',
  'Run...',
  'Print',
  'Associate...',
  'Search...',
  'View File Contents',
  '',
  'Move...',
  'Copy...',
  'Delete...',
  'Rename...',
  'Change Attributes...',
  '',
  'Create Directory...',
  '',
  'Select All',
  'Deselect All',
  '',
  'Exit'
 );

 SubMenuFileGermany:Array[0..18]of String[20]=(
  'ôffnen',
  'AusfÅhren...',
  'Drucken',
  'VerknÅpfen...',
  'Suchen...',
  'Dateiinhalt anzeigen',
  '',
  'Verschieben...',
  'Kopieren...',
  'Lîschen...',
  'Umbenennen...',
  'Attribute Ñndern...',
  '',
  'Verzeichnis erstellen...',
  '',
  'Alles auswÑhlen',
  'Auswahl aufheben',
  '',
  'Beenden'
 );

 SubMenuOptions:Array[0..6]of String[40]=(
  'Confirmation...',
  'Options d''affichage des fichiers...',
  'SÇlectionner dans tous les rÇpertoires',
  'Renseignements...',
  'Activer la commutation de tÉches',
  'Ecran...',
  'Couleurs...'
 );

 SubMenuOptionsEnglish:Array[0..6]of String[20]=(
  'Confirmation...',
  'File Display Options...',
  'Select Across Directories',
  'Show Information...',
  'Enable Task Swapper',
  'Display...',
  'Colors...'
 );

 SubMenuOptionsGermany:Array[0..6]of String[30]=(
  'BestÑtigen...',
  'Dateianzeige...',
  'Aus mehreren Verzeichnissen auswÑhlen',
  'Informationen anzeigen...',
  'Programmumschaltung aktivieren',
  'Anzeigemodus...',
  'Farbschema...'
 );

 SubMenuView:Array[0..7]of String[30]=(
  'Liste simple',
  'Listes multiples',
  'Tous les fichiers',
  'Listes programmes/fichiers',
  'Liste programmes',
  '',
  'Actualiser l''Çcran',
  'Actualiser'
 );

 SubMenuViewEnglish:Array[0..7]of String[20]=(
  'Single File List',
  'Dual File Lists',
  'All Files',
  'Program/File Lists',
  'Program List',
  '',
  'Repaint Screen',
  'Refresh'
 );

 SubMenuViewGermany:Array[0..7]of String[25]=(
  'Einfache Dateiliste',
  'Zweifache Dateiliste',
  'Nur Dateien',
  'Programme und Dateien',
  'Nur Programme',
  '',
  'Anzeige neu aufbauen',
  'Aktualisieren'
 );

 SubMenuTree:Array[0..3]of String[25]=(
  'DÇvelopper un niveau',
  'DÇvelopper une branche',
  'DÇvelopper tout',
  'RÇduire une branche'
 );

 SubMenuTreeEnglish:Array[0..3]of String[20]=(
  'Expand One Level',
  'Expand Branch',
  'Expand All',
  'Collapse Branch'
 );

 SubMenuTreeGermany:Array[0..3]of String[20]=(
  'NÑchste Ebene einblenden',
  'Zweig einblenden',
  'Alle Ebenen einblenden',
  'Zweig ausblenden'
 );

 SubMenuHelp:Array[0..7]of String[20]=(
  'Index',
  'Clavier',
  'Notions fondamentales',
  'Commandes',
  'ProcÇdures',
  'Utiliser l''aide',
  '',
  'A propos du Shell'
 );

 SubMenuHelpEnglish:Array[0..7]of String[20]=(
  'Index',
  'Keyboard',
  'Shell Basics',
  'Commands',
  'Procedures',
  'Using Help',
  '',
  'About Shell'
 );

 SubMenuHelpGermany:Array[0..7]of String[20]=(
  'Index',
  'Tastatur',
  'Grundlagen',
  'Befehle',
  'Verfahren',
  'Hilfe verwenden',
  '',
  'Info Åber Shell'
 );

 YMenuMax:Array[1..5]of Byte=(
  High(SubMenuFile),High(SubMenuOptions),High(SubMenuView),
  High(SubMenuTree),High(SubMenuHelp)
 );

 MaxFiles=511;
 FileYMax=7;

Type
 ProgramRec=Record
  Command:String;
  Title:String[38];
  Help:String;
  Pause,Group:Boolean;
  Next:Pointer;
 End;

 PProgramRec=^ProgramRec;

 StrName=String[12];

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 YMenu,XMenu:Integer;
 FilePos,MenuPos:Integer;
 MenuYMax:Byte;
 CurrZone,FileY,MenuY:Byte;
 ShowASCII128,OnMenu:Boolean;
 FileManager:Boolean;
 ProgramList:PProgramRec;
 ProgramCount:Integer;
 Nom:Array[0..MaxFiles] of StrName;
 Temps:Array[0..MaxFiles] of LongInt;
 Taille:Array[0..MaxFiles] of LongInt;
 Attribt:Array[0..MaxFiles] of Byte;
 Accepte:Array[0..MaxFiles] of 0..1;
 NombreFichierX:0..MaxFiles;
 TypeTri:0..4;

{$IFNDEF FPC}
 Procedure CursorOff;
 Var
  Regs:Registers;
 Begin
  Regs.AH:=1;
  Regs.CH:=32;
  Regs.CL:=0;
  Intr($10,Regs);
 End;

 Procedure CursorOn;
 Var
  Regs:Registers;
 Begin
  Regs.AX:=$0100;
  Regs.CX:=(7 shl 8)+9;
  Intr($10,Regs);
 End;
{$ENDIF}


Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
End;

Function PadZeroLeft(Value:Integer;Space:Byte):String;
Var
 S:String;
Begin
 Str(Value,S);
 While Length(S)<Space do S:='0'+S;
 PadZeroLeft:=S;
End;

Function DuplicateString(C:Char;Num:Integer):String;
Var
 I:Byte;
 S:String;
Begin
 S:='';
 For I:=1 to Num do S:=S+C;
 DuplicateString:=S;
End;

Function TrimL(S:String):String;
Var
 I:Byte;
Begin
 For I:=1to Length(S)do Begin
  If S[I]<>' 'Then Begin
   TrimL:=Copy(S,I,255);
   Exit;
  End;
 End;
 TrimL:=S;
End;

Function TrimR(s:String):String;
Var
 i:Integer;
Begin
 i:=Length(s);
 While (i>0)and(s[i]in[#9,' '])do Dec(i);
 s[0]:=Chr(i);
 TrimR:=S;
End;

Function Trim(S:String):String;Begin
 Trim:=TrimL(TrimR(S));
End;

Function GetCurrentDisk:Char;
Var
 CurrentDir:String;
Begin
 GetDir(0,CurrentDir);
 GetCurrentDisk:=CurrentDir[1];
End;

Procedure Box(X1,Y1,X2,Y2,Couleur:Byte);Begin
 Window(X1,Y1,X2,Y2);
 TextBackground((Couleur shr 4)and 15);
 If Couleur and $80=$80 Then Begin
  TextColor((Couleur and 15)+BLINK);
 End
  Else
 TextColor(Couleur and 15);
 ClrScr;
 Window(1,1,80,25);
End;

Procedure FrameEmpty(X1,Y1,X2,Y2,Couleur:Byte);
Var
 I:Byte;
 ChrHori,ChrVert:Char;
 Chr218,Chr192,Chr191,Chr217:Char;
Begin
 TextBackground((Couleur shr 4)and 15);
 If Couleur and $80=$80 Then Begin
  TextColor((Couleur and 15)+BLINK);
 End
  Else
 TextColor(Couleur and 15);
 If(ShowASCII128)Then Begin
  ChrHori:='-';
  ChrVert:='|';
  Chr218:='+';
  Chr192:='+';
  Chr191:='+';
  Chr217:='+';
 End
  Else
 Begin
  ChrHori:=#$C4;
  ChrVert:=#$B3;
  Chr218:=#218;
  Chr192:=#192;
  Chr191:=#191;
  Chr217:=#217;
 End;
 For I:=Y1+1 to Y2-1 do Begin
  GotoXY(X1,I);
  Write(ChrVert);
  GotoXY(X2,I);
  Write(ChrVert);
 End;
 GotoXY(X1+1,Y1);
 Write(DuplicateString(ChrHori,X2-X1-1));
 GotoXY(X1+1,Y2);
 Write(DuplicateString(ChrHori,X2-X1-1));
 GotoXY(X1,Y1);
 Write(Chr218);
 GotoXY(X1,Y2);
 Write(Chr192);
 GotoXY(X2,Y1);
 Write(Chr191);
 GotoxY(X2,Y2);
 Write(Chr217);
End;

Function AddProgramList:Pointer;
Var
 P:PProgramRec;
 CurrProgram:PProgramRec;
Begin
 AddProgramList:=NIL;
 GetMem(P,SizeOf(ProgramRec));
 If P<>NIL Then Begin
  If(ProgramList=NIL)Then ProgramList:=P
   Else
  Begin
   CurrProgram:=ProgramList;
   While CurrProgram^.Next<>NIL do CurrProgram:=CurrProgram^.Next;
   If CurrProgram^.Next=NIL Then Begin
    CurrProgram^.Next:=P;
   End;
  End;
  Inc(ProgramCount);
  AddProgramList:=P;
 End;
End;

Procedure LoadDosShellIni;
Var
 CurrSection:(_None,_SaveState,_ProgramStarter);
 FileIni:Text;
 InProgram:Boolean;
 OpenAccol,Group:Integer;
 CurrLine,CurrWord,ResultValue:String;
 I:Integer;
 CurrProgram:ProgramRec;
 CurrPProgram:PProgramRec;
Begin
 {$I-}Assign(FileIni,'DOSSHELL.INI');
 Reset(FileIni);{$I+}
 If IoResult=0Then Begin
  Group:=0;
  OpenAccol:=0;
  CurrSection:=_None;
  InProgram:=False;
  FillChar(CurrProgram,SizeOf(CurrProgram),0);
  CurrProgram.Next:=NIL;
  While Not EOF(FileIni)do Begin
   ReadLn(FileIni,CurrLine);
   CurrLine:=Trim(CurrLine);
   If StrToUpper(CurrLine)='[SAVESTATE]'Then CurrSection:=_SaveState Else
   If StrToUpper(CurrLine)='[PROGRAMSTARTER]'Then CurrSection:=_ProgramStarter Else
   If Trim(CurrLine)='{'Then Inc(OpenAccol) Else
   If Trim(CurrLine)='}'Then Begin
    If InProgram Then Begin
     CurrPProgram:=AddProgramList;
     If CurrPProgram<>NIL Then Begin
      Move(CurrProgram,CurrPProgram^,SizeOf(CurrProgram));
      FillChar(CurrProgram,SizeOf(CurrProgram),0);
      CurrProgram.Next:=NIL;
     End;
     InProgram:=False;
    End
     Else
    If Group>0Then Dec(Group);
    Dec(OpenAccol)
   End
    Else
   Begin
    CurrWord:='';
    I:=1;
    While(CurrLine[I]in['A'..'Z','a'..'z'])and(I<=Length(CurrLine))do Begin
     CurrWord:=CurrWord+CurrLine[I];
     Inc(I);
    End;
    While(CurrLine[I]in[' ',#9])and(I<=Length(CurrLine))do Inc(I);
    If CurrLine[I]='='Then Begin
     Inc(I);
     While(CurrLine[I]in[' ',#9])and(I<=Length(CurrLine))do Inc(I);
     ResultValue:=Copy(CurrLine,I,255);
     If(CurrSection=_ProgramStarter)Then Begin
      If(InProgram)Then Begin
       If StrToUpper(CurrWord)='COMMAND'Then CurrProgram.Command:=ResultValue Else
       If StrToUpper(CurrWord)='HELP'Then CurrProgram.Help:=ResultValue Else
       If StrToUpper(CurrWord)='PAUSE'Then Begin
        If StrToUpper(ResultValue)='ENABLED'Then CurrProgram.Pause:=True Else
        If StrToUpper(ResultValue)='DISABLED'Then CurrProgram.Pause:=False;
       End
        Else
       If StrToUpper(CurrWord)='TITLE'Then CurrProgram.Title:=ResultValue;
      End
       Else
      If StrToUpper(CurrWord)='GROUP'Then Inc(Group) Else
      If StrToUpper(CurrWord)='FILEMANAGER'Then Begin
       If StrToUpper(ResultValue)='ENABLED'Then FileManager:=True Else
       If StrToUpper(ResultValue)='DISABLED'Then FileManager:=False;
      End
       Else
      If StrToUpper(CurrWord)='PROGRAM'Then InProgram:=True;
     End;
    End;
   End;
  End;
  Close(FileIni);
 End;
End;

Procedure ReadFiles(Chaine:PathStr;Attribut:Word);
Var
 Compteur,Position:Word;
 OK:Boolean;
 Ecart,I,J,K,M:LongInt;
 Sortie:Boolean;
 X:String[12];
 XTaille:LongInt;
 XAttribt:Byte;
 XSeconde:0..59;
 XMinute:0..59;
 XHeure:0..23;
 XJour:1..31;
 XMois:1..12;
 XAnnees:Word;
 Date_TimeB:DateTime;
 Palette:SearchRec;
 Directory:DirStr;
 FileName:NameStr;
 Extension:ExtStr;
 Erreur:Integer;

 Procedure SousTri;
 Var
  Date_Time:DateTime;
 Begin
  UnpackTime(Temps[I],Date_Time);
  UnPackTime(Temps[M],Date_TimeB);
  X               := Nom[I];
  XTaille         := Taille[I];
  XAttribt        := Attribt[I];
  XSeconde        := Date_Time.Sec;
  XMinute         := Date_Time.Min;
  XHeure          := Date_Time.Hour;
  XJour           := Date_Time.Day;
  XMois           := Date_Time.Month;
  XAnnees  	  := Date_Time.Year;
  Nom[I]     := Nom[M];
  Taille[I]  := Taille[M];
  Attribt[I] := Attribt[M];
  Date_Time.Sec   := Date_TimeB.Sec;
  Date_Time.Min   := Date_TimeB.Min;
  Date_Time.Hour  := Date_TimeB.Hour;
  Date_Time.Day   := Date_TimeB.Day;
  Date_Time.Month := Date_TimeB.Month;
  Date_Time.Year  := Date_TimeB.Year;
  Nom[M]     := X;
  Taille[M]  := XTaille;
  Attribt[M] := XAttribt;
  Date_TimeB.Sec  := XSeconde;
  Date_TimeB.Min  := XMinute;
  Date_TimeB.Hour := XHeure;
  Date_TimeB.Day  := XJour;
  Date_TimeB.Month:= XMois;
  Date_TimeB.Year := XAnnees;
  PackTime(Date_Time,Temps[I]);
  PackTime(Date_TimeB,Temps[M]);
  Dec(I,Ecart);
 End;

 Procedure SousInit;Begin
  Ecart := Ecart div 2;
  J     := 1;
  K     := NombreFichierX - Ecart;
 End;

 Procedure TriNom;Begin
  Ecart := NombreFichierX;
  If(Ecart>3)Then
  Repeat
   SousInit;
   Repeat
    I      := J;
    Sortie := False;
    Repeat
     M := I + Ecart;
     If Nom[I] > Nom[M] Then SousTri
		      	Else Sortie := True;
    Until (I<1) or (Sortie = True);
    Inc(J);
   Until J>K;
  Until Ecart = 1;
 End;

 Procedure TriExtension;Begin
  Ecart := NombreFichierX;
  If(Ecart>3)Then
  Repeat
   SousInit;
   Repeat
    I      := J;
    Sortie := False;
    Repeat
     M := I + Ecart;
     If(Copy(Nom[I],10,3)+Copy(Nom[I],1,8) >
	Copy(Nom[M],10,3)+Copy(Nom[M],1,8))Then
     SousTri Else Sortie := True;
    Until (I<1) or (Sortie = True);
    Inc(J);
   Until J>K;
  Until Ecart = 1;
 End;

 Procedure TriHeure;Begin
  Ecart := NombreFichierX;
  If(Ecart>3)Then
  Repeat
   SousInit;
   Repeat
    I      := J;
    Sortie := False;
    Repeat
     M := I + Ecart;
     If(Temps[I]>Temps[M])Then
      SousTri
      Else
     Sortie := True;
    Until (I<1) or (Sortie = True);
    Inc(J);
   Until J>K;
  Until Ecart = 1;
 End;

 Procedure TriTaille;Begin
  Ecart := NombreFichierX;
  If(Ecart>3)Then
  Repeat
   SousInit;
   Repeat
    I      := J;
    Sortie := False;
    Repeat
     M := I + Ecart;
     If Taille[I] > Taille[M] Then SousTri
					Else Sortie := True;
    Until (I<1) or (Sortie = True);
    Inc(J);
   Until J>K;
  Until Ecart = 1;
 End;

Begin
 Position:=0;
 FindFirst(Chaine,$FFF7,Palette);
 Erreur:=DOSERROR;
 While Erreur = 0 do Begin
  If((Palette.Name<>'.')and(Erreur=0))and(Palette.Attr and 16=0)Then Begin
   Accepte[Position] := 0;
   Attribt[Position] := Palette.Attr and 22;
   Temps[Position]   := Palette.Time;
   Taille[Position]  := Palette.Size;
   If Length(Palette.Name)>12Then Begin
    Nom[Position] := Copy(Palette.Name,1,12);
   End
    Else
   Nom[Position] := Palette.Name;
   If(Attribt[Position]<>16)Then Begin
    FSplit(Palette.Name,Directory,FileName,Extension);
    Repeat
     FileName := FileName + ' ';
    Until (Length(FileName)>=8);
    Nom[Position] := Filename + Extension;
   End
    else
   If(Attribt[Position]=16)Then Begin
    Nom[Position] := #1 + Nom[Position];
   End;
   Inc(Position);
  End;
  If Position>=MaxFiles Then Break;
  FindNext(Palette);
  Erreur:=DOSERROR;
 End;
 NombreFichierX := Position - 1;
 Case TypeTri of
  0 : TriNom;
  1 : TriExtension;
  2 : TriHeure;
  3 : TriTaille;
 End;
 For Compteur:=1 to NombreFichierX do Begin
  If(Copy(Nom[Compteur],1,1)<#32)Then Nom[Compteur]:=Copy(Nom[Compteur],2,11);
 End;
End;

Procedure ShowTitle;Begin
 Box(1,1,80,1,$1F);
 GotoXY(30,1);
 Write('MS-DOS Shell Clone');
End;

Procedure SetColorSelect;Begin
 TextColor(15);
 TextBackground(0);
End;

Procedure SetColorUnSelect;Begin
 TextColor(0);
 TextBackground(3);
End;

Procedure ShowMenu;
Var
 I:Byte;
Begin
 Box(1,2,80,2,$30);
 GotoXY(1,2);
 For I:=0 to High(MainMenu) do Begin
  If Not((CurrZone=3)and(I=3))Then Begin
   If(OnMenu)Then Begin
    If I+1=XMenu Then SetColorSelect
                 Else SetColorUnSelect;
   End;
   Case Language of
    _Germany:Write(' ',MainMenuGermany[I],' ');
    _English:Write(' ',MainMenuEnglish[I],' ');
    Else Write(' ',MainMenu[I],' ');
   End;
   SetColorUnSelect;
   If Language in[_English,_French]Then Write(' ');
  End;
 End;
End;

Procedure SubMenuItem(Y:Integer;Disable:Boolean);Begin
 If(Disable)Then SetColorUnSelect Else
 If Y=YMenu Then SetColorSelect
            Else SetColorUnSelect;
 Case XMenu of
  1:Begin
   GotoXY(2,4+Y);
   If SubMenuFile[Y]=''Then Write(DuplicateString('-',27+1))
    Else
   Case Language of
    _English:Write(' ',PadRight(SubMenuFileEnglish[Y],27));
    _Germany:Write(' ',PadRight(SubMenuFileGermany[Y],27));
    Else Write(' ',PadRight(SubMenuFile[Y],27));
   End;
  End;
  2:Begin
   Case Language of
    _English:GotoXY(9,4+Y);
    Else GotoXY(12,4+Y);
   End;
   If SubMenuOptions[Y]=''Then Write(DuplicateString('-',39+1))
    Else
   Case Language of
    _English:Write(' ',PadRight(SubMenuOptionsEnglish[Y],39));
    _Germany:Write(' ',PadRight(SubMenuOptionsGermany[Y],39));
    Else Write(' ',PadRight(SubMenuOptions[Y],39));
   End;
  End;
  3:Begin
   Case Language of
    _English:GotoXY(19,4+Y);
    Else GotoXY(22,4+Y);
   End;
   If SubMenuView[Y]=''Then Write(DuplicateString('-',27+1))
    Else
   Case Language of
    _English:Write(' ',PadRight(SubMenuViewEnglish[Y],27));
    _Germany:Write(' ',PadRight(SubMenuViewGermany[Y],27));
    Else Write(' ',PadRight(SubMenuView[Y],27));
   End;
  End;
  4:Begin
   GotoXY(34,4+Y);
   If SubMenuTree[Y]=''Then Write(DuplicateString('-',27+1))
    Else
   Case Language of
    _English:Write(' ',PadRight(SubMenuTreeEnglish[Y],27));
    _Germany:Write(' ',PadRight(SubMenuTreeGermany[Y],27));
    Else Write(' ',PadRight(SubMenuTree[Y],27));
   End;
  End;
  5:Begin
   If(CurrZone=3)Then GotoXY(34,4+Y)
                 Else GotoXY(42,4+Y);
   If SubMenuHelp[Y]=''Then Write(DuplicateString('-',27+1))
    Else
   Case Language of
    _English:Write(' ',PadRight(SubMenuHelpEnglish[Y],27));
    _Germany:Write(' ',PadRight(SubMenuHelpGermany[Y],27));
    Else Write(' ',PadRight(SubMenuHelp[Y],27));
   End;
  End;
 End;
End;

Procedure ShowSubMenu;
Var
 I:Integer;
Begin
 Case XMenu of
  1:Begin
   FrameEmpty(1,3,30,5+High(SubMenuFile),$30);
   For I:=Low(SubMenuFile)to High(SubMenuFile)do Begin
    SubMenuItem(I,False);
   End;
  End;
  2:Begin
   Case Language of
    _English:FrameEmpty(8,3,49,5+High(SubMenuOptions),$30);
    Else FrameEmpty(11,3,52,5+High(SubMenuOptions),$30);
   End;
   For I:=Low(SubMenuOptions)to High(SubMenuOptions)do Begin
    SubMenuItem(I,False);
   End;
  End;
  3:Begin
   Case Language of
    _English:FrameEmpty(18,3,47,5+High(SubMenuView),$30);
    Else FrameEmpty(21,3,50,5+High(SubMenuView),$30);
   End;
   For I:=Low(SubMenuView)to High(SubMenuView)do Begin
    SubMenuItem(I,False);
   End;
  End;
  4:Begin
   FrameEmpty(33,3,62,5+High(SubMenuTree),$30);
   For I:=Low(SubMenuTree)to High(SubMenuTree)do Begin
    SubMenuItem(I,False);
   End;
  End;
  5:Begin
   If(CurrZone=3)Then Begin
    FrameEmpty(33,3,62,5+High(SubMenuHelp),$30);
   End
    Else
   FrameEmpty(41,3,70,5+High(SubMenuHelp),$30);
   For I:=Low(SubMenuHelp)to High(SubMenuHelp)do Begin
    SubMenuItem(I,False);
   End;
  End;
 End;
End;

Procedure ShowPath;
Var
 Path:String;
Begin
 TextColor(0+BLINK);
 TextBackground(7);
 GetDir(0,Path);
 GotoXY(1,3);
 Write(' ':2,Path);
 ClrEol;
End;

Procedure RefreshDrive;
Var
 CurrDrive,I:Char;
Begin
 TextColor(0+BLINK);
 TextBackground(7);
 GotoXY(1,4);
 Write(' ');
 CurrDrive:=GetCurrentDisk;
 For I:='A' to 'Z'do Begin
  If(DiskSize(1+Ord(I)-Ord('A'))<>-1)Then Begin
   If CurrDrive=I Then Begin
    TextColor($F);
    If CurrZone=0 Then TextBackground(1)
                  Else TextBackground(0);
   End
    Else
   Begin
    TextColor(0+BLINK);
    TextBackground(7);
   End;
   Write('[',I,':]');
   TextColor(00+BLINK);
   TextBackground(7);
   Write('  ');
  End;
 End;
 ClrEol;
End;

Function PreviousDrive:Boolean;
Var
 LastDrive,CurrDrive,I:Char;
Begin
 PreviousDrive:=False;
 CurrDrive:=GetCurrentDisk;
 LastDrive:='@';
 For I:='A' to 'Z'do Begin
  If(DiskSize(1+Ord(I)-Ord('A'))<>-1)Then Begin
   If CurrDrive=I Then Begin
    If LastDrive='@'Then Exit;
    ChDir(LastDrive+':');
    PreviousDrive:=True;
    Exit;
   End
    Else
   LastDrive:=I;
  End;
 End;
End;

Function NextDrive:Boolean;
Var
 CurrDrive,I:Char;
 FindCurr:Boolean;
Begin
 NextDrive:=False;
 FindCurr:=False;
 CurrDrive:=GetCurrentDisk;
 For I:='A' to 'Z'do Begin
  If(DiskSize(1+Ord(I)-Ord('A'))<>-1)Then Begin
   If FindCurr Then Begin
    ChDir(I+':');
    NextDrive:=True;
    Exit;
   End
    Else
   If CurrDrive=I Then FindCurr:=True;
  End;
 End;
End;

Procedure ShowDrive;Begin
 Box(1,4,80,5,$F0);
 RefreshDrive;
End;

Procedure ShowFunctionKey;
Const
 FunctionKey:Array[0..1]of String[15]=(
  'F10=Actions','Shift+F9=Prompt de commande'
 );
 FunctionKeyEnglish:Array[0..1]of String[15]=(
  'F10=Actions','Shift+F9=Command Prompt'
 );
 FunctionKeyGermany:Array[0..1]of String[35]=(
  'F10=MenÅleiste','UMSCHALT+F9=Eingabeaufforderung'
 );
Var
 I:Integer;
Begin
 TextColor(0);
 TextBackground(3);
 GotoXY(1,25);
 ClrEol;
 For I:=0 to High(FunctionKey) do Begin
  Case Language of
   _Germany:Write(' ',FunctionKeyGermany[I]);
   _English:Write(' ',FunctionKeyEnglish[I]);
   Else Write(' ',FunctionKey[I]);
  End;
 End;
End;

Procedure ShowDirectoryTreePanel;
Var
 ColorState:Byte;
Begin
 If CurrZone=1Then ColorState:=$1F
              Else ColorState:=$70;
 Box(1,6,40,15,$F0);
 FrameEmpty(1,6,40,15,$F0);
 Box(1,6,40,6,ColorState);
 GotoXY(12,6);
 Case Language of
  _Germany:Write('Verzeichnisstruktur');
  _English:Write('Directory Tree');
  Else Write('Arbre de repertoire');
 End;
End;

Procedure ShowFileLine(Y:Byte;Line:Word;Selected:Boolean);
Var
 Date_Time:DateTime;
Begin
 TextColor(0+BLINK);
 TextBackground(7);
 GotoXY(42,7+Y);
 If(Selected)Then Begin
  If CurrZone=2Then Write(' ',#26)
               Else Write(' ':2);
  Write(' ',#16,' ');
 End
  Else
 Write(' ':5);
 If(Selected)Then Begin
  TextColor($F);
   If CurrZone=2Then TextBackground(1)
                Else TextBackground(0+BLINK);
 End;
 Write(PadRight(Nom[Line],12));
 If(Attribt[Line]<>16)Then Write(Taille[Line]:10) Else
 If(Attribt[Line]=16)Then Begin
  If(Nom[Line]='..')Then Write(PadRight(' SOUS-REP',10))
                    Else Write(PadRight(' SUR-REP',10));
 End;
 UnPackTime(Temps[Line],Date_Time);
 Write(' ':2,Date_Time.Day:2,'/',
       PadZeroLeft(Date_Time.Month,2),'/',
       PadZeroLeft(Date_Time.Year mod 100,2));
End;

Procedure SelectFile;Begin
 ShowFileLine(FileY,FilePos,True);
End;

Procedure UnselectFile;Begin
 ShowFileLine(FileY,FilePos,False);
End;

Procedure ShowFilesPanel;
Var
 Path:String;
 ColorState:Byte;
 I:Integer;
Begin
 If CurrZone=2Then ColorState:=$1F
              Else ColorState:=$70;
 Box(41,6,80,15,$F0);
 FrameEmpty(41,6,80,15,$F0);
 Box(41,6,80,6,ColorState);
 GetDir(0,Path);
 If Path[Length(Path)]<>'\'Then Path:=Path+'\';
 Path:=Copy(Path,1,36)+'*.*';
 GotoXY(60-(Length(Path) shr 1),6);
 Write(Path);
 TextColor(0);
 TextBackground($7);
 For I:=0 to 7 do Begin
  ShowFileLine(I,FilePos-FileY+I,I=FilePos);
  If I>NombreFichierX-1 Then Break;
 End;
End;

Procedure ShowMainPanel;
Var
 StartY,Y,YP:Byte;
 CurrProgram:PProgramRec;
 ColorState:Byte;
Begin
 If CurrZone=3Then ColorState:=$1F
              Else ColorState:=$70;
 StartY:=16;
 If Not(FileManager)Then StartY:=3;
 Box(1,StartY,40,24,$F0);
 FrameEmpty(1,StartY,40,24,$F0);
 Box(1,StartY,40,StartY,ColorState);
 GotoXY(16,StartY);
 Case Language of
  _Germany:Write('Hauptgruppe');
  _English:Write('Main');
  Else Write('Principal');
 End;
 CurrProgram:=ProgramList;
 Y:=StartY+1;
 TextColor(0+BLINK);
 TextBackground(7);
 YP:=0;
 If CurrProgram<>NIL Then Repeat
  If CurrZone=3 Then Begin
   If YP=MenuY Then Begin
    GotoXY(2,Y);
    Write(#26);
    TextColor($F);
    TextBackground(1);
   End
    Else
   Begin
    TextColor(0+BLINK);
    TextBackground($7);
   End;
  End;
  GotoXY(6,Y);
  Write(CurrProgram^.Title);
  If CurrProgram^.Next=NIL Then Break;
  CurrProgram:=CurrProgram^.Next;
  Inc(Y);
  Inc(YP);
 Until CurrProgram=NIL;
End;

Procedure SelectProgram;
Var
 StartY,Y:Byte;
 I:Integer;
 CurrProgram:PProgramRec;
Begin
 StartY:=16;
 If Not(FileManager)Then StartY:=3;
 Y:=StartY+1+MenuY;
 GotoXY(2,Y);
 Write(#26);
 TextColor($F);
 TextBackground(1);
 GotoXY(6,Y);
 CurrProgram:=ProgramList;
 If MenuPos>0 Then Begin
  I:=0;
  While I<=MenuPos do Begin
   If CurrProgram^.Next=NIL Then Break;
   CurrProgram:=CurrProgram^.Next;
   Inc(I);
  End;
 End;
 Write(CurrProgram^.Title);
End;

Procedure UnselectProgram;
Var
 StartY,Y:Byte;
 I:Integer;
 CurrProgram:PProgramRec;
Begin
 StartY:=16;
 If Not(FileManager)Then StartY:=3;
 Y:=StartY+1+MenuY;
 TextColor(0);
 TextBackground($7);
 GotoXY(2,Y);
 CurrProgram:=ProgramList;
 If MenuPos>0 Then Begin
  I:=0;
  While I<=MenuPos do Begin
   If CurrProgram^.Next=NIL Then Break;
   CurrProgram:=CurrProgram^.Next;
   Inc(I);
  End;
 End;
 Write(' ':4,CurrProgram^.Title);
End;

Procedure ShowActiveTaskListPanel;
Var
 StartY:Byte;
 ColorState:Byte;
Begin
 If CurrZone=4Then ColorState:=$1F
              Else ColorState:=$70;
 StartY:=16;
 If Not(FileManager)Then StartY:=3;
 Box(41,StartY,80,24,$F0);
 FrameEmpty(41,StartY,80,24,$F0);
 Box(41,StartY,80,StartY,ColorState);
 GotoXY(50,StartY);
 Case Language of
  _English:Write('Active Task List');
  _Germany:Write('Aktive Programme');
  Else Write('Liste de tache active');
 End;
End;

Procedure UpdateFiles;
Var
 Path:String;
Begin
 GetDir(0,Path);
 If Path[Length(Path)]<>'\'Then Path:=Path+'\';
 Path:=Path+'*.*';
 ReadFiles(Path,ReadOnly+Hidden+SysFile+Archive);
 ShowFilesPanel;
End;

Procedure RefreshAll;Begin
 ShowTitle;
 ShowMenu;
 If(FileManager)Then Begin
  ShowPath;
  ShowDrive;
  ShowDirectoryTreePanel;
  UpdateFiles;
 End;
 ShowMainPanel;
 ShowActiveTaskListPanel;
 ShowFunctionKey;
End;

Procedure HideSubMenu;Begin
 RefreshAll;
End;

Procedure NotImplemented;Begin
 Box(5,11,75,13,$60);
 FrameEmpty(5,11,75,13,$60);
 GotoXY(20,12);
 Write('Cette fonctionnalitÇ n''est pas implÇmentÇ');
 ReadKey;
 HideSubMenu;
End;

Procedure Init;
Var
 Regs:Registers;
Begin
 CursorOff;
 Regs.AX:=$1003;
 Regs.BL:=$0;
 Intr($10,Regs);
 OnMenu:=False;
 MenuYMax:=7;
 FilePos:=0;
 FileY:=0;
 MenuPos:=0;
 XMenu:=0;
 MenuY:=0;
 CurrZone:=3;
 ProgramCount:=0;
 ProgramList:=NIL;
 FileManager:=True;
 LoadDosShellIni;
 RefreshAll;
End;

Procedure Run;
Var
 Terminated:Boolean;
 K:Char;
 OldZone:Byte;
 CurrProgram:PProgramRec;
 I:Integer;
Begin
 Terminated:=False;
 Repeat
  K:=ReadKey;
  If(OnMenu)Then Case K of
   #0:Case ReadKey of
    #61:Terminated:=True; { F3 }
    #72:Begin { Up }
     SubMenuItem(YMenu,True);
     If YMenu>0Then Dec(YMenu)
               Else YMenu:=YMenuMax[XMenu];
     Case XMenu of
      1:If YMenu in[6,12,14,17]Then Dec(YMenu);
      3:If YMenu in[5]Then Dec(YMenu);
     End;
     SubMenuItem(YMenu,False);
    End;
    #75:Begin { Gauche }
     HideSubMenu;
     If XMenu>1 Then Dec(XMenu)
                Else XMenu:=High(MainMenu)+1;
     If(CurrZone=3)and(XMenu=4)Then XMenu:=3;
     YMenu:=0;
     ShowMenu;
     ShowSubMenu;
    End;
    #77:Begin { Droite }
     HideSubMenu;
     If XMenu<=High(MainMenu)Then Inc(XMenu)
                             Else XMenu:=1;
     If(CurrZone=3)and(XMenu=4)Then XMenu:=5;
     YMenu:=0;
     ShowMenu;
     ShowSubMenu;
    End;
    #80:Begin { Down }
     SubMenuItem(YMenu,True);
     If YMenu<YMenuMax[XMenu]Then Inc(YMenu)
                             Else YMenu:=0;
     Case XMenu of
      1:If YMenu in[6,12,14,17]Then Inc(YMenu);
      3:If YMenu in[5]Then Inc(YMenu);
     End;
     SubMenuItem(YMenu,False);
    End;
   End;
   #13:Begin
    OnMenu:=False;
    HideSubMenu;
    Case XMenu of
     1:Case YMenu of
      18:Terminated:=True;
      Else NotImplemented;
     End;
     Else NotImplemented;
    End;
   End;
   #27:Begin
    OnMenu:=False;
    HideSubMenu;
   End;
  End
   Else
  Case K of
   #9:Begin { Tab }
    OldZone:=CurrZone;
    If CurrZone=4 Then Begin
     If(FileManager)Then CurrZone:=0
                    Else CurrZone:=3;
    End
     Else
    CurrZone:=CurrZone+1;
    Case OldZone of
     0:ShowDrive;
     1:ShowDirectoryTreePanel;
     2:ShowFilesPanel;
     3:ShowMainPanel;
     4:ShowActiveTaskListPanel;
    End;
    Case CurrZone of
     0:ShowDrive;
     1:ShowDirectoryTreePanel;
     2:ShowFilesPanel;
     3:ShowMainPanel;
     4:ShowActiveTaskListPanel;
    End;
    ShowMenu;
   End;
   #13:Begin { Enter }
    Case CurrZone of
     2:Begin
      TextColor(7);
      TextBackground(0);
      ClrScr;
      CursorOn;
      Exec(Trim(Copy(Nom[FilePos],1,8))+Trim(Copy(Nom[FilePos],9,4)),'');
      GotoXY(1,25);
      Write('Presse une touche pour retourner...');
      ReadKey;
      CursorOff;
      RefreshAll;
     End;
     3:Begin
      CurrProgram:=ProgramList;
      If MenuPos>0 Then Begin
       I:=0;
       While I<=MenuPos do Begin
        If CurrProgram^.Next=NIL Then Break;
        CurrProgram:=CurrProgram^.Next;
        Inc(I);
       End;
      End;
      TextColor(7);
      TextBackground(0);
      ClrScr;
      Exec(CurrProgram^.Command,'');
      RefreshAll;
     End;
    End;
   End;
   #27:Terminated:=True;
   #0:Begin
    K:=ReadKey;
    Case K of
     #33:Begin { Alt+F }
      XMenu:=1;YMenu:=0;
      OnMenu:=True;
      ShowMenu;
      ShowSubMenu;
     End;
     #72:Begin { Up }
      Case CurrZone of
       2:If FilePos>0 Then Begin
        UnselectFile;
        Dec(FilePos);
        If FileY>0Then Dec(FileY)
         Else
        Begin
         Window(42,7,79,14);
         InsLine;
         Window(1,1,80,25);
        End;
        SelectFile;
       End;
       3:If MenuPos>0 Then Begin
        UnselectProgram;
        Dec(MenuPos);
        If MenuY>0Then Dec(MenuY);
        SelectProgram;
       End;
      End;
     End;
     #75:Begin { Left }
      Case CurrZone of
       0:Begin
        If PreviousDrive Then UpdateFiles;
        RefreshDrive;
       End;
      End;
     End;
     #77:Begin { Right }
      Case CurrZone of
       0:Begin
        If NextDrive Then UpdateFiles;
        RefreshDrive;
       End;
      End;
     End;
     #80:Begin { Down }
      Case CurrZone of
       2:If FilePos<NombreFichierX-1 Then Begin
        UnselectFile;
        Inc(FilePos);
        If FileY<FileYMax Then Inc(FileY)
         Else
        Begin
         Window(42,7,79,14);
         DelLine;
         Window(1,1,80,25);
        End;
        SelectFile;
       End;
       3:If MenuPos<ProgramCount-1 Then Begin
        UnselectProgram;
        Inc(MenuPos);
        If(MenuY<MenuYMax)Then Inc(MenuY);
        SelectProgram;
       End;
      End;
     End;
     #92:Begin { Shift+F9 }
      TextColor(7);
      TextBackground(0);
      ClrScr;
      Exec(GetEnv('COMSPEC'),'');
      RefreshAll;
     End;
    End;
   End;
  End;
 Until Terminated;
End;

Procedure Done;Begin
 TextBackground(0);
 TextColor(7);
 ClrScr;
 GotoXY(1,1);
 CursorOn;
End;

Var
 I:Integer;

BEGIN
 ShowASCII128:=False;
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ENDIF}
 {$ENDIF}
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
    WriteLn('Startet die DOS-Shell.');
    WriteLn;
    WriteLn('DOSSHELL [/ASCII128]');
   End;
   Else Begin
    WriteLn('DOSSHELL : Cette commande permet de lancer DOSSHELL.');
    WriteLn;
    WriteLn('Syntaxe : DOSSHELL [/ASCII128]');
    WriteLn;
    WriteLn(' /ASCII128   Ce parametre permet de lancer en mode compatibilite 128 caracteres seulement.');
   End;
  End;
  Halt;
 End;
 If ParamCount>0Then For I:=1 to ParamCount do Begin
  If StrToUpper(ParamStr(I))='/ASCII128'Then ShowASCII128:=True
   Else
  Begin
   WriteLn('Parametre non reconnu');
   Halt;
  End;
 End;
 Init;
 Run;
 Done;
END.