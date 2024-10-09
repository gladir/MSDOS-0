{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2 (Windows))
}

Program JOIN;

{$A-}

Uses
 {$IFDEF FPC}
  DOS,Windows,SysUtils;
 {$ELSE}
  DOS,Strings;
 {$ENDIF}

Type
 TCDS=Record
  Reserved1:Array[0..21] of Byte;
  CurrentDir:Array[0..64] of Char;
  Reserved2:Array[0..29] of Byte;
 End;

Var
 CurrentDrive:String;
 DriveName:String;
 C:Char;

Function ResolvePath(Var S:String):Boolean;
Var
 Regs:Registers;
 X:Byte;
Begin
 ResolvePath:=False;
 S:=S+#0;
 Regs.DS:=Seg(S);
 Regs.SI:=Word(Ofs(S))+1;
 Regs.ES:=Seg(S);
 Regs.DI:=Word(Ofs(S))+1;
 Regs.AH:=$60;
 Intr($21,Regs);
 If Regs.Flags and 1=1 Then Exit; { Si CF est fix‚ alors }
 ResolvePath:=True;
 X:=0;
 While(S[X+1]<>#0)and(X<128)do Inc(X);
 S[0]:=Chr(X);
End;

{$IFDEF FPC}
 Procedure JoinDirectory(Drive:Char;NewDir:String);
 Var
  DriveLetter:String;
  DrivePChar,DirPChar:PChar;
 Begin
  DriveLetter:=Drive;
  DrivePChar:=PChar(AnsiString(DriveLetter));
  DirPChar:=PChar(AnsiString(NewDir));
  If Not DefineDosDevice(DDD_RAW_TARGET_PATH,DrivePChar,DirPChar)Then
   Writeln('Erreur: ',SysErrorMessage(GetLastError))
  Else
   WriteLn('Unit‚ ', DriveLetter, ' … join le r‚pertoire ',NewDir,' avec succŠs !');
 End;

 Procedure ListJoins;
 Var
  Buffer:Array[0..65535]of Char;
  ReturnedLength:DWORD;
  DriveLetter:PChar;
  TargetPath:Array[0..65535]of Char;
 Begin
  ReturnedLength:=QueryDosDevice(Nil,Buffer,SizeOf(Buffer));
  If ReturnedLength=0 Then Begin
   Writeln('Erreur: ',SysErrorMessage(GetLastError));
   Exit;
  End;
  DriveLetter:=Buffer;
  While DriveLetter^<>#0 do Begin
   If QueryDosDevice(DriveLetter,TargetPath,SizeOf(TargetPath))<>0 Then Begin
    If(StrPos(TargetPath,'\??\')<>NIL)Then
     Writeln(DriveLetter,' => ',PChar(@TargetPath[4]))
    Else
     Writeln(DriveLetter, ' => ',TargetPath);
   End;
   Inc(DriveLetter, StrLen(DriveLetter) + 1);  { Move to the next drive letter }
  End;
 End;

{$ELSE}
 Procedure fGetCDS(Drive:Byte; Var CDS:TCDS);
 Var
  Regs:Registers;
  CDSList:Pointer;
 Begin
  Regs.AH:=$52;
  MsDos(Regs);
  CDSList:=Ptr(Regs.ES,Regs.BX);
  CDS:=TCDS(Pointer(Ptr(Seg(CDSList^),Ofs(CDSList^)+Drive*$44))^);
 End;

 Procedure JoinDirectory(Drive:Char;NewDir:String);
 Var
  CDSRecord:TCDS;
 Begin
  fGetCDS(Ord(UpCase(Drive))-Ord('A'),CDSRecord);
  StrPCopy(CDSRecord.CurrentDir,NewDir);
 End;
{$ENDIF}

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('JOIN : Cette commande permet de cr‚er un disque virtuel ',
                    '… partir d''un r‚pertoire.');
  WriteLn;
  WriteLn('Syntaxe : JOIN [/?]');
  WriteLn('          JOIN drive1: [drive2:]path');
  WriteLn;
  WriteLn('  /?            Affiche l''aide sur cette commande.');
  WriteLn(' drive1:        Unit‚ de disque … associ‚');
  WriteLn(' drive2:[path]  Chemin … associ‚');
 End
  Else
 If ParamCount=2 Then Begin
  CurrentDrive:=ParamStr(1);
  If(Length(CurrentDrive)>2)or(Copy(CurrentDrive,2,1)<>':')Then Begin
   WriteLn('Unit‚ de disque de format invalide !');
   Halt(1);
  End;
  JoinDirectory(UpCase(CurrentDrive[1]),ParamStr(2));
 End
  Else
 Begin
  {$IFDEF FPC}
   ListJoins;
  {$ELSE}
   For C:='A' to 'Z'do Begin
    DriveName:=C;
    If(ResolvePath(DriveName))Then Writeln(C,': => ',DriveName);
   End;
  {$ENDIF}
 End;
END.
