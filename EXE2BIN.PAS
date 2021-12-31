{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program EXE2BIN;

Uses DOS;

Const
 BufferSize=65520;

Type
 HeadExeType=Record
  Signature:Word;
  LengthRem:Word;
  LengthPages:Word;
  NumReloc:Word;
  HeaderSize:Word;
  MinHeap:Word;
  MaxHeap:Word;
  ReloSS:Word;
  ExeSP:Word;
  CheckSum:Word;
  ExeIP:Word;
  ReloCS:Word;
  TablOff:Word;
  OverlayNum:Word;
 End;

Var
 Head:HeadExeType;
 Fexe,Fbin:File;
 ExeLN:LongInt;
 smx:Word;
 com2exe,ReAdrs:Boolean;
 exeFile,binFile:String;
 p:^Byte;
 L:LongInt;
 FOff,FSeg,i,dat2,Addres:Word;
 SSeek:LongInt;
 s:String[4];
 c:Array[1..4] of Byte;
 Ok:Boolean;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('EXE2BIN : Cette commande permet de convertir un fichier EXE en binaire (COM).');
  WriteLn;
  WriteLn('Syntaxe : EXE2BIN fichier.exe [fichier.bin]');
 End
  Else
 If ParamCount>0Then Begin
  Case ParamCount of
   1:Begin
    ExeFile:=ParamStr(1);
    If Pos('.',exeFile)<>0 Then	BinFile:=Copy(exeFile,1,Pos('.',exeFile))+'bin'
                           Else BinFile:=Concat(binFile+'.bin');
   End;
   2:Begin
    ExeFile:=ParamStr(1);
    BinFile:=ParamStr(2);
   End
   Else Begin
    WriteLn('Nombre de parametre invalide !');
    Halt;
   End;
  End;
  Assign(Fexe,ExeFile);
  {$I-}Reset(Fexe,1);{$I+}
  If IOresult<>0 Then Begin
   WriteLn('Fichier introuvable ou ne peut pas etre lue !');
   Halt;
  End;
  BlockRead(Fexe,Head,SizeOf(Head));
  If IOresult<>0 Then Begin
   WriteLn('Erreur de lecture de l''entree');
   Close(Fexe);
   Halt;
  End;
  With Head do Begin
   If (Signature<>23117) and (Signature<>19802) then Begin
    WriteLn('Signature du fichier EXE invalide !');
    Halt;
   End;
   com2exe:=false; ReAdrs:=False;
   If(ReloSS=$fff0) and (ReloCS=$fff0) and (ExeIP=$100)Then If(ExeSP=0)or(ExeSP=$fffe)Then com2exe:=true;
   If(ReloSS=0)and(ExeSP=0)and(ReloCS=0)and(ExeIP=0)Then If NumReloc<>0 Then ReAdrs:=true;
   If Not com2exe Then Begin
    If(ReloSS<>0)or(ExeSP<>0)or(ReloCS<>0)Then Begin
     WriteLn('Le fichier EXE ne peut pas etre convertie');
     Halt;
    End;
    If(ExeIP<>0)and(ExeIP<>$100)Then Begin
     WriteLn('L''adresse de debut du programme doit etre entre 000h et 100h');
     Halt;
    End;
   End;
   smx:=HeaderSize*16+ExeIp;
   ExeLN:=LongInt(LengthPages-1)*512+LengthRem;
   If ExeLN>65536 Then Begin
    WriteLn('Code de segment superieur a 65536 octets !');
    Halt;
   End;
   If com2exe Then Dec(smx,ExeIp)
  End;
  Assign(Fbin,binFile);
  {$I-}ReWrite(Fbin,1);{$I+}
  Seek(Fexe,smx);
  L:=ExeLN-smx;
  Repeat
   GetMem(p,BufferSize);
   If p=NIL Then Begin
    WriteLn('Manque de memoire');
    Halt;
   End;
   {$I-}BlockRead(Fexe,p^,BufferSize);{$I+}
   If IOresult<>0 Then Begin
    WriteLn('Erreur de lecture de l''entree');
    Halt;
   End;
   {$I-}BlockWrite(Fbin,p^,BufferSize);{$I+}
   if IOresult<>0 then Begin
    WriteLn('Impossible de creer la sortie !');
    Halt;
   End;
   FreeMem(p,BufferSize);
   Dec(L,BufferSize)
  Until L=0;
  If ReAdrs Then Begin
   Addres:=0;
   For i:=1 to 4 do c[i]:=0;
   Repeat
    Write('Segment auquel le fichier binaire sera charge (hexadecimal): ');
    ReadLn(s);
    Ok:=True;
    For i:=1 to Ord(s[0]) do Begin
     s[i]:=UpCase(s[i]);
     If Not(s[i] in ['0'..'9','A'..'F'])Then Begin
      Ok:=False;
      Break;
     End;
    End;
   Until (Length(s)<>0)and(Ok);
   For i:=1 to Length(s)do Begin
    s[i]:=UpCase(s[i]);
    If s[i] in ['0'..'9']Then c[4-Length(s)+i]:=Ord(s[i])-$30
                         Else c[4-Length(s)+i]:=Ord(s[i])-$37;
   End;
   For i:=1 to 4 do Addres:=Addres+c[i]*Round(Exp((4-i)*Ln(16)));
   {$I-}Seek(Fexe,Head.TablOff);{$I+}
   For i:=1 to Head.NumReloc do Begin
    {$I-}BlockRead(Fexe,FOff,2);
    BlockRead(Fexe,FSeg,2);{$I+}
    If IOresult<>0 Then Begin
     WriteLn('Erreur de lecture de l''entree');
     Halt;
    End;
    SSeek:=LongInt(FSeg)*16+FOff;
    If SSeek>=16*65536 Then Dec(SSeek,16*65536);
    {$I-}Seek(Fbin,SSeek);
    BlockRead(Fbin,dat2,2);{$I+}
    If IOresult<>0 Then Begin
     WriteLn('Erreur de lecture de l''entree');
     Halt;
    End;
    dat2:=dat2+Addres;
    {$I-}Seek(Fbin,SSeek);
    BlockWrite(Fbin,dat2,2);{$I+}
    If IOresult<>0 Then Begin
     WriteLn('Impossible d''ecrire le fichier');
     Halt;
    End;
   End;
  End;
  Close(Fexe);
  Close(Fbin);
 End
  Else
 WriteLn('Parametre manquant !');
END.