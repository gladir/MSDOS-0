{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program SETVER;

Uses DOS,Strings;

Const
 MAX_ENTRIES = 64;
 TABLE_SIGNATURE = $1234;

Type
 TVersionEntry=Record
  Filename:Array[1..13] of Char;
  MajorVersion:Byte;
  MinorVersion:Byte;
 End;

 TVersionTable=Record
  Signature:Word;
  Count:Word;
  Entries:Array[1..MAX_ENTRIES] of TVersionEntry;
 End;

Var
 VersionTable:TVersionTable;
 TableFile:File;
 Param1,Param2:String;
 Major,Minor:Byte;
 Code:Integer;

Procedure LoadTable;Begin
 Assign(TableFile, 'C:\SETVER.DAT');
 {$I-} Reset(TableFile, SizeOf(TVersionTable));
 If IOResult=0 Then Begin
  BlockRead(TableFile, VersionTable, 1);
  Close(TableFile);
  If VersionTable.Signature<>TABLE_SIGNATURE Then VersionTable.Count:=0;
 End
  Else
 VersionTable.Count:=0;
 {$I+}
End;

Procedure SaveTable;Begin
 Assign(TableFile, 'C:\SETVER.DAT');
 {$I-}Rewrite(TableFile,SizeOf(TVersionTable));
 If IOResult=0 Then Begin
  VersionTable.Signature:=TABLE_SIGNATURE;
  BlockWrite(TableFile,VersionTable,1);
  Close(TableFile);
 End;
 {$I+}
End;

Function AddEntry(Const Filename:String;Major,Minor:Byte):Boolean;Begin
 AddEntry:=False;
 If VersionTable.Count<MAX_ENTRIES Then Begin
  Inc(VersionTable.Count);
  With VersionTable.Entries[VersionTable.Count] do Begin
   FillChar(Filename,SizeOf(Filename),0);
   Move(Filename[1], VersionTable.Entries[VersionTable.Count].Filename, Length(Filename));
   MajorVersion:=Major;
   MinorVersion:=Minor;
  End;
  AddEntry:=True;
 End;
End;

Procedure DeleteEntry(Const Filename:String);
Var
 i:Integer;
Begin
 For i:=1 to VersionTable.Count do
  If StrComp(@VersionTable.Entries[i].Filename, @Filename[1])=0 Then Begin
   If i<VersionTable.Count Then
    Move(VersionTable.Entries[i+1], VersionTable.Entries[i],
        (VersionTable.Count - i) * SizeOf(TVersionEntry));
    Dec(VersionTable.Count);
   Break;
  End;
End;

Procedure DisplayTable;
Var
 i:Integer;
Begin
 WriteLn('Programme             Version rapport‚');
 WriteLn('----------------------------------------');
 For i:=1 to VersionTable.Count do With VersionTable.Entries[i] do
  WriteLn(Filename, '          ',MajorVersion, '.',MinorVersion);
End;

Procedure InstallHandler;
Var
 Regs:Registers;
Begin
 Regs.AH:=$84;  { Installation du gestionnaire SETVER }
 Regs.AL:=$00;  { Installation }
 Intr($2F,Regs);
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('SETVER - Cette commande permet de fixer la version pour un programme.');
  WriteLn;
  WriteLn('Syntaxe: SETVER [drive:][path]filename [major.minor]');
  WriteLn('         SETVER /DELETE [drive:][path]filename');
  WriteLn('         SETVER /QUERY [drive:][path]filename');
  WriteLn('         SETVER /DISPLAY');
  Halt;
 End;
 LoadTable;
 Param1 := ParamStr(1);
 If Param1='/DISPLAY'Then DisplayTable Else
 If Param1='/DELETE'Then Begin
  If ParamCount<2 Then Begin
   WriteLn('ParamŠtre attendue');
   Halt;
  End
   Else
  Begin
   DeleteEntry(ParamStr(2));
   SaveTable;
  End;
 End
  Else
 If ParamCount=2 Then Begin
  Param2:=ParamStr(2);
  Val(Copy(Param2,1,Pos('.',Param2)-1),Major,Code);
  Val(Copy(Param2,Pos('.',Param2)+1, 2),Minor,Code);
  If AddEntry(Param1, Major, Minor)Then Begin
   SaveTable;
   InstallHandler;
  End
   Else
  Begin
   WriteLn('Erreur: Table de version pleine');
   Halt(2);
  End;
 End;
END.
