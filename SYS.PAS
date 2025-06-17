{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program SYS;

{$A-}

Uses DOS;

Const
 SECTOR_SIZE = 512;
 MAX_PATH = 64;
 SYSTEM_FILES: array[1..3] of string = ('IO.SYS', 'MSDOS.SYS', 'COMMAND.COM');

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

var
  SourceDrive, DestDrive: Char;
  BootSector: TBootSector;
  FATBuffer: array[0..32767] of Byte;
  ErrorCode: Integer;

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
 Regs.AH:=$03;  { êcriture de secteurs }
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

Function CopySystemFile(Const FileName:String;SourceDrv,DestDrv:Char):Boolean;
Var
 SourceFile,DestFile:File;
 Buffer:Array[0..8191] of Byte;
 BytesRead:Word;
Begin
 CopySystemFile:= False;
 {$I-}Assign(SourceFile, SourceDrv + ':' + FileName);
 Reset(SourceFile, 1); {$I+}
 If IOResult<>0 Then Exit;
 {$I-}Assign(DestFile, DestDrv + ':' + FileName);
 Rewrite(DestFile, 1);{$I+}
 If IOResult<>0 Then Begin
  Close(SourceFile);
  Exit;
 End;
 Repeat
  BlockRead(SourceFile, Buffer, SizeOf(Buffer),BytesRead);
  If BytesRead>0 Then BlockWrite(DestFile, Buffer,BytesRead);
 Until BytesRead = 0;
 Close(SourceFile);
 Close(DestFile);
 CopySystemFile:=True;
End;

Function ReserveFATSpace(Drive:Char):Boolean;
Var
 Sector:TSector;
 i:Integer;
Begin
 ReserveFATSpace:=False;

  { Lire le premier secteur de la FAT }
 If Not ReadSector(Ord(Drive)-Ord('A'),1,Sector,1) then Exit;

  { RÇserver les premiers unitÇs d'allocations }
 For i:=2 to 16 do Sector[i] := $FF;

  { êcrire la FAT mise Ö jour }
 ReserveFATSpace:=WriteSector(Ord(Drive)-Ord('A'),1,Sector,1);
End;

Var
 i:Integer;
 Success:Boolean;
 CurrParam:String;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('SYS : Cette commande permet de transfÇrer les fichiers systämes.');
  WriteLn;
  WriteLn('Syntaxe : SYS [source:] destination:');
  Halt;
 End;
  { DÇterminer les lecteurs source et destination }
 If ParamCount=1 Then Begin
  SourceDrive:='C';
  DestDrive:=ParamStr(1)[1];
 End
  Else
 Begin
  CurrParam:=ParamStr(1);
  SourceDrive:=CurrParam[1];
  DestDrive:=CurrParam[1];
 End;
  { RÇserver l'espace dans la FAT }
 If Not ReserveFATSpace(DestDrive)Then Begin
  WriteLn('Erreur: Impossible de mettre Ö jour la FAT dans l''unitÇ de destination');
  Halt(1);
 End;

  { Copier les fichiers systäme }
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