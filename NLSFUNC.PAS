{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program NLSFUNC;

{$M 16384,0,0}
{$A-}

Uses DOS;

Const
  { Codes d'erreur MS-DOS }
 ERR_SUCCESS = 0;                { Succäs, aucune erreur }
 ERR_FUNCTION_INVALID = 1;       { Fonction invalide }
 ERR_FILE_NOT_FOUND = 2;         { Fichier introuvable }
 ERR_ACCESS_DENIED = 5;          { Accäs refusÇ }
 ERR_INVALID_FORMAT = 11;        { Format invalide }
 ERR_INVALID_DATA = 13;          { DonnÇes invalides }
 ERR_INVALID_DRIVE = 15;         { Lecteur invalide }
 ERR_CURRENT_DIR = 16;           { RÇpertoire courant }
 ERR_NO_MORE_FILES = 18;         { Plus de fichiers }
 ERR_DISK_WRITE_PROTECT = 19;    { Disque protÇgÇ en Çcriture }
 ERR_BAD_UNIT = 20;              { UnitÇ dÇfaillante }
 ERR_NOT_READY = 21;             { Lecteur pas pràt }
 ERR_CRC_ERROR = 23;             { Erreur de contrìle CRC }
 ERR_SEEK_ERROR = 25;            { Erreur de positionnement }
 ERR_SECTOR_NOT_FOUND = 27;      { Secteur introuvable }
 ERR_OUT_OF_PAPER = 28;          { Plus de papier }
 ERR_WRITE_FAULT = 29;           { DÇfaut d'Çcriture }
 ERR_READ_FAULT = 30;            { DÇfaut de lecture }
 ERR_GENERAL_FAILURE = 31;       { Panne gÇnÇrale }
 ERR_INVALID_PARAMETER = 87;     { Paramätre invalide }

  { Constantes NLSFUNC }
 NLSFUNC_MULTIPLEX = $14;        { NumÇro d'interruption multiplex pour NLSFUNC }
 NLSFUNC_INSTALL_CHECK = $00;    { VÇrification si NLSFUNC est installÇ }
 NLSFUNC_GET_EXTENDED_INFO = $01;{ Obtenir informations Çtendues de pays }
 NLSFUNC_SET_CODEPAGE = $02;     { DÇfinir la page de codes active }
 NLSFUNC_GET_CODEPAGE = $03;     { Obtenir la page de codes courante }

 { Tailles des tampons mÇmoire }
 COUNTRY_BUFFER_SIZE = 512;      { Taille du tampon pour informations de pays }
 CODEPAGE_BUFFER_SIZE = 256;     { Taille du tampon pour page de codes }

  { Signature d'identification NLSFUNC en mÇmoire (7 caractäres) }
 NLSFUNC_SIGNATURE: String[7] = 'NLSFUNC';

  { Fichier par dÇfaut contenant les informations de localisation }
 DEFAULT_COUNTRY_FILE = 'COUNTRY.SYS';

Type
 { Structure d'informations de pays }
 TCountryInfo = Record
  CountryCode: Word;                      { Code pays (1=êtats-Unis, 33=France,...) }
  CodePage: Word;                         { Page de codes (850, 437, etc.) }
  DateFormat: Word;                       { Format de date (0=êtats-Unis, 1=Europe, 2=Japon) }
  CurrencySymbol: Array[0..4] of Char;    { Symbole monÇtaire }
  ThousandSeparator: Array[0..1] of Char; { SÇparateur des milliers }
  DecimalSeparator: Array[0..1] of Char;  { SÇparateur dÇcimal }
  DateSeparator: Array[0..1] of Char;     { SÇparateur de date }
  TimeSeparator: Array[0..1] of Char;     { SÇparateur d'heure }
  CurrencyFormat: Byte;                   { Format monÇtaire }
  CurrencyDigits: Byte;                   { Nombre de chiffres apräs virgule }
  TimeFormat: Byte;                       { Format d'heure (0=12h, 1=24h) }
  CasemapCall: Pointer;                   { Adresse de la routine de conversion }
  DataListSeparator: Array[0..1] of Char; { SÇparateur de liste }
  Reserved: Array[0..9] of Byte;          { RÇservÇ }
 End;

 { Structure d'entàte de fichier COUNTRY.SYS }
 TCountryFileHeader = Record
  Signature: Array[0..7] of Char;  { Signature du fichier }
  InfoCount: Word;                 { Nombre d'entrÇes d'informations }
  Version: Word;                   { Version du fichier }
  FileSize: LongInt;               { Taille du fichier }
 End;

 { EntrÇe d'information dans COUNTRY.SYS }
 TCountryEntry = Record
  CountryCode: Word;     { Code du pays }
  CodePage: Word;        { Page de codes }
  Reserved1: Word;       { RÇservÇ }
  DataOffset: LongInt;   { DÇcalage vers les donnÇes }
  DataSize: Word;        { Taille des donnÇes }
 End;

 { Structure de contrìle TSR }
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
 I: Byte;
 Param: String;
 ShowStatusFlag: Boolean;
 UninstallFlag: Boolean;

{ Convertir une chaåne de caractäres en majuscules }
Function StrToUpper(S: String): String;
Var
 I: Byte;
Begin
 For I := 1 to Length(S) do Begin
  If S[I] in ['a'..'z'] Then S[I] := Chr(Ord(S[I]) - 32);
 End;
 StrToUpper := S;
End;

 { Convertir un entier en chaåne de caractäres }
Function IntToStr(Value: Integer): String;
Var
 S: String;
Begin
 Str(Value, S);
 IntToStr := S;
End;

{ Obtenir le message d'erreur selon la langue }
Function GetErrorMessage(Code: Word): String;Begin
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
   ERR_INVALID_PARAMETER: GetErrorMessage := 'UngÅltiger Parameter';
   ERR_INVALID_FORMAT: GetErrorMessage := 'UngÅltiges Format';
   ERR_NOT_READY: GetErrorMessage := 'Laufwerk nicht bereit';
   ERR_GENERAL_FAILURE: GetErrorMessage := 'Allgemeiner Fehler';
   Else GetErrorMessage := 'Fehler ' + IntToStr(Code);
  End;
  Else { Franáais par dÇfaut }
   Case Code Of
    ERR_FILE_NOT_FOUND: GetErrorMessage := 'Fichier introuvable';
    ERR_ACCESS_DENIED: GetErrorMessage := 'Accäs refusÇ';
    ERR_INVALID_PARAMETER: GetErrorMessage := 'Paramätre invalide';
    ERR_INVALID_FORMAT: GetErrorMessage := 'Format invalide';
    ERR_NOT_READY: GetErrorMessage := 'Lecteur pas pràt';
    ERR_GENERAL_FAILURE: GetErrorMessage := 'Erreur gÇnÇrale';
    Else GetErrorMessage := 'Erreur ' + IntToStr(Code);
   End;
 End;
End;

 { VÇrifier si NLSFUNC est dÇjÖ installÇ }
Function IsNLSFuncInstalled: Boolean;
Var
 Regs: Registers;
Begin
 Regs.AH := NLSFUNC_MULTIPLEX;
 Regs.AL := NLSFUNC_INSTALL_CHECK;
 Intr($2F, Regs);
 IsNLSFuncInstalled := (Regs.AL = $FF);
End;

{ Lire l'entàte du fichier COUNTRY.SYS }
Function ReadCountryFileHeader(Var F: File; Var Header: TCountryFileHeader): Boolean;Begin
 {$I-}
 BlockRead(F, Header, SizeOf(TCountryFileHeader));
 {$I+}
 ReadCountryFileHeader := (IOResult = 0);
End;

{ Lire une entrÇe de pays depuis COUNTRY.SYS }
Function ReadCountryEntry(Var F: File; Var Entry: TCountryEntry): Boolean;Begin
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
 {$I-} Reset(F, 1); {$I+}
 If IOResult <> 0 Then Exit;
  { Lire l'entàte }
 If Not ReadCountryFileHeader(F, Header) Then Begin
  Close(F);
  Exit;
 End;
  { Rechercher l'entrÇe correspondante }
 For I := 1 to Header.InfoCount do Begin
  If Not ReadCountryEntry(F, Entry) Then Break;
  If (Entry.CountryCode = CountryCode) And
     ((CodePage = 0) Or (Entry.CodePage = CodePage)) Then Begin
   Found := True;
   Break;
  End;
 End;
 If Found Then Begin
  { Se positionner aux donnÇes du pays }
  Seek(F, Entry.DataOffset);
  {$I-} BlockRead(F, Info, SizeOf(TCountryInfo)); {$I+}
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
  { VÇrifier si c'est notre fonction multiplex $14 }
 If (SavedAX Shr 8) = NLSFUNC_MULTIPLEX Then Begin
  Case (SavedAX And $FF) Of
   NLSFUNC_INSTALL_CHECK: Begin
    { RÇpondre que NLSFUNC est installÇ }
    Asm
     Mov AL, $FF
    End;
   End;
   NLSFUNC_GET_EXTENDED_INFO: Begin
    { Obtenir informations Çtendues de pays }
    Asm
     Mov AX, ERR_SUCCESS
    End;
   End;
   NLSFUNC_SET_CODEPAGE: Begin
    { DÇfinir la page de codes }
    Asm
     Mov AX, ERR_SUCCESS
    End;
   End;
   NLSFUNC_GET_CODEPAGE: Begin
    { Retourner page de codes et pays actuels }
    Asm
     Mov BX, 437    { Page de codes par dÇfaut }
     Mov DX, 1      { Pays par dÇfaut (Etats-Unis) }
     Mov AX, ERR_SUCCESS
    End;
   End;
    Else Begin
    { Fonction non supportÇe - passer Ö l'ancien gestionnaire }
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
 End
  Else
 Begin
  { Autre fonction multiplex - passer Ö l'ancien gestionnaire }
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
{ Version Free Pascal simplifi√©e }
Begin
 { Gestionnaire d'interruption simplifiÇ pour Free Pascal }
 { En rÇalitÇ, ce gestionnaire serait plus complexe }
 { mais pour la compatibilitÇ avec FPC, on utilise une approche basique }
End;
{$ENDIF}

 { Installer NLSFUNC en mÇmoire rÇsidente }
Procedure InstallNLSFunc;Begin
 { Initialiser la structure de contrìle }
 Move(NLSFUNC_SIGNATURE[1], NLSControl.Signature, Length(NLSFUNC_SIGNATURE));
 NLSControl.Installed := True;
 NLSControl.CountryFile := CountryFile;
 NLSControl.CurrentCountry := 1; { êtats-Unis par dÇfaut }
 NLSControl.CurrentCodePage := 437; { Page de codes par dÇfaut }
 { Sauvegarder l'ancien gestionnaire INT 2Fh }
 GetIntVec($2F, NLSControl.OldInt2FHandler);
  { Installer le nouveau gestionnaire }
 SetIntVec($2F, @NLSFuncInt2FHandler);
  { Marquer comme installÇ }
 IsInstalled := True;
End;

{ DÇsinstaller NLSFUNC }
Procedure UninstallNLSFunc;Begin
 If IsInstalled Then Begin
  { Restaurer l'ancien gestionnaire INT 2Fh }
  SetIntVec($2F, NLSControl.OldInt2FHandler);
  IsInstalled := False;
 End;
End;

{ Afficher l'Çtat actuel }
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
   End
    Else
   Begin
    WriteLn('  Status: Not installed');
   End;
  End;
  _Germany: Begin
   WriteLn('NLSFUNC-Status:');
   If IsNLSFuncInstalled Then Begin
    WriteLn('  Status: Installiert und aktiv');
    WriteLn('  LÑnderdatei: ', CountryFile);
    WriteLn('  Aktuelles Land: ', NLSControl.CurrentCountry);
    WriteLn('  Aktuelle Codeseite: ', NLSControl.CurrentCodePage);
   End Else Begin
    WriteLn('  Status: Nicht installiert');
   End;
  End;
  Else Begin { Franáais }
   WriteLn('Statut de NLSFUNC:');
   If IsNLSFuncInstalled Then Begin
    WriteLn('  êtat: InstallÇ et actif');
    WriteLn('  Fichier pays: ', CountryFile);
    WriteLn('  Pays actuel: ', NLSControl.CurrentCountry);
    WriteLn('  Page de codes actuelle: ', NLSControl.CurrentCodePage);
   End
    Else
   Begin
    WriteLn('  êtat: Non installÇ');
   End;
  End;
 End;
End;

{ VÇrifier l'existence du fichier COUNTRY.SYS }
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
 Language := _French; { Franáais par dÇfaut }
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
  { Traitement des paramätres de ligne de commande }
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
      WriteLn('NLSFUNC - Nationale SprachunterstÅtzungsfunktion');
      WriteLn;
      WriteLn('LÑdt lÑnderspezifische Informationen zur UnterstÅtzung von Codeseiten.');
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
     Else Begin { Franáais }
      WriteLn('NLSFUNC - Fonction de Support de Langue Nationale');
      WriteLn;
      WriteLn('Cette commande permet de charger les informations sp√©cifiques au ',
              'pays supportant le changement de page de codes.');
      WriteLn;
      WriteLn('NLSFUNC [fichier]');
      WriteLn;
      WriteLn('  fichier    SpÇcifie le fichier d''informations COUNTRY (dÇfaut: COUNTRY.SYS)');
      WriteLn;
      WriteLn('Options:');
      WriteLn('  /?         Afficher cette aide');
      WriteLn('  /U         DÇsinstaller NLSFUNC de la mÇmoire');
      WriteLn('  /S         Afficher l''Çtat actuel');
     End;
    End;
    Exit;
   End
    Else
   If (Param = '/U') Then Begin
    UninstallFlag := True;
   End
    Else
   If (Param = '/S') Then Begin
    ShowStatusFlag := True;
   End
    Else
   If (Param[1] <> '/') And (Param[1] <> '-') Then Begin
    { Nom de fichier COUNTRY.SYS }
    CountryFile := ParamStr(I);
   End
    Else
   Begin
    Case Language Of
     _English: WriteLn('Invalid parameter: ', Param);
     _Germany: WriteLn('UngÅltiger Parameter: ', Param);
     Else WriteLn('Paramätre invalide: ', Param);
    End;
    Halt(1);
   End;
  End;
 If UninstallFlag Then Begin
  UninstallNLSFunc;
  Case Language Of
   _English: WriteLn('NLSFUNC uninstalled from memory.');
   _Germany: WriteLn('NLSFUNC aus dem Speicher entfernt.');
   Else WriteLn('NLSFUNC dÇsinstallÇ de la mÇmoire.');
  End;
  Exit;
 End;
 If ShowStatusFlag Then Begin
  ShowStatus;
  Exit;
 End;
  { VÇrifier si dÇjÖ installÇ }
 If IsNLSFuncInstalled Then Begin
  Case Language Of
   _English: WriteLn('NLSFUNC is already installed in memory.');
   _Germany: WriteLn('NLSFUNC ist bereits im Speicher installiert.');
   Else WriteLn('NLSFUNC est dÇjÖ installÇ en mÇmoire.');
  End;
  Exit;
 End;
  { VÇrifier l'existence du fichier COUNTRY.SYS }
 If Not CheckCountryFile Then Begin
  Case Language Of
   _English: WriteLn('Cannot find country information file: ', CountryFile);
   _Germany: WriteLn('LÑnderinformationsdatei nicht gefunden: ', CountryFile);
   Else WriteLn('Fichier d''informations de pays introuvable: ', CountryFile);
  End;
  Halt(1);
 End;
  { Installer NLSFUNC }
 InstallNLSFunc;
 Case Language Of
  _English: WriteLn('NLSFUNC installed. Country information file: ', CountryFile);
  _Germany: WriteLn('NLSFUNC installiert. LÑnderinformationsdatei: ', CountryFile);
  Else WriteLn('NLSFUNC installÇ. Fichier d''informations de pays: ', CountryFile);
 End;
  { Rester rÇsident en mÇmoire }
 Keep(0);
END.
