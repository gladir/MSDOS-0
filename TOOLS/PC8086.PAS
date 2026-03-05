{ @author: Sylvain Maltais
  @created: 2026
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
  @description: Compilateur Pascal pour 8086
}

Program PC8086;

{$A-}

Uses DOS;

{ ============================================================================ }
{ CONSTANTES ET TYPES                                                          }
{ ============================================================================ }

Const
 MAX_SYMBOL_NAME = 32;
 MAX_STRING_LENGTH = 255;
 MAX_SYMBOLS = 1000;
 MAX_LABEL_COUNT = 100;
 MAX_INCLUDE_DEPTH = 10;

 { Types de symboles Pascal }
 SYM_UNKNOWN = 0;
 SYM_PROGRAM = 1;
 SYM_UNIT = 2;
 SYM_USES = 3;
 SYM_INTERFACE = 4;
 SYM_IMPLEMENTATION = 5;
 SYM_VAR = 6;
 SYM_CONST = 7;
 SYM_TYPE = 8;
 SYM_PROCEDURE = 9;
 SYM_FUNCTION = 10;
 SYM_BEGIN = 11;
 SYM_END = 12;
 SYM_IF = 13;
 SYM_THEN = 14;
 SYM_ELSE = 15;
 SYM_WHILE = 16;
 SYM_DO = 17;
 SYM_FOR = 18;
 SYM_TO = 19;
 SYM_DOWNTO = 20;
 SYM_REPEAT = 21;
 SYM_UNTIL = 22;
 SYM_CASE = 23;
 SYM_OF = 24;
 SYM_WRITE = 25;
 SYM_WRITELN = 26;
 SYM_READ = 27;
 SYM_READLN = 28;
 SYM_INTERRUPT = 29;
 SYM_RECORD = 30;
 SYM_ARRAY = 31;
 SYM_OTHERWISE = 32;
 SYM_LABEL = 33;
 SYM_GOTO = 34;
 SYM_FORWARD = 35;
 SYM_STRING_LITERAL = 50; { Chaåne littÇrale entre guillemets simples }
 SYM_NOT        = 51; { OpÇrateur NOT }
 SYM_HALT       = 52; { ProcÇdure HALT }
 SYM_PARAMCOUNT = 53; { Fonction ParamCount }
 SYM_PARAMSTR   = 54; { Fonction ParamStr }

 { OpÇrateurs de comparaison }
 SYM_EQUAL = 36;      { = }
 SYM_NOTEQUAL = 37;   { <> }
 SYM_LESS = 38;       { < }
 SYM_GREATER = 39;    { > }
 SYM_LESSEQ = 40;     { <= }
 SYM_GREATEREQ = 41;  { >= }

 { OpÇrateurs arithmÇtiques }
 SYM_PLUS = 42;       { + }
 SYM_MINUS = 43;      { - }
 SYM_MULTIPLY = 44;   { * }
 SYM_DIVIDE = 45;     { / }

 { OpÇrateurs logiques }
 SYM_AND = 46;        { AND }
 SYM_OR = 47;         { OR }
 SYM_XOR = 48;        { XOR }

 { Caractäres spÇciaux }
 SYM_DOT = 49;        { . }

 { Types de donnÇes Pascal }
 TYPE_INTEGER = 1;
 TYPE_BYTE = 2;
 TYPE_WORD = 3;
 TYPE_STRING = 4;
 TYPE_CHAR = 5;
 TYPE_BOOLEAN = 6;
 TYPE_REAL = 7;
 TYPE_RECORD = 8;
 TYPE_ARRAY = 9;
 TYPE_POINTER = 10;
 TYPE_TEXT = 11;   { Fichier texte (TextRec: 256 octets) }
 TYPE_FILE = 12;   { Fichier binaire gÇnÇrique (FileRec: 128 octets) }

  { Classes d'entreposage }
 STORAGE_GLOBAL = 1;
 STORAGE_LOCAL = 2;
 STORAGE_PARAMETER = 3;
 STORAGE_FUNCTION_RESULT = 4;
 STORAGE_UNIT_INTERFACE = 5;   { Symbole dÇfini dans l'interface d'une unitÇ }
 STORAGE_UNIT_IMPLEMENTATION = 6; { Symbole dÇfini dans l'implÇmentation d'une unitÇ }

Type
 { Structure pour les symboles }
 TSymbol = Record
  name: String[MAX_SYMBOL_NAME];
  symbol_type: Integer;
  data_type: Integer;
  storage_class: Integer;
  offset: Integer;
  value: Integer;
  defined: Boolean;
  return_type: Integer;      { Type de retour pour les fonctions }
  is_function: Boolean;      { Indicateur fonction vs procÇdure }
  record_size: Integer;      { Taille totale du record }
  field_count: Integer;      { Nombre de champs dans le record }
  unit_name: String[MAX_SYMBOL_NAME]; { Nom de l'unitÇ d'origine }
  is_external: Boolean;      { Symbole dÇfini dans une autre unitÇ }
  is_forward: Boolean;       { DÇclaration anticipÇe (forward) }
 End;

 { Pointeur vers un symbole }
 PSymbol = ^TSymbol;

 { Structure pour les Çtiquettes }
 TLabel = Record
  name: String[MAX_SYMBOL_NAME];
  label_id: Integer;
  defined: Boolean;
  address: Integer;
 End;

 { Pointeur vers une Çtiquette }
 PLabel = ^TLabel;

Var
 { Variables globales }
 input_file: Text;
 output_file: Text;
 current_line: String;
 line_pos: Integer;
 current_char: Char;
 line_number: Integer;

 { Table des symboles }
 symbol_table: Array[1..MAX_SYMBOLS] of PSymbol;
 symbol_count: Integer;

 { Table des Çtiquettes }
 label_table: Array[1..MAX_LABEL_COUNT] of PLabel;
 label_count: Integer;
 next_label_id: Integer;

 { êtat du compilateur }
 current_token: String;
 current_symbol: Integer;
 current_value: Integer;
 error_count: Integer;

 { Variables de gÇnÇration de code }
 code_segment: Boolean;  { True si MAIN PROC a ÇtÇ Çmis }
 code_header: Boolean;   { True si .CODE a ÇtÇ Çmis (dÇbut de section, avant MAIN PROC) }
 data_segment: Boolean;
 stack_offset: Integer;

 { Noms des fichiers }
 source_filename: String;
 output_filename: String;
 program_name: String;

 { Variables pour les fonctions }
 current_function_name: String;
 current_function_type: Integer;
 in_function: Boolean;

 { Variables pour les unitÇs }
 current_unit_name: String;
 in_unit: Boolean;
 in_interface: Boolean;
 in_implementation: Boolean;
 unit_symbols_start: Integer; { Index du premier symbole de l'unitÇ courante }

 { Options du compilateur }
 option_units_support: Boolean; { Option 3: Support complet des UNIT/INTERFACE/IMPLEMENTATION/USES }
 option_crt_dos_support: Boolean; { Option 2: Support partiel interne Uses Crt,DOS }

{ ============================================================================ }
{ FONCTIONS UTILITAIRES                                                        }
{ ============================================================================ }

{ Afficher un message d'erreur }
Procedure Error(msg: String);Begin
 WriteLn('ERREUR ligne ', line_number, ': ', msg);
 Inc(error_count);
End;

{ Afficher un avertissement }
Procedure Warning(msg: String);Begin
 WriteLn('ATTENTION ligne ', line_number, ': ', msg);
End;

{ Convertir une chaåne en majuscules }
Function UpperCase(s: String): String;
Var
 i: Integer;
 result: String;
Begin
 result := s;
 For i := 1 to Length(s) do
  If (s[i] >= 'a') and (s[i] <= 'z') Then
   result[i] := Chr(Ord(s[i]) - 32);
 UpperCase := result;
End;

{ ============================================================================ }
{ GESTION DES FICHIERS ET LECTURE                                             }
{ ============================================================================ }

{ Lire le caractäre suivant }
Procedure NextChar;Begin
 If line_pos > Length(current_line) Then Begin
  If not Eof(input_file) Then
  Begin
   ReadLn(input_file, current_line);
   Inc(line_number);
   line_pos := 1;
   If Length(current_line) = 0 Then
   Begin
    current_char := ' '; { Traiter ligne vide comme espace }
    Exit;
   End;
  End
  Else
  Begin
   current_char := #0;
   Exit;
  End;
 End;
 If line_pos <= Length(current_line) Then Begin
  current_char := current_line[line_pos];
  Inc(line_pos);
 End
  Else
 Begin
  current_char := ' '; { Fin de ligne = espace }
  Inc(line_pos); { Pour dÇclencher la lecture de la ligne suivante }
 End;
End;

{ Ignorer les espaces et commentaires }
Procedure SkipWhitespace;Begin
 While (current_char = ' ') or (current_char = #9) or (current_char = #13) or (current_char = #10) do
  NextChar;
 { GÇrer les commentaires Pascal dÇlimitÇs par accolades }
 If current_char = '{' Then
 Begin
  NextChar;
  While (current_char <> '}') and (current_char <> #0) do
   NextChar;
  If current_char = '}' Then
   NextChar;
  SkipWhitespace; { RÇcursion pour ignorer les espaces apräs commentaire }
 End;
 { GÇrer les commentaires Pascal (* *) }
 If (current_char = '(') and (line_pos <= Length(current_line)) and (current_line[line_pos] = '*') Then Begin
  NextChar; NextChar; { Ignorer (* }
  While not ((current_char = '*') and (line_pos <= Length(current_line))
         and (current_line[line_pos] = ')')) and (current_char <> #0) do
   NextChar;
  If current_char = '*' Then Begin
   NextChar; NextChar; { Ignorer *) }
  End;
  SkipWhitespace; { RÇcursion }
 End;
End;

{ ============================================================================ }
{ ANALYSEUR LEXICAL                                                           }
{ ============================================================================ }

{ Lire un identificateur ou mot-clef }
Procedure ReadIdentifier;Begin
 current_token := '';
 While ((current_char >= 'A') and (current_char <= 'Z')) or
       ((current_char >= 'a') and (current_char <= 'z')) or
       ((current_char >= '0') and (current_char <= '9')) or
       (current_char = '_') do
 Begin
  current_token := current_token + current_char;
  NextChar;
 End;
  { Identifier le type de symbole }
 current_token := UpperCase(current_token);
 If current_token = 'PROGRAM' Then current_symbol := SYM_PROGRAM
 Else If current_token = 'UNIT' Then current_symbol := SYM_UNIT
 Else If current_token = 'USES' Then current_symbol := SYM_USES
 Else If current_token = 'INTERFACE' Then current_symbol := SYM_INTERFACE
 Else If current_token = 'IMPLEMENTATION' Then current_symbol := SYM_IMPLEMENTATION
 Else If current_token = 'VAR' Then current_symbol := SYM_VAR
 Else If current_token = 'CONST' Then current_symbol := SYM_CONST
 Else If current_token = 'TYPE' Then current_symbol := SYM_TYPE
 Else If current_token = 'PROCEDURE' Then current_symbol := SYM_PROCEDURE
 Else If current_token = 'FUNCTION' Then current_symbol := SYM_FUNCTION
 Else If current_token = 'BEGIN' Then current_symbol := SYM_BEGIN
 Else If current_token = 'END' Then current_symbol := SYM_END
 Else If current_token = 'IF' Then current_symbol := SYM_IF
 Else If current_token = 'THEN' Then current_symbol := SYM_THEN
 Else If current_token = 'ELSE' Then current_symbol := SYM_ELSE
 Else If current_token = 'WHILE' Then current_symbol := SYM_WHILE
 Else If current_token = 'DO' Then current_symbol := SYM_DO
 Else If current_token = 'FOR' Then current_symbol := SYM_FOR
 Else If current_token = 'TO' Then current_symbol := SYM_TO
 Else If current_token = 'DOWNTO' Then current_symbol := SYM_DOWNTO
 Else If current_token = 'REPEAT' Then current_symbol := SYM_REPEAT
 Else If current_token = 'UNTIL' Then current_symbol := SYM_UNTIL
 Else If current_token = 'CASE' Then current_symbol := SYM_CASE
 Else If current_token = 'OF' Then current_symbol := SYM_OF
 Else If current_token = 'WRITE' Then current_symbol := SYM_WRITE
 Else If current_token = 'WRITELN' Then current_symbol := SYM_WRITELN
 Else If current_token = 'READ' Then current_symbol := SYM_READ
 Else If current_token = 'READLN' Then current_symbol := SYM_READLN
 Else If current_token = 'RECORD' Then current_symbol := SYM_RECORD
 Else If current_token = 'ARRAY' Then current_symbol := SYM_ARRAY
 Else If current_token = 'OTHERWISE' Then current_symbol := SYM_OTHERWISE
 Else If current_token = 'LABEL' Then current_symbol := SYM_LABEL
 Else If current_token = 'GOTO' Then current_symbol := SYM_GOTO
 Else If current_token = 'FORWARD' Then current_symbol := SYM_FORWARD
 Else If current_token = 'AND' Then current_symbol := SYM_AND
 Else If current_token = 'OR' Then current_symbol := SYM_OR
 Else If current_token = 'XOR' Then current_symbol := SYM_XOR
 Else If current_token = 'NOT' Then current_symbol := SYM_NOT
 Else If current_token = 'HALT' Then current_symbol := SYM_HALT
 Else If current_token = 'PARAMCOUNT' Then current_symbol := SYM_PARAMCOUNT
 Else If current_token = 'PARAMSTR' Then current_symbol := SYM_PARAMSTR
 Else current_symbol := SYM_UNKNOWN;
End;

{ Lire un nombre }
Procedure ReadNumber;
Var
 temp: String;
 code: Integer;
Begin
 temp := '';
 While (current_char >= '0') and (current_char <= '9') do Begin
  temp := temp + current_char;
  NextChar;
 End;
 Val(temp, current_value, code);
 If code <> 0 Then Begin
  Error('Nombre invalide: ' + temp);
  current_value := 0;
 End;
 current_token := temp;
 current_symbol := SYM_UNKNOWN;
End;

{ Obtenir le prochain jeton }
Procedure NextToken;Begin
 SkipWhitespace;
 If current_char = #0 Then
 Begin
  current_token := '';
  current_symbol := SYM_UNKNOWN;
  Exit;
 End;
 { Chaåne de caractäres }
 If current_char = '''' Then Begin
  current_token := '';
  current_symbol := SYM_STRING_LITERAL;
  NextChar; { Ignorer le premier guillemet }
  While current_char <> #0 do
  Begin
   If current_char = '''' Then
   Begin
    NextChar; { Consommer l'apostrophe }
    If current_char = '''' Then Begin
     { Double apostrophe = apostrophe littÇrale dans la chaåne }
     current_token := current_token + '''';
     NextChar;
    End
    Else
    Begin
     { Apostrophe simple = fin de cha√Æne (current_char est dÇjÖ le suivant) }
     Break;
    End;
   End
   Else
   Begin
    current_token := current_token + current_char;
    NextChar;
   End;
  End;
  { Pas de NextChar supplÇmentaire : la fin de chaåne est dÇjÖ consommÇe ci-dessus }
 End
 { OpÇrateur d'affectation := }
 Else If current_char = ':' Then
 Begin
  NextChar;
  If current_char = '=' Then
  Begin
   current_token := ':=';
   current_symbol := SYM_UNKNOWN;
   NextChar;
  End
  Else
  Begin
   current_token := ':';
   current_symbol := SYM_UNKNOWN;
  End;
 End
 { OpÇrateurs de comparaison }
 Else If current_char = '<' Then
 Begin
  NextChar;
  If current_char = '=' Then
  Begin
   current_token := '<=';
   current_symbol := SYM_LESSEQ;
   NextChar;
  End
  Else If current_char = '>' Then
  Begin
   current_token := '<>';
   current_symbol := SYM_NOTEQUAL;
   NextChar;
  End
  Else
  Begin
   current_token := '<';
   current_symbol := SYM_LESS;
  End;
 End
 Else If current_char = '>' Then
 Begin
  NextChar;
  If current_char = '=' Then
  Begin
   current_token := '>=';
   current_symbol := SYM_GREATEREQ;
   NextChar;
  End
  Else
  Begin
   current_token := '>';
   current_symbol := SYM_GREATER;
  End;
 End
 Else If current_char = '=' Then
 Begin
  current_token := '=';
  current_symbol := SYM_EQUAL;
  NextChar;
 End
 { Op√©rateurs arithm√©tiques }
 Else If current_char = '+' Then
 Begin
  current_token := '+';
  current_symbol := SYM_PLUS;
  NextChar;
 End
 Else If current_char = '-' Then
 Begin
  current_token := '-';
  current_symbol := SYM_MINUS;
  NextChar;
 End
 Else If current_char = '*' Then
 Begin
  current_token := '*';
  current_symbol := SYM_MULTIPLY;
  NextChar;
 End
 Else If current_char = '/' Then
 Begin
  current_token := '/';
  current_symbol := SYM_DIVIDE;
  NextChar;
 End
 { Identifier ou mot-clef }
 Else If ((current_char >= 'A') and (current_char <= 'Z')) or
    ((current_char >= 'a') and (current_char <= 'z')) or
    (current_char = '_') Then
  ReadIdentifier
 { Nombre }
 Else If (current_char >= '0') and (current_char <= '9') Then
  ReadNumber
 { Caractäres spÇciaux }
 Else If current_char = '.' Then
 Begin
  current_token := '.';
  current_symbol := SYM_DOT;
  NextChar;
 End
 Else
 Begin
  current_token := current_char;
  current_symbol := SYM_UNKNOWN;
  NextChar;
 End;
End;

{ ============================================================================ }
{ GESTION DE LA TABLE DES SYMBOLES                                            }
{ ============================================================================ }

{ Rechercher un symbole dans la table }
Function FindSymbol(name: String): Integer;
Var
 i: Integer;
Begin
 name := UpperCase(name);
 For i := 1 to symbol_count do
  If (symbol_table[i] <> nil) and (symbol_table[i]^.name = name) Then
  Begin
   FindSymbol := i;
   Exit;
  End;
 FindSymbol := 0;
End;

{ Ajouter un symbole Ö la table }
Function AddSymbol(name: String; sym_type, data_type, storage: Integer): Integer;
Var
 upper_name: String;
Begin
 If symbol_count >= MAX_SYMBOLS Then Begin
  Error('Table des symboles pleine');
  AddSymbol := 0;
  Exit;
 End;
 upper_name := UpperCase(name);
 Inc(symbol_count);
 New(symbol_table[symbol_count]);
 With symbol_table[symbol_count]^ do Begin
  name := upper_name;  { Utiliser la version en majuscules }
  symbol_type := sym_type;
  data_type := data_type;
  storage_class := storage;
  offset := 0;
  value := 0;
  defined := False;
  return_type := TYPE_INTEGER;  { Par d√©faut }
  is_function := False;
  record_size := 0;
  field_count := 0;
  is_forward := False;
 End;
 AddSymbol := symbol_count;
End;

{ Ajouter une fonction Ö la table des symboles }
Function AddFunction(name: String; return_type: Integer): Integer;
Var
 upper_name: String;
 rt: Integer; { Copie locale du paramätre return_type (Çvite le masquage par le champ With) }
Begin
 If symbol_count >= MAX_SYMBOLS Then Begin
  Error('Table des symboles pleine');
  AddFunction := 0;
  Exit;
 End;
 upper_name := UpperCase(name);
 rt := return_type; { Sauvegarder avant le bloc With }
 Inc(symbol_count);
 New(symbol_table[symbol_count]);
 With symbol_table[symbol_count]^ do Begin
  name := upper_name;
  symbol_type := SYM_FUNCTION;
  data_type := rt;
  storage_class := STORAGE_GLOBAL;
  offset := 0;
  value := 0;
  defined := True;
  return_type := rt;
  is_function := True;
  record_size := 0;
  field_count := 0;
  is_forward := False;
 End;
 AddFunction := symbol_count;
End;

{ Ajouter une procÇdure Ö la table des symboles }
Function AddProcedure(name: String): Integer;
Var
 upper_name: String;
Begin
 If symbol_count >= MAX_SYMBOLS Then Begin
  Error('Table des symboles pleine');
  AddProcedure := 0;
  Exit;
 End;
 upper_name := UpperCase(name);
 Inc(symbol_count);
 New(symbol_table[symbol_count]);
 With symbol_table[symbol_count]^ do Begin
  name := upper_name;
  symbol_type := SYM_PROCEDURE;
  data_type := TYPE_INTEGER; { Pas utilisÇ pour les procÇdures }
  storage_class := STORAGE_GLOBAL;
  offset := 0;
  value := 0;
  defined := True;
  return_type := TYPE_INTEGER; { Pas utilisÇ }
  is_function := False; { ProcÇdure, pas fonction }
  record_size := 0;
  field_count := 0;
  is_forward := False;
 End;
 AddProcedure := symbol_count;
End;

{ Ajouter une procÇdure d'interruption Ö la table des symboles }
Function AddInterrupt(name: String): Integer;
Var
 upper_name: String;
Begin
 If symbol_count >= MAX_SYMBOLS Then Begin
  Error('Table des symboles pleine');
  AddInterrupt := 0;
  Exit;
 End;
 upper_name := UpperCase(name);
 Inc(symbol_count);
 New(symbol_table[symbol_count]);
 With symbol_table[symbol_count]^ do Begin
  name := upper_name;
  symbol_type := SYM_INTERRUPT;
  data_type := TYPE_INTEGER; { Pas utilisÇ pour les interruptions }
  storage_class := STORAGE_GLOBAL;
  offset := 0;
  value := 0;
  defined := True;
  return_type := TYPE_INTEGER; { Pas utilisÇ }
  is_function := False; { ProcÇdure d'interruption, pas fonction }
  record_size := 0;
  field_count := 0;
  is_forward := False;
 End;
 AddInterrupt := symbol_count;
End;

{ Ajouter un type RECORD Ö la table des symboles }
Function AddRecord(name: String; size: Integer): Integer;
Var
 upper_name: String;
Begin
 If symbol_count >= MAX_SYMBOLS Then Begin
  Error('Table des symboles pleine');
  AddRecord := 0;
  Exit;
 End;
 upper_name := UpperCase(name);
 Inc(symbol_count);
 New(symbol_table[symbol_count]);
 With symbol_table[symbol_count]^ do Begin
  name := upper_name;
  symbol_type := SYM_TYPE;
  data_type := TYPE_RECORD;
  storage_class := STORAGE_GLOBAL;
  offset := 0;
  value := 0;
  defined := True;
  return_type := TYPE_INTEGER; { Pas utilis√© }
  is_function := False;
  record_size := size;
  field_count := 0;
 End;
 AddRecord := symbol_count;
End;

 { Ajouter un champ de RECORD Ö la table des symboles }
Function AddRecordField(field_name: String; field_type: Integer; record_index: Integer; field_offset: Integer): Integer;
Var
 upper_name: String;
Begin
 If symbol_count >= MAX_SYMBOLS Then
 Begin
  Error('Table des symboles pleine');
  AddRecordField := 0;
  Exit;
 End;
 upper_name := UpperCase(field_name);
 Inc(symbol_count);
 New(symbol_table[symbol_count]);
 With symbol_table[symbol_count]^ do Begin
  name := upper_name;
  symbol_type := SYM_VAR; { Les champs sont traitÇs comme des variables }
  data_type := field_type;
  storage_class := STORAGE_PARAMETER; { UtilisÇ pour indiquer que c'est un champ }
  offset := field_offset;
  value := record_index; { Index du record parent }
  defined := True;
  return_type := TYPE_INTEGER;
  is_function := False;
  record_size := 0;
  field_count := 0;
 End;
  { IncrÇmenter le nombre de champs du record parent }
 If (record_index > 0) and (record_index <= symbol_count) Then
  Inc(symbol_table[record_index]^.field_count);
 AddRecordField := symbol_count;
End;

 { Ajouter un type alias Ö la table des symboles }
Function AddTypeAlias(type_name: String; base_type: Integer): Integer;
Var
 upper_name: String;
Begin
 If symbol_count >= MAX_SYMBOLS Then
 Begin
  Error('Table des symboles pleine');
  AddTypeAlias := 0;
  Exit;
 End;
 upper_name := UpperCase(type_name);
 Inc(symbol_count);
 New(symbol_table[symbol_count]);
 With symbol_table[symbol_count]^ do Begin
  name := upper_name;
  symbol_type := SYM_TYPE;
  data_type := base_type;
  storage_class := STORAGE_GLOBAL;
  offset := 0;
  value := 0;
  defined := True;
  return_type := TYPE_INTEGER;
  is_function := False;
  record_size := 0;
  field_count := 0;
 End;
 AddTypeAlias := symbol_count;
End;

{ ============================================================================ }
{ GêNêRATION DE CODE ASSEMBLEUR 8086                                           }
{ ============================================================================ }

{ êcrire une ligne dans le fichier de sortie }
Procedure EmitLine(line: String);Begin
 WriteLn(output_file, line);
End;

{ GÇnÇrer une instruction assembleur }
Procedure Emit(instruction: String);Begin
 EmitLine('    ' + instruction);
End;

{ GÇnÇrer une Çtiquette }
Procedure EmitLabel(label_name: String);Begin
 EmitLine(label_name + ':');
End;

{ GÇnÇrer un commentaire }
Procedure EmitComment(comment: String);
Begin
 EmitLine('; ' + comment);
End;

{ GÇnÇrer l'entàte du programme }
Procedure GenerateHeader;
Var
 year, month, day, dayofweek: Word;
 hour, minute, second, sec100: Word;
 date_str, time_str, temp: String;
Begin
 EmitComment('CompilÇ par PC8086 - Compilateur Pascal vers 8086');
  { Obtenir la date systäme }
 GetDate(year, month, day, dayofweek);
  { Construire la chaåne de date manuellement }
 Str(year, temp);
 date_str := temp + '-';
 If month < 10 Then date_str := date_str + '0';
 Str(month, temp);
 date_str := date_str + temp + '-';
 If day < 10 Then date_str := date_str + '0';
 Str(day, temp);
 date_str := date_str + temp;
  { Obtenir l'heure systäme }
 GetTime(hour, minute, second, sec100);
  { Construire la chaåne d'heure }
 time_str := '';
 If hour < 10 Then time_str := time_str + '0';
 Str(hour, temp);
 time_str := time_str + temp + ':';
 If minute < 10 Then time_str := time_str + '0';
 Str(minute, temp);
 time_str := time_str + temp + ':';
 If second < 10 Then time_str := time_str + '0';
 Str(second, temp);
 time_str := time_str + temp;
 EmitComment('Date: ' + date_str + ' ' + time_str);
 EmitLine('');
 EmitLine('.MODEL SMALL');
 EmitLine('.STACK 100h');
 EmitLine('');
 EmitLine('.DATA');
 { DÇfinir les cha√Ænes constantes pour les boolÇens }
 EmitLine('TRUE_STR  DB ''TRUE$''');
 EmitLine('FALSE_STR DB ''FALSE$''');
 EmitLine('');
 data_segment := True;
End;

{ DÇclaration anticipÇe - dÇfinie plus loin dans le fichier }
Function IntToStr(value: Integer): String; forward;

{ GÇnÇrer la dÇclaration d'une variable }
Procedure GenerateVariableDeclaration(var_name: String; var_type: Integer; string_size: Integer);
Var
 type_index: Integer;
 record_size: Integer;
Begin
 If not data_segment Then
 Begin
  EmitLine('.DATA');
  data_segment := True;
 End;

 Case var_type of
  TYPE_INTEGER, TYPE_WORD: EmitLine(var_name + ' DW ?');
  TYPE_BYTE, TYPE_CHAR: EmitLine(var_name + ' DB ?');
  TYPE_STRING:
   Begin
    { Une chaåne Pascal: 1 octet longueur + string_size caractäres }
    EmitLine(var_name + ' DB ' + IntToStr(string_size + 1) + ' DUP(?)')
   End;
  TYPE_BOOLEAN: EmitLine(var_name + ' DB ?');
  TYPE_RECORD:
   Begin
    { Chercher la taille du record dans la table des symboles }
    type_index := FindSymbol(var_name); { Ceci ne fonctionnera pas, il faudrait passer le type }
    { Pour l'instant, utiliser une taille par dÇfaut }
    EmitLine(var_name + ' DB 64 DUP(?) ; Record (taille estimÇe)');
   End;
  TYPE_ARRAY:
   Begin
    { Taille totale en octets transmise via le paramätre string_size }
    EmitLine(var_name + ' DB ' + IntToStr(string_size) + ' DUP(?) ; Tableau');
   End;
  TYPE_POINTER:
   Begin
    { Les pointeurs sont des mots de 16 bits en 8086 }
    EmitLine(var_name + ' DW ? ; Pointeur');
   End;
  TYPE_TEXT:
   Begin
    { TextRec de Turbo Pascal = 256 octets }
    EmitLine(var_name + ' DB 256 DUP(?) ; TextRec');
   End;
  TYPE_FILE:
   Begin
    { FileRec de Turbo Pascal = 128 octets }
    EmitLine(var_name + ' DB 128 DUP(?) ; FileRec');
   End;
 Else
  EmitLine(var_name + ' DW ?'); { Par d√©faut }
 End;
End;

{ Commencer la section .CODE sans MAIN PROC (pour les procÇdures utilisateur) }
Procedure StartCodeSection;Begin
 If data_segment Then
 Begin
  EmitLine('');
  data_segment := False;
 End;
 If not code_header Then
 Begin
  EmitLine('.CODE');
  code_header := True;
 End;
End;

{ Commencer la section de code principale (MAIN PROC) }
Procedure BeginCodeSection;Begin
 StartCodeSection; { Assure que .CODE est √©mis }
 If not code_segment Then Begin
  EmitLine('MAIN PROC');
  EmitLine('    mov ax, @data');
  EmitLine('    mov ds, ax');
  EmitLine('');
  code_segment := True;
 End;
End;

 { Terminer le programme }
Procedure GenerateFooter;Begin
 If code_segment Then
 Begin
  EmitLine('');
  EmitLine('    mov ax, 4C00h');
  EmitLine('    int 21h');
  EmitLine('MAIN ENDP');
  EmitLine('END MAIN');
 End;
End;

 { Convertir un entier en chaåne }
Function IntToStr(value: Integer): String;
Var
 result: String;
 negative: Boolean;
 digit: Integer;
Begin
 If value = 0 Then Begin
  IntToStr := '0';
  Exit;
 End;
 result := '';
 negative := value < 0;
 If negative Then value := -value;
 While value > 0 do Begin
  digit := value mod 10;
  result := Chr(48 + digit) + result;
  value := value div 10;
 End;
 If negative Then result := '-' + result;
 IntToStr := result;
End;

{ GÇnÇrer une nouvelle Çtiquette }
Function NewLabel: String;Begin
 Inc(next_label_id);
 NewLabel := 'L' + IntToStr(next_label_id);
End;

{ ============================================================================ }
{ ANALYSEUR SYNTAXIQUE PASCAL                                                 }
{ ============================================================================ }

{ DÇclarations anticipÇes }
Procedure ParseStatement; forward;
Procedure ParseExpression; forward;
Procedure ParseBlock; forward;
Procedure ParseFor; forward;
Procedure ParseCase; forward;
Procedure ParseUnit; forward;
Procedure ParseInterface; forward;
Procedure ParseImplementation; forward;
Procedure ParseUses; forward;
Procedure ParseLabelDeclarations; forward;
Procedure ParseConstDeclarations; forward;
Procedure ParseGoto; forward;
Procedure ParseProgramMain; forward;

 { Ajouter une Çtiquette Ö la table }
Function AddLabel(name: String): Integer;
Var
 upper_name: String;
Begin
 If label_count >= MAX_LABEL_COUNT Then Begin
  Error('Table des Çtiquettes pleine');
  AddLabel := 0;
  Exit;
 End;
 upper_name := UpperCase(name);
 Inc(label_count);
 New(label_table[label_count]);
 With label_table[label_count]^ do Begin
  name := upper_name;
  label_id := next_label_id;
  defined := False;
  address := 0;
 End;
 Inc(next_label_id);
 AddLabel := label_count;
End;

 { Rechercher une Çtiquette dans la table }
Function FindLabel(name: String): Integer;
Var
 i: Integer;
Begin
 name := UpperCase(name);
 For i := 1 to label_count do
  If (label_table[i] <> nil) and (label_table[i]^.name = name) Then Begin
   FindLabel := i;
   Exit;
  End;
 FindLabel := 0;
End;

Function Accept(expected_symbol: Integer): Boolean;Begin
 Accept := (current_symbol = expected_symbol);
End;

 { Consommer un token attendu }
Procedure Expect(expected_symbol: Integer; error_msg: String);Begin
 If current_symbol = expected_symbol Then
  NextToken
 Else
  Error(error_msg + ', trouvÇ: ' + current_token);
End;

 { Analyser une expression simple }
Procedure ParseExpression;
Var
 sym_index: Integer;
 temp_token: String;
 left_operand: String;
 left_type: Integer; { Type du premier opÇrande }
 comparison_op: Integer;
 is_string_literal: Boolean;
 string_label: String;
Begin
 left_type := TYPE_INTEGER; { Type par dÇfaut }
 is_string_literal := False;
  { Analyser le premier opÇrande }
 { Chaåne littÇrale entre guillemets simples }
 If current_symbol = SYM_STRING_LITERAL Then Begin
  temp_token := current_token;
  string_label := 'STR' + IntToStr(next_label_id);
  Inc(next_label_id);
  If not data_segment Then Begin
   EmitLine('.DATA');
   data_segment := True;
  End;
  EmitLine(string_label + ' DB ' + IntToStr(Length(temp_token)) + ', ''' + temp_token + '''');
  If not code_segment Then BeginCodeSection;
  Emit('mov si, OFFSET ' + string_label);
  left_operand := 'si';
  left_type := TYPE_STRING;
  NextToken;
 End
  Else
 If current_symbol = SYM_UNKNOWN Then Begin
  temp_token := current_token;
  { Expression groupÇe entre parenthäses }
  If temp_token = '(' Then Begin
   NextToken; { Consommer ( }
   ParseExpression; { êvaluer l'expression interne, rÇsultat dans AX }
   left_operand := 'ax';
   left_type := TYPE_INTEGER;
   If current_token = ')' Then NextToken;
  End
  { Nombre littÇral (commence par un chiffre) }
  Else If (temp_token <> '') and (temp_token[1] >= '0') and (temp_token[1] <= '9') Then
  Begin
   Emit('mov ax, ' + temp_token);
   left_operand := 'ax';
   left_type := TYPE_INTEGER;
   NextToken;
  End
  Else If temp_token <> '' Then
  Begin
   { Identificateur - chercher dans la table des symboles en PREMIER }
   sym_index := FindSymbol(temp_token);
   If sym_index > 0 Then
   Begin
    left_type := symbol_table[sym_index]^.data_type;
     { VÇrifier si c'est un appel de fonction }
    If symbol_table[sym_index]^.is_function Then Begin
     { Appel de fonction }
     EmitComment('Appel fonction: ' + temp_token);
     NextToken; { Consommer le nom de la fonction }
      { GÇrer les paramätres (pour l'instant, on ignore) }
     If current_token = '(' Then Begin
      NextToken;
      While (current_token <> ')') and (current_char <> #0) do
       NextToken;
      If current_token = ')' Then
       NextToken;
     End;
      { GÇnÇrer l'appel }
     Emit('call ' + symbol_table[sym_index]^.name);
     { Le rÇsultat est dans AX ou AL selon le type de retour }
     Case symbol_table[sym_index]^.return_type of
      TYPE_INTEGER, TYPE_WORD: left_operand := 'ax';
      TYPE_BYTE, TYPE_CHAR: left_operand := 'al';
      TYPE_STRING: left_operand := 'si';
     Else
      left_operand := 'ax';
     End;
     left_type := symbol_table[sym_index]^.return_type;
    End
    { VÇrifier si c'est un appel de procÇdure }
    Else If symbol_table[sym_index]^.symbol_type = SYM_PROCEDURE Then
    Begin
     { Appel de procÇdure }
     EmitComment('Appel procÇdure: ' + temp_token);
     NextToken; { Consommer le nom de la procÇdure }
     { GÇrer les paramätres (pour l'instant, on ignore) }
     If current_token = '(' Then
     Begin
      NextToken;
      While (current_token <> ')') and (current_char <> #0) do
       NextToken;
      If current_token = ')' Then
       NextToken;
     End;
     { GÇnÇrer l'appel - les procÇdures ne retournent pas de valeur }
     Emit('call ' + symbol_table[sym_index]^.name);
     left_operand := 'ax'; { Valeur par dÇfaut }
     left_type := TYPE_INTEGER;
    End
    { VÇrifier si c'est un appel d'interruption }
     Else
    If symbol_table[sym_index]^.symbol_type = SYM_INTERRUPT Then Begin
     { Appel d'interruption }
     EmitComment('Appel interruption: ' + temp_token);
     NextToken; { Consommer le nom de l'interruption }
     { GÇrer les paramätres (pour l'instant, on ignore) }
     If current_token = '(' Then Begin
      NextToken;
      While (current_token <> ')') and (current_char <> #0) do NextToken;
      If current_token = ')' Then NextToken;
     End;
     { GÇnÇrer l'appel - les interruptions ne retournent pas de valeur }
     Emit('call ' + symbol_table[sym_index]^.name);
     left_operand := 'ax'; { Valeur par dÇfaut }
     left_type := TYPE_INTEGER;
    End
    { VÇrifier si c'est une constante }
     Else
    If symbol_table[sym_index]^.symbol_type = SYM_CONST Then Begin
     { Constante - Çmettre la valeur immÇdiate directement }
     Case symbol_table[sym_index]^.data_type of
      TYPE_STRING:
       Begin
        Emit('mov si, OFFSET ' + UpperCase(symbol_table[sym_index]^.name) + '_STR');
        left_operand := 'si';
       End;
      TYPE_BYTE, TYPE_CHAR:
       Begin
        Emit('mov al, ' + IntToStr(symbol_table[sym_index]^.value));
        left_operand := 'al';
       End;
     Else
      Begin
       Emit('mov ax, ' + IntToStr(symbol_table[sym_index]^.value));
       left_operand := 'ax';
      End;
     End;
     left_type := symbol_table[sym_index]^.data_type;
     NextToken;
    End
     Else
    Begin
     { Variable normale }
     Case symbol_table[sym_index]^.data_type of
      TYPE_INTEGER, TYPE_WORD:
       Begin
        Emit('mov ax, ' + symbol_table[sym_index]^.name);
        left_operand := 'ax';
       End;
      TYPE_BYTE, TYPE_CHAR:
       Begin
        Emit('mov al, ' + symbol_table[sym_index]^.name);
        left_operand := 'al';
       End;
      TYPE_STRING:
       Begin
        Emit('mov si, OFFSET ' + symbol_table[sym_index]^.name);
        left_operand := 'si';
       End;
     Else
      Begin
       Emit('mov ax, ' + symbol_table[sym_index]^.name);
       left_operand := 'ax';
      End;
     End;
     NextToken;
    End;
   End
   Else
   Begin
    Error('Variable non dÇclarÇe: ' + temp_token);
    left_operand := 'ax';
    left_type := TYPE_INTEGER;
    NextToken;
   End;
  End
  Else
  Begin
   NextToken; { Token vide, continuer }
   left_operand := 'ax';
   left_type := TYPE_INTEGER;
  End;
 End
  Else
 If current_symbol = SYM_NOT Then Begin
  NextToken; { Consommer NOT }
  { Analyser le jeton suivant comme opÇrande de NOT }
  If (current_symbol = SYM_UNKNOWN) and (current_token <> '') Then Begin
   temp_token := current_token;
   sym_index := FindSymbol(temp_token);
   If sym_index > 0 Then Begin
    { Appel de fonction dans NOT }
    If symbol_table[sym_index]^.is_function Then Begin
     NextToken; { Consommer nom de la fonction }
     If current_token = '(' Then Begin
      NextToken;
      While (current_token <> ')') and (current_char <> #0) do NextToken;
      If current_token = ')' Then NextToken;
     End;
     Emit('call ' + symbol_table[sym_index]^.name);
    End
    Else
    Begin
     Case symbol_table[sym_index]^.data_type of
      TYPE_BYTE, TYPE_CHAR, TYPE_BOOLEAN:
       Begin
        Emit('mov al, ' + symbol_table[sym_index]^.name);
        Emit('mov ah, 0');
       End;
     Else
      Emit('mov ax, ' + symbol_table[sym_index]^.name);
     End;
     NextToken;
    End;
    Emit('xor ax, 1'); { NOT bool√©en }
   End
   Else
   Begin
    Error('Variable non dÇclarÇe apräs NOT: ' + temp_token);
    Emit('xor ax, 1');
    NextToken; { Avancer uniquement en cas d'erreur (identifiant inconnu) }
   End;
   { Pas de NextToken ici : la branche fonction/variable a dÇjÖ avancÇ }
  End
  Else
  Begin
   { NOT appliquÇ Ö une sous-expression dÇjÖ dans AX }
   ParseExpression;
   Emit('xor ax, 1');
  End;
  left_operand := 'ax';
  left_type := TYPE_BOOLEAN;
 End
  Else
 If current_symbol = SYM_PARAMCOUNT Then Begin
  Emit('call PARAMCOUNT'); { Nombre de paramätres Ö AX }
  left_operand := 'ax';
  left_type := TYPE_INTEGER;
  NextToken;
 End
  Else
 If current_symbol = SYM_PARAMSTR Then Begin
  NextToken; { Consommer PARAMSTR }
  If current_token = '(' Then Begin
   NextToken; { Consommer ( }
   { Analyser l'index du paramätre dans AX }
   If (current_symbol = SYM_UNKNOWN) and (current_token <> '') Then Begin
    If (current_token[1] >= '0') and (current_token[1] <= '9') Then Begin
     Emit('mov ax, ' + current_token);
     NextToken;
    End
     Else
    Begin
     sym_index := FindSymbol(current_token);
     If sym_index > 0 Then
      Emit('mov ax, ' + symbol_table[sym_index]^.name)
     Else
      Emit('mov ax, 1');
     NextToken;
    End;
   End
   Else
    Emit('mov ax, 1');
   If current_token = ')' Then NextToken;
  End
  Else
   Emit('mov ax, 1'); { D√©faut: premier param√®tre }
  Emit('call PARAMSTR'); { R√©sultat: SI = pointeur cha√Æne Pascal }
  left_operand := 'si';
  left_type := TYPE_STRING;
 End
  Else
 Begin
  NextToken; { Symbole reconnu, continuer }
  left_operand := 'ax';
  left_type := TYPE_INTEGER;
 End;
  { Traiter toutes les opÇrations arithmÇtiques ou logiques (AND/OR/XOR en chaåne) }
 While (current_symbol = SYM_PLUS) or (current_symbol = SYM_MINUS) or
    (current_symbol = SYM_MULTIPLY) or (current_symbol = SYM_DIVIDE) or
    (current_symbol = SYM_AND) or (current_symbol = SYM_OR) or (current_symbol = SYM_XOR) Do
 Begin
  comparison_op := current_symbol;
  NextToken; { Consommer l'opÇrateur }
  { Parser le deuxiäme opÇrande }
  { Expression groupÇe entre parenthäses }
  If (current_symbol = SYM_UNKNOWN) and (current_token = '(') Then Begin
   Emit('push ax'); { Sauvegarder rÇsultat du premier opÇrande }
   NextToken; { Consommer ( }
   ParseExpression; { êvaluer expression interne Ö AX }
   Emit('pop bx'); { Premier opÇrande Ö BX }
   Case comparison_op of
    SYM_AND: Emit('and bx, ax');
    SYM_OR:  Emit('or bx, ax');
    SYM_XOR: Emit('xor bx, ax');
   Else
    Emit('or bx, ax');
   End;
   Emit('mov ax, bx');
   left_operand := 'ax';
   If current_token = ')' Then NextToken;
  End
   Else
  If current_symbol = SYM_UNKNOWN Then Begin
   temp_token := current_token;
    { Nombre littÇral }
   If (temp_token <> '') and (temp_token[1] >= '0') and (temp_token[1] <= '9') Then Begin
    { GÇnÇrer l'opÇration }
    Case comparison_op of
     SYM_PLUS:
      Begin
       { VÇrifier si c'est une concatÇnation de chaånes }
       If left_type = TYPE_STRING Then Begin
        { ConcatÇnation de chaånes - pour l'instant on gÇnäre un appel de fonction }
        EmitComment('ConcatÇnation de chaånes');
        Emit('call CONCAT_STR');
       End
       Else If left_operand = 'ax' Then
        Emit('add ax, ' + temp_token)
       Else
        Emit('add al, ' + temp_token);
      End;
     SYM_MINUS:
      Begin
       If left_operand = 'ax' Then
        Emit('sub ax, ' + temp_token)
       Else
        Emit('sub al, ' + temp_token);
      End;
     SYM_MULTIPLY:
      Begin
       If left_operand = 'ax' Then
       Begin
        Emit('mov bx, ' + temp_token);
        Emit('mul bx');
       End
       Else
       Begin
        Emit('mov bl, ' + temp_token);
        Emit('mul bl');
       End;
      End;
     SYM_DIVIDE:
      Begin
       If left_operand = 'ax' Then
       Begin
        Emit('mov bx, ' + temp_token);
        Emit('div bx');
       End
       Else
       Begin
        Emit('mov bl, ' + temp_token);
        Emit('div bl');
       End;
      End;
     SYM_AND:
      Begin
       If left_operand = 'ax' Then
        Emit('and ax, ' + temp_token)
       Else
        Emit('and al, ' + temp_token);
      End;
     SYM_OR:
      Begin
       If left_operand = 'ax' Then
        Emit('or ax, ' + temp_token)
       Else
        Emit('or al, ' + temp_token);
      End;
     SYM_XOR:
      Begin
       If left_operand = 'ax' Then
        Emit('xor ax, ' + temp_token)
       Else
        Emit('xor al, ' + temp_token);
      End;
    End;
    NextToken;
   End
    Else
   If temp_token <> '' Then Begin
    { Variable - chercher dans la table des symboles }
    sym_index := FindSymbol(temp_token);
    If sym_index > 0 Then
    Begin
     Case comparison_op of
      SYM_PLUS:
       Begin
        { VÇrifier si c'est une concatÇnation de chaånes }
        If (left_type = TYPE_STRING) and (symbol_table[sym_index]^.data_type = TYPE_STRING) Then
        Begin
         EmitComment('ConcatÇnation de chaånes');
         Emit('mov di, OFFSET ' + symbol_table[sym_index]^.name);
         Emit('call CONCAT_STR'); { Appel de fonction de concatÇnation }
        End
        Else If left_operand = 'ax' Then
         Emit('add ax, ' + symbol_table[sym_index]^.name)
        Else
         Emit('add al, ' + symbol_table[sym_index]^.name);
       End;
      SYM_MINUS:
       Begin
        If left_operand = 'ax' Then
         Emit('sub ax, ' + symbol_table[sym_index]^.name)
        Else
         Emit('sub al, ' + symbol_table[sym_index]^.name);
       End;
      SYM_MULTIPLY:
       Begin
        If left_operand = 'ax' Then
        Begin
         Emit('mov bx, ' + symbol_table[sym_index]^.name);
         Emit('mul bx');
        End
        Else
        Begin
         Emit('mov bl, ' + symbol_table[sym_index]^.name);
         Emit('mul bl');
        End;
       End;
      SYM_DIVIDE:
       Begin
        If left_operand = 'ax' Then
        Begin
         Emit('mov bx, ' + symbol_table[sym_index]^.name);
         Emit('div bx');
        End
        Else
        Begin
         Emit('mov bl, ' + symbol_table[sym_index]^.name);
         Emit('div bl');
        End;
       End;
      SYM_AND:
       Begin
        If left_operand = 'ax' Then
         Emit('and ax, ' + symbol_table[sym_index]^.name)
        Else
         Emit('and al, ' + symbol_table[sym_index]^.name);
       End;
      SYM_OR:
       Begin
        If left_operand = 'ax' Then
         Emit('or ax, ' + symbol_table[sym_index]^.name)
        Else
         Emit('or al, ' + symbol_table[sym_index]^.name);
       End;
      SYM_XOR:
       Begin
        If left_operand = 'ax' Then
         Emit('xor ax, ' + symbol_table[sym_index]^.name)
        Else
         Emit('xor al, ' + symbol_table[sym_index]^.name);
       End;
     End;
    End
    Else
     Error('Variable non dÇclarÇe: ' + temp_token);
    NextToken;
   End;
   left_operand := 'ax'; { Le rÇsultat est toujours dans AX }
  End;
 End;
  { VÇrifier s'il y a un opÇrateur de comparaison }
 comparison_op := current_symbol;
 If (comparison_op = SYM_EQUAL) or (comparison_op = SYM_NOTEQUAL) or
    (comparison_op = SYM_LESS) or (comparison_op = SYM_GREATER) or
    (comparison_op = SYM_LESSEQ) or (comparison_op = SYM_GREATEREQ) Then
 Begin
  NextToken; { Consommer l'opÇrateur }

  { Analyser le deuxiäme opÇrande }
  If current_symbol = SYM_STRING_LITERAL Then Begin
   { Comparaison de chaåne littÇrale: appel COMPARE_STR }
   temp_token := current_token;
   string_label := 'CMP_STR' + IntToStr(next_label_id);
   Inc(next_label_id);
   If not data_segment Then Begin
    EmitLine('.DATA');
    data_segment := True;
   End;
   EmitLine(string_label + ' DB ' + IntToStr(Length(temp_token)) + ', ''' + temp_token + '''');
   If not code_segment Then BeginCodeSection;
   Emit('mov di, OFFSET ' + string_label); { DI = chaåne droite }
   Emit('call COMPARE_STR');               { AX = 0 si Çgal, 1 si diffÇrent }
   Emit('cmp ax, 0');                      { PrÇparer drapeaux pour saut conditionnel }
   NextToken;
  End
   Else
  If current_symbol = SYM_UNKNOWN Then Begin
   temp_token := current_token;
    { Nombre littÇral }
   If (temp_token <> '') and (temp_token[1] >= '0') and (temp_token[1] <= '9') Then Begin
    If left_operand = 'ax' Then
     Emit('cmp ax, ' + temp_token)
    Else
     Emit('cmp al, ' + temp_token);
    NextToken;
   End
    Else
   If temp_token <> '' Then Begin
    { Variable }
    sym_index := FindSymbol(temp_token);
    If sym_index > 0 Then Begin
     Case symbol_table[sym_index]^.data_type of
      TYPE_INTEGER, TYPE_WORD:
       Begin
        If left_operand = 'ax' Then
         Emit('cmp ax, ' + symbol_table[sym_index]^.name)
        Else
        Begin
         Emit('mov bx, ' + symbol_table[sym_index]^.name);
         Emit('cmp al, bl');
        End;
       End;
      TYPE_BYTE, TYPE_CHAR:
       Begin
        If left_operand = 'al' Then
         Emit('cmp al, ' + symbol_table[sym_index]^.name)
        Else
        Begin
         Emit('mov bl, ' + symbol_table[sym_index]^.name);
         Emit('cmp ax, bx');
        End;
       End;
     Else
      Begin
       If left_operand = 'ax' Then
        Emit('cmp ax, ' + symbol_table[sym_index]^.name)
       Else
        Emit('cmp al, ' + symbol_table[sym_index]^.name);
      End;
     End;
    End
    Else
     Error('Variable non dÇclarÇe: ' + temp_token);
    NextToken;
   End;
   { GÇnÇrer le code conditionnel selon l'opÇrateur }
   Case comparison_op of
    SYM_EQUAL:
     Begin
      Emit('mov ax, 1');
      Emit('je COMP_TRUE_' + IntToStr(next_label_id));
      Emit('mov ax, 0');
      EmitLabel('COMP_TRUE_' + IntToStr(next_label_id));
      Inc(next_label_id);
     End;
    SYM_NOTEQUAL:
     Begin
      Emit('mov ax, 1');
      Emit('jne COMP_TRUE_' + IntToStr(next_label_id));
      Emit('mov ax, 0');
      EmitLabel('COMP_TRUE_' + IntToStr(next_label_id));
      Inc(next_label_id);
     End;
    SYM_LESS:
     Begin
      Emit('mov ax, 1');
      Emit('jl COMP_TRUE_' + IntToStr(next_label_id));
      Emit('mov ax, 0');
      EmitLabel('COMP_TRUE_' + IntToStr(next_label_id));
      Inc(next_label_id);
     End;
    SYM_GREATER:
     Begin
      Emit('mov ax, 1');
      Emit('jg COMP_TRUE_' + IntToStr(next_label_id));
      Emit('mov ax, 0');
      EmitLabel('COMP_TRUE_' + IntToStr(next_label_id));
      Inc(next_label_id);
     End;
    SYM_LESSEQ:
     Begin
      Emit('mov ax, 1');
      Emit('jle COMP_TRUE_' + IntToStr(next_label_id));
      Emit('mov ax, 0');
      EmitLabel('COMP_TRUE_' + IntToStr(next_label_id));
      Inc(next_label_id);
     End;
    SYM_GREATEREQ:
     Begin
      Emit('mov ax, 1');
      Emit('jge COMP_TRUE_' + IntToStr(next_label_id));
      Emit('mov ax, 0');
      EmitLabel('COMP_TRUE_' + IntToStr(next_label_id));
      Inc(next_label_id);
     End;
   End;
  End;
 End;
End;

 { Analyser une instruction d'affectation }
Procedure ParseAssignment(var_name: String);
Var
 sym_index: Integer;
 string_temp: String;
 is_string_assignment: Boolean;
Begin
 sym_index := FindSymbol(var_name);
 If sym_index = 0 Then Begin
  Error('Variable non dÇclarÇe: ' + var_name);
  NextToken; { Consommer le token pour Çviter la boucle infinie }
  Exit;
 End;
  { Refuser l'affectation Ö une constante }
 If symbol_table[sym_index]^.symbol_type = SYM_CONST Then Begin
  Error('Impossible d''affecter une valeur Ö la constante: ' + var_name);
  NextToken;
  Exit;
 End;
  { Attendre := }
 NextToken; { Consommer l'identificateur de variable }
 If current_token = ':=' Then Begin
  NextToken; { Consommer := }
   { VÇrifier si c'est une affectation de chaåne littÇrale }
  is_string_assignment := False;
  If (symbol_table[sym_index]^.data_type = TYPE_STRING) Then Begin
   { Pour une variable string, vÇrifier si on a une chaåne littÇrale en cours }
   string_temp := current_token;
   { ConsidÇrer que c'est une chaåne littÇrale si ce n'est pas un nombre }
   If (Length(string_temp) > 0) and
      not ((string_temp[1] >= '0') and (string_temp[1] <= '9')) Then
   Begin
    is_string_assignment := True;
   End;
  End;
  If is_string_assignment Then Begin
    { Affectation de chaåne littÇrale }
   EmitComment('Affectation chaåne: ' + var_name + ' := ''' + string_temp + '''');
    { Entreposer la longueur d'abord (format Pascal) }
   Emit('mov al, ' + IntToStr(Length(string_temp)));
   Emit('mov ' + symbol_table[sym_index]^.name + ', al');
    { Copier les caractäres si la chaåne n'est pas vide }
   If Length(string_temp) > 0 Then Begin
    { GÇnÇrer la chaåne constante dans le segment de donnÇes }
    If not data_segment Then Begin
     EmitLine('.DATA');
     data_segment := True;
    End;
    EmitLine('STR_CONST' + IntToStr(next_label_id) + ' DB ''' + string_temp + '''');
     { Retour au segment de code }
    If not code_segment Then BeginCodeSection;
     { Copier les caractäres }
    Emit('mov si, OFFSET STR_CONST' + IntToStr(next_label_id));
    Emit('mov di, OFFSET ' + symbol_table[sym_index]^.name + '+1');
    Emit('mov cx, ' + IntToStr(Length(string_temp)));
    Emit('rep movsb');
    Inc(next_label_id);
   End;
   NextToken; { Consommer la chaåne }
  End
   Else
  Begin
   ParseExpression;
    { VÇrifier si c'est une affectation au rÇsultat d'une fonction }
   If symbol_table[sym_index]^.is_function and (symbol_table[sym_index]^.name = current_function_name) Then Begin
     { Affectation au rÇsultat de la fonction }
    EmitComment('Affectation rÇsultat fonction: ' + var_name);
    Case symbol_table[sym_index]^.return_type of
     TYPE_INTEGER, TYPE_WORD:
      Begin
       Emit('mov [bp-2], ax');  { Entreposer le rÇsultat dans l'espace local }
      End;
     TYPE_BYTE, TYPE_CHAR:
      Begin
       Emit('mov [bp-2], al');
      End;
     TYPE_STRING:
      Begin
       { Pour les chaånes, copier depuis SI vers l'espace local }
       Emit('mov di, [bp-2]');
       Emit('call COPY_STR');
      End;
    Else
     Begin
      Emit('mov [bp-2], ax');
     End;
    End;
   End
   Else
   Begin
    { GÇnÇrer le code d'affectation normal }
    Case symbol_table[sym_index]^.data_type of
     TYPE_INTEGER, TYPE_WORD: Emit('mov ' + symbol_table[sym_index]^.name + ', ax');
     TYPE_BYTE, TYPE_CHAR: Emit('mov ' + symbol_table[sym_index]^.name + ', al');
     TYPE_STRING:
      Begin
       EmitComment('Copie de chaåne');
       Emit('mov di, OFFSET ' + symbol_table[sym_index]^.name);
       Emit('call COPY_STR'); { SI -> DI }
      End;
    Else
     Emit('mov ' + symbol_table[sym_index]^.name + ', ax');
    End;
   End;
  End;
 End
 Else
 Begin
  Error('Attendu := pour l''affectation, trouvÇ: ' + current_token);
  NextToken; { Consommer le token erronÇ pour Çviter la boucle infinie }
 End;
End;

 { Analyser une instruction WRITE (sans saut de ligne) }
Procedure ParseWrite;
Var
 i, sym_index: Integer;
 is_string: Boolean;
 var_name: String;
Begin
 NextToken; { Consommer WRITE }
 If current_token = '(' Then Begin
  NextToken;
   { Traitement des paramätres multiples sÇparÇs par des virgules }
  Repeat
   is_string := False;
    { VÇrifier si c'est une chaåne littÇrale (entre guillemets) }
   If (current_symbol = SYM_STRING_LITERAL) or
      ((current_symbol = SYM_UNKNOWN) and (Length(current_token) > 0) and
       (Pos('''', current_line) > 0)) Then
   Begin
    { Chaåne littÇrale }
    is_string := True;
    EmitComment('Affichage chaåne (Write): ' + current_token);
     { Optimisation: utiliser l'interruption DOS 09h pour les chaånes }
    If Length(current_token) > 0 Then Begin
     { GÇnÇrer une Çtiquette de donnÇes pour la chaåne }
     If not data_segment Then Begin
      EmitLine('.DATA');
      data_segment := True;
     End;
     EmitLine('STR' + IntToStr(next_label_id) + ' DB ''' + current_token + '$''');
      { Retour au segment de code }
     If not code_segment Then BeginCodeSection;
      { Afficher la chaåne avec DOS function 09h }
     Emit('mov dx, OFFSET STR' + IntToStr(next_label_id));
     Emit('mov ah, 09h');
     Emit('int 21h');
     Inc(next_label_id);
    End;
    NextToken;
   End
    Else
   If (current_symbol = SYM_UNKNOWN) and (current_token <> '') Then Begin
    { VÇrifier si c'est un nombre ou une variable }
    If (current_token[1] >= '0') and (current_token[1] <= '9') Then Begin
     { Nombre littÇral }
     EmitComment('Affichage nombre (Write): ' + current_token);
     Emit('mov ax, ' + current_token);
     Emit('call PRINT_NUM');
    End
     Else
    Begin
     { Variable - vÇrifier dans la table des symboles }
     var_name := current_token;
     sym_index := FindSymbol(var_name);
     If sym_index > 0 Then Begin
      { Constante : êmettre la valeur immÇdiate }
      If symbol_table[sym_index]^.symbol_type = SYM_CONST Then Begin
       EmitComment('Affichage constante (Write): ' + var_name);
       Case symbol_table[sym_index]^.data_type of
        TYPE_STRING:
         Begin
          Emit('mov si, OFFSET ' + UpperCase(var_name) + '_STR');
          Emit('call PRINT_STR');
         End;
        TYPE_BOOLEAN:
         Begin
          If symbol_table[sym_index]^.value <> 0 Then
           Emit('mov dx, OFFSET TRUE_STR')
          Else
           Emit('mov dx, OFFSET FALSE_STR');
          Emit('mov ah, 09h');
          Emit('int 21h');
         End;
       Else
        Begin
         Emit('mov ax, ' + IntToStr(symbol_table[sym_index]^.value));
         Emit('call PRINT_NUM');
        End;
       End;
      End
       Else
      Begin
       EmitComment('Affichage variable (Write): ' + var_name);
       Case symbol_table[sym_index]^.data_type of
        TYPE_INTEGER, TYPE_WORD:
        Begin
         Emit('mov ax, ' + symbol_table[sym_index]^.name);
         Emit('call PRINT_NUM');
        End;
       TYPE_BYTE:
        Begin
         Emit('mov al, ' + symbol_table[sym_index]^.name);
         Emit('mov ah, 0');
         Emit('call PRINT_NUM');
        End;
       TYPE_CHAR:
        Begin
         Emit('mov dl, ' + symbol_table[sym_index]^.name);
         Emit('mov ah, 02h');
         Emit('int 21h');
        End;
       TYPE_STRING:
        Begin
         EmitComment('Affichage variable chaåne (Write): ' + var_name);
         Emit('mov si, OFFSET ' + symbol_table[sym_index]^.name);
         Emit('call PRINT_STR');
        End;
       TYPE_BOOLEAN:
        Begin
         Emit('mov al, ' + symbol_table[sym_index]^.name);
         Emit('cmp al, 0');
         Emit('je FALSE_' + IntToStr(next_label_id));
         Emit('mov dx, OFFSET TRUE_STR');
         Emit('jmp BOOL_END_' + IntToStr(next_label_id));
         EmitLabel('FALSE_' + IntToStr(next_label_id));
         Emit('mov dx, OFFSET FALSE_STR');
         EmitLabel('BOOL_END_' + IntToStr(next_label_id));
         Emit('mov ah, 09h');
         Emit('int 21h');
         Inc(next_label_id);
        End;
      Else
       Begin
        Emit('mov ax, ' + symbol_table[sym_index]^.name);
        Emit('call PRINT_NUM');
       End;
      End; { Case data_type }
      End; { Else variable normale }
     End { If sym_index > 0 }
      Else
     Begin
      Error('Variable non dÇclarÇe: ' + var_name);
     End;
    End;
    NextToken;
   End;
    { VÇrifier s'il y a d'autres paramätres }
   If current_token = ',' Then Begin
    NextToken;
    Continue; { Traiter le paramätre suivant }
   End
    Else
   Break; { Fin des paramätres }
  Until False;
  If current_token = ')' Then NextToken
                         Else Error('Attendu ) apräs les paramätres de Write');
 End;
  { Pas de saut de ligne pour WRITE (contrairement Ö WRITELN) }
End;

 { Analyser une instruction WRITELN }
Procedure ParseWriteln;
Var
 i, sym_index: Integer;
 is_string: Boolean;
 var_name: String;
Begin
 NextToken; { Consommer WRITELN }
 If current_token = '(' Then Begin
  NextToken;
   { Traitement des paramätres multiples sÇparÇs par des virgules }
  Repeat
   is_string := False;
    { VÇrifier si c'est une chaåne littÇrale - dÇtection amÇliorÇe }
   If (current_symbol = SYM_STRING_LITERAL) or
      ((current_symbol = SYM_UNKNOWN) and (Length(current_token) > 0) and
       (Length(current_line) > 0) and (line_pos > 1) and
       (current_line[line_pos-Length(current_token)-1] = '''')) Then
   Begin
    { Chaåne littÇrale }
    is_string := True;
    EmitComment('Affichage chaåne: ' + current_token);
     { Optimisation: utiliser l'interruption DOS 09h pour les chaånes }
    If Length(current_token) > 0 Then Begin
     { GÇnÇrer une Çtiquette de donnÇes pour la chaåne }
     If not data_segment Then Begin
      EmitLine('.DATA');
      data_segment := True;
     End;
     EmitLine('STR' + IntToStr(next_label_id) + ' DB ''' + current_token + '$''');
      { Retour au segment de code }
     If not code_segment Then BeginCodeSection;
      { Afficher la chaåne avec DOS function 09h }
     Emit('mov dx, OFFSET STR' + IntToStr(next_label_id));
     Emit('mov ah, 09h');
     Emit('int 21h');
     Inc(next_label_id);
    End;
    NextToken;
   End
    Else
   If (current_symbol = SYM_UNKNOWN) and (current_token <> '') Then Begin
    { VÇrifier si c'est un nombre ou une variable }
    If (current_token[1] >= '0') and (current_token[1] <= '9') Then Begin
     { Nombre littÇral }
      EmitComment('Affichage nombre: ' + current_token);
      Emit('mov ax, ' + current_token);
      Emit('call PRINT_NUM');
    End
     Else
    Begin
     { Variable - vÇrifier dans la table des symboles }
     var_name := current_token;
     sym_index := FindSymbol(var_name);
     If sym_index > 0 Then Begin
      { Constante : êmettre la valeur immÇdiate }
      If symbol_table[sym_index]^.symbol_type = SYM_CONST Then Begin
       EmitComment('Affichage constante: ' + var_name);
       Case symbol_table[sym_index]^.data_type of
        TYPE_STRING:
         Begin
          Emit('mov si, OFFSET ' + UpperCase(var_name) + '_STR');
          Emit('call PRINT_STR');
         End;
        TYPE_BOOLEAN:
         Begin
          If symbol_table[sym_index]^.value <> 0 Then
           Emit('mov dx, OFFSET TRUE_STR')
          Else
           Emit('mov dx, OFFSET FALSE_STR');
          Emit('mov ah, 09h');
          Emit('int 21h');
         End;
       Else
        Begin
         Emit('mov ax, ' + IntToStr(symbol_table[sym_index]^.value));
         Emit('call PRINT_NUM');
        End;
       End;
      End
      Else
      Begin
       EmitComment('Affichage variable: ' + var_name);
       Case symbol_table[sym_index]^.data_type of
        TYPE_INTEGER, TYPE_WORD:
        Begin
         Emit('mov ax, ' + symbol_table[sym_index]^.name);
         Emit('call PRINT_NUM');
        End;
       TYPE_BYTE:
        Begin
         Emit('mov al, ' + symbol_table[sym_index]^.name);
         Emit('mov ah, 0');
         Emit('call PRINT_NUM');
        End;
       TYPE_CHAR:
        Begin
         Emit('mov dl, ' + symbol_table[sym_index]^.name);
         Emit('mov ah, 02h');
         Emit('int 21h');
        End;
       TYPE_STRING:
        Begin
         EmitComment('Affichage variable cha√Æne: ' + var_name);
         Emit('mov si, OFFSET ' + symbol_table[sym_index]^.name);
         Emit('call PRINT_STR');
        End;
       TYPE_BOOLEAN:
        Begin
         Emit('mov al, ' + symbol_table[sym_index]^.name);
         Emit('cmp al, 0');
         Emit('je FALSE_' + IntToStr(next_label_id));
         Emit('mov dx, OFFSET TRUE_STR');
         Emit('jmp BOOL_END_' + IntToStr(next_label_id));
         EmitLabel('FALSE_' + IntToStr(next_label_id));
         Emit('mov dx, OFFSET FALSE_STR');
         EmitLabel('BOOL_END_' + IntToStr(next_label_id));
         Emit('mov ah, 09h');
         Emit('int 21h');
         Inc(next_label_id);
        End;
      Else
       Begin
        Emit('mov ax, ' + symbol_table[sym_index]^.name);
        Emit('call PRINT_NUM');
       End;
      End; { Case data_type }
      End; { Else variable normale }
     End { If sym_index > 0 }
      Else
     Begin
      { Traiter comme chaåne littÇrale si non trouvÇ }
      EmitComment('Affichage chaåne: ' + current_token);
      If not data_segment Then Begin
       EmitLine('.DATA');
       data_segment := True;
      End;
      EmitLine('STR' + IntToStr(next_label_id) + ' DB ''' + current_token + '$''');
      If not code_segment Then BeginCodeSection;
      Emit('mov dx, OFFSET STR' + IntToStr(next_label_id));
      Emit('mov ah, 09h');
      Emit('int 21h');
      Inc(next_label_id);
     End;
    End;
    NextToken;
   End;
    { VÇrifier s'il y a d'autres paramätres }
   If current_token = ',' Then Begin
    NextToken;
    Continue; { Traiter le paramätre suivant }
   End
    Else
   Break; { Fin des paramätres }
  Until False;
  If current_token = ')'Then NextToken
                        Else Error('Attendu ) apräs les paramätres de WriteLn');
 End;
  { GÇnÇrer saut de ligne pour WRITELN }
 Emit('mov dl, 13');
 Emit('mov ah, 02h');
 Emit('int 21h');
 Emit('mov dl, 10');
 Emit('mov ah, 02h');
 Emit('int 21h');
End;

{ Analyser une instruction IF }
Procedure ParseIf;
Var
 else_label, end_label: String;
Begin
 NextToken; { Consommer IF }
 ParseExpression;
 Expect(SYM_THEN, 'Attendu THEN apräs IF');
  { GÇnÇrer le code de test }
 else_label := NewLabel;
 end_label := NewLabel;
 Emit('cmp ax, 0');
 Emit('je ' + else_label);
 ParseStatement;
 If Accept(SYM_ELSE) Then Begin
  NextToken;
  Emit('jmp ' + end_label);
  EmitLabel(else_label);
  ParseStatement;
  EmitLabel(end_label);
 End
  Else
 EmitLabel(else_label);
End;

 { Analyser une instruction REPEAT }
Procedure ParseRepeat;
Var
 start_label: String;
Begin
 NextToken; { Consommer REPEAT }
 start_label := NewLabel;
 EmitLabel(start_label);
  { Analyser le corps de la boucle }
 While not Accept(SYM_UNTIL) and (current_char <> #0) do Begin
  ParseStatement;
   { GÇrer les point-virgules optionnels }
  If current_token = ';' Then NextToken;
 End;
  { Traiter UNTIL }
 If Accept(SYM_UNTIL) Then Begin
  NextToken; { Consommer UNTIL }
  ParseExpression;
  { GÇnÇrer le code de test - condition inversÇe par rapport Ö WHILE }
  Emit('cmp ax, 0');
  Emit('je ' + start_label); { Sauter au dÇbut si condition FAUSSE }
 End
  Else
 Error('Attendu UNTIL apräs REPEAT');
End;

 { Analyser une instruction WHILE }
Procedure ParseWhile;
Var
 start_label, end_label: String;
Begin
 NextToken; { Consommer WHILE }
 start_label := NewLabel;
 end_label := NewLabel;
 EmitLabel(start_label);
 ParseExpression;
 Expect(SYM_DO, 'Attendu DO apr√®s WHILE');
 Emit('cmp ax, 0');
 Emit('je ' + end_label);
 ParseStatement;
 Emit('jmp ' + start_label);
 EmitLabel(end_label);
End;

 { Analyser une boucle FOR }
Procedure ParseFor;
Var
 start_label, end_label, increment_label: String;
 var_name: String;
 is_downto: Boolean;
 sym_idx: Integer;
Begin
 NextToken; { Consommer FOR }
  { Lire la variable de contrìle }
 If current_symbol = SYM_UNKNOWN Then Begin
  var_name := current_token;
  sym_idx := FindSymbol(var_name);
  If sym_idx <= 0 Then
   Error('Variable de contrìle non dÇclarÇe: ' + var_name);
  NextToken;
 End
  Else
 Error('Attendu nom de variable apr√®s FOR');
  { Attendre := }
 If current_token = ':=' Then NextToken
                         Else Error('Attendu := apräs nom de variable');
  { Analyser l'expression de dÇpart }
 ParseExpression;
 Emit('mov [' + var_name + '], ax'); { Entreposer valeur initiale }
  { VÇrifier TO ou DOWNTO }
 If current_symbol = SYM_TO Then Begin
  is_downto := False;
  NextToken;
 End
  Else
 If current_symbol = SYM_DOWNTO Then Begin
  is_downto := True;
  NextToken;
 End
  Else
 Error('Attendu TO ou DOWNTO dans boucle FOR');
  { Analyser l'expression de fin }
 ParseExpression;
 Emit('mov bx, ax'); { Entreposer valeur finale dans BX }
  { Attendre DO }
 Expect(SYM_DO, 'Attendu DO apräs expression finale');
  { GÇnÇrer les Çtiquettes }
 start_label := NewLabel;
 increment_label := NewLabel;
 end_label := NewLabel;
  { DÇbut de la boucle }
 EmitLabel(start_label);
  { Comparer la variable de contrìle avec la valeur finale }
 Emit('mov ax, [' + var_name + ']');
 Emit('cmp ax, bx');
 If is_downto Then Emit('jl ' + end_label) { Si var < limite_finale, sortir }
              Else Emit('jg ' + end_label); { Si var > limite_finale, sortir }
  { ExÇcuter le corps de la boucle }
 ParseStatement;
 { IncrÇmenter ou dÇcrÇmenter la variable de contrìle }
 EmitLabel(increment_label);
 Emit('mov ax, [' + var_name + ']');
 If is_downto Then Emit('dec ax')
              Else Emit('inc ax');
 Emit('mov [' + var_name + '], ax');
  { Retourner au dÇbut }
 Emit('jmp ' + start_label);
 EmitLabel(end_label);
End;

 { Analyser une instruction CASE }
Procedure ParseCase;
Var
 end_label, else_label, case_label: String;
 case_value: Integer;
Begin
 NextToken; { Consommer CASE }
  { Analyser l'expression de sÇlection }
 ParseExpression;
 Emit('mov bx, ax'); { Entreposer la valeur du case dans BX }
  { Attendre OF }
 Expect(SYM_OF, 'Attendu OF apräs expression CASE');
  { GÇnÇrer les Çtiquettes }
 end_label := NewLabel;
 else_label := NewLabel;
  { Analyser chaque cas }
 While (current_symbol <> SYM_END) and (current_symbol <> SYM_ELSE) and
       (current_symbol <> SYM_OTHERWISE) and (current_char <> #0) do Begin
   { Lire la valeur du cas - c'est un nombre }
  If current_symbol = SYM_UNKNOWN Then Begin
   { VÇrifier si c'est un nombre }
   If (current_token <> '') and (current_token[1] >= '0') and (current_token[1] <= '9') Then Begin
    case_value := current_value;
    NextToken;
     { Attendre : }
    If current_token = ':' Then
     NextToken
    Else
     Error('Attendu : apräs valeur de cas');
     { GÇnÇrer l'Çtiquette pour ce cas }
    case_label := NewLabel;
     { Tester la valeur }
    Emit('cmp bx, ' + IntToStr(case_value));
    Emit('je ' + case_label);
     { Analyser l'instruction }
    EmitLabel(case_label);
    ParseStatement;
     { Saut vers la fin apräs exÇcution du cas }
    Emit('jmp ' + end_label);
     { Point-virgule optionnel }
    If current_token = ';' Then NextToken;
   End
   Else
    NextToken; { Ignorer token non-numÇrique }
  End
   Else
  NextToken; { Ignorer autres symboles }
 End;
  { Si aucun cas n'a de correspondance, aller au ELSE }
 Emit('jmp ' + else_label);
  { GÇrer ELSE ou OTHERWISE }
 If Accept(SYM_ELSE) or Accept(SYM_OTHERWISE) Then Begin
  NextToken; { Consommer ELSE/OTHERWISE }
  EmitLabel(else_label);
  ParseStatement;
   { Point-virgule optionnel apräs ELSE }
  If current_token = ';' Then NextToken;
 End
  Else
 Begin
   { Pas d'ELSE - juste une Çtiquette vide }
  EmitLabel(else_label);
 End;
  { Attendre END }
 Expect(SYM_END, 'Attendu END pour fermer CASE');
  { êtiquette de fin }
 EmitLabel(end_label);
End;

 { Analyser une instruction }
Procedure ParseStatement;
Var
 sym_idx: Integer;
 label_name: String;
Begin
 Case current_symbol of
  SYM_BEGIN:
   Begin
    NextToken; { Consommer BEGIN }
    While not Accept(SYM_END) and (current_char <> #0) do Begin
     If current_symbol <> SYM_UNKNOWN Then
      ParseStatement
     Else
      { Laisser ParseStatement gÇrer les tokens SYM_UNKNOWN pour les labels et affectations }
      ParseStatement;
     { GÇrer les point-virgules optionnels }
     If current_token = ';' Then NextToken;
    End;
    If Accept(SYM_END) Then
     NextToken { Consommer END }
    Else
     Error('Attendu END');
   End;
  SYM_IF:
   ParseIf;
  SYM_WHILE:
   ParseWhile;
  SYM_FOR:
   ParseFor;
  SYM_CASE:
   ParseCase;
  SYM_REPEAT:
   ParseRepeat;
  SYM_WRITE:
   ParseWrite;
  SYM_WRITELN:
   ParseWriteln;
  SYM_GOTO:
   ParseGoto;
  SYM_READ:
   Begin
    { READ: consomme les paramätres, gÇnäre lecture DOS 21h }
    NextToken; { Consommer READ }
    If current_token = '(' Then Begin
     NextToken; { Consommer ( }
     While (current_token <> ')') and (current_char <> #0) do NextToken;
     If current_token = ')' Then NextToken;
    End;
   End;
  SYM_READLN:
   Begin
    { READLN: consomme les paramätres, gÇnäre lecture avec retour chariot }
    NextToken; { Consommer READLN }
    If current_token = '(' Then Begin
     NextToken; { Consommer ( }
      { Ignorer tous les paramätres }
     While (current_token <> ')') and (current_char <> #0) do NextToken;
     If current_token = ')' Then NextToken;
    End;
    { GÇnäre un CRLF minimal (lecture ignorÇe cìtÇ 8086) }
   End;
  SYM_HALT:
   Begin
    NextToken; { Consommer HALT }
    { Argument optionnel (code de retour) }
    If current_token = '(' Then
    Begin
     NextToken; { Consommer ( }
     While (current_token <> ')') and (current_char <> #0) do
      NextToken;
     If current_token = ')' Then NextToken;
    End;
    If not code_segment Then BeginCodeSection;
    Emit('mov ax, 4C00h');
    Emit('int 21h');
   End;
  SYM_UNKNOWN:
   Begin
    If current_token <> '' Then Begin
     { VÇrifier d'abord si c'est un appel de procÇdure }
     sym_idx := FindSymbol(current_token);
     If (sym_idx > 0) and (symbol_table[sym_idx]^.symbol_type = SYM_PROCEDURE) Then Begin
      { Appel de procÇdure }
      EmitComment('Appel procÇdure: ' + current_token);
      NextToken; { Consommer le nom de la procÇdure }

      { GÇrer les paramätres (pour l'instant, on ignore) }
      If current_token = '(' Then Begin
       NextToken;
       While (current_token <> ')') and (current_char <> #0) do
        NextToken;
       If current_token = ')' Then
        NextToken;
      End;
       { GÇnÇrer l'appel }
      Emit('call ' + symbol_table[sym_idx]^.name);
     End
      Else
     If (sym_idx > 0) and (symbol_table[sym_idx]^.symbol_type = SYM_INTERRUPT) Then Begin
      { Appel d'interruption }
      EmitComment('Appel interruption: ' + current_token);
      NextToken; { Consommer le nom de l'interruption }
       { GÇrer les paramätres (pour l'instant, on ignore) }
      If current_token = '(' Then Begin
       NextToken;
       While (current_token <> ')') and (current_char <> #0) do NextToken;
       If current_token = ')' Then NextToken;
      End;
       { GÇnÇrer l'appel }
      Emit('call ' + symbol_table[sym_idx]^.name);
     End
      { Peut-àtre une affectation }
      Else
     If sym_idx > 0 Then Begin
      ParseAssignment(current_token); { ParseAssignment gÇrera NextToken }
     End
     { VÇrifier si c'est une Çtiquette suivie de ':' }
      Else
     If current_token <> '' Then Begin
       { DEBUG: Information sur le token courant }
      EmitComment('DEBUG: Token = [' + current_token + ']');
      { Sauvegarder le nom potentiel de l'Çtiquette }
      label_name := current_token;
      NextToken; { Lire le jeton suivant }
      { DEBUG: Information sur le jeton suivant }
      EmitComment('DEBUG: Token suivant = [' + current_token + ']');
       { Si le jeton suivant est ':', c'est une dÇfinition d'Çtiquette }
      If current_token = ':' Then Begin
       { C'est une dÇfinition d'Çtiquette }
       EmitComment('êtiquette dÇfinie: ' + label_name);
       EmitLabel(UpperCase(label_name) + '_LABEL');
        { Marquer l'Çtiquette comme dÇfinie dans la table }
       sym_idx := FindLabel(UpperCase(label_name));
       If sym_idx > 0 Then label_table[sym_idx]^.defined := True;
       NextToken; { Consommer ':' }
      End;
      { Si ce n'est pas ':', on a dÇjÖ consommÇ le jeton, continuer }
     End
      Else
     NextToken;
    End
     Else
    NextToken;
   End;
    Else
   NextToken; { Ignorer les autres jetons }
 End;
End;

 { Analyser les dÇclarations de constantes }
Procedure ParseConstDeclarations;
Var
 const_name: String;
 const_val_str: String;
 const_val: Integer;
 const_type: Integer;
 is_negative: Boolean;
 sym_index: Integer;
 code_val: Integer;
Begin
 NextToken; { Consommer CONST }
 While (current_symbol = SYM_UNKNOWN) and (current_token <> '') do Begin
  const_name := current_token;
  NextToken; { Consommer le nom }
   { Attendre le = }
  If current_token <> '=' Then Begin
   Error('Attendu = apräs nom de constante: ' + const_name);
   Break;
  End;
  NextToken; { Consommer = }
  { Lire la valeur }
  is_negative := False;
  If current_token = '-' Then Begin
   is_negative := True;
   NextToken; { Consommer le signe moins }
  End;
  const_val := 0;
  const_type := TYPE_INTEGER;
  const_val_str := '';
   { VÇrifier d'abord si c'est une chaåne entre guillemets simples }
  If current_symbol = SYM_STRING_LITERAL Then Begin
   { Constante entre guillemets simples }
   const_val_str := current_token;
   If Length(const_val_str) = 1 Then Begin
    { Caractäre unique : TYPE_CHAR }
    const_val := Ord(const_val_str[1]);
    const_type := TYPE_CHAR;
   End
    Else
   Begin
    { Chaåne de plusieurs caractäres : êmettre dans .DATA }
    const_type := TYPE_STRING;
    If data_segment Then EmitLine(UpperCase(const_name) + '_STR DB ''' + const_val_str + ''', 0')
     Else
    Begin
     EmitLine('.DATA');
     data_segment := True;
     EmitLine(UpperCase(const_name) + '_STR DB ''' + const_val_str + ''', 0');
    End;
    const_val := 0;
   End;
   NextToken;
  End
   Else
  If UpperCase(current_token) = 'TRUE' Then Begin
   const_val := 1;
   const_type := TYPE_BOOLEAN;
   NextToken;
  End
   Else
  If UpperCase(current_token) = 'FALSE' Then Begin
   const_val := 0;
   const_type := TYPE_BOOLEAN;
   NextToken;
  End
   Else
  If (Length(current_token) = 1) and
     ((current_token[1] >= '0') and (current_token[1] <= '9') or
      (current_token[1] = '$')) Then Begin
   { Nombre dÇcimal ou hexadÇcimal }
   Val(current_token, const_val, code_val);
   If code_val <> 0 Then Begin
    Warning('Valeur numÇrique invalide pour la constante: ' + const_name + ', assumÇ 0');
    const_val := 0;
   End;
   If is_negative Then const_val := -const_val;
   const_type := TYPE_INTEGER;
   NextToken;
  End
   Else
  If (Length(current_token) > 1) and
     (current_token[1] >= '0') and (current_token[1] <= '9') Then Begin
   { Nombre Ö plusieurs chiffres }
   Val(current_token, const_val, code_val);
   If code_val <> 0 Then Begin
    Warning('Valeur numÇrique invalide pour la constante: ' + const_name + ', assumÇ 0');
    const_val := 0;
   End;
   If is_negative Then const_val := -const_val;
   const_type := TYPE_INTEGER;
   NextToken;
  End
   Else
  Begin
   { RÇfÇrencer un autre symbole CONST ou expression inconnue }
   sym_index := FindSymbol(current_token);
   If (sym_index > 0) and (symbol_table[sym_index]^.symbol_type = SYM_CONST) Then Begin
    const_val := symbol_table[sym_index]^.value;
    const_type := symbol_table[sym_index]^.data_type;
   End
    Else
   Begin
    Warning('Valeur de constante non reconnue: ' + current_token + ', assumÇ 0');
    const_val := 0;
    const_type := TYPE_INTEGER;
   End;
   NextToken;
  End;
   { Ajouter la constante Ö la table des symboles }
  sym_index := AddSymbol(const_name, SYM_CONST, const_type, STORAGE_GLOBAL);
  If sym_index > 0 Then Begin
   symbol_table[sym_index]^.value := const_val;
   { êmettre un commentaire dans le .ASM pour documenter la constante }
   If const_type = TYPE_STRING Then
    EmitComment('Constante: ' + UpperCase(const_name) + ' = ''' +
                const_val_str + ''' (label: ' + UpperCase(const_name) + '_STR)')
    Else
   If const_type = TYPE_BOOLEAN Then Begin
    If const_val <> 0 Then
     EmitComment('Constante: ' + UpperCase(const_name) + ' = TRUE')
    Else
     EmitComment('Constante: ' + UpperCase(const_name) + ' = FALSE');
   End
    Else
   If const_type = TYPE_CHAR Then
    EmitComment('Constante: ' + UpperCase(const_name) + ' = ''' + Chr(const_val) + '''')
   Else
    EmitComment('Constante: ' + UpperCase(const_name) + ' = ' + IntToStr(const_val));
  End;
  { Attendre ; }
  If current_token = ';' Then
   NextToken
  Else
   Error('Attendu ; apräs dÇclaration de constante');
 End;
End;

 { Analyser les dÇclarations de variables }
Procedure ParseVarDeclarations;
Var
 var_names: Array[1..50] of String;
 var_count: Integer;
 var_type: Integer;
 type_name: String;
 i, sym_index: Integer;
 string_size: Integer;   { Taille de STRING ou taille totale en octets (ARRAY) }
 const_idx: Integer;     { Index pour chercher une constante }
 array_low, array_high, array_elem_size: Integer; { Bornes et taille ÇlÇment du tableau }
Begin
 NextToken; { Consommer VAR }
 While (current_symbol = SYM_UNKNOWN) and (current_token <> '') do Begin
  { Lire les noms de variables }
  var_count := 0;
  Repeat
   If current_symbol = SYM_UNKNOWN Then
   Begin
    Inc(var_count);
    var_names[var_count] := current_token;
    NextToken;
   End
    Else
   Begin
    Error('Attendu nom de variable');
    Break;
   End;
   If current_token = ',' Then NextToken
                          Else Break;
  Until False;
   { Attendre le deux-points }
  If current_token = ':' Then NextToken
                         Else Error('Attendu : apräs nom de variable');
  { Lire le type }
  If Accept(SYM_ARRAY) Then Begin
    { Syntaxe: Array[low..high] of ElementType }
   NextToken; { Consommer ARRAY }
   array_low := 0;
   array_high := 0;
   array_elem_size := 2;
   If current_token = '[' Then Begin
    NextToken; { Consommer '[' }
     { Borne infÇrieure: nombre ou constante }
    If (current_token <> '') and (current_token[1] >= '0') and (current_token[1] <= '9') Then Begin
     array_low := current_value;
     NextToken;
    End
     Else
    If current_symbol = SYM_UNKNOWN Then Begin
     const_idx := FindSymbol(current_token);
     If (const_idx > 0) and (symbol_table[const_idx]^.symbol_type = SYM_CONST) Then
      array_low := symbol_table[const_idx]^.value
     Else
      Error('Borne infÇrieure invalide: ' + current_token);
     NextToken;
    End
    Else
     Error('Attendu borne infÇrieure du tableau');
     { Consommer '..' (deux SYM_DOT consÇcutifs) }
    If current_symbol = SYM_DOT Then NextToken;
    If current_symbol = SYM_DOT Then NextToken;
     { Borne supÇrieure: nombre ou constante }
    If (current_token <> '') and (current_token[1] >= '0') and (current_token[1] <= '9') Then Begin
     array_high := current_value;
     NextToken;
    End
     Else
    If current_symbol = SYM_UNKNOWN Then Begin
     const_idx := FindSymbol(current_token);
     If (const_idx > 0) and (symbol_table[const_idx]^.symbol_type = SYM_CONST) Then
      array_high := symbol_table[const_idx]^.value
     Else
      Error('Borne supÇrieure invalide: ' + current_token);
     NextToken;
    End
     Else
    Error('Attendu borne supÇrieure du tableau');
     { Consommer ']' }
    If current_token = ']' Then
     NextToken
    Else
     Error('Attendu ] apräs bornes du tableau');
   End
    Else
   Error('Attendu [ apräs ARRAY');
    { Consommer OF }
   If Accept(SYM_OF)Then NextToken
                    Else Error('Attendu OF apräs Array[...]');
    { Lire le type des ÇlÇments et dÇterminer sa taille }
   If current_symbol = SYM_UNKNOWN Then Begin
    type_name := UpperCase(current_token);
    If (type_name = 'INTEGER') or (type_name = 'WORD') Then array_elem_size := 2
    Else If (type_name = 'BYTE') or (type_name = 'CHAR') or (type_name = 'BOOLEAN') Then array_elem_size := 1
    Else If type_name = 'STRING' Then array_elem_size := 256
    Else If (type_name = 'TEXT') Then array_elem_size := 256
    Else If (type_name = 'FILE') Then array_elem_size := 128
    Else
    Begin
      { Pointeur ou type dÇfini par l'utilisateur = 2 octets sur 8086 }
     const_idx := FindSymbol(type_name);
     If (const_idx > 0) and (symbol_table[const_idx]^.symbol_type = SYM_TYPE) Then Begin
      Case symbol_table[const_idx]^.data_type of
       TYPE_BYTE, TYPE_CHAR, TYPE_BOOLEAN: array_elem_size := 1;
       TYPE_TEXT: array_elem_size := 256;
       TYPE_FILE: array_elem_size := 128;
      Else
       array_elem_size := 2;
      End;
     End
     Else
      array_elem_size := 2; { Par dÇfaut: mot 16 bits }
    End;
    NextToken;
   End
    Else
   Error('Attendu type d''ÇlÇment apräs OF');
   var_type := TYPE_ARRAY;
    { string_size contient le nombre total d'octets du tableau }
   string_size := (array_high - array_low + 1) * array_elem_size;
   If string_size <= 0 Then string_size := 2; { SÇcuritÇ }
  End
   Else
  If current_symbol = SYM_UNKNOWN Then Begin
   type_name := UpperCase(current_token);
   If type_name = 'INTEGER' Then var_type := TYPE_INTEGER
   Else If type_name = 'BYTE' Then var_type := TYPE_BYTE
   Else If type_name = 'WORD' Then var_type := TYPE_WORD
   Else If type_name = 'STRING' Then var_type := TYPE_STRING
   Else If type_name = 'CHAR' Then var_type := TYPE_CHAR
   Else If type_name = 'BOOLEAN' Then var_type := TYPE_BOOLEAN
   Else If type_name = 'TEXT' Then var_type := TYPE_TEXT
   Else If type_name = 'FILE' Then var_type := TYPE_FILE
    Else
   Begin
    { VÇrifier si c'est un type dÇfini par l'utilisateur }
    sym_index := FindSymbol(type_name);
    If (sym_index > 0) and (symbol_table[sym_index]^.symbol_type = SYM_TYPE) Then Begin
     { C'est un type dÇfini par l'utilisateur }
     var_type := symbol_table[sym_index]^.data_type;
    End
     Else
    Begin
     Error('Type inconnu: ' + type_name);
     var_type := TYPE_INTEGER;
    End;
   End;
   NextToken;
    { Analyser la taille optionnelle de STRING: String[255] ou String[MA_CONSTANTE] }
   string_size := 255; { Taille par dÇfaut }
   If (var_type = TYPE_STRING) and (current_token = '[') Then Begin
    NextToken; { Consommer '[' }
    If (current_token <> '') and (current_token[1] >= '0') and (current_token[1] <= '9') Then Begin
     { Taille numÇrique littÇrale }
     string_size := current_value;
     NextToken;
    End
     Else
    If current_symbol = SYM_UNKNOWN Then Begin
     { Taille dÇfinie par une constante }
     const_idx := FindSymbol(current_token);
     If (const_idx > 0) and (symbol_table[const_idx]^.symbol_type = SYM_CONST) Then
      string_size := symbol_table[const_idx]^.value
     Else
      Error('Taille de STRING invalide: ' + current_token);
     NextToken;
    End
     Else
     Error('Attendu taille numÇrique ou constante apräs String[');
    If current_token = ']' Then NextToken
                           Else Error('Attendu ] apräs taille de STRING');
   End;
  End
   Else
  Begin
   Error('Attendu type de variable');
   var_type := TYPE_INTEGER;
  End;
   { Ajouter les variables Ö la table des symboles }
  For i := 1 to var_count do Begin
   sym_index := AddSymbol(var_names[i], SYM_VAR, var_type, STORAGE_GLOBAL);
   If sym_index > 0 Then
    GenerateVariableDeclaration(var_names[i], var_type, string_size);
  End;
   { Attendre le point-virgule }
  If current_token = ';' Then NextToken
                         Else Error('Attendu ; apräs dÇclaration de variable');
 End;
End;

 { Analyser les dÇclarations de types }
Procedure ParseTypeDeclarations;
Var
 type_name: String;
 record_index: Integer;
 field_names: Array[1..50] of String;
 field_types: Array[1..50] of Integer;
 field_count: Integer;
 field_type: Integer;
 type_name_field: String;
 i: Integer;
 current_offset: Integer;
 sym_index: Integer;  { Variable manquante ajoutÇe }
 field_string_size: Integer; { Taille STRING du champ courant }
 const_idx: Integer;         { Index pour chercher une constante }
Begin
 NextToken; { Consommer TYPE }
 While (current_symbol = SYM_UNKNOWN) and (current_token <> '') do Begin
   { Lire le nom du type }
  If current_symbol = SYM_UNKNOWN Then Begin
   type_name := current_token;
   NextToken;
  End
   Else
  Begin
   Error('Attendu nom de type');
   Break;
  End;
   { Attendre le signe = }
  If current_token = '=' Then NextToken
                         Else Error('Attendu = apräs nom de type');
   { VÇrifier si c'est un RECORD }
  If Accept(SYM_RECORD) Then Begin
   NextToken; { Consommer RECORD }
    { CrÇer le type record dans la table des symboles }
   record_index := AddRecord(type_name, 0); { Taille calculÇe plus tard }
   current_offset := 0;
    { Lire les champs du record }
   While not Accept(SYM_END) and (current_char <> #0) do Begin
    { Lire les noms de champs }
    field_count := 0;
    Repeat
     If current_symbol = SYM_UNKNOWN Then Begin
      Inc(field_count);
      field_names[field_count] := current_token;
      NextToken;
     End
      Else
     Begin
      Error('Attendu nom de champ');
      Break;
     End;
     If current_token = ',' Then NextToken
                            Else Break;
    Until False;
     { Attendre le deux-points }
    If current_token = ':' Then NextToken
                           Else Error('Attendu : apräs nom de champ');
     { Lire le type du champ }
    If current_symbol = SYM_UNKNOWN Then Begin
     type_name_field := UpperCase(current_token);
     If type_name_field = 'INTEGER' Then field_type := TYPE_INTEGER
     Else If type_name_field = 'BYTE' Then field_type := TYPE_BYTE
     Else If type_name_field = 'WORD' Then field_type := TYPE_WORD
     Else If type_name_field = 'STRING' Then field_type := TYPE_STRING
     Else If type_name_field = 'CHAR' Then field_type := TYPE_CHAR
     Else If type_name_field = 'BOOLEAN' Then field_type := TYPE_BOOLEAN
     Else If type_name_field = 'TEXT' Then field_type := TYPE_TEXT
     Else If type_name_field = 'FILE' Then field_type := TYPE_FILE
      Else
     Begin
      Error('Type de champ inconnu: ' + type_name_field);
      field_type := TYPE_INTEGER;
     End;
     NextToken;
      { Analyser la taille optionnelle de STRING: String[255] ou String[MA_CONST] }
     field_string_size := 255; { Taille par d√©faut }
     If (field_type = TYPE_STRING) and (current_token = '[') Then Begin
      NextToken; { Consommer '[' }
      If (current_token <> '') and (current_token[1] >= '0') and (current_token[1] <= '9') Then Begin
       field_string_size := current_value;
       NextToken;
      End
       Else
      If current_symbol = SYM_UNKNOWN Then Begin
       const_idx := FindSymbol(current_token);
       If (const_idx > 0) and (symbol_table[const_idx]^.symbol_type = SYM_CONST) Then
        field_string_size := symbol_table[const_idx]^.value
       Else
        Error('Taille de STRING invalide: ' + current_token);
       NextToken;
      End
      Else
       Error('Attendu taille numÇrique ou constante apräs String[');
      If current_token = ']' Then
       NextToken
      Else
       Error('Attendu ] apräs taille de STRING');
     End;
    End
    Else
    Begin
     Error('Attendu type de champ');
     field_type := TYPE_INTEGER;
    End;
     { Ajouter les champs Ö la table des symboles }
    For i := 1 to field_count do Begin
     AddRecordField(field_names[i], field_type, record_index, current_offset);
      { Calculer le dÇplacement suivant }
     Case field_type of
      TYPE_INTEGER, TYPE_WORD: Inc(current_offset, 2);
      TYPE_BYTE, TYPE_CHAR, TYPE_BOOLEAN: Inc(current_offset, 1);
      TYPE_STRING: Inc(current_offset, field_string_size + 1);
      TYPE_TEXT: Inc(current_offset, 256);
      TYPE_FILE: Inc(current_offset, 128);
     Else
      Inc(current_offset, 2);
     End;
    End;
     { Attendre le point-virgule }
    If current_token = ';' Then
     NextToken
    Else If not Accept(SYM_END) Then
     Error('Attendu ; apräs dÇclaration de champ');
   End;
    { Consommer END }
   If Accept(SYM_END)Then NextToken
                     Else Error('Attendu END apräs dÇclaration de RECORD');
    { Mettre Ö jour la taille du record }
   If record_index > 0 Then symbol_table[record_index]^.record_size := current_offset;
  End
   { VÇrifier si c'est un type ARRAY }
   Else
  If Accept(SYM_ARRAY) Then Begin
   NextToken; { Consommer ARRAY }
    { Pour l'instant, on traite les arrays comme des types simples }
    { ImplÇmenter l'analyse complet des tableaux }
   While (current_token <> ';') and (current_char <> #0) do NextToken;
    { CrÇer un type array simple }
   AddSymbol(type_name, SYM_TYPE, TYPE_ARRAY, STORAGE_GLOBAL);
  End
   { VÇrifier si c'est un type POINTEUR : PType = ^AutreType }
   Else
  If current_token = '^' Then Begin
   NextToken; { Consommer '^' }
   { Lire le nom du type pointÇ }
   If current_symbol = SYM_UNKNOWN Then Begin
    { Enregistrer comme type pointeur - 2 octets sur 8086 }
    AddSymbol(type_name, SYM_TYPE, TYPE_POINTER, STORAGE_GLOBAL);
    NextToken; { Consommer le nom du type pointÇ }
   End
    Else
   Begin
    Error('Attendu nom de type apräs ^');
    AddSymbol(type_name, SYM_TYPE, TYPE_POINTER, STORAGE_GLOBAL);
   End;
  End
   Else
  Begin
    { Type alias - rÇfÇrence Ö un autre type }
   If current_symbol = SYM_UNKNOWN Then Begin
    type_name_field := UpperCase(current_token);
    If type_name_field = 'INTEGER' Then
     AddTypeAlias(type_name, TYPE_INTEGER)
    Else If type_name_field = 'BYTE' Then
     AddTypeAlias(type_name, TYPE_BYTE)
    Else If type_name_field = 'WORD' Then
     AddTypeAlias(type_name, TYPE_WORD)
    Else If type_name_field = 'STRING' Then
     AddTypeAlias(type_name, TYPE_STRING)
    Else If type_name_field = 'CHAR' Then
     AddTypeAlias(type_name, TYPE_CHAR)
    Else If type_name_field = 'BOOLEAN' Then
     AddTypeAlias(type_name, TYPE_BOOLEAN)
    Else If type_name_field = 'TEXT' Then
     AddTypeAlias(type_name, TYPE_TEXT)
    Else If type_name_field = 'FILE' Then
     AddTypeAlias(type_name, TYPE_FILE)
    Else
    Begin
     { VÇrifier si c'est une rÇfÇrence Ö un type dÇfini }
     sym_index := FindSymbol(type_name_field);
     If sym_index > 0 Then
      AddTypeAlias(type_name, symbol_table[sym_index]^.data_type)
      Else
     Begin
      Error('Type de rÇfÇrence inconnu: ' + type_name_field);
      AddTypeAlias(type_name, TYPE_INTEGER);
     End;
    End;
    NextToken;
   End
    Else
   Begin
    { Types simples non supportÇs pour l'instant }
    Error('Type non supportÇ');
    While (current_token <> ';') and (current_char <> #0) do NextToken;
   End;
  End;
   { Attendre le point-virgule final }
  If current_token = ';' Then NextToken
                         Else Error('Attendu ; apräs dÇclaration de type');
 End;
End;

 { Analyser une dÇclaration de fonction }
Procedure ParseFunctionDeclaration;
Var
 func_name: String;
 return_type: Integer;
 type_name: String;
 sym_index: Integer;
 begin_count: Integer;
Begin
 NextToken; { Consommer FUNCTION }
  { Lire le nom de la fonction }
 If current_symbol = SYM_UNKNOWN Then Begin
  func_name := current_token;
  NextToken;
 End
  Else
 Begin
  Error('Attendu nom de fonction');
  Exit;
 End;
  { Ignorer les paramätres pour l'instant }
 If current_token = '(' Then Begin
  NextToken;
  While (current_token <> ')') and (current_char <> #0) do NextToken;
  If current_token = ')' Then NextToken;
 End;
  { Attendre le deux-points pour le type de retour }
 If current_token = ':' Then NextToken
                        Else Error('Attendu : apräs nom de fonction');
  { Lire le type de retour }
 If current_symbol = SYM_UNKNOWN Then Begin
  type_name := UpperCase(current_token);
  If type_name = 'INTEGER' Then return_type := TYPE_INTEGER
  Else If type_name = 'BYTE' Then return_type := TYPE_BYTE
  Else If type_name = 'WORD' Then return_type := TYPE_WORD
  Else If type_name = 'STRING' Then return_type := TYPE_STRING
  Else If type_name = 'CHAR' Then return_type := TYPE_CHAR
  Else If type_name = 'BOOLEAN' Then return_type := TYPE_BOOLEAN
  Else
  Begin
   Error('Type de retour inconnu: ' + type_name);
   return_type := TYPE_INTEGER;
  End;
  NextToken;
 End
 Else
 Begin
  Error('Attendu type de retour');
  return_type := TYPE_INTEGER;
 End;
  { Consommer le point-virgule apräs le type de retour }
 If current_token = ';' Then NextToken
                        Else Error('Attendu ; apräs type de retour de fonction');
  { VÇrifier si c'est une dÇclaration FORWARD }
 If current_symbol = SYM_FORWARD Then Begin
  NextToken; { Consommer FORWARD }
   { Attendre le point-virgule final apräs FORWARD }
  If current_token = ';' Then NextToken
                         Else Error('Attendu ; apräs FORWARD');
   { Ajouter la fonction Ö la table des symboles avec is_forward := True }
  sym_index := AddFunction(func_name, return_type);
  If sym_index > 0 Then Begin
   symbol_table[sym_index]^.is_forward := True;
   symbol_table[sym_index]^.defined := False; { Corps absent jusqu'√† l'impl√©mentation }
  End;
   { Pas de corps Ö analyser pour FORWARD, terminer ici }
 End
  Else
 Begin
  { Traitement normal de la fonction - le ; est dÇjÖ consommÇ }
  { VÇrifier s'il y a une dÇclaration FORWARD existante }
  sym_index := FindSymbol(func_name);
  If sym_index > 0 Then Begin
   { VÇrifier si c'est une dÇclaration FORWARD }
   If symbol_table[sym_index]^.is_forward And
      (symbol_table[sym_index]^.symbol_type = SYM_FUNCTION) And
      (symbol_table[sym_index]^.data_type = return_type) Then
   Begin
    { Marquer comme implÇmentÇe }
    symbol_table[sym_index]^.is_forward := False;
    symbol_table[sym_index]^.defined := True;
   End
   Else
   Begin
    Error('RedÇfinition de fonction: ' + func_name);
    Exit;
   End;
  End
   Else
  Begin
   { Ajouter la fonction Ö la table des symboles }
   sym_index := AddFunction(func_name, return_type);
  End;
   { Configurer l'Çtat pour la fonction }
  current_function_name := UpperCase(func_name);
  current_function_type := return_type;
  in_function := True;
   { êmettre l'entàte de procÇdure assembleur }
  StartCodeSection; { Assurer .CODE sans MAIN PROC }
  EmitLine('');
  EmitLine(UpperCase(func_name) + ' PROC');
  EmitLine('    push bp');
  EmitLine('    mov bp, sp');
  EmitLine('');
   { Ignorer toute dÇclaration VAR locale }
  While Accept(SYM_VAR) do Begin
   NextToken; { Consommer VAR }
   { Ignorer jusqu'au prochain BEGIN }
   While (current_symbol <> SYM_BEGIN) and (current_char <> #0) do NextToken;
  End;
   { Parser le corps de la fonction - pour l'instant on l'ignore mais on compte les BEGIN/END }
   { Note: CASE...OF...END et RECORD...END comptent aussi comme blocs ouvrants }
  If Accept(SYM_BEGIN) Then Begin
   NextToken; { Consommer BEGIN }
   begin_count := 1;
   While (begin_count > 0) and (current_char <> #0) do Begin
    If Accept(SYM_BEGIN) or Accept(SYM_CASE) or Accept(SYM_RECORD) Then
     Inc(begin_count)
    Else If Accept(SYM_END) Then
     Dec(begin_count);
    NextToken;
   End;
  End;
   { Attendre le point-virgule final }
  If current_token = ';' Then NextToken;
   { êmettre l'Çpilogue de la fonction }
  EmitLine('');
  EmitLine('    pop bp');
  EmitLine('    ret');
  EmitLine(UpperCase(func_name) + ' ENDP');
   { RÇinitialiser l'Çtat }
  current_function_name := '';
  in_function := False;
 End;
End;

 { Analyser une dÇclaration de procÇdure }
Procedure ParseProcedureDeclaration;
Var
 proc_name: String;
 sym_index: Integer;
 begin_count: Integer;
 is_interrupt: Boolean;
Begin
 NextToken; { Consommer PROCEDURE }
 is_interrupt := False;
  { Lire le nom de la procÇdure }
 If current_symbol = SYM_UNKNOWN Then Begin
  proc_name := current_token;
  NextToken;
 End
  Else
 Begin
  Error('Attendu nom de procÇdure');
  Exit;
 End;
  { Ignorer les paramätres pour l'instant }
 If current_token = '(' Then Begin
  NextToken;
  While (current_token <> ')') and (current_char <> #0) do NextToken;
  If current_token = ')' Then NextToken;
 End;
  { VÇrifier si c'est une procÇdure d'interruption }
 If UpperCase(current_token) = 'INTERRUPT' Then Begin
  is_interrupt := True;
  NextToken; { Consommer INTERRUPT }
 End;
  { Consommer le point-virgule apräs la signature }
 If current_token = ';' Then
  NextToken
 Else
  Error('Attendu ; apr√®s signature de proc√©dure');
 { VÇrifier si c'est une dÇclaration FORWARD }
 If current_symbol = SYM_FORWARD Then Begin
  NextToken; { Consommer FORWARD }
   { Attendre le point-virgule final apräs FORWARD }
  If current_token = ';' Then NextToken
                         Else Error('Attendu ; apräs FORWARD');
   { Ajouter la procÇdure Ö la table des symboles avec is_forward := True }
  If is_interrupt Then sym_index := AddInterrupt(proc_name)
                  Else sym_index := AddProcedure(proc_name);
  If sym_index > 0 Then Begin
   symbol_table[sym_index]^.is_forward := True;
   symbol_table[sym_index]^.defined := False; { Corps absent jusqu'Ö l'implÇmentation }
  End;
   { Pas de corps Ö analyser pour FORWARD, terminer ici }
 End
  Else
 Begin
  { Traitement normal de la procÇdure - le ; est dÇjÖ consommÇ }
  { VÇrifier s'il y a une dÇclaration FORWARD existante }
  sym_index := FindSymbol(proc_name);
  If sym_index > 0 Then Begin
   { VÇrifier si c'est une dÇclaration FORWARD }
   If symbol_table[sym_index]^.is_forward And
      ((symbol_table[sym_index]^.symbol_type = SYM_PROCEDURE) Or
       (symbol_table[sym_index]^.symbol_type = SYM_INTERRUPT)) Then
   Begin
     { Marquer comme implÇmentÇe }
    symbol_table[sym_index]^.is_forward := False;
    symbol_table[sym_index]^.defined := True;
   End
    Else
   Begin
    Error('RedÇfinition de procÇdure: ' + proc_name);
    Exit;
   End;
  End
   Else
  Begin
   { Ajouter la procÇdure Ö la table des symboles }
   If is_interrupt Then sym_index := AddInterrupt(proc_name)
                   Else sym_index := AddProcedure(proc_name);
  End;
   { Configurer l'Çtat pour la procÇdure }
  current_function_name := UpperCase(proc_name);
  current_function_type := TYPE_INTEGER; { Pas utilisÇ }
  in_function := True; { Utilise le màme drapeau pour les procÇdures }

  { êmettre l'entàte de procÇdure assembleur }
  StartCodeSection; { Assurer .CODE sans MAIN PROC }
  EmitLine('');
  EmitLine(UpperCase(proc_name) + ' PROC');
  EmitLine('    push bp');
  EmitLine('    mov bp, sp');
  EmitLine('');
   { Ignorer toute dÇclaration VAR locale }
  While Accept(SYM_VAR) do Begin
   NextToken; { Consommer VAR }
    { Ignorer jusqu'au prochain BEGIN }
   While (current_symbol <> SYM_BEGIN) and (current_char <> #0) do
    NextToken;
  End;
   { Analyser le corps de la procÇdure - pour l'instant on l'ignore mais on compte les BEGIN/END }
  { Note: CASE...OF...END et RECORD...END comptent aussi comme blocs ouvrants }
  If Accept(SYM_BEGIN) Then Begin
   NextToken; { Consommer BEGIN }
   begin_count := 1;
   While (begin_count > 0) and (current_char <> #0) do Begin
    If Accept(SYM_BEGIN) or Accept(SYM_CASE) or Accept(SYM_RECORD) Then
     Inc(begin_count)
    Else If Accept(SYM_END) Then
     Dec(begin_count);
    NextToken;
   End;
  End;
   { Attendre le point-virgule final }
  If current_token = ';' Then
   NextToken;
  { êmettre l'Çpilogue de la procÇdure }
  EmitLine('');
  EmitLine('    pop bp');
  EmitLine('    ret');
  EmitLine(UpperCase(proc_name) + ' ENDP');
   { RÇinitialiser l'Çtat }
  current_function_name := '';
  in_function := False;
 End;
End;

 { Analyser un bloc Pascal }
Procedure ParseBlock;Begin
 { GÇrer les dÇclarations LABEL }
 If Accept(SYM_LABEL) Then ParseLabelDeclarations;
  { GÇrer les dÇclarations CONST }
 If Accept(SYM_CONST) Then ParseConstDeclarations;
  { GÇrer les d√©clarations TYPE }
 If Accept(SYM_TYPE) Then
  ParseTypeDeclarations;
 { GÇrer les dÇclarations VAR }
 If Accept(SYM_VAR) Then ParseVarDeclarations;
  { Premiäre passe: gÇrer les dÇclarations FORWARD }
 While Accept(SYM_FUNCTION) or Accept(SYM_PROCEDURE) do Begin
  If current_symbol = SYM_FUNCTION Then Begin
   ParseFunctionDeclaration;
  End
   Else
  If current_symbol = SYM_PROCEDURE Then Begin
   ParseProcedureDeclaration;
  End;
 End;
  { GÇrer le BEGIN principal }
 If Accept(SYM_BEGIN) Then Begin
  BeginCodeSection;
  ParseStatement;
 End
  Else
 Error('Attendu BEGIN');
End;

 { Analyser un programme ou une unitÇ Pascal }
Procedure ParseProgram;Begin
  { VÇrifier si c'est une UNIT }
 If Accept(SYM_UNIT) Then Begin
  ParseUnit;
  Exit;
 End;
  { Sinon, traiter comme un PROGRAM }
 ParseProgramMain;
End;

 { Analyser un programme principal Pascal }
Procedure ParseProgramMain;Begin
 { Entàte PROGRAM }
 If Accept(SYM_PROGRAM) Then Begin
  NextToken; { Consommer PROGRAM }
  If current_symbol = SYM_UNKNOWN Then Begin
   program_name := current_token;
   EmitComment('Programme: ' + program_name);
   NextToken; { Consommer le nom }
   { GÇrer les paramätres optionnels du programme }
   If current_token = '(' Then Begin
    NextToken; { Consommer ( }
    EmitComment('Paramätres du programme:');
     { Ignorer les param√®tres pour l'instant }
    While (current_token <> ')') and (current_char <> #0) do Begin
     If current_symbol = SYM_UNKNOWN Then EmitComment('  - ' + current_token);
     NextToken;
      { GÇrer les virgules }
     If current_token = ',' Then NextToken;
    End;
    If current_token = ')' Then NextToken
                           Else Error('Attendu ) apräs paramätres du programme');
   End;
   If current_token = ';' Then NextToken
                          Else Error('Attendu ; apräs nom d''unitÇ');
  End
   Else
  Error('Attendu nom d''unitÇ');
 End
  Else
 Begin
  { Programme sans entàte PROGRAM - acceptÇ mais avec avertissement }
  Warning('Programme sans entàte PROGRAM - assumÇ programme principal');
  EmitComment('Programme: (sans nom)');
 End;
  { GÇrer la clause USES }
 If Accept(SYM_USES) or ((current_symbol = SYM_UNKNOWN) and (UpperCase(current_token) = 'USES')) Then
  ParseUses;
 GenerateHeader;
 { Analyser le bloc principal }
 ParseBlock;
  { Attendre le point final }
 If current_symbol = SYM_DOT Then NextToken
                             Else Error('Attendu . Ö la fin du programme');
 GenerateFooter;
End;

{ ============================================================================ }
{ PROCêDURES D'INITIALISATION ET PRINCIPALE                                    }
{ ============================================================================ }

{ Initialiser le compilateur }
Procedure InitCompiler;
Var
 i: Integer;
Begin
  { Initialiser les tables de symboles et d'Çtiquettes }
 For i := 1 to MAX_SYMBOLS do symbol_table[i] := nil;
 For i := 1 to MAX_LABEL_COUNT do label_table[i] := nil;
 label_table[i] := nil;
 symbol_count := 0;
 label_count := 0;
 next_label_id := 0;
 error_count := 0;
 line_number := 1;
 line_pos := 1;
 current_char := ' ';
 code_segment := False;
 code_header := False;
 data_segment := False;
 stack_offset := 0;
 current_function_name := '';
 current_function_type := TYPE_INTEGER;
 in_function := False;
  { Initialiser les variables pour les unitÇs }
 current_unit_name := '';
 in_unit := False;
 in_interface := False;
 in_implementation := False;
 unit_symbols_start := 0;
  { PrÇ-enregistrer TRUE et FALSE comme constantes boolÇennes }
 i := AddSymbol('TRUE', SYM_CONST, TYPE_BOOLEAN, STORAGE_GLOBAL);
 If i > 0 Then Begin
  symbol_table[i]^.value := 1;
  symbol_table[i]^.defined := True;
 End;
 i := AddSymbol('FALSE', SYM_CONST, TYPE_BOOLEAN, STORAGE_GLOBAL);
 If i > 0 Then Begin
  symbol_table[i]^.value := 0;
  symbol_table[i]^.defined := True;
 End;
  { PrÇ-enregistrer les fonctions et variables systäme courantes }
 i := AddFunction('EOF',      TYPE_BOOLEAN); If i > 0 Then symbol_table[i]^.defined := True;
 i := AddFunction('EOLN',     TYPE_BOOLEAN); If i > 0 Then symbol_table[i]^.defined := True;
 i := AddFunction('POS',      TYPE_INTEGER); If i > 0 Then symbol_table[i]^.defined := True;
 i := AddFunction('LENGTH',   TYPE_INTEGER); If i > 0 Then symbol_table[i]^.defined := True;
 i := AddFunction('COPY',     TYPE_STRING);  If i > 0 Then symbol_table[i]^.defined := True;
 i := AddFunction('CONCAT',   TYPE_STRING);  If i > 0 Then symbol_table[i]^.defined := True;
 i := AddFunction('UPCASE',   TYPE_CHAR);    If i > 0 Then symbol_table[i]^.defined := True;
 i := AddFunction('CHR',      TYPE_CHAR);    If i > 0 Then symbol_table[i]^.defined := True;
 i := AddFunction('ORD',      TYPE_INTEGER); If i > 0 Then symbol_table[i]^.defined := True;
 i := AddFunction('SUCC',     TYPE_INTEGER); If i > 0 Then symbol_table[i]^.defined := True;
 i := AddFunction('PRED',     TYPE_INTEGER); If i > 0 Then symbol_table[i]^.defined := True;
 i := AddFunction('ABS',      TYPE_INTEGER); If i > 0 Then symbol_table[i]^.defined := True;
  { IORESULT = variable globale entier (0 apräs succäs) }
 i := AddSymbol('IORESULT', SYM_VAR, TYPE_INTEGER, STORAGE_GLOBAL);
 If i > 0 Then symbol_table[i]^.defined := True;
 { PrÇ-enregistrer les procÇdures systäme courantes }
 i := AddProcedure('ASSIGN');   If i > 0 Then symbol_table[i]^.defined := True;
 i := AddProcedure('RESET');    If i > 0 Then symbol_table[i]^.defined := True;
 i := AddProcedure('REWRITE');  If i > 0 Then symbol_table[i]^.defined := True;
 i := AddProcedure('CLOSE');    If i > 0 Then symbol_table[i]^.defined := True;
 i := AddProcedure('EXIT');     If i > 0 Then symbol_table[i]^.defined := True;
 i := AddProcedure('INC');      If i > 0 Then symbol_table[i]^.defined := True;
 i := AddProcedure('DEC');      If i > 0 Then symbol_table[i]^.defined := True;
 i := AddProcedure('NEW');      If i > 0 Then symbol_table[i]^.defined := True;
 i := AddProcedure('DISPOSE');  If i > 0 Then symbol_table[i]^.defined := True;
 i := AddProcedure('STR');      If i > 0 Then symbol_table[i]^.defined := True;
 i := AddProcedure('VAL');      If i > 0 Then symbol_table[i]^.defined := True;
 i := AddProcedure('FILLCHAR'); If i > 0 Then symbol_table[i]^.defined := True;
 i := AddProcedure('MOVE');     If i > 0 Then symbol_table[i]^.defined := True;
 i := AddProcedure('DELETE');   If i > 0 Then symbol_table[i]^.defined := True;
 i := AddProcedure('INSERT');   If i > 0 Then symbol_table[i]^.defined := True;
End;

 { LibÇrer la mÇmoire allouÇe }
Procedure CleanupCompiler;
Var
 i: Integer;
Begin
  { LibÇrer les symboles }
 For i := 1 to symbol_count do If symbol_table[i] <> nil Then Dispose(symbol_table[i]);
  { LibÇrer les Çtiquettes }
 For i := 1 to label_count do If label_table[i] <> nil Then Dispose(label_table[i]);
End;

 { Analyser une clause USES }
Procedure ParseUses;
Var
 unit_name: String;
Begin
 NextToken; { Consommer USES }
 If not option_units_support and not option_crt_dos_support Then Begin
  Warning('USES ignorÇ - aucune option d''unitÇ activÇe (/2 ou /3)');
   { Ignorer jusqu'au point-virgule }
  While (current_token <> ';') and (current_char <> #0) do NextToken;
  If current_token = ';' Then NextToken;
  Exit;
 End;
 If option_crt_dos_support and not option_units_support Then Begin
  { Mode option /2: Support partiel pour Uses Crt,DOS seulement }
  EmitComment('Clause USES (mode partiel Crt,DOS)');
  { Lire les noms d'unit√©s et v√©rifier qu'elles sont support√©es }
  Repeat
   If current_symbol = SYM_UNKNOWN Then Begin
    unit_name := UpperCase(current_token);
    If (unit_name = 'CRT') or (unit_name = 'DOS') Then Begin
     EmitComment('  UnitÇ interne supportÇe: ' + unit_name);
    End
     Else
    Begin
     Warning('UnitÇ non supportÇe en mode /2: ' + unit_name + ' (seuls Crt et DOS sont supportÇs)');
    End;
    NextToken;
   End
   Else
   Begin
    Error('Attendu nom d''unitÇ dans clause USES');
    Break;
   End;
    { GÇrer les virgules }
   If current_token = ',' Then NextToken
                          Else Break;
  Until False;
 End
  Else
 Begin
   { Mode option /3: Support complet des unitÇs }
  EmitComment('Clause USES dÇtectÇe');
  { Lire les noms d'unitÇs }
  Repeat
   If current_symbol = SYM_UNKNOWN Then Begin
    unit_name := current_token;
    EmitComment('  UnitÇ requise: ' + unit_name);
    NextToken;
   End
    Else
   Begin
    Error('Attendu nom d''unitÇ dans clause USES');
    Break;
   End;
    { GÇrer les virgules }
   If current_token = ',' Then NextToken
                          Else Break;
  Until False;
 End;
  { Attendre le point-virgule }
 If current_token = ';' Then NextToken
                        Else Error('Attendu ; apräs clause USES');
End;

 { Analyser la section INTERFACE d'une UNIT }
Procedure ParseInterface;Begin
 NextToken; { Consommer INTERFACE }
 Warning('Section INTERFACE dÇtectÇe - implÇmentation simple');
 { Pour l'instant, ignorer jusqu'Ö IMPLEMENTATION ou END (sans les consommer) }
 While not ((current_symbol = SYM_UNKNOWN) and
          ((UpperCase(current_token) = 'IMPLEMENTATION') or
           (UpperCase(current_token) = 'END'))) and
       (current_symbol <> SYM_END) and (current_char <> #0) do
  NextToken;
End;

 { Analyser la section IMPLEMENTATION d'une UNIT }
Procedure ParseImplementation;Begin
 NextToken; { Consommer IMPLEMENTATION }
 Warning('Section IMPLEMENTATION dÇtectÇe - implÇmentation simple');
  { Pour l'instant, ignorer jusqu'Ö END (sans le consommer) }
 While not ((current_symbol = SYM_UNKNOWN) and (UpperCase(current_token) = 'END')) and
       (current_symbol <> SYM_END) and (current_char <> #0) do
  NextToken;
End;

 { Analyser une UNIT compläte }
Procedure ParseUnit;Begin
 NextToken; { Consommer UNIT }
  { Lire le nom de l'unitÇ }
 If current_symbol = SYM_UNKNOWN Then Begin
  current_unit_name := current_token;
  EmitComment('UnitÇ: ' + current_unit_name);
  NextToken;
 End
  Else
 Begin
  Error('Attendu nom d''unitÇ');
  current_unit_name := '';
 End;
  { Attendre le point-virgule }
 If current_token = ';' Then NextToken
                        Else Error('Attendu ; apräs nom d''unitÇ');
  { Analyser l'interface (si prÇsente) }
 If Accept(SYM_INTERFACE) or ((current_symbol = SYM_UNKNOWN) and (UpperCase(current_token) = 'INTERFACE')) Then
  ParseInterface;
  { Parser l'implÇmentation (si prÇsente) }
 If Accept(SYM_IMPLEMENTATION) or ((current_symbol = SYM_UNKNOWN) and (UpperCase(current_token) = 'IMPLEMENTATION')) Then
  ParseImplementation;
  { Attendre END et le point final }
 If Accept(SYM_END) or ((current_symbol = SYM_UNKNOWN) and (UpperCase(current_token) = 'END')) Then Begin
  NextToken;
  If current_token = '.'Then NextToken
                        Else Error('Attendu . apräs END d''unitÇ');
 End
  Else
 Error('Attendu END Ö la fin de l''unitÇ');
  { RÇinitialiser l'Çtat }
 current_unit_name := '';
End;

 { Analyser les dÇclarations de Çtiquettes }
Procedure ParseLabelDeclarations;
Var
 label_name: String;
 label_index: Integer;
Begin
 NextToken; { Consommer LABEL }
 While (current_symbol = SYM_UNKNOWN) and (current_token <> '') do Begin
  { Lire le nom de l'Çtiquette }
  If current_symbol = SYM_UNKNOWN Then Begin
   label_name := current_token;
    { VÇrifier si l'Çtiquette existe dÇjÖ }
   If FindLabel(label_name) > 0 Then
    Error('êtiquette dÇjÖ dÇclarÇe: ' + label_name)
   Else
   Begin
    { Ajouter l'Çtiquette Ö la table }
    label_index := AddLabel(label_name);
    If label_index > 0 Then EmitComment('DÇclaration Çtiquette: ' + label_name);
   End;
   NextToken;
  End
   Else
  Begin
   Error('Attendu nom d''Çtiquette');
   Break;
  End;
   { GÇrer les virgules }
  If current_token = ',' Then NextToken
                         Else Break;
 End;
  { Attendre le point-virgule }
 If current_token = ';'Then NextToken
                       Else Error('Attendu ; apräs dÇclarations de labels');
End;

 { Analyser une instruction GOTO }
Procedure ParseGoto;
Var
 label_name: String;
 label_index: Integer;
Begin
 NextToken; { Consommer GOTO }
  { Lire le nom de l'Çtiquette }
 If current_symbol = SYM_UNKNOWN Then Begin
  label_name := current_token;
   { VÇrifier si l'Çtiquette est dÇclarÇe }
  label_index := FindLabel(label_name);
  If label_index = 0 Then Error('êtiquette non dÇclarÇe: ' + label_name)
   Else
  Begin
   { GÇnÇrer l'instruction de saut }
   EmitComment('GOTO ' + label_name);
   Emit('jmp ' + UpperCase(label_name) + '_LABEL');
  End;
  NextToken;
 End
  Else
 Error('Attendu nom d''Çtiquette apräs GOTO');
End;

 { GÇnÇrer les procÇdures d'aide (comme PRINT_NUM) }
Procedure GenerateHelpProcedures;Begin
 EmitLine('');
 EmitComment('ProcÇdures d''aide pour l''affichage');
  { ProcÇdure pour afficher un nombre entier }
 EmitLine('PRINT_NUM PROC');
 EmitComment('Affiche le nombre dans AX en dÇcimal');
 EmitLine('    push ax');
 EmitLine('    push bx');
 EmitLine('    push cx');
 EmitLine('    push dx');
 EmitLine('');
 EmitComment('Traiter le signe nÇgatif');
 EmitLine('    cmp ax, 0');
 EmitLine('    jge PRINT_POSITIVE');
 EmitLine('    mov dl, ''-''');
 EmitLine('    mov ah, 02h');
 EmitLine('    int 21h');
 EmitLine('    neg ax');
 EmitLine('');
 EmitLine('PRINT_POSITIVE:');
 EmitComment('Conversion en dÇcimal et affichage');
 EmitLine('    mov cx, 0    ; Compteur de chiffres');
 EmitLine('    mov bx, 10   ; Diviseur');
 EmitLine('');
 EmitLine('PUSH_DIGITS:');
 EmitLine('    mov dx, 0');
 EmitLine('    div bx       ; AX = AX / 10, DX = reste');
 EmitLine('    add dl, 48   ; Convertir en ASCII');
 EmitLine('    push dx      ; Empiler le chiffre');
 EmitLine('    inc cx       ; IncrÇmenter compteur');
 EmitLine('    cmp ax, 0');
 EmitLine('    jne PUSH_DIGITS');
 EmitLine('');
 EmitLine('POP_DIGITS:');
 EmitLine('    pop dx       ; DÇpiler et afficher');
 EmitLine('    mov ah, 02h');
 EmitLine('    int 21h');
 EmitLine('    loop POP_DIGITS');
 EmitLine('');
 EmitLine('    pop dx');
 EmitLine('    pop cx');
 EmitLine('    pop bx');
 EmitLine('    pop ax');
 EmitLine('    ret');
 EmitLine('PRINT_NUM ENDP');
 EmitLine('');
 EmitComment('ProcÇdures d''aide pour les chaånes');
  { ProcÇdure de copie de chaånes }
 EmitLine('COPY_STR PROC');
 EmitComment('Copie une chaåne de SI vers DI (format Pascal: longueur + caractäres)');
 EmitLine('    push ax');
 EmitLine('    push cx');
 EmitLine('    push si');
 EmitLine('    push di');
 EmitLine('');
 EmitComment('Lire la longueur');
 EmitLine('    lodsb            ; Charger longueur depuis [SI]');
 EmitLine('    stosb            ; Stocker longueur vers [DI]');
 EmitLine('    mov cl, al       ; Nombre de caractäres Ö copier');
 EmitLine('    mov ch, 0');
 EmitLine('');
 EmitComment('Copier les caractäres');
 EmitLine('    rep movsb        ; Copier CX caractäres');
 EmitLine('');
 EmitLine('    pop di');
 EmitLine('    pop si');
 EmitLine('    pop cx');
 EmitLine('    pop ax');
 EmitLine('    ret');
 EmitLine('COPY_STR ENDP');
  { ProcÇdure de concatÇnation de chaånes }
 EmitLine('');
 EmitLine('CONCAT_STR PROC');
 EmitComment('Concatäne deux chaånes: SI (source1) + DI (source2) -> SI (rÇsultat)');
 EmitLine('    push ax');
 EmitLine('    push bx');
 EmitLine('    push cx');
 EmitLine('    push dx');
 EmitLine('    push di');
 EmitLine('');
 EmitComment('Calculer la longueur totale');
 EmitLine('    mov al, [si]     ; Longueur chaåne 1');
 EmitLine('    mov bl, [di]     ; Longueur chaåne 2');
 EmitLine('    add al, bl       ; Longueur totale');
 EmitLine('    cmp al, 255      ; VÇrifier dÇpassement');
 EmitLine('    jbe CONCAT_OK');
 EmitLine('    mov al, 255      ; Limiter Ö 255');
 EmitLine('');
 EmitLine('CONCAT_OK:');
 EmitComment('Stocker nouvelle longueur');
 EmitLine('    mov [si], al');
 EmitLine('');
 EmitComment('Positionner pour copie de la deuxiäme chaåne');
 EmitLine('    mov cl, [si]     ; Longueur chaåne 1 originale');
 EmitLine('    mov ch, 0');
 EmitLine('    mov dx, si');
 EmitLine('    inc dx           ; Pointer apräs longueur');
 EmitLine('    add dx, cx       ; Pointer apräs chaåne 1');
 EmitLine('');
 EmitComment('Copier la deuxiäme chaåne');
 EmitLine('    mov cl, [di]     ; Longueur chaåne 2');
 EmitLine('    inc di           ; Pointer apräs longueur');
 EmitLine('    mov si, di       ; Source = chaåne 2');
 EmitLine('    mov di, dx       ; Destination = fin de chaåne 1');
 EmitLine('    rep movsb        ; Copier');
 EmitLine('');
 EmitLine('    pop di');
 EmitLine('    pop dx');
 EmitLine('    pop cx');
 EmitLine('    pop bx');
 EmitLine('    pop ax');
 EmitLine('    ret');
 EmitLine('CONCAT_STR ENDP');
  { ProcÇdure de comparaison de chaånes }
 EmitLine('');
 EmitLine('COMPARE_STR PROC');
 EmitComment('Compare deux chaånes SI et DI, rÇsultat dans AX (0=Çgal, 1=diffÇrent)');
 EmitLine('    push bx');
 EmitLine('    push cx');
 EmitLine('    push dx');
 EmitLine('    push si');
 EmitLine('    push di');
 EmitLine('');
 EmitComment('Lire la longueur');
 EmitLine('    lodsb            ; Charger longueur depuis [SI]');
 EmitLine('    mov cl, al');
 EmitLine('    mov ch, 0');
 EmitLine('    jcxz COMP_STR_END');
 EmitLine('');
 EmitLine('COMP_STR_LOOP:');
 EmitLine('    lodsb            ; Charger caractäre');
 EmitLine('    mov dl, al       ; Caractäre Ö comparer');
 EmitLine('    cmp dl, [di]');
 EmitLine('    jne COMP_DIFF');
 EmitLine('    loop COMP_STR_LOOP');
 EmitLine('');
 EmitLine('COMP_DIFF:');
 EmitLine('    mov ax, 1        ; DiffÇrent');
 EmitLine('    jmp COMP_END');
 EmitLine('');
 EmitLine('COMP_EQUAL:');
 EmitLine('    mov ax, 0        ; êgal');
 EmitLine('');
 EmitLine('COMP_END:');
 EmitLine('    pop di');
 EmitLine('    pop si');
 EmitLine('    pop dx');
 EmitLine('    pop cx');
 EmitLine('    pop bx');
 EmitLine('    ret');
 EmitLine('COMPARE_STR ENDP');
  { ProcÇdure d'affichage de chaånes }
 EmitLine('');
 EmitLine('PRINT_STR PROC');
 EmitComment('Affiche une chaåne Pascal pointÇe par SI');
 EmitLine('    push ax');
 EmitLine('    push cx');
 EmitLine('    push dx');
 EmitLine('    push si');
 EmitLine('');
 EmitComment('Lire la longueur');
 EmitLine('    lodsb            ; AL = longueur');
 EmitLine('    mov cl, al');
 EmitLine('    mov ch, 0');
 EmitLine('    jcxz PRINT_STR_END');
 EmitLine('');
 EmitLine('PRINT_CHAR_LOOP:');
 EmitLine('    lodsb            ; Charger caractäre');
 EmitLine('    mov dl, al       ; Caractäre Ö afficher');
 EmitLine('    mov ah, 02h      ; Fonction DOS affichage caractäre');
 EmitLine('    int 21h');
 EmitLine('    loop PRINT_CHAR_LOOP');
 EmitLine('');
 EmitLine('PRINT_STR_END:');
 EmitLine('    pop si');
 EmitLine('    pop dx');
 EmitLine('    pop cx');
 EmitLine('    pop ax');
 EmitLine('    ret');
 EmitLine('PRINT_STR ENDP');
  { Routine PARAMCOUNT - compte les paramätres de la ligne de commande DOS }
 EmitLine('');
 EmitComment('Routine PARAMCOUNT - compte les paramätres de la ligne de commande');
 EmitLine('PARAMCOUNT PROC');
 EmitComment('RÇsultat dans AX = nombre de paramätres');
 EmitLine('    push bx');
 EmitLine('    push cx');
 EmitLine('    push dx');
 EmitLine('    push es');
 EmitLine('    mov ah, 62h');
 EmitLine('    int 21h');
 EmitLine('    mov es, bx');
 EmitLine('    xor ax, ax');
 EmitLine('    mov cl, es:[80h]');
 EmitLine('    xor ch, ch');
 EmitLine('    jcxz PCT_DONE');
 EmitLine('    mov bx, 81h');
 EmitLine('    xor dh, dh');
 EmitLine('PCT_LOOP:');
 EmitLine('    mov dl, es:[bx]');
 EmitLine('    inc bx');
 EmitLine('    cmp dl, 20h');
 EmitLine('    je PCT_SPC');
 EmitLine('    cmp dl, 09h');
 EmitLine('    je PCT_SPC');
 EmitLine('    cmp dl, 13');
 EmitLine('    je PCT_DONE');
 EmitLine('    cmp dl, 0');
 EmitLine('    je PCT_DONE');
 EmitLine('    test dh, dh');
 EmitLine('    jnz PCT_INTOK');
 EmitLine('    inc ax');
 EmitLine('    mov dh, 1');
 EmitLine('PCT_INTOK:');
 EmitLine('    loop PCT_LOOP');
 EmitLine('    jmp PCT_DONE');
 EmitLine('PCT_SPC:');
 EmitLine('    xor dh, dh');
 EmitLine('    loop PCT_LOOP');
 EmitLine('PCT_DONE:');
 EmitLine('    pop es');
 EmitLine('    pop dx');
 EmitLine('    pop cx');
 EmitLine('    pop bx');
 EmitLine('    ret');
 EmitLine('PARAMCOUNT ENDP');

 { Routine PARAMSTR - extrait le Niäme paramätre de la ligne de commande DOS }
 EmitLine('');
 EmitComment('Tampon pour PARAMSTR (format Pascal: longueur + contenu)');
 EmitLine('.DATA');
 EmitLine('PARAMSTR_BUF DB 256 DUP(0)');
 EmitLine('.CODE');
 EmitComment('Routine PARAMSTR - AX = index (base 1), rÇsultat SI = chaåne Pascal');
 EmitLine('PARAMSTR PROC');
 EmitLine('    push bx');
 EmitLine('    push cx');
 EmitLine('    push dx');
 EmitLine('    push di');
 EmitLine('    push es');
 EmitLine('    push ax');
 EmitLine('    mov ah, 62h');
 EmitLine('    int 21h');
 EmitLine('    mov es, bx');
 EmitLine('    pop ax');
 EmitLine('    cmp ax, 0');
 EmitLine('    je PS_EMPTY');
 EmitLine('    mov cx, ax');
 EmitLine('    mov bx, 81h');
 EmitLine('    xor dl, dl');
 EmitLine('    mov dh, es:[80h]');
 EmitLine('    xor di, di');
 EmitLine('    xor ah, ah');
 EmitLine('PS_FIND:');
 EmitLine('    cmp di, dx');
 EmitLine('    jge PS_EMPTY');
 EmitLine('    mov al, es:[bx+di]');
 EmitLine('    inc di');
 EmitLine('    cmp al, 20h');
 EmitLine('    je PS_SPC');
 EmitLine('    cmp al, 09h');
 EmitLine('    je PS_SPC');
 EmitLine('    cmp al, 13');
 EmitLine('    je PS_EMPTY');
 EmitLine('    cmp al, 0');
 EmitLine('    je PS_EMPTY');
 EmitLine('    test ah, ah');
 EmitLine('    jnz PS_INTOK');
 EmitLine('    dec cx');
 EmitLine('    jz PS_COPY');
 EmitLine('    mov ah, 1');
 EmitLine('PS_INTOK:');
 EmitLine('    jmp PS_FIND');
 EmitLine('PS_SPC:');
 EmitLine('    xor ah, ah');
 EmitLine('    jmp PS_FIND');
 EmitLine('PS_COPY:');
 EmitLine('    dec di');
 EmitLine('    mov si, OFFSET PARAMSTR_BUF');
 EmitLine('    push si');
 EmitLine('    inc si');
 EmitLine('    xor cl, cl');
 EmitLine('PS_CPLOOP:');
 EmitLine('    cmp di, dx');
 EmitLine('    jge PS_CPDONE');
 EmitLine('    mov al, es:[bx+di]');
 EmitLine('    inc di');
 EmitLine('    cmp al, 20h');
 EmitLine('    je PS_CPDONE');
 EmitLine('    cmp al, 09h');
 EmitLine('    je PS_CPDONE');
 EmitLine('    cmp al, 13');
 EmitLine('    je PS_CPDONE');
 EmitLine('    cmp al, 0');
 EmitLine('    je PS_CPDONE');
 EmitLine('    mov [si], al');
 EmitLine('    inc si');
 EmitLine('    inc cl');
 EmitLine('    jmp PS_CPLOOP');
 EmitLine('PS_CPDONE:');
 EmitLine('    pop si');
 EmitLine('    mov [si], cl');
 EmitLine('    jmp PS_DONE');
 EmitLine('PS_EMPTY:');
 EmitLine('    mov si, OFFSET PARAMSTR_BUF');
 EmitLine('    mov byte ptr [si], 0');
 EmitLine('PS_DONE:');
 EmitLine('    pop es');
 EmitLine('    pop di');
 EmitLine('    pop dx');
 EmitLine('    pop cx');
 EmitLine('    pop bx');
 EmitLine('    ret');
 EmitLine('PARAMSTR ENDP');
End;

{ VÇrifier les Çtiquettes non dÇfinies }
Procedure CheckUndefinedLabels;
Var
 i: Integer;
Begin
 For i := 1 to label_count do
  If (label_table[i] <> nil) and not label_table[i]^.defined Then
   Error('êtiquette dÇclarÇe mais non dÇfinie: ' + label_table[i]^.name);
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('PC8086 - Cette commande permet de lancer une compilateur Pascal gÇnÇrant du code pour le ',
          'microprocesseur 8086 ou 8088.');
  WriteLn;
  WriteLn('Syntaxe: PC8086 [options] <fichier.pas> [fichier.asm]');
  WriteLn('');
  WriteLn('Options:');
  WriteLn('  /2         : Activer support partiel interne Uses Crt,DOS');
  WriteLn('  /3         : Activer support complet UNIT/INTERFACE/IMPLEMENTATION/USES');
  WriteLn('');
  WriteLn('  <fichier.pas>  : Fichier source Pascal');
  WriteLn('  [fichier.asm]  : Fichier assembleur de sortie (optionnel)');
  Halt;
 End;
  { Initialiser les options par dÇfaut }
 option_units_support := False;
 option_crt_dos_support := False;
  { Traiter les options }
 If (ParamCount >= 1) and (ParamStr(1) = '/2') Then Begin
  option_crt_dos_support := True;
  WriteLn('Option 2 activÇe: Support partiel interne Uses Crt,DOS');
  source_filename := ParamStr(2);
  If ParamCount >= 3 Then output_filename := ParamStr(3)
                     Else output_filename := '';
 End
  Else
 If (ParamCount >= 1) and (ParamStr(1) = '/3') Then Begin
  option_units_support := True;
  WriteLn('Option 3 activÇe: Support complet des unitÇs Pascal');
  source_filename := ParamStr(2);
  If ParamCount >= 3 Then output_filename := ParamStr(3)
                     Else output_filename := '';
 End
  Else
 Begin
  source_filename := ParamStr(1);
  If ParamCount >= 2 Then output_filename := ParamStr(2)
                     Else output_filename := '';
 End;
 WriteLn('PC8086 - Compilateur Pascal vers Assembleur 8086 v1.0');
 WriteLn('======================================================');
 WriteLn('');
  { GÇnÇrer le nom de fichier de sortie si nÇcessaire }
 If output_filename = '' Then Begin
  output_filename := source_filename;
  { Changer l'extension .pas en .asm }
  If Pos('.', output_filename) > 0 Then output_filename := Copy(output_filename, 1, Pos('.', output_filename) - 1) + '.asm'
                                   Else output_filename := output_filename + '.asm';
 End;
 WriteLn('Fichier source: ', source_filename);
 WriteLn('Fichier sortie: ', output_filename);
 WriteLn('');
  { Ouvrir les fichiers }
 Assign(input_file, source_filename);
 {$I-}
 Reset(input_file);
 {$I+}
 If IOResult <> 0 Then Begin
  WriteLn('ERREUR: Impossible d''ouvrir le fichier source: ', source_filename);
  Exit;
 End;
 Assign(output_file, output_filename);
 {$I-}
 Rewrite(output_file);
 {$I+}
 If IOResult <> 0 Then Begin
  WriteLn('ERREUR: Impossible de crÇer le fichier de sortie: ', output_filename);
  Close(input_file);
  Exit;
 End;
  { Initialiser le compilateur }
 InitCompiler;
  { Lire la premiäre ligne }
 If not Eof(input_file) Then Begin
  ReadLn(input_file, current_line);
  line_pos := 1;
 End;
 { Lire le premier caractäre }
 NextChar;
 NextToken;
  { Commencer la compilation }
 ParseProgram;
  { GÇnÇrer les procÇdures d'aide }
 GenerateHelpProcedures;
  { VÇrifier les Çtiquettes }
 CheckUndefinedLabels;
  { Fermer les fichiers }
 Close(input_file);
 Close(output_file);
  { LibÇrer la mÇmoire }
 CleanupCompiler;
 WriteLn('Compilation terminÇe.');
 WriteLn('Erreurs: ', error_count);
 If error_count = 0 Then WriteLn('Assemblage recommandÇ: MASM ', output_filename)
                    Else WriteLn('Veuillez corriger les erreurs avant l''assemblage.');
END.