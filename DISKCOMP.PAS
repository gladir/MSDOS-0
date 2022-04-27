{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program DISKCOMP;

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
 DiskIdentical:Boolean;
 TotSects,CurrPos,I:LongInt;
 CurrSide,CurrSec,CurrTrack,DskSource,DskTarget:Integer;
 IsDisk1,IsDisk2:Boolean;
 ByteReaded,FileStart:Integer;
 NmHeads,NumTrack,SecPerTrk:Word;
 CurrParam:String;
 FileName1,FileName2:String;
 FileSource,FileTarget:File {$IFDEF FPC} of Byte{$ENDIF};
 BufferSource,BufferTarget:Array[0..511]of Byte;
 TeleDisk:TeleDiskHeader Absolute BufferSource;
 _CurrTrack:Array[0..3]of Byte;

Function TwoByteToWord(A,B:Byte):Word;Begin
 TwoByteToWord:=B*256+A;
End;

Function FourByteToLongInt(A,B,C,D:Byte):LongInt;Begin
 FourByteToLongInt:=D*16777216+C*65536+B*256+A;
End;

Function CompareBuffer:Boolean;
Var
 I:Integer;
Begin
 CompareBuffer:=True;
 For I:=0 to 511 do Begin
  If BufferSource[I]<>BufferTarget[I]Then Begin
   CompareBuffer:=False;
   DiskIdentical:=False;
   Exit;
  End;
 End;
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

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('DISKCOMP : Cette commande permet de comparer des disquettes ou des images.');
  WriteLn;
  WriteLn('Syntaxe : DISKCOPY disque: fichier');
  WriteLn('          DISKCOPY fichier fichier');
  WriteLn('          DISKCOPY fichier disque:');
 End
  Else
 If ParamCount>=2Then Begin
  DiskIdentical:=True;
  FileStart:=0;
  IsDisk1:=False;
  IsDisk2:=False;
  FileName1:='';
  FileName2:='';
  CurrSec:=0;
  CurrTrack:=0;
  CurrSide:=0;
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
   I:=0;
   WriteLn('Lecture des informations d''entete du disque...');
   If ReadTrack(DskSource,0,0,1,1,BufferSource)<>0Then Begin
    WriteLn('Erreur de lecture de piste');
    Halt;
   End;
   TotSects:=TwoByteToWord(BufferSource[$13],BufferSource[$14]);
   If TotSects=0Then TotSects:=FourByteToLongInt(BufferSource[$20],
                    BufferSource[$21],BufferSource[$22],BufferSource[$23]);
   NmHeads:=TwoByteToWord(BufferSource[$1A],BufferSource[$1B]);
   SecPerTrk:=TwoByteToWord(BufferSource[$18],BufferSource[$19]);
   If BufferSource[$15]=$FDThen NumTrack:=40
                           Else NumTrack:=80;
   {$I-}Assign(FileTarget,FileName2);
   Rewrite(FileTarget);{$I+}
   Repeat
    If ReadTrack(DskSource,CurrSide,CurrTrack,CurrSec,1,BufferSource)<>0Then Begin
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
    BlockRead(FileTarget,BufferTarget,SizeOf(BufferTarget),ByteReaded);
    If Not(CompareBuffer)Then Begin
      WriteLn('Difference dans la comparaison');
      WriteLn('face ',CurrSide,', piste ',CurrTrack,' secteur ',CurrSec);
      WriteLn;
     End;
    Inc(I);
   Until I>TotSects;
   Close(FileTarget);
   If DiskIdentical Then Begin
    WriteLn;
    WriteLn('Disquette identique');
    WriteLn;
   End;
  End
   Else
  If(IsDisk1=False)and(IsDisk2=False)Then Begin { Fichier a fichier }
   WriteLn(FileName1,' vs ',FileName2);
   FillChar(BufferSource,SizeOf(BufferSource),0);
   FillChar(BufferTarget,SizeOf(BufferTarget),0);
   {$I-}Assign(FileSource,FileName1);
   Reset(FileSource);{$I+}
   If IoResult=0Then Begin
    CurrPos:=0;
    SecPerTrk:=9;
    NmHeads:=2;
    If FileSize(FileSource)=163840 Then Begin
     WriteLn('Disquette 5 1/4", 160 Ko, 40 pistes, 8 secteurs par piste, simple face');
     SecPerTrk:=8;
     NmHeads:=1;
    End
     Else
    If FileSize(FileSource)=327680 Then Begin
     WriteLn('Disquette 5 1/4", 320 Ko, 40 pistes, 8 secteurs par piste, double face');
     SecPerTrk:=8;
     NmHeads:=2;
    End
     Else
    If FileSize(FileSource)=184320 Then Begin
     WriteLn('Disquette 5 1/4", 180 Ko, 40 pistes, 9 secteurs par piste, simple face');
     SecPerTrk:=9;
     NmHeads:=1;
    End
     Else
    If FileSize(FileSource)=256256 Then Begin
      { Secteur = 128 octets }
     WriteLn('Disquette 8", 250 Ko, 77 pistes, 26 secteurs par piste, simple face');
     SecPerTrk:=26;
     NmHeads:=1;
    End
     Else
    If FileSize(FileSource)=368640 Then Begin
     WriteLn('Disquette 5 1/4", 360 Ko, 40 pistes, 9 secteurs par piste, double face');
     SecPerTrk:=9;
     NmHeads:=2;
    End
     Else
    If FileSize(FileSource)=512512 Then Begin
      { Secteur = 128 octets }
     WriteLn('Disquette 8", 500 Ko, 77 pistes, 26 secteurs par piste, double face');
     SecPerTrk:=26;
     NmHeads:=2;
    End
     Else
    If FileSize(FileSource)=737280 Then Begin
     { 1440 secteurs }
     WriteLn('Disquette 3 1/2", 720 Ko, 80 pistes, 9 secteurs par piste, double face');
     SecPerTrk:=9;
     NmHeads:=2;
    End
     Else
    If FileSize(FileSource)=1261568 Then Begin
      { Secteur = 1024 octets }
     WriteLn('Disquette 8", 1,2 Mo, 77 pistes, 26 secteurs par piste, double face');
     SecPerTrk:=26;
     NmHeads:=2;
    End
     Else
    If FileSize(FileSource)=1228800Then Begin
     { 2400 secteurs }
     WriteLn('Disquette 5 1/4", 1,2 Mo, 80 pistes, 15 secteurs par piste, double face');
     SecPerTrk:=15;
     NmHeads:=2;
    End
     Else
    If FileSize(FileSource)=1474560Then Begin
     { 2880 secteurs }
     WriteLn('Disquette 3 1/2", 1,44 Mo, 80 pistes, 18 secteurs par piste, double face');
     SecPerTrk:=18;
     NmHeads:=2;
    End
     Else
    If FileSize(FileSource)=1720320Then Begin
     WriteLn('Disquette 3 1/2", 1,68 Mo, 80 pistes, 21 secteurs par piste, double face');
     SecPerTrk:=21;
     NmHeads:=2;
    End
     Else
    If FileSize(FileSource)=1763328Then Begin
     WriteLn('Disquette 3 1/2", 1,72 Mo, 82 pistes, 21 secteurs par piste, double face');
     SecPerTrk:=21;
     NmHeads:=2;
    End
     Else
    If FileSize(FileSource)=2949120 Then Begin
     { 2880 secteurs }
     WriteLn('Disquette 3 1/2", 2,88 Mo, 80 pistes, 36 secteurs par piste, double face');
     SecPerTrk:=36;
     NmHeads:=2;
    End
     Else
    If FileSize(FileSource)=126222336 Then Begin
     WriteLn('Disquette LS-120, 120 Mo, 963 pistes, 32 secteurs par piste, 8 tˆtes');
     SecPerTrk:=32;
     NmHeads:=8;
    End
     Else
    If FileSize(FileSource)=240386048 Then Begin
     WriteLn('Disquette LS-240, 240 Mo, 262 pistes, 32 secteurs par piste, 56 tˆtes');
     SecPerTrk:=32;
     NmHeads:=56;
    End;
    {$I-}Assign(FileTarget,FileName2);
    Reset(FileTarget);{$I+}
    If IoResult<>0Then Begin
     Close(FileSource);
     WriteLn('Erreur de lecture du fichier destinataire !');
     Halt;
    End;
    BlockRead(FileSource,BufferSource,SizeOf(BufferSource),ByteReaded);
    If(BufferSource[0]=Byte('T'))and(BufferSource[1]=Byte('D'))Then Begin { Image TeleDisk? }
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
    If(BufferSource[0]=$AA)and(BufferSource[1]=$59)Then Begin { Fichier image IBM OS/2 }
     FileStart:=$29;
     WriteLn('Image IBM OS/2 detecter');
    End
     Else
    WriteLn('Image standard detecter');
    Seek(FileSource,FileStart);
    Seek(FileTarget,0);
    While Not EOF(FileSource)do Begin
     BlockRead(FileSource,BufferSource,SizeOf(BufferSource),ByteReaded);
     Inc(CurrPos,ByteReaded);
     If ByteReaded=0Then Break;
     BlockRead(FileTarget,BufferTarget,SizeOf(BufferTarget),ByteReaded);
     If ByteReaded=0Then Break;
     If Not(CompareBuffer)Then Begin
      WriteLn('Difference dans la comparaison');
      WriteLn('Position absolue ',CurrPos,', face ',CurrSide,
              ', piste ',CurrTrack,' secteur ',CurrSec);
      WriteLn;
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
    End;
    Close(FileTarget);
    Close(FileSource);
    If DiskIdentical Then Begin
     WriteLn;
     WriteLn('Disquette identique');
     WriteLn;
    End;
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