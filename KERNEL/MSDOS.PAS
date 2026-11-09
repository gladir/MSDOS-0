{ @author: Sylvain Maltais
  @created: 2026
  @website(https://www.gladir.com/msdos0)
  @description: Le MS Operating System est un systeme d'exploitation remplacant
    le DOS traditionnel.

  Directives de compilation pour compatibilite processeur :
  - CPU86  : Cible 8088/8086 (pas de PUSH immediate)
  - CPU286 : Cible 80286+ (PUSH immediate supporte)

  Pour compiler en mode 8088 compatible : $DEFINE CPU86

  Fonctions DOS implementees :
  - 00h : Terminer le programme
  - 01h : Entree de caractere avec echo
  - 02h : Sortie de caractere
  - 03h : Entree de caractere depuis AUX (port serie)
  - 04h : Sortie de caractere vers AUX (port serie)
  - 05h : Sortie de caractere vers PRN (imprimante)
  - 06h : Entree/sortie directe de console
  - 07h : Entree de caractere directe sans sortie
  - 08h : Entree de caractere sans sortie (avec Ctrl+C)
  - 09h : Affichage de chaine de caracteres terminer par $
  - 0Ah : Lecture de chaine avec buffer
  - 0Bh : l'etat d'entree
  - 0Ch : Vider le tampon et appeler la fonction d'entree
  - 0Dh : Reinitialisation du disque
  - 0Eh : Selectionne le lecteur courant
  - 0Fh : Ouvrir un fichier avec FCB
  - 10h : Fermer un fichier avec FCB
  - 11h : Rechercher le premier fichier avec FCB
  - 12h : Rechercher le fichier suivant avec FCB
  - 13h : Supprimer un fichier avec FCB
  - 14h : Lecture séquentielle avec FCB
  - 15h : Ecriture séquentielle avec FCB
  - 16h : Créer un fichier avec FCB
  - 17h : Renommer un fichier avec FCB
  - 18h : Fonction réservée
  - 19h : Demande le lecteur courant
  - 1Ah : Définir l'adresse DTA (Disk Transfer Area)
  - 1Bh : Obtenir les informations d'allocation du lecteur par défaut
  - 1Ch : Obtenir les informations d'allocation d'un lecteur spécifique
  - 1Dh : Fermer tous les fichiers (fonction non documentée)
  - 1Eh : Fonction réservée/non documentée
  - 1Fh : Fonction réservée/non documentée
  - 20h : Terminer le programme (obsolète)
  - 21h : Lecture aléatoire avec FCB
  - 22h : Ecriture aléatoire avec FCB
  - 23h : Obtenir la taille de fichier avec FCB
  - 24h : Définir l'adresse aléatoire avec FCB
  - 25h : Fixe le vecteur d'interruption
  - 26h : Créer un nouveau PSP (Program Segment Prefix)
  - 27h : Lecture aléatoire de bloc avec FCB
  - 28h : Ecriture aléatoire de bloc avec FCB
  - 29h : Analyser nom de fichier dans FCB
  - 2Ah : Lire la date
  - 2Bh : Fixe la date
  - 2Ch : Lire l'heure système
  - 2Dh : Fixer l'heure système
  - 2Eh : Fixer/réinitialiser le drapeau de vérification
  - 2Fh : DOS Multiplex Interrupt (interface TSR/utilitaires)
  - 30h : Get DOS Version (obtenir version DOS)
  - 31h : Terminate Stay Resident (TSR avec code de retour)
  - 32h : Get Drive Parameter Block (DPB - paramètres lecteur)
  - 33h : Multi-fonction (Control Break, Boot Drive)
    - 00h : Get Control Break check state
    - 01h : Set Control Break check state
    - 05h : Get boot drive
    - 06h : Get DOS version
  - 34h : Demande l'adresse du drapeau InDos
  - 35h : Demande le vecteur d'interruption
  - 36h : Get free disk space (espace libre sur disque)
  - 37h : Switch character functions (fonctions caractère de commutation)
  - 38h : Get/Set Country Information (informations de localisation)
  - 39h : Create Subdirectory (création de sous-répertoire)
  - 3Ah : Remove Directory (suppression de sous-répertoire)
  - 3Bh : Change Directory (changement de répertoire courant)
  - 3Ch : Create or Open File (création ou ouverture de fichier)
  - 3Dh : Open File (ouverture de fichier existant)
  - 3Eh : Close File (fermeture de fichier)
  - 3Fh : Read File (lecture de fichier)
  - 40h : Write File (écriture de fichier)
  - 41h : Delete File (suppression de fichier)
  - 42h : Seek File (positionnement dans fichier)
  - 43h : Get/Set File Attributes (lecture/modification attributs fichier)
  - 44h : IOCTL (contrôle d'entrée/sortie)
  - 45h : Duplicate Handle (duplication de handle)
  - 46h : Force Duplicate Handle (duplication forcée de handle)
  - 47h : Get Current Directory (obtenir le répertoire courant)
  - 48h : Allocate Memory Block (allouer bloc mémoire)
  - 49h : Free Memory Block (libérer bloc mémoire)
  - 4Ah : Modify Memory Block (modifier taille bloc mémoire)
  - 4Bh : EXEC - Load and Execute Program (charger et exécuter programme)
  - 4Ch : Terminate Program (terminer programme)
  - 4Dh : Get Return Code (obtenir code de retour)

  @target: Turbo Pascal 7 (syntaxe assembleur Intel)
}

Unit MSDOS;

INTERFACE

{$A-,S-,R-,Q-,I-}

{ Constantes pour les codes d'erreur étendus DOS }
Const
 { Codes d'erreur étendus }
 ERROR_INVALID_FUNCTION      = 1;   { Fonction invalide }
 ERROR_FILE_NOT_FOUND        = 2;   { Fichier non trouvé }
 ERROR_PATH_NOT_FOUND        = 3;   { Chemin non trouvé }
 ERROR_TOO_MANY_OPEN_FILES   = 4;   { Trop de fichiers ouverts }
 ERROR_ACCESS_DENIED         = 5;   { Accès refusé }
 ERROR_INVALID_HANDLE        = 6;   { Handle invalide }
 ERROR_ARENA_TRASHED         = 7;   { Zone de contrôle mémoire détruite }
 ERROR_NOT_ENOUGH_MEMORY     = 8;   { Pas assez de mémoire }
 ERROR_INVALID_BLOCK         = 9;   { Bloc de mémoire invalide }
 ERROR_BAD_ENVIRONMENT       = 10;  { Environnement incorrect }
 ERROR_BAD_FORMAT            = 11;  { Format incorrect }
 ERROR_INVALID_PARAMETER     = 87;  { Paramètre invalide }
 ERROR_NO_MORE_FILES         = 18;  { Plus de fichiers }
 ERROR_FILE_EXISTS           = 80;  { Fichier existe déjà }

 { Classes d'erreur }
 ERRCLASS_OUTOFRESOURCE     = 1;    { Ressources épuisées }
 ERRCLASS_TEMPSIT           = 2;    { Situation temporaire }
 ERRCLASS_TEMPFAIL          = 2;    { Échec temporaire (alias de TEMPSIT) }
 ERRCLASS_AUTH              = 3;    { Autorisation }
 ERRCLASS_INTRN             = 4;    { Erreur interne }
 ERRCLASS_HRDFAIL           = 5;    { Défaillance matérielle }
 ERRCLASS_SYSFAIL           = 6;    { Défaillance système }
 ERRCLASS_APPERR            = 7;    { Erreur d'application }
 ERRCLASS_NOTFND            = 8;    { Non trouvé }
 ERRCLASS_BADFMT            = 9;    { Format incorrect }
 ERRCLASS_LOCKED            = 10;   { Verrouillé }
 ERRCLASS_MEDIA             = 11;   { Erreur média }
 ERRCLASS_EXISTS            = 12;   { Existe déjà }
 ERRCLASS_UNK               = 13;   { Inconnu }
 ERRCLASS_BADCALL           = 14;   { Appel incorrect }

 { Actions suggérées }
 ERRACT_RETRY               = 1;    { Réessayer }
 ERRACT_DLYRET              = 2;    { Attendre puis réessayer }
 ERRACT_USER                = 3;    { Demander à l'utilisateur }
 ERRACT_ABORT               = 4;    { Abandonner }
 ERRACT_PANIC               = 5;    { Arrêt immédiat }
 ERRACT_IGNORE              = 6;    { Ignorer }
 ERRACT_INTRET              = 7;    { Réessayer après correction }

 { Localisation de l'erreur }
 ERRLOC_UNK                 = 1;    { Inconnue }
 ERRLOC_DISK                = 2;    { Disque }
 ERRLOC_NET                 = 3;    { Réseau }
 ERRLOC_SERDEV              = 4;    { Périphérique série }
 ERRLOC_MEM                 = 5;    { Mémoire }

Type
  { Paramètres de lecteur de disque }
  DriveParameterTable=Record
   SectorsPerTrack:Word;     { Secteurs par piste }
   NumberOfHeads:Word;       { Nombre de têtes }
   NumberOfCylinders:Word;   { Nombre de cylindres }
   BytesPerSector:Word;      { Octets par secteur }
   SectorsPerCluster:Byte;   { Secteurs par cluster }
  End;

  { Structure pour Boot Sector (FAT12/FAT16) }
  BootSectorRec=Record
   JmpBoot:Array[0..2] of Byte;      { Code de saut }
   OEMName:Array[0..7] of Char;      { Nom OEM }
   BytesPerSector:Word;              { Octets par secteur }
   SectorsPerCluster:Byte;           { Secteurs par cluster }
   ReservedSectors:Word;             { Secteurs réservés }
   NumberOfFATs:Byte;                { Nombre de FATs }
   RootDirEntries:Word;              { Entrées répertoire racine }
   TotalSectors:Word;                { Secteurs totaux }
   MediaDescriptor:Byte;             { Descripteur média }
   SectorsPerFAT:Word;               { Secteurs par FAT }
   SectorsPerTrack:Word;             { Secteurs par piste }
   NumberOfHeads:Word;               { Nombre de têtes }
   HiddenSectors:LongInt;            { Secteurs cachés }
   TotalSectorsLarge:LongInt;        { Secteurs totaux (32-bit) }
   DriveNumber:Byte;                 { Numéro de lecteur }
   Reserved:Byte;                    { Réservé }
   BootSignature:Byte;               { Signature de démarrage }
   VolumeID:LongInt;                 { ID de volume }
   VolumeLabel:Array[0..10] of Char; { Label de volume }
   FileSystemType:Array[0..7] of Char; { Type de système de fichiers }
   BootCode:Array[0..447] of Byte;   { Code de démarrage }
   BootSectorSignature:Word;         { Signature 55AAh }
  End;

  { Entrée de répertoire FAT }
  DirectoryEntry=Record
   FileName:Array[0..7] of Char;     { Nom de fichier (8 caractères) }
   Extension:Array[0..2] of Char;    { Extension (3 caractères) }
   Attributes:Byte;                  { Attributs de fichier }
   Reserved:Byte;                    { Réservé }
   CreationTimeFine:Byte;            { Création temps fin }
   CreationTime:Word;                { Heure de création }
   CreationDate:Word;                { Date de création }
   LastAccessDate:Word;              { Date dernier accès }
   FirstClusterHigh:Word;            { Cluster de départ (partie haute) }
   LastWriteTime:Word;               { Heure dernière écriture }
   LastWriteDate:Word;               { Date dernière écriture }
   FirstClusterLow:Word;             { Cluster de départ (partie basse) }
   FileSize:LongInt;                 { Taille du fichier }
  End;

  { Paramètres de bloc BIOS }
  BIOSParameterBlock=Record
   BytesPerSector:Word;              { Octets par secteur }
   SectorsPerCluster:Byte;           { Secteurs par cluster }
   ReservedSectors:Word;             { Secteurs réservés }
   NumberOfFATs:Byte;                { Nombre de FATs }
   RootDirEntries:Word;              { Entrées répertoire racine }
   TotalSectors:Word;                { Secteurs totaux }
   MediaDescriptor:Byte;             { Descripteur média }
   SectorsPerFAT:Word;               { Secteurs par FAT }
   SectorsPerTrack:Word;             { Secteurs par piste }
   NumberOfHeads:Word;               { Nombre de têtes }
   HiddenSectors:LongInt;            { Secteurs cachés }
   TotalSectorsLarge:LongInt;        { Secteurs totaux (32-bit) }
  End;

  { Requête d'I/O disque }
  DiskIORequest=Record
   DriveNumber:Byte;                 { Numéro de lecteur }
   SectorNumber:LongInt;             { Numéro de secteur }
   SectorCount:Word;                 { Nombre de secteurs }
   BufferPtr:Pointer;                { Pointeur vers buffer }
  End;

Procedure BEGIN_KERNEL;
Procedure END_KERNEL;

IMPLEMENTATION

Const
 { Le noyau (IO.SYS) est charge en 0070:0000 et occupe jusqu'a 64 Ko : l'arene
   de memoire (MCB) commence apres, et s'arrete avant la pile du noyau. }
 CDBase=114;         { offset de CurrentDir dans DataMOS (apres FindState) }
 CDSize=67;          { Drive(1) + Cluster(2) + Path(1+63) }
 NDrv=6;            { unites A: a F: (LASTDRIVE ne peut pas depasser F:) }
 FTBase=516;         { CDBase + NDrv*CDSize : debut de FileTable dans DataMOS }
 FxBase=1146;        { FTBase + 20*17 + 9 + 280 + 1 : apres PendingLF ;
   20 x (secteur LongInt + index Byte) }
 ArenaBase=$1080;
 ArenaEnd=$9000;
 VerDos=7;          { Version de DOS }
 SubVerDos=10;      { Sous-version de DOS }

Type
 Registers=Record
  Case Integer of
   0: (AX, BX, CX, DX, BP, SI, DI, DS, ES, Flags: Word);
   1: (AL, AH, BL, BH, CL, CH, DL, DH: Byte);
 End;

 { Structure pour recherche de fichiers }
 FindFileState = Record
  SearchMask: String[12];            { Masque de recherche (*.*, *.TXT, etc.) }
  SearchPath: String[80];            { Chemin de recherche }
  SearchAttr: Byte;                  { Attributs recherchés }
  CurrentDir: Word;                  { Cluster répertoire courant }
  CurrentEntry: Word;                { Entrée courante dans le répertoire }
  Active: Boolean;                   { État de recherche actif }
 End;

 { Structure d'entrée de répertoire FAT12/FAT16 }
 DirectoryEntryFAT = Record
  FileName: Array[0..10] of Char;   { Nom 8.3 (8 + 3 caractères) }
  Attributes: Byte;                 { Attributs du fichier }
  Reserved: Byte;                   { Réservé }
  CreateTimeTenths: Byte;           { Dixièmes de seconde création }
  CreateTime: Word;                 { Heure de création }
  CreateDate: Word;                 { Date de création }
  LastAccessDate: Word;             { Date dernier accès }
  FirstClusterHigh: Word;           { Cluster de départ (poids fort) - FAT32 }
  Time: Word;                       { Heure de modification }
  Date: Word;                       { Date de modification }
  FirstCluster: Word;               { Cluster de départ (poids faible) }
  Size: LongInt;                    { Taille du fichier }
 End;

  { Volume FAT compact et entree de repertoire (couche d'ecriture Fx*) }
 TFxVol = Record
  Drive:Byte;
  SPC:Byte;
  NFat:Byte;
  Is16:Boolean;
  Res:Word;
  SPF:Word;
  RootEnt:Word;
  Clusters:Word;
  FirstData:LongInt;
 End;
 TFxSec = Array[0..511] of Byte;
 TFxFree = Record
  SPC,Free,BPS,Total:Word;
 End;
 TFxEnt = Record
  Attr:Byte;
  Cluster:Word;
  Size:LongInt;
 End;

  { Structure pour verrous de fichiers (File Locking) }
 FileLockEntry = Record
  InUse: Boolean;                    { Entrée utilisée }
  Handle: Word;                      { Handle de fichier }
  PSPOwner: Word;                    { PSP propriétaire du verrou }
  StartOffset: LongInt;              { Offset de début }
  Length: LongInt;                   { Longueur verrouillée }
  LockType: Byte;                    { Type de verrou (0=read, 1=write) }
 End;

 FileTableEntry = Record
  InUse: Boolean;         { Fichier en cours d'utilisation }
  Drive: Byte;           { Lecteur (0=A:, 1=B:, etc.) }
  FirstCluster: Word;    { Premier cluster du fichier }
  FileSize: LongInt;     { Taille du fichier }
  CurrentPos: LongInt;   { Position courante dans le fichier }
  Attributes: Byte;      { Attributs du fichier }
  CurrentCluster: Word;  { Cluster courant pour lecture/écriture }
  ClusterOffset: Word;   { Offset dans le cluster courant }
 End;

  { Structure pour les données internes DOS }
 DataMOS=Record
  Key:Byte;
  InDos:Byte;
  CurrDisk:Byte;
  DTASegment:Word;    { Segment de la DTA }
  DTAOffset:Word;     { Offset de la DTA }
  CurrentCountry:Word; { Code pays actuel }
  LastReturnCode:Word; { Code de retour du dernier programme (AH=raison,
    AL=code) }
  CurrentPSP:Word;     { Segment du PSP courant }
  VerifyFlag:Byte;     { Flag de vérification en écriture (0=off, 1=on) }
  FindState: FindFileState; { État de la recherche de fichiers }
  CurrentDir: Array[0..5] of Record
   Drive: Byte;
   Cluster: Word;
   Path: String[63];
  End;
  FileTable:Array[0..19]of FileTableEntry;
  { Données pour fonction 59h - Get Extended Error Information }
  ExtendedError:Word;       { Code d'erreur étendu }
  ErrorClass:Byte;          { Classe d'erreur }
  SuggestedAction:Byte;     { Action suggérée }
  ErrorLocus:Byte;          { Localisation de l'erreur }
  MemoryStrategy:Word;      { Stratégie d'allocation mémoire }
  UMBLinkState:Word;        { État de liaison des UMB }
  { Table des verrous de fichiers }
  FileLocks: Array[0..19] of FileLockEntry; { Max 20 verrous simultanés }
  PendingLF: Byte;
    { console : LF a rendre apres un CR lu caractere par caractere }
 End;

 { Structure pour les informations pays }
 DataCountryRec=Record
  CountryCode:Word;           { Code pays }
  DateFormat:Byte;            { 0=USA, 1=Europe, 2=Japan }
  Currency:Array[0..4] of Char; { Symbole monétaire }
  ThousandsSep:Array[0..1] of Char; { Séparateur milliers }
  DecimalSep:Array[0..1] of Char;   { Séparateur décimal }
  DateSep:Array[0..1] of Char;      { Séparateur date }
  TimeSep:Array[0..1] of Char;      { Séparateur heure }
  CurrencyFormat:Byte;        { Format monétaire }
  DecimalDigits:Byte;         { Chiffres après virgule }
  TimeFormat:Byte;            { 0=12h, 1=24h }
  DataListSep:Array[0..1] of Char; { Séparateur liste }
 End;

{ Structure pour la table des fichiers ouverts }
Type
 PBytePtr = ^Byte;       { Pointeur vers Byte pour Turbo Pascal }
 PChar = ^Char;          { Pointeur vers Char pour chaînes ASCIIZ }

 { Bloc de contrôle mémoire (MCB - Memory Control Block) }
 MemoryControlBlock = Record
  BlockType: Char;       { 'M' = bloc normal, 'Z' = dernier bloc }
  Owner: Word;           { Segment propriétaire (0 = libre) }
  BlockSize: Word;       { Taille en paragraphes (16 bytes) }
  Reserved: Array[0..2] of Byte; { Réservé }
  ProgramName: Array[0..7] of Char; { Nom du programme propriétaire }
 End;

 { Structure pour la gestion de la mémoire }
 MemoryManager = Record
  FirstMCB: Word;        { Segment du premier MCB }
  LastMCB: Word;         { Segment du dernier MCB }
  TotalMemory: Word;     { Mémoire totale en KB }
  FreeMemory: Word;      { Mémoire libre en KB }
 End;

 { Structure pour EXEC - Program Segment Prefix (PSP) }
 ProgramSegmentPrefix = Record
  Int20h: Word;              { INT 20h instruction }
  TopOfMemory: Word;         { Segment du haut de la mémoire }
  Reserved1: Byte;           { Réservé }
  CallToDispatcher: Array[0..4] of Byte; { Appel au dispatcher DOS }
  TerminateAddress: Pointer; { Adresse de fin INT 22h }
  CtrlCAddress: Pointer;     { Adresse Ctrl+C INT 23h }
  CriticalErrorAddress: Pointer; { Adresse erreur critique INT 24h }
  ParentPSP: Word;           { Segment PSP parent }
  HandleTable: Array[0..19] of Byte; { Table des handles ouverts }
  Environment: Word;         { Segment environnement }
  SavedSSSP: LongInt;        { SS:SP sauvegardé }
  HandleTableSize: Word;     { Taille table handles }
  HandleTablePtr: Pointer;   { Pointeur table handles }
  Reserved2: Array[0..23] of Byte; { Réservé }
  DOSCall: Array[0..2] of Byte;    { INT 21h, RETF }
  Reserved3: Array[0..8] of Byte;  { Réservé }
  FCB1: Array[0..15] of Byte;      { FCB #1 }
  FCB2: Array[0..19] of Byte;      { FCB #2 }
  CommandLine: Array[0..127] of Byte; { Ligne de commande }
 End;

 { Structure pour les paramètres EXEC }
 ExecParameterBlock = Record
  Environment: Word;         { Segment environnement (0 = hériter) }
  CommandLine: Pointer;      { Pointeur ligne de commande }
  FCB1: Pointer;            { Pointeur FCB #1 }
  FCB2: Pointer;            { Pointeur FCB #2 }
  InitialSSSP: Pointer;     { SS:SP initial (pour type 01h) }
  InitialCSIP: Pointer;     { CS:IP initial (pour type 01h) }
 End;

 { En-tête EXE }
 ExeHeader = Record
  Signature: Word;          { 'MZ' ou 'ZM' }
  BytesInLastPage: Word;    { Octets dans la dernière page }
  PagesInFile: Word;        { Pages dans le fichier }
  Relocations: Word;        { Nombre de relocalisations }
  HeaderParagraphs: Word;   { Taille en-tête en paragraphes }
  MinExtraParagraphs: Word; { Paragraphes supplémentaires min }
  MaxExtraParagraphs: Word; { Paragraphes supplémentaires max }
  InitialSS: Word;          { SS initial relatif }
  InitialSP: Word;          { SP initial }
  Checksum: Word;           { Checksum }
  InitialIP: Word;          { IP initial }
  InitialCS: Word;          { CS initial relatif }
  RelocTableOffset: Word;   { Offset table relocalisations }
  OverlayNumber: Word;      { Numéro overlay }
 End;

{ Structure DTA pour Find First/Next File }
DTAStruct = Record
 Reserved: Array[0..20] of Byte;    { Zone réservée DOS }
 Attribute: Byte;                   { Attribut du fichier trouvé }
 Time: Word;                        { Heure du fichier }
 Date: Word;                        { Date du fichier }
 Size: LongInt;                     { Taille du fichier }
 Name: Array[0..12] of Char;        { Nom 8.3 + terminateur }
 End;

{ Structure Liste des Listes (List of Lists) - DOS 52h }
ListOfLists = Record
 FirstDPB: Pointer;                 { Pointeur vers premier DPB }
 FirstSFT: Pointer;                 { Pointeur vers première SFT }
 ClockDevice: Pointer;              { Pointeur vers driver horloge }
 ConDevice: Pointer;                { Pointeur vers driver console }
 MaxSectorLength: Word;             { Longueur max secteur }
 FirstBuffer: Pointer;              { Pointeur vers premier buffer disque }
 FirstDirtyBuffer: Pointer;         { Pointeur vers premier buffer sale }
 FreeClusters: Word;                { Nombre clusters libres (-1 si inconnu) }
 NextFreeDPB: Pointer;              { Pointeur prochain DPB libre }
 NumberOfBuffers: Word;             { Nombre de buffers disque }
 NumberOfLookaheadBuffers: Byte;    { Nombre buffers anticipation }
 BootDrive: Byte;                   { Lecteur de démarrage (1=A:, 2=B:, etc.) }
 DOSDataSeg: Word;                  { Segment données DOS }
 LastDrive: Byte;                   { Dernier lecteur valide }
 NULDevice: Pointer;                { Pointeur vers driver NUL }
End;

{ Structure Drive Parameter Block (DPB) }
DriveParameterBlock = Record
 DriveNumber: Byte;                 { Numéro lecteur (0=A:, 1=B:, etc.) }
 UnitNumber: Byte;                  { Numéro unité }
 BytesPerSector: Word;              { Octets par secteur }
 LastSectorInCluster: Byte;         { Dernier secteur dans cluster }
 SectorsPerClusterShift: Byte;      { Décalage secteurs/cluster }
 ReservedSectors: Word;             { Secteurs réservés }
 NumberOfFATs: Byte;                { Nombre de FATs }
 MaxRootEntries: Word;              { Entrées max répertoire racine }
 FirstDataSector: Word;             { Premier secteur de données }
 HighestCluster: Word;              { Plus haut numéro de cluster }
 SectorsPerFAT: Word;               { Secteurs par FAT }
 FirstDirSector: Word;              { Premier secteur répertoire racine }
 DeviceDriverHeader: Pointer;       { En-tête driver périphérique }
 MediaID: Byte;                     { ID média }
 AccessFlag: Byte;                  { Flag d'accès }
 NextDPB: Pointer;                  { Pointeur DPB suivant }
 FirstFreeCluster: Word;            { Premier cluster libre }
 NumberFreeClusters: Word;          { Nombre clusters libres }
End;

{ Variables globales supprimées - maintenant dans Code Segment }
{$IFNDEF FPC}
{ Aucune variable globale nécessaire en mode Turbo Pascal }
{$ENDIF}

{ Déclarations Forward }
Procedure Intr1Ah;{$IFNDEF FPC}Interrupt;{$ENDIF}Forward;
Procedure Intr21h;{$IFNDEF FPC}Interrupt;{$ENDIF}Forward;
Procedure Intr20hEntry;{$IFNDEF FPC}Interrupt;{$ENDIF}Forward;
Procedure Intr21hCore;{$IFNDEF FPC}Interrupt;{$ENDIF}Forward;
Procedure Intr25h;{$IFNDEF FPC}Interrupt;{$ENDIF}Forward;
Procedure Intr26h;{$IFNDEF FPC}Interrupt;{$ENDIF}Forward;
Procedure Intr28h;{$IFNDEF FPC}Interrupt;{$ENDIF}Forward;
Procedure Intr2Ah;{$IFNDEF FPC}Interrupt;{$ENDIF}Forward;
Procedure Intr2Fh;{$IFNDEF FPC}Interrupt;{$ENDIF}Forward;
Procedure Intr33h;{$IFNDEF FPC}Interrupt;{$ENDIF}Forward;

{ Déclarations des fonctions DOS }
Function DOS4Eh_FindFirstFile(Path:String;Attr:Byte;var DTA:DTAStruct):Word;
  Forward;
Function DOS4Fh_FindNextFile(var DTA:DTAStruct):Word;Forward;

{ Fonctions d'accès aux données du kernel }

{ Fonctions FAT pour Find File }
Function GetRootDirectorySector:Word;Near;Forward;
Function GetRootDirectorySize:Word;Near;Forward;
Function RootSectorOf(Drive:Byte):Word;Near;Forward;
Function RootSizeOf(Drive:Byte):Word;Near;Forward;
Function ReadSectorSimple(Sector:Word;Var Buffer):Boolean;Near;Forward;
Function WriteSectorSimple(Sector:Word;Var Buffer):Boolean;Near;Forward;

Procedure SetIntVec(_AL:Byte;_DS,_DX:Word);Near;Forward;
Procedure GetIntVec(_AL:Byte;Var _DS,_DX:Word);Near;Forward;
Procedure FillChar(Var Dest;Size:Word;Value:Byte);Near;Forward;
Procedure Move(Var Source,Dest;Size:Word);Near;Forward;
Procedure Intr(IntNo:Byte;Var Regs:Registers);Near;Forward;

{ Fonctions de manipulation de chaînes internes }
Function Length(S:String):Byte;Near;Forward;
Function Copy(S:String;Index,Count:Byte):String;Near;Forward;
Procedure Delete(Var S:String;Index,Count:Byte);Near;Forward;

Function Handle38hSetCountryInfo(NewCountryCode:Word):Word;Near;Forward;

{ Procédures pour gestion FAT et répertoires - Fonctions 39h/3Ah }
Function ReadBootSector(Drive:Byte;Var BootSec:BootSectorRec):Boolean;Near;
  Forward;
Function ReadSector(Drive:Byte;Sector:LongInt;Buffer:Pointer):Boolean;Near;
  Forward;
Function WriteSector(Drive:Byte;Sector:LongInt;Buffer:Pointer):Boolean;Near;
  Forward;
Function FindFreeCluster(Drive:Byte;BootSec:BootSectorRec):Word;Near;Forward;
Function AllocateCluster(Drive:Byte;BootSec:BootSectorRec;Cluster:Word):Boolean;
  Near;Forward;
Function CreateDirEntry(Drive:Byte;BootSec:BootSectorRec;ParentCluster:Word;
  DirName:String):Boolean;Near;Forward;
Function ParsePath(Path:String;Var Drive:Byte;Var DirName:String):Boolean;Near;
  Forward;
Function FindParentDirectory(Drive:Byte;BootSec:BootSectorRec;Path:String;
  Var ParentCluster:Word):Boolean;Near;Forward;

{ Procédures spécifiques pour fonction 3Ah - Remove Directory }
Function FindDirectoryEntry(Drive:Byte;BootSec:BootSectorRec;ParentCluster:Word;
                           DirName:String;Var Entry:DirectoryEntry;
                           Var EntryOffset:Word):Boolean;Near;Forward;
Function IsDirectoryEmpty(Drive:Byte;BootSec:BootSectorRec;
  DirCluster:Word):Boolean;Near;Forward;
Function FreeFATChain(Drive:Byte;BootSec:BootSectorRec;
  StartCluster:Word):Boolean;Near;Forward;
Function DeleteDirEntry(Drive:Byte;BootSec:BootSectorRec;ParentCluster:Word;
  EntryOffset:Word):Boolean;Near;Forward;
Function GetClusterSector(Drive:Byte;BootSec:BootSectorRec;
  Cluster:Word):LongInt;Near;Forward;

{ Fonctions principales pour 3Ah et 3Bh }
Function DOS3Ah_RemoveDirectory(PathPtr:Pointer):Word;Near;Forward;
Function DOS39h_MakeDirectory(PathPtr:Pointer):Word;Near;Forward;
Function DOS36h_DiskFree(Drive:Byte;Var R:TFxFree):Word;Near;Forward;
Procedure InitPartition;Near;Forward;
Procedure SftRefSet(I,V:Byte);Near;Forward;
Function CountryInt21(Buf:Pointer):Word;Near;Forward;
Procedure CharOut21(C:Byte);Near;Forward;
Function CharIn21(Echo:Word):Word;Near;Forward;
Procedure StrOut21(P:Pointer);Near;Forward;
Function GetDTASeg:Word;Near;Forward;
Function GetDTAOfs:Word;Near;Forward;
Function OpenInt21(PathPtr:Pointer;Mode:Byte):Word;Near;Forward;
Function CreateInt21(PathPtr:Pointer):Word;Near;Forward;
Function CreateNewInt21(PathPtr:Pointer;Attr:Word):Word;Near;Forward;
Function TempInt21(PathPtr:Pointer;Attr:Word):Word;Near;Forward;
Function CloseInt21(H:Word):Word;Near;Forward;
Function SeekInt21(H,OffsetHi,OffsetLo:Word;Method:Byte):LongInt;Near;Forward;
Function DateTimeInt21(H:Word;Action:Byte;NewDate,NewTime:Word):LongInt;Near;
  Forward;
Function LockInt21(H:Word;Action:Byte;Start,Len:LongInt):Word;Near;Forward;
Function IoctlInt21(Sub,H:Word;Var Info:Word):Word;Near;Forward;
Function FcbOpen(P:Pointer):Byte;Near;Forward;
Function FcbClose(P:Pointer):Byte;Near;Forward;
Function FcbFindFirst(P:Pointer):Byte;Near;Forward;
Function FcbFindNext(P:Pointer):Byte;Near;Forward;
Function FcbDelete(P:Pointer):Byte;Near;Forward;
Function FcbSeqRead(P:Pointer):Byte;Near;Forward;
Function FcbSeqWrite(P:Pointer):Byte;Near;Forward;
Function FcbCreate(P:Pointer):Byte;Near;Forward;
Function FcbRename(P:Pointer):Byte;Near;Forward;
Function FcbRandRead(P:Pointer):Byte;Near;Forward;
Function FcbRandWrite(P:Pointer):Byte;Near;Forward;
Function FcbFileSize(P:Pointer):Byte;Near;Forward;
Function FcbSetRandom(P:Pointer):Byte;Near;Forward;
Function FcbBlockRead(P:Pointer;Count:Word;Var Done:Word):Byte;Near;Forward;
Function FcbBlockWrite(P:Pointer;Count:Word;Var Done:Word):Byte;Near;Forward;
Function FcbParse(StrPtr:Pointer;Fcb:Pointer;Flags:Word;Var NewOfs:Word):Byte;
  Near;Forward;
Function SftRefGet(I:Byte):Byte;Near;Forward;
Procedure SetPartOfs(V:LongInt);Near;Forward;
Function DiskTransfer(Op:Byte;Drive:Byte;Sector:LongInt;Buffer:Pointer):Boolean;
  Near;Forward;

{ Procédures spécifiques pour fonction 3Bh - Change Directory }
Function FindDirectoryByPath(Drive:Byte;BootSec:BootSectorRec;Path:String;
  Var DirCluster:Word):Boolean;Near;Forward;
Function SetCurrentDirectory(Drive:Byte;DirCluster:Word):Boolean;Near;Forward;
Function DOS3Bh_ChangeDirectory(PathPtr:Pointer):Word;Near;Forward;

{ Procédures spécifiques pour fonction 3Ch - Create or Open File }
Function ParseFilePath(Path:String;Var Drive:Byte;Var DirPath,
  FileName:String):Boolean;Near;Forward;
Function FindOrCreateFile(Drive:Byte;BootSec:BootSectorRec;DirPath,
  FileName:String;
                         Attributes:Byte;Var FileHandle:Word):Word;Near;Forward;
Function AllocateFileHandle(Drive:Byte;FirstCluster,FileSize:LongInt;
                           Attributes:Byte;Var Handle:Word):Boolean;Near;
                             Forward;
Function CreateFileEntry(Drive:Byte;BootSec:BootSectorRec;DirCluster:Word;
                        FileName:String;Attributes:Byte;
                          Var FirstCluster:Word):Word;Near;Forward;
Function OpenExistingFile(Drive:Byte;Entry:DirectoryEntry;Var Handle:Word):Word;
  Near;Forward;
Function DOS3Ch_CreateOpenFile(PathPtr:Pointer):Word;Near;Forward;

{ Procédures spécifiques pour fonction 3Dh - Open File }
Function ValidateAccessMode(AccessMode:Byte):Boolean;Near;Forward;
Function OpenFileReadOnly(Drive:Byte;Entry:DirectoryEntry;Var Handle:Word):Word;
  Near;Forward;
Function OpenFileWriteOnly(Drive:Byte;Entry:DirectoryEntry;
  Var Handle:Word):Word;Near;Forward;
Function OpenFileReadWrite(Drive:Byte;Entry:DirectoryEntry;
  Var Handle:Word):Word;Near;Forward;
Function DOS3Dh_OpenFile(PathPtr:Pointer;AccessMode:Byte):Word;Near;Forward;

{ Forward declarations pour fonction 3Eh }
Function GetFileTableEntry(Handle:Word;Var Entry:FileTableEntry):Boolean;Near;
  Forward;
Function SetFileTableEntry(Handle:Word;Entry:FileTableEntry):Boolean;Near;
  Forward;
Function CloseFileHandle(Handle:Word):Word;Near;Forward;
Function FlushFileBuffers(Handle:Word):Word;Near;Forward;
Function UpdateDirectoryEntry(Handle:Word):Word;Near;Forward;
Function DOS3Eh_CloseFile(Handle:Word):Word;Near;Forward;

{ Forward declarations pour fonction 3Fh }
Function ReadFromCluster(Drive:Byte;BootSec:BootSectorRec;Cluster:Word;
                         Offset:Word;Buffer:Pointer;
                         BytesToRead:Word):Word;Near;Forward;
Function GetNextCluster(Drive:Byte;BootSec:BootSectorRec;
  CurrentCluster:Word):Word;Near;Forward;
Function ReadFileData(Handle:Word;Buffer:Pointer;BytesToRead:Word;
  Var BytesRead:Word):Word;Near;Forward;
Function DOS3Fh_ReadFile(Handle:Word;Buffer:Pointer;BytesToRead:Word;
  Var BytesRead:Word):Word;Near;Forward;

{ Forward declarations pour fonction 40h }
Function WriteToCluster(Drive:Byte;BootSec:BootSectorRec;Cluster:Word;
                       Offset:Word;Buffer:Pointer;BytesToWrite:Word):Word;Near;
                         Forward;
Function AllocateNewCluster(Drive:Byte;BootSec:BootSectorRec;
  PreviousCluster:Word):Word;Near;Forward;
Function UpdateFATEntry(Drive:Byte;BootSec:BootSectorRec;Cluster:Word;
  NextCluster:Word):Boolean;Near;Forward;
Function WriteFileData(Handle:Word;Buffer:Pointer;BytesToWrite:Word;
  Var BytesWritten:Word):Word;Near;Forward;
Function DOS40h_WriteFile(Handle:Word;Buffer:Pointer;BytesToWrite:Word;
  Var BytesWritten:Word):Word;Near;Forward;

{ Forward declarations pour fonction 41h }
Function DeleteDirectoryEntry(Drive:Byte;BootSec:BootSectorRec;DirCluster:Word;
  FileName:String):Boolean;Near;Forward;
Function DOS41h_DeleteFile(PathPtr:Pointer):Word;Near;Forward;

{ Forward declarations pour fonction 42h }
Function CalculateClusterFromPosition(Drive:Byte;BootSec:BootSectorRec;
                                      FirstCluster:Word;Position:LongInt;
                                      Var TargetCluster:Word;
                                      Var ClusterOffset:Word):Boolean;Near;
                                        Forward;
Function DOS42h_SeekFile(Handle:Word;OffsetHi,OffsetLo:Word;
  Method:Byte):LongInt;Near;Forward;

{ Forward declarations pour fonction 43h }
Function GetFileAttributes(Drive:Byte;BootSec:BootSectorRec;DirCluster:Word;
                           FileName:String;Var Attributes:Byte):Boolean;Near;
                             Forward;
Function SetFileAttributes(Drive:Byte;BootSec:BootSectorRec;DirCluster:Word;
                           FileName:String;NewAttributes:Byte):Boolean;Near;
                             Forward;
Function DOS43h_GetSetFileAttributes(PathPtr:Pointer;Action:Byte;
  NewAttributes:Byte):Word;Near;Forward;

{ Forward declarations pour fonction 44h }
Function IOCTL_GetDeviceInfo(Handle:Word):Word;Near;Forward;
Function IOCTL_SetDeviceInfo(Handle:Word;DeviceInfo:Word):Word;Near;Forward;
Function IOCTL_GetDriveInfo(Drive:Byte):Word;Near;Forward;
Function IOCTL_SetDriveInfo(Drive:Byte;DeviceInfo:Word):Word;Near;Forward;
Function IOCTL_ReadControlData(Handle:Word;Buffer:Pointer;
  BytesToRead:Word):Word;Near;Forward;
Function IOCTL_WriteControlData(Handle:Word;Buffer:Pointer;
  BytesToWrite:Word):Word;Near;Forward;
Function DOS44h_IOCTL(Handle:Word;SubFunction:Byte;Buffer:Pointer;
  ByteCount:Word):Word;Near;Forward;
Function DOS45h_DuplicateHandle(SourceHandle:Word):Word;Near;Forward;
Function DOS46h_ForceDuplicateHandle(SourceHandle:Word;TargetHandle:Word):Word;
  Near;Forward;
Function DOS47h_GetCurrentDirectory(Drive:Byte;BufferSeg:Word;
  BufferOfs:Word):Word;Near;Forward;
Function DOS48h_AllocateMemory(BlockSize:Word):Word;Near;Forward;
Function DOS49h_FreeMemory(BlockSegment:Word):Word;Near;Forward;
Function DOS4Ah_ModifyMemory(BlockSegment:Word;NewSize:Word):Word;Near;Forward;
Function DOS4Bh_ExecProgram(ExecType:Byte;ProgramPath:String;
  ParamBlock:ExecParameterBlock):Word;Near;Forward;
Function DOS4Ch_TerminateProgram(ExitCode:Byte):Word;Near;Forward;
Function DOS31h_Keep(ExitCode:Byte;Paras:Word):Word;Near;Forward;
Function ExecFromInt21(Mode:Word;NamePtr:Pointer;BlockPtr:Pointer):Word;Near;
  Forward;
Function ReadInt21(Handle:Word;Buf:Pointer;Count:Word;Var Got:Word):Word;Near;
  Forward;
Function AbsDiskInt21(Wr,Drive,Count,SecHi,SecLo,BufSeg,BufOfs:Word):Word;Near;
  Forward;
Function WriteInt21(Handle:Word;Buf:Pointer;Count:Word;Var Got:Word):Word;Near;
  Forward;
Function AllocInt21(Size:Word):Word;Near;Forward;
Function FindFirstInt21(NamePtr:Pointer;Attr:Word):Word;Near;Forward;
Function FindNextInt21:Word;Near;Forward;
Function LargestFreeBlock:Word;Near;Forward;
Procedure DowTable;Near;Forward;
Procedure SetDTA(S,O:Word);Near;Forward;
Function DateInt21:LongInt;Near;Forward;
Function WdayInt21:Word;Near;Forward;
Function TimeInt21:LongInt;Near;Forward;
Function PendingLFSet:Boolean;Near;Forward;
Procedure ClearPendingLF;Near;Forward;
Procedure SetPendingLF;Near;Forward;
{$IFDEF KDEBUG}
Procedure DbgW(Tag:Char;W:Word);Near;Forward;
{$ENDIF}
Function DOS4Dh_GetReturnCode:Word;Near;Forward;

{ Fonctions 50h et 51h - Gestion PSP }
Function DOS50h_SetPSPAddress(PSPSegment:Word):Word;Near;Forward;
Function DOS51h_GetPSPAddress:Word;Near;Forward;

{ Fonctions 52h et 53h - Structures internes DOS }
Function DOS52h_GetListOfLists:Pointer;Near;Forward;
Function DOS53h_TranslateBPBtoDPB(BPBPtr:Pointer;DPBPtr:Pointer):Word;Near;
  Forward;

{ Fonctions 2Eh et 54h - Vérification en écriture }
Function DOS2Eh_SetVerifyFlag(VerifyState:Byte):Word;Near;Forward;
Function DOS54h_GetVerifyFlag:Byte;Near;Forward;

{ Fonction 55h - Create Child PSP }
Function DOS55h_CreateChildPSP(NewPSPSegment:Word):Word;Near;Forward;

{ Fonction 56h - Rename/Move File }
Function DOS56h_RenameFile(OldPathPtr:Pointer;NewPathPtr:Pointer):Word;Near;
  Forward;

{ Fonction 57h - Get/Set File Date and Time }
Function DOS57h_GetSetFileDateTime(Handle:Word;Action:Byte;NewDate,
  NewTime:Word):LongInt;Near;Forward;

{ Fonction 58h - Get/Set Memory Allocation Strategy }
Function DOS58h_GetSetMemoryStrategy(Action:Byte;NewStrategy:Word):Word;Near;
  Forward;

{ Fonction 59h - Get Extended Error Information }
Function DOS59h_GetExtendedError:LongInt;Near;Forward;

{ Fonction 5Ah - Create Temporary File }
Function DOS5Ah_CreateTempFile(PathPtr:Pointer;Attributes:Word):Word;Near;
  Forward;

{ Fonction 5Bh - Create New File }
Function DOS5Bh_CreateNewFile(PathPtr:Pointer;Attributes:Word):Word;Near;
  Forward;

{ Fonction 5Ch - Lock/Unlock File Region }
Function DOS5Ch_LockUnlockRegion(Handle:Word;Action:Byte;StartOffset,
  Length:LongInt):Word;Near;Forward;

{ Fonctions utilitaires pour opérations FAT réelles }
Function ReadFATSector(Drive:Byte;Sector:Word;Var Buffer):Boolean;Near;Forward;
Function WriteFATSector(Drive:Byte;Sector:Word;Var Buffer):Boolean;Near;Forward;
Function ReadDirectorySector(Drive:Byte;Sector:Word;Var Buffer):Boolean;Near;
  Forward;
Function WriteDirectorySector(Drive:Byte;Sector:Word;Var Buffer):Boolean;Near;
  Forward;
Function FindDirectoryEntryByName(Drive:Byte;DirCluster:Word;
                                  FileName:String;Var Entry:DirectoryEntryFAT;
                                  Var EntryOffset:Word):Boolean;Near;Forward;
Function ParseFullPath(Path:String;Var Drive:Byte;Var DirPath,
  FileName:String):Boolean;Near;Forward;
Function UpdateDirectoryEntryName(Drive:Byte;DirCluster:Word;EntryOffset:Word;
  NewName:String):Boolean;Near;Forward;

{ Fonctions utilitaires pour la vérification }
Function VerifyWrite(Drive:Byte;Sector:LongInt;Buffer:Pointer;
  Size:Word):Boolean;Near;Forward;
Function WriteSectorWithVerify(Drive:Byte;Sector:LongInt;
  Buffer:Pointer):Boolean;Near;Forward;

{ Fonctions utilitaires pour EXEC }
Function LoadExeFile(FileName:String;Var LoadSegment:Word;
  Var ExeHdr:ExeHeader):Boolean;Near;Forward;
Function LoadComFile(FileName:String;Var LoadSegment:Word):Boolean;Near;Forward;
Function CreatePSP(ParentPSP:Word;TopMemory:Word):Word;Near;Forward;
Function SetupEnvironment(EnvSeg:Word;ParentPSP:Word):Word;Near;Forward;
Function BootLetter:Char;Near;Forward;
Procedure Data;Near;Forward;
Function RelocateExe(LoadSeg:Word;ExeHdr:ExeHeader;FileName:String):Boolean;
  Near;Forward;

{ Fonction pour charger le processeur de commandes }
Function LoadAndExecuteCommandProcessor:Boolean;Near;Forward;
Procedure InitConfig;Near;Forward;
Function CfgWord(Ofs:Word):Word;Near;Forward;
Function CfgSegGet:Word;Near;Forward;

{ Fonctions utilitaires de base }
Function UpperCase(S:String):String;Near;Forward;
Function MatchFileName(FileName:String;Mask:String):Boolean;Near;Forward;
Function Pos(SubStr:String;S:String):Byte;Near;Forward;

{ Fonctions utilitaires pour la gestion mémoire }
Function InitializeMemoryManager:Boolean;Near;Forward;
Function FindFreeMCB(Size:Word;Var Segment:Word):Boolean;Near;Forward;
Function CreateMCB(Segment:Word;Size:Word;Owner:Word;IsLast:Boolean):Boolean;
  Near;Forward;
Function GetMCB(Segment:Word;Var MCB:MemoryControlBlock):Boolean;Near;Forward;
Function SetMCB(Segment:Word;MCB:MemoryControlBlock):Boolean;Near;Forward;
Function GetMemoryStrategy:Word;Near;Forward;
Procedure SetMemoryStrategy(NewStrategy:Word);Near;Forward;
Function AllocateMemoryWithStrategy(Size:Word;Strategy:Word):Word;Near;Forward;
Function GetUMBLinkState:Word;Near;Forward;
Procedure SetUMBLinkState(NewState:Word);Near;Forward;

{ Fonctions pour gestion des erreurs étendues }
Procedure SetExtendedError(ErrorCode:Word;ErrorClass,SuggestedAction,
  ErrorLocus:Byte);Near;Forward;
Function GetExtendedErrorCode:Word;Near;Forward;
Function GetExtendedErrorClass:Byte;Near;Forward;
Function GetExtendedSuggestedAction:Byte;Near;Forward;
Function GetExtendedErrorLocus:Byte;Near;Forward;
Procedure ClearExtendedError;Near;Forward;
Procedure SetStandardError(ErrorCode:Word);Near;Forward;

{ Fonctions d'accès aux données dans Code Segment }
Function GetCurrentDrive: Byte;Near;Forward;
Procedure SetCurrentDrive(Drive: Byte);Near;Forward;
Function GetCurrentDirCluster(Index: Byte): Word;Near;Forward;
Function GetCurrentDirPath(Index: Byte): String;Near;Forward;
Procedure SetCurrentDirDrive(Index, Drive: Byte);Near;Forward;
Procedure SetCurrentDirCluster(Index: Byte; Cluster: Word);Near;Forward;
Procedure SetCurrentDirPath(Index: Byte; Path: String);Near;Forward;

{ Fonctions d'accès aux données FileTable dans Code Segment }
Function GetFileTableInUse(Index: Byte): Boolean;Near;Forward;
Function GetFileTableDrive(Index: Byte): Byte;Near;Forward;
Function GetFileTableFirstCluster(Index: Byte): Word;Near;Forward;
Function GetFileTableFileSize(Index: Byte): LongInt;Near;Forward;
Function GetFileTableCurrentPos(Index: Byte): LongInt;Near;Forward;
Function GetFileTableAttributes(Index: Byte): Byte;Near;Forward;
Function GetFileTableCurrentCluster(Index: Byte): Word;Near;Forward;
Function GetFileTableClusterOffset(Index: Byte): Word;Near;Forward;
Procedure SetFileTableInUse(Index: Byte; InUse: Boolean);Near;Forward;

{ Procédure pour initialiser la table des verrous }
Procedure InitializeFileLocks;Near;Forward;
Procedure SetFileTableDrive(Index: Byte; Drive: Byte);Near;Forward;
Procedure SetFileTableFirstCluster(Index: Byte; FirstCluster: Word);Near;
  Forward;
Procedure SetFileTableFileSize(Index: Byte; FileSize: LongInt);Near;Forward;
Procedure SetFileTableCurrentPos(Index: Byte; CurrentPos: LongInt);Near;Forward;
Procedure SetFileTableAttributes(Index: Byte; Attributes: Byte);Near;Forward;
Procedure SetFileTableCurrentCluster(Index: Byte; CurrentCluster: Word);Near;
  Forward;
Procedure SetFileTableClusterOffset(Index: Byte; ClusterOffset: Word);Near;
  Forward;

{ Fonctions d'accès aux nouvelles variables }
Function GetLastReturnCode: Word;Near;Forward;
Procedure SetLastReturnCode(ReturnCode: Word);Near;Forward;
Function GetCurrentPSP: Word;Near;Forward;
Procedure SetCurrentPSP(PSP: Word);Near;Forward;

{ Fonctions d'accès au flag de vérification }
Function GetVerifyFlag: Byte;Near;Forward;
Procedure SetVerifyFlag(Flag: Byte);Near;Forward;

Function CSeg: Word;Near;Forward;

Procedure ConPutChar(C:Byte);Near;Forward;

Procedure BEGIN_KERNEL;
Var
 I:Byte;
 Msg:String[60];
 IntSeg, IntOfs: Word;
Begin
 { Chargeur de la suite d'IO.SYS : le secteur de boot (MS-DOS 5/6) ne charge que
   les 3 premiers secteurs
   du fichier en 0070:0000 (DL = unite de boot,
     BPB en 0000:7C00). On relit ici le reste depuis la racine
   du volume (fichier contigu) ;
     sous /KERNELTEST (fichier deja entierement charge) la relecture est sans
   effet. Ce code doit rester dans les 1536 premiers octets du fichier. Comme
     IO.SYS (> 30 Ko) recouvre la pile
   du secteur de boot (0000:7C00) et le BPB,
     le chargeur copie ce dont il a besoin et passe sur une pile privee
   9000:FFF0 sur laquelle le noyau continue de s'executer. }
 ASM
  MOV BX,SS
  MOV CX,SP
  CLI
  MOV AX,9000h
  MOV SS,AX
  MOV SP,0FFF0h
  STI
  PUSH BX
  PUSH CX
  PUSH BP
  MOV BP,SP
  SUB SP,24
  PUSH DS
  PUSH ES
  PUSH SI
  PUSH DI
  MOV [BP-2],DL
  JMP @Main
@Rd:
  PUSH AX
  PUSH BX
  PUSH CX
  PUSH DX
  MOV CX,[BP-20]
  CMP DX,CX
  JAE @RdErr
  DIV CX
  INC DL
  MOV [BP-18],DL
  XOR DX,DX
  MOV CX,[BP-22]
  DIV CX
  MOV DH,DL
  MOV CH,AL
  MOV AL,AH
  AND AL,3
  MOV CL,6
  SHL AL,CL
  OR AL,[BP-18]
  MOV CL,AL
  MOV DL,[BP-2]
  MOV AX,0201h
  INT 13h
  POP DX
  POP CX
  POP BX
  POP AX
  DB 0C3h
@RdErr:
  STC
  POP DX
  POP CX
  POP BX
  POP AX
  DB 0C3h
@Main:
  XOR AX,AX
  MOV DS,AX
  MOV AX,[7DFEh]
  CMP AX,0AA55h
  JE @HaveBPB
  MOV AX,8000h
  MOV ES,AX
  MOV DS,AX
  MOV BX,7C00h
  MOV AX,0201h
  MOV CX,0001h
  XOR DH,DH
  MOV DL,[BP-2]
  INT 13h
  JC @Done
@HaveBPB:
  MOV AX,[7C18h]
  MOV [BP-20],AX
  MOV AX,[7C1Ah]
  MOV [BP-22],AX
  MOV AL,[7C0Dh]
  MOV [BP-24],AL
  MOV AL,[7C10h]
  XOR AH,AH
  MOV CX,[7C16h]
  MUL CX
  ADD AX,[7C0Eh]
  ADC DX,0
  ADD AX,[7C1Ch]
  ADC DX,[7C1Eh]
  MOV [BP-4],AX
  MOV [BP-6],DX
  MOV AX,[7C11h]
  MOV CL,5
  SHL AX,CL
  ADD AX,[7C0Bh]
  DEC AX
  XOR DX,DX
  MOV CX,[7C0Bh]
  DIV CX
  MOV [BP-8],AX
  MOV CX,AX
  MOV AX,[BP-4]
  MOV DX,[BP-6]
@RootLoop:
  OR CX,CX
  JZ @Done
  PUSH CX
  PUSH AX
  PUSH DX
  MOV BX,8000h
  MOV ES,BX
  XOR BX,BX
  CALL @Rd
  JC @RootErr
  XOR DI,DI
  MOV CX,16
@Ent:
  PUSH CX
  MOV AX,ES:[DI]
  CMP AX,4F49h
  JNE @NoMatch
  MOV AX,ES:[DI+2]
  CMP AX,2020h
  JNE @NoMatch
  MOV AX,ES:[DI+4]
  CMP AX,2020h
  JNE @NoMatch
  MOV AX,ES:[DI+6]
  CMP AX,2020h
  JNE @NoMatch
  MOV AX,ES:[DI+8]
  CMP AX,5953h
  JNE @NoMatch
  MOV AL,ES:[DI+10]
  CMP AL,53h
  JE @Found
@NoMatch:
  POP CX
  ADD DI,32
  LOOP @Ent
  POP DX
  POP AX
  POP CX
  ADD AX,1
  ADC DX,0
  DEC CX
  JMP @RootLoop
@RootErr:
  ADD SP,6
  JMP @Done
@Found:
  MOV AX,ES:[DI+1Ah]
  MOV [BP-10],AX
  MOV AX,ES:[DI+1Ch]
  MOV DX,ES:[DI+1Eh]
  ADD SP,8
  ADD AX,511
  ADC DX,0
  MOV CL,9
  SHR AX,CL
  MOV CL,7
  SHL DX,CL
  OR AX,DX
  MOV [BP-12],AX
  MOV AX,[BP-4]
  MOV DX,[BP-6]
  ADD AX,[BP-8]
  ADC DX,0
  MOV [BP-14],AX
  MOV [BP-16],DX
  MOV AX,[BP-10]
  SUB AX,2
  MOV CL,[BP-24]
  XOR CH,CH
  MUL CX
  ADD AX,[BP-14]
  ADC DX,[BP-16]
  MOV [BP-4],AX
  MOV [BP-6],DX
  MOV SI,3
@Ld:
  CMP SI,[BP-12]
  JAE @Done
  MOV AX,SI
  MOV CL,5
  SHL AX,CL
  ADD AX,70h
  MOV ES,AX
  XOR BX,BX
  MOV AX,[BP-4]
  MOV DX,[BP-6]
  ADD AX,SI
  ADC DX,0
  CALL @Rd
  JC @Done
  INC SI
  JMP @Ld
@Done:
  POP DI
  POP SI
  POP ES
  POP DS
  MOV AL,[BP-2]
  MOV SP,BP
  ADD SP,6
  MOV BP,SP
  SUB SP,128
  PUSH CS
  POP DS
  AND AL,80h
  JZ @BootA
  MOV AL,2
@BootA:
  MOV BYTE PTR [Data + 2],AL
 END;
 { Le noyau est chargé comme IO.SYS : DS=CS pour les chaînes et constantes que
   le
   compilateur place dans le segment du noyau (pas de segment de données
     séparé). }
 ASM
  PUSH CS
  POP DS
 END;
 { Message de démarrage (page de codes 437 : é = 130) }
 Msg:='Demarrage du MSDOS-0...';
 Msg[2]:=#130;
 ConPutChar(13);
 ConPutChar(10);
 For I:=1 To Length(Msg) Do ConPutChar(Ord(Msg[I]));
 ConPutChar(13);
 ConPutChar(10);
 { Initialiser répertoires courants via les fonctions d'accès Code Segment }
 For I:=0 To NDrv-1 Do Begin
  SetCurrentDirDrive(I, I);
  SetCurrentDirCluster(I, 0); { Répertoire racine }
  SetCurrentDirPath(I, '\');
 End;

 { Initialiser table des fichiers ouverts }
 For I:=0 To 19 Do Begin
  SetFileTableInUse(I, False);
 End;

 { Initialiser table des verrous de fichiers }
 InitializeFileLocks;

 { Vérifier si l'interruption 1Ah existe et l'installer si nécessaire }
 GetIntVec($1A, IntSeg, IntOfs);
 If (IntSeg = 0) And (IntOfs = 0) Then Begin
  { L'interruption 1Ah n'existe pas, installer notre gestionnaire }
  SetIntVec($1A, CSeg, Ofs(Intr1Ah));
 End;

 SetIntVec($20,CSeg,Ofs(Intr20hEntry));
 SetIntVec($21,CSeg,Ofs(Intr21h));
 SetIntVec($25,CSeg,Ofs(Intr25h));
 SetIntVec($26,CSeg,Ofs(Intr26h));
 SetIntVec($28,CSeg,Ofs(Intr28h));
 SetIntVec($2A,CSeg,Ofs(Intr2Ah));
 SetIntVec($2F,CSeg,Ofs(Intr2Fh));
 SetIntVec($33,CSeg,Ofs(Intr33h));

 { Partition du disque dur (lecteur C:) }
 InitPartition;

 { Initialiser le gestionnaire de mémoire }
 InitializeMemoryManager;

 { CONFIG.SYS : FILES, BUFFERS, LASTDRIVE, SHELL, DEVICE, INSTALL }
 InitConfig;
 { Charger et exécuter COMMAND.COM ou COMMAND.EXE }
 { Le processeur de commandes est relance s'il se termine (EXIT) ; absent,
   le noyau s'arrête }
 While LoadAndExecuteCommandProcessor Do;
 Msg:='Interpreteur de commandes introuvable (COMMAND.EXE)';
 ConPutChar(13);
 ConPutChar(10);
 For I:=1 To Length(Msg) Do ConPutChar(Ord(Msg[I]));
 ASM
 @Halt:
  CLI
  HLT
  JMP @Halt
  DB 'DEBUT DU NOYAU MSDOS-0'
 END;
End;

{ Debut de la partition du disque dur C: (0 si le disque commence par un secteur
  de boot FAT : superfloppy) }
Procedure InitPartition;
Var Buf:Array[0..511] of Byte;
Begin
 SetPartOfs(0);
 If DiskTransfer($02,2,0,@Buf) Then
  If (Buf[0]<>$EB) And (Buf[0]<>$E9) And (Buf[510]=$55) And (Buf[511]=$AA) Then
   SetPartOfs(Word(Buf[$1C6])+Word(Buf[$1C7])*256+(LongInt(Buf[$1C8])+
     LongInt(Buf[$1C9])*256)*65536);
End;

Procedure Data;Assembler;ASM
@DataMOS:
 DB 0          { Key:   Touche }
 DB 0          { InDos: Dans l'Interruption DOS? }
 DB 2          { CurrDisk: Disque courant (2=C: par défaut) }
 DW 0          { DTASegment: Segment DTA (initialisé à 0) }
 DW 80h        { DTAOffset: Offset DTA (par défaut 80h) }
 DW 33         { CurrentCountry: Pays actuel (33=France par défaut) }
 DW 0          { LastReturnCode: Code de retour du dernier programme }
 DW 1000h      { CurrentPSP: Segment du PSP courant (par défaut 1000h) }
@VerifyFlag:
 DB 0          { VerifyFlag: Flag de vérification en écriture (0=off, 1=on) }

 { FindState: FindFileState - 100 bytes }
 { SearchMask: String[12] = 13 bytes }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0
 { SearchPath: String[80] = 81 bytes }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0          { SearchAttr: Byte }
 DW 0          { CurrentDir: Word }
 DW 0          { CurrentEntry: Word }
 DB 0          { Active: Boolean }

 { CurrentDir: Array[0..5] of Record : Drive(1) + Cluster(2) + Path(1+63) = 67
   octets par lecteur }
 DB 0,0,0,1,'\',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 1,0,0,1,'\',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 2,0,0,1,'\',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 3,0,0,1,'\',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 4,0,0,1,'\',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 5,0,0,1,'\',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 { FileTable:Array[0..19]of FileTableEntry - 20 entrées de 17 octets = 340 bytes
   }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0  { FileTable[0] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0  { FileTable[1] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0  { FileTable[2] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0  { FileTable[3] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0  { FileTable[4] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0  { FileTable[5] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0  { FileTable[6] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0  { FileTable[7] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0  { FileTable[8] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0  { FileTable[9] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0  { FileTable[10] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0  { FileTable[11] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0  { FileTable[12] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0  { FileTable[13] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0  { FileTable[14] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0  { FileTable[15] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0  { FileTable[16] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0  { FileTable[17] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0  { FileTable[18] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0  { FileTable[19] }

 { Données pour fonction 59h - Get Extended Error Information }
 DW 0          { ExtendedError }
 DB 0          { ErrorClass }
 DB 0          { SuggestedAction }
 DB 0          { ErrorLocus }
 DW 1          { MemoryStrategy: First Fit par défaut }
 DW 0          { UMBLinkState: Non liés par défaut }

 { Table des verrous de fichiers - FileLocks: Array[0..19] of FileLockEntry }
 { Chaque FileLockEntry = 1+2+2+4+4+1 = 14 bytes * 20 = 280 bytes }
 { FileLock[0] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0
 { FileLock[1] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0
 { FileLock[2] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0
 { FileLock[3] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0
 { FileLock[4] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0
 { FileLock[5] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0
 { FileLock[6] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0
 { FileLock[7] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0
 { FileLock[8] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0
 { FileLock[9] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0
 { FileLock[10] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0
 { FileLock[11] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0
 { FileLock[12] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0
 { FileLock[13] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0
 { FileLock[14] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0
 { FileLock[15] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0
 { FileLock[16] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0
 { FileLock[17] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0
 { FileLock[18] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0
 { FileLock[19] }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0          { PendingLF }
 { FxLoc : emplacement de l'entree de repertoire de chaque handle (20 x 5
   octets) }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 { PartOfs : debut de la partition du disque dur (secteurs, 4 octets) }
 DB 0,0,0,0
 { SftRef : compteur de references de chaque entree de la table des fichiers
   ouverts (20 octets) }
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 { KSP : sommet de la pile privee du noyau (segment 9000h) }
 DW 0F000h
 { CfgSeg : segment du bloc de configuration (CONFIG.SYS) }
 DW 0

 { Structure Liste des Listes pour fonction 52h (disposition MS-DOS 4+) : le mot
   qui precede est le segment du
   premier MCB ; l'en-tete du pilote NUL est en LoL+22h,
     tete de la chaine des pilotes de peripheriques }
 DW 1080h
@DOSListOfLists:
 DW 0,0        { 00 : premier DPB }
 DW 0,0        { 04 : premiere SFT }
 DW 0,0        { 08 : pilote CLOCK$ }
 DW 0,0        { 0C : pilote CON }
 DW 512        { 10 : taille maximale de secteur }
 DW 0,0        { 12 : premier tampon disque }
 DW 0,0        { 16 : tableau des repertoires courants }
 DW 0,0        { 1A : table FCB }
 DW 0          { 1E : FCB proteges }
 DB 1          { 20 : nombre d'unites de bloc }
 DB 6          { 21 : LASTDRIVE }
 DW 0FFFFh,0FFFFh { 22 : en-tete du pilote NUL : suivant (fin de chaine) }
 DW 8004h      { attributs : peripherique caractere, NUL }
 DW @NulRet    { strategie }
 DW @NulRet    { interruption }
 DB 'NUL     '
 DB 0          { 34 : unites jointes }
@NulRet:
 DB 0CBh
END;

Procedure Intr1Ah;Assembler;ASM
 { INT 1Ah - Time of Day Services (Services d'horloge temps réel) }
 {
   AH = 00h : Read System Time (lire l'heure système)
         Retour : CX:DX = nombre de ticks depuis minuit
                 AL = 1 si passage à minuit depuis dernier appel
   AH = 01h : Set System Time (fixer l'heure système)
         Entrée : CX:DX = nombre de ticks depuis minuit

   1 tick = 1/18.2 seconde (environ 55ms)
   1440 minutes * 60 secondes * 18.2 ticks = 1573040 ticks par jour
 }

 PUSH BP
 MOV BP,SP
 PUSH DS
 PUSH ES

 { Sauvegarder les registres modifiés }
 PUSH BX
 PUSH SI
 PUSH DI

 PUSH AX                    { AH = fonction : MOV AX,CS la detruirait }
 MOV AX,CS
 MOV DS,AX
 POP AX

 CMP AH,00h
 JE @ReadTime
 CMP AH,01h
 JE @SetTime
 JMP @Exit

@ReadTime:
 { Lire l'heure système - simulation basée sur un compteur }
 { Pour simplicité, on retourne une valeur incrémentée }
 MOV CX,WORD PTR CS:[@TimeHigh]
 MOV DX,WORD PTR CS:[@TimeLow]

 { Incrémenter le compteur pour simulation }
 ADD DX,1
 ADC CX,0

 { Vérifier si on dépasse 24h (1573040 ticks) }
 CMP CX,18h      { 1573040 = 0x180070 }
 JB @NoMidnight
 CMP DX,0070h
 JB @NoMidnight

 { Passage à minuit - reset à 0 }
 MOV CX,0
 MOV DX,0
 MOV AL,1        { Indiquer passage à minuit }
 JMP @SaveAndExit

@NoMidnight:
 MOV AL,0        { Pas de passage à minuit }

@SaveAndExit:
 MOV WORD PTR CS:[@TimeHigh],CX
 MOV WORD PTR CS:[@TimeLow],DX
 JMP @Exit

@SetTime:
 { Fixer l'heure système }
 MOV WORD PTR CS:[@TimeHigh],CX
 MOV WORD PTR CS:[@TimeLow],DX
 JMP @Exit

@Exit:
 POP DI
 POP SI
 POP BX
 POP ES
 POP DS
 POP BP
 IRET

@TimeHigh: DW 0    { Partie haute du compteur de ticks }
@TimeLow:  DW 0    { Partie basse du compteur de ticks }
END;

Procedure Intr21hCore;Assembler;ASM
 STI
 INC Data.DataMOS.InDos
@CallFunc:
 { saut vers la fonction AH en conservant BX (parametre des fonctions) }
 CMP AH,70h { fonctions au-dela de 70h : sans effet }
 JA @Xit
 PUSH BX
 MOV BL,AH
 XOR BH,BH
 SHL BX,1
 MOV BX,@Label.Word[BX]
 PUSH BP
 MOV BP,SP
 XCHG BX,[BP+2]
 POP BP
 DB 0C3h               { RET proche vers la fonction }
@Label:
 DW @00h { Fonction 00h - Terminer le programme }
 DW @01h { Fonction 01h - Entree de caractere avec echo }
 DW @02h { Fonction 02h - Sortie de caractere }
 DW @03h { Fonction 03h - Entree de caractere depuis AUX }
 DW @04h { Fonction 04h - Sortie de caractere vers AUX }
 DW @05h { Fonction 05h - Sortie de caractere vers PRN }
 DW @06h { Fonction 06h - Entree/sortie directe de console }
 DW @07h { Fonction 07h - Entree de caractere directe sans sortie }
 DW @08h { Fonction 08h - Entree de caractere sans sortie}
 DW @09h { Fonction 09h - Affichage de chaine terminee par $ }
 DW @0Ah { Fonction 0Ah - Lecture de chaine avec buffer }
 DW @0Bh { Fonction 0Bh - Lire l'etat d'entree}
 DW @0Ch { Fonction 0Ch - Vider le tampon et appeler la fonction d'entree }
 DW @0Dh { Fonction 0Dh - Reinitialisation du disque }
 DW @0Eh { Fonction 0Eh - Selectionne le disque courant }
 DW @0Fh { Fonction 0Fh - Ouvrir un fichier avec FCB }
 DW @10h { Fonction 10h - Fermer un fichier avec FCB }
 DW @11h { Fonction 11h - Rechercher le premier fichier avec FCB }
 DW @12h { Fonction 12h - Rechercher le fichier suivant avec FCB }
 DW @13h { Fonction 13h - Supprimer un fichier avec FCB }
 DW @14h { Fonction 14h - Lecture séquentielle avec FCB }
 DW @15h { Fonction 15h - Ecriture séquentielle avec FCB }
 DW @16h { Fonction 16h - Créer un fichier avec FCB }
 DW @17h { Fonction 17h - Renommer un fichier avec FCB }
 DW @18h { Fonction 18h - Fonction réservée }
 DW @19h { Fonction 19h - Demande le lecteur courant }
 DW @1Ah { Fonction 1Ah - Définir l'adresse DTA }
 DW @1Bh { Fonction 1Bh - Obtenir informations allocation drive par défaut }
 DW @1Ch { Fonction 1Ch - Obtenir informations allocation drive spécifique }
 DW @1Dh { Fonction 1Dh - Fermer tous les fichiers }
 DW @1Eh { Fonction 1Eh - Fonction réservée/non documentée }
 DW @1Fh { Fonction 1Fh - Fonction réservée/non documentée }
 DW @20h { Fonction 20h - Terminer le programme (obsolète) }
 DW @21h { Fonction 21h - Lecture aléatoire avec FCB }
 DW @22h { Fonction 22h - Ecriture aléatoire avec FCB }
 DW @23h { Fonction 23h - Obtenir la taille de fichier avec FCB }
 DW @24h { Fonction 24h - Définir l'adresse aléatoire avec FCB }
 DW @25h { Fonction 25h - Fixe le vecteur d'Interruption}
 DW @26h { Fonction 26h - Créer un nouveau PSP }
 DW @27h { Fonction 27h - Lecture aléatoire de bloc avec FCB }
 DW @28h { Fonction 28h - Ecriture aléatoire de bloc avec FCB }
 DW @29h { Fonction 29h - Analyser nom de fichier dans FCB }
 DW @2Ah { Fonction 2Ah - Lire la date }
 DW @2Bh { Fonction 2Bh - Fixe la date }
 DW @2Ch { Fonction 2Ch - Lire l'heure système }
 DW @2Dh { Fonction 2Dh - Fixer l'heure système }
 DW @2Eh { Fonction 2Eh - Fixer/réinitialiser le drapeau de vérification }
 DW @2Fh { Fonction 2Fh - DOS Multiplex Interrupt }
 DW @30h { Fonction 30h - Get DOS Version }
 DW @31h { Fonction 31h - Terminate Stay Resident (TSR) }
 DW @32h { Fonction 32h - Get Drive Parameter Block (DPB) }
 DW @33h { Fonction 33h - Multi-fonction }
 DW @34h { Fonction 34h - Demande l'adresse du drapeau "InDos" }
 DW @35h { Fonction 35h - Demande le vecteur d'Interruption}
 DW @36h { Fonction 36h - Get free disk space }
 DW @37h { Fonction 37h - Switch character functions }
 DW @38h { Fonction 38h - Get/Set Country Information }
 DW @39h { Fonction 39h - Create Subdirectory }
 DW @3Ah { Fonction 3Ah - Remove Directory }
 DW @3Bh { Fonction 3Bh - Change Directory }
 DW @3Ch { Fonction 3Ch - Create or Open File }
 DW @3Dh { Fonction 3Dh - Open File }
 DW @3Eh { Fonction 3Eh - Close File }
 DW @3Fh { Fonction 3Fh - Read File }
 DW @40h { Fonction 40h - Write File }
 DW @41h { Fonction 41h - Delete File }
 DW @42h { Fonction 42h - Seek File }
 DW @43h { Fonction 43h - Get/Set File Attributes }
 DW @44h { Fonction 44h - IOCTL (Input/Output Control) }
 DW @45h { Fonction 45h - Duplicate Handle }
 DW @46h { Fonction 46h - Force Duplicate Handle }
 DW @47h { Fonction 47h - Get Current Directory }
 DW @48h { Fonction 48h - Allocate Memory Block }
 DW @49h { Fonction 49h - Free Memory Block }
 DW @4Ah { Fonction 4Ah - Modify Memory Block }
 DW @4Bh { Fonction 4Bh - EXEC - Load and Execute Program }
 DW @4Ch { Fonction 4Ch - Terminate Program }
 DW @4Dh { Fonction 4Dh - Get Return Code }
 DW @4Eh { Fonction 4Eh - Find First File }
 DW @4Fh { Fonction 4Fh - Find Next File }
 DW @50h { Fonction 50h - Set PSP Address }
 DW @51h { Fonction 51h - Get PSP Address }
 DW @52h { Fonction 52h - Get List of Lists }
 DW @53h { Fonction 53h - Translate BPB to DPB }
 DW @54h { Fonction 54h - Get Verify Flag }
 DW @55h { Fonction 55h - Create Child PSP }
 DW @56h { Fonction 56h - Rename/Move File }
 DW @57h { Fonction 57h - Get/Set File Date and Time }
 DW @58h { Fonction 58h - Get/Set Memory Allocation Strategy }
 DW @59h { Fonction 59h - Get Extended Error Information }
 DW @5Ah { Fonction 5Ah - Create Temporary File }
 DW @5Bh { Fonction 5Bh - Create New File }
 DW @5Ch { Fonction 5Ch - Lock/Unlock File Region }
 DW @Xit { Fonction 5Dh - a d�velopper }
 DW @Xit { Fonction 5Eh - a d�velopper }
 DW @Xit { Fonction 5Fh - a d�velopper }
 DW @Xit { Fonction 60h - a d�velopper }
 DW @Xit { Fonction 61h - a d�velopper }
 DW @51h { Fonction 62h - Get PSP Address }
 DW @Xit { Fonction 63h - a d�velopper }
 DW @Xit { Fonction 64h - a d�velopper }
 DW @Xit { Fonction 65h - a d�velopper }
 DW @Xit { Fonction 66h - a d�velopper }
 DW @68h { Fonction 67h - Set Handle Count (accepte) }
 DW @68h { Fonction 68h - Commit File }
 DW @Xit { Fonction 69h - a d�velopper }
 DW @Xit { Fonction 6Ah - a d�velopper }
 DW @Xit { Fonction 6Bh - a d�velopper }
 DW @Xit { Fonction 6Ch - a d�velopper }
 DW @Xit { Fonction 6Dh - a d�velopper }
 DW @F2h { Fonction 6Eh - interne : lecture absolue (INT 25h) }
 DW @F3h { Fonction 6Fh - interne : ecriture absolue (INT 26h) }
 DW @70h { Fonction 70h - interne : relire la table de partition (INSTALL) }

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 00h: Terminer le programme                      }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@00h:
 MOV AH,4Ch                 { Fonction 4Ch - Terminaison avec code de retour }
 XOR AL,AL                  { Code de retour = 0 }
 INT 21h                    { Appel recursif pour terminer proprement }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 01h: Entree de caractere avec echo              }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@01h:
 PUSH BX
 PUSH CX
 PUSH DX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DS
 MOV AX,1
 PUSH AX
 PUSH CS
 POP DS
 CALL CharIn21
 POP DS
 POP ES
 POP DI
 POP SI
 POP DX
 POP CX
 POP BX
 CMP AX,0FFFEh
 JE @01hCon
 CMP AX,0FFFFh
 JNE @01hGot
 MOV AX,1Ah
@01hGot:
 CLC
 JMP @Xit
@01hCon:
 MOV AL,Data.DataMOS.Key
 OR  AL,AL
 JE  @01GetInt16h
 MOV AH,0
 JMP @01EchoChar
@01GetInt16h:
 XOR AX,AX
 INT 16h
@01EchoChar:
 MOV Data.DataMOS.Key,AH    { Sauver la touche suivante }
 CMP AL,3                   { Ctrl+C/Ctrl+Break ? }
 JNE @01NoBreak
 INT 23h
@01NoBreak:
 PUSH AX                    { Sauver le caractere }
 MOV DL,AL
 MOV AH,02h                 { Fonction 02h - Sortie caractere }
 INT 21h
 POP AX                     { Restaurer le caractere }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 02h: Sortie de caractere                        }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@02h:
 PUSH BX
 PUSH CX
 PUSH DX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DS
 XOR DH,DH
 PUSH DX
 PUSH CS
 POP DS
 CALL CharOut21
 POP DS
 POP ES
 POP DI
 POP SI
 POP DX
 POP CX
 POP BX
 MOV AL,DL
 CLC
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 03h: Entree de caractere depuis AUX             }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@03h:
 MOV AH,02h                 { BIOS - Lire caractere serie }
 XOR DX,DX                  { Port COM1 }
 INT 14h
 TEST AH,80h                { Verifier timeout }
 JZ @03NoError
 MOV AL,1Ah                 { Code EOF si erreur }
@03NoError:
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 04h: Sortie de caractere vers AUX               }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@04h:
 MOV AL,DL
 MOV AH,01h                 { BIOS - Ecrire caractere serie }
 XOR DX,DX                  { Port COM1 }
 INT 14h
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 05h: Sortie de caractere vers PRN (imprimante)  }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@05h:
 MOV AL,DL
 XOR AH,AH                  { BIOS - Imprimer caractere }
 XOR DX,DX                  { Port LPT1 }
 INT 17h
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 06h: Entree/sortie directe de console           }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@06h:
 CMP DL,0FFh                { Fonction d'entree ? }
 JNE @06Output
 { Fonction d'entree }
 MOV AL,Data.DataMOS.Key
 OR  AL,AL
 JE  @06CheckKeyboard
 MOV AH,0
 MOV Data.DataMOS.Key,0     { Effacer la touche }
 CMP AL,0                   { Zero Flag = 0 si caractere disponible }
 JMP @Xit
@06CheckKeyboard:
 MOV AH,01h                 { BIOS - Verifier si touche disponible }
 INT 16h
 JZ  @06NoKey              { Pas de touche }
 XOR AX,AX                  { Lire la touche }
 INT 16h
 MOV Data.DataMOS.Key,AH    { Sauver scan code }
 TEST AL,AL                 { Zero Flag = 0 si caractere valide }
 JMP @Xit
@06NoKey:
 XOR AL,AL                  { Pas de caractere - Zero Flag = 1 }
 JMP @Xit
@06Output:
 { Fonction de sortie }
 MOV AH,02h
 INT 21h
 MOV AL,DL
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 07h: Entree de caractere directe sans sortie }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@07h:
 PUSH BX
 PUSH CX
 PUSH DX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DS
 MOV AX,0
 PUSH AX
 PUSH CS
 POP DS
 CALL CharIn21
 POP DS
 POP ES
 POP DI
 POP SI
 POP DX
 POP CX
 POP BX
 CMP AX,0FFFEh
 JE @07hCon
 CMP AX,0FFFFh
 JNE @07hGot
 MOV AX,1Ah
@07hGot:
 CLC
 JMP @Xit
@07hCon:
 MOV AL,Data.DataMOS.Key
 OR  AL,AL
 JE  @GetInt16h
 MOV AH,0
 JMP @SetNextKey
@GetInt16h:
 XOR AX,AX
 INT 16h
@SetNextKey:
 MOV Data.DataMOS.Key,AH
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 08h: Entree de caractere sans sortie }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@08h:
 PUSH BX
 PUSH CX
 PUSH DX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DS
 MOV AX,0
 PUSH AX
 PUSH CS
 POP DS
 CALL CharIn21
 POP DS
 POP ES
 POP DI
 POP SI
 POP DX
 POP CX
 POP BX
 CMP AX,0FFFEh
 JE @08hCon
 CMP AX,0FFFFh
 JNE @08hGot
 MOV AX,1Ah
@08hGot:
 CLC
 JMP @Xit
@08hCon:
 MOV AL,Data.DataMOS.Key
 OR  AL,AL
 JE  @08GetInt16h
 MOV AH,0
 JMP @08SetNextKey
@08GetInt16h:
 XOR AX,AX
 INT 16h
@08SetNextKey:
 MOV Data.DataMOS.Key,AH
 CMP AL,3                   { Ctrl+C/Ctrl+Break ? }
 JNE @08NoBreak
 INT 23h
@08NoBreak:
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 09h: Affichage de chaine terminee par $         }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@09h:
 PUSH BX
 PUSH CX
 PUSH DX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DS
 PUSH DS
 PUSH DX
 PUSH CS
 POP DS
 CALL StrOut21
 POP DS
 POP ES
 POP DI
 POP SI
 POP DX
 POP CX
 POP BX
 MOV AL,24h
 CLC
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 0Ah: Lecture de chaine avec buffer              }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@0Ah:
 PUSH SI                    { Sauver registres }
 PUSH DI
 PUSH DS
 PUSH ES
 MOV SI,DX                  { DS:DX pointe sur le buffer }
 MOV DI,DX
 ADD DI,2                   { DI pointe sur le debut de la chaine }
 XOR CX,CX
 MOV CL,[SI]                { Taille maximum du buffer }
 DEC CX                     { Laisser place pour le caractere nul }
 XOR BX,BX                  { Compteur de caracteres lus }
@0ALoop:
 PUSH AX                    { Sauver registres }
 PUSH BX
 PUSH CX
 PUSH DX
 MOV AH,01h                 { Fonction 01h - Entree avec echo }
 INT 21h
 XCHG DI,AX                 { Sauver AX (avec le caractere) dans DI }
 POP DX                     { Restaurer registres }
 POP CX
 POP BX
 POP AX                     { Restaurer AX original }
 XCHG AX,DI                 { Recuperer le caractere dans AX }
 CMP AL,1Ah                 { Fin de fichier (entree redirigee) ? }
 JE @0AEnd
 CMP AL,0Dh                 { Entree (CR) ? }
 JE @0AEnd
 CMP AL,08h                 { Backspace ? }
 JE @0ABackspace
 CMP AL,1Bh                 { Echap ? }
 JE @0ACancel
 CMP BX,CX                  { Buffer plein ? }
 JAE @0ALoop
 MOV [DI+BX],AL             { Stocker le caractere }
 INC BX                     { Incrementer compteur }
 JMP @0ALoop
@0ABackspace:
 OR BX,BX                   { Position 0 ? }
 JE @0ALoop
 DEC BX                     { Decrementer compteur }
 JMP @0ALoop
@0ACancel:
 XOR BX,BX                  { Effacer le buffer }
 JMP @0ALoop
@0AEnd:
 MOV [SI+1],BL              { Stocker le nombre de caracteres lus }
 MOV BYTE PTR [DI+BX],0Dh   { Terminer par CR }
 POP ES                     { Restaurer registres }
 POP DS
 POP DI
 POP SI
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 0Bh: Lire l'etat d'entree }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@0Bh:
 XOR AX,AX
 MOV ES,AX
 LES DX,ES:[041Ah]
 MOV BX,ES
 CMP BX,DX
 JE  @Xit
 MOV AL,0FFh
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - - }
 { Interruption 21h - Fonction 0Ch: Vider le tampon et appeler la fonction
   d'entree }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - - }
@0Ch:
 PUSH AX
  XOR AX,AX
  MOV ES,AX
  MOV AX,ES:[480h]
  MOV ES:[41Ah],AX
  MOV ES:[41Ch],AX
 POP BX
 JMP @CallFunc

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 0Dh: Reinitialisation du disque                 }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@0Dh:
 PUSH AX                    { Sauver registres }
 PUSH DX
 MOV AH,0Dh                 { BIOS - Reset disque }
 INT 13h                    { Appel BIOS }
 POP DX                     { Restaurer registres }
 POP AX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 0Eh: Selectionne le lecteur courant }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@0Eh:
 PUSH DS
 PUSH CS
 POP DS
 PUSH DX
 MOV AX,2
 PUSH AX
 CALL CfgWord
 POP DX
 POP DS
 { AL = LASTDRIVE : nombre d'unites }
 CMP DL,AL
 JAE @Xit
 MOV BYTE PTR [Data + 2],DL { Stocker CurrentDrive dans DataMOS.CurrDisk }
 MOV Data.DataMOS.CurrDisk,DL { Maintenir compatibilité }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 0Fh: Ouvrir un fichier avec FCB                 }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@0Fh:
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 PUSH DS
 PUSH DX
 PUSH CS
 POP DS
 CALL FcbOpen
 POP DS
 CLC
 POP DX
 POP ES
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 10h: Fermer un fichier avec FCB                 }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@10h:
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 PUSH DS
 PUSH DX
 PUSH CS
 POP DS
 CALL FcbClose
 POP DS
 CLC
 POP DX
 POP ES
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
 { Interruption 21h - Fonction 11h: Rechercher le premier fichier avec FCB     }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
@11h:
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 PUSH DS
 PUSH DX
 PUSH CS
 POP DS
 CALL FcbFindFirst
 POP DS
 CLC
 POP DX
 POP ES
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
 { Interruption 21h - Fonction 12h: Rechercher le fichier suivant avec FCB     }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
@12h:
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 PUSH DS
 PUSH DX
 PUSH CS
 POP DS
 CALL FcbFindNext
 POP DS
 CLC
 POP DX
 POP ES
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
 { Interruption 21h - Fonction 13h: Supprimer un fichier avec FCB              }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
@13h:
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 PUSH DS
 PUSH DX
 PUSH CS
 POP DS
 CALL FcbDelete
 POP DS
 CLC
 POP DX
 POP ES
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
 { Interruption 21h - Fonction 14h: Lecture séquentielle avec FCB              }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
@14h:
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 PUSH DS
 PUSH DX
 PUSH CS
 POP DS
 CALL FcbSeqRead
 POP DS
 CLC
 POP DX
 POP ES
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
 { Interruption 21h - Fonction 15h: Ecriture séquentielle avec FCB             }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
@15h:
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 PUSH DS
 PUSH DX
 PUSH CS
 POP DS
 CALL FcbSeqWrite
 POP DS
 CLC
 POP DX
 POP ES
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
 { Interruption 21h - Fonction 16h: Créer un fichier avec FCB                  }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
@16h:
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 PUSH DS
 PUSH DX
 PUSH CS
 POP DS
 CALL FcbCreate
 POP DS
 CLC
 POP DX
 POP ES
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
 { Interruption 21h - Fonction 17h: Renommer un fichier avec FCB               }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
@17h:
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 PUSH DS
 PUSH DX
 PUSH CS
 POP DS
 CALL FcbRename
 POP DS
 CLC
 POP DX
 POP ES
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
 { Interruption 21h - Fonction 18h: Fonction réservée                          }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
@18h:
 { Fonction réservée dans DOS classique - pas d'implémentation }
 { Certaines versions de DOS utilisent cette fonction à des fins internes }
 MOV AL,0                   { Code de retour neutre }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 19h: Demande le lecteur courant }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@19h:
 MOV AL,BYTE PTR [Data + 2]  { CurrentDrive dans DataMOS.CurrDisk }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
 { Interruption 21h - Fonction 1Ah: Définir l'adresse DTA                      }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
@1Ah:
 { Définir l'adresse du Disk Transfer Area (DTA) }
 { DS:DX contient la nouvelle adresse DTA }
 MOV Data.DataMOS.DTASegment,DS   { Sauvegarder le segment }
 MOV Data.DataMOS.DTAOffset,DX    { Sauvegarder le deplacemnet }
 { Pas de valeur de retour pour cette fonction }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
 { Interruption 21h - Fonction 1Bh: Obtenir infos allocation drive par défaut  }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
@1Bh:
 { Retourner les informations d'allocation pour le lecteur par défaut }
 { Format de retour dans les registres :
   AL = Secteurs par cluster
   CX = Taille d'un secteur en octets
   DX = Nombre de clusters sur le lecteur
   DS:BX pointe sur l'identificateur de média (FAT ID) }
 PUSH ES                    { Sauver registres }
 PUSH DI
 { Valeurs simulées pour un disque standard }
 MOV AL,1                   { 1 secteur par cluster }
 MOV CX,512                 { 512 octets par secteur }
 MOV DX,2880                { 2880 clusters (1.44MB disquette) }
 { Pointer DS:BX sur un identificateur de média fictif }
 PUSH CS
 POP DS
 MOV BX,OFFSET @MediaID
 JMP @1BEnd
@MediaID:
 DB 0F0h                    { ID média pour disquette 1.44MB }
@1BEnd:
 POP DI
 POP ES
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
 { Interruption 21h - Fonction 1Ch: Obtenir infos allocation drive spécifique  }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
@1Ch:
 { Retourner les informations d'allocation pour un lecteur spécifique }
 { DL contient le numéro de lecteur (1=A:, 2=B:, etc.) }
 { Même format de retour que 1Bh }
 PUSH ES                    { Sauver registres }
 PUSH DI
 CMP DL,0                   { Drive 0 = lecteur par défaut ? }
 JE @1CDefaultDrive
 CMP DL,26                  { Vérifier que le lecteur est valide (A-Z) }
 JA @1CError
 { Lecteur spécifique - mêmes valeurs simulées }
 MOV AL,1                   { 1 secteur par cluster }
 MOV CX,512                 { 512 octets par secteur }
 MOV DX,2880                { 2880 clusters }
 PUSH CS
 POP DS
 MOV BX,OFFSET @MediaID1C
 JMP @1CEnd
@1CDefaultDrive:
 { Utiliser le lecteur par défaut }
 MOV AL,1
 MOV CX,512
 MOV DX,2880
 PUSH CS
 POP DS
 MOV BX,OFFSET @MediaID1C
 JMP @1CEnd
@1CError:
 { Lecteur invalide - retourner AL=FFh }
 MOV AL,0FFh
 JMP @1CEnd
@MediaID1C:
 DB 0F0h                    { ID média }
@1CEnd:
 POP DI
 POP ES
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
 { Interruption 21h - Fonction 1Dh: Fermer tous les fichiers                   }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
@1Dh:
 { Fonction non documentée dans DOS classique,
   utilisée pour fermer tous les FCB ouverts }
 { Dans une implémentation complète,
   il faudrait parcourir la table des FCB ouverts }
 { et fermer chaque fichier ouvert }
 PUSH AX                    { Sauver registres }
 PUSH BX
 PUSH CX
 PUSH DX
 { Simulation : ne rien faire car pas de table FCB active dans cette version }
 { Dans un DOS complet, on appellerait une routine pour fermer tous les FCB }
 MOV AL,0                   { Code de retour : succès }
 POP DX                     { Restaurer registres }
 POP CX
 POP BX
 POP AX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
 { Interruption 21h - Fonction 1Eh: Fonction réservée/non documentée           }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
@1Eh:
 { Fonction non documentée dans DOS classique }
 { Utilisée en interne par certaines versions de DOS pour la redirection I/O }
 { Pour compatibilité, on retourne simplement sans erreur }
 MOV AL,0                   { Code de retour : succès (pas d'erreur) }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
 { Interruption 21h - Fonction 1Fh: Fonction réservée/non documentée           }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
@1Fh:
 { Fonction non documentée dans DOS classique }
 { Utilisée en interne par certaines versions de DOS pour la configuration
   d'imprimante }
 { Pour compatibilité, on retourne simplement sans erreur }
 MOV AL,0                   { Code de retour : succès (pas d'erreur) }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
 { Interruption 21h - Fonction 20h: Terminer le programme (obsolète)           }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
@20h:
 { Fonction de terminaison obsolète, équivalente à la fonction 00h }
 MOV AH,4Ch                 { Fonction 4Ch - Terminaison avec code de retour }
 XOR AL,AL                  { Code de retour = 0 }
 INT 21h                    { Appel récursif pour terminer proprement }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
 { Interruption 21h - Fonction 21h: Lecture aléatoire avec FCB                 }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
@21h:
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 PUSH DS
 PUSH DX
 PUSH CS
 POP DS
 CALL FcbRandRead
 POP DS
 CLC
 POP DX
 POP ES
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
 { Interruption 21h - Fonction 22h: Ecriture aléatoire avec FCB                }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
@22h:
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 PUSH DS
 PUSH DX
 PUSH CS
 POP DS
 CALL FcbRandWrite
 POP DS
 CLC
 POP DX
 POP ES
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
 { Interruption 21h - Fonction 23h: Obtenir la taille de fichier avec FCB      }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
@23h:
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 PUSH DS
 PUSH DX
 PUSH CS
 POP DS
 CALL FcbFileSize
 POP DS
 CLC
 POP DX
 POP ES
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
 { Interruption 21h - Fonction 24h: Définir l'adresse aléatoire avec FCB       }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
@24h:
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 PUSH DS
 PUSH DX
 PUSH CS
 POP DS
 CALL FcbSetRandom
 POP DS
 CLC
 POP DX
 POP ES
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 25h: Fixe le vecteur d'Interruption }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@25h:
 XOR BX,BX
 MOV ES,BX
 MOV BL,AL
 {$IFOPT G+}
  SHL BX,2
 {$ELSE}
  SHL BX,1
  SHL BX,1
 {$ENDIF}
 MOV ES:[BX],DX
 MOV ES:[BX+2],DS
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
 { Interruption 21h - Fonction 26h: Créer un nouveau PSP                       }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
@26h:
 { Créer un nouveau Program Segment Prefix }
 { DX contient l'adresse du segment du nouveau PSP }
 PUSH AX                    { Sauver registres }
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH DS
 PUSH ES
 { Dans une implémentation complète, il faudrait :
   1. Allouer un bloc mémoire de 256 octets (100h)
   2. Copier le PSP courant vers le nouveau PSP
   3. Modifier les champs nécessaires (comme la table des handles)
   4. Initialiser les pointeurs vers les routines DOS }
 { Version simplifiée : juste retourner succès }
 MOV AL,0                   { Code de retour: succès }
 POP ES                     { Restaurer registres }
 POP DS
 POP DI
 POP SI
 POP CX
 POP BX
 POP AX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
 { Interruption 21h - Fonction 27h: Lecture aléatoire de bloc avec FCB         }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
@27h:
 PUSH BX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 XOR AX,AX
 PUSH AX
 MOV SI,SP
 PUSH DS
 PUSH DX
 PUSH CX
 PUSH SS
 PUSH SI
 PUSH CS
 POP DS
 CALL FcbBlockRead
 POP CX
 POP DS
 POP DX
 POP ES
 POP DI
 POP SI
 POP BX
 CLC
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
 { Interruption 21h - Fonction 28h: Ecriture aléatoire de bloc avec FCB        }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
@28h:
 PUSH BX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 XOR AX,AX
 PUSH AX
 MOV SI,SP
 PUSH DS
 PUSH DX
 PUSH CX
 PUSH SS
 PUSH SI
 PUSH CS
 POP DS
 CALL FcbBlockWrite
 POP CX
 POP DS
 POP DX
 POP ES
 POP DI
 POP SI
 POP BX
 CLC
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
 { Interruption 21h - Fonction 29h: Analyser nom de fichier dans FCB           }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
@29h:
 PUSH BX
 PUSH CX
 PUSH DX
 PUSH ES
 PUSH DI
 PUSH DS
 XOR AH,AH
 MOV BX,AX
 XOR AX,AX
 PUSH AX
 MOV CX,SP
 PUSH DS
 PUSH SI
 PUSH ES
 PUSH DI
 PUSH BX
 PUSH SS
 PUSH CX
 PUSH CS
 POP DS
 CALL FcbParse
 POP SI
 POP DS
 POP DI
 POP ES
 POP DX
 POP CX
 POP BX
 CLC
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 2Ah: Lire la date   }
 {- - - - - - - - - - - - - - - - - - - - - - - - -}
@2Ah:
 PUSH BX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DS
 PUSH CS
 POP DS
 CALL DateInt21
 POP DS
 MOV CX,AX
 PUSH CX
 PUSH DX
 PUSH DS
 PUSH CS
 POP DS
 CALL WdayInt21
 POP DS
 POP DX
 POP CX
 CLC
 POP ES
 POP DI
 POP SI
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 2Bh: Fixe la date   }
 {- - - - - - - - - - - - - - - - - - - - - - - - -}
@2Bh:
 MOV AH,05h
 INT 1Ah
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
 { Interruption 21h - Fonction 2Ch: Lire l'heure système                       }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
@2Ch:
 PUSH BX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DS
 PUSH CS
 POP DS
 CALL TimeInt21
 POP DS
 MOV CX,AX
 MOV DL,0
 CLC
 POP ES
 POP DI
 POP SI
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
 { Interruption 21h - Fonction 2Dh: Fixer l'heure système                     }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
@2Dh:
 { Fixer l'heure système }
 { Entrée : CH = heures (0-23), CL = minutes (0-59), DH = secondes (0-59),
   DL = centièmes (0-99) }
 { Sortie : AL = 0 si succès, AL = FFh si heure invalide }
 PUSH AX                    { Sauver AX }
 PUSH BX                    { Sauver BX }
 { Vérifier la validité de l'heure }
 CMP CH,23                  { Heures valides ? }
 JA @2DError
 CMP CL,59                  { Minutes valides ? }
 JA @2DError
 CMP DH,59                  { Secondes valides ? }
 JA @2DError
 CMP DL,99                  { Centièmes valides ? }
 JA @2DError
 { Heure valide - appeler le BIOS pour la fixer }
 MOV AH,03h                 { Fonction BIOS - Fixer l'heure }
 INT 1Ah                    { Appel BIOS }
 MOV AL,0                   { Code de retour : succès }
 JMP @2DEnd
@2DError:
 MOV AL,0FFh                { Code d'erreur : heure invalide }
@2DEnd:
 POP BX                     { Restaurer registres }
 XCHG AX,BX                 { Récupérer AL dans BX }
 POP AX                     { Restaurer AX original }
 MOV AL,BL                  { Mettre le code de retour dans AL }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
 { Interruption 21h - Fonction 2Eh: Fixer/réinitialiser drapeau vérification  }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
@2Eh:
 PUSH BX
 PUSH CX
 PUSH DX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DS
 XOR AH,AH
 PUSH AX
 PUSH CS
 POP DS
 CALL DOS2Eh_SetVerifyFlag
 POP DS
 POP ES
 POP DI
 POP SI
 POP DX
 POP CX
 POP BX
 CLC
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
 { Interruption 21h - Fonction 2Fh: DOS Multiplex Interrupt                    }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
@2Fh:
 { DOS Multiplex Interrupt - interface de communication pour TSR et utilitaires
   }
 { Entrée : AH = fonction, AL = sous-fonction, autres registres selon fonction }
 { Cette fonction est utilisée par DOSKEY, PRINT, APPEND, SHARE, etc. }
 { Pour cette implémentation de base, on retourne "fonction non supportée" }
 CMP AH,43h                 { Fonction 43h - Extended Memory Specification (XMS)
   ? }
 JE @2FhXMS
 CMP AH,10h                 { Fonction 10h - SHARE.EXE ? }
 JE @2FhShare
 { Fonction non reconnue - retourner AL=0 (non installé/supporté) }
 XOR AL,AL
 JMP @Xit
@2FhXMS:
 { XMS non implémenté dans ce DOS de base }
 XOR AL,AL
 JMP @Xit
@2FhShare:
 { SHARE.EXE non installé }
 XOR AL,AL
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
 { Interruption 21h - Fonction 30h: Get DOS Version                            }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
@30h:
 { Retourner la version DOS }
 { Sortie : AL = version majeure, AH = version mineure }
 { BH = fabricant OEM (00h = IBM PC-DOS, FFh = MS-DOS) }
 { BL:CX = numéro de série de l'utilisateur (généralement 0) }
 MOV AL,VerDos              { Version majeure (7) }
 MOV AH,SubVerDos           { Version mineure (10) }
 MOV BH,0FFh                { MS-DOS compatible }
 XOR BL,BL                  { Pas de numéro de série utilisateur }
 XOR CX,CX                  { Pas de numéro de série utilisateur }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
 { Interruption 21h - Fonction 31h: Terminate Stay Resident (TSR)              }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
@31h:
 PUSH BX
 PUSH CX
 PUSH DX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DS
 XOR AH,AH
 PUSH AX
 PUSH DX
 PUSH CS
 POP DS
 CALL DOS31h_Keep
 POP DS
 POP ES
 POP DI
 POP SI
 POP DX
 POP CX
 POP BX
 STC
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
 { Interruption 21h - Fonction 32h: Get Drive Parameter Block (DPB)            }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   - }
@32h:
 { Obtenir le DPB (Drive Parameter Block) pour un lecteur spécifié }
 { Entrée : DL = numéro de lecteur (0=défaut, 1=A:, 2=B:, etc.) }
 { Sortie : AL = 0 si succès, FFh si erreur; DS:BX pointe sur le DPB }
 PUSH AX                    { Sauver registres }
 PUSH CX
 PUSH DX
 PUSH DI
 PUSH ES

 { Vérifier le numéro de lecteur }
 CMP DL,0                   { Lecteur par défaut ? }
 JE @32hDefaultDrive
 CMP DL,26                  { Vérifier limite (A-Z) }
 JA @32hError

@32hDefaultDrive:
 { Dans un DOS complet, le DPB contient les informations détaillées du lecteur :
   - Octets par secteur
   - Secteurs par cluster
   - Secteurs réservés
   - Nombre de FAT
   - Entrées répertoire racine
   - Secteurs par FAT
   - Type de média
   etc. }

 { Pour cette implémentation simplifiée, on simule un DPB basique }
 { Créer un DPB fictif en mémoire }
 PUSH CS
 POP DS                     { DS pointe sur notre segment }
 MOV BX,OFFSET @DPB32h      { BX pointe sur le DPB simulé }
 MOV AL,0                   { Code de retour : succès }
 JMP @32hEnd

@32hError:
 { Lecteur invalide }
 MOV AL,0FFh                { Code d'erreur : lecteur invalide }
 XOR BX,BX                  { Pas de DPB valide }
 JMP @32hEnd

@DPB32h:
 { Structure DPB simplifiée (format DOS standard) }
 DB 0                       { Drive number (0=A:, 1=B:, etc.) }
 DB 1                       { Unit number }
 DW 512                     { Bytes per sector }
 DB 0                       { Sectors per cluster - 1 }
 DB 1                       { Shift count for sectors per cluster }
 DW 1                       { Reserved sectors }
 DB 2                       { Number of FATs }
 DW 224                     { Root directory entries }
 DW 2880                    { Total sectors }
 DB 0F0h                    { Media descriptor }
 DW 9                       { Sectors per FAT }
 DW 18                      { Sectors per track }
 DW 2                       { Number of heads }
 DD 0                       { Hidden sectors }
 DD 0                       { Large total sectors }
 DB 0                       { Reserved }
 DB 0                       { Reserved }
 DB 0                       { Reserved }

@32hEnd:
 POP ES                     { Restaurer registres }
 POP DI
 POP DX
 POP CX
 { Le code de retour est déjà dans AL }
 { BX contient déjà l'offset du DPB }
 { Restaurer AX original mais garder AL }
 XCHG AL,AH                 { Échanger AL et AH temporairement }
 POP AX                     { Restaurer AX original }
 XCHG AL,AH                 { Remettre le code de retour dans AL }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 33h: Multi-fonction }
 {- - - - - - - - - - - - - - - - - - - - - - - - -}
@33h:
 { Multi-fonction de contrôle système }
 CMP AL,00h                 { Sous-fonction 00h : Get Control Break state ? }
 JE @33h00h
 CMP AL,01h                 { Sous-fonction 01h : Set Control Break state ? }
 JE @33h01h
 CMP AL,05h                 { Sous-fonction 05h : Get boot drive ? }
 JE @33h05h
 CMP AL,06h                 { Sous-fonction 06h : Get DOS version (existante) ?
   }
 JE @33h06h
 JMP @Unknown33h

@33h00h:
 { Sous-fonction 00h : Get Control Break check state }
 { Sortie : DL = état actuel (0=désactivé, 1=activé) }
 MOV DL,1                   { Pour cette implémentation, toujours activé }
 JMP @Xit

@33h01h:
 { Sous-fonction 01h : Set Control Break check state }
 { Entrée : DL = nouvel état (0=désactiver, 1=activer) }
 { Dans un DOS complet,
   ceci contrôlerait si Ctrl+C est vérifié pendant les E/S }
 { Pour cette implémentation, on accepte la commande mais sans effet réel }
 CMP DL,1                   { Valeur valide ? }
 JA @Xit                    { Ignorer les valeurs invalides }
 { État accepté, pas de valeur de retour }
 JMP @Xit

@33h05h:
 { Sous-fonction 05h : Get boot drive }
 { Sortie : DL = lecteur de boot (1=A:, 2=B:, 3=C:, etc.) }
 MOV DL,3                   { Simuler boot depuis C: (lecteur 3) }
 JMP @Xit

@33h06h:
 { Sous-fonction 06h : Get DOS version (fonction existante) }
 MOV BL,VerDos              { Version majeure }
 MOV BH,SubVerDos           { Version mineure }
 XOR DX,DX                  { Pas d'information supplémentaire }
 MOV AL,0FFh                { Indicateur de succès }
 JMP @Xit

@Unknown33h:
 { Sous-fonction non supportée }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 34h: Demande l'adresse du drapeau "InDos" }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@34h:
 MOV BX,Offset Data.DataMOS.InDos
 PUSH CS
 POP ES
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 35h: Demande le vecteur d'Interruption }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@35h:
 XOR BX,BX
 MOV ES,BX
 MOV BL,AL
 SHL BX,1
 SHL BX,1
 LES BX,DWord Ptr ES:[BX]
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 36h: Get free disk space                }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@36h:
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DS
 SUB SP,8
 MOV SI,SP
 XOR DH,DH
 PUSH DX
 PUSH SS
 PUSH SI
 PUSH CS
 POP DS
 CALL DOS36h_DiskFree
 OR AX,AX
 JNZ @36hErr
 POP AX
 POP BX
 POP CX
 POP DX
 POP DS
 POP ES
 POP DI
 POP SI
 JMP @Xit
@36hErr:
 ADD SP,8
 POP DS
 POP ES
 POP DI
 POP SI
 MOV AX,0FFFFh
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 37h: Switch character functions         }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@37h:
 { Fonctions de caractère de commutation DOS }
 { AL = sous-fonction : }
 { 00h = Get switch character (généralement '/') }
 { 01h = Set switch character }
 { 02h = Get available device list }
 { 03h = Set available device list }

 CMP AL,00h                 { Sous-fonction 00h : Get switch character ? }
 JE @37h00h
 CMP AL,01h                 { Sous-fonction 01h : Set switch character ? }
 JE @37h01h
 CMP AL,02h                 { Sous-fonction 02h : Get device list ? }
 JE @37h02h
 CMP AL,03h                 { Sous-fonction 03h : Set device list ? }
 JE @37h03h
 JMP @37hUnknown

@37h00h:
 { Sous-fonction 00h : Get switch character }
 { Sortie : DL = caractère de commutation (généralement '/') }
 MOV DL,'/'                 { Caractère de commutation standard DOS }
 JMP @Xit

@37h01h:
 { Sous-fonction 01h : Set switch character }
 { Entrée : DL = nouveau caractère de commutation }
 { Dans un DOS complet, on sauvegarderait ce caractère }
 { Pour cette implémentation, on accepte mais on ne change rien }
 JMP @Xit

@37h02h:
 { Sous-fonction 02h : Get available device list }
 { Cette fonction était utilisée par certaines versions de DOS }
 { pour obtenir des informations sur les périphériques disponibles }
 MOV DL,0                   { Valeur par défaut }
 JMP @Xit

@37h03h:
 { Sous-fonction 03h : Set available device list }
 { Accepter la commande sans effet réel }
 JMP @Xit

@37hUnknown:
 { Sous-fonction non supportée }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 38h: Get/Set Country Information        }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@38h:
 CMP AL,0FFh
 JE @38hBad
 PUSH CX
 PUSH DX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DS
 PUSH DS
 PUSH DX
 PUSH CS
 POP DS
 CALL CountryInt21
 MOV BX,Data.DataMOS.CurrentCountry
 POP DS
 POP ES
 POP DI
 POP SI
 POP DX
 POP CX
 CLC
 JMP @Xit
@38hBad:
 MOV AX,1
 STC
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 39h: Create Subdirectory                        }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@39h:
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 PUSH DS
 PUSH DX
 PUSH CS
 POP DS
 CALL DOS39h_MakeDirectory
 POP DS
 OR AX,AX
 JZ @39hOk
 STC
 JMP @39hEnd
@39hOk:
 CLC
@39hEnd:
 POP DX
 POP ES
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 3Ah: Remove Directory (supprimer répertoire)   }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@3Ah:
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 PUSH DS
 PUSH DX
 PUSH CS
 POP DS
 CALL DOS3Ah_RemoveDirectory
 POP DS
 OR AX,AX
 JZ @3AhOk
 STC
 JMP @3AhEnd
@3AhOk:
 CLC
@3AhEnd:
 POP DX
 POP ES
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 3Bh: Change Directory (changer répertoire)     }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@3Bh:
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 PUSH DS
 PUSH DX
 PUSH CS
 POP DS
 CALL DOS3Bh_ChangeDirectory
 POP DS
 OR AX,AX
 JZ @3BhOk
 STC
 JMP @3BhEnd
@3BhOk:
 CLC
@3BhEnd:
 POP DX
 POP ES
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 3Ch: Create or Open File                        }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@3Ch:
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 PUSH DS
 PUSH DX
 PUSH CS
 POP DS
 CALL CreateInt21
 POP DS
 CMP AX,0FFFFh
 JNE @3ChOk
 PUSH DS
 PUSH CS
 POP DS
 CALL GetExtendedErrorCode
 POP DS
 STC
 JMP @3ChEnd
@3ChOk:
 CLC
@3ChEnd:
 POP DX
 POP ES
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 3Dh: Open File                                  }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@3Dh:
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 PUSH DS
 PUSH DX
 XOR AH,AH
 PUSH AX
 PUSH CS
 POP DS
 CALL OpenInt21
 POP DS
 CMP AX,0FFFFh
 JNE @3DhOk
 PUSH DS
 PUSH CS
 POP DS
 CALL GetExtendedErrorCode
 POP DS
 STC
 JMP @3DhEnd
@3DhOk:
 CLC
@3DhEnd:
 POP DX
 POP ES
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 3Eh: Close File                                 }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@3Eh:
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 PUSH BX
 PUSH CS
 POP DS
 CALL CloseInt21
 POP DS
 OR AX,AX
 JZ @3EhOk
 STC
 JMP @3EhEnd
@3EhOk:
 CLC
@3EhEnd:
 POP DX
 POP ES
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 3Fh: Read File                                  }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@3Fh:
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 XOR AX,AX
 PUSH AX
 MOV SI,SP
 PUSH BX
 PUSH DS
 PUSH DX
 PUSH CX
 PUSH SS
 PUSH SI
 PUSH CS
 POP DS
 CALL ReadInt21
 POP BX
 POP DS
 OR AX,AX
 JZ @3FhOk
 STC
 JMP @3FhEnd
@3FhOk:
 MOV AX,BX
 CLC
@3FhEnd:
 POP DX
 POP ES
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 40h: Write File                                 }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@40h:
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 XOR AX,AX
 PUSH AX
 MOV SI,SP
 PUSH BX
 PUSH DS
 PUSH DX
 PUSH CX
 PUSH SS
 PUSH SI
 PUSH CS
 POP DS
 CALL WriteInt21
 POP BX
 POP DS
 OR AX,AX
 JZ @40hOk
 STC
 JMP @40hEnd
@40hOk:
 MOV AX,BX
 CLC
@40hEnd:
 POP DX
 POP ES
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 41h: Delete File                                }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@41h:
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 PUSH DS
 PUSH DX
 PUSH CS
 POP DS
 CALL DOS41h_DeleteFile
 POP DS
 OR AX,AX
 JZ @41hOk
 STC
 JMP @41hEnd
@41hOk:
 CLC
@41hEnd:
 POP DX
 POP ES
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 42h: Seek File                                  }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@42h:
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DS
 PUSH BX
 PUSH CX
 PUSH DX
 XOR AH,AH
 PUSH AX
 PUSH CS
 POP DS
 CALL SeekInt21
 POP DS
 CMP AX,0FFFFh
 JNE @42hOk
 CMP DX,0FFFFh
 JNE @42hOk
 PUSH DS
 PUSH CS
 POP DS
 CALL GetExtendedErrorCode
 POP DS
 STC
 JMP @42hEnd
@42hOk:
 CLC
@42hEnd:
 POP ES
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 43h: Get/Set File Attributes                   }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@43h:
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 XOR AH,AH
 PUSH AX
 PUSH DS
 PUSH DX
 PUSH AX
 PUSH CX
 PUSH CS
 POP DS
 CALL DOS43h_GetSetFileAttributes
 POP BX
 POP DS
 CMP AX,0FFFFh
 JNE @43hOk
 PUSH DS
 PUSH CS
 POP DS
 CALL GetExtendedErrorCode
 POP DS
 STC
 JMP @43hEnd
@43hOk:
 OR BL,BL
 JNZ @43hSet
 POP DX
 POP ES
 POP DI
 POP SI
 ADD SP,2
 POP BX
 MOV CX,AX
 CLC
 JMP @Xit
@43hSet:
 CLC
@43hEnd:
 POP DX
 POP ES
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 44h: IOCTL (Input/Output Control)              }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@44h:
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DS
 XOR AH,AH
 MOV CX,AX
 XOR AX,AX
 PUSH AX
 MOV SI,SP
 PUSH CX
 PUSH BX
 PUSH SS
 PUSH SI
 PUSH CS
 POP DS
 CALL IoctlInt21
 POP BX
 POP DS
 OR AX,AX
 JZ @44hOk
 CALL @44hErr
 STC
 JMP @44hEnd
@44hErr:
 PUSH DS
 PUSH CS
 POP DS
 CALL GetExtendedErrorCode
 POP DS
 DB 0C3h
@44hOk:
 MOV AX,BX
 OR CL,CL
 JZ @44hDx
 CMP CL,9
 JNE @44hNoDx
@44hDx:
 MOV DX,BX
@44hNoDx:
 CLC
@44hEnd:
 POP ES
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 45h: Duplicate Handle                           }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@45h:
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 PUSH BX
 PUSH CS
 POP DS
 CALL DOS45h_DuplicateHandle
 POP DS
 CMP AX,0FFFFh
 JNE @45hOk
 PUSH DS
 PUSH CS
 POP DS
 CALL GetExtendedErrorCode
 POP DS
 STC
 JMP @45hEnd
@45hOk:
 CLC
@45hEnd:
 POP DX
 POP ES
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 46h: Force Duplicate Handle                    }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@46h:
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 PUSH BX
 PUSH CX
 PUSH CS
 POP DS
 CALL DOS46h_ForceDuplicateHandle
 POP DS
 OR AX,AX
 JZ @46hOk
 STC
 JMP @46hEnd
@46hOk:
 CLC
@46hEnd:
 POP DX
 POP ES
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 47h: Get Current Directory                     }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@47h:
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 XOR DH,DH
 PUSH DX
 PUSH DS
 PUSH SI
 PUSH CS
 POP DS
 CALL DOS47h_GetCurrentDirectory
 POP DS
 OR AX,AX
 JZ @47hOk
 STC
 JMP @47hEnd
@47hOk:
 CLC
@47hEnd:
 POP DX
 POP ES
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 48h: Allocate Memory Block                     }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@48h:
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 PUSH BX
 PUSH CS
 POP DS
 CALL AllocInt21
 POP DS
 OR AX,AX
 JNZ @48hOk
 PUSH DS
 PUSH CS
 POP DS
 CALL LargestFreeBlock
 POP DS
 MOV BX,AX
 MOV AX,8
 STC
 JMP @48hEnd
@48hOk:
 CLC
@48hEnd:
 POP DX
 POP ES
 POP DI
 POP SI
 POP CX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 49h: Free Memory Block                         }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@49h:
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 PUSH ES
 PUSH CS
 POP DS
 CALL DOS49h_FreeMemory
 POP DS
 OR AX,AX
 JZ @49hOk
 STC
 JMP @49hEnd
@49hOk:
 CLC
@49hEnd:
 POP DX
 POP ES
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 4Ah: Modify Memory Block                       }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@4Ah:
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 PUSH ES
 PUSH BX
 PUSH CS
 POP DS
 CALL DOS4Ah_ModifyMemory
 POP DS
 OR AX,AX
 JZ @4AhOk
 STC
 JMP @4AhEnd
@4AhOk:
 CLC
@4AhEnd:
 POP DX
 POP ES
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 4Bh: EXEC - Load and Execute Program           }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@4Bh:
 PUSH BX                    { Sauvegarder les registres }
 PUSH CX
 PUSH SI
 PUSH DI

 { Paramètres: AL = type EXEC, DS:DX = nom fichier, ES:BX = bloc paramètres }
 { Convention Pascal : arguments de gauche à droite,
   pointeur = segment puis offset, }
 { l'appelée dépile ; DS = segment du noyau pendant l'appel }
 PUSH DS                    { DS de l'appelant, restauré après l'appel }
 XOR AH,AH
 PUSH AX                    { Mode (AL) }
 PUSH DS                    { Nom : segment }
 PUSH DX                    { Nom : offset }
 PUSH ES                    { Bloc : segment }
 PUSH BX                    { Bloc : offset }
 PUSH CS
 POP DS
 CALL ExecFromInt21
 POP DS

 { AX contient le résultat (0 si succès, code d'erreur sinon) }
 CMP AX,0                   { Vérifier si succès }
 JE @4BhSuccess             { Si succès }

 { Erreur }
 STC                        { Set Carry Flag }
 JMP @4BhEnd

@4BhSuccess:
 { Succès }
 CLC                        { Clear Carry Flag }

@4BhEnd:
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 4Ch: Terminate Program                         }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@4Ch:
 PUSH CX                    { Sauvegarder les registres }
 PUSH SI
 PUSH DI

 { Paramètres: AL = code de retour }
 XOR AH,AH
 PUSH AX                    { Code de retour (AL) }
 PUSH CS
 POP DS

 CALL DOS4Ch_TerminateProgram { Appeler fonction Pascal (ne revient pas) }

 { Cette fonction ne retourne jamais - elle termine le programme }
 { En cas d'erreur, continuer quand même }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 4Dh: Get Return Code                           }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@4Dh:
 PUSH CX                    { Sauvegarder les registres }
 PUSH SI
 PUSH DI

 CALL DOS4Dh_GetReturnCode  { Appeler fonction Pascal }
 { AX contient le code de retour (AH = raison, AL = code) }

 { Pas de modification du Carry Flag - cette fonction réussit toujours }
 CLC                        { Clear Carry Flag }

 POP DI
 POP SI
 POP CX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 4Eh: Find First File                           }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@4Eh:
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 PUSH DS
 PUSH DX
 PUSH CX
 PUSH CS
 POP DS
 CALL FindFirstInt21
 POP DS
 OR AX,AX
 JZ @4EhOk
 STC
 JMP @4EhEnd
@4EhOk:
 CLC
@4EhEnd:
 POP DX
 POP ES
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 4Fh: Find Next File                            }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@4Fh:
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 PUSH CS
 POP DS
 CALL FindNextInt21
 POP DS
 OR AX,AX
 JZ @4FhOk
 STC
 JMP @4FhEnd
@4FhOk:
 CLC
@4FhEnd:
 POP DX
 POP ES
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 50h: Set PSP Address                           }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@50h:
 PUSH BX
 PUSH CX
 PUSH DX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DS
 PUSH BX
 PUSH CS
 POP DS
 CALL DOS50h_SetPSPAddress
 POP DS
 POP ES
 POP DI
 POP SI
 POP DX
 POP CX
 POP BX
 OR AX,AX
 JZ @50hOk
 STC
 JMP @Xit
@50hOk:
 CLC
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 51h: Get PSP Address                           }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@51h:
 PUSH CX                    { Sauvegarder les registres }

 CALL DOS51h_GetPSPAddress  { Appeler fonction Pascal }
 { AX contient l'adresse du PSP }

 MOV BX,AX                  { Retourner PSP dans BX }
 CLC                        { Clear Carry Flag - toujours succès }

 POP CX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 52h: Get List of Lists                         }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@52h:
 PUSH CX                    { Sauvegarder les registres }

 CALL DOS52h_GetListOfLists { Appeler fonction Pascal }
 { AX:DX contient le pointeur vers Liste des Listes }

 MOV BX,AX                  { BX = offset }
 MOV ES,DX                  { ES = segment }
 CLC                        { Clear Carry Flag - toujours succès }

 POP CX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 53h: Translate BPB to DPB                      }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@53h:
 CLC
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 54h: Get Verify Flag                           }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@54h:
 PUSH BX
 PUSH CX
 PUSH DX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DS
 PUSH CS
 POP DS
 CALL DOS54h_GetVerifyFlag
 POP DS
 POP ES
 POP DI
 POP SI
 POP DX
 POP CX
 POP BX
 CLC
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 55h: Create Child PSP                         }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@55h:
 PUSH BX
 PUSH CX
 PUSH DX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DS
 PUSH DX
 PUSH CS
 POP DS
 CALL DOS55h_CreateChildPSP
 POP DS
 POP ES
 POP DI
 POP SI
 POP DX
 POP CX
 POP BX
 OR AX,AX
 JZ @55hOk
 STC
 JMP @Xit
@55hOk:
 CLC
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 56h: Rename/Move File                         }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@56h:
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 PUSH DS
 PUSH DX
 PUSH ES
 PUSH DI
 PUSH CS
 POP DS
 CALL DOS56h_RenameFile
 POP DS
 OR AX,AX
 JZ @56hOk
 STC
 JMP @56hEnd
@56hOk:
 CLC
@56hEnd:
 POP DX
 POP ES
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 57h: Get/Set File Date and Time                }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@57h:
 PUSH BX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH CX
 PUSH DX
 PUSH DS
 XOR AH,AH
 PUSH AX
 PUSH BX
 PUSH AX
 PUSH DX
 PUSH CX
 PUSH CS
 POP DS
 CALL DateTimeInt21
 POP SI
 POP DS
 CMP AX,0FFFFh
 JNE @57Ok
 CMP DX,0FFFFh
 JNE @57Ok
 PUSH DS
 PUSH CS
 POP DS
 CALL GetExtendedErrorCode
 POP DS
 STC
 JMP @57End
@57Ok:
 OR SI,SI
 JNZ @57Set
 ADD SP,4
 POP ES
 POP DI
 POP SI
 POP BX
 MOV CX,AX
 CLC
 JMP @Xit
@57Set:
 CLC
@57End:
 POP DX
 POP CX
 POP ES
 POP DI
 POP SI
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 58h: Get/Set Memory Allocation Strategy       }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@58h:
 PUSH BX
 PUSH CX
 PUSH DX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DS
 XOR AH,AH
 PUSH AX
 PUSH BX
 PUSH CS
 POP DS
 CALL DOS58h_GetSetMemoryStrategy
 POP DS
 POP ES
 POP DI
 POP SI
 POP DX
 POP CX
 POP BX
 CMP AX,0FFFFh
 JE @58hErr
 CLC
 JMP @Xit
@58hErr:
 MOV AX,1
 STC
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 59h: Get Extended Error Information           }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@59h:
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DS
 PUSH CS
 POP DS
 CALL DOS59h_GetExtendedError
 MOV BX,DX
 MOV CH,Data.DataMOS.ErrorLocus
 XOR CL,CL
 POP DS
 POP ES
 POP DI
 POP SI
 CLC
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 5Ah: Create Temporary File                     }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@5Ah:
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 PUSH DS
 PUSH DX
 PUSH CX
 PUSH CS
 POP DS
 CALL TempInt21
 POP DS
 CMP AX,0FFFFh
 JNE @5AhOk
 PUSH DS
 PUSH CS
 POP DS
 CALL GetExtendedErrorCode
 POP DS
 STC
 JMP @5AhEnd
@5AhOk:
 CLC
@5AhEnd:
 POP DX
 POP ES
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 5Bh: Create New File                           }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@5Bh:
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 PUSH DS
 PUSH DX
 PUSH CX
 PUSH CS
 POP DS
 CALL CreateNewInt21
 POP DS
 CMP AX,0FFFFh
 JNE @5BhOk
 PUSH DS
 PUSH CS
 POP DS
 CALL GetExtendedErrorCode
 POP DS
 STC
 JMP @5BhEnd
@5BhOk:
 CLC
@5BhEnd:
 POP DX
 POP ES
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
 { Interruption 21h - Fonction 5Ch: Lock/Unlock File Region                   }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   -}
@5Ch:
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 PUSH BX
 XOR AH,AH
 PUSH AX
 PUSH CX
 PUSH DX
 PUSH SI
 PUSH DI
 PUSH CS
 POP DS
 CALL LockInt21
 POP DS
 OR AX,AX
 JZ @5ChOk
 STC
 JMP @5ChEnd
@5ChOk:
 CLC
@5ChEnd:
 POP DX
 POP ES
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

@F2h:
@F3h:
 PUSH BX
 PUSH CX
 PUSH SI
 PUSH DI
 PUSH ES
 PUSH DX
 PUSH DS
 MOV SI,AX
 XOR AH,AH
 MOV DI,AX
 MOV AX,SI
 MOV AL,AH
 AND AX,0001h
 PUSH AX
 PUSH DI
 PUSH CX
 XOR AX,AX
 PUSH AX
 PUSH DX
 PUSH DS
 PUSH BX
 PUSH CS
 POP DS
 CALL AbsDiskInt21
 POP DS
 OR AX,AX
 JZ @F2hOk
 STC
 JMP @F2hEnd
@F2hOk:
 CLC
@F2hEnd:
 POP DX
 POP ES
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

@68h:
 CLC
 JMP @Xit

@70h:
 PUSH DS
 PUSH CS
 POP DS
 CALL InitPartition
 POP DS
 CLC
 JMP @Xit

@Xit:
 DEC Data.DataMOS.InDos
 { IRET restaure les FLAGS de l'appelant : recopier CF (resultat) dans les FLAGS
   empiles }
 PUSH BP
 MOV BP,SP
 JC @XitCarry
 AND WORD PTR [BP+6],0FFFEh
 JMP @XitDone
@XitCarry:
 OR WORD PTR [BP+6],1
@XitDone:
 POP BP
END;

{ Point d'entree de INT 21h : le noyau s'execute sur une pile privee
  (9000:0000..KSP), hors de l'arene
  memoire,
    pour ne pas dependre de la pile (parfois minuscule) du programme appelant.
      Cadre utilisateur
  sauvegarde : CX BX AX BP ES DS IP CS FLAGS (de bas en haut). Les registres de
    sortie sont rendus
  dans ces emplacements avant de revenir sur la pile utilisateur. Un appel
    imbrique (deja sur la pile
  privee) va directement au coeur. }
Procedure Intr21h;Assembler;ASM
 PUSH DS
 PUSH ES
 PUSH BP
 PUSH AX
 PUSH BX
 PUSH CX
 MOV AX,CS
 MOV DS,AX
 MOV AX,SS
 CMP AX,9000h
 JNE @Switch
 POP CX
 POP BX
 POP AX
 POP BP
 POP ES
 POP DS
 JMP Intr21hCore
@Switch:
 MOV AX,SP
 MOV BX,SS
 MOV CX,9000h
 CLI
 MOV SS,CX
 MOV SP,WORD PTR [Data + FxBase + 124]
 STI
 PUSH BX
 PUSH AX
 MOV DS,BX
 MOV BX,AX
 MOV AX,[BX+10]
 PUSH AX
 MOV AX,[BX+4]
 MOV CX,[BX]
 MOV BP,[BX+6]
 MOV ES,[BX+8]
 MOV BX,[BX+2]
 POP DS
 PUSHF
 CALL Intr21hCore
 PUSH BP
 MOV BP,SP
 PUSH ES
 PUSH BX
 MOV BX,[BP+4]
 MOV ES,BX
 MOV BX,[BP+2]
 MOV ES:[BX+4],AX
 MOV AX,[BP-4]
 MOV ES:[BX+2],AX
 MOV ES:[BX],CX
 MOV AX,[BP-2]
 MOV ES:[BX+8],AX
 MOV AX,[BP]
 MOV ES:[BX+6],AX
 MOV ES:[BX+10],DS
 JC @Cf1
 MOV AX,ES:[BX+16]
 AND AX,0FFFEh
 JMP @Cf2
@Cf1:
 MOV AX,ES:[BX+16]
 OR AX,1
@Cf2:
 MOV ES:[BX+16],AX
 CLI
 MOV AX,ES
 MOV SS,AX
 MOV SP,BX
 POP CX
 POP BX
 POP AX
 POP BP
 POP ES
 POP DS
 IRET
END;

{ INT 20h (terminaison de programme,
  par exemple RET depuis un .COM) : AX=4C00h puis INT 21h }
Procedure Intr20hEntry;Assembler;ASM
 MOV AX,4C00h
 JMP Intr21h
END;

{ INT 25h / INT 26h : lecture / ecriture absolue de secteurs. Passent par INT
  21h (fonctions internes
  F2h/F3h) pour profiter de la pile privee ;
    retour FAR en laissant les FLAGS de l'INT sur la pile de
  l'appelant (comportement DOS), CF = erreur. }
Procedure Intr25h;Assembler;ASM
 MOV AH,6Eh
 INT 21h
 DB 0CBh
END;

Procedure Intr26h;Assembler;ASM
 MOV AH,6Fh
 INT 21h
 DB 0CBh
END;

Procedure Intr28h;Assembler;ASM
 { Vide - Executer a temps perdu! }
END;

Procedure Intr2Ah;Assembler;ASM
 XOR AX,AX
END;

Procedure Intr2Fh;Assembler;ASM
 XOR BX,BX
 XOR AX,AX
END;

Procedure Intr33h;Assembler;ASM
 XOR AX,AX
END;

{ Procédure interne pour remplir une zone mémoire avec une valeur }
Procedure FillChar(Var Dest;Size:Word;Value:Byte);Assembler;ASM
 PUSH ES
  PUSH DI
   PUSH CX
    PUSH AX
     LES DI,Dest       { ES:DI pointe sur destination }
     MOV CX,Size       { CX = nombre d'octets }
     MOV AL,Value      { AL = valeur à remplir }
     CLD               { Direction forward }
     REP STOSB         { Remplir ES:[DI] avec AL, CX fois }
    POP AX
   POP CX
  POP DI
 POP ES
END;

{ Procédure interne pour copier des données en mémoire }
Procedure Move(Var Source,Dest;Size:Word);Assembler;ASM
 PUSH ES
  PUSH DS
   PUSH SI
    PUSH DI
     PUSH CX
      LDS SI,Source    { DS:SI pointe sur source }
      LES DI,Dest      { ES:DI pointe sur destination }
      MOV CX,Size      { CX = nombre d'octets à copier }
      CLD              { Direction forward }
      REP MOVSB        { Copier DS:[SI] vers ES:[DI], CX fois }
     POP CX
    POP DI
   POP SI
  POP DS
 POP ES
END;

{ Procédure interne pour appeler une interruption logicielle }
Procedure Intr(IntNo: Byte; var Regs: Registers);Assembler;ASM
{$IFNDEF Win32}
	PUSH	DS
{$IFDEF ProtectedMode}
{$IFDEF Windows}
 PUSH CS
 CALL	AllocCSToDSAlias
{$ELSE}
 MOV AX,CS
 ADD AX,SelectorInc
{$ENDIF}
	MOV	DS,AX
	CLI
	PUSH	WORD PTR DS:@@Int
	PUSH	DS
	MOV	AL,IntNo
	MOV	BYTE PTR DS:@@Int+1,AL
{$ELSE}
	PUSH	WORD PTR CS:@@Int
	MOV	AL,IntNo
	MOV	BYTE PTR CS:@@Int+1,AL
{$ENDIF}
	PUSH	BP			{ Preserve our BP }
	LDS	SI,Regs
	CLD
	LODSW
	PUSH	AX			{ Regs.AX }
	LODSW
	XCHG	AX,BX
	LODSW
	XCHG	AX,CX
	LODSW
	XCHG	AX,DX
	LODSW
	XCHG	AX,BP
	LODSW
	PUSH	AX			{ Regs.SI }
	LODSW
	XCHG	AX,DI
	LODSW
	PUSH	AX			{ Regs.DS }
	LODSW
{$IFDEF DPMI}
        VERR    AX
	JNZ	@@1
	MOV	ES,AX
@@1:	POP	AX			{ Regs.DS }
	VERR	AX
	JNZ	@@2
	MOV	DS,AX
@@2:
{$ELSE}
	MOV	ES,AX
	POP	DS			{ Regs.DS }
{$ENDIF}
	POP	SI			{ Regs.SI }
	POP	AX			{ Regs.AX }
@@Int:	INT	0
	STI
	PUSHF				{ New Regs.Flags, .ES, .DI, .BP }
	PUSH	ES
	PUSH	DI
	PUSH	BP
	MOV	BP,SP
	MOV	BP,[BP+8]		{ Recover our BP }
	LES	DI,Regs
	CLD
	STOSW
	XCHG	AX,BX
	STOSW
	XCHG	AX,CX
	STOSW
	XCHG	AX,DX
	STOSW
	POP	AX			{ New Regs.BP }
	STOSW
	XCHG	AX,SI
	STOSW
	POP	AX			{ New Regs.DI }
	STOSW
	MOV	AX,DS
	STOSW
	POP	AX			{ New Regs.ES }
	STOSW
	POP	AX			{ New Regs.Flags }
	STOSW
	POP	AX			{ Throw away our pushed BP }
{$IFDEF ProtectedMode}
	POP	DS
	POP	WORD PTR DS:@@Int
{$ELSE}
	POP	WORD PTR CS:@@Int
{$ENDIF}
{$IFDEF Windows}
	MOV	AX,DS
	POP	DS
	PUSH	AX
	CALL	FreeSelector
{$ELSE}
	POP	DS
{$ENDIF}
{$ENDIF}
END;

{==============================================================================}
{ FONCTIONS D'ACCÈS AUX DONNÉES DANS LE CODE SEGMENT                          }
{==============================================================================}

{ Fonctions pour accéder aux variables CurrentDrive et CurrentDir dans Data }
Function GetCurrentDrive: Byte;Assembler;
ASM
 MOV AL,BYTE PTR [Data + 2]  { CurrentDrive dans DataMOS.CurrDisk }
END;

Procedure SetCurrentDrive(Drive: Byte);Assembler;
ASM
 MOV AL,Drive
 MOV BYTE PTR [Data + 2],AL  { Stocker CurrentDrive dans DataMOS.CurrDisk }
END;

Function GetCurrentDirCluster(Index: Byte): Word;Assembler;
ASM
 MOV AL,Index
 CMP AL,NDrv
 JB @Ok
 XOR AL,AL
@Ok:
 MOV AH,CDSize
 MUL AH
 MOV BX,AX
 MOV AX,WORD PTR [Data + BX + CDBase + 1] { Cluster dans CurrentDir }
END;

Function GetCurrentDirPath(Index: Byte): String;
Var
 Path: String;
 I, Len, Cc: Byte;
 Base: Word;
Begin
 If Index>=NDrv Then Index:=0;
 Base := Index * CDSize + CDBase + 3;
 ASM
  MOV BX,Base
  MOV AL,BYTE PTR [Data + BX]
  MOV Len,AL
 END;
 If Len > 63 Then Len := 63;
 Path[0] := Chr(Len);
 For I := 1 To Len Do Begin
  ASM
   MOV BX,Base
   MOV AL,I
   XOR AH,AH
   ADD BX,AX
   MOV AL,BYTE PTR [Data + BX]
   MOV Cc,AL
  END;
  Path[I] := Chr(Cc);
 End;
 GetCurrentDirPath := Path;
End;

Procedure SetCurrentDirDrive(Index, Drive: Byte);Assembler;
ASM
 MOV AL,Index
 CMP AL,NDrv
 JB @Ok
 XOR AL,AL
@Ok:
 MOV AH,CDSize
 MUL AH
 MOV BX,AX
 MOV AL,Drive
 MOV BYTE PTR [Data + BX + CDBase],AL
END;

Procedure SetCurrentDirCluster(Index: Byte; Cluster: Word);Assembler;
ASM
 MOV AL,Index
 CMP AL,NDrv
 JB @Ok
 XOR AL,AL
@Ok:
 MOV AH,CDSize
 MUL AH
 MOV BX,AX
 MOV AX,Cluster
 MOV WORD PTR [Data + BX + CDBase + 1],AX
END;

Procedure SetCurrentDirPath(Index: Byte; Path: String);
Var
 I, Len, Cc: Byte;
 Base: Word;
Begin
 Len := Length(Path);
 If Len > 63 Then Len := 63;
 If Index>=NDrv Then Index:=0;
 Base := Index * CDSize + CDBase + 3;
 ASM
  MOV BX,Base
  MOV AL,Len
  MOV BYTE PTR [Data + BX],AL
 END;
 For I := 1 To Len Do Begin
  Cc := Ord(Path[I]);
  ASM
   MOV BX,Base
   MOV AL,I
   XOR AH,AH
   ADD BX,AX
   MOV AL,Cc
   MOV BYTE PTR [Data + BX],AL
  END;
 End;
End;

{==============================================================================}
{ FONCTIONS D'ACCÈS À LA FILETABLE DANS LE CODE SEGMENT                       }
{==============================================================================}

{ Structure FileTable : 7 + 26*131 + 20*17 = 3747 + 340 = 4087
  Offset de FileTable dans Data = 114 + 26*131 = 3520 }

{ Fonctions pour accéder aux variables FileTable dans Data }
Function GetFileTableInUse(Index: Byte): Boolean;Assembler;
ASM
 MOV AL,Index
 MOV AH,17                   { Taille d'une entrée FileTable }
 MUL AH
 ADD AX,FTBase+0                 { Ajouter offset de base FileTable dans DataMOS
   }
 MOV BX,AX
 MOV AL,BYTE PTR [Data + BX] { Lire InUse dans FileTable }
 CMP AL,0
 JE @False                   { Si égal à 0, retourner False }
 MOV AL,1                    { Sinon retourner True }
 JMP @End
@False:
 MOV AL,0
@End:
END;

Procedure SetFileTableInUse(Index: Byte; InUse: Boolean);Assembler;
ASM
 MOV AL,Index
 MOV AH,17
 MUL AH
 ADD AX,FTBase+0
 MOV BX,AX
 MOV AL,InUse
 MOV BYTE PTR [Data + BX],AL
END;

Function GetFileTableDrive(Index: Byte): Byte;Assembler;
ASM
 MOV AL,Index
 MOV AH,17
 MUL AH
 ADD AX,FTBase+1                 { Offset + 1 pour Drive dans FileTable }
 MOV BX,AX
 MOV AL,BYTE PTR [Data + BX]
END;

Procedure SetFileTableDrive(Index: Byte; Drive: Byte);Assembler;
ASM
 MOV AL,Index
 MOV AH,17
 MUL AH
 ADD AX,FTBase+1
 MOV BX,AX
 MOV AL,Drive
 MOV BYTE PTR [Data + BX],AL
END;

Function GetFileTableFirstCluster(Index: Byte): Word;Assembler;
ASM
 MOV AL,Index
 MOV AH,17
 MUL AH
 ADD AX,FTBase+2                 { Offset + 2 pour FirstCluster dans FileTable }
 MOV BX,AX
 MOV AX,WORD PTR [Data + BX]
END;

Procedure SetFileTableFirstCluster(Index: Byte; FirstCluster: Word);Assembler;
ASM
 MOV AL,Index
 MOV AH,17
 MUL AH
 ADD AX,FTBase+2
 MOV BX,AX
 MOV AX,FirstCluster
 MOV WORD PTR [Data + BX],AX
END;

Function GetFileTableFileSize(Index: Byte): LongInt;Assembler;
ASM
 MOV AL,Index
 MOV AH,17
 MUL AH
 ADD AX,FTBase+4                 { Offset + 4 pour FileSize dans FileTable }
 MOV BX,AX
 MOV AX,WORD PTR [Data + BX]     { Partie basse }
 MOV DX,WORD PTR [Data + BX + 2] { Partie haute }
END;

Procedure SetFileTableFileSize(Index: Byte; FileSize: LongInt);Assembler;
ASM
 MOV AL,Index
 MOV AH,17
 MUL AH
 ADD AX,FTBase+4
 MOV BX,AX
 MOV AX,WORD PTR [FileSize]      { Partie basse }
 MOV WORD PTR [Data + BX],AX
 MOV AX,WORD PTR [FileSize + 2]  { Partie haute }
 MOV WORD PTR [Data + BX + 2],AX
END;

Function GetFileTableCurrentPos(Index: Byte): LongInt;Assembler;
ASM
 MOV AL,Index
 MOV AH,17
 MUL AH
 ADD AX,FTBase+8                 { Offset + 8 pour CurrentPos }
 MOV BX,AX
 MOV AX,WORD PTR [Data + BX]
 MOV DX,WORD PTR [Data + BX + 2]
END;

Procedure SetFileTableCurrentPos(Index: Byte; CurrentPos: LongInt);Assembler;
ASM
 MOV AL,Index
 MOV AH,17
 MUL AH
 ADD AX,FTBase+8
 MOV BX,AX
 MOV AX,WORD PTR [CurrentPos]
 MOV WORD PTR [Data + BX],AX
 MOV AX,WORD PTR [CurrentPos + 2]
 MOV WORD PTR [Data + BX + 2],AX
END;

Function GetFileTableAttributes(Index: Byte): Byte;Assembler;
ASM
 MOV AL,Index
 MOV AH,17
 MUL AH
 ADD AX,FTBase+12                 { Offset + 12 pour Attributes }
 MOV BX,AX
 MOV AL,BYTE PTR [Data + BX]
END;

Procedure SetFileTableAttributes(Index: Byte; Attributes: Byte);Assembler;
ASM
 MOV AL,Index
 MOV AH,17
 MUL AH
 ADD AX,FTBase+12
 MOV BX,AX
 MOV AL,Attributes
 MOV BYTE PTR [Data + BX],AL
END;

Function GetFileTableCurrentCluster(Index: Byte): Word;Assembler;
ASM
 MOV AL,Index
 MOV AH,17
 MUL AH
 ADD AX,FTBase+13                 { Offset + 13 pour CurrentCluster }
 MOV BX,AX
 MOV AX,WORD PTR [Data + BX]
END;

Procedure SetFileTableCurrentCluster(Index: Byte; CurrentCluster: Word);
  Assembler;
ASM
 MOV AL,Index
 MOV AH,17
 MUL AH
 ADD AX,FTBase+13
 MOV BX,AX
 MOV AX,CurrentCluster
 MOV WORD PTR [Data + BX],AX
END;

Function GetFileTableClusterOffset(Index: Byte): Word;Assembler;
ASM
 MOV AL,Index
 MOV AH,17
 MUL AH
 ADD AX,FTBase+15                 { Offset + 15 pour ClusterOffset }
 MOV BX,AX
 MOV AX,WORD PTR [Data + BX]
END;

Procedure SetFileTableClusterOffset(Index: Byte; ClusterOffset: Word);Assembler;
ASM
 MOV AL,Index
 MOV AH,17
 MUL AH
 ADD AX,FTBase+15
 MOV BX,AX
 MOV AX,ClusterOffset
 MOV WORD PTR [Data + BX],AX
END;

{ Fonctions d'accès aux nouvelles variables DataMOS }
Function GetLastReturnCode: Word;Assembler;
ASM
 MOV AX,WORD PTR [Data.DataMOS.LastReturnCode]
END;

Procedure SetLastReturnCode(ReturnCode: Word);Assembler;
ASM
 MOV AX,ReturnCode
 MOV WORD PTR [Data.DataMOS.LastReturnCode],AX
END;

{ Procédure pour initialiser la table des verrous }
Procedure InitializeFileLocks;Assembler;
Const
 FileLockEntrySize=SizeOf(FileLockEntry);
ASM
 { Initialiser tous les verrous comme non utilisés }
 MOV CX,20                  { 20 entrées }
 MOV DI,OFFSET Data.DataMOS
 ADD DI,OFFSET DataMOS.FileLocks
@InitLoop:
 MOV BYTE PTR [DI].FileLockEntry.InUse,0
 ADD DI,FileLockEntrySize
 LOOP @InitLoop
END;

Function GetCurrentPSP: Word;Assembler;
ASM
 MOV AX,WORD PTR [Data.DataMOS.CurrentPSP]
END;

Procedure SetCurrentPSP(PSP: Word);Assembler;
ASM
 MOV AX,PSP
 MOV WORD PTR [Data.DataMOS.CurrentPSP],AX
END;

{ Fonctions d'accès au flag de vérification }
Function GetVerifyFlag: Byte;Assembler;
ASM
 MOV AL,BYTE PTR [Data.DataMOS.VerifyFlag]
END;

Procedure SetVerifyFlag(Flag: Byte);Assembler;
ASM
 MOV AL,Flag
 MOV BYTE PTR [Data.DataMOS.VerifyFlag],AL
END;

{ Lire une entrée complète de la FileTable }
Function GetFileTableEntry(Handle:Word;Var Entry:FileTableEntry):Boolean;
Begin
 GetFileTableEntry:=False;

 { Vérifier la validité du handle }
 If Handle >= 20 Then Exit;

 { Vérifier si l'entrée est utilisée }
 If Not GetFileTableInUse(Handle) Then Exit;

 { Remplir la structure }
 Entry.InUse:=GetFileTableInUse(Handle);
 Entry.Drive:=GetFileTableDrive(Handle);
 Entry.FirstCluster:=GetFileTableFirstCluster(Handle);
 Entry.FileSize:=GetFileTableFileSize(Handle);
 Entry.CurrentPos:=GetFileTableCurrentPos(Handle);
 Entry.Attributes:=GetFileTableAttributes(Handle);
 Entry.CurrentCluster:=GetFileTableCurrentCluster(Handle);
 Entry.ClusterOffset:=GetFileTableClusterOffset(Handle);

 GetFileTableEntry:=True;
End;

{ Écrire une entrée complète dans la FileTable }
Function SetFileTableEntry(Handle:Word;Entry:FileTableEntry):Boolean;
Begin
 SetFileTableEntry:=False;

 { Vérifier la validité du handle }
 If Handle >= 20 Then Exit;

 { Mettre à jour tous les champs }
 SetFileTableInUse(Handle, Entry.InUse);
 SetFileTableDrive(Handle, Entry.Drive);
 SetFileTableFirstCluster(Handle, Entry.FirstCluster);
 SetFileTableFileSize(Handle, Entry.FileSize);
 SetFileTableCurrentPos(Handle, Entry.CurrentPos);
 SetFileTableAttributes(Handle, Entry.Attributes);
 SetFileTableCurrentCluster(Handle, Entry.CurrentCluster);
 SetFileTableClusterOffset(Handle, Entry.ClusterOffset);

 SetFileTableEntry:=True;
End;

{==============================================================================}
{ FONCTIONS DE MANIPULATION DE CHAÎNES INTERNES                               }
{==============================================================================}

{ Fonction Length - retourne la longueur d'une chaîne Pascal }
Function Length(S:String):Byte;
Begin
 Length:=Ord(S[0]);
End;

{ Fonction Copy - extrait une sous-chaîne }
Function Copy(S:String;Index,Count:Byte):String;
Var
 I,Len:Byte;
 Result:String;
Begin
 Result:='';
 Len:=Ord(S[0]);

 { Validation des paramètres }
 If (Index=0)or(Index>Len)or(Count=0) Then Begin
  Copy:=Result;
  Exit;
 End;

 { Ajuster Count si nécessaire }
 If Index+Count-1>Len Then Count:=Len-Index+1;
 If Count>255 Then Count:=255;

 { Copier les caractères }
 Result[0]:=Chr(Count);
 For I:=1 to Count Do Begin
  Result[I]:=S[Index+I-1];
 End;

 Copy:=Result;
End;

{ Procédure Delete - supprime une portion de chaîne }
Procedure Delete(Var S:String;Index,Count:Byte);
Var
 I,Len,NewLen:Byte;
Begin
 Len:=Ord(S[0]);

 { Validation des paramètres }
 If (Index=0)or(Index>Len)or(Count=0) Then Exit;

 { Ajuster Count si nécessaire }
 If Index+Count-1>Len Then Count:=Len-Index+1;

 { Calculer nouvelle longueur }
 NewLen:=Len-Count;

 { Décaler les caractères restants }
 For I:=Index to NewLen Do Begin
  S[I]:=S[I+Count];
 End;

 { Mettre à jour la longueur }
 S[0]:=Chr(NewLen);
End;


 { Fonction helper pour valider et changer le code pays }
Function Handle38hSetCountryInfo(NewCountryCode:Word):Word;Begin
 { Valider que c'est un code pays supporté }
 Case NewCountryCode of
  1, 2, 33, 34: Begin
    { Code pays valide - le sauvegarder }
    ASM
     MOV AX,NewCountryCode
     MOV Data.DataMOS.CurrentCountry,AX
    END;
    Handle38hSetCountryInfo := 0; { Succès }
  End;
  Else Begin
    Handle38hSetCountryInfo := 2; { Erreur : code pays invalide }
  End;
 End;
End;


{ =============================================== }
{ Fonctions de support pour opérations disque  }
{ =============================================== }

Function GetDriveParameterTable(Drive:Byte;Var DPT:DriveParameterTable):Boolean;
{ Récupère les paramètres du lecteur spécifié }
Var
  Regs:Registers;
Begin
  GetDriveParameterTable:=False;

  { Initialiser structure par défaut }
  FillChar(DPT,SizeOf(DPT),0);

  { Pour les disquettes (0=A:, 1=B:) }
  If Drive < 2 Then Begin
    { Paramètres standard disquette 1.44MB }
    DPT.SectorsPerTrack:=18;
    DPT.NumberOfHeads:=2;
    DPT.NumberOfCylinders:=80;
    DPT.BytesPerSector:=512;
    DPT.SectorsPerCluster:=1;
    GetDriveParameterTable:=True;
  End
  Else Begin
    { Pour disques durs, essayer INT 13h AH=08h }
    Regs.AH:=$08;
    Regs.DL:=Drive+$80; { 80h=C:, 81h=D:, etc. }
    Intr($13,Regs);

    If (Regs.Flags And 1)=0 Then Begin { CF=0, succès }
      DPT.NumberOfHeads:=(Regs.DH And $FF)+1;
      DPT.SectorsPerTrack:=Regs.CL And $3F;
      DPT.NumberOfCylinders:=((Regs.CL And $C0) Shl 2) Or Regs.CH;
      DPT.BytesPerSector:=512; { Standard }
      DPT.SectorsPerCluster:=4; { Valeur par défaut }
      GetDriveParameterTable:=True;
    End;
  End;
End;

Function ValidateDriveNumber(DriveNumber:Byte):Boolean;
{ Vérifie si le numéro de lecteur est valide }
Begin
  ValidateDriveNumber:=(DriveNumber>=0) And (DriveNumber<=NDrv-1); { A-Z }
End;

Procedure ConvertLBAtoCHS(LBA:LongInt;Var Cylinder,Head,Sector:Word;
  DPT:DriveParameterTable);
{ Convertit une adresse LBA en adresse CHS }
Var
  SectorsPerCylinder:Word;
Begin
  SectorsPerCylinder:=DPT.SectorsPerTrack * DPT.NumberOfHeads;

  Cylinder:=LBA Div SectorsPerCylinder;
  Head:=(LBA Mod SectorsPerCylinder) Div DPT.SectorsPerTrack;
  Sector:=(LBA Mod DPT.SectorsPerTrack)+1; { BIOS sectors start at 1 }
End;

Function BIOSReadSector(DriveNumber:Byte;Cylinder,Head,Sector:Word;
                        NumSectors:Byte;Buffer:Pointer):Boolean;
{ Lecture de secteurs via BIOS INT 13h }
Var
  Regs:Registers;
Begin
  BIOSReadSector:=False;

  Regs.AH:=$02; { Read sectors }
  Regs.AL:=NumSectors;
  Regs.CH:=Lo(Cylinder);
  Regs.CL:=Hi(Cylinder) Shl 6 Or Sector;
  Regs.DH:=Head;

  If DriveNumber<2 Then
    Regs.DL:=DriveNumber { Disquette: 0=A:, 1=B: }
  Else
    Regs.DL:=DriveNumber+$80; { Disque dur: 80h=C:, 81h=D: }

  Regs.ES:=Seg(Buffer^);
  Regs.BX:=Ofs(Buffer^);

  Intr($13,Regs);

  BIOSReadSector:=(Regs.Flags And 1)=0; { CF=0 si succès }
End;

Function BIOSWriteSector(DriveNumber:Byte;Cylinder,Head,Sector:Word;
                         NumSectors:Byte;Buffer:Pointer):Boolean;
{ Écriture de secteurs via BIOS INT 13h }
Var
  Regs:Registers;
Begin
  BIOSWriteSector:=False;

  Regs.AH:=$03; { Write sectors }
  Regs.AL:=NumSectors;
  Regs.CH:=Lo(Cylinder);
  Regs.CL:=Hi(Cylinder) Shl 6 Or Sector;
  Regs.DH:=Head;

  If DriveNumber<2 Then
    Regs.DL:=DriveNumber
  Else
    Regs.DL:=DriveNumber+$80;

  Regs.ES:=Seg(Buffer^);
  Regs.BX:=Ofs(Buffer^);

  Intr($13,Regs);

  BIOSWriteSector:=(Regs.Flags And 1)=0;
End;

Function ReadSectorLBA(Drive:Byte;LBA:LongInt;Buffer:Pointer):Boolean;
{ Lecture d'un secteur par adresse LBA }
Var
  DPT:DriveParameterTable;
  Cylinder,Head,Sector:Word;
Begin
  ReadSectorLBA:=False;

  If Not ValidateDriveNumber(Drive) Then Exit;
  If Not GetDriveParameterTable(Drive,DPT) Then Exit;

  ConvertLBAtoCHS(LBA,Cylinder,Head,Sector,DPT);
  ReadSectorLBA:=BIOSReadSector(Drive,Cylinder,Head,Sector,1,Buffer);
End;

Function WriteSectorLBA(Drive:Byte;LBA:LongInt;Buffer:Pointer):Boolean;
{ Écriture d'un secteur par adresse LBA }
Var
  DPT:DriveParameterTable;
  Cylinder,Head,Sector:Word;
Begin
  WriteSectorLBA:=False;

  If Not ValidateDriveNumber(Drive) Then Exit;
  If Not GetDriveParameterTable(Drive,DPT) Then Exit;

  ConvertLBAtoCHS(LBA,Cylinder,Head,Sector,DPT);
  WriteSectorLBA:=BIOSWriteSector(Drive,Cylinder,Head,Sector,1,Buffer);
End;

{==============================================================================}
{ PROCÉDURES DE SUPPORT POUR LA GESTION FAT ET RÉPERTOIRES - FONCTION 39h     }
{==============================================================================}

{ Lire le secteur de démarrage d'un lecteur }
Function ReadBootSector(Drive:Byte;Var BootSec:BootSectorRec):Boolean;
Begin
 ReadBootSector:=ReadSector(Drive,0,@BootSec);
End;

{ Lire un secteur depuis un lecteur }
{ Une operation BIOS INT 13h sur un secteur (Op = 02h lecture, 03h ecriture) }
Function BiosDisk(Op:Byte;BiosDrv:Byte;Cyl,Head,Sec:Word;
  Buffer:Pointer):Boolean;Assembler;
ASM
 MOV AX,Cyl
 MOV CH,AL
 MOV BL,AH
 MOV CL,6
 SHL BL,CL
 MOV CL,BYTE PTR Sec
 OR CL,BL
 MOV DH,BYTE PTR Head
 MOV DL,BiosDrv
 MOV AH,Op
 MOV AL,1
 LES BX,Buffer
 INT 13h
 MOV AL,1
 JNC @Ok
 XOR AL,AL
@Ok:
END;

{ Geometrie du disque (secteurs par piste, nombre de tetes) ; defaut 18 x 2 }
Procedure GetGeometry(BiosDrv:Byte;Var SPT,Heads:Word);Assembler;
ASM
 PUSH ES
 PUSH DI
 MOV DL,BiosDrv
 MOV AH,08h
 INT 13h
 JC @Def
 MOV AL,CL
 AND AX,003Fh
 JZ @Def
 MOV BX,AX
 MOV AL,DH
 XOR AH,AH
 INC AX
 MOV CX,AX
 JMP @Store
@Def:
 MOV BX,18
 MOV CX,2
@Store:
 LES DI,SPT
 MOV ES:[DI],BX
 LES DI,Heads
 MOV ES:[DI],CX
 POP DI
 POP ES
END;

Procedure ResetDisk(BiosDrv:Byte);Assembler;
ASM
 MOV DL,BiosDrv
 XOR AH,AH
 INT 13h
END;

{ Lecture/ecriture d'un secteur logique : lecteur DOS (0=A:, 1=B:, 2=C:...) }
Function GetPartOfs:LongInt;Assembler;
ASM
 MOV AX,WORD PTR [Data + FxBase + 100]
 MOV DX,WORD PTR [Data + FxBase + 102]
END;

Procedure SetPartOfs(V:LongInt);Assembler;
ASM
 MOV AX,WORD PTR [V]
 MOV WORD PTR [Data + FxBase + 100],AX
 MOV AX,WORD PTR [V + 2]
 MOV WORD PTR [Data + FxBase + 102],AX
END;

Function DiskTransfer(Op:Byte;Drive:Byte;Sector:LongInt;Buffer:Pointer):Boolean;
Var
 BiosDrv: Byte;
 SPT,Heads,Tries,Head,Sec: Word;
 Cyl,Tmp: LongInt;
Begin
 DiskTransfer:=False;
 If Drive<2 Then BiosDrv:=Drive Else Begin
  BiosDrv:=$80+(Drive-2);
  Sector:=Sector+GetPartOfs;
 End;
 GetGeometry(BiosDrv,SPT,Heads);
 Sec:=Word(Sector Mod SPT)+1;
 Tmp:=Sector Div SPT;
 Head:=Word(Tmp Mod Heads);
 Cyl:=Tmp Div Heads;
 For Tries:=1 To 3 Do Begin
  If BiosDisk(Op,BiosDrv,Word(Cyl),Head,Sec,Buffer) Then Begin
   DiskTransfer:=True;
   Exit;
  End;
  ResetDisk(BiosDrv);
 End;
End;

Function ReadSector(Drive:Byte;Sector:LongInt;Buffer:Pointer):Boolean;
Begin
 ReadSector:=DiskTransfer($02,Drive,Sector,Buffer);
End;

{ Écrire un secteur sur un lecteur }
Function WriteSector(Drive:Byte;Sector:LongInt;Buffer:Pointer):Boolean;
Begin
 WriteSector:=DiskTransfer($03,Drive,Sector,Buffer);
End;

{ Trouver un cluster libre dans la FAT }
Function FindFreeCluster(Drive:Byte;BootSec:BootSectorRec):Word;
Var
 FATSector:LongInt;
 FATBuffer:Array[0..511] of Byte;
 I,J:Word;
 TotalClusters:Word;
 FATEntry:Word;
Begin
 FindFreeCluster:=0;  { 0 = pas de cluster libre trouvé }

 { Calculer le nombre total de clusters }
 If BootSec.TotalSectors=0 Then
  TotalClusters:=(BootSec.TotalSectorsLarge-BootSec.ReservedSectors-
                  BootSec.NumberOfFATs*BootSec.SectorsPerFAT-
                  (BootSec.RootDirEntries*32+511)div 512)
                 div BootSec.SectorsPerCluster
 Else
  TotalClusters:=(BootSec.TotalSectors-BootSec.ReservedSectors-
                  BootSec.NumberOfFATs*BootSec.SectorsPerFAT-
                  (BootSec.RootDirEntries*32+511)div 512)
                 div BootSec.SectorsPerCluster;

 { Déterminer si FAT12 ou FAT16 }
 If TotalClusters<4085 Then Begin
  { FAT12 }
  For I:=2 to TotalClusters+1 Do Begin
   FATSector:=BootSec.ReservedSectors+(I*3 div 2)div 512;
   If ReadSector(Drive,FATSector,@FATBuffer) Then Begin
    J:=(I*3 div 2)mod 512;
    If I and 1=0 Then
     FATEntry:=FATBuffer[J]or((FATBuffer[J+1]and $0F)shl 8)
    Else
     FATEntry:=((FATBuffer[J]and $F0)shr 4)or(FATBuffer[J+1]shl 4);
    If FATEntry=0 Then Begin
     FindFreeCluster:=I;
     Exit;
    End;
   End;
  End;
 End Else Begin
  { FAT16 }
  For I:=2 to TotalClusters+1 Do Begin
   FATSector:=BootSec.ReservedSectors+(I*2)div 512;
   If ReadSector(Drive,FATSector,@FATBuffer) Then Begin
    J:=((I*2)mod 512);
    FATEntry:=FATBuffer[J]or(FATBuffer[J+1]shl 8);
    If FATEntry=0 Then Begin
     FindFreeCluster:=I;
     Exit;
    End;
   End;
  End;
 End;
End;

{ Allouer un cluster dans la FAT (le marquer comme dernier cluster) }
Function AllocateCluster(Drive:Byte;BootSec:BootSectorRec;Cluster:Word):Boolean;
Var
 FATSector:LongInt;
 FATBuffer:Array[0..511] of Byte;
 J:Word;
 TotalClusters:Word;
 FATCopy:Byte;
Begin
 AllocateCluster:=False;

 { Calculer le nombre total de clusters }
 If BootSec.TotalSectors=0 Then
  TotalClusters:=(BootSec.TotalSectorsLarge-BootSec.ReservedSectors-
                  BootSec.NumberOfFATs*BootSec.SectorsPerFAT-
                  (BootSec.RootDirEntries*32+511)div 512)
                 div BootSec.SectorsPerCluster
 Else
  TotalClusters:=(BootSec.TotalSectors-BootSec.ReservedSectors-
                  BootSec.NumberOfFATs*BootSec.SectorsPerFAT-
                  (BootSec.RootDirEntries*32+511)div 512)
                 div BootSec.SectorsPerCluster;

 { Mettre à jour toutes les copies de la FAT }
 For FATCopy:=0 to BootSec.NumberOfFATs-1 Do Begin
  If TotalClusters<4085 Then Begin
   { FAT12 }
   FATSector:=BootSec.ReservedSectors+FATCopy*BootSec.SectorsPerFAT+(Cluster*3
     div 2)div 512;
   If ReadSector(Drive,FATSector,@FATBuffer) Then Begin
    J:=(Cluster*3 div 2)mod 512;
    If Cluster and 1=0 Then Begin
     FATBuffer[J]:=$FF;
     FATBuffer[J+1]:=(FATBuffer[J+1]and $F0)or $0F;
    End Else Begin
     FATBuffer[J]:=(FATBuffer[J]and $0F)or $F0;
     FATBuffer[J+1]:=$FF;
    End;
    If Not WriteSector(Drive,FATSector,@FATBuffer) Then Exit;
   End Else Exit;
  End Else Begin
   { FAT16 }
   FATSector:=BootSec.ReservedSectors+FATCopy*BootSec.SectorsPerFAT+(Cluster*
     2)div 512;
   If ReadSector(Drive,FATSector,@FATBuffer) Then Begin
    J:=(Cluster*2)mod 512;
    FATBuffer[J]:=$FF;
    FATBuffer[J+1]:=$FF;
    If Not WriteSector(Drive,FATSector,@FATBuffer) Then Exit;
   End Else Exit;
  End;
 End;

 AllocateCluster:=True;
End;

{ Analyser un chemin et extraire le lecteur et le nom du répertoire }
Function ParsePath(Path:String;Var Drive:Byte;Var DirName:String):Boolean;
Var
 I:Byte;
Begin
 ParsePath:=False;
 Drive:=0;
 DirName:='';

 If Length(Path)=0 Then Exit;

 { Vérifier le lecteur }
 If (Length(Path)>=2)and(Path[2]=':') Then Begin
  If (Path[1]>='A')and(Path[1]<='Z') Then
   Drive:=Ord(Path[1])-Ord('A')+1
  Else If (Path[1]>='a')and(Path[1]<='z') Then
   Drive:=Ord(Path[1])-Ord('a')+1
  Else Exit;
  Delete(Path,1,2);
 End Else Begin
  { Utiliser le lecteur courant depuis Data }
  Drive:=GetCurrentDrive;
 End;

 { Enlever les backslashes de début }
 While (Length(Path)>0)and(Path[1]='\')Do Delete(Path,1,1);

 { Extraire le nom du dernier répertoire }
 I:=Length(Path);
 While (I>0)and(Path[I]<>'\')Do Dec(I);
 If I>0 Then Begin
  DirName:=Copy(Path,I+1,255);
  Delete(Path,I,255);
 End Else Begin
  DirName:=Path;
  Path:='';
 End;

 { Valider le nom de répertoire (format 8.3 sans extension) }
 If (Length(DirName)>8)or(Length(DirName)=0) Then Exit;
 For I:=1 to Length(DirName) Do Begin
  If Not ((DirName[I]>='A')and(DirName[I]<='Z'))and
     Not ((DirName[I]>='a')and(DirName[I]<='z'))and
     Not ((DirName[I]>='0')and(DirName[I]<='9'))and
     Not (DirName[I]='_') Then Exit;
 End;

 ParsePath:=True;
End;

{ Trouver le cluster parent d'un répertoire }
Function FindParentDirectory(Drive:Byte;BootSec:BootSectorRec;Path:String;
  Var ParentCluster:Word):Boolean;
Begin
 { Pour cette implémentation simplifiée, on suppose créer dans la racine }
 ParentCluster:=0;  { 0 = répertoire racine }
 FindParentDirectory:=True;
End;

{ Créer une entrée de répertoire }
Function CreateDirEntry(Drive:Byte;BootSec:BootSectorRec;ParentCluster:Word;
  DirName:String):Boolean;
Var
 DirSector:LongInt;
 DirBuffer:Array[0..511] of Byte;
 Entry:DirectoryEntry Absolute DirBuffer;
 I,J:Word;
 FreeCluster:Word;
 DOSDate,DOSTime:Word;
Begin
 CreateDirEntry:=False;

 { Obtenir la date/heure DOS }
 ASM
  MOV AH,2Ah
  INT 21h
  MOV AX,CX
  SUB AX,1980
  { Décaler AX de 9 bits - Compatible 8088 }
 {$IFOPT G+}
  SHL AX,9
 {$ELSE}
  SHL AX,1
  SHL AX,1
  SHL AX,1
  SHL AX,1
  SHL AX,1
  SHL AX,1
  SHL AX,1
  SHL AX,1
  SHL AX,1
 {$ENDIF}
  MOV CL,DH
  XOR CH,CH
  { Décaler CX de 5 bits - Compatible 8088 }
 {$IFOPT G+}
  SHL CX,5
 {$ELSE}
  SHL CX,1
  SHL CX,1
  SHL CX,1
  SHL CX,1
  SHL CX,1
 {$ENDIF}
  OR AX,CX
  OR AL,DL
  MOV DOSDate,AX

  MOV AH,2Ch
  INT 21h
  MOV AL,CH
  XOR AH,AH
  { Décaler AX de 11 bits - Compatible 8088 }
 {$IFOPT G+}
  SHL AX,11
 {$ELSE}
  SHL AX,1
  SHL AX,1
  SHL AX,1
  SHL AX,1
  SHL AX,1
  SHL AX,1
  SHL AX,1
  SHL AX,1
  SHL AX,1
  SHL AX,1
  SHL AX,1
 {$ENDIF}
  MOV BL,CL
  XOR BH,BH
  { Décaler BX de 5 bits - Compatible 8088 }
 {$IFOPT G+}
  SHL BX,5
 {$ELSE}
  SHL BX,1
  SHL BX,1
  SHL BX,1
  SHL BX,1
  SHL BX,1
 {$ENDIF}
  OR AX,BX
  MOV BL,DH
  SHR BL,1
  OR AL,BL
  MOV DOSTime,AX
 END;

 { Trouver un cluster libre pour le nouveau répertoire }
 FreeCluster:=FindFreeCluster(Drive,BootSec);
 If FreeCluster=0 Then Exit;

 { Allouer le cluster }
 If Not AllocateCluster(Drive,BootSec,FreeCluster) Then Exit;

 { Calculer secteur du répertoire racine }
 DirSector:=BootSec.ReservedSectors+BootSec.NumberOfFATs*BootSec.SectorsPerFAT;

 { Chercher une entrée libre dans le répertoire parent }
 For I:=0 to (BootSec.RootDirEntries*32)div 512-1 Do Begin
  If ReadSector(Drive,DirSector+I,@DirBuffer) Then Begin
   For J:=0 to 15 Do Begin  { 16 entrées par secteur }
    Move(DirBuffer[J*32],Entry,32);
    If (Entry.FileName[0]=#0)or(Entry.FileName[0]=#$E5) Then Begin
     { Entrée libre trouvée }
     FillChar(Entry,32,0);

     { Remplir le nom (format 8.3, majuscules, espaces) }
     FillChar(Entry.FileName,11,Byte(' '));
     For J:=1 to Length(DirName) Do Begin
      If J<=8 Then Begin
       If (DirName[J]>='a')and(DirName[J]<='z') Then
        Entry.FileName[J-1]:=Chr(Ord(DirName[J])-32)
       Else
        Entry.FileName[J-1]:=DirName[J];
      End;
     End;

     Entry.Attributes:=$10;        { Attribut répertoire }
     Entry.LastWriteTime:=DOSTime;
     Entry.LastWriteDate:=DOSDate;
     Entry.FirstClusterLow:=FreeCluster;
     Entry.FirstClusterHigh:=0;     { FAT16 n'utilise que la partie basse }
     Entry.FileSize:=0;

     { Écrire l'entrée }
     Move(Entry,DirBuffer[J*32],32);
     If WriteSector(Drive,DirSector+I,@DirBuffer) Then Begin
      { Initialiser le nouveau répertoire avec . et .. }
      FillChar(DirBuffer,512,0);

      { Entrée "." }
      Move(Entry,DirBuffer[0],32);
      FillChar(DirBuffer[0],11,Byte(' '));
      DirBuffer[0]:=Byte('.');

      { Entrée ".." }
      Move(Entry,DirBuffer[32],32);
      FillChar(DirBuffer[32],11,Byte(' '));
      DirBuffer[32]:=Byte('.');
      DirBuffer[33]:=Byte('.');
      FillChar(DirBuffer[32+26],2,0); { Cluster parent = racine }

      { Écrire le secteur du nouveau répertoire }
      DirSector:=BootSec.ReservedSectors+BootSec.NumberOfFATs*
        BootSec.SectorsPerFAT+
                 (BootSec.RootDirEntries*32+511)div 512+
                 (FreeCluster-2)*BootSec.SectorsPerCluster;

      If WriteSector(Drive,DirSector,@DirBuffer) Then Begin
       CreateDirEntry:=True;
       Exit;
      End;
     End;
    End;
   End;
  End;
 End;
End;

{==============================================================================}
{ FONCTIONS POUR SUPPRIMER UN RÉPERTOIRE (Fonction 3Ah)                      }
{==============================================================================}

Function GetClusterSector(Drive:Byte;BootSec:BootSectorRec;
  Cluster:Word):LongInt;
{ Calcule le secteur de départ d'un cluster donné }
Begin
 If Cluster = 0 Then
  { Répertoire racine }
  GetClusterSector:=BootSec.ReservedSectors+
                    (BootSec.NumberOfFATs*BootSec.SectorsPerFAT)
 Else
  { Cluster de données }
  GetClusterSector:=BootSec.ReservedSectors+
                    (BootSec.NumberOfFATs*BootSec.SectorsPerFAT)+
                    (BootSec.RootDirEntries*32+511)div 512+
                    (Cluster-2)*BootSec.SectorsPerCluster;
End;

Function FindDirectoryEntry(Drive:Byte;BootSec:BootSectorRec;
                           ParentCluster:Word;DirName:String;
                           Var Entry:DirectoryEntry;
                           Var EntryOffset:Word):Boolean;
{ Cherche une entrée (fichier ou répertoire) par son nom 8.3 (8 caractères de
  nom
  + 3 d'extension, complétés par des espaces) dans le répertoire parent : racine
  (ParentCluster=0) ou chaîne de clusters. }
Var
 DirBuffer:Array[0..511] of Byte;
 Name11:Array[0..10] of Char;
 DirSector:LongInt;
 SectorsToRead,I,J,K,N,Cluster,Dot:Word;
 EntryPtr:^DirectoryEntry;
 Match:Boolean;
 C:Char;
Begin
 FindDirectoryEntry:=False;
 EntryOffset:=0;
 For K:=0 To 10 Do Name11[K]:=' ';
 N:=Length(DirName);
 Dot:=0;
 For K:=1 To N Do If (DirName[K]='.') And (Dot=0) Then Dot:=K;
 If Dot>0 Then Begin
  { NOM.EXT : nom sur 8 caractères, extension sur 3 }
  For K:=1 To Dot-1 Do Begin
   If K<=8 Then Name11[K-1]:=DirName[K];
  End;
  For K:=1 To 3 Do Begin
   If (Dot+K<=N) And (DirName[Dot+K]<>' ') Then Name11[7+K]:=DirName[Dot+K];
  End;
 End
 Else Begin
  If N>11 Then N:=11;
  For K:=1 To N Do Name11[K-1]:=DirName[K];
 End;
 For K:=0 To 10 Do Begin
  C:=Name11[K];
  If (C>='a') And (C<='z') Then Name11[K]:=Chr(Ord(C)-32);
 End;
 Cluster:=ParentCluster;
 Repeat
  DirSector:=GetClusterSector(Drive,BootSec,Cluster);
  If Cluster=0 Then SectorsToRead:=(BootSec.RootDirEntries*32+511) Div 512
  Else SectorsToRead:=BootSec.SectorsPerCluster;
  For I:=0 To SectorsToRead-1 Do Begin
   If ReadSector(Drive,DirSector+I,@DirBuffer) Then Begin
    For J:=0 To 15 Do Begin
     EntryPtr:=@DirBuffer[J*32];
     If EntryPtr^.FileName[0]=#0 Then Exit;
     If (EntryPtr^.FileName[0]<>#$E5) And ((EntryPtr^.Attributes And $08)=0)
       Then Begin
      Match:=True;
      For K:=0 To 7 Do If EntryPtr^.FileName[K]<>Name11[K] Then Match:=False;
      For K:=0 To 2 Do If EntryPtr^.Extension[K]<>Name11[8+K] Then Match:=False;
      If Match Then Begin
       Entry:=EntryPtr^;
       EntryOffset:=(I*16+J)*32;
       FindDirectoryEntry:=True;
       Exit;
      End;
     End;
    End;
   End;
  End;
  If Cluster=0 Then Exit;
  Cluster:=GetNextCluster(Drive,BootSec,Cluster);
 Until (Cluster<2) Or (Cluster>=$FF8);
End;

Function IsDirectoryEmpty(Drive:Byte;BootSec:BootSectorRec;
  DirCluster:Word):Boolean;
{ Vérifie si un répertoire est vide (contient seulement . et ..) }
Var
 DirBuffer:Array[0..511] of Byte;
 DirSector:LongInt;
 I,J:Word;
 EntryPtr:^DirectoryEntry;
 ValidEntries:Word;
Begin
 IsDirectoryEmpty:=False;
 ValidEntries:=0;

 DirSector:=GetClusterSector(Drive,BootSec,DirCluster);

 { Parcourir tous les secteurs du cluster }
 For I:=0 To BootSec.SectorsPerCluster-1 Do Begin
  If ReadSector(Drive,DirSector+I,@DirBuffer) Then Begin
   For J:=0 To 15 Do Begin { 16 entrées par secteur }
    EntryPtr:=@DirBuffer[J*32];

    { Compter les entrées valides }
    If (EntryPtr^.FileName[0]<>#0)and(EntryPtr^.FileName[0]<>#$E5) Then Begin
     Inc(ValidEntries);

     { Plus de 2 entrées = répertoire non vide }
     If ValidEntries > 2 Then Exit;
    End;
   End;
  End;
 End;

 { Répertoire vide si seulement . et .. }
 IsDirectoryEmpty:=(ValidEntries <= 2);
End;

Function FreeFATChain(Drive:Byte;BootSec:BootSectorRec;
  StartCluster:Word):Boolean;
{ Libère une chaîne de clusters dans la FAT }
Var
 FATBuffer:Array[0..511] of Byte;
 FATSector:LongInt;
 CurrentCluster,NextCluster:Word;
 FATOffset:Word;
 FATEntry:^Word;
Begin
 FreeFATChain:=False;
 CurrentCluster:=StartCluster;

 While (CurrentCluster >= 2)and(CurrentCluster < $FFF0) Do Begin
  { Calculer secteur FAT et offset }
  FATOffset:=CurrentCluster * 2; { FAT16: 2 octets par entrée }
  FATSector:=BootSec.ReservedSectors + (FATOffset div 512);

  { Lire le secteur FAT }
  If Not ReadSector(Drive,FATSector,@FATBuffer) Then Exit;

  { Lire la prochaine entrée de cluster }
  FATEntry:=@FATBuffer[FATOffset mod 512];
  NextCluster:=FATEntry^;

  { Marquer le cluster comme libre }
  FATEntry^:=0;

  { Écrire le secteur FAT modifié }
  If Not WriteSector(Drive,FATSector,@FATBuffer) Then Exit;

  { Écrire aussi la copie de la FAT si elle existe }
  If BootSec.NumberOfFATs > 1 Then Begin
   FATSector:=FATSector + BootSec.SectorsPerFAT;
   If Not WriteSector(Drive,FATSector,@FATBuffer) Then Exit;
  End;

  { Passer au cluster suivant }
  CurrentCluster:=NextCluster;
 End;

 FreeFATChain:=True;
End;

Function DeleteDirEntry(Drive:Byte;BootSec:BootSectorRec;ParentCluster:Word;
  EntryOffset:Word):Boolean;
{ Supprime une entrée de répertoire }
Var
 DirBuffer:Array[0..511] of Byte;
 DirSector:LongInt;
 SectorOffset:Word;
 EntryInSector:Word;
Begin
 DeleteDirEntry:=False;

 { Calculer secteur et position dans le secteur }
 DirSector:=GetClusterSector(Drive,BootSec,ParentCluster);
 SectorOffset:=EntryOffset div 512;
 EntryInSector:=EntryOffset mod 512;

 { Lire le secteur contenant l'entrée }
 If ReadSector(Drive,DirSector+SectorOffset,@DirBuffer) Then Begin
  { Marquer l'entrée comme supprimée }
  DirBuffer[EntryInSector]:=$E5; { Premier caractère = E5h }

  { Écrire le secteur modifié }
  If WriteSector(Drive,DirSector+SectorOffset,@DirBuffer) Then
   DeleteDirEntry:=True;
 End;
End;

{ ===== Couche FAT en ecriture (FAT12/FAT16) =====
  Volume compact (pas de copie du secteur de boot de 512 octets sur la pile),
    entrees de repertoire
  manipulees directement dans le tampon d'un secteur (decalages : nom 0-10,
    attribut 11, date 24,
  premier cluster 26,
    taille 28). L'emplacement de l'entree de repertoire de chaque handle est
  memorise dans Data.DataMOS.FxLoc (FxBase) pour mettre a jour la taille a la
    fermeture. }
Function FxGetSec(H:Byte):LongInt;Assembler;
ASM
 MOV AL,H
 MOV AH,5
 MUL AH
 ADD AX,FxBase
 MOV BX,AX
 MOV AX,WORD PTR [Data + BX]
 MOV DX,WORD PTR [Data + BX + 2]
END;

Function FxGetIdx(H:Byte):Byte;Assembler;
ASM
 MOV AL,H
 MOV AH,5
 MUL AH
 ADD AX,FxBase+4
 MOV BX,AX
 MOV AL,BYTE PTR [Data + BX]
END;

Procedure FxSetLoc(H:Byte;Sec:LongInt;Idx:Byte);Assembler;
ASM
 MOV AL,H
 MOV AH,5
 MUL AH
 ADD AX,FxBase
 MOV BX,AX
 MOV AX,WORD PTR [Sec]
 MOV WORD PTR [Data + BX],AX
 MOV AX,WORD PTR [Sec + 2]
 MOV WORD PTR [Data + BX + 2],AX
 MOV AL,Idx
 MOV BYTE PTR [Data + BX + 4],AL
END;

Function FxVol(Drive:Byte;Var V:TFxVol):Boolean;
Var
 Buf:TFxSec;
 Tot,Root:LongInt;
Begin
 FxVol:=False;
 If Not ReadSector(Drive,0,@Buf) Then Exit;
 V.Drive:=Drive;
 V.SPC:=Buf[13];
 V.Res:=Word(Buf[14])+Word(Buf[15])*256;
 V.NFat:=Buf[16];
 V.RootEnt:=Word(Buf[17])+Word(Buf[18])*256;
 V.SPF:=Word(Buf[22])+Word(Buf[23])*256;
 Tot:=Word(Buf[19])+Word(Buf[20])*256;
 If Tot=0 Then
  Tot:=Word(Buf[32])+Word(Buf[33])*256+(LongInt(Buf[34])+LongInt(Buf[35])*256)*
    65536;
 If V.SPC=0 Then Exit;
 Root:=(LongInt(V.RootEnt)*32+511) Div 512;
 V.FirstData:=LongInt(V.Res)+LongInt(V.NFat)*V.SPF+Root;
 V.Clusters:=Word((Tot-V.FirstData) Div V.SPC);
 V.Is16:=V.Clusters>=4085;
 FxVol:=True;
End;

Function FxGet(Var V:TFxVol;C:Word):Word;
Var
 B:Array[0..1023] of Byte;
 Off,S:LongInt;
 O,R:Word;
Begin
 FxGet:=$FFFF;
 If V.Is16 Then Off:=LongInt(C)*2 Else Off:=LongInt(C)*3 Div 2;
 S:=V.Res+Off Div 512;
 O:=Word(Off Mod 512);
 If Not ReadSector(V.Drive,S,@B) Then Exit;
 If (Not V.Is16) And (O=511) Then
  If Not ReadSector(V.Drive,S+1,@B[512]) Then Exit;
 R:=Word(B[O])+Word(B[O+1])*256;
 If V.Is16 Then Begin
  If R>=$FFF8 Then R:=$FFFF;
 End Else Begin
  If (C And 1)=0 Then R:=R And $0FFF Else R:=R Shr 4;
  If R>=$0FF8 Then R:=$FFFF;
 End;
 FxGet:=R;
End;

Procedure FxSet(Var V:TFxVol;C:Word;Val:Word);
Var
 B:Array[0..1023] of Byte;
 Off,S:LongInt;
 O:Word;
 K:Byte;
 Two:Boolean;
Begin
 If V.Is16 Then Off:=LongInt(C)*2 Else Off:=LongInt(C)*3 Div 2;
 O:=Word(Off Mod 512);
 Two:=(Not V.Is16) And (O=511);
 For K:=0 To V.NFat-1 Do Begin
  S:=LongInt(V.Res)+LongInt(K)*V.SPF+Off Div 512;
  If ReadSector(V.Drive,S,@B) Then Begin
   If Two Then ReadSector(V.Drive,S+1,@B[512]);
   If V.Is16 Then Begin
    B[O]:=Val And $FF;
    B[O+1]:=Val Shr 8;
   End Else If (C And 1)=0 Then Begin
    B[O]:=Val And $FF;
    B[O+1]:=(B[O+1] And $F0) Or ((Val Shr 8) And $0F);
   End Else Begin
    B[O]:=(B[O] And $0F) Or ((Val And $0F) Shl 4);
    B[O+1]:=(Val Shr 4) And $FF;
   End;
   WriteSector(V.Drive,S,@B);
   If Two Then WriteSector(V.Drive,S+1,@B[512]);
  End;
 End;
End;

Function FxAlloc(Var V:TFxVol;Prev:Word):Word;
{ Premier cluster libre a partir de Prev+1 (puis 2) ;
  marque fin de chaine et le relie a Prev }
Var
 B:Array[0..1023] of Byte;
 C,Start,K,O,R:Word;
 Off,CS,S:LongInt;
Begin
 FxAlloc:=0;
 CS:=-1;
 Start:=2;
 If Prev>=2 Then Start:=Prev+1;
 For K:=0 To V.Clusters-1 Do Begin
  C:=Start+K;
  If C>V.Clusters+1 Then C:=C-V.Clusters;
  If V.Is16 Then Off:=LongInt(C)*2 Else Off:=LongInt(C)*3 Div 2;
  S:=V.Res+Off Div 512;
  If S<>CS Then Begin
   If Not ReadSector(V.Drive,S,@B) Then Exit;
   ReadSector(V.Drive,S+1,@B[512]);
   CS:=S;
  End;
  O:=Word(Off Mod 512);
  R:=Word(B[O])+Word(B[O+1])*256;
  If V.Is16 Then Begin
   If R=0 Then Begin R:=1 End Else R:=2;
  End Else Begin
   If (C And 1)=0 Then R:=R And $0FFF Else R:=R Shr 4;
   If R=0 Then R:=1 Else R:=2;
  End;
  If R=1 Then Begin
   FxSet(V,C,$FFFF);
   If Prev>=2 Then FxSet(V,Prev,C);
   FxAlloc:=C;
   Exit;
  End;
 End;
End;

Procedure FxFreeChain(Var V:TFxVol;C:Word);
Var Nx:Word;
Begin
 While (C>=2) And (C<>$FFFF) Do Begin
  Nx:=FxGet(V,C);
  FxSet(V,C,0);
  C:=Nx;
 End;
End;

{ Secteur N du repertoire Dir (0 = racine) }
Function FxDirSec(Var V:TFxVol;Dir,N:Word;Var S:LongInt):Boolean;
Var C,K:Word;
Begin
 FxDirSec:=False;
 If Dir=0 Then Begin
  If LongInt(N)>=(LongInt(V.RootEnt)*32) Div 512 Then Exit;
  S:=LongInt(V.Res)+LongInt(V.NFat)*V.SPF+N;
  FxDirSec:=True;
  Exit;
 End;
 C:=Dir;
 K:=N Div V.SPC;
 While K>0 Do Begin
  C:=FxGet(V,C);
  If C=$FFFF Then Exit;
  Dec(K);
 End;
 S:=V.FirstData+LongInt(C-2)*V.SPC+N Mod V.SPC;
 FxDirSec:=True;
End;

{ Nom 8.3 -> 11 caracteres (majuscules, complete par des espaces) }
Procedure FxName11(Var S:String;Var N:String);
Var I,J:Byte;
Begin
 N:='           ';
 If (S='.') Or (S='..') Then Begin
  N[1]:='.';
  If S='..' Then N[2]:='.';
  Exit;
 End;
 I:=1;
 J:=1;
 While (I<=Length(S)) And (S[I]<>'.') Do Begin
  If J<=8 Then Begin N[J]:=UpCase(S[I]); Inc(J) End;
  Inc(I);
 End;
 If I<=Length(S) Then Begin
  Inc(I);
  J:=9;
  While I<=Length(S) Do Begin
   If J<=11 Then Begin N[J]:=UpCase(S[I]); Inc(J) End;
   Inc(I);
  End;
 End;
End;

{ Cherche Nm (11 caracteres) dans le repertoire Dir : emplacement (Sec,Idx) et
  contenu ; FSec/FIdx = premier emplacement libre }
Function FxScan(Var V:TFxVol;Dir:Word;Var Nm:String;Var Sec:LongInt;
  Var Idx:Byte;
                Var FSec:LongInt;Var FIdx:Integer;Var E:TFxEnt):Boolean;
Var
 Buf:TFxSec;
 N,P:Word;
 I,K:Byte;
 S:LongInt;
 Same:Boolean;
Begin
 FxScan:=False;
 FIdx:=-1;
 N:=0;
 While FxDirSec(V,Dir,N,S) Do Begin
  If Not ReadSector(V.Drive,S,@Buf) Then Exit;
  For I:=0 To 15 Do Begin
   P:=I*32;
   If Buf[P]=0 Then Begin
    If FIdx<0 Then Begin FSec:=S; FIdx:=I End;
    Exit;
   End;
   If Buf[P]=$E5 Then Begin
    If FIdx<0 Then Begin FSec:=S; FIdx:=I End;
   End Else Begin
    Same:=True;
    For K:=0 To 10 Do
     If Chr(Buf[P+K])<>Nm[K+1] Then Same:=False;
    If Same And ((Buf[P+11] And $08)=0) Then Begin
     Sec:=S;
     Idx:=I;
     E.Attr:=Buf[P+11];
     E.Cluster:=Word(Buf[P+26])+Word(Buf[P+27])*256;
     E.Size:=Word(Buf[P+28])+Word(Buf[P+29])*256+(LongInt(Buf[P+30])+
       LongInt(Buf[P+31])*256)*65536;
     FxScan:=True;
     Exit;
    End;
   End;
  End;
  Inc(N);
 End;
End;

{ Repertoire (hors racine) plein : ajoute un cluster vide a sa chaine ;
  S = premier secteur du nouveau cluster }
Function FxGrowDir(Var V:TFxVol;Dir:Word;Var S:LongInt):Boolean;
Var
 C,Nx,K:Word;
 B:TFxSec;
Begin
 FxGrowDir:=False;
 If Dir<2 Then Exit;
 C:=Dir;
 Repeat
  Nx:=FxGet(V,C);
  If (Nx>=2) And (Nx<>$FFFF) Then C:=Nx;
 Until (Nx<2) Or (Nx=$FFFF);
 Nx:=FxAlloc(V,C);
 If Nx=0 Then Exit;
 FillChar(B,512,0);
 S:=V.FirstData+LongInt(Nx-2)*V.SPC;
 For K:=0 To V.SPC-1 Do WriteSector(V.Drive,S+K,@B);
 FxGrowDir:=True;
End;

{ Ecrit une entree de repertoire dans le tampon a la position P }
{ Date et heure DOS courantes (horloge BIOS INT 1Ah/02h-04h) ;
  1980-01-01 00:00 si l'horloge est absente }
Procedure FxStamp(Var Buf:TFxSec;P:Word);
Var
 D,T:LongInt;
 Y,Mo,Dy,H,Mi,Sc,PD,PT:Word;
Begin
 D:=DateInt21;
 T:=TimeInt21;
 Y:=Word(D);
 Mo:=Hi(Word(D Shr 16));
 Dy:=Lo(Word(D Shr 16));
 H:=Hi(Word(T));
 Mi:=Lo(Word(T));
 Sc:=Hi(Word(T Shr 16));
 If (Y<1980) Or (Y>2107) Or (Mo<1) Or (Mo>12) Or (Dy<1) Or (Dy>31) Or (H>23) Or
   (Mi>59) Or (Sc>59) Then Begin
  PD:=$21;
  PT:=0;
 End Else Begin
  PD:=((Y-1980) Shl 9) Or (Mo Shl 5) Or Dy;
  PT:=(H Shl 11) Or (Mi Shl 5) Or (Sc Shr 1);
 End;
 Buf[P+22]:=PT And $FF;
 Buf[P+23]:=PT Shr 8;
 Buf[P+24]:=PD And $FF;
 Buf[P+25]:=PD Shr 8;
End;

Procedure FxPutEnt(Var Buf:TFxSec;P:Word;Var Nm:String;Attr:Byte;Cl:Word;
  Size:LongInt);
Var K:Byte;
Begin
 FillChar(Buf[P],32,0);
 For K:=0 To 10 Do Buf[P+K]:=Ord(Nm[K+1]);
 Buf[P+11]:=Attr;
 FxStamp(Buf,P);
 Buf[P+26]:=Cl And $FF;
 Buf[P+27]:=Cl Shr 8;
 Buf[P+28]:=Size And $FF;
 Buf[P+29]:=(Size Shr 8) And $FF;
 Buf[P+30]:=(Size Shr 16) And $FF;
 Buf[P+31]:=(Size Shr 24) And $FF;
End;

Function FxWalk(Var V:TFxVol;DirP:String;Start:Word;Var Dir:Word):Boolean;
Var
 I,J,Idx:Byte;
 Comp,Nm:String;
 Sec,FS:LongInt;
 FI:Integer;
 E:TFxEnt;
Begin
 FxWalk:=False;
 Dir:=Start;
 I:=1;
 While I<=Length(DirP) Do Begin
  If DirP[I]='\' Then Inc(I) Else Begin
   J:=I;
   While (J<=Length(DirP)) And (DirP[J]<>'\') Do Inc(J);
   Comp:=Copy(DirP,I,J-I);
   I:=J;
   FxName11(Comp,Nm);
   If Not FxScan(V,Dir,Nm,Sec,Idx,FS,FI,E) Then Exit;
   If (E.Attr And $10)=0 Then Exit;
   Dir:=E.Cluster;
  End;
 End;
 FxWalk:=True;
End;

{ Chemin ASCIIZ -> volume, repertoire parent (cluster) et nom 11 caracteres }
Function FxOpenPath(PathPtr:Pointer;Var V:TFxVol;Var Dir:Word;
  Var Nm:String):Boolean;
Var
 P:PChar;
 Path,DirP,FN:String;
 Dr,I,Q:Byte;
 Absolu:Boolean;
 Start:Word;
Begin
 FxOpenPath:=False;
 P:=PChar(PathPtr);
 Path:='';
 I:=0;
 While (P^<>#0) And (I<255) Do Begin
  Path:=Path+P^;
  Inc(P);
  Inc(I);
 End;
 If Not ParseFilePath(Path,Dr,DirP,FN) Then Exit;
 If Not FxVol(Dr,V) Then Exit;
 Q:=1;
 If (Length(Path)>=2) And (Path[2]=':') Then Q:=3;
 Absolu:=(Q<=Length(Path)) And (Path[Q]='\');
 If Absolu Then Start:=0 Else Start:=GetCurrentDirCluster(Dr);
 If Not FxWalk(V,DirP,Start,Dir) Then Exit;
 FxName11(FN,Nm);
 FxOpenPath:=True;
End;

{ Nom 8.3 (11 caracteres) invalide pour une creation : vide, joker,
  caracteres interdits }
Function InList(C:Byte;Const L:String):Boolean;
Var K:Byte;
Begin
 InList:=False;
 For K:=1 To Length(L) Do
  If Ord(L[K])=C Then InList:=True;
End;

Function FxBadName(Var Nm:String):Boolean;
Var K:Byte;
Begin
 FxBadName:=Nm[1]=' ';
 For K:=1 To 11 Do
  If (Nm[K]<' ') Or InList(Ord(Nm[K]),'*?"/\[]:|<>+=;,') Then FxBadName:=True;
End;

Function FxOpen(PathPtr:Pointer;Mode:Byte):Word;
Var
 V:TFxVol;
 Dir,H:Word;
 Nm:String;
 Sec,FS:LongInt;
 Idx:Byte;
 FI:Integer;
 E:TFxEnt;
Begin
 FxOpen:=$FFFF;
 If Not FxOpenPath(PathPtr,V,Dir,Nm) Then Begin SetStandardError(3); Exit End;
 If Not FxScan(V,Dir,Nm,Sec,Idx,FS,FI,E) Then Begin SetStandardError(2);
   Exit End;
 If (E.Attr And $10)<>0 Then Begin SetStandardError(5); Exit End;
 If ((Mode And 3)<>0) And ((E.Attr And $01)<>0) Then Begin SetStandardError(5);
   Exit End;
 If Not AllocateFileHandle(V.Drive,E.Cluster,E.Size,Mode And 3,
   H) Then Begin SetStandardError(4); Exit End;
 FxSetLoc(H,Sec,Idx);
 FxOpen:=H;
End;

Function FxCreate(PathPtr:Pointer;Attr:Byte;FailIfExists:Boolean):Word;
Var
 V:TFxVol;
 Dir,H:Word;
 Nm:String;
 Sec,FS:LongInt;
 Idx:Byte;
 FI:Integer;
 E:TFxEnt;
 Buf:TFxSec;
 P:Word;
Begin
 FxCreate:=$FFFF;
 If Not FxOpenPath(PathPtr,V,Dir,Nm) Then Begin SetStandardError(3); Exit End;
 If FxBadName(Nm) Then Begin SetStandardError(3); Exit End;
 If FxScan(V,Dir,Nm,Sec,Idx,FS,FI,E) Then Begin
  If FailIfExists Then Begin SetStandardError(80); Exit End;
  If (E.Attr And $11)<>0 Then Begin SetStandardError(5); Exit End;
  If E.Cluster>=2 Then FxFreeChain(V,E.Cluster);
  If Not ReadSector(V.Drive,Sec,@Buf) Then Begin SetStandardError(5); Exit End;
  P:=Idx*32;
  FxPutEnt(Buf,P,Nm,Attr Or $20,0,0);
 End Else Begin
  If FI<0 Then Begin
   If Not FxGrowDir(V,Dir,FS) Then Begin SetStandardError(5); Exit End;
   FI:=0;
  End;
  Sec:=FS;
  Idx:=FI;
  If Not ReadSector(V.Drive,Sec,@Buf) Then Begin SetStandardError(5); Exit End;
  P:=Idx*32;
  FxPutEnt(Buf,P,Nm,Attr Or $20,0,0);
 End;
 If Not WriteSector(V.Drive,Sec,@Buf) Then Begin SetStandardError(5); Exit End;
 If Not AllocateFileHandle(V.Drive,0,0,2,H) Then Begin SetStandardError(4);
   Exit End;
 FxSetLoc(H,Sec,Idx);
 FxCreate:=H;
End;

{ Mise a jour de l'entree de repertoire (premier cluster, taille) }
Procedure FxFlush(H:Word);
Var
 Buf:TFxSec;
 S,Size:LongInt;
 P,Cl:Word;
 Drive:Byte;
Begin
 S:=FxGetSec(H);
 If S=0 Then Exit;
 Drive:=GetFileTableDrive(H);
 If Not ReadSector(Drive,S,@Buf) Then Exit;
 P:=FxGetIdx(H)*32;
 Cl:=GetFileTableFirstCluster(H);
 Size:=GetFileTableFileSize(H);
 If (Buf[P+26]<>(Cl And $FF)) Or (Buf[P+27]<>(Cl Shr 8)) Or (Buf[P+28]<>(Size
   And $FF)) Or
    (Buf[P+29]<>((Size Shr 8) And $FF)) Or (Buf[P+30]<>((Size Shr 16) And $FF))
      Then FxStamp(Buf,P);
 Buf[P+26]:=Cl And $FF;
 Buf[P+27]:=Cl Shr 8;
 Buf[P+28]:=Size And $FF;
 Buf[P+29]:=(Size Shr 8) And $FF;
 Buf[P+30]:=(Size Shr 16) And $FF;
 Buf[P+31]:=(Size Shr 24) And $FF;
 WriteSector(Drive,S,@Buf);
End;

{ Ecrit Gap octets nuls a la fin du fichier (position courante = taille) }
Function FxWriteData(H:Word;Buffer:Pointer;Count:Word;Var Written:Word):Word;
  Forward;

Procedure FxFillGap(H:Word;Gap:LongInt);
Var Z:Array[0..511] of Byte;
 N,W:Word;
Begin
 FillChar(Z,512,0);
 While Gap>0 Do Begin
  If Gap>512 Then N:=512 Else N:=Word(Gap);
  FxWriteData(H,@Z,N,W);
  If W=0 Then Exit;
  Dec(Gap,W);
 End;
End;

{ 40h avec 0 octet : le fichier est tronque (ou prolonge) a la position courante
  }
Function FxTruncate(H:Word):Word;
Var V:TFxVol;
 Pos,Size:LongInt;
 First,Cur,Off,Nx:Word;
Begin
 FxTruncate:=0;
 Pos:=GetFileTableCurrentPos(H);
 Size:=GetFileTableFileSize(H);
 If Pos=Size Then Exit;
 If Pos>Size Then Begin
  SetFileTableCurrentPos(H,Size);
  FxFillGap(H,Pos-Size);
  Exit;
 End;
 If Not FxVol(GetFileTableDrive(H),V) Then Begin
  FxTruncate:=5;
  Exit;
 End;
 First:=GetFileTableFirstCluster(H);
 Cur:=GetFileTableCurrentCluster(H);
 Off:=GetFileTableClusterOffset(H);
 If Pos=0 Then Begin
  If First>=2 Then FxFreeChain(V,First);
  SetFileTableFirstCluster(H,0);
  SetFileTableCurrentCluster(H,0);
  SetFileTableClusterOffset(H,0);
 End Else If Cur>=2 Then Begin
  Nx:=FxGet(V,Cur);
  FxSet(V,Cur,$FFFF);
  If (Nx>=2) And (Nx<>$FFFF) Then FxFreeChain(V,Nx);
 End;
 SetFileTableFileSize(H,Pos);
End;

Function FxWriteData(H:Word;Buffer:Pointer;Count:Word;Var Written:Word):Word;
Var
 V:TFxVol;
 Sb:Array[0..511] of Byte;
 First,Cur,Off,Nx,CSize,SOff,N:Word;
 Pos,Size,S:LongInt;
 Src:Pointer;
 BufSeg,BufOfs:Word;
 Err:Word;
Begin
 FxWriteData:=6;
 Written:=0;
 If H>=20 Then Exit;
 If Not GetFileTableInUse(H) Then Exit;
 If (GetFileTableAttributes(H) And 3)=0 Then Begin FxWriteData:=5; Exit End;
 If Not FxVol(GetFileTableDrive(H),V) Then Begin FxWriteData:=5; Exit End;
 ASM
  LES DI,Buffer
  MOV BufSeg,ES
  MOV BufOfs,DI
 END;
 If Count=0 Then Begin
  FxWriteData:=FxTruncate(H);
  Exit;
 End;
 Pos:=GetFileTableCurrentPos(H);
 Size:=GetFileTableFileSize(H);
 If Pos>Size Then Begin
  SetFileTableCurrentPos(H,Size);
  FxFillGap(H,Pos-Size);
 End;
 First:=GetFileTableFirstCluster(H);
 Cur:=GetFileTableCurrentCluster(H);
 Off:=GetFileTableClusterOffset(H);
 Pos:=GetFileTableCurrentPos(H);
 Size:=GetFileTableFileSize(H);
 CSize:=V.SPC*512;
 If (First>=2) And ((Cur=$FFFF) Or (Cur<2)) Then Begin
  { apres une lecture jusqu'a la fin : revenir sur le dernier cluster de la
    chaine }
  Cur:=First;
  While (FxGet(V,Cur)<>$FFFF) And (FxGet(V,Cur)>=2) Do Cur:=FxGet(V,Cur);
  Off:=CSize;
 End;
 Err:=0;
 While (Count>0) And (Err=0) Do Begin
  If First=0 Then Begin
   First:=FxAlloc(V,0);
   If First=0 Then Err:=5 Else Begin Cur:=First; Off:=0 End;
  End Else If Cur=0 Then Begin Cur:=First; Off:=0 End;
  If (Err=0) And (Off>=CSize) Then Begin
   Nx:=FxGet(V,Cur);
   If Nx=$FFFF Then Nx:=FxAlloc(V,Cur);
   If Nx=0 Then Err:=5 Else Begin Cur:=Nx; Off:=0 End;
  End;
  If Err=0 Then Begin
   SOff:=Off Mod 512;
   N:=512-SOff;
   If N>Count Then N:=Count;
   S:=V.FirstData+LongInt(Cur-2)*V.SPC+Off Div 512;
   If N<512 Then ReadSector(V.Drive,S,@Sb);
   Src:=Ptr(BufSeg,BufOfs);
   Move(Src^,Sb[SOff],N);
   If Not WriteSector(V.Drive,S,@Sb) Then Err:=5
   Else Begin
    Inc(BufOfs,N);
    Inc(Written,N);
    Dec(Count,N);
    Inc(Off,N);
    Inc(Pos,N);
    If Pos>Size Then Size:=Pos;
   End;
  End;
 End;
 SetFileTableFirstCluster(H,First);
 SetFileTableCurrentCluster(H,Cur);
 SetFileTableClusterOffset(H,Off);
 SetFileTableCurrentPos(H,Pos);
 SetFileTableFileSize(H,Size);
 FxWriteData:=Err;
End;

Function FxDelete(PathPtr:Pointer):Word;
Var
 V:TFxVol;
 Dir:Word;
 Nm:String;
 Sec,FS:LongInt;
 Idx:Byte;
 FI:Integer;
 E:TFxEnt;
 Buf:TFxSec;
Begin
 FxDelete:=3;
 If Not FxOpenPath(PathPtr,V,Dir,Nm) Then Begin SetStandardError(3); Exit End;
 FxDelete:=2;
 If Not FxScan(V,Dir,Nm,Sec,Idx,FS,FI,E) Then Begin SetStandardError(2);
   Exit End;
 FxDelete:=5;
 If (E.Attr And $11)<>0 Then Begin SetStandardError(5); Exit End;
 If E.Cluster>=2 Then FxFreeChain(V,E.Cluster);
 If Not ReadSector(V.Drive,Sec,@Buf) Then Begin SetStandardError(5); Exit End;
 Buf[Idx*32]:=$E5;
 If Not WriteSector(V.Drive,Sec,@Buf) Then Begin SetStandardError(5); Exit End;
 FxDelete:=0;
End;

Function FxRename(OldPtr,NewPtr:Pointer):Word;
Var
 V,V2:TFxVol;
 Dir,Dir2:Word;
 Nm,Nm2:String;
 Sec,FS,Sec2,FS2:LongInt;
 Idx,Idx2:Byte;
 FI,FI2:Integer;
 E,E2:TFxEnt;
 Buf:TFxSec;
 Ent:Array[0..31] of Byte;
 K:Byte;
Begin
 FxRename:=3;
 If Not FxOpenPath(OldPtr,V,Dir,Nm) Then Begin SetStandardError(3); Exit End;
 If Not FxOpenPath(NewPtr,V2,Dir2,Nm2) Then Begin SetStandardError(3); Exit End;
 If FxBadName(Nm2) Then Begin SetStandardError(3); Exit End;
 FxRename:=2;
 If Not FxScan(V,Dir,Nm,Sec,Idx,FS,FI,E) Then Begin SetStandardError(2);
   Exit End;
 FxRename:=5;
 If V.Drive<>V2.Drive Then Begin SetStandardError(17); FxRename:=17; Exit End;
 If FxScan(V2,Dir2,Nm2,Sec2,Idx2,FS2,FI2,E2) Then Begin SetStandardError(5);
   Exit End;
 If Not ReadSector(V.Drive,Sec,@Buf) Then Begin SetStandardError(5); Exit End;
 If Dir=Dir2 Then Begin
  For K:=0 To 10 Do Buf[Idx*32+K]:=Ord(Nm2[K+1]);
  If Not WriteSector(V.Drive,Sec,@Buf) Then Begin SetStandardError(5); Exit End;
 End Else Begin
  If FI2<0 Then Begin SetStandardError(5); Exit End;
  For K:=0 To 31 Do Ent[K]:=Buf[Idx*32+K];
  For K:=0 To 10 Do Ent[K]:=Ord(Nm2[K+1]);
  Buf[Idx*32]:=$E5;
  If Not WriteSector(V.Drive,Sec,@Buf) Then Begin SetStandardError(5); Exit End;
  If Not ReadSector(V.Drive,FS2,@Buf) Then Begin SetStandardError(5); Exit End;
  For K:=0 To 31 Do Buf[FI2*32+K]:=Ent[K];
  If Not WriteSector(V.Drive,FS2,@Buf) Then Begin SetStandardError(5); Exit End;
 End;
 FxRename:=0;
End;

Function FxMkDir(PathPtr:Pointer):Word;
Var
 V:TFxVol;
 Dir,C:Word;
 Nm,Dot:String;
 Sec,FS:LongInt;
 Idx:Byte;
 FI:Integer;
 E:TFxEnt;
 Buf:TFxSec;
 K:Byte;
Begin
 FxMkDir:=3;
 If Not FxOpenPath(PathPtr,V,Dir,Nm) Then Begin SetStandardError(3); Exit End;
 If FxBadName(Nm) Then Begin SetStandardError(3); Exit End;
 FxMkDir:=5;
 If FxScan(V,Dir,Nm,Sec,Idx,FS,FI,E) Then Begin SetStandardError(5); Exit End;
 If FI<0 Then Begin
  If Not FxGrowDir(V,Dir,FS) Then Begin SetStandardError(5); Exit End;
  FI:=0;
 End;
 C:=FxAlloc(V,0);
 If C=0 Then Begin SetStandardError(5); Exit End;
 { cluster du nouveau repertoire : "." et ".." puis entrees vides }
 FillChar(Buf,512,0);
 Dot:='.          ';
 FxPutEnt(Buf,0,Dot,$10,C,0);
 Dot:='..         ';
 FxPutEnt(Buf,32,Dot,$10,Dir,0);
 WriteSector(V.Drive,V.FirstData+LongInt(C-2)*V.SPC,@Buf);
 FillChar(Buf,512,0);
 For K:=1 To V.SPC-1 Do WriteSector(V.Drive,V.FirstData+LongInt(C-2)*V.SPC+K,
   @Buf);
 { entree dans le repertoire parent }
 If Not ReadSector(V.Drive,FS,@Buf) Then Begin SetStandardError(5); Exit End;
 FxPutEnt(Buf,FI*32,Nm,$10,C,0);
 If Not WriteSector(V.Drive,FS,@Buf) Then Begin SetStandardError(5); Exit End;
 FxMkDir:=0;
End;

Function FxRmDir(PathPtr:Pointer):Word;
Var
 V:TFxVol;
 Dir:Word;
 Nm:String;
 Sec,FS,S:LongInt;
 Idx,I:Byte;
 FI:Integer;
 E:TFxEnt;
 Buf:TFxSec;
 N:Word;
Begin
 FxRmDir:=3;
 If Not FxOpenPath(PathPtr,V,Dir,Nm) Then Begin SetStandardError(3); Exit End;
 If Not FxScan(V,Dir,Nm,Sec,Idx,FS,FI,E) Then Begin SetStandardError(3);
   Exit End;
 FxRmDir:=5;
 If (E.Attr And $10)=0 Then Begin SetStandardError(5); Exit End;
 { le repertoire doit etre vide (hors "." et "..") }
 N:=0;
 While FxDirSec(V,E.Cluster,N,S) Do Begin
  If Not ReadSector(V.Drive,S,@Buf) Then Begin SetStandardError(5); Exit End;
  For I:=0 To 15 Do
   If (Buf[I*32]<>0) And (Buf[I*32]<>$E5) And (Buf[I*32]<>Ord('.')) Then Begin
     SetStandardError(5); Exit End;
  Inc(N);
 End;
 If E.Cluster>=2 Then FxFreeChain(V,E.Cluster);
 If Not ReadSector(V.Drive,Sec,@Buf) Then Begin SetStandardError(5); Exit End;
 Buf[Idx*32]:=$E5;
 If Not WriteSector(V.Drive,Sec,@Buf) Then Begin SetStandardError(5); Exit End;
 FxRmDir:=0;
End;

Function FxChDir(PathPtr:Pointer):Word;
Var
 V:TFxVol;
 P:PChar;
 Path,Full,NewP,Comp,Nm:String;
 Dr,I,J,Idx:Byte;
 Dir:Word;
 Sec,FS:LongInt;
 FI:Integer;
 E:TFxEnt;
Begin
 FxChDir:=3;
 P:=PChar(PathPtr);
 Path:='';
 I:=0;
 While (P^<>#0) And (I<255) Do Begin
  Path:=Path+P^;
  Inc(P);
  Inc(I);
 End;
 Dr:=GetCurrentDrive;
 Full:=Path;
 If (Length(Path)>=2) And (Path[2]=':') Then Begin
  Dr:=Ord(UpCase(Path[1]))-Ord('A');
  Full:=Copy(Path,3,255);
 End;
 If Dr>NDrv-1 Then Begin FxChDir:=15; Exit End;
 If Not FxVol(Dr,V) Then Begin FxChDir:=15; Exit End;
 If Full='' Then Begin
  SetCurrentDrive(Dr);
  FxChDir:=0;
  Exit;
 End;
 If Full[1]='\' Then Begin
  Dir:=0;
  NewP:='\';
 End Else Begin
  Dir:=GetCurrentDirCluster(Dr);
  NewP:=GetCurrentDirPath(Dr);
  If NewP='' Then NewP:='\';
 End;
 I:=1;
 While I<=Length(Full) Do Begin
  If Full[I]='\' Then Inc(I) Else Begin
   J:=I;
   While (J<=Length(Full)) And (Full[J]<>'\') Do Inc(J);
   Comp:=Copy(Full,I,J-I);
   I:=J;
   If Comp<>'.' Then Begin
    FxName11(Comp,Nm);
    If Not FxScan(V,Dir,Nm,Sec,Idx,FS,FI,E) Then Begin SetStandardError(3);
      Exit End;
    If (E.Attr And $10)=0 Then Begin SetStandardError(3); Exit End;
    Dir:=E.Cluster;
    If Comp='..' Then Begin
     { retire le dernier composant du chemin }
     J:=Length(NewP);
     While (J>1) And (NewP[J]<>'\') Do Dec(J);
     If J<=1 Then NewP:='\' Else NewP:=Copy(NewP,1,J-1);
    End Else Begin
     If NewP<>'\' Then NewP:=NewP+'\';
     J:=1;
     While J<=Length(Comp) Do Begin Comp[J]:=UpCase(Comp[J]); Inc(J) End;
     NewP:=NewP+Comp;
    End;
   End;
  End;
 End;
 SetCurrentDirCluster(Dr,Dir);
 SetCurrentDirPath(Dr,NewP);
 SetCurrentDrive(Dr);
 FxChDir:=0;
End;

{ Etat d'une recherche 4Eh/4Fh : conserve dans les 21 octets reserves de la DTA
  (comme MS-DOS), ce qui
  permet plusieurs recherches imbriquees : [0]=lecteur+1, [1..12]=masque,
    [13]=attributs, [14..15]=entree,
  [16..17]=repertoire, [18]=actif }
Procedure FindSaveDta(Var St:FindFileState;Var DTA:DTAStruct);
Var K:Byte;
Begin
 DTA.Reserved[0]:=Ord(St.SearchPath[1])-64;
 For K:=1 To 12 Do
  If K<=Length(St.SearchMask) Then DTA.Reserved[K]:=Ord(St.SearchMask[K]) Else
    DTA.Reserved[K]:=0;
 DTA.Reserved[13]:=St.SearchAttr;
 DTA.Reserved[14]:=Lo(St.CurrentEntry);
 DTA.Reserved[15]:=Hi(St.CurrentEntry);
 DTA.Reserved[16]:=Lo(St.CurrentDir);
 DTA.Reserved[17]:=Hi(St.CurrentDir);
 If St.Active Then DTA.Reserved[18]:=1 Else DTA.Reserved[18]:=0;
End;

Procedure FindLoadDta(Var DTA:DTAStruct;Var St:FindFileState);
Var K:Byte;
Begin
 St.Active:=DTA.Reserved[18]=1;
 St.SearchPath:='A';
 St.SearchPath[1]:=Chr(DTA.Reserved[0]+64);
 K:=0;
 While (K<12) And (DTA.Reserved[K+1]<>0) Do Begin
  Inc(K);
  St.SearchMask[K]:=Chr(DTA.Reserved[K]);
 End;
 St.SearchMask[0]:=Chr(K);
 St.SearchAttr:=DTA.Reserved[13];
 St.CurrentEntry:=Word(DTA.Reserved[14])+Word(DTA.Reserved[15])*256;
 St.CurrentDir:=Word(DTA.Reserved[16])+Word(DTA.Reserved[17])*256;
End;

{ Recherche de fichiers (4Eh/4Fh) : repertoire courant ou sous-repertoire,
  entrees de toute taille de repertoire }
Function FxFindFrom(Var DTA:DTAStruct):Word;
Var
 V:TFxVol;
 St:FindFileState;
 Buf:TFxSec;
 Nm:String;
 N,P:Word;
 I,I0,K,L:Byte;
 S:LongInt;
Begin
 FxFindFrom:=18;
 FindLoadDta(DTA,St);
 If Not St.Active Then Exit;
 If (St.SearchPath[1]<'A') Or (St.SearchPath[1]>'Z') Then Exit;
 If Not FxVol(Ord(St.SearchPath[1])-65,V) Then Exit;
 N:=St.CurrentEntry Div 16;
 I0:=Byte(St.CurrentEntry Mod 16);
 While FxDirSec(V,St.CurrentDir,N,S) Do Begin
  If Not ReadSector(V.Drive,S,@Buf) Then Exit;
  For I:=I0 To 15 Do Begin
   P:=I*32;
   If Buf[P]=0 Then Begin
    St.Active:=False;
    FindSaveDta(St,DTA);
    Exit;
   End;
   If (Buf[P]<>$E5) And ((Buf[P+11] And $1E And (Not St.SearchAttr))=0) Then
     Begin
    L:=0;
    For K:=0 To 7 Do
     If Buf[P+K]<>32 Then Begin Inc(L); Nm[L]:=Chr(Buf[P+K]) End Else Break;
    If Buf[P+8]<>32 Then Begin
     Inc(L);
     Nm[L]:='.';
     For K:=8 To 10 Do
      If Buf[P+K]<>32 Then Begin Inc(L); Nm[L]:=Chr(Buf[P+K]) End Else Break;
    End;
    Nm[0]:=Chr(L);
    If MatchFileName(Nm,St.SearchMask) Then Begin
     FillChar(DTA.Reserved,21,0);
     DTA.Attribute:=Buf[P+11];
     DTA.Time:=Word(Buf[P+22])+Word(Buf[P+23])*256;
     DTA.Date:=Word(Buf[P+24])+Word(Buf[P+25])*256;
     DTA.Size:=Word(Buf[P+28])+Word(Buf[P+29])*256+(LongInt(Buf[P+30])+
       LongInt(Buf[P+31])*256)*65536;
     Move(Nm[1],DTA.Name[0],L);
     DTA.Name[L]:=#0;
     St.CurrentEntry:=N*16+I+1;
     FindSaveDta(St,DTA);
     FxFindFrom:=0;
     Exit;
    End;
   End;
  End;
  I0:=0;
  Inc(N);
 End;
 St.Active:=False;
 FindSaveDta(St,DTA);
End;

Function FxFindFirst(Path:String;Attr:Byte;Var DTA:DTAStruct):Word;
Var
 V:TFxVol;
 St:FindFileState;
 DirP,Mask:String;
 Dr,Q,L,J:Byte;
 Dir,Start:Word;
Begin
 FxFindFirst:=18;
 Dr:=GetCurrentDrive;
 Q:=1;
 If (Length(Path)>=2) And (Path[2]=':') Then Begin
  Dr:=Ord(UpCase(Path[1]))-Ord('A');
  Q:=3;
 End;
 L:=0;
 For J:=Q To Length(Path) Do
  If (Path[J]='\') Or (Path[J]='/') Then L:=J;
 If L>0 Then Begin
  DirP:=Copy(Path,Q,L-Q);
  Mask:=Copy(Path,L+1,255);
 End Else Begin
  DirP:='';
  Mask:=Copy(Path,Q,255);
 End;
 If Mask='' Then Mask:='*.*';
 If Dr>NDrv-1 Then Begin FxFindFirst:=3; Exit End;
 If Not FxVol(Dr,V) Then Begin FxFindFirst:=3; Exit End;
 If (Q<=Length(Path)) And ((Path[Q]='\') Or (Path[Q]='/')) Then Start:=0 Else
   Start:=GetCurrentDirCluster(Dr);
 If Not FxWalk(V,DirP,Start,Dir) Then Begin FxFindFirst:=3; Exit End;
 If Mask='*.*' Then Mask:='*';
 St.SearchMask:=UpperCase(Mask);
 St.SearchPath:=Chr(Dr+65);
 St.SearchAttr:=Attr;
 St.CurrentDir:=Dir;
 St.CurrentEntry:=0;
 St.Active:=True;
 FindSaveDta(St,DTA);
 FxFindFirst:=FxFindFrom(DTA);
End;

{ Fonction 36h : espace disque (clusters libres comptes dans la FAT) }
Function DOS36h_DiskFree(Drive:Byte;Var R:TFxFree):Word;
Var
 V:TFxVol;
 B:Array[0..1023] of Byte;
 C,K,O,X,Cnt:Word;
 Off,S,CS:LongInt;
Begin
 DOS36h_DiskFree:=15;
 If Drive=0 Then Drive:=GetCurrentDrive Else Dec(Drive);
 If Drive>NDrv-1 Then Exit;
 If Not FxVol(Drive,V) Then Exit;
 CS:=-1;
 Cnt:=0;
 If V.Is16 Then Begin
  { FAT16 : parcours direct de chaque secteur de la FAT (256 entrees) }
  C:=2;
  While C<=V.Clusters+1 Do Begin
   If Not ReadSector(V.Drive,V.Res+LongInt(C) Div 256,@B) Then Exit;
   O:=C And 255;
   Repeat
    If (B[O*2]=0) And (B[O*2+1]=0) Then Inc(Cnt);
    Inc(O);
    Inc(C);
   Until (O=256) Or (C>V.Clusters+1);
  End;
 End Else
 For K:=0 To V.Clusters-1 Do Begin
  C:=K+2;
  If V.Is16 Then Off:=LongInt(C)*2 Else Off:=LongInt(C)*3 Div 2;
  S:=V.Res+Off Div 512;
  If S<>CS Then Begin
   If Not ReadSector(V.Drive,S,@B) Then Exit;
   ReadSector(V.Drive,S+1,@B[512]);
   CS:=S;
  End;
  O:=Word(Off Mod 512);
  X:=Word(B[O])+Word(B[O+1])*256;
  If Not V.Is16 Then Begin
   If (C And 1)=0 Then X:=X And $0FFF Else X:=X Shr 4;
  End;
  If X=0 Then Inc(Cnt);
 End;
 R.SPC:=V.SPC;
 R.BPS:=512;
 R.Total:=V.Clusters;
 R.Free:=Cnt;
 DOS36h_DiskFree:=0;
End;

Function DOS3Ah_RemoveDirectory(PathPtr:Pointer):Word;
Begin
 DOS3Ah_RemoveDirectory:=FxRmDir(PathPtr);
End;

Function DOS39h_MakeDirectory(PathPtr:Pointer):Word;
Begin
 DOS39h_MakeDirectory:=FxMkDir(PathPtr);
End;
{==============================================================================}
{ FONCTIONS POUR CHANGER DE RÉPERTOIRE (Fonction 3Bh)                        }
{==============================================================================}

Function FindDirectoryByPath(Drive:Byte;BootSec:BootSectorRec;Path:String;
  Var DirCluster:Word):Boolean;
{ Trouve un répertoire par son chemin complet }
Var
 PathParts:Array[0..15] of String; { Maximum 16 niveaux }
 PartCount:Byte;
 CurrentCluster:Word;
 I,J:Byte;
 TempPath:String;
 Entry:DirectoryEntry;
 EntryOffset:Word;
Begin
 FindDirectoryByPath:=False;
 DirCluster:=0;

 { Traiter le cas du répertoire racine }
 If (Path = '\') or (Path = '') Then Begin
  DirCluster:=0; { Répertoire racine }
  FindDirectoryByPath:=True;
  Exit;
 End;

 { Décomposer le chemin en parties }
 TempPath:=Path;
 PartCount:=0;

 { Enlever le \ initial s'il existe }
 If (Length(TempPath) > 0) and (TempPath[1] = '\') Then
  Delete(TempPath,1,1);

 { Séparer par \ }
 While (Length(TempPath) > 0) and (PartCount < 16) Do Begin
  J:=Pos('\',TempPath);
  If J = 0 Then Begin
   PathParts[PartCount]:=TempPath;
   TempPath:='';
  End
  Else Begin
   PathParts[PartCount]:=Copy(TempPath,1,J-1);
   Delete(TempPath,1,J);
  End;
  Inc(PartCount);
 End;

 { Commencer par le répertoire racine }
 CurrentCluster:=0;

 { Parcourir chaque partie du chemin }
 For I:=0 To PartCount-1 Do Begin
  If Not FindDirectoryEntry(Drive,BootSec,CurrentCluster,PathParts[I],Entry,
    EntryOffset) Then
   Exit; { Partie non trouvée }

  { Vérifier que c'est un répertoire }
  If (Entry.Attributes and $10) = 0 Then
   Exit; { Pas un répertoire }

  { Passer au cluster suivant }
  CurrentCluster:=Entry.FirstClusterLow or (Word(Entry.FirstClusterHigh) shl
    16);
 End;

 DirCluster:=CurrentCluster;
 FindDirectoryByPath:=True;
End;

Function SetCurrentDirectory(Drive:Byte;DirCluster:Word):Boolean;
{ Met à jour le répertoire courant pour un lecteur }
Begin
 SetCurrentDirectory:=False;

 { Vérifier validité du lecteur }
 If Drive>NDrv-1 Then Exit; { A-Z seulement }

 { Mettre à jour via les fonctions d'accès Code Segment }
 SetCurrentDirDrive(Drive, Drive);
 SetCurrentDirCluster(Drive, DirCluster);

 { Pour l'instant, path sera mis à jour plus tard }
 If DirCluster = 0 Then
  SetCurrentDirPath(Drive, '\')
 Else
  SetCurrentDirPath(Drive, '\SUBDIR'); { Simplifié pour le test }

 SetCurrentDirectory:=True;
End;

Function DOS3Bh_ChangeDirectory(PathPtr:Pointer):Word;
Begin
 DOS3Bh_ChangeDirectory:=FxChDir(PathPtr);
End;
{==============================================================================}
{ FONCTIONS POUR 3Ch - CREATE OR OPEN FILE                                    }
{==============================================================================}

{ Analyser un chemin de fichier (séparé répertoire/fichier) }
Function ParseFilePath(Path:String;Var Drive:Byte;Var DirPath,
  FileName:String):Boolean;
Var
 I,J:Byte;
 FullPath:String;
Begin
 ParseFilePath:=False;
 Drive:=GetCurrentDrive;
 DirPath:='';
 FileName:='';

 If Length(Path) = 0 Then Exit;

 FullPath:=Path;

 { Analyser le lecteur }
 If (Length(FullPath) >= 2) and (FullPath[2] = ':') Then Begin
  Drive:=Ord(UpCase(FullPath[1])) - Ord('A');
  Delete(FullPath,1,2);
 End;

 If Drive>NDrv-1 Then Exit; { Lecteur invalide }

 { Trouver le dernier backslash }
 I:=0;
 For J:=1 To Length(FullPath) Do Begin
  If FullPath[J] = '\' Then I:=J;
 End;

 If I > 0 Then Begin
  { Il y a un chemin de répertoire }
  DirPath:=Copy(FullPath,1,I-1);
  FileName:=Copy(FullPath,I+1,255);
 End
 Else Begin
  { Pas de chemin - fichier dans répertoire courant }
  DirPath:='';
  FileName:=FullPath;
 End;

 { Valider nom de fichier (format 8.3) }
 If Length(FileName) = 0 Then Exit;
 If Length(FileName) > 12 Then Exit; { nom.ext max }

 ParseFilePath:=True;
End;

{ Allouer un handle de fichier libre }
Function AllocateFileHandle(Drive:Byte;FirstCluster,FileSize:LongInt;
                           Attributes:Byte;Var Handle:Word):Boolean;
Var
 I:Byte;
Begin
 AllocateFileHandle:=False;
 Handle:=0;

 { Chercher une entrée libre dans la table des fichiers (poignées 0..4 =
   périphériques standard) }
 For I:=5 To CfgWord(0)-1 Do Begin
  If Not GetFileTableInUse(I) Then Begin
   { Initialiser l'entrée via fonctions d'accès Code Segment }
   SetFileTableInUse(I, True);
   SetFileTableDrive(I, Drive);
   SetFileTableFirstCluster(I, FirstCluster);
   SetFileTableFileSize(I, FileSize);
   SetFileTableCurrentPos(I, 0);
   SetFileTableAttributes(I, Attributes);
   SetFileTableCurrentCluster(I, FirstCluster);
   SetFileTableClusterOffset(I, 0);
   SftRefSet(I,1);

   Handle:=I;
   AllocateFileHandle:=True;
   Exit;
  End;
 End;
End;

{ Créer une nouvelle entrée de fichier dans le répertoire }
Function CreateFileEntry(Drive:Byte;BootSec:BootSectorRec;DirCluster:Word;
                        FileName:String;Attributes:Byte;
                          Var FirstCluster:Word):Word;
Var
 Buffer: Array[0..511] of Byte;
 Entry: DirectoryEntry;
 Sector: LongInt;
 I,J: Byte;
 EntryPtr: Pointer;
 Found: Boolean;
 DirSector: LongInt;
 EntriesPerSector: Byte;
Begin
 CreateFileEntry:=5; { Access denied par défaut }
 FirstCluster:=0;

 { Calculer le secteur du répertoire }
 If DirCluster = 0 Then Begin
  { Répertoire racine }
  DirSector:=BootSec.ReservedSectors + (BootSec.NumberOfFATs *
    BootSec.SectorsPerFAT);
 End
 Else Begin
  { Sous-répertoire }
  DirSector:=GetClusterSector(Drive,BootSec,DirCluster);
  If DirSector = -1 Then Begin
   CreateFileEntry:=3; { Path not found }
   Exit;
  End;
 End;

 { Chercher une entrée libre }
 EntriesPerSector:=BootSec.BytesPerSector Div 32;
 Found:=False;

 For I:=0 To 15 Do Begin { Maximum 16 secteurs à chercher }
  If Not ReadSector(Drive,DirSector + I,@Buffer) Then Begin
   CreateFileEntry:=5; { Access denied }
   Exit;
  End;

  For J:=0 To EntriesPerSector-1 Do Begin
   EntryPtr:=@Buffer[J * 32];
   Move(EntryPtr^,Entry,32);

   { Vérifier si l'entrée est libre }
   If (Entry.FileName[0] = #0) or (Entry.FileName[0] = #$E5) Then Begin
    Found:=True;
    Break;
   End;
  End;

  If Found Then Break;
 End;

 If Not Found Then Begin
  CreateFileEntry:=5; { Access denied - répertoire plein }
  Exit;
 End;

 { Allouer un cluster pour le fichier }
 FirstCluster:=FindFreeCluster(Drive,BootSec);
 If FirstCluster = 0 Then Begin
  CreateFileEntry:=5; { Access denied - disque plein }
  Exit;
 End;

 If Not AllocateCluster(Drive,BootSec,FirstCluster) Then Begin
  CreateFileEntry:=5; { Access denied }
  Exit;
 End;

 { Créer l'entrée de répertoire }
 FillChar(Entry,32,0);

 { Convertir nom fichier au format 8.3 }
 FillChar(Entry.FileName,11,32); { Espaces }
 J:=1;
 For I:=0 To 7 Do Begin
  If (J <= Length(FileName)) and (FileName[J] <> '.') Then Begin
   Entry.FileName[I]:=UpCase(FileName[J]);
   Inc(J);
  End
  Else Break;
 End;

 { Chercher l'extension }
 While (J <= Length(FileName)) and (FileName[J] <> '.') Do Inc(J);
 If J < Length(FileName) Then Begin
  Inc(J); { Passer le point }
  For I:=8 To 10 Do Begin
   If J <= Length(FileName) Then Begin
    Entry.Extension[I-8]:=UpCase(FileName[J]);
    Inc(J);
   End;
  End;
 End;

 Entry.Attributes:=Attributes;
 Entry.FirstClusterLow:=FirstCluster;
 Entry.FirstClusterHigh:=0;
 Entry.FileSize:=0;

 { Écrire l'entrée }
 Move(Entry,EntryPtr^,32);

 If Not WriteSector(Drive,DirSector + I,@Buffer) Then Begin
  CreateFileEntry:=5; { Access denied }
  Exit;
 End;

 CreateFileEntry:=0; { Succès }
End;

{ Ouvrir un fichier existant }
Function OpenExistingFile(Drive:Byte;Entry:DirectoryEntry;Var Handle:Word):Word;
Var
 FirstCluster: Word;
 FileSize: LongInt;
Begin
 FirstCluster:=Entry.FirstClusterLow or (LongInt(Entry.FirstClusterHigh) shl
   16);
 FileSize:=Entry.FileSize;

 If AllocateFileHandle(Drive,FirstCluster,FileSize,Entry.Attributes,Handle) Then
  OpenExistingFile:=0 { Succès }
 Else
  OpenExistingFile:=4; { Too many open files }
End;

{ Trouver ou créer un fichier }
Function FindOrCreateFile(Drive:Byte;BootSec:BootSectorRec;DirPath,
  FileName:String;
                         Attributes:Byte;Var FileHandle:Word):Word;
Var
 DirCluster: Word;
 Entry: DirectoryEntry;
 EntryOffset: Word;
 FirstCluster: Word;
 Result: Word;
Begin
 FileHandle:=0;

 { Trouver le répertoire parent }
 If DirPath = '' Then
  DirCluster:=0 { Répertoire racine }
 Else Begin
  If Not FindDirectoryByPath(Drive,BootSec,DirPath,DirCluster) Then Begin
   FindOrCreateFile:=3; { Path not found }
   Exit;
  End;
 End;

 { Chercher si le fichier existe déjà }
 If FindDirectoryEntry(Drive,BootSec,DirCluster,FileName + '        ',Entry,
   EntryOffset) Then Begin
  { Fichier existant - l'ouvrir }
  If (Entry.Attributes and $10) <> 0 Then Begin
   FindOrCreateFile:=5; { Access denied - c'est un répertoire }
   Exit;
  End;

  FindOrCreateFile:=OpenExistingFile(Drive,Entry,FileHandle);
 End
 Else Begin
  { Fichier n'existe pas - le créer }
  Result:=CreateFileEntry(Drive,BootSec,DirCluster,FileName,Attributes,
    FirstCluster);
  If Result <> 0 Then Begin
   FindOrCreateFile:=Result;
   Exit;
  End;

  { Allouer un handle pour le nouveau fichier }
  If AllocateFileHandle(Drive,FirstCluster,0,Attributes,FileHandle) Then
   FindOrCreateFile:=0
  Else
   FindOrCreateFile:=4; { Too many open files }
 End;
End;

{ Fonction principale 3Ch }
Function DOS3Ch_CreateOpenFile(PathPtr:Pointer):Word;
Begin
 DOS3Ch_CreateOpenFile:=FxCreate(PathPtr,0,False);
End;
{ Valider mode d'accès pour fonction 3Dh }
Function ValidateAccessMode(AccessMode:Byte):Boolean;
Begin
 { Modes valides : 0=lecture seule, 1=écriture seule, 2=lecture/écriture }
 ValidateAccessMode:=(AccessMode and $03) <= 2;
End;

{ Ouvrir fichier en lecture seule }
Function OpenFileReadOnly(Drive:Byte;Entry:DirectoryEntry;Var Handle:Word):Word;
Var
 FirstCluster: Word;
 FileSize: LongInt;
Begin
 FirstCluster:=Entry.FirstClusterLow or (LongInt(Entry.FirstClusterHigh) shl
   16);
 FileSize:=Entry.FileSize;

 If AllocateFileHandle(Drive,FirstCluster,FileSize,$00,Handle) Then
  OpenFileReadOnly:=0 { Succès }
 Else
  OpenFileReadOnly:=4; { Too many open files }
End;

{ Ouvrir fichier en écriture seule }
Function OpenFileWriteOnly(Drive:Byte;Entry:DirectoryEntry;
  Var Handle:Word):Word;
Var
 FirstCluster: Word;
 FileSize: LongInt;
Begin
 FirstCluster:=Entry.FirstClusterLow or (LongInt(Entry.FirstClusterHigh) shl
   16);
 FileSize:=Entry.FileSize;

 If AllocateFileHandle(Drive,FirstCluster,FileSize,$01,Handle) Then
  OpenFileWriteOnly:=0 { Succès }
 Else
  OpenFileWriteOnly:=4; { Too many open files }
End;

{ Ouvrir fichier en lecture/écriture }
Function OpenFileReadWrite(Drive:Byte;Entry:DirectoryEntry;
  Var Handle:Word):Word;
Var
 FirstCluster: Word;
 FileSize: LongInt;
Begin
 FirstCluster:=Entry.FirstClusterLow or (LongInt(Entry.FirstClusterHigh) shl
   16);
 FileSize:=Entry.FileSize;

 If AllocateFileHandle(Drive,FirstCluster,FileSize,$02,Handle) Then
  OpenFileReadWrite:=0 { Succès }
 Else
  OpenFileReadWrite:=4; { Too many open files }
End;

{ Fonction principale 3Dh }
Function DOS3Dh_OpenFile(PathPtr:Pointer;AccessMode:Byte):Word;
Begin
 If Not ValidateAccessMode(AccessMode) Then Begin
  SetStandardError(ERROR_INVALID_FUNCTION);
  DOS3Dh_OpenFile:=$FFFF;
  Exit;
 End;
 DOS3Dh_OpenFile:=FxOpen(PathPtr,AccessMode);
End;
{ Flush les buffers de fichier vers le disque }
Function FlushFileBuffers(Handle:Word):Word;
Var
 FileEntry: FileTableEntry;
 Drive: Byte;
 BootSec: BootSectorRec;
Begin
 FlushFileBuffers:=6; { Invalid handle par défaut }

 { Vérifier la validité du handle }
 If Handle >= 20 Then Exit;

 If Not GetFileTableEntry(Handle,FileEntry) Then Exit;

 { Vérifier si le handle est utilisé }
 If Not FileEntry.InUse Then Exit;

 Drive:=FileEntry.Drive; { index 0-based, tel que stocké }

 { Lire boot sector }
 If Not ReadBootSector(Drive,BootSec) Then Begin
  FlushFileBuffers:=5; { Access denied }
  Exit;
 End;

 { Pour l'instant, on simule un flush réussi }
 { Dans un vrai système, on écrirait les buffers modifiés }

 FlushFileBuffers:=0; { Succès }
End;

{ Mettre à jour l'entrée de répertoire avec la nouvelle taille et date }
Function UpdateDirectoryEntry(Handle:Word):Word;
Var
 FileEntry: FileTableEntry;
 Drive: Byte;
 BootSec: BootSectorRec;
 DirCluster: Word;
 Entry: DirectoryEntry;
 EntryOffset: Word;
 Buffer: Array[0..511] of Byte;
 SectorInDir: Word;
 EntryInSector: Word;
 DirSector: LongInt;
Begin
 UpdateDirectoryEntry:=6; { Invalid handle par défaut }

 { Vérifier la validité du handle }
 If Handle >= 20 Then Exit;

 If Not GetFileTableEntry(Handle,FileEntry) Then Exit;

 { Vérifier si le handle est utilisé }
 If Not FileEntry.InUse Then Exit;

 Drive:=FileEntry.Drive; { index 0-based, tel que stocké }

 { Lire boot sector }
 If Not ReadBootSector(Drive,BootSec) Then Begin
  UpdateDirectoryEntry:=5; { Access denied }
  Exit;
 End;

 { Pour l'instant, on simule une mise à jour réussie }
 { Dans un vrai système, on chercherait l'entrée de répertoire }
 { et on mettrait à jour la taille et la date }

 UpdateDirectoryEntry:=0; { Succès }
End;

{ Fermer un handle de fichier }
Function CloseFileHandle(Handle:Word):Word;
Begin
 CloseFileHandle:=6;
 If Handle>=20 Then Exit;
 If Not GetFileTableInUse(Handle) Then Exit;
 If (GetFileTableAttributes(Handle) And 3)<>0 Then FxFlush(Handle);
 SetFileTableInUse(Handle,False);
 SetFileTableFirstCluster(Handle,0);
 SetFileTableFileSize(Handle,0);
 SetFileTableCurrentPos(Handle,0);
 SetFileTableAttributes(Handle,0);
 SetFileTableCurrentCluster(Handle,0);
 SetFileTableClusterOffset(Handle,0);
 FxSetLoc(Handle,0,0);
 CloseFileHandle:=0;
End;
{ Fonction principale 3Eh }
Function DOS3Eh_CloseFile(Handle:Word):Word;
Begin
 DOS3Eh_CloseFile:=CloseFileHandle(Handle);
End;

{==============================================================================}
{ TABLE DES FICHIERS OUVERTS (SFT) PARTAGEE ET TABLE DE HANDLES PAR PROCESSUS  }
{ (JFT : 20 octets dans le PSP, offset 18h). Un handle de programme est un     }
{ index de JFT ; l'octet correspondant donne l'index dans la SFT (FileTable).  }
{ Les entrees 0..4 de la SFT sont les peripheriques (console...) ; les autres  }
{ sont comptees (SftRef) pour DUP/FORCEDUP et l'heritage par EXEC.             }
{==============================================================================}
Function SftRefGet(I:Byte):Byte;Assembler;
ASM
 MOV AL,I
 XOR AH,AH
 ADD AX,FxBase+104
 MOV BX,AX
 MOV AL,BYTE PTR [Data + BX]
END;

Procedure SftRefSet(I,V:Byte);Assembler;
ASM
 MOV AL,I
 XOR AH,AH
 ADD AX,FxBase+104
 MOV BX,AX
 MOV AL,V
 MOV BYTE PTR [Data + BX],AL
END;

{ Index SFT du handle H du processus courant ($FFFF si invalide) }
Function JftGet(H:Word):Word;
Var P:Word;
Begin
 JftGet:=$FFFF;
 If H>=20 Then Exit;
 P:=GetCurrentPSP;
 If Mem[P:$18+H]=$FF Then Exit;
 JftGet:=Mem[P:$18+H];
End;

{ Libere une reference sur une entree SFT (ferme le fichier a la derniere) }
Procedure SftRelease(S:Word);
Var R:Byte;
Begin
 If (S<5) Or (S>=20) Then Exit;
 R:=SftRefGet(S);
 If R>1 Then SftRefSet(S,R-1)
 Else Begin
  SftRefSet(S,0);
  CloseFileHandle(S);
 End;
End;

{ Premier handle libre du processus courant ($FFFF si aucun) }
Function JftFree:Word;
Var P,H:Word;
Begin
 JftFree:=$FFFF;
 P:=GetCurrentPSP;
 For H:=0 To 19 Do
  If Mem[P:$18+H]=$FF Then Begin
   JftFree:=H;
   Exit;
  End;
End;

{ Associe une entree SFT fraichement ouverte a un handle du processus courant }
Function JftBind(S:Word):Word;
Var P,H:Word;
Begin
 JftBind:=$FFFF;
 If S=$FFFF Then Exit;
 H:=JftFree;
 If H=$FFFF Then Begin
  SftRelease(S);
  SetStandardError(4);
  Exit;
 End;
 P:=GetCurrentPSP;
 Mem[P:$18+H]:=Byte(S);
 JftBind:=H;
End;

{ 3Eh : fermeture d'un handle }
Function JftClose(H:Word):Word;
Var S,P:Word;
Begin
 S:=JftGet(H);
 If S=$FFFF Then Begin
  JftClose:=6;
  Exit;
 End;
 P:=GetCurrentPSP;
 Mem[P:$18+H]:=$FF;
 SftRelease(S);
 JftClose:=0;
End;

{ 45h : duplication d'un handle (nouveau handle = $FFFF si erreur) }
Function JftDup(H:Word):Word;
Var S,N,P:Word;
Begin
 JftDup:=$FFFF;
 S:=JftGet(H);
 If S=$FFFF Then Begin
  SetStandardError(6);
  Exit;
 End;
 N:=JftFree;
 If N=$FFFF Then Begin
  SetStandardError(4);
  Exit;
 End;
 P:=GetCurrentPSP;
 Mem[P:$18+N]:=Byte(S);
 If S>=5 Then SftRefSet(S,SftRefGet(S)+1);
 JftDup:=N;
End;

{ 46h : le handle T designe la meme entree que H (code d'erreur, 0 = succes) }
Function JftForce(H,T:Word):Word;
Var S,Old,P:Word;
Begin
 JftForce:=6;
 S:=JftGet(H);
 If (S=$FFFF) Or (T>=20) Then Begin
  SetStandardError(6);
  Exit;
 End;
 JftForce:=0;
 If H=T Then Exit;
 P:=GetCurrentPSP;
 If S>=5 Then SftRefSet(S,SftRefGet(S)+1);
 Old:=JftGet(T);
 Mem[P:$18+T]:=Byte(S);
 If Old<>$FFFF Then SftRelease(Old);
End;

{ Table de handles d'un nouveau processus : copie de celle du parent (references
  incrementees) }
Procedure JftInherit(Child,Parent:Word);
Var I:Word;
 V:Byte;
Begin
 For I:=0 To 19 Do Mem[Child:$18+I]:=$FF;
 If (Parent=0) Or (MemW[Parent:0]<>$20CD) Then Begin
  For I:=0 To 4 Do Mem[Child:$18+I]:=I;
  Exit;
 End;
 For I:=0 To 19 Do Begin
  V:=Mem[Parent:$18+I];
  If V<>$FF Then Begin
   Mem[Child:$18+I]:=V;
   If (V>=5) And (V<20) Then SftRefSet(V,SftRefGet(V)+1);
  End;
 End;
End;

Procedure LockReleasePsp(Psp:Word);Near;Forward;

{ Fermeture de tous les handles d'un processus qui se termine }
Procedure JftReleaseAll(P:Word);
Var H:Word;
 V:Byte;
Begin
 For H:=0 To 19 Do Begin
  V:=Mem[P:$18+H];
  Mem[P:$18+H]:=$FF;
  If V<>$FF Then SftRelease(V);
 End;
 LockReleasePsp(P);
End;

{ Passerelles INT 21h : handles de programme -> entrees SFT }
Function OpenInt21(PathPtr:Pointer;Mode:Byte):Word;
Begin
 OpenInt21:=JftBind(DOS3Dh_OpenFile(PathPtr,Mode));
End;

Function CreateInt21(PathPtr:Pointer):Word;
Begin
 CreateInt21:=JftBind(DOS3Ch_CreateOpenFile(PathPtr));
End;

Function CreateNewInt21(PathPtr:Pointer;Attr:Word):Word;
Begin
 CreateNewInt21:=JftBind(DOS5Bh_CreateNewFile(PathPtr,Attr));
End;

Function TempInt21(PathPtr:Pointer;Attr:Word):Word;
Begin
 TempInt21:=JftBind(DOS5Ah_CreateTempFile(PathPtr,Attr));
End;

Function CloseInt21(H:Word):Word;
Begin
 CloseInt21:=JftClose(H);
End;

Function SeekInt21(H,OffsetHi,OffsetLo:Word;Method:Byte):LongInt;
Begin
 SeekInt21:=DOS42h_SeekFile(JftGet(H),OffsetHi,OffsetLo,Method);
End;

Function DateTimeInt21(H:Word;Action:Byte;NewDate,NewTime:Word):LongInt;
Begin
 DateTimeInt21:=DOS57h_GetSetFileDateTime(JftGet(H),Action,NewDate,NewTime);
End;

Function LockInt21(H:Word;Action:Byte;Start,Len:LongInt):Word;
Var S:Word;
Begin
 S:=JftGet(H);
 If S>=20 Then Begin
  SetStandardError(6);
  LockInt21:=6;
  Exit;
 End;
 LockInt21:=DOS5Ch_LockUnlockRegion(S,Action,Start,Len);
End;

{ 44h : sous-fonctions de peripherique ;
  Info = valeur de retour (DX pour 0 et 9, AX pour les autres) }
Function IoctlInt21(Sub,H:Word;Var Info:Word):Word;
Var S:Word;
Begin
 IoctlInt21:=0;
 Info:=0;
 Case Sub Of
  8: Info:=1;
  9: Info:=0;
  Else Begin
   S:=JftGet(H);
   If S=$FFFF Then Begin
    SetStandardError(6);
    IoctlInt21:=6;
    Exit;
   End;
   Case Sub Of
    0: If S<5 Then Info:=$80D3 Else Info:=0;
    1: Info:=0;
    6,7: Info:=$FF;
    Else Begin
     SetStandardError(1);
     IoctlInt21:=1;
    End;
   End;
  End;
 End;
End;

{==============================================================================}
{ FCB (INT 21h 0Fh..17h, 21h..24h,
  27h..29h) : traduits en fonctions de handle  }
{ Octets utilises dans le FCB : +18h = index SFT,
  +19h = marqueur $5A (ouvert). }
{==============================================================================}
Procedure BufParts(Buf:Pointer;Var S,O:Word);Near;Forward;

Type
 TFcbZ=Array[0..31] of Char;
 TFcbNm=Array[0..10] of Byte;

Procedure FcbSegOfs(P:Pointer;Var S,O:Word);
Begin
 BufParts(P,S,O);
 If Mem[S:O]=$FF Then Inc(O,7);
End;

{ Nom du FCB (offset Off) sous la forme "[X:]NOM[.EXT]" ;
  False si le nom est vide }
Procedure FcbField(S,O,Off,Len:Word;Wild:Boolean;Var Path:String);
Var I,L,T:Byte;
Begin
 L:=0;
 For I:=1 To Len Do
  If Mem[S:O+Off+I-1]<>32 Then L:=I;
 T:=L;
 If Wild Then
  While (T>0) And (Mem[S:O+Off+T-1]=Ord('?')) Do Dec(T);
 For I:=1 To T Do Path:=Path+Chr(Mem[S:O+Off+I-1]);
 If T<L Then Path:=Path+'*';
End;

{ Off >= $100 : un '?' final d'un champ couvre aussi les caracteres absents
  ('*') }
Function FcbName(S,O,Off:Word;Var Path:String):Boolean;
Var Wild:Boolean;
 N:Byte;
Begin
 Wild:=Off>=$100;
 Off:=Off And $FF;
 Path:='';
 If Mem[S:O]<>0 Then Begin
  Path:='A:';
  Path[1]:=Chr(64+Mem[S:O]);
 End;
 N:=Length(Path);
 FcbField(S,O,Off,8,Wild,Path);
 FcbName:=Length(Path)>N;
 If Length(Path)=N Then Exit;
 N:=Length(Path);
 Path:=Path+'.';
 FcbField(S,O,Off+8,3,Wild,Path);
 If Length(Path)=N+1 Then Path[0]:=Chr(N);
End;

Procedure PathToZ(Var Path:String;Var Z:TFcbZ);
Var I:Byte;
Begin
 For I:=1 To Length(Path) Do Z[I-1]:=Path[I];
 Z[Length(Path)]:=#0;
End;

Function FcbRecSize(S,O:Word):Word;
Begin
 FcbRecSize:=MemW[S:O+$0E];
 If MemW[S:O+$0E]=0 Then FcbRecSize:=128;
End;

Function FcbSft(S,O:Word):Word;
Begin
 FcbSft:=$FFFF;
 If Mem[S:O+$19]=$5A Then FcbSft:=Mem[S:O+$18];
End;

Procedure FcbInit(S,O,T:Word);
Var R:LongInt;
 Sz:LongInt;
Begin
 If Mem[S:O]=0 Then Mem[S:O]:=GetCurrentDrive+1;
 Mem[S:O+$18]:=Byte(T);
 Mem[S:O+$19]:=$5A;
 MemW[S:O+$0C]:=0;
 MemW[S:O+$0E]:=128;
 Sz:=GetFileTableFileSize(T);
 MemW[S:O+$10]:=Word(Sz);
 MemW[S:O+$12]:=Word(Sz Shr 16);
 R:=DOS57h_GetSetFileDateTime(T,0,0,0);
 If R<>$FFFFFFFF Then Begin
  MemW[S:O+$14]:=Word(R Shr 16);
  MemW[S:O+$16]:=Word(R);
 End;
 Mem[S:O+$20]:=0;
End;

Function FcbOpen(P:Pointer):Byte;
Var S,O,T:Word;
 Path:String;
 Z:TFcbZ;
Begin
 FcbOpen:=$FF;
 FcbSegOfs(P,S,O);
 If Not FcbName(S,O,$101,Path) Then Exit;
 PathToZ(Path,Z);
 T:=DOS3Dh_OpenFile(@Z,2);
 If T=$FFFF Then T:=DOS3Dh_OpenFile(@Z,0);
 If T=$FFFF Then Exit;
 FcbInit(S,O,T);
 FcbOpen:=0;
End;

Function FcbCreate(P:Pointer):Byte;
Var S,O,T:Word;
 Path:String;
 Z:TFcbZ;
Begin
 FcbCreate:=$FF;
 FcbSegOfs(P,S,O);
 If Not FcbName(S,O,$101,Path) Then Exit;
 PathToZ(Path,Z);
 T:=DOS3Ch_CreateOpenFile(@Z);
 If T=$FFFF Then Exit;
 FcbInit(S,O,T);
 FcbCreate:=0;
End;

Function FcbClose(P:Pointer):Byte;
Var S,O,T:Word;
Begin
 FcbClose:=$FF;
 FcbSegOfs(P,S,O);
 T:=FcbSft(S,O);
 If T=$FFFF Then Exit;
 Mem[S:O+$19]:=0;
 SftRelease(T);
 FcbClose:=0;
End;

{ Entree de repertoire de la recherche courante -> DTA au format FCB (lecteur +
  entree de 32 octets) }
Procedure FcbFill(Var T:DTAStruct;Drive:Byte);
Var D:Word;
 DS_,DO_:Word;
 I,K:Byte;
 N:Array[0..10] of Byte;
Begin
 DS_:=GetDTASeg;
 DO_:=GetDTAOfs;
 For I:=0 To 10 Do N[I]:=32;
 K:=0;
 I:=0;
 While (T.Name[I]<>#0) And (T.Name[I]<>'.') And (K<8) Do Begin
  N[K]:=Ord(T.Name[I]);
  Inc(K);
  Inc(I);
 End;
 While (T.Name[I]<>#0) And (T.Name[I]<>'.') Do Inc(I);
 If T.Name[I]='.' Then Begin
  Inc(I);
  K:=8;
  While (T.Name[I]<>#0) And (K<11) Do Begin
   N[K]:=Ord(T.Name[I]);
   Inc(K);
   Inc(I);
  End;
 End;
 For I:=0 To 32 Do Mem[DS_:DO_+I]:=0;
 Mem[DS_:DO_]:=Drive;
 For I:=0 To 10 Do Mem[DS_:DO_+1+I]:=N[I];
 Mem[DS_:DO_+12]:=T.Attribute;
 MemW[DS_:DO_+23]:=T.Time;
 MemW[DS_:DO_+25]:=T.Date;
 MemW[DS_:DO_+29]:=Word(T.Size);
 MemW[DS_:DO_+31]:=Word(T.Size Shr 16);
End;

Function FcbFindFirst(P:Pointer):Byte;
Var S,O:Word;
 Path:String;
 T:DTAStruct;
 Attr:Byte;
 Dr,K:Byte;
Begin
 FcbFindFirst:=$FF;
 FcbSegOfs(P,S,O);
 BufParts(P,S,O);
 Attr:=0;
 Dr:=Mem[S:O];
 If Mem[S:O]=$FF Then Begin
  Attr:=Mem[S:O+6];
  Inc(O,7);
  Dr:=Mem[S:O];
 End;
 If Dr=0 Then Dr:=GetCurrentDrive+1;
 If Not FcbName(S,O,$101,Path) Then Path:='*.*';
 If DOS4Eh_FindFirstFile(Path,Attr,T)<>0 Then Exit;
 For K:=0 To 18 Do Mem[S:O+12+K]:=T.Reserved[K];
 FcbFill(T,Dr);
 FcbFindFirst:=0;
End;

Function FcbFindNext(P:Pointer):Byte;
Var S,O:Word;
 T:DTAStruct;
 Dr,K:Byte;
Begin
 FcbFindNext:=$FF;
 FcbSegOfs(P,S,O);
 Dr:=Mem[S:O];
 If Dr=0 Then Dr:=GetCurrentDrive+1;
 FillChar(T,SizeOf(T),0);
 For K:=0 To 18 Do T.Reserved[K]:=Mem[S:O+12+K];
 If DOS4Fh_FindNextFile(T)<>0 Then Exit;
 For K:=0 To 18 Do Mem[S:O+12+K]:=T.Reserved[K];
 FcbFill(T,Dr);
 FcbFindNext:=0;
End;

{ Compare Nm (11 caracteres, '?' = joker) avec une entree de 11 caracteres }
Function FcbNewName(Var Old,Pat:TFcbNm;Var Res:String):Boolean;
Var I:Byte;
 C:Byte;
Begin
 Res:='';
 For I:=0 To 10 Do Begin
  If Pat[I]=Ord('?') Then C:=Old[I] Else C:=Pat[I];
  If I=8 Then Res:=Res+'.';
  If C<>32 Then Res:=Res+Chr(C)
  Else If I<8 Then Begin
   { espace dans le nom : fin du nom }
  End;
 End;
 FcbNewName:=Length(Res)>0;
End;

Function FcbDelete(P:Pointer):Byte;
Var S,O:Word;
 Path,Nm:String;
 T:DTAStruct;
 Z:TFcbZ;
 Any:Boolean;
 R:Word;
Begin
 FcbDelete:=$FF;
 FcbSegOfs(P,S,O);
 If Not FcbName(S,O,$101,Path) Then Exit;
 Any:=False;
 R:=DOS4Eh_FindFirstFile(Path,0,T);
 While R=0 Do Begin
  Nm:='';
  If Mem[S:O]<>0 Then Begin
   Nm:='A:';
   Nm[1]:=Chr(64+Mem[S:O]);
  End;
  R:=0;
  While T.Name[R]<>#0 Do Begin
   Nm:=Nm+T.Name[R];
   Inc(R);
  End;
  PathToZ(Nm,Z);
  If DOS41h_DeleteFile(@Z)=0 Then Any:=True;
  R:=DOS4Fh_FindNextFile(T);
 End;
 If Any Then FcbDelete:=0;
End;

Function FcbRename(P:Pointer):Byte;
Var S,O:Word;
 Path,Nm,Res:String;
 T:DTAStruct;
 Z,Z2:TFcbZ;
 Any:Boolean;
 R,I:Word;
 Old,Pat:TFcbNm;
 Pre:String;
 DS_,DO_:Word;
Begin
 FcbRename:=$FF;
 FcbSegOfs(P,S,O);
 If Not FcbName(S,O,$101,Path) Then Exit;
 For I:=0 To 10 Do Pat[I]:=Mem[S:O+$11+I];
 Pre:='';
 If Mem[S:O]<>0 Then Begin
  Pre:='A:';
  Pre[1]:=Chr(64+Mem[S:O]);
 End;
 Any:=False;
 DS_:=GetDTASeg;
 DO_:=GetDTAOfs;
 R:=DOS4Eh_FindFirstFile(Path,0,T);
 While R=0 Do Begin
  Nm:=Pre;
  R:=0;
  While T.Name[R]<>#0 Do Begin
   Nm:=Nm+T.Name[R];
   Inc(R);
  End;
  FcbFill(T,0);
  For I:=0 To 10 Do Old[I]:=Mem[DS_:DO_+1+I];
  If FcbNewName(Old,Pat,Res) Then Begin
   Res:=Pre+Res;
   PathToZ(Nm,Z);
   PathToZ(Res,Z2);
   If FxRename(@Z,@Z2)=0 Then Any:=True;
  End;
  R:=DOS4Fh_FindNextFile(T);
 End;
 If Any Then FcbRename:=0;
End;

{ Position du prochain enregistrement sequentiel / aleatoire }
Function FcbSeqPos(S,O:Word):LongInt;
Begin
 FcbSeqPos:=(LongInt(MemW[S:O+$0C])*128+Mem[S:O+$20])*FcbRecSize(S,O);
End;

Function FcbRandRec(S,O:Word):LongInt;
Var R:LongInt;
Begin
 R:=LongInt(MemW[S:O+$21])+LongInt(MemW[S:O+$23])*65536;
 If FcbRecSize(S,O)>=64 Then R:=R And $00FFFFFF;
 FcbRandRec:=R;
End;

Procedure FcbSetBlockRec(S,O:Word;R:LongInt);
Begin
 MemW[S:O+$0C]:=Word(R Div 128);
 Mem[S:O+$20]:=Byte(R Mod 128);
End;

Procedure FcbStoreRand(S,O:Word;R:LongInt);
Begin
 MemW[S:O+$21]:=Word(R);
 MemW[S:O+$23]:=Word(R Shr 16);
End;

{ Lit un enregistrement a la position Pos dans la DTA : 0 ok, 1 fin de fichier,
  3 enregistrement partiel }
Function FcbReadRec(S,O,T:Word;Pos:LongInt;DO_:Word):Byte;
Var Rs,Got,I,DS_:Word;
Begin
 Rs:=FcbRecSize(S,O);
 DS_:=GetDTASeg;
 DOS42h_SeekFile(T,Word(Pos Shr 16),Word(Pos),0);
 Got:=0;
 DOS3Fh_ReadFile(T,Ptr(DS_,DO_),Rs,Got);
 If Got=0 Then Begin
  FcbReadRec:=1;
  Exit;
 End;
 If Got<Rs Then Begin
  For I:=Got To Rs-1 Do Mem[DS_:DO_+I]:=0;
  FcbReadRec:=3;
  Exit;
 End;
 FcbReadRec:=0;
End;

Function FcbWriteRec(S,O,T:Word;Pos:LongInt):Byte;
Var Rs,Wr:Word;
 Sz:LongInt;
Begin
 Rs:=FcbRecSize(S,O);
 DOS42h_SeekFile(T,Word(Pos Shr 16),Word(Pos),0);
 Wr:=0;
 DOS40h_WriteFile(T,Ptr(GetDTASeg,GetDTAOfs),Rs,Wr);
 If Wr<>Rs Then Begin
  FcbWriteRec:=1;
  Exit;
 End;
 Sz:=GetFileTableFileSize(T);
 MemW[S:O+$10]:=Word(Sz);
 MemW[S:O+$12]:=Word(Sz Shr 16);
 FcbWriteRec:=0;
End;

Function FcbSeqRead(P:Pointer):Byte;
Var S,O,T:Word;
 R:Byte;
Begin
 FcbSeqRead:=1;
 FcbSegOfs(P,S,O);
 T:=FcbSft(S,O);
 If T=$FFFF Then Begin
  FcbSeqRead:=$FF;
  Exit;
 End;
 R:=FcbReadRec(S,O,T,FcbSeqPos(S,O),GetDTAOfs);
 If R<>1 Then Begin
  Mem[S:O+$20]:=Mem[S:O+$20]+1;
  If Mem[S:O+$20]>=128 Then Begin
   Mem[S:O+$20]:=0;
   MemW[S:O+$0C]:=MemW[S:O+$0C]+1;
  End;
 End;
 FcbSeqRead:=R;
End;

Function FcbSeqWrite(P:Pointer):Byte;
Var S,O,T:Word;
 R:Byte;
Begin
 FcbSegOfs(P,S,O);
 T:=FcbSft(S,O);
 If T=$FFFF Then Begin
  FcbSeqWrite:=$FF;
  Exit;
 End;
 R:=FcbWriteRec(S,O,T,FcbSeqPos(S,O));
 If R=0 Then Begin
  Mem[S:O+$20]:=Mem[S:O+$20]+1;
  If Mem[S:O+$20]>=128 Then Begin
   Mem[S:O+$20]:=0;
   MemW[S:O+$0C]:=MemW[S:O+$0C]+1;
  End;
 End;
 FcbSeqWrite:=R;
End;

Function FcbRandRead(P:Pointer):Byte;
Var S,O,T:Word;
 Rec:LongInt;
Begin
 FcbSegOfs(P,S,O);
 T:=FcbSft(S,O);
 If T=$FFFF Then Begin
  FcbRandRead:=$FF;
  Exit;
 End;
 Rec:=FcbRandRec(S,O);
 FcbSetBlockRec(S,O,Rec);
 FcbRandRead:=FcbReadRec(S,O,T,Rec*FcbRecSize(S,O),GetDTAOfs);
End;

Function FcbRandWrite(P:Pointer):Byte;
Var S,O,T:Word;
 Rec:LongInt;
Begin
 FcbSegOfs(P,S,O);
 T:=FcbSft(S,O);
 If T=$FFFF Then Begin
  FcbRandWrite:=$FF;
  Exit;
 End;
 Rec:=FcbRandRec(S,O);
 FcbSetBlockRec(S,O,Rec);
 FcbRandWrite:=FcbWriteRec(S,O,T,Rec*FcbRecSize(S,O));
End;

{ 27h / 28h : Count enregistrements a partir de l'enregistrement aleatoire ;
  Done = nombre traite }
Function FcbBlockRead(P:Pointer;Count:Word;Var Done:Word):Byte;
Var S,O,T,I,Rs,DO_:Word;
 Rec:LongInt;
 R:Byte;
Begin
 Done:=0;
 FcbSegOfs(P,S,O);
 T:=FcbSft(S,O);
 If T=$FFFF Then Begin
  FcbBlockRead:=$FF;
  Exit;
 End;
 Rec:=FcbRandRec(S,O);
 Rs:=FcbRecSize(S,O);
 DO_:=GetDTAOfs;
 R:=0;
 I:=0;
 While I<Count Do Begin
  R:=FcbReadRec(S,O,T,Rec*Rs,DO_+I*Rs);
  If R=1 Then Break;
  Inc(Done);
  Inc(Rec);
  Inc(I);
  If R=3 Then Break;
 End;
 FcbSetBlockRec(S,O,Rec);
 FcbStoreRand(S,O,Rec);
 If (R=1) And (Done>0) Then R:=3;
 FcbBlockRead:=R;
End;

Function FcbBlockWrite(P:Pointer;Count:Word;Var Done:Word):Byte;
Var S,O,T,I,Rs,Wr:Word;
 Rec:LongInt;
 Sz:LongInt;
Begin
 Done:=0;
 FcbBlockWrite:=$FF;
 FcbSegOfs(P,S,O);
 T:=FcbSft(S,O);
 If T=$FFFF Then Exit;
 Rec:=FcbRandRec(S,O);
 Rs:=FcbRecSize(S,O);
 FcbBlockWrite:=0;
 For I:=0 To Count-1 Do Begin
  DOS42h_SeekFile(T,Word((Rec*Rs) Shr 16),Word(Rec*Rs),0);
  Wr:=0;
  DOS40h_WriteFile(T,Ptr(GetDTASeg,GetDTAOfs+I*Rs),Rs,Wr);
  If Wr<>Rs Then Begin
   FcbBlockWrite:=1;
   Break;
  End;
  Inc(Done);
  Inc(Rec);
 End;
 Sz:=GetFileTableFileSize(T);
 MemW[S:O+$10]:=Word(Sz);
 MemW[S:O+$12]:=Word(Sz Shr 16);
 FcbSetBlockRec(S,O,Rec);
 FcbStoreRand(S,O,Rec);
End;

{ 23h : taille du fichier (en enregistrements) dans le champ d'enregistrement
  aleatoire }
Function FcbFileSize(P:Pointer):Byte;
Var S,O:Word;
 Path:String;
 T:DTAStruct;
 Rs:Word;
 N:LongInt;
Begin
 FcbFileSize:=$FF;
 FcbSegOfs(P,S,O);
 If Not FcbName(S,O,$101,Path) Then Exit;
 If DOS4Eh_FindFirstFile(Path,0,T)<>0 Then Exit;
 Rs:=FcbRecSize(S,O);
 N:=(T.Size+Rs-1) Div Rs;
 FcbStoreRand(S,O,N);
 FcbFileSize:=0;
End;

{ 24h : champ d'enregistrement aleatoire = bloc courant / enregistrement courant
  }
Function FcbSetRandom(P:Pointer):Byte;
Var S,O:Word;
Begin
 FcbSegOfs(P,S,O);
 FcbStoreRand(S,O,LongInt(MemW[S:O+$0C])*128+Mem[S:O+$20]);
 FcbSetRandom:=0;
End;

{ 29h : analyse d'un nom de fichier (chaine en StrPtr) dans le FCB Fcb ;
  NewOfs = offset apres l'analyse }
Function FcbIsSep(C:Byte):Boolean;
Begin
 FcbIsSep:=(C<=32) Or InList(C,'.:;,=+/"[]<>|\');
End;

Function FcbParse(StrPtr:Pointer;Fcb:Pointer;Flags:Word;Var NewOfs:Word):Byte;
Var SS_,SO,FS,FO,I:Word;
 C:Byte;
 Wild:Boolean;
 Star:Boolean;
Begin
 BufParts(StrPtr,SS_,SO);
 BufParts(Fcb,FS,FO);
 Wild:=False;
 C:=Mem[SS_:SO];
 While (C=32) Or (C=9) Do Begin Inc(SO); C:=Mem[SS_:SO]; End;
 If (Flags And 1)<>0 Then
  While (C=Ord(';')) Or (C=Ord(',')) Or (C=Ord('=')) Do Begin Inc(SO);
    C:=Mem[SS_:SO]; End;
 { lecteur }
 If (Flags And 2)=0 Then Mem[FS:FO]:=0;
 If (Mem[SS_:SO+1]=Ord(':')) And (((C>=65) And (C<=90)) Or ((C>=97) And
   (C<=122))) Then Begin
  If C>=97 Then C:=C-32;
  Mem[FS:FO]:=C-64;
  Inc(SO,2);
  C:=Mem[SS_:SO];
 End;
 { nom }
 If (Flags And 4)=0 Then For I:=1 To 8 Do Mem[FS:FO+I]:=32;
 I:=1;
 Star:=False;
 If Not FcbIsSep(C) Or (C=Ord('*')) Or (C=Ord('?')) Then
  While Not FcbIsSep(C) Do Begin
   If I<=8 Then Begin
    If C=Ord('*') Then Begin
     Wild:=True;
     While I<=8 Do Begin Mem[FS:FO+I]:=Ord('?'); Inc(I); End;
    End Else Begin
     If C=Ord('?') Then Wild:=True;
     If (C>=97) And (C<=122) Then C:=C-32;
     Mem[FS:FO+I]:=C;
     Inc(I);
    End;
   End;
   Inc(SO);
   C:=Mem[SS_:SO];
  End;
 { extension }
 If (Flags And 8)=0 Then For I:=9 To 11 Do Mem[FS:FO+I]:=32;
 If C=Ord('.') Then Begin
  Inc(SO);
  C:=Mem[SS_:SO];
  I:=9;
  While Not FcbIsSep(C) Do Begin
   If I<=11 Then Begin
    If C=Ord('*') Then Begin
     Wild:=True;
     While I<=11 Do Begin Mem[FS:FO+I]:=Ord('?'); Inc(I); End;
    End Else Begin
     If C=Ord('?') Then Wild:=True;
     If (C>=97) And (C<=122) Then C:=C-32;
     Mem[FS:FO+I]:=C;
     Inc(I);
    End;
   End;
   Inc(SO);
   C:=Mem[SS_:SO];
  End;
 End;
 NewOfs:=SO;
 If Wild Then FcbParse:=1 Else FcbParse:=0;
End;

{ Lire des données depuis un cluster spécifique }
Function ReadFromCluster(Drive:Byte;BootSec:BootSectorRec;Cluster:Word;
  Offset:Word;Buffer:Pointer;BytesToRead:Word):Word;
Var
 FirstDataSector: LongInt;
 ClusterSector: LongInt;
 SectorInCluster: Word;
 ByteInSector: Word;
 SectorBuffer: Array[0..511] of Byte;
 BytesThisRead: Word;
 BytesRemaining: Word;
 BufferOfs: Word;
 BufferSeg: Word;
 I: Word;
Begin
 ReadFromCluster:=0; { Succès par défaut }

 { Calculer le premier secteur de données }
 FirstDataSector:=BootSec.ReservedSectors + (BootSec.NumberOfFATs *
   BootSec.SectorsPerFAT) +
                  ((BootSec.RootDirEntries * 32) div BootSec.BytesPerSector);

 { Calculer le secteur du cluster }
 ClusterSector:=FirstDataSector + (LongInt(Cluster - 2) *
   BootSec.SectorsPerCluster);

 BytesRemaining:=BytesToRead;

 { Extraire segment et offset du pointeur }
 ASM
  LES DI,Buffer
  MOV BufferSeg,ES
  MOV BufferOfs,DI
 END;

 While BytesRemaining > 0 Do Begin
  { Calculer secteur et offset dans le secteur }
  SectorInCluster:=Offset div BootSec.BytesPerSector;
  ByteInSector:=Offset mod BootSec.BytesPerSector;

  { Lire le secteur }
  If Not ReadSector(Drive, ClusterSector + SectorInCluster,
    @SectorBuffer) Then Begin
   ReadFromCluster:=5; { Access denied }
   Exit;
  End;

  { Calculer combien d'octets lire de ce secteur }
  BytesThisRead:=BootSec.BytesPerSector - ByteInSector;
  If BytesThisRead > BytesRemaining Then
   BytesThisRead:=BytesRemaining;

  { Copier les données }
  ASM
   PUSH DS
   PUSH SI
   PUSH ES
   PUSH DI

   MOV AX,BufferSeg
   MOV ES,AX
   MOV DI,BufferOfs

   LEA SI,SectorBuffer
   ADD SI,ByteInSector
   PUSH SS
   POP DS

   MOV CX,BytesThisRead
   CLD
   REP MOVSB

   POP DI
   POP ES
   POP SI
   POP DS
  END;

  { Mettre à jour les compteurs }
  Dec(BytesRemaining, BytesThisRead);
  Inc(Offset, BytesThisRead);
  Inc(BufferOfs, BytesThisRead);

  { Gérer le débordement de segment }
  If BufferOfs >= $10000 Then Begin
   Inc(BufferSeg, $1000);
   Dec(BufferOfs, $10000);
  End;

  { Si on a dépassé la taille du cluster, sortir }
  If Offset >= (BootSec.SectorsPerCluster * BootSec.BytesPerSector) Then
   Break;
 End;

 ReadFromCluster:=0; { Succès }
End;

{ Obtenir le cluster suivant dans la chaîne FAT }
Function GetNextCluster(Drive:Byte;BootSec:BootSectorRec;
  CurrentCluster:Word):Word;
Var
 V:TFxVol;
Begin
 { FxGet gere FAT12 (entrees a cheval sur deux secteurs) et FAT16 }
 GetNextCluster:=$FFFF;
 If CurrentCluster < 2 Then Exit;
 If Not FxVol(Drive,V) Then Exit;
 GetNextCluster:=FxGet(V,CurrentCluster);
End;

{ Lire les données d'un fichier }
Function ReadFileData(Handle:Word;Buffer:Pointer;BytesToRead:Word;
  Var BytesRead:Word):Word;
Var
 FileEntry: FileTableEntry;
 Drive: Byte;
 BootSec: BootSectorRec;
 CurrentCluster: Word;
 ClusterSize: Word;
 RemainingInCluster: Word;
 BytesToReadNow: Word;
 BufferOfs: Word;
 BufferSeg: Word;
 TotalBytesRead: Word;
 Result: Word;
Begin
 ReadFileData:=6; { Invalid handle par défaut }
 BytesRead:=0;

 { Vérifier la validité du handle }
 If Handle >= 20 Then Exit;

 If Not GetFileTableEntry(Handle, FileEntry) Then Exit;

 { Vérifier si le handle est utilisé }
 If Not FileEntry.InUse Then Exit;

 Drive:=FileEntry.Drive; { index 0-based, tel que stocké }
{$IFDEF KDEBUG}DbgW('D',FileEntry.Drive);DbgW('A',FileEntry.Attributes);
  DbgW('S',Word(FileEntry.FileSize));DbgW('P',Word(FileEntry.CurrentPos));
    DbgW('F',FileEntry.FirstCluster);{$ENDIF}

 { Lire boot sector }
 If Not ReadBootSector(Drive, BootSec) Then Begin
  ReadFileData:=5; { Access denied }
  Exit;
 End;

 { Vérifier si on peut lire (pas en mode écriture seule) }
 If (FileEntry.Attributes and $01) <> 0 Then Begin { Mode écriture seule }
  ReadFileData:=5; { Access denied }
  Exit;
 End;

 { Calculer combien on peut lire }
 If FileEntry.CurrentPos >= FileEntry.FileSize Then Begin
  ReadFileData:=0; { EOF - succès mais 0 octets lus }
  Exit;
 End;

 If FileEntry.CurrentPos + BytesToRead > FileEntry.FileSize Then
  BytesToRead:=FileEntry.FileSize - FileEntry.CurrentPos;

 TotalBytesRead:=0;

 { Extraire segment et offset du pointeur }
 ASM
  LES DI,Buffer
  MOV BufferSeg,ES
  MOV BufferOfs,DI
 END;

 CurrentCluster:=FileEntry.CurrentCluster;
 If CurrentCluster = 0 Then CurrentCluster:=FileEntry.FirstCluster;

 ClusterSize:=BootSec.SectorsPerCluster * BootSec.BytesPerSector;

 While (BytesToRead > 0) and (CurrentCluster <> $FFFF) and (CurrentCluster >= 2)
   Do Begin
  { Calculer combien on peut lire du cluster courant }
  RemainingInCluster:=ClusterSize - FileEntry.ClusterOffset;
  BytesToReadNow:=BytesToRead;
  If BytesToReadNow > RemainingInCluster Then
   BytesToReadNow:=RemainingInCluster;

  { Lire du cluster courant }
  Result:=ReadFromCluster(Drive, BootSec, CurrentCluster,
    FileEntry.ClusterOffset, Ptr(BufferSeg, BufferOfs), BytesToReadNow);
  If Result <> 0 Then Begin
   ReadFileData:=Result;
   Exit;
  End;

  { Mettre à jour les pointeurs et compteurs }
  Inc(BufferOfs, BytesToReadNow);

  { Gérer le débordement de segment }
  If BufferOfs >= $10000 Then Begin
   Inc(BufferSeg, $1000);
   Dec(BufferOfs, $10000);
  End;

  Inc(TotalBytesRead, BytesToReadNow);
  Dec(BytesToRead, BytesToReadNow);
  Inc(FileEntry.CurrentPos, BytesToReadNow);
  Inc(FileEntry.ClusterOffset, BytesToReadNow);

  { Si on a fini ce cluster, passer au suivant }
  If FileEntry.ClusterOffset >= ClusterSize Then Begin
   CurrentCluster:=GetNextCluster(Drive, BootSec, CurrentCluster);
   FileEntry.CurrentCluster:=CurrentCluster;
   FileEntry.ClusterOffset:=0;
  End;
 End;

 { Mettre à jour l'entrée de fichier }
 SetFileTableEntry(Handle, FileEntry);

 BytesRead:=TotalBytesRead;
 ReadFileData:=0; { Succès }
End;

{ Fonction principale 3Fh }
Function DOS3Fh_ReadFile(Handle:Word;Buffer:Pointer;BytesToRead:Word;
  Var BytesRead:Word):Word;
Begin
 DOS3Fh_ReadFile:=ReadFileData(Handle, Buffer, BytesToRead, BytesRead);
End;

{ Écrire des données vers un cluster spécifique }
Function WriteToCluster(Drive:Byte;BootSec:BootSectorRec;Cluster:Word;
  Offset:Word;Buffer:Pointer;BytesToWrite:Word):Word;
Var
 FirstDataSector: LongInt;
 ClusterSector: LongInt;
 SectorInCluster: Word;
 ByteInSector: Word;
 SectorBuffer: Array[0..511] of Byte;
 BytesThisWrite: Word;
 BytesRemaining: Word;
 BufferOfs: Word;
 BufferSeg: Word;
 I: Word;
Begin
 WriteToCluster:=0; { Succès par défaut }

 { Calculer le premier secteur de données }
 FirstDataSector:=BootSec.ReservedSectors + (BootSec.NumberOfFATs *
   BootSec.SectorsPerFAT) +
                  ((BootSec.RootDirEntries * 32) div BootSec.BytesPerSector);

 { Calculer le secteur du cluster }
 ClusterSector:=FirstDataSector + (LongInt(Cluster - 2) *
   BootSec.SectorsPerCluster);

 BytesRemaining:=BytesToWrite;

 { Extraire segment et offset du pointeur }
 ASM
  LES DI,Buffer
  MOV BufferSeg,ES
  MOV BufferOfs,DI
 END;

 While BytesRemaining > 0 Do Begin
  { Calculer secteur et offset dans le secteur }
  SectorInCluster:=Offset div BootSec.BytesPerSector;
  ByteInSector:=Offset mod BootSec.BytesPerSector;

  { Si on n'écrit pas tout le secteur, il faut d'abord le lire }
  If (ByteInSector <> 0) or (BytesRemaining < BootSec.BytesPerSector) Then Begin
   If Not ReadSector(Drive, ClusterSector + SectorInCluster,
     @SectorBuffer) Then Begin
    WriteToCluster:=5; { Access denied }
    Exit;
   End;
  End;

  { Calculer combien d'octets écrire dans ce secteur }
  BytesThisWrite:=BootSec.BytesPerSector - ByteInSector;
  If BytesThisWrite > BytesRemaining Then
   BytesThisWrite:=BytesRemaining;

  { Copier les données du buffer vers le secteur }
  ASM
   PUSH DS
   PUSH SI
   PUSH ES
   PUSH DI

   MOV AX,BufferSeg
   MOV DS,AX
   MOV SI,BufferOfs

   LEA DI,SectorBuffer
   ADD DI,ByteInSector
   PUSH SS
   POP ES

   MOV CX,BytesThisWrite
   CLD
   REP MOVSB

   POP DI
   POP ES
   POP SI
   POP DS
  END;

  { Écrire le secteur }
  If Not WriteSector(Drive, ClusterSector + SectorInCluster,
    @SectorBuffer) Then Begin
   WriteToCluster:=5; { Access denied }
   Exit;
  End;

  { Mettre à jour les compteurs }
  Dec(BytesRemaining, BytesThisWrite);
  Inc(Offset, BytesThisWrite);
  Inc(BufferOfs, BytesThisWrite);

  { Gérer le débordement de segment }
  If BufferOfs >= $10000 Then Begin
   Inc(BufferSeg, $1000);
   Dec(BufferOfs, $10000);
  End;

  { Si on a dépassé la taille du cluster, sortir }
  If Offset >= (BootSec.SectorsPerCluster * BootSec.BytesPerSector) Then
   Break;
 End;

 WriteToCluster:=0; { Succès }
End;

{ Mettre à jour une entrée dans la FAT }
Function UpdateFATEntry(Drive:Byte;BootSec:BootSectorRec;Cluster:Word;
  NextCluster:Word):Boolean;
Var
 FATSector: Word;
 FATOffset: Word;
 Buffer: Array[0..511] of Byte;
 I: Byte;
Begin
 UpdateFATEntry:=False;

 If BootSec.SectorsPerFAT = 0 Then Exit; { FAT32 non supportée }
 If Cluster < 2 Then Exit; { Cluster invalide }

 { Pour FAT12 }
 If BootSec.SectorsPerFAT <= 12 Then Begin
  FATOffset:=(Cluster * 3) div 2;
  FATSector:=BootSec.ReservedSectors + (FATOffset div BootSec.BytesPerSector);
  FATOffset:=FATOffset mod BootSec.BytesPerSector;

  If Not ReadSector(Drive, FATSector, @Buffer) Then Exit;

  If (Cluster mod 2) = 0 Then Begin
   Buffer[FATOffset]:=NextCluster and $FF;
   Buffer[FATOffset + 1]:=(Buffer[FATOffset + 1] and $F0) or ((NextCluster shr
     8) and $0F);
  End
  Else Begin
   Buffer[FATOffset]:=(Buffer[FATOffset] and $0F) or ((NextCluster and $0F) shl
     4);
   Buffer[FATOffset + 1]:=(NextCluster shr 4) and $FF;
  End;
 End
 Else Begin
  { Pour FAT16 }
  FATOffset:=Cluster * 2;
  FATSector:=BootSec.ReservedSectors + (FATOffset div BootSec.BytesPerSector);
  FATOffset:=FATOffset mod BootSec.BytesPerSector;

  If Not ReadSector(Drive, FATSector, @Buffer) Then Exit;

  Buffer[FATOffset]:=NextCluster and $FF;
  Buffer[FATOffset + 1]:=(NextCluster shr 8) and $FF;
 End;

 { Écrire dans toutes les copies de la FAT }
 For I:=0 To BootSec.NumberOfFATs-1 Do Begin
  If Not WriteSector(Drive, FATSector + (I * BootSec.SectorsPerFAT),
    @Buffer) Then Exit;
 End;

 UpdateFATEntry:=True;
End;

{ Allouer un nouveau cluster et le chaîner au précédent }
Function AllocateNewCluster(Drive:Byte;BootSec:BootSectorRec;
  PreviousCluster:Word):Word;
Var
 NewCluster: Word;
 MaxCluster: Word;
Begin
 AllocateNewCluster:=0; { Erreur par défaut }

 { Déterminer le nombre maximum de clusters }
 If BootSec.SectorsPerFAT <= 12 Then
  MaxCluster:=$FF0 { FAT12 }
 Else
  MaxCluster:=$FFF0; { FAT16 }

 { Chercher un cluster libre }
 For NewCluster:=2 To MaxCluster Do Begin
  If GetNextCluster(Drive, BootSec, NewCluster) = 0 Then Begin
   { Cluster libre trouvé - le marquer comme utilisé }
   If UpdateFATEntry(Drive, BootSec, NewCluster, $FFFF) Then Begin
    { Si on a un cluster précédent, le chaîner }
    If PreviousCluster <> 0 Then Begin
     If UpdateFATEntry(Drive, BootSec, PreviousCluster, NewCluster) Then Begin
      AllocateNewCluster:=NewCluster;
      Exit;
     End;
    End
    Else Begin
     AllocateNewCluster:=NewCluster;
     Exit;
    End;
   End;
  End;
 End;
End;

{ Écrire les données d'un fichier }
Function WriteFileData(Handle:Word;Buffer:Pointer;BytesToWrite:Word;
  Var BytesWritten:Word):Word;
Begin
 WriteFileData:=FxWriteData(Handle,Buffer,BytesToWrite,BytesWritten);
End;
{ Fonction principale 40h }
Function DOS40h_WriteFile(Handle:Word;Buffer:Pointer;BytesToWrite:Word;
  Var BytesWritten:Word):Word;
Begin
 DOS40h_WriteFile:=WriteFileData(Handle, Buffer, BytesToWrite, BytesWritten);
End;

{ Supprimer une entrée de répertoire }
Function DeleteDirectoryEntry(Drive:Byte;BootSec:BootSectorRec;DirCluster:Word;
  FileName:String):Boolean;
Var
 Buffer: Array[0..511] of Byte;
 Entry: DirectoryEntry;
 EntryPtr: ^DirectoryEntry;
 FirstDataSector: LongInt;
 DirSector: LongInt;
 SectorsToRead: Word;
 I, J, K: Word;
 Found: Boolean;
 SearchName: String;
Begin
 DeleteDirectoryEntry:=False;

 { Préparer le nom de recherche (8.3 avec espaces) }
 SearchName:=FileName;
 While Length(SearchName) < 11 Do SearchName:=SearchName + ' ';

 { Calculer le secteur de début du répertoire }
 If DirCluster = 0 Then Begin
  { Répertoire racine }
  FirstDataSector:=BootSec.ReservedSectors + (BootSec.NumberOfFATs *
    BootSec.SectorsPerFAT);
  DirSector:=FirstDataSector;
  SectorsToRead:=(BootSec.RootDirEntries * 32) div BootSec.BytesPerSector;
 End
 Else Begin
  { Sous-répertoire }
  FirstDataSector:=BootSec.ReservedSectors + (BootSec.NumberOfFATs *
    BootSec.SectorsPerFAT) +
                   ((BootSec.RootDirEntries * 32) div BootSec.BytesPerSector);
  DirSector:=FirstDataSector + (LongInt(DirCluster - 2) *
    BootSec.SectorsPerCluster);
  SectorsToRead:=BootSec.SectorsPerCluster;
 End;

 { Parcourir les secteurs du répertoire }
 For I:=0 To SectorsToRead-1 Do Begin
  If Not ReadSector(Drive, DirSector + I, @Buffer) Then Exit;

  EntryPtr:=@Buffer;
  For J:=0 To (BootSec.BytesPerSector div 32)-1 Do Begin
   Move(EntryPtr^, Entry, 32);

   { Vérifier si c'est l'entrée recherchée }
   Found:=True;
   For K:=0 To 10 Do Begin
    If Entry.FileName[K] <> SearchName[K+1] Then Begin
     Found:=False;
     Break;
    End;
   End;

   If Found and (Entry.FileName[0] <> #0) and (Entry.FileName[0] <> #$E5) Then
     Begin
    { Entrée trouvée - la marquer comme supprimée }
    Entry.FileName[0]:=#$E5;

    { Libérer la chaîne de clusters }
    If Entry.FirstClusterLow > 0 Then Begin
     If Not FreeFATChain(Drive, BootSec, Entry.FirstClusterLow) Then Exit;
    End;

    { Réécrire l'entrée modifiée }
    Move(Entry, EntryPtr^, 32);
    If Not WriteSector(Drive, DirSector + I, @Buffer) Then Exit;

    DeleteDirectoryEntry:=True;
    Exit;
   End;

   Inc(LongInt(EntryPtr), 32);
  End;
 End;
End;

{ Fonction principale 41h }
Function DOS41h_DeleteFile(PathPtr:Pointer):Word;
Begin
 DOS41h_DeleteFile:=FxDelete(PathPtr);
End;
{ Calculer le cluster et l'offset à partir d'une position dans le fichier }
Function CalculateClusterFromPosition(Drive:Byte;BootSec:BootSectorRec;
                                      FirstCluster:Word;Position:LongInt;
                                      Var TargetCluster:Word;
                                      Var ClusterOffset:Word):Boolean;
Var
 ClusterSize: Word;
 ClustersToSkip: Word;
 CurrentCluster: Word;
 I: Word;
Begin
 CalculateClusterFromPosition:=False;

 If FirstCluster < 2 Then Exit; { Cluster invalide }

 ClusterSize:=BootSec.SectorsPerCluster * BootSec.BytesPerSector;

 { Calculer combien de clusters complets à ignorer }
 ClustersToSkip:=Position div ClusterSize;
 ClusterOffset:=Position mod ClusterSize;

 { Parcourir la chaîne de clusters }
 CurrentCluster:=FirstCluster;
 For I:=1 To ClustersToSkip Do Begin
  CurrentCluster:=GetNextCluster(Drive, BootSec, CurrentCluster);
  If (CurrentCluster = $FFFF) or (CurrentCluster < 2) Then Exit;
 End;

 TargetCluster:=CurrentCluster;
 CalculateClusterFromPosition:=True;
End;

{ Fonction principale 42h - Seek File }
Function DOS42h_SeekFile(Handle:Word;OffsetHi,OffsetLo:Word;
  Method:Byte):LongInt;
Var
 V:TFxVol;
 P,Q,Size:LongInt;
 First,Cur,Off,CSize,N:Word;
Begin
 DOS42h_SeekFile:=$FFFFFFFF;
 { peripheriques (CON, AUX, PRN...) : le positionnement reussit et rend 0,
   comme sous MS-DOS }
 If Handle<5 Then Begin
  DOS42h_SeekFile:=0;
  Exit;
 End;
 If (Handle>=20) Or Not GetFileTableInUse(Handle) Then Begin
  SetStandardError(6);
  Exit;
 End;
 Size:=GetFileTableFileSize(Handle);
 P:=(LongInt(OffsetHi) Shl 16) Or OffsetLo;
 Case Method Of
  0:;
  1:P:=P+GetFileTableCurrentPos(Handle);
  2:P:=P+Size;
  Else Begin
   SetStandardError(1);
   Exit;
  End;
 End;
 If P<0 Then Begin
  SetStandardError(131);
  Exit;
 End;
 First:=GetFileTableFirstCluster(Handle);
 Cur:=First;
 Off:=0;
 If First>=2 Then Begin
  If Not FxVol(GetFileTableDrive(Handle),V) Then Begin
   SetStandardError(5);
   Exit;
  End;
  CSize:=V.SPC*512;
  { cluster qui contient la position (au plus la fin du fichier ; plus loin,
    un trou sera comble a l'ecriture) }
  Q:=P;
  If Q>Size Then Q:=Size;
  N:=Word(Q Div CSize);
  Off:=Word(Q Mod CSize);
  If (Off=0) And (N>0) Then Begin
   Dec(N);
   Off:=CSize;
  End;
  While N>0 Do Begin
   Cur:=FxGet(V,Cur);
   If (Cur<2) Or (Cur=$FFFF) Then Begin
    SetStandardError(5);
    Exit;
   End;
   Dec(N);
  End;
 End;
 SetFileTableCurrentCluster(Handle,Cur);
 SetFileTableClusterOffset(Handle,Off);
 SetFileTableCurrentPos(Handle,P);
 DOS42h_SeekFile:=P;
End;

{ Obtenir les attributs d'un fichier }
Function GetFileAttributes(Drive:Byte;BootSec:BootSectorRec;DirCluster:Word;
  FileName:String;Var Attributes:Byte):Boolean;
Var
 Buffer: Array[0..511] of Byte;
 Entry: DirectoryEntry;
 EntryPtr: ^DirectoryEntry;
 FirstDataSector: LongInt;
 DirSector: LongInt;
 SectorsToRead: Word;
 I, J, K: Word;
 Found: Boolean;
 SearchName: String;
Begin
 GetFileAttributes:=False;
 Attributes:=0;

 { Préparer le nom de recherche (8.3 avec espaces) }
 SearchName:=FileName;
 While Length(SearchName) < 11 Do SearchName:=SearchName + ' ';

 { Calculer le secteur de début du répertoire }
 If DirCluster = 0 Then Begin
  { Répertoire racine }
  FirstDataSector:=BootSec.ReservedSectors + (BootSec.NumberOfFATs *
    BootSec.SectorsPerFAT);
  DirSector:=FirstDataSector;
  SectorsToRead:=(BootSec.RootDirEntries * 32) div BootSec.BytesPerSector;
 End
 Else Begin
  { Sous-répertoire }
  FirstDataSector:=BootSec.ReservedSectors + (BootSec.NumberOfFATs *
    BootSec.SectorsPerFAT) +
                   ((BootSec.RootDirEntries * 32) div BootSec.BytesPerSector);
  DirSector:=FirstDataSector + (LongInt(DirCluster - 2) *
    BootSec.SectorsPerCluster);
  SectorsToRead:=BootSec.SectorsPerCluster;
 End;

 { Parcourir les secteurs du répertoire }
 For I:=0 To SectorsToRead-1 Do Begin
  If Not ReadSector(Drive, DirSector + I, @Buffer) Then Exit;

  EntryPtr:=@Buffer;
  For J:=0 To (BootSec.BytesPerSector div 32)-1 Do Begin
   Move(EntryPtr^, Entry, 32);

   { Vérifier si c'est l'entrée recherchée }
   Found:=True;
   For K:=0 To 10 Do Begin
    If Entry.FileName[K] <> SearchName[K+1] Then Begin
     Found:=False;
     Break;
    End;
   End;

   If Found and (Entry.FileName[0] <> #0) and (Entry.FileName[0] <> #$E5) Then
     Begin
    { Entrée trouvée - retourner les attributs }
    Attributes:=Entry.Attributes;
    GetFileAttributes:=True;
    Exit;
   End;

   Inc(LongInt(EntryPtr), 32);
  End;
 End;
End;

{ Définir les attributs d'un fichier }
Function SetFileAttributes(Drive:Byte;BootSec:BootSectorRec;DirCluster:Word;
  FileName:String;NewAttributes:Byte):Boolean;
Var
 Buffer: Array[0..511] of Byte;
 Entry: DirectoryEntry;
 EntryPtr: ^DirectoryEntry;
 FirstDataSector: LongInt;
 DirSector: LongInt;
 SectorsToRead: Word;
 I, J, K: Word;
 Found: Boolean;
 SearchName: String;
Begin
 SetFileAttributes:=False;

 { Préparer le nom de recherche (8.3 avec espaces) }
 SearchName:=FileName;
 While Length(SearchName) < 11 Do SearchName:=SearchName + ' ';

 { Ne pas permettre de changer certains attributs critiques }
 NewAttributes:=NewAttributes and $37; { Masquer les bits réservés }

 { Calculer le secteur de début du répertoire }
 If DirCluster = 0 Then Begin
  { Répertoire racine }
  FirstDataSector:=BootSec.ReservedSectors + (BootSec.NumberOfFATs *
    BootSec.SectorsPerFAT);
  DirSector:=FirstDataSector;
  SectorsToRead:=(BootSec.RootDirEntries * 32) div BootSec.BytesPerSector;
 End
 Else Begin
  { Sous-répertoire }
  FirstDataSector:=BootSec.ReservedSectors + (BootSec.NumberOfFATs *
    BootSec.SectorsPerFAT) +
                   ((BootSec.RootDirEntries * 32) div BootSec.BytesPerSector);
  DirSector:=FirstDataSector + (LongInt(DirCluster - 2) *
    BootSec.SectorsPerCluster);
  SectorsToRead:=BootSec.SectorsPerCluster;
 End;

 { Parcourir les secteurs du répertoire }
 For I:=0 To SectorsToRead-1 Do Begin
  If Not ReadSector(Drive, DirSector + I, @Buffer) Then Exit;

  EntryPtr:=@Buffer;
  For J:=0 To (BootSec.BytesPerSector div 32)-1 Do Begin
   Move(EntryPtr^, Entry, 32);

   { Vérifier si c'est l'entrée recherchée }
   Found:=True;
   For K:=0 To 10 Do Begin
    If Entry.FileName[K] <> SearchName[K+1] Then Begin
     Found:=False;
     Break;
    End;
   End;

   If Found and (Entry.FileName[0] <> #0) and (Entry.FileName[0] <> #$E5) Then
     Begin
    { Entrée trouvée - modifier les attributs }
    Entry.Attributes:=NewAttributes;

    { Réécrire l'entrée modifiée }
    Move(Entry, EntryPtr^, 32);
    If Not WriteSector(Drive, DirSector + I, @Buffer) Then Exit;

    SetFileAttributes:=True;
    Exit;
   End;

   Inc(LongInt(EntryPtr), 32);
  End;
 End;
End;

{ Fonction principale 43h }
Function DOS43h_GetSetFileAttributes(PathPtr:Pointer;Action:Byte;
  NewAttributes:Byte):Word;
Var
 V:TFxVol;
 Dir:Word;
 Nm:String;
 Sec,FS:LongInt;
 Idx:Byte;
 FI:Integer;
 E:TFxEnt;
 Buf:TFxSec;
 P:Word;
 Root:Boolean;
 K:Byte;
Begin
 DOS43h_GetSetFileAttributes:=$FFFF;
 If Action>1 Then Begin
  SetStandardError(1);
  Exit;
 End;
 If Not FxOpenPath(PathPtr,V,Dir,Nm) Then Begin
  SetStandardError(3);
  Exit;
 End;
 Root:=True;
 For K:=1 To 11 Do
  If Nm[K]<>' ' Then Root:=False;
 If Root Then Begin
  { la racine (ou un chemin terminé par \) : repertoire }
  If Action=0 Then DOS43h_GetSetFileAttributes:=$10
  Else SetStandardError(5);
  Exit;
 End;
 If Not FxScan(V,Dir,Nm,Sec,Idx,FS,FI,E) Then Begin
  SetStandardError(2);
  Exit;
 End;
 If Action=0 Then Begin
  DOS43h_GetSetFileAttributes:=E.Attr;
  Exit;
 End;
 If Not ReadSector(V.Drive,Sec,@Buf) Then Begin
  SetStandardError(5);
  Exit;
 End;
 P:=Idx*32;
 Buf[P+11]:=(Buf[P+11] And $D8) Or (NewAttributes And $27);
 If Not WriteSector(V.Drive,Sec,@Buf) Then Begin
  SetStandardError(5);
  Exit;
 End;
 DOS43h_GetSetFileAttributes:=0;
End;

{ Obtenir les informations d'un périphérique (sous-fonction 00h) }
Function IOCTL_GetDeviceInfo(Handle:Word):Word;
Var
 FileEntry: FileTableEntry;
 DeviceInfo: Word;
Begin
 IOCTL_GetDeviceInfo:=$FFFF; { Erreur par défaut }

 { Vérifier la validité du handle }
 If Handle >= 20 Then Exit;

 If Not GetFileTableEntry(Handle, FileEntry) Then Exit;

 { Vérifier si le handle est utilisé }
 If Not FileEntry.InUse Then Exit;

 { Construire les informations du périphérique }
 DeviceInfo:=0;

 { Handle 0-4 sont les périphériques standard }
 Case Handle Of
  0: DeviceInfo:=$80D3; { STDIN - caractère, pas EOF, standard input }
  1: DeviceInfo:=$80D2; { STDOUT - caractère, standard output }
  2: DeviceInfo:=$80D2; { STDERR - caractère, standard error }
  3: DeviceInfo:=$80C0; { STDAUX - caractère, null device }
  4: DeviceInfo:=$80A0; { STDPRN - caractère, printer }
  Else Begin
   { Fichier normal - informations basées sur le lecteur }
   DeviceInfo:=FileEntry.Drive; { Numéro de lecteur (0=A:, 1=B:, etc.) }
   { Pas de flags spéciaux pour les fichiers normaux }
  End;
 End;

 IOCTL_GetDeviceInfo:=DeviceInfo;
End;

{ Définir les informations d'un périphérique (sous-fonction 01h) }
Function IOCTL_SetDeviceInfo(Handle:Word;DeviceInfo:Word):Word;
Var
 FileEntry: FileTableEntry;
Begin
 IOCTL_SetDeviceInfo:=1; { Invalid function par défaut }

 { Vérifier la validité du handle }
 If Handle >= 20 Then Exit;

 If Not GetFileTableEntry(Handle, FileEntry) Then Exit;

 { Vérifier si le handle est utilisé }
 If Not FileEntry.InUse Then Exit;

 { Les handles 0-4 sont en lecture seule pour les informations }
 If Handle <= 4 Then Exit;

 { Pour les fichiers normaux, on ne peut pas changer les infos de périphérique }
 { Cette fonction est principalement pour les drivers de périphériques }

 IOCTL_SetDeviceInfo:=0; { Succès simulé }
End;

{ Obtenir les informations d'un lecteur (sous-fonction 08h) }
Function IOCTL_GetDriveInfo(Drive:Byte):Word;
Var
 BootSec: BootSectorRec;
 DriveInfo: Word;
Begin
 IOCTL_GetDriveInfo:=$FFFF; { Erreur par défaut }

 { Vérifier que le lecteur est valide }
 If Drive>=NDrv Then Exit; { A: à Z: seulement }

 { Lire le boot sector pour vérifier que le lecteur existe }
 If Not ReadBootSector(Drive, BootSec) Then Exit;

 { Construire les informations du lecteur }
 DriveInfo:=0;

 { Bit 0: 0=amovible, 1=fixe }
 If Drive >= 2 Then { C: et plus sont considérés comme fixes }
  DriveInfo:=DriveInfo or $01;

 { Bits supplémentaires pour type de média et capacités }
 Case Drive Of
  0, 1: DriveInfo:=DriveInfo or $00; { A:, B: - disquettes amovibles }
  Else  DriveInfo:=DriveInfo or $01; { Disques durs fixes }
 End;

 IOCTL_GetDriveInfo:=DriveInfo;
End;

{ Définir les informations d'un lecteur (sous-fonction 09h) }
Function IOCTL_SetDriveInfo(Drive:Byte;DeviceInfo:Word):Word;
Begin
 IOCTL_SetDriveInfo:=1; { Invalid function }

 { Vérifier que le lecteur est valide }
 If Drive>=NDrv Then Exit;

 { Cette fonction n'est généralement pas implémentée }
 { Elle permettrait de changer les paramètres du lecteur }

 IOCTL_SetDriveInfo:=0; { Succès simulé }
End;

{ Lire les données de contrôle (sous-fonction 02h) }
Function IOCTL_ReadControlData(Handle:Word;Buffer:Pointer;
  BytesToRead:Word):Word;
Begin
 IOCTL_ReadControlData:=1; { Invalid function par défaut }

 { Cette fonction lit des données spéciales du périphérique }
 { Non implémentée dans cette version basique }

 IOCTL_ReadControlData:=0; { Pas de données lues }
End;

{ Écrire les données de contrôle (sous-fonction 03h) }
Function IOCTL_WriteControlData(Handle:Word;Buffer:Pointer;
  BytesToWrite:Word):Word;
Begin
 IOCTL_WriteControlData:=1; { Invalid function par défaut }

 { Cette fonction écrit des données spéciales vers le périphérique }
 { Non implémentée dans cette version basique }

 IOCTL_WriteControlData:=0; { Pas de données écrites }
End;

{ Fonction principale 44h - IOCTL }
Function DOS44h_IOCTL(Handle:Word;SubFunction:Byte;Buffer:Pointer;
  ByteCount:Word):Word;
Var
 Result: Word;
 Drive: Byte;
Begin
 DOS44h_IOCTL:=1; { Invalid function par défaut }

 { Dispatcher selon la sous-fonction }
 Case SubFunction Of
  $00: Begin { Get device information }
   Result:=IOCTL_GetDeviceInfo(Handle);
   If Result <> $FFFF Then Begin
    { Retourner l'information dans DX }
    ASM
     MOV AX,Result
     MOV DX,AX
    END;
    DOS44h_IOCTL:=0;
   End;
  End;

  $01: Begin { Set device information }
   { ByteCount contient les nouvelles informations }
   Result:=IOCTL_SetDeviceInfo(Handle, ByteCount);
   DOS44h_IOCTL:=Result;
  End;

  $02: Begin { Read control data from character device }
   Result:=IOCTL_ReadControlData(Handle, Buffer, ByteCount);
   DOS44h_IOCTL:=Result;
  End;

  $03: Begin { Write control data to character device }
   Result:=IOCTL_WriteControlData(Handle, Buffer, ByteCount);
   DOS44h_IOCTL:=Result;
  End;

  $08: Begin { Get drive information }
   Drive:=Handle; { Pour cette sous-fonction,
     Handle contient le numéro de lecteur }
   Result:=IOCTL_GetDriveInfo(Drive);
   If Result <> $FFFF Then Begin
    { Retourner l'information dans DX }
    ASM
     MOV AX,Result
     MOV DX,AX
    END;
    DOS44h_IOCTL:=0;
   End;
  End;

  $09: Begin { Set drive information }
   Drive:=Handle;
   Result:=IOCTL_SetDriveInfo(Drive, ByteCount);
   DOS44h_IOCTL:=Result;
  End;

  Else
   DOS44h_IOCTL:=1; { Invalid function }
 End;
End;

{ Fonction 45h - Duplicate Handle (table de handles du processus courant) }
Function DOS45h_DuplicateHandle(SourceHandle:Word):Word;
Begin
 DOS45h_DuplicateHandle:=JftDup(SourceHandle);
End;

{ Fonction 46h - Force Duplicate Handle }
Function DOS46h_ForceDuplicateHandle(SourceHandle:Word;TargetHandle:Word):Word;
Begin
 DOS46h_ForceDuplicateHandle:=JftForce(SourceHandle,TargetHandle);
End;

{ Fonction 47h - Get Current Directory }
Function DOS47h_GetCurrentDirectory(Drive:Byte;BufferSeg:Word;
  BufferOfs:Word):Word;
Var
 CurrentDrive: Byte;
 I: Byte;
 Path: String;
 Dst: PChar;
Begin
 DOS47h_GetCurrentDirectory:=15; { Invalid drive par defaut }
 If Drive = 0 Then
  CurrentDrive:=GetCurrentDrive
 Else Begin
  CurrentDrive:=Drive - 1; { 1=A:, 2=B:, ... -> 0=A:, 1=B:, ... }
  If CurrentDrive>=NDrv Then Exit;
 End;
 { chemin courant memorise sans le "\" initial (chaine vide pour la racine) }
 Path:='';
 If GetCurrentDirCluster(CurrentDrive) <> 0 Then Begin
  Path:=GetCurrentDirPath(CurrentDrive);
  If (Length(Path) > 0) And (Path[1] = '\') Then Delete(Path,1,1);
 End;
 Dst:=PChar(Ptr(BufferSeg,BufferOfs));
 For I:=1 To Length(Path) Do Begin
  Dst^:=Path[I];
  Inc(Dst);
 End;
 Dst^:=#0;
 DOS47h_GetCurrentDirectory:=0;
End;
{ Fonctions de gestion de la mémoire }

{ Initialise le gestionnaire de mémoire }
Function InitializeMemoryManager:Boolean;
Var
 MCB: MemoryControlBlock;
 FirstMCB: Word;
Begin
 InitializeMemoryManager:=False;

 { Le premier MCB commence généralement à 0x0060 (après les vecteurs
   d'interruption) }
 FirstMCB:=ArenaBase;

 { Créer le premier MCB couvrant toute la mémoire conventionnelle }
 MCB.BlockType:='Z';      { Dernier bloc }
 MCB.Owner:=0;            { Bloc libre }
 MCB.BlockSize:=ArenaEnd-ArenaBase-1; { mémoire conventionnelle après le noyau }
 FillChar(MCB.Reserved, 3, 0);
 FillChar(MCB.ProgramName, 8, 0);

 If SetMCB(FirstMCB, MCB) Then Begin
  { Initialiser la stratégie d'allocation par défaut (First Fit) }
  SetMemoryStrategy(0);

  { Initialiser l'état UMB par défaut (non liés) }
  SetUMBLinkState(0);

  { Initialiser les informations d'erreur étendue }
  ClearExtendedError;

  InitializeMemoryManager:=True;
 End;
End;

{ Obtient un MCB à partir de son segment }
Function GetMCB(Segment:Word;Var MCB:MemoryControlBlock):Boolean;
Begin
 GetMCB:=False;
 { Lire le MCB depuis la mémoire }
 ASM
  PUSH DS
  PUSH ES
  MOV AX,Segment
  MOV DS,AX
  XOR SI,SI

  { Pointer vers la structure MCB (paramètre Var) }
  LES DI,MCB
  MOV CX,16           { Taille d'un MCB }
  CLD
  REP MOVSB

  POP ES
  POP DS
 END;
 GetMCB:=True;
End;

{ Définit un MCB à son segment }
Function SetMCB(Segment:Word;MCB:MemoryControlBlock):Boolean;
Begin
 SetMCB:=False;
 { Écrire le MCB en mémoire }
 ASM
  PUSH ES
  PUSH DS
  MOV AX,Segment
  MOV ES,AX
  XOR DI,DI

  { Pointer vers la structure MCB sur la pile }
  PUSH SS
  POP DS
  LEA SI,MCB
  MOV CX,16           { Taille d'un MCB }
  CLD
  REP MOVSB

  POP DS
  POP ES
 END;
 SetMCB:=True;
End;

{ Trouve un MCB libre de la taille demandée }
Function FindFreeMCB(Size:Word;Var Segment:Word):Boolean;
Var
 CurrentSeg: Word;
 MCB: MemoryControlBlock;
 Found: Boolean;
Begin
 FindFreeMCB:=False;
 Found:=False;
 CurrentSeg:=ArenaBase; { Premier MCB }

 While Not Found Do Begin
  If Not GetMCB(CurrentSeg, MCB) Then Break;

  { Vérifier si le bloc est libre et assez grand }
  If (MCB.Owner = 0) And (MCB.BlockSize >= Size) Then Begin
   Segment:=CurrentSeg + 1; { Le segment utilisable est MCB + 1 }
   Found:=True;
   FindFreeMCB:=True;
  End;

  { Passer au MCB suivant }
  If MCB.BlockType = 'Z' Then Break; { Dernier bloc }
  CurrentSeg:=CurrentSeg + MCB.BlockSize + 1;
 End;
End;

{ Crée un nouveau MCB }
Function CreateMCB(Segment:Word;Size:Word;Owner:Word;IsLast:Boolean):Boolean;
Var
 MCB: MemoryControlBlock;
Begin
 CreateMCB:=False;

 If IsLast Then
  MCB.BlockType:='Z'
 Else
  MCB.BlockType:='M';

 MCB.Owner:=Owner;
 MCB.BlockSize:=Size;
 FillChar(MCB.Reserved, 3, 0);
 FillChar(MCB.ProgramName, 8, 0);

 { Copier le nom "COMMAND" pour les blocs système }
 If Owner <> 0 Then Begin
  MCB.ProgramName[0]:='C';
  MCB.ProgramName[1]:='O';
  MCB.ProgramName[2]:='M';
  MCB.ProgramName[3]:='M';
  MCB.ProgramName[4]:='A';
  MCB.ProgramName[5]:='N';
  MCB.ProgramName[6]:='D';
  MCB.ProgramName[7]:=#0;
 End;

 CreateMCB:=SetMCB(Segment, MCB);
End;

{ Fonction 48h - Alloue un bloc mémoire }
Function DOS48h_AllocateMemory(BlockSize:Word):Word;
Var
 CurrentStrategy: Word;
 Segment: Word;
Begin
 DOS48h_AllocateMemory:=0; { Erreur par défaut }

 { Vérifier que la taille est raisonnable }
 If BlockSize = 0 Then Begin
  DOS48h_AllocateMemory:=0;
  Exit;
 End;

 { Obtenir la stratégie d'allocation actuelle }
 CurrentStrategy := GetMemoryStrategy;

 { Allouer avec la stratégie appropriée }
 Segment := AllocateMemoryWithStrategy(BlockSize, CurrentStrategy);

 DOS48h_AllocateMemory := Segment;
End;

{ Fonction 49h - Libère un bloc mémoire }
Function DOS49h_FreeMemory(BlockSegment:Word):Word;
Var
 MCBSeg: Word;
 MCB: MemoryControlBlock;
Begin
 DOS49h_FreeMemory:=9; { Invalid memory block par défaut }

 { Vérifier la validité du segment }
 If BlockSegment <= ArenaBase Then Exit; { Trop bas }

 MCBSeg:=BlockSegment - 1; { MCB est juste avant }

 { Obtenir le MCB }
 If GetMCB(MCBSeg, MCB) Then Begin
  { Vérifier que le bloc est alloué }
  If MCB.Owner = 0 Then Begin
   DOS49h_FreeMemory:=9; { Bloc déjà libre }
   Exit;
  End;

  { Marquer le bloc comme libre }
  MCB.Owner:=0;
  FillChar(MCB.ProgramName, 8, 0);
  SetMCB(MCBSeg, MCB);

  { Fusionner avec les blocs libres adjacents si possible }
  { (implémentation simplifiée - pas de fusion pour l'instant) }

  DOS49h_FreeMemory:=0; { Succès }
 End;
End;

{ Fonction 4Ah - Modifie la taille d'un bloc mémoire }
Function DOS4Ah_ModifyMemory(BlockSegment:Word;NewSize:Word):Word;
Var
 MCBSeg: Word;
 MCB: MemoryControlBlock;
 NextMCBSeg: Word;
 NextMCB: MemoryControlBlock;
Begin
 DOS4Ah_ModifyMemory:=9; { Invalid memory block par défaut }

 { Vérifier la validité du segment }
 If BlockSegment <= ArenaBase Then Exit;

 MCBSeg:=BlockSegment - 1;

 { Obtenir le MCB }
 If GetMCB(MCBSeg, MCB) Then Begin
  { Vérifier que le bloc est alloué }
  If MCB.Owner = 0 Then Begin
   DOS4Ah_ModifyMemory:=9;
   Exit;
  End;

  { Si la nouvelle taille est identique, rien à faire }
  If MCB.BlockSize = NewSize Then Begin
   DOS4Ah_ModifyMemory:=0;
   Exit;
  End;

  { Si réduction de taille }
  If NewSize < MCB.BlockSize Then Begin
   { Créer un nouveau MCB pour la partie libérée }
   NextMCBSeg:=MCBSeg + NewSize + 1;
   CreateMCB(NextMCBSeg, MCB.BlockSize - NewSize - 1, 0, MCB.BlockType = 'Z');

   { Modifier le MCB actuel }
   MCB.BlockSize:=NewSize;
   MCB.BlockType:='M';
   SetMCB(MCBSeg, MCB);

   DOS4Ah_ModifyMemory:=0;
  End
  Else Begin
   { Agrandissement - vérifier si possible }
   NextMCBSeg:=MCBSeg + MCB.BlockSize + 1;

   { Si ce n'est pas le dernier bloc, vérifier le suivant }
   If MCB.BlockType = 'M' Then Begin
    If GetMCB(NextMCBSeg, NextMCB) Then Begin
     { Si le bloc suivant est libre et assez grand }
     If (NextMCB.Owner = 0) And
        (MCB.BlockSize + NextMCB.BlockSize + 1 >= NewSize) Then Begin

      { Fusionner les blocs }
      MCB.BlockSize:=NewSize;
      MCB.BlockType:=NextMCB.BlockType;

      { Si il reste de l'espace, créer un nouveau MCB libre }
      If MCB.BlockSize + NextMCB.BlockSize + 1 > NewSize Then Begin
       CreateMCB(MCBSeg + NewSize + 1,
                MCB.BlockSize + NextMCB.BlockSize + 1 - NewSize - 1,
                0, NextMCB.BlockType = 'Z');
       MCB.BlockType:='M';
      End;

      SetMCB(MCBSeg, MCB);
      DOS4Ah_ModifyMemory:=0;
     End
     Else
      DOS4Ah_ModifyMemory:=8; { Insufficient memory }
    End;
   End
   Else
    DOS4Ah_ModifyMemory:=8; { Pas assez d'espace }
  End;
 End;
End;

{ Fonctions pour EXEC - Load and Execute Program }

{ Crée un nouveau PSP (Program Segment Prefix) }
Function CreatePSP(ParentPSP:Word;TopMemory:Word):Word;
Var
 PSP: ProgramSegmentPrefix;
 PSPSeg: Word;
 I: Integer;
Begin
 CreatePSP:=0;

 { Allouer un segment pour le PSP (256 octets = 16 paragraphes) }
 PSPSeg:=DOS48h_AllocateMemory(16);
 If PSPSeg = 0 Then Exit;

 { Initialiser le PSP }
 FillChar(PSP, SizeOf(PSP), 0);

 { INT 20h instruction (CD 20) }
 PSP.Int20h:=$20CD;

 { Segment du haut de la mémoire }
 PSP.TopOfMemory:=TopMemory;

 { Call to DOS dispatcher (9A 00 00 00 F0) }
 PSP.CallToDispatcher[0]:=$9A;
 PSP.CallToDispatcher[1]:=$00;
 PSP.CallToDispatcher[2]:=$00;
 PSP.CallToDispatcher[3]:=$00;
 PSP.CallToDispatcher[4]:=$F0;

 { PSP parent }
 PSP.ParentPSP:=ParentPSP;

 { Initialiser la table des handles (tous fermés sauf 0,1,2) }
 For I:=0 To 19 Do
  PSP.HandleTable[I]:=$FF; { Fermé }
 PSP.HandleTable[0]:=$01;   { STDIN }
 PSP.HandleTable[1]:=$01;   { STDOUT }
 PSP.HandleTable[2]:=$01;   { STDERR }

 { Taille table handles }
 PSP.HandleTableSize:=20;

 { DOS call (CD 21 CB) }
 PSP.DOSCall[0]:=$CD;
 PSP.DOSCall[1]:=$21;
 PSP.DOSCall[2]:=$CB;

 { Copier le PSP en mémoire }
 ASM
  PUSH ES
  PUSH DS

  MOV AX,PSPSeg
  MOV ES,AX
  XOR DI,DI

  PUSH SS
  POP DS
  LEA SI,PSP
  MOV CX,256       { Taille d'un PSP }
  CLD
  REP MOVSB

  POP DS
  POP ES
 END;

 CreatePSP:=PSPSeg;
End;

{ Configure l'environnement pour le nouveau programme }
Function SetupEnvironment(EnvSeg:Word;ParentPSP:Word):Word;
Var
 EnvSegment: Word;
 DefaultEnv: String;
Begin
 SetupEnvironment:=0;

 { Si aucun environnement spécifié, créer un environnement minimal }
 If EnvSeg = 0 Then Begin
  { Allouer 1KB pour l'environnement }
  EnvSegment:=DOS48h_AllocateMemory(64); { 64 paragraphes = 1KB }
  If EnvSegment = 0 Then Exit;

  { Créer un environnement minimal }
  DefaultEnv:='PATH=C:\';
  DefaultEnv[6]:=BootLetter;

  { Copier l'environnement }
  ASM
   PUSH ES
   PUSH DS

   MOV AX,EnvSegment
   MOV ES,AX
   XOR DI,DI

   PUSH SS
   POP DS
   LEA SI,DefaultEnv
   MOV CL,[SI]
   MOV CH,0
   INC SI
   CLD
   REP MOVSB

   { Ajouter deux zéros de fin }
   MOV AL,0
   STOSB
   STOSB

   POP DS
   POP ES
  END;

  SetupEnvironment:=EnvSegment;
 End
 Else Begin
  SetupEnvironment:=EnvSeg;
 End;
End;

{ Charge un fichier COM en mémoire }
Function LoadComFile(FileName:String;Var LoadSegment:Word):Boolean;
Var
 Handle: Word;
 FileSize: LongInt;
 Buffer: Array[0..511] of Byte;
 BytesRead: Word;
 TotalRead: Word;
Begin
 LoadComFile:=False;

 { Allouer mémoire pour le programme (64KB max) }
 LoadSegment:=DOS48h_AllocateMemory(4096); { 64KB }
 If LoadSegment = 0 Then Exit;

 { Note: Les fonctions DOS3Dh, DOS3Eh, etc. doivent être implémentées }
 { Pour l'instant, implémentation simplifiée }
 LoadComFile:=True;
End;

{ Charge un fichier EXE en mémoire }
Function LoadExeFile(FileName:String;Var LoadSegment:Word;
  Var ExeHdr:ExeHeader):Boolean;
Begin
 LoadExeFile:=False;

 { Allouer mémoire basique }
 LoadSegment:=DOS48h_AllocateMemory(1024); { 16KB }
 If LoadSegment = 0 Then Exit;

 { Implémentation simplifiée pour l'instant }
 LoadExeFile:=True;
End;

{ Applique les relocalisations EXE }
Function RelocateExe(LoadSeg:Word;ExeHdr:ExeHeader;FileName:String):Boolean;
Begin
 { Implémentation simplifiée - pas de relocalisations pour l'instant }
 RelocateExe:=True;
End;

{$IFDEF KDEBUG}
Procedure DbgW(Tag:Char;W:Word);Assembler;
ASM
 MOV AL,Tag
 MOV AH,0Eh
 XOR BX,BX
 INT 10h
 MOV DX,W
 MOV CX,4
@Nib:
 PUSH CX
 MOV CL,4
 ROL DX,CL
 POP CX
 MOV AL,DL
 AND AL,0Fh
 ADD AL,48
 CMP AL,57
 JBE @Pr
 ADD AL,7
@Pr:
 MOV AH,0Eh
 XOR BX,BX
 INT 10h
 LOOP @Nib
 MOV AL,32
 MOV AH,0Eh
 XOR BX,BX
 INT 10h
END;
{$ENDIF}

{ ---------- EXEC : chargement et lancement d'un programme DOS ---------- }

{ Transfere le controle au programme : sauve le contexte du noyau (SS:SP dans le
  PSP enfant, registres sur la pile), puis RETF vers CS:IP du programme.
  Reprend quand le programme se termine (ExecReturn). }
Procedure ExecEnter(ChildPSP,CodeSeg,CodeOfs,StackSeg,StackOfs:Word);Assembler;
ASM
 PUSH SI
 PUSH DI
 PUSH DS
 PUSH ES
 MOV ES,ChildPSP
 MOV AX,CS
 MOV DS,AX
 MOV AX,WORD PTR [Data + FxBase + 124]
 MOV ES:[3Ah],AX
 MOV AX,SS
 CMP AX,9000h
 JNE @NoK
 MOV AX,SP
 SUB AX,24
 MOV WORD PTR [Data + FxBase + 124],AX
@NoK:
 MOV ES:[2Eh],SP
 MOV ES:[30h],SS
 MOV AX,StackSeg
 MOV BX,StackOfs
 MOV CX,CodeSeg
 MOV DX,CodeOfs
 PUSH ES
 POP DS
 CLI
 MOV SS,AX
 MOV SP,BX
 STI
 PUSH CX
 PUSH DX
 XOR AX,AX
 XOR BX,BX
 XOR CX,CX
 XOR DX,DX
 XOR SI,SI
 XOR DI,DI
 XOR BP,BP
 RETF
END;

{ Retour dans le noyau, a l'appelant d'ExecEnter,
  quand le programme se termine. }
Procedure ExecReturn(ChildPSP:Word);Assembler;
ASM
 MOV ES,ChildPSP
 MOV AX,CS
 MOV DS,AX
 MOV AX,ES:[3Ah]
 MOV WORD PTR [Data + FxBase + 124],AX
 MOV AX,ES:[2Eh]
 MOV BX,ES:[30h]
 CLI
 MOV SS,BX
 MOV SP,AX
 STI
 POP ES
 POP DS
 POP DI
 POP SI
 POP BP
 RET 10
END;

Procedure SetBlockOwner(BlockSeg,Owner:Word);
Var
 MCB: MemoryControlBlock;
Begin
 If GetMCB(BlockSeg-1,MCB) Then Begin
  MCB.Owner:=Owner;
  SetMCB(BlockSeg-1,MCB);
 End;
End;

{ Libere tous les blocs d'un proprietaire et fusionne les blocs libres contigus
  }
Procedure FreeProcessMemory(Owner:Word);
Var
 Cur: Word;
 MCB,Next: MemoryControlBlock;
 Last: Boolean;
Begin
 Cur:=ArenaBase;
 Last:=False;
 While Not Last Do Begin
  If Not GetMCB(Cur,MCB) Then Break;
  If MCB.Owner=Owner Then Begin
   MCB.Owner:=0;
   SetMCB(Cur,MCB);
  End;
  Last:=(MCB.BlockType='Z');
  If Not Last Then Cur:=Cur+MCB.BlockSize+1;
 End;
 Cur:=ArenaBase;
 While GetMCB(Cur,MCB) Do Begin
  If MCB.BlockType='Z' Then Break;
  If (MCB.Owner=0) And GetMCB(Cur+MCB.BlockSize+1,
    Next) And (Next.Owner=0) Then Begin
   MCB.BlockSize:=MCB.BlockSize+Next.BlockSize+1;
   MCB.BlockType:=Next.BlockType;
   SetMCB(Cur,MCB);
  End
  Else Cur:=Cur+MCB.BlockSize+1;
 End;
End;

{ Taille (en paragraphes) du plus grand bloc libre }
Function LargestFreeBlock:Word;
Var
 Cur,Best: Word;
 MCB: MemoryControlBlock;
Begin
 Cur:=ArenaBase;
 Best:=0;
 While GetMCB(Cur,MCB) Do Begin
  If (MCB.Owner=0) And (MCB.BlockSize>Best) Then Best:=MCB.BlockSize;
  If MCB.BlockType='Z' Then Break;
  Cur:=Cur+MCB.BlockSize+1;
 End;
 LargestFreeBlock:=Best;
End;

Procedure BuildPSP(P,Parent,Top,EnvSeg:Word;CmdPtr:Pointer);
Var
 I,N,CmdSeg,CmdOfs: Word;
Begin
 For I:=0 To 255 Do Mem[P:I]:=0;
 MemW[P:0]:=$20CD;
 MemW[P:2]:=Top;
 Mem[P:5]:=$9A;
 MemW[P:$16]:=Parent;
 { le premier processus (parent sans PSP valide) est son propre parent,
   comme sous MS-DOS }
 If (Parent=0) Or (MemW[Parent:0]<>$20CD) Then MemW[P:$16]:=P;
 JftInherit(P,Parent);
 MemW[P:$2C]:=EnvSeg;
 MemW[P:$32]:=20;
 MemW[P:$34]:=$18;
 MemW[P:$36]:=P;
 Mem[P:$50]:=$CD; Mem[P:$51]:=$21; Mem[P:$52]:=$CB;
 Mem[P:$80]:=0; Mem[P:$81]:=$0D;
 If CmdPtr<>Nil Then Begin
  ASM
   LES DI,CmdPtr
   MOV CmdSeg,ES
   MOV CmdOfs,DI
  END;
  N:=Mem[CmdSeg:CmdOfs];
  If N>126 Then N:=126;
  Mem[P:$80]:=N;
  For I:=1 To N Do Mem[P:$80+I]:=Mem[CmdSeg:CmdOfs+I];
  Mem[P:$81+N]:=$0D;
 End;
End;

{ Lettre du lecteur d'amorcage (lecteur courant au demarrage) }
Function BootLetter:Char;Assembler;
ASM
 MOV AL,BYTE PTR [Data + 2]
 ADD AL,65
END;

{ Environnement : COMSPEC + PATH, puis nombre de chaines et nom du programme }
Function BuildEnvironment(Owner:Word;ProgName:String):Word;
Var
 Seg,Ofs2,I: Word;
 Env: String;
Begin
 BuildEnvironment:=0;
 Seg:=DOS48h_AllocateMemory(32);
 If Seg=0 Then Exit;
 SetBlockOwner(Seg,Owner);
 Env:='COMSPEC=C:\COMMAND.EXE';
 Env[9]:=BootLetter;
 If Mem[CfgSegGet:12]<>0 Then Begin
  Env:='COMSPEC=';
  For I:=1 To Mem[CfgSegGet:12] Do Env:=Env+Chr(Mem[CfgSegGet:12+I]);
 End;
 Ofs2:=0;
 For I:=1 To Length(Env) Do Begin
  Mem[Seg:Ofs2]:=Ord(Env[I]); Inc(Ofs2);
 End;
 Mem[Seg:Ofs2]:=0; Inc(Ofs2);
 Env:='PATH=C:\';
 Env[6]:=BootLetter;
 For I:=1 To Length(Env) Do Begin
  Mem[Seg:Ofs2]:=Ord(Env[I]); Inc(Ofs2);
 End;
 Mem[Seg:Ofs2]:=0; Inc(Ofs2);
 Mem[Seg:Ofs2]:=0; Inc(Ofs2);
 MemW[Seg:Ofs2]:=1; Inc(Ofs2,2);
 For I:=1 To Length(ProgName) Do Begin
  Mem[Seg:Ofs2]:=Ord(ProgName[I]); Inc(Ofs2);
 End;
 Mem[Seg:Ofs2]:=0;
 BuildEnvironment:=Seg;
End;

{ Fonction principale 4Bh - EXEC (type 00h : charger et executer) }
{ Chargement d'un programme .COM : image a PSP:0100,
  tout le bloc libre alloue (64 Ko au plus),
  pile en haut du segment avec un mot nul (le RET termine par INT 20h du PSP) }
Function ExecCom(Handle:Word;ProgramPath:String;CmdLine:Pointer):Word;
Var
 Size,Left,ImgBytes: LongInt;
 Need,Avail,EnvSeg,Block,Parent,Chunk,Got,N,Sp: Word;
Begin
 ExecCom:=11;
 Size:=DOS42h_SeekFile(Handle,0,0,2);
 If (Size=LongInt($FFFFFFFF)) Or (Size<1) Or (Size>65280) Then Begin
  DOS3Eh_CloseFile(Handle);
  Exit;
 End;
 EnvSeg:=BuildEnvironment(0,ProgramPath);
 Avail:=LargestFreeBlock;
 Need:=Avail;
 If Need>4096 Then Need:=4096;
 If Need<Word((Size+15) Div 16)+32 Then Begin
  DOS3Eh_CloseFile(Handle);
  ExecCom:=8;
  Exit;
 End;
 Parent:=GetCurrentPSP;
 Block:=DOS48h_AllocateMemory(Need);
 If Block=0 Then Begin
  DOS3Eh_CloseFile(Handle);
  ExecCom:=8;
  Exit;
 End;
 SetBlockOwner(Block,Block);
 If EnvSeg<>0 Then SetBlockOwner(EnvSeg,Block);
 BuildPSP(Block,Parent,Block+Need,EnvSeg,CmdLine);
 DOS42h_SeekFile(Handle,0,0,0);
 ImgBytes:=Size;
 N:=0;
 While ImgBytes>0 Do Begin
  If ImgBytes>8192 Then Chunk:=8192 Else Chunk:=Word(ImgBytes);
  Got:=0;
  DOS3Fh_ReadFile(Handle,Ptr(Block+16+N*512,0),Chunk,Got);
  If Got=0 Then Break;
  Dec(ImgBytes,Got);
  Inc(N);
 End;
 DOS3Eh_CloseFile(Handle);
 SetCurrentPSP(Block);
 SetDTA(Block,$80);
 If Need>=4096 Then Sp:=$FFFE Else Sp:=Need*16-2;
 MemW[Block:Sp]:=0;
 ExecCom:=0;
 ExecEnter(Block,Block,$100,Block,Sp);
 ExecCom:=0;
End;

Function DOS4Bh_ExecProgram(ExecType:Byte;ProgramPath:String;
  ParamBlock:ExecParameterBlock):Word;
Var
 Hdr: ExeHeader;
 Path: Array[0..127] of Char;
 Handle,Got,I,Block,ImgSeg,Need,Avail,EnvSeg,Parent,Chunk,Reloc,FixSeg,
   FixOfs: Word;
 FileLen,ImgBytes,WantL: LongInt;
 Pairs: Array[0..63] of Word;
 Left,Todo: Word;
Begin
 DOS4Bh_ExecProgram:=2;
 If ExecType<>0 Then Begin DOS4Bh_ExecProgram:=1; Exit; End;
 For I:=1 To Length(ProgramPath) Do Path[I-1]:=ProgramPath[I];
 Path[Length(ProgramPath)]:=#0;
 Handle:=DOS3Dh_OpenFile(@Path,0);
{$IFDEF KDEBUG}DbgW('H',Handle);{$ENDIF}
 If Handle=$FFFF Then Exit;
 Got:=0;
 DOS3Fh_ReadFile(Handle,@Hdr,SizeOf(Hdr),Got);
{$IFDEF KDEBUG}DbgW('g',Got);DbgW('m',Hdr.Signature);DbgW('p',Hdr.PagesInFile);
  {$ENDIF}
 If (Got<SizeOf(Hdr)) Or ((Hdr.Signature<>$5A4D) And (Hdr.Signature<>$4D5A))
   Then Begin
  { fichier .COM : image brute }
  If (Length(ProgramPath)>=4) And
    (UpCase(ProgramPath[Length(ProgramPath)-2])='C') And
     (UpCase(ProgramPath[Length(ProgramPath)-1])='O') And
       (UpCase(ProgramPath[Length(ProgramPath)])='M') Then Begin
   DOS4Bh_ExecProgram:=ExecCom(Handle,ProgramPath,ParamBlock.CommandLine);
   Exit;
  End;
  DOS3Eh_CloseFile(Handle);
  DOS4Bh_ExecProgram:=11; { format incorrect }
  Exit;
 End;
 If Hdr.BytesInLastPage=0 Then FileLen:=LongInt(Hdr.PagesInFile)*512
 Else FileLen:=LongInt(Hdr.PagesInFile-1)*512+Hdr.BytesInLastPage;
 ImgBytes:=FileLen-LongInt(Hdr.HeaderParagraphs)*16;
 { paragraphes : PSP (16) + image + supplement minimal }
 Need:=16+Word((ImgBytes+15) Div 16)+Hdr.MinExtraParagraphs;
 EnvSeg:=BuildEnvironment(0,ProgramPath);
 Avail:=LargestFreeBlock;
 If Need>Avail Then Begin
  DOS3Eh_CloseFile(Handle);
  DOS4Bh_ExecProgram:=8;
  Exit;
 End;
 { donner au programme tout ce qui est possible jusqu'au maximum demande }
 If (Hdr.MaxExtraParagraphs>=Hdr.MinExtraParagraphs) And
   (Hdr.MaxExtraParagraphs<>$FFFF) Then Begin
  WantL:=Need;
  WantL:=WantL-Hdr.MinExtraParagraphs;
  WantL:=WantL+Hdr.MaxExtraParagraphs;
  If WantL<Avail Then Need:=Word(WantL)
  Else Need:=Avail;
 End
 Else Need:=Avail;
 Parent:=GetCurrentPSP;
 Block:=DOS48h_AllocateMemory(Need);
 If Block=0 Then Begin
  DOS3Eh_CloseFile(Handle);
  DOS4Bh_ExecProgram:=8;
  Exit;
 End;
 SetBlockOwner(Block,Block);
 If EnvSeg<>0 Then SetBlockOwner(EnvSeg,Block);
 BuildPSP(Block,Parent,Block+Need,EnvSeg,ParamBlock.CommandLine);
 ImgSeg:=Block+16;
 { charger l'image par morceaux de 8 Ko (512 paragraphes) }
 DOS42h_SeekFile(Handle,0,Hdr.HeaderParagraphs*16,0);
 Left:=0;
 While ImgBytes>0 Do Begin
  If ImgBytes>8192 Then Chunk:=8192 Else Chunk:=Word(ImgBytes);
  Got:=0;
  DOS3Fh_ReadFile(Handle,Ptr(ImgSeg+Left*512,0),Chunk,Got);
  If Got=0 Then Break;
  Dec(ImgBytes,Got);
  Inc(Left);
 End;
 { relocalisations }
 If Hdr.Relocations>0 Then Begin
  DOS42h_SeekFile(Handle,0,Hdr.RelocTableOffset,0);
  Reloc:=Hdr.Relocations;
  While Reloc>0 Do Begin
   If Reloc>32 Then Todo:=32 Else Todo:=Reloc;
   Got:=0;
   DOS3Fh_ReadFile(Handle,@Pairs,Todo*4,Got);
   If Got<Todo*4 Then Break;
   For I:=0 To Todo-1 Do Begin
    FixOfs:=Pairs[I*2];
    FixSeg:=ImgSeg+Pairs[I*2+1];
    MemW[FixSeg:FixOfs]:=MemW[FixSeg:FixOfs]+ImgSeg;
   End;
   Dec(Reloc,Todo);
  End;
 End;
 DOS3Eh_CloseFile(Handle);
 SetCurrentPSP(Block);
 SetDTA(Block,$80);
 { sauver les vecteurs de terminaison dans le PSP }
 DOS4Bh_ExecProgram:=0;
 ExecEnter(Block,ImgSeg+Hdr.InitialCS,Hdr.InitialIP,ImgSeg+Hdr.InitialSS,
   Hdr.InitialSP);
 { le programme est termine : retour ici }
 DOS4Bh_ExecProgram:=0;
End;

{ Pont INT 21h/4Bh : ASCIIZ DS:DX et bloc de parametres ES:BX -> parametres
  Pascal }
Function ExecFromInt21(Mode:Word;NamePtr:Pointer;BlockPtr:Pointer):Word;
Var
 Name: String;
 PB: ExecParameterBlock;
 P: PChar;
 N: Word;
Begin
 Name:='';
 P:=PChar(NamePtr);
 N:=0;
 While (P^<>#0) And (N<127) Do Begin
  Name:=Name+P^;
  Inc(P);
  Inc(N);
 End;
 FillChar(PB,SizeOf(PB),0);
 ASM
  PUSH DS
  LDS SI,BlockPtr
  LEA DI,PB
  PUSH SS
  POP ES
  MOV CX,14
  CLD
  REP MOVSB
  POP DS
 END;
 ExecFromInt21:=DOS4Bh_ExecProgram(Lo(Mode),Name,PB);
End;

{ ---------- Passerelles INT 21h -> fonctions Pascal ---------- }
Procedure ConPutChar(C:Byte);Assembler;
ASM
 PUSH BP
 PUSH DS
 MOV AX,40h
 MOV DS,AX
 MOV DX,DS:[50h]          { curseur BIOS (zone de donnees 0040:0050) }
 POP DS
 MOV AH,02h
 XOR BH,BH
 INT 10h
 MOV AL,C
 MOV AH,0Eh
 MOV BX,0007h
 INT 10h
 MOV AH,03h
 XOR BH,BH
 INT 10h
 PUSH DS
 MOV AX,40h
 MOV DS,AX
 MOV DS:[50h],DX
 POP DS
 POP BP
END;

Function ConGetKey:Word;Assembler;
ASM
 XOR AX,AX
 INT 16h
END;

Procedure BufParts(Buf:Pointer;Var S,O:Word);Assembler;
ASM
 PUSH ES
 PUSH DI
 LES DI,Buf
 MOV AX,ES
 MOV BX,DI
 LES DI,S
 MOV ES:[DI],AX
 LES DI,O
 MOV ES:[DI],BX
 POP DI
 POP ES
END;

Function GetDTASeg:Word;Assembler;
ASM
 MOV AX,Data.DataMOS.DTASegment
END;

Function GetDTAOfs:Word;Assembler;
ASM
 MOV AX,Data.DataMOS.DTAOffset
END;

Procedure SetDTA(S,O:Word);Assembler;
ASM
 MOV AX,S
 MOV Data.DataMOS.DTASegment,AX
 MOV AX,O
 MOV Data.DataMOS.DTAOffset,AX
END;

Function PendingLFSet:Boolean;Assembler;
ASM
 MOV AL,Data.DataMOS.PendingLF
END;

Procedure ClearPendingLF;Assembler;
ASM
 MOV Data.DataMOS.PendingLF,0
END;

Procedure SetPendingLF;Assembler;
ASM
 MOV Data.DataMOS.PendingLF,1
END;

Procedure DowTable;Assembler;
ASM
 DB 0,3,2,5,0,3,5,1,4,6,2,4
END;

Function BiosDateRaw:LongInt;Assembler;
ASM
 MOV AH,04h
 INT 1Ah
 MOV AX,CX
END;

Function BiosTimeRaw:LongInt;Assembler;
ASM
 MOV AH,02h
 INT 1Ah
 MOV AX,CX
END;

Function Bcd(B:Byte):Word;
Begin
 Bcd:=(B Shr 4)*10+(B And 15);
End;

{ INT 21h/2Ah : DX:AX = annee ; (mois << 8 | jour) }
Function DateInt21:LongInt;
Var
 R: LongInt;
 CY,MD: Word;
Begin
 R:=BiosDateRaw;
 CY:=Word(R);
 MD:=Word(R Shr 16);
 DateInt21:=LongInt(Bcd(Hi(CY))*100+Bcd(Lo(CY)))+LongInt(Bcd(Hi(MD))*256+
   Bcd(Lo(MD)))*65536;
End;

{ Jour de la semaine (0=dimanche) par la formule de Sakamoto }
Function WdayInt21:Word;
Var
 R: LongInt;
 Y,M,D: Word;
Begin
 R:=DateInt21;
 Y:=Word(R);
 M:=Hi(Word(R Shr 16));
 D:=Lo(Word(R Shr 16));
 If (M<1) Or (M>12) Then M:=1;
 If M<3 Then Dec(Y);
 WdayInt21:=(Y+Y Div 4-Y Div 100+Y Div 400+Word(Mem[CSeg:Ofs(DowTable)+M-1])+D)
   Mod 7;
End;

{ INT 21h/2Ch : DX:AX = (heures << 8 | minutes) ; (secondes << 8 | centiemes) }
Function TimeInt21:LongInt;
Var
 R: LongInt;
 HM,SC: Word;
Begin
 R:=BiosTimeRaw;
 HM:=Word(R);
 SC:=Word(R Shr 16);
 TimeInt21:=LongInt(Bcd(Hi(HM))*256+Bcd(Lo(HM)))+LongInt(Bcd(Hi(SC))*256)*65536;
End;

Function GetCurrentCountryCode:Word;Assembler;
ASM
 MOV AX,Data.DataMOS.CurrentCountry
END;

{ 38h : informations pays au format DOS (34 octets) en Buf }
Function CountryInt21(Buf:Pointer):Word;
Const
 { code pays (2 octets), octets 0..17 de la structure (format de date, monnaie,
   separateurs, formats), separateur de liste (2) :
   Etats-Unis, Canada, France, Espagne }
 T: String[88]=#1#0#0#0'$'#0#0#0#0','#0'.'#0'/'#0':'#0#0#2#0','#0+
              #2#0#1#0'$'#0#0#0#0' '#0','#0'/'#0':'#0#0#2#1';'#0+
              #33#0#1#0'FR'#0#0#0' '#0','#0'/'#0':'#0#0#2#1';'#0+
              #34#0#1#0'Pts'#0#0'.'#0','#0'/'#0':'#0#0#2#1';'#0;
Var
 S,O,K,E,C: Word;
Begin
 BufParts(Buf,S,O);
 C:=GetCurrentCountryCode;
 E:=45;
 For K:=0 To 3 Do
  If Ord(T[K*22+1])=C Then E:=K*22+1;
 For K:=0 To 33 Do Mem[S:O+K]:=0;
 For K:=0 To 17 Do Mem[S:O+K]:=Ord(T[E+2+K]);
 Mem[S:O+22]:=Ord(T[E+20]);
 Mem[S:O+23]:=Ord(T[E+21]);
 CountryInt21:=0;
End;

{ Sortie sur la sortie standard (handle 1, redirigeable) }
Procedure CharOut21(C:Byte);
Var Got:Word;
 B:Byte;
Begin
 B:=C;
 WriteInt21(1,@B,1,Got);
End;

{ Entree depuis l'entree standard quand elle est redirigee vers un fichier :
  $FFFE = console (a traiter par le clavier), $FFFF = fin de fichier,
    sinon l'octet lu }
Function CharIn21(Echo:Word):Word;
Var C:Byte;
 Got,S:Word;
Begin
 S:=JftGet(0);
 If (S=$FFFF) Or (S<5) Then Begin
  CharIn21:=$FFFE;
  Exit;
 End;
 Got:=0;
 DOS3Fh_ReadFile(S,@C,1,Got);
 If Got=0 Then CharIn21:=$FFFF
 Else Begin
  CharIn21:=C;
  If Echo<>0 Then CharOut21(C);
 End;
End;

{ 09h : chaine terminee par $ }
Procedure StrOut21(P:Pointer);
Var S,O,N,Got:Word;
Begin
 BufParts(P,S,O);
 N:=0;
 While (Mem[S:O+N]<>36) And (N<65000) Do Inc(N);
 If N>0 Then WriteInt21(1,P,N,Got);
End;

{ Lecture : poignees 0..4 = console (ligne editee, terminee par CR LF) }
{ Lecture / ecriture absolue de secteurs logiques (INT 25h / 26h). CX=FFFFh :
  paquet DS:BX
  (secteur LongInt, nombre Word,
    tampon Pointer). Rend 0 ou un code d'erreur DOS. }
Function AbsDiskInt21(Wr,Drive,Count,SecHi,SecLo,BufSeg,BufOfs:Word):Word;
Var
 Sec: LongInt;
 I,PS,PO,BS,BO: Word;
 Ok: Boolean;
Begin
 AbsDiskInt21:=0;
 If Drive>NDrv-1 Then Begin AbsDiskInt21:=1; Exit; End;
 BS:=BufSeg;
 BO:=BufOfs;
 Sec:=SecHi;
 Sec:=Sec*65536;
 Sec:=Sec+SecLo;
 If Count=$FFFF Then Begin
  PS:=BufSeg;
  PO:=BufOfs;
  Sec:=MemW[PS:PO+2];
  Sec:=Sec*65536;
  Sec:=Sec+MemW[PS:PO];
  Count:=MemW[PS:PO+4];
  BO:=MemW[PS:PO+6];
  BS:=MemW[PS:PO+8];
 End;
 I:=0;
 While I<Count Do Begin
  If Wr<>0 Then Ok:=WriteSector(Drive,Sec,Ptr(BS+I*32,BO))
  Else Ok:=ReadSector(Drive,Sec,Ptr(BS+I*32,BO));
  If Not Ok Then Begin AbsDiskInt21:=$0C; Exit; End;
  Sec:=Sec+1;
  Inc(I);
 End;
End;

Function ReadInt21(Handle:Word;Buf:Pointer;Count:Word;Var Got:Word):Word;
Var
 S,O,N,K: Word;
 C: Byte;
Begin
 Handle:=JftGet(Handle);
 If Handle=$FFFF Then Begin
  SetStandardError(6);
  Got:=0;
  ReadInt21:=6;
  Exit;
 End;
 If Handle>=5 Then Begin
  ReadInt21:=DOS3Fh_ReadFile(Handle,Buf,Count,Got);
  Exit;
 End;
 BufParts(Buf,S,O);
 N:=0;
 If Count=1 Then Begin
  { lecture caractere par caractere (RTL) : saisie avec echo, CR suivi d'un LF }
  If PendingLFSet Then Begin
   ClearPendingLF;
   Mem[S:O]:=10;
  End
  Else Begin
   { les touches etendues (AL=0, ex. fleches, Maj/Ctrl seuls) ne donnent
     aucun caractere : elles sont ignorees comme par l'editeur de ligne DOS }
   Repeat
    K:=ConGetKey;
    C:=Lo(K);
   Until C<>0;
   Mem[S:O]:=C;
   If C=13 Then Begin ConPutChar(13); ConPutChar(10); SetPendingLF; End
   Else If C=8 Then Begin ConPutChar(8); ConPutChar(32); ConPutChar(8); End
   Else If C>=32 Then ConPutChar(C);
  End;
{$IFDEF KDEBUG}DbgW('r',Mem[S:O]);{$ENDIF}
  Got:=1;
  ReadInt21:=0;
  Exit;
 End;
 If Count>=2 Then Begin
  Repeat
   K:=ConGetKey;
   C:=Lo(K);
   If C=13 Then Begin
    Mem[S:O+N]:=13; Mem[S:O+N+1]:=10; Inc(N,2);
    ConPutChar(13); ConPutChar(10);
    Break;
   End
   Else If C=8 Then Begin
    If N>0 Then Begin Dec(N); ConPutChar(8); ConPutChar(32); ConPutChar(8); End;
   End
   Else If ((C>=32) Or (C=26)) And (N<Count-2) Then Begin
    Mem[S:O+N]:=C; Inc(N);
    If C=26 Then Begin ConPutChar(94); ConPutChar(90) End Else ConPutChar(C);
   End;
  Until False;
 End;
 Got:=N;
 ReadInt21:=0;
End;

{ Ecriture : poignees 0..4 = console }
Function WriteInt21(Handle:Word;Buf:Pointer;Count:Word;Var Got:Word):Word;
Var
 S,O,I: Word;
Begin
 Handle:=JftGet(Handle);
 If Handle=$FFFF Then Begin
  SetStandardError(6);
  Got:=0;
  WriteInt21:=6;
  Exit;
 End;
 If Handle>=5 Then Begin
  WriteInt21:=DOS40h_WriteFile(Handle,Buf,Count,Got);
  Exit;
 End;
 BufParts(Buf,S,O);
 For I:=0 To Count-1 Do ConPutChar(Mem[S:O+I]);
 Got:=Count;
 WriteInt21:=0;
End;

Function AllocInt21(Size:Word):Word;
Begin
 AllocInt21:=DOS48h_AllocateMemory(Size);
End;

Function FindFirstInt21(NamePtr:Pointer;Attr:Word):Word;
Var
 Name: String;
 P: PChar;
 N: Word;
 D: ^DTAStruct;
Begin
 Name:='';
 P:=PChar(NamePtr);
 N:=0;
 While (P^<>#0) And (N<127) Do Begin
  Name:=Name+P^;
  Inc(P);
  Inc(N);
 End;
 D:=Ptr(GetDTASeg,GetDTAOfs);
 FindFirstInt21:=DOS4Eh_FindFirstFile(Name,Lo(Attr),D^);
End;

Function FindNextInt21:Word;
Var
 D: ^DTAStruct;
Begin
 D:=Ptr(GetDTASeg,GetDTAOfs);
 FindNextInt21:=DOS4Fh_FindNextFile(D^);
End;

{ ---------- CONFIG.SYS : FILES, BUFFERS, LASTDRIVE, SHELL, DEVICE,
  INSTALL ---------- }
{ Bloc de configuration (segment CfgSeg, alloue au demarrage) :
    0 FILES (mot)  2 LASTDRIVE (nombre d'unites)  4 BUFFERS  8 tete de la chaine
      des pilotes (FFFF:FFFF = vide)
    12 SHELL : chemin (chaine Pascal de 63 car.)  76 SHELL : arguments  140
      requete de pilote  172 ligne de commande du pilote
    320 contenu du fichier CONFIG.SYS }
Function CfgSegGet:Word;Assembler;
ASM
 MOV AX,WORD PTR [Data + FxBase + 126]
END;

Function CfgWord(Ofs:Word):Word;Assembler;
ASM
 PUSH ES
 MOV AX,WORD PTR [Data + FxBase + 126]
 MOV ES,AX
 MOV BX,Ofs
 MOV AX,ES:[BX]
 POP ES
END;

Procedure CfgMsg(Id:Byte);
Var I:Byte; M:String[40];
Begin
 If Id=0 Then M:='Pilote non installe' Else If Id=1 Then
   M:='INSTALL: programme introuvable'
 Else M:='Commande incorrecte dans CONFIG.SYS';
 For I:=1 To Length(M) Do ConPutChar(Ord(M[I]));
 ConPutChar(13);
 ConPutChar(10);
End;

{ DEVICE= : charge le pilote dont le chemin est a CfS:300 (ASCIIZ),
  appelle sa commande INIT et l'ajoute a la chaine }
Procedure CfgCopy(Src,Dst,Len:Word);
Var CfS,I:Word;
Begin
 CfS:=CfgSegGet;
 I:=0;
 While I<Len Do Begin Mem[CfS:Dst+I]:=Mem[CfS:Src+I]; Inc(I); End;
End;

{ DEVICE= : charge un pilote par DEVLOAD.EXE ;
  INSTALL= : lance un programme residant (ligne de commande a CfS:172) }
Procedure CfgRun(Dev:Boolean;V,P,A,E:Word);
Var
 PB: ExecParameterBlock;
 Pth: String;
 CfS,I: Word;
Begin
 CfS:=CfgSegGet;
 FillChar(PB,SizeOf(PB),0);
 PB.CommandLine:=Ptr(CfS,172);
 PB.FCB1:=Ptr(CfS,140);
 PB.FCB2:=Ptr(CfS,140);
 If Dev Then Begin
  Pth:='\DEVLOAD.EXE';
  A:=V;
 End Else Begin
  Pth:='';
  For I:=V To P-1 Do Pth:=Pth+Chr(Mem[CfS:I]);
 End;
 If E-A>120 Then E:=A+120;
 Mem[CfS:172]:=E-A+1;
 Mem[CfS:173]:=32;
 CfgCopy(A,174,E-A);
 If DOS4Bh_ExecProgram(0,Pth,PB)<>0 Then CfgMsg(0);
End;

{ Traite la ligne CfS:S..E-1 du tampon (en place) : le mot-cle est reconnu par
  ses deux premieres lettres }
Procedure CfgLine(S,E:Word);
Var
 CfS,V,P,A,I,N,Sig: Word;
Begin
 CfS:=CfgSegGet;
 Mem[CfS:E]:=32;
 While (S<E) And (Mem[CfS:S]<=32) Do Inc(S);
 If S>=E Then Exit;
 Sig:=(Mem[CfS:S] And $DF)*256+(Mem[CfS:S+1] And $DF);
 V:=S;
 While (Mem[CfS:V]>32) And (Mem[CfS:V]<>61) Do Inc(V);
 While (V<E) And ((Mem[CfS:V]<=32) Or (Mem[CfS:V]=61)) Do Inc(V);
 P:=V;
 While (P<E) And (Mem[CfS:P]>32) Do Inc(P);
 A:=P;
 While (A<E) And (Mem[CfS:A]<=32) Do Inc(A);
 N:=0;
 For I:=V To P-1 Do
  If (Mem[CfS:I]>=48) And (Mem[CfS:I]<=57) Then N:=N*10+Mem[CfS:I]-48;
 Case Sig Of
  $4649:Begin If N<8 Then N:=8; If N>20 Then N:=20; MemW[CfS:0]:=N; End;
    { FILES }
  $4255:Begin If N<1 Then N:=1; MemW[CfS:4]:=N; End;
    { BUFFERS }
  $4C41:Begin                                                                {
    LASTDRIVE }
   N:=(Mem[CfS:V] And $DF)-64;
   If N<3 Then N:=3;
   If N>NDrv Then N:=NDrv;
   MemW[CfS:2]:=N;
  End;
  $5348:Begin                                                                {
    SHELL }
   Mem[CfS:12]:=P-V;
   CfgCopy(V,13,P-V);
   Mem[CfS:76]:=E-A;
   CfgCopy(A,77,E-A);
  End;
  $4445:CfgRun(True,V,P,A,E);
    { DEVICE, DEVICEHIGH }
  $494E:CfgRun(False,V,P,A,E);
    { INSTALL }
  $5245,$4252,$444F,$5354,$4643,$434F,$5357:;
    { INSTALL REM BREAK DOS STACKS FCBS COUNTRY SWITCHES }
  Else CfgMsg(2);
 End;
End;

Procedure InitConfig;
Var
 CfS,H,Got,I,S: Word;
 Nm: String[13];
Begin
 CfS:=DOS48h_AllocateMemory(150);
 If CfS=0 Then Exit;
 SetBlockOwner(CfS,8);
 For I:=0 To 399 Do Mem[CfS:I]:=0;
 MemW[CfS:0]:=20;
 MemW[CfS:2]:=NDrv;
 MemW[CfS:4]:=20;
 ASM
  MOV AX,CfS
  MOV WORD PTR [Data + FxBase + 126],AX
 END;
 { C:\CONFIG.SYS }
 Nm:='\CONFIG.SYS';
 For I:=1 To 11 Do Mem[CfS:299+I]:=Ord(Nm[I]);
 H:=DOS3Dh_OpenFile(Ptr(CfS,300),0);
 If H<>$FFFF Then Begin
  Got:=0;
  DOS3Fh_ReadFile(H,Ptr(CfS,400),2040,Got);
  DOS3Eh_CloseFile(H);
  I:=0;
  While I<Got Do Begin
   S:=I;
   While (I<Got) And (Mem[CfS:400+I]<>13) And (Mem[CfS:400+I]<>10) And
     (Mem[CfS:400+I]<>26) Do Inc(I);
   CfgLine(400+S,400+I);
   Inc(I);
  End;
 End;
 DOS4Ah_ModifyMemory(CfS,25);
End;

{ SHELL= de CONFIG.SYS : lance l'interpreteur choisi (0 = s'est execute puis
  termine, 1 = absent ou echec) }
Function CfgShell:Word;
Var
 PB: ExecParameterBlock;
 Shell: String;
 F: Array[0..15] of Byte;
 CfS,I: Word;
Begin
 CfgShell:=1;
 CfS:=CfgSegGet;
 If Mem[CfS:12]=0 Then Exit;
 FillChar(PB,SizeOf(PB),0);
 FillChar(F,SizeOf(F),0);
 Shell:='';
 For I:=1 To Mem[CfS:12] Do Shell:=Shell+Chr(Mem[CfS:12+I]);
 PB.CommandLine:=Ptr(CfS,76);
 PB.FCB1:=@F;
 PB.FCB2:=@F;
 CfgShell:=DOS4Bh_ExecProgram(0,Shell,PB);
End;

{ Charge et exécute le processeur de commandes }
Function LoadAndExecuteCommandProcessor:Boolean;
Var
 ParamBlock: ExecParameterBlock;
 Result: Word;
 CommandLine: String;
 FCB1, FCB2: Array[0..15] of Byte;
Begin
 { Préparer les paramètres EXEC }
 FillChar(ParamBlock, SizeOf(ParamBlock), 0);

 { Environnement par défaut (0 = hériter) }
 ParamBlock.Environment:=0;

 { Ligne de commande vide }
 CommandLine:=#0;
 ParamBlock.CommandLine:=@CommandLine;

 { FCB vides }
 FillChar(FCB1, SizeOf(FCB1), 0);
 FillChar(FCB2, SizeOf(FCB2), 0);
 ParamBlock.FCB1:=@FCB1;
 ParamBlock.FCB2:=@FCB2;

 Result:=CfgShell;
 { Essayer de charger COMMAND.COM en premier }
 If Result <> 0 Then Result:=DOS4Bh_ExecProgram(0, '\COMMAND.COM',
   ParamBlock);
 If Result <> 0 Then Begin
  { Si COMMAND.COM échoue, essayer COMMAND.EXE }
  Result:=DOS4Bh_ExecProgram(0, '\COMMAND.EXE', ParamBlock);
  If Result <> 0 Then Begin
   { Si les deux échouent, essayer dans le répertoire courant }
   Result:=DOS4Bh_ExecProgram(0, 'COMMAND.COM', ParamBlock);
   If Result <> 0 Then Begin
    { Dernier essai avec COMMAND.EXE local }
    Result:=DOS4Bh_ExecProgram(0, 'COMMAND.EXE', ParamBlock);
   End;
  End;
 End;

 LoadAndExecuteCommandProcessor:=Result=0;
End;

{ Fonctions utilitaires de base pour éviter les dépendances SYSTEM.PAS }

{ Convertit une chaîne en majuscules - Version noyau DOS }
{ Exemple: UpperCase('Hello') retourne 'HELLO' }
Function UpperCase(S:String):String;
Var
 I: Byte;
 Result: String;
Begin
 Result:=S;
 For I:=1 To Length(Result) Do Begin
  If (Result[I] >= 'a') And (Result[I] <= 'z') Then
   Result[I]:=Chr(Ord(Result[I]) - 32);
 End;
 UpperCase:=Result;
End;

{ Trouve la position d'une sous-chaîne dans une chaîne - Version noyau DOS }
{ Exemple: Pos('COM', 'COMMAND.COM') retourne 9 }
{ Retourne 0 si la sous-chaîne n'est pas trouvée }
Function Pos(SubStr:String;S:String):Byte;
Var
 I, J: Byte;
 Found: Boolean;
 SubLen, StrLen: Byte;
Begin
 Pos:=0;
 SubLen:=Length(SubStr);
 StrLen:=Length(S);

 { Vérifier les cas limites }
 If (SubLen = 0) Or (StrLen = 0) Or (SubLen > StrLen) Then Exit;

 { Rechercher la sous-chaîne }
 For I:=1 To (StrLen - SubLen + 1) Do Begin
  Found:=True;
  For J:=1 To SubLen Do Begin
   If S[I + J - 1] <> SubStr[J] Then Begin
    Found:=False;
    Break;
   End;
  End;

  If Found Then Begin
   Pos:=I;
   Exit;
  End;
 End;
End;

{ Fonction pour comparer un nom de fichier avec un masque (wildcards * et ?) }
Function MatchFileName(FileName:String;Mask:String):Boolean;
Var
 FI, MI: Byte; { Index pour FileName et Mask }
 FLen, MLen: Byte;
Begin
 MatchFileName:=False;
 FI:=1; MI:=1;
 FLen:=Length(FileName);
 MLen:=Length(Mask);

 While (FI <= FLen) And (MI <= MLen) Do Begin
  Case Mask[MI] Of
   '*': Begin
    { Wildcard * - peut correspondre à n'importe quel nombre de caractères }
    Inc(MI);
    If MI > MLen Then Begin
     MatchFileName:=True;
     Exit;
    End;

    { Chercher le prochain caractère non-wildcard dans le masque }
    While (FI <= FLen) Do Begin
     If MatchFileName(Copy(FileName,FI,FLen-FI+1),Copy(Mask,MI,
       MLen-MI+1)) Then Begin
      MatchFileName:=True;
      Exit;
     End;
     Inc(FI);
    End;
    Exit;
   End;

   '?': Begin
    { Wildcard ? - correspond à exactement un caractère }
    Inc(FI);
    Inc(MI);
   End;

   Else Begin
    { Caractère normal - doit correspondre exactement (insensible à la casse) }
    If UpperCase(FileName[FI]) <> UpperCase(Mask[MI]) Then Exit;
    Inc(FI);
    Inc(MI);
   End;
  End;
 End;

 { Vérifier si on a traité tous les caractères }
 If (FI > FLen) Then Begin
  { Si il reste des * à la fin du masque, c'est OK }
  While (MI <= MLen) And (Mask[MI] = '*') Do Inc(MI);
  MatchFileName:=(MI > MLen);
 End;
End;

{ Convertit un nom de fichier DOS 8.3 en chaîne }
Function DOS83ToString(DOS83:Array of Char):String;
Var
 S: String;
 I, N: Byte;
Begin
 N:=0;
 For I:=0 To 7 Do Begin
  If DOS83[I] = ' ' Then Break;
  Inc(N);
  S[N]:=DOS83[I];
 End;
 If DOS83[8] <> ' ' Then Begin
  Inc(N);
  S[N]:='.';
  For I:=8 To 10 Do Begin
   If DOS83[I] = ' ' Then Break;
   Inc(N);
   S[N]:=DOS83[I];
  End;
 End;
 S[0]:=Chr(N);
 DOS83ToString:=S;
End;

{ Fonctions FAT pour accès au répertoire racine }

{ Obtient le secteur de début du répertoire racine }
Function RootSectorOf(Drive:Byte):Word;
Var
 BootSec: BootSectorRec;
Begin
 RootSectorOf:=0;
 If ReadBootSector(Drive,BootSec) Then
  RootSectorOf:=BootSec.ReservedSectors+BootSec.NumberOfFATs*
    BootSec.SectorsPerFAT;
End;

Function RootSizeOf(Drive:Byte):Word;
Var
 BootSec: BootSectorRec;
Begin
 RootSizeOf:=0;
 If ReadBootSector(Drive,BootSec) Then
  RootSizeOf:=(BootSec.RootDirEntries*32+511) Div 512;
End;

Function GetRootDirectorySector:Word;
Var
 Drive: Byte;
Begin
 ASM
  MOV AL,Data.DataMOS.CurrDisk
  MOV Drive,AL
 END;
 GetRootDirectorySector:=RootSectorOf(Drive);
End;

Function GetRootDirectorySize:Word;
Var
 Drive: Byte;
Begin
 ASM
  MOV AL,Data.DataMOS.CurrDisk
  MOV Drive,AL
 END;
 GetRootDirectorySize:=RootSizeOf(Drive);
End;

{ Lecture simplifiée d'un secteur pour Find File }
Function ReadSectorSimple(Sector:Word;Var Buffer):Boolean;
Var
 Drive: Byte;
Begin
 ASM
  MOV AL,Data.DataMOS.CurrDisk
  MOV Drive,AL
 END;
 ReadSectorSimple:=ReadSector(Drive,Sector,@Buffer);
End;

{ Écriture simplifiée d'un secteur avec vérification optionnelle }
Function WriteSectorSimple(Sector:Word;Var Buffer):Boolean;
Var
 DriveNum: Byte;
 Head, Track, SectorNum: Byte;
 WriteSuccess: Byte;
 WriteResult: Boolean;
Begin
 WriteResult := False;
 WriteSuccess := 0;

 { Calculer les paramètres CHS pour le lecteur C: (disque dur) }
 DriveNum := $80;  { Premier disque dur }

 { Conversion LBA vers CHS (supposons géométrie standard 63 secteurs/piste,
   16 têtes) }
 Head := (Sector DIV 63) MOD 16;
 Track := Sector DIV (63 * 16);
 SectorNum := (Sector MOD 63) + 1;  { Les secteurs commencent à 1 }

 { Préparer les registres pour INT 13h, fonction 03h (écriture secteur) }
 ASM
  { Sauvegarder les registres importants }
  PUSH AX
  PUSH BX
  PUSH CX
  PUSH DX
  PUSH ES

  { Paramètres pour INT 13h fonction 03h }
  MOV AH, 03h           { Fonction écriture secteur }
  MOV AL, 1             { Nombre de secteurs à écrire }
  MOV DL, DriveNum      { Lecteur }
  MOV DH, Head          { Tête }
  MOV CH, Track         { Piste (cylindre) }
  MOV CL, SectorNum     { Secteur }

  { Pointer ES:BX vers le buffer }
  LES BX, Buffer

  { Appeler l'interruption BIOS }
  INT 13h

  { Vérifier le résultat (CF=0 si succès) }
  JC @WriteError

  { Succès }
  MOV WriteSuccess, 1
  JMP @WriteDone

@WriteError:
  { Erreur }
  MOV WriteSuccess, 0

@WriteDone:
  { Restaurer les registres }
  POP ES
  POP DX
  POP CX
  POP BX
  POP AX
 END;

 { Assigner le résultat }
 WriteResult := (WriteSuccess <> 0);

 { Si la vérification est activée, vérifier l'écriture }
 If WriteResult And (GetVerifyFlag <> 0) Then Begin
  WriteResult := VerifyWrite(DriveNum And $7F, Sector, @Buffer, 512);
 End;

 { Retourner le résultat final }
 WriteSectorSimple := WriteResult;
End;

{ Fonctions d'accès aux données du kernel dans le Code Segment }

{ Obtient l'état de recherche de fichiers depuis le Code Segment }
{ Sauvegarde l'état de recherche de fichiers dans le Code Segment }
{ Fonctions 4Ch et 4Dh - Terminaison et code de retour }

{ Fonction 4Ch - Terminate Program }
Function DOS4Ch_TerminateProgram(ExitCode:Byte):Word;
Var
 Cur,Parent: Word;
Begin
 DOS4Ch_TerminateProgram:=0;
 Cur:=GetCurrentPSP;
 If (Cur=0) Or (MemW[Cur:$2E]=0) Then Begin
  { aucun programme lance par EXEC : le noyau s'arrete }
  ASM
   CLI
   HLT
  END;
  Exit;
 End;
 Parent:=MemW[Cur:$16];
 SetLastReturnCode(ExitCode);
 JftReleaseAll(Cur);
 If Parent=Cur Then Begin
  { processeur de commandes principal : plus de processus courant (le noyau
    relancera COMMAND) }
  SetCurrentPSP(0);
  SetDTA($9000,0);
 End Else Begin
  SetCurrentPSP(Parent);
  SetDTA(Parent,$80);
 End;
 FreeProcessMemory(Cur);
 ASM
  DEC Data.DataMOS.InDos
 END;
 ExecReturn(Cur);
End;

{ Fonction 31h - Terminate and Stay Resident : le bloc du programme est reduit a
  Paras paragraphes
  (6 au minimum) et reste alloue ;
    ne revient pas si le programme a ete lance par EXEC }
Function DOS31h_Keep(ExitCode:Byte;Paras:Word):Word;
Var
 Cur,Parent: Word;
Begin
 DOS31h_Keep:=1;
 Cur:=GetCurrentPSP;
 If (Cur=0) Or (MemW[Cur:$2E]=0) Then Exit;
 If Paras<6 Then Paras:=6;
 DOS4Ah_ModifyMemory(Cur,Paras);
 Parent:=MemW[Cur:$16];
 SetLastReturnCode(ExitCode);
 If Parent=Cur Then Begin
  SetCurrentPSP(0);
  SetDTA($9000,0);
 End Else Begin
  SetCurrentPSP(Parent);
  SetDTA(Parent,$80);
 End;
 ASM
  DEC Data.DataMOS.InDos
 END;
 ExecReturn(Cur);
End;

{ Fonction 4Dh - Get Return Code }
Function DOS4Dh_GetReturnCode:Word;
Var
 ReturnCode: Word;
Begin
 { Obtenir le code de retour du dernier programme terminé }
 ReturnCode:=GetLastReturnCode;

 { Effacer le code de retour après lecture (comportement DOS) }
 SetLastReturnCode(0);

 DOS4Dh_GetReturnCode:=ReturnCode;
End;

{ Fonctions 4Eh et 4Fh - Find First/Next File }

{ Fonction 4Eh - Find First File }
Function DOS4Eh_FindFirstFile(Path:String;Attr:Byte;var DTA:DTAStruct):Word;
Begin
 DOS4Eh_FindFirstFile:=FxFindFirst(Path,Attr,DTA);
End;
{ Fonction 4Fh - Find Next File }
Function DOS4Fh_FindNextFile(var DTA:DTAStruct):Word;
Begin
 DOS4Fh_FindNextFile:=FxFindFrom(DTA);
End;
{ Fonctions 50h et 51h - Gestion PSP (Program Segment Prefix) }

{ Fonction 50h - Set PSP Address }
Function DOS50h_SetPSPAddress(PSPSegment:Word):Word;
Begin
 DOS50h_SetPSPAddress:=0; { Succès par défaut }

 { Valider que le segment PSP est valide }
 If PSPSegment < ArenaBase Then Begin { En-dessous de la zone conventionnelle }
  DOS50h_SetPSPAddress:=1; { Erreur : segment invalide }
  Exit;
 End;

 If PSPSegment > $A000 Then Begin { Au-dessus de 640KB }
  DOS50h_SetPSPAddress:=1; { Erreur : segment invalide }
  Exit;
 End;

 { Sauvegarder le nouveau PSP courant }
 SetCurrentPSP(PSPSegment);

 { Dans un vrai DOS, on pourrait aussi vérifier que le segment }
 { contient réellement un PSP valide (signature INT 20h, etc.) }

 DOS50h_SetPSPAddress:=0; { Succès }
End;

{ Fonction 51h - Get PSP Address }
Function DOS51h_GetPSPAddress:Word;
Begin
 { Retourner l'adresse du PSP courant }
 DOS51h_GetPSPAddress:=GetCurrentPSP;
End;

{ Fonctions 52h et 53h - Structures internes DOS }

{ Fonction 52h - Get List of Lists }
Function DOS52h_GetListOfLists:Pointer;Assembler;
ASM
 MOV DX,CS
 MOV AX,OFFSET Data
 ADD AX,FxBase+130            { Liste des Listes (apres CfgSeg et le mot du
   premier MCB) }
END;

{ Fonction 53h - Translate BPB to DPB }
Function DOS53h_TranslateBPBtoDPB(BPBPtr:Pointer;DPBPtr:Pointer):Word;
Var
 BPB: BIOSParameterBlock;
 DPB: DriveParameterBlock;
 SectorsPerCluster: Byte;
 Temp: Word;
Begin
 DOS53h_TranslateBPBtoDPB:=$FFFF; { Erreur par défaut }

 { Vérifier que les pointeurs ne sont pas nuls }
 If (BPBPtr = Nil) Or (DPBPtr = Nil) Then Exit;

 { Copier le BPB depuis l'adresse fournie }
 ASM
  PUSH DS
  PUSH ES
  LDS SI,BPBPtr
  LEA DI,BPB
  PUSH SS
  POP ES
  MOV CX,TYPE BIOSParameterBlock
  CLD
  REP MOVSB
  POP ES
  POP DS
 END;

 { Convertir BPB vers DPB }
 FillChar(DPB, SizeOf(DPB), 0);

 { Copier les champs de base }
 DPB.BytesPerSector:=BPB.BytesPerSector;
 DPB.ReservedSectors:=BPB.ReservedSectors;
 DPB.NumberOfFATs:=BPB.NumberOfFATs;
 DPB.MaxRootEntries:=BPB.RootDirEntries;
 DPB.SectorsPerFAT:=BPB.SectorsPerFAT;
 DPB.MediaID:=BPB.MediaDescriptor;

 { Calculer les champs dérivés }
 SectorsPerCluster:=BPB.SectorsPerCluster;
 DPB.LastSectorInCluster:=SectorsPerCluster - 1;

 { Calculer le décalage pour secteurs par cluster (log2) }
 DPB.SectorsPerClusterShift:=0;
 Temp:=SectorsPerCluster;
 While Temp > 1 Do Begin
  Temp:=Temp Shr 1;
  Inc(DPB.SectorsPerClusterShift);
 End;

 { Calculer secteur de début des données }
 DPB.FirstDirSector:=BPB.ReservedSectors + (BPB.NumberOfFATs *
   BPB.SectorsPerFAT);
 DPB.FirstDataSector:=DPB.FirstDirSector + ((BPB.RootDirEntries * 32) div
   BPB.BytesPerSector);

 { Calculer nombre total de clusters }
 If BPB.TotalSectors = 0 Then
  Temp:=BPB.TotalSectorsLarge
 Else
  Temp:=BPB.TotalSectors;

 DPB.HighestCluster:=(Temp - DPB.FirstDataSector) div SectorsPerCluster + 1;

 { Initialiser autres champs }
 DPB.DriveNumber:=0; { A: par défaut }
 DPB.UnitNumber:=0;
 DPB.AccessFlag:=0;
 DPB.NextDPB:=Nil;
 DPB.FirstFreeCluster:=2; { Premier cluster utilisable }
 DPB.NumberFreeClusters:=$FFFF; { Inconnu }

 { Copier le DPB vers l'adresse de destination }
 ASM
  PUSH ES
  PUSH DS
  LES DI,DPBPtr
  LEA SI,DPB
  PUSH SS
  POP DS
  MOV CX,TYPE DriveParameterBlock
  CLD
  REP MOVSB
  POP DS
  POP ES
 END;

 DOS53h_TranslateBPBtoDPB:=0; { Succès }
End;

{ Fonctions 2Eh et 54h - Vérification en écriture avec vraies vérifications }

{ Fonction utilitaire - Vérifier l'écriture d'un secteur }
Function VerifyWrite(Drive:Byte;Sector:LongInt;Buffer:Pointer;
  Size:Word):Boolean;
Var
 VerifyBuffer: Array[0..511] of Byte;
 I: Word;
 Success: Boolean;
Begin
 VerifyWrite:=False;

 { Si la vérification est désactivée, retourner succès immédiatement }
 If GetVerifyFlag = 0 Then Begin
  VerifyWrite:=True;
  Exit;
 End;

 { Relire le secteur qui vient d'être écrit }
 Success:=ReadSectorSimple(Sector, VerifyBuffer);
 If Not Success Then Exit;

 { Comparer octet par octet avec le buffer original }
 ASM
  PUSH DS
  PUSH ES

  LDS SI,Buffer               { DS:SI = buffer original }
  LEA DI,VerifyBuffer         { ES:DI = buffer relu }
  PUSH SS
  POP ES
  MOV CX,Size                 { Nombre d'octets à comparer }
  CLD                         { Direction forward }
  REPE CMPSB                  { Comparer les chaînes }
  JNZ @VerifyFailed          { Si différent, échec }

  { Vérification réussie }
  MOV Success,1
  JMP @VerifyEnd

@VerifyFailed:
  MOV Success,0

@VerifyEnd:
  POP ES
  POP DS
 END;

 VerifyWrite:=Success;
End;

{ Fonction utilitaire - Écrire un secteur avec vérification }
Function WriteSectorWithVerify(Drive:Byte;Sector:LongInt;
  Buffer:Pointer):Boolean;
Var
 WriteSuccess: Boolean;
 VerifySuccess: Boolean;
 Retries: Byte;
Begin
 WriteSectorWithVerify:=False;

 { Essayer l'écriture avec jusqu'à 3 tentatives }
 For Retries:=1 To 3 Do Begin
  { Écrire le secteur }
  WriteSuccess:=True; { Simulation écriture pour l'instant }

  If WriteSuccess Then Begin
   { Si la vérification est activée, vérifier l'écriture }
   VerifySuccess:=VerifyWrite(Drive, Sector, Buffer, 512);

   If VerifySuccess Then Begin
    WriteSectorWithVerify:=True;
    Exit; { Succès complet }
   End Else Begin
    { Vérification échouée - réessayer }
    Continue;
   End;
  End;
 End;

 { Toutes les tentatives ont échoué }
 WriteSectorWithVerify:=False;
End;

{ Fonction 2Eh - Set/Reset Verify Flag }
{ Entrée: AL = 0 (désactiver) ou 1 (activer) la vérification }
{ Sortie: AX = 0 (succès) ou 1 (fonction invalide) }
Function DOS2Eh_SetVerifyFlag(VerifyState:Byte):Word;
Begin
 DOS2Eh_SetVerifyFlag:=0; { Succès par défaut }

 { Valider le paramètre (0=off, 1=on, autres valeurs = erreur) }
 If VerifyState > 1 Then Begin
  DOS2Eh_SetVerifyFlag:=1; { Fonction invalide }
  Exit;
 End;

 { Mettre à jour le flag de vérification dans le Code Segment }
 SetVerifyFlag(VerifyState);

 { Dans un vrai DOS, cette fonction pourrait aussi :
   - Configurer le contrôleur de disque pour la vérification matérielle
   - Notifier les drivers de périphériques du changement d'état
   - Mettre à jour les paramètres BIOS si nécessaire }

 { Forcer un flush des buffers disque si on active la vérification }
 If VerifyState = 1 Then Begin
  { Simuler un flush des buffers - dans un vrai DOS, cela forcerait
    l'écriture de tous les buffers sales sur disque }
 End;

 DOS2Eh_SetVerifyFlag:=0; { Succès }
End;

{ Fonction 54h - Get Verify Flag }
{ Entrée: Aucune }
{ Sortie: AL = état actuel (0=désactivé, 1=activé) }
Function DOS54h_GetVerifyFlag:Byte;
Var
 CurrentFlag: Byte;
Begin
 { Obtenir l'état actuel du flag de vérification depuis le Code Segment }
 CurrentFlag := GetVerifyFlag;

 { S'assurer que la valeur retournée est valide (0 ou 1) }
 If CurrentFlag > 1 Then
  CurrentFlag := 0; { Valeur par défaut si corrompue }

 DOS54h_GetVerifyFlag := CurrentFlag;

 { Note : Cette fonction est utilisée par :
   - Les utilitaires système pour vérifier l'état de vérification
   - Les programmes qui veulent adapter leur comportement selon l'état
   - Les shells pour afficher l'état du système }
End;

{ Fonction 55h - Create Child PSP }
{ Entrée: DX = segment où créer le nouveau PSP }
{ Sortie: AX = 0 (succès) ou code d'erreur }
Function DOS55h_CreateChildPSP(NewPSPSegment:Word):Word;
Var
 CurrentPSP: Word;
 NewPSP: ProgramSegmentPrefix;
 I: Integer;
Begin
 DOS55h_CreateChildPSP := 8; { Insufficient memory par défaut }

 { Vérifier que le segment est valide }
 If NewPSPSegment < ArenaBase Then Begin { En-dessous de la zone conventionnelle
   }
  DOS55h_CreateChildPSP := 7; { Memory control blocks destroyed }
  Exit;
 End;

 If NewPSPSegment > $9FFF Then Begin { Au-dessus de 640KB }
  DOS55h_CreateChildPSP := 7; { Memory control blocks destroyed }
  Exit;
 End;

 { Obtenir le PSP courant comme parent }
 CurrentPSP := GetCurrentPSP;
 If CurrentPSP = 0 Then CurrentPSP := $1000; { PSP par défaut }

 { Initialiser le nouveau PSP }
 FillChar(NewPSP, SizeOf(NewPSP), 0);

 { INT 20h instruction (CD 20) au début du PSP }
 NewPSP.Int20h := $20CD;

 { Segment du haut de la mémoire (calculé à partir du segment + 256 bytes) }
 NewPSP.TopOfMemory := NewPSPSegment + $10; { +256 bytes en paragraphes }

 { Call to DOS dispatcher (9A 00 00 00 F0) }
 NewPSP.CallToDispatcher[0] := $9A;
 NewPSP.CallToDispatcher[1] := $00;
 NewPSP.CallToDispatcher[2] := $00;
 NewPSP.CallToDispatcher[3] := $00;
 NewPSP.CallToDispatcher[4] := $F0;

 { PSP parent }
 NewPSP.ParentPSP := CurrentPSP;

 { Copier la table des handles du parent }
 ASM
  PUSH DS
  PUSH ES
  PUSH SI
  PUSH DI

  { Lire les handles du PSP parent }
  MOV AX, CurrentPSP
  MOV DS, AX
  MOV SI, 18h        { Offset de la table des handles dans le PSP }

  { Copier vers le nouveau PSP }
  PUSH SS
  POP ES
  LEA DI, NewPSP.HandleTable
  MOV CX, 20         { 20 handles à copier }
  CLD
  REP MOVSB

  POP DI
  POP SI
  POP ES
  POP DS
 END;

 { Taille table handles }
 NewPSP.HandleTableSize := 20;
 NewPSP.HandleTablePtr := Ptr(NewPSPSegment, $18); { Pointe vers la table }

 { DOS call (CD 21 CB) }
 NewPSP.DOSCall[0] := $CD;
 NewPSP.DOSCall[1] := $21;
 NewPSP.DOSCall[2] := $CB; { RETF }

 { Copier l'environnement du parent }
 ASM
  PUSH DS
  MOV AX, CurrentPSP
  MOV DS, AX
  MOV AX, [2Ch]      { Offset de l'environnement dans le PSP }
  MOV NewPSP.Environment, AX
  POP DS
 END;

 { Copier le PSP complet en mémoire au segment spécifié }
 ASM
  PUSH DS
  PUSH ES
  PUSH SI
  PUSH DI

  { Source: notre structure NewPSP }
  PUSH SS
  POP DS
  LEA SI, NewPSP

  { Destination: segment spécifié }
  MOV AX, NewPSPSegment
  MOV ES, AX
  MOV DI, 0

  { Copier 256 bytes (taille d'un PSP) }
  MOV CX, 256
  CLD
  REP MOVSB

  POP DI
  POP SI
  POP ES
  POP DS
 END;

 DOS55h_CreateChildPSP := 0; { Succès }

 { Note: Cette fonction était principalement utilisée dans DOS 1.x et 2.x
   Elle a été largement remplacée par les fonctions 26h et 4Bh dans les
   versions ultérieures, mais reste disponible pour compatibilité }
End;

{ Fonctions utilitaires pour opérations FAT réelles - Utilisent INT 25h/26h }

{ Lire un secteur de FAT avec INT 25h }
Function ReadFATSector(Drive:Byte;Sector:Word;Var Buffer):Boolean;
Var
 DriveNum: Byte;
 Result: Boolean;
Begin
 Result := False;

 { Convertir numéro de lecteur (0=A:, 1=B:, 2=C:) }
 DriveNum := Drive;

 { Utiliser INT 25h pour lire le secteur }
 ASM
  PUSH AX
  PUSH BX
  PUSH CX
  PUSH DX
  PUSH DS

  MOV AL, DriveNum       { Lecteur }
  MOV DX, Sector         { Secteur à lire }
  MOV CX, 1              { Nombre de secteurs }
  LDS BX, Buffer         { DS:BX pointe vers le buffer }

  INT 25h                { Lecture absolue de secteur }
  JC @ReadFATError

  MOV Result, 1          { Succès }
  JMP @ReadFATDone

@ReadFATError:
  MOV Result, 0          { Erreur }

@ReadFATDone:
  POPF                   { INT 25h laisse des flags sur la pile }
  POP DS
  POP DX
  POP CX
  POP BX
  POP AX
 END;

 ReadFATSector := Result;
End;

{ Écrire un secteur de FAT avec INT 26h }
Function WriteFATSector(Drive:Byte;Sector:Word;Var Buffer):Boolean;
Var
 DriveNum: Byte;
 Result: Boolean;
Begin
 Result := False;

 DriveNum := Drive;

 { Utiliser INT 26h pour écrire le secteur }
 ASM
  PUSH AX
  PUSH BX
  PUSH CX
  PUSH DX
  PUSH DS

  MOV AL, DriveNum       { Lecteur }
  MOV DX, Sector         { Secteur à écrire }
  MOV CX, 1              { Nombre de secteurs }
  LDS BX, Buffer         { DS:BX pointe vers le buffer }

  INT 26h                { Écriture absolue de secteur }
  JC @WriteFATError

  MOV Result, 1          { Succès }
  JMP @WriteFATDone

@WriteFATError:
  MOV Result, 0          { Erreur }

@WriteFATDone:
  POPF                   { INT 26h laisse des flags sur la pile }
  POP DS
  POP DX
  POP CX
  POP BX
  POP AX
 END;

 WriteFATSector := Result;
End;

{ Lire un secteur de répertoire avec INT 25h }
Function ReadDirectorySector(Drive:Byte;Sector:Word;Var Buffer):Boolean;
Begin
 { Même implémentation que ReadFATSector - la différence est conceptuelle }
 ReadDirectorySector := ReadFATSector(Drive, Sector, Buffer);
End;

{ Écrire un secteur de répertoire avec INT 26h }
Function WriteDirectorySector(Drive:Byte;Sector:Word;Var Buffer):Boolean;
Var
 WriteResult: Boolean;
Begin
 { Même implémentation que WriteFATSector - avec vérification si activée }
 WriteResult := WriteFATSector(Drive, Sector, Buffer);

 { Si la vérification est activée, vérifier l'écriture }
 If WriteResult And (GetVerifyFlag <> 0) Then Begin
  WriteResult := VerifyWrite(Drive, Sector, @Buffer, 512);
 End;

 WriteDirectorySector := WriteResult;
End;

{ Analyser un chemin complet en drive, répertoire et nom de fichier }
Function ParseFullPath(Path:String;Var Drive:Byte;Var DirPath,
  FileName:String):Boolean;
Var
 ColonPos, LastSlashPos: Byte;
 I: Byte;
 FoundSlash: Boolean;
Begin
 ParseFullPath := False;
 Drive := 2; { C: par défaut }
 DirPath := '';
 FileName := '';

 If Length(Path) = 0 Then Exit;

 { Chercher le drive (X:) }
 ColonPos := Pos(':', Path);
 If ColonPos = 2 Then Begin
  Case UpCase(Path[1]) Of
   'A': Drive := 0;
   'B': Drive := 1;
   'C': Drive := 2;
   'D': Drive := 3;
   'E': Drive := 4;
   'F': Drive := 5;
   'G': Drive := 6;
   'H': Drive := 7;
   'I': Drive := 8;
   'J': Drive := 9;
   'K': Drive := 10;
   'L': Drive := 11;
   'M': Drive := 12;
   'N': Drive := 13;
   'O': Drive := 14;
   'P': Drive := 15;
   'Q': Drive := 16;
   'R': Drive := 17;
   'S': Drive := 18;
   'T': Drive := 19;
   'U': Drive := 20;
   'V': Drive := 21;
   'W': Drive := 22;
   'X': Drive := 23;
   'Y': Drive := 24;
   'Z': Drive := 25;
  End;
  Delete(Path, 1, 2); { Enlever "X:" }
 End;

 { Chercher le dernier backslash pour séparer répertoire et fichier }
 LastSlashPos := 0;
 FoundSlash := False;
 For I := Length(Path) DownTo 1 Do Begin
  If Path[I] = '\' Then Begin
   LastSlashPos := I;
   FoundSlash := True;
   Break;
  End;
 End;

 If FoundSlash Then Begin
  DirPath := Copy(Path, 1, LastSlashPos - 1);
  FileName := Copy(Path, LastSlashPos + 1, 255);
 End Else Begin
  DirPath := '';
  FileName := Path;
 End;

 { Valider le nom de fichier (pas vide) }
 If Length(FileName) = 0 Then Exit;

 ParseFullPath := True;
End;

{ Chercher une entrée de répertoire par nom }
Function FindDirectoryEntryByName(Drive:Byte;DirCluster:Word;
                                  FileName:String;
                                  Var Entry:DirectoryEntryFAT;
                                  Var EntryOffset:Word):Boolean;
Var
 Buffer: Array[0..511] of Byte;
 RootSector, Sector: Word;
 I: Byte;
 DirEntry: ^DirectoryEntryFAT;
 EntryName: String;
Begin
 FindDirectoryEntryByName := False;
 EntryOffset := 0;

 { Pour cette implémentation, on cherche dans le répertoire racine }
 { Dans un système complet, on suivrait la chaîne de clusters }

 { Calculer le secteur de début du répertoire racine }
 RootSector := RootSectorOf(Drive);

 { Parcourir les secteurs du répertoire racine }
 For Sector := RootSector To RootSector + 31 Do Begin { Max 32 secteurs }
  If Not ReadDirectorySector(Drive, Sector, Buffer) Then Continue;

  { Examiner chaque entrée de 32 bytes dans le secteur }
  For I := 0 To 15 Do Begin { 16 entrées par secteur }
   DirEntry := @Buffer[I * 32];

   { Entrée libre ? }
   If DirEntry^.FileName[0] = #0 Then Break;
   { Entrée supprimée ? }
   If DirEntry^.FileName[0] = #$E5 Then Continue;

   { Convertir le nom 8.3 en chaîne }
   EntryName := DOS83ToString(DirEntry^.FileName);

   { Comparaison insensible à la casse }
   If UpperCase(EntryName) = UpperCase(FileName) Then Begin
    { Trouvé ! Copier l'entrée }
    Move(DirEntry^, Entry, SizeOf(DirectoryEntryFAT));
    EntryOffset := (Sector - RootSector) * 16 + I;
    FindDirectoryEntryByName := True;
    Exit;
   End;
  End;
 End;
End;

{ Mettre à jour le nom dans une entrée de répertoire }
Function UpdateDirectoryEntryName(Drive:Byte;DirCluster:Word;EntryOffset:Word;
  NewName:String):Boolean;
Var
 Buffer: Array[0..511] of Byte;
 RootSector, TargetSector: Word;
 EntryIndex: Byte;
 DirEntry: ^DirectoryEntryFAT;
 DOS83Name: Array[0..10] of Char;
 I: Byte;
 DotPos: Byte;
Begin
 UpdateDirectoryEntryName := False;

 { Calculer le secteur et l'index de l'entrée }
 RootSector := RootSectorOf(Drive);

 TargetSector := RootSector + (EntryOffset DIV 16);
 EntryIndex := EntryOffset MOD 16;

 { Lire le secteur contenant l'entrée }
 If Not ReadDirectorySector(Drive, TargetSector, Buffer) Then Exit;

 { Pointer vers l'entrée }
 DirEntry := @Buffer[EntryIndex * 32];

 { Convertir le nouveau nom en format 8.3 }
 FillChar(DOS83Name, 11, Byte(' ')); { Remplir avec des espaces }

 DotPos := Pos('.', NewName);
 If DotPos > 0 Then Begin
  { Nom avec extension }
  For I := 1 To DotPos - 1 Do Begin
   If I > 8 Then Break;
   DOS83Name[I - 1] := UpCase(NewName[I]);
  End;
  For I := DotPos + 1 To Length(NewName) Do Begin
   If (I - DotPos) > 3 Then Break;
   DOS83Name[8 + (I - DotPos) - 1] := UpCase(NewName[I]);
  End;
 End Else Begin
  { Nom sans extension }
  For I := 1 To Length(NewName) Do Begin
   If I > 8 Then Break;
   DOS83Name[I - 1] := UpCase(NewName[I]);
  End;
 End;

 { Mettre à jour l'entrée }
 Move(DOS83Name, DirEntry^.FileName, 11);

 { Réécrire le secteur }
 UpdateDirectoryEntryName := WriteDirectorySector(Drive, TargetSector, Buffer);
End;

{ Fonction principale 56h - Rename/Move File }
{ Entrée: DS:DX pointe vers l'ancien nom, ES:DI vers le nouveau nom }
{ Sortie: AX = 0 (succès) ou code d'erreur DOS }
Function DOS56h_RenameFile(OldPathPtr:Pointer;NewPathPtr:Pointer):Word;
Begin
 DOS56h_RenameFile:=FxRename(OldPathPtr,NewPathPtr);
End;
{ Fonctions utilitaires pour gestion des dates/heures DOS }

{ Convertit les composants date/heure en format DOS }
Function PackDOSDateTime(Year,Month,Day,Hour,Minute,Second:Word):LongInt;
Var
 DOSDate, DOSTime: Word;
Begin
 { Format DOS Date: bits 15-9=année-1980, bits 8-5=mois, bits 4-0=jour }
 DOSDate := ((Year - 1980) SHL 9) OR (Month SHL 5) OR Day;

 { Format DOS Time: bits 15-11=heures, bits 10-5=minutes, bits 4-0=secondes/2 }
 DOSTime := (Hour SHL 11) OR (Minute SHL 5) OR (Second SHR 1);

 { Retourner comme LongInt: high word = date, low word = time }
 PackDOSDateTime := (LongInt(DOSDate) SHL 16) OR DOSTime;
End;

{ Extrait les composants d'une date/heure DOS }
{ Obtient l'offset d'une entrée de répertoire par son handle }
Function GetDirectoryOffsetByHandle(Handle:Word;Var Drive:Byte;
  Var EntryOffset:Word):Boolean;
Var
 FileEntry: FileTableEntry;
 SearchResult: Boolean;
Begin
 GetDirectoryOffsetByHandle := False;

 { Vérifier la validité du handle }
 If Handle >= 20 Then Exit;

 { Obtenir l'entrée de la table des fichiers }
 If Not GetFileTableEntry(Handle, FileEntry) Then Exit;

 { Vérifier si le handle est utilisé }
 If Not FileEntry.InUse Then Exit;

 Drive := FileEntry.Drive;

 { Pour cette implémentation, nous utilisons une recherche simplifiée }
 { Dans un vrai DOS, l'offset serait maintenu dans la table des fichiers }
 EntryOffset := Handle * 32; { Approximation basique }

 GetDirectoryOffsetByHandle := True;
End;

{ Met à jour la date/heure dans une entrée de répertoire }
Function UpdateDirectoryDateTime(Drive:Byte;EntryOffset:Word;NewDate,
  NewTime:Word):Boolean;
Var
 Sector: Word;
 Buffer: Array[0..511] Of Byte;
 EntryInSector: Word;
 Entry: DirectoryEntryFAT;
 UpdateResult: Boolean;
Begin
 UpdateResult := False;

 { Calculer le secteur et l'offset dans le secteur }
 Sector := GetRootDirectorySector + (EntryOffset DIV 512);
 EntryInSector := EntryOffset MOD 512;

 { Lire le secteur de répertoire }
 If Not ReadDirectorySector(Drive, Sector, Buffer) Then Exit;

 { Vérifier que l'entrée est dans les limites du secteur }
 If (EntryInSector + SizeOf(DirectoryEntryFAT)) > 512 Then Exit;

 { Copier l'entrée depuis le buffer }
 Move(Buffer[EntryInSector], Entry, SizeOf(DirectoryEntryFAT));

 { Vérifier que ce n'est pas une entrée vide ou supprimée }
 If (Entry.FileName[0] = #0) Or (Entry.FileName[0] = #$E5) Then Exit;

 { Mettre à jour les champs date/heure }
 Entry.Time := NewTime;
 Entry.Date := NewDate;

 { Copier l'entrée modifiée dans le buffer }
 Move(Entry, Buffer[EntryInSector], SizeOf(DirectoryEntryFAT));

 { Écrire le secteur modifié }
 UpdateResult := WriteDirectorySector(Drive, Sector, Buffer);

 UpdateDirectoryDateTime := UpdateResult;
End;

{ Obtient la date/heure d'une entrée de répertoire }
Function GetDirectoryDateTime(Drive:Byte;EntryOffset:Word;Var Date,
  Time:Word):Boolean;
Var
 Sector: Word;
 Buffer: Array[0..511] Of Byte;
 EntryInSector: Word;
 Entry: DirectoryEntryFAT;
Begin
 GetDirectoryDateTime := False;

 { Calculer le secteur et l'offset dans le secteur }
 Sector := GetRootDirectorySector + (EntryOffset DIV 512);
 EntryInSector := EntryOffset MOD 512;

 { Lire le secteur de répertoire }
 If Not ReadDirectorySector(Drive, Sector, Buffer) Then Exit;

 { Vérifier que l'entrée est dans les limites du secteur }
 If (EntryInSector + SizeOf(DirectoryEntryFAT)) > 512 Then Exit;

 { Copier l'entrée depuis le buffer }
 Move(Buffer[EntryInSector], Entry, SizeOf(DirectoryEntryFAT));

 { Vérifier que ce n'est pas une entrée vide ou supprimée }
 If (Entry.FileName[0] = #0) Or (Entry.FileName[0] = #$E5) Then Exit;

 { Récupérer les champs date/heure }
 Date := Entry.Date;
 Time := Entry.Time;

 GetDirectoryDateTime := True;
End;

{ Fonction principale 57h - Get/Set File Date and Time }
Function DOS57h_GetSetFileDateTime(Handle:Word;Action:Byte;NewDate,
  NewTime:Word):LongInt;
Var
 Buf:TFxSec;
 Sec:LongInt;
 P:Word;
 Drive:Byte;
Begin
 DOS57h_GetSetFileDateTime:=$FFFFFFFF;
 If Action>1 Then Begin
  SetStandardError(1);
  Exit;
 End;
 If (Handle<5) Or (Handle>=20) Then Begin
  SetStandardError(6);
  Exit;
 End;
 If Not GetFileTableInUse(Handle) Then Begin
  SetStandardError(6);
  Exit;
 End;
 Sec:=FxGetSec(Handle);
 If Sec=0 Then Begin
  SetStandardError(6);
  Exit;
 End;
 Drive:=GetFileTableDrive(Handle);
 P:=FxGetIdx(Handle)*32;
 If Not ReadSector(Drive,Sec,@Buf) Then Begin
  SetStandardError(5);
  Exit;
 End;
 If Action=0 Then Begin
  DOS57h_GetSetFileDateTime:=(LongInt(Word(Buf[P+24])+Word(Buf[P+25])*256) Shl
    16) Or
   LongInt(Word(Buf[P+22])+Word(Buf[P+23])*256);
  Exit;
 End;
 Buf[P+22]:=NewTime And $FF;
 Buf[P+23]:=NewTime Shr 8;
 Buf[P+24]:=NewDate And $FF;
 Buf[P+25]:=NewDate Shr 8;
 If Not WriteSector(Drive,Sec,@Buf) Then Begin
  SetStandardError(5);
  Exit;
 End;
 DOS57h_GetSetFileDateTime:=0;
End;

{ Fonctions utilitaires pour la gestion de la stratégie d'allocation mémoire }

{ Obtient la stratégie d'allocation mémoire actuelle depuis le Code Segment }
Function GetMemoryStrategy:Word;
Var
 Strategy: Word;
Begin
 { Lire la stratégie depuis la structure Data dans le Code Segment }
 ASM
  PUSH DS

  { Pointer vers la structure Data.DataMOS }
  MOV AX,CS
  MOV DS,AX
  MOV SI,OFFSET Data.DataMOS

  { Lire le champ MemoryStrategy }
  MOV AX,[SI].DataMOS.MemoryStrategy
  MOV Strategy,AX

  POP DS
 END;

 GetMemoryStrategy := Strategy;
End;

{ Définit la stratégie d'allocation mémoire dans le Code Segment }
Procedure SetMemoryStrategy(NewStrategy:Word);
Begin
 { Sauvegarder la stratégie dans la structure Data dans le Code Segment }
 ASM
  PUSH DS
  PUSH AX

  { Pointer vers la structure Data.DataMOS }
  MOV AX,CS
  MOV DS,AX
  MOV SI,OFFSET Data.DataMOS

  { Écrire le nouveau champ MemoryStrategy }
  MOV AX,NewStrategy
  MOV [SI].DataMOS.MemoryStrategy,AX

  POP AX
  POP DS
 END;
End;

{ Obtient l'état de liaison UMB depuis le Code Segment }
Function GetUMBLinkState:Word;
Var
 LinkState: Word;
Begin
 { Lire l'état de liaison UMB depuis la structure Data dans le Code Segment }
 ASM
  PUSH DS

  { Pointer vers la structure Data.DataMOS }
  MOV AX,CS
  MOV DS,AX
  MOV SI,OFFSET Data.DataMOS

  { Lire le champ UMBLinkState }
  MOV AX,[SI].DataMOS.UMBLinkState
  MOV LinkState,AX

  POP DS
 END;

 GetUMBLinkState := LinkState;
End;

{ Définit l'état de liaison UMB dans le Code Segment }
Procedure SetUMBLinkState(NewState:Word);
Begin
 { Sauvegarder l'état UMB dans la structure Data dans le Code Segment }
 ASM
  PUSH DS
  PUSH AX

  { Pointer vers la structure Data.DataMOS }
  MOV AX,CS
  MOV DS,AX
  MOV SI,OFFSET Data.DataMOS

  { Écrire le nouveau champ UMBLinkState }
  MOV AX,NewState
  MOV [SI].DataMOS.UMBLinkState,AX

  POP AX
  POP DS
 END;
End;

{ Vérifie si les UMB sont disponibles dans le système }
Function AreUMBsAvailable:Boolean;
Begin
 { Pour cette implémentation basique, simuler la disponibilité des UMB }
 { Dans un vrai DOS,
   cela vérifierait la présence d'un gestionnaire UMB comme EMM386 }
 AreUMBsAvailable := True; { Supposer que les UMB sont disponibles }
End;

{ Recherche et lie les blocs de mémoire haute (UMB) }
Function LinkUMBs:Boolean;
Var
 UMBSegment: Word;
 UMBSize: Word;
Begin
 LinkUMBs := False;

 { Pour cette implémentation, simuler la liaison des UMB }
 { Dans un vrai DOS, cela rechercherait les vrais blocs UMB }
 UMBSegment := $D000; { Segment UMB typique }
 UMBSize := $2000;    { Taille typique 128KB }

 { Créer un MCB factice pour l'UMB }
 If CreateMCB(UMBSegment - 1, UMBSize, 0, True) Then
  LinkUMBs := True;
End;

{ Délie les blocs de mémoire haute (UMB) }
Function UnlinkUMBs:Boolean;
Begin
 { Pour cette implémentation, simuler la déliaison des UMB }
 { Dans un vrai DOS, cela retirerait les UMB de la chaîne MCB }
 UnlinkUMBs := True;
End;

{ Recherche de bloc mémoire avec stratégie First Fit }
Function FindMemoryFirstFit(Size:Word;Var Segment:Word):Boolean;
Var
 CurrentSeg: Word;
 MCB: MemoryControlBlock;
 Found: Boolean;
Begin
 Found := False;
 CurrentSeg := ArenaBase; { Premier MCB }

 While (CurrentSeg < $A000) And Not Found Do Begin
  If GetMCB(CurrentSeg, MCB) Then Begin
   { Vérifier si le bloc est libre et assez grand }
   If (MCB.Owner = 0) And (MCB.BlockSize >= Size) Then Begin
    Segment := CurrentSeg + 1; { Segment utilisable après le MCB }
    Found := True;
   End Else Begin
    { Passer au MCB suivant }
    If MCB.BlockType = 'Z' Then Break; { Dernier bloc }
    CurrentSeg := CurrentSeg + MCB.BlockSize + 1;
   End;
  End Else Break;
 End;

 FindMemoryFirstFit := Found;
End;

{ Recherche de bloc mémoire avec stratégie Best Fit }
Function FindMemoryBestFit(Size:Word;Var Segment:Word):Boolean;
Var
 CurrentSeg: Word;
 MCB: MemoryControlBlock;
 BestSeg: Word;
 BestSize: Word;
 Found: Boolean;
Begin
 Found := False;
 BestSize := $FFFF; { Taille maximale }
 BestSeg := 0;
 CurrentSeg := ArenaBase; { Premier MCB }

 While CurrentSeg < $A000 Do Begin
  If GetMCB(CurrentSeg, MCB) Then Begin
   { Vérifier si le bloc est libre, assez grand,
     mais plus petit que le meilleur }
   If (MCB.Owner = 0) And (MCB.BlockSize >= Size) And (MCB.BlockSize < BestSize)
     Then Begin
    BestSeg := CurrentSeg + 1;
    BestSize := MCB.BlockSize;
    Found := True;
   End;

   { Passer au MCB suivant }
   If MCB.BlockType = 'Z' Then Break; { Dernier bloc }
   CurrentSeg := CurrentSeg + MCB.BlockSize + 1;
  End Else Break;
 End;

 If Found Then Segment := BestSeg;
 FindMemoryBestFit := Found;
End;

{ Recherche de bloc mémoire avec stratégie Last Fit }
Function FindMemoryLastFit(Size:Word;Var Segment:Word):Boolean;
Var
 CurrentSeg: Word;
 MCB: MemoryControlBlock;
 LastSeg: Word;
 Found: Boolean;
Begin
 Found := False;
 LastSeg := 0;
 CurrentSeg := ArenaBase; { Premier MCB }

 { Parcourir tous les blocs pour trouver le dernier qui convient }
 While CurrentSeg < $A000 Do Begin
  If GetMCB(CurrentSeg, MCB) Then Begin
   { Vérifier si le bloc est libre et assez grand }
   If (MCB.Owner = 0) And (MCB.BlockSize >= Size) Then Begin
    LastSeg := CurrentSeg + 1;
    Found := True;
   End;

   { Passer au MCB suivant }
   If MCB.BlockType = 'Z' Then Break; { Dernier bloc }
   CurrentSeg := CurrentSeg + MCB.BlockSize + 1;
  End Else Break;
 End;

 If Found Then Segment := LastSeg;
 FindMemoryLastFit := Found;
End;

{ Fonction améliorée d'allocation mémoire avec stratégies }
Function AllocateMemoryWithStrategy(Size:Word;Strategy:Word):Word;
{ Premier bloc libre assez grand ;
  le reste du bloc devient un nouveau bloc libre. }
Var
 Cur: Word;
 MCB: MemoryControlBlock;
Begin
 AllocateMemoryWithStrategy := 0; { Erreur par défaut }
 Cur := ArenaBase;
 While GetMCB(Cur, MCB) Do Begin
  If (MCB.Owner = 0) And (MCB.BlockSize >= Size) Then Begin
   If MCB.BlockSize > Size + 1 Then Begin
    CreateMCB(Cur + Size + 1, MCB.BlockSize - Size - 1, 0, MCB.BlockType = 'Z');
    MCB.BlockType := 'M';
    MCB.BlockSize := Size;
   End;
   MCB.Owner := GetCurrentPSP;
   SetMCB(Cur, MCB);
   AllocateMemoryWithStrategy := Cur + 1;
   Exit;
  End;
  If MCB.BlockType = 'Z' Then Exit;
  Cur := Cur + MCB.BlockSize + 1;
 End;
End;

{ Fonction principale 58h - Get/Set Memory Allocation Strategy }
Function DOS58h_GetSetMemoryStrategy(Action:Byte;NewStrategy:Word):Word;
Var
 CurrentStrategy: Word;
 CurrentUMBState: Word;
Begin
 DOS58h_GetSetMemoryStrategy := $FFFF; { Erreur par défaut }

 Case Action Of
  0: Begin { GET - Obtenir la stratégie actuelle }
      CurrentStrategy := GetMemoryStrategy;
      DOS58h_GetSetMemoryStrategy := CurrentStrategy;
     End;

  1: Begin { SET - Définir une nouvelle stratégie }
      { Valider la stratégie (0=First Fit, 1=Best Fit, 2=Last Fit) }
      If NewStrategy > 2 Then Begin
       DOS58h_GetSetMemoryStrategy := 1; { Invalid function }
       Exit;
      End;

      SetMemoryStrategy(NewStrategy);
      DOS58h_GetSetMemoryStrategy := 0; { Succès }
     End;

  2: Begin { GET UMB Link State - Obtenir l'état de liaison UMB }
      { Vérifier si les UMB sont disponibles }
      If Not AreUMBsAvailable Then Begin
       DOS58h_GetSetMemoryStrategy := 1; { Invalid function }
       Exit;
      End;

      CurrentUMBState := GetUMBLinkState;
      DOS58h_GetSetMemoryStrategy := CurrentUMBState;
     End;

  3: Begin { SET UMB Link State - Définir l'état de liaison UMB }
      { Vérifier si les UMB sont disponibles }
      If Not AreUMBsAvailable Then Begin
       DOS58h_GetSetMemoryStrategy := 1; { Invalid function }
       Exit;
      End;

      { Valider l'état (0=Unlinked, 1=Linked) }
      If NewStrategy > 1 Then Begin
       DOS58h_GetSetMemoryStrategy := 1; { Invalid function }
       Exit;
      End;

      { Effectuer la liaison/déliaison selon l'état demandé }
      If NewStrategy = 1 Then Begin
       { Lier les UMB }
       If LinkUMBs Then Begin
        SetUMBLinkState(1);
        DOS58h_GetSetMemoryStrategy := 0; { Succès }
       End Else Begin
        DOS58h_GetSetMemoryStrategy := 8; { Insufficient memory }
       End;
      End Else Begin
       { Délier les UMB }
       If UnlinkUMBs Then Begin
        SetUMBLinkState(0);
        DOS58h_GetSetMemoryStrategy := 0; { Succès }
       End Else Begin
        DOS58h_GetSetMemoryStrategy := 1; { Invalid function }
       End;
      End;
     End;

  Else Begin
   DOS58h_GetSetMemoryStrategy := 1; { Invalid function }
  End;
 End;

 { Note: Cette implémentation gère les stratégies d'allocation mémoire et UMB
   basiques.
   Un système DOS complet supporterait :
   - La gestion de la mémoire étendue (XMS)
   - La gestion de la mémoire expansée (EMS)
   - Les blocs de mémoire haute (HMA)
   - La défragmentation automatique
   - Les statistiques détaillées d'allocation
   - La protection contre la fragmentation
   - La détection automatique des gestionnaires UMB (EMM386, QEMM, etc.)

   Les sous-fonctions implémentées :
   00h = Get Memory Allocation Strategy
   01h = Set Memory Allocation Strategy (0=First Fit, 1=Best Fit, 2=Last Fit)
   02h = Get UMB Link State (0=Unlinked, 1=Linked)
   03h = Set UMB Link State (0=Unlink, 1=Link)

   Les UMB (Upper Memory Blocks) permettent d'utiliser la mémoire haute
   entre 640KB et 1MB pour charger des programmes et pilotes. }
End;

{ Fonctions de gestion des erreurs étendues pour DOS 59h }

{ Définit une erreur étendue complète dans le Code Segment }
Procedure SetExtendedError(ErrorCode:Word;ErrorClass,SuggestedAction,
  ErrorLocus:Byte);
Begin
 { Sauvegarder toutes les informations d'erreur dans la structure Data }
 ASM
  PUSH DS
  PUSH AX

  { Pointer vers la structure Data.DataMOS }
  MOV AX,CS
  MOV DS,AX
  MOV SI,OFFSET Data.DataMOS

  { Écrire les champs d'erreur étendue }
  MOV AX,ErrorCode
  MOV [SI].DataMOS.ExtendedError,AX

  MOV AL,ErrorClass
  MOV [SI].DataMOS.ErrorClass,AL

  MOV AL,SuggestedAction
  MOV [SI].DataMOS.SuggestedAction,AL

  MOV AL,ErrorLocus
  MOV [SI].DataMOS.ErrorLocus,AL

  POP AX
  POP DS
 END;
End;

{ Obtient le code d'erreur étendu }
Function GetExtendedErrorCode:Word;
Var
 ErrorCode: Word;
Begin
 ASM
  PUSH DS

  { Pointer vers la structure Data.DataMOS }
  MOV AX,CS
  MOV DS,AX
  MOV SI,OFFSET Data.DataMOS

  { Lire le champ ExtendedError }
  MOV AX,[SI].DataMOS.ExtendedError
  MOV ErrorCode,AX

  POP DS
 END;

 GetExtendedErrorCode := ErrorCode;
End;

{ Obtient la classe d'erreur }
Function GetExtendedErrorClass:Byte;
Var
 ErrorClass: Byte;
Begin
 ASM
  PUSH DS

  { Pointer vers la structure Data.DataMOS }
  MOV AX,CS
  MOV DS,AX
  MOV SI,OFFSET Data.DataMOS

  { Lire le champ ErrorClass }
  MOV AL,[SI].DataMOS.ErrorClass
  MOV ErrorClass,AL

  POP DS
 END;

 GetExtendedErrorClass := ErrorClass;
End;

{ Obtient l'action suggérée }
Function GetExtendedSuggestedAction:Byte;
Var
 SuggestedAction: Byte;
Begin
 ASM
  PUSH DS

  { Pointer vers la structure Data.DataMOS }
  MOV AX,CS
  MOV DS,AX
  MOV SI,OFFSET Data.DataMOS

  { Lire le champ SuggestedAction }
  MOV AL,[SI].DataMOS.SuggestedAction
  MOV SuggestedAction,AL

  POP DS
 END;

 GetExtendedSuggestedAction := SuggestedAction;
End;

{ Obtient la localisation de l'erreur }
Function GetExtendedErrorLocus:Byte;
Var
 ErrorLocus: Byte;
Begin
 ASM
  PUSH DS

  { Pointer vers la structure Data.DataMOS }
  MOV AX,CS
  MOV DS,AX
  MOV SI,OFFSET Data.DataMOS

  { Lire le champ ErrorLocus }
  MOV AL,[SI].DataMOS.ErrorLocus
  MOV ErrorLocus,AL

  POP DS
 END;

 GetExtendedErrorLocus := ErrorLocus;
End;

{ Efface les informations d'erreur étendue }
Procedure ClearExtendedError;
Begin
 { Remettre à zéro toutes les informations d'erreur }
 ASM
  PUSH DS
  PUSH AX

  { Pointer vers la structure Data.DataMOS }
  MOV AX,CS
  MOV DS,AX
  MOV SI,OFFSET Data.DataMOS

  { Effacer tous les champs d'erreur }
  MOV AX,0
  MOV [SI].DataMOS.ExtendedError,AX
  MOV [SI].DataMOS.ErrorClass,AL
  MOV [SI].DataMOS.SuggestedAction,AL
  MOV [SI].DataMOS.ErrorLocus,AL

  POP AX
  POP DS
 END;
End;

{ Définit une erreur standard avec des paramètres prédéfinis }
Procedure SetStandardError(ErrorCode:Word);
Var
 ErrorClass, SuggestedAction, ErrorLocus: Byte;
Begin
 { Définir les paramètres selon le code d'erreur }
 Case ErrorCode Of
  ERROR_INVALID_FUNCTION: Begin
   ErrorClass := ERRCLASS_APPERR;
   SuggestedAction := ERRACT_ABORT;
   ErrorLocus := ERRLOC_UNK;
  End;

  ERROR_FILE_NOT_FOUND: Begin
   ErrorClass := ERRCLASS_NOTFND;
   SuggestedAction := ERRACT_USER;
   ErrorLocus := ERRLOC_DISK;
  End;

  ERROR_PATH_NOT_FOUND: Begin
   ErrorClass := ERRCLASS_NOTFND;
   SuggestedAction := ERRACT_USER;
   ErrorLocus := ERRLOC_DISK;
  End;

  ERROR_TOO_MANY_OPEN_FILES: Begin
   ErrorClass := ERRCLASS_OUTOFRESOURCE;
   SuggestedAction := ERRACT_RETRY;
   ErrorLocus := ERRLOC_UNK;
  End;

  ERROR_ACCESS_DENIED: Begin
   ErrorClass := ERRCLASS_AUTH;
   SuggestedAction := ERRACT_USER;
   ErrorLocus := ERRLOC_DISK;
  End;

  ERROR_INVALID_HANDLE: Begin
   ErrorClass := ERRCLASS_APPERR;
   SuggestedAction := ERRACT_ABORT;
   ErrorLocus := ERRLOC_UNK;
  End;

  ERROR_NOT_ENOUGH_MEMORY: Begin
   ErrorClass := ERRCLASS_OUTOFRESOURCE;
   SuggestedAction := ERRACT_ABORT;
   ErrorLocus := ERRLOC_MEM;
  End;

  ERROR_INVALID_BLOCK: Begin
   ErrorClass := ERRCLASS_APPERR;
   SuggestedAction := ERRACT_ABORT;
   ErrorLocus := ERRLOC_MEM;
  End;

  Else Begin { Erreur inconnue }
   ErrorClass := ERRCLASS_UNK;
   SuggestedAction := ERRACT_IGNORE;
   ErrorLocus := ERRLOC_UNK;
  End;
 End;

 { Appeler la fonction complète }
 SetExtendedError(ErrorCode, ErrorClass, SuggestedAction, ErrorLocus);
End;

{ Fonction auxiliaire pour le handler assembleur }
{ Fonction principale 59h - Get Extended Error Information }
Function DOS59h_GetExtendedError:LongInt;
Var
 ErrorCode: Word;
 ErrorClass: Byte;
 SuggestedAction: Byte;
 ErrorLocus: Byte;
 Result: LongInt;
Begin
 { Obtenir toutes les informations d'erreur étendue }
 ErrorCode := GetExtendedErrorCode;
 ErrorClass := GetExtendedErrorClass;
 SuggestedAction := GetExtendedSuggestedAction;
 ErrorLocus := GetExtendedErrorLocus;

 { Empaqueter le résultat dans un LongInt }
 { High Word: ErrorClass dans le byte haut, SuggestedAction dans le byte bas }
 { Low Word: ErrorCode }
 Result := (LongInt(ErrorClass) SHL 24) OR (LongInt(SuggestedAction) SHL 16) OR
   ErrorCode;

 { Note: Dans le handler assembleur, le Locus sera récupéré séparément }
 DOS59h_GetExtendedError := Result;
End;

{ Fonction 5Ah - Create Temporary File }
Function DOS5Ah_CreateTempFile(PathPtr:Pointer;Attributes:Word):Word;
Var
 P: PChar;
 L,Counter,W: Word;
 K: Byte;
 Handle: Word;
 T: String[12];
Begin
 { le chemin (repertoire) est suivi du nom genere TMPnnnnn.TMP dans le tampon de
   l'appelant }
 P:=PChar(PathPtr);
 L:=0;
 While (P[L]<>#0) And (L<240) Do Inc(L);
 If (L>0) And (P[L-1]<>'\') Then Begin P[L]:='\'; Inc(L); End;
 For Counter:=1 To 9999 Do Begin
  W:=Counter;
  T:='TMP00000.TMP';
  For K:=0 To 12 Do P[L+K]:=T[K+1];
  P[L+12]:=#0;
  For K:=7 DownTo 3 Do Begin
   P[L+K]:=Chr(48+(W Mod 10));
   W:=W Div 10;
  End;
  Handle:=FxCreate(PathPtr,Byte(Attributes),True);
  If Handle<>$FFFF Then Begin
   ClearExtendedError;
   DOS5Ah_CreateTempFile:=Handle;
   Exit;
  End;
 End;
 DOS5Ah_CreateTempFile:=$FFFF;
End;

{ Fonction 5Bh - Create New File }
Function DOS5Bh_CreateNewFile(PathPtr:Pointer;Attributes:Word):Word;
Begin
 DOS5Bh_CreateNewFile:=FxCreate(PathPtr,Byte(Attributes),True);
End;
{ Fonctions utilitaires pour File Locking }

{ Trouver un slot libre dans la table des verrous }
Function FindFreeLockSlot:Integer;
Const
 FileLockEntrySize=SizeOf(FileLockEntry);
Var
 I: Integer;
 Found: Boolean;
Begin
 FindFreeLockSlot := -1;
 Found := False;
 For I := 0 To 19 Do Begin
  If Not Found Then Begin
   ASM
    MOV SI,OFFSET Data
    MOV AX,I
    MOV BX,FileLockEntrySize
    MUL BX
    ADD AX,OFFSET DataMOS.FileLocks
    MOV BX,AX
    CMP BYTE PTR [BX].FileLockEntry.InUse,0
    JNE @NextSlot
    MOV Found,1
    MOV AX,I
    MOV @Result,AX
@NextSlot:
   END;
  End;
 End;
End;

{ Vérifier si une région est en conflit avec les verrous existants }
Function CheckLockConflict(Handle:Word;StartOffset,Length:LongInt;
  PSPOwner:Word):Boolean;
Const
 FileLockEntrySize=SizeOf(FileLockEntry);
Var
 I: Integer;
 LockEnd, RequestEnd: LongInt;
 LockEntry: FileLockEntry;
Begin
 CheckLockConflict := False;
 RequestEnd := StartOffset + Length - 1;

 For I := 0 To 19 Do Begin
  { Copier l'entrée depuis le Code Segment }
  ASM
   PUSH DS
   MOV SI,OFFSET Data
   MOV AX,I
   MOV BX,FileLockEntrySize
   MUL BX
   ADD SI,AX
   ADD SI,OFFSET DataMOS.FileLocks

   LEA DI,LockEntry
   PUSH SS
   POP ES
   MOV CX,FileLockEntrySize
   CLD
   REP MOVSB
   POP DS
  END;

  If LockEntry.InUse and (LockEntry.Handle = Handle) and
     (LockEntry.PSPOwner <> PSPOwner) Then Begin
   LockEnd := LockEntry.StartOffset + LockEntry.Length - 1;
   { Vérifier si les régions se chevauchent }
   If Not ((RequestEnd < LockEntry.StartOffset) or (StartOffset > LockEnd)) Then
     Begin
    CheckLockConflict := True;
    SetExtendedError(ERROR_ACCESS_DENIED, ERRCLASS_AUTH, ERRACT_USER,
      ERRLOC_UNK);
    Exit;
   End;
  End;
 End;
End;

{ Fonction principale 5Ch - Lock/Unlock File Region (AL=0 verrouiller,
  AL=1 deverrouiller).
  Table des verrous : 20 entrees de 14 octets dans DataMOS.FileLocks (InUse:1,
    Handle:2, PSP:2,
  Debut:4, Longueur:4, Type:1). Handle = index SFT. }
Const
 LkBase=865;

Function LkGetB(Off:Word):Byte;Assembler;
ASM
 MOV BX,Off
 MOV AL,BYTE PTR [Data + BX]
END;

Function LkGetW(Off:Word):Word;Assembler;
ASM
 MOV BX,Off
 MOV AX,WORD PTR [Data + BX]
END;

Procedure LkSetB(Off:Word;V:Byte);Assembler;
ASM
 MOV BX,Off
 MOV AL,V
 MOV BYTE PTR [Data + BX],AL
END;

Procedure LkSetW(Off:Word;V:Word);Assembler;
ASM
 MOV BX,Off
 MOV AX,V
 MOV WORD PTR [Data + BX],AX
END;

Function LkGetL(Off:Word):LongInt;
Begin
 LkGetL:=LongInt(LkGetW(Off))+LongInt(LkGetW(Off+2))*65536;
End;

Procedure LkSetL(Off:Word;V:LongInt);
Begin
 LkSetW(Off,Word(V));
 LkSetW(Off+2,Word(V Shr 16));
End;

{ Supprime les verrous d'un processus qui se termine }
Procedure LockReleasePsp(Psp:Word);
Var I:Word;
Begin
 For I:=0 To 19 Do
  If (LkGetB(LkBase+I*14)<>0) And (LkGetW(LkBase+I*14+3)=Psp) Then
    LkSetB(LkBase+I*14,0);
End;

Function DOS5Ch_LockUnlockRegion(Handle:Word;Action:Byte;StartOffset,
  Length:LongInt):Word;
Var
 I,E,Free,Psp:Word;
 S,L:LongInt;
Begin
 DOS5Ch_LockUnlockRegion:=1;
 If Action>1 Then Begin
  SetStandardError(1);
  Exit;
 End;
 If (Handle<5) Or (Handle>=20) Then Begin
  SetStandardError(6);
  DOS5Ch_LockUnlockRegion:=6;
  Exit;
 End;
 Psp:=GetCurrentPSP;
 If Action=0 Then Begin
  Free:=$FFFF;
  For I:=0 To 19 Do Begin
   E:=LkBase+I*14;
   If LkGetB(E)=0 Then Begin
    If Free=$FFFF Then Free:=I;
   End Else If (LkGetW(E+1)=Handle) And (LkGetW(E+3)<>Psp) Then Begin
    S:=LkGetL(E+5);
    L:=LkGetL(E+9);
    If (StartOffset<S+L) And (S<StartOffset+Length) Then Begin
     SetStandardError(33);
     DOS5Ch_LockUnlockRegion:=33;
     Exit;
    End;
   End;
  End;
  If Free=$FFFF Then Begin
   SetStandardError(36);
   DOS5Ch_LockUnlockRegion:=36;
   Exit;
  End;
  E:=LkBase+Free*14;
  LkSetB(E,1);
  LkSetW(E+1,Handle);
  LkSetW(E+3,Psp);
  LkSetL(E+5,StartOffset);
  LkSetL(E+9,Length);
  LkSetB(E+13,1);
 End Else Begin
  For I:=0 To 19 Do Begin
   E:=LkBase+I*14;
   If (LkGetB(E)<>0) And (LkGetW(E+1)=Handle) And (LkGetW(E+3)=Psp) And
      (LkGetL(E+5)=StartOffset) And (LkGetL(E+9)=Length) Then Begin
    LkSetB(E,0);
    ClearExtendedError;
    DOS5Ch_LockUnlockRegion:=0;
    Exit;
   End;
  End;
  SetStandardError(33);
  DOS5Ch_LockUnlockRegion:=33;
  Exit;
 End;
 ClearExtendedError;
 DOS5Ch_LockUnlockRegion:=0;
End;

Procedure SetIntVec(_AL:Byte;_DS,_DX:Word);Assembler;ASM
 { Mettre le vecteur d'interruption à l'adresse AL*4 }
 PUSH ES
  MOV AX,0000h
  MOV ES,AX
  MOV BL,_AL
  MOV BH,0
  SHL BX,1
  SHL BX,1                  { BX = AL * 4 }
  MOV AX,_DX
  MOV ES:[BX],AX           { Offset }
  MOV AX,_DS
  MOV ES:[BX+2],AX         { Segment }
 POP ES
END;

Procedure GetIntVec(_AL:Byte;Var _DS,_DX:Word);Assembler;ASM
 { Lire le vecteur d'interruption à l'adresse AL*4 }
 PUSH ES
  MOV AX,0000h
  MOV ES,AX
  MOV BL,_AL
  MOV BH,0
  SHL BX,1
  SHL BX,1                  { BX = AL * 4 }
  MOV AX,ES:[BX]           { Offset }
  LES DI,_DX               { Adresse de _DX }
  MOV ES:[DI],AX
  MOV AX,ES:[BX+2]         { Segment }
  LES DI,_DS               { Adresse de _DS }
  MOV ES:[DI],AX
 POP ES
END;

Function CSeg: Word;Assembler;
ASM
 MOV AX,CS
END;

Procedure END_KERNEL;Begin
 ASM
  DB 'FIN DU NOYAU MSDOS-0';
 END;
End;

END.
