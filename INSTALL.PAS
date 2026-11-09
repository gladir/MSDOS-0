{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/msdos-0)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program INSTALL;

{ Programme d'installation de MSDOS-0 (dans le style de l'Install de
  MS-DOS 6.22) : installe le systeme d'exploitation sur un disque dur.

  Ecrans bleus plein texte (memoire video directe), francais ou anglais.
  Deroulement :
    1. bienvenue, 2. parametres systeme (date, pays, langue),
    3. repertoire d'installation (defaut C:\DOS),
    4. copie des fichiers decrits par INSTALL.INF (demande des disquettes
       suivantes), 5. disque amorcable : secteur de boot MS-DOS, chargeur MBR
       et partition active, fichiers systeme au debut du disque,
    6. CONFIG.SYS et AUTOEXEC.BAT (les anciens deviennent *.OLD),
    7. fin et redemarrage.

  Le disque cible doit deja etre partitionne (FDISK) et formate (FORMAT).
  INSTALL.INF (un fichier par ligne : disquette,destination,nom,taille ;
  destination \ = racine, sinon le repertoire d'installation) est produit
  par TOOLS\MAKEDISK.PAS (option /INF). }

{$M 16384,0,32768}

Uses DOS;

{$I BOOTCODE.INC}

Const
 MaxEntries=120;
 MaxItems=8;
 CopyBufSize=16384;
 kEnter=13;
 kEsc=27;
 kBack=8;
 kF1=$3B00;
 kF3=$3D00;
 kF5=$3F00;
 kUp=$4800;
 kDown=$5000;
 { codes pays : indice, nom francais, nom anglais, code de pays, langue }
 CountryCount=6;
 LangCount=5;

Type
 TEntry=Record
  Name:String[12];
  Root:Boolean;
  Disk:Byte;
  Size:LongInt;
 End;
 TSec=Array[0..511]of Byte;

Var
 Entries:Array[1..MaxEntries]of TEntry;
 EntryCount,DiskTotal:Integer;
 VidSeg:Word;
 Mono:Boolean;
 Lang:Integer;          { 0 = francais, 1 = anglais (langue de l'ecran) }
 SysLang:Integer;       { langue du systeme installe (LangCodes) }
 CountryIdx:Integer;
 InstDir:String;
 SrcDrive:Char;
 SrcDir:String;
 TotalBytes,DoneBytes:LongInt;
 CurDisk:Integer;
 ListItems:Array[1..MaxItems]of String[40];
 { couleurs }
 aNorm,aTitle,aHi,aDlg,aBar,aGauge,aBorder,aTxt:Byte;
 { acces disque brut }
 Unit8:Byte;
 PartLBA:LongInt;
 Spt,Heads:Word;
 { messages de l'ecran de copie }
 CopyNote:String;
 CurFile:String;
 LastErr:Integer;
 LastStage:Char;

Const
 LangCodes:Array[1..LangCount]of String[2]=('FR','EN','GR','IT','SP');
 CountryCodes:Array[1..CountryCount]of Word=(33,2,32,1,44,49);

Function T(Const Fr,En:String):String;
Begin
 If Lang=0 Then T:=Fr Else T:=En;
End;

Function UpStr(S:String):String;
Var
 I:Integer;
Begin
 For I:=1 to Length(S)do
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 UpStr:=S;
End;

Function NumStr(N:LongInt):String;
Var
 S:String;
Begin
 Str(N,S);
 NumStr:=S;
End;

Function Pad2(N:Integer):String;
Begin
 If N<10 Then Pad2:='0'+NumStr(N)Else Pad2:=NumStr(N);
End;

Function PadTo(S:String;N:Integer):String;
Begin
 While Length(S)<N do S:=S+' ';
 PadTo:=S;
End;

Function CountryName(I:Integer):String;
Begin
 Case I of
  1:CountryName:=T('France','France');
  2:CountryName:=T('Canada (Fran‡ais)','Canada (French)');
  3:CountryName:=T('Belgique','Belgium');
  4:CountryName:=T('tats-Unis','United States');
  5:CountryName:=T('Royaume-Uni','United Kingdom');
 Else
  CountryName:=T('Allemagne','Germany');
 End;
End;

Function LangName(I:Integer):String;
Begin
 Case I of
  1:LangName:='Fran‡ais';
  2:LangName:='English';
  3:LangName:='Deutsch';
  4:LangName:='Italiano';
 Else
  LangName:='Espa¤ol';
 End;
End;

{ ---------------------------------------------------------------------- }
{ Affichage direct en memoire video                                       }
{ ---------------------------------------------------------------------- }

Procedure SetTheme;
Begin
 If Mono Then Begin
  aNorm:=$07;aTitle:=$0F;aHi:=$70;aDlg:=$70;aBar:=$70;aGauge:=$70;
  aBorder:=$70;aTxt:=$70;
 End
 Else Begin
  aNorm:=$1E;aTitle:=$1F;aHi:=$70;aDlg:=$30;aBar:=$70;aGauge:=$E0;
  aBorder:=$30;aTxt:=$1E;
 End;
End;

Procedure PutCh(X,Y:Integer;Ch:Char;A:Byte);
Var
 O:Word;
Begin
 If(X<1)or(X>80)or(Y<1)or(Y>25)Then Exit;
 O:=(Y-1)*160+(X-1)*2;
 Mem[VidSeg:O]:=Ord(Ch);
 Mem[VidSeg:O+1]:=A;
End;

Procedure PutStr(X,Y:Integer;Const S:String;A:Byte);
Var
 I:Integer;
Begin
 For I:=1 to Length(S)do PutCh(X+I-1,Y,S[I],A);
End;

Procedure Fill(X1,Y1,X2,Y2:Integer;Ch:Char;A:Byte);
Var
 X,Y:Integer;
Begin
 For Y:=Y1 to Y2 do
  For X:=X1 to X2 do PutCh(X,Y,Ch,A);
End;

{ Cadre (double trait si Dbl) ; l'interieur est efface }
Procedure Box(X1,Y1,X2,Y2:Integer;Dbl:Boolean;A:Byte);
Var
 X,Y:Integer;
 H,V,TL,TR,BL,BR:Char;
Begin
 If Dbl Then Begin
  H:=#205;V:=#186;TL:=#201;TR:=#187;BL:=#200;BR:=#188;
 End
 Else Begin
  H:=#196;V:=#179;TL:=#218;TR:=#191;BL:=#192;BR:=#217;
 End;
 Fill(X1,Y1,X2,Y2,' ',A);
 For X:=X1+1 to X2-1 do Begin PutCh(X,Y1,H,A);PutCh(X,Y2,H,A);End;
 For Y:=Y1+1 to Y2-1 do Begin PutCh(X1,Y,V,A);PutCh(X2,Y,V,A);End;
 PutCh(X1,Y1,TL,A);PutCh(X2,Y1,TR,A);PutCh(X1,Y2,BL,A);PutCh(X2,Y2,BR,A);
End;

{ Texte avec retour a la ligne ; retourne la prochaine ligne libre }
Function PutWrap(X,Y,W:Integer;Const S:String;A:Byte):Integer;
Var
 P,L,Cut:Integer;
 Part:String;
Begin
 P:=1;
 While P<=Length(S)do Begin
  L:=Length(S)-P+1;
  If L>W Then Begin
   Cut:=W;
   While(Cut>1)and(S[P+Cut]<>' ')do Dec(Cut);
   If Cut<=1 Then Cut:=W;
   L:=Cut;
  End;
  Part:=Copy(S,P,L);
  While(Length(Part)>0)and(Part[Length(Part)]=' ')do Dec(Part[0]);
  PutStr(X,Y,Part,A);
  Inc(Y);
  P:=P+L;
  While(P<=Length(S))and(S[P]=' ')do Inc(P);
 End;
 PutWrap:=Y;
End;

Function PutBullet(X,Y,W:Integer;Const S:String;A:Byte):Integer;
Begin
 PutCh(X,Y,#7,A);
 PutBullet:=PutWrap(X+2,Y,W-2,S,A);
End;

Procedure Clear;
Begin
 Fill(1,1,80,25,' ',aNorm);
End;

Procedure Title;
Var
 S:String;
Begin
 S:=T('Installation de MSDOS-0','MSDOS-0 Setup');
 PutStr(2,2,S,aTitle);
 Fill(2,3,Length(S)+3,3,#205,aTitle);
End;

Procedure StatusBar(Const S:String);
Begin
 Fill(1,25,80,25,' ',aBar);
 PutStr(1,25,S,aBar);
End;

Function KeysEnterF1F3:String;
Begin
 KeysEnterF1F3:=T(' ENTREE=Continuer  F1=Aide  F3=Quitter  F5=Noir/blanc',
                  ' ENTER=Continue  F1=Help  F3=Exit  F5=Black/white');
End;

Procedure CursorOff;
Var
 R:Registers;
Begin
 R.AH:=1;R.CX:=$2000;Intr($10,R);
End;

Procedure CursorOn;
Var
 R:Registers;
Begin
 R.AH:=1;R.CX:=$0607;Intr($10,R);
End;

Procedure GotoXYb(X,Y:Integer);
Var
 R:Registers;
Begin
 R.AH:=2;R.BH:=0;R.DH:=Y-1;R.DL:=X-1;Intr($10,R);
End;

{ Touche normalisee : code ASCII seul pour une touche normale (le code de
  balayage varie selon l'emulateur), AX complet (AL=0) pour une touche
  etendue : F1 = $3B00, fleche haut = $4800... }
Function GetKey:Word;
Var
 R:Registers;
Begin
 R.AH:=0;
 Intr($16,R);
 If(R.AL<>0)and((R.AL<>$E0)or(R.AH=0))Then GetKey:=R.AL
 Else GetKey:=Word(R.AH)shl 8;
End;

Procedure InitVideo;
Var
 R:Registers;
Begin
 R.AH:=$0F;Intr($10,R);
 If R.AL=7 Then VidSeg:=$B000 Else Begin
  If R.AL<>3 Then Begin R.AH:=0;R.AL:=3;Intr($10,R);End;
  VidSeg:=$B800;
  { fond clair sans clignotement (barre de progression jaune) }
  R.AX:=$1003;R.BL:=0;Intr($10,R);
 End;
End;

Procedure RestoreScreen;
Var
 R:Registers;
Begin
 R.AH:=0;R.AL:=3;Intr($10,R);
 CursorOn;
End;

{ ---------------------------------------------------------------------- }
{ Boites de dialogue                                                      }
{ ---------------------------------------------------------------------- }

Procedure DlgBox(X1,Y1,X2,Y2:Integer);
Begin
 Fill(X1+1,Y2+1,X2+1,Y2+1,' ',$08);
 Fill(X2+1,Y1+1,X2+2,Y2+1,' ',$08);
 Box(X1,Y1,X2,Y2,True,aBorder);
End;

Function ConfirmExit:Boolean;
Var
 K:Word;
 Y:Integer;
Begin
 Clear;
 Title;
 DlgBox(8,6,72,18);
 PutStr(10,6,T(' Installation non termin‚e ',' Setup is not complete '),aDlg);
 Y:=PutWrap(11,8,58,T('L''installation de MSDOS-0 n''est pas termin‚e. '+
  'Si vous quittez maintenant, vous devrez relancer Install pour '+
  'installer MSDOS-0.',
  'MSDOS-0 Setup is not complete. If you exit now, you will need to run '+
  'Setup again to install MSDOS-0.'),aDlg);
 Y:=PutBullet(12,Y+1,57,T('Pour reprendre l''installation, appuyez sur ENTREE.',
  'To continue Setup, press ENTER.'),aDlg);
 Y:=PutBullet(12,Y+1,57,T('Pour quitter Install, appuyez sur F3.',
  'To exit Setup, press F3.'),aDlg);
 StatusBar(T(' ENTREE=Continuer  F3=Quitter',' ENTER=Continue  F3=Exit'));
 Repeat
  K:=GetKey;
 Until(K=kEnter)or(K=kF3);
 ConfirmExit:=K=kF3;
End;

Procedure QuitInstall;
Begin
 RestoreScreen;
 WriteLn(T('Pour installer MSDOS-0, tapez INSTALL … l''invite de commande.',
           'To install MSDOS-0, type INSTALL at the command prompt.'));
 Halt(1);
End;

{ Boite d'erreur : l'installation s'arrete }
Procedure Fatal(Const Fr,En:String);
Var
 Y:Integer;
 K:Word;
Begin
 Clear;
 Title;
 DlgBox(8,6,72,16);
 PutStr(10,6,T(' Erreur ',' Error '),aDlg);
 Y:=PutWrap(11,8,58,T(Fr,En),aDlg);
 PutStr(11,Y+2,T('Appuyez sur ENTREE pour quitter Install.',
                 'Press ENTER to exit Setup.'),aDlg);
 StatusBar(T(' ENTREE=Quitter',' ENTER=Exit'));
 Repeat
  K:=GetKey;
 Until K=kEnter;
 RestoreScreen;
 Halt(2);
End;

Procedure ShowHelp(N:Integer);
Var
 Y:Integer;
 K:Word;
Begin
 Clear;
 Title;
 PutStr(4,5,T('Aide d''Install','Setup Help'),aTitle);
 Y:=7;
 Case N of
  1:Y:=PutWrap(4,Y,72,T('Install copie les fichiers de MSDOS-0 sur votre '+
    'disque dur et le rend amor‡able. Avant de commencer, le disque dur '+
    'doit avoir ‚t‚ partitionn‚ avec FDISK et format‚ avec FORMAT. Faites '+
    'une copie de sauvegarde de vos fichiers importants avec BACKUP.',
    'Setup copies the MSDOS-0 files to your hard disk and makes it '+
    'bootable. Before you start, the hard disk must have been partitioned '+
    'with FDISK and formatted with FORMAT. Back up your important files '+
    'with BACKUP.'),aNorm);
  2:Y:=PutWrap(4,Y,72,T('Utilisez les touches HAUT et BAS pour choisir un '+
    'paramŠtre puis appuyez sur ENTREE pour le modifier. La langue choisie '+
    'est aussi celle des messages des commandes MSDOS-0 install‚es '+
    '(variable LANGUAGE de AUTOEXEC.BAT).',
    'Use the UP and DOWN keys to select a setting, then press ENTER to '+
    'change it. The selected language is also the language of the messages '+
    'of the installed MSDOS-0 commands (LANGUAGE variable in '+
    'AUTOEXEC.BAT).'),aNorm);
  3:Y:=PutWrap(4,Y,72,T('Tapez le chemin du r‚pertoire o— placer les '+
    'fichiers de MSDOS-0 (par exemple C:\DOS) puis appuyez sur ENTREE. '+
    'Les fichiers systŠme IO.SYS, MSDOS.SYS et COMMAND.COM sont toujours '+
    'copi‚s … la racine du disque.',
    'Type the path of the directory for the MSDOS-0 files (for example '+
    'C:\DOS), then press ENTER. The system files IO.SYS, MSDOS.SYS and '+
    'COMMAND.COM are always copied to the root of the disk.'),aNorm);
 Else
  Y:=PutWrap(4,Y,72,T('Install copie les fichiers. Quand une autre '+
    'disquette est n‚cessaire, ins‚rez-la dans le lecteur indiqu‚ puis '+
    'appuyez sur ENTREE.',
    'Setup is copying files. When another disk is needed, insert it in '+
    'the drive shown and press ENTER.'),aNorm);
 End;
 StatusBar(T(' ENTREE=Retour',' ENTER=Return'));
 Repeat
  K:=GetKey;
 Until(K=kEnter)or(K=kEsc);
End;

{ Gestion commune de F1 (aide), F3 (quitter) et F5 (noir/blanc) }
Procedure Nav(K:Word;HelpTopic:Integer);
Begin
 If K=kF1 Then ShowHelp(HelpTopic)
 Else If K=kF3 Then Begin
  If ConfirmExit Then QuitInstall;
 End
 Else If K=kF5 Then Begin Mono:=Not Mono;SetTheme;End;
End;

{ Liste de choix dans une boite ; retourne l'indice (0 = annule) }
Function PickList(Const Caption:String;Count,Cur:Integer):Integer;
Var
 I,Y1,Y2:Integer;
 K:Word;
Begin
 Y1:=8;Y2:=Y1+Count+3;
 Repeat
  DlgBox(20,Y1,60,Y2);
  PutStr(22,Y1,' '+Caption+' ',aDlg);
  For I:=1 to Count do
   If I=Cur Then PutStr(23,Y1+1+I,PadTo(' '+ListItems[I],36),aHi)
   Else PutStr(23,Y1+1+I,PadTo(' '+ListItems[I],36),aDlg);
  K:=GetKey;
  If(K=kUp)and(Cur>1)Then Dec(Cur)
  Else If(K=kDown)and(Cur<Count)Then Inc(Cur)
  Else If K=kF5 Then Begin Mono:=Not Mono;SetTheme;End
  Else If K=kEsc Then Begin PickList:=0;Exit;End;
 Until K=kEnter;
 PickList:=Cur;
End;

{ Saisie d'une ligne dans une zone ; retourne la touche de fin }
Function EditLine(X,Y,W:Integer;Var S:String):Word;
Var
 K:Word;
 C:Char;
 First:Boolean;
Begin
 First:=True;
 CursorOn;
 Repeat
  Fill(X,Y,X+W-1,Y,' ',aHi);
  PutStr(X,Y,S,aHi);
  GotoXYb(X+Length(S),Y);
  K:=GetKey;
  C:=Chr(K and $FF);
  If(K and $FF)>=32 Then Begin
   If First Then S:='';
   If Length(S)<W-1 Then S:=S+C;
  End
  Else If(K=kBack)and(Length(S)>0)Then Dec(S[0]);
  If(K and $FF)<>0 Then First:=False;
 Until(K=kEnter)or(K=kEsc)or(K=kF1)or(K=kF3)or(K=kF5);
 CursorOff;
 EditLine:=K;
End;

{ ---------------------------------------------------------------------- }
{ Lecture de INSTALL.INF                                                  }
{ ---------------------------------------------------------------------- }

Function SplitField(Var S:String):String;
Var
 P:Integer;
Begin
 P:=Pos(',',S);
 If P=0 Then Begin SplitField:=S;S:='';End
 Else Begin SplitField:=Copy(S,1,P-1);S:=Copy(S,P+1,255);End;
End;

Procedure ReadInf;
Var
 F:Text;
 L,Fld:String;
 Code:Integer;
 V:LongInt;
 Err:Integer;
Begin
 EntryCount:=0;DiskTotal:=1;TotalBytes:=0;
 Assign(F,SrcDir+'INSTALL.INF');
 {$I-}Reset(F);{$I+}
 Err:=IOResult;
 If Err<>0 Then
  Fatal('Le fichier INSTALL.INF est introuvable sur la disquette '+
        'd''installation.',
        'INSTALL.INF was not found on the setup disk.');
 While Not Eof(F)do Begin
  ReadLn(F,L);
  While(Length(L)>0)and(L[Length(L)]in[#13,#10,' '])do Dec(L[0]);
  If(L<>'')and(L[1]in['0'..'9'])and(EntryCount<MaxEntries)Then Begin
   Inc(EntryCount);
   Fld:=SplitField(L);
   Val(Fld,V,Code);
   Entries[EntryCount].Disk:=Byte(V);
   If V>DiskTotal Then DiskTotal:=V;
   Fld:=SplitField(L);
   Entries[EntryCount].Root:=Fld='\';
   Entries[EntryCount].Name:=SplitField(L);
   Fld:=SplitField(L);
   Val(Fld,V,Code);
   Entries[EntryCount].Size:=V;
   TotalBytes:=TotalBytes+V;
  End;
 End;
 Close(F);
 If EntryCount=0 Then
  Fatal('INSTALL.INF ne contient aucun fichier … installer.',
        'INSTALL.INF does not list any file to install.');
End;

{ ---------------------------------------------------------------------- }
{ Ecrans                                                                  }
{ ---------------------------------------------------------------------- }

Procedure ScreenWelcome;
Var
 K:Word;
 Y:Integer;
Begin
 Repeat
  Clear;
  Title;
  PutStr(8,6,T('Bienvenue … Install.','Welcome to Setup.'),aNorm);
  PutStr(8,8,T('Le programme d''installation installe MSDOS-0.',
               'The Setup program installs MSDOS-0.'),aNorm);
  Y:=PutBullet(10,10,66,T('Pour installer MSDOS-0 maintenant, appuyez sur '+
    'ENTREE.','To install MSDOS-0 now, press ENTER.'),aNorm);
  Y:=PutBullet(10,Y+1,66,T('Pour plus d''informations … propos de '+
    'l''installation, appuyez sur F1 ou consultez la documentation de '+
    'MSDOS-0.','For more information about Setup, press F1 or see the '+
    'MSDOS-0 documentation.'),aNorm);
  Y:=PutBullet(10,Y+1,66,T('Pour quitter Install sans installer MSDOS-0, '+
    'appuyez sur F3.','To exit Setup without installing MSDOS-0, press F3.'),
    aNorm);
  PutStr(8,Y+1,T('Remarque :','Note:'),aNorm);
  Y:=PutWrap(20,Y+1,58,T('Si vous n''avez pas r‚alis‚ de sauvegarde de '+
    'vos fichiers r‚cemment, vous devriez le faire avant l''installation '+
    'de MSDOS-0.','If you have not backed up your files recently, you '+
    'should do so before installing MSDOS-0.'),aNorm);
  Y:=PutWrap(20,Y,58,T('Pour sauvegarder vos fichiers, appuyez sur F3 pour '+
    'quitter Install maintenant puis r‚alisez une sauvegarde avec un '+
    'programme de sauvegarde (BACKUP).','To back up your files, press F3 to '+
    'exit Setup now, then back them up with a backup program (BACKUP).'),
    aNorm);
  PutStr(8,Y+1,T('Pour continuer le programme d''installation, appuyez sur '+
    'ENTREE.','To continue Setup, press ENTER.'),aNorm);
  StatusBar(KeysEnterF1F3);
  K:=GetKey;
  If K=kEnter Then Exit;
  Nav(K,1);
 Until False;
End;

Function DateTimeStr:String;
Var
 Y,M,D,Dw,H,Mi,S,S100:Word;
Begin
 GetDate(Y,M,D,Dw);GetTime(H,Mi,S,S100);
 DateTimeStr:=NumStr(Y)+'-'+Pad2(M)+'-'+Pad2(D)+' '+Pad2(H)+':'+Pad2(Mi);
End;

{ Saisie de AAAA-MM-JJ HH:MM ; ignore silencieusement une saisie invalide }
Procedure ChangeDateTime;
Var
 S:String;
 K:Word;
 Y,M,D,H,Mi:LongInt;
 C1,C2,C3,C4,C5:Integer;
Begin
 S:=DateTimeStr;
 DlgBox(14,8,66,13);
 PutStr(16,8,T(' Date et heure ',' Date and time '),aDlg);
 PutStr(17,10,T('Tapez la date et l''heure (AAAA-MM-JJ HH:MM) :',
                'Type the date and time (YYYY-MM-DD HH:MM):'),aDlg);
 K:=EditLine(17,11,20,S);
 If K<>kEnter Then Exit;
 Val(Copy(S,1,4),Y,C1);Val(Copy(S,6,2),M,C2);Val(Copy(S,9,2),D,C3);
 Val(Copy(S,12,2),H,C4);Val(Copy(S,15,2),Mi,C5);
 If(C1+C2+C3+C4+C5=0)and(M>=1)and(M<=12)and(D>=1)and(D<=31)and(H<=23)and
   (Mi<=59)Then Begin
  SetDate(Word(Y),Word(M),Word(D));
  SetTime(Word(H),Word(Mi),0,0);
 End;
End;

Procedure ChoosePays;
Var
 I,R:Integer;
Begin
 For I:=1 to CountryCount do ListItems[I]:=CountryName(I);
 R:=PickList(T('Pays','Country'),CountryCount,CountryIdx);
 If R>0 Then Begin
  CountryIdx:=R;
  Case R of
   4,5:SysLang:=2;
   6:SysLang:=3;
  Else
   SysLang:=1;
  End;
  If SysLang=1 Then Lang:=0 Else Lang:=1;
 End;
End;

Procedure ChooseLangue;
Var
 I,R:Integer;
Begin
 For I:=1 to LangCount do ListItems[I]:=LangName(I);
 R:=PickList(T('Langue','Language'),LangCount,SysLang);
 If R>0 Then Begin
  SysLang:=R;
  If R=1 Then Lang:=0 Else Lang:=1;
 End;
End;

Procedure ScreenSettings;
Var
 K:Word;
 Sel,Y:Integer;
 Attr:Byte;
Begin
 Sel:=4;
 Repeat
  Clear;
  Title;
  PutStr(8,6,T('Install utilisera les paramŠtres systŠme suivants :',
               'Setup will use the following system settings:'),aNorm);
  Box(7,8,66,13,False,aNorm);
  For Y:=1 to 4 do Begin
   If Sel=Y Then Attr:=aHi Else Attr:=aNorm;
   Fill(8,8+Y,65,8+Y,' ',Attr);
   Case Y of
    1:Begin PutStr(10,9,T('Date/Heure :','Date/Time :'),Attr);
       PutStr(31,9,DateTimeStr,Attr);End;
    2:Begin PutStr(10,10,T('Pays :','Country :'),Attr);
       PutStr(31,10,CountryName(CountryIdx),Attr);End;
    3:Begin PutStr(10,11,T('Langue :','Language :'),Attr);
       PutStr(31,11,LangName(SysLang),Attr);End;
   Else
    PutStr(10,12,T('Les paramŠtres sont corrects.',
      'The settings are correct.'),Attr);
   End;
  End;
  Y:=PutWrap(8,15,66,T('Si tous les paramŠtres sont corrects, appuyez sur '+
    'ENTREE.','If all settings are correct, press ENTER.'),aNorm);
  Y:=PutWrap(8,Y+1,66,T('Pour modifier un paramŠtre, appuyez sur les '+
    'touches de direction HAUT ou BAS pour le s‚lectionner. Appuyez '+
    'ensuite sur ENTREE pour visualiser les options.',
    'To change a setting, press the UP or DOWN arrow key to select it. '+
    'Then press ENTER to see the options.'),aNorm);
  StatusBar(KeysEnterF1F3);
  K:=GetKey;
  If K=kUp Then Begin If Sel>1 Then Dec(Sel);End
  Else If K=kDown Then Begin If Sel<4 Then Inc(Sel);End
  Else If K=kEnter Then Begin
   Case Sel of
    1:ChangeDateTime;
    2:ChoosePays;
    3:ChooseLangue;
   Else
    Exit;
   End;
  End
  Else Nav(K,2);
 Until False;
End;

Function ValidDir(Const S:String):Boolean;
Var
 I:Integer;
Begin
 ValidDir:=False;
 If(Length(S)<3)or(Not(UpCase(S[1])in['A'..'Z']))or(S[2]<>':')or
   (S[3]<>'\')Then Exit;
 For I:=3 to Length(S)do
  If S[I]in[' ','*','?','"','/','<','>','|',',',';','='] Then Exit;
 ValidDir:=True;
End;

Procedure ScreenDirectory;
Var
 K:Word;
 S:String;
 Y:Integer;
Begin
 S:='C:\DOS';
 Repeat
  Clear;
  Title;
  Y:=PutWrap(10,6,60,T('Install placera vos fichiers MSDOS-0 dans le '+
    'r‚pertoire suivant :','Setup will place your MSDOS-0 files in the '+
    'following directory:'),aNorm);
  Fill(10,9,70,9,' ',aHi);
  PutStr(10,9,S,aHi);
  Y:=PutWrap(10,11,60,T('Pour placer les fichiers MSDOS-0 dans ce '+
    'r‚pertoire, appuyez sur ENTREE.','To place the MSDOS-0 files in this '+
    'directory, press ENTER.'),aNorm);
  Y:=PutWrap(10,Y+1,60,T('Pour placer les fichiers MSDOS-0 dans un '+
    'r‚pertoire diff‚rent, tapez son chemin et appuyez sur ENTREE.',
    'To place the MSDOS-0 files in a different directory, type its path '+
    'and press ENTER.'),aNorm);
  StatusBar(KeysEnterF1F3);
  K:=EditLine(10,9,60,S);
  If K=kEnter Then Begin
   S:=UpStr(S);
   While(Length(S)>3)and(S[Length(S)]='\')do Dec(S[0]);
   If ValidDir(S)Then Begin InstDir:=S;Exit;End;
  End
  Else Nav(K,3);
 Until False;
End;

{ ---------------------------------------------------------------------- }
{ Ecran de copie                                                          }
{ ---------------------------------------------------------------------- }

Const
 GaugeW=70;

Procedure DrawGauge;
Var
 Pct,N:LongInt;
Begin
 If TotalBytes>0 Then Pct:=DoneBytes*100 div TotalBytes Else Pct:=100;
 If Pct>100 Then Pct:=100;
 N:=Pct*GaugeW div 100;
 PutStr(5,16,NumStr(Pct)+T('% effectu‚','% complete')+'       ',aNorm);
 Fill(6,18,5+GaugeW,18,' ',aNorm);
 If N>0 Then Fill(6,18,5+N,18,' ',aGauge);
 Fill(3,20,78,20,' ',aNorm);
 If CurFile<>'' Then PutStr(5,20,CopyNote+' '+CurFile,aNorm);
End;

Procedure DrawCopyScreen;
Var
 Y:Integer;
Begin
 Clear;
 Title;
 Y:=PutWrap(8,6,66,T('MSDOS-0 est un clone de MS-DOS ‚crit entiŠrement en '+
   'Pascal.','MSDOS-0 is an MS-DOS clone written entirely in Pascal.'),aNorm);
 Y:=PutWrap(8,Y+1,66,T('Tous les programmes install‚s sont fournis avec '+
   'leur code source : vous pouvez les compiler avec Turbo Pascal ou Free '+
   'Pascal.','All the installed programs come with their source code: you '+
   'can compile them with Turbo Pascal or Free Pascal.'),aNorm);
 Y:=PutWrap(8,Y+1,66,T('Tapez DIR '+InstDir+' … l''invite pour voir les '+
   'commandes install‚es.','Type DIR '+InstDir+' at the prompt to see the '+
   'installed commands.'),aNorm);
 Box(4,17,5+GaugeW+1,19,False,aNorm);
 StatusBar(T(' ENTREE=Continuer  F3=Quitter',' ENTER=Continue  F3=Exit'));
 DrawGauge;
End;

Function FileThere(Const Path:String):Boolean;
Var
 SR:SearchRec;
Begin
 FindFirst(Path,AnyFile,SR);
 FileThere:=DosError=0;
End;

{ Demande la disquette N (lecteur source) }
Procedure AskDisk(N:Integer;Retry:Boolean);
Var
 K:Word;
Begin
 Repeat
  DlgBox(14,8,66,14);
  PutStr(18,10,T('Ins‚rez la disquette dans le lecteur '+SrcDrive+':',
                 'Insert the disk in drive '+SrcDrive+':'),aDlg);
  PutStr(18,11,T('Disquette ','Disk ')+NumStr(N),aDlg);
  If Retry Then PutStr(18,12,T('Ce n''est pas la bonne disquette.',
                               'This is not the correct disk.'),aDlg)
  Else PutStr(18,12,T('Appuyez ensuite sur ENTREE.','Then press ENTER.'),aDlg);
  K:=GetKey;
  If K=kF3 Then Begin
   If ConfirmExit Then QuitInstall;
   DrawCopyScreen;
  End
  Else If K=kF5 Then Begin Mono:=Not Mono;SetTheme;DrawCopyScreen;End;
 Until K=kEnter;
End;

Procedure MakeDirs(Const Path:String);
Var
 I:Integer;
 Err:Integer;
Begin
 For I:=4 to Length(Path)do
  If(Path[I]='\')or(I=Length(Path))Then Begin
   If Path[I]='\' Then Begin
    {$I-}MkDir(Copy(Path,1,I-1));{$I+}
   End
   Else Begin
    {$I-}MkDir(Path);{$I+}
   End;
   Err:=IOResult;
  End;
End;

{ Copie un fichier ; retourne False en cas d'echec }
Function CopyOne(Const Src,Dst:String;Hidden:Boolean):Boolean;
Var
 FS,FD:File;
 Buf:Pointer;
 Got,Put:Word;
 Err,At:Word;
 Ok:Boolean;
Begin
 CopyOne:=False;
 LastErr:=0;LastStage:='?';
 { un ancien fichier en lecture seule est ecrase }
 Assign(FD,Dst);
 {$I-}GetFAttr(FD,At);{$I+}
 Err:=IOResult;
 If Err=0 Then Begin
  {$I-}SetFAttr(FD,0);{$I+}
  Err:=IOResult;
 End;
 Assign(FS,Src);
 FileMode:=0;  { lecture seule : IO.SYS est cache et en lecture seule }
 {$I-}Reset(FS,1);{$I+}
 If IOResult<>0 Then Begin FileMode:=2;Exit;End;
 FileMode:=2;
 {$I-}Rewrite(FD,1);{$I+}
 Err:=IOResult;
 If Err<>0 Then Begin
  LastErr:=Err;LastStage:='C';
  Close(FS);Exit;
 End;
 GetMem(Buf,CopyBufSize);
 Ok:=True;
 Repeat
  {$I-}BlockRead(FS,Buf^,CopyBufSize,Got);{$I+}
  Err:=IOResult;
  If Err<>0 Then Begin Ok:=False;LastErr:=Err;LastStage:='R';End
  Else If Got>0 Then Begin
   {$I-}BlockWrite(FD,Buf^,Got,Put);{$I+}
   Err:=IOResult;
   If(Err<>0)or(Put<>Got)Then Begin Ok:=False;LastErr:=Err;LastStage:='W';End;
   DoneBytes:=DoneBytes+Got;
   DrawGauge;
  End;
 Until(Got=0)or(Not Ok);
 FreeMem(Buf,CopyBufSize);
 Close(FS);
 {$I-}Close(FD);{$I+}
 Err:=IOResult;
 If Hidden Then Begin
  Assign(FD,Dst);
  {$I-}SetFAttr(FD,$27);{$I+}
  Err:=IOResult;
 End;
 CopyOne:=Ok;
End;

Function ClusterRound(Size:LongInt):LongInt;
Begin
 ClusterRound:=((Size+4095)div 4096)*4096;
End;

Procedure CheckTarget;
Var
 Drv:Integer;
 Free,Need:LongInt;
 I:Integer;
Begin
 Drv:=Ord(UpCase(InstDir[1]))-64;
 Free:=DiskFree(Drv);
 If Free<0 Then
  Fatal('Install ne trouve pas le disque '+InstDir[1]+': ou il n''est pas '+
        'format‚. Partitionnez le disque dur avec FDISK puis formatez-le '+
        'avec FORMAT '+InstDir[1]+': /S, et relancez Install.',
        'Setup cannot find drive '+InstDir[1]+': or it is not formatted. '+
        'Partition the hard disk with FDISK, format it with FORMAT '+
        InstDir[1]+': /S, then run Setup again.');
 Need:=0;
 For I:=1 to EntryCount do Need:=Need+ClusterRound(Entries[I].Size);
 If Free<Need Then
  Fatal('Espace disque insuffisant sur '+InstDir[1]+': : '+
        NumStr((Need+1023)div 1024)+' Ko requis, '+NumStr(Free div 1024)+
        ' Ko disponibles.',
        'Not enough disk space on '+InstDir[1]+': '+
        NumStr((Need+1023)div 1024)+' KB required, '+NumStr(Free div 1024)+
        ' KB available.');
End;

Procedure CopyFiles;
Var
 I:Integer;
 Dst,Src:String;
 Drv:String;
 DirMade:Boolean;
Begin
 Drv:=InstDir[1]+':\';
 DoneBytes:=0;CurFile:='';
 CopyNote:=T('Copie de','Copying');
 DrawCopyScreen;
 { le repertoire est cree apres les fichiers systeme : IO.SYS et MSDOS.SYS
   doivent rester les deux premieres entrees de la racine }
 DirMade:=False;
 For I:=1 to EntryCount do Begin
  If Entries[I].Disk<>CurDisk Then Begin
   AskDisk(Entries[I].Disk,False);
   CurDisk:=Entries[I].Disk;
   While Not FileThere(SrcDir+Entries[I].Name)do
    AskDisk(Entries[I].Disk,True);
   DrawCopyScreen;
  End;
  If Entries[I].Root Then Dst:=Drv+Entries[I].Name
  Else Dst:=InstDir+'\'+Entries[I].Name;
  Src:=SrcDir+Entries[I].Name;
  If(Not Entries[I].Root)and(Not DirMade)Then Begin
   MakeDirs(InstDir);
   DirMade:=True;
  End;
  CurFile:=Entries[I].Name;
  DrawGauge;
  If Not CopyOne(Src,Dst,Entries[I].Root and
     ((Entries[I].Name='IO.SYS')or(Entries[I].Name='MSDOS.SYS')))Then
   Fatal('La copie de '+Entries[I].Name+' vers '+Dst+' a ‚chou‚ (disque '+
         'plein ou prot‚g‚ en ‚criture). Code '+LastStage+NumStr(LastErr)+'.',
         'Copying '+Entries[I].Name+' to '+Dst+' failed (disk full or '+
         'write-protected). Code '+LastStage+NumStr(LastErr)+'.');
 End;
 CurFile:='';
 DoneBytes:=TotalBytes;
 DrawGauge;
End;

{ ---------------------------------------------------------------------- }
{ Disque amorcable                                                        }
{ ---------------------------------------------------------------------- }

Function Bios13(Fn:Byte;Abs:LongInt;Var Buf:TSec):Boolean;
Var
 R:Registers;
 Tries:Integer;
 Sec,Hd,Cyl:Word;
 Tk:LongInt;
Begin
 Bios13:=False;
 If(Spt=0)or(Heads=0)Then Exit;
 Sec:=Word(Abs mod Spt)+1;
 Tk:=Abs div Spt;
 Hd:=Word(Tk mod Heads);
 Cyl:=Word(Tk div Heads);
 For Tries:=1 to 3 do Begin
  R.AH:=Fn;R.AL:=1;
  R.CH:=Byte(Cyl and $FF);
  R.CL:=Byte(Sec or((Cyl shr 2)and $C0));
  R.DH:=Byte(Hd);R.DL:=Unit8;
  R.ES:=Seg(Buf);R.BX:=Ofs(Buf);
  Intr($13,R);
  If(R.Flags and FCarry)=0 Then Begin Bios13:=True;Exit;End;
  R.AH:=0;R.DL:=Unit8;Intr($13,R);
 End;
End;

Function RdAbs(Abs:LongInt;Var Buf:TSec):Boolean;
Begin
 RdAbs:=Bios13($02,Abs,Buf);
End;

Function WrAbs(Abs:LongInt;Var Buf:TSec):Boolean;
Begin
 WrAbs:=Bios13($03,Abs,Buf);
End;

Function RdPart(LBA:LongInt;Var Buf:TSec):Boolean;
Begin
 RdPart:=RdAbs(PartLBA+LBA,Buf);
End;

Function LE32(Var B:TSec;O:Integer):LongInt;
Begin
 LE32:=LongInt(B[O])+LongInt(B[O+1])*256+LongInt(B[O+2])*65536+
       LongInt(B[O+3])*16777216;
End;

{ Unite BIOS et debut de partition du lecteur cible ; False si non gere }
Function PrepareUnit(Drv:Char):Boolean;
Var
 R:Registers;
 M:TSec;
 I,O:Integer;
Begin
 PrepareUnit:=False;
 Drv:=UpCase(Drv);
 PartLBA:=0;
 Case Drv of
  'A':Unit8:=0;
  'B':Unit8:=1;
  'C':Unit8:=$80;
 Else
  Exit;
 End;
 R.AH:=8;R.DL:=Unit8;Intr($13,R);
 If(R.Flags and FCarry)<>0 Then Begin
  If Unit8>=$80 Then Exit;
  Spt:=18;Heads:=2;
 End
 Else Begin
  Spt:=R.CL and $3F;
  Heads:=Word(R.DH)+1;
 End;
 If Unit8=$80 Then Begin
  If Not RdAbs(0,M)Then Exit;
  If(M[510]<>$55)or(M[511]<>$AA)Then Exit;
  For I:=0 to 3 do Begin
   O:=$1BE+I*16;
   If(M[O+4]in[1,4,6,$0E])and(PartLBA=0)Then PartLBA:=LE32(M,O+8);
  End;
  If PartLBA=0 Then Exit;
 End;
 PrepareUnit:=True;
End;

Var
 FatBuf:TSec;
 FatCached:LongInt;
 BpbRes,BpbSpf,BpbSpc:Word;
 Fat16:Boolean;

Function FatEntry(C:Word):Word;
Var
 O:LongInt;
 Sc,Of2:Word;
 V:Word;
Begin
 If Fat16 Then O:=LongInt(C)*2 Else O:=LongInt(C)*3 div 2;
 Sc:=Word(O div 512);Of2:=Word(O mod 512);
 If FatCached<>Sc Then Begin
  If Not RdPart(BpbRes+Sc,FatBuf)Then Begin FatEntry:=0;Exit;End;
  FatCached:=Sc;
 End;
 If Fat16 Then V:=FatBuf[Of2]+FatBuf[Of2+1]*256
 Else Begin
  V:=FatBuf[Of2];
  If Of2=511 Then Begin
   If Not RdPart(BpbRes+Sc+1,FatBuf)Then Begin FatEntry:=0;Exit;End;
   FatCached:=Sc+1;
   V:=V+FatBuf[0]*256;
  End
  Else V:=V+FatBuf[Of2+1]*256;
  If C and 1<>0 Then V:=V shr 4 Else V:=V and $FFF;
 End;
 FatEntry:=V;
End;

{ IO.SYS puis MSDOS.SYS doivent etre les deux premieres entrees de la racine,
  contigus : c'est ce que cherche le secteur de boot MS-DOS }
Function SystemLayoutOk:Boolean;
Const
 NmIo:String[11]='IO      SYS';
 NmDos:String[11]='MSDOS   SYS';
Var
 B,Root:TSec;
 Nf,RootEnt,Spf:Word;
 TotSec,DataStart:LongInt;
 C0,C1,N,K:Word;
 S0:LongInt;
 Last:Word;
Begin
 SystemLayoutOk:=False;
 If Not RdPart(0,B)Then Exit;
 BpbSpc:=B[13];BpbRes:=B[14]+B[15]*256;Nf:=B[16];
 RootEnt:=B[17]+B[18]*256;Spf:=B[22]+B[23]*256;
 TotSec:=B[19]+B[20]*256;
 If TotSec=0 Then TotSec:=LE32(B,32);
 If(BpbSpc=0)or(Nf=0)Then Exit;
 BpbSpf:=Spf;
 DataStart:=LongInt(BpbRes)+LongInt(Nf)*Spf+
  (LongInt(RootEnt)*32+511)div 512;
 Fat16:=(TotSec-DataStart)div BpbSpc>=4085;
 FatCached:=-1;
 If Not RdPart(BpbRes+Nf*Spf,Root)Then Exit;
 For K:=0 to 10 do Begin
  If Root[K]<>Ord(NmIo[K+1])Then Exit;
  If Root[32+K]<>Ord(NmDos[K+1])Then Exit;
 End;
 C0:=Root[26]+Root[27]*256;
 C1:=Root[32+26]+Root[32+27]*256;
 S0:=LE32(Root,28);
 If(C0<2)or(S0<=0)Then Exit;
 N:=Word((S0+LongInt(BpbSpc)*512-1)div(LongInt(BpbSpc)*512));
 If C1<>C0+N Then Exit;
 For K:=0 to N-2 do
  If FatEntry(C0+K)<>C0+K+1 Then Exit;
 Last:=FatEntry(C0+N-1);
 If Fat16 Then Begin If Last<$FFF8 Then Exit;End
 Else If Last<$FF8 Then Exit;
 SystemLayoutOk:=True;
End;

Function WriteBootSector:Boolean;
Var
 Old,Buf:TSec;
 J:Integer;
 FS:String[8];
Begin
 WriteBootSector:=False;
 If Not RdPart(0,Old)Then Exit;
 Move(BootCode,Buf,512);
 For J:=3 to 61 do Buf[J]:=Old[J];
 If Unit8>=$80 Then Buf[36]:=$80 Else Buf[36]:=0;
 Buf[38]:=$29;
 If(Old[39]or Old[40]or Old[41]or Old[42])=0 Then Begin
  Buf[39]:=$13;Buf[40]:=$57;Buf[41]:=$9B;Buf[42]:=$DF;
 End;
 If Old[43]=0 Then For J:=43 to 53 do Buf[J]:=32;
 If Fat16 Then FS:='FAT16   ' Else FS:='FAT12   ';
 Move(FS[1],Buf[54],8);
 Buf[510]:=$55;Buf[511]:=$AA;
 WriteBootSector:=WrAbs(PartLBA,Buf);
End;

{ Chargeur MBR si absent et partition de C: active }
Function WriteMbr:Boolean;
Var
 M:TSec;
 I,O:Integer;
 Any:Byte;
Begin
 WriteMbr:=False;
 If Unit8<$80 Then Begin WriteMbr:=True;Exit;End;
 If Not RdAbs(0,M)Then Exit;
 If(M[510]<>$55)or(M[511]<>$AA)Then Exit;
 Any:=0;
 For I:=0 to 445 do Any:=Any or M[I];
 If Any=0 Then Move(MbrCode,M,SizeOf(MbrCode));
 For I:=0 to 3 do Begin
  O:=$1BE+I*16;
  If(M[O+4]<>0)and(LE32(M,O+8)=PartLBA)Then M[O]:=$80 Else M[O]:=0;
 End;
 WriteMbr:=WrAbs(0,M);
End;

Procedure MakeBootable;
Var
 Drv:Char;
Begin
 Drv:=UpCase(InstDir[1]);
 CurFile:='';
 CopyNote:=T('Pr‚paration du disque...','Preparing the disk...');
 PutStr(5,20,CopyNote+'                    ',aNorm);
 If Not PrepareUnit(Drv)Then Begin
  Fatal('Le lecteur '+Drv+': ne peut pas ˆtre rendu amor‡able (seuls les '+
        'lecteurs A:, B: et la premiŠre partition du disque dur C: sont '+
        'pris en charge). Les fichiers ont ‚t‚ copi‚s.',
        'Drive '+Drv+': cannot be made bootable (only A:, B: and the first '+
        'partition of hard disk C: are supported). The files were copied.');
 End;
 If Not SystemLayoutOk Then
  Fatal('IO.SYS et MSDOS.SYS ne sont pas au d‚but du disque '+Drv+': '+
        'Formatez le disque avec FORMAT '+Drv+': /S puis relancez Install.',
        'IO.SYS and MSDOS.SYS are not at the start of drive '+Drv+': '+
        'Format the disk with FORMAT '+Drv+': /S, then run Setup again.');
 If Not WriteBootSector Then
  Fatal('Impossible d''‚crire le secteur de d‚marrage du disque '+Drv+':',
        'Cannot write the boot sector of drive '+Drv+':');
 If Not WriteMbr Then
  Fatal('Impossible d''‚crire le chargeur MBR du disque dur. Le disque '+
        'est-il partitionn‚ avec FDISK ?',
        'Cannot write the hard disk MBR. Is the disk partitioned with '+
        'FDISK?');
End;

{ ---------------------------------------------------------------------- }
{ CONFIG.SYS et AUTOEXEC.BAT                                              }
{ ---------------------------------------------------------------------- }

Procedure Backup(Const Path,OldPath:String);
Var
 F:File;
 Err:Integer;
 At:Word;
Begin
 If Not FileThere(Path)Then Exit;
 Assign(F,OldPath);
 {$I-}SetFAttr(F,0);Erase(F);{$I+}
 Err:=IOResult;
 Assign(F,Path);
 {$I-}SetFAttr(F,0);Rename(F,OldPath);{$I+}
 Err:=IOResult;
End;

Procedure WriteConfig;
Var
 F:Text;
 Drv:String;
 Err:Integer;
 CC:String;
Begin
 Drv:=InstDir[1]+':';
 Backup(Drv+'\CONFIG.SYS',Drv+'\CONFIG.OLD');
 Backup(Drv+'\AUTOEXEC.BAT',Drv+'\AUTOEXEC.OLD');
 CC:=NumStr(CountryCodes[CountryIdx]);
 While Length(CC)<3 do CC:='0'+CC;
 Assign(F,Drv+'\CONFIG.SYS');
 {$I-}Rewrite(F);{$I+}
 Err:=IOResult;
 If Err<>0 Then
  Fatal('Impossible de cr‚er CONFIG.SYS sur '+Drv,
        'Cannot create CONFIG.SYS on '+Drv);
 WriteLn(F,'FILES=30');
 WriteLn(F,'BUFFERS=20');
 WriteLn(F,'LASTDRIVE=E');
 WriteLn(F,'COUNTRY=',CC);
 WriteLn(F,'SHELL=',Drv,'\COMMAND.COM ',Drv,'\ /P');
 Close(F);
 Assign(F,Drv+'\AUTOEXEC.BAT');
 {$I-}Rewrite(F);{$I+}
 Err:=IOResult;
 If Err<>0 Then
  Fatal('Impossible de cr‚er AUTOEXEC.BAT sur '+Drv,
        'Cannot create AUTOEXEC.BAT on '+Drv);
 WriteLn(F,'@ECHO OFF');
 WriteLn(F,'SET LANGUAGE=',LangCodes[SysLang]);
 WriteLn(F,'PATH ',InstDir);
 WriteLn(F,'PROMPT $P$G');
 Close(F);
End;

{ ---------------------------------------------------------------------- }
{ Fin                                                                     }
{ ---------------------------------------------------------------------- }

Procedure ScreenDone;
Var
 K:Word;
 Y:Integer;
 R:Registers;
Begin
 Repeat
  Clear;
  Title;
  DlgBox(8,6,72,17);
  PutStr(26,6,T(' Installation de MSDOS-0 termin‚e. ',
                ' MSDOS-0 Setup is complete. '),aDlg);
  Y:=PutWrap(11,8,58,T('MSDOS-0 est maintenant install‚ sur votre '+
    'ordinateur.','MSDOS-0 is now installed on your computer.'),aDlg);
  Y:=PutBullet(12,Y+1,57,T('Pour red‚marrer votre ordinateur avec MSDOS-0, '+
    'retirez la disquette du lecteur A: puis appuyez sur ENTREE.',
    'To restart your computer with MSDOS-0, remove the disk from drive A: '+
    'and press ENTER.'),aDlg);
  Y:=PutBullet(12,Y+1,57,T('Pour voir les commandes install‚es, tapez DIR '+
    InstDir+' … l''invite.','To see the installed commands, type DIR '+
    InstDir+' at the prompt.'),aDlg);
  StatusBar(T(' ENTREE=Continuer',' ENTER=Continue'));
  K:=GetKey;
  If K=kF5 Then Begin Mono:=Not Mono;SetTheme;End;
 Until K=kEnter;
 RestoreScreen;
 { demarrage a chaud puis INT 19h (rechargement du secteur de boot) }
 MemW[$40:$72]:=$1234;
 Intr($19,R);
 WriteLn(T('Red‚marrez l''ordinateur pour utiliser MSDOS-0.',
           'Restart your computer to use MSDOS-0.'));
End;

Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
BEGIN
 Mono:=False;
 Lang:=0;SysLang:=1;CountryIdx:=1;
 If UpStr(Copy(GetEnv('LANGUAGE'),1,2))='EN' Then Begin
  Lang:=1;SysLang:=2;CountryIdx:=4;
 End;
 FSplit(FExpand(ParamStr(0)),D,N,E);
 SrcDir:=D;
 SrcDrive:=UpCase(D[1]);
 CurDisk:=1;
 SetTheme;
 InitVideo;
 CursorOff;
 ReadInf;
 ScreenWelcome;
 ScreenSettings;
 ScreenDirectory;
 CheckTarget;
 CopyFiles;
 MakeBootable;
 WriteConfig;
 ScreenDone;
END.
