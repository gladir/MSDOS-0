{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program SORT(Input,Output);

Uses Dos;

Type
 StrPointer=^String;

Var
 Option:Set Of (_Reverse,_NmCol);
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 I,J,_Index,Nm,Err:Word;
 P:StrPointer;
 S:String;
 PA:Array[1..12000] of StrPointer;
 F:Text;

Function StrToUpper(S:String):String;
Var
 I:Byte; { Compteur de boucle attribue a la chaine de caracteres }
Begin
 For I:=1to Length(S)do S[I]:=UpCase(S[I]);
 StrToUpper:=S;
End;

Procedure QuickSort(Left,Right:Word);
Var
 Lower,Upper,Middle:Word;
 Pivot,T:String;
 Temp:StrPointer;
Begin
 Lower:=Left;
 Upper:=Right;
 Middle:=(Left+Right) shr 1;
 If(_NmCol in Option)Then Begin
  Pivot:=Copy(PA[Middle]^,Nm,255);
 End
  Else
 Pivot:=PA[Middle]^;
 Repeat
  If(_NmCol in Option)Then Begin
   While Copy(PA[Lower]^,Nm,255) < Pivot do Inc(Lower);
   While Pivot < Copy(PA[Upper]^,Nm,255) do Dec(Upper);
  End
   Else
  Begin
   While PA[Lower]^ < Pivot do Inc(Lower);
   While Pivot < PA[Upper]^ do Dec(Upper);
  End;
  If(Lower<=Upper)Then Begin
   Temp:=PA[Lower];
   PA[Lower]:=PA[Upper];
   PA[Upper]:=Temp;
   Inc(Lower);
   Dec(Upper);
  End;
 Until Lower>Upper;
 If Left<Upper Then QuickSort(Left,Upper);
 If Lower<Right Then QuickSort(Lower,Right);
End;

Procedure QuickSortReverse(Left,Right:Word);
Var
 Lower,Upper,Middle:Word;
 Pivot,T:String;
 Temp:StrPointer;
Begin
 Lower:=Left;
 Upper:=Right;
 Middle:=(Left+Right) shr 1;
 If(_NmCol in Option)Then Begin
  Pivot:=Copy(PA[Middle]^,Nm,255);
 End
  Else
 Pivot:=PA[Middle]^;
 Repeat
  If(_NmCol in Option)Then Begin
   While (Copy(PA[Lower]^,Nm,255) > Pivot) do Inc(Lower);
   While (Pivot > Copy(PA[Upper]^,Nm,255)) do Dec(Upper);
  End
   Else
  Begin
   While (PA[Lower]^ > Pivot) do Inc(Lower);
   While (Pivot > PA[Upper]^) do Dec(Upper);
  End;
  If(Lower<=Upper)Then Begin
   Temp:=PA[Lower];
   PA[Lower]:=PA[Upper];
   PA[Upper]:=Temp;
   Inc(Lower);
   Dec(Upper);
  End;
 Until(Lower>Upper);
 If(Left<Upper)Then QuickSortReverse(Left,Upper);
 If(Lower<Right)Then QuickSortReverse(Lower,Right);
End;

BEGIN
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
   _Germany:Begin
    WriteLn('Gibt die Eingabe sortiert auf Bildschirm, Datei oder anderes GerÑt aus.');
    WriteLn;
    WriteLn('SORT [/R] [Laufwerk1:][Pfad1]Datename1');
    WriteLn;
    WriteLn('[Laufwerk1:][Pfad1]Datename1 Datei, die sortiert werden soll.');
    WriteLn('/+n                          Sortiert die Eingabe nach den Zeichen ab Spalte n.');
    WriteLn('/R                           Dreht die Sortierreihenfolge um (von Z nach A, von 9 nach 0).');
   End;
   _English:Begin
    WriteLn('Sorts input and writes results to the screen, a file, or another device.');
    WriteLn;
    WriteLn('SORT [/R] [/+n] [drive1:][path1]filename1');
    WriteLn;
    WriteLn('[drive1:][path1]filename1  Specifies file(s) to be sorted');
    WriteLn('/+n                        Sorts the file according to characters in column n.');
    WriteLn('/R                         Reverses the sort order; this is, sorts Z to A, ');
    WriteLn('                           then 9 to 0.');
   End;
   Else Begin
    WriteLn('SORT : Cette commande permet de trier un fichier texte ASCII.');
    WriteLn;
    WriteLn('Syntaxe : SORT [/R] fichier');
    WriteLn;
    WriteLn('fichier  Indique le fichier Ö trier.');
    WriteLn('/+n      Trie l''entrÇe par les caractäres de la colonne n.');
    WriteLn('/R       Tri dans le sens inverse');
   End;
  End;
 End
  Else
 If ParamCount>=1Then Begin
  Nm:=1;
  Option:=[];
  For J:=1 to ParamCount do Begin
   If Copy(ParamStr(J),1,2)='/+'Then Begin
    Include(Option,_NmCol);
    Val(Copy(ParamStr(J),3,255),Nm,Err);
    If Err>0 Then Begin
     WriteLn('Nombre invalide dans le paramätre /+');
     Halt;
    End;
   End
    Else
   If StrToUpper(ParamStr(J))='/R'Then Include(Option,_Reverse);
  End;
  For J:=1 to ParamCount do Begin
   If Copy(ParamStr(J),1,2)='/+'Then Begin
   End
    Else
   If StrToUpper(ParamStr(J))<>'/R'Then Begin
    {$I+}Assign(F,ParamStr(J));
    Reset(F);{$I-}
    _Index:=0;
    While Not EOF(F) do Begin
     ReadLn(F,S);
     Inc(_Index);
     GetMem(P,Length(S)+1);
     P^:=S;
     PA[_Index]:=P;
    End;
    Close(F);
    If _Index>1 Then Begin
     If _Reverse in Option Then QuickSortReverse(1,_Index)
                           Else QuickSort(1,_Index);
    End;
    For I:=1 to _Index do WriteLn(PA[I]^);
   End;
  End;
 End
  Else
 Begin
  _Index:=0;
  While Not EOF do Begin
   ReadLn(Input,S);
   Inc(_Index);
   GetMem(P,Length(S)+1);
   P^:=S;
   PA[_Index]:=P;
  End;
  If _Index>1 Then QuickSort(1,_Index);
  For I:=1 to _Index do WriteLn(PA[I]^);
 End;
END.
