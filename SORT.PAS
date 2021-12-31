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
 I,_Index:Word;
 P:StrPointer;
 S:String;
 PA:Array[1..12000] of StrPointer;
 F:Text;

Procedure QuickSort(Left,Right:Word);
Var
 Lower,Upper,Middle:Word;
 Pivot,T:String;
 Temp:StrPointer;
Begin
 Lower:=Left;
 Upper:=Right;
 Middle:=(Left+Right) shr 1;
 Pivot:=PA[Middle]^;
 Repeat
  While PA[Lower]^ < Pivot do Inc(Lower);
  While Pivot < PA[Upper]^ do Dec(Upper);
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


BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('SORT : Cette commande permet de trier un fichier texte ASCII.');
  WriteLn;
  WriteLn('Syntaxe : SORT fichier');
 End
  Else
 If ParamCount>=1Then Begin
  Assign(F,ParamStr(1));
  Reset(F);
  _Index:=0;
  While Not EOF(F) do Begin
   ReadLn(F,S);
   Inc(_Index);
   GetMem(P,Length(S)+1);
   P^:=S;
   PA[_Index]:=P;
  End;
  Close(F);
  If _Index>1 Then QuickSort(1,_Index);
  For I:=1 to _Index do WriteLn(PA[I]^);
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