# Instructions pour les Agents de Codage IA - MSDOS-0

## Vue d'ensemble du projet

MSDOS-0 est un clone des commandes MS-DOS basé sur Pascal supportant les langues française, allemande et anglaise. Chaque fichier `.PAS` implémente une seule commande DOS comme exécutable autonome, compilé avec Turbo Pascal 7 ou Free Pascal.

## Conventions de développement

### Système d'aide
- **Toujours implémenter** : paramètres `/?`, `--help`, `-h`, `/h`, `/H`
- Afficher les descriptions en français par défaut, en anglais avec la variable d'environnement `LANGUAGE=EN`
- Utiliser un format cohérent : nom de commande, description, syntaxe, détails des paramètres

### Gestion des erreurs
- Utiliser les directives `{$I-}` et `{$I+}` autour des opérations de fichier
- Vérifier `IOResult` pour les erreurs d'opération de fichier
- Fournir des messages d'erreur clairs en français (ex: "Fichier introuvable !")

## Structure des fichiers et modèles

### En-tête standard des fichiers
Chaque fichier Pascal doit inclure cet en-tête exact :
```pascal
{ @author: Sylvain Maltais (support@gladir.com)
  @created: YYYY
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}
```
### Compatibilité multi-plateforme
- Utiliser la compilation conditionnelle : `{$IFDEF WINDOWS}`, `{$IFDEF UNIX}`, `{$IFDEF DARWIN}`
- Inclure les unités spécifiques à la plateforme dans la clause Uses avec des conditions
- Gérer les séparateurs de chemin et les différences de système de fichiers

### Structure des programmes
- **Directive mémoire** : Utiliser `{$M 16384,0,0}` pour les programmes TSR, `{$N+}` pour les nombres flottants
- **Units** : Toujours `Uses Crt,DOS;` (certains fichiers utilisent aussi des unités spécifiques)
- **Nommage des programmes** : Correspondre au nom de fichier sans extension (ex: `Program VSAFE;` pour `VSAFE.PAS`)

### Support multi-langue
- Vérifier la variable d'environnement `LANGUAGE`
- Support : Français (par défaut), Anglais (`EN`), Allemand (`GR`), Italien (`IT`), Espagnol (`SP`), Albanais (`SQ`/`ALB`), Portugais (`PT`/`PRT`), Suédois (`SE`/`SWE`), Danois (`DK`/`DNK`), Japonais (`JP`/`JPN` - écrit en rōmaji)
- Utiliser un type énuméré : `Language:(_French,_English,_Germany,_Italian,_Spain,_Albanian,_Portuguese,_Swedish,_Danish,_Japanese);`


## Fonctions utilitaires essentielles

Ces fonctions sont couramment dupliquées dans les fichiers et doivent être incluses au besoin :

```pascal
Function StrToUpper(S:String):String;
Var I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function PadRight(S:String;Space:Byte):String;
Function PadZeroLeft(Value:Integer;Space:Byte):String;
Function GetErrorMessage(Code:Word):String;  // Pour les opérations sur fichiers
```

## Modèles spécifiques aux commandes

### Commandes système de bas niveau
Les fichiers comme `VSAFE.PAS`, `FASTOPEN.PAS` utilisent :
- **TSR (Terminate Stay Resident)** : `Keep(0);` pour rester en mémoire
- **Gestionnaires d'interruption** : `Procedure HandlerName(...);Interrupt;`
- **Interruptions DOS** : `Intr($21, Regs);`, `Intr($13, Regs);` pour les appels système
- **Accès mémoire** : `Mem[segment:offset]` pour la manipulation directe de la mémoire

### Opérations sur le système de fichiers
Les commandes comme `BACKUP.PAS`, `RESTORE.PAS`, `UNDELETE.PAS` :
- Utilisent `SearchRec` pour parcourir les répertoires
- Implémentent l'accès direct aux secteurs avec `ReadSector`/`WriteSector`
- Gèrent la manipulation directe de la FAT (File Allocation Table)

### Traitement de texte
- Gestion d'erreurs avec `{$I-}` et `{$I+}` autour des opérations sur fichiers
- Toujours vérifier `IOResult` après les opérations sur fichiers
- Utiliser `BlockRead`/`BlockWrite` pour les fichiers binaires, `ReadLn`/`WriteLn` pour le texte

## Compilation

Les commandes se compilent indépendamment sans dépendances :
```bash
fpc NOMFICHIER.PAS    # Free Pascal
tpc NOMFICHIER.PAS    # Turbo Pascal
```

Les binaires compilés vont dans le répertoire `/BIN16/` pour la compatibilité DOS 16-bit.

## Conventions de style de code

- **Nommage des variables** : PascalCase (ex: `CurrCommand`, `ParamList`)
- **Constantes** : MAJUSCULES avec underscores
- **Commentaires** : Utiliser `{ }` pour les commentaires bloc, éviter `//`
- **Indentation** : Indentations de 1 espace (style Pascal legacy)
- **Déclarations forward** : Utiliser le mot-clé `Forward;` pour les procédures appelées avant définition

## Considérations architecturales

- Chaque commande est complètement autonome - pas de bibliothèques ou modules partagés
- Les contraintes mémoire comptent - cible les vrais systèmes DOS avec RAM limitée
- L'accès direct au matériel/interruptions est commun et attendu
- Le français est la langue par défaut pour les messages utilisateur et texte d'aide
- Les messages d'erreur doivent être localisés selon la variable `Language`

## Fichiers clés à référencer

- `COMMAND.PAS` : Interpréteur de commandes complexe avec commandes intégrées
- `VSAFE.PAS` : Protection antivirus TSR avec gestion d'interruptions
- `TYPE.PAS` : Utilitaire simple d'affichage de fichiers montrant les modèles de base
- `XCOPY.PAS` : Opérations sur fichiers avec internationalisation

Rappel : Ce projet privilégie le comportement DOS authentique par rapport aux pratiques de programmation modernes. L'accès direct à la mémoire, la gestion d'interruptions et la vérification minimale d'erreurs sont des choix de conception intentionnels.
