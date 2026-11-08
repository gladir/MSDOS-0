Program TDOS;
{$M 8192,0,0}
Uses DOS;
Var
 R:Registers;
 Fails:Word;
 Z:Array[0..79] of Char;
 Buf:Array[0..63] of Byte;
 S1,S2,S3,Psp:Word;
 Y,M,D,Dw,H,Mi,Sc,Cs:Word;
 V:Pointer;

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

Begin
 Fails:=0;
 WriteLn('== TDOS : fonctions systeme ==');
 R.AH:=$30; Check('30h version',Call And (R.AL>=3));
 GetDate(Y,M,D,Dw); Check('2Ah date plausible',
   (Y>=2024) And (M>=1) And (M<=12) And (D>=1) And (D<=31));
 GetTime(H,Mi,Sc,Cs); Check('2Ch heure plausible',
   (H<24) And (Mi<60) And (Sc<60));
 FillChar(Buf,SizeOf(Buf),$FF);
 R.AX:=$3800; R.DS:=Seg(Buf); R.DX:=Ofs(Buf);
 Check('38h infos pays',Call And (R.BX=33) And (Buf[2]<>$FF));
 R.AH:=$54; Check('54h verify = 0 au depart',Call And (R.AL=0));
 R.AH:=$2E; R.AL:=1; R.DL:=0; Call;
 R.AH:=$54; Check('2Eh/54h verify = 1',Call And (R.AL=1));
 R.AH:=$2E; R.AL:=0; R.DL:=0; Call;
 R.AX:=$5800; Check('5800h strategie',Call);
 R.AX:=$5801; R.BX:=2; Check('5801h fixer strategie',Call);
 R.AX:=$5800; Check('5800h relire = 2',Call And (R.AX=2));
 R.AX:=$5801; R.BX:=0; Call;
 Z[0]:='X'; Z[1]:=#0;
 R.AX:=$3D00; R.DS:=Seg(Z); R.DX:=Ofs(Z);
 Check('3Dh fichier absent -> erreur',Not Call);
 R.AH:=$59; R.BX:=0; Check('59h erreur etendue = 2',Call And (R.AX=2));
 R.AH:=$62; Check('62h PSP = PrefixSeg',Call And (R.BX=PrefixSeg));
 Psp:=R.BX;
 R.AH:=$51; Check('51h PSP identique',Call And (R.BX=Psp));
 R.AH:=$50; R.BX:=Psp; Check('50h fixer PSP',Call);
 R.AH:=$34; Check('34h indos',Call);
 R.AH:=$19; Check('19h lecteur courant = C',Call And (R.AL=2));
 R.AH:=$36; R.DL:=0; Check('36h espace libre',
   Call And (R.AX<>$FFFF) And (R.BX>0));
 R.AH:=$48; R.BX:=$100; Check('48h allocation',Call);
 S1:=R.AX;
 R.AH:=$48; R.BX:=$100; Check('48h seconde allocation',Call);
 S2:=R.AX;
 Check('blocs distincts',(S1<>S2) And (S1<>0));
 R.AH:=$4A; R.ES:=S1; R.BX:=$80; Check('4Ah reduction du bloc',Call);
 R.AH:=$49; R.ES:=S1; Check('49h liberation',Call);
 R.AH:=$49; R.ES:=S2; Check('49h liberation 2',Call);
 R.AH:=$49; R.ES:=S2; Check('49h double liberation -> erreur',Not Call);
 R.AH:=$48; R.BX:=$FFFF; Check('48h trop grand -> erreur 8',
   (Not Call) And (R.AX=8) And (R.BX>$1000));
 GetIntVec($60,V);
 SetIntVec($60,Ptr($1234,$5678));
 GetIntVec($60,V);
 Check('25h/35h vecteur',(Seg(V^)=$1234) And (Ofs(V^)=$5678));
 R.AH:=$0B; Check('0Bh etat entree',Call);
 R.AH:=$67; R.BX:=30; Check('67h nombre de handles accepte',Call);
 R.AH:=$68; R.BX:=1; Check('68h commit',Call);
 R.AH:=$62; Call; 
 If Fails=0 Then WriteLn('== TOUS LES TESTS REUSSIS ==') Else
   WriteLn('== ECHECS : ',Fails,' ==');
End.
