{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program DEBUG;

Uses Crt;

Const
 CommandList:Array[0..36]of String[4]=(
  'A','C','DB','DD','DI','DL','DM','DW','DX','E','EXIT',
  'F','G','H','ID','IW','L','M','MC','MD','N',
  'OD','OW','P','PR','Q','QUIT','R',
  'RM','RN','RNR','S','T','TM','U','W','D'
 );

 CommandName:Array[0..36]of String[35]=(
  'Assembler',
  'Comparer',
  'Sortir un octet',
  'Sortir un double mot',
  'Sortir un interruption',
  'Sortir le LDT',
  'Sortir une chaine MCB',
  'Sortir un mot',
  'Sortir la memoire etendu',
  'Entrer',
  'Sortir',
  'Remplir',
  'Aller a',
  'Hexadecimal',
  'Entree de port d''un double mot',
  'Entree de port d''un mot',
  'Charge un fichier',
  'Deplacer',
  'Fixe le mode FPU',
  'Deplacer',
  'Nom',
  'Sortie de port d''un double mot',
  'Sortie de port d''un mot',
  'Traitement',
  'Retourne le traitement',
  'Sortir',
  'Sortir',
  'Registre',
  'Registre MMX',
  'Registre FPU',
  'Registre FPU',
  'Recherche',
  'Trace',
  'Mode tracage',
  'Dessembler',
  'Ecrire le fichier',
  'Sortir'
 );

 CommandSyntax:Array[0..36]of String[50]=(
  'A [adresse]',
  'C intervalle adresse',
  'DB intervalle',
  'DD intervalle',
  'DI interruption [compteur]',
  'DL selecteur [compteur]',
  'DM',
  'DW intervalle',
  'DX [adresse_physique]',
  'E adresse [liste]',
  'EXIT',
  'F intervalle liste',
  'G [=adresse] [point_d_arret]',
  'H valeur1 valeur2',
  'ID port',
  'IW port',
  'L [adresse]',
  'M intervalle adresse',
  'MC [2:N] (2=287, N=Pas de FPU)',
  'MD',
  'N [[unite:][chemin]nomfichier [listeparametre]]',
  'OD port valeur',
  'OW port valeur',
  'P [=adresse] [compteur]',
  'PR',
  'Q',
  'QUIT',
  'R [registre [valeur]]',
  'RM',
  'RN',
  'RNR',
  'S intervalle liste',
  'T [=adresse] [compteur]',
  'TM [0|1]',
  'U [intervalle]',
  'W [adresse]',
  'D [intervalle]'
 );

Type
 Instr80x86Rec=Record
  BaseSize:Byte;
  AsmName:String[10];
  AsmName66h:String[10];
  AsmName0Fh:String[10];
  Param:Boolean;
 End;

Const
 {Adresse d'assembleur pour le micro-processeur Intel (Cpu Intel)}
 ciBXnSI=$00;{©[BX+SI]î,88+}
 ciBXnDI=$01;{©[BX+DI]î,88+}
 ciBPnSI=$02;{©[BP+SI]î,88+}
 ciBPnDI=$03;{©[BP+DI]î,88+}
 ciSI=$04;{©[SI]î,88+}
 ciDI=$05;{©[DI]î,88+}
 ciBP=$06;{©[BP]î,88+}
 ciBX=$07;{©[BX]î,88+}
 {Instruction d'assembleur pour le micro-processeur Intel (Cpu Intel)}
 ciAAA=$37;{©AAAî,88+}
 ciAAD_=$D5;{©AADî,88+}
 ciAAM_=$D4;{©AAMî,88+}
 ciAAS=$3F;{©AASî,88+}
 ciAdcAL_=$14;{©ADC AL,??hî,286+}
 ciAdcAX_=$15;{©ADC AX,????hî,286+}
 ciAddAL_=$04;{©ADD AL,??hî,286+}
 ciAddAX_=$05;{©ADD AX,????hî,286+}
 ciAndAL_=$24;{©AND AL,??hî,286+}
 ciAndAX_=$25;{©AND AX,????hî,286+}
 ciCallFarAbs=$9A;{©CALL FAR ????h:????hî,88+}
 ciCBW=$98;{©CBWî,88+}
 ciCC=$CC;{©INT 03hî(Code Sp'cial CCh),88+}
 ciCLC=$F8;{©CLCî,88+}
 ciCLD=$FC;{©CLDî,88+}
 ciCLI=$FA;{©CLIî,88+}
 ciCMC=$F5;{©CMCî,88+}
 ciCmpAL_=$3C;{©CMP AL,??hî,286+}
 ciCmpAX_=$3D;{©CMP AX,????hî,286+}
 ciCmpSB=$A6;{©CMPSBî,88+}
 ciCmpSW=$A7;{©CMPSWî,88+}
 ciCS=$2E;{©CSî,88+}
 ciCWD=$99;{©CWDî,88+}
 ciDAA=$27;{©DAAî,88+}
 ciDAS=$2F;{©DASî,88+}
 ciDecAX=$48;{©DEC AXî,88+}
 ciDecBP=$4D;{©DEC BPî,88+}
 ciDecBX=$4B;{©DEC BXî,88+}
 ciDecCX=$49;{©DEC CXî,88+}
 ciDecDI=$4F;{©DEC DIî,88+}
 ciDecDX=$4A;{©DEC DXî,88+}
 ciDecSI=$4E;{©DEC SIî,88+}
 ciDecSP=$4C;{©DEC SPî,88+}
 ciDS=$3E;{©DSî,88+}
 ciES=$26;{©ESî,88+}
 ciFS=$64;{©FSî,386+}
 ciGS=$65;{©GSî,386+}
 ciHLT=$F4;{©HLTî,88+}
 ciIncAX=$40;{©INC AXî,88+}
 ciIncBP=$45;{©INC BPî,88+}
 ciIncBX=$43;{©INC BXî,88+}
 ciIncCX=$41;{©INC CXî,88+}
 ciIncDI=$47;{©INC DIî,88+}
 ciIncDX=$42;{©INC DXî,88+}
 ciIncSI=$46;{©INC SIî,88+}
 ciIncSP=$44;{©INC SPî,88+}
 ciInsB=$6C;{©INSBî,88+}
 ciInsW=$6D;{©INSWî,88+}
 ciInt=$CD;{©INT ??hî,88+}
 ciIntO=$CE;{©INTOî,88+}
 ciIRet=$CF;{©IRETî,88+}
 ciJBE=$76;{©JBE ?î,88+}
 ciJC=$72;{©JC ?î,88+}
 ciJG=$7E;{©JG ?î,88+}
 ciJL=$7C;{©JL ?î,88+}
 ciJMP_Word=$E9;{©JMP ????î,88+}
 ciJNBE=$77;{©JNBE ?î,88+}
 ciJNC=$73;{©JNC ?î,88+}
 ciJNG=$7F;{©JNG ?î,88+}
 ciJNL=$7D;{©JNL ?î,88+}
 ciJNO=$71;{©JNO ?î,88+}
 ciJNP=$7B;{©JNP ?î,88+}
 ciJNS=$79;{©JNS ?î,88+}
 ciJNZ=$75;{©JNZ ?î,88+}
 ciJO=$70;{©JO ?î,88+}
 ciJP=$7A;{©JP ?î,88+}
 ciJS=$78;{©JS ?î,88+}
 ciJZ=$74;{©JZ ?î,88+}
 ciLAHF=$9F;{©LAHFî,88+}
 ciLAR=$020F;{©LARî,386+}
 ciLeave=$C9;{©LEAVEî,286+}
 ciLDS=$C5;{©LDS reg,memî,88+}
 ciLES=$C4;{©LES reg,memî,88+}
 ciLFS=$B40F;{©LFS reg,memî,386+}
 ciLGS=$B50F;{©LGS reg,memî,386+}
 ciLock=$F0;{©LOCK ?î,88+}
 ciLODSB=$AC;{©LODSBî,88+}
 ciLODSD=$AD66;{©LODSDî,386+}
 ciLODSW=$AD;{©LODSWî,88+}
 ciLSL=$030F;{©LSL ?î,386+}
 ciLSS=$B20F;{©LSS reg,memî,386+}
 ciMovAL_=$A0;{©MOV AL,[addr]î,286+}
 ciMovAL_Byte=$B0;{©MOV AL,??î,88+}
 ciMovAX_=$A1;{©MOV AX,[addr]î,286+}
 ciMovAX_Word=$B8;{©MOV AX,????î, 88+}
 ciMovAH_AL=$E08A;{©MOV AH,ALî,88+}
 ciMovBP_SP=$EC8B;{©MOV BP,SPî,88+}
 ciMovBX_CX=$D98B;{©MOV BX,CXî,88+}
 ciMovCX_BX=$CB8B;{©MOV CX,BXî,88+}
 ciMovDX_Word=$BA;{©MOV DX,????î,88+}
 ciMovEAX_ES_DI=$058B6626;{©MOV EAX,ES:[DI]î,386+}
 ciMovES_DI_EAX=$05896626;{©MOV ES:[DI],EAXî,386+}
 ciMovSB=$A4;{©MOVSBî,88+}
 ciMovSD=$A566;{©MOVSDî,386+}
 ciMovSW=$A5;{©MOVSWî,88+}
 ciNOP=$90;{©NOPî,88+}
 ciOutDX_AL=$EE;{©OUT DX,ALî,88+}
 ciOutDX_AX=$EF;{©OUT DX,AXî,88+}
 ciOutSB=$6E;{©OUTSBî,286+}
 ciOutSD=$6F66;{©OUTSDî,386+}
 ciOutSW=$6F;{©OUTSWî,286+}
 ciPopAX=$58;{©POP AXî,88+}
 ciPopBP=$5D;{©POP BPî,88+}
 ciPopBX=$5B;{©POP BXî,88+}
 ciPopCX=$59;{©POP CXî,88+}
 ciPopDX=$5A;{©POP DXî,88+}
 ciPopDI=$5F;{©POP DIî,88+}
 ciPopDS=$1F;{©POP DSî,88+}
 ciPopEAX=$5866;{©POP EAXî,386+}
 ciPopEBX=$5B66;{©POP EBXî,386+}
 ciPopECX=$5966;{©POP ECXî,386+}
 ciPopEDI=$66+(ciPopDI shl 8);{©PUSH EDIî,386+}
 ciPopEDX=$5A66;{©POP EDXî,386+}
 ciPopFS=$A10F;{©PUSH FSî,386+}
 ciPopGS=$A90F;{©PUSH GSî,386+}
 ciPopES=$07;{©POP ESî,88+}
 ciPopSI=$5E;{©POP SIî,88+}
 ciPopSP=$5C;{©POP SPî,88+}
 ciPopSS=$17;{©POP SSî,88+}
 ciPopA=$61;{©POPAî,286+}
 ciPopF=$9D;{©POPFî,88+}
 ciPushA=$60;{©PUSHAî,286+}
 ciPushAX=$50;{©PUSH AXî,88+}
 ciPushBP=$55;{©PUSH BPî,88+}
 ciPushBX=$53;{©PUSH BXî,88+}
 ciPushCS=$0E;{©PUSH CSî,88+}
 ciPushCX=$51;{©PUSH CXî,88+}
 ciPushDI=$57;{©PUSH DIî,88+}
 ciPushDS=$1E;{©PUSH DSî,88+}
 ciPushDX=$52;{©PUSH DXî,88+}
 ciPushEAX=$5066;{©PUSH EAXî,386+}
 ciPushEBX=$5366;{©PUSH EBXî,386+}
 ciPushECX=$5166;{©PUSH ECXî,386+}
 ciPushEDX=$5266;{©PUSH EDXî,386+}
 ciPushEDI=$66+(ciPushDI shl 8);{©PUSH EDIî,386+}
 ciPushES=$06;{©PUSH ESî,88+}
 ciPushFS=$A00F;{©PUSH FSî,386+}
 ciPushGS=$A80F;{©PUSH GSî, 386+}
 ciPushMemB=$6A;{©PUSH ??î, 286+}
 ciPushSI=$56;{©PUSH SIî,88+}
 ciPushSP=$54;{©PUSH SPî,88+}
 ciPushSS=$16;{©PUSH SSî,88+}
 ciPushF=$9C;{©PUSHFî,88+}
 ciRepNZ=$F2;{©REPNZ ?î,88+}
 ciRep=$F3;{©REP ?î,88+}
 ciRetF=$CB;{©RETFî,88+}
 ciRetN=$C3;{©RETNî,88+}
 ciRet=ciRetN;{©RETNîou©RETFî,88+}
 ciSAHF=$9E;{©SAHFî,88+}
 ciSbbAL_=$1C;{©SBB AL,??hî,286+}
 ciSbbAX_=$1D;{©SBB AX,????hî,286+}
 ciSCASB=$AE;{©SCASBî,88+}
 ciSCASD=$AF66;{©SCASSî,386+}
 ciSCASW=$AF;{©SCASWî,88+}
 ciSHR_AX_=$E8C1;{©SHR AX,?î,88+}
 ciSHR_CX_=$E9C1;{©SHR CX,?î,88+}
 ciSubAL_=$2C;{ ©SUB AL,??hî,286+}
 ciSubAX_=$2D;{©SUB AX,????hî,286+}
 ciSS=$36;{©SSî,88+}
 ciSTC=$F9;{©STCî,88+}
 ciSTD=$FD;{©STDî,88+}
 ciSTI=$FB;{©STIî,88+}
 ciSTOSB=$AA;{©STOSBî,88+}
 ciSTOSD=$AB66;{©STOSDî,386+}
 ciSTOSW=$AB;{©STOSWî,88+}
 ciXchgAXnBP=$95;{©XCHG AX,BPî,88+}
 ciXchgAXnBX=$93;{©XCHG AX,BXî,88+}
 ciXchgAXnCX=$91;{©XCHG AX,CXî,88+}
 ciXchgAXnDI=$97;{©XCHG AX,DIî,88+}
 ciXchgAXnDX=$92;{©XCHG AX,DXî,88+}
 ciXchgAXnSI=$96;{©XCHG AX,SIî,88+}
 ciXchgAXnSP=$94;{©XCHG AX,SPî,88+}
 ciXchgEAX_DS_SI=$048B663E;{©XCHG EAX,DS:[SI]î,386+}
 ciXlat=$D7;{©XLATî,88+}
 ciXOR_=$81;{©XOR ?,?î,88+}
 ciXOR_AL_=$34;{©XOR AL,??hî,286+}
 ciXOR_AX_=$35;{©XOR AX,????hî,286+}


Const
 RegWord:Array[0..7]of String[2]=('AX','CX','DX','BX','SP','BP','SI','DI');
 RegByte:Array[0..7]of String[2]=('AL','CL','DL','BL','AH','CH','DH','BH');
 RegS:Array[0..3]of String[2]=('ES','CS','SS','DS');
 BasS:Array[0..7]of String[3]=('ADD','OR', 'ADC','SBB','AND','SUB','XOR','CMP');
 RotS:Array[0..7]of String[3]=('ROL','ROR','RCL','RCR','SHL','SHR','SAR','SAL');
 SmpS:Array[2..7]of String[4]=('NOT','NEG','MUL','IMUL','DIV','IDIV');
 PtrS:Array[0..1]of String[9]=('Byte Ptr ','Word Ptr ');
 PrcS:Array[0..1]of String[9]=('Near Ptr ','Far Ptr ');
 FlgS:Array[0..$F]of String[2]=(
  {0} 'O ',
  {1} 'NO',
  {2} 'C ',
  {3} 'NC',
  {4} 'Z ',
  {5} 'NZ',
  {6} 'BE',
  {7} 'A ',
  {8} 'S ',
  {9} 'NS',
  {A} 'P ',
  {B} 'NP',
  {C} 'L ',
  {D} 'NL',
  {E} 'G ',
  {F} 'NG');

 Instr80x86:Array[0..$FF]of Instr80x86Rec=(
  (BaseSize:$02;AsmName:'ADD';      AsmName66h:'';         AsmName0Fh:'';Param:True), { [00h] ADD mem/reg,regbyte }
  (BaseSize:$02;AsmName:'ADD';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [01h] ADD }
  (BaseSize:$02;AsmName:'ADD';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [02h] ADD }
  (BaseSize:$02;AsmName:'ADD';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [03h] ADD }
  (BaseSize:$02;AsmName:'ADD';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [04h] ADD AL,kk }
  (BaseSize:$03;AsmName:'ADD';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [05h] ADD AX,jjkk }
  (BaseSize:$01;AsmName:'PUSH ES';  AsmName66h:'';         AsmName0Fh:'CLTS';Param:False),   { [06h] PUSH ES }
  (BaseSize:$01;AsmName:'POP ES';   AsmName66h:'';         AsmName0Fh:'LOADALL';Param:False), { [07h] POP ES }
  (BaseSize:$02;AsmName:'OR';       AsmName66h:'';         AsmName0Fh:'WBINVD';Param:True),  { [08h] OR }
  (BaseSize:$02;AsmName:'OR';       AsmName66h:'';         AsmName0Fh:'INVD';Param:True),    { [09h] OR }
  (BaseSize:$02;AsmName:'OR';       AsmName66h:'';         AsmName0Fh:'';Param:True),        { [0Ah] OR }
  (BaseSize:$02;AsmName:'OR';       AsmName66h:'';         AsmName0Fh:'';Param:True),        { [0Bh] OR }
  (BaseSize:$02;AsmName:'OR';       AsmName66h:'';         AsmName0Fh:'';Param:True),        { [0Ch] OR AL,kk }
  (BaseSize:$03;AsmName:'OR';       AsmName66h:'';         AsmName0Fh:'';Param:True),        { [0Dh] OR AX,jjkk }
  (BaseSize:$01;AsmName:'PUSH CS';  AsmName66h:'';         AsmName0Fh:'';Param:False),       { [0Eh] PUSH CS }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [0Fh] Inutilise }
  (BaseSize:$02;AsmName:'ADC';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [10h] ADC }
  (BaseSize:$02;AsmName:'ADC';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [11h] ADC }
  (BaseSize:$02;AsmName:'ADC';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [12h] ADC }
  (BaseSize:$02;AsmName:'ADC';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [13h] ADC }
  (BaseSize:$02;AsmName:'ADC';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [14h] ADC AL,kk }
  (BaseSize:$03;AsmName:'ADC';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [15h] ADC AX,jjkk }
  (BaseSize:$01;AsmName:'PUSH SS';  AsmName66h:'';         AsmName0Fh:'';Param:False),       { [16h] PUSH SS }
  (BaseSize:$01;AsmName:'POP SS';   AsmName66h:'';         AsmName0Fh:'';Param:False),       { [17h] POP SS }
  (BaseSize:$02;AsmName:'SBB';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [18h] SBB }
  (BaseSize:$02;AsmName:'SBB';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [19h] SBB }
  (BaseSize:$02;AsmName:'SBB';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [1Ah] SBB }
  (BaseSize:$02;AsmName:'SBB';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [1Bh] SBB }
  (BaseSize:$02;AsmName:'SBB';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [1Ch] SBB AL,kk }
  (BaseSize:$03;AsmName:'SBB';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [1Dh] SBB AX,jjkk }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [1Eh] PUSH DS }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [1Fh] POP DS }
  (BaseSize:$02;AsmName:'AND';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [20h] AND }
  (BaseSize:$02;AsmName:'AND';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [21h] AND }
  (BaseSize:$02;AsmName:'AND';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [22h] AND }
  (BaseSize:$02;AsmName:'AND';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [23h] AND }
  (BaseSize:$02;AsmName:'AND';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [24h] AND AL,kk }
  (BaseSize:$03;AsmName:'AND';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [25h] AND AX,jjkk }
  (BaseSize:$01;AsmName:'ES:';      AsmName66h:'';         AsmName0Fh:'';Param:False),       { [26h] ES: }
  (BaseSize:$01;AsmName:'DAA';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [27h] DAA }
  (BaseSize:$02;AsmName:'SUB';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [28h] SUB }
  (BaseSize:$02;AsmName:'SUB';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [29h] SUB }
  (BaseSize:$02;AsmName:'SUB';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [2Ah] SUB }
  (BaseSize:$02;AsmName:'SUB';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [2Bh] SUB }
  (BaseSize:$02;AsmName:'SUB';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [2Ch] SUB AL,kk }
  (BaseSize:$03;AsmName:'SUB';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [2Dh] SUB AX,jjkk }
  (BaseSize:$01;AsmName:'CS:';      AsmName66h:'';         AsmName0Fh:'';Param:False),       { [2Eh] CS: }
  (BaseSize:$01;AsmName:'DAS';      AsmName66h:'';         AsmName0Fh:'';Param:False),       { [2Fh] DAS }
  (BaseSize:$02;AsmName:'XOR';      AsmName66h:'';         AsmName0Fh:'WRMSR';Param:True),   { [30h] XOR }
  (BaseSize:$02;AsmName:'XOR';      AsmName66h:'';         AsmName0Fh:'RDTSC';Param:True),   { [31h] XOR }
  (BaseSize:$02;AsmName:'XOR';      AsmName66h:'';         AsmName0Fh:'RDMSR';Param:True),   { [32h] XOR }
  (BaseSize:$02;AsmName:'XOR';      AsmName66h:'';         AsmName0Fh:'RDPMC';Param:True),   { [33h] XOR }
  (BaseSize:$02;AsmName:'XOR';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [34h] XOR AL,kk }
  (BaseSize:$03;AsmName:'XOR';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [35h] XOR AX,jjkk }
  (BaseSize:$01;AsmName:'SS:';      AsmName66h:'';         AsmName0Fh:'';Param:False),       { [36h] SS: }
  (BaseSize:$01;AsmName:'AAA';      AsmName66h:'';         AsmName0Fh:'';Param:False),       { [37h] AAA }
  (BaseSize:$02;AsmName:'CMP';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [38h] CMP }
  (BaseSize:$02;AsmName:'CMP';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [39h] CMP }
  (BaseSize:$02;AsmName:'CMP';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [3Ah] CMP }
  (BaseSize:$02;AsmName:'CMP';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [3Bh] CMP }
  (BaseSize:$02;AsmName:'CMP';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [3Ch] CMP AL,kk }
  (BaseSize:$03;AsmName:'CMP';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [3Dh] CMP AX,jjkk }
  (BaseSize:$01;AsmName:'DS:';      AsmName66h:'';         AsmName0Fh:'';Param:False),       { [3Eh] DS: }
  (BaseSize:$01;AsmName:'AAS';      AsmName66h:'';         AsmName0Fh:'';Param:False),       { [3Fh] AAS }
  (BaseSize:$01;AsmName:'INC AX';   AsmName66h:'';         AsmName0Fh:'';Param:False),       { [40h] INC AX }
  (BaseSize:$01;AsmName:'INC CX';   AsmName66h:'';         AsmName0Fh:'';Param:False),       { [41h] INC CX }
  (BaseSize:$01;AsmName:'INC DX';   AsmName66h:'';         AsmName0Fh:'';Param:False),       { [42h] INC DX }
  (BaseSize:$01;AsmName:'INC BX';   AsmName66h:'';         AsmName0Fh:'';Param:False),       { [43h] INC BX }
  (BaseSize:$01;AsmName:'INC SP';   AsmName66h:'';         AsmName0Fh:'';Param:False),       { [44h] INC SP }
  (BaseSize:$01;AsmName:'INC BP';   AsmName66h:'';         AsmName0Fh:'';Param:False),       { [45h] INC BP }
  (BaseSize:$01;AsmName:'INC SI';   AsmName66h:'';         AsmName0Fh:'';Param:False),       { [46h] INC SI }
  (BaseSize:$01;AsmName:'INC DI';   AsmName66h:'';         AsmName0Fh:'';Param:False),       { [47h] INC DI }
  (BaseSize:$01;AsmName:'DEC AX';   AsmName66h:'';         AsmName0Fh:'';Param:False),       { [48h] DEC AX }
  (BaseSize:$01;AsmName:'DEC CX';   AsmName66h:'';         AsmName0Fh:'';Param:False),       { [49h] DEC CX }
  (BaseSize:$01;AsmName:'DEC DX';   AsmName66h:'';         AsmName0Fh:'';Param:False),       { [4Ah] DEC DX }
  (BaseSize:$01;AsmName:'DEC BX';   AsmName66h:'';         AsmName0Fh:'';Param:False),       { [4Bh] DEC BX }
  (BaseSize:$01;AsmName:'DEC SP';   AsmName66h:'';         AsmName0Fh:'';Param:False),       { [4Ch] DEC SP }
  (BaseSize:$01;AsmName:'DEC BP';   AsmName66h:'';         AsmName0Fh:'';Param:False),       { [4Dh] DEC BP }
  (BaseSize:$01;AsmName:'DEC SI';   AsmName66h:'';         AsmName0Fh:'';Param:False),       { [4Eh] DEC SI }
  (BaseSize:$01;AsmName:'DEC DI';   AsmName66h:'';         AsmName0Fh:'';Param:False),       { [4Fh] DEC DI }
  (BaseSize:$01;AsmName:'PUSH AX';  AsmName66h:'';         AsmName0Fh:'';Param:False),       { [50h] PUSH AX }
  (BaseSize:$01;AsmName:'PUSH CX';  AsmName66h:'';         AsmName0Fh:'';Param:False),       { [51h] PUSH CX }
  (BaseSize:$01;AsmName:'PUSH DX';  AsmName66h:'';         AsmName0Fh:'';Param:False),       { [52h] PUSH DX }
  (BaseSize:$01;AsmName:'PUSH BX';  AsmName66h:'';         AsmName0Fh:'';Param:False),       { [53h] PUSH BX }
  (BaseSize:$01;AsmName:'PUSH SP';  AsmName66h:'';         AsmName0Fh:'';Param:False),       { [54h] PUSH SP }
  (BaseSize:$01;AsmName:'PUSH BP';  AsmName66h:'';         AsmName0Fh:'';Param:False),       { [55h] PUSH BP }
  (BaseSize:$01;AsmName:'PUSH SI';  AsmName66h:'';         AsmName0Fh:'';Param:False),       { [56h] PUSH SI }
  (BaseSize:$01;AsmName:'PUSH DI';  AsmName66h:'';         AsmName0Fh:'';Param:False),       { [57h] PUSH DI }
  (BaseSize:$01;AsmName:'POP AX';   AsmName66h:'';         AsmName0Fh:'';Param:False),       { [58h] POP AX }
  (BaseSize:$01;AsmName:'POP CX';   AsmName66h:'';         AsmName0Fh:'';Param:False),       { [59h] POP CX }
  (BaseSize:$01;AsmName:'POP DX';   AsmName66h:'';         AsmName0Fh:'';Param:False),       { [5Ah] POP DX }
  (BaseSize:$01;AsmName:'POP BX';   AsmName66h:'';         AsmName0Fh:'';Param:False),       { [5Bh] POP BX }
  (BaseSize:$01;AsmName:'POP SP';   AsmName66h:'';         AsmName0Fh:'';Param:False),       { [5Ch] POP SP }
  (BaseSize:$01;AsmName:'POP BP';   AsmName66h:'';         AsmName0Fh:'';Param:False),       { [5Dh] POP BP }
  (BaseSize:$01;AsmName:'POP SI';   AsmName66h:'';         AsmName0Fh:'';Param:False),       { [5Eh] POP SI }
  (BaseSize:$01;AsmName:'POP DI';   AsmName66h:'';         AsmName0Fh:'';Param:False),       { [5Fh] POP DI }
  (BaseSize:$01;AsmName:'PUSHA';    AsmName66h:'PUSHAD';   AsmName0Fh:'';Param:False),       { [60h] PUSHA }
  (BaseSize:$01;AsmName:'POPA';     AsmName66h:'POPAD';    AsmName0Fh:'';Param:False),       { [61h] POPA }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [62h] BOUND }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [63h] ARPL }
  (BaseSize:$01;AsmName:'FS:';      AsmName66h:'';         AsmName0Fh:'';Param:False),       { [64h] FS: }
  (BaseSize:$01;AsmName:'GS:';      AsmName66h:'';         AsmName0Fh:'';Param:False),       { [65h] GS: }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [66h] 386... }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [67h] 386... }
  (BaseSize:$03;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [68h] PUSH Immediat Word }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [69h] IMUL }
  (BaseSize:$02;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [6Ah] PUSH Immediat Byte }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [6Bh] IMUL }
  (BaseSize:$01;AsmName:'INSB';     AsmName66h:'';         AsmName0Fh:'';Param:False),       { [6Ch] INSB }
  (BaseSize:$01;AsmName:'INSW';     AsmName66h:'INSD';     AsmName0Fh:'';Param:False),       { [6Dh] INSW }
  (BaseSize:$01;AsmName:'OUTSB';    AsmName66h:'';         AsmName0Fh:'';Param:False),       { [6Eh] OUTSB }
  (BaseSize:$01;AsmName:'OUTSW';    AsmName66h:'OUTSD';    AsmName0Fh:'';Param:False),       { [6Fh] OUTSW }
  (BaseSize:$02;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [70h] }
  (BaseSize:$02;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [71h] }
  (BaseSize:$02;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [72h] }
  (BaseSize:$02;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [73h] }
  (BaseSize:$02;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [74h] }
  (BaseSize:$02;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [75h] }
  (BaseSize:$02;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [76h] }
  (BaseSize:$02;AsmName:'';         AsmName66h:'';         AsmName0Fh:'EMMS';Param:True),    { [77h] }
  (BaseSize:$02;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [78h] }
  (BaseSize:$02;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [79h] }
  (BaseSize:$02;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [7Ah] }
  (BaseSize:$02;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [7Bh] }
  (BaseSize:$02;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [7Ch] }
  (BaseSize:$02;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [7Dh] }
  (BaseSize:$02;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [7Eh] }
  (BaseSize:$02;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [7Fh] }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [80h] }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [81h] }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [82h] }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [83h] }
  (BaseSize:$02;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [84h] TEST }
  (BaseSize:$02;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [85h] TEST }
  (BaseSize:$02;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [86h] XCHG }
  (BaseSize:$02;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [87h] XCHG }
  (BaseSize:$02;AsmName:'MOV';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [88h] MOV }
  (BaseSize:$02;AsmName:'MOV';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [89h] MOV }
  (BaseSize:$02;AsmName:'MOV';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [8Ah] MOV }
  (BaseSize:$02;AsmName:'MOV';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [8Bh] MOV }
  (BaseSize:$02;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [8Ch] MOV [],ES }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [8Dh] }
  (BaseSize:$02;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [8Eh] }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [8Fh] }
  (BaseSize:$01;AsmName:'NOP';      AsmName66h:'';         AsmName0Fh:'';Param:False),       { [90h] NOP }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [91h] }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [92h] }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [93h] }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [94h] }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [95h] }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [96h] }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [97h] }
  (BaseSize:$01;AsmName:'CBW';      AsmName66h:'CDWE';     AsmName0Fh:'';Param:True),        { [98h] }
  (BaseSize:$01;AsmName:'CWD';      AsmName66h:'CDQ';      AsmName0Fh:'';Param:True),        { [99h] }
  (BaseSize:$05;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [9Ah] CALL FAR iijj:kkll }
  (BaseSize:$01;AsmName:'WAIT';     AsmName66h:'';         AsmName0Fh:'';Param:True),        { [9Bh] }
  (BaseSize:$01;AsmName:'PUSHF';    AsmName66h:'PUSHFD';   AsmName0Fh:'';Param:True),        { [9Ch] }
  (BaseSize:$01;AsmName:'POPF';     AsmName66h:'POPFD';    AsmName0Fh:'';Param:True),        { [9Dh] }
  (BaseSize:$01;AsmName:'SAHF';     AsmName66h:'';         AsmName0Fh:'';Param:True),        { [9Eh] }
  (BaseSize:$01;AsmName:'LAHF';     AsmName66h:'';         AsmName0Fh:'';Param:True),        { [9Fh] }
  (BaseSize:$03;AsmName:'';         AsmName66h:'';         AsmName0Fh:'PUSH FS';Param:True), { [A0h] }
  (BaseSize:$03;AsmName:'';         AsmName66h:'';         AsmName0Fh:'POP FS';Param:True),  { [A1h] }
  (BaseSize:$03;AsmName:'';         AsmName66h:'';         AsmName0Fh:'CPUID';Param:True),   { [A2h] MOV [iijj],AL }
  (BaseSize:$03;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [A3h] }
  (BaseSize:$01;AsmName:'MOVSB';    AsmName66h:'';         AsmName0Fh:'';Param:False),       { [A4h] MOVSB }
  (BaseSize:$01;AsmName:'MOVSW';    AsmName66h:'MOVSD';    AsmName0Fh:'';Param:False),       { [A5h] MOVSW }
  (BaseSize:$01;AsmName:'CMPSB';    AsmName66h:'';         AsmName0Fh:'';Param:False),       { [A6h] CMPSB }
  (BaseSize:$01;AsmName:'CMPSD';    AsmName66h:'CMPSD';    AsmName0Fh:'';Param:False),       { [A7h] CMPSW }
  (BaseSize:$02;AsmName:'';         AsmName66h:'';         AsmName0Fh:'PUSH GS';Param:True), { [A8h] TEST AL,ii }
  (BaseSize:$03;AsmName:'';         AsmName66h:'';         AsmName0Fh:'POP GS';Param:True),  { [A9h] TEST AX,iijj }
  (BaseSize:$01;AsmName:'STOSB';    AsmName66h:'';         AsmName0Fh:'RSM';Param:False),    { [AAh] STOSB }
  (BaseSize:$01;AsmName:'STOSW';    AsmName66h:'STOSD';    AsmName0Fh:'';Param:False),       { [ABh] STOSW }
  (BaseSize:$01;AsmName:'LODSB';    AsmName66h:'';         AsmName0Fh:'';Param:False),       { [ACh] LODSB }
  (BaseSize:$01;AsmName:'LODSW';    AsmName66h:'LODSD';    AsmName0Fh:'';Param:False),       { [ADh] LODSW }
  (BaseSize:$01;AsmName:'SCASB';    AsmName66h:'';         AsmName0Fh:'';Param:False),       { [AEh] SCASB }
  (BaseSize:$01;AsmName:'SCASW';    AsmName66h:'SCASD';    AsmName0Fh:'';Param:False),       { [AFh] SCASW }
  (BaseSize:$02;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [B0h] }
  (BaseSize:$02;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [B1h] }
  (BaseSize:$02;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [B2h] }
  (BaseSize:$02;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [B3h] }
  (BaseSize:$02;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [B4h] }
  (BaseSize:$02;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [B5h] }
  (BaseSize:$02;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [B6h] }
  (BaseSize:$02;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [B7h] }
  (BaseSize:$03;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [B8h] MOV AX,jjkk }
  (BaseSize:$03;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [B9h] MOV CX,jjkk }
  (BaseSize:$03;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [BAh] MOV DX,jjkk }
  (BaseSize:$03;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [BBh] MOV BX,jjkk }
  (BaseSize:$03;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [BCh] MOV SP,jjkk }
  (BaseSize:$03;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [BDh] MOV BP,jjkk }
  (BaseSize:$03;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [BEh] MOV SI,jjkk }
  (BaseSize:$03;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [BFh] MOV DI,jjkk }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [C0h] }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [C1h] }
  (BaseSize:$03;AsmName:'RETN ';    AsmName66h:'';         AsmName0Fh:'';Param:True),        { [C2h] RETN iijj }
  (BaseSize:$01;AsmName:'RETN';     AsmName66h:'';         AsmName0Fh:'';Param:False),       { [C3h] RETN }
  (BaseSize:$02;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [C4h] LES }
  (BaseSize:$02;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [C5h] LDS }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [C6h] MOV }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [C7h] MOV }
  (BaseSize:$04;AsmName:'ENTER ';   AsmName66h:'';         AsmName0Fh:'';Param:True),        { [C8h] ENTER }
  (BaseSize:$01;AsmName:'LEAVE';    AsmName66h:'';         AsmName0Fh:'';Param:True),        { [C9h] }
  (BaseSize:$03;AsmName:'RETF ';    AsmName66h:'';         AsmName0Fh:'';Param:True),        { [CAh] }
  (BaseSize:$01;AsmName:'RETF';     AsmName66h:'';         AsmName0Fh:'';Param:True),        { [CBh] }
  (BaseSize:$01;AsmName:'INT 03h';  AsmName66h:'';         AsmName0Fh:'';Param:True),        { [CCh] }
  (BaseSize:$02;AsmName:'INT ';     AsmName66h:'';         AsmName0Fh:'';Param:True),        { [CDh] }
  (BaseSize:$01;AsmName:'INTO';     AsmName66h:'';         AsmName0Fh:'';Param:True),        { [CEh] }
  (BaseSize:$01;AsmName:'IRET';     AsmName66h:'IRETD';    AsmName0Fh:'';Param:True),        { [CFh] }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [D0h] }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [D1h] }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [D2h] }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [D3h] }
  (BaseSize:$02;AsmName:'AAM';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [D4h] }
  (BaseSize:$02;AsmName:'AAD';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [D5h] AAD,... }
  (BaseSize:$01;AsmName:'SETALC';   AsmName66h:'';         AsmName0Fh:'';Param:True),        { [D6h] }
  (BaseSize:$01;AsmName:'XLAT';     AsmName66h:'';         AsmName0Fh:'';Param:True),        { [D7h] }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [D8h] }
  (BaseSize:$02;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [D9h] Float... }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [DAh] }
  (BaseSize:$02;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [DBh] Float... }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [DCh] }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [DDh] }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [DEh] }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [DFh] }
  (BaseSize:$02;AsmName:'LOOPNZ';   AsmName66h:'';         AsmName0Fh:'';Param:True),        { [E0h] LOOPNZ ii }
  (BaseSize:$02;AsmName:'LOOPZ';    AsmName66h:'';         AsmName0Fh:'';Param:True),        { [E1h] LOOPZ ii }
  (BaseSize:$02;AsmName:'LOOP';     AsmName66h:'';         AsmName0Fh:'';Param:True),        { [E2h] LOOP ii }
  (BaseSize:$02;AsmName:'JCXZ';     AsmName66h:'JECXZ';    AsmName0Fh:'';Param:True),        { [E3h] JCXZ ii }
  (BaseSize:$02;AsmName:'IN';       AsmName66h:'';         AsmName0Fh:'';Param:True),        { [E4h] IN AL,ii }
  (BaseSize:$02;AsmName:'IN';       AsmName66h:'';         AsmName0Fh:'';Param:True),        { [E5h] IN AX,ii }
  (BaseSize:$02;AsmName:'OUT';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [E6h] OUT AL,ii }
  (BaseSize:$02;AsmName:'OUT';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [E7h] OUT AX,ii }
  (BaseSize:$03;AsmName:'CALL ';    AsmName66h:'';         AsmName0Fh:'';Param:True),        { [E8h] CALL $+jjkk }
  (BaseSize:$03;AsmName:'JMP';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [E9h] JMP $+jjkk }
  (BaseSize:$05;AsmName:'JMP FAR';  AsmName66h:'';         AsmName0Fh:'';Param:True),        { [EAh] JMP FAR iijj:kkll }
  (BaseSize:$02;AsmName:'JMP';      AsmName66h:'';         AsmName0Fh:'';Param:True),        { [EBh] JMP ii }
  (BaseSize:$01;AsmName:'IN AL,DX'; AsmName66h:'';         AsmName0Fh:'';Param:True),        { [ECh] }
  (BaseSize:$01;AsmName:'IN AX,DX'; AsmName66h:'IN EAX,DX';AsmName0Fh:'';Param:True),        { [EDh] }
  (BaseSize:$01;AsmName:'OUT DX,AL';AsmName66h:'';         AsmName0Fh:'';Param:True),        { [EEh] }
  (BaseSize:$01;AsmName:'OUT DX,';  AsmName66h:'';         AsmName0Fh:'';Param:True),        { [EFh] }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [F0h] LOCK ? }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [F1h] }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [F2h] }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [F3h] }
  (BaseSize:$01;AsmName:'HLT';      AsmName66h:'';         AsmName0Fh:'';Param:False),       { [F4h] HLT }
  (BaseSize:$01;AsmName:'CMC';      AsmName66h:'';         AsmName0Fh:'';Param:False),       { [F5h] CMC }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [F6h] }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [F7h] }
  (BaseSize:$01;AsmName:'CLC';      AsmName66h:'';         AsmName0Fh:'';Param:False),       { [F8h] CLC }
  (BaseSize:$01;AsmName:'STC';      AsmName66h:'';         AsmName0Fh:'';Param:False),       { [F9h] STC }
  (BaseSize:$01;AsmName:'CLI';      AsmName66h:'';         AsmName0Fh:'';Param:False),       { [FAh] CLI }
  (BaseSize:$01;AsmName:'STI';      AsmName66h:'';         AsmName0Fh:'';Param:False),       { [FBh] STI }
  (BaseSize:$01;AsmName:'CLD';      AsmName66h:'';         AsmName0Fh:'';Param:False),       { [FCh] CLD }
  (BaseSize:$01;AsmName:'STD';      AsmName66h:'';         AsmName0Fh:'';Param:False),       { [FDh] STD }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True),        { [FEh] }
  (BaseSize:$01;AsmName:'';         AsmName66h:'';         AsmName0Fh:'';Param:True)         { [FFh] }
 );

Type
 TByte=Array[0..65519]of Byte;

Var
 CommandFound,Terminated:Boolean;
 CurrProgName:String;
 CmdStr:String;
 CurrCommand,ParamList:String;
 I,J:Byte;
 StartPointer:Word;
 Sector:^TByte;
 SizeSector:Word;

Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
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

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function GetHex(S:String;Var Result:Word):Boolean;
Var
 i,j,k:Integer;
Begin
 GetHex:=False;j:=0;Result:=0;
 For i:=1to Length(S)do Begin
  If S[i]>' 'Then begin
   If Not(S[I]in['0'..'9','A'..'F'])Then Exit;
   If S[i]>'9'Then S[i]:=Char(Byte(S[i])-7);
   Result:=(Result shl 4)+(Byte(S[i])and $f);
   Inc(j);
  End;
 End;
 If j>0Then GetHex:=True;
End;

Procedure ExtractCommand;
Var
 I:Byte;
Begin
 For I:=1 to Length(CmdStr)do Begin
  If Not(CmdStr[I]in['A'..'Z','a'..'z','_','-','0'..'9'])Then Begin
   CurrCommand:=StrToUpper(Copy(CmdStr,1,I-1));
   ParamList:=TrimL(Copy(CmdStr,I,255));
   Exit;
  End;
 End;
 CurrCommand:=StrToUpper(CmdStr);
 ParamList:='';
End;

Function ExtractParam(Index:Byte):String;
Var
 Count:Word;
 LocalIndex:Word;
 l:Byte;
 Temp:String;
Begin
 Temp:='';Count:=1;LocalIndex:=1;l:=0;
 While Count<=Length(ParamList)do Begin
  If Not(ParamList[Count] in [' ',#9])then Begin
   If LocalIndex=Index Then Begin
    While (Count<=Length(ParamList)) and (Not(ParamList[count] in[' ',#9])) and (l < 256) do Begin
     Temp:=Temp+ParamList[count];
     Inc(l);
     Inc(Count);
    end;
    Temp[0]:=Char(l);
    ExtractParam:=Temp;
    Exit;
   End;
   While (Count<=Length(ParamList)) and (Not(ParamList[count] in [' ',#9])) do Inc(Count);
   Inc(LocalIndex);
  End;
  If Count>=Length(ParamList)Then Break;
  Inc(Count);
 End;
 ExtractParam:=Temp;
End;

Function ByteHex2Str(value:Byte):String;
Const
 matrix:Array[0..15]of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
 ByteHex2Str:=matrix[(value shr 4) and $0F]+matrix[value and $F];
End;

Function HexWord2Str(value:Word):String;Begin
 HexWord2Str:=ByteHex2Str(Hi(value))+ByteHex2Str(Lo(value));
End;


Function HexByte(X:Byte):String;Begin
 HexByte:=ByteHex2Str(X)+'h';
End;

Function HexWord(X:Word):String;Begin
 HexWord:=HexWord2Str(X)+'h';
End;

Function HalfWord(I:Byte):String;Near;
Var
 W:Word;
Begin
 If I<$80Then W:=0
         Else W:=$FF00;
 W:=W or I;
 HalfWord:=HexWord(W);
End;

Function Decode(Var Buf;Var I:Word):String;
Label
 ReStart,Rep,99,_999,Xit;
Var
 T:Array[0..65520] of Byte Absolute Buf;
 CurrCode,X2,X3:Byte;
 S:String;
 XSeg,Prefix:Byte;
 X386,Wd:Boolean;
 PS,OldPS:^String;

 Procedure DB;Begin
  If Chr(CurrCode)in[' ','A'..'z']Then S:='DB '''+Chr(CurrCode)+''''
   Else
  Begin
   S:='DB '+HexByte(CurrCode);
  End;
 End;

 Function TWd(X:Word):Word;Begin
  TWd:=T[X]+T[X+1]*256;
 End;

 Function SegS:String;Begin
  Case(XSeg)of
   ciCS:SegS:='CS:';
   ciDS:SegS:='DS:';
   ciES:SegS:='ES:';
   ciFS:SegS:='FS:';
   ciGS:SegS:='GS:';
   ciSS:SegS:='SS:';
   Else SegS:='';
  End;
 End;

 Function JmpAddr:String;Begin
  If T[I+1]>$7FThen JmpAddr:=HexWord(I-($100-2-T[I+1]))
               Else JmpAddr:=HexWord(I+2+T[I+1]);
 End;

 Function OfsByte:String;Begin
  If T[I]>=$7FThen OfsByte:='-'+HexByte($100-T[I])
              Else OfsByte:='+'+HexByte(T[I]);
 End;

 Function OfsWord:String;Begin
  If T[I]>$7FFFThen OfsWord:='-'+HexWord($10000-TWd(I))
               Else OfsWord:='+'+HexWord(TWd(I));
 End;

 Function RegxWord(I:Byte):String;Begin
  If(X386)Then RegxWord:='E'+RegWord[I]
          Else RegxWord:=RegWord[I];
 End;

 Function D:String;Begin
  If(X386)Then D:='D'
          Else D:=''
 End;

 Function LoadAddr:String;
 Const
  SAddr:Array[0..7]of String[7]=(
   '[BX+SI]',
   '[BX+DI]',
   '[BP+SI]',
   '[BP+DI]',
   '[SI]',
   '[DI]',
   '[BP]',
   '[BX]'
  );
 Var
  S:String;
  X2:Byte;
 Begin
  S:=SegS+SAddr[T[I+1]and$7];
  X2:=(T[I+1]shr 3)and 7;
  If(CurrCode>=$FE)and(X2 in[2..5])Then LoadAddr:=PrcS[X2 and 1]+S
   Else
  Begin
   S:=PtrS[CurrCode and 1]+S;
   If Boolean(CurrCode and 1)Then S:=D+S;
   LoadAddr:=S;
  End;
 End;

 Function WordAddr:String;Begin
  WordAddr:=SegS+'['+HexWord(TWd(I+1))+']'
 End;

 Function XtrkAddr:String;
 Var
  S:String;
 Begin
  S:=LoadAddr;
  Case T[I+1]of
   0..$3F:Inc(I);
   $40..$7F:Begin
    S:=Copy(S,1,Length(S)-1);
    Inc(I,2);
    S:=S+OfsByte+']';
   End;
   Else Begin { 80h . BFh }
    S:=Copy(S,1,Length(S)-1);
    Inc(I,2);
    S:=S+OfsWord;
    Inc(I);
    S:=S+']';
   End;
  End;
  XtrkAddr:=S;
 End;

 Var First:Boolean;

 Function Register:String;
 Label 1;
 Var
  T2:Byte;
 Begin
  T2:=T[I+1];
  If CurrCode=$8EThen Begin
   If(First)Then Begin
    Register:=RegS[(T2 and$3F)shr 3];
    First:=False;
    Exit;
   End;
   Goto 1;
  End
   Else
  If CurrCode=$8CThen Begin
   If Not(First)Then Begin
    Register:=RegS[(T2 and$3F)shr 3];
    First:=True;
    Exit;
   End;
 1:Register:=RegxWord(T2 and 7)
  End
   Else
  Begin
   If CurrCode in[$E4..$E7]Then T2:=0;
   Case(T2)of
    $40..$7F:T2:=(T2 and$3F)shr 3;
    $C0..$FF:Begin
     If(First=True)Then T2:=T2 and 7
                   Else T2:=(T2 and$3F)shr 3;
     First:=False;
    End;
    Else T2:=(T2 shr 3)and 7;
   End;
   If CurrCode and 1=1Then Register:=RegxWord(T2)
                      Else Register:=RegByte[T2];
  End;
 End;

 Function XtrkStandard:String;
 Label Swp;
 Var
  R,S:String;
  Wd:Boolean;
  Reg:Byte;
 Begin
  Wd:=Boolean(CurrCode and 1);
  Case T[I+1]of
   $06:Reg:=0;
   $0E:Reg:=1;
   $16:Reg:=2;
   $1E:Reg:=3;
   $26:Reg:=4;
   $2E:Reg:=5;
   $36:Reg:=6;
   $3E:Reg:=7;
   $40..$7F:Begin
    S:=XtrkAddr;
    Dec(I,2);
    R:=Register;
    Inc(I);
    Goto Swp;
   End;
   $C0..$FF:Begin
    XtrkStandard:=Register+','+Register;
    Exit;
   End;
   Else Begin
    R:=Register;
    S:=LoadAddr;
    Goto Swp;
   End;
  End;
  If T[I+1]in[$06,$0E,$16,$1E,$26,$2E,$36,$3E]Then Begin
   If CurrCode in[$8C,$8E]Then Begin
    R:=RegS[Reg and 3];
    Wd:=True;
   End
    Else
   If(Wd)Then R:=RegxWord(Reg)
         Else R:=RegByte[Reg];
   Inc(I,2);
   S:=PtrS[Byte(Wd)]+SegS+'[';
   S:=S+HexWord(TWd(I))+']';
Swp:If CurrCode and 2=0Then XtrkStandard:=S+','+R
                       Else XtrkStandard:=R+','+S;
  End;
 End;

 Function _286A:String;Begin
  If T[I]and 1=1Then _286A:=RegxWord(0)+','+HexWord(TWd(I+1))
                Else _286A:='AL,'+HexByte(T[I+1])
 End;

 Procedure UpDateBasHome(CurrCode:Byte);Begin
  If CurrCode>=$88Then S:='MOV'
                  Else S:=BasS[CurrCode];
  S:=S+' ';
 End;

Begin
 First:=True;Prefix:=0;XSeg:=0;X386:=False;
ReStart:
 CurrCode:=T[I];
 PS:=@Instr80x86[CurrCode].AsmName;
 OldPS:=PS;
 If(X386)Then Begin
  PS:=@Instr80x86[CurrCode].AsmName66h;
  If PS^=''Then PS:=@Instr80x86[CurrCode].AsmName;
 End;
 S:=PS^;
 Case(CurrCode)of
    $00,$01,$02,$03,$04,$05,$08,$09,$0A,$0B,$0C,$0D,
    $10,$11,$12,$13,$14,$15,$18,$19,$1A,$1B,$1C,$1D,
    $20,$21,$22,$23,$24,$25,$28,$29,$2A,$2B,$2C,$2D,
    $30,$31,$32,$33,$34,$35,$38,$39,$3A,$3B,$3C,$3D,
    $88,$89,$8A,$8B:Begin
     If CurrCode>=$88Then UpDateBasHome(CurrCode)
                     Else UpDateBasHome(CurrCode shr 3);
     If CurrCode and 7>3Then S:=S+_286A
                        Else S:=S+XtrkStandard;
     Goto Xit;
    End;
    $06,$07,$0E,$16,$1E,$1F:Begin
     S:=RegS[CurrCode shr 3];
     Case CurrCode and$7of
      6:S:='PUSH '+S;
      7:S:='POP '+S;
     End;
     Goto Xit;
    End;
    $0F,$17:Begin
     PS:=@Instr80x86[CurrCode].AsmName0Fh;
     If PS^=''Then DB
              Else S:=PS^;
     S:=RegxWord(CurrCode and 7);
     If CurrCode and 8=8Then S:='DEC '+S
                        Else S:='INC '+S;
     Goto Xit;
    End;
    $26:Goto _999;
    $27:Goto Xit;
    $2E:Goto _999;
    $2F:Goto Xit;
    $36:Goto _999;
    $37:Goto Xit;
    $3E:Goto _999;
    $3F:Goto Xit;
    $40,$41,$42,$43,$44,$45,$46,$47,$48,$49,$4A,$4B,$4C,$4D,$4E,$4F:Begin
     S:=RegxWord(CurrCode and 7);
     If CurrCode and 8=8Then S:='DEC '+S
                        Else S:='INC '+S;
     Goto Xit;
    End;
    $50,$51,$52,$53,$54,$55,$56,$57:Begin
     S:='PUSH '+RegxWord(CurrCode and 7);
     Goto Xit;
    End;
    $58,$59,$5A,$5B,$5C,$5D,$5E,$5F:Begin
     S:='POP '+RegxWord(CurrCode and 7);
     Goto Xit;
    End;
    $60:Goto Xit;
    $61:Goto Xit;
    $62,$63,$67,$69,$6B,$8F,$D8,$DA,$DC,$DD,$DE,$DF,$F1:Begin
     DB;
     Goto Xit;
    End;
    $64:Goto _999;
    $65:Goto _999;
    $66:Begin
     X386:=True;Inc(I);
     Goto Restart;
    End;
    $68:Begin
     S:='PUSH '+HexWord(TWd(I+1));
     Goto Xit;
    End;
    $6A:Begin
     S:='PUSH '+HexWord(T[I+1]);
     Goto Xit;
    End;
    $6C:Goto Xit;
    $6D:Goto Xit;
    $6E:Goto Xit;
    $6F:Goto Xit;
    $70,$71,$72,$73,$74,$75,$76,$77,$78,$79,$7A,$7B,$7C,$7D,$7E,$7F:Begin
     S:='J'+FlgS[CurrCode and$F]+' '+JmpAddr;
    End;
    $80,$81,$82,$83:Begin
     X2:=T[I+1];
     UpDateBasHome((X2 and$3F)shr 3);
     Wd:=Boolean(CurrCode and 1);
     Case(X2)of
      $C0..$FF:Begin
       S:=S+Register+',';
       If CurrCode and 2=2Then Begin
        Inc(I,2);
        S:=S+HalfWord(T[I]);
       End
        Else
       Begin
        If(Wd)Then Begin
         Inc(I,2);
         S:=S+HexWord(TWd(I));
        End
         Else
        S:=S+HexByte(T[I+2]);
        Inc(I)
       End
      End;
      Else Begin
       S:=S+XtrkAddr+',';
       Inc(I);
       If CurrCode and 2=2Then S:=S+HalfWord(T[I]) Else
       If(Wd)Then Begin
        S:=S+HexWord(TWd(I));
        Inc(I)
       End
        Else
       S:=S+HexByte(T[I]);
      End;
     End;
     Goto Xit;
    End;
    $84,$85:Begin
     S:='TEST '+XtrkStandard;
     Goto Xit;
    End;
    $86,$87:Begin
     S:='XCHG '+XtrkStandard;
     Goto Xit;
    End;
    $8D:Begin
     Case T[I+1]of
      $40..$BF:S:='LEA '+RegxWord(T[I+1]and 7)+','+XtrkAddr;
      Else S:='DW '+HexWord(TWd(I));
     End;
     Goto Xit;
    End;
    $8C,$8E:Begin
     UpDateBasHome(CurrCode);
     S:=S+XtrkStandard;
     Goto Xit;
    End;
    $90:Goto Xit;
    $91,$92,$93,$94,$95,$96,$97:Begin
     S:='XCHG '+RegxWord(0)+','+RegxWord(CurrCode and$7);
     Goto Xit;
    End;
    $98:Goto Xit;
    $99:Goto Xit;
    $9A:Begin
     S:='CALL '+HexWord(TWd(I+3))+':'+HexWord(TWd(I+1));
     Goto Xit;
    End;
    $9B:Goto Xit;
    $9C:Goto Xit;
    $9D:Goto Xit;
    $9E:Goto Xit;
    $9F:Goto Xit;
    $A0,$A1,$A2,$A3:Begin
     UpDateBasHome(CurrCode);
     If CurrCode and 2=2Then Begin
      S:=S+WordAddr+',';
      If Boolean(CurrCode and 1)Then S:=S+RegxWord(0)
                                Else S:=S+RegByte[0];
     End
      Else
     Begin
      If Boolean(CurrCode and 1)Then S:=S+RegxWord(0)
                                Else S:=S+RegByte[0];
      S:=S+','+WordAddr;
     End;
     Goto Xit;
    End;
    $A4:Goto Xit;
    $A5:Goto Xit;
    $A6:Goto Xit;
    $A7:Goto Xit;
    $A8,$A9:Begin
     S:='TEST '+_286A;
     Goto Xit;
    End;
    $AA:Goto Xit;
    $AB:Goto Xit;
    $AC:Goto Xit;
    $AD:Goto Xit;
    $AE:Goto Xit;
    $AF:Goto Xit;
    $B0,$B1,$B2,$B3,$B4,$B5,$B6,$B7,$B8,$B9,$BA,$BB,$BC,$BD,$BE,$BF:Begin
     UpDateBasHome(CurrCode);
     If CurrCode and$8=8Then S:=S+RegxWord(CurrCode and 7)+','+HexWord(TWd(I+1))
                        Else S:=S+RegByte[CurrCode and 7]+','+HexByte(T[I+1]);
     Goto Xit;
    End;
    $C0,$C1:Begin
     X2:=T[I+1];
     S:=RotS[(X2 and$3F)shr 3]+' '+Register+',';
     Case(X2)of
      $C0..$FF:Begin
       Inc(I,2);
       S:=S+HexByte(T[I])
      End;
      Else S:=S+XtrkAddr;
     End;
     Goto Xit;
    End;
    $C2:Begin
     S:=S+HexWord(TWd(I+1));
     Goto Xit;
    End;
    $C3:Goto Xit;
    $C4,$C5:Begin
     If Boolean(CurrCode and 1)Then S:='LDS '
                               Else S:='LES ';
     Case T[I+1]of
      $76:Begin
       Inc(I,2);
       S:=S+'SI,'+SegS+'[BP'+OfsByte+']';
       Dec(I);
      End;
      $7E:Begin
       Inc(I,2);
       S:=S+'DI,'+SegS+'[BP'+OfsByte+']';
       Dec(I);
      End;
      $B4:If T[I+2]=$B4Then Begin
       Inc(I,3);
       S:=S+'DI,'+SegS+'[SI'+OfsWord+']';
      End;
      $BE:Begin
       Inc(I,2);
       S:=S+SegS+'[BP'+OfsWord+']';
      End;
      Else S:=S+RegxWord((T[I+1]shr 3)and 7)+','+LoadAddr;
     End;
     Goto Xit;
    End;
    $C6,$C7:Begin
     UpDateBasHome(CurrCode);
     Case T[I+1]of
      $C0..$FF:Begin
       S:=S+Register;
       Inc(I)
      End;
      Else S:=S+XtrkAddr;
     End;
     Inc(I);
     S:=S+',';
     If Boolean(CurrCode and 1)Then Begin
      S:=S+HexWord(TWd(I));
     Inc(I)
     End
      Else
     S:=S+HexByte(T[I]);
     Goto Xit;
    End;
    $C8:Begin
     S:=S+HexWord(TWd(I+1))+','+HexByte(T[I+3]);
     Goto Xit;
    End;
    $C9:Goto Xit;
    $CA:Begin
     S:=S+HexWord(TWd(I+1));
     Goto Xit;
    End;
    $CB:Goto Xit;
    $CC:Goto Xit;
    $CD:Begin
     S:=S+HexByte(T[I+1]);
     Goto Xit;
    End;
    $CE:Goto Xit;
    $CF:Goto Xit;
    $D0,$D1,$D2,$D3:Begin
     Case T[I+1]of
      $C0..$FF:Begin
       S:=RotS[(T[I+1]and$3F)shr 3]+' '+Register+',';
       Inc(I);
       If T[I]and 2=2Then S:=S+RegByte[1]
                     Else S:=S+'1';
      End;
      Else DB;
     End;
     Goto Xit;
    End;
    $D4:Goto Xit;
    $D5:Goto Xit;
    $D6:Goto Xit;
    $D7:Goto Xit;
    $D9:Begin
     Case T[I+1]of
      $D0:S:='FNOP';
      $E0:S:='FCHS';
      $E1:S:='FABS';
      $E2:S:='FCLEX';
      $E4:S:='FTST';
      $E5:S:='FXAM';
      $E8:S:='FLD1';
      $E9:S:='FLDL2T';
      $EA:S:='FLDL2E';
      $EB:S:='FLDPI';
      $EC:S:='FLDLG2';
      $ED:S:='FLDLN2';
      $EE:S:='FLDZ';
      $F1:S:='FYL2X';
      $F2:S:='FPTAN';
      $F3:S:='FPATAN';
      $F4:S:='FXTRACT';
      $F6:S:='FDECSTP';
      $F7:S:='FINCSTP';
      $F8:S:='FPREM';
      $FA:S:='FSQRT';
      $FB:S:='FSINCOS';
      $FC:S:='FRNDINT';
      $FD:S:='FSCALE';
      $FE:S:='FSIN';
      Else DB;
     End;
     Goto Xit;
    End;
    $DB:Begin
     Case T[I+1]of
      $E0:S:='FENI';
      $E1:S:='FDISI';
      $E3:S:='FINIT';
      $E4:S:='FSETPM';
      Else DB;
     End;
     Goto Xit;
    End;
    $E0,$E1,$E2,$E3,$EB:Begin
     S:=S+' '+JmpAddr;
     Goto Xit;
    End;
    $E4,$E5,$E6,$E7:Begin
     S:=S+' '+Register+','+HexByte(T[I+1]);
     Goto Xit;
    End;
    $E8:Begin
     S:=S+HexWord(TWd(I+1)+3+I);
     Goto Xit;
    End;
    $E9:Begin
     S:=S+' '+HexWord(TWd(I+1)+3+I);
     Goto Xit;
    End;
    $EA:Begin
     S:=S+' '+HexWord(TWd(I+3))+':'+HexWord(TWd(I+1));
     Goto Xit;
    End;
    $EC:Goto Xit;
    $ED:Goto Xit;
    $EE:Goto Xit;
    $EF:Begin
     S:=S+RegxWord(0);
     Goto Xit;
    End;
    $F0,$F2,$F3:Begin
     Prefix:=CurrCode;
     Inc(I);
     Goto Restart;
    End;
    $F4:Goto Xit;
    $F5:Goto Xit;
    $F6,$F7:Begin
     If T[I+1]in[$10..$3F,$50..$7F,$D0..$FF]Then Begin
      S:=SmpS[(T[I+1]and$3F)shr 3]+' ';
     End;
     Case T[I+1]of
      $00..$07,$40..$47:Begin
       S:='TEST ';
       If T[I+1]=6Then Begin
        Inc(I,2);
        S:=S+SegS+'['+HexWord(TWd(I))+']';
        Inc(I,2)
       End
        Else
       Begin
        S:=S+XtrkAddr;
        Inc(I)
       End;
       S:=S+',';
       If CurrCode and 1=1Then Begin
        S:=S+HexWord(TWd(I));
        Inc(I)
       End
        Else
       S:=S+HexByte(T[I]);
      End;
      $10..$3F,$50..$7F:S:=S+XtrkAddr;
      $D0..$FF:Begin
       S:=S+Register;
       Inc(I)
      End;
      Else DB;
     End;
     Goto Xit;
    End;
    $F8:Goto Xit;
    $F9:Goto Xit;
    $FA:Goto Xit;
    $FB:Goto Xit;
    $FC:Goto Xit;
    $FD:Goto Xit;
    $FE,$FF:Begin
     X2:=(T[I+1]shr 3)and 7;
     Wd:=Boolean(CurrCode and 1);
     X3:=0;
     Repeat
      DB;
      Case(X2)of
       0:S:='INC ';
       1:S:='DEC ';
       2,3:If(Wd)Then S:='CALL '
                 Else Break;
       4,5:If(Wd)Then S:='JMP '
                 Else Break;
       7:S:='PUSH ';
       Else Break;
      End;
      Case T[I+1]of
       $06,$16,$26,$36:Begin
        If T[I+1]in[$06,$36]Then S:=S+PtrS[1]
                            Else S:=S+PrcS[0];
        Goto 99;
       End;
       $0E,$1E,$2E,$3E:Begin
        If T[I+1]in[$06,$36]Then S:=S+PtrS[1]
                            Else S:=S+PrcS[1];
     99:Inc(I,2);
        S:=S+SegS+'['+HexWord(TWd(I))+']';
       End;
       $C0..$FF:Begin
        S:=S+Register;
        Inc(I)
       End;
       Else S:=S+XtrkAddr;
      End;
     Until True;
     Goto Xit;
    End;
 End;
_999:XSeg:=CurrCode;Inc(I);
    Goto ReStart;
Xit:
 Repeat
  Case(Prefix)of
   $F0:S:='LOCK '+S;
   $F2:S:='REPNZ '+S;
   $F3:S:='REP '+S;
   Else Break;
  End;
  S:=S+' '+SegS;
 Until True;
 Inc(I,Instr80x86[CurrCode].BaseSize);
 Decode:=S;
End;

Function Encode(S:String;Var Buf;Var I:Word):Boolean;
Const
 Instr2:Array[0..33] of String[8]=(
   'FNOP',    'FCHS',   'FABS',   'FTST',   'FXAM',
   'FLD1',    'FLDL2T', 'FLDL2E', 'FLDPI',  'FLDLG2', 'FLDLN2',
   'FLDZ',    'F2XM1',  'FYL2X',  'FPTAN',  'FPATAN', 'FXTRACT',
   'FDECSTP', 'FINCSTP','FPREM',  'FYL2XP1','FSQRT',  'FRNDINT',
   'FSCALE',  'FENI',   'FDISI',  'FCLEX',  'FINIT',  'FCOMPP',
   'FNCLEX',  'FNDISI', 'FNENI',  'FNINIT',
   'LODSD'
 );
 OpcodeInstr2:Array[0..33] of Word=(
   $D9D0, $D9E0, $D9E1, $D9E4, $D9E5, $D9E8,
   $D9E9, $D9EA, $D9EB, $D9EC, $D9ED, $D9EE,
   $D9F0, $D9F1, $D9F2, $D9F3, $D9F4, $D9F6,
   $D9F7, $D9F8, $D9F9, $D9FA, $D9FC, $D9FD,
   $DBE0, $DBE1, $DBE2, $DBE3, $DED9,
   $DBE2, $DBE1, $DBE0, $DBE3,
   $66AD
 );
Var
 T:Array[0..65520] of Byte Absolute Buf;
 J:Byte;
 HexValue:Word;
Begin
 Encode:=False;
 If S=''Then Exit;
 For J:=0 to 255 do If Not(Instr80x86[J].Param)and(StrToUpper(S)=Instr80x86[J].AsmName)Then Begin
  T[I]:=J;Inc(I);
  Encode:=True;
  Exit;
 End;
 For J:=Low(Instr2) to High(Instr2) do If StrToUpper(S)=Instr2[J]Then Begin
  T[I]:=Hi(OpcodeInstr2[J]);
  T[I+1]:=Lo(OpcodeInstr2[J]);
  Inc(I,2);
  Encode:=True;
  Exit;
 End;
 If StrToUpper(Copy(S,1,3))='DB 'Then Begin
  If GetHex(TrimL(Copy(S,4,255)),HexValue)Then Begin
   T[I]:=Lo(HexValue);
   Inc(I);
   Encode:=True;
   Exit;
  End;
 End;
 If StrToUpper(Copy(S,1,3))='DW 'Then Begin
  If GetHex(StrToUpper(TrimL(Copy(S,4,255))),HexValue)Then Begin
   T[I]:=Lo(HexValue);
   T[I+1]:=Hi(HexValue);
   Inc(I,2);
   Encode:=True;
   Exit;
  End;
 End;
End;

Procedure HomeMessage;Begin
 WriteLn;
 WriteLn('DEBUG - Programme de deboguage');
 WriteLn;
End;

Procedure ShowPrompt;Begin
 Write('-');
End;

Procedure ACommand;
Var
 OrigPointer:Word;
 S:String;
Begin
 If GetHex(StrToUpper(ExtractParam(1)),OrigPointer)Then Begin
  StartPointer:=OrigPointer;
 End;
 Repeat
  Write(HexWord2Str(Seg(Sector^)),':',HexWord2Str(StartPointer),' ');
  ReadLn(S);
  If S=''Then Break;
  If Not Encode(S,Sector^,StartPointer)Then Begin
   WriteLn('Cette instruction n''est pas reconnu');
  End;
 Until S='';
End;

Procedure CCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure DCommand;
Var
 I,J:Integer;
 OrigPointer:Word;
Begin
 If GetHex(StrToUpper(ExtractParam(1)),OrigPointer)Then Begin
  StartPointer:=OrigPointer;
 End;
 For I:=1 to 8 do Begin
  Write(HexWord2Str(Seg(Sector^)),':',HexWord2Str(StartPointer),'  ');
  For J:=0 to 15 do Begin
   Write(ByteHex2Str(Sector^[StartPointer+J]));
   If J=7Then Write('-')
         Else Write(' ');
  End;
  Write('  ');
  For J:=0 to 15 do Begin
   If(Sector^[StartPointer+J]<32)Then Write(' ')
                                 Else Write(Chr(Sector^[StartPointer+J]));
  End;
  WriteLn;
  Inc(StartPointer,16);
 End;
End;

Procedure DBCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure DDCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure DICommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure DLCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure DMCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure DWCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure DXCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure ECommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Function EXITCommand:Boolean;Begin
 EXITCommand:=True;
End;

Procedure FCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure GCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure HCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure IDCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure IWCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure LCommand;
Var
 Source:File{$IFDEF FPC}of Byte{$ENDIF};
 ProgSize:LongInt;
 ByteReaded:Integer;
Begin
 If CurrProgName=''Then Begin
  WriteLn('Nom de fichier inconnu. Utiliser la commande "N" pour indiquer le nom.');
 End
  Else
 Begin
  Assign(Source,CurrProgName);
  Reset(Source);
  ProgSize:=FileSize(Source);
  If(ProgSize>SizeSector)Then ProgSize:=SizeSector;
  BlockRead(Source,Sector^,ProgSize,ByteReaded);
  Close(Source);
 End;
End;

Procedure MCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure MCCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;
Procedure MDCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure NCommand;Begin
 CurrProgName:=ExtractParam(1);
End;

Procedure ODCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure OWCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure PCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure PRCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Function QCommand:Boolean;Begin
 QCommand:=True;
End;

Function QUITCommand:Boolean;Begin
 QUITCommand:=True;
End;

Procedure RCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure RMCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure RNCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure RNRCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure SCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure TCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure TMCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure UCommand;
Var
 I,J:Integer;
 OrigPointer:Word;
 S:String;
Begin
 If GetHex(StrToUpper(ExtractParam(1)),OrigPointer)Then Begin
  StartPointer:=OrigPointer;
 End;
 For I:=1 to 20 do Begin
  Write(HexWord2Str(Seg(Sector^)),':',HexWord2Str(StartPointer),' ');
  OrigPointer:=StartPointer;
  S:=Decode(Sector^,StartPointer);
  For J:=OrigPointer to StartPointer-1 do Begin
   Write(ByteHex2Str(Sector^[J]));
  End;
  WriteLn(' ':16-(StartPointer-OrigPointer)*2,S);
 End;
End;

Procedure WCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure UnknownCommand;Begin
 WriteLn('Commande ou nom de fichier non reconnu');
 WriteLn;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('DEBUG : Cette commande permet de deboguer des programmes.');
  WriteLn;
  WriteLn('Syntaxe : DEBUG');
 End
  Else
 Begin
  CurrProgName:='';
  Terminated:=False;
  StartPointer:=$100;
  SizeSector:=65520;
  GetMem(Sector,SizeSector);
  If(Sector=NIL)Then Begin
   WriteLn('Manque de memoire');
   Halt;
  End;
  HomeMessage;
  Repeat
   ShowPrompt;
   ReadLn(CmdStr);
   ExtractCommand;
   CommandFound:=False;
   For J:=Low(CommandList) to High(CommandList) do Begin
    If CurrCommand=CommandList[J]Then Begin
     Case(J)of
      0:ACommand;
      1:CCommand;
      2:DBCommand;
      3:DDCommand;
      4:DICommand;
      5:DLCommand;
      6:DMCommand;
      7:DWCommand;
      8:DXCommand;
      9:ECommand;
      10:Terminated:=EXITCommand;
      11:FCommand;
      12:GCommand;
      13:HCommand;
      14:IDCommand;
      15:IWCommand;
      16:LCommand;
      17:MCommand;
      18:MCCommand;
      19:MDCommand;
      20:NCommand;
      21:ODCommand;
      22:OWCommand;
      23:PCommand;
      24:PRCommand;
      25:Terminated:=QCommand;
      26:Terminated:=QUITCommand;
      27:RCommand;
      28:RMCommand;
      29:RNCommand;
      30:RNRCommand;
      31:SCommand;
      32:TCommand;
      33:TMCommand;
      34:UCommand;
      35:WCommand;
      36:DCommand;
     End;
     If J<=High(CommandList)Then Begin
      CommandFound:=True;
      WriteLn;
      Break;
     End;
    End;
   End;
   If Not(CommandFound)Then Begin
    If(CmdStr='?')or(StrToUpper(CmdStr)='HELP')Then Begin
     For I:=Low(CommandList) to High(CommandList) do Begin
      Write(PadRight(CommandName[I],31));
      WriteLn(CommandSyntax[I]);
     End;
     WriteLn;
     WriteLn;
    End
     Else
    UnknownCommand;
   End;
  Until Terminated;
 End;
END.
