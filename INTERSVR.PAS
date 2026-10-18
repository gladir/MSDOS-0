{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7)
  @description: Clone de la commande INTERSVR de MS-DOS 6.0
  @license: MIT
}

Program INTERSVR;

{ Clone de INTERSVR.EXE (Microsoft InterSvr), base sur le code source de
  MS-DOS 6.0 (c6ers\interlnk). INTERSVR est le programme de l'ordinateur
  "serveur": il met ses lecteurs de disque et ses imprimantes a la disposition
  d'un ordinateur "client" relie par un cable serie (3 fils) ou parallele, qui
  execute INTERLNK (voir INTERLNK.PAS).

  Ce programme contient:
   - le moteur de liaison de l'original, identique a celui de INTERLNK.PAS
     (trames avec numero de sequence, CRC-CCITT, blocs de 8192 octets au
     plus, negociation de la vitesse de 9600 a 115200 bauds, mode "echoplex",
     cable parallele "turbo"), avec en plus la cote serveur: ecoute des ports
     (poignee de main AA/00/55/FF/5A/11 en serie, WSYNC/RSYNC en parallele) et
     reponse aux octets d'inactivite envoyes par le client;
   - les gestionnaires de paquets du serveur: information serveur,
     initialisation et correspondance des lecteurs et des imprimantes,
     controle du support, construction du BPB, lecture, ecriture,
     ouverture/fermeture, IOCTL generique, taille et nom des volumes,
     impression (LPT et INT 17h);
   - l'acces aux pilotes de peripheriques de DOS: les requetes du client sont
     transmises directement aux pilotes des lecteurs (appel de la strategie
     puis de l'interruption), comme le fait l'original;
   - l'ecran du serveur: liste des lecteurs et des imprimantes, port, vitesse
     et etat (repos, lecture, ecriture, impression); F3 ou Alt+F4 pour quitter.

  Syntaxe: INTERSVR [lecteur: ...] [/X=lecteur ...] [/COM[:n|:adr]] [/LPT[:n|:adr]]
                    [/BAUD:vitesse] [/MAXBLOCK:n] [/B] [/V] [/RCOPY]
  Les options peuvent aussi se trouver dans la variable d'environnement
  INTERSVR. Sans lecteur indique, tous les lecteurs du serveur sont proposes
  (sauf ceux deja rediriges par INTERLNK).
  Differences avec l'original: /RCOPY (copie de INTERLNK sur un client par
  une liaison serie, a l'aide d'un programme d'amorcage ecrit en langage
  machine) n'est pas reprise, ainsi que la gestion de Windows 386, DESQview
  et du commutateur de taches de DOS 5.

  Tout le code est contenu dans ce fichier: aucun fichier d'inclusion, aucune
  unite externe autre que DOS et CRT.
}

{$M 8192,0,0}
{$A-}
{$R-}
{$S-}

Uses Dos,Crt;

Const
 VerMajor=1; VerMinor=0;

  { Types de paquets echanges avec le serveur }
 INIT_PACKET_REQ=1; MEDIA_CHECK_REQ=2; BUILD_BPB_REQ=3; READ_REQ=4;
 WRITE_REQ=5; WRITE_VER_REQ=6; ERROR_REQ=7; AUX_WRITE_REQ=10;
 OUTPUT_STATUS_REQ=14; FLUSH_OUTPUT_REQ=16; AUX_DEV_OPEN_REQ=17;
 AUX_DEV_CLOSE_REQ=18; DEV_OPEN_REQ=22; DEV_CLOSE_REQ=23; DRIVE_INFO_REQ=28;
 GEN_IOCTL_REQ=29;
 UNASSIGNED=$FF; DONT_CARE=$FE;
 MAX_DEVICES=26; MAX_VOLUME=12; MAX_PACKET=87; MAX_LPT_BUFF=64;

  { Octet de synchronisation des trames serie }
 BYTE_LENGTH=$80; CONTINUED_PACKET=$40; ECHOPLEX=$04; SEQUENCE_BITS=$03;
 IDLE_BITS=$FC;

  { Delais en tics de l'horloge du BIOS (18,2 par seconde) }
 MINIMUM_TICKS=5; RECV_PACK_TICKS=2*18; SYNC_TICKS=36; CONNECT_TICKS=5;
 INITIAL_CRC=$FFFF; MAGIC_CRC=$1D0F;
 MAX_SERIAL_BLOCK=8192;
 OP_SEND=0; OP_RECV=1;
 BAUD_9600=3; BAUD_115200=7;

  { Quartets du cable parallele }
 WACK=$06; WNAK=$03; WIDLE=$0A; RACK=$B0; RNAK=$98; WSYNC=$15; RSYNC=$28;

  { Etat des pilotes de peripherique }
 STATUS_ERROR=$8000; STATUS_BUSY=$0200; STATUS_DONE=$0100;
 ERR_WRITE_PROT=0; ERR_UNK_UNIT=1; ERR_NOT_READY=2; ERR_UNK_COMMAND=3;
 ERR_UNK_MEDIA=7; ERR_WRITE_FAULT=$0A; ERR_READ_FAULT=$0B; ERR_DISK_CHANGE=$0F;
 ATT_CHARACTER=$8000; ATT_OCRM=$0800; ATT_GEN_IOCTL=$0040; ATT_HUGE=$0002;
 ATT_NON_IBM=$2000;
 DOS331=$031F; DOS40=$0400; DOS50=$0500;

 BaudDiv:Array[0..7] of Byte=(96,48,24,12,6,3,2,1);
 BaudList1:Array[0..15] of Byte=($00,$FF,$00,$5A,$55,$AA,$F0,$0F,$E7,$7E,$C3,$3C,$81,$18,$00,$FF);
 BaudList2:Array[0..15] of Byte=($00,$00,$FF,$A5,$AA,$55,$F0,$0F,$FF,$00,$18,$81,$3C,$C3,$7E,$E7);

Type
 TBuf=Array[0..65534] of Byte;
 PBuf=^TBuf;

  { Tampon de parametres du BIOS (BPB), 25 octets utiles + 6 de remplissage }
 TBpb=packed Record
  BytesPerSector:Word;
  SectorsPerUnit:Byte;
  ReservedSectors:Word;
  NumberOfFats:Byte;
  RootDirEntries:Word;
  TotalSectors:Word;
  MediaId:Byte;
  SectorsPerFat:Word;
  SectorsPerTrack:Word;
  NumberOfHeads:Word;
  HiddenSectors:Word;
  HighHidden:Word;
  LongTotalSectors:LongInt;
  Pad:Array[0..5] of Byte;
 End;

  { Paquets du protocole }
 TServerInfoReq=packed Record
  OsType,Developer,Product,Version:Word;
  DeviceDriver,WantSupported,Checksum,Crc:Byte;
  MaxSerBlock:Word;
  Reserved:Array[0..11] of Byte;
  ClientId,LastServerId:LongInt;
 End;
 TServerInfoAns=packed Record
  OsType,Developer,Product,Version:Word;
  DeviceServer,Checksum,Crc:Byte;
  MaxSerBlock:Word;
  Reserved:Array[0..11] of Byte;
  LastClientId,ServerId:LongInt;
 End;
 TInitReq=packed Record
  PacketType,MajorVersion,MinorVersion:Byte;
  DosVersion:Word;
  MaxDevices,FirstUnit:Byte;
  PrnMap:Array[0..2] of Byte;
  Mapping:Array[0..MAX_DEVICES-1] of Byte;
 End;
 TInitAns=packed Record
  MajorVersion,MinorVersion:Byte;
  DosVersion:Word;
  Devices:Byte;
  PrnMap:Array[0..2] of Byte;
  Mapping:Array[0..MAX_DEVICES-1] of Byte;
  Attributes:Array[0..MAX_DEVICES-1] of Word;
  Multitasker:Byte;
 End;
 TUnitReq=packed Record      { controle du support, construction du BPB, ouverture }
  PacketType,Unit_,MediaId:Byte;
 End;
 TMediaAns=packed Record
  Status:Word;
  Changed:Byte;
  Volume:Array[0..MAX_VOLUME-1] of Byte;
  Serial:LongInt;
 End;
 TBpbAns=packed Record
  Status:Word;
  Bpb:TBpb;
 End;
 TIoReq=packed Record
  PacketType,Unit_,MediaId:Byte;
  Requested,Start:Word;
  HugeStart:LongInt;
 End;
 TIoAns=packed Record
  Status,Transferred:Word;
  Volume:Array[0..MAX_VOLUME-1] of Byte;
  Serial:LongInt;
 End;
 TErrReq=packed Record
  PacketType,BlockDvr,Unit_,Code,Data:Byte;
 End;
 TStatusAns=packed Record
  Status:Word;
 End;
 TLptReq=packed Record
  PacketType,LptId:Byte;
  Count:Word;
  Data:Byte;
 End;
 TLptAns=packed Record
  Status,Transferred:Word;
 End;
 TLptCmd=packed Record
  PacketType,LptId:Byte;
 End;
 TIoctlReq=packed Record
  PacketType,Unit_,Category,Func:Byte;
 End;
 TMediaIdBuf=packed Record
  InfoLevel:Word;
  Serial:LongInt;
  VolumeLabel:Array[0..10] of Byte;
  FileSys:Array[0..7] of Byte;
 End;
 TDriveInfoReq=packed Record
  PacketType,Drive:Byte;
 End;
 TDriveInfoAns=packed Record
  Size:Array[0..9] of Char;
  VolLabel:Array[0..11] of Char;
  WriteProt:Byte;
 End;

  { En-tete de requete des pilotes de peripherique (13 octets communs) }
 TReq=packed Record
  Len,Unit_,Cmd:Byte;
  Status:Word;
  Reserved:Array[0..7] of Byte;
  Case Byte of
   0:(Media:Byte;Changed:Byte;MediaLabel:Pointer);
   1:(Media1:Byte;Fat:Pointer;BpbPtr:Pointer);
   2:(Media2:Byte;IoData:Pointer;IoCount:Word;IoStart:Word;IoStartHigh:Word;
      IoPad:Word;IoHuge:LongInt);
   3:(Media3:Byte;Dat3:Pointer;Transferred:Word;Pad3:Word;IoLabel:Pointer);
   4:(Category:Byte;Func:Byte;GenSI:Word;GenDI:Word;GenData:Pointer);
 End;
 PReq=^TReq;


Var
 CrcTab:Array[0..255] of Word;

  { ------------------------------------------------------------------ acces materiel }
  { Ces fonctions sont les seuls acces directs au materiel du moteur de
    liaison: ports d'entree-sortie et compteur de tics du BIOS (0040:006C). }
{ -- DOS-LOW-BEGIN -- }
Function InB(P:Word):Byte;Begin InB:=Port[P];End;
Procedure OutB(P:Word;V:Byte);Begin Port[P]:=V;End;
Function BiosTicks:Word;Begin BiosTicks:=MemW[$0040:$006C];End;
{ -- DOS-LOW-END -- }

{ ================================================================== BEGIN ENGINE }
Var
 Aborted:Boolean;
 PollCnt:Word;

{ -- DOS-LOW3-BEGIN -- }
  { Interroge le clavier de temps en temps: F3 ou Alt+F4 arrete le serveur }
Procedure PollAbort;
Var C:Char;
Begin
 Inc(PollCnt);
 If (PollCnt and $FF)<>0 Then Exit;
 While KeyPressed do Begin
  C:=ReadKey;
  If C=#0 Then Begin
   C:=ReadKey;
   If (C=#61) Or (C=#107) Then Aborted:=True;
  End;
 End;
End;
{ -- DOS-LOW3-END -- }

Type
  { Moteur de liaison: les protocoles serie et parallele sont symetriques
    (envoi et reception de paquets), seule la synchronisation initiale differe. }
 TLink=Object
  Base:Word;                 { adresse du port actif, 0 = non connecte }
  IsSerial:Byte;
  SeqNum,LastOp:Byte;
  Baud,PriorBaud,MaxBaud,ClientMaxBaud:Byte;
  MaxBlock:Word;
  SendEcho,RecvEcho,NeedEcho:Byte;
  FirstSend:Byte;
  SendFails:Byte;
  ErrNo:Integer;
  PacketOk,RecvErr:Byte;
  ForceVar:Byte;
  ParSpeed:Byte;
  LastNibSent,LastNibRecv:Byte;
  IdleAck,IdleWait:Byte;
  IdleStamp:Word;
  AlarmStart,AlarmLimit:Word;
  AlarmFresh:Boolean;
  LastTick,CurTick:Word;
  CrcErrors:Word;
  Crc:Word;
  RecvSync:Word;
  Masked:Boolean;
  IrqSave:Byte;
  SaveSer:Array[0..4] of Byte;
  SavePar:Array[0..1] of Byte;
  List1,List2:Array[0..15] of Byte;
  Procedure Init;
  Function Now:Word;
  Procedure SetAlarm(N:Word);
  Function Expired:Boolean;
  Procedure Delay(N:Word);
  Procedure CrcAdd(B:Byte);
  Procedure Lost;
   { serie }
  Function GetNB(Var B:Byte):Boolean;
  Function SendNB(B:Byte):Boolean;
  Function TxByte(B:Byte):Boolean;
  Function RxByte(Var B:Byte):Boolean;
  Procedure Drain;
  Function WaitIdle:Boolean;
  Procedure SetBaud(Idx:Byte);
  Procedure InitSerial;
  Procedure ResetSerial;
  Procedure MaskOn;
  Procedure MaskOff;
  Function TxEcho(B:Byte):Boolean;
  Function SendBaudRate(NewIdx:Byte):Boolean;
  Function RecvBaudRate(Req:Byte):Boolean;
  Procedure GotoMaxBaud;
  Function SerSendBlock(Var Buf;Start,Len:Word;Var Fl:Byte):Boolean;
  Function SerSend(Var Buf;Len:Word):Boolean;
  Function SerRecvBlock(Var Buf;Start,Max:Word;Var Got:Word;Var Fl:Byte):Boolean;
  Function SerRecv(Var Buf;Max:Word;Var Total:Word):Boolean;
   { parallele }
  Function ReadStat(Var V:Byte):Boolean;
  Function WaitS7(Want:Boolean;Fast:Boolean;Var V:Byte):Boolean;
  Function WaitVal(Want:Byte):Boolean;
  Procedure ParSave;
  Procedure ParRestore;
  Function ParTx(B:Byte;Ticks:Word;Var Ack:Byte):Boolean;
  Function ParRxNoAck(Ticks:Word;Var B:Byte):Boolean;
  Function ParRxSync(Ticks:Word;Var B:Byte):Boolean;
  Function ParRx(Ticks:Word;Var B:Byte):Boolean;
  Procedure ParWaitSendAck(Last:Byte);
  Function ParSendData(Var Buf;Len:Word):Boolean;
  Function ParSend(Var Buf;Len:Word):Boolean;
  Function ParRecvData(Var Buf;Len:Word):Boolean;
  Function ParRecv(Var Buf;Max:Word;Var Total:Word):Boolean;
   { generique }
  Function Send(Var Buf;Len:Word):Boolean;
  Function Recv(Var Buf;Max:Word;Var Total:Word):Boolean;
 End;

Procedure InitCrcTab;
Var I,J,C:Word;
Begin
 For I:=0 to 255 do Begin
  C:=I shl 8;
  For J:=1 to 8 do
   If (C and $8000)<>0 Then C:=((C shl 1) and $FFFF) xor $1021
                       Else C:=(C shl 1) and $FFFF;
  CrcTab[I]:=C;
 End;
End;

Procedure TLink.Init;Begin
 FillChar(Self,SizeOf(Self),0);
 MaxBlock:=MAX_SERIAL_BLOCK;
 Baud:=BAUD_9600;
 MaxBaud:=BAUD_115200;
 ClientMaxBaud:=BAUD_115200;
 IdleAck:=WIDLE;
 Move(BaudList1,List1,16);
 Move(BaudList2,List2,16);
 LastTick:=BiosTicks;
End;

  { Compteur de tics logique (gere le passage de minuit) }
Function TLink.Now:Word;
Var T,Dt:Word;
Begin
 T:=BiosTicks;
 Dt:=T-LastTick;
 LastTick:=T;
 If Dt>=2*18 Then Dt:=1;
 CurTick:=CurTick+Dt;
 Now:=CurTick;
End;

  { L'alarme demarre au premier test d'expiration: elle peut donc etre
    relancee a chaque octet sans lire l'horloge }
Procedure TLink.SetAlarm(N:Word);Begin
 AlarmLimit:=N;
 AlarmFresh:=True;
End;

Function TLink.Expired:Boolean;Begin
 PollAbort;
 If Aborted Then Begin
  Expired:=True;
  Exit;
 End;
 If AlarmFresh Then Begin
  AlarmStart:=Now;
  AlarmFresh:=False;
  Expired:=False;
 End
  Else
 Expired:=Word(Now-AlarmStart)>=AlarmLimit;
End;

Procedure TLink.Delay(N:Word);
Var T0:Word;
Begin
 T0:=Now;
 Repeat Until Word(Now-T0)>=N;
End;

Procedure TLink.CrcAdd(B:Byte);Begin
 Crc:=((Crc shl 8) and $FFFF) xor CrcTab[(Crc shr 8) xor B];
End;

  { Connexion perdue: le prochain acces doit relancer la synchronisation }
Procedure TLink.Lost;Begin
 Base:=0;
End;

 { ------------------------------------------------------------------ serie }

Function TLink.GetNB(Var B:Byte):Boolean;Begin
 If (InB(Base+5) and 1)=0 Then GetNB:=False
  Else
 Begin
  B:=InB(Base);
  GetNB:=True;
 End;
End;

Function TLink.SendNB(B:Byte):Boolean;Begin
 If (InB(Base+5) and $20)=0 Then SendNB:=False
  Else
 Begin
  OutB(Base,B);
  SendNB:=True;
 End;
End;

  { Envoie un octet (attend le registre de transmission), met le CRC a jour }
Function TLink.TxByte(B:Byte):Boolean;Begin
 TxByte:=False;
 While (InB(Base+5) and $20)=0 do If Expired Then Exit;
 OutB(Base,B);
 CrcAdd(B);
 TxByte:=True;
End;

  { Recoit un octet jusqu'a l'expiration de l'alarme, met le CRC a jour.
    Les octets recus avec une erreur de ligne sont jetes. }
Function TLink.RxByte(Var B:Byte):Boolean;
Var S:Byte;
Begin
 RxByte:=False;
 Repeat
  S:=InB(Base+5);
  If (S and 1)<>0 Then Begin
   If (S and $0E)<>0 Then Begin
    RecvErr:=S shr 1;
    B:=InB(Base);
   End
    Else
   Begin
    B:=InB(Base);
    CrcAdd(B);
    RxByte:=True;
    Exit;
   End;
  End
   Else
  If Expired Then Exit;
 Until False;
End;

Procedure TLink.Drain;
Var B:Byte;
Begin
 While (InB(Base+5) and 1)<>0 do B:=InB(Base);
End;

Function TLink.WaitIdle:Boolean;
Var T0:Word;S:Byte;
Begin
 WaitIdle:=True;
 T0:=Now;
 Repeat
  S:=InB(Base+5);
  If S=$60 Then Exit;
  If (S and 1)<>0 Then S:=InB(Base);
 Until Word(Now-T0)>2;
 WaitIdle:=False;
End;

Procedure TLink.SetBaud(Idx:Byte);Begin
 Baud:=Idx;
 WaitIdle;
 OutB(Base+3,$83);
 OutB(Base+1,0);
 OutB(Base,BaudDiv[Idx]);
 OutB(Base+3,$03);
 WaitIdle;
End;

  { Sauvegarde l'etat du UART puis le met en 8N1, sans interruption }
Procedure TLink.InitSerial;
Var L:Byte;
Begin
 Baud:=BAUD_9600;
 WaitIdle;
 SaveSer[0]:=InB(Base+1);
 SaveSer[1]:=InB(Base+4);
 L:=InB(Base+3);
 SaveSer[2]:=L;
 OutB(Base+3,L or $80);
 SaveSer[3]:=InB(Base+1);
 SaveSer[4]:=InB(Base);
 OutB(Base+3,$03);
 OutB(Base+1,0);
 OutB(Base+4,0);
 SetBaud(Baud);
End;

Procedure TLink.ResetSerial;
Var B:Byte;
Begin
 OutB(Base+1,SaveSer[0]);
 OutB(Base+4,SaveSer[1]);
 OutB(Base+3,SaveSer[2] or $80);
 OutB(Base+1,SaveSer[3]);
 OutB(Base,SaveSer[4]);
 OutB(Base+3,SaveSer[2]);
 B:=InB(Base);
End;

Procedure TLink.MaskOn;Begin
 IrqSave:=InB($21);
 OutB($21,$FE);
 Masked:=True;
End;

Procedure TLink.MaskOff;Begin
 If Masked Then Begin
  OutB($21,IrqSave);
  Masked:=False;
 End;
End;

  { Envoi avec attente de l'echo si le mode echoplex est actif }
Function TLink.TxEcho(B:Byte):Boolean;
Var Save:Word;E:Byte;
Begin
 TxEcho:=False;
 If Not TxByte(B) Then Exit;
 If SendEcho<>0 Then Begin
  Save:=Crc;
  Repeat
   If Not RxByte(E) Then Exit;
  Until E=B;
  Crc:=Save;
 End;
 TxEcho:=True;
End;

  { Demande a l'autre extremite de passer a la vitesse NewIdx }
Function TLink.SendBaudRate(NewIdx:Byte):Boolean;
Var Cl,Stage:Byte;
 Function Run:Boolean;
 Var B,Bh:Byte;I:Integer;
 Begin
  Run:=False;
  SetAlarm(SYNC_TICKS);
  If LastOp=OP_RECV Then Begin
   Repeat
    If Not RxByte(B) Then Exit;
   Until B=SeqNum;
   LastOp:=OP_SEND;
  End;
  B:=(Not SeqNum) and $FF;
  Bh:=SeqNum;
  If Not TxByte(B) Then Exit;
  Repeat
   If Not RxByte(B) Then Exit;
  Until B=Bh;
  Stage:=1;
  SetAlarm(MINIMUM_TICKS);
  If Not TxByte(NewIdx) Then Exit;
  SetBaud(NewIdx);
  Stage:=2;
  SetAlarm(2*MINIMUM_TICKS);
  Cl:=((NewIdx shl 4) or SeqNum) and $FF;
  Repeat
   If Not RxByte(B) Then Exit;
  Until B=Cl;
  List1[0]:=Cl;
  List2[0]:=(Not Cl) and $FF;
  For I:=0 to 15 do Begin
   If Not TxByte(List1[I]) Then Exit;
   Repeat
    If Not RxByte(B) Then Exit;
   Until B=List2[I];
  End;
  Run:=True;
 End;
Begin
 PriorBaud:=Baud;
 Cl:=0;
 Stage:=0;
 If Run Then Begin
  ErrNo:=0;
  SendBaudRate:=True;
 End
  Else
 Begin
  SendBaudRate:=False;
  Case Stage of
   0:ErrNo:=4;
   1:ErrNo:=-4;
   Else
    If Cl<PriorBaud Then ErrNo:=-4
     Else
    Begin
     MaxBaud:=PriorBaud;
     SetBaud(PriorBaud);
     ErrNo:=0;
     SendBaudRate:=True;
    End;
  End;
 End;
End;

  { Reponse a une demande de changement de vitesse. Retourne False si la
    liaison est perdue (ErrNo=4). }
Function TLink.RecvBaudRate(Req:Byte):Boolean;
Var NewB,Bh,A:Byte;Di,St:Integer;T0,Si,T:Word;Failed:Boolean;
Begin
 RecvBaudRate:=True;
 Drain;
 SetAlarm(MINIMUM_TICKS);
 If Not TxByte((Not Req) and $FF) Then Exit;
 If Not RxByte(NewB) Then Exit;
 If NewB>=Baud Then If NewB>MaxBaud Then Exit;
 PriorBaud:=Baud;
 SetBaud(NewB);
 Bh:=((Baud shl 4) or SeqNum) and $FF;
 List2[0]:=(Not Bh) and $FF;
 Di:=0;
 St:=0;
 T0:=Now;
 Si:=T0;
 Failed:=False;
 Repeat
  Case St of
   0:If SendNB(Bh) Then Begin Si:=Now;St:=1;End Else Failed:=Word(Now-T0)>MINIMUM_TICKS;
   1:If GetNB(A) Then Begin
      If A=Bh Then St:=2 Else Failed:=Word(Now-T0)>MINIMUM_TICKS;
     End
      Else
     Begin
      T:=Now;
      If T<>Si Then St:=0 Else Failed:=Word(T-T0)>MINIMUM_TICKS;
     End;
   2:If SendNB(List2[Di]) Then Begin
      Inc(Di);
      If Di>=16 Then Exit;
      St:=3;
     End
      Else
     Failed:=Word(Now-T0)>MINIMUM_TICKS;
   3:If GetNB(A) Then Begin
      If A=List1[Di] Then St:=2 Else Failed:=Word(Now-T0)>MINIMUM_TICKS;
     End
      Else
     Failed:=Word(Now-T0)>MINIMUM_TICKS;
  End;
 Until Failed;
 If PriorBaud>=Baud Then Begin
  ErrNo:=4;
  RecvBaudRate:=False;
 End
  Else
 Begin
  MaxBaud:=PriorBaud;
  SetBaud(PriorBaud);
 End;
End;

  { A la premiere emission, monte progressivement jusqu'a la vitesse maximale }
Procedure TLink.GotoMaxBaud;
Var Cl:Byte;
Begin
 If FirstSend<>1 Then Exit;
 Cl:=Baud;
 While Cl<>MaxBaud do Begin
  If Cl<MaxBaud Then Inc(Cl) Else Cl:=MaxBaud;
  If Not SendBaudRate(Cl) Then Begin FirstSend:=0;Exit;End;
  Cl:=Baud;
 End;
 FirstSend:=0;
End;

  { Envoie un bloc de la trame serie: octet de synchronisation, longueur, donnees,
    CRC. Le resultat est dans ErrNo: 0 = envoye et acquitte, -1 = pas de
    synchronisation, -3 = echec apres la synchronisation. }
Function TLink.SerSendBlock(Var Buf;Start,Len:Word;Var Fl:Byte):Boolean;
Var B,E,Want:Byte;I,C:Word;
Begin
 SerSendBlock:=False;
 If Len<256 Then Fl:=Fl or BYTE_LENGTH Else Fl:=Fl and $7F;
 SetAlarm(SYNC_TICKS);
 If LastOp=OP_RECV Then Begin
  Repeat
   If Not RxByte(B) Then Begin ErrNo:=-1;Exit;End;
  Until B=SeqNum;
  LastOp:=OP_SEND;
 End;
 Drain;
 B:=Fl or SeqNum;
 PacketOk:=B;
 If Not TxByte(B) Then Begin ErrNo:=-1;Exit;End;
 Want:=((Not B) and $FF) and $FB;
 Repeat
  If Not RxByte(E) Then Begin ErrNo:=-1;Exit;End;
 Until (E and $FB)=Want;
 SendEcho:=E and ECHOPLEX;
 SetAlarm(2*MINIMUM_TICKS);
 Crc:=INITIAL_CRC;
 If Not TxEcho(Len and $FF) Then Begin ErrNo:=-3;Exit;End;
 If Len>=256 Then If Not TxEcho(Len shr 8) Then Begin ErrNo:=-3;Exit;End;
 I:=0;
 C:=Len;
 Repeat
  SetAlarm(2*MINIMUM_TICKS);
  If Not TxEcho(TBuf(Buf)[Start+I]) Then Begin ErrNo:=-3;Exit;End;
  Inc(I);
  Dec(C);
 Until C=0;
 C:=(Not Crc) and $FFFF;
 SetAlarm(2*MINIMUM_TICKS);
 If Not TxEcho(C shr 8) Then Begin ErrNo:=-3;Exit;End;
 If Not TxByte(C and $FF) Then Begin ErrNo:=-3;Exit;End;
 SetAlarm(2*MINIMUM_TICKS);
 If Not RxByte(E) Then Begin ErrNo:=-3;Exit;End;
 If E<>PacketOk Then Begin ErrNo:=-3;Exit;End;
 SeqNum:=(SeqNum+1) and 3;
 ErrNo:=0;
 SerSendBlock:=True;
End;

  { Envoie un paquet complet (Len=0 signifie 65536 octets) }
Function TLink.SerSend(Var Buf;Len:Word):Boolean;
Var Rem,Start,Blk:Word;Fl,Cl:Byte;
Begin
 SerSend:=False;
 SendFails:=0;
 If Base=0 Then Exit;
 Rem:=Len;
 Start:=0;
 Fl:=0;
 GotoMaxBaud;
 Repeat
  Blk:=Rem;
  If (Blk=0) Or (Blk>MaxBlock) Then Begin
   Fl:=Fl or CONTINUED_PACKET;
   Blk:=MaxBlock;
  End
   Else
  Fl:=Fl and $BF;
  Fl:=(Fl and $FB) or NeedEcho;
  If SerSendBlock(Buf,Start,Blk,Fl) Then Begin
   If (Fl and CONTINUED_PACKET)=0 Then Begin SerSend:=True;Exit;End;
   Dec(Rem,MaxBlock);
   Inc(Start,MaxBlock);
   SendFails:=0;
  End
   Else
  Begin
   If ErrNo>=-1 Then Begin Lost;Exit;End;
   If SendEcho=0 Then Begin
    SendFails:=0;
    NeedEcho:=ECHOPLEX;
   End
    Else
   Begin
    Inc(SendFails);
    If SendFails>=2 Then Begin
     Cl:=Baud;
     If Cl<=BAUD_9600 Then Begin ErrNo:=-1;Lost;Exit;End;
     Dec(Cl);
     If Not SendBaudRate(Cl) Then Begin Lost;Exit;End;
     SendFails:=0;
     NeedEcho:=0;
    End;
   End;
  End;
 Until False;
End;

  { Recoit un bloc de la trame serie. Fl recoit l'octet de synchronisation. }
Function TLink.SerRecvBlock(Var Buf;Start,Max:Word;Var Got:Word;Var Fl:Byte):Boolean;
Var B,Reply,Ah,Bb:Byte;Len,Top,Mx,I:Word;Found,Again,Bad:Boolean;
Begin
 SerRecvBlock:=False;
 Got:=0;
 ErrNo:=0;
 Fl:=0;
 If LastOp=OP_SEND Then Begin
  SendNB(SeqNum);
  LastOp:=OP_RECV;
 End;
 Found:=False;
 Repeat
  SetAlarm(RecvSync);
  Again:=False;
  Repeat
   If Not RxByte(B) Then Begin ErrNo:=-1;Exit;End;
   If B=(((SeqNum xor 1) or IDLE_BITS) and $FF) Then Begin
     { octet d'inactivite du client: on le lui renvoie et on relance le delai }
    SendNB(B);
    SetAlarm(RecvSync);
   End
    Else
   If (B and SEQUENCE_BITS)=SeqNum Then Found:=True
    Else
   If ((Not B) and SEQUENCE_BITS)=SeqNum Then Begin
    If Not RecvBaudRate(B) Then Exit;
    Again:=True;
   End;
  Until Found Or Again;
 Until Found;
 Drain;
 PacketOk:=B;
 Fl:=B;
 Ah:=B and ECHOPLEX;
 If ForceVar<>0 Then Ah:=ECHOPLEX;
 RecvEcho:=Ah;
 Reply:=(((Not B) and $FF) and $FB) or Ah;
 SetAlarm(MINIMUM_TICKS);
 RecvErr:=0;
 If (RecvEcho=0) And (Baud>BAUD_9600) Then MaskOn;
 Bad:=False;
 If Not TxByte(Reply) Then Begin ErrNo:=-3;MaskOff;Exit;End;
 Crc:=INITIAL_CRC;
 If Not RxByte(Bb) Then Begin ErrNo:=-3;MaskOff;Exit;End;
 If RecvEcho<>0 Then SendNB(Bb);
 Len:=Bb;
 If (PacketOk and BYTE_LENGTH)=0 Then Begin
  If Not RxByte(Bb) Then Begin ErrNo:=-3;MaskOff;Exit;End;
  If RecvEcho<>0 Then SendNB(Bb);
  Len:=Len or (Word(Bb) shl 8);
 End;
 Top:=Len;
 Dec(Top);
 Mx:=Max;
 Dec(Mx);
 If Top>Mx Then Bad:=True
  Else
 Begin
  I:=Len;
  Top:=0;
  Repeat
   If Not RxByte(Bb) Then Begin ErrNo:=-3;MaskOff;Exit;End;
   SetAlarm(MINIMUM_TICKS);
   If RecvEcho<>0 Then SendNB(Bb);
   TBuf(Buf)[Start+Top]:=Bb;
   Inc(Top);
   Dec(I);
  Until I=0;
  If Not RxByte(Bb) Then Begin ErrNo:=-3;MaskOff;Exit;End;
  If RecvEcho<>0 Then SendNB(Bb);
  If Not RxByte(Bb) Then Begin ErrNo:=-3;MaskOff;Exit;End;
  If (RecvErr<>0) Or (Crc<>MAGIC_CRC) Then Bad:=True;
 End;
 If Bad Then Begin
   { Bloc incorrect: vider la ligne jusqu'au silence, l'emetteur reessaiera }
  Repeat
   SetAlarm(MINIMUM_TICKS);
  Until Not RxByte(Bb);
  ErrNo:=-3;
  MaskOff;
  Exit;
 End;
 SetAlarm(MINIMUM_TICKS);
 If Not TxByte(PacketOk) Then Begin ErrNo:=-3;MaskOff;Exit;End;
 MaskOff;
 SeqNum:=(SeqNum+1) and 3;
 Got:=Top;
 SerRecvBlock:=True;
End;

  { Recoit un paquet complet de Max octets au plus; Total = octets recus }
Function TLink.SerRecv(Var Buf;Max:Word;Var Total:Word):Boolean;
Var Start,Got,Cnt:Word;Fl:Byte;
Begin
 SerRecv:=False;
 Total:=0;
 If Base=0 Then Exit;
 RecvSync:=RECV_PACK_TICKS;
 Start:=0;
 Cnt:=Max;
 Repeat
  If SerRecvBlock(Buf,Start,Cnt,Got,Fl) Then Begin
   RecvSync:=SYNC_TICKS;
   Inc(Total,Got);
   If (Fl and CONTINUED_PACKET)=0 Then Begin SerRecv:=True;Exit;End;
   Inc(Start,Got);
   Dec(Cnt,Got);
  End
   Else
  Begin
   RecvSync:=SYNC_TICKS;
   If (ErrNo=-1) Or (ErrNo>0) Then Begin Lost;Exit;End;
  End;
 Until False;
End;

 { ------------------------------------------------------------------ parallele }

  { Lit le registre d'etat 5 fois: True si les 5 lectures sont identiques }
Function TLink.ReadStat(Var V:Byte):Boolean;
Var A:Byte;I:Integer;
Begin
 ReadStat:=False;
 A:=InB(Base+1) and $F8;
 For I:=1 to 4 do If (InB(Base+1) and $F8)<>A Then Exit;
 V:=A;
 ReadStat:=True;
End;

  { Attend que le bit 7 du registre d'etat vaille Want (lecture simple en mode
    rapide, lecture stabilisee sinon) }
Function TLink.WaitS7(Want:Boolean;Fast:Boolean;Var V:Byte):Boolean;
Var S:Byte;
Begin
 WaitS7:=True;
 Repeat
  If Fast Then Begin
   S:=InB(Base+1);
   V:=S and $F8;
   If ((S and $80)<>0)=Want Then Exit;
  End
   Else
  If ReadStat(V) Then If ((V and $80)<>0)=Want Then Exit;
 Until Expired;
 WaitS7:=False;
End;


  { Attend que le registre d'etat (stabilise) prenne exactement la valeur Want }
Function TLink.WaitVal(Want:Byte):Boolean;
Var V:Byte;
Begin
 WaitVal:=True;
 Repeat
  If ReadStat(V) Then If V=Want Then Exit;
 Until Expired;
 WaitVal:=False;
End;

  { Sauvegarde les registres du port parallele et le met dans l'etat de repos }
Procedure TLink.ParSave;
Var Orig,Rd,Chg,Std,Res,I,Bit:Byte;
Begin
 Orig:=InB(Base+2);
 OutB(Base+2,0);
 Rd:=InB(Base+2);
 OutB(Base+2,$0F);
 Chg:=Rd xor InB(Base+2);
 Chg:=(Chg or $F0) and $DF;
 Std:=$0C;
 Res:=0;
 For I:=0 to 7 do Begin
  If (Chg and 1)<>0 Then Bit:=Orig and 1 Else Bit:=Std and 1;
  Chg:=Chg shr 1;
  Orig:=Orig shr 1;
  Std:=Std shr 1;
  Res:=Res or (Bit shl I);
 End;
 OutB(Base+2,$0C);
 SavePar[1]:=Res;
 SavePar[0]:=InB(Base);
End;

Procedure TLink.ParRestore;Begin
 OutB(Base,SavePar[0]);
 OutB(Base+2,SavePar[1]);
End;

  { Envoie un octet (quartet bas avec le bit de transition, puis quartet haut)
    et retourne dans Ack l'etat final du cable (acquittement) }
Function TLink.ParTx(B:Byte;Ticks:Word;Var Ack:Byte):Boolean;
Var V:Byte;
Begin
 ParTx:=False;
 SetAlarm(Ticks);
 CrcAdd(B);
 OutB(Base,B or $10);
 If Not WaitS7(False,False,V) Then Exit;
 OutB(Base,B shr 4);
 If Not WaitS7(True,False,V) Then Exit;
 Ack:=V;
 ParTx:=True;
End;

  { Recoit un octet sans envoyer l'acquittement final }
Function TLink.ParRxNoAck(Ticks:Word;Var B:Byte):Boolean;
Var V1,V2:Byte;
Begin
 ParRxNoAck:=False;
 SetAlarm(Ticks);
 If Not WaitS7(False,False,V1) Then Exit;
 OutB(Base,(Not WNAK) and $FF);
 If Not WaitS7(True,False,V2) Then Exit;
 B:=((V1 shr 3) and $0F) or ((V2 shl 1) and $F0);
 CrcAdd(B);
 ParRxNoAck:=True;
End;

Function TLink.ParRx(Ticks:Word;Var B:Byte):Boolean;Begin
 ParRx:=False;
 If Not ParRxNoAck(Ticks,B) Then Exit;
 OutB(Base,WNAK);
 ParRx:=True;
End;

  { Premier octet d'un paquet recu: attend la transition du cable et repond
    aux quartets d'inactivite envoyes par le client pour garder la liaison }
Function TLink.ParRxSync(Ticks:Word;Var B:Byte):Boolean;
Var V,V1,Last:Byte;T0,TS:Word;
Begin
 ParRxSync:=False;
 T0:=Now;
 TS:=T0;
 Last:=$FF;
 Repeat
  PollAbort;
  If Aborted Then Exit;
  If ReadStat(V) Then Begin
   If (V and $80)=0 Then Begin
    V1:=V;
    OutB(Base,(Not WNAK) and $FF);
    Repeat
     If ReadStat(V) Then
      If (V and $80)<>0 Then Begin
       B:=((V1 shr 3) and $0F) or ((V shl 1) and $F0);
       CrcAdd(B);
       ParRxSync:=True;
       Exit;
      End;
     PollAbort;
    Until (Word(Now-TS)>Ticks) Or Aborted;
    Exit;
   End
    Else
   If (V=$D0) Or (V=$A8) Then Begin
    If Word(Now-T0)>=3 Then Begin
     OutB(Base,(V shr 3) and $0F);
     If V<>Last Then Begin
      Last:=V;
      TS:=Now;
     End;
    End;
   End;
  End;
 Until Word(Now-TS)>Ticks;
End;

  { Attend que l'emetteur acquitte notre dernier quartet (retournement de ligne) }
Procedure TLink.ParWaitSendAck(Last:Byte);
Var V,Want:Byte;
Begin
 SetAlarm(MINIMUM_TICKS);
 Want:=((Not Last) and $FF) and $F0;
 Repeat
  If ReadStat(V) Then If ((V shl 1) and $FF)=Want Then Exit;
 Until Expired;
End;

Function TLink.ParSendData(Var Buf;Len:Word):Boolean;
Var I,N:Word;B,V:Byte;Fast:Boolean;
Begin
 ParSendData:=False;
 Fast:=ParSpeed<>0;
 N:=Len;
 I:=0;
 Repeat
  SetAlarm(MINIMUM_TICKS);
  B:=TBuf(Buf)[I];
  OutB(Base,B or $10);
  If Not WaitS7(False,Fast,V) Then Exit;
  OutB(Base,B shr 4);
  CrcAdd(B);
  If Not WaitS7(True,Fast,V) Then Exit;
  Inc(I);
  Dec(N);
 Until N=0;
 ParSendData:=True;
End;

  { Envoie un paquet (Len=0 signifie 65536 octets). En cas d'erreur a vitesse
    "turbo", reessaie une fois a vitesse normale. }
Function TLink.ParSend(Var Buf;Len:Word):Boolean;
Var A:Byte;C:Word;Fatal,Done,Failed:Boolean;
Begin
 ParSend:=False;
 If Base=0 Then Exit;
 If LastOp<>OP_SEND Then Begin
  ParWaitSendAck(LastNibRecv);
  LastOp:=OP_SEND;
 End;
 Repeat
  Fatal:=False;
  Done:=False;
  Failed:=False;
  Crc:=INITIAL_CRC;
  If Not ParTx(SeqNum,SYNC_TICKS,A) Then Fatal:=True
   Else
  If A<>RACK Then Fatal:=True
   Else
  If Not ParTx(Len and $FF,MINIMUM_TICKS,A) Then Fatal:=True
   Else
  If Not ParTx(Len shr 8,MINIMUM_TICKS,A) Then Fatal:=True
   Else
  Begin
   Failed:=Not ParSendData(Buf,Len);
   If Not Failed Then Begin
    C:=(Not Crc) and $FFFF;
    Failed:=Not ParTx(C shr 8,MINIMUM_TICKS,A);
    If Not Failed Then Begin
     LastNibSent:=(C and $FF) shr 4;
     Failed:=Not ParTx(C and $FF,MINIMUM_TICKS,A);
     If Not Failed Then Begin
      If A=RACK Then Begin
       SeqNum:=(SeqNum+1) and 3;
       Done:=True;
      End
       Else
      Begin
       Inc(CrcErrors);
       Failed:=True;
      End;
     End;
    End;
   End;
   If Failed Then Begin
    If ParSpeed=0 Then Fatal:=True
     Else
    Begin
     ParSpeed:=0;
     OutB(Base,WNAK);
     Delay(4*MINIMUM_TICKS);
    End;
   End;
  End;
  If Fatal Then Begin
   OutB(Base,WNAK);
   Lost;
  End;
 Until Done Or Fatal;
 ParSend:=Done;
End;

Function TLink.ParRecvData(Var Buf;Len:Word):Boolean;
Var I,N:Word;B,V1,V2:Byte;Fast:Boolean;
Begin
 ParRecvData:=False;
 Fast:=ParSpeed<>0;
 N:=Len;
 I:=0;
 Repeat
  SetAlarm(MINIMUM_TICKS);
  If Not WaitS7(False,Fast,V1) Then Exit;
  If Fast Then V1:=InB(Base+1) and $F8;
  OutB(Base,(Not WNAK) and $FF);
  If Not WaitS7(True,Fast,V2) Then Exit;
  If Fast Then V2:=InB(Base+1) and $F8;
  OutB(Base,WNAK);
  B:=((V1 shr 3) and $0F) or ((V2 shl 1) and $F0);
  TBuf(Buf)[I]:=B;
  CrcAdd(B);
  Inc(I);
  Dec(N);
 Until N=0;
 ParRecvData:=True;
End;

  { Recoit un paquet de Max octets au plus (Max=0 signifie 65536) }
Function TLink.ParRecv(Var Buf;Max:Word;Var Total:Word):Boolean;
Var B,Bl,Bh:Byte;Len,T1,T2:Word;Fatal,Done,Failed:Boolean;
Begin
 ParRecv:=False;
 Total:=0;
 If Base=0 Then Exit;
 If LastOp<>OP_RECV Then Begin
  OutB(Base,(Not LastNibSent) and $0F);
  LastOp:=OP_RECV;
 End;
 Repeat
  Fatal:=False;
  Done:=False;
  Failed:=False;
  Crc:=INITIAL_CRC;
  If Not ParRxSync(RECV_PACK_TICKS,B) Then Fatal:=True
   Else
  If (B and SEQUENCE_BITS)<>SeqNum Then Fatal:=True
   Else
  Begin
   OutB(Base,WACK);
   If Not ParRx(MINIMUM_TICKS,Bl) Then Fatal:=True
    Else
   If Not ParRx(MINIMUM_TICKS,Bh) Then Fatal:=True
    Else
   Begin
    Len:=Bl or (Word(Bh) shl 8);
    T1:=Len;
    Dec(T1);
    T2:=Max;
    Dec(T2);
    If T1>T2 Then Fatal:=True
     Else
    Begin
     Failed:=Not ParRecvData(Buf,Len);
     If Not Failed Then Failed:=Not ParRx(MINIMUM_TICKS,B);
     If Not Failed Then Failed:=Not ParRxNoAck(MINIMUM_TICKS,B);
     If Not Failed Then Begin
      If Crc=MAGIC_CRC Then Begin
       OutB(Base,WACK);
       LastNibRecv:=B;
       SeqNum:=(SeqNum+1) and 3;
       Total:=Len;
       Done:=True;
      End
       Else
      Begin
       Inc(CrcErrors);
       Failed:=True;
      End;
     End;
     If Failed Then Begin
      If ParSpeed=0 Then Fatal:=True
       Else
      Begin
       ParSpeed:=0;
       OutB(Base,WNAK);
       Delay(2*MINIMUM_TICKS);
      End;
     End;
    End;
   End;
  End;
  If Fatal Then Begin
   OutB(Base,WNAK);
   Lost;
  End;
 Until Done Or Fatal;
 ParRecv:=Done;
End;

Function TLink.Send(Var Buf;Len:Word):Boolean;Begin
 If IsSerial<>0 Then Send:=SerSend(Buf,Len) Else Send:=ParSend(Buf,Len);
End;

Function TLink.Recv(Var Buf;Max:Word;Var Total:Word):Boolean;Begin
 If IsSerial<>0 Then Recv:=SerRecv(Buf,Max,Total) Else Recv:=ParRecv(Buf,Max,Total);
End;
{ ================================================================== END ENGINE }
{ ================================================================== BEGIN SERVER DATA }
Const
 MAX_SLAVE_DEVICES=26;
 SDP_INACTIVE=0; SDP_READING=1; SDP_WRITING=2; SDP_PRINTING=3;
 PACKET_TYPES=30;
 SERIAL_PORT=0; PARALLEL_PORT=1;
 MAX_PORTS=8;
 BIOS_PRINT_REQ=25; BIOS_STATUS_REQ=27;
 DEVICE_OPEN=13; DEVICE_CLOSE=14;

Type
 TMap=Array[0..MAX_DEVICES-1] of Byte;
  { Un lecteur du serveur }
 TDevice=Record
  Header:Pointer;                 { en-tete du pilote de peripherique }
  Dpb:Pointer;
  Attribute,Bps:Word;
  Drive,Unit_,Invalid,MediaDesc:Byte;
  DataSize:LongInt;
  NFats,Spc:Byte;
  NonRemovable,IsFloppy:Boolean;
  VolLabel:Array[0..11] of Char;  { doit preceder Serial: les deux sont envoyes ensemble }
  Serial:LongInt;
 End;
 TPrinter=Record
  Addr:Word;
  Enabled:Boolean;
 End;
 TPortInfo=Record
  Typ,Bios:Byte;
  Addr:Word;
  Bad:Boolean;
  State:Byte;
  SaveSer:Array[0..4] of Byte;     { etat d'origine du UART }
  SavePar:Array[0..1] of Byte;     { etat d'origine du port parallele }
 End;
 PServerInfoReq=^TServerInfoReq;

Var
 Link:TLink;
 Ports:Array[0..MAX_PORTS-1] of TPortInfo;
 NumPorts,CurPort:Integer;
 Connected:Boolean;
 Devices:Array[0..MAX_SLAVE_DEVICES-1] of TDevice;
 SlaveDevices:Integer;
 DrivePriority:Array[0..25] of Byte;
 NumDrives,NumIncludes:Integer;
 IncludedDrives,ExcludedDrives:Array[0..25] of Byte;
 LptDrivers:Array[0..2] of Pointer;
 Printers:Array[0..2] of TPrinter;
 NumLpt,NumServerFloppies:Integer;
 ActualPrnMap:Array[0..2] of Byte;
 SlaveDosVersion,MasterDosVersion:Word;
 MasterMaxDevices,MasterFirstUnit:Byte;
 Packet:Array[0..127] of Byte;
 Buffer:PBuf;
 Rh:TReq;
 MediaBuf:TMediaIdBuf;
 LastClientId,ServerId:LongInt;
 SettingsMaxBaud:Byte;
 SettingsMaxBlock:Word;
 ListenStart:Word;
 CurDrive,CurPrinter,CurState:Integer;
{ ================================================================== END SERVER DATA }

 { ------------------------------------------------------------------ acces DOS bas niveau }
Type
 PtrRec=Record Ofs,Seg:Word;End;

{ -- DOS-LOW2-BEGIN -- }
Function PeekB(S,O:Word):Byte;Begin PeekB:=Mem[S:O];End;
Function PeekW(S,O:Word):Word;Begin PeekW:=MemW[S:O];End;
Procedure PokeB(S,O:Word;V:Byte);Begin Mem[S:O]:=V;End;
Procedure PokeW(S,O,V:Word);Begin MemW[S:O]:=V;End;
Function MakePtr(S,O:Word):Pointer;Begin MakePtr:=Ptr(S,O);End;
Function OfsOf(P:Pointer):Word;Begin OfsOf:=PtrRec(P).Ofs;End;
Function SegOf(P:Pointer):Word;Begin SegOf:=PtrRec(P).Seg;End;
{ -- DOS-LOW2-END -- }

 { ------------------------------------------------------------------ messages }
Const
 M_BANNER=1; M_NEEDDOS=2; M_INVSERVER=3; M_INVOPTION=4; M_INVBAUD=5; M_INVBLOCK=6;
 M_NOPORTS=7; M_PORTERR=8; M_BADSER=9; M_BADPAR=10; M_IDLE=11; M_READING=12;
 M_WRITING=13; M_PRINTING=14; M_NOTCONN=15; M_SERVER=16; M_CLIENT=17; M_QUIT=18;
 M_NOBUFFER=19; M_RCOPY=20; M_NODRIVES=21; M_PORT=22; M_SPEED=23; M_STATE=24;
 M_USAGE=40;

Type
 TLanguage=(_French,_English,_Germany);

Var
 Language:TLanguage;
 TmpLanguage:String;

Function Msg(N:Integer):String;Begin
 Case Language of
  _English:Case N of
   M_BANNER:Msg:='Microsoft InterSvr (Pascal clone)  Version 1.00';
   M_NEEDDOS:Msg:='InterSvr requires DOS 3.1 or later.';
   M_INVSERVER:Msg:='Invalid server drive: ';
   M_INVOPTION:Msg:='Unrecognized option: ';
   M_INVBAUD:Msg:='Invalid /BAUD rate (9600, 19200, 38400, 57600 or 115200): ';
   M_INVBLOCK:Msg:='Invalid /MAXBLOCK value (1 to 32768): ';
   M_NOPORTS:Msg:='No communication port available.';
   M_PORTERR:Msg:='Unable to initialize the port ';
   M_BADSER:Msg:='Invalid serial port address ';
   M_BADPAR:Msg:='Invalid parallel port address ';
   M_IDLE:Msg:='Idle';
   M_READING:Msg:='Reading';
   M_WRITING:Msg:='Writing';
   M_PRINTING:Msg:='Printing';
   M_NOTCONN:Msg:='(not connected)';
   M_SERVER:Msg:='Server';
   M_CLIENT:Msg:='Client';
   M_QUIT:Msg:='F3=Quit';
   M_NOBUFFER:Msg:='Not enough memory for the transfer buffer.';
   M_RCOPY:Msg:='The /RCOPY option (copy of INTERLNK to a client) is not supported by this version.';
   M_NODRIVES:Msg:='No drive can be shared.';
   M_PORT:Msg:='Port=';
   M_SPEED:Msg:='Speed=';
   M_STATE:Msg:='Status: ';
   M_USAGE:Msg:='Shares the drives and printers of this computer with a client computer running INTERLNK.';
   M_USAGE+1:Msg:='INTERSVR [drive: ...] [/X=drive ...] [/COM[:n|:addr]] [/LPT[:n|:addr]]';
   M_USAGE+2:Msg:='         [/BAUD:rate] [/MAXBLOCK:n] [/B] [/V] [/RCOPY]';
   M_USAGE+3:Msg:='  drive:      Drives to share (default: all the drives, in order).';
   M_USAGE+4:Msg:='  /X=drive    Drives that must not be shared.';
   M_USAGE+5:Msg:='  /COM, /LPT  Ports to listen on (all, BIOS number or address).';
   M_USAGE+6:Msg:='  /BAUD:rate  Maximum serial rate: 9600, 19200, 38400, 57600 or 115200.';
   M_USAGE+7:Msg:='  /MAXBLOCK:n Maximum size of a serial block.';
   M_USAGE+8:Msg:='  /B          Black and white display.';
   M_USAGE+9:Msg:='  /V          Forces the echo of each byte (variable speed mode).';
   M_USAGE+10:Msg:='  /RCOPY      Copies INTERLNK to a client (not supported).';
   M_USAGE+11:Msg:='The options can also be set in the INTERSVR environment variable.';
  End;
  _Germany:Case N of
   M_BANNER:Msg:='Microsoft InterSvr (Pascal-Klon)  Version 1.00';
   M_NEEDDOS:Msg:='InterSvr benoetigt DOS 3.1 oder hoeher.';
   M_INVSERVER:Msg:='Ungueltiges Server-Laufwerk: ';
   M_INVOPTION:Msg:='Unbekannte Option: ';
   M_INVBAUD:Msg:='Ungueltige /BAUD-Rate (9600, 19200, 38400, 57600 oder 115200): ';
   M_INVBLOCK:Msg:='Ungueltiger /MAXBLOCK-Wert (1 bis 32768): ';
   M_NOPORTS:Msg:='Keine Schnittstelle verfuegbar.';
   M_PORTERR:Msg:='Schnittstelle kann nicht initialisiert werden: ';
   M_BADSER:Msg:='Ungueltige Adresse der seriellen Schnittstelle ';
   M_BADPAR:Msg:='Ungueltige Adresse der parallelen Schnittstelle ';
   M_IDLE:Msg:='Bereit';
   M_READING:Msg:='Lesen';
   M_WRITING:Msg:='Schreiben';
   M_PRINTING:Msg:='Drucken';
   M_NOTCONN:Msg:='(nicht verbunden)';
   M_SERVER:Msg:='Server';
   M_CLIENT:Msg:='Client';
   M_QUIT:Msg:='F3=Ende';
   M_NOBUFFER:Msg:='Nicht genug Speicher fuer den Uebertragungspuffer.';
   M_RCOPY:Msg:='Die Option /RCOPY (Kopie von INTERLNK auf einen Client) wird nicht unterstuetzt.';
   M_NODRIVES:Msg:='Kein Laufwerk kann freigegeben werden.';
   M_PORT:Msg:='Port=';
   M_SPEED:Msg:='Rate=';
   M_STATE:Msg:='Status: ';
   M_USAGE:Msg:='Gibt Laufwerke und Drucker dieses Computers fuer einen Client mit INTERLNK frei.';
   M_USAGE+1:Msg:='INTERSVR [Laufwerk: ...] [/X=Laufwerk ...] [/COM[:n|:Adr]] [/LPT[:n|:Adr]]';
   M_USAGE+2:Msg:='         [/BAUD:Rate] [/MAXBLOCK:n] [/B] [/V] [/RCOPY]';
   M_USAGE+3:Msg:='  Laufwerk:   Freizugebende Laufwerke (Standard: alle, der Reihe nach).';
   M_USAGE+4:Msg:='  /X=Laufwerk Laufwerke, die nicht freigegeben werden.';
   M_USAGE+5:Msg:='  /COM, /LPT  Schnittstellen zum Abhoeren (alle, BIOS-Nummer, Adresse).';
   M_USAGE+6:Msg:='  /BAUD:Rate  Hoechste serielle Rate: 9600, 19200, 38400, 57600 oder 115200.';
   M_USAGE+7:Msg:='  /MAXBLOCK:n Hoechste Groesse eines seriellen Blocks.';
   M_USAGE+8:Msg:='  /B          Schwarzweiss-Anzeige.';
   M_USAGE+9:Msg:='  /V          Erzwingt das Echo jedes Bytes.';
   M_USAGE+10:Msg:='  /RCOPY      Kopiert INTERLNK auf einen Client (nicht unterstuetzt).';
   M_USAGE+11:Msg:='Die Optionen koennen auch in der Variablen INTERSVR stehen.';
  End;
  Else Case N of
   M_BANNER:Msg:='Microsoft InterSvr (clone Pascal)  Version 1.00';
   M_NEEDDOS:Msg:='InterSvr requiert DOS 3.1 ou superieur.';
   M_INVSERVER:Msg:='Lecteur serveur invalide : ';
   M_INVOPTION:Msg:='Option non reconnue : ';
   M_INVBAUD:Msg:='Vitesse /BAUD invalide (9600, 19200, 38400, 57600 ou 115200) : ';
   M_INVBLOCK:Msg:='Valeur /MAXBLOCK invalide (1 a 32768) : ';
   M_NOPORTS:Msg:='Aucun port de communication disponible.';
   M_PORTERR:Msg:='Impossible d''initialiser le port ';
   M_BADSER:Msg:='Adresse de port serie invalide ';
   M_BADPAR:Msg:='Adresse de port parallele invalide ';
   M_IDLE:Msg:='Repos';
   M_READING:Msg:='Lecture';
   M_WRITING:Msg:='Ecriture';
   M_PRINTING:Msg:='Impression';
   M_NOTCONN:Msg:='(non connecte)';
   M_SERVER:Msg:='Serveur';
   M_CLIENT:Msg:='Client';
   M_QUIT:Msg:='F3=Quitter';
   M_NOBUFFER:Msg:='Memoire insuffisante pour le tampon de transfert.';
   M_RCOPY:Msg:='L''option /RCOPY (copie de INTERLNK sur un client) n''est pas prise en charge par cette version.';
   M_NODRIVES:Msg:='Aucun lecteur ne peut etre partage.';
   M_PORT:Msg:='Port=';
   M_SPEED:Msg:='Vitesse=';
   M_STATE:Msg:='Etat : ';
   M_USAGE:Msg:='Partage les lecteurs et les imprimantes de cet ordinateur avec un client executant INTERLNK.';
   M_USAGE+1:Msg:='INTERSVR [lecteur: ...] [/X=lecteur ...] [/COM[:n|:adr]] [/LPT[:n|:adr]]';
   M_USAGE+2:Msg:='         [/BAUD:vitesse] [/MAXBLOCK:n] [/B] [/V] [/RCOPY]';
   M_USAGE+3:Msg:='  lecteur:    Lecteurs a partager (par defaut: tous, dans l''ordre).';
   M_USAGE+4:Msg:='  /X=lecteur  Lecteurs qui ne doivent pas etre partages.';
   M_USAGE+5:Msg:='  /COM, /LPT  Ports a ecouter (tous, numero du BIOS ou adresse).';
   M_USAGE+6:Msg:='  /BAUD:vit.  Vitesse serie maximale: 9600, 19200, 38400, 57600 ou 115200.';
   M_USAGE+7:Msg:='  /MAXBLOCK:n Taille maximale d''un bloc serie.';
   M_USAGE+8:Msg:='  /B          Affichage noir et blanc.';
   M_USAGE+9:Msg:='  /V          Force l''echo de chaque octet (mode a vitesse variable).';
   M_USAGE+10:Msg:='  /RCOPY      Copie INTERLNK sur un client (non prise en charge).';
   M_USAGE+11:Msg:='Les options peuvent aussi se trouver dans la variable INTERSVR.';
  End;
 End;
End;

Function StrUpper(S:String):String;
Var I:Integer;
Begin
 For I:=1 to Length(S) do S[I]:=UpCase(S[I]);
 StrUpper:=S;
End;

Function DecStr(V:LongInt):String;
Var S:String;
Begin
 Str(V,S);
 DecStr:=S;
End;

Function Pad(S:String;N:Integer):String;Begin
 While Length(S)<N do S:=S+' ';
 Pad:=S;
End;

Function LabelStr(Var A;Max:Integer):String;
Var I:Integer;S:String;
Begin
 S:='';
 I:=0;
 While (I<Max) And (TBuf(A)[I]<>0) do Begin
  S:=S+Chr(TBuf(A)[I]);
  Inc(I);
 End;
 LabelStr:=S;
End;

  { Texte de la taille d'un lecteur: vide pour une disquette ou un support amovible }
Function DriveSize(I:Integer):String;
Begin
 If (Devices[I].DataSize=0) Or Devices[I].IsFloppy Or (Not Devices[I].NonRemovable) Then DriveSize:=''
  Else
 If Devices[I].DataSize<2000000 Then DriveSize:=DecStr(Devices[I].DataSize div 1000)+'Kb'
  Else
 DriveSize:=DecStr(Devices[I].DataSize div 1000000)+'Mb';
End;

 { ------------------------------------------------------------------ plateforme DOS }
Var
 ColorOn:Boolean;
 TopRow,LeftCol,Rows:Integer;
 Regs:Registers;

{ -- DOS-LOW4-BEGIN -- }
{ -- BASM-BEGIN -- }
  { Appel eloigne d'une routine d'un pilote avec ES:BX = en-tete de requete }
Procedure FarCall(Rq,Fn:Pointer);Assembler;
Asm
 push ds
 push si
 push di
 les  bx,Rq
 call dword ptr Fn
 cld
 pop  di
 pop  si
 pop  ds
End;

{ -- BASM-END -- }

  { Transmet une requete a un pilote de peripherique: strategie puis interruption }
Procedure CallDriver(Var Rq:TReq;Hdr:Pointer);
Var S,O:Word;
Begin
 S:=SegOf(Hdr);
 O:=OfsOf(Hdr);
 FarCall(@Rq,MakePtr(S,PeekW(S,O+6)));
 FarCall(@Rq,MakePtr(S,PeekW(S,O+8)));
End;

{ -- BASM2-BEGIN -- }
  { Gestionnaire d'erreur critique: toujours "Echec" (AL=3) }
Procedure CritErr;Assembler;
Asm
 mov  al,3
 iret
End;
{ -- BASM2-END -- }

Procedure ResetDisk;Begin
 Regs.AH:=$0D;
 MsDos(Regs);
End;

  { Imprimante par le BIOS (INT 17h): retourne l'octet d'etat }
Function BiosPrinter(Cmd,Port,Ch:Byte):Byte;Begin
 Regs.AH:=Cmd;
 Regs.AL:=Ch;
 Regs.DX:=Port;
 Intr($17,Regs);
 BiosPrinter:=Regs.AH;
End;

Function IsIlDrive(Drv:Byte):Boolean;Begin
 Regs.AX:=$5601;
 Regs.BH:=Drv;
 Regs.BL:=0;
 Regs.DX:=$FFFF;
 Intr($2F,Regs);
 IsIlDrive:=Regs.AL=$FF;
End;

  { Nom de volume et numero de serie d'un lecteur }
Procedure ReadVolumeLabel(Dev:Integer);
Var SR:SearchRec;I,J:Integer;Path:String;
Begin
 Devices[Dev].VolLabel[0]:=#0;
 Devices[Dev].Serial:=0;
 Path:=Chr(65+Devices[Dev].Drive)+':\*.*';
 FindFirst(Path,VolumeID,SR);
 If DosError=0 Then Begin
  J:=0;
  FillChar(Devices[Dev].VolLabel,SizeOf(Devices[Dev].VolLabel),0);
  For I:=1 to Length(SR.Name) do
   If SR.Name[I]='.' Then Begin
    While J<8 do Begin
     Devices[Dev].VolLabel[J]:=' ';
     Inc(J);
    End;
   End
    Else
   Begin
    Devices[Dev].VolLabel[J]:=SR.Name[I];
    Inc(J);
   End;
 End;
 If (Lo(DosVersion)>=4) And ((Devices[Dev].Attribute and ATT_GEN_IOCTL)<>0) Then Begin
  FillChar(Rh,SizeOf(Rh),0);
  Rh.Len:=23;
  Rh.Unit_:=Devices[Dev].Unit_;
  Rh.Cmd:=19;
  Rh.Category:=8;
  Rh.Func:=$66;
  Rh.GenData:=@MediaBuf;
  CallDriver(Rh,Devices[Dev].Header);
  If (Rh.Status and STATUS_ERROR)=0 Then Devices[Dev].Serial:=MediaBuf.Serial;
 End;
End;

  { ------------------------------------------------------------------ ecran }
Procedure Attr(Normal,Bright:Integer);Begin
 If ColorOn Then TextAttr:=Normal Else TextAttr:=Bright;
End;

Procedure PutAt(R,C:Integer;S:String);Begin
 GotoXY(C+1,R+1);
 Write(S);
End;

Procedure DrawBox(R,C,H,W:Integer);
Var I:Integer;
Begin
 Attr($1F,$07);
 PutAt(R,C,Chr(218)+Pad('',W-2)+Chr(191));
 For I:=1 to W-2 do PutAt(R,C+I,Chr(196));
 For I:=1 to H-2 do Begin
  PutAt(R+I,C,Chr(179));
  PutAt(R+I,C+W-1,Chr(179));
  PutAt(R+I,C+1,Pad('',W-2));
 End;
 PutAt(R+H-1,C,Chr(192)+Pad('',W-2)+Chr(217));
 For I:=1 to W-2 do PutAt(R+H-1,C+I,Chr(196));
End;

Function SpeedText:String;
Begin
 If CurPort<0 Then SpeedText:=''
  Else
 If Link.IsSerial<>0 Then Begin
  Case Link.Baud of
   0:SpeedText:='1200';
   1:SpeedText:='2400';
   2:SpeedText:='4800';
   3:SpeedText:='9600';
   4:SpeedText:='19200';
   5:SpeedText:='38400';
   6:SpeedText:='57600';
   Else SpeedText:='115200';
  End;
 End
  Else
 If Link.ParSpeed<>0 Then SpeedText:='Turbo' Else SpeedText:='Normal';
End;

Function PortText:String;
Var S:String;
Begin
 PortText:='';
 If (CurPort<0) Or (Not Connected) Then Exit;
 With Ports[CurPort] do Begin
  If Typ=SERIAL_PORT Then S:='COM' Else S:='LPT';
  If Bios<>0 Then S:=S+DecStr(Bios) Else S:=S+'('+DecStr(Addr)+')';
 End;
 PortText:=S;
End;

Procedure UiBar;
Var S:String;
Begin
 Attr($30,$70);
 S:=' '+Msg(M_PORT)+Pad(PortText,10)+' '+Msg(M_SPEED)+Pad(SpeedText,8)+' ';
 Case CurState of
  SDP_READING:S:=S+Msg(M_STATE)+Pad(Msg(M_READING),12);
  SDP_WRITING:S:=S+Msg(M_STATE)+Pad(Msg(M_WRITING),12);
  SDP_PRINTING:S:=S+Msg(M_STATE)+Pad(Msg(M_PRINTING),12);
  Else S:=S+Msg(M_STATE)+Pad(Msg(M_IDLE),12);
 End;
 S:=Pad(S,70)+Msg(M_QUIT);
 S:=Pad(S,80);
 PutAt(24,0,Copy(S,1,79));
End;

  { Etat courant: repos, lecture, ecriture, impression (marque * devant le lecteur) }
Procedure UiStatus(K:Integer);
Var I:Integer;
Begin
 CurState:=K;
 Attr($1F,$07);
 For I:=0 to NumDrives-1 do If I<Rows Then Begin
  If (K=SDP_READING) Or (K=SDP_WRITING) Then
   If I=CurDrive Then PutAt(TopRow+4+I,LeftCol+1,'*')
    Else PutAt(TopRow+4+I,LeftCol+1,' ')
  Else PutAt(TopRow+4+I,LeftCol+1,' ');
 End;
 UiBar;
End;

Procedure UiPort;Begin
 UiBar;
End;

  { Affiche la correspondance des lecteurs et des imprimantes (Show = colonne du client) }
Procedure UiMap(Var Map:TMap;Show:Boolean);
Var I,Di,Row:Integer;SlaveMap:Array[0..MAX_DEVICES-1] of Byte;S,T:String;
Begin
 FillChar(SlaveMap,SizeOf(SlaveMap),$FF);
 For I:=0 to MAX_DEVICES-1 do
  If Map[I]<MAX_DEVICES Then SlaveMap[Map[I]]:=I;
 Attr($1F,$07);
 For I:=0 to NumDrives-1 do Begin
  Di:=DrivePriority[I];
  S:=Chr(65+Devices[Di].Drive)+':';
  T:=Pad(S,3)+Pad(DriveSize(Di),9);
  If Show Then Begin
   If (SlaveMap[Di]<>$FF) And (MasterFirstUnit+SlaveMap[Di]<MAX_DEVICES) Then
    T:=T+'=  '+Chr(65+MasterFirstUnit+SlaveMap[Di])+':'
   Else T:=T+'   '+Msg(M_NOTCONN);
  End;
  If I<Rows Then PutAt(TopRow+4+I,LeftCol+3,Pad(T,34));
 End;
 For I:=0 to NumLpt-1 do Begin
  Row:=TopRow+4+NumDrives+I;
  T:=Pad('LPT'+DecStr(I+1)+':',12);
  If Printers[I].Enabled And Show Then Begin
   Di:=0;
   While (Di<3) And (ActualPrnMap[Di]<>I) do Inc(Di);
   If Di<3 Then T:=T+'=  LPT'+DecStr(Di+1)+':' Else T:=T+'   '+Msg(M_NOTCONN);
  End;
  If Row<TopRow+4+Rows Then PutAt(Row,LeftCol+3,Pad(T,34));
 End;
End;

Procedure UiInit;
Var I:Integer;S:String;
Begin
 TextAttr:=$07;
 ClrScr;
 Rows:=NumDrives+NumLpt;
 If Rows>16 Then Rows:=16;
 TopRow:=(24-(Rows+6)) div 2+1;
 If TopRow<1 Then TopRow:=1;
 LeftCol:=20;
 Attr($0F,$07);
 S:=Msg(M_BANNER);
 PutAt(0,(80-Length(S)) div 2,S);
 DrawBox(TopRow,LeftCol,Rows+5,40);
 Attr($1F,$07);
 PutAt(TopRow+1,LeftCol+3,Pad(Msg(M_SERVER),18)+Msg(M_CLIENT));
 PutAt(TopRow+2,LeftCol+3,Pad('('+Msg(M_SERVER)+')',18)+'('+Msg(M_CLIENT)+')');
 PutAt(TopRow+3,LeftCol,Chr(195));
 For I:=1 to 38 do PutAt(TopRow+3,LeftCol+I,Chr(196));
 PutAt(TopRow+3,LeftCol+39,Chr(180));
 GotoXY(1,25);
 UiBar;
End;

Procedure UiDone;Begin
 TextAttr:=$07;
 ClrScr;
End;
{ -- DOS-LOW4-END -- }

{ ================================================================== BEGIN SERVER LOGIC }
 { ------------------------------------------------------------------ correspondances }

Function InPriority(D:Byte):Boolean;
Var I:Integer;
Begin
 InPriority:=False;
 For I:=0 to NumDrives-1 do If DrivePriority[I]=D Then InPriority:=True;
End;

  { Attribue aux lecteurs du client (units) des lecteurs du serveur: les
    attributions demandees sont conservees si possible, les autres (DONT_CARE)
    recoivent les lecteurs restants dans l'ordre de priorite }
Procedure GenerateDriveMappings(Var Map:TMap;NumMaster:Integer;Var Desired:TMap);
Var I,MasterUnit:Integer;Used:Array[0..MAX_DEVICES-1] of Byte;Done:Boolean;
Begin
 Move(Desired,Map,MAX_DEVICES);
 FillChar(Used,SizeOf(Used),0);
 For I:=0 to MAX_DEVICES-1 do
  If Map[I]<MAX_DEVICES Then Begin
   If (Map[I]>=SlaveDevices) Or (Not InPriority(Map[I])) Then Map[I]:=UNASSIGNED
                                                          Else Used[Map[I]]:=1;
  End;
 MasterUnit:=0;
 I:=0;
 Done:=False;
 While (I<NumDrives) And (Not Done) do Begin
  While (MasterUnit<NumMaster) And (Map[MasterUnit]<>DONT_CARE) do Begin
   If Not InPriority(Map[MasterUnit]) Then Map[MasterUnit]:=UNASSIGNED;
   Inc(MasterUnit);
  End;
  If MasterUnit>=NumMaster Then Done:=True
   Else
  Begin
   While (I<NumDrives) And (Used[DrivePriority[I]]<>0) do Inc(I);
   If I>=NumDrives Then Done:=True
    Else
   Begin
    Map[MasterUnit]:=DrivePriority[I];
    Inc(I);
   End;
  End;
 End;
End;

  { Une imprimante n'est offerte que si elle ne sert pas de port de liaison }
Procedure MakePrinterMap;
Var I:Integer;
Begin
 For I:=0 to NumLpt-1 do
  Printers[I].Enabled:=(CurPort<0) Or (Ports[CurPort].Addr<>Printers[I].Addr) Or (Not Connected);
End;

Procedure SetupBlockDevices;
Var I:Integer;
Begin
 For I:=0 to MAX_SLAVE_DEVICES-1 do Devices[I].Invalid:=1;
End;

 { ------------------------------------------------------------------ paquets }

Function SrvInfoHandler:Boolean;
Var Rq:TServerInfoReq;An:TServerInfoAns;Got:Word;
Begin
 SrvInfoHandler:=False;
 If Not Link.Recv(Rq,SizeOf(Rq),Got) Then Exit;
 FillChar(An,SizeOf(An),0);
 An.Version:=(VerMajor shl 8) or VerMinor;
 An.DeviceServer:=1;
 An.Crc:=1;
 If Rq.MaxSerBlock<SettingsMaxBlock Then Link.MaxBlock:=Rq.MaxSerBlock
                                    Else Link.MaxBlock:=SettingsMaxBlock;
 An.MaxSerBlock:=Link.MaxBlock;
 An.LastClientId:=LastClientId;
 An.ServerId:=ServerId;
  { nouveau client (ou serveur redemarre): les donnees en cache du client sont perimees }
 If (Rq.ClientId<>LastClientId) Or (Rq.LastServerId<>ServerId) Then Begin
  LastClientId:=Rq.ClientId;
  ResetDisk;
  SetupBlockDevices;
 End;
 SrvInfoHandler:=Link.Send(An,SizeOf(An));
End;

Function InitHandler:Boolean;
Var Rq:TInitReq;An:TInitAns;Desired:TMap;Avail:Array[0..2] of Boolean;I,Mp,Sp:Integer;
Begin
 Move(Packet,Rq,SizeOf(Rq));
 MasterDosVersion:=Rq.DosVersion;
 MasterMaxDevices:=Rq.MaxDevices;
 MasterFirstUnit:=Rq.FirstUnit;
 Move(Rq.Mapping,Desired,MAX_DEVICES);
 FillChar(An,SizeOf(An),0);
 An.Devices:=SlaveDevices;
 An.MajorVersion:=VerMajor;
 An.MinorVersion:=VerMinor;
 An.DosVersion:=SlaveDosVersion;
 An.Multitasker:=0;
 MakePrinterMap;
 FillChar(ActualPrnMap,3,UNASSIGNED);
 For Sp:=0 to 2 do Avail[Sp]:=(Sp<NumLpt) And Printers[Sp].Enabled;
  { affectations imposees puis "peu importe" }
 For Mp:=0 to 2 do Begin
  Sp:=Rq.PrnMap[Mp];
  If (Sp<3) Then If Avail[Sp] Then Begin
   ActualPrnMap[Mp]:=Sp;
   Avail[Sp]:=False;
  End;
 End;
 For Mp:=0 to 2 do
  If Rq.PrnMap[Mp]=DONT_CARE Then Begin
   Sp:=0;
   While Sp<NumLpt do Begin
    If Avail[Sp] Then Begin
     ActualPrnMap[Mp]:=Sp;
     Avail[Sp]:=False;
     Sp:=NumLpt;
    End
     Else Inc(Sp);
   End;
  End;
 Move(ActualPrnMap,An.PrnMap,3);
 GenerateDriveMappings(TMap(An.Mapping),MasterMaxDevices,Desired);
 For I:=0 to SlaveDevices-1 do An.Attributes[I]:=Devices[I].Attribute;
 InitHandler:=Link.Send(An,SizeOf(An));
 UiMap(TMap(An.Mapping),True);
End;

Function MediaCheckHandler:Boolean;
Var Rq:TUnitReq;An:TMediaAns;Dev:Integer;Copied:Boolean;
Begin
 Move(Packet,Rq,SizeOf(Rq));
 Dev:=Rq.Unit_;
 Copied:=False;
 FillChar(An,SizeOf(An),0);
 If Dev>=SlaveDevices Then Begin
  An.Changed:=0;
  An.Status:=STATUS_ERROR or STATUS_DONE or ERR_UNK_UNIT;
 End
  Else
 Begin
  Rh.Len:=15;
  Rh.Unit_:=Devices[Dev].Unit_;
  Rh.Cmd:=1;
  Rh.Media:=Rq.MediaId;
  CallDriver(Rh,Devices[Dev].Header);
  An.Changed:=Rh.Changed;
  An.Status:=Rh.Status;
  If (Rh.Changed=$FF) And ((SlaveDosVersion shr 8)>=3) Then Begin
   Move(PBuf(Rh.MediaLabel)^,An.Volume,MAX_VOLUME);
   Copied:=True;
  End;
  If Not Copied Then Move(Devices[Dev].VolLabel,An.Volume,MAX_VOLUME+4);
 End;
 MediaCheckHandler:=Link.Send(An,SizeOf(An));
End;

  { Lit le premier secteur de la FAT: certains pilotes l'exigent avant la
    construction du BPB }
Function ReadFirstFatSector(Dev:Integer;MediaId:Byte):Boolean;
Begin
 ReadFirstFatSector:=False;
 If Dev>=SlaveDevices Then Begin
  Rh.Status:=STATUS_ERROR or STATUS_DONE or ERR_UNK_UNIT;
  Rh.Transferred:=0;
  Exit;
 End;
 Rh.Len:=30;
 Rh.Unit_:=Devices[Dev].Unit_;
 Rh.Cmd:=4;
 Rh.Media:=MediaId;
 Rh.IoData:=Buffer;
 Rh.IoCount:=1;
 If (SlaveDosVersion<DOS331) Or ((Devices[Dev].Attribute and ATT_HUGE)=0) Then Rh.IoStart:=1
  Else
 If SlaveDosVersion=DOS331 Then Begin
  Rh.Len:=24;
  Rh.IoStart:=1;
  Rh.IoStartHigh:=0;
 End
  Else
 Begin
  Rh.IoStart:=$FFFF;
  Rh.IoHuge:=1;
 End;
 CallDriver(Rh,Devices[Dev].Header);
 ReadFirstFatSector:=(Rh.Status and STATUS_ERROR)=0;
End;

Function BuildBpbHandler:Boolean;
Var Rq:TUnitReq;An:TBpbAns;Dev:Integer;Len:Word;Ok:Boolean;
Begin
 Move(Packet,Rq,SizeOf(Rq));
 Dev:=Rq.Unit_;
 FillChar(An,SizeOf(An),0);
 If Dev>=SlaveDevices Then Rh.Status:=STATUS_ERROR or STATUS_DONE or ERR_UNK_UNIT
  Else
 Begin
  Ok:=(Devices[Dev].Attribute and ATT_NON_IBM)<>0;
  If Not Ok Then Ok:=ReadFirstFatSector(Dev,Rq.MediaId);
  If Ok Then Begin
   FillChar(Rh,SizeOf(Rh),0);
   Rh.Len:=22;
   Rh.Unit_:=Devices[Dev].Unit_;
   Rh.Cmd:=2;
   Rh.Media:=Rq.MediaId;
   Rh.Fat:=Buffer;
   CallDriver(Rh,Devices[Dev].Header);
  End;
 End;
 An.Status:=Rh.Status;
 If (Rh.Status and STATUS_ERROR)=0 Then Begin
  Move(PBuf(Rh.BpbPtr)^,An.Bpb,SizeOf(TBpb));
  Devices[Dev].Bps:=An.Bpb.BytesPerSector;
  Len:=SizeOf(An);
  If Not Devices[Dev].NonRemovable Then Begin
   ResetDisk;
   ReadVolumeLabel(Dev);
  End;
 End
  Else
 Len:=2;
 BuildBpbHandler:=Link.Send(An,Len);
 If Dev<SlaveDevices Then Devices[Dev].Invalid:=0;
End;

  { Prepare la requete de lecture ou d'ecriture selon la version de DOS }
Procedure SetupIo(Dev:Integer;Var Rq:TIoReq;Cmd:Byte);Begin
 Rh.Len:=22;
 Rh.Unit_:=Devices[Dev].Unit_;
 Rh.Cmd:=Cmd;
 Rh.Media:=Rq.MediaId;
 Rh.IoData:=Buffer;
 Rh.IoCount:=Rq.Requested;
 Rh.IoStart:=Rq.Start;
 Rh.IoHuge:=Rq.HugeStart;
 If SlaveDosVersion=DOS331 Then Begin
  Rh.Len:=24;
  Rh.IoStart:=Word(Rq.HugeStart and $FFFF);
  Rh.IoStartHigh:=Word((Rq.HugeStart shr 16) and $FFFF);
 End;
End;

  { Reponse de lecture ou d'ecriture: etat, nombre transfere et, en cas de
    changement de disque, nom de volume }
Function SendIoAnswer(Transferred:Word):Boolean;
Var An:TIoAns;Len:Word;
Begin
 FillChar(An,SizeOf(An),0);
 An.Status:=Rh.Status;
 An.Transferred:=Transferred;
 Len:=4;
 If (Lo(Rh.Status)=ERR_DISK_CHANGE) And ((SlaveDosVersion shr 8)>=3) Then Begin
  Move(PBuf(Rh.IoLabel)^,An.Volume,MAX_VOLUME);
  Len:=Len+MAX_VOLUME+4;
 End;
 SendIoAnswer:=Link.Send(An,Len);
End;

Function ReadHandler:Boolean;
Var Rq:TIoReq;Dev:Integer;Done:Word;
Begin
 Move(Packet,Rq,SizeOf(Rq));
 Dev:=Rq.Unit_;
 If Dev>=SlaveDevices Then Begin
  Rh.Status:=STATUS_ERROR or STATUS_DONE or ERR_UNK_UNIT;
  Rh.Transferred:=0;
 End
  Else
 Begin
  SetupIo(Dev,Rq,4);
  CallDriver(Rh,Devices[Dev].Header);
 End;
 If (Rh.Status and STATUS_ERROR)<>0 Then Done:=0 Else Done:=Rh.Transferred;
 ReadHandler:=False;
 If Not SendIoAnswer(Done) Then Exit;
 If Done<>0 Then
  If Not Link.Send(Buffer^,Word(LongInt(Done)*Devices[Dev].Bps)) Then Exit;
 ReadHandler:=True;
End;

Function WriteHandler:Boolean;
Var Rq:TIoReq;Dev:Integer;Got:Word;Cmd:Byte;
Begin
 WriteHandler:=False;
 Move(Packet,Rq,SizeOf(Rq));
 If Packet[0]=WRITE_REQ Then Cmd:=8 Else Cmd:=9;
 If Not Link.Recv(Buffer^,0,Got) Then Exit;
 Dev:=Rq.Unit_;
 If Dev>=SlaveDevices Then Begin
  Rh.Status:=STATUS_ERROR or STATUS_DONE or ERR_UNK_UNIT;
  Rh.Transferred:=0;
 End
  Else
 If Got<>Word(LongInt(Rq.Requested)*Devices[Dev].Bps) Then Begin
  Rh.Status:=STATUS_ERROR or STATUS_DONE or ERR_WRITE_FAULT;
  Rh.Transferred:=0;
 End
  Else
 Begin
  SetupIo(Dev,Rq,Cmd);
  CallDriver(Rh,Devices[Dev].Header);
 End;
 WriteHandler:=SendIoAnswer(Rh.Transferred);
End;

Function ErrorHandler:Boolean;Begin
 ErrorHandler:=True;
End;

Function UnknownHandler:Boolean;Begin
 UnknownHandler:=False;
End;

Function OcrmHandler:Boolean;
Var Dev:Integer;An:TStatusAns;
Begin
 Dev:=Packet[1];
 If Dev>=SlaveDevices Then Rh.Status:=STATUS_ERROR or STATUS_DONE or ERR_UNK_UNIT
  Else
 Begin
  Rh.Len:=13;
  Rh.Unit_:=Devices[Dev].Unit_;
  If Packet[0]=DEV_OPEN_REQ Then Rh.Cmd:=DEVICE_OPEN Else Rh.Cmd:=DEVICE_CLOSE;
  CallDriver(Rh,Devices[Dev].Header);
 End;
 An.Status:=Rh.Status;
 OcrmHandler:=Link.Send(An,SizeOf(An));
End;

Function GenIoctlHandler:Boolean;
Var Rq:TIoctlReq;An:TStatusAns;Dev:Integer;Fn:Byte;Got:Word;
Begin
 GenIoctlHandler:=False;
 Move(Packet,Rq,SizeOf(Rq));
 Dev:=Rq.Unit_;
 Fn:=0;
 If Dev>=SlaveDevices Then Rh.Status:=STATUS_ERROR or STATUS_DONE or ERR_UNK_UNIT
  Else
 Begin
  Fn:=Rq.Func;
  If Fn=$46 Then If Not Link.Recv(MediaBuf,SizeOf(MediaBuf),Got) Then Exit;
  Rh.Len:=23;
  Rh.Unit_:=Devices[Dev].Unit_;
  Rh.Cmd:=19;
  Rh.Category:=Rq.Category;
  Rh.Func:=Fn;
  Rh.GenData:=@MediaBuf;
  CallDriver(Rh,Devices[Dev].Header);
 End;
 An.Status:=Rh.Status;
 If Not Link.Send(An,SizeOf(An)) Then Exit;
 If (Rh.Status and STATUS_ERROR)=0 Then
  If Fn=$66 Then Begin
   GenIoctlHandler:=Link.Send(MediaBuf,SizeOf(MediaBuf));
   Exit;
  End;
 GenIoctlHandler:=True;
End;

  { Taille et nom de volume d'un lecteur du serveur }
Function DriveInfoHandler:Boolean;
Var An:TDriveInfoAns;I:Integer;S:String;J:Integer;
Begin
 I:=Packet[1];
 FillChar(An,SizeOf(An),0);
 If I<SlaveDevices Then Begin
  S:=DriveSize(I);
  For J:=1 to Length(S) do An.Size[J-1]:=S[J];
  Move(Devices[I].VolLabel,An.VolLabel,12);
 End;
 DriveInfoHandler:=Link.Send(An,SizeOf(An));
End;

 { ------------------------------------------------------------------ imprimantes }

Function PrnWriteHandler:Boolean;
Var Rq:TLptReq;An:TLptAns;Got:Word;Id:Byte;
Begin
 PrnWriteHandler:=False;
 Move(Packet,Rq,SizeOf(Rq));
 Got:=Rq.Count;
 If Rq.Count>1 Then Begin
  If Not Link.Recv(Buffer^,0,Got) Then Exit;
 End
  Else
 Begin
  Buffer^[0]:=Rq.Data;
  Got:=Rq.Count;
 End;
 Id:=Rq.LptId;
 FillChar(Rh,SizeOf(Rh),0);
 If (Id>2) Or (LptDrivers[Id]=Nil) Then Begin
  Rh.Status:=STATUS_ERROR or STATUS_DONE or ERR_UNK_UNIT;
  Rh.Transferred:=0;
 End
  Else
 If Got<>Rq.Count Then Begin
  Rh.Status:=STATUS_ERROR or STATUS_DONE or ERR_WRITE_FAULT;
  Rh.Transferred:=0;
 End
  Else
 Begin
  Rh.Len:=30;
  Rh.Cmd:=8;
  Rh.IoData:=Buffer;
  Rh.IoCount:=Rq.Count;
  CallDriver(Rh,LptDrivers[Id]);
 End;
 An.Status:=Rh.Status;
 An.Transferred:=Rh.Transferred;
 PrnWriteHandler:=Link.Send(An,SizeOf(An));
End;

Function PrnCmdHandler:Boolean;
Var Rq:TLptCmd;An:TStatusAns;Id,Cmd:Byte;
Begin
 Move(Packet,Rq,SizeOf(Rq));
 Case Rq.PacketType of
  OUTPUT_STATUS_REQ:Cmd:=10;
  FLUSH_OUTPUT_REQ:Cmd:=11;
  AUX_DEV_OPEN_REQ:Cmd:=DEVICE_OPEN;
  Else Cmd:=DEVICE_CLOSE;
 End;
 Id:=Rq.LptId;
 If (Id>2) Or (LptDrivers[Id]=Nil) Then Rh.Status:=STATUS_ERROR or STATUS_DONE or ERR_UNK_UNIT
  Else
 Begin
  Rh.Len:=13;
  Rh.Cmd:=Cmd;
  If ((PeekW(SegOf(LptDrivers[Id]),OfsOf(LptDrivers[Id])+4) and ATT_OCRM)<>0) Or (Cmd=10) Or (Cmd=11) Then
   CallDriver(Rh,LptDrivers[Id])
  Else Rh.Status:=STATUS_DONE;
 End;
 An.Status:=Rh.Status;
 PrnCmdHandler:=Link.Send(An,SizeOf(An));
End;

  { Impression par l'INT 17h du BIOS (clients utilisant l'interception du BIOS) }
Function BiosHandler:Boolean;
Var Cmd,Port,St:Byte;
Begin
 Cmd:=Packet[0]-BIOS_PRINT_REQ;
 Port:=Packet[1];
 If (Port<NumLpt) And Printers[Port].Enabled Then St:=BiosPrinter(Cmd,Port,Packet[2])
  Else St:=$19;
 BiosHandler:=Link.Send(St,1);
End;

 { ------------------------------------------------------------------ ecoute des ports }

  { Remet un UART serie dans l'etat d'ecoute (9600 bauds) sans reecrire la sauvegarde }
Procedure SerReinit;Begin
 Link.Baud:=BAUD_9600;
 OutB(Link.Base+3,$03);
 OutB(Link.Base+1,0);
 OutB(Link.Base+4,0);
 Link.SetBaud(BAUD_9600);
End;

  { Initialise tous les ports; Save = True au premier appel (sauvegarde de l'etat d'origine) }
Procedure InitPorts(Save:Boolean);
Var I:Integer;
Begin
 For I:=0 to NumPorts-1 do Begin
  Link.Base:=Ports[I].Addr;
  Ports[I].State:=0;
  If Ports[I].Typ=SERIAL_PORT Then Begin
   If Save Then Begin
    Ports[I].Bad:=Not Link.WaitIdle;
    If Not Ports[I].Bad Then Begin
     Link.InitSerial;
     Move(Link.SaveSer,Ports[I].SaveSer,5);
    End;
   End
    Else
   If Not Ports[I].Bad Then SerReinit;
  End
   Else
  If Save Then Begin
   Link.ParSave;
   Move(Link.SavePar,Ports[I].SavePar,2);
  End;
 End;
 Link.Base:=0;
 ListenStart:=Link.Now;
End;

  { Remet les ports dans leur etat d'origine (sauf le port connecte si Keep) }
Procedure RestorePorts(Keep:Boolean);
Var I:Integer;
Begin
 For I:=0 to NumPorts-1 do
  If (Not Keep) Or (I<>CurPort) Then Begin
   Link.Base:=Ports[I].Addr;
   If Ports[I].Typ=SERIAL_PORT Then Begin
    If Not Ports[I].Bad Then Begin
     Move(Ports[I].SaveSer,Link.SaveSer,5);
     Link.ResetSerial;
    End;
   End
    Else
   Begin
    Move(Ports[I].SavePar,Link.SavePar,2);
    Link.ParRestore;
   End;
  End;
 Link.Base:=0;
End;

  { Un pas de la poignee de main serie du serveur: AA, 00, 55, FF, 5A, 11 }
Function SerListenStep(Var P:TPortInfo):Boolean;
Var B:Byte;
Begin
 SerListenStep:=False;
 Case P.State of
  0:If Link.GetNB(B) Then If B=$AA Then P.State:=1;
  1:If Link.SendNB(0) Then P.State:=2;
  2:If Link.GetNB(B) Then If B=$55 Then P.State:=3;
  3:If Link.SendNB($FF) Then P.State:=4;
  4:If Link.GetNB(B) Then If B=$5A Then P.State:=5;
  5:If Link.SendNB($11) Then Begin
     P.State:=0;
     Link.MaxBaud:=SettingsMaxBaud;
     Link.MaxBlock:=SettingsMaxBlock;
     Link.FirstSend:=1;
     Link.NeedEcho:=0;
     Link.SendEcho:=0;
     Link.RecvEcho:=0;
     Link.ErrNo:=0;
     Link.IsSerial:=1;
     SerListenStep:=True;
    End;
 End;
End;

  { Un pas de la synchronisation parallele du serveur }
Function ParListenStep(Var P:TPortInfo):Boolean;
Var V:Byte;
Begin
 ParListenStep:=False;
 Case P.State of
  0:Begin
     OutB(Link.Base,(Not WSYNC) and $FF);
     P.State:=1;
    End;
  1:If Link.ReadStat(V) Then If V=RSYNC Then Begin
     OutB(Link.Base,WSYNC);
     P.State:=2;
    End;
  2:If Link.ReadStat(V) Then Begin
     If V=(((Not RSYNC) and $FF) and $F8) Then Begin
      OutB(Link.Base,WNAK);
      P.State:=0;
      Link.ParSpeed:=1;
      Link.IsSerial:=0;
      ParListenStep:=True;
     End
      Else
     If V=(((Not RNAK) and $FF) and $F8) Then P.State:=0;
    End;
 End;
End;

  { Passe une fois sur tous les ports en ecoute: True des qu'un client se connecte }
Function Listen:Boolean;
Var I:Integer;Ok:Boolean;
Begin
 Listen:=False;
 For I:=0 to NumPorts-1 do
  If Not Ports[I].Bad Then Begin
   Link.Base:=Ports[I].Addr;
   If Ports[I].Typ=SERIAL_PORT Then Ok:=SerListenStep(Ports[I])
                               Else Ok:=ParListenStep(Ports[I]);
   If Ok Then Begin
    CurPort:=I;
    Link.SeqNum:=0;
    Link.LastOp:=OP_RECV;
    RestorePorts(True);
    Link.Base:=Ports[I].Addr;
    Listen:=True;
    Exit;
   End;
  End;
 Link.Base:=0;
  { sans client depuis 2 secondes: on reinitialise les ports }
 If Word(Link.Now-ListenStart)>=2*18 Then InitPorts(False);
End;

 { ------------------------------------------------------------------ transactions }

Const
 PacketKind:Array[0..PACKET_TYPES-1] of Byte=
  (0,0,1,1,1,2,2,0,0,0,3,3,0,0,0,0,0,0,0,0,0,3,1,1,1,3,3,3,0,0);

  { Recoit un paquet de requete et le traite. Une erreur de liaison
    deconnecte le client: l'ecoute reprend. }
Procedure Transaction;
Var Got:Word;Ty:Byte;Ok:Boolean;Kind:Integer;
Begin
 If Not Connected Then Begin
  If Listen Then Begin
   Connected:=True;
   UiPort;
  End;
  Exit;
 End;
 If Not Link.Recv(Packet,SizeOf(Packet),Got) Then Begin
  Connected:=False;
  Link.Lost;
  InitPorts(False);
  UiPort;
  Exit;
 End;
 FillChar(Rh,SizeOf(Rh),0);
 Ty:=Packet[0];
 CurDrive:=-1;
 CurPrinter:=-1;
 Ok:=False;
 If Ty<PACKET_TYPES Then Begin
  Kind:=PacketKind[Ty];
  If (Kind=SDP_READING) Or (Kind=SDP_WRITING) Then Begin
   CurDrive:=0;
   While (CurDrive<NumDrives) And (DrivePriority[CurDrive]<>Packet[1]) do Inc(CurDrive);
   If CurDrive>=NumDrives Then CurDrive:=-1;
  End
   Else
  If Kind=SDP_PRINTING Then CurPrinter:=Packet[1];
  UiStatus(Kind);
  Case Ty of
   0:Ok:=SrvInfoHandler;
   1:Ok:=InitHandler;
   2:Ok:=MediaCheckHandler;
   3:Ok:=BuildBpbHandler;
   4:Ok:=ReadHandler;
   5,6:Ok:=WriteHandler;
   7:Ok:=ErrorHandler;
   10,11,20,21:Ok:=PrnWriteHandler;
   14,16,17,18:Ok:=PrnCmdHandler;
   22,23,24:Ok:=OcrmHandler;
   25,26,27:Ok:=BiosHandler;
   28:Ok:=DriveInfoHandler;
   29:Ok:=GenIoctlHandler;
   Else Ok:=UnknownHandler;
  End;
 End;
 If Not Ok Then Begin
  Connected:=False;
  Link.Lost;
  InitPorts(False);
  UiPort;
 End;
 UiStatus(SDP_INACTIVE);
End;
{ ================================================================== END SERVER LOGIC }

 { ------------------------------------------------------------------ materiel du serveur }

Procedure GetSysVars(Var S,O:Word);
Var R:Registers;
Begin
 R.AH:=$52;
 MsDos(R);
 S:=R.ES;
 O:=R.BX;
End;

  { Premier peripherique a caracteres portant ce nom (8 caracteres) dans la chaine de DOS }
Function FindCharDevice(Const Name:String):Pointer;
Var S,O,NS,NO,N,I:Word;Ok:Boolean;
Begin
 FindCharDevice:=Nil;
 GetSysVars(S,O);
 NS:=S;
 NO:=O+$22;
 N:=0;
 While (NO<>$FFFF) And (N<200) do Begin
  Ok:=True;
  For I:=1 to 8 do If PeekB(NS,NO+10+I-1)<>Ord(Name[I]) Then Ok:=False;
  If Ok Then Begin
   FindCharDevice:=MakePtr(NS,NO);
   Exit;
  End;
  S:=PeekW(NS,NO+2);
  O:=PeekW(NS,NO);
  NS:=S;
  NO:=O;
  Inc(N);
 End;
End;

  { Lit la liste des DPB de DOS: un lecteur du serveur par DPB }
Procedure LoadDeviceInformation;
Var SvS,SvO,S,O,HS,HO:Word;Ver4:Boolean;Eq:Word;MaxNumber:Word;SR:SearchRec;
 DevOfs,NextOfs,MediaOfs:Word;N:Integer;
Begin
 LptDrivers[0]:=FindCharDevice('LPT1    ');
 LptDrivers[1]:=FindCharDevice('LPT2    ');
 LptDrivers[2]:=FindCharDevice('LPT3    ');
 Intr($11,Regs);
 Eq:=Regs.AX;
 If (Eq and 1)<>0 Then NumServerFloppies:=((Eq and $C0) shr 6)+1 Else NumServerFloppies:=0;
 Ver4:=Lo(DosVersion)>=4;
 If Ver4 Then Begin DevOfs:=$13;MediaOfs:=$17;NextOfs:=$19;End
         Else Begin DevOfs:=$12;MediaOfs:=$16;NextOfs:=$18;End;
 GetSysVars(SvS,SvO);
 S:=PeekW(SvS,SvO+2);
 O:=PeekW(SvS,SvO);
 SlaveDevices:=0;
 While (O<>$FFFF) And (SlaveDevices<MAX_SLAVE_DEVICES) do Begin
  N:=SlaveDevices;
  FillChar(Devices[N],SizeOf(Devices[N]),0);
  With Devices[N] do Begin
   Dpb:=MakePtr(S,O);
   Drive:=PeekB(S,O);
   Unit_:=PeekB(S,O+1);
   Bps:=PeekW(S,O+2);
   Spc:=PeekB(S,O+4)+1;
   NFats:=PeekB(S,O+8);
   MaxNumber:=PeekW(S,O+$0D);
   HO:=PeekW(S,O+DevOfs);
   HS:=PeekW(S,O+DevOfs+2);
   Header:=MakePtr(HS,HO);
   Attribute:=PeekW(HS,HO+4);
   MediaDesc:=PeekB(S,O+MediaOfs);
   NonRemovable:=False;
    { support fixe: on touche le lecteur pour que son DPB soit a jour }
   If Not IsIlDrive(N) Then Begin
    Regs.AX:=$4408;
    Regs.BL:=N+1;
    MsDos(Regs);
    If ((Regs.Flags and 1)=0) And (Regs.AX=1) Then Begin
     NonRemovable:=True;
     FindFirst(Chr(65+N)+':\*.*',VolumeID,SR);
    End;
   End;
   IsFloppy:=(N<2) And (NumServerFloppies>=1);
   If MediaDesc<>0 Then DataSize:=LongInt(MaxNumber-1)*Spc*Bps;
  End;
  If Devices[N].NonRemovable Then ReadVolumeLabel(N);
  Inc(SlaveDevices);
  HS:=PeekW(S,O+NextOfs+2);
  O:=PeekW(S,O+NextOfs);
  S:=HS;
 End;
End;

  { Indique si un lecteur doit etre propose par defaut: ni lecteur redirige par
    INTERLNK, ni lettre secondaire d'un meme lecteur physique }
Function DefaultDriveOk(Drv:Integer):Boolean;
Begin
 DefaultDriveOk:=True;
 If IsIlDrive(Drv) Then Begin
  DefaultDriveOk:=False;
  Exit;
 End;
 If SlaveDosVersion>=$0314 Then Begin
  Regs.AX:=$440E;
  Regs.BL:=Drv+1;
  MsDos(Regs);
  If (Regs.Flags and 1)=0 Then
   If Regs.AL<>0 Then DefaultDriveOk:=(Drv+1)=Regs.AL;
 End
  Else
 If ((Drv=0) And (NumServerFloppies<1)) Or ((Drv=1) And (NumServerFloppies<2)) Then
  Case Devices[Drv].MediaDesc of
   $F8,$F0,$F9,$FC,$FD,$FE,$FF:;
   Else DefaultDriveOk:=False;
  End;
End;

  { Tampon de 64 Ko pour les transferts de secteurs }
Function AllocBuffer:PBuf;
Begin
 Regs.AH:=$48;
 Regs.BX:=4096;
 MsDos(Regs);
 If (Regs.Flags and 1)<>0 Then AllocBuffer:=Nil
                          Else AllocBuffer:=MakePtr(Regs.AX,0);
End;

Procedure MakeServerId;
Var I:Integer;L,H:Word;
Begin
 L:=0;
 H:=0;
 For I:=0 to 63 do Begin
  L:=L xor PeekW($40,I*4);
  H:=H xor PeekW($40,I*4+2);
 End;
 L:=L xor BiosTicks;
 OutB($43,0);
 H:=H xor (InB($40) or (Word(InB($40)) shl 8));
 If (L=0) And (H=0) Then L:=1;
 ServerId:=(LongInt(H) shl 16) or L;
End;

 { ------------------------------------------------------------------ options }

Procedure Fatal(Const S:String);Begin
 WriteLn(S);
 Halt(1);
End;

Function CharAtP(Const S:String;P:Integer):Char;Begin
 If (P>=1) And (P<=Length(S)) Then CharAtP:=S[P] Else CharAtP:=#0;
End;

Function HexVal(Const S:String;Var P:Integer):Word;
Var V:Word;C:Char;Go:Boolean;
Begin
 V:=0;
 Go:=True;
 While (P<=Length(S)) And Go do Begin
  C:=UpCase(S[P]);
  If C in ['0'..'9'] Then V:=(V shl 4) or (Ord(C)-48)
   Else
  If C in ['A'..'F'] Then V:=(V shl 4) or (Ord(C)-55)
   Else
  Go:=False;
  If Go Then Inc(P);
 End;
 HexVal:=V;
End;

Procedure AddPort(Typ:Byte;Addr:Word;Bios:Byte);
Var I:Integer;
Begin
 If (Addr<$200) Or (Addr>=$8000) Or ((Typ=SERIAL_PORT) And ((Addr and 7)<>0)) Or
    ((Typ=PARALLEL_PORT) And ((Addr and 3)<>0)) Then Begin
  If (Typ=SERIAL_PORT) Or (Addr>3) Then Begin
   If Typ=SERIAL_PORT Then Write(Msg(M_BADSER)) Else Write(Msg(M_BADPAR));
   WriteLn(Addr);
  End;
  Exit;
 End;
 For I:=0 to NumPorts-1 do If Ports[I].Addr=Addr Then Exit;
 If NumPorts<MAX_PORTS Then Begin
  FillChar(Ports[NumPorts],SizeOf(Ports[NumPorts]),0);
  Ports[NumPorts].Typ:=Typ;
  Ports[NumPorts].Bios:=Bios;
  Ports[NumPorts].Addr:=Addr;
  Inc(NumPorts);
 End;
End;

Procedure AddBiosSerial(N:Byte);
Var A:Word;
Begin
 A:=PeekW($40,(N-1)*2);
 If A<>0 Then Begin
  If A=$3F8 Then N:=1 Else If A=$2F8 Then N:=2;
  AddPort(SERIAL_PORT,A,N);
 End;
End;

Procedure AddBiosParallel(N:Byte);
Var A:Word;
Begin
 A:=PeekW($40,8+(N-1)*2);
 If A<>0 Then AddPort(PARALLEL_PORT,A,N);
End;

Procedure AddAllBios;
Var I:Integer;Eq:Word;
Begin
 Intr($11,Regs);
 Eq:=Regs.AX;
 For I:=1 to (Eq shr 9) and 7 do If I<=4 Then AddBiosSerial(I);
 For I:=1 to NumLpt do AddBiosParallel(I);
End;

Procedure RemoveServerDrive(D:Byte);
Var I:Integer;
Begin
 If IncludedDrives[D]<>0 Then Begin
  I:=0;
  While (I<NumDrives) And (DrivePriority[I]<>D) do Inc(I);
  If I<NumDrives Then Begin
   While I<NumDrives-1 do Begin
    DrivePriority[I]:=DrivePriority[I+1];
    Inc(I);
   End;
   Dec(NumDrives);
  End;
 End;
End;

  { Analyse de la ligne de commande (et de la variable INTERSVR). Les lettres
    en dehors des options designent les lecteurs a partager, ou a exclure
    apres /X= }
Procedure ProcessArgs(S:String);
Var P:Integer;C:Char;Excluding:Boolean;D:Byte;V:LongInt;Known:Boolean;
 Function Match(Const K:String):Boolean;Begin
  Match:=False;
  If Copy(S,P,Length(K))<>K Then Exit;
  If CharAtP(S,P+Length(K)) in ['A'..'Z'] Then Exit;
  Match:=True;
 End;
 Procedure SkipPortArg(Serial:Boolean);
 Var A:Word;I,K:Integer;
 Begin
  If CharAtP(S,P)=':' Then Inc(P);
  If CharAtP(S,P)='*' Then Inc(P);
  I:=P;
  A:=HexVal(S,P);
  If (A>=1) And (A<=4) And (Serial Or (A<=3)) Then Begin
   If Serial Then AddBiosSerial(A) Else AddBiosParallel(A);
  End
   Else
  If CharAtP(S,I)<=' ' Then Begin
   If Serial Then Begin
    Intr($11,Regs);
    For K:=1 to (Regs.AX shr 9) and 7 do If K<=4 Then AddBiosSerial(K);
   End
    Else
   For K:=1 to NumLpt do AddBiosParallel(K);
  End
   Else
  If Serial Then AddPort(SERIAL_PORT,A,0) Else AddPort(PARALLEL_PORT,A,0);
 End;
Begin
 S:=StrUpper(S);
 If Pos('?',S)>0 Then Begin
  WriteLn(Msg(M_BANNER));
  WriteLn;
  For P:=0 to 11 do WriteLn(Msg(M_USAGE+P));
  Halt(0);
 End;
 Excluding:=False;
 P:=1;
 While P<=Length(S) do Begin
  C:=S[P];
  If C<>'/' Then Begin
   If C in ['A'..'Z'] Then Begin
    D:=Ord(C)-65;
    If Excluding Then Begin
     RemoveServerDrive(D);
     ExcludedDrives[D]:=1;
     IncludedDrives[D]:=0;
    End
     Else
    Begin
     If IncludedDrives[D]=0 Then Begin
      DrivePriority[NumDrives]:=D;
      Inc(NumDrives);
      Inc(NumIncludes);
     End;
     ExcludedDrives[D]:=0;
     IncludedDrives[D]:=1;
    End;
   End
    Else
   If (C>' ') And (C<>':') And ((C<>'=') Or (Not Excluding)) Then Fatal(Msg(M_INVSERVER)+C);
   Inc(P);
  End
   Else
  Begin
   Inc(P);
   Excluding:=False;
   Known:=True;
   If Match('X') Then Begin
    Inc(P);
    Excluding:=True;
   End
    Else
   If Match('COM') Then Begin Inc(P,3);SkipPortArg(True);End
    Else
   If Match('LPT') Then Begin Inc(P,3);SkipPortArg(False);End
    Else
   If Match('BAUD') Then Begin
    Inc(P,4);
    If CharAtP(S,P)=':' Then Inc(P);
    V:=0;
    While CharAtP(S,P) in ['0'..'9'] do Begin
     If V<1000000 Then V:=V*10+Ord(S[P])-48;
     Inc(P);
    End;
    If V=115200 Then SettingsMaxBaud:=BAUD_115200
     Else
    If V=57600 Then SettingsMaxBaud:=6
     Else
    If V=38400 Then SettingsMaxBaud:=5
     Else
    If V=19200 Then SettingsMaxBaud:=4
     Else
    If V=9600 Then SettingsMaxBaud:=BAUD_9600
     Else
    Fatal(Msg(M_INVBAUD)+DecStr(V));
   End
    Else
   If Match('MAXBLOCK') Then Begin
    Inc(P,8);
    If CharAtP(S,P)=':' Then Inc(P);
    V:=0;
    While CharAtP(S,P) in ['0'..'9'] do Begin
     If V<1000000 Then V:=V*10+Ord(S[P])-48;
     Inc(P);
    End;
    If (V<1) Or (V>$8000) Then Fatal(Msg(M_INVBLOCK)+DecStr(V));
    SettingsMaxBlock:=V;
   End
    Else
   If Match('RCOPY') Then Fatal(Msg(M_RCOPY))
    Else
   If Match('B') Then Begin Inc(P);ColorOn:=False;End
    Else
   If Match('V') Then Begin Inc(P);Link.ForceVar:=1;End
    Else
    Known:=False;
   If Not Known Then Begin
    Write(Msg(M_INVOPTION));
    While CharAtP(S,P) in ['A'..'Z'] do Begin
     Write(S[P]);
     Inc(P);
    End;
    WriteLn;
    Halt(1);
   End;
  End;
 End;
End;

Procedure Cleanup;Begin
 RestorePorts(False);
 ResetDisk;
 UiDone;
End;

Var
 I,Good:Integer;
 Eq:Word;
 Args:String;
 Dummy:TMap;
 Desired:TMap;
BEGIN
 Language:=_French;
 TmpLanguage:=GetEnv('LANGUAGE');
 If TmpLanguage<>'' Then Begin
  If TmpLanguage[1]='"' Then TmpLanguage:=Copy(TmpLanguage,2,255);
  If StrUpper(Copy(TmpLanguage,1,2))='EN' Then Language:=_English Else
  If StrUpper(Copy(TmpLanguage,1,2))='GR' Then Language:=_Germany;
 End;
 If (Lo(DosVersion)<3) Or ((Lo(DosVersion)=3) And (Hi(DosVersion)<10)) Then Fatal(Msg(M_NEEDDOS));
 CheckBreak:=False;
 ColorOn:=True;
 InitCrcTab;
 Link.Init;
 SettingsMaxBaud:=BAUD_115200;
 SettingsMaxBlock:=MAX_SERIAL_BLOCK;
 NumPorts:=0;
 CurPort:=-1;
 Connected:=False;
 SlaveDosVersion:=(Word(Lo(DosVersion)) shl 8) or Hi(DosVersion);
 Intr($11,Regs);
 Eq:=Regs.AX;
 NumLpt:=(Eq shr 14) and 3;
 For I:=0 to NumLpt-1 do Begin
  Printers[I].Addr:=PeekW($40,8+I*2);
  Printers[I].Enabled:=True;
 End;
 FillChar(ActualPrnMap,3,UNASSIGNED);
 Args:=GetEnv('INTERSVR');
 For I:=1 to ParamCount do Args:=Args+' '+ParamStr(I);
 ProcessArgs(Args);
 If NumPorts=0 Then Begin
  AddAllBios;
  If NumPorts=0 Then Fatal(Msg(M_NOPORTS));
 End;
 Buffer:=AllocBuffer;
 If Buffer=Nil Then Fatal(Msg(M_NOBUFFER));
 LoadDeviceInformation;
 ResetDisk;
 SetupBlockDevices;
 For I:=0 to 25 do
  If (I>=SlaveDevices) And ((IncludedDrives[I]<>0) Or (ExcludedDrives[I]<>0)) Then
   Fatal(Msg(M_INVSERVER)+Chr(65+I));
 If NumIncludes=0 Then
  For I:=0 to SlaveDevices-1 do
   If (ExcludedDrives[I]=0) And DefaultDriveOk(I) Then Begin
    DrivePriority[NumDrives]:=I;
    Inc(NumDrives);
   End;
 If (NumDrives=0) And (NumLpt=0) Then Fatal(Msg(M_NODRIVES));
 SetIntVec($24,@CritErr);
 MakeServerId;
 InitPorts(True);
 Good:=0;
 For I:=0 to NumPorts-1 do
  If Ports[I].Bad Then WriteLn(Msg(M_PORTERR),Ports[I].Addr)
                  Else Inc(Good);
 If Good=0 Then Fatal(Msg(M_NOPORTS));
 UiInit;
 FillChar(Desired,SizeOf(Desired),DONT_CARE);
 GenerateDriveMappings(Dummy,MAX_DEVICES,Desired);
 UiMap(Dummy,False);
 UiStatus(SDP_INACTIVE);
 Repeat
  Transaction;
 Until Aborted;
 Cleanup;
END.
