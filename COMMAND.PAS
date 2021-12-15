{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Free Pascal)
}

Program COMMAND;

Uses Crt,DOS;

Const
 CommandList:Array[0..36]of String[8]=(
  'BREAK','CALL','CD','CHCP','CHDIR','CLS','COPY','CTTY','DEL','DELETE',
  'DIR','ECHO','ERA','ERASE','EXIT','FOR','IF','LOADHIGH','MD','MKDIR',
  'PATH','PAUSE','PROMPT','RD','REM','REN','RENAME','RMDIR','SET',
  'SHIFT','TIME','TRUENAME','TYPE','VER','VERIFY','VOL','DATE'
 );

Var
 Echo:Boolean;
 CommandFound,Terminated:Boolean;
 CmdStr:String;
 CurrCommand,ParamList:String;
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
 I:Byte;
Begin
 For I:=1 to Length(CmdStr)do Begin
  If Not(CmdStr[I]in['A'..'Z','a'..'z','_','-','0'..'9'])Then Begin
   CurrCommand:=StrToUpper(Copy(CmdStr,1,I-1));
   ParamList:=TrimL(Copy(CmdStr,I,255));
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
  WriteLn('BREAK   Cette commande permet de fixer ou de demander l''etat du Ctrl+Break.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('BREAK [/?]');
  WriteLn;
  WriteLn('  /?    Ce parametre permet d''afficher l''aide sur cette commande');
 End
  Else
 Begin
  GetCBreak(X);
  Write('BREAK = ');
  If(X)Then WriteLn('on')
       Else WriteLn('off');
 End;
End;

Procedure CallCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure ChDirCommand;
Var
 Error:Word;
 FirstParam,Dir:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  WriteLn('CHDIR   Cette commande permet de fixer ou de demander le repertoire courant.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('CD [/?] chemin');
  WriteLn('CHDIR [/?] chemin');
  WriteLn;
  WriteLn('  /?     Ce parametre permet d''afficher l''aide sur cette commande');
  WriteLn(' chemin  Ce parametre permet d''indiquer le chemin du repertoire.');
 End
  Else
 If Length(FirstParam)>0Then Begin
  {$I-} ChDir(FirstParam);{$I+}
  Error:=IoResult;
  If Error<>0Then WriteLn(GetErrorMessage(Error));
 End
  Else
 Begin
  GetDir(0,Dir);
  WriteLn(Dir);
 End;
End;

Procedure CHCPCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure CLSCommand;
Var
 FirstParam:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  WriteLn('CLS   Cette commande permet d''effacer l''ecran.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('CLS [/?]');
  WriteLn;
  WriteLn('  /?    Ce parametre permet d''afficher l''aide sur cette commande');
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

Procedure DeleteCommand;Var
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
   WriteLn('DEL   Cette commande permet d''effectuer la suppression de fichier sur un unite de disque.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('DEL [/?] fichier');
   WriteLn;
   WriteLn('    /?    Ce parametre permet d''afficher l''aide sur cette commande');
   WriteLn(' fichier  Ce parametre permet d''indiquer le nom du fichier a supprimer.');
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
   WriteLn('DIR   Cette commande permet d''afficher le contenu d''un repertoire dans l''unite de disque.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('DIR [/?] [/2|/W] [/B] [/P] [chemin]');
   WriteLn;
   WriteLn(' /?   Ce parametre permet d''afficher l''aide sur cette commande');
   WriteLn(' /2   Ce parametre permet d''afficher sur 2 colonnes');
   WriteLn(' /B   Ce parametre enleve l''entete et les details de la fin');
   WriteLN(' /P   Ce parametre affiche une pause apres l''affichage d''une page pleine');
   WriteLn(' /W   Ce parametre affiche seulement les fichiers sur plein de colonnes');
   Exit;
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
   Write(PadRight('<DIR>',9));
  End
   Else
  Write(Info.Size:9);
  UnpackTime(Info.Time,T);
  Write(' ',T.Year:4,'-',PadZeroLeft(T.Month,2),'-',PadZeroLeft(T.Day,2),' ',T.Hour:2,':',PadZeroLeft(T.Min,2),' ');
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
   WriteLn('Le volume de l''unite '+CurrDrive+' est '+CurrLabel);
   WriteLn;
  End;
  While DOSError=0 do Begin
   Write(PadRight(Info.Name,13));
   If Info.Attr and Directory=Directory Then Begin
    Write(PadRight('<DIR>',15));
   End
    Else
   Write(Info.Size:15);
   UnpackTime(Info.Time,T);
   WriteLn(' ',T.Year:4,'-',PadZeroLeft(T.Month,2),'-',PadZeroLeft(T.Day,2),' ',T.Hour:2,':',PadZeroLeft(T.Min,2));
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
   WriteLn(' Les ',TotalNumFiles,' fichier(s) utilisent ',TotalSize,' octet(s)');
   WriteLn(DiskFree(Byte(CurrDrive)-64):10,' octet(s) de libre');
  End;
 End;
End;

Procedure EchoCommand;
Var
 FirstParam:String;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
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
 End
  Else
 If ParamList='.'Then WriteLn Else
 If StrToUpper(ParamList)='OFF'Then Echo:=False Else
 If StrToUpper(ParamList)='ON'Then Echo:=True
                              Else WriteLn(ParamList);
End;

Procedure EraseCommand;Var
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
   WriteLn('ERASE   Cette commande permet d''effectuer la suppression de fichier sur un unite de disque.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('ERASE [/?] fichier');
   WriteLn;
   WriteLn('      /?    Ce parametre permet d''afficher l''aide sur cette commande');
   WriteLn('  fichier   Ce parametre permet d''indiquer le nom du fichier a supprimer.');
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
  WriteLn('EXIT  Cette commande permet de quitter l''interpreteur de commande.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('EXIT [/?] [CodeSortie]');
  WriteLn;
  WriteLn(' CodeSortie   Ce parametre permet d''indiquer le code de sortie a ',
                         'retourner a l''application parent');
  WriteLn('        /?    Ce parametre permet d''afficher l''aide sur cette commande');
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
   WriteLn('MKDIR   Cette commande permet de creer un repertoire.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('MKDIR [/?] nomrepertoire');
   WriteLn;
   WriteLn('  nomrepertoire   Ce parametre permet d''indiquer le nom du repertoire');
   WriteLn('            /?    Ce parametre permet d''afficher l''aide sur cette commande');
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
  WriteLn('PAUSE   Cette commande permet d''afficher un message de pause et une ',
          'attente d''une action utilisateur pour poursuivre.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('PAUSE [/?]');
  WriteLn;
  WriteLn('   /?    Ce parametre permet d''afficher l''aide sur cette commande');
 End
  Else
 Begin
  WriteLn('Presse une touche pour continuer...');
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
   WriteLn('RMDIR   Cette commande permet de supprimer un repertoire vide.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('RMDIR [/?] nomrepertoire');
   WriteLn;
   WriteLn('  /?           Ce parametre permet d''afficher l''aide sur cette commande');
   WriteLn('nomrepertoire  Ce parametre permet d''indiquer le nom du repertoire');
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
   WriteLn('RENAME   Cette commande permet de renommer un fichier.');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('RENAME [/?] anciennom nouveaunom');
   WriteLn;
   WriteLn(' /?         Ce parametre permet d''afficher l''aide sur cette commande');
   WriteLn('anciennom   Ce parametre permet d''indiquer l''ancien nom');
   WriteLn('nouveaunom  Ce parametre permet d''indiquer le nouveau nom');
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
 FirstParam:String;
Begin
 Pause:=False;
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  WriteLn('SET   Cette commande permet de fixer ou demander le contenu des ',
          'variables d''environnement du systeme d''exploitation');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('SET [/?] [/P]');
  WriteLn;
  WriteLn(' /?   Ce parametre permet d''afficher l''aide sur cette commande');
  WriteLn(' /P   Ce parametre permet d''effectuer une pause entre chaque page');
  Exit;
 End
  Else
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
  WriteLn('TIME   Cette commande permet de fixer ou l''heure du systeme d''exploitation');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('TIME [/?]');
  WriteLn;
  WriteLn('  /?    Ce parametre permet d''afficher l''aide sur cette commande');
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
   WriteLn('TRUENAME   Cette commande permet d''afficher le nom complet d''un unite, repertoire ou d''un nom de fichier');
   WriteLn;
   WriteLn('Syntaxe:');
   WriteLn;
   WriteLn('TRUENAME [/?] [chemin]');
   WriteLn;
   WriteLn(' /?     Ce parametre permet d''afficher l''aide sur cette commande');
   WriteLn('chemin  Ce parametre permet d''indiquer le nom du chemin a analyser');
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
    WriteLn(CurrLine);
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
  WriteLn('VER   Cette commande permet de demander la version du systeme d''exploitation.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('VER [/?]');
  WriteLn;
  WriteLn(' /?    Ce parametre permet d''afficher l''aide sur cette commande');
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
  WriteLn('VOL   Cette commande permet d''afficher le nom du volume d''une unite de disque.');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('VOL [/?] [unite:]');
  WriteLn;
  WriteLn(' /?      Ce parametre permet d''afficher l''aide sur cette commande');
  WriteLn(' unite:  Ce paramtre permet d''indiquer la lettre d''unite de disque');
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

Procedure DateCommand;
Var
 FirstParam:String;
 Year,Month,Day,DayOfMonth:Word;
Begin
 FirstParam:=ExtractParam(1);
 If FirstParam='/?'Then Begin
  WriteLn('DATE   Cette commande permet de fixer ou de demander la date du systeme d''exploitation');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('DATE [/?]');
  WriteLn;
  WriteLn('  /?    Ce parametre permet d''afficher l''aide sur cette commande');
 End
  Else
 Begin
  GetDate(Year,Month,Day,DayOfMonth);
  WriteLn('La date du jour est ',Year:4,'-',PadZeroLeft(Month,2),'-',PadZeroLeft(Day,2));
 End;
End;

Procedure UnknownCommand;Begin
 Exec(CurrCommand,ParamList);
 If DosError<>0Then Begin
  WriteLn('Commande ou nom de fichier non reconnu');
 End;
 WriteLn;
End;

BEGIN
 Echo:=True;Terminated:=False;
 HomeMessage;
 Repeat
  ShowPrompt;
  ReadLn(CmdStr);
  ExtractCommand;
  CommandFound:=False;
  For J:=Low(CommandList) to High(CommandList) do Begin
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
  If Not(CommandFound)Then Begin
   If CmdStr='?'Then Begin
    For I:=Low(CommandList) to High(CommandList) do Write(PadRight(CommandList[I],10));
    WriteLn;
    WriteLn;
   End
    Else
   UnknownCommand;
  End;
 Until Terminated;
END.
