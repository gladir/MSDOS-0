{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program Attrib;

Uses DOS;

Var
 IsAttrSetting:Array[Byte]of Boolean;
 AttrAdd,AttrRemove:Word;
 I:Byte;
 SubDirectory:Boolean;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Procedure SetAttribut(Var F:File);
Var
 CurrAttr:Word;
Begin
 GetFAttr(F,CurrAttr);
 If AttrRemove and ReadOnly=ReadOnly Then CurrAttr:=CurrAttr and Not ReadOnly;
 If AttrRemove and Archive=Archive Then CurrAttr:=CurrAttr and Not Archive;
 If AttrRemove and Hidden=Hidden Then CurrAttr:=CurrAttr and Not Hidden;
 If AttrRemove and SysFile=SysFile Then CurrAttr:=CurrAttr and Not SysFile;

 If AttrAdd and ReadOnly=ReadOnly Then CurrAttr:=CurrAttr or ReadOnly;
 If AttrAdd and Archive=Archive Then CurrAttr:=CurrAttr or Archive;
 If AttrAdd and Hidden=Hidden Then CurrAttr:=CurrAttr or Hidden;
 If AttrAdd and SysFile=SysFile THen CurrAttr:=CurrAttr or SysFile;
 SetFAttr(F,CurrAttr);
End;

Procedure SetAttributFiles(FileSpec:String);
Var
 Info:SearchRec;
 CurrFile:File;
 Found:Boolean;
Begin
 FindFirst(FileSpec,AnyFile,Info);
 Found:=False;
 While DOSError=0 do Begin
  Found:=True;
  If Info.Attr and Directory=Directory Then Begin
   {If(SubDirectory)Then SetAttributFiles(Info.Name+'\*.*');}
  End
   Else
  Begin
   Assign(CurrFile,Info.Name);
   SetAttribut(CurrFile);
  End;
  FindNext(Info);
 End;
 If Not Found Then WriteLn('Aucun resultat trouve');
End;

Procedure ShowAttribut;
Var
 Info:SearchRec;
Begin
 FindFirst('*.*',AnyFile and Not Directory,Info);
 While DOSError=0 do Begin
  If Info.Attr and ReadOnly=ReadOnly Then Write('r') Else Write('-');
  If Info.Attr and SysFile=SysFile Then Write('s') Else Write('-');
  If Info.Attr and Archive=Archive Then Write('a') Else Write('-');
  If Info.Attr and Hidden=Hidden Then Write('h') Else Write('-');
  If Info.Attr and VolumeID=VolumeID Then Write('v') Else Write('-');
  If Info.Attr and Directory=Directory Then Write('d') Else Write('-');
  Write(' ');
  WriteLn(Info.Name);
  FindNext(Info);
 End;
End;

BEGIN
 If ParamStr(1)='/?'Then Begin
  WriteLn('ATTRIB - Cette commande permet de demander ou changer l''attribut d''un fichier');
  WriteLn;
  WriteLn('Syntaxe : ATTRIB nomdufichier [+R|-R] [+A|-A] [+S|-S] [+H|-H]');
 End
  Else
 If ParamCount=0Then ShowAttribut
  Else
 If ParamCount>0Then Begin
  FillChar(IsAttrSetting,SizeOf(IsAttrSetting),0);
  AttrAdd:=0;
  AttrRemove:=0;
  SubDirectory:=False;
  For I:=1to ParamCount do Begin
   If StrToUpper(ParamStr(I))='+R'Then Begin
    AttrAdd:=ReadOnly;
    IsAttrSetting[I]:=True;
   End
    Else
   If StrToUpper(ParamStr(I))='-R'Then Begin
    AttrRemove:=ReadOnly;
    IsAttrSetting[I]:=True;
   End
    Else
   If StrToUpper(ParamStr(I))='+H'Then Begin
    AttrAdd:=Hidden;
    IsAttrSetting[I]:=True;
   End
    Else
   If StrToUpper(ParamStr(I))='-H'Then Begin
    AttrRemove:=Hidden;
    IsAttrSetting[I]:=True;
   End
    Else
   If StrToUpper(ParamStr(I))='+A'Then Begin
    AttrAdd:=Archive;
    IsAttrSetting[I]:=True;
   End
    Else
   If StrToUpper(ParamStr(I))='-A'Then Begin
    AttrRemove:=Archive;
    IsAttrSetting[I]:=True;
   End
    Else
   If StrToUpper(ParamStr(I))='+S'Then Begin
    AttrAdd:=SysFile;
    IsAttrSetting[I]:=True;
   End
    Else
   If StrToUpper(ParamStr(I))='-S'Then Begin
    AttrRemove:=SysFile;
    IsAttrSetting[I]:=True;
   End
    Else
   If StrToUpper(ParamStr(I))='/S'Then Begin
    SubDirectory:=True;
    IsAttrSetting[I]:=True;
   End;
  End;
  For I:=1to ParamCount do Begin
   If Not IsAttrSetting[I]Then Begin
    SetAttributFiles(ParamStr(I));
   End;
   If I=255Then Exit;
  End;
 End;
END.