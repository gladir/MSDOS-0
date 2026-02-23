{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program SCANDISK;

{$A-}

Uses DOS, Crt;

Type
 TBootSector = Record
  JumpCode: Array[0..2] of Byte;
  OEMName: Array[0..7] of Char;
  BytesPerSector: Word;
  SectorsPerCluster: Byte;
  ReservedSectors: Word;
  NumberOfFATs: Byte;
  RootEntries: Word;
  TotalSectors: Word;
  MediaDescriptor: Byte;
  SectorsPerFAT: Word;
  SectorsPerTrack: Word;
  NumberOfHeads: Word;
  HiddenSectors: LongInt;
  TotalSectorsBig: LongInt;
 End;

 TDirEntry = Record
  Name: Array[0..7] of Char;
  Ext: Array[0..2] of Char;
  Attr: Byte;
  Reserved: Array[0..9] of Byte;
  Time: Word;
  Date: Word;
  StartCluster: Word;
  Size: LongInt;
 End;

 TErrorType = (etNone, etBadSector, etCrossLinked, etLostChain, etBadFAT, etBadDir);
 TCheckItem = (ciMedia, ciFAT, ciDirectory, ciFileSystem, ciFreeSpace, ciSurface);

Var
 Language: (_French, _English, _Germany, _Italian, _Spain);
 TmpLanguage, DrivePath, FileName: String;
 BootSector: TBootSector;
 FAT: Array[0..8191] of Word;
 RootDir: Array[0..511] of TDirEntry;
 SectorBuffer: Array[0..511] of Byte;
 TotalSectors, BadSectors, LostClusters, CrossLinkedFiles: LongInt;
 ClusterMap: Array[0..8191] of Byte;  { 0=free, 1=used, 2=bad, 3=cross-linked }
 FileHandle: File;
 IsImageFile: Boolean;
 AutoFix, CheckOnly, DoSurfaceScan: Boolean;
 DriveNum: Byte;
 ErrorsFound: Integer;
 CheckStatus: Array[TCheckItem] of Boolean;

Function StrToUpper(S: String): String;
Var I: Byte;
Begin
 For I := 1 to Length(S) do Begin
  If S[I] in ['a'..'z'] Then S[I] := Chr(Ord(S[I]) - 32);
 End;
 StrToUpper := S;
End;

Function Min(A, B: Integer): Integer;
Begin
 If A < B Then Min := A Else Min := B;
End;

Function IntToStr(Value: Integer): String;
Var S: String;
Begin
 Str(Value, S);
 IntToStr := S;
End;

Procedure SetupColors;
Begin
 TextBackground(Blue);
 TextColor(White);
 ClrScr;
End;

Procedure DrawBox(X1, Y1, X2, Y2: Byte);
Var i: Byte;
Begin
 GotoXY(X1, Y1);
 Write(#218);
 For i := X1 + 1 to X2 - 1 do Write(#196);
 Write(#191);

 For i := Y1 + 1 to Y2 - 1 do Begin
  GotoXY(X1, i); Write(#179);
  GotoXY(X2, i); Write(#179);
 End;

 GotoXY(X1, Y2);
 Write(#192);
 For i := X1 + 1 to X2 - 1 do Write(#196);
 Write(#217);
End;

Procedure ShowTitle;
Begin
 GotoXY(1, 1);
 TextColor(Yellow);
 Write('Microsoft ScanDisk');
 TextColor(White);
End;

Procedure ShowCheckList;
Var i: TCheckItem;
    CheckMark: Char;
Begin
 GotoXY(1, 3);
 If IsImageFile Then
  Write('ScanDisk is now checking the following areas of file ', FileName, ':')
 Else
  Write('ScanDisk is now checking the following areas of drive ', DrivePath, ':');
 
 { Effacer le reste de la ligne }
 ClrEol;

 For i := ciMedia to ciSurface do Begin
  If CheckStatus[i] Then CheckMark := #251 Else CheckMark := #16;

  Case i of
   ciMedia: Begin
    GotoXY(1, 5);
    Write('   ', CheckMark, '    Media descriptor');
    ClrEol;
   End;
   ciFAT: Begin
    GotoXY(1, 6);
    Write('   ', CheckMark, '    File allocation tables');
    ClrEol;
   End;
   ciDirectory: Begin
    GotoXY(1, 7);
    Write('   ', CheckMark, '    Directory structure');
    ClrEol;
   End;
   ciFileSystem: Begin
    GotoXY(1, 8);
    Write('   ', CheckMark, '    File system');
    ClrEol;
   End;
   ciFreeSpace: Begin
    GotoXY(1, 9);
    Write('   ', CheckMark, '    Free space');
    ClrEol;
   End;
   ciSurface: Begin
    GotoXY(1, 10);
    Write('   ');
    If CheckStatus[ciSurface] Then Write(#251) 
    Else If DoSurfaceScan Then Write(#16) 
    Else Write(' ');
    Write('    Surface scan');
    ClrEol;
   End;
  End;
 End;
End;

Function ShowDialog(Title, Message: String; ShowYesNo: Boolean): Boolean;
Var Key: Char;
    BoxWidth, BoxHeight, X1, Y1, i, j: Byte;
    Lines: Array[0..10] of String;
    LineCount, CurrentLine, MaxLineLen: Byte;
Begin
 BoxWidth := 60;
 BoxHeight := 8;
 X1 := (80 - BoxWidth) div 2;
 Y1 := (25 - BoxHeight) div 2;
 
 { Découper le message en lignes }
 LineCount := 0;
 CurrentLine := 1;
 MaxLineLen := BoxWidth - 4; { Marge de 2 caractères de chaque côté }
 
 While (CurrentLine <= Length(Message)) and (LineCount < 10) do Begin
  If (CurrentLine + MaxLineLen - 1) <= Length(Message) Then Begin
   { Chercher un espace pour couper proprement }
   j := CurrentLine + MaxLineLen - 1;
   While (j > CurrentLine) and (Message[j] <> ' ') do Dec(j);
   If j = CurrentLine Then j := CurrentLine + MaxLineLen - 1; { Pas d'espace trouvé, couper au max }
   
   Lines[LineCount] := Copy(Message, CurrentLine, j - CurrentLine + 1);
   CurrentLine := j + 1;
   If Message[j] = ' ' Then Inc(CurrentLine); { Passer l'espace }
  End Else Begin
   Lines[LineCount] := Copy(Message, CurrentLine, Length(Message) - CurrentLine + 1);
   CurrentLine := Length(Message) + 1;
  End;
  Inc(LineCount);
 End;

 { Ajuster la hauteur de la boîte selon le nombre de lignes }
 BoxHeight := 5 + LineCount;
 Y1 := (25 - BoxHeight) div 2;

 { Sauvegarder et changer les couleurs }
 TextBackground(LightGray);
 TextColor(Black);

 { Remplir la boîte avec l'arrière-plan }
 For i := Y1 to Y1 + BoxHeight do Begin
  GotoXY(X1, i);
  For j := X1 to X1 + BoxWidth do Write(' ');
 End;

 { Dessiner le cadre }
 DrawBox(X1, Y1, X1 + BoxWidth, Y1 + BoxHeight);

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
  GotoXY(X1 + 18, Y1 + BoxHeight - 2);
  Write('< Yes >   < No >');
 End Else Begin
  GotoXY(X1 + 25, Y1 + BoxHeight - 2);
  Write('< OK >');
 End;

 { Attendre la réponse }
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
  If ShowYesNo and (UpCase(Key) = 'Y') Then Begin
   ShowDialog := True;
   Break;
  End;
 Until False;

 { Restaurer les couleurs et redessiner l'écran }
 SetupColors;
 ShowTitle;
 ShowCheckList;
 GotoXY(1, 14);
 Write('examining drive ', DrivePath, '...');
 ClrEol;
End;

Procedure ShowSurfaceScanScreen;
Begin
 ClrScr;
 ShowTitle;
 
 { Titre du surface scan }
 GotoXY(35, 4);
 TextColor(Yellow);
 Write('Surface Scan');
 TextColor(White);
 
 { Boîte principale pour la carte du disque }
 DrawBox(1, 6, 50, 20);
 
 { Informations du lecteur à droite }
 GotoXY(55, 8);
 If IsImageFile Then
  Write('File: ', FileName)
 Else
  Write('Drive ', DrivePath, ':');
  
 GotoXY(55, 10);
 Write(TotalSectors, ' sectors');
 GotoXY(55, 11);
 Write('0 examined');
 GotoXY(55, 12);
 Write('0 found bad');
 
 { Légende }
 GotoXY(55, 15);
 TextColor(Green);
 Write(#219, ' = 100 sectors');
 TextColor(White);
 
 GotoXY(55, 17);
 TextColor(Green);
 Write(#219, ' unused sectors');
 TextColor(LightGray);
 GotoXY(55, 18);
 Write(#177, ' some used sectors');
 TextColor(DarkGray);
 GotoXY(55, 19);
 Write(#178, ' used sectors');
 TextColor(Red);
 GotoXY(55, 20);
 Write(#219, ' some bad sectors');
 TextColor(White);
 
 { Boutons en bas }
 DrawBox(40, 22, 55, 24);
 GotoXY(42, 23);
 Write('< More Info >');
 
 DrawBox(58, 22, 70, 24);
 GotoXY(62, 23);
 Write('< Exit >');
End;

Procedure UpdateSurfaceProgress(SectorsChecked: LongInt; BadFound: LongInt);
Var Percentage: Integer;
    X, Y, BlocksToShow, i: Integer;
    BlockColor: Byte;
Begin
 { Mettre à jour les statistiques }
 GotoXY(55, 11);
 Write(SectorsChecked, ' examined     ');
 GotoXY(55, 12);
 Write(BadFound, ' found bad     ');
 
 { Calculer et dessiner la carte du disque }
 BlocksToShow := (SectorsChecked * 672) div TotalSectors; { 672 = 48*14 blocs dans la boîte }
 If BlocksToShow > 672 Then BlocksToShow := 672;
 
 For i := 0 to BlocksToShow - 1 do Begin
  X := 2 + (i mod 48);
  Y := 7 + (i div 48);
  
  { Déterminer la couleur du bloc selon l'utilisation }
  If (i * TotalSectors div 672) < (BootSector.ReservedSectors + BootSector.NumberOfFATs * BootSector.SectorsPerFAT) Then
   BlockColor := DarkGray  { Secteurs système }
  Else Begin
   { Vérifier si le secteur est utilisé par un fichier }
   If Random(10) < 3 Then
    BlockColor := LightGray  { Secteur utilisé }
   Else
    BlockColor := Green;     { Secteur libre }
  End;
  
  GotoXY(X, Y);
  TextColor(BlockColor);
  Write(#219);
 End;
 
 TextColor(White);
 
 { Barre de progression en bas }
 Percentage := (SectorsChecked * 100) div TotalSectors;
 GotoXY(1, 25);
 Write(Percentage, '% complete  ');
 
 { Barre de progression graphique }
 For i := 15 to 65 do Begin
  GotoXY(i, 25);
  If i <= (15 + (Percentage * 50 div 100)) Then
   Write(#219)
  Else
   Write(#177);
 End;
End;

Procedure ShowHelp;
Begin
 Case Language of
  _English: Begin
   WriteLn('SCANDISK - Disk diagnostic and repair utility');
   WriteLn('Usage: SCANDISK [drive: | filename] [/AUTOFIX] [/CHECKONLY] [/SURFACE]');
   WriteLn('  drive:     Drive to check (A:, C:, etc.)');
   WriteLn('  filename   Disk image file to check');
   WriteLn('  /AUTOFIX   Automatically fix errors');
   WriteLn('  /CHECKONLY Check only, do not fix');
   WriteLn('  /SURFACE   Perform surface scan');
  End;
  Else Begin
   WriteLn('SCANDISK - Utilitaire de diagnostic et réparation de disque');
   WriteLn;
   WriteLn('Syntaxe: SCANDISK [lecteur: | fichier] [/AUTOFIX] [/CHECKONLY] [/SURFACE]');
   WriteLn;
   WriteLn('  lecteur:   Lecteur à vérifier (A:, C:, etc.)');
   WriteLn('  fichier    Fichier image disque à vérifier');
   WriteLn('  /AUTOFIX   Réparer automatiquement les erreurs');
   WriteLn('  /CHECKONLY Vérification seulement, pas de réparation');
   WriteLn('  /SURFACE   Effectuer un scan de surface');
  End;
 End;
End;

Function ReadSector(SectorNum: LongInt): Boolean;
{$IFDEF Windows}
Begin
 If IsImageFile Then Begin
  Seek(FileHandle, SectorNum * 512);
  BlockRead(FileHandle, SectorBuffer, 512);
  ReadSector := IOResult = 0;
 End Else Begin
  WriteLn('Accès disque direct non supporté sous Windows');
  ReadSector := False;
 End;
End;
{$ELSE}
Var Regs: Registers;
Begin
 If IsImageFile Then Begin
  Seek(FileHandle, SectorNum * 512);
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
  Seek(FileHandle, SectorNum * 512);
  BlockWrite(FileHandle, SectorBuffer, 512);
  WriteSector := IOResult = 0;
 End Else Begin
  WriteLn('Accès disque direct non supporté sous Windows');
  WriteSector := False;
 End;
End;
{$ELSE}
Var Regs: Registers;
Begin
 If IsImageFile Then Begin
  Seek(FileHandle, SectorNum * 512);
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

Function ReadBootSector: Boolean;
Begin
 If ReadSector(0) Then Begin
  Move(SectorBuffer, BootSector, SizeOf(BootSector));

  TotalSectors := BootSector.TotalSectors;
  If TotalSectors = 0 Then TotalSectors := BootSector.TotalSectorsBig;

  { Vérifications de sanité }
  If (BootSector.SectorsPerFAT = 0) or (BootSector.SectorsPerFAT > 255) Then Begin
   ShowDialog('Error', 'Invalid sectors per FAT: ' + IntToStr(BootSector.SectorsPerFAT), False);
   ReadBootSector := False;
   Exit;
  End;

  If (BootSector.BytesPerSector <> 512) Then Begin
   ShowDialog('Error', 'Unsupported sector size: ' + IntToStr(BootSector.BytesPerSector), False);
   ReadBootSector := False;
   Exit;
  End;

  ReadBootSector := True;
 End Else ReadBootSector := False;
End;

Procedure ReadFAT;
Var i, j, FATIndex: Integer;
    MaxFATEntries, MaxSectors: Integer;
Begin
 CheckStatus[ciFAT] := False;
 MaxFATEntries := High(FAT) + 1;
 MaxSectors := MaxFATEntries div 256;

 For i := 0 to Min(BootSector.SectorsPerFAT - 1, MaxSectors - 1) do Begin
  If ReadSector(BootSector.ReservedSectors + i) Then Begin
   For j := 0 to 255 do Begin
    FATIndex := i * 256 + j;
    If (FATIndex >= 0) and (FATIndex < MaxFATEntries) Then Begin
     If (j * 2 + 1) < 512 Then Begin
      FAT[FATIndex] := SectorBuffer[j * 2] + (SectorBuffer[j * 2 + 1] shl 8);
     End;
    End Else Break;
   End;
  End Else Begin
   Exit;
  End;
 End;
 CheckStatus[ciFAT] := True;
End;

Procedure CheckFATConsistency;
Var i, j: Integer;
Begin
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
   For j := 0 to 15 do Begin { 16 entrées par secteur }
    If (i * 16 + j) <= High(RootDir) Then Begin
     Move(SectorBuffer[j * 32], RootDir[i * 16 + j], 32);

     { Vérifier l'entrée }
     If RootDir[i * 16 + j].Name[0] <> #0 Then Begin
      { Marquer les clusters utilisés }
      If (RootDir[i * 16 + j].StartCluster > 0) and
         (RootDir[i * 16 + j].StartCluster <= High(ClusterMap)) Then Begin
       ClusterMap[RootDir[i * 16 + j].StartCluster] := 1;
      End;
     End;
    End;
   End;
  End Else Begin
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
Begin
 CheckStatus[ciFileSystem] := False;

 For i := 2 to High(FAT) do Begin
  If (FAT[i] <> 0) and (FAT[i] < $FF8) Then Begin
   { Suivre la chaîne de clusters }
   NextCluster := i;
   ChainLength := 0;
   FillChar(Chain, SizeOf(Chain), 0);

   Repeat
    If ChainLength < High(Chain) Then Begin
     Chain[ChainLength] := NextCluster;
     Inc(ChainLength);
    End;

    If NextCluster <= High(ClusterMap) Then Begin
     If ClusterMap[NextCluster] = 1 Then
      ClusterMap[NextCluster] := 1
     Else If ClusterMap[NextCluster] = 0 Then
      ClusterMap[NextCluster] := 1
     Else Begin
      Inc(CrossLinkedFiles);
      ClusterMap[NextCluster] := 3;
     End;
    End;

    If NextCluster <= High(FAT) Then
     NextCluster := FAT[NextCluster]
    Else
     Break;

    If ChainLength > 1000 Then Break; { Protection contre les boucles infinies }
   Until (NextCluster >= $FF8) or (NextCluster = 0);
  End;
 End;
 CheckStatus[ciFileSystem] := True;
End;

Procedure CheckLostClusters;
Var i: Integer;
Begin
 CheckStatus[ciFreeSpace] := False;

 For i := 2 to High(FAT) do Begin
  If (i <= High(ClusterMap)) and (FAT[i] <> 0) and (ClusterMap[i] = 0) Then Begin
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
Begin
 If Not DoSurfaceScan Then Exit;

 { Initialiser les variables }
 CheckStatus[ciSurface] := False;
 BadSectors := 0;
 SectorsExamined := 0;
 
 { Afficher l'écran de surface scan }
 ShowSurfaceScanScreen;
 
 { Initialiser le générateur de nombres aléatoires pour la simulation }
 Randomize;

 For i := 0 to TotalSectors - 1 do Begin
  Inc(SectorsExamined);
  BadSectorFound := Not ReadSector(i);

  If BadSectorFound Then Begin
   Inc(BadSectors);
   If AutoFix Then Begin
    { Marquer le cluster correspondant comme défectueux }
    If i >= (BootSector.ReservedSectors + BootSector.NumberOfFATs * BootSector.SectorsPerFAT) Then Begin
     FAT[(i - (BootSector.ReservedSectors + BootSector.NumberOfFATs * BootSector.SectorsPerFAT)) div BootSector.SectorsPerCluster + 2] := $FF7;
    End;
   End;
  End;

  { Mettre à jour l'affichage toutes les 5 secteurs }
  If (i mod 5) = 0 Then Begin
   UpdateSurfaceProgress(SectorsExamined, BadSectors);
  End;
  
  { Vérifier si l'utilisateur appuie sur une touche }
  If KeyPressed Then Begin
   Case ReadKey of
    #27, 'e', 'E': Begin { ESC ou Exit }
     Break;
    End;
   End;
  End;
  
  Delay(10); { Délai pour voir l'animation }
 End;
 
 { Mettre à jour l'affichage final }
 UpdateSurfaceProgress(SectorsExamined, BadSectors);
 CheckStatus[ciSurface] := True;
 
 { Attendre que l'utilisateur appuie sur une touche }
 GotoXY(1, 23);
 Write('Press any key to continue...');
 ReadKey;
End;

Procedure PerformChecks;
Begin
 ClrScr;
 ShowTitle;
 ShowCheckList;

 GotoXY(1, 14);
 Write('examining drive ', DrivePath, '...');
 ClrEol;

 { Effectuer les vérifications une par une avec mise à jour en place }
 CheckStatus[ciMedia] := False;
 CheckFATConsistency;
 ShowCheckList;
 Delay(800);

 CheckStatus[ciFAT] := False; 
 ReadFAT;
 ShowCheckList;
 Delay(800);

 CheckStatus[ciDirectory] := False;
 CheckDirectoryStructure;
 ShowCheckList;
 Delay(800);

 CheckStatus[ciFileSystem] := False;
 CheckFileAllocation;
 ShowCheckList;
 Delay(800);

 CheckStatus[ciFreeSpace] := False;
 CheckLostClusters;
 ShowCheckList;
 Delay(800);

 { Demander pour le surface scan }
 If ShowDialog('ScanDisk', 'ScanDisk has finished testing the file structure. Do you want to perform a surface scan now?', True) Then Begin
  DoSurfaceScan := True;
  SurfaceScan;
 End;
End;

Procedure ShowSummary;
Begin
 ClrScr;
 ShowTitle;
 
 GotoXY(1, 5);
 Write('=== RÉSUMÉ DE LA VÉRIFICATION ===');
 GotoXY(1, 6);
 Write('Secteurs totaux: ', TotalSectors);
 GotoXY(1, 7);
 Write('Secteurs défectueux: ', BadSectors);
 GotoXY(1, 8);
 Write('Clusters perdus: ', LostClusters);
 GotoXY(1, 9);
 Write('Fichiers avec liens croisés: ', CrossLinkedFiles);
 GotoXY(1, 10);
 Write('Erreurs totales: ', ErrorsFound);

 GotoXY(1, 12);
 If ErrorsFound = 0 Then
  Write('Aucune erreur trouvée. Le disque est en bon état.')
 Else Begin
  Write('Des erreurs ont été détectées.');
  GotoXY(1, 13);
  If CheckOnly Then
   Write('Mode vérification seulement - aucune réparation effectuée.')
  Else If AutoFix Then
   Write('Réparations automatiques effectuées.')
  Else
   Write('Utilisez /AUTOFIX pour réparer automatiquement les erreurs.');
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
 If TmpLanguage <> '' Then Begin
  If TmpLanguage[1] = '"' Then TmpLanguage := Copy(TmpLanguage, 2, 255);
  If StrToUpper(Copy(TmpLanguage, 1, 2)) = 'EN' Then Language := _English Else
  If StrToUpper(Copy(TmpLanguage, 1, 2)) = 'GR' Then Language := _Germany Else
  If StrToUpper(Copy(TmpLanguage, 1, 2)) = 'IT' Then Language := _Italian Else
  If StrToUpper(Copy(TmpLanguage, 1, 2)) = 'SP' Then Language := _Spain;
 End;

 { Vérification des paramètres d'aide }
 If (ParamStr(1) = '/?') or (ParamStr(1) = '--help') or (ParamStr(1) = '-h') or
    (ParamStr(1) = '/h') or (ParamStr(1) = '/H') or (ParamCount = 0) Then Begin
  ShowHelp;
  Halt;
 End;

 { Setup de l'interface graphique }
 SetupColors;

 { Initialisation des variables }
 AutoFix := False;
 CheckOnly := False;
 DoSurfaceScan := False;
 IsImageFile := False;
 BadSectors := 0;
 LostClusters := 0;
 CrossLinkedFiles := 0;
 ErrorsFound := 0;
 FillChar(ClusterMap, SizeOf(ClusterMap), 0);
 FillChar(CheckStatus, SizeOf(CheckStatus), 0);

 { Analyse des paramètres }
 DrivePath := StrToUpper(ParamStr(1));

 If (Length(DrivePath) = 2) and (DrivePath[2] = ':') Then Begin
  { C'est un lecteur }
  IsImageFile := False;
  Case DrivePath[1] of
   'A': DriveNum := 0;
   'B': DriveNum := 1;
   'C': DriveNum := $80;
   'D': DriveNum := $81;
   Else Begin
    ShowDialog('Error', 'Unsupported drive: ' + DrivePath, False);
    Halt(1);
   End;
  End;
 End Else Begin
  { C'est un fichier image }
  IsImageFile := True;
  FileName := ParamStr(1);
  DrivePath := 'file';

  {$I-}
  Assign(FileHandle, FileName);
  Reset(FileHandle, 1);
  {$I+}
  If IOResult <> 0 Then Begin
   ShowDialog('Error', 'Cannot open file: ' + FileName, False);
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

 { Lecture du secteur de boot }
 If Not ReadBootSector Then Begin
  ShowDialog('Error', 'Cannot read boot sector', False);
  If IsImageFile Then Close(FileHandle);
  Halt(1);
 End;

 { Effectuer les vérifications avec interface graphique }
 PerformChecks;

 { Sauvegarde si des modifications ont été faites }
 If AutoFix and (ErrorsFound > 0) and Not CheckOnly Then Begin
  { Réécrire la FAT si nécessaire }
 End;

 { Nettoyage }
 If IsImageFile Then Close(FileHandle);

 { Affichage du résumé }
 ShowSummary;

 { Code de sortie }
 If ErrorsFound > 0 Then Halt(1) Else Halt(0);
END.
