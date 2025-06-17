{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7)
}

Program VSAFE;

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

Procedure PCopy(Source,Target:Byte);Begin
 {$IFNDEF FPC}
  Move(Mem[SegB800:Source*(MemW[$0040:$4A]*25*2)],Mem[SegB800:Target*(MemW[$0040:$4A]*25*2)],MemW[$0040:$4A]*25*2)
 {$ENDIF}
End;

Function InstallEMS:Boolean;
Var
 Regs:Registers;
Begin
 Regs.AH:=$41;  { EMS - Demande l'ï¿½tat }
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
   ShowWarning('Tentative de formatage d‚tect‚ !');
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

Procedure Int21Handler(Flags,CS,IP,AX,BX,CX,DX,SI,DI,DS,ES,BP:Word);Interrupt;
Var
 Buffer: array[1..512] of Byte;
 VirusName: string;
Begin
 Case Hi(AX) of
  $31:If Options.TSRWarning Then Begin { TSR }
   WriteLn(#7'Attention: Le programmme tente de devenir r‚sident !');
  End;
  $3D:If Options.CheckPrograms and((Lo(AX) and 3) <> 0)Then Begin  { Ouverture de fichier }
   { Vï¿½rifier si c'est un fichier exï¿½cutable }
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
  { Installer en mï¿½moire ï¿½tendue si possible }
 If Not(UseEMS)and Not(UseXMS)Then Begin
  If(InstallXMS)Then UseXMS:=True Else
  If(InstallEMS)Then UseEMS := True;
 End;
  { Devenir rï¿½sident }
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
  Regs.AX := $4456;  { Notre identifiant VSAFE }
  Regs.BX := $FFFF;  { Fonction de dï¿½chargement }
  Intr($2F, Regs);
  UnloadVSafe := True;
  WriteLn('VSAFE dï¿½charger de la mï¿½moire');
 End
  Else
 WriteLn('VSAFE n''est pas chargï¿½');
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

  { Vï¿½rifier si VSAFE est dï¿½jï¿½ chargï¿½ }
 If IsVSafeLoaded Then Begin
  WriteLn('VSAFE est dï¿½ja chargï¿½');
  For i:=1 to ParamCount do Begin
   If StrToUpper(ParamStr(i))='/U'Then Begin
    UnloadVSafe;
    Exit;
   End;
  End;
  Exit;  { Si pas de /U, quitter car dï¿½jï¿½ chargï¿½ }
 End;

  { Initialiser les options }
 FillChar(Options, SizeOf(Options), 0);
 UseEMS:=True;
 UseXMS:=True;
 ChecksumEnabled:=True;
 NetworkEnabled:=False;
  { Analyser les paramï¿½tres }
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
 InitVirusDB;  { Initialiser la base de donnÃ©es de virus }
END.