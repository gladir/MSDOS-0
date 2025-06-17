{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program SYS;

{$A-}

Uses DOS,Strings;

Const
 SECTOR_SIZE=512;
 MAX_PATH=64;
 SYSTEM_FILES:Array[1..3] of string = ('IO.SYS', 'MSDOS.SYS', 'COMMAND.COM');

Type
 TSector=Array[0..SECTOR_SIZE-1] of Byte;
 TFatEntry=Word;

 TBootSector=Record
  JumpCode:Array[0..2] of Byte;
  OEMName:Array[0..7] of Char;
  BytesPerSector:Word;
  SectorsPerCluster:Byte;
  ReservedSectors:Word;
  NumberOfFATs:Byte;
  RootEntries:Word;
  TotalSectors:Word;
  MediaDescriptor:Byte;
  SectorsPerFAT:Word;
  SectorsPerTrack:Word;
  NumberOfHeads:Word;
  HiddenSectors:LongInt;
  TotalSectorsBig:LongInt;
 End;

 TDirEntry=Record
  Name:Array[0..7] of Char;
  Ext:Array[0..2] of Char;
  Attr:Byte;
  Reserved:Array[0..9] of Byte;
  Time:Word;
  Date:Word;
  StartCluster:Word;
  Size:LongInt;
 End;

Var
 SourceDrive,DestDrive:Char;
 BootSector:TBootSector;
 FATBuffer:Array[0..32767] of Byte;
 ErrorCode:Integer;
 i:Integer;
 Success:Boolean;
 CurrParam:String;

Function ReadSector(Drive:Byte;Sector:LongInt;Var Buffer;Count:Word):Boolean;
Var
 Regs:Registers;
Begin
 Regs.AH:=02;  { Lecture de secteurs }
 Regs.AL:=Count;
 Regs.CH:=(Sector shr 8) and $FF;
 Regs.CL:=(Sector and $3F) or ((Sector shr 2) and $C0);
 Regs.DH:=(Sector shr 8) and 1;
 Regs.DL:=Drive;
 Regs.ES:=Seg(Buffer);
 Regs.BX:=Ofs(Buffer);
 Intr($13,Regs);
 ReadSector:=(Regs.Flags and 1) = 0;
End;

Function WriteSector(Drive:Byte;Sector:LongInt;Var Buffer;Count:Word):Boolean;
Var
 Regs:Registers;
Begin
 Regs.AH:=$03;  { ÔøΩcriture de secteurs }
 Regs.AL:=Count;
 Regs.CH:=(Sector shr 8) and $FF;
 Regs.CL:=(Sector and $3F) or ((Sector shr 2) and $C0);
 Regs.DH:=(Sector shr 8) and 1;
 Regs.DL:=Drive;
 Regs.ES:=Seg(Buffer);
 Regs.BX:=Ofs(Buffer);
 Intr($13,Regs);
 WriteSector:=(Regs.Flags and 1) = 0;
End;

Function TrimRight(Const S:String):String;
Var
 i:Integer;
Begin
 i:=Length(S);
 While(i > 0)and(S[i] = ' ')do Dec(i);
 TrimRight:=Copy(S, 1, i);
End;

Function GetFileCluster(Drive:Char;Const FileName:String):Word;
Var
 DirSector:TSector;
 DirEntry:Array[0..31] of Byte;
 i:Integer;
Begin
 GetFileCluster:=0;
  { Lire le rÇpertoire racine }
 If Not ReadSector(Ord(Drive)-Ord('A'), 19, DirSector, 1)Then Exit;
  { Chercher le fichier }
 For i:=0 to 15 do Begin
  Move(DirSector[i * 32], DirEntry, 32);
  If(DirEntry[0]<>0)and(DirEntry[0] <> $E5)and
    (Copy(FileName,1,8)=TrimRight(StrPas(@DirEntry[0])))Then Begin
   GetFileCluster := DirEntry[26] + (DirEntry[27] shl 8);
   Exit;
  End;
 End;
End;

Function GetFileInfo(Drive:Char;Const FileName:String;Var Entry:TDirEntry):Boolean;
Var
 DirSector:TSector;
 i:Integer;
Begin
 GetFileInfo:=False;
 If Not ReadSector(Ord(Drive)-Ord('A'),19,DirSector,1)Then Exit;
 For i:=0 to (SECTOR_SIZE div SizeOf(TDirEntry))-1 do Begin
  Move(DirSector[i * SizeOf(TDirEntry)],Entry,SizeOf(TDirEntry));
  If(Entry.Name[0]<>#0)and(Entry.Name[0]<>Chr($E5))and
    (Copy(FileName,1,8)=TrimRight(StrPas(@Entry.Name)))Then Begin
   GetFileInfo := True;
   Exit;
  End;
 End;
End;

Function CopySystemFile(Const FileName:String;SourceDrv,DestDrv:Char):Boolean;
Var
 Entry:TDirEntry;
 SourceSector,DestSector:LongInt;
 Buffer:TSector;
 SectorsToRead:LongInt;
 CurrentSector:LongInt;
Begin
 CopySystemFile:=False;
  { Obtenir les informations du fichier source }
 If Not GetFileInfo(SourceDrv,FileName,Entry)Then Exit;

  { Calculer le nombre de secteurs √† copier }
 SectorsToRead:=(Entry.Size+SECTOR_SIZE-1) div SECTOR_SIZE;

  { Calculer les secteurs de d√©part }
 SourceSector:=33+(Entry.StartCluster-2);
 DestSector:=33; { Pour IO.SYS et MSDOS.SYS }

  { Pour COMMAND.COM, on √©crit ailleurs }
 If FileName='COMMAND.COM'Then DestSector:=50;

  { Copier les secteurs }
 For CurrentSector:=0 to SectorsToRead-1 do Begin
  If Not ReadSector(Ord(SourceDrv)-Ord('A'),SourceSector+CurrentSector,Buffer,1)Then Exit;
  If Not WriteSector(Ord(DestDrv)-Ord('A'),DestSector+CurrentSector,Buffer,1)Then Exit;
 End;
 CopySystemFile := True;
End;

Function ReserveFATSpace(Drive:Char):Boolean;
Var
 Sector:TSector;
 i:Integer;
Begin
 ReserveFATSpace:=False;
  { Lire le premier secteur de la FAT }
 If Not ReadSector(Ord(Drive)-Ord('A'),1,Sector,1)Then Exit;
  { RÇserver les premiers unitÇs d'allocations }
 For i:=2 to 16 do Sector[i]:=$FF;
  { êcrire la FAT mise Ö jour }
 ReserveFATSpace:=WriteSector(Ord(Drive)-Ord('A'),1,Sector,1);
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('SYS : Cette commande permet de transfÇrer les fichiers systämes.');
  WriteLn;
  WriteLn('Syntaxe : SYS [source:] destination:');
  Halt;
 End;
  { DÔøΩterminer les lecteurs source et destination }
 If ParamCount=1 Then Begin
  SourceDrive:='C';
  CurrParam:=ParamStr(1);
  DestDrive:=CurrParam[1];
 End
  Else
 Begin
  CurrParam:=ParamStr(1);
  SourceDrive:=CurrParam[1];
  CurrParam:=ParamStr(2);
  DestDrive:=CurrParam[1];
 End;
  { RÇserver l'espace dans la FAT }
 If Not ReserveFATSpace(DestDrive)Then Begin
  WriteLn('Erreur: Impossible de mettre Ö jour la FAT dans l''unitÇ de destination');
  Halt(1);
 End;

  { Copier les fichiers systÔøΩme }
 Success:=True;
 For i:=1 to 3 do Begin
  Write('Copiage de ', SYSTEM_FILES[i], '... ');
  If CopySystemFile(SYSTEM_FILES[i], SourceDrive, DestDrive)Then WriteLn('OK')
   Else
  Begin
   WriteLn('êchec');
   Success := False;
   Break;
  End;
 End;
 If(Success)Then WriteLn('Systäme transfÇrÇ')
            Else WriteLn('êchec du transfäre du systäme');
END.