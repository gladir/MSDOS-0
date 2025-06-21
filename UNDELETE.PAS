{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program UNDELETE;

Uses Crt,DOS;

Const
 SECTOR_SIZE=512;
 MAX_PATH=64;
 DELETED_MARKER=$E5;

Type
 TSector=Array[0..SECTOR_SIZE-1] of Byte;
 TFatEntry=Word;

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
 DiskFile:File;
 BootSector:TSector;
 FATSector:Array[0..9] of TSector; { Maximum de 10 secteurs par FAT }
 RootDir:Array[0..32] of TSector;  { Maximum de 32 secteurs de rÇpertoire racine }
 SectorsPerCluster:Byte;
 ReservedSectors:Word;
 NumberOfFATs:Byte;
 RootEntries:Word;
 SectorsPerFAT:Word;
 FirstDataSector:Word;

Function ReadSector(Drive:Byte;Sector:Word;Var Buffer:TSector):Boolean;
Var
 Regs:Registers;
Begin
 Regs.AH:=$02;  { Lecture de secteurs }
 Regs.AL:=1;    { Nombre de secteurs }
 Regs.CH:=Sector shr 8;   { Piste }
 Regs.CL:=(Sector and $FF) + 1;  { Secteur }
 Regs.DH:=0;    { Tàte }
 Regs.DL:=Drive;{ UnitÇ de disque }
 Regs.ES:=Seg(Buffer);
 Regs.BX:=Ofs(Buffer);
 Intr($13,Regs);
 ReadSector:=(Regs.Flags and 1)=0;
End;

Function WriteSector(Drive:Byte;Sector:Word;Var Buffer:TSector):Boolean;
Var
 Regs:Registers;
Begin
 Regs.AH:=$03;  { êcriture de secteurs }
 Regs.AL:=1;    { Nombre de secteurs }
 Regs.CH:=Sector shr 8;   { Piste }
 Regs.CL:=(Sector and $FF) + 1;  { Secteur }
 Regs.DH:=0;    { Tàte }
 Regs.DL:=Drive;{ UnitÇ de disque }
 Regs.ES:=Seg(Buffer);
 Regs.BX:=Ofs(Buffer);
 Intr($13,Regs);
 WriteSector:=(Regs.Flags and 1) = 0;
End;

Function ReadBootSector(Drive:Byte):Boolean;Begin
 ReadBootSector:=False;
 If ReadSector(Drive,0,BootSector)Then Begin
  SectorsPerCluster:=BootSector[13];
  ReservedSectors:=BootSector[14] + (BootSector[15] shl 8);
  NumberOfFATs:=BootSector[16];
  RootEntries:=BootSector[17] + (BootSector[18] shl 8);
  SectorsPerFAT:=BootSector[22] + (BootSector[23] shl 8);
  FirstDataSector:=ReservedSectors + (NumberOfFATs * SectorsPerFAT) +
                    ((RootEntries * 32 + SECTOR_SIZE - 1) div SECTOR_SIZE);
  ReadBootSector:=True;
 End;
End;

Function FindDeletedFile(Const Mask:String;Var Entry:TDirEntry;Var Sector,Offset:Word):Boolean;
Var
 i,j:Word;
 DirSector:TSector;
Begin
 FindDeletedFile:=False;
 For i:=0 to (RootEntries*32 div SECTOR_SIZE)-1 do Begin
  If Not ReadSector(0,ReservedSectors+(NumberOfFATs*SectorsPerFAT)+i,DirSector)Then Exit;
  For j:=0 to (SECTOR_SIZE div SizeOf(TDirEntry))-1 do Begin
   Move(DirSector[j * SizeOf(TDirEntry)],Entry,SizeOf(TDirEntry));
   If Entry.Name[0]=Chr(DELETED_MARKER)Then Begin
     { VÇrifier si le fichier correspond au masque }
    If(Mask='*.*')or(Mask=Entry.Name)Then Begin
     Sector:=i;
     Offset:=j*SizeOf(TDirEntry);
     FindDeletedFile:=True;
     Exit;
    End;
   End;
  End;
 End;
End;

Function RestoreFile(Var Entry:TDirEntry;Sector,Offset:Word):Boolean;
Var
 DirSector:TSector;
 FirstChar:Char;
Begin
 RestoreFile:=False;

 Write('Remplace la premiäre lettre ''',Chr(DELETED_MARKER),
        ''' dans ''',Entry.Name,''' par quel lettre ? ');
 ReadLn(FirstChar);
 if FirstChar = #13 then Exit;

  { Lire le secteur contenant l'entrÇe }
 If Not ReadSector(0,ReservedSectors+(NumberOfFATs*SectorsPerFAT)+Sector,DirSector)Then
  Exit;

  { Restaurer le premier caractäre du nom }
 If Entry.Name[0]=Chr(DELETED_MARKER)Then Entry.Name[0]:=FirstChar;

  { êcrire l'entrÇe mise Ö jour }
 Move(Entry, DirSector[Offset], SizeOf(TDirEntry));
 RestoreFile:=WriteSector(0,ReservedSectors+(NumberOfFATs*SectorsPerFAT)+Sector,DirSector);
End;

Var
 FileName:String;
 Entry:TDirEntry;
 Sector,Offset:Word;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('UNDELETE : Cette commande permet de rÇcupÇrer des fichiers supprimÇs');
  WriteLn;
  WriteLn('Syntaxe : UNDELETE [drive:][path]filename');
  WriteLn('          UNDELETE [drive:][path]*.*');
  Halt;
 End;
 FileName:=ParamStr(1);
 If Not ReadBootSector(0)Then Begin
  WriteLn('Erreur de lecture du secteur de dÇmarrage');
  Exit;
 End;
 While FindDeletedFile(FileName,Entry,Sector,Offset)do Begin
  Write('Restaure ', Entry.Name, '.', Entry.Ext, '? (O/N) ');
  If UpCase(ReadKey)in['O','Y']Then Begin
   WriteLn;
   If RestoreFile(Entry, Sector, Offset)Then
    WriteLn('Fichier restaurÇ avec succäs')
   Else
    WriteLn('Erreur de restauration de fichier');
  End;
  WriteLn;
 End;
END.
