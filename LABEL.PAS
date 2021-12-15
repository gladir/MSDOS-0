{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Free Pascal)
}

Program LabelDOS;

Uses SysUtils;

Var
 NewName:String;

Function GetVolumeInformation(lpRootPathName: PChar; lpVolumeNameBuffer: PChar; nVolumeNameSize: DWORD; lpVolumeSerialNumber: PDWORD;
  Var lpMaximumComponentLength, lpFileSystemFlags: DWORD; lpFileSystemNameBuffer: PChar; nFileSystemNameSize: DWORD): LongBool; stdcall;
  External 'kernel32.dll' name 'GetVolumeInformationA';

Function SetVolumeLabelA(lpRootPathName,lpVolumeName:PWideChar):Boolean; stdcall; External 'kernel32.dll' name 'SetVolumeLabelA';

Function GetCurrDrive:Char;
Var
 S:String;
Begin
 GetDir(0,S);
 GetCurrDrive := S[1];
End;

Function GetVolumeLabel(Dsk:Byte):String;
Var
  lpMaximumComponentLength, lpFileSystemFlags:DWORD;
  lpRootPathName,lpVolumeNameBuffer:Array[0..MAX_PATH] of Char;
Begin
 If Dsk=0Then StrPCopy(lpRootPathName,GetCurrDrive+':\')
         Else StrPCopy(lpRootPathName,Char(Dsk+64) + ':\');
 GetVolumeInformation(lpRootPathName,lpVolumeNameBuffer,SizeOf(lpVolumeNameBuffer),NIL,lpMaximumComponentLength,lpFileSystemFlags,NIL,0);
 GetVolumeLabel := StrPas(lpVolumeNameBuffer);
End;

Procedure SetVolumeLabel(Dsk:Byte;NewName:String);
Var
 lpRootPathName,lpVolumeNameBuffer:Array[0..MAX_PATH] of WideChar;
Begin
 If Dsk=0Then StrPCopy(lpRootPathName,GetCurrDrive+':\')
         Else StrPCopy(lpRootPathName,Char(Dsk+64) + ':\');
 StrPCopy(lpVolumeNameBuffer,NewName);
 WriteLn(SetVolumeLabelA(lpRootPathName,lpVolumeNameBuffer));
End;

Var
 I:Byte;
 IsUnit:Array[0..255]of Boolean;

Function IsRomanLetter(C:Char):Boolean;Begin
 IsRomanLetter := C in ['A'..'Z','a'..'z'];
End;

BEGIN
 If(ParamStr(1) = 'HELP')or(ParamStr(1) = '/?')Then Begin
  WriteLn('LABEL : Cette commande permet de changer le nom du volume');
  WriteLn;
  WriteLn('Syntaxe: LABEL [unite: [nouveaunom]]');
  WriteLn;
  WriteLn(' unite:      Indique l''unitÇ que vous souhaitez traitÇ');
  WriteLn(' nouveaunom  Indique le nouveau du volume');
  WriteLn;
  WriteLn('NB: Si le nouveaunom n''est pas dÇfinit, il retournera le nom courant');
 End
  Else
 If ParamCount=0Then Begin
  WriteLn('êtiquette de l''unitÇ ',GetCurrDrive,' est ',GetVolumeLabel(0));
 End
  Else
 Begin
  NewName:='';
  For I:=1 to ParamCount do Begin
   IsUnit[I] := Pos(':',ParamStr(I)) > 0;
   If Not(IsUnit[I])Then NewName:=ParamStr(I);
  End;
  If NewName=''Then Begin
   For I:=1 to ParamCount do Begin
    If IsUnit[I]Then WriteLn('êtiquette de l''unitÇ ',ParamStr(I),' est ',GetVolumeLabel(Byte(ParamStr(I)[1])-64));
   End
  End
   Else
  Begin
   For I:=1 to ParamCount do Begin
    If IsUnit[I]Then SetVolumeLabel(Byte(ParamStr(I)[1])-64,NewName);
   End
  End;
 End;
END.