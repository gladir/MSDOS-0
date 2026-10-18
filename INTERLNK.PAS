{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7)
  @description: Clone de la commande INTERLNK de MS-DOS 6.0
  @license: MIT
}

Program INTERLNK;

{ Clone de INTERLNK.EXE (Microsoft InterLnk), base sur le code source de
  MS-DOS 6.0 (c6ers\interlnk). INTERLNK relie deux ordinateurs par un cable
  serie (3 fils) ou parallele (cable de type LapLink/FastLynx): l'ordinateur
  "client" (celui qui execute INTERLNK) voit les lecteurs de disque et les
  imprimantes de l'ordinateur "serveur" (qui execute INTERSVR) comme s'il
  s'agissait de lecteurs et d'imprimantes locaux.

  Ce programme contient:
   - le protocole de liaison de l'original (poignee de main serie AA/00/55/FF/
     5A/11 et synchronisation parallele WSYNC/RSYNC, trames avec numero de
     sequence, CRC-CCITT, bloc maximum de 8192 octets, negociation de la
     vitesse de 9600 a 115200 bauds, mode "echoplex", changement de vitesse
     "turbo" du cable parallele, octets d'inactivite);
   - les paquets du pilote: information serveur, initialisation, controle du
     support, construction du BPB, lecture, ecriture, ouverture/fermeture,
     IOCTL generique (numero de serie et nom de volume) et imprimante;
   - le pilote de peripherique residant (blocs et LPT1 a LPT3) lie a la chaine
     des peripheriques de DOS, ainsi que la creation des DPB et des CDS des
     lecteurs redirigeables;
   - l'interface multiplex INT 2Fh, fonction 56h (detection du pilote) et le
     blocage des acces absolus INT 25h/26h aux lecteurs redirigeables;
   - la commande INTERLNK: affichage de l'etat de la liaison et de la table de
     correspondance des lecteurs, ainsi que la syntaxe
     INTERLNK [client[:]=[serveur][:]] pour changer les correspondances.

  Utilisation: un programme Pascal ne pouvant pas etre un pilote charge par
  DEVICE= dans CONFIG.SYS, le premier lancement de INTERLNK (ligne de commande
  ou AUTOEXEC.BAT) installe le pilote (options /DRIVES:n /NOPRINTER /COM /LPT
  /NOSCAN /AUTO /LOW /BAUD:vitesse /V identiques a celles de DEVICE=INTERLNK.EXE)
  et les lancements suivants se comportent comme la commande INTERLNK.EXE.
  La directive LASTDRIVE de CONFIG.SYS doit reserver assez de lettres pour les
  lecteurs redirigeables (par exemple LASTDRIVE=Z).

  Tout le code est contenu dans ce fichier: aucun fichier d'inclusion, aucune
  unite externe autre que DOS.
  Differences avec l'original: l'interception INT 17h (impression directe par
  le BIOS) n'est pas reprise, l'option /LOW est acceptee mais ignoree (le
  pilote ne peut pas etre deplace en memoire haute) et la prise en charge de
  Windows 386 n'est pas reprise.
}

{$M 4096,0,0}
{$A-}
{$R-}
{$S-}

Uses Dos;

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
 MINIMUM_TICKS=5; RECV_PACK_TICKS=401; SYNC_TICKS=36; CONNECT_TICKS=5;
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
 BusyFlag:Byte;

  { ------------------------------------------------------------------ acces materiel }
  { Ces fonctions sont les seuls acces directs au materiel dans le moteur de
    liaison: ports d'entree-sortie et compteur de tics du BIOS (0040:006C). }
{ -- DOS-LOW-BEGIN -- }
Function InB(P:Word):Byte;Begin InB:=Port[P];End;
Procedure OutB(P:Word;V:Byte);Begin Port[P]:=V;End;
Function BiosTicks:Word;Begin BiosTicks:=MemW[$0040:$006C];End;
{ -- DOS-LOW-END -- }

{ ================================================================== BEGIN ENGINE }
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
  Function SerConnect:Boolean;
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
  Procedure IdleSerial;
   { parallele }
  Function ReadStat(Var V:Byte):Boolean;
  Function WaitS7(Want:Boolean;Fast:Boolean;Var V:Byte):Boolean;
  Function WaitVal(Want:Byte):Boolean;
  Procedure ParSave;
  Procedure ParRestore;
  Function ParConnect:Boolean;
  Function ParTx(B:Byte;Ticks:Word;Var Ack:Byte):Boolean;
  Function ParRxNoAck(Ticks:Word;Var B:Byte):Boolean;
  Function ParRx(Ticks:Word;Var B:Byte):Boolean;
  Procedure ParWaitSendAck(Last:Byte);
  Function ParSendData(Var Buf;Len:Word):Boolean;
  Function ParSend(Var Buf;Len:Word):Boolean;
  Function ParRecvData(Var Buf;Len:Word):Boolean;
  Function ParRecv(Var Buf;Max:Word;Var Total:Word):Boolean;
  Procedure IdleParallel;
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

  { Poignee de main du client: AA, 00, 55, FF, 5A, 11 }
Function TLink.SerConnect:Boolean;
Var State:Byte;T0:Word;B:Byte;
Begin
 SerConnect:=False;
 State:=0;
 T0:=Now;
 Repeat
  Case State of
   0:If SendNB($AA) Then Begin T0:=Now;State:=1;End;
   1:If GetNB(B) Then If B=0 Then Begin T0:=Now;State:=2;End;
   2:If SendNB($55) Then State:=3;
   3:If GetNB(B) Then If B=$FF Then Begin T0:=Now;State:=4;End;
   4:If SendNB($5A) Then State:=5;
   5:If GetNB(B) Then If B=$11 Then Begin
      MaxBaud:=ClientMaxBaud;
      LastOp:=OP_SEND;
      SeqNum:=0;
      NeedEcho:=0;
      SendEcho:=0;
      RecvEcho:=0;
      FirstSend:=1;
      SerConnect:=True;
      Exit;
     End;
  End;
 Until Word(Now-T0)>=CONNECT_TICKS;
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

  { Octet d'inactivite: maintient la liaison ouverte entre deux requetes }
Procedure TLink.IdleSerial;
Var B,E:Byte;
Begin
 LastOp:=OP_SEND;
 B:=((SeqNum xor 1) or IDLE_BITS) and $FF;
 SendNB(B);
 E:=0;
 If GetNB(E) And (E=B) Then IdleWait:=0
  Else
 Begin
  Inc(IdleWait);
  If IdleWait>2*MINIMUM_TICKS Then Lost;
 End;
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

  { Synchronisation du client: WSYNC/RSYNC en 5 tics au maximum }
Function TLink.ParConnect:Boolean;
Var Ok:Boolean;
Begin
 OutB(Base,(Not WNAK) and $FF);
 SetAlarm(CONNECT_TICKS);
 Ok:=WaitVal(((Not RSYNC) and $FF) and $F8);
 If Ok Then Begin
  OutB(Base,WSYNC);
  Ok:=WaitVal(RSYNC);
 End;
 If Ok Then Begin
  OutB(Base,(Not WSYNC) and $FF);
  Ok:=WaitVal(RNAK);
 End;
 If Ok Then Begin
  SeqNum:=0;
  ParSpeed:=1;
 End
  Else
 OutB(Base,WNAK);
 LastOp:=OP_SEND;
 ParConnect:=Ok;
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
  If Not ParRxNoAck(RECV_PACK_TICKS,B) Then Fatal:=True
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

  { Quartet d'inactivite: maintient la liaison parallele ouverte }
Procedure TLink.IdleParallel;
Var V:Byte;
Begin
 LastOp:=OP_SEND;
 OutB(Base,IdleAck);
 V:=InB(Base+1);
 If (((V xor $80) shr 3) and $FF)=IdleAck Then Begin
  IdleAck:=(Not IdleAck) and $0F;
  IdleWait:=0;
 End
  Else
 Begin
  Inc(IdleWait);
  If IdleWait>2*MINIMUM_TICKS Then Lost;
 End;
End;

Function TLink.Send(Var Buf;Len:Word):Boolean;Begin
 If IsSerial<>0 Then Send:=SerSend(Buf,Len) Else Send:=ParSend(Buf,Len);
End;

Function TLink.Recv(Var Buf;Max:Word;Var Total:Word):Boolean;Begin
 If IsSerial<>0 Then Recv:=SerRecv(Buf,Max,Total) Else Recv:=ParRecv(Buf,Max,Total);
End;
{ ================================================================== END ENGINE }

{ ================================================================== BEGIN HANDLERS }
Type
 TPortDef=Record
  Addr:Word;
  Bios:Byte;
 End;
  { Etat complet du pilote. Il se trouve dans le segment de donnees du
    programme, qui reste residant: la commande INTERLNK lancee une seconde
    fois y accede directement. Le premier champ doit rester Link (le premier
    mot de Link est l'adresse du port actif, lue par le gestionnaire INT 2Fh). }
 TDrv=Record
  Link:TLink;
  NumSer,NumPar,NumPorts:Byte;
  SerPorts,ParPorts:Array[0..3] of TPortDef;
  PortIndex:Byte;
  NumLpt,NumCom:Byte;
  Units,FirstUnit,DefaultUnits,SlaveUnits:Byte;
  PrinterLoaded:Byte;
  Initialized:Byte;
  DosVersion,SlaveDosVersion:Word;
  ServerMajor,ServerMinor,Multitasker:Byte;
  ClientId,LastServerId:LongInt;
  MaxSecSize:Word;
  PrnMap:Array[0..2] of Byte;
  DriveMap,DefaultMap:Array[0..MAX_DEVICES-1] of Byte;
  Invalid:Array[0..MAX_DEVICES-1] of Byte;
  DdAttr:Array[0..MAX_DEVICES-1] of Word;
  Bpb:Array[0..MAX_DEVICES-1] of TBpb;
  VolSer:Array[0..15] of Byte;
  Packet:Array[0..MAX_PACKET+8] of Byte;
  MappedUnit,UnmappedUnit:Word;
  IdleSem:Byte;
  DisplayScan:Boolean;
  LptBuf:Array[0..MAX_LPT_BUFF-1] of Byte;
  LptCount:Word;
  LptBuffering:Byte;
 End;
 PDrv=^TDrv;
 PWord=^Word;
 PMediaAns=^TMediaAns;
 PBpbAns=^TBpbAns;
 PIoAns=^TIoAns;
 PServerInfoAns=^TServerInfoAns;
 PInitAns=^TInitAns;
 PLptAns=^TLptAns;

Var
 Drv:TDrv;
 D:PDrv;
 RhPtr:Pointer;
 DevId:Byte;

Procedure ShowDot;Begin
 If D^.DisplayScan Then Write('.');
End;

  { Recherche le serveur sur les ports parallele puis serie }
Function ConnectPorts:Boolean;
Var I:Integer;
Begin
 ConnectPorts:=True;
 With D^ do Begin
  IdleSem:=0;
  If Link.Base<>0 Then Exit;
  For I:=0 to NumPar-1 do Begin
   Link.Base:=ParPorts[I].Addr;
   Link.ParSave;
   ShowDot;
   If Link.ParConnect Then Begin
    Link.IsSerial:=0;
    PortIndex:=I;
    IdleSem:=MINIMUM_TICKS+1;
    Exit;
   End;
   Link.ParRestore;
  End;
  For I:=0 to NumSer-1 do Begin
   Link.Base:=SerPorts[I].Addr;
   Link.InitSerial;
   ShowDot;
   If Link.SerConnect Then Begin
    Link.IsSerial:=1;
    PortIndex:=I;
    IdleSem:=MINIMUM_TICKS+1;
    Exit;
   End;
   Link.ResetSerial;
  End;
  Link.Base:=0;
  ConnectPorts:=False;
 End;
End;

Procedure ResetPrinters;
Var I:Integer;
Begin
 With D^ do
  For I:=0 to 2 do
   If (PrinterLoaded=0) Or (I<NumLpt) Then PrnMap[I]:=UNASSIGNED
                                      Else PrnMap[I]:=DONT_CARE;
End;

  { Echange d'information avec le serveur puis envoi du paquet d'initialisation
    (tailles de secteur, correspondance des lecteurs et des imprimantes) }
Function GetRemoteInfo:Boolean;
Var Z:Word;Got:Word;Req:TServerInfoReq;Ir:TInitReq;A:PServerInfoAns;Ia:PInitAns;I:Integer;
Begin
 GetRemoteInfo:=False;
 With D^ do Begin
  Z:=0;
  If Not Link.Send(Z,2) Then Exit;
  FillChar(Req,SizeOf(Req),0);
  Req.Version:=(VerMajor shl 8) or VerMinor;
  Req.DeviceDriver:=1;
  Req.Crc:=1;
  Req.MaxSerBlock:=MAX_SERIAL_BLOCK;
  Req.ClientId:=ClientId;
  Req.LastServerId:=LastServerId;
  If Not Link.Send(Req,SizeOf(Req)) Then Exit;
  If Not Link.Recv(Packet,MAX_PACKET,Got) Then Exit;
  A:=@Packet;
  Link.MaxBlock:=A^.MaxSerBlock;
  If A^.LastClientId<>ClientId Then Begin
   Initialized:=0;
   Move(DefaultMap,DriveMap,MAX_DEVICES);
   LastServerId:=A^.ServerId;
  End;
  If A^.DeviceServer=0 Then Exit;
  If Initialized<>0 Then Begin
   GetRemoteInfo:=True;
   Exit;
  End;
  ResetPrinters;
  FillChar(Ir,SizeOf(Ir),0);
  Ir.PacketType:=INIT_PACKET_REQ;
  Ir.MajorVersion:=VerMajor;
  Ir.MinorVersion:=VerMinor;
  Ir.DosVersion:=DosVersion;
  Ir.MaxDevices:=DefaultUnits;
  Ir.FirstUnit:=FirstUnit;
  Move(PrnMap,Ir.PrnMap,3);
  Move(DriveMap,Ir.Mapping,MAX_DEVICES);
  If Not Link.Send(Ir,SizeOf(Ir)) Then Exit;
  If Not Link.Recv(Packet,MAX_PACKET,Got) Then Exit;
  Ia:=@Packet;
  SlaveDosVersion:=Ia^.DosVersion;
  ServerMajor:=Ia^.MajorVersion;
  ServerMinor:=Ia^.MinorVersion;
  Multitasker:=Ia^.Multitasker;
  Move(Ia^.PrnMap,PrnMap,3);
  Move(Ia^.Mapping,DriveMap,MAX_DEVICES);
  SlaveUnits:=Ia^.Devices;
  If SlaveUnits>MAX_DEVICES Then SlaveUnits:=MAX_DEVICES;
  For I:=0 to SlaveUnits-1 do DdAttr[I]:=Ia^.Attributes[I];
  Initialized:=$FF;
  FillChar(Invalid,MAX_DEVICES,$FF);
  GetRemoteInfo:=True;
 End;
End;

  { ------------------------------------------------------------------ requetes }

Function NotReady(Var R:TReq):Word;Begin
 If (R.Cmd=4) Or (R.Cmd=8) Or (R.Cmd=9) Then R.Transferred:=0;
 NotReady:=STATUS_ERROR or ERR_NOT_READY;
End;

  { Traduit le numero de lecteur du client en numero de lecteur du serveur }
Function MapUnit(U:Byte;Var Err:Word):Boolean;
Var M:Byte;
Begin
 MapUnit:=False;
 With D^ do Begin
  If U>=Units Then Begin Err:=STATUS_ERROR or ERR_UNK_UNIT;Exit;End;
  M:=DriveMap[U] and $7F;
  If M>=SlaveUnits Then Begin Err:=STATUS_ERROR or ERR_UNK_UNIT;Exit;End;
  MappedUnit:=M;
  UnmappedUnit:=U;
 End;
 MapUnit:=True;
End;

  { Informe le serveur d'un support inutilisable (paquet sans reponse) }
Procedure ErrorPacket(Code:Byte);
Var Q:TErrReq;
Begin
 With D^ do Begin
  Q.PacketType:=ERROR_REQ;
  Q.BlockDvr:=$FF;
  Q.Unit_:=Lo(UnmappedUnit);
  Q.Code:=Code;
  Q.Data:=Lo(MappedUnit);
  Link.Send(Q,SizeOf(Q));
 End;
End;

Function CheckUnit(Var R:TReq;Var Err:Word):Boolean;Begin
 CheckUnit:=False;
 If Not MapUnit(R.Unit_,Err) Then Exit;
 With D^ do
  If (DdAttr[MappedUnit] and ATT_CHARACTER)<>0 Then Begin
   ErrorPacket(0);
   Err:=STATUS_ERROR or ERR_UNK_MEDIA;
   Exit;
  End;
 CheckUnit:=True;
End;

Function DoMediaCheck(Var R:TReq):Word;
Var Err,Got:Word;Q:TUnitReq;A:PMediaAns;Ch:Byte;
Begin
 With D^ do Begin
  If Not CheckUnit(R,Err) Then Begin DoMediaCheck:=Err;Exit;End;
  Q.PacketType:=MEDIA_CHECK_REQ;
  Q.Unit_:=Lo(MappedUnit);
  Q.MediaId:=R.Media;
  If Not Link.Send(Q,SizeOf(Q)) Then Begin DoMediaCheck:=STATUS_ERROR or ERR_NOT_READY;Exit;End;
  If Not Link.Recv(Packet,MAX_PACKET,Got) Then Begin DoMediaCheck:=STATUS_ERROR or ERR_NOT_READY;Exit;End;
  A:=@Packet;
  Move(A^.Volume,VolSer,MAX_VOLUME+4);
  Ch:=A^.Changed;
  If Invalid[UnmappedUnit]<>0 Then Ch:=$FF;
  R.Changed:=Ch;
  If Ch=$FF Then R.MediaLabel:=@VolSer;
  DoMediaCheck:=A^.Status;
 End;
End;

Function DoBuildBpb(Var R:TReq):Word;
Var Err,Got:Word;Q:TUnitReq;A:PBpbAns;
Begin
 With D^ do Begin
  If Not CheckUnit(R,Err) Then Begin DoBuildBpb:=Err;Exit;End;
  Q.PacketType:=BUILD_BPB_REQ;
  Q.Unit_:=Lo(MappedUnit);
  Q.MediaId:=R.Media;
  If Not Link.Send(Q,SizeOf(Q)) Then Begin DoBuildBpb:=STATUS_ERROR or ERR_NOT_READY;Exit;End;
  If Not Link.Recv(Packet,MAX_PACKET,Got) Then Begin DoBuildBpb:=STATUS_ERROR or ERR_NOT_READY;Exit;End;
  A:=@Packet;
  R.BpbPtr:=@Bpb[UnmappedUnit];
  DoBuildBpb:=A^.Status;
  If (A^.Status and STATUS_ERROR)<>0 Then Exit;
  Bpb[UnmappedUnit]:=A^.Bpb;
  Invalid[UnmappedUnit]:=0;
   { support inutilisable: secteur trop grand, ou adressage 32 bits sans DOS 3.31 }
  If (A^.Bpb.BytesPerSector>MaxSecSize) Or
     ((A^.Bpb.TotalSectors=0) And ((DosVersion<DOS331) Or (SlaveDosVersion<DOS331))) Then Begin
   DdAttr[MappedUnit]:=DdAttr[MappedUnit] or ATT_CHARACTER;
   DoBuildBpb:=STATUS_ERROR or ERR_UNK_MEDIA;
  End;
 End;
End;

  { Convertit le numero de secteur de depart selon les versions de DOS }
Procedure ConvertStart(Var R:TReq;Var Q:TIoReq);
Var Lo_,Hi_,St:Word;
Begin
 With D^ do Begin
  If DosVersion>DOS331 Then Begin
   Lo_:=Word(R.IoHuge and $FFFF);
   Hi_:=Word((R.IoHuge shr 16) and $FFFF);
   St:=Lo_;
  End
   Else
  If DosVersion=DOS331 Then Begin
   St:=R.IoStart;
   Lo_:=St;
   Hi_:=R.IoStartHigh;
  End
   Else
  Begin
   St:=R.IoStart;
   Lo_:=St;
   Hi_:=0;
  End;
  If SlaveDosVersion>DOS331 Then
   If (DdAttr[MappedUnit] and ATT_HUGE)<>0 Then St:=$FFFF;
  Q.Start:=St;
  Q.HugeStart:=(LongInt(Hi_) shl 16) or Lo_;
 End;
End;

  { Nombre d'octets pour Sectors secteurs (0 = 65536); False si invalide }
Function DataLen(Sectors:Word;Var Bytes:Word):Boolean;
Var N:LongInt;
Begin
 With D^ do N:=LongInt(Sectors)*Bpb[UnmappedUnit].BytesPerSector;
 Bytes:=Word(N and $FFFF);
 DataLen:=(N>0) And (N<=65536);
End;

Procedure CopyLabel(Var A:TIoAns);Begin
 Move(A.Volume,D^.VolSer,MAX_VOLUME+4);
End;

Function DoRead(Var R:TReq):Word;
Var Err,Got,Want,Cnt,Bytes:Word;Q:TIoReq;A:PIoAns;
 Function Fail(St:Word):Word;Begin
  R.Transferred:=0;
  Fail:=St;
 End;
Begin
 With D^ do Begin
  Want:=R.IoCount;
  If Not CheckUnit(R,Err) Then Begin DoRead:=Fail(Err);Exit;End;
  If Want=0 Then Begin DoRead:=Fail(STATUS_ERROR or ERR_READ_FAULT);Exit;End;
  Q.PacketType:=READ_REQ;
  Q.Unit_:=Lo(MappedUnit);
  Q.MediaId:=R.Media;
  Q.Requested:=Want;
  ConvertStart(R,Q);
  If Not Link.Send(Q,SizeOf(Q)) Then Begin DoRead:=Fail(STATUS_ERROR or ERR_NOT_READY);Exit;End;
  If Not Link.Recv(Packet,MAX_PACKET,Got) Then Begin DoRead:=Fail(STATUS_ERROR or ERR_NOT_READY);Exit;End;
  A:=@Packet;
  If Lo(A^.Status)=ERR_DISK_CHANGE Then Begin
   CopyLabel(A^);
   R.IoLabel:=@VolSer;
  End;
  Cnt:=A^.Transferred;
  If Cnt<>0 Then Begin
   If (Cnt>Want) Or (Not DataLen(Cnt,Bytes)) Then Begin DoRead:=Fail(STATUS_ERROR or ERR_READ_FAULT);Exit;End;
   If Not Link.Recv(PBuf(R.IoData)^,Bytes,Got) Then Begin DoRead:=Fail(STATUS_ERROR or ERR_NOT_READY);Exit;End;
  End;
  R.Transferred:=Cnt;
  DoRead:=A^.Status;
 End;
End;

Function DoWrite(Var R:TReq):Word;
Var Err,Got,Want,Bytes:Word;Q:TIoReq;A:PIoAns;
 Function Fail(St:Word):Word;Begin
  R.Transferred:=0;
  Fail:=St;
 End;
Begin
 With D^ do Begin
  Want:=R.IoCount;
  If R.Unit_<MAX_DEVICES Then
   If (DriveMap[R.Unit_] and $80)<>0 Then Begin DoWrite:=Fail(STATUS_ERROR or ERR_WRITE_PROT);Exit;End;
  If Not CheckUnit(R,Err) Then Begin DoWrite:=Fail(Err);Exit;End;
  If R.Cmd=8 Then Q.PacketType:=WRITE_REQ Else Q.PacketType:=WRITE_VER_REQ;
  Q.Unit_:=Lo(MappedUnit);
  Q.MediaId:=R.Media;
  Q.Requested:=Want;
  ConvertStart(R,Q);
  If Not Link.Send(Q,SizeOf(Q)) Then Begin DoWrite:=Fail(STATUS_ERROR or ERR_NOT_READY);Exit;End;
  If Not DataLen(Want,Bytes) Then Begin DoWrite:=Fail(STATUS_ERROR or ERR_WRITE_FAULT);Exit;End;
  If Not Link.Send(PBuf(R.IoData)^,Bytes) Then Begin DoWrite:=Fail(STATUS_ERROR or ERR_NOT_READY);Exit;End;
  If Not Link.Recv(Packet,MAX_PACKET,Got) Then Begin DoWrite:=Fail(STATUS_ERROR or ERR_NOT_READY);Exit;End;
  A:=@Packet;
  If Lo(A^.Status)=ERR_DISK_CHANGE Then Begin
   CopyLabel(A^);
   R.IoLabel:=@VolSer;
  End;
  R.Transferred:=A^.Transferred;
  DoWrite:=A^.Status;
 End;
End;

  { Ouverture et fermeture d'un lecteur }
Function DoOpenClose(Var R:TReq):Word;
Var Err,Got:Word;Q:TLptCmd;
Begin
 With D^ do Begin
  If Not MapUnit(R.Unit_,Err) Then Begin DoOpenClose:=Err;Exit;End;
  DoOpenClose:=STATUS_DONE;
  If (DdAttr[MappedUnit] and ATT_OCRM)=0 Then Exit;
  If Not CheckUnit(R,Err) Then Begin DoOpenClose:=Err;Exit;End;
  If R.Cmd=13 Then Q.PacketType:=DEV_OPEN_REQ Else Q.PacketType:=DEV_CLOSE_REQ;
  Q.LptId:=Lo(MappedUnit);
  If Not Link.Send(Q,SizeOf(Q)) Then Begin DoOpenClose:=STATUS_ERROR or ERR_NOT_READY;Exit;End;
  If Not Link.Recv(Packet,MAX_PACKET,Got) Then Begin DoOpenClose:=STATUS_ERROR or ERR_NOT_READY;Exit;End;
  DoOpenClose:=PWord(@Packet)^;
 End;
End;

Function DoRemovable(Var R:TReq):Word;
Var Err:Word;
Begin
 If MapUnit(R.Unit_,Err) Then DoRemovable:=STATUS_DONE Else DoRemovable:=Err;
End;

  { IOCTL generique, categorie 8: lecture (66h) et ecriture (46h) de
    l'identification du support (numero de serie, nom de volume) }
Function DoGenIoctl(Var R:TReq):Word;
Var Err,Got:Word;Q:TIoctlReq;Fn:Byte;Data:Pointer;
Begin
 With D^ do Begin
  If Not MapUnit(R.Unit_,Err) Then Begin DoGenIoctl:=Err;Exit;End;
  Fn:=R.Func;
  If ((DdAttr[MappedUnit] and ATT_GEN_IOCTL)=0) Or (R.Category<>8) Or
     ((Fn<>$46) And (Fn<>$66)) Then Begin
   DoGenIoctl:=STATUS_ERROR or ERR_UNK_COMMAND;
   Exit;
  End;
  Data:=R.GenData;
  Q.PacketType:=GEN_IOCTL_REQ;
  Q.Unit_:=Lo(MappedUnit);
  Q.Category:=8;
  Q.Func:=Fn;
  DoGenIoctl:=STATUS_ERROR or ERR_NOT_READY;
  If Not Link.Send(Q,SizeOf(Q)) Then Exit;
  If Fn=$46 Then If Not Link.Send(PBuf(Data)^,SizeOf(TMediaIdBuf)) Then Exit;
  If Not Link.Recv(Packet,MAX_PACKET,Got) Then Exit;
  DoGenIoctl:=PWord(@Packet)^;
  If (PWord(@Packet)^ and STATUS_ERROR)=0 Then
   If Fn=$66 Then
    If Not Link.Recv(PBuf(Data)^,SizeOf(TMediaIdBuf),Got) Then DoGenIoctl:=STATUS_ERROR or ERR_NOT_READY;
 End;
End;

  { Gestionnaire du peripherique a blocs }
Function BlockHandler(Var R:TReq):Word;
Var Need,Comm:Boolean;St:Word;
Begin
 With D^ do Begin
  Comm:=R.Cmd in [1,2,4,8,9,13,14,19];
  Need:=Comm;
  If (R.Cmd=19) And (R.Func<>$46) And (R.Func<>$66) Then Need:=False;
  If Need And (Link.Base=0) Then
   If (Not ConnectPorts) Or (Not GetRemoteInfo) Then Begin
    BlockHandler:=NotReady(R);
    Exit;
   End;
  Case R.Cmd of
   1:St:=DoMediaCheck(R);
   2:St:=DoBuildBpb(R);
   3,5,6,7,10,11,12,16:St:=0;
   4:St:=DoRead(R);
   8,9:St:=DoWrite(R);
   13,14:St:=DoOpenClose(R);
   15:St:=DoRemovable(R);
   19:St:=DoGenIoctl(R);
   Else St:=STATUS_ERROR or ERR_UNK_COMMAND;
  End;
  If Comm And (Link.Base=0) Then St:=NotReady(R);
  BlockHandler:=St;
 End;
End;

 { ------------------------------------------------------------------ imprimantes }

  { Numero d'imprimante du serveur associe au LPT du client, ou 3 si aucun }
Function LptId:Byte;Begin
 With D^ do
  If (DevId>=1) And (DevId<=3) Then LptId:=PrnMap[DevId-1] Else LptId:=3;
End;

  { Envoie Cnt octets a imprimer }
Function LptWriteBlock(Var Data;Cnt:Word;Var R:TReq):Word;
Var Q:TLptReq;A:PLptAns;Got:Word;
Begin
 With D^ do Begin
  LptWriteBlock:=STATUS_ERROR or ERR_NOT_READY;
  If LptId>=3 Then Begin
   LptWriteBlock:=STATUS_ERROR or ERR_UNK_UNIT;
   R.Transferred:=0;
   Exit;
  End;
  Q.PacketType:=AUX_WRITE_REQ;
  Q.LptId:=LptId;
  Q.Count:=Cnt;
  Q.Data:=TBuf(Data)[0];
  R.Transferred:=0;
  If Not Link.Send(Q,SizeOf(Q)) Then Exit;
  If Cnt<>1 Then If Not Link.Send(Data,Cnt) Then Exit;
  If Not Link.Recv(Packet,MAX_PACKET,Got) Then Exit;
  A:=@Packet;
  R.Transferred:=A^.Transferred;
  LptWriteBlock:=A^.Status;
 End;
End;

Function LptFlush(Var R:TReq):Word;
Var St:Word;
Begin
 With D^ do Begin
  LptFlush:=0;
  If LptCount=0 Then Exit;
  St:=LptWriteBlock(LptBuf,LptCount,R);
  If (St and STATUS_ERROR)=0 Then LptCount:=0;
  LptFlush:=St;
 End;
End;

Function LptWrite(Var R:TReq):Word;
Var Cnt:Word;St:Word;
Begin
 With D^ do Begin
  If LptId>=3 Then Begin
   R.Transferred:=0;
   LptWrite:=STATUS_ERROR or ERR_UNK_UNIT;
   Exit;
  End;
  Cnt:=R.IoCount;
  If LptBuffering=0 Then Begin
   LptWrite:=LptWriteBlock(PBuf(R.IoData)^,Cnt,R);
   Exit;
  End;
  If (LongInt(LptCount)+Cnt)>MAX_LPT_BUFF Then Begin
   St:=LptFlush(R);
   If (St and STATUS_ERROR)<>0 Then Begin LptWrite:=St;Exit;End;
  End;
  If Cnt>=MAX_LPT_BUFF Then Begin
   LptWrite:=LptWriteBlock(PBuf(R.IoData)^,Cnt,R);
   Exit;
  End;
  Move(PBuf(R.IoData)^,LptBuf[LptCount],Cnt);
  Inc(LptCount,Cnt);
  St:=STATUS_DONE;
  If LptCount>=MAX_LPT_BUFF Then Begin
   St:=LptFlush(R);
   If (St and STATUS_ERROR)<>0 Then Begin LptWrite:=St;Exit;End;
  End;
  R.Transferred:=Cnt;
  LptWrite:=STATUS_DONE;
 End;
End;

  { Etat de sortie, vidage, ouverture et fermeture d'une imprimante }
Function LptCommand(Var R:TReq;Req:Byte):Word;
Var Q:TLptCmd;Got:Word;
Begin
 With D^ do Begin
  If LptId>=3 Then Begin LptCommand:=STATUS_ERROR or ERR_UNK_UNIT;Exit;End;
  Q.PacketType:=Req;
  Q.LptId:=LptId;
  LptCommand:=STATUS_ERROR or ERR_NOT_READY;
  If Not Link.Send(Q,SizeOf(Q)) Then Exit;
  If Not Link.Recv(Packet,MAX_PACKET,Got) Then Exit;
  LptCommand:=PWord(@Packet)^;
 End;
End;

Function LptHandler(Var R:TReq):Word;
Var Comm:Boolean;St:Word;
Begin
 With D^ do Begin
  Comm:=R.Cmd in [8,9,13,14];
  If Comm And (Link.Base=0) Then
   If (Not ConnectPorts) Or (Not GetRemoteInfo) Then Begin
    If (R.Cmd=13) Or (R.Cmd=14) Then LptHandler:=0 Else LptHandler:=NotReady(R);
    Exit;
   End;
  Case R.Cmd of
   0:St:=0;
   8,9:St:=LptWrite(R);
   10:St:=LptCommand(R,OUTPUT_STATUS_REQ);
   11:Begin
       St:=LptFlush(R);
       If (St and STATUS_ERROR)=0 Then St:=LptCommand(R,FLUSH_OUTPUT_REQ);
      End;
   13,14:If LptId>=3 Then St:=STATUS_DONE
          Else Begin
           St:=LptFlush(R);
           If (St and STATUS_ERROR)=0 Then Begin
            If R.Cmd=13 Then Begin
             LptBuffering:=1;
             St:=LptCommand(R,AUX_DEV_OPEN_REQ);
            End
             Else
            Begin
             LptBuffering:=0;
             St:=LptCommand(R,AUX_DEV_CLOSE_REQ);
            End;
           End;
          End;
   Else St:=STATUS_ERROR or ERR_UNK_COMMAND;
  End;
  If Comm And (Link.Base=0) Then Begin
   If (R.Cmd=13) Or (R.Cmd=14) Then St:=0 Else St:=NotReady(R);
  End;
  LptHandler:=St;
 End;
End;

 { ------------------------------------------------------------------ point d'entree }

  { Appele par le code d'entree du pilote (pile et DS du programme) }
Procedure DriverMain;
Var R:PReq;St:Word;
Begin
 R:=RhPtr;
 If DevId=0 Then St:=BlockHandler(R^) Else St:=LptHandler(R^);
 R^.Status:=St or STATUS_DONE;
 D^.IdleSem:=MINIMUM_TICKS+1;
End;

  { Appele par le chronometre (INT 1Ch): octet d'inactivite }
Procedure IdleTick;
Var T:Word;
Begin
 With D^ do Begin
  If (BusyFlag<>0) Or (Link.Base=0) Or (IdleSem=0) Then Exit;
  If IdleSem<>1 Then Begin
   Dec(IdleSem);
   Link.IdleWait:=0;
   Exit;
  End;
  T:=Link.Now;
  If T=Link.IdleStamp Then Exit;
  Link.IdleStamp:=T;
  If Link.IsSerial<>0 Then Link.IdleSerial Else Link.IdleParallel;
 End;
End;
{ ================================================================== END HANDLERS }

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
Function CodeSeg:Word;Begin CodeSeg:=CSeg;End;
Function PspSeg:Word;Begin PspSeg:=PrefixSeg;End;
{ -- DOS-LOW2-END -- }

Var
 SaveSS,SaveSP,TSaveSS,TSaveSP:Word;
 InTimer:Byte;
 OldInt1C,OldInt25,OldInt26,OldInt2F:Pointer;
 GFirstUnit,GUnits,GDriverId:Byte;
 GVersion:Word;
 DrvStack:Array[0..2047] of Byte;
 IdleStack:Array[0..511] of Byte;

  { ------------------------------------------------------------------ points d'entree }
  { Code d'entree du pilote de peripherique et gestionnaires d'interruption,
    en assembleur integre. Les en-tetes de peripheriques se trouvent dans le
    segment de code du programme; DOS appelle le pilote par un appel eloigne
    (strategie puis interruption). L'interruption bascule sur la pile
    DrvStack et appelle DriverMain, ecrite en Pascal. }
{ -- BASM-BEGIN -- }
Procedure DrvStrategy;Assembler;
Asm
 push ds
 push ax
 mov  ax,seg @Data
 mov  ds,ax
 mov  word ptr RhPtr,bx
 mov  word ptr RhPtr+2,es
 pop  ax
 pop  ds
 retf
End;

Procedure DrvIntrCommon;Assembler;
Asm
 pushf
 cli
 cld
 push ds
 push es
 push bx
 push cx
 push dx
 push di
 push si
 push bp
 mov  bx,seg @Data
 mov  ds,bx
 mov  DevId,al
 mov  bl,0FFh
 xchg bl,BusyFlag
 or   bl,bl
 jnz  @Busy
 mov  SaveSS,ss
 mov  SaveSP,sp
 mov  ax,ds
 mov  ss,ax
 mov  sp,offset DrvStack+2048
 sti
 call DriverMain
 mov  BusyFlag,0
 cli
 mov  ss,SaveSS
 mov  sp,SaveSP
 jmp  @Done
@Busy:
 les  bx,RhPtr
 mov  word ptr es:[bx+3],8102h
@Done:
 pop  bp
 pop  si
 pop  di
 pop  dx
 pop  cx
 pop  bx
 pop  es
 pop  ds
 popf
 pop  ax
 retf
End;

Procedure DrvIntr0;Assembler;
Asm
 push ax
 mov  al,0
 jmp  DrvIntrCommon
End;

Procedure DrvIntr1;Assembler;
Asm
 push ax
 mov  al,1
 jmp  DrvIntrCommon
End;

Procedure DrvIntr2;Assembler;
Asm
 push ax
 mov  al,2
 jmp  DrvIntrCommon
End;

Procedure DrvIntr3;Assembler;
Asm
 push ax
 mov  al,3
 jmp  DrvIntrCommon
End;

  { En-tetes des peripheriques (18 octets chacun), dans l'ordre de la chaine:
    LPT3, LPT2, LPT1, peripherique a blocs, puis l'empreinte du pilote
    ('INTERLNK', version, segment de donnees). Les champs de chainage sont
    remplis a l'installation. }
Procedure DrvHeader;Assembler;
Asm
 dw 0FFFFh,0FFFFh
 dw 8800h
 dw offset DrvStrategy
 dw offset DrvIntr3
 db 'LPT3    '
 dw 0FFFFh,0FFFFh
 dw 8800h
 dw offset DrvStrategy
 dw offset DrvIntr2
 db 'LPT2    '
 dw 0FFFFh,0FFFFh
 dw 8800h
 dw offset DrvStrategy
 dw offset DrvIntr1
 db 'LPT1    '
 dw 0FFFFh,0FFFFh
 dw 2842h
 dw offset DrvStrategy
 dw offset DrvIntr0
 db 0,0,0,0,0,0,0,0
 db 'INTERLNK'
 db 1,0
 dw 0
End;

Procedure RetStub;Assembler;
Asm
 iret
End;

  { INT 2Fh, fonction 56h: detection du pilote et des lecteurs redirigeables
    (AL=0 installation, AL=1 lecteur BH, AL=2 adresse de port CX) }
Procedure Int2FHook;Assembler;
Asm
 sub  sp,4
 push bp
 mov  bp,sp
 cmp  ah,56h
 jne  @Pass
 cmp  dx,0FFFFh
 jne  @Pass
 push ds
 push si
 mov  si,seg @Data
 mov  ds,si
 cmp  bl,0
 je   @Func
 cmp  bl,GDriverId
 jne  @Pass2
@Func:
 cmp  al,0
 je   @Ok
 cmp  al,1
 je   @Chk
 cmp  al,2
 jne  @Pass2
 cmp  cx,word ptr Drv
 jne  @Fail
 jmp  @Ok
@Chk:
 cmp  bh,25
 ja   @Pass2
 cmp  bh,GFirstUnit
 jb   @Fail
 push ax
 mov  al,GFirstUnit
 add  al,GUnits
 cmp  bh,al
 pop  ax
 jae  @Fail
@Ok:
 mov  al,0FFh
 jmp  @Answer
@Fail:
 or   bl,bl
 jz   @Pass2
 mov  al,0
@Answer:
 mov  bl,GDriverId
 mov  cx,GVersion
 mov  dx,cs
 pop  si
 pop  ds
 pop  bp
 add  sp,4
 iret
@Pass2:
 pop  si
 pop  ds
@Pass:
 push ds
 push ax
 mov  ax,seg @Data
 mov  ds,ax
 mov  ax,word ptr OldInt2F
 mov  [bp+2],ax
 mov  ax,word ptr OldInt2F+2
 mov  [bp+4],ax
 pop  ax
 pop  ds
 pop  bp
 retf
End;

  { INT 25h (lecture absolue): refuse l'acces aux lecteurs redirigeables }
Procedure Int25Hook;Assembler;
Asm
 sub  sp,4
 push bp
 mov  bp,sp
 push ds
 push bx
 mov  bx,seg @Data
 mov  ds,bx
 cmp  al,GFirstUnit
 jb   @Pass
 mov  bl,GFirstUnit
 add  bl,GUnits
 cmp  al,bl
 jae  @Pass
 pop  bx
 pop  ds
 pop  bp
 add  sp,4
 mov  ax,0102h
 stc
 retf
@Pass:
 mov  bx,word ptr OldInt25
 mov  [bp+2],bx
 mov  bx,word ptr OldInt25+2
 mov  [bp+4],bx
 pop  bx
 pop  ds
 pop  bp
 retf
End;

  { INT 26h (ecriture absolue) }
Procedure Int26Hook;Assembler;
Asm
 sub  sp,4
 push bp
 mov  bp,sp
 push ds
 push bx
 mov  bx,seg @Data
 mov  ds,bx
 cmp  al,GFirstUnit
 jb   @Pass
 mov  bl,GFirstUnit
 add  bl,GUnits
 cmp  al,bl
 jae  @Pass
 pop  bx
 pop  ds
 pop  bp
 add  sp,4
 mov  ax,0102h
 stc
 retf
@Pass:
 mov  bx,word ptr OldInt26
 mov  [bp+2],bx
 mov  bx,word ptr OldInt26+2
 mov  [bp+4],bx
 pop  bx
 pop  ds
 pop  bp
 retf
End;

  { INT 1Ch (chronometre): octets d'inactivite entre deux requetes }
Procedure TimerHook;Assembler;
Asm
 sub  sp,4
 push bp
 mov  bp,sp
 push ds
 push es
 push ax
 push bx
 push cx
 push dx
 push si
 push di
 mov  ax,seg @Data
 mov  ds,ax
 mov  ax,word ptr OldInt1C
 mov  [bp+2],ax
 mov  ax,word ptr OldInt1C+2
 mov  [bp+4],ax
 cmp  InTimer,0
 jne  @Out
 mov  InTimer,1
 cld
 mov  TSaveSS,ss
 mov  TSaveSP,sp
 mov  ax,ds
 mov  ss,ax
 mov  sp,offset IdleStack+512
 call IdleTick
 mov  ss,TSaveSS
 mov  sp,TSaveSP
 mov  InTimer,0
@Out:
 pop  di
 pop  si
 pop  dx
 pop  cx
 pop  bx
 pop  ax
 pop  es
 pop  ds
 pop  bp
 retf
End;
{ -- BASM-END -- }

 { ------------------------------------------------------------------ messages }
Const
 M_BANNER=1; M_NEEDDOS=2; M_ALREADY=3; M_INVSWITCH=4; M_BADDRIVES=5; M_BADBAUD=6;
 M_BADCOM=7; M_BADLPT=8; M_BADSERADDR=9; M_BADBIOSSER=10; M_TOOMANYSER=11;
 M_BADPARADDR=12; M_BADBIOSPAR=13; M_TOOMANYPAR=14; M_NOPORTS=15; M_NODEVICES=16;
 M_TRYCONN=17; M_CONNOK=18; M_CONNFAIL=19; M_MAXBAUD=20; M_NODRIVER=21;
 M_DRIVES=22; M_NODRIVES=23; M_PRINTERS=24; M_NOPRINTERS=25; M_MAPHDR1=26;
 M_MAPHDR2=27; M_EQUALS=28; M_NOTCONN=29; M_LOSTCONN=30; M_DRVSYNTAX=31;
 M_LASTDRIVE=32; M_NOCDS=33; M_BADVER=34; M_USAGE=40;

Type
 TLanguage=(_French,_English,_Germany);

Var
 Language:TLanguage;
 TmpLanguage:String;

Function Msg(N:Integer):String;Begin
 Case Language of
  _English:Case N of
   M_BANNER:Msg:='Microsoft InterLnk (Pascal clone)  Version 1.00';
   M_NEEDDOS:Msg:='InterLnk requires DOS 3.1 or later.';
   M_ALREADY:Msg:='InterLnk is already installed.';
   M_INVSWITCH:Msg:='Invalid switch: ';
   M_BADDRIVES:Msg:='Invalid number of drives in /DRIVES.';
   M_BADBAUD:Msg:='Invalid /BAUD rate (9600, 19200, 38400, 57600 or 115200).';
   M_BADCOM:Msg:='Invalid /COM parameter.';
   M_BADLPT:Msg:='Invalid /LPT parameter.';
   M_BADSERADDR:Msg:='Invalid serial port address: ';
   M_BADBIOSSER:Msg:='Serial port not present (BIOS number): ';
   M_TOOMANYSER:Msg:='Too many serial ports specified: ';
   M_BADPARADDR:Msg:='Invalid parallel port address: ';
   M_BADBIOSPAR:Msg:='Parallel port not present (BIOS number): ';
   M_TOOMANYPAR:Msg:='Too many parallel ports specified: ';
   M_NOPORTS:Msg:='No communication port to look for the server (see /COM and /LPT).';
   M_NODEVICES:Msg:='No drive or printer can be redirected.';
   M_TRYCONN:Msg:='Scanning for the server ';
   M_CONNOK:Msg:='Server found.';
   M_CONNFAIL:Msg:='No server found.';
   M_MAXBAUD:Msg:='Maximum baud rate: ';
   M_NODRIVER:Msg:='The InterLnk driver was not installed.';
   M_DRIVES:Msg:='InterLnk drives: ';
   M_NODRIVES:Msg:='InterLnk drives: none.';
   M_PRINTERS:Msg:='InterLnk printers: ';
   M_NOPRINTERS:Msg:='InterLnk printers: none.';
   M_MAPHDR1:Msg:='This Computer';
   M_MAPHDR2:Msg:='Other Computer';
   M_EQUALS:Msg:='equals';
   M_NOTCONN:Msg:='Unable to connect to the server (is INTERSVR running?).';
   M_LOSTCONN:Msg:='The connection with the server was lost.';
   M_DRVSYNTAX:Msg:='Invalid drive assignment, expected: client[:]=[server][:]';
   M_LASTDRIVE:Msg:='Warning: add LASTDRIVE=Z to CONFIG.SYS to get more redirectable drives.';
   M_NOCDS:Msg:='No free drive letter is available for redirection.';
   M_BADVER:Msg:='The installed InterLnk driver has a different version.';
   M_USAGE:Msg:='Connects two computers by a serial or parallel cable and redirects drives and printers.';
   M_USAGE+1:Msg:='INTERLNK [client[:]=[server][:]]';
   M_USAGE+2:Msg:='INTERLNK [/DRIVES:n] [/NOPRINTER] [/COM[:n|:addr]] [/LPT[:n|:addr]] [/NOSCAN]';
   M_USAGE+3:Msg:='         [/AUTO] [/LOW] [/BAUD:rate] [/V]';
   M_USAGE+4:Msg:='  client      Drive letter of the redirected drive on this computer.';
   M_USAGE+5:Msg:='  server      Drive letter on the other computer (omit it to cancel).';
   M_USAGE+6:Msg:='  /DRIVES:n   Number of drives to redirect (default 3).';
   M_USAGE+7:Msg:='  /NOPRINTER  Does not redirect printers.';
   M_USAGE+8:Msg:='  /COM, /LPT  Ports where the server is searched (all, BIOS number or address).';
   M_USAGE+9:Msg:='  /NOSCAN     Installs without trying to connect to the server.';
   M_USAGE+10:Msg:='  /AUTO       Installs only if a server is found.';
   M_USAGE+11:Msg:='  /LOW        Accepted for compatibility (the driver stays in low memory).';
   M_USAGE+12:Msg:='  /BAUD:rate  Maximum serial rate: 9600, 19200, 38400, 57600 or 115200.';
   M_USAGE+13:Msg:='  /V          Forces the echo of each byte (variable speed mode).';
   M_USAGE+14:Msg:='The first run installs the driver, the next runs act as the INTERLNK command.';
  End;
  _Germany:Case N of
   M_BANNER:Msg:='Microsoft InterLnk (Pascal-Klon)  Version 1.00';
   M_NEEDDOS:Msg:='InterLnk benoetigt DOS 3.1 oder hoeher.';
   M_ALREADY:Msg:='InterLnk ist bereits installiert.';
   M_INVSWITCH:Msg:='Ungueltige Option: ';
   M_BADDRIVES:Msg:='Ungueltige Laufwerksanzahl bei /DRIVES.';
   M_BADBAUD:Msg:='Ungueltige /BAUD-Rate (9600, 19200, 38400, 57600 oder 115200).';
   M_BADCOM:Msg:='Ungueltiger /COM-Parameter.';
   M_BADLPT:Msg:='Ungueltiger /LPT-Parameter.';
   M_BADSERADDR:Msg:='Ungueltige Adresse der seriellen Schnittstelle: ';
   M_BADBIOSSER:Msg:='Serielle Schnittstelle nicht vorhanden (BIOS-Nummer): ';
   M_TOOMANYSER:Msg:='Zu viele serielle Schnittstellen angegeben: ';
   M_BADPARADDR:Msg:='Ungueltige Adresse der parallelen Schnittstelle: ';
   M_BADBIOSPAR:Msg:='Parallele Schnittstelle nicht vorhanden (BIOS-Nummer): ';
   M_TOOMANYPAR:Msg:='Zu viele parallele Schnittstellen angegeben: ';
   M_NOPORTS:Msg:='Keine Schnittstelle zur Suche des Servers (siehe /COM und /LPT).';
   M_NODEVICES:Msg:='Kein Laufwerk und kein Drucker kann umgeleitet werden.';
   M_TRYCONN:Msg:='Suche nach dem Server ';
   M_CONNOK:Msg:='Server gefunden.';
   M_CONNFAIL:Msg:='Kein Server gefunden.';
   M_MAXBAUD:Msg:='Hoechste Baudrate: ';
   M_NODRIVER:Msg:='Der InterLnk-Treiber wurde nicht installiert.';
   M_DRIVES:Msg:='InterLnk-Laufwerke: ';
   M_NODRIVES:Msg:='InterLnk-Laufwerke: keine.';
   M_PRINTERS:Msg:='InterLnk-Drucker: ';
   M_NOPRINTERS:Msg:='InterLnk-Drucker: keine.';
   M_MAPHDR1:Msg:='Dieser Computer';
   M_MAPHDR2:Msg:='Anderer Computer';
   M_EQUALS:Msg:='gleich';
   M_NOTCONN:Msg:='Verbindung zum Server nicht moeglich (laeuft INTERSVR?).';
   M_LOSTCONN:Msg:='Die Verbindung zum Server wurde unterbrochen.';
   M_DRVSYNTAX:Msg:='Ungueltige Laufwerkszuordnung, erwartet: Client[:]=[Server][:]';
   M_LASTDRIVE:Msg:='Achtung: LASTDRIVE=Z in CONFIG.SYS eintragen, um mehr Laufwerke umzuleiten.';
   M_NOCDS:Msg:='Kein freier Laufwerksbuchstabe fuer die Umleitung verfuegbar.';
   M_BADVER:Msg:='Der installierte InterLnk-Treiber hat eine andere Version.';
   M_USAGE:Msg:='Verbindet zwei Computer ueber ein serielles oder paralleles Kabel und leitet Laufwerke und Drucker um.';
   M_USAGE+1:Msg:='INTERLNK [Client[:]=[Server][:]]';
   M_USAGE+2:Msg:='INTERLNK [/DRIVES:n] [/NOPRINTER] [/COM[:n|:Adr]] [/LPT[:n|:Adr]] [/NOSCAN]';
   M_USAGE+3:Msg:='         [/AUTO] [/LOW] [/BAUD:Rate] [/V]';
   M_USAGE+4:Msg:='  Client      Laufwerksbuchstabe des umgeleiteten Laufwerks auf diesem Computer.';
   M_USAGE+5:Msg:='  Server      Laufwerksbuchstabe auf dem anderen Computer (leer: aufheben).';
   M_USAGE+6:Msg:='  /DRIVES:n   Anzahl der umzuleitenden Laufwerke (Standard 3).';
   M_USAGE+7:Msg:='  /NOPRINTER  Leitet keine Drucker um.';
   M_USAGE+8:Msg:='  /COM, /LPT  Schnittstellen zur Suche des Servers (alle, BIOS-Nummer, Adresse).';
   M_USAGE+9:Msg:='  /NOSCAN     Installiert ohne Verbindungsversuch.';
   M_USAGE+10:Msg:='  /AUTO       Installiert nur, wenn ein Server gefunden wird.';
   M_USAGE+11:Msg:='  /LOW        Aus Kompatibilitaetsgruenden akzeptiert.';
   M_USAGE+12:Msg:='  /BAUD:Rate  Hoechste serielle Rate: 9600, 19200, 38400, 57600 oder 115200.';
   M_USAGE+13:Msg:='  /V          Erzwingt das Echo jedes Bytes.';
   M_USAGE+14:Msg:='Der erste Aufruf installiert den Treiber, spaetere Aufrufe wirken als Befehl INTERLNK.';
  End;
  Else Case N of
   M_BANNER:Msg:='Microsoft InterLnk (clone Pascal)  Version 1.00';
   M_NEEDDOS:Msg:='InterLnk requiert DOS 3.1 ou superieur.';
   M_ALREADY:Msg:='InterLnk est deja installe.';
   M_INVSWITCH:Msg:='Option invalide : ';
   M_BADDRIVES:Msg:='Nombre de lecteurs invalide pour /DRIVES.';
   M_BADBAUD:Msg:='Vitesse /BAUD invalide (9600, 19200, 38400, 57600 ou 115200).';
   M_BADCOM:Msg:='Parametre /COM invalide.';
   M_BADLPT:Msg:='Parametre /LPT invalide.';
   M_BADSERADDR:Msg:='Adresse de port serie invalide : ';
   M_BADBIOSSER:Msg:='Port serie absent (numero du BIOS) : ';
   M_TOOMANYSER:Msg:='Trop de ports series specifies : ';
   M_BADPARADDR:Msg:='Adresse de port parallele invalide : ';
   M_BADBIOSPAR:Msg:='Port parallele absent (numero du BIOS) : ';
   M_TOOMANYPAR:Msg:='Trop de ports paralleles specifies : ';
   M_NOPORTS:Msg:='Aucun port de communication pour chercher le serveur (voir /COM et /LPT).';
   M_NODEVICES:Msg:='Aucun lecteur ni aucune imprimante ne peut etre redirige.';
   M_TRYCONN:Msg:='Recherche du serveur ';
   M_CONNOK:Msg:='Serveur trouve.';
   M_CONNFAIL:Msg:='Aucun serveur trouve.';
   M_MAXBAUD:Msg:='Vitesse maximale : ';
   M_NODRIVER:Msg:='Le pilote InterLnk n''a pas ete installe.';
   M_DRIVES:Msg:='Lecteurs InterLnk : ';
   M_NODRIVES:Msg:='Lecteurs InterLnk : aucun.';
   M_PRINTERS:Msg:='Imprimantes InterLnk : ';
   M_NOPRINTERS:Msg:='Imprimantes InterLnk : aucune.';
   M_MAPHDR1:Msg:='Cet ordinateur';
   M_MAPHDR2:Msg:='Autre ordinateur';
   M_EQUALS:Msg:='egale';
   M_NOTCONN:Msg:='Impossible de se connecter au serveur (INTERSVR est-il lance ?).';
   M_LOSTCONN:Msg:='La connexion avec le serveur a ete perdue.';
   M_DRVSYNTAX:Msg:='Affectation de lecteur invalide, attendu : client[:]=[serveur][:]';
   M_LASTDRIVE:Msg:='Attention : ajoutez LASTDRIVE=Z dans CONFIG.SYS pour obtenir plus de lecteurs redirigeables.';
   M_NOCDS:Msg:='Aucune lettre de lecteur libre n''est disponible pour la redirection.';
   M_BADVER:Msg:='Le pilote InterLnk installe a une version differente.';
   M_USAGE:Msg:='Relie deux ordinateurs par un cable serie ou parallele et redirige les lecteurs et les imprimantes.';
   M_USAGE+1:Msg:='INTERLNK [client[:]=[serveur][:]]';
   M_USAGE+2:Msg:='INTERLNK [/DRIVES:n] [/NOPRINTER] [/COM[:n|:adr]] [/LPT[:n|:adr]] [/NOSCAN]';
   M_USAGE+3:Msg:='         [/AUTO] [/LOW] [/BAUD:vitesse] [/V]';
   M_USAGE+4:Msg:='  client      Lettre du lecteur redirige sur cet ordinateur.';
   M_USAGE+5:Msg:='  serveur     Lettre du lecteur sur l''autre ordinateur (vide : annule).';
   M_USAGE+6:Msg:='  /DRIVES:n   Nombre de lecteurs a rediriger (3 par defaut).';
   M_USAGE+7:Msg:='  /NOPRINTER  Ne redirige pas les imprimantes.';
   M_USAGE+8:Msg:='  /COM, /LPT  Ports ou chercher le serveur (tous, numero du BIOS ou adresse).';
   M_USAGE+9:Msg:='  /NOSCAN     Installe sans essayer de se connecter au serveur.';
   M_USAGE+10:Msg:='  /AUTO       Installe seulement si un serveur est trouve.';
   M_USAGE+11:Msg:='  /LOW        Accepte par compatibilite (le pilote reste en memoire basse).';
   M_USAGE+12:Msg:='  /BAUD:vit.  Vitesse serie maximale : 9600, 19200, 38400, 57600 ou 115200.';
   M_USAGE+13:Msg:='  /V          Force l''echo de chaque octet (mode a vitesse variable).';
   M_USAGE+14:Msg:='Le premier lancement installe le pilote, les suivants agissent comme la commande INTERLNK.';
  End;
 End;
End;

 { ------------------------------------------------------------------ utilitaires }

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

Function HexStr(V:Word):String;
Const Digits:String[16]='0123456789ABCDEF';
Var S:String;
Begin
 S:='';
 Repeat
  S:=Digits[(V and $F)+1]+S;
  V:=V shr 4;
 Until V=0;
 HexStr:=S;
End;

Function Pad(S:String;N:Integer):String;Begin
 While Length(S)<N do S:=S+' ';
 Pad:=S;
End;

  { Chaine ASCIIZ d'une zone de caracteres }
Function AsciiZ(Var A;Max:Integer):String;
Var I:Integer;S:String;
Begin
 S:='';
 I:=0;
 While (I<Max) And (TBuf(A)[I]<>0) do Begin
  S:=S+Chr(TBuf(A)[I]);
  Inc(I);
 End;
 AsciiZ:=S;
End;

 { ------------------------------------------------------------------ ports }
Var
 CmdLine:String;
 OptNoScan,OptAuto,OptHelp:Boolean;
 Regs:Registers;

Function CharAt(Const S:String;P:Integer):Char;Begin
 If P<=Length(S) Then CharAt:=S[P] Else CharAt:=#0;
End;

  { Valide une adresse d'entree-sortie de port }
Function ValidPort(A:Word):Boolean;Begin
 ValidPort:=((A and 3)=0) And (A>=$200) And (A<$8000);
End;

Procedure AddSerial(A:Word);
Var Bios:Byte;I:Integer;Addr:Word;
Begin
 With Drv do Begin
  Addr:=A;
  If A=0 Then Begin WriteLn(Msg(M_BADSERADDR),HexStr(A));Exit;End;
  If A<=4 Then Begin
   If A>NumCom Then Begin WriteLn(Msg(M_BADBIOSSER),HexStr(A));Exit;End;
   Addr:=PeekW($40,(A-1)*2);
  End;
  If Not ValidPort(Addr) Then Begin WriteLn(Msg(M_BADSERADDR),HexStr(Addr));Exit;End;
  For I:=0 to NumSer-1 do If SerPorts[I].Addr=Addr Then Exit;
  If NumSer>=4 Then Begin WriteLn(Msg(M_TOOMANYSER),HexStr(Addr));Exit;End;
  Bios:=0;
  For I:=0 to NumCom-1 do If PeekW($40,I*2)=Addr Then Bios:=I+1;
  SerPorts[NumSer].Addr:=Addr;
  SerPorts[NumSer].Bios:=Bios;
  Inc(NumSer);
  Inc(NumPorts);
 End;
End;

Procedure AddParallel(A:Word);
Var Bios:Byte;I:Integer;Addr:Word;
Begin
 With Drv do Begin
  Addr:=A;
  If A=0 Then Begin WriteLn(Msg(M_BADPARADDR),HexStr(A));Exit;End;
  If A<=3 Then Begin
   If A>NumLpt Then Begin WriteLn(Msg(M_BADBIOSPAR),HexStr(A));Exit;End;
   Addr:=PeekW($40,8+(A-1)*2);
  End;
  If Not ValidPort(Addr) Then Begin WriteLn(Msg(M_BADPARADDR),HexStr(Addr));Exit;End;
  For I:=0 to NumPar-1 do If ParPorts[I].Addr=Addr Then Exit;
  If NumPar>=4 Then Begin WriteLn(Msg(M_TOOMANYPAR),HexStr(Addr));Exit;End;
  Bios:=0;
  For I:=0 to NumLpt-1 do If PeekW($40,8+I*2)=Addr Then Bios:=I+1;
  ParPorts[NumPar].Addr:=Addr;
  ParPorts[NumPar].Bios:=Bios;
  Inc(NumPar);
  Inc(NumPorts);
 End;
End;

  { Argument de /COM ou /LPT: rien ou * = tous les ports du BIOS, sinon un
    numero du BIOS ou une adresse hexadecimale }
Procedure SetPortArg(Const S:String;Var P:Integer;Serial:Boolean);
Var C:Char;V:Word;I:Integer;Bad:Boolean;
Begin
 Bad:=False;
 V:=0;
 C:=CharAt(S,P);
 If (C<=' ') Then Begin
  If Serial Then For I:=1 to Drv.NumCom do AddSerial(I)
            Else For I:=1 to Drv.NumLpt do AddParallel(I);
  Exit;
 End;
 If (C=':') Or (C='=') Then Inc(P);
 C:=CharAt(S,P);
 If C in ['A'..'Z'] Then Bad:=True
  Else
 If C='*' Then Begin
  Inc(P);
  If Serial Then For I:=1 to Drv.NumCom do AddSerial(I)
            Else For I:=1 to Drv.NumLpt do AddParallel(I);
  Exit;
 End
  Else
 If C in ['0'..'9'] Then Begin
  While (CharAt(S,P) in ['0'..'9','A'..'F']) do Begin
   If CharAt(S,P)<='9' Then V:=(V shl 4) or (Ord(CharAt(S,P))-48)
                       Else V:=(V shl 4) or (Ord(CharAt(S,P))-55);
   Inc(P);
  End;
  If Serial Then AddSerial(V) Else AddParallel(V);
  Exit;
 End
  Else
 Bad:=True;
 If Bad Then If Serial Then WriteLn(Msg(M_BADCOM)) Else WriteLn(Msg(M_BADLPT));
End;

  { Analyse les options de DEVICE=INTERLNK.EXE; les jetons sans / ni - sont des
    correspondances de lecteurs, traitees plus loin }
Function ParseSwitches(S:String):Boolean;
Var P:Integer;C:Char;N:LongInt;
 Function Match(Const K:String):Boolean;Begin
  Match:=False;
  If Copy(S,P,Length(K))<>K Then Exit;
  If CharAt(S,P+Length(K)) in ['A'..'Z'] Then Exit;
  Match:=True;
 End;
 Function Number:LongInt;
 Var V:LongInt;
 Begin
  V:=0;
  While CharAt(S,P) in ['0'..'9'] do Begin
   If V<1000000 Then V:=V*10+Ord(CharAt(S,P))-48;
   Inc(P);
  End;
  Number:=V;
 End;
Begin
 ParseSwitches:=True;
 S:=StrUpper(S);
 P:=1;
 While P<=Length(S) do Begin
  C:=S[P];
  Inc(P);
  If (C='/') Or (C='-') Then Begin
   If Match('COM') Then Begin Inc(P,3);SetPortArg(S,P,True);End
    Else
   If Match('LPT') Then Begin Inc(P,3);SetPortArg(S,P,False);End
    Else
   If Match('LOW') Then Inc(P,3)
    Else
   If Match('DRIVES') Then Begin
    Inc(P,6);
    If (CharAt(S,P) in [':','=']) And (CharAt(S,P+1) in ['0'..'9']) Then Begin
     Inc(P);
     N:=Number;
     If N>MAX_DEVICES Then WriteLn(Msg(M_BADDRIVES)) Else Drv.DefaultUnits:=N;
    End
     Else
    WriteLn(Msg(M_BADDRIVES));
   End
    Else
   If Match('NOPRINTER') Then Begin Inc(P,9);Drv.PrinterLoaded:=0;End
    Else
   If Match('NOSCAN') Then Begin Inc(P,6);OptNoScan:=True;End
    Else
   If Match('AUTO') Then Begin Inc(P,4);OptAuto:=True;End
    Else
   If Match('BAUD') Then Begin
    Inc(P,4);
    N:=0;
    If (CharAt(S,P) in [':','=']) And (CharAt(S,P+1) in ['0'..'9']) Then Begin
     Inc(P);
     N:=Number;
    End;
    If N=9600 Then Drv.Link.ClientMaxBaud:=3
     Else
    If N=19200 Then Drv.Link.ClientMaxBaud:=4
     Else
    If N=38400 Then Drv.Link.ClientMaxBaud:=5
     Else
    If N=57600 Then Drv.Link.ClientMaxBaud:=6
     Else
    If N=115200 Then Drv.Link.ClientMaxBaud:=7
     Else
    WriteLn(Msg(M_BADBAUD));
    Drv.Link.MaxBaud:=Drv.Link.ClientMaxBaud;
   End
    Else
   If Match('V') Then Begin Inc(P);Drv.Link.ForceVar:=1;End
    Else
   If CharAt(S,P)='?' Then Begin Inc(P);OptHelp:=True;End
    Else
   Begin
    Write(Msg(M_INVSWITCH),'/');
    While CharAt(S,P) in ['0'..'9','A'..'Z'] do Begin
     Write(S[P]);
     Inc(P);
    End;
    WriteLn;
    ParseSwitches:=False;
    Exit;
   End;
  End
   Else
  If C<>' ' Then
   While (P<=Length(S)) And (S[P]<>' ') do Inc(P);
 End;
End;

  { Correspondances de lecteurs "client[:]=[serveur][:]" (INTERLNK E:=A:) }
Function ParseMappings(S:String):Boolean;
Var P:Integer;C:Char;Local:Integer;Mapped,I:Integer;
Begin
 ParseMappings:=False;
 S:=StrUpper(S);
 P:=1;
 While P<=Length(S) do Begin
  C:=S[P];
  Inc(P);
  If C='/' Then Begin
   While (P<=Length(S)) And (S[P]<>' ') do Inc(P);
  End
   Else
  If (C<>',') And (C<>':') And (C<>' ') Then Begin
   If Not (C in ['A'..'Z']) Then Exit;
   Local:=Ord(C)-65-D^.FirstUnit;
   If (Local<0) Or (Local>=MAX_DEVICES) Then Exit;
   Repeat
    C:=CharAt(S,P);
    If C<' ' Then Exit;
    Inc(P);
   Until C<>':';
   If C<>'=' Then Exit;
   While CharAt(S,P)=':' do Inc(P);
   C:=CharAt(S,P);
   If C<=' ' Then Mapped:=UNASSIGNED
    Else
   Begin
    If Local>=D^.Units Then Exit;
    If Not (C in ['A'..'Z']) Then Mapped:=UNASSIGNED
     Else
    Begin
     Inc(P);
     Mapped:=Ord(C)-65;
      { le lecteur du serveur ne peut servir qu'une fois }
     I:=0;
     While (I<MAX_DEVICES) And (D^.DriveMap[I]<>Mapped) do Inc(I);
     If I<MAX_DEVICES Then Begin
      D^.DriveMap[I]:=UNASSIGNED;
      D^.DefaultMap[I]:=UNASSIGNED;
     End;
    End;
   End;
   D^.DriveMap[Local]:=Mapped;
   D^.DefaultMap[Local]:=Mapped;
  End;
 End;
 ParseMappings:=True;
End;

 { ------------------------------------------------------------------ affichage }

Function PortName:String;
Var S:String;
Begin
 With D^ do
  If Link.IsSerial<>0 Then Begin
   If SerPorts[PortIndex].Bios<>0 Then S:='COM'+DecStr(SerPorts[PortIndex].Bios)
                                  Else S:='COM('+HexStr(SerPorts[PortIndex].Addr)+')';
  End
   Else
  Begin
   If ParPorts[PortIndex].Bios<>0 Then S:='LPT'+DecStr(ParPorts[PortIndex].Bios)
                                  Else S:='LPT('+HexStr(ParPorts[PortIndex].Addr)+')';
  End;
 PortName:=S;
End;

  { Recherche du serveur avec affichage de la progression }
Function ConnectServer:Boolean;
Var Ok:Boolean;
Begin
 Write(Msg(M_TRYCONN));
 D^.DisplayScan:=True;
 Ok:=ConnectPorts;
 D^.DisplayScan:=False;
 If Ok Then Begin
  D^.Initialized:=0;
  Ok:=GetRemoteInfo;
 End;
 If Ok Then Begin
  WriteLn(' ',Msg(M_CONNOK));
  WriteLn('Port=',PortName);
  D^.IdleSem:=0;
 End
  Else
 Begin
  WriteLn(' ',Msg(M_CONNFAIL));
  D^.Link.Base:=0;
 End;
 ConnectServer:=Ok;
End;

  { Table de correspondance des lecteurs (retourne False si la liaison est perdue) }
Function ShowDriveMap:Boolean;
Var I,M:Integer;Q:TDriveInfoReq;Got:Word;A:^TDriveInfoAns;
Begin
 ShowDriveMap:=True;
 WriteLn;
 WriteLn(Pad(Msg(M_MAPHDR1),19),Msg(M_MAPHDR2));
 WriteLn(Pad('(Client)',19),'(Server)');
 WriteLn(Pad('-------------',19),'--------------');
 With D^ do
  For I:=0 to Units-1 do Begin
   M:=DriveMap[I] and $7F;
   If (DriveMap[I]<>UNASSIGNED) And (DriveMap[I]<>DONT_CARE) And (M<MAX_DEVICES) Then Begin
    Write(' ',Chr(65+FirstUnit+I),':  ',Pad(Msg(M_EQUALS),9),Chr(65+M),':   ');
    Q.PacketType:=DRIVE_INFO_REQ;
    Q.Drive:=M;
    If (Not Link.Send(Q,SizeOf(Q))) Or (Not Link.Recv(Packet,MAX_PACKET,Got)) Then Begin
     WriteLn;
     WriteLn(Msg(M_LOSTCONN));
     ShowDriveMap:=False;
     Exit;
    End;
    A:=@Packet;
    WriteLn(Pad(AsciiZ(A^.Size,10),9),AsciiZ(A^.VolLabel,12));
   End;
  End;
End;

Procedure ShowPrinterMap;
Var I:Integer;
Begin
 With D^ do
  If PrinterLoaded<>0 Then
   For I:=0 to 2 do
    If (PrnMap[I]<3) Then
     WriteLn(' LPT',I+1,':  ',Pad(Msg(M_EQUALS),9),'LPT',PrnMap[I]+1,':');
End;

Procedure ShowUnits;
Begin
 With D^ do Begin
  If Units=0 Then WriteLn(Msg(M_NODRIVES))
   Else
  WriteLn(Msg(M_DRIVES),Units,' (',Chr(65+FirstUnit),': - ',Chr(65+FirstUnit+Units-1),':)');
  If PrinterLoaded=0 Then WriteLn(Msg(M_NOPRINTERS))
   Else
  WriteLn(Msg(M_PRINTERS),3-NumLpt,' (LPT',NumLpt+1,' - LPT3)');
 End;
End;

Procedure ShowUsage;
Var I:Integer;
Begin
 WriteLn(Msg(M_BANNER));
 WriteLn;
 For I:=0 to 14 do Begin
  WriteLn(Msg(M_USAGE+I));
  If I=0 Then WriteLn;
 End;
End;

 { ------------------------------------------------------------------ installation }
Const
 DPB_SIZE=48;
Var
 DpbStore:Array[0..MAX_DEVICES*DPB_SIZE-1] of Byte;

Procedure GetSysVars(Var S,O:Word);
Var R:Registers;
Begin
 R.AH:=$52;
 MsDos(R);
 S:=R.ES;
 O:=R.BX;
End;

  { Identifiant arbitraire non nul du client: zone de donnees du BIOS et compteur du chronometre }
Procedure MakeClientId;
Var I:Integer;L,H:Word;
Begin
 L:=0;
 H:=0;
 For I:=0 to 63 do Begin
  L:=L xor PeekW($40,I*4);
  H:=H xor PeekW($40,I*4+2);
 End;
 OutB($43,0);
 L:=L xor (InB($40) or (Word(InB($40)) shl 8));
 OutB($43,0);
 H:=H xor (InB($40) or (Word(InB($40)) shl 8));
 If (L=0) And (H=0) Then L:=1;
 Drv.ClientId:=(LongInt(H) shl 16) or L;
End;

  { Remplit le DPB du lecteur K a partir d'un BPB par defaut (le BPB reel est
    demande au serveur lors du premier acces, DOS reconstruit alors le DPB) }
Procedure MakeDpb(K:Integer;Ver4:Boolean);
Var Base,Spf,Root,FirstRoot,FirstData:Word;
 Procedure SetB(O:Word;V:Byte);Begin DpbStore[Base+O]:=V;End;
 Procedure SetW(O:Word;V:Word);Begin
  DpbStore[Base+O]:=V and $FF;
  DpbStore[Base+O+1]:=V shr 8;
 End;
Begin
 Base:=K*DPB_SIZE;
 FillChar(DpbStore[Base],DPB_SIZE,0);
 Spf:=1;
 Root:=64;
 FirstRoot:=1+2*Spf;
 FirstData:=FirstRoot+(Root*32+511) div 512;
 SetB(0,Drv.FirstUnit+K);
 SetB(1,K);
 SetW(2,512);
 SetB(4,0);
 SetB(5,0);
 SetW(6,1);
 SetB(8,2);
 SetW(9,Root);
 SetW($0B,FirstData);
 SetW($0D,(128-FirstData)+1);
 SetW($0F,Spf);
 If Ver4 Then Begin
  SetW($11,FirstRoot);
  SetW($13,OfsOf(@DrvHeader)+54);
  SetW($15,CodeSeg);
  SetB($17,0);
  SetB($18,$FF);
  SetW($19,$FFFF);
  SetW($1B,$FFFF);
  SetW($1D,0);
  SetW($1F,$FFFF);
 End
  Else
 Begin
  SetW($10,FirstRoot);
  SetW($12,OfsOf(@DrvHeader)+54);
  SetW($14,CodeSeg);
  SetB($16,0);
  SetB($17,$FF);
  SetW($18,$FFFF);
  SetW($1A,$FFFF);
  SetW($1C,0);
  SetW($1E,$FFFF);
 End;
End;

  { Cree les DPB et les CDS des lecteurs redirigeables et les ajoute a DOS.
    Retourne le nombre de lecteurs effectivement crees. }
Function MakeDrives:Integer;
Var SvS,SvO,CdsS,CdsO,CdsSize,Last,Tmpl,DpbNext,I,K,N:Word;Ver4:Boolean;
 Flags:Word;E,DS_,DO_,Co_,PS,PO:Word;
Begin
 MakeDrives:=0;
 GetSysVars(SvS,SvO);
 Ver4:=Hi(Drv.DosVersion)>=4;
 Last:=PeekB(SvS,SvO+$21);
 CdsO:=PeekW(SvS,SvO+$16);
 CdsS:=PeekW(SvS,SvO+$18);
 If Ver4 Then CdsSize:=88 Else CdsSize:=81;
 If Ver4 Then DpbNext:=$19 Else DpbNext:=$18;
  { entree CDS modele: premier lecteur physique valide }
 Tmpl:=$FFFF;
 For I:=0 to Last-1 do Begin
  Flags:=PeekW(CdsS,CdsO+I*CdsSize+$43);
  If (Tmpl=$FFFF) And ((Flags and $4000)<>0) And ((Flags and $B000)=0) Then Tmpl:=I;
 End;
 If Tmpl=$FFFF Then Exit;
  { nombre de lecteurs possibles }
 N:=0;
 While (N<Drv.Units) And (Drv.FirstUnit+N<Last) And (PeekW(CdsS,CdsO+(Drv.FirstUnit+N)*CdsSize+$43)=0) do Inc(N);
 If N=0 Then Exit;
 DS_:=SegOf(@DpbStore);
 For K:=0 to N-1 do Begin
  MakeDpb(K,Ver4);
  DO_:=OfsOf(@DpbStore)+K*DPB_SIZE;
   { CDS: copie du modele puis chemin, indicateurs et DPB }
  Co_:=CdsO+(Drv.FirstUnit+K)*CdsSize;
  For I:=0 to CdsSize-1 do PokeB(CdsS,Co_+I,PeekB(CdsS,CdsO+Tmpl*CdsSize+I));
  For I:=0 to 66 do PokeB(CdsS,Co_+I,0);
  PokeB(CdsS,Co_,65+Drv.FirstUnit+K);
  PokeB(CdsS,Co_+1,Ord(':'));
  PokeB(CdsS,Co_+2,Ord('\'));
  PokeW(CdsS,Co_+$43,$4000);
  PokeW(CdsS,Co_+$45,DO_);
  PokeW(CdsS,Co_+$47,DS_);
  PokeW(CdsS,Co_+$49,$FFFF);
  PokeW(CdsS,Co_+$4F,2);
   { chainage a la fin de la liste des DPB }
  PS:=PeekW(SvS,SvO+2);
  PO:=PeekW(SvS,SvO);
  I:=0;
  While (PeekW(PS,PO+DpbNext)<>$FFFF) And (I<64) do Begin
   E:=PeekW(PS,PO+DpbNext+2);
   PO:=PeekW(PS,PO+DpbNext);
   PS:=E;
   Inc(I);
  End;
  PokeW(PS,PO+DpbNext,DO_);
  PokeW(PS,PO+DpbNext+2,DS_);
 End;
 PokeB(SvS,SvO+$20,Drv.FirstUnit+N);
 MakeDrives:=N;
End;

  { Chaine les en-tetes de peripheriques apres le peripherique NUL }
Procedure LinkDevices;
Var H,C,NulS,NulO,SvS,SvO:Word;Lst:Array[0..3] of Word;N,I:Integer;
Begin
 H:=OfsOf(@DrvHeader);
 C:=CodeSeg;
 PokeW(C,H+82,SegOf(@Drv));
 N:=0;
 If Drv.PrinterLoaded<>0 Then
  For I:=3 downto Drv.NumLpt+1 do Begin
   Lst[N]:=H+(3-I)*18;
   Inc(N);
  End;
 If Drv.Units>0 Then Begin
  Lst[N]:=H+54;
  Inc(N);
  PokeB(C,H+54+10,Drv.Units);
 End;
 If N=0 Then Exit;
 GetSysVars(SvS,SvO);
 NulS:=SvS;
 NulO:=SvO+$22;
 For I:=0 to N-2 do Begin
  PokeW(C,Lst[I],Lst[I+1]);
  PokeW(C,Lst[I]+2,C);
 End;
 PokeW(C,Lst[N-1],PeekW(NulS,NulO));
 PokeW(C,Lst[N-1]+2,PeekW(NulS,NulO+2));
 PokeW(NulS,NulO,Lst[0]);
 PokeW(NulS,NulO+2,C);
End;

Procedure HookVectors;Begin
 GFirstUnit:=Drv.FirstUnit;
 GUnits:=Drv.Units;
 GDriverId:=1;
 GVersion:=VerMajor or (VerMinor shl 8);
 GetIntVec($2F,OldInt2F);
 If OldInt2F=Nil Then OldInt2F:=@RetStub
  Else
 Begin
   { numero logique du pilote: un de plus que le dernier pilote repondant }
  Regs.AX:=$5600;
  Regs.BX:=0;
  Regs.DX:=$FFFF;
  Intr($2F,Regs);
  If Regs.AL=$FF Then GDriverId:=Regs.BL+1;
 End;
 SetIntVec($2F,@Int2FHook);
 GetIntVec($25,OldInt25);
 SetIntVec($25,@Int25Hook);
 GetIntVec($26,OldInt26);
 SetIntVec($26,@Int26Hook);
 GetIntVec($1C,OldInt1C);
 If OldInt1C=Nil Then OldInt1C:=@RetStub;
 SetIntVec($1C,@TimerHook);
End;

  { Libere l'environnement pour reduire la memoire residente }
Procedure FreeEnvironment;
Var Env:Word;
Begin
 Env:=PeekW(PspSeg,$2C);
 If Env<>0 Then Begin
  Regs.AH:=$49;
  Regs.ES:=Env;
  MsDos(Regs);
  PokeW(PspSeg,$2C,0);
 End;
End;

Procedure ShowMaxBaud;
Begin
 With Drv.Link do
  If ClientMaxBaud<BAUD_115200 Then Begin
   Write(Msg(M_MAXBAUD));
   Case ClientMaxBaud of
    3:WriteLn(9600);
    4:WriteLn(19200);
    5:WriteLn(38400);
    6:WriteLn(57600);
   End;
  End;
End;

Procedure NotInstalled;Begin
 WriteLn(Msg(M_NODRIVER));
 Halt(1);
End;

  { Premier lancement: installe le pilote en memoire }
Procedure Install;
Var SvS,SvO:Word;Eq:Word;Created,Want:Integer;Ver:Word;
Begin
 WriteLn(Msg(M_BANNER));
 Ver:=DosVersion;
 If (Lo(Ver)<3) Or ((Lo(Ver)=3) And (Hi(Ver)<10)) Then Begin
  WriteLn(Msg(M_NEEDDOS));
  Halt(1);
 End;
 FillChar(Drv,SizeOf(Drv),0);
 D:=@Drv;
 InitCrcTab;
 Drv.Link.Init;
 Drv.DosVersion:=(Word(Lo(Ver)) shl 8) or Hi(Ver);
 Drv.DefaultUnits:=3;
 Drv.PrinterLoaded:=1;
 FillChar(Drv.DriveMap,MAX_DEVICES,DONT_CARE);
 FillChar(Drv.DefaultMap,MAX_DEVICES,DONT_CARE);
  { materiel declare par le BIOS }
 Intr($11,Regs);
 Eq:=Regs.AX;
 Drv.NumLpt:=(Eq shr 14) and 3;
 Drv.NumCom:=(Eq shr 9) and 7;
 If Drv.NumCom>4 Then Drv.NumCom:=4;
 If Drv.NumLpt=3 Then Drv.PrinterLoaded:=0;
 If Not ParseSwitches(CmdLine) Then NotInstalled;
 If OptHelp Then Begin
  ShowUsage;
  Halt(0);
 End;
 If Drv.NumPorts=0 Then Begin
  ParseSwitches('/LPT* /COM*');
 End;
 MakeClientId;
 GetSysVars(SvS,SvO);
 Drv.MaxSecSize:=PeekW(SvS,SvO+$10);
 Drv.FirstUnit:=PeekB(SvS,SvO+$20);
 Want:=Drv.DefaultUnits;
 If Drv.FirstUnit>=MAX_DEVICES Then Want:=0
  Else
 If Want>MAX_DEVICES-Drv.FirstUnit Then Want:=MAX_DEVICES-Drv.FirstUnit;
 Drv.Units:=Want;
 If Drv.NumPorts=0 Then Begin
  WriteLn(Msg(M_NOPORTS));
  NotInstalled;
 End;
 If (Drv.Units=0) And (Drv.PrinterLoaded=0) Then Begin
  WriteLn(Msg(M_NODEVICES));
  NotInstalled;
 End;
 ShowMaxBaud;
  { correspondances demandees sur la ligne de commande }
 If Not ParseMappings(CmdLine) Then Begin
  WriteLn(Msg(M_DRVSYNTAX));
  NotInstalled;
 End;
 If Not OptNoScan Then
  If (Not ConnectServer) And OptAuto Then NotInstalled;
 If (Drv.Link.Base<>0) Then Drv.IdleSem:=MINIMUM_TICKS+1;
  { DPB et CDS des lecteurs }
 If Drv.Units>0 Then Begin
  Created:=MakeDrives;
  If Created<Drv.Units Then Begin
   WriteLn(Msg(M_LASTDRIVE));
   Drv.Units:=Created;
   If Created=0 Then WriteLn(Msg(M_NOCDS));
  End;
 End;
 If (Drv.Units=0) And (Drv.PrinterLoaded=0) Then Begin
  WriteLn(Msg(M_NODEVICES));
  NotInstalled;
 End;
 ShowUnits;
 If Drv.Link.Base<>0 Then Begin
  If ShowDriveMap Then ShowPrinterMap;
 End;
 LinkDevices;
 HookVectors;
 Drv.Link.LastTick:=BiosTicks;
 FreeEnvironment;
 Keep(0);
End;

 { ------------------------------------------------------------------ commande }

  { Retrouve le pilote installe par l'interface multiplex INT 2Fh, AH=56h }
Function FindDriver(Var ResCode,ResData:Word):Integer;
Var I:Integer;Ok:Boolean;
Begin
 FindDriver:=0;
 Regs.AX:=$5600;
 Regs.BX:=0;
 Regs.CX:=0;
 Regs.DX:=$FFFF;
 Intr($2F,Regs);
 If (Regs.AL<>$FF) Or (Regs.DX=$FFFF) Then Exit;
 ResCode:=Regs.DX;
 Ok:=True;
 For I:=0 to 7 do
  If PeekB(ResCode,OfsOf(@DrvHeader)+72+I)<>Ord('INTERLNK'[I+1]) Then Ok:=False;
 If Not Ok Then Exit;
 If (PeekB(ResCode,OfsOf(@DrvHeader)+80)<>VerMajor) Or
    (PeekB(ResCode,OfsOf(@DrvHeader)+81)<>VerMinor) Then Begin
  FindDriver:=2;
  Exit;
 End;
 ResData:=PeekW(ResCode,OfsOf(@DrvHeader)+82);
 FindDriver:=1;
End;

  { Lancements suivants: commande INTERLNK (etat, correspondances) }
Procedure Command;
Var ResCode,ResData:Word;Busy:PByte;Ok:Boolean;
Begin
 If FindDriver(ResCode,ResData)<>1 Then Begin
  WriteLn(Msg(M_BADVER));
  Halt(1);
 End;
 D:=MakePtr(ResData,OfsOf(@Drv));
 Busy:=MakePtr(ResData,OfsOf(@BusyFlag));
 If Not ParseMappings(CmdLine) Then Begin
  WriteLn(Msg(M_DRVSYNTAX));
  Halt(1);
 End;
 Busy^:=1;
 WriteLn;
 Ok:=ConnectServer;
 FillChar(D^.DefaultMap,MAX_DEVICES,DONT_CARE);
 If Not Ok Then Begin
  Busy^:=0;
  WriteLn(Msg(M_NOTCONN));
  Halt(1);
 End;
 Ok:=ShowDriveMap;
 If Ok Then ShowPrinterMap;
 D^.IdleSem:=MINIMUM_TICKS+1;
 D^.Link.IdleStamp:=D^.Link.Now;
 Busy^:=0;
 If Not Ok Then Halt(1);
End;

Function Installed:Boolean;
Var A,B:Word;
Begin
 Installed:=FindDriver(A,B)<>0;
End;

BEGIN
 Language:=_French;
 TmpLanguage:=GetEnv('LANGUAGE');
 If TmpLanguage<>'' Then Begin
  If TmpLanguage[1]='"' Then TmpLanguage:=Copy(TmpLanguage,2,255);
  If StrUpper(Copy(TmpLanguage,1,2))='EN' Then Language:=_English Else
  If StrUpper(Copy(TmpLanguage,1,2))='GR' Then Language:=_Germany;
 End;
 InitCrcTab;
 CmdLine:='';
 If ParamCount>0 Then Begin
  CmdLine:=ParamStr(1);
  If ParamCount>1 Then CmdLine:=CmdLine+' '+ParamStr(2);
  If ParamCount>2 Then CmdLine:=CmdLine+' '+ParamStr(3);
  If ParamCount>3 Then CmdLine:=CmdLine+' '+ParamStr(4);
  If ParamCount>4 Then CmdLine:=CmdLine+' '+ParamStr(5);
  If ParamCount>5 Then CmdLine:=CmdLine+' '+ParamStr(6);
  If ParamCount>6 Then CmdLine:=CmdLine+' '+ParamStr(7);
  If ParamCount>7 Then CmdLine:=CmdLine+' '+ParamStr(8);
  If ParamCount>8 Then CmdLine:=CmdLine+' '+ParamStr(9);
 End;
 OptNoScan:=False;
 OptAuto:=False;
 OptHelp:=False;
 If Installed Then Begin
  If Pos('/?',CmdLine)>0 Then Begin
   ShowUsage;
   Halt(0);
  End;
  Command;
 End
  Else
 Begin
  If Pos('/?',CmdLine)>0 Then Begin
   ShowUsage;
   Halt(0);
  End;
  Install;
 End;
END.
