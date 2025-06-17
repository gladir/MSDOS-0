{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program BACKUP;

{$A-}

Uses DOS;

Const
 MAX_FILES=500;
 BACKUP_SIGNATURE=$4241434B; { 'BACK' }

Type
 TDateTime=Record
  Date:Word;
  Time:Word;
 End;

 TBackupFileEntry = record
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
 SourcePath,TargetDrive:String;
 Header:TBackupHeader;
 Files:Array[1..MAX_FILES] of TBackupFileEntry;
 FileCount:Word;
 BackupFile:File;
 LogFile:Text;
 BackupAfterDate:Word;
 BackupAfterTime:Word;
 Recursive,OnlyModified,Append:Boolean;
 LogFileName:String;

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
 Val(Copy(DateStr,1,2),Month,Code);
 Val(Copy(DateStr,4,2),Day,Code);
 Val(Copy(DateStr,7,2),Year,Code);
 If Year<80 Then Year:=Year+2000
            Else Year:=Year+1900;
 ParseDate:=(Year - 1980) shl 9 + Month shl 5 + Day;
End;

Function ParseTime(Const TimeStr:String):Word;
Var
 Hour,Min,Sec:Word;
 Code:Integer;
Begin
 Val(Copy(TimeStr,1,2),Hour,Code);
 Val(Copy(TimeStr,4,2),Min,Code);
 Val(Copy(TimeStr,7,2),Sec,Code);
 ParseTime:=Hour shl 11 + Min shl 5 + (Sec shr 1);
End;

Function PackTime(Hour,Min,Sec:Word):Word;Begin
 PackTime:= (Hour shl 11) or (Min shl 5) or (Sec shr 1);
End;

Function UnpackTime(Time:Word;Var Hour,Min,Sec:Word):Boolean;Begin
 Hour:=Time shr 11;
 Min:=(Time shr 5) and $3F;
 Sec:=(Time and $1F) shl 1;
 UnpackTime:=True;
End;

Function PackDate(Year,Month,Day:Word):Word;Begin
 PackDate:= ((Year - 1980) shl 9) or (Month shl 5) or Day;
End;

Function UnpackDate(Date:Word;Var Year,Month,Day:Word):Boolean;Begin
 Year:=(Date shr 9) + 1980;
 Month:=(Date shr 5) and $0F;
 Day:=Date and $1F;
 UnpackDate:=True;
End;

Function GetCurrentDate:Word;
Var
 Year,Month,Day,DayOfWeek:Word;
Begin
 GetDate(Year,Month,Day,DayOfWeek);
 GetCurrentDate:=(Year shl 9)or(Month shl 5) or Day;
End;

Procedure ScanDirectory(Const Path:String);
Var
 Info:SearchRec;
 FullPath:String;
 Year,Month,Day:Word;
Begin
 FullPath:=Path;
 If FullPath[Length(FullPath)]<>'\'Then FullPath:=FullPath+'\';
 FindFirst(FullPath+'*.*',AnyFile,Info);
 While (DosError=0)and(FileCount<MAX_FILES)do Begin
  If(Info.Name[1]<>'.')and((Info.Attr and Directory)=0)Then Begin
   If (BackupAfterDate = 0) or (Info.Time > BackupAfterDate)Then Begin
    Inc(FileCount);
    With Files[FileCount] do Begin
     Name:=Info.Name;
     Path:=FullPath;
     UnpackDate(Word(Info.Time),Year,Month,Day);
     DateTime.Date:=PackDate(Year,Month,Day);
     DateTime.Time:=Info.Time shr 16;
     Size := Info.Size;
     Attributes := Info.Attr;
     BackupOffset := 0;
    End;
   End;
  End
   Else
  If Recursive and(Info.Name[1]<>'.')and((Info.Attr and Directory)<>0)Then
   ScanDirectory(FullPath + Info.Name);
  FindNext(Info);
 End;
End;

Procedure BackupFiles;
Var
 i:Integer;
 SourceFile:File;
 Buffer:Array[1..4096] of Byte;
 BytesRead:Word;
 CurrentOffset:LongInt;
Begin
  { êcrire l'en-tàte }
 Header.Signature:=BACKUP_SIGNATURE;
 Header.FileCount:=FileCount;
 Header.BackupDate:=GetCurrentDate;
 BlockWrite(BackupFile,Header,SizeOf(Header));

  { êcrire le catalogue }
 CurrentOffset:=SizeOf(Header)+FileCount*SizeOf(TBackupFileEntry);
 For i:=1 to FileCount do Files[i].BackupOffset:=CurrentOffset+Files[i].Size;
 BlockWrite(BackupFile,Files,FileCount*SizeOf(TBackupFileEntry));

  { Copier les fichiers }
 For i:=1 to FileCount do Begin
  Assign(SourceFile, Files[i].Path+Files[i].Name);
  Reset(SourceFile, 1);
  If LogFileName<>''Then
   WriteLn(LogFile, 'Copie de sauvegarde: ', Files[i].Path, Files[i].Name);
  While Not Eof(SourceFile) do Begin
   BlockRead(SourceFile, Buffer, SizeOf(Buffer), BytesRead);
   BlockWrite(BackupFile, Buffer, BytesRead);
  End;
  Close(SourceFile);
 End;
End;

Var
 i:Integer;
 Param:String;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('BACKUP : Cette commande permet de crÇer une copie de sauvegarde.');
  WriteLn;
  WriteLn('Syntaxe: BACKUP source [destination] [/S] [/M] [/A]');
  WriteLn('                [/D:mm-dd-yy] [/T:hh:mm:ss] [/L:logfile] [/F:size]');
  Halt;
 End;
  { Initialiser les paramätres }
 SourcePath:=ParamStr(1);
 TargetDrive:=ParamStr(2);
 FileCount:=0;
 BackupAfterDate:=0;
 BackupAfterTime:=0;
 Recursive:=False;
 OnlyModified:=False;
 Append:=False;
 LogFileName:='';
  { Analyser les options }
 For i:=3 to ParamCount do Begin
  Param:=StrToUpper(ParamStr(i));
  If Param[1]='/'Then Case Param[2]of
   'S': Recursive := True;
   'M': OnlyModified := True;
   'A': Append := True;
   'D': BackupAfterDate:=ParseDate(Copy(Param,4,8));
   'T': BackupAfterTime:=ParseTime(Copy(Param,4,8));
   'L': LogFileName := Copy(Param, 4, Length(Param));
  End;
 End;
  { Ouvrir le fichier journal si n√©cessaire }
 If LogFileName<>''Then Begin
  Assign(LogFile, LogFileName);
  Rewrite(LogFile);
 End;

  { Analyse les fichiers }
 ScanDirectory(SourcePath);

  { CrÇer le fichier de sauvegarde }
 Assign(BackupFile,TargetDrive+'\BACKUP.DAT');
 If(Append)Then Reset(BackupFile,1)
           Else Rewrite(BackupFile,1);
  { Sauvegarder les fichiers }
 BackupFiles;
  { Fermer les fichiers }
 Close(BackupFile);
 If LogFileName<>''Then Close(LogFile);
 WriteLn(FileCount, ' fichier(s) sauvegardÇ(s)');
END.