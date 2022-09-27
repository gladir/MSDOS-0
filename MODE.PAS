{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal, Free Pascal )
}

Program Mode;

Uses DOS{$IFDEF Windows},Windows{$ENDIF};

Const
  { Registre par defaut pour les modes d'affichages texte de la Graphics Solution }
 RegMonoGS:Array[0..11]of Byte=($61,$50,$52,$0F,$19,$06,$19,$19,$02,$0D,$0B,$0C);
 RegColGS:Array[0..11]of Byte=($71,$50,$5A,$0A,$1F,$06,$19,$1C,$02,$07,$06,$07);

Var
 _Rate,_Delay,I:Integer;      { Compteur de boucle }
 {$IFDEF Windows}
  SmallRate,SmallDelay:SmallInt;
 {$ENDIF}
 SetRate,SetDelay:Boolean;
 Err:Word;
 Regs:Registers;

Function StrToUpper(S:String):String;
Var
 I:Byte; { Compteur de boucle attribue a la chaine de caracteres }
Begin
 For I:=1to Length(S)do S[I]:=UpCase(S[I]);
 StrToUpper:=S;
End;

Procedure DisableInterrupt;
{$IFDEF FPC}
 Begin
 End;
{$ELSE}
 Assembler;ASM
  CLI
 END;
{$ENDIF}

Procedure EnableInterrupt;
{$IFDEF FPC}
 Begin
 End;
{$ELSE}
 Assembler;ASM
  STI
 END;
{$ENDIF}

BEGIN
 If(ParamCount=0)or(ParamStr(1)='/?')or(ParamStr(1)='-?')Then Begin
  WriteLn('MODE - Cette commande permet d''effectuer la gestion des parametres d''un peripherique');
  WriteLn;
  WriteLn('MODE [/?]');
  WriteLn('MODE [MONO|BW40|CO40|BW80|CO80] [/GS]');
  WriteLn('MODE CON[:] RATE=taux DELAY=delai');
  WriteLn;
  WriteLn(' MONO         Mode texte monochrome 80x25');
  WriteLn(' BW40         Mode texte noir et blanc 40x25');
  WriteLn(' CO40         Mode texte couleur 40x25');
  WriteLn(' BW80         Mode texte noir et blanc 80x25');
  WriteLn(' CO80         Mode texte couleur 80x25');
  WriteLn(' RATE=taux    Taux de repetition du clavier (1 a 32)');
  WriteLn(' DELAY=delai  Delai entre les repetitions (1 a 4)');
  WriteLn(' /GS          Force a s''appliquer en fonction d''une Graphics Solution d''ATI');
  Halt;
 End
  Else
 If StrToUpper(ParamStr(1))='MONO'Then Begin
  If ParamStr(2)='/GS'Then Begin
   {$IFDEF FPC}
    WriteLn('Port materiel : Non supporte par le compilateur FREE PASCAL');
   {$ELSE}
    DisableInterrupt;
     { Permettre une Graphics Solution en mono...}
    Port[$3DF]:=$47; Port[$3B8]:=$08;
    For I:=0to 11do Begin
     Port[$3B4]:=I;
     Port[$3B5]:=RegMonoGS[I];
    End;
    Port[$3B8]:=$08;
     { Mise-a-jour des informations du BIOS en fonction de l'affichage actuel }
    Mem [$0040:$49]:=7;
    MemW[$0040:$4C]:=4096;
    MemW[$0040:$4E]:=0;
    Mem [$0040:$62]:=0;
    MemW[$0040:$63]:=$3B4;
    MemW[$0040:$4A]:=80;
    Mem [$0040:$84]:=24;
    MemW[$0040:$85]:=14;
    Mem [$0040:$60]:=12;
    Mem [$0040:$61]:=11;
    EnableInterrupt;
   {$ENDIF}
  End;
  {$IFDEF FPC}
   WriteLn('Memoire materiel : Non supporte par le compilateur FREE PASCAL');
  {$ELSE}
   Mem[$0:$0410]:=(Mem[$0:$0410] and $CF)or $30; { Mode 80x25 monochrome }
  {$ENDIF}
  Regs.AX:=7;
  Intr($10,Regs);
  WriteLn('Mode texte monochrome 80x25 standard.');
  Halt;
 End
  Else
 If(StrToUpper(ParamStr(1))='CO80')or(StrToUpper(ParamStr(1))='CO40')or
   (StrToUpper(ParamStr(1))='BW80')or(StrToUpper(ParamStr(1))='BW40')Then
 Begin
  If StrToUpper(ParamStr(2))='/GS'Then Begin
   {$IFDEF FPC}
    WriteLn('Port materiel : Non supporte par le compilateur FREE PASCAL');
   {$ELSE}
    DisableInterrupt;
    Port[$3BA]:=$80; Port[$3DF]:=$80;
    Port[$3D8]:=$02; Port[$3DD]:=$00; Port[$3D8]:=$25;
    For I:=0to 11do Begin
     Port[$3D4]:=I;
     Port[$3D5]:=RegColGS[I];
    End;
    Port[$3D8]:=$2D;
    Port[$3D9]:=$30;
    Port[$3DD]:=$00;
     { Mise-a-jour des informations du BIOS en fonction de l'affichage actuel }
    Mem [$0040:$49]:=3;
    MemW[$0040:$4C]:=4096;
    MemW[$0040:$4E]:=0;
    Mem [$0040:$62]:=0;
    MemW[$0040:$63]:=$3D4;
    MemW[$0040:$4A]:=80;
    Mem [$0040:$84]:=24;
    MemW[$0040:$85]:=8;
    Mem [$0040:$60]:=7;
    Mem [$0040:$61]:=6;
    Mem [$0040:$10]:=(Mem[$0040:$10]and Not(16+32))or(32);
    EnableInterrupt;
   {$ENDIF}
  End;
  {$IFDEF FPC}
   WriteLn('Memoire materiel : Non supporte par le compilateur FREE PASCAL');
  {$ELSE}
   Mem[$0:$0410]:=(Mem[$0:$0410] and $CF)or $20; { Mode 80x25 en 16 couleurs}
  {$ENDIF}
  If ParamStr(1)='CO80'Then Begin
   Regs.AX:=3;
   Intr($10,Regs);
   WriteLn('Mode texte couleur 80x25.');
  End
   Else
  If StrToUpper(ParamStr(1))='CO40'Then Begin
   Regs.AX:=1;
   Intr($10,Regs);
   WriteLn('Mode texte couleur 40x25.');
  End
   Else
  If StrToUpper(ParamStr(1))='BW80'Then
  Begin
   Regs.AX:=2;
   Intr($10,Regs);
   WriteLn('Mode texte noir et blanc 80x25.');
  End
   Else
  Begin
   Regs.AX:=0;
   Intr($10,Regs);
   WriteLn('Mode texte noir et blanc 40x25.');
  End;
  Halt;
 End
  Else
 If(StrToUpper(ParamStr(1))='CON:')or(StrToUpper(ParamStr(1))='CON')Then Begin
  _Rate:=-1;
  _Delay:=-1;
  SetRate:=False;
  SetDelay:=False;
  For I:=2 to ParamCount do Begin
   If(Copy(StrToUpper(ParamStr(I)),1,5)='RATE=')Then Begin
    Val(Copy(ParamStr(I),6,255),_Rate,Err);
    SetRate:=True;
   End
    Else
   If(Copy(StrToUpper(ParamStr(I)),1,6)='DELAY=')Then Begin
    Val(Copy(ParamStr(I),7,255),_Delay,Err);
    SetDelay:=True;
   End
    Else
   Begin
    WriteLn('Parametre de console invalide');
    Halt;
   End;
  End;
  If(SetRate)or(SetDelay)Then Begin
   If Not(SetRate)Then Begin
    WriteLn('Le taux doit ˆtre definit');
    Halt;
   End;
   If Not(SetDelay)Then Begin
    WriteLn('Le delai doit ˆtre definit');
    Halt;
   End;
   If(_Delay<1)or(_Delay>4)Then Begin
    WriteLn('Delai invalide (1 a 4)');
    Halt;
   End;
   If(_Rate<1)or(_Rate>32)Then Begin
    WriteLn('Taux invalide (1 a 32)');
    Halt;
   End;
   {$IFDEF Windows}
    SmallRate:=_Rate;
    If Not SystemParametersInfo(SPI_GETKEYBOARDSPEED,0,@SmallRate,SPIF_SENDCHANGE)Then Begin
     WriteLn('Erreur pendant la fixation du taux de repetition');
    End;
    SmallDelay:=_Delay-1;
    If Not SystemParametersInfo(SPI_GETKEYBOARDDELAY,0,@SmallDelay,SPIF_SENDCHANGE)Then Begin
     WriteLn('Erreur pendant la fixation du delai de repetition');
    End;
   {$ELSE}
    Regs.AX:=$0305;
    Regs.BL:=32-_Rate;
    Regs.BH:=_Delay-1;
    Intr($16,Regs);
   {$ENDIF}
  End;
 End
  Else
 WriteLn('Erreur de parametre.');
END.