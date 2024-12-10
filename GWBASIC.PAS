{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/msdos-0)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program GWBASIC;

Uses {$IFDEF FPC}
      Crt,DOS,PtcGraph,PtcCrt,PtcMouse,Printer
     {$ELSE}
      Crt,DOS,Graph,Printer
     {$ENDIF};

Const
 Version='0.70';

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
 GosubStackRec=Record
  Line,Col:Word;
  LineNumber:Integer;
 End;
 ForStackRec=Record
  Line,Col:Word;
  LineNumber:Integer;
  VarName:String[20];
 End;

Var
 Terminated,Tron,KeyFunction:Boolean;
 CurrCommand:String;
 FileName,CurrLine:String;
 CurrPos:Byte;
 PA:Array[1..MaxLine] of StrPointer;
 CurrLinePtr,NumberLine:Integer;
 CurrNumberLine:Integer;
 VarList:Array[1..MaxVariable]of VarPointer;
 I,NumberVariable:Integer;
 FunctionKeyList:Array[1..10]of String[15];
 GosubStack:Array[1..10]of GosubStackRec;
 GosubPos:Byte;
 ForStack:Array[1..10]of ForStackRec;
 ForPos:Byte;
 LineEmpty,InGraph:Boolean;

Function RunBasic(InList:Boolean):Boolean;Forward;
Procedure NewCommand;Forward;

Function TAN(X:Real):Real;Begin
 If Cos(X)=0.0Then Tan:=0.0
              Else Tan:=SIN(X)/COS(X);
End;

Function IsNumberWord(S:String):Boolean;
Var
 I:Integer;
Begin
 IsNumberWord:=True;
 For I:=1 to Length(S)do Begin
  If Not(S[I]in['0'..'9'])Then Begin
   IsNumberWord:=False;
   Exit;
  End;
 End;
End;

Function IntToStr(I:Integer):String;
Var
 S:String;
Begin
 Str(I,S);
 IntToStr:=S;
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

Function RTrim(s:String):String;
Var
 i:Integer;
Begin
 i:=Length(s);
 While (i>0)and(s[i]in[#9,' '])do Dec(i);
 s[0]:=Chr(i);
 RTrim:=S;
End;

Function Trim(s:String):String;Begin
 Trim:=LTrim(RTrim(s));
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
  15:GetErrorMessage:='NumÇro de disque invalide';
  16:GetErrorMessage:='Impossible de supprimer le rÇpertoire';
  17:GetErrorMessage:='Impossible de renommer sur plusieurs volumes';
  100:GetErrorMessage:='Erreur de lecture Ö partir du disque';
  101:GetErrorMessage:='Erreur d''ecriture sur le disque';
  102:GetErrorMessage:='Fichier non attribue';
  103:GetErrorMessage:='Le fichier n''est pas ouvert';
  104:GetErrorMessage:='Le fichier n''est pas ouvert Ö l''entree';
  105:GetErrorMessage:='Le fichier n''est pas ouvert Ö la sortie';
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

Procedure ShowFunctionKey;
Var
 I,J,OldY:Byte;
 Temp:String;
Begin
 OldY:=WhereY;
 Window(1,1,80,25);
 GotoXY(1,25);
 ClrEol;
 If(KeyFunction)Then Begin
  For I:=1 to 10 do Begin
   TextColor(7);
   TextBackground(0);
   Write(I mod 10);
   TextColor(0);
   TextBackground(7);
   Temp:='';
   For J:=1 to Length(FunctionKeyList[I])do Begin
    If FunctionKeyList[I][J]<>#13Then Temp:=Temp+FunctionKeyList[I][J];
   End;
   Write(Temp);
   TextColor(7);
   TextBackground(0);
   If I<10 Then Begin
    If Length(Temp)<7 Then Write(' ':7-Length(Temp));
   End;
  End;
 End;
 Window(1,1,80,24);
 GotoXY(1,OldY);
End;

Procedure HomeMessage;Begin
 ClrScr;
 ShowFunctionKey;
 Window(1,1,80,24);
 WriteLn('GW-BASIC Clone ',Version);
 WriteLn('Licence libre et open source MIT 2021, 2022, 2024');
End;

Function ExtractCommand:Byte;
Var
 I:Byte;
Begin
 ExtractCommand:=255;
 CurrCommand:='';
 If(CurrPos<=Length(CurrLine))and(CurrLine[CurrPos]='?')Then Begin
  CurrCommand:='PRINT';
  Inc(CurrPos);
 End
  Else
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

Function AddVariableString(S:String;Value:String):Boolean;
Var
 P:VarPointer;
 PS:StrPointer;
Begin
 If NumberVariable>=MaxVariable Then Begin
  AddVariableString:=False;
  Exit;
 End;
 Inc(NumberVariable);
 GetMem(P,SizeOf(VarRec));
 P^.VarName:=Copy(StrToUpper(S),1,20);
 P^.VarType:=_String;
 GetMem(PS,SizeOf(String));
 PS^:=Value;
 P^.Variant.S:=PS;
 VarList[NumberVariable]:=P;
 AddVariableString:=True;
End;

Function GetVariableString(S:String):String;
Var
 I:Integer;
Begin
 GetVariableString:='';
 For I:=1 to NumberVariable do If(StrToUpper(S)=VarList[I]^.VarName)Then Begin
  GetVariableString:=VarList[I]^.Variant.S^;
  Exit;
 End;
End;

Procedure SetVariableString(S:String;Value:String);
Var
 I:Integer;
Begin
 For I:=1 to NumberVariable do If(S=VarList[I]^.VarName)Then Begin
  VarList[I]^.Variant.S^:=Value;
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

Procedure DeleteLineNumber(Number:Word);
Var
 ThisNumber:LongInt;
 I:Integer;
Begin
 For I:=1 to NumberLine do Begin
  ThisNumber:=FirstNumberInStr(PA[I]^);
  If ThisNumber>0 Then Begin
   If(ThisNumber=Number)Then Begin
    PA[I]^:='';
    ResortList;
    Exit;
   End;
  End;
 End;
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

Function IsStringValue:Boolean;
Var
 I:Byte;
Begin
 IsStringValue:=False;
 If CurrLine[CurrPos]='"'Then Begin
  IsStringValue:=True;
 End
  Else
 Begin
  I:=CurrPos;
  While(CurrLine[I]in[' '])and(I<Length(CurrLine))do Inc(I);
  If CurrLine[I]in['A'..'Z','a'..'z']Then Begin
   Inc(I);
   While I<Length(CurrLine)do Begin
    If Not(CurrLine[I]in['A'..'Z','a'..'z','0'..'9'])Then Break;
    Inc(I);
   End;
   If(I<=Length(CurrLine))and(CurrLine[I]='$')Then IsStringValue:=True;
  End;
 End;
End;

Function GetVariableName:String;
Var
 S:String;
Begin
 S:='';
 If CurrLine[CurrPos]in['A'..'Z','a'..'z']Then Begin
  S:=S+CurrLine[CurrPos];
  Inc(CurrPos);
  While CurrPos<Length(CurrLine)do Begin
   If Not(CurrLine[CurrPos]in['A'..'Z','a'..'z','0'..'9'])Then Break;
   S:=S+CurrLine[CurrPos];
   Inc(CurrPos);
  End;
 End;
 GetVariableName:=StrToUpper(S);
End;

Function ReadInteger:Integer;
Var
 S:String;
 Number:Integer;
 Err:Word;
Begin
 S:='';
 If CurrLine[CurrPos]in['0'..'9']Then Begin
  S:=S+CurrLine[CurrPos];
  Inc(CurrPos);
  While CurrPos<=Length(CurrLine)do Begin
   If Not(CurrLine[CurrPos]in['0'..'9'])Then Break;
   S:=S+CurrLine[CurrPos];
   Inc(CurrPos);
  End;
 End;
 Val(S,Number,Err);
 If Err>0 Then Number:=-1;
 ReadInteger:=Number;
End;

Function ReadWord:String;
Var
 S:String;
Begin
 S:='';
 If CurrLine[CurrPos]in['A'..'Z','a'..'z']Then Begin
  S:=S+CurrLine[CurrPos];
  Inc(CurrPos);
  While CurrPos<Length(CurrLine)do Begin
   If Not(CurrLine[CurrPos]in['A'..'Z','a'..'z','0'..'9'])Then Break;
   S:=S+CurrLine[CurrPos];
   Inc(CurrPos);
  End;
 End;
 ReadWord:=StrToUpper(S);
End;

Function ReadWordString:String;
Var
 S:String;
Begin
 S:='';
 If CurrLine[CurrPos]in['A'..'Z','a'..'z']Then Begin
  S:=S+CurrLine[CurrPos];
  Inc(CurrPos);
  While CurrPos<Length(CurrLine)do Begin
   If Not(CurrLine[CurrPos]in['A'..'Z','a'..'z','0'..'9'])Then Break;
   S:=S+CurrLine[CurrPos];
   Inc(CurrPos);
  End;
  If CurrLine[CurrPos]='$'Then Begin
   S:=S+'$';
   Inc(CurrPos);
  End;
 End;
 ReadWordString:=StrToUpper(S);
End;

Function GetNumberValue(MinTopOfStack:Integer):Real;Forward;

Function GetStringValue:String;
Label Restart;
Var
 J:Integer;
 _Result:Real;
 FunctionFound:Boolean;
 S,VarName:String;
Begin
 GetStringValue:='';
 S:='';
Restart:
 If CurrLine[CurrPos]='"'Then Begin
  Inc(CurrPos);
  While(CurrLine[CurrPos]<>'"')and(CurrPos<=Length(CurrLine))do Begin
   S:=S+CurrLine[CurrPos];
   Inc(CurrPos);
  End;
  If CurrLine[CurrPos]='"'Then Inc(CurrPos);
 End
  Else
 Begin
  VarName:=ReadWordString;
  SkipSpace;
  FunctionFound:=False;
  For J:=Low(FunctionList)to High(FunctionList)do Begin
   If FunctionList[J]=VarName Then Begin
    FunctionFound:=True;
    Case J of
     3:Begin{CHR$}
      If CurrLine[CurrPos]<>'('Then Begin
       WriteLn('"(" attendu');
       Exit;
      End;
      Inc(CurrPos);
      _Result:=GetNumberValue(1);
      If CurrLine[CurrPos]<>')'Then Begin
       WriteLn('")" attendu');
       Exit;
      End;
      Inc(CurrPos);
      S:=S+Chr(Byte(Trunc(_Result)));
      GetStringValue:=S;
      Break;
     End;
     Else Begin
      WriteLn('Type incompatible');
      Exit;
     End;
    End;
   End;
  End;
  If Not(FunctionFound)Then Begin
   If VariableExist(VarName)Then Begin
    S:=S+GetVariableString(VarName);
   End;
  End;
 End;
 SkipSpace;
 If CurrLine[CurrPos]in['+',';']Then Begin
  Inc(CurrPos);
  Goto Restart;
 End;
 GetStringValue:=S;
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
  If(I<=Length(Infix))and(Infix[I]in['A'..'Z','a'..'z'])Then Begin
   VarName:=Infix[I];
   Inc(I);
   While(I<=Length(Infix))and(Infix[I]in['A'..'Z','a'..'z','%','!','#'])do Begin
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
  If(StrToUpper(Copy(Infix,I,4))='THEN')or(StrToUpper(Copy(Infix,I,2))='TO')Then Break;
 Until I>Length(Infix);
 CurrPos:=I;
 While(TopOfStack>MinTopOfStack)do PostFix:=PostFix+StackPop;
  { Transformation en POSTFIX }
 I:=1;
 Repeat
  If PostFix[I]in['*','+','-','/']Then Begin
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

Function CircleCommand:Boolean;
Var
 X,Y,R:Real;
Begin
 CircleCommand:=False;
 If GetSeparator='('Then Begin
  Inc(CurrPos);
 End
  Else
 Exit;
 X:=GetNumberValue(1);
 If GetSeparator=','Then Begin
  Inc(CurrPos);
 End
  Else
 Exit;
 Y:=GetNumberValue(1);
 If GetSeparator=')'Then Begin
  Inc(CurrPos);
 End
  Else
 Exit;
 If GetSeparator=','Then Begin
  Inc(CurrPos);
 End
  Else
 Exit;
 R:=GetNumberValue(1);
 Circle(Trunc(X),Trunc(Y),Trunc(R));
 CircleCommand:=True;
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

Function ForCommand:Boolean;
Var
 R1,R2:Real;
Begin
 ForCommand:=False;
 If ForPos>=High(ForStack)Then Begin
  WriteLn('Pile de FOR pleine.');
  Exit;
 End;
 Inc(ForPos);
 ForStack[ForPos].Line:=CurrLinePtr;
 ForStack[ForPos].LineNumber:=CurrNumberLine;
 SkipSpace;
 ForStack[ForPos].VarName:=Copy(GetVariableName,1,20);
 SkipSpace;
 If GetSeparator<>'='Then Begin
  WriteLn('"=" attendu.');
  Exit;
 End;
 Inc(CurrPos);
 R1:=GetNumberValue(1);
 If VariableExist(ForStack[ForPos].VarName)Then
  SetVariableReal(ForStack[ForPos].VarName,Trunc(R1))
 Else
  AddVariableReal(ForStack[ForPos].VarName,Trunc(R1));
 SkipSpace;
 If StrToUpper(ReadWord)<>'TO'Then Begin
  WriteLn('Mot rÇservÇ "TO" attendu');
  Exit;
 End;
 SkipSpace;
 ForStack[ForPos].Col:=CurrPos;
 R2:=GetNumberValue(1);
 ForCommand:=True;
End;

Function GosubCommand:Boolean;
Var
 JumpLine:Integer;
 I,J,Err:Integer;
Begin
 GosubCommand:=True;
 If GosubPos>=High(GosubStack)Then Begin
  WriteLn('Pile de GOSUB pleine !');
  GosubCommand:=False;
  Exit;
 End;
 JumpLine:=Trunc(GetNumberValue(1));
 If(CurrPos<=Length(CurrLine))and(CurrLine[CurrPos]=':')Then Inc(CurrPos);
 Inc(GosubPos);
 GosubStack[GosubPos].Line:=CurrLinePtr;
 GosubStack[GosubPos].Col:=CurrPos;
 GosubStack[GosubPos].LineNumber:=CurrNumberLine;
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
 GosubCommand:=False;
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
   WriteLn('Erreur d''opÇrateur de comparaison');
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
  WriteLn('Mot resÇrvÇ THEN introuvable');
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

Procedure KeyCommand;
Var
 S:String;
Begin
 SkipSpace;
 S:='';
 While CurrPos<=Length(CurrLine) do Begin
  If Not(CurrLine[CurrPos]in['A'..'Z','a'..'z'])Then Break;
  S:=S+CurrLine[CurrPos];
  Inc(CurrPos);
 End;
 If StrToUpper(S)='ON'Then Begin
  KeyFunction:=True;
  ShowFunctionKey;
 End
  Else
 If StrToUpper(S)='OFF'Then Begin
  KeyFunction:=False;
  ShowFunctionKey;
 End
  Else
 WriteLn('Mot non reconnu');
End;

Function LineCommand:Boolean;
Var
 Mode:(_Line,_B,_BF);
 X1,Y1,X2,Y2,C:Real;
 S:String;
Begin
 LineCommand:=False;
 If GetSeparator='('Then Begin
  Inc(CurrPos);
 End
  Else
 Exit;
 X1:=GetNumberValue(1);
 If GetSeparator=','Then Begin
  Inc(CurrPos);
 End
  Else
 Exit;
 Y1:=GetNumberValue(1);
 If GetSeparator=')'Then Begin
  Inc(CurrPos);
 End
  Else
 Exit;
 If GetSeparator='-'Then Begin
  Inc(CurrPos);
 End
  Else
 Exit;
 If GetSeparator='('Then Begin
  Inc(CurrPos);
 End
  Else
 Exit;
 X2:=GetNumberValue(1);
 If GetSeparator=','Then Begin
  Inc(CurrPos);
 End
  Else
 Exit;
 Y2:=GetNumberValue(1);
 If GetSeparator=')'Then Begin
  Inc(CurrPos);
 End
  Else
 Exit;
 If GetSeparator=','Then Begin
  Inc(CurrPos);
 End
  Else
 Exit;
 C:=GetNumberValue(1);
 SetColor(Trunc(C));
 Mode:=_Line;
 If GetSeparator=','Then Begin
  Inc(CurrPos);
  SkipSpace;
  S:='';
  While CurrPos<=Length(CurrLine) do Begin
   If Not(CurrLine[CurrPos]in['A'..'Z','a'..'z'])Then Break;
   S:=S+UpCase(CurrLine[CurrPos]);
   Inc(CurrPos);
  End;
  If S='B'Then Mode:=_B Else
  If S='BF'Then Mode:=_BF;
 End;
 Case Mode of
  _B:Rectangle(Trunc(X1),Trunc(Y1),Trunc(X2),Trunc(Y2));
  _BF:Begin
   SetFillStyle(SolidFill,Trunc(C));
   Bar(Trunc(X1),Trunc(Y1),Trunc(X2),Trunc(Y2));
  End;
  Else Line(Trunc(X1),Trunc(Y1),Trunc(X2),Trunc(Y2));
 End;
 LineCommand:=True;
End;

Procedure ListCommand;
Var
 I,Start,Finish:Integer;
 Err:Word;
 Number:Word;
Begin
 If NumberLine>0Then Begin
  Start:=-1;
  Finish:=-1;
  SkipSpace;
  If GetSeparator='-'Then Begin
   Inc(CurrPos);
   Finish:=ReadInteger;
  End
   Else
  Begin
   Start:=ReadInteger;
   If GetSeparator='-'Then Begin
    Inc(CurrPos);
    Finish:=ReadInteger;
   End
    Else
   Finish:=Start;
  End;
  If(Start=-1)and(Finish=-1)Then Begin
   For I:=1 to NumberLine do Begin
    If PA[I]^<>''Then WriteLn(PA[I]^);
   End;
  End
   Else
  If(Start<>-1)and(Finish=-1)Then Begin
   For I:=1 to NumberLine do Begin
    Number:=FirstNumberInStr(PA[I]^);
    If(Number>=Start)Then Begin
     If PA[I]^<>''Then WriteLn(PA[I]^);
    End;
   End;
  End
   Else
  If(Start=-1)and(Finish<>-1)Then Begin
   For I:=1 to NumberLine do Begin
    Number:=FirstNumberInStr(PA[I]^);
    If(Number<=Finish)Then Begin
     If PA[I]^<>''Then WriteLn(PA[I]^);
    End;
   End;
  End
   Else
  Begin
   For I:=1 to NumberLine do Begin
    Number:=FirstNumberInStr(PA[I]^);
    If(Number>=Start)and(Number<=Finish)Then Begin
     If PA[I]^<>''Then WriteLn(PA[I]^);
    End;
   End;
  End;
 End;
End;

Procedure LListCommand;
Var
 I,Start,Finish:Integer;
 Err:Word;
 Number:Word;
Begin
 If NumberLine>0Then Begin
  Start:=-1;
  Finish:=-1;
  SkipSpace;
  If GetSeparator='-'Then Begin
   Inc(CurrPos);
   Finish:=ReadInteger;
  End
   Else
  Begin
   Start:=ReadInteger;
   If GetSeparator='-'Then Begin
    Inc(CurrPos);
    Finish:=ReadInteger;
   End
    Else
   Finish:=Start;
  End;
  If(Start=-1)and(Finish=-1)Then Begin
   For I:=1 to NumberLine do WriteLn(Lst,PA[I]^);
  End
   Else
  If(Start<>-1)and(Finish=-1)Then Begin
   For I:=1 to NumberLine do Begin
    Number:=FirstNumberInStr(PA[I]^);
    If(Number>=Start)Then WriteLn(Lst,PA[I]^);
   End;
  End
   Else
  If(Start=-1)and(Finish<>-1)Then Begin
   For I:=1 to NumberLine do Begin
    Number:=FirstNumberInStr(PA[I]^);
    If(Number<=Finish)Then WriteLn(Lst,PA[I]^);
   End;
  End
   Else
  Begin
   For I:=1 to NumberLine do Begin
    Number:=FirstNumberInStr(PA[I]^);
    If(Number>=Start)and(Number<=Finish)Then WriteLn(Lst,PA[I]^);
   End;
  End;
 End;
End;

Procedure LoadCommand;
Var
 FileLoad:Text;
 S:String;

 Function LoadBASIC(SourceName:String):Boolean;
 Label RFGW,RF0,RF1;
 Var
  Mode:(None,CocoFileBAS,Coco1FileBAS,GWBASIC);
  Source:File;
  Pos:Word;
  ByteReaded:Word;
  LastB,B:Byte;
  NewLine:Boolean;
  Buffer:Array[0..4]of Byte;
  BufSingle:Single;
  BufDouble:Double;
 Begin
  LoadBASIC:=True;
  S:='';
  {$I-}Assign(Source,SourceName);
  Reset(Source,1);{$I+}
  If IoResult<>0Then Begin
   WriteLn('Fichier source introuvable');
   Exit;
  End;
  BlockRead(Source,Buffer,3,ByteReaded);
  Mode:=None;
  If(Buffer[0]=$55)Then Begin
   Seek(Source,$119);
   BlockRead(Source,Buffer,3,ByteReaded);
  End;
  If(Buffer[0]=$9D)Then Begin
   Mode:=CocoFileBAS;
  End
   Else
  If(Buffer[0]=$FF)Then Begin
   If Buffer[1]=$7AThen Mode:=GWBASIC
                   Else Mode:=Coco1FileBAS;
  End;
  Case Mode of
   GWBASIC:Begin
    NewCommand;
    BlockRead(Source,Buffer,1,ByteReaded);
    Pos:=Buffer[0];
    BlockRead(Source,Buffer,1,ByteReaded);
    Pos:=Pos+Buffer[0]*256;
    S:=S+IntToStr(Pos)+' ';
    NewLine:=True;
    LastB:=0;
    Repeat
     BlockRead(Source,Buffer,1,ByteReaded);
     B:=Buffer[0];
 RFGW:
     Case B of
      0:Begin
       If Not AddLine(LTrim(S))Then Begin
        WriteLn('Manque de mÇmoire');
        Break;
       End;
       S:='';
       BlockRead(Source,Buffer,1,ByteReaded);
       Pos:=Buffer[0];
       BlockRead(Source,Buffer,1,ByteReaded);
       Pos:=Pos+Buffer[0]*256;
       BlockRead(Source,Buffer,1,ByteReaded);
       If(Pos=0)and(Buffer[0]=26)Then Break;
       Pos:=Buffer[0];
       BlockRead(Source,Buffer,1,ByteReaded);
       Pos:=Pos+Buffer[0]*256;
       S:=S+IntToStr(Pos)+' ';
       NewLine:=True;
      End;
      $0C:S:=S+'&H';
      $0F:Begin
       BlockRead(Source,Buffer,1,ByteReaded);
       S:=S+IntToStr(Buffer[0]);
      End;
      $11..$1A:Begin
       S:=S+Char(Buffer[0]+31);
      End;
      $1C:Begin
       BlockRead(Source,Buffer,2,ByteReaded);
       S:=S+IntToStr(Buffer[0]+Buffer[1]*256);
      End;
      $1D:Begin
       BlockRead(Source,BufSingle,4,ByteReaded);
       {Write(BufSingle);}
      End;
      $1F:Begin
       BlockRead(Source,BufDouble,4,ByteReaded);
       {Write(BufDouble);}
      End;
      $3A:Begin
       BlockRead(Source,Buffer,1,ByteReaded);
       Case Buffer[0]of
        $20:Begin
         BlockRead(Source,Buffer,1,ByteReaded);
         If Buffer[0]=32Then S:=S+'GOSUB'
                        Else S:=S+#$3A+#32+IntToStr(Buffer[0]);
        End;
        $8F:Begin
         LastB:=B;
         B:=Buffer[0];
         Goto RFGW;
        ENd;
        $A1:S:=S+'ELSE';
        Else Begin
         S:=S+Char(B);
         LastB:=B;
         B:=Buffer[0];
         Goto RFGW;
        End;
       End;
      End;
      $81:S:=S+'END';
      $82:S:=S+'FOR';
      $83:S:=S+'NEXT';
      $84:S:=S+'DATA';
      $85:S:=S+'INPUT';
      $86:S:=S+'DIM';
      $87:S:=S+'READ';
      $88:S:=S+'LET';
      $89:S:=S+'GOTO';
      $8A:S:=S+'RUN';
      $8B:S:=S+'IF';
      $8C:S:=S+'RESTORE';
      $8D:S:=S+'GOSUB';
      $8E:S:=S+'RETURN';
      $8F:Begin
       BlockRead(Source,Buffer,1,ByteReaded);
       Case Buffer[0]of
        $D9:Begin
         S:=S+'''';
         While Not EOF(Source)do Begin
          BlockRead(Source,Buffer,1,ByteReaded);
          If Buffer[0]=0Then Begin
           B:=Buffer[0];
           Goto RFGW;
          End;
          S:=S+Char(Buffer[0]);
         End;
        End;
        Else Begin
         S:=S+'REM';
         While Not EOF(Source)do Begin
          BlockRead(Source,Buffer,1,ByteReaded);
          If Buffer[0]=0Then Begin
          B:=Buffer[0];
           Goto RFGW;
          End;
          S:=S+Char(Buffer[0]);
         End;
        End;
       End;
      End;
      $90:S:=S+'STOP';
      $91:S:=S+'PRINT';
      $92:S:=S+'CLEAR';
      $93:S:=S+'LIST';
      $94:S:=S+'NEW';
      $95:S:=S+'ON';
      $96:S:=S+'WAIT';
      $97:S:=S+'DEF';
      $98:S:=S+'POKE';
      $99:S:=S+'CONT';
      $9C:S:=S+'OUT';
      $9D:S:=S+'LPRINT';
      $9E:S:=S+'LLIST';
      $A0:S:=S+'WIDTH';
      $A1:S:=S+'ELSE';
      $A2:S:=S+'TRON';
      $A3:S:=S+'TROFF';
      $A4:S:=S+'SWAP';
      $A5:S:=S+'ERASE';
      $A6:S:=S+'EDIT';
      $A7:S:=S+'ERROR';
      $A8:S:=S+'RESUME';
      $A9:S:=S+'DELETE';
      $AA:S:=S+'AUTO';
      $AB:S:=S+'RENUM';
      $AC:S:=S+'DEFSTR';
      $AD:S:=S+'DEFINT';
      $AE:S:=S+'DEFSNG';
      $AF:S:=S+'DEFDBL';
      $B0:S:=S+'LINE';
      $B1:S:=S+'WHILE';
      $B2:S:=S+'WEND';
      $B3:S:=S+'CALL';
      $B7:S:=S+'WRITE';
      $B8:S:=S+'OPTION';
      $B9:S:=S+'RANDOMIZE';
      $BA:S:=S+'OPEN';
      $BB:S:=S+'CLOSE';
      $BC:S:=S+'LOAD';
      $BD:S:=S+'MERGE';
      $BE:S:=S+'SAVE';
      $BF:S:=S+'COLOR';
      $C0:S:=S+'CLS';
      $C1:S:=S+'MOTOR';
      $C2:S:=S+'BSAVE';
      $C3:S:=S+'BLOAD';
      $C4:S:=S+'SOUND';
      $C5:S:=S+'BEEP';
      $C6:S:=S+'PSET';
      $C7:S:=S+'PRESET';
      $C8:S:=S+'SCREEN';
      $C9:S:=S+'KEY';
      $CA:S:=S+'LOCATE';
      $CC:S:=S+'TO';
      $CD:S:=S+'THEN';
      $CE:S:=S+'TAB(';
      $CF:S:=S+'STEP';
      $D0:S:=S+'USR';
      $D1:S:=S+'FN';
      $D2:S:=S+'SPC(';
      $D3:S:=S+'NOT';
      $D4:S:=S+'ERL';
      $D5:S:=S+'ERR';
      $D6:S:=S+'STRING$';
      $D7:S:=S+'USING';
      $D8:S:=S+'INSTR';
      $D9:S:=S+'''';
      $DA:S:=S+'VARPTR';
      $DB:S:=S+'CSRLIN';
      $DC:S:=S+'POINT';
      $DD:S:=S+'OFF';
      $DE:S:=S+'INKEY$';
      $E6:S:=S+'>';
      $E7:S:=S+'=';
      $E8:S:=S+'<';
      $E9:S:=S+'+';
      $EA:S:=S+'-';
      $EB:S:=S+'*';
      $EC:S:=S+'/';
      $EE:S:=S+'AND';
      $EF:S:=S+'OR';
      $F0:S:=S+'XOR';
      $F1:S:=S+'EQV';
      $F2:S:=S+'IMP';
      $F3:S:=S+'MOD';
      $F4:S:=S+'\';
      $FD:Begin
       BlockRead(Source,Buffer,1,ByteReaded);
       Case Buffer[0]of
        $81:S:=S+'CVI';
        $82:S:=S+'CVS';
        $83:S:=S+'CVD';
        $84:S:=S+'MKI$';
        $85:S:=S+'MKS$';
        $86:S:=S+'MKD$';
        $87..$8A:S:=S+'---';
        $8B:S:=S+'EXTERR';
        Else S:=S+Char(Buffer[0]);
       End;
      End;
      $FE:Begin
       BlockRead(Source,Buffer,1,ByteReaded);
       Case Buffer[0]of
        $81:S:=S+'FILES';
        $82:S:=S+'FIELD';
        $83:S:=S+'SYSTEM';
        $84:S:=S+'NAME';
        $85:S:=S+'LSET';
        $86:S:=S+'RSET';
        $87:S:=S+'KILL';
        $88:S:=S+'PUT';
        $89:S:=S+'GET';
        $8A:S:=S+'RESET';
        $8B:S:=S+'COMMON';
        $8C:S:=S+'CHAIN';
        $8D:S:=S+'DATE$';
        $8E:S:=S+'TIME$';
        $8F:S:=S+'PAINT';
        $90:S:=S+'COM';
        $91:S:=S+'CIRCLE';
        $92:S:=S+'DRAW';
        $93:S:=S+'PLAY';
        $94:S:=S+'TIMER';
        $95:S:=S+'ERDEV';
        $96:S:=S+'IOCTL';
        $97:S:=S+'CHDIR';
        $98:S:=S+'MKDIR';
        $99:S:=S+'RMDIR';
        $9A:S:=S+'SHELL';
        $9B:S:=S+'ENVIRON';
        $9C:S:=S+'VIEW';
        $9D:S:=S+'WINDOW';
        $9E:S:=S+'PMAP';
        $9F:S:=S+'PALETTE';
        $A0:S:=S+'LCOPY';
        $A1:S:=S+'CALLS';
        $A2,$A3,$A4,$A6:S:=S+'---';
        $A5:S:=S+'PCOPY';
        $A7:S:=S+'LOCK';
        $A8:S:=S+'UNLOCK';
        Else S:=S+Char(Buffer[0]);
       End;
      End;
      $FF:Begin
       BlockRead(Source,Buffer,1,ByteReaded);
       Case Buffer[0]of
        $81:S:=S+'LEFT$';
        $82:S:=S+'RIGHT$';
        $83:S:=S+'MID$';
        $84:S:=S+'SGN';
        $85:S:=S+'INT';
        $86:S:=S+'ABS';
        $87:S:=S+'SQR';
        $88:S:=S+'RND';
        $89:S:=S+'SIN';
        $8A:S:=S+'LOG';
        $8B:S:=S+'EXP';
        $8C:S:=S+'COS';
        $8D:S:=S+'TAN';
        $8E:S:=S+'ATN';
        $8F:S:=S+'FRE';
        $90:S:=S+'INP';
        $91:S:=S+'POS';
        $92:S:=S+'LEN';
        $93:S:=S+'STR$';
        $94:S:=S+'VAL';
        $95:S:=S+'ASC';
        $96:S:=S+'CHR$';
        $97:S:=S+'PEEK';
        $98:S:=S+'SPACE$';
        $99:S:=S+'OCT$';
        $9A:S:=S+'HEX$';
        $9B:S:=S+'LPOS';
        $9C:S:=S+'CINT';
        $9D:S:=S+'CSNG';
        $9E:S:=S+'CDBL';
        $9F:S:=S+'FIX';
        $A0:S:=S+'PEN';
        $A1:S:=S+'STICK';
        $A2:S:=S+'STRIG';
        $A3:S:=S+'EOF';
        $A4:S:=S+'LOC';
        $A5:S:=S+'LOF';
        Else S:=S+Char(Buffer[0]);
       End;
      End;
      Else S:=S+Char(Buffer[0]);
     End;
     If B<>0Then NewLine:=False;
     LastB:=B;
    Until EOF(Source);
    Close(Source);
   End;
   Else Begin
    Close(Source);
    LoadBASIC:=False;
   End;
  End;
 End;

Begin
 If GetSeparator='"'Then Begin
  FileName:=GetStringValue;
  If FileName<>''Then Begin
   If StrToUpper(Copy(FileName,Length(FileName)-3,4))<>'.BAS'Then FileName:=FileName+'.BAS';
   If Not LoadBASIC(FileName)Then Begin
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
      WriteLn('Manque de mÇmoire');
      Break;
     End;
    End;
    Close(FileLoad);
   End;
   ResortList;
  End
   Else
  WriteLn('Nom du fichier absent');
 End
  Else
 WriteLn('Chaine de caractäres attendu');
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

Function NextCommand:Boolean;
Var
 NextCurrPos,NextCurrLinePtr,NextCurrNumberLine:Word;
 R2:Real;
Begin
 NextCommand:=False;
 If ForPos=0 Then Begin
  WriteLn('NEXT sans FOR');
  Exit;
 End;
 NextCurrPos:=CurrPos;
 NextCurrLinePtr:=CurrLinePtr;
 NextCurrNumberLine:=CurrNumberLine;
 CurrPos:=ForStack[ForPos].Col;
 CurrLinePtr:=ForStack[ForPos].Line;
 CurrLine:=PA[CurrLinePtr]^;
 CurrNumberLine:=ForStack[ForPos].LineNumber;
 SetVariableReal(ForStack[ForPos].VarName,GetVariableReal(ForStack[ForPos].VarName)+1);
 R2:=GetNumberValue(1);
 If GetVariableReal(ForStack[ForPos].VarName)>R2 Then Begin
  CurrPos:=NextCurrPos;
  CurrLinePtr:=NextCurrLinePtr;
  CurrNumberLine:=NextCurrNumberLine;
  CurrLine:=PA[CurrLinePtr]^;
  Dec(ForPos);
 End;
 NextCommand:=True;
End;

Procedure PrintCommand;
Var
 R:Real;
Begin
 SkipSpace;
 Begin
  If IsStringValue Then Begin
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

Procedure ReturnCommand;Begin
 If(GosubPos=0)Then Begin
  WriteLn('RETURN sans GOSUB');
  Exit;
 End;
 CurrPos:=GosubStack[GosubPos].Col;
 CurrLinePtr:=GosubStack[GosubPos].Line;
 CurrLine:=PA[CurrLinePtr]^;
 CurrNumberLine:=GosubStack[GosubPos].LineNumber;
 Dec(GosubPos);
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
   If CurrLine<>''Then Begin
    If Not RunBasic(True)Then Break;
   End;
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

Procedure ScreenCommand;
Var
 Screen:Real;
 Driver,Mode:Integer;
 ErrCode:Integer;
Begin
 Screen:=GetNumberValue(1);
 Case Trunc(Screen)of
  0:Begin
   CloseGraph;
   InGraph:=False;
  End;
  Else Begin
   InGraph:=True;
   {$IFDEF FPC}
    Driver:=VGA;
    Mode:=VGAHi;
   {$ELSE}
    Driver:=Detect;
    Mode:=VGAHi;
   {$ENDIF}
    InitGraph(Driver,Mode,'');
    ErrCode:=GraphResult;
    If ErrCode=grOk Then Begin
    SetColor(White);
    SetLineStyle(0, 0, 1);
   End
    Else
   Begin
    WriteLn('Erreur graphique : ',GraphErrorMsg(ErrCode));
    Halt;
   End;
  End;
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

Procedure ReadLine(Var S:String);
Var
 K:Char;
 Y:Byte;
Begin
 Y:=WhereY;
 S:='';
 Repeat
  GotoXY(1,Y);
  Write(S);
  ClrEol;
  K:=ReadKey;
  Case K of
   #0:Case ReadKey of
    #59:S:=S+FunctionKeyList[1]; { F1 }
    #60:S:=S+FunctionKeyList[2]; { F2 }
    #61:S:=S+FunctionKeyList[3]; { F3 }
    #62:S:=S+FunctionKeyList[4]; { F4 }
    #63:S:=S+FunctionKeyList[5]; { F5 }
    #64:S:=S+FunctionKeyList[6]; { F6 }
    #65:S:=S+FunctionKeyList[7]; { F7 }
    #66:S:=S+FunctionKeyList[8]; { F8 }
    #67:S:=S+FunctionKeyList[9]; { F9 }
    #68:S:=S+FunctionKeyList[10]; { F10 }
   End;
   #8:Begin
    If S<>''Then S:=Copy(S,1,Length(S)-1);
   End;
   Else S:=S+K;
  End;
  If S[Length(S)]=#13Then Begin
   S:=Copy(S,1,Length(S)-1);
   K:=#13;
  End;
 Until K=#13;
 GotoXY(1,Y);
 WriteLn(S);
End;

Function RunBasic(InList:Boolean):Boolean;
Var
 UnknownCommand:Boolean;
 NoImplementation:Boolean;
 J,Err:Integer;
 R1:Real;
 S1:String;
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
 SkipSpace;
 If CurrLine[CurrPos]=''''Then Begin
  { C'est un commentaire, on est fait rien }
 End
  Else
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
   9: CircleCommand;{CIRCLE}
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
   25: Exit;{END}
   26: NoImplementation:=True;{ERASE}
   27: NoImplementation:=True;{ERROR}
   28: NoImplementation:=True;{FIELD}
   29: FilesCommand;{FILES}
   30: If Not(ForCommand)Then Exit;{FOR}
   31: NoImplementation:=True;{GET}
   32: If Not(GosubCommand)Then Exit;{GOSUB}
   33: If Not(GotoCommand)Then Exit;{GOTO}
   34: HelpCommand;{HELP}
   35: IfCommand;{IF}
   36: NoImplementation:=True;{INPUT}
   37: KeyCommand;{KEY}
   38: NoImplementation:=True;{KILL}
   39: NoImplementation:=True;{LET}
   40: LineCommand;{LINE}
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
   51: If Not(NextCommand)Then Exit;{NEXT}
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
   72: ReturnCommand;{RETURN}
   73: RmDirCommand;{RMDIR}
   74: NoImplementation:=True;{RSET}
   75: RunCommand;{RUN}
   76: SaveCommand;{SAVE}
   77: ScreenCommand;{SCREEN}
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
     '$':Begin
      Inc(CurrPos);
      S1:=GetStringValue;
      If VariableExist(CurrCommand)Then
       SetVariableString(CurrCommand,S1)
      Else
       AddVariableString(CurrCommand,S1);
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
   If(InList)Then WriteLn('Commande non reconnu Ö la ligne ',CurrNumberLine,': ',CurrCommand)
             Else WriteLn('Commande non reconnu');
   Exit;
  End;
  If(NoImplementation)Then Begin
   WriteLn('Cette commande n''a pas ÇtÇ implÇmentÇ : ',CurrCommand);
   Exit;
  End;
  While(CurrLine[CurrPos]in[' ',':'])and(CurrPos<=Length(CurrLine)) do Inc(CurrPos);
  If CurrPos>=Length(CurrLine)Then Break;
  If Not(CurrLine[CurrPos]in['A'..'Z','a'..'z','_'])Then Begin
   If(InList)Then WriteLn('Erreur de syntaxe Ö la position ',CurrPos,' de la ligne ',CurrNumberLine)
             Else WriteLn('Erreur de syntaxe Ö la position ',CurrPos);
   Exit;
  End;
 Until CurrPos>Length(CurrLine);
 RunBasic:=True;
End;

BEGIN
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ENDIF}
 {$ENDIF}
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('GWBASIC : Cette commande permet de lancer l''interpreteur de GWBASIC.');
  WriteLn;
  WriteLn('Syntaxe : GWBASIC [fichier]');
  WriteLn;
  WriteLn(' fichier   Ce paramätre permet d''indiquer le nom du fichier BASIC.');
 End
  Else
 If ParamStr(1)='--version'Then Begin
  WriteLn('GWBASIC ',Version,' - Clone Pascal de corail, MS-DOS-0, GWBASIC-0');
  WriteLn('Licence MIT');
  WriteLn;
  WriteLn('êcrit par Sylvain Maltais');
 End
  Else
 Begin
  FileName:='';
  FunctionKeyList[1]:='LIST ';
  FunctionKeyList[2]:='RUN'#13;
  FunctionKeyList[3]:='LOAD"';
  FunctionKeyList[4]:='SAVE"';
  FunctionKeyList[5]:='CONT'#13;
  FunctionKeyList[6]:=',"LPT1';
  FunctionKeyList[7]:='TRON'#13;
  FunctionKeyList[8]:='TROFF'#13;
  FunctionKeyList[9]:='KEY ';
  FunctionKeyList[10]:='SCREEN';
  InGraph:=False;
  Tron:=False;KeyFunction:=True;
  NumberLine:=0;CurrNumberLine:=0;
  NumberVariable:=0;GosubPos:=0;ForPos:=0;
  For I:=1 to ParamCount do Begin
   FileName:=ParamStr(I);
  End;
  HomeMessage;
  If FileName<>''Then Begin
   CurrLine:='LOAD "'+FileName+'":RUN';
   RunBasic(False);
  End;
  Terminated:=False;
  LineEmpty:=False;
  Repeat
   If Not(LineEmpty)Then WriteLn('Ok');
   ReadLine(CurrLine);
   LineEmpty:=CurrLine='';
   If CurrLine=''Then LineEmpty:=True Else
   If(IsNumberWord(Trim(CurrLine)))Then Begin { Supprime un numÇro de ligne ? }
    CurrPos:=1;
    CurrLine:=Trim(CurrLine);
    DeleteLineNumber(ReadInteger);
   End
    Else
   Begin
    CurrLine:=LTrim(CurrLine);
    RunBasic(False);
   End;
  Until Terminated;
  If(InGraph)Then CloseGraph;
  Window(1,1,80,25);
  ClrScr;
 End;
END.
