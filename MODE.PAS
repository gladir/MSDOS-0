{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal )
}

Program Mode;

Const
  { Registre par defaut pour les modes d'affichages texte de la Graphics Solution }
 RegMonoGS:Array[0..11]of Byte=($61,$50,$52,$0F,$19,$06,$19,$19,$02,$0D,$0B,$0C);
 RegColGS:Array[0..11]of Byte=($71,$50,$5A,$0A,$1F,$06,$19,$1C,$02,$07,$06,$07);

Var
 ParamStr1:String; { Chaine de caracteres reserve pour les parametres }
 I:Byte;           { Compteur de boucle }
 PS:^String;       { Pointeur de chaine de caracteres }

Function StrUp(S:String):String;
Var
 I:Byte; { Compteur de boucle attribue a la chaine de caracteres }
Begin
 For I:=1to Length(S)do S[I]:=UpCase(S[I]);
 StrUp:=S;
End;

BEGIN
 PS:=System.Ptr(PrefixSeg,$80);
 PS^:=StrUp(PS^);
 ParamStr1:=ParamStr(1);
 If ParamStr1<>''Then Begin
  If(ParamStr1[1]='-')or(ParamStr1[1]='/')Then ParamStr1:=Copy(ParamStr1,2,255);
 End;
 If(ParamCount=0)or(ParamStr1='?')Then Begin
  WriteLn('MODE - Cette commande permet d''effectuer la gestion des parametres d''un peripherique');
  WriteLn;
  WriteLn('MODE [/?]');
  WriteLn('MODE [MONO|BW40|CO40|BW80|CO80][/GS]');
  WriteLn;
  WriteLn(' MONO  Mode texte monochrome 80x25');
  WriteLn(' BW40  Mode texte noir et blanc 40x25');
  WriteLn(' CO40  Mode texte couleur 40x25');
  WriteLn(' BW80  Mode texte noir et blanc 80x25');
  WriteLn(' CO80  Mode texte couleur 80x25');
  WriteLn(' /GS   Force a s''appliquer en fonction d''une Graphics Solution d''ATI');
  Halt;
 End;
 If ParamStr1='MONO'Then Begin
  If ParamStr(2)='/GS'Then Begin
   ASM
    CLI { Interdit les interruptions car ceux-ci pourrait
        { completement alterer l'affichage sinon... }
   ENd;
    { Permettre une Graphics Solution en mono...}
   Port[$3DF]:=$47; Port[$3B8]:=$08;
   For I:=0to 11do Begin
    Port[$3B4]:=I;
    Port[$3B5]:=RegMonoGS[I];
   End;
   Port[$3B8]:=$08;
    { Mise-a-jour des informations du BIOS en fonction de l'affichage actuel }
   Mem[$0040:$49]:=7;
   MemW[$0040:$4C]:=4096; MemW[$0040:$4E]:=0; Mem[$0040:$62]:=0;
   MemW[$0040:$63]:=$3B4; MemW[$0040:$4A]:=80; Mem[$0040:$84]:=24;
   MemW[$0040:$85]:=14; Mem[$0040:$60]:=12; Mem[$0040:$61]:=11;
   ASM
    STI { Autorise les interruptions temporairement interdit }
   END;
  End;
  ASM
   XOR AX,AX
   MOV ES,AX
   AND Byte Ptr ES:[0410h],0CFh
   OR  Byte Ptr ES:[0410h],030h
   MOV AX,7
   INT 10h
  END;
  WriteLn('Mode texte monochrome 80x25 standard.');
  Halt;
 End;
 If(ParamStr1='CO80')or(ParamStr1='CO40')or
   (ParamStr1='BW80')or(ParamStr1='BW40')Then
 Begin
  If ParamStr(2)='/GS'Then Begin
   ASM
    CLI
   END;
   Port[$3BA]:=$80; Port[$3DF]:=$80;
   Port[$3D8]:=$02; Port[$3DD]:=$00; Port[$3D8]:=$25;
   For I:=0to 11do
   Begin
    Port[$3D4]:=I;
    Port[$3D5]:=RegColGS[I];
   End;
   Port[$3D8]:=$2D; Port[$3D9]:=$30; Port[$3DD]:=$00;
    { Mise-a-jour des informations du BIOS en fonction de l'affichage actuel }
   Mem[$0040:$49]:=3;
   MemW[$0040:$4C]:=4096; MemW[$0040:$4E]:=0; Mem[$0040:$62]:=0;
   MemW[$0040:$63]:=$3D4; MemW[$0040:$4A]:=80; Mem[$0040:$84]:=24;
   MemW[$0040:$85]:=8; Mem[$0040:$60]:=7; Mem[$0040:$61]:=6;
   Mem[$0040:$10]:=(Mem[$0040:$10]and Not(16+32))or(32);
   ASM
    STI
   END;
  End;
  ASM
   XOR AX,AX
   MOV ES,AX
   AND Byte Ptr ES:[0410h],0CFh
   OR  Byte Ptr ES:[0410h],020h
  END;
  If ParamStr1='CO80'Then Begin
   ASM
    MOV AX,3
    INT 010h
   END;
   WriteLn('Mode texte couleur 80x25.');
  End
   Else
  If ParamStr1='CO40'Then Begin
   ASM
    MOV AX,1
    INT 010h
   END;
   WriteLn('Mode texte couleur 40x25.');
  End
   Else
  If ParamStr1='BW80'Then
  Begin
   ASM
    MOV AX,2
    INT 010h
   END;
   WriteLn('Mode texte noir et blanc 80x25.');
  End
   Else
  Begin
   ASM
    XOR AX,AX
    INT 010h
   END;
   WriteLn('Mode texte noir et blanc 40x25.');
  End;
  Halt;
 End;
 WriteLn('Erreur de parametre.');
END.