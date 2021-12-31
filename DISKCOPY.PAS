{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program DISKCOPY;

Uses DOS;

Type
 TeleDiskHeader=Record
  { Entete d'image }
  Signature:Array[0..1]of Byte;
  Sequence:Byte;
  Checksequence:Byte;
  TelediskVersion:Byte;
  DataRate:Byte;
  DriveType:Byte;
  Stepping:Byte;
  DOSAllocationFlag:Byte;
  Sides:Byte;
  CyclicRedundancyCheck:Array[0..1]of Byte;
   { Entete de commentaire }
  CommentCyclicRedundancyCheck:Array[0..1]of Byte;
  DataLength:Word;
  Year:Byte; { +1900}
  Month:Byte;
  Day:Byte;
  Hour:Byte;
  Minute:Byte;
  Second:Byte
 End;

Var
 TotSects,CurrPos,I:LongInt;
 CurrSide,CurrSec,CurrTrack,DskSource,DskTarget:Byte;
 IsDisk1,IsDisk2:Boolean;
 ByteReaded,FileStart:Integer;
 NmHeads,NumTrack,SecPerTrk:Word;
 CurrParam:String;
 FileName1,FileName2:String;
 FileSource,FileTarget:File {$IFDEF FPC}of Byte{$ENDIF};
 Buffer:Array[0..511]of Byte;
 TeleDisk:TeleDiskHeader Absolute Buffer;
 _CurrTrack:Array[0..3]of Byte;

Function TwoByteToWord(A,B:Byte):Word;Begin
 TwoByteToWord:=B*256+A;
End;

Function FourByteToLongInt(A,B,C,D:Byte):LongInt;Begin
 FourByteToLongInt:=D*16777216+C*65536+B*256+A;
End;

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

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('DISKCOPY : Cette commande permet de copier des disquettes ou des images.');
  WriteLn;
  WriteLn('Syntaxe : DISKCOPY disque: fichier');
  WriteLn('          DISKCOPY fichier fichier');
  WriteLn('          DISKCOPY fichier disque:');
 End
  Else
 If ParamCount>=2Then Begin
  FileStart:=0;
  IsDisk1:=False;
  IsDisk2:=False;
  FileName1:='';
  FileName2:='';
  CurrParam:=ParamStr(1);
  If(CurrParam[1]in['a'..'z','A'..'Z'])and(CurrParam[2]=':')Then IsDisk1:=True
                                                            Else FileName1:=CurrParam;
  CurrParam:=ParamStr(2);
  If(CurrParam[1]in['a'..'z','A'..'Z'])and(CurrParam[2]=':')Then IsDisk2:=True
                                                            Else FileName2:=CurrParam;
  If(IsDisk1=True)and(IsDisk2=False)Then Begin { Disque a fichier }
   CurrParam:=ParamStr(1);
   Case CurrParam[1]of
    'A','a':DskSource:=0;
    'B','b':DskSource:=1;
    'C','c':DskSource:=$80;
    'D','d':DskSource:=$81;
    Else Begin
     WriteLn('Disque source invalide');
     Halt;
    End;
   End;
   CurrSec:=0;
   CurrTrack:=0;
   CurrSide:=0;
   I:=0;
   WriteLn('Lecture des informations d''entete du disque...');
   If ReadTrack(DskSource,0,0,1,1,Buffer)<>0Then Begin
    WriteLn('Erreur de lecture de piste');
    Halt;
   End;
   TotSects:=TwoByteToWord(Buffer[$13],Buffer[$14]);
   If TotSects=0Then TotSects:=FourByteToLongInt(Buffer[$20],Buffer[$21],Buffer[$22],Buffer[$23]);
   NmHeads:=TwoByteToWord(Buffer[$1A],Buffer[$1B]);
   SecPerTrk:=TwoByteToWord(Buffer[$18],Buffer[$19]);
   If Buffer[$15]=$FDThen NumTrack:=40
                     Else NumTrack:=80;
   {$I-}Assign(FileTarget,FileName2);
   Rewrite(FileTarget);{$I+}
   Repeat
    If ReadTrack(DskSource,CurrSide,CurrTrack,CurrSec,1,Buffer)<>0Then Begin
     WriteLn('Erreur de lecture de piste');
     Halt;
    End;
    Inc(CurrSec);
    If(CurrSec>=SecPerTrk)Then Begin
     CurrSec:=0;
     Inc(CurrSide);
     If(CurrSide=NmHeads)Then Begin
      CurrSide:=0;
      Inc(CurrTrack);
     End;
    End;
    BlockWrite(FileTarget,Buffer,ByteReaded);
    Inc(I);
   Until I>TotSects;
   Close(FileTarget);
  End
   Else
  If(IsDisk1=False)and(IsDisk2=False)Then Begin { Fichier a fichier }
   WriteLn(FileName1,' vers ',FileName2);
   FillChar(Buffer,SizeOf(Buffer),0);
   {$I-}Assign(FileSource,FileName1);
   Reset(FileSource);{$I+}
   If IoResult=0Then Begin
    {$I-}Assign(FileTarget,FileName2);
    Rewrite(FileTarget);{$I+}
    If IoResult<>0Then Begin
     Close(FileSource);
     WriteLn('Erreur de creation du fichier destinataire !');
     Halt;
    End;
    BlockRead(FileSource,Buffer,SizeOf(Buffer),ByteReaded);
    If(Buffer[0]=Byte('T'))and(Buffer[1]=Byte('D'))Then Begin { Image TeleDisk? }
     FileStart:=SizeOf(TeleDiskHeader)+TeleDisk.DataLength;
     Seek(FileSource,FileStart);
     I:=0;
     Repeat
      BlockRead(FileSource,CurrTrack,SizeOf(CurrTrack),ByteReaded);
      If I>255Then Break;
      Inc(I);
      Inc(FileStart,4);
     Until(_CurrTrack[0]=$00)and(_CurrTrack[1]=$00)and(_CurrTrack[2]=$00)and(_CurrTrack[3]=$FF);
     WriteLn('Image TeleDisk detecter');
    End
     Else
    If(Buffer[0]=$AA)and(Buffer[1]=$59)Then Begin { Fichier image IBM OS/2 }
     FileStart:=$29;
     WriteLn('Image IBM OS/2 detecter');
    End
     Else
    WriteLn('Image standard detecter');
    Seek(FileSource,FileStart);
    While Not EOF(FileSource)do Begin
     BlockRead(FileSource,Buffer,SizeOf(Buffer),ByteReaded);
     BlockWrite(FileTarget,Buffer,ByteReaded);
    End;
    Close(FileTarget);
    Close(FileSource);
   End
    Else
   WriteLn('Probleme de lecture du fichier source !');
  End
   Else
  WriteLn('Cette operation n''est pas mise en oeuvre.');
 End
  Else
 WriteLn('Parametre manquant !');
END.
