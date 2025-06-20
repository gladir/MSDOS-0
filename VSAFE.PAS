{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7)
}

Program VSAFE;

{$M 16384,0,0}

Uses Crt,DOS;

Const
 PROGRAM_ID=$4456;  { 'VD' pour le pilote VSAFE }
 MAX_SIGNATURES=32;
 SIG_LENGTH=16;
 SCREEN_WIDTH = 80;
 SCREEN_HEIGHT = 25;
 POPUP_WIDTH = 60;
 POPUP_HEIGHT = 15;
 VIDEO_SEG = $B800;

 JerusalemSignature:Array[1..5]of Byte = ($B8, $21, $35, $CD, $21);
 StonedSignature:Array[1..5]of Byte = ($B4, $02, $B0, $03, $CD);
 MichelangeloSignature:Array[1..5]of Byte = ($FA, $B8, $C2, $34, $B1);

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

 TVirusSignature=Record
  Name:String[32];
  Signature:Array[1..SIG_LENGTH] of Byte;
  Offset:Word;
 End;

 TByteArray=Array[0..65520] of Byte;
 PByteArray=^TByteArray;

Var
 Options:TOptions;
 OldInt13h,OldInt21h:Pointer;
 UseEMS,UseXMS:Boolean;
 HotKeyAlt,HotKeyCtrl:Char;
 ChecksumEnabled:Boolean;
 NetworkEnabled:Boolean;
 i:Integer;
 Param:String;
 VirusDB:Array[1..MAX_SIGNATURES] of TVirusSignature;
 SignatureCount:Integer;
 ScreenX,ScreenY:Byte;

Procedure ShowPopup(Const Title:String;Const Message:String);Forward;
Procedure ShowWarning(Const Msg:String);Forward;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function CompareMem(Const P1,P2;Size:Word):Boolean;
Var
 B1: array[0..65520] of Byte absolute P1;
 B2: array[0..65520] of Byte absolute P2;
 i:Word;
Begin
 CompareMem:=True;
 For i:=0 to Size-1 do If B1[i]<>B2[i]Then Begin
  CompareMem:=False;
  Exit;
 End;
End;

Procedure PCopy(Source,Target:Byte);Begin
 {$IFNDEF FPC}
  Move(Mem[SegB800:Source*(MemW[$0040:$4A]*25*2)],Mem[SegB800:Target*(MemW[$0040:$4A]*25*2)],MemW[$0040:$4A]*25*2)
 {$ENDIF}
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
   { V‚rifier les tentatives de formatage }
  If (Hi(AX)=5)Then Begin { Formatage de piste }
   ShowWarning('Tentative de formatage d‚tect‚ !');
   If Not(NetworkEnabled)Then Begin
    Flags:=Flags or $0001;  { Fixe le drapeau de retenue }
    Exit;
   End;
  End;
 End;
  { Appeler le gestionnaire original }
 inline($9C);        { PUSHF }
 inline($FF/$1E/     { CALL DWORD PTR } OldInt13h);
End;

Function CheckExecutable(DS,SI:Word):Boolean;
Var
 FileName:String;
 i:Integer;
 Ext:String[3];
Begin
 CheckExecutable:=False;
  { Obtenir le nom du fichier }
 FileName:='';
 i:=0;
 While(Char(Mem[DS:SI+i])<>#0)and(i<64)do Begin
  FileName:=FileName+Char(Mem[DS:SI+i]);
  Inc(i);
 End;
  { Extraire l'extension }
 Ext:='';
 i:=Length(FileName);
 While(i>0)and(FileName[i]<>'.') do Dec(i);
 If i>0 Then Ext:=StrToUpper(Copy(FileName,i+1,3));
  { VÃ©rifier si c'est un exÃ©cutable }
 If(Ext='EXE')or(Ext='COM')or(Ext='SYS')Then Begin
  If(Options.ExeWarning)Then
   ShowWarning('Attention: AccŠs … un fichier ex‚cutable d‚tect‚ !'#13#10 + FileName);
  { V‚rifier les signatures de virus si activ‚ }
  If(Options.CheckPrograms)Then
   CheckExecutable:= True;  { Indique qu'il faut v‚rifier les signatures }
 End;
End;

Procedure Int21Handler(Flags, CS, IP, AX, BX, CX, DX, SI, DI, DS, ES, BP: Word);Interrupt;
Var
 CheckVirus:Boolean;
 Buffer:Array[1..512] of Byte;
 VirusName:String;
 RFile:File;
 SFile:FileRec Absolute RFile;
 BytesRead:Word;
Begin
 Case AX shr 8 of  { AH }
  $31:If Options.TSRWarning Then Begin { TSR }
   ShowPopup('Attention VSAFE', 'Le programme essai de devenir r‚sident !'#13#10+
             'Presse une touche pour continue...');
  End;
  $3D,$3F,$40:Begin  { Open, Read, Write }
   CheckVirus:=CheckExecutable(DS, SI);
   If(CheckVirus)Then Begin
    SFile.Handle:=AX and $FF;
     { Lire le dÃ©but du fichier }
    BlockRead(RFile,Buffer,SizeOf(Buffer),BytesRead);
     { VÃ©rifier les signatures connues }
    If CompareMem(Buffer[1],JerusalemSignature,5)Then
     ShowWarning('Virus Jerusalem d‚tect‚ dans un fichier !')
    Else If CompareMem(Buffer[32], StonedSignature, 5)Then
     ShowWarning('Virus Stoned d‚tect‚ dans un fichier !')
    Else If CompareMem(Buffer[128], MichelangeloSignature, 5)Then
     ShowWarning('Virus Michelangelo d‚tect‚ dans un fichier !');
    If IOResult<>0 Then;  { R‚initialise l'‚tat d'erreur }
   End;
  End;
 End;
  { Appeler le gestionnaire original }
 inline($9C);         { PUSHF }
 inline($FF/$1E/     { CALL DWORD PTR } OldInt21h);
End;

Procedure InstallVSafe;Begin
  { Sauvegarder les anciens vecteurs }
 GetIntVec($13,OldInt13h);
 GetIntVec($21,OldInt21h);
  { Installer nos gestionnaires }
 SetIntVec($13,@Int13Handler);
 SetIntVec($21,@Int21Handler);
  { Installer en m‚moire ‚tendue si possible }
 If Not(UseEMS)and Not(UseXMS)Then Begin
  If(InstallXMS)Then UseXMS:=True Else
  If(InstallEMS)Then UseEMS:=True;
 End;
  { Devenir r‚sident }
 Keep(0);
End;

Function IsVSafeLoaded:Boolean;
Var
 Regs:Registers;
Begin
 Regs.AX:=$4456;  { Notre identifiant VSAFE }
 Regs.BX:=$0000;  { Fonction de vï¿½rification }
 Intr($2F,Regs);   { Multiplexeur DOS }
 IsVSafeLoaded:=(Regs.BX=$4456);  { Si BX contient notre ID, VSAFE est chargï¿½ }
End;

Function UnloadVSafe:Boolean;
Var
 Regs:Registers;
Begin
 UnloadVSafe:=False;
 If IsVSafeLoaded Then Begin
  Regs.AX:=$4456;  { Notre identifiant VSAFE }
  Regs.BX:=$FFFF;  { Fonction de dï¿½chargement }
  Intr($2F,Regs);
  UnloadVSafe := True;
  WriteLn('VSAFE d‚charger de la m‚moire');
 End
  Else
 WriteLn('VSAFE n''est pas charg‚');
End;

Procedure InitVirusDB;Begin
 SignatureCount := 3;     { 3 signatures }
 With VirusDB[1]do Begin  { Jerusalem }
  Name:='Jerusalem';
  Signature[1] := $B8; Signature[2] := $21; Signature[3] := $35;
  Signature[4] := $CD; Signature[5] := $21;
  Offset := 0;
 End;
 With VirusDB[2] do Begin  { Stoned }
  Name:='Stoned';
  Signature[1] := $B4; Signature[2] := $02; Signature[3] := $B0;
  Signature[4] := $03; Signature[5] := $CD;
  Offset := 32;
 End;
 With VirusDB[3] do Begin  { Brain }
  Name:='Brain';
  Signature[1] := $FA; Signature[2] := $B8; Signature[3] := $C2;
  Signature[4] := $34; Signature[5] := $B1;
  Offset := 0;
 End;
End;

Function CheckVirusSignature(Var Buffer;Size:Word):String;
Var
 i,j:Integer;
 Match:Boolean;
 BufPtr:PByteArray;
Begin
 CheckVirusSignature:='';
 BufPtr:=@Buffer;
 For i:=1 to SignatureCount do With VirusDB[i] do Begin
  If Size<(Offset + SIG_LENGTH)Then Continue;
  Match:=True;
  For j:=1 to SIG_LENGTH do If BufPtr^[Offset+j-1]<>Signature[j]Then Begin
   Match := False;
   Break;
  End;
  If Match Then Begin
   CheckVirusSignature:=Name;
   Exit;
  End;
 End;
End;

Procedure SaveCursor;
Var
 Regs:Registers;
Begin
 Regs.AH:=3;
 Regs.BH:=0;
 Intr($10,Regs);
 ScreenX:=Regs.DL;
 ScreenY:=Regs.DH;
End;

Procedure RestoreCursor;
Var
 Regs:Registers;
Begin
 Regs.AH:=2;
 Regs.BH:=0;
 Regs.DL:=ScreenX;
 Regs.DH:=ScreenY;
 Intr($10,Regs);
End;

Procedure SaveScreenArea;Begin
 PCopy(0,1);
End;

Procedure RestoreScreenArea;Begin
 PCopy(1,0);
End;

Function StringOfChar(Ch:Char;Count:Integer):String;
Var
 i:Integer;
 R:String;
Begin
 R[0]:=Chr(Count);
 For i:=1 to Count do R[i]:=Ch;
 StringOfChar:=R;
End;

Procedure ShowPopup(Const Title:String;Const Message:String);
Var
 i,StartX,StartY:Integer;
 Attr:Byte;
Begin
 SaveCursor;
 SaveScreenArea;
 StartX:=(SCREEN_WIDTH-POPUP_WIDTH) div 2;
 StartY:=(SCREEN_HEIGHT-POPUP_HEIGHT) div 2;
 Attr:=$70;  { Blanc sur noir }
  { Dessiner le cadre avec des caractÃ¨res simples }
 For i:=StartY to StartY + POPUP_HEIGHT do Begin
  GotoXY(StartX,i);
  TextAttr:=Attr;
  If i=StartY Then
   Write('+', StringOfChar(#196, POPUP_WIDTH-2), '+')
  Else If i = StartY + POPUP_HEIGHT then
   Write('+', StringOfChar(#196, POPUP_WIDTH-2), '+')
  Else
   Write('|', StringOfChar(' ', POPUP_WIDTH-2), '|');
 End;
  { Afficher le titre }
 GotoXY(StartX + (POPUP_WIDTH - Length(Title)) div 2, StartY);
 Write(Title);
  { Afficher le message }
 GotoXY(StartX+2,StartY+2);
 Write(Message);
  { Attendre une touche }
 ReadKey;
 RestoreScreenArea;
 RestoreCursor;
End;

Procedure ShowWarning(Const Msg:String);Begin
 ShowPopup('Attention VSAFE ', Msg);
End;

BEGIN
 If ParamCount=0 Then Begin
  WriteLn('VSAFE - Cette commande permet de g‚rer la protection virus');
  WriteLn;
  WriteLn('Syntaxe : VSAFE [/option[+ | -] ...] [/NE] [/NX] [/Ax | /Cx] [/N] [/D] [/U]');
  WriteLn;
  WriteLn('Options:');
  WriteLn('  1  Attention au formatage');
  WriteLn('  2  Attention au TSR');
  WriteLn('  3  Protection contre l''‚criture');
  WriteLn('  4  V‚rifie le programme');
  WriteLn('  5  V‚rifie le secteur de d‚marrage');
  WriteLn('  6  Attention … la partition et l''‚criture du secteur de d‚marrage');
  WriteLn('  7  Atterntion … l''‚criture du secteur de d‚marrage');
  WriteLn('  8  Attention au ‚criture de fichier ex‚cutable');
  Halt;
 End;

  { Vï¿½rifier si VSAFE est dï¿½jï¿½ chargï¿½ }
 If IsVSafeLoaded Then Begin
  WriteLn('VSAFE est d‚j… charg‚');
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
 InitVirusDB;  { Initialiser la base de donn‚es de virus }
END.
