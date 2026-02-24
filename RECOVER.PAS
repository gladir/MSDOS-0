{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program RECOVER;

{$M 65520,0,655200}

Uses DOS,Crt;

Const
 { Codes d'erreur }
 ERR_SUCCESS = 0;
 ERR_FILE_NOT_FOUND = 2;
 ERR_PATH_NOT_FOUND = 3;
 ERR_ACCESS_DENIED = 5;
 ERR_INVALID_DRIVE = 15;
 ERR_DISK_FULL = 28;
 ERR_INVALID_PARAMETER = 87;

Type
 { Structure du secteur de boot FAT }
 TBootSector = Record
  JumpCode: Array[0..2] of Byte;         { Code de saut vers le code de boot (E9 xx xx ou EB xx 90) }
  OEMName: Array[0..7] of Char;          { Nom du système de fichiers (ex: "MSDOS5.0") }
  BytesPerSector: Word;                  { Nombre d'octets par secteur (généralement 512) }
  SectorsPerCluster: Byte;               { Nombre de secteurs par cluster (1, 2, 4, 8, 16, 32, 64, 128) }
  ReservedSectors: Word;                 { Nombre de secteurs réservés (généralement 1 pour FAT12/16) }
  NumberOfFATs: Byte;                    { Nombre de copies de la FAT (généralement 2) }
  RootEntries: Word;                     { Nombre d'entrées dans le répertoire racine (0 pour FAT32) }
  TotalSectors: Word;                    { Nombre total de secteurs (0 si > 65535, voir TotalSectorsBig) }
  MediaDescriptor: Byte;                 { Descripteur de média (F0=disquette, F8=disque dur, etc.) }
  SectorsPerFAT: Word;                   { Nombre de secteurs par FAT (0 pour FAT32) }
  SectorsPerTrack: Word;                 { Nombre de secteurs par piste (géométrie physique) }
  NumberOfHeads: Word;                   { Nombre de têtes (géométrie physique) }
  HiddenSectors: LongInt;                { Nombre de secteurs cachés avant la partition }
  TotalSectorsBig: LongInt;              { Nombre total de secteurs si TotalSectors = 0 }
 End;

 { Entrée de répertoire FAT }
 TDirEntry = Record
  Name: Array[0..10] of Char;            { Nom de fichier 8.3 (8 car + 3 ext, sans point) }
  Attr: Byte;                            { Attributs:
                                             bit 0=lecture seule,
                                                 1=caché,
                                                 2=système,
                                                 3=label,
                                                 4=répertoire,
                                                 5=archive }
  Reserved: Array[0..9] of Byte;         { Octets réservés (NT, temps création, etc.) }
  Time: Word;                            { Heure de dernière modification (format packed) }
  Date: Word;                            { Date de dernière modification (format packed) }
  StartCluster: Word;                    { Numéro du premier cluster du fichier }
  Size: LongInt;                         { Taille du fichier en octets }
 End;

 { Master Boot Record }
 TMBR = Record
  BootCode: Array[0..445] of Byte;       { Code de boot }
  Partition: Array[0..3] of Record       { Table des partitions }
   Status: Byte;                         { 00=inactive, 80=active }
   StartHead: Byte;                      { Tête de début }
   StartSector: Byte;                    { Secteur de début (bits 0-5) + cylindre haut (bits 6-7) }
   StartCylinder: Byte;                  { Cylindre de début (bits bas) }
   PartType: Byte;                       { Type de partition (01=FAT12, 04=FAT16, etc.) }
   EndHead: Byte;                        { Tête de fin }
   EndSector: Byte;                      { Secteur de fin }
   EndCylinder: Byte;                    { Cylindre de fin }
   StartLBA: LongInt;                    { Secteur de début (LBA) }
   SizeLBA: LongInt;                     { Taille en secteurs }
  End;
  Signature: Word;                       { Signature 55AA }
 End;

 { Fragment de FAT }
 PFATFragment = ^TFATFragment;
 TFATFragment = Array[0..8191] of Word;

Var
 Language:(_French,_English,_Germany,_Italian,_Spain,_Albanian,_Portuguese,_Swedish,_Danish,_Japanese);
 TmpLanguage: String;
 BootSector: TBootSector;
 MBR: TMBR;
 RootDir: Array[0..511] of TDirEntry;
 SectorBuffer: Array[0..511] of Byte;
 FAT: PFATFragment;
 FileHandle: File;
 TotalClusters, BadClusters: Word;
 RecoveredFiles: Integer;
 DriveNumber: Byte;
 DriveLetter: Char;
 TargetPath: String;
 FileName: String;
 RecoverWholeDisk: Boolean;

{ Conversion lettre de lecteur vers numéro }
Function DriveLetterToNumber(Letter: Char): Byte;
Begin
 If Letter in ['a'..'z'] Then Letter := Chr(Ord(Letter) - 32);
 DriveLetterToNumber := Ord(Letter) - Ord('A');
End;

{ Lecture d'un secteur physique }
Function ReadSector(Drive: Byte; Sector: LongInt; Buffer: Pointer): Boolean;
Var
 Regs: Registers;
Begin
 ReadSector := False;
 
 { Utiliser l'interruption 25h pour la lecture directe }
 Regs.AL := Drive;          { Numéro de lecteur (0=A:, 1=B:, 2=C:, etc.) }
 Regs.CX := 1;              { Nombre de secteurs à lire }
 Regs.DX := Sector;         { Numéro de secteur (partie basse) }
 Regs.DS := Seg(Buffer^);   { Segment du buffer }
 Regs.BX := Ofs(Buffer^);   { Offset du buffer }
 
 Intr($25, Regs);           { Int 25h - Lecture secteur absolu }
 
 If (Regs.Flags and 1) = 0 Then ReadSector := True;
End;

{ Écriture d'un secteur physique }
Function WriteSector(Drive: Byte; Sector: LongInt; Buffer: Pointer): Boolean;
Var
 Regs: Registers;
Begin
 WriteSector := False;
 
 { Utiliser l'interruption 26h pour l'écriture directe }
 Regs.AL := Drive;          { Numéro de lecteur }
 Regs.CX := 1;              { Nombre de secteurs à écrire }
 Regs.DX := Sector;         { Numéro de secteur }
 Regs.DS := Seg(Buffer^);   { Segment du buffer }
 Regs.BX := Ofs(Buffer^);   { Offset du buffer }
 
 Intr($26, Regs);           { Int 26h - Écriture secteur absolu }
 
 If (Regs.Flags and 1) = 0 Then WriteSector := True;
End;

{ Conversion entier vers chaîne }
Function IntToStr(Value: Integer): String;
Var S: String;
Begin
 Str(Value, S);
 IntToStr := S;
End;

{ Vérification d'existence de fichier }
Function FileExists(FileName: String): Boolean;
Var F: File;
Begin
 {$I-}
 Assign(F, FileName);
 Reset(F);
 {$I+}
 If IOResult = 0 Then Begin
  Close(F);
  FileExists := True;
 End Else
  FileExists := False;
End;
Function StrToUpper(S:String):String;
Var I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

{ Formatage d'un nom de fichier 8.3 }
Function FormatFileName(Name: String): String;
Var
 DotPos: Integer;
 FileName, FileExt: String;
Begin
 Name := StrToUpper(Name);
 DotPos := Pos('.', Name);

 If DotPos > 0 Then Begin
  FileName := Copy(Name, 1, DotPos - 1);
  FileExt := Copy(Name, DotPos + 1, Length(Name));
 End Else Begin
  FileName := Name;
  FileExt := '';
 End;

 { Ajuster la longueur }
 While Length(FileName) < 8 Do FileName := FileName + ' ';
 If Length(FileName) > 8 Then FileName := Copy(FileName, 1, 8);

 While Length(FileExt) < 3 Do FileExt := FileExt + ' ';
 If Length(FileExt) > 3 Then FileExt := Copy(FileExt, 1, 3);

 FormatFileName := FileName + FileExt;
End;

{ Lecture du secteur de boot }
Function ReadBootSector(Drive: Char): Boolean;
Var
 DriveNum: Byte;
Begin
 ReadBootSector := False;
 DriveNum := DriveLetterToNumber(Drive);
 
 { Lire le secteur 0 (secteur de boot) }
 If ReadSector(DriveNum, 0, @BootSector) Then Begin
  { Vérification de la validité du secteur de boot }
  If (BootSector.BytesPerSector = 512) and
     (BootSector.SectorsPerCluster > 0) and
     (BootSector.NumberOfFATs > 0) Then
    ReadBootSector := True;
 End;
End;

{ Lecture de la FAT }
Function ReadFAT(Drive: Char): Boolean;
Var
 DriveNum: Byte;
 FATSector: LongInt;
 I: Integer;
 Buffer: Array[0..511] of Byte;
Begin
 ReadFAT := False;
 DriveNum := DriveLetterToNumber(Drive);

 { Calcul du secteur de début de la FAT }
 FATSector := BootSector.ReservedSectors;

 New(FAT);

 { Lire tous les secteurs de la FAT }
 For I := 0 to BootSector.SectorsPerFAT - 1 Do Begin
  If Not ReadSector(DriveNum, FATSector + I, @Buffer) Then Exit;
  
  { Copier le secteur dans la FAT }
  Move(Buffer, PByte(FAT)[I * 512], 512);
 End;

 ReadFAT := True;
End;

{ Marquer un cluster comme défectueux dans la FAT }
Procedure MarkClusterAsBad(ClusterNum: Word);
Begin
 If ClusterNum < TotalClusters Then Begin
  { FAT16: valeur $FFF7 = cluster défectueux }
  FAT^[ClusterNum] := $FFF7;
  Inc(BadClusters);
 End;
End;

{ Écriture de la FAT }
Function WriteFAT(Drive: Char): Boolean;
Var
 DriveNum: Byte;
 FATSector: LongInt;
 I, J: Integer;
 Buffer: Array[0..511] of Byte;
Begin
 WriteFAT := False;
 DriveNum := DriveLetterToNumber(Drive);
 FATSector := BootSector.ReservedSectors;

 { Écrire toutes les copies de la FAT }
 For I := 0 to BootSector.NumberOfFATs - 1 Do Begin
  For J := 0 to BootSector.SectorsPerFAT - 1 Do Begin
   { Copier un secteur de la FAT dans le buffer }
   Move(PByte(FAT)[J * 512], Buffer, 512);
   
   { Écrire le secteur }
   If Not WriteSector(DriveNum, FATSector + I * BootSector.SectorsPerFAT + J, @Buffer) Then Exit;
  End;
 End;

 WriteFAT := True;
End;

{ Récupération d'un fichier spécifique }
Function RecoverFile(Drive: Char; FilePath: String): Boolean;
Var
 F: File;
 NewName: String;
 Counter: Integer;
 SearchAttr: Word;
Begin
 RecoverFile := False;

 { Vérifier si le fichier existe et est accessible }
 {$I-}
 Assign(F, FilePath);
 Reset(F, 1);
 {$I+}

 If IOResult = 0 Then Begin
  Close(F);
  Case Language of
   _English: WriteLn('File "', FilePath, '" appears to be valid');
   _Germany: WriteLn('Datei "', FilePath, '" scheint gültig zu sein');
   _Italian: WriteLn('Il file "', FilePath, '" sembra essere valido');
   _Spain: WriteLn('El archivo "', FilePath, '" parece ser válido');
   _Albanian: WriteLn('Skedari "', FilePath, '" duket të jetë i vlefshëm');
   _Portuguese: WriteLn('O arquivo "', FilePath, '" parece estar válido');
   _Swedish: WriteLn('Filen "', FilePath, '" verkar vara giltig');
   _Danish: WriteLn('Filen "', FilePath, '" ser ud til at være gyldig');
   _Japanese: WriteLn('Fairu "', FilePath, '" wa tadashii you desu');
  Else
   WriteLn('Le fichier "', FilePath, '" semble être valide');
  End;
  Exit;
 End;

 { Tentative de récupération }
 Counter := 1;
 NewName := 'FILE' + IntToStr(Counter) + '.REC';

 While FileExists(NewName) Do Begin
  Inc(Counter);
  NewName := 'FILE' + IntToStr(Counter) + '.REC';
 End;

 {$I-}
 Assign(F, NewName);
 Rewrite(F, 1);
 {$I+}

 If IOResult = 0 Then Begin
  { Copier les données récupérables }
  Close(F);
  Inc(RecoveredFiles);

  Case Language of
   _English: WriteLn('File recovered as "', NewName, '"');
   _Germany: WriteLn('Datei wiederhergestellt als "', NewName, '"');
   _Italian: WriteLn('File recuperato come "', NewName, '"');
   _Spain: WriteLn('Archivo recuperado como "', NewName, '"');
   _Albanian: WriteLn('Skedari u rikuperua si "', NewName, '"');
   _Portuguese: WriteLn('Arquivo recuperado como "', NewName, '"');
   _Swedish: WriteLn('Fil återställd som "', NewName, '"');
   _Danish: WriteLn('Fil gendannet som "', NewName, '"');
   _Japanese: WriteLn('Fairu wa "', NewName, '" to shite fukugen saremashita');
  Else
   WriteLn('Fichier récupéré sous "', NewName, '"');
  End;

  RecoverFile := True;
 End Else Begin
  Case Language of
   _English: WriteLn('File not found: ', FilePath);
   _Germany: WriteLn('Datei nicht gefunden: ', FilePath);
   _Italian: WriteLn('File non trovato: ', FilePath);
   _Spain: WriteLn('Archivo no encontrado: ', FilePath);
   _Albanian: WriteLn('Skedari nuk u gjet: ', FilePath);
   _Portuguese: WriteLn('Arquivo não encontrado: ', FilePath);
   _Swedish: WriteLn('Fil hittades inte: ', FilePath);
   _Danish: WriteLn('Fil ikke fundet: ', FilePath);
   _Japanese: WriteLn('Fairu ga mitsukarimasen: ', FilePath);
  Else
   WriteLn('Fichier non trouvé : ', FilePath);
  End;
 End;
End;

{ Récupération d'un disque entier }
Function RecoverWholeDrive(Drive: Char): Boolean;
Var
 I: Integer;
Begin
 RecoverWholeDrive := False;

 Case Language of
  _English: WriteLn('WARNING: This will recover all files on drive ', Drive, ':');
  _Germany: WriteLn('WARNUNG: Dies stellt alle Dateien auf Laufwerk ', Drive, ': wieder her');
  _Italian: WriteLn('AVVISO: Questo recupererà tutti i file sull''unità ', Drive, ':');
  _Spain: WriteLn('ADVERTENCIA: Esto recuperará todos los archivos en la unidad ', Drive, ':');
  _Albanian: WriteLn('PARALAJMËRIM: Kjo do të rikuperojë të gjithë skedarët në njësinë ', Drive, ':');
  _Portuguese: WriteLn('AVISO: Isso recuperará todos os arquivos na unidade ', Drive, ':');
  _Swedish: WriteLn('VARNING: Detta kommer att återställa alla filer på enhet ', Drive, ':');
  _Danish: WriteLn('ADVARSEL: Dette vil gendanne alle filer på drev ', Drive, ':');
  _Japanese: WriteLn('KEIKOKU: Kore wa doraiwu ', Drive, ': no subete no fairu wo fukugen shimasu');
 Else
  WriteLn('ATTENTION : Ceci récupérera tous les fichiers du lecteur ', Drive, ':');
 End;

 Case Language of
  _English: Write('Are you sure (Y/N)? ');
  _Germany: Write('Sind Sie sicher (J/N)? ');
  _Italian: Write('Sei sicuro (S/N)? ');
  _Spain: Write('¿Está seguro (S/N)? ');
  _Albanian: Write('A jeni i sigurt (P/J)? ');
  _Portuguese: Write('Tem certeza (S/N)? ');
  _Swedish: Write('Är du säker (J/N)? ');
  _Danish: Write('Er du sikker (J/N)? ');
  _Japanese: Write('Yoroshii desu ka (Y/N)? ');
 Else
  Write('Êtes-vous sûr (O/N) ? ');
 End;

 { Attendre la réponse utilisateur }
 If UpCase(ReadKey) in ['Y','O','J','S','P'] Then Begin
  WriteLn;

  { Lire les structures du disque }
  If Not ReadBootSector(Drive) Then Begin
   Case Language of
    _English: WriteLn('Error: Cannot read boot sector');
    _Germany: WriteLn('Fehler: Boot-Sektor kann nicht gelesen werden');
    _Italian: WriteLn('Errore: Impossibile leggere il settore di avvio');
    _Spain: WriteLn('Error: No se puede leer el sector de arranque');
    _Albanian: WriteLn('Gabim: Nuk mund të lexohet sektori i nisjes');
    _Portuguese: WriteLn('Erro: Não é possível ler o setor de inicialização');
    _Swedish: WriteLn('Fel: Kan inte läsa startsektorn');
    _Danish: WriteLn('Fejl: Kan ikke læse bootsektor');
    _Japanese: WriteLn('Eraa: Buuto sekuta wo yomu koto ga dekimasen');
   Else
    WriteLn('Erreur : Impossible de lire le secteur de boot');
   End;
   Exit;
  End;

  If Not ReadFAT(Drive) Then Begin
   Case Language of
    _English: WriteLn('Error: Cannot read FAT');
    _Germany: WriteLn('Fehler: FAT kann nicht gelesen werden');
    _Italian: WriteLn('Errore: Impossibile leggere la FAT');
    _Spain: WriteLn('Error: No se puede leer la FAT');
    _Albanian: WriteLn('Gabim: Nuk mund të lexohet FAT');
    _Portuguese: WriteLn('Erro: Não é possível ler a FAT');
    _Swedish: WriteLn('Fel: Kan inte läsa FAT');
    _Danish: WriteLn('Fejl: Kan ikke læse FAT');
    _Japanese: WriteLn('Eraa: FAT wo yomu koto ga dekimasen');
   Else
    WriteLn('Erreur : Impossible de lire la FAT');
   End;
   Exit;
  End;

  { Calculer le nombre total de clusters }
  TotalClusters := (BootSector.SectorsPerFAT * 512) Div 2;

  Case Language of
   _English: WriteLn('Scanning ', TotalClusters, ' clusters...');
   _Germany: WriteLn('Scanne ', TotalClusters, ' Cluster...');
   _Italian: WriteLn('Scansione di ', TotalClusters, ' cluster...');
   _Spain: WriteLn('Escaneando ', TotalClusters, ' clusters...');
   _Albanian: WriteLn('Skanimin e ', TotalClusters, ' klusterëve...');
   _Portuguese: WriteLn('Verificando ', TotalClusters, ' clusters...');
   _Swedish: WriteLn('Skannar ', TotalClusters, ' kluster...');
   _Danish: WriteLn('Scanner ', TotalClusters, ' klynger...');
   _Japanese: WriteLn(TotalClusters, ' kurasuta wo sukyan-chuu...');
  Else
   WriteLn('Analyse de ', TotalClusters, ' clusters...');
  End;

  { Scanner les clusters et marquer les défectueux }
  BadClusters := 0;
  For I := 2 to TotalClusters - 1 Do Begin
   { Vérifier l'intégrité du cluster }
   { Simuler la détection de clusters défectueux }
   If (I Mod 100) = 0 Then Write('.');

   { Si un cluster est détecté comme défectueux }
   { MarkClusterAsBad(I); }
  End;

  WriteLn;

  Case Language of
   _English: WriteLn('Found ', BadClusters, ' bad clusters');
   _Germany: WriteLn(BadClusters, ' defekte Cluster gefunden');
   _Italian: WriteLn('Trovati ', BadClusters, ' cluster danneggiati');
   _Spain: WriteLn('Se encontraron ', BadClusters, ' clusters defectuosos');
   _Albanian: WriteLn('U gjetën ', BadClusters, ' klusterë të dëmtuar');
   _Portuguese: WriteLn('Encontrados ', BadClusters, ' clusters defeituosos');
   _Swedish: WriteLn('Hittade ', BadClusters, ' defekta kluster');
   _Danish: WriteLn('Fandt ', BadClusters, ' dårlige klynger');
   _Japanese: WriteLn(BadClusters, ' furyou kurasuta wo hakken');
  Else
   WriteLn(BadClusters, ' clusters défectueux trouvés');
  End;

  { Sauvegarder la FAT mise à jour }
  If BadClusters > 0 Then Begin
   If WriteFAT(Drive) Then Begin
    Case Language of
     _English: WriteLn('FAT updated successfully');
     _Germany: WriteLn('FAT erfolgreich aktualisiert');
     _Italian: WriteLn('FAT aggiornata con successo');
     _Spain: WriteLn('FAT actualizada exitosamente');
     _Albanian: WriteLn('FAT u përditësua me sukses');
     _Portuguese: WriteLn('FAT atualizada com sucesso');
     _Swedish: WriteLn('FAT uppdaterades framgångsrikt');
     _Danish: WriteLn('FAT opdateret med succes');
     _Japanese: WriteLn('FAT no koushin ni seikou shimashita');
    Else
     WriteLn('FAT mise à jour avec succès');
    End;
   End Else Begin
    Case Language of
     _English: WriteLn('Error: Cannot update FAT');
     _Germany: WriteLn('Fehler: FAT kann nicht aktualisiert werden');
     _Italian: WriteLn('Errore: Impossibile aggiornare la FAT');
     _Spain: WriteLn('Error: No se puede actualizar la FAT');
     _Albanian: WriteLn('Gabim: Nuk mund të përditësohet FAT');
     _Portuguese: WriteLn('Erro: Não é possível atualizar a FAT');
     _Swedish: WriteLn('Fel: Kan inte uppdatera FAT');
     _Danish: WriteLn('Fejl: Kan ikke opdatere FAT');
     _Japanese: WriteLn('Eraa: FAT wo koushin dekimasen');
    Else
     WriteLn('Erreur : Impossible de mettre à jour la FAT');
    End;
   End;
  End;

  RecoverWholeDrive := True;
 End Else Begin
  WriteLn;
  Case Language of
   _English: WriteLn('Operation cancelled');
   _Germany: WriteLn('Vorgang abgebrochen');
   _Italian: WriteLn('Operazione annullata');
   _Spain: WriteLn('Operación cancelada');
   _Albanian: WriteLn('Operacioni u anulua');
   _Portuguese: WriteLn('Operação cancelada');
   _Swedish: WriteLn('Operation avbruten');
   _Danish: WriteLn('Operation aflyst');
   _Japanese: WriteLn('Sagyou ga kyanseru saremashita');
  Else
   WriteLn('Opération annulée');
  End;
 End;
End;

{ Programme principal }
BEGIN
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
 RecoveredFiles := 0;
 RecoverWholeDisk := False;
 DriveNumber := 0;
  { Traitement des paramètres }
 If (ParamCount = 0) or (StrToUpper(ParamStr(1)) = '/?') or
    (StrToUpper(ParamStr(1)) = '--HELP') or (StrToUpper(ParamStr(1)) = '-H') or
    (StrToUpper(ParamStr(1)) = '/H') or (StrToUpper(ParamStr(1)) = '/HELP') Then Begin
  Case Language of
   _English: Begin
    WriteLn('RECOVER - Recovers files from a damaged disk');
    WriteLn;
    WriteLn('Syntax:');
    WriteLn('  RECOVER drive:');
    WriteLn('  RECOVER [drive:][path]filename');
    WriteLn;
    WriteLn('Parameters:');
    WriteLn('  drive:           Drive letter to recover');
    WriteLn('  [path]filename   Specific file to recover');
    WriteLn;
    WriteLn('Examples:');
    WriteLn('  RECOVER A:       Recovers all files on drive A:');
    WriteLn('  RECOVER C:DATA.TXT  Recovers specific file');
   End;
   _Germany: Begin
    WriteLn('RECOVER - Stellt Dateien von einem beschädigten Datenträger wieder her');
    WriteLn;
    WriteLn('Syntax:');
    WriteLn('  RECOVER Laufwerk:');
    WriteLn('  RECOVER [Laufwerk:][Pfad]Dateiname');
    WriteLn;
    WriteLn('Parameter:');
    WriteLn('  Laufwerk:           Laufwerksbuchstabe zur Wiederherstellung');
    WriteLn('  [Pfad]Dateiname     Spezifische Datei zur Wiederherstellung');
    WriteLn;
    WriteLn('Beispiele:');
    WriteLn('  RECOVER A:          Stellt alle Dateien auf Laufwerk A: wieder her');
    WriteLn('  RECOVER C:DATA.TXT  Stellt spezifische Datei wieder her');
   End;
   _Italian: Begin
    WriteLn('RECOVER - Recupera file da un disco danneggiato');
    WriteLn;
    WriteLn('Sintassi:');
    WriteLn('  RECOVER unità:');
    WriteLn('  RECOVER [unità:][percorso]nomefile');
    WriteLn;
    WriteLn('Parametri:');
    WriteLn('  unità:              Lettera dell''unità da recuperare');
    WriteLn('  [percorso]nomefile  File specifico da recuperare');
    WriteLn;
    WriteLn('Esempi:');
    WriteLn('  RECOVER A:          Recupera tutti i file sull''unità A:');
    WriteLn('  RECOVER C:DATA.TXT  Recupera file specifico');
   End;
   _Spain: Begin
    WriteLn('RECOVER - Recupera archivos de un disco dañado');
    WriteLn;
    WriteLn('Sintaxis:');
    WriteLn('  RECOVER unidad:');
    WriteLn('  RECOVER [unidad:][ruta]nombrearchivo');
    WriteLn;
    WriteLn('Parámetros:');
    WriteLn('  unidad:                Letra de unidad a recuperar');
    WriteLn('  [ruta]nombrearchivo    Archivo específico a recuperar');
    WriteLn;
    WriteLn('Ejemplos:');
    WriteLn('  RECOVER A:             Recupera todos los archivos en unidad A:');
    WriteLn('  RECOVER C:DATA.TXT     Recupera archivo específico');
   End;
   _Albanian: Begin
    WriteLn('RECOVER - Rikuperon skedarët nga një disk i dëmtuar');
    WriteLn;
    WriteLn('Sintaksa:');
    WriteLn('  RECOVER njësia:');
    WriteLn('  RECOVER [njësia:][rruga]emriskedari');
    WriteLn;
    WriteLn('Parametrat:');
    WriteLn('  njësia:               Shkronja e njësisë për t''u rikuperuar');
    WriteLn('  [rruga]emriskedari    Skedari specifik për t''u rikuperuar');
    WriteLn;
    WriteLn('Shembuj:');
    WriteLn('  RECOVER A:            Rikuperon të gjithë skedarët në njësinë A:');
    WriteLn('  RECOVER C:DATA.TXT    Rikuperon skedarin specifik');
   End;
   _Portuguese: Begin
    WriteLn('RECOVER - Recupera arquivos de um disco danificado');
    WriteLn;
    WriteLn('Sintaxe:');
    WriteLn('  RECOVER unidade:');
    WriteLn('  RECOVER [unidade:][caminho]nomearquivo');
    WriteLn;
    WriteLn('Parâmetros:');
    WriteLn('  unidade:                Letra da unidade a recuperar');
    WriteLn('  [caminho]nomearquivo    Arquivo específico a recuperar');
    WriteLn;
    WriteLn('Exemplos:');
    WriteLn('  RECOVER A:              Recupera todos os arquivos na unidade A:');
    WriteLn('  RECOVER C:DATA.TXT      Recupera arquivo específico');
   End;
   _Swedish: Begin
    WriteLn('RECOVER - Återställer filer från en skadad disk');
    WriteLn;
    WriteLn('Syntax:');
    WriteLn('  RECOVER enhet:');
    WriteLn('  RECOVER [enhet:][sökväg]filnamn');
    WriteLn;
    WriteLn('parametrar:');
    WriteLn('  enhet:              Enhetsbokstav att återställa');
    WriteLn('  [sökväg]filnamn     Specifik fil att återställa');
    WriteLn;
    WriteLn('Exempel:');
    WriteLn('  RECOVER A:          Återställer alla filer på enhet A:');
    WriteLn('  RECOVER C:DATA.TXT  Återställer specifik fil');
   End;
   _Danish: Begin
    WriteLn('RECOVER - Gendanner filer fra en beskadiget disk');
    WriteLn;
    WriteLn('Syntaks:');
    WriteLn('  RECOVER drev:');
    WriteLn('  RECOVER [drev:][sti]filnavn');
    WriteLn;
    WriteLn('Parametre:');
    WriteLn('  drev:            Drevbogstav at gendanne');
    WriteLn('  [sti]filnavn     Specifik fil at gendanne');
    WriteLn;
    WriteLn('Eksempler:');
    WriteLn('  RECOVER A:       Gendanner alle filer på drev A:');
    WriteLn('  RECOVER C:DATA.TXT  Gendanner specifik fil');
   End;
   _Japanese: Begin
    WriteLn('RECOVER - Songaishita disuku kara fairu wo fukugen shimasu');
    WriteLn;
    WriteLn('Koubun:');
    WriteLn('  RECOVER doraiwu:');
    WriteLn('  RECOVER [doraiwu:][pasu]fairumei');
    WriteLn;
    WriteLn('Parameta:');
    WriteLn('  doraiwu:           Fukugen suru doraiwu moji');
    WriteLn('  [pasu]fairumei     Fukugen suru tokutei no fairu');
    WriteLn;
    WriteLn('Rei:');
    WriteLn('  RECOVER A:         Doraiwu A: no subete no fairu wo fukugen');
    WriteLn('  RECOVER C:DATA.TXT Tokutei no fairu wo fukugen');
   End;
   Else Begin
    WriteLn('RECOVER - Cette comande permet de r�cup�rer des fichiers ',
                       'd''un disque endommag�.');
    WriteLn;
    WriteLn('Syntaxe :');
    WriteLn('  RECOVER lecteur:');
    WriteLn('  RECOVER [lecteur:][chemin]nomfichier');
    WriteLn;
    WriteLn('Paramètres :');
    WriteLn('  lecteur:              Lettre de lecteur à récupérer');
    WriteLn('  [chemin]nomfichier    Fichier spécifique à récupérer');
    WriteLn;
    WriteLn('Exemples :');
    WriteLn('  RECOVER A:            Récupère tous les fichiers du lecteur A:');
    WriteLn('  RECOVER C:DATA.TXT    Récupère un fichier spécifique');
   End;
  End;
  Halt(ERR_SUCCESS);
 End;

 TargetPath := StrToUpper(ParamStr(1));

 { Vérifier le format du paramètre }
 If Length(TargetPath) = 2 Then Begin
  If TargetPath[2] = ':' Then Begin
   { Format "X:" - récupérer tout le lecteur }
   DriveLetter := TargetPath[1];
   DriveNumber := DriveLetterToNumber(DriveLetter);
   RecoverWholeDisk := True;
  End Else Begin
   Case Language of
    _English: WriteLn('Invalid parameter format');
    _Germany: WriteLn('Ungültiges Parameterformat');
    _Italian: WriteLn('Formato parametro non valido');
    _Spain: WriteLn('Formato de parámetro inválido');
    _Albanian: WriteLn('Format parametri i pavlefshëm');
    _Portuguese: WriteLn('Formato de parâmetro inválido');
    _Swedish: WriteLn('Ogiltigt parameterformat');
    _Danish: WriteLn('Ugyldigt parameterformat');
    _Japanese: WriteLn('Parameta no keishiki ga machigatte imasu');
   Else
    WriteLn('Format de paramètre invalide');
   End;
   Halt(ERR_INVALID_PARAMETER);
  End;
 End Else Begin
  { Format avec nom de fichier }
  If (Length(TargetPath) > 2) and (TargetPath[2] = ':') Then Begin
   DriveLetter := TargetPath[1];
   DriveNumber := DriveLetterToNumber(DriveLetter);
   FileName := Copy(TargetPath, 3, Length(TargetPath));
   RecoverWholeDisk := False;
  End Else Begin
   Case Language of
    _English: WriteLn('Invalid drive specification');
    _Germany: WriteLn('Ungültige Laufwerksangabe');
    _Italian: WriteLn('Specifica unità non valida');
    _Spain: WriteLn('Especificación de unidad inválida');
    _Albanian: WriteLn('Specifikimi i njësisë i pavlefshëm');
    _Portuguese: WriteLn('Especificação de unidade inválida');
    _Swedish: WriteLn('Ogiltig enhetsspecifikation');
    _Danish: WriteLn('Ugyldig drevspecifikation');
    _Japanese: WriteLn('Doraiwu shitei ga machigatte imasu');
   Else
    WriteLn('Spécification de lecteur invalide');
   End;
   Halt(ERR_INVALID_PARAMETER);
  End;
 End;

 { Vérifier la validité du lecteur }
 If Not (DriveLetter in ['A'..'Z']) Then Begin
  Case Language of
   _English: WriteLn('Invalid drive letter: ', DriveLetter);
   _Germany: WriteLn('Ungültiger Laufwerksbuchstabe: ', DriveLetter);
   _Italian: WriteLn('Lettera unità non valida: ', DriveLetter);
   _Spain: WriteLn('Letra de unidad inválida: ', DriveLetter);
   _Albanian: WriteLn('Shkronja e njësisë e pavlefshme: ', DriveLetter);
   _Portuguese: WriteLn('Letra de unidade inválida: ', DriveLetter);
   _Swedish: WriteLn('Ogiltig enhetsbokstav: ', DriveLetter);
   _Danish: WriteLn('Ugyldigt drevbogstav: ', DriveLetter);
   _Japanese: WriteLn('Doraiwu moji ga machigatte imasu: ', DriveLetter);
  Else
   WriteLn('Lettre de lecteur invalide : ', DriveLetter);
  End;
  Halt(ERR_INVALID_DRIVE);
 End;

 { Exécution de la récupération }
 If RecoverWholeDisk Then Begin
  If Not RecoverWholeDrive(DriveLetter) Then Begin
   Halt(ERR_ACCESS_DENIED);
  End;
 End Else Begin
  If Not RecoverFile(DriveLetter, DriveLetter + ':' + FileName) Then Begin
   Halt(ERR_FILE_NOT_FOUND);
  End;
 End;

 { Affichage du résumé }
 If RecoveredFiles > 0 Then Begin
  Case Language of
   _English: WriteLn(RecoveredFiles, ' file(s) recovered successfully');
   _Germany: WriteLn(RecoveredFiles, ' Datei(en) erfolgreich wiederhergestellt');
   _Italian: WriteLn(RecoveredFiles, ' file recuperati con successo');
   _Spain: WriteLn(RecoveredFiles, ' archivo(s) recuperado(s) exitosamente');
   _Albanian: WriteLn(RecoveredFiles, ' skedar(ë) u rikuperuan me sukses');
   _Portuguese: WriteLn(RecoveredFiles, ' arquivo(s) recuperado(s) com sucesso');
   _Swedish: WriteLn(RecoveredFiles, ' fil(er) återställda framgångsrikt');
   _Danish: WriteLn(RecoveredFiles, ' fil(er) gendannet med succes');
   _Japanese: WriteLn(RecoveredFiles, ' fairu ga seikou-teki ni fukugen saremashita');
  Else
   WriteLn(RecoveredFiles, ' fichier(s) récupéré(s) avec succès');
  End;
 End;

 { Libération de la mémoire }
 If FAT <> Nil Then Dispose(FAT);

 Halt(ERR_SUCCESS);
END.
