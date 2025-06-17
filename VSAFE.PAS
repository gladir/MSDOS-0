{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7)
}

Program VSAFE;

Uses DOS;

Const
 PROGRAM_ID=$4456;  { 'VD' pour le pilote VSAFE }

Type
 TOptions=Record
  FormatWarning:Boolean;     { Option 1 }
  TSRWarning:Boolean;        { Option 2 }
  DiskWriteProtect:Boolean;  { Option 3 }
  CheckPrograms:Boolean;     { Option 4 }
  CheckBootSector:Boolean;   { Option 5 }
  PartitionWarning:Boolean;  { Option 6 }
  BootWarning:Boolean;       { Option 7 }
  ExeWarning:Boolean;        { Option 8 }
 End;

 TMemoryType=(mtConventional,mtEMS,mtXMS);

Var
 Options:TOptions;
 OldInt13h,OldInt21h:Pointer;
 UseEMS,UseXMS:Boolean;
 HotKeyAlt,HotKeyCtrl:Char;
 ChecksumEnabled:Boolean;
 NetworkEnabled:Boolean;
 i:Integer;
 Param:String;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function InstallEMS:Boolean;
Var
 Regs:Registers;
Begin
 Regs.AH:=$41;  { EMS - Demande l'‚tat }
 Intr($67,Regs);
 InstallEMS:=(Regs.AH=0);
End;

Function InstallXMS:Boolean;
Var
 Regs:Registers;
Begin
 Regs.AX:=$4300;  { XMS - Demande la version }
 Intr($2F,Regs);
 InstallXMS:=(Regs.AL=$80);
End;

Procedure Int13Handler(Flags,CS,IP,AX,BX,CX,DX,SI,DI,DS,ES,BP:Word);Interrupt;Begin
 If(Options.FormatWarning)Then Begin
   { Vï¿½rifier les tentatives de formatage }
  If (Hi(AX)=5)Then Begin { Formatage de piste }
   WriteLn(#7'Attention: Tentative de formatage d‚tect‚!');
   If Not(NetworkEnabled)Then Begin
    Flags:=Flags or $0001;  { Fixe le drapeau de retenue }
    Exit;
   End;
  End;
 End;

  { Appeler le gestionnaire original }
 inline($9C);         { PUSHF }
 inline($FF/$1E/     { CALL DWORD PTR } OldInt13h);
End;

Procedure Int21Handler(Flags,CS,IP,AX,BX,CX,DX,SI,DI,DS,ES,BP:Word);Interrupt;Begin
 Case Hi(AX) of
  $31:If Options.TSRWarning Then Begin { TSR }
   WriteLn(#7'Warning: Program attempting to go resident!');
  End;
  $3D:If Options.CheckPrograms and((Lo(AX) and 3) <> 0)Then Begin  { Ouverture de fichier }
   { V‚rifier si c'est un fichier ex‚cutable }
  End;
 End;
  { Appeler le gestionnaire original }
 inline($9C);         { PUSHF }
 inline($FF/$1E/     { CALL DWORD PTR } OldInt21h);
End;

Procedure InstallVSafe;Begin
  { Sauvegarder les anciens vecteurs }
 GetIntVec($13, OldInt13h);
 GetIntVec($21, OldInt21h);
  { Installer nos gestionnaires }
 SetIntVec($13, @Int13Handler);
 SetIntVec($21, @Int21Handler);
  { Installer en m‚moire ‚tendue si possible }
 If Not(UseEMS)and Not(UseXMS)Then Begin
  If(InstallXMS)Then UseXMS:=True Else
  If(InstallEMS)Then UseEMS := True;
 End;
  { Devenir r‚sident }
 Keep(0);
End;

Function IsVSafeLoaded:Boolean;
Var
 Regs:Registers;
Begin
 Regs.AX:=$4456;  { Notre identifiant VSAFE }
 Regs.BX:=$0000;  { Fonction de v‚rification }
 Intr($2F,Regs);   { Multiplexeur DOS }
 IsVSafeLoaded:=(Regs.BX=$4456);  { Si BX contient notre ID, VSAFE est charg‚ }
End;

Function UnloadVSafe:Boolean;
Var
 Regs:Registers;
Begin
 UnloadVSafe:=False;
 If IsVSafeLoaded Then Begin
  Regs.AX := $4456;  { Notre identifiant VSAFE }
  Regs.BX := $FFFF;  { Fonction de d‚chargement }
  Intr($2F, Regs);
  UnloadVSafe := True;
  WriteLn('VSAFE d‚charger de la m‚moire');
 End
  Else
 WriteLn('VSAFE n''est pas charg‚');
End;

BEGIN
 If ParamCount=0 Then Begin
  WriteLn('VSAFE - Cette commande permet de gï¿½rer la protection virus');
  WriteLn;
  WriteLn('Syntaxe : VSAFE [/option[+ | -] ...] [/NE] [/NX] [/Ax | /Cx] [/N] [/D] [/U]');
  WriteLn;
  WriteLn('Options:');
  WriteLn('  1  Attention au formatage');
  WriteLn('  2  Attention au TSR');
  WriteLn('  3  Protection contre l''ï¿½criture');
  WriteLn('  4  Vï¿½rifie le programme');
  WriteLn('  5  Vï¿½rifie le secteur de dï¿½marrage');
  WriteLn('  6  Attention ï¿½ la partition et l''ï¿½criture du secteur de dï¿½marrage');
  WriteLn('  7  Atterntion ï¿½ l''ï¿½criture du secteur de dï¿½marrage');
  WriteLn('  8  Attention au ï¿½criture de fichier exï¿½cutable');
  Halt;
 End;

  { V‚rifier si VSAFE est d‚j… charg‚ }
 If IsVSafeLoaded Then Begin
  WriteLn('VSAFE est d‚ja charg‚');
  For i:=1 to ParamCount do Begin
   If StrToUpper(ParamStr(i))='/U'Then Begin
    UnloadVSafe;
    Exit;
   End;
  End;
  Exit;  { Si pas de /U, quitter car d‚j… charg‚ }
 End;

  { Initialiser les options }
 FillChar(Options, SizeOf(Options), 0);
 UseEMS:=True;
 UseXMS:=True;
 ChecksumEnabled:=True;
 NetworkEnabled:=False;
  { Analyser les paramŠtres }
 For i:=1 to ParamCount do Begin
   Param := StrToUpper(ParamStr(i));
   If Param[1]='/'Then Case Param[2] of
    'U':Begin
     UnloadVSafe;
     Exit;
    End;
    'N':Case Length(Param) of
     2:NetworkEnabled := True;
     3:If Param[3]='E'Then UseEMS:=False Else
       If Param[3]='X'Then UseXMS:=False;
    End;
    'D': ChecksumEnabled:=False;
    'A': If Length(Param)=3 Then HotKeyAlt:=Param[3];
    'C': If Length(Param)=3 Then HotKeyCtrl:=Param[3];
    '1'..'8':Begin
     Case Param[2] of
      '1': Options.FormatWarning := True;
      '2': Options.TSRWarning := True;
      '3': Options.DiskWriteProtect := True;
      '4': Options.CheckPrograms := True;
      '5': Options.CheckBootSector := True;
      '6': Options.PartitionWarning := True;
      '7': Options.BootWarning := True;
      '8': Options.ExeWarning := True;
      End;
      If(Length(Param)>2)and(Param[3]='-')Then Case Param[2] of
       '1': Options.FormatWarning := False;
       '2': Options.TSRWarning := False;
       '3': Options.DiskWriteProtect := False;
       '4': Options.CheckPrograms := False;
       '5': Options.CheckBootSector := False;
       '6': Options.PartitionWarning := False;
       '7': Options.BootWarning := False;
       '8': Options.ExeWarning := False;
      End;
     End;
  End;
 End;
  { Installer VSafe }
 If Not(IsVSafeLoaded)Then InstallVSafe;
END.
