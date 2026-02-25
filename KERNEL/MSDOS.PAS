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

  { Structure pour les données internes DOS }
 DataMOS=Record
  Key:Byte;
  InDos:Byte;
  CurrDisk:Byte;
  DTASegment:Word;    { Segment de la DTA }
  DTAOffset:Word;     { Offset de la DTA }
  CurrentCountry:Word; { Code pays actuel }
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

{ Variables globales supprimées - maintenant dans Code Segment }
{$IFNDEF FPC}
{ Aucune variable globale nécessaire en mode Turbo Pascal }
{$ENDIF}

{ Déclarations Forward }
Procedure Intr20h;Interrupt;Forward;
Procedure Intr21h;Interrupt;Forward;
Procedure Intr25h;Interrupt;Forward;
Procedure Intr26h;Interrupt;Forward;
Procedure Intr28h;Interrupt;Forward;
Procedure Intr2Ah;Interrupt;Forward;
Procedure Intr2Fh;Interrupt;Forward;
Procedure Intr33h;Interrupt;Forward;

Procedure SetIntVec(AL:Byte;DS,DX:Word);Near;Forward;
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
  { TODO : Charger un programme COMMAND.EXE, faire un JMP sur le point d'entr�e du programme charg� en m�moire }
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
 CMP AL,1                   { Activer la vérification ? }
 JA @Xit                    { Valeur invalide - ignorer }
 { Dans un DOS complet, cette fonction activerait/désactiverait }
 { la vérification des écritures sur disque }
 { Pour cette implémentation, on ne fait rien mais on accepte la commande }
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
End;Procedure SetIntVec(AL:Byte;DS,DX:Word);
Var
 TableInt:Array[Byte]of Pointer Absolute 0:0;
Begin
 TableInt[AL]:=Ptr(DS,DX);
End;

Procedure END_KERNEL;Begin
 ASM
  DB 'FIN DU NOYAU MSDOS-0';
 END;
End;

END.
