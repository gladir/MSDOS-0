{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program _APPEND;

Uses DOS;

Var
 Language:(_Albanian,_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 Regs:Registers;
 I:Integer;
 C:Char;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

BEGIN
 Language:=_French;
 TmpLanguage:=GetEnv('LANGUAGE');
 If TmpLanguage<>''Then Begin
  If TmpLanguage[1]='"'Then TmpLanguage:=Copy(TmpLanguage,2,255);
  If StrToUpper(Copy(TmpLanguage,1,2))='EN'Then Language:=_English Else
  If StrToUpper(Copy(TmpLanguage,1,2))='GR'Then Language:=_Germany Else
  If StrToUpper(Copy(TmpLanguage,1,2))='IT'Then Language:=_Italian Else
  If StrToUpper(Copy(TmpLanguage,1,2))='SP'Then Language:=_Spain Else
  If(StrToUpper(Copy(TmpLanguage,1,2))='SQ')or
    (StrToUpper(Copy(TmpLanguage,1,3))='ALB')Then Language:=_Albanian;
 End;
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  Case Language of
   _Albanian:Begin
    WriteLn('APPEND : Kjo komandâ ju lejon tâ hapni dosje tâ vendosura nâ repertorâ te ',
                     'specifikuar sikur tâ ishte repertori aktual.');
    WriteLn;
    WriteLn('Sintaksa: APPEND [/E] [/PATH:ON|OFF] [/X:ON|OFF]');
    WriteLn;
    WriteLn(' /E         Duhet tâ lidhni listân e repertorâve me njâ variabâl tâ ',
                         'quajtur "APPEND"');
    WriteLn(' /PATH:OFF  Mos kârkoni nâ listân e repertorâve tâ shtuara kur kârkoni ',
                         'dosje tâ dhânash.');
    WriteLn(' /PATH:ON   Duhet tâ kârkoni nâpâr listân e repertorâve tâ shtuara ',
                         'kur kârkoni dosje tâ dhânash.');
    WriteLn(' /X:OFF     Mos kârkoni nâ listân e repertorâve tâ shtuara kur ',
                         'ekzekutoni njâ program.');
    WriteLn(' /X:ON      Duhet tâ kârkoni tâ kârkoni nâ listân e repertorâve ',
                         'tâ shtuara gjatâ ekzekutimit tâ njâ programi.');
   End;
   _Germany:Begin
    WriteLn('Ermîglicht Programmen das Offnen von Datedateien in den angegebenen ');
    WriteLn('Verzeichnissen, als ob sie im aktuellen Verzichnis wÑren.');
    WriteLn;
    WriteLn('APPEND [[Laufwerk:]Pfad[;...]] [/X[:ON|:OFF]] [/PATH:ON|/PATH:OFF] [/E]');
   End;
   _English:Begin
    WriteLn('APPEND : Allows programs to open data files in specified ',
            'directories as if they were in the current directory.');
    WriteLn;
    WriteLn('Syntax : APPEND [/E] [/PATH:ON|OFF] [/X:ON|OFF]');
    WriteLn;
    WriteLn(' /E         Stores a copy of the appended directory list in an environment');
    WriteLn('            variable named APPEND. /E may by used only the first time');
    WriteLn('            you use APPEND after starting your system.');
    WriteLn(' /PATH:ON   Applies appended directories to file requests that already');
    WriteLn('            specify a path.  /PATH:ON is the default setting.');
    WriteLn(' /PATH:OFF  Turns off the effect of /PATH:ON.');
    WriteLn(' /X:OFF     Applies appended directories to file requests to open files.');
    WriteLn('            /X:OFF is the default setting.');
    WriteLn(' /X:ON      Applies appended directories to file searches and');
    WriteLn('            application execution.');
   End;
   Else Begin
    WriteLn('APPEND : Cette commande permet d''ouvrir des fichiers ',
                 'quelques se trouvant dans les rÇpertoires spÇcifiÇs ',
           'comme s''il s''agissait du rÇpertoire courant.');
    WriteLn;
    WriteLn('Syntaxe : APPEND [/E] [/PATH:ON|OFF] [/X:ON|OFF]');
    WriteLn;
    WriteLn(' /E         Il faut associÇ la liste des rÇpertoires Ö une variable');
    WriteLn('            d''environnement se nommant ÆAPPENDØ.');
    WriteLn(' /PATH:OFF  Il ne faut pas rechercher dans la liste des rÇpertoires');
    WriteLn('            ajoutÇs lors de la recherche de fichiers de donnÇes.');
    WriteLn(' /PATH:ON   Il faut rechercher dans la liste des rÇpertoires ajoutÇs');
    WriteLn('            lors de la recherche de fichiers de donnÇes.');
    WriteLn(' /X:OFF     Il ne faut pas rechercher dans la liste des rÇpertoires');
    WriteLn('            ajoutÇs lors de l''exÇcution d''un programme.');
    WriteLn(' /X:ON      Il faut rechercher dans la liste des rÇpertoires ajoutÇs');
    WriteLn('            lors de l''exÇcution d''un programme.');
   End;
  End;
 End
  Else
 If ParamCount>0 Then Begin
  For I:=1 to ParamCount do Begin
   If StrToUpper(ParamStr(I))='/E'Then Begin
    Regs.AX:=$B700;
    Intr($2F,Regs);
    Regs.AX:=$B707;
    Regs.BX:=Regs.BX or (1 shl 14);
    Intr($2F,Regs);
   End
    Else
   If StrToUpper(ParamStr(I))='/PATH:OFF'Then Begin
    Regs.AX:=$B700;
    Intr($2F,Regs);
    Regs.AX:=$B707;
    Regs.BX:=Regs.BX and Not(1 shl 13);
    Intr($2F,Regs);
   End
    Else
   If StrToUpper(ParamStr(I))='/PATH:ON'Then Begin
    Regs.AX:=$B700;
    Intr($2F,Regs);
    Regs.AX:=$B707;
    Regs.BX:=Regs.BX or (1 shl 13);
    Intr($2F,Regs);
   End
    Else
   If StrToUpper(ParamStr(I))='/X:OFF'Then Begin
    Regs.AX:=$B700;
    Intr($2F,Regs);
    Regs.AX:=$B707;
    Regs.BX:=Regs.BX and Not(1 shl 15);
    Intr($2F,Regs);
   End
    Else
   If StrToUpper(ParamStr(I))='/X:ON'Then Begin
    Regs.AX:=$B700;
    Intr($2F,Regs);
    Regs.AX:=$B707;
    Regs.BX:=Regs.BX or (1 shl 15);
    Intr($2F,Regs);
   End
    Else
   Begin
    WriteLn('Le paramätre ',ParamStr(I),' n''est pas reconnu.');
    Halt;
   End;
  End;
 End
  Else
 Begin
  Regs.AX:=$B704;
  Intr($2F,Regs);
  If(Regs.ES=0)and(Regs.DI=0)Then Begin
   WriteLn('Aucun chemin de recherche pour APPEND');
  End
   Else
  Begin
   {$IFNDEF FPC}
    I:=0;
    Repeat
     C:=Char(Mem[Regs.ES:Regs.DI+I]);
     Write(C);
     Inc(I);
    Until C=#0;
   {$ENDIF}
   WriteLn;
  End;
 End;
END.
