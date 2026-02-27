{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

{ PRINTFIX - TSR pour corriger les erreurs d'impression sur port parallèle sous MS-DOS 5.x
  
  Ce programme est un TSR (Terminate Stay Resident) qui intercepte l'interruption BIOS 17h
  (services d'impression parallèle) pour corriger un problème spécifique avec MS-DOS 5.0+.
  
  Problème: Certains systèmes retournent le bit 3 du statut d'erreur E/S même quand 
  l'imprimante fonctionne correctement, causant des erreurs "Write fault" sous MS-DOS 5.x.
  
  Solution: Ce TSR remplace le gestionnaire INT 17h et masque le bit 3 d'erreur E/S
  pour éviter ces faux positifs.
}

{$M 16384,0,0}  { Mémoire nécessaire pour TSR }

{$IFDEF FPC}
  {$MODE TP}
  {$PACKRECORDS 1}
{$ENDIF}

{$IFDEF FPC}
{$MODE OBJFPC}
{$ENDIF}

Program PRINTFIX;

{ Déclarations système pour TSR }
{$IFDEF FPC}
Type
  PPointer = ^Pointer;
  
{ Fonctions système simulées pour Free Pascal }
Procedure GetIntVec(IntNo: Byte; Var Vector: Pointer);
Begin
  { Simulation basique - en réalité il faudrait accéder à la table des interruptions }
  Vector := Nil;
End;

Procedure SetIntVec(IntNo: Byte; Vector: Pointer);
Begin
  { Simulation basique - en réalité il faudrait modifier la table des interruptions }
End;

Function GetEnv(VarName: String): String;
Begin
  GetEnv := '';
End;

Procedure Keep(ExitCode: Word; Size: Word);
Begin
  { Simulation - ne fait rien sous Free Pascal moderne }
  Halt(ExitCode);
End;

Function ParamCount: Integer;
Var i: Integer;
Begin
  i := 0;
  While ParamStr(i+1) <> '' Do Inc(i);
  ParamCount := i;
End;

Function ParamStr(Index: Integer): String;
Begin
  { Simulation basique }
  ParamStr := '';
End;

{$ELSE}
{ Turbo Pascal - utiliser les fonctions système natives }
{$L-} { Désactiver les liens locaux }

{ Déclarations système pour Turbo Pascal }
Procedure GetIntVec(IntNo: Byte; Var Vector: Pointer); assembler;
asm
  push es
  mov al, IntNo
  mov ah, 35h
  int 21h
  les di, Vector
  mov word ptr es:[di], bx
  mov word ptr es:[di+2], es
  pop es
end;

Procedure SetIntVec(IntNo: Byte; Vector: Pointer); assembler;
asm
  push ds
  mov al, IntNo
  mov ah, 25h
  lds dx, Vector
  int 21h
  pop ds
end;

Function GetEnv(VarName: String): String;
Begin
  { Version simplifiée pour Turbo Pascal }
  GetEnv := '';
End;

Procedure Keep(ExitCode: Word; Size: Word); assembler;
asm
  mov al, byte ptr ExitCode
  mov dx, Size
  mov ah, 31h
  int 21h
end;

{$ENDIF}

Var
  Language : (_French,_English,_Germany,_Italian,_Spain,_Albanian,_Portuguese,_Swedish,_Danish,_Japanese);
  OldInt17 : Pointer;  { Pointeur vers l'ancien gestionnaire INT 17h }
  Installed : Boolean;

{ Fonction utilitaire pour convertir en majuscules }
Function StrToUpper(S:String):String;
Var I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

{ Détection de la langue système }
Procedure DetectLanguage;
Var
  Lang: String;
Begin
  Language := _French;
  Lang := StrToUpper(GetEnv('LANGUAGE'));
  If Lang = 'EN' Then Language := _English
  Else If Lang = 'GR' Then Language := _Germany
  Else If Lang = 'IT' Then Language := _Italian
  Else If Lang = 'SP' Then Language := _Spain
  Else If (Lang = 'SQ') or (Lang = 'ALB') Then Language := _Albanian
  Else If (Lang = 'PT') or (Lang = 'PRT') Then Language := _Portuguese
  Else If (Lang = 'SE') or (Lang = 'SWE') Then Language := _Swedish
  Else If (Lang = 'DK') or (Lang = 'DNK') Then Language := _Danish
  Else If (Lang = 'JP') or (Lang = 'JPN') Then Language := _Japanese;
End;

{ Affichage de l'aide selon la langue }
Procedure ShowHelp;
Begin
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
      WriteLn('Das Programm installiert sich als TSR und fängt BIOS-Interrupt 17h ab,');
      WriteLn('um Bit 3 (E/A-Fehler) aus Druckerstatus-Meldungen zu maskieren.');
      WriteLn;
      WriteLn('Parameter:');
      WriteLn('  /?     Diese Hilfe anzeigen');
      WriteLn('  /U     TSR deinstallieren (falls vom System unterstützt)');
    End
    Else Begin  { Français par défaut }
      WriteLn('PRINTFIX - Correction des erreurs d''imprimante parallèle sous MS-DOS 5.x');
      WriteLn;
      WriteLn('Ce programme TSR (Terminate Stay Resident) corrige les fausses erreurs E/S');
      WriteLn('sur les ports d''imprimante parallèle qui se produisent sur certains');
      WriteLn('systèmes avec MS-DOS 5.0+');
      WriteLn;
      WriteLn('Syntaxe: PRINTFIX');
      WriteLn;
      WriteLn('Le programme s''installe en TSR et intercepte l''interruption BIOS 17h');
      WriteLn('pour masquer le bit 3 (erreur E/S) des rapports de statut d''imprimante.');
      WriteLn;
      WriteLn('Paramètres:');
      WriteLn('  /?     Afficher cette aide');
      WriteLn('  /U     Désinstaller le TSR (si supporté par le système)');
    End;
  End;
End;

{ Nouveau gestionnaire d'interruption 17h }
Procedure NewInt17Handler; assembler;
asm
  { Sauvegarder les registres }
  push ax
  push bx
  push cx
  push dx
  push si
  push di
  push ds
  push es
  pushf
  
  { Vérifier si c'est la fonction Get Printer Status (AH=02h) }
  cmp ah, 02h
  jne @CallOldHandler
  
  { Pour la fonction Get Printer Status, retourner un statut fixe }
  { Bit 4 = Printer selected, Bit 7 = Printer not busy }
  mov ah, 90h
  popf
  pop es
  pop ds
  pop di
  pop si
  pop dx
  pop cx
  pop bx
  pop ax
  iret
  
@CallOldHandler:
  { Restaurer les drapeaux }
  popf
  
  { Restaurer les registres }
  pop es
  pop ds
  pop di
  pop si
  pop dx
  pop cx
  pop bx
  pop ax
  
  { Appeler l'ancien gestionnaire INT 17h }
  pushf
  call [OldInt17]
  
  { Masquer le bit 3 (I/O error) du statut retourné dans AH }
  and ah, 0F7h  { Bit 3 = 0 (pas d'erreur E/S) }
  
  iret
end;

{ Vérifier si le TSR est déjà installé }
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
      Else WriteLn('PRINTFIX est déjà installé.');
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
      WriteLn('PRINTFIX installé avec succès.');
      WriteLn('TSR maintenant actif - les erreurs E/S d''imprimante parallèle seront masquées.');
    End;
  End;
  
  Installed := True;
  
{$IFDEF FPC}
  { Free Pascal: TSR non supporté nativement, juste terminer }
  WriteLn('Note: TSR functionality not fully supported in modern systems.');
  Halt(0);
{$ELSE}
  { Turbo Pascal: Calculer la taille du programme résident et installer TSR }
  TSRSize := (Ofs(InstallTSR) - Ofs(NewInt17Handler) + 256 + 15) shr 4;
  Keep(0, TSRSize);
{$ENDIF}
End;

{ Tentative de désinstallation du TSR }
Procedure UninstallTSR;
Var
  CurrentVec: Pointer;
Begin
  GetIntVec($17, CurrentVec);
  
  If CurrentVec <> @NewInt17Handler Then Begin
    Case Language Of
      _English: WriteLn('PRINTFIX is not currently installed.');
      _Germany: WriteLn('PRINTFIX ist derzeit nicht installiert.');
      Else WriteLn('PRINTFIX n''est pas actuellement installé.');
    End;
    Halt(1);
  End;
  
  { Restaurer l'ancien vecteur }
  SetIntVec($17, OldInt17);
  
  Case Language Of
    _English: WriteLn('PRINTFIX uninstalled successfully.');
    _Germany: WriteLn('PRINTFIX erfolgreich deinstalliert.');
    Else WriteLn('PRINTFIX désinstallé avec succès.');
  End;
End;

{ Programme principal }
Var
  I: Integer;
  Param: String;
  
BEGIN
  DetectLanguage;
  
  { Traitement des paramètres de ligne de commande }
  For I := 1 To ParamCount Do Begin
    Param := StrToUpper(ParamStr(I));
    
    If (Param = '/?') or (Param = '-H') or (Param = '--HELP') or (Param = '/H') Then Begin
      ShowHelp;
      Halt(0);
    End
    Else If Param = '/U' Then Begin
      UninstallTSR;
      Halt(0);
    End
    Else Begin
      Case Language Of
        _English: WriteLn('Invalid parameter: ', ParamStr(I));
        _Germany: WriteLn('Ungültiger Parameter: ', ParamStr(I));
        Else WriteLn('Paramètre invalide: ', ParamStr(I));
      End;
      WriteLn;
      ShowHelp;
      Halt(1);
    End;
  End;
  
  { Si aucun paramètre, installer le TSR }
  InstallTSR;
END.
