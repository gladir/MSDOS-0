{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal)
}

Program MEM;

Uses Crt,DOS;

Const
 MaxBlk=200;
 MaxTok=40;
 MaxMod=60;

Type
 XMSRegs=Record
  AX,BX,DX,SI,Segment:Word;
 End;
 TBlock=Record
  Seg,Size,Own:Word;
 End;

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 XMSPtr:Pointer;
 XMSErr:Byte;
 Used:Integer;
 TotalSize,TotalUsed,TotalFree:LongInt;
 Blk:Array[1..MaxBlk]of TBlock;
 NBlk:Integer;
 FirstSeg:Word;
 Mode:Integer;       { 0 normal, 1 /CLASSIFY, 2 /DEBUG, 3 /FREE, 4 /MODULE }
 PageMode:Boolean;
 LineCnt:Integer;
 ModName:String;
 Tok:Array[1..MaxTok]of String[40];
 IsOpt:Array[1..MaxTok]of Boolean;
 NTok:Integer;
 WantHelp:Boolean;
 BadParam:String;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function GetConvMemory:Word;
Var
 Regs:Registers;
Begin
 Regs.AX:=0;
 Intr($12,Regs);
 GetConvMemory:=Regs.AX;
End;

{ Texte dans la langue choisie (variable LANGUAGE) }
Function T5(Const Fr,En,Gr,It,Sp:String):String;
Begin
 Case Language of
  _French:T5:=Fr;
  _English:T5:=En;
  _Germany:T5:=Gr;
  _Italian:T5:=It;
 Else
  T5:=Sp;
 End;
End;

Function NumStr(N:LongInt):String;
Var
 S:String;
Begin
 Str(N,S);
 NumStr:=S;
End;

{ Nombre avec separateur de milliers selon la langue }
Function Fmt(N:LongInt):String;
Var
 S,R:String;
 I,Cnt:Integer;
 Sep:Char;
Begin
 Case Language of
  _French:Sep:=' ';
  _English:Sep:=',';
 Else
  Sep:='.';
 End;
 Str(N,S);
 R:='';
 Cnt:=0;
 For I:=Length(S)downto 1 do Begin
  If(Cnt>0)and(Cnt mod 3=0)Then R:=Sep+R;
  R:=S[I]+R;
  Inc(Cnt);
 End;
 Fmt:=R;
End;

Function PadR(S:String;N:Integer):String;
Begin
 While Length(S)<N do S:=S+' ';
 PadR:=S;
End;

Function PadL(S:String;N:Integer):String;
Begin
 While Length(S)<N do S:=' '+S;
 PadL:=S;
End;

Function Dash(N:Integer):String;
Var
 S:String;
Begin
 S:='';
 While Length(S)<N do S:=S+'-';
 Dash:=S;
End;

Function Hex4(W:Word):String;
Const
 HexDigit:String[16]='0123456789ABCDEF';
Begin
 Hex4:=HexDigit[(W shr 12)and 15+1]+HexDigit[(W shr 8)and 15+1]+
       HexDigit[(W shr 4)and 15+1]+HexDigit[W and 15+1];
End;

{ Ecriture d'une ligne ; avec /PAGE, pause tous les 23 lignes }
Procedure Out(Const S:String);
Begin
 WriteLn(S);
 Inc(LineCnt);
 If(PageMode)and(LineCnt>=23)Then Begin
  Write(T5('Appuyez sur une touche pour continuer...',
           'Press any key to continue...',
           'Weiter mit beliebiger Taste...',
           'Premere un tasto per continuare...',
           'Pulse una tecla para continuar...'));
  If ReadKey=#0 Then ReadKey;
  WriteLn;
  LineCnt:=0;
 End;
End;

{ Parcourt la chaine des MCB (premier MCB en ES:BX-2 apres INT 21h/52h).
  Le bloc de MEM lui-meme et son environnement sont comptes comme libres
  (rendus a la sortie), les blocs libres voisins sont fusionnes. }
Procedure LoadBlocks;
Var
 Regs:Registers;
 Seg,Sz,Own:Word;
 Stop:Boolean;
Begin
 Regs.AH:=$52;
 Intr($21,Regs);
 Seg:=MemW[Regs.ES:Regs.BX-2];
 FirstSeg:=Seg;
 NBlk:=0;
 Stop:=False;
 Repeat
  If(Mem[Seg:0]<>Ord('M'))and(Mem[Seg:0]<>Ord('Z'))Then Stop:=True
  Else Begin
   Sz:=MemW[Seg:3];
   Own:=MemW[Seg:1];
   If Own=PrefixSeg Then Own:=0;
   If(Own=0)and(NBlk>0)and(Blk[NBlk].Own=0)Then Inc(Blk[NBlk].Size,Sz+1)
   Else If NBlk<MaxBlk Then Begin
    Inc(NBlk);
    Blk[NBlk].Seg:=Seg;
    Blk[NBlk].Size:=Sz;
    Blk[NBlk].Own:=Own;
   End;
   If Mem[Seg:0]=Ord('Z')Then Stop:=True
                         Else Seg:=Seg+Sz+1;
  End;
 Until Stop;
End;

{ Nom du programme proprietaire (PSP) d'apres son environnement }
Function ProgName(Psp:Word):String;
Var
 Env,Q,I:Word;
 S:String;
Begin
 If Psp=8 Then Begin
  ProgName:='MSDOS';
  Exit;
 End;
 ProgName:='????';
 If Psp<$60 Then Exit;
 { interpreteur de commandes : son propre parent (apres un SET, le nom
   du programme a la fin de l'environnement n'est plus fiable) }
 If MemW[Psp:$16]=Psp Then Begin
  ProgName:='COMMAND';
  Exit;
 End;
 Env:=MemW[Psp:$2C];
 If Env=0 Then Exit;
 Q:=0;
 While(Q<4000)and((Mem[Env:Q]<>0)or(Mem[Env:Q+1]<>0))do Inc(Q);
 If Q>=4000 Then Exit;
 I:=Q+4;
 S:='';
 While(I<Q+120)and(Mem[Env:I]<>0)do Begin
  S:=S+Chr(Mem[Env:I]);
  Inc(I);
 End;
 Q:=Length(S);
 While(Q>0)and(S[Q]<>'\')and(S[Q]<>':')and(S[Q]<>'/')do Dec(Q);
 S:=Copy(S,Q+1,255);
 Q:=Pos('.',S);
 If Q>0 Then S:=Copy(S,1,Q-1);
 If S='' Then S:='????';
 ProgName:=Copy(StrToUpper(S),1,10);
End;

Function XMSInit:Boolean;
Var
 Regs:Registers;
 xr:XMSRegs;
Begin
 Regs.AX:=$4300;
 Intr($2F,Regs);
 If(Regs.AL=$80)Then Begin
  Regs.AX:=$4310;
  Intr($2F,Regs);
  XMSPtr:=Ptr(Regs.ES,Regs.BX);
  XMSErr:=0;
  XMSInit:=True;
 End
  Else
 XMSInit:=False;
End;

Procedure XMSCall(NumFonc:Byte;Var XRegs:XMSRegs);Begin
 Inline ( $8C / $D9 /                          { mov    cx,ds        *}
           $51 /                                { push   cx           *}
           $C5 / $BE / $04 / $00 /              { lds    di,[bp+0004] *}
           $8A / $66 / $08 /                    { mov    ah,[bp+0008] *}
           $8B / $9D / $02 / $00 /              { mov    bx,[di+0002] *}
           $8B / $95 / $04 / $00 /              { mov    dx,[di+0004] *}
           $8B / $B5 / $06 / $00 /              { mov    si,[di+0006] *}
           $8E / $5D / $08 /                    { mov    ds,[di+08]   *}
           $8E / $C1 /                          { mov    es,cx        *}
           $26 / $FF / $1E / XMSPtr /           { call   es:[XMSPtr]  *}
           $8C / $D9 /                          { mov    cx,ds        *}
           $C5 / $7E / $04 /                    { lds    di,[bp+04]   *}
           $89 / $05 /                          { mov    [di],ax      *}
           $89 / $5D / $02 /                    { mov    [di+02],bx   *}
           $89 / $55 / $04 /                    { mov    [di+04],dx   *}
           $89 / $75 / $06 /                    { mov    [di+06],si   *}
           $89 / $4D / $08 /                    { mov    [di+08],cx   *}
           $1F                                  { pop    ds           *}
        );
 If(XRegs.AX = 0)and(XRegs.BX >= 128)Then Begin
  XMSErr:=Lo(XRegs.BX)
 End
  else
 XMSErr:=0;
End;

Function XMSUsed:Integer;
Var
 Used:Integer;
 Handle:Word;
 Xr:XMSRegs;
Begin
 Used:=0;
 For Handle:=0 to 65520 do Begin
  Xr.DX:=Handle;
  XmsCall(14,Xr);
  If Xr.AX=0 Then Break;
  Inc(Used,Xr.DX);
 End;
 XMSUsed:=Used;
End;

Function XMSFree:Integer;
Var
 Xr:XMSRegs;
Begin
 XmsCall(8,Xr);
 XMSFree:=Xr.AX;
End;

{ Type d'un bloc : 0 libre, 1 systeme, 2 programme, 3 environnement,
  4 donnees }
Function BlockType(I:Integer):Integer;
Var
 Own:Word;
Begin
 Own:=Blk[I].Own;
 If Own=0 Then BlockType:=0
 Else If Own=8 Then BlockType:=1
 Else If Blk[I].Seg+1=Own Then BlockType:=2
 Else If(Own>=$60)and(MemW[Own:$2C]=Blk[I].Seg+1)Then BlockType:=3
 Else BlockType:=4;
End;

Function TypeName(T:Integer):String;
Begin
 Case T of
  0:TypeName:=T5('Libre','Free','Frei','Libero','Libre');
  1:TypeName:=T5('Donn'+#130+'es syst'+#138+'me','System Data',
                 'Systemdaten','Dati di sistema','Datos del sistema');
  2:TypeName:=T5('Programme','Program','Programm','Programma','Programa');
  3:TypeName:=T5('Environnement','Environment','Umgebung','Ambiente',
                 'Entorno');
 Else
  TypeName:=T5('Donn'+#130+'es','Data','Daten','Dati','Datos');
 End;
End;

Function SizeK(N:LongInt):String;
Begin
 SizeK:=Fmt(N)+' ('+NumStr((N+512)shr 10)+'K)';
End;

Function FreeBytes:LongInt;
Var
 I:Integer;
 N:LongInt;
Begin
 N:=0;
 For I:=1 to NBlk do If Blk[I].Own=0 Then Inc(N,LongInt(Blk[I].Size)*16);
 FreeBytes:=N;
End;

Function LargestBytes:LongInt;
Var
 I:Integer;
 N:LongInt;
Begin
 N:=0;
 For I:=1 to NBlk do
  If(Blk[I].Own=0)and(LongInt(Blk[I].Size)*16>N)Then
   N:=LongInt(Blk[I].Size)*16;
 LargestBytes:=N;
End;

Procedure MemRow(Const Name:String;A,B,C:LongInt);
Var
 S:String;
Begin
 S:=PadR(Name,19);
 S:=S+PadL(NumStr(A)+'K',7);
 S:=S+PadL(NumStr(B)+'K',10);
 S:=S+PadL(NumStr(C)+'K',12);
 Out(S);
End;


{ Tableau de la memoire (conventionnelle, XMS) et plus grand programme }
Procedure ShowSummary;
Var
 Conv,FreeK:LongInt;
 S:String;
Begin
 TotalSize:=0;TotalUsed:=0;TotalFree:=0;
 Conv:=GetConvMemory;
 FreeK:=FreeBytes shr 10;
 S:=PadR(T5('Type de m'+#130+'moire','Memory Type','Speicherart',
            'Tipo di memoria','Tipo de memoria'),19);
 S:=S+PadL(T5('Total','Total','Gesamt','Totale','Total'),7);
 S:=S+PadL('= '+T5('Utilis'+#130,'Used','Belegt','Usata','Usada'),10);
 S:=S+PadL('+ '+T5('Libre','Free','Frei','Libera','Libre'),12);
 Out(S);
 Out(Dash(19)+' '+Dash(6)+' '+Dash(9)+' '+Dash(11));
 Inc(TotalSize,Conv);
 Inc(TotalUsed,Conv-FreeK);
 Inc(TotalFree,FreeK);
 MemRow(T5('Conventionnelle','Conventional','Konventionell',
           'Convenzionale','Convencional'),Conv,Conv-FreeK,FreeK);
 If(XMSInit)Then Begin
  Used:=XMSUsed;
  Inc(TotalSize,Used+XMSFree);
  Inc(TotalUsed,Used);
  Inc(TotalFree,XMSFree);
  MemRow(T5('Etendue (XMS)','Extended (XMS)','Erweitert (XMS)',
            'Estesa (XMS)','Extendida (XMS)'),Used+XMSFree,Used,XMSFree);
 End;
 Out(Dash(19)+' '+Dash(6)+' '+Dash(9)+' '+Dash(11));
 MemRow(T5(' M'+#130+'moire totale',' Total memory',' Gesamtspeicher',
           ' Memoria totale',' Memoria total'),TotalSize,TotalUsed,TotalFree);
 Out('');
 Out(PadR(T5('Taille du plus grand programme','Largest executable program',
             'Gr'+#148+#225+'tes Programm','Programma eseguibile maggiore',
             'Programa ejecutable mayor'),32)+
     PadL(NumStr(LargestBytes shr 10)+'K',6)+'  ('+Fmt(LargestBytes)+' '+
     T5('octets','bytes','Bytes','byte','bytes')+')');
End;

Function BytesAbove(I:Integer):LongInt;
Begin
 BytesAbove:=(LongInt(Blk[I].Size)+1)*16;
End;

Function ColK(N:LongInt):String;
Begin
 ColK:=PadL(SizeK(N),17);
End;

Procedure ShowClassify;
Var
 Names:Array[1..MaxMod]of String[12];
 Tot:Array[1..MaxMod]of LongInt;
 NN,I,J:Integer;
 S:String;
Begin
 NN:=1;
 Names[1]:='MSDOS';
 Tot[1]:=LongInt(FirstSeg)*16;
 For I:=1 to NBlk do Begin
  If Blk[I].Own=8 Then Inc(Tot[1],BytesAbove(I))
  Else If Blk[I].Own<>0 Then Begin
   S:=ProgName(Blk[I].Own);
   J:=1;
   While(J<=NN)and(Names[J]<>S)do Inc(J);
   If(J>NN)and(NN<MaxMod)Then Begin
    Inc(NN);
    Names[NN]:=S;
    Tot[NN]:=0;
    J:=NN;
   End;
   If J<=NN Then Inc(Tot[J],BytesAbove(I));
  End;
 End;
 Out(T5('Modules utilisant la m'+#130+'moire sous 1 Mo :',
        'Modules using memory below 1 MB:',
        'Module im Speicher unter 1 MB:',
        'Moduli che usano la memoria sotto 1 MB:',
        'M'+#162+'dulos que usan memoria bajo 1 MB:'));
 Out('');
 Out('  '+PadR(T5('Nom','Name','Name','Nome','Nombre'),10)+
     PadL(T5('Total','Total','Gesamt','Totale','Total'),17)+
     PadL(T5('Conventionnelle','Conventional','Konventionell',
             'Convenzionale','Convencional'),17)+
     PadL(T5('Haute','Upper','Oberer','Alta','Alta'),17));
 Out('  '+Dash(8)+'  '+Dash(15)+'  '+Dash(15)+'  '+Dash(15));
 For J:=1 to NN do
  Out('  '+PadR(Names[J],10)+ColK(Tot[J])+ColK(Tot[J])+ColK(0));
 Out('  '+PadR(T5('LIBRE','FREE','FREI','LIBERA','LIBRE'),10)+
     ColK(FreeBytes)+ColK(FreeBytes)+ColK(0));
 Out('');
 ShowSummary;
End;

Procedure DebugRow(Seg:Word;Bytes:LongInt;Const Nm,Ty:String);
Begin
 Out('  '+Hex4(Seg)+'  '+PadL(SizeK(Bytes),17)+'  '+PadR(Nm,10)+' '+Ty);
End;

Procedure ShowDebug;
Var
 I:Integer;
 T:Integer;
 Nm:String;
Begin
 Out(T5('D'+#130+'tail de la m'+#130+'moire conventionnelle :',
        'Conventional Memory Detail:',
        'Details zum konventionellen Speicher:',
        'Dettaglio della memoria convenzionale:',
        'Detalle de la memoria convencional:'));
 Out('');
 Out('  '+PadR('Segment',6)+PadL(T5('Total','Total','Gesamt','Totale',
                                       'Total'),19)+'  '+
     PadR(T5('Nom','Name','Name','Nome','Nombre'),10)+' '+
     T5('Type','Type','Typ','Tipo','Tipo'));
 Out('  '+Dash(7)+'  '+Dash(17)+'  '+Dash(10)+' '+Dash(12));
 DebugRow(0,1024,'',T5('Vecteurs d''interruption','Interrupt Vector',
                       'Interruptvektoren','Vettori di interrupt',
                       'Vectores de interrupci'+#162+'n'));
 DebugRow($40,256,'',T5('Zone de communication ROM','ROM Communication Area',
                        'ROM-Kommunikationsbereich',
                        'Area comunicazioni ROM','Area de comunicaci'+#162+
                        'n ROM'));
 DebugRow($50,512,'',T5('Zone de communication DOS','DOS Communication Area',
                        'DOS-Kommunikationsbereich',
                        'Area comunicazioni DOS','Area de comunicaci'+#162+
                        'n DOS'));
 DebugRow($70,(LongInt(FirstSeg)-$70)*16,'MSDOS',TypeName(1));
 For I:=1 to NBlk do Begin
  T:=BlockType(I);
  If T=0 Then Nm:=''
         Else Nm:=ProgName(Blk[I].Own);
  DebugRow(Blk[I].Seg,BytesAbove(I),Nm,TypeName(T));
 End;
 Out('');
 ShowSummary;
End;

Procedure ShowFree;
Var
 I:Integer;
Begin
 Out(T5('M'+#130+'moire conventionnelle libre :','Free Conventional Memory:',
        'Freier konventioneller Speicher:','Memoria convenzionale libera:',
        'Memoria convencional libre:'));
 Out('');
 Out('  '+PadR('Segment',6)+PadL(T5('Total','Total','Gesamt','Totale',
                                       'Total'),19));
 Out('  '+Dash(7)+'  '+Dash(17));
 For I:=1 to NBlk do If Blk[I].Own=0 Then
  Out('  '+Hex4(Blk[I].Seg)+'  '+PadL(SizeK(LongInt(Blk[I].Size)*16),17));
 Out('');
 Out('  '+T5('Total libre :','Total Free:','Gesamt frei:','Totale libero:',
          'Total libre:')+' '+SizeK(FreeBytes));
End;

Procedure ShowModule;
Var
 I,Found:Integer;
 Nm:String;
 P:Integer;
Begin
 Nm:=StrToUpper(ModName);
 P:=Length(Nm);
 While(P>0)and(Nm[P]<>'\')and(Nm[P]<>':')do Dec(P);
 Nm:=Copy(Nm,P+1,255);
 P:=Pos('.',Nm);
 If P>0 Then Nm:=Copy(Nm,1,P-1);
 Found:=0;
 For I:=1 to NBlk do
  If(Blk[I].Own<>0)and(ProgName(Blk[I].Own)=Nm)Then Inc(Found);
 If(Nm='MSDOS')Then Inc(Found);
 If Found=0 Then Begin
  Out(T5('Module '+Nm+' introuvable en m'+#130+'moire.',
         'Module '+Nm+' not found in memory.',
         'Modul '+Nm+' nicht im Speicher gefunden.',
         'Modulo '+Nm+' non trovato in memoria.',
         'M'+#162+'dulo '+Nm+' no encontrado en memoria.'));
  Halt(1);
 End;
 Out(T5(Nm+' utilise la m'+#130+'moire suivante :',
        Nm+' is using the following memory:',
        Nm+' belegt folgenden Speicher:',
        Nm+' usa la memoria seguente:',
        Nm+' est'+#160+' usando la memoria siguiente:'));
 Out('');
 Out('  '+PadR('Segment',6)+PadL(T5('Total','Total','Gesamt','Totale',
                                       'Total'),19)+'  '+
     T5('Type','Type','Typ','Tipo','Tipo'));
 Out('  '+Dash(7)+'  '+Dash(17)+'  '+Dash(12));
 If(Nm='MSDOS')Then
  DebugRow($70,(LongInt(FirstSeg)-$70)*16,'',TypeName(1));
 For I:=1 to NBlk do
  If(Blk[I].Own<>0)and(ProgName(Blk[I].Own)=Nm)Then
   DebugRow(Blk[I].Seg,BytesAbove(I),'',TypeName(BlockType(I)));
End;

Procedure AddTok(S:String;O:Boolean);
Begin
 If(S<>'')and(NTok<MaxTok)Then Begin
  Inc(NTok);
  Tok[NTok]:=S;
  IsOpt[NTok]:=O;
 End;
End;

Procedure Tokenize;
Var
 I,P:Integer;
 A:String;
Begin
 NTok:=0;
 For I:=1 to ParamCount do Begin
  A:=StrToUpper(ParamStr(I));
  If Copy(A,1,2)='--'Then A:='/'+Copy(A,3,255)
  Else If(Length(A)>1)and(A[1]='-')Then A[1]:='/';
  If(A='')or(A[1]<>'/')Then AddTok(A,False)
  Else Begin
   Delete(A,1,1);
   While A<>''do Begin
    P:=Pos('/',A);
    If P=0 Then Begin
     AddTok(A,True);
     A:='';
    End
     Else
    Begin
     AddTok(Copy(A,1,P-1),True);
     Delete(A,1,P);
    End;
   End;
  End;
 End;
End;

Function IsOpt2(Const O,Full:String):Boolean;
Begin
 IsOpt2:=(O<>'')and(Copy(Full,1,Length(O))=O);
End;

Procedure ParseArgs;
Var
 I,P:Integer;
 O,Arg:String;
Begin
 Tokenize;
 I:=1;
 While I<=NTok do Begin
  If IsOpt[I]Then Begin
   O:=Tok[I];
   Arg:='';
   P:=Pos(':',O);
   If P=0 Then P:=Pos('=',O);
   If P>0 Then Begin
    Arg:=Copy(O,P+1,255);
    O:=Copy(O,1,P-1);
   End;
   If IsOpt2(O,'CLASSIFY')Then Mode:=1
   Else If IsOpt2(O,'DEBUG')Then Mode:=2
   Else If IsOpt2(O,'FREE')Then Mode:=3
   Else If IsOpt2(O,'PAGE')Then PageMode:=True
   Else If IsOpt2(O,'MODULE')Then Begin
    Mode:=4;
    If(Arg='')and(I<NTok)and(Not IsOpt[I+1])Then Begin
     Inc(I);
     Arg:=Tok[I];
    End;
    ModName:=Arg;
   End
   Else If(O='?')or(O='H')or(O='HELP')Then WantHelp:=True
   Else If BadParam=''Then BadParam:='/'+Tok[I];
  End
   Else
  If BadParam=''Then BadParam:=Tok[I];
  Inc(I);
 End;
End;

Procedure ShowHelp;
Begin
 Out(T5('MEM : Cette commande permet d''afficher les informations sur la '+
        'm'+#130+'moire.',
        'Displays the amount of used and free memory in your system.',
        'Zeigt die Gr'+#148+#225+'e des belegten und noch freien '+
        'Arbeitsspeichers im System an.',
        'Visualizza la quantit'+#133+' di memoria usata e libera nel '+
        'sistema.',
        'Muestra la cantidad de memoria usada y libre en el sistema.'));
 Out('');
 Out(T5('Syntaxe :','Syntax:','Syntax:','Sintassi:','Sintaxis:')+
     ' MEM [/CLASSIFY|/DEBUG|/FREE|/MODULE '+
     T5('programme','program','Programm','programma','programa')+'] [/PAGE]');
 Out('');
 Out('  /CLASSIFY  '+T5('Liste les programmes en m'+#130+'moire.',
     'Lists programs currently in conventional memory.',
     'Listet die Programme im konventionellen Speicher auf.',
     'Elenca i programmi in memoria convenzionale.',
     'Lista los programas en memoria convencional.'));
 Out('  /DEBUG     '+T5('Liste les programmes et pilotes internes.',
     'Lists programs and internal drivers in memory.',
     'Listet Programme und interne Treiber im Speicher auf.',
     'Elenca programmi e driver interni in memoria.',
     'Lista programas y controladores internos en memoria.'));
 Out('  /FREE      '+T5('Liste les blocs de m'+#130+'moire libres.',
     'Lists the free memory blocks.',
     'Listet die freien Speicherbl'+#148+'cke auf.',
     'Elenca i blocchi di memoria liberi.',
     'Lista los bloques de memoria libres.'));
 Out('  /MODULE    '+T5('Affiche la m'+#130+'moire utilis'+#130+
     'e par le programme.',
     'Shows the memory used by the specified program.',
     'Zeigt den vom Programm belegten Speicher.',
     'Mostra la memoria usata dal programma.',
     'Muestra la memoria usada por el programa.'));
 Out('  /PAGE      '+T5('Pause '+#133+' chaque page d''affichage.',
     'Pauses after each screenful of information.',
     'H'+#132+'lt nach jeder Bildschirmseite an.',
     'Pausa dopo ogni schermata.',
     'Pausa tras cada pantalla.'));
End;

BEGIN
 Language:=_French;
 TmpLanguage:=GetEnv('LANGUAGE');
 If TmpLanguage<>''Then Begin
  If TmpLanguage[1]='"'Then TmpLanguage:=Copy(TmpLanguage,2,255);
  If StrToUpper(Copy(TmpLanguage,1,2))='EN'Then Language:=_English Else
  If StrToUpper(Copy(TmpLanguage,1,2))='GR'Then Language:=_Germany Else
  If StrToUpper(Copy(TmpLanguage,1,2))='IT'Then Language:=_Italian Else
  If StrToUpper(Copy(TmpLanguage,1,2))='SP'Then Language:=_Spain;
 End;
 Mode:=0;
 PageMode:=False;
 LineCnt:=0;
 ModName:='';
 WantHelp:=False;
 BadParam:='';
 ParseArgs;
 If WantHelp Then ShowHelp
  Else
 If BadParam<>''Then Begin
  Out(T5('Param'+#138+'tre non valide - ','Invalid parameter - ',
         'Ung'+#129+'ltiger Parameter - ','Parametro non valido - ',
         'Par'+#160+'metro no v'+#160+'lido - ')+BadParam);
  Halt(1);
 End
  Else
 Begin
  If(Mode=4)and(ModName='')Then Begin
   Out(T5('Nom de module manquant.','Module name missing.',
          'Modulname fehlt.','Nome del modulo mancante.',
          'Falta el nombre del m'+#162+'dulo.'));
   Halt(1);
  End;
  LoadBlocks;
  Case Mode of
   1:ShowClassify;
   2:ShowDebug;
   3:ShowFree;
   4:ShowModule;
  Else
   ShowSummary;
  End;
 End;
END.
