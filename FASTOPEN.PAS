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
 DEFAULT_ENTRIES=24;
 ENTRY_SIZE=32;  { Taille d'une entr‚e de r‚pertoire DOS }

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

Var
 DriveCache:Array[0..MAX_DRIVES-1] of TDriveCache;
 UseXMS:Boolean;
 OldInt21:Pointer;
 i: Integer;
 Param: string;
 Drive: Char;
 Entries: Word;
 _Pos: Integer;
 Err:Word;

Procedure InitCache(Drive:Char;_Entries:Word);
Var
 DriveIndex:Integer;
Begin
 DriveIndex := Ord(UpCase(Drive))-Ord('A');
 If(DriveIndex >= 0)and(DriveIndex<MAX_DRIVES)Then
 With DriveCache[DriveIndex] do Begin
  Drive:=UpCase(Drive);
  MaxEntries:=_Entries;
  CurrentEntries:=0;
  FillChar(Entries,SizeOf(Entries),0);
 End;
End;

Procedure InstallHandler;Interrupt;
Var
 Regs:Registers;
Begin
 If Regs.AH=$0F Then Begin
  { V‚rifier si le fichier est dans le cache }
  { et retourner les informations si trouvÃ© }
 End
  Else
  { Appeler le gestionnaire original }
 Inline($9C);       { PUSHF }
 Inline($FF/$1E/     { CALL DWORD PTR } OldInt21);
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
 Regs.DX:=(Ofs(InstallHandler) + 15) shr 4;  { Paragraphes … converv‚ }
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
  WriteLn('  drive: Lettre d''unit‚ … cache');
  WriteLn('  n      Nombre d''entr‚es (par d‚faut 24)');
  WriteLn('  /X     Utilise la m‚moire ‚tendue');
  Halt;
 End;
 UseXMS:=False;
  { Analyse les paramŠtres }
 For i:=1 to ParamCount do Begin
  Param:=ParamStr(i);
  If(Param='/X')or(Param='/x')Then UseXMS:=True Else
  if (Length(Param)>=2)and(Param[2]=':')Then Begin
   Drive:=UpCase(Param[1]);
   Entries:=DEFAULT_ENTRIES;
    { V‚rifier s'il y a un nombre d'entr‚es sp‚cifi‚ }
   _Pos := Pos('=',Param);
   If _Pos>0 Then Val(Copy(Param,_Pos+1,Length(Param)),Entries,Err);
   InitCache(Drive, Entries);
  End;
 End;
  { Installer le gestionnaire }
 If(InstallFastOpen)Then WriteLn('FASTOPEN install‚ avec succŠs')
                    Else WriteLn('Erreur d''installation deFASTOPEN');
END.