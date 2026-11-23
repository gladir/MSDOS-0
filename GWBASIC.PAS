{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/gwbasic-0)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

{$IFNDEF FPC}
 {$N+,E+,S-}
 {$M 32768,0,393216}
{$ENDIF}
{$R-,B-,V-}

Program GWBASIC;

Uses {$IFDEF FPC}
      Crt,DOS,PtcGraph,PtcCrt,PtcMouse,Printer
     {$ELSE}
      Crt,DOS,Graph,Printer
     {$ENDIF};

Const
 Version='0.83';
 MaxLine=2000;
 MaxFile=15;
 MaxDim=8;
 MaxSS=20;
 MaxFor=32;
 MaxGosub=100;
 MaxWhile=32;
 MaxParm=8;
 MaxNum=1.701411834604692E+38;
 NK=215;

  { Table des mots rÇservÇs : les index 1 Ö 116 correspondent aux jetons
    $81 Ö $F4 du GW-BASIC, 128 Ö 164 aux jetons $FF81 Ö $FFA5,
    165 Ö 204 aux jetons $FE81 Ö $FEA8 et 205 Ö 215 aux jetons $FD81 Ö $FD8B. }
 KW:Array[1..NK]of String[9]=(
  'END','FOR','NEXT','DATA','INPUT','DIM','READ','LET','GOTO','RUN',
  'IF','RESTORE','GOSUB','RETURN','REM','STOP','PRINT','CLEAR','LIST','NEW',
  'ON','WAIT','DEF','POKE','CONT','','','OUT','LPRINT','LLIST',
  '','WIDTH','ELSE','TRON','TROFF','SWAP','ERASE','EDIT','ERROR','RESUME',
  'DELETE','AUTO','RENUM','DEFSTR','DEFINT','DEFSNG','DEFDBL','LINE','WHILE','WEND',
  'CALL','','','','WRITE','OPTION','RANDOMIZE','OPEN','CLOSE','LOAD',
  'MERGE','SAVE','COLOR','CLS','MOTOR','BSAVE','BLOAD','SOUND','BEEP','PSET',
  'PRESET','SCREEN','KEY','LOCATE','','TO','THEN','TAB(','STEP','USR',
  'FN','SPC(','NOT','ERL','ERR','STRING$','USING','INSTR','','VARPTR',
  'CSRLIN','POINT','OFF','INKEY$','','','','','','',
  '','','','','','','','','','AND',
  'OR','XOR','EQV','IMP','MOD','','HELP','SLEEP','CAT','CLR',
  'LTRIM$','RTRIM$','TRIM$','','','','','LEFT$','RIGHT$','MID$',
  'SGN','INT','ABS','SQR','RND','SIN','LOG','EXP','COS','TAN',
  'ATN','FRE','INP','POS','LEN','STR$','VAL','ASC','CHR$','PEEK',
  'SPACE$','OCT$','HEX$','LPOS','CINT','CSNG','CDBL','FIX','PEN','STICK',
  'STRIG','EOF','LOC','LOF','FILES','FIELD','SYSTEM','NAME','LSET','RSET',
  'KILL','PUT','GET','RESET','COMMON','CHAIN','DATE$','TIME$','PAINT','COM',
  'CIRCLE','DRAW','PLAY','TIMER','ERDEV','IOCTL','CHDIR','MKDIR','RMDIR','SHELL',
  'ENVIRON','VIEW','WINDOW','PMAP','PALETTE','LCOPY','CALLS','','','',
  'PCOPY','','LOCK','UNLOCK','CVI','CVS','CVD','MKI$','MKS$','MKD$',
  '','','','','EXTERR');

 kEND=1;kFOR=2;kNEXT=3;kDATA=4;kINPUT=5;kDIM=6;kREAD=7;kLET=8;kGOTO=9;kRUN=10;
 kIF=11;kRESTORE=12;kGOSUB=13;kRETURN=14;kREM=15;kSTOP=16;kPRINT=17;kCLEAR=18;
 kLIST=19;kNEW=20;kON=21;kWAIT=22;kDEF=23;kPOKE=24;kCONT=25;kOUT=28;kLPRINT=29;
 kLLIST=30;kWIDTH=32;kELSE=33;kTRON=34;kTROFF=35;kSWAP=36;kERASE=37;kEDIT=38;
 kERROR=39;kRESUME=40;kDELETE=41;kAUTO=42;kRENUM=43;kDEFSTR=44;kDEFDBL=47;
 kLINE=48;kWHILE=49;kWEND=50;kWRITE=55;kOPTION=56;kRANDOMIZE=57;kOPEN=58;
 kCLOSE=59;kLOAD=60;kMERGE=61;kSAVE=62;kCOLOR=63;kCLS=64;kMOTOR=65;kBSAVE=66;
 kSOUND=68;kBEEP=69;kPSET=70;kPRESET=71;kSCREEN=72;kKEY=73;kLOCATE=74;kTO=76;
 kTHEN=77;kTAB=78;kSTEP=79;kUSR=80;kFN=81;kSPC=82;kNOT=83;kERL=84;kERR=85;
 kSTRING=86;kUSING=87;kINSTR=88;kVARPTR=90;kCSRLIN=91;kPOINT=92;kOFF=93;
 kINKEY=94;kAND=110;kOR=111;kXOR=112;kEQV=113;kIMP=114;kMOD=115;kHELP=117;
 kSLEEP=118;kLEFT=128;kRIGHT=129;kMID=130;kRND=135;kFRE=142;kLEN=145;kVAL=147;
 kHEX=153;kCVI=205;kMKI=208;kFILES=165;kSYSTEM=167;kNAME=168;kKILL=171;
 kRESET=174;kCOMMON=175;kCHAIN=176;kDATE=177;kTIME=178;kPAINT=179;kCIRCLE=181;
 kDRAW=182;kPLAY=183;kTIMER=184;kIOCTL=186;kCHDIR=187;kMKDIR=188;kRMDIR=189;
 kSHELL=190;kENVIRON=191;kERDEV=185;kCAT=119;kCLR=120;kCALL=51;kBLOAD=67;
 kCOM=180;kPEN=159;kSTRIG=161;kFIELD=166;kLSET=169;kRSET=170;kPUT=172;kGET=173;
 kVIEW=192;kWINDOW=193;kPMAP=194;kPALETTE=195;kLCOPY=196;kCALLS=197;kPCOPY=201;
 kLOCK=203;kUNLOCK=204;kLTRIM=121;kTRIM=123;kEXTERR=215;

  { Messages d'erreur (numÇros identiques Ö ceux du GW-BASIC) }
 ErrMsg:Array[1..76]of String[38]=(
  'NEXT sans FOR','Erreur de syntaxe','RETURN sans GOSUB','Plus de DATA',
  'Appel de fonction illÇgal','DÇpassement de capacitÇ','MÇmoire insuffisante',
  'NumÇro de ligne indÇfini','Indice hors limites','DÇfinition en double',
  'Division par zÇro','IllÇgal en mode direct','Types incompatibles',
  'Plus d''espace pour les chaånes','Chaåne trop longue',
  'Formule de chaåne trop complexe','Impossible de continuer',
  'Fonction utilisateur non dÇfinie','Pas de RESUME','RESUME sans erreur','',
  'OpÇrande manquant','DÇbordement du tampon de ligne',
  'DÇlai du pÇriphÇrique dÇpassÇ','DÇfaillance du pÇriphÇrique','FOR sans NEXT',
  'Plus de papier','','WHILE sans WEND','WEND sans WHILE',
  '','','','','','','','','','','','','','','','','','','',
  'DÇbordement de FIELD','Erreur interne','Mauvais numÇro de fichier',
  'Fichier introuvable','Mauvais mode de fichier','Fichier dÇjÖ ouvert','',
  'Erreur d''E/S du pÇriphÇrique','Le fichier existe dÇjÖ','','','Disque plein',
  'Lecture au-delÖ de la fin','Mauvais numÇro d''enregistrement',
  'Mauvais nom de fichier','','Instruction directe dans le fichier',
  'Trop de fichiers','PÇriphÇrique non disponible',
  'DÇbordement du tampon de communication','Permission refusÇe',
  'Disque pas pràt','Erreur de support du disque','Fonction avancÇe',
  'Renommage entre disques','Erreur d''accäs chemin/fichier',
  'Chemin introuvable');

 { Messages (constantes typÇes : rangÇes dans le segment de donnÇes) }
 MsgHelp1:String[68]='GWBASIC : Cette commande permet de lancer l''interprÇteur de GWBASIC.';
 MsgHelp2:String[66]=' fichier   Ce paramätre permet d''indiquer le nom du fichier BASIC.';
 MsgLic:String[55]='Licence libre et open source MIT 2021, 2022, 2024, 2026';
 MsgSeed:String[48]='Germe du gÇnÇrateur alÇatoire (-32768 Ö 32767)? ';
 MsgClone:String[46]=' - Clone Pascal de corail, MS-DOS-0, GWBASIC-0';
 MsgRedo:String[28]='?Recommencez depuis le dÇbut';
 MsgSyntax:String[27]='Syntaxe : GWBASIC [fichier]';
 MsgAuthor:String[25]='êcrit par Sylvain Maltais';
 MsgUnprint:String[21]='Erreur non imprimable';
 MsgDigits:String[16]='0123456789ABCDEF';
 MsgTitle:String[15]='GW-BASIC Clone ';
 MsgFree:String[14]=' octets libres';
 MsgAtLine:String[12]=' Ö la ligne ';
 MsgBreak:String[10]='Interrompu';

  { Raccourcis Alt+lettre (code de balayage 16 Ö 50) vers un mot rÇservÇ }
 AltKey:Array[16..50]of Byte=(
  0,kWIDTH,kELSE,kRUN,kTHEN,0,kUSING,kINPUT,kOPEN,kPRINT,0,0,0,0,
  kAUTO,kSCREEN,kDELETE,kFOR,kGOTO,kHEX,0,kKEY,kLOCATE,0,0,0,0,0,0,
  kXOR,kCOLOR,kVAL,kBSAVE,kNEXT,kMOTOR);

Type
 StrPointer=^String;
 PStrPtr=^StrPointer;
 TStrArr=Array[0..63]of StrPointer;
 PStrArr=^TStrArr;
 PInt=^Integer;
 PSng=^Single;
 PDbl=^Double;
 TByteArr=Array[0..65519]of Byte;
 PByteArr=^TByteArr;
 TKey=String[41];
 PLine=^TLine;
 TLine=Record
  Num:Word;
  Text:String;
 End;
 PVar=^TVar;
 TVar=Record
  Next:PVar;
  Value:Double;
  Name:TKey;
 End;
 PArr=^TArr;
 TArr=Record
  Next:PArr;
  Data:PByteArr;
  Size:Word;
  NDim:Byte;
  Dim:Array[1..MaxDim]of Integer;
  Name:TKey;
 End;
 PFn=^TFn;
 TFn=Record
  Next:PFn;
  LinePtr,Pos:Integer;
  Name:TKey;
 End;
 TRef=Record
  T:Char;
  P:Pointer;
 End;
 ForRec=Record
  P:Pointer;
  T:Char;
  Lim,Stp:Double;
  LP,Pos:Integer;
 End;
 GosubRec=Record
  LP,Pos,FSP,WSP:Integer;
  Jmp:Boolean;
  Ev:Byte;
 End;
 PField=^TField;
 TField=Record
  Next:PField;
  F:Byte;
  Ofs,Len:Word;
  P:PStrPtr;
 End;
 {$IFDEF FPC}
  TVMem=Array[0..65535]of Byte;
 {$ENDIF}
 WhileRec=Record
  LP,Pos:Integer;
 End;

Var
 PA:Array[1..MaxLine]of PLine;
 NumberLine:Integer;
 CurrLine,DirectLine,EditBuf:String;
 CurrPos,CurrLinePtr,StmtPtr,StmtPos:Integer;
 ErrCode,ErrNum,ForceLine:Integer;
 ErrLin,OnErrLine:Word;
 InHandler:Boolean;
 ResPtr,ResPos:Integer;
 Jumped,StopExec,Terminated,Tron,KeyFunction,BreakFlag:Boolean;
 ContOk,ContJump:Boolean;
 ContPtr,ContPos:Integer;
 VT:Char;
 VN:Double;
 VS:String;
 SS:Array[1..MaxSS]of String;
 SSP:Integer;
 VarList:PVar;
 ArrList:PArr;
 FnList:PFn;
 DefT:Array['A'..'Z']of Char;
 OptBase,FnDepth,EvDepth:Integer;
 ForStk:Array[1..MaxFor]of ForRec;
 GosubStk:Array[1..MaxGosub]of GosubRec;
 WhileStk:Array[1..MaxWhile]of WhileRec;
 ForSP,GosubSP,WhileSP:Integer;
 DataPtr,DataPos,DataLine:Integer;
 DataIn:Boolean;
 RndX:LongInt;
 OutF,LPCol:Integer;
 FT:Array[1..MaxFile]of Text;
 FMode:Array[1..MaxFile]of Char;
 FCol,FLook:Array[1..MaxFile]of Integer;
 KeyBuf:String[20];
 FileName:String;
 FunctionKeyList:Array[1..10]of String[15];
 AutoLines,IncrAuto:Word;
 IsAuto,IsEdit,ShowOk:Boolean;
 InGraph:Boolean;
 GMode,GW,GH,GLX,GLY,GCol,GRow,GFore:Integer;
 ScrW:Integer;
 DefSeg:Word;
 PollCnt:Byte;
 POct,PLen,PTempo,PStyle:Integer;
 FR:Array[1..MaxFile]of File;
 FBuf:Array[1..MaxFile]of PByteArr;
 FLen:Array[1..MaxFile]of Word;
 FRec,FCnt:Array[1..MaxFile]of LongInt;
 FREof:Array[1..MaxFile]of Boolean;
 FNm:Array[1..MaxFile]of StrPointer;
 FieldList:PField;
 EvLine:Array[1..29]of Word;
 EvSt:Array[1..29]of Byte;
 EvPend:Array[1..29]of Boolean;
 TimerInt,TimerRef:Double;
 ViewOn,WinOn,WinScr:Boolean;
 VX1,VY1,VX2,VY2,VOX,VOY,VTop,VBot:Integer;
 WX1,WY1,WX2,WY2:Double;
 CommonStr:String;
 EnvList:PStrArr;
 EnvCnt:Integer;
 UsrAddr:Array[0..9]of Word;
 UsrDef:Word;
 VPKey:Array[0..15]of Word;
 VPRef:Array[0..15]of TRef;
 VPN:Byte;
 {$IFDEF FPC}
  VMem:^TVMem;
 {$ENDIF}

 { Utilitaires }
Procedure Err(N:Integer);Begin
 If ErrCode=0 Then ErrCode:=N;
End;

Procedure SynErr;Begin
 Err(2);
End;

Function Alloc(Size:Word):Pointer;
Var
 P:Pointer;
Begin
 {$IFNDEF FPC}
  If MaxAvail<Size Then Begin
   Err(7);
   Alloc:=NIL;
   Exit;
  End;
 {$ENDIF}
 GetMem(P,Size);
 Alloc:=P;
End;

Function IntToStr(L:LongInt):String;
Var
 S:String;
Begin
 Str(L,S);
 IntToStr:=S;
End;

Function Rep(C:Char;N:Integer):String;
Var
 S:String;
Begin
 If N<0 Then N:=0;
 If N>255 Then N:=255;
 S[0]:=Chr(N);
 FillChar(S[1],N,C);
 Rep:=S;
End;

Procedure Order(Var A,B:Integer);
Var
 T:Integer;
Begin
 If A>B Then Begin
  T:=A;
  A:=B;
  B:=T;
 End;
End;

Function NumBase(L:LongInt;B:Integer):String;
Var
 S:String;
Begin
 S:='';
 Repeat
  S:=MsgDigits[L mod B+1]+S;
  L:=L div B;
 Until L=0;
 NumBase:=S;
End;

Function LTrim(S:String):String;
Var
 I:Integer;
Begin
 I:=1;
 While(I<=Length(s))and(S[I] in [#9,' '])do Inc(I);
 Delete(S,1,I-1);
 LTrim:=S;
End;

Function RTrim(S:String):String;
Var
 I:Integer;
Begin
 I:=Length(S);
 While(I>0)and(S[I]in[#9,' '])do Dec(I);
 S[0]:=Chr(I);
 RTrim:=S;
End;

Function StrToUpper(S:String):String;
Var
 I:Integer;
Begin
 For I:=1 to Length(S)do S[I]:=UpCase(S[I]);
 StrToUpper:=S;
End;

Function Pow10(E:Integer):Double;
Var
 R:Double;
 I:Integer;
Begin
 R:=1;
 For I:=1 to Abs(E)do R:=R*10;
 If E<0 Then Pow10:=1/R
        Else Pow10:=R;
End;

Function RoundI(X:Double):LongInt;Begin
 If X>=0 Then RoundI:=Trunc(X+0.5)
         Else RoundI:=-Trunc(0.5-X);
End;

Function Sng(X:Double):Double;
Var
 S:Single;
Begin
 S:=X;
 Sng:=S;
End;

Function CInt(X:Double):Integer;Begin
 If(X<=-32768.5)or(X>=32767.5)Then Begin
  Err(6);
  CInt:=0;
 End
  Else
 CInt:=RoundI(X);
End;

 { Analyse du texte de la ligne courante }
Function Cur:Char;Begin
 If CurrPos<=Length(CurrLine)Then Cur:=CurrLine[CurrPos]
                             Else Cur:=#0;
End;

Procedure SkipSp;Begin
 While(CurrPos<=Length(CurrLine))and(CurrLine[CurrPos]in[' ',#9])do Inc(CurrPos);
End;

Function NextCh:Char;Begin
 SkipSp;
 NextCh:=Cur;
End;

Function TokAt(P:Integer):Integer;
Var
 C:Char;
Begin
 TokAt:=0;
 If P<=Length(CurrLine)Then Begin
  C:=CurrLine[P];
  If C=#$FF Then Begin
   If P<Length(CurrLine)Then TokAt:=Ord(CurrLine[P+1]);
  End
   Else
  If C>=#$81 Then TokAt:=Ord(C)-$80;
 End;
End;

Function PeekTok:Integer;Begin
 SkipSp;
 PeekTok:=TokAt(CurrPos);
End;

Procedure SkipTok;Begin
 If Cur=#$FF Then Inc(CurrPos,2)
             Else Inc(CurrPos);
End;

Function AcceptTok(T:Integer):Boolean;Begin
 AcceptTok:=False;
 If PeekTok=T Then Begin
  SkipTok;
  AcceptTok:=True;
 End;
End;

Procedure ExpectTok(T:Integer);Begin
 If Not AcceptTok(T)Then SynErr;
End;

Function Accept(C:Char):Boolean;Begin
 Accept:=False;
 If NextCh=C Then Begin
  Inc(CurrPos);
  Accept:=True;
 End;
End;

Procedure Expect(C:Char);Begin
 If Not Accept(C)Then SynErr;
End;

Function IsDigit:Boolean;Begin
 IsDigit:=NextCh in['0'..'9'];
End;

Function EndOfStmt:Boolean;
Var
 C:Char;
Begin
 C:=NextCh;
 EndOfStmt:=(C=#0)or(C=':')or(C='''')or(TokAt(CurrPos)=kELSE);
End;

Function TokStr(K:Integer):String;Begin
 If K<=126 Then TokStr:=Chr($80+K)
           Else TokStr:=#$FF+Chr(K);
End;

Procedure SkipString;Begin
 Repeat
  Inc(CurrPos);
 Until(CurrPos>Length(CurrLine))or(CurrLine[CurrPos]='"');
 Inc(CurrPos);
End;

 { Avance jusqu'Ö la fin d'un DATA (':' hors guillemets) }
Procedure SkipData;
Var
 Q:Boolean;
Begin
 Q:=False;
 While CurrPos<=Length(CurrLine)do Begin
  If CurrLine[CurrPos]='"'Then Q:=Not Q Else
  If(CurrLine[CurrPos]=':')and Not Q Then Exit;
  Inc(CurrPos);
 End;
End;

 { Avance jusqu'Ö la fin de l'instruction courante }
Procedure SkipStmt;
Var
 C:Char;
Begin
 While CurrPos<=Length(CurrLine)do Begin
  C:=CurrLine[CurrPos];
  If C='"'Then SkipString Else
  If(C=':')or(C='''')or(TokAt(CurrPos)=kELSE)Then Exit Else
  If C=#$FF Then Inc(CurrPos,2)
            Else Inc(CurrPos);
 End;
End;

 { Lecture d'un nom de variable (avec son suffixe de type) }
Procedure ReadName(Var K:TKey);
Var
 T:Char;
Begin
 K:='';
 SkipSp;
 While(CurrPos<=Length(CurrLine))and(CurrLine[CurrPos]in['A'..'Z','0'..'9','.'])do Begin
  If Length(K)<40 Then K:=K+CurrLine[CurrPos];
  Inc(CurrPos);
 End;
 T:=Cur;
 If T in['%','!','#','$']Then Inc(CurrPos)
                         Else T:=DefT[K[1]];
 K:=K+T;
End;

Function ParseLineNum:Word;
Var
 L:LongInt;
Begin
 L:=0;
 ParseLineNum:=0;
 If Not IsDigit Then Begin
  SynErr;
  Exit;
 End;
 While Cur in['0'..'9']do Begin
  If L<100000 Then L:=L*10+Ord(Cur)-48;
  Inc(CurrPos);
 End;
 If L>65529 Then SynErr
            Else ParseLineNum:=L;
End;

 { Gestion de la liste des lignes du programme }
Function FindLine(N:Word;Var I:Integer):Boolean;
Var
 L,H,M:Integer;
Begin
 FindLine:=False;
 L:=1;
 H:=NumberLine;
 While L<=H do Begin
  M:=(L+H)shr 1;
  If PA[M]^.Num=N Then Begin
   I:=M;
   FindLine:=True;
   Exit;
  End;
  If PA[M]^.Num<N Then L:=M+1
                  Else H:=M-1;
 End;
 I:=L;
End;

Function LineSize(P:PLine):Word;Begin
 LineSize:=SizeOf(TLine)-255+Length(P^.Text);
End;

Procedure RemoveLine(I:Integer);
Var
 J:Integer;
Begin
 FreeMem(PA[I],LineSize(PA[I]));
 For J:=I to NumberLine-1 do PA[J]:=PA[J+1];
 Dec(NumberLine);
End;

Procedure StoreLine(N:Word;Const T:String);
Var
 I,J:Integer;
 P:PLine;
Begin
 If FindLine(N,I)Then RemoveLine(I);
 If T=''Then Exit;
 If NumberLine>=MaxLine Then Begin
  Err(7);
  Exit;
 End;
 P:=Alloc(SizeOf(TLine)-255+Length(T));
 If P=NIL Then Exit;
 P^.Num:=N;
 P^.Text:=T;
 For J:=NumberLine downto I do PA[J+1]:=PA[J];
 PA[I]:=P;
 Inc(NumberLine);
End;

Procedure LoadLine(P:Integer);Begin
 If P=0 Then CurrLine:=DirectLine
        Else CurrLine:=PA[P]^.Text;
 CurrLinePtr:=P;
End;

 { Conversion en jetons (comme le Æ cruncher Ø du GW-BASIC) }
Function MatchKW(Const S:String;I:Integer;Var L:Integer):Integer;
Var
 K,J,N:Integer;
 C:Char;
Begin
 MatchKW:=0;
 If(I+3<Length(S))and(UpCase(S[I])='G')and(UpCase(S[I+1])='O')and(S[I+2]=' ')Then Begin
  J:=I+2;
  While(J<Length(S))and(S[J]=' ')do Inc(J);
  C:=UpCase(S[J+1]);
  If(UpCase(S[J])='T')and(C='O')Then K:=kGOTO Else
  If(UpCase(S[J])='S')and(C='U')and(UpCase(S[J+2])='B')Then K:=kGOSUB
                                                       Else K:=0;
  If K>0 Then Begin
   If K=kGOTO Then L:=J+2-I
              Else L:=J+3-I;
   MatchKW:=K;
   Exit;
  End;
 End;
 For K:=1 to NK do Begin
  N:=Length(KW[K]);
  If(N>0)and(I+N-1<=Length(S))Then Begin
   J:=1;
   While(J<=N)and(UpCase(S[I+J-1])=KW[K][J])do Inc(J);
   If J>N Then Begin
    If(KW[K][N]='(')or(K=kFN)or(K=kUSR)or(I+N>Length(S))or
      Not(UpCase(S[I+N])in['A'..'Z','0'..'9','.'])Then Begin
     L:=N;
     MatchKW:=K;
     Exit;
    End;
   End;
  End;
 End;
End;

Function Crunch(Const S:String):String;
Var
 R:String;
 I,K,L:Integer;
 C:Char;
 InQ,Lit,DataM:Boolean;
Begin
 R:='';
 I:=1;
 InQ:=False;
 Lit:=False;
 DataM:=False;
 While I<=Length(S)do Begin
  C:=S[I];
  If Lit Then R:=R+C Else
  If C='"'Then Begin
   InQ:=Not InQ;
   R:=R+C;
  End
   Else
  If InQ Then R:=R+C Else
  If DataM Then Begin
   R:=R+C;
   If C=':'Then DataM:=False;
  End
   Else
  If C=''''Then Begin
   Lit:=True;
   R:=R+C;
  End
   Else
  If C='?'Then R:=R+TokStr(kPRINT) Else
  If UpCase(C)in['A'..'Z']Then Begin
   K:=MatchKW(S,I,L);
   If K>0 Then Begin
    R:=R+TokStr(K);
    Inc(I,L);
    If K=kREM Then Lit:=True;
    If K=kDATA Then DataM:=True;
    Continue;
   End;
   While(I<=Length(S))and(UpCase(S[I])in['A'..'Z','0'..'9','.'])do Begin
    R:=R+UpCase(S[I]);
    Inc(I);
   End;
   Continue;
  End
   Else
  If C in['0'..'9','.']Then Begin
   While(I<=Length(S))and(S[I]in['0'..'9','.'])do Begin
    R:=R+S[I];
    Inc(I);
   End;
   If(I<Length(S))and(UpCase(S[I])in['E','D'])and(S[I+1]in['0'..'9','+','-'])Then Begin
    R:=R+UpCase(S[I])+S[I+1];
    Inc(I,2);
    While(I<=Length(S))and(S[I]in['0'..'9'])do Begin
     R:=R+S[I];
     Inc(I);
    End;
   End;
   Continue;
  End
   Else
  If C='&'Then Begin
   R:=R+C;
   Inc(I);
   While(I<=Length(S))and(UpCase(S[I])in['0'..'9','A'..'F','H','O'])do Begin
    R:=R+UpCase(S[I]);
    Inc(I);
   End;
   Continue;
  End
   Else
  If C<#$80 Then R:=R+C;
  Inc(I);
 End;
 Crunch:=R;
End;

 { Conversion inverse pour LIST/SAVE }
Function Detok(Const S:String):String;
Var
 R:String;
 I,T:Integer;
 C:Char;
 InQ,Lit,DataM:Boolean;
Begin
 R:='';
 I:=1;
 InQ:=False;
 Lit:=False;
 DataM:=False;
 While I<=Length(S)do Begin
  C:=S[I];
  If Lit Then R:=R+C Else
  If C='"'Then Begin
   InQ:=Not InQ;
   R:=R+C;
  End
   Else
  If InQ Then R:=R+C Else
  If DataM Then Begin
   R:=R+C;
   If C=':'Then DataM:=False;
  End
   Else
  If C=''''Then Begin
   Lit:=True;
   R:=R+C;
  End
   Else
  If C>=#$81 Then Begin
   If C=#$FF Then Begin
    Inc(I);
    T:=Ord(S[I]);
   End
    Else
   T:=Ord(C)-$80;
   If T<=NK Then R:=R+KW[T];
   If T=kREM Then Lit:=True;
   If T=kDATA Then DataM:=True;
  End
   Else
  R:=R+C;
  Inc(I);
 End;
 Detok:=R;
End;

 { Sortie vers l'Çcran, l'imprimante ou un fichier }
Procedure GrNewLine;Begin
 GCol:=0;
 If GRow<23 Then Inc(GRow);
End;

Procedure GrOut(Const S:String);
Var
 I,CW,CH:Integer;
Begin
 CW:=(GetMaxX+1)div ScrW;
 CH:=(GetMaxY+1)div 25;
 For I:=1 to Length(S)do Begin
  If S[I]=#13 Then GrNewLine Else
  If S[I]>=' 'Then Begin
   If GCol>=ScrW Then GrNewLine;
   SetFillStyle(SolidFill,0);
   Bar(GCol*CW,GRow*CH,GCol*CW+CW-1,GRow*CH+CH-1);
   SetColor(GFore);
   OutTextXY(GCol*CW,GRow*CH,S[I]);
   Inc(GCol);
  End;
 End;
End;

Procedure OutS(Const S:String);Begin
 Case OutF of
  0:If(InGraph)Then GrOut(S)
               Else Write(S);
  -1:Begin
   {$I-}Write(Lst,S);{$I+}
   If IoResult<>0 Then;
   Inc(LPCol,Length(S));
  End;
  Else Begin
   {$I-}Write(FT[OutF],S);{$I+}
   If IoResult<>0 Then Err(57);
   Inc(FCol[OutF],Length(S));
   Inc(FCnt[OutF],Length(S));
  End;
 End;
End;

Procedure OutLn;Begin
 Case OutF of
  0:If(InGraph)Then GrNewLine
               Else WriteLn;
  -1:Begin
   {$I-}WriteLn(Lst);{$I+}
   If IoResult<>0 Then;
   LPCol:=0;
  End;
  Else Begin
   {$I-}WriteLn(FT[OutF]);{$I+}
   If IoResult<>0 Then Err(57);
   FCol[OutF]:=0;
  End;
 End;
End;

Function OutCol:Integer;Begin
 Case OutF of
  0:If(InGraph)Then OutCol:=GCol
               Else OutCol:=WhereX-1;
  -1:OutCol:=LPCol;
  Else OutCol:=FCol[OutF];
 End;
End;

Function OutWidth:Integer;Begin
 Case OutF of
  0:OutWidth:=ScrW;
  -1:OutWidth:=80;
  Else OutWidth:=255;
 End;
End;

Function ErrText(N:Integer):String;Begin
 If(N>=1)and(N<=76)and(ErrMsg[N]<>'')Then ErrText:=ErrMsg[N]
                                     Else ErrText:=MsgUnprint;
End;

Procedure ScreenMsg(Const S:String);Begin
 OutF:=0;
 If OutCol>0 Then OutLn;
 OutS(S);
 OutLn;
End;

 { Erreurs Æ douces Ø : division par zÇro et dÇpassement en virgule
   flottante affichent un message et l'exÇcution continue. }
Procedure SoftErr(N:Integer);
Var
 F:Integer;
Begin
 If(OnErrLine<>0)and Not InHandler Then Err(N)
  Else
 Begin
  F:=OutF;
  ScreenMsg(ErrText(N));
  OutF:=F;
 End;
End;

 { Valeurs numÇriques }
Function MaxT(A,B:Char):Char;Begin
 If(A='#')or(B='#')Then MaxT:='#' Else
 If(A='!')or(B='!')Then MaxT:='!'
                   Else MaxT:='%';
End;

Procedure Fix(X:Double;T:Char);Begin
 If Abs(X)>MaxNum Then Begin
  SoftErr(6);
  If X<0 Then X:=-MaxNum
         Else X:=MaxNum;
 End;
 If(T='%')and((X<-32768)or(X>32767))Then T:='!';
 If T='!'Then X:=Sng(X);
 VN:=X;
 VT:=T;
End;

Procedure FixI(I:LongInt);Begin
 Fix(I,'%');
End;

Procedure NeedNum;Begin
 If VT='$'Then Err(13);
End;

Function ToInt:Integer;Begin
 ToInt:=0;
 If VT='$'Then Err(13)
          Else ToInt:=CInt(VN);
End;

Function ToByte:Integer;
Var
 I:Integer;
Begin
 I:=ToInt;
 If(I<0)or(I>255)Then Err(5);
 ToByte:=I;
End;

 { Extraction des 18 premiers chiffres dÇcimaux de X (X>0) :
   X = 0,D x 10^(E+1). Le Str de Turbo Pascal Çtant imprÇcis au-delÖ du
   15e chiffre, on calcule les chiffres avec des puissances de 10 exactes. }
Procedure GetDigits(X:Double;Var D:String;Var E:Integer);
Var
 {$IFDEF FPC}
  S:String;
  K,I,Code:Integer;
  Ex:Extended;
 {$ELSE}
  Y,Q:Extended;
  K,I:Integer;

 Function P10(N:Integer):Extended;
 Var
  R:Extended;
  J:Integer;
 Begin
  R:=1;
  For J:=1 to N do R:=R*10;
  P10:=R;
 End;
 {$ENDIF}

Begin
 {$IFDEF FPC}
  Ex:=X;
  Str(Ex:26,S);
  I:=Pos('E',S);
  Val(Copy(S,I+1,6),E,Code);
  D:='';
  For K:=1 to I-1 do If S[K]in['0'..'9']Then D:=D+S[K];
  While(Length(D)>1)and(D[1]='0')do Begin
   Delete(D,1,1);
   Dec(E);
  End;
 {$ELSE}
  Y:=Ln(X)/Ln(10);
  E:=Trunc(Y);
  If(Y<0)and(E<>Y)Then Dec(E);
  Repeat
   K:=17-E;
   Y:=X;
   If K>27 Then Begin
    Y:=Y*P10(27);
    Dec(K,27);
   End;
   If K>0 Then Y:=Y*P10(K) Else
   If K<0 Then Y:=Y/P10(-K);
   Y:=Int(Y+0.5);
   If Y>=1E18 Then Inc(E) Else
   If Y<1E17 Then Dec(E)
             Else Break;
  Until False;
  D[0]:=#18;
  For I:=18 downto 1 do Begin
   Q:=Int(Y/10);
   D[I]:=Chr(48+Trunc(Y-Q*10));
   Y:=Q;
  End;
 {$ENDIF}
End;

 { Conversion d'un nombre en texte selon les rägles du GW-BASIC :
   7 chiffres en simple prÇcision, 16 en double prÇcision. }
Function NumToStr(X:Double;T:Char):String;
Var
 S,D:String;
 E,K,N,P,I:Integer;
 Neg:Boolean;
Begin
 Neg:=X<0;
 If(Neg)Then X:=-X;
 If T='%'Then Str(RoundI(X),S) Else
 If X=0 Then S:='0'
  Else
 Begin
  If T='#'Then P:=16
          Else P:=7;
  GetDigits(X,D,E);
  If Length(D)>P Then Begin
   If D[P+1]>='5'Then Begin
    I:=P;
    While(I>0)and(D[I]='9')do Begin
     D[I]:='0';
     Dec(I);
    End;
    If I=0 Then Begin
     D:='1'+D;
     Inc(E);
    End
     Else
    D[I]:=Succ(D[I]);
   End;
   D[0]:=Chr(P);
  End;
  N:=Length(D);
  While(N>1)and(D[N]='0')do Dec(N);
  D[0]:=Chr(N);
  K:=E+1;
  If(K>P)or((K<=0)and(N-K>P))Then Begin
   S:=D[1];
   If N>1 Then S:=S+'.'+Copy(D,2,P);
   If T='#'Then S:=S+'D'
           Else S:=S+'E';
   If K<1 Then S:=S+'-'
          Else S:=S+'+';
   E:=Abs(K-1);
   If E<10 Then S:=S+'0';
   S:=S+IntToStr(E);
  End
   Else
  If K<=0 Then S:='.'+Rep('0',-K)+D Else
  If N<=K Then S:=D+Rep('0',K-N)
          Else S:=Copy(D,1,K)+'.'+Copy(D,K+1,P);
 End;
 If(Neg)Then NumToStr:='-'+S
        Else NumToStr:=' '+S;
End;

 { Lecture d'un nombre (constante, VAL, INPUT, READ) }
Function ScanNum(Const S:String;Var P:Integer;Var X:Double;Var T:Char;Lenient:Boolean):Boolean;
Var
 M:String[20];
 B,Dig,FracCnt,ExpV,I,Code,P0:Integer;
 Dot,ExpS,Neg,ExpNeg,Any:Boolean;
 C:Char;
 L:LongInt;

 Function Ch:Char;Begin
  If(Lenient)Then While(P<=Length(S))and(S[P]in[' ',#9])do Inc(P);
  If P<=Length(S)Then Ch:=UpCase(S[P])
                 Else Ch:=#0;
 End;

Begin
 X:=0;
 T:='!';
 Neg:=False;
 Any:=False;
 P0:=P;
 C:=Ch;
 If(Lenient)and(C in['+','-'])Then Begin
  Neg:=C='-';
  Inc(P);
  C:=Ch;
 End;
 If C='&'Then Begin
  Inc(P);
  C:=Ch;
  B:=8;
  If C='H'Then Begin
   B:=16;
   Inc(P);
  End
   Else
  If C='O'Then Inc(P);
  L:=0;
  Repeat
   C:=Ch;
   If C in['0'..'9']Then I:=Ord(C)-48 Else
   If C in['A'..'F']Then I:=Ord(C)-55
                    Else I:=99;
   If I>=B Then Break;
   L:=L*B+I;
   Inc(P);
   Any:=True;
   If L>65535 Then Begin
    Err(6);
    L:=0;
   End;
  Until False;
  If L>32767 Then L:=L-65536;
  X:=L;
  T:='%';
 End
  Else
 Begin
  M:='';
  Dot:=False;
  ExpS:=False;
  Dig:=0;
  FracCnt:=0;
  ExpV:=0;
  Repeat
   C:=Ch;
   If C in['0'..'9']Then Begin
    Any:=True;
    If(M='')and(C='0')Then Begin
     If(Dot)Then Inc(FracCnt);
    End
     Else
    If Length(M)<20 Then Begin
     M:=M+C;
     If(Dot)Then Inc(FracCnt);
    End
     Else
    If Not Dot Then Dec(FracCnt);
    If M<>''Then Inc(Dig);
   End
    Else
   If(C='.')and Not Dot Then Dot:=True
                        Else Break;
   Inc(P);
  Until False;
  If(Any)and(C in['E','D'])Then Begin
   I:=P;
   Inc(P);
   ExpNeg:=False;
   C:=Ch;
   If C in['+','-']Then Begin
    ExpNeg:=C='-';
    Inc(P);
   End;
   If Ch in['0'..'9']Then Begin
    ExpS:=True;
    If UpCase(S[I])='D'Then T:='#';
    While Ch in['0'..'9']do Begin
     If ExpV<1000 Then ExpV:=ExpV*10+Ord(Ch)-48;
     Inc(P);
    End;
    If(ExpNeg)Then ExpV:=-ExpV;
   End
    Else
   P:=I;
  End;
  C:=Ch;
  If(Not Lenient)and(C in['%','!','#'])Then Begin
   T:=C;
   Inc(P);
  End
   Else
  If Not ExpS Then Begin
   If Dig>7 Then T:='#' Else
   If Not Dot Then T:='%';
  End;
  If M<>''Then Begin
   ExpV:=ExpV-FracCnt;
   If Length(M)+ExpV>39 Then Begin
    SoftErr(6);
    X:=MaxNum;
   End
    Else
   If Length(M)+ExpV>=-38 Then Val(M+'E'+IntToStr(ExpV),X,Code);
   If X>MaxNum Then X:=MaxNum;
  End;
  If(T='%')and(X>32767)Then Begin
   If(C='%')and Not Lenient Then Err(6)
                            Else T:='!';
  End;
 End;
 If Not Any Then P:=P0;
 ScanNum:=Any;
 If(Neg)Then X:=-X;
 If T='%'Then X:=CInt(X) Else
 If T='!'Then X:=Sng(X);
End;

 { Pile de chaånes temporaires (Çvite les grosses variables locales) }
Procedure PushS(Const S:String);Begin
 Inc(SSP);
 If SSP>MaxSS Then Err(16)
              Else SS[SSP]:=S;
End;

 { Variables et tableaux }
Function ESize(T:Char):Integer;Begin
 Case T of
  '%':ESize:=2;
  '!':ESize:=4;
  '#':ESize:=8;
  Else ESize:=SizeOf(StrPointer);
 End;
End;

Procedure SetStrP(P:PStrPtr;Const S:String);Begin
 If P^<>NIL Then FreeMem(P^,Length(P^^)+1);
 P^:=NIL;
 If S<>''Then Begin
  P^:=Alloc(Length(S)+1);
  If P^<>NIL Then P^^:=S;
 End;
End;

Function FindVar(Const K:TKey):PVar;
Var
 V:PVar;
Begin
 V:=VarList;
 While(V<>NIL)and(V^.Name<>K)do V:=V^.Next;
 FindVar:=V;
End;

Function FindArr(Const K:TKey):PArr;
Var
 A:PArr;
Begin
 A:=ArrList;
 While(A<>NIL)and(A^.Name<>K)do A:=A^.Next;
 FindArr:=A;
End;

Function MakeArr(Const K:TKey;N:Integer;Var D:Array of Integer):PArr;
Var
 A:PArr;
 I:Integer;
 C:LongInt;
Begin
 MakeArr:=NIL;
 C:=ESize(K[Length(K)]);
 For I:=0 to N-1 do Begin
  If D[I]<OptBase Then Begin
   Err(9);
   Exit;
  End;
  C:=C*(D[I]-OptBase+1);
  If C>65520 Then Begin
   Err(7);
   Exit;
  End;
 End;
 A:=Alloc(SizeOf(TArr)-41+Length(K));
 If A=NIL Then Exit;
 A^.Data:=Alloc(C);
 If A^.Data=NIL Then Begin
  FreeMem(A,SizeOf(TArr)-41+Length(K));
  Exit;
 End;
 FillChar(A^.Data^,C,0);
 A^.Size:=C;
 A^.NDim:=N;
 For I:=1 to N do A^.Dim[I]:=D[I-1];
 A^.Name:=K;
 A^.Next:=ArrList;
 ArrList:=A;
 MakeArr:=A;
End;

Procedure FreeArr(A:PArr);
Var
 I:Word;
Begin
 If A^.Name[Length(A^.Name)]='$'Then Begin
  I:=0;
  While I<A^.Size do Begin
   SetStrP(@A^.Data^[I],'');
   Inc(I,SizeOf(StrPointer));
  End;
 End;
 FreeMem(A^.Data,A^.Size);
 FreeMem(A,SizeOf(TArr)-41+Length(A^.Name));
End;

Procedure FreeFns;
Var
 F:PFn;
Begin
 While FnList<>NIL do Begin
  F:=FnList;
  FnList:=F^.Next;
  FreeMem(F,SizeOf(TFn)-41+Length(F^.Name));
 End;
End;

Procedure DropFields(N:Integer;V:Pointer);
Var
 P,Q,Prev:PField;
Begin
 P:=FieldList;
 Prev:=NIL;
 While P<>NIL do Begin
  Q:=P^.Next;
  If((N=0)or(P^.F=N))and((V=NIL)or(P^.P=V))Then Begin
   If Prev=NIL Then FieldList:=Q
               Else Prev^.Next:=Q;
   FreeMem(P,SizeOf(TField));
  End
   Else
  Prev:=P;
  P:=Q;
 End;
End;

Procedure ClearVars;
Var
 V:PVar;
 A:PArr;
Begin
 DropFields(0,NIL);
 While VarList<>NIL do Begin
  V:=VarList;
  VarList:=V^.Next;
  If V^.Name[Length(V^.Name)]='$'Then SetStrP(@V^.Value,'');
  FreeMem(V,SizeOf(TVar)-41+Length(V^.Name));
 End;
 While ArrList<>NIL do Begin
  A:=ArrList;
  ArrList:=A^.Next;
  FreeArr(A);
 End;
 FreeFns;
End;

Procedure Eval;Forward;

 { Analyse d'une rÇfÇrence de variable (scalaire ou ÇlÇment de tableau) }
Procedure GetVarRef(Var R:TRef);
Var
 K:TKey;
 Sub,Dm:Array[0..MaxDim-1]of Integer;
 N,I:Integer;
 A:PArr;
 V:PVar;
 Idx:LongInt;
Begin
 R.P:=NIL;
 R.T:='!';
 If Not(NextCh in['A'..'Z'])Then Begin
  SynErr;
  Exit;
 End;
 ReadName(K);
 R.T:=K[Length(K)];
 If Cur in['(','[']Then Begin
  Inc(CurrPos);
  N:=0;
  Repeat
   If N>=MaxDim Then Begin
    Err(9);
    Exit;
   End;
   Eval;
   Sub[N]:=ToInt;
   Dm[N]:=10;
   Inc(N);
   If ErrCode<>0 Then Exit;
  Until Not Accept(',');
  If Not(Accept(')')or Accept(']'))Then Begin
   SynErr;
   Exit;
  End;
  A:=FindArr(K);
  If A=NIL Then A:=MakeArr(K,N,Dm);
  If A=NIL Then Exit;
  If A^.NDim<>N Then Begin
   Err(9);
   Exit;
  End;
  Idx:=0;
  For I:=0 to N-1 do Begin
   If(Sub[I]<OptBase)or(Sub[I]>A^.Dim[I+1])Then Begin
    Err(9);
    Exit;
   End;
   Idx:=Idx*(A^.Dim[I+1]-OptBase+1)+Sub[I]-OptBase;
  End;
  R.P:=@A^.Data^[Idx*ESize(R.T)];
 End
  Else
 Begin
  V:=FindVar(K);
  If V=NIL Then Begin
   V:=Alloc(SizeOf(TVar)-41+Length(K));
   If V=NIL Then Exit;
   V^.Value:=0;
   V^.Name:=K;
   V^.Next:=VarList;
   VarList:=V;
  End;
  R.P:=@V^.Value;
 End;
End;

 { Lecture et Çcriture d'une valeur Ö l'adresse d'une rÇfÇrence }
Procedure LoadRef(Const R:TRef);Begin
 VT:=R.T;
 Case R.T of
  '%':VN:=PInt(R.P)^;
  '!':VN:=PSng(R.P)^;
  '#':VN:=PDbl(R.P)^;
  Else If PStrPtr(R.P)^=NIL Then VS:=''
                            Else VS:=PStrPtr(R.P)^^;
 End;
End;

Procedure StoreNum(Const R:TRef;X:Double);Begin
 Case R.T of
  '%':PInt(R.P)^:=CInt(X);
  '!':PSng(R.P)^:=X;
  '#':PDbl(R.P)^:=X;
 End;
End;

 { Range l'accumulateur dans la variable }
Procedure StoreVal(Const R:TRef);Begin
 If ErrCode<>0 Then Exit;
 If(R.T='$')<>(VT='$')Then Err(13) Else
 If R.T='$'Then SetStrP(R.P,VS)
           Else StoreNum(R,VN);
End;

 { Clavier : tampon interne pour dÇtecter Ctrl+C sans perdre de touches }
Procedure PollKey;
Var
 C,E:Char;
 K:Integer;
Begin
 While KeyPressed do Begin
  C:=ReadKey;
  E:=#0;
  K:=0;
  If C=#0 Then Begin
   E:=ReadKey;
   Case E of
    #59..#68:K:=Ord(E)-58;
    #72:K:=11;
    #75:K:=12;
    #77:K:=13;
    #80:K:=14;
   End;
  End;
  If(K>0)and(EvSt[K]>0)Then EvPend[K]:=True Else
  If C=#3 Then BreakFlag:=True Else
  If Length(KeyBuf)<18 Then Begin
   KeyBuf:=KeyBuf+C;
   If C=#0 Then KeyBuf:=KeyBuf+E;
  End;
 End;
End;

Function GetKey:Char;Begin
 If KeyBuf<>''Then Begin
  GetKey:=KeyBuf[1];
  Delete(KeyBuf,1,1);
 End
  Else
 GetKey:=ReadKey;
End;

 { Fichiers sÇquentiels }
Function FGet(N:Integer):Char;
Var
 C:Char;
Begin
 If FLook[N]>=0 Then Begin
  FGet:=Chr(FLook[N]);
  FLook[N]:=-1;
  Exit;
 End;
 Inc(FCnt[N]);
 {$I-}
 If Eof(FT[N])Then C:=#26
              Else Read(FT[N],C);
 {$I+}
 If IoResult<>0 Then C:=#26;
 FGet:=C;
End;

Function FEof(N:Integer):Boolean;Begin
 If FLook[N]>=0 Then FEof:=FLook[N]=26
  Else
 Begin
  {$I-}FEof:=Eof(FT[N]);{$I+}
  If IoResult<>0 Then FEof:=True;
 End;
End;

Function CheckFile(N:Integer;M:Char):Integer;Begin
 CheckFile:=0;
 If ErrCode<>0 Then Exit;
 If(N<1)or(N>MaxFile)Then Err(52) Else
 If FMode[N]=#0 Then Err(52) Else
 If((M='I')and(FMode[N]<>'I'))or((M='O')and Not(FMode[N]in['O','A']))or
   ((M='R')and(FMode[N]<>'R'))Then Err(54)
  Else
 CheckFile:=N;
End;

Function FileLen(N:Integer):LongInt;
Var
 F:File;
Begin
 FileLen:=0;
 {$I-}
 If FMode[N]='R'Then FileLen:=FileSize(FR[N])
  Else
 Begin
  If FMode[N]<>'I'Then Flush(FT[N]);
  Assign(F,FNm[N]^);
  Reset(F,1);
  If IoResult=0 Then Begin
   FileLen:=FileSize(F);
   Close(F);
  End;
 End;
 {$I+}
 If IoResult<>0 Then;
End;

 { MÇmoire (PEEK, POKE, BLOAD, BSAVE) : sous Free Pascal, un segment
   de 64 Ko simulÇ remplace la mÇmoire rÇelle du DOS. }
Function PeekB(S,A:Word):Byte;Begin
 {$IFDEF FPC}
  If VMem=NIL Then PeekB:=0
              Else PeekB:=VMem^[A];
 {$ELSE}
  PeekB:=Mem[S:A];
 {$ENDIF}
End;

Procedure PokeB(S,A:Word;B:Byte);Begin
 {$IFDEF FPC}
  If VMem=NIL Then Begin
   New(VMem);
   FillChar(VMem^,SizeOf(TVMem),0);
  End;
  VMem^[A]:=B;
 {$ELSE}
  Mem[S:A]:=B;
 {$ENDIF}
End;

Function Z2(N:Word):String;Begin
 Z2:=Chr(48+N div 10)+Chr(48+N mod 10);
End;

 { Format binaire Microsoft (MBF) utilisÇ par CVS/CVD/MKS$/MKD$ }
Function MBFToNum(Const S:String;N:Integer):Double;
Var
 M:Double;
 I,E:Integer;
Begin
 M:=0;
 E:=Ord(S[N+1]);
 If E<>0 Then Begin
  For I:=1 to N do If I=N Then M:=(M+(Ord(S[I])or $80))/256
                          Else M:=(M+Ord(S[I]))/256;
  Dec(E,128);
  While E>0 do Begin
   M:=M*2;
   Dec(E);
  End;
  While E<0 do Begin
   M:=M/2;
   Inc(E);
  End;
  If Ord(S[N])and $80<>0 Then M:=-M;
 End;
 MBFToNum:=M;
End;

Function NumToMBF(X:Double;N:Integer):String;
Var
 S:String;
 I,E,B:Integer;
 Neg:Boolean;
Begin
 S[0]:=Chr(N+1);
 FillChar(S[1],N+1,0);
 If X<>0 Then Begin
  Neg:=X<0;
  X:=Abs(X);
  E:=128;
  While X>=1 do Begin
   X:=X/2;
   Inc(E);
  End;
  While X<0.5 do Begin
   X:=X*2;
   Dec(E);
  End;
  If(E>0)and(E<256)Then Begin
   For I:=N downto 1 do Begin
    X:=X*256;
    B:=Trunc(X);
    X:=X-B;
    S[I]:=Chr(B);
   End;
   S[N]:=Chr((Ord(S[N])and $7F)or(Ord(Neg)shl 7));
   S[N+1]:=Chr(E);
  End;
 End;
 NumToMBF:=S;
End;

 { GÇnÇrateur alÇatoire identique Ö celui du GW-BASIC (congruentiel 24 bits) }
Function DoRnd(X:Double):Double;
Var
 S:Single;
 L:LongInt;
 Y:Double;
Begin
 If X<0 Then Begin
  S:=X;
  Move(S,L,4);
  RndX:=(L and $FFFF)or(((L shr 16)and $7F)or((L shr 24)and $80))shl 16;
 End;
 If X<>0 Then Begin
  Y:=RndX;
  Y:=Y*214013+2531011;
  RndX:=Trunc(Y-Int(Y/16777216)*16777216);
 End;
 DoRnd:=RndX/16777216.0;
End;

 { Graphiques : conversion des coordonnÇes logiques en coordonnÇes physiques }
Function SXp(X:Integer):Integer;Begin
 SXp:=LongInt(X-VOX)*(GetMaxX+1)div GW;
End;

Function SYp(Y:Integer):Integer;Begin
 SYp:=LongInt(Y-VOY)*(GetMaxY+1)div GH;
End;

Function GColor(C:Integer):Word;Begin
 Case GMode of
  1:Case C and 3 of
   0:GColor:=0;
   1:GColor:=3;
   2:GColor:=5;
   Else GColor:=15;
  End;
  2:If C<>0 Then GColor:=15
            Else GColor:=0;
  Else GColor:=C and 15;
 End;
End;

 { Couleur logique correspondant Ö une couleur physique }
Function LogColor(P:Word):Integer;
Var
 I:Integer;
Begin
 I:=0;
 While(I<15)and(GColor(I)<>P)do Inc(I);
 LogColor:=I;
End;

 { WINDOW : conversion entre coordonnÇes du monde et coordonnÇes logiques }
Function VWid:Integer;Begin
 If(ViewOn)Then VWid:=VX2-VX1+1
           Else VWid:=GW;
End;

Function VHgt:Integer;Begin
 If(ViewOn)Then VHgt:=VY2-VY1+1
           Else VHgt:=GH;
End;

Function Clip(X:Double):Integer;Begin
 If X>32000 Then X:=32000;
 If X<-32000 Then X:=-32000;
 Clip:=RoundI(X);
End;

Function MapX(X:Double):Integer;Begin
 If(WinOn)Then X:=(X-WX1)*(VWid-1)/(WX2-WX1)+VOX;
 MapX:=Clip(X);
End;

Function MapY(Y:Double):Integer;Begin
 If(WinOn)Then Begin
  If(WinScr)Then Y:=(Y-WY1)*(VHgt-1)/(WY2-WY1)+VOY
            Else Y:=(WY2-Y)*(VHgt-1)/(WY2-WY1)+VOY;
 End;
 MapY:=Clip(Y);
End;

Function UnX(L:Integer):Double;Begin
 If(WinOn)Then UnX:=(L-VOX)*(WX2-WX1)/(VWid-1)+WX1
          Else UnX:=L;
End;

Function UnY(L:Integer):Double;Begin
 If Not(WinOn)Then UnY:=L Else
 If(WinScr)Then UnY:=(L-VOY)*(WY2-WY1)/(VHgt-1)+WY1
           Else UnY:=WY2-(L-VOY)*(WY2-WY1)/(VHgt-1);
End;

Function Secs:Double;
Var
 H,M,S,S100:Word;
Begin
 GetTime(H,M,S,S100);
 Secs:=H*3600.0+M*60.0+S+S100/100;
End;

 { VARPTR : clÇ de 16 bits identifiant l'adresse d'une variable }
Function PtrKey(P:Pointer):Word;Begin
 {$IFDEF FPC}
  PtrKey:=Word(PtrUInt(P));
 {$ELSE}
  PtrKey:=Word(LongInt(Seg(P^))*16+Ofs(P^));
 {$ENDIF}
End;

 { Variable dÇsignÇe dans une chaåne DRAW/PLAY par VARPTR$ ou par nom; }
Function SubRef(Const S:String;Var I:Integer;Var R:TRef):Boolean;
Var
 K:TKey;
 V:PVar;
 C:Char;
 J:Integer;
Begin
 SubRef:=False;
 R.P:=NIL;
 If(I+2<=Length(S))and(S[I]in[#2,#3,#4,#8])Then Begin
  Case S[I]of
   #2:C:='%';
   #3:C:='$';
   #4:C:='!';
   Else C:='#';
  End;
  For J:=0 to 15 do If(VPRef[J].P<>NIL)and(VPRef[J].T=C)and
                      (VPKey[J]=Ord(S[I+1])+Ord(S[I+2])*256)Then Begin
   R:=VPRef[J];
   SubRef:=True;
  End;
  Inc(I,3);
 End
  Else
 Begin
  K:='';
  While(I<=Length(S))and(UpCase(S[I])in['A'..'Z','0'..'9','.','%','!','#','$'])do Begin
   K:=K+UpCase(S[I]);
   Inc(I);
  End;
  If(K<>'')and(K[1]in['A'..'Z'])Then Begin
   If Not(K[Length(K)]in['%','!','#','$'])Then K:=K+DefT[K[1]];
   V:=FindVar(K);
   If V<>NIL Then Begin
    R.T:=K[Length(K)];
    R.P:=@V^.Value;
    SubRef:=True;
   End;
  End;
 End;
 If(I<=Length(S))and(S[I]=';')Then Inc(I);
End;

Function SubNum(Const S:String;Var I:Integer):Integer;
Var
 R:TRef;
Begin
 SubNum:=0;
 If SubRef(S,I,R)and(R.T<>'$')Then Begin
  LoadRef(R);
  SubNum:=CInt(VN);
 End;
End;

 { USR, STICK, STRIG et EXTERR (services du BIOS et du DOS sous Turbo Pascal) }
Procedure CallUsr(N:Integer);
{$IFNDEF FPC}
 Var
  D:Double;
  P:Pointer;
  SaveDS:Word;
  T:Byte;
{$ENDIF}
Begin
 {$IFDEF FPC}
  Err(5);
 {$ELSE}
  D:=VN;
  T:=8;
  If VT='%'Then Begin
   T:=2;
   PInt(@D)^:=CInt(VN);
  End
   Else
  If VT='!'Then T:=4;
  P:=Ptr(DefSeg,UsrAddr[N]);
  SaveDS:=DSeg;
  Asm
   mov al,T
   push ss
   pop es
   lea bx,D
   call dword ptr P
   mov ds,SaveDS
  End;
  If T=2 Then FixI(PInt(@D)^)
         Else Fix(D,VT);
 {$ENDIF}
End;

Function DosInfo(T,N:Integer):Integer;
{$IFNDEF FPC}
 Const
  SB:Array[0..3]of Byte=($10,$40,$20,$80);
 Var
  Regs:Registers;
{$ENDIF}
Begin
 DosInfo:=0;
 {$IFNDEF FPC}
  FillChar(Regs,SizeOf(Regs),0);
  If T=kEXTERR Then Begin
   Regs.AH:=$59;
   MsDos(Regs);
   Case N of
    0:DosInfo:=Regs.AX;
    1:DosInfo:=Regs.BH;
    2:DosInfo:=Regs.BL;
    Else DosInfo:=Regs.CH;
   End;
  End
   Else
  Begin
   Regs.AH:=$84;
   Regs.DX:=Ord(T=160);
   Intr($15,Regs);
   If Regs.Flags and FCarry=0 Then Begin
    If T=160 Then Case N of
     0:DosInfo:=Regs.AX;
     1:DosInfo:=Regs.BX;
     2:DosInfo:=Regs.CX;
     Else DosInfo:=Regs.DX;
    End
     Else
    If Regs.AL and SB[N shr 1]=0 Then DosInfo:=-1;
   End;
  End;
 {$ENDIF}
End;

 { ENVIRON : variables d'environnement dÇfinies par le programme }
Function EnvFind(Const N:String):Integer;
Var
 I:Integer;
Begin
 EnvFind:=-1;
 For I:=0 to EnvCnt-1 do
  If Copy(EnvList^[I]^,1,Length(N)+1)=N+'='Then EnvFind:=I;
End;

Function EnvGet(N:String):String;
Var
 I:Integer;
Begin
 N:=StrToUpper(N);
 I:=EnvFind(N);
 If I<0 Then EnvGet:=GetEnv(N)
        Else EnvGet:=Copy(EnvList^[I]^,Length(N)+2,255);
End;

 { êvaluation des expressions }
Procedure EvalPrimary;Forward;
Procedure EvalNeg;Forward;
Procedure EvalRel;Forward;

Procedure EvalS;Begin
 Eval;
 If(ErrCode=0)and(VT<>'$')Then Err(13);
End;

Function EvalN:Double;Begin
 Eval;
 NeedNum;
 EvalN:=VN;
End;

Function EvalI:Integer;Begin
 Eval;
 EvalI:=ToInt;
End;

Function EvalB:Integer;Begin
 Eval;
 EvalB:=ToByte;
End;

Function DoPow(X,Y:Double):Double;
Var
 R,T:Double;
 N:LongInt;
 Neg:Boolean;
Begin
 DoPow:=1;
 If Y=0 Then Exit;
 If X=0 Then Begin
  If Y<0 Then Begin
   SoftErr(11);
   DoPow:=MaxNum;
  End
   Else
  DoPow:=0;
  Exit;
 End;
 Neg:=False;
 If X<0 Then Begin
  If Frac(Y)<>0 Then Begin
   Err(5);
   Exit;
  End;
  X:=-X;
  Neg:=Frac(Abs(Y)/2)<>0;
 End;
 T:=Y*Ln(X);
 If T>88.03 Then Begin
  SoftErr(6);
  R:=MaxNum;
 End
  Else
 If T<-104 Then R:=0 Else
 If(Frac(Y)=0)and(Abs(Y)<=64)Then Begin
  N:=Trunc(Abs(Y));
  R:=1;
  T:=X;
  While N>0 do Begin
   If Odd(N)Then R:=R*T;
   T:=T*T;
   N:=N shr 1;
  End;
  If Y<0 Then R:=1/R;
 End
  Else
 R:=Exp(T);
 If(Neg)Then R:=-R;
 DoPow:=R;
End;

Procedure EvalPow;
Var
 L:Double;
 LT:Char;
Begin
 EvalPrimary;
 While(ErrCode=0)and(NextCh='^')do Begin
  Inc(CurrPos);
  NeedNum;
  L:=VN;
  LT:=VT;
  If NextCh in['-','+']Then EvalNeg
                       Else EvalPrimary;
  NeedNum;
  If ErrCode=0 Then Begin
   If MaxT(LT,VT)='#'Then Fix(DoPow(L,VN),'#')
                     Else Fix(DoPow(L,VN),'!');
  End;
 End;
End;

Procedure EvalNeg;Begin
 Case NextCh of
  '-':Begin
   Inc(CurrPos);
   EvalNeg;
   NeedNum;
   If ErrCode=0 Then Fix(-VN,VT);
  End;
  '+':Begin
   Inc(CurrPos);
   EvalNeg;
  End;
  Else EvalPow;
 End;
End;

Procedure EvalMul;
Var
 L:Double;
 LT,C:Char;
Begin
 EvalNeg;
 While ErrCode=0 do Begin
  C:=NextCh;
  If Not(C in['*','/'])Then Exit;
  Inc(CurrPos);
  NeedNum;
  L:=VN;
  LT:=VT;
  EvalNeg;
  NeedNum;
  If ErrCode<>0 Then Exit;
  If C='*'Then Fix(L*VN,MaxT(LT,VT))
   Else
  Begin
   If MaxT(LT,VT)='#'Then LT:='#'
                     Else LT:='!';
   If VN=0 Then Begin
    SoftErr(11);
    If L<0 Then Fix(-MaxNum,LT)
           Else Fix(MaxNum,LT);
   End
    Else
   Fix(L/VN,LT);
  End;
 End;
End;

 { \ (division entiäre) et MOD }
Procedure EvalIM(IsMod:Boolean);
Var
 A,B:Integer;
Begin
 If(IsMod)Then EvalIM(False)
          Else EvalMul;
 While ErrCode=0 do Begin
  If(IsMod)Then Begin
   If Not AcceptTok(kMOD)Then Exit;
  End
   Else
  If NextCh='\'Then Inc(CurrPos)
               Else Exit;
  A:=ToInt;
  If(IsMod)Then EvalIM(False)
           Else EvalMul;
  B:=ToInt;
  If ErrCode<>0 Then Exit;
  If B=0 Then Begin
   SoftErr(11);
   If A<0 Then FixI(-32768)
          Else FixI(32767);
  End
   Else
  If(IsMod)Then FixI(A mod B)
           Else FixI(LongInt(A)div B);
 End;
End;

Procedure EvalAdd;
Var
 L:Double;
 LT,C:Char;
 K:Integer;
Begin
 EvalIM(True);
 While ErrCode=0 do Begin
  C:=NextCh;
  If Not(C in['+','-'])Then Exit;
  Inc(CurrPos);
  If VT='$'Then Begin
   If C='-'Then Begin
    Err(13);
    Exit;
   End;
   K:=SSP;
   PushS(VS);
   EvalIM(True);
   If(ErrCode=0)and(VT<>'$')Then Err(13);
   If ErrCode=0 Then Begin
    If Length(SS[K+1])+Length(VS)>255 Then Err(15)
                                      Else VS:=SS[K+1]+VS;
   End;
   SSP:=K;
  End
   Else
  Begin
   L:=VN;
   LT:=VT;
   EvalIM(True);
   NeedNum;
   If ErrCode<>0 Then Exit;
   If C='+'Then Fix(L+VN,MaxT(LT,VT))
           Else Fix(L-VN,MaxT(LT,VT));
  End;
 End;
End;

 { OpÇrateurs relationnels : = <> >< < > <= =< >= => }
Procedure EvalRel;
Var
 Op,K,Cmp:Integer;
 L:Double;
Begin
 EvalAdd;
 While ErrCode=0 do Begin
  Op:=0;
  Repeat
   Case NextCh of
    '<':Op:=Op or 1;
    '=':Op:=Op or 2;
    '>':Op:=Op or 4;
    Else Break;
   End;
   Inc(CurrPos);
  Until False;
  If Op=0 Then Exit;
  Cmp:=0;
  If VT='$'Then Begin
   K:=SSP;
   PushS(VS);
   EvalAdd;
   If(ErrCode=0)and(VT<>'$')Then Err(13);
   If ErrCode=0 Then Begin
    If SS[K+1]<VS Then Cmp:=1 Else
    If SS[K+1]=VS Then Cmp:=2
                  Else Cmp:=4;
   End;
   SSP:=K;
  End
   Else
  Begin
   L:=VN;
   EvalAdd;
   NeedNum;
   If L<VN Then Cmp:=1 Else
   If L=VN Then Cmp:=2
           Else Cmp:=4;
  End;
  If ErrCode<>0 Then Exit;
  FixI(-Ord(Op and Cmp<>0));
 End;
End;

 { AND, OR, XOR, EQV et IMP (NOT est traitÇ comme opÇrande) }
Procedure EvalLog(Lev:Integer);
Const
 Ops:Array[0..4]of Byte=(kIMP,kEQV,kXOR,kOR,kAND);
Var
 A,B:Integer;
Begin
 If Lev=4 Then EvalRel
          Else EvalLog(Lev+1);
 While(ErrCode=0)and AcceptTok(Ops[Lev])do Begin
  A:=ToInt;
  If Lev=4 Then EvalRel
           Else EvalLog(Lev+1);
  B:=ToInt;
  If ErrCode<>0 Then Exit;
  Case Lev of
   0:A:=(Not A)or B;
   1:A:=Not(A xor B);
   2:A:=A xor B;
   3:A:=A or B;
   Else A:=A and B;
  End;
  FixI(A);
 End;
End;

Procedure Eval;Begin
 Inc(EvDepth);
 If EvDepth>30 Then Err(7)
               Else EvalLog(0);
 Dec(EvDepth);
End;

 { Appel d'une fonction dÇfinie par DEF FN }
Procedure CallFn;
Var
 K:TKey;
 F:PFn;
 NA,NP,I,S0,LSlot,SP,SPos:Integer;
 Num,Old:Array[1..MaxParm]of Double;
 Typ:Array[1..MaxParm]of Char;
 OldP:Array[1..MaxParm]of StrPointer;
 Refs:Array[1..MaxParm]of TRef;
Begin
 If Not(NextCh in['A'..'Z'])Then Begin
  SynErr;
  Exit;
 End;
 ReadName(K);
 F:=FnList;
 While(F<>NIL)and(F^.Name<>K)do F:=F^.Next;
 If F=NIL Then Begin
  Err(18);
  Exit;
 End;
 If FnDepth>=8 Then Begin
  Err(7);
  Exit;
 End;
 S0:=SSP;
 NA:=0;
 If Accept('(')Then Begin
  Repeat
   If NA>=MaxParm Then Begin
    SynErr;
    Break;
   End;
   Inc(NA);
   Eval;
   If ErrCode<>0 Then Break;
   Typ[NA]:=VT;
   If VT='$'Then Begin
    PushS(VS);
    Num[NA]:=SSP;
   End
    Else
   Num[NA]:=VN;
  Until Not Accept(',');
  Expect(')');
 End;
 PushS(CurrLine);
 If ErrCode<>0 Then Begin
  SSP:=S0;
  Exit;
 End;
 Inc(FnDepth);
 LSlot:=SSP;
 SP:=CurrLinePtr;
 SPos:=CurrPos;
 LoadLine(F^.LinePtr);
 CurrPos:=F^.Pos;
 NP:=0;
 If Accept('(')Then Begin
  Repeat
   If NP>=NA Then Begin
    SynErr;
    Break;
   End;
   GetVarRef(Refs[NP+1]);
   If ErrCode<>0 Then Break;
   If(Refs[NP+1].T='$')<>(Typ[NP+1]='$')Then Begin
    Err(13);
    Break;
   End;
   Inc(NP);
   If Typ[NP]='$'Then Begin
    OldP[NP]:=PStrPtr(Refs[NP].P)^;
    PStrPtr(Refs[NP].P)^:=NIL;
    SetStrP(Refs[NP].P,SS[Trunc(Num[NP])]);
   End
    Else
   Begin
    LoadRef(Refs[NP]);
    Old[NP]:=VN;
    StoreNum(Refs[NP],Num[NP]);
   End;
  Until Not Accept(',');
  Expect(')');
 End;
 If(ErrCode=0)and(NP<>NA)Then SynErr;
 Expect('=');
 If ErrCode=0 Then Eval;
 For I:=NP downto 1 do Begin
  If Refs[I].T='$'Then Begin
   SetStrP(Refs[I].P,'');
   PStrPtr(Refs[I].P)^:=OldP[I];
  End
   Else
  StoreNum(Refs[I],Old[I]);
 End;
 CurrLine:=SS[LSlot];
 CurrLinePtr:=SP;
 CurrPos:=SPos;
 SSP:=S0;
 Dec(FnDepth);
 If ErrCode=0 Then Begin
  If(VT='$')<>(K[Length(K)]='$')Then Err(13) Else
  If VT<>'$'Then Begin
   If K[Length(K)]='%'Then FixI(CInt(VN))
                      Else Fix(VN,K[Length(K)]);
  End;
 End;
End;

 { Fonctions prÇdÇfinies }
Procedure EvalFunc(T:Integer);
Var
 X,Y:Double;
 I,N,K:Integer;
 L:LongInt;
 C:Char;
 H,M,S,S100:Word;
 R:TRef;
Begin
 Case T of
  kFN:CallFn;
  kNOT:Begin
   EvalRel;
   I:=ToInt;
   If ErrCode=0 Then FixI(Not I);
  End;
  kERL:Fix(ErrLin,'!');
  kERR:FixI(ErrNum);
  kCSRLIN:If(InGraph)Then FixI(GRow+1)
                     Else FixI(WhereY+VTop-1);
  kINKEY:Begin
   PollKey;
   VS:='';
   If KeyBuf<>''Then Begin
    N:=1;
    If KeyBuf[1]=#0 Then N:=2;
    VS:=Copy(KeyBuf,1,N);
    Delete(KeyBuf,1,N);
   End;
   VT:='$';
  End;
  kTIMER:Fix(Secs,'!');
  kPMAP:Begin
   Expect('(');
   X:=EvalN;
   Expect(',');
   N:=EvalI;
   Expect(')');
   If ErrCode=0 Then Case N of
    0:FixI(MapX(X));
    1:FixI(MapY(X));
    2:Fix(UnX(Clip(X)),'!');
    3:Fix(UnY(Clip(X)),'!');
    Else Err(5);
   End;
  End;
  kDATE:Begin
   GetDate(H,M,S,S100);
   VS:=Z2(M)+'-'+Z2(S)+'-'+IntToStr(H);
   VT:='$';
  End;
  kTIME:Begin
   GetTime(H,M,S,S100);
   VS:=Z2(H)+':'+Z2(M)+':'+Z2(S);
   VT:='$';
  End;
  kERDEV:Begin
   If Cur='$'Then Begin
    Inc(CurrPos);
    VS:='';
    VT:='$';
   End
    Else
   FixI(0);
  End;
  kENVIRON:Begin
   If Cur<>'$'Then Begin
    SynErr;
    Exit;
   End;
   Inc(CurrPos);
   Expect('(');
   Eval;
   Expect(')');
   If ErrCode=0 Then Begin
    If VT='$'Then VS:=EnvGet(VS)
             Else VS:=EnvStr(ToInt);
    VT:='$';
   End;
  End;
  kINPUT:Begin { INPUT$(n[,#f]) }
   If Cur<>'$'Then Begin
    SynErr;
    Exit;
   End;
   Inc(CurrPos);
   Expect('(');
   N:=EvalB;
   If(ErrCode=0)and(N=0)Then Err(5);
   K:=0;
   If Accept(',')Then Begin
    Accept('#');
    K:=CheckFile(EvalI,'I');
   End;
   Expect(')');
   If ErrCode<>0 Then Exit;
   VS:='';
   For I:=1 to N do Begin
    If K>0 Then Begin
     If FEof(K)Then Begin
      Err(62);
      Exit;
     End;
     VS:=VS+FGet(K);
    End
     Else
    VS:=VS+GetKey;
   End;
   VT:='$';
  End;
  kSTRING:Begin
   Expect('(');
   N:=EvalB;
   Expect(',');
   Eval;
   C:=' ';
   If ErrCode=0 Then Begin
    If VT='$'Then Begin
     If VS=''Then Err(5)
             Else C:=VS[1];
    End
     Else
    C:=Chr(ToByte);
   End;
   Expect(')');
   If ErrCode=0 Then Begin
    VS:=Rep(C,N);
    VT:='$';
   End;
  End;
  kINSTR:Begin
   Expect('(');
   Eval;
   N:=1;
   If(ErrCode=0)and(VT<>'$')Then Begin
    N:=ToInt;
    If(N<1)or(N>255)Then Err(5);
    Expect(',');
    EvalS;
   End;
   K:=SSP;
   PushS(VS);
   Expect(',');
   EvalS;
   Expect(')');
   If ErrCode=0 Then Begin
    I:=0;
    If N<=Length(SS[K+1])Then Begin
     If VS=''Then I:=N
      Else
     Begin
      I:=Pos(VS,Copy(SS[K+1],N,255));
      If I>0 Then Inc(I,N-1);
     End;
    End;
    FixI(I);
   End;
   SSP:=K;
  End;
  kLEFT,kRIGHT,kMID:Begin
   Expect('(');
   EvalS;
   K:=SSP;
   PushS(VS);
   Expect(',');
   N:=EvalB;
   I:=255;
   If T=kMID Then Begin
    If(ErrCode=0)and(N=0)Then Err(5);
    If Accept(',')Then I:=EvalB;
   End;
   Expect(')');
   If ErrCode=0 Then Begin
    Case T of
     kLEFT:VS:=Copy(SS[K+1],1,N);
     kRIGHT:If N>=Length(SS[K+1])Then VS:=SS[K+1]
                                 Else VS:=Copy(SS[K+1],Length(SS[K+1])-N+1,N);
     Else VS:=Copy(SS[K+1],N,I);
    End;
    VT:='$';
   End;
   SSP:=K;
  End;
  kRND:Begin
   X:=1;
   If Accept('(')Then Begin
    X:=EvalN;
    Expect(')');
   End;
   If ErrCode=0 Then Fix(DoRnd(X),'!');
  End;
  kPOINT:Begin
   Expect('(');
   X:=EvalN;
   If Accept(',')Then Begin
    Y:=EvalN;
    Expect(')');
    If(ErrCode=0)and Not(InGraph)Then Err(5);
    If ErrCode<>0 Then Exit;
    I:=SXp(MapX(X));
    N:=SYp(MapY(Y));
    If(I<0)or(N<0)or(I>GetMaxX)or(N>GetMaxY)Then FixI(-1)
                                            Else FixI(LogColor(GetPixel(I,N)));
   End
    Else
   Begin
    Expect(')');
    If ErrCode=0 Then Case RoundI(X)of
     0:FixI(GLX);
     1:FixI(GLY);
     2:Fix(UnX(GLX),'!');
     3:Fix(UnY(GLY),'!');
     Else Err(5);
    End;
   End;
  End;
  kSCREEN:Begin { SCREEN(ligne,colonne[,z]) }
   Expect('(');
   N:=EvalI;
   Expect(',');
   K:=EvalI;
   I:=0;
   If Accept(',')Then I:=EvalI;
   Expect(')');
   If ErrCode<>0 Then Exit;
   If(N<1)or(N>25)or(K<1)or(K>ScrW)Then Err(5)
    Else
   Begin
    {$IFDEF FPC}
     If I<>0 Then FixI(7)
             Else FixI(32);
    {$ELSE}
     FixI(Mem[$B800:((N-1)*ScrW+K-1)*2+Ord(I<>0)]);
    {$ENDIF}
   End;
  End;
  kVARPTR:Begin
   I:=Ord(Cur='$');
   Inc(CurrPos,I);
   Expect('(');
   If(I=0)and Accept('#')Then Begin
    N:=CheckFile(EvalI,' ');
    Expect(')');
    If ErrCode=0 Then Fix(PtrKey(@FT[N]),'!');
    Exit;
   End;
   GetVarRef(R);
   Expect(')');
   If ErrCode<>0 Then Exit;
   H:=PtrKey(R.P);
   If I=0 Then Fix(H,'!')
    Else
   Begin
    VPKey[VPN]:=H;
    VPRef[VPN]:=R;
    VPN:=(VPN+1)and 15;
    Case R.T of
     '%':C:=#2;
     '$':C:=#3;
     '!':C:=#4;
     Else C:=#8;
    End;
    VS:=C+Chr(Lo(H))+Chr(Hi(H));
    VT:='$';
   End;
  End;
  kUSR:Begin
   N:=0;
   If Cur in['0'..'9']Then Begin
    N:=Ord(Cur)-48;
    Inc(CurrPos);
   End;
   Expect('(');
   Eval;
   Expect(')');
   If ErrCode<>0 Then Exit;
   If(UsrDef and(1 shl N)=0)or(VT='$')Then Err(5)
                                      Else CallUsr(N);
  End;
  kIOCTL:Begin
   If Cur='$'Then Inc(CurrPos);
   Expect('(');
   Accept('#');
   CheckFile(EvalI,' ');
   Expect(')');
   Err(5);
  End;
  kLTRIM..kTRIM:Begin
   Expect('(');
   EvalS;
   Expect(')');
   If ErrCode=0 Then Begin
    If T<>kLTRIM+1 Then VS:=LTrim(VS);
    If T<>kLTRIM Then VS:=RTrim(VS);
   End;
  End;
  kPLAY,159..161,kEXTERR:Begin
   Expect('(');
   N:=EvalI;
   Expect(')');
   If ErrCode<>0 Then Exit;
   If(N<0)or((T=160)and(N>3))or((T=161)and(N>7))or((T=kEXTERR)and(N>3))Then Err(5) Else
   If T in[160,161,kEXTERR]Then FixI(DosInfo(T,N))
                           Else FixI(0);
  End;
  131..134,136..158,162..164,205..210:Begin
   Expect('(');
   If T in[162..164]Then Accept('#');
   Eval;
   Expect(')');
   If ErrCode<>0 Then Exit;
   If T in[kLEN,kVAL,148,205..207]Then Begin
    If VT<>'$'Then Begin
     Err(13);
     Exit;
    End;
   End
    Else
   If(T<>kFRE)and(VT='$')Then Begin
    Err(13);
    Exit;
   End;
   X:=VN;
   Case T of
    131:If X>0 Then FixI(1) Else
        If X<0 Then FixI(-1)
               Else FixI(0);
    132:Begin { INT }
     Y:=Int(X);
     If Y>X Then Y:=Y-1;
     Fix(Y,VT);
    End;
    133:Fix(Abs(X),VT);
    134:If X<0 Then Err(5)
               Else Fix(Sqrt(X),'!');
    136:Fix(Sin(X),'!');
    137:If X<=0 Then Err(5)
                Else Fix(Ln(X),'!');
    138:If X>88.02969 Then Begin
     SoftErr(6);
     Fix(MaxNum,'!');
    End
     Else
    Fix(Exp(X),'!');
    139:Fix(Cos(X),'!');
    140:If Cos(X)=0 Then Fix(MaxNum,'!')
                    Else Fix(Sin(X)/Cos(X),'!');
    141:Fix(ArcTan(X),'!');
    kFRE:{$IFDEF FPC}Fix(60000,'!');{$ELSE}Fix(MemAvail,'!');{$ENDIF}
    143:Begin
     {$IFDEF FPC}
      FixI(255);
     {$ELSE}
      FixI(Port[Word(RoundI(X))]);
     {$ENDIF}
    End;
    144:If(InGraph)Then FixI(GCol+1)
                   Else FixI(WhereX);
    kLEN:FixI(Length(VS));
    146:Begin
     VS:=NumToStr(X,VT);
     VT:='$';
    End;
    kVAL:Begin
     I:=1;
     If ScanNum(VS,I,X,C,True)Then Fix(X,C)
                              Else Fix(0,'!');
    End;
    148:If VS=''Then Err(5)
                Else FixI(Ord(VS[1]));
    149:Begin
     N:=ToByte;
     VS:=Chr(N);
     VT:='$';
    End;
    150:FixI(PeekB(DefSeg,Word(RoundI(X))));
    151:Begin
     VS:=Rep(' ',ToByte);
     VT:='$';
    End;
    152,kHEX:Begin
     L:=RoundI(X);
     If(L<-32768)or(L>65535)Then Err(6);
     If L<0 Then Inc(L,65536);
     If T=kHEX Then VS:=NumBase(L,16)
               Else VS:=NumBase(L,8);
     VT:='$';
    End;
    154:FixI(LPCol+1);
    155:FixI(CInt(X));
    156:Fix(X,'!');
    157:Fix(X,'#');
    158:Fix(Int(X),VT);
    162:Begin { EOF }
     N:=CheckFile(ToInt,' ');
     If ErrCode=0 Then Begin
      If FMode[N]='I'Then FixI(-Ord(FEof(N))) Else
      If FMode[N]='R'Then FixI(-Ord(FREof[N]))
                     Else FixI(0);
     End;
    End;
    163,164:Begin
     N:=CheckFile(ToInt,' ');
     If ErrCode=0 Then Begin
      If T=164 Then Fix(FileLen(N),'!') Else
      If FMode[N]='R'Then Fix(FRec[N],'!')
                     Else Fix(FCnt[N]div 128,'!');
     End;
    End;
    205:If Length(VS)<2 Then Err(5)
                        Else FixI(Integer(Word(Ord(VS[1])+Ord(VS[2])*256)));
    206:If Length(VS)<4 Then Err(5)
                        Else Fix(MBFToNum(VS,3),'!');
    207:If Length(VS)<8 Then Err(5)
                        Else Fix(MBFToNum(VS,7),'#');
    kMKI:Begin
     N:=ToInt;
     VS:=Chr(Lo(N))+Chr(Hi(N));
     VT:='$';
    End;
    209:Begin
     VS:=NumToMBF(X,3);
     VT:='$';
    End;
    210:Begin
     VS:=NumToMBF(X,7);
     VT:='$';
    End;
   End;
  End;
  Else SynErr;
 End;
End;

Procedure EvalPrimary;
Var
 C:Char;
 T:Integer;
 R:TRef;
Begin
 If ErrCode<>0 Then Exit;
 C:=NextCh;
 If C in['0'..'9','.','&']Then Begin
  If Not ScanNum(CurrLine,CurrPos,VN,VT,False)Then SynErr;
 End
  Else
 If C='"'Then Begin
  Inc(CurrPos);
  T:=CurrPos;
  While(CurrPos<=Length(CurrLine))and(CurrLine[CurrPos]<>'"')do Inc(CurrPos);
  VS:=Copy(CurrLine,T,CurrPos-T);
  VT:='$';
  If CurrPos<=Length(CurrLine)Then Inc(CurrPos);
 End
  Else
 If C='('Then Begin
  Inc(CurrPos);
  Eval;
  Expect(')');
 End
  Else
 If C in['A'..'Z']Then Begin
  GetVarRef(R);
  If ErrCode=0 Then LoadRef(R);
 End
  Else
 If C>=#$81 Then Begin
  T:=TokAt(CurrPos);
  SkipTok;
  EvalFunc(T);
 End
  Else
 If(C=#0)or(C=':')Then Err(22)
                  Else SynErr;
End;

 { Saut vers une ligne }
Procedure GotoIdx(I:Integer);Begin
 LoadLine(I);
 CurrPos:=1;
 Jumped:=True;
 If(Tron)Then OutS('['+IntToStr(PA[I]^.Num)+']');
End;

Procedure JumpTo(N:Word);
Var
 I:Integer;
Begin
 If ErrCode<>0 Then Exit;
 If FindLine(N,I)Then GotoIdx(I)
                 Else Err(8);
End;

Procedure DoBreak(P:Integer);Begin
 If CurrLinePtr>0 Then Begin
  ScreenMsg(MsgBreak+MsgAtLine+IntToStr(PA[CurrLinePtr]^.Num));
  ContOk:=True;
  ContPtr:=CurrLinePtr;
  ContPos:=P;
  ContJump:=True;
 End
  Else
 ScreenMsg(MsgBreak);
 StopExec:=True;
End;

 { êditeur de ligne (invite, INPUT, LINE INPUT, AUTO, EDIT) }
Function EditLine(Var S:String):Boolean;
Var
 SX,SY,I,Old,P:Integer;
 K:Char;
 Ins,Done:Boolean;
 Ext:String[20];
Begin
 EditLine:=False;
 SX:=WhereX;
 SY:=WhereY;
 I:=Length(S)+1;
 Old:=0;
 Ins:=False;
 Done:=False;
 Repeat
  GotoXY(SX,SY);
  Write(S);
  P:=Length(S);
  If Old>P Then Begin
   Write(Rep(' ',Old-P));
   P:=Old;
  End;
  P:=SX-1+P;
  If SY+P div ScrW>VBot-VTop+1 Then SY:=VBot-VTop+1-P div ScrW;
  Old:=Length(S);
  P:=SX-2+I;
  GotoXY(P mod ScrW+1,SY+P div ScrW);
  If(Done)Then Break;
  K:=GetKey;
  Ext:='';
  Case K of
   #0:Begin
    K:=GetKey;
    Case K of
     #16..#50:If AltKey[Ord(K)]<>0 Then Ext:=KW[AltKey[Ord(K)]]+' ';
     #59..#68:Ext:=FunctionKeyList[Ord(K)-58];
     #71:I:=1;
     #75:If I>1 Then Dec(I);
     #77:If I<=Length(S)Then Inc(I);
     #79:I:=Length(S)+1;
     #82:Ins:=Not Ins;
     #83:Delete(S,I,1);
    End;
   End;
   #3:Exit;
   #8:If I>1 Then Begin
    Delete(S,I-1,1);
    Dec(I);
   End;
   #13:Done:=True;
   #27:Begin
    S:='';
    I:=1;
   End;
   Else If K>=' 'Then Ext:=K;
  End;
  If Ext<>''Then Begin
   If Ext[Length(Ext)]=#13 Then Begin
    Dec(Ext[0]);
    Done:=True;
   End;
   If Not(Ins)and(I<=Length(S))Then Delete(S,I,Length(Ext));
   Insert(Ext,S,I);
   Inc(I,Length(Ext));
   If Length(S)>254 Then S[0]:=#254;
   If I>Length(S)+1 Then I:=Length(S)+1;
  End;
  If(Done)Then I:=Length(S)+1;
 Until False;
 EditLine:=True;
End;

 { PRINT USING }
Function FmtNum(X:Double;B,A,Fl:Integer):String;
Var
 S,D:String;
 Neg:Boolean;
 W,E,I,Dg:Integer;
 M:Double;
Begin
 Neg:=X<0;
 X:=Abs(X);
 If A<0 Then I:=0
        Else I:=A;
 W:=B+A+1+Ord(Fl and 2<>0)+Ord(Fl and 97<>0);
 If Fl and 16<>0 Then Begin
  Inc(W,4);
  Dg:=B;
  If Fl and 97=0 Then Dec(Dg);
  E:=0;
  If X<>0 Then Begin
   E:=Trunc(Ln(X)/Ln(10))-Dg+1;
   M:=X/Pow10(E);
   While M>=Pow10(Dg)do Begin
    M:=M/10;
    Inc(E);
   End;
   While(M<Pow10(Dg-1))and(Dg>0)do Begin
    M:=M*10;
    Dec(E);
   End;
   M:=Int(M*Pow10(I)+0.5)/Pow10(I);
   If M>=Pow10(Dg)Then Begin
    M:=M/10;
    Inc(E);
   End;
   X:=M;
  End;
 End;
 Str(X:0:I,S);
 If A<0 Then Begin
  I:=Pos('.',S);
  If I>0 Then S[0]:=Chr(I-1);
 End;
 If((B=0)or(Fl and 16<>0)and(Dg=0))and(Copy(S,1,2)='0.')Then Delete(S,1,1);
 If Fl and 8<>0 Then Begin
  I:=Pos('.',S);
  If I=0 Then I:=Length(S)+1;
  D:=Copy(S,I,255);
  S:=Copy(S,1,I-1);
  I:=Length(S)-3;
  While I>0 do Begin
   Insert(',',S,I+1);
   Dec(I,3);
  End;
  S:=S+D;
 End;
 If Fl and 16<>0 Then Begin
  S:=S+'E';
  If E<0 Then S:=S+'-'
         Else S:=S+'+';
  S:=S+Z2(Abs(E));
 End;
 If Fl and 2<>0 Then S:='$'+S;
 D:='';
 If(Neg)Then D:='-' Else
 If Fl and 33<>0 Then D:='+' Else
 If Fl and 64<>0 Then D:=' ';
 If Fl and 96<>0 Then S:=S+D
                 Else S:=D+S;
 If Length(S)>W Then S:='%'+S Else
 If Fl and 4<>0 Then S:=Rep('*',W-Length(S))+S
                Else S:=Rep(' ',W-Length(S))+S;
 FmtNum:=S;
End;

Procedure DoUsing;
Var
 F,P,L,B,A,Fl,Q:Integer;
 NoNL:Boolean;

 Function FieldAt(J:Integer):Boolean;
 Var
  C,N:Char;
 Begin
  C:=SS[F][J];
  If J<L Then N:=SS[F][J+1]
         Else N:=#0;
  Case C of
   '!','&','#':FieldAt:=True;
   '\':Begin
    Q:=J+1;
    While(Q<=L)and(SS[F][Q]=' ')do Inc(Q);
    FieldAt:=(Q<=L)and(SS[F][Q]='\');
   End;
   '.':FieldAt:=N='#';
   '+':FieldAt:=N in['#','.','$','*'];
   '$':FieldAt:=N='$';
   '*':FieldAt:=N='*';
   Else FieldAt:=False;
  End;
 End;

 Function Lit(Wrap:Boolean):Boolean;Begin
  Lit:=False;
  Repeat
   If P>L Then Begin
    If Not(Wrap)Then Exit;
    P:=1;
   End;
   If FieldAt(P)Then Begin
    Lit:=True;
    Exit;
   End;
   If(SS[F][P]='_')and(P<L)Then Inc(P);
   OutS(SS[F][P]);
   Inc(P);
  Until False;
 End;

Begin
 EvalS;
 If ErrCode<>0 Then Exit;
 L:=Length(VS);
 F:=SSP+1;
 PushS(VS);
 If Not(Accept(';')or Accept(','))Then SynErr;
 If ErrCode<>0 Then Exit;
 Q:=0;
 For P:=1 to L do If FieldAt(P)Then Q:=1;
 If Q=0 Then Begin
  Err(5);
  Exit;
 End;
 P:=1;
 NoNL:=False;
 Repeat
  Lit(True);
  Eval;
  If ErrCode<>0 Then Exit;
  Case SS[F][P]of
   '!','&','\':Begin
    If VT<>'$'Then Begin
     Err(13);
     Exit;
    End;
    Case SS[F][P]of
     '!':Begin
      OutS(Copy(VS+' ',1,1));
      Inc(P);
     End;
     '&':Begin
      OutS(VS);
      Inc(P);
     End;
     Else Begin
      FieldAt(P);
      B:=Q-P+1;
      OutS(Copy(VS+Rep(' ',B),1,B));
      P:=Q+1;
     End;
    End;
   End;
   Else Begin
    If VT='$'Then Begin
     Err(13);
     Exit;
    End;
    Fl:=0;
    B:=0;
    A:=-1;
    If SS[F][P]='+'Then Begin
     Fl:=1;
     Inc(P);
    End;
    If Copy(SS[F],P,3)='**$'Then Begin
     Fl:=Fl or 6;
     B:=2;
     Inc(P,3);
    End
     Else
    If Copy(SS[F],P,2)='**'Then Begin
     Fl:=Fl or 4;
     B:=2;
     Inc(P,2);
    End
     Else
    If Copy(SS[F],P,2)='$$'Then Begin
     Fl:=Fl or 2;
     B:=1;
     Inc(P,2);
    End;
    While(P<=L)and(SS[F][P]in['#',','])do Begin
     If SS[F][P]=','Then Fl:=Fl or 8;
     Inc(B);
     Inc(P);
    End;
    If(P<=L)and(SS[F][P]='.')Then Begin
     A:=0;
     Inc(P);
     While(P<=L)and(SS[F][P]='#')do Begin
      Inc(A);
      Inc(P);
     End;
    End;
    If Copy(SS[F],P,4)='^^^^'Then Begin
     Fl:=Fl or 16;
     Inc(P,4);
    End;
    If(Fl and 1=0)and(P<=L)Then Begin
     If SS[F][P]='+'Then Begin
      Fl:=Fl or 32;
      Inc(P);
     End
      Else
     If SS[F][P]='-'Then Begin
      Fl:=Fl or 64;
      Inc(P);
     End;
    End;
    OutS(FmtNum(VN,B,A,Fl));
   End;
  End;
  If Accept(';')or Accept(',')Then Begin
   If(EndOfStmt)Then Begin
    NoNL:=True;
    Break;
   End;
  End
   Else
  Begin
   If Not(EndOfStmt)Then SynErr
                    Else Lit(False);
   Break;
  End;
 Until ErrCode<>0;
 If(ErrCode=0)and Not(NoNL)Then OutLn;
End;

 { PRINT, LPRINT, PRINT # }
Procedure DoPrint(Dev:Integer);
Var
 C:Char;
 NoNL:Boolean;
 N,W,P:Integer;
 S:String;
Begin
 OutF:=Dev;
 If(Dev=0)and Accept('#')Then Begin
  OutF:=CheckFile(EvalI,'O');
  If ErrCode<>0 Then Exit;
  If Not Accept(',')Then If Not(EndOfStmt)Then SynErr;
 End;
 If AcceptTok(kUSING)Then Begin
  DoUsing;
  Exit;
 End;
 NoNL:=False;
 W:=OutWidth;
 While(ErrCode=0)and Not(EndOfStmt)do Begin
  C:=NextCh;
  NoNL:=True;
  N:=TokAt(CurrPos);
  If C=';'Then Inc(CurrPos) Else
  If C=','Then Begin
   Inc(CurrPos);
   P:=OutCol;
   If(W<255)and(P>=W-W mod 14-14)Then OutLn
                                 Else OutS(Rep(' ',14-P mod 14));
  End
   Else
  If(N=kTAB)or(N=kSPC)Then Begin
   SkipTok;
   P:=EvalI;
   Expect(')');
   If ErrCode<>0 Then Exit;
   If P<0 Then P:=0;
   If(N=kTAB)and(P>0)Then Dec(P);
   If W<255 Then P:=P mod W;
   If N=kSPC Then OutS(Rep(' ',P))
    Else
   Begin
    N:=OutCol;
    If P>N Then OutS(Rep(' ',P-N)) Else
    If P<N Then Begin
     OutLn;
     OutS(Rep(' ',P));
    End;
   End;
  End
   Else
  Begin
   NoNL:=False;
   Eval;
   If ErrCode<>0 Then Exit;
   If VT='$'Then S:=VS
    Else
   Begin
    S:=NumToStr(VN,VT);
    P:=OutCol+Length(S);
    If(NextCh<>',')or((W<255)and(P>=W-W mod 14-14))or((P+1)mod 14<>0)Then S:=S+' ';
   End;
   P:=OutCol;
   If(W<255)and(P>0)and(P+Length(S)>W)Then OutLn;
   OutS(S);
  End;
 End;
 If(ErrCode=0)and Not(NoNL)Then OutLn;
End;

Procedure DoWrite;
Var
 S:String;
Begin
 OutF:=0;
 If Accept('#')Then Begin
  OutF:=CheckFile(EvalI,'O');
  If ErrCode<>0 Then Exit;
  If Not Accept(',')Then If Not(EndOfStmt)Then SynErr;
 End;
 While(ErrCode=0)and Not(EndOfStmt)do Begin
  Eval;
  If ErrCode<>0 Then Exit;
  If VT='$'Then S:='"'+VS+'"'
   Else
  Begin
   S:=NumToStr(VN,VT);
   If S[1]=' 'Then Delete(S,1,1);
  End;
  OutS(S);
  If Accept(',')or Accept(';')Then OutS(',')
                              Else Break;
 End;
 If ErrCode=0 Then OutLn;
End;

 { INPUT # et LINE INPUT # }
Procedure FileInput(IsLine:Boolean);
Var
 N,P:Integer;
 R:TRef;
 C:Char;
Begin
 N:=CheckFile(EvalI,'I');
 Expect(',');
 If ErrCode<>0 Then Exit;
 Repeat
  GetVarRef(R);
  If ErrCode<>0 Then Exit;
  If FEof(N)Then Begin
   Err(62);
   Exit;
  End;
  VS:='';
  C:=FGet(N);
  If(IsLine)Then Begin
   While Not(C in[#13,#10,#26])do Begin
    VS:=VS+C;
    C:=FGet(N);
   End;
  End
   Else
  Begin
   While C in[' ',#13,#10]do C:=FGet(N);
   If C=#26 Then Begin
    Err(62);
    Exit;
   End;
   If(C='"')and(R.T='$')Then Begin
    C:=FGet(N);
    While Not(C in['"',#26])do Begin
     VS:=VS+C;
     C:=FGet(N);
    End;
    C:=FGet(N);
    While C=' 'do C:=FGet(N);
   End
    Else
   Begin
    While Not(C in[',',#13,#10,#26])and((R.T='$')or(C<>' '))do Begin
     VS:=VS+C;
     C:=FGet(N);
    End;
    If R.T='$'Then VS:=RTrim(VS)
              Else While C=' 'do C:=FGet(N);
   End;
   If Not(C in[',',#13,#10,#26])Then FLook[N]:=Ord(C);
  End;
  If C=#13 Then Begin
   C:=FGet(N);
   If C<>#10 Then FLook[N]:=Ord(C);
  End;
  If R.T='$'Then VT:='$'
   Else
  Begin
   P:=1;
   If Not ScanNum(VS,P,VN,VT,True)Then Fix(0,'!');
  End;
  StoreVal(R);
 Until(IsLine)or Not Accept(',');
End;

 { INPUT et LINE INPUT au clavier }
Procedure DoInput(IsLine:Boolean);
Var
 Prompt,Ln:String;
 VarPos,P,Pass,N:Integer;
 NoCR,Ok:Boolean;
 R:TRef;
Begin
 If Accept('#')Then Begin
  FileInput(IsLine);
  Exit;
 End;
 NoCR:=Accept(';');
 Prompt:='';
 If NextCh='"'Then Begin
  Inc(CurrPos);
  P:=CurrPos;
  While(CurrPos<=Length(CurrLine))and(CurrLine[CurrPos]<>'"')do Inc(CurrPos);
  Prompt:=Copy(CurrLine,P,CurrPos-P);
  If CurrPos<=Length(CurrLine)Then Inc(CurrPos);
  If Accept(';')Then Begin
   If Not(IsLine)Then Prompt:=Prompt+'? ';
  End
   Else
  If Not Accept(',')Then Begin
   SynErr;
   Exit;
  End;
 End
  Else
 If Not(IsLine)Then Prompt:='? ';
 VarPos:=CurrPos;
 Repeat
  OutF:=0;
  OutS(Prompt);
  Ln:='';
  If Not EditLine(Ln)Then Begin
   OutLn;
   DoBreak(StmtPos);
   Exit;
  End;
  If Not(NoCR)Then OutLn;
  If(IsLine)Then Begin
   GetVarRef(R);
   VS:=Ln;
   VT:='$';
   StoreVal(R);
   Exit;
  End;
  Ok:=True;
  For Pass:=0 to 1 do Begin
   CurrPos:=VarPos;
   P:=1;
   Repeat
    GetVarRef(R);
    If ErrCode<>0 Then Exit;
    While(P<=Length(Ln))and(Ln[P]=' ')do Inc(P);
    If R.T='$'Then Begin
     If(P<=Length(Ln))and(Ln[P]='"')Then Begin
      Inc(P);
      N:=P;
      While(P<=Length(Ln))and(Ln[P]<>'"')do Inc(P);
      VS:=Copy(Ln,N,P-N);
      Inc(P);
      While(P<=Length(Ln))and(Ln[P]=' ')do Inc(P);
     End
      Else
     Begin
      N:=P;
      While(P<=Length(Ln))and(Ln[P]<>',')do Inc(P);
      VS:=RTrim(Copy(Ln,N,P-N));
     End;
     VT:='$';
    End
     Else
    Begin
     VN:=0;
     VT:='!';
     If(P<=Length(Ln))and(Ln[P]<>',')Then Ok:=ScanNum(Ln,P,VN,VT,True);
     While(P<=Length(Ln))and(Ln[P]=' ')do Inc(P);
     If ErrCode<>0 Then Begin
      ErrCode:=0;
      Ok:=False;
     End;
     If(R.T='%')and((VN<-32768)or(VN>32767))Then Ok:=False;
    End;
    If(Ok)and(Pass=1)Then StoreVal(R);
    If(Ok)Then Begin
     If Accept(',')Then Begin
      If(P<=Length(Ln))and(Ln[P]=',')Then Inc(P)
                                     Else Ok:=False;
     End
      Else
     Begin
      If P<=Length(Ln)Then Ok:=False;
      Break;
     End;
    End;
   Until Not(Ok);
   If Not(Ok)Then Break;
  End;
  If(Ok)or(ErrCode<>0)Then Exit;
  OutS(MsgRedo);
  OutLn;
 Until False;
End;

 { DATA, READ et RESTORE }
Function NextData:Boolean;
Var
 L:PLine;
 P,Q:Integer;
 C:Char;
Begin
 NextData:=False;
 While DataPtr<=NumberLine do Begin
  L:=PA[DataPtr];
  P:=DataPos;
  If Not(DataIn)Then Begin
   While P<=Length(L^.Text)do Begin
    C:=L^.Text[P];
    If C='"'Then Begin
     Repeat
      Inc(P);
     Until(P>Length(L^.Text))or(L^.Text[P]='"');
     Inc(P);
    End
     Else
    If(C='''')or(C=Chr($80+kREM))Then P:=256 Else
    If C=Chr($80+kDATA)Then Begin
     DataIn:=True;
     Inc(P);
     Break;
    End
     Else
    If C=#$FF Then Inc(P,2)
              Else Inc(P);
   End;
   If Not(DataIn)Then Begin
    Inc(DataPtr);
    DataPos:=1;
    Continue;
   End;
  End;
  While(P<=Length(L^.Text))and(L^.Text[P]=' ')do Inc(P);
  If(P<=Length(L^.Text))and(L^.Text[P]='"')Then Begin
   Inc(P);
   Q:=P;
   While(P<=Length(L^.Text))and(L^.Text[P]<>'"')do Inc(P);
   VS:=Copy(L^.Text,Q,P-Q);
   While(P<=Length(L^.Text))and Not(L^.Text[P]in[',',':'])do Inc(P);
  End
   Else
  Begin
   Q:=P;
   While(P<=Length(L^.Text))and Not(L^.Text[P]in[',',':'])do Inc(P);
   VS:=RTrim(Copy(L^.Text,Q,P-Q));
  End;
  If(P<=Length(L^.Text))and(L^.Text[P]=',')Then Inc(P)
                                           Else DataIn:=False;
  DataPos:=P;
  DataLine:=L^.Num;
  NextData:=True;
  Exit;
 End;
End;

Procedure DoRead;
Var
 R:TRef;
 P:Integer;
Begin
 Repeat
  GetVarRef(R);
  If ErrCode<>0 Then Exit;
  If Not NextData Then Begin
   Err(4);
   Exit;
  End;
  If R.T='$'Then VT:='$'
   Else
  Begin
   P:=1;
   VN:=0;
   VT:='!';
   If VS<>''Then Begin
    If Not ScanNum(VS,P,VN,VT,True)or(P<=Length(VS))Then Begin
     ForceLine:=DataLine;
     SynErr;
     Exit;
    End;
   End;
  End;
  StoreVal(R);
 Until(ErrCode<>0)or Not Accept(',');
End;

Procedure DoRestore;
Var
 I:Integer;
Begin
 DataPtr:=1;
 DataPos:=1;
 DataIn:=False;
 If(IsDigit)Then Begin
  If FindLine(ParseLineNum,I)Then DataPtr:=I
                             Else Err(8);
 End;
End;

 { Fichiers : OPEN et CLOSE }
Function IOErr(R:Integer):Integer;Begin
 Case R of
  2:IOErr:=53;
  3:IOErr:=76;
  4:IOErr:=67;
  5:IOErr:=75;
  15:IOErr:=68;
  17:IOErr:=74;
  100:IOErr:=62;
  101:IOErr:=61;
  150:IOErr:=70;
  152:IOErr:=71;
  Else IOErr:=57;
 End;
End;

Function ReadWord:TKey;
Var
 K:TKey;
Begin
 K:='';
 SkipSp;
 While Cur in['A'..'Z']do Begin
  K:=K+Cur;
  Inc(CurrPos);
 End;
 ReadWord:=K;
End;

Procedure CloseFile(N:Integer);Begin
 If FMode[N]<>#0 Then Begin
  {$I-}
  If FMode[N]='R'Then Begin
   Close(FR[N]);
   FreeMem(FBuf[N],FLen[N]);
   DropFields(N,NIL);
  End
   Else
  Close(FT[N]);
  {$I+}
  If IoResult<>0 Then;
  SetStrP(@FNm[N],'');
  FMode[N]:=#0;
 End;
End;

Procedure CloseAll;
Var
 N:Integer;
Begin
 For N:=1 to MaxFile do CloseFile(N);
End;

Procedure DoOpen;
Var
 M:Char;
 N,E,K,RL:Integer;
 W:TKey;
Begin
 EvalS;
 K:=SSP;
 PushS(VS);
 M:=' ';
 N:=0;
 RL:=128;
 If AcceptTok(kFOR)Then Begin
  If AcceptTok(kINPUT)Then M:='I'
   Else
  Begin
   W:=ReadWord;
   If W='OUTPUT'Then M:='O' Else
   If W='APPEND'Then M:='A' Else
   If W='RANDOM'Then M:='R'
                Else SynErr;
  End;
  If ReadWord<>'AS'Then SynErr;
  Accept('#');
  N:=EvalI;
  If AcceptTok(kLEN)Then Begin
   Expect('=');
   RL:=EvalI;
  End;
 End
  Else
 If ErrCode=0 Then Begin
  M:=' ';
  If VS<>''Then M:=UpCase(VS[1]);
  Expect(',');
  Accept('#');
  N:=EvalI;
  Expect(',');
  EvalS;
  If ErrCode=0 Then SS[K+1]:=VS;
  If Accept(',')Then RL:=EvalI;
 End;
 If ErrCode<>0 Then Exit;
 If(N<1)or(N>MaxFile)Then Err(52) Else
 If FMode[N]<>#0 Then Err(55) Else
 If(RL<1)or(RL>32767)Then Err(5) Else
 If Not(M in['I','O','A','R'])Then Err(54);
 If ErrCode<>0 Then Exit;
 Assign(FT[N],SS[K+1]);
 Assign(FR[N],SS[K+1]);
 {$I-}
 Case M of
  'I':Reset(FT[N]);
  'O':Rewrite(FT[N]);
  'R':Begin
   Reset(FR[N],1);
   If IoResult<>0 Then Rewrite(FR[N],1);
  End;
  Else Begin
   Append(FT[N]);
   If IoResult<>0 Then Rewrite(FT[N]);
  End;
 End;
 {$I+}
 E:=IoResult;
 If E<>0 Then Err(IOErr(E))
  Else
 Begin
  FMode[N]:=M;
  FCol[N]:=0;
  FCnt[N]:=0;
  FLook[N]:=-1;
  SetStrP(@FNm[N],SS[K+1]);
  If M='R'Then Begin
   FBuf[N]:=Alloc(RL);
   If FBuf[N]=NIL Then Begin
    {$I-}Close(FR[N]);{$I+}
    If IoResult<>0 Then;
    FMode[N]:=#0;
    Exit;
   End;
   FillChar(FBuf[N]^,RL,0);
   FLen[N]:=RL;
   FRec[N]:=0;
   FREof[N]:=False;
  End;
 End;
 SSP:=K;
End;

Procedure DoClose;
Var
 N:Integer;
Begin
 If(EndOfStmt)Then CloseAll
  Else
 Repeat
  Accept('#');
  N:=EvalI;
  If ErrCode<>0 Then Exit;
  If(N<1)or(N>MaxFile)Then Err(52)
                      Else CloseFile(N);
 Until Not Accept(',');
End;

 { Fichiers Ö accäs direct : FIELD, GET, PUT, LSET et RSET }
Procedure SyncFields(N:Integer);
Var
 P:PField;
 S:String;
Begin
 P:=FieldList;
 While P<>NIL do Begin
  If P^.F=N Then Begin
   S[0]:=Chr(P^.Len);
   Move(FBuf[N]^[P^.Ofs],S[1],P^.Len);
   SetStrP(P^.P,S);
  End;
  P:=P^.Next;
 End;
End;

Procedure DoField;
Var
 N,W,O:Integer;
 R:TRef;
 P:PField;
Begin
 Accept('#');
 N:=CheckFile(EvalI,'R');
 O:=0;
 While(ErrCode=0)and Accept(',')do Begin
  W:=EvalB;
  If ReadWord<>'AS'Then SynErr;
  GetVarRef(R);
  If ErrCode<>0 Then Exit;
  If R.T<>'$'Then Err(13) Else
  If O+W>FLen[N]Then Err(50)
   Else
  Begin
   DropFields(0,R.P);
   P:=Alloc(SizeOf(TField));
   If P=NIL Then Exit;
   P^.F:=N;
   P^.Ofs:=O;
   P^.Len:=W;
   P^.P:=R.P;
   P^.Next:=FieldList;
   FieldList:=P;
   Inc(O,W);
  End;
 End;
 If ErrCode=0 Then SyncFields(N);
End;

Procedure DoFileGetPut(IsPut:Boolean);
Var
 N,E:Integer;
 Rec:Double;
 Got:Word;
Begin
 Accept('#');
 N:=CheckFile(EvalI,'R');
 If ErrCode<>0 Then Exit;
 Rec:=FRec[N]+1;
 If Accept(',')Then Rec:=Int(EvalN);
 If ErrCode<>0 Then Exit;
 If(Rec<1)or(Rec>16777215.0)Then Begin
  Err(63);
  Exit;
 End;
 {$I-}
 Seek(FR[N],(Trunc(Rec)-1)*LongInt(FLen[N]));
 If(IsPut)Then BlockWrite(FR[N],FBuf[N]^,FLen[N])
  Else
 Begin
  FillChar(FBuf[N]^,FLen[N],0);
  Got:=0;
  If FilePos(FR[N])<FileSize(FR[N])Then BlockRead(FR[N],FBuf[N]^,FLen[N],Got);
  FREof[N]:=Got<FLen[N];
  SyncFields(N);
 End;
 {$I+}
 E:=IoResult;
 If E<>0 Then Err(IOErr(E));
 FRec[N]:=Trunc(Rec);
End;

Procedure DoLRSet(IsR:Boolean);
Var
 R:TRef;
 P:PField;
 L:Integer;
 S:String;
Begin
 GetVarRef(R);
 If(ErrCode=0)and(R.T<>'$')Then Err(13);
 Expect('=');
 If ErrCode=0 Then EvalS;
 If ErrCode<>0 Then Exit;
 P:=FieldList;
 While(P<>NIL)and(P^.P<>R.P)do P:=P^.Next;
 If P<>NIL Then L:=P^.Len Else
 If PStrPtr(R.P)^=NIL Then L:=0
                      Else L:=Length(PStrPtr(R.P)^^);
 If Length(VS)>L Then VS[0]:=Chr(L);
 If(IsR)Then S:=Rep(' ',L-Length(VS))+VS
        Else S:=VS+Rep(' ',L-Length(VS));
 If P<>NIL Then Move(S[1],FBuf[P^.F]^[P^.Ofs],L);
 SetStrP(R.P,S);
End;

 { RÇfÇrence Ö un tableau (nom seul ou ÇlÇment de dÇpart) }
Procedure ArrRef(Var A:PArr;Var O:Word);
Var
 K:TKey;
 P:Integer;
 R:TRef;
Begin
 O:=0;
 A:=NIL;
 SkipSp;
 P:=CurrPos;
 If Not(Cur in['A'..'Z'])Then Begin
  SynErr;
  Exit;
 End;
 ReadName(K);
 If Cur in['(','[']Then Begin
  CurrPos:=P;
  GetVarRef(R);
  If ErrCode<>0 Then Exit;
  A:=FindArr(K);
  {$IFDEF FPC}
   O:=PtrUInt(R.P)-PtrUInt(A^.Data);
  {$ELSE}
   O:=Ofs(R.P^)-Ofs(A^.Data^);
  {$ENDIF}
 End
  Else
 A:=FindArr(K);
 If A=NIL Then Err(5);
End;

 { BSAVE "fichier",dÇplacement,longueur et BLOAD "fichier"[,dÇplacement] }
Procedure DoBSaveLoad(IsLoad:Boolean);
Var
 F:File;
 H:Array[0..6]of Byte;
 Buf:Array[0..255]of Byte;
 K,E,I:Integer;
 S,O,L,N,R:Word;
 HasO:Boolean;
Begin
 EvalS;
 K:=SSP;
 PushS(VS);
 S:=DefSeg;
 O:=0;
 L:=0;
 HasO:=Accept(',');
 If(HasO)Then O:=Word(RoundI(EvalN));
 If Not(IsLoad)Then Begin
  Expect(',');
  L:=Word(RoundI(EvalN));
 End;
 If ErrCode<>0 Then Exit;
 Assign(F,SS[K+1]);
 {$I-}
 If(IsLoad)Then Begin
  Reset(F,1);
  E:=IoResult;
  If E=0 Then Begin
   BlockRead(F,H,7,R);
   If(R<7)or(H[0]<>$FD)Then E:=-1
    Else
   Begin
    If Not(HasO)Then Begin
     S:=H[1]+H[2]*256;
     O:=H[3]+H[4]*256;
    End;
    L:=H[5]+H[6]*256;
    While L>0 do Begin
     N:=SizeOf(Buf);
     If N>L Then N:=L;
     BlockRead(F,Buf,N,R);
     If R=0 Then L:=0;
     For I:=0 to Integer(R)-1 do PokeB(S,O+I,Buf[I]);
     Inc(O,R);
     Dec(L,R);
    End;
   End;
   Close(F);
  End;
 End
  Else
 Begin
  Rewrite(F,1);
  E:=IoResult;
  If E=0 Then Begin
   H[0]:=$FD;
   H[1]:=Lo(S);
   H[2]:=Hi(S);
   H[3]:=Lo(O);
   H[4]:=Hi(O);
   H[5]:=Lo(L);
   H[6]:=Hi(L);
   BlockWrite(F,H,7);
   While L>0 do Begin
    N:=SizeOf(Buf);
    If N>L Then N:=L;
    For I:=0 to N-1 do Buf[I]:=PeekB(S,O+I);
    BlockWrite(F,Buf,N);
    Inc(O,N);
    Dec(L,N);
   End;
   Close(F);
  End;
 End;
 {$I+}
 If IoResult<>0 Then;
 If E<0 Then Err(54) Else
 If E>0 Then Err(IOErr(E));
 SSP:=K;
End;

 { CALL et CALLS : appel d'une routine en langage machine (DEF SEG:adresse).
   CALL passe le dÇplacement de chaque variable, CALLS son adresse longue. }
Procedure DoCall(IsS:Boolean);
Var
 K:TKey;
 V:PVar;
 R:TRef;
 N:Integer;
 A:Array[1..MaxParm]of Pointer;
 P:Pointer;
 SaveDS:Word;
Begin
 If Not(NextCh in['A'..'Z'])Then Begin
  SynErr;
  Exit;
 End;
 ReadName(K);
 V:=FindVar(K);
 VN:=0;
 If V<>NIL Then Begin
  R.T:=K[Length(K)];
  R.P:=@V^.Value;
  LoadRef(R);
  If VT='$'Then Err(13);
 End;
 P:=NIL;
 {$IFNDEF FPC}
  P:=Ptr(DefSeg,Word(RoundI(VN)));
 {$ENDIF}
 N:=0;
 If Accept('(')Then Begin
  Repeat
   If N>=MaxParm Then SynErr;
   GetVarRef(R);
   If ErrCode<>0 Then Exit;
   Inc(N);
   A[N]:=R.P;
  Until Not Accept(',');
  Expect(')');
 End;
 If ErrCode<>0 Then Exit;
 {$IFDEF FPC}
  Err(5);
 {$ELSE}
  SaveDS:=DSeg;
  Asm
   mov cx,N
   lea si,A
   jcxz @go
  @lp:
   cmp byte ptr IsS,0
   je @near
   push word ptr ss:[si+2]
  @near:
   push word ptr ss:[si]
   add si,4
   loop @lp
  @go:
   call dword ptr P
   mov ds,SaveDS
  End;
 {$ENDIF}
End;

Procedure SetPal(A,C:Integer);
{$IFNDEF FPC}
 Var
  Regs:Registers;
{$ENDIF}
Begin
 If(InGraph)Then SetPalette(GColor(A),C)
 {$IFNDEF FPC}
  Else
 Begin
  Regs.AX:=$1000;
  Regs.BL:=A;
  Regs.BH:=C;
  Intr($10,Regs);
 End;
 {$ENDIF}
End;

Procedure DoPalette;
Var
 A,C,I:Integer;
 Arr:PArr;
 O:Word;
 Pal:PaletteType;
Begin
 If(EndOfStmt)Then Begin
  If(InGraph)Then Begin
   GetDefaultPalette(Pal);
   SetAllPalette(Pal);
  End;
  Exit;
 End;
 If AcceptTok(kUSING)Then Begin
  ArrRef(Arr,O);
  If ErrCode<>0 Then Exit;
  If Arr^.Name[Length(Arr^.Name)]<>'%'Then Err(13) Else
  If O+32>Arr^.Size Then Err(5)
   Else
  For I:=0 to 15 do Begin
   C:=PInt(@Arr^.Data^[O+I*2])^;
   If(C>=0)and(C<=63)Then SetPal(I,C);
  End;
  Exit;
 End;
 A:=EvalI;
 Expect(',');
 C:=EvalI;
 If ErrCode<>0 Then Exit;
 If(A<0)or(A>15)or(C<-1)or(C>63)Then Err(5) Else
 If C>=0 Then SetPal(A,C);
End;

Procedure DoWait;
Var
 P:Word;
 A,X:Integer;
Begin
 P:=Word(RoundI(EvalN));
 Expect(',');
 A:=EvalB;
 X:=0;
 If Accept(',')Then X:=EvalB;
 {$IFNDEF FPC}
  If ErrCode=0 Then Repeat
   PollKey;
  Until((Port[P]xor X)and A<>0)or(BreakFlag);
 {$ENDIF}
End;

 { Affectations et dÇclarations }
Procedure DoLet;
Var
 R:TRef;
Begin
 GetVarRef(R);
 Expect('=');
 If ErrCode<>0 Then Exit;
 Eval;
 StoreVal(R);
End;

Procedure DoMidStmt;
Var
 R:TRef;
 N,M,I:Integer;
 S:String;
Begin
 Expect('(');
 GetVarRef(R);
 If(ErrCode=0)and(R.T<>'$')Then Err(13);
 Expect(',');
 N:=EvalB;
 M:=255;
 If Accept(',')Then M:=EvalB;
 Expect(')');
 Expect('=');
 If ErrCode<>0 Then Exit;
 EvalS;
 If ErrCode<>0 Then Exit;
 S:=VS;
 LoadRef(R);
 If(N=0)or(N>Length(VS))Then Begin
  Err(5);
  Exit;
 End;
 If M>Length(S)Then M:=Length(S);
 If M>Length(VS)-N+1 Then M:=Length(VS)-N+1;
 For I:=1 to M do VS[N+I-1]:=S[I];
 SetStrP(R.P,VS);
End;

Procedure DoDim;
Var
 K:TKey;
 D:Array[0..MaxDim-1]of Integer;
 N:Integer;
Begin
 Repeat
  If Not(NextCh in['A'..'Z'])Then Begin
   SynErr;
   Exit;
  End;
  ReadName(K);
  If Not(Accept('(')or Accept('['))Then Begin
   SynErr;
   Exit;
  End;
  N:=0;
  Repeat
   If N>=MaxDim Then Begin
    Err(9);
    Exit;
   End;
   D[N]:=EvalI;
   Inc(N);
   If ErrCode<>0 Then Exit;
  Until Not Accept(',');
  If Not(Accept(')')or Accept(']'))Then Begin
   SynErr;
   Exit;
  End;
  If FindArr(K)<>NIL Then Begin
   Err(10);
   Exit;
  End;
  If MakeArr(K,N,D)=NIL Then Exit;
 Until Not Accept(',');
End;

Procedure DoErase;
Var
 K:TKey;
 A,B:PArr;
Begin
 Repeat
  If Not(NextCh in['A'..'Z'])Then Begin
   SynErr;
   Exit;
  End;
  ReadName(K);
  If Accept('(')Then Expect(')');
  A:=ArrList;
  B:=NIL;
  While(A<>NIL)and(A^.Name<>K)do Begin
   B:=A;
   A:=A^.Next;
  End;
  If A=NIL Then Begin
   Err(5);
   Exit;
  End;
  If B=NIL Then ArrList:=A^.Next
           Else B^.Next:=A^.Next;
  FreeArr(A);
 Until Not Accept(',');
End;

Procedure DoOption;
Var
 N:Word;
Begin
 If ReadWord<>'BASE'Then Begin
  SynErr;
  Exit;
 End;
 N:=ParseLineNum;
 If N>1 Then SynErr Else
 If ArrList<>NIL Then Err(10)
                 Else OptBase:=N;
End;

Procedure DoDef;
Var
 K:TKey;
 F:PFn;
Begin
 If AcceptTok(kFN)Then Begin
  If CurrLinePtr=0 Then Begin
   Err(12);
   Exit;
  End;
  If Not(NextCh in['A'..'Z'])Then Begin
   SynErr;
   Exit;
  End;
  ReadName(K);
  F:=FnList;
  While(F<>NIL)and(F^.Name<>K)do F:=F^.Next;
  If F=NIL Then Begin
   F:=Alloc(SizeOf(TFn)-41+Length(K));
   If F=NIL Then Exit;
   F^.Name:=K;
   F^.Next:=FnList;
   FnList:=F;
  End;
  F^.LinePtr:=CurrLinePtr;
  F^.Pos:=CurrPos;
  SkipStmt;
 End
  Else
 If AcceptTok(kUSR)Then Begin
  K:='0';
  If Cur in['0'..'9']Then Begin
   K:=Cur;
   Inc(CurrPos);
  End;
  Expect('=');
  UsrAddr[Ord(K[1])-48]:=Word(RoundI(EvalN));
  If ErrCode=0 Then UsrDef:=UsrDef or(1 shl(Ord(K[1])-48));
 End
  Else
 Begin
  If ReadWord<>'SEG'Then Begin
   SynErr;
   Exit;
  End;
  {$IFDEF FPC}
   DefSeg:=0;
  {$ELSE}
   DefSeg:=DSeg;
  {$ENDIF}
  If Accept('=')Then DefSeg:=Word(RoundI(EvalN));
 End;
End;

Procedure DoDefType(T:Integer);
Var
 C,D,E,F:Char;
Begin
 Case T of
  44:C:='$';
  45:C:='%';
  46:C:='!';
  Else C:='#';
 End;
 Repeat
  D:=NextCh;
  If Not(D in['A'..'Z'])Then Begin
   SynErr;
   Exit;
  End;
  Inc(CurrPos);
  E:=D;
  If Accept('-')Then Begin
   E:=NextCh;
   If Not(E in['A'..'Z'])Then Begin
    SynErr;
    Exit;
   End;
   Inc(CurrPos);
  End;
  For F:=D to E do DefT[F]:=C;
 Until Not Accept(',');
End;

Procedure DoSwap;
Var
 A,B:TRef;
 Buf:Array[0..7]of Byte;
Begin
 GetVarRef(A);
 Expect(',');
 GetVarRef(B);
 If ErrCode<>0 Then Exit;
 If A.T<>B.T Then Begin
  Err(13);
  Exit;
 End;
 Move(A.P^,Buf,ESize(A.T));
 Move(B.P^,A.P^,ESize(A.T));
 Move(Buf,B.P^,ESize(A.T));
End;

 { Recherche du NEXT (ou WEND) correspondant, en sautant les blocs imbriquÇs }
Function ScanTo(Open,Close:Integer):Boolean;
Var
 Depth,T:Integer;
 C:Char;
Begin
 ScanTo:=False;
 Depth:=0;
 Repeat
  If CurrPos>Length(CurrLine)Then Begin
   If(CurrLinePtr=0)or(CurrLinePtr>=NumberLine)Then Exit;
   LoadLine(CurrLinePtr+1);
   CurrPos:=1;
   Continue;
  End;
  C:=CurrLine[CurrPos];
  If C='"'Then Begin
   SkipString;
   Continue;
  End;
  If C=''''Then Begin
   CurrPos:=Length(CurrLine)+1;
   Continue;
  End;
  T:=TokAt(CurrPos);
  If T>0 Then SkipTok
         Else Inc(CurrPos);
  If T=kREM Then CurrPos:=Length(CurrLine)+1 Else
  If T=kDATA Then SkipData Else
  If T=Open Then Inc(Depth) Else
  If T=Close Then Begin
   If Close=kNEXT Then Begin
    Repeat
     If NextCh in['A'..'Z']Then Begin
      While Cur in['A'..'Z','0'..'9','.']do Inc(CurrPos);
      If Cur in['%','!','#','$']Then Inc(CurrPos);
     End;
     If Depth=0 Then Begin
      ScanTo:=True;
      Exit;
     End;
     Dec(Depth);
    Until Not Accept(',');
   End
    Else
   Begin
    If Depth=0 Then Begin
     ScanTo:=True;
     Exit;
    End;
    Dec(Depth);
   End;
  End;
 Until False;
End;

 { Contrìle du dÇroulement }
Procedure DoNext;
Var
 R:TRef;
 I:Integer;
Begin
 Repeat
  If ForSP=0 Then Begin
   Err(1);
   Exit;
  End;
  I:=ForSP;
  If Not(EndOfStmt)Then Begin
   GetVarRef(R);
   If ErrCode<>0 Then Exit;
   While(I>0)and(ForStk[I].P<>R.P)do Dec(I);
   If I=0 Then Begin
    Err(1);
    Exit;
   End;
  End;
  ForSP:=I;
  With ForStk[I]do Begin
   R.P:=P;
   R.T:=T;
   LoadRef(R);
   StoreNum(R,VN+Stp);
   If ErrCode<>0 Then Exit;
   LoadRef(R);
   If((Stp>=0)and(VN<=Lim))or((Stp<0)and(VN>=Lim))Then Begin
    LoadLine(LP);
    CurrPos:=Pos;
    Exit;
   End;
  End;
  Dec(ForSP);
 Until Not Accept(',');
End;

Procedure DoFor;
Var
 R:TRef;
 X,L,S:Double;
 I:Integer;
Begin
 GetVarRef(R);
 If(ErrCode=0)and(R.T='$')Then Err(13);
 Expect('=');
 X:=EvalN;
 ExpectTok(kTO);
 L:=EvalN;
 S:=1;
 If AcceptTok(kSTEP)Then S:=EvalN;
 If(ErrCode=0)and Not(EndOfStmt)Then SynErr;
 If ErrCode<>0 Then Exit;
 Case R.T of
  '%':Begin
   L:=CInt(L);
   S:=CInt(S);
  End;
  '!':Begin
   L:=Sng(L);
   S:=Sng(S);
  End;
 End;
 StoreNum(R,X);
 If ErrCode<>0 Then Exit;
 For I:=ForSP downto 1 do If ForStk[I].P=R.P Then Begin
  ForSP:=I-1;
  Break;
 End;
 If ForSP>=MaxFor Then Begin
  Err(7);
  Exit;
 End;
 Inc(ForSP);
 With ForStk[ForSP]do Begin
  P:=R.P;
  T:=R.T;
  Lim:=L;
  Stp:=S;
  LP:=CurrLinePtr;
  Pos:=CurrPos;
 End;
 LoadRef(R);
 If((S>=0)and(VN>L))or((S<0)and(VN<L))Then Begin
  Dec(ForSP);
  If Not ScanTo(kFOR,kNEXT)Then Err(26) Else
  If Accept(',')Then DoNext;
 End;
End;

Procedure DoWhile;
Var
 P:Integer;
 Top:Boolean;
Begin
 P:=StmtPos;
 Eval;
 NeedNum;
 If ErrCode<>0 Then Exit;
 Top:=(WhileSP>0)and(WhileStk[WhileSP].LP=CurrLinePtr)and(WhileStk[WhileSP].Pos=P);
 If VN<>0 Then Begin
  If Not(Top)Then Begin
   If WhileSP>=MaxWhile Then Begin
    Err(7);
    Exit;
   End;
   Inc(WhileSP);
   WhileStk[WhileSP].LP:=CurrLinePtr;
   WhileStk[WhileSP].Pos:=P;
  End;
 End
  Else
 Begin
  If(Top)Then Dec(WhileSP);
  If Not ScanTo(kWHILE,kWEND)Then Err(29);
 End;
End;

Procedure DoWend;Begin
 If WhileSP=0 Then Err(30)
  Else
 Begin
  LoadLine(WhileStk[WhileSP].LP);
  CurrPos:=WhileStk[WhileSP].Pos;
  Jumped:=True;
 End;
End;

Procedure PushGosub(N:Word);Begin
 If ErrCode<>0 Then Exit;
 If GosubSP>=MaxGosub Then Begin
  Err(7);
  Exit;
 End;
 Inc(GosubSP);
 With GosubStk[GosubSP]do Begin
  LP:=CurrLinePtr;
  Pos:=CurrPos;
  FSP:=ForSP;
  WSP:=WhileSP;
  Jmp:=False;
  Ev:=0;
 End;
 JumpTo(N);
 If ErrCode<>0 Then Dec(GosubSP);
End;

Procedure DoReturn;Begin
 If GosubSP=0 Then Begin
  Err(3);
  Exit;
 End;
 With GosubStk[GosubSP]do Begin
  ForSP:=FSP;
  WhileSP:=WSP;
  Dec(GosubSP);
  If(Ev>0)and(EvSt[Ev]=2)Then EvSt[Ev]:=1;
  If(IsDigit)Then JumpTo(ParseLineNum)
   Else
  Begin
   LoadLine(LP);
   CurrPos:=Pos;
   Jumped:=Jmp;
  End;
 End;
End;


 { Interception des ÇvÇnements : KEY(n), TIMER, COM(n), PEN, PLAY, STRIG(n) }
Function EvParse(T:Integer;IsOn:Boolean):Integer;
Var
 X:Double;
 N:Integer;
Begin
 EvParse:=0;
 X:=0;
 If(T<>kPEN)and(IsOn or Not(T in[kTIMER,kPLAY]))Then Begin
  Expect('(');
  X:=EvalN;
  Expect(')');
 End;
 If ErrCode<>0 Then Exit;
 N:=RoundI(X);
 Case T of
  kKEY:If(N<1)or(N>20)Then Err(5)
                      Else EvParse:=N;
  kTIMER:Begin
   If(IsOn)Then Begin
    If(X<=0)or(X>86400)Then Err(5);
    TimerInt:=X;
   End;
   EvParse:=21;
  End;
  kCOM:If(N<1)or(N>2)Then Err(5)
                     Else EvParse:=21+N;
  kPEN:EvParse:=24;
  kPLAY:EvParse:=25;
  Else If(N<0)or(N>6)or Odd(N)Then Err(5)
                              Else EvParse:=26+N div 2;
 End;
End;

Procedure DoEvSet(I:Integer);Begin
 If ErrCode<>0 Then Exit;
 If AcceptTok(kON)Then Begin
  EvSt[I]:=1;
  If I=21 Then TimerRef:=Secs;
 End
  Else
 If AcceptTok(kOFF)Then Begin
  EvSt[I]:=0;
  EvPend[I]:=False;
 End
  Else
 If AcceptTok(kSTOP)Then EvSt[I]:=2
                    Else SynErr;
End;

 { DÇclenche un ÇvÇnement en attente : GOSUB implicite }
Procedure FireEvent;
Var
 I,J:Integer;
 S:Double;
Begin
 If EvSt[21]=1 Then Begin
  S:=Secs-TimerRef;
  If S<0 Then S:=S+86400;
  If S>=TimerInt Then Begin
   EvPend[21]:=True;
   TimerRef:=Secs;
  End;
 End;
 For I:=1 to 29 do If(EvPend[I])and(EvSt[I]=1)and(EvLine[I]<>0)Then Begin
  EvPend[I]:=False;
  If(GosubSP<MaxGosub)and FindLine(EvLine[I],J)Then Begin
   Inc(GosubSP);
   With GosubStk[GosubSP]do Begin
    LP:=CurrLinePtr;
    Pos:=CurrPos;
    FSP:=ForSP;
    WSP:=WhileSP;
    Jmp:=True;
    Ev:=I;
   End;
   EvSt[I]:=2;
   GotoIdx(J);
  End;
  Exit;
 End;
End;

Procedure DoOn;
Var
 N,K,T:Integer;
 L,Target:Word;
 IsSub:Boolean;
Begin
 T:=PeekTok;
 If T in[kKEY,kTIMER,kCOM,kPEN,kPLAY,kSTRIG]Then Begin
  SkipTok;
  N:=EvParse(T,True);
  ExpectTok(kGOSUB);
  L:=ParseLineNum;
  If ErrCode<>0 Then Exit;
  If(L<>0)and Not FindLine(L,K)Then Err(8)
                               Else EvLine[N]:=L;
  Exit;
 End;
 If AcceptTok(kERROR)Then Begin
  ExpectTok(kGOTO);
  L:=ParseLineNum;
  If ErrCode<>0 Then Exit;
  If L=0 Then Begin
   OnErrLine:=0;
   If(InHandler)Then Begin
    ForceLine:=ErrLin;
    Err(ErrNum);
   End;
  End
   Else
  If FindLine(L,K)Then OnErrLine:=L
                  Else Err(8);
  Exit;
 End;
 N:=EvalI;
 If ErrCode<>0 Then Exit;
 If(N<0)or(N>255)Then Begin
  Err(5);
  Exit;
 End;
 IsSub:=False;
 If AcceptTok(kGOSUB)Then IsSub:=True Else
 If Not AcceptTok(kGOTO)Then Begin
  SynErr;
  Exit;
 End;
 K:=0;
 Target:=0;
 Repeat
  Inc(K);
  L:=ParseLineNum;
  If K=N Then Target:=L;
 Until(ErrCode<>0)or Not Accept(',');
 If(ErrCode<>0)or(N=0)or(N>K)Then Exit;
 If(IsSub)Then PushGosub(Target)
          Else JumpTo(Target);
End;

Procedure DoIf;
Var
 Depth,T:Integer;
 Cond,IsGoto:Boolean;
 C:Char;
Begin
 Eval;
 If ErrCode<>0 Then Exit;
 If VT='$'Then Begin
  Err(13);
  Exit;
 End;
 Cond:=VN<>0;
 Accept(',');
 IsGoto:=AcceptTok(kGOTO);
 If Not(IsGoto)and Not AcceptTok(kTHEN)Then Begin
  SynErr;
  Exit;
 End;
 If Not(Cond)Then Begin
   { Recherche du ELSE correspondant en tenant compte des IF imbriquÇs }
  IsGoto:=False;
  Depth:=0;
  Repeat
   If CurrPos>Length(CurrLine)Then Exit;
   C:=CurrLine[CurrPos];
   If C='"'Then SkipString Else
   If C=''''Then CurrPos:=Length(CurrLine)+1
    Else
   Begin
    T:=TokAt(CurrPos);
    If T>0 Then SkipTok
           Else Inc(CurrPos);
    If T=kREM Then CurrPos:=Length(CurrLine)+1 Else
    If T=kDATA Then SkipData Else
    If T=kIF Then Inc(Depth) Else
    If T=kELSE Then Begin
     If Depth=0 Then Break;
     Dec(Depth);
    End;
   End;
  Until False;
 End;
 If(IsDigit)Then JumpTo(ParseLineNum) Else
 If(IsGoto)Then SynErr
           Else Jumped:=True;
End;

 { Programme : effacement, chargement, sauvegarde }
Procedure FreeLines;Begin
 While NumberLine>0 do RemoveLine(NumberLine);
End;

Procedure ResetRun;Begin
 ForSP:=0;
 GosubSP:=0;
 WhileSP:=0;
 DataPtr:=1;
 DataPos:=1;
 DataIn:=False;
End;

Procedure ClearAll;
Var
 C:Char;
Begin
 ClearVars;
 For C:='A'to'Z'do DefT[C]:='!';
 OptBase:=0;
 ResetRun;
 RndX:=$4FC752;
 OnErrLine:=0;
 InHandler:=False;
 ContOk:=False;
 CloseAll;
 FillChar(EvSt,SizeOf(EvSt),0);
 FillChar(EvPend,SizeOf(EvPend),0);
 FillChar(EvLine,SizeOf(EvLine),0);
 CommonStr:=',';
End;

Procedure AddExt(Var S:String);
Var
 I:Integer;
Begin
 I:=Length(S);
 While(I>0)and Not(S[I]in['.','\','/',':'])do Dec(I);
 If(I=0)or(S[I]<>'.')Then S:=S+'.BAS';
End;

Procedure LoadBinary(Var F:File);
Var
 S:String;
 N,W:Word;
 B,B2,Pend:Integer;
 Buf:String[8];
 Lit,InQ,DataM,Eof0:Boolean;
 X:Double;

 Function RB:Integer;
 Var
  Y:Byte;
  R:Word;
 Begin
  If Pend>=0 Then Begin
   RB:=Pend;
   Pend:=-1;
   Exit;
  End;
  Y:=0;
  BlockRead(F,Y,1,R);
  If R=0 Then Eof0:=True;
  RB:=Y;
 End;

 Function RW:Word;
 Var
  W:Word;
 Begin
  W:=RB;
  RW:=W+RB*256;
 End;

 Procedure Num(T:Char;K:Integer);
 Var
  I:Integer;
 Begin
  Buf[0]:=Chr(K);
  For I:=1 to K do Buf[I]:=Chr(RB);
  If K=4 Then X:=MBFToNum(Buf,3)
         Else X:=MBFToNum(Buf,7);
  Buf:=NumToStr(X,T);
  Delete(Buf,1,Ord(Buf[1]=' '));
  If(T='#')and(Pos('D',Buf)=0)and(Length(Buf)<=8)Then Buf:=Buf+'#' Else
  If(T='!')and(Pos('.',Buf)=0)and(Pos('E',Buf)=0)and(Abs(X)<=32767)Then Buf:=Buf+'!';
  S:=S+Buf;
 End;

Begin
 Pend:=-1;
 Eof0:=False;
 Repeat
  If RW=0 Then Break;
  N:=RW;
  S:='';
  Lit:=False;
  InQ:=False;
  DataM:=False;
  Repeat
   B:=RB;
   If(B=0)or(Eof0)Then Break;
   If(Lit)or(InQ)and(B<>$22)Then S:=S+Chr(B) Else
   If B=$22 Then Begin
    InQ:=Not InQ;
    S:=S+'"';
   End
    Else
   If(DataM)Then Begin
    S:=S+Chr(B);
    If B=$3A Then DataM:=False;
   End
    Else
   Case B of
    $0B:S:=S+'&O'+NumBase(RW,8);
    $0C:S:=S+'&H'+NumBase(RW,16);
    $0D,$0E:S:=S+IntToStr(RW);
    $0F:S:=S+IntToStr(RB);
    $11..$1B:S:=S+IntToStr(B-$11);
    $1C:S:=S+IntToStr(Integer(RW));
    $1D:Num('!',4);
    $1F:Num('#',8);
    $3A:Begin
     B2:=RB;
     If B2=$A1 Then S:=S+TokStr(kELSE) Else
     If B2=$8F Then Pend:=B2
      Else
     Begin
      S:=S+':';
      Pend:=B2;
     End;
    End;
    $8F:Begin
     B2:=RB;
     If B2=$D9 Then S:=S+''''
      Else
     Begin
      S:=S+TokStr(kREM);
      Pend:=B2;
     End;
     Lit:=True;
    End;
    $84:Begin
     S:=S+TokStr(kDATA);
     DataM:=True;
    End;
    $E6..$ED:S:=S+Copy('>=<+-*/^',B-$E5,1);
    $F4:S:=S+'\';
    $D9:S:=S+'''';
    $FD,$FE,$FF:Begin
     B2:=RB-$81;
     Case B of
      $FD:B2:=B2+205;
      $FE:B2:=B2+165;
      Else B2:=B2+128;
     End;
     If(B2>=128)and(B2<=NK)Then S:=S+TokStr(B2);
    End;
    Else S:=S+Chr(B);
   End;
  Until False;
  StoreLine(N,S);
 Until(Eof0)or(ErrCode<>0);
End;

Procedure LoadProgram(Name:String;Merge:Boolean);
Var
 F:File;
 T:Text;
 B:Byte;
 R:Word;
 S:String;
 N:LongInt;
 P,E:Integer;
 C:Char;
Begin
 AddExt(Name);
 Assign(F,Name);
 {$I-}Reset(F,1);{$I+}
 E:=IoResult;
 If E<>0 Then Begin
  Err(IOErr(E));
  Exit;
 End;
 B:=0;
 BlockRead(F,B,1,R);
 If Not(Merge)Then FreeLines;
 If B=$FF Then Begin
  If(Merge)Then Err(54)
           Else LoadBinary(F);
  Close(F);
 End
  Else
 Begin
  Close(F);
  If B=$FE Then Begin
   Err(54);
   Exit;
  End;
  Assign(T,Name);
  Reset(T);
  S:='';
  While ErrCode=0 do Begin
   If Eof(T)Then C:=#26
            Else Read(T,C);
   If C in[#10,#13,#26]Then Begin
    S:=LTrim(S);
    If S<>''Then Begin
     If Not(S[1]in['0'..'9'])Then Err(66)
      Else
     Begin
      P:=1;
      N:=0;
      While(P<=Length(S))and(S[P]in['0'..'9'])do Begin
       If N<100000 Then N:=N*10+Ord(S[P])-48;
       Inc(P);
      End;
      If N>65529 Then SynErr
                 Else StoreLine(N,Crunch(LTrim(Copy(S,P,255))));
     End;
    End;
    S:='';
    If C=#26 Then Break;
   End
    Else
   If Length(S)<255 Then S:=S+C;
  End;
  Close(T);
 End;
 FileName:=Name;
End;

Procedure DoSave;
Var
 T:Text;
 I,E:Integer;
 Name:String;
Begin
 Name:=FileName;
 If Not(EndOfStmt)and(NextCh<>',')Then Begin
  EvalS;
  Name:=VS;
 End;
 If Accept(',')Then ReadWord;
 If ErrCode<>0 Then Exit;
 If Name=''Then Begin
  Err(64);
  Exit;
 End;
 AddExt(Name);
 Assign(T,Name);
 {$I-}Rewrite(T);{$I+}
 E:=IoResult;
 If E<>0 Then Begin
  Err(IOErr(E));
  Exit;
 End;
 For I:=1 to NumberLine do WriteLn(T,PA[I]^.Num,' ',Detok(PA[I]^.Text));
 Close(T);
 FileName:=Name;
End;

Procedure ParseRange(Var A,B:Word);Begin
 A:=0;
 B:=65535;
 If(IsDigit)Then Begin
  A:=ParseLineNum;
  B:=A;
  If Accept('-')Then Begin
   B:=65535;
   If(IsDigit)Then B:=ParseLineNum;
  End;
 End
  Else
 If Accept('-')Then B:=ParseLineNum;
End;

Procedure DoList(Dev:Integer);
Var
 A,B:Word;
 I:Integer;
Begin
 ParseRange(A,B);
 If ErrCode<>0 Then Exit;
 OutF:=Dev;
 For I:=1 to NumberLine do With PA[I]^do If(Num>=A)and(Num<=B)Then Begin
  OutS(IntToStr(Num)+' ');
  OutS(Detok(Text));
  OutLn;
  If Dev=0 Then Begin
   PollKey;
   If(BreakFlag)Then Begin
    BreakFlag:=False;
    Break;
   End;
  End;
 End;
 OutF:=0;
 StopExec:=True;
End;

Procedure DoDelete;
Var
 A,B:Word;
 I,C:Integer;
Begin
 ParseRange(A,B);
 If ErrCode<>0 Then Exit;
 C:=0;
 I:=1;
 While I<=NumberLine do If(PA[I]^.Num>=A)and(PA[I]^.Num<=B)Then Begin
  RemoveLine(I);
  Inc(C);
 End
  Else
 Inc(I);
 If C=0 Then Err(5);
 ClearAll;
 StopExec:=True;
End;

Procedure DoRenum;
Var
 NewS,OldS,Step:Word;
 I,I0,J,P,Q,T:Integer;
 N:LongInt;
 S,U:String;
 L:PLine;
Begin
 NewS:=10;
 OldS:=0;
 Step:=10;
 If(IsDigit)Then NewS:=ParseLineNum;
 If Accept(',')Then Begin
  If(IsDigit)Then OldS:=ParseLineNum;
  If Accept(',')Then Step:=ParseLineNum;
 End;
 If ErrCode<>0 Then Exit;
 FindLine(OldS,I0);
 If(Step=0)or((I0>1)and(I0<=NumberLine)and(PA[I0-1]^.Num>=NewS))or
   (NewS+LongInt(NumberLine-I0)*Step>65529)Then Begin
  Err(5);
  Exit;
 End;
 For I:=1 to NumberLine do Begin
  S:=PA[I]^.Text;
  P:=1;
  While P<=Length(S)do Begin
   If S[P]='"'Then Begin
    Repeat
     Inc(P);
    Until(P>Length(S))or(S[P]='"');
    Inc(P);
   End
    Else
   If(S[P]='''')or(S[P]=Chr($80+kREM))or(S[P]=Chr($80+kDATA))Then P:=256
    Else
   Begin
    If S[P]=#$FF Then Begin
     T:=Ord(S[P+1]);
     Inc(P,2);
    End
     Else
    Begin
     T:=Ord(S[P])-$80;
     Inc(P);
    End;
    If T in[kGOTO,kGOSUB,kTHEN,kELSE,kRESTORE,kRESUME,kRUN]Then Repeat
     While(P<=Length(S))and(S[P]=' ')do Inc(P);
     If(P>Length(S))or Not(S[P]in['0'..'9'])Then Break;
     Q:=P;
     N:=0;
     While(P<=Length(S))and(S[P]in['0'..'9'])do Begin
      If N<100000 Then N:=N*10+Ord(S[P])-48;
      Inc(P);
     End;
     If(N<=65529)and FindLine(N,J)Then Begin
      If J>=I0 Then Begin
       U:=IntToStr(NewS+LongInt(J-I0)*Step);
       Delete(S,Q,P-Q);
       Insert(U,S,Q);
       P:=Q+Length(U);
      End;
     End
      Else
     ScreenMsg('Ligne '+IntToStr(N)+' indÇfinie'+MsgAtLine+IntToStr(PA[I]^.Num));
     While(P<=Length(S))and(S[P]=' ')do Inc(P);
     If(P>Length(S))or(S[P]<>',')Then Break;
     Inc(P);
    Until False;
   End;
  End;
  If S<>PA[I]^.Text Then Begin
   L:=Alloc(SizeOf(TLine)-255+Length(S));
   If L=NIL Then Exit;
   L^.Num:=PA[I]^.Num;
   L^.Text:=S;
   FreeMem(PA[I],LineSize(PA[I]));
   PA[I]:=L;
  End;
 End;
 For I:=I0 to NumberLine do PA[I]^.Num:=NewS+LongInt(I-I0)*Step;
 ClearAll;
 StopExec:=True;
End;

 { Commandes du systäme de fichiers }
Procedure DoFiles;
Var
 Info:SearchRec;
 Dir,N:String;
 I:Integer;
Begin
 Dir:='*.*';
 If Not(EndOfStmt)Then Begin
  EvalS;
  If ErrCode<>0 Then Exit;
  Dir:=VS;
 End;
 FindFirst(Dir,AnyFile,Info);
 If DosError<>0 Then Begin
  Err(53);
  Exit;
 End;
 GetDir(0,Dir);
 OutF:=0;
 OutS(Dir);
 OutLn;
 While DosError=0 do Begin
  N:=Info.Name;
  I:=Pos('.',N);
  If(I>1)and(I<=9)and(Length(N)-I<=3)Then N:=Copy(N,1,I-1)+Rep(' ',9-I)+Copy(N,I,4) Else
  If(I=0)and(Length(N)<=8)Then N:=N+Rep(' ',8-Length(N));
  N:=N+Rep(' ',12-Length(N));
  If Info.Attr and Directory<>0 Then N:=N+'<DIR>';
  N:=N+Rep(' ',18-Length(N))+' ';
  If OutCol+Length(N)>ScrW Then OutLn;
  OutS(N);
  FindNext(Info);
 End;
 {$IFDEF FPC}FindClose(Info);{$ENDIF}
 If OutCol>0 Then OutLn;
 Str(DiskFree(0),N);
 OutS(N+MsgFree);
 OutLn;
End;

Procedure DoKill;
Var
 F:File;
 Info:SearchRec;
 D:DirStr;
 N:NameStr;
 E:ExtStr;
 R:Integer;
Begin
 EvalS;
 If ErrCode<>0 Then Exit;
 FSplit(VS,D,N,E);
 FindFirst(VS,AnyFile-Directory-VolumeID,Info);
 If DosError<>0 Then Begin
  Err(53);
  Exit;
 End;
 While DosError=0 do Begin
  Assign(F,D+Info.Name);
  {$I-}Erase(F);{$I+}
  R:=IoResult;
  If R<>0 Then Err(IOErr(R));
  FindNext(Info);
 End;
 {$IFDEF FPC}FindClose(Info);{$ENDIF}
End;

Procedure DoName;
Var
 F:File;
 K,E:Integer;
Begin
 EvalS;
 K:=SSP;
 PushS(VS);
 If ReadWord<>'AS'Then SynErr;
 EvalS;
 If ErrCode<>0 Then Exit;
 Assign(F,SS[K+1]);
 {$I-}Rename(F,VS);{$I+}
 E:=IoResult;
 If E=5 Then Err(58) Else
 If E<>0 Then Err(IOErr(E));
 SSP:=K;
End;

Procedure DoDir(T:Integer);
Var
 E:Integer;
Begin
 EvalS;
 If ErrCode<>0 Then Exit;
 {$I-}
 Case T of
  kCHDIR:ChDir(VS);
  kMKDIR:MkDir(VS);
  Else RmDir(VS);
 End;
 {$I+}
 E:=IoResult;
 If E<>0 Then Err(IOErr(E));
End;

Procedure DoShell;
Var
 C:String;
Begin
 C:='';
 If Not(EndOfStmt)Then Begin
  EvalS;
  If ErrCode<>0 Then Exit;
  C:=VS;
 End;
 SwapVectors;
 {$IFDEF UNIX}
  If C=''Then Exec('/bin/sh','')
         Else Exec('/bin/sh','-c "'+C+'"');
 {$ELSE}
  If C=''Then Exec(GetEnv('COMSPEC'),'')
         Else Exec(GetEnv('COMSPEC'),'/C '+C);
 {$ENDIF}
 SwapVectors;
 If DosError<>0 Then Err(5);
End;

Procedure DoSetDateTime(T:Integer);
Var
 N:Array[0..2]of Word;
 I,P:Integer;
 S:String;
Begin
 Expect('=');
 EvalS;
 If ErrCode<>0 Then Exit;
 S:=VS;
 P:=1;
 For I:=0 to 2 do Begin
  N[I]:=0;
  While(P<=Length(S))and(S[P]in['0'..'9'])do Begin
   N[I]:=N[I]*10+Ord(S[P])-48;
   Inc(P);
  End;
  If(P<=Length(S))and(S[P]in['-','/',':'])Then Inc(P);
 End;
 If T=kDATE Then Begin
  If N[2]<100 Then Inc(N[2],1900);
  If N[2]<1980 Then Inc(N[2],100);
  If(N[0]<1)or(N[0]>12)or(N[1]<1)or(N[1]>31)Then Err(5)
                                            Else SetDate(N[2],N[0],N[1]);
 End
  Else
 If(N[0]>23)or(N[1]>59)or(N[2]>59)Then Err(5)
                                  Else SetTime(N[0],N[1],N[2],0);
End;

Procedure DoRandomize;
Var
 S:String;
 P:Integer;
 X:Double;
 T:Char;
 Ok:Boolean;
Begin
 If(EndOfStmt)Then Begin
  Repeat
   OutF:=0;
   OutS(MsgSeed);
   S:='';
   If Not EditLine(S)Then Begin
    OutLn;
    DoBreak(StmtPos);
    Exit;
   End;
   OutLn;
   P:=1;
   Ok:=ScanNum(S,P,X,T,True);
   While(P<=Length(S))and(S[P]=' ')do Inc(P);
  Until(Ok)and(P>Length(S))and(X>=-32768)and(X<=32767);
 End
  Else
 X:=EvalN;
 If ErrCode<>0 Then Exit;
 RndX:=(RndX and $FF)or((RoundI(X)and $FFFF)shl 8);
 DoRnd(1);
End;

 { êcran et clavier }
Procedure ShowFunctionKey;
Var
 I,J,N,OldX,OldY:Byte;
 Temp:String;
Begin
 If(InGraph)Then Exit;
 OldX:=WhereX;
 OldY:=WhereY;
 Window(1,1,ScrW,25);
 GotoXY(1,25);
 ClrEol;
 If(KeyFunction)Then Begin
  N:=ScrW div 8;
  For I:=1 to N do Begin
   TextColor(7);
   TextBackground(0);
   Write(I mod 10);
   TextColor(0);
   TextBackground(7);
   Temp:='';
   For J:=1 to Length(FunctionKeyList[I])do Begin
    If FunctionKeyList[I][J]<>#13 Then Temp:=Temp+FunctionKeyList[I][J];
   End;
   Temp:=Copy(Temp,1,6);
   Write(Temp);
   TextColor(7);
   TextBackground(0);
   If I<N Then Write(Rep(' ',7-Length(Temp)));
  End;
 End;
 Window(1,VTop,ScrW,VBot);
 GotoXY(OldX,OldY);
End;

Procedure DoCls;Begin
 If Not(EndOfStmt)Then EvalI;
 If(InGraph)Then Begin
  If(ViewOn)Then ClearViewPort
            Else ClearDevice;
  GCol:=0;
  GRow:=0;
 End
  Else
 ClrScr;
 ShowFunctionKey;
End;

Procedure DoColor;
Var
 F,B:Integer;
Begin
 F:=-1;
 B:=-1;
 If Not(EndOfStmt)and(NextCh<>',')Then F:=EvalI;
 If Accept(',')Then Begin
  If Not(EndOfStmt)and(NextCh<>',')Then B:=EvalI;
  If Accept(',')Then EvalI;
 End;
 If ErrCode<>0 Then Exit;
 If(F>31)or(B>15)Then Err(5) Else
 If(InGraph)Then Begin
  If GMode=1 Then Begin
   If F>=0 Then SetBkColor(F and 15);
  End
   Else
  Begin
   If F>=0 Then GFore:=GColor(F);
   If B>=0 Then SetBkColor(B);
  End;
 End
  Else
 Begin
  If F>=0 Then Begin
   If F>15 Then TextColor((F and 15)+Blink)
           Else TextColor(F);
  End;
  If B>=0 Then TextBackground(B and 7);
 End;
End;

Procedure DoLocate;
Var
 R,C:Integer;
Begin
 R:=WhereY+VTop-1;
 C:=WhereX;
 If(InGraph)Then Begin
  R:=GRow+1;
  C:=GCol+1;
 End;
 If Not(EndOfStmt)and(NextCh<>',')Then R:=EvalI;
 If Accept(',')Then Begin
  If Not(EndOfStmt)and(NextCh<>',')Then C:=EvalI;
  While Accept(',')do If Not(EndOfStmt)and(NextCh<>',')Then EvalI;
 End;
 If ErrCode<>0 Then Exit;
 If(InGraph)Then Begin
  If(R<1)or(R>24)or(C<1)or(C>ScrW)Then Err(5)
   Else
  Begin
   GRow:=R-1;
   GCol:=C-1;
  End;
 End
  Else
 If(R<VTop)or(R>VBot)or(C<1)or(C>ScrW)Then Err(5)
                                      Else GotoXY(C,R-VTop+1);
End;

Procedure DoKey;
Var
 N:Integer;
Begin
 If NextCh='('Then DoEvSet(EvParse(kKEY,False)) Else
 If AcceptTok(kON)Then Begin
  KeyFunction:=True;
  ShowFunctionKey;
 End
  Else
 If AcceptTok(kOFF)Then Begin
  KeyFunction:=False;
  ShowFunctionKey;
 End
  Else
 If AcceptTok(kLIST)Then Begin
  For N:=1 to 10 do Begin
   VS:=FunctionKeyList[N];
   While Pos(#13,VS)>0 do Delete(VS,Pos(#13,VS),1);
   OutS('F'+IntToStr(N)+' '+VS);
   OutLn;
  End;
 End
  Else
 Begin
  N:=EvalI;
  Expect(',');
  EvalS;
  If ErrCode<>0 Then Exit;
  If(N<1)or(N>10)Then Err(5)
   Else
  Begin
   FunctionKeyList[N]:=Copy(VS,1,15);
   ShowFunctionKey;
  End;
 End;
End;

Procedure DoWidth;
Var
 N:Integer;
Begin
 If(NextCh='"')or(NextCh='#')Then Begin
  SkipStmt;
  Exit;
 End;
 N:=EvalI;
 If Accept(',')Then EvalI;
 If ErrCode<>0 Then Exit;
 If(N<>40)and(N<>80)Then Err(5)
  Else
 Begin
  If N=40 Then TextMode(C40)
          Else TextMode(C80);
  ScrW:=N;
  VTop:=1;
  VBot:=24;
  Window(1,1,ScrW,24);
  ClrScr;
  ShowFunctionKey;
 End;
End;

 { Son }
Procedure Tone(F,D:LongInt);Begin
 If F>=37 Then Sound(F);
 If D>0 Then Delay(D);
 NoSound;
End;

Procedure DoSound;
Var
 F,D:Double;
Begin
 F:=EvalN;
 Expect(',');
 D:=EvalN;
 If ErrCode<>0 Then Exit;
 If((F<37)and(F<>0))or(F>32767)or(D<0)or(D>65535)Then Err(5)
                                                 Else Tone(Trunc(F),Trunc(D*1000/18.2));
End;

Procedure PlayStr(Const S:String;Depth:Integer);
Const
 NoteOfs:Array['A'..'G']of Byte=(9,11,0,2,4,5,7);
Var
 I,N,L:Integer;
 C:Char;
 D:Double;
 R:TRef;

 Function Num(Def:Integer):Integer;
 Var
  V:Integer;
 Begin
  While(I<=Length(S))and(S[I]=' ')do Inc(I);
  If(I<=Length(S))and(S[I]='=')Then Begin
   Inc(I);
   Num:=SubNum(S,I);
  End
   Else
  If(I<=Length(S))and(S[I]in['0'..'9'])Then Begin
   V:=0;
   While(I<=Length(S))and(S[I]in['0'..'9'])do Begin
    If V<1000 Then V:=V*10+Ord(S[I])-48;
    Inc(I);
   End;
   Num:=V;
  End
   Else
  Num:=Def;
 End;

Begin
 If Depth>8 Then Err(7);
 I:=1;
 While(I<=Length(S))and(ErrCode=0)do Begin
  C:=UpCase(S[I]);
  Inc(I);
  N:=-2;
  Case C of
   'A'..'G':Begin
    N:=POct*12+NoteOfs[C];
    If(I<=Length(S))and(S[I]in['#','+','-'])Then Begin
     If S[I]='-'Then Dec(N)
                Else Inc(N);
     Inc(I);
    End;
    L:=Num(PLen);
   End;
   'N':Begin
    N:=Num(0)-1;
    L:=PLen;
   End;
   'P','R':Begin
    N:=-1;
    L:=Num(PLen);
   End;
   'O':POct:=Num(4)mod 7;
   '>':If POct<6 Then Inc(POct);
   '<':If POct>0 Then Dec(POct);
   'L':PLen:=Num(4);
   'T':PTempo:=Num(120);
   'X':If SubRef(S,I,R)and(R.T='$')and(PStrPtr(R.P)^<>NIL)Then PlayStr(PStrPtr(R.P)^^,Depth+1);
   'M':If I<=Length(S)Then Begin
    Case UpCase(S[I])of
     'N':PStyle:=7;
     'L':PStyle:=8;
     'S':PStyle:=6;
    End;
    Inc(I);
   End;
  End;
  If(PLen<1)or(PLen>64)or(PTempo<32)or(PTempo>255)Then Err(5);
  If(N>-2)and(ErrCode=0)Then Begin
   If(L<1)or(L>64)Then L:=PLen;
   D:=240000.0/(PTempo*L);
   While(I<=Length(S))and(S[I]='.')do Begin
    D:=D*1.5;
    Inc(I);
   End;
   If N<0 Then Delay(Trunc(D))
    Else
   Begin
    Tone(Trunc(440*Exp((N-57)*Ln(2)/12)+0.5),Trunc(D*PStyle/8));
    Delay(Trunc(D*(8-PStyle)/8));
   End;
  End;
 End;
End;

Procedure DoPlay;Begin
 EvalS;
 PushS(VS);
 If ErrCode=0 Then PlayStr(SS[SSP],0);
End;

 { Graphiques }
Function NeedGraph:Boolean;Begin
 NeedGraph:=InGraph;
 If Not(InGraph)Then Err(5);
End;

Procedure Pair(Var A,B:Double);Begin
 Expect('(');
 A:=EvalN;
 Expect(',');
 B:=EvalN;
 Expect(')');
End;

Procedure ParseXY(Var X,Y:Integer);
Var
 Rel:Boolean;
 A,B:Double;
Begin
 Rel:=AcceptTok(kSTEP);
 Pair(A,B);
 If(Rel)Then Begin
  A:=A+UnX(GLX);
  B:=B+UnY(GLY);
 End;
 X:=MapX(A);
 Y:=MapY(B);
End;

Function OptColor:Integer;Begin
 OptColor:=GFore;
 If Not(EndOfStmt)and(NextCh<>',')Then OptColor:=GColor(EvalI);
End;

Procedure DoScreen;
Var
 M,Driver,Mode:Integer;
Begin
 M:=0;
 If NextCh<>','Then M:=EvalI;
 While Accept(',')do If Not(EndOfStmt)and(NextCh<>',')Then EvalI;
 If ErrCode<>0 Then Exit;
 Case M of
  0:If(InGraph)Then Begin
   CloseGraph;
   InGraph:=False;
   ScrW:=80;
   VTop:=1;
   VBot:=24;
   Window(1,1,ScrW,24);
   ClrScr;
   ShowFunctionKey;
  End;
  1,2,7,8,9:Begin
   If Not(InGraph)Then Begin
    Driver:=VGA;
    Mode:=VGAHi;
    InitGraph(Driver,Mode,'');
    Mode:=GraphResult;
    If Mode<>grOk Then Begin
     ScreenMsg(GraphErrorMsg(Mode));
     Err(5);
     Exit;
    End;
    InGraph:=True;
   End;
   SetViewPort(0,0,GetMaxX,GetMaxY,ClipOn);
   ViewOn:=False;
   WinOn:=False;
   VOX:=0;
   VOY:=0;
   GMode:=M;
   GW:=640;
   GH:=200;
   If M in[1,7]Then GW:=320;
   If M=9 Then GH:=350;
   GFore:=15;
   If M=1 Then GFore:=GColor(3);
   ScrW:=GW div 8;
   GLX:=GW div 2;
   GLY:=GH div 2;
   GCol:=0;
   GRow:=0;
   ClearDevice;
  End;
  Else Err(5);
 End;
End;

Procedure DoPset(IsSet:Boolean);
Var
 X,Y,C:Integer;
Begin
 If Not(NeedGraph)Then Exit;
 ParseXY(X,Y);
 If(IsSet)Then C:=GFore
          Else C:=0;
 If Accept(',')Then C:=GColor(EvalI);
 If ErrCode<>0 Then Exit;
 SetFillStyle(SolidFill,C);
 Bar(SXp(X),SYp(Y),SXp(X+1)-1,SYp(Y+1)-1);
 GLX:=X;
 GLY:=Y;
End;

Procedure DoLine;
Var
 X1,Y1,X2,Y2,C:Integer;
 B:TKey;
Begin
 If Not(NeedGraph)Then Exit;
 X1:=GLX;
 Y1:=GLY;
 If NextCh<>'-'Then ParseXY(X1,Y1);
 Expect('-');
 GLX:=X1;
 GLY:=Y1;
 ParseXY(X2,Y2);
 C:=GFore;
 B:='';
 If Accept(',')Then Begin
  C:=OptColor;
  If Accept(',')Then B:=ReadWord;
 End;
 If ErrCode<>0 Then Exit;
 SetColor(C);
 If B='B'Then Rectangle(SXp(X1),SYp(Y1),SXp(X2),SYp(Y2)) Else
 If B='BF'Then Begin
  SetFillStyle(SolidFill,C);
  Order(X1,X2);
  Order(Y1,Y2);
  Bar(SXp(X1),SYp(Y1),SXp(X2+1)-1,SYp(Y2+1)-1);
 End
  Else
 Line(SXp(X1),SYp(Y1),SXp(X2),SYp(Y2));
 GLX:=X2;
 GLY:=Y2;
End;

Procedure DoCircle;
Var
 X,Y,C:Integer;
 R,A1,A2,Asp,RX,RY:Double;
Begin
 If Not(NeedGraph)Then Exit;
 ParseXY(X,Y);
 Expect(',');
 R:=EvalN;
 C:=GFore;
 A1:=0;
 A2:=2*Pi;
 Asp:=4/3*GH/GW;
 If Accept(',')Then Begin
  C:=OptColor;
  If Accept(',')Then Begin
   If NextCh<>','Then A1:=Abs(EvalN);
   If Accept(',')Then Begin
    If NextCh<>','Then A2:=Abs(EvalN);
    If Accept(',')Then Asp:=EvalN;
   End;
  End;
 End;
 If ErrCode<>0 Then Exit;
 If(WinOn)Then R:=R*(VWid-1)/Abs(WX2-WX1);
 If Asp<=0 Then Asp:=1;
 RX:=R;
 RY:=R*Asp;
 If Asp>1 Then Begin
  RX:=R/Asp;
  RY:=R;
 End;
 SetColor(C);
 Ellipse(SXp(X),SYp(Y),Trunc(A1*180/Pi+0.5),Trunc(A2*180/Pi+0.5),
         Trunc(RX*(GetMaxX+1)/GW),Trunc(RY*(GetMaxY+1)/GH));
 GLX:=X;
 GLY:=Y;
End;

Procedure DoPaint;
Const
 MaxSeed=1000;
Var
 X,Y,C,B,N,XL,XR,DY:Integer;
 SX,SY:Array[1..MaxSeed]of Integer;
 Run:Boolean;

 Function Free(PX,PY:Integer):Boolean;
 Var
  P:Word;
 Begin
  P:=GetPixel(PX,PY);
  Free:=(P<>B)and(P<>C);
 End;

 Procedure Push(PX,PY:Integer);Begin
  If N<MaxSeed Then Begin
   Inc(N);
   SX[N]:=PX;
   SY[N]:=PY;
  End;
 End;

Begin
 If Not(NeedGraph)Then Exit;
 ParseXY(X,Y);
 C:=GFore;
 B:=-1;
 If Accept(',')Then Begin
  C:=OptColor;
  If Accept(',')Then B:=GColor(EvalI);
 End;
 If ErrCode<>0 Then Exit;
 If B<0 Then B:=C;
 X:=SXp(X);
 Y:=SYp(Y);
 If(X<0)or(Y<0)or(X>GetMaxX)or(Y>GetMaxY)Then Exit;
 SetColor(C);
 N:=0;
 Push(X,Y);
 While N>0 do Begin
  X:=SX[N];
  Y:=SY[N];
  Dec(N);
  If Free(X,Y)Then Begin
   XL:=X;
   While(XL>0)and Free(XL-1,Y)do Dec(XL);
   XR:=X;
   While(XR<GetMaxX)and Free(XR+1,Y)do Inc(XR);
   Line(XL,Y,XR,Y);
   DY:=-1;
   Repeat
    If(Y+DY>=0)and(Y+DY<=GetMaxY)Then Begin
     Run:=False;
     For X:=XL to XR do If Free(X,Y+DY)Then Begin
      If Not(Run)Then Push(X,Y+DY);
      Run:=True;
     End
      Else
     Run:=False;
    End;
    Inc(DY,2);
   Until DY>1;
  End;
 End;
End;

Procedure DrawStr(Const S:String;Depth:Integer);
Const
 DrawScale:Integer=4;
Var
 I,N,X,Y,DX,DY:Integer;
 C:Char;
 NoDraw,NoMove:Boolean;
 R:TRef;

 Function Num(Def:Integer):Integer;
 Var
  V:Integer;
  Neg:Boolean;
 Begin
  While(I<=Length(S))and(S[I]=' ')do Inc(I);
  Neg:=False;
  If(I<=Length(S))and(S[I]in['+','-'])Then Begin
   Neg:=S[I]='-';
   Inc(I);
  End;
  If(I<=Length(S))and(S[I]='=')Then Begin
   Inc(I);
   V:=SubNum(S,I);
  End
   Else
  If(I<=Length(S))and(S[I]in['0'..'9'])Then Begin
   V:=0;
   While(I<=Length(S))and(S[I]in['0'..'9'])do Begin
    If V<10000 Then V:=V*10+Ord(S[I])-48;
    Inc(I);
   End;
  End
   Else
  V:=Def;
  If(Neg)Then V:=-V;
  Num:=V;
 End;

Begin
 If Depth>8 Then Err(7);
 I:=1;
 NoDraw:=False;
 NoMove:=False;
 While(I<=Length(S))and(ErrCode=0)do Begin
  C:=UpCase(S[I]);
  Inc(I);
  DX:=0;
  DY:=0;
  Case C of
   'U':DY:=-1;
   'D':DY:=1;
   'L':DX:=-1;
   'R':DX:=1;
   'E':Begin
    DX:=1;
    DY:=-1;
   End;
   'F':Begin
    DX:=1;
    DY:=1;
   End;
   'G':Begin
    DX:=-1;
    DY:=1;
   End;
   'H':Begin
    DX:=-1;
    DY:=-1;
   End;
   'B':NoDraw:=True;
   'N':NoMove:=True;
   'C':GFore:=GColor(Num(15));
   'S':DrawScale:=Num(4);
   'A':Num(0);
   'X':If SubRef(S,I,R)and(R.T='$')and(PStrPtr(R.P)^<>NIL)Then DrawStr(PStrPtr(R.P)^^,Depth+1);
  End;
  If C in['U','D','L','R','E','F','G','H','M']Then Begin
   If C='M'Then Begin
    While(I<=Length(S))and(S[I]=' ')do Inc(I);
    If(I<=Length(S))and(S[I]in['+','-'])Then Begin
     X:=GLX+Num(0)*DrawScale div 4;
     If(I<=Length(S))and(S[I]=',')Then Inc(I);
     Y:=GLY+Num(0)*DrawScale div 4;
    End
     Else
    Begin
     X:=Num(GLX);
     If(I<=Length(S))and(S[I]=',')Then Inc(I);
     Y:=Num(GLY);
    End;
   End
    Else
   Begin
    N:=Num(1)*DrawScale div 4;
    X:=GLX+DX*N;
    Y:=GLY+DY*N;
   End;
   If Not(NoDraw)Then Begin
    SetColor(GFore);
    Line(SXp(GLX),SYp(GLY),SXp(X),SYp(Y));
   End;
   If Not(NoMove)Then Begin
    GLX:=X;
    GLY:=Y;
   End;
   NoDraw:=False;
   NoMove:=False;
  End;
 End;
End;

Procedure DoDraw;Begin
 If Not(NeedGraph)Then Exit;
 EvalS;
 PushS(VS);
 If ErrCode=0 Then DrawStr(SS[SSP],0);
End;

Function Bpp:Integer;Begin
 Case GMode of
  1:Bpp:=2;
  2:Bpp:=1;
  Else Bpp:=4;
 End;
End;

 { GET (x1,y1)-(x2,y2),tableau et PUT (x,y),tableau[,action] graphiques,
   au format du GW-BASIC : largeur en bits, hauteur, puis les pixels. }
Procedure DoGraphGetPut(IsPut:Boolean);
Var
 X1,Y1,X2,Y2,X,Y,B,W,H,RB,C,E,Act:Integer;
 A:PArr;
 O,Q:Word;
Begin
 If Not(NeedGraph)Then Exit;
 ParseXY(X1,Y1);
 If Not(IsPut)Then Begin
  Expect('-');
  ParseXY(X2,Y2);
 End;
 Expect(',');
 ArrRef(A,O);
 Act:=kXOR;
 If(IsPut)and Accept(',')Then Begin
  Act:=PeekTok;
  If Act in[kPSET,kPRESET,kAND,kOR,kXOR]Then SkipTok
                                       Else SynErr;
 End;
 If ErrCode<>0 Then Exit;
 B:=Bpp;
 If(IsPut)Then Begin
  W:=PInt(@A^.Data^[O])^div B;
  H:=PInt(@A^.Data^[O+2])^;
  X2:=X1+W-1;
  Y2:=Y1+H-1;
 End
  Else
 Begin
  Order(X1,X2);
  Order(Y1,Y2);
  W:=X2-X1+1;
  H:=Y2-Y1+1;
 End;
 RB:=(W*B+7)div 8;
 If(W<1)or(H<1)or(4+LongInt(RB)*H>A^.Size-O)or(X1<0)or(Y1<0)or
   (X2>=GW)or(Y2>=GH)Then Begin
  Err(5);
  Exit;
 End;
 If Not(IsPut)Then Begin
  PInt(@A^.Data^[O])^:=W*B;
  PInt(@A^.Data^[O+2])^:=H;
  FillChar(A^.Data^[O+4],RB*H,0);
 End;
 For Y:=0 to H-1 do For X:=0 to W-1 do Begin
  Q:=O+4+Y*RB+(X*B)div 8;
  E:=8-B-(X*B)mod 8;
  C:=LogColor(GetPixel(SXp(X1+X),SYp(Y1+Y)));
  If(IsPut)Then Begin
   E:=(A^.Data^[Q]shr E)and(1 shl B-1);
   Case Act of
    kPSET:C:=E;
    kPRESET:C:=Not E and(1 shl B-1);
    kAND:C:=C and E;
    kOR:C:=C or E;
    Else C:=C xor E;
   End;
   SetFillStyle(SolidFill,GColor(C));
   Bar(SXp(X1+X),SYp(Y1+Y),SXp(X1+X+1)-1,SYp(Y1+Y+1)-1);
  End
   Else
  A^.Data^[Q]:=A^.Data^[Q]or((C and(1 shl B-1))shl E);
 End;
End;

 { VIEW [[SCREEN](x1,y1)-(x2,y2)[,[couleur][,bordure]]] et VIEW PRINT }
Procedure DoView;
Var
 S:Boolean;
 X1,Y1,X2,Y2,F,B:Integer;
Begin
 If AcceptTok(kPRINT)Then Begin
  X1:=1;
  Y1:=24;
  If Not(EndOfStmt)Then Begin
   X1:=EvalI;
   ExpectTok(kTO);
   Y1:=EvalI;
  End;
  If ErrCode<>0 Then Exit;
  If(X1<1)or(Y1>24)or(X1>Y1)Then Err(5)
   Else
  Begin
   VTop:=X1;
   VBot:=Y1;
   If Not(InGraph)Then Window(1,VTop,ScrW,VBot);
  End;
  Exit;
 End;
 If Not(NeedGraph)Then Exit;
 SetViewPort(0,0,GetMaxX,GetMaxY,ClipOn);
 ViewOn:=False;
 VOX:=0;
 VOY:=0;
 If(EndOfStmt)Then Exit;
 S:=AcceptTok(kSCREEN);
 Expect('(');
 X1:=EvalI;
 Expect(',');
 Y1:=EvalI;
 Expect(')');
 Expect('-');
 Expect('(');
 X2:=EvalI;
 Expect(',');
 Y2:=EvalI;
 Expect(')');
 F:=-1;
 B:=-1;
 If Accept(',')Then Begin
  If Not(EndOfStmt)and(NextCh<>',')Then F:=EvalI;
  If Accept(',')Then B:=EvalI;
 End;
 If ErrCode<>0 Then Exit;
 Order(X1,X2);
 Order(Y1,Y2);
 If(X1<0)or(Y1<0)or(X2>=GW)or(Y2>=GH)Then Begin
  Err(5);
  Exit;
 End;
 If B>=0 Then Begin
  SetColor(GColor(B));
  Rectangle(SXp(X1-1),SYp(Y1-1),SXp(X2+1),SYp(Y2+1));
 End;
 SetViewPort(SXp(X1),SYp(Y1),SXp(X2+1)-1,SYp(Y2+1)-1,ClipOn);
 If F>=0 Then Begin
  SetFillStyle(SolidFill,GColor(F));
  Bar(0,0,SXp(X2+1)-1-SXp(X1),SYp(Y2+1)-1-SYp(Y1));
 End;
 ViewOn:=True;
 VX1:=X1;
 VY1:=Y1;
 VX2:=X2;
 VY2:=Y2;
 If(S)Then Begin
  VOX:=X1;
  VOY:=Y1;
 End;
 GLX:=VOX+(X2-X1)div 2;
 GLY:=VOY+(Y2-Y1)div 2;
End;

 { WINDOW [[SCREEN](x1,y1)-(x2,y2)] }
Procedure DoWindow;
Var
 T:Double;
Begin
 If Not(NeedGraph)Then Exit;
 WinOn:=False;
 If(EndOfStmt)Then Exit;
 WinScr:=AcceptTok(kSCREEN);
 Pair(WX1,WY1);
 Expect('-');
 Pair(WX2,WY2);
 If ErrCode<>0 Then Exit;
 If(WX1=WX2)or(WY1=WY2)Then Begin
  Err(5);
  Exit;
 End;
 If WX1>WX2 Then Begin
  T:=WX1;
  WX1:=WX2;
  WX2:=T;
 End;
 If WY1>WY2 Then Begin
  T:=WY1;
  WY1:=WY2;
  WY2:=T;
 End;
 WinOn:=True;
End;

 { COMMON et CHAIN [MERGE] f$[,[ligne][,[ALL][,DELETE intervalle]]] }
Procedure DoCommon;
Var
 K:TKey;
Begin
 Repeat
  If Not(NextCh in['A'..'Z'])Then Begin
   SynErr;
   Exit;
  End;
  ReadName(K);
  If Accept('(')Then Begin
   Expect(')');
   K:=K+'()';
  End;
  If Length(CommonStr)+Length(K)<254 Then CommonStr:=CommonStr+K+',';
 Until Not Accept(',');
End;

Procedure KeepCommon;
Var
 V,PV,NV:PVar;
 A,PAr,NA:PArr;
Begin
 DropFields(0,NIL);
 V:=VarList;
 PV:=NIL;
 While V<>NIL do Begin
  NV:=V^.Next;
  If Pos(','+V^.Name+',',CommonStr)=0 Then Begin
   If PV=NIL Then VarList:=NV
             Else PV^.Next:=NV;
   If V^.Name[Length(V^.Name)]='$'Then SetStrP(@V^.Value,'');
   FreeMem(V,SizeOf(TVar)-41+Length(V^.Name));
  End
   Else
  PV:=V;
  V:=NV;
 End;
 A:=ArrList;
 PAr:=NIL;
 While A<>NIL do Begin
  NA:=A^.Next;
  If Pos(','+A^.Name+'(),',CommonStr)=0 Then Begin
   If PAr=NIL Then ArrList:=NA
              Else PAr^.Next:=NA;
   FreeArr(A);
  End
   Else
  PAr:=A;
  A:=NA;
 End;
End;

Procedure DoChain;
Var
 Mg,All,Del:Boolean;
 L,A,B:Word;
 K,I:Integer;
Begin
 Mg:=AcceptTok(kMERGE);
 EvalS;
 K:=SSP;
 PushS(VS);
 L:=0;
 I:=-1;
 All:=False;
 Del:=False;
 If Accept(',')Then Begin
  If(IsDigit)Then Begin
   L:=ParseLineNum;
   I:=0;
  End;
  If Accept(',')Then Begin
   If Not(PeekTok=kDELETE)and(NextCh<>',')Then All:=ReadWord='ALL';
   If Accept(',')or(PeekTok=kDELETE)Then Begin
    ExpectTok(kDELETE);
    ParseRange(A,B);
    Del:=True;
   End;
  End;
 End;
 If ErrCode<>0 Then Exit;
 If(Del)Then Begin
  I:=1;
  While I<=NumberLine do If(PA[I]^.Num>=A)and(PA[I]^.Num<=B)Then RemoveLine(I)
                                                         Else Inc(I);
  I:=-1;
  If L<>0 Then I:=0;
 End;
 If Not(All or Mg)Then KeepCommon;
 CommonStr:=',';
 LoadProgram(SS[K+1],Mg);
 SSP:=K;
 If ErrCode<>0 Then Exit;
 FreeFns;
 ResetRun;
 If NumberLine=0 Then StopExec:=True Else
 If I>=0 Then JumpTo(L)
         Else GotoIdx(1);
End;

Procedure HelpCommand;
Var
 I:Integer;
Begin
 For I:=1 to NK do If KW[I]<>''Then Begin
  If OutCol+10>ScrW Then OutLn;
  OutS(KW[I]+Rep(' ',10-Length(KW[I])));
 End;
 OutLn;
End;

 { ExÇcution d'une instruction }
Procedure ExecStatement;
Var
 T,I:Integer;
 C:Char;
 X:Double;
Begin
 C:=NextCh;
 If(C=#0)or(C=':')Then Exit;
 If C=''''Then Begin
  CurrPos:=Length(CurrLine)+1;
  Exit;
 End;
 If C in['A'..'Z']Then Begin
  DoLet;
  Exit;
 End;
 T:=TokAt(CurrPos);
 If T=0 Then Begin
  SynErr;
  Exit;
 End;
 SkipTok;
 Case T of
  kEND:Begin
   CloseAll;
   InHandler:=False;
   If CurrLinePtr>0 Then Begin
    ContOk:=True;
    ContPtr:=CurrLinePtr;
    ContPos:=CurrPos;
    ContJump:=False;
   End;
   StopExec:=True;
  End;
  kFOR:DoFor;
  kNEXT:DoNext;
  kDATA:SkipData;
  kINPUT:DoInput(False);
  kDIM:DoDim;
  kREAD:DoRead;
  kLET:DoLet;
  kGOTO:JumpTo(ParseLineNum);
  kRUN:Begin
   If NextCh='"'Then Begin
    EvalS;
    If ErrCode<>0 Then Exit;
    If Accept(',')Then ReadWord;
    LoadProgram(VS,False);
    If ErrCode<>0 Then Exit;
    I:=-1;
   End
    Else
   Begin
    I:=-1;
    If(IsDigit)Then I:=ParseLineNum;
    If ErrCode<>0 Then Exit;
   End;
   ClearAll;
   If NumberLine=0 Then StopExec:=True Else
   If I>=0 Then JumpTo(I)
           Else GotoIdx(1);
  End;
  kIF:DoIf;
  kRESTORE:DoRestore;
  kGOSUB:PushGosub(ParseLineNum);
  kRETURN:DoReturn;
  kREM:CurrPos:=Length(CurrLine)+1;
  kSTOP:Begin
   DoBreak(CurrPos);
   ContJump:=False;
  End;
  kPRINT:DoPrint(0);
  kLIST:DoList(0);
  kNEW:Begin
   FreeLines;
   ClearAll;
   StopExec:=True;
  End;
  kON:DoOn;
  kMOTOR:SkipStmt;
  kDEF:DoDef;
  kPOKE,kOUT:Begin
   X:=EvalN;
   Expect(',');
   I:=EvalB;
   If ErrCode=0 Then Begin
    If T=kPOKE Then PokeB(DefSeg,Word(RoundI(X)),I)
    {$IFNDEF FPC}
               Else Port[Word(RoundI(X))]:=I
    {$ENDIF};
   End;
  End;
  kCONT:If Not(ContOk)Then Err(17)
         Else
        Begin
         LoadLine(ContPtr);
         CurrPos:=ContPos;
         Jumped:=ContJump;
         ContOk:=False;
        End;
  kLPRINT:DoPrint(-1);
  kLLIST:DoList(-1);
  kWIDTH:DoWidth;
  kELSE:CurrPos:=Length(CurrLine)+1;
  kTRON:Tron:=True;
  kTROFF:Tron:=False;
  kSWAP:DoSwap;
  kERASE:DoErase;
  kEDIT:Begin
   I:=ParseLineNum;
   If ErrCode<>0 Then Exit;
   If FindLine(I,T)Then Begin
    EditBuf:=IntToStr(I)+' '+Detok(PA[T]^.Text);
    IsEdit:=True;
    StopExec:=True;
   End
    Else
   Err(8);
  End;
  kERROR:Begin
   I:=EvalI;
   If ErrCode=0 Then Begin
    If(I<1)or(I>255)Then Err(5)
                    Else Err(I);
   End;
  End;
  kRESUME:Begin
   If Not(InHandler)Then Err(20)
    Else
   Begin
    InHandler:=False;
    If AcceptTok(kNEXT)Then Begin
     LoadLine(ResPtr);
     CurrPos:=ResPos;
     SkipStmt;
    End
     Else
    Begin
     I:=0;
     If(IsDigit)Then I:=ParseLineNum;
     If I<>0 Then JumpTo(I)
      Else
     Begin
      LoadLine(ResPtr);
      CurrPos:=ResPos;
      Jumped:=True;
     End;
    End;
   End;
  End;
  kDELETE:DoDelete;
  kAUTO:Begin
   AutoLines:=10;
   IncrAuto:=10;
   If(IsDigit)Then AutoLines:=ParseLineNum;
   If Accept(',')Then If(IsDigit)Then IncrAuto:=ParseLineNum;
   IsAuto:=ErrCode=0;
   StopExec:=True;
  End;
  kRENUM:DoRenum;
  44..47:DoDefType(T);
  kLINE:If AcceptTok(kINPUT)Then DoInput(True)
                            Else DoLine;
  kWHILE:DoWhile;
  kWEND:DoWend;
  kWRITE:DoWrite;
  kOPTION:DoOption;
  kRANDOMIZE:DoRandomize;
  kOPEN:DoOpen;
  kCLOSE:DoClose;
  kLOAD:Begin
   EvalS;
   If ErrCode<>0 Then Exit;
   I:=0;
   If Accept(',')Then If ReadWord='R'Then I:=1;
   If I=0 Then CloseAll;
   LoadProgram(VS,False);
   If ErrCode=0 Then Begin
    ClearVars;
    ResetRun;
    OnErrLine:=0;
    ContOk:=False;
    If(I=1)and(NumberLine>0)Then GotoIdx(1)
                            Else StopExec:=True;
   End;
  End;
  kMERGE:Begin
   EvalS;
   If ErrCode=0 Then LoadProgram(VS,True);
   StopExec:=True;
  End;
  kSAVE:DoSave;
  kCOLOR:DoColor;
  kCLS:DoCls;
  kSOUND:DoSound;
  kBEEP:Tone(800,250);
  kPSET,kPRESET:DoPset(T=kPSET);
  kSCREEN:DoScreen;
  kKEY:DoKey;
  kLOCATE:DoLocate;
  kHELP:HelpCommand;
  kSLEEP:Begin
   X:=1;
   If Not(EndOfStmt)Then X:=EvalN;
   If(ErrCode=0)and(X>0)Then Delay(Trunc(X*1000));
  End;
  kMID:DoMidStmt;
  kFILES:DoFiles;
  kSYSTEM:Begin
   Terminated:=True;
   StopExec:=True;
  End;
  kNAME:DoName;
  kKILL:DoKill;
  kRESET:CloseAll;
  kCHAIN:DoChain;
  kCOMMON:DoCommon;
  kCAT:DoFiles;
  kCLEAR,kCLR:Begin
   SkipStmt;
   ClearAll;
  End;
  kFIELD:DoField;
  kGET,kPUT:If(NextCh='(')or(PeekTok=kSTEP)Then DoGraphGetPut(T=kPUT)
                                           Else DoFileGetPut(T=kPUT);
  kLSET,kRSET:DoLRSet(T=kRSET);
  kBLOAD,kBSAVE:DoBSaveLoad(T=kBLOAD);
  kCALL,kCALLS:DoCall(T=kCALLS);
  kPALETTE:DoPalette;
  kWAIT:DoWait;
  kVIEW:DoView;
  kWINDOW:DoWindow;
  kTIMER,kCOM,kPEN,kSTRIG:Begin
   If(T=kSTRIG)and(NextCh<>'(')Then Begin
    If Not(AcceptTok(kON)or AcceptTok(kOFF))Then SynErr;
   End
    Else
   DoEvSet(EvParse(T,False));
  End;
  kLOCK,kUNLOCK,kLCOPY,kPCOPY:SkipStmt;
  kENVIRON:Begin
   EvalS;
   If ErrCode<>0 Then Exit;
   I:=Pos('=',VS);
   If(I<2)or(EnvCnt>=64)Then Err(5)
    Else
   Begin
    VS:=StrToUpper(Copy(VS,1,I-1))+Copy(VS,I,255);
    I:=EnvFind(Copy(VS,1,I-1));
    If I<0 Then Begin
     I:=EnvCnt;
     Inc(EnvCnt);
    End;
    SetStrP(@EnvList^[I],VS);
   End;
  End;
  kIOCTL:Begin
   Accept('#');
   CheckFile(EvalI,' ');
   Expect(',');
   EvalS;
   Err(5);
  End;
  kDATE,kTIME:DoSetDateTime(T);
  kPAINT:DoPaint;
  kCIRCLE:DoCircle;
  kDRAW:DoDraw;
  kPLAY:If PeekTok in[kON,kOFF,kSTOP]Then DoEvSet(25)
                                    Else DoPlay;
  kCHDIR,kMKDIR,kRMDIR:DoDir(T);
  kSHELL:DoShell;
  kTO,kTHEN,kTAB,kSTEP,kUSR,kFN,kSPC,kNOT,kERL,kERR,kSTRING,kUSING,kINSTR,
  kVARPTR,kCSRLIN,kPOINT,kOFF,kINKEY,kAND..kMOD,128,129,131..158,160,162..164,
  kERDEV,kPMAP,kLTRIM..kTRIM,205..215:SynErr;
  Else Err(73);
 End;
End;

 { Traitement d'une erreur : interception par ON ERROR ou affichage }
Function HandleError:Boolean;
Var
 E:Integer;
 L:Word;
Begin
 HandleError:=False;
 E:=ErrCode;
 ErrCode:=0;
 If ForceLine>=0 Then L:=ForceLine Else
 If StmtPtr>0 Then L:=PA[StmtPtr]^.Num
              Else L:=65535;
 ForceLine:=-1;
 ErrNum:=E;
 ErrLin:=L;
 If(OnErrLine<>0)and Not(InHandler)Then Begin
  InHandler:=True;
  ResPtr:=StmtPtr;
  ResPos:=StmtPos;
  JumpTo(OnErrLine);
  If ErrCode=0 Then Begin
   HandleError:=True;
   Exit;
  End;
  E:=ErrCode;
  ErrCode:=0;
 End;
 InHandler:=False;
 If L<>65535 Then ScreenMsg(ErrText(E)+MsgAtLine+IntToStr(L))
             Else ScreenMsg(ErrText(E));
 If(E=2)and(L<>65535)and FindLine(L,StmtPtr)Then Begin
  EditBuf:=IntToStr(L)+' '+Detok(PA[StmtPtr]^.Text);
  IsEdit:=True;
 End;
 ContOk:=False;
End;

 { Boucle d'exÇcution }
Procedure Execute;
Var
 C:Char;
Begin
 StopExec:=False;
 Repeat
  Inc(PollCnt);
  If PollCnt and 15=0 Then Begin
   PollKey;
   If CurrLinePtr>0 Then FireEvent;
  End;
  If(BreakFlag)Then Begin
   BreakFlag:=False;
   DoBreak(CurrPos);
   Exit;
  End;
  StmtPtr:=CurrLinePtr;
  StmtPos:=CurrPos;
  SSP:=0;
  EvDepth:=0;
  OutF:=0;
  Jumped:=False;
  ExecStatement;
  If ErrCode<>0 Then Begin
   If HandleError Then Continue;
   Exit;
  End;
  If(StopExec)Then Exit;
  If Not(Jumped)Then Begin
   C:=NextCh;
   If C=':'Then Inc(CurrPos) Else
   If(C='''')or(TokAt(CurrPos)=kELSE)Then CurrPos:=Length(CurrLine)+1 Else
   If C<>#0 Then Begin
    SynErr;
    If HandleError Then Continue;
    Exit;
   End;
  End;
  If NextCh=#0 Then Begin
   If CurrLinePtr=0 Then Exit;
   If CurrLinePtr>=NumberLine Then Begin
    If(InHandler)Then Begin
     Err(19);
     HandleError;
    End;
    CloseAll;
    Exit;
   End;
   GotoIdx(CurrLinePtr+1);
  End;
 Until False;
End;

 { Traitement d'une ligne tapÇe au clavier }
Procedure ProcessLine(S:String);
Var
 N:LongInt;
 P,I:Integer;
Begin
 S:=LTrim(S);
 If S=''Then Begin
  ShowOk:=False;
  Exit;
 End;
 If S[1]in['0'..'9']Then Begin
  ShowOk:=False;
  N:=0;
  P:=1;
  While(P<=Length(S))and(S[P]in['0'..'9'])do Begin
   If N<100000 Then N:=N*10+Ord(S[P])-48;
   Inc(P);
  End;
  If N>65529 Then Begin
   ScreenMsg(ErrText(2));
   ShowOk:=True;
   Exit;
  End;
  If(IsAuto)Then Begin
   If(P<=Length(S))and(S[P]='*')Then Delete(S,P,1);
   AutoLines:=N+IncrAuto;
  End;
  S:=LTrim(Copy(S,P,255));
  If S=''Then Begin
   If(IsAuto)Then Exit;
   If Not FindLine(N,I)Then Begin
    ScreenMsg(ErrText(8));
    ShowOk:=True;
    Exit;
   End;
  End;
  StoreLine(N,Crunch(S));
  If ErrCode<>0 Then Begin
   ScreenMsg(ErrText(ErrCode));
   ErrCode:=0;
  End;
  ClearAll;
 End
  Else
 Begin
  DirectLine:=Crunch(S);
  LoadLine(0);
  CurrPos:=1;
  Execute;
  If(InGraph)and(GCol>0)Then GrNewLine;
 End;
End;

Procedure HomeMessage;Begin
 ClrScr;
 ShowFunctionKey;
 Window(1,1,ScrW,24);
 WriteLn(MsgTitle,Version);
 WriteLn(MsgLic);
End;

Var
 Line0:String;
 I0:Integer;

BEGIN
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ENDIF}
 {$ENDIF}
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn(MsgHelp1);
  WriteLn;
  WriteLn(MsgSyntax);
  WriteLn;
  WriteLn(MsgHelp2);
 End
  Else
 If ParamStr(1)='--version'Then Begin
  WriteLn('GWBASIC ',Version,MsgClone);
  WriteLn('Licence MIT');
  WriteLn;
  WriteLn(MsgAuthor);
 End
  Else
 Begin
  CheckBreak:=False;
  FileName:='';
  FunctionKeyList[1]:='LIST ';
  FunctionKeyList[2]:='RUN'#13;
  FunctionKeyList[3]:='LOAD"';
  FunctionKeyList[4]:='SAVE"';
  FunctionKeyList[5]:='CONT'#13;
  FunctionKeyList[6]:=',"LPT1';
  FunctionKeyList[7]:='TRON'#13;
  FunctionKeyList[8]:='TROFF'#13;
  FunctionKeyList[9]:='KEY ';
  FunctionKeyList[10]:='SCREEN';
  ScrW:=80;
  VTop:=1;
  VBot:=24;
  TimerInt:=1;
  FieldList:=NIL;
  EnvList:=Alloc(64*SizeOf(StrPointer));
  FillChar(EnvList^,64*SizeOf(StrPointer),0);
  EnvCnt:=0;
  InGraph:=False;
  Tron:=False;
  KeyFunction:=True;
  NumberLine:=0;
  VarList:=NIL;
  ArrList:=NIL;
  FnList:=NIL;
  ErrCode:=0;
  ForceLine:=-1;
  KeyBuf:='';
  LPCol:=0;
  POct:=4;
  PLen:=4;
  PTempo:=120;
  PStyle:=7;
  {$IFDEF FPC}
   DefSeg:=0;
  {$ELSE}
   DefSeg:=DSeg;
  {$ENDIF}
  For I0:=1 to MaxFile do FMode[I0]:=#0;
  ClearAll;
  Terminated:=False;
  AutoLines:=10;
  IncrAuto:=10;
  IsAuto:=False;
  IsEdit:=False;
  ShowOk:=True;
  HomeMessage;
  For I0:=1 to ParamCount do FileName:=ParamStr(I0);
  If FileName<>''Then ProcessLine('RUN "'+FileName+'"');
  While Not(Terminated)do Begin
   If(ShowOk)Then Begin
    If WhereX>1 Then WriteLn;
    WriteLn('Ok');
   End;
   ShowOk:=True;
   Line0:='';
   If(IsEdit)Then Begin
    Line0:=EditBuf;
    IsEdit:=False;
   End
    Else
   If(IsAuto)Then Begin
    Line0:=IntToStr(AutoLines);
    If FindLine(AutoLines,I0)Then Line0:=Line0+'*'
                             Else Line0:=Line0+' ';
   End;
   If Not EditLine(Line0)Then Begin
    WriteLn;
    IsAuto:=False;
    ShowOk:=False;
   End
    Else
   Begin
    WriteLn;
    ProcessLine(Line0);
   End;
  End;
  CloseAll;
  If(InGraph)Then CloseGraph;
  Window(1,1,80,25);
  ClrScr;
 End;
END.
