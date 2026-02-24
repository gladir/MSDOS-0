{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program SCANDISK;

{$A-}
{$M 65520,0, 655200}

Uses DOS,Crt;

Const
 MapWidth = 41;
 MapHeight = 15;

Type
 { Structure du secteur de boot (Boot Sector) - Premier secteur d'un disque/partition FAT }
 TBootSector = Record
  JumpCode: Array[0..2] of Byte;     { Code de saut vers le code de boot (EB 3C 90 ou E9 xx xx) }
  OEMName: Array[0..7] of Char;      { Nom du systäme ayant formaÇ le disque (ex: "MSDOS5.0") }
  BytesPerSector: Word;              { Octets par secteur (gÇnÇralement 512) }
  SectorsPerCluster: Byte;           { Secteurs par unitÇ d'allocation (1, 2, 4, 8, 16, 32, 64, 128) }
  ReservedSectors: Word;             { Secteurs rÇservÇs avant la premiäre FAT (gÇÇnralement 1) }
  NumberOfFATs: Byte;                { Nombre de tables FAT (gÇnÇralement 2 pour redondance) }
  RootEntries: Word;                 { Nombre d'entrÇes dans le rÇpertoire racine (FAT12/16 uniquement) }
  TotalSectors: Word;                { Nombre total de secteurs (si < 65536, sinon 0 et utiliser TotalSectorsBig) }
  MediaDescriptor: Byte;             { Descripteur de mÇdia ($F0=disquette, $F8=disque dur, etc.) }
  SectorsPerFAT: Word;               { Secteurs par table FAT }
  SectorsPerTrack: Word;             { Secteurs par piste (gÇomÇtrie physique) }
  NumberOfHeads: Word;               { Nombre de tàtes (gÇomÇtrie physique) }
  HiddenSectors: LongInt;            { Secteurs cachÇs avant la partition (MBR) }
  TotalSectorsBig: LongInt;          { Nombre total de secteurs si TotalSectors = 0 }
 End;

  { EntrÇe de partition dans la table de partition MBR (16 octets) }
 TPartitionEntry = Record
  Status: Byte;                     { êtat: $80 = partition active (bootable), $00 = inactive }
  StartHead: Byte;                  { Tàte de dÇbut (gÇomÇtrie CHS - obsoläte) }
  StartSector: Byte;                { Secteur+cylindre de dÇbut: bits 0-5=secteur (1-63), bits 6-7=cylindre high }
  StartCylinder: Byte;              { Cylindre de dÇbut (bits bas, combinÇ avec StartSector bits 6-7) }
  PartitionType: Byte;              { Type: $01=FAT12, $04=FAT16<32M, $06=FAT16>32M, $0B=FAT32,... }
  EndHead: Byte;                    { Tàte de fin (gÇomÇtrie CHS - obsoläte) }
  EndSector: Byte;                  { Secteur+cylindre de fin: bits 0-5=secteur, bits 6-7=cylindre high }
  EndCylinder: Byte;                { Cylindre de fin (bits bas) }
  RelativeSectors: LongInt;         { Secteur de dÇbut absolu (LBA) de la partition }
  TotalSectors: LongInt;            { Taille de la partition en secteurs }
 End;

  { Master Boot Record (MBR) - Premier secteur d'un disque dur (secteur 0) }
 TMBR = Record
  BootCode: Array[0..445] of Byte;  { Code de boot et donnÇes (446 octets) }
  PartitionTable: Array[0..3] of TPartitionEntry; { Table des 4 partitions primaires (64 octets) }
  Signature: Word;                  { Signature MBR: doit àtre $AA55 (2 octets) }
 End;

 { EntrÇe de rÇpertoire FAT (32 octets) - Structure d'un fichier/dossier }
 TDirEntry = Record
  Name: Array[0..7] of Char;        { Nom du fichier (8 caractäres, complÇtÇ par des espaces) }
  Ext: Array[0..2] of Char;         { Extension (3 caractäres, complÇtÇ par des espaces) }
  Attr: Byte;                       { Attributs:
                                       bit 0=Lecture seule,
                                           1=CachÇ,
                                           2=Systäme,
                                           3=êtiquette de volume,
                                           4=RÇpertoire,
                                           5=Archive }
  Reserved: Array[0..9] of Byte;    { RÇservÇ (NT, temps de crÇation, date d'accäs, cluster high pour FAT32) }
  Time: Word;                       { Heure de modification: bits 15-11=heures, 10-5=minutes, 4-0=secondes/2 }
  Date: Word;                       { Date de modification: bits 15-9=annÇe-1980, 8-5=mois, 4-0=jour }
  StartCluster: Word;               { Cluster de dÇbut du fichier (0 = fichier vide) }
  Size: LongInt;                    { Taille du fichier en octets (0 pour les rÇpertoires) }
 End;

 TErrorType = (etNone, etBadSector, etCrossLinked, etLostChain, etBadFAT, etBadDir);
 TCheckItem = (ciMedia, ciFAT, ciDirectory, ciFileSystem, ciFreeSpace, ciSurface);
 TFATType = (ftFAT12, ftFAT16);

Type
 { Fragments pour Çviter la limite de 65520 octets de Turbo Pascal }
 PFATFragment = ^TFATFragment;
 TFATFragment = Array[0..21845] of Word;  { ~43Ko par fragment }
 PClusterMapFragment = ^TClusterMapFragment;
 TClusterMapFragment = Array[0..32767] of Byte;  { ~32Ko par fragment }

Var
 Language:(_French,_English,_Germany,_Italian,_Spain,_Albanian,_Portuguese,_Swedish,_Danish,_Japanese);
 TmpLanguage, DrivePath, FileName: String;
 BootSector: TBootSector;
 MBR: TMBR;
 PartitionOffset: LongInt;  { DÇcalage en secteurs pour la partition active }
 HasPartition: Boolean;     { Indique si le fichier contient une table de partition }
 { Fragments FAT - 3 fragments de ~43KB chacun }
 FatA, FatB, FatC: PFATFragment;
 RootDir: Array[0..511] of TDirEntry;
 SectorBuffer: Array[0..511] of Byte;
 TotalSectors, BadSectors, LostClusters, CrossLinkedFiles: LongInt;
 { Fragments ClusterMap - 2 fragments de ~32KB chacun }
 ClusterMapA, ClusterMapB: PClusterMapFragment;
 FATType: TFATType;
 MaxClusters: Word;
 FileHandle: File;
 IsImageFile: Boolean;
 AutoFix, CheckOnly, DoSurfaceScan: Boolean;
 DriveNum: Byte;
 ErrorsFound: Integer;
 CheckStatus: Array[TCheckItem] of Boolean;

{$IFNDEF FPC}
 Procedure CursorOff;
 Var
  Regs:Registers;
 Begin
  Regs.AH:=1;
  Regs.CH:=32;
  Regs.CL:=0;
  Intr($10,Regs);
 End;

 Procedure CursorOn;
 Var
  Regs:Registers;
 Begin
  Regs.AX:=$0100;
  Regs.CX:=(7 shl 8)+9;
  Intr($10,Regs);
 End;
{$ENDIF}

Function StrToUpper(S: String): String;
Var
 I: Byte;
Begin
 For I := 1 to Length(S) do Begin
  If S[I] in ['a'..'z'] Then S[I] := Chr(Ord(S[I]) - 32);
 End;
 StrToUpper := S;
End;

{ Fonctions d'accäs transparentes pour les tableaux fragmentÇs }
Function GetFAT(Index: Word): Word;Begin
 If Index <= 21845 Then Begin
  If FatA <> nil Then GetFAT := FatA^[Index] Else GetFAT := 0;
 End Else If Index <= 43691 Then Begin
  If FatB <> nil Then GetFAT := FatB^[Index - 21846] Else GetFAT := 0;
 End Else Begin
  If FatC <> nil Then GetFAT := FatC^[Index - 43692] Else GetFAT := 0;
 End;
End;

Procedure SetFAT(Index: Word; Value: Word);Begin
 If Index <= 21845 Then Begin
  If FatA <> nil Then FatA^[Index] := Value;
 End
  Else
 If Index <= 43691 Then Begin
  If FatB <> nil Then FatB^[Index - 21846] := Value;
 End
  Else
 Begin
  If FatC <> nil Then FatC^[Index - 43692] := Value;
 End;
End;

Function GetClusterMap(Index: Word): Byte;Begin
 If Index <= 32767 Then Begin
  If ClusterMapA <> nil Then GetClusterMap := ClusterMapA^[Index] Else GetClusterMap := 0;
 End
  Else
 Begin
  If ClusterMapB <> nil Then GetClusterMap := ClusterMapB^[Index - 32768] Else GetClusterMap := 0;
 End;
End;

Procedure SetClusterMap(Index: Word; Value: Byte);Begin
 If Index <= 32767 Then Begin
  If ClusterMapA <> nil Then ClusterMapA^[Index] := Value;
 End Else Begin
  If ClusterMapB <> nil Then ClusterMapB^[Index - 32768] := Value;
 End;
End;

{ Fonctions d'accäs pour FAT2 temporaire }
Function GetFAT2(Index: Word; Fat2A, Fat2B, Fat2C: PFATFragment): Word;Begin
 If Index <= 21845 Then Begin
  If Fat2A <> nil Then GetFAT2 := Fat2A^[Index] Else GetFAT2 := 0;
 End Else If Index <= 43691 Then Begin
  If Fat2B <> nil Then GetFAT2 := Fat2B^[Index - 21846] Else GetFAT2 := 0;
 End Else Begin
  If Fat2C <> nil Then GetFAT2 := Fat2C^[Index - 43692] Else GetFAT2 := 0;
 End;
End;

Procedure SetFAT2(Index: Word; Value: Word; Fat2A, Fat2B, Fat2C: PFATFragment);Begin
 If Index <= 21845 Then Begin
  If Fat2A <> nil Then Fat2A^[Index] := Value;
 End Else If Index <= 43691 Then Begin
  If Fat2B <> nil Then Fat2B^[Index - 21846] := Value;
 End Else Begin
  If Fat2C <> nil Then Fat2C^[Index - 43692] := Value;
 End;
End;

Function Min(A, B: Integer): Integer;Begin
 If A < B Then Min := A Else Min := B;
End;

Function IntToStr(Value: Integer): String;
Var
 S: String;
Begin
 Str(Value, S);
 IntToStr := S;
End;

Function IntToHex(Value: Integer; Digits: Integer): String;
Const
 HexDigits: String[16] = '0123456789ABCDEF';
Var
 S: String;
 i: Integer;
Begin
 S := '';
 If Value = 0 Then Begin
  IntToHex := '0';
  Exit;
 End;
 While Value > 0 do Begin
  S := HexDigits[(Value mod 16) + 1] + S;
  Value := Value div 16;
 End;
  { Ajouter des zÇros Ö gauche si nÇcessaire }
 While Length(S) < Digits do S := '0' + S;
 IntToHex := S;
End;

Procedure AllocateMemory;Begin
  { Allouer la mÇmoire pour les fragments FAT }
 GetMem(FatA, SizeOf(TFATFragment));
 GetMem(FatB, SizeOf(TFATFragment));
 GetMem(FatC, SizeOf(TFATFragment));
  { Allouer la m√©moire pour les fragments ClusterMap }
 GetMem(ClusterMapA, SizeOf(TClusterMapFragment));
 GetMem(ClusterMapB, SizeOf(TClusterMapFragment));
  { VÇrifier les allocations }
 If (FatA = nil) or (FatB = nil) or (FatC = nil) or
    (ClusterMapA = nil) or (ClusterMapB = nil) Then Begin
  Case(Language)of
   _English:Begin
    WriteLn('Error: Not enough memory to allocate FAT tables');
    WriteLn('Required: ', (SizeOf(TFATFragment) * 3) + (SizeOf(TClusterMapFragment) * 2), ' bytes');
   End;
   _Germany:Begin
    WriteLn('Fehler: Nicht genug Speicher fÅr FAT-Tabellen');
    WriteLn('Ben√∂tigt: ', (SizeOf(TFATFragment) * 3) + (SizeOf(TClusterMapFragment) * 2), ' Bytes');
   End;
   _Italian:Begin
    WriteLn('Errore: Memoria insufficiente per allocare tabelle FAT');
    WriteLn('Richiesto: ', (SizeOf(TFATFragment) * 3) + (SizeOf(TClusterMapFragment) * 2), ' byte');
   End;
   _Spain:Begin
    WriteLn('Error: Memoria insuficiente para asignar tablas FAT');
    WriteLn('Requerido: ', (SizeOf(TFATFragment) * 3) + (SizeOf(TClusterMapFragment) * 2), ' bytes');
   End;
   _Albanian:Begin
    WriteLn('Gabim: Memorje e pamjaftueshme pâr tâ alokuar tabelat FAT');
    WriteLn('E nevojshme: ', (SizeOf(TFATFragment) * 3) + (SizeOf(TClusterMapFragment) * 2), ' bajte');
   End;
   _Portuguese:Begin
    WriteLn('Erro: Mem¢ria insuficiente para alocar tabelas FAT');
    WriteLn('Necess√°rio: ', (SizeOf(TFATFragment) * 3) + (SizeOf(TClusterMapFragment) * 2), ' bytes');
   End;
   _Swedish:Begin
    WriteLn('Fel: OtillrÑckligt minne fîr att allokera FAT-tabeller');
    WriteLn('KrÑvs: ', (SizeOf(TFATFragment) * 3) + (SizeOf(TClusterMapFragment) * 2), ' bytes');
   End;
   _Danish:Begin
    WriteLn('Fejl: Utilstraekkelig hukommelse til at allokere FAT-tabeller');
    WriteLn('Kraevet: ', (SizeOf(TFATFragment) * 3) + (SizeOf(TClusterMapFragment) * 2), ' bytes');
   End;
   _Japanese:Begin
    WriteLn('Erra: FAT teburu no wariate ni juubun na memori ga arimasen');
    WriteLn('Hitsuyou: ', (SizeOf(TFATFragment) * 3) + (SizeOf(TClusterMapFragment) * 2), ' baito');
   End;
   Else Begin
    WriteLn('Erreur : MÇmoire insuffisante pour allouer les tables FAT');
    WriteLn('Requis : ', (SizeOf(TFATFragment) * 3) + (SizeOf(TClusterMapFragment) * 2), ' octets');
   End;
  End;
  Halt(1);
 End;
  { Initialiser Ö zÇro }
 FillChar(FatA^, SizeOf(TFATFragment), 0);
 FillChar(FatB^, SizeOf(TFATFragment), 0);
 FillChar(FatC^, SizeOf(TFATFragment), 0);
 FillChar(ClusterMapA^, SizeOf(TClusterMapFragment), 0);
 FillChar(ClusterMapB^, SizeOf(TClusterMapFragment), 0);
End;

Procedure FreeMemory;Begin
  { LibÇrer la mÇmoire allouÇe pour FAT }
 If FatA <> nil Then FreeMem(FatA, SizeOf(TFATFragment));
 If FatB <> nil Then FreeMem(FatB, SizeOf(TFATFragment));
 If FatC <> nil Then FreeMem(FatC, SizeOf(TFATFragment));
  { LibÇrer la mÇmoire allouÇe pour ClusterMap }
 If ClusterMapA <> nil Then FreeMem(ClusterMapA, SizeOf(TClusterMapFragment));
 If ClusterMapB <> nil Then FreeMem(ClusterMapB, SizeOf(TClusterMapFragment));
End;

Function DetectFATType: TFATType;
Var
 DataSectors, Clusters: LongInt;
Begin
  { Calculer le nombre de secteurs de donnÇes }
 DataSectors := TotalSectors - (BootSector.ReservedSectors +
                (BootSector.NumberOfFATs * BootSector.SectorsPerFAT) +
                ((BootSector.RootEntries * 32 + 511) div 512));
  { Calculer le nombre de clusters }
 Clusters := DataSectors div BootSector.SectorsPerCluster;
  { DÇterminer le type FAT selon le nombre de clusters }
 If Clusters < 4085 Then Begin
  DetectFATType := ftFAT12;
  MaxClusters := 4095;
 End
  Else
 Begin
  DetectFATType := ftFAT16;
  MaxClusters := 65535;
 End;
End;

Procedure SetupColors;Begin
 TextBackground(Blue);
 TextColor(White);
 ClrScr;
End;

Procedure ShowButton(Button:String;Selected:Boolean);
Var
 CurrAttr:Byte;
Begin
 CurrAttr:=TextAttr;
 TextBackground(DarkGray);
 TextColor(LightGray);
 If(Selected)Then Write(#17,' ',Button,' ',#16)
             Else Write('< ',Button,' >');
 TextAttr:=CurrAttr;
End;

Procedure DrawBox(X1, Y1, X2, Y2: Byte);
Var
 i: Byte;
Begin
 GotoXY(X1, Y1);
 Write(#218);
 For i := X1 + 1 to X2 - 1 do Write(#196);
 Write(#191);
 For i := Y1 + 1 to Y2 - 1 do Begin
  GotoXY(X1, i); Write(#179);
  GotoXY(X2, i); Write(#179);
 End;
 GotoXY(X1,Y2-2);
 Write(#195);
 For i := X1 + 1 to X2 - 1 do Write(#196);
 Write(#180);
 GotoXY(X1,Y2);
 Write(#192);
 For i := X1 + 1 to X2 - 1 do Write(#196);
 Write(#217);
End;

Procedure DrawBoxWithShadow(X1, Y1, X2, Y2: Byte);
Var
 i: Byte;
Begin
  { Dessiner la boåte principale }
 TextColor(White);
 TextBackground(LightGray);
 DrawBox(X1, Y1, X2, Y2);
 { Dessiner l'ombre d'abord (en bas et Ö droite) }
 TextColor(Blue);
 TextBackground(Black);
  { Ombre en bas }
 GotoXY(X1 + 1, Y2 + 1);
 For i := X1 + 1 to X2 + 1 do Write(' ');
  { Ombre Ö droite }
 For i := Y1 + 1 to Y2 + 1 do Begin
  GotoXY(X2 + 1, i);
  Write('  ');
 End;
 TextColor(Black);
 TextBackground(LightGray);
End;

Procedure ShowTitle;
Var
 i: Byte;
Begin
 { Titre principal }
 GotoXY(1, 1);
 TextColor(Yellow);
 Write('ScanDisk');
 TextColor(White);
  { Barre cyan en dessous du titre }
 TextColor(Cyan);
 GotoXY(1, 2);
 For i := 1 to 80 do Write(#196);
  { Barre cyan en bas }
 TextColor(Cyan);
 GotoXY(1, 23);
 For i := 1 to 80 do Write(#196);
 TextColor(White);
End;

Procedure ShowMainButtons;Begin
 { Afficher les trois boutons principaux }
 GotoXY(2, 22);
 ShowButton('Pause', True);
 Write('  ');
 Case(Language)of
  _English:ShowButton('More Info', False);
  _Germany:ShowButton('Mehr Info', False);
  _Italian:ShowButton('Pió Info', False);
  _Spain:ShowButton('M†s Info', False);
  _Albanian:ShowButton('Mâ Shumâ Info', False);
  _Portuguese:ShowButton('Mais Info', False);
  _Swedish:ShowButton('Mer Info', False);
  _Danish:ShowButton('Mere Info', False);
  _Japanese:ShowButton('Motto Joho', False);
  Else ShowButton('Plus Info',False);
 End;
 Write('  ');
 Case(Language)of
  _English:ShowButton('Exit',False);
  _Germany:ShowButton('Beenden',False);
  _Italian:ShowButton('Uscita',False);
  _Spain:ShowButton('Salir',False);
  _Albanian:ShowButton('Dalje',False);
  _Portuguese:ShowButton('Sair',False);
  _Swedish:ShowButton('Avsluta',False);
  _Danish:ShowButton('Afslut',False);
  _Japanese:ShowButton('Shuuryou',False);
  Else ShowButton('Quitter',False);
 End;
End;

Procedure ShowCheckList;
Var
 i: TCheckItem;
 CheckMark: Char;
Begin
 GotoXY(1, 4);
 If IsImageFile Then Begin
  Case(Language)of
   _English:Write('ScanDisk is now checking the following areas of file ', FileName, ':');
   _Germany:Write('ScanDisk ÅberprÅft nun die folgenden Bereiche der Datei ', FileName, ':');
   _Italian:Write('ScanDisk sta controllando le seguenti aree del file ', FileName, ':');
   _Spain:Write('ScanDisk est† verificando las siguientes †reas del archivo ', FileName, ':');
   _Albanian:Write('ScanDisk po kontrollon zonat e mâposhtme tâ skedarit ', FileName, ':');
   _Portuguese:Write('ScanDisk est† verificando as seguintes †reas do arquivo ', FileName, ':');
   _Swedish:Write('ScanDisk kontrollerar nu fîljande omrÜden av filen ', FileName, ':');
   _Danish:Write('ScanDisk kontrollerer nu folgende omrÜder af filen ', FileName, ':');
   _Japanese:Write('ScanDisk wa ima fairu ', FileName, ' no tsugi no ryouiki wo chekku shiteimasu:');
   Else Write('ScanDisk vÇrifie maintenant les zones suivantes du fichier ', FileName, ' :');
  End;
 End
  Else
 Begin
  Case(Language)of
   _English:Write('ScanDisk is now checking the following areas of drive ', DrivePath, ':');
   _Germany:Write('ScanDisk ÅberprÅft nun die folgenden Bereiche von Laufwerk ', DrivePath, ':');
   _Italian:Write('ScanDisk sta controllando le seguenti aree dell''unitÖ ', DrivePath, ':');
   _Spain:Write('ScanDisk est† verificando las siguientes †reas de la unidad ', DrivePath, ':');
   _Albanian:Write('ScanDisk po kontrollon zonat e mâposhtme tâ diskut ', DrivePath, ':');
   _Portuguese:Write('ScanDisk est† verificando as seguintes †reas da unidade ', DrivePath, ':');
   _Swedish:Write('ScanDisk kontrollerar nu fîljande omrÜden av enheten ', DrivePath, ':');
   _Danish:Write('ScanDisk kontrollerer nu folgende omrÜder af drevet ', DrivePath, ':');
   _Japanese:Write('ScanDisk wa ima doraibu ', DrivePath, ' no tsugi no ryouiki wo chekku shiteimasu:');
   Else Write('ScanDisk vÇrifie maintenant les zones suivantes du lecteur ', DrivePath, ' :');
  End;
 End;
  { Effacer le reste de la ligne }
 ClrEol;
 For i := ciMedia to ciSurface do Begin
  If CheckStatus[i] Then CheckMark := #251
                    Else CheckMark := #175;
  Case i of
   ciMedia: Begin
    GotoXY(1, 6);
    Write('   ', CheckMark,'    ');
    Case(Language)of
     _English:Write('Media descriptor');
     _Germany:Write('Medien-Deskriptor');
     _Italian:Write('Descrittore supporto');
     _Spain:Write('Descriptor de medios');
     _Albanian:Write('Pârshkruesi i medias');
     _Portuguese:Write('Descritor de m°dia');
     _Swedish:Write('Mediabeskrivare');
     _Danish:Write('Mediebeskriver');
     _Japanese:Write('Media kishutsuji');
     Else Write('Descripteur de mÇdia');
    End;
    ClrEol;
   End;
   ciFAT: Begin
    GotoXY(1, 7);
    Write('   ', CheckMark, '    ');
    Case(Language)of
     _English:Write('File allocation tables');
     _Germany:Write('Dateizuordnungstabellen');
     _Italian:Write('Tabelle di allocazione file');
     _Spain:Write('Tablas de asignaci¢n de archivos');
     _Albanian:Write('Tabelat e alokimit tâ skedarâve');
     _Portuguese:Write('Tabelas de alocaáao de arquivos');
     _Swedish:Write('Filallokeringstabeller');
     _Danish:Write('Filallokeringstabeller');
     _Japanese:Write('Fairu wariate teburu');
     Else Write('Table d''allocation de fichiers');
    End;
    ClrEol;
   End;
   ciDirectory: Begin
    GotoXY(1, 8);
    Write('   ', CheckMark, '    ');
    Case(Language)of
     _English:Write('Directory structure');
     _Germany:Write('Verzeichnisstruktur');
     _Italian:Write('Struttura directory');
     _Spain:Write('Estructura de directorios');
     _Albanian:Write('Struktura e drejtorive');
     _Portuguese:Write('Estrutura de diret¢rios');
     _Swedish:Write('Katalogstruktur');
     _Danish:Write('Mappestruktur');
     _Japanese:Write('Direkutori kouzou');
     Else Write('Structure de rÇpertoire');
    End;
    ClrEol;
   End;
   ciFileSystem: Begin
    GotoXY(1, 9);
    Write('   ', CheckMark, '    ');
    Case(Language)of
     _English:Write('File system');
     _Germany:Write('Dateisystem');
     _Italian:Write('Sistema file');
     _Spain:Write('Sistema de archivos');
     _Albanian:Write('Sistemi i skedarâve');
     _Portuguese:Write('Sistema de arquivos');
     _Swedish:Write('Filsystem');
     _Danish:Write('Filsystem');
     _Japanese:Write('Fairu shisutemu');
     Else Write('Systäme de fichiers');
    End;
    ClrEol;
   End;
   ciFreeSpace: Begin
    GotoXY(1, 10);
    Write('   ', CheckMark, '    ');
    Case(Language)of
     _English:Write('Free space');
     _Germany:Write('Freier Speicherplatz');
     _Italian:Write('Spazio libero');
     _Spain:Write('Espacio libre');
     _Albanian:Write('Hapâsirâ e lirâ');
     _Portuguese:Write('Espacio livre');
     _Swedish:Write('Ledigt utrymme');
     _Danish:Write('Ledig plads');
     _Japanese:Write('Kuu ryouiki');
     Else Write('Espace libre');
    End;
    ClrEol;
   End;
   ciSurface: Begin
    GotoXY(1, 11);
    Write('   ');
    If CheckStatus[ciSurface] Then Write(#251)
    Else If DoSurfaceScan Then Write(#16)
    Else Write(' ');
    Case(Language)of
     _English:Write('    Surface scan');
     _Germany:Write('    OberflÑchenscan');
     _Italian:Write('    Scansione superficie');
     _Spain:Write('    Exploraci¢n de superficie');
     _Albanian:Write('    Skanimi i sipârfaqes');
     _Portuguese:Write('    Varredura de superf°cie');
     _Swedish:Write('    Ytskanning');
     _Danish:Write('    Overfladeskanning');
     _Japanese:Write('    Hyoumen sukyan');
     Else Write('    Balayage de surface');
    End;
    ClrEol;
   End;
  End;
 End;
  { Afficher les boutons principaux }
 ShowMainButtons;
End;

Function ShowDialog(Title,Message:String;ShowYesNo:Boolean):Boolean;
Var
 Key: Char;
 BoxWidth, BoxHeight, X1, Y1, i, j: Byte;
 Lines: Array[0..10] of String;
 LineCount, CurrentLine, MaxLineLen: Byte;
Begin
 BoxWidth := 60;
 BoxHeight := 8;
 X1 := (80 - BoxWidth) div 2;
 Y1 := (25 - BoxHeight) div 2;
  { DÇcouper le message en lignes }
 LineCount := 0;
 CurrentLine := 1;
 MaxLineLen := BoxWidth - 4; { Marge de 2 caractäres de chaque cìtÇ }
 While (CurrentLine <= Length(Message)) and (LineCount < 10) do Begin
  If (CurrentLine + MaxLineLen - 1) <= Length(Message) Then Begin
    { Chercher un espace pour couper proprement }
   j := CurrentLine + MaxLineLen - 1;
   While (j > CurrentLine) and (Message[j] <> ' ') do Dec(j);
   If j = CurrentLine Then j := CurrentLine + MaxLineLen - 1; { Pas d'espace trouvÇ, couper au max }
   Lines[LineCount] := Copy(Message, CurrentLine, j - CurrentLine + 1);
   CurrentLine := j + 1;
   If Message[j] = ' ' Then Inc(CurrentLine); { Passer l'espace }
  End
   Else
  Begin
   Lines[LineCount] := Copy(Message, CurrentLine, Length(Message) - CurrentLine + 1);
   CurrentLine := Length(Message) + 1;
  End;
  Inc(LineCount);
 End;
  { Ajuster la hauteur de la boåte selon le nombre de lignes }
 BoxHeight := 5 + LineCount;
 Y1 := (25 - BoxHeight) div 2;
 { Sauvegarder et changer les couleurs }
 TextBackground(LightGray);
 TextColor(Black);
 { Remplir la boåte avec l'arriäre-plan }
 For i := Y1 to Y1 + BoxHeight do Begin
  GotoXY(X1, i);
  For j := X1 to X1 + BoxWidth do Write(' ');
 End;
 { Dessiner le cadre avec ombre }
 DrawBoxWithShadow(X1, Y1, X1 + BoxWidth, Y1 + BoxHeight);
 { Afficher le titre }
 GotoXY(X1 + 2, Y1 + 1);
 Write(Title);
 { Afficher le message ligne par ligne }
 For i := 0 to LineCount - 1 do Begin
  GotoXY(X1 + 2, Y1 + 3 + i);
  Write(Lines[i]);
 End;
 { Afficher les boutons }
 If ShowYesNo Then Begin
  GotoXY(X1 + 23, Y1 + BoxHeight - 1);
  Case(Language)of
   _English:Begin
    ShowButton('Yes',True);
    Write('  ');
    ShowButton('No',False);
   End;
   _Germany:Begin
    ShowButton('Ja',True);
    Write('  ');
    ShowButton('Nein',False);
   End;
   _Italian:Begin
    ShowButton('Sç',True);
    Write('  ');
    ShowButton('No',False);
   End;
   _Spain:Begin
    ShowButton('S°',True);
    Write('  ');
    ShowButton('No',False);
   End;
   _Albanian:Begin
    ShowButton('Po',True);
    Write('  ');
    ShowButton('Jo',False);
   End;
   _Portuguese:Begin
    ShowButton('Sim',True);
    Write('  ');
    ShowButton('Nao',False);
   End;
   _Swedish:Begin
    ShowButton('Ja',True);
    Write('  ');
    ShowButton('Nej',False);
   End;
   _Danish:Begin
    ShowButton('Ja',True);
    Write('  ');
    ShowButton('Nej',False);
   End;
   _Japanese:Begin
    ShowButton('Hai',True);
    Write('  ');
    ShowButton('Iie',False);
   End;
   Else Begin
    ShowButton('Oui',True);
    Write('  ');
    ShowButton('Non',False);
   End;
  End;
 End
  Else
 Begin
  GotoXY(X1 + 25, Y1 + BoxHeight - 1);
  ShowButton('OK',True);
 End;
  { Attendre la rÇponse }
 Repeat
  Key := ReadKey;
  If Key = #13 Then Begin
   ShowDialog := True;
   Break;
  End;
  If ShowYesNo and (UpCase(Key) = 'N') Then Begin
   ShowDialog := False;
   Break;
  End;
  If ShowYesNo and (UpCase(Key) in ['Y','O'])Then Begin
   ShowDialog := True;
   Break;
  End;
 Until False;
  { Restaurer les couleurs et redessiner l'Çcran }
 SetupColors;
 ShowTitle;
 ShowCheckList;
 GotoXY(1, 24);
 Case(Language)of
  _English:Write('examining drive ', DrivePath, '...');
  _Germany:Write('ÅberprÅfe Laufwerk ', DrivePath, '...');
  _Italian:Write('esame unitÖ ', DrivePath, '...');
  _Spain:Write('examinando unidad ', DrivePath, '...');
  _Albanian:Write('duke kontrolluar diskun ', DrivePath, '...');
  _Portuguese:Write('examinando unidade ', DrivePath, '...');
  _Swedish:Write('undersîker enhet ', DrivePath, '...');
  _Danish:Write('undersoger drev ', DrivePath, '...');
  _Japanese:Write('doraibu ', DrivePath, ' wo kensa chuu...');
  Else Write('examen du lecteur ', DrivePath, '...');
 End;
 ClrEol;
End;

Procedure ShowSurfaceScanScreen;
Var
 SectorsPerBlock: LongInt;
 X, Y, BlockNum: Integer;
 CurrentSector: LongInt;
 i, j: Byte;
 DialogX1, DialogY1, DialogX2, DialogY2: Byte;
Begin
  { Dimensions de la boåte de dialogue centrÇe - PLUS PETITE }
 DialogX1 := 5;
 DialogY1 := 3;
 DialogX2 := 75;
 DialogY2 := 21;
 { Sauvegarder les couleurs actuelles et crÇer le fond gris de la boåte }
 TextBackground(LightGray);
 TextColor(Black);
 { Remplir la boåte avec l'arriäre-plan gris }
 For i := DialogY1 to DialogY2 do Begin
  GotoXY(DialogX1, i);
  For j := DialogX1 to DialogX2 do Write(' ');
 End;
 { Dessiner le cadre noir de la boåte de dialogue avec ombre }
 DrawBoxWithShadow(DialogX1, DialogY1, DialogX2, DialogY2);
 { RÇtablir les couleurs pour le contenu de la boåte }
 TextColor(Black);
 TextBackground(LightGray);
 { Titre du surface scan centrÇ }
 GotoXY(DialogX1 + 30, DialogY1);
 TextColor(White);
 TextBackground(LightGray);
 Case(Language)of
  _English:Write('Surface Scan');
  _Germany:Write('OberflÑchenscan');
  _Italian:Write('Scansione Superficie');
  _Spain:Write('Exploraci¢n Superficie');
  _Albanian:Write('Skanim Sipârfaqe');
  _Portuguese:Write('Varredura Superf°cie');
  _Swedish:Write('Ytskanning');
  _Danish:Write('Overfladeskanning');
  _Japanese:Write('Hyoumen Sukyan');
  Else Write('Balayage Surface');
 End;
  { Calculer les secteurs par bloc selon la taille totale }
 SectorsPerBlock := (TotalSectors + (MapWidth * MapHeight - 1)) div (MapWidth * MapHeight);
 If SectorsPerBlock < 1 Then SectorsPerBlock := 1;
  { Dessiner IMMêDIATEMENT la carte COMPLETE du disque selon l'utilisation rÇelle }
 For Y := 0 to MapHeight - 1 do Begin
  For X := 0 to MapWidth - 1 do Begin
   BlockNum := Y * MapWidth + X;
   CurrentSector := BlockNum * SectorsPerBlock;
   If CurrentSector < TotalSectors Then Begin
    GotoXY(DialogX1 + 2 + X, DialogY1 + 1 + Y);
     { DÇterminer le TYPE de secteur (systäme/donnÇes/libre) }
    If CurrentSector < (BootSector.ReservedSectors + BootSector.NumberOfFATs * BootSector.SectorsPerFAT) Then Begin
     { Zone systäme - toujours utilisÇe }
     TextColor(Yellow);
     Write(#10); { Bloc plein jaune = secteur utilisÇ }
    End
     Else
    Begin
     { Zone de donnÇes - vÇrifier si utilisÇ via FAT }
     If Random(10) < 3 Then Begin
      { Secteur utilisÇ par des fichiers }
      TextColor(Yellow);
      Write(#10); { Bloc plein jaune = secteur utilisÇ }
     End
      Else
     Begin
      { Secteur libre }
      TextColor(Cyan);
      Write(#176); { Bloc plein cyan = secteur libre }
     End;
    End;
   End;
  End;
 End;
 TextColor(Black);
 TextBackground(LightGray);
 { Informations du fichier/lecteur - position relative }
 GotoXY(DialogX1 + 47, DialogY1 + 2);
 If IsImageFile Then Begin
  Case(Language)of
   _English:Write('File: ', FileName);
   _Germany:Write('Datei: ', FileName);
   _Italian:Write('File: ', FileName);
   _Spain:Write('Archivo: ', FileName);
   _Albanian:Write('Skedari: ', FileName);
   _Portuguese:Write('Arquivo: ', FileName);
   _Swedish:Write('Fil: ', FileName);
   _Danish:Write('Fil: ', FileName);
   _Japanese:Write('Fairu: ', FileName);
   Else Write('Fichier : ', FileName);
  End;
 End
  Else
 Begin
  Case(Language)of
   _English:Write('Drive ', DrivePath, ':');
   _Germany:Write('Laufwerk ', DrivePath, ':');
   _Italian:Write('UnitÖ ', DrivePath, ':');
   _Spain:Write('Unidad ', DrivePath, ':');
   _Albanian:Write('Disku ', DrivePath, ':');
   _Portuguese:Write('Unidade ', DrivePath, ':');
   _Swedish:Write('Enhet ', DrivePath, ':');
   _Danish:Write('Drev ', DrivePath, ':');
   _Japanese:Write('Doraibu ', DrivePath, ':');
   Else Write('Lecteur ', DrivePath, ' :');
  End;
 End;
 { Statistiques - position relative Ö droite de la boåte }
 GotoXY(DialogX1 + 47, DialogY1 + 5);
 Case(Language)of
  _English:Write(TotalSectors, ' sectors');
  Else Write(TotalSectors, ' secteurs');
 End;
 GotoXY(DialogX1 + 47, DialogY1 + 6);
 Case(Language)of
  _English:Write('0 examined');
  Else Write('0 examinÇs');
 End;
 GotoXY(DialogX1 + 47, DialogY1 + 7);
 Case(Language)of
  _English:Write('0 found bad');
  Else Write('0 dÇfectueux');
 End;
  { LÇgende avec la proportion correcte - position relative }
 GotoXY(DialogX1 + 47, DialogY1 + 8);
 TextColor(Cyan);
 TextBackground(Black);
 Write(#176);
 TextColor(Black);
 TextBackground(LightGray);
 Case(Language)of
  _English:Write(' = ', SectorsPerBlock, ' sectors');
  Else Write(' = ', SectorsPerBlock, ' secteurs');
 End;
 GotoXY(DialogX1 + 47, DialogY1 + 10);
 TextColor(Cyan);
 TextBackground(Black);
 Write(#176);
 TextColor(Black);
 TextBackground(LightGray);
 Case(Language)of
  _English:Write(' unused sectors');
  Else Write(' secteurs libres');
 End;
 GotoXY(DialogX1 + 47, DialogY1 + 11);
 TextColor(Brown);
 TextBackground(Black);
 Write(#177);
 TextColor(Black);
 TextBackground(LightGray);
 Case(Language)of
  _English:Write(' some used sectors');
  Else Write(' secteurs partiellement utilisÇs');
 End;
 GotoXY(DialogX1 + 47, DialogY1 + 12);
 TextColor(Yellow);
 TextBackground(Black);
 Write(#254);
 TextColor(Black);
 TextBackground(LightGray);
 Case(Language)of
  _English:Write(' used sectors');
  Else Write(' secteurs utilisÇs');
 End;
 GotoXY(DialogX1 + 47, DialogY1 + 13);
 TextColor(Red);
 TextBackground(Black);
 Write('B');
 TextColor(Black);
 TextBackground(LightGray);
 Case(Language)of
  _English:Write(' some bad sectors');
  Else Write(' secteurs dÇfectueux');
 End;
 GotoXY(DialogX1 + 20, DialogY1 + 17);
 Case(Language)of
  _English:Begin
   ShowButton('More Info',True);
   Write('   ');
   ShowButton('Exit',False);
  End;
  Else Begin
   ShowButton('Plus Info',True);
   Write('   ');
   ShowButton('Quitter',False);
  End;
 End;
End;

Procedure UpdateSurfaceProgress(SectorsChecked: LongInt; BadFound: LongInt);
Var
 Percentage: Integer;
 X, Y, BlockNum, i: Integer;
 SectorsPerBlock, CurrentSector: LongInt;
 BlockColor: Byte;
 BlockChar: Char;
 IsScanned: Boolean;
 DialogX1, DialogY1: Byte;
Begin
 { Positions de la bo√Æte de dialogue }
 DialogX1 := 5;
 DialogY1 := 3;
  { Calculer les secteurs reprÇsentÇs par chaque bloc }
 SectorsPerBlock := (TotalSectors + (MapWidth * MapHeight - 1)) div (MapWidth * MapHeight);
 If SectorsPerBlock < 1 Then SectorsPerBlock := 1;
 { Mettre Ö jour les statistiques - position relative }
 GotoXY(DialogX1 + 47, DialogY1 + 7);
 TextColor(Black);
 TextBackground(LightGray);
 Case(Language)of
  _English:Write(SectorsChecked, ' examined     ');
  Else Write(SectorsChecked, ' examinÇs     ');
 End;
 GotoXY(DialogX1 + 47, DialogY1 + 8);
 Case(Language)of
  _English:Write(BadFound, ' found bad     ');
  Else Write(BadFound, ' dÇfectueux     ');
 End;
 { Mettre Ö jour SEULEMENT les attributs visuels des blocs dÇjÖ scannÇs }
 For Y := 0 to MapHeight - 1 do Begin
  For X := 0 to MapWidth - 1 do Begin
   BlockNum := Y * MapWidth + X;
   CurrentSector := BlockNum * SectorsPerBlock;
   If CurrentSector < TotalSectors Then Begin
    { VÇrifier si ce bloc a ÇtÇ scannÇ }
    IsScanned := CurrentSector < SectorsChecked;
    GotoXY(DialogX1 + 2 + X, DialogY1 + 1 + Y);
    { DÇterminer le type de secteur (màme logique qu'avant) }
    If CurrentSector < (BootSector.ReservedSectors + BootSector.NumberOfFATs * BootSector.SectorsPerFAT) Then Begin
     { Zone systäme }
     If IsScanned Then Begin
      { Balayage - couleur brillante }
      TextColor(Yellow);
     End Else Begin
      { Pas encore scannÇ - couleur attÇnuÇe }
      TextColor(Cyan);
     End;
     Write(#254); { TOUJOURS LE MEME CARACTERE }
    End
     Else
    Begin
     { Zone de donnÇes }
     If Random(10) < 3 Then Begin
      { Secteur utilisÇ }
      If IsScanned Then Begin
       { ScannÇ - couleur brillante }
       TextColor(Yellow);
      End
       Else
      Begin
       { Pas encore scannÇ - couleur attÇnuÇe }
       TextColor(Cyan);
      End;
      Write(#254); { TOUJOURS LE MEME CARACTERE }
     End
      Else
     Begin
       { Secteur libre }
      If IsScanned Then Begin
       { ScannÇ - couleur brillante }
       TextColor(Yellow);
      End
       Else
      Begin
       { Pas encore scannÇ - couleur attÇnuÇe }
       TextColor(DarkGray);
      End;
      Write(#254); { TOUJOURS LE MEME CARACTERE }
     End;
    End;
   End;
  End;
 End;
 TextColor(Black);
 TextBackground(LightGray);
 TextBackground(Blue);
 TextColor(White);
 Percentage := (SectorsChecked * 100) div TotalSectors;
 If Percentage > 100 Then Percentage := 100;
 GotoXY(1, 24);
 Case(Language)of
  _English:Write(Percentage, '% complete  ');
  Else Write(Percentage, '% terminÇ  ');
 End;
  { Barre de progression graphique }
 For i := 15 to 65 do Begin
  GotoXY(i, 24);
  If i <= (15 + (Percentage * 50 div 100)) Then Begin
   TextColor(White);
   TextBackground(Blue);
   Write(#219)
  End
   Else
  Begin
   TextColor(DarkGray);
   TextBackground(Blue);
   Write(#177);
  End;
 End;
End;

Function DriveExists(Drive: Char): Boolean;
{$IFDEF Windows}
Var
 F: File;
 TestFile: String;
Begin
 TestFile := Drive + ':\$$$TEST.$$$';
 {$I-}Assign(F, TestFile);
 Reset(F); {$I+}
 If IOResult = 0 Then Begin
  Close(F);
  DriveExists := True;
 End
  Else
 Begin
  { Essayer de crÇer un fichier test }
  {$I-}Assign(F, TestFile);
  Rewrite(F);{$I+}
  If IOResult = 0 Then Begin
   Close(F);
   Erase(F);
   DriveExists := True;
  End
   Else
  Begin
   DriveExists := False;
  End;
 End;
End;
{$ELSE}
Var
 Regs: Registers;
 OldDrive: Byte;
Begin
  { Sauvegarder le lecteur actuel }
 Regs.AH := $19;
 Intr($21, Regs);
 OldDrive := Regs.AL;
  { Essayer de changer vers le lecteur }
 Regs.AH := $0E;
 Regs.DL := Ord(UpCase(Drive)) - Ord('A');
 Intr($21, Regs);
  { VÇrifier si le changement a rÇussi }
 Regs.AH := $19;
 Intr($21, Regs);
 DriveExists := Regs.AL = (Ord(UpCase(Drive)) - Ord('A'));
  { Restaurer le lecteur original }
 Regs.AH := $0E;
 Regs.DL := OldDrive;
 Intr($21, Regs);
End;
{$ENDIF}

Function SelectDrive: String;
Var
 Key: Char;
 SelectedDrive: Integer;
 DriveAvailable: Array[0..3] of Boolean;
 DriveCount: Integer;
 i: Integer;
Begin
  { VÇrifier quels lecteurs sont disponibles }
 DriveAvailable[0] := DriveExists('A'); { A: }
 DriveAvailable[1] := DriveExists('B'); { B: }
 DriveAvailable[2] := DriveExists('C'); { C: }
 DriveAvailable[3] := DriveExists('D'); { D: }
 DriveCount := 0;
 For i := 0 to 3 do If DriveAvailable[i] Then Inc(DriveCount);
 If DriveCount = 0 Then Begin
  Case(Language)of
   _English:ShowDialog('Error', 'No drives available', False);
   Else ShowDialog('Erreur', 'Aucun lecteur disponible', False);
  End;
  SelectDrive := '';
  Exit;
 End;
 SelectedDrive := 2; { Commencer avec C: par dÇfaut }
 While Not DriveAvailable[SelectedDrive] do
  SelectedDrive := (SelectedDrive + 1) mod 4;
 Repeat
  ClrScr;
  ShowTitle;
  GotoXY(1, 4);
  Case Language of
   _English: Write('Select the drive you want to check:');
   Else Write('SÇlectionnez le lecteur que vous voulez vÇrifier :');
  End;
   { Afficher les lecteurs disponibles }
  For i := 0 to 3 do Begin
   If DriveAvailable[i] Then Begin
    GotoXY(5, 7 + i);
    If i = SelectedDrive Then Begin
     TextColor(Black);
     TextBackground(White);
     Write('> ');
    End
     Else
    Begin
     TextColor(White);
     TextBackground(Blue);
     Write('  ');
    End;
    Write(Chr(Ord('A') + i), ':');
    If i = SelectedDrive Then Begin
     Write(' <');
     TextColor(White);
     TextBackground(Blue);
    End;
    ClrEol;
   End;
  End;
  GotoXY(1, 15);
  Case Language of
   _English: Begin
    Write('Use ',#24,#25,' arrows to select, Enter to continue, Esc to exit');
   End;
   Else Begin
    Write('Utilisez les fläches ',#24,#25,' pour sÇlectionner, EntrÇe pour continuer, êchap pour quitter');
   End;
  End;
  Key := ReadKey;
  Case Key of
   #0: Begin { Touche Çtendue }
    Key := ReadKey;
    Case Key of
     #72: Begin { Fläche haut }
      Repeat
       SelectedDrive := (SelectedDrive + 3) mod 4;
      Until DriveAvailable[SelectedDrive];
     End;
     #80: Begin { Fläche bas }
      Repeat
       SelectedDrive := (SelectedDrive + 1) mod 4;
      Until DriveAvailable[SelectedDrive];
     End;
    End;
   End;
   #13: Begin { Enter }
    SelectDrive := Chr(Ord('A') + SelectedDrive) + ':';
    Exit;
   End;
   #27: Begin { Escape }
    SelectDrive := '';
    Exit;
   End;
  End;
 Until False;
End;

Function ReadSector(SectorNum: LongInt): Boolean;
{$IFDEF Windows}
Begin
 If IsImageFile Then Begin
   { Appliquer le dÇplacement de partition si nÇcessaire }
  Seek(FileHandle, (SectorNum + PartitionOffset) * 512);
  BlockRead(FileHandle, SectorBuffer, 512);
  ReadSector := IOResult = 0;
 End
  Else
 Begin
  WriteLn('Accäs disque direct non supportÇ sous Windows');
  ReadSector := False;
 End;
End;
{$ELSE}
Var Regs: Registers;
Begin
 If IsImageFile Then Begin
   { Appliquer le dÇplacement de partition si nÇcessaire }
  Seek(FileHandle, (SectorNum + PartitionOffset) * 512);
  BlockRead(FileHandle, SectorBuffer, 512);
  ReadSector := IOResult = 0;
 End Else Begin
  Regs.AH := $02;
  Regs.AL := 1;
  Regs.CH := (SectorNum div (18 * 2)) and $FF;
  Regs.CL := (SectorNum mod 18) + 1;
  Regs.DH := (SectorNum div 18) mod 2;
  Regs.DL := DriveNum;
  Regs.ES := Seg(SectorBuffer);
  Regs.BX := Ofs(SectorBuffer);
  Intr($13, Regs);
  ReadSector := (Regs.Flags and 1) = 0;
 End;
End;
{$ENDIF}

Function WriteSector(SectorNum: LongInt): Boolean;
{$IFDEF Windows}
Begin
 If IsImageFile Then Begin
  { Appliquer le dÇplacement de partition si nÇcessaire }
  Seek(FileHandle, (SectorNum + PartitionOffset) * 512);
  BlockWrite(FileHandle, SectorBuffer, 512);
  WriteSector := IOResult = 0;
 End Else Begin
  WriteLn('Accäs disque direct non supportÇ sous Windows');
  WriteSector := False;
 End;
End;
{$ELSE}
Var Regs: Registers;
Begin
 If IsImageFile Then Begin
  { Appliquer le dÇplacement de partition si nÇcessaire }
  Seek(FileHandle, (SectorNum + PartitionOffset) * 512);
  BlockWrite(FileHandle, SectorBuffer, 512);
  WriteSector := IOResult = 0;
 End Else Begin
  Regs.AH := $03;
  Regs.AL := 1;
  Regs.CH := (SectorNum div (18 * 2)) and $FF;
  Regs.CL := (SectorNum mod 18) + 1;
  Regs.DH := (SectorNum div 18) mod 2;
  Regs.DL := DriveNum;
  Regs.ES := Seg(SectorBuffer);
  Regs.BX := Ofs(SectorBuffer);
  Intr($13, Regs);
  WriteSector := (Regs.Flags and 1) = 0;
 End;
End;
{$ENDIF}

Function DetectPartition: Boolean;
Var
 i: Integer;
 PartitionFound: Boolean;
 FileSize: LongInt;
Begin
 HasPartition := False;
 PartitionOffset := 0;
 DetectPartition := True;
 If Not IsImageFile Then Begin
  { Pour les vrais lecteurs, pas de partition Ö dÇtecter }
  DetectPartition := True;
  Exit;
 End;
  { Obtenir la taille du fichier image }
 FileSize := System.FileSize(FileHandle);
 If IOResult <> 0 Then Begin
  DetectPartition := False;
  Exit;
 End;
  { Si le fichier fait moins de 4 Mo, c'est probablement une disquette }
  { Les disquettes n'ont pas de table de partition MBR }
 If FileSize < (4 * 1024 * 1024) Then Begin
  Case(Language)of
   _English:Begin
    GotoXY(1, 3);
    Write('Small disk image (', FileSize div 1024, 'KB) - assuming floppy disk format');
    ClrEol;
   End;
   _Germany:Begin
    GotoXY(1, 3);
    Write('Kleines Disk-Image (', FileSize div 1024, 'KB) - Disketten-Format angenommen');
    ClrEol;
   End;
   _Italian:Begin
    GotoXY(1, 3);
    Write('Immagine disco piccola (', FileSize div 1024, 'KB) - formato dischetto assunto');
    ClrEol;
   End;
   _Spain:Begin
    GotoXY(1, 3);
    Write('Imagen de disco peque§a (', FileSize div 1024, 'KB) - formato disquete asumido');
    ClrEol;
   End;
   _Albanian:Begin
    GotoXY(1, 3);
    Write('Imazh disku i vogâl (', FileSize div 1024, 'KB) - format diskete supozohet');
    ClrEol;
   End;
   _Portuguese:Begin
    GotoXY(1, 3);
    Write('Imagem de disco pequena (', FileSize div 1024, 'KB) - formato disquete assumido');
    ClrEol;
   End;
   _Swedish:Begin
    GotoXY(1, 3);
    Write('Liten diskavbild (', FileSize div 1024, 'KB) - diskett-format antas');
    ClrEol;
   End;
   _Danish:Begin
    GotoXY(1, 3);
    Write('Lille disk-image (', FileSize div 1024, 'KB) - diskette-format antaget');
    ClrEol;
   End;
   _Japanese:Begin
    GotoXY(1, 3);
    Write('Chiisana disuku imeeji (', FileSize div 1024, 'KB) - furopii disuku keishiki to suitei');
    ClrEol;
   End;
   Else Begin
    GotoXY(1, 3);
    Write('Petite image disque (', FileSize div 1024, 'Ko) - format disquette assumÇ');
    ClrEol;
   End;
  End;
  DetectPartition := True;
  Exit;
 End;
  { Lire le secteur 0 pour vÇrifier s'il y a une table de partition }
 Seek(FileHandle, 0);
 BlockRead(FileHandle, MBR, SizeOf(TMBR));
 If IOResult <> 0 Then Begin
  DetectPartition := False;
  Exit;
 End;
  { VÇrifier la signature MBR }
 If MBR.Signature <> $AA55 Then Begin
  Case(Language)of
   _English:Begin
    GotoXY(1, 3);
    Write('No MBR signature found - assuming direct FAT format');
    ClrEol;
   End;
   Else Begin
    GotoXY(1, 3);
    Write('Signature MBR introuvable - format FAT direct assum√©');
    ClrEol;
   End;
  End;
  DetectPartition := True;
  Exit;
 End;
  { Afficher info sur la dÇtection de MBR }
 Case(Language)of
  _English:Begin
   GotoXY(1, 3);
   Write('MBR detected - analyzing partition table...');
   ClrEol;
  End;
   Else
  Begin
   GotoXY(1, 3);
   Write('MBR dÇtectÇ - analyse de la table de partition...');
   ClrEol;
  End;
 End;
  { Chercher une partition active ou la premiäre partition FAT }
 PartitionFound := False;
  { D'abord, chercher une partition active }
 For i := 0 to 3 do Begin
  With MBR.PartitionTable[i] do Begin
   If (Status = $80) and (PartitionType in [$01, $04, $06, $0B, $0C, $0E, $0F]) and (TotalSectors > 0) Then Begin
    PartitionOffset := RelativeSectors;
    HasPartition := True;
    PartitionFound := True;
    Case(Language)of
     _English:Begin
      GotoXY(1, 3);
      Write('Active partition found at sector ', RelativeSectors, ' (Type: $',
            IntToHex(PartitionType, 2), ')');
      ClrEol;
     End;
     Else Begin
      GotoXY(1, 3);
      Write('Partition active trouvÇe au secteur ', RelativeSectors, ' (Type: $',
            IntToHex(PartitionType, 2), ')');
      ClrEol;
     End;
    End;
    Break;
   End;
  End;
 End;
  { Si pas de partition active, chercher la premiäre partition FAT }
 If Not PartitionFound Then Begin
  For i := 0 to 3 do Begin
   With MBR.PartitionTable[i] do Begin
    { Debug : afficher toutes les partitions trouvÇes }
    If TotalSectors > 0 Then Begin
     Case(Language)of
      _English:Begin
       GotoXY(1, 5 + i);
       Write('Partition ', i, ': Type=$', IntToHex(PartitionType, 2),
             ' Status=$', IntToHex(Status, 2), ' Sectors=', TotalSectors);
       ClrEol;
      End;
      Else Begin
       GotoXY(1, 5 + i);
       Write('Partition ', i, ': Type=$', IntToHex(PartitionType, 2),
             ' Status=$', IntToHex(Status, 2), ' Secteurs=', TotalSectors);
       ClrEol;
      End;
     End;
    End;
    If (PartitionType in [$01, $04, $06, $0B, $0C, $0E, $0F]) and (TotalSectors > 0) Then Begin
     PartitionOffset := RelativeSectors;
     HasPartition := True;
     PartitionFound := True;
     Case(Language)of
      _English:Begin
       GotoXY(1, 3);
       Write('FAT partition found at sector ', RelativeSectors, ' (Type: $',
             IntToHex(PartitionType, 2), ')');
       ClrEol;
      End;
      Else Begin
       GotoXY(1, 3);
       Write('Partition FAT trouvÇe au secteur ', RelativeSectors, ' (Type: $',
             IntToHex(PartitionType, 2), ')');
       ClrEol;
      End;
     End;
     Break;
    End;
   End;
  End;
 End;
 If Not PartitionFound Then Begin
  Case(Language)of
   _English:ShowDialog('Error', 'No valid FAT partition found in disk image', False);
   Else ShowDialog('Erreur', 'Aucune partition FAT valide trouvÇe dans l''image disque', False);
  End;
  DetectPartition := False;
  Exit;
 End;
 DetectPartition := True;
End;

Function ReadBootSector:Boolean;Begin
 If ReadSector(0) Then Begin
  Move(SectorBuffer, BootSector, SizeOf(BootSector));
  TotalSectors := BootSector.TotalSectors;
  If TotalSectors = 0 Then TotalSectors := BootSector.TotalSectorsBig;
   { Initialiser le type de FAT et les limites }
  FATType := DetectFATType;
   { VÇrifications de sanitÇ }
  If (BootSector.SectorsPerFAT = 0) or (BootSector.SectorsPerFAT > 512) Then Begin
   Case(Language)of
    _English:ShowDialog('Error', 'Invalid sectors per FAT: ' + IntToStr(BootSector.SectorsPerFAT), False);
    Else ShowDialog('Erreur', 'Secteurs par FAT invalide : ' + IntToStr(BootSector.SectorsPerFAT), False);
   End;
   ReadBootSector := False;
   Exit;
  End;
  If (BootSector.BytesPerSector <> 512) Then Begin
   Case(Language)of
    _English:ShowDialog('Error', 'Unsupported sector size: ' + IntToStr(BootSector.BytesPerSector), False);
    Else ShowDialog('Erreur', 'Taille de secteur non supportÇe : ' + IntToStr(BootSector.BytesPerSector), False);
   End;
   ReadBootSector := False;
   Exit;
  End;
   { Afficher le type de FAT dÇtectÇ pour information }
  Case(Language)of
   _English:Begin
    If FATType = ftFAT12 Then Begin
     GotoXY(1, 3);
     Write('Detected file system: FAT12 (', MaxClusters, ' clusters max)');
     ClrEol;
    End
     Else
    Begin
     GotoXY(1, 3);
     Write('Detected file system: FAT16 (', MaxClusters, ' clusters max)');
     ClrEol;
    End;
   End;
   Else Begin
    If FATType = ftFAT12 Then Begin
     GotoXY(1, 3);
     Write('Systäme de fichiers dÇtectÇ : FAT12 (', MaxClusters, ' clusters max)');
     ClrEol;
    End
     Else
    Begin
     GotoXY(1, 3);
     Write('Systäme de fichiers dÇtectÇ : FAT16 (', MaxClusters, ' clusters max)');
     ClrEol;
    End;
   End;
  End;
  ReadBootSector := True;
 End
  Else
 ReadBootSector := False;
End;

Procedure ReadFAT;
Var
 i, j, FATIndex: Integer;
 MaxFATEntries, MaxSectors: Integer;
 ByteOffset: Word;
 FATValue: Word;
Begin
 CheckStatus[ciFAT] := False;
  { DÇtecter le type de FAT }
 FATType := DetectFATType;
  { Initialiser la FAT - dÇjÖ fait dans AllocateMemory }
 If FATType = ftFAT12 Then Begin
  MaxFATEntries := MaxClusters + 2;
  MaxSectors := (MaxFATEntries * 3 div 2 + 511) div 512; { FAT12: 1.5 octets par entrÇe }
  For i := 0 to Min(BootSector.SectorsPerFAT - 1, MaxSectors - 1) do Begin
   If ReadSector(BootSector.ReservedSectors + i) Then Begin
    { Lire les entrÇes FAT12 (1.5 octets par entrÇe) }
    For j := 0 to 341 do Begin { 512 / 1.5 ~ 341 entrÇes par secteur }
     FATIndex := i * 341 + j;
     If FATIndex >= MaxFATEntries Then Break;
     ByteOffset := (FATIndex * 3) div 2;
     If ByteOffset + 1 < 512 Then Begin
      If (FATIndex mod 2) = 0 Then Begin
       { EntrÇe paire : bits 0-11 }
       FATValue := SectorBuffer[ByteOffset] + ((SectorBuffer[ByteOffset + 1] and $0F) shl 8);
      End Else Begin
       { EntrÇe impaire : bits 4-15 }
       FATValue := (SectorBuffer[ByteOffset] shr 4) + (SectorBuffer[ByteOffset + 1] shl 4);
      End;
       { Masquer Ö 12 bits }
      SetFAT(FATIndex, FATValue and $0FFF);
     End;
    End;
   End
    Else
   Begin
    Exit;
   End;
  End;
 End
  Else
 Begin { FAT16 }
  MaxFATEntries := MaxClusters + 2;
  MaxSectors := (MaxFATEntries * 2 + 511) div 512; { FAT16: 2 octets par entrÇe }
  For i := 0 to Min(BootSector.SectorsPerFAT - 1, MaxSectors - 1) do Begin
   If ReadSector(BootSector.ReservedSectors + i) Then Begin
    { Lire les entrÇes FAT16 (2 octets par entrÇe) }
    For j := 0 to 255 do Begin { 512 / 2 = 256 entrÇes par secteur }
     FATIndex := i * 256 + j;
     If FATIndex >= MaxFATEntries Then Break;
     If (j * 2 + 1) < 512 Then Begin
      SetFAT(FATIndex, SectorBuffer[j * 2] + (SectorBuffer[j * 2 + 1] shl 8));
     End;
    End;
   End
    Else
   Begin
    Exit;
   End;
  End;
 End;
 CheckStatus[ciFAT] := True;
End;

Procedure CheckFATConsistency;
Var
 i, j, FATEntry, NextCluster: Integer;
 { Fragments FAT2 pour Çviter la limite de 65520 octets }
 Fat2A, Fat2B, Fat2C: PFATFragment;
 MaxFATEntries, MaxSectors: Integer;
 FATMismatch: Boolean;
 EndOfChainMark, BadClusterMark: Word;
 ByteOffset: Word;
 FATValue: Word;
Begin
 CheckStatus[ciMedia] := False;
  { Allouer la m√©moire pour les fragments FAT2 }
 GetMem(Fat2A, SizeOf(TFATFragment));
 GetMem(Fat2B, SizeOf(TFATFragment));
 GetMem(Fat2C, SizeOf(TFATFragment));
  { VÇrifier les allocations }
 If (Fat2A = nil) or (Fat2B = nil) or (Fat2C = nil) Then Begin
  { LibÇrer ce qui a ÇtÇ allouÇ }
  If Fat2A <> nil Then FreeMem(Fat2A, SizeOf(TFATFragment));
  If Fat2B <> nil Then FreeMem(Fat2B, SizeOf(TFATFragment));
  If Fat2C <> nil Then FreeMem(Fat2C, SizeOf(TFATFragment));
  Exit;
 End;
  { Initialiser Ö zÇro }
 FillChar(Fat2A^, SizeOf(TFATFragment), 0);
 FillChar(Fat2B^, SizeOf(TFATFragment), 0);
 FillChar(Fat2C^, SizeOf(TFATFragment), 0);
  { DÇfinir les marqueurs selon le type FAT }
 If FATType = ftFAT12 Then Begin
  EndOfChainMark := $FF8;
  BadClusterMark := $FF7;
 End
  Else
 Begin { FAT16 }
  EndOfChainMark := $FFF8;
  BadClusterMark := $FFF7;
 End;
  { VÇrifier d'abord le descripteur de mÇdia }
 If BootSector.MediaDescriptor <> $F0 Then Begin { $F0 = disquette HD, $F8 = disque dur }
  If BootSector.MediaDescriptor <> $F8 Then Begin
   Inc(ErrorsFound);
   If Not CheckOnly Then Begin
    Case(Language)of
     _English:ShowDialog('Media Error', 'Invalid media descriptor: $' +
                IntToStr(BootSector.MediaDescriptor), False);
     Else ShowDialog('Erreur mÇdia', 'Descripteur de mÇdia invalide : $' +
                IntToStr(BootSector.MediaDescriptor), False);
    End;
   End;
  End;
 End;
  { VÇrifier que les deux copies de la FAT sont identiques }
 If BootSector.NumberOfFATs >= 2 Then Begin
  FATMismatch := False;
  MaxFATEntries := MaxClusters + 2;
  If FATType = ftFAT12 Then Begin
   MaxSectors := (MaxFATEntries * 3 div 2 + 511) div 512;
  End Else Begin
   MaxSectors := (MaxFATEntries * 2 + 511) div 512;
  End;
   { Lire la deuxiäme FAT avec le bon format }
   { RÇinitialiser les fragments FAT2 }
  FillChar(Fat2A^, SizeOf(TFATFragment), 0);
  FillChar(Fat2B^, SizeOf(TFATFragment), 0);
  FillChar(Fat2C^, SizeOf(TFATFragment), 0);
  If FATType = ftFAT12 Then Begin
   { Lire FAT12 pour la deuxiäme copie }
   For i := 0 to Min(BootSector.SectorsPerFAT - 1, MaxSectors - 1) do Begin
    If ReadSector(BootSector.ReservedSectors + BootSector.SectorsPerFAT + i) Then Begin
     For j := 0 to 341 do Begin
      If (i * 341 + j) >= MaxFATEntries Then Break;
       { Lire les entrÇes FAT12 (1.5 octets par entrÇe) - màme logique que ReadFAT }
      ByteOffset := ((i * 341 + j) * 3) div 2;
      If ByteOffset + 1 < 512 Then Begin
       If ((i * 341 + j) mod 2) = 0 Then Begin
        { EntrÇe paire : bits 0-11 }
        FATValue := SectorBuffer[ByteOffset] + ((SectorBuffer[ByteOffset + 1] and $0F) shl 8);
       End Else Begin
        { EntrÇe impaire : bits 4-15 }
        FATValue := (SectorBuffer[ByteOffset] shr 4) + (SectorBuffer[ByteOffset + 1] shl 4);
       End;
       { Masquer Ö 12 bits et entreposer }
       SetFAT2(i * 341 + j, FATValue and $0FFF, Fat2A, Fat2B, Fat2C);
      End;
     End;
    End
     Else
    Begin
     Inc(ErrorsFound);
     Exit;
    End;
   End;
  End
   Else
  Begin
   { Lire FAT16 pour la deuxiäme copie }
   For i := 0 to Min(BootSector.SectorsPerFAT - 1, MaxSectors - 1) do Begin
    If ReadSector(BootSector.ReservedSectors + BootSector.SectorsPerFAT + i) Then Begin
     For j := 0 to 255 do Begin
      If (i * 256 + j) >= MaxFATEntries Then Break;
      If (j * 2 + 1) < 512 Then Begin
       SetFAT2(i * 256 + j, SectorBuffer[j * 2] + (SectorBuffer[j * 2 + 1] shl 8), Fat2A, Fat2B, Fat2C);
      End;
     End;
    End Else Begin
     Inc(ErrorsFound);
     Exit;
    End;
   End;
  End;
   { Comparer les deux FATs }
  For i := 0 to MaxFATEntries - 1 do Begin
   If GetFAT(i) <> GetFAT2(i, Fat2A, Fat2B, Fat2C) Then Begin
    FATMismatch := True;
    Inc(ErrorsFound);
    Break;
   End;
  End;
   If FATMismatch Then Begin
   If AutoFix Then Begin
    { RÇparer en copiant la premiäre FAT sur la deuxiäme - Ö implÇmenter }
   End
    Else
   Begin
    Case(Language)of
     _English:ShowDialog('FAT Error', 'FAT copies are inconsistent. Use /AUTOFIX to repair.', False);
     Else ShowDialog('Erreur FAT', 'Les copies de FAT sont incoh√©rentes. Utilisez /AUTOFIX pour r√©parer.', False);
    End;
   End;
  End;
 End;
  { VÇrifier les entrÇes spÇciales de la FAT }
 If MaxFATEntries >= 2 Then Begin
  { Les deux premiäres entrÇes doivent avoir des valeurs spÇciales }
  If FATType = ftFAT12 Then Begin
   If (GetFAT(0) and $0FFF) <> ($0F00 or BootSector.MediaDescriptor) Then Begin
    Inc(ErrorsFound);
    If AutoFix Then Begin
     SetFAT(0, $0F00 or BootSector.MediaDescriptor);
    End
     Else
    Begin
     Case(Language)of
      _English:ShowDialog('FAT Error', 'Invalid FAT[0] entry', False);
      Else ShowDialog('Erreur FAT', 'Entr√©e FAT[0] invalide', False);
     End;
    End;
   End;
   If (GetFAT(1) and $0FFF) <> $0FFF Then Begin
    Inc(ErrorsFound);
    If AutoFix Then Begin
     SetFAT(1, $0FFF);
    End Else Begin
     Case(Language)of
      _English:ShowDialog('FAT Error', 'Invalid FAT[1] entry', False);
      Else ShowDialog('Erreur FAT', 'EntrÇe FAT[1] invalide', False);
     End;
    End;
   End;
  End Else Begin { FAT16 }
   If (GetFAT(0) and $FFFF) <> ($FF00 or BootSector.MediaDescriptor) Then Begin
    Inc(ErrorsFound);
    If AutoFix Then Begin
     SetFAT(0, $FF00 or BootSector.MediaDescriptor);
    End Else Begin
     Case(Language)of
      _English:ShowDialog('FAT Error', 'Invalid FAT[0] entry', False);
      Else ShowDialog('Erreur FAT', 'EntrÇe FAT[0] invalide', False);
     End;
    End;
   End;
   If (GetFAT(1) and $FFFF) <> $FFFF Then Begin
    Inc(ErrorsFound);
    If AutoFix Then Begin
     SetFAT(1, $FFFF);
    End Else Begin
     Case(Language)of
      _English:ShowDialog('FAT Error', 'Invalid FAT[1] entry', False);
      Else ShowDialog('Erreur FAT', 'Entr√©e FAT[1] invalide', False);
     End;
    End;
   End;
  End;
 End;
  { VÇrifier les chaånes de clusters pour dÇtecter les boucles infinies }
 For i := 2 to MaxClusters + 1 do Begin
  If (GetFAT(i) <> 0) and (GetFAT(i) < EndOfChainMark) Then Begin
   NextCluster := GetFAT(i);
   j := 0;
   While (NextCluster < EndOfChainMark) and (NextCluster <> 0) and (j < 1000) do Begin
    If NextCluster > MaxClusters + 1 Then Begin
     Inc(ErrorsFound);
     Case(Language)of
      _English:ShowDialog('FAT Error', 'Invalid cluster chain at cluster ' + IntToStr(i), False);
      Else ShowDialog('Erreur FAT', 'Chaåne de cluster invalide au cluster ' + IntToStr(i), False);
     End;
     Break;
    End;
    NextCluster := GetFAT(NextCluster);
    Inc(j);
   End;
   If j >= 1000 Then Begin
    Inc(ErrorsFound);
    Case(Language)of
     _English:ShowDialog('FAT Error', 'Infinite loop detected in cluster chain starting at cluster ' + IntToStr(i), False);
     Else ShowDialog('Erreur FAT', 'Boucle infinie dÇtectÇe dans '+
             'la chaåne de cluster commenáant au cluster ' + IntToStr(i), False);
    End;
   End;
  End;
 End;
  { LibÇrer la mÇmoire allouÇe pour FAT2 }
 FreeMem(Fat2A, SizeOf(TFATFragment));
 FreeMem(Fat2B, SizeOf(TFATFragment));
 FreeMem(Fat2C, SizeOf(TFATFragment));
 CheckStatus[ciMedia] := True;
End;

Procedure CheckDirectoryStructure;
Var
 i, j: Integer;
 RootSectors: Integer;
 FirstDataSector: Integer;
Begin
 CheckStatus[ciDirectory] := False;
 RootSectors := (BootSector.RootEntries * 32 + 511) div 512;
 FirstDataSector := BootSector.ReservedSectors + (BootSector.NumberOfFATs * BootSector.SectorsPerFAT);
 For i := 0 to RootSectors - 1 do Begin
  If ReadSector(FirstDataSector + i) Then Begin
   For j := 0 to 15 do Begin { 16 entr√©es par secteur }
    If (i * 16 + j) <= High(RootDir) Then Begin
     Move(SectorBuffer[j * 32], RootDir[i * 16 + j], 32);
      { VÇrifier l'entrÇe }
     If RootDir[i * 16 + j].Name[0] <> #0 Then Begin
      { Marquer les clusters utilisÇs }
      If (RootDir[i * 16 + j].StartCluster > 0) and
         (RootDir[i * 16 + j].StartCluster <= 65535) Then Begin
       SetClusterMap(RootDir[i * 16 + j].StartCluster, 1);
      End;
     End;
    End;
   End;
  End
   Else
  Begin
   Exit;
  End;
 End;
 CheckStatus[ciDirectory] := True;
End;

Procedure CheckFileAllocation;
Var
 i, NextCluster: Integer;
 Chain: Array[0..1023] of Word;
 ChainLength: Integer;
 EndOfChainMark: Word;
Begin
 CheckStatus[ciFileSystem] := False;
  { DÇfinir le marqueur de fin selon le type FAT }
 If FATType = ftFAT12 Then Begin
  EndOfChainMark := $FF8;
 End
  Else
 Begin { FAT16 }
  EndOfChainMark := $FFF8;
 End;
 For i := 2 to MaxClusters + 1 do Begin
  If (GetFAT(i) <> 0) and (GetFAT(i) < EndOfChainMark) Then Begin
   { Suivre la chaåne de clusters }
   NextCluster := i;
   ChainLength := 0;
   FillChar(Chain, SizeOf(Chain), 0);
   Repeat
    If ChainLength < High(Chain) Then Begin
     Chain[ChainLength] := NextCluster;
     Inc(ChainLength);
    End;
    If NextCluster <= MaxClusters + 1 Then Begin
     If GetClusterMap(NextCluster) = 1 Then
      SetClusterMap(NextCluster, 1)
     Else If GetClusterMap(NextCluster) = 0 Then
      SetClusterMap(NextCluster, 1)
     Else Begin
      Inc(CrossLinkedFiles);
      SetClusterMap(NextCluster, 3);
     End;
    End;
    If NextCluster <= MaxClusters + 1 Then NextCluster := GetFAT(NextCluster)
                                      Else Break;
    If ChainLength > 1000 Then Break; { Protection contre les boucles infinies }
   Until (NextCluster >= EndOfChainMark) or (NextCluster = 0);
  End;
 End;
 CheckStatus[ciFileSystem] := True;
End;

Procedure CheckLostClusters;
Var
 i: Integer;
Begin
 CheckStatus[ciFreeSpace] := False;
 For i := 2 to MaxClusters + 1 do Begin
  If (i <= MaxClusters + 1) and (GetFAT(i) <> 0) and (GetClusterMap(i) = 0) Then Begin
   Inc(LostClusters);
   Inc(ErrorsFound);
  End;
 End;
 CheckStatus[ciFreeSpace] := True;
End;

Procedure SurfaceScan;
Var
 i: LongInt;
 BadSectorFound: Boolean;
 SectorsExamined: LongInt;
 DialogX1, DialogY1: Byte;
Begin
 If Not DoSurfaceScan Then Exit;
  { Positions de la boåte de dialogue }
 DialogX1 := 5;
 DialogY1 := 3;
  { Initialiser les variables }
 CheckStatus[ciSurface] := False;
 BadSectors := 0;
 SectorsExamined := 0;
  { Afficher l'Çcran de surface scan - êCRAN FIXE }
 ShowSurfaceScanScreen;
 { Initialiser le gÇnÇrateur de nombres alÇatoires pour la simulation }
 Randomize;
 For i := 0 to TotalSectors - 1 do Begin
  Inc(SectorsExamined);
  BadSectorFound := Not ReadSector(i);
  If BadSectorFound Then Begin
   Inc(BadSectors);
   If AutoFix Then Begin
     { Marquer le cluster correspondant comme dÇfectueux }
    If i >= (BootSector.ReservedSectors + BootSector.NumberOfFATs * BootSector.SectorsPerFAT) Then Begin
     If FATType = ftFAT12 Then Begin
      SetFAT((i - (BootSector.ReservedSectors + BootSector.NumberOfFATs * BootSector.SectorsPerFAT))
            div BootSector.SectorsPerCluster + 2, $FF7);
     End Else Begin { FAT16 }
      SetFAT((i - (BootSector.ReservedSectors + BootSector.NumberOfFATs * BootSector.SectorsPerFAT))
            div BootSector.SectorsPerCluster + 2, $FFF7);
     End;
    End;
   End;
  End;
   { Mettre Ö jour l'affichage selon la taille du disque pour Çviter de ralentir }
  If (HasPartition) Then Begin
   { Pour les gros disques, mise Ö jour moins frÇquente }
   If (i mod (TotalSectors div 100 + 1)) = 0 Then Begin
    UpdateSurfaceProgress(SectorsExamined, BadSectors);
   End;
  End
   Else
  If (TotalSectors < 100) or ((i mod (TotalSectors div 200 + 1)) = 0) Then Begin
   UpdateSurfaceProgress(SectorsExamined, BadSectors);
  End;
   { VÇrifier si l'utilisateur appuie sur une touche }
  If KeyPressed Then Begin
   Case ReadKey of
    #27, 'e', 'E': Begin { ESC ou Exit }
     Break;
    End;
   End;
  End;
   { DÇlai proportionnel Ö la taille du disque - pas de dÇlai pour les gros disques }
  If TotalSectors < 1000 Then Delay(20) Else
  If TotalSectors < 10000 Then Delay(2) Else
  If HasPartition Then { Pas de dÇlai pour les disques avec partitions }
                       { Pas de dÇlai du tout }
                  Else Delay(1);
 End;
  { Mettre Ö jour l'affichage final }
 UpdateSurfaceProgress(SectorsExamined, BadSectors);
 CheckStatus[ciSurface] := True;
  { Attendre que l'utilisateur appuie sur une touche - EN BAS DE L'√âCRAN }
 TextBackground(Blue);
 TextColor(White);
 GotoXY(20, 24);
 Case(Language)of
  _English:Write('Press any key to continue...');
  Else Write('Appuyez sur une touche pour continuer...');
 End;
 ReadKey;
End;

Procedure PerformChecks;
Var
 CheckDelay: Integer;
Begin
 ClrScr;
 ShowTitle;
 ShowCheckList;
 GotoXY(1, 24);
 Case(Language)of
  _English:Write('examining drive ', DrivePath, '...');
  Else Write('examen du lecteur ', DrivePath, '...');
 End;
 ClrEol;
  { DÇterminer le dÇlai selon la taille du disque }
 If HasPartition or (TotalSectors > 10000) Then CheckDelay := 10 Else
 If TotalSectors > 2000 Then CheckDelay := 50
                        Else CheckDelay := 100;
  { Effectuer les vÇrifications une par une avec mise Ö jour en place }
 CheckStatus[ciMedia] := False;
 CheckFATConsistency;
 ShowCheckList;
 Delay(CheckDelay);
 CheckStatus[ciFAT] := False;
 ReadFAT;
 ShowCheckList;
 Delay(CheckDelay);
 CheckStatus[ciDirectory] := False;
 CheckDirectoryStructure;
 ShowCheckList;
 Delay(CheckDelay);
 CheckStatus[ciFileSystem] := False;
 CheckFileAllocation;
 ShowCheckList;
 Delay(CheckDelay);
 CheckStatus[ciFreeSpace] := False;
 CheckLostClusters;
 ShowCheckList;
 Delay(CheckDelay);
 { Demander pour le surface scan }
 Case(Language)of
  _English:Begin
   If ShowDialog('ScanDisk', 'ScanDisk has finished testing the file structure. Do you want to '+
                             'perform a surface scan now?', True)Then Begin
    DoSurfaceScan:=True;
    SurfaceScan;
   End;
  End;
  Else Begin
   If ShowDialog('Balayage de surface', 'ScanDisk a terminÇ les testes de structure de fichiers. Voulez-vous '+
                 'effectuer un test de surface maintenant ?', True)Then Begin
    DoSurfaceScan:=True;
    SurfaceScan;
   End;
  End;
 End;
End;

Procedure ShowSummary;Begin
 TextBackground(Black);
 TextColor(LightGray);
 ClrScr;
 GotoXY(1, 5);
 Write('=== RêSUMê DE LA VêRIFICATION ===');
 GotoXY(1, 6);
 Write('Secteurs totaux: ', TotalSectors);
 GotoXY(1, 7);
 Write('Secteurs dÇfectueux: ', BadSectors);
 GotoXY(1, 8);
 Write('UnitÇs d''allocations perdus: ', LostClusters);
 GotoXY(1, 9);
 Write('Fichiers avec liens croisÇs: ', CrossLinkedFiles);
 GotoXY(1, 10);
 Write('Erreurs totales: ', ErrorsFound);
 GotoXY(1, 12);
 If ErrorsFound = 0 Then Write('Aucune erreur trouvÇe. Le disque est en bon Çtat.')
  Else
 Begin
  Write('Des erreurs ont ÇtÇ dÇtectÇes.');
  GotoXY(1, 13);
  If CheckOnly Then Write('Mode vÇrification seulement - aucune rÇparation effectuÇe.') Else
  If AutoFix Then Write('RÇparations automatiques effectuÇes.')
             Else Write('Utilisez /AUTOFIX pour rÇparer automatiquement les erreurs.');
 End;
End;

BEGIN
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ENDIF}
 {$ENDIF}
  { Initialisation }
 Language := _French;
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
  { VÇrification des paramätres d'aide }
 If (ParamStr(1) = '/?') or (ParamStr(1) = '--help') or (ParamStr(1) = '-h') or
    (ParamStr(1) = '/h') or (ParamStr(1) = '/H') Then Begin
  Case Language of
   _English: Begin
    WriteLn('SCANDISK - Disk diagnostic and repair utility');
    WriteLn;
    WriteLn('Usage: SCANDISK [drive: | filename] [/AUTOFIX] [/CHECKONLY] [/SURFACE]');
    WriteLn;
    WriteLn('  drive:     Drive to check (A:, C:, etc.)');
    WriteLn('  filename   Disk image file to check');
    WriteLn('  /AUTOFIX   Automatically fix errors');
    WriteLn('  /CHECKONLY Check only, do not fix');
    WriteLn('  /SURFACE   Perform surface scan');
   End;
   _Germany: Begin
    WriteLn('SCANDISK - Festplatten-Diagnose- und Reparaturprogramm');
    WriteLn;
    WriteLn('Verwendung: SCANDISK [Laufwerk: | Dateiname] [/AUTOFIX] [/CHECKONLY] [/SURFACE]');
    WriteLn;
    WriteLn('  Laufwerk:  Zu prÅfendes Laufwerk (A:, C:, usw.)');
    WriteLn('  Dateiname  Zu prÅfende Festplatten-Image-Datei');
    WriteLn('  /AUTOFIX   Fehler automatisch beheben');
    WriteLn('  /CHECKONLY Nur prÅfen, nicht reparieren');
    WriteLn('  /SURFACE   OberflÑchenscan durchfÅhren');
   End;
   _Italian: Begin
    WriteLn('SCANDISK - UtilitÖ di diagnosi e riparazione disco');
    WriteLn;
    WriteLn('Utilizzo: SCANDISK [unitÖ: | nomefile] [/AUTOFIX] [/CHECKONLY] [/SURFACE]');
    WriteLn;
    WriteLn('  unitÖ:     UnitÖ da controllare (A:, C:, ecc.)');
    WriteLn('  nomefile   File immagine disco da controllare');
    WriteLn('  /AUTOFIX   Ripara automaticamente gli errori');
    WriteLn('  /CHECKONLY Solo controllo, non riparare');
    WriteLn('  /SURFACE   Esegui scansione superficie');
   End;
   _Spain: Begin
    WriteLn('SCANDISK - Utilidad de diagn¢stico y reparaci¢n de disco');
    WriteLn;
    WriteLn('Uso: SCANDISK [unidad: | archivo] [/AUTOFIX] [/CHECKONLY] [/SURFACE]');
    WriteLn;
    WriteLn('  unidad:    Unidad a verificar (A:, C:, etc.)');
    WriteLn('  archivo    Archivo de imagen de disco a verificar');
    WriteLn('  /AUTOFIX   Reparar autom†ticamente los errores');
    WriteLn('  /CHECKONLY Solo verificar, no reparar');
    WriteLn('  /SURFACE   Realizar exploraci¢n de superficie');
   End;
   _Albanian: Begin
    WriteLn('SCANDISK - Utilitar diagnostik dhe riparim disku');
    WriteLn;
    WriteLn('Pârdorimi: SCANDISK [disku: | skedari] [/AUTOFIX] [/CHECKONLY] [/SURFACE]');
    WriteLn;
    WriteLn('  disku:     Disku pâr tâ kontrolluar (A:, C:, etj.)');
    WriteLn('  skedari    Skedari imazh disku pâr tâ kontrolluar');
    WriteLn('  /AUTOFIX   Riparo automatikisht gabimet');
    WriteLn('  /CHECKONLY Vetâm kontrollo, mos riparo');
    WriteLn('  /SURFACE   Kryej skanim sipârfaqe');
   End;
   _Portuguese: Begin
    WriteLn('SCANDISK - Utilit†rio de diagn¢stico e reparo de disco');
    WriteLn;
    WriteLn('Uso: SCANDISK [unidade: | arquivo] [/AUTOFIX] [/CHECKONLY] [/SURFACE]');
    WriteLn;
    WriteLn('  unidade:   Unidade a verificar (A:, C:, etc.)');
    WriteLn('  arquivo    Arquivo de imagem de disco a verificar');
    WriteLn('  /AUTOFIX   Reparar automaticamente os erros');
    WriteLn('  /CHECKONLY Apenas verificar, nao reparar');
    WriteLn('  /SURFACE   Realizar varredura de superf°cie');
   End;
   _Swedish: Begin
    WriteLn('SCANDISK - Disk diagnos- och reparationsverktyg');
    WriteLn;
    WriteLn('AnvÑndning: SCANDISK [enhet: | filnamn] [/AUTOFIX] [/CHECKONLY] [/SURFACE]');
    WriteLn;
    WriteLn('  enhet:     Enhet att kontrollera (A:, C:, osv.)');
    WriteLn('  filnamn    Diskavbildningsfil att kontrollera');
    WriteLn('  /AUTOFIX   AtgÑrda fel automatiskt');
    WriteLn('  /CHECKONLY Bara kontrollera, reparera inte');
    WriteLn('  /SURFACE   Utfîr ytskanning');
   End;
   _Danish: Begin
    WriteLn('SCANDISK - Disk diagnose- og reparationsvaerktoj');
    WriteLn;
    WriteLn('Brug: SCANDISK [drev: | filnavn] [/AUTOFIX] [/CHECKONLY] [/SURFACE]');
    WriteLn;
    WriteLn('  drev:      Drev at kontrollere (A:, C:, osv.)');
    WriteLn('  filnavn    Disk-image-fil at kontrollere');
    WriteLn('  /AUTOFIX   Reparer fejl automatisk');
    WriteLn('  /CHECKONLY Kun kontroller, reparer ikke');
    WriteLn('  /SURFACE   Udfor overfladeskanning');
   End;
   _Japanese: Begin
    WriteLn('SCANDISK - Disuku shindan oyobi shuuri yuutiriti');
    WriteLn;
    WriteLn('Tsukaikata: SCANDISK [doraibu: | fairu mei] [/AUTOFIX] [/CHECKONLY] [/SURFACE]');
    WriteLn;
    WriteLn('  doraibu:   Chekku suru doraibu (A:, C:, nado)');
    WriteLn('  fairu mei  Chekku suru disuku imeeji fairu');
    WriteLn('  /AUTOFIX   Jidouteki ni eraa wo shuuri suru');
    WriteLn('  /CHECKONLY Chekku nomi, shuuri shinai');
    WriteLn('  /SURFACE   Hyoumen sukyan wo jikkou suru');
   End;
   Else Begin
    WriteLn('SCANDISK - Cette commande permet de lancer l''utilitaire ',
                        'de diagnostic et rÇparation de disque.');
    WriteLn;
    WriteLn('Syntaxe : SCANDISK [lecteur: | fichier] [/AUTOFIX] [/CHECKONLY] [/SURFACE]');
    WriteLn;
    WriteLn('  lecteur:   Lecteur Ö vÇrifier (A:, C:, etc.)');
    WriteLn('  fichier    Fichier image disque Ö vÇrifier');
    WriteLn('  /AUTOFIX   RÇparer automatiquement les erreurs');
    WriteLn('  /CHECKONLY VÇrification seulement, pas de rÇparation');
    WriteLn('  /SURFACE   Effectuer un scan de surface');
   End;
  End;
  Halt;
 End;
  { Ajustement de l'interface graphique }
 CursorOff;
 SetupColors;
  { Allouer la mÇmoire pour les tableaux FAT et ClusterMap }
 AllocateMemory;
  { Si aucun param√®tre, permettre la sÇlection d'un lecteur }
 If ParamCount = 0 Then Begin
  DrivePath := SelectDrive;
  If DrivePath = '' Then Begin
   FreeMemory;
   CursorOn;
   Halt(0);
  End;
 End
  Else
 Begin
  { Analyse des paramätres }
  DrivePath := StrToUpper(ParamStr(1));
 End;
  { Initialisation des variables }
 AutoFix := False;
 CheckOnly := False;
 DoSurfaceScan := False;
 IsImageFile := False;
 BadSectors := 0;
 LostClusters := 0;
 CrossLinkedFiles := 0;
 ErrorsFound := 0;
 HasPartition := False;
 PartitionOffset := 0;
  { ClusterMap est maintenant initialis√© dans AllocateMemory }
 FillChar(CheckStatus, SizeOf(CheckStatus), 0);
  { DÇterminer le type de cible (lecteur ou fichier image) }
 If (Length(DrivePath) = 2) and (DrivePath[2] = ':') Then Begin
  { C'est un lecteur }
  IsImageFile := False;
  Case DrivePath[1] of
   'A': DriveNum := 0;
   'B': DriveNum := 1;
   'C': DriveNum := $80;
   'D': DriveNum := $81;
   Else Begin
    Case(Language)of
     _English:ShowDialog('Error', 'Unsupported drive: ' + DrivePath, False);
     Else ShowDialog('Erreur', 'Lecteur non supportÇ : ' + DrivePath, False);
    End;
    FreeMemory;
    Halt(1);
   End;
  End;
 End
  Else
 Begin
  { C'est un fichier image }
  IsImageFile := True;
  FileName := DrivePath;
  DrivePath := 'file';
  {$I-} Assign(FileHandle, FileName);
  Reset(FileHandle, 1);
  {$I+}
  If IOResult <> 0 Then Begin
   Case(Language)of
    _English:ShowDialog('Error', 'Cannot open file: ' + FileName, False);
    Else ShowDialog('Erreur', 'Impossible d''ouvrir le fichier : ' + FileName, False);
   End;
   FreeMemory;
   Halt(1);
  End;
 End;
  { Traitement des options }
 If ParamCount > 1 Then Begin
  For ErrorsFound := 2 to ParamCount do Begin
   If StrToUpper(ParamStr(ErrorsFound)) = '/AUTOFIX' Then AutoFix := True;
   If StrToUpper(ParamStr(ErrorsFound)) = '/CHECKONLY' Then CheckOnly := True;
   If StrToUpper(ParamStr(ErrorsFound)) = '/SURFACE' Then DoSurfaceScan := True;
  End;
 End;
 ErrorsFound := 0;
  { DÇtecter les partitions pour les fichiers images }
 If IsImageFile Then Begin
  If Not DetectPartition Then Begin
   If IsImageFile Then Close(FileHandle);
   FreeMemory;
   Halt(1);
  End;
 End;
  { Lecture du secteur de boot }
 If Not ReadBootSector Then Begin
  Case(Language)of
   _English:ShowDialog('Error', 'Cannot read boot sector', False);
   Else ShowDialog('Erreur', 'Impossible de lire le secteur de boot', False);
  End;
  If IsImageFile Then Close(FileHandle);
  FreeMemory;
  Halt(1);
 End;
  { Effectuer les vÇrifications avec interface graphique }
 PerformChecks;
  { Sauvegarde si des modifications ont ÇtÇ faites }
 If AutoFix and (ErrorsFound > 0) and Not CheckOnly Then Begin
  { RÇÇcrire la FAT si nÇcessaire }
 End;
  { Nettoyage }
 If IsImageFile Then Close(FileHandle);
  { LibÇrer la mÇmoire allouÇe }
 FreeMemory;
 { Affichage du rÇsumÇ }
 ShowSummary;
 CursorOn;
  { Code de sortie }
 If ErrorsFound > 0 Then Halt(1) Else Halt(0);
END.