{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7)
}

Program FASTOPEN;

{$A-}
{$M 16384,0,0}

Uses DOS;

Const
 MAX_DRIVES=26;
 DEFAULT_ENTRIES=22;      { 26 lecteurs x 22 entrees : tient dans le segment de donnees de 64 Ko avec les donnees internes de TPC }
 ENTRY_SIZE=32;  { Taille d'une entr‚e de r‚pertoire DOS }
  { XMS }
 XMS_INT = $2F;
 XMS_FUNCTION = $4310;
 XMS_ALLOCATE = $09;
 XMS_FREE = $0A;
 XMS_MOVE = $0B;

Type
 TDirEntry=Record
  Name:Array[1..8] of Char;
  Ext:Array[1..3] of Char;
  Attr:Byte;
  Reserved:Array[1..10] of Byte;
  Time:Word;
  Date:Word;
  StartCluster:Word;
  Size:LongInt;
 End;

 TCacheEntry=Record
  Drive:Byte;
  Path:String[64];
  DirEntry:TDirEntry;
  LastAccess:LongInt;
 End;

 TDriveCache=Record
  Drive:Char;
  MaxEntries:Word;
  CurrentEntries:Word;
  Entries:Array[1..DEFAULT_ENTRIES] of TCacheEntry;
 End;

 TXMSDriver = record
  Length: Word;
  SourceHandle: Word;
  SourceOffset: LongInt;
  DestHandle: Word;
  DestOffset: LongInt;
 End;

Var
 DriveCache:Array[0..MAX_DRIVES-1] of TDriveCache;
 UseXMS:Boolean;
 OldInt21:Pointer;
 i: Integer;
 Param: string;
 Drive:Char;
 Entries:Word;
 _Pos:Integer;
 Err:Word;
 XMSDriver:Pointer;
 XMSHandle:Word;
 XMSAvailable:Boolean;

Function XMSInstalled:Boolean;
Var
 Regs:Registers;
Begin
 Regs.AX:=XMS_FUNCTION;
 Intr(XMS_INT,Regs);
 XMSDriver:=Ptr(Regs.ES,Regs.BX);
 XMSInstalled:=(Regs.AX=1)and(XMSDriver<>NIL);
End;

Function XMSAllocate(Size:Word):Word;
Var
 Regs:Registers;
Begin
 Regs.AH:=XMS_ALLOCATE;
 Regs.DX:=Size;
 ASM
  push es
  push bx
  les bx, XMSDriver
  call dword ptr es:[bx]
  pop bx
  pop es
 END;
 If Regs.AX=1 Then XMSAllocate:=Regs.DX
              Else XMSAllocate:=0;
End;

Procedure InitCache(Drive:Char;_Entries:Word);
Var
 DriveIndex:Integer;
 MemSize: Word;
Begin
 DriveIndex := Ord(UpCase(Drive))-Ord('A');
 If(DriveIndex >= 0)and(DriveIndex<MAX_DRIVES)Then
 With DriveCache[DriveIndex] do Begin
  Drive:=UpCase(Drive);
  MaxEntries:=_Entries;
  CurrentEntries:=0;
  If(UseXMS)and(XMSAvailable)Then Begin
    { Allouer la mï¿½moire XMS pour ce lecteur }
   MemSize:=(_Entries * SizeOf(TCacheEntry)) div 1024 + 1;
   XMSHandle:=XMSAllocate(MemSize);
   If XMSHandle=0 Then UseXMS:=False; { Retour … la m‚moire conventionnelle }
  End;
  If Not(UseXMS)Then FillChar(Entries,SizeOf(Entries),0);
 End;
End;

Procedure InstallHandler(Flags,rCS,rIP,rAX,rBX,rCX,rDX,rSI,rDI,rDS,rES,rBP:Word);Interrupt;
Var
 DriveIndex: Integer;
 FileName: string;
 i: Integer;
 Found: Boolean;
 Old: Pointer;
Begin
 Found:=False;
 If Hi(rAX)=$0F Then Begin
  DriveIndex := Ord(Char(Lo(rDX))) - Ord('A');
  If(DriveIndex>=0)and(DriveIndex<MAX_DRIVES)Then Begin
    { Construire le nom du fichier a partir des registres }
   FileName := '';
   For i:=0 to 7 do FileName:=FileName+Char(Mem[rDS:rSI+i]);
   With DriveCache[DriveIndex] do Begin
    { Chercher dans le cache }
    For i := 1 to CurrentEntries do Begin
     If Entries[i].Path+Entries[i].DirEntry.Name = FileName Then Begin
      { Trouve - copier les informations dans les registres }
      rAX := 0;  { Succes }
      Move(Entries[i].DirEntry, Mem[rES:rDI], SizeOf(TDirEntry));
      Entries[i].LastAccess := MemL[$40:$6C];  { Compteur de tic de minuterie }
      Found:=True;
      Break;
     End;
    End;
   End;
  End;
 End;
 If Found Then Flags:=Flags And $FFFE
  Else
 Begin
  { Appeler le gestionnaire original }
  Old:=OldInt21;
  Asm
   MOV AX,rAX
   MOV BX,rBX
   MOV CX,rCX
   MOV DX,rDX
   MOV SI,rSI
   MOV DI,rDI
   MOV ES,rES
   PUSH rDS
   POP DS
   PUSH Flags
   CALL DWORD PTR Old
   MOV rAX,AX
   MOV rBX,BX
   MOV rCX,CX
   MOV rDX,DX
   MOV rSI,SI
   MOV rDI,DI
   MOV rES,ES
   MOV rDS,DS
   PUSHF
   POP Flags
  End;
 End;
End;

Function InstallFastOpen:Boolean;
Var
 Regs:Registers;
Begin
 InstallFastOpen:=False;
  { Sauvegarder l'ancien vecteur d'interruption }
 GetIntVec($21, OldInt21);
  { Installer notre gestionnaire }
 SetIntVec($21, @InstallHandler);
  { Initialiser le TSR }
 Regs.AH:=$31;           { Fonction TSR }
 Regs.AL:=0;             { Code de sortie }
 Regs.DX:=SSeg+$400-PrefixSeg;  { paragraphes conserves : du PSP a la fin de la pile (code, donnees et pile) }
 Intr($21,Regs);
 InstallFastOpen:=True;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('FASTOPEN - Cette commande permet d''acc‚l‚rer les accŠs fichiers.');
  WriteLn;
  WriteLn('Syntaxe : FASTOPEN drive:[=n] [drive:[n]...] [/X]');
  WriteLn;
  WriteLn('  drive: Lettre d''unit‚ en cache');
  WriteLn('  n      Nombre d''entr‚es (par d‚faut 24)');
  WriteLn('  /X     Utilise la m‚moire ‚tendue');
  Halt;
 End;
 UseXMS:=False;
 XMSAvailable := False;
  { Vï¿½rifier si XMS est disponible }
 If(XMSInstalled)Then XMSAvailable:=True;
  { Analyse les paramï¿½tres }
 For i:=1 to ParamCount do Begin
  Param:=ParamStr(i);
  If(Param='/X')or(Param='/x')Then UseXMS:=True Else
  if (Length(Param)>=2)and(Param[2]=':')Then Begin
   Drive:=UpCase(Param[1]);
   Entries:=DEFAULT_ENTRIES;
    { Vï¿½rifier s'il y a un nombre d'entrï¿½es spï¿½cifiï¿½ }
   _Pos := Pos('=',Param);
   If _Pos>0 Then Val(Copy(Param,_Pos+1,Length(Param)),Entries,Err);
   InitCache(Drive, Entries);
  End;
 End;
  { Installer le gestionnaire }
 If(InstallFastOpen)Then WriteLn('FASTOPEN install‚ avec succŠs')
                    Else WriteLn('Erreur d''installation de FASTOPEN');
END.
