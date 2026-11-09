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
    4. disque dur : s'il n'est pas partitionne (ou sans partition MS-DOS),
       creation d'une partition occupant tout le disque (MBR + table) ; si la
       partition n'est pas formatee, formatage FAT12/FAT16,
    5. IO.SYS et MSDOS.SYS en tete du disque : les entrees de la racine et les
       premieres grappes sont liberees en deplacant les fichiers existants
       (donnees, FAT, repertoires),
    6. copie des fichiers decrits par INSTALL.INF (demande des disquettes
       suivantes), 7. disque amorcable : secteur de boot MS-DOS, chargeur MBR
       et partition active,
    8. CONFIG.SYS et AUTOEXEC.BAT (les anciens deviennent *.OLD),
    9. fin et redemarrage.

  Les acces disque (partition, formatage, deplacement, boot) passent par le
  BIOS (INT 13h) ; le noyau est prevenu d'un changement de table de partition
  par la fonction interne INT 21h AH=70h.
  INSTALL.INF (un fichier par ligne : disquette,destination,nom,taille ;
  destination \ = racine, sinon le repertoire d'installation) est produit
  par TOOLS\MAKEDISK.PAS (option /INF). }

{$M 16384,0,32768}

Uses DOS;

Const
 BootCode:Array[0..511] of Byte = (
  $EB,$3C,$90,$4D,$53,$44,$4F,$53,$35,$2E,$30,$00,$02,$40,$01,$00,
  $02,$00,$02,$00,$00,$F8,$00,$01,$3F,$00,$80,$00,$3F,$00,$00,$00,
  $41,$DC,$3F,$00,$80,$00,$29,$8A,$85,$17,$3B,$4E,$4F,$20,$4E,$41,
  $4D,$45,$20,$20,$20,$20,$46,$41,$54,$31,$36,$20,$20,$20,$FA,$33,
  $C0,$8E,$D0,$BC,$00,$7C,$16,$07,$BB,$78,$00,$36,$C5,$37,$1E,$56,
  $16,$53,$BF,$3E,$7C,$B9,$0B,$00,$FC,$F3,$A4,$06,$1F,$C6,$45,$FE,
  $0F,$8B,$0E,$18,$7C,$88,$4D,$F9,$89,$47,$02,$C7,$07,$3E,$7C,$FB,
  $CD,$13,$72,$79,$33,$C0,$39,$06,$13,$7C,$74,$08,$8B,$0E,$13,$7C,
  $89,$0E,$20,$7C,$A0,$10,$7C,$F7,$26,$16,$7C,$03,$06,$1C,$7C,$13,
  $16,$1E,$7C,$03,$06,$0E,$7C,$83,$D2,$00,$A3,$50,$7C,$89,$16,$52,
  $7C,$A3,$49,$7C,$89,$16,$4B,$7C,$B8,$20,$00,$F7,$26,$11,$7C,$8B,
  $1E,$0B,$7C,$03,$C3,$48,$F7,$F3,$01,$06,$49,$7C,$83,$16,$4B,$7C,
  $00,$BB,$00,$05,$8B,$16,$52,$7C,$A1,$50,$7C,$E8,$92,$00,$72,$1D,
  $B0,$01,$E8,$AC,$00,$72,$16,$8B,$FB,$B9,$0B,$00,$BE,$E0,$7D,$F3,
  $A6,$75,$0A,$8D,$7F,$20,$B9,$0B,$00,$F3,$A6,$74,$18,$BE,$9E,$7D,
  $E8,$5F,$00,$33,$C0,$CD,$16,$5E,$1F,$8F,$04,$8F,$44,$02,$CD,$19,
  $58,$58,$58,$EB,$E8,$8B,$47,$1A,$48,$48,$8A,$1E,$0D,$7C,$32,$FF,
  $F7,$E3,$03,$06,$49,$7C,$13,$16,$4B,$7C,$BB,$00,$07,$B9,$03,$00,
  $50,$52,$51,$E8,$3A,$00,$72,$D8,$B0,$01,$E8,$54,$00,$59,$5A,$58,
  $72,$BB,$05,$01,$00,$83,$D2,$00,$03,$1E,$0B,$7C,$E2,$E2,$8A,$2E,
  $15,$7C,$8A,$16,$24,$7C,$8B,$1E,$49,$7C,$A1,$4B,$7C,$EA,$00,$00,
  $70,$00,$AC,$0A,$C0,$74,$29,$B4,$0E,$BB,$07,$00,$CD,$10,$EB,$F2,
  $3B,$16,$18,$7C,$73,$19,$F7,$36,$18,$7C,$FE,$C2,$88,$16,$4F,$7C,
  $33,$D2,$F7,$36,$1A,$7C,$88,$16,$25,$7C,$A3,$4D,$7C,$F8,$C3,$F9,
  $C3,$B4,$02,$8B,$16,$4D,$7C,$B1,$06,$D2,$E6,$0A,$36,$4F,$7C,$8B,
  $CA,$86,$E9,$8A,$16,$24,$7C,$8A,$36,$25,$7C,$CD,$13,$C3,$0D,$0A,
  $44,$69,$73,$71,$75,$65,$20,$6E,$6F,$6E,$2D,$73,$79,$73,$74,$8A,
  $6D,$65,$2F,$65,$72,$72,$65,$75,$72,$20,$64,$69,$73,$71,$75,$65,
  $0D,$0A,$52,$65,$6D,$70,$6C,$61,$63,$65,$7A,$20,$65,$74,$20,$70,
  $72,$65,$73,$73,$65,$7A,$20,$74,$6F,$75,$63,$68,$65,$0D,$0A,$00,
  $49,$4F,$20,$20,$20,$20,$20,$20,$53,$59,$53,$4D,$53,$44,$4F,$53,
  $20,$20,$20,$53,$59,$53,$00,$00,$00,$00,$00,$00,$00,$00,$55,$AA
 );

Const
 { Chargeur MBR minimal : se recopie en 0000:0600, cherche l'entree active
   de la table de partition, charge son secteur de boot en 0000:7C00 et y
   saute (DL = 80h). Sinon INT 18h. }
 MbrCode:Array[0..$4C]of Byte=(
  $FA,$33,$C0,$8E,$D0,$BC,$00,$7C,$8E,$D8,$8E,$C0,$FB,$FC,$BE,$00,
  $7C,$BF,$00,$06,$B9,$00,$01,$F3,$A5,$EA,$1E,$06,$00,$00,$BE,$BE,
  $07,$B1,$04,$80,$3C,$80,$74,$09,$83,$C6,$10,$E2,$F6,$CD,$18,$EB,
  $FE,$8B,$14,$8B,$4C,$02,$BB,$00,$7C,$B8,$01,$02,$CD,$13,$72,$EE,
  $81,$3E,$FE,$7D,$55,$AA,$75,$E5,$EA,$00,$7C,$00,$00);

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
    'disque dur et le rend amor‡able. Si le disque dur n''est pas '+
    'partitionn‚ ou format‚, Install le propose. Faites une copie de '+
    'sauvegarde de vos fichiers importants avec BACKUP avant de commencer.',
    'Setup copies the MSDOS-0 files to your hard disk and makes it '+
    'bootable. If the hard disk is not partitioned or formatted, Setup '+
    'offers to do it. Back up your important files with BACKUP before '+
    'you start.'),aNorm);
  2:Y:=PutWrap(4,Y,72,T('Utilisez les touches HAUT et BAS pour choisir un '+
    'paramŠtre puis appuyez sur ENTREE pour le modifier. La langue choisie '+
    'est aussi celle des messages des commandes MSDOS-0 install‚es '+
    '(variable LANGUAGE de AUTOEXEC.BAT).',
    'Use the UP and DOWN keys to select a setting, then press ENTER to '+
    'change it. The selected language is also the language of the messages '+
    'of the installed MSDOS-0 commands (LANGUAGE variable in '+
    'AUTOEXEC.BAT).'),aNorm);
  5:Y:=PutWrap(4,Y,72,T('Le disque dur doit avoir une partition MS-DOS '+
    'format‚e. Si ce n''est pas le cas, Install cr‚e une partition occupant '+
    'tout le disque (les autres partitions sont supprim‚es) et/ou formate '+
    'la partition : toutes les donn‚es concern‚es sont perdues.',
    'The hard disk needs a formatted MS-DOS partition. If it has none, '+
    'Setup creates a partition using the whole disk (other partitions are '+
    'deleted) and/or formats the partition: all the affected data is '+
    'lost.'),aNorm);
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

Procedure PrepareSystemArea;Forward;

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
 PrepareSystemArea;
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

Const
 dsNoDisk=0;
 dsNoPart=1;
 dsOther=2;
 dsNoFormat=3;
 dsReady=4;
 MaxMap=200;
 MaxStack=48;

Var
 Cyls:Word;
 HdTotal:LongInt;
 PartSectors:LongInt;
 FatBuf:TSec;
 FatCached:LongInt;
 BpbRes,BpbSpf,BpbSpc,BpbNf,BpbRoot:Word;
 BpbTot,DataStart,BpbClusters:LongInt;
 Fat16:Boolean;
 MapOld,MapNew:Array[1..MaxMap]of Word;
 MapCount:Integer;
 DStack:Array[1..MaxStack]of Word;
 DSp:Integer;

Function WrPart(LBA:LongInt;Var Buf:TSec):Boolean;
Begin
 WrPart:=WrAbs(PartLBA+LBA,Buf);
End;

Function DiskGeometry(U:Byte):Boolean;
Var
 R:Registers;
Begin
 DiskGeometry:=False;
 R.AH:=8;R.DL:=U;Intr($13,R);
 If(R.Flags and FCarry)<>0 Then Begin
  If U>=$80 Then Exit;
  Spt:=18;Heads:=2;Cyls:=80;
 End
 Else Begin
  Spt:=R.CL and $3F;
  Heads:=Word(R.DH)+1;
  Cyls:=(Word(R.CL and $C0)shl 2)+R.CH+1;
 End;
 HdTotal:=LongInt(Cyls)*Heads*Spt;
 DiskGeometry:=(Spt<>0)and(Heads<>0);
End;

{ Le noyau relit la table de partition du disque dur (fonction interne 70h) }
Procedure KernelRefresh;
Var
 R:Registers;
Begin
 R.AH:=$70;
 Intr($21,R);
End;

{ BPB de la partition courante ; False si ce n'est pas un volume FAT12/FAT16 }
Function LoadBpb:Boolean;
Var
 B:TSec;
Begin
 LoadBpb:=False;
 FatCached:=-1;
 If Not RdPart(0,B)Then Exit;
 If(B[510]<>$55)or(B[511]<>$AA)Then Exit;
 If(B[11]<>0)or(B[12]<>2)Then Exit;
 BpbSpc:=B[13];BpbRes:=B[14]+B[15]*256;BpbNf:=B[16];
 BpbRoot:=B[17]+B[18]*256;BpbSpf:=B[22]+B[23]*256;
 BpbTot:=B[19]+B[20]*256;
 If BpbTot=0 Then BpbTot:=LE32(B,32);
 If(BpbSpc=0)or(BpbNf=0)or(BpbNf>2)or(BpbRes=0)or(BpbSpf=0)or
   (BpbRoot=0)or(B[21]<$F0)Then Exit;
 DataStart:=LongInt(BpbRes)+LongInt(BpbNf)*BpbSpf+
  (LongInt(BpbRoot)*32+511)div 512;
 If BpbTot<=DataStart Then Exit;
 BpbClusters:=(BpbTot-DataStart)div BpbSpc;
 Fat16:=BpbClusters>=4085;
 LoadBpb:=True;
End;

{ Unite BIOS et debut de partition du lecteur cible ; False si non gere }
Function PrepareUnit(Drv:Char):Boolean;
Var
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
 If Not DiskGeometry(Unit8)Then Exit;
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

{ Etat du disque dur : pas de disque, pas de partition, partitions autres que
  MS-DOS, partition non formatee, pret }
Function DiskState:Integer;
Var
 M:TSec;
 I,O,Used:Integer;
Begin
 Unit8:=$80;PartLBA:=0;PartSectors:=0;
 If Not DiskGeometry($80)Then Begin DiskState:=dsNoDisk;Exit;End;
 If Not RdAbs(0,M)Then Begin DiskState:=dsNoDisk;Exit;End;
 Used:=0;
 If(M[510]=$55)and(M[511]=$AA)Then
  For I:=0 to 3 do Begin
   O:=$1BE+I*16;
   If M[O+4]<>0 Then Inc(Used);
   If(M[O+4]in[1,4,6,$0E])and(PartLBA=0)Then Begin
    PartLBA:=LE32(M,O+8);
    PartSectors:=LE32(M,O+12);
   End;
  End;
 If Used=0 Then DiskState:=dsNoPart
 Else If PartLBA=0 Then DiskState:=dsOther
 Else If LoadBpb Then DiskState:=dsReady
 Else DiskState:=dsNoFormat;
End;

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

{ Ecrit une entree de la FAT dans toutes les copies }
Function FatPut(C,V:Word):Boolean;
Var
 B1,B2:TSec;
 O:LongInt;
 Sc,Of2:Word;
 K:Integer;
 Two:Boolean;
Begin
 FatPut:=False;
 If Fat16 Then O:=LongInt(C)*2 Else O:=LongInt(C)*3 div 2;
 Sc:=Word(O div 512);Of2:=Word(O mod 512);
 Two:=(Not Fat16)and(Of2=511);
 For K:=0 to BpbNf-1 do Begin
  If Not RdPart(LongInt(BpbRes)+LongInt(K)*BpbSpf+Sc,B1)Then Exit;
  If Two Then
   If Not RdPart(LongInt(BpbRes)+LongInt(K)*BpbSpf+Sc+1,B2)Then Exit;
  If Fat16 Then Begin
   B1[Of2]:=Byte(V and $FF);B1[Of2+1]:=Byte(V shr 8);
  End
  Else If C and 1=0 Then Begin
   B1[Of2]:=Byte(V and $FF);
   If Two Then B2[0]:=(B2[0]and $F0)or Byte((V shr 8)and $0F)
   Else B1[Of2+1]:=(B1[Of2+1]and $F0)or Byte((V shr 8)and $0F);
  End
  Else Begin
   B1[Of2]:=(B1[Of2]and $0F)or Byte((V and $0F)shl 4);
   If Two Then B2[0]:=Byte((V shr 4)and $FF)
   Else B1[Of2+1]:=Byte((V shr 4)and $FF);
  End;
  If Not WrPart(LongInt(BpbRes)+LongInt(K)*BpbSpf+Sc,B1)Then Exit;
  If Two Then
   If Not WrPart(LongInt(BpbRes)+LongInt(K)*BpbSpf+Sc+1,B2)Then Exit;
 End;
 FatCached:=-1;
 FatPut:=True;
End;

{ IO.SYS puis MSDOS.SYS doivent etre les deux premieres entrees de la racine,
  contigus : c'est ce que cherche le secteur de boot MS-DOS }
Function SystemLayoutOk:Boolean;
Const
 NmIo:String[11]='IO      SYS';
 NmDos:String[11]='MSDOS   SYS';
Var
 Root:TSec;
 C0,C1,N,K:Word;
 S0:LongInt;
 Last:Word;
Begin
 SystemLayoutOk:=False;
 If Not LoadBpb Then Exit;
 If Not RdPart(LongInt(BpbRes)+LongInt(BpbNf)*BpbSpf,Root)Then Exit;
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

{ ---------------------------------------------------------------------- }
{ Partitionnement et formatage                                            }
{ ---------------------------------------------------------------------- }

Procedure PutLE32b(Var B:TSec;O:Integer;V:LongInt);
Begin
 B[O]:=Byte(V and $FF);B[O+1]:=Byte((V shr 8)and $FF);
 B[O+2]:=Byte((V shr 16)and $FF);B[O+3]:=Byte((V shr 24)and $FF);
End;

{ Adresse CHS d'un secteur LBA dans une entree de partition (3 octets) }
Procedure PutChs(Var B:TSec;O:Integer;LBA:LongInt);
Var
 S,H,C,Tk:LongInt;
Begin
 S:=(LBA mod Spt)+1;
 Tk:=LBA div Spt;
 H:=Tk mod Heads;
 C:=Tk div Heads;
 If C>1023 Then Begin C:=1023;H:=Heads-1;S:=Spt;End;
 B[O]:=Byte(H);
 B[O+1]:=Byte(S or((C shr 2)and $C0));
 B[O+2]:=Byte(C and $FF);
End;

{ Taille (en secteurs) de la partition unique occupant tout le disque,
  limitee a 2 Go (FAT16) }
Function WholeDiskSize:LongInt;
Var
 S:LongInt;
Begin
 S:=HdTotal-Spt;
 If S>4190000 Then S:=4190000;
 WholeDiskSize:=S;
End;

Function MoStr(Sectors:LongInt):String;
Begin
 MoStr:=NumStr(Sectors div 2048)+T(' Mo',' MB');
End;

{ Table de partition : une seule partition active occupant tout le disque ;
  les autres partitions sont supprimees }
Function CreatePartition:Boolean;
Var
 M:TSec;
 Size:LongInt;
Begin
 CreatePartition:=False;
 If Not DiskGeometry($80)Then Exit;
 Size:=WholeDiskSize;
 If Size<2000 Then Exit;
 FillChar(M,512,0);
 Move(MbrCode,M,SizeOf(MbrCode));
 M[$1BE]:=$80;
 PutChs(M,$1BF,Spt);
 If Size<4200 Then M[$1C2]:=1
 Else If Size<65536 Then M[$1C2]:=4
 Else M[$1C2]:=6;
 PutChs(M,$1C3,Spt+Size-1);
 PutLE32b(M,$1C6,Spt);
 PutLE32b(M,$1CA,Size);
 M[510]:=$55;M[511]:=$AA;
 If Not WrAbs(0,M)Then Exit;
 PartLBA:=Spt;PartSectors:=Size;
 KernelRefresh;
 CreatePartition:=True;
End;

{ Taille de grappe et de FAT d'une partition de Total secteurs (racine de 512
  entrees, deux FAT) }
Procedure CalcFormat(Total:LongInt;Var Spc:Byte;Var Spf:Word;Var F16:Boolean);
Const
 RootSecs=32;
Var
 I,K:Integer;
 C,Need:LongInt;
 Spf2:Word;
Begin
 Spc:=1;Spf:=1;F16:=True;
 For I:=0 to 6 do Begin
  Spc:=1 shl I;
  Spf:=1;
  For K:=1 to 6 do Begin
   C:=(Total-1-RootSecs-LongInt(2)*Spf)div Spc;
   F16:=C>=4085;
   If F16 Then Need:=(C+2)*2 Else Need:=((C+2)*3+1)div 2;
   Spf2:=Word((Need+511)div 512);
   If Spf2=Spf Then Break;
   Spf:=Spf2;
  End;
  If C<=65524 Then Exit;
 End;
End;

Procedure FormatScreen;
Begin
 Clear;
 Title;
 PutStr(8,6,T('Formatage du disque dur '+InstDir[1]+': en cours...',
              'Formatting hard disk '+InstDir[1]+': ...'),aNorm);
 Box(4,17,5+GaugeW+1,19,False,aNorm);
 StatusBar('');
End;

Procedure FormatGauge(Done,Total:LongInt);
Var
 Pct,N:LongInt;
Begin
 If Total>0 Then Pct:=Done*100 div Total Else Pct:=100;
 N:=Pct*GaugeW div 100;
 PutStr(5,16,NumStr(Pct)+T('% effectu‚','% complete')+'       ',aNorm);
 Fill(6,18,5+GaugeW,18,' ',aNorm);
 If N>0 Then Fill(6,18,5+N,18,' ',aGauge);
End;

{ Formatage rapide FAT12/FAT16 de la partition courante : secteur de boot MS-DOS
  (BPB), deux FAT et racine vides }
Function FormatPartition:Boolean;
Var
 B,M:TSec;
 Total,Done,All:LongInt;
 Spc:Byte;
 Spf:Word;
 F16:Boolean;
 I,K,O:Integer;
 S,Mi,Se,Hs:Word;
 FS:String[8];
Begin
 FormatPartition:=False;
 If Not RdAbs(0,M)Then Exit;
 Total:=0;
 For I:=0 to 3 do Begin
  O:=$1BE+I*16;
  If(M[O+4]<>0)and(LE32(M,O+8)=PartLBA)Then Total:=LE32(M,O+12);
 End;
 If Total<1000 Then Exit;
 If Not DiskGeometry(Unit8)Then Exit;
 CalcFormat(Total,Spc,Spf,F16);
 Move(BootCode,B,512);
 B[11]:=0;B[12]:=2;B[13]:=Spc;B[14]:=1;B[15]:=0;B[16]:=2;
 B[17]:=0;B[18]:=2;
 If Total<65536 Then Begin
  B[19]:=Byte(Total and $FF);B[20]:=Byte(Total shr 8);
  PutLE32b(B,32,0);
 End
 Else Begin
  B[19]:=0;B[20]:=0;PutLE32b(B,32,Total);
 End;
 B[21]:=$F8;
 B[22]:=Byte(Spf and $FF);B[23]:=Byte(Spf shr 8);
 B[24]:=Byte(Spt);B[25]:=0;B[26]:=Byte(Heads);B[27]:=0;
 PutLE32b(B,28,PartLBA);
 B[36]:=$80;B[37]:=0;B[38]:=$29;
 GetTime(S,Mi,Se,Hs);
 B[39]:=Byte(Se);B[40]:=Byte(Hs);B[41]:=Byte(Mi);B[42]:=Byte(S);
 For K:=43 to 53 do B[K]:=32;
 B[43]:=Ord('N');B[44]:=Ord('O');B[46]:=Ord('N');B[47]:=Ord('A');
 B[48]:=Ord('M');B[49]:=Ord('E');
 If F16 Then FS:='FAT16   ' Else FS:='FAT12   ';
 Move(FS[1],B[54],8);
 B[510]:=$55;B[511]:=$AA;
 FormatScreen;
 All:=LongInt(2)*Spf+32;Done:=0;
 FormatGauge(0,All);
 If Not WrAbs(PartLBA,B)Then Exit;
 For K:=0 to 1 do
  For I:=0 to Spf-1 do Begin
   FillChar(B,512,0);
   If I=0 Then Begin
    B[0]:=$F8;B[1]:=$FF;B[2]:=$FF;
    If F16 Then B[3]:=$FF;
   End;
   If Not WrPart(1+LongInt(K)*Spf+I,B)Then Exit;
   Inc(Done);
   If Done mod 16=0 Then FormatGauge(Done,All);
  End;
 FillChar(B,512,0);
 For I:=0 to 31 do Begin
  If Not WrPart(1+LongInt(2)*Spf+I,B)Then Exit;
  Inc(Done);
 End;
 FormatGauge(All,All);
 FormatPartition:=LoadBpb;
End;

{ Ecran d'information puis partitionnement / formatage }
Procedure ScreenDisk;
Var
 St:Integer;
 K:Word;
 Y:Integer;
 Sz:LongInt;
Begin
 If UpCase(InstDir[1])<>'C' Then Exit;
 St:=DiskState;
 If St=dsReady Then Exit;
 If St=dsNoDisk Then
  Fatal('Install n''a d‚tect‚ aucun disque dur.',
        'Setup did not detect any hard disk.');
 Sz:=WholeDiskSize;
 Repeat
  Clear;
  Title;
  PutStr(8,6,T('Disque dur','Hard disk'),aTitle);
  Case St of
   dsNoPart:Begin
    Y:=PutWrap(8,8,66,T('Le disque dur n''est pas partitionn‚.',
      'The hard disk is not partitioned.'),aNorm);
    Y:=PutWrap(8,Y+1,66,T('Install va cr‚er une partition MSDOS-0 de '+
      MoStr(Sz)+' occupant tout le disque dur, puis la formater.',
      'Setup will create a '+MoStr(Sz)+' MSDOS-0 partition using the whole '+
      'hard disk, then format it.'),aNorm);
   End;
   dsOther:Begin
    Y:=PutWrap(8,8,66,T('Le disque dur ne contient aucune partition MS-DOS.',
      'The hard disk has no MS-DOS partition.'),aNorm);
    Y:=PutWrap(8,Y+1,66,T('ATTENTION : pour continuer, Install doit SUPPRIMER '+
      'toutes les partitions du disque dur, cr‚er une partition MSDOS-0 de '+
      MoStr(Sz)+' et la formater. Toutes les donn‚es du disque dur seront '+
      'perdues.','WARNING: to continue, Setup must DELETE all the partitions '+
      'of the hard disk, create a '+MoStr(Sz)+' MSDOS-0 partition and format '+
      'it. All the data on the hard disk will be lost.'),aNorm);
   End;
  Else Begin
    Y:=PutWrap(8,8,66,T('Le disque dur n''est pas format‚.',
      'The hard disk is not formatted.'),aNorm);
    Y:=PutWrap(8,Y+1,66,T('Install va formater la partition '+InstDir[1]+
      ': ('+MoStr(PartSectors)+'). Toutes les donn‚es de cette partition '+
      'seront perdues.','Setup will format partition '+InstDir[1]+': ('+
      MoStr(PartSectors)+'). All the data on this partition will be lost.'),
      aNorm);
   End;
  End;
  Y:=PutBullet(10,Y+2,64,T('Pour continuer, appuyez sur ENTREE.',
    'To continue, press ENTER.'),aNorm);
  Y:=PutBullet(10,Y+1,64,T('Pour quitter Install, appuyez sur F3.',
    'To exit Setup, press F3.'),aNorm);
  StatusBar(KeysEnterF1F3);
  K:=GetKey;
  If K=kEnter Then Break;
  Nav(K,5);
 Until False;
 If St<>dsNoFormat Then
  If Not CreatePartition Then
   Fatal('Impossible de cr‚er la partition du disque dur.',
         'Cannot create the hard disk partition.');
 If Not FormatPartition Then
  Fatal('Le formatage du disque dur a ‚chou‚.',
        'Formatting the hard disk failed.');
 If DiskState<>dsReady Then
  Fatal('Le disque dur n''est pas utilisable aprŠs le formatage.',
        'The hard disk is not usable after formatting.');
End;

{ ---------------------------------------------------------------------- }
{ Fichiers d'amorcage en tete du disque (deplacement des fichiers)        }
{ ---------------------------------------------------------------------- }

Function MapLookup(C:Word):Word;
Var
 I:Integer;
Begin
 MapLookup:=0;
 For I:=1 to MapCount do
  If MapOld[I]=C Then MapLookup:=MapNew[I];
End;

Function FindFree(From:Word):Word;
Var
 C:Word;
Begin
 FindFree:=0;
 C:=From;
 While LongInt(C)<=BpbClusters+1 do Begin
  If FatEntry(C)=0 Then Begin FindFree:=C;Exit;End;
  Inc(C);
 End;
End;

Function CopyCluster(Src,Dst:Word):Boolean;
Var
 B:TSec;
 K:Word;
Begin
 CopyCluster:=False;
 For K:=0 to BpbSpc-1 do Begin
  If Not RdPart(DataStart+LongInt(Src-2)*BpbSpc+K,B)Then Exit;
  If Not WrPart(DataStart+LongInt(Dst-2)*BpbSpc+K,B)Then Exit;
 End;
 CopyCluster:=True;
End;

Function IsEnd(V:Word):Boolean;
Begin
 If Fat16 Then IsEnd:=V>=$FFF8 Else IsEnd:=V>=$FF8;
End;

{ Les entrees 0 et 1 de la racine sont deplacees vers des emplacements libres }
Function FreeRootSlots:Boolean;
Var
 M0,M:TSec;
 RS:LongInt;
 RootSecs,I,J,Sc:Integer;
 Found:Boolean;
Begin
 FreeRootSlots:=False;
 RS:=LongInt(BpbRes)+LongInt(BpbNf)*BpbSpf;
 RootSecs:=(BpbRoot*32+511)div 512;
 For I:=0 to 1 do Begin
  If Not RdPart(RS,M0)Then Exit;
  If(M0[I*32]<>0)and(M0[I*32]<>$E5)Then Begin
   Found:=False;
   For Sc:=0 to RootSecs-1 do
    If Not Found Then Begin
     If Sc>0 Then
      If Not RdPart(RS+Sc,M)Then Exit;
     For J:=0 to 15 do
      If(Not Found)and((Sc>0)or(J>1))Then Begin
       If Sc=0 Then Begin
        If(M0[J*32]=0)or(M0[J*32]=$E5)Then Begin
         Move(M0[I*32],M0[J*32],32);Found:=True;
        End;
       End
       Else If(M[J*32]=0)or(M[J*32]=$E5)Then Begin
        Move(M0[I*32],M[J*32],32);Found:=True;
        If Not WrPart(RS+Sc,M)Then Exit;
       End;
      End;
    End;
   If Not Found Then Exit;
   M0[I*32]:=$E5;
   If Not WrPart(RS,M0)Then Exit;
  End;
 End;
 FreeRootSlots:=True;
End;

{ Remplace dans une entree de repertoire les premieres grappes deplacees ;
  empile les sous-repertoires }
Procedure PatchSector(LBA:LongInt;Var Stop:Boolean);
Var
 M:TSec;
 I,E:Integer;
 St,Nw:Word;
 Dirty:Boolean;
Begin
 If Not RdPart(LBA,M)Then Begin Stop:=True;Exit;End;
 Dirty:=False;
 For I:=0 to 15 do
  If Not Stop Then Begin
   E:=I*32;
   If M[E]=0 Then Stop:=True
   Else If(M[E]<>$E5)and(M[E+11]<>$0F)and((M[E+11]and 8)=0)Then Begin
    St:=M[E+26]+M[E+27]*256;
    Nw:=MapLookup(St);
    If Nw<>0 Then Begin
     M[E+26]:=Byte(Nw and $FF);M[E+27]:=Byte(Nw shr 8);
     Dirty:=True;St:=Nw;
    End;
    If((M[E+11]and $10)<>0)and(M[E]<>$2E)and(St>=2)and(DSp<MaxStack)Then Begin
     Inc(DSp);DStack[DSp]:=St;
    End;
   End;
  End;
 If Dirty Then
  If Not WrPart(LBA,M)Then Stop:=True;
End;

{ Parcourt la racine et tous les sous-repertoires }
Procedure PatchDirs;
Var
 D,C:Word;
 K,Guard,RootSecs:Integer;
 Stop:Boolean;
Begin
 RootSecs:=(BpbRoot*32+511)div 512;
 DSp:=1;DStack[1]:=0;
 While DSp>0 do Begin
  D:=DStack[DSp];Dec(DSp);
  Stop:=False;
  If D=0 Then Begin
   For K:=0 to RootSecs-1 do
    If Not Stop Then
     PatchSector(LongInt(BpbRes)+LongInt(BpbNf)*BpbSpf+K,Stop);
  End
  Else Begin
   C:=D;Guard:=0;
   While(Not Stop)and(C>=2)and(Not IsEnd(C))and(Guard<4096)do Begin
    For K:=0 to BpbSpc-1 do
     If Not Stop Then PatchSector(DataStart+LongInt(C-2)*BpbSpc+K,Stop);
    C:=FatEntry(C);
    Inc(Guard);
   End;
  End;
 End;
End;

Procedure DeleteOld(Const Path:String);
Var
 F:File;
 At:Word;
 Err:Integer;
Begin
 Assign(F,Path);
 {$I-}GetFAttr(F,At);{$I+}
 Err:=IOResult;
 If Err<>0 Then Exit;
 {$I-}SetFAttr(F,0);Erase(F);{$I+}
 Err:=IOResult;
End;

{ Libere les entrees 0 et 1 de la racine et les premieres grappes du disque
  pour IO.SYS et MSDOS.SYS : les fichiers qui s'y trouvent sont deplaces
  (donnees, FAT, repertoires) }
Procedure PrepareSystemArea;
Var
 Drv:Char;
 I:Integer;
 Need,CB,Sz1,Sz2:LongInt;
 C,F,Nx,V,N2,From:Word;
Begin
 Drv:=UpCase(InstDir[1]);
 If Not PrepareUnit(Drv)Then Exit;
 If Not LoadBpb Then Exit;
 PutStr(5,20,T('Pr‚paration du disque...','Preparing the disk...')+
        '                    ',aNorm);
 DeleteOld(Drv+':\IO.SYS');
 DeleteOld(Drv+':\MSDOS.SYS');
 Sz1:=0;Sz2:=0;
 For I:=1 to EntryCount do
  If Entries[I].Root Then Begin
   If Entries[I].Name='IO.SYS' Then Sz1:=Entries[I].Size;
   If Entries[I].Name='MSDOS.SYS' Then Sz2:=Entries[I].Size;
  End;
 CB:=LongInt(BpbSpc)*512;
 Need:=(Sz1+CB-1)div CB+(Sz2+CB-1)div CB;
 If Need<1 Then Exit;
 If Not FreeRootSlots Then
  Fatal('Le r‚pertoire racine est plein : impossible de placer IO.SYS et '+
        'MSDOS.SYS en tˆte du disque.',
        'The root directory is full: cannot place IO.SYS and MSDOS.SYS at '+
        'the start of the disk.');
 MapCount:=0;
 From:=Word(Need+2);
 For C:=2 to Word(Need+1) do Begin
  Nx:=FatEntry(C);
  If Nx<>0 Then Begin
   If(Nx=$FFF7)or((Not Fat16)and(Nx=$FF7))Then
    Fatal('Une grappe d‚fectueuse se trouve au d‚but du disque.',
          'A bad cluster is located at the start of the disk.');
   F:=FindFree(From);
   If(F=0)or(MapCount>=MaxMap)Then
    Fatal('Espace disque insuffisant pour d‚placer les fichiers existants.',
          'Not enough disk space to move the existing files.');
   From:=F+1;
   If(Not CopyCluster(C,F))or(Not FatPut(F,Nx))Then
    Fatal('Erreur de lecture ou d''‚criture du disque.',
          'Disk read or write error.');
   Inc(MapCount);MapOld[MapCount]:=C;MapNew[MapCount]:=F;
  End;
 End;
 If MapCount=0 Then Exit;
 { les chaines FAT qui menent aux grappes deplacees }
 For C:=2 to Word(BpbClusters+1) do Begin
  V:=FatEntry(C);
  If(V>=2)and(V<=Need+1)Then Begin
   N2:=MapLookup(V);
   If N2<>0 Then FatPut(C,N2);
  End;
 End;
 For I:=1 to MapCount do FatPut(MapOld[I],0);
 { les premieres grappes des fichiers et les entrees . et .. }
 PatchDirs;
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
 { geometrie du BIOS (INT 13h) et secteurs caches : le secteur de boot s'en
   sert pour convertir les adresses en CHS ; une valeur invalide laissee par
   un autre outil de formatage empeche le demarrage }
 If DiskGeometry(Unit8)Then Begin
  Buf[24]:=Byte(Spt);Buf[25]:=0;Buf[26]:=Byte(Heads);Buf[27]:=0;
 End;
 PutLE32b(Buf,28,PartLBA);
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
 ScreenDisk;
 CheckTarget;
 CopyFiles;
 MakeBootable;
 WriteConfig;
 ScreenDone;
END.
