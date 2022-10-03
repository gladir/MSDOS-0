{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program COMMAND;

{$M 8192,0,0}

Uses Crt,DOS;

Const
 CommandList:Array[0..36]of String[8]=(
  'BREAK','CALL','CD','CHCP','CHDIR','CLS','COPY','CTTY','DEL','DELETE',
  'DIR','ECHO','ERA','ERASE','EXIT','FOR','IF','LOADHIGH','MD','MKDIR',
  'PATH','PAUSE','PROMPT','RD','REM','REN','RENAME','RMDIR','SET',
  'SHIFT','TIME','TRUENAME','TYPE','VER','VERIFY','VOL','DATE'
 );

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 Pipe,PipeToCommand:Boolean;
 PipeFile:Text;
 InCmd:Byte;
 Option:(optNone,optCommand);
 Echo:Boolean;
 CommandFound,Terminated:Boolean;
 CmdStr:String;
 CurrCommand,ParamList,PipeCommand:String;
 I,J:Byte;

Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
End;

Function PadZeroLeft(Value:Integer;Space:Byte):String;
Var
 S:String;
Begin
 Str(Value,S);
 While Length(S)<Space do S:='0'+S;
 PadZeroLeft:=S;
End;

Function TrimL(S:String):String;
Var
 I:Byte;
Begin
 For I:=1to Length(S)do Begin
  If S[I]<>' 'Then Begin
   TrimL:=Copy(S,I,255);
   Exit;
  End;
 End;
 TrimL:=S;
End;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function GetCurrentDisk:Char;
Var
 CurrentDir:String;
Begin
 GetDir(0,CurrentDir);
 GetCurrentDisk:=CurrentDir[1];
End;

Function FileExist(Name:String):Boolean;
Var
 Rec:SearchRec;
Begin
 FindFirst(Name,AnyFile,Rec);
 FileExist:=DosError=0;
End;

Function Path2Drive(Path:String):Char;Begin
 Path:=FExpand(Path);
 Path2Drive:=Path[1];
End;

Function GetDiskLabel(Dsk:Byte):String;
Var
 Info:SearchRec;
 CurrentDir:String;
Begin
 If Dsk=0Then GetDir(0,CurrentDir)
         Else CurrentDir:=Char(Dsk+64);
 FindFirst(CurrentDir[1]+':\*.*',VolumeID,Info);
 While DosError=0do Begin
  If(Info.Attr = VolumeID)Then Begin
   GetDiskLabel:=Info.Name;
   Exit;
  End;
  FindNext(Info);
 End;
 GetDiskLabel:=''
End;

Procedure SetEnv(EnvVar,Value:String);
Var
 Link,
 PrevLink,
 EnvirP:Word;
 Size,Scan,Where,Dif:Integer;
 NewVar,OldVar,Test:String;

 Function CheckSpace(Wanted:Integer):Boolean;Begin
  If Wanted+Scan>Size Then InOutRes:=8;
  CheckSpace := inoutres = 0;
 End;

Begin
 {$IFNDEF FPC}
  If InOutRes>0 Then Exit;
  For Scan:=1 TO Length(EnvVar)do EnvVar[Scan]:=UpCase(EnvVar[Scan]);
  EnvVar:=EnvVar+'=';
  NewVar:=EnvVar+Value+#0;
  link:=PrefixSeg;
  Repeat
   PrevLink:=Link;
   Link:=MemW[link:$16];
  Until Link=prevlink;
  EnvirP:=MemW[Link:$2C];
  Size:=MemW[Envirp-1:$03]*16;
  Scan:=0;
  Where:=-1;
  While mem[EnvirP:Scan]<>0 do Begin
   Move(mem[EnvirP:Scan],Test[1],255);
   Test[0]:=#255;
   Test[0]:=Chr(pos(#0,Test));
   If Pos(EnvVar,Test)=1 Then Begin
    Where:=Scan;
    OldVar:=Test;
   End;
   Scan:=Scan+Length(Test);
  End;
  If Where=-1 Then Begin
   Where:=Scan;
   NewVar:=NewVar+#0#0#0;
   If Not CheckSpace(Length(NewVar)) Then Exit;
  End
   Else
  Begin
   Dif:=Length(NewVar)-Length(OldVar);
   If Dif>0 Then Begin
    If Not CheckSpace(Dif)Then Exit;
    Move(mem[EnvirP:Where], mem[EnvirP:Where+Dif],Scan-Where+3);
   End
    Else
   If Dif<0 Then Move(mem[EnvirP:Where-Dif],Mem[EnvirP:Where],Size-Where+Dif);
  End;
  Move(NewVar[1],Mem[EnvirP:Where],Length(NewVar));
 {$ENDIF}
End;

Function CopyFile(Source,Target:String;ShowProgression:Boolean):Boolean;
Var
 SourceFile,TargetFile:File;
 RecordsRead:Integer;
 Buffer:Array[1..1000]of Byte;
Begin
 CopyFile:=False;
 Assign(SourceFile,Source);
 {$I-}Reset(SourceFile,1);{$I+}
 If IOResult<>0Then Begin
  WriteLn('Fichier source introuvable ',Source);
  Exit;
 End;
 Assign(TargetFile,Target);
 {$I-}Rewrite(TargetFile,1);
 If(ShowProgression)Then WriteLn('. = 1000 octets de copies');
 BlockRead(SourceFile,Buffer,SizeOf(Buffer),RecordsRead);
 While RecordsRead>0 do Begin
  If(ShowProgression)Then Write('.');
  BlockWrite(TargetFile,Buffer,RecordsRead);
  BlockRead(SourceFile,Buffer,SizeOf(Buffer),RecordsRead);
 End;
 If(ShowProgression)Then WriteLn;
 Close(SourceFile);
 Close(TargetFile);
 {$I+}
 CopyFile:=True;
End;

Function GetErrorMessage(Code:Word):String;Begin
 Case Code of
  0:GetErrorMessage:='';
  2:GetErrorMessage:='Fichier introuvable';
  3:GetErrorMessage:='Chemin introuvable';
  4:GetErrorMessage:='Trop de fichiers ouvert';
  5:GetErrorMessage:='Acces refuse';
  6:GetErrorMessage:='Handle de fichier invalide';
  12:GetErrorMessage:='Mode d''acces sur disque invalide';
  15:GetErrorMessage:='NumÇro de disque invalide';
  16:GetErrorMessage:='Impossible de supprimer le rÇpertoire';
  17:GetErrorMessage:='Impossible de renommer sur plusieurs volumes';
  100:GetErrorMessage:='Erreur de lecture Ö partir du disque';
  101:GetErrorMessage:='Erreur d''ecriture sur le disque';
  102:GetErrorMessage:='Fichier non attribue';
  103:GetErrorMessage:='Le fichier n''est pas ouvert';
  104:GetErrorMessage:='Le fichier n''est pas ouvert Ö l''entree';
  105:GetErrorMessage:='Le fichier n''est pas ouvert Ö la sortie';
  106:GetErrorMessage:='Numero invalide';
  150:GetErrorMessage:='Disque protege en ecriture';
  151:GetErrorMessage:='Peripherique est inconnu';
  152:GetErrorMessage:='Disque pas pret';
  153:GetErrorMessage:='Commande inconnue';
  154:GetErrorMessage:='Echec de verification CRC';
  155:GetErrorMessage:='Disque invalide';
  156:GetErrorMessage:='Erreur de recherche sur disque';
  157:GetErrorMessage:='Type de media invalide';
  158:GetErrorMessage:='Secteur introuvable';
  159:GetErrorMessage:='L''imprimante n''a plus de papier';
  160:GetErrorMessage:='Erreur d''ecriture sur le peripherique';
  161:GetErrorMessage:='Erreur de lecture sur le peripherique';
  162:GetErrorMessage:='Defaillance materielle';
  Else GetErrorMessage:='Erreur inconnue';
 End;
End;

Procedure ExtractCommand;
Var
 I,J:Byte;
Begin
 For I:=1 to Length(CmdStr)do Begin
  If Not(CmdStr[I]in['A'..'Z','a'..'z','_','-','0'..'9'])Then Begin
   CurrCommand:=StrToUpper(Copy(CmdStr,1,I-1));
   ParamList:=TrimL(Copy(CmdStr,I,255));
   For J:=1 to Length(ParamList)do Begin
    Case ParamList[J]of
     '|':Begin
      If Not(Pipe)Then Begin
       {$I-}Assign(PipeFile,'COMMAND.TMP');
       Rewrite(PipeFile);{$I-}
       If IoResult<>0 Then Begin
        WriteLn('Tuyau invalide !');
       End;
       Pipe:=True;
      End;
      PipeToCommand:=True;
      PipeCommand:=TrimL(Copy(ParamList,J+1,255));
      If J=1 Then ParamList:=''
             Else ParamList:=Copy(ParamList,1,J-1);
     End;
     '>':Begin
      If Not(Pipe)Then Begin
       {$I-}Assign(PipeFile,TrimL(Copy(ParamList,J+1,255)));
       Rewrite(PipeFile);{$I-}
       If IoResult<>0 Then Begin
        WriteLn('Tuyau invalide !');
       End
        Else
       Pipe:=True;
      End;
      If J=1 Then ParamList:=''
             Else ParamList:=Copy(ParamList,1,J-1);
     End;
    End;
   End;
   Exit;
  End;
 End;
 CurrCommand:=StrToUpper(CmdStr);
 ParamList:='';
End;

Function ExtractParam(Index:Byte):String;
Var
 Count:Word;
 LocalIndex:Word;
 l:Byte;
 Temp:String;
Begin
 Temp:='';Count:=1;LocalIndex:=1;l:=0;
 While Count<=Length(ParamList)do Begin
  If Not(ParamList[Count] in [' ',#9])then Begin
   If LocalIndex=Index Then Begin
    While (Count<=Length(ParamList)) and (Not(ParamList[count] in[' ',#9])) and (l < 256) do Begin
     Temp:=Temp+ParamList[count];
     Inc(l);
     Inc(Count);
    end;
    Temp[0]:=Char(l);
    ExtractParam:=Temp;
    Exit;
   End;
   While (Count<=Length(ParamList)) and (Not(ParamList[count] in [' ',#9])) do Inc(Count);
   Inc(LocalIndex);
  End;
  If Count>=Length(ParamList)Then Break;
  Inc(Count);
 End;
 ExtractParam:=Temp;
End;

Procedure HomeMessage;Begin
 WriteLn;
 WriteLn('MSDOS-0 COMMAND.COM');
 WriteLn('gladir.com 2021. Tous droits reserves.');
 WriteLn;
End;

Procedure ShowPrompt;
Const Week:Array[0..6]of String[3]=('Dim','Lun','Mar','Mer','Jeu','Ven','Sam');
      Mon:Array[1..12]of String[3]=('Jan','Fev','Mar','Avr','Mai','Jui',
			            'Jul','Aou','Sep','Oct','Nov','Dec');
Var
 SP,CurrentDir:String;
 I:Byte;
 Year,Month,Day,DayOfWeek,Hour,Min,Sec,Sec100:Word;
Begin
 If Not(Echo)Then Exit;
 GetDir(0,CurrentDir);
 SP:=GetEnv('PROMPT');
 If SP=''Then SP:='$P$G';
 I:=1;
 While I<=Length(SP)do Begin
  If SP[I]='$'Then Begin
   Inc(I);
   Case SP[I] of
       'D': Begin
	     GetDate(Year,Month,Day,DayOfWeek);
	     Write(Week[DayOfWeek],'  ',Mon[Month],Day,',',Year);
	    End;
       'T': Begin
	     GetTime(Hour,Min,Sec,Sec100);
	     Write(Hour,':',Min,':',Sec);
	    End;
       'B' : Write('|');
   'e','E' : Write(#27);
   'g','G' : Write('>');
       'N' : Write(GetCurrentDisk);
   'p','P' : Begin
     GetDir(0,CurrentDir);
     Write(CurrentDir);
   End;
   '-','S' : Write(' ');
       'V' : Write(Lo(DosVersion),'.',Hi(DosVersion));
   '_','Z' : Write(#13#10);
       'z' : Write('?');
   End;
  End
   Else
  Write(SP[I]);
  Inc(I);
 End;
End;

Procedure InvalidParam(P:Byte);Begin
 WriteLn('Le parametre suivant est invalide : ',ExtractParam(P));
End;

Procedure BreakCommand;
Var
 FirstParam:String;
 X:Boolean;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  Case Language of
   _Germany:Begin
    WriteLn('Schaltet (zusÑtzliche) öberwachung fÅr STRG+C ein (ON) oder aus (OFF).');
    WriteLn;
    WriteLn('BREAK [/?] [ON|OFF]');
   End;
   _English:Begin
    WriteLn('Purpose:  Display, enable, or disable Ctrl-C and Ctrl-Break checking.');
    WriteLn;
    WriteLn('Format:  BREAK [/?] [ON|OFF]');
   End;
   Else Begin
    WriteLn('BREAK   Cette commande permet de fixer ou de demander l''Çtat du Ctrl+Break.');
    WriteLn;
    WriteLn('Syntaxe:');
    WriteLn;
    WriteLn('BREAK [/?] [ON|OFF]');
    WriteLn;
    WriteLn('  /?    Ce paramätre permet d''afficher l''aide sur cette commande');
    WriteLn('  OFF   Ce paramätre permet de dÇsactiver le Ctrl+C ou Ctrl+Break.');
    WriteLn('  ON    Ce paramätre permet d''activer le Ctrl+C ou Ctrl+Break.');
   End;
  End;
 End
  Else
 If StrToUpper(ParamList)='OFF'Then SetCBreak(False) Else
 If StrToUpper(ParamList)='ON'Then SetCBreak(True)
  Else
 Begin
  GetCBreak(X);
  If(Pipe)Then Begin
   Write(PipeFile,'BREAK = ');
   If(X)Then WriteLn(PipeFile,'on')
        Else WriteLn(PipeFile,'off');
  End
   Else
  Begin
   Write('BREAK = ');
   If(X)Then WriteLn('on')
        Else WriteLn('off');
  End;
 End;
End;

Procedure CallCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure ChDirCommand;
Var
 Drive:Char;
 Error:Word;
 FirstParam,Dir,CurrPath:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  Case Language of
   _Germany:Begin
    WriteLn('Wechselt das aktuelle Verzeichnis oder zeigt dessen Namen an.');
    WriteLn;
    WriteLn('CD [path | -]');
    WriteLn('CHDIR [path | -]');
   End;
   _English:Begin
    WriteLn('Purpose:  Display or change the current directory.');
    WriteLn;
    WriteLn('Format:   CD [path | -]');
    WriteLn(' ':14,'or');
    WriteLn(' ':10,'CHDIR [path | -]');
   End;
   Else Begin
    WriteLn('CHDIR   Cette commande permet de fixer ou de demander le rÇpertoire courant.');
    WriteLn;
    WriteLn('Syntaxe:');
    WriteLn;
    WriteLn('CD [/?] chemin');
    WriteLn('CHDIR [/?] chemin');
    WriteLn;
    WriteLn('  /?     Ce paramätre permet d''afficher l''aide sur cette commande');
    WriteLn(' chemin  Ce paramätre permet d''indiquer le chemin du repÇrtoire.');
   End;
  End;
 End
  Else
 If Length(FirstParam)>0Then Begin
  GetDir(0,CurrPath);
  Drive:=GetCurrentDisk;
  {$I-} ChDir(FirstParam);{$I+}
  Error:=IoResult;
  If Error<>0Then WriteLn(GetErrorMessage(Error));
  If Drive<>GetCurrentDisk Then ChDir(CurrPath);
 End
  Else
 Begin
  GetDir(0,Dir);
  WriteLn(Dir);
 End;
End;

Procedure CHCPCommand;
Var
 Err:Word;
 Regs:Registers;
 FirstParam:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  Case Language of
   _Germany:Begin
    WriteLn('Wechselt die aktuelle Codeseite oder zeigt deren Nummer an.');
    WriteLn;
    WriteLn('CHCP [/?] [nnn]');
    WriteLn;
    WriteLn('nnn      Die Nummer einer Codeseite.');
   End;
   _English:Begin
    WriteLn('Displays or sets the active code page number.');
    WriteLn;
    WriteLn('CHCP [/?] [nnn]');
    WriteLn;
    WriteLn('nnn      Specify a code page number.');
   End;
   Else Begin
    WriteLn('CHCP   Cette commande permet de fixer ou de demander la page de codes.');
    WriteLn;
    WriteLn('Syntaxe:');
    WriteLn;
    WriteLn('CHCP [/?] [code]');
    WriteLn;
    WriteLn('  /?     Ce parametre permet d''afficher l''aide sur cette commande');
    WriteLn(' code    Ce parametre permet d''indiquer la page de code');
   End;
  End;
 End
  Else
 If FirstParam<>''Then Begin
  Regs.AX:=$6602;
  Val(FirstParam,Regs.BX,Err);
  If Err=0Then Begin
   Intr($21,Regs);
   If(Regs.Flags and FCarry=FCarry)Then Begin
    WriteLn('Impossible de changer le code de page actif');
   End;
  End
   Else
  WriteLn('Code de page invalide.');
 End
  Else
 Begin
  Regs.AX:=$6601;
  Intr($21,Regs);
  If(Regs.Flags and FCarry=FCarry)Then Begin
   WriteLn('Page de code active inconnnu');
  End
   Else
  WriteLn('Page de code active : ',Regs.BX);
 End;
End;

Procedure CLSCommand;
Var
 FirstParam:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  Case Language of
   _Germany:Begin
    WriteLn('Lîscht den Bildschirminhalt.');
    WriteLn;
    WriteLn('CLS');
   End;
   _English:Begin
    WriteLn('Purpose:  Clear the video display and move the cursor to the upper left');
    WriteLn;
    WriteLn('Format:   CLS [/?]');
   End;
   Else Begin
    WriteLn('CLS   Cette commande permet d''effacer l''Çcran.');
    WriteLn;
    WriteLn('Syntaxe:');
    WriteLn;
    WriteLn('CLS [/?]');
    WriteLn;
    WriteLn('  /?    Ce paramätre permet d''afficher l''aide sur cette commande');
   End;
  End;
 End
  Else
 Begin
  ClrScr;
 End;
End;

Procedure CopyCommand;
Var
 P:Byte;
 ShowProgression:Boolean;
 F:File;
 CurrParam,Source,Target:String;
Begin
 P:=0;
 ShowProgression:=False;
 Source:='';
 Target:='';
 Repeat
  Inc(P);
  CurrParam:=ExtractParam(P);
  If CurrParam=''Then Begin
   If P=1Then Begin
    WriteLn('Paramätre requis');
   End;
   Break;
  End
   Else
  If CurrParam='/?'Then Begin
   Case Language of
    _Germany:Begin
     WriteLn('Kopiert eine oder mehrere Dateien an eine andere Position.');
     WriteLn;
     WriteLn('COPY [/?] [/P] source target');
    End;
    _English:Begin
     WriteLn('Purpose:  Copy data between disks, directories or files.');
     WriteLn;
     WriteLn('Format:   COPY [/?] [/P] source target');
    End;
    Else Begin
     WriteLn('COPY   Cette commande permet d''effacer la copie de fichier vers un autre emplacement.');
     WriteLn;
     WriteLn('Syntaxe:');
     WriteLn;
     WriteLn('COPY [/?] [/P] source destination');
     WriteLn;
     WriteLn('    /?       Ce parametre permet d''afficher l''aide sur cette commande');
     WriteLn('    /P       Ce parametre permet d''afficher la progression de la copie');
     WriteLn('source       Ce parametre permet d''indiquer le fichier source');
     WriteLn('destination  Ce parametre permet d''indiquer le fichier destination');
     Exit;
    End;
   End;
  End
   Else
  If(CurrParam='/P')or(CurrParam='/p')Then ShowProgression:=True
   Else
  If CurrParam<>''Then
  Begin
   If Source=''Then Source:=CurrParam
               Else Target:=CurrParam;
  End;
  If P>9Then Break;
 Until CurrParam='';
 If(Source='')or(Target='')Then Begin
  WriteLn('La source et la destination sont requises');
 End
  Else
 Begin
  If CopyFile(Source,Target,ShowProgression)Then WriteLn('1 fichier copie')
                                            Else WriteLn('Echec de copie de fichier');
 End;
End;

Procedure CTTYCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure DateCommand;
Var
 FirstParam:String;
 Year,Month,Day,DayOfMonth:Word;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  Case Language of
   _Germany:Begin
    WriteLn('Wechselt das eingestellte Datum oder zeigt es an.');
    WriteLn;
    WriteLn('DATE [/?]');
   End;
   _English:Begin
    WriteLn('Purpose:  Display and optionnally change the system date.');
    WriteLn;
    WriteLn('Format:   DATE [/?]');
   End;
   Else Begin
    WriteLn('DATE   Cette commande permet de fixer ou de demander la date du systeme d''exploitation');
    WriteLn;
    WriteLn('Syntaxe:');
    WriteLn;
    WriteLn('DATE [/?]');
    WriteLn;
    WriteLn('  /?    Ce paramätre permet d''afficher l''aide sur cette commande');
   End;
  End;
 End
  Else
 Begin
  GetDate(Year,Month,Day,DayOfMonth);
  If(Pipe)Then WriteLn(PipeFile,'La date du jour est ',Year:4,'-',PadZeroLeft(Month,2),'-',PadZeroLeft(Day,2))
          Else WriteLn('La date du jour est ',Year:4,'-',PadZeroLeft(Month,2),'-',PadZeroLeft(Day,2));
 End;
End;

Procedure DeleteCommand;
Var
 P:Byte;
 Err:Word;
 F:File;
 CurrParam:String;
Begin
 P:=0;
 Repeat
  Inc(P);
  CurrParam:=ExtractParam(P);
  If CurrParam=''Then Begin
   If P=1Then Begin
    WriteLn('Paramätre requis');
   End;
   Break;
  End
   Else
  If CurrParam='/?'Then Begin
   Case Language of
    _Germany:Begin
     WriteLn('Lîscht eine oder mehrere Dateien.');
     WriteLn;
     WriteLn('DEL [/?] Datainame');
    End;
    _English:Begin
     WriteLn('Purpose:  Erase one file');
     WriteLn;
     WriteLn('Format:   DEL [/?] file');
     Exit;
    End;
    Else Begin
     WriteLn('DEL   Cette commande permet d''effectuer la suppression de fichier sur un unitÇ de disque.');
     WriteLn;
     WriteLn('Syntaxe:');
     WriteLn;
     WriteLn('DEL [/?] fichier');
     WriteLn;
     WriteLn('    /?    Ce paramätre permet d''afficher l''aide sur cette commande');
     WriteLn(' fichier  Ce paramätre permet d''indiquer le nom du fichier a supprimer.');
     Exit;
    End;
   End;
  End;
  {$I-}Assign(F,CurrParam);
  Erase(F);
  {$I+}
  Err:=IoResult;
  If Err=0Then WriteLn('1 fichier de supprime')
          Else WriteLn(GetErrorMessage(Err));
  If P>9Then Break;
 Until CurrParam='';
End;

Procedure DirCommand;
Var
 P:Byte;
 Info:SearchRec;
 T:DateTime;
 Option:Set of (Pause,Subdirectory,Lower,Brief,Description);
 Column:Set Of (Double,Width);
 TotalNumFiles,TotalSize:LongInt;
 CurrParam,ShowDir,CurrLabel:String;
 CurrDrive:Char;
Begin
 Option:=[];
 Column:=[];
 P:=0;
 ShowDir:='*.*';
 Repeat
  Inc(P);
  CurrParam:=ExtractParam(P);
  If Length(CurrParam)=0Then Break;
  If CurrParam='/?'Then Begin
   Case Language of
    _Germany:Begin
     WriteLn('Listet die Dateien und Unterverzeichnisse eines Verzeichnisses auf.');
     WriteLn;
     WriteLn('Format:   DIR [/?] [/2|/W] [/B] [/P] [path]');
    End;
    _English:Begin
     WriteLn('Purpose:  Display information about files and subdirectories.');
     WriteLn;
     WriteLn('Format:   DIR [/?] [/2|/W] [/B] [/P] [path]');
     Exit;
    End;
    Else Begin
     WriteLn('DIR   Cette commande permet d''afficher le contenu d''un repertoire dans l''unitÇ de disque.');
     WriteLn;
     WriteLn('Syntaxe:');
     WriteLn;
     WriteLn('DIR [/?] [/2|/W] [/B] [/P] [chemin]');
     WriteLn;
     WriteLn(' /?   Ce parametre permet d''afficher l''aide sur cette commande');
     WriteLn(' /2   Ce parametre permet d''afficher sur 2 colonnes');
     WriteLn(' /B   Ce parametre enleve l''entàte et les dÇtails de la fin');
     WriteLN(' /P   Ce parametre affiche une pause apres l''affichage d''une page pleine');
     WriteLn(' /W   Ce parametre affiche seulement les fichiers sur plein de colonnes');
     Exit;
    End;
   End;
  End
   Else
  If CurrParam='/2'Then Include(Column,Double) Else
  If(CurrParam='/B')or(CurrParam='/b')Then Include(Option,Brief) Else
  If(CurrParam='/L')or(CurrParam='/l')Then Include(Option,Lower) Else
  If(CurrParam='/P')or(CurrParam='/p')Then Include(Option,Pause) Else
  If(CurrParam='/W')or(CurrParam='/w')Then Include(Column,Width)
                   Else ShowDir:=CurrParam;
  If P>99Then Break;
 Until CurrParam='';
 CurrDrive:=Path2Drive(ShowDir);
 CurrLabel:=GetDiskLabel(Byte(CurrDrive)-64);
 P:=0;
 FindFirst(ShowDir,AnyFile,Info);
 If(Width)in(Column)Then While DOSError=0 do Begin
  Write(PadRight(Info.Name,16));
  FindNext(Info);
  If(Pause)in(Option)Then Begin
   Inc(P);
   If P=Hi(WindMax)Then Begin
    Write('Presse une touche pour continuer...');
    If ReadKey=#27Then Exit;
    WriteLn;
    P:=0;
   End;
  End;
 End
  Else
 If(Double)in(Column)Then While DOSError=0 do Begin
  Write(PadRight(Info.Name,13));
  If Info.Attr and Directory=Directory Then Begin
   If(Pipe)Then Write(PipeFile,PadRight('<DIR>',9))
           Else Write(PadRight('<DIR>',9));
  End
   Else
  Write(Info.Size:9);
  UnpackTime(Info.Time,T);
  If(Pipe)Then Begin
   Write(PipeFile,' ',T.Year:4,'-',PadZeroLeft(T.Month,2),'-',
         PadZeroLeft(T.Day,2),' ',T.Hour:2,':',PadZeroLeft(T.Min,2),' ');
  End
   Else
  Begin
   Write(' ',T.Year:4,'-',PadZeroLeft(T.Month,2),'-',PadZeroLeft(T.Day,2),' ',
         T.Hour:2,':',PadZeroLeft(T.Min,2),' ');
  End;
  FindNext(Info);
  If(Pause)in(Option)Then Begin
   Inc(P);
   If P=Hi(WindMax)Then Begin
    Write('Presse une touche pour continuer...');
    If ReadKey=#27Then Exit;
    WriteLn;
    P:=0;
   End;
  End;
 End
  Else
 Begin
  TotalNumFiles:=0;
  TotalSize:=0;
  If Not((Brief)in(Option))Then Begin
   Inc(P,2);
   If(Pipe)Then Begin
    WriteLn(PipeFile,'Le volume de l''unite '+CurrDrive+' est '+CurrLabel);
    WriteLn(PipeFile);
   End
    Else
   Begin
    WriteLn('Le volume de l''unite '+CurrDrive+' est '+CurrLabel);
    WriteLn;
   End;
  End;
  While DOSError=0 do Begin
   If(Pipe)Then Write(PipeFile,PadRight(Info.Name,13))
           Else Write(PadRight(Info.Name,13));
   If Info.Attr and Directory=Directory Then Begin
    If(Pipe)Then Write(PipeFile,PadRight('<DIR>',15))
            Else Write(PadRight('<DIR>',15));
   End
    Else
   Begin
    If(Pipe)Then Write(PipeFile,Info.Size:15)
            Else Write(Info.Size:15);
   End;
   UnpackTime(Info.Time,T);
   If(Pipe)Then Begin
    WriteLn(PipeFile,' ',T.Year:4,'-',PadZeroLeft(T.Month,2),'-',
            PadZeroLeft(T.Day,2),' ',T.Hour:2,':',PadZeroLeft(T.Min,2));
   End
    Else
   Begin
    WriteLn(' ',T.Year:4,'-',PadZeroLeft(T.Month,2),'-',
            PadZeroLeft(T.Day,2),' ',T.Hour:2,':',PadZeroLeft(T.Min,2));
   End;
   FindNext(Info);
   If(Pause)in(Option)Then Begin
    Inc(P);
    If P=Hi(WindMax)Then Begin
     Write('Presse une touche pour continuer...');
     If ReadKey=#27Then Exit;
     WriteLn;
     P:=0;
    End;
   End;
   Inc(TotalNumFiles);
   Inc(TotalSize,Info.Size);
  End;
  If Not((Brief)in(Option))Then Begin
   If(Pipe)Then Begin
    WriteLn(PipeFile,' Les ',TotalNumFiles,' fichier(s) utilisent ',TotalSize,' octet(s)');
    WriteLn(PipeFile,DiskFree(Byte(CurrDrive)-64):10,' octet(s) de libre');
   End
    Else
   Begin
    WriteLn(' Les ',TotalNumFiles,' fichier(s) utilisent ',TotalSize,' octet(s)');
    WriteLn(DiskFree(Byte(CurrDrive)-64):10,' octet(s) de libre');
   End;
  End;
 End;
End;

Procedure EchoCommand;
Var
 FirstParam:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  Case Language of
   _Germany:Begin
    WriteLn('Zeigt Meldungen an oder schaltet die Befehlsanzeige ein (ON) oder aus (OFF).');
    WriteLn;
    WriteLn('ECHO [ON | OFF]');
    WriteLN('ECHO [Meldung]');
   End;
   _English:Begin
    WriteLn('Purpose:  Display a message, enable or disable batch file or command-line');
    WriteLn(' ':10,'echoing, or display the echo status.');
    WriteLn;
    WriteLn('Format:   ECHO [ON | OFF | message]');
   End;
   Else Begin
    WriteLn('ECHO   Cette commande permet d''activer ou desactiver le prompt de commande ',
            'ou d''afficher un message sur le console du systeme d''exploitation.');
    WriteLn;
    WriteLn('Syntaxe:');
    WriteLn;
    WriteLn('ECHO [/?] message');
    WriteLn('ECHO [OFF|ON]');
    WriteLn;
    WriteLn('       /?  Ce parametre permet d''afficher l''aide sur cette commande');
    WriteLn('  message  Ce parametre permet d''afficher un message');
    WriteLn('      OFF  Ce parametre permet de desactiver le prompt.');
    WriteLn('       ON  Ce parametre permet d''activer le prompt.');
   End;
  End;
 End
  Else
 If ParamList='.'Then WriteLn Else
 If StrToUpper(ParamList)='OFF'Then Echo:=False Else
 If StrToUpper(ParamList)='ON'Then Echo:=True
                              Else WriteLn(ParamList);
End;

Procedure EraseCommand;
Var
 P:Byte;
 Err:Word;
 F:File;
 CurrParam:String;
Begin
 P:=0;
 Repeat
  Inc(P);
  CurrParam:=ExtractParam(P);
  If CurrParam=''Then Begin
   If P=1Then Begin
    WriteLn('Paramätre requis');
   End;
   Break;
  End
   Else
  If CurrParam='/?'Then Begin
   Case Language of
    _Germany:Begin
     WriteLn('Lîscht eine oder mehrere Dateien.');
     WriteLn;
     WriteLn('ERASE Dateiname [/P]');
    End;
    _English:Begin
     WriteLn('Purpose:  Erase one file');
     WriteLn;
     WriteLn('Format:   ERASE [/?] file');
    End;
    Else Begin
     WriteLn('ERASE   Cette commande permet d''effectuer la suppression de fichier sur un unitÇ de disque.');
     WriteLn;
     WriteLn('Syntaxe:');
     WriteLn;
     WriteLn('ERASE [/?] fichier');
     WriteLn;
     WriteLn('      /?    Ce parametre permet d''afficher l''aide sur cette commande');
     WriteLn('  fichier   Ce parametre permet d''indiquer le nom du fichier a supprimer.');
    End;
   End;
   Exit;
  End;
  {$I-}Assign(F,CurrParam);
  Erase(F);
  {$I+}
  Err:=IoResult;
  If Err=0Then WriteLn('1 fichier de supprime')
          Else WriteLn(GetErrorMessage(Err));
  If P>9Then Break;
 Until CurrParam='';
End;

Function ExitCommand:Boolean;
Var
 FirstParam:String;
 N,Err:Integer;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  Case Language of
   _Germany:Begin
    WriteLn('Beendet den Befehlsinterpreter COMMAND.COM.');
    WriteLn;
    WriteLn('Format:   EXIT [value]');
   End;
   _English:Begin
    WriteLn('Purpose:  Return from COMMAND.');
    WriteLn;
    WriteLn('Format:   EXIT [value]');
   End;
   Else Begin
    WriteLn('EXIT  Cette commande permet de quitter l''interpreteur de commande.');
    WriteLn;
    WriteLn('Syntaxe:');
    WriteLn;
    WriteLn('EXIT [/?] [CodeSortie]');
    WriteLn;
    WriteLn(' CodeSortie   Ce parametre permet d''indiquer le code de sortie a ',
                           'retourner a l''application parent');
    WriteLn('        /?    Ce parametre permet d''afficher l''aide sur cette commande');
   End;
  End;
  ExitCommand:=False;
 End
  Else
 If Length(FirstParam)>0Then Begin
  Val(FirstParam,N,Err);
  Halt(N);
  ExitCommand:=True;
 End
  Else
 ExitCommand:=True;
End;

Procedure ForCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure IfCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure LoadHighCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure MkDirCommand;Var
 P:Byte;
 Err:Word;
 CurrParam:String;
Begin
 P:=0;
 Repeat
  Inc(P);
  CurrParam:=ExtractParam(P);
  If CurrParam=''Then Begin
   If P=1Then Begin
    WriteLn('Paramätre requis');
   End;
   Break;
  End
   Else
  If CurrParam='/?'Then Begin
   Case Language of
    _Germany:Begin
     WriteLn('Erstellt ein Verichnis.');
     WriteLn;
     WriteLn('MKDIR [Laufwerk:]Pfad');
    End;
    _English:Begin
     WriteLn('Purpose:  Create a subdirectory.');
     WriteLn;
     WriteLn('MKDIR [/?] path');
    End;
    Else Begin
     WriteLn('MKDIR   Cette commande permet de creer un repertoire.');
     WriteLn;
     WriteLn('Syntaxe:');
     WriteLn;
     WriteLn('MKDIR [/?] nomrepertoire');
     WriteLn;
     WriteLn('  nomrepertoire   Ce parametre permet d''indiquer le nom du repertoire');
     WriteLn('            /?    Ce parametre permet d''afficher l''aide sur cette commande');
    End;
   End;
   Exit;
  End;
  {$I-}MkDir(CurrParam);{$I+}
  Err:=IoResult;
  If Err<>0Then WriteLn(GetErrorMessage(Err));
  If P>9Then Break;
 Until CurrParam='';
End;

Procedure PathCommand;Begin
 WriteLn(GetEnv('PATH'));
End;

Procedure PauseCommand;
Var
 FirstParam:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  Case Language of
   _Germany:Begin
    Write('HÑlt die AusfÅhrung einer Stapelverarbeitungsdatei an und zeigh ');
    WriteLn('folgende Meldung an: ''Eine belige Taste drÅcken, um fortzsetsen''');
    WriteLn;
    WriteLn('PAUSE [/?]');
   End;
   _English:Begin
    WriteLn('Purpose:  Suspend batch file or alias extension.');
    WriteLn;
    WriteLn('PAUSE [text]');
   End;
   Else Begin
    WriteLn('PAUSE   Cette commande permet d''afficher un message de pause et une ',
            'attente d''une action utilisateur pour poursuivre.');
    WriteLn;
    WriteLn('Syntaxe:');
    WriteLn;
    WriteLn('PAUSE [/?] [texte]');
    WriteLn;
    WriteLn('   /?    Ce paramätre permet d''afficher l''aide sur cette commande');
    WriteLn(' texte   Ce paramätre permet d''indiquer le message de remplacement.');
   End;
  End;
 End
  Else
 If FirstParam<>''Then Begin
  WriteLn(ParamList);
  ReadKey;
 End
  Else
 Begin
  Case Language of
   _Germany:WriteLn('Eine belige Taste drÅcken, um fortzsetsen');
   _English:WriteLn('Strike a key when ready...');
   Else WriteLn('Presse une touche pour continuer...');
  End;
  ReadKey;
 End;
End;

Procedure PromptCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure RmDirCommand;Var
 P:Byte;
 Err:Word;
 CurrParam:String;
Begin
 P:=0;
 Repeat
  Inc(P);
  CurrParam:=ExtractParam(P);
  If CurrParam=''Then Begin
   If P=1Then Begin
    WriteLn('Paramätre requis');
   End;
   Break;
  End
   Else
  If CurrParam='/?'Then Begin
   Case Language of
    _Germany:Begin
     WriteLn('Eine belige Taste drÅcken, um fortzsetsen');
     WriteLn;
     WriteLn('RMDIR [Laufwerk:]Pfad');
    End;
    _English:Begin
     WriteLn('Purpose:  Remove one or more subdirectories.');
     WriteLn;
     WriteLn('Format:   RMDIR path');
    End;
    Else Begin
     WriteLn('RMDIR   Cette commande permet de supprimer un repertoire vide.');
     WriteLn;
     WriteLn('Syntaxe:');
     WriteLn;
     WriteLn('RMDIR [/?] nomrepertoire');
     WriteLn;
     WriteLn('  /?           Ce parametre permet d''afficher l''aide sur cette commande');
     WriteLn('nomrepertoire  Ce parametre permet d''indiquer le nom du repertoire');
    End;
   End;
   Exit;
  End;
  {$I-}RmDir(CurrParam);{$I+}
  Err:=IoResult;
  If Err<>0Then WriteLn(GetErrorMessage(Err));
  If P>9Then Break;
 Until CurrParam='';
End;

Procedure RemCommand;
Var
 FirstParam:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  Case Language of
   _Germany:Begin
    WriteLn('Leitet Kommentare in einer Stapelverarbeitungsdatei oder ',
            'in CONFIG.SYS ein.');
    WriteLn;
    WriteLn('REM [Kommentar]');
   End;
   Else Begin
    WriteLn('REM   Cette commande permet d''indiquer une remarque.');
    WriteLn;
    WriteLn('Syntaxe:');
    WriteLn;
    WriteLn('REM [/?] commentaires');
    WriteLn;
    WriteLn('  /?           Ce parametre permet d''afficher l''aide sur cette commande');
    WriteLn('commentaires   Ce parametre permet d''indiquer une remarque');
   End;
  End;
 End;
End;

Procedure RenameCommand;
Var
 P:Byte;
 Err:Word;
 F:File;
 CurrParam,Source,Target:String;
Begin
 P:=0;
 Source:='';
 Target:='';
 Repeat
  Inc(P);
  CurrParam:=ExtractParam(P);
  If CurrParam=''Then Begin
   If P=1Then Begin
    WriteLn('Paramätre requis');
   End;
   Break;
  End
   Else
  If CurrParam='/?'Then Begin
   Case Language of
    _Germany:Begin
     WriteLn('Benennt eine oder mehrere Dateien um.');
     WriteLn;
     WriteLn('REN [Laufwerk:][Pfad]Dateiname1 Dateiname2');
     WriteLn('RENAME [Laufwerk:][Pfad]Dateiname1 Dateiname2');
    End;
    _English:Begin
     WriteLn('Purpose:  Rename files.');
     WriteLn;
     WriteLn('Format:   REN old_name new_name');
    End;
    Else Begin
     WriteLn('RENAME   Cette commande permet de renommer un fichier.');
     WriteLn;
     WriteLn('Syntaxe:');
     WriteLn;
     WriteLn('RENAME [/?] anciennom nouveaunom');
     WriteLn;
     WriteLn(' /?         Ce parametre permet d''afficher l''aide sur cette commande');
     WriteLn('anciennom   Ce parametre permet d''indiquer l''ancien nom');
     WriteLn('nouveaunom  Ce parametre permet d''indiquer le nouveau nom');
    End;
   End;
   Exit;
  End
   Else
  If CurrParam<>''Then
  Begin
   If Source=''Then Source:=CurrParam
               Else Target:=CurrParam;
  End;
  If P>9Then Break;
 Until CurrParam='';
 If(Source='')or(Target='')Then Begin
  WriteLn('La source et la destination sont requises');
 End
  Else
 Begin
  {$I-}Assign(F,Source);
  Rename(F,Target);
  {$I+}
  Err:=IoResult;
  If Err=0Then WriteLn('1 fichier de renomme')
          Else WriteLn(GetErrorMessage(Err));
 End;
End;

Procedure SetCommand;
Var
 Pause:Boolean;
 I,P:Integer;
 FirstParam,VarName,VarValue:String;
Begin
 Pause:=False;
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  Case Language of
   _Germany:Begin
    WriteLn('Setzt oder entfernt DOS-Umgebungsvariablen oder zeigt sie an.');
    WriteLn;
    WriteLn('SET [Variable=[Zeichenfolge]]');
   End;
   _English:Begin
    WriteLn('Purpose:  Display, create, modify, or delete environment variables.');
    WriteLn;
    WriteLn('Format:   SET [/?] [/P]');
   End;
   Else Begin
    WriteLn('SET   Cette commande permet de fixer ou demander le contenu des ',
            'variables d''environnement du systeme d''exploitation');
    WriteLn;
    WriteLn('Syntaxe:');
    WriteLn;
    WriteLn('SET [/?] [/P]');
    WriteLn;
    WriteLn(' /?   Ce parametre permet d''afficher l''aide sur cette commande');
    WriteLn(' /P   Ce parametre permet d''effectuer une pause entre chaque page');
   End;
  End;
  Exit;
 End
  Else
 If Pos('=',FirstParam)>0 Then Begin
  VarName:=Copy(FirstParam,1,Pos('=',FirstParam)-1);
  VarValue:=Copy(FirstParam,Pos('=',FirstParam)+1,255);
  SetEnv(VarName,VarValue);
 End
  Else
 Begin
  If(FirstParam='/P')or(FirstParam='/p')Then Pause:=True;
  P:=0;
  For I:=0to EnvCount do Begin
   WriteLn(EnvStr(I));
   If(Pause)Then Begin
    Inc(P);
    If P=Hi(WindMax)Then Begin
     Write('Presse une touche pour continuer...');
     ReadKey;
     WriteLn;
     P:=0;
    End;
   End;
  End;
 End;
End;

Procedure ShiftCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure TimeCommand;
Var
 FirstParam:String;
 Hour,Minute,Second,CentSec:Word;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  Case Language of
   _English:Begin
    WriteLn('Purpose:  Display or set the current system time.');
    WriteLn;
    WriteLn('Format:   TIME [/?]');
   End;
   Else Begin
    WriteLn('TIME   Cette commande permet de fixer ou de demander l''heure du systeme d''exploitation');
    WriteLn;
    WriteLn('Syntaxe:');
    WriteLn;
    WriteLn('TIME [/?]');
    WriteLn;
    WriteLn('  /?    Ce parametre permet d''afficher l''aide sur cette commande');
   End;
  End;
 End
  Else
 Begin
  GetTime(Hour,Minute,Second,CentSec);
  WriteLn('L''heure actuelle est ',Hour:2,':',PadZeroLeft(Minute,2),':',PadZeroLeft(Second,2),',',CentSec);
 End;
End;

Procedure TrueNameCommand;
Var
 P:Byte;
 CurrParam:String;
 CurrDirectory:String;
Begin
 P:=0;
 Repeat
  Inc(P);
  CurrParam:=ExtractParam(P);
  If CurrParam=''Then Begin
   If P=1Then Begin
    GetDir(0,CurrDirectory);
    WriteLn(CurrDirectory);
   End;
   Break;
  End
   Else
  If CurrParam='/?'Then Begin
   Case Language of
    _English:Begin
     WriteLn('Purpose:  Find the full, true path and file name for a file.');
     WriteLn;
     WriteLn('Format:   TRUENAME file');
    End;
    Else Begin
     WriteLn('TRUENAME   Cette commande permet d''afficher le nom complet d''un unite, repertoire ou d''un nom de fichier');
     WriteLn;
     WriteLn('Syntaxe:');
     WriteLn;
     WriteLn('TRUENAME [/?] [chemin]');
     WriteLn;
     WriteLn(' /?     Ce parametre permet d''afficher l''aide sur cette commande');
     WriteLn('chemin  Ce parametre permet d''indiquer le nom du chemin a analyser');
    End;
   End;
   Exit;
  End;
  WriteLn(FExpand(CurrParam));
  If P>9Then Break;
 Until CurrParam='';
End;

Procedure TypeCommand;
Var
 P:Byte;
 Err:Word;
 Handle:Text;
 CurrParam,CurrLine:String;
Begin
 P:=0;
 Repeat
  Inc(P);
  CurrParam:=ExtractParam(P);
  If(Length(CurrParam)=0)and(P=1)Then Begin
   WriteLn('La syntaxe est incorrecte');
   Exit;
  End;
  If CurrParam='/?'Then Begin
   Case Language of
    _English:Begin
     WriteLn('Purpose:  Display the contents of the specified file(s).');
     WriteLn;
     WriteLn('TYPE [/?] [file]');
    End;
    Else Begin
     WriteLn('TYPE   Cette commande permet d''afficher le contenu d''un fichier');
     WriteLn;
     WriteLn('Syntaxe:');
     WriteLn;
     WriteLn('TYPE [/?] [fichier]');
     WriteLn;
     WriteLn('  /?     Ce parametre permet d''afficher l''aide sur cette commande');
     WriteLn('fichier  Ce parametre permet d''indiquer le nom du fichier a afficher');
     Exit;
    End;
   End;
  End;
  If CurrParam<>''Then Begin
   Assign(Handle,CurrParam);
   {$I-}Reset(Handle);{$I+}
   Err:=IOResult;
   If Err<>0Then Begin
    WriteLn('Nom du fichier : "',CurrParam,'"');
    WriteLn(GetErrorMessage(Err));
    Exit;
   End;
   While NOT EOF(Handle)do Begin
    ReadLn(Handle,CurrLine);
    If(Pipe)Then WriteLn(PipeFile,CurrLine)
            Else WriteLn(CurrLine);
   End;
   Close(Handle);
  End;
  If P>9Then Break;
 Until CurrParam='';
End;

Procedure VerCommand;
Var
 Ver:Word;
 FirstParam:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  Case Language of
   _English:Begin
    WriteLn('Purpose:  Display the current command processor and operating system');
    WriteLn(' ':10,'versions.');
    WriteLn;
    WriteLn('Format:   VER [/?]');
   End;
   Else Begin
    WriteLn('VER   Cette commande permet de demander la version du systeme d''exploitation.');
    WriteLn;
    WriteLn('Syntaxe:');
    WriteLn;
    WriteLn('VER [/?]');
    WriteLn;
    WriteLn(' /?    Ce parametre permet d''afficher l''aide sur cette commande');
   End;
  End;
 End
  Else
 Begin
  Ver:=DosVersion;
  WriteLn('DOS version ',Lo(Ver),'.',Hi(Ver));
 End;
End;

Procedure VerifyCommand;Var
 FirstParam:String;
 X:Boolean;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  Case Language of
   _English:Begin
    WriteLn('Purpose:  Enable or disable disk write verification or display the');
    WriteLn(' ':10,'verification state.');
    WriteLn;
    WriteLn('Format:   VERIFY [ON | OFF]');
   End;
   Else Begin
    WriteLn('VERIFY   Cette commande permet de fixer ou de demander l''etat du ',
            'drapeau de verification de lecture de secteur d''unite d''allocation du systeme d''exploitation.');
    WriteLn;
    WriteLn('Syntaxe:');
    WriteLn;
    WriteLn('VERIFY [/?] [OFF|ON]');
    WriteLn;
    WriteLn('  /?    Ce parametre permet d''afficher l''aide sur cette commande');
    WriteLn(' OFF    Ce parametre permet d''activer la verification');
    WriteLn(' ON     Ce parametre permet de desactiver la verification');
   End;
  End;
 End
  Else
 If StrToUpper(ParamList)='OFF'Then SetVerify(False) Else
 If StrToUpper(ParamList)='ON'Then SetVerify(True)
  Else
 Begin
  GetVerify(X);
  Write('VERIFY = ');
  If(X)Then WriteLn('on')
       Else WriteLn('off');
 End;
End;

Procedure VolCommand;
Var
 FirstParam,Volume:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  Case Language of
   _English:Begin
    WriteLn('Purpose:  Display disk volume label(s).');
    WriteLn;
    WriteLn('Format:   VOL [d:] ...');
   End;
   Else Begin
    WriteLn('VOL   Cette commande permet d''afficher le nom du volume d''une unite de disque.');
    WriteLn;
    WriteLn('Syntaxe:');
    WriteLn;
    WriteLn('VOL [/?] [unite:]');
    WriteLn;
    WriteLn(' /?      Ce parametre permet d''afficher l''aide sur cette commande');
    WriteLn(' unite:  Ce paramtre permet d''indiquer la lettre d''unite de disque');
   End;
  End;
 End
  Else
 If(Length(FirstParam)=2) and (FirstParam[2]=':')Then Begin
  If FirstParam[2]=':'Then Begin
   Write('Le volume de l''unite ',UpCase(FirstParam[1]));
   Volume:=GetDiskLabel(Byte(UpCase(FirstParam[1]))-64);
   If Length(Volume)=0Then WriteLn(' n''a pas d''etiquette')
                      Else WriteLn(Volume);
  End
   Else
  InvalidParam(1);
 End
  Else
 If Length(FirstParam)>0Then Begin
  InvalidParam(1);
 End
  Else
 Begin
   Write('Le volume de l''unite ',GetCurrentDisk);
   Volume:=GetDiskLabel(0);
   If Length(Volume)=0Then WriteLn(' n''a pas d''etiquette')
                      Else WriteLn(Volume);
 End;
End;

Procedure UnknownCommand;
Var
 Err:Word;
Begin
 Exec(CurrCommand,ParamList);
 Err:=DosError;
 Case Err of
  0:;
  2:WriteLn('Commande ou nom de fichier non reconnu');
  Else Write(GetErrorMessage(Err));
 End;
 WriteLn;
End;

Procedure RunCommand;
Label
 Restart;
Var
 LastEcho:Boolean;
 FileBat:Text;
 OY:Byte;
 Error:Word;
 PipeS:String;
Begin
  { Change d'unitÇ de disque A:, B:, C:, D:,... }
 If(Length(CmdStr)=2)and(CmdStr[2]=':')and(CmdStr[1]in['A'..'Z','a'..'z'])Then Begin
  {$I-}GetDir(Ord(UpCase(CmdStr[1]))-64,PipeS);
  If PipeS<>''Then ChDir(PipeS)
              Else ChDir(CmdStr+'\');{$I+}
  Error:=IoResult;
  If Error<>0Then WriteLn(GetErrorMessage(Error));
  Exit;
 End;
  { Recherche une commande interne }
Restart:
 ExtractCommand;
 CommandFound:=False;
 For J:=Low(CommandList) to High(CommandList) do Begin
  If(PipeToCommand)and(StrToUpper(CurrCommand)='MORE')Then Begin
   Reset(PipeFile);
   OY:=1;
   While Not EOF(PipeFile)do Begin
    ReadLn(PipeFile,PipeS);
    WriteLn(PipeS);
    Inc(OY);
    If OY=25 Then Begin
     Write('Presse ESC pour quitter ou une autre touche pour continuer...');
     If ReadKey=#27 Then Begin
      WriteLn;
      Break;
     End;
     OY:=1;
    End;
   End;
   Close(PipeFile);
   Pipe:=False;
   PipeToCommand:=False;
   CommandFound:=True;
   Exit;
  End
   Else
  If CurrCommand=CommandList[J]Then Begin
   Case(J)of
    0:BreakCommand;
    1:CallCommand;
    2:ChDirCommand;
    3:CHCPCommand;
    4:ChDirCommand;
    5:CLSCommand;
    6:CopyCommand;
    7:CTTYCommand;
    8:DeleteCommand;
    9:DeleteCommand;
    10:DirCommand;
    11:EchoCommand;
    12:EraseCommand;
    13:EraseCommand;
    14:Terminated:=ExitCommand;
    15:ForCommand;
    16:IfCommand;
    17:LoadHighCommand;
    18:MkDirCommand;
    19:MkDirCommand;
    20:PathCommand;
    21:PauseCommand;
    22:PromptCommand;
    23:RmDirCommand;
    24:RemCommand;
    25:RenameCommand;
    26:RenameCommand;
    27:RmDirCommand;
    28:SetCommand;
    29:ShiftCommand;
    30:TimeCommand;
    31:TrueNameCommand;
    32:TypeCommand;
    33:VerCommand;
    34:VerifyCommand;
    35:VolCommand;
    36:DateCommand;
   End;
   If J<=High(CommandList)Then Begin
    CommandFound:=True;
    WriteLn;
    Break;
   End;
  End;
 End;
 If(PipeToCommand)Then Begin
  If Not(CommandFound)Then Begin
   WriteLn('Commande non supportÇ dans un contexte du tuyau');
   Exit;
  End;
  CmdStr:=PipeCommand;
  PipeCommand:='';
  Goto Restart;
 End;
 If(Pipe)Then Begin
  If Not(CommandFound)Then Begin
   WriteLn('Redirection non supportÇ dans un contexte du tuyau');
   Exit;
  End;
  Pipe:=False;
  Close(PipeFile);
 End;
 If Not(CommandFound)Then Begin
  If CmdStr='?'Then Begin
   For I:=Low(CommandList) to High(CommandList) do Write(PadRight(CommandList[I],10));
   WriteLn;
   WriteLn;
  End
   Else
  If FileExist(CmdStr+'.BAT')Then Begin
   Inc(InCmd);
   If InCmd>20Then Begin
    WriteLn('Limite de 20 fichiers de traitements par lots maximum.');
    Exit;
   End;
   LastEcho:=Echo;
   Assign(FileBat,CmdStr+'.BAT');
   {$I-}Reset(FileBat);{$I+}
   If IOResult=0Then Begin
    While Not EOF(FileBat)do Begin
     ReadLn(FileBat,CmdStr);
     If(Echo)Then WriteLn(CmdStr);
     RunCommand;
    End;
   End
    Else
   WriteLn('Probleme de lecture du fichier de traitement par lot');
   Close(FileBat);
   Echo:=LastEcho;
   Dec(InCmd);
  End
   Else
  UnknownCommand;
 End;
End;

BEGIN
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ENDIF}
 {$ENDIF}
 Language:=_French;
 TmpLanguage:=GetEnv('LANGUAGE');
 If TmpLanguage<>''Then Begin
  If TmpLanguage[1]='"'Then TmpLanguage:=Copy(TmpLanguage,2,255);
  If StrToUpper(Copy(TmpLanguage,1,2))='EN'Then Language:=_English Else
  If StrToUpper(Copy(TmpLanguage,1,2))='GR'Then Language:=_Germany Else
  If StrToUpper(Copy(TmpLanguage,1,2))='IT'Then Language:=_Italian Else
  If StrToUpper(Copy(TmpLanguage,1,2))='SP'Then Language:=_Spain;
 End;
 Echo:=True;Pipe:=False;PipeToCommand:=False;
 InCmd:=0;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  Case Language of
   _Germany:Begin
    WriteLn('COMMAND : Startet eine neue Kopie des DOS-Befehlsinterpreters.');
    WriteLn;
    WriteLn('COMMAND [/C Befehl]');
   End;
   _English:Begin
    WriteLn('COMMAND : Start a new copy of the DOS Command Interpreter.');
    WriteLn;
    WriteLn('Syntax : COMMAND [/C command]');
   End;
   Else Begin
    WriteLn('COMMAND : Cette commande permet de lancer l''interpreteur de commande.');
    WriteLn;
    WriteLn('Syntaxe : COMMAND [/C command]');
   End;
  End;
 End
  Else
 If ParamCount>1Then Begin
  Option:=optNone;
  For I:=1 to ParamCount do Begin
   If(Option=optCommand)Then Begin
    CmdStr:=ParamStr(I);
    RunCommand;
    Option:=optNone;
   End
    Else
   If StrToUpper(ParamStr(I))='/C'Then Option:=optCommand
    Else
   Begin
    WriteLn('Parametre non reconnu : ',ParamStr(I));
   End;
  End;
 End
  Else
 Begin
  Terminated:=False;
  HomeMessage;
  Repeat
   ShowPrompt;
   ReadLn(CmdStr);
   RunCommand;
  Until Terminated;
 End;
END.
