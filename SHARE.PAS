{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program SHARE;

{$M 16384,0,10000}
{$A-}

Uses DOS,Strings;

 { Fonction StrPCopy pour la compatibilitÇ }
Procedure StrPCopy(Dest: PChar; Source: String);
Var
 I: Integer;
Begin
 For I := 1 to Length(Source) do Dest[I-1] := Source[I];
 Dest[Length(Source)] := #0;
End;

 { Fonction GetPID simulÇe pour la compatibilitÇ }
Function GetPID:Word;Begin
 GetPID := 1; { PID simulÇ pour compatibilitÇ DOS }
End;

Const
 { Codes d'erreur MS-DOS }
 ERR_SUCCESS = 0;                { Succäs, aucune erreur }
 ERR_INVALID_FUNCTION = 1;       { Fonction invalide }
 ERR_FILE_NOT_FOUND = 2;         { Fichier introuvable }
 ERR_ACCESS_DENIED = 5;          { Accäs refusÇ }
 ERR_NOT_ENOUGH_MEMORY = 8;      { MÇmoire insuffisante }
 ERR_INVALID_FORMAT = 11;        { Format invalide }
 ERR_INVALID_DATA = 13;          { DonnÇes invalides }
 ERR_INVALID_PARAMETER = 87;     { Paramätre invalide }

 { Constantes SHARE }
 SHARE_MULTIPLEX = $10;          { NumÇro d'interruption multiplex pour SHARE }
 SHARE_INSTALL_CHECK = $00;      { VÇrification si SHARE est installÇ }
 SHARE_LOCK_FILE_REGION = $01;   { Verrouiller rÇgion de fichier }
 SHARE_UNLOCK_FILE_REGION = $02; { DÇverrouiller rÇgion de fichier }
 SHARE_CHECK_FILE_LOCK = $03;    { VÇrifier verrou de fichier }
 SHARE_GET_MACHINE_NAME = $04;   { Obtenir nom de machine }
 SHARE_SET_MACHINE_NAME = $05;   { DÇfinir nom de machine }

  { Valeurs par dÇfaut }
 DEFAULT_FILE_SPACE = 2048;      { Espace par dÇfaut pour informations de partage (octets) }
 DEFAULT_LOCK_COUNT = 20;        { Nombre maximal de verrous par dÇfaut }
 MAX_FILENAME_LENGTH = 128;      { Longueur maximale du nom de fichier }
 MAX_MACHINE_NAME = 15;          { Longueur maximale du nom de machine }

  { Signature d'identification SHARE en mÇmoire }
 SHARE_SIGNATURE: String[5] = 'SHARE';

 { Modes de partage de fichier }
 SHARE_DENY_NONE = $40;          { Aucune restriction de partage }
 SHARE_DENY_READ = $30;          { Interdire lecture }
 SHARE_DENY_WRITE = $20;         { Interdire Çcriture }
 SHARE_DENY_ALL = $10;           { Interdire tout accäs }
 SHARE_COMPATIBILITY = $00;      { Mode de compatibilitÇ }

Type
 { Structure d'entrÇe de fichier partagÇ }
 TSharedFileEntry = Record
  FileName: Array[0..MAX_FILENAME_LENGTH-1] of Char; { Nom de fichier canonique }
  ShareMode: Byte;              { Mode de partage }
  AccessMode: Byte;             { Mode d'accäs }
  ProcessID: Word;              { ID du processus propri√©taire }
  MachineID: Word;              { ID de la machine }
  FileHandle: Word;             { Handle du fichier }
  RefCount: Word;               { Nombre de rÇfÇrences }
  LockCount: Word;              { Nombre de verrous actifs }
  Next: Pointer;                { Pointeur vers l'entrÇe suivante }
 End;

 { Structure de verrou de fichier }
 TFileLock = Record
  FileEntry: Pointer;           { Pointeur vers l'entrÇe de fichier }
  StartOffset: LongInt;         { Offset de dÇbut du verrou }
  Length: LongInt;              { Longueur de la rÇgion verrouillÇe }
  ProcessID: Word;              { ID du processus propriÇtaire }
  MachineID: Word;              { ID de la machine }
  LockType: Byte;               { Type de verrou (lecture/Çcriture) }
  Next: Pointer;                { Pointeur vers le verrou suivant }
 End;

 { Structure de contrìle SHARE TSR }
 TShareControl = Record
  Signature: Array[0..5] of Char; { Signature 'SHARE' }
  Installed: Boolean;           { Flag d'installation }
  FileSpace: Word;              { Espace allouÇ pour les informations }
  MaxLocks: Word;               { Nombre maximum de verrous }
  CurrentLocks: Word;           { Nombre de verrous actuels }
  FileListHead: Pointer;        { Tàte de liste des fichiers partagÇs }
  LockListHead: Pointer;        { Tàte de liste des verrous }
  MachineName: Array[0..MAX_MACHINE_NAME] of Char; { Nom de la machine }
  OldInt2FHandler: Pointer;     { Ancien gestionnaire INT 2Fh }
  OldInt21Handler: Pointer;     { Ancien gestionnaire INT 21h }
 End;

Var
 Language:(_French,_English,_Germany,_Italian,_Spain,_Albanian,_Portuguese,_Swedish,_Danish,_Japanese);
 TmpLanguage: String;
 ShareControl: TShareControl;
 IsInstalled: Boolean;
 FileSpace: Word;
 MaxLocks: Word;
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

 { Convertir un entier en cha√Æne }
Function IntToStr(Value: Integer): String;
Var
 S: String;
Begin
 Str(Value, S);
 IntToStr := S;
End;

 { Convertir une chaåne en entier }
Function StrToInt(S: String): Integer;
Var
 Result, Code: Integer;
Begin
 Val(S, Result, Code);
 If Code <> 0 Then Result := 0;
 StrToInt := Result;
End;

{ Obtenir le message d'erreur selon la langue }
Function GetErrorMessage(Code: Word): String;Begin
 Case Language Of
  _English: Case Code Of
   ERR_FILE_NOT_FOUND: GetErrorMessage := 'File not found';
   ERR_ACCESS_DENIED: GetErrorMessage := 'Access denied';
   ERR_NOT_ENOUGH_MEMORY: GetErrorMessage := 'Not enough memory';
   ERR_INVALID_PARAMETER: GetErrorMessage := 'Invalid parameter';
   ERR_INVALID_FORMAT: GetErrorMessage := 'Invalid format';
   Else GetErrorMessage := 'Error ' + IntToStr(Code);
  End;
  _Germany: Case Code Of
   ERR_FILE_NOT_FOUND: GetErrorMessage := 'Datei nicht gefunden';
   ERR_ACCESS_DENIED: GetErrorMessage := 'Zugriff verweigert';
   ERR_NOT_ENOUGH_MEMORY: GetErrorMessage := 'Nicht genug Speicher';
   ERR_INVALID_PARAMETER: GetErrorMessage := 'UngÅltiger Parameter';
   ERR_INVALID_FORMAT: GetErrorMessage := 'UngÅltiges Format';
   Else GetErrorMessage := 'Fehler ' + IntToStr(Code);
  End;
  Else { Fran√ßais par d√©faut }
   Case Code Of
    ERR_FILE_NOT_FOUND: GetErrorMessage := 'Fichier introuvable';
    ERR_ACCESS_DENIED: GetErrorMessage := 'Accäs refusÇ';
    ERR_NOT_ENOUGH_MEMORY: GetErrorMessage := 'MÇmoire insuffisante';
    ERR_INVALID_PARAMETER: GetErrorMessage := 'Paramätre invalide';
    ERR_INVALID_FORMAT: GetErrorMessage := 'Format invalide';
    Else GetErrorMessage := 'Erreur ' + IntToStr(Code);
   End;
 End;
End;

{ VÇrifier si SHARE est dÇjÖ installÇ }
Function IsShareInstalled: Boolean;
Var
 Regs: Registers;
Begin
 Regs.AH := SHARE_MULTIPLEX;
 Regs.AL := SHARE_INSTALL_CHECK;
 Intr($2F, Regs);
 IsShareInstalled := (Regs.AL = $FF);
End;

 { Trouver une entrÇe de fichier partagÇ par nom }
Function FindSharedFile(FileName:String):Pointer;
Var
 Current: Pointer;
 Entry: TSharedFileEntry;
 Found: Boolean;
Begin
 FindSharedFile := Nil;
 Current := ShareControl.FileListHead;
 Found := False;
 While (Current <> Nil) And Not Found Do Begin
  Move(Current^,Entry,SizeOf(TSharedFileEntry));
  If StrToUpper(StrPas(Entry.FileName)) = StrToUpper(FileName) Then Begin
   FindSharedFile := Current;
   Found := True;
  End
   Else
  Begin
   Current := Entry.Next;
  End;
 End;
End;

 { Ajouter une nouvelle entrÇe de fichier partagÇ }
Function AddSharedFile(FileName: String; ShareMode, AccessMode: Byte;ProcessID: Word): Pointer;
Var
 NewEntry: Pointer;
 Entry: TSharedFileEntry;
Begin
 AddSharedFile := Nil;
  { Allouer mÇmoire pour la nouvelle entrÇe }
 GetMem(NewEntry, SizeOf(TSharedFileEntry));
 If NewEntry = Nil Then Exit;
  { Initialiser l'entrÇe }
 FillChar(Entry, SizeOf(TSharedFileEntry), 0);
 StrPCopy(Entry.FileName, Copy(FileName, 1, MAX_FILENAME_LENGTH-1));
 Entry.ShareMode := ShareMode;
 Entry.AccessMode := AccessMode;
 Entry.ProcessID := ProcessID;
 Entry.MachineID := 1; { ID machine local }
 Entry.RefCount := 1;
 Entry.LockCount := 0;
 Entry.Next := ShareControl.FileListHead;
  { Copier dans la mÇmoire allouÇe }
 Move(Entry, NewEntry^, SizeOf(TSharedFileEntry));
  { Mettre Ö jour la tàte de liste }
 ShareControl.FileListHead := NewEntry;
 AddSharedFile := NewEntry;
End;

 { VÇrifier les conflits de partage }
Function CheckShareConflict(FileName: String; ShareMode, AccessMode: Byte): Boolean;
Var
 FileEntry: Pointer;
 Entry: TSharedFileEntry;
Begin
 CheckShareConflict := False;
 FileEntry := FindSharedFile(FileName);
 If FileEntry <> Nil Then Begin
  Move(FileEntry^, Entry, SizeOf(TSharedFileEntry));
   { VÇrifier les conflits selon les modes de partage }
  Case Entry.ShareMode Of
   SHARE_DENY_ALL: CheckShareConflict := True;
   SHARE_DENY_READ: CheckShareConflict := (AccessMode And $03) <> 1; { Pas lecture seule }
   SHARE_DENY_WRITE: CheckShareConflict := (AccessMode And $03) <> 0; { Pas Çcriture }
   SHARE_DENY_NONE: CheckShareConflict := False;
   Else { Mode de compatibilitÇ }
    CheckShareConflict := (Entry.ProcessID <> GetPID) Or (AccessMode <> Entry.AccessMode);
  End;
 End;
End;

{ Ajouter un verrou de fichier }
Function AddFileLock(FileEntry: Pointer; StartOffset, Length: LongInt;
                    ProcessID: Word; LockType: Byte): Boolean;
Var
 NewLock: Pointer;
 Lock: TFileLock;
Begin
 AddFileLock := False;
  { VÇrifier si le maximum de verrous n'est pas atteint }
 If ShareControl.CurrentLocks >= ShareControl.MaxLocks Then Exit;
  { Allouer mÇmoire pour le nouveau verrou }
 GetMem(NewLock, SizeOf(TFileLock));
 If NewLock = Nil Then Exit;
  { Initialiser le verrou }
 FillChar(Lock, SizeOf(TFileLock), 0);
 Lock.FileEntry := FileEntry;
 Lock.StartOffset := StartOffset;
 Lock.Length := Length;
 Lock.ProcessID := ProcessID;
 Lock.MachineID := 1;
 Lock.LockType := LockType;
 Lock.Next := ShareControl.LockListHead;
  { Copier dans la mÇmoire allouÇe }
 Move(Lock, NewLock^, SizeOf(TFileLock));
  { Mettre Ö jour les listes }
 ShareControl.LockListHead := NewLock;
 Inc(ShareControl.CurrentLocks);
 AddFileLock := True;
End;

 { VÇrifier les conflits de verrous }
Function CheckLockConflict(FileEntry: Pointer; StartOffset, Length: LongInt;LockType: Byte): Boolean;
Var
 Current: Pointer;
 Lock: TFileLock;
 EndOffset, LockEndOffset: LongInt;
Begin
 CheckLockConflict := False;
 Current := ShareControl.LockListHead;
 EndOffset := StartOffset + Length - 1;
 While Current <> Nil Do Begin
  Move(Current^, Lock, SizeOf(TFileLock));
  If Lock.FileEntry = FileEntry Then Begin
   LockEndOffset := Lock.StartOffset + Lock.Length - 1;
    { VÇrifier le chevauchement }
   If Not ((EndOffset < Lock.StartOffset) Or (StartOffset > LockEndOffset)) Then Begin
    { Il y a chevauchement - vÇrifier le type de conflit }
    If (LockType = 1) And (Lock.LockType = 1) Then Begin
     { Deux verrous en lecture - pas de conflit }
     CheckLockConflict := False;
    End
     Else
    Begin
     { Au moins un verrou en Çcriture - conflit }
     CheckLockConflict := True;
     Exit;
    End;
   End;
  End;
  Current := Lock.Next;
 End;
End;

 { Gestionnaire d'interruption INT 21h pour intercepter les appels de partage }
{$F+}
Procedure ShareInt21Handler;
{$F-}
{$IFNDEF FPC}
Var
 SavedAX, SavedBX, SavedCX, SavedDX: Word;
Begin
 Asm
  Mov SavedAX, AX
  Mov SavedBX, BX
  Mov SavedCX, CX
  Mov SavedDX, DX
 End;
  { VÇrifier les fonctions de verrouillage de fichier }
 Case SavedAX Shr 8 Of
  $5C: Begin { Verrouiller/DÇverrouiller rÇgion de fichier }
   Case SavedAX And $FF Of
    $00: Begin { Verrouiller }
     { ImplÇmenter la logique de verrouillage }
     Asm
      Mov AX, ERR_SUCCESS
     End;
    End;
    $01: Begin { DÇverrouiller }
     { ImplÇmenter la logique de dÇverrouillage }
     Asm
      Mov AX, ERR_SUCCESS
     End;
    End;
    Else Begin
     { Passer Ö l'ancien gestionnaire }
     Asm
      Mov AX, SavedAX
      Mov BX, SavedBX
      Mov CX, SavedCX
      Mov DX, SavedDX
      Pushf
      Call ShareControl.OldInt21Handler
     End;
     Exit;
    End;
   End;
   Asm
    Iret
   End;
  End;
  Else Begin
   { Autre fonction - passer Ö l'ancien gestionnaire }
   Asm
    Mov AX, SavedAX
    Mov BX, SavedBX
    Mov CX, SavedCX
    Mov DX, SavedDX
    Pushf
    Call ShareControl.OldInt21Handler
   End;
  End;
 End;
End;
{$ELSE}
Begin
 { Version simplifiÇe pour Free Pascal }
End;
{$ENDIF}

{ Gestionnaire d'interruption INT 2Fh pour SHARE }
{$F+}
Procedure ShareInt2FHandler;
{$F-}
{$IFNDEF FPC}
Var
 SavedAX, SavedBX, SavedCX, SavedDX: Word;
Begin
 Asm
  Mov SavedAX, AX
  Mov SavedBX, BX
  Mov SavedCX, CX
  Mov SavedDX, DX
 End;
 If (SavedAX Shr 8) = SHARE_MULTIPLEX Then Begin
  Case (SavedAX And $FF) Of
   SHARE_INSTALL_CHECK: Begin
    Asm
     Mov AL, $FF  { Signaler que SHARE est installÇ }
    End;
   End;
   SHARE_GET_MACHINE_NAME: Begin
    { Retourner le nom de la machine }
    Asm
     Mov AX, ERR_SUCCESS
    End;
   End;
   Else Begin
    Asm
     Mov AX, ERR_INVALID_FUNCTION
    End;
   End;
  End;
  Asm
   Iret
  End;
 End Else Begin
  { Autre fonction multiplex - passer Ö l'ancien gestionnaire }
  Asm
   Mov AX, SavedAX
   Mov BX, SavedBX
   Mov CX, SavedCX
   Mov DX, SavedDX
   Pushf
   Call ShareControl.OldInt2FHandler
  End;
 End;
End;
{$ELSE}
Begin
 { Version simplifiÇe pour Free Pascal }
End;
{$ENDIF}

{ Installer SHARE en mÇmoire rÇsidente }
Procedure InstallShare;Begin
 { Initialiser la structure de contrìle }
 Move(SHARE_SIGNATURE[1], ShareControl.Signature, Length(SHARE_SIGNATURE));
 ShareControl.Installed := True;
 ShareControl.FileSpace := FileSpace;
 ShareControl.MaxLocks := MaxLocks;
 ShareControl.CurrentLocks := 0;
 ShareControl.FileListHead := Nil;
 ShareControl.LockListHead := Nil;
  { Initialiser le nom de machine par dÇfaut }
 FillChar(ShareControl.MachineName, MAX_MACHINE_NAME + 1, 0);
 StrPCopy(ShareControl.MachineName, 'PC');
  { Sauvegarder les anciens gestionnaires d'interruption }
 GetIntVec($21, ShareControl.OldInt21Handler);
 GetIntVec($2F, ShareControl.OldInt2FHandler);
  { Installer les nouveaux gestionnaires }
 SetIntVec($21, @ShareInt21Handler);
 SetIntVec($2F, @ShareInt2FHandler);
  { Marquer comme installÇ }
 IsInstalled := True;
End;

 { DÇsinstaller SHARE }
Procedure UninstallShare;Begin
 If IsInstalled Then Begin
   { Restaurer les anciens gestionnaires d'interruption }
  SetIntVec($21, ShareControl.OldInt21Handler);
  SetIntVec($2F, ShareControl.OldInt2FHandler);
   { LibÇrer la mÇmoire allouÇe }
   { (Dans une vraie implÇmentation, il faudrait parcourir les listes) }
  IsInstalled := False;
 End;
End;

 { Afficher l'Çtat de SHARE }
Procedure ShowStatus;Begin
 Case Language Of
  _English: Begin
   WriteLn('SHARE Status:');
   If IsShareInstalled Then Begin
    WriteLn('  Status: Installed and active');
    WriteLn('  File space allocated: ', ShareControl.FileSpace, ' bytes');
    WriteLn('  Maximum locks: ', ShareControl.MaxLocks);
    WriteLn('  Current locks: ', ShareControl.CurrentLocks);
    WriteLn('  Machine name: ', StrPas(ShareControl.MachineName));
   End Else Begin
    WriteLn('  Status: Not installed');
   End;
  End;
  _Germany: Begin
   WriteLn('SHARE-Status:');
   If IsShareInstalled Then Begin
    WriteLn('  Status: Installiert und aktiv');
    WriteLn('  Dateispeicher zugewiesen: ', ShareControl.FileSpace, ' Bytes');
    WriteLn('  Maximale Sperren: ', ShareControl.MaxLocks);
    WriteLn('  Aktuelle Sperren: ', ShareControl.CurrentLocks);
    WriteLn('  Maschinenname: ', StrPas(ShareControl.MachineName));
   End Else Begin
    WriteLn('  Status: Nicht installiert');
   End;
  End;
  Else Begin { Fran√ßais }
   WriteLn('êtat de SHARE:');
   If IsShareInstalled Then Begin
    WriteLn('  êtat: InstallÇ et actif');
    WriteLn('  Espace fichier allouÇ: ', ShareControl.FileSpace, ' octets');
    WriteLn('  Verrous maximum: ', ShareControl.MaxLocks);
    WriteLn('  Verrous actuels: ', ShareControl.CurrentLocks);
    WriteLn('  Nom de machine: ', StrPas(ShareControl.MachineName));
   End
    Else
   Begin
    WriteLn('  êtat: Non installÇ');
   End;
  End;
 End;
End;

{ Analyser un paramätre /F: ou /L: }
Function ParseParameter(Param: String; var Value: Word): Boolean;
Var
 ColonPos: Byte;
 ValueStr: String;
Begin
 ParseParameter := False;
 ColonPos := Pos(':', Param);
 If ColonPos > 0 Then Begin
  ValueStr := Copy(Param, ColonPos + 1, Length(Param) - ColonPos);
  Value := StrToInt(ValueStr);
  ParseParameter := (Value > 0);
 End;
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
 IsInstalled := False;
 FileSpace := DEFAULT_FILE_SPACE;
 MaxLocks := DEFAULT_LOCK_COUNT;
 FillChar(ShareControl, SizeOf(TShareControl), 0);
  { Traitement des param√®tres de ligne de commande }
 For I := 1 to ParamCount do Begin
  Param := StrToUpper(ParamStr(I));
   If (Param = '/?') Or (Param = '/H') Or (Param = '-H') Or (Param = '--HELP') Then Begin
   Case Language Of
    _English: Begin
     WriteLn('SHARE - File Sharing and Locking');
     WriteLn;
     WriteLn('Installs file-sharing and locking capabilities on your hard disk.');
     WriteLn;
     WriteLn('SHARE [/F:space] [/L:locks]');
     WriteLn;
     WriteLn('  /F:space   Allocates file space (in bytes) for file-sharing information');
     WriteLn('             (default: ', DEFAULT_FILE_SPACE, ')');
     WriteLn('  /L:locks   Sets the number of files that can be locked at one time');
     WriteLn('             (default: ', DEFAULT_LOCK_COUNT, ')');
     WriteLn;
     WriteLn('Options:');
     WriteLn('  /?         Display this help');
     WriteLn('  /U         Uninstall SHARE from memory');
     WriteLn('  /S         Show current status');
    End;
    _Germany: Begin
     WriteLn('SHARE - Dateifreigabe und -sperrung');
     WriteLn;
     WriteLn('Installiert Dateifreigabe- und Sperrfunktionen auf Ihrer Festplatte.');
     WriteLn;
     WriteLn('SHARE [/F:speicher] [/L:sperren]');
     WriteLn;
     WriteLn('  /F:speicher  Weist Dateispeicher (in Bytes) fÅr Dateifreigabe zu');
     WriteLn('               (Standard: ', DEFAULT_FILE_SPACE, ')');
     WriteLn('  /L:sperren   Setzt die Anzahl der Dateien, die gleichzeitig gesperrt werden kînnen');
     WriteLn('               (Standard: ', DEFAULT_LOCK_COUNT, ')');
     WriteLn;
     WriteLn('Optionen:');
     WriteLn('  /?         Diese Hilfe anzeigen');
     WriteLn('  /U         SHARE aus dem Speicher entfernen');
     WriteLn('  /S         Aktuellen Status anzeigen');
    End;
    Else Begin { Franáais }
     WriteLn('SHARE - Partage et verrouillage de fichiers');
     WriteLn;
     WriteLn('Cette commande permet d''effectuer la gestion du partage des fichiers');
     WriteLn('entre logiciel et programme multitÉche.');
     WriteLn;
     WriteLn('SHARE [/F:espace] [/L:verrous]');
     WriteLn;
     WriteLn('  /F:espace   Alloue l''espace (en octets) pour les informations de partage');
     WriteLn('              (dÇfaut: ', DEFAULT_FILE_SPACE, ')');
     WriteLn('  /L:verrous  DÇfinit le nombre de fichiers pouvant àtre verrouillÇs');
     WriteLn('              simultanÇment (dÇfaut: ', DEFAULT_LOCK_COUNT, ')');
     WriteLn;
     WriteLn('Options:');
     WriteLn('  /?         Afficher cette aide');
     WriteLn('  /U         DÇsinstaller SHARE de la mÇmoire');
     WriteLn('  /S         Afficher l''Çtat actuel');
    End;
   End;
   Exit;
  End
  Else If (Copy(Param, 1, 3) = '/F:') Then Begin
   If Not ParseParameter(Param, FileSpace) Then Begin
    Case Language Of
     _English: WriteLn('Invalid file space parameter: ', Param);
     _Germany: WriteLn('UngÅltiger Dateispeicher-Parameter: ', Param);
     Else WriteLn('Paramätre d''espace fichier invalide: ', Param);
    End;
    Halt(1);
   End;
  End
  Else If (Copy(Param, 1, 3) = '/L:') Then Begin
   If Not ParseParameter(Param, MaxLocks) Then Begin
    Case Language Of
     _English: WriteLn('Invalid lock count parameter: ', Param);
     _Germany: WriteLn('UngÅltiger Sperren-Parameter: ', Param);
     Else WriteLn('Paramätre de nombre de verrous invalide: ', Param);
    End;
    Halt(1);
   End;
  End
  Else If (Param = '/U') Then Begin
   UninstallShare;
   Case Language Of
    _English: WriteLn('SHARE uninstalled from memory.');
    _Germany: WriteLn('SHARE aus dem Speicher entfernt.');
    Else WriteLn('SHARE dÇsinstallÇ de la mÇmoire.');
   End;
   Exit;
  End
  Else If (Param = '/S') Then Begin
   ShowStatus;
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
  { VÇrifier si SHARE est dÇjÖ installÇ }
 If IsShareInstalled Then Begin
  Case Language Of
   _English: WriteLn('SHARE is already installed in memory.');
   _Germany: WriteLn('SHARE ist bereits im Speicher installiert.');
   Else WriteLn('SHARE est dÇjÖ installÇ en mÇmoire.');
  End;
  Exit;
 End;
  { Valider les paramätres }
 If FileSpace < 512 Then Begin
  Case Language Of
   _English: WriteLn('File space must be at least 512 bytes.');
   _Germany: WriteLn('Dateispeicher muss mindestens 512 Bytes betragen.');
   Else WriteLn('L''espace fichier doit àtre d''au moins 512 octets.');
  End;
  Halt(1);
 End;
 If MaxLocks < 1 Then Begin
  Case Language Of
   _English: WriteLn('Lock count must be at least 1.');
   _Germany: WriteLn('Sperren-Anzahl muss mindestens 1 betragen.');
   Else WriteLn('Le nombre de verrous doit àtre d''au moins 1.');
  End;
  Halt(1);
 End;
  { Installer SHARE }
 InstallShare;
 Case Language Of
  _English: Begin
   WriteLn('SHARE installed successfully.');
   WriteLn('File space: ', FileSpace, ' bytes');
   WriteLn('Maximum locks: ', MaxLocks);
  End;
  _Germany: Begin
   WriteLn('SHARE erfolgreich installiert.');
   WriteLn('Dateispeicher: ', FileSpace, ' Bytes');
   WriteLn('Maximale Sperren: ', MaxLocks);
  End;
  Else Begin { Fran√ßais }
   WriteLn('SHARE installÇ avec succäs.');
   WriteLn('Espace fichier: ', FileSpace, ' octets');
   WriteLn('Verrous maximum: ', MaxLocks);
  End;
 End;
  { Rester rÇsident en mÇmoire }
 Keep(0);
END.
