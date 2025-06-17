{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program RESTORE;

Uses DOS;

Const
 MAX_FILES=500;
 BACKUP_SIGNATURE=$4241434B; { 'BACK' }

Type
 TDateTime=Record
  Date:Word;
  Time:Word;
 End;

 TBackupFileEntry=Record
  Name:String[13];
  Path:String[64];
  DateTime:TDateTime;
  Size:LongInt;
  Attributes:Byte;
  BackupOffset:LongInt;
 End;

 TBackupHeader=Record
  Signature:LongInt;
  FileCount:Word;
  BackupDate:Word;
 End;

Var
 BackupDrive,TargetDrive:Char;
 TargetPath:String;
 BackupFile:File;
 Header:TBackupHeader;
 Files:Array[1..MAX_FILES] of TBackupFileEntry;
 FileCount:Word;
 Recursive,Prompt,DisplayOnly:Boolean;
 BeforeDate,AfterDate:Word;
 BeforeTime,AfterTime:Word;
 OnlyNew,OnlyModified:Boolean;
 i:Integer;
 Param:String;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function ParseDate(Const DateStr:String):Word;
Var
 Month,Day,Year:Word;
 Code:Integer;
Begin
 Val(Copy(DateStr, 1, 2), Month, Code);
 Val(Copy(DateStr, 4, 2), Day, Code);
 Val(Copy(DateStr, 7, 2), Year, Code);
 If Year<80 Then Year:=Year+2000
            Else Year:=Year+1900;
 ParseDate:=(Year-1980) shl 9 + Month shl 5 + Day;
End;

Function ParseTime(Const TimeStr:String):Word;
Var
 Hour,Min:Word;
 Code:Integer;
Begin
 Val(Copy(TimeStr, 1, 2),Hour,Code);
 Val(Copy(TimeStr, 4, 2),Min,Code);
 ParseTime:=Hour shl 11 + Min shl 5;
End;

Function ShouldRestore(Const Entry:TBackupFileEntry):Boolean;
Var
 Info:SearchRec;
Begin
 ShouldRestore:=True;
  { V‚rifier les dates }
 If(BeforeDate<>0)and(Entry.DateTime.Date>BeforeDate)Then ShouldRestore:=False;
 If(AfterDate<>0)and(Entry.DateTime.Date < AfterDate)Then ShouldRestore:=False;
  { V‚rifier les heures }
 If(BeforeTime<>0)and(Entry.DateTime.Time>BeforeTime)Then ShouldRestore:=False;
 If(AfterTime<>0)and(Entry.DateTime.Time < AfterTime)Then ShouldRestore:=False;
  { V‚rifier si le fichier existe }
 If OnlyNew or OnlyModified Then Begin
  FindFirst(TargetDrive+':'+Entry.Path+Entry.Name,AnyFile,Info);
  If DosError=0 Then Begin
   If OnlyNew Then ShouldRestore:=False else
   If OnlyModified Then ShouldRestore:=(Info.Time<Entry.DateTime.Time)or(Info.Size<>Entry.Size);
  End;
 End;
End;

Procedure RestoreFile(Var Entry:TBackupFileEntry);
Var
 DestFile:File;
 Buffer:Array[1..4096] of Byte;
 BytesToRead,BytesRead:Word;
Begin
 If DisplayOnly Then Begin
  WriteLn(Entry.Path, Entry.Name);
  Exit;
 End;
  { Cr‚er le r‚pertoire si n‚cessaire }
  {$I-} MkDir(TargetDrive + ':' + Entry.Path); {$I+}
  { Ouvrir le fichier destination }
 Assign(DestFile, TargetDrive + ':'+Entry.Path+Entry.Name);
 Rewrite(DestFile, 1);

 { Positionner le fichier de sauvegarde }
 Seek(BackupFile, Entry.BackupOffset);

  { Copier le contenu }
 While Entry.Size>0 do Begin
  If Entry.Size>SizeOf(Buffer)Then BytesToRead:=SizeOf(Buffer)
                              Else BytesToRead:=Entry.Size;
  BlockRead(BackupFile, Buffer, BytesToRead, BytesRead);
  BlockWrite(DestFile, Buffer, BytesRead);
  Dec(Entry.Size, BytesRead);
 End;
 Close(DestFile);
  { Restaurer la date et les attributs }
 SetFTime(DestFile, Entry.DateTime.Time);
 SetFAttr(DestFile, Entry.Attributes);
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('RESTORE - Cette commande permet d''effectuer une r‚cup‚ration de ',
          'fichiers d''une copie de s‚curit‚s.');
  WriteLn;
  WriteLn('Syntaxe: RESTORE drive1: drive2:[path[file]] [/S] [/P] [/B:date]');
  WriteLn('                [/A:date] [/E:time] [/L:time] [/M] [/N] [/D]');
  WriteLn;
  WriteLn('  /S  Restaure le sous-r‚pertoire');
  WriteLn('  /P  Prompt avant restaurer des fichiers en lecture seulement');
  WriteLn('  /B  Avant la date');
  WriteLn('  /A  AprŠs date');
  WriteLn('  /E  Avant l''heure');
  WriteLn('  /L  AprŠs l''heure');
  WriteLn('  /M  Seulement les fichiers modifi‚s');
  WriteLn('  /N  Seulement les nouveaux fichiers');
  WriteLn('  /D  Seulement les fichiers affich‚s');
  Halt;
 End;

  { Initialiser les paramŠtres }
 Param:=ParamStr(1);
 BackupDrive:=UpCase(Param[1]);
 Param:=ParamStr(2);
 TargetDrive:=UpCase(Param[1]);
 TargetPath:=Copy(ParamStr(2),4,Length(ParamStr(2)));

  { Analyser les options }
 For i:=3 to ParamCount do Begin
  Param:=StrToUpper(ParamStr(i));
   If Param[1]='/'Then Case Param[2] of
    'S': Recursive:=True;
    'P': Prompt:=True;
    'D': DisplayOnly:=True;
    'M': OnlyModified:=True;
    'N': OnlyNew:=True;
    'B': BeforeDate:=ParseDate(Copy(Param, 4, 8));
    'A': AfterDate:=ParseDate(Copy(Param, 4, 8));
    'E': BeforeTime:=ParseTime(Copy(Param, 4, 5));
    'L': AfterTime:=ParseTime(Copy(Param, 4, 5));
   End;
  End;
   { Ouvrir le fichier de sauvegarde }
  Assign(BackupFile, BackupDrive + ':\BACKUP.DAT');
  {$I-}
  Reset(BackupFile, 1);
  If IOResult<>0 Then Begin
   WriteLn('Erreur: Impossible d''ouvrir le fichier de copie de sauvegarde');
   Halt;
  End;
   { Lire l'entˆte }
  BlockRead(BackupFile,Header,SizeOf(Header));
  If(Header.Signature<>BACKUP_SIGNATURE)Then Begin
  WriteLn('Error: Invalid backup file');
  Close(BackupFile);
  Exit;
 End;
  { Lire le catalogue }
 FileCount := Header.FileCount;
 If FileCount>MAX_FILES Then FileCount:=MAX_FILES;
 BlockRead(BackupFile,Files,FileCount*SizeOf(TBackupFileEntry));
  { Restaurer les fichiers }
 For i:=1 to FileCount do If ShouldRestore(Files[i])Then RestoreFile(Files[i]);
 Close(BackupFile);
END.