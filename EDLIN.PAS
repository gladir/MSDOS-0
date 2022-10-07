{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program EDLIN;

Uses Crt,DOS,Strings;

Const
 CommandList:Array[0..12]of String[16]=(
  'A','C','D','E','I','L','M','P','Q','R','S','T','W'
 );

Type

 PCharByteRec = Record
  PChr:PChar;
  Nm:Byte;
 End;

 StrByteRec = Record
  PChr:PChar;
  Nm:Byte;
  Len:Word;
 End;

 StrWordRec = Record
  PChr:PChar;
  Nm,Len:Word;
 End;

 PCharWordRec = Record
  PChr:PChar;
  Nm:Word;
 End;

 RBufPtr = ^RBufRec;

 RBufRec = Record
  Buf:Pointer;
  Size:Word;
  Previous,Next:RBufPtr;
 End;

 ArrayList = Record
  PCurrPtr,Count:LongInt;
  CurrPtr,List,EndListPtr:RBufPtr;
 End;

Const
 MinRec=SizeOf(PCharWordRec)+1;

Function MaxAvail:LongInt;Begin
 MaxAvail:=High(LongInt);
End;

Function MemAlloc(Size:Word):Pointer;
Var Ptr:Pointer;
Begin
 MemAlloc := NIL;
 If(Size = 0)Then Exit;
 If(MaxAvail < Size)Then Exit;
 GetMem(Ptr,Size);
 MemAlloc := Ptr;
End;

Function MemNew(Size:Word):Pointer;
Var
 Ptr:Pointer;
Begin
 Ptr:=MemAlloc(Size);
 If(Ptr<>NIL)Then FillChar(Ptr^,Size,0);
 MemNew:=Ptr;
End;

Function NewBlock(Var Buf;Size:Word):Pointer;
Var
 Ptr:Pointer;
Begin
 Ptr:=MemAlloc(Size);
 If(Ptr<>NIL)Then Move(Buf,Ptr^,Size);
 NewBlock:=Ptr;
End;

Procedure ArrayListInit(Var Q:ArrayList);Begin
 Q.PCurrPtr := -1;
 Q.CurrPtr := NIL;
 Q.List := NIL;
 Q.EndListPtr := NIL;
 Q.Count := 0;
End;

Function ArrayListIsEmpty(Var Q:ArrayList):Boolean;
Begin
 ArrayListIsEmpty := (Q.List = NIL);
End;

Function ArrayListAdd(Var Q:ArrayList;Size:Word):Pointer;
Var
 W:RBufRec;
 WPtr:RBufPtr;
 Addr:Pointer;
Begin
 ArrayListAdd:=NIL;
 FillChar(W,SizeOf(W),0);
 If Size>0Then Begin
  Addr:=MemAlloc(Size);
  If(Addr=NIL)Then Exit;
  W.Buf:=Addr;
  W.Size:=Size
 End;
 If(Q.List=NIL)Then Begin
  Q.List:=NewBlock(W,SizeOf(RBufRec));
  If(Q.List=NIL)Then Exit;
  Q.EndListPtr:=Q.List
 End
  Else
 Begin
  WPtr:=Q.EndListPtr;
  If(WPtr=NIL)Then Exit;
  W.Previous:=WPtr;
  WPtr^.Next:=NewBlock(W,SizeOf(RBufRec));
  Q.EndListPtr:=WPtr^.Next;
 End;
 Inc(Q.Count);
 ArrayListAdd:=Addr
End;

Function ArrayListAddBuf(Var Q:ArrayList;Size:Word;Const Block):Boolean;
Var
 Ptr:Pointer;
Begin
 ArrayListAddBuf:=False;
 Ptr:=ArrayListAdd(Q,Size);
 If(Ptr<>NIL)Then Begin
  Move(Block,Ptr^,Size);
  ArrayListAddBuf:=True;
 End;
End;

Function ArrayList_AddBuf(Var Q:ArrayList;Size:Word):Pointer;
Var Ptr:Pointer;
Begin
 ArrayList_AddBuf := NIL;
 If Not(ArrayListAddBuf(Q,Size,Ptr))Then Exit;
 ArrayList_AddBuf := Ptr;
End;

Function ArrayList_SetPtr(Var Q:ArrayList;P:LongInt):Pointer;
Var
 WP:RBufPtr;
 I:LongInt;
Begin
 WP:=Q.List;
 For I:=1to(P)do Begin
  WP:=WP^.Next;
  If(WP=NIL)Then Begin
   ArrayList_SetPtr:=NIL;
   Exit;
  End;
 End;
 ArrayList_SetPtr:=WP
End;


Function ArrayListIns(Var Q:ArrayList;P:LongInt;Size:Word):Pointer;
Var
 WP,NewP:RBufPtr;
 Addr:Pointer;
Begin
 ArrayListIns:=NIL;
 If(P>Q.Count)Then Exit;
 If(P=Q.Count)Then ArrayListIns:=ArrayListAdd(Q,Size)
  else
 Begin
  Addr:=NIL;
  If P=0Then Begin
   WP:=MemNew(SizeOf(Q.List^));
   If(WP=NIL)Then Exit;
   Q.List^.Previous:=WP;WP^.Next:=Q.List;
   If Size>0Then Begin
    Addr:=MemAlloc(Size);
    If(Addr=NIL)Then Exit;
    WP^.Buf:=Addr;WP^.Size:=Size
   End;
   Q.List:=WP
  End
   else
  Begin
   NewP:=MemNew(SizeOf(Q.List^));
   If(NewP=NIL)Then Exit;
   WP:=ArrayList_SetPtr(Q,P);
   If(WP=NIL)Then Exit;
   NewP^.Next:=WP;
   NewP^.Previous:=WP^.Previous;
   If Size>0Then Begin
    Addr:=MemAlloc(Size);
    If(Addr=NIL)Then Exit;
    NewP^.Buf:=Addr;
    NewP^.Size:=Size
   End;
   WP^.Previous^.Next:=NewP;
   WP^.Previous:=NewP
  End;
  Inc(Q.Count);
  ArrayListIns:=Addr
 End
End;

Function ArrayListInsBlock(Var Q:ArrayList;P:LongInt;Size:Word;Const Block):Boolean;
Var
 Ptr:Pointer;
Begin
 ArrayListInsBlock:=False;
 Ptr:=ArrayListIns(Q,P,Size);
 If(Ptr<>NIL)Then Begin
  Move(Block,Ptr^,Size);
  ArrayListInsBlock:=True;
 End;
End;


Function ArrayListInsBuf(Var Q:ArrayList;P:LongInt;Size:Word;Var Addr:Pointer):Boolean;
Var WP,NewP:RBufPtr; I:LongInt;
Begin
 ArrayListInsBuf := False;
 If(P > Q.Count)Then Exit;
 If(P = Q.Count)Then ArrayListInsBuf := ArrayListAddBuf(Q,Size,Addr)
  else
 Begin
  ArrayListInsBuf := False;
  If(P = 0)Then
  Begin
   WP := MemAlloc(SizeOf(Q.List^));
   If(WP = NIL)Then Exit;
   Q.List^.Previous := WP; WP^.Previous := NIL; WP^.Next := Q.List;
   If(Size = 0)Then
   Begin
    WP^.Buf := NIL; WP^.Size := 0; Addr := NIL;
   End
    Else
   Begin
    Addr := MemAlloc(Size);
    If(Addr = NIL)Then Exit;
    WP^.Buf := Addr; WP^.Size := Size;
   End;
   Q.List := WP;
  End
   else
  Begin
   NewP := MemAlloc(SizeOf(Q.List^));
   If(NewP = NIL)Then Exit;
   WP := Q.List;
   For I := 1 to P do
   Begin
    If(WP = NIL)Then Exit;
    WP := WP^.Next;
   End;
   NewP^.Next := WP; NewP^.Previous := WP^.Previous;
   If(Size = 0)Then
   Begin
    NewP^.Buf := NIL; NewP^.Size := 0; Addr := NIL;
   End
    Else
   Begin
    Addr := MemAlloc(Size);
    If(Addr = NIL)Then Exit;
    NewP^.Buf := Addr; NewP^.Size := Size;
   End;
   WP^.Previous^.Next := NewP; WP^.Previous := NewP;
  End;
  Inc(Q.Count); ArrayListInsBuf := True;
 End;
End;

Function ArrayListAddPChr(Var Q:ArrayList;PChr:PChar):Boolean;
Type
 TChar=Array[0..32767]of Char;
Var
 PBuf:^TChar;
 L:Word;
Begin
 ArrayListAddPChr:=False;
 L:=StrLen(PChr)+1;
 PBuf:=ArrayListAdd(Q,L);
 If(PBuf=NIL)Then Exit;
 If L=1Then PBuf^[0]:=#0
       Else Move(PChr^,PBuf^,L);
 ArrayListAddPChr:=True
End;

Function ArrayListAddPChrByte(Var Q:ArrayList;PChr:PChar;Num:Byte):Boolean;
Var PCharByte:^PCharByteRec; Ptr:Pointer;
Begin
 ArrayListAddPChrByte := False;
 If Not(ArrayListAddBuf(Q,SizeOf(PCharByteRec),Ptr))Then Exit;
 PCharByte := Ptr; PCharByte^.PChr := PChr; PCHarByte^.Nm := Num;
 ArrayListAddPChrByte := True;
End;

Function ArrayListAddStrByte(Var Q:ArrayList;Str:String;Num:Byte):Boolean;
Var StrByte:^StrByteRec; Ptr:Pointer; PChr:Array[0..255] of Char;
Begin
 ArrayListAddStrByte := False;
 If Not(ArrayListAddBuf(Q,SizeOf(StrByteRec),Ptr))Then Exit;
 StrByte := Ptr; StrPCopy(PChr,Str); StrByte^.PChr := StrNew(PChr);
 StrByte^.Len := Length(Str); StrByte^.Nm := Num; ArrayListAddStrByte := True;
End;

Function ArrayListAddStrWord(Var Q:ArrayList;Str:String;Num:Word):Boolean;
Var StrWord:^StrWordRec; Ptr:Pointer; PChr:Array[0..255] of Char;
Begin
 ArrayListAddStrWord := False;
 If Not(ArrayListAddBuf(Q,SizeOf(StrWordRec),Ptr))Then Exit;
 StrWord := Ptr; StrPCopy(PChr,Str); StrWord^.PChr := StrNew(PChr);
 StrWord^.Len := Length(Str); StrWord^.Nm := Num; ArrayListAddStrWord := True;
End;

Function ArrayListAddLn(Var Q:ArrayList):Boolean;
Begin
 ArrayListAddLn := ArrayListAddPChr(Q,NIL);
End;

Function ArrayListAddStr(Var Q:ArrayList;Const Str:String):Boolean;
Var
 Ptr:Pointer;
 PC:PChar Absolute Ptr;
 Size:Word;
Begin
 If Length(Str)=0Then ArrayListAddStr:=ArrayListAddLn(Q)
  Else
 Begin
  ArrayListAddStr:=False;
  Size:=Length(Str)+1;
  If(Size<MinRec)Then Size:=MinRec;
  Ptr:=ArrayListAdd(Q,Size);
  If(Ptr=NIL)Then Exit;
  StrPCopy(PC,Str);
  ArrayListAddStr:=True
 End;
End;

Function ArrayListInsStr(Var Q:ArrayList;P:LongInt;Str:String):Boolean;
Var Ptr:Pointer; PChr:PChar; Size:Word;
Begin
 ArrayListInsStr := False; Size := Length(Str)+1;
 If(Size < 32)Then Size := 32;
 If Not(ArrayListInsBuf(Q,P,Size,Ptr))Then Exit;
 If(Ptr = NIL)Then Exit;
 PChr := Ptr; StrPCopy(PChr,Str); ArrayListInsStr := True;
End;

Function ArrayListInsStrWord(Var Q:ArrayList;P:LongInt;Str:String;Num:Word):Boolean;
Var StrWord:^StrWordRec; Ptr:Pointer; PChr:Array[0..255] of Char;
Begin
 ArrayListInsStrWord := False;
 If Not(ArrayListInsBuf(Q,P,SizeOf(StrWordRec),Ptr))Then Exit;
 StrWord := Ptr; StrPCopy(PChr,Str);
 StrWord^.PChr := StrNew(PChr); StrWord^.Len := Length(Str);
 StrWord^.Nm := Num; ArrayListInsStrWord := True;
End;

Function ArrayListAddPChrWord(Var Q:ArrayList;PChr:PChar;Num:Word):Boolean;
Var PCharWord:^PCharWordRec; Ptr:Pointer;
Begin
 ArrayListAddPChrWord := False;
 If Not(ArrayListAddBuf(Q,SizeOf(PCharWordRec),Ptr))Then Exit;
 PCharWord := Ptr; PCharWord^.PChr := PChr;
 PCHarWord^.Nm := Num; ArrayListAddPChrWord := True;
End;

Function ArrayListGetBuf(Var Q:ArrayList;P:LongInt;Var Size:Word):Pointer;
Var WP:RBufPtr; I:LongInt;
Begin
 Size := 0; ArrayListGetBuf := Nil;
 If(P < 0)or(P >= Q.Count)Then Exit;
 If(P = 0)Then
 Begin
  ArrayListGetBuf := Q.List^.Buf; Size := Q.List^.Size;
 End
  Else
 Begin
  WP := Q.List;
  For I := 1 to P do
  Begin
   If(WP = NIL)Then Exit;
   WP := WP^.Next;
  End;
  If(WP = NIL)Then Exit;
  ArrayListGetBuf := WP^.Buf; Size := WP^.Size;
 End;
End;

Procedure ArrayListPrevious(Var Q:ArrayList);Begin
 If Not(Q.CurrPtr = NIL)Then
 Begin
  Q.CurrPtr := Q.CurrPtr^.Previous;
  Dec(Q.PCurrPtr);
 End;
End;

Procedure ArrayListNext(Var Q:ArrayList);Begin
 If Not(Q.CurrPtr = NIL)Then
 Begin
  Q.CurrPtr := Q.CurrPtr^.Next;
  Inc(Q.PCurrPtr);
 End;
End;

Procedure ArrayListSetPtr(Var Q:ArrayList;P:LongInt);
Var WP:RBufPtr; I:LongInt;
Begin
 If(P = 0)Then
 Begin
  Q.PCurrPtr := 0; Q.CurrPtr := Q.List;
 End
  else
 If Not(Q.PCurrPtr = P)Then
 Begin
  If(Q.PCurrPtr - 1 = P)Then ArrayListPrevious(Q) else
  If(Q.PCurrPtr + 1 = P)Then ArrayListNext(Q)
   else
  Begin
   WP := Q.List;
   If(P > 0)Then For I := 1 to P do
   Begin
    If(WP = NIL)Then Exit;
    WP := WP^.Next;
   End;
   If(WP = NIL)Then Exit;
   Q.PCurrPtr := P;
   Q.CurrPtr  := WP;
  End;
 End;
End;

Function ArrayList_GetCurrBuf(Var Q:ArrayList):Pointer;Begin
 If(Q.CurrPtr = NIL)Then ArrayList_GetCurrBuf := NIL Else ArrayList_GetCurrBuf := Q.CurrPtr^.Buf;
End;

Function ArrayListGetCurrBuf(Var Q:ArrayList;Var Size:Word):Pointer;Begin
 If(Q.CurrPtr = NIL)Then
 Begin
  ArrayListGetCurrBuf := NIL; Size := 0;
 End
  Else
 Begin
  ArrayListGetCurrBuf := Q.CurrPtr^.Buf; Size := Q.CurrPtr^.Size;
 End;
End;

Function ArrayList_GetBuf(Var Q:ArrayList;P:LongInt):Pointer;
Var Size:Word;
Begin
 ArrayList_GetBuf := ArrayListGetBuf(Q,P,Size);
End;

Function ArrayListGetCurrStr(Var Q:ArrayList):String;Begin
 ArrayListGetCurrStr := StrPas(ArrayList_GetCurrBuf(Q));
End;

Function ArrayList_GetStr(Var Q:ArrayList;P:LongInt):String;Begin
 ArrayList_GetStr := StrPas(ArrayList_GetBuf(Q,P));
End;

Function ArrayListRemoveAt(Var Q:ArrayList;P:LongInt):Boolean;
Var WP:RBufPtr; I:LongInt;
Begin
 ArrayListRemoveAt := False;
 If(Q.Count = 0)or(P < 0)or(P >= Q.Count)Then Exit;
 If(P = 0)Then
 Begin
  If(Q.List = NIL)Then Exit;
  WP := Q.List;
  FreeMem(WP^.Buf,WP^.Size);
  FreeMem(WP,SizeOf(WP^));
  If(Q.Count > 1)Then
  Begin
   If(Q.List^.Next = NIL)Then Exit;
   WP^.Next^.Previous := NIL; Q.List := Q.List^.Next; Q.CurrPtr := NIL;
   Q.PCurrPtr := -1; Dec(Q.Count); ArrayListRemoveAt := True;
   Exit;
  End
   else
  Begin
   Q.PCurrPtr := -1; Q.CurrPtr := NIL; Q.List := NIL; Q.EndListPtr := NIL;
   Q.Count := 0; ArrayListRemoveAt := True;
   Exit;
  End;
 End
  else
 Begin
  WP := Q.List;
  For I := 1 to P do
  Begin
   If(WP = NIL)Then Exit;
   WP := WP^.Next;
  End;
  If(WP = NIL)Then Exit;
  If(Q.Count - 1 = P)Then
  Begin
   Q.EndListPtr := WP^.Previous; WP^.Previous^.Next := NIL;
  End
   Else
  Begin
   WP^.Next^.Previous := WP^.Previous; WP^.Previous^.Next := WP^.Next;
  End;
  FreeMem(WP^.Buf,WP^.Size);
  FreeMem(WP,SizeOf(Q.List^));
  Dec(Q.Count);
  ArrayListRemoveAt := True;
 End;
End;

Function ArrayListSetBuf(Var Q:ArrayList;P:LongInt;Size:Word;Var Addr:Pointer):Boolean;
Var WP:RBufPtr; I:LongInt;
Begin
 ArrayListSetBuf := False;
 If(P < 0)or(P > Q.Count)Then Exit;
 If(P = Q.Count)Then
 Begin
  ArrayListSetBuf := ArrayListAddBuf(Q,Size,Addr);
  Exit;
 End;
 If(P = 0)Then
 Begin
  FreeMem(Q.List^.Buf,Q.List^.Size);
  If(Size = 0)Then
  Begin
   Q.List^.Buf := NIL; Q.List^.Size := 0;
  End
   Else
  Begin
   Addr := MemAlloc(Size);
   If(Addr = NIL)Then Exit;
   Q.List^.Buf := Addr; Q.List^.Size := Size;
  End;
  ArrayListSetBuf := True;
  Exit;
 End;
 WP := Q.List;
 For I := 1 to P do
 Begin
  If(WP = NIL)Then Exit;
  WP := WP^.Next;
 End;
 FreeMem(WP^.Buf,WP^.Size);
 If(Size = 0)Then
 Begin
  WP^.Buf := NIL; WP^.Size := 0;
 End
  Else
 Begin
  Addr := MemAlloc(Size);
  If(Addr = NIL)Then Exit;
  WP^.Buf := Addr; WP^.Size := Size;
 End;
 ArrayListSetBuf := True;
End;

Function ArrayList_SetBuf(Var Q:ArrayList;P:LongInt;Size:Word):Pointer;
Var Ptr:Pointer;
Begin
 ArrayList_SetBuf := NIL;
 If Not(ArrayListSetBuf(Q,P,Size,Ptr))Then Exit;
 ArrayList_SetBuf := Ptr;
End;

Function ArrayListCount(Var Q:ArrayList):LongInt;Begin
 ArrayListCount := Q.Count;
End;

Function ArrayListMaxList(Var Q:ArrayList):LongInt;Begin
 ArrayListMaxList := Q.Count - 1;
End;

Procedure ArrayListPopCurrPtr(Var Q:ArrayList;Addr:Pointer);Begin
 Q.CurrPtr:=Addr;
End;

Procedure ArrayListDone(Var Q:ArrayList);
Var WP:RBufPtr; Ptr:^StrByteRec;
Begin
 WP := Q.List;
 While Not(WP = NIL) do
 Begin
  If(WP^.Size = SizeOf(StrByteRec))Then
  Begin
   Ptr := WP^.Buf;
   StrDispose(Ptr^.PChr);
  End;
  FreeMem(WP^.Buf,WP^.Size);
  FreeMem(WP,SizeOf(RBufRec));
  WP := WP^.Next;
 End;
End;

Var
 Language:(_French,_English,_Germany,_Italian,_Spain);
 TmpLanguage:String;
 CommandFound,Terminated:Boolean;
 CmdStr:String;
 CurrCommand,ParamList:String;
 List:ArrayList;
 I:Integer;
 P:LongInt;
 PX:LongInt;
 J,X,Y:Byte;
 InsMode,Modified:Boolean;
 CurrPtr:Pointer;
 FileName:String;

Function RTrim(s:String):String;
Var
 i:Integer;
Begin
 i:=Length(s);
 While (i>0)and(s[i]in[#9,' '])do Dec(i);
 s[0]:=Chr(i);
 RTrim:=S;
End;


Function LTrim(S:String):String;
Var
 I:Byte;
Begin
 For I:=1to Length(S)do Begin
  If S[I]<>' 'Then Begin
   LTrim:=Copy(S,I,255);
   Exit;
  End;
 End;
 LTrim:=S;
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

Procedure LoadText(FileName:String);
Var
 TextFile:Text;
 CurrLine:String;
Begin
 Assign(TextFile,FileName);
 {$I-}Reset(TextFile);{$I+}
 If IOResult=0Then Begin
  While Not EOF(TextFile) do Begin
   ReadLn(TextFile,CurrLine);
   ArrayListAddStr(List,CurrLine);
  End;
  Close(TextFile);
 End;
End;

Procedure SaveText(FileName:String);
Var
 TextFile:Text;
 CurrLine:String;
 I:LongInt;
Begin
 Assign(TextFile,FileName);
 Rewrite(TextFile);
 If Not ArrayListIsEmpty(List)Then Begin
  ArrayListSetPtr(List,0);
  For I:=1 to ArrayListCount(List)do Begin
   CurrLine:=ArrayListGetCurrStr(List);
   WriteLn(TextFile,CurrLine);
   ArrayListNext(List);
  End;
 End;
 Close(TextFile);
End;

Function TEPopCurr:PChar;Begin
 ArrayListPopCurrPtr(List,CurrPtr);
 TEPopCurr:=ArrayList_GetCurrBuf(List)
End;

Procedure ShowPrompt;Begin
 Write('*');
End;

Procedure ExtractCommand;
Var
 I:Byte;
Begin
 CurrCommand:='';
 ParamList:='';
 For I:=1 to Length(CmdStr)do Begin
  If(CmdStr[I]in['A'..'Z','a'..'z'])Then Begin
   CurrCommand:=StrToUpper(Copy(CmdStr,I,255));
   ParamList:=RTrim(LTrim(Copy(CmdStr,1,I-1)));
   Exit;
  End;
 End;
 ParamList:=CmdStr;
End;

Procedure ACommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure CCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure DCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure ECommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure ICommand;
Var
 Value:LongInt;
 Err:Word;
 CurrLine:String;
Begin
 If ParamList<>''Then Begin
  Val(ParamList,Value,Err);
  If Err>0Then WriteLn('Numero de ligne invalide');
  If Value>=List.Count Then WriteLn('La ligne n''existe pas')Else
  If Value=0Then WriteLn('La ligne doit etre superieur a 0')
   Else
  Begin
   P:=Value-1;
   ArrayListSetPtr(List,P);
  End;
 End;
 Repeat
  Write(' ':5,P+1,':');
  ReadLn(CurrLine);
  If CurrLine<>^Z Then Begin
   If P<List.Count Then Begin
     If Not ArrayListInsStr(List,P,CurrLine)Then Begin
      WriteLn('Manque de memoire');
     End;
   End
    Else
   ArrayListAddStr(List,CurrLine);
   Inc(P);
  End;
  If CurrLine=#3Then Break;
 Until CurrLine=^Z;
End;

Procedure LCommand;
Var
 I:LongInt;
 CurrLine:String;
Begin
 ArrayListSetPtr(List,0);
 If Not ArrayListIsEmpty(List)Then For I:=0 to ArrayListMaxList(List) do Begin
  CurrLine:=ArrayListGetCurrStr(List);
  WriteLn(' ':5,I+1,':',CurrLine);
  ArrayListNext(List);
 End;
End;

Procedure MCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure PCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure QCommand;Begin
 Write('Annule l''edition (O/N) ?');
 If ReadKey in['Y','y','O','o']Then Begin
  WriteLn('Oui');
  Terminated:=True;
 End
   Else
 WriteLn('Non');
End;

Procedure RCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure SCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure TCommand;Begin
 WriteLn('Cette commande n''est pas mise en oeuvre');
End;

Procedure WCommand;Begin
 SaveText(FileName);
End;

Procedure EditLineCommand;
Var
 Value:LongInt;
 Err:Word;
 Ptr:PChar;
 CurrLine:String;
Begin
 Val(ParamList,Value,Err);
 If Err>0Then WriteLn('Numero de ligne invalide');
 If Value>=List.Count Then WriteLn('La ligne n''existe pas')Else
  If Value=0Then WriteLn('La ligne doit etre superieur a 0')
  Else
 Begin
  P:=Value-1;
  ArrayListSetPtr(List,P);
  CurrLine:=ArrayListGetCurrStr(List);
  WriteLn(' ':5,Value,':',CurrLine);
  Write(' ':5,Value,':');
  ReadLn(CurrLine);
  Ptr:=ArrayList_SetBuf(List,P,Length(CurrLine)+1);
  StrPCopy(Ptr,CurrLine);
  Inc(P);
 End;
End;

Procedure UnknownCommand;Begin
 WriteLn('Commande non reconnu');;
 WriteLn;
End;

BEGIN
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ENDIF}
 {$ENDIF}
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
    WriteLn('Startet den EDLIN, der ASCII-Dateien erzeugt und ver„ndert.');
    WriteLn;
    WriteLn('EDLIN');
   End;
   Else Begin
    WriteLn('EDLIN : Cette commande permet d''editer un fichier texte ASCII.');
    WriteLn;
    WriteLn('Syntaxe : EDLIN [nomdufichier]');
   End;
  End;
 End
  Else
 Begin
  Modified:=False;
  InsMode:=True;
  P:=0;PX:=0;
  X:=0;Y:=0;
  FileName:='';
  For I:=1 to ParamCount do Begin
   FileName:=ParamStr(I);
  End;
  ArrayListInit(List);
  If FileName<>''Then Begin
   LoadText(FileName);
   P:=List.Count-1;
  End;
  Terminated:=False;
  Repeat
   ShowPrompt;
   ReadLn(CmdStr);
   ExtractCommand;
   CommandFound:=False;
   For J:=Low(CommandList) to High(CommandList) do Begin
    If CurrCommand=CommandList[J]Then Begin
     Case(J)of
      0:ACommand;
      1:CCommand;
      2:DCommand;
      3:ECommand;
      4:ICommand;
      5:LCommand;
      6:MCommand;
      7:PCommand;
      8:QCommand;
      9:RCommand;
      10:SCommand;
      11:TCommand;
      12:WCommand;
     End;
     If J<=High(CommandList)Then Begin
      CommandFound:=True;
      WriteLn;
      Break;
     End;
    End;
   End;
   If(ParamList<>'')and(CurrCommand='')Then EditLineCommand Else
   If Not(CommandFound)Then UnknownCommand;
  Until Terminated;
  ArrayListDone(List);
 End;
END.