{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program MIRROR;

Uses DOS;

Const
 SectorSize = 512; { Taille d'un secteur en octets }

Type
 SectorBuffer=Array[1..SectorSize] of Byte;

Var
 Regs:Registers;
 Buffer:SectorBuffer;
 Drive,Mode:Char;
 FileHandle:File;
 CurrParam:String;

 { Lecture d'un secteur du disque avec interruption 13h }
Function ReadSector(Drive:Byte;Head,Track,Sector:Byte;Var Buffer:SectorBuffer):Boolean;Begin
 FillChar(Regs,SizeOf(Regs),0);
 Regs.AH:=$02;       { Fonction 02h : Lecture d'un secteur }
 Regs.AL:=1;         { Nombre de secteurs Ö lire }
 Regs.CH:=Track;     { NumÇro de piste (track) }
 Regs.CL:=Sector;    { NumÇro de secteur (bits 0 Ö 5) }
 Regs.CL:=Regs.CL or ((Track shr 2) and $C0); { Ajout des bits 6 Ö 7 de la piste }
 Regs.DH:=Head;      { NumÇro de tàte (head) }
 Regs.DL:=Drive;     { NumÇro du disque (0=A:, 1=B:, 80h=HDD) }
 Regs.ES:=Seg(buffer);
 Regs.BX:=Ofs(buffer);
 Intr($13,Regs);
 ReadSector:=(Regs.Flags and FCarry) = 0; { VÇrifie si l'opÇration a rÇussi }
End;

 { êcriture d'un secteur du disque avec interruption 13h }
Function WriteSector(Drive:Byte;Head,Track,Sector:Byte;Var Buffer:SectorBuffer):Boolean;Begin
 FillChar(Regs, SizeOf(Regs), 0);
 Regs.AH:=$03;       { Fonction 03h : êcriture d'un secteur }
 Regs.AL:=1;         { Nombre de secteurs Ö Çcrire }
 Regs.CH:=track;     { NumÇro de piste (track) }
 Regs.CL:=sector;    { NumÇro de secteur (bits 0-5) }
 Regs.CL:=Regs.CL or ((track shr 2) and $C0); { Ajout des bits 6-7 de la piste }
 Regs.DH:=head;      { NumÇro de tàte (head) }
 Regs.DL:=drive;     { NumÇro du disque (0=A:, 1=B:, 80h=HDD) }
 Regs.ES:=Seg(buffer);
 Regs.BX:=Ofs(buffer);
 Intr($13,Regs);
 WriteSector:=(Regs.Flags and FCarry) = 0; { VÇrifie si l'opÇration a rÇussi }
End;

 { Sauvegarde du secteur de dÇmarrage dans un fichier }
Procedure BackupSector(Drive:Byte;Filename:String);Begin
 If not ReadSector(drive,0,0,1,Buffer)Then Begin
  WriteLn('Erreur : Impossible de lire le secteur de dÇmarrage.');
  Exit;
 End;
 Assign(FileHandle,Filename);
 Rewrite(FileHandle,1);
 BlockWrite(FileHandle,Buffer,SectorSize);
 Close(FileHandle);
 WriteLn('Secteur de dÇmarrage sauvegardÇ dans ', filename);
End;

{ Restauration du secteur de dÇmarrage depuis un fichier }
Procedure RestoreSector(Drive:Byte;Filename:String);Begin
 Assign(FileHandle,Filename);
 Reset(FileHandle, 1);
 BlockRead(FileHandle, Buffer, SectorSize);
 Close(FileHandle);
 If Not WriteSector(drive,0,0,1,Buffer)Then Begin
  WriteLn('Erreur : Impossible d''Çcrire le secteur de dÇmarrage.');
  Exit;
 End;
 WriteLn('Secteur de dÇmarrage restaurÇ depuis ', filename);
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('MIRROR: Sauvegarde et restauration du secteur de dÇmarrage');
  WriteLn;
  WriteLn('Syntaxe:  MIRROR B <lecteur> <fichier> (Sauvegarder)');
  WriteLn('          MIRROR R <lecteur> <fichier> (Restaurer)');
  WriteLn;
  WriteLn(' B   Sauvegarder le secteur');
  WriteLn(' R   Restaurer le secteur');
 End
  Else
 If ParamCount<3 Then Begin
  WriteLn('Erreur : Paramätres insuffisants.');
  Halt(1);
 End
  Else
 Begin
  CurrParam:=ParamStr(1);
  Mode:=UpCase(CurrParam[1]);
  CurrParam:=ParamStr(2);
  Drive:=UpCase(CurrParam[1]);
  Case Drive of
   'A': Drive := #0;
   'B': Drive := #1;
   'C': Drive := #$80;
   'D': Drive := #$81;
   Else Begin
    WriteLn('Erreur : UnitÇ de disque invalide.');
    Halt(1);
   End;
  End;
  If Mode='B'Then BackupSector(Byte(Drive), ParamStr(3)) Else
  If Mode='R'Then RestoreSector(Byte(Drive), ParamStr(3))
             Else WriteLn('Erreur : Mode inconnu. Utilisez B ou R.');
 End;
END.