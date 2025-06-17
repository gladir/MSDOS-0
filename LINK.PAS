{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program LINK;

{$A-}

Uses DOS;

Const
 MAX_SEGMENTS=128;
 MAX_SYMBOLS=1024;
 MAX_RELOCATIONS=2048;

Type
 TExeHeader=Record
  Signature:Word;          { 'MZ' }
  LastPageBytes:Word;
  PageCount:Word;
  RelocCount:Word;
  HeaderSize:Word;
  MinAlloc:Word;
  MaxAlloc:Word;
  InitSS:Word;
  InitSP:Word;
  Checksum:Word;
  InitIP:Word;
  InitCS:Word;
  RelocOffset:Word;
  OverlayNumber:Word;
 End;

 TSegment=Record
  Name:String[16];
  Address:LongInt;
  Size:Word;
  Class:String[8];
 End;

 TSymbol=Record
  Name:String[32];
  Segment:Word;
  Offset:Word;
  IsExternal:Boolean;
 End;

 TRelocation=Record
  Segment:Word;
  Offset:Word;
  Target:Word;
 End;

Var
 ObjFile,ExeFile,MapFile:File;
 ExeHeader:TExeHeader;
 Segments:Array[1..MAX_SEGMENTS] of TSegment;
 Symbols:Array[1..MAX_SYMBOLS] of TSymbol;
 Relocations:Array[1..MAX_RELOCATIONS] of TRelocation;
 SegmentCount,SymbolCount,RelocationCount:Integer;
 StackSize:Word;
 ObjFileName,ExeFileName,MapFileName:String;  { Ajout des variables }
 i:Integer;
 Param:string;
 Buffer:Array[0..1023] of Byte;  { Ajout du tampon manquant }

Function ReadObjFile(Const FileName:String):Boolean;
Var
 RecType:Byte;
 RecLen:Word;
 Buffer:Array[0..1023] of Byte;
Begin
 ReadObjFile:=False;
 {$I-}Assign(ObjFile,FileName);
 Reset(ObjFile, 1);{$I+}
 If IOResult<>0 Then Exit;
 While Not Eof(ObjFile) do Begin
  BlockRead(ObjFile,RecType,1);
  BlockRead(ObjFile,RecLen,2);
  If RecLen>SizeOf(Buffer)Then Begin
   WriteLn('Erreur : RecLen sup‚rieur … la taille du tampon');
   Halt(10);
  End;
  BlockRead(ObjFile,Buffer,RecLen);
  Case RecType of
   $80:Begin { D‚finition de segment }
    Inc(SegmentCount);
    With Segments[SegmentCount] do Begin
     Name:='';
     Move(Buffer[0], Size, 2);
     Class:='CODE';
    End;
   End;
   $90:Begin { D‚finition publique }
    Inc(SymbolCount);
    With Symbols[SymbolCount] do Begin
     Name:='';
     Move(Buffer[0],Segment,2);
     Move(Buffer[2],Offset,2);
     IsExternal:=False;
    End;
   End;
   $9C:Begin { R‚f‚rence externe }
    Inc(SymbolCount);
    With Symbols[SymbolCount] do Begin
     Name:='';
     Segment:=0;
     Offset := 0;
     IsExternal:=True;
    End;
   End;
  End;
 End;
 Close(ObjFile);
 ReadObjFile:=True;
End;

Procedure GenerateExe(Const FileName:String);
Var
 i:Integer;
 CodeSize:LongInt;
 Buffer:Array[0..1023] of Byte;
Begin
  { Initialise l'entˆte EXE }
 FillChar(ExeHeader, SizeOf(ExeHeader), 0);
 With ExeHeader do Begin
  Signature:=$5A4D;  { 'MZ' }
  HeaderSize:=2;     { Dans les paragraphes de 16 octets }
  MinAlloc:=0;
  MaxAlloc:=$FFFF;
  InitSS:=0;
  InitSP:=StackSize;
  InitCS:=0;
  InitIP:=0;
  RelocOffset:=$1E;
 End;

  { Calcul du taille du code }
 CodeSize:=0;
 For i:=1 to SegmentCount do Inc(CodeSize,Segments[i].Size);
 ExeHeader.LastPageBytes:=CodeSize mod 512;
 ExeHeader.PageCount:=(CodeSize + 511) div 512;
 ExeHeader.RelocCount:=RelocationCount;

  { Ecrit un fichier EXE }
 Assign(ExeFile,FileName);
 Rewrite(ExeFile,1);
 BlockWrite(ExeFile,ExeHeader,SizeOf(ExeHeader));

  { crire la relocations }
 For i:=1 to RelocationCount do BlockWrite(ExeFile,Relocations[i],4);
  { Ecrit les segments de code }
 For i:=1 to SegmentCount do Begin
  { crit le segments de donn‚es - simplifi‚ }
  FillChar(Buffer, Segments[i].Size, 0);
  BlockWrite(ExeFile, Buffer, Segments[i].Size);
 End;
 Close(ExeFile);
End;

Function ChangeFileExt(Const FileName:String;Const NewExt:String):String;
Var
 i:Integer;
 BaseName:String;
Begin
 BaseName:=FileName;
 i:=Length(BaseName);
 While(i>0)and(BaseName[i]<>'.')and(BaseName[i]<>'\')and(BaseName[i]<>':')do Dec(i);
 If(i>0)and(BaseName[i]='.')Then BaseName:=Copy(BaseName, 1, i-1);
 ChangeFileExt:=BaseName+NewExt;
End;

Function StrToInt(Const S:String):Integer;
Var
 i:Integer;
 Negative:Boolean;
 Value:Integer;
Begin
 Value:=0;
 i:=1;
 Negative:=False;
  { Saute les espaces blancs }
 While(i<=Length(S))and(S[i] = ' ')do Inc(i);
  { V‚rifie pour les signes }
 If(i<=Length(S))Then Begin
  If S[i]='-'Then Begin
   Negative:=True;
   Inc(i);
  End
  Else If S[i]='+'Then Inc(i);
 End;

  { Convertie en chiffres }
 While(i<=Length(S))and(S[i]>='0')and(S[i]<='9')do Begin
  Value:=Value*10+(Ord(S[i])-Ord('0'));
  Inc(i);
 End;
 If(Negative)Then StrToInt:=-Value
             Else StrToInt:=Value;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('LINK : Cette commande permet de lancer le fabricant de liaison.');
  WriteLn;
  WriteLn('Syntaxe : LINK objfile[+objfile...][,[exefile][,[mapfile][,[libraries]]]] [options]');
  WriteLn;
  WriteLn('  /CP:n    - Fixe le maximum de paragraphes');
  WriteLn('  /STACK:n - Fixe la taille de la pile');
  WriteLn('  /MAP     - Gï¿½nï¿½ un fichier de cartographie (MAP)');
  Halt;
 End;
  { Initialise }
 SegmentCount:=0;
 SymbolCount:=0;
 RelocationCount:=0;
 StackSize:=2048;  { Taille de la pile par d‚faut }
  { Analyse de la ligne de commande }
 ObjFileName:=ParamStr(1);
 If ParamCount>1 Then ExeFileName:=ParamStr(2)
                 Else ExeFileName:=ChangeFileExt(ObjFileName, '.EXE');
  { Traitements des options de la ligne de commande }
 For i:=1 to ParamCount do Begin
  Param:=ParamStr(i);
  If(Length(Param)>1)and(Param[1]='/')Then Begin
   Case UpCase(Param[2]) of
    'S':If Copy(Param,1,7)='/STACK:'Then StackSize:=StrToInt(Copy(Param,8,255));
   End;
  End;
 End;
  { Processus de liaison }
 If ReadObjFile(ObjFileName)Then Begin
  GenerateExe(ExeFileName);
  WriteLn('Liaison compl‚t‚');
 End
  Else
 WriteLn('Erreur de lecture de fichier objet');
END.