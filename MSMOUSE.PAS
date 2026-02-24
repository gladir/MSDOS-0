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
 { Version du pilote souris }
 MOUSE_DRIVER_VERSION = $0806;  { Version 8.06 }

 { Codes d'erreur }
 ERR_SUCCESS = 0;
 ERR_INVALID_FUNCTION = 1;
 ERR_NO_MOUSE = 2;
 ERR_DRIVER_NOT_INSTALLED = 3;
 ERR_INVALID_PARAMETER = 4;

 { Interruption souris }
 MOUSE_INT = $33;

 { Ports série pour souris série }
 COM1_BASE = $3F8;
 COM2_BASE = $2F8;
 COM3_BASE = $3E8;
 COM4_BASE = $2E8;

 { Ports PS/2 pour souris PS/2 }
 PS2_DATA_PORT = $60;
 PS2_STATUS_PORT = $64;
 PS2_COMMAND_PORT = $64;

 { IRQ pour souris }
 PS2_IRQ = 12;           { IRQ 12 pour souris PS/2 }
 COM1_IRQ = 4;           { IRQ 4 pour COM1 }
 COM2_IRQ = 3;           { IRQ 3 pour COM2 }

 { Types de souris }
 MOUSE_TYPE_NONE = 0;
 MOUSE_TYPE_SERIAL = 1;
 MOUSE_TYPE_PS2 = 2;
 MOUSE_TYPE_BUS = 3;

 { États des boutons }
 BUTTON_LEFT = 1;
 BUTTON_RIGHT = 2;
 BUTTON_MIDDLE = 4;

 { Limites de position souris }
 DEFAULT_MIN_X = 0;
 DEFAULT_MAX_X = 639;
 DEFAULT_MIN_Y = 0;
 DEFAULT_MAX_Y = 199;

Type
 { Structure d'état de la souris }
 TMouseState = Record
  X, Y: Integer;          { Position actuelle }
  Buttons: Byte;          { État des boutons }
  DeltaX, DeltaY: Integer; { Déplacement depuis dernière lecture }
  Visible: Boolean;       { Curseur visible }
  MinX, MaxX: Integer;    { Limites horizontales }
  MinY, MaxY: Integer;    { Limites verticales }
  MickeyX, MickeyY: Integer; { Sensibilité }
  DoubleSpeedThreshold: Integer; { Seuil de vitesse double }
 End;

 { Structure de contrôle du pilote TSR }
 TMouseDriver = Record
  Installed: Boolean;     { Pilote installé }
  MouseType: Byte;        { Type de souris détecté }
  SerialPort: Word;       { Port série (si souris série) }
  SerialIRQ: Byte;        { IRQ série }
  State: TMouseState;     { État de la souris }
  UserHandler: Pointer;   { Gestionnaire utilisateur }
  CallMask: Word;         { Masque d'appel utilisateur }
  OldInt33Handler: Pointer; { Ancien gestionnaire INT 33h }
  OldSerialHandler: Pointer; { Ancien gestionnaire IRQ série }
  OldPS2Handler: Pointer;    { Ancien gestionnaire IRQ PS/2 }
  InitializedHardware: Boolean; { Matériel initialisé }
  SilentMode: Boolean;    { Mode silencieux }
 End;

Var
 Language:(_French,_English,_Germany,_Italian,_Spain,_Albanian,_Portuguese,_Swedish,_Danish,_Japanese);
 TmpLanguage: String;
 MouseDriver: TMouseDriver;
 I: Byte;
 Param: String;

{ Convertir une chaîne en majuscules }
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

{ Écrire un byte dans un port }
Procedure PortWriteByte(Port: Word; Value: Byte);
{$IFDEF FPC}
Begin
 { Simulation pour Free Pascal - pas d'accès direct aux ports }
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

{ Détecter une souris série sur un port COM }
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
 
 { Test de présence du port série }
 OldValue := PortReadByte(ComPort + 4); { Registre de contrôle modem }
 PortWriteByte(ComPort + 4, $10);       { RTS on, DTR off }
 TestValue := PortReadByte(ComPort + 6); { Registre d'état modem }
 
 If (TestValue And $10) = 0 Then Begin { CTS devrait être off }
  PortWriteByte(ComPort + 4, $11);     { RTS on, DTR on }
  TestValue := PortReadByte(ComPort + 6);
  
  If (TestValue And $20) <> 0 Then Begin { DSR devrait être on }
   { Initialisation basique de la souris série }
   PortWriteByte(ComPort + 3, $80);    { DLAB = 1 }
   PortWriteByte(ComPort + 0, $60);    { 1200 baud }
   PortWriteByte(ComPort + 1, $00);
   PortWriteByte(ComPort + 3, $02);    { 7 bits, no parity, 1 stop }
   PortWriteByte(ComPort + 4, $03);    { DTR et RTS on }
   PortWriteByte(ComPort + 1, $00);    { Pas d'interruptions }
   
   DetectSerialMouse := True;
  End;
 End;
 
 PortWriteByte(ComPort + 4, OldValue); { Restaurer l'ancien état }
End;
{$ENDIF}

{ Détecter une souris PS/2 }
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
 
 { Vérifier si le contrôleur PS/2 existe }
 Status := PortReadByte(PS2_STATUS_PORT);
 If (Status And $02) = 0 Then Begin { Buffer d'entrée vide }
  { Envoyer commande de test du port souris }
  PortWriteByte(PS2_COMMAND_PORT, $A9);
  
  { Attendre la réponse }
  Repeat
   Status := PortReadByte(PS2_STATUS_PORT);
  Until (Status And $01) <> 0;
  
  { Lire le résultat }
  Status := PortReadByte(PS2_DATA_PORT);
  If Status = $00 Then Begin { Test réussi }
   DetectPS2Mouse := True;
  End;
 End;
End;
{$ENDIF}

{ Détecter le type de souris présent }
Function DetectMouseType: Byte;
Begin
 DetectMouseType := MOUSE_TYPE_NONE;
 
 { Essayer de détecter une souris PS/2 en premier }
 If DetectPS2Mouse Then Begin
  DetectMouseType := MOUSE_TYPE_PS2;
  Exit;
 End;
 
 { Essayer les ports série }
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

{ Initialiser l'état de la souris }
Procedure InitMouseState;
Begin
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

{ Gestionnaire d'interruption pour souris série }
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
  
  { Code de traitement de l'interruption série }
  { Lecture des données de la souris série }
  Mov DX, MouseDriver.SerialPort
  In AL, DX
  
  { Traitement simplifié des données souris }
  { (Dans une vraie implémentation, il faudrait décoder le protocole) }
  
  { Envoyer EOI au contrôleur d'interruption }
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
 { Version simplifiée pour Free Pascal }
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
  
  { Lire les données de la souris PS/2 }
  In AL, PS2_DATA_PORT
  
  { Traitement simplifié des données souris PS/2 }
  { (Dans une vraie implémentation, il faudrait décoder le protocole) }
  
  { Envoyer EOI au contrôleur d'interruption }
  Mov AL, $20
  Out $A0, AL    { PIC esclave }
  Out $20, AL    { PIC maître }
  
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
 { Version simplifiée pour Free Pascal }
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
  
  { Vérifier la fonction demandée dans AX }
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
  
  Jmp @ExitHandler
  
@ResetMouse:
  Mov AX, $FFFF          { Souris présente }
  Mov BX, 2              { 2 boutons }
  Jmp @ExitHandler
  
@ShowCursor:
  Mov MouseDriver.State.Visible, 1
  Jmp @ExitHandler
  
@HideCursor:
  Mov MouseDriver.State.Visible, 0
  Jmp @ExitHandler
  
@GetMouseStatus:
  Mov AX, MouseDriver.State.Buttons
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
 { Version simplifiée pour Free Pascal }
End;
{$ENDIF}

{ Installer le pilote souris }
Function InstallMouseDriver: Boolean;
Begin
 InstallMouseDriver := False;
 
 { Détecter le type de souris }
 MouseDriver.MouseType := DetectMouseType;
 If MouseDriver.MouseType = MOUSE_TYPE_NONE Then Exit;
 
 { Initialiser l'état de la souris }
 InitMouseState;
 
 { Sauvegarder l'ancien gestionnaire INT 33h }
 GetIntVec(MOUSE_INT, MouseDriver.OldInt33Handler);
 
 { Installer le nouveau gestionnaire }
 SetIntVec(MOUSE_INT, @MouseInt33Handler);
 
 { Installer les gestionnaires d'interruption matériel }
 Case MouseDriver.MouseType Of
  MOUSE_TYPE_SERIAL: Begin
   GetIntVec($0C + MouseDriver.SerialIRQ, MouseDriver.OldSerialHandler);
   SetIntVec($0C + MouseDriver.SerialIRQ, @SerialMouseHandler);
   
   {$IFNDEF FPC}
   { Activer l'IRQ dans le PIC }
   Asm
    In AL, $21
    And AL, Not (1 Shl MouseDriver.SerialIRQ)
    Out $21, AL
   End;
   {$ENDIF}
  End;
  
  MOUSE_TYPE_PS2: Begin
   GetIntVec($74, MouseDriver.OldPS2Handler); { IRQ 12 = INT 74h }
   SetIntVec($74, @PS2MouseHandler);
   
   {$IFNDEF FPC}
   { Activer l'IRQ 12 dans le PIC }
   Asm
    In AL, $A1     { PIC esclave }
    And AL, $EF    { Bit 4 = IRQ 12 }
    Out $A1, AL
    
    In AL, $21     { PIC maître }
    And AL, $FB    { Bit 2 = IRQ cascade }
    Out $21, AL
   End;
   {$ENDIF}
  End;
 End;
 
 MouseDriver.Installed := True;
 MouseDriver.InitializedHardware := True;
 InstallMouseDriver := True;
End;

{ Désinstaller le pilote souris }
Procedure UninstallMouseDriver;
Begin
 If MouseDriver.Installed Then Begin
  { Restaurer les anciens gestionnaires }
  SetIntVec(MOUSE_INT, MouseDriver.OldInt33Handler);
  
  Case MouseDriver.MouseType Of
   MOUSE_TYPE_SERIAL: Begin
    SetIntVec($0C + MouseDriver.SerialIRQ, MouseDriver.OldSerialHandler);
    
    {$IFNDEF FPC}
    { Désactiver l'IRQ dans le PIC }
    Asm
     In AL, $21
     Or AL, (1 Shl MouseDriver.SerialIRQ)
     Out $21, AL
    End;
    {$ENDIF}
   End;
   
   MOUSE_TYPE_PS2: Begin
    SetIntVec($74, MouseDriver.OldPS2Handler);
    
    {$IFNDEF FPC}
    { Désactiver l'IRQ 12 dans le PIC }
    Asm
     In AL, $A1
     Or AL, $10
     Out $A1, AL
    End;
    {$ENDIF}
   End;
  End;
  
  MouseDriver.Installed := False;
 End;
End;

{ Réinitialiser le pilote souris }
Procedure ResetMouseDriver;
Begin
 If MouseDriver.Installed Then Begin
  InitMouseState;
  
  If Not MouseDriver.SilentMode Then Begin
   Case Language Of
    _English: WriteLn('Mouse driver reset successfully.');
    _Germany: WriteLn('Maustreiber erfolgreich zurückgesetzt.');
    Else WriteLn('Pilote souris réinitialisé avec succès.');
   End;
  End;
 End Else Begin
  Case Language Of
   _English: WriteLn('Mouse driver not installed.');
   _Germany: WriteLn('Maustreiber nicht installiert.');
   Else WriteLn('Pilote souris non installé.');
  End;
 End;
End;

{ Forcer la détection matérielle }
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
  Else Begin { Français }
   WriteLn('Résultats de la détection matérielle:');
   Case DetectedType Of
    MOUSE_TYPE_NONE: WriteLn('  Aucune souris détectée');
    MOUSE_TYPE_SERIAL: WriteLn('  Souris série détectée sur COM', 
                              (MouseDriver.SerialPort - COM1_BASE) Div 8 + 1);
    MOUSE_TYPE_PS2: WriteLn('  Souris PS/2 détectée');
    MOUSE_TYPE_BUS: WriteLn('  Souris bus détectée');
   End;
  End;
 End;
End;

{ Afficher les informations internes }
Procedure ShowInternalInfo;
Begin
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
  Else Begin { Français }
   WriteLn('Informations internes du pilote souris:');
   WriteLn('  Version: ', MOUSE_DRIVER_VERSION Shr 8, '.', MOUSE_DRIVER_VERSION And $FF);
   WriteLn('  Pilote installé: ', MouseDriver.Installed);
   If MouseDriver.Installed Then Begin
    WriteLn('  Type souris: ', MouseDriver.MouseType);
    WriteLn('  Position: (', MouseDriver.State.X, ',', MouseDriver.State.Y, ')');
    WriteLn('  État boutons: ', MouseDriver.State.Buttons);
    WriteLn('  Curseur visible: ', MouseDriver.State.Visible);
    WriteLn('  Limites X: ', MouseDriver.State.MinX, '-', MouseDriver.State.MaxX);
    WriteLn('  Limites Y: ', MouseDriver.State.MinY, '-', MouseDriver.State.MaxY);
   End;
  End;
 End;
End;

{ Vérifier si le pilote est déjà installé }
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

 { Traitement des paramètres de ligne de commande }
 For I := 1 to ParamCount do Begin
  Param := StrToUpper(ParamStr(I));

  If (Param = '/?') Or (Param = '/H') Or (Param = '--HELP') Then Begin
   Case Language Of
    _English: Begin
     WriteLn('MSMOUSE - Microsoft Mouse Driver');
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
     WriteLn('MSMOUSE - Microsoft Maustreiber');
     WriteLn;
     WriteLn('Lädt den Maustreiber für MS-DOS-Anwendungen.');
     WriteLn;
     WriteLn('MSMOUSE [Parameter]');
     WriteLn;
     WriteLn('Parameter:');
     WriteLn('  /Y         Treiber ohne Nachrichten laden (stiller Modus)');
     WriteLn('  /R         Im Speicher geladenen Maustreiber zurücksetzen');
     WriteLn('  /U         Treiber aus dem Speicher entfernen (wenn als TSR geladen)');
     WriteLn('  /C         Hardware-Mauserkennung erzwingen');
     WriteLn('  /S         Serielle Maus erzwingen (COM1/COM2)');
     WriteLn('  /B         Bus-Maus erzwingen (IBM PC)');
     WriteLn('  /I         Interne Treiber- und Hardware-Informationen anzeigen');
     WriteLn('  /?         Diese Hilfe anzeigen');
    End;
    Else Begin { Français }
     WriteLn('MSMOUSE - Pilote de souris Microsoft');
     WriteLn;
     WriteLn('Charge le pilote souris pour les applications MS-DOS.');
     WriteLn;
     WriteLn('MSMOUSE [paramètres]');
     WriteLn;
     WriteLn('Paramètres:');
     WriteLn('  /Y         Charger le pilote sans afficher de messages (mode silencieux)');
     WriteLn('  /R         Réinitialiser le pilote souris déjà chargé en mémoire');
     WriteLn('  /U         Décharger le pilote de la mémoire (si chargé comme TSR)');
     WriteLn('  /C         Forcer la détection du matériel souris');
     WriteLn('  /S         Forcer l''utilisation d''une souris série (COM1/COM2)');
     WriteLn('  /B         Forcer l''utilisation d''une souris bus (IBM PC)');
     WriteLn('  /I         Afficher les informations internes du pilote et matériel');
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
     Else WriteLn('Pilote souris déchargé de la mémoire.');
    End;
   End;
   Exit;
  End
  Else If (Param = '/C') Then Begin
   ForceHardwareDetection;
   Exit;
  End
  Else If (Param = '/S') Then Begin
   { Forcer souris série - sera implémenté dans DetectMouseType }
   MouseDriver.MouseType := MOUSE_TYPE_SERIAL;
  End
  Else If (Param = '/B') Then Begin
   { Forcer souris bus - pour compatibilité }
   MouseDriver.MouseType := MOUSE_TYPE_BUS;
  End
  Else If (Param = '/I') Then Begin
   ShowInternalInfo;
   Exit;
  End
  Else Begin
   Case Language Of
    _English: WriteLn('Invalid parameter: ', Param);
    _Germany: WriteLn('Ungültiger Parameter: ', Param);
    Else WriteLn('Paramètre invalide: ', Param);
   End;
   Halt(1);
  End;
 End;

 { Vérifier si un pilote souris est déjà installé }
 If IsMouseDriverInstalled Then Begin
  If Not MouseDriver.SilentMode Then Begin
   Case Language Of
    _English: WriteLn('Mouse driver already loaded in memory.');
    _Germany: WriteLn('Maustreiber bereits im Speicher geladen.');
    Else WriteLn('Pilote souris déjà chargé en mémoire.');
   End;
  End;
  Exit;
 End;

 { Installer le pilote souris }
 If InstallMouseDriver Then Begin
  If Not MouseDriver.SilentMode Then Begin
   Case Language Of
    _English: Begin
     WriteLn('Microsoft Mouse Driver v', MOUSE_DRIVER_VERSION Shr 8, '.', 
             MOUSE_DRIVER_VERSION And $FF, ' loaded successfully.');
     Case MouseDriver.MouseType Of
      MOUSE_TYPE_SERIAL: WriteLn('Serial mouse detected on COM', 
                                (MouseDriver.SerialPort - COM1_BASE) Div 8 + 1, '.');
      MOUSE_TYPE_PS2: WriteLn('PS/2 mouse detected.');
      MOUSE_TYPE_BUS: WriteLn('Bus mouse detected.');
     End;
    End;
    _Germany: Begin
     WriteLn('Microsoft Maustreiber v', MOUSE_DRIVER_VERSION Shr 8, '.', 
             MOUSE_DRIVER_VERSION And $FF, ' erfolgreich geladen.');
     Case MouseDriver.MouseType Of
      MOUSE_TYPE_SERIAL: WriteLn('Serielle Maus an COM', 
                                (MouseDriver.SerialPort - COM1_BASE) Div 8 + 1, ' erkannt.');
      MOUSE_TYPE_PS2: WriteLn('PS/2-Maus erkannt.');
      MOUSE_TYPE_BUS: WriteLn('Bus-Maus erkannt.');
     End;
    End;
    Else Begin { Français }
     WriteLn('Pilote souris Microsoft v', MOUSE_DRIVER_VERSION Shr 8, '.', 
             MOUSE_DRIVER_VERSION And $FF, ' chargé avec succès.');
     Case MouseDriver.MouseType Of
      MOUSE_TYPE_SERIAL: WriteLn('Souris série détectée sur COM', 
                                (MouseDriver.SerialPort - COM1_BASE) Div 8 + 1, '.');
      MOUSE_TYPE_PS2: WriteLn('Souris PS/2 détectée.');
      MOUSE_TYPE_BUS: WriteLn('Souris bus détectée.');
     End;
    End;
   End;
  End;
  
  { Rester résident en mémoire }
  Keep(0);
 End Else Begin
  Case Language Of
   _English: WriteLn('No mouse hardware detected. Driver not loaded.');
   _Germany: WriteLn('Keine Maus-Hardware erkannt. Treiber nicht geladen.');
   Else WriteLn('Aucun matériel souris détecté. Pilote non chargé.');
  End;
  Halt(1);
 End;
END.
