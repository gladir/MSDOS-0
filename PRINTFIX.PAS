{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

{ PRINTFIX - TSR pour corriger les erreurs d'impression sur port paralläle sous MS-DOS 5.x

  Ce programme est un TSR (Terminate Stay Resident) qui intercepte l'interruption BIOS 17h
  (services d'impression paralläle) pour corriger un probläme spÇcifique avec MS-DOS 5.0+.

  Probläme: Certains systämes retournent le bit 3 d'Çtat d'erreur d'entrÇe/sortie màme quand
  l'imprimante fonctionne correctement, causant des erreurs "Write fault" sous MS-DOS 5.x.

  Solution: Ce TSR remplace le gestionnaire INT 17h et masque le bit 3 d'erreur d'entrÇe/sortie
  pour Çviter ces faux positifs.
}

Program PRINTFIX;

{$IFDEF FPC}
 {$MODE TP}
 {$ASMMODE INTEL}
{$ENDIF}

Uses DOS;

{$M 8192,0,0}  { MÇmoire nÇcessaire pour TSR }

Var
 Language:(_French,_English,_Germany,_Italian,_Spain,_Albanian,_Portuguese,_Swedish,_Danish,_Japanese);
 TmpLanguage:String;
 OldInt17:Pointer;  { Pointeur vers l'ancien gestionnaire INT 17h }
 Installed:Boolean;

 { Fonctions systäme pour TSR }
{$IFNDEF FPC}
 Procedure Keep(ExitCode:Word;Size:Word);Assembler;ASM
  MOV AL,Byte Ptr ExitCode
  MOV DX,Size
  MOV AH,31h
  INT 21h
 END;
{$ENDIF}

 { Fonction utilitaire pour convertir en majuscules }
Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

 { Nouveau gestionnaire d'interruption 17h }
Procedure NewInt17Handler;Assembler;ASM
  { Sauvegarder les registres }
 PUSH AX
 PUSH BX
 PUSH CX
 PUSH DX
 PUSH SI
 PUSH DI
 PUSH DS
 PUSH ES
 PUSHF
  { VÇrifier si c'est la fonction Get Printer Status (AH=02h) }
 CMP AH, 02h
 jne @CallOldHandler
  { Pour la fonction Get Printer Status, retourner un statut fixe }
  { Bit 4 = Printer selected, Bit 7 = Printer not busy }
 MOV AH, 90h
 POPF
 POP ES
 POP DS
 POP DI
 POP SI
 POP DX
 POP CX
 POP BX
 POP AX
 IRET
@CallOldHandler:
  { Restaurer les drapeaux }
 POPF
  { Restaurer les registres }
 POP ES
 POP DS
 POP DI
 POP SI
 POP DX
 POP CX
 POP BX
 POP AX
  { Appeler l'ancien gestionnaire INT 17h }
 PUSHF
 CALL [OldInt17]
  { Masquer le bit 3 (I/O error) d'Çtat retournÇ dans AH }
 AND AH, 0F7h  { Bit 3 = 0 (pas d'erreur d'entrÇe/sortie) }
 IRET
END;

 { VÇrifier si le TSR est dÇjÖ installÇ }
Function IsAlreadyInstalled: Boolean;
Var
 IntVec: Pointer;
Begin
 GetIntVec($17, IntVec);
 IsAlreadyInstalled := (IntVec = @NewInt17Handler);
End;

{ Installer le TSR }
Procedure InstallTSR;
{$IFNDEF FPC}
 Var
  TSRSize: Word;
{$ENDIF}
Begin
 If IsAlreadyInstalled Then Begin
  Case Language Of
   _English: WriteLn('PRINTFIX is already installed.');
   _Germany: WriteLn('PRINTFIX ist bereits installiert.');
   Else WriteLn('PRINTFIX est dÇjÖ installÇ.');
  End;
  Halt(1);
 End;
  { Sauvegarder l'ancien vecteur d'interruption }
 GetIntVec($17, OldInt17);
  { Installer le nouveau gestionnaire }
 SetIntVec($17, @NewInt17Handler);
  { Afficher le message d'installation }
 Case Language Of
  _English: Begin
   WriteLn('PRINTFIX installed successfully.');
   WriteLn('TSR now active - parallel printer I/O errors will be masked.');
  End;
  _Germany: Begin
   WriteLn('PRINTFIX erfolgreich installiert.');
   WriteLn('TSR jetzt aktiv - Paralleldrucker-E/A-Fehler werden maskiert.');
  End
  Else Begin
   WriteLn('PRINTFIX installÇ avec succäs.');
   WriteLn('TSR maintenant actif - les erreurs d''entrÇe/sortie d''imprimante paralläle seront masquÇes.');
  End;
 End;
 Installed := True;
 {$IFDEF FPC}
   { Free Pascal: TSR non supportÇ nativement, juste terminer }
  Case Language of
   _English:WriteLn('Note: TSR functionality not fully supported in modern systems.');
   Else WriteLn('TSR non supportÇ nativement, juste terminer');
  End;
  Halt(0);
 {$ELSE}
  { Turbo Pascal: Calculer la taille du programme rÇsident et installer TSR }
  TSRSize := (Ofs(InstallTSR) - Ofs(NewInt17Handler) + 256 + 15) shr 4;
  Keep(0, TSRSize);
 {$ENDIF}
End;

 { Tentative de dÇsinstallation du TSR }
Procedure UninstallTSR;
Var
 CurrentVec: Pointer;
Begin
 GetIntVec($17,CurrentVec);
 If CurrentVec<>@NewInt17Handler Then Begin
  Case Language Of
   _English: WriteLn('PRINTFIX is not currently installed.');
   _Germany: WriteLn('PRINTFIX ist derzeit nicht installiert.');
   Else WriteLn('PRINTFIX n''est pas actuellement installÇ.');
  End;
  Halt(1);
 End;
  { Restaurer l'ancien vecteur }
 SetIntVec($17, OldInt17);
 Case Language Of
   _English: WriteLn('PRINTFIX uninstalled successfully.');
   _Germany: WriteLn('PRINTFIX erfolgreich deinstalliert.');
   Else WriteLn('PRINTFIX dÇsinstallÇ avec succäs.');
 End;
End;

{ Programme principal }
Var
 I: Integer;
 Param: String;

BEGIN
  { Initialiser variables }
 Language := _French;
 TmpLanguage := GetEnv('LANGUAGE');
 If TmpLanguage <> '' Then Begin
  If TmpLanguage[1] = '"' Then TmpLanguage := Copy(TmpLanguage, 2, 255);
  If StrToUpper(Copy(TmpLanguage, 1, 2)) = 'EN' Then Language := _English Else
  If StrToUpper(Copy(TmpLanguage, 1, 2)) = 'GR' Then Language := _Germany Else
  If StrToUpper(Copy(TmpLanguage, 1, 2)) = 'IT' Then Language := _Italian Else
  If StrToUpper(Copy(TmpLanguage, 1, 2)) = 'SP' Then Language := _Spain Else
  If (StrToUpper(Copy(TmpLanguage, 1, 2)) = 'SQ') or
     (StrToUpper(Copy(TmpLanguage, 1, 3)) = 'ALB') Then Language := _Albanian Else
  If (StrToUpper(Copy(TmpLanguage, 1, 2)) = 'PT') or
     (StrToUpper(Copy(TmpLanguage, 1, 3)) = 'PRT') Then Language := _Portuguese Else
  If (StrToUpper(Copy(TmpLanguage, 1, 2)) = 'SE') or
     (StrToUpper(Copy(TmpLanguage, 1, 3)) = 'SWE') Then Language := _Swedish Else
  If (StrToUpper(Copy(TmpLanguage, 1, 2)) = 'DK') or
     (StrToUpper(Copy(TmpLanguage, 1, 3)) = 'DNK') Then Language := _Danish Else
  If (StrToUpper(Copy(TmpLanguage, 1, 2)) = 'JP') or
     (StrToUpper(Copy(TmpLanguage, 1, 3)) = 'JPN') Then Language := _Japanese;
 End;
 Installed := False;
  { Traitement des paramätres de ligne de commande }
 For I := 1 To ParamCount Do Begin
  Param := StrToUpper(ParamStr(I));
  If (Param = '/?') or (Param = '-H') or (Param = '--HELP') or (Param = '/H') Then Begin
  Case Language Of
   _English: Begin
    WriteLn('PRINTFIX - Fix parallel printer I/O errors in MS-DOS 5.x');
     WriteLn;
     WriteLn('This TSR (Terminate Stay Resident) program fixes false I/O errors');
     WriteLn('on parallel printer ports that occur on some systems with MS-DOS 5.0+');
     WriteLn;
     WriteLn('Usage: PRINTFIX');
     WriteLn;
     WriteLn('The program installs itself as a TSR and intercepts BIOS interrupt 17h');
     WriteLn('to mask bit 3 (I/O error) from printer status reports.');
     WriteLn;
     WriteLn('Parameters:');
     WriteLn('  /?     Show this help');
     WriteLn('  /U     Uninstall TSR (if supported by system)');
   End;
    _Germany: Begin
      WriteLn('PRINTFIX - Reparatur von Paralleldruckerproblemen in MS-DOS 5.x');
      WriteLn;
      WriteLn('Dieses TSR-Programm behebt falsche E/A-Fehler bei Paralleldruckern,');
      WriteLn('die auf einigen Systemen mit MS-DOS 5.0+ auftreten.');
      WriteLn;
      WriteLn('Verwendung: PRINTFIX');
      WriteLn;
      WriteLn('Das Programm installiert sich als TSR und fÑngt BIOS-Interrupt 17h ab,');
      WriteLn('um Bit 3 (E/A-Fehler) aus Druckerstatus-Meldungen zu maskieren.');
      WriteLn;
      WriteLn('Parameter:');
      WriteLn('  /?     Diese Hilfe anzeigen');
      WriteLn('  /U     TSR deinstallieren (falls vom System unterst√ºtzt)');
    End
    Else Begin  { Franáais par dÇfaut }
      WriteLn('PRINTFIX - Cette commande permet d''installer la correction des erreurs d''imprimante paralläle ',
              'sous MS-DOS 5.x.');
      WriteLn;
      WriteLn('Ce programme TSR (Terminate Stay Resident) corrige les fausses erreurs d''entrÇe/sortie');
      WriteLn('sur les ports d''imprimante paralläle qui se produisent sur certains');
      WriteLn('systämes avec MS-DOS 5.0+');
      WriteLn;
      WriteLn('Syntaxe: PRINTFIX');
      WriteLn;
      WriteLn('Le programme s''installe en TSR et intercepte l''interruption BIOS 17h');
      WriteLn('pour masquer le bit 3 (erreur d''entrÇe/sortie) des rapports de statut d''imprimante.');
      WriteLn;
      WriteLn('Paramätres:');
      WriteLn('  /?     Afficher cette aide');
      WriteLn('  /U     DÇsinstaller le TSR (si supportÇ par le systäme)');
    End;
   End;
   Halt(0);
  End
   Else
  If Param = '/U' Then Begin
   UninstallTSR;
   Halt(0);
  End
   Else
  Begin
    Case Language Of
     _English: WriteLn('Invalid parameter: ', ParamStr(I));
     _Germany: WriteLn('UngÅltiger Parameter: ', ParamStr(I));
     Else WriteLn('Paramätre invalide: ', ParamStr(I));
    End;
    Halt(1);
   End;
  End;
  { Si aucun paramätre, installer le TSR }
 InstallTSR;
END.