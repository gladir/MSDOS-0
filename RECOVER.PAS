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
 { Structure du secteur de d‚marrage FAT }
 TBootSector = Record
  JumpCode: Array[0..2] of Byte;         { Code de saut vers le code de boot (E9 xx xx ou EB xx 90) }
  OEMName: Array[0..7] of Char;          { Nom du systŠme de fichiers (ex: "MSDOS5.0") }
  BytesPerSector: Word;                  { Nombre d'octets par secteur (g‚n‚ralement 512) }
  SectorsPerCluster: Byte;               { Nombre de secteurs par cluster (1, 2, 4, 8, 16, 32, 64, 128) }
  ReservedSectors: Word;                 { Nombre de secteurs r‚serv‚s (g‚n‚ralement 1 pour FAT12/16) }
  NumberOfFATs: Byte;                    { Nombre de copies de la FAT (g‚n‚ralement 2) }
  RootEntries: Word;                     { Nombre d'entr‚es dans le r‚pertoire racine (0 pour FAT32) }
  TotalSectors: Word;                    { Nombre total de secteurs (0 si > 65535, voir TotalSectorsBig) }
  MediaDescriptor: Byte;                 { Descripteur de m‚dia (F0=disquette, F8=disque dur, etc.) }
  SectorsPerFAT: Word;                   { Nombre de secteurs par FAT (0 pour FAT32) }
  SectorsPerTrack: Word;                 { Nombre de secteurs par piste (g‚om‚trie physique) }
  NumberOfHeads: Word;                   { Nombre de tˆtes (g‚om‚trie physique) }
  HiddenSectors: LongInt;                { Nombre de secteurs cach‚s avant la partition }
  TotalSectorsBig: LongInt;              { Nombre total de secteurs si TotalSectors = 0 }
 End;

 { Entr‚e de r‚pertoire FAT }
 TDirEntry = Record
  Name: Array[0..10] of Char;            { Nom de fichier 8.3 (8 caractŠres + 3 extensions, sans point) }
  Attr: Byte;                            { Attributs:
                                             bit 0=lecture seulement,
                                                 1=cach‚,
                                                 2=systŠme,
                                                 3=‚tiquette,
                                                 4=r‚pertoire,
                                                 5=archive }
  Reserved: Array[0..9] of Byte;         { Octets r‚serv‚s (NT, temps cr‚ation, etc.) }
  Time: Word;                            { Heure de derniŠre modification (format packed) }
  Date: Word;                            { Date de derniŠre modification (format packed) }
  StartCluster: Word;                    { Num‚ro du premier cluster du fichier }
  Size: LongInt;                         { Taille du fichier en octets }
 End;

 { Enregistrement de d‚marrage principal (Master Boot Record) }
 TMBR = Record
  BootCode: Array[0..445] of Byte;       { Code de boot }
  Partition: Array[0..3] of Record       { Table des partitions }
   Status: Byte;                         { 00=inactive, 80=active }
   StartHead: Byte;                      { Tˆte de d‚but }
   StartSector: Byte;                    { Secteur de d‚but (bits 0-5) + cylindre haut (bits 6-7) }
   StartCylinder: Byte;                  { Cylindre de d‚but (bits bas) }
   PartType: Byte;                       { Type de partition (01=FAT12, 04=FAT16, etc.) }
   EndHead: Byte;                        { Tˆte de fin }
   EndSector: Byte;                      { Secteur de fin }
   EndCylinder: Byte;                    { Cylindre de fin }
   StartLBA: LongInt;                    { Secteur de d‚but (LBA) }
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
 FileIMG: File;
 UseImageFile: Boolean;
 ImageFileName: String;
 TotalClusters, BadClusters: Word;
 RecoveredFiles: Integer;
 DriveNumber: Byte;
 DriveLetter: Char;
 TargetPath: String;
 FileName: String;
 RecoverWholeDisk: Boolean;

 { Conversion lettre de lecteur vers num‚ro }
Function DriveLetterToNumber(Letter: Char): Byte;Begin
 If Letter in ['a'..'z'] Then Letter := Chr(Ord(Letter) - 32);
 DriveLetterToNumber := Ord(Letter) - Ord('A');
End;

 { Lecture d'un secteur physique }
Function ReadSector(Drive: Byte; Sector: LongInt; Buffer: Pointer): Boolean;
Var
 Regs: Registers;
 ByteReaded: Integer;
Begin
 ReadSector := False;

 If UseImageFile Then Begin
  { Lecture depuis un fichier image }
  {$I-}
  Seek(FileIMG, Sector);
  BlockRead(FileIMG, Buffer^, 512, ByteReaded);
  {$I+}
  If (IOResult = 0) and (ByteReaded = 512) Then ReadSector := True;
 End Else Begin
  { Utiliser l'interruption 25h pour la lecture directe }
  Regs.AL := Drive;          { Num‚ro de lecteur (0=A:, 1=B:, 2=C:, etc.) }
  Regs.CX := 1;              { Nombre de secteurs Ã  lire }
  Regs.DX := Sector;         { Num‚ro de secteur (partie basse) }
  Regs.DS := Seg(Buffer^);   { Segment du buffer }
  Regs.BX := Ofs(Buffer^);   { Offset du buffer }
  Intr($25, Regs);           { Int 25h - Lecture secteur absolu }
  If (Regs.Flags and 1) = 0 Then ReadSector := True;
 End;
End;

 { criture d'un secteur physique }
Function WriteSector(Drive: Byte; Sector: LongInt; Buffer: Pointer): Boolean;
Var
 Regs: Registers;
 ByteWritten: Integer;
Begin
 WriteSector := False;
 If UseImageFile Then Begin
  { criture vers un fichier image }
  {$I-}
  Seek(FileIMG, Sector);
  BlockWrite(FileIMG, Buffer^, 512, ByteWritten);
  {$I+}
  If (IOResult = 0) and (ByteWritten = 512) Then WriteSector := True;
 End
  Else
 Begin
  { Utiliser l'interruption 26h pour l'‚criture directe }
  Regs.AL := Drive;          { Num‚ro de lecteur }
  Regs.CX := 1;              { Nombre de secteurs … ‚crire }
  Regs.DX := Sector;         { Num‚ro de secteur }
  Regs.DS := Seg(Buffer^);   { Segment du buffer }
  Regs.BX := Ofs(Buffer^);   { Offset du buffer }
  Intr($26, Regs);           { Int 26h - criture secteur absolu }
  If (Regs.Flags and 1) = 0 Then WriteSector := True;
 End;
End;

 { Ouverture d'un fichier image de disque }
Function OpenImageFile(FileName:String):Boolean;Begin
 OpenImageFile := False;
 {$I-}Assign(FileIMG, FileName);
 Reset(FileIMG, 1);{$I+}
 If IOResult=0 Then Begin
  UseImageFile := True;
  ImageFileName := FileName;
  OpenImageFile := True;
 End;
End;

{ Fermeture du fichier image }
Procedure CloseImageFile;Begin
 If UseImageFile Then Begin
  {$I-}
  Close(FileIMG);
  {$I+}
  UseImageFile := False;
 End;
End;

 { Conversion entier vers chaÃ®ne }
Function IntToStr(Value: Integer): String;
Var
 S: String;
Begin
 Str(Value, S);
 IntToStr := S;
End;

 { V‚rification d'existence de fichier }
Function FileExists(FileName:String):Boolean;
Var
 F: File;
Begin
 {$I-}Assign(F, FileName);
 Reset(F); {$I+}
 If IOResult = 0 Then Begin
  Close(F);
  FileExists := True;
 End
  Else
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
Function FormatFileName(Name:String):String;
Var
 DotPos: Integer;
 FileName, FileExt: String;
Begin
 Name := StrToUpper(Name);
 DotPos := Pos('.', Name);
 If DotPos > 0 Then Begin
  FileName := Copy(Name, 1, DotPos - 1);
  FileExt := Copy(Name, DotPos + 1, Length(Name));
 End
  Else
 Begin
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

 { Lecture du secteur de d‚marrage }
Function ReadBootSector(Drive: Char): Boolean;
Var
 DriveNum: Byte;
Begin
 ReadBootSector := False;
 DriveNum := DriveLetterToNumber(Drive);
  { Lire le secteur 0 (secteur de d‚marrage) }
 If ReadSector(DriveNum, 0, @BootSector) Then Begin
  { V‚rification de la validit‚ du secteur de d‚marrage }
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
Begin
 ReadFAT := False;
 DriveNum := DriveLetterToNumber(Drive);
  { Calcul du secteur de d‚but de la FAT }
 FATSector := BootSector.ReservedSectors;
 New(FAT);
  { Lire tous les secteurs de la FAT directement }
 For I := 0 to BootSector.SectorsPerFAT - 1 Do Begin
  If Not ReadSector(DriveNum, FATSector + I, @FAT^[I * 256]) Then Exit;
 End;
 ReadFAT := True;
End;

 { Marquer un unit‚ d'allocation comme d‚fectueux dans la FAT }
Procedure MarkClusterAsBad(ClusterNum:Word);Begin
 If ClusterNum < TotalClusters Then Begin
   { FAT16: valeur $FFF7 = unit‚ d'allocation d‚fectueux }
  FAT^[ClusterNum] := $FFF7;
  Inc(BadClusters);
 End;
End;

{ criture de la FAT }
Function WriteFAT(Drive: Char): Boolean;
Var
 DriveNum: Byte;
 FATSector: LongInt;
 I, J: Integer;
Begin
 WriteFAT := False;
 DriveNum := DriveLetterToNumber(Drive);
 FATSector := BootSector.ReservedSectors;
  { crire toutes les copies de la FAT }
 For I := 0 to BootSector.NumberOfFATs - 1 Do Begin
  For J := 0 to BootSector.SectorsPerFAT - 1 Do Begin
   { crire directement depuis la FAT }
   If Not WriteSector(DriveNum, FATSector + I * BootSector.SectorsPerFAT + J, @FAT^[J * 256]) Then Exit;
  End;
 End;
 WriteFAT := True;
End;

{ R‚cup‚ration d'un fichier sp‚cifique }
Function RecoverFile(Drive: Char; FilePath: String): Boolean;
Var
 F: File;
 NewName: String;
 Counter: Integer;
 SearchAttr: Word;
Begin
 RecoverFile := False;
  { V‚rifier si le fichier existe et est accessible }
 {$I-} Assign(F, FilePath);
 Reset(F, 1);{$I+}
 If IOResult = 0 Then Begin
  Close(F);
  Case Language of
   _English: WriteLn('File "', FilePath, '" appears to be valid');
   _Germany: WriteLn('Datei "', FilePath, '" scheint gltig zu sein');
   _Italian: WriteLn('Il file "', FilePath, '" sembra essere valido');
   _Spain: WriteLn('El archivo "', FilePath, '" parece ser v lido');
   _Albanian: WriteLn('Skedari "', FilePath, '" duket t‰ jet‰ i vlefsh‰m');
   _Portuguese: WriteLn('O arquivo "', FilePath, '" parece estar v lido');
   _Swedish: WriteLn('Filen "', FilePath, '" verkar vara giltig');
   _Danish: WriteLn('Filen "', FilePath, '" ser ud til at vaere gyldig');
   _Japanese: WriteLn('Fairu "', FilePath, '" wa tadashii you desu');
  Else WriteLn('Le fichier "', FilePath, '" semble ˆtre valide');
  End;
  Exit;
 End;
  { Tentative de r‚cup‚ration }
 Counter := 1;
 NewName := 'FILE' + IntToStr(Counter) + '.REC';
 While FileExists(NewName) Do Begin
  Inc(Counter);
  NewName := 'FILE' + IntToStr(Counter) + '.REC';
 End;
 {$I-} Assign(F, NewName);
 Rewrite(F, 1); {$I+}
 If IOResult = 0 Then Begin
  { Copier les donn‚es r‚cup‚rables }
  Close(F);
  Inc(RecoveredFiles);
  Case Language of
   _English: WriteLn('File recovered as "', NewName, '"');
   _Germany: WriteLn('Datei wiederhergestellt als "', NewName, '"');
   _Italian: WriteLn('File recuperato come "', NewName, '"');
   _Spain: WriteLn('Archivo recuperado como "', NewName, '"');
   _Albanian: WriteLn('Skedari u rikuperua si "', NewName, '"');
   _Portuguese: WriteLn('Arquivo recuperado como "', NewName, '"');
   _Swedish: WriteLn('Fil †terst„lld som "', NewName, '"');
   _Danish: WriteLn('Fil gendannet som "', NewName, '"');
   _Japanese: WriteLn('Fairu wa "', NewName, '" to shite fukugen saremashita');
   Else WriteLn('Fichier r‚cup‚r‚ sous "', NewName, '"');
  End;
  RecoverFile := True;
 End
  Else
 Begin
  Case Language of
   _English: WriteLn('File not found: ', FilePath);
   _Germany: WriteLn('Datei nicht gefunden: ', FilePath);
   _Italian: WriteLn('File non trovato: ', FilePath);
   _Spain: WriteLn('Archivo no encontrado: ', FilePath);
   _Albanian: WriteLn('Skedari nuk u gjet: ', FilePath);
   _Portuguese: WriteLn('Arquivo nao encontrado: ', FilePath);
   _Swedish: WriteLn('Fil hittades inte: ', FilePath);
   _Danish: WriteLn('Fil ikke fundet: ', FilePath);
   _Japanese: WriteLn('Fairu ga mitsukarimasen: ', FilePath);
  Else
   WriteLn('Fichier non trouv‚ : ', FilePath);
  End;
 End;
End;

 { R‚cup‚ration d'un disque entier }
Function RecoverWholeDrive(Drive: Char): Boolean;
Var
 I: Integer;
Begin
 RecoverWholeDrive := False;
 Case Language of
  _English: WriteLn('WARNING: This will recover all files on drive ', Drive, ':');
  _Germany: WriteLn('WARNUNG: Dies stellt alle Dateien auf Laufwerk ', Drive, ': wieder her');
  _Italian: WriteLn('AVVISO: Questo recuperer… tutti i file sull''unit… ', Drive, ':');
  _Spain: WriteLn('ADVERTENCIA: Esto recuperar  todos los archivos en la unidad ', Drive, ':');
  _Albanian: WriteLn('PARALAJMERIM: Kjo do t‰ rikuperoj‰ t‰ gjith‰ skedar‰t n‰ nj‰sin‰ ', Drive, ':');
  _Portuguese: WriteLn('AVISO: Isso recuperar  todos os arquivos na unidade ', Drive, ':');
  _Swedish: WriteLn('VARNING: Detta kommer att †terst„lla alla filer p† enhet ', Drive, ':');
  _Danish: WriteLn('ADVARSEL: Dette vil gendanne alle filer p† drev ', Drive, ':');
  _Japanese: WriteLn('KEIKOKU: Kore wa doraiwu ', Drive, ': no subete no fairu wo fukugen shimasu');
  Else WriteLn('ATTENTION : Ceci r‚cup‚rera tous les fichiers du lecteur ', Drive, ':');
 End;
 Case Language of
  _English: Write('Are you sure (Y/N)? ');
  _Germany: Write('Sind Sie sicher (J/N)? ');
  _Italian: Write('Sei sicuro (S/N)? ');
  _Spain: Write('Est  seguro (S/N)? ');
  _Albanian: Write('A jeni i sigurt (P/J)? ');
  _Portuguese: Write('Tem certeza (S/N)? ');
  _Swedish: Write('Ar du s„ker (J/N)? ');
  _Danish: Write('Er du sikker (J/N)? ');
  _Japanese: Write('Yoroshii desu ka (Y/N)? ');
  Else Write('Etes-vous s–r (O/N) ? ');
 End;
  { Attendre la r‚ponse utilisateur }
 If UpCase(ReadKey) in ['Y','O','J','S','P'] Then Begin
  WriteLn;
   { Lire les structures du disque }
  If Not ReadBootSector(Drive) Then Begin
   Case Language of
    _English: WriteLn('Error: Cannot read boot sector');
    _Germany: WriteLn('Fehler: Boot-Sektor kann nicht gelesen werden');
    _Italian: WriteLn('Errore: Impossibile leggere il settore di avvio');
    _Spain: WriteLn('Error: No se puede leer el sector de arranque');
    _Albanian: WriteLn('Gabim: Nuk mund t‰ lexohet sektori i nisjes');
    _Portuguese: WriteLn('Erro: Nao ‚ poss¡vel ler o setor de inicializa‡ao');
    _Swedish: WriteLn('Fel: Kan inte l„sa startsektorn');
    _Danish: WriteLn('Fejl: Kan ikke laese bootsektor');
    _Japanese: WriteLn('Eraa: Buuto sekuta wo yomu koto ga dekimasen');
    Else WriteLn('Erreur : Impossible de lire le secteur de boot');
   End;
   Exit;
  End;
   If Not ReadFAT(Drive) Then Begin
   Case Language of
    _English: WriteLn('Error: Cannot read FAT');
    _Germany: WriteLn('Fehler: FAT kann nicht gelesen werden');
    _Italian: WriteLn('Errore: Impossibile leggere la FAT');
    _Spain: WriteLn('Error: No se puede leer la FAT');
    _Albanian: WriteLn('Gabim: Nuk mund t‰ lexohet FAT');
    _Portuguese: WriteLn('Erro: Nao ‚ poss¡vel ler a FAT');
    _Swedish: WriteLn('Fel: Kan inte l„sa FAT');
    _Danish: WriteLn('Fejl: Kan ikke laese FAT');
    _Japanese: WriteLn('Eraa: FAT wo yomu koto ga dekimasen');
    Else WriteLn('Erreur : Impossible de lire la FAT');
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
   _Albanian: WriteLn('Skanimin e ', TotalClusters, ' klusterÃ«ve...');
   _Portuguese: WriteLn('Verificando ', TotalClusters, ' clusters...');
   _Swedish: WriteLn('Skannar ', TotalClusters, ' kluster...');
   _Danish: WriteLn('Scanner ', TotalClusters, ' klynger...');
   _Japanese: WriteLn(TotalClusters, ' kurasuta wo sukyan-chuu...');
   Else WriteLn('Analyse de ', TotalClusters, ' les unit‚s d''allocations...');
  End;
   { Analyser les unit‚s d'allocations et marquer les d‚fectueux }
  BadClusters := 0;
  For I := 2 to TotalClusters - 1 Do Begin
   { V‚rifier l'int‚grit‚ du cluster }
   { Simuler la d‚tection de clusters d‚fectueux }
   If (I Mod 100) = 0 Then Write('.');
   { Si un cluster est d‚tect‚ comme d‚fectueux }
   { MarkClusterAsBad(I); }
  End;
  WriteLn;
  Case Language of
   _English: WriteLn('Found ', BadClusters, ' bad clusters');
   _Germany: WriteLn(BadClusters, ' defekte Cluster gefunden');
   _Italian: WriteLn('Trovati ', BadClusters, ' cluster danneggiati');
   _Spain: WriteLn('Se encontraron ', BadClusters, ' clusters defectuosos');
   _Albanian: WriteLn('U gjet‰n ', BadClusters, ' kluster‰ t‰ d‰mtuar');
   _Portuguese: WriteLn('Encontrados ', BadClusters, ' clusters defeituosos');
   _Swedish: WriteLn('Hittade ', BadClusters, ' defekta kluster');
   _Danish: WriteLn('Fandt ', BadClusters, ' d†rlige klynger');
   _Japanese: WriteLn(BadClusters, ' furyou kurasuta wo hakken');
   Else WriteLn(BadClusters, ' unit‚s d''allocations d‚fectueux trouv‚s');
  End;
   { Sauvegarder la FAT mise … jour }
  If BadClusters > 0 Then Begin
   If WriteFAT(Drive) Then Begin
    Case Language of
     _English: WriteLn('FAT updated successfully');
     _Germany: WriteLn('FAT erfolgreich aktualisiert');
     _Italian: WriteLn('FAT aggiornata con successo');
     _Spain: WriteLn('FAT actualizada exitosamente');
     _Albanian: WriteLn('FAT u p‰rdit‰sua me sukses');
     _Portuguese: WriteLn('FAT atualizada com sucesso');
     _Swedish: WriteLn('FAT uppdaterades framg†ngsrikt');
     _Danish: WriteLn('FAT opdateret med succes');
     _Japanese: WriteLn('FAT no koushin ni seikou shimashita');
     Else WriteLn('FAT mise … jour avec succŠs');
    End;
   End
    Else
   Begin
    Case Language of
     _English: WriteLn('Error: Cannot update FAT');
     _Germany: WriteLn('Fehler: FAT kann nicht aktualisiert werden');
     _Italian: WriteLn('Errore: Impossibile aggiornare la FAT');
     _Spain: WriteLn('Error: No se puede actualizar la FAT');
     _Albanian: WriteLn('Gabim: Nuk mund t‰ p‰rdit‰sohet FAT');
     _Portuguese: WriteLn('Erro: Nao ‚ poss¡vel atualizar a FAT');
     _Swedish: WriteLn('Fel: Kan inte uppdatera FAT');
     _Danish: WriteLn('Fejl: Kan ikke opdatere FAT');
     _Japanese: WriteLn('Eraa: FAT wo koushin dekimasen');
     Else WriteLn('Erreur : Impossible de mettre … jour la FAT');
    End;
   End;
  End;
  RecoverWholeDrive := True;
 End
  Else
 Begin
  WriteLn;
  Case Language of
   _English: WriteLn('Operation cancelled');
   _Germany: WriteLn('Vorgang abgebrochen');
   _Italian: WriteLn('Operazione annullata');
   _Spain: WriteLn('Operaci¢n cancelada');
   _Albanian: WriteLn('Operacioni u anulua');
   _Portuguese: WriteLn('Opera‡ao cancelada');
   _Swedish: WriteLn('Operation avbruten');
   _Danish: WriteLn('Operation aflyst');
   _Japanese: WriteLn('Sagyou ga kyanseru saremashita');
   Else WriteLn('Op‚ration annul‚e');
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
 UseImageFile := False;
 ImageFileName := '';
  { Traitement des paramÃ¨tres }
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
    WriteLn('  RECOVER /IMG:imagefile');
    WriteLn;
    WriteLn('Parameters:');
    WriteLn('  drive:           Drive letter to recover');
    WriteLn('  [path]filename   Specific file to recover');
    WriteLn('  /IMG:imagefile   Recover from disk image file');
    WriteLn;
    WriteLn('Examples:');
    WriteLn('  RECOVER A:       Recovers all files on drive A:');
    WriteLn('  RECOVER C:DATA.TXT  Recovers specific file');
    WriteLn('  RECOVER /IMG:DISK.IMG  Recovers from disk image');
   End;
   _Germany: Begin
    WriteLn('RECOVER - Stellt Dateien von einem besch„digten Datentr„ger wieder her');
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
    WriteLn('  RECOVER unit…:');
    WriteLn('  RECOVER [unit…:][percorso]nomefile');
    WriteLn;
    WriteLn('Parametri:');
    WriteLn('  unit…:              Lettera dell''unit… da recuperare');
    WriteLn('  [percorso]nomefile  File specifico da recuperare');
    WriteLn;
    WriteLn('Esempi:');
    WriteLn('  RECOVER A:          Recupera tutti i file sull''unit… A:');
    WriteLn('  RECOVER C:DATA.TXT  Recupera file specifico');
   End;
   _Spain: Begin
    WriteLn('RECOVER - Recupera archivos de un disco da¤ado');
    WriteLn;
    WriteLn('Sintaxis:');
    WriteLn('  RECOVER unidad:');
    WriteLn('  RECOVER [unidad:][ruta]nombrearchivo');
    WriteLn;
    WriteLn('Par metros:');
    WriteLn('  unidad:                Letra de unidad a recuperar');
    WriteLn('  [ruta]nombrearchivo    Archivo espec¡fico a recuperar');
    WriteLn;
    WriteLn('Ejemplos:');
    WriteLn('  RECOVER A:             Recupera todos los archivos en unidad A:');
    WriteLn('  RECOVER C:DATA.TXT     Recupera archivo espec¡fico');
   End;
   _Albanian: Begin
    WriteLn('RECOVER - Rikuperon skedar‰t nga nj‰ disk i d‰mtuar');
    WriteLn;
    WriteLn('Sintaksa:');
    WriteLn('  RECOVER nj‰sia:');
    WriteLn('  RECOVER [nj‰sia:][rruga]emriskedari');
    WriteLn;
    WriteLn('Parametrat:');
    WriteLn('  nj‰sia:               Shkronja e nj‰sis‰ p‰r t''u rikuperuar');
    WriteLn('  [rruga]emriskedari    Skedari specifik p‰r t''u rikuperuar');
    WriteLn;
    WriteLn('Shembuj:');
    WriteLn('  RECOVER A:            Rikuperon t‰ gjith‰ skedar‰t n‰ nj‰sin‰ A:');
    WriteLn('  RECOVER C:DATA.TXT    Rikuperon skedarin specifik');
   End;
   _Portuguese: Begin
    WriteLn('RECOVER - Recupera arquivos de um disco danificado');
    WriteLn;
    WriteLn('Sintaxe:');
    WriteLn('  RECOVER unidade:');
    WriteLn('  RECOVER [unidade:][caminho]nomearquivo');
    WriteLn;
    WriteLn('Parametros:');
    WriteLn('  unidade:                Letra da unidade a recuperar');
    WriteLn('  [caminho]nomearquivo    Arquivo espec¡fico a recuperar');
    WriteLn;
    WriteLn('Exemplos:');
    WriteLn('  RECOVER A:              Recupera todos os arquivos na unidade A:');
    WriteLn('  RECOVER C:DATA.TXT      Recupera arquivo espec¡fico');
   End;
   _Swedish: Begin
    WriteLn('RECOVER - Aterst„ller filer fr†n en skadad disk');
    WriteLn;
    WriteLn('Syntax:');
    WriteLn('  RECOVER enhet:');
    WriteLn('  RECOVER [enhet:][s”kv„g]filnamn');
    WriteLn;
    WriteLn('parametrar:');
    WriteLn('  enhet:              Enhetsbokstav att †terst„lla');
    WriteLn('  [s”kv„g]filnamn     Specifik fil att †terst„lla');
    WriteLn;
    WriteLn('Exempel:');
    WriteLn('  RECOVER A:          Aterst„ller alla filer p† enhet A:');
    WriteLn('  RECOVER C:DATA.TXT  Aterst„ller specifik fil');
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
    WriteLn('  RECOVER A:       Gendanner alle filer p† drev A:');
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
    WriteLn('RECOVER - Cette commande permet de r‚cup‚rer des fichiers ',
                       'd''un disque endommag‚.');
    WriteLn;
    WriteLn('Syntaxe :');
    WriteLn('  RECOVER lecteur:');
    WriteLn('  RECOVER [lecteur:][chemin]nomfichier');
    WriteLn('  RECOVER /IMG:fichiermage');
    WriteLn;
    WriteLn('ParamŠtres :');
    WriteLn('  lecteur:              Lettre de lecteur … r‚cup‚rer');
    WriteLn('  [chemin]nomfichier    Fichier sp‚cifique … r‚cup‚rer');
    WriteLn('  /IMG:fichierimage     R‚cupŠre depuis un fichier image disque');
    WriteLn;
    WriteLn('Exemples :');
    WriteLn('  RECOVER A:               R‚cupŠre tous les fichiers du lecteur A:');
    WriteLn('  RECOVER C:DATA.TXT       R‚cupŠre un fichier sp‚cifique');
    WriteLn('  RECOVER /IMG:DISQUE.IMG  R‚cupŠre depuis une image disque');
   End;
  End;
  Halt(ERR_SUCCESS);
 End;
 TargetPath := StrToUpper(ParamStr(1));
  { V‚rifier si c'est un paramŠtre /IMG: }
 If StrToUpper(Copy(TargetPath, 1, 5)) = '/IMG:' Then Begin
  ImageFileName := Copy(ParamStr(1), 6, Length(ParamStr(1)));
  If Not OpenImageFile(ImageFileName) Then Begin
   Case Language of
    _English: WriteLn('Error: Cannot open disk image file: ', ImageFileName);
    _Germany: WriteLn('Fehler: Disk-Image-Datei kann nicht ge”ffnet werden: ', ImageFileName);
    _Italian: WriteLn('Errore: Impossibile aprire il file immagine disco: ', ImageFileName);
    _Spain: WriteLn('Error: No se puede abrir el archivo de imagen de disco: ', ImageFileName);
    _Albanian: WriteLn('Gabim: Nuk mund t‰ hapet skedari i imazhit t‰ diskut: ', ImageFileName);
    _Portuguese: WriteLn('Erro: Nao ‚ poss¡vel abrir o arquivo de imagem de disco: ', ImageFileName);
    _Swedish: WriteLn('Fel: Kan inte ”ppna diskbildsfil: ', ImageFileName);
    _Danish: WriteLn('Fejl: Kan ikke †bne diskbilledfil: ', ImageFileName);
    _Japanese: WriteLn('Eraa: Disuku imeeji fairu wo hiraku koto ga dekimasen: ', ImageFileName);
    Else WriteLn('Erreur : Impossible d''ouvrir le fichier image disque : ', ImageFileName);
   End;
   Halt(ERR_FILE_NOT_FOUND);
  End;
  RecoverWholeDisk := True;
  DriveLetter := 'A';  { Valeur par d‚faut pour les images }
  DriveNumber := 0;
 End
  Else
 Begin
   { V‚rifier le format du paramŠtre }
  If Length(TargetPath) = 2 Then Begin
   If TargetPath[2] = ':' Then Begin
    { Format "X:" - r‚cup‚rer tout le lecteur }
    DriveLetter := TargetPath[1];
    DriveNumber := DriveLetterToNumber(DriveLetter);
    RecoverWholeDisk := True;
   End
    Else
   Begin
    Case Language of
     _English: WriteLn('Invalid parameter format');
     _Germany: WriteLn('Ungltiges Parameterformat');
     _Italian: WriteLn('Formato parametro non valido');
     _Spain: WriteLn('Formato de par metro inv lido');
     _Albanian: WriteLn('Format parametri i pavlefsh‰m');
     _Portuguese: WriteLn('Formato de par†metro invi lido');
     _Swedish: WriteLn('Ogiltigt parameterformat');
     _Danish: WriteLn('Ugyldigt parameterformat');
     _Japanese: WriteLn('Parameta no keishiki ga machigatte imasu');
     Else WriteLn('Format de paramŠtre invalide');
    End;
    Halt(ERR_INVALID_PARAMETER);
   End;
  End
   Else
  Begin
   { Format avec nom de fichier }
   If (Length(TargetPath) > 2) and (TargetPath[2] = ':') Then Begin
    DriveLetter := TargetPath[1];
    DriveNumber := DriveLetterToNumber(DriveLetter);
    FileName := Copy(TargetPath, 3, Length(TargetPath));
    RecoverWholeDisk := False;
   End
    Else
   Begin
    Case Language of
     _English: WriteLn('Invalid drive specification');
     _Germany: WriteLn('Ungltige Laufwerksangabe');
     _Italian: WriteLn('Specifica unit… non valida');
     _Spain: WriteLn('Especificaci¢n de unidad inv lida');
     _Albanian: WriteLn('Specifikimi i nj‰sis‰ i pavlefsh‰m');
     _Portuguese: WriteLn('Especifica‡£o de unidade inv lida');
     _Swedish: WriteLn('Ogiltig enhetsspecifikation');
     _Danish: WriteLn('Ugyldig drevspecifikation');
     _Japanese: WriteLn('Doraiwu shitei ga machigatte imasu');
     Else WriteLn('Sp‚cification de lecteur invalide');
    End;
    Halt(ERR_INVALID_PARAMETER);
   End;
  End;
 End;
 { V‚rifier la validit‚ du lecteur }
 If Not (DriveLetter in ['A'..'Z']) Then Begin
  Case Language of
   _English: WriteLn('Invalid drive letter: ', DriveLetter);
   _Germany: WriteLn('Ungltiger Laufwerksbuchstabe: ', DriveLetter);
   _Italian: WriteLn('Lettera unit… non valida: ', DriveLetter);
   _Spain: WriteLn('Letra de unidad inv lida: ', DriveLetter);
   _Albanian: WriteLn('Shkronja e nj‰sis‰ e pavlefshme: ', DriveLetter);
   _Portuguese: WriteLn('Letra de unidade inv lida: ', DriveLetter);
   _Swedish: WriteLn('Ogiltig enhetsbokstav: ', DriveLetter);
   _Danish: WriteLn('Ugyldigt drevbogstav: ', DriveLetter);
   _Japanese: WriteLn('Doraiwu moji ga machigatte imasu: ', DriveLetter);
   Else WriteLn('Lettre de lecteur invalide : ', DriveLetter);
  End;
  Halt(ERR_INVALID_DRIVE);
 End;
  { Ex‚cution de la r‚cup‚ration }
 If RecoverWholeDisk Then Begin
  If Not RecoverWholeDrive(DriveLetter) Then Begin
   Halt(ERR_ACCESS_DENIED);
  End;
 End Else Begin
  If Not RecoverFile(DriveLetter, DriveLetter + ':' + FileName) Then Begin
   Halt(ERR_FILE_NOT_FOUND);
  End;
 End;
  { Affichage du r‚sum‚ }
 If RecoveredFiles > 0 Then Begin
  Case Language of
   _English: WriteLn(RecoveredFiles, ' file(s) recovered successfully');
   _Germany: WriteLn(RecoveredFiles, ' Datei(en) erfolgreich wiederhergestellt');
   _Italian: WriteLn(RecoveredFiles, ' file recuperati con successo');
   _Spain: WriteLn(RecoveredFiles, ' archivo(s) recuperado(s) exitosamente');
   _Albanian: WriteLn(RecoveredFiles, ' skedar(‰) u rikuperuan me sukses');
   _Portuguese: WriteLn(RecoveredFiles, ' arquivo(s) recuperado(s) com sucesso');
   _Swedish: WriteLn(RecoveredFiles, ' fil(er) †terst„llda framg†ngsrikt');
   _Danish: WriteLn(RecoveredFiles, ' fil(er) gendannet med succes');
   _Japanese: WriteLn(RecoveredFiles, ' fairu ga seikou-teki ni fukugen saremashita');
   Else WriteLn(RecoveredFiles, ' fichier(s) r‚cup‚r‚(s) avec succŠs');
  End;
 End;
  { Lib‚ration de la m‚moire }
 If FAT <> Nil Then Dispose(FAT);
  { Fermeture du fichier image si utilis‚ }
 CloseImageFile;
 Halt(ERR_SUCCESS);
END.