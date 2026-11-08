Program TSTRESS;
Uses DOS;
Var
 Fails:Word;
 F,G:File;
 T:Text;
 Buf:Array[0..4095] of Byte;
 Chk:Array[0..4095] of Byte;
 I,J,N,Got,Cnt:Word;
 L:LongInt;
 S:String;
 Info:SearchRec;
 Free0,Free1:LongInt;

Procedure Check(Msg:String;Ok:Boolean);
Begin
 If Ok Then WriteLn('OK   ',Msg) Else Begin WriteLn('FAIL ',Msg); Inc(Fails); End;
End;

Function Num(N:Word):String;
Var S:String;
Begin
 Str(N,S);
 Num:=S;
End;

Procedure Fill(Seed:Byte);
Var K:Word;
Begin
 For K:=0 To 4095 Do Buf[K]:=Byte(K*7+Seed);
End;

Begin
 Fails:=0;
 WriteLn('== TSTRESS : systeme de fichiers ==');
 Free0:=DiskFree(0);
 { 1. gros fichier 200 Ko ecrit par blocs de 4 Ko, relu et verifie }
 Assign(F,'BIG.DAT');
 Rewrite(F,1);
 For I:=0 To 49 Do Begin
  Fill(Byte(I));
  BlockWrite(F,Buf,4096,Got);
 End;
 Close(F);
 Reset(F,1);
 Check('taille BIG.DAT = 204800',FileSize(F)=204800);
 N:=0;
 For I:=0 To 49 Do Begin
  BlockRead(F,Chk,4096,Got);
  Fill(Byte(I));
  If (Got<>4096) Or (Buf[0]<>Chk[0]) Or (Buf[100]<>Chk[100]) Or (Buf[4095]<>Chk[4095]) Then Inc(N);
 End;
 Check('relecture 50 blocs sans erreur',N=0);
 { acces direct : bloc 30 }
 Seek(F,LongInt(30)*4096);
 BlockRead(F,Chk,4096,Got);
 Fill(30);
 Check('Seek + lecture bloc 30',(Got=4096) And (Chk[1]=Buf[1]) And (Chk[2000]=Buf[2000]));
 Seek(F,204800);
 BlockRead(F,Chk,10,Got);
 Check('lecture en fin de fichier -> 0',Got=0);
 Close(F);
 { 2. ajout et troncature }
 Reset(F,1);
 Seek(F,FileSize(F));
 Fill(99);
 BlockWrite(F,Buf,100,Got);
 Check('ajout de 100 octets',Got=100);
 Check('taille 204900',FileSize(F)=204900);
 Seek(F,1000);
 Truncate(F);
 Check('Truncate a 1000',FileSize(F)=1000);
 Close(F);
 Reset(F,1);
 Check('taille relue = 1000',FileSize(F)=1000);
 Close(F);
 { 3. ecriture au-dela de la fin (trou) }
 Assign(G,'GAP.DAT');
 Rewrite(G,1);
 Seek(G,5000);
 Fill(5);
 BlockWrite(G,Buf,10,Got);
 Close(G);
 Reset(G,1);
 Check('GAP.DAT taille 5010',FileSize(G)=5010);
 Close(G);
 { 4. 120 fichiers dans un sous-repertoire }
 MkDir('MANY');
 Check('MkDir MANY',IOResult=0);
 ChDir('MANY');
 N:=0;
 For I:=1 To 120 Do Begin
  Assign(G,'F'+Num(I)+'.TXT');
  {$I-}Rewrite(G,1);{$I+}
  If IOResult=0 Then Begin
   BlockWrite(G,Buf,I,Got);
   Close(G);
   Inc(N);
  End;
 End;
 Check('120 fichiers crees',N=120);
 Cnt:=0;
 FindFirst('*.TXT',Archive,Info);
 While DosError=0 Do Begin
  Inc(Cnt);
  FindNext(Info);
 End;
 Check('FindFirst/FindNext compte 120',Cnt=120);
 Assign(G,'F77.TXT');
 Reset(G,1);
 Check('F77.TXT a 77 octets',FileSize(G)=77);
 Close(G);
 { suppression d'un sur deux }
 For I:=1 To 120 Do
  If Odd(I) Then Begin
   Assign(G,'F'+Num(I)+'.TXT');
   Erase(G);
  End;
 Cnt:=0;
 FindFirst('*.TXT',Archive,Info);
 While DosError=0 Do Begin
  Inc(Cnt);
  FindNext(Info);
 End;
 Check('60 fichiers apres suppression',Cnt=60);
 { reutilisation des entrees libres }
 For I:=1 To 20 Do Begin
  Assign(G,'N'+Num(I)+'.DAT');
  Rewrite(G,1);
  Close(G);
 End;
 Cnt:=0;
 FindFirst('*.*',Archive,Info);
 While DosError=0 Do Begin
  Inc(Cnt);
  FindNext(Info);
 End;
 Check('80 fichiers apres creation',Cnt=80);
 { rename vers un autre repertoire }
 Assign(G,'F2.TXT');
 {$I-}Rename(G,'..\MOVED.TXT');{$I+}
 Check('Rename vers repertoire parent',IOResult=0);
 ChDir('..');
 Assign(G,'MOVED.TXT');
 Reset(G,1);
 Check('MOVED.TXT a 2 octets',FileSize(G)=2);
 Close(G);
 { RmDir non vide }
 {$I-}RmDir('MANY');{$I+}
 Check('RmDir repertoire non vide refuse',IOResult<>0);
 {$I-}MkDir('MANY');{$I+}
 Check('MkDir repertoire existant refuse',IOResult<>0);
 { nettoyage MANY }
 ChDir('MANY');
 FindFirst('*.*',Archive,Info);
 While DosError=0 Do Begin
  S:=Info.Name;
  FindNext(Info);
  Assign(G,S);
  Erase(G);
 End;
 ChDir('..');
 RmDir('MANY');
 Check('RmDir apres nettoyage',IOResult=0);
 { 5. fichier texte }
 Assign(T,'TXT.TXT');
 Rewrite(T);
 For I:=1 To 300 Do WriteLn(T,'Ligne numero ',I,' avec du texte');
 Close(T);
 Reset(T);
 N:=0;
 While Not Eof(T) Do Begin
  ReadLn(T,S);
  Inc(N);
 End;
 Close(T);
 Check('300 lignes de texte relues',N=300);
 Check('derniere ligne',S='Ligne numero 300 avec du texte');
 { 6. nettoyage et espace libre }
 Assign(F,'BIG.DAT'); Erase(F);
 Assign(F,'GAP.DAT'); Erase(F);
 Assign(F,'MOVED.TXT'); Erase(F);
 Assign(F,'TXT.TXT'); Erase(F);
 Free1:=DiskFree(0);
 Check('espace libre restitue',Free1=Free0);
 If Fails=0 Then WriteLn('== TOUS LES TESTS REUSSIS ==') Else WriteLn('== ECHECS : ',Fails,' ==');
End.
