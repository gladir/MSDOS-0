{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program FDISK;

{$A-}

Uses Crt,DOS;

Type
 {Structure de lecture pour le disque }
 SecPosType=Record
  Head:Byte;
  SectTrack:Word;
 End;

 {Structure de partition}
 PartEntry=Record
  Status:Byte;
  StartSec:SecPosType;
  PartType:Byte;
  EndSec:SecPosType;
  SecOfs,NumSec:LongInt;
 End;

 PartSec=Record { d‚crit le secteur de partition }
  BootCode:Array[0..$1BD]of Byte;    { Code de d‚marrage du disque dur }
  PartTable:Array[0..3]of PartEntry; { Table des partitions de disque dur }
  IdCode:Word;                       { Signature: AA55h }
 End;

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 CurrentDisk:Byte;
 IsDisk:Boolean;
 FileName:String;
 Buffer:Array[0..1023]of Byte;

Procedure DiskReset;
{$IFDEF Windows}
 Begin
  WriteLn('Cette operation n''est pas mise en oeuvre.');
  Halt;
 End;
{$ElSE}
 Var
  Regs:Registers;
 Begin
  Regs.AH:=$00;
  Regs.DL:=0;
  Intr($13,Regs);
 End;
{$ENDIF}

Function ReadTrack(Lecteur,Face,Piste,Start,Nombre:Byte;Var Buffer):Byte;
{$IFDEF Windows}
 Begin
  WriteLn('Cette operation n''est pas mise en oeuvre.');
  Halt;
 End;
{$ElSE}
 Var
  Essais:Byte;
  Regs:Registers;
 Begin
  essais:=5;
  Repeat
   WriteLn(Essais);
   Regs.AH:=$02;        { Numero de fonction pour appel interruption }
   Regs.AL:=Nombre;     { Nombre Secteurs par Piste }
   Regs.CH:=Piste;      { Numero de Piste }
   Regs.CL:=Start;      { Commencer par le secteur 1 }
   Regs.DL:=Lecteur;    { Numero de lecteur }
   Regs.DH:=Face;       { Numero de la face }
   Regs.ES:=Seg(Buffer);{ Adresse pour tampon }
   Regs.BX:=Ofs(Buffer);
   Intr($13,Regs);
   If Regs.flags and fcarry=1Then DiskReset;
   Dec(essais);
  Until(Regs.flags and fcarry=0)or(Essais=0);
  ReadTrack:=Regs.AH;
 End;
{$ENDIF}

Function WriteTrack(Lecteur,Face,Piste,Start,Nombre:Byte;Var Buffer):Byte;
{$IFDEF Windows}
 Begin
  WriteLn('Cette operation n''est pas mise en oeuvre.');
  Halt;
 End;
{$ElSE}
 Var
  Essais:Byte;
  Regs:Registers;
 Begin
  essais:=5;
  Repeat
   Regs.AH:=$03;        { Numero de fonction pour appel interruption }
   Regs.AL:=Nombre;     { Nombre Secteurs par Piste }
   Regs.CH:=Piste;      { Numero de Piste }
   Regs.CL:=Start;      { Commencer par le secteur 1 }
   Regs.DL:=Lecteur;    { Numero de lecteur }
   Regs.DH:=Face;       { Numero de la face }
   Regs.ES:=Seg(Buffer);{ Adresse pour tampon }
   Regs.BX:=Ofs(Buffer);
   Intr($13,Regs);
   If Regs.flags and fcarry=1Then DiskReset;
   Dec(essais);
  Until(Regs.flags and fcarry=0)or(Essais=0);
  WriteTrack:=Regs.AH;
 End;
{$ENDIF}

Procedure ReadPartitionRecord;
Var
 Partition:File;
 ByteReaded:Word;
Begin
 If(IsDisk)Then Begin
  ReadTrack(CurrentDisk-1,0,0,1,1,Buffer);
 End
  Else
 If FileName<>''Then Begin
  {$I-}Assign(Partition,FileName);
  Reset(Partition,1);{$I+}
  If IOResult=0 Then Begin
   BlockRead(Partition,Buffer,512,ByteReaded);
   Close(Partition);
  End;
 End;
End;

Procedure WritePartitionRecord;
Var
 Partition:File;
 ByteReaded:Word;
Begin
 If(IsDisk)Then Begin
  WriteTrack(CurrentDisk-1,0,0,1,1,Buffer);
 End
  Else
 If FileName<>''Then Begin
  {$I-}Assign(Partition,FileName);
  Reset(Partition,1);{$I+}
  If IOResult=0 Then Begin
   BlockWrite(Partition,Buffer,512,ByteReaded);
   Close(Partition);
  End;
 End;
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

Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
End;

Procedure WriteLnCenter(S:String);Begin
 GotoXY((((Lo(WindMax)-Lo(WindMin))-Length(S))shr 1),WhereY);
 WriteLn(S);
End;

Procedure WriteListPartition;
Var
 Partition:PartSec Absolute Buffer;
 I:Byte;
 Letter:Char;
 TypeName:String;
Begin
 Write(' ':2,'Lecteur de disque dur en cours : ');
 HighVideo;
 If FileName<>''Then WriteLn(FileName)
                Else WriteLn(CurrentDisk);
 LowVideo;
 WriteLn;
 WriteLn(' ':2,'Partition    Etat   Type   Nom du volume    Mo  SystŠme    Utilis‚');
 ReadPartitionRecord;
 Letter:='C';
 For I:=0 to 3 do If Partition.PartTable[I].PartType<>0Then Begin
  Write(' ':3);
  If Partition.PartTable[I].PartType in[$04,$05,$06,$07,$0B,$0C]Then Begin
   Write(Letter,': ');
   Letter:=Succ(Letter);
  End
   Else
  Write(' ':3);
  HighVideo;
  Write(I+1,' ':9);
  LowVideo;
  If Partition.PartTable[I].Status=$80 Then Write('A')
                                       Else Write(' ');
  Write(' ':4);
  Write('PRI DOS',' ':2);
  Write('NOLABEL',' ':7);
  Write(2048,' ':3);
  Case Partition.PartTable[I].PartType of
   $00:TypeName:='Entr‚e vide';
   $01:TypeName:='FAT12';
   $02:TypeName:='XENIX root';
   $03:TypeName:='XENIX /usr';
   $04,$05,$06:TypeName:='FAT16';
   $07:TypeName:='NTFS ou HPFS';
   $08:TypeName:='D‚marrage AIX';
   $09:TypeName:='Donn‚es AIX';
   $0A:TypeName:='OS/2 Boot Manager';
   $0B,$0C:TypeName:='FAT32';
   $0D:TypeName:='SILICON SAFE';
   $0E,$0F:TypeName:='FAT16/WIN95';
   $11,$14,$16:TypeName:='FAT12 cach‚';
   $12:TypeName:='Partition de configuration';
   $17:TypeName:='IFS cach‚';
   $18:TypeName:='AST SmartSleep';
   $1B:TypeName:='FAT32 cach‚';
   $1C:TypeName:='FAT32';
   $1E:TypeName:='FAT16/WIN95';
   $24:TypeName:='NEC DOS';
   $27:TypeName:='MirOS';
   $2A:TypeName:='AtheOS';
   $2B:TypeName:='SylStor';
   $32:TypeName:='NOS';
   $35:TypeName:='JFS';
   Else TypeName:='Inconnu';
  End;
  Write(PadRight(TypeName,11));
  Write(100,'%');
  WriteLn;
 End;
End;

Procedure CreatePartition;Begin
 ClrScr;
 WriteLn('Cette fonctionnalit‚ n''est pas implement‚ !');
 ReadKey;
End;

Procedure ActivePartition;
Var
 Partition:PartSec Absolute Buffer;
 CurrActive,I,ActiveX,ActiveY:Byte;
Begin
 ClrScr;
 WriteLn;
 WriteLn;
 WriteLn;
 WriteLnCenter('Activation de la partition de la partition');
 WriteLn;
 WriteListPartition;
 WriteLn;
 WriteLn;
 WriteLn;
 Write(' ':2,'Entrez le num‚ro de la partition que vous voulez activer...: ');
 HighVideo;
 CurrActive:=0;
 For I:=0 to 3 do Begin
  If Partition.PartTable[I].Status=$80 Then CurrActive:=I+1;
 End;
 Write('[');
 ActiveX:=WhereX;
 ActiveY:=WhereY;
 WriteLn(CurrActive,']');
 GotoXY(1,25);
 LowVideo;
 Write(' ':2,'Appuyez sur ');
 HighVideo;
 Write('ECHAP');
 LowVideo;
 Write(' pour quitter FDISK');
 Repeat
  HighVideo;
  GotoXY(ActiveX,ActiveY);
  Write(CurrActive);
  GotoXY(ActiveX,ActiveY);
  LowVideo;
  Case ReadKey of
   '1':If Partition.PartTable[0].PartType<>0Then CurrActive:=1;
   '2':If Partition.PartTable[1].PartType<>0Then CurrActive:=2;
   '3':If Partition.PartTable[2].PartType<>0Then CurrActive:=3;
   '4':If Partition.PartTable[3].PartType<>0Then CurrActive:=4;
   #13:Begin
    WritePartitionRecord;
    Exit;
   End;
   #27:Exit;
  End;
 Until False;
End;

Procedure DeletePartition;Begin
 ClrScr;
 WriteLn('Cette fonctionnalit‚ n''est pas implement‚ !');
 Write(' ':2,'Appuyez sur ');
 HighVideo;
 Write('ECHAP');
 LowVideo;
 Write(' pour quitter FDISK');
 ReadKey;
End;

Procedure ShowPartition;Begin
 ClrScr;
 WriteLn;
 WriteLn;
 WriteLn;
 WriteLnCenter('Affichage des informations sur les partitions');
 WriteLn;
 WriteListPartition;
 GotoXY(1,25);
 Write(' ':2,'Appuyez sur ');
 HighVideo;
 Write('ECHAP');
 LowVideo;
 Write(' pour quitter FDISK');
 ReadKey;
End;

Procedure SelectFixedDisk;Begin
 ClrScr;
 WriteLn('Cette fonctionnalit‚ n''est pas implement‚ !');
 Write(' ':2,'Appuyez sur ');
 HighVideo;
 Write('ECHAP');
 LowVideo;
 Write(' pour quitter FDISK');
 ReadKey;
End;

Function ShowMainMenu:Byte;
Var
 Choice:Char;
Begin
 ShowMainMenu:=0;
 Choice:='4';
 TextBackground(0);
 TextColor(7);
 ClrScr;
 WriteLnCenter('MSDOS Version 0');
 WriteLnCenter('FDISK');
 WriteLnCenter('Gladir.com licence MIT 2022');
 WriteLn;
 HighVideo;
 Case Language of
  _English: WriteLnCenter('Fixed Disk Setup Program');
  Else WriteLnCenter('Options de FDISK');
 End;
 WriteLn;
 LowVideo;
 Case Language of
  _English:Write(' ':4,'Current Fixed Disk Drive: ');
  Else Write(' ':4,'Lecteur de disque dur en cours : ');
 End;
 HighVideo;
 If FileName<>''Then WriteLn(FileName)
                Else WriteLn(CurrentDisk);
 LowVideo;
 WriteLn;
 Case Language of
  _English:WriteLn(' ':4,'Choose one of the following: ');
  Else WriteLn(' ':4,'Choisissez parmi ce qui suit : ');
 End;
 WriteLn;
 HighVideo;
 Write(' ':4,'1. ');
 LowVideo;
 Case Language of
  _English: WriteLn('Create DOS Partition');
  Else WriteLn('Cr‚ation d''une partition ou lecteur logique DOS');
 End;
 HighVideo;
 Write(' ':4,'2. ');
 LowVideo;
 Case Language of
  _English:WriteLn('Change Active partition');
  Else WriteLn('Activation d''une partition');
 End;
 HighVideo;
 Write(' ':4,'3. ');
 LowVideo;
 Case Language of
  _English:WriteLn('Delete DOS partition');
  Else WriteLn('Suppression d''une partition ou lecteur logique DOS');
 End;
 HighVideo;
 Write(' ':4,'4. ');
 LowVideo;
 Case Language of
  _English:WriteLn('Display Partition Data');
  Else WriteLn('Affichage des informations sur les partitions');
 End;
 HighVideo;
 Write(' ':4,'5. ');
 LowVideo;
 Case Language of
  _English:WriteLn('Select Next Fixed Disk Drive');
  Else WriteLn('S‚lectionne le prochain unit‚ de disque dur');
 End;
 WriteLn;
 WriteLn;
 WriteLn;
 Case Language of
  _English:Write(' ':4,'Entrer choice: ');
  Else Write(' ':4,'Entrez votre choix : ');
 End;
 HighVideo;
 WriteLn('[',Choice,']');
 LowVideo;
 WriteLn;
 WriteLn;
 WriteLn;
 Case Language of
  _English:Begin
   Write(' ':4,'Press ');
   HighVideo;
   Write('Esc');
   LowVideo;
   Write(' to return to DOS');
  End;
  Else Begin
   Write(' ':4,'Appuyez sur ');
   HighVideo;
   Write('ECHAP');
   LowVideo;
   Write(' pour quitter FDISK');
  End;
 End;
 Repeat
  GotoXY(27,19);
  Write(Choice);
  GotoXY(27,19);
  Case ReadKey of
   #0:ReadKey;
   #13:Begin
    Case Choice of
     '1':ShowMainMenu:=1;
     '2':ShowMainMenu:=2;
     '3':ShowMainMenu:=3;
     '4':ShowMainMenu:=4;
     '5':ShowMainMenu:=5;
    End;
    Exit;
   End;
   #27:Exit;
   '1':Choice:='1';
   '2':Choice:='2';
   '3':Choice:='3';
   '4':Choice:='4';
   '5':Choice:='5';
  End;
 Until False;
End;

BEGIN
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ENDIF}
 {$ENDIF}
 Language:=_French;
 TmpLanguage:=GetEnv('LANGUAGE');
 If TmpLanguage<>''Then Begin
  If TmpLanguage[1]='"'Then TmpLanguage:=Copy(TmpLanguage,2,255);
  If StrToUpper(Copy(TmpLanguage,1,2))='EN'Then Language:=_English Else
  If StrToUpper(Copy(TmpLanguage,1,2))='GR'Then Language:=_Germany Else
  If StrToUpper(Copy(TmpLanguage,1,2))='IT'Then Language:=_Italian Else
  If StrToUpper(Copy(TmpLanguage,1,2))='SP'Then Language:=_Spain;
 End;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('FDISK : Cette commande permet d''effectuer la gestion d''un disque dur.');
  WriteLn;
  WriteLn('Syntaxe : FDISK [fichier]');
 End
  Else
 Begin
  If SizeOf(PartSec)<>512 Then Begin
   WriteLn('Mauvaise directe de compilation. Les enregistrements ne doivent pas ˆtre align‚s');
   Halt;
  End;
  FileName:='';
  CurrentDisk:=1;
  IsDisk:=True;
  If ParamStr(1)<>''Then Begin
   FileName:=ParamStr(1);
   IsDisk:=False;
  End;
  Repeat
   Case ShowMainMenu of
    0:Break;
    1:CreatePartition;
    2:ActivePartition;
    3:DeletePartition;
    4:ShowPartition;
    5:SelectFixedDisk;
   End;
  Until False;
  ClrScr;
 End;
END.