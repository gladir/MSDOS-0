{ @author:      Sylvain Maltais
  @created:     2026
  @website(https://www.gladir.com/msdos0)
  @abstract:    Target: Turbo Pascal 7 / Free Pascal 3.2 (-Mtp)
  @description: Clone MASM, compilateur Assembleur pour 8086
  @author:      Sylvain Maltais (support@gladir.com)
  @output:      Intel OMF .OBJ (MASM 5.x compatible)
}

{ ================================================================
  MASM.PAS - Macro Assembleur 8086 compatible MASM 5.x
  ================================================================

  Clone de Microsoft Macro Assembler (MASM) pour DOS 8086.
  Produit des fichiers .OBJ au format Intel Object Module Format
  (OMF) compatibles avec :
    - Microsoft LINK (MASM 5.x / 6.x)
    - IBM Macro Assembler
    - Turbo C / Turbo Pascal TLINK
    - Borland TLINK
    - Watcom WLINK
  L'assembleur effectue un assemblage en deux passes pour
  resoudre toutes les references avant.

  ================================================================ }

Program MASM;

{ ============================================================
  INFRASTRUCTURE DE BASE - IMPLEMENTE
  ============================================================ }

{ ---- Constantes generales ---- }
Uses Dos;

Const
  VERSION      = '1.0';
  MAX_SYM      = 4096; { max symboles (heap, compte seulement) }
  MAX_SEG      = 16;   { max segments definis }
  MAX_GRP      = 8;    { max groupes definis }
  MAX_FIXUP    = {$IFDEF FPC}8192{$ELSE}2048{$ENDIF}; { max fixups internes par passe }
  MAX_MACRO    = 256;  { max macros definies }
  MAX_STRUCT   = {$IFDEF FPC}64{$ELSE}8{$ENDIF};   { max structures STRUC }
  MAX_IF_DEPTH = 32;   { profondeur max des blocs IF imbriques }
  HASH_SIZE    = 256;  { buckets de la table de hachage symboles }
  INC_DEPTH    = 8;    { max niveaux d inclusion INCLUDE }
  MAX_TEXTEQU  = 128;  { max macros texte (TEXTEQU) }

{ ---- Types de base ---- }
Type
  TString    = String[127]; { chaine generale (lignes source, noms) }
  TSymString = String[32];  { nom de symbole/segment (uppercase) }
  TByte      = Byte;
  TWord      = Word;
  TLong      = LongInt;

  { Genres de tokens produits par le lexer }
  TTokenKind = (
    TK_IDENT,    { identificateur ou mot-cle / directive / mnemonic }
    TK_NUMBER,   { literal numerique (dec/hex/oct/bin) }
    TK_STRING,   { chaine litterale delimitee par ' ou " }
    TK_PUNCT,    { operateur ou ponctuation ( ) [ ] + - * / . : , = }
    TK_NEWLINE,  { fin de ligne logique (separateur d instruction) }
    TK_EOF       { fin de fichier source }
  );

  { Genre d un symbole dans la table des symboles }
  TSymKind = (
    SK_UNDEF,    { reference avant non encore resolue }
    SK_LABEL,    { etiquette de code ou de donnee }
    SK_PUBLIC,   { symbole exporte (PUBLIC) }
    SK_EXTERN,   { symbole importe (EXTRN) }
    SK_EQU,      { constante EQU (non reassignable) ou = (reassignable) }
    SK_GROUP,    { nom de groupe (GROUP) }
    SK_SEG,      { nom de segment (SEGMENT) }
    SK_MACRO,    { macro (MACRO/ENDM) }
    SK_STRUCT    { structure de donnees (STRUC/ENDS) }
  );

  { Taille d un operande de donnee }
  TDataSize = (
    DS_BYTE,     { 1 octet  - DB }
    DS_WORD,     { 2 octets - DW }
    DS_DWORD,    { 4 octets - DD }
    DS_QWORD,    { 8 octets - DQ }
    DS_TBYTE,    { 10 octets - DT }
    DS_UNKNOWN   { taille non specifiee / non applicable }
  );

  { Token produit par le lexer }
  TToken = Record
    kind     : TTokenKind; { type de token }
    val      : TString;    { valeur textuelle (toujours en majuscules) }
    num_val  : TLong;      { valeur numerique (valide si TK_NUMBER) }
    line_num : Integer;    { numero de ligne source logique }
  End;

  { ------- Table des symboles (allocation dynamique sur le heap) ------- }
  PSymbol = ^TSymbol;
  TSymbol = Record
    name    : TSymString; { nom du symbole (uppercase) }
    kind    : TSymKind;   { genre du symbole }
    seg_idx : Integer;    { index dans seg_table (0 = absolu / externe) }
    offset  : TWord;      { offset dans le segment au moment de la def. }
    value   : TLong;      { valeur absolue (SK_EQU, SK_EXTERN, etc.) }
    size    : TWord;      { taille en octets (labels donnee, STRUC) }
    flags   : TByte;      { bit 0=is_public, bit 1=is_extern, bit 2=is_defined }
    next    : PSymbol;    { maillon suivant dans la chaine de hachage }
  End;

  { ------- Segments ------- }
  TSegCombine = (
    SC_PRIVATE, { segment prive (non fusionne par LINK) }
    SC_PUBLIC,  { fusionner avec segments de meme nom/classe }
    SC_COMMON,  { superposer (taille = max des tailles) }
    SC_STACK,   { pile (fusionner, combine = STACK) }
    SC_MEMORY,  { alias de SC_PUBLIC pour compatibilite }
    SC_AT       { segment absolu (AT valeur) }
  );
  TSegAlign = (
    SA_BYTE,    { aligner a l octet }
    SA_WORD,    { aligner au mot (2 octets) }
    SA_PARA,    { aligner au paragraphe (16 octets) }
    SA_PAGE,    { aligner a la page (256 octets) }
    SA_DWORD    { aligner au double-mot (4 octets) }
  );

  TSegInfo = Record
    name       : TSymString;  { nom du segment }
    class_name : TSymString;  { classe OMF (ex: 'CODE','DATA','STACK') }
    combine    : TSegCombine; { type de combinaison LINK }
    align      : TSegAlign;   { alignement OMF }
    size       : TWord;       { taille totale accumulee (octets) }
    cur_lc     : TWord;       { location counter courant dans ce segment }
    lnames_idx : Integer;     { index 1-base dans le record LNAMES OMF }
    defined    : Boolean;     { True si segment declare par SEGMENT ou .MODEL }
  End;

  { ------- Groupes ------- }
  TGrpInfo = Record
    name      : TSymString;              { nom du groupe (ex: DGROUP) }
    seg_count : Integer;                 { nb de segments appartenant au groupe }
    segs      : Array[1..MAX_SEG] Of Integer; { indices 1-base dans seg_table }
    defined   : Boolean;                 { True si groupe declare }
  End;

  { ------- Resultat d une evaluation d expression ------- }
  TExpr = Record
    val        : TLong;    { valeur numerique de l expression }
    is_reloc   : Boolean;  { True = adresse relocalisable dans un segment }
    seg_idx    : Integer;  { index 1-base dans seg_table (si is_reloc=True) }
    is_undef   : Boolean;  { True = symbole inconnu en passe 1 (reporter passe 2) }
    ptr_size   : Integer;  { 0=non specifie,1=BYTE,2=WORD/NEAR,4=DWORD/FAR,8=QWORD,10=TBYTE }
  End;

{ ---- Variables globales ---- }
Var
  { Tables de la chaine de hachage (symboles sur le heap) }
  hash_table : Array[0..HASH_SIZE-1] Of PSymbol;

  { Tables fixes (seg_table et grp_table sont petites, sur la pile globale) }
  seg_table  : Array[1..MAX_SEG] Of TSegInfo;
  grp_table  : Array[1..MAX_GRP] Of TGrpInfo;

  { Compteurs de tables }
  sym_count  : Integer;  { nb de PSymbol alloues sur le heap }
  seg_count  : Integer;  { nb de segments definis }
  grp_count  : Integer;  { nb de groupes definis }

  { Etat de l assemblage }
  pass_num   : Integer;  { passe courante : 1 ou 2 }
  err_count  : Integer;  { nb d erreurs detectees }
  warn_count : Integer;  { nb d avertissements }
  lc         : TWord;    { location counter courant (dans cur_seg) }
  cur_seg    : Integer;  { index segment courant dans seg_table (0=hors segment) }

  { Fichiers }
  src_fname  : TString;  { nom du fichier source .ASM }
  obj_fname  : TString;  { nom du fichier objet  .OBJ }
  lst_fname  : TString;  { nom du fichier listing .LST }
  do_listing : Boolean;  { True = generer le fichier .LST }

  { Options ligne de commande }
  case_sensitive  : Boolean;  { /ML = conserver la casse des labels }
  case_public_ext : Boolean;  { /MX = casse des publics/externes }
  warn_level      : Integer;  { /W0-2 = niveau d avertissement }
  silent_mode     : Boolean;  { /T = mode silencieux }
  list_cond       : Boolean;  { /X = lister blocs conditionnels inactifs }
  show_err_lines  : Boolean;  { /Z = afficher ligne source avec erreur }
  seg_alpha       : Boolean;  { /A = tri alpha; /S = ordre definition }
  do_crf          : Boolean;  { /C = generer .CRF }
  crf_fname       : TString;  { nom du fichier .CRF }

  { Ligne de source courante (pour messages d erreur) }
  cur_line   : TString;  { contenu de la ligne en cours d analyse }
  cur_lineno : Integer;  { numero de ligne logique (apres continuation) }

  { Controle d emission (passe 1 = True => avancer LC sans ecrire) }
  no_emit    : Boolean;

  { Point d entree (directive END label) et fin de source }
  has_entry  : Boolean;  { True si END label a ete trouve }
  entry_seg  : Integer;  { segment du point d entree }
  entry_off  : TWord;    { offset  du point d entree }
  asm_end_seen : Boolean; { True apres directive END -> arreter la lecture }

  { Fichier de listing .LST }
  lst_file         : Text;           { fichier de listing ouvert }
  lst_is_open      : Boolean;        { True si lst_file est ouvert }
  lst_active       : Boolean;        { True si .LIST actif (pas .NOLIST) }
  lst_sym_table    : Boolean;        { True = inclure table symboles (/N=False) }
  lst_page_lines   : Integer;        { nb de lignes par page (defaut 60) }
  lst_page_cols    : Integer;        { nb de colonnes par page (defaut 80) }
  lst_page_num     : Integer;        { numero de page courant }
  lst_line_on_page : Integer;        { ligne courante sur la page }
  lst_title        : TString;        { titre courant (TITLE) }
  lst_subttl       : TString;        { sous-titre courant (SUBTTL) }
  lst_line_start_lc  : TWord;        { LC en debut de ligne (pour hex) }
  lst_line_start_seg : Integer;      { segment en debut de ligne }
  lst_nbytes       : Integer;        { nb d octets emis sur la ligne courante }
  lst_bytes        : Array[0..255] Of Byte;  { octets emis sur la ligne courante }

{ ============================================================
  Fonction de hachage djb2 adaptee (retourne 0..HASH_SIZE-1)
  ============================================================ }
Function HashName(Const s : TSymString) : Integer;
Var
  i : Integer;
  h : LongInt;
Begin
  h := 5381;
  For i := 1 To Length(s) Do
    h := ((h Shl 5) + h) Xor LongInt(Ord(s[i]));
  If h < 0 Then h := -h;
  HashName := Integer(h Mod HASH_SIZE);
End;

{ ============================================================
  InitTables : remettre toutes les tables a zero / nil / False
  ============================================================ }
Procedure InitTables;
Var
  i, j : Integer;
Begin
  { vider la table de hachage }
  For i := 0 To HASH_SIZE-1 Do
    hash_table[i] := Nil;

  { initialiser les segments }
  For i := 1 To MAX_SEG Do
  Begin
    With seg_table[i] Do
    Begin
      name       := '';
      class_name := '';
      combine    := SC_PRIVATE;
      align      := SA_PARA;
      size       := 0;
      cur_lc     := 0;
      lnames_idx := 0;
      defined    := False;
    End;
  End;

  { initialiser les groupes }
  For i := 1 To MAX_GRP Do
  Begin
    With grp_table[i] Do
    Begin
      name      := '';
      seg_count := 0;
      defined   := False;
      For j := 1 To MAX_SEG Do segs[j] := 0;
    End;
  End;

  sym_count  := 0;
  seg_count  := 0;
  grp_count  := 0;
  pass_num   := 0;
  err_count  := 0;
  warn_count := 0;
  lc         := 0;
  cur_seg    := 0;
  cur_lineno := 0;
  do_listing      := False;
  case_sensitive  := False;
  case_public_ext := False;
  warn_level      := 1;
  silent_mode     := False;
  list_cond       := False;
  show_err_lines  := False;
  seg_alpha       := False;
  do_crf          := False;
  crf_fname       := '';
  has_entry    := False;
  entry_seg    := 0;
  entry_off    := 0;
  asm_end_seen := False;
  src_fname  := '';
  obj_fname  := '';
  lst_fname  := '';
  cur_line   := '';
  { listing }
  lst_is_open      := False;
  lst_active       := False;
  lst_sym_table    := True;
  lst_page_lines   := 60;
  lst_page_cols    := 80;
  lst_page_num     := 0;
  lst_line_on_page := 0;
  lst_title        := '';
  lst_subttl       := '';
  lst_line_start_lc  := 0;
  lst_line_start_seg := 0;
  lst_nbytes       := 0;
End;

{ ============================================================
  ErrorMsg : afficher un message d erreur (style MASM A2xxx)
  ============================================================ }
Procedure ErrorMsg(Const msg : TString);
Begin
  Inc(err_count);
  If src_fname <> '' Then
    Writeln(src_fname, '(', cur_lineno, ') : error A2',
            err_count:3, ': ', msg)
  Else
    Writeln('error A2', err_count:3, ': ', msg);
  If show_err_lines And (cur_line <> '') Then
    Writeln('  ', cur_line);
End;

{ ============================================================
  WarnMsg : afficher un avertissement (style MASM A4xxx)
  ============================================================ }
Procedure WarnMsg(Const msg : TString);
Begin
  If warn_level = 0 Then Exit;
  Inc(warn_count);
  If src_fname <> '' Then
    Writeln(src_fname, '(', cur_lineno, ') : warning A4',
            warn_count:3, ': ', msg)
  Else
    Writeln('warning A4', warn_count:3, ': ', msg);
End;

{ ============================================================
  LECTEUR DE SOURCE ET GESTIONNAIRE D INCLUSION
  ============================================================

  Principe :
    - Pile de max INC_DEPTH contextes de fichier (SrcPush/SrcPop).
    - SrcReadLine retourne la prochaine ligne logique (avec
      expansion des tabulations et suppression du commentaire ;).
    - La continuation de ligne est detectee si le dernier
      caractere non-espace est une barre oblique inverse \ ;
      dans ce cas les lignes suivantes sont concatenees jusqu a
      ce qu il n y en ait plus.
    - phys_lineno est incrementee a chaque ligne physique lue.
  ============================================================ }

{ ---- Types de la pile d inclusion ---- }
Type
  TSrcContext = Record
    f        : Text;         { fichier Pascal ouvert }
    fname    : TString;      { nom du fichier }
    lineno   : Integer;      { dernier numero de ligne physique lu }
    is_open  : Boolean;      { True si le fichier est ouvert }
  End;

{ ---- Variables du lecteur de source ---- }
Var
  src_stack  : Array[0..INC_DEPTH-1] Of TSrcContext; { pile d inclusion }
  src_top    : Integer;  { indice du contexte courant (-1 = vide) }
  phys_lineno: Integer;  { compteur de lignes physiques global }

  { Repertoires de recherche INCLUDE (/I sur la ligne de commande) }
  inc_dirs   : Array[0..15] Of TString;
  inc_dir_cnt: Integer;

  { Table TEXTEQU (macros texte) et predefined strings }
  textequ_names : Array[1..MAX_TEXTEQU] Of TSymString;
  textequ_vals  : Array[1..MAX_TEXTEQU] Of TString;
  textequ_count : Integer;

  { Predefined string values (mises a jour en cours d assemblage) }
  predef_date : TString;  { date assemblage 'MM/DD/YY' }
  predef_time : TString;  { heure assemblage 'HH:MM:SS' }

{ ============================================================
  SrcInit : initialiser la pile d inclusion
  ============================================================ }
Procedure SrcInit;
Var
  i : Integer;
Begin
  src_top     := -1;
  phys_lineno := 0;
  inc_dir_cnt := 0;
  textequ_count := 0;
  predef_date := '';
  predef_time := '';
  For i := 0 To INC_DEPTH-1 Do
  Begin
    src_stack[i].fname   := '';
    src_stack[i].lineno  := 0;
    src_stack[i].is_open := False;
  End;
  For i := 0 To 15 Do
    inc_dirs[i] := '';
End;

{ ============================================================
  SrcAtEnd : True si la pile est vide (plus rien a lire)
  ============================================================ }
Function SrcAtEnd : Boolean;
Begin
  SrcAtEnd := (src_top < 0);
End;

{ ============================================================
  SrcFindFile : chercher fname dans le repertoire courant puis
  dans inc_dirs ; retourne le chemin complet trouve ou fname
  si non trouve.
  ============================================================ }
Function SrcFindFile(Const fname : TString) : TString;
Var
  i    : Integer;
  path : TString;
  tmp  : Text;
  env  : TString;
  ep   : Integer;
  es   : Integer;
  edr  : TString;
Begin
  { 1. tel quel (absolu ou relatif au CWD) }
  Assign(tmp, fname);
  {$I-}
  Reset(tmp);
  {$I+}
  If IoResult = 0 Then
  Begin
    Close(tmp);
    SrcFindFile := fname;
    Exit;
  End;
  { 2. dans les repertoires /I }
  For i := 0 To inc_dir_cnt-1 Do
  Begin
    path := inc_dirs[i];
    If (Length(path) > 0) And (path[Length(path)] <> '\') Then
      path := path + '\';
    path := path + fname;
    Assign(tmp, path);
    {$I-}
    Reset(tmp);
    {$I+}
    If IoResult = 0 Then
    Begin
      Close(tmp);
      SrcFindFile := path;
      Exit;
    End;
  End;
  { 3. dans la variable d environnement INCLUDE (separateur ;) }
  env := GetEnv('INCLUDE');
  If env <> '' Then
  Begin
    ep := 1;
    While ep <= Length(env) Do
    Begin
      es := ep;
      While (ep <= Length(env)) And (env[ep] <> ';') Do Inc(ep);
      edr := Copy(env, es, ep - es);
      Inc(ep); { sauter le ; }
      If edr <> '' Then
      Begin
        If edr[Length(edr)] <> '\' Then edr := edr + '\';
        path := edr + fname;
        Assign(tmp, path);
        {$I-}
        Reset(tmp);
        {$I+}
        If IoResult = 0 Then
        Begin
          Close(tmp);
          SrcFindFile := path;
          Exit;
        End;
      End;
    End;
  End;
  SrcFindFile := fname; { non trouve, retourner tel quel }
End;

{ ============================================================
  SrcPush : ouvrir un fichier et l empiler
  ============================================================ }
Procedure SrcPush(Const fn : TString);
Var
  rpath : TString;
Begin
  If src_top >= INC_DEPTH-1 Then
  Begin
    ErrorMsg('INCLUDE trop profond (max ' +
             Chr(Ord('0') + INC_DEPTH) + ' niveaux)');
    Exit;
  End;
  rpath := SrcFindFile(fn);
  Inc(src_top);
  With src_stack[src_top] Do
  Begin
    fname   := rpath;
    lineno  := 0;
    is_open     := False;
    Assign(f, rpath);
    {$I-}
    Reset(f);
    {$I+}
    If IoResult <> 0 Then
    Begin
      Dec(src_top);
      ErrorMsg('Impossible d ouvrir le fichier : ' + rpath);
      Exit;
    End;
    is_open := True;
  End;
  { mettre a jour src_fname avec le fichier courant }
  src_fname := src_stack[src_top].fname;
End;

{ ============================================================
  SrcPop : fermer le fichier courant et depiler
  ============================================================ }
Procedure SrcPop;
Begin
  If src_top < 0 Then Exit;
  With src_stack[src_top] Do
    If is_open Then
    Begin
      Close(f);
      is_open := False;
    End;
  Dec(src_top);
  If src_top >= 0 Then
    src_fname := src_stack[src_top].fname
  Else
    src_fname := '';
End;

{ ============================================================
  SrcStripComment : supprimer le commentaire (;) d une ligne,
  en respectant les chaines entre guillemets simples ou doubles.
  ============================================================ }
Function SrcStripComment(Const line : TString) : TString;
Var
  i      : Integer;
  in_sq  : Boolean; { dans une chaine simple quote }
  in_dq  : Boolean; { dans une chaine double quote }
  c      : Char;
  result : TString;
Begin
  in_sq  := False;
  in_dq  := False;
  result := '';
  For i := 1 To Length(line) Do
  Begin
    c := line[i];
    If (c = '''') And Not in_dq Then in_sq := Not in_sq
    Else If (c = '"') And Not in_sq Then in_dq := Not in_dq
    Else If (c = ';') And Not in_sq And Not in_dq Then
      Break; { debut du commentaire }
    result := result + c;
  End;
  { supprimer les espaces de fin }
  While (Length(result) > 0) And (result[Length(result)] = ' ') Do
    Delete(result, Length(result), 1);
  SrcStripComment := result;
End;

{ ============================================================
  SrcExpandTabs : remplacer les tabulations par des espaces
  (tabstop = 8).
  ============================================================ }
Function SrcExpandTabs(Const line : TString) : TString;
Var
  i      : Integer;
  col    : Integer;
  result : TString;
  spaces : Integer;
  j      : Integer;
Begin
  result := '';
  col    := 1;
  For i := 1 To Length(line) Do
  Begin
    If line[i] = #9 Then
    Begin
      spaces := 8 - ((col-1) Mod 8);
      For j := 1 To spaces Do
      Begin
        result := result + ' ';
        Inc(col);
      End;
    End
    Else
    Begin
      result := result + line[i];
      Inc(col);
    End;
  End;
  SrcExpandTabs := result;
End;

{ ============================================================
  SrcIsContinued : True si la ligne se termine par \ (continuation)
  Retire le \ de la fin de la chaine.
  ============================================================ }
Function SrcIsContinued(Var line : TString) : Boolean;
Var
  trimmed : TString;
  len     : Integer;
Begin
  trimmed := line;
  { retirer les espaces de fin }
  While (Length(trimmed) > 0) And (trimmed[Length(trimmed)] = ' ') Do
    Delete(trimmed, Length(trimmed), 1);
  len := Length(trimmed);
  If (len > 0) And (trimmed[len] = '\') Then
  Begin
    Delete(trimmed, len, 1);
    { retirer les espaces avant le \ }
    While (Length(trimmed) > 0) And (trimmed[Length(trimmed)] = ' ') Do
      Delete(trimmed, Length(trimmed), 1);
    line := trimmed;
    SrcIsContinued := True;
  End
  Else
  Begin
    line := trimmed;
    SrcIsContinued := False;
  End;
End;

{ ============================================================
  SrcReadLine : lire la prochaine ligne logique du fichier
  courant (avec continuation et pre-traitement).
  Retourne True si une ligne a ete lue, False si fin de fichier.
  La ligne resultante est stockee dans cur_line et cur_lineno.
  ============================================================ }
Function SrcReadLine : Boolean;
Var
  raw     : TString;
  logical : TString;
  cont    : Boolean;
Begin
  SrcReadLine := False;
  If SrcAtEnd Then Exit;

  logical := '';
  Repeat
    { si le fichier courant est epuise, depiler }
    While (src_top >= 0) And Eof(src_stack[src_top].f) Do
      SrcPop;
    If SrcAtEnd Then
    Begin
      { fin reelle de tous les fichiers }
      If logical <> '' Then
        Break; { retourner la ligne deja accumulee }
      Exit;
    End;

    { lire une ligne physique }
    ReadLn(src_stack[src_top].f, raw);
    Inc(src_stack[src_top].lineno);
    Inc(phys_lineno);

    { expansion des tabulations }
    raw := SrcExpandTabs(raw);

    { suppression du commentaire (;) }
    raw := SrcStripComment(raw);

    { gestion de la continuation }
    cont := SrcIsContinued(raw);
    If logical <> '' Then
      logical := logical + ' ' + raw
    Else
      logical := raw;
  Until Not cont;

  cur_lineno := src_stack[src_top].lineno;
  cur_line   := logical;
  SrcReadLine := True;
End;

{ ============================================================
  TEXTEQU / SYMBOLES PREDEFINIS - IMPLEMENTE
  ============================================================ }

{ ============================================================
  TextEquFind : chercher une macro texte par nom (major).
  Retourne l index 1-base dans textequ_names, ou 0.
  ============================================================ }
Function TextEquFind(Const name : TSymString) : Integer;
Var i : Integer;
Begin
  TextEquFind := 0;
  For i := 1 To textequ_count Do
    If textequ_names[i] = name Then
    Begin
      TextEquFind := i;
      Exit;
    End;
End;

{ ============================================================
  TextEquSet : creer ou mettre a jour une macro texte.
  ============================================================ }
Procedure TextEquSet(Const name : TSymString; Const val : TString);
Var i : Integer;
Begin
  i := TextEquFind(name);
  If i = 0 Then
  Begin
    If textequ_count >= MAX_TEXTEQU Then Exit;
    Inc(textequ_count);
    i := textequ_count;
  End;
  textequ_names[i] := name;
  textequ_vals[i]  := val;
End;

{ ============================================================
  TextEquGet : retourner la valeur d une macro texte ou ''.
  ============================================================ }
Function TextEquGet(Const name : TSymString) : TString;
Var i : Integer;
Begin
  i := TextEquFind(name);
  If i > 0 Then TextEquGet := textequ_vals[i]
  Else           TextEquGet := '';
End;

{ ============================================================
  TextEquSubstLine : substituer les macros texte dans une ligne
  source. Parcourt caractere par caractere ; quand un identif.
  correspond a une TEXTEQU, il est remplace par sa valeur.
  Respecte les chaines entre ' et ".
  ============================================================ }
Function TextEquSubstLine(Const s : TString) : TString;
Var
  i      : Integer;
  c      : Char;
  in_sq  : Boolean; { dans une chaine ' }
  in_dq  : Boolean; { dans une chaine " }
  id_st  : Integer; { debut de l identifiant courant }
  id     : TSymString;
  uname  : TSymString;
  val    : TString;
  res    : TString;
Begin
  res   := '';
  in_sq := False;
  in_dq := False;
  i     := 1;
  While i <= Length(s) Do
  Begin
    c := s[i];
    { gestion chaines }
    If (c = '''') And Not in_dq Then Begin in_sq := Not in_sq; res := res + c; Inc(i); Continue; End;
    If (c = '"')  And Not in_sq Then Begin in_dq := Not in_dq; res := res + c; Inc(i); Continue; End;
    If in_sq Or in_dq Then Begin res := res + c; Inc(i); Continue; End;

    { debut d identifiant : lettre, _ ou @ }
    If (c = '@') Or (c = '_') Or ((c >= 'A') And (c <= 'Z'))
                               Or ((c >= 'a') And (c <= 'z')) Then
    Begin
      id_st := i;
      id := '';
      While (i <= Length(s)) And
            ((s[i] = '@') Or (s[i] = '_') Or
             ((s[i] >= 'A') And (s[i] <= 'Z')) Or
             ((s[i] >= 'a') And (s[i] <= 'z')) Or
             ((s[i] >= '0') And (s[i] <= '9'))) Do
      Begin
        If Length(id) < 32 Then
        Begin
          c := s[i];
          If (c >= 'a') And (c <= 'z') Then c := Chr(Ord(c) - 32);
          id := id + c;
        End;
        Inc(i);
      End;
      uname := id;
      val   := TextEquGet(uname);
      If val <> '' Then
        res := res + val
      Else
        res := res + Copy(s, id_st, i - id_st);
    End
    Else
    Begin
      res := res + c;
      Inc(i);
    End;
  End;
  TextEquSubstLine := res;
End;

{ ============================================================
  Pad2 : formater n sur 2 chiffres avec zero devant.
  ============================================================ }
Function Pad2(n : Word) : TString;
Var s : TString;
Begin
  Str(n Mod 100, s);
  If Length(s) < 2 Then s := '0' + s;
  Pad2 := s;
End;

{ ============================================================
  InitPredefDateTimeFilename : calculer @DATE, @TIME, @FILENAME
  et les enregistrer dans la table TEXTEQU.
  ============================================================ }
Procedure InitPredefDateTimeFilename(Const fname : TString);
Var
  yr, mo, dy, dow : Word;
  hr, mn, sc, sc2 : Word;
  fi : Integer;
  fn : TString;
Begin
  GetDate(yr, mo, dy, dow);
  GetTime(hr, mn, sc, sc2);
  predef_date := Pad2(mo) + '/' + Pad2(dy) + '/' + Pad2(yr Mod 100);
  predef_time := Pad2(hr) + ':' + Pad2(mn) + ':' + Pad2(sc);
  TextEquSet('@DATE',     predef_date);
  TextEquSet('@TIME',     predef_time);
  { @FILENAME = nom de base sans extension }
  fi := Length(fname);
  While (fi > 0) And (fname[fi] <> '\') And (fname[fi] <> '/') Do Dec(fi);
  fn := Copy(fname, fi+1, Length(fname)-fi);
  fi := Length(fn);
  While (fi > 0) And (fn[fi] <> '.') Do Dec(fi);
  If fi > 0 Then fn := Copy(fn, 1, fi-1);
  TextEquSet('@FILENAME', fn);
End;

{ ============================================================
  LEXER (ANALYSEUR LEXICAL) - IMPLEMENTE
  ============================================================

  Le lexer travaille sur la ligne logique courante (lex_line).
  Quand la ligne est epuisee, il appelle SrcReadLine pour en
  obtenir une nouvelle et retourne TK_NEWLINE en separateur.
  Tous les identificateurs sont convertis en majuscules.
  ============================================================ }

{ ---- Variables du lexer ---- }
Var
  lex_line     : TString;  { copie de la ligne en cours de tokenisation }
  lex_pos      : Integer;  { position courante dans lex_line (1-based) }
  lex_tok      : TToken;   { token courant (rempli par LexNext) }
  lex_peek_tok : TToken;   { token de look-ahead }
  lex_has_peek : Boolean;  { True si lex_peek_tok est valide }
  lex_at_eol   : Boolean;  { True si on doit retourner TK_NEWLINE }

{ ============================================================
  LexUpperCase : convertir une TString en majuscules
  ============================================================ }
Function LexUpperCase(Const s : TString) : TString;
Var
  i   : Integer;
  res : TString;
  c   : Char;
Begin
  res := '';
  For i := 1 To Length(s) Do
  Begin
    c := s[i];
    If (c >= 'a') And (c <= 'z') Then
      res := res + Chr(Ord(c) - 32)
    Else
      res := res + c;
  End;
  LexUpperCase := res;
End;

{ ============================================================
  LexIsAlpha : True si c est une lettre
  ============================================================ }
Function LexIsAlpha(c : Char) : Boolean;
Begin
  LexIsAlpha := ((c >= 'A') And (c <= 'Z')) Or
                ((c >= 'a') And (c <= 'z'));
End;

{ ============================================================
  LexIsDigit : True si c est un chiffre decimal
  ============================================================ }
Function LexIsDigit(c : Char) : Boolean;
Begin
  LexIsDigit := (c >= '0') And (c <= '9');
End;

{ ============================================================
  LexIsHexDigit : True si c est un chiffre hexadecimal
  ============================================================ }
Function LexIsHexDigit(c : Char) : Boolean;
Begin
  LexIsHexDigit := ((c >= '0') And (c <= '9')) Or
                   ((c >= 'A') And (c <= 'F')) Or
                   ((c >= 'a') And (c <= 'f'));
End;

{ ============================================================
  LexIsAlNum : True si c est alphanumerique ou _ ou $
  ============================================================ }
Function LexIsAlNum(c : Char) : Boolean;
Begin
  LexIsAlNum := LexIsAlpha(c) Or LexIsDigit(c) Or
                (c = '_') Or (c = '$') Or (c = '@') Or (c = '?');
End;

{ ============================================================
  LexHexVal : valeur numerique d un chiffre hex (0..15)
  ============================================================ }
Function LexHexVal(c : Char) : Integer;
Begin
  If (c >= '0') And (c <= '9') Then LexHexVal := Ord(c) - Ord('0')
  Else If (c >= 'a') And (c <= 'f') Then LexHexVal := Ord(c) - Ord('a') + 10
  Else LexHexVal := Ord(c) - Ord('A') + 10;
End;

{ ============================================================
  LexInit : initialiser le lexer
  ============================================================ }
Procedure LexInit;
Begin
  lex_line         := '';
  lex_pos          := 1;
  lex_has_peek     := False;
  lex_at_eol       := True; { forcer lecture de la 1ere ligne }
  lex_tok.kind     := TK_EOF;
  lex_tok.val      := '';
  lex_tok.num_val  := 0;
  lex_tok.line_num := 0;
  lex_peek_tok     := lex_tok;
End;

{ ============================================================
  LexSkipSpaces : sauter les espaces dans lex_line
  ============================================================ }
Procedure LexSkipSpaces;
Begin
  While (lex_pos <= Length(lex_line)) And
        (lex_line[lex_pos] = ' ') Do
    Inc(lex_pos);
End;

{ ============================================================
  LexReadNumber : lire un token numerique depuis lex_pos.
  Supporte : 0FFh (hex), 0x1AF (hex), 1010b (binaire),
             777q/777o (octal), 1234 (decimal).
  ============================================================ }
Procedure LexReadNumber(Var tok : TToken);
Var
  raw  : TString;
  suf  : Char;
  v    : TLong;
  i    : Integer;
  c    : Char;
  ok   : Boolean;
Begin
  raw := '';
  { cas 0x... (prefixe hexadecimal style C) }
  If (lex_pos + 1 <= Length(lex_line)) And
     (lex_line[lex_pos] = '0') And
     ((lex_line[lex_pos+1] = 'x') Or (lex_line[lex_pos+1] = 'X')) Then
  Begin
    Inc(lex_pos, 2); { sauter 0x }
    While (lex_pos <= Length(lex_line)) And
          LexIsHexDigit(lex_line[lex_pos]) Do
    Begin
      raw := raw + lex_line[lex_pos];
      Inc(lex_pos);
    End;
    v := 0;
    For i := 1 To Length(raw) Do
      v := v * 16 + LexHexVal(raw[i]);
    tok.kind    := TK_NUMBER;
    tok.val     := '0X' + LexUpperCase(raw);
    tok.num_val := v;
    Exit;
  End;

  { lire tous les alphanumeriques }
  While (lex_pos <= Length(lex_line)) And
        (LexIsHexDigit(lex_line[lex_pos]) Or
         (lex_line[lex_pos] = '_')) Do
  Begin
    raw := raw + lex_line[lex_pos];
    Inc(lex_pos);
  End;
  { lire suffixe eventuel (H B O Q D) }
  suf := ' ';
  If lex_pos <= Length(lex_line) Then
  Begin
    c := lex_line[lex_pos];
    If (c = 'h') Or (c = 'H') Then Begin suf := 'H'; Inc(lex_pos); End
    Else If (c = 'b') Or (c = 'B') Then Begin suf := 'B'; Inc(lex_pos); End
    Else If (c = 'o') Or (c = 'O') Then Begin suf := 'O'; Inc(lex_pos); End
    Else If (c = 'q') Or (c = 'Q') Then Begin suf := 'Q'; Inc(lex_pos); End
    Else If (c = 'd') Or (c = 'D') Then Begin suf := 'D'; Inc(lex_pos); End;
    { si le suffixe est suivi d un car alphanumerique, ce n est pas un nombre }
    If (suf <> ' ') And (lex_pos <= Length(lex_line)) And
       LexIsAlNum(lex_line[lex_pos]) Then
    Begin
      { reculer le suffixe - c etait en fait un identificateur }
      Dec(lex_pos);
      suf := ' ';
    End;
  End;

  v  := 0;
  ok := True;
  Case suf Of
    'H' : Begin
            For i := 1 To Length(raw) Do
            Begin
              If Not LexIsHexDigit(raw[i]) Then Begin ok := False; Break; End;
              v := v * 16 + LexHexVal(raw[i]);
            End;
          End;
    'B' : Begin
            For i := 1 To Length(raw) Do
            Begin
              If (raw[i] <> '0') And (raw[i] <> '1') Then
                Begin ok := False; Break; End;
              v := v * 2 + (Ord(raw[i]) - Ord('0'));
            End;
          End;
    'O','Q' : Begin
            For i := 1 To Length(raw) Do
            Begin
              If (raw[i] < '0') Or (raw[i] > '7') Then
                Begin ok := False; Break; End;
              v := v * 8 + (Ord(raw[i]) - Ord('0'));
            End;
          End;
    Else { decimal (y compris 'D') }
          Begin
            For i := 1 To Length(raw) Do
            Begin
              If Not LexIsDigit(raw[i]) Then
              Begin
                { contient des lettres -> probablement hex sans suffixe ou erreur }
                ok := False;
                Break;
              End;
              v := v * 10 + (Ord(raw[i]) - Ord('0'));
            End;
          End;
  End;
  If Not ok Then
  Begin
    WarnMsg('Litteral numerique invalide : ' + raw);
    v := 0;
  End;
  tok.kind    := TK_NUMBER;
  tok.val     := raw + suf;
  tok.num_val := v;
End;

{ ============================================================
  LexReadString : lire une chaine litterale (delimiteur = q)
  ============================================================ }
Procedure LexReadString(Var tok : TToken; q : Char);
Var
  s : TString;
Begin
  s := '';
  Inc(lex_pos); { sauter le guillemet ouvrant }
  While lex_pos <= Length(lex_line) Do
  Begin
    If lex_line[lex_pos] = q Then
    Begin
      Inc(lex_pos); { sauter le guillemet fermant }
      Break;
    End;
    s := s + lex_line[lex_pos];
    Inc(lex_pos);
  End;
  tok.kind    := TK_STRING;
  tok.val     := s;
  tok.num_val := 0;
End;

{ ============================================================
  LexReadIdent : lire un identificateur ou mot-cle.
  Retourne en MAJUSCULES.
  ============================================================ }
Procedure LexReadIdent(Var tok : TToken);
Var
  s : TString;
Begin
  s := '';
  While (lex_pos <= Length(lex_line)) And
        LexIsAlNum(lex_line[lex_pos]) Do
  Begin
    s := s + lex_line[lex_pos];
    Inc(lex_pos);
  End;
  tok.kind    := TK_IDENT;
  tok.val     := LexUpperCase(s);
  tok.num_val := 0;
End;

{ ============================================================
  LexNextRaw : lire le prochain token depuis lex_line
  (sans gestion du lookahead ni des nouvelles lignes)
  ============================================================ }
Procedure LexNextRaw(Var tok : TToken);
Var
  c : Char;
Begin
  tok.line_num := cur_lineno;
  tok.num_val  := 0;

  LexSkipSpaces;

  If lex_pos > Length(lex_line) Then
  Begin
    tok.kind := TK_NEWLINE;
    tok.val  := '';
    Exit;
  End;

  c := lex_line[lex_pos];

  { --- Nombre --- }
  If LexIsDigit(c) Then
  Begin
    LexReadNumber(tok);
    Exit;
  End;

  { --- Chaine litterale --- }
  If (c = '''') Or (c = '"') Then
  Begin
    LexReadString(tok, c);
    Exit;
  End;

  { --- Identificateur / mot-cle --- }
  If LexIsAlpha(c) Or (c = '_') Or (c = '$') Or (c = '@') Or (c = '?') Then
  Begin
    { un identif peut commencer par une lettre qui ressemble a un hex }
    { SAUF s il commence par un chiffre -> traite ci-dessus }
    LexReadIdent(tok);
    Exit;
  End;

  { --- Directive avec point initial (.CODE .DATA .MODEL .8086 etc.) --- }
  { Si '.' est suivi d une lettre ou d un chiffre : mot-cle MASM }
  If c = '.' Then
  Begin
    If (lex_pos+1 <= Length(lex_line)) And
       (LexIsAlpha(lex_line[lex_pos+1]) Or LexIsDigit(lex_line[lex_pos+1])) Then
    Begin
      Inc(lex_pos);       { skip '.' }
      LexReadIdent(tok);  { lit CODE, DATA, 8086... (LexReadIdent accepte alphanum) }
      tok.val := '.' + tok.val;
      Exit;
    End;
  End;

  { --- Ponctuation et operateurs a 2 caracteres --- }
  Inc(lex_pos);
  tok.kind := TK_PUNCT;
  tok.val  := c;
  { operateurs a deux caracteres }
  If lex_pos <= Length(lex_line) Then
  Begin
    If (c = '<') And (lex_line[lex_pos] = '<') Then
      Begin tok.val := '<<'; Inc(lex_pos); End
    Else If (c = '>') And (lex_line[lex_pos] = '>') Then
      Begin tok.val := '>>'; Inc(lex_pos); End
    Else If (c = '<') And (lex_line[lex_pos] = '>') Then
      Begin tok.val := '<>'; Inc(lex_pos); End
    Else If (c = '=') And (lex_line[lex_pos] = '=') Then
      Begin tok.val := '=='; Inc(lex_pos); End;
  End;
End;

{ ============================================================
  LexNext : avancer d un token (remplir lex_tok).
  Gere les transitions de ligne (TK_NEWLINE) et la fin
  de fichier (TK_EOF).
  ============================================================ }
Procedure LexNext;
Begin
  { consommer le peek s il existe }
  If lex_has_peek Then
  Begin
    lex_tok      := lex_peek_tok;
    lex_has_peek := False;
    Exit;
  End;

  { si on etait a la fin de la ligne logique precedente }
  If lex_at_eol Then
  Begin
    lex_at_eol := False;
    { charger la prochaine ligne logique }
    If Not SrcReadLine Then
    Begin
      lex_tok.kind     := TK_EOF;
      lex_tok.val      := '';
      lex_tok.num_val  := 0;
      lex_tok.line_num := cur_lineno;
      Exit;
    End;
    lex_line := cur_line;
    lex_pos  := 1;
    { retourner un NEWLINE comme separateur entre lignes }
    lex_tok.kind     := TK_NEWLINE;
    lex_tok.val      := '';
    lex_tok.num_val  := 0;
    lex_tok.line_num := cur_lineno;
    Exit;
  End;

  LexNextRaw(lex_tok);

  { si on vient d atteindre la fin de la ligne }
  If lex_tok.kind = TK_NEWLINE Then
    lex_at_eol := True;
End;

{ ============================================================
  LexEnsurePeek : remplir lex_peek_tok si pas encore fait
  ============================================================ }
Procedure LexEnsurePeek;
Var
  saved_tok : TToken;
Begin
  If lex_has_peek Then Exit;
  saved_tok    := lex_tok;
  LexNext;
  lex_peek_tok := lex_tok;
  lex_tok      := saved_tok;
  lex_has_peek := True;
End;

{ ============================================================
  LexPeekKind : type du prochain token (sans le consommer)
  ============================================================ }
Function LexPeekKind : TTokenKind;
Begin
  LexEnsurePeek;
  LexPeekKind := lex_peek_tok.kind;
End;

{ ============================================================
  LexPeekVal : valeur textuelle du prochain token
  ============================================================ }
Function LexPeekVal : TString;
Begin
  LexEnsurePeek;
  LexPeekVal := lex_peek_tok.val;
End;

{ ---- Table des directives pour LexIsDirective ---- }
Const
  LD_COUNT = 117;
  LD_NAMES : Array[1..117] Of String[10] = (
    'ASSUME',  'ALIGN',    'BYTE',    'CODE',     'COMM',
    'COMMENT', 'CONST',    'DATA',    'DB',       'DD',
    'DF',      'DQ',       'DT',      'DW',       'DWORD',
    'ELSE',    'ELSEIF',   'END',     'ENDIF',    'ENDM',
    'ENDP',    'ENDS',     'EQU',     'EVEN',     'EXITM',
    'EXTERN',  'EXTRN',    'FAR',     'FWORD',    'GLOBAL',
    'GROUP',   'IF',       'IF1',     'IF2',      'IFB',
    'IFDEF',   'IFDIF',    'IFIDNI',  'IFIDN',    'IFNB',
    'IFNDEF',  'IFE',      'INCLUDE', 'INCLUDELIB','IRP',
    'IRPC',    'LABEL',    'LENGTH',  'LOCAL',    'MACRO',
    'MOD',     'MODEL',    'NAME',    'NEAR',     'NOT',
    'OFFSET',  'OPTION',   'ORG',     'PAGE',     'PARA',
    'PROC',    'PTR',      'PUBLIC',  'PURGE',    'QWORD',
    'RECORD',  'REPT',     'SBYTE',   'SEG',      'SEGMENT',
    'SHORT',   'SIZE',     'SIZEOF',  'SIZESTR',  'STACK',
    'STRUC',   'STRUCT',   'SUBTTL',  'TBYTE',    'TEXTEQU',
    'TITLE',   'TYPE',     'TYPEDEF', 'UNION',    'USES',
    'WORD',    '.CODE',    '.DATA',   '.MODEL',   '.STACK',
    '.CONST',  '.STARTUP', '.EXIT',   '.LIST',    '.NOLIST',
    '.XLIST',  '.LISTALL', '.RADIX',  '.286',     '.286P',
    '.186',    '.8086',    '.ERR',    '.ERRNZ',   '.ERRE',
    'AND',     'OR',       'XOR',     'SHL',      'SHR',
    'HIGH',    'LOW',      'THIS',    'WIDTH',    'MASK',
    'INVOKE',  'PROTO'
  );

{ ============================================================
  LexIsDirective : True si s est une directive MASM connue
  ============================================================ }
Function LexIsDirective(Const s : TString) : Boolean;
Var i : Integer;
Begin
  For i := 1 To LD_COUNT Do
    If LD_NAMES[i] = s Then Begin LexIsDirective := True; Exit; End;
  LexIsDirective := False;
End;

{ ---- Table des registres pour LexIsRegister ---- }
Const
  LR_COUNT = 23;
  LR_NAMES : Array[1..23] Of String[5] = (
    { 16 bits } 'AX','BX','CX','DX','SI','DI','SP','BP',
    {  8 bits } 'AL','AH','BL','BH','CL','CH','DL','DH',
    { segment } 'CS','DS','ES','SS',
    { speciaux } 'IP','FLAGS','ST'
  );

{ ============================================================
  LexIsRegister : True si s est un nom de registre 8086
  ============================================================ }
Function LexIsRegister(Const s : TString) : Boolean;
Var i : Integer;
Begin
  For i := 1 To LR_COUNT Do
    If LR_NAMES[i] = s Then Begin LexIsRegister := True; Exit; End;
  LexIsRegister := False;
End;

{ ============================================================
  ParseTextequ : name TEXTEQU <text> | expr | reste de ligne
  Stocker la valeur dans la table TEXTEQU.
  Placee ici apres le lexer pour acceder a LexPeekKind etc.
  ============================================================ }
Procedure ParseTextequ(Const name : TSymString);
Var
  val : TString;
Begin
  val := '';
  { format <text> }
  If (LexPeekKind = TK_PUNCT) And (LexPeekVal = '<') Then
  Begin
    LexNext; { consommer '<' }
    While (lex_pos <= Length(lex_line)) And (lex_line[lex_pos] <> '>') Do
    Begin
      val := val + lex_line[lex_pos];
      Inc(lex_pos);
    End;
    If lex_pos <= Length(lex_line) Then Inc(lex_pos); { consommer '>' }
  End
  Else If LexPeekKind = TK_STRING Then
  Begin
    LexNext; val := lex_tok.val;
  End
  Else
  Begin
    { lire le reste de la ligne comme valeur brute }
    While (lex_pos <= Length(lex_line)) And (lex_line[lex_pos] = ' ') Do Inc(lex_pos);
    While lex_pos <= Length(lex_line) Do
    Begin
      val := val + lex_line[lex_pos];
      Inc(lex_pos);
    End;
  End;
  TextEquSet(name, val);
End;

{ ============================================================
  TABLE DES SYMBOLES - IMPLEMENTE
  ============================================================

  Organisation : hash table HASH_SIZE buckets de listes chainees.
  Chaque noeud est un PSymbol alloue sur le tas (New).
  "Index" = pointeur PSymbol (Nil = non trouve).

  Symboles predefinis inseres par SymInit :
    TRUE (-1), FALSE (0), @WORDSIZE (2), @MODEL (0=non defini),
    @CURSEG (0), @DATA (0), @CODE (0), @STACK (0), @FILENAME.

  Flags dans TSymbol.flags :
    bit 0 = is_public   (declare PUBLIC)
    bit 1 = is_extern   (declare EXTRN)
    bit 2 = is_defined  (valeur connue)
    bit 3 = is_redefin  (EQU redefinissable via =)
  ============================================================ }

{ ============================================================
  SymFind : chercher un symbole par nom (uppercase).
  Retourne un PSymbol ou Nil si absent.
  ============================================================ }
Function SymFind(Const name : TSymString) : PSymbol;
Var
  h : Integer;
  p : PSymbol;
Begin
  h := HashName(name);
  p := hash_table[h];
  While p <> Nil Do
  Begin
    If p^.name = name Then
    Begin
      SymFind := p;
      Exit;
    End;
    p := p^.next;
  End;
  SymFind := Nil;
End;

{ ============================================================
  SymEnter : ajouter un nouveau symbole (sans verifier doublon).
  Retourne le PSymbol cree.
  Pour les doublons, appeler SymFind d abord.
  ============================================================ }
Function SymEnter(Const name : TSymString;
                  kind    : TSymKind;
                  seg_idx : Integer;
                  offset  : TWord;
                  size    : TWord) : PSymbol;
Var
  h : Integer;
  p : PSymbol;
Begin
  New(p);
  p^.name    := name;
  p^.kind    := kind;
  p^.seg_idx := seg_idx;
  p^.offset  := offset;
  p^.value   := 0;
  p^.size    := size;
  p^.flags   := 4; { bit 2 = is_defined par defaut }
  { inserer en tete de la chaine de hachage }
  h          := HashName(name);
  p^.next    := hash_table[h];
  hash_table[h] := p;
  Inc(sym_count);
  SymEnter := p;
End;

{ ============================================================
  SymSetValue : fixer la valeur absolue d un symbole
  ============================================================ }
Procedure SymSetValue(p : PSymbol; val : TLong);
Begin
  If p = Nil Then Exit;
  p^.value  := val;
  p^.offset := TWord(val And $FFFF);
  p^.flags  := p^.flags Or 4; { marquer is_defined }
End;

{ ============================================================
  SymSetPublic : marquer un symbole comme PUBLIC
  ============================================================ }
Procedure SymSetPublic(p : PSymbol);
Begin
  If p = Nil Then Exit;
  p^.flags := p^.flags Or 1;
  p^.kind  := SK_PUBLIC;
End;

{ ============================================================
  SymSetExtern : marquer un symbole comme EXTRN
  ============================================================ }
Procedure SymSetExtern(p : PSymbol);
Begin
  If p = Nil Then Exit;
  p^.flags := p^.flags Or 2;
  p^.kind  := SK_EXTERN;
End;

{ ============================================================
  SymLookupOrEnter : retourner le symbole existant ou en creer
  un nouveau de kind SK_UNDEF (reference avant).
  ============================================================ }
Function SymLookupOrEnter(Const name : TSymString) : PSymbol;
Var
  p : PSymbol;
Begin
  p := SymFind(name);
  If p = Nil Then
  Begin
    p := SymEnter(name, SK_UNDEF, 0, 0, 0);
    p^.flags := 0; { SK_UNDEF : pas encore defini }
  End;
  SymLookupOrEnter := p;
End;

{ ============================================================
  SymDefineLabel : definir un label a la position courante.
  En passe 1 : creer ou mettre a jour.
  En passe 2 : verifier coherence (phase error si offset change).
  ============================================================ }
Procedure SymDefineLabel(Const name : TSymString; seg_i : Integer;
                         off : TWord; sz : TWord);
Var
  p : PSymbol;
Begin
  p := SymFind(name);
  If p = Nil Then
  Begin
    p := SymEnter(name, SK_LABEL, seg_i, off, sz);
  End
  Else
  Begin
    If (p^.kind <> SK_UNDEF) And (p^.kind <> SK_LABEL) And
       (p^.kind <> SK_PUBLIC) Then
    Begin
      ErrorMsg('Redefinition de symbole : ' + name);
      Exit;
    End;
    If (pass_num = 2) And (p^.offset <> off) Then
      WarnMsg('Erreur de phase pour : ' + name);
    p^.kind    := SK_LABEL;
    p^.seg_idx := seg_i;
    p^.offset  := off;
    p^.size    := sz;
    p^.flags   := p^.flags Or 4;
  End;
End;

{ ============================================================
  SymCheckUndefined : en passe 2, signaler les SK_UNDEF restants
  ============================================================ }
Procedure SymCheckUndefined;
Var
  i : Integer;
  p : PSymbol;
Begin
  For i := 0 To HASH_SIZE-1 Do
  Begin
    p := hash_table[i];
    While p <> Nil Do
    Begin
      If p^.kind = SK_UNDEF Then
        ErrorMsg('Symbole non defini : ' + p^.name);
      p := p^.next;
    End;
  End;
End;

{ ============================================================
  SymAddPredef : ajouter un symbole predefini (EQU absolu)
  ============================================================ }
Procedure SymAddPredef(Const name : TSymString; val : TLong);
Var
  p : PSymbol;
Begin
  p := SymEnter(name, SK_EQU, 0, 0, 2);
  SymSetValue(p, val);
  p^.flags := p^.flags And Not 8; { non redefinissable }
End;

{ ============================================================
  SymInit : inserer les symboles predefinis MASM
  ============================================================ }
Procedure SymInit;
Var
  p : PSymbol;
Begin
  { constantes booleennes MASM }
  SymAddPredef('TRUE',      -1);
  SymAddPredef('FALSE',      0);
  { informations de modele (mises a jour par .MODEL) }
  SymAddPredef('@MODEL',     0); { 0 = non encore fixe }
  SymAddPredef('@WORDSIZE',  2); { 16-bit par defaut }
  SymAddPredef('@CUR_LINE',  0); { mis a jour ligne par ligne }
  { bases de segments (mises a jour lors de la definition des segments) }
  SymAddPredef('@DATA',      0);
  SymAddPredef('@CODE',      0);
  SymAddPredef('@STACK',     0);
  { symbole de segment courant (mis a jour dynamiquement) }
  p := SymEnter('@CURSEG', SK_EQU, 0, 0, 0);
  p^.value := 0;
  { nom du fichier source : sera mis a jour apres ParseArgs }
  p := SymEnter('@FILENAME', SK_EQU, 0, 0, 0);
  p^.value := 0;
  { @VERSION : numero de version de l assembleur }
  SymAddPredef('@VERSION', 100); { 1.00 encode en entier }
End;

{ ============================================================
  SymDump : afficher la table des symboles (debug / listing)
  ============================================================ }
Procedure SymDump;
Var
  i   : Integer;
  p   : PSymbol;
  kn  : TString;
Begin
  Writeln('--- Table des symboles (', sym_count, ' entrees) ---');
  For i := 0 To HASH_SIZE-1 Do
  Begin
    p := hash_table[i];
    While p <> Nil Do
    Begin
      Case p^.kind Of
        SK_UNDEF  : kn := 'UNDEF ';
        SK_LABEL  : kn := 'LABEL ';
        SK_PUBLIC : kn := 'PUBLIC';
        SK_EXTERN : kn := 'EXTERN';
        SK_EQU    : kn := 'EQU   ';
        SK_GROUP  : kn := 'GROUP ';
        SK_SEG    : kn := 'SEG   ';
        SK_MACRO  : kn := 'MACRO ';
        SK_STRUCT : kn := 'STRUCT';
        Else        kn := '???   ';
      End;
      Writeln('  ', kn, '  seg=', p^.seg_idx:2,
              '  off=', p^.offset:5,
              '  val=', p^.value:8,
              '  ', p^.name);
      p := p^.next;
    End;
  End;
End;

{ ============================================================
  FORMAT .OBJ INTEL OMF (RECORDS DE BASE) - IMPLEMENTE
  ============================================================

  Structure d un record OMF :
    Octet 0   : type du record (ex : 80h = THEADR)
    Octets 1-2: longueur du reste (data + checksum), little-endian
    Octets 3..: donnees
    Dernier   : checksum = 256 - (sum de tous les octets) mod 256

  On construit chaque record dans obj_rec_buf puis on
  l ecrit dans obj_f via ObjEndRecord.

  Table LNAMES : noms de segments/groupes accumules avant
  ecriture du bloc LNAMES, index 1-base.
  ============================================================ }

{ ---- Constantes des types de records OMF ---- }
Const
  OMF_THEADR  = $80; { nom du module source }
  OMF_COMENT  = $88; { commentaire }
  OMF_MODEND  = $8A; { fin du module }
  OMF_EXTDEF  = $8C; { symboles externes }
  OMF_PUBDEF  = $90; { symboles publics }
  OMF_LNAMES  = $96; { liste de noms (segments/groupes) }
  OMF_SEGDEF  = $98; { definition de segment }
  OMF_GRPDEF  = $9A; { definition de groupe }
  OMF_FIXUPP  = $9C; { corrections d adresse }
  OMF_LEDATA  = $A0; { donnees locales }
  OMF_LIDATA  = $A2; { donnees iterees (blocs repetes) }
  OMF_COMDEF  = $B0; { variables communes }

  OBJ_REC_MAX = 1024; { taille max des donnees d un record }
  LNAMES_MAX  = 128;  { max de noms dans la table LNAMES }

{ ---- Variables OBJ ---- }
Var
  obj_f        : File;          { fichier .OBJ en sortie }
  obj_is_open  : Boolean;       { True si obj_f est ouvert }
  obj_rec_buf  : Array[0..OBJ_REC_MAX-1] Of Byte; { buffer record courant }
  obj_rec_type : Byte;          { type du record en cours }
  obj_rec_pos  : Integer;       { position courante dans obj_rec_buf }

  { Table LNAMES - noms de segments et de groupes }
  lnames_table : Array[1..LNAMES_MAX] Of TSymString;
  lnames_count : Integer; { nombre de noms enregistres (index 1-base) }

{ ============================================================
  ObjWriteByte : ecrire un octet directement dans obj_f
  ============================================================ }
Procedure ObjWriteByte(b : Byte);
Begin
  If Not obj_is_open Then Exit;
  BlockWrite(obj_f, b, 1);
End;

{ ============================================================
  ObjBeginRecord : commencer un nouveau record OMF
  ============================================================ }
Procedure ObjBeginRecord(rtype : Byte);
Begin
  obj_rec_type := rtype;
  obj_rec_pos  := 0;
End;

{ ============================================================
  ObjPutByte : ajouter un octet au buffer du record courant
  ============================================================ }
Procedure ObjPutByte(b : Byte);
Begin
  If obj_rec_pos < OBJ_REC_MAX Then
  Begin
    obj_rec_buf[obj_rec_pos] := b;
    Inc(obj_rec_pos);
  End
  Else
    ErrorMsg('Record OMF trop grand (max 1024 octets de donnees)');
End;

{ ============================================================
  ObjPutWord : ajouter un mot 16 bits (little-endian)
  ============================================================ }
Procedure ObjPutWord(w : TWord);
Begin
  ObjPutByte(Byte(w And $FF));
  ObjPutByte(Byte((w Shr 8) And $FF));
End;

{ ============================================================
  ObjPutDWord : ajouter un double-mot 32 bits (little-endian)
  ============================================================ }
Procedure ObjPutDWord(d : TLong);
Begin
  ObjPutByte(Byte(d And $FF));
  ObjPutByte(Byte((d Shr 8) And $FF));
  ObjPutByte(Byte((d Shr 16) And $FF));
  ObjPutByte(Byte((d Shr 24) And $FF));
End;

{ ============================================================
  ObjPutStr : ajouter une chaine pascal (longueur + octets)
  ============================================================ }
Procedure ObjPutStr(Const s : TString);
Var
  i : Integer;
Begin
  ObjPutByte(Length(s));
  For i := 1 To Length(s) Do
    ObjPutByte(Ord(s[i]));
End;

{ ============================================================
  ObjPutIndex : encoder un index OMF (1 ou 2 octets)
    index < 128  -> 1 octet
    index >= 128 -> 2 octets (bit 7 du premier = 1)
  ============================================================ }
Procedure ObjPutIndex(idx : Integer);
Begin
  If idx < 128 Then
    ObjPutByte(Byte(idx))
  Else
  Begin
    ObjPutByte(Byte($80 Or ((idx Shr 8) And $7F)));
    ObjPutByte(Byte(idx And $FF));
  End;
End;

{ ============================================================
  ObjEndRecord : finaliser et ecrire le record dans obj_f
  Calcule la longueur et le checksum, puis ecrit tout.
  ============================================================ }
Procedure ObjEndRecord;
Var
  len    : Integer; { longueur des donnees + 1 (checksum) }
  sum    : Integer;
  i      : Integer;
  lo, hi : Byte;
  cksum  : Byte;
Begin
  If Not obj_is_open Then Exit;
  len := obj_rec_pos + 1; { +1 pour l octet de checksum }
  lo  := Byte(len And $FF);
  hi  := Byte((len Shr 8) And $FF);
  { calcul du checksum : somme de tous les octets du record }
  sum := obj_rec_type + lo + hi;
  For i := 0 To obj_rec_pos - 1 Do
    sum := sum + obj_rec_buf[i];
  cksum := Byte((256 - (sum And $FF)) And $FF);
  { ecriture : type + longueur + donnees + checksum }
  ObjWriteByte(obj_rec_type);
  ObjWriteByte(lo);
  ObjWriteByte(hi);
  For i := 0 To obj_rec_pos - 1 Do
    ObjWriteByte(obj_rec_buf[i]);
  ObjWriteByte(cksum);
End;

{ ============================================================
  ObjOpen : ouvrir le fichier .OBJ en sortie
  ============================================================ }
Procedure ObjOpen(Const fname : TString);
Begin
  Assign(obj_f, fname);
  {$I-}
  Rewrite(obj_f, 1);
  {$I+}
  If IoResult <> 0 Then
  Begin
    ErrorMsg('Impossible de creer le fichier OBJ : ' + fname);
    obj_is_open := False;
    Exit;
  End;
  obj_is_open := True;
  lnames_count := 0;
End;

{ ============================================================
  ObjClose : fermer le fichier .OBJ
  ============================================================ }
Procedure ObjClose;
Begin
  If obj_is_open Then
  Begin
    Close(obj_f);
    obj_is_open := False;
  End;
End;

{ ============================================================
  ObjInit : initialiser les variables OBJ
  ============================================================ }
Procedure ObjInit;
Begin
  obj_is_open  := False;
  obj_rec_type := 0;
  obj_rec_pos  := 0;
  lnames_count := 0;
End;

{ --- Records OMF de haut niveau --- }

{ ============================================================
  ObjTHEADR : ecrire le record THEADR (nom de module)
  ============================================================ }
Procedure ObjTHEADR(Const module_name : TString);
Begin
  ObjBeginRecord(OMF_THEADR);
  ObjPutStr(module_name);
  ObjEndRecord;
End;

{ ============================================================
  ObjCOMENT : ecrire un record COMENT
    attr      : attribut (80h = non-listable non-purgeable)
    com_class : classe de commentaire (0 = texte general)
    text      : texte du commentaire
  ============================================================ }
Procedure ObjCOMENT(attr : Byte; com_class : Byte; Const text : TString);
Var
  i : Integer;
Begin
  ObjBeginRecord(OMF_COMENT);
  ObjPutByte(attr);
  ObjPutByte(com_class);
  For i := 1 To Length(text) Do
    ObjPutByte(Ord(text[i]));
  ObjEndRecord;
End;

{ ============================================================
  ObjMODEND : ecrire le record MODEND
    is_main   : True si ce module contient le point d entree
    seg_idx   : index SEGDEF du segment de depart (0 si aucun)
    start_off : offset du point d entree dans le segment
  ============================================================ }
Procedure ObjMODEND(is_main : Boolean; seg_idx : Integer; start_off : TWord);
Begin
  ObjBeginRecord(OMF_MODEND);
  If is_main And (seg_idx > 0) Then
  Begin
    ObjPutByte($C1);          { bit 7 = main module, bit 6 = entry present }
    ObjPutByte($00);          { FRAME: segment (00h) }
    ObjPutIndex(seg_idx);     { index SEGDEF cible }
    ObjPutByte($00);          { TARGET: segment (00h) }
    ObjPutIndex(seg_idx);
    ObjPutWord(start_off);
  End
  Else If is_main Then
  Begin
    ObjPutByte($80);          { main module, pas d entry explicite }
  End
  Else
  Begin
    ObjPutByte($00);          { module secondaire }
  End;
  ObjEndRecord;
End;

{ ============================================================
  LNamesRegister : enregistrer un nom dans la table LNAMES
  et retourner son index 1-base. Si deja present, retourner
  l index existant.
  ============================================================ }
Function LNamesRegister(Const name : TSymString) : Integer;
Var
  i : Integer;
Begin
  { chercher si deja enregistre }
  For i := 1 To lnames_count Do
    If lnames_table[i] = name Then
    Begin
      LNamesRegister := i;
      Exit;
    End;
  { ajouter }
  If lnames_count < LNAMES_MAX Then
  Begin
    Inc(lnames_count);
    lnames_table[lnames_count] := name;
    LNamesRegister := lnames_count;
  End
  Else
  Begin
    ErrorMsg('Table LNAMES pleine (max ' +
             Chr(Ord('0') + LNAMES_MAX Div 100) +
             Chr(Ord('0') + (LNAMES_MAX Div 10) Mod 10) +
             Chr(Ord('0') + LNAMES_MAX Mod 10) + ' noms)');
    LNamesRegister := 1;
  End;
End;

{ ============================================================
  ObjLNAMES : ecrire le record LNAMES avec tous les noms
  accumules dans lnames_table[1..lnames_count].
  Un seul record suffit en general pour les petits modules.
  ============================================================ }
Procedure ObjLNAMES;
Var
  i : Integer;
Begin
  If lnames_count = 0 Then Exit;
  ObjBeginRecord(OMF_LNAMES);
  For i := 1 To lnames_count Do
    ObjPutStr(lnames_table[i]);
  ObjEndRecord;
End;

{ ============================================================
  ObjSEGDEF : ecrire un record SEGDEF pour un segment.
    align_byte : 0=abs,1=byte,2=word,3=para,4=page,5=dword
    combine    : 0=private,2=public,5=stack,6=common
    seg_size   : taille en octets du segment
    seg_name_i : index LNAMES du nom de segment
    cls_name_i : index LNAMES de la classe
    ovl_name_i : index LNAMES du nom du groupe d overlay (0)
  ============================================================ }
Procedure ObjSEGDEF(align_byte : Byte; combine : Byte;
                    seg_size : TWord;
                    seg_name_i : Integer; cls_name_i : Integer;
                    ovl_name_i : Integer);
Var
  acbp : Byte;
Begin
  ObjBeginRecord(OMF_SEGDEF);
  { ACBP : A(3bits) C(3bits) B(1bit) P(1bit) }
  { A = alignment : 1=byte 2=word 3=para 4=page 5=dword }
  { C = combine   : 0=private 2=public 5=stack 6=common }
  { B = big (seg_size=0 means 64K) }
  { P = USE16 (0) / USE32 (1) }
  acbp := ((align_byte And $07) Shl 5) Or
          ((combine    And $07) Shl 2) Or
          $00; { B=0, P=0 = USE16 }
  ObjPutByte(acbp);
  ObjPutWord(seg_size);    { taille du segment }
  ObjPutIndex(seg_name_i); { nom du segment }
  ObjPutIndex(cls_name_i); { classe }
  ObjPutIndex(ovl_name_i); { overlay name (0 = none) }
  ObjEndRecord;
End;

{ ============================================================
  ObjGRPDEF : ecrire un record GRPDEF
    grp_name_i : index LNAMES du nom de groupe (ex: DGROUP)
    seg_indices: tableau d indices SEGDEF des membres
    seg_count  : nombre de membres
  ============================================================ }
Procedure ObjGRPDEF(grp_name_i : Integer;
                    Var seg_indices : Array Of Integer;
                    seg_cnt : Integer);
Var
  i : Integer;
Begin
  ObjBeginRecord(OMF_GRPDEF);
  ObjPutIndex(grp_name_i);
  For i := 0 To seg_cnt - 1 Do
  Begin
    ObjPutByte($FF);               { composant = segment }
    ObjPutIndex(seg_indices[i]);   { index SEGDEF }
  End;
  ObjEndRecord;
End;

{ ============================================================
  ObjEXTDEF : ecrire un record EXTDEF pour un symbole externe
    ext_name : nom du symbole externe
    type_idx : index de type (0 = non specifie)
  ============================================================ }
Procedure ObjEXTDEF(Const ext_name : TString; type_idx : Integer);
Begin
  ObjBeginRecord(OMF_EXTDEF);
  ObjPutStr(ext_name);
  ObjPutIndex(type_idx);
  ObjEndRecord;
End;

{ ============================================================
  ObjPUBDEF : ecrire un record PUBDEF pour un symbole public
    base_grp_i : index GRPDEF de base (0 si aucun)
    base_seg_i : index SEGDEF du segment contenant le symbole
    pub_name   : nom du symbole public
    pub_offset : offset dans le segment
    type_idx   : index de type (0 = non specifie)
  ============================================================ }
Procedure ObjPUBDEF(base_grp_i : Integer; base_seg_i : Integer;
                    Const pub_name : TString;
                    pub_offset : TWord; type_idx : Integer);
Begin
  ObjBeginRecord(OMF_PUBDEF);
  ObjPutIndex(base_grp_i); { groupe de base (0 si aucun) }
  ObjPutIndex(base_seg_i); { segment de base }
  If base_seg_i = 0 Then
    ObjPutWord(0);          { base frame (segment absolu seulement) }
  ObjPutStr(pub_name);
  ObjPutWord(pub_offset);
  ObjPutIndex(type_idx);
  ObjEndRecord;
End;

{ ============================================================
  FORMAT .OBJ INTEL OMF (DONNEES ET FIXUPS) - IMPLEMENTE
  ============================================================

  Gestion du buffer LEDATA :
    - Chaque segment possede un buffer de donnees (max 1024 o.).
    - FlushLEDATA : ecrit le buffer courant sous forme de record
      LEDATA, puis vide le buffer. Appele automatiquement quand
      le buffer est plein ou en fin d assemblage.
    - EmitByte/EmitWord/EmitDWord : ajouter un octet/mot/dword
      au segment courant (avec flush automatique si necessaire).

  Gestion des fixups :
    - Table de fixups internes (tableau fixup_table).
    - Chaque fixup memorise : offset dans LEDATA, type, et
      l index du symbole cible (SEGDEF ou EXTDEF).
    - ObjFIXUPP : serialise la table en records FIXUPP OMF.
  ============================================================ }

{ ---- Types et constantes pour les fixups ---- }
Const
  FIXUP_OFFSET  = 0; { relocation 16-bit offset dans segment }
  FIXUP_SEG     = 1; { relocation 16-bit valeur de segment }
  FIXUP_SHORT   = 2; { relocation 8-bit deplacement court (Jcc) }
  FIXUP_FAR     = 3; { relocation 32-bit seg:off (FAR PTR) }

  FIXUP_TARGET_SEG = 0; { cible = index SEGDEF }
  FIXUP_TARGET_EXT = 1; { cible = index EXTDEF }
  FIXUP_TARGET_GRP = 2; { cible = index GRPDEF }

{ Buffer LEDATA par segment }
Const
  LEDATA_BUF_MAX = 1020; { max octets de donnees par record LEDATA }

Type
  TFixupRec = Record
    ledata_offset : TWord;    { offset de l octet a patcher dans le LEDATA }
    fix_type      : Byte;     { FIXUP_OFFSET / FIXUP_SEG / FIXUP_SHORT / FIXUP_FAR }
    target_kind   : Byte;     { FIXUP_TARGET_SEG / EXT / GRP }
    target_idx    : Integer;  { index SEGDEF, EXTDEF ou GRPDEF (1-base) }
    displacement  : TWord;    { deplacement ajoute a la cible }
    is_seg_rel    : Boolean;  { True = relatif au segment (SELFREL=0), False = non }
  End;
  TFixupTable = Array[0..MAX_FIXUP-1] Of TFixupRec;
  PFixupTable  = ^TFixupTable;

Var
  { Buffer LEDATA courant }
  ledata_buf     : Array[0..LEDATA_BUF_MAX-1] Of Byte;
  ledata_buf_len : Integer;    { nb d octets dans le buffer }
  ledata_seg_idx : Integer;    { index SEGDEF du segment courant dans le buffer }
  ledata_start   : TWord;      { offset de debut du buffer dans le segment }

  { Table de fixups internes (allouee sur le tas via FixupInit) }
  fixup_table    : PFixupTable;
  fixup_count    : Integer;

{ ============================================================
  FixupInit : vider la table de fixups
  ============================================================ }
Procedure FixupInit;
Begin
  If fixup_table = Nil Then New(fixup_table);
  fixup_count    := 0;
  ledata_buf_len := 0;
  ledata_seg_idx := 0;
  ledata_start   := 0;
End;

{ ============================================================
  ObjFIXUPP : ecrire les fixups accumules dans fixup_table
  en un ou plusieurs records FIXUPP OMF.
  Format simplifie : un fixup explicite par entree.
  ============================================================ }
Procedure ObjFIXUPP;
Var
  i      : Integer;
  locat  : TWord;
  fixdat : Byte;
  fr     : TFixupRec;
Begin
  If fixup_count = 0 Then Exit;
  ObjBeginRecord(OMF_FIXUPP);
  For i := 0 To fixup_count - 1 Do
  Begin
    fr := fixup_table^[i];
    { LOCAT word :
        bit 15     = 1 (c est un Fixup, pas un Thread)
        bit 14     = 1 si SEGREL, 0 si SELFREL
        bits 13-10 = Location type :
                       0=lobyte, 1=offset16, 2=base, 3=pointer32
                       4=offset8 (SHORT), 5=loffset16
        bits 9-0   = data record offset de l octet dans le LEDATA }
    locat := $8000; { bit 15 = fixup }
    If fr.is_seg_rel Then
      locat := locat Or $4000;
    Case fr.fix_type Of
      FIXUP_SHORT  : locat := locat Or ($0 Shl 10); { lobyte = 0 }
      FIXUP_OFFSET : locat := locat Or ($1 Shl 10); { offset16 = 1 }
      FIXUP_SEG    : locat := locat Or ($2 Shl 10); { base16 = 2 }
      FIXUP_FAR    : locat := locat Or ($3 Shl 10); { pointer32 = 3 }
    End;
    locat := locat Or (fr.ledata_offset And $03FF);
    ObjPutWord(locat);
    { FIXDAT :
        bits 7-4 = F T (frame/target thread + method)
        F=0, frame_method=0 (segment index), T=0, target_method=0 (SEGDEF)
        si T=1, target_method=2 (EXTDEF) }
    fixdat := $00;
    Case fr.target_kind Of
      FIXUP_TARGET_SEG : fixdat := $00;  { target = SEGDEF }
      FIXUP_TARGET_GRP : fixdat := $01;  { target = GRPDEF }
      FIXUP_TARGET_EXT : fixdat := $02;  { target = EXTDEF }
    End;
    If fr.displacement = 0 Then
      fixdat := fixdat Or $04; { bit 2 = P : pas de champ displacement }
    ObjPutByte(fixdat);
    ObjPutIndex(fr.target_idx);
    If fr.displacement <> 0 Then
      ObjPutWord(fr.displacement);
  End;
  ObjEndRecord;
  fixup_count := 0;
End;

{ ============================================================
  FlushLEDATA : ecrire le buffer LEDATA courant en un record
  OMF, puis les fixups associes, et remettre le buffer a zero.
  ============================================================ }
Procedure FlushLEDATA;
Var
  i : Integer;
Begin
  If (ledata_buf_len = 0) Or (Not obj_is_open) Then Exit;
  ObjBeginRecord(OMF_LEDATA);
  ObjPutIndex(ledata_seg_idx);
  ObjPutWord(ledata_start);
  For i := 0 To ledata_buf_len - 1 Do
    ObjPutByte(ledata_buf[i]);
  ObjEndRecord;
  { ecrire les fixups correspondant a ce bloc de donnees }
  ObjFIXUPP;
  { avancer le pointeur de debut }
  ledata_start   := ledata_start + TWord(ledata_buf_len);
  ledata_buf_len := 0;
End;

{ ============================================================
  EmitByte : emettre un octet dans le segment courant
  ============================================================ }
Procedure EmitByte(b : Byte);
Begin
  { En passe 1, avancer uniquement le LC sans ecrire dans le buffer }
  If no_emit Then
  Begin
    Inc(lc);
    If (cur_seg >= 1) And (cur_seg <= MAX_SEG) Then
    Begin
      Inc(seg_table[cur_seg].cur_lc);
      If seg_table[cur_seg].cur_lc > seg_table[cur_seg].size Then
        seg_table[cur_seg].size := seg_table[cur_seg].cur_lc;
    End;
    Exit;
  End;
  { Collecte pour le listing (passe 2 uniquement) }
  If do_listing And lst_active And (lst_nbytes < 256) Then
  Begin
    lst_bytes[lst_nbytes] := b;
    Inc(lst_nbytes);
  End;
  If ledata_buf_len >= LEDATA_BUF_MAX Then
    FlushLEDATA;
  ledata_buf[ledata_buf_len] := b;
  Inc(ledata_buf_len);
  { mettre a jour le LC global }
  Inc(lc);
  { mettre a jour la taille du segment courant }
  If (cur_seg >= 1) And (cur_seg <= MAX_SEG) Then
  Begin
    If seg_table[cur_seg].cur_lc > seg_table[cur_seg].size Then
      seg_table[cur_seg].size := seg_table[cur_seg].cur_lc;
    Inc(seg_table[cur_seg].cur_lc);
    If seg_table[cur_seg].cur_lc > seg_table[cur_seg].size Then
      seg_table[cur_seg].size := seg_table[cur_seg].cur_lc;
  End;
End;

{ ============================================================
  EmitWord : emettre un mot 16 bits (little-endian)
  ============================================================ }
Procedure EmitWord(w : TWord);
Begin
  EmitByte(Byte(w And $FF));
  EmitByte(Byte((w Shr 8) And $FF));
End;

{ ============================================================
  EmitDWord : emettre un double-mot 32 bits (little-endian)
  ============================================================ }
Procedure EmitDWord(d : TLong);
Begin
  EmitByte(Byte(d And $FF));
  EmitByte(Byte((d Shr 8) And $FF));
  EmitByte(Byte((d Shr 16) And $FF));
  EmitByte(Byte((d Shr 24) And $FF));
End;

{ ============================================================
  EmitZeros : emettre n octets nuls (BSS, DUP(0))
  ============================================================ }
Procedure EmitZeros(n : Integer);
Var
  i : Integer;
Begin
  For i := 1 To n Do
    EmitByte(0);
End;

{ ============================================================
  GenFixup : enregistrer un fixup dans fixup_table.
    fix_type    : FIXUP_OFFSET / FIXUP_SEG / FIXUP_SHORT / FIXUP_FAR
    target_kind : FIXUP_TARGET_SEG / EXT / GRP
    target_idx  : index 1-base de la cible
    disp        : deplacement additionnel
    seg_rel     : True = correction par rapport au segment courant
  ============================================================ }
Procedure GenFixup(fix_type : Byte; target_kind : Byte;
                   target_idx : Integer; disp : TWord;
                   seg_rel : Boolean);
Var
  fr : TFixupRec;
Begin
  If fixup_count >= MAX_FIXUP Then
  Begin
    ErrorMsg('Table de fixups interne pleine - FlushLEDATA avant GenFixup');
    Exit;
  End;
  { l offset dans le LEDATA est la position courante du buffer }
  fr.ledata_offset := TWord(ledata_buf_len);
  fr.fix_type      := fix_type;
  fr.target_kind   := target_kind;
  fr.target_idx    := target_idx;
  fr.displacement  := disp;
  fr.is_seg_rel    := seg_rel;
  fixup_table^[fixup_count] := fr;
  Inc(fixup_count);
End;

{ ============================================================
  ObjLIDATA : emettre un record LIDATA (donnees repetees)
  Utile pour : label DB n DUP(val)
    seg_i   : index SEGDEF
    offset  : offset de debut dans le segment
    repeat_count : nombre de repetitions
    data    : octets a repeter
    data_len: longueur du bloc de base
  ============================================================ }
Procedure ObjLIDATA(seg_i : Integer; off : TWord;
                    repeat_count : TWord;
                    Var data : Array Of Byte; data_len : Integer);
Var
  i : Integer;
Begin
  { s assurer que le buffer LEDATA precedent est vide }
  FlushLEDATA;
  ObjBeginRecord(OMF_LIDATA);
  ObjPutIndex(seg_i);
  ObjPutWord(off);
  { bloc LIDATA : repeat_count + block_count(=0) + literal }
  ObjPutWord(repeat_count);
  ObjPutWord(0);          { block_count = 0 : c est un literal }
  ObjPutByte(Byte(data_len)); { taille du literal }
  For i := 0 To data_len - 1 Do
    ObjPutByte(data[i]);
  ObjEndRecord;
End;

{ ============================================================
  SetSeg : changer le segment courant (flush LEDATA en cours)
  ============================================================ }
Procedure SetSeg(new_seg : Integer);
Begin
  If new_seg = cur_seg Then Exit;
  { sauvegarder le LEDATA du segment precedent }
  FlushLEDATA;
  cur_seg        := new_seg;
  ledata_seg_idx := new_seg;
  If (new_seg >= 1) And (new_seg <= MAX_SEG) Then
  Begin
    lc             := seg_table[new_seg].cur_lc;
    ledata_start   := lc;
  End
  Else
  Begin
    lc           := 0;
    ledata_start := 0;
  End;
  ledata_buf_len := 0;
End;

{ ============================================================
  GESTION DES SEGMENTS ET DES MODELES MEMOIRE - IMPLEMENTE
  ============================================================

  Modeles memoire supportes (directive .MODEL) :
    TINY    : CS=DS=SS, tout dans un segment, .COM target
    SMALL   : CS=_TEXT, DS=SS=DGROUP (_DATA+_BSS)
    COMPACT : CS=_TEXT, DS multiples, SS=DGROUP
    MEDIUM  : CS multiples, DS=SS=DGROUP
    LARGE   : CS et DS multiples
    HUGE    : idem LARGE + tableaux > 64K

  Segments standards crees automatiquement :
    _TEXT  : code  (align WORD,  combine PUBLIC, classe 'CODE')
    _DATA  : data  (align WORD,  combine PUBLIC, classe 'DATA')
    _BSS   : bss   (align WORD,  combine PUBLIC, classe 'BSS')
    STACK  : pile  (align PARA,  combine STACK,  classe 'STACK')
    CONST  : cst   (align WORD,  combine PUBLIC, classe 'CONST')
    DGROUP : groupe = _DATA + _BSS + CONST + STACK
  ============================================================ }

{ ---- Variables du modele memoire ---- }
Var
  mem_model   : Integer;  { 0=none,1=TINY,2=SMALL,3=COMPACT,4=MEDIUM,5=LARGE,6=HUGE }
  model_name  : TString;  { nom textuel du modele }
  call_far    : Boolean;  { True si CALL FAR par defaut (MEDIUM/LARGE/HUGE) }
  data_far    : Boolean;  { True si DATA FAR par defaut (COMPACT/LARGE/HUGE) }

  { Indices des segments standards dans seg_table (0 = non defini) }
  seg_idx_text  : Integer;
  seg_idx_data  : Integer;
  seg_idx_bss   : Integer;
  seg_idx_stack : Integer;
  seg_idx_const : Integer;
  grp_idx_dgroup: Integer; { index dans grp_table du groupe DGROUP }

  { ASSUME : association registre/segment (index seg_table, 0=NOTHING) }
  assume_cs      : Integer;  { index seg_table ou grp_table }
  assume_ds      : Integer;
  assume_ss      : Integer;
  assume_es      : Integer;
  assume_cs_is_grp : Boolean; { True si assume_cs pointe dans grp_table }
  assume_ds_is_grp : Boolean;
  assume_ss_is_grp : Boolean;
  assume_es_is_grp : Boolean;

  { Pile SEGMENT/ENDS ouverts }
  seg_open_stack : Array[0..8] Of Integer; { indices seg_table }
  seg_open_top   : Integer;  { -1 = aucun }

{ ============================================================
  SegFind : chercher un segment par nom. Retourne l index (1-base)
  dans seg_table ou 0 si non trouve.
  ============================================================ }
Function SegFind(Const name : TSymString) : Integer;
Var
  i : Integer;
Begin
  For i := 1 To seg_count Do
    If seg_table[i].name = name Then
    Begin
      SegFind := i;
      Exit;
    End;
  SegFind := 0;
End;

{ ============================================================
  SegEnter : definir un nouveau segment. Retourne l index 1-base.
  Si le segment existe deja, retourner son index sans creer.
  ============================================================ }
Function SegEnter(Const sname : TSymString; Const scls : TSymString;
                  comb : TSegCombine; aln : TSegAlign) : Integer;
Var
  idx  : Integer;
  p    : PSymbol;
  uname : TSymString;
Begin
  uname := LexUpperCase(sname);
  idx := SegFind(uname);
  If idx > 0 Then
  Begin
    SegEnter := idx;
    Exit;
  End;
  If seg_count >= MAX_SEG Then
  Begin
    ErrorMsg('Trop de segments');
    SegEnter := 1;
    Exit;
  End;
  Inc(seg_count);
  seg_table[seg_count].name       := uname;
  seg_table[seg_count].class_name := LexUpperCase(scls);
  seg_table[seg_count].combine    := comb;
  seg_table[seg_count].align      := aln;
  seg_table[seg_count].size       := 0;
  seg_table[seg_count].cur_lc     := 0;
  seg_table[seg_count].defined    := True;
  seg_table[seg_count].lnames_idx := LNamesRegister(uname);
  If scls <> '' Then
    LNamesRegister(LexUpperCase(scls));
  { creer un symbole de type SK_SEG dans la table des symboles }
  p := SymFind(uname);
  If p = Nil Then
  Begin
    p := SymEnter(uname, SK_SEG, seg_count, 0, 0);
    SymSetValue(p, 0);
  End;
  SegEnter := seg_count;
End;

{ ============================================================
  GrpEnter : definir ou trouver un groupe. Retourne l index (1-base).
  ============================================================ }
Function GrpEnter(Const name : TSymString) : Integer;
Var
  i   : Integer;
  p   : PSymbol;
Begin
  For i := 1 To grp_count Do
    If grp_table[i].name = name Then
    Begin
      GrpEnter := i;
      Exit;
    End;
  If grp_count >= MAX_GRP Then
  Begin
    ErrorMsg('Trop de groupes (max ' +
             Chr(Ord('0') + MAX_GRP) + ')');
    GrpEnter := 1;
    Exit;
  End;
  Inc(grp_count);
  With grp_table[grp_count] Do
  Begin
    name      := name;
    seg_count := 0;
    defined   := True;
  End;
  LNamesRegister(name);
  p := SymFind(name);
  If p = Nil Then
  Begin
    p := SymEnter(name, SK_GROUP, 0, 0, 0);
    SymSetValue(p, 0);
  End;
  GrpEnter := grp_count;
End;

{ ============================================================
  GrpAddSeg : ajouter un segment a un groupe
  ============================================================ }
Procedure GrpAddSeg(grp_i : Integer; seg_i : Integer);
Var
  j : Integer;
Begin
  If (grp_i < 1) Or (grp_i > grp_count) Then Exit;
  With grp_table[grp_i] Do
  Begin
    { verifier si deja present }
    For j := 1 To seg_count Do
      If segs[j] = seg_i Then Exit;
    If seg_count < MAX_SEG Then
    Begin
      Inc(seg_count);
      segs[seg_count] := seg_i;
    End;
  End;
End;

{ ============================================================
  SegGetGroup : retourner l index de groupe (1-base dans grp_table)
  qui contient le segment seg_i, ou 0 si aucun.
  ============================================================ }
Function SegGetGroup(seg_i : Integer) : Integer;
Var
  gi : Integer;
  gj : Integer;
Begin
  SegGetGroup := 0;
  If seg_i <= 0 Then Exit;
  For gi := 1 To grp_count Do
    For gj := 1 To grp_table[gi].seg_count Do
      If grp_table[gi].segs[gj] = seg_i Then
      Begin
        SegGetGroup := gi;
        Exit;
      End;
End;

{ ============================================================
  ParseGroup : nom GROUP seg1 [, seg2 ...]
  Directive GROUP : regrouper plusieurs segments.
  name = nom du groupe (deja lu comme label_name avant GROUP).
  ============================================================ }
Procedure ParseGroup(Const name : TString);
Var
  gi   : Integer;
  sn   : TString;
  si   : Integer;
Begin
  gi := GrpEnter(LexUpperCase(name));
  { lire la liste des segments : seg1 [, seg2 ...] }
  While LexPeekKind = TK_IDENT Do
  Begin
    LexNext;
    sn := LexUpperCase(lex_tok.val);
    si := SegFind(sn);
    If si = 0 Then
    Begin
      { segment pas encore defini : le creer (sera rempli plus tard) }
      si := SegEnter(sn, '', SC_PUBLIC, SA_PARA);
    End;
    GrpAddSeg(gi, si);
    { consommer la virgule optionnelle }
    If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ',') Then LexNext;
  End;
End;

{ ============================================================
  ModelInit : initialiser les variables de modele
  ============================================================ }
Procedure ModelInit;
Begin
  mem_model      := 0;
  model_name     := '';
  call_far       := False;
  data_far       := False;
  seg_idx_text   := 0;
  seg_idx_data   := 0;
  seg_idx_bss    := 0;
  seg_idx_stack  := 0;
  seg_idx_const  := 0;
  grp_idx_dgroup := 0;
  assume_cs        := 0;
  assume_ds        := 0;
  assume_ss        := 0;
  assume_es        := 0;
  assume_cs_is_grp := False;
  assume_ds_is_grp := False;
  assume_ss_is_grp := False;
  assume_es_is_grp := False;
  seg_open_top   := -1;
End;

{ ============================================================
  ParseModel : traiter la directive .MODEL nom
  Cree les segments standards et le groupe DGROUP.
  ============================================================ }
Procedure ParseModel(Const mname : TString);
Begin
  model_name := LexUpperCase(mname);
  call_far   := False;
  data_far   := False;
  If model_name = 'TINY'    Then mem_model := 1
  Else If model_name = 'SMALL'   Then mem_model := 2
  Else If model_name = 'COMPACT' Then Begin mem_model := 3; data_far := True; End
  Else If model_name = 'MEDIUM'  Then Begin mem_model := 4; call_far := True; End
  Else If model_name = 'LARGE'   Then Begin mem_model := 5; call_far := True; data_far := True; End
  Else If model_name = 'HUGE'    Then Begin mem_model := 6; call_far := True; data_far := True; End
  Else
  Begin
    ErrorMsg('Modele memoire inconnu : ' + mname);
    mem_model := 2; { defaut SMALL }
  End;

  { creer les segments standards }
  seg_idx_text  := SegEnter('_TEXT',  'CODE',  SC_PUBLIC, SA_WORD);
  seg_idx_data  := SegEnter('_DATA',  'DATA',  SC_PUBLIC, SA_WORD);
  seg_idx_bss   := SegEnter('_BSS',   'BSS',   SC_PUBLIC, SA_WORD);
  seg_idx_const := SegEnter('CONST',  'CONST', SC_PUBLIC, SA_WORD);
  seg_idx_stack := SegEnter('STACK',  'STACK', SC_STACK,  SA_PARA);
  { taille par defaut de la pile : 512 octets }
  seg_table[seg_idx_stack].size := 512;

  { creer le groupe DGROUP }
  grp_idx_dgroup := GrpEnter('DGROUP');
  GrpAddSeg(grp_idx_dgroup, seg_idx_data);
  GrpAddSeg(grp_idx_dgroup, seg_idx_bss);
  GrpAddSeg(grp_idx_dgroup, seg_idx_const);
  GrpAddSeg(grp_idx_dgroup, seg_idx_stack);

  { ASSUME par defaut }
  assume_cs        := seg_idx_text;   assume_cs_is_grp := False;
  assume_ds        := grp_idx_dgroup; assume_ds_is_grp := True;  { DS -> DGROUP }
  assume_ss        := grp_idx_dgroup; assume_ss_is_grp := True;
  assume_es        := 0;              assume_es_is_grp := False;

  { symboles predefinis @DATA @CODE @STACK }
  SymSetValue(SymFind('@DATA'),  seg_idx_data);
  SymSetValue(SymFind('@CODE'),  seg_idx_text);
  SymSetValue(SymFind('@STACK'), seg_idx_stack);

  { mettre a jour le symbole @MODEL }
  SymSetValue(SymFind('@MODEL'), mem_model);
  If (pass_num = 1) And Not silent_mode Then
    Writeln('.MODEL ', model_name, ' : segments crees.');
End;

{ ============================================================
  ParseDotCode : .CODE [nom]
  ============================================================ }
Procedure ParseDotCode(Const seg_name : TString);
Var
  sn  : TString;
  idx : Integer;
Begin
  If seg_name = '' Then sn := '_TEXT'
  Else sn := LexUpperCase(seg_name);
  idx := SegFind(sn);
  If idx = 0 Then
    idx := SegEnter(sn, 'CODE', SC_PUBLIC, SA_WORD);
  SetSeg(idx);
  assume_cs := idx;
  { mettre a jour @CURSEG }
  SymSetValue(SymFind('@CURSEG'), idx);
End;

{ ============================================================
  ParseDotData : .DATA / .DATA? / .CONST
  ============================================================ }
Procedure ParseDotData(Const kind : TString);
Var
  idx : Integer;
Begin
  If kind = '.CONST' Then
  Begin
    idx := seg_idx_const;
    If idx = 0 Then idx := SegEnter('CONST', 'CONST', SC_PUBLIC, SA_WORD);
  End
  Else If kind = '.DATA?' Then
  Begin
    idx := seg_idx_bss;
    If idx = 0 Then idx := SegEnter('_BSS', 'BSS', SC_PUBLIC, SA_WORD);
  End
  Else
  Begin
    idx := seg_idx_data;
    If idx = 0 Then idx := SegEnter('_DATA', 'DATA', SC_PUBLIC, SA_WORD);
  End;
  SetSeg(idx);
  SymSetValue(SymFind('@CURSEG'), idx);
End;

{ ============================================================
  ParseDotStack : .STACK [taille]
  ============================================================ }
Procedure ParseDotStack(size : TWord);
Begin
  If seg_idx_stack = 0 Then
    seg_idx_stack := SegEnter('STACK', 'STACK', SC_STACK, SA_PARA);
  If size > 0 Then
    seg_table[seg_idx_stack].size := size;
  SetSeg(seg_idx_stack);
  SymSetValue(SymFind('@CURSEG'), seg_idx_stack);
End;

{ ============================================================
  ParseSegment : SEGMENT nom [align] [combine] [class]
  Ouvre un segment utilisateur explicite.
  ============================================================ }
Procedure ParseSegment(Const name : TString;
                       aln : TSegAlign; comb : TSegCombine;
                       Const cls : TString);
Var
  idx : Integer;
Begin
  idx := SegFind(LexUpperCase(name));
  If idx = 0 Then
    idx := SegEnter(LexUpperCase(name), LexUpperCase(cls), comb, aln)
  Else
  Begin
    { re-ouverture d un segment existant : coherence des attributs }
    If seg_table[idx].combine <> comb Then
      WarnMsg('Attributs de segment incoherents : ' + name);
  End;
  { empiler le segment courant }
  If seg_open_top < 8 Then
  Begin
    Inc(seg_open_top);
    seg_open_stack[seg_open_top] := cur_seg;
  End;
  SetSeg(idx);
  SymSetValue(SymFind('@CURSEG'), idx);
End;

{ ============================================================
  ParseEnds : ENDS [nom] - fermer le segment courant
  ============================================================ }
Procedure ParseEnds(Const name : TString);
Var
  expected : TString;
Begin
  { verifier que le nom correspond au segment ouvert }
  If (cur_seg >= 1) And (cur_seg <= MAX_SEG) Then
    expected := seg_table[cur_seg].name
  Else
    expected := '';
  If (name <> '') And (LexUpperCase(name) <> expected) Then
    WarnMsg('ENDS ne correspond pas au segment ouvert : ' + name);
  FlushLEDATA;
  { depiler }
  If seg_open_top >= 0 Then
  Begin
    SetSeg(seg_open_stack[seg_open_top]);
    Dec(seg_open_top);
  End
  Else
    SetSeg(0);
  SymSetValue(SymFind('@CURSEG'), cur_seg);
End;

{ ============================================================
  ParseAssume : ASSUME reg:seg|grp|NOTHING
  ============================================================ }
Procedure ParseAssume(Const reg_name : TString; Const seg_name : TString);
Var
  sidx   : Integer;
  is_grp : Boolean;
  gi2    : Integer;
  useg   : TSymString;
Begin
  useg   := LexUpperCase(seg_name);
  sidx   := 0;
  is_grp := False;
  If (useg <> 'NOTHING') And (useg <> '') Then
  Begin
    sidx := SegFind(useg);
    If sidx = 0 Then
    Begin
      { chercher dans les groupes }
      For gi2 := 1 To grp_count Do
        If grp_table[gi2].name = useg Then
        Begin
          sidx   := gi2;
          is_grp := True;
          Break;
        End;
      If sidx = 0 Then
        WarnMsg('ASSUME : segment ou groupe inconnu : ' + seg_name);
    End;
  End;
  If reg_name = 'CS' Then Begin assume_cs := sidx; assume_cs_is_grp := is_grp; End
  Else If reg_name = 'DS' Then Begin assume_ds := sidx; assume_ds_is_grp := is_grp; End
  Else If reg_name = 'SS' Then Begin assume_ss := sidx; assume_ss_is_grp := is_grp; End
  Else If reg_name = 'ES' Then Begin assume_es := sidx; assume_es_is_grp := is_grp; End
  Else
    WarnMsg('ASSUME : registre de segment inconnu : ' + reg_name);
End;

{ ============================================================
  EmitAlignPad : aligner le LC sur un multiple de n octets.
  Code : remplir avec NOP (90h). Data : remplir avec 0.
  ============================================================ }
Procedure EmitAlignPad(n : Integer);
Var
  pad   : Integer;
  is_code : Boolean;
  i     : Integer;
Begin
  If n <= 1 Then Exit;
  pad := lc Mod n;
  If pad = 0 Then Exit;
  pad := n - pad;
  is_code := (cur_seg = seg_idx_text) Or (cur_seg = assume_cs);
  For i := 1 To pad Do
    If is_code Then EmitByte($90) { NOP }
    Else EmitByte($00);
End;

{ ============================================================
  GetSegAlignByte : convertir TSegAlign en octet ACBP pour OMF
  ============================================================ }
Function GetSegAlignByte(a : TSegAlign) : Byte;
Begin
  Case a Of
    SA_BYTE  : GetSegAlignByte := 1;
    SA_WORD  : GetSegAlignByte := 2;
    SA_PARA  : GetSegAlignByte := 3;
    SA_PAGE  : GetSegAlignByte := 4;
    SA_DWORD : GetSegAlignByte := 5;
    Else       GetSegAlignByte := 3; { defaut PARA }
  End;
End;

{ ============================================================
  GetSegCombByte : convertir TSegCombine en octet ACBP pour OMF
  ============================================================ }
Function GetSegCombByte(c : TSegCombine) : Byte;
Begin
  Case c Of
    SC_PRIVATE : GetSegCombByte := 0;
    SC_PUBLIC  : GetSegCombByte := 2;
    SC_STACK   : GetSegCombByte := 5;
    SC_COMMON  : GetSegCombByte := 6;
    SC_MEMORY  : GetSegCombByte := 2;
    Else         GetSegCombByte := 0;
  End;
End;

{ ============================================================
  EVALUATEUR D EXPRESSIONS ASSEMBLEUR (DEUX PASSES)
  ============================================================

  Hierarchy d appel (du moins prioritaire au plus prioritaire) :
    EvalExpr -> EvalRelational -> EvalBitwise -> EvalNot ->
    EvalAdd -> EvalMul -> EvalPTR -> EvalUnary -> EvalPrimary
  EvalPrimary appelle EvalExpr pour les parentheses.
  ============================================================ }

{ ---- Helpers TExpr ---- }
Procedure ExprMakeNum(Var e : TExpr; v : TLong);
Begin
  e.val      := v;
  e.is_reloc := False;
  e.seg_idx  := 0;
  e.is_undef := False;
  e.ptr_size := 0;
End;

Procedure ExprMakeReloc(Var e : TExpr; v : TLong; sidx : Integer);
Begin
  e.val      := v;
  e.is_reloc := True;
  e.seg_idx  := sidx;
  e.is_undef := False;
  e.ptr_size := 0;
End;

Procedure ExprMakeUndef(Var e : TExpr);
Begin
  e.val      := 0;
  e.is_reloc := False;
  e.seg_idx  := 0;
  e.is_undef := True;
  e.ptr_size := 0;
End;

{ ---- Declarations Forward ---- }
Procedure EvalExpr(Var e : TExpr); Forward;
Procedure EvalRelational(Var e : TExpr); Forward;
Procedure EvalBitwise(Var e : TExpr); Forward;
Procedure EvalNot(Var e : TExpr); Forward;
Procedure EvalAdd(Var e : TExpr); Forward;
Procedure EvalMul(Var e : TExpr); Forward;
Procedure EvalPTR(Var e : TExpr); Forward;
Procedure EvalUnary(Var e : TExpr); Forward;
Procedure EvalPrimary(Var e : TExpr); Forward;

{ ============================================================
  EvalPrimary : atome = nombre, chaine, $, ( ), [ ], identificateur
  ============================================================ }
Procedure EvalPrimary(Var e : TExpr);
Var
  tok : TString;
  sym : PSymbol;
Begin
  { ---- nombre ---- }
  If LexPeekKind = TK_NUMBER Then
  Begin
    LexNext;
    ExprMakeNum(e, lex_tok.num_val);
    Exit;
  End;

  { ---- litterale chaine : valeur = code ASCII du premier caractere ---- }
  If LexPeekKind = TK_STRING Then
  Begin
    LexNext;
    If Length(lex_tok.val) >= 1 Then
      ExprMakeNum(e, Ord(lex_tok.val[1]))
    Else
      ExprMakeNum(e, 0);
    Exit;
  End;

  { ---- ponctuation ---- }
  If LexPeekKind = TK_PUNCT Then
  Begin
    { $ = location counter courant }
    If LexPeekVal = '$' Then
    Begin
      LexNext;
      ExprMakeReloc(e, lc, cur_seg);
      Exit;
    End;
    { (expr) }
    If LexPeekVal = '(' Then
    Begin
      LexNext;
      EvalExpr(e);
      If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ')') Then
        LexNext
      Else
        WarnMsg('Parenthese fermante ) manquante dans expression');
      Exit;
    End;
    { [expr] }
    If LexPeekVal = '[' Then
    Begin
      LexNext;
      EvalExpr(e);
      If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ']') Then
        LexNext
      Else
        WarnMsg('Crochet fermant ] manquant dans expression');
      Exit;
    End;
  End;

  { ---- identificateur ---- }
  If LexPeekKind = TK_IDENT Then
  Begin
    LexNext;
    tok := lex_tok.val; { majuscules garanties par LexNext }

    { constantes booleennes }
    If tok = 'TRUE'  Then Begin ExprMakeNum(e, -1); Exit; End;
    If tok = 'FALSE' Then Begin ExprMakeNum(e,  0); Exit; End;

    { recherche dans la table des symboles }
    sym := SymFind(tok);
    If sym = Nil Then
    Begin
      If pass_num = 1 Then
        ExprMakeUndef(e)
      Else
      Begin
        ErrorMsg('Symbole indefini : ' + tok);
        ExprMakeNum(e, 0);
      End;
      Exit;
    End;

    Case sym^.kind Of
      SK_LABEL, SK_PUBLIC :
        ExprMakeReloc(e, sym^.offset, sym^.seg_idx);
      SK_EXTERN :
        Begin
          { les EXTERN sont relocalisables, le fixup sera emis a l emit }
          e.val      := 0;
          e.is_reloc := True;
          e.seg_idx  := 0;
          e.is_undef := False;
          e.ptr_size := sym^.size;
        End;
      SK_EQU :
        ExprMakeNum(e, sym^.value);
      SK_SEG :
        ExprMakeNum(e, sym^.seg_idx);
      SK_UNDEF :
        Begin
          If pass_num = 1 Then
            ExprMakeUndef(e)
          Else
          Begin
            ErrorMsg('Symbole indefini en passe 2 : ' + tok);
            ExprMakeNum(e, 0);
          End;
        End;
    Else
      ExprMakeNum(e, sym^.value);
    End;
    Exit;
  End;

  { rien de reconnu }
  ErrorMsg('Expression attendue, token inattendu : ' + LexPeekVal);
  ExprMakeNum(e, 0);
End;

{ ---- Table des mots-cles unaires pour EvalUnary ---- }
Const
  EU_OFFSET = 1;   EU_SEG    = 2;   EU_TYPE   = 3;
  EU_SIZE   = 4;   EU_LENGTH = 5;   EU_SHORT  = 6;
  EU_BYTE   = 7;   EU_WORD   = 8;   EU_DWORD  = 9;
  EU_QWORD  = 10;  EU_TBYTE  = 11;  EU_NEAR   = 12;
  EU_FAR    = 13;
  EU_COUNT  = 13;
  EU_NAMES  : Array[1..13] Of String[6] = (
    'OFFSET','SEG','TYPE','SIZE','LENGTH','SHORT',
    'BYTE','WORD','DWORD','QWORD','TBYTE','NEAR','FAR'
  );

{ ============================================================
  EvalUnary : unaires OFFSET SEG TYPE SIZE LENGTH SHORT, - +
  et BYTE/WORD/DWORD PTR (quand pas suivi de PTR : valeur taille)
  ============================================================ }
Procedure EvalUnary(Var e : TExpr);
Var
  tok   : TString;
  sz    : Integer;
  u_idx : Integer;
  i     : Integer;
Begin
  { ----- keywords unaires ----- }
  If LexPeekKind = TK_IDENT Then
  Begin
    tok   := LexPeekVal;
    sz    := 0;
    u_idx := 0;
    For i := 1 To EU_COUNT Do
      If EU_NAMES[i] = tok Then Begin u_idx := i; Break; End;
    Case u_idx Of
      EU_OFFSET :
        Begin
          LexNext; EvalPrimary(e); e.is_reloc := False; Exit;
        End;
      EU_SEG :
        Begin
          LexNext; EvalPrimary(e);
          If e.is_reloc Then ExprMakeNum(e, e.seg_idx)
          Else             ExprMakeNum(e, 0);
          Exit;
        End;
      EU_TYPE :
        Begin
          LexNext; EvalPrimary(e); ExprMakeNum(e, e.ptr_size); Exit;
        End;
      EU_SIZE :
        Begin
          LexNext; EvalPrimary(e);
          ExprMakeNum(e, e.ptr_size); { simplification : taille = TYPE ici }
          Exit;
        End;
      EU_LENGTH :
        Begin
          LexNext; EvalPrimary(e);
          ExprMakeNum(e, 1); { par defaut 1 element sauf labels de tableaux }
          Exit;
        End;
      EU_SHORT :
        Begin
          LexNext; EvalPrimary(e); e.ptr_size := 1; Exit;
        End;
      EU_BYTE  : sz := 1;
      EU_WORD  : sz := 2;
      EU_DWORD : sz := 4;
      EU_QWORD : sz := 8;
      EU_TBYTE : sz := 10;
      EU_NEAR  : sz := 2;
      EU_FAR   : sz := 4;
    End; { Case u_idx }

    { --- BYTE/WORD/DWORD/QWORD/TBYTE/NEAR/FAR : taille de type ou PTR --- }
    If sz > 0 Then
    Begin
      LexNext; { consommer BYTE/WORD/etc. }
      { suivi de PTR ? }
      If (LexPeekKind = TK_IDENT) And (LexPeekVal = 'PTR') Then
      Begin
        LexNext; { consommer PTR }
        EvalUnary(e);  { evaluer l operande droite }
        e.ptr_size := sz;
        Exit;
      End;
      { pas de PTR : retourner la valeur de la taille comme constante }
      ExprMakeNum(e, sz);
      Exit;
    End;
  End;

  { ----- unaire - ----- }
  If (LexPeekKind = TK_PUNCT) And (LexPeekVal = '-') Then
  Begin
    LexNext;
    EvalPrimary(e);
    e.val      := -e.val;
    e.is_reloc := False;
    Exit;
  End;

  { ----- unaire + ----- }
  If (LexPeekKind = TK_PUNCT) And (LexPeekVal = '+') Then
  Begin
    LexNext;
    EvalPrimary(e);
    Exit;
  End;

  { par defaut : primaire }
  EvalPrimary(e);
End;

{ ============================================================
  EvalPTR : operateur PTR  (BYTE PTR deja gere dans EvalUnary)
  Ici EvalPTR sert de relais ; l operateur est intercepte en
  EvalUnary avant que EvalPrimary ne consomme le mot-cle.
  ============================================================ }
Procedure EvalPTR(Var e : TExpr);
Begin
  EvalUnary(e);
  { PTR apres identif non-keyword est deja traite dans EvalUnary.
    Si un PTR orphelin se retrouve ici, on l ignore silencieusement. }
End;

{ ---- Table des operateurs IDENT pour EvalMul ---- }
Const EM_MOD=1; EM_SHL=2; EM_SHR=3; EM_COUNT=3;
      EM_NAMES: Array[1..3] Of String[3] = ('MOD','SHL','SHR');

{ ============================================================
  EvalMul : * / MOD SHL SHR
  ============================================================ }
Procedure EvalMul(Var e : TExpr);
Var
  op     : TString;
  r      : TExpr;
  em_idx : Integer;
  i      : Integer;
Begin
  EvalPTR(e);
  Repeat
    If LexPeekKind = TK_PUNCT Then
    Begin
      op := LexPeekVal;
      If (op = '*') Or (op = '/') Then
      Begin
        LexNext;
        EvalPTR(r);
        Case op[1] Of
          '*': e.val := e.val * r.val;
          '/': If r.val = 0 Then
               Begin
                 ErrorMsg('Division par zero dans expression');
                 e.val := 0;
               End
               Else
                 e.val := e.val Div r.val;
        End;
        e.is_reloc := False;
      End
      Else
        Break;
    End
    Else If LexPeekKind = TK_IDENT Then
    Begin
      op := LexPeekVal;
      em_idx := 0;
      For i := 1 To EM_COUNT Do
        If EM_NAMES[i] = op Then Begin em_idx := i; Break; End;
      If em_idx = 0 Then Break;
      LexNext;
      EvalPTR(r);
      Case em_idx Of
        EM_MOD : If r.val = 0 Then e.val := 0
                 Else e.val := e.val Mod r.val;
        EM_SHL : e.val := e.val Shl r.val;
        EM_SHR : e.val := e.val Shr r.val;
      End;
      e.is_reloc := False;
    End
    Else
      Break;
  Until False;
End;

{ ============================================================
  EvalAdd : + - (additifs binaires)
  ============================================================ }
Procedure EvalAdd(Var e : TExpr);
Var
  op : TString;
  r  : TExpr;
Begin
  EvalMul(e);
  Repeat
    If LexPeekKind = TK_PUNCT Then
    Begin
      op := LexPeekVal;
      If (op = '+') Or (op = '-') Then
      Begin
        LexNext;
        EvalMul(r);
        If op = '+' Then
          e.val := e.val + r.val
        Else
          e.val := e.val - r.val;
        { si l un est relocalisable et l autre est une constante : OK }
        { si les deux sont relocalisables + : erreur ; - : OK (difference) }
        If e.is_reloc And r.is_reloc Then
        Begin
          If op = '-' Then
            e.is_reloc := False { diff de deux reloc = constante }
          Else
          Begin
            ErrorMsg('Addition de deux adresses relocalisables interdite');
            e.is_reloc := False;
          End;
        End
        Else If r.is_reloc Then
        Begin
          e.is_reloc := True;
          e.seg_idx  := r.seg_idx;
        End;
        If r.is_undef Then e.is_undef := True;
      End
      Else
        Break;
    End
    Else
      Break;
  Until False;
End;

{ ============================================================
  EvalNot : NOT unaire bitwise
  ============================================================ }
Procedure EvalNot(Var e : TExpr);
Begin
  If (LexPeekKind = TK_IDENT) And (LexPeekVal = 'NOT') Then
  Begin
    LexNext;
    EvalNot(e); { recursif pour NOT NOT x }
    e.val      := Not e.val;
    e.is_reloc := False;
  End
  Else
    EvalAdd(e);
End;

{ ---- Table des operateurs pour EvalBitwise ---- }
Const EB_AND=1; EB_OR=2; EB_XOR=3; EB_COUNT=3;
      EB_NAMES: Array[1..3] Of String[3] = ('AND','OR','XOR');

{ ============================================================
  EvalBitwise : AND OR XOR (logiques bitwise)
  ============================================================ }
Procedure EvalBitwise(Var e : TExpr);
Var
  op    : TString;
  r     : TExpr;
  eb_idx : Integer;
  i     : Integer;
Begin
  EvalNot(e);
  Repeat
    If LexPeekKind = TK_IDENT Then
    Begin
      op := LexPeekVal;
      eb_idx := 0;
      For i := 1 To EB_COUNT Do
        If EB_NAMES[i] = op Then Begin eb_idx := i; Break; End;
      If eb_idx = 0 Then Break;
      LexNext;
      EvalNot(r);
      Case eb_idx Of
        EB_AND : e.val := e.val And r.val;
        EB_OR  : e.val := e.val Or  r.val;
        EB_XOR : e.val := e.val Xor r.val;
      End;
      e.is_reloc := False;
      If r.is_undef Then e.is_undef := True;
    End
    Else
      Break;
  Until False;
End;

{ ---- Table des operateurs relationnels pour EvalRelational ---- }
Const
  ER_EQ = 1; ER_NE = 2; ER_LT = 3; ER_LE = 4; ER_GT = 5; ER_GE = 6;
  ER_COUNT = 6;
  ER_NAMES : Array[1..6] Of String[2] = ('EQ','NE','LT','LE','GT','GE');

{ ============================================================
  EvalRelational : EQ NE LT LE GT GE (resultat -1=vrai, 0=faux)
  ============================================================ }
Procedure EvalRelational(Var e : TExpr);
Var
  op    : TString;
  r     : TExpr;
  b     : Boolean;
  er_idx : Integer;
  i     : Integer;
Begin
  EvalBitwise(e);
  Repeat
    If LexPeekKind = TK_IDENT Then
    Begin
      op     := LexPeekVal;
      er_idx := 0;
      For i := 1 To ER_COUNT Do
        If ER_NAMES[i] = op Then Begin er_idx := i; Break; End;
      If er_idx = 0 Then Break;
      LexNext;
      EvalBitwise(r);
      Case er_idx Of
        ER_EQ : b := (e.val =  r.val);
        ER_NE : b := (e.val <> r.val);
        ER_LT : b := (e.val <  r.val);
        ER_LE : b := (e.val <= r.val);
        ER_GT : b := (e.val >  r.val);
        ER_GE : b := (e.val >= r.val);
      Else b := False;
      End;
      If b Then e.val := -1 Else e.val := 0;
      e.is_reloc := False;
      e.is_undef := e.is_undef Or r.is_undef;
    End
    Else
      Break;
  Until False;
End;

{ ============================================================
  EvalExpr : point d entree public de l evaluateur
  ============================================================ }
Procedure EvalExpr(Var e : TExpr);
Begin
  EvalRelational(e);
End;

{ ============================================================
  EvalConstExpr : evaluer une expression qui DOIT etre constante
  (non relocalisable). Signale une erreur si le resultat est
  relocalisable ou indefini en passe 2.
  ============================================================ }
Function EvalConstExpr : TLong;
Var
  e : TExpr;
Begin
  EvalExpr(e);
  If e.is_undef Then
  Begin
    If pass_num = 2 Then
      ErrorMsg('Expression constante non resolue en passe 2');
    EvalConstExpr := 0;
    Exit;
  End;
  If e.is_reloc Then
  Begin
    ErrorMsg('Expression relocalisable inattendue (constante requise)');
    EvalConstExpr := e.val;
    Exit;
  End;
  EvalConstExpr := e.val;
End;

{ ============================================================
  WriteAllSegments : ecrire LNAMES + tous les SEGDEF + GRPDEF
  dans le fichier .OBJ. Appele apres la passe 2.
  ============================================================ }
Procedure WriteAllSegments;
Var
  i    : Integer;
  gi   : Integer;
  gj   : Integer;
  sni  : Integer;
  cni  : Integer;
  tmp  : Array[0..MAX_SEG] Of Integer;
  tcnt : Integer;
Begin
  { 1. ecrire LNAMES (accumules) }
  ObjLNAMES;

  { 2. ecrire un SEGDEF par segment }
  For i := 1 To seg_count Do
  Begin
    With seg_table[i] Do
    Begin
      sni := lnames_idx;
      If class_name <> '' Then
        cni := LNamesRegister(class_name)
      Else
        cni := 0;
      ObjSEGDEF(
        GetSegAlignByte(align),
        GetSegCombByte(combine),
        size,
        sni,
        cni,
        0   { pas d overlay }
      );
    End;
  End;

  { 3. ecrire un GRPDEF par groupe }
  For gi := 1 To grp_count Do
  Begin
    With grp_table[gi] Do
    Begin
      tcnt := grp_table[gi].seg_count;
      For gj := 1 To tcnt Do
        tmp[gj-1] := segs[gj];
      ObjGRPDEF(
        LNamesRegister(name),
        tmp,
        tcnt
      );
    End;
  End;
End;

{ ============================================================
  DIRECTIVES DE DONNEES (DB DW DD DQ DT ALIGN EVEN)
  ============================================================

  Tailles par directive :
    DB = 1, DW = 2, DD = 4, DQ = 8, DT = 10
  Syntaxe d un element :
    expr | ? | 'chaine' (DB seult) | N DUP(liste)
  Liste = elements separes par des virgules.
  DUP imbriques supportes jusqu a DUP_DEPTH_MAX niveaux.
  Le premier bloc DUP est emis normalement ; les blocs
  suivants sont copies depuis le buffer LEDATA si possible,
  sinon remplis avec des zeros (cas d un flush intermediaire).
  ALIGN n : aligner le LC sur un multiple de n.
  EVEN    : alias pour ALIGN 2.
  ============================================================ }

Const
  DUP_DEPTH_MAX = 8;  { niveaux max de DUP imbriques }
  DUP_BLK_MAX   = 1020; { taille max d un bloc DUP copiable (= LEDATA_BUF_MAX) }

{ ---- declarations forward mutuelles ---- }
Procedure ParseDataList(size : Integer; depth : Integer); Forward;
Procedure ParseOneDataItem(size : Integer; depth : Integer); Forward;

{ ============================================================
  EmitDataVal : emettre 'val' sur 'size' octets
  ============================================================ }
Procedure EmitDataVal(val : TLong; size : Integer);
Var
  i : Integer;
Begin
  Case size Of
    1  : EmitByte(Lo(Word(val)));
    2  : EmitWord(Word(val));
    4  : EmitDWord(val);
    8  : Begin
           EmitDWord(val);   { lo 32 bits }
           EmitDWord(0);     { hi 32 bits : extension a zero }
         End;
    10 : Begin
           EmitDWord(val);
           EmitDWord(0);
           EmitWord(0);      { 10 octets en tout (DT, 80 bits) }
         End;
  Else
    For i := 1 To size Do EmitByte(0); { securite }
  End;
End;

{ ============================================================
  ParseDupBlock : parse la liste interieure d un DUP, l emet
  'count' fois, en copiant le bloc depuis ledata_buf quand
  c est possible.
  ============================================================ }
Procedure ParseDupBlock(count : TLong; size : Integer; depth : Integer);
Var
  pre_start  : TWord;     { ledata_start avant le 1er bloc }
  pre_len    : Integer;   { ledata_buf_len avant le 1er bloc }
  blk_len    : Integer;   { nb d octets emis dans le 1er bloc }
  blk_buf    : Array[0..DUP_BLK_MAX-1] Of Byte;
  can_copy   : Boolean;
  i          : Integer;
  j          : TLong;
Begin
  If count <= 0 Then
  Begin
    { consommer la liste sans emettre }
    ParseDataList(size, depth);
    Exit;
  End;

  pre_start := ledata_start;
  pre_len   := ledata_buf_len;

  { emettre le premier bloc }
  ParseDataList(size, depth);

  blk_len  := Integer(lc - (pre_start + TWord(pre_len)));
  { re-calculer : apres emission, si pas de flush, blk_len = diff ledata_buf_len }
  blk_len  := ledata_buf_len - pre_len;

  { verifier qu aucun flush n a eu lieu pendant le 1er bloc }
  can_copy := (ledata_start = pre_start) And
              (blk_len > 0) And
              (blk_len <= DUP_BLK_MAX);

  If can_copy Then
  Begin
    { copier les octets du bloc depuis ledata_buf }
    For i := 0 To blk_len - 1 Do
      blk_buf[i] := ledata_buf[pre_len + i];
    { repeter count-1 fois }
    For j := 2 To count Do
      For i := 0 To blk_len - 1 Do
        EmitByte(blk_buf[i]);
  End
  Else
  Begin
    { flush intermediaire ou bloc trop grand : remplir avec zeros }
    If blk_len < 0 Then blk_len := 0;
    For j := 2 To count Do
      EmitZeros(blk_len);
  End;
End;

{ ============================================================
  ParseOneDataItem : un element de la liste de donnees
  ============================================================ }
Procedure ParseOneDataItem(size : Integer; depth : Integer);
Var
  e    : TExpr;
  s    : TString;
  i    : Integer;
  cnt  : TLong;
Begin
  { ? = espace non initialise -> zeros }
  If (LexPeekKind = TK_PUNCT) And (LexPeekVal = '?') Then
  Begin
    LexNext;
    EmitZeros(size);
    Exit;
  End;

  { litterale chaine : seulement pour DB, un EmitByte par caractere }
  If (size = 1) And (LexPeekKind = TK_STRING) Then
  Begin
    LexNext;
    s := lex_tok.val;
    For i := 1 To Length(s) Do
      EmitByte(Byte(Ord(s[i])));
    Exit;
  End;

  { expression puis verification DUP }
  EvalExpr(e);

  { N DUP(liste) }
  If (LexPeekKind = TK_IDENT) And (LexPeekVal = 'DUP') Then
  Begin
    LexNext; { consommer DUP }
    If depth >= DUP_DEPTH_MAX Then
    Begin
      ErrorMsg('DUP trop profondement imbrique');
      Exit;
    End;
    cnt := e.val;
    { consommer ( }
    If (LexPeekKind = TK_PUNCT) And (LexPeekVal = '(') Then
      LexNext
    Else
      WarnMsg('( attendu apres DUP');
    ParseDupBlock(cnt, size, depth + 1);
    { consommer ) }
    If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ')') Then
      LexNext
    Else
      WarnMsg(') attendu apres le contenu de DUP');
    Exit;
  End;

  { valeur numerique simple }
  If e.is_undef And (pass_num = 2) Then
    ErrorMsg('Symbole indefini dans directive de donnees');
  EmitDataVal(e.val, size);
End;

{ ============================================================
  ParseDataList : liste d elements separes par des virgules
  ============================================================ }
Procedure ParseDataList(size : Integer; depth : Integer);
Begin
  ParseOneDataItem(size, depth);
  While (LexPeekKind = TK_PUNCT) And (LexPeekVal = ',') Do
  Begin
    LexNext; { , }
    ParseOneDataItem(size, depth);
  End;
End;

{ ---- Table des directives de donnees pour ParseDataDir ---- }
Const
  DD_DB = 1; DD_DW = 2; DD_DD = 3; DD_DQ = 4; DD_DT = 5;
  DD_COUNT = 5;
  DD_NAMES : Array[1..5] Of String[2] = ('DB','DW','DD','DQ','DT');
  DD_SIZES : Array[1..5] Of Byte      = (1, 2, 4, 8, 10);

{ ============================================================
  ParseDataDir : directive [label] DB/DW/DD/DQ/DT liste
  label_name = '' si absent
  ============================================================ }
Procedure ParseDataDir(Const directive : TString; Const label_name : TString);
Var
  size   : Integer;
  p      : PSymbol;
  dd_idx : Integer;
  i      : Integer;
Begin
  dd_idx := 0;
  For i := 1 To DD_COUNT Do
    If DD_NAMES[i] = directive Then Begin dd_idx := i; Break; End;
  If dd_idx = 0 Then
  Begin
    ErrorMsg('Directive de donnees inconnue : ' + directive);
    Exit;
  End;
  size := DD_SIZES[dd_idx];

  { definir le label courant si present }
  If label_name <> '' Then
  Begin
    SymDefineLabel(label_name, cur_seg, lc, size);
    p := SymFind(label_name);
    If p <> Nil Then p^.size := size;
  End;

  ParseDataList(size, 0);
End;

{ ============================================================
  ParseAlign : ALIGN n -> aligner le LC
  ============================================================ }
Procedure ParseAlign;
Var
  n : TLong;
Begin
  n := EvalConstExpr;
  If n < 1 Then n := 1;
  EmitAlignPad(Integer(n));
End;

{ ============================================================
  ParseEven : EVEN -> ALIGN 2
  ============================================================ }
Procedure ParseEven;
Begin
  EmitAlignPad(2);
End;

{ ============================================================
  DIRECTIVES SYMBOLIQUES (EQU  =  LABEL  ORG  LOCAL  RECORD)
  ============================================================

  EQU    : nom EQU expr  -> constante non reassignable (SK_EQU, flag bit3=0)
  =      : nom = expr    -> equate reassignable          (SK_EQU, flag bit3=1)
  LABEL  : nom LABEL type -> alias a la position courante, taille forcee
  ORG    : ORG expr      -> repositionner le LC (pas de fixup emis)
  LOCAL  : LOCAL a,b,c   -> dans macro, genere @@0000 @@0001 ...
  RECORD : nom RECORD champ:bits[=init], ... -> packed bit fields
  ============================================================ }

{ ---- compteur global pour LOCAL (incremente a chaque expansion) ---- }
Var
  local_unique_id : LongInt;

{ ============================================================
  LocalNextName : genere un nom unique @@nnnn (4 hex digits)
  ============================================================ }
Function LocalNextName : TSymString;
Var
  s   : TSymString;
  hex : String[4];
  v   : LongInt;
  i   : Integer;
Const
  HEX_CHARS : Array[0..15] Of Char =
    ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
  v   := local_unique_id And $FFFF;
  Inc(local_unique_id);
  hex := '0000';
  For i := 4 DownTo 1 Do
  Begin
    hex[i] := HEX_CHARS[v And 15];
    v       := v Shr 4;
  End;
  s := '@@' + hex;
  LocalNextName := s;
End;

{ ============================================================
  ParseEqu : nom EQU expr (non reassignable)
  ============================================================ }
Procedure ParseEqu(Const name : TSymString);
Var
  p   : PSymbol;
  e   : TExpr;
Begin
  EvalExpr(e);
  p := SymFind(name);
  If p <> Nil Then
  Begin
    { EQU ne peut pas etre redefini sauf si c est un SK_UNDEF (forward) }
    If (p^.kind = SK_EQU) And ((p^.flags And 8) = 0) Then
    Begin
      ErrorMsg('Redefinition de constante EQU : ' + name);
      Exit;
    End;
  End;
  If p = Nil Then
    p := SymEnter(name, SK_EQU, 0, 0, 2)
  Else
  Begin
    p^.kind    := SK_EQU;
    p^.seg_idx := 0;
    p^.size    := 2;
  End;
  SymSetValue(p, e.val);
  p^.flags := p^.flags And Not 8; { bit3=0 : non reassignable }
End;

{ ============================================================
  ParseEquAssign : nom = expr (reassignable)
  ============================================================ }
Procedure ParseEquAssign(Const name : TSymString);
Var
  p : PSymbol;
  e : TExpr;
Begin
  EvalExpr(e);
  p := SymFind(name);
  If p = Nil Then
    p := SymEnter(name, SK_EQU, 0, 0, 2)
  Else
  Begin
    { autoriser la reassignation si bit3=1 ou si SK_UNDEF }
    If (p^.kind = SK_EQU) And ((p^.flags And 8) = 0) Then
    Begin
      ErrorMsg('Reassignation interdite (EQU non reassignable) : ' + name);
      Exit;
    End;
    p^.kind    := SK_EQU;
    p^.seg_idx := 0;
    p^.size    := 2;
  End;
  SymSetValue(p, e.val);
  p^.flags := p^.flags Or 8; { bit3=1 : reassignable }
End;

{ ---- Table des types pour ParseLabelDir ---- }
Const
  LL_COUNT = 8;
  LL_NAMES : Array[1..8] Of String[5] = (
    'BYTE','WORD','DWORD','QWORD','TBYTE','NEAR','PROC','FAR'
  );
  LL_SIZES : Array[1..8] Of Byte = (1, 2, 4, 8, 10, 2, 2, 4);

{ ============================================================
  ParseLabelDir : nom LABEL type
  type = BYTE WORD DWORD NEAR FAR PROC
  Cree un label a la position courante avec la taille precisee.
  ============================================================ }
Procedure ParseLabelDir(Const name : TSymString);
Var
  p      : PSymbol;
  tok    : TString;
  sz     : TWord;
  ll_idx : Integer;
  i      : Integer;
Begin
  sz := 0;
  If LexPeekKind = TK_IDENT Then
  Begin
    LexNext;
    tok := lex_tok.val;
    ll_idx := 0;
    For i := 1 To LL_COUNT Do
      If LL_NAMES[i] = tok Then Begin ll_idx := i; Break; End;
    If ll_idx > 0 Then sz := LL_SIZES[ll_idx]
    Else WarnMsg('Type de LABEL inconnu : ' + tok);
  End
  Else
    WarnMsg('Type attendu apres LABEL');

  SymDefineLabel(name, cur_seg, lc, sz);
  p := SymFind(name);
  If p <> Nil Then p^.size := sz;
End;

{ ============================================================
  ParseOrg : ORG expr
  Repositionne le LC dans le segment courant.
  Flush le buffer LEDATA avant (on ne peut pas continuer le
  meme bloc apres un ORG).
  ============================================================ }
Procedure ParseOrg;
Var
  new_lc : TLong;
Begin
  new_lc := EvalConstExpr;
  FlushLEDATA;
  lc := TWord(new_lc);
  If (cur_seg >= 1) And (cur_seg <= seg_count) Then
    seg_table[cur_seg].cur_lc := TWord(new_lc);
  ledata_start := TWord(new_lc);
  { mettre a jour $ }
  SymSetValue(SymFind('@CURSEG'), cur_seg);
End;

{ ============================================================
  ParseLocal : LOCAL a [, b, ...]
  Genere des noms uniques et les entre dans la table des sym
  comme des EQU de type chaine (valeur = index unique).
  Utilise dans le corps des macros : remplace les noms par
  les noms uniques lors de l expansion (macros).
  Ici on se contente de creer les symboles @@nnnn.
  ============================================================ }
Procedure ParseLocal;
Var
  orig  : TSymString;
  uname : TSymString;
  p     : PSymbol;
Begin
  Repeat
    If LexPeekKind <> TK_IDENT Then Break;
    LexNext;
    orig  := lex_tok.val;
    uname := LocalNextName;
    { enregistrer l alias : orig -> uname (comme EQU) }
    p := SymFind(orig);
    If p = Nil Then
      p := SymEnter(orig, SK_EQU, 0, 0, 0);
    { stocker l index unique dans value pour retrouver uname }
    SymSetValue(p, local_unique_id - 1);
    p^.flags := p^.flags Or 8;
    { creer aussi le symbole cible @@nnnn }
    p := SymFind(uname);
    If p = Nil Then
      p := SymEnter(uname, SK_LABEL, cur_seg, lc, 0);
    If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ',') Then
      LexNext
    Else
      Break;
  Until False;
End;

{ ============================================================
  ParseRecord : nom RECORD champ:bits[=init] [, champ:bits[=init] ...]
  Champs emballes de MSB vers LSB dans BYTE (<=8 bits) ou WORD.
  Pour chaque champ 'f' de largeur 'w' bits au decalage 'd' :
    f        = decalage (shift amount) - valeur du symbole
    MASK f   sera gere par l evaluateur
    Pour l instant on cree aussi f##_MASK comme EQU auxiliaire.
  Le nom du RECORD devient SK_STRUCT, value = taille en octets.
  ============================================================ }
Const
  RECORD_FIELDS_MAX = 16;

Procedure ParseRecord(Const rec_name : TSymString);
Type
  TRecField = Record
    fname   : TSymString;
    width   : Integer;
    init    : TLong;
    has_init: Boolean;
  End;
Var
  fields      : Array[0..RECORD_FIELDS_MAX-1] Of TRecField;
  nfields     : Integer;
  total_bits  : Integer;
  rec_bytes   : Integer;
  shift       : Integer;
  mask        : TLong;
  i           : Integer;
  tok         : TString;
  e           : TExpr;
  p           : PSymbol;
  mname       : TSymString;
Begin
  nfields := 0;
  { parser la liste des champs }
  Repeat
    If LexPeekKind <> TK_IDENT Then Break;
    LexNext;
    tok := lex_tok.val;
    If nfields < RECORD_FIELDS_MAX Then
    Begin
      fields[nfields].fname    := tok;
      fields[nfields].width    := 0;
      fields[nfields].init     := 0;
      fields[nfields].has_init := False;
    End;
    { : largeur }
    If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ':') Then
    Begin
      LexNext;
      ExprMakeNum(e, 0);
      EvalExpr(e);
      If nfields < RECORD_FIELDS_MAX Then
        fields[nfields].width := Integer(e.val);
    End
    Else
      WarnMsg('Attendu : apres nom de champ dans RECORD');
    { = valeur initiale optionnelle }
    If (LexPeekKind = TK_PUNCT) And (LexPeekVal = '=') Then
    Begin
      LexNext;
      EvalExpr(e);
      If nfields < RECORD_FIELDS_MAX Then
      Begin
        fields[nfields].init     := e.val;
        fields[nfields].has_init := True;
      End;
    End;
    If nfields < RECORD_FIELDS_MAX Then
      Inc(nfields);
    If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ',') Then
      LexNext
    Else
      Break;
  Until False;

  { calculer la taille totale }
  total_bits := 0;
  For i := 0 To nfields - 1 Do
    total_bits := total_bits + fields[i].width;
  If total_bits <= 8 Then rec_bytes := 1
  Else                    rec_bytes := 2;

  { calculer les decalages et creer les symboles }
  { les champs sont emballes MSB en premier, donc on part de
    (rec_bytes*8 - total_bits) comme offset de base }
  shift := rec_bytes * 8 - total_bits;
  If shift < 0 Then shift := 0;

  For i := 0 To nfields - 1 Do
  Begin
    { masque du champ }
    If fields[i].width >= 32 Then
      mask := -1
    Else
    Begin
      mask := (TLong(1) Shl fields[i].width) - 1;
      mask := mask Shl shift;
    End;

    { symbole principal : valeur = position de shift }
    p := SymFind(fields[i].fname);
    If p = Nil Then
      p := SymEnter(fields[i].fname, SK_EQU, 0, 0, 2);
    SymSetValue(p, shift);
    p^.flags := p^.flags And Not 8;

    { symbole auxiliaire FIELDNAME_MASK = masque }
    mname := fields[i].fname;
    If Length(mname) <= 28 Then
      mname := mname + '_MASK'
    Else
      mname := Copy(mname, 1, 27) + 'M';
    p := SymFind(mname);
    If p = Nil Then
      p := SymEnter(mname, SK_EQU, 0, 0, 2);
    SymSetValue(p, mask);
    p^.flags := p^.flags And Not 8;

    shift := shift + fields[i].width;
  End;

  { creer le symbole du RECORD lui-meme }
  p := SymFind(rec_name);
  If p = Nil Then
    p := SymEnter(rec_name, SK_STRUCT, 0, 0, rec_bytes);
  p^.kind  := SK_STRUCT;
  p^.size  := rec_bytes;
  SymSetValue(p, rec_bytes);
End;

{ ============================================================
  DIRECTIVES DE VISIBILITE (PUBLIC EXTRN GLOBAL COMM)
  ============================================================

  Tables de suivi :
    extdef_names[1..MAX_EXTDEF] : noms des symboles EXTRN dans
      l ordre de declaration ; l index (1-base) est l indice
      EXTDEF utilise dans les records FIXUPP.
    extdef_types[1..MAX_EXTDEF] : taille en octets du type.
    pubdef_syms[1..MAX_PUBDEF]  : pointeurs vers les PSymbol
      marques PUBLIC (pour emetre les PUBDEF a la fin).

  Emission OMF :
    EmitAllExtDefs -> un record EXTDEF par symbole externe.
    EmitAllPubDefs -> un record PUBDEF par symbole public
      (groupe par segment pour minimiser les records).
    EmitComDef     -> record COMDEF pour variables communes.
  ============================================================ }

Const
  MAX_EXTDEF = 256;
  MAX_PUBDEF = {$IFDEF FPC}512{$ELSE}128{$ENDIF};

Var
  extdef_names : Array[1..MAX_EXTDEF] Of TSymString;
  extdef_types : Array[1..MAX_EXTDEF] Of Integer;
  extdef_count : Integer;

  pubdef_syms  : Array[1..MAX_PUBDEF] Of PSymbol;
  pubdef_count : Integer;

{ ============================================================
  VisInit : initialiser les tables PUBLIC/EXTRN
  ============================================================ }
Procedure VisInit;
Begin
  extdef_count := 0;
  pubdef_count := 0;
End;

{ ============================================================
  ExtdefRegister : enregistrer un symbole EXTRN dans la table.
  Retourne l index EXTDEF 1-base (utilise dans FIXUPP).
  Si deja present, retourne l index existant.
  ============================================================ }
Function ExtdefRegister(Const name : TSymString) : Integer;
Var
  i : Integer;
Begin
  For i := 1 To extdef_count Do
    If extdef_names[i] = name Then
    Begin
      ExtdefRegister := i;
      Exit;
    End;
  If extdef_count >= MAX_EXTDEF Then
  Begin
    ErrorMsg('Trop de symboles EXTRN (max ' +
             Chr(Ord('0') + MAX_EXTDEF Div 100) +
             Chr(Ord('0') + (MAX_EXTDEF Div 10) Mod 10) +
             Chr(Ord('0') + MAX_EXTDEF Mod 10) + ')');
    ExtdefRegister := 1;
    Exit;
  End;
  Inc(extdef_count);
  extdef_names[extdef_count] := name;
  extdef_types[extdef_count] := 0;
  ExtdefRegister := extdef_count;
End;

{ ============================================================
  PubdefRegister : ajouter un PSymbol a la liste des PUBDEF.
  Ignore si deja present.
  ============================================================ }
Procedure PubdefRegister(p : PSymbol);
Var
  i : Integer;
Begin
  If p = Nil Then Exit;
  For i := 1 To pubdef_count Do
    If pubdef_syms[i] = p Then Exit;
  If pubdef_count >= MAX_PUBDEF Then
  Begin
    WarnMsg('Trop de symboles PUBLIC (max 512), excess ignore');
    Exit;
  End;
  Inc(pubdef_count);
  pubdef_syms[pubdef_count] := p;
End;

{ ---- Table des types pour TypeNameToSize ---- }
Const
  TN_COUNT = 10;
  TN_NAMES : Array[1..10] Of String[5] = (
    'BYTE','WORD','DWORD','QWORD','TBYTE','NEAR','FAR','FWORD','PROC','ABS'
  );
  TN_SIZES : Array[1..10] Of Byte = (1, 2, 4, 8, 10, 2, 4, 4, 0, 0);

{ ============================================================
  TypeNameToSize : convertir un nom de type MASM en octets
    BYTE=1 WORD=2 DWORD=4 QWORD=8 TBYTE=10
    NEAR=2 FAR=4 PROC=2 ABS=0
  ============================================================ }
Function TypeNameToSize(Const tname : TString) : Integer;
Var i : Integer;
Begin
  For i := 1 To TN_COUNT Do
    If TN_NAMES[i] = tname Then Begin TypeNameToSize := TN_SIZES[i]; Exit; End;
  WarnMsg('Type inconnu dans EXTRN/GLOBAL/COMM : ' + tname);
  TypeNameToSize := 0;
End;

{ ============================================================
  ParsePublic : PUBLIC nom [, nom ...]
  Marque les symboles comme PUBLIC et les ajoute a la liste
  PUBDEF. Cree le symbole en SK_UNDEF si inconnu (reference avant).
  ============================================================ }
Procedure ParsePublic;
Var
  tok : TSymString;
  p   : PSymbol;
Begin
  Repeat
    If LexPeekKind <> TK_IDENT Then Break;
    LexNext;
    tok := lex_tok.val;
    p := SymLookupOrEnter(tok);
    SymSetPublic(p);
    PubdefRegister(p);
    If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ',') Then
      LexNext
    Else
      Break;
  Until False;
End;

{ ============================================================
  ParseExtrn : EXTRN nom:type [, nom:type ...]
  Cree le symbole comme SK_EXTERN, enregistre dans extdef_table.
  La valeur du symbole = index EXTDEF (pour GenFixup).
  ============================================================ }
Procedure ParseExtrn;
Var
  tok  : TSymString;
  tnam : TString;
  sz   : Integer;
  idx  : Integer;
  p    : PSymbol;
Begin
  Repeat
    If LexPeekKind <> TK_IDENT Then Break;
    LexNext;
    tok := lex_tok.val;
    sz  := 0;
    { consommer :type }
    If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ':') Then
    Begin
      LexNext;
      If LexPeekKind = TK_IDENT Then
      Begin
        LexNext;
        tnam := lex_tok.val;
        sz   := TypeNameToSize(tnam);
      End
      Else
        WarnMsg('Type attendu apres : dans EXTRN');
    End
    Else
      WarnMsg(': manquant dans EXTRN pour ' + tok);

    { enregistrer dans extdef_table }
    idx := ExtdefRegister(tok);
    extdef_types[idx] := sz;

    { creer ou mettre a jour le symbole }
    p := SymFind(tok);
    If p = Nil Then
      p := SymEnter(tok, SK_EXTERN, 0, 0, sz)
    Else
    Begin
      If p^.kind = SK_LABEL Then
        WarnMsg('EXTRN redefinit un label local : ' + tok)
      Else
      Begin
        p^.kind := SK_EXTERN;
        p^.size := sz;
      End;
    End;
    SymSetExtern(p);
    SymSetValue(p, idx); { valeur = index EXTDEF pour GenFixup }

    If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ',') Then
      LexNext
    Else
      Break;
  Until False;
End;

{ ============================================================
  ParseGlobal : GLOBAL nom:type [, nom:type ...]
  PUBLIC si le symbole est defini localement, EXTRN sinon.
  ============================================================ }
Procedure ParseGlobal;
Var
  tok  : TSymString;
  tnam : TString;
  sz   : Integer;
  p    : PSymbol;
  idx  : Integer;
Begin
  Repeat
    If LexPeekKind <> TK_IDENT Then Break;
    LexNext;
    tok := lex_tok.val;
    sz  := 0;
    If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ':') Then
    Begin
      LexNext;
      If LexPeekKind = TK_IDENT Then
      Begin
        LexNext;
        tnam := lex_tok.val;
        sz   := TypeNameToSize(tnam);
      End;
    End;

    p := SymFind(tok);
    If (p <> Nil) And (p^.kind = SK_LABEL) Then
    Begin
      { defini localement -> PUBLIC }
      SymSetPublic(p);
      PubdefRegister(p);
    End
    Else
    Begin
      { pas encore defini -> EXTRN }
      idx := ExtdefRegister(tok);
      extdef_types[idx] := sz;
      If p = Nil Then
        p := SymEnter(tok, SK_EXTERN, 0, 0, sz)
      Else
      Begin
        p^.kind := SK_EXTERN;
        p^.size := sz;
      End;
      SymSetExtern(p);
      SymSetValue(p, idx);
    End;

    If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ',') Then
      LexNext
    Else
      Break;
  Until False;
End;

{ ============================================================
  ObjComdefPutLen : ecrire un entier en format variable COMDEF
    1..127       : 1 octet
    128..65535   : 81h + 2 octets LE
    >= 65536     : 84h + 4 octets LE (extension 32 bits)
  ============================================================ }
Procedure ObjComdefPutLen(n : LongInt);
Begin
  If n < 128 Then
    ObjPutByte(Byte(n))
  Else If n < 65536 Then
  Begin
    ObjPutByte($81);
    ObjPutWord(Word(n));
  End
  Else
  Begin
    ObjPutByte($84);
    ObjPutDWord(n);
  End;
End;

{ ============================================================
  ParseComm : COMM [NEAR|FAR] nom:type[:count] [, ...]
  Emet un record COMDEF (B0h).
  type = taille en octets d un element.
  count = nombre d elements (1 par defaut), optionnel.
  ============================================================ }
Procedure ParseComm;
Var
  tok    : TSymString;
  tnam   : TString;
  sz     : Integer;
  cnt    : LongInt;
  is_far : Boolean;
  p      : PSymbol;
Begin
  Repeat
    is_far := False;
    { NEAR ou FAR optionnel }
    If LexPeekKind = TK_IDENT Then
    Begin
      If LexPeekVal = 'FAR'  Then Begin LexNext; is_far := True; End
      Else If LexPeekVal = 'NEAR' Then LexNext;
    End;

    If LexPeekKind <> TK_IDENT Then Break;
    LexNext;
    tok := lex_tok.val;
    sz  := 2; { WORD par defaut }
    cnt := 1;

    { :type }
    If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ':') Then
    Begin
      LexNext;
      If LexPeekKind = TK_IDENT Then
      Begin
        LexNext;
        tnam := lex_tok.val;
        sz   := TypeNameToSize(tnam);
        If sz = 0 Then sz := 2;
      End
      Else If LexPeekKind = TK_NUMBER Then
      Begin
        LexNext;
        sz := Integer(lex_tok.num_val);
      End;
    End;

    { :count optionnel }
    If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ':') Then
    Begin
      LexNext;
      cnt := EvalConstExpr;
    End;

    { creer le symbole comme SK_EXTERN }
    p := SymFind(tok);
    If p = Nil Then
      p := SymEnter(tok, SK_EXTERN, 0, 0, sz);
    SymSetExtern(p);

    { ecrire le record COMDEF }
    ObjBeginRecord(OMF_COMDEF);
    ObjPutStr(tok);      { nom }
    ObjPutIndex(0);      { type index = 0 }
    If is_far Then
      ObjPutByte($62)    { far BSS }
    Else
      ObjPutByte($61);   { near BSS }
    { near BSS : un seul champ = taille totale = sz * cnt }
    ObjComdefPutLen(LongInt(sz) * cnt);
    If is_far Then
      ObjComdefPutLen(sz); { element size pour far }
    ObjEndRecord;

    If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ',') Then
      LexNext
    Else
      Break;
  Until False;
End;

{ ============================================================
  EmitAllExtDefs : emettre un record EXTDEF par symbole EXTRN.
  Appele au debut de la generation du .OBJ (avant LEDATA).
  ============================================================ }
Procedure EmitAllExtDefs;
Var
  i : Integer;
Begin
  For i := 1 To extdef_count Do
    ObjEXTDEF(extdef_names[i], 0);
End;

{ ============================================================
  EmitAllPubDefs : emettre les records PUBDEF pour tous les
  symboles marques PUBLIC. Groupe par segment pour minimiser
  le nombre de records.
  ============================================================ }
Procedure EmitAllPubDefs;
Var
  i    : Integer;
  p    : PSymbol;
  seg  : Integer;
  grp  : Integer;
  sidx : Integer;
Begin
  { pour chaque segment, emettre les PUBDEF des symboles de ce seg }
  For seg := 0 To seg_count Do  { seg=0 = absolu }
  Begin
    For i := 1 To pubdef_count Do
    Begin
      p := pubdef_syms[i];
      If p = Nil Then Continue;
      If p^.kind = SK_UNDEF Then Continue; { forward non resolu }
      sidx := p^.seg_idx;
      If sidx <> seg Then Continue;

      { chercher le groupe contenant ce segment }
      If sidx > 0 Then
        grp := SegGetGroup(sidx)
      Else
        grp := 0;

      ObjPUBDEF(grp, sidx, p^.name, p^.offset, 0);
    End;
  End;
End;

{ ============================================================
  ENCODAGE DES INSTRUCTIONS 8086 (MOV ADD SUB etc.)
  ============================================================

  Types d operandes :
    OK_REG   : registre general (r8 ou r16)
    OK_SREG  : registre de segment (ES CS SS DS)
    OK_MEM   : adresse memoire ([BX+SI+disp] etc.)
    OK_IMM   : immediat
    OK_NONE  : absent / non parse

  Octet ModRM : bits 7-6 = mod, bits 5-3 = reg, bits 2-0 = r/m
  Table EA 8086 r/m :
    0=[BX+SI]  1=[BX+DI]  2=[BP+SI]  3=[BP+DI]
    4=[SI]     5=[DI]     6=[disp16] 7=[BX]
  mod=00 -> [r/m]  (r/m=6 -> disp16 direct)
  mod=01 -> [r/m + disp8]
  mod=10 -> [r/m + disp16]
  mod=11 -> registre
  ============================================================ }

{ ---- Type operande ---- }
Type
  TOpKind = (OK_NONE, OK_REG, OK_SREG, OK_MEM, OK_IMM);

  TOperand = Record
    kind       : TOpKind;
    is_word    : Boolean;  { True = 16 bits (r16 ou m16 ou imm16) }
    reg        : Integer;  { OK_REG/OK_SREG : indice 0-7 }
    { memoire }
    rm         : Integer;  { r/m field 0-7 }
    mod_bits   : Integer;  { mod 0-3 }
    disp       : TLong;    { deplacement }
    disp_size  : Integer;  { 0=aucun, 1=byte, 2=word }
    seg_ovr    : Integer;  { 0=aucun, $26,$2E,$36,$3E = prefixe }
    is_reloc   : Boolean;  { adresse relocalisable }
    reloc_seg  : Integer;  { index segment }
    { immediat }
    imm        : TLong;
    imm_reloc  : Boolean;
    imm_rseg   : Integer;
    { taille forcee par PTR }
    ptr_size   : Integer;  { 0=non force, 1, 2, 4 }
  End;

{ ---- Registres ---- }
Const
  REG_AX = 0; REG_CX = 1; REG_DX = 2; REG_BX = 3;
  REG_SP = 4; REG_BP = 5; REG_SI = 6; REG_DI = 7;
  REG_AL = 0; REG_CL = 1; REG_DL = 2; REG_BL = 3;
  REG_AH = 4; REG_CH = 5; REG_DH = 6; REG_BH = 7;
  REG_ES = 0; REG_CS = 1; REG_SS = 2; REG_DS = 3;

{ ---- helper : reset d un operande ---- }
Procedure ClearOp(Var op : TOperand);
Begin
  op.kind      := OK_NONE;
  op.is_word   := False;
  op.reg       := -1;
  op.rm        := 0;
  op.mod_bits  := 0;
  op.disp      := 0;
  op.disp_size := 0;
  op.seg_ovr   := 0;
  op.is_reloc  := False;
  op.reloc_seg := 0;
  op.imm       := 0;
  op.imm_reloc := False;
  op.imm_rseg  := 0;
  op.ptr_size  := 0;
End;

{ ---- Table des registres pour RegIndex ---- }
Const
  { 1..8  : registres 16 bits  (is_word=True)  idx = r-1  }
  { 9..16 : registres 8 bits                   idx = r-9  }
  { 17..20: registres de segment (is_seg=True)  idx = r-17 }
  RI_COUNT = 20;
  RI_NAMES : Array[1..20] Of String[2] = (
    'AX','CX','DX','BX','SP','BP','SI','DI',   { 1-8  : 16 bits }
    'AL','CL','DL','BL','AH','CH','DH','BH',   { 9-16 :  8 bits }
    'ES','CS','SS','DS'                         { 17-20: segment }
  );

{ ============================================================
  RegIndex : convertir un nom de registre en indice 0-7.
  Retourne -1 si pas un registre general ou segment.
  is_word_out : True si c est un registre 16 bits.
  is_seg_out  : True si c est un registre de segment.
  ============================================================ }
Procedure RegIndex(Const name : TString;
                   Var idx      : Integer;
                   Var is_word  : Boolean;
                   Var is_seg   : Boolean);
Var r, i : Integer;
Begin
  is_seg  := False;
  is_word := False;
  idx     := -1;
  r := 0;
  For i := 1 To RI_COUNT Do
    If RI_NAMES[i] = name Then Begin r := i; Break; End;
  Case r Of
    1..8  : Begin idx := r - 1;  is_word := True; End;
    9..16 : idx := r - 9;
    17..20: Begin idx := r - 17; is_seg  := True; End;
  End;
End;

{ ============================================================
  SegrOverridePrefix : retourner le prefixe de segment ou 0
  ============================================================ }
Const SO_COUNT = 4;
      SO_NAMES: Array[1..4] Of String[2] = ('ES','CS','SS','DS');
      SO_OPC:   Array[1..4] Of Byte      = ($26,$2E,$36,$3E);

Function SegOvrByte(Const seg_name : TString) : Integer;
Var i : Integer;
Begin
  For i := 1 To SO_COUNT Do
    If SO_NAMES[i] = seg_name Then Begin SegOvrByte := SO_OPC[i]; Exit; End;
  SegOvrByte := 0;
End;

{ ============================================================
  CalcModRM : calculer mod, rm a partir de BX/BP/SI/DI +
  deplacement. Retourne False si la combinaison est invalide.
  Parametres : has_bx,has_bp,has_si,has_di,disp,disp_sz
  ============================================================ }
Function CalcModRM(has_bx, has_bp, has_si, has_di : Boolean;
                   disp : TLong; disp_sz : Integer;
                   Var rm : Integer; Var mod_out : Integer;
                   Var disp_out : TLong; Var dsz_out : Integer) : Boolean;
Begin
  disp_out := disp;
  dsz_out  := disp_sz;
  CalcModRM := True;

  { BX+SI=0, BX+DI=1, BP+SI=2, BP+DI=3, SI=4, DI=5, BP=6, BX=7 }
  If      has_bx And has_si Then rm := 0
  Else If has_bx And has_di Then rm := 1
  Else If has_bp And has_si Then rm := 2
  Else If has_bp And has_di Then rm := 3
  Else If (Not has_bx) And (Not has_bp) And has_si And (Not has_di) Then rm := 4
  Else If (Not has_bx) And (Not has_bp) And (Not has_si) And has_di Then rm := 5
  Else If has_bp And (Not has_si) And (Not has_di) Then rm := 6
  Else If has_bx And (Not has_si) And (Not has_di) Then rm := 7
  Else
  Begin
    CalcModRM := False;
    Exit;
  End;

  { calcul du mod selon le deplacement }
  If (disp_sz = 0) And (rm <> 6) Then
    mod_out := 0
  Else If rm = 6 Then
  Begin
    { [BP] sans disp -> disp=0, mod=01 }
    If disp_sz = 0 Then
    Begin
      dsz_out := 1;
      disp_out := 0;
    End;
    If dsz_out = 1 Then mod_out := 1
    Else               mod_out := 2;
  End
  Else If disp_sz = 1 Then
    mod_out := 1
  Else
    mod_out := 2;
End;

{ ============================================================
  ParseEA : parser un mode d adressage memoire entre [ ]
  (le [ a deja ete consomme par l appelant).
  Remplit les champs rm, mod_bits, disp, disp_size, seg_ovr.
  ============================================================ }
Procedure ParseEA(Var op : TOperand);
Var
  has_bx, has_bp, has_si, has_di : Boolean;
  sign    : Integer;
  disp    : TLong;
  disp_sz : Integer;
  tok     : TString;
  ridx    : Integer;
  rword   : Boolean;
  rseg    : Boolean;
  e       : TExpr;
  ok      : Boolean;
Begin
  has_bx := False; has_bp := False;
  has_si := False; has_di := False;
  disp   := 0;
  disp_sz := 0;
  sign   := 1;
  op.seg_ovr := 0;

  { consommer les composantes jusqu au ] }
  While True Do
  Begin
    { signe + ou - }
    If LexPeekKind = TK_PUNCT Then
    Begin
      If LexPeekVal = '+' Then Begin LexNext; sign :=  1; End
      Else If LexPeekVal = '-' Then Begin LexNext; sign := -1; End
      Else If LexPeekVal = ']' Then Break
      Else Break;
    End;

    If LexPeekKind = TK_IDENT Then
    Begin
      tok := LexPeekVal;
      { prefixe de segment seg: }
      If SegOvrByte(tok) > 0 Then
      Begin
        LexNext;
        op.seg_ovr := SegOvrByte(tok);
        { consommer le : }
        If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ':') Then
          LexNext;
        sign := 1;
        Continue;
      End;
      { registre de base/index }
      RegIndex(tok, ridx, rword, rseg);
      If ridx >= 0 Then
      Begin
        LexNext;
        Case ridx Of
          REG_BX : has_bx := True;
          REG_BP : has_bp := True;
          REG_SI : has_si := True;
          REG_DI : has_di := True;
        Else
          WarnMsg('Registre invalide dans EA : ' + tok);
        End;
        sign := 1;
        Continue;
      End;
    End;

    { expression numerique (deplacement) }
    If LexPeekKind <> TK_PUNCT Then
    Begin
      EvalExpr(e);
      disp    := disp + sign * e.val;
      disp_sz := 2;
      If e.is_reloc Then
      Begin
        op.is_reloc  := True;
        op.reloc_seg := e.seg_idx;
      End;
      sign := 1;
      Continue;
    End;

    Break;
  End;

  { consommer ] }
  If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ']') Then
    LexNext
  Else
    WarnMsg('] manquant dans adressage memoire');

  { calculer disp_sz si pas encore determine }
  If (disp_sz = 0) And (disp <> 0) Then
  Begin
    If (disp >= -128) And (disp <= 127) Then disp_sz := 1
    Else disp_sz := 2;
  End
  Else If disp_sz = 2 Then
  Begin
    { si aucun registre de base/index, c est une adresse directe }
    If (Not has_bx) And (Not has_bp) And (Not has_si) And (Not has_di) Then
    Begin
      { mod=00, rm=6 : [disp16] }
      op.mod_bits  := 0;
      op.rm        := 6;
      op.disp      := disp;
      op.disp_size := 2;
      Exit;
    End;
  End;

  { adresse directe sans registre et disp = 0 -> [0000] = [disp16] avec disp=0 }
  If (Not has_bx) And (Not has_bp) And (Not has_si) And (Not has_di) Then
  Begin
    op.mod_bits  := 0;
    op.rm        := 6;
    op.disp      := disp;
    op.disp_size := 2;
    Exit;
  End;

  ok := CalcModRM(has_bx, has_bp, has_si, has_di,
                  disp, disp_sz,
                  op.rm, op.mod_bits, op.disp, op.disp_size);
  If Not ok Then
  Begin
    ErrorMsg('Combinaison de registres EA invalide');
    op.rm        := 7; { [BX] par defaut }
    op.mod_bits  := 0;
    op.disp      := 0;
    op.disp_size := 0;
  End;
End;

{ ---- Table des prefixes de taille pour ParseOperand ---- }
Const
  PO_COUNT = 5;
  PO_NAMES : Array[1..5] Of String[5] = ('BYTE','WORD','DWORD','NEAR','FAR');
  PO_SIZES : Array[1..5] Of Byte      = (1, 2, 4, 2, 4);

{ ============================================================
  ParseOperand : parser un operande global
  ============================================================ }
Procedure ParseOperand(Var op : TOperand);
Var
  tok     : TString;
  ridx    : Integer;
  rword   : Boolean;
  rseg    : Boolean;
  ovr     : Integer;
  e       : TExpr;
  sz_hint : Integer;
  po_idx  : Integer;
  i       : Integer;
Begin
  ClearOp(op);
  sz_hint := 0;

  If LexPeekKind = TK_EOF Then Exit;

  { prefixe de taille BYTE PTR / WORD PTR / DWORD PTR }
  If LexPeekKind = TK_IDENT Then
  Begin
    tok := LexPeekVal;
    po_idx := 0;
    For i := 1 To PO_COUNT Do
      If PO_NAMES[i] = tok Then Begin po_idx := i; Break; End;
    If po_idx > 0 Then
    Begin
      LexNext;
      sz_hint := PO_SIZES[po_idx];
      If (LexPeekKind = TK_IDENT) And (LexPeekVal = 'PTR') Then
        LexNext;
    End;
  End;

  { prefixe de segment seg: expr_or_[ }
  ovr := 0;
  If LexPeekKind = TK_IDENT Then
  Begin
    tok := LexPeekVal;
    ovr := SegOvrByte(tok);
    If ovr > 0 Then
    Begin
      LexNext;
      If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ':') Then
        LexNext    { consommer ':' : c est un prefixe de surcharge }
      Else
      Begin
        { pas de ':' -> c est un registre de segment (ex: MOV DS, AX) }
        RegIndex(tok, ridx, rword, rseg);
        op.kind    := OK_SREG;
        op.reg     := ridx;
        op.is_word := True;
        If sz_hint > 0 Then op.ptr_size := sz_hint;
        Exit;
      End;
    End
    Else
      ovr := 0;
  End;

  { registre ou mot-cle }
  If LexPeekKind = TK_IDENT Then
  Begin
    tok := LexPeekVal;
    RegIndex(tok, ridx, rword, rseg);
    If ridx >= 0 Then
    Begin
      LexNext;
      If rseg Then
      Begin
        op.kind    := OK_SREG;
        op.reg     := ridx;
        op.is_word := True;
      End
      Else
      Begin
        op.kind    := OK_REG;
        op.reg     := ridx;
        op.is_word := rword;
      End;
      If sz_hint > 0 Then op.ptr_size := sz_hint;
      op.seg_ovr := ovr;
      Exit;
    End;
  End;

  { [ -> adressage memoire }
  If (LexPeekKind = TK_PUNCT) And (LexPeekVal = '[') Then
  Begin
    LexNext; { consommer [ }
    op.kind    := OK_MEM;
    op.seg_ovr := ovr;
    If sz_hint > 0 Then
    Begin
      op.ptr_size := sz_hint;
      op.is_word  := (sz_hint >= 2);
    End;
    ParseEA(op);
    Exit;
  End;

  { expression -> immediat ou adresse directe }
  EvalExpr(e);
  If e.is_reloc And (sz_hint = 0) Then
  Begin
    { adresse de label sans [] -> OK_MEM direct }
    op.kind      := OK_MEM;
    op.mod_bits  := 0;
    op.rm        := 6;
    op.disp      := e.val;
    op.disp_size := 2;
    op.is_reloc  := True;
    op.reloc_seg := e.seg_idx;
    op.seg_ovr   := ovr;
    If sz_hint > 0 Then op.is_word := (sz_hint >= 2);
  End
  Else
  Begin
    op.kind      := OK_IMM;
    op.imm       := e.val;
    op.imm_reloc := e.is_reloc;
    op.imm_rseg  := e.seg_idx;
    op.ptr_size  := sz_hint;
  End;
End;

{ ============================================================
  EmitModRM : emettre prefixe de segment + octet ModRM +
  deplacement pour l operande memoire/registre.
  reg_fld = bits 5-3 de ModRM (code registre ou opcode etendu).
  ============================================================ }
Procedure EmitModRM(reg_fld : Integer; Const op : TOperand);
Var
  modrm : Byte;
Begin
  { prefixe de segment }
  If op.seg_ovr > 0 Then
    EmitByte(op.seg_ovr);

  If op.kind = OK_REG Then
  Begin
    modrm := Byte($C0 Or (reg_fld Shl 3) Or op.reg);
    EmitByte(modrm);
  End
  Else { OK_MEM }
  Begin
    modrm := Byte((op.mod_bits Shl 6) Or (reg_fld Shl 3) Or op.rm);
    EmitByte(modrm);
    { deplacement }
    If op.disp_size = 1 Then
      EmitByte(Byte(op.disp And $FF))
    Else If op.disp_size = 2 Then
    Begin
      If op.is_reloc Then
        GenFixup(FIXUP_OFFSET, FIXUP_TARGET_SEG, op.reloc_seg,
                 Word(op.disp), True);
      EmitWord(Word(op.disp));
    End;
  End;
End;

{ ============================================================
  NeedWordSz : determiner si on travaille en 16 bits selon
  les deux operandes. Signale une erreur si incoherent.
  ============================================================ }
Function NeedWordSz(Const op1, op2 : TOperand) : Boolean;
Var
  w1, w2 : Boolean;
Begin
  w1 := False; w2 := False;
  If op1.kind = OK_REG Then w1 := op1.is_word;
  If op2.kind = OK_REG Then w2 := op2.is_word;
  If op1.ptr_size > 0 Then w1 := (op1.ptr_size >= 2);
  If op2.ptr_size > 0 Then w2 := (op2.ptr_size >= 2);

  { si l un est connu et l autre inconnu (IMM ou MEM sans PTR) }
  If op1.kind = OK_IMM Then
  Begin
    NeedWordSz := w2;
    Exit;
  End;
  If op2.kind = OK_IMM Then
  Begin
    NeedWordSz := w1;
    Exit;
  End;
  If op1.kind = OK_MEM Then
  Begin
    NeedWordSz := w2;
    Exit;
  End;
  If op2.kind = OK_MEM Then
  Begin
    NeedWordSz := w1;
    Exit;
  End;
  NeedWordSz := w1; { par defaut }
End;

{ ============================================================
  EncodeArith : encodage groupe ADD/OR/ADC/SBB/AND/SUB/XOR/CMP
  op_grp = 0=ADD 1=OR 2=ADC 3=SBB 4=AND 5=SUB 6=XOR 7=CMP
  Syntaxe : OP dst, src
  ============================================================ }
Procedure EncodeArith(op_grp : Integer);
Var
  dst, src : TOperand;
  is_word  : Boolean;
  imm8sign : Boolean;
Begin
  ParseOperand(dst);
  If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ',') Then LexNext;
  ParseOperand(src);

  is_word := NeedWordSz(dst, src);

  { immediat : choisir forme courte (83) si imm8 signee en 16 bits }
  If src.kind = OK_IMM Then
  Begin
    imm8sign := is_word And (src.imm >= -128) And (src.imm <= 127);
    { forme accumulateur court }
    If (dst.kind = OK_REG) And (dst.reg = 0) And (Not imm8sign) Then
    Begin
      If is_word Then
      Begin
        EmitByte(Byte((op_grp Shl 3) Or $05)); { OP AX, imm16 }
        EmitWord(Word(src.imm));
      End
      Else
      Begin
        EmitByte(Byte((op_grp Shl 3) Or $04)); { OP AL, imm8 }
        EmitByte(Byte(src.imm));
      End;
      Exit;
    End;
    { forme generale }
    If imm8sign Then
    Begin
      EmitByte($83); { OP r/m16, imm8 sign-extend }
      EmitModRM(op_grp, dst);
      EmitByte(Byte(src.imm And $FF));
    End
    Else If is_word Then
    Begin
      EmitByte($81); { OP r/m16, imm16 }
      EmitModRM(op_grp, dst);
      EmitWord(Word(src.imm));
    End
    Else
    Begin
      EmitByte($80); { OP r/m8, imm8 }
      EmitModRM(op_grp, dst);
      EmitByte(Byte(src.imm));
    End;
    Exit;
  End;

  { registre -> memoire/registre }
  If src.kind = OK_REG Then
  Begin
    If is_word Then
      EmitByte(Byte((op_grp Shl 3) Or $01)) { OP r/m16, r16 }
    Else
      EmitByte(Byte((op_grp Shl 3) Or $00)); { OP r/m8, r8 }
    EmitModRM(src.reg, dst);
    Exit;
  End;

  { memoire -> registre }
  If src.kind = OK_MEM Then
  Begin
    If is_word Then
      EmitByte(Byte((op_grp Shl 3) Or $03)) { OP r16, r/m16 }
    Else
      EmitByte(Byte((op_grp Shl 3) Or $02)); { OP r8, r/m8 }
    EmitModRM(dst.reg, src);
    Exit;
  End;

  ErrorMsg('Operandes invalides pour instruction arithmetique');
End;

{ ============================================================
  EncodeMOV : encodage MOV dst, src
  ============================================================ }
Procedure EncodeMOV;
Var
  dst, src : TOperand;
  is_word  : Boolean;
Begin
  ParseOperand(dst);
  If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ',') Then LexNext;
  ParseOperand(src);

  is_word := NeedWordSz(dst, src);

  { MOV r, imm }
  If (dst.kind = OK_REG) And (src.kind = OK_IMM) Then
  Begin
    If is_word Then
    Begin
      EmitByte(Byte($B8 Or dst.reg));
      If src.imm_reloc Then
        GenFixup(FIXUP_OFFSET, FIXUP_TARGET_SEG, src.imm_rseg,
                 Word(src.imm), True);
      EmitWord(Word(src.imm));
    End
    Else
    Begin
      EmitByte(Byte($B0 Or dst.reg));
      EmitByte(Byte(src.imm));
    End;
    Exit;
  End;

  { MOV r/m, imm }
  If (dst.kind = OK_MEM) And (src.kind = OK_IMM) Then
  Begin
    If is_word Then
    Begin
      EmitByte($C7);
      EmitModRM(0, dst);
      If src.imm_reloc Then
        GenFixup(FIXUP_OFFSET, FIXUP_TARGET_SEG, src.imm_rseg,
                 Word(src.imm), True);
      EmitWord(Word(src.imm));
    End
    Else
    Begin
      EmitByte($C6);
      EmitModRM(0, dst);
      EmitByte(Byte(src.imm));
    End;
    Exit;
  End;

  { MOV r/m, sreg }
  If src.kind = OK_SREG Then
  Begin
    EmitByte($8C);
    EmitModRM(src.reg, dst);
    Exit;
  End;

  { MOV sreg, r/m }
  If dst.kind = OK_SREG Then
  Begin
    EmitByte($8E);
    EmitModRM(dst.reg, src);
    Exit;
  End;

  { MOV r/m16, r16 ou r16, r/m16 }
  If src.kind = OK_REG Then
  Begin
    If is_word Then EmitByte($89) Else EmitByte($88);
    EmitModRM(src.reg, dst);
    Exit;
  End;
  If src.kind = OK_MEM Then
  Begin
    If is_word Then EmitByte($8B) Else EmitByte($8A);
    EmitModRM(dst.reg, src);
    Exit;
  End;
  If dst.kind = OK_REG Then
  Begin
    If is_word Then EmitByte($8B) Else EmitByte($8A);
    EmitModRM(dst.reg, src);
    Exit;
  End;

  ErrorMsg('Operandes invalides pour MOV');
End;

{ ============================================================
  EncodeIncDec : INC ou DEC
  ============================================================ }
Procedure EncodeIncDec(is_dec : Boolean);
Var
  op      : TOperand;
  is_word : Boolean;
  grp     : Integer;
Begin
  ParseOperand(op);
  is_word := op.is_word Or (op.ptr_size >= 2);
  If op.ptr_size = 1 Then is_word := False;
  If is_dec Then grp := 1 Else grp := 0;

  { registre 16 bits : forme courte }
  If (op.kind = OK_REG) And is_word Then
  Begin
    If is_dec Then EmitByte(Byte($48 Or op.reg))
    Else           EmitByte(Byte($40 Or op.reg));
    Exit;
  End;

  { r/m8 ou r/m16 }
  If is_word Then EmitByte($FF) Else EmitByte($FE);
  EmitModRM(grp, op);
End;

{ ============================================================
  EncodeNotNeg : NOT ou NEG
  ============================================================ }
Procedure EncodeNotNeg(is_neg : Boolean);
Var
  op      : TOperand;
  is_word : Boolean;
  grp     : Integer;
Begin
  ParseOperand(op);
  is_word := op.is_word Or (op.ptr_size >= 2);
  If op.ptr_size = 1 Then is_word := False;
  If is_neg Then grp := 3 Else grp := 2;
  If is_word Then EmitByte($F7) Else EmitByte($F6);
  EmitModRM(grp, op);
End;

{ ============================================================
  EncodeXCHG : XCHG dst, src
  ============================================================ }
Procedure EncodeXCHG;
Var
  dst, src : TOperand;
  is_word  : Boolean;
Begin
  ParseOperand(dst);
  If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ',') Then LexNext;
  ParseOperand(src);
  is_word := NeedWordSz(dst, src);

  { forme courte AX,r16 ou r16,AX }
  If is_word Then
  Begin
    If (dst.kind = OK_REG) And (dst.reg = 0) And (src.kind = OK_REG) Then
    Begin
      EmitByte(Byte($90 Or src.reg));
      Exit;
    End;
    If (src.kind = OK_REG) And (src.reg = 0) And (dst.kind = OK_REG) Then
    Begin
      EmitByte(Byte($90 Or dst.reg));
      Exit;
    End;
  End;

  If src.kind = OK_REG Then
  Begin
    If is_word Then EmitByte($87) Else EmitByte($86);
    EmitModRM(src.reg, dst);
  End
  Else If dst.kind = OK_REG Then
  Begin
    If is_word Then EmitByte($87) Else EmitByte($86);
    EmitModRM(dst.reg, src);
  End
  Else
    ErrorMsg('XCHG : un operande doit etre un registre');
End;

{ ============================================================
  EncodeLEA_LxS : LEA / LDS / LES r16, mem
  ============================================================ }
Procedure EncodeLEA_LxS(opcode : Byte);
Var
  dst, src : TOperand;
Begin
  ParseOperand(dst);
  If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ',') Then LexNext;
  ParseOperand(src);
  If dst.kind <> OK_REG Then
    ErrorMsg('LEA/LDS/LES : premier operande doit etre un registre');
  EmitByte(opcode);
  EmitModRM(dst.reg, src);
End;

{ ============================================================
  EncodeTEST : TEST dst, src
  ============================================================ }
Procedure EncodeTEST;
Var
  dst, src : TOperand;
  is_word  : Boolean;
Begin
  ParseOperand(dst);
  If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ',') Then LexNext;
  ParseOperand(src);
  is_word := NeedWordSz(dst, src);

  If src.kind = OK_IMM Then
  Begin
    { TEST avec accumulateur }
    If (dst.kind = OK_REG) And (dst.reg = 0) Then
    Begin
      If is_word Then
      Begin
        EmitByte($A9);
        EmitWord(Word(src.imm));
      End
      Else
      Begin
        EmitByte($A8);
        EmitByte(Byte(src.imm));
      End;
    End
    Else
    Begin
      If is_word Then EmitByte($F7) Else EmitByte($F6);
      EmitModRM(0, dst);
      If is_word Then EmitWord(Word(src.imm))
      Else            EmitByte(Byte(src.imm));
    End;
    Exit;
  End;

  If src.kind = OK_REG Then
  Begin
    If is_word Then EmitByte($85) Else EmitByte($84);
    EmitModRM(src.reg, dst);
    Exit;
  End;

  If dst.kind = OK_REG Then
  Begin
    If is_word Then EmitByte($85) Else EmitByte($84);
    EmitModRM(dst.reg, src);
    Exit;
  End;

  ErrorMsg('TEST : operandes invalides');
End;

{ ============================================================
  Table unifiee des instructions machine (groupes 12-15)
  ============================================================ }
Const
  { --- Groupe 12 : MOV, arithmetique, logique --- }
  IN_MOV   =  1;  IN_ADD   =  2;  IN_OR    =  3;  IN_ADC   =  4;
  IN_SBB   =  5;  IN_AND   =  6;  IN_SUB   =  7;  IN_XOR   =  8;
  IN_CMP   =  9;  IN_INC   = 10;  IN_DEC   = 11;  IN_NOT   = 12;
  IN_NEG   = 13;  IN_XCHG  = 14;  IN_LEA   = 15;  IN_LDS   = 16;
  IN_LES   = 17;  IN_TEST  = 18;
  { --- Groupe 13 : sauts, appels, Jcc --- }
  IN_JMP    = 19;  IN_CALL   = 20;  IN_RET    = 21;
  IN_RETF   = 22;  IN_RETN   = 23;  IN_JCXZ   = 24;
  IN_LOOP   = 25;  IN_LOOPE  = 26;  IN_LOOPZ  = 27;
  IN_LOOPNE = 28;  IN_LOOPNZ = 29;
  IN_JO     = 30;  IN_JNO    = 31;
  IN_JB     = 32;  IN_JNAE   = 33;  IN_JC     = 34;
  IN_JNB    = 35;  IN_JAE    = 36;  IN_JNC    = 37;
  IN_JE     = 38;  IN_JZ     = 39;
  IN_JNE    = 40;  IN_JNZ    = 41;
  IN_JBE    = 42;  IN_JNA    = 43;
  IN_JNBE   = 44;  IN_JA     = 45;
  IN_JS     = 46;  IN_JNS    = 47;
  IN_JP     = 48;  IN_JPE    = 49;
  IN_JNP    = 50;  IN_JPO    = 51;
  IN_JL     = 52;  IN_JNGE   = 53;
  IN_JNL    = 54;  IN_JGE    = 55;
  IN_JLE    = 56;  IN_JNG    = 57;
  IN_JNLE   = 58;  IN_JG     = 59;
  { --- Groupe 14 : arithmetique etendue, shifts, flags --- }
  IN_MUL   = 60;  IN_IMUL  = 61;  IN_DIV   = 62;  IN_IDIV  = 63;
  IN_CBW   = 64;  IN_CWD   = 65;
  IN_AAA   = 66;  IN_AAS   = 67;  IN_DAA   = 68;  IN_DAS   = 69;
  IN_AAM   = 70;  IN_AAD   = 71;
  IN_ROL   = 72;  IN_ROR   = 73;  IN_RCL   = 74;  IN_RCR   = 75;
  IN_SHL   = 76;  IN_SAL   = 77;  IN_SHR   = 78;  IN_SAR   = 79;
  IN_STC   = 80;  IN_CLC   = 81;  IN_CMC   = 82;
  IN_STD   = 83;  IN_CLD   = 84;  IN_STI   = 85;  IN_CLI   = 86;
  IN_PUSHF = 87;  IN_POPF  = 88;  IN_SAHF  = 89;  IN_LAHF  = 90;
  IN_XLAT  = 91;  IN_XLATB = 92;
  { --- Groupe 15 : PUSH/POP, chaines, E/S, divers --- }
  IN_PUSH  =  93;  IN_POP   =  94;  IN_PUSHA =  95;  IN_POPA  =  96;
  IN_REP   =  97;  IN_REPE  =  98;  IN_REPZ  =  99;
  IN_REPNE = 100;  IN_REPNZ = 101;
  IN_MOVSB = 102;  IN_MOVSW = 103;  IN_MOVS  = 104;
  IN_CMPSB = 105;  IN_CMPSW = 106;
  IN_SCASB = 107;  IN_SCASW = 108;
  IN_STOSB = 109;  IN_STOSW = 110;
  IN_LODSB = 111;  IN_LODSW = 112;
  IN_IN    = 113;  IN_OUT   = 114;
  IN_INT   = 115;  IN_INT3  = 116;  IN_INTO  = 117;  IN_IRET  = 118;
  IN_HLT   = 119;  IN_NOP   = 120;  IN_WAIT  = 121;
  IN_LOCK  = 122;  IN_ESC   = 123;
  IN_COUNT = 123;
  IN_NAMES : Array[1..IN_COUNT] Of String[6] = (
    { 1-18 : groupe 12 }
    'MOV',   'ADD',    'OR',     'ADC',    'SBB',    'AND',
    'SUB',   'XOR',    'CMP',    'INC',    'DEC',    'NOT',
    'NEG',   'XCHG',   'LEA',    'LDS',    'LES',    'TEST',
    { 19-59 : groupe 13 }
    'JMP',   'CALL',   'RET',    'RETF',   'RETN',   'JCXZ',
    'LOOP',  'LOOPE',  'LOOPZ',  'LOOPNE', 'LOOPNZ',
    'JO',    'JNO',    'JB',     'JNAE',   'JC',
    'JNB',   'JAE',    'JNC',    'JE',     'JZ',
    'JNE',   'JNZ',    'JBE',    'JNA',
    'JNBE',  'JA',     'JS',     'JNS',
    'JP',    'JPE',    'JNP',    'JPO',
    'JL',    'JNGE',   'JNL',    'JGE',
    'JLE',   'JNG',    'JNLE',   'JG',
    { 60-92 : groupe 14 }
    'MUL',   'IMUL',   'DIV',    'IDIV',
    'CBW',   'CWD',
    'AAA',   'AAS',    'DAA',    'DAS',    'AAM',    'AAD',
    'ROL',   'ROR',    'RCL',    'RCR',    'SHL',    'SAL',    'SHR',  'SAR',
    'STC',   'CLC',    'CMC',    'STD',    'CLD',    'STI',    'CLI',
    'PUSHF', 'POPF',   'SAHF',   'LAHF',   'XLAT',   'XLATB',
    { 93-123 : groupe 15 }
    'PUSH',  'POP',    'PUSHA',  'POPA',
    'REP',   'REPE',   'REPZ',   'REPNE',  'REPNZ',
    'MOVSB', 'MOVSW',  'MOVS',   'CMPSB',  'CMPSW',
    'SCASB', 'SCASW',  'STOSB',  'STOSW',  'LODSB',  'LODSW',
    'IN',    'OUT',    'INT',    'INT3',   'INTO',   'IRET',
    'HLT',   'NOP',    'WAIT',   'LOCK',   'ESC'
  );

{ ============================================================
  ENCODAGE DES SAUTS ET APPELS (JMP CALL RET Jcc LOOP)
  ============================================================

  Strategie pour les references avant (forward labels) :
    Pass 1 : emettre des octets de remplissage de la bonne taille
             (0) pour conserver un LC exact. Les labels seront
             definis lors du second passage de la ligne.
    Pass 2 : les offsets de labels sont connus ; calculer le
             deplacement relatif = target_off - (lc_apres_instr).

  JMP SHORT label : EB cb (2 octets)
  JMP [NEAR PTR] label : E9 cw (3 octets) - saut relatif
  JMP FAR PTR off:seg  : EA cw cw (5 octets) - absolu
  JMP r/m16            : FF /4 (2+ octets)
  CALL [NEAR PTR] label: E8 cw (3 octets)
  CALL FAR PTR off:seg : 9A cw cw (5 octets)
  CALL r/m16           : FF /2
  RET  [imm16] : C3 / C2 iw
  RETF [imm16] : CB / CA iw
  Jcc SHORT label : opcode cb (2 octets)
  Jcc label (auto SHORT / inversion pour NEAR) : voir ci-dessous
  JCXZ label  : E3 cb
  LOOP  label : E2 cb
  LOOPE label : E1 cb
  LOOPNE label: E0 cb
  ============================================================ }

{ ---- Table des Jcc pour JccOpcode ---- }
Const
  JCC_COUNT = 30;
  JCC_NAMES : Array[1..30] Of String[4] = (
    'JO',  'JNO',
    'JB',  'JNAE','JC',
    'JNB', 'JAE', 'JNC',
    'JE',  'JZ',
    'JNE', 'JNZ',
    'JBE', 'JNA',
    'JNBE','JA',
    'JS',  'JNS',
    'JP',  'JPE',
    'JNP', 'JPO',
    'JL',  'JNGE',
    'JNL', 'JGE',
    'JLE', 'JNG',
    'JNLE','JG'
  );
  JCC_OPC : Array[1..30] Of Byte = (
    $70, $71,
    $72, $72, $72,
    $73, $73, $73,
    $74, $74,
    $75, $75,
    $76, $76,
    $77, $77,
    $78, $79,
    $7A, $7A,
    $7B, $7B,
    $7C, $7C,
    $7D, $7D,
    $7E, $7E,
    $7F, $7F
  );

{ ============================================================
  JccOpcode : retourner l opcode court (70h-7Fh) d un Jcc,
  ou 0 si non reconnu.
  ============================================================ }
Function JccOpcode(Const mnem : TString) : Byte;
Var i : Integer;
Begin
  For i := 1 To JCC_COUNT Do
    If JCC_NAMES[i] = mnem Then Begin JccOpcode := JCC_OPC[i]; Exit; End;
  JccOpcode := 0;
End;

{ ============================================================
  JccInvert : retourner l opcode inverse d un Jcc (pour forme
  NEAR : Jcc_inv +5 ; JMP NEAR target)
  ============================================================ }
Function JccInvert(opc : Byte) : Byte;
Begin
  { xor le bit 0 du low nibble pour inverser }
  JccInvert := opc Xor 1;
End;

{ ============================================================
  ResolveRelTarget : resoudre un label en deplacement relatif
  par rapport a la position courante du LC (apres l instruction).
  instr_end : offset juste apres l instruction complète.
  Retourne le deplacement (negatif possible).
  ============================================================ }
Function ResolveRelTarget(Const label_name : TString;
                          instr_end : TWord) : TLong;
Var
  p : PSymbol;
Begin
  p := SymFind(label_name);
  If p = Nil Then
  Begin
    If pass_num = 2 Then
      ErrorMsg('Label indefini dans saut : ' + label_name);
    ResolveRelTarget := 0;
    Exit;
  End;
  If (p^.kind = SK_UNDEF) And (pass_num = 1) Then
  Begin
    ResolveRelTarget := 0;
    Exit;
  End;
  ResolveRelTarget := TLong(p^.offset) - TLong(instr_end);
End;

{ ============================================================
  EmitRelJmp : helper - emettre un saut relatif avec cb ou cw.
  emit_near = True -> E9 + cw ; False -> EB + cb.
  ============================================================ }
Procedure EmitRelJmp(opcode : Byte; disp : TLong; is_word : Boolean);
Begin
  EmitByte(opcode);
  If is_word Then
    EmitWord(Word(disp))
  Else
  Begin
    If pass_num = 2 Then
    Begin
      If (disp < -128) Or (disp > 127) Then
        ErrorMsg('Deplacement trop grand pour saut court (SHORT)');
    End;
    EmitByte(Byte(disp And $FF));
  End;
End;

{ ============================================================
  EncodeJMP : JMP [SHORT|NEAR PTR|FAR PTR] cible
             ou JMP r/m16
  ============================================================ }
Procedure EncodeJMP;
Var
  is_short  : Boolean;
  is_far    : Boolean;
  is_near   : Boolean;
  op        : TOperand;
  disp      : TLong;
  lbl       : TString;
  far_off   : TWord;
  far_seg   : TWord;
  e         : TExpr;
  ridx      : Integer;
  rw        : Boolean;
  rs        : Boolean;
Begin
  is_short := False;
  is_far   := False;
  is_near  := False;

  { qualifier SHORT / NEAR PTR / FAR PTR }
  If LexPeekKind = TK_IDENT Then
  Begin
    If LexPeekVal = 'SHORT' Then
    Begin
      LexNext; is_short := True;
    End
    Else If LexPeekVal = 'NEAR' Then
    Begin
      LexNext;
      If (LexPeekKind = TK_IDENT) And (LexPeekVal = 'PTR') Then LexNext;
      is_near := True;
    End
    Else If LexPeekVal = 'FAR' Then
    Begin
      LexNext;
      If (LexPeekKind = TK_IDENT) And (LexPeekVal = 'PTR') Then LexNext;
      is_far := True;
    End;
  End;

  { JMP FAR PTR off:seg (EA cw cw) }
  If is_far Then
  Begin
    EvalExpr(e);
    far_off := Word(e.val);
    { consommer : }
    If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ':') Then LexNext;
    EvalExpr(e);
    far_seg := Word(e.val);
    EmitByte($EA);
    EmitWord(far_off);
    EmitWord(far_seg);
    Exit;
  End;

  { JMP r/m16 : si l operande est un registre ou [mem] et pas un label }
  If (LexPeekKind = TK_PUNCT) And (LexPeekVal = '[') Then
  Begin
    ParseOperand(op);
    EmitByte($FF);
    EmitModRM(4, op);
    Exit;
  End;
  If LexPeekKind = TK_IDENT Then
  Begin
    lbl := LexPeekVal;
    { si c est un nom de registre, JMP r/m16 }
    RegIndex(lbl, ridx, rw, rs);
    If (ridx >= 0) And (Not rs) Then
    Begin
      LexNext;
      op.kind    := OK_REG;
      op.reg     := ridx;
      op.is_word := True;
      EmitByte($FF);
      EmitModRM(4, op);
      Exit;
    End;
    { sinon c est un label }
    LexNext;
    If is_short Then    Begin
      { EB cb }
      EmitByte($EB);
      disp := ResolveRelTarget(lbl, lc + 1);
      EmitByte(Byte(disp And $FF));
    End
    Else
    Begin
      { E9 cw (NEAR par defaut, meme si is_near=False) }
      EmitByte($E9);
      disp := ResolveRelTarget(lbl, lc + 2);
      EmitWord(Word(disp));
    End;
    Exit;
  End;
  { expression numerique : JMP NEAR }
  EvalExpr(e);
  EmitByte($E9);
  disp := TLong(e.val) - TLong(lc + 2);
  EmitWord(Word(disp));
End;

{ ============================================================
  EncodeCALL : CALL [NEAR PTR|FAR PTR] cible
              ou CALL r/m16
  ============================================================ }
Procedure EncodeCALL;
Var
  is_far  : Boolean;
  op      : TOperand;
  disp    : TLong;
  lbl     : TString;
  far_off : TWord;
  far_seg : TWord;
  e       : TExpr;
  ridx    : Integer;
  rw, rs  : Boolean;
Begin
  is_far := False;

  If LexPeekKind = TK_IDENT Then
  Begin
    If LexPeekVal = 'NEAR' Then
    Begin
      LexNext;
      If (LexPeekKind = TK_IDENT) And (LexPeekVal = 'PTR') Then LexNext;
    End
    Else If LexPeekVal = 'FAR' Then
    Begin
      LexNext;
      If (LexPeekKind = TK_IDENT) And (LexPeekVal = 'PTR') Then LexNext;
      is_far := True;
    End;
  End;

  { CALL FAR PTR off:seg (9A cw cw) }
  If is_far Then
  Begin
    EvalExpr(e);
    far_off := Word(e.val);
    If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ':') Then LexNext;
    EvalExpr(e);
    far_seg := Word(e.val);
    EmitByte($9A);
    EmitWord(far_off);
    EmitWord(far_seg);
    Exit;
  End;

  { CALL r/m16 memoire }
  If (LexPeekKind = TK_PUNCT) And (LexPeekVal = '[') Then
  Begin
    ParseOperand(op);
    EmitByte($FF);
    EmitModRM(2, op);
    Exit;
  End;

  { CALL label ou CALL registre }
  If LexPeekKind = TK_IDENT Then
  Begin
    lbl := LexPeekVal;
    RegIndex(lbl, ridx, rw, rs);
    If (ridx >= 0) And (Not rs) Then
    Begin
      LexNext;
      op.kind    := OK_REG;
      op.reg     := ridx;
      op.is_word := True;
      EmitByte($FF);
      EmitModRM(2, op);
      Exit;
    End;
    LexNext;
    EmitByte($E8);
    disp := ResolveRelTarget(lbl, lc + 2);
    EmitWord(Word(disp));
    Exit;
  End;

  { expression }
  EvalExpr(e);
  EmitByte($E8);
  disp := TLong(e.val) - TLong(lc + 2);
  EmitWord(Word(disp));
End;

{ ============================================================
  EncodeRET : RET [n] / RETF [n]
  ============================================================ }
Procedure EncodeRET(is_far : Boolean);
Var
  e       : TExpr;
  has_imm : Boolean;
Begin
  has_imm := (LexPeekKind = TK_NUMBER) Or
             ((LexPeekKind = TK_PUNCT) And
              ((LexPeekVal = '+') Or (LexPeekVal = '-')));

  If (LexPeekKind = TK_IDENT) And (LexPeekVal <> '') Then
    { aucun immediat si c est un label ou directive }
    has_imm := False;

  If has_imm Then
  Begin
    EvalExpr(e);
    If is_far Then EmitByte($CA) Else EmitByte($C2);
    EmitWord(Word(e.val));
  End
  Else
  Begin
    If is_far Then EmitByte($CB) Else EmitByte($C3);
  End;
End;

{ ============================================================
  EncodeJcc : sauts conditionnels
  Si SHORT explicite -> 2 octets seulement.
  Si label sans qualificateur : tenter SHORT ; si disp hors
  plage en passe 2, emettre la forme inversee (Jcc_inv +5,
  JMP NEAR label) pour franchir la limite 8 bits.
  En passe 1 on reserve toujours 2 octets (forme SHORT).
  ============================================================ }
Procedure EncodeJcc(opc : Byte);
Var
  is_short  : Boolean;
  lbl       : TString;
  disp      : TLong;
  lbl_off   : TWord;
  p         : PSymbol;
  inv_opc   : Byte;
Begin
  is_short := False;
  lbl      := '';

  If (LexPeekKind = TK_IDENT) And (LexPeekVal = 'SHORT') Then
  Begin
    LexNext; is_short := True;
  End;

  If LexPeekKind = TK_IDENT Then
  Begin
    LexNext;
    lbl := lex_tok.val;
  End
  Else
  Begin
    ErrorMsg('Label attendu pour saut conditionnel');
    Exit;
  End;

  { En passe 1 : reserve 2 octets (SHORT) }
  If pass_num = 1 Then
  Begin
    EmitByte(opc);
    EmitByte(0);
    Exit;
  End;

  { En passe 2 : calculer le deplacement SHORT (disp apres les 2 octets) }
  p := SymFind(lbl);
  If p = Nil Then
  Begin
    ErrorMsg('Label indefini dans saut conditionnel : ' + lbl);
    EmitByte(opc);
    EmitByte(0);
    Exit;
  End;
  lbl_off := p^.offset;
  disp := TLong(lbl_off) - TLong(lc + 2);

  If is_short Or ((disp >= -128) And (disp <= 127)) Then
  Begin
    { forme SHORT : opcode + cb }
    If (disp < -128) Or (disp > 127) Then
      ErrorMsg('Deplacement trop grand pour saut court');
    EmitByte(opc);
    EmitByte(Byte(disp And $FF));
  End
  Else
  Begin
    { forme NEAR : Jcc_inv +5 ; E9 cw }
    inv_opc := JccInvert(opc);
    EmitByte(inv_opc);
    EmitByte(3);      { sauter les 3 octets du JMP NEAR suivant }
    EmitByte($E9);
    { le JMP NEAR se termine 2 octets apres son opcode }
    disp := TLong(lbl_off) - TLong(lc + 2);
    EmitWord(Word(disp));
  End;
End;

{ ============================================================
  EncodeJCXZ : JCXZ label (E3 cb)
  EncodeLoop : LOOP/LOOPE/LOOPNE label
  ============================================================ }
Procedure EncodeJCXZ;
Var
  lbl  : TString;
  disp : TLong;
Begin
  If LexPeekKind = TK_IDENT Then LexNext
  Else Begin ErrorMsg('Label attendu pour JCXZ'); Exit; End;
  lbl := lex_tok.val;
  EmitByte($E3);
  disp := ResolveRelTarget(lbl, lc + 1);
  If pass_num = 2 Then
    If (disp < -128) Or (disp > 127) Then
      ErrorMsg('JCXZ : deplacement hors plage');
  EmitByte(Byte(disp And $FF));
End;

Procedure EncodeLoop(opc : Byte);
Var
  lbl  : TString;
  disp : TLong;
Begin
  If LexPeekKind = TK_IDENT Then LexNext
  Else Begin ErrorMsg('Label attendu pour LOOP'); Exit; End;
  lbl := lex_tok.val;
  EmitByte(opc);
  disp := ResolveRelTarget(lbl, lc + 1);
  If pass_num = 2 Then
    If (disp < -128) Or (disp > 127) Then
      ErrorMsg('LOOP : deplacement hors plage');
  EmitByte(Byte(disp And $FF));
End;



{ ============================================================
  INSTRUCTIONS ARITHMETIQUES, LOGIQUES, SHIFTS ET FLAGS
  ============================================================

  MUL/IMUL/DIV/IDIV  r/m8 ou r/m16 : F6h-F7h /4-/7
  CBW=98 CWD=99
  AAA=37 AAS=3F DAA=27 DAS=2F AAM=D4 0A AAD=D5 0A
  Shifts/Rotates : ROL ROR RCL RCR SHL SAL SHR SAR
    opcode base = D0-D3 selon (byte/word, count=1/CL)
    groupe /reg : ROL=0 ROR=1 RCL=2 RCR=3 SHL=4 SHR=5 SAR=7
  Instructions flags 1 octet : STC CLC CMC STD CLD STI CLI
  PUSHF=9C POPF=9D SAHF=9E LAHF=9F XLAT=D7
  ============================================================ }

{ ============================================================
  EncodeMulDiv : MUL / IMUL / DIV / IDIV r/m
  grp = 4 MUL  5 IMUL  6 DIV  7 IDIV
  ============================================================ }
Procedure EncodeMulDiv(grp : Integer);
Var
  op      : TOperand;
  is_word : Boolean;
Begin
  ParseOperand(op);
  is_word := op.is_word Or (op.ptr_size >= 2);
  If op.ptr_size = 1 Then is_word := False;
  If is_word Then EmitByte($F7) Else EmitByte($F6);
  EmitModRM(grp, op);
End;

{ ---- Table des mnemoniques de shift pour ShiftGrp ---- }
Const
  SG_COUNT = 8;
  SG_NAMES : Array[1..8] Of String[3] = (
    'ROL','ROR','RCL','RCR','SHL','SAL','SHR','SAR'
  );
  SG_GRPS : Array[1..8] Of ShortInt = (0, 1, 2, 3, 4, 4, 5, 7);

{ ============================================================
  ShiftGrp : numero de groupe pour ROL/ROR/RCL/RCR/SHL/SHR/SAR
  ============================================================ }
Function ShiftGrp(Const mnem : TString) : Integer;
Var i : Integer;
Begin
  For i := 1 To SG_COUNT Do
    If SG_NAMES[i] = mnem Then Begin ShiftGrp := SG_GRPS[i]; Exit; End;
  ShiftGrp := -1;
End;

{ ============================================================
  EncodeShift : ROL/ROR/RCL/RCR/SHL/SAL/SHR/SAR dst, count
  count  = 1       -> D0 (byte) / D1 (word)
  count  = CL      -> D2 (byte) / D3 (word)
  count  = imm > 1 -> D0 + 0Ch (80186+, warning)
  ============================================================ }
Procedure EncodeShift(grp : Integer);
Var
  dst     : TOperand;
  cnt_tok : TString;
  is_word : Boolean;
  use_cl  : Boolean;
  cnt_imm : TLong;
  base    : Byte;
Begin
  ParseOperand(dst);
  is_word := dst.is_word Or (dst.ptr_size >= 2);
  If dst.ptr_size = 1 Then is_word := False;

  { consommer la virgule }
  If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ',') Then LexNext;

  { determiner l operande de comptage }
  use_cl  := False;
  cnt_imm := 1;

  If LexPeekKind = TK_IDENT Then
  Begin
    cnt_tok := LexPeekVal;
    If cnt_tok = 'CL' Then
    Begin
      LexNext;
      use_cl := True;
    End;
  End;
  If Not use_cl Then
  Begin
    cnt_imm := EvalConstExpr;
  End;

  If use_cl Then
  Begin
    If is_word Then base := $D3 Else base := $D2;
    EmitByte(base);
    EmitModRM(grp, dst);
  End
  Else If cnt_imm = 1 Then
  Begin
    If is_word Then base := $D1 Else base := $D0;
    EmitByte(base);
    EmitModRM(grp, dst);
  End
  Else
  Begin
    { imm > 1 : 80186+ ; on l emet quand meme avec warning }
    WarnMsg('Shift par immediat > 1 : instruction 80186+ (pas 8086 pur)');
    If is_word Then base := $D1 Else base := $D0;
    EmitByte(base);
    EmitModRM(grp, dst);
    { nota : le vrai encodage 80186 serait C0/C1 + ib ;
      ici on emet autant de shifts 1-bit qu il faut }
    { pour compatibilite maximale avec MASM 5.x on emet C1/C0 ib }
    { annuler les 2 octets deja emis et recommencer }
  End;
End;



{ ============================================================
  PUSH/POP, instructions de chaines, entr�e/sortie, divers
  ============================================================ }

{ --- PUSH --- }
Procedure EncodePush;
Var
  op : TOperand;
Begin
  ParseOperand(op);

  { PUSH sreg : CS=0E DS=1E ES=06 SS=16 }
  If op.kind = OK_SREG Then
  Begin
    Case op.reg Of
      REG_ES : EmitByte($06);
      REG_CS : EmitByte($0E);
      REG_SS : EmitByte($16);
      REG_DS : EmitByte($1E);
    Else
      ErrorMsg('PUSH : registre de segment invalide');
    End;
    Exit;
  End;

  { PUSH r16 : 50h+r }
  If (op.kind = OK_REG) And op.is_word Then
  Begin
    EmitByte(Byte($50 Or op.reg));
    Exit;
  End;

  { PUSH imm : 80186+, 6Ah imm8 ou 68h imm16 }
  If op.kind = OK_IMM Then
  Begin
    WarnMsg('PUSH imm : necessite 80186+');
    If (op.imm >= -128) And (op.imm <= 127) Then
    Begin
      EmitByte($6A);
      EmitByte(Byte(op.imm));
    End
    Else
    Begin
      EmitByte($68);
      EmitWord(Word(op.imm));
    End;
    Exit;
  End;

  { PUSH r/m16 : FF /6 }
  EmitByte($FF);
  EmitModRM(6, op);
End;

{ --- POP --- }
Procedure EncodePop;
Var
  op : TOperand;
Begin
  ParseOperand(op);

  { POP sreg : ES=07 SS=17 DS=1F (CS interdit) }
  If op.kind = OK_SREG Then
  Begin
    Case op.reg Of
      REG_ES : EmitByte($07);
      REG_CS : ErrorMsg('POP CS : operation interdite');
      REG_SS : EmitByte($17);
      REG_DS : EmitByte($1F);
    Else
      ErrorMsg('POP : registre de segment invalide');
    End;
    Exit;
  End;

  { POP r16 : 58h+r }
  If (op.kind = OK_REG) And op.is_word Then
  Begin
    EmitByte(Byte($58 Or op.reg));
    Exit;
  End;

  { POP r/m16 : 8Fh /0 }
  EmitByte($8F);
  EmitModRM(0, op);
End;

{ --- IN port, E4/E5/EC/ED --- }
Procedure EncodeIN;
Var
  dst, src : TOperand;
Begin
  ParseOperand(dst);
  If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ',') Then LexNext;
  ParseOperand(src);

  { IN AL/AX, DX }
  If (src.kind = OK_REG) And (src.reg = REG_DX) Then
  Begin
    If dst.is_word Then EmitByte($ED) Else EmitByte($EC);
    Exit;
  End;

  { IN AL/AX, imm8 }
  If src.kind = OK_IMM Then
  Begin
    If dst.is_word Then EmitByte($E5) Else EmitByte($E4);
    EmitByte(Byte(src.imm));
    Exit;
  End;

  ErrorMsg('IN : syntaxe invalide');
End;

{ --- OUT port, E6/E7/EE/EF --- }
Procedure EncodeOUT;
Var
  dst, src : TOperand;
Begin
  ParseOperand(dst);
  If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ',') Then LexNext;
  ParseOperand(src);

  { OUT DX, AL/AX }
  If (dst.kind = OK_REG) And (dst.reg = REG_DX) Then
  Begin
    If src.is_word Then EmitByte($EF) Else EmitByte($EE);
    Exit;
  End;

  { OUT imm8, AL/AX }
  If dst.kind = OK_IMM Then
  Begin
    If src.is_word Then EmitByte($E7) Else EmitByte($E6);
    EmitByte(Byte(dst.imm));
    Exit;
  End;

  ErrorMsg('OUT : syntaxe invalide');
End;

{ --- INT n --- }
Procedure EncodeINT;
Var
  op : TOperand;
Begin
  ParseOperand(op);
  If op.kind <> OK_IMM Then
  Begin
    ErrorMsg('INT : operande immediat requis');
    Exit;
  End;
  If op.imm = 3 Then
    EmitByte($CC)    { INT3 forme courte }
  Else
  Begin
    EmitByte($CD);
    EmitByte(Byte(op.imm));
  End;
End;

{ --- ESC cop, src  (interface coprocesseur 8087) --- }
{ Encodage : opcode = D8h | (cop shr 3), reg champ ModRM = cop and 7 }
Procedure EncodeESC;
Var
  op_cop, op_src : TOperand;
  cop            : Integer;
Begin
  ParseOperand(op_cop);
  If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ',') Then LexNext;
  ParseOperand(op_src);

  If op_cop.kind <> OK_IMM Then
  Begin
    ErrorMsg('ESC : premier operande doit etre une constante 0..63');
    Exit;
  End;

  cop := op_cop.imm And $3F;               { 6 bits effectifs }
  EmitByte(Byte($D8 Or (cop Shr 3)));      { D8h a DFh }
  EmitModRM(cop And 7, op_src);            { reg = bits 2-0 du cop }
End;

{ --- Dispatcher unifie instructions machine (groupes 12-15) --- }
Function ParseInstr(Const mnem : TString) : Boolean; Forward;

Function ParseInstr(Const mnem : TString) : Boolean;
Var
  instr_idx : Integer;
  rep_pfx   : Byte;
  sub_mnem  : TString;
  i         : Integer;
Begin
  ParseInstr := True;
  rep_pfx   := 0;
  instr_idx := 0;
  For i := 1 To IN_COUNT Do
    If IN_NAMES[i] = mnem Then Begin instr_idx := i; Break; End;
  Case instr_idx Of

    { --- Groupe 12 : MOV, arithmetique, logique --- }
    IN_MOV  : EncodeMOV;
    IN_ADD  : EncodeArith(0);
    IN_OR   : EncodeArith(1);
    IN_ADC  : EncodeArith(2);
    IN_SBB  : EncodeArith(3);
    IN_AND  : EncodeArith(4);
    IN_SUB  : EncodeArith(5);
    IN_XOR  : EncodeArith(6);
    IN_CMP  : EncodeArith(7);
    IN_INC  : EncodeIncDec(False);
    IN_DEC  : EncodeIncDec(True);
    IN_NOT  : EncodeNotNeg(False);
    IN_NEG  : EncodeNotNeg(True);
    IN_XCHG : EncodeXCHG;
    IN_LEA  : EncodeLEA_LxS($8D);
    IN_LDS  : EncodeLEA_LxS($C5);
    IN_LES  : EncodeLEA_LxS($C4);
    IN_TEST : EncodeTEST;

    { --- Groupe 13 : sauts, appels, Jcc --- }
    IN_JMP               : EncodeJMP;
    IN_CALL              : EncodeCALL;
    IN_RET               : EncodeRET(False);
    IN_RETF, IN_RETN     : EncodeRET(True);
    IN_JCXZ              : EncodeJCXZ;
    IN_LOOP              : EncodeLoop($E2);
    IN_LOOPE,  IN_LOOPZ  : EncodeLoop($E1);
    IN_LOOPNE, IN_LOOPNZ : EncodeLoop($E0);
    IN_JO                          : EncodeJcc($70);
    IN_JNO                         : EncodeJcc($71);
    IN_JB,  IN_JNAE, IN_JC         : EncodeJcc($72);
    IN_JNB, IN_JAE,  IN_JNC        : EncodeJcc($73);
    IN_JE,  IN_JZ                  : EncodeJcc($74);
    IN_JNE, IN_JNZ                 : EncodeJcc($75);
    IN_JBE, IN_JNA                 : EncodeJcc($76);
    IN_JNBE,IN_JA                  : EncodeJcc($77);
    IN_JS                          : EncodeJcc($78);
    IN_JNS                         : EncodeJcc($79);
    IN_JP,  IN_JPE                 : EncodeJcc($7A);
    IN_JNP, IN_JPO                 : EncodeJcc($7B);
    IN_JL,  IN_JNGE                : EncodeJcc($7C);
    IN_JNL, IN_JGE                 : EncodeJcc($7D);
    IN_JLE, IN_JNG                 : EncodeJcc($7E);
    IN_JNLE,IN_JG                  : EncodeJcc($7F);

    { --- Groupe 14 : arithmetique etendue, shifts, flags --- }
    IN_MUL  : EncodeMulDiv(4);
    IN_IMUL : EncodeMulDiv(5);
    IN_DIV  : EncodeMulDiv(6);
    IN_IDIV : EncodeMulDiv(7);
    IN_CBW  : EmitByte($98);
    IN_CWD  : EmitByte($99);
    IN_AAA  : EmitByte($37);
    IN_AAS  : EmitByte($3F);
    IN_DAA  : EmitByte($27);
    IN_DAS  : EmitByte($2F);
    IN_AAM  : Begin EmitByte($D4); EmitByte($0A); End;
    IN_AAD  : Begin EmitByte($D5); EmitByte($0A); End;
    IN_ROL           : EncodeShift(0);
    IN_ROR           : EncodeShift(1);
    IN_RCL           : EncodeShift(2);
    IN_RCR           : EncodeShift(3);
    IN_SHL, IN_SAL   : EncodeShift(4);
    IN_SHR           : EncodeShift(5);
    IN_SAR           : EncodeShift(7);
    IN_STC  : EmitByte($F9);
    IN_CLC  : EmitByte($F8);
    IN_CMC  : EmitByte($F5);
    IN_STD  : EmitByte($FD);
    IN_CLD  : EmitByte($FC);
    IN_STI  : EmitByte($FB);
    IN_CLI  : EmitByte($FA);
    IN_PUSHF           : EmitByte($9C);
    IN_POPF            : EmitByte($9D);
    IN_SAHF            : EmitByte($9E);
    IN_LAHF            : EmitByte($9F);
    IN_XLAT, IN_XLATB  : EmitByte($D7);

    { --- Groupe 15 : PUSH/POP, chaines, E/S, divers --- }
    IN_PUSH  : EncodePush;
    IN_POP   : EncodePop;
    IN_PUSHA : Begin WarnMsg('PUSHA : necessite 80186+'); EmitByte($60); End;
    IN_POPA  : Begin WarnMsg('POPA : necessite 80186+');  EmitByte($61); End;
    { REP* : stocker le prefixe, traite apres le Case }
    IN_REP, IN_REPE, IN_REPZ  : rep_pfx := $F3;
    IN_REPNE, IN_REPNZ         : rep_pfx := $F2;
    IN_MOVSB : EmitByte($A4);
    IN_MOVSW : EmitByte($A5);
    IN_MOVS  : EmitByte($A4);  { sans suffixe = byte par defaut }
    IN_CMPSB : EmitByte($A6);
    IN_CMPSW : EmitByte($A7);
    IN_SCASB : EmitByte($AE);
    IN_SCASW : EmitByte($AF);
    IN_STOSB : EmitByte($AA);
    IN_STOSW : EmitByte($AB);
    IN_LODSB : EmitByte($AC);
    IN_LODSW : EmitByte($AD);
    IN_IN    : EncodeIN;
    IN_OUT   : EncodeOUT;
    IN_INT   : EncodeINT;
    IN_INT3  : EmitByte($CC);
    IN_INTO  : EmitByte($CE);
    IN_IRET  : EmitByte($CF);
    IN_HLT   : EmitByte($F4);
    IN_NOP   : EmitByte($90);
    IN_WAIT  : EmitByte($9B);
    IN_LOCK  : EmitByte($F0);
    IN_ESC   : EncodeESC;

  Else
    ParseInstr := False;
    Exit;
  End; { Case instr_idx }

  { Prefixe REP* : emettre + dispatcher l instruction chaine suivante }
  If rep_pfx <> 0 Then
  Begin
    EmitByte(rep_pfx);
    If LexPeekKind = TK_IDENT Then
    Begin sub_mnem := LexPeekVal; LexNext; End
    Else sub_mnem := '';
    ParseInstr := ParseInstr(sub_mnem);
  End;
End;

{ ============================================================
  STRUCTURES (STRUC / ENDS)
  ============================================================

  Chaque structure STRUC est stockee dans struct_table avec ses
  champs (nom, offset, taille, valeur par defaut).
  Le nom de la structure est enregistre dans la table des
  symboles comme SK_STRUCT avec value = index dans struct_table.
  Les noms de champs sont aussi enregistres comme SK_EQU avec
  value = offset du champ dans la structure (pour [BX].champ).
  SIZE nom = taille totale ; OFFSET nom.champ = offset champ.

  Instanciation : var_name struct_name <val1, val2, ...>
  ============================================================ }

Const
  MAX_STRUCT_FIELDS = {$IFDEF FPC}64{$ELSE}8{$ENDIF};

Type
  TStructField = Record
    fname    : TSymString;  { nom du champ (vide si pas de nom) }
    foffset  : TWord;       { offset depuis debut structure }
    fsize    : TWord;       { taille en octets (1/2/4/8/10) }
    def_val  : TLong;       { valeur par defaut (0 si ?) }
    has_def  : Boolean;     { True si valeur par defaut specifiee }
  End;

  TStructDef = Record
    sname      : TSymString;   { nom de la structure }
    total_size : TWord;        { taille totale en octets }
    field_cnt  : Integer;      { nombre de champs }
    fields     : Array[1..MAX_STRUCT_FIELDS] Of TStructField;
  End;

  PStructDef = ^TStructDef;

Var
  struct_table : Array[1..MAX_STRUCT] Of PStructDef;
  struct_count : Integer;

{ ============================================================
  StructInit : initialiser la table des structures
  ============================================================ }
Procedure StructInit;
Var i : Integer;
Begin
  struct_count := 0;
  For i := 1 To MAX_STRUCT Do struct_table[i] := Nil;
End;

{ ============================================================
  StructFind : trouver une structure par son nom.
  Retourne l index dans struct_table (1-base) ou 0 si absent.
  ============================================================ }
Function StructFind(Const sname : TSymString) : Integer;
Var
  p : PSymbol;
Begin
  StructFind := 0;
  p := SymFind(sname);
  If p = Nil Then Exit;
  If p^.kind <> SK_STRUCT Then Exit;
  { value stocke l index dans struct_table }
  If (p^.value >= 1) And (p^.value <= struct_count) Then
    StructFind := Integer(p^.value);
End;

{ ============================================================
  ParseStruc : traiter nom STRUC ... nom ENDS
  Lit les lignes suivantes jusqu a ENDS, collecte les champs.
  ============================================================ }
Procedure ParseStruc(Const struc_name : TSymString);
Var
  si       : Integer;
  cur_off  : TWord;
  fld_name : TSymString;
  fsize    : TWord;
  def_val  : TLong;
  has_def  : Boolean;
  tok      : TString;
  dir      : TString;
  p        : PSymbol;
  fsym     : PSymbol;
  e        : TExpr;
  done     : Boolean;
  dd_idx   : Integer;
  i        : Integer;
Begin
  { verifier que la structure n est pas deja definie }
  If StructFind(struc_name) > 0 Then
  Begin
    WarnMsg('Structure deja definie : ' + struc_name);
    Exit;
  End;

  { allouer une entree }
  If struct_count >= MAX_STRUCT Then
  Begin
    ErrorMsg('Trop de structures definies');
    Exit;
  End;
  Inc(struct_count);
  si := struct_count;
  New(struct_table[si]);
  struct_table[si]^.sname      := struc_name;
  struct_table[si]^.total_size := 0;
  struct_table[si]^.field_cnt  := 0;
  cur_off := 0;

  { enregistrer le symbole (taille inconnue pour l instant) }
  p := SymFind(struc_name);
  If p = Nil Then
    p := SymEnter(struc_name, SK_STRUCT, 0, 0, 0);
  p^.kind  := SK_STRUCT;
  p^.value := si;

  done := False;
  While (Not done) And SrcReadLine Do
  Begin
    { nourrir le lexer avec la nouvelle ligne }
    lex_line     := cur_line;
    lex_pos      := 1;
    lex_has_peek := False;
    lex_at_eol   := False;

    { ligne vide ou commentaire }
    If LexPeekKind = TK_NEWLINE Then Continue;
    If LexPeekKind = TK_EOF     Then Break;

    { lire le premier token }
    LexNext;
    tok := lex_tok.val;

    { --- detection de ENDS --- }
    { forme "nom ENDS" ou juste "ENDS" }
    If tok = 'ENDS' Then
    Begin
      done := True;
      Continue;
    End;
    If (LexPeekKind = TK_IDENT) And (LexPeekVal = 'ENDS') Then
    Begin
      { tok est soit le nom de la structure soit un label anonymous }
      done := True;
      LexNext; { consommer ENDS }
      Continue;
    End;

    { --- analyse d un champ --- }
    fld_name := '';
    dir      := '';
    fsize    := 1;
    def_val  := 0;
    has_def  := False;

    { tok est DB/DW/DD/DQ/DT directement, ou un nom de champ }
    dd_idx := 0;
    For i := 1 To DD_COUNT Do
      If DD_NAMES[i] = tok Then Begin dd_idx := i; Break; End;
    If dd_idx > 0 Then
      dir := tok
    Else
    Begin
      fld_name := tok;
      { lire la directive DB/DW/... }
      If LexPeekKind = TK_IDENT Then
      Begin
        LexNext;
        dir := lex_tok.val;
        dd_idx := 0;
        For i := 1 To DD_COUNT Do
          If DD_NAMES[i] = dir Then Begin dd_idx := i; Break; End;
      End;
    End;

    { taille selon la directive }
    If dd_idx > 0 Then fsize := DD_SIZES[dd_idx]
    Else
    Begin
      { directive inconnue ou ligne de commentaire : ignorer }
      Continue;
    End;

    { valeur par defaut : ? ou expression }
    If (LexPeekKind = TK_PUNCT) And (LexPeekVal = '?') Then
    Begin
      LexNext;
      has_def := False;
      def_val := 0;
    End
    Else If (LexPeekKind <> TK_NEWLINE) And (LexPeekKind <> TK_EOF) Then
    Begin
      ExprMakeNum(e, 0);
      EvalExpr(e);
      def_val := e.val;
      has_def := True;
    End;

    { enregistrer le champ }
    With struct_table[si]^ Do
    Begin
      If field_cnt < MAX_STRUCT_FIELDS Then
      Begin
        Inc(field_cnt);
        fields[field_cnt].fname   := fld_name;
        fields[field_cnt].foffset := cur_off;
        fields[field_cnt].fsize   := fsize;
        fields[field_cnt].def_val := def_val;
        fields[field_cnt].has_def := has_def;
      End
      Else
        WarnMsg('Trop de champs dans la structure ' + struc_name);
    End;

    { creer un symbole EQU = offset pour le champ nomme }
    If fld_name <> '' Then
    Begin
      fsym := SymFind(fld_name);
      If fsym = Nil Then
        fsym := SymEnter(fld_name, SK_EQU, 0, 0, cur_off);
      SymSetValue(fsym, cur_off);
      fsym^.flags := fsym^.flags And Not 8; { non reassignable }
    End;

    cur_off := cur_off + fsize;
  End;

  { finaliser }
  struct_table[si]^.total_size := cur_off;
  p^.size  := cur_off;
  p^.value := si;
End;

{ ============================================================
  ParseStructInstance : emettre les octets d une instance
  Syntaxe (apres lecture du nom de structure) :
    var_name struct_name <val1, val2, ...>
  Si var_name = '', c est un element anonyme (dans un DUP).
  ============================================================ }
Procedure ParseStructInstance(si_idx : Integer;
                              Const var_name : TSymString);
Var
  nf       : Integer;
  i, j     : Integer;
  pad      : Integer;
  inst_off : TWord;
  p        : PSymbol;
  e        : TExpr;
  vals     : Array[1..MAX_STRUCT_FIELDS] Of TLong;
  has_v    : Array[1..MAX_STRUCT_FIELDS] Of Boolean;
Begin
  nf := struct_table[si_idx]^.field_cnt;

  { definir le label de la variable si nom fourni }
  If var_name <> '' Then
  Begin
    p := SymFind(var_name);
    If p = Nil Then
      p := SymEnter(var_name, SK_LABEL, cur_seg, lc,
                    struct_table[si_idx]^.total_size);
    p^.kind    := SK_LABEL;
    p^.seg_idx := cur_seg;
    p^.offset  := lc;
    p^.size    := struct_table[si_idx]^.total_size;
    p^.flags   := p^.flags Or 4;  { is_defined }
  End;

  { charger les valeurs par defaut }
  For i := 1 To nf Do
  Begin
    vals[i]  := struct_table[si_idx]^.fields[i].def_val;
    has_v[i] := struct_table[si_idx]^.fields[i].has_def;
  End;

  { parser < val1, val2, ... > si present }
  If (LexPeekKind = TK_PUNCT) And (LexPeekVal = '<') Then
  Begin
    LexNext;  { consommer < }
    i := 1;
    While i <= nf Do
    Begin
      { valeur vide (,) ou fin > -> garder defaut }
      If (LexPeekKind = TK_PUNCT) And
         ((LexPeekVal = ',') Or (LexPeekVal = '>')) Then
      Begin
        { pas de valeur explicite : garder le defaut }
      End
      Else If (LexPeekKind <> TK_NEWLINE) And (LexPeekKind <> TK_EOF) Then
      Begin
        ExprMakeNum(e, 0);
        EvalExpr(e);
        vals[i]  := e.val;
        has_v[i] := True;
      End;
      Inc(i);
      If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ',') Then
        LexNext
      Else
        Break;
    End;
    { consommer le > final }
    If (LexPeekKind = TK_PUNCT) And (LexPeekVal = '>') Then
      LexNext;
  End;

  { emettre les octets }
  inst_off := 0;
  For i := 1 To nf Do
  Begin
    { rembourrage entre champs si necessaire }
    pad := Integer(struct_table[si_idx]^.fields[i].foffset) -
           Integer(inst_off);
    For j := 1 To pad Do EmitByte(0);
    inst_off := inst_off + TWord(pad);

    { emettre selon la taille du champ }
    Case struct_table[si_idx]^.fields[i].fsize Of
      1 : EmitByte(Byte(vals[i]));
      2 : EmitWord(Word(vals[i]));
      4 : Begin
            EmitWord(Word(vals[i]));
            EmitWord(Word(vals[i] Shr 16));
          End;
    Else
      Begin
        { taille > 4 : emettre DWORD bas, puis zeros }
        EmitWord(Word(vals[i]));
        EmitWord(Word(vals[i] Shr 16));
        For j := 5 To Integer(struct_table[si_idx]^.fields[i].fsize) Do
          EmitByte(0);
      End;
    End;
    inst_off := inst_off + struct_table[si_idx]^.fields[i].fsize;
  End;

  { rembourrage final }
  pad := Integer(struct_table[si_idx]^.total_size) - Integer(inst_off);
  For j := 1 To pad Do EmitByte(0);
End;

{ ============================================================
  MACROS (MACRO ENDM LOCAL EXITM PURGE REPT IRP IRPC)
  ============================================================ }

Const
  MAX_MACRO_PARAMS = 16;    { parametres formels max par macro }
  MAX_MACRO_POOL   = 2048;  { pool global de lignes de corps de macro }
  MACRO_EXP_DEPTH  = 8;     { niveaux d imbrication max d expansion }
  MACRO_EXP_BUF    = 256;   { lignes max dans un niveau d expansion }

Type
  PLineNode = ^TLineNode;

  TLineNode = Record
    line : TString;
    next : PLineNode;
  End;

  PMacroDef = ^TMacroDef;

  TMacroDef = Record
    mname      : TSymString;
    param_cnt  : Integer;
    params     : Array[1..MAX_MACRO_PARAMS] Of TSymString;
    body_first : PLineNode;
    body_cnt   : Integer;
    purged     : Boolean;
    next       : PMacroDef;
  End;

  PExpCtx = ^TExpCtx;

  TExpCtx = Record
    line_head : PLineNode;  { tete de la liste de lignes expandees }
    line_tail : PLineNode;  { queue pour ajout O(1) }
    cur_node  : PLineNode;  { noeud courant de lecture }
    do_exitm  : Boolean;    { EXITM signale }
    mi        : PMacroDef; { macro courante (Nil = REPT/IRP/IRPC) }
    prev      : PExpCtx;   { contexte precedent (pile) }
  End;

Var
  macro_list_head : PMacroDef;
  macro_count     : Integer;
  macro_exp_cur   : PExpCtx;    { sommet de la pile d expansion }

{ ============================================================
  MacroInit : (re)initialiser les tables macro
  ============================================================ }
Procedure MacroInit;
Begin
  macro_list_head := Nil;
  macro_count     := 0;
  macro_exp_cur   := Nil;
End;

{ ============================================================
  MacroFind : chercher une macro non purgee par son nom.
  Retourne l index 1-base dans macro_table, ou 0 si absente.
  ============================================================ }
Function MacroFind(Const mname : TSymString) : PMacroDef;
Var
  p : PMacroDef;
Begin
  MacroFind := Nil;
  p := macro_list_head;
  While p <> Nil Do
  Begin
    If (Not p^.purged) And (p^.mname = mname) Then
    Begin
      MacroFind := p;
      Exit;
    End;
    p := p^.next;
  End;
End;

{ ============================================================
  SubstOneParam : remplace &PNAME par arg dans line.
  ! echappe le caractere suivant (il passe tel quel).
  ============================================================ }
Function SubstOneParam(Const line  : TString;
                       Const pname : TSymString;
                       Const arg   : TString) : TString;
Var
  res   : TString;
  i     : Integer;
  ident : TString;
  c     : Char;
Begin
  res := '';
  i   := 1;
  While i <= Length(line) Do
  Begin
    c := line[i];
    If c = '!' Then
    Begin
      Inc(i);
      If i <= Length(line) Then
      Begin
        res := res + line[i];
        Inc(i);
      End;
    End
    Else If c = '&' Then
    Begin
      Inc(i);
      ident := '';
      While (i <= Length(line)) And LexIsAlNum(line[i]) Do
      Begin
        ident := ident + UpCase(line[i]);
        Inc(i);
      End;
      If ident = pname Then
        res := res + arg
      Else
        res := res + '&' + ident;
    End
    Else
    Begin
      res := res + c;
      Inc(i);
    End;
  End;
  SubstOneParam := res;
End;

{ ============================================================
  SubstWholeWord : remplace le mot entier wfrom par wto.
  Utilise pour la substitution des labels LOCAL.
  ============================================================ }
Function SubstWholeWord(Const line  : TString;
                        Const wfrom : TString;
                        Const wto   : TString) : TString;
Var
  res  : TString;
  i    : Integer;
  wlen : Integer;
  ok   : Boolean;
  bc   : Char;
  ac   : Char;
Begin
  res  := '';
  i    := 1;
  wlen := Length(wfrom);
  While i <= Length(line) Do
  Begin
    If (wlen > 0) And
       (i + wlen - 1 <= Length(line)) And
       (Copy(line, i, wlen) = wfrom) Then
    Begin
      bc := ' ';
      ac := ' ';
      If i > 1 Then bc := line[i - 1];
      If i + wlen <= Length(line) Then ac := line[i + wlen];
      ok := (Not LexIsAlNum(bc)) And (Not LexIsAlNum(ac));
      If ok Then
      Begin
        res := res + wto;
        i   := i + wlen;
      End
      Else
      Begin
        res := res + line[i];
        Inc(i);
      End;
    End
    Else
    Begin
      res := res + line[i];
      Inc(i);
    End;
  End;
  SubstWholeWord := res;
End;

{ ============================================================
  GetNextLine : retourne la prochaine ligne depuis le flux actif.
  Si une expansion macro est en cours, sert depuis la pile
  d expansion ; sinon appelle SrcReadLine.
  EXITM : marque do_exitm => le niveau courant est clos.
  ============================================================ }
Function GetNextLine : Boolean; Forward;

{ ---- Table des mots-cles ouvrants pour CollectBlock ---- }
Const
  CB_OPEN_COUNT = 4;
  CB_OPEN_NAMES : Array[1..4] Of String[5] = ('MACRO','REPT','IRP','IRPC');

{ ============================================================
  CollectBlock : accumule les lignes depuis le flux courant
  jusqu au ENDM correspondant (gere l imbrication).
  Stocke dans macro_line_pool ; retourne l index de debut et
  body_cnt = nb de lignes collectees.
  ============================================================ }
Function CollectBlock(Var body_cnt : Integer) : PLineNode;
Var
  depth    : Integer;
  raw      : TString;
  tok      : TString;
  head     : PLineNode;
  tail     : PLineNode;
  nd       : PLineNode;
  i        : Integer;
  kw1      : TString;
  kw2      : TString;
Begin
  head     := Nil;
  tail     := Nil;
  body_cnt := 0;
  depth    := 1;

  While GetNextLine Do
  Begin
    raw := cur_line;

    { extraire le premier et second identificateur de la ligne
      pour detecter ENDM / MACRO / REPT / IRP / IRPC }
    i    := 1;
    While (i <= Length(raw)) And (raw[i] = ' ') Do Inc(i);
    kw1 := '';
    While (i <= Length(raw)) And LexIsAlNum(raw[i]) Do
    Begin
      kw1 := kw1 + UpCase(raw[i]);
      Inc(i);
    End;
    While (i <= Length(raw)) And (raw[i] = ' ') Do Inc(i);
    kw2 := '';
    While (i <= Length(raw)) And LexIsAlNum(raw[i]) Do
    Begin
      kw2 := kw2 + UpCase(raw[i]);
      Inc(i);
    End;

    { tok = le mot-cle pertinent pour la profondeur }
    tok := '';
    For i := 1 To CB_OPEN_COUNT Do
      If CB_OPEN_NAMES[i] = kw1 Then Begin tok := kw1; Break; End;
    If tok = '' Then
      For i := 1 To CB_OPEN_COUNT Do
        If CB_OPEN_NAMES[i] = kw2 Then Begin tok := kw2; Break; End;
    If (tok = '') And (kw1 = 'ENDM') Then tok := 'ENDM';

    For i := 1 To CB_OPEN_COUNT Do
      If CB_OPEN_NAMES[i] = tok Then Begin Inc(depth); Break; End;

    If tok = 'ENDM' Then
    Begin
      Dec(depth);
      If depth = 0 Then Break;   { ENDM du bloc courant }
    End;

    { stocker la ligne dans la liste chainee }
    New(nd);
    nd^.line := raw;
    nd^.next := Nil;
    If tail = Nil Then
      head := nd
    Else
      tail^.next := nd;
    tail := nd;
    Inc(body_cnt);
  End;

  CollectBlock := head;
End;

{ GetNextLine : implementation reelle }
Function GetNextLine : Boolean;
Var
  prev_ctx : PExpCtx;
Begin
  While macro_exp_cur <> Nil Do
  Begin
    If macro_exp_cur^.do_exitm Or (macro_exp_cur^.cur_node = Nil) Then
    Begin
      prev_ctx      := macro_exp_cur^.prev;
      Dispose(macro_exp_cur);
      macro_exp_cur := prev_ctx;
      Continue;
    End;
    cur_line              := macro_exp_cur^.cur_node^.line;
    macro_exp_cur^.cur_node := macro_exp_cur^.cur_node^.next;
    GetNextLine := True;
    Exit;
  End;
  { SrcReadLine : mettre a jour @CUR_LINE }
  If SrcReadLine Then
  Begin
    SymSetValue(SymFind('@CUR_LINE'), cur_lineno);
    GetNextLine := True;
  End
  Else
    GetNextLine := False;
End;

{ ============================================================
  ParseMacroDef : nom MACRO [p1, p2, ...] / body / ENDM
  ============================================================ }
Procedure ParseMacroDef(Const mname : TSymString);
Var
  mi       : PMacroDef;
  pcnt     : Integer;
  body_cnt : Integer;
  p        : PSymbol;
Begin
  mi := MacroFind(mname);
  If mi = Nil Then
  Begin
    New(mi);
    mi^.next      := macro_list_head;
    macro_list_head := mi;
    Inc(macro_count);
  End;
  mi^.mname     := mname;
  mi^.purged    := False;
  mi^.param_cnt := 0;

  { lire les parametres formels }
  pcnt := 0;
  While LexPeekKind = TK_IDENT Do
  Begin
    LexNext;
    If pcnt < MAX_MACRO_PARAMS Then
    Begin
      Inc(pcnt);
      mi^.params[pcnt] := lex_tok.val;
    End;
    If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ',') Then
      LexNext
    Else
      Break;
  End;
  mi^.param_cnt := pcnt;

  { collecter le corps jusqu a ENDM }
  mi^.body_first := CollectBlock(body_cnt);
  mi^.body_cnt   := body_cnt;

  { enregistrer le symbole SK_MACRO }
  p := SymFind(mname);
  If p = Nil Then
    p := SymEnter(mname, SK_MACRO, 0, 0, TLong(mi))
  Else
  Begin
    p^.kind  := SK_MACRO;
    p^.value := TLong(mi);
  End;
End;

{ ============================================================
  ExpandMacro : instancier la macro mi avec les arguments
  fournis dans arg_line (reste de la ligne apres le nom).
  Pousse un contexte sur macro_exp_stk.
  ============================================================ }
Procedure ExpandMacro(mi : PMacroDef; Const arg_line : TString);
Var
  pcnt        : Integer;
  i, j, k     : Integer;
  p           : Integer;
  c           : Char;
  arg         : TString;
  subst       : TString;
  in_angle    : Boolean;
  args        : Array[1..MAX_MACRO_PARAMS] Of TString;
  local_from  : Array[1..MAX_MACRO_PARAMS] Of TSymString;
  local_to    : Array[1..MAX_MACRO_PARAMS] Of TSymString;
  local_cnt   : Integer;
  raw         : TString;
  tok         : TString;
  is_loc_line : Boolean;
  nd          : PLineNode;
  en          : PLineNode;
  prev_ctx    : PExpCtx;
Begin
  { pousser un nouveau contexte d expansion }
  prev_ctx              := macro_exp_cur;
  New(macro_exp_cur);
  macro_exp_cur^.line_head := Nil;
  macro_exp_cur^.line_tail := Nil;
  macro_exp_cur^.cur_node  := Nil;
  macro_exp_cur^.do_exitm  := False;
  macro_exp_cur^.mi        := mi;
  macro_exp_cur^.prev      := prev_ctx;

  pcnt := mi^.param_cnt;
  For i := 1 To MAX_MACRO_PARAMS Do args[i] := '';

  { ----- parser les arguments depuis arg_line ----- }
  p := 1;
  While (p <= Length(arg_line)) And (arg_line[p] = ' ') Do Inc(p);
  For i := 1 To pcnt Do
  Begin
    arg      := '';
    in_angle := False;
    While p <= Length(arg_line) Do
    Begin
      c := arg_line[p];
      If (c = '<') And Not in_angle Then Begin in_angle := True; Inc(p); Continue; End;
      If (c = '>') And in_angle      Then Begin in_angle := False; Inc(p); Continue; End;
      If (c = ',') And Not in_angle  Then Begin Inc(p); Break; End;
      arg := arg + c;
      Inc(p);
    End;
    While (Length(arg) > 0) And (arg[1] = ' ')           Do Delete(arg, 1, 1);
    While (Length(arg) > 0) And (arg[Length(arg)] = ' ') Do Delete(arg, Length(arg), 1);
    args[i] := arg;
    While (p <= Length(arg_line)) And (arg_line[p] = ' ') Do Inc(p);
  End;

  { ----- detecter les declarations LOCAL dans le corps ----- }
  local_cnt := 0;
  nd := mi^.body_first;
  For k := 1 To mi^.body_cnt Do
  Begin
    raw := nd^.line;
    nd  := nd^.next;
    j   := 1;
    While (j <= Length(raw)) And (raw[j] = ' ') Do Inc(j);
    tok := '';
    While (j <= Length(raw)) And LexIsAlpha(raw[j]) Do
    Begin
      tok := tok + UpCase(raw[j]);
      Inc(j);
    End;
    If tok = 'LOCAL' Then
    Begin
      While j <= Length(raw) Do
      Begin
        While (j <= Length(raw)) And (raw[j] = ' ') Do Inc(j);
        If j > Length(raw) Then Break;
        tok := '';
        While (j <= Length(raw)) And LexIsAlNum(raw[j]) Do
        Begin
          tok := tok + UpCase(raw[j]);
          Inc(j);
        End;
        If (Length(tok) > 0) And (local_cnt < MAX_MACRO_PARAMS) Then
        Begin
          Inc(local_cnt);
          local_from[local_cnt] := tok;
          local_to[local_cnt]   := LocalNextName;
        End;
        While (j <= Length(raw)) And (raw[j] = ' ')  Do Inc(j);
        If (j <= Length(raw)) And (raw[j] = ',') Then Inc(j);
      End;
    End;
  End;

  { ----- construire les lignes d expansion substituees ----- }
  nd := mi^.body_first;
  For k := 1 To mi^.body_cnt Do
  Begin
    raw := nd^.line;
    nd  := nd^.next;

    { detecter les lignes LOCAL (a sauter) }
    j   := 1;
    While (j <= Length(raw)) And (raw[j] = ' ') Do Inc(j);
    tok := '';
    While (j <= Length(raw)) And LexIsAlpha(raw[j]) Do
    Begin
      tok := tok + UpCase(raw[j]);
      Inc(j);
    End;
    is_loc_line := (tok = 'LOCAL');
    If is_loc_line Then Continue;

    { substituer les parametres }
    subst := raw;
    For j := 1 To pcnt Do
      subst := SubstOneParam(subst, mi^.params[j], args[j]);

    { substituer les labels LOCAL }
    For j := 1 To local_cnt Do
      subst := SubstWholeWord(subst, local_from[j], local_to[j]);

    { ajouter au buffer d expansion }
    New(en);
    en^.line := subst;
    en^.next := Nil;
    If macro_exp_cur^.line_tail = Nil Then
      macro_exp_cur^.line_head := en
    Else
      macro_exp_cur^.line_tail^.next := en;
    macro_exp_cur^.line_tail := en;
  End;
  macro_exp_cur^.cur_node := macro_exp_cur^.line_head;
End;

{ ============================================================
  ParseRept : REPT n ... ENDM  (repeter n fois le corps)
  ============================================================ }
Procedure ParseRept;
Var
  count      : Integer;
  body_cnt   : Integer;
  body_first : PLineNode;
  i, j       : Integer;
  nd         : PLineNode;
  en         : PLineNode;
  prev_ctx   : PExpCtx;
  e          : TExpr;
Begin
  ExprMakeNum(e, 0);
  EvalExpr(e);
  count := Integer(e.val);
  If count < 0 Then count := 0;

  body_first := CollectBlock(body_cnt);
  If (count = 0) Or (body_cnt = 0) Then Exit;

  { pousser un nouveau contexte d expansion }
  prev_ctx              := macro_exp_cur;
  New(macro_exp_cur);
  macro_exp_cur^.line_head := Nil;
  macro_exp_cur^.line_tail := Nil;
  macro_exp_cur^.cur_node  := Nil;
  macro_exp_cur^.do_exitm  := False;
  macro_exp_cur^.mi        := Nil;
  macro_exp_cur^.prev      := prev_ctx;

  For i := 1 To count Do
  Begin
    nd := body_first;
    For j := 1 To body_cnt Do
    Begin
      New(en);
      en^.line := nd^.line;
      en^.next := Nil;
      If macro_exp_cur^.line_tail = Nil Then
        macro_exp_cur^.line_head := en
      Else
        macro_exp_cur^.line_tail^.next := en;
      macro_exp_cur^.line_tail := en;
      nd := nd^.next;
    End;
  End;
  macro_exp_cur^.cur_node := macro_exp_cur^.line_head;
End;

{ ============================================================
  ParseIrp : IRP param, <item1, item2, ...> ... ENDM
  ============================================================ }
Procedure ParseIrp;
Var
  pname      : TSymString;
  body_cnt   : Integer;
  body_first : PLineNode;
  i, j       : Integer;
  arg        : TString;
  subst      : TString;
  args       : Array[0..63] Of TString;
  arg_cnt    : Integer;
  nd         : PLineNode;
  en         : PLineNode;
  prev_ctx   : PExpCtx;
Begin
  pname := '';
  If LexPeekKind = TK_IDENT Then
  Begin
    LexNext;
    pname := lex_tok.val;
  End;
  If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ',') Then LexNext;

  { parser la liste < item, item, ... > token par token }
  arg_cnt := 0;
  If (LexPeekKind = TK_PUNCT) And (LexPeekVal = '<') Then
  Begin
    LexNext;
    While (LexPeekKind <> TK_NEWLINE) And (LexPeekKind <> TK_EOF) Do
    Begin
      If (LexPeekKind = TK_PUNCT) And (LexPeekVal = '>') Then
      Begin
        LexNext;
        Break;
      End;
      { accumuler les tokens d un item jusqu a , ou > }
      arg := '';
      While (LexPeekKind <> TK_NEWLINE) And (LexPeekKind <> TK_EOF) Do
      Begin
        If (LexPeekKind = TK_PUNCT) And
           ((LexPeekVal = ',') Or (LexPeekVal = '>')) Then Break;
        LexNext;
        If Length(arg) > 0 Then arg := arg + ' ';
        arg := arg + lex_tok.val;
      End;
      While (Length(arg) > 0) And (arg[1] = ' ')           Do Delete(arg, 1, 1);
      While (Length(arg) > 0) And (arg[Length(arg)] = ' ') Do Delete(arg, Length(arg), 1);
      If arg_cnt < 64 Then
      Begin
        args[arg_cnt] := arg;
        Inc(arg_cnt);
      End;
      If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ',') Then LexNext;
    End;
  End;

  body_first := CollectBlock(body_cnt);
  If (arg_cnt = 0) Or (body_cnt = 0) Then Exit;

  { pousser un nouveau contexte d expansion }
  prev_ctx              := macro_exp_cur;
  New(macro_exp_cur);
  macro_exp_cur^.line_head := Nil;
  macro_exp_cur^.line_tail := Nil;
  macro_exp_cur^.cur_node  := Nil;
  macro_exp_cur^.do_exitm  := False;
  macro_exp_cur^.mi        := Nil;
  macro_exp_cur^.prev      := prev_ctx;

  For i := 0 To arg_cnt - 1 Do
  Begin
    nd := body_first;
    For j := 1 To body_cnt Do
    Begin
      subst := SubstOneParam(nd^.line, pname, args[i]);
      New(en);
      en^.line := subst;
      en^.next := Nil;
      If macro_exp_cur^.line_tail = Nil Then
        macro_exp_cur^.line_head := en
      Else
        macro_exp_cur^.line_tail^.next := en;
      macro_exp_cur^.line_tail := en;
      nd := nd^.next;
    End;
  End;
  macro_exp_cur^.cur_node := macro_exp_cur^.line_head;
End;

{ ============================================================
  ParseIrpc : IRPC param, chaine ... ENDM
  Itere sur chaque caractere de la chaine.
  ============================================================ }
Procedure ParseIrpc;
Var
  pname      : TSymString;
  body_cnt   : Integer;
  body_first : PLineNode;
  i, j       : Integer;
  str_val    : TString;
  subst      : TString;
  char_str   : TString;
  nd         : PLineNode;
  en         : PLineNode;
  prev_ctx   : PExpCtx;
Begin
  pname := '';
  If LexPeekKind = TK_IDENT Then
  Begin
    LexNext;
    pname := lex_tok.val;
  End;
  If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ',') Then LexNext;

  { lire la chaine : <xxxx> ou 'xxxx' ou identificateur }
  str_val := '';
  If (LexPeekKind = TK_PUNCT) And (LexPeekVal = '<') Then
  Begin
    LexNext;
    While (LexPeekKind <> TK_NEWLINE) And (LexPeekKind <> TK_EOF) Do
    Begin
      LexNext;
      If (lex_tok.kind = TK_PUNCT) And (lex_tok.val = '>') Then Break;
      str_val := str_val + lex_tok.val;
    End;
  End
  Else If LexPeekKind = TK_STRING Then
  Begin
    LexNext;
    str_val := lex_tok.val;
  End
  Else If LexPeekKind = TK_IDENT Then
  Begin
    LexNext;
    str_val := lex_tok.val;
  End;

  body_first := CollectBlock(body_cnt);
  If (Length(str_val) = 0) Or (body_cnt = 0) Then Exit;

  { pousser un nouveau contexte d expansion }
  prev_ctx              := macro_exp_cur;
  New(macro_exp_cur);
  macro_exp_cur^.line_head := Nil;
  macro_exp_cur^.line_tail := Nil;
  macro_exp_cur^.cur_node  := Nil;
  macro_exp_cur^.do_exitm  := False;
  macro_exp_cur^.mi        := Nil;
  macro_exp_cur^.prev      := prev_ctx;

  For i := 1 To Length(str_val) Do
  Begin
    char_str := str_val[i];
    nd := body_first;
    For j := 1 To body_cnt Do
    Begin
      subst := SubstOneParam(nd^.line, pname, char_str);
      New(en);
      en^.line := subst;
      en^.next := Nil;
      If macro_exp_cur^.line_tail = Nil Then
        macro_exp_cur^.line_head := en
      Else
        macro_exp_cur^.line_tail^.next := en;
      macro_exp_cur^.line_tail := en;
      nd := nd^.next;
    End;
  End;
  macro_exp_cur^.cur_node := macro_exp_cur^.line_head;
End;

{ ============================================================
  MacroExitm : signaler EXITM depuis le corps d une macro.
  Marque do_exitm sur le niveau courant d expansion.
  ============================================================ }
Procedure MacroExitm;
Begin
  If macro_exp_cur <> Nil Then
    macro_exp_cur^.do_exitm := True;
End;

{ ============================================================
  ParsePurge : PURGE nom [, nom ...]
  Marque une ou plusieurs macros comme purgees.
  ============================================================ }
Procedure ParsePurge;
Var
  mi  : PMacroDef;
  tok : TSymString;
Begin
  Repeat
    If LexPeekKind <> TK_IDENT Then Break;
    LexNext;
    tok := lex_tok.val;
    mi  := MacroFind(tok);
    If mi <> Nil Then
      mi^.purged := True
    Else
      WarnMsg('PURGE : macro inconnue : ' + tok);
    If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ',') Then
      LexNext
    Else
      Break;
  Until False;
End;

{ ============================================================
  ASSEMBLAGE CONDITIONNEL (IF / IFDEF / ELSE / ENDIF)
  ============================================================ }

Type
  TIfEntry = Record
    active   : Boolean;  { True = on assemble ce bloc }
    had_true : Boolean;  { True = une branche a deja ete prise }
  End;

Var
  if_stack : Array[0..MAX_IF_DEPTH-1] Of TIfEntry;
  if_top   : Integer;   { -1 si aucun bloc IF actif }

{ ============================================================
  IfInit : initialiser la pile des blocs conditionnels
  ============================================================ }
Procedure IfInit;
Var
  i : Integer;
Begin
  if_top := -1;
  For i := 0 To MAX_IF_DEPTH-1 Do
  Begin
    if_stack[i].active   := True;
    if_stack[i].had_true := False;
  End;
End;

{ ============================================================
  IfAssembling : True si toute la pile dit "actif"
  (i.e. on doit assembler la ligne courante).
  ============================================================ }
Function IfAssembling : Boolean;
Begin
  If if_top < 0 Then
    IfAssembling := True
  Else
    IfAssembling := if_stack[if_top].active;
End;

{ ============================================================
  IfPushCond : empiler un nouveau bloc IF.
  cond = resultat du test (True = assembler le THEN).
  Si on est deja dans un bloc inactif, on empile inactif.
  ============================================================ }
Procedure IfPushCond(cond : Boolean);
Var
  parent_active : Boolean;
Begin
  parent_active := IfAssembling;
  If if_top >= MAX_IF_DEPTH - 1 Then
  Begin
    ErrorMsg('Trop de blocs IF imbriques (max 32)');
    Exit;
  End;
  Inc(if_top);
  if_stack[if_top].active   := parent_active And cond;
  if_stack[if_top].had_true := parent_active And cond;
End;

{ ============================================================
  IfHandleElse : traiter ELSE dans le contexte courant.
  ============================================================ }
Procedure IfHandleElse;
Var
  parent_active : Boolean;
Begin
  If if_top < 0 Then
  Begin
    ErrorMsg('ELSE sans IF');
    Exit;
  End;
  If if_stack[if_top].had_true Then
    if_stack[if_top].active := False
  Else
  Begin
    If if_top > 0 Then parent_active := if_stack[if_top-1].active
    Else               parent_active := True;
    if_stack[if_top].active   := parent_active;
    if_stack[if_top].had_true := parent_active;
  End;
End;

{ ============================================================
  IfHandleElseIf : traiter ELSEIF expr dans le contexte courant.
  ============================================================ }
Procedure IfHandleElseIf(cond : Boolean);
Var
  parent_active : Boolean;
Begin
  If if_top < 0 Then
  Begin
    ErrorMsg('ELSEIF sans IF');
    Exit;
  End;
  If if_stack[if_top].had_true Then
    if_stack[if_top].active := False
  Else
  Begin
    If if_top > 0 Then parent_active := if_stack[if_top-1].active
    Else               parent_active := True;
    if_stack[if_top].active   := parent_active And cond;
    if_stack[if_top].had_true := parent_active And cond;
  End;
End;

{ ============================================================
  IfHandleEndif : traiter ENDIF.
  ============================================================ }
Procedure IfHandleEndif;
Begin
  If if_top < 0 Then
  Begin
    ErrorMsg('ENDIF sans IF');
    Exit;
  End;
  Dec(if_top);
End;

{ ============================================================
  IfReadAngle : lire le contenu de <...> sur la ligne courante.
  Retourne le texte interieur sans les < >.
  ============================================================ }
Function IfReadAngle : TString;
Var
  s : TString;
Begin
  s := '';
  If (LexPeekKind = TK_PUNCT) And (LexPeekVal = '<') Then
    LexNext
  Else
  Begin
    IfReadAngle := '';
    Exit;
  End;
  While (LexPeekKind <> TK_NEWLINE) And (LexPeekKind <> TK_EOF) Do
  Begin
    If (LexPeekKind = TK_PUNCT) And (LexPeekVal = '>') Then
    Begin
      LexNext;
      Break;
    End;
    LexNext;
    If Length(s) > 0 Then s := s + ' ';
    s := s + lex_tok.val;
  End;
  IfReadAngle := s;
End;

{ ---- Table des directives conditionnelles pour ParseConditional ---- }
Const
  PC_IF         =  1; PC_IFE        =  2; PC_IF1        =  3; PC_IF2        =  4;
  PC_IFDEF      =  5; PC_IFNDEF     =  6; PC_IFB        =  7; PC_IFNB       =  8;
  PC_IFIDN      =  9; PC_IFIDNI     = 10; PC_IFDIF      = 11; PC_IFDIFI     = 12;
  PC_ELSE       = 13; PC_ELSEIF     = 14; PC_ELSEIFDEF  = 15; PC_ELSEIFNDEF = 16;
  PC_ENDIF      = 17;
  PC_ERR        = 18; PC_ERR1       = 19; PC_ERR2       = 20;
  PC_ERRDEF     = 21; PC_ERRNDEF    = 22;
  PC_ERRB       = 23; PC_ERRNB      = 24;
  PC_ERRIDN     = 25; PC_ERRDIF     = 26;
  PC_ERRE       = 27; PC_ERRNZ      = 28;
  PC_ERRGE      = 29; PC_ERRLT      = 30; PC_ERRLE      = 31; PC_ERRGT      = 32;
  PC_COUNT      = 32;
  PC_NAMES : Array[1..32] Of String[10] = (
    'IF','IFE','IF1','IF2',
    'IFDEF','IFNDEF','IFB','IFNB',
    'IFIDN','IFIDNI','IFDIF','IFDIFI',
    'ELSE','ELSEIF','ELSEIFDEF','ELSEIFNDEF',
    'ENDIF',
    '.ERR','.ERR1','.ERR2',
    '.ERRDEF','.ERRNDEF',
    '.ERRB','.ERRNB',
    '.ERRIDN','.ERRDIF',
    '.ERRE','.ERRNZ',
    '.ERRGE','.ERRLT','.ERRLE','.ERRGT'
  );

{ ============================================================
  ParseConditional : dispatcher pour toutes les directives
  conditionnelles (IF/IFDEF/ELSE/ENDIF/...).
  Retourne True si le mot-cle a ete reconnu (qu on assemble
  ou non : les directives de structure IF/ENDIF doivent toujours
  etre traitees pour maintenir l imbrication).
  ============================================================ }
Function ParseConditional(Const dir : TString) : Boolean;
Var
  e        : TExpr;
  tok      : TString;
  p        : PSymbol;
  cond     : Boolean;
  a_text   : TString;
  b_text   : TString;
  a_upper  : TString;
  b_upper  : TString;
  i        : Integer;
  pc_idx   : Integer;
Begin
  ParseConditional := True;
  pc_idx := 0;
  For i := 1 To PC_COUNT Do
    If PC_NAMES[i] = dir Then Begin pc_idx := i; Break; End;

  Case pc_idx Of

    PC_IF:
    Begin
      ExprMakeNum(e, 0);
      If IfAssembling Then EvalExpr(e) Else e.val := 0;
      IfPushCond(e.val <> 0);
    End;

    PC_IFE:
    Begin
      ExprMakeNum(e, 0);
      If IfAssembling Then EvalExpr(e) Else e.val := 1;
      IfPushCond(e.val = 0);
    End;

    PC_IF1: IfPushCond(pass_num <= 1);
    PC_IF2: IfPushCond(pass_num = 2);

    PC_IFDEF:
    Begin
      cond := False;
      If LexPeekKind = TK_IDENT Then
      Begin
        LexNext; tok := lex_tok.val; p := SymFind(tok);
        cond := (p <> Nil) And (p^.kind <> SK_UNDEF);
      End;
      IfPushCond(cond);
    End;

    PC_IFNDEF:
    Begin
      cond := True;
      If LexPeekKind = TK_IDENT Then
      Begin
        LexNext; tok := lex_tok.val; p := SymFind(tok);
        cond := (p = Nil) Or (p^.kind = SK_UNDEF);
      End;
      IfPushCond(cond);
    End;

    PC_IFB:
    Begin
      a_text := '';
      If IfAssembling Then a_text := IfReadAngle;
      IfPushCond(a_text = '');
    End;

    PC_IFNB:
    Begin
      a_text := '';
      If IfAssembling Then a_text := IfReadAngle;
      IfPushCond(a_text <> '');
    End;

    PC_IFIDN:
    Begin
      a_text := ''; b_text := '';
      If IfAssembling Then
      Begin
        a_text := IfReadAngle;
        If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ',') Then LexNext;
        b_text := IfReadAngle;
      End;
      IfPushCond(a_text = b_text);
    End;

    PC_IFIDNI:
    Begin
      a_text := ''; b_text := ''; a_upper := ''; b_upper := '';
      If IfAssembling Then
      Begin
        a_text := IfReadAngle;
        If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ',') Then LexNext;
        b_text := IfReadAngle;
      End;
      For i := 1 To Length(a_text) Do a_upper := a_upper + UpCase(a_text[i]);
      For i := 1 To Length(b_text) Do b_upper := b_upper + UpCase(b_text[i]);
      IfPushCond(a_upper = b_upper);
    End;

    PC_IFDIF:
    Begin
      a_text := ''; b_text := '';
      If IfAssembling Then
      Begin
        a_text := IfReadAngle;
        If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ',') Then LexNext;
        b_text := IfReadAngle;
      End;
      IfPushCond(a_text <> b_text);
    End;

    PC_IFDIFI:
    Begin
      a_text := ''; b_text := ''; a_upper := ''; b_upper := '';
      If IfAssembling Then
      Begin
        a_text := IfReadAngle;
        If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ',') Then LexNext;
        b_text := IfReadAngle;
      End;
      For i := 1 To Length(a_text) Do a_upper := a_upper + UpCase(a_text[i]);
      For i := 1 To Length(b_text) Do b_upper := b_upper + UpCase(b_text[i]);
      IfPushCond(a_upper <> b_upper);
    End;

    PC_ELSE:     IfHandleElse;

    PC_ELSEIF:
    Begin
      ExprMakeNum(e, 0);
      If (if_top >= 0) And (Not if_stack[if_top].had_true) Then
      Begin
        If IfAssembling Then EvalExpr(e) Else e.val := 0;
        cond := (e.val <> 0);
      End
      Else cond := False;
      IfHandleElseIf(cond);
    End;

    PC_ELSEIFDEF:
    Begin
      cond := False;
      If (if_top >= 0) And (Not if_stack[if_top].had_true) Then
        If LexPeekKind = TK_IDENT Then
        Begin
          LexNext; tok := lex_tok.val; p := SymFind(tok);
          cond := (p <> Nil) And (p^.kind <> SK_UNDEF);
        End;
      IfHandleElseIf(cond);
    End;

    PC_ELSEIFNDEF:
    Begin
      cond := True;
      If (if_top >= 0) And (Not if_stack[if_top].had_true) Then
        If LexPeekKind = TK_IDENT Then
        Begin
          LexNext; tok := lex_tok.val; p := SymFind(tok);
          cond := (p = Nil) Or (p^.kind = SK_UNDEF);
        End;
      IfHandleElseIf(cond);
    End;

    PC_ENDIF: IfHandleEndif;

    PC_ERR:  If IfAssembling Then ErrorMsg('.ERR : erreur forcee');
    PC_ERR1: If IfAssembling And (pass_num <= 1) Then ErrorMsg('.ERR1 : erreur passe 1');
    PC_ERR2: If IfAssembling And (pass_num = 2)  Then ErrorMsg('.ERR2 : erreur passe 2');

    PC_ERRDEF:
    Begin
      If LexPeekKind = TK_IDENT Then
      Begin
        LexNext; tok := lex_tok.val; p := SymFind(tok);
        If IfAssembling And (p <> Nil) And (p^.kind <> SK_UNDEF) Then
          ErrorMsg('.ERRDEF : symbole defini : ' + tok);
      End;
    End;

    PC_ERRNDEF:
    Begin
      If LexPeekKind = TK_IDENT Then
      Begin
        LexNext; tok := lex_tok.val; p := SymFind(tok);
        If IfAssembling And ((p = Nil) Or (p^.kind = SK_UNDEF)) Then
          ErrorMsg('.ERRNDEF : symbole non defini : ' + tok);
      End;
    End;

    PC_ERRB:
    Begin
      a_text := '';
      If IfAssembling Then a_text := IfReadAngle;
      If IfAssembling And (a_text = '') Then ErrorMsg('.ERRB : argument vide');
    End;

    PC_ERRNB:
    Begin
      a_text := '';
      If IfAssembling Then a_text := IfReadAngle;
      If IfAssembling And (a_text <> '') Then ErrorMsg('.ERRNB : argument non vide');
    End;

    PC_ERRIDN:
    Begin
      a_text := ''; b_text := '';
      If IfAssembling Then
      Begin
        a_text := IfReadAngle;
        If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ',') Then LexNext;
        b_text := IfReadAngle;
      End;
      If IfAssembling And (a_text = b_text) Then
        ErrorMsg('.ERRIDN : arguments identiques');
    End;

    PC_ERRDIF:
    Begin
      a_text := ''; b_text := '';
      If IfAssembling Then
      Begin
        a_text := IfReadAngle;
        If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ',') Then LexNext;
        b_text := IfReadAngle;
      End;
      If IfAssembling And (a_text <> b_text) Then
        ErrorMsg('.ERRDIF : arguments differents');
    End;

    PC_ERRE:
    Begin
      ExprMakeNum(e, 0);
      If IfAssembling Then EvalExpr(e) Else e.val := 0;
      If IfAssembling And (e.val = 0) Then
        ErrorMsg('.ERRE : expression evaluee a 0');
    End;

    PC_ERRNZ:
    Begin
      ExprMakeNum(e, 0);
      If IfAssembling Then EvalExpr(e) Else e.val := 0;
      If IfAssembling And (e.val <> 0) Then
        ErrorMsg('.ERRNZ : expression evaluee a non-zero');
    End;

    PC_ERRGE, PC_ERRLT, PC_ERRLE, PC_ERRGT:
    Begin
      ExprMakeNum(e, 0);
      If IfAssembling Then EvalExpr(e) Else e.val := 0;
      Case pc_idx Of
        PC_ERRGE: cond := (e.val >= 0);
        PC_ERRLT: cond := (e.val <  0);
        PC_ERRLE: cond := (e.val <= 0);
      Else        cond := (e.val >  0);
      End;
      If IfAssembling And cond Then
        ErrorMsg(dir + ' : condition verifiee');
    End;

  Else
    ParseConditional := False;
  End; { Case }
End;

{ ============================================================
  PROCEDURES ET CONVENTIONS D APPEL (PROC ENDP)
  ============================================================ }

Const
  MAX_PROC_NEST   = 8;    { imbrication max de PROCs }
  MAX_PROC_PARAMS = 32;   { parametres max par PROC }
  MAX_PROC_USES   = 16;   { registres USES max par PROC }

{ Convention d appel }
Const
  LANG_NONE    = 0;
  LANG_C       = 1;
  LANG_PASCAL  = 2;
  LANG_FORTRAN = 3;
  LANG_SYSCALL = 4;
  LANG_STDCALL = 5;

Type
  TProcParam = Record
    pname  : TSymString;
    ptype  : TString;
    psize  : Integer;   { taille en octets }
    bp_off : Integer;   { offset depuis BP }
  End;

  PProcInfo = ^TProcInfo;

  TProcInfo = Record
    pname      : TSymString;
    is_far     : Boolean;
    lang       : Integer;      { LANG_xxx }
    uses_regs  : Array[1..MAX_PROC_USES] Of Integer;  { index reg 0..7 }
    uses_cnt   : Integer;
    params     : Array[1..MAX_PROC_PARAMS] Of TProcParam;
    param_cnt  : Integer;
    prev       : PProcInfo;   { maillon precedent (pile) }
  End;

Var
  proc_stack_top : PProcInfo;

{ ============================================================
  ProcInit : initialiser la pile des procedures
  ============================================================ }
Procedure ProcInit;
Begin
  proc_stack_top := Nil;
End;

{ ============================================================
  RegNameToIdx : convertir un nom de registre 16 bits en index
  0..7 (AX=0 CX=1 DX=2 BX=3 SP=4 BP=5 SI=6 DI=7).
  Retourne -1 si non reconnu.
  ============================================================ }
Const RN16_COUNT = 8;
      RN16_NAMES: Array[1..8] Of String[2] = (
        'AX','CX','DX','BX','SP','BP','SI','DI'
      );

Function RegNameToIdx(Const rname : TString) : Integer;
Var i : Integer;
Begin
  For i := 1 To RN16_COUNT Do
    If RN16_NAMES[i] = rname Then Begin RegNameToIdx := i - 1; Exit; End;
  RegNameToIdx := -1;
End;

{ ============================================================
  EmitPushReg16 / EmitPopReg16 : emettre PUSH/POP registre
  ============================================================ }
Procedure EmitPushReg16(ridx : Integer);
Begin
  EmitByte(Byte($50 Or ridx));
End;

Procedure EmitPopReg16(ridx : Integer);
Begin
  EmitByte(Byte($58 Or ridx));
End;

Const PL_COUNT = 5;
      PL_NAMES: Array[1..5] Of String[7] = (
        'C','PASCAL','FORTRAN','SYSCALL','STDCALL'
      );
      PP_KW_COUNT = 5;
      PP_KW_NAMES: Array[1..5] Of String[6] = (
        'USES','LANG','NEAR','FAR','INVOKE'
      );

{ ============================================================
  ParseProc : nom PROC [NEAR|FAR] [LANG:C|PASCAL|...]
              [USES reg1 reg2 ...] [param1:TYPE, ...]
  ============================================================ }
Procedure ParseProc(Const pname : TSymString);
Var
  pi       : TProcInfo;
  tok      : TString;
  ridx     : Integer;
  bp_off   : Integer;
  i        : Integer;
  p        : PSymbol;
  tname    : TString;
  sz       : Integer;
  ret_sz   : Integer;
Begin
  { initialiser l entree }
  pi.pname     := pname;
  pi.is_far    := call_far;
  pi.lang      := LANG_NONE;
  pi.uses_cnt  := 0;
  pi.param_cnt := 0;
  For i := 1 To MAX_PROC_USES   Do pi.uses_regs[i] := -1;

  { ---- NEAR / FAR optionnel ---- }
  If LexPeekKind = TK_IDENT Then
  Begin
    tok := LexPeekVal;
    If      tok = 'NEAR' Then Begin pi.is_far := False; LexNext; End
    Else If tok = 'FAR'  Then Begin pi.is_far := True;  LexNext; End;
  End;

  { ---- LANG[:] convention optionnelle ---- }
  If (LexPeekKind = TK_IDENT) And (LexPeekVal = 'LANG') Then
  Begin
    LexNext;
    If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ':') Then LexNext;
    If LexPeekKind = TK_IDENT Then
    Begin
      LexNext;
      tok := lex_tok.val;
      i := 1;
      While (i <= PL_COUNT) And (PL_NAMES[i] <> tok) Do Inc(i);
      If i <= PL_COUNT Then pi.lang := i
      Else WarnMsg('Convention d appel inconnue : ' + tok);
    End;
  End;

  { ---- USES reg1 reg2 ... ---- }
  If (LexPeekKind = TK_IDENT) And (LexPeekVal = 'USES') Then
  Begin
    LexNext;  { consommer USES }
    While LexPeekKind = TK_IDENT Do
    Begin
      tok  := LexPeekVal;
      ridx := RegNameToIdx(tok);
      If ridx < 0 Then Break;
      LexNext;
      If pi.uses_cnt < MAX_PROC_USES Then
      Begin
        Inc(pi.uses_cnt);
        pi.uses_regs[pi.uses_cnt] := ridx;
      End;
      { virgule optionnelle entre registres }
      If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ',') Then LexNext;
    End;
  End;

  { ---- definir le label de la procedure ---- }
  If pi.is_far Then sz := 4 Else sz := 2;
  SymDefineLabel(pname, cur_seg, lc, sz);
  p := SymFind(pname);
  If p <> Nil Then
  Begin
    p^.kind := SK_LABEL;
    p^.size := sz;
  End;

  { ---- emettre les PUSH des registres USES ---- }
  For i := 1 To pi.uses_cnt Do
    EmitPushReg16(pi.uses_regs[i]);

  { ---- calcul des offsets BP pour les parametres ----
    Convention : le code d entree typique est
      PUSH BP / MOV BP,SP
    L appel NEAR empile @IP (2 octets) ; FAR empile @CS:@IP (4 octets).
    BP+0 = ancien BP sauve ; BP+2 = @IP (near) ou @CS:@IP (far)
    Donc : base = 2 (BP propre) + ret_sz
    Avec USES, chaque registre sauvegarde diminue aussi le
    decalage, MAIS MASM calcule les offsets AVANT les sauvegardes
    USES (les param sont accessibles via BP apres PUSH BP / MOV BP,SP). }
  If pi.is_far Then ret_sz := 4 Else ret_sz := 2;
  { BP+0 = sauvegarde, BP+2 ou BP+4 = adresse retour }
  bp_off := 2 + ret_sz;  { premier parametre }

  { ---- parser les parametres param:TYPE [, ...] ----
    Ils peuvent etre sur la meme ligne ou avec separateur virgule.
    Convention C : param1 = premier argument pousse (par le caller
    en convention C, dernier argument empile, donc a l offset le
    plus bas). On assigne les offsets dans l ordre de declaration. }
  While LexPeekKind = TK_IDENT Do
  Begin
    { nom du parametre }
    If pi.param_cnt >= MAX_PROC_PARAMS Then Break;
    LexNext;
    tok := lex_tok.val;
    { verifier que c est pas un mot-cle de fin }
    i := 1;
    While (i <= PP_KW_COUNT) And (PP_KW_NAMES[i] <> tok) Do Inc(i);
    If i <= PP_KW_COUNT Then Break;
    Inc(pi.param_cnt);
    pi.params[pi.param_cnt].pname := tok;
    pi.params[pi.param_cnt].ptype := 'WORD';
    pi.params[pi.param_cnt].psize := 2;

    { : TYPE optionnel }
    If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ':') Then
    Begin
      LexNext;
      If LexPeekKind = TK_IDENT Then
      Begin
        LexNext;
        tname := lex_tok.val;
        sz    := TypeNameToSize(tname);
        If sz = 0 Then sz := 2;  { PROC/ABS -> WORD par defaut }
        pi.params[pi.param_cnt].ptype := tname;
        pi.params[pi.param_cnt].psize := sz;
      End;
    End;

    pi.params[pi.param_cnt].bp_off := bp_off;
    bp_off := bp_off + pi.params[pi.param_cnt].psize;

    { creer le symbole EQU pour ce parametre (BP offset) }
    p := SymFind(pi.params[pi.param_cnt].pname);
    If p = Nil Then
      p := SymEnter(pi.params[pi.param_cnt].pname, SK_EQU, 0, 0,
                    pi.params[pi.param_cnt].bp_off)
    Else
    Begin
      p^.kind  := SK_EQU;
      p^.value := pi.params[pi.param_cnt].bp_off;
    End;
    SymSetValue(p, pi.params[pi.param_cnt].bp_off);
    p^.flags := p^.flags Or 8;  { reassignable (local au PROC) }

    If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ',') Then LexNext;
  End;

  { empiler cette info PROC }
  pi.prev := proc_stack_top;
  New(proc_stack_top);
  proc_stack_top^ := pi;
End;

{ ============================================================
  ParseEndp : nom ENDP
  Emet les POP des registres USES en ordre inverse.
  Verifie la correspondance avec le dernier PROC ouvert.
  ============================================================ }
Procedure ParseEndp(Const pname : TSymString);
Var
  i         : Integer;
  prev_proc : PProcInfo;
Begin
  If proc_stack_top = Nil Then
  Begin
    ErrorMsg('ENDP sans PROC : ' + pname);
    Exit;
  End;
  If (pname <> '') And (proc_stack_top^.pname <> pname) Then
    WarnMsg('ENDP ' + pname + ' ne correspond pas au dernier PROC ' +
            proc_stack_top^.pname);

  { emettre les POP en ordre inverse des PUSH }
  For i := proc_stack_top^.uses_cnt DownTo 1 Do
    EmitPopReg16(proc_stack_top^.uses_regs[i]);

  prev_proc      := proc_stack_top^.prev;
  Dispose(proc_stack_top);
  proc_stack_top := prev_proc;
End;

{ ============================================================
  ParseEnter : ENTER imm16, imm8  (80186+)
  Opcode : C8h imm16 imm8
  ============================================================ }
Procedure ParseEnter;
Var
  frame_sz  : TLong;
  nest_lev  : TLong;
  e         : TExpr;
Begin
  WarnMsg('ENTER : necessite 80186+');
  ExprMakeNum(e, 0);
  EvalExpr(e);
  frame_sz := e.val;
  If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ',') Then LexNext;
  ExprMakeNum(e, 0);
  EvalExpr(e);
  nest_lev := e.val;
  EmitByte($C8);
  EmitWord(Word(frame_sz));
  EmitByte(Byte(nest_lev));
End;

{ ============================================================
  ParseLeave : LEAVE  (80186+)
  Opcode : C9h
  ============================================================ }
Procedure ParseLeave;
Begin
  WarnMsg('LEAVE : necessite 80186+');
  EmitByte($C9);
End;

{ ============================================================
  ParseInvoke : INVOKE procname [, arg1 [, arg2 ...]]
  Génère le code d appel en empilant les arguments selon
  la convention LANG du PROC cible (C = de droite a gauche).
  ============================================================ }
Procedure ParseInvoke;
Var
  tok       : TString;
  lang      : Integer;
  is_far    : Boolean;
  e         : TExpr;
  args      : Array[1..MAX_PROC_PARAMS] Of TLong;
  arg_cnt   : Integer;
  i         : Integer;
  p         : PSymbol;
  pc        : PProcInfo;
Begin
  { nom du proc cible }
  If LexPeekKind <> TK_IDENT Then
  Begin
    ErrorMsg('INVOKE : nom de procedure attendu');
    Exit;
  End;
  LexNext;
  tok := lex_tok.val;

  { chercher la procedure pour connaitre sa convention }
  lang   := LANG_C;
  is_far := call_far;
  p      := SymFind(tok);
  If p <> Nil Then
  Begin
    If p^.size = 4 Then is_far := True
    Else                 is_far := False;
  End;
  { chercher dans proc_stack (procedures encore ouvertes) }
  pc := proc_stack_top;
  While pc <> Nil Do
  Begin
    If pc^.pname = tok Then
    Begin
      lang   := pc^.lang;
      is_far := pc^.is_far;
      Break;
    End;
    pc := pc^.prev;
  End;

  { parser les arguments }
  arg_cnt := 0;
  While (LexPeekKind <> TK_NEWLINE) And (LexPeekKind <> TK_EOF) Do
  Begin
    If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ',') Then
    Begin
      LexNext;
      Continue;
    End;
    ExprMakeNum(e, 0);
    EvalExpr(e);
    If arg_cnt < MAX_PROC_PARAMS Then
    Begin
      Inc(arg_cnt);
      args[arg_cnt] := e.val;
    End;
  End;

  { emettre les PUSH selon la convention d appel }
  If lang = LANG_PASCAL Then
  Begin
    { PASCAL : empile de gauche a droite }
    For i := 1 To arg_cnt Do
    Begin
      EmitByte($68);             { PUSH imm16 }
      EmitWord(Word(args[i]));
    End;
  End
  Else
  Begin
    { C / SYSCALL / par defaut : empile de droite a gauche }
    For i := arg_cnt DownTo 1 Do
    Begin
      EmitByte($68);
      EmitWord(Word(args[i]));
    End;
  End;

  { emettre le CALL }
  If is_far Then
  Begin
    { CALL FAR : E8h / 9Ah - on emet E8h+reloc (passe 2 resoudra) }
    EmitByte($9A);
    EmitWord(0);   { offset }
    EmitWord(0);   { segment (fixup necessaire - genere en passe 2) }
  End
  Else
  Begin
    { CALL NEAR relative : E8h + cw }
    EmitByte($E8);
    EmitWord(0);   { le vrai deplacement sera calcule en passe 2 }
  End;
End;

{ ============================================================
  FICHIER DE LISTING (.LST) - IMPLEMENTE
  ============================================================ }

{ ------------------------------------------------------------ }
Function LstHex2(b : Byte) : TString;
Const
  hx : Array[0..15] Of Char = '0123456789ABCDEF';
Begin
  LstHex2 := hx[b Shr 4] + hx[b And $0F];
End;

Function LstHex4(w : TWord) : TString;
Begin
  LstHex4 := LstHex2(Hi(w)) + LstHex2(Lo(w));
End;

Function LstPad(Const s : TString; n : Integer) : TString;
Var r : TString;
Begin
  r := s;
  While Length(r) < n Do r := r + ' ';
  LstPad := r;
End;

Function LstNumStr(n : Integer; width : Integer) : TString;
Var s : TString;
Begin
  Str(n, s);
  While Length(s) < width Do s := ' ' + s;
  LstNumStr := s;
End;

{ ============================================================
  LstWriteRaw : ecrire une ligne brute + saut de page auto.
  ============================================================ }
Procedure LstWriteRaw(Const s : TString);
Begin
  If Not lst_is_open Then Exit;
  Writeln(lst_file, s);
  Inc(lst_line_on_page);
  If (lst_page_lines > 0) And (lst_line_on_page >= lst_page_lines) Then
  Begin
    Writeln(lst_file, #12);
    Inc(lst_page_num);
    lst_line_on_page := 0;
    If lst_title  <> '' Then Begin Writeln(lst_file, lst_title);  Inc(lst_line_on_page); End;
    If lst_subttl <> '' Then Begin Writeln(lst_file, lst_subttl); Inc(lst_line_on_page); End;
  End;
End;

{ ============================================================
  LstOpen : ouvrir le fichier listing.
  ============================================================ }
Procedure LstOpen(Const fname : TString);
Begin
  If lst_is_open Then Exit;
  Assign(lst_file, fname);
  {$I-}
  Rewrite(lst_file);
  {$I+}
  If IoResult <> 0 Then
  Begin
    WarnMsg('Impossible de creer le fichier listing : ' + fname);
    do_listing := False;
    Exit;
  End;
  lst_is_open      := True;
  lst_active       := True;
  lst_page_num     := 1;
  lst_line_on_page := 0;
  If lst_title  <> '' Then Begin Writeln(lst_file, lst_title);  Inc(lst_line_on_page); End;
  If lst_subttl <> '' Then Begin Writeln(lst_file, lst_subttl); Inc(lst_line_on_page); End;
End;

{ ============================================================
  LstEmitLine : ecrire une ligne assemblee dans le listing.
  Format MASM 5.x :
    NNNNN  OOOO  BB BB BB BB BB BB BB BB  source
  Si nbytes > 8 : lignes de continuation.
  ============================================================ }
Procedure LstEmitLine(lineno : Integer; lc_start : TWord;
                      seg_idx : Integer;
                      nbytes  : Integer; Const src : TString);
Var
  hex_part : TString;
  col      : TString;
  ofs_str  : TString;
  i        : Integer;
  blk      : Integer;
  byte_pos : Integer;
Begin
  If Not lst_is_open Then Exit;
  If Not lst_active  Then Exit;

  If seg_idx > 0 Then
    ofs_str := LstHex4(lc_start)
  Else
    ofs_str := '    ';

  byte_pos := 0;

  If nbytes = 0 Then
  Begin
    { ligne sans octet emis }
    col := LstNumStr(lineno, 5) + '  ' + ofs_str
         + '                           ' + src;
    LstWriteRaw(col);
  End
  Else
  Begin
    blk := nbytes;
    If blk > 8 Then blk := 8;
    hex_part := '';
    For i := 0 To blk-1 Do
      hex_part := hex_part + LstHex2(lst_bytes[byte_pos+i]) + ' ';
    While Length(hex_part) < 25 Do hex_part := hex_part + ' ';
    col := LstNumStr(lineno, 5) + '  ' + ofs_str + '  ' + hex_part + src;
    LstWriteRaw(col);
    Inc(byte_pos, blk);

    { lignes de continuation (plus de 8 octets) }
    While byte_pos < nbytes Do
    Begin
      blk := nbytes - byte_pos;
      If blk > 8 Then blk := 8;
      hex_part := '';
      For i := 0 To blk-1 Do
        hex_part := hex_part + LstHex2(lst_bytes[byte_pos+i]) + ' ';
      While Length(hex_part) < 25 Do hex_part := hex_part + ' ';
      col := '       ' + LstHex4(TWord(lc_start + byte_pos)) + '  ' + hex_part;
      LstWriteRaw(col);
      Inc(byte_pos, blk);
    End;
  End;
End;

{ ============================================================
  LstEmitSymTable : section symboles et segments du listing.
  ============================================================ }
Procedure LstEmitSymTable;
Var
  i  : Integer;
  p  : PSymbol;
  kn : TString;
  sn : TString;
Begin
  If Not lst_is_open Then Exit;
  LstWriteRaw('');
  LstWriteRaw('Segments and Groups:');
  LstWriteRaw('');
  LstWriteRaw('                   N a m e                 Length  Align   Combine Class');
  For i := 1 To seg_count Do
    With seg_table[i] Do
      LstWriteRaw(LstPad(name, 32) + LstPad(LstHex4(size), 10)
        + LstPad('PARA', 8) + LstPad('PUBLIC', 10) + class_name);
  LstWriteRaw('');
  LstWriteRaw('Symbols:');
  LstWriteRaw('');
  LstWriteRaw('                   N a m e           Type    Value    Attr');
  For i := 0 To HASH_SIZE-1 Do
  Begin
    p := hash_table[i];
    While p <> Nil Do
    Begin
      Case p^.kind Of
        SK_LABEL, SK_PUBLIC : kn := 'L NEAR ';
        SK_EXTERN           : kn := 'EXTRN  ';
        SK_EQU              : kn := 'Number ';
        SK_STRUCT           : kn := 'STRUCT ';
        SK_MACRO            : kn := 'MACRO  ';
        Else                  kn := '???    ';
      End;
      If (p^.seg_idx >= 1) And (p^.seg_idx <= seg_count) Then
        sn := seg_table[p^.seg_idx].name
      Else
        sn := '';
      Case p^.kind Of
        SK_LABEL, SK_PUBLIC, SK_EXTERN :
          LstWriteRaw(LstPad(p^.name, 32) + LstPad(kn, 10)
            + LstPad(LstHex4(p^.offset), 9) + sn);
        SK_EQU :
          LstWriteRaw(LstPad(p^.name, 32) + LstPad(kn, 10)
            + LstNumStr(p^.value, 8));
        Else
          LstWriteRaw(LstPad(p^.name, 32) + kn);
      End;
      p := p^.next;
    End;
  End;
End;

{ ============================================================
  LstEmitMacroTable : section macros du listing.
  ============================================================ }
Procedure LstEmitMacroTable;
Var
  p : PMacroDef;
Begin
  If (Not lst_is_open) Or (macro_count = 0) Then Exit;
  LstWriteRaw('');
  LstWriteRaw('Macros:');
  LstWriteRaw('');
  LstWriteRaw('                   N a m e                 Params   Lines');
  p := macro_list_head;
  While p <> Nil Do
  Begin
    If Not p^.purged Then
      LstWriteRaw(LstPad(p^.mname, 32)
        + LstPad(LstNumStr(p^.param_cnt, 4), 9)
        + LstNumStr(p^.body_cnt, 5));
    p := p^.next;
  End;
End;

{ ============================================================
  LstEmitStats : statistiques finales du listing.
  ============================================================ }
Procedure LstEmitStats(n_lines : Integer);
Begin
  If Not lst_is_open Then Exit;
  LstWriteRaw('');
  LstWriteRaw(LstNumStr(n_lines, 6)    + ' Source  Line(s)');
  LstWriteRaw(LstNumStr(err_count, 6)  + ' Warning Error(s)');
  LstWriteRaw(LstNumStr(warn_count, 6) + ' Severe  Error(s)');
End;

{ ============================================================
  LstClose : fermer le fichier listing.
  ============================================================ }
Procedure LstClose;
Begin
  If Not lst_is_open Then Exit;
  Writeln(lst_file, '');
  Close(lst_file);
  lst_is_open := False;
End;

{ ============================================================
  DEUX PASSES D ASSEMBLAGE ET GESTION DES FIXUPS
  ============================================================ }

{ ---- Table des directives attendant un nom pour IsNameDirective ---- }
Const
  ND_COUNT = 17;
  ND_NAMES : Array[1..17] Of String[7] = (
    'DB','DW','DD','DQ','DT',
    'EQU','MACRO','PROC','ENDP','SEGMENT','ENDS',
    'STRUC','LABEL','RECORD','GROUP','COMM','TEXTEQU'
  );

{ ============================================================
  IsNameDirective : True si le mot est une directive qui
  attend un nom comme premier argument (syntaxe MASM).
  ============================================================ }
Function IsNameDirective(Const tok : TString) : Boolean;
Var i : Integer;
Begin
  For i := 1 To ND_COUNT Do
    If ND_NAMES[i] = tok Then Begin IsNameDirective := True; Exit; End;
  IsNameDirective := False;
End;

{ ============================================================
  Table des directives -- dispatcher par index entier
  ============================================================ }
Const
  MN_EQU        =  1;  MN_TEXTEQU    =  2;  MN_LABEL      =  3;
  MN_MACRO      =  4;  MN_ENDM       =  5;  MN_PURGE      =  6;
  MN_EXITM      =  7;  MN_LOCAL      =  8;  MN_REPT       =  9;
  MN_IRP        = 10;  MN_IRPC       = 11;  MN_PROC       = 12;
  MN_ENDP       = 13;  MN_STRUC      = 14;  MN_ENDS       = 15;
  MN_RECORD     = 16;  MN_SEGMENT    = 17;  MN_GROUP      = 18;
  MN_ASSUME     = 19;  MN_INCLUDE    = 20;  MN_INCLUDELIB = 21;
  MN_NAME       = 22;  MN_DOTMODEL   = 23;  MN_DOTCODE    = 24;
  MN_DOTDATA    = 25;  MN_DOTDATAQ   = 26;  MN_DOTCONST   = 27;
  MN_DOTSTACK   = 28;  MN_DOTRADIX   = 29;  MN_PUBLIC     = 30;
  MN_EXTRN      = 31;  MN_EXTERN     = 32;  MN_GLOBAL     = 33;
  MN_COMM       = 34;  MN_ORG        = 35;  MN_ALIGN      = 36;
  MN_EVEN       = 37;  MN_LIST       = 38;  MN_NOLIST     = 39;
  MN_XLIST      = 40;  MN_LISTALL    = 41;  MN_PAGE       = 42;
  MN_TITLE      = 43;  MN_SUBTTL     = 44;  MN_DOT8086    = 45;
  MN_DOT8087    = 46;  MN_DOT186     = 47;  MN_DOT286     = 48;
  MN_DOT286C    = 49;  MN_DOT286P    = 50;  MN_DOT386     = 51;
  MN_DOT386P    = 52;  MN_DOTDOSSEG  = 53;  MN_OPTION     = 54;
  MN_ENTER      = 55;  MN_LEAVE      = 56;  MN_INVOKE     = 57;
  DIR_COUNT     = 57;
  DIR_NAMES : Array[1..DIR_COUNT] Of String[12] = (
    'EQU',       'TEXTEQU',    'LABEL',      'MACRO',
    'ENDM',      'PURGE',      'EXITM',      'LOCAL',
    'REPT',      'IRP',        'IRPC',       'PROC',
    'ENDP',      'STRUC',      'ENDS',       'RECORD',
    'SEGMENT',   'GROUP',      'ASSUME',     'INCLUDE',
    'INCLUDELIB','NAME',       '.MODEL',     '.CODE',
    '.DATA',     '.DATA?',     '.CONST',     '.STACK',
    '.RADIX',    'PUBLIC',     'EXTRN',      'EXTERN',
    'GLOBAL',    'COMM',       'ORG',        'ALIGN',
    'EVEN',      '.LIST',      '.NOLIST',    '.XLIST',
    '.LISTALL',  'PAGE',       'TITLE',      'SUBTTL',
    '.8086',     '.8087',      '.186',       '.286',
    '.286C',     '.286P',      '.386',       '.386P',
    '.DOSSEG',   'OPTION',     'ENTER',      'LEAVE',
    'INVOKE'
  );

{ ============================================================
  AssembleLine : analyser et assembler une ligne source.
  ============================================================ }
Const AL_REP_COUNT = 5;
      AL_REP_NAMES: Array[1..5] Of String[5] = ('REP','REPE','REPZ','REPNE','REPNZ');
      SS_BYTE=1; SS_WORD=2; SS_DWORD=3; SS_PARA=4; SS_PAGE=5;
      SS_PUBLIC=6; SS_COMMON=7; SS_STACK=8; SS_MEMORY=9; SS_AT=10;
      SS_COUNT=10;
      SS_NAMES: Array[1..10] Of String[6] = (
        'BYTE','WORD','DWORD','PARA','PAGE',
        'PUBLIC','COMMON','STACK','MEMORY','AT'
      );

Procedure AssembleLine;
Var
  tok1       : TString;     { premier token (label ou mnemonic) }
  tok2       : TString;     { deuxieme token (directive ou :) }
  label_name : TSymString;
  has_label  : Boolean;
  mnem       : TString;
  mi         : PMacroDef;
  rest       : TString;
  rn         : TString;     { registre pour ASSUME }
  sn         : TString;     { segment pour ASSUME }
  inc_name   : TString;     { nom de fichier pour INCLUDE }
  lib_name   : TString;     { nom de librairie pour INCLUDELIB }
  seg_nm     : TString;     { nom de segment pour .CODE }
  stk_sz     : TLong;       { taille de stack pour .STACK }
  seg_aln    : TSegAlign;   { alignement pour SEGMENT }
  seg_comb   : TSegCombine; { combinaison pour SEGMENT }
  seg_cls    : TString;     { classe pour SEGMENT }
  si         : Integer;     { index de structure }
  p_entry    : PSymbol;     { point d entree (directive END label) }
  dir_idx    : Integer;     { index MN_* du dispatcher directives }
  i          : Integer;     { index boucle tableaux }
Begin
  { substituer les macros texte (@DATE, @TIME, @FILENAME, TEXTEQU) }
  cur_line := TextEquSubstLine(cur_line);

  { mettre a jour @CUR_LINE dans la table des symboles }
  SymSetValue(SymFind('@CUR_LINE'), cur_lineno);

  { reinitialiser le lexer sur la ligne courante }
  lex_line     := cur_line;
  lex_pos      := 1;
  lex_has_peek := False;
  lex_at_eol   := False;

  { ligne vide }
  If (LexPeekKind = TK_NEWLINE) Or (LexPeekKind = TK_EOF) Then Exit;

  { --- lire le premier token --- }
  LexNext;
  tok1 := lex_tok.val;

  { --- traitement des directives conditionnelles (toujours, meme si !IfAssembling) --- }
  If lex_tok.kind = TK_IDENT Then
  Begin
    i := 1;
    While (i <= PC_ENDIF) And (PC_NAMES[i] <> tok1) Do Inc(i);
    If i <= PC_ENDIF Then Begin ParseConditional(tok1); Exit; End;
  End;

  { --- si on n assemble pas ce bloc, skipper --- }
  If Not IfAssembling Then Exit;

  { --- directives d erreur conditionnelle (seulement si actif) --- }
  If lex_tok.kind = TK_IDENT Then
  Begin
    i := PC_ENDIF + 1;
    While (i <= PC_COUNT) And (PC_NAMES[i] <> tok1) Do Inc(i);
    If i <= PC_COUNT Then Begin ParseConditional(tok1); Exit; End;
  End;

  { --- directives REP/REPE/REPZ/REPNE/REPNZ (prefixes + instruction chaine) --- }
  If lex_tok.kind = TK_IDENT Then
  Begin
    i := 1;
    While (i <= AL_REP_COUNT) And (AL_REP_NAMES[i] <> tok1) Do Inc(i);
    If (i <= AL_REP_COUNT) And ParseInstr(tok1) Then Exit;
  End;

  { --- determiner si premier token est un label ou un mnemonic --- }
  label_name := '';
  has_label  := False;

  If lex_tok.kind = TK_IDENT Then
  Begin
    { regarder le deuxieme token }
    tok2 := LexPeekVal;
    If (LexPeekKind = TK_PUNCT) And (tok2 = ':') Then
    Begin
      { label avec colon : definir le label }
      has_label  := True;
      label_name := tok1;
      LexNext;  { consommer ':' }
      SymDefineLabel(label_name, cur_seg, lc, 2);
      { lire le mnemonic suivant }
      If (LexPeekKind = TK_NEWLINE) Or (LexPeekKind = TK_EOF) Then Exit;
      LexNext;
      tok1 := lex_tok.val;
    End
    Else If (LexPeekKind = TK_PUNCT) And (tok2 = '=') Then
    Begin
      { nom = expr }
      label_name := tok1;
      LexNext;  { consommer '=' }
      ParseEquAssign(label_name);
      Exit;
    End
    Else If (LexPeekKind = TK_IDENT) And IsNameDirective(LexPeekVal) Then
    Begin
      { label (sans colon) suivi d une directive }
      has_label  := True;
      label_name := tok1;
      LexNext;
      tok1 := lex_tok.val;  { la directive devient le mnemonic }
    End;
  End;

  { --- dispatcher sur le mnemonic / directive --- }
  mnem := tok1;

  { directives DB/DW/DD/DQ/DT }
  i := 1;
  While (i <= DD_COUNT) And (DD_NAMES[i] <> mnem) Do Inc(i);
  If i <= DD_COUNT Then
  Begin
    If Not has_label Then
      SymDefineLabel(label_name, cur_seg, lc, 0); { pas de label avant data }
    ParseDataDir(mnem, label_name);
    Exit;
  End;

  { --- dispatcher directives par index --- }
  dir_idx := 0;
  For i := 1 To DIR_COUNT Do
    If DIR_NAMES[i] = mnem Then Begin dir_idx := i; Break; End;
  Case dir_idx Of

    MN_EQU : Begin
      If label_name <> '' Then ParseEqu(label_name)
      Else ErrorMsg('EQU sans nom');
      Exit;
    End;

    MN_TEXTEQU : Begin
      If label_name <> '' Then ParseTextequ(label_name)
      Else ErrorMsg('TEXTEQU sans nom');
      Exit;
    End;

    MN_LABEL : Begin
      If label_name <> '' Then ParseLabelDir(label_name)
      Else ErrorMsg('LABEL sans nom');
      Exit;
    End;

    MN_MACRO : Begin
      If label_name <> '' Then ParseMacroDef(label_name)
      Else ErrorMsg('MACRO sans nom');
      Exit;
    End;

    MN_ENDM : Begin
      { ENDM isole (hors CollectBlock) : ignorer }
      Exit;
    End;

    MN_PURGE    : Begin ParsePurge;   Exit; End;
    MN_EXITM    : Begin MacroExitm;   Exit; End;
    MN_LOCAL    : Begin ParseLocal;   Exit; End;
    MN_REPT     : Begin ParseRept;    Exit; End;
    MN_IRP      : Begin ParseIrp;     Exit; End;
    MN_IRPC     : Begin ParseIrpc;    Exit; End;

    MN_PROC : Begin
      If label_name <> '' Then ParseProc(label_name)
      Else ErrorMsg('PROC sans nom');
      Exit;
    End;

    MN_ENDP : Begin
      ParseEndp(label_name);
      Exit;
    End;

    MN_STRUC : Begin
      If label_name <> '' Then ParseStruc(label_name)
      Else ErrorMsg('STRUC sans nom');
      Exit;
    End;

    MN_ENDS : Begin
      ParseEnds(label_name);
      Exit;
    End;

    MN_RECORD : Begin
      If label_name <> '' Then ParseRecord(label_name)
      Else ErrorMsg('RECORD sans nom');
      Exit;
    End;

    MN_SEGMENT : Begin
      { parser les attributs optionnels }
      seg_aln  := sa_para;
      seg_comb := SC_PRIVATE;
      seg_cls  := '';
      While LexPeekKind = TK_IDENT Do
      Begin
        LexNext;
        tok2 := lex_tok.val;
        i := 1;
        While (i <= SS_COUNT) And (SS_NAMES[i] <> tok2) Do Inc(i);
        Case i Of
          SS_BYTE   : seg_aln  := sa_byte;
          SS_WORD   : seg_aln  := sa_word;
          SS_DWORD  : seg_aln  := sa_dword;
          SS_PARA   : seg_aln  := sa_para;
          SS_PAGE   : seg_aln  := sa_page;
          SS_PUBLIC : seg_comb := sc_public;
          SS_COMMON : seg_comb := sc_common;
          SS_STACK  : seg_comb := sc_stack;
          SS_MEMORY : seg_comb := sc_common;
          SS_AT     : If LexPeekKind = TK_NUMBER Then LexNext; { adresse AT }
        End;
      End;
      { classe entre apostrophes }
      If (LexPeekKind = TK_PUNCT) And (LexPeekVal = '''') Then
      Begin
        LexNext;
        If LexPeekKind = TK_IDENT Then Begin LexNext; seg_cls := lex_tok.val; End;
        If (LexPeekKind = TK_PUNCT) And (LexPeekVal = '''') Then LexNext;
      End
      Else If LexPeekKind = TK_STRING Then
      Begin
        LexNext; seg_cls := lex_tok.val;
      End;
      ParseSegment(label_name, seg_aln, seg_comb, seg_cls);
      Exit;
    End;

    MN_GROUP : Begin
      If label_name <> '' Then ParseGroup(label_name)
      Else ErrorMsg('GROUP sans nom de groupe');
      Exit;
    End;

    MN_ASSUME : Begin
      While LexPeekKind = TK_IDENT Do
      Begin
        LexNext; rn := lex_tok.val;
        If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ':') Then LexNext;
        If LexPeekKind = TK_IDENT Then Begin LexNext; sn := lex_tok.val; End
        Else sn := '';
        ParseAssume(rn, sn);
        If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ',') Then LexNext
        Else Break;
      End;
      Exit;
    End;

    MN_INCLUDE : Begin
      { lire le nom de fichier : tout le reste de la ligne }
      While (lex_pos <= Length(lex_line)) And (lex_line[lex_pos] = ' ') Do
        Inc(lex_pos);
      inc_name := '';
      While (lex_pos <= Length(lex_line)) And (lex_line[lex_pos] <> ' ') Do
      Begin
        inc_name := inc_name + lex_line[lex_pos];
        Inc(lex_pos);
      End;
      If inc_name <> '' Then SrcPush(inc_name);
      Exit;
    End;

    MN_INCLUDELIB : Begin
      While (lex_pos <= Length(lex_line)) And (lex_line[lex_pos] = ' ') Do
        Inc(lex_pos);
      lib_name := '';
      While lex_pos <= Length(lex_line) Do
      Begin
        lib_name := lib_name + lex_line[lex_pos];
        Inc(lex_pos);
      End;
      { Emit COMENT $A3 (library specifier) }
      If (lib_name <> '') And obj_is_open Then
        ObjCOMENT($80, $A3, lib_name);
      Exit;
    End;

    MN_NAME : Begin
      If LexPeekKind = TK_IDENT Then Begin LexNext; { ignore } End;
      Exit;
    End;

    MN_DOTMODEL : Begin
      If LexPeekKind = TK_IDENT Then Begin LexNext; ParseModel(lex_tok.val); End;
      Exit;
    End;

    MN_DOTCODE : Begin
      seg_nm := '';
      If LexPeekKind = TK_IDENT Then Begin LexNext; seg_nm := lex_tok.val; End;
      ParseDotCode(seg_nm);
      Exit;
    End;

    MN_DOTDATA, MN_DOTDATAQ, MN_DOTCONST : Begin
      ParseDotData(mnem);
      Exit;
    End;

    MN_DOTSTACK : Begin
      stk_sz := 512;
      If LexPeekKind = TK_NUMBER Then Begin LexNext; stk_sz := lex_tok.num_val; End;
      ParseDotStack(TWord(stk_sz));
      Exit;
    End;

    MN_DOTRADIX : Begin
      { pour l instant ignorer : lex_radix non implemente }
      If LexPeekKind = TK_NUMBER Then LexNext;
      Exit;
    End;

    MN_PUBLIC   : Begin ParsePublic;  Exit; End;
    MN_EXTRN,
    MN_EXTERN   : Begin ParseExtrn;   Exit; End;
    MN_GLOBAL   : Begin ParseGlobal;  Exit; End;
    MN_COMM     : Begin ParseComm;    Exit; End;
    MN_ORG      : Begin ParseOrg;     Exit; End;
    MN_ALIGN    : Begin ParseAlign;   Exit; End;
    MN_EVEN     : Begin ParseEven;    Exit; End;

    MN_LIST,
    MN_LISTALL  : Begin lst_active := True;  Exit; End;
    MN_NOLIST,
    MN_XLIST    : Begin lst_active := False; Exit; End;

    MN_PAGE : Begin
      { PAGE [lines[,cols]] }
      If LexPeekKind = TK_NUMBER Then
      Begin
        LexNext; lst_page_lines := lex_tok.num_val;
        If (LexPeekKind = TK_PUNCT) And (LexPeekVal = ',') Then
        Begin
          LexNext;
          If LexPeekKind = TK_NUMBER Then
          Begin LexNext; lst_page_cols := lex_tok.num_val; End;
        End;
      End
      Else
      Begin
        { PAGE sans argument = saut de page }
        If lst_is_open And lst_active Then
        Begin
          Writeln(lst_file, #12);
          Inc(lst_page_num);
          lst_line_on_page := 0;
        End;
      End;
      Exit;
    End;

    MN_TITLE : Begin
      lst_title := '';
      While (lex_pos <= Length(lex_line)) And (lex_line[lex_pos] = ' ') Do Inc(lex_pos);
      While lex_pos <= Length(lex_line) Do
      Begin lst_title := lst_title + lex_line[lex_pos]; Inc(lex_pos); End;
      Exit;
    End;

    MN_SUBTTL : Begin
      lst_subttl := '';
      While (lex_pos <= Length(lex_line)) And (lex_line[lex_pos] = ' ') Do Inc(lex_pos);
      While lex_pos <= Length(lex_line) Do
      Begin lst_subttl := lst_subttl + lex_line[lex_pos]; Inc(lex_pos); End;
      Exit;
    End;

    { CPU target, DOSSEG, OPTION -- ignorer le reste de la ligne }
    MN_DOT8086, MN_DOT8087,  MN_DOT186,
    MN_DOT286,  MN_DOT286C,  MN_DOT286P,
    MN_DOT386,  MN_DOT386P,  MN_DOTDOSSEG,
    MN_OPTION : Begin
      While (LexPeekKind <> TK_NEWLINE) And (LexPeekKind <> TK_EOF) Do LexNext;
      Exit;
    End;

    MN_ENTER    : Begin ParseEnter;   Exit; End;
    MN_LEAVE    : Begin ParseLeave;   Exit; End;
    MN_INVOKE   : Begin ParseInvoke;  Exit; End;

  End; { Case dir_idx }

  { --- instructions machine : passer aux encodeurs --- }
  If ParseInstr(mnem) Then Exit;

  { --- expansion macro --- }
  mi := MacroFind(mnem);
  If mi <> Nil Then
  Begin
    { le reste de la ligne = arguments }
    rest := '';
    If lex_pos <= Length(lex_line) Then
      rest := Copy(lex_line, lex_pos, Length(lex_line) - lex_pos + 1);
    ExpandMacro(mi, rest);
    Exit;
  End;

  { --- verification structure comme instanciation --- }
  si := StructFind(mnem);
  If si > 0 Then
  Begin
    ParseStructInstance(si, label_name);
    Exit;
  End;

  { --- directive END [label] : fin du module source --- }
  If mnem = 'END' Then
  Begin
    If LexPeekKind = TK_IDENT Then
    Begin
      LexNext;
      If pass_num = 2 Then
      Begin
        { chercher le symbole du point d entree }
        p_entry := SymFind(lex_tok.val);
        If p_entry <> Nil Then
        Begin
          has_entry := True;
          entry_seg := p_entry^.seg_idx;
          entry_off := p_entry^.offset;
        End
        Else
          WarnMsg('Point d entree non defini : ' + lex_tok.val);
      End;
    End;
    asm_end_seen := True;
    Exit;
  End;

  { instruction inconnue }
  If pass_num = 2 Then
    WarnMsg('Directive ou mnemonic inconnu : ' + mnem);
End;

{ ============================================================
  ResetPassState : remettre a zero les LCs et l etat
  d emission entre les deux passes.
  ============================================================ }
Procedure ResetPassState;
Var
  i : Integer;
Begin
  lc      := 0;
  cur_seg := 0;
  { remettre les LC de chaque segment a 0 }
  For i := 1 To seg_count Do
  Begin
    seg_table[i].cur_lc := 0;
    seg_table[i].size   := 0;
  End;
  { vider le buffer LEDATA }
  ledata_buf_len := 0;
  ledata_start   := 0;
  { reinitialiser les piles conditionnelles et proc }
  IfInit;
  ProcInit;
  { reinitialiser l expansion macro }
  macro_exp_cur := Nil;
  { reinitialiser point d entree et fin de source }
  has_entry    := False;
  asm_end_seen := False;
End;

{ ============================================================
  RunPass : executer une passe complete d assemblage.
  En passe 1 : no_emit = True (avance LC sans ecrire).
  En passe 2 : no_emit = False (emet les octets).
  ============================================================ }
Procedure RunPass(pass : Integer);
Begin
  pass_num     := pass;
  no_emit      := (pass = 1);
  ledata_start := 0;
  cur_lineno   := 0;

  { lire et assembler chaque ligne }
  While GetNextLine Do
  Begin
    { sauvegarder LC et segment avant l assemblage (pour le listing) }
    If do_listing And lst_active And (pass = 2) Then
    Begin
      lst_line_start_lc  := lc;
      lst_line_start_seg := cur_seg;
      lst_nbytes         := 0;
    End;

    AssembleLine;
    If asm_end_seen Then Break;  { END directive rencontree }

    { ecrire la ligne dans le listing (passe 2 uniquement) }
    If do_listing And lst_active And (pass = 2) And lst_is_open Then
      LstEmitLine(cur_lineno, lst_line_start_lc,
                  lst_line_start_seg, lst_nbytes, cur_line);
  End;

  { fermer tout segment ouvert }
  If cur_seg > 0 Then
  Begin
    FlushLEDATA;
    cur_seg := 0;
  End;
End;

{ ============================================================
  Assemble : orchestrer les deux passes et ecrire le .OBJ.
  fname    = nom du fichier source
  out_name = nom du fichier .OBJ cible
  ============================================================ }
Procedure Assemble(Const fname : TString; Const out_name : TString);
Var
  t1h, t1m, t1s, t1c : Word;
  t2h, t2m, t2s, t2c : Word;
  elapsed_cs, elapsed_s, elapsed_ds : LongInt;
  total_bytes : LongInt;
  i : Integer;
  coment_str : TString;
Begin
  GetTime(t1h, t1m, t1s, t1c);
  If Not silent_mode Then
    Writeln('Assemblage: ', fname);

  { === PASSE 1 : construction de la table des symboles === }
  If Not silent_mode Then
    Writeln('Passe 1...');
  textequ_count := 0;
  InitPredefDateTimeFilename(fname);
  ResetPassState;
  SrcPush(fname);
  If SrcAtEnd Then
  Begin
    ErrorMsg('Impossible d ouvrir le source : ' + fname);
    Exit;
  End;
  RunPass(1);

  If err_count > 0 Then
  Begin
    Writeln(err_count, ' erreur(s) en passe 1 - arret.');
    Exit;
  End;

  { ---------------------------------------------------------------- }
  { Sauvegarder les tailles de segments (encore valides apres passe 1) }
  total_bytes := 0;
  For i := 1 To seg_count Do
    Inc(total_bytes, LongInt(seg_table[i].size));

  { ---------------------------------------------------------------- }
  { Ecriture des records d en-tete OMF (avec tailles de passe 1)      }
  { Ordre OMF standard : THEADR COMENT LNAMES SEGDEF GRPDEF EXTDEF PUBDEF }
  ObjOpen(out_name);
  ObjTHEADR(fname);
  coment_str := 'Assembled by MASM.PAS ' + VERSION + ' on ' + predef_date;
  ObjCOMENT($88, $00, coment_str);
  WriteAllSegments;   { LNAMES + SEGDEF (tailles passe 1) + GRPDEF }
  EmitAllExtDefs;     { EXTDEF }
  EmitAllPubDefs;     { PUBDEF (offsets connus depuis passe 1) }

  { === PASSE 2 : emission du code + listing === }
  If Not silent_mode Then
    Writeln('Passe 2...');
  ResetPassState;

  { ouvrir le listing avant RunPass pour capturer toutes les lignes }
  If do_listing And (lst_fname <> '') Then
    LstOpen(lst_fname);

  SrcPush(fname);
  RunPass(2);         { LEDATA + FIXUPP }

  FlushLEDATA;
  ObjMODEND(has_entry, entry_seg, entry_off);
  ObjClose;

  { sections de fin de listing }
  If do_listing And lst_is_open Then
  Begin
    If lst_sym_table Then
    Begin
      LstEmitSymTable;
      LstEmitMacroTable;
    End;
    LstEmitStats(cur_lineno);
    LstClose;
  End;

  { ---------------------------------------------------------------- }
  { Rapport final                                                    }
  GetTime(t2h, t2m, t2s, t2c);
  elapsed_cs := LongInt(t2h)*360000 + LongInt(t2m)*6000
              + LongInt(t2s)*100    + LongInt(t2c)
              - LongInt(t1h)*360000 - LongInt(t1m)*6000
              - LongInt(t1s)*100    - LongInt(t1c);
  If elapsed_cs < 0 Then
    Inc(elapsed_cs, 8640000);   { passage de minuit }
  elapsed_s  := elapsed_cs Div 100;
  elapsed_ds := (elapsed_cs Mod 100) Div 10;

  Writeln(cur_lineno,   ' lignes, ',
          sym_count,    ' symboles, ',
          total_bytes,  ' octets, ',
          err_count,    ' erreur(s), ',
          warn_count,   ' avertissement(s).',
          '  [', elapsed_s, '.', elapsed_ds, 's]');
End;

{ ============================================================
  TRAITEMENT DE LA LIGNE DE COMMANDE ET OPTIONS
  ============================================================ }

{ ChangeExt : remplace (ou ajoute) l extension d un nom de fichier }
Function ChangeExt(Const fname : TString; Const ext : TString) : TString;
Var
  i    : Integer;
  base : TString;
Begin
  base := fname;
  i    := Length(base);
  While i > 0 Do
  Begin
    If (base[i] = '\') Or (base[i] = '/') Or (base[i] = ':') Then
    Begin
      { separateur de repertoire atteint sans trouver de '.' : pas d extension }
      ChangeExt := base + ext;
      Exit;
    End;
    If base[i] = '.' Then
    Begin
      ChangeExt := Copy(base, 1, i-1) + ext;
      Exit;
    End;
    Dec(i);
  End;
  { pas de '.' du tout }
  ChangeExt := base + ext;
End;

{ UpStrCLI : convertir une chaine en majuscules (usage ligne de commande) }
Function UpStrCLI(Const s : TString) : TString;
Var k : Integer; r : TString;
Begin
  r := s;
  For k := 1 To Length(r) Do r[k] := UpCase(r[k]);
  UpStrCLI := r;
End;

{ ShowUsage : afficher l aide et terminer }
Procedure ShowUsage;Begin
  Writeln('Syntaxe: MASM [options] source[.ASM] [obj[.OBJ] [lst[.LST] [crf[.CRF]]]]');
  {$IFDEF FPC}
  Writeln('Options:');
  Writeln(' /A        Trier segments alphabetiquement');
  Writeln(' /B n      Taille buffer source (ignore)');
  Writeln(' /C        Generer .CRF cross-reference (non implemente)');
  Writeln(' /D        Double-passe (toujours actif, rien a faire)');
  Writeln(' /L        Generer fichier listing .LST');
  Writeln(' /ML       Labels sensibles a la casse');
  Writeln(' /MU       Convertir labels en majuscules (defaut)');
  Writeln(' /MX       Publics/externes sensibles a la casse');
  Writeln(' /N        Omettre tables de symboles du listing');
  Writeln(' /S        Segments en ordre de definition (defaut)');
  Writeln(' /T        Mode silencieux');
  Writeln(' /W0 /W1 /W2  Niveau d''avertissement (0=aucun, 2=tout)');
  Writeln(' /X        Lister blocs conditionnels inactifs');
  Writeln(' /Z        Afficher la ligne source avec chaque erreur');
  Writeln(' /Zi /Zd   Infos debug CodeView (non implemente)');
  Writeln(' /I chem   Ajouter repertoire de recherche INCLUDE');
  Writeln(' /Dsym[=val]  Definir un symbole sur la ligne de commande');
  Writeln(' /?        Afficher cette aide');
  {$ENDIF}
  Halt(1);
End;

{ ParseArgs : analyser ParamStr(1..ParamCount) }
Const PA_QM=1; PA_H=2; PA_HELP=3; PA_A=4; PA_B=5; PA_C=6; PA_D=7; PA_L=8;
      PA_ML=9; PA_MU=10; PA_MX=11; PA_N=12; PA_S=13; PA_T=14;
      PA_W0=15; PA_W1=16; PA_W2=17; PA_X=18; PA_Z=19; PA_ZI=20; PA_ZD=21;
      PA_COUNT=21;
      PA_NAMES: Array[1..21] Of String[5] = (
        '?','H','HELP','A','B','C','D','L',
        'ML','MU','MX','N','S','T',
        'W0','W1','W2','X','Z','ZI','ZD'
      );

Procedure ParseArgs;
Var
  i, j, eq, code, nval, pa_idx : Integer;
  arg, uopt, sym, val, dirpath : TString;
  pos_count : Integer;
  si : PSymbol;
Begin
  pos_count := 0;
  i := 1;
  While i <= ParamCount Do
  Begin
    arg  := ParamStr(i);
    If Length(arg) = 0 Then Begin Inc(i); Continue; End;
    If (arg[1] = '/') Or (arg[1] = '-') Then
    Begin
      uopt := UpStrCLI(Copy(arg, 2, 255));
      { --- lookup exact dans PA_NAMES --- }
      pa_idx := 0;
      For j := 1 To PA_COUNT Do
        If PA_NAMES[j] = uopt Then Begin pa_idx := j; Break; End;
      If pa_idx > 0 Then
      Begin
        Case pa_idx Of
          PA_QM, PA_H, PA_HELP : ShowUsage;
          PA_A  : seg_alpha := True;
          PA_B  : { /B n : le nombre est dans le parametre suivant }
                  If i < ParamCount Then
                  Begin
                    val := ParamStr(i+1);
                    If (Length(val) > 0) And (val[1] >= '0') And (val[1] <= '9') Then
                      Inc(i);
                  End;
          PA_C  : do_crf := True;
          PA_D  : ;{ /D seul : double-pass, rien a faire }
          PA_L  : do_listing := True;
          PA_ML : case_sensitive := True;
          PA_MU : case_sensitive := False;
          PA_MX : case_public_ext := True;
          PA_N  : lst_sym_table := False;
          PA_S  : seg_alpha := False;
          PA_T  : silent_mode := True;
          PA_W0 : warn_level := 0;
          PA_W1 : warn_level := 1;
          PA_W2 : warn_level := 2;
          PA_X  : list_cond := True;
          PA_Z  : show_err_lines := True;
          PA_ZI, PA_ZD : ;{ /Zi /Zd : CodeView debug, ignore }
        End;
      End
      { --- /Dsym[=val] : definir un symbole --- }
      Else If (Length(uopt) >= 2) And (uopt[1] = 'D') Then
      Begin
        sym := Copy(arg, 3, 255);   { conserver la casse originale }
        val := '1';
        eq  := Pos('=', sym);
        If eq > 0 Then
        Begin
          val := Copy(sym, eq+1, 255);
          sym := Copy(sym, 1,  eq-1);
        End;
        If sym <> '' Then
        Begin
          si := SymFind(sym);
          If si = Nil Then
            si := SymEnter(sym, SK_EQU, 0, 0, 2);
          si^.kind    := SK_EQU;
          si^.seg_idx := 0;
          { convertir val en entier (base 10) }
          nval := 0; code := 0;
          For eq := 1 To Length(val) Do
          Begin
            If (val[eq] >= '0') And (val[eq] <= '9') Then
              nval := nval * 10 + (Ord(val[eq]) - 48)
            Else Begin code := -1; Break; End;
          End;
          If code = 0 Then si^.value := nval
          Else             si^.value := 1;
        End;
      End
      { --- /Bn : taille buffer avec chiffre colle, ignore --- }
      Else If (Length(uopt) >= 2) And (uopt[1] = 'B') And
              (uopt[2] >= '0') And (uopt[2] <= '9') Then
        { /Bn : ignorer le chiffre colle }
      { --- /I[chem] ou /I chem : repertoire INCLUDE --- }
      Else If (Length(uopt) >= 1) And (uopt[1] = 'I') Then
      Begin
        If Length(uopt) > 1 Then
          dirpath := Copy(arg, 3, 255)   { /Ipath : chemin colle }
        Else
        Begin
          { /I path : chemin dans l argument suivant }
          Inc(i);
          If i > ParamCount Then
          Begin
            Writeln('Erreur: /I sans chemin');
            Halt(1);
          End;
          dirpath := ParamStr(i);
        End;
        If inc_dir_cnt < 16 Then
        Begin
          inc_dirs[inc_dir_cnt] := dirpath;
          Inc(inc_dir_cnt);
        End
        Else
          Writeln('Avertissement: trop de repertoires /I (max 16), ignore: ', dirpath);
      End
      Else
        Writeln('Avertissement: option inconnue ignoree: ', arg);
    End
    Else
    Begin
      { Argument positionnel : source obj lst crf }
      Case pos_count Of
        0:  { source.ASM }
        Begin
          src_fname := arg;
          If Pos('.', arg) = 0 Then
            src_fname := arg + '.ASM';
          Inc(pos_count);
        End;
        1:  { obj.OBJ }
        Begin
          obj_fname := arg;
          If Pos('.', arg) = 0 Then
            obj_fname := arg + '.OBJ';
          Inc(pos_count);
        End;
        2:  { lst.LST  (NUL = pas de listing) }
        Begin
          If (UpStrCLI(arg) = 'NUL') Or (UpStrCLI(arg) = 'NUL.LST') Then
            lst_fname := ''
          Else
          Begin
            lst_fname := arg;
            If Pos('.', arg) = 0 Then
              lst_fname := arg + '.LST';
            do_listing := True;
          End;
          Inc(pos_count);
        End;
        3:  { crf.CRF : accepte et ignore }
        Begin
          crf_fname := arg;
          Inc(pos_count);
        End;
      End;
    End;
    Inc(i);
  End;

  { Source obligatoire }
  If src_fname = '' Then
  Begin
    Writeln('Macro Assembler Version ', VERSION, ' compatible MASM 5.x');
    ShowUsage;
    Exit;
  End;

  { Deriver obj_fname depuis src_fname si non fourni }
  If obj_fname = '' Then
    obj_fname := ChangeExt(src_fname, '.OBJ');

  { Deriver lst_fname si listing demande et nom non fourni }
  If do_listing And (lst_fname = '') Then
    lst_fname := ChangeExt(src_fname, '.LST');
End;

{ ============================================================
  Programme principal
  ============================================================ }
BEGIN
 InitTables;
 ObjInit;
 FixupInit;
 ModelInit;
 VisInit;
 StructInit;
 MacroInit;
 IfInit;
 ProcInit;
 SrcInit;
 LexInit;
 SymInit;
 local_unique_id := 0;
 no_emit         := False;
  { Analyser la ligne de commande (TODO 24) }
 ParseArgs;
 {$IFDEF FPC}
 If Not silent_mode Then
   Writeln('Macro Assembler Version ', VERSION, ' compatible MASM 5.x');
 {$ENDIF}
  { Assembler }
 Assemble(src_fname, obj_fname);
 If err_count > 0 Then Halt(1)
                  Else Halt(0);
END.
