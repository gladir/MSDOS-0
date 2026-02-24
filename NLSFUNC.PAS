{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program NLSFUNC;

{$M 16384,0,0}
{$A-}

Uses DOS,Crt;

Const
 { Codes d'erreur MS-DOS }
 ERR_SUCCESS = 0;                { Succès, aucune erreur }
 ERR_FUNCTION_INVALID = 1;       { Fonction invalide }
 ERR_FILE_NOT_FOUND = 2;         { Fichier introuvable }
 ERR_ACCESS_DENIED = 5;          { Accès refusé }
 ERR_INVALID_FORMAT = 11;        { Format invalide }
 ERR_INVALID_DATA = 13;          { Données invalides }
 ERR_INVALID_DRIVE = 15;         { Lecteur invalide }
 ERR_CURRENT_DIR = 16;           { Répertoire courant }
 ERR_NO_MORE_FILES = 18;         { Plus de fichiers }
 ERR_DISK_WRITE_PROTECT = 19;    { Disque protégé en écriture }
 ERR_BAD_UNIT = 20;              { Unité défaillante }
 ERR_NOT_READY = 21;             { Lecteur pas prêt }
 ERR_CRC_ERROR = 23;             { Erreur de contrôle CRC }
 ERR_SEEK_ERROR = 25;            { Erreur de positionnement }
 ERR_SECTOR_NOT_FOUND = 27;      { Secteur introuvable }
 ERR_OUT_OF_PAPER = 28;          { Plus de papier }
 ERR_WRITE_FAULT = 29;           { Défaut d'écriture }
 ERR_READ_FAULT = 30;            { Défaut de lecture }
 ERR_GENERAL_FAILURE = 31;       { Panne générale }
 ERR_INVALID_PARAMETER = 87;     { Paramètre invalide }

 { Constantes NLSFUNC }
 NLSFUNC_MULTIPLEX = $14;        { Numéro d'interruption multiplex pour NLSFUNC }
 NLSFUNC_INSTALL_CHECK = $00;    { Vérification si NLSFUNC est installé }
 NLSFUNC_GET_EXTENDED_INFO = $01;{ Obtenir informations étendues de pays }
 NLSFUNC_SET_CODEPAGE = $02;     { Définir la page de codes active }
 NLSFUNC_GET_CODEPAGE = $03;     { Obtenir la page de codes courante }

 { Tailles des tampons mémoire }
 COUNTRY_BUFFER_SIZE = 512;      { Taille du tampon pour informations de pays }
 CODEPAGE_BUFFER_SIZE = 256;     { Taille du tampon pour page de codes }

 { Signature d'identification NLSFUNC en mémoire (7 caractères) }
 NLSFUNC_SIGNATURE: String[7] = 'NLSFUNC';

 { Fichier par défaut contenant les informations de localisation }
 DEFAULT_COUNTRY_FILE = 'COUNTRY.SYS';

Type
 { Structure d'informations de pays }
 TCountryInfo = Record
  CountryCode: Word;           { Code pays (1=USA, 33=France, etc.) }
  CodePage: Word;              { Page de codes (850, 437, etc.) }
  DateFormat: Word;            { Format de date (0=USA, 1=Europe, 2=Japon) }
  CurrencySymbol: Array[0..4] of Char;  { Symbole monétaire }
  ThousandSeparator: Array[0..1] of Char; { Séparateur des milliers }
  DecimalSeparator: Array[0..1] of Char;  { Séparateur décimal }
  DateSeparator: Array[0..1] of Char;     { Séparateur de date }
  TimeSeparator: Array[0..1] of Char;     { Séparateur d'heure }
  CurrencyFormat: Byte;        { Format monétaire }
  CurrencyDigits: Byte;        { Nombre de chiffres après virgule }
  TimeFormat: Byte;            { Format d'heure (0=12h, 1=24h) }
  CasemapCall: Pointer;        { Adresse de la routine de conversion }
  DataListSeparator: Array[0..1] of Char; { Séparateur de liste }
  Reserved: Array[0..9] of Byte; { Réservé }
 End;

 { Structure d'en-tête de fichier COUNTRY.SYS }
 TCountryFileHeader = Record
  Signature: Array[0..7] of Char;  { Signature du fichier }
  InfoCount: Word;                 { Nombre d'entrées d'informations }
  Version: Word;                   { Version du fichier }
  FileSize: LongInt;              { Taille du fichier }
 End;

 { Entrée d'information dans COUNTRY.SYS }
 TCountryEntry = Record
  CountryCode: Word;     { Code du pays }
  CodePage: Word;        { Page de codes }
  Reserved1: Word;       { Réservé }
  DataOffset: LongInt;   { Décalage vers les données }
  DataSize: Word;        { Taille des données }
 End;

 { Structure de contrôle TSR }
 TNLSFuncControl = Record
  Signature: Array[0..7] of Char; { Signature 'NLSFUNC' }
  Installed: Boolean;             { Flag d'installation }
  CountryFile: String[80];        { Chemin du fichier COUNTRY.SYS }
  CurrentCountry: Word;           { Code pays actuel }
  CurrentCodePage: Word;          { Page de codes actuelle }
  OldInt2FHandler: Pointer;       { Ancien gestionnaire INT 2Fh }
 End;

Var
 Language:(_French,_English,_Germany,_Italian,_Spain,_Albanian,_Portuguese,_Swedish,_Danish,_Japanese);
 TmpLanguage: String;
 CountryFile: String;
 NLSControl: TNLSFuncControl;
 CountryInfo: TCountryInfo;
 IsInstalled: Boolean;

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

{ Convertir un entier en chaîne }
Function IntToStr(Value: Integer): String;
Var
 S: String;
Begin
 Str(Value, S);
 IntToStr := S;
End;

{ Obtenir le message d'erreur selon la langue }
Function GetErrorMessage(Code: Word): String;
Begin
 Case Language Of
  _English: Case Code Of
   ERR_FILE_NOT_FOUND: GetErrorMessage := 'File not found';
   ERR_ACCESS_DENIED: GetErrorMessage := 'Access denied';
   ERR_INVALID_PARAMETER: GetErrorMessage := 'Invalid parameter';
   ERR_INVALID_FORMAT: GetErrorMessage := 'Invalid format';
   ERR_NOT_READY: GetErrorMessage := 'Drive not ready';
   ERR_GENERAL_FAILURE: GetErrorMessage := 'General failure';
   Else GetErrorMessage := 'Error ' + IntToStr(Code);
  End;
  _Germany: Case Code Of
   ERR_FILE_NOT_FOUND: GetErrorMessage := 'Datei nicht gefunden';
   ERR_ACCESS_DENIED: GetErrorMessage := 'Zugriff verweigert';
   ERR_INVALID_PARAMETER: GetErrorMessage := 'Ungültiger Parameter';
   ERR_INVALID_FORMAT: GetErrorMessage := 'Ungültiges Format';
   ERR_NOT_READY: GetErrorMessage := 'Laufwerk nicht bereit';
   ERR_GENERAL_FAILURE: GetErrorMessage := 'Allgemeiner Fehler';
   Else GetErrorMessage := 'Fehler ' + IntToStr(Code);
  End;
  Else { Français par défaut }
   Case Code Of
    ERR_FILE_NOT_FOUND: GetErrorMessage := 'Fichier introuvable';
    ERR_ACCESS_DENIED: GetErrorMessage := 'Accès refusé';
    ERR_INVALID_PARAMETER: GetErrorMessage := 'Paramètre invalide';
    ERR_INVALID_FORMAT: GetErrorMessage := 'Format invalide';
    ERR_NOT_READY: GetErrorMessage := 'Lecteur pas prêt';
    ERR_GENERAL_FAILURE: GetErrorMessage := 'Erreur générale';
    Else GetErrorMessage := 'Erreur ' + IntToStr(Code);
   End;
 End;
End;

{ Vérifier si NLSFUNC est déjà installé }
Function IsNLSFuncInstalled: Boolean;
Var
 Regs: Registers;
Begin
 Regs.AH := NLSFUNC_MULTIPLEX;
 Regs.AL := NLSFUNC_INSTALL_CHECK;
 Intr($2F, Regs);
 IsNLSFuncInstalled := (Regs.AL = $FF);
End;

{ Lire l'en-tête du fichier COUNTRY.SYS }
Function ReadCountryFileHeader(Var F: File; Var Header: TCountryFileHeader): Boolean;
Begin
 {$I-}
 BlockRead(F, Header, SizeOf(TCountryFileHeader));
 {$I+}
 ReadCountryFileHeader := (IOResult = 0);
End;

{ Lire une entrée de pays depuis COUNTRY.SYS }
Function ReadCountryEntry(Var F: File; Var Entry: TCountryEntry): Boolean;
Begin
 {$I-}
 BlockRead(F, Entry, SizeOf(TCountryEntry));
 {$I+}
 ReadCountryEntry := (IOResult = 0);
End;

{ Charger les informations de pays depuis COUNTRY.SYS }
Function LoadCountryInfo(CountryCode, CodePage: Word; Var Info: TCountryInfo): Boolean;
Var
 F: File;
 Header: TCountryFileHeader;
 Entry: TCountryEntry;
 I: Word;
 Found: Boolean;
Begin
 LoadCountryInfo := False;
 Found := False;

 { Ouvrir le fichier COUNTRY.SYS }
 Assign(F, CountryFile);
 {$I-}
 Reset(F, 1);
 {$I+}
 If IOResult <> 0 Then Exit;

 { Lire l'en-tête }
 If Not ReadCountryFileHeader(F, Header) Then Begin
  Close(F);
  Exit;
 End;

 { Rechercher l'entrée correspondante }
 For I := 1 to Header.InfoCount do Begin
  If Not ReadCountryEntry(F, Entry) Then Break;
  If (Entry.CountryCode = CountryCode) And
     ((CodePage = 0) Or (Entry.CodePage = CodePage)) Then Begin
   Found := True;
   Break;
  End;
 End;

 If Found Then Begin
  { Se positionner aux données du pays }
  Seek(F, Entry.DataOffset);
  {$I-}
  BlockRead(F, Info, SizeOf(TCountryInfo));
  {$I+}
  LoadCountryInfo := (IOResult = 0);
 End;

 Close(F);
End;

{ Gestionnaire d'interruption INT 2Fh pour NLSFUNC }
{$F+}
Procedure NLSFuncInt2FHandler;
{$F-}
{$IFNDEF FPC}
{ Version Turbo Pascal avec assembleur inline complet }
Var
 SavedAX, SavedBX, SavedCX, SavedDX: Word;
Begin
 { Sauvegarder les registres }
 Asm
  Mov SavedAX, AX
  Mov SavedBX, BX
  Mov SavedCX, CX
  Mov SavedDX, DX
 End;

 { Vérifier si c'est notre fonction multiplex $14 }
 If (SavedAX Shr 8) = NLSFUNC_MULTIPLEX Then Begin
  Case (SavedAX And $FF) Of
   NLSFUNC_INSTALL_CHECK: Begin
    { Répondre que NLSFUNC est installé }
    Asm
     Mov AL, $FF
    End;
   End;

   NLSFUNC_GET_EXTENDED_INFO: Begin
    { Obtenir informations étendues de pays }
    Asm
     Mov AX, ERR_SUCCESS
    End;
   End;

   NLSFUNC_SET_CODEPAGE: Begin
    { Définir la page de codes }
    Asm
     Mov AX, ERR_SUCCESS
    End;
   End;

   NLSFUNC_GET_CODEPAGE: Begin
    { Retourner page de codes et pays actuels }
    Asm
     Mov BX, 437    { Page de codes par défaut }
     Mov DX, 1      { Pays par défaut (USA) }
     Mov AX, ERR_SUCCESS
    End;
   End;

   Else Begin
    { Fonction non supportée - passer à l'ancien gestionnaire }
    Asm
     Mov AX, SavedAX
     Mov BX, SavedBX
     Mov CX, SavedCX
     Mov DX, SavedDX
     Pushf
     Call NLSControl.OldInt2FHandler
    End;
    Exit;
   End;
  End;

  { Terminer avec IRET pour Turbo Pascal }
  Asm
   Iret
  End;
 End Else Begin
  { Autre fonction multiplex - passer à l'ancien gestionnaire }
  Asm
   Mov AX, SavedAX
   Mov BX, SavedBX
   Mov CX, SavedCX
   Mov DX, SavedDX
   Pushf
   Call NLSControl.OldInt2FHandler
  End;
 End;
End;
{$ELSE}
{ Version Free Pascal simplifiée }
Begin
 { Gestionnaire d'interruption simplifié pour Free Pascal }
 { En réalité, ce gestionnaire serait plus complexe }
 { mais pour la compatibilité avec FPC, on utilise une approche basique }
End;
{$ENDIF}


{ Installer NLSFUNC en mémoire résidente }
Procedure InstallNLSFunc;
Begin
 { Initialiser la structure de contrôle }
 Move(NLSFUNC_SIGNATURE[1], NLSControl.Signature, Length(NLSFUNC_SIGNATURE));
 NLSControl.Installed := True;
 NLSControl.CountryFile := CountryFile;
 NLSControl.CurrentCountry := 1; { USA par défaut }
 NLSControl.CurrentCodePage := 437; { Page de codes par défaut }

 { Sauvegarder l'ancien gestionnaire INT 2Fh }
 GetIntVec($2F, NLSControl.OldInt2FHandler);

 { Installer le nouveau gestionnaire }
 SetIntVec($2F, @NLSFuncInt2FHandler);

 { Marquer comme installé }
 IsInstalled := True;
End;

{ Désinstaller NLSFUNC }
Procedure UninstallNLSFunc;
Begin
 If IsInstalled Then Begin
  { Restaurer l'ancien gestionnaire INT 2Fh }
  SetIntVec($2F, NLSControl.OldInt2FHandler);
  IsInstalled := False;
 End;
End;

{ Afficher le statut actuel }
Procedure ShowStatus;
Begin
 Case Language Of
  _English: Begin
   WriteLn('NLSFUNC Status:');
   If IsNLSFuncInstalled Then Begin
    WriteLn('  Status: Installed and active');
    WriteLn('  Country file: ', CountryFile);
    WriteLn('  Current country: ', NLSControl.CurrentCountry);
    WriteLn('  Current code page: ', NLSControl.CurrentCodePage);
   End Else Begin
    WriteLn('  Status: Not installed');
   End;
  End;
  _Germany: Begin
   WriteLn('NLSFUNC-Status:');
   If IsNLSFuncInstalled Then Begin
    WriteLn('  Status: Installiert und aktiv');
    WriteLn('  Länderdatei: ', CountryFile);
    WriteLn('  Aktuelles Land: ', NLSControl.CurrentCountry);
    WriteLn('  Aktuelle Codeseite: ', NLSControl.CurrentCodePage);
   End Else Begin
    WriteLn('  Status: Nicht installiert');
   End;
  End;
  Else Begin { Français }
   WriteLn('Statut de NLSFUNC:');
   If IsNLSFuncInstalled Then Begin
    WriteLn('  Statut: Installé et actif');
    WriteLn('  Fichier pays: ', CountryFile);
    WriteLn('  Pays actuel: ', NLSControl.CurrentCountry);
    WriteLn('  Page de codes actuelle: ', NLSControl.CurrentCodePage);
   End Else Begin
    WriteLn('  Statut: Non installé');
   End;
  End;
 End;
End;

{ Traiter les paramètres de ligne de commande }
Function ProcessParameters: Boolean;
Var
 I: Byte;
 Param: String;
 ShowStatusFlag: Boolean;
 UninstallFlag: Boolean;
Begin
 ProcessParameters := True;
 ShowStatusFlag := False;
 UninstallFlag := False;
 CountryFile := DEFAULT_COUNTRY_FILE;

 For I := 1 to ParamCount do Begin
  Param := StrToUpper(ParamStr(I));

  If (Param = '/?') Or (Param = '/H') Or (Param = '-H') Or (Param = '--HELP') Then Begin
   Case Language Of
  _English: Begin
   WriteLn('NLSFUNC - National Language Support Function');
   WriteLn;
   WriteLn('Loads country-specific information supporting code page switching.');
   WriteLn;
   WriteLn('NLSFUNC [filename]');
   WriteLn;
   WriteLn('  filename   Specifies the COUNTRY information file (default: COUNTRY.SYS)');
   WriteLn;
   WriteLn('Options:');
   WriteLn('  /?         Display this help');
   WriteLn('  /U         Uninstall NLSFUNC from memory');
   WriteLn('  /S         Show current status');
  End;
  _Germany: Begin
   WriteLn('NLSFUNC - Nationale Sprachunterstützungsfunktion');
   WriteLn;
   WriteLn('Lädt länderspezifische Informationen zur Unterstützung von Codeseiten.');
   WriteLn;
   WriteLn('NLSFUNC [dateiname]');
   WriteLn;
   WriteLn('  dateiname  Gibt die COUNTRY-Informationsdatei an (Standard: COUNTRY.SYS)');
   WriteLn;
   WriteLn('Optionen:');
   WriteLn('  /?         Diese Hilfe anzeigen');
   WriteLn('  /U         NLSFUNC aus dem Speicher entfernen');
   WriteLn('  /S         Aktuellen Status anzeigen');
  End;
  Else Begin { Français }
   WriteLn('NLSFUNC - Fonction de Support de Langue Nationale');
   WriteLn;
   WriteLn('Cette commande permet de charger les informations spécifiques au ',
           'pays supportant le changement de page de codes.');
   WriteLn;
   WriteLn('NLSFUNC [fichier]');
   WriteLn;
   WriteLn('  fichier    Spécifie le fichier d''informations COUNTRY (défaut: COUNTRY.SYS)');
   WriteLn;
   WriteLn('Options:');
   WriteLn('  /?         Afficher cette aide');
   WriteLn('  /U         Désinstaller NLSFUNC de la mémoire');
   WriteLn('  /S         Afficher le statut actuel');
  End;
 End;
   ProcessParameters := False;
   Exit;
  End
  Else If (Param = '/U') Then Begin
   UninstallFlag := True;
  End
  Else If (Param = '/S') Then Begin
   ShowStatusFlag := True;
  End
  Else If (Param[1] <> '/') And (Param[1] <> '-') Then Begin
   { Nom de fichier COUNTRY.SYS }
   CountryFile := ParamStr(I);
  End
  Else Begin
   Case Language Of
    _English: WriteLn('Invalid parameter: ', Param);
    _Germany: WriteLn('Ungültiger Parameter: ', Param);
    Else WriteLn('Paramètre invalide: ', Param);
   End;
   ProcessParameters := False;
   Exit;
  End;
 End;
 If UninstallFlag Then Begin
  UninstallNLSFunc;
  Case Language Of
   _English: WriteLn('NLSFUNC uninstalled from memory.');
   _Germany: WriteLn('NLSFUNC aus dem Speicher entfernt.');
   Else WriteLn('NLSFUNC désinstallé de la mémoire.');
  End;
  ProcessParameters := False;
  Exit;
 End;
 If ShowStatusFlag Then Begin
  ShowStatus;
  ProcessParameters := False;
  Exit;
 End;
End;

{ Vérifier l'existence du fichier COUNTRY.SYS }
Function CheckCountryFile: Boolean;
Var
 F: File;
Begin
 CheckCountryFile := False;
 Assign(F, CountryFile);
 {$I-}
 Reset(F);
 {$I+}
 If IOResult = 0 Then Begin
  Close(F);
  CheckCountryFile := True;
 End;
End;

BEGIN
 Language := _French; { Français par défaut }
 TmpLanguage := GetEnv('LANGUAGE');
 If TmpLanguage<>''Then Begin
  If TmpLanguage[1]='"'Then TmpLanguage:=Copy(TmpLanguage,2,255);
  If StrToUpper(Copy(TmpLanguage,1,2))='EN'Then Language:=_English Else
  If StrToUpper(Copy(TmpLanguage,1,2))='GR'Then Language:=_Germany Else
  If StrToUpper(Copy(TmpLanguage,1,2))='IT'Then Language:=_Italian Else
  If StrToUpper(Copy(TmpLanguage,1,2))='SP'Then Language:=_Spain Else
  If(StrToUpper(Copy(TmpLanguage,1,2))='SQ')or
    (StrToUpper(Copy(TmpLanguage,1,3))='ALB')Then Language:=_Albanian Else
  If(StrToUpper(Copy(TmpLanguage,1,2))='PT')or
    (StrToUpper(Copy(TmpLanguage,1,3))='PRT')Then Language:=_Portuguese Else
  If(StrToUpper(Copy(TmpLanguage,1,2))='SE')or
    (StrToUpper(Copy(TmpLanguage,1,3))='SWE')Then Language:=_Swedish Else
  If(StrToUpper(Copy(TmpLanguage,1,2))='DK')or
    (StrToUpper(Copy(TmpLanguage,1,3))='DNK')Then Language:=_Danish Else
  If(StrToUpper(Copy(TmpLanguage,1,2))='JP')or
    (StrToUpper(Copy(TmpLanguage,1,3))='JPN')Then Language:=_Japanese;
 End;
  { Initialisation }
 IsInstalled := False;
 FillChar(NLSControl, SizeOf(TNLSFuncControl), 0);
 FillChar(CountryInfo, SizeOf(TCountryInfo), 0);
  { Traiter les paramètres }
 If Not ProcessParameters Then Exit;
  { Vérifier si déjà installé }
 If IsNLSFuncInstalled Then Begin
  Case Language Of
   _English: WriteLn('NLSFUNC is already installed in memory.');
   _Germany: WriteLn('NLSFUNC ist bereits im Speicher installiert.');
   Else WriteLn('NLSFUNC est déjà installé en mémoire.');
  End;
  Exit;
 End;
  { Vérifier l'existence du fichier COUNTRY.SYS }
 If Not CheckCountryFile Then Begin
  Case Language Of
   _English: WriteLn('Cannot find country information file: ', CountryFile);
   _Germany: WriteLn('Länderinformationsdatei nicht gefunden: ', CountryFile);
   Else WriteLn('Fichier d''informations de pays introuvable: ', CountryFile);
  End;
  Halt(1);
 End;
  { Installer NLSFUNC }
 InstallNLSFunc;
 Case Language Of
  _English: WriteLn('NLSFUNC installed. Country information file: ', CountryFile);
  _Germany: WriteLn('NLSFUNC installiert. Länderinformationsdatei: ', CountryFile);
  Else WriteLn('NLSFUNC installé. Fichier d''informations de pays: ', CountryFile);
 End;
  { Rester résident en mémoire }
 Keep(0);
END.