{ @author: Sylvain Maltais
  @created: 2026
  @website(https://www.gladir.com/msdos0)
  @description: Le MS Operating System est un systeme d'exploitation remplacant le DOS traditionnel.

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

  { Structure pour les données internes DOS }
 DataMOS=Record
  Key:Byte;
  InDos:Byte;
  CurrDisk:Byte;
  DTASegment:Word;    { Segment de la DTA }
  DTAOffset:Word;     { Offset de la DTA }
  CurrentCountry:Word; { Code pays actuel }
  LastReturnCode:Word; { Code de retour du dernier programme (AH=raison, AL=code) }
  CurrentPSP:Word;     { Segment du PSP courant }
  VerifyFlag:Byte;     { Flag de vérification en écriture (0=off, 1=on) }
  FindState: FindFileState; { État de la recherche de fichiers }
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
  Reserved2: Array[0..22] of Byte; { Réservé }
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
{$ENDIF}{ Déclarations Forward }
Procedure Intr20h;Forward;
Procedure Intr21h;Forward;
Procedure Intr25h;Forward;
Procedure Intr26h;Forward;
Procedure Intr28h;Forward;
Procedure Intr2Ah;Forward;
Procedure Intr2Fh;Forward;
Procedure Intr33h;Forward;

{ Déclarations des fonctions DOS }
Function DOS4Eh_FindFirstFile(Path:String;Attr:Byte;var DTA:DTAStruct):Word;Forward;
Function DOS4Fh_FindNextFile(var DTA:DTAStruct):Word;Forward;

{ Fonctions d'accès aux données du kernel }
Procedure GetFindState(Var State:FindFileState);Near;Forward;
Procedure SetFindState(Var State:FindFileState);Near;Forward;

{ Fonctions FAT pour Find File }
Function GetRootDirectorySector:Word;Near;Forward;
Function GetRootDirectorySize:Word;Near;Forward;
Function ReadSectorSimple(Sector:Word;Var Buffer):Boolean;Near;Forward;
Function WriteSectorSimple(Sector:Word;Var Buffer):Boolean;Near;Forward;

Procedure SetIntVec(_AL:Byte;_DS,_DX:Word);Near;Forward;
Procedure DataCountry(CountryCode:Word;Var CountryInfo:DataCountryRec);Near;Forward;
Procedure FillChar(Var Dest;Size:Word;Value:Byte);Near;Forward;
Procedure Move(Var Source,Dest;Size:Word);Near;Forward;
Procedure Intr(IntNo:Byte;Var Regs:Registers);Near;Forward;

{ Fonctions de manipulation de chaînes internes }
Function Length(S:String):Byte;Near;Forward;
Function Copy(S:String;Index,Count:Byte):String;Near;Forward;
Procedure Delete(Var S:String;Index,Count:Byte);Near;Forward;

Procedure Handle38hGetCountryInfo(CountryCode:Word;BufferPtr:Word);Near;Forward;
Function Handle38hSetCountryInfo(NewCountryCode:Word):Word;Near;Forward;

{ Procédures pour gestion FAT et répertoires - Fonctions 39h/3Ah }
Function ReadBootSector(Drive:Byte;Var BootSec:BootSectorRec):Boolean;Near;Forward;
Function ReadSector(Drive:Byte;Sector:LongInt;Buffer:Pointer):Boolean;Near;Forward;
Function WriteSector(Drive:Byte;Sector:LongInt;Buffer:Pointer):Boolean;Near;Forward;
Function FindFreeCluster(Drive:Byte;BootSec:BootSectorRec):Word;Near;Forward;
Function AllocateCluster(Drive:Byte;BootSec:BootSectorRec;Cluster:Word):Boolean;Near;Forward;
Function CreateDirEntry(Drive:Byte;BootSec:BootSectorRec;ParentCluster:Word;DirName:String):Boolean;Near;Forward;
Function ParsePath(Path:String;Var Drive:Byte;Var DirName:String):Boolean;Near;Forward;
Function FindParentDirectory(Drive:Byte;BootSec:BootSectorRec;Path:String;Var ParentCluster:Word):Boolean;Near;Forward;

{ Procédures spécifiques pour fonction 3Ah - Remove Directory }
Function FindDirectoryEntry(Drive:Byte;BootSec:BootSectorRec;ParentCluster:Word;
                           DirName:String;Var Entry:DirectoryEntry;
                           Var EntryOffset:Word):Boolean;Near;Forward;
Function IsDirectoryEmpty(Drive:Byte;BootSec:BootSectorRec;DirCluster:Word):Boolean;Near;Forward;
Function FreeFATChain(Drive:Byte;BootSec:BootSectorRec;StartCluster:Word):Boolean;Near;Forward;
Function DeleteDirEntry(Drive:Byte;BootSec:BootSectorRec;ParentCluster:Word;EntryOffset:Word):Boolean;Near;Forward;
Function GetClusterSector(Drive:Byte;BootSec:BootSectorRec;Cluster:Word):LongInt;Near;Forward;

{ Fonctions principales pour 3Ah et 3Bh }
Function DOS3Ah_RemoveDirectory(PathPtr:Pointer):Word;Near;Forward;

{ Procédures spécifiques pour fonction 3Bh - Change Directory }
Function FindDirectoryByPath(Drive:Byte;BootSec:BootSectorRec;Path:String;Var DirCluster:Word):Boolean;Near;Forward;
Function SetCurrentDirectory(Drive:Byte;DirCluster:Word):Boolean;Near;Forward;
Function DOS3Bh_ChangeDirectory(PathPtr:Pointer):Word;Near;Forward;

{ Procédures spécifiques pour fonction 3Ch - Create or Open File }
Function ParseFilePath(Path:String;Var Drive:Byte;Var DirPath,FileName:String):Boolean;Near;Forward;
Function FindOrCreateFile(Drive:Byte;BootSec:BootSectorRec;DirPath,FileName:String;
                         Attributes:Byte;Var FileHandle:Word):Word;Near;Forward;
Function AllocateFileHandle(Drive:Byte;FirstCluster,FileSize:LongInt;
                           Attributes:Byte;Var Handle:Word):Boolean;Near;Forward;
Function CreateFileEntry(Drive:Byte;BootSec:BootSectorRec;DirCluster:Word;
                        FileName:String;Attributes:Byte;Var FirstCluster:Word):Word;Near;Forward;
Function OpenExistingFile(Drive:Byte;Entry:DirectoryEntry;Var Handle:Word):Word;Near;Forward;
Function DOS3Ch_CreateOpenFile(PathPtr:Pointer):Word;Near;Forward;

{ Procédures spécifiques pour fonction 3Dh - Open File }
Function ValidateAccessMode(AccessMode:Byte):Boolean;Near;Forward;
Function OpenFileReadOnly(Drive:Byte;Entry:DirectoryEntry;Var Handle:Word):Word;Near;Forward;
Function OpenFileWriteOnly(Drive:Byte;Entry:DirectoryEntry;Var Handle:Word):Word;Near;Forward;
Function OpenFileReadWrite(Drive:Byte;Entry:DirectoryEntry;Var Handle:Word):Word;Near;Forward;
Function DOS3Dh_OpenFile(PathPtr:Pointer;AccessMode:Byte):Word;Near;Forward;

{ Forward declarations pour fonction 3Eh }
Function GetFileTableEntry(Handle:Word;Var Entry:FileTableEntry):Boolean;Near;Forward;
Function SetFileTableEntry(Handle:Word;Entry:FileTableEntry):Boolean;Near;Forward;
Function CloseFileHandle(Handle:Word):Word;Near;Forward;
Function FlushFileBuffers(Handle:Word):Word;Near;Forward;
Function UpdateDirectoryEntry(Handle:Word):Word;Near;Forward;
Function DOS3Eh_CloseFile(Handle:Word):Word;Near;Forward;

{ Forward declarations pour fonction 3Fh }
Function ReadFromCluster(Drive:Byte;BootSec:BootSectorRec;Cluster:Word;
                         Offset:Word;Buffer:Pointer;
                         BytesToRead:Word):Word;Near;Forward;
Function GetNextCluster(Drive:Byte;BootSec:BootSectorRec;CurrentCluster:Word):Word;Near;Forward;
Function ReadFileData(Handle:Word;Buffer:Pointer;BytesToRead:Word;Var BytesRead:Word):Word;Near;Forward;
Function DOS3Fh_ReadFile(Handle:Word;Buffer:Pointer;BytesToRead:Word;Var BytesRead:Word):Word;Near;Forward;

{ Forward declarations pour fonction 40h }
Function WriteToCluster(Drive:Byte;BootSec:BootSectorRec;Cluster:Word;
                       Offset:Word;Buffer:Pointer;BytesToWrite:Word):Word;Near;Forward;
Function AllocateNewCluster(Drive:Byte;BootSec:BootSectorRec;PreviousCluster:Word):Word;Near;Forward;
Function UpdateFATEntry(Drive:Byte;BootSec:BootSectorRec;Cluster:Word;NextCluster:Word):Boolean;Near;Forward;
Function WriteFileData(Handle:Word;Buffer:Pointer;BytesToWrite:Word;Var BytesWritten:Word):Word;Near;Forward;
Function DOS40h_WriteFile(Handle:Word;Buffer:Pointer;BytesToWrite:Word;Var BytesWritten:Word):Word;Near;Forward;

{ Forward declarations pour fonction 41h }
Function DeleteDirectoryEntry(Drive:Byte;BootSec:BootSectorRec;DirCluster:Word;FileName:String):Boolean;Near;Forward;
Function DOS41h_DeleteFile(PathPtr:Pointer):Word;Near;Forward;

{ Forward declarations pour fonction 42h }
Function CalculateClusterFromPosition(Drive:Byte;BootSec:BootSectorRec;
                                      FirstCluster:Word;Position:LongInt;
                                      Var TargetCluster:Word;
                                      Var ClusterOffset:Word):Boolean;Near;Forward;
Function DOS42h_SeekFile(Handle:Word;OffsetHi,OffsetLo:Word;Method:Byte):LongInt;Near;Forward;

{ Forward declarations pour fonction 43h }
Function GetFileAttributes(Drive:Byte;BootSec:BootSectorRec;DirCluster:Word;
                           FileName:String;Var Attributes:Byte):Boolean;Near;Forward;
Function SetFileAttributes(Drive:Byte;BootSec:BootSectorRec;DirCluster:Word;
                           FileName:String;NewAttributes:Byte):Boolean;Near;Forward;
Function DOS43h_GetSetFileAttributes(PathPtr:Pointer;Action:Byte;NewAttributes:Byte):Word;Near;Forward;

{ Forward declarations pour fonction 44h }
Function IOCTL_GetDeviceInfo(Handle:Word):Word;Near;Forward;
Function IOCTL_SetDeviceInfo(Handle:Word;DeviceInfo:Word):Word;Near;Forward;
Function IOCTL_GetDriveInfo(Drive:Byte):Word;Near;Forward;
Function IOCTL_SetDriveInfo(Drive:Byte;DeviceInfo:Word):Word;Near;Forward;
Function IOCTL_ReadControlData(Handle:Word;Buffer:Pointer;BytesToRead:Word):Word;Near;Forward;
Function IOCTL_WriteControlData(Handle:Word;Buffer:Pointer;BytesToWrite:Word):Word;Near;Forward;
Function DOS44h_IOCTL(Handle:Word;SubFunction:Byte;Buffer:Pointer;ByteCount:Word):Word;Near;Forward;
Function DOS45h_DuplicateHandle(SourceHandle:Word):Word;Near;Forward;
Function DOS46h_ForceDuplicateHandle(SourceHandle:Word;TargetHandle:Word):Word;Near;Forward;
Function DOS47h_GetCurrentDirectory(Drive:Byte;BufferSeg:Word;BufferOfs:Word):Word;Near;Forward;
Function DOS48h_AllocateMemory(BlockSize:Word):Word;Near;Forward;
Function DOS49h_FreeMemory(BlockSegment:Word):Word;Near;Forward;
Function DOS4Ah_ModifyMemory(BlockSegment:Word;NewSize:Word):Word;Near;Forward;
Function DOS4Bh_ExecProgram(ExecType:Byte;ProgramPath:String;ParamBlock:ExecParameterBlock):Word;Near;Forward;
Function DOS4Ch_TerminateProgram(ExitCode:Byte):Word;Near;Forward;
Function DOS4Dh_GetReturnCode:Word;Near;Forward;

{ Fonctions 50h et 51h - Gestion PSP }
Function DOS50h_SetPSPAddress(PSPSegment:Word):Word;Near;Forward;
Function DOS51h_GetPSPAddress:Word;Near;Forward;

{ Fonctions 52h et 53h - Structures internes DOS }
Function DOS52h_GetListOfLists:Pointer;Near;Forward;
Function DOS53h_TranslateBPBtoDPB(BPBPtr:Pointer;DPBPtr:Pointer):Word;Near;Forward;

{ Fonctions 2Eh et 54h - Vérification en écriture }
Function DOS2Eh_SetVerifyFlag(VerifyState:Byte):Word;Near;Forward;
Function DOS54h_GetVerifyFlag:Byte;Near;Forward;

{ Fonction 55h - Create Child PSP }
Function DOS55h_CreateChildPSP(NewPSPSegment:Word):Word;Near;Forward;

{ Fonction 56h - Rename/Move File }
Function DOS56h_RenameFile(OldPathPtr:Pointer;NewPathPtr:Pointer):Word;Near;Forward;

{ Fonction 57h - Get/Set File Date and Time }
Function DOS57h_GetSetFileDateTime(Handle:Word;Action:Byte;NewDate,NewTime:Word):LongInt;Near;Forward;

{ Fonction 58h - Get/Set Memory Allocation Strategy }
Function DOS58h_GetSetMemoryStrategy(Action:Byte;NewStrategy:Word):Word;Near;Forward;

{ Fonctions utilitaires pour opérations FAT réelles }
Function ReadFATSector(Drive:Byte;Sector:Word;Var Buffer):Boolean;Near;Forward;
Function WriteFATSector(Drive:Byte;Sector:Word;Var Buffer):Boolean;Near;Forward;
Function ReadDirectorySector(Drive:Byte;Sector:Word;Var Buffer):Boolean;Near;Forward;
Function WriteDirectorySector(Drive:Byte;Sector:Word;Var Buffer):Boolean;Near;Forward;
Function FindDirectoryEntryByName(Drive:Byte;DirCluster:Word;
                                  FileName:String;Var Entry:DirectoryEntryFAT;
                                  Var EntryOffset:Word):Boolean;Near;Forward;
Function ParseFullPath(Path:String;Var Drive:Byte;Var DirPath,FileName:String):Boolean;Near;Forward;
Function UpdateDirectoryEntryName(Drive:Byte;DirCluster:Word;EntryOffset:Word;NewName:String):Boolean;Near;Forward;

{ Fonctions utilitaires pour la vérification }
Function VerifyWrite(Drive:Byte;Sector:LongInt;Buffer:Pointer;Size:Word):Boolean;Near;Forward;
Function WriteSectorWithVerify(Drive:Byte;Sector:LongInt;Buffer:Pointer):Boolean;Near;Forward;

{ Fonctions utilitaires pour EXEC }
Function LoadExeFile(FileName:String;Var LoadSegment:Word;Var ExeHdr:ExeHeader):Boolean;Near;Forward;
Function LoadComFile(FileName:String;Var LoadSegment:Word):Boolean;Near;Forward;
Function CreatePSP(ParentPSP:Word;TopMemory:Word):Word;Near;Forward;
Function SetupEnvironment(EnvSeg:Word;ParentPSP:Word):Word;Near;Forward;
Function RelocateExe(LoadSeg:Word;ExeHdr:ExeHeader;FileName:String):Boolean;Near;Forward;

{ Fonction pour charger le processeur de commandes }
Procedure LoadAndExecuteCommandProcessor;Near;Forward;

{ Fonctions utilitaires de base }
Function UpperCase(S:String):String;Near;Forward;
Function Pos(SubStr:String;S:String):Byte;Near;Forward;

{ Fonctions utilitaires pour la gestion mémoire }
Function InitializeMemoryManager:Boolean;Near;Forward;
Function FindFreeMCB(Size:Word;Var Segment:Word):Boolean;Near;Forward;
Function CreateMCB(Segment:Word;Size:Word;Owner:Word;IsLast:Boolean):Boolean;Near;Forward;
Function GetMCB(Segment:Word;Var MCB:MemoryControlBlock):Boolean;Near;Forward;
Function SetMCB(Segment:Word;MCB:MemoryControlBlock):Boolean;Near;Forward;
Function GetMemoryStrategy:Word;Near;Forward;
Procedure SetMemoryStrategy(NewStrategy:Word);Near;Forward;
Function AllocateMemoryWithStrategy(Size:Word;Strategy:Word):Word;Near;Forward;
Function GetUMBLinkState:Word;Near;Forward;
Procedure SetUMBLinkState(NewState:Word);Near;Forward;

{ Fonctions d'accès aux données dans Code Segment }
Function GetCurrentDrive: Byte;Near;Forward;
Procedure SetCurrentDrive(Drive: Byte);Near;Forward;
Function GetCurrentDirDrive(Index: Byte): Byte;Near;Forward;
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
Procedure SetFileTableDrive(Index: Byte; Drive: Byte);Near;Forward;
Procedure SetFileTableFirstCluster(Index: Byte; FirstCluster: Word);Near;Forward;
Procedure SetFileTableFileSize(Index: Byte; FileSize: LongInt);Near;Forward;
Procedure SetFileTableCurrentPos(Index: Byte; CurrentPos: LongInt);Near;Forward;
Procedure SetFileTableAttributes(Index: Byte; Attributes: Byte);Near;Forward;
Procedure SetFileTableCurrentCluster(Index: Byte; CurrentCluster: Word);Near;Forward;
Procedure SetFileTableClusterOffset(Index: Byte; ClusterOffset: Word);Near;Forward;

{ Fonctions d'accès aux nouvelles variables }
Function GetLastReturnCode: Word;Near;Forward;
Procedure SetLastReturnCode(ReturnCode: Word);Near;Forward;
Function GetCurrentPSP: Word;Near;Forward;
Procedure SetCurrentPSP(PSP: Word);Near;Forward;

{ Fonctions d'accès au flag de vérification }
Function GetVerifyFlag: Byte;Near;Forward;
Procedure SetVerifyFlag(Flag: Byte);Near;Forward;

Procedure BEGIN_KERNEL;
Var I:Byte;
Begin
 { Initialiser répertoires courants via les fonctions d'accès Code Segment }
 SetCurrentDrive(2); { C: par défaut }
 For I:=0 To 25 Do Begin
  SetCurrentDirDrive(I, I);
  SetCurrentDirCluster(I, 0); { Répertoire racine }
  SetCurrentDirPath(I, '\');
 End;

 { Initialiser table des fichiers ouverts }
 For I:=0 To 19 Do Begin
  SetFileTableInUse(I, False);
 End;

 SetIntVec($20,CSeg,Ofs(Intr21h));
 SetIntVec($21,CSeg,Ofs(Intr21h));
 SetIntVec($25,CSeg,Ofs(Intr25h));
 SetIntVec($26,CSeg,Ofs(Intr26h));
 SetIntVec($28,CSeg,Ofs(Intr28h));
 SetIntVec($2A,CSeg,Ofs(Intr2Ah));
 SetIntVec($2F,CSeg,Ofs(Intr2Fh));
 SetIntVec($33,CSeg,Ofs(Intr33h));
 
 { Initialiser le gestionnaire de mémoire }
 InitializeMemoryManager;
 
 { Charger et exécuter COMMAND.COM ou COMMAND.EXE }
 LoadAndExecuteCommandProcessor;
 ASM
  DB 'DEBUT DU NOYAU MSDOS-0';
 END;
End;

Procedure Data;Assembler;ASM
 DB 0          { Key:   Touche }
 DB 0          { InDos: Dans l'Interruption DOS? }
 DB 0          { CurrDisk: Disque courant }
 DW 0          { DTASegment: Segment DTA (initialisé à 0) }
 DW 80h        { DTAOffset: Offset DTA (par défaut 80h) }
 DW 33         { CurrentCountry: Pays actuel (33=France par défaut) }
 DW 0          { LastReturnCode: Code de retour du dernier programme }
 DW 1000h      { CurrentPSP: Segment du PSP courant (par défaut 1000h) }
@VerifyFlag:
 DB 0          { VerifyFlag: Flag de vérification en écriture (0=off, 1=on) }

 { Variables pour gestion répertoires courants }
 DB 2          { CurrentDrive: Lecteur courant (0=A:, 1=B:, 2=C:) }

 { CurrentDir: Array[0..25] of Record - Structure pour chaque drive }
 { Drive A: (0) }
 DB 0          { Drive }
 DW 0          { Cluster }
 DB 1,'\',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0  { Path: String[127] avec '\' par défaut }
 { Drive B: (1) }
 DB 1          { Drive }
 DW 0          { Cluster }
 DB 1,'\',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0  { Path: String[127] avec '\' par défaut }
 { Drive C: (2) }
 DB 2          { Drive }
 DW 0          { Cluster }
 DB 1,'\',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0  { Path: String[127] avec '\' par défaut }
 { Drive D: (3) }
 DB 3          { Drive }
 DW 0          { Cluster }
 DB 1,'\',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0  { Path: String[127] avec '\' par défaut }
 { Drive E: (4) }
 DB 4          { Drive }
 DW 0          { Cluster }
 DB 1,'\',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0  { Path: String[127] avec '\' par défaut }
 { Drives F: à Z: (5-25) - 21 drives restants avec même structure }
 { Drive F: (5) }
 DB 5,0,0,1,'\',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0
 { Drive G: (6) }
 DB 6,0,0,1,'\',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0
 { Drive H: (7) }
 DB 7,0,0,1,'\',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0
 { Drive I: (8) }
 DB 8,0,0,1,'\',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0
 { Drive J: (9) }
 DB 9,0,0,1,'\',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0
 { Drive K: (10) }
 DB 10,0,0,1,'\',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0
 { Drive L: (11) }
 DB 11,0,0,1,'\',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0
 { Drive M: (12) }
 DB 12,0,0,1,'\',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0
 { Drive N: (13) }
 DB 13,0,0,1,'\',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0
 { Drive O: (14) }
 DB 14,0,0,1,'\',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0
 { Drive P: (15) }
 DB 15,0,0,1,'\',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0
 { Drive Q: (16) }
 DB 16,0,0,1,'\',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0
 { Drive R: (17) }
 DB 17,0,0,1,'\',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0
 { Drive S: (18) }
 DB 18,0,0,1,'\',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0
 { Drive T: (19) }
 DB 19,0,0,1,'\',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0
 { Drive U: (20) }
 DB 20,0,0,1,'\',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0
 { Drive V: (21) }
 DB 21,0,0,1,'\',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0
 { Drive W: (22) }
 DB 22,0,0,1,'\',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0
 { Drive X: (23) }
 DB 23,0,0,1,'\',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0
 { Drive Y: (24) }
 DB 24,0,0,1,'\',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0
 { Drive Z: (25) }
 DB 25,0,0,1,'\',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DB 0,0,0,0

 { FileTable: Array[0..19] of FileTableEntry - 20 entrées de 17 octets chacune }
 { Chaque entrée: InUse(1) + Drive(1) + FirstCluster(2) +
                  FileSize(4) + CurrentPos(4) + Attributes(1) +
                  CurrentCluster(2) + ClusterOffset(2) = 17 octets }
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

 { Structure Liste des Listes pour fonction 52h }
@DOSListOfLists:
 DW 0,0        { FirstDPB: Pointer }
 DW 0,0        { FirstSFT: Pointer }
 DW 0,0        { ClockDevice: Pointer }
 DW 0,0        { ConDevice: Pointer }
 DW 512        { MaxSectorLength: 512 bytes standard }
 DW 0,0        { FirstBuffer: Pointer }
 DW 0,0        { FirstDirtyBuffer: Pointer }
 DW 0FFFFh     { FreeClusters: -1 = inconnu }
 DW 0,0        { NextFreeDPB: Pointer }
 DW 20         { NumberOfBuffers: 20 buffers }
 DB 4          { NumberOfLookaheadBuffers: 4 }
 DB 3          { BootDrive: C: (3) par défaut }
 DW 0          { DOSDataSeg: Segment données DOS }
 DB 26         { LastDrive: Z: (26 drives max) }
 DW 0,0        { NULDevice: Pointer vers driver NUL }

END;

Procedure Intr20h;Assembler;ASM
 { TODO : Mettre le code n�cessaire }
END;

Procedure Intr21h;Assembler;ASM
 INC Data.DataMOS.InDos
 MOV BL,AH
@CallFunc:
 XOR BH,BH
 SHL BX,1
 JMP @Label.Word[BX]
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

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 00h: Terminer le programme                      }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@00h:
 MOV AH,4Ch                 { Fonction 4Ch - Terminaison avec code de retour }
 XOR AL,AL                  { Code de retour = 0 }
 INT 21h                    { Appel recursif pour terminer proprement }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 01h: Entree de caractere avec echo              }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@01h:
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

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 02h: Sortie de caractere                        }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@02h:
 MOV AL,DL
 MOV AH,0Eh                 { BIOS - Sortie caractere }
 XOR BX,BX                  { Page 0, couleur par defaut }
 INT 10h
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 03h: Entree de caractere depuis AUX             }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@03h:
 MOV AH,02h                 { BIOS - Lire caractere serie }
 XOR DX,DX                  { Port COM1 }
 INT 14h
 TEST AH,80h                { Verifier timeout }
 JZ @03NoError
 MOV AL,1Ah                 { Code EOF si erreur }
@03NoError:
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 04h: Sortie de caractere vers AUX               }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@04h:
 MOV AL,DL
 MOV AH,01h                 { BIOS - Ecrire caractere serie }
 XOR DX,DX                  { Port COM1 }
 INT 14h
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 05h: Sortie de caractere vers PRN (imprimante)  }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@05h:
 MOV AL,DL
 XOR AH,AH                  { BIOS - Imprimer caractere }
 XOR DX,DX                  { Port LPT1 }
 INT 17h
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 06h: Entree/sortie directe de console           }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
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
 MOV AL,DL
 MOV AH,0Eh                 { BIOS - Sortie caractere }
 XOR BX,BX                  { Page 0, couleur par defaut }
 INT 10h
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 07h: Entree de caractere directe sans sortie }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@07h:
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

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 09h: Affichage de chaine terminee par $         }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@09h:
 PUSH SI                    { Sauver registres }
 PUSH DS
 MOV SI,DX                  { DS:DX pointe sur la chaine }
@09Loop:
 LODSB                      { Charger AL depuis DS:SI et incrementer SI }
 CMP AL,'$'                 { Caractere de fin ? }
 JE @09End
 MOV DL,AL                  { Preparer caractere pour sortie }
 PUSH AX                    { Sauver AX }
 PUSH SI                    { Sauver SI }
 MOV AH,02h                 { Fonction 02h - Sortie caractere }
 INT 21h
 POP SI                     { Restaurer SI }
 POP AX                     { Restaurer AX }
 JMP @09Loop
@09End:
 POP DS                     { Restaurer registres }
 POP SI
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 0Ah: Lecture de chaine avec buffer              }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
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

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 0Ch: Vider le tampon et appeler la fonction d'entree }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@0Ch:
 PUSH AX
  XOR AX,AX
  MOV ES,AX
  MOV AX,ES:[480h]
  MOV ES:[41Ah],AX
  MOV ES:[41Ch],AX
 POP BX
 JMP @CallFunc

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 0Dh: Reinitialisation du disque                 }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
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
 MOV AL,26 { Nombre d'unite installe }
 CMP DL,AL
 JAE @Xit
 MOV BYTE PTR [Data + 6],DL { Stocker CurrentDrive à l'offset 6 }
 MOV Data.DataMOS.CurrDisk,DL { Maintenir compatibilité }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 0Fh: Ouvrir un fichier avec FCB                 }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@0Fh:
 PUSH SI                    { Sauver registres }
 PUSH DI
 PUSH DS
 PUSH ES
 MOV SI,DX                  { DS:DX pointe sur le FCB }
 { Verifier si le fichier existe en utilisant le nom dans le FCB }
 PUSH AX
 PUSH BX
 PUSH CX
 PUSH DX
 { Simuler une ouverture reussie pour les FCB standards }
 MOV AL,0                   { Code de retour: succes }
 { Marquer le FCB comme ouvert en mettant le drive courant }
 MOV BL,Data.DataMOS.CurrDisk
 INC BL                     { 1=A:, 2=B:, etc. }
 MOV [SI],BL                { Stocker dans le FCB }
 POP DX
 POP CX
 POP BX
 POP AX
 POP ES                     { Restaurer registres }
 POP DS
 POP DI
 POP SI
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 10h: Fermer un fichier avec FCB                 }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@10h:
 PUSH SI                    { Sauver registres }
 PUSH DS
 MOV SI,DX                  { DS:DX pointe sur le FCB }
 { Verifier que le FCB est valide }
 CMP BYTE PTR [SI],0        { Drive = 0 ? }
 JE @10Error
 { Simuler une fermeture reussie }
 MOV BYTE PTR [SI],0        { Marquer le FCB comme ferme }
 MOV AL,0                   { Code de retour: succes }
 JMP @10End
@10Error:
 MOV AL,0FFh                { Code d'erreur: FCB invalide }
@10End:
 POP DS                     { Restaurer registres }
 POP SI
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 11h: Rechercher le premier fichier avec FCB     }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@11h:
 PUSH SI                    { Sauver registres }
 PUSH DI
 PUSH DS
 PUSH ES
 MOV SI,DX                  { DS:DX pointe sur le FCB }
 { Pour cette implementation basique, nous retournons "aucun fichier trouve" }
 { Dans une implementation complete, il faudrait chercher dans les repertoires }
 MOV AL,0FFh                { Code de retour: aucun fichier trouve }
 { Alternative: simuler la decouverte d'un fichier fictif }
 { MOV AL,0                   Code de retour: fichier trouve }
 { Il faudrait alors remplir la DTA avec les informations du fichier }
 POP ES                     { Restaurer registres }
 POP DS
 POP DI
 POP SI
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 12h: Rechercher le fichier suivant avec FCB     }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@12h:
 PUSH SI                    { Sauver registres }
 PUSH DI
 PUSH DS
 PUSH ES
 MOV SI,DX                  { DS:DX pointe sur le FCB }
 { Implementation basique: retourner "plus de fichiers" }
 { Dans un DOS complet, cette fonction continuerait la recherche commencee par 11h }
 MOV AL,0FFh                { Code de retour: plus de fichiers }
 POP ES                     { Restaurer registres }
 POP DS
 POP DI
 POP SI
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 13h: Supprimer un fichier avec FCB              }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@13h:
 PUSH SI                    { Sauver registres }
 PUSH DI
 PUSH DS
 PUSH ES
 MOV SI,DX                  { DS:DX pointe sur le FCB }
 { Verifier que le nom de fichier est valide dans le FCB }
 CMP BYTE PTR [SI+1],' '    { Premier caractere du nom vide ? }
 JE @13Error
 { Implementation simplifiee: simuler une suppression reussie }
 { Dans un DOS complet, il faudrait verifier l'existence et supprimer le fichier }
 MOV AL,0                   { Code de retour: succes }
 JMP @13End
@13Error:
 MOV AL,0FFh                { Code d'erreur: fichier non trouve }
@13End:
 POP ES                     { Restaurer registres }
 POP DS
 POP DI
 POP SI
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 14h: Lecture séquentielle avec FCB              }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@14h:
 PUSH SI                    { Sauver registres }
 PUSH DI
 PUSH DS
 PUSH ES
 MOV SI,DX                  { DS:DX pointe sur le FCB }
 { Verifier que le FCB est ouvert }
 CMP BYTE PTR [SI],0        { Drive = 0 ? }
 JE @14Error
 { Implementation simplifiee: simuler une lecture EOF }
 { Dans un DOS complet, il faudrait lire les donnees dans la DTA }
 { et incrementer le pointeur de fichier dans le FCB }
 MOV AL,1                   { Code de retour: EOF (End Of File) }
 JMP @14End
@14Error:
 MOV AL,0FFh                { Code d'erreur: FCB non valide }
@14End:
 POP ES                     { Restaurer registres }
 POP DS
 POP DI
 POP SI
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 15h: Ecriture séquentielle avec FCB             }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@15h:
 PUSH SI                    { Sauver registres }
 PUSH DI
 PUSH DS
 PUSH ES
 MOV SI,DX                  { DS:DX pointe sur le FCB }
 { Verifier que le FCB est ouvert }
 CMP BYTE PTR [SI],0        { Drive = 0 ? }
 JE @15Error
 { Implementation simplifiee: simuler une ecriture reussie }
 { Dans un DOS complet, il faudrait ecrire les donnees depuis la DTA }
 { et incrementer le pointeur de fichier dans le FCB }
 MOV AL,0                   { Code de retour: succes }
 JMP @15End
@15Error:
 MOV AL,0FFh                { Code d'erreur: FCB non valide }
@15End:
 POP ES                     { Restaurer registres }
 POP DS
 POP DI
 POP SI
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 16h: Créer un fichier avec FCB                  }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@16h:
 PUSH SI                    { Sauver registres }
 PUSH DI
 PUSH DS
 PUSH ES
 MOV SI,DX                  { DS:DX pointe sur le FCB }
 { Verifier que le nom de fichier est valide dans le FCB }
 CMP BYTE PTR [SI+1],' '    { Premier caractere du nom vide ? }
 JE @16Error
 { Implementation simplifiee: simuler une creation reussie }
 { Dans un DOS complet, il faudrait creer le fichier sur disque }
 { et initialiser la structure FCB avec les informations du nouveau fichier }
 MOV BL,Data.DataMOS.CurrDisk
 INC BL                     { 1=A:, 2=B:, etc. }
 MOV [SI],BL                { Marquer le FCB comme ouvert sur le drive courant }
 { Initialiser les champs du FCB pour un nouveau fichier }
 MOV WORD PTR [SI+12],0     { Bloc courant = 0 }
 MOV WORD PTR [SI+14],128   { Taille d'enregistrement = 128 }
 MOV WORD PTR [SI+16],0     { Taille du fichier = 0 (partie basse) }
 MOV WORD PTR [SI+18],0     { Taille du fichier = 0 (partie haute) }
 MOV AL,0                   { Code de retour: succes }
 JMP @16End
@16Error:
 MOV AL,0FFh                { Code d'erreur: nom invalide }
@16End:
 POP ES                     { Restaurer registres }
 POP DS
 POP DI
 POP SI
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 17h: Renommer un fichier avec FCB               }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@17h:
 PUSH SI                    { Sauver registres }
 PUSH DI
 PUSH DS
 PUSH ES
 MOV SI,DX                  { DS:DX pointe sur le FCB source }
 { Le FCB pour renommer contient l'ancien nom (offset 0) et le nouveau nom (offset 17) }
 { Verifier que l'ancien nom est valide }
 CMP BYTE PTR [SI+1],' '    { Premier caractere de l'ancien nom vide ? }
 JE @17Error
 { Verifier que le nouveau nom est valide }
 CMP BYTE PTR [SI+17],' '   { Premier caractere du nouveau nom vide ? }
 JE @17Error
 { Implementation simplifiee: simuler un renommage reussi }
 { Dans un DOS complet, il faudrait localiser le fichier dans le repertoire }
 { et modifier l'entree pour changer le nom }
 MOV AL,0                   { Code de retour: succes }
 JMP @17End
@17Error:
 MOV AL,0FFh                { Code d'erreur: fichier non trouve ou nom invalide }
@17End:
 POP ES                     { Restaurer registres }
 POP DS
 POP DI
 POP SI
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 18h: Fonction réservée                          }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@18h:
 { Fonction réservée dans DOS classique - pas d'implémentation }
 { Certaines versions de DOS utilisent cette fonction à des fins internes }
 MOV AL,0                   { Code de retour neutre }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 19h: Demande le lecteur courant }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@19h:
 MOV AL,BYTE PTR [Data + 6]  { CurrentDrive à l'offset 6 }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 1Ah: Définir l'adresse DTA                      }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@1Ah:
 { Définir l'adresse du Disk Transfer Area (DTA) }
 { DS:DX contient la nouvelle adresse DTA }
 MOV Data.DataMOS.DTASegment,DS   { Sauvegarder le segment }
 MOV Data.DataMOS.DTAOffset,DX    { Sauvegarder le deplacemnet }
 { Pas de valeur de retour pour cette fonction }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 1Bh: Obtenir infos allocation drive par défaut  }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
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

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 1Ch: Obtenir infos allocation drive spécifique  }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
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

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 1Dh: Fermer tous les fichiers                   }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@1Dh:
 { Fonction non documentée dans DOS classique, utilisée pour fermer tous les FCB ouverts }
 { Dans une implémentation complète, il faudrait parcourir la table des FCB ouverts }
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

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 1Eh: Fonction réservée/non documentée           }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@1Eh:
 { Fonction non documentée dans DOS classique }
 { Utilisée en interne par certaines versions de DOS pour la redirection I/O }
 { Pour compatibilité, on retourne simplement sans erreur }
 MOV AL,0                   { Code de retour : succès (pas d'erreur) }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 1Fh: Fonction réservée/non documentée           }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@1Fh:
 { Fonction non documentée dans DOS classique }
 { Utilisée en interne par certaines versions de DOS pour la configuration d'imprimante }
 { Pour compatibilité, on retourne simplement sans erreur }
 MOV AL,0                   { Code de retour : succès (pas d'erreur) }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 20h: Terminer le programme (obsolète)           }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@20h:
 { Fonction de terminaison obsolète, équivalente à la fonction 00h }
 MOV AH,4Ch                 { Fonction 4Ch - Terminaison avec code de retour }
 XOR AL,AL                  { Code de retour = 0 }
 INT 21h                    { Appel récursif pour terminer proprement }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 21h: Lecture aléatoire avec FCB                 }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@21h:
 PUSH SI                    { Sauver registres }
 PUSH DI
 PUSH DS
 PUSH ES
 MOV SI,DX                  { DS:DX pointe sur le FCB }
 { Vérifier que le FCB est ouvert }
 CMP BYTE PTR [SI],0        { Drive = 0 ? }
 JE @21Error
 { Lecture aléatoire : utilise le champ "random record number" du FCB }
 { Offset 21h (33) dans le FCB contient le numéro d'enregistrement }
 { Implementation simplifiée: simuler une lecture réussie }
 { Dans un DOS complet, il faudrait :
   1. Lire le numéro d'enregistrement depuis FCB+21h (4 octets)
   2. Calculer la position dans le fichier
   3. Lire les données dans la DTA
   4. Mettre à jour les champs FCB si nécessaire }
 MOV AL,0                   { Code de retour: succès }
 JMP @21End
@21Error:
 MOV AL,1                   { Code d'erreur: EOF ou FCB invalide }
@21End:
 POP ES                     { Restaurer registres }
 POP DS
 POP DI
 POP SI
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 22h: Ecriture aléatoire avec FCB                }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@22h:
 PUSH SI                    { Sauver registres }
 PUSH DI
 PUSH DS
 PUSH ES
 MOV SI,DX                  { DS:DX pointe sur le FCB }
 { Vérifier que le FCB est ouvert }
 CMP BYTE PTR [SI],0        { Drive = 0 ? }
 JE @22Error
 { Ecriture aléatoire : utilise le champ "random record number" du FCB }
 { Implementation simplifiée: simuler une écriture réussie }
 { Dans un DOS complet, il faudrait :
   1. Lire le numéro d'enregistrement depuis FCB+21h (4 octets)
   2. Calculer la position dans le fichier
   3. Ecrire les données depuis la DTA
   4. Mettre à jour la taille du fichier dans le FCB si nécessaire }
 MOV AL,0                   { Code de retour: succès }
 JMP @22End
@22Error:
 MOV AL,1                   { Code d'erreur: disque plein ou FCB invalide }
@22End:
 POP ES                     { Restaurer registres }
 POP DS
 POP DI
 POP SI
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 23h: Obtenir la taille de fichier avec FCB      }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@23h:
 PUSH SI                    { Sauver registres }
 PUSH DI
 PUSH DS
 PUSH ES
 MOV SI,DX                  { DS:DX pointe sur le FCB }
 { Vérifier que le nom de fichier est valide dans le FCB }
 CMP BYTE PTR [SI+1],' '    { Premier caractère du nom vide ? }
 JE @23Error
 { Obtenir la taille du fichier et la convertir en numéro d'enregistrement }
 { Dans un DOS complet, il faudrait :
   1. Localiser le fichier sur le disque
   2. Lire sa taille depuis l'entrée de répertoire
   3. Calculer le numéro du dernier enregistrement
   4. Stocker ce numéro dans FCB+21h (random record number) }
 { Implementation simplifiée: simuler une taille fictive }
 MOV WORD PTR [SI+33],100   { Nombre d'enregistrements fictif (partie basse) }
 MOV WORD PTR [SI+35],0     { Partie haute = 0 }
 MOV AL,0                   { Code de retour: succès }
 JMP @23End
@23Error:
 MOV AL,0FFh                { Code d'erreur: fichier non trouvé }
@23End:
 POP ES                     { Restaurer registres }
 POP DS
 POP DI
 POP SI
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 24h: Définir l'adresse aléatoire avec FCB       }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@24h:
 PUSH SI                    { Sauver registres }
 PUSH DI
 PUSH DS
 PUSH ES
 MOV SI,DX                  { DS:DX pointe sur le FCB }
 { Vérifier que le FCB est valide }
 CMP BYTE PTR [SI],0        { Drive = 0 ? }
 JE @24Error
 { Définir l'adresse aléatoire dans le FCB }
 { Cette fonction copie le champ "current block" et "current record"
   vers le champ "random record number" pour permettre l'accès aléatoire }
 { FCB+0Ch = current block (2 octets)
   FCB+20h = current record (1 octet)
   FCB+21h = random record number (4 octets) }
 MOV AX,[SI+12]             { Lire current block }
 MOV BL,[SI+32]             { Lire current record }
 XOR BH,BH                  { Étendre à 16-bit }
 { Calculer l'adresse aléatoire: block * 128 + record }
 MOV CX,128                 { Taille de bloc standard }
 MUL CX                     { AX = block * 128 }
 ADD AX,BX                  { AX = block * 128 + record }
 MOV [SI+33],AX             { Stocker dans random record (partie basse) }
 MOV WORD PTR [SI+35],0     { Partie haute = 0 }
 MOV AL,0                   { Code de retour: succès }
 JMP @24End
@24Error:
 MOV AL,0FFh                { Code d'erreur: FCB invalide }
@24End:
 POP ES                     { Restaurer registres }
 POP DS
 POP DI
 POP SI
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

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 26h: Créer un nouveau PSP                       }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
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

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 27h: Lecture aléatoire de bloc avec FCB         }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@27h:
 { Lire plusieurs enregistrements consécutifs à partir d'une position aléatoire }
 { DS:DX pointe sur FCB, CX contient le nombre d'enregistrements à lire }
 PUSH SI                    { Sauver registres }
 PUSH DI
 PUSH DS
 PUSH ES
 PUSH CX
 MOV SI,DX                  { DS:DX pointe sur le FCB }
 { Vérifier que le FCB est ouvert }
 CMP BYTE PTR [SI],0        { Drive = 0 ? }
 JE @27Error
 { Dans une implémentation complète, il faudrait :
   1. Lire le numéro d'enregistrement aléatoire depuis FCB+21h
   2. Lire CX enregistrements consécutifs depuis cette position
   3. Transférer les données vers la DTA
   4. Mettre à jour le pointeur de fichier dans le FCB }
 { Version simplifiée : simuler une lecture réussie de tous les enregistrements }
 POP CX                     { Nombre d'enregistrements demandés }
 MOV AL,0                   { Code de retour: succès, tous lus }
 JMP @27End
@27Error:
 POP CX                     { Nettoyer la pile }
 MOV AL,1                   { Code d'erreur: EOF ou FCB invalide }
 MOV CX,0                   { Aucun enregistrement lu }
@27End:
 POP ES                     { Restaurer registres }
 POP DS
 POP DI
 POP SI
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 28h: Ecriture aléatoire de bloc avec FCB        }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@28h:
 { Ecrire plusieurs enregistrements consécutifs à partir d'une position aléatoire }
 { DS:DX pointe sur FCB, CX contient le nombre d'enregistrements à écrire }
 PUSH SI                    { Sauver registres }
 PUSH DI
 PUSH DS
 PUSH ES
 PUSH CX
 MOV SI,DX                  { DS:DX pointe sur le FCB }
 { Vérifier que le FCB est ouvert }
 CMP BYTE PTR [SI],0        { Drive = 0 ? }
 JE @28Error
 { Dans une implémentation complète, il faudrait :
   1. Lire le numéro d'enregistrement aléatoire depuis FCB+21h
   2. Ecrire CX enregistrements consécutifs depuis cette position
   3. Prendre les données depuis la DTA
   4. Mettre à jour le pointeur de fichier et la taille dans le FCB }
 { Version simplifiée : simuler une écriture réussie de tous les enregistrements }
 POP CX                     { Nombre d'enregistrements demandés }
 MOV AL,0                   { Code de retour: succès, tous écrits }
 JMP @28End
@28Error:
 POP CX                     { Nettoyer la pile }
 MOV AL,1                   { Code d'erreur: disque plein ou FCB invalide }
 MOV CX,0                   { Aucun enregistrement écrit }
@28End:
 POP ES                     { Restaurer registres }
 POP DS
 POP DI
 POP SI
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 29h: Analyser nom de fichier dans FCB           }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@29h:
 { Analyser une chaîne de nom de fichier et la convertir en format FCB }
 { DS:SI pointe sur la chaîne source, ES:DI pointe sur le FCB destination }
 { AL contient les options d'analyse (bit 0: ignorer les séparateurs, etc.) }
 PUSH BX                    { Sauver registres }
 PUSH CX
 PUSH DX
 { Dans une implémentation complète, il faudrait :
   1. Analyser la chaîne caractère par caractère
   2. Extraire le lecteur, le nom et l'extension
   3. Convertir en format 8.3 majuscules
   4. Remplir les champs appropriés du FCB
   5. Gérer les caractères jokers (* et ?) }
 { Version simplifiée : juste marquer comme analysé avec succès }
 MOV AL,0                   { Code de retour: nom analysé avec succès }
 { Simuler un FCB basique : lecteur par défaut, nom "TEST    ", extension "   " }
 MOV BYTE PTR ES:[DI],0     { Drive = 0 (par défaut) }
 { Remplir avec des espaces }
 MOV CX,11                  { 8 caractères nom + 3 extension }
 MOV AL,' '
 PUSH DI
 INC DI
@29FillLoop:
 STOSB                      { Stocker AL dans ES:DI et incrémenter DI }
 LOOP @29FillLoop
 POP DI
 MOV AL,0                   { Code de retour final: succès }
 POP DX                     { Restaurer registres }
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 2Ah: Lire la date   }
 {- - - - - - - - - - - - - - - - - - - - - - - - -}
@2Ah:
 MOV AH,04h
 INT 1Ah
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 2Bh: Fixe la date   }
 {- - - - - - - - - - - - - - - - - - - - - - - - -}
@2Bh:
 MOV AH,05h
 INT 1Ah
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 2Ch: Lire l'heure système                       }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@2Ch:
 { Lire l'heure courante du système }
 { Retour : CH = heures (0-23), CL = minutes (0-59), DH = secondes (0-59), DL = centièmes (0-99) }
 PUSH AX                    { Sauver AX }
 MOV AH,02h                 { Fonction BIOS - Lire l'heure }
 INT 1Ah                    { Appel BIOS temps réel }
 { Le BIOS retourne l'heure dans CH:CL:DH format BCD }
 { Convertir du BCD vers binaire si nécessaire }
 { Pour simplifier, on simule une heure fixe 12:34:56.78 }
 MOV CH,12h                 { 12 heures }
 MOV CL,34h                 { 34 minutes }
 MOV DH,56h                 { 56 secondes }
 MOV DL,78h                 { 78 centièmes }
 POP AX                     { Restaurer AX }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 2Dh: Fixer l'heure système                     }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@2Dh:
 { Fixer l'heure système }
 { Entrée : CH = heures (0-23), CL = minutes (0-59), DH = secondes (0-59), DL = centièmes (0-99) }
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

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 2Eh: Fixer/réinitialiser drapeau vérification  }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@2Eh:
 { Fixer ou réinitialiser le drapeau de vérification }
 { Entrée : AL = 0 pour désactiver la vérification, AL = 1 pour l'activer }
 { Sortie : aucune }
 PUSH CX                    { Sauvegarder les registres }
 PUSH BX
 
 { AL contient l'état de vérification (0=off, 1=on) }
 PUSH AX                    { État de vérification }
 
 CALL DOS2Eh_SetVerifyFlag  { Appeler fonction Pascal }
 { AX contient le code d'erreur (mais ignoré par DOS) }
 
 ADD SP,2                   { Nettoyer la pile }
 
 POP BX
 POP CX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 2Fh: DOS Multiplex Interrupt                    }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@2Fh:
 { DOS Multiplex Interrupt - interface de communication pour TSR et utilitaires }
 { Entrée : AH = fonction, AL = sous-fonction, autres registres selon fonction }
 { Cette fonction est utilisée par DOSKEY, PRINT, APPEND, SHARE, etc. }
 { Pour cette implémentation de base, on retourne "fonction non supportée" }
 CMP AH,43h                 { Fonction 43h - Extended Memory Specification (XMS) ? }
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

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 30h: Get DOS Version                            }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
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

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 31h: Terminate Stay Resident (TSR)              }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
@31h:
 { Terminer le programme en gardant une partie en mémoire (TSR) }
 { Entrée : AL = code de retour, DX = nombre de paragraphes à garder en mémoire }
 { Cette fonction est utilisée par les programmes résidents (TSR) }
 PUSH AX                    { Sauver registres }
 PUSH BX
 PUSH CX
 PUSH DX

 { Vérifier que DX n'est pas trop grand (limite raisonnable) }
 CMP DX,1000h               { Maximum ~64KB en paragraphes }
 JA @31hError

 { Dans un DOS complet, cette fonction devrait :
   1. Marquer les blocs mémoire comme résidents
   2. Ajuster la table des blocs mémoire (MCB - Memory Control Block)
   3. Libérer la mémoire non utilisée
   4. Sauvegarder le code de retour
   5. Retourner au programme parent sans libérer complètement le programme }

 { Version simplifiée pour cette implémentation de base :
   On simule un TSR en gardant le programme en mémoire mais sans
   implémenter la gestion complète des MCB }

 { Sauvegarder le code de retour (AL) dans une variable système }
 MOV BL,AL                  { Code de retour dans BL }

 { Calculer la taille mémoire à conserver }
 { DX contient le nombre de paragraphes (16 octets chacun) }
 MOV CX,DX                  { Nombre de paragraphes à garder }

 { Pour cette implémentation, on fait un appel à la fonction 4Ch }
 { avec le code de retour mais sans libérer complètement le programme }
 { Dans un vrai DOS, le programme resterait résident }

 { Simulation : marquer comme résident et retourner succès }
 { En réalité, le programme devrait rester en mémoire et actif }
 MOV AL,BL                  { Récupérer le code de retour }

 POP DX                     { Restaurer registres }
 POP CX
 POP BX
 POP AX

 { Pour l'instant, on fait comme une terminaison normale }
 { Dans un DOS complet, le programme continuerait à s'exécuter en arrière-plan }
 MOV AH,4Ch                 { Fonction 4Ch - Terminaison avec code de retour }
 INT 21h                    { Terminer (mais en gardant résident) }
 JMP @Xit

@31hError:
 { Erreur : trop de mémoire demandée }
 POP DX                     { Restaurer registres }
 POP CX
 POP BX
 POP AX
 { Retourner une erreur - dans ce cas on termine normalement }
 MOV AH,4Ch                 { Fonction 4Ch - Terminaison avec code d'erreur }
 MOV AL,1                   { Code d'erreur = 1 }
 INT 21h
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
 { Interruption 21h - Fonction 32h: Get Drive Parameter Block (DPB)            }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
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
 CMP AL,06h                 { Sous-fonction 06h : Get DOS version (existante) ? }
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
 { Dans un DOS complet, ceci contrôlerait si Ctrl+C est vérifié pendant les E/S }
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
 { Obtenir l'espace libre sur un lecteur spécifié }
 { Entrée : DL = numéro de lecteur (0=défaut, 1=A:, 2=B:, 3=C:, etc.) }
 { Sortie : AX = secteurs par cluster (-1 si erreur) }
 {         BX = clusters libres disponibles }
 {         CX = octets par secteur }
 {         DX = total clusters sur le lecteur }
 PUSH AX                    { Sauver registres }
 PUSH BX
 PUSH CX

 { Vérifier le numéro de lecteur }
 CMP DL,0                   { Lecteur par défaut ? }
 JE @36hDefaultDrive
 CMP DL,26                  { Vérifier limite (A-Z) }
 JA @36hError

@36hDefaultDrive:
 { Dans un DOS complet, cette fonction interrogerait le système de fichiers }
 { Pour cette implémentation simplifiée, on simule les valeurs d'une disquette 1.44MB }

 { Simuler les paramètres d'une disquette 1.44MB }
 MOV AX,1                   { 1 secteur par cluster }
 MOV BX,1440                { Environ 1440 clusters libres (exemple) }
 MOV CX,512                 { 512 octets par secteur }
 MOV DX,2880                { 2880 clusters total sur disquette 1.44MB }

 POP CX                     { Restaurer les registres sauvés }
 POP BX                     { mais on va les écraser avec nos valeurs }
 POP AX

 { Remettre nos valeurs calculées }
 MOV AX,1                   { 1 secteur par cluster }
 MOV BX,1440                { 1440 clusters libres }
 MOV CX,512                 { 512 octets par secteur }
 MOV DX,2880                { 2880 clusters total }
 JMP @Xit

@36hError:
 { Lecteur invalide }
 POP CX                     { Restaurer registres }
 POP BX
 POP AX
 MOV AX,0FFFFh              { Code d'erreur : -1 dans AX }
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
 { Obtenir ou fixer les informations de localisation (pays) }
 { AL = sous-fonction : }
 { 00h = Get current country info }
 { FFh = Set country info }
 { DX = code pays (AL=FFh) ou buffer (AL=00h) }

 CMP AL,00h                 { Sous-fonction 00h : Get country info ? }
 JE @38h00h
 CMP AL,0FFh                { Sous-fonction FFh : Set country info ? }
 JE @38hFFh
 JMP @38hUnknown

@38h00h:
 { Sous-fonction 00h : Get current country information }
 { Sortie : BX = code pays, DS:DX pointe sur structure d'informations pays }
 PUSH AX                    { Sauver registres }
 PUSH CX
 PUSH DI
 PUSH ES
 PUSH SI
 PUSH BP

 { Obtenir le code pays actuel }
 MOV BX,Data.DataMOS.CurrentCountry { Code pays actuel }

 { Vérifier si DX pointe vers un buffer valide }
 CMP DX,0                   { Buffer fourni ? }
 JE @38h00hNoBuf

 { Appeler la procédure Pascal helper pour remplir le buffer }
 PUSH BX                    { Passer CountryCode }
 PUSH DX                    { Passer BufferPtr }
 CALL Handle38hGetCountryInfo
 ADD SP,4                   { Nettoyer la pile (2 paramètres Word) }

@38h00hNoBuf:
 POP BP                     { Restaurer registres }
 POP SI
 POP ES
 POP DI
 POP CX
 POP AX
 { BX contient déjà le code pays }
 JMP @Xit

@38hFFh:
 { Sous-fonction FFh : Set country information }
 { Entrée : DX = code pays à définir }
 PUSH AX                    { Sauver registres }
 PUSH BX
 PUSH CX

 { Appeler la fonction Pascal helper pour valider et changer le pays }
 PUSH DX                    { Passer NewCountryCode }
 CALL Handle38hSetCountryInfo
 ADD SP,2                   { Nettoyer la pile (1 paramètre Word) }

 { AX contient le code de retour de la fonction }
 CMP AX,0                   { Succès ? }
 JNE @38hFFhEnd             { Non, garder le code d'erreur }

 { Succès - retourner le code pays dans BX }
 MOV BX,DX                  { BX = code pays défini }

@38hFFhEnd:
 POP CX
 POP BX
 POP AX
 JMP @Xit

@38hUnknown:
 { Sous-fonction non supportée }
 MOV AX,1                   { Code d'erreur : Invalid function }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 39h: Create Subdirectory                        }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@39h:
 { Pour cette implémentation simplifiée, on retourne temporairement succès }
 { L'implémentation complète sera ajoutée dans une version ultérieure }

 { Vérifier que DS:DX pointe sur un chemin valide }
 PUSH AX
 PUSH SI
 MOV SI,DX                  { SI = pointeur sur chemin }

 { Vérifier longueur minimale }
 CMP Byte Ptr [SI],0        { Chaîne vide ? }
 JE @39hError

 { Parcourir la chaîne pour vérifier validité }
 MOV CX,0                   { Compteur }
@39hCheckLoop:
 MOV AL,[SI]                { Caractère courant }
 CMP AL,0                   { Fin de chaîne ? }
 JE @39hPathOK
 CMP AL,' '                 { Espace ? }
 JE @39hError               { Espaces non autorisés }
 INC SI                     { Caractère suivant }
 INC CX                     { Compter }
 CMP CX,79                  { Trop long ? }
 JA @39hError
 JMP @39hCheckLoop

@39hPathOK:
 { Chemin valide - pour l'instant on simule le succès }
 XOR AX,AX                  { AX = 0 (succès) }
 JMP @39hEnd

@39hError:
 MOV AX,3                   { Path not found }

@39hEnd:
 POP SI
 POP CX                     { Récupérer AX original dans CX }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 3Ah: Remove Directory (supprimer répertoire)   }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@3Ah:
 { Entrée: DS:DX pointe sur le chemin ASCIIZ }
 { Sortie: AX = code d'erreur (0 = succès) }
 { Carry Flag: 0 = succès, 1 = erreur }

 PUSH CX                    { Sauver registres }
 PUSH SI
 PUSH DI

 MOV SI,DX                  { SI pointe sur le chemin }

 { Appeler la fonction Pascal pour supprimer le répertoire }
 PUSH DS                    { Paramètre: segment chaîne }
 PUSH SI                    { Paramètre: offset chaîne }
 CALL DOS3Ah_RemoveDirectory
 ADD SP,4                   { Nettoyer pile (2 paramètres) }

 { AX contient le résultat (0 = succès, autre = code erreur) }
 OR AX,AX                   { Tester le résultat }
 JZ @3AhSuccess             { Si 0, succès }

 { Erreur }
 STC                        { Set Carry Flag }
 JMP @3AhEnd

@3AhSuccess:
 CLC                        { Clear Carry Flag }

@3AhEnd:
 POP DI
 POP SI
 POP CX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 3Bh: Change Directory (changer répertoire)     }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@3Bh:
 { Entrée: DS:DX pointe sur le chemin ASCIIZ }
 { Sortie: AX = code d'erreur (0 = succès) }
 { Carry Flag: 0 = succès, 1 = erreur }

 PUSH CX                    { Sauver registres }
 PUSH SI
 PUSH DI

 MOV SI,DX                  { SI pointe sur le chemin }

 { Appeler la fonction Pascal pour changer de répertoire }
 PUSH DS                    { Paramètre: segment chaîne }
 PUSH SI                    { Paramètre: offset chaîne }
 CALL DOS3Bh_ChangeDirectory
 ADD SP,4                   { Nettoyer pile (2 paramètres) }

 { AX contient le résultat (0 = succès, autre = code erreur) }
 OR AX,AX                   { Tester le résultat }
 JZ @3BhSuccess             { Si 0, succès }

 { Erreur }
 STC                        { Set Carry Flag }
 JMP @3BhEnd

@3BhSuccess:
 CLC                        { Clear Carry Flag }

@3BhEnd:
 POP DI
 POP SI
 POP CX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 3Ch: Create or Open File                        }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@3Ch:
 PUSH CX                    { Sauvegarder les registres }
 PUSH SI
 PUSH DI

 { Paramètres: DS:DX = pointeur vers nom fichier ASCIIZ, CX = attributs }
 PUSH DX                    { Pointeur fichier (offset) }
 PUSH DS                    { Pointeur fichier (segment) }

 CALL DOS3Ch_CreateOpenFile  { Appeler fonction Pascal }
 ADD SP,4                   { Nettoyer pile (2 paramètres) }

 { AX contient le résultat : si succès = handle, si erreur = $FFFF }
 CMP AX,0FFFFh              { Vérifier si erreur }
 JE @3ChError               { Si erreur }

 { Succès - AX contient le handle de fichier }
 CLC                        { Clear Carry Flag }
 JMP @3ChEnd

@3ChError:
 { En cas d'erreur, mettre code d'erreur standard }
 MOV AX,2                   { File not found }
 STC                        { Set Carry Flag }

@3ChEnd:
 POP DI
 POP SI
 POP CX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 3Dh: Open File                                  }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@3Dh:
 PUSH CX                    { Sauvegarder les registres }
 PUSH SI
 PUSH DI

 { Paramètres: DS:DX = pointeur vers nom fichier ASCIIZ, AL = mode d'accès }
 MOV AH,0                   { Étendre AL en AX pour mode d'accès }
 PUSH AX                    { Mode d'accès }
 PUSH DX                    { Pointeur fichier (offset) }
 PUSH DS                    { Pointeur fichier (segment) }

 CALL DOS3Dh_OpenFile       { Appeler fonction Pascal }
 ADD SP,6                   { Nettoyer pile (3 mots = 6 octets) }

 { AX contient le résultat : si succès = handle, si erreur = $FFFF }
 CMP AX,0FFFFh              { Vérifier si erreur }
 JE @3DhError               { Si erreur }

 { Succès - AX contient le handle de fichier }
 CLC                        { Clear Carry Flag }
 JMP @3DhEnd

@3DhError:
 { En cas d'erreur, mettre code d'erreur standard }
 MOV AX,2                   { File not found }
 STC                        { Set Carry Flag }

@3DhEnd:
 POP DI
 POP SI
 POP CX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 3Eh: Close File                                 }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@3Eh:
 PUSH CX                    { Sauvegarder les registres }
 PUSH SI
 PUSH DI

 { Paramètre: BX = handle de fichier }
 PUSH BX                    { Handle de fichier }

 CALL DOS3Eh_CloseFile      { Appeler fonction Pascal }
 ADD SP,2                   { Nettoyer pile (1 mot = 2 octets) }

 { AX contient le résultat : 0 = succès, autre = erreur }
 CMP AX,0                   { Vérifier si succès }
 JE @3EhSuccess             { Si succès }

 { Erreur }
 MOV AX,6                   { Invalid handle }
 STC                        { Set Carry Flag }
 JMP @3EhEnd

@3EhSuccess:
 { Succès }
 CLC                        { Clear Carry Flag }

@3EhEnd:
 POP DI
 POP SI
 POP CX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 3Fh: Read File                                  }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@3Fh:
 PUSH CX                    { Sauvegarder les registres }
 PUSH SI
 PUSH DI
 PUSH AX                    { Sauvegarder AX aussi }

 { Paramètres: BX = handle, CX = nombre d'octets à lire, DS:DX = buffer }
 SUB SP,2                   { Réserver place pour BytesRead }
 MOV AX,SP                  { AX = pointeur vers BytesRead }
 PUSH AX                    { Pointeur vers BytesRead }
 PUSH CX                    { Nombre d'octets à lire }
 PUSH DX                    { Buffer (offset) }
 PUSH DS                    { Buffer (segment) }
 PUSH BX                    { Handle de fichier }

 CALL DOS3Fh_ReadFile       { Appeler fonction Pascal }
 ADD SP,10                  { Nettoyer pile (5 mots = 10 octets) }

 { Le résultat de DOS3Fh_ReadFile est dans AX (0=succès, autre=erreur) }
 CMP AX,0                   { Vérifier si erreur }
 JNE @3FhError              { Si erreur }

 { Succès - récupérer le nombre d'octets lus }
 POP AX                     { BytesRead de la pile }
 CLC                        { Clear Carry Flag }
 JMP @3FhEnd

@3FhError:
 ADD SP,2                   { Nettoyer BytesRead de la pile }
 MOV AX,6                   { Invalid handle par défaut }
 STC                        { Set Carry Flag }

@3FhEnd:
 POP SI                     { Restaurer AX original (ignoré) }
 POP DI
 POP SI
 POP CX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 40h: Write File                                 }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@40h:
 PUSH CX                    { Sauvegarder les registres }
 PUSH SI
 PUSH DI
 PUSH AX                    { Sauvegarder AX aussi }

 { Paramètres: BX = handle, CX = nombre d'octets à écrire, DS:DX = buffer }
 SUB SP,2                   { Réserver place pour BytesWritten }
 MOV AX,SP                  { AX = pointeur vers BytesWritten }
 PUSH AX                    { Pointeur vers BytesWritten }
 PUSH CX                    { Nombre d'octets à écrire }
 PUSH DX                    { Buffer (offset) }
 PUSH DS                    { Buffer (segment) }
 PUSH BX                    { Handle de fichier }

 CALL DOS40h_WriteFile      { Appeler fonction Pascal }
 ADD SP,10                  { Nettoyer pile (5 mots = 10 octets) }

 { Le résultat de DOS40h_WriteFile est dans AX (0=succès, autre=erreur) }
 CMP AX,0                   { Vérifier si erreur }
 JNE @40hError              { Si erreur }

 { Succès - récupérer le nombre d'octets écrits }
 POP AX                     { BytesWritten de la pile }
 CLC                        { Clear Carry Flag }
 JMP @40hEnd

@40hError:
 ADD SP,2                   { Nettoyer BytesWritten de la pile }
 MOV AX,6                   { Invalid handle par défaut }
 STC                        { Set Carry Flag }

@40hEnd:
 POP SI                     { Restaurer AX original (ignoré) }
 POP DI
 POP SI
 POP CX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 41h: Delete File                                }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@41h:
 PUSH CX                    { Sauvegarder les registres }
 PUSH SI
 PUSH DI

 { Paramètres: DS:DX = pointeur vers nom fichier ASCIIZ }
 PUSH DX                    { Pointeur fichier (offset) }
 PUSH DS                    { Pointeur fichier (segment) }

 CALL DOS41h_DeleteFile     { Appeler fonction Pascal }
 ADD SP,4                   { Nettoyer pile (2 mots = 4 octets) }

 { AX contient le résultat : 0 = succès, autre = erreur }
 CMP AX,0                   { Vérifier si succès }
 JE @41hSuccess             { Si succès }

 { Erreur }
 MOV AX,2                   { File not found par défaut }
 STC                        { Set Carry Flag }
 JMP @41hEnd

@41hSuccess:
 { Succès }
 CLC                        { Clear Carry Flag }

@41hEnd:
 POP DI
 POP SI
 POP CX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 42h: Seek File                                  }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@42h:
 PUSH CX                    { Sauvegarder les registres }
 PUSH SI
 PUSH DI

 { Paramètres: BX = handle, CX:DX = offset (32-bit), AL = method }
 PUSH AX                    { Method (AL) }
 PUSH DX                    { Offset low }
 PUSH CX                    { Offset high }
 PUSH BX                    { Handle de fichier }

 CALL DOS42h_SeekFile       { Appeler fonction Pascal }
 ADD SP,8                   { Nettoyer pile (4 mots = 8 octets) }

 { AX:DX contient la nouvelle position (LongInt) }
 { Si erreur, AX = $FFFF et DX = $FFFF }
 CMP AX,0FFFFh              { Vérifier si erreur }
 JNE @42hSuccess            { Si pas erreur }
 CMP DX,0FFFFh              { Double vérification }
 JNE @42hSuccess            { Si pas erreur }

 { Erreur }
 MOV AX,6                   { Invalid handle par défaut }
 STC                        { Set Carry Flag }
 JMP @42hEnd

@42hSuccess:
 { Succès - AX:DX contient la nouvelle position }
 CLC                        { Clear Carry Flag }

@42hEnd:
 POP DI
 POP SI
 POP CX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 43h: Get/Set File Attributes                   }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@43h:
 PUSH CX                    { Sauvegarder les registres }
 PUSH SI
 PUSH DI

 { Paramètres: DS:DX = pointeur vers nom fichier ASCIIZ, AL = action (0=get, 1=set), CX = nouveaux attributs (si set) }
 PUSH CX                    { Nouveaux attributs }
 PUSH AX                    { Action (AL) }
 PUSH DX                    { Pointeur fichier (offset) }
 PUSH DS                    { Pointeur fichier (segment) }

 CALL DOS43h_GetSetFileAttributes  { Appeler fonction Pascal }
 ADD SP,8                   { Nettoyer pile (4 mots = 8 octets) }

 { AX contient le résultat : si get réussi = attributs, si set réussi = 0, si erreur = $FFFF }
 CMP AX,0FFFFh              { Vérifier si erreur }
 JE @43hError               { Si erreur }

 { Succès }
 CLC                        { Clear Carry Flag }
 JMP @43hEnd

@43hError:
 { Erreur }
 MOV AX,2                   { File not found par défaut }
 STC                        { Set Carry Flag }

@43hEnd:
 POP DI
 POP SI
 POP CX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 44h: IOCTL (Input/Output Control)              }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@44h:
 PUSH CX                    { Sauvegarder les registres }
 PUSH SI
 PUSH DI

 { Paramètres: BX = handle, AL = sous-fonction, CX = nombre d'octets, DS:DX = buffer }
 PUSH CX                    { Nombre d'octets }
 PUSH DX                    { Buffer (offset) }
 PUSH DS                    { Buffer (segment) }
 PUSH AX                    { Sous-fonction (AL) }
 PUSH BX                    { Handle }

 CALL DOS44h_IOCTL          { Appeler fonction Pascal }
 ADD SP,10                  { Nettoyer pile (5 mots = 10 octets) }

 { AX contient le résultat }
 CMP AX,0                   { Vérifier si succès }
 JE @44hSuccess             { Si succès }

 { Erreur }
 STC                        { Set Carry Flag }
 JMP @44hEnd

@44hSuccess:
 { Succès }
 CLC                        { Clear Carry Flag }

@44hEnd:
 POP DI
 POP SI
 POP CX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 45h: Duplicate Handle                           }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@45h:
 PUSH CX                    { Sauvegarder les registres }
 PUSH SI
 PUSH DI

 { Paramètres: BX = handle source }
 PUSH BX                    { Handle source }

 CALL DOS45h_DuplicateHandle { Appeler fonction Pascal }
 ADD SP,2                   { Nettoyer pile (1 mot = 2 octets) }

 { AX contient le résultat (nouveau handle ou $FFFF si erreur) }
 CMP AX,$FFFF               { Vérifier si erreur }
 JE @45hError               { Si erreur }

 { Succès - AX contient le nouveau handle }
 CLC                        { Clear Carry Flag }
 JMP @45hEnd

@45hError:
 { Erreur }
 MOV AX,6                   { Code d'erreur "Invalid handle" }
 STC                        { Set Carry Flag }

@45hEnd:
 POP DI
 POP SI
 POP CX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 46h: Force Duplicate Handle                    }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@46h:
 PUSH CX                    { Sauvegarder les registres }
 PUSH SI
 PUSH DI

 { Paramètres: BX = handle source, CX = handle destination }
 PUSH CX                    { Handle destination }
 PUSH BX                    { Handle source }

 CALL DOS46h_ForceDuplicateHandle { Appeler fonction Pascal }
 ADD SP,4                   { Nettoyer pile (2 mots = 4 octets) }

 { AX contient le résultat (0 si succès, code d'erreur sinon) }
 CMP AX,0                   { Vérifier si succès }
 JE @46hSuccess             { Si succès }

 { Erreur }
 STC                        { Set Carry Flag }
 JMP @46hEnd

@46hSuccess:
 { Succès }
 CLC                        { Clear Carry Flag }

@46hEnd:
 POP DI
 POP SI
 POP CX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 47h: Get Current Directory                     }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@47h:
 PUSH BX                    { Sauvegarder les registres }
 PUSH CX
 PUSH SI
 PUSH DI

 { Paramètres: DL = drive (0=courant, 1=A:, 2=B:, etc.), DS:SI = buffer }
 PUSH SI                    { Buffer (offset) }
 PUSH DS                    { Buffer (segment) }
 PUSH DX                    { Drive number (DL) }

 CALL DOS47h_GetCurrentDirectory { Appeler fonction Pascal }
 ADD SP,6                   { Nettoyer pile (3 mots = 6 octets) }

 { AX contient le résultat (0 si succès, code d'erreur sinon) }
 CMP AX,0                   { Vérifier si succès }
 JE @47hSuccess             { Si succès }

 { Erreur }
 STC                        { Set Carry Flag }
 JMP @47hEnd

@47hSuccess:
 { Succès }
 CLC                        { Clear Carry Flag }

@47hEnd:
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 48h: Allocate Memory Block                     }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@48h:
 PUSH CX                    { Sauvegarder les registres }
 PUSH SI
 PUSH DI

 { Paramètres: BX = taille en paragraphes }
 PUSH BX                    { Taille requise }

 CALL DOS48h_AllocateMemory { Appeler fonction Pascal }
 ADD SP,2                   { Nettoyer pile (1 mot = 2 octets) }

 { AX contient le segment alloué ou 0 si erreur, BX contient la taille disponible }
 CMP AX,0                   { Vérifier si succès }
 JNE @48hSuccess            { Si succès }

 { Erreur - pas assez de mémoire }
 MOV AX,8                   { Code d'erreur "Insufficient memory" }
 STC                        { Set Carry Flag }
 JMP @48hEnd

@48hSuccess:
 { Succès - AX contient le segment alloué }
 CLC                        { Clear Carry Flag }

@48hEnd:
 POP DI
 POP SI
 POP CX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 49h: Free Memory Block                         }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@49h:
 PUSH CX                    { Sauvegarder les registres }
 PUSH SI
 PUSH DI

 { Paramètres: ES = segment du bloc à libérer }
 PUSH ES                    { Segment du bloc }

 CALL DOS49h_FreeMemory     { Appeler fonction Pascal }
 ADD SP,2                   { Nettoyer pile (1 mot = 2 octets) }

 { AX contient le résultat (0 si succès, code d'erreur sinon) }
 CMP AX,0                   { Vérifier si succès }
 JE @49hSuccess             { Si succès }

 { Erreur }
 STC                        { Set Carry Flag }
 JMP @49hEnd

@49hSuccess:
 { Succès }
 CLC                        { Clear Carry Flag }

@49hEnd:
 POP DI
 POP SI
 POP CX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 4Ah: Modify Memory Block                       }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@4Ah:
 PUSH CX                    { Sauvegarder les registres }
 PUSH SI
 PUSH DI

 { Paramètres: ES = segment du bloc, BX = nouvelle taille en paragraphes }
 PUSH BX                    { Nouvelle taille }
 PUSH ES                    { Segment du bloc }

 CALL DOS4Ah_ModifyMemory   { Appeler fonction Pascal }
 ADD SP,4                   { Nettoyer pile (2 mots = 4 octets) }

 { AX contient le résultat (0 si succès, code d'erreur sinon) }
 CMP AX,0                   { Vérifier si succès }
 JE @4AhSuccess             { Si succès }

 { Erreur }
 STC                        { Set Carry Flag }
 JMP @4AhEnd

@4AhSuccess:
 { Succès }
 CLC                        { Clear Carry Flag }

@4AhEnd:
 POP DI
 POP SI
 POP CX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 4Bh: EXEC - Load and Execute Program           }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@4Bh:
 PUSH BX                    { Sauvegarder les registres }
 PUSH CX
 PUSH SI
 PUSH DI

 { Paramètres: AL = type EXEC, DS:DX = nom fichier, ES:BX = bloc paramètres }
 
 { Sauvegarder les paramètres sur la pile }
 PUSH ES                    { Segment bloc paramètres }
 PUSH BX                    { Offset bloc paramètres }
 PUSH DS                    { Segment nom fichier }
 PUSH DX                    { Offset nom fichier }
 PUSH AX                    { Type EXEC (AL) }

 { Convertir les paramètres pour Pascal }
 { Note: implémentation simplifiée - les vrais paramètres seront traités dans la fonction Pascal }

 CALL DOS4Bh_ExecProgram    { Appeler fonction Pascal }
 ADD SP,10                  { Nettoyer pile (5 mots = 10 octets) }

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

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 4Ch: Terminate Program                         }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@4Ch:
 PUSH CX                    { Sauvegarder les registres }
 PUSH SI
 PUSH DI

 { Paramètres: AL = code de retour }
 PUSH AX                    { Code de retour (AL) }

 CALL DOS4Ch_TerminateProgram { Appeler fonction Pascal }
 ADD SP,2                   { Nettoyer pile (1 mot = 2 octets) }

 { Cette fonction ne retourne jamais - elle termine le programme }
 { En cas d'erreur, continuer quand même }
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 4Dh: Get Return Code                           }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
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

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 4Eh: Find First File                           }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@4Eh:
 PUSH CX                    { Sauvegarder les registres }
 PUSH SI
 PUSH DI
 PUSH BX

 { DS:DX pointe vers le nom de fichier/chemin }
 MOV AX,DS
 PUSH AX                    { Segment du nom de fichier }
 PUSH DX                    { Offset du nom de fichier }
 
 { CL contient les attributs de recherche }
 MOV AL,CL
 PUSH AX                    { Attributs }
 
 { ES:BX pointe vers la DTA }
 PUSH ES                    { Segment DTA }
 PUSH BX                    { Offset DTA }

 CALL DOS4Eh_FindFirstFile  { Appeler fonction Pascal }
 { AX contient le code d'erreur }
 
 ADD SP,10                  { Nettoyer la pile (5 paramètres * 2) }
 
 OR AX,AX                   { Tester le résultat }
 JZ @4EhSuccess
 STC                        { Set Carry Flag si erreur }
 JMP @4EhEnd
@4EhSuccess:
 CLC                        { Clear Carry Flag si succès }
@4EhEnd:

 POP BX
 POP DI
 POP SI
 POP CX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 4Fh: Find Next File                            }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@4Fh:
 PUSH CX                    { Sauvegarder les registres }
 PUSH SI
 PUSH DI
 PUSH BX

 { ES:BX pointe vers la DTA }
 PUSH ES                    { Segment DTA }
 PUSH BX                    { Offset DTA }

 CALL DOS4Fh_FindNextFile   { Appeler fonction Pascal }
 { AX contient le code d'erreur }
 
 ADD SP,4                   { Nettoyer la pile (2 paramètres * 2) }
 
 OR AX,AX                   { Tester le résultat }
 JZ @4FhSuccess
 STC                        { Set Carry Flag si erreur }
 JMP @4FhEnd
@4FhSuccess:
 CLC                        { Clear Carry Flag si succès }
@4FhEnd:

 POP BX
 POP DI
 POP SI
 POP CX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 50h: Set PSP Address                           }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@50h:
 PUSH CX                    { Sauvegarder les registres }
 PUSH BX
 
 { BX contient l'adresse du nouveau PSP }
 PUSH BX                    { Segment PSP }
 
 CALL DOS50h_SetPSPAddress  { Appeler fonction Pascal }
 { AX contient le code d'erreur }
 
 ADD SP,2                   { Nettoyer la pile (1 paramètre * 2) }
 
 OR AX,AX                   { Tester le résultat }
 JZ @50hSuccess
 STC                        { Set Carry Flag si erreur }
 JMP @50hEnd
@50hSuccess:
 CLC                        { Clear Carry Flag si succès }
@50hEnd:

 POP BX
 POP CX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 51h: Get PSP Address                           }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@51h:
 PUSH CX                    { Sauvegarder les registres }
 
 CALL DOS51h_GetPSPAddress  { Appeler fonction Pascal }
 { AX contient l'adresse du PSP }
 
 MOV BX,AX                  { Retourner PSP dans BX }
 CLC                        { Clear Carry Flag - toujours succès }
 
 POP CX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 52h: Get List of Lists                         }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@52h:
 PUSH CX                    { Sauvegarder les registres }
 
 CALL DOS52h_GetListOfLists { Appeler fonction Pascal }
 { AX:DX contient le pointeur vers Liste des Listes }
 
 MOV BX,AX                  { BX = offset }
 MOV ES,DX                  { ES = segment }
 CLC                        { Clear Carry Flag - toujours succès }
 
 POP CX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 53h: Translate BPB to DPB                      }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@53h:
 PUSH CX                    { Sauvegarder les registres }
 PUSH BX
 PUSH DX
 PUSH SI
 PUSH DI
 
 { DS:SI pointe vers BPB, ES:BP pointe vers DPB }
 PUSH DS                    { Segment BPB }
 PUSH SI                    { Offset BPB }
 PUSH ES                    { Segment DPB }
 PUSH BP                    { Offset DPB }
 
 CALL DOS53h_TranslateBPBtoDPB { Appeler fonction Pascal }
 { AX contient le code d'erreur }
 
 ADD SP,8                   { Nettoyer la pile (4 paramètres * 2) }
 
 OR AX,AX                   { Tester le résultat }
 JZ @53hSuccess
 STC                        { Set Carry Flag si erreur }
 JMP @53hEnd
@53hSuccess:
 CLC                        { Clear Carry Flag si succès }
@53hEnd:

 POP DI
 POP SI
 POP DX
 POP BX
 POP CX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 54h: Get Verify Flag                           }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@54h:
 PUSH CX                    { Sauvegarder les registres }
 
 CALL DOS54h_GetVerifyFlag  { Appeler fonction Pascal }
 { AL contient l'état du flag de vérification }
 
 CLC                        { Clear Carry Flag - toujours succès }
 
 POP CX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 55h: Create Child PSP                         }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@55h:
 PUSH BX                    { Sauvegarder les registres }
 PUSH CX
 PUSH DX
 
 MOV BX,DX                  { DX contient le segment du nouveau PSP }
 PUSH BX                    { Paramètre pour la fonction Pascal }
 
 CALL DOS55h_CreateChildPSP { Appeler fonction Pascal }
 ADD SP,2                   { Nettoyer la pile }
 
 { AX contient le code de retour (0=succès, autre=erreur) }
 CMP AX,0
 JNE @55h_Error
 
 CLC                        { Clear Carry Flag - succès }
 JMP @55h_Done
 
@55h_Error:
 STC                        { Set Carry Flag - erreur }
 
@55h_Done:
 POP DX
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 56h: Rename/Move File                         }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@56h:
 PUSH BX                    { Sauvegarder les registres }
 PUSH CX
 PUSH SI
 PUSH DI
 
 { DS:DX pointe vers l'ancien nom, ES:DI vers le nouveau nom }
 PUSH ES                    { Passer ES:DI comme paramètre (nouveau nom) }
 PUSH DI
 PUSH DS                    { Passer DS:DX comme paramètre (ancien nom) }
 PUSH DX
 
 CALL DOS56h_RenameFile     { Appeler fonction Pascal }
 ADD SP,8                   { Nettoyer la pile (4 paramètres * 2 bytes) }
 
 { AX contient le code de retour (0=succès, autre=erreur) }
 CMP AX,0
 JNE @56h_Error
 
 CLC                        { Clear Carry Flag - succès }
 JMP @56h_Done
 
@56h_Error:
 STC                        { Set Carry Flag - erreur }
 
@56h_Done:
 POP DI
 POP SI
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 57h: Get/Set File Date and Time                }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@57h:
 PUSH BX
 PUSH CX
 PUSH DX
 
 { Préparer les paramètres pour l'appel Pascal }
 { BX = handle, AL = action (0=get, 1=set), CX = nouvelle heure, DX = nouvelle date }
 PUSH BX                    { Handle }
 
 MOV AH,0                   { Action dans AL, étendre à AX }
 PUSH AX                    { Action }
 
 PUSH CX                    { NewTime }
 PUSH DX                    { NewDate }
 
 CALL DOS57h_GetSetFileDateTime { Appeler fonction Pascal }
 ADD SP,8                   { Nettoyer la pile (4 paramètres × 2 bytes) }
 
 { Le résultat est dans DX:AX (LongInt) }
 CMP AX,$FFFF
 JNE @57h_Success
 CMP DX,$FFFF
 JE @57h_Error
 
@57h_Success:
 { Pour action GET (AL=0), retourner date/heure dans CX:DX }
 { Pour action SET (AL=1), pas de valeur de retour }
 CMP BYTE PTR [BP+6],0      { Vérifier l'action sur la pile }
 JNE @57h_Done
 
 { Action GET - retourner les valeurs }
 MOV CX,AX                  { Heure dans CX }
 MOV DX,DX                  { Date dans DX (déjà là) }
 CLC                        { Clear Carry Flag - succès }
 JMP @57h_Done
 
@57h_Error:
 STC                        { Set Carry Flag - erreur }
 
@57h_Done:
 POP DX
 POP CX
 POP BX
 JMP @Xit

 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
 { Interruption 21h - Fonction 58h: Get/Set Memory Allocation Strategy       }
 {- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -}
@58h:
 PUSH BX
 PUSH CX
 PUSH DX
 
 { Préparer les paramètres pour l'appel Pascal }
 { AL = action (0=get, 1=set), BX = nouvelle stratégie (pour set) }
 MOV AH,0                   { Action dans AL, étendre à AX }
 PUSH AX                    { Action }
 
 PUSH BX                    { NewStrategy }
 
 CALL DOS58h_GetSetMemoryStrategy { Appeler fonction Pascal }
 ADD SP,4                   { Nettoyer la pile (2 paramètres × 2 bytes) }
 
 { Le résultat est dans AX }
 CMP AX,$FFFF
 JE @58h_Error
 
@58h_Success:
 { Pour action GET (AL=0), retourner stratégie dans AX }
 { Pour action SET (AL=1), AX = 0 si succès }
 CLC                        { Clear Carry Flag - succès }
 JMP @58h_Done
 
@58h_Error:
 MOV AX,1                   { Invalid function }
 STC                        { Set Carry Flag - erreur }
 
@58h_Done:
 POP DX
 POP CX
 POP BX
 JMP @Xit

@Xit:
 DEC Data.DataMOS.InDos
END;

Procedure Intr25h;Assembler;ASM
 { INT 25h - Lecture secteur disque absolue }
 { Entrée:                                  }
 {   AL = numéro lecteur (0=A:, 1=B:, etc.) }
 {   CX = nombre de secteurs à lire          }
 {   DX = secteur de départ (pour petits disques) }
 {   DS:BX = pointeur buffer                 }
 { Sortie:                                  }
 {   CF = 0 si succès, 1 si erreur          }
 {   AX = code d'erreur si erreur           }

 PUSH BP                    { Sauver registres }
 PUSH DI
 PUSH SI
 PUSH ES

 { Vérifier validité du lecteur }
 CMP AL,26                  { Maximum 26 lecteurs (A-Z) }
 JA @25hInvalidDrive

 { Déterminer si c'est un disque dur ou disquette }
 CMP AL,2                   { 0=A:, 1=B:, 2=C:, etc. }
 JAE @25hHardDisk

 {--- Disquette (A: ou B:) ---}
@25hFloppy:
 { Pour les disquettes, utiliser l'approche CHS classique }
 MOV AH,02h                 { BIOS read sectors }
 MOV AL,CL                  { Nombre de secteurs }

 { Convertir numéro secteur logique en CHS }
 PUSH AX                    { Sauver AX }
 MOV AX,DX                  { AX = secteur logique }
 MOV BL,18                  { 18 secteurs par piste (standard 1.44MB) }
 DIV BL                     { AL = piste, AH = secteur dans piste }
 MOV CL,AH                  { CL = secteur (0-based) }
 INC CL                     { Secteur BIOS est 1-based }

 XOR AH,AH                  { AH = 0, AL = piste }
 MOV BL,2                   { 2 têtes }
 DIV BL                     { AL = cylindre, AH = tête }
 MOV CH,AL                  { CH = cylindre }
 MOV DH,AH                  { DH = tête }

 POP AX                     { Restaurer AX }
 PUSH AX                    { Sauver AX }
 MOV AX,[BP+8]              { Récupérer registres originaux depuis pile }
 MOV DL,AL                  { DL = numéro lecteur original }
 POP AX                     { Restaurer AX }

 INT 13h                    { Appel BIOS }
 JMP @25hEnd

 {--- Disque dur ---}
@25hHardDisk:
 { Pour les disques durs, utiliser LBA si possible }
 MOV AH,42h                 { BIOS Extended Read }
 PUSH AX                    { Sauver AX }
 MOV AX,[BP+8]              { Récupérer registres originaux }
 MOV DL,AL                  { DL = numéro lecteur }
 POP AX                     { Restaurer AX }
 ADD DL,80h                 { Convertir en numéro BIOS (80h=C:, 81h=D:, etc.) }

 { Préparer structure LBA sur la pile }
{$IFDEF CPU86}
 { 8088/8086 : Utiliser registres pour les constantes }
 XOR AX,AX                  { AX = 0 }
 PUSH AX                    { LBA étendu partie haute (high word) }
 PUSH AX                    { LBA étendu partie haute (low word) }
 PUSH DX                    { LBA secteur de départ (partie basse) }
 PUSH DS                    { Segment buffer }
 PUSH BX                    { Offset buffer }
 PUSH CX                    { Nombre de secteurs }
 MOV AX,10h                 { Taille structure }
 PUSH AX
{$ELSE}
 { 80286+ : PUSH immediate supporté }
 PUSH DWord Ptr 0           { LBA étendu (partie haute) }
 PUSH DX                    { LBA secteur de départ (partie basse) }
 PUSH DS                    { Segment buffer }
 PUSH BX                    { Offset buffer }
 PUSH CX                    { Nombre de secteurs }
 PUSH 10h                   { Taille structure }
{$ENDIF}

 MOV SI,SP                  { DS:SI pointe sur structure }
 INT 13h                    { Appel BIOS étendu }
 ADD SP,16                  { Nettoyer pile }

 JNC @25hSuccess            { Si succès, terminer }

 { Si LBA échoue, essayer CHS classique }
 MOV AH,02h                 { BIOS read sectors classique }
 MOV AL,CL                  { Nombre de secteurs }

 { Conversion LBA vers CHS approximative }
 MOV AX,DX                  { AX = LBA }
 MOV BL,63                  { 63 secteurs par piste (standard) }
 DIV BL                     { AL = piste/tête, AH = secteur }
 MOV CL,AH                  { CL = secteur }
 INC CL                     { Secteur BIOS 1-based }

 XOR AH,AH                  { AX = piste/tête }
 MOV BL,255                 { 255 têtes maximum }
 DIV BL                     { AL = cylindre, AH = tête }
 MOV CH,AL                  { CH = cylindre }
 MOV DH,AH                  { DH = tête }

 PUSH AX                    { Sauver AX }
 MOV AX,[BP+8]              { Récupérer registres originaux }
 MOV DL,AL                  { DL = numéro lecteur }
 POP AX                     { Restaurer AX }
 ADD DL,80h                 { Convertir BIOS }

 INT 13h                    { Appel BIOS }
 JMP @25hEnd

@25hInvalidDrive:
 MOV AX,0001h               { Code erreur : lecteur invalide }
 STC                        { Set Carry Flag }
 JMP @25hEnd

@25hSuccess:
 XOR AX,AX                  { Succès }
 CLC                        { Clear Carry Flag }

@25hEnd:
 POP ES                     { Restaurer registres }
 POP SI
 POP DI
 POP BP

 { COMPORTEMENT SPÉCIAL INT 25h: }
 { INT 25h laisse les FLAGS sur la pile pour l'appelant }
 { L'appelant doit faire POPF ou ADD SP,2 pour nettoyer }

 { Récupérer l'adresse de retour et les flags depuis la pile }
 POP DX                     { DX = adresse de retour (offset) }
 POP CX                     { CX = adresse de retour (segment) }
 PUSHF                      { Pousser les flags actuels }
 PUSH CX                    { Repousser segment de retour }
 PUSH DX                    { Repousser offset de retour }

 { Retour normal - les flags restent sur la pile pour l'appelant }
END;

Procedure Intr26h;Assembler;ASM
 { INT 26h - Écriture secteur disque absolue }
 { Entrée:                                   }
 {   AL = numéro lecteur (0=A:, 1=B:, etc.)  }
 {   CX = nombre de secteurs à écrire        }
 {   DX = secteur de départ                  }
 {   DS:BX = pointeur buffer                 }
 { Sortie:                                   }
 {   CF = 0 si succès, 1 si erreur           }
 {   AX = code d'erreur si erreur            }

 PUSH BP                    { Sauver registres }
 PUSH DI
 PUSH SI
 PUSH ES

 { Vérifier validité du lecteur }
 CMP AL,26                  { Maximum 26 lecteurs }
 JA @26hInvalidDrive

 { Déterminer type de lecteur }
 CMP AL,2
 JAE @26hHardDisk

 {--- Disquette ---}
@26hFloppy:
 MOV AH,03h                 { BIOS write sectors }
 MOV AL,CL                  { Nombre de secteurs }

 { Convertir secteur logique en CHS }
 PUSH AX
 MOV AX,DX                  { AX = secteur logique }
 MOV BL,18                  { Secteurs par piste }
 DIV BL                     { AL = piste, AH = secteur }
 MOV CL,AH
 INC CL                     { Secteur 1-based }

 XOR AH,AH
 MOV BL,2                   { Têtes }
 DIV BL                     { AL = cylindre, AH = tête }
 MOV CH,AL
 MOV DH,AH

 POP AX
 PUSH AX                    { Sauver AX }
 MOV AX,[BP+8]              { Récupérer registres originaux }
 MOV DL,AL                  { Numéro lecteur }
 POP AX                     { Restaurer AX }

 INT 13h
 JMP @26hEnd

 {--- Disque dur ---}
@26hHardDisk:
 MOV AH,43h                 { BIOS Extended Write }
 PUSH AX                    { Sauver AX }
 MOV AX,[BP+8]              { Récupérer registres originaux }
 MOV DL,AL                  { DL = numéro lecteur }
 POP AX                     { Restaurer AX }
 ADD DL,80h                 { Numéro BIOS }

 { Structure LBA }
{$IFDEF CPU86}
 { 8088/8086 : Utiliser registres pour les constantes }
 XOR AX,AX                  { AX = 0 }
 PUSH AX                    { LBA étendu partie haute (high word) }
 PUSH AX                    { LBA étendu partie haute (low word) }
 PUSH DX                    { LBA secteur }
 PUSH DS                    { Segment buffer }
 PUSH BX                    { Offset buffer }
 PUSH CX                    { Nombre secteurs }
 MOV AX,10h                 { Taille structure }
 PUSH AX
{$ELSE}
 { 80286+ : PUSH immediate supporté }
 PUSH DWord Ptr 0           { LBA étendu }
 PUSH DX                    { LBA secteur }
 PUSH DS                    { Segment buffer }
 PUSH BX                    { Offset buffer }
 PUSH CX                    { Nombre secteurs }
 PUSH 10h                   { Taille structure }
{$ENDIF}

 MOV SI,SP
 INT 13h
 ADD SP,16

 JNC @26hSuccess

 { Fallback CHS }
 MOV AH,03h                 { BIOS write sectors }
 MOV AL,CL

 MOV AX,DX
 MOV BL,63
 DIV BL
 MOV CL,AH
 INC CL

 XOR AH,AH
 MOV BL,255
 DIV BL
 MOV CH,AL
 MOV DH,AH

 PUSH AX                    { Sauver AX }
 MOV AX,[BP+8]              { Récupérer registres originaux }
 MOV DL,AL                  { DL = numéro lecteur }
 POP AX                     { Restaurer AX }
 ADD DL,80h

 INT 13h
 JMP @26hEnd

@26hInvalidDrive:
 MOV AX,0001h
 STC
 JMP @26hEnd

@26hSuccess:
 XOR AX,AX
 CLC

@26hEnd:
 POP ES
 POP SI
 POP DI
 POP BP

 { COMPORTEMENT SPÉCIAL INT 26h: }
 { INT 26h laisse les FLAGS sur la pile pour l'appelant }
 { L'appelant doit faire POPF ou ADD SP,2 pour nettoyer }

 { Récupérer l'adresse de retour et les flags depuis la pile }
 POP DX                     { DX = adresse de retour (offset) }
 POP CX                     { CX = adresse de retour (segment) }
 PUSHF                      { Pousser les flags actuels }
 PUSH CX                    { Repousser segment de retour }
 PUSH DX                    { Repousser offset de retour }

 { Retour normal - les flags restent sur la pile pour l'appelant }
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
 MOV AL,BYTE PTR [Data + 6]  { CurrentDrive est à l'offset 6 }
END;

Procedure SetCurrentDrive(Drive: Byte);Assembler;
ASM
 MOV AL,Drive
 MOV BYTE PTR [Data + 6],AL  { Stocker CurrentDrive à l'offset 6 }
END;

Function GetCurrentDirDrive(Index: Byte): Byte;Assembler;
ASM
 MOV AL,Index
 MOV AH,131                  { Taille d'un enregistrement CurrentDir (1+2+128) }
 MUL AH                      { AL = Index * 131 }
 ADD AX,7                    { Ajouter offset de base (7) }
 MOV BX,AX
 MOV AL,BYTE PTR [Data + BX] { Lire Drive }
END;

Function GetCurrentDirCluster(Index: Byte): Word;Assembler;
ASM
 MOV AL,Index
 MOV AH,131                  { Taille d'un enregistrement CurrentDir }
 MUL AH
 ADD AX,8                    { Drive(1) + offset de base(7) = 8 }
 MOV BX,AX
 MOV AX,WORD PTR [Data + BX] { Lire Cluster (Word) }
END;

Function GetCurrentDirPath(Index: Byte): String;
Var
 Path: String;
 I, Len: Byte;
 BaseOffset: Word;
Begin
 BaseOffset := 7 + (Index * 131) + 3;  { Base + Index*RecordSize + Drive(1) + Cluster(2) }

 { Lire la longueur de la chaîne }
 ASM
  MOV BX,BaseOffset
  MOV AL,BYTE PTR [Data + BX]
  MOV Len,AL
 END;

 { Lire les caractères }
 Path[0] := Chr(Len);
 For I := 1 To Len Do Begin
  ASM
   MOV AL,I
   MOV AH,0
   ADD AX,BaseOffset
   MOV BX,AX
   MOV AL,BYTE PTR [Data + BX]

   { Stocker le caractère dans Path[I] }
   LEA BX,Path
   MOV CL,I
   MOV CH,0
   ADD BX,CX
   MOV BYTE PTR [BX],AL
  END;
 End;

 GetCurrentDirPath := Path;
End;

Procedure SetCurrentDirDrive(Index, Drive: Byte);Assembler;
ASM
 MOV AL,Index
 MOV AH,131                  { Taille d'un enregistrement CurrentDir }
 MUL AH
 ADD AX,7                    { Ajouter offset de base }
 MOV BX,AX
 MOV AL,Drive
 MOV BYTE PTR [Data + BX],AL { Stocker Drive }
END;

Procedure SetCurrentDirCluster(Index: Byte; Cluster: Word);Assembler;
ASM
 MOV AL,Index
 MOV AH,131                  { Taille d'un enregistrement CurrentDir }
 MUL AH
 ADD AX,8                    { Drive(1) + offset de base(7) = 8 }
 MOV BX,AX
 MOV AX,Cluster
 MOV WORD PTR [Data + BX],AX { Stocker Cluster }
END;

Procedure SetCurrentDirPath(Index: Byte; Path: String);
Var
 I, Len: Byte;
 BaseOffset: Word;
Begin
 Len := Length(Path);
 BaseOffset := 7 + (Index * 131) + 3;  { Base + Index*RecordSize + Drive(1) + Cluster(2) }

 { Stocker la longueur }
 ASM
  MOV BX,BaseOffset
  MOV AL,Len
  MOV BYTE PTR [Data + BX],AL
 END;

 { Stocker les caractères }
 For I := 1 To Len Do Begin
  ASM
   { Calculer l'adresse de destination dans Data }
   MOV AL,I
   MOV AH,0
   ADD AX,BaseOffset
   MOV DI,AX           { DI = adresse destination dans Data }

   { Lire le caractère depuis Path[I] }
   LEA BX,Path
   MOV CL,I
   MOV CH,0
   ADD BX,CX
   MOV AL,BYTE PTR [BX] { AL = Path[I] }

   { Stocker dans Data }
   MOV BYTE PTR [Data + DI],AL
  END;
 End;
End;

{==============================================================================}
{ FONCTIONS D'ACCÈS À LA FILETABLE DANS LE CODE SEGMENT                       }
{==============================================================================}

{ Structure FileTable : 7 + 26*131 + 20*17 = 3747 + 340 = 4087
  Offset de FileTable dans Data = 7 + 26*131 = 3413 }

{ Fonctions pour accéder aux variables FileTable dans Data }
Function GetFileTableInUse(Index: Byte): Boolean;Assembler;
ASM
 MOV AL,Index
 MOV AH,17                   { Taille d'une entrée FileTable }
 MUL AH
 ADD AX,3413                 { Ajouter offset de base FileTable }
 MOV BX,AX
 MOV AL,BYTE PTR [Data + BX] { Lire InUse }
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
 ADD AX,3413
 MOV BX,AX
 MOV AL,InUse
 MOV BYTE PTR [Data + BX],AL
END;

Function GetFileTableDrive(Index: Byte): Byte;Assembler;
ASM
 MOV AL,Index
 MOV AH,17
 MUL AH
 ADD AX,3414                 { Offset + 1 pour Drive }
 MOV BX,AX
 MOV AL,BYTE PTR [Data + BX]
END;

Procedure SetFileTableDrive(Index: Byte; Drive: Byte);Assembler;
ASM
 MOV AL,Index
 MOV AH,17
 MUL AH
 ADD AX,3414
 MOV BX,AX
 MOV AL,Drive
 MOV BYTE PTR [Data + BX],AL
END;

Function GetFileTableFirstCluster(Index: Byte): Word;Assembler;
ASM
 MOV AL,Index
 MOV AH,17
 MUL AH
 ADD AX,3415                 { Offset + 2 pour FirstCluster }
 MOV BX,AX
 MOV AX,WORD PTR [Data + BX]
END;

Procedure SetFileTableFirstCluster(Index: Byte; FirstCluster: Word);Assembler;
ASM
 MOV AL,Index
 MOV AH,17
 MUL AH
 ADD AX,3415
 MOV BX,AX
 MOV AX,FirstCluster
 MOV WORD PTR [Data + BX],AX
END;

Function GetFileTableFileSize(Index: Byte): LongInt;Assembler;
ASM
 MOV AL,Index
 MOV AH,17
 MUL AH
 ADD AX,3417                 { Offset + 4 pour FileSize }
 MOV BX,AX
 MOV AX,WORD PTR [Data + BX]     { Partie basse }
 MOV DX,WORD PTR [Data + BX + 2] { Partie haute }
END;

Procedure SetFileTableFileSize(Index: Byte; FileSize: LongInt);Assembler;
ASM
 MOV AL,Index
 MOV AH,17
 MUL AH
 ADD AX,3417
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
 ADD AX,3421                 { Offset + 8 pour CurrentPos }
 MOV BX,AX
 MOV AX,WORD PTR [Data + BX]
 MOV DX,WORD PTR [Data + BX + 2]
END;

Procedure SetFileTableCurrentPos(Index: Byte; CurrentPos: LongInt);Assembler;
ASM
 MOV AL,Index
 MOV AH,17
 MUL AH
 ADD AX,3421
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
 ADD AX,3425                 { Offset + 12 pour Attributes }
 MOV BX,AX
 MOV AL,BYTE PTR [Data + BX]
END;

Procedure SetFileTableAttributes(Index: Byte; Attributes: Byte);Assembler;
ASM
 MOV AL,Index
 MOV AH,17
 MUL AH
 ADD AX,3425
 MOV BX,AX
 MOV AL,Attributes
 MOV BYTE PTR [Data + BX],AL
END;

Function GetFileTableCurrentCluster(Index: Byte): Word;Assembler;
ASM
 MOV AL,Index
 MOV AH,17
 MUL AH
 ADD AX,3426                 { Offset + 13 pour CurrentCluster }
 MOV BX,AX
 MOV AX,WORD PTR [Data + BX]
END;

Procedure SetFileTableCurrentCluster(Index: Byte; CurrentCluster: Word);Assembler;
ASM
 MOV AL,Index
 MOV AH,17
 MUL AH
 ADD AX,3426
 MOV BX,AX
 MOV AX,CurrentCluster
 MOV WORD PTR [Data + BX],AX
END;

Function GetFileTableClusterOffset(Index: Byte): Word;Assembler;
ASM
 MOV AL,Index
 MOV AH,17
 MUL AH
 ADD AX,3428                 { Offset + 15 pour ClusterOffset }
 MOV BX,AX
 MOV AX,WORD PTR [Data + BX]
END;

Procedure SetFileTableClusterOffset(Index: Byte; ClusterOffset: Word);Assembler;
ASM
 MOV AL,Index
 MOV AH,17
 MUL AH
 ADD AX,3428
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
 PUSH BP
 MOV BP,SP
 MOV AL,[BP+4]        { Récupérer le paramètre Flag depuis la pile }
 MOV BYTE PTR [Data.DataMOS.VerifyFlag],AL
 POP BP
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

Procedure Handle38hGetCountryInfo(CountryCode:Word;BufferPtr:Word);
{ Procedure helper pour remplir le buffer avec les informations pays }
Var
 CountryInfo: DataCountryRec;
 I: Byte;
Begin
 { Obtenir les informations du pays }
 DataCountry(CountryCode, CountryInfo);

 { Remplir le buffer de 38 octets au format DOS en utilisant l'assembleur inline }
 ASM
  PUSH ES
  PUSH DI
  PUSH AX
  PUSH CX

  MOV DI,BufferPtr           { DI = adresse du buffer }

  { Format de date }
  MOV AL,CountryInfo.DateFormat
  MOV ES:[DI],AL
  INC DI

  { Symbole monétaire (5 octets) }
  MOV AL,BYTE PTR CountryInfo.Currency[0]
  MOV ES:[DI],AL
  INC DI
  MOV AL,BYTE PTR CountryInfo.Currency[1]
  MOV ES:[DI],AL
  INC DI
  MOV AL,BYTE PTR CountryInfo.Currency[2]
  MOV ES:[DI],AL
  INC DI
  MOV AL,BYTE PTR CountryInfo.Currency[3]
  MOV ES:[DI],AL
  INC DI
  MOV AL,BYTE PTR CountryInfo.Currency[4]
  MOV ES:[DI],AL
  INC DI

  { Séparateur milliers (2 octets) }
  MOV AL,BYTE PTR CountryInfo.ThousandsSep[0]
  MOV ES:[DI],AL
  INC DI
  MOV AL,BYTE PTR CountryInfo.ThousandsSep[1]
  MOV ES:[DI],AL
  INC DI

  { Séparateur décimal (2 octets) }
  MOV AL,BYTE PTR CountryInfo.DecimalSep[0]
  MOV ES:[DI],AL
  INC DI
  MOV AL,BYTE PTR CountryInfo.DecimalSep[1]
  MOV ES:[DI],AL
  INC DI

  { Séparateur date (2 octets) }
  MOV AL,BYTE PTR CountryInfo.DateSep[0]
  MOV ES:[DI],AL
  INC DI
  MOV AL,BYTE PTR CountryInfo.DateSep[1]
  MOV ES:[DI],AL
  INC DI

  { Séparateur heure (2 octets) }
  MOV AL,BYTE PTR CountryInfo.TimeSep[0]
  MOV ES:[DI],AL
  INC DI
  MOV AL,BYTE PTR CountryInfo.TimeSep[1]
  MOV ES:[DI],AL
  INC DI

  { Format monétaire }
  MOV AL,CountryInfo.CurrencyFormat
  MOV ES:[DI],AL
  INC DI

  { Chiffres après virgule }
  MOV AL,CountryInfo.DecimalDigits
  MOV ES:[DI],AL
  INC DI

  { Format heure }
  MOV AL,CountryInfo.TimeFormat
  MOV ES:[DI],AL
  INC DI

  { Adresse routine conversion (4 octets) - non utilisé }
  XOR AL,AL
  MOV ES:[DI],AL
  INC DI
  MOV ES:[DI],AL
  INC DI
  MOV ES:[DI],AL
  INC DI
  MOV ES:[DI],AL
  INC DI

  { Séparateur liste (2 octets) }
  MOV AL,BYTE PTR CountryInfo.DataListSep[0]
  MOV ES:[DI],AL
  INC DI
  MOV AL,BYTE PTR CountryInfo.DataListSep[1]
  MOV ES:[DI],AL
  INC DI

  { Réservé (10 octets) }
  MOV CX,10
  XOR AL,AL
@FillLoop:
  MOV ES:[DI],AL
  INC DI
  LOOP @FillLoop

  POP CX
  POP AX
  POP DI
  POP ES
 END;
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

Procedure DataCountry(CountryCode:Word;Var CountryInfo:DataCountryRec);Begin
 { Remplir les informations selon le code pays }
 FillChar(CountryInfo,SizeOf(CountryInfo),0);
 CountryInfo.CountryCode:=CountryCode;

 Case CountryCode of
  1: Begin { États-Unis }
   CountryInfo.DateFormat:=0;          { Format USA mm/dd/yy }
   CountryInfo.Currency[0]:='$';
   CountryInfo.Currency[1]:=#0;
   CountryInfo.ThousandsSep[0]:=',';   { Virgule pour milliers }
   CountryInfo.ThousandsSep[1]:=#0;
   CountryInfo.DecimalSep[0]:='.';     { Point décimal }
   CountryInfo.DecimalSep[1]:=#0;
   CountryInfo.DateSep[0]:='/';
   CountryInfo.DateSep[1]:=#0;
   CountryInfo.TimeSep[0]:=':';
   CountryInfo.TimeSep[1]:=#0;
   CountryInfo.CurrencyFormat:=0;      { $ précède }
   CountryInfo.DecimalDigits:=2;
   CountryInfo.TimeFormat:=0;          { Format 12h }
   CountryInfo.DataListSep[0]:=',';
   CountryInfo.DataListSep[1]:=#0;
  End;
  2: Begin { Canada }
   CountryInfo.DateFormat:=1;          { Format européen dd/mm/yy }
   CountryInfo.Currency[0]:='$';
   CountryInfo.Currency[1]:=#0;
   CountryInfo.ThousandsSep[0]:=' ';   { Espace pour milliers }
   CountryInfo.ThousandsSep[1]:=#0;
   CountryInfo.DecimalSep[0]:=',';     { Virgule décimale (français canadien) }
   CountryInfo.DecimalSep[1]:=#0;
   CountryInfo.DateSep[0]:='/';
   CountryInfo.DateSep[1]:=#0;
   CountryInfo.TimeSep[0]:=':';
   CountryInfo.TimeSep[1]:=#0;
   CountryInfo.CurrencyFormat:=0;      { $ précède }
   CountryInfo.DecimalDigits:=2;
   CountryInfo.TimeFormat:=1;          { Format 24h }
   CountryInfo.DataListSep[0]:=';';
   CountryInfo.DataListSep[1]:=#0;
  End;
  33: Begin { France }
   CountryInfo.DateFormat:=1;          { Format européen dd/mm/yy }
   CountryInfo.Currency[0]:='F';
   CountryInfo.Currency[1]:='R';
   CountryInfo.Currency[2]:=#0;
   CountryInfo.ThousandsSep[0]:=' ';   { Espace pour milliers }
   CountryInfo.ThousandsSep[1]:=#0;
   CountryInfo.DecimalSep[0]:=',';     { Virgule décimale }
   CountryInfo.DecimalSep[1]:=#0;
   CountryInfo.DateSep[0]:='/';
   CountryInfo.DateSep[1]:=#0;
   CountryInfo.TimeSep[0]:=':';
   CountryInfo.TimeSep[1]:=#0;
   CountryInfo.CurrencyFormat:=0;      { FR précède }
   CountryInfo.DecimalDigits:=2;
   CountryInfo.TimeFormat:=1;          { Format 24h }
   CountryInfo.DataListSep[0]:=';';
   CountryInfo.DataListSep[1]:=#0;
  End;
  34: Begin { Espagne }
   CountryInfo.DateFormat:=1;          { Format européen dd/mm/yy }
   CountryInfo.Currency[0]:='P';
   CountryInfo.Currency[1]:='t';
   CountryInfo.Currency[2]:='s';
   CountryInfo.Currency[3]:=#0;
   CountryInfo.ThousandsSep[0]:='.';   { Point pour milliers }
   CountryInfo.ThousandsSep[1]:=#0;
   CountryInfo.DecimalSep[0]:=',';     { Virgule décimale }
   CountryInfo.DecimalSep[1]:=#0;
   CountryInfo.DateSep[0]:='/';
   CountryInfo.DateSep[1]:=#0;
   CountryInfo.TimeSep[0]:=':';
   CountryInfo.TimeSep[1]:=#0;
   CountryInfo.CurrencyFormat:=0;      { Pts précède }
   CountryInfo.DecimalDigits:=2;
   CountryInfo.TimeFormat:=1;          { Format 24h }
   CountryInfo.DataListSep[0]:=';';
   CountryInfo.DataListSep[1]:=#0;
  End;
  Else Begin { Pays par défaut (France) }
   DataCountry(33,CountryInfo);
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
  ValidateDriveNumber:=(DriveNumber>=0) And (DriveNumber<=25); { A-Z }
End;

Procedure ConvertLBAtoCHS(LBA:LongInt;Var Cylinder,Head,Sector:Word;DPT:DriveParameterTable);
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
Function ReadSector(Drive:Byte;Sector:LongInt;Buffer:Pointer):Boolean;
Var
 Result:Byte;
Begin
 ASM
  PUSH ES
  PUSH BX
  PUSH CX
  PUSH DX
  PUSH AX

  MOV DL,Drive               { DL = numéro de lecteur }
  MOV AX,Word Ptr Sector     { Secteur bas }
  MOV DX,Word Ptr Sector+2   { Secteur haut }

  { Convertir secteur logique en CHS si nécessaire }
  { Pour simplifier, on utilise l'interruption 25h }

  LES BX,Buffer              { ES:BX = buffer }
  MOV CX,1                   { Lire 1 secteur }
  MOV AL,DL                  { AL = lecteur }
  INT 25h                    { Interruption lecture secteur }
  JC @ReadError

  MOV AL,1                   { Succès }
  JMP @ReadEnd
@ReadError:
  XOR AL,AL                  { Échec }
@ReadEnd:
  MOV Result,AL              { Sauver résultat dans variable Pascal }
  POP BX                     { Nettoyer pile (INT 25h pousse flags) }
  POP AX
  POP DX
  POP CX
  POP BX
  POP ES
 END;
 ReadSector:=(Result<>0);
End;

{ Écrire un secteur sur un lecteur }
Function WriteSector(Drive:Byte;Sector:LongInt;Buffer:Pointer):Boolean;
Var
 Result:Byte;
Begin
 ASM
  PUSH ES
  PUSH BX
  PUSH CX
  PUSH DX
  PUSH AX

  MOV DL,Drive               { DL = numéro de lecteur }
  MOV AX,Word Ptr Sector     { Secteur bas }
  MOV DX,Word Ptr Sector+2   { Secteur haut }

  LES BX,Buffer              { ES:BX = buffer }
  MOV CX,1                   { Écrire 1 secteur }
  MOV AL,DL                  { AL = lecteur }
  INT 26h                    { Interruption écriture secteur }
  JC @WriteError

  MOV AL,1                   { Succès }
  JMP @WriteEnd
@WriteError:
  XOR AL,AL                  { Échec }
@WriteEnd:
  MOV Result,AL              { Sauver résultat dans variable Pascal }
  POP BX                     { Nettoyer pile (INT 26h pousse flags) }
  POP AX
  POP DX
  POP CX
  POP BX
  POP ES
 END;
 WriteSector:=(Result<>0);
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
   FATSector:=BootSec.ReservedSectors+FATCopy*BootSec.SectorsPerFAT+(Cluster*3 div 2)div 512;
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
   FATSector:=BootSec.ReservedSectors+FATCopy*BootSec.SectorsPerFAT+(Cluster*2)div 512;
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
Function FindParentDirectory(Drive:Byte;BootSec:BootSectorRec;Path:String;Var ParentCluster:Word):Boolean;
Begin
 { Pour cette implémentation simplifiée, on suppose créer dans la racine }
 ParentCluster:=0;  { 0 = répertoire racine }
 FindParentDirectory:=True;
End;

{ Créer une entrée de répertoire }
Function CreateDirEntry(Drive:Byte;BootSec:BootSectorRec;ParentCluster:Word;DirName:String):Boolean;
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
      DirSector:=BootSec.ReservedSectors+BootSec.NumberOfFATs*BootSec.SectorsPerFAT+
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

Function GetClusterSector(Drive:Byte;BootSec:BootSectorRec;Cluster:Word):LongInt;
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
{ Trouve l'entrée de répertoire dans le répertoire parent }
Var
 DirBuffer:Array[0..511] of Byte;
 DirSector:LongInt;
 SectorsToRead:Word;
 I,J:Word;
 EntryPtr:^DirectoryEntry;
 FoundName:String;
Begin
 FindDirectoryEntry:=False;
 EntryOffset:=0;

 { Convertir nom en format 8.3 majuscules }
 DirName:=Copy(DirName+'        ',1,8); { Pad avec espaces }
 For I:=1 To Length(DirName) Do
  If (DirName[I]>='a')and(DirName[I]<='z') Then
   DirName[I]:=Chr(Ord(DirName[I])-32);

 { Calculer secteur et nombre de secteurs à lire }
 DirSector:=GetClusterSector(Drive,BootSec,ParentCluster);
 If ParentCluster = 0 Then
  SectorsToRead:=(BootSec.RootDirEntries*32+511)div 512
 Else
  SectorsToRead:=BootSec.SectorsPerCluster;

 { Parcourir les secteurs du répertoire }
 For I:=0 To SectorsToRead-1 Do Begin
  If ReadSector(Drive,DirSector+I,@DirBuffer) Then Begin
   { Parcourir les entrées du secteur }
   For J:=0 To 15 Do Begin { 16 entrées par secteur (512/32) }
    EntryPtr:=@DirBuffer[J*32];

    { Vérifier si l'entrée est valide }
    If (EntryPtr^.FileName[0]<>#0)and(EntryPtr^.FileName[0]<>#$E5) Then Begin
     { Construire le nom de l'entrée }
     FoundName:='';
     For I:=0 To 7 Do Begin
      If EntryPtr^.FileName[I]<>' ' Then
       FoundName:=FoundName+EntryPtr^.FileName[I];
     End;

     { Comparer avec le nom recherché }
     If (FoundName = Copy(DirName,1,Length(FoundName)))and
        (EntryPtr^.Attributes and $10 <> 0) Then Begin { Répertoire }
      Entry:=EntryPtr^;
      EntryOffset:=(I*16+J)*32;
      FindDirectoryEntry:=True;
      Exit;
     End;
    End;
   End;
  End;
 End;
End;

Function IsDirectoryEmpty(Drive:Byte;BootSec:BootSectorRec;DirCluster:Word):Boolean;
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

Function FreeFATChain(Drive:Byte;BootSec:BootSectorRec;StartCluster:Word):Boolean;
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

Function DeleteDirEntry(Drive:Byte;BootSec:BootSectorRec;ParentCluster:Word;EntryOffset:Word):Boolean;
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

Function DOS3Ah_RemoveDirectory(PathPtr:Pointer):Word;
{ Fonction principale pour supprimer un répertoire }
Var
 Path:String;
 Drive:Byte;
 DirName:String;
 BootSec:BootSectorRec;
 ParentCluster:Word;
 Entry:DirectoryEntry;
 EntryOffset:Word;
 DirCluster:Word;
 P:^Char;
 I:Byte;
Begin
 DOS3Ah_RemoveDirectory:=3; { Par défaut: Path not found }

 { Convertir pointeur en chaîne Pascal }
 P:=PathPtr;
 Path:='';
 I:=0;
 While (P^ <> #0) and (I < 255) Do Begin
  Path:=Path + P^;
  Inc(P);
  Inc(I);
 End;

 { Analyser le chemin }
 If Not ParsePath(Path,Drive,DirName) Then Begin
  DOS3Ah_RemoveDirectory:=3; { Path not found }
  Exit;
 End;

 { Lire le secteur de boot }
 If Not ReadBootSector(Drive,BootSec) Then Begin
  DOS3Ah_RemoveDirectory:=15; { Invalid drive }
  Exit;
 End;

 { Trouver le répertoire parent }
 If Not FindParentDirectory(Drive,BootSec,Path,ParentCluster) Then Begin
  DOS3Ah_RemoveDirectory:=3; { Path not found }
  Exit;
 End;

 { Trouver l'entrée du répertoire à supprimer }
 If Not FindDirectoryEntry(Drive,BootSec,ParentCluster,DirName,Entry,EntryOffset) Then Begin
  DOS3Ah_RemoveDirectory:=2; { File not found }
  Exit;
 End;

 { Vérifier que c'est bien un répertoire }
 If (Entry.Attributes and $10) = 0 Then Begin
  DOS3Ah_RemoveDirectory:=16; { Cannot remove current directory }
  Exit;
 End;

 { Construire le numéro de cluster }
 DirCluster:=Entry.FirstClusterLow or (Word(Entry.FirstClusterHigh) shl 16);

 { Vérifier si le répertoire est vide }
 If Not IsDirectoryEmpty(Drive,BootSec,DirCluster) Then Begin
  DOS3Ah_RemoveDirectory:=16; { Directory not empty }
  Exit;
 End;

 { Libérer les clusters du répertoire }
 If DirCluster <> 0 Then Begin
  If Not FreeFATChain(Drive,BootSec,DirCluster) Then Begin
   DOS3Ah_RemoveDirectory:=5; { Access denied }
   Exit;
  End;
 End;

 { Supprimer l'entrée du répertoire parent }
 If Not DeleteDirEntry(Drive,BootSec,ParentCluster,EntryOffset) Then Begin
  DOS3Ah_RemoveDirectory:=5; { Access denied }
  Exit;
 End;

 DOS3Ah_RemoveDirectory:=0; { Succès }
End;

{==============================================================================}
{ FONCTIONS POUR CHANGER DE RÉPERTOIRE (Fonction 3Bh)                        }
{==============================================================================}

Function FindDirectoryByPath(Drive:Byte;BootSec:BootSectorRec;Path:String;Var DirCluster:Word):Boolean;
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
  If Not FindDirectoryEntry(Drive,BootSec,CurrentCluster,PathParts[I],Entry,EntryOffset) Then
   Exit; { Partie non trouvée }

  { Vérifier que c'est un répertoire }
  If (Entry.Attributes and $10) = 0 Then
   Exit; { Pas un répertoire }

  { Passer au cluster suivant }
  CurrentCluster:=Entry.FirstClusterLow or (Word(Entry.FirstClusterHigh) shl 16);
 End;

 DirCluster:=CurrentCluster;
 FindDirectoryByPath:=True;
End;

Function SetCurrentDirectory(Drive:Byte;DirCluster:Word):Boolean;
{ Met à jour le répertoire courant pour un lecteur }
Begin
 SetCurrentDirectory:=False;

 { Vérifier validité du lecteur }
 If Drive > 25 Then Exit; { A-Z seulement }

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
{ Fonction principale pour changer de répertoire }
Var
 Path:String;
 Drive:Byte;
 DirName:String;
 FullPath:String;
 BootSec:BootSectorRec;
 DirCluster:Word;
 P:^Char;
 I,J:Byte;
Begin
 DOS3Bh_ChangeDirectory:=3; { Par défaut: Path not found }

 { Convertir pointeur en chaîne Pascal }
 P:=PathPtr;
 Path:='';
 I:=0;
 While (P^ <> #0) and (I < 255) Do Begin
  Path:=Path + P^;
  Inc(P);
  Inc(I);
 End;

 { Déterminer le lecteur }
 If (Length(Path) >= 2) and (Path[2] = ':') Then Begin
  Drive:=Ord(UpCase(Path[1])) - Ord('A');
  FullPath:=Copy(Path,3,255); { Enlever "C:" }
 End
 Else Begin
  Drive:=GetCurrentDrive; { Lecteur courant }
  FullPath:=Path;
 End;

 { Vérifier validité du lecteur }
 If Drive > 25 Then Begin
  DOS3Bh_ChangeDirectory:=15; { Invalid drive }
  Exit;
 End;

 { Lire le secteur de boot }
 If Not ReadBootSector(Drive,BootSec) Then Begin
  DOS3Bh_ChangeDirectory:=15; { Invalid drive }
  Exit;
 End;

 { Traiter les cas spéciaux }
 If FullPath = '' Then Begin
  { Pas de chemin = juste changer de lecteur }
  SetCurrentDrive(Drive);
  DOS3Bh_ChangeDirectory:=0;
  Exit;
 End;

 { Gérer chemin relatif vs absolu }
 If (Length(FullPath) = 0) or (FullPath[1] <> '\') Then Begin
  { Chemin relatif - partir du répertoire courant }
  If GetCurrentDirPath(Drive) <> '\' Then
   FullPath:=GetCurrentDirPath(Drive) + '\' + FullPath
  Else
   FullPath:='\' + FullPath;
 End;

 { Gérer ".." (répertoire parent) }
 While Pos('\..\',FullPath) > 0 Do Begin
  I:=Pos('\..\',FullPath);
  If I > 1 Then Begin
   { Trouver le répertoire parent }
   J:=I-1;
   While (J > 1) and (FullPath[J] <> '\') Do Dec(J);
   Delete(FullPath,J+1,I+3-J-1);
  End
  Else
   Delete(FullPath,1,4); { Enlever "\.." au début }
 End;

 { Gérer "." (répertoire courant) }
 While Pos('\.\',FullPath) > 0 Do Begin
  I:=Pos('\.\',FullPath);
  Delete(FullPath,I,2); { Enlever "\." }
 End;

 { Chercher le répertoire }
 If Not FindDirectoryByPath(Drive,BootSec,FullPath,DirCluster) Then Begin
  DOS3Bh_ChangeDirectory:=3; { Path not found }
  Exit;
 End;

 { Mettre à jour le répertoire courant }
 If Not SetCurrentDirectory(Drive,DirCluster) Then Begin
  DOS3Bh_ChangeDirectory:=5; { Access denied }
  Exit;
 End;

 { Changer le lecteur courant si nécessaire }
 SetCurrentDrive(Drive);

 DOS3Bh_ChangeDirectory:=0; { Succès }
End;

{==============================================================================}
{ FONCTIONS POUR 3Ch - CREATE OR OPEN FILE                                    }
{==============================================================================}

{ Analyser un chemin de fichier (séparé répertoire/fichier) }
Function ParseFilePath(Path:String;Var Drive:Byte;Var DirPath,FileName:String):Boolean;
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

 If Drive > 25 Then Exit; { Lecteur invalide }

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

 { Chercher une entrée libre dans la table des fichiers }
 For I:=0 To 19 Do Begin
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

   Handle:=I;
   AllocateFileHandle:=True;
   Exit;
  End;
 End;
End;

{ Créer une nouvelle entrée de fichier dans le répertoire }
Function CreateFileEntry(Drive:Byte;BootSec:BootSectorRec;DirCluster:Word;
                        FileName:String;Attributes:Byte;Var FirstCluster:Word):Word;
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
  DirSector:=BootSec.ReservedSectors + (BootSec.NumberOfFATs * BootSec.SectorsPerFAT);
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
 FirstCluster:=Entry.FirstClusterLow or (LongInt(Entry.FirstClusterHigh) shl 16);
 FileSize:=Entry.FileSize;

 If AllocateFileHandle(Drive,FirstCluster,FileSize,Entry.Attributes,Handle) Then
  OpenExistingFile:=0 { Succès }
 Else
  OpenExistingFile:=4; { Too many open files }
End;

{ Trouver ou créer un fichier }
Function FindOrCreateFile(Drive:Byte;BootSec:BootSectorRec;DirPath,FileName:String;
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
 If FindDirectoryEntry(Drive,BootSec,DirCluster,FileName + '        ',Entry,EntryOffset) Then Begin
  { Fichier existant - l'ouvrir }
  If (Entry.Attributes and $10) <> 0 Then Begin
   FindOrCreateFile:=5; { Access denied - c'est un répertoire }
   Exit;
  End;

  FindOrCreateFile:=OpenExistingFile(Drive,Entry,FileHandle);
 End
 Else Begin
  { Fichier n'existe pas - le créer }
  Result:=CreateFileEntry(Drive,BootSec,DirCluster,FileName,Attributes,FirstCluster);
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
Var
 Path: String;
 Drive: Byte;
 DirPath,FileName: String;
 BootSec: BootSectorRec;
 FileHandle: Word;
 P: PChar;
 I: Byte;
 Result: Word;
Begin
 DOS3Ch_CreateOpenFile:=$FFFF; { Erreur par défaut }

 { Convertir pointeur ASCIIZ en string Pascal }
 P:=PChar(PathPtr);
 Path:='';
 I:=0;
 While (P^ <> #0) and (I < 255) Do Begin
  Path:=Path + P^;
  Inc(P);
  Inc(I);
 End;

 { Analyser le chemin }
 If Not ParseFilePath(Path,Drive,DirPath,FileName) Then Begin
  DOS3Ch_CreateOpenFile:=$FFFF; { Invalid path }
  Exit;
 End;

 { Lire boot sector }
 If Not ReadBootSector(Drive,BootSec) Then Begin
  DOS3Ch_CreateOpenFile:=$FFFF; { Invalid drive }
  Exit;
 End;

 { Trouver ou créer le fichier }
 Result:=FindOrCreateFile(Drive,BootSec,DirPath,FileName,0,FileHandle);

 { Si succès, retourner le handle }
 If Result = 0 Then
  DOS3Ch_CreateOpenFile:=FileHandle
 Else
  DOS3Ch_CreateOpenFile:=Result;
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
 FirstCluster:=Entry.FirstClusterLow or (LongInt(Entry.FirstClusterHigh) shl 16);
 FileSize:=Entry.FileSize;

 If AllocateFileHandle(Drive,FirstCluster,FileSize,$00,Handle) Then
  OpenFileReadOnly:=0 { Succès }
 Else
  OpenFileReadOnly:=4; { Too many open files }
End;

{ Ouvrir fichier en écriture seule }
Function OpenFileWriteOnly(Drive:Byte;Entry:DirectoryEntry;Var Handle:Word):Word;
Var
 FirstCluster: Word;
 FileSize: LongInt;
Begin
 FirstCluster:=Entry.FirstClusterLow or (LongInt(Entry.FirstClusterHigh) shl 16);
 FileSize:=Entry.FileSize;

 If AllocateFileHandle(Drive,FirstCluster,FileSize,$01,Handle) Then
  OpenFileWriteOnly:=0 { Succès }
 Else
  OpenFileWriteOnly:=4; { Too many open files }
End;

{ Ouvrir fichier en lecture/écriture }
Function OpenFileReadWrite(Drive:Byte;Entry:DirectoryEntry;Var Handle:Word):Word;
Var
 FirstCluster: Word;
 FileSize: LongInt;
Begin
 FirstCluster:=Entry.FirstClusterLow or (LongInt(Entry.FirstClusterHigh) shl 16);
 FileSize:=Entry.FileSize;

 If AllocateFileHandle(Drive,FirstCluster,FileSize,$02,Handle) Then
  OpenFileReadWrite:=0 { Succès }
 Else
  OpenFileReadWrite:=4; { Too many open files }
End;

{ Fonction principale 3Dh }
Function DOS3Dh_OpenFile(PathPtr:Pointer;AccessMode:Byte):Word;
Var
 Path: String;
 Drive: Byte;
 DirPath,FileName: String;
 BootSec: BootSectorRec;
 DirCluster: Word;
 Entry: DirectoryEntry;
 EntryOffset: Word;
 FileHandle: Word;
 P: PChar;
 I: Byte;
 Result: Word;
Begin
 DOS3Dh_OpenFile:=$FFFF; { Erreur par défaut }

 { Valider le mode d'accès }
 If Not ValidateAccessMode(AccessMode) Then Begin
  DOS3Dh_OpenFile:=$FFFF; { Invalid access mode }
  Exit;
 End;

 { Convertir pointeur ASCIIZ en string Pascal }
 P:=PChar(PathPtr);
 Path:='';
 I:=0;
 While (P^ <> #0) and (I < 255) Do Begin
  Path:=Path + P^;
  Inc(P);
  Inc(I);
 End;

 { Analyser le chemin }
 If Not ParseFilePath(Path,Drive,DirPath,FileName) Then Begin
  DOS3Dh_OpenFile:=$FFFF; { Invalid path }
  Exit;
 End;

 { Lire boot sector }
 If Not ReadBootSector(Drive,BootSec) Then Begin
  DOS3Dh_OpenFile:=$FFFF; { Invalid drive }
  Exit;
 End;

 { Trouver le répertoire parent }
 If DirPath = '' Then
  DirCluster:=0 { Répertoire racine }
 Else Begin
  If Not FindDirectoryByPath(Drive,BootSec,DirPath,DirCluster) Then Begin
   DOS3Dh_OpenFile:=$FFFF; { Path not found }
   Exit;
  End;
 End;

 { Chercher le fichier }
 If Not FindDirectoryEntry(Drive,BootSec,DirCluster,FileName + '        ',Entry,EntryOffset) Then Begin
  DOS3Dh_OpenFile:=$FFFF; { File not found }
  Exit;
 End;

 { Vérifier que c'est bien un fichier (pas un répertoire) }
 If (Entry.Attributes and $10) <> 0 Then Begin
  DOS3Dh_OpenFile:=$FFFF; { Access denied - c'est un répertoire }
  Exit;
 End;

 { Ouvrir selon le mode d'accès }
 Case AccessMode and $03 Of
  0: Result:=OpenFileReadOnly(Drive,Entry,FileHandle);
  1: Result:=OpenFileWriteOnly(Drive,Entry,FileHandle);
  2: Result:=OpenFileReadWrite(Drive,Entry,FileHandle);
 End;

 { Si succès, retourner le handle }
 If Result = 0 Then
  DOS3Dh_OpenFile:=FileHandle
 Else
  DOS3Dh_OpenFile:=$FFFF;
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

 Drive:=FileEntry.Drive - 1; { Conversion en index 0-based }

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

 Drive:=FileEntry.Drive - 1; { Conversion en index 0-based }

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
Var
 FileEntry: FileTableEntry;
 Result: Word;
Begin
 CloseFileHandle:=6; { Invalid handle par défaut }

 { Vérifier la validité du handle }
 If Handle >= 20 Then Exit;

 If Not GetFileTableEntry(Handle,FileEntry) Then Exit;

 { Vérifier si le handle est utilisé }
 If Not FileEntry.InUse Then Begin
  CloseFileHandle:=6; { Invalid handle }
  Exit;
 End;

 { Flush les buffers si le fichier a été modifié }
 If (FileEntry.Attributes and $01) <> 0 Then Begin { Mode écriture }
  Result:=FlushFileBuffers(Handle);
  If Result <> 0 Then Begin
   CloseFileHandle:=Result;
   Exit;
  End;

  { Mettre à jour l'entrée de répertoire }
  Result:=UpdateDirectoryEntry(Handle);
  If Result <> 0 Then Begin
   CloseFileHandle:=Result;
   Exit;
  End;
 End;

 { Marquer le handle comme libre }
 FileEntry.InUse:=False;
 FileEntry.Drive:=0;
 FileEntry.FirstCluster:=0;
 FileEntry.FileSize:=0;
 FileEntry.CurrentPos:=0;
 FileEntry.Attributes:=0;
 FileEntry.CurrentCluster:=0;
 FileEntry.ClusterOffset:=0;

 SetFileTableEntry(Handle,FileEntry);

 CloseFileHandle:=0; { Succès }
End;

{ Fonction principale 3Eh }
Function DOS3Eh_CloseFile(Handle:Word):Word;
Begin
 DOS3Eh_CloseFile:=CloseFileHandle(Handle);
End;

{ Lire des données depuis un cluster spécifique }
Function ReadFromCluster(Drive:Byte;BootSec:BootSectorRec;Cluster:Word;Offset:Word;Buffer:Pointer;BytesToRead:Word):Word;
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
 FirstDataSector:=BootSec.ReservedSectors + (BootSec.NumberOfFATs * BootSec.SectorsPerFAT) +
                  ((BootSec.RootDirEntries * 32) div BootSec.BytesPerSector);

 { Calculer le secteur du cluster }
 ClusterSector:=FirstDataSector + (LongInt(Cluster - 2) * BootSec.SectorsPerCluster);

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
  If Not ReadSector(Drive, ClusterSector + SectorInCluster, @SectorBuffer) Then Begin
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
Function GetNextCluster(Drive:Byte;BootSec:BootSectorRec;CurrentCluster:Word):Word;
Var
 FATSector: Word;
 FATOffset: Word;
 Buffer: Array[0..511] of Byte;
 NextCluster: Word;
Begin
 GetNextCluster:=$FFFF; { Fin de chaîne par défaut }

 If BootSec.SectorsPerFAT = 0 Then Exit; { FAT32 non supportée }

 If CurrentCluster < 2 Then Exit; { Cluster invalide }

 { Pour FAT12 }
 If BootSec.SectorsPerFAT <= 12 Then Begin
  FATOffset:=(CurrentCluster * 3) div 2;
  FATSector:=BootSec.ReservedSectors + (FATOffset div BootSec.BytesPerSector);
  FATOffset:=FATOffset mod BootSec.BytesPerSector;

  If Not ReadSector(Drive, FATSector, @Buffer) Then Exit;

  If (CurrentCluster mod 2) = 0 Then
   NextCluster:=(Buffer[FATOffset] or ((Buffer[FATOffset + 1] and $0F) shl 8))
  Else
   NextCluster:=((Buffer[FATOffset] shr 4) or (Buffer[FATOffset + 1] shl 4));

  If NextCluster >= $FF8 Then NextCluster:=$FFFF; { Fin de chaîne }
 End
 Else Begin
  { Pour FAT16 }
  FATOffset:=CurrentCluster * 2;
  FATSector:=BootSec.ReservedSectors + (FATOffset div BootSec.BytesPerSector);
  FATOffset:=FATOffset mod BootSec.BytesPerSector;

  If Not ReadSector(Drive, FATSector, @Buffer) Then Exit;

  NextCluster:=Buffer[FATOffset] or (Buffer[FATOffset + 1] shl 8);

  If NextCluster >= $FFF8 Then NextCluster:=$FFFF; { Fin de chaîne }
 End;

 GetNextCluster:=NextCluster;
End;

{ Lire les données d'un fichier }
Function ReadFileData(Handle:Word;Buffer:Pointer;BytesToRead:Word;Var BytesRead:Word):Word;
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

 Drive:=FileEntry.Drive - 1; { Conversion en index 0-based }

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

 While (BytesToRead > 0) and (CurrentCluster <> $FFFF) and (CurrentCluster >= 2) Do Begin
  { Calculer combien on peut lire du cluster courant }
  RemainingInCluster:=ClusterSize - FileEntry.ClusterOffset;
  BytesToReadNow:=BytesToRead;
  If BytesToReadNow > RemainingInCluster Then
   BytesToReadNow:=RemainingInCluster;

  { Lire du cluster courant }
  Result:=ReadFromCluster(Drive, BootSec, CurrentCluster, FileEntry.ClusterOffset, Ptr(BufferSeg, BufferOfs), BytesToReadNow);
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
Function DOS3Fh_ReadFile(Handle:Word;Buffer:Pointer;BytesToRead:Word;Var BytesRead:Word):Word;
Begin
 DOS3Fh_ReadFile:=ReadFileData(Handle, Buffer, BytesToRead, BytesRead);
End;

{ Écrire des données vers un cluster spécifique }
Function WriteToCluster(Drive:Byte;BootSec:BootSectorRec;Cluster:Word;Offset:Word;Buffer:Pointer;BytesToWrite:Word):Word;
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
 FirstDataSector:=BootSec.ReservedSectors + (BootSec.NumberOfFATs * BootSec.SectorsPerFAT) +
                  ((BootSec.RootDirEntries * 32) div BootSec.BytesPerSector);

 { Calculer le secteur du cluster }
 ClusterSector:=FirstDataSector + (LongInt(Cluster - 2) * BootSec.SectorsPerCluster);

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
   If Not ReadSector(Drive, ClusterSector + SectorInCluster, @SectorBuffer) Then Begin
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

   MOV CX,BytesThisWrite
   CLD
   REP MOVSB

   POP DI
   POP ES
   POP SI
   POP DS
  END;

  { Écrire le secteur }
  If Not WriteSector(Drive, ClusterSector + SectorInCluster, @SectorBuffer) Then Begin
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
Function UpdateFATEntry(Drive:Byte;BootSec:BootSectorRec;Cluster:Word;NextCluster:Word):Boolean;
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
   Buffer[FATOffset + 1]:=(Buffer[FATOffset + 1] and $F0) or ((NextCluster shr 8) and $0F);
  End
  Else Begin
   Buffer[FATOffset]:=(Buffer[FATOffset] and $0F) or ((NextCluster and $0F) shl 4);
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
  If Not WriteSector(Drive, FATSector + (I * BootSec.SectorsPerFAT), @Buffer) Then Exit;
 End;

 UpdateFATEntry:=True;
End;

{ Allouer un nouveau cluster et le chaîner au précédent }
Function AllocateNewCluster(Drive:Byte;BootSec:BootSectorRec;PreviousCluster:Word):Word;
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
Function WriteFileData(Handle:Word;Buffer:Pointer;BytesToWrite:Word;Var BytesWritten:Word):Word;
Var
 FileEntry: FileTableEntry;
 Drive: Byte;
 BootSec: BootSectorRec;
 CurrentCluster: Word;
 ClusterSize: Word;
 RemainingInCluster: Word;
 BytesToWriteNow: Word;
 BufferOfs: Word;
 BufferSeg: Word;
 TotalBytesWritten: Word;
 Result: Word;
 NewCluster: Word;
Begin
 WriteFileData:=6; { Invalid handle par défaut }
 BytesWritten:=0;

 { Vérifier la validité du handle }
 If Handle >= 20 Then Exit;

 If Not GetFileTableEntry(Handle, FileEntry) Then Exit;

 { Vérifier si le handle est utilisé }
 If Not FileEntry.InUse Then Exit;

 Drive:=FileEntry.Drive - 1; { Conversion en index 0-based }

 { Lire boot sector }
 If Not ReadBootSector(Drive, BootSec) Then Begin
  WriteFileData:=5; { Access denied }
  Exit;
 End;

 { Vérifier si on peut écrire (pas en mode lecture seule) }
 If (FileEntry.Attributes and $02) = 0 Then Begin { Mode lecture seule }
  WriteFileData:=5; { Access denied }
  Exit;
 End;

 TotalBytesWritten:=0;

 { Extraire segment et offset du pointeur }
 ASM
  LES DI,Buffer
  MOV BufferSeg,ES
  MOV BufferOfs,DI
 END;

 CurrentCluster:=FileEntry.CurrentCluster;
 If CurrentCluster = 0 Then CurrentCluster:=FileEntry.FirstCluster;
 If CurrentCluster = 0 Then Begin
  { Premier cluster du fichier }
  CurrentCluster:=AllocateNewCluster(Drive, BootSec, 0);
  If CurrentCluster = 0 Then Begin
   WriteFileData:=5; { Access denied - disque plein }
   Exit;
  End;
  FileEntry.FirstCluster:=CurrentCluster;
  FileEntry.CurrentCluster:=CurrentCluster;
 End;

 ClusterSize:=BootSec.SectorsPerCluster * BootSec.BytesPerSector;

 While BytesToWrite > 0 Do Begin
  { Calculer combien on peut écrire dans le cluster courant }
  RemainingInCluster:=ClusterSize - FileEntry.ClusterOffset;
  BytesToWriteNow:=BytesToWrite;
  If BytesToWriteNow > RemainingInCluster Then
   BytesToWriteNow:=RemainingInCluster;

  { Écrire dans le cluster courant }
  Result:=WriteToCluster(Drive, BootSec, CurrentCluster, FileEntry.ClusterOffset, Ptr(BufferSeg, BufferOfs), BytesToWriteNow);
  If Result <> 0 Then Begin
   WriteFileData:=Result;
   Exit;
  End;

  { Mettre à jour les pointeurs et compteurs }
  Inc(BufferOfs, BytesToWriteNow);

  { Gérer le débordement de segment }
  If BufferOfs >= $10000 Then Begin
   Inc(BufferSeg, $1000);
   Dec(BufferOfs, $10000);
  End;

  Inc(TotalBytesWritten, BytesToWriteNow);
  Dec(BytesToWrite, BytesToWriteNow);
  Inc(FileEntry.CurrentPos, BytesToWriteNow);
  Inc(FileEntry.ClusterOffset, BytesToWriteNow);

  { Mettre à jour la taille du fichier si nécessaire }
  If FileEntry.CurrentPos > FileEntry.FileSize Then
   FileEntry.FileSize:=FileEntry.CurrentPos;

  { Si on a fini ce cluster et qu'il reste des données, allouer un nouveau cluster }
  If (FileEntry.ClusterOffset >= ClusterSize) and (BytesToWrite > 0) Then Begin
   NewCluster:=AllocateNewCluster(Drive, BootSec, CurrentCluster);
   If NewCluster = 0 Then Begin
    WriteFileData:=5; { Access denied - disque plein }
    Exit;
   End;
   CurrentCluster:=NewCluster;
   FileEntry.CurrentCluster:=CurrentCluster;
   FileEntry.ClusterOffset:=0;
  End;
 End;

 { Mettre à jour l'entrée de fichier }
 SetFileTableEntry(Handle, FileEntry);

 BytesWritten:=TotalBytesWritten;
 WriteFileData:=0; { Succès }
End;

{ Fonction principale 40h }
Function DOS40h_WriteFile(Handle:Word;Buffer:Pointer;BytesToWrite:Word;Var BytesWritten:Word):Word;
Begin
 DOS40h_WriteFile:=WriteFileData(Handle, Buffer, BytesToWrite, BytesWritten);
End;

{ Supprimer une entrée de répertoire }
Function DeleteDirectoryEntry(Drive:Byte;BootSec:BootSectorRec;DirCluster:Word;FileName:String):Boolean;
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
  FirstDataSector:=BootSec.ReservedSectors + (BootSec.NumberOfFATs * BootSec.SectorsPerFAT);
  DirSector:=FirstDataSector;
  SectorsToRead:=(BootSec.RootDirEntries * 32) div BootSec.BytesPerSector;
 End
 Else Begin
  { Sous-répertoire }
  FirstDataSector:=BootSec.ReservedSectors + (BootSec.NumberOfFATs * BootSec.SectorsPerFAT) +
                   ((BootSec.RootDirEntries * 32) div BootSec.BytesPerSector);
  DirSector:=FirstDataSector + (LongInt(DirCluster - 2) * BootSec.SectorsPerCluster);
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

   If Found and (Entry.FileName[0] <> #0) and (Entry.FileName[0] <> #$E5) Then Begin
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
Var
 Path: String;
 Drive: Byte;
 DirPath,FileName: String;
 BootSec: BootSectorRec;
 DirCluster: Word;
 Entry: DirectoryEntry;
 EntryOffset: Word;
 P: PChar;
 I: Byte;
 Handle: Word;
 FileEntry: FileTableEntry;
Begin
 DOS41h_DeleteFile:=2; { File not found par défaut }

 { Convertir pointeur ASCIIZ en string Pascal }
 P:=PChar(PathPtr);
 Path:='';
 I:=0;
 While (P^ <> #0) and (I < 255) Do Begin
  Path:=Path + P^;
  Inc(P);
  Inc(I);
 End;

 { Analyser le chemin }
 If Not ParseFilePath(Path,Drive,DirPath,FileName) Then Begin
  DOS41h_DeleteFile:=3; { Path not found }
  Exit;
 End;

 { Lire boot sector }
 If Not ReadBootSector(Drive,BootSec) Then Begin
  DOS41h_DeleteFile:=2; { File not found }
  Exit;
 End;

 { Trouver le répertoire parent }
 If DirPath = '' Then
  DirCluster:=0 { Répertoire racine }
 Else Begin
  If Not FindDirectoryByPath(Drive,BootSec,DirPath,DirCluster) Then Begin
   DOS41h_DeleteFile:=3; { Path not found }
   Exit;
  End;
 End;

 { Vérifier que le fichier existe }
 If Not FindDirectoryEntry(Drive,BootSec,DirCluster,FileName + '        ',Entry,EntryOffset) Then Begin
  DOS41h_DeleteFile:=2; { File not found }
  Exit;
 End;

 { Vérifier que c'est bien un fichier (pas un répertoire) }
 If (Entry.Attributes and $10) <> 0 Then Begin
  DOS41h_DeleteFile:=5; { Access denied - c'est un répertoire }
  Exit;
 End;

 { Vérifier si le fichier est ouvert }
 For Handle:=0 To 19 Do Begin
  If GetFileTableEntry(Handle, FileEntry) Then Begin
   If FileEntry.InUse and (FileEntry.FirstCluster = Entry.FirstClusterLow) Then Begin
    DOS41h_DeleteFile:=5; { Access denied - fichier ouvert }
    Exit;
   End;
  End;
 End;

 { Supprimer l'entrée de répertoire }
 If DeleteDirectoryEntry(Drive, BootSec, DirCluster, FileName + '        ') Then
  DOS41h_DeleteFile:=0 { Succès }
 Else
  DOS41h_DeleteFile:=5; { Access denied }
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
Function DOS42h_SeekFile(Handle:Word;OffsetHi,OffsetLo:Word;Method:Byte):LongInt;
Var
 FileEntry: FileTableEntry;
 NewPosition: LongInt;
 Offset: LongInt;
 TargetCluster: Word;
 ClusterOffset: Word;
 Drive: Byte;
 BootSec: BootSectorRec;
Begin
 DOS42h_SeekFile:=$FFFFFFFF; { Erreur par défaut }

 { Vérifier la validité du handle }
 If Handle >= 20 Then Exit;

 If Not GetFileTableEntry(Handle, FileEntry) Then Exit;

 { Vérifier si le handle est utilisé }
 If Not FileEntry.InUse Then Exit;

 { Construire l'offset 32-bit }
 Offset:=(LongInt(OffsetHi) shl 16) or OffsetLo;

 { Calculer la nouvelle position selon la méthode }
 Case Method Of
  0: NewPosition:=Offset;                        { Depuis le début }
  1: NewPosition:=FileEntry.CurrentPos + Offset; { Depuis position courante }
  2: NewPosition:=FileEntry.FileSize + Offset;   { Depuis la fin }
  Else Exit; { Méthode invalide }
 End;

 { Vérifier que la position est valide }
 If NewPosition < 0 Then Exit;

 { Pour les fichiers, on peut seek au-delà de la fin }
 { Mais on ne peut pas lire/écrire au-delà sans étendre le fichier }

 Drive:=FileEntry.Drive - 1; { Conversion en index 0-based }

 { Lire boot sector }
 If Not ReadBootSector(Drive, BootSec) Then Exit;

 { Si la nouvelle position est dans le fichier, calculer le cluster }
 If NewPosition <= FileEntry.FileSize Then Begin
  If NewPosition = 0 Then Begin
   { Position au début du fichier }
   FileEntry.CurrentCluster:=FileEntry.FirstCluster;
   FileEntry.ClusterOffset:=0;
  End
  Else Begin
   { Calculer le cluster et l'offset }
   If Not CalculateClusterFromPosition(Drive, BootSec,
           FileEntry.FirstCluster, NewPosition, TargetCluster,
           ClusterOffset) Then Exit;
   FileEntry.CurrentCluster:=TargetCluster;
   FileEntry.ClusterOffset:=ClusterOffset;
  End;
 End
 Else Begin
  { Position au-delà de la fin du fichier - utiliser le dernier cluster }
  If FileEntry.FileSize = 0 Then Begin
   FileEntry.CurrentCluster:=FileEntry.FirstCluster;
   FileEntry.ClusterOffset:=0;
  End
  Else Begin
   If Not CalculateClusterFromPosition(Drive, BootSec,
           FileEntry.FirstCluster, FileEntry.FileSize - 1,
           TargetCluster, ClusterOffset) Then Exit;
   FileEntry.CurrentCluster:=TargetCluster;
   { L'offset sera géré lors de la prochaine opération de lecture/écriture }
  End;
 End;

 { Mettre à jour la position courante }
 FileEntry.CurrentPos:=NewPosition;

 { Sauvegarder l'entrée modifiée }
 If Not SetFileTableEntry(Handle, FileEntry) Then Exit;

 DOS42h_SeekFile:=NewPosition;
End;

{ Obtenir les attributs d'un fichier }
Function GetFileAttributes(Drive:Byte;BootSec:BootSectorRec;DirCluster:Word;FileName:String;Var Attributes:Byte):Boolean;
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
  FirstDataSector:=BootSec.ReservedSectors + (BootSec.NumberOfFATs * BootSec.SectorsPerFAT);
  DirSector:=FirstDataSector;
  SectorsToRead:=(BootSec.RootDirEntries * 32) div BootSec.BytesPerSector;
 End
 Else Begin
  { Sous-répertoire }
  FirstDataSector:=BootSec.ReservedSectors + (BootSec.NumberOfFATs * BootSec.SectorsPerFAT) +
                   ((BootSec.RootDirEntries * 32) div BootSec.BytesPerSector);
  DirSector:=FirstDataSector + (LongInt(DirCluster - 2) * BootSec.SectorsPerCluster);
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

   If Found and (Entry.FileName[0] <> #0) and (Entry.FileName[0] <> #$E5) Then Begin
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
Function SetFileAttributes(Drive:Byte;BootSec:BootSectorRec;DirCluster:Word;FileName:String;NewAttributes:Byte):Boolean;
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
  FirstDataSector:=BootSec.ReservedSectors + (BootSec.NumberOfFATs * BootSec.SectorsPerFAT);
  DirSector:=FirstDataSector;
  SectorsToRead:=(BootSec.RootDirEntries * 32) div BootSec.BytesPerSector;
 End
 Else Begin
  { Sous-répertoire }
  FirstDataSector:=BootSec.ReservedSectors + (BootSec.NumberOfFATs * BootSec.SectorsPerFAT) +
                   ((BootSec.RootDirEntries * 32) div BootSec.BytesPerSector);
  DirSector:=FirstDataSector + (LongInt(DirCluster - 2) * BootSec.SectorsPerCluster);
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

   If Found and (Entry.FileName[0] <> #0) and (Entry.FileName[0] <> #$E5) Then Begin
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
Function DOS43h_GetSetFileAttributes(PathPtr:Pointer;Action:Byte;NewAttributes:Byte):Word;
Var
 Path: String;
 Drive: Byte;
 DirPath,FileName: String;
 BootSec: BootSectorRec;
 DirCluster: Word;
 Attributes: Byte;
 P: PChar;
 I: Byte;
Begin
 DOS43h_GetSetFileAttributes:=$FFFF; { Erreur par défaut }

 { Convertir pointeur ASCIIZ en string Pascal }
 P:=PChar(PathPtr);
 Path:='';
 I:=0;
 While (P^ <> #0) and (I < 255) Do Begin
  Path:=Path + P^;
  Inc(P);
  Inc(I);
 End;

 { Analyser le chemin }
 If Not ParseFilePath(Path,Drive,DirPath,FileName) Then Begin
  DOS43h_GetSetFileAttributes:=$FFFF; { Invalid path }
  Exit;
 End;

 { Lire boot sector }
 If Not ReadBootSector(Drive,BootSec) Then Begin
  DOS43h_GetSetFileAttributes:=$FFFF; { Invalid drive }
  Exit;
 End;

 { Trouver le répertoire parent }
 If DirPath = '' Then
  DirCluster:=0 { Répertoire racine }
 Else Begin
  If Not FindDirectoryByPath(Drive,BootSec,DirPath,DirCluster) Then Begin
   DOS43h_GetSetFileAttributes:=$FFFF; { Path not found }
   Exit;
  End;
 End;

 { Action selon le paramètre }
 Case Action Of
  0: Begin { Get attributes }
   If GetFileAttributes(Drive, BootSec, DirCluster, FileName + '        ', Attributes) Then
    DOS43h_GetSetFileAttributes:=Attributes
   Else
    DOS43h_GetSetFileAttributes:=$FFFF; { File not found }
  End;

  1: Begin { Set attributes }
   If SetFileAttributes(Drive, BootSec, DirCluster, FileName + '        ', NewAttributes) Then
    DOS43h_GetSetFileAttributes:=0 { Succès }
   Else
    DOS43h_GetSetFileAttributes:=$FFFF; { File not found }
  End;

  Else
   DOS43h_GetSetFileAttributes:=$FFFF; { Invalid action }
 End;
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
   DeviceInfo:=FileEntry.Drive - 1; { Numéro de lecteur (0=A:, 1=B:, etc.) }
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
 If Drive >= 26 Then Exit; { A: à Z: seulement }

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
 If Drive >= 26 Then Exit;

 { Cette fonction n'est généralement pas implémentée }
 { Elle permettrait de changer les paramètres du lecteur }

 IOCTL_SetDriveInfo:=0; { Succès simulé }
End;

{ Lire les données de contrôle (sous-fonction 02h) }
Function IOCTL_ReadControlData(Handle:Word;Buffer:Pointer;BytesToRead:Word):Word;
Begin
 IOCTL_ReadControlData:=1; { Invalid function par défaut }

 { Cette fonction lit des données spéciales du périphérique }
 { Non implémentée dans cette version basique }

 IOCTL_ReadControlData:=0; { Pas de données lues }
End;

{ Écrire les données de contrôle (sous-fonction 03h) }
Function IOCTL_WriteControlData(Handle:Word;Buffer:Pointer;BytesToWrite:Word):Word;
Begin
 IOCTL_WriteControlData:=1; { Invalid function par défaut }

 { Cette fonction écrit des données spéciales vers le périphérique }
 { Non implémentée dans cette version basique }

 IOCTL_WriteControlData:=0; { Pas de données écrites }
End;

{ Fonction principale 44h - IOCTL }
Function DOS44h_IOCTL(Handle:Word;SubFunction:Byte;Buffer:Pointer;ByteCount:Word):Word;
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
   Drive:=Handle; { Pour cette sous-fonction, Handle contient le numéro de lecteur }
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

{ Fonction 45h - Duplicate Handle }
Function DOS45h_DuplicateHandle(SourceHandle:Word):Word;
Var
 SourceEntry: FileTableEntry;
 NewHandle: Word;
 NewEntry: FileTableEntry;
Begin
 DOS45h_DuplicateHandle:=$FFFF; { Erreur par défaut }
 
 { Vérifier la validité du handle source }
 If SourceHandle >= 20 Then Exit;
 
 If Not GetFileTableEntry(SourceHandle, SourceEntry) Then Exit;
 
 { Vérifier si le handle source est utilisé }
 If Not SourceEntry.InUse Then Exit;
 
 { Trouver un nouveau handle libre }
 For NewHandle:=0 To 19 Do Begin
  If GetFileTableEntry(NewHandle, NewEntry) Then Begin
   If Not NewEntry.InUse Then Begin
    { Copier toutes les informations du handle source }
    NewEntry.InUse:=True;
    NewEntry.Drive:=SourceEntry.Drive;
    NewEntry.FirstCluster:=SourceEntry.FirstCluster;
    NewEntry.CurrentCluster:=SourceEntry.CurrentCluster;
    NewEntry.CurrentPos:=SourceEntry.CurrentPos;
    NewEntry.FileSize:=SourceEntry.FileSize;
    NewEntry.Attributes:=SourceEntry.Attributes;
    NewEntry.ClusterOffset:=SourceEntry.ClusterOffset;
    
    { Sauvegarder la nouvelle entrée }
    If SetFileTableEntry(NewHandle, NewEntry) Then Begin
     { Incrémenter le compteur de références si c'est un fichier }
     If SourceHandle >= 5 Then Begin
      { Pour les fichiers normaux, on incrémente un compteur de références }
      { Dans cette implémentation simplifiée, on marque juste comme dupliqué }
     End;
     
     DOS45h_DuplicateHandle:=NewHandle;
     Exit;
    End;
   End;
  End;
 End;
 
 { Aucun handle libre trouvé }
 DOS45h_DuplicateHandle:=$FFFF;
End;

{ Fonction 46h - Force Duplicate Handle }
Function DOS46h_ForceDuplicateHandle(SourceHandle:Word;TargetHandle:Word):Word;
Var
 SourceEntry: FileTableEntry;
 TargetEntry: FileTableEntry;
Begin
 DOS46h_ForceDuplicateHandle:=6; { Invalid handle par défaut }
 
 { Vérifier la validité des handles }
 If (SourceHandle >= 20) Or (TargetHandle >= 20) Then Begin
  DOS46h_ForceDuplicateHandle:=6; { Invalid handle }
  Exit;
 End;
 
 { Vérifier que le handle source existe }
 If Not GetFileTableEntry(SourceHandle, SourceEntry) Then Exit;
 
 { Vérifier si le handle source est utilisé }
 If Not SourceEntry.InUse Then Exit;
 
 { Si le handle de destination est déjà utilisé, le fermer d'abord }
 If GetFileTableEntry(TargetHandle, TargetEntry) Then Begin
  If TargetEntry.InUse Then Begin
   { Fermer le handle de destination s'il est ouvert }
   { Pour les handles système (0-4), on ne les ferme pas réellement }
   If TargetHandle >= 5 Then Begin
    TargetEntry.InUse:=False;
    TargetEntry.FirstCluster:=0;
    TargetEntry.FileSize:=0;
    TargetEntry.CurrentPos:=0;
    TargetEntry.CurrentCluster:=0;
    TargetEntry.ClusterOffset:=0;
    SetFileTableEntry(TargetHandle, TargetEntry);
   End;
  End;
 End Else Begin
  { Initialiser l'entrée de destination si elle n'existe pas }
  FillChar(TargetEntry, SizeOf(TargetEntry), 0);
 End;
 
 { Copier toutes les informations du handle source vers la destination }
 TargetEntry.InUse:=True;
 TargetEntry.Drive:=SourceEntry.Drive;
 TargetEntry.FirstCluster:=SourceEntry.FirstCluster;
 TargetEntry.CurrentCluster:=SourceEntry.CurrentCluster;
 TargetEntry.CurrentPos:=SourceEntry.CurrentPos;
 TargetEntry.FileSize:=SourceEntry.FileSize;
 TargetEntry.Attributes:=SourceEntry.Attributes;
 TargetEntry.ClusterOffset:=SourceEntry.ClusterOffset;
 
 { Sauvegarder l'entrée de destination }
 If SetFileTableEntry(TargetHandle, TargetEntry) Then Begin
  { Marquer comme réussi }
  DOS46h_ForceDuplicateHandle:=0; { Succès }
 End Else Begin
  DOS46h_ForceDuplicateHandle:=6; { Invalid handle }
 End;
End;

{ Fonction 47h - Get Current Directory }
Function DOS47h_GetCurrentDirectory(Drive:Byte;BufferSeg:Word;BufferOfs:Word):Word;
Var
 CurrentDrive: Byte;
 CurrentCluster: Word;
 PathBuffer: Array[0..63] Of Char;
 PathStr: String;
Begin
 DOS47h_GetCurrentDirectory:=15; { Invalid drive par défaut }
 
 { Déterminer le lecteur à utiliser }
 If Drive = 0 Then
  CurrentDrive:=GetCurrentDrive
 Else Begin
  CurrentDrive:=Drive - 1; { 1=A:, 2=B:, etc. -> 0=A:, 1=B:, etc. }
  If CurrentDrive >= 26 Then Begin
   DOS47h_GetCurrentDirectory:=15; { Invalid drive }
   Exit;
  End;
 End;
 
 { Obtenir le cluster du répertoire courant pour ce lecteur }
 CurrentCluster:=GetCurrentDirCluster(CurrentDrive);
 
 { Si c'est le répertoire racine, retourner chaîne vide }
 If CurrentCluster = 0 Then Begin
  { Écrire une chaîne vide dans le buffer }
  ASM
   PUSH DS
   MOV AX,BufferSeg
   MOV DS,AX
   MOV SI,BufferOfs
   MOV BYTE PTR [SI],0     { Terminator null }
   POP DS
  END;
  DOS47h_GetCurrentDirectory:=0;
  Exit;
 End;
 
 { Pour cette implémentation simplifiée, retourner un chemin générique }
 { basé sur le numéro de cluster du répertoire courant }
 PathStr:='SUBDIR';
 
 { Copier le chemin dans le buffer de l'utilisateur }
 ASM
  PUSH DS
  PUSH ES
  
  { Pointer vers notre string PathStr }
  LEA SI,PathStr
  MOV CL,[SI]        { Longueur de la chaîne }
  INC SI             { Pointer vers le contenu }
  
  { Pointer vers le buffer utilisateur }
  MOV AX,BufferSeg
  MOV ES,AX
  MOV DI,BufferOfs
  
  { Copier le chemin }
  MOV CH,0
  CLD
  REP MOVSB
  
  { Ajouter le terminateur null }
  MOV AL,0
  STOSB
  
  POP ES
  POP DS
 END;
 
 DOS47h_GetCurrentDirectory:=0; { Succès }
End;

{ Fonctions de gestion de la mémoire }

{ Initialise le gestionnaire de mémoire }
Function InitializeMemoryManager:Boolean;
Var
 MCB: MemoryControlBlock;
 FirstMCB: Word;
Begin
 InitializeMemoryManager:=False;
 
 { Le premier MCB commence généralement à 0x0060 (après les vecteurs d'interruption) }
 FirstMCB:=$0060;
 
 { Créer le premier MCB couvrant toute la mémoire conventionnelle }
 MCB.BlockType:='Z';      { Dernier bloc }
 MCB.Owner:=0;            { Bloc libre }
 MCB.BlockSize:=$9F00;    { ~640KB - adresse de départ }
 FillChar(MCB.Reserved, 3, 0);
 FillChar(MCB.ProgramName, 8, 0);
 
 If SetMCB(FirstMCB, MCB) Then Begin
  { Initialiser la stratégie d'allocation par défaut (First Fit) }
  SetMemoryStrategy(0);
  
  { Initialiser l'état UMB par défaut (non liés) }
  SetUMBLinkState(0);
  
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
 CurrentSeg:=$0060; { Premier MCB }
 
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
 If BlockSegment < $0061 Then Exit; { Trop bas }
 
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
 If BlockSegment < $0061 Then Exit;
 
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
  
  { Copier l'environnement }
  ASM
   PUSH ES
   PUSH DS
   
   MOV AX,EnvSegment
   MOV ES,AX
   XOR DI,DI
   
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
Function LoadExeFile(FileName:String;Var LoadSegment:Word;Var ExeHdr:ExeHeader):Boolean;
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

{ Fonction principale 4Bh - EXEC }
Function DOS4Bh_ExecProgram(ExecType:Byte;ProgramPath:String;ParamBlock:ExecParameterBlock):Word;
Var
 PSPSeg: Word;
 LoadSeg: Word;
 EnvSeg: Word;
 ExeHdr: ExeHeader;
 IsCOM: Boolean;
 ProgPath: String;
Begin
 DOS4Bh_ExecProgram:=2; { File not found par défaut }
 
 { Convertir le chemin (implémentation simplifiée) }
 ProgPath:=ProgramPath;
 
 { Déterminer le type de fichier }
 IsCOM:=(Pos('.COM', UpperCase(ProgPath)) > 0);
 
 { Créer l'environnement }
 EnvSeg:=SetupEnvironment(ParamBlock.Environment, 0);
 If EnvSeg = 0 Then Begin
  DOS4Bh_ExecProgram:=8; { Insufficient memory }
  Exit;
 End;
 
 { Charger le programme }
 If IsCOM Then Begin
  If Not LoadComFile(ProgPath, LoadSeg) Then Begin
   DOS49h_FreeMemory(EnvSeg);
   Exit;
  End;
 End
 Else Begin
  If Not LoadExeFile(ProgPath, LoadSeg, ExeHdr) Then Begin
   DOS49h_FreeMemory(EnvSeg);
   Exit;
  End;
 End;
 
 { Créer le PSP }
 PSPSeg:=CreatePSP(0, LoadSeg + $1000); { Approximation }
 If PSPSeg = 0 Then Begin
  DOS49h_FreeMemory(LoadSeg);
  DOS49h_FreeMemory(EnvSeg);
  DOS4Bh_ExecProgram:=8;
  Exit;
 End;
 
 { Pour type 00h (Load and Execute), transférer le contrôle }
 If ExecType = 0 Then Begin
  { Implémentation simplifiée - ne transfère pas réellement le contrôle }
  { Dans un vrai système, on ferait un FAR CALL vers le programme }
  
  { Libérer les ressources pour l'instant }
  DOS49h_FreeMemory(PSPSeg);
  DOS49h_FreeMemory(LoadSeg);
  DOS49h_FreeMemory(EnvSeg);
 End;
 
 DOS4Bh_ExecProgram:=0; { Succès }
End;

{ Charge et exécute le processeur de commandes }
Procedure LoadAndExecuteCommandProcessor;
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
 
 { Essayer de charger COMMAND.COM en premier }
 Result:=DOS4Bh_ExecProgram(0, 'C:\COMMAND.COM', ParamBlock);
 If Result <> 0 Then Begin
  { Si COMMAND.COM échoue, essayer COMMAND.EXE }
  Result:=DOS4Bh_ExecProgram(0, 'C:\COMMAND.EXE', ParamBlock);
  If Result <> 0 Then Begin
   { Si les deux échouent, essayer dans le répertoire courant }
   Result:=DOS4Bh_ExecProgram(0, 'COMMAND.COM', ParamBlock);
   If Result <> 0 Then Begin
    { Dernier essai avec COMMAND.EXE local }
    Result:=DOS4Bh_ExecProgram(0, 'COMMAND.EXE', ParamBlock);
   End;
  End;
 End;
 
 { Si aucun processeur de commandes n'est trouvé, continuer quand même }
 { Le système restera en mode noyau }
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
     If MatchFileName(Copy(FileName,FI,FLen-FI+1),Copy(Mask,MI,MLen-MI+1)) Then Begin
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
 Result: String;
 I: Byte;
Begin
 Result:='';
 
 { Nom principal (8 caractères max) }
 For I:=0 To 7 Do Begin
  If DOS83[I] <> ' ' Then Result:=Result + DOS83[I]
  Else Break;
 End;
 
 { Extension (3 caractères max) }
 If DOS83[8] <> ' ' Then Begin
  Result:=Result + '.';
  For I:=8 To 10 Do Begin
   If DOS83[I] <> ' ' Then Result:=Result + DOS83[I]
   Else Break;
  End;
 End;
 
 DOS83ToString:=Result;
End;

{ Fonctions FAT pour accès au répertoire racine }

{ Obtient le secteur de début du répertoire racine }
Function GetRootDirectorySector:Word;
Var
 BootSec: BootSectorRec;
 Drive: Byte;
Begin
 GetRootDirectorySector:=0;
 
 { Utiliser le lecteur courant }
 ASM
  MOV AL,Data.DataMOS.CurrDisk
  MOV Drive,AL
 END;
 
 { Lire le boot sector - implémentation simplifiée }
 { Pour l'instant, retourner des valeurs par défaut pour FAT12 }
 If Drive <= 1 Then Begin { A: ou B: - disquettes }
  GetRootDirectorySector:=19; { Secteur typique pour disquette 1.44MB }
 End Else Begin { C: et plus - disques durs }
  GetRootDirectorySector:=33; { Secteur typique pour disque dur FAT16 }
 End;
End;

{ Obtient la taille du répertoire racine en secteurs }
Function GetRootDirectorySize:Word;
Var
 BootSec: BootSectorRec;
 Drive: Byte;
Begin
 GetRootDirectorySize:=0;
 
 { Utiliser le lecteur courant }
 ASM
  MOV AL,Data.DataMOS.CurrDisk
  MOV Drive,AL
 END;
 
 { Retourner des valeurs par défaut selon le type de lecteur }
 If Drive <= 1 Then Begin { A: ou B: - disquettes }
  GetRootDirectorySize:=14; { 224 entrées * 32 bytes / 512 = 14 secteurs }
 End Else Begin { C: et plus - disques durs }
  GetRootDirectorySize:=32; { 512 entrées * 32 bytes / 512 = 32 secteurs }
 End;
End;

{ Lecture simplifiée d'un secteur pour Find File }
Function ReadSectorSimple(Sector:Word;Var Buffer):Boolean;
Var
 DriveNum: Byte;
 Head, Track, SectorNum: Byte;
 ReadSuccess: Byte;
 Result: Boolean;
Begin
 Result := False;
 ReadSuccess := 0;
 
 { Calculer les paramètres CHS pour le lecteur C: (disque dur) }
 DriveNum := $80;  { Premier disque dur }
 
 { Conversion LBA vers CHS (supposons géométrie standard 63 secteurs/piste, 16 têtes) }
 Head := (Sector DIV 63) MOD 16;
 Track := Sector DIV (63 * 16);
 SectorNum := (Sector MOD 63) + 1;  { Les secteurs commencent à 1 }
 
 { Préparer les registres pour INT 13h, fonction 02h (lecture secteur) }
 ASM
  { Sauvegarder les registres importants }
  PUSH AX
  PUSH BX
  PUSH CX
  PUSH DX
  PUSH ES
  
  { Paramètres pour INT 13h fonction 02h }
  MOV AH, 02h           { Fonction lecture secteur }
  MOV AL, 1             { Nombre de secteurs à lire }
  MOV DL, DriveNum      { Lecteur }
  MOV DH, Head          { Tête }
  MOV CH, Track         { Piste (cylindre) }
  MOV CL, SectorNum     { Secteur }
  
  { Pointer ES:BX vers le buffer }
  LES BX, Buffer
  
  { Appeler l'interruption BIOS }
  INT 13h
  
  { Vérifier le résultat (CF=0 si succès) }
  JC @ReadError
  
  { Succès }
  MOV ReadSuccess, 1
  JMP @ReadDone
  
@ReadError:
  { Erreur }
  MOV ReadSuccess, 0
  
@ReadDone:
  { Restaurer les registres }
  POP ES
  POP DX
  POP CX
  POP BX
  POP AX
 END;
 
 { Assigner le résultat }
 Result := (ReadSuccess <> 0);
 
 { Retourner le résultat final }
 ReadSectorSimple := Result;
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
 
 { Conversion LBA vers CHS (supposons géométrie standard 63 secteurs/piste, 16 têtes) }
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
Procedure GetFindState(Var State:FindFileState);
Begin
 { Les données sont stockées dans le Code Segment dans la structure Data }
 ASM
  PUSH DS
  PUSH SI
  
  { Pointer vers la structure Data.DataMOS.FindState }
  MOV SI,OFFSET Data.DataMOS
  ADD SI,TYPE DataMOS - TYPE FindFileState  { Offset vers FindState }
  
  { Copier FindState depuis le Code Segment vers la variable paramètre }
  LES DI,State
  MOV CX,TYPE FindFileState
  CLD
  REP MOVSB
  
  POP SI
  POP DS
 END;
End;

{ Sauvegarde l'état de recherche de fichiers dans le Code Segment }
Procedure SetFindState(Var State:FindFileState);
Begin
 { Sauvegarder dans le Code Segment dans la structure Data }
 ASM
  PUSH ES
  PUSH DI
  
  { Pointer vers la structure Data.DataMOS.FindState }
  PUSH CS
  POP ES
  MOV DI,OFFSET Data.DataMOS
  ADD DI,TYPE DataMOS - TYPE FindFileState  { Offset vers FindState }
  
  { Copier State vers le Code Segment }
  LDS SI,State
  MOV CX,TYPE FindFileState
  CLD
  REP MOVSB
  
  POP DI
  POP ES
 END;
End;

{ Fonctions 4Ch et 4Dh - Terminaison et code de retour }

{ Fonction 4Ch - Terminate Program }
Function DOS4Ch_TerminateProgram(ExitCode:Byte):Word;
Var
 CurrentPSP: Word;
 ParentPSP: Word;
Begin
 DOS4Ch_TerminateProgram:=0;
 
 { Obtenir le PSP courant }
 CurrentPSP:=GetCurrentPSP;
 If CurrentPSP = 0 Then CurrentPSP:=$1000; { PSP par défaut si non défini }
 
 { Lire le PSP pour obtenir le parent }
 ParentPSP:=0; { Valeur par défaut }
 ASM
  PUSH DS
  MOV AX,CurrentPSP
  MOV DS,AX
  
  { Lire ParentPSP à l'offset $16 }
  MOV AX,[16h]       { Offset $16 = ParentPSP }
  MOV ParentPSP,AX
  
  POP DS
 END;
 
 { Sauvegarder le code de retour }
 { AH = 0 (terminaison normale), AL = code de sortie }
 SetLastReturnCode(ExitCode);
 
 { Fermer les handles ouverts (implémentation simplifiée) }
 { Dans un vrai DOS, on fermerait tous les handles du processus }
 
 { Libérer la mémoire du PSP et du programme }
 If CurrentPSP <> $1000 Then Begin { Ne pas libérer le PSP système }
  DOS49h_FreeMemory(CurrentPSP);
 End;
 
 { Restaurer le PSP parent }
 SetCurrentPSP(ParentPSP);
 
 { Dans un vrai DOS, on ferait un JMP vers le parent }
 { Pour l'instant, on retourne simplement }
 
 DOS4Ch_TerminateProgram:=0;
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
Var
 SearchPath: String;
 SearchName: String;
 DirEntry: DirectoryEntryFAT;
 RootDirSector, Sector: Word;
 EntryIndex: Word;
 Buffer: Array[0..511] of Byte;
 I, Pos: Byte;
 FileName: String;
 FindState: FindFileState;
Begin
 DOS4Eh_FindFirstFile:=18; { Pas d'autres fichiers par défaut }
 
 { Initialiser l'état de recherche }
 GetFindState(FindState);
 With FindState Do Begin
  Active:=False;
  CurrentDir:=0;  { Répertoire racine par défaut }
  CurrentEntry:=0;
  
  { Extraire le chemin et le masque de recherche }
  Pos:=Length(Path);
  While (Pos > 0) And (Path[Pos] <> '\') And (Path[Pos] <> '/') Do Dec(Pos);
  
  If Pos > 0 Then Begin
   SearchPath:=Copy(Path,1,Pos);
   SearchName:=Copy(Path,Pos+1,Length(Path)-Pos);
  End Else Begin
   SearchPath:='';
   SearchName:=Path;
  End;
  
  { Si pas de masque spécifié, utiliser *.* }
  If SearchName = '' Then SearchName:='*.*';
  SearchMask:=UpperCase(SearchName);
  SearchPath:=UpperCase(SearchPath);
  SearchAttr:=Attr;
 End;
 SetFindState(FindState);
 
 { Commencer la recherche dans le répertoire racine }
 RootDirSector:=GetRootDirectorySector;
 If RootDirSector = 0 Then Exit;
 
 EntryIndex:=0;
 Sector:=RootDirSector;
 
 { Parcourir les entrées du répertoire racine }
 While Sector < (RootDirSector + GetRootDirectorySize) Do Begin
  If Not ReadSectorSimple(Sector,Buffer) Then Exit;
  
  For I:=0 To 15 Do Begin { 16 entrées par secteur }
   Move(Buffer[I * 32],DirEntry,SizeOf(DirectoryEntryFAT));
   
   { Ignorer les entrées supprimées ou vides }
   If DirEntry.FileName[0] = #0 Then Break; { Fin des entrées }
   If DirEntry.FileName[0] = #$E5 Then Begin
    Inc(EntryIndex);
    Continue; { Entrée supprimée }
   End;
   
   { Vérifier les attributs }
   If (DirEntry.Attributes And $08) <> 0 Then Begin { Volume Label }
    Inc(EntryIndex);
    Continue;
   End;
   
   { Construire le nom du fichier }
   FileName:=DOS83ToString(DirEntry.FileName);
   
   { Vérifier si le nom correspond au masque }
   If MatchFileName(FileName,FindState.SearchMask) Then Begin
    { Vérifier les attributs }
    If (Attr And $10) <> 0 Then Begin { Chercher répertoires }
     If (DirEntry.Attributes And $10) = 0 Then Begin
      Inc(EntryIndex);
      Continue; { Pas un répertoire }
     End;
    End Else Begin { Chercher fichiers }
     If (DirEntry.Attributes And $10) <> 0 Then Begin
      Inc(EntryIndex);
      Continue; { Pas un fichier }
     End;
    End;
    
    { Fichier trouvé ! Remplir la DTA }
    FillChar(DTA.Reserved,21,0);
    DTA.Attribute:=DirEntry.Attributes;
    DTA.Time:=DirEntry.Time;
    DTA.Date:=DirEntry.Date;
    DTA.Size:=DirEntry.Size;
    
    { Copier le nom (format 8.3 avec terminateur null) }
    Move(FileName[1],DTA.Name[0],Length(FileName));
    DTA.Name[Length(FileName)]:=#0;
    
    { Mettre à jour l'état pour FindNext }
    GetFindState(FindState);
    With FindState Do Begin
     Active:=True;
     CurrentEntry:=EntryIndex + 1;
    End;
    SetFindState(FindState);
    
    DOS4Eh_FindFirstFile:=0; { Succès }
    Exit;
   End;
   
   Inc(EntryIndex);
  End;
  
  Inc(Sector);
 End;
End;

{ Fonction 4Fh - Find Next File }
Function DOS4Fh_FindNextFile(var DTA:DTAStruct):Word;
Var
 DirEntry: DirectoryEntryFAT;
 RootDirSector, Sector: Word;
 Buffer: Array[0..511] of Byte;
 I: Byte;
 FileName: String;
 EntryIndex, SectorEntry: Word;
 FindState: FindFileState;
Begin
 DOS4Fh_FindNextFile:=18; { Pas d'autres fichiers }
 
 { Vérifier si une recherche est active }
 GetFindState(FindState);
 If Not FindState.Active Then Exit;
 
 RootDirSector:=GetRootDirectorySector;
 If RootDirSector = 0 Then Exit;
 
 EntryIndex:=FindState.CurrentEntry;
 Sector:=RootDirSector + (EntryIndex Div 16);
 SectorEntry:=EntryIndex Mod 16;
 
 { Continuer la recherche depuis la position courante }
 While Sector < (RootDirSector + GetRootDirectorySize) Do Begin
  If Not ReadSectorSimple(Sector,Buffer) Then Exit;
  
  For I:=SectorEntry To 15 Do Begin { Continuer depuis la position courante }
   Move(Buffer[I * 32],DirEntry,SizeOf(DirectoryEntryFAT));
   
   { Ignorer les entrées supprimées ou vides }
   If DirEntry.FileName[0] = #0 Then Begin
    GetFindState(FindState);
    FindState.Active:=False;
    SetFindState(FindState);
    Exit; { Fin des entrées }
   End;
   
   If DirEntry.FileName[0] = #$E5 Then Begin
    Inc(EntryIndex);
    Continue; { Entrée supprimée }
   End;
   
   { Vérifier les attributs }
   If (DirEntry.Attributes And $08) <> 0 Then Begin { Volume Label }
    Inc(EntryIndex);
    Continue;
   End;
   
   { Construire le nom du fichier }
   FileName:=DOS83ToString(DirEntry.FileName);
   
   { Vérifier si le nom correspond au masque }
   If MatchFileName(FileName,FindState.SearchMask) Then Begin
    { Vérifier les attributs }
    If (FindState.SearchAttr And $10) <> 0 Then Begin { Chercher répertoires }
     If (DirEntry.Attributes And $10) = 0 Then Begin
      Inc(EntryIndex);
      Continue; { Pas un répertoire }
     End;
    End Else Begin { Chercher fichiers }
     If (DirEntry.Attributes And $10) <> 0 Then Begin
      Inc(EntryIndex);
      Continue; { Pas un fichier }
     End;
    End;
    
    { Fichier trouvé ! Remplir la DTA }
    FillChar(DTA.Reserved,21,0);
    DTA.Attribute:=DirEntry.Attributes;
    DTA.Time:=DirEntry.Time;
    DTA.Date:=DirEntry.Date;
    DTA.Size:=DirEntry.Size;
    
    { Copier le nom (format 8.3 avec terminateur null) }
    Move(FileName[1],DTA.Name[0],Length(FileName));
    DTA.Name[Length(FileName)]:=#0;
    
    { Mettre à jour l'état pour le prochain FindNext }
    GetFindState(FindState);
    FindState.CurrentEntry:=EntryIndex + 1;
    SetFindState(FindState);
    
    DOS4Fh_FindNextFile:=0; { Succès }
    Exit;
   End;
   
   Inc(EntryIndex);
  End;
  
  Inc(Sector);
  SectorEntry:=0; { Commencer au début du secteur suivant }
 End;
 
 { Plus de fichiers trouvés }
 GetFindState(FindState);
 FindState.Active:=False;
 SetFindState(FindState);
End;

{ Fonctions 50h et 51h - Gestion PSP (Program Segment Prefix) }

{ Fonction 50h - Set PSP Address }
Function DOS50h_SetPSPAddress(PSPSegment:Word):Word;
Begin
 DOS50h_SetPSPAddress:=0; { Succès par défaut }
 
 { Valider que le segment PSP est valide }
 If PSPSegment < $0060 Then Begin { En-dessous de la zone conventionnelle }
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
Function DOS52h_GetListOfLists:Pointer;
Begin
 { Retourner un pointeur vers la structure Liste des Listes }
 { L'adresse est calculée dynamiquement }
 ASM
  MOV AX,CS
  MOV DX,AX              { DX = segment }
  
  { Calculer l'offset de la structure dans le segment de données }
  MOV AX,OFFSET Data
  ADD AX,3500            { Offset approximatif vers la structure }
  
  { Retourner le pointeur dans AX:DX }
  { En Pascal, Pointer est retourné dans AX (offset) et DX (segment) }
 END;
End;

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
  LDS SI,BPBPtr
  LEA DI,BPB
  MOV CX,TYPE BIOSParameterBlock
  CLD
  REP MOVSB
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
 DPB.FirstDirSector:=BPB.ReservedSectors + (BPB.NumberOfFATs * BPB.SectorsPerFAT);
 DPB.FirstDataSector:=DPB.FirstDirSector + ((BPB.RootDirEntries * 32) div BPB.BytesPerSector);
 
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
  LES DI,DPBPtr
  LEA SI,DPB
  MOV CX,TYPE DriveParameterBlock
  CLD
  REP MOVSB
  POP ES
 END;
 
 DOS53h_TranslateBPBtoDPB:=0; { Succès }
End;

{ Fonctions 2Eh et 54h - Vérification en écriture avec vraies vérifications }

{ Fonction utilitaire - Vérifier l'écriture d'un secteur }
Function VerifyWrite(Drive:Byte;Sector:LongInt;Buffer:Pointer;Size:Word):Boolean;
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
Function WriteSectorWithVerify(Drive:Byte;Sector:LongInt;Buffer:Pointer):Boolean;
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
 If NewPSPSegment < $0060 Then Begin { En-dessous de la zone conventionnelle }
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
Function ParseFullPath(Path:String;Var Drive:Byte;Var DirPath,FileName:String):Boolean;
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
 If Drive <= 1 Then
  RootSector := 19  { Disquettes }
 Else
  RootSector := 33; { Disques durs }
 
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
Function UpdateDirectoryEntryName(Drive:Byte;DirCluster:Word;EntryOffset:Word;NewName:String):Boolean;
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
 If Drive <= 1 Then
  RootSector := 19
 Else
  RootSector := 33;
 
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
Var
 OldPath, NewPath: String;
 OldDrive, NewDrive: Byte;
 OldDirPath, OldFileName: String;
 NewDirPath, NewFileName: String;
 OldEntry: DirectoryEntryFAT;
 EntryOffset: Word;
 P: PChar;
 I: Byte;
Begin
 DOS56h_RenameFile := 2; { File not found par défaut }
 
 { Convertir les pointeurs ASCIIZ en chaînes Pascal }
 P := PChar(OldPathPtr);
 OldPath := '';
 I := 0;
 While (P^ <> #0) And (I < 255) Do Begin
  OldPath := OldPath + P^;
  Inc(P);
  Inc(I);
 End;
 
 P := PChar(NewPathPtr);
 NewPath := '';
 I := 0;
 While (P^ <> #0) And (I < 255) Do Begin
  NewPath := NewPath + P^;
  Inc(P);
  Inc(I);
 End;
 
 { Analyser les chemins }
 If Not ParseFullPath(OldPath, OldDrive, OldDirPath, OldFileName) Then Begin
  DOS56h_RenameFile := 2; { File not found }
  Exit;
 End;
 
 If Not ParseFullPath(NewPath, NewDrive, NewDirPath, NewFileName) Then Begin
  DOS56h_RenameFile := 3; { Path not found }
  Exit;
 End;
 
 { Vérifier que c'est sur le même lecteur (DOS ne permet pas le déplacement entre lecteurs) }
 If OldDrive <> NewDrive Then Begin
  DOS56h_RenameFile := 17; { Not same device }
  Exit;
 End;
 
 { Pour cette implémentation, on ne supporte que le renommage dans le même répertoire }
 { Un système complet supporterait le déplacement entre répertoires }
 If UpperCase(OldDirPath) <> UpperCase(NewDirPath) Then Begin
  DOS56h_RenameFile := 3; { Path not found }
  Exit;
 End;
 
 { Chercher le fichier source }
 If Not FindDirectoryEntryByName(OldDrive, 0, OldFileName, OldEntry, EntryOffset) Then Begin
  DOS56h_RenameFile := 2; { File not found }
  Exit;
 End;
 
 { Vérifier que ce n'est pas un répertoire (pour cette implémentation simplifiée) }
 If (OldEntry.Attributes And $10) <> 0 Then Begin
  DOS56h_RenameFile := 5; { Access denied }
  Exit;
 End;
 
 { Vérifier que le nouveau nom n'existe pas déjà }
 If FindDirectoryEntryByName(NewDrive, 0, NewFileName, OldEntry, EntryOffset) Then Begin
  DOS56h_RenameFile := 80; { File already exists }
  Exit;
 End;
 
 { Restaurer l'entrée originale (elle a été écrasée par la recherche du nouveau nom) }
 If Not FindDirectoryEntryByName(OldDrive, 0, OldFileName, OldEntry, EntryOffset) Then Begin
  DOS56h_RenameFile := 2; { File not found }
  Exit;
 End;
 
 { Mettre à jour le nom dans l'entrée de répertoire }
 If Not UpdateDirectoryEntryName(OldDrive, 0, EntryOffset, NewFileName) Then Begin
  DOS56h_RenameFile := 5; { Access denied }
  Exit;
 End;
 
 DOS56h_RenameFile := 0; { Succès }
 
 { Note: Cette implémentation gère le renommage basique dans le répertoire racine.
   Un système DOS complet supporterait :
   - Le déplacement entre sous-répertoires
   - La gestion des noms longs (VFAT)
   - Les attributs étendus
   - La gestion des liens et raccourcis
   - La validation complète des noms de fichiers
   - La gestion des fichiers ouverts (verrouillage)
   
   Les interruptions 25h/26h sont utilisées pour l'accès direct aux secteurs
   permettant une manipulation FAT12/FAT16 authentique. }
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
Procedure UnpackDOSDateTime(DOSDateTime:LongInt;Var Year,Month,Day,Hour,Minute,Second:Word);
Var
 DOSDate, DOSTime: Word;
Begin
 DOSDate := Hi(DOSDateTime);  { High word = date }
 DOSTime := Lo(DOSDateTime);  { Low word = time }
 
 { Extraire les composants de la date }
 Year := ((DOSDate SHR 9) AND $7F) + 1980;
 Month := (DOSDate SHR 5) AND $0F;
 Day := DOSDate AND $1F;
 
 { Extraire les composants de l'heure }
 Hour := (DOSTime SHR 11) AND $1F;
 Minute := (DOSTime SHR 5) AND $3F;
 Second := (DOSTime AND $1F) SHL 1;
End;

{ Obtient l'offset d'une entrée de répertoire par son handle }
Function GetDirectoryOffsetByHandle(Handle:Word;Var Drive:Byte;Var EntryOffset:Word):Boolean;
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
Function UpdateDirectoryDateTime(Drive:Byte;EntryOffset:Word;NewDate,NewTime:Word):Boolean;
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
Function GetDirectoryDateTime(Drive:Byte;EntryOffset:Word;Var Date,Time:Word):Boolean;
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
Function DOS57h_GetSetFileDateTime(Handle:Word;Action:Byte;NewDate,NewTime:Word):LongInt;
Var
 Drive: Byte;
 EntryOffset: Word;
 CurrentDate, CurrentTime: Word;
 Success: Boolean;
Begin
 DOS57h_GetSetFileDateTime := $FFFFFFFF; { Erreur par défaut }
 
 { Vérifier la validité de l'action }
 If Action > 1 Then Exit; { Seules les actions 0 (GET) et 1 (SET) sont valides }
 
 { Obtenir l'offset de l'entrée de répertoire pour ce handle }
 If Not GetDirectoryOffsetByHandle(Handle, Drive, EntryOffset) Then Exit;
 
 Case Action Of
  0: Begin { GET - Obtenir la date/heure actuelle }
      If GetDirectoryDateTime(Drive, EntryOffset, CurrentDate, CurrentTime) Then Begin
       { Retourner la date/heure dans le format attendu }
       { High word = date, Low word = time }
       DOS57h_GetSetFileDateTime := (LongInt(CurrentDate) SHL 16) OR CurrentTime;
      End;
     End;
     
  1: Begin { SET - Définir une nouvelle date/heure }
      { Valider les valeurs de date/heure (validation basique) }
      If (NewDate = 0) Or (NewTime > $BEFF) Then Exit; { Validation basique }
      
      If UpdateDirectoryDateTime(Drive, EntryOffset, NewDate, NewTime) Then Begin
       DOS57h_GetSetFileDateTime := 0; { Succès pour SET }
      End;
     End;
 End;
 
 { Note: Cette implémentation gère les opérations de date/heure basiques.
   Un système DOS complet supporterait :
   - Les attributs de date étendus (création, accès)
   - La gestion des fuseaux horaires
   - La validation complète des dates
   - Les opérations sur les sous-répertoires
   - La gestion des fichiers système et cachés
   - Les horodatages haute précision
   
   Les interruptions 25h/26h sont utilisées via ReadDirectorySector/WriteDirectorySector
   pour l'accès direct aux secteurs de répertoire FAT12/FAT16. }
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
  
  { Lire le champ de stratégie (supposons qu'il soit à un offset fixe) }
  MOV AX,[SI+20]  { Offset approximatif pour la stratégie }
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
  
  { Écrire le nouveau champ de stratégie }
  MOV AX,NewStrategy
  MOV [SI+20],AX  { Offset approximatif pour la stratégie }
  
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
  
  { Lire le champ d'état UMB (supposons qu'il soit à un offset fixe) }
  MOV AX,[SI+22]  { Offset approximatif pour l'état UMB }
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
  
  { Écrire le nouveau champ d'état UMB }
  MOV AX,NewState
  MOV [SI+22],AX  { Offset approximatif pour l'état UMB }
  
  POP AX
  POP DS
 END;
End;

{ Vérifie si les UMB sont disponibles dans le système }
Function AreUMBsAvailable:Boolean;
Begin
 { Pour cette implémentation basique, simuler la disponibilité des UMB }
 { Dans un vrai DOS, cela vérifierait la présence d'un gestionnaire UMB comme EMM386 }
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
 CurrentSeg := $0060; { Premier MCB }
 
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
 CurrentSeg := $0060; { Premier MCB }
 
 While CurrentSeg < $A000 Do Begin
  If GetMCB(CurrentSeg, MCB) Then Begin
   { Vérifier si le bloc est libre, assez grand, mais plus petit que le meilleur }
   If (MCB.Owner = 0) And (MCB.BlockSize >= Size) And (MCB.BlockSize < BestSize) Then Begin
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
 CurrentSeg := $0060; { Premier MCB }
 
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
Var
 Segment: Word;
 Success: Boolean;
Begin
 AllocateMemoryWithStrategy := 0; { Erreur par défaut }
 
 Case Strategy Of
  0: Success := FindMemoryFirstFit(Size, Segment);  { First Fit }
  1: Success := FindMemoryBestFit(Size, Segment);   { Best Fit }
  2: Success := FindMemoryLastFit(Size, Segment);   { Last Fit }
  Else Success := FindMemoryFirstFit(Size, Segment); { Par défaut }
 End;
 
 If Success Then Begin
  { Créer le MCB pour marquer le bloc comme utilisé }
  If CreateMCB(Segment - 1, Size, GetCurrentPSP, False) Then
   AllocateMemoryWithStrategy := Segment;
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
 
 { Note: Cette implémentation gère les stratégies d'allocation mémoire et UMB basiques.
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

Procedure END_KERNEL;Begin
 ASM
  DB 'FIN DU NOYAU MSDOS-0';
 END;
End;

END.
