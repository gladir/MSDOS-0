{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program MSMOUSE;

{$M 16384,0,65535}
{$A-}

Uses DOS;

Const
 { Version du pilote souris - Compatible Microsoft Mouse Driver }
 MOUSE_DRIVER_VERSION = $0806;  { Version 8.06 - Format: version majeure.mineure }

 { Codes d'erreur pour les opÇrations souris }
 ERR_SUCCESS = 0;               { OpÇration rÇussie }
 ERR_INVALID_FUNCTION = 1;      { Fonction non supportÇe }
 ERR_NO_MOUSE = 2;              { Aucune souris dÇtectÇe }
 ERR_DRIVER_NOT_INSTALLED = 3;  { Pilote non installÇ }
 ERR_INVALID_PARAMETER = 4;     { Paramätre invalide }

 { Interruption logicielle souris - Standard MS-DOS }
 MOUSE_INT = $33;               { INT 33h - Interface standard souris }

 { Ports sÇrie pour souris s√©rie Microsoft/compatibles }
 COM1_BASE = $3F8;              { Port sÇrie COM1 - Adresse de base }
 COM2_BASE = $2F8;              { Port sÇrie COM2 - Adresse de base }
 COM3_BASE = $3E8;              { Port sÇrie COM3 - Adresse de base }
 COM4_BASE = $2E8;              { Port sÇrie COM4 - Adresse de base }

 { Ports PS/2 pour souris PS/2 (contrìleur clavier 8042) }
 PS2_DATA_PORT = $60;           { Port de donnÇes PS/2 }
 PS2_STATUS_PORT = $64;         { Port de statut PS/2 (lecture) }
 PS2_COMMAND_PORT = $64;        { Port de commande PS/2 (Çcriture) }

 { NumÇros IRQ pour interruptions matÇrielles souris }
 PS2_IRQ = 12;                  { IRQ 12 - Souris PS/2 (PIC esclave) }
 COM1_IRQ = 4;                  { IRQ 4 - Port sÇrie COM1 }
 COM2_IRQ = 3;                  { IRQ 3 - Port sÇrie COM2 }

 { Types de souris supportÇs par le pilote }
 MOUSE_TYPE_NONE = 0;           { Aucune souris dÇtectÇe }
 MOUSE_TYPE_SERIAL = 1;         { Souris sÇrie (COM1-COM4) }
 MOUSE_TYPE_PS2 = 2;            { Souris PS/2 (port auxiliaire) }
 MOUSE_TYPE_BUS = 3;            { Souris bus (IBM PC/InPort) }

 { Masques de bits pour l'Çtat des boutons souris }
 BUTTON_LEFT = 1;               { Bit 0 - Bouton gauche }
 BUTTON_RIGHT = 2;              { Bit 1 - Bouton droit }
 BUTTON_MIDDLE = 4;             { Bit 2 - Bouton central }

 { Limites par dÇfaut de la zone de travail souris }
 DEFAULT_MIN_X = 0;              { CoordonnÇe X minimale }
 DEFAULT_MAX_X = 639;            { CoordonnÇe X maximale (mode 640x200) }
 DEFAULT_MIN_Y = 0;              { CoordonnÇe Y minimale }
 DEFAULT_MAX_Y = 199;            { CoordonnÇe Y maximale (mode 640x200) }

Type
 { Structure d'Çtat de la souris }
 TMouseState = Record
  X, Y: Integer;                 { Position actuelle }
  Buttons: Byte;                 { êtat des boutons }
  DeltaX, DeltaY: Integer;       { DÇplacement depuis derniäre lecture }
  Visible: Boolean;              { Curseur visible }
  MinX, MaxX: Integer;           { Limites horizontales }
  MinY, MaxY: Integer;           { Limites verticales }
  MickeyX, MickeyY: Integer;     { SensibilitÇ }
  DoubleSpeedThreshold: Integer; { Seuil de vitesse double }
 End;

  { Structure de contrìle du pilote TSR }
 TMouseDriver = Record
  Installed: Boolean;            { Pilote installÇ }
  MouseType: Byte;               { Type de souris dÇtectÇ }
  SerialPort: Word;              { Port sÇrie (si souris sÇrie) }
  SerialIRQ: Byte;               { IRQ sÇrie }
  State: TMouseState;            { êtat de la souris }
  UserHandler: Pointer;          { Gestionnaire utilisateur }
  CallMask: Word;                { Masque d'appel utilisateur }
  OldInt33Handler: Pointer;      { Ancien gestionnaire INT 33h }
  OldSerialHandler: Pointer;     { Ancien gestionnaire IRQ sÇrie }
  OldPS2Handler: Pointer;        { Ancien gestionnaire IRQ PS/2 }
  InitializedHardware: Boolean;  { MatÇriel initialisÇ }
  SilentMode: Boolean;           { Mode silencieux }
 End;

Var
 Language:(_French,_English,_Germany,_Italian,_Spain,_Albanian,_Portuguese,_Swedish,_Danish,_Japanese);
 TmpLanguage: String;
 MouseDriver: TMouseDriver;
 I: Byte;
 Param: String;

 { Convertir une chaåne en majuscules }
Function StrToUpper(S: String): String;
Var
 I: Byte;
Begin
 For I := 1 to Length(S) do Begin
  If S[I] in ['a'..'z'] Then S[I] := Chr(Ord(S[I]) - 32);
 End;
 StrToUpper := S;
End;

 { Lire un byte d'un port }
Function PortReadByte(Port: Word): Byte;
{$IFDEF FPC}
Begin
 PortReadByte := 0; { Simulation pour Free Pascal }
End;
{$ELSE}
Begin
 Asm
  Mov DX, Port
  In AL, DX
  Mov @Result, AL
 End;
End;
{$ENDIF}

{ êcrire un byte dans un port }
Procedure PortWriteByte(Port: Word; Value: Byte);
{$IFDEF FPC}
Begin
 { Simulation pour Free Pascal - pas d'accäs direct aux ports }
End;
{$ELSE}
Begin
 Asm
  Mov DX, Port
  Mov AL, Value
  Out DX, AL
 End;
End;
{$ENDIF}

 { DÇtecter une souris sÇrie sur un port COM }
Function DetectSerialMouse(ComPort: Word): Boolean;
{$IFDEF FPC}
Begin
 DetectSerialMouse := False; { Simulation pour Free Pascal }
End;
{$ELSE}
Var
 OldValue, TestValue: Byte;
Begin
 DetectSerialMouse := False;
  { Test de prÇsence du port sÇrie }
 OldValue := PortReadByte(ComPort + 4); { Registre de contrìle modem }
 PortWriteByte(ComPort + 4, $10);       { RTS on, DTR off }
 TestValue := PortReadByte(ComPort + 6); { Registre d'Çtat modem }

 If (TestValue And $10) = 0 Then Begin { CTS devrait àtre off }
  PortWriteByte(ComPort + 4, $11);     { RTS on, DTR on }
  TestValue := PortReadByte(ComPort + 6);
  If (TestValue And $20) <> 0 Then Begin { DSR devrait àtre on }
   { Initialisation basique de la souris sÇrie }
   PortWriteByte(ComPort + 3, $80);    { DLAB = 1 }
   PortWriteByte(ComPort + 0, $60);    { 1200 baud }
   PortWriteByte(ComPort + 1, $00);
   PortWriteByte(ComPort + 3, $02);    { 7 bits, no parity, 1 stop }
   PortWriteByte(ComPort + 4, $03);    { DTR et RTS on }
   PortWriteByte(ComPort + 1, $00);    { Pas d'interruptions }
   DetectSerialMouse := True;
  End;
 End;
 PortWriteByte(ComPort + 4, OldValue); { Restaurer l'ancien Çtat }
End;
{$ENDIF}

{ DÇtecter une souris PS/2 }
Function DetectPS2Mouse: Boolean;
{$IFDEF FPC}
Begin
 DetectPS2Mouse := False; { Simulation pour Free Pascal }
End;
{$ELSE}
Var
 Status: Byte;
Begin
 DetectPS2Mouse := False;
  { VÇrifier si le contrìleur PS/2 existe }
 Status := PortReadByte(PS2_STATUS_PORT);
 If (Status And $02) = 0 Then Begin { Tampon d'entrÇe vide }
  { Envoyer commande de test du port souris }
  PortWriteByte(PS2_COMMAND_PORT, $A9);
   { Attendre la rÇponse }
  Repeat
   Status := PortReadByte(PS2_STATUS_PORT);
  Until (Status And $01) <> 0;
   { Lire le rÇsultat }
  Status := PortReadByte(PS2_DATA_PORT);
  If Status = $00 Then Begin { Test rÇussi }
   DetectPS2Mouse := True;
  End;
 End;
End;
{$ENDIF}

{ DÇtecter le type de souris prÇsent }
Function DetectMouseType: Byte;Begin
 DetectMouseType := MOUSE_TYPE_NONE;
  { Essayer de dÇtecter une souris PS/2 en premier }
 If DetectPS2Mouse Then Begin
  DetectMouseType := MOUSE_TYPE_PS2;
  Exit;
 End;
  { Essayer les ports sÇrie }
 If DetectSerialMouse(COM1_BASE) Then Begin
  DetectMouseType := MOUSE_TYPE_SERIAL;
  MouseDriver.SerialPort := COM1_BASE;
  MouseDriver.SerialIRQ := COM1_IRQ;
  Exit;
 End;
 If DetectSerialMouse(COM2_BASE) Then Begin
  DetectMouseType := MOUSE_TYPE_SERIAL;
  MouseDriver.SerialPort := COM2_BASE;
  MouseDriver.SerialIRQ := COM2_IRQ;
  Exit;
 End;
End;

{ Initialiser l'Çtat de la souris }
Procedure InitMouseState;Begin
 With MouseDriver.State Do Begin
  X := (DEFAULT_MAX_X + DEFAULT_MIN_X) Div 2;
  Y := (DEFAULT_MAX_Y + DEFAULT_MIN_Y) Div 2;
  Buttons := 0;
  DeltaX := 0;
  DeltaY := 0;
  Visible := False;
  MinX := DEFAULT_MIN_X;
  MaxX := DEFAULT_MAX_X;
  MinY := DEFAULT_MIN_Y;
  MaxY := DEFAULT_MAX_Y;
  MickeyX := 8;
  MickeyY := 16;
  DoubleSpeedThreshold := 64;
 End;
End;

{ Gestionnaire d'interruption pour souris sÇrie }
{$F+}
Procedure SerialMouseHandler;
{$F-}
{$IFNDEF FPC}
Begin
 Asm
  Push AX
  Push BX
  Push CX
  Push DX
  Push SI
  Push DI
  Push DS
  Push ES
   { Code de traitement de l'interruption sÇrie }
   { Lecture des donn√©es de la souris sÇrie }
  Mov DX, MouseDriver.SerialPort
  In AL, DX
   { Traitement simplifiÇ des donnÇes souris }
   { (Dans une vraie implÇmentation, il faudrait dÇcoder le protocole) }
   { Envoyer EOI au contrìleur d'interruption }
  Mov AL, $20
  Out $20, AL
  Pop ES
  Pop DS
  Pop DI
  Pop SI
  Pop DX
  Pop CX
  Pop BX
  Pop AX
  Iret
 End;
End;
{$ELSE}
Begin
 { Version simplifiÇe pour Free Pascal }
End;
{$ENDIF}

{ Gestionnaire d'interruption pour souris PS/2 }
{$F+}
Procedure PS2MouseHandler;
{$F-}
{$IFNDEF FPC}
Begin
 Asm
  Push AX
  Push BX
  Push CX
  Push DX
  Push SI
  Push DI
  Push DS
  Push ES
  { Lire les donn√©es de la souris PS/2 }
  In AL, PS2_DATA_PORT
  { Traitement simplifiÇ des donnÇes souris PS/2 }
  { (Dans une vraie implÇmentation, il faudrait dÇcoder le protocole) }
  { Envoyer EOI au contrìleur d'interruption }
  Mov AL, $20
  Out $A0, AL    { PIC esclave }
  Out $20, AL    { PIC maåtre }
  Pop ES
  Pop DS
  Pop DI
  Pop SI
  Pop DX
  Pop CX
  Pop BX
  Pop AX
  Iret
 End;
End;
{$ELSE}
Begin
 { Version simplifiÇe pour Free Pascal }
End;
{$ENDIF}

{ Gestionnaire principal d'interruption INT 33h }
{$F+}
Procedure MouseInt33Handler;
{$F-}
{$IFNDEF FPC}
Begin
 Asm
  Sti           { Activer les interruptions }
  Push BX
  Push CX
  Push DX
  Push SI
  Push DI
  Push DS
  Push ES
  { VÇrifier la fonction demandÇe dans AX }
  Cmp AX, 0
  Je @ResetMouse
  Cmp AX, 1
  Je @ShowCursor
  Cmp AX, 2
  Je @HideCursor
  Cmp AX, 3
  Je @GetMouseStatus
  Cmp AX, 4
  Je @SetMousePosition
  Cmp AX, 7
  Je @SetHorizontalLimits
  Cmp AX, 8
  Je @SetVerticalLimits
  Cmp AX, 11
  Je @ReadMouseMotion
  Cmp AX, 15
  Je @SetMickeyRatio
  Cmp AX, 36
  Je @GetDriverVersion
  Cmp AX, 109
  Je @MicrosoftDetection
  Jmp @ExitHandler
@ResetMouse:
  Mov AX, $FFFF          { Souris prÇsente }
  Mov BX, 2              { 2 boutons }
  Jmp @ExitHandler
@ShowCursor:
  Mov MouseDriver.State.Visible, 1
  Jmp @ExitHandler
@HideCursor:
  Mov MouseDriver.State.Visible, 0
  Jmp @ExitHandler
@GetMouseStatus:
  MOV AL, MouseDriver.State.Buttons
  MOV AH, 0
  Mov CX, MouseDriver.State.X
  Mov DX, MouseDriver.State.Y
  Jmp @ExitHandler
@SetMousePosition:
  Mov MouseDriver.State.X, CX
  Mov MouseDriver.State.Y, DX
  Jmp @ExitHandler
@SetHorizontalLimits:
  Mov MouseDriver.State.MinX, CX
  Mov MouseDriver.State.MaxX, DX
  Jmp @ExitHandler
@SetVerticalLimits:
  Mov MouseDriver.State.MinY, CX
  Mov MouseDriver.State.MaxY, DX
  Jmp @ExitHandler
@ReadMouseMotion:
  Mov CX, MouseDriver.State.DeltaX
  Mov DX, MouseDriver.State.DeltaY
  Mov MouseDriver.State.DeltaX, 0
  Mov MouseDriver.State.DeltaY, 0
  Jmp @ExitHandler
@SetMickeyRatio:
  Mov MouseDriver.State.MickeyX, CX
  Mov MouseDriver.State.MickeyY, DX
  Jmp @ExitHandler
@GetDriverVersion:
  Mov AX, MOUSE_DRIVER_VERSION
  Mov BX, 0              { Pas de gestionnaire utilisateur }
  Jmp @ExitHandler
@MicrosoftDetection:
  { Fonction 6Dh (109) - DÇtection pilote Microsoft }
  { Retourne la signature Microsoft dans les registres }
  Mov AX, $006D          { Code de fonction confirmÇ }
  Mov BX, $4D53          { Signature "MS" }
  Mov CX, $002E          { Version majeure.mineure }
  Mov DX, $0000          { RÇservÇ }
  Jmp @ExitHandler
@ExitHandler:
  Pop ES
  Pop DS
  Pop DI
  Pop SI
  Pop DX
  Pop CX
  Pop BX
  Iret
 End;
End;
{$ELSE}
Begin
 { Version simplifiÇe pour Free Pascal }
End;
{$ENDIF}

{ Installer le pilote souris }
Function InstallMouseDriver:Boolean;Begin
 InstallMouseDriver := False;
  { DÇtecter le type de souris }
 MouseDriver.MouseType := DetectMouseType;
 If MouseDriver.MouseType = MOUSE_TYPE_NONE Then Exit;
  { Initialiser l'Çtat de la souris }
 InitMouseState;
  { Sauvegarder l'ancien gestionnaire INT 33h }
 GetIntVec(MOUSE_INT, MouseDriver.OldInt33Handler);
  { Installer le nouveau gestionnaire }
 SetIntVec(MOUSE_INT, @MouseInt33Handler);
  { Installer les gestionnaires d'interruption matÇriel }
 Case MouseDriver.MouseType Of
  MOUSE_TYPE_SERIAL: Begin
   GetIntVec($0C + MouseDriver.SerialIRQ, MouseDriver.OldSerialHandler);
   SetIntVec($0C + MouseDriver.SerialIRQ, @SerialMouseHandler);
   {$IFNDEF FPC}
    { Activer l'IRQ dans le PIC }
    Port[$21] := Port[$21] And Not (1 Shl MouseDriver.SerialIRQ);
   {$ENDIF}
  End;
  MOUSE_TYPE_PS2: Begin
   GetIntVec($74, MouseDriver.OldPS2Handler); { IRQ 12 = INT 74h }
   SetIntVec($74, @PS2MouseHandler);
   {$IFNDEF FPC}
   { Activer l'IRQ 12 dans le PIC }
   Port[$A1] := Port[$A1] And $EF;  { PIC esclave - Bit 4 = IRQ 12 }
   Port[$21] := Port[$21] And $FB;  { PIC maåtre - Bit 2 = IRQ cascade }
   {$ENDIF}
  End;
 End;
 MouseDriver.Installed := True;
 MouseDriver.InitializedHardware := True;
 InstallMouseDriver := True;
End;

{ DÇsinstaller le pilote souris }
Procedure UninstallMouseDriver;Begin
 If MouseDriver.Installed Then Begin
  { Restaurer les anciens gestionnaires }
  SetIntVec(MOUSE_INT, MouseDriver.OldInt33Handler);
  Case MouseDriver.MouseType Of
   MOUSE_TYPE_SERIAL: Begin
    SetIntVec($0C + MouseDriver.SerialIRQ, MouseDriver.OldSerialHandler);
    {$IFNDEF FPC}
     { DÇsactiver l'IRQ dans le PIC }
     Port[$21] := Port[$21] Or (1 Shl MouseDriver.SerialIRQ);
    {$ENDIF}
   End;
   MOUSE_TYPE_PS2: Begin
    SetIntVec($74, MouseDriver.OldPS2Handler);
    {$IFNDEF FPC}
    { DÇsactiver l'IRQ 12 dans le PIC }
    Port[$A1] := Port[$A1] Or $10;
    {$ENDIF}
   End;
  End;
  MouseDriver.Installed := False;
 End;
End;

{ RÇinitialiser le pilote souris }
Procedure ResetMouseDriver;Begin
 If MouseDriver.Installed Then Begin
  InitMouseState;
  If Not MouseDriver.SilentMode Then Begin
   Case Language Of
    _English: WriteLn('Mouse driver reset successfully.');
    _Germany: WriteLn('Maustreiber erfolgreich zurÅckgesetzt.');
    Else WriteLn('Pilote souris rÇinitialisÇ avec succäs.');
   End;
  End;
 End Else Begin
  Case Language Of
   _English: WriteLn('Mouse driver not installed.');
   _Germany: WriteLn('Maustreiber nicht installiert.');
   Else WriteLn('Pilote souris non installÇ.');
  End;
 End;
End;

 { Forcer la dÇtection matÇrielle }
Procedure ForceHardwareDetection;
Var
 DetectedType: Byte;
Begin
 DetectedType := DetectMouseType;
 Case Language Of
  _English: Begin
   WriteLn('Hardware detection results:');
   Case DetectedType Of
    MOUSE_TYPE_NONE: WriteLn('  No mouse detected');
    MOUSE_TYPE_SERIAL: WriteLn('  Serial mouse detected on COM',
                              (MouseDriver.SerialPort - COM1_BASE) Div 8 + 1);
    MOUSE_TYPE_PS2: WriteLn('  PS/2 mouse detected');
    MOUSE_TYPE_BUS: WriteLn('  Bus mouse detected');
   End;
  End;
  _Germany: Begin
   WriteLn('Hardware-Erkennungsergebnisse:');
   Case DetectedType Of
    MOUSE_TYPE_NONE: WriteLn('  Keine Maus erkannt');
    MOUSE_TYPE_SERIAL: WriteLn('  Serielle Maus an COM',
                              (MouseDriver.SerialPort - COM1_BASE) Div 8 + 1, ' erkannt');
    MOUSE_TYPE_PS2: WriteLn('  PS/2-Maus erkannt');
    MOUSE_TYPE_BUS: WriteLn('  Bus-Maus erkannt');
   End;
  End;
  Else Begin { Franáais }
   WriteLn('RÇsultats de la dÇtection matÇrielle:');
   Case DetectedType Of
    MOUSE_TYPE_NONE: WriteLn('  Aucune souris dÇtectÇe');
    MOUSE_TYPE_SERIAL: WriteLn('  Souris sÇrie dÇtectÇe sur COM',
                              (MouseDriver.SerialPort - COM1_BASE) Div 8 + 1);
    MOUSE_TYPE_PS2: WriteLn('  Souris PS/2 dÇtectÇe');
    MOUSE_TYPE_BUS: WriteLn('  Souris bus dÇtectÇe');
   End;
  End;
 End;
End;

{ Afficher les informations internes }
Procedure ShowInternalInfo;Begin
 Case Language Of
  _English: Begin
   WriteLn('Mouse Driver Internal Information:');
   WriteLn('  Version: ', MOUSE_DRIVER_VERSION Shr 8, '.', MOUSE_DRIVER_VERSION And $FF);
   WriteLn('  Driver installed: ', MouseDriver.Installed);
   If MouseDriver.Installed Then Begin
    WriteLn('  Mouse type: ', MouseDriver.MouseType);
    WriteLn('  Position: (', MouseDriver.State.X, ',', MouseDriver.State.Y, ')');
    WriteLn('  Button state: ', MouseDriver.State.Buttons);
    WriteLn('  Cursor visible: ', MouseDriver.State.Visible);
    WriteLn('  X limits: ', MouseDriver.State.MinX, '-', MouseDriver.State.MaxX);
    WriteLn('  Y limits: ', MouseDriver.State.MinY, '-', MouseDriver.State.MaxY);
   End;
  End;
  _Germany: Begin
   WriteLn('Interne Informationen des Maustreibers:');
   WriteLn('  Version: ', MOUSE_DRIVER_VERSION Shr 8, '.', MOUSE_DRIVER_VERSION And $FF);
   WriteLn('  Treiber installiert: ', MouseDriver.Installed);
   If MouseDriver.Installed Then Begin
    WriteLn('  Maustyp: ', MouseDriver.MouseType);
    WriteLn('  Position: (', MouseDriver.State.X, ',', MouseDriver.State.Y, ')');
    WriteLn('  Tastenstatus: ', MouseDriver.State.Buttons);
    WriteLn('  Cursor sichtbar: ', MouseDriver.State.Visible);
    WriteLn('  X-Grenzen: ', MouseDriver.State.MinX, '-', MouseDriver.State.MaxX);
    WriteLn('  Y-Grenzen: ', MouseDriver.State.MinY, '-', MouseDriver.State.MaxY);
   End;
  End;
  Else Begin { Franáais }
   WriteLn('Informations internes du pilote souris:');
   WriteLn('  Version: ', MOUSE_DRIVER_VERSION Shr 8, '.', MOUSE_DRIVER_VERSION And $FF);
   WriteLn('  Pilote installÇ: ', MouseDriver.Installed);
   If MouseDriver.Installed Then Begin
    WriteLn('  Type souris: ', MouseDriver.MouseType);
    WriteLn('  Position: (', MouseDriver.State.X, ',', MouseDriver.State.Y, ')');
    WriteLn('  êtat boutons: ', MouseDriver.State.Buttons);
    WriteLn('  Curseur visible: ', MouseDriver.State.Visible);
    WriteLn('  Limites X: ', MouseDriver.State.MinX, '-', MouseDriver.State.MaxX);
    WriteLn('  Limites Y: ', MouseDriver.State.MinY, '-', MouseDriver.State.MaxY);
   End;
  End;
 End;
End;

{ VÇrifier si le pilote est dÇjÖ installÇ }
Function IsMouseDriverInstalled: Boolean;
Var
 Regs: Registers;
Begin
 Regs.AX := 0; { Fonction Reset }
 Intr(MOUSE_INT, Regs);
 IsMouseDriverInstalled := (Regs.AX = $FFFF);
End;

BEGIN
 { Initialisation de la langue }
 Language := _French;
 TmpLanguage := GetEnv('LANGUAGE');
 If TmpLanguage <> '' Then Begin
  If TmpLanguage[1] = '"' Then TmpLanguage := Copy(TmpLanguage, 2, 255);
  If StrToUpper(Copy(TmpLanguage, 1, 2)) = 'EN' Then Language := _English Else
  If StrToUpper(Copy(TmpLanguage, 1, 2)) = 'GR' Then Language := _Germany Else
  If StrToUpper(Copy(TmpLanguage, 1, 2)) = 'IT' Then Language := _Italian Else
  If StrToUpper(Copy(TmpLanguage, 1, 2)) = 'SP' Then Language := _Spain Else
  If (StrToUpper(Copy(TmpLanguage, 1, 2)) = 'SQ') or
     (StrToUpper(Copy(TmpLanguage, 1, 3)) = 'ALB') Then Language := _Albanian Else
  If (StrToUpper(Copy(TmpLanguage, 1, 2)) = 'PT') or
     (StrToUpper(Copy(TmpLanguage, 1, 3)) = 'PRT') Then Language := _Portuguese Else
  If (StrToUpper(Copy(TmpLanguage, 1, 2)) = 'SE') or
     (StrToUpper(Copy(TmpLanguage, 1, 3)) = 'SWE') Then Language := _Swedish Else
  If (StrToUpper(Copy(TmpLanguage, 1, 2)) = 'DK') or
     (StrToUpper(Copy(TmpLanguage, 1, 3)) = 'DNK') Then Language := _Danish Else
  If (StrToUpper(Copy(TmpLanguage, 1, 2)) = 'JP') or
     (StrToUpper(Copy(TmpLanguage, 1, 3)) = 'JPN') Then Language := _Japanese;
 End;
  { Initialisation }
 FillChar(MouseDriver, SizeOf(TMouseDriver), 0);
 MouseDriver.SilentMode := False;
  { Traitement des paramätres de ligne de commande }
 For I := 1 to ParamCount do Begin
  Param := StrToUpper(ParamStr(I));
  If (Param = '/?') Or (Param = '/H') Or (Param = '--HELP') Then Begin
   Case Language Of
    _English: Begin
     WriteLn('MSMOUSE - MS Mouse Driver');
     WriteLn;
     WriteLn('Loads the mouse driver for MS-DOS applications.');
     WriteLn;
     WriteLn('MSMOUSE [parameters]');
     WriteLn;
     WriteLn('Parameters:');
     WriteLn('  /Y         Load driver without displaying messages (silent mode)');
     WriteLn('  /R         Reset the mouse driver already loaded in memory');
     WriteLn('  /U         Unload the driver from memory (if loaded as TSR)');
     WriteLn('  /C         Force hardware mouse detection');
     WriteLn('  /S         Force serial mouse usage (COM1/COM2)');
     WriteLn('  /B         Force bus mouse usage (IBM PC)');
     WriteLn('  /I         Display internal driver and hardware information');
     WriteLn('  /?         Display this help');
    End;
    _Germany: Begin
     WriteLn('MSMOUSE - MS Maustreiber');
     WriteLn;
     WriteLn('LÑdt den Maustreiber fÅr MS-DOS-Anwendungen.');
     WriteLn;
     WriteLn('MSMOUSE [Parameter]');
     WriteLn;
     WriteLn('Parameter:');
     WriteLn('  /Y         Treiber ohne Nachrichten laden (stiller Modus)');
     WriteLn('  /R         Im Speicher geladenen Maustreiber zurÅcksetzen');
     WriteLn('  /U         Treiber aus dem Speicher entfernen (wenn als TSR geladen)');
     WriteLn('  /C         Hardware-Mauserkennung erzwingen');
     WriteLn('  /S         Serielle Maus erzwingen (COM1/COM2)');
     WriteLn('  /B         Bus-Maus erzwingen (IBM PC)');
     WriteLn('  /I         Interne Treiber- und Hardware-Informationen anzeigen');
     WriteLn('  /?         Diese Hilfe anzeigen');
    End;
    Else Begin { Franáais }
     WriteLn('MSMOUSE - Pilote de souris MS');
     WriteLn;
     WriteLn('Cette commande permet de charger le pilote souris pour les applications MS-DOS.');
     WriteLn;
     WriteLn('MSMOUSE [paramätres]');
     WriteLn;
     WriteLn('Paramätres:');
     WriteLn('  /Y         Charger le pilote sans afficher de messages (mode silencieux)');
     WriteLn('  /R         RÇinitialiser le pilote souris dÇjÖ chargÇ en mÇmoire');
     WriteLn('  /U         DÇcharger le pilote de la mÇmoire (si chargÇ comme TSR)');
     WriteLn('  /C         Forcer la dÇtection du matÇriel souris');
     WriteLn('  /S         Forcer l''utilisation d''une souris sÇrie (COM1/COM2)');
     WriteLn('  /B         Forcer l''utilisation d''une souris bus (IBM PC)');
     WriteLn('  /I         Afficher les informations internes du pilote et matÇriel');
     WriteLn('  /?         Afficher cette aide');
    End;
   End;
   Exit;
  End
  Else If (Param = '/Y') Then Begin
   MouseDriver.SilentMode := True;
  End
  Else If (Param = '/R') Then Begin
   ResetMouseDriver;
   Exit;
  End
  Else If (Param = '/U') Then Begin
   UninstallMouseDriver;
   If Not MouseDriver.SilentMode Then Begin
    Case Language Of
     _English: WriteLn('Mouse driver unloaded from memory.');
     _Germany: WriteLn('Maustreiber aus dem Speicher entfernt.');
     Else WriteLn('Pilote souris dÇchargÇ de la mÇmoire.');
    End;
   End;
   Exit;
  End
  Else If (Param = '/C') Then Begin
   ForceHardwareDetection;
   Exit;
  End
  Else If (Param = '/S') Then Begin
   { Forcer souris sÇrie - sera implÇmentÇ dans DetectMouseType }
   MouseDriver.MouseType := MOUSE_TYPE_SERIAL;
  End
  Else If (Param = '/B') Then Begin
   { Forcer souris bus - pour compatibilitÇ }
   MouseDriver.MouseType := MOUSE_TYPE_BUS;
  End
  Else If (Param = '/I') Then Begin
   ShowInternalInfo;
   Exit;
  End
  Else Begin
   Case Language Of
    _English: WriteLn('Invalid parameter: ', Param);
    _Germany: WriteLn('UngÅltiger Parameter: ', Param);
    Else WriteLn('Paramätre invalide: ', Param);
   End;
   Halt(1);
  End;
 End;
  { VÇrifier si un pilote souris est dÇjÖ installÇ }
 If IsMouseDriverInstalled Then Begin
  If Not MouseDriver.SilentMode Then Begin
   Case Language Of
    _English: WriteLn('Mouse driver already loaded in memory.');
    _Germany: WriteLn('Maustreiber bereits im Speicher geladen.');
    Else WriteLn('Pilote souris dÇjÖ chargÇ en mÇmoire.');
   End;
  End;
  Exit;
 End;
  { Installer le pilote souris }
 If InstallMouseDriver Then Begin
  If Not MouseDriver.SilentMode Then Begin
   Case Language Of
    _English: Begin
     WriteLn('MS Mouse Driver v', MOUSE_DRIVER_VERSION Shr 8, '.',
             MOUSE_DRIVER_VERSION And $FF, ' loaded successfully.');
     Case MouseDriver.MouseType Of
      MOUSE_TYPE_SERIAL: WriteLn('Serial mouse detected on COM',
                                (MouseDriver.SerialPort - COM1_BASE) Div 8 + 1, '.');
      MOUSE_TYPE_PS2: WriteLn('PS/2 mouse detected.');
      MOUSE_TYPE_BUS: WriteLn('Bus mouse detected.');
     End;
    End;
    _Germany: Begin
     WriteLn('MS Maustreiber v', MOUSE_DRIVER_VERSION Shr 8, '.',
             MOUSE_DRIVER_VERSION And $FF, ' erfolgreich geladen.');
     Case MouseDriver.MouseType Of
      MOUSE_TYPE_SERIAL: WriteLn('Serielle Maus an COM',
                                (MouseDriver.SerialPort - COM1_BASE) Div 8 + 1, ' erkannt.');
      MOUSE_TYPE_PS2: WriteLn('PS/2-Maus erkannt.');
      MOUSE_TYPE_BUS: WriteLn('Bus-Maus erkannt.');
     End;
    End;
    Else Begin { Franáais }
     WriteLn('Pilote souris MS v', MOUSE_DRIVER_VERSION Shr 8, '.',
             MOUSE_DRIVER_VERSION And $FF, ' chargÇ avec succäs.');
     Case MouseDriver.MouseType Of
      MOUSE_TYPE_SERIAL: WriteLn('Souris sÇrie dÇtectÇe sur COM',
                                (MouseDriver.SerialPort - COM1_BASE) Div 8 + 1, '.');
      MOUSE_TYPE_PS2: WriteLn('Souris PS/2 dÇtectÇe.');
      MOUSE_TYPE_BUS: WriteLn('Souris bus dÇtectÇe.');
     End;
    End;
   End;
  End;
   { Rester rÇsident en mÇmoire }
  Keep(0);
 End Else Begin
  Case Language Of
   _English: WriteLn('No mouse hardware detected. Driver not loaded.');
   _Germany: WriteLn('Keine Maus-Hardware erkannt. Treiber nicht geladen.');
   Else WriteLn('Aucun matÇriel souris dÇtectÇ. Pilote non chargÇ.');
  End;
  Halt(1);
 End;
END.