Program TESTH;
Uses DOS;

Var
 R:Registers;
 Fails:Word;
 Buf:Array[0..255] of Char;
 Name:Array[0..79] of Char;
 H,H2,Save:Word;

Procedure Z(S:String);
Var I:Byte;
Begin
 For I:=1 To Length(S) Do Name[I-1]:=S[I];
 Name[Length(S)]:=#0;
End;

Procedure Pause;
Var L:String;
Begin
 ReadLn(L);
End;

Procedure Check(Msg:String;Ok:Boolean);
Begin
 If Ok Then WriteLn('OK   ',Msg) Else Begin WriteLn('FAIL ',Msg); Inc(Fails);
   End;
End;

Function Call:Boolean;
Begin
 MsDos(R);
 Call:=(R.Flags And 1)=0;
End;

Function DosCreate(S:String):Word;
Begin
 Z(S); R.AH:=$3C; R.CX:=0; R.DS:=Seg(Name); R.DX:=Ofs(Name);
 If Call Then DosCreate:=R.AX Else DosCreate:=$FFFF;
End;

Function DosOpen(S:String;Mode:Byte):Word;
Begin
 Z(S); R.AH:=$3D; R.AL:=Mode; R.DS:=Seg(Name); R.DX:=Ofs(Name);
 If Call Then DosOpen:=R.AX Else DosOpen:=$FFFF;
End;

Function DosClose(Hd:Word):Boolean;
Begin
 R.AH:=$3E; R.BX:=Hd;
 DosClose:=Call;
End;

Function DosWrite(Hd:Word;S:String):Boolean;
Var T:Array[0..79] of Char; I:Byte;
Begin
 For I:=1 To Length(S) Do T[I-1]:=S[I];
 R.AH:=$40; R.BX:=Hd; R.CX:=Length(S); R.DS:=Seg(T); R.DX:=Ofs(T);
 DosWrite:=Call And (R.AX=Length(S));
End;

Function DosRead(Hd:Word;N:Word):Word;
Begin
 R.AH:=$3F; R.BX:=Hd; R.CX:=N; R.DS:=Seg(Buf); R.DX:=Ofs(Buf);
 If Call Then DosRead:=R.AX Else DosRead:=$FFFF;
End;

Function BufIs(S:String):Boolean;
Var I:Byte; Ok:Boolean;
Begin
 Ok:=True;
 For I:=1 To Length(S) Do If Buf[I-1]<>S[I] Then Ok:=False;
 BufIs:=Ok;
End;

Var
 Fcb:Array[0..36] of Byte;
 Fcb2:Array[0..36] of Byte;
 Dta:Array[0..255] of Byte;
 I,N:Word;
 Attr,Tm,Dt:Word;
 Path:Array[0..40] of Char;
 SeekOk,Ok1,Ok2:Boolean;

Procedure SetDta;
Begin
 R.AH:=$1A; R.DS:=Seg(Dta); R.DX:=Ofs(Dta);
 MsDos(R);
End;

Procedure FcbName(Var F:Array of Byte;D:Byte;S:String);
Var K:Byte;
Begin
 FillChar(F,37,0);
 F[0]:=D;
 For K:=1 To 11 Do F[K]:=32;
 For K:=1 To Length(S) Do F[K]:=Ord(S[K]);
End;

Begin
 Fails:=0;
 WriteLn('== TESTH : handles, 43h, 44h, 57h, 5Ah, 5Bh, 5Ch, FCB ==');
 { 1. creation / ecriture / relecture }
 H:=DosCreate('T1.TMP');
 Check('3Ch creer T1.TMP',H<>$FFFF);
 Check('40h ecrire abcdef',DosWrite(H,'abcdef'));
 Check('3Eh fermer',DosClose(H));
 H:=DosOpen('T1.TMP',0);
 Check('3Dh ouvrir lecture',H<>$FFFF);
 Check('3Fh lire 3',(DosRead(H,3)=3) And BufIs('abc'));
 { 2. DUP }
 R.AH:=$45; R.BX:=H;
 Check('45h DUP',Call);
 H2:=R.AX;
 Check('45h nouveau handle different',H2<>H);
 Check('3Eh fermer original',DosClose(H));
 Check('3Eh original deja ferme -> erreur',Not DosClose(H));
 Check('3Fh via copie lit la suite (def)',(DosRead(H2,3)=3) And BufIs('def'));
 Check('3Eh fermer copie',DosClose(H2));
 Check('3Fh sur handle ferme -> erreur',DosRead(H2,1)=$FFFF);
 Pause;
 { 3. redirection stdout par FORCEDUP }
 R.AH:=$45; R.BX:=1;
 Check('45h DUP stdout',Call);
 Save:=R.AX;
 H:=DosCreate('OUT.TXT');
 R.AH:=$46; R.BX:=H; R.CX:=1;
 Ok1:=Call;
 DosClose(H);
 WriteLn('texte redirige');
 R.AH:=$46; R.BX:=Save; R.CX:=1;
 Ok2:=Call;
 DosClose(Save);
 Check('46h FORCEDUP fichier -> stdout',Ok1);
 Check('46h restaure stdout',Ok2);
 H:=DosOpen('OUT.TXT',0);
 N:=DosRead(H,40);
 DosClose(H);
 Check('OUT.TXT contient le texte redirige',(N=16) And BufIs('texte redirige'));
 Pause;
 { 4. attributs 43h }
 Z('OUT.TXT'); R.AX:=$4300; R.DS:=Seg(Name); R.DX:=Ofs(Name);
 Check('4300h lire attributs',Call And ((R.CX And $20)<>0));
 Z('OUT.TXT'); R.AX:=$4301; R.CX:=$21; R.DS:=Seg(Name); R.DX:=Ofs(Name);
 Check('4301h poser attributs R+A',Call);
 Z('OUT.TXT'); R.AX:=$4300; R.DS:=Seg(Name); R.DX:=Ofs(Name);
 Check('4300h relire = 21h',Call And (R.CX=$21));
 Z('OUT.TXT'); R.AX:=$4301; R.CX:=$20; R.DS:=Seg(Name); R.DX:=Ofs(Name);
 Check('4301h remettre A',Call);
 Z('NOEXIST.XYZ'); R.AX:=$4300; R.DS:=Seg(Name); R.DX:=Ofs(Name);
 Check('4300h fichier inconnu -> erreur 2',(Not Call) And (R.AX=2));
 Pause;
 { 5. 57h date/heure }
 H:=DosOpen('OUT.TXT',2);
 R.AX:=$5700; R.BX:=H;
 Check('5700h lire date/heure',Call And (R.DX<>0));
 R.AX:=$5701; R.BX:=H; R.CX:=$6000; R.DX:=$2A21;
 Check('5701h poser date/heure',Call);
 DosClose(H);
 H:=DosOpen('OUT.TXT',0);
 R.AX:=$5700; R.BX:=H;
 Check('5700h relire = 2A21 6000',Call And (R.DX=$2A21) And (R.CX=$6000));
 { 6. 44h }
 R.AX:=$4400; R.BX:=H;
 Check('4400h fichier : peripherique=0',Call And ((R.DX And $80)=0));
 DosClose(H);
 R.AX:=$4400; R.BX:=1;
 Check('4400h stdout : peripherique',Call And ((R.DX And $80)<>0));
 R.AX:=$4400; R.BX:=19;
 Check('4400h handle invalide -> erreur 6',(Not Call) And (R.AX=6));
 Pause;
 { 7. 5Bh }
 Z('OUT.TXT'); R.AH:=$5B; R.CX:=0; R.DS:=Seg(Name); R.DX:=Ofs(Name);
 Check('5Bh fichier existant -> erreur 50h',(Not Call) And (R.AX=$50));
 Z('NEW5B.TMP'); R.AH:=$5B; R.CX:=0; R.DS:=Seg(Name); R.DX:=Ofs(Name);
 Check('5Bh nouveau fichier',Call);
 DosClose(R.AX);
 { 8. 5Ah }
 FillChar(Path,SizeOf(Path),0);
 Path[0]:='\';
 R.AH:=$5A; R.CX:=0; R.DS:=Seg(Path); R.DX:=Ofs(Path);
 Check('5Ah fichier temporaire',Call);
 H:=R.AX;
 Check('5Ah nom genere commence par \TMP',
   (Path[0]='\') And (Path[1]='T') And (Path[2]='M'));
 DosClose(H);
 R.AH:=$41; R.DS:=Seg(Path); R.DX:=Ofs(Path);
 Check('41h supprime le fichier temporaire',Call);
 Pause;
 { 9. 5Ch verrou }
 H:=DosOpen('OUT.TXT',2);
 R.AX:=$5C00; R.BX:=H; R.CX:=0; R.DX:=0; R.SI:=0; R.DI:=4;
 Check('5C00h verrouiller',Call);
 R.AX:=$5C01; R.BX:=H; R.CX:=0; R.DX:=0; R.SI:=0; R.DI:=4;
 Check('5C01h deverrouiller',Call);
 DosClose(H);
 Pause;
 { 10. FCB }
 FcbName(Fcb,0,'OUT     TXT');
 R.AH:=$0F; R.DS:=Seg(Fcb); R.DX:=Ofs(Fcb);
 MsDos(R);
 Check('0Fh ouvrir FCB OUT.TXT',R.AL=0);
 Check('FCB taille = 16 (texte redirige+CRLF)',(Fcb[16]=16) And (Fcb[17]=0));
 Check('FCB taille enregistrement = 128',(Fcb[14]=128) And (Fcb[15]=0));
 SetDta;
 FillChar(Dta,SizeOf(Dta),'#');
 R.AH:=$14; R.DS:=Seg(Fcb); R.DX:=Ofs(Fcb);
 MsDos(R);
 Check('14h lecture sequentielle -> 3 (partiel)',R.AL=3);
 Check('DTA = texte redirige',
   (Dta[0]=Ord('t')) And (Dta[13]=Ord('e')) And (Dta[50]=0));
 R.AH:=$14; R.DS:=Seg(Fcb); R.DX:=Ofs(Fcb);
 MsDos(R);
 Check('14h lecture suivante -> 1 (fin)',R.AL=1);
 R.AH:=$10; R.DS:=Seg(Fcb); R.DX:=Ofs(Fcb);
 MsDos(R);
 Check('10h fermer FCB',R.AL=0);
 FcbName(Fcb,0,'FCBTEST DAT');
 R.AH:=$16; R.DS:=Seg(Fcb); R.DX:=Ofs(Fcb);
 MsDos(R);
 Check('16h creer FCB',R.AL=0);
 Fcb[14]:=64; Fcb[15]:=0;
 SetDta;
 For I:=0 To 255 Do Dta[I]:=I;
 R.AH:=$15; R.DS:=Seg(Fcb); R.DX:=Ofs(Fcb);
 MsDos(R);
 Check('15h ecriture sequentielle 1',R.AL=0);
 For I:=0 To 63 Do Dta[I]:=100+I;
 R.AH:=$15; R.DS:=Seg(Fcb); R.DX:=Ofs(Fcb);
 MsDos(R);
 Check('15h ecriture sequentielle 2',R.AL=0);
 R.AH:=$10; R.DS:=Seg(Fcb); R.DX:=Ofs(Fcb);
 MsDos(R);
 Check('10h fermer apres ecriture',R.AL=0);
 FcbName(Fcb,0,'FCBTEST DAT');
 R.AH:=$0F; R.DS:=Seg(Fcb); R.DX:=Ofs(Fcb);
 MsDos(R);
 Check('0Fh rouvrir FCBTEST.DAT',R.AL=0);
 Check('taille FCB = 128',(Fcb[16]=128) And (Fcb[17]=0));
 Fcb[14]:=64; Fcb[15]:=0;
 Fcb[33]:=1; Fcb[34]:=0; Fcb[35]:=0; Fcb[36]:=0;
 FillChar(Dta,SizeOf(Dta),0);
 R.AH:=$21; R.DS:=Seg(Fcb); R.DX:=Ofs(Fcb);
 MsDos(R);
 Check('21h lecture aleatoire enregistrement 1',
   (R.AL=0) And (Dta[0]=100) And (Dta[63]=163));
 R.AH:=$23; R.DS:=Seg(Fcb); R.DX:=Ofs(Fcb);
 MsDos(R);
 Check('23h taille = 2 enregistrements',(R.AL=0) And (Fcb[33]=2));
 R.AH:=$10; R.DS:=Seg(Fcb); R.DX:=Ofs(Fcb);
 MsDos(R);
 { recherche FCB }
 FcbName(Fcb2,0,'???????????');
 N:=0;
 R.AH:=$11; R.DS:=Seg(Fcb2); R.DX:=Ofs(Fcb2);
 MsDos(R);
 While (R.AL=0) And (N<50) Do Begin
  Inc(N);
  R.AH:=$12; R.DS:=Seg(Fcb2); R.DX:=Ofs(Fcb2);
  MsDos(R);
 End;
 WriteLn('  (N=',N,' AL=',R.AL,')');
 Check('11h/12h enumerent des fichiers (>=6)',N>=6);
 { renommer / supprimer FCB }
 FcbName(Fcb,0,'FCBTEST DAT');
 For I:=0 To 10 Do Fcb[$11+I]:=32;
 Fcb[$11]:=Ord('F'); Fcb[$12]:=Ord('C'); Fcb[$13]:=Ord('B'); Fcb[$19]:=Ord('B');
   Fcb[$1A]:=Ord('A'); Fcb[$1B]:=Ord('K');
 R.AH:=$17; R.DS:=Seg(Fcb); R.DX:=Ofs(Fcb);
 MsDos(R);
 Check('17h renommer FCBTEST.DAT -> FCB.BAK',R.AL=0);
 H:=DosOpen('FCB.BAK',0);
 Check('FCB.BAK existe',H<>$FFFF);
 If H<>$FFFF Then DosClose(H);
 FcbName(Fcb,0,'FCB     BAK');
 R.AH:=$13; R.DS:=Seg(Fcb); R.DX:=Ofs(Fcb);
 MsDos(R);
 Check('13h supprimer FCB.BAK',R.AL=0);
 H:=DosOpen('FCB.BAK',0);
 Check('FCB.BAK supprime',H=$FFFF);
 { analyse de nom 29h }
 Z('b:fichier*.t?t rest');
 FillChar(Fcb,37,0);
 R.AH:=$29; R.AL:=0; R.DS:=Seg(Name); R.SI:=Ofs(Name); R.ES:=Seg(Fcb);
   R.DI:=Ofs(Fcb);
 MsDos(R);
 Check('29h joker -> AL=1',R.AL=1);
 Check('29h lecteur B',Fcb[0]=2);
 Check('29h nom FICHIER?',
   (Fcb[1]=Ord('F')) And (Fcb[7]=Ord('R')) And (Fcb[8]=Ord('?')));
 Check('29h ext T?T',(Fcb[9]=Ord('T')) Or (Fcb[9]=Ord('?')));
 Check('29h SI apres analyse',R.SI=Ofs(Name)+Length('b:fichier*.t?t'));
 { nettoyage }
 Z('T1.TMP'); R.AH:=$41; R.DS:=Seg(Name); R.DX:=Ofs(Name); MsDos(R);
 Z('OUT.TXT'); R.AH:=$41; R.DS:=Seg(Name); R.DX:=Ofs(Name); MsDos(R);
 Z('NEW5B.TMP'); R.AH:=$41; R.DS:=Seg(Name); R.DX:=Ofs(Name); MsDos(R);
 Z('FCBTEST.DAT'); R.AH:=$41; R.DS:=Seg(Name); R.DX:=Ofs(Name); MsDos(R);
 If Fails=0 Then WriteLn('== TOUS LES TESTS REUSSIS ==') Else
   WriteLn('== ECHECS : ',Fails,' ==');
End.
