{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program MSD;

Uses Crt,DOS,Strings;

Const

 MainMenu:Array[0..2]of String[15]=(
  'Fichier','Utilitaires','Aide'
 );

 MainMenuEnglish:Array[0..2]of String[15]=(
  'File','Utilities','Help'
 );

 SubMenuFile:Array[0..12]of String[20]=(
  'Recherche le fichier...','Imprime le rapport...','',
  '1 AUTOEXEC.BAT',
  '2 CONFIG.SYS',
  '3 SYSTEM.INI',
  '4 WIN.INI',
  '5 MSMAIL.INI',
  '6 PROTOCOL.INI',
  '7 DRVSPACE.INI',
  '8 MEMMAKER.STS',
  '',
  'Sortir'
 );

 SubMenuFileEnglish:Array[0..12]of String[20]=(
  'Find File...','Print Report...','',
  '1 AUTOEXEC.BAT',
  '2 CONFIG.SYS',
  '3 SYSTEM.INI',
  '4 WIN.INI',
  '5 MSMAIL.INI',
  '6 PROTOCOL.INI',
  '7 DRVSPACE.INI',
  '8 MEMMAKER.STS',
  '',
  'Exit'
 );

 SubMenuUtilities:Array[0..5]of String[20]=(
  'Affiche les blocs de m‚moire ...',
  'Naviguer dans la m‚moire ...',
  'InsŠre une commande ...',
  'Test l''imprimante ...',
  '',
  'Noir et blanc'
 );

 SubMenuUtilitiesEnglish:Array[0..5]of String[20]=(
  'Memory Block Display ...',
  'Memory Browser ...',
  'Insert Command ...',
  'Test Printer ...',
  '',
  'Black & White'
 );

 SubMenuHelp:Array[0..0]of String[20]=(
  'A propos ...'
 );

 SubMenuHelpEnglish:Array[0..0]of String[20]=(
  'About ...'
 );

 YMenuMax:Array[1..3]of Byte=(
  High(SubMenuFile),High(SubMenuUtilities),High(SubMenuHelp)
 );

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 I:Integer;
 ShowASCII128,OnMenu:Boolean;
 YMenu,XMenu:Integer;

{$IFNDEF FPC}
 Procedure CursorOff;
 Var
  Regs:Registers;
 Begin
  Regs.AH:=1;
  Regs.CH:=32;
  Regs.CL:=0;
  Intr($10,Regs);
 End;

 Procedure CursorOn;
 Var
  Regs:Registers;
 Begin
  Regs.AX:=$0100;
  Regs.CX:=(7 shl 8)+9;
  Intr($10,Regs);
 End;
{$ENDIF}

Function MouseDriverFound:Boolean;
Var
 Int33h:Pointer;
 Regs:Registers;
Begin
 MouseDriverFound:=False;
 GetIntVec($33,Int33h);
 If Int33h=NIL Then Exit;
 Regs.AX:=0;
 Intr($33,Regs);
 MouseDriverFound:=Regs.AX=$FFFF;
End;

Function MicrosoftMouseFound:Boolean;
Var
 Regs:Registers;
Begin
 MicrosoftMouseFound:=False;
 Regs.AX:=$006D;
 Regs.ES:=0;
 Regs.DI:=0;
 Intr($33,Regs);
 If(Regs.ES=0)and(Regs.DI=0)Then Exit;
 MicrosoftMouseFound:=True;
End;

Function GeniusMouseFound:Boolean;
Var
 Regs:Registers;
Begin
 GeniusMouseFound:=False;
 Regs.AX:=$004D;
 Regs.ES:=0;
 Regs.DI:=0;
 Intr($33,Regs);
 If(Regs.ES=0)and(Regs.DI=0)Then Exit;
 {$IFDEF FPC}
  GeniusMouseFound:=True;
 {$ELSE}
  If(Chr(Mem[Regs.ES:Regs.DI])='K')and
    (Chr(Mem[Regs.ES:Regs.DI+1])='Y')and
    (Chr(Mem[Regs.ES:Regs.DI]+2)='E')Then GeniusMouseFound:=True;
 {$ENDIF}
End;

Function ZNIXMouseFound:Boolean;
Var
 Regs:Registers;
Begin
 ZNIXMouseFound:=False;
 Regs.AX:=$004B;
 Regs.ES:=0;
 Regs.DI:=0;
 Intr($33,Regs);
 If(Regs.ES=0)and(Regs.DI=0)Then Exit;
 {$IFDEF FPC}
  ZNIXMouseFound:=True;
 {$ELSE}
  If(Chr(Mem[Regs.ES:Regs.DI])='Z')and
    (Chr(Mem[Regs.ES:Regs.DI+1])='-')and
    (Chr(Mem[Regs.ES:Regs.DI+2])='N')and
    (Chr(Mem[Regs.ES:Regs.DI+3])='I')and
    (Chr(Mem[Regs.ES:Regs.DI]+4)='X')Then ZNIXMouseFound:=True;
 {$ENDIF}
End;

Function GetCurrentDisk:Char;
Var
 CurrentDir:String;
Begin
 GetDir(0,CurrentDir);
 GetCurrentDisk:=CurrentDir[1];
End;

Function GetBootDrive:Char;
Var
 Regs:Registers;
Begin
 Regs.AX:=$3305;
 MsDos(Regs);
 If Regs.AL=0 Then GetBootDrive:=GetCurrentDisk
              Else GetBootDrive:=Chr(Regs.AL+64);
End;

Function GetModelROM:Byte;Begin
 {$IFDEF FPC}
  GetModelROM:=0;
 {$ELSE}
  GetModelROM:=Mem[$FFFF:$E];
 {$ENDIF}
End;

Function GetEquip:Word;
Var
 Regs:Registers;
Begin
 Regs.AX:=0;
 Intr($11,Regs);
 GetEquip:=Regs.AX;
End;

Function JoystickPresent:Boolean;Begin
 JoystickPresent:=(GetEquip shr 12)and 1=1;
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

Function DuplicateString(C:Char;Num:Integer):String;
Var
 I:Byte;
 S:String;
Begin
 S:='';
 For I:=1 to Num do S:=S+C;
 DuplicateString:=S;
End;

Function PadCenter(S:String;Width:Integer):String;
Var
 Left2,Right2:Integer;
 TmpS:String;
Begin
 If Length(S)>=Width Then Begin
  PadCenter:=S;
  Exit;
 End;
 Left2:=(Width-Length(S))shr 1;
 Right2:=Left2+((Width-Length(S))and 1);
 TmpS:='';
 If Left2>0 Then TmpS:=DuplicateString(' ',Left2);
 TmpS:=TmpS+S;
 If Right2>0 Then TmpS:=TmpS+DuplicateString(' ',Right2);
 PadCenter:=TmpS;
End;

Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
End;

Function ByteHex2Str(value:Byte):String;
Const
 matrix:Array[0..15]of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
 ByteHex2Str:=matrix[(value shr 4) and $0F]+matrix[value and $F];
End;

Procedure Box(X1,Y1,X2,Y2,Couleur:Byte);Begin
 Window(X1,Y1,X2,Y2);
 TextBackground((Couleur shr 4)and 15);
 {$IFDEF FPC}
  If Couleur and $80=$80 Then Begin
   TextColor((Couleur and 15)+BLINK);
  End
   Else
  TextColor(Couleur and 15);
 {$ELSE}
  TextColor(Couleur and 15);
 {$ENDIF}
 ClrScr;
 Window(1,1,80,25);
End;

Procedure FrameEmpty(X1,Y1,X2,Y2,Couleur:Byte);
Var
 I:Byte;
 ChrHori,ChrVert:Char;
 Chr218,Chr192,Chr191,Chr217:Char;
Begin
 TextBackground((Couleur shr 4)and 15);
 {$IFDEF FPC}
  If Couleur and $80=$80 Then Begin
   TextColor((Couleur and 15)+BLINK);
  End
   Else
  TextColor(Couleur and 15);
 {$ELSE}
  TextColor(Couleur and 15);
 {$ENDIF}
 If(ShowASCII128)Then Begin
  ChrHori:='-';
  ChrVert:='|';
  Chr218:='+';
  Chr192:='+';
  Chr191:='+';
  Chr217:='+';
 End
  Else
 Begin
  ChrHori:=#$C4;
  ChrVert:=#$B3;
  Chr218:=#218;
  Chr192:=#192;
  Chr191:=#191;
  Chr217:=#217;
 End;
 For I:=Y1+1 to Y2-1 do Begin
  GotoXY(X1,I);
  Write(ChrVert);
  GotoXY(X2,I);
  Write(ChrVert);
 End;
 GotoXY(X1+1,Y1);
 Write(DuplicateString(ChrHori,X2-X1-1));
 GotoXY(X1+1,Y2);
 Write(DuplicateString(ChrHori,X2-X1-1));
 GotoXY(X1,Y1);
 Write(Chr218);
 GotoXY(X1,Y2);
 Write(Chr192);
 GotoXY(X2,Y1);
 Write(Chr191);
 GotoxY(X2,Y2);
 Write(Chr217);
End;

Procedure WritePadCenterHighlight(S:String;Width:Integer);
Var
 Left2,Right2,HighLight,BitHighLight,I:Integer;
Begin
 HighLight:=Pos('^',S);
 BitHighLight:=Byte(Highlight>0);
 Left2:=(Width-(Length(S)-BitHighLight))shr 1;
 Right2:=Left2+((Width-(Length(S)-BitHighLight))and 1);
 If Left2>0 Then Write(DuplicateString(' ',Left2));
 If HighLight>0 Then Begin
  I:=1;
  While I<=Length(S)do Begin
   If S[I]='^'Then Begin
    TextColor(Red);
    Write(S[I+1]);
    Inc(I,2);
   End
    Else
   Begin
    TextColor(Black);
    Write(S[I]);
    Inc(I);
   End;
  End;
 End
  Else
 Write(S);
 If Right2>0 Then Write(DuplicateString(' ',Right2));
End;

Procedure ShowHome;
Const
 Buttons:Array[0..13]of String[20]=(
  'Ord^inateur...','^Memoire...','^Vid‚o...','R‚s^eau...',
  'Version ^OS...','So^uris...','^Autre adaptat...',
  'Unit‚ de ^disque...','Ports ^LPT...','Ports ^COM...','^Windows...',
  'tats IR^Q','Programmes ^TSR...','Pilote pe^riph...'
 );
 ButtonsEnglish:Array[0..13]of String[20]=(
  'Com^puter...','^Memory...','^Video...','^Network...',
  '^OS Version...','Mo^use...','Other ^Adapters',
  '^Disk Drives...','^LPT Ports...','^COM Ports...','^Windows...',
  'IR^Q Status','^TSR Programs...','Device D^rivers...'
 );
Var
 I,J:Byte;
Begin
 TextColor(White{$IFDEF FPC}+BLINK{$ENDIF});
 TextBackground(Blue);
 ClrScr;
 For I:=0 to 1 do For J:=0 to 6 do Begin
  GotoXY(2+I*40,3+J*3);
  TextBackground(Blue);
  TextColor(7{$IFDEF FPC}+BLINK{$ENDIF});
  Write(DuplicateString(#220,20));
  TextColor(Black);
  TextBackground(7);
  GotoXY(2+I*40,4+J*3);
  Case Language of
   _English:WritePadCenterHighlight(ButtonsEnglish[I*7+J],20);
   Else WritePadCenterHighlight(Buttons[I*7+J],20);
  End;
  TextBackground(7);
  TextColor(8);
  Write(#219);
  GotoXY(2+I*40,5+J*3);
  TextBackground(Blue);
  TextColor(7{$IFDEF FPC}+BLINK{$ENDIF});
  Write(#223);
  TextBackground(7);
  TextColor(8);
  Write(DuplicateString(#220,19),#219);
 End;
End;

Procedure ShowStatusBar;Begin
 TextColor(Black);
 TextBackground(7);
 GotoXY(1,25);
 Case Language of
  _English:Write('Press ALT for menu, or press highlighted letter, or F3 to quit MSD.');
  Else Write('Presse ALT pour le menu, ou presse la lettre en rouge, ou F3 pour quitter MSD.');
 End;
 ClrEol;
End;

Procedure SetColorSelect;Begin
 TextColor(15);
 TextBackground(0);
End;

Procedure SetColorUnSelect;Begin
 TextColor(0{$IFDEF FPC}+BLINK{$ENDIF});
 TextBackground(15);
End;

Procedure ShowMenu;
Var
 I:Byte;
Begin
 Box(1,1,80,1,$F0);
 GotoXY(4,1);
 For I:=0 to High(MainMenu) do Begin
  If(OnMenu)Then Begin
   If I+1=XMenu Then SetColorSelect
                Else SetColorUnSelect;
  End;
  Case Language of
   _English:Write(' ',MainMenuEnglish[I],' ');
   Else Write(' ',MainMenu[I],' ');
  End;
 End;
End;

Procedure SubMenuItem(Y:Integer;Disable:Boolean);Begin
 If(Disable)Then SetColorUnSelect Else
 If Y=YMenu Then SetColorSelect
            Else SetColorUnSelect;
 Case XMenu of
  1:Begin
   GotoXY(5,3+Y);
   If SubMenuFile[Y]=''Then Write(DuplicateString('-',25+1))
    Else
   Case Language of
    _English:Write(' ',PadRight(SubMenuFileEnglish[Y],25));
    Else Write(' ',PadRight(SubMenuFile[Y],25));
   End;
  End;
  2:Begin
   Case Language of
    _English:GotoXY(11,3+Y);
    Else GotoXY(14,3+Y);
   End;
   If SubMenuUtilities[Y]=''Then Write(DuplicateString('-',25+1))
    Else
   Case Language of
    _English:Write(' ',PadRight(SubMenuUtilitiesEnglish[Y],25));
    Else Write(' ',PadRight(SubMenuUtilities[Y],25));
   End;
  End;
  3:Begin
   Case Language of
    _English:GotoXY(22,3+Y);
    Else GotoXY(27,3+Y);
   End;
   If SubMenuHelp[Y]=''Then Write(DuplicateString('-',25+1))
    Else
   Case Language of
    _English:Write(' ',PadRight(SubMenuHelpEnglish[Y],25));
    Else Write(' ',PadRight(SubMenuHelp[Y],25));
   End;
  End;
 End;
End;

Procedure ShowSubMenu;
Var
 I:Integer;
Begin
 Case XMenu of
  1:Begin
   FrameEmpty(4,2,31,4+High(SubMenuFile),$F0);
   For I:=Low(SubMenuFile)to High(SubMenuFile)do Begin
    SubMenuItem(I,False);
   End;
  End;
  2:Begin
   Case Language of
    _English:FrameEmpty(10,2,37,4+High(SubMenuUtilities),$F0);
    Else FrameEmpty(13,2,40,4+High(SubMenuUtilities),$F0);
   End;
   For I:=Low(SubMenuUtilities)to High(SubMenuUtilities)do Begin
    SubMenuItem(I,False);
   End;
  End;
  3:Begin
   Case Language of
    _English:FrameEmpty(21,2,48,4+High(SubMenuHelp),$F0);
    Else FrameEmpty(26,2,53,4+High(SubMenuHelp),$F0);
   End;
   For I:=Low(SubMenuHelp)to High(SubMenuHelp)do Begin
    SubMenuItem(I,False);
   End;
  End;
 End;
End;

Procedure HideSubMenu;Begin
 ShowHome;
 ShowStatusBar;
 ShowMenu;
End;

Procedure NotImplemented;Begin
 Box(5,11,75,13,$60);
 FrameEmpty(5,11,75,13,$60);
 GotoXY(20,12);
 Write('Cette fonctionnalite n''est pas implemented');
 ReadKey;
 HideSubMenu;
End;

Procedure ShowComputer;
Var
 Regs:Registers;
Begin
 Box(20,4,60,22,$F0);
 FrameEmpty(20,4,60,22,$F0);
 Window(21,5,59,21);
 GotoXY(1,1);
 WriteLn('Computer Name:':19,' ','Unknown');
 Regs.AH:=$C0;
 Intr($10,Regs);
 WriteLn('BIOS Manufacturer:':19,' ','Unknown');
 WriteLn('BIOS Version:':19,' ','Unknown');
 Write('BIOS Category:':19,' ');
 Case GetModelROM of
  $55: WriteLn('Conterm Max');
  $FB: WriteLn('IBM PC XT avec carte 256/640');
  $FC: WriteLn('IBM PC AT');
  $FD: WriteLn('IBM PC Junior');
  $FE: WriteLn('IBM PC XT');
  Else WriteLn('Unknown');
 End;
 {$IFDEF FPC}
  WriteLn('BIOS ID Bytes:':19,' ','Unknown');
 {$ELSE}
  WriteLn('BIOS ID Bytes:':19,' ',ByteHex2Str(Mem[Regs.ES:Regs.BX+2]),' ',
          ByteHex2Str(Mem[Regs.ES:Regs.BX+3]),' ',
          ByteHex2Str(Mem[Regs.ES:Regs.BX+4]));
 {$ENDIF}
 WriteLn('BIOS Date:':19,' ','Unknown');
 Write('Processor:':19,' ');
 Case Test8086 of
  0:WriteLn('8086');
  1:WriteLn('80286');
  2:WriteLn('80386 ou sup‚rieur');
  Else WriteLn('Unknown');
 End;
 Write('Math Coprocessor:':19,' ');
 Case Test8087 of
  0:WriteLn('Absent');
  1:WriteLn('8087');
  2:WriteLn('80287');
  3:WriteLn('80387');
  Else WriteLn('Unknown');
 End;
 WriteLn('Keyboard:':19,' ','Unknown');
 WriteLn('Bus Type:':19,' ','Unknown');
 WriteLn('DMA Controller:':19,' ','Unknown');
 WriteLn('Cascaded IRQ2:':19,' ','Unknown');
 WriteLn('BIOS Data Segment:':19,' ','Unknown');
 WriteLn(DuplicateString(#196,39));
 Write(' ':16);
 TextColor(Black);
 TextBackground(7);
 Write('   OK   ');
 Window(1,1,80,25);
 ReadKey;
End;

Procedure ShowMemory;Begin
 NotImplemented;
End;

Procedure ShowVideo;
Var
 OldWindMax:Word;
Begin
 OldWindMax:=WindMax;
 Box(5,3,75,22,$F0);
 FrameEmpty(5,3,75,22,$F0);
 Window(6,4,74,21);
 GotoXY(1,1);
 WriteLn('Video Adapter Type:':24,' ','Unknown');
 WriteLn('Manufacturer:':24,' ','Unknown');
 WriteLn('Model:':24,' ','Unknown');
 WriteLn('Display Type:':24,' ','Unknown');
 WriteLn('Video Mode:':24,' ',LastMode);
 WriteLn('Number of Columns:':24,' ',Lo(OldWindMax)+1);
 WriteLn('Number of Rows:':24,' ',Hi(OldWindMax)+1);
 WriteLn('Video BIOS Adapter:':24,' ','Unknown');
 WriteLn;
 WriteLn;
 WriteLn('Video BIOS Date:':24,' ','Unknown');
 WriteLn('VESA Support Installed:':24,' ','Unknown');
 WriteLn('VESA Version:':24,' ','Unknown');
 WriteLn('VESA OEM Name:':24,' ','Unknown');
 WriteLn('Secondary Adapter:':24,' ','Unknown');
 WriteLn(DuplicateString(#196,69));
 Write(' ':30);
 TextColor(Black);
 TextBackground(7);
 Write('   OK   ');
 Window(1,1,80,25);
 ReadKey;
End;

Procedure ShowNetwork;Begin
 NotImplemented;
End;

Procedure ShowOSVersion;Begin
 Box(20,3,60,22,$F0);
 FrameEmpty(20,3,60,22,$F0);
 Window(21,4,59,21);
 GotoXY(1,1);
 WriteLn('Operating System:':19,' ','DOS ',Lo(DosVersion),'.',Hi(DosVersion));
 WriteLn('Internal Revision:':19,' ','Unknown');
 WriteLn('OEM Serial Number:':19,' ','Unknown');
 WriteLn('User Serial Number:':19,' ','Unknown');
 WriteLn('OEM Version String:':19,' ','Unknown');
 WriteLn('DOS Located in:':19,' ','Unknown');
 WriteLn('Boot Drive:':19,' ',GetBootDrive,':');
 WriteLn('Path to Program:':19,' ','Unknown');
 WriteLn;
 WriteLn('  Environment Strings');
 WriteLn(DuplicateString('-',20));
 WriteLn('COMSPEC=',Copy(GetEnv('COMSPEC'),1,30));
 WriteLn('PROMPT=',Copy(GetEnv('PROMPT'),1,30));
 WriteLn('PATH=',Copy(GetEnv('PATH'),1,33));
 WriteLn('TEMP=',Copy(GetEnv('TEMP'),1,33));
 Write(DuplicateString(#196,39));
 Write(' ':16);
 TextColor(Black);
 TextBackground(7);
 Write('   OK   ');
 Window(1,1,80,25);
 ReadKey;
End;

Procedure ShowMouse;Begin
 Box(20,10,60,16,$F0);
 FrameEmpty(20,10,60,16,$F0);
 Window(21,11,59,15);
 GotoXY(1,1);
 Write('Mouse Hardware:':19,' ');
 If Not MouseDriverFound Then WriteLn('Absent')
                         Else WriteLn('Unknown');
 Write('Driver Manufacturer:':19,' ');
 If Not MouseDriverFound Then WriteLn('Absent')Else
 If MicrosoftMouseFound Then WriteLn('Microsoft') Else
 If GeniusMouseFound Then WriteLn('Genius') Else
 If ZNIXMouseFound Then Write('Z-NIX')
                   Else WriteLn('Unknown');
 Write(DuplicateString(#196,39));
 Write(' ':16);
 TextColor(Black);
 TextBackground(7);
 Write('   OK   ');
 Window(1,1,80,25);
 ReadKey;
End;

Procedure ShowOtherAdapters;Begin
 Box(20,10,60,15,$F0);
 FrameEmpty(20,10,60,15,$F0);
 Window(21,11,59,14);
 GotoXY(1,1);
 Write('Game Adapter:':19,' ');
 If(JoystickPresent)Then WriteLn('Pr‚sent')
                    Else WriteLn('Absent');
 Write(DuplicateString(#196,39));
 Write(' ':16);
 TextColor(Black);
 TextBackground(7);
 Write('   OK   ');
 Window(1,1,80,25);
 ReadKey;
End;

Procedure ShowDiskDrives;Begin
 NotImplemented;
End;

Procedure ShowLPTPorts;Begin
 NotImplemented;
End;

Procedure ShowCOMPorts;Begin
 NotImplemented;
End;

Procedure ShowWindows;Begin
 NotImplemented;
End;

Procedure ShowIRQStatus;Begin
 NotImplemented;
End;

Procedure ShowTSRPrograms;Begin
 NotImplemented;
End;

Procedure ShowDeviceDrivers;Begin
 NotImplemented;
End;

Procedure Init;Begin
 CursorOff;
 ShowHome;
 ShowStatusBar;
 ShowMenu;
End;

Procedure Run;
Var
 Terminated:Boolean;
 K:Char;
Begin
 Terminated:=False;
 Repeat
  K:=ReadKey;
  If(OnMenu)Then Case K of
   #0:Case ReadKey of
    #61:Terminated:=True; { F3 }
    #72:Begin { Up }
     SubMenuItem(YMenu,True);
     If YMenu>0Then Dec(YMenu)
               Else YMenu:=YMenuMax[XMenu];
     Case XMenu of
      1:If YMenu in[2,11]Then Dec(YMenu);
      2:If YMenu in[4]Then Dec(YMenu);
     End;
     SubMenuItem(YMenu,False);
    End;
    #75:Begin { Gauche }
     HideSubMenu;
     If XMenu>1 Then Dec(XMenu)
                Else XMenu:=High(MainMenu)+1;
     YMenu:=0;
     ShowMenu;
     ShowSubMenu;
    End;
    #77:Begin { Droite }
     HideSubMenu;
     If XMenu<=High(MainMenu)Then Inc(XMenu)
                             Else XMenu:=1;
     YMenu:=0;
     ShowMenu;
     ShowSubMenu;
    End;
    #80:Begin { Down }
     SubMenuItem(YMenu,True);
     If YMenu<YMenuMax[XMenu]Then Inc(YMenu)
                             Else YMenu:=0;
     Case XMenu of
      1:If YMenu in[2,11]Then Inc(YMenu);
      2:If YMenu in[4]Then Inc(YMenu);
     End;
     SubMenuItem(YMenu,False);
    End;
   End;
   #13:Begin
    OnMenu:=False;
    HideSubMenu;
    Case XMenu of
     1:Case YMenu of
      12:Terminated:=True;
      Else NotImplemented;
     End;
     Else NotImplemented;
    End;
   End;
   #27:Begin
    OnMenu:=False;
    HideSubMenu;
   End;
  End
   Else
  Case K of
   #0:Case ReadKey of
    #22:Begin { Alt+U }
     XMenu:=2;YMenu:=0;
     OnMenu:=True;
     ShowMenu;
     ShowSubMenu;
    End;
    #30:Begin { Alt+A }
     XMenu:=3;YMenu:=0;
     OnMenu:=True;
     ShowMenu;
     ShowSubMenu;
    End;
    #33:Begin { Alt+F }
     XMenu:=1;YMenu:=0;
     OnMenu:=True;
     ShowMenu;
     ShowSubMenu;
    End;
    #35:Begin { Alt+H }
     XMenu:=3;YMenu:=0;
     OnMenu:=True;
     ShowMenu;
     ShowSubMenu;
    End;
    #61:Terminated:=True; { F3 }
   End;
   'a','A':Begin
    ShowOtherAdapters;
    HideSubMenu;
   End;
   'c','C':Begin
    ShowCOMPorts;
    HideSubMenu;
   End;
   'd','D':Begin
    ShowDiskDrives;
    HideSubMenu;
   End;
   'e','E','n','N':Begin
    ShowNetwork;
    HideSubMenu;
   End;
   'i','I','p','P':Begin
    ShowComputer;
    HideSubMenu;
   End;
   'l','L':Begin
    ShowLPTPorts;
    HideSubMenu;
   End;
   'm','M':Begin
    ShowMemory;
    HideSubMenu;
   End;
   'o','O':Begin
    ShowOSVersion;
    HideSubMenu;
   End;
   'q','Q':Begin
    ShowIRQStatus;
    HideSubMenu;
   End;
   'r','R':Begin
    ShowDeviceDrivers;
    HideSubMenu;
   End;
   't','T':Begin
    ShowTSRPrograms;
    HideSubMenu;
   End;
   'u','U':Begin
    ShowMouse;
    HideSubMenu;
   End;
   'v','V':Begin
    ShowVideo;
    HideSubMenu;
   End;
   'w','W':Begin
    ShowWindows;
    HideSubMenu;
   End;
  End;
 Until Terminated;
End;

Procedure Done;Begin
 TextColor(7);
 TextBackground(0);
 ClrScr;
 CursorOn;
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
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  Case Language of
   _English:Begin
    WriteLn('Provides details technical information about your computer.');
    WriteLn;
    WriteLn('MSD [/ASCII128]')
   End;
   Else Begin
    WriteLn('MSD : Cette commande permet de fournir des informations ',
            'techniques … propos de votre ordinateur');
    WriteLn;
    WriteLn('Syntaxe : MSD [/ASCII128]');
    WriteLn;
    WriteLn(' /ASCII128   Ce parametre permet de lancer en mode compatibilite 128 caracteres seulement.');
   End;
  End;
 End
  Else
 Begin
  Init;
  Run;
  Done;
 End;
END.