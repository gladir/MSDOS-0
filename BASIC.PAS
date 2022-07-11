{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program BASIC;

Uses Crt,DOS,Printer;

Const
 CommandList:Array[0..91]of String[12]=(
  'AND','AUTO','BEEP','BLOAD','BSAVE','CALL','CAT','CHAIN','CHDIR',
  'CIRCLE','CLEAR','CLOSE','CLR','CLS','COLOR','COM','COMMON','CONT',
  'DATA','DEF','DELETE','DIM','DRAW','EDIT','ELSE','END','ERASE','ERROR',
  'FIELD','FILES','FOR','GET','GOSUB','GOTO','HELP','IF','INPUT','KEY',
  'KILL','LET','LINE','LIST','LLIST','LOAD','LOCATE','LPRINT',
  'LSET','MERGE','MKDIR','NAME','NEW','NEXT','ON','OPEN','OPTION',
  'OR','OUT','PAINT','PALETTE','POKE','PLAY','PRESET','PRINT',
  'PSET','PUT','RANDOMIZE','READ','REM','RENUM','RESET','RESUME',
  'RESTORE','RETURN','RMDIR','RSET','RUN','SAVE','SCREEN','SHELL','SLEEP',
  'STOP','SYSTEM','THEN','TROFF','TRON','VIEW','WAIT','WEND','WHILE',
  'WIDTH','WINDOW','WRITE'
 );

 FunctionList:Array[0..53]of String[12]=(
  'ABS','ASC','ATN','CHR$','CINT','CSNG','CSRLIN','COS','CVD','CVI',
  'CVS','DATE$','EOF','ERL','ERR','EXP','FIX','FRE','INKEY$','INP',
  'INPUT$','INSTR','INT','LEFT$','LEN','LOF','LOG','LPOS','LTRIM$',
  'MID$','OCT$','PEEK','PLAY','PMAP','POS','RIGHT$','RND','RTRIM$',
  'SCREEN','SGN','SIN','SQR','STR$','STRIG','STRING$','TAN','TAB',
  'TIME$','TIMER','TRIM$','USR','VAL','VARPTR','VARPTR$'
 );

 MaxLine=1024;
 MaxVariable=100;

Type
 VarTypeEnum=(_None,_Integer,_LongInt,_Real,_String);
 StrPointer=^String;
 VarRec=Record
  Variant:Record Case Integer of
   0:(I:Integer);
   1:(L:LongInt);
   2:(R:Real);
   3:(S:StrPointer);
  End;
  VarType:VarTypeEnum;
  VarName:String[20];
 End;
 VarPointer=^VarRec;

Var
 Terminated,Tron:Boolean;
 CurrCommand:String;
 FileName,CurrLine:String;
 CurrPos:Byte;
 PA:Array[1..MaxLine] of StrPointer;
 CurrLinePtr,NumberLine:Integer;
 CurrNumberLine:Integer;
 VarList:Array[1..MaxVariable]of VarPointer;
 I,NumberVariable:Integer;

Function RunBasic(InList:Boolean):Boolean;Forward;
Procedure NewCommand;Forward;

Function TAN(X:Real):Real;Begin
 If Cos(X)=0.0Then Tan:=0.0
              Else Tan:=SIN(X)/COS(X);
End;

Function LTrim(S:String):String;
Var
 I:Integer;
Begin
 I:=1;
 While(I<=Length(s)) and (S[I] in [#9,' ']) do Inc(I);
 Delete(S,1,I-1);
 LTrim:=S;
End;

Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
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

Function GetCurrentDisk:Char;
Var
 CurrentDir:String;
Begin
 GetDir(0,CurrentDir);
 GetCurrentDisk:=CurrentDir[1];
End;

Function GetErrorMessage(Code:Word):String;Begin
 Case Code of
  0:GetErrorMessage:='';
  2:GetErrorMessage:='Fichier introuvable';
  3:GetErrorMessage:='Chemin introuvable';
  4:GetErrorMessage:='Trop de fichiers ouvert';
  5:GetErrorMessage:='Acces refuse';
  6:GetErrorMessage:='Handle de fichier invalide';
  12:GetErrorMessage:='Mode d''acces sur disque invalide';
  15:GetErrorMessage:='Num‚ro de disque invalide';
  16:GetErrorMessage:='Impossible de supprimer le r‚pertoire';
  17:GetErrorMessage:='Impossible de renommer sur plusieurs volumes';
  100:GetErrorMessage:='Erreur de lecture … partir du disque';
  101:GetErrorMessage:='Erreur d''ecriture sur le disque';
  102:GetErrorMessage:='Fichier non attribue';
  103:GetErrorMessage:='Le fichier n''est pas ouvert';
  104:GetErrorMessage:='Le fichier n''est pas ouvert … l''entree';
  105:GetErrorMessage:='Le fichier n''est pas ouvert … la sortie';
  106:GetErrorMessage:='Numero invalide';
  150:GetErrorMessage:='Disque protege en ecriture';
  151:GetErrorMessage:='Peripherique est inconnu';
  152:GetErrorMessage:='Disque pas pret';
  153:GetErrorMessage:='Commande inconnue';
  154:GetErrorMessage:='Echec de verification CRC';
  155:GetErrorMessage:='Disque invalide';
  156:GetErrorMessage:='Erreur de recherche sur disque';
  157:GetErrorMessage:='Type de media invalide';
  158:GetErrorMessage:='Secteur introuvable';
  159:GetErrorMessage:='L''imprimante n''a plus de papier';
  160:GetErrorMessage:='Erreur d''ecriture sur le peripherique';
  161:GetErrorMessage:='Erreur de lecture sur le peripherique';
  162:GetErrorMessage:='Defaillance materielle';
  Else GetErrorMessage:='Erreur inconnue';
 End;
End;

Procedure HomeMessage;Begin
 ClrScr;
 WriteLn('Corail BASIC 2022 tous droits reserves Gladir.com');
End;

Function ExtractCommand:Byte;
Var
 I:Byte;
Begin
 ExtractCommand:=255;
 CurrCommand:='';
 For I:=CurrPos to Length(CurrLine)do Begin
  If Not(CurrLine[I]in['A'..'Z','a'..'z','$','%','!','#'])Then Begin
   CurrCommand:=StrToUpper(Copy(CurrLine,CurrPos,I-CurrPos));
   CurrPos:=I;
   Break;
  End;
 End;
 If CurrCommand=''Then Begin
  CurrCommand:=StrToUpper(Copy(CurrLine,CurrPos,255));
  CurrPos:=Length(CurrLine)+1;
 End;
 For I:=Low(CommandList)to High(CommandList)do Begin
  If CurrCommand=CommandList[I]Then Begin
   ExtractCommand:=I;
   Exit;
  End;
 End;
End;

 { Traitement des variables }
Function VariableExist(S:String):Boolean;
Var
 I:Integer;
Begin
 VariableExist:=False;
 For I:=1 to NumberVariable do If(StrToUpper(S)=VarList[I]^.VarName)Then Begin
  VariableExist:=True;
  Exit;
 End;
End;

Function VariableType(S:String):VarTypeEnum;
Var
 I:Integer;
Begin
 VariableType:=_None;
 For I:=1 to NumberVariable do If(StrToUpper(S)=VarList[I]^.VarName)Then Begin
  VariableType:=VarList[I]^.VarType;
  Exit;
 End;
End;

Function AddVariableInt(S:String;Value:Integer):Boolean;
Var
 P:VarPointer;
Begin
 If NumberVariable>=MaxVariable Then Begin
  AddVariableInt:=False;
  Exit;
 End;
 Inc(NumberVariable);
 GetMem(P,SizeOf(VarRec));
 P^.VarName:=Copy(StrToUpper(S),1,20);
 P^.VarType:=_Integer;
 P^.Variant.I:=Value;
 VarList[NumberVariable]:=P;
 AddVariableInt:=True;
End;

Function GetVariableInt(S:String):Integer;
Var
 I:Integer;
Begin
 GetVariableInt:=0;
 For I:=1 to NumberVariable do If(StrToUpper(S)=VarList[I]^.VarName)Then Begin
  GetVariableInt:=VarList[I]^.Variant.I;
  Exit;
 End;
End;

Procedure SetVariableInt(S:String;Value:Integer);
Var
 I:Integer;
Begin
 For I:=1 to NumberVariable do If(S=VarList[I]^.VarName)Then Begin
  VarList[I]^.Variant.I:=Value;
  Exit;
 End;
End;

Function AddVariableLongInt(S:String;Value:LongInt):Boolean;
Var
 P:VarPointer;
Begin
 If NumberVariable>=MaxVariable Then Begin
  AddVariableLongInt:=False;
  Exit;
 End;
 Inc(NumberVariable);
 GetMem(P,SizeOf(VarRec));
 P^.VarName:=Copy(StrToUpper(S),1,20);
 P^.VarType:=_LongInt;
 P^.Variant.L:=Value;
 VarList[NumberVariable]:=P;
 AddVariableLongInt:=True;
End;

Function GetVariableLongInt(S:String):LongInt;
Var
 I:Integer;
Begin
 GetVariableLongInt:=0;
 For I:=1 to NumberVariable do If(StrToUpper(S)=VarList[I]^.VarName)Then Begin
  GetVariableLongInt:=VarList[I]^.Variant.L;
  Exit;
 End;
End;

Procedure SetVariableLongInt(S:String;Value:LongInt);
Var
 I:Integer;
Begin
 For I:=1 to NumberVariable do If(S=VarList[I]^.VarName)Then Begin
  VarList[I]^.Variant.L:=Value;
  Exit;
 End;
End;

Function AddVariableReal(S:String;Value:Real):Boolean;
Var
 P:VarPointer;
Begin
 If NumberVariable>=MaxVariable Then Begin
  AddVariableReal:=False;
  Exit;
 End;
 Inc(NumberVariable);
 GetMem(P,SizeOf(VarRec));
 P^.VarName:=Copy(StrToUpper(S),1,20);
 P^.VarType:=_Real;
 P^.Variant.R:=Value;
 VarList[NumberVariable]:=P;
 AddVariableReal:=True;
End;

Function GetVariableReal(S:String):Real;
Var
 I:Integer;
Begin
 GetVariableReal:=0;
 For I:=1 to NumberVariable do If(StrToUpper(S)=VarList[I]^.VarName)Then Begin
  GetVariableReal:=VarList[I]^.Variant.R;
  Exit;
 End;
End;

Procedure SetVariableReal(S:String;Value:Real);
Var
 I:Integer;
Begin
 For I:=1 to NumberVariable do If(S=VarList[I]^.VarName)Then Begin
  VarList[I]^.Variant.R:=Value;
  Exit;
 End;
End;


 { Traitement de la liste }
Function AddLine(S:String):Boolean;
Var
 P:StrPointer;
Begin
 If NumberLine>=MaxLine Then Begin
  AddLine:=False;
  Exit;
 End;
 Inc(NumberLine);
 GetMem(P,Length(S)+1);
 P^:=S;
 PA[NumberLine]:=P;
 AddLine:=True;
End;

Function FirstNumberInStr(S:String):Integer;
Var
 J,Number,Err:Integer;
Begin
 FirstNumberInStr:=0;
 J:=1;
 While(J<Length(S))do Begin
  If Not(S[J]in['0'..'9'])Then Begin
   Val(Copy(S,1,J-1),Number,Err);
   FirstNumberInStr:=Number;
   Break;
  End;
  Inc(J);
 End;
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
 Pivot:=PA[Middle]^;
 Repeat
  While FirstNumberInStr(PA[Lower]^) < FirstNumberInStr(Pivot) do Inc(Lower);
  While FirstNumberInStr(Pivot) < FirstNumberInStr(PA[Upper]^) do Dec(Upper);
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

Procedure ResortList;Begin
 If NumberLine>1 Then QuickSort(1,NumberLine);
End;

 { Evaluation d'expression (Infix to PostFix ) }
Var
 Stack:Array[0..100]of Char;
 TopOfStack:Byte;
 resultStack:Array[0..100]of Real;
 TopOfStackInt:Byte;

Procedure StackPushChar(C:Char);Begin
 If TopOfStack>=High(Stack)Then Begin
  WriteLn('Pile pleine!');
  Halt;
 End
  Else
 Begin
  Stack[TopOfStack]:=C;
  Inc(TopOfStack);
 End;
End;

Function StackPop:String;
Var
 S:String;
 Err:Word;
Begin
 Dec(TopOfStack);
 If TopOfStack<1Then Begin
  StackPop:='';
  WriteLn('Pile vide');
  Halt;
 End
  Else
 StackPop:=Stack[TopOfStack];
End;

Function StackPeek:Char;Begin
 StackPeek:=Stack[TopOfStack-1];
End;

Procedure ResultStackPush(C:Real);Begin
 If TopOfStackInt>=High(ResultStack)Then Begin
  WriteLn('Pile pleine!');
  Halt;
 End
  Else
 Begin
  ResultStack[TopOfStackInt]:=C;
  Inc(TopOfStackInt);
 End;
End;

Function ResultStackPop:Real;Begin
 Dec(TopOfStackInt);
 If TopOfStackInt<1Then Begin
  ResultStackPop:=-1.0;
  WriteLn('Pile vide');
  Exit;
 End
  Else
 ResultStackPop:=ResultStack[TopOfStackInt];
End;


Procedure SkipSpace;Begin
 While(CurrLine[CurrPos]in[' '])and(CurrPos<Length(CurrLine))do Inc(CurrPos);
End;

Function GetSeparator:Char;Begin
 If CurrPos>Length(CurrLine)Then Begin
  GetSeparator:=#0;
  Exit;
 End;
 SkipSpace;
 GetSeparator:=CurrLine[CurrPos];
End;

Function GetStringValue:String;
Var
 S:String;
Begin
 GetStringValue:='';
 S:='';
 If CurrLine[CurrPos]='"'Then Begin
  Inc(CurrPos);
  While(CurrLine[CurrPos]<>'"')and(CurrPos<=Length(CurrLine))do Begin
   S:=S+CurrLine[CurrPos];
   Inc(CurrPos);
  End;
  If CurrLine[CurrPos]='"'Then Inc(CurrPos);
  GetStringValue:=S;
 End;
End;

Function GetNumberValue(MinTopOfStack:Integer):Real;
Var
 I,J:Byte;
 Top,P_2:Char;
 AppendOk,FunctionFound:Boolean;
 _Result,P,P2:Real;
 Err:Word;
 PostFix:String;
 VarName,Value:String;
 Exposant:Boolean;
 StopChar:Set Of Char;
 Infix:String;
Begin
 StopChar:=[',',':',';','"','<','=','>'];
 TopOfStack:=1;
 TopOfStackInt:=1;
 PostFix:='';
 Infix:=CurrLine;
 I:=CurrPos;
 If Infix[CurrPos]='-'Then Begin
  Insert('(0)',Infix,CurrPos);
  Dec(CurrPos,3);
 End;
 Repeat
  If Infix[I]in['A'..'Z','a'..'z']Then Begin
   VarName:='';
   While Infix[I]in['A'..'Z','a'..'z','%','!','#']do Begin
    VarName:=VarName+Infix[I];
    Inc(I);
   End;
   VarName:=StrToUpper(VarName);
   If VariableExist(VarName)Then Begin
    Case VariableType(VarName)of
     _Integer:Str(GetVariableInt(VarName),Value);
     _LongInt:Str(GetVariableLongInt(VarName),Value);
     _Real:Str(GetVariableReal(VarName),Value);
     Else Begin
      WriteLn('Type incompatiable');
      Exit;
     End;
    End;
   End
    Else
   Begin { Fonction ?}
    FunctionFound:=False;
    For J:=Low(FunctionList)to High(FunctionList)do Begin
     If FunctionList[J]=VarName Then Begin
      FunctionFound:=True;
      Case J of
       0:Begin{ABS}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        _Result:=GetNumberValue(TopOfStack);
        If Frac(_Result)=0.0 Then Str(Trunc(_Result),Value)
                             Else Str(_Result,Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       1:Begin{ASC}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        Value:=GetStringValue;
        If Length(Value)=0Then _Result:=0.0
                          Else _Result:=Ord(Value[1]);
        Str(_Result:0:0,Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       2:Begin{ATN}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        _Result:=GetNumberValue(TopOfStack);
        Str(ArcTan(_Result),Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       3:Begin{CHR$}
        WriteLn('Type incompatible');
        Exit;
       End;
       4:Begin{CINT}
       End;
       5:Begin{CSNG}
       End;
       6:Begin{CSRLIN}
        Str(WhereY,Value);
       End;
       7:Begin{COS}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        _Result:=GetNumberValue(TopOfStack);
        Str(Cos(_Result),Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       8:Begin{CVD}
       End;
       9:Begin{CVI}
       End;
       10:Begin{CVS}
       End;
       11:Begin{DATE$}
       End;
       12:Begin{EOF}
       End;
       13:Begin{ERL}
       End;
       14:Begin{ERR}
       End;
       15:Begin{EXP}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        _Result:=GetNumberValue(TopOfStack);
        Str(Exp(_Result),Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       16:Begin{FIX}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        _Result:=Trunc(GetNumberValue(TopOfStack));
        Str(_Result:0:0,Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       17:Begin{FRE}
       End;
       18:Begin{INKEY$}
       End;
       19:Begin{INP}
       End;
       20:Begin{INPUT$}
       End;
       21:Begin{INSTR}
       End;
       22:Begin{INT}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        _Result:=Round(GetNumberValue(TopOfStack));
        Str(_Result:0:0,Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       23:Begin{LEFT$}
       End;
       24:Begin{LEN}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        Value:=GetStringValue;
        If Length(Value)=0Then _Result:=0.0
                          Else _Result:=Length(Value);
        Str(_Result:0:0,Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       25:Begin{LOF}
       End;
       26:Begin{LOG}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        _Result:=GetNumberValue(TopOfStack);
        Str(Ln(_Result),Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       27:Begin{LPOS}
       End;
       28:Begin{LTRIM$}
       End;
       29:Begin{MID$}
       End;
       30:Begin{OCT$}
       End;
       31:Begin{PEEK}
       End;
       32:Begin{PLAY}
       End;
       33:Begin{PMAP}
       End;
       34:Begin{POS}
       End;
       35:Begin{RIGHT$}
       End;
       36:Begin{RND}
       End;
       37:Begin{RTRIM$}
       End;
       38:Begin{SCREEN}
       End;
       39:Begin{SGN}
       End;
       40:Begin{SIN}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        _Result:=GetNumberValue(TopOfStack);
        Str(Sin(_Result),Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       41:Begin{SQR}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        _Result:=GetNumberValue(TopOfStack);
        Str(Sqrt(_Result),Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       42:Begin{STR$}
       End;
       43:Begin{STRIG}
       End;
       44:Begin{STRING$}
       End;
       45:Begin{TAN}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        _Result:=GetNumberValue(TopOfStack);
        Str(Tan(_Result),Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       46:Begin{TAB}
       End;
       47:Begin{TIME$}
       End;
       48:Begin{TIMER}
       End;
       49:Begin{TRIM$}
       End;
       50:Begin{USR}
       End;
       51:Begin{VAL}
        If Infix[I]<>'('Then Begin
         WriteLn('"(" attendu');
         Exit;
        End;
        Inc(I);
        CurrPos:=I;
        Value:=GetStringValue;
        Val(Value,_Result,Err);
        Str(_Result,Value);
        I:=CurrPos;
        If Infix[I]<>')'Then Begin
         WriteLn('")" attendu');
         Exit;
        End;
        Inc(I);
       End;
       52:Begin{VARPTR}
       End;
       53:Begin{VARPTR$}
       End;
      End;
      Break;
     End
      Else
     Begin { Variable vide }
      Value:='0';
     End;
    End;
   End;
   PostFix:=PostFix+'('+LTrim(Value)+')';
   If I>Length(Infix)Then Break;
  End
   Else
  If Infix[I]in['0'..'9']Then Begin
   Value:='';
   Exposant:=False;
   Repeat
    If Infix[I]in['E','e']Then Begin
     Exposant:=True;
     Value:=Value+Infix[I];
     Inc(I);
    End
     Else
    If(Exposant)and(Infix[I]in['-','+'])Then Begin
     Value:=Value+Infix[I];
     Inc(I);
    End
     Else
    If Infix[I]in['0'..'9','.']Then Begin
     Value:=Value+Infix[I];
     Inc(I);
    End
     Else
    Break;
   Until I>Length(Infix);
   PostFix:=PostFix+'('+Value+')';
  End
   Else
  If Infix[I]='('Then Begin
   StackPushChar(Infix[I]);
   Inc(I);
  End
   Else
  If Infix[I]in['*','+','-','/']Then Begin
   While(TopOfStack>MinTopOfStack)and(StackPeek <> '(')do Begin
    Top:=StackPeek;
    P_2:=Infix[I];
    AppendOk:=True;
    If(Top='+')and(P_2='*')Then AppendOk:=False
    Else If(Top='*')and(P_2='-')Then AppendOk:=True
    Else If(Top='+')and(P_2='-')Then AppendOk:=True;
    If(AppendOk)Then PostFix:=PostFix+StackPop
                Else Break;
   End;
   StackPushChar(Infix[I]);
   Inc(I);
  End
   Else
  If Infix[I]=')'Then Begin
   If TopOfStack<=MinTopOfStack Then Begin
    Break;
   End;
   While(TopOfStack>MinTopOfStack)and(StackPeek<>'(')do PostFix:=PostFix+StackPop;
   If TopOfStack>1Then StackPop;
   Inc(I);
  End
   Else
  Inc(I);
  If(Infix[I]in StopChar)Then Break;
  If StrToUpper(Copy(Infix,I,4))='THEN'Then Break;
 Until I>Length(Infix);
 CurrPos:=I;
 While(TopOfStack>MinTopOfStack)do PostFix:=PostFix+StackPop;
  { Transformation en POSTFIX }
 I:=1;
 Repeat
  If PostFix[I]in['*','+','-',' ']Then Begin
   P:=ResultStackPop;
   P2:=ResultStackPop;
   Case PostFix[I]of
    '+':_Result:=P2+P;
    '-':_Result:=P2-P;
    '*':_Result:=P2*P;
    '/':_Result:=P2/P;
    Else _Result:=-1;
   End;
   ResultStackPush(_Result);
  End
   Else
  Begin
   Value:='';
   Exposant:=False;
   Repeat
    If Postfix[I]in['0'..'9','.']Then Begin
     Value:=Value+Postfix[I];
     Inc(I);
    End
     Else
    If(Value<>'')and(Postfix[I]in['E','e'])Then Begin
     Exposant:=True;
     Value:=Value+Postfix[I];
     Inc(I);
    End
     Else
    If(Value<>'')and(Exposant)and(Postfix[I]in['+','-'])Then Begin
     Value:=Value+Postfix[I];
     Inc(I);
    End
     Else
    Break;
   Until I>Length(Postfix);
   If Value<>''Then Begin
    Val(Value,_Result,Err);
    ResultStackPush(_Result);
   End;
  End;
  Inc(I);
 Until I>Length(Postfix);
 GetNumberValue:=ResultStackPop;
End;

 { Traitement des commandes }
Procedure BeepCommand;Begin
 Sound(1550);
 Delay(182);
 NoSound;
End;

Procedure ColorCommand;
Var
 Foreground,Background:Real;
Begin
 Foreground:=GetNumberValue(1);
 TextColor(Trunc(Foreground));
 If GetSeparator=','Then Begin
  Inc(CurrPos);
  Background:=GetNumberValue(1);
  TextBackground(Trunc(Background));
 End;
End;

Procedure ChDirCommand;
Var
 Error:Word;
 S:String;
Begin
 SkipSpace;
 {$I-} ChDir(GetStringValue);{$I+}
 Error:=IoResult;
 If Error<>0Then WriteLn(GetErrorMessage(Error));
End;

Procedure FilesCommand;
Var
 Info:SearchRec;
 CurrDrive:Char;
Begin
 CurrDrive:=GetCurrentDisk;
 FindFirst('*.*',AnyFile,Info);
 While DOSError=0 do Begin
  Write(PadRight(Info.Name,16));
  FindNext(Info);
 End;
 WriteLn;
 WriteLn(' ',DiskFree(Byte(CurrDrive)-64):10,' octet(s) de libre');
 WriteLn;
End;

Function GotoCommand:Boolean;
Var
 JumpLine:Integer;
 I,J,Err:Integer;
Begin
 GotoCommand:=True;
 JumpLine:=Trunc(GetNumberValue(1));
 If NumberLine>0Then Begin
  For I:=1 to NumberLine do If(FirstNumberInStr(PA[I]^)=JumpLine)Then Begin
   CurrNumberLine:=JumpLine;
   CurrLine:=PA[I]^;
   CurrLinePtr:=I;
   J:=1;
   While(J<Length(CurrLine))do Begin
    If Not(CurrLine[J]in['0'..'9'])Then Begin
     Val(Copy(CurrLine,1,J-1),CurrNumberLine,Err);
     Break;
    End;
    Inc(J);
   End;
   While J<=Length(CurrLine)do Begin
    If CurrLine[J]in[' ',#9]Then Inc(J)
                            Else Break;
   End;
   CurrPos:=J;
   Exit;
  End;
 End;
 WriteLn('Etiquette introuvable');
 GotoCommand:=False;
End;

Procedure HelpCommand;
Var
 I:Byte;
Begin
 For I:=Low(CommandList) to High(CommandList) do Write(PadRight(CommandList[I],10));
 WriteLn;
End;

Procedure IfCommand;
Var
 ResultCmp:Boolean;
 Compare:String;
 R1,R2:Real;
 S,S1,S2:String;
Begin
 If GetSeparator='"'Then Begin
  Compare:='';
  S1:=GetStringValue;
  Case GetSeparator of
   '=':Begin
    Compare:='=';
    Inc(CurrPos);
   End;
   '<':Begin
    Inc(CurrPos);
    If GetSeparator='='Then Begin
     Compare:='<=';
     Inc(CurrPos);
    End
     Else
    Compare:='<';
   End;
   '>':Begin
    Inc(CurrPos);
    If GetSeparator='='Then Begin
     Compare:='>=';
     Inc(CurrPos);
    End
     Else
    Compare:='>';
   End;
  End;
  S2:=GetStringValue;
  If Compare='<='Then ResultCmp:=S1<=S2 Else
  If Compare='<'Then ResultCmp:=S1<S2 Else
  If Compare='>='THen ResultCmp:=S1>=S2 Else
  If Compare='>'Then ResultCmp:=S1>S2 Else
  If Compare='='Then ResultCmp:=S1=S2
   Else
  Begin
   WriteLn('Erreur d''operateur de comparaison');
   Exit;
  End;
 End
  Else
 Begin
  Compare:='';
  R1:=GetNumberValue(1);
  Case GetSeparator of
   '=':Begin
    Inc(CurrPos);
    Compare:='=';
   End;
   '<':Begin
    Inc(CurrPos);
    If GetSeparator='='Then Begin
     Inc(CurrPos);
     Compare:='<=';
    End
     Else
    Compare:='<';
   End;
   '>':Begin
    Inc(CurrPos);
    If GetSeparator='='Then Begin
     Compare:='>=';
     Inc(CurrPos);
    End
     Else
    Compare:='>';
   End;
  End;
  R2:=GetNumberValue(1);
  If Compare='<='Then ResultCmp:=R1<=R2 Else
  If Compare='<'Then ResultCmp:=R1<R2 Else
  If Compare='>='THen ResultCmp:=R1>=R2 Else
  If Compare='>'Then ResultCmp:=R1>R2 Else
  If Compare='='Then ResultCmp:=R1=R2
   Else
  Begin
   WriteLn('Erreur d''operateur de comparaison');
   Exit;
  End;
 End;
 While CurrPos<Length(CurrLine) do Begin
  If Not(CurrLine[CurrPos]in[#9,' '])Then Break;
  Inc(CurrPos);
 End;
 S:='';
 While CurrPos<Length(CurrLine) do Begin
  If Not(CurrLine[CurrPos]in['A'..'Z','a'..'z'])Then Break;
  S:=S+CurrLine[CurrPos];
  Inc(CurrPos);
 End;
 If StrToUpper(S)<>'THEN'Then Begin
  WriteLn('Mot reserve THEN introuvable');
  Exit;
 End;
 While CurrPos<Length(CurrLine) do Begin
  If Not(CurrLine[CurrPos]in[#9,' '])Then Break;
  Inc(CurrPos);
 End;
 If ResultCmp Then Exit;
 While CurrPos<Length(CurrLine) do Begin
  If(CurrLine[CurrPos]in[#9,' ',':'])and(StrToUpper(Copy(CurrLine,CurrPos+1,4))='ELSE')Then Begin
   Inc(CurrPos,5);
   Break;
  End;
  Inc(CurrPos);
 End;
End;

Procedure ListCommand;
Var
 I:Integer;
Begin
 If NumberLine>0Then Begin
  For I:=1 to NumberLine do WriteLn(PA[I]^);
 End;
End;

Procedure LListCommand;
Var
 I:Integer;
Begin
 If NumberLine>0Then Begin
  For I:=1 to NumberLine do WriteLn(Lst,PA[I]^);
 End;
End;

Procedure LoadCommand;
Var
 FileLoad:Text;
 S:String;
Begin
 If GetSeparator='"'Then Begin
  FileName:=GetStringValue;
  If FileName<>''Then Begin
   If StrToUpper(Copy(FileName,Length(FileName)-3,4))<>'.BAS'Then FileName:=FileName+'.BAS';
   {$I-}Assign(FileLoad,FileName);
   Reset(FileLoad);{$I+}
   If IoResult<>0Then Begin
    WriteLn('Fichier introuvable');
    Exit;
   End;
   NewCommand;
   While Not EOF(FileLoad) do Begin
    ReadLn(FileLoad,S);
    If Not AddLine(LTrim(S))Then Begin
     WriteLn('Manque de m‚moire');
     Break;
    End;
   End;
   Close(FileLoad);
   ResortList;
  End
   Else
  WriteLn('Nom du fichier absent');
 End
  Else
 WriteLn('Chaine de caractŠres attendu');
End;

Procedure LocateCommand;
Var
 X,Y:Real;
Begin
 Y:=GetNumberValue(1);
 If GetSeparator=','Then Begin
  Inc(CurrPos);
  X:=GetNumberValue(1);
  If(X>80.0)or(X<0.0)Then Begin
   WriteLn('Depassement d''intervalle');
   Exit;
  End;
  GotoXY(Trunc(X),Trunc(Y));
 End
  Else
 GotoXY(1,Trunc(Y));
End;

Procedure MkDirCommand;
Var
 Error:Word;
 S:String;
Begin
 SkipSpace;
 {$I-} MkDir(GetStringValue);{$I+}
 Error:=IoResult;
 If Error<>0Then WriteLn(GetErrorMessage(Error));
End;

Procedure NewCommand;
Var
 I:Integer;
Begin
 For I:=1 to NumberLine do FreeMem(PA[I],Length(PA[I]^)+1);
 NumberLine:=0;
End;

Procedure PrintCommand;
Var
 R:Real;
Begin
 If GetSeparator='"'Then Begin
  WriteLn(GetStringValue);
 End
  Else
 Begin
  If CurrPos>Length(CurrLine)Then WriteLn
   Else
  Begin
   R:=GetNumberValue(1);
   If Frac(R)=0.0Then WriteLn(R:0:0)
                 Else WriteLn(R);
  End;
 End;
End;

Procedure RmDirCommand;
Var
 Error:Word;
 S:String;
Begin
 SkipSpace;
 {$I-} RmDir(GetStringValue);{$I+}
 Error:=IoResult;
 If Error<>0Then WriteLn(GetErrorMessage(Error));
End;

Procedure RunCommand;
Var
 J:Integer;
 Err:Integer;
Begin
 If NumberLine>0Then Begin
  CurrLinePtr:=1;
  While(CurrLinePtr<=NumberLine) do Begin
   CurrLine:=PA[CurrLinePtr]^;
   CurrNumberLine:=0;
   J:=1;
   While(J<Length(CurrLine))do Begin
    If Not(CurrLine[J]in['0'..'9'])Then Begin
     Val(Copy(CurrLine,1,J-1),CurrNumberLine,Err);
     If(Tron)Then Write('[',CurrNumberLine,']');
     Break;
    End;
    Inc(J);
   End;
   While J<=Length(CurrLine)do Begin
    If CurrLine[J]in[' ',#9]Then Inc(J)
                            Else Break;
   End;
   CurrPos:=J;
   If Not RunBasic(True)Then Break;
   Inc(CurrLinePtr);
  End;
 End;
End;

Procedure SaveCommand;
Var
 I:Integer;
 Target:Text;
Begin
 If GetSeparator='"'Then Begin
  FileName:=GetStringValue;
  If FileName=''Then Begin
   WriteLn('Sauvegarde avec un nom vide impossible');
   Exit;
  End;
  {$I-}Assign(Target,FileName);
  Rewrite(Target);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Impossible de creer le fichier');
   Exit;
  End;
  If NumberLine>0Then Begin
   For I:=1 to NumberLine do WriteLn(Target,PA[I]^);
  End;
  Close(Target);
 End
  Else
 Begin
  If FileName<>''Then Begin
   {$I-}Assign(Target,FileName);
   Rewrite(Target);{$I+}
   If IoResult<>0Then Begin
    WriteLn('Impossible de creer le fichier');
    Exit;
   End;
   If NumberLine>0Then Begin
    For I:=1 to NumberLine do WriteLn(Target,PA[I]^);
   End;
   Close(Target);
  End
   Else
  WriteLn('Sauvegarde sans nom impossible');
 End;
End;

Procedure SleepCommand;
Var
 N:Real;
Begin
 N:=GetNumberValue(1);
 Delay(Trunc(N*1000));
End;

Procedure TroffCommand;Begin
 Tron:=False;
End;

Procedure TronCommand;Begin
 Tron:=True;
End;

Function WidthCommand:Boolean;
Var
 Width:Real;
Begin
 WidthCommand:=True;
 Width:=GetNumberValue(1);
 Case Trunc(Width)of
  40:TextMode(C40);
  80:TextMode(C80);
  Else Begin
   WriteLn('Valeur invalide');
   WidthCommand:=False;
  End;
 End;
End;

Function RunBasic(InList:Boolean):Boolean;
Var
 UnknownCommand:Boolean;
 NoImplementation:Boolean;
 J,Err:Integer;
 R1:Real;
Begin
 RunBasic:=False;
 If Not(InList)Then Begin
  CurrPos:=1;
  J:=1;CurrNumberLine:=0;
  While(J<Length(CurrLine))do Begin
   If Not(CurrLine[J]in['0'..'9'])Then Begin
    Val(Copy(CurrLine,1,J-1),CurrNumberLine,Err);
    Break;
   End;
   Inc(J);
  End;
  If CurrNumberLine<>0Then Begin
   AddLine(CurrLine);
   ResortList;
   Exit;
  End;
 End;
 Repeat
  NoImplementation:=False;
  UnknownCommand:=False;
  Case ExtractCommand of
   0: NoImplementation:=True;{AND}
   1: NoImplementation:=True;{AUTO}
   2: BeepCommand;{BEEP}
   3: NoImplementation:=True;{BLOAD}
   4: NoImplementation:=True;{BSAVE}
   5: NoImplementation:=True;{CALL}
   6: NoImplementation:=True;{CAT}
   7: NoImplementation:=True;{CHAIN}
   8: ChDirCommand;{CHDIR}
   9: NoImplementation:=True;{CIRCLE}
   10: NoImplementation:=True;{CLEAR}
   11: NoImplementation:=True;{CLOSE}
   12: NoImplementation:=True;{CLR}
   13: ClrScr;{CLS}
   14: ColorCommand;{COLOR}
   15: NoImplementation:=True;{COM}
   16: NoImplementation:=True;{COMMON}
   17: NoImplementation:=True;{CONT}
   18: NoImplementation:=True;{DATA}
   19: NoImplementation:=True;{DEF}
   20: NoImplementation:=True;{DELETE}
   21: NoImplementation:=True;{DIM}
   22: NoImplementation:=True;{DRAW}
   23: NoImplementation:=True;{EDIT}
   24: NoImplementation:=True;{ELSE}
   25: NoImplementation:=True;{END}
   26: NoImplementation:=True;{ERASE}
   27: NoImplementation:=True;{ERROR}
   28: NoImplementation:=True;{FIELD}
   29: FilesCommand;{FILES}
   30: NoImplementation:=True;{FOR}
   31: NoImplementation:=True;{GET}
   32: NoImplementation:=True;{GOSUB}
   33: If Not(GotoCommand)Then Exit;{GOTO}
   34: HelpCommand;{HELP}
   35: IfCommand;{IF}
   36: NoImplementation:=True;{INPUT}
   37: NoImplementation:=True;{KEY}
   38: NoImplementation:=True;{KILL}
   39: NoImplementation:=True;{LET}
   40: NoImplementation:=True;{LINE}
   41: ListCommand;{LIST}
   42: LListCommand;{LLIST}
   43: LoadCommand;{LOAD}
   44: LocateCommand;{LOCATE}
   45: NoImplementation:=True;{LPRINT}
   46: NoImplementation:=True;{LSET}
   47: NoImplementation:=True;{MERGE}
   48: MkDirCommand;{MKDIR}
   49: NoImplementation:=True;{NAME}
   50: NewCommand;{NEW}
   51: NoImplementation:=True;{NEXT}
   52: NoImplementation:=True;{ON}
   53: NoImplementation:=True;{OPEN}
   54: NoImplementation:=True;{OPTION}
   55: NoImplementation:=True;{OR}
   56: NoImplementation:=True;{OUT}
   57: NoImplementation:=True;{PAINT}
   58: NoImplementation:=True;{PALETTE}
   59: NoImplementation:=True;{POKE}
   60: NoImplementation:=True;{PLAY}
   61: NoImplementation:=True;{PRESET}
   62: PrintCommand;{PRINT}
   63: NoImplementation:=True;{PSET}
   64: NoImplementation:=True;{PUT}
   65: NoImplementation:=True;{RANDOMIZE}
   66: NoImplementation:=True;{READ}
   67: Begin
    RunBasic:=True;
    Exit;{REM}
   End;
   68: NoImplementation:=True;{RENUM}
   69: NoImplementation:=True;{RESET}
   70: NoImplementation:=True;{RESUME}
   71: NoImplementation:=True;{RESTORE}
   72: NoImplementation:=True;{RETURN}
   73: RmDirCommand;{RMDIR}
   74: NoImplementation:=True;{RSET}
   75: RunCommand;{RUN}
   76: SaveCommand;{SAVE}
   77: NoImplementation:=True;{SCREEN}
   78: NoImplementation:=True;{SHELL}
   79: SleepCommand;{SLEEP}
   80: Exit;{STOP}
   81: Begin {SYSTEM}
    Terminated:=True;
    Exit;
   End;
   82: NoImplementation:=True;{THEN}
   83: TroffCommand;{TROFF}
   84: TronCommand;{TRON}
   85: NoImplementation:=True;{VIEW}
   86: NoImplementation:=True;{WAIT}
   87: NoImplementation:=True;{WEND}
   88: NoImplementation:=True;{WHILE}
   89: If Not(WidthCommand)Then Break;{WIDTH}
   90: NoImplementation:=True;{WINDOW}
   91: NoImplementation:=True;{WRITE}
   Else UnknownCommand:=True;
  End;
  If(UnknownCommand)Then Begin
   SkipSpace;
   If CurrLine[CurrPos]='='Then Begin
    Case CurrCommand[Length(CurrCommand)]of
     '%':Begin
      R1:=GetNumberValue(1);
      If VariableExist(CurrCommand)Then
       SetVariableInt(CurrCommand,Trunc(R1))
      Else
       AddVariableInt(CurrCommand,Trunc(R1));
     End;
     '#','!':Begin
      R1:=GetNumberValue(1);
      If VariableExist(CurrCommand)Then
       SetVariableReal(CurrCommand,Trunc(R1))
      Else
       AddVariableReal(CurrCommand,Trunc(R1));
     End;
     Else Begin
      R1:=GetNumberValue(1);
      If VariableExist(CurrCommand)Then
       SetVariableLongInt(CurrCommand,Trunc(R1))
      Else
       AddVariableLongInt(CurrCommand,Trunc(R1));
     End;
    End;
   End
    Else
   WriteLn('Commande non reconnu');
   Exit;
  End;
  If(NoImplementation)Then Begin
   WriteLn('Cette commande n''a pas ete implemente');
   Exit;
  End;
  While(CurrLine[CurrPos]in[' ',':'])and(CurrPos<=Length(CurrLine)) do Inc(CurrPos);
  If CurrPos>=Length(CurrLine)Then Break;
  If Not(CurrLine[CurrPos]in['A'..'Z','a'..'z','_'])Then Begin
   If(InList)Then WriteLn('Erreur de syntaxe a la position ',CurrPos,' de la ligne ',CurrNumberLine)
             ELse WriteLn('Erreur de syntaxe a la position ',CurrPos);
   Exit;
  End;
 Until CurrPos>Length(CurrLine);
 RunBasic:=True;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('BASIC : Cette commande permet de lancer l''interpreteur de BASIC.');
  WriteLn;
  WriteLn('Syntaxe : BASIC [fichier]');
 End
  Else
 Begin
  FileName:='';
  Tron:=False;
  NumberLine:=0;CurrNumberLine:=0;
  NumberVariable:=0;
  For I:=1 to ParamCount do Begin
   FileName:=ParamStr(I);
  End;
  HomeMessage;
  If FileName<>''Then Begin
   CurrLine:='LOAD "'+FileName+'":RUN';
   RunBasic(False);
  End;
  Terminated:=False;
  Repeat
   WriteLn('Ok');
   ReadLn(CurrLine);
   CurrLine:=LTrim(CurrLine);
   RunBasic(False);
  Until Terminated;
 End;
END.