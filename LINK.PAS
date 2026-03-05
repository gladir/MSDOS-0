{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program LINK;

{$A-}

Uses DOS;

Const
 MAX_SEGMENTS=128;            { Nombre maximal de segments suivis pendant l'edition de liens }
 MAX_SYMBOLS=1024;            { Nombre maximal de symboles (publics + externes) }
 MAX_RELOCATIONS=2048;        { Nombre maximal d'entrees de relocation en memoire }
 MAX_GROUPS=128;              { Nombre maximal de groupes OMF (GRPDEF) }
 MAX_LNAMES=2048;             { Nombre maximal de noms logiques LNAMES }
 MAX_LINENUMS=4096;           { Nombre maximal d'entrees de debug LINNUM }
 MAX_COMMENTS=2048;           { Nombre maximal d'enregistrements COMENT OMF }
 MAX_ALIASES=1024;            { Nombre maximal de definitions ALIAS }
 MAX_CMD_OBJS=256;            { Nombre maximal de fichiers objets en entree (phase 1) }
 MAX_CMD_LIBS=256;            { Nombre maximal de bibliotheques en entree (phase 1) }
 MAX_LIB_TRACKED_MODULES=256; { Modules de bibliotheque charges/suivis }

Type
 { En-tete DOS MZ du fichier executable genere }
 TExeHeader=Record
  Signature:Word;          { Signature DOS 'MZ' }
  LastPageBytes:Word;      { Nombre d'octets utilises dans la derniere page }
  PageCount:Word;          { Nombre total de pages de 512 octets dans l'EXE }
  RelocCount:Word;         { Nombre d'entrees de relocation }
  HeaderSize:Word;         { Taille de l'en-tete en paragraphes (16 octets) }
  MinAlloc:Word;           { Memoire minimale supplementaire demandee }
  MaxAlloc:Word;           { Memoire maximale supplementaire demandee }
  InitSS:Word;             { Valeur initiale de SS (relative au debut de chargement) }
  InitSP:Word;             { Valeur initiale de SP }
  Checksum:Word;           { Somme de controle (souvent 0 si non utilisee) }
  InitIP:Word;             { Valeur initiale de IP }
  InitCS:Word;             { Valeur initiale de CS (relative au debut de chargement) }
  RelocOffset:Word;        { Offset dans l'en-tete de la table de relocation }
  OverlayNumber:Word;      { Numero d'overlay (0 pour programme principal) }
 End;

   { Description d'un segment logique dans l'image liee }
 TSegment=Record
  Name:String[16];         { Nom logique du segment }
  Address:LongInt;         { Adresse/offset de base du segment dans l'image liee }
  Size:Word;               { Taille du segment en octets }
  Class:String[8];         { Classe du segment (CODE, DATA, etc.) }
 End;

   { Description d'un symbole resolu ou externe }
 TSymbol=Record
  Name:String[32];         { Nom du symbole }
  Segment:Word;            { Index du segment de definition (0 si externe) }
  Offset:Word;             { Offset du symbole dans son segment }
  IsExternal:Boolean;      { True si symbole externe non defini dans ce module }
 End;

   { Entree de relocation pour corriger une adresse a l'execution }
 TRelocation=Record
  Offset:Word;             { Offset MZ de la valeur a relocaliser }
  Segment:Word;            { Segment MZ (paragraphe) de la valeur a relocaliser }
  Target:Word;             { Reserve pour informations de cible/fixup }
 End;

 PSegment=^TSegment;
 PSymbol=^TSymbol;

 { Listes chainees des structures principales }
 PSegmentItem=^TSegmentItem;
 TSegmentItem=Record
  Value:TSegment;
  Next:PSegmentItem;
 End;

 PSymbolItem=^TSymbolItem;
 TSymbolItem=Record
  Value:TSymbol;
  Next:PSymbolItem;
 End;

 PRelocationItem=^TRelocationItem;
 TRelocationItem=Record
  Value:TRelocation;
  Next:PRelocationItem;
 End;

 PGroupMemberItem=^TGroupMemberItem;
 TGroupMemberItem=Record
  SegIndex:Word;
  Next:PGroupMemberItem;
 End;

 PGroupItem=^TGroupItem;
 TGroupItem=Record
  NameIndex:Word;
  Is32Bit:Boolean;
  MemberHead,MemberTail:PGroupMemberItem;
  MemberCount:Integer;
  Next:PGroupItem;
 End;

 PLNameItem=^TLNameItem;
 TLNameItem=Record
  Value:String[64];
  Next:PLNameItem;
 End;

 PLineInfoItem=^TLineInfoItem;
 TLineInfoItem=Record
  GroupIndex:Word;
  SegIndex:Word;
  LineNo:LongInt;
  CodeOffset:LongInt;
  Is32Bit:Boolean;
  Next:PLineInfoItem;
 End;

 PCommentItem=^TCommentItem;
 TCommentItem=Record
  Flags:Byte;
  ClassCode:Byte;
  Text:String[80];
  Next:PCommentItem;
 End;

 { Liste chainee des corrections OFFSET }
 POffsetPatchItem=^TOffsetPatchItem;
 TOffsetPatchItem=Record
  Pos:LongInt;
  Delta:Integer;
  Next:POffsetPatchItem;
 End;

 PBackPatchItem=^TBackPatchItem;
 TBackPatchItem=Record
  SegIndex:Word;
  LocType:Byte;
  PatchOffset:LongInt;
  PatchValue:LongInt;
  Is32Bit:Boolean;
  Next:PBackPatchItem;
 End;

 PAliasItem=^TAliasItem;
 TAliasItem=Record
  AliasName:String[64];
  SubstituteName:String[64];
  Next:PAliasItem;
 End;

 TObjRecBuffer=Array[0..8191] of Byte;
 TStr32=String[32];
 TStr64=String[64];
 TStr128=String[128];
 TCmdObjNameArray=Array[1..MAX_CMD_OBJS] of String[128];
 PCmdObjNameArray=^TCmdObjNameArray;
 TCmdLibNameArray=Array[1..MAX_CMD_LIBS] of String[128];
 PCmdLibNameArray=^TCmdLibNameArray;

Var
 ObjFile,ExeFile,MapFile:File;
 ExeHeader:TExeHeader;
 SegmentHead,SegmentTail:PSegmentItem;
 SymbolHead,SymbolTail:PSymbolItem;
 RelocationHead,RelocationTail:PRelocationItem;
 GroupHead,GroupTail:PGroupItem;
 LNameHead,LNameTail:PLNameItem;
 LineInfoHead,LineInfoTail:PLineInfoItem;
 CommentHead,CommentTail:PCommentItem;
 OffsetPatchHead,OffsetPatchTail:POffsetPatchItem;
 BackPatchHead,BackPatchTail:PBackPatchItem;
 AliasHead,AliasTail:PAliasItem;
 SegmentCount,SymbolCount,RelocationCount:Integer;
 GroupCount:Integer;
 LNameCount,LineInfoCount:Integer;
 CommentCount:Integer;
 OffsetPatchCount:Integer;
 BackPatchCount:Integer;
 AliasCount:Integer;
 HasEntryPoint:Boolean;
 EntrySegIndex:Word;
 EntryOffset:LongInt;
 StackSize:Word;
 ObjModuleName:String[64];
 ObjFileName,ExeFileName,MapFileName:String;  { Ajout des variables }
 ObjInputCount,LibInputCount:Integer;
 PrimaryObjInputCount:Integer;
 ObjInputList:PCmdObjNameArray;
 ObjSegBaseList:Array[1..MAX_CMD_OBJS] of Integer;
 LibInputList:PCmdLibNameArray;
 TempLibObjCount:Integer;
 TempLibObjList:PCmdObjNameArray;
 LoadedLibModuleCount:Integer;
 LoadedLibModuleLibIndex:Array[1..MAX_LIB_TRACKED_MODULES] of Integer;
 LoadedLibModuleStart:Array[1..MAX_LIB_TRACKED_MODULES] of LongInt;
 LoadedLibModuleName:Array[1..MAX_LIB_TRACKED_MODULES] of String[64];
 LibModulesScannedCount:LongInt;
 LibModulesLoadedCount:LongInt;
 LibResolutionPasses:Integer;
 TraceLibRequested:Boolean;
 TraceLibSymbolsRequested:Boolean;
 TraceLibNameFilter:String[128];
 TraceSymNameFilter:String[32];
 MapRequested:Boolean;
 LineNumbersRequested:Boolean;
 PublicsMapRequested:Boolean;
 NoDefaultLibrarySearch:Boolean;
 NoGroupAssociation:Boolean;
 NoIgnoreCase:Boolean;
 DosSegOrdering:Boolean;
 DsAllocateTop:Boolean;
 ExePackRequested:Boolean;
 HighLoadRequested:Boolean;
 PauseRequested:Boolean;
 OverlayInterruptSet:Boolean;
 OverlayInterruptValue:Byte;
 MaxAllocParagraphs:Word;
 MaxSegmentsOption:Integer;
 SpecField:Integer;
 SpecTerminated:Boolean;
 SpecCurrentItem:String[128];
 ResponseDepth:Integer;
 i:Integer;
 Param:string;
 Buffer:Array[0..1023] of Byte;  { Ajout du tampon manquant }

Procedure InitOffsetPatchList;
Begin
 OffsetPatchHead:=Nil;
 OffsetPatchTail:=Nil;
 OffsetPatchCount:=0;
End;

Procedure AddOffsetPatch(Const Pos:LongInt; Const Delta:Integer);
Var item:POffsetPatchItem;
Begin
 If OffsetPatchCount>=MAX_RELOCATIONS Then Begin
  WriteLn('Erreur : Trop de patchs OFFSET');
  Halt(15);
 End;
 New(item);
 item^.Pos:=Pos;
 item^.Delta:=Delta;
 item^.Next:=Nil;
 If OffsetPatchHead=Nil Then OffsetPatchHead:=item
                        Else OffsetPatchTail^.Next:=item;
 OffsetPatchTail:=item;
 Inc(OffsetPatchCount);
End;

Procedure AddBackPatch(Const SegIdx:Word; Const LocTyp:Byte;
                       Const OfsVal,PatchVal:LongInt; Is32Rec:Boolean);
Var item:PBackPatchItem;
Begin
 If BackPatchCount>=MAX_RELOCATIONS Then Begin
  WriteLn('Erreur : Trop d''entrees BAKPAT');
  Halt(18);
 End;
 New(item);
 item^.SegIndex:=SegIdx;
 item^.LocType:=LocTyp;
 item^.PatchOffset:=OfsVal;
 item^.PatchValue:=PatchVal;
 item^.Is32Bit:=Is32Rec;
 item^.Next:=Nil;
 If BackPatchHead=Nil Then BackPatchHead:=item
                     Else BackPatchTail^.Next:=item;
 BackPatchTail:=item;
 Inc(BackPatchCount);
End;

Procedure AddAlias(Const AliasNm,SubNm:String);
Var
 item,scan:PAliasItem;
Begin
 scan:=AliasHead;
 While scan<>Nil do Begin
  If scan^.AliasName=Copy(AliasNm,1,64) Then Begin
   scan^.SubstituteName:=Copy(SubNm,1,64);
   Exit;
  End;
  scan:=scan^.Next;
 End;

 If AliasCount>=MAX_ALIASES Then Begin
  WriteLn('Erreur : Trop de definitions ALIAS');
  Halt(19);
 End;

 New(item);
 item^.AliasName:=Copy(AliasNm,1,64);
 item^.SubstituteName:=Copy(SubNm,1,64);
 item^.Next:=Nil;
 If AliasHead=Nil Then AliasHead:=item
                  Else AliasTail^.Next:=item;
 AliasTail:=item;
 Inc(AliasCount);
End;

Function ResolveAliasName(Const Nm:String):String;
Var
 curName:String[64];
 aliasItem:PAliasItem;
 loopCount:Integer;
 changed:Boolean;
Begin
 curName:=Copy(Nm,1,64);
 For loopCount:=1 to 16 do Begin
  changed:=False;
  aliasItem:=AliasHead;
  While aliasItem<>Nil do Begin
   If aliasItem^.AliasName=curName Then Begin
    If aliasItem^.SubstituteName='' Then Begin
     ResolveAliasName:=curName;
     Exit;
    End;
    curName:=aliasItem^.SubstituteName;
    changed:=True;
    Break;
   End;
   aliasItem:=aliasItem^.Next;
  End;
  If Not changed Then Break;
 End;
 ResolveAliasName:=curName;
End;

Procedure FreeOffsetPatchList;
Var item,nextItem:POffsetPatchItem;
Begin
 item:=OffsetPatchHead;
 While item<>Nil do Begin
  nextItem:=item^.Next;
  Dispose(item);
  item:=nextItem;
 End;
 OffsetPatchHead:=Nil;
 OffsetPatchTail:=Nil;
 OffsetPatchCount:=0;
End;

Procedure InitMainLists;
Begin
 SegmentHead:=Nil;
 SegmentTail:=Nil;
 SymbolHead:=Nil;
 SymbolTail:=Nil;
 RelocationHead:=Nil;
 RelocationTail:=Nil;
 GroupHead:=Nil;
 GroupTail:=Nil;
 LNameHead:=Nil;
 LNameTail:=Nil;
 LineInfoHead:=Nil;
 LineInfoTail:=Nil;
 CommentHead:=Nil;
 CommentTail:=Nil;
 BackPatchHead:=Nil;
 BackPatchTail:=Nil;
 AliasHead:=Nil;
 AliasTail:=Nil;
 SegmentCount:=0;
 SymbolCount:=0;
 RelocationCount:=0;
 GroupCount:=0;
 LNameCount:=0;
 LineInfoCount:=0;
 CommentCount:=0;
 BackPatchCount:=0;
 AliasCount:=0;
End;

Procedure FreeMainLists;
Var
 segItem,nextSeg:PSegmentItem;
 symItem,nextSym:PSymbolItem;
 relItem,nextRel:PRelocationItem;
 grpItem,nextGrp:PGroupItem;
 memItem,nextMem:PGroupMemberItem;
 nameItem,nextName:PLNameItem;
 lineItem,nextLine:PLineInfoItem;
 comItem,nextCom:PCommentItem;
 bakItem,nextBak:PBackPatchItem;
 aliasItem,nextAlias:PAliasItem;
Begin
 segItem:=SegmentHead;
 While segItem<>Nil do Begin
  nextSeg:=segItem^.Next;
  Dispose(segItem);
  segItem:=nextSeg;
 End;
 symItem:=SymbolHead;
 While symItem<>Nil do Begin
  nextSym:=symItem^.Next;
  Dispose(symItem);
  symItem:=nextSym;
 End;
 relItem:=RelocationHead;
 While relItem<>Nil do Begin
  nextRel:=relItem^.Next;
  Dispose(relItem);
  relItem:=nextRel;
 End;

 grpItem:=GroupHead;
 While grpItem<>Nil do Begin
  memItem:=grpItem^.MemberHead;
  While memItem<>Nil do Begin
   nextMem:=memItem^.Next;
   Dispose(memItem);
   memItem:=nextMem;
  End;
  nextGrp:=grpItem^.Next;
  Dispose(grpItem);
  grpItem:=nextGrp;
 End;

 nameItem:=LNameHead;
 While nameItem<>Nil do Begin
  nextName:=nameItem^.Next;
  Dispose(nameItem);
  nameItem:=nextName;
 End;

 lineItem:=LineInfoHead;
 While lineItem<>Nil do Begin
  nextLine:=lineItem^.Next;
  Dispose(lineItem);
  lineItem:=nextLine;
 End;

 comItem:=CommentHead;
 While comItem<>Nil do Begin
  nextCom:=comItem^.Next;
  Dispose(comItem);
  comItem:=nextCom;
 End;

 bakItem:=BackPatchHead;
 While bakItem<>Nil do Begin
  nextBak:=bakItem^.Next;
  Dispose(bakItem);
  bakItem:=nextBak;
 End;

 aliasItem:=AliasHead;
 While aliasItem<>Nil do Begin
  nextAlias:=aliasItem^.Next;
  Dispose(aliasItem);
  aliasItem:=nextAlias;
 End;
 InitMainLists;
End;

Procedure ApplyAliasToExternalSymbols;
Var
 SymItem:PSymbolItem;
Begin
 SymItem:=SymbolHead;
 While SymItem<>Nil do Begin
  If SymItem^.Value.IsExternal Then
   SymItem^.Value.Name:=Copy(ResolveAliasName(SymItem^.Value.Name),1,32);
  SymItem:=SymItem^.Next;
 End;
End;

Procedure RecomputeSegmentAddresses;
Type
 TSegOrderItem=Record
  SegPtr:PSegmentItem;
  Priority:Integer;
  OrigIndex:Integer;
  ClassName:String[8];
  SegName:String[16];
 End;
Var
 segItem:PSegmentItem;
 currentBase:LongInt;
 segCount,a,b:Integer;
 orderArr:Array[1..MAX_SEGMENTS] of TSegOrderItem;
 tmp:TSegOrderItem;

 Function UpStrLocal(Const S:String):String;
 Var
  r:String;
  k:Integer;
 Begin
  r:=S;
  For k:=1 to Length(r) do r[k]:=UpCase(r[k]);
  UpStrLocal:=r;
 End;

 Function DosSegPriority(Const ClassName,SegName:String):Integer;
 Var
  cls,nm:String;
  isCode,isData,isBss,isStack:Boolean;
 Begin
  cls:=UpStrLocal(ClassName);
  nm:=UpStrLocal(SegName);

  isCode:=(Pos('CODE',cls)>0)Or(Pos('CODE',nm)>0)Or(Pos('_TEXT',nm)>0);
  isData:=(Pos('DATA',cls)>0)Or(Pos('DATA',nm)>0);
  isBss:=(Pos('BSS',cls)>0)Or(Pos('BSS',nm)>0);
  isStack:=(Pos('STACK',cls)>0)Or(Pos('STACK',nm)>0);

  If isCode Then Begin
   DosSegPriority:=10;
   Exit;
  End;
  If isStack Then Begin
   DosSegPriority:=90;
   Exit;
  End;

  If DsAllocateTop Then Begin
   If isData Then DosSegPriority:=70
   Else If isBss Then DosSegPriority:=80
   Else DosSegPriority:=50;
   Exit;
  End;

  If isData Then DosSegPriority:=20
  Else If isBss Then DosSegPriority:=30
  Else DosSegPriority:=50;
 End;
Begin
 currentBase:=0;

 If (Not DosSegOrdering)Or(SegmentCount<2) Then Begin
  segItem:=SegmentHead;
  While segItem<>Nil do Begin
  segItem^.Value.Address:=currentBase;
  Inc(currentBase,segItem^.Value.Size);
  segItem:=segItem^.Next;
  End;
  Exit;
 End;

 segCount:=0;
 segItem:=SegmentHead;
 While segItem<>Nil do Begin
  If segCount<MAX_SEGMENTS Then Begin
  Inc(segCount);
  orderArr[segCount].SegPtr:=segItem;
  orderArr[segCount].Priority:=DosSegPriority(segItem^.Value.Class,segItem^.Value.Name);
  orderArr[segCount].OrigIndex:=segCount;
  orderArr[segCount].ClassName:=segItem^.Value.Class;
  orderArr[segCount].SegName:=segItem^.Value.Name;
  End;
  segItem:=segItem^.Next;
 End;

 For a:=1 to segCount-1 do
  For b:=a+1 to segCount do
  If (orderArr[a].Priority>orderArr[b].Priority)
    Or((orderArr[a].Priority=orderArr[b].Priority)And(orderArr[a].ClassName>orderArr[b].ClassName))
    Or((orderArr[a].Priority=orderArr[b].Priority)And(orderArr[a].ClassName=orderArr[b].ClassName)
      And(orderArr[a].SegName>orderArr[b].SegName))
    Or((orderArr[a].Priority=orderArr[b].Priority)And(orderArr[a].ClassName=orderArr[b].ClassName)
      And(orderArr[a].SegName=orderArr[b].SegName)
      And(orderArr[a].OrigIndex>orderArr[b].OrigIndex)) Then Begin
   tmp:=orderArr[a];
   orderArr[a]:=orderArr[b];
   orderArr[b]:=tmp;
  End;

 For a:=1 to segCount do Begin
  orderArr[a].SegPtr^.Value.Address:=currentBase;
  Inc(currentBase,orderArr[a].SegPtr^.Value.Size);
 End;
End;

  Function NormalizeSymbolName(Const Nm:String):String;
  Var
   canon:String;
   k:Integer;
  Begin
   canon:=Copy(ResolveAliasName(Copy(Nm,1,64)),1,32);
   If Not NoIgnoreCase Then
    For k:=1 to Length(canon) do canon[k]:=UpCase(canon[k]);
   NormalizeSymbolName:=canon;
  End;

  Function IsPublicSymbolDefined(Const Nm:String):Boolean;
  Var
   symItem:PSymbolItem;
   lookupName:String[32];
  Begin
   IsPublicSymbolDefined:=False;
   lookupName:=NormalizeSymbolName(Nm);
   If lookupName='' Then Exit;

   symItem:=SymbolHead;
   While symItem<>Nil do Begin
    If Not symItem^.Value.IsExternal Then
     If NormalizeSymbolName(symItem^.Value.Name)=lookupName Then Begin
      IsPublicSymbolDefined:=True;
      Exit;
     End;
    symItem:=symItem^.Next;
   End;
  End;

  Function IsExternalNameUnresolved(Const Nm:String):Boolean;
  Var
   symItem:PSymbolItem;
   lookupName:String[32];
  Begin
   IsExternalNameUnresolved:=False;
   lookupName:=NormalizeSymbolName(Nm);
   If lookupName='' Then Exit;
   If IsPublicSymbolDefined(lookupName) Then Exit;

   symItem:=SymbolHead;
   While symItem<>Nil do Begin
    If symItem^.Value.IsExternal Then
     If NormalizeSymbolName(symItem^.Value.Name)=lookupName Then Begin
      IsExternalNameUnresolved:=True;
      Exit;
     End;
    symItem:=symItem^.Next;
   End;
  End;

  Function CountExternalReferences:Integer;
  Var
   symItem:PSymbolItem;
    count:Integer;
  Begin
    count:=0;
   symItem:=SymbolHead;
   While symItem<>Nil do Begin
     If symItem^.Value.IsExternal Then Inc(count);
    symItem:=symItem^.Next;
   End;
    CountExternalReferences:=count;
  End;

  Function CountPublicDefinitions:Integer;
  Var
   symItem:PSymbolItem;
   count:Integer;
  Begin
   count:=0;
   symItem:=SymbolHead;
   While symItem<>Nil do Begin
    If (Not symItem^.Value.IsExternal)And(symItem^.Value.Segment>0) Then
     Inc(count);
    symItem:=symItem^.Next;
   End;
   CountPublicDefinitions:=count;
  End;

  Function CountUnresolvedExternalNames:Integer;
  Var
   symItem:PSymbolItem;
   names:Array[1..MAX_SYMBOLS] of String[32];
   count,k:Integer;
   nm:String[32];
   seen:Boolean;
  Begin
   count:=0;
   symItem:=SymbolHead;
   While symItem<>Nil do Begin
    If symItem^.Value.IsExternal Then Begin
     nm:=NormalizeSymbolName(symItem^.Value.Name);
     If (nm<>'')And IsExternalNameUnresolved(nm) Then Begin
      seen:=False;
      For k:=1 to count do
       If names[k]=nm Then Begin
        seen:=True;
        Break;
       End;
      If Not seen Then Begin
       If count<MAX_SYMBOLS Then Begin
        Inc(count);
        names[count]:=nm;
       End;
      End;
     End;
    End;
    symItem:=symItem^.Next;
   End;
   CountUnresolvedExternalNames:=count;
  End;

   Function TraceLibraryMatches(Const LibName:String):Boolean;
   Var
    u:String;
    k:Integer;
   Begin
    u:=LibName;
    For k:=1 to Length(u) do u[k]:=UpCase(u[k]);
    If TraceLibNameFilter='' Then TraceLibraryMatches:=True
                           Else TraceLibraryMatches:=Pos(TraceLibNameFilter,u)>0;
   End;

   Function TraceSymbolMatches(Const SymbolName:String):Boolean;
   Var
    u:String;
    k:Integer;
   Begin
    u:=SymbolName;
    For k:=1 to Length(u) do u[k]:=UpCase(u[k]);
    If TraceSymNameFilter='' Then TraceSymbolMatches:=True
                           Else TraceSymbolMatches:=Pos(TraceSymNameFilter,u)>0;
   End;

  Procedure TraceUnresolvedExternalNames(Const Prefix:String; Const MaxItems:Integer);
  Var
   symItem:PSymbolItem;
   names:Array[1..MAX_SYMBOLS] of String[32];
   count,k,shown,limit:Integer;
   nm:String[32];
   seen:Boolean;
  Begin
   If Not TraceLibRequested Then Exit;

   count:=0;
   symItem:=SymbolHead;
   While symItem<>Nil do Begin
    If symItem^.Value.IsExternal Then Begin
     nm:=NormalizeSymbolName(symItem^.Value.Name);
     If (nm<>'')And IsExternalNameUnresolved(nm)And TraceSymbolMatches(nm) Then Begin
      seen:=False;
      For k:=1 to count do
       If names[k]=nm Then Begin
        seen:=True;
        Break;
       End;
      If (Not seen)And(count<MAX_SYMBOLS) Then Begin
       Inc(count);
       names[count]:=nm;
      End;
     End;
    End;
    symItem:=symItem^.Next;
   End;

   WriteLn('TRACE LIB: ',Prefix,' : ',count,' externe(s) non resolu(s)');
   If Not TraceLibSymbolsRequested Then Exit;

   limit:=MaxItems;
   If limit<1 Then limit:=1;
   shown:=0;
   For k:=1 to count do Begin
    Inc(shown);
    If shown>limit Then Begin
     WriteLn('TRACE LIB:   ... (',count-limit,' nom(s) supplementaire(s))');
     Break;
    End;
    WriteLn('TRACE LIB:   - ',names[k]);
   End;
  End;

  Procedure AddTempLibObjFile(Const FileName:String);
  Begin
   If TempLibObjCount<MAX_CMD_OBJS Then Begin
    Inc(TempLibObjCount);
    TempLibObjList^[TempLibObjCount]:=Copy(FileName,1,128);
   End;
  End;

  Procedure CleanupTempLibObjFiles;
  Var
   f:File;
   n:Integer;
  Begin
   For n:=1 to TempLibObjCount do Begin
    If TempLibObjList^[n]<>'' Then Begin
     {$I-}
     Assign(f,TempLibObjList^[n]);
     Erase(f);
     If(IOResult<>0)Then;
     {$I+}
    End;
   End;
   TempLibObjCount:=0;
  End;

  Function IsLibModuleAlreadyLoaded(Const LibIdx:Integer; Const StartPos:LongInt):Boolean;
  Var
   n:Integer;
  Begin
   IsLibModuleAlreadyLoaded:=False;
   For n:=1 to LoadedLibModuleCount do
    If (LoadedLibModuleLibIndex[n]=LibIdx)And(LoadedLibModuleStart[n]=StartPos) Then Begin
     IsLibModuleAlreadyLoaded:=True;
     Exit;
    End;
  End;

  Procedure MarkLibModuleLoaded(Const LibIdx:Integer; Const StartPos:LongInt; Const ModuleName:String);
  Begin
   If LoadedLibModuleCount<MAX_LIB_TRACKED_MODULES Then Begin
    Inc(LoadedLibModuleCount);
    LoadedLibModuleLibIndex[LoadedLibModuleCount]:=LibIdx;
    LoadedLibModuleStart[LoadedLibModuleCount]:=StartPos;
    LoadedLibModuleName[LoadedLibModuleCount]:=Copy(ModuleName,1,64);
   End;
  End;

Function AddSegment(Const Seg:TSegment):Integer;
Var item:PSegmentItem;
Begin
 If SegmentCount>=MaxSegmentsOption Then Begin
  WriteLn('Erreur : Trop de segments dans le fichier objet');
  Halt(11);
 End;
 New(item);
 item^.Value:=Seg;
 item^.Next:=Nil;
 If SegmentHead=Nil Then SegmentHead:=item
                    Else SegmentTail^.Next:=item;
 SegmentTail:=item;
 Inc(SegmentCount);
 AddSegment:=SegmentCount;
End;

Procedure AddSymbol(Const Sym:TSymbol);
Var item:PSymbolItem;
Begin
 New(item);
 item^.Value:=Sym;
 item^.Next:=Nil;
 If SymbolHead=Nil Then SymbolHead:=item
                   Else SymbolTail^.Next:=item;
 SymbolTail:=item;
 Inc(SymbolCount);
End;

Function AddGroup(Const NameIdx:Word; Is32Rec:Boolean):PGroupItem;
Var item:PGroupItem;
Begin
 If GroupCount>=MAX_GROUPS Then Begin
  WriteLn('Erreur : Trop de groupes OMF');
  Halt(16);
 End;
 New(item);
 item^.NameIndex:=NameIdx;
 item^.Is32Bit:=Is32Rec;
 item^.MemberHead:=Nil;
 item^.MemberTail:=Nil;
 item^.MemberCount:=0;
 item^.Next:=Nil;
 If GroupHead=Nil Then GroupHead:=item
                   Else GroupTail^.Next:=item;
 GroupTail:=item;
 Inc(GroupCount);
 AddGroup:=item;
End;

Procedure AddGroupMember(GroupItem:PGroupItem; SegIdx:Word);
Var mem:PGroupMemberItem;
Begin
 If GroupItem=Nil Then Exit;
 New(mem);
 mem^.SegIndex:=SegIdx;
 mem^.Next:=Nil;
 If GroupItem^.MemberHead=Nil Then GroupItem^.MemberHead:=mem
                            Else GroupItem^.MemberTail^.Next:=mem;
 GroupItem^.MemberTail:=mem;
 Inc(GroupItem^.MemberCount);
End;

Procedure AddLName(Const Nm:String);
Var item:PLNameItem;
Begin
 If LNameCount>=MAX_LNAMES Then Begin
  WriteLn('Erreur : Trop de noms LNAMES');
  Halt(17);
 End;
 New(item);
 item^.Value:=Copy(Nm,1,64);
 item^.Next:=Nil;
 If LNameHead=Nil Then LNameHead:=item
                   Else LNameTail^.Next:=item;
 LNameTail:=item;
 Inc(LNameCount);
End;

Function GetLName(Index:Word):String;
Var
 item:PLNameItem;
 n:Word;
Begin
 GetLName:='';
 If (Index=0)Or(Index>LNameCount) Then Exit;
 item:=LNameHead;
 n:=1;
 While(item<>Nil)And(n<Index)do Begin
  item:=item^.Next;
  Inc(n);
 End;
 If item<>Nil Then GetLName:=item^.Value;
End;

Procedure AddLineInfo(Const GrpIdx,SegIdx:Word; Const LineNum,CodeOfs:LongInt; Is32Rec:Boolean);
Var item:PLineInfoItem;
Begin
 If LineInfoCount>=MAX_LINENUMS Then Exit;
 New(item);
 If NoGroupAssociation Then item^.GroupIndex:=0
                      Else item^.GroupIndex:=GrpIdx;
 item^.SegIndex:=SegIdx;
 item^.LineNo:=LineNum;
 item^.CodeOffset:=CodeOfs;
 item^.Is32Bit:=Is32Rec;
 item^.Next:=Nil;
 If LineInfoHead=Nil Then LineInfoHead:=item
                      Else LineInfoTail^.Next:=item;
 LineInfoTail:=item;
 Inc(LineInfoCount);
End;

Procedure AddComment(Const Flags,ClassCode:Byte; Const Txt:String);
Var item:PCommentItem;
Begin
 If CommentCount>=MAX_COMMENTS Then Exit;
 New(item);
 item^.Flags:=Flags;
 item^.ClassCode:=ClassCode;
 item^.Text:=Copy(Txt,1,80);
 item^.Next:=Nil;
 If CommentHead=Nil Then CommentHead:=item
                    Else CommentTail^.Next:=item;
 CommentTail:=item;
 Inc(CommentCount);
End;

Function GetSegmentPtr(Index:Integer):PSegment;
Var
 item:PSegmentItem;
 n:Integer;
Begin
 GetSegmentPtr:=Nil;
 If (Index<=0)Or(Index>SegmentCount) Then Exit;
 item:=SegmentHead;
 n:=1;
 While(item<>Nil)And(n<Index)do Begin
  item:=item^.Next;
  Inc(n);
 End;
 If item<>Nil Then GetSegmentPtr:=@item^.Value;
End;

Procedure AddRelocationEntry(Const OffsetVal,SegmentVal,TargetVal:Word);
Var
 item:PRelocationItem;
 rel:TRelocation;
Begin
 If RelocationCount>=MAX_RELOCATIONS Then Begin
  WriteLn('Erreur : Trop de relocations');
  Halt(14);
 End;
 rel.Offset:=OffsetVal;
 rel.Segment:=SegmentVal;
 rel.Target:=TargetVal;
 New(item);
 item^.Value:=rel;
 item^.Next:=Nil;
 If RelocationHead=Nil Then RelocationHead:=item
                       Else RelocationTail^.Next:=item;
 RelocationTail:=item;
 Inc(RelocationCount);
End;

Function SkipIterBlock16(Var RecBuf:TObjRecBuffer; Var Pos:Integer; Limit:Integer; Var Generated:LongInt):Boolean;
Var
 RepeatCount,BlockCount:Word;
 DataCount:Byte;
 i:Integer;
 SubLen,AddLen:LongInt;
Begin
 Generated:=0;
 SkipIterBlock16:=False;
 If Pos+3>=Limit Then Exit;

 RepeatCount:=RecBuf[Pos]+Word(RecBuf[Pos+1])*256;
 Inc(Pos,2);
 BlockCount:=RecBuf[Pos]+Word(RecBuf[Pos+1])*256;
 Inc(Pos,2);

 If BlockCount=0 Then Begin
  If Pos>=Limit Then Exit;
  DataCount:=RecBuf[Pos];
  Inc(Pos);
  If Pos+DataCount>Limit Then Exit;
  Inc(Pos,DataCount);
  Generated:=LongInt(RepeatCount)*LongInt(DataCount);
  SkipIterBlock16:=True;
  Exit;
 End;

 For i:=1 to BlockCount do Begin
  If Not SkipIterBlock16(RecBuf,Pos,Limit,SubLen) Then Exit;
  AddLen:=LongInt(RepeatCount)*SubLen;
  If Generated>High(LongInt)-AddLen Then Generated:=High(LongInt)
                                 Else Inc(Generated,AddLen);
 End;

 SkipIterBlock16:=True;
End;

Procedure EmitRawSpanToExe(Var ExeF:File; Var RecBuf:TObjRecBuffer;
                           StartPos,Count:Integer; DestBase:LongInt;
                           Var Produced:LongInt; MaxBytes:LongInt);
Var
 Writable:LongInt;
 WriteCount:Word;
Begin
 If Count<=0 Then Exit;
 Writable:=0;
 If Produced<MaxBytes Then Begin
  Writable:=MaxBytes-Produced;
  If Writable>Count Then Writable:=Count;
 End;
 If Writable>0 Then Begin
  WriteCount:=Writable;
  Seek(ExeF,DestBase+Produced);
  BlockWrite(ExeF,RecBuf[StartPos],WriteCount);
 End;
 If Produced>High(LongInt)-Count Then Produced:=High(LongInt)
                                Else Inc(Produced,Count);
End;

Function EmitIterBlock16(Var ExeF:File; Var RecBuf:TObjRecBuffer;
                         Var Pos:Integer; Limit:Integer;
                         DestBase:LongInt; Var Produced:LongInt;
                         MaxBytes:LongInt):Boolean;
Var
 RepeatCount,BlockCount:Word;
 DataCount:Byte;
 i,r:Integer;
 TempPos,SubEnd:Integer;
 DummyLen:LongInt;
 DataStart:Integer;
Begin
 EmitIterBlock16:=False;
 If Pos+3>=Limit Then Exit;

 RepeatCount:=RecBuf[Pos]+Word(RecBuf[Pos+1])*256;
 Inc(Pos,2);
 BlockCount:=RecBuf[Pos]+Word(RecBuf[Pos+1])*256;
 Inc(Pos,2);

 If BlockCount=0 Then Begin
  If Pos>=Limit Then Exit;
  DataCount:=RecBuf[Pos];
  Inc(Pos);
  If Pos+DataCount>Limit Then Exit;
  DataStart:=Pos;
  Inc(Pos,DataCount);

  For r:=1 to RepeatCount do
   EmitRawSpanToExe(ExeF,RecBuf,DataStart,DataCount,DestBase,Produced,MaxBytes);

  EmitIterBlock16:=True;
  Exit;
 End;

 TempPos:=Pos;
 For i:=1 to BlockCount do
  If Not SkipIterBlock16(RecBuf,TempPos,Limit,DummyLen) Then Exit;
 SubEnd:=TempPos;

 For r:=1 to RepeatCount do Begin
  TempPos:=Pos;
  For i:=1 to BlockCount do
   If Not EmitIterBlock16(ExeF,RecBuf,TempPos,SubEnd,DestBase,Produced,MaxBytes) Then Exit;
 End;

 Pos:=SubEnd;
 EmitIterBlock16:=True;
End;

Function SkipIterBlockEx(Var RecBuf:TObjRecBuffer; Var Pos:Integer; Limit:Integer;
                        Use32Repeat:Boolean; Var Generated:LongInt):Boolean;
Var
 RepeatCount,AddLen:LongInt;
 BlockCount:Word;
 DataCount:Byte;
 i:Integer;
 SubLen:LongInt;
Begin
 Generated:=0;
 SkipIterBlockEx:=False;

 If Use32Repeat Then Begin
  If Pos+5>=Limit Then Exit;
  RepeatCount:=LongInt(RecBuf[Pos])
           + LongInt(RecBuf[Pos+1]) * 256
           + LongInt(RecBuf[Pos+2]) * 65536
           + LongInt(RecBuf[Pos+3]) * 16777216;
  Inc(Pos,4);
 End Else Begin
  If Pos+3>=Limit Then Exit;
  RepeatCount:=RecBuf[Pos]+LongInt(RecBuf[Pos+1])*256;
  Inc(Pos,2);
 End;

 BlockCount:=RecBuf[Pos]+Word(RecBuf[Pos+1])*256;
 Inc(Pos,2);

 If BlockCount=0 Then Begin
  If Pos>=Limit Then Exit;
  DataCount:=RecBuf[Pos];
  Inc(Pos);
  If Pos+DataCount>Limit Then Exit;
  Inc(Pos,DataCount);
  Generated:=RepeatCount*LongInt(DataCount);
  SkipIterBlockEx:=True;
  Exit;
 End;

 For i:=1 to BlockCount do Begin
  If Not SkipIterBlockEx(RecBuf,Pos,Limit,Use32Repeat,SubLen) Then Exit;
  AddLen:=RepeatCount*SubLen;
  If Generated>High(LongInt)-AddLen Then Generated:=High(LongInt)
                                 Else Inc(Generated,AddLen);
 End;

 SkipIterBlockEx:=True;
End;

Function EmitIterBlockEx(Var ExeF:File; Var RecBuf:TObjRecBuffer;
                         Var Pos:Integer; Limit:Integer;
                         DestBase:LongInt; Var Produced:LongInt;
                         MaxBytes:LongInt; Use32Repeat:Boolean):Boolean;
Var
 RepeatCount:LongInt;
 BlockCount:Word;
 DataCount:Byte;
 i,r:LongInt;
 TempPos,SubEnd:Integer;
 DummyLen:LongInt;
 DataStart:Integer;
Begin
 EmitIterBlockEx:=False;

 If Use32Repeat Then Begin
  If Pos+5>=Limit Then Exit;
  RepeatCount:=LongInt(RecBuf[Pos])
           + LongInt(RecBuf[Pos+1]) * 256
           + LongInt(RecBuf[Pos+2]) * 65536
           + LongInt(RecBuf[Pos+3]) * 16777216;
  Inc(Pos,4);
 End Else Begin
  If Pos+3>=Limit Then Exit;
  RepeatCount:=RecBuf[Pos]+LongInt(RecBuf[Pos+1])*256;
  Inc(Pos,2);
 End;

 BlockCount:=RecBuf[Pos]+Word(RecBuf[Pos+1])*256;
 Inc(Pos,2);

 If BlockCount=0 Then Begin
  If Pos>=Limit Then Exit;
  DataCount:=RecBuf[Pos];
  Inc(Pos);
  If Pos+DataCount>Limit Then Exit;
  DataStart:=Pos;
  Inc(Pos,DataCount);

  For r:=1 to RepeatCount do
   EmitRawSpanToExe(ExeF,RecBuf,DataStart,DataCount,DestBase,Produced,MaxBytes);

  EmitIterBlockEx:=True;
  Exit;
 End;

 TempPos:=Pos;
 For i:=1 to BlockCount do
  If Not SkipIterBlockEx(RecBuf,TempPos,Limit,Use32Repeat,DummyLen) Then Exit;
 SubEnd:=TempPos;

 For r:=1 to RepeatCount do Begin
  TempPos:=Pos;
  For i:=1 to BlockCount do
   If Not EmitIterBlockEx(ExeF,RecBuf,TempPos,SubEnd,DestBase,Produced,MaxBytes,Use32Repeat) Then Exit;
 End;

 Pos:=SubEnd;
 EmitIterBlockEx:=True;
End;

Function ReadObjFile(Const FileName:String):Boolean;
Var
 RecType:Byte;
 RecLen:Word;
 Buffer:TObjRecBuffer;
 SegIndex:Word;
 SegOffset:Word;
 DataLen:Word;
 EndPos:LongInt;
 IdxSize:Integer;
 ModuleEnded:Boolean;
 NameLen:Byte;
 j:Integer;
 LastDataSeg:Word;
 LastDataOfs:Word;
 HasDataContext:Boolean;
 FixPos,FixLimit:Integer;
 Locat,FixDat,FixByte:Byte;
 LocOfs:Word;
 LocKind:Byte;
 LocIsSelfRel:Boolean;
 FrameMethod,TargetMethod:Byte;
 RelocLinearPos,RelocDataPos:LongInt;
 SegSize32:LongInt;
 SymRec:TSymbol;
 SegRec:TSegment;
 SegPtr:PSegment;
 GroupPtr:PGroupItem;
 GroupPos,GroupLimit:Integer;
 ExtPos,ExtLimit:Integer;
 GroupNameIdx,GroupMemberIdx:Word;
 GroupItemType:Byte;
 NamePos,NameLimit:Integer;
 PubPos,PubLimit:Integer;
 LinePos,LineLimit:Integer;
 BaseGroupIdx,BaseSegIdx:Word;
 PubTypeIdx:Word;
 SegNameIdx,SegClassIdx,SegOverlayIdx:Word;
 CommentFlags,CommentClass:Byte;
 ModType,EndDat:Byte;
 EntryFrameIdx,EntryTargetIdx:Word;
 ParsedName:String[64];
 ParsedClass:String[64];
 CommentText:String[80];
 ParsedNameLen:Byte;
 CommentTextLen:Byte;
 PubOfs:LongInt;
 EntryDisp:LongInt;
 LineNum,LineOfs:LongInt;
 IterLen,BlockLen:LongInt;
 LegacyPubParsed:Integer;
 DataOfs32:LongInt;
 TmpPos:Integer;
 ParseOK:Boolean;
 IterPos:Integer;
 k:Integer;
 BakLocType:Byte;
 BakPatchOfs:LongInt;
 BakPatchVal:LongInt;
 LSymFlags:Byte;
 LSymName:String[64];
 LSymContinue:Boolean;
 LSymSeg:Word;
 LSymBaseOfs:LongInt;
 LastLSymName:String[64];
 LastLSymSeg:Word;
 LastLSymBaseOfs:LongInt;
 HasLastLSym:Boolean;
 ComDataType:Byte;
 ComdatFlags:Byte;
 ComdatAttr:Byte;
 ComdatAllocType:Byte;
 ComdatEnumOfs:LongInt;
 ModuleSegBase:Integer;
 ModuleLNameBase:Integer;
 LocalSegCount:Integer;
 LocalLNameCount:Integer;

 Function ReadOmfIndex(Var Pos:Integer; Limit:Integer; Var Idx:Word):Boolean;
 Var b:Byte;
 Begin
  ReadOmfIndex:=False;
  If Pos>=Limit Then Exit;
  b:=Buffer[Pos];
  Inc(Pos);
  If (b And $80)<>0 Then Begin
   If Pos>=Limit Then Exit;
   Idx:=((Word(b And $7F) Shl 8) Or Buffer[Pos]);
   Inc(Pos);
  End Else Idx:=b;
  ReadOmfIndex:=True;
 End;

   Function MapSegIndexLocal(Const LocalIdx:Word):Word;
   Begin
    If (LocalIdx=0)Or(LocalIdx>LocalSegCount) Then MapSegIndexLocal:=0
    Else MapSegIndexLocal:=ModuleSegBase+LocalIdx;
   End;

   Function MapLNameIndexLocal(Const LocalIdx:Word):Word;
   Begin
    If (LocalIdx=0)Or(LocalIdx>LocalLNameCount) Then MapLNameIndexLocal:=0
    Else MapLNameIndexLocal:=ModuleLNameBase+LocalIdx;
   End;

   Function UpperLocalStr(Const S:String):String;
   Var
    r:String;
    u:Integer;
   Begin
    r:=S;
    For u:=1 to Length(r) do r[u]:=UpCase(r[u]);
    UpperLocalStr:=r;
   End;

   Function HasExtensionLocal(Const Nm:String):Boolean;
   Var
    s:String;
    n,lastSep,lastDot,i,j:Integer;
   Begin
    i:=1;
    j:=Length(Nm);
    While (i<=j)And((Nm[i]=' ')Or(Nm[i]=#9)Or(Nm[i]=#13)Or(Nm[i]=#10)) do Inc(i);
    While (j>=i)And((Nm[j]=' ')Or(Nm[j]=#9)Or(Nm[j]=#13)Or(Nm[j]=#10)) do Dec(j);
    If j<i Then s:=''
           Else s:=Copy(Nm,i,j-i+1);
    lastSep:=0;
    lastDot:=0;
    For n:=1 to Length(s) do Begin
     If (s[n]='\')Or(s[n]='/')Or(s[n]=':') Then Begin
      lastSep:=n;
      lastDot:=0;
     End Else If s[n]='.' Then lastDot:=n;
    End;
    HasExtensionLocal:=lastDot>lastSep;
   End;

   Function EnsureDefaultLibExt(Const Nm:String):String;
   Var
    s:String;
    i,j:Integer;
   Begin
    i:=1;
    j:=Length(Nm);
    While (i<=j)And((Nm[i]=' ')Or(Nm[i]=#9)Or(Nm[i]=#13)Or(Nm[i]=#10)) do Inc(i);
    While (j>=i)And((Nm[j]=' ')Or(Nm[j]=#9)Or(Nm[j]=#13)Or(Nm[j]=#10)) do Dec(j);
    If j<i Then s:=''
         Else s:=Copy(Nm,i,j-i+1);
    If s='' Then Begin
     EnsureDefaultLibExt:='';
     Exit;
    End;
    If HasExtensionLocal(s) Then EnsureDefaultLibExt:=s
                            Else EnsureDefaultLibExt:=s+'.LIB';
   End;

   Function IsLibAlreadyListed(Const Nm:String):Boolean;
   Var
    m:Integer;
    probe:String;
   Begin
    IsLibAlreadyListed:=False;
    probe:=UpperLocalStr(Copy(Nm,1,128));
    For m:=1 to LibInputCount do
     If UpperLocalStr(LibInputList^[m])=probe Then Begin
      IsLibAlreadyListed:=True;
      Exit;
     End;
   End;

   Procedure AddDefaultLibraryFromCommentName(Const Nm:String);
   Var
    libName:String;
   Begin
    libName:=EnsureDefaultLibExt(Nm);
    If libName='' Then Exit;
    If IsLibAlreadyListed(libName) Then Exit;

    If LibInputCount>=MAX_CMD_LIBS Then Begin
     WriteLn('Avertissement : limite bibliotheques atteinte, DEFAULTLIB ignoree : ',libName);
     Exit;
    End;

    Inc(LibInputCount);
    LibInputList^[LibInputCount]:=Copy(libName,1,128);
   End;

   Procedure ParseDefaultLibrariesFromComment(Const Txt:String);
   Var
    up:String;
    i,j:Integer;
    nameStart,nameEnd:Integer;
    quoteCh:Char;
    libName:String;
   Begin
    up:=UpperLocalStr(Txt);
    i:=1;
    While i<=Length(up)-9 do Begin
     If Copy(up,i,10)='DEFAULTLIB' Then Begin
      j:=i+10;
      While (j<=Length(up))And((up[j]=' ')Or(up[j]=#9)) do Inc(j);
      If (j<=Length(up))And((up[j]=':')Or(up[j]='=')) Then Inc(j);
      While (j<=Length(up))And((up[j]=' ')Or(up[j]=#9)) do Inc(j);

      If j<=Length(up) Then Begin
       If (Txt[j]='"')Or(Txt[j]='''') Then Begin
        quoteCh:=Txt[j];
        Inc(j);
        nameStart:=j;
        While (j<=Length(Txt))And(Txt[j]<>quoteCh) do Inc(j);
        nameEnd:=j-1;
        If (nameEnd>=nameStart) Then Begin
         libName:=Copy(Txt,nameStart,nameEnd-nameStart+1);
         AddDefaultLibraryFromCommentName(libName);
        End;
        If j<=Length(Txt) Then Inc(j);
       End Else Begin
        nameStart:=j;
        While (j<=Length(Txt))And(Txt[j]>' ')And(Txt[j]<>',')And(Txt[j]<>';') do Inc(j);
        nameEnd:=j-1;
        If (nameEnd>=nameStart) Then Begin
         libName:=Copy(Txt,nameStart,nameEnd-nameStart+1);
         AddDefaultLibraryFromCommentName(libName);
        End;
       End;
      End;
      i:=j;
     End Else Inc(i);
    End;
   End;

 Function FindSymbolByName(Const Nm:String; Var SegIdx:Word; Var OfsVal:LongInt):Boolean;
 Var
  symItem:PSymbolItem;
  lookupName:String[64];
 Begin
  FindSymbolByName:=False;
  SegIdx:=0;
  OfsVal:=0;
  lookupName:=ResolveAliasName(Nm);
  symItem:=SymbolHead;
  While symItem<>Nil do Begin
   If (Not symItem^.Value.IsExternal)
      And((symItem^.Value.Name=Nm)Or(symItem^.Value.Name=lookupName)) Then Begin
    SegIdx:=symItem^.Value.Segment;
    OfsVal:=symItem^.Value.Offset;
    FindSymbolByName:=True;
    Exit;
   End;
   symItem:=symItem^.Next;
  End;
 End;

 Function SkipComdefNumber(Var Pos:Integer; Limit:Integer):Boolean;
 Var b:Byte;
 Begin
  SkipComdefNumber:=False;
  If Pos>=Limit Then Exit;
  b:=Buffer[Pos];
  Inc(Pos);
  Case b of
   $81:Begin
    If Pos+1>=Limit Then Exit;
    Inc(Pos,2);
   End;
   $84:Begin
    If Pos+2>=Limit Then Exit;
    Inc(Pos,3);
   End;
   $88:Begin
    If Pos+3>=Limit Then Exit;
    Inc(Pos,4);
   End;
  Else
   If b>$80 Then Exit;
  End;
  SkipComdefNumber:=True;
 End;

Begin
 ReadObjFile:=False;
 ModuleSegBase:=SegmentCount;
 ModuleLNameBase:=LNameCount;
 LocalSegCount:=0;
 LocalLNameCount:=0;
 ModuleEnded:=False;
 LastDataSeg:=0;
 LastDataOfs:=0;
 HasDataContext:=False;
 HasLastLSym:=False;
 LastLSymName:='';
 LastLSymSeg:=0;
 LastLSymBaseOfs:=0;
 {$I-}Assign(ObjFile,FileName);
 Reset(ObjFile, 1);{$I+}
 If IOResult<>0 Then Exit;
 While(Not Eof(ObjFile))and(Not ModuleEnded)do Begin
  BlockRead(ObjFile,RecType,1);
  If Eof(ObjFile) Then Break;
    If RecType<$80 Then RecType:=RecType Or $80;
  BlockRead(ObjFile,RecLen,2);
  If RecLen>SizeOf(Buffer)Then Begin
   WriteLn('Erreur : RecLen sup‚rieur … la taille du tampon');
   Halt(10);
  End;
  BlockRead(ObjFile,Buffer,RecLen);
  Case RecType of
    $00..$7F:Begin
     { Codes bas : normalement convertis en forme haute ci-dessus }
    End;
    $80, $82:Begin
      ObjModuleName:='';
      If RecLen>=2 Then Begin
       NameLen:=Buffer[0];
       If NameLen>(RecLen-2) Then NameLen:=RecLen-2;
       If NameLen>64 Then NameLen:=64;
       For j:=1 to NameLen do ObjModuleName:=ObjModuleName+Chr(Buffer[j]);
      End;
    End;
    $84, $86:Begin
      { PEDATA/PIDATA (anciens) : support de compatibilite }
      GroupPos:=0;
      GroupLimit:=RecLen-1; { sans checksum }
      If GroupLimit<=0 Then Continue;

      SegIndex:=Buffer[GroupPos];
      Inc(GroupPos);
      If (SegIndex And $80)<>0 Then Begin
       If GroupPos>=GroupLimit Then Continue;
       SegIndex:=((SegIndex And $7F) Shl 8) Or Buffer[GroupPos];
       Inc(GroupPos);
      End;
      SegIndex:=MapSegIndexLocal(SegIndex);

      If GroupPos+1>=GroupLimit Then Continue;
      SegOffset:=Buffer[GroupPos]+Word(Buffer[GroupPos+1])*256;
      Inc(GroupPos,2);

      If RecType=$84 Then Begin
       IterLen:=GroupLimit-GroupPos;
      End Else Begin
       IterPos:=GroupPos;
       IterLen:=0;
       While IterPos<GroupLimit do Begin
        BlockLen:=0;
        If Not SkipIterBlock16(Buffer,IterPos,GroupLimit,BlockLen) Then Break;
        If IterLen>High(LongInt)-BlockLen Then IterLen:=High(LongInt)
                      Else Inc(IterLen,BlockLen);
       End;
      End;

      If (SegIndex>0)And(SegIndex<=SegmentCount) Then Begin
       SegPtr:=GetSegmentPtr(SegIndex);
       If SegPtr<>Nil Then Begin
        EndPos:=LongInt(SegOffset)+IterLen;
        If EndPos>$FFFF Then EndPos:=$FFFF;
        If EndPos>SegPtr^.Size Then SegPtr^.Size:=EndPos;
        LastDataSeg:=SegIndex;
        LastDataOfs:=SegOffset;
        HasDataContext:=True;
       End;
      End;
    End;
    $88:Begin
     { COMENT : commentaires/directives du compilateur/assembleur }
      GroupLimit:=RecLen-1; { sans checksum }
      If GroupLimit<2 Then Continue;
      CommentFlags:=Buffer[0];
      CommentClass:=Buffer[1];
      CommentTextLen:=GroupLimit-2;
      If CommentTextLen>80 Then CommentTextLen:=80;
      CommentText:='';
      For k:=1 to CommentTextLen do
       CommentText:=CommentText+Chr(Buffer[1+k]);
      AddComment(CommentFlags,CommentClass,CommentText);
      If Not NoDefaultLibrarySearch Then
       ParseDefaultLibrariesFromComment(CommentText);
    End;
    $8A, $8B:Begin
     { MODEND/MODEND32 : fin de module }
         GroupPos:=0;
         GroupLimit:=RecLen-1; { sans checksum }
         If GroupLimit>0 Then Begin
          ModType:=Buffer[GroupPos];
          Inc(GroupPos);

          { Bit 6 du MODTYP : adresse de depart presente }
          If ((ModType And $40)<>0)And(GroupPos<GroupLimit) Then Begin
           EndDat:=Buffer[GroupPos];
           Inc(GroupPos);

           EntryFrameIdx:=0;
           EntryTargetIdx:=0;
           EntryDisp:=0;

           { Frame datum explicite si F=0 (bit 7) et methode 0..2 }
           FrameMethod:=(EndDat Shr 4) And $07;
           If ((EndDat And $80)=0)And(FrameMethod<=2) Then
      If Not ReadOmfIndex(GroupPos,GroupLimit,EntryFrameIdx) Then GroupPos:=GroupLimit;

           { Target datum explicite si T=0 (bit 3) et methode 0..2 }
           TargetMethod:=EndDat And $03;
           If ((EndDat And $08)=0)And(TargetMethod<=2) Then
      If Not ReadOmfIndex(GroupPos,GroupLimit,EntryTargetIdx) Then GroupPos:=GroupLimit;

           { P=0 => displacement present }
           If (EndDat And $04)=0 Then Begin
      If RecType=$8B Then Begin
       If GroupPos+3<GroupLimit Then Begin
        EntryDisp:=LongInt(Buffer[GroupPos])
          + LongInt(Buffer[GroupPos+1]) * 256
          + LongInt(Buffer[GroupPos+2]) * 65536
          + LongInt(Buffer[GroupPos+3]) * 16777216;
        Inc(GroupPos,4);
       End;
      End Else Begin
       If GroupPos+1<GroupLimit Then Begin
        EntryDisp:=Buffer[GroupPos]+LongInt(Buffer[GroupPos+1])*256;
        Inc(GroupPos,2);
       End;
      End;
           End;

                 { Cas supporte pour MZ: cible segment (SEGDEF index) }
                 If (TargetMethod=0)And(EntryTargetIdx>0) Then Begin
              EntrySegIndex:=MapSegIndexLocal(EntryTargetIdx);
              If EntrySegIndex>0 Then Begin
               HasEntryPoint:=True;
               EntryOffset:=EntryDisp;
              End;
           End;
          End;

                { Compatibilite pratique: certains OBJ codent MODEND avec 2 index sur 16 bits }
                If (Not HasEntryPoint)And((ModType And $01)<>0) Then Begin
                 If (RecType=$8A)And(GroupLimit>=7) Then Begin
            EntryFrameIdx:=Word(Buffer[1]) * 256 + Buffer[2];
            EntryTargetIdx:=Word(Buffer[3]) * 256 + Buffer[4];
            EntryDisp:=Buffer[5] + LongInt(Buffer[6]) * 256;
            If EntryTargetIdx=0 Then EntryTargetIdx:=EntryFrameIdx;
            EntrySegIndex:=MapSegIndexLocal(EntryTargetIdx);
            If EntrySegIndex>0 Then Begin
             HasEntryPoint:=True;
             EntryOffset:=EntryDisp;
            End;
                 End Else If (RecType=$8B)And(GroupLimit>=9) Then Begin
            EntryFrameIdx:=Word(Buffer[1]) * 256 + Buffer[2];
            EntryTargetIdx:=Word(Buffer[3]) * 256 + Buffer[4];
            EntryDisp:=LongInt(Buffer[5])
              + LongInt(Buffer[6]) * 256
              + LongInt(Buffer[7]) * 65536
              + LongInt(Buffer[8]) * 16777216;
            If EntryTargetIdx=0 Then EntryTargetIdx:=EntryFrameIdx;
            EntrySegIndex:=MapSegIndexLocal(EntryTargetIdx);
            If EntrySegIndex>0 Then Begin
             HasEntryPoint:=True;
             EntryOffset:=EntryDisp;
            End;
                 End;
                End;
         End;
     ModuleEnded:=True;
    End;
    $8C, $8D, $B4, $B5, $CC, $CD:Begin { EXTDEF/LEXTDEF/CEXTDEF(compat) : references externes }
     ExtPos:=0;
     ExtLimit:=RecLen-1; { sans checksum }
     If ExtLimit<=0 Then Continue;

     While ExtPos<ExtLimit do Begin
      ParsedNameLen:=Buffer[ExtPos];
      Inc(ExtPos);
      If (ParsedNameLen=0)Or(ExtPos>ExtLimit) Then Break;
      If ExtPos+ParsedNameLen>ExtLimit Then ParsedNameLen:=ExtLimit-ExtPos;

      ParsedName:='';
      For k:=1 to ParsedNameLen do Begin
       ParsedName:=ParsedName+Chr(Buffer[ExtPos]);
       Inc(ExtPos);
      End;

      If Not ReadOmfIndex(ExtPos,ExtLimit,PubTypeIdx) Then Break;

      If SymbolCount>=MAX_SYMBOLS Then Begin
       WriteLn('Erreur : Trop de symboles externes');
       Halt(13);
      End;

      SymRec.Name:=Copy(ParsedName,1,32);
      SymRec.Segment:=0;
      SymRec.Offset:=0;
      SymRec.IsExternal:=True;
      AddSymbol(SymRec);
     End;
    End;
    $8E, $8F:Begin
     { TYPDEF / ancien PUBDEF(32) : tentative de decode PUBDEF, sinon ignore }
     PubPos:=0;
     PubLimit:=RecLen-1; { sans checksum }
     LegacyPubParsed:=0;
     If PubLimit<=0 Then Continue;

     If ReadOmfIndex(PubPos,PubLimit,BaseGroupIdx)
        And ReadOmfIndex(PubPos,PubLimit,BaseSegIdx) Then Begin

      BaseSegIdx:=MapSegIndexLocal(BaseSegIdx);

      { Garde-fou: index segment aberrant => probablement TYPDEF }
      If BaseSegIdx>MAX_SEGMENTS Then PubPos:=PubLimit;

      { Cas special OMF : BaseSeg=0 => frame explicite }
      If BaseSegIdx=0 Then Begin
       If RecType=$8F Then Begin
        If PubPos+3<PubLimit Then Inc(PubPos,4)
                            Else PubPos:=PubLimit;
       End Else Begin
        If PubPos+1<PubLimit Then Inc(PubPos,2)
                            Else PubPos:=PubLimit;
       End;
      End;

      While PubPos<PubLimit do Begin
       ParsedNameLen:=Buffer[PubPos];
       Inc(PubPos);
       If (ParsedNameLen=0)Or(PubPos>PubLimit) Then Break;
       If PubPos+ParsedNameLen>PubLimit Then ParsedNameLen:=PubLimit-PubPos;

       ParsedName:='';
       For k:=1 to ParsedNameLen do Begin
        ParsedName:=ParsedName+Chr(Buffer[PubPos]);
        Inc(PubPos);
       End;
       If ParsedName='' Then Break;

       If RecType=$8F Then Begin
        If PubPos+3>=PubLimit Then Break;
        PubOfs:=LongInt(Buffer[PubPos])
              + LongInt(Buffer[PubPos+1]) * 256
              + LongInt(Buffer[PubPos+2]) * 65536
              + LongInt(Buffer[PubPos+3]) * 16777216;
        Inc(PubPos,4);
       End Else Begin
        If PubPos+1>=PubLimit Then Break;
        PubOfs:=Buffer[PubPos]+LongInt(Buffer[PubPos+1])*256;
        Inc(PubPos,2);
       End;

       If Not ReadOmfIndex(PubPos,PubLimit,PubTypeIdx) Then Break;

       If SymbolCount>=MAX_SYMBOLS Then Begin
        WriteLn('Erreur : Trop de symboles publics');
        Halt(12);
       End;

       SymRec.Name:=Copy(ParsedName,1,32);
       SymRec.Segment:=BaseSegIdx;
       If PubOfs<0 Then SymRec.Offset:=0
       Else If PubOfs>$FFFF Then SymRec.Offset:=$FFFF
       Else SymRec.Offset:=PubOfs;
       SymRec.IsExternal:=False;
       AddSymbol(SymRec);
       Inc(LegacyPubParsed);
      End;
     End;

     { Si aucun symbole extrait, on considere le record comme TYPDEF et on l'ignore }
    End;
    $90, $91:Begin
     { PUBDEF/PUBDEF32 : definition publique }
     PubPos:=0;
     PubLimit:=RecLen-1; { sans checksum }
     If PubLimit<=0 Then Continue;
     If Not ReadOmfIndex(PubPos,PubLimit,BaseGroupIdx) Then Continue;
     If Not ReadOmfIndex(PubPos,PubLimit,BaseSegIdx) Then Continue;
    BaseSegIdx:=MapSegIndexLocal(BaseSegIdx);

     { Cas special OMF : BaseSeg=0 => frame explicite }
     If BaseSegIdx=0 Then Begin
      If RecType=$91 Then Begin
       If PubPos+3<PubLimit Then Inc(PubPos,4)
                           Else Continue;
      End Else Begin
       If PubPos+1<PubLimit Then Inc(PubPos,2)
                           Else Continue;
      End;
     End;

     While PubPos<PubLimit do Begin
      ParsedNameLen:=Buffer[PubPos];
      Inc(PubPos);
      If (ParsedNameLen=0)Or(PubPos>PubLimit) Then Break;
      If PubPos+ParsedNameLen>PubLimit Then ParsedNameLen:=PubLimit-PubPos;

      ParsedName:='';
      For k:=1 to ParsedNameLen do Begin
       ParsedName:=ParsedName+Chr(Buffer[PubPos]);
       Inc(PubPos);
      End;

      If RecType=$91 Then Begin
       If PubPos+3>=PubLimit Then Break;
       PubOfs:=LongInt(Buffer[PubPos])
             + LongInt(Buffer[PubPos+1]) * 256
             + LongInt(Buffer[PubPos+2]) * 65536
             + LongInt(Buffer[PubPos+3]) * 16777216;
       Inc(PubPos,4);
      End Else Begin
       If PubPos+1>=PubLimit Then Break;
       PubOfs:=Buffer[PubPos]+LongInt(Buffer[PubPos+1])*256;
       Inc(PubPos,2);
      End;

      If Not ReadOmfIndex(PubPos,PubLimit,PubTypeIdx) Then Break;

      If SymbolCount>=MAX_SYMBOLS Then Begin
       WriteLn('Erreur : Trop de symboles publics');
       Halt(12);
      End;

      SymRec.Name:=Copy(ParsedName,1,32);
      SymRec.Segment:=BaseSegIdx;
      If PubOfs<0 Then SymRec.Offset:=0
      Else If PubOfs>$FFFF Then SymRec.Offset:=$FFFF
      Else SymRec.Offset:=PubOfs;
      SymRec.IsExternal:=False;
      AddSymbol(SymRec);
     End;
    End;
    $92, $93, $B6, $B7:Begin
     { LPUBDEF/LPUBDEF32 : definition publique locale }
     PubPos:=0;
     PubLimit:=RecLen-1; { sans checksum }
     If PubLimit<=0 Then Continue;
     If Not ReadOmfIndex(PubPos,PubLimit,BaseGroupIdx) Then Continue;
     If Not ReadOmfIndex(PubPos,PubLimit,BaseSegIdx) Then Continue;
    BaseSegIdx:=MapSegIndexLocal(BaseSegIdx);

     { Cas special OMF : BaseSeg=0 => frame explicite }
     If BaseSegIdx=0 Then Begin
      If (RecType=$93)Or(RecType=$B7) Then Begin
       If PubPos+3<PubLimit Then Inc(PubPos,4)
                           Else Continue;
      End Else Begin
       If PubPos+1<PubLimit Then Inc(PubPos,2)
                           Else Continue;
      End;
     End;

     While PubPos<PubLimit do Begin
      ParsedNameLen:=Buffer[PubPos];
      Inc(PubPos);
      If PubPos>PubLimit Then Break;
      If PubPos+ParsedNameLen>PubLimit Then ParsedNameLen:=PubLimit-PubPos;

      ParsedName:='';
      For k:=1 to ParsedNameLen do Begin
       ParsedName:=ParsedName+Chr(Buffer[PubPos]);
       Inc(PubPos);
      End;

      If (RecType=$93)Or(RecType=$B7) Then Begin
       If PubPos+3>=PubLimit Then Break;
       PubOfs:=LongInt(Buffer[PubPos])
             + LongInt(Buffer[PubPos+1]) * 256
             + LongInt(Buffer[PubPos+2]) * 65536
             + LongInt(Buffer[PubPos+3]) * 16777216;
       Inc(PubPos,4);
      End Else Begin
       If PubPos+1>=PubLimit Then Break;
       PubOfs:=Buffer[PubPos]+LongInt(Buffer[PubPos+1])*256;
       Inc(PubPos,2);
      End;

      If Not ReadOmfIndex(PubPos,PubLimit,PubTypeIdx) Then Break;

      If SymbolCount>=MAX_SYMBOLS Then Begin
       WriteLn('Erreur : Trop de symboles publics locaux');
       Halt(12);
      End;

      SymRec.Name:=Copy(ParsedName,1,32);
      SymRec.Segment:=BaseSegIdx;
      If PubOfs<0 Then SymRec.Offset:=0
      Else If PubOfs>$FFFF Then SymRec.Offset:=$FFFF
      Else SymRec.Offset:=PubOfs;
      SymRec.IsExternal:=False;
      AddSymbol(SymRec);
     End;
    End;
    $94, $95:Begin
     { LINNUM/LINNUM32 : information de lignes source }
     LinePos:=0;
     LineLimit:=RecLen-1; { sans checksum }
     If LineLimit<=0 Then Continue;
     If Not ReadOmfIndex(LinePos,LineLimit,BaseGroupIdx) Then Continue;
     If Not ReadOmfIndex(LinePos,LineLimit,BaseSegIdx) Then Continue;
    BaseSegIdx:=MapSegIndexLocal(BaseSegIdx);

     While LinePos<LineLimit do Begin
      If LinePos+1>=LineLimit Then Break;
      LineNum:=Buffer[LinePos]+LongInt(Buffer[LinePos+1])*256;
      Inc(LinePos,2);

      If RecType=$95 Then Begin
       If LinePos+3>=LineLimit Then Break;
       LineOfs:=LongInt(Buffer[LinePos])
              + LongInt(Buffer[LinePos+1]) * 256
              + LongInt(Buffer[LinePos+2]) * 65536
              + LongInt(Buffer[LinePos+3]) * 16777216;
       Inc(LinePos,4);
      End Else Begin
       If LinePos+1>=LineLimit Then Break;
       LineOfs:=Buffer[LinePos]+LongInt(Buffer[LinePos+1])*256;
       Inc(LinePos,2);
      End;

      AddLineInfo(BaseGroupIdx,BaseSegIdx,LineNum,LineOfs,RecType=$95);
     End;
    End;
    $96, $97, $CA, $CB:Begin
     { LNAMES/LLNAMES : table de noms logiques (segments/classes/overlays) }
     NamePos:=0;
     NameLimit:=RecLen-1; { sans checksum }
     While NamePos<NameLimit do Begin
      ParsedNameLen:=Buffer[NamePos];
      Inc(NamePos);
      If NamePos>NameLimit Then Break;
      If NamePos+ParsedNameLen>NameLimit Then ParsedNameLen:=NameLimit-NamePos;

      ParsedName:='';
      For k:=1 to ParsedNameLen do Begin
       ParsedName:=ParsedName+Chr(Buffer[NamePos]);
       Inc(NamePos);
      End;
      AddLName(ParsedName);
      Inc(LocalLNameCount);
     End;
    End;
    $99:Begin
     { SEGDEF32 : definition de segment avec taille 32 bits }
      SegRec.Name:='';
      SegRec.Class:='CODE';
      SegSize32:=0;
      If RecLen>=6 Then
       SegSize32:=LongInt(Buffer[1])
                 + LongInt(Buffer[2]) * 256
                 + LongInt(Buffer[3]) * 65536
                 + LongInt(Buffer[4]) * 16777216;
      If SegSize32>$FFFF Then SegRec.Size:=$FFFF
                          Else SegRec.Size:=SegSize32;
      SegRec.Address:=0;

      { tentative de resolution des index de noms via LNAMES }
      GroupPos:=0;
      GroupLimit:=RecLen-1;
      If GroupLimit>0 Then Begin
       Inc(GroupPos);      { ACBP }
       Inc(GroupPos,4);    { longueur 32 bits }
       If ReadOmfIndex(GroupPos,GroupLimit,SegNameIdx) Then Begin
        If ReadOmfIndex(GroupPos,GroupLimit,SegClassIdx) Then Begin
         ReadOmfIndex(GroupPos,GroupLimit,SegOverlayIdx);
           SegNameIdx:=MapLNameIndexLocal(SegNameIdx);
           SegClassIdx:=MapLNameIndexLocal(SegClassIdx);
         ParsedName:=GetLName(SegNameIdx);
         ParsedClass:=GetLName(SegClassIdx);
         If ParsedName<>'' Then SegRec.Name:=Copy(ParsedName,1,16);
         If ParsedClass<>'' Then SegRec.Class:=Copy(ParsedClass,1,8);
        End;
       End;
      End;

      AddSegment(SegRec);
        Inc(LocalSegCount);
    End;
    $9A, $9B:Begin
      { GRPDEF / GRPDEF32 : definition de groupes de segments }
      If NoGroupAssociation Then Continue;
      GroupPos:=0;
      GroupLimit:=RecLen-1;  { sans checksum OMF }
      If GroupLimit<=0 Then Continue;
      If Not ReadOmfIndex(GroupPos,GroupLimit,GroupNameIdx) Then Continue;
      GroupNameIdx:=MapLNameIndexLocal(GroupNameIdx);

      GroupPtr:=AddGroup(GroupNameIdx, RecType=$9B);

      While GroupPos<GroupLimit do Begin
       GroupItemType:=Buffer[GroupPos];
       Inc(GroupPos);
       Case GroupItemType of
        $FF:Begin { composant segment }
         If Not ReadOmfIndex(GroupPos,GroupLimit,GroupMemberIdx) Then Break;
         GroupMemberIdx:=MapSegIndexLocal(GroupMemberIdx);
         AddGroupMember(GroupPtr,GroupMemberIdx);
        End;
        $FE, $FD:Begin
         { composant externe/groupe : consommer l'index, non resolu ici }
         If Not ReadOmfIndex(GroupPos,GroupLimit,GroupMemberIdx) Then Break;
        End;
       Else
        { Tolerance format : tentative index direct }
        Dec(GroupPos);
        If Not ReadOmfIndex(GroupPos,GroupLimit,GroupMemberIdx) Then Break;
        GroupMemberIdx:=MapSegIndexLocal(GroupMemberIdx);
        AddGroupMember(GroupPtr,GroupMemberIdx);
       End;
      End;
    End;
    $9C, $9D:Begin
      { FIXUPP / FIXUPP32 : extraction des relocations chargeur MZ }
      If (Not HasDataContext)Or(LastDataSeg=0)Or(LastDataSeg>SegmentCount) Then Continue;
      If RecLen<2 Then Continue;

      { Le dernier octet est le checksum OMF }
      FixPos:=0;
      FixLimit:=RecLen-1;

      While FixPos<FixLimit do Begin
       FixByte:=Buffer[FixPos];
       Inc(FixPos);

       If (FixByte And $80)=0 Then Begin
        { THREAD subrecord : on ne decode pas l'etat interne ici }
        { Le byte de thread est consomme, on poursuit le balayage }
        Continue;
       End;

       { FIXUP subrecord }
       Locat:=FixByte;
       If FixPos>=FixLimit Then Break;
       LocOfs:=(Word(Locat And $03) Shl 8) Or Buffer[FixPos];
       Inc(FixPos);
       LocKind:=(Locat Shr 2) And $0F;
      LocIsSelfRel:=(Locat And $40)<>0;

       If FixPos>=FixLimit Then Break;
       FixDat:=Buffer[FixPos];
       Inc(FixPos);

       { Frame datum explicite }
       If (FixDat And $80)<>0 Then Begin
        FrameMethod:=(FixDat Shr 4) And $07;
        If FrameMethod<=2 Then Begin
         If FixPos>=FixLimit Then Break;
         FixByte:=Buffer[FixPos];
         Inc(FixPos);
         If (FixByte And $80)<>0 Then If FixPos<FixLimit Then Inc(FixPos) Else Break;
        End;
       End;

       { Target datum explicite }
       If (FixDat And $08)<>0 Then Begin
        TargetMethod:=FixDat And $03;
        If TargetMethod<=2 Then Begin
         If FixPos>=FixLimit Then Break;
         FixByte:=Buffer[FixPos];
         Inc(FixPos);
         If (FixByte And $80)<>0 Then If FixPos<FixLimit Then Inc(FixPos) Else Break;
        End;
       End;

       { Displacement cible si P=0 (bit 2 du FIXDAT) }
      If (FixDat And $04)<>0 Then Begin
        If RecType=$9D Then Begin
         If FixPos+3<FixLimit Then Inc(FixPos,4)
              Else FixPos:=FixLimit;
        End Else Begin
         If FixPos+1<FixLimit Then Inc(FixPos,2)
              Else FixPos:=FixLimit;
        End;
       End;

       { On ne genere des relocations MZ que pour BASE (2) et POINTER (3) }
       Case LocKind of
       1:RelocDataPos:=LongInt(LastDataOfs)+LongInt(LocOfs);           { OFFSET 16 }
        2: RelocDataPos:=LongInt(LastDataOfs)+LongInt(LocOfs);
        3: RelocDataPos:=LongInt(LastDataOfs)+LongInt(LocOfs)+2;
       Else
        RelocDataPos:=-1;
       End;

       If RelocDataPos>=0 Then Begin
        SegPtr:=GetSegmentPtr(LastDataSeg);
        If SegPtr=Nil Then Continue;
        RelocLinearPos:=SegPtr^.Address+RelocDataPos;

       { OFFSET segment-relatif : correction a l'edition de liens }
       If (LocKind=1)And(Not LocIsSelfRel) Then Begin
        If (RelocLinearPos>=0)And(RelocLinearPos<=1048575) Then Begin
         AddOffsetPatch(RelocLinearPos, SegPtr^.Address);
        End;
       End;

        If (RelocLinearPos>=0)And(RelocLinearPos<=1048575) Then Begin
         If LocKind In [2,3] Then
          AddRelocationEntry(RelocLinearPos Mod 16, RelocLinearPos Div 16, 0);
        End;
       End;
      End;
    End;
    $9E, $9F:Begin
     { Records OMF historiques/reserves }
     { Le payload est deja lu dans Buffer : on l'ignore volontairement }
    End;
    $B0, $B8:Begin
     { COMDEF/LCOMDEF : communaux, traites comme symboles externes }
     ExtPos:=0;
     ExtLimit:=RecLen-1; { sans checksum }
     If ExtLimit<=0 Then Continue;

     While ExtPos<ExtLimit do Begin
      ParsedNameLen:=Buffer[ExtPos];
      Inc(ExtPos);
      If (ParsedNameLen=0)Or(ExtPos>ExtLimit) Then Break;
      If ExtPos+ParsedNameLen>ExtLimit Then ParsedNameLen:=ExtLimit-ExtPos;

      ParsedName:='';
      For k:=1 to ParsedNameLen do Begin
       ParsedName:=ParsedName+Chr(Buffer[ExtPos]);
       Inc(ExtPos);
      End;

      If Not ReadOmfIndex(ExtPos,ExtLimit,PubTypeIdx) Then Break;
      If ExtPos>=ExtLimit Then Break;

      ComDataType:=Buffer[ExtPos];
      Inc(ExtPos);
      Case ComDataType of
       $61:Begin
      If Not SkipComdefNumber(ExtPos,ExtLimit) Then Break;
      If Not SkipComdefNumber(ExtPos,ExtLimit) Then Break;
       End;
       $62:Begin
      If Not SkipComdefNumber(ExtPos,ExtLimit) Then Break;
       End;
      Else
       Break;
      End;

      If SymbolCount>=MAX_SYMBOLS Then Begin
       WriteLn('Erreur : Trop de symboles externes');
       Halt(13);
      End;

      SymRec.Name:=Copy(ParsedName,1,32);
      SymRec.Segment:=0;
      SymRec.Offset:=0;
      SymRec.IsExternal:=True;
      AddSymbol(SymRec);
     End;
    End;
   $98:Begin { SEGDEF : Dï¿½finition de segment OMF }
      SegRec.Name:='';
      SegRec.Class:='CODE';
      If RecLen>=4 Then Move(Buffer[1], SegRec.Size, 2)
            Else SegRec.Size:=0;
      SegRec.Address:=0;

      { tentative de resolution des index de noms via LNAMES }
      GroupPos:=0;
      GroupLimit:=RecLen-1;
      If GroupLimit>0 Then Begin
       Inc(GroupPos);      { ACBP }
       Inc(GroupPos,2);    { longueur 16 bits }
       If ReadOmfIndex(GroupPos,GroupLimit,SegNameIdx) Then Begin
        If ReadOmfIndex(GroupPos,GroupLimit,SegClassIdx) Then Begin
         ReadOmfIndex(GroupPos,GroupLimit,SegOverlayIdx);
          SegNameIdx:=MapLNameIndexLocal(SegNameIdx);
          SegClassIdx:=MapLNameIndexLocal(SegClassIdx);
         ParsedName:=GetLName(SegNameIdx);
         ParsedClass:=GetLName(SegClassIdx);
         If ParsedName<>'' Then SegRec.Name:=Copy(ParsedName,1,16);
         If ParsedClass<>'' Then SegRec.Class:=Copy(ParsedClass,1,8);
        End;
       End;
      End;

      AddSegment(SegRec);
        Inc(LocalSegCount);
   End;
   $A0:Begin { LEDATA : Donn‚es de segment }
    If RecLen>=5 Then Begin
     IdxSize:=1;
     SegIndex:=Buffer[0];
     If (SegIndex And $80)<>0 Then Begin
      If RecLen<6 Then Continue;
      SegIndex:=((SegIndex And $7F) Shl 8) Or Buffer[1];
      IdxSize:=2;
     End;
    SegIndex:=MapSegIndexLocal(SegIndex);
     Move(Buffer[IdxSize],SegOffset,2);
     DataLen:=RecLen-IdxSize-2-1; { -index -offset -checksum }
     If (SegIndex>0)And(SegIndex<=SegmentCount) Then Begin
      SegPtr:=GetSegmentPtr(SegIndex);
      If SegPtr<>Nil Then Begin
       EndPos:=LongInt(SegOffset)+LongInt(DataLen);
       If EndPos>$FFFF Then EndPos:=$FFFF;
       If EndPos>SegPtr^.Size Then SegPtr^.Size:=EndPos;
       LastDataSeg:=SegIndex;
       LastDataOfs:=SegOffset;
       HasDataContext:=True;
      End;
     End;
    End;
   End;
      $A1:Begin
       { LEDATA/LIDATA 32-bit : support pragmatique (brut ou itere) }
       GroupPos:=0;
       GroupLimit:=RecLen-1; { sans checksum }
       If GroupLimit<=0 Then Continue;

       SegIndex:=Buffer[GroupPos];
       Inc(GroupPos);
       If (SegIndex And $80)<>0 Then Begin
        If GroupPos>=GroupLimit Then Continue;
        SegIndex:=((SegIndex And $7F) Shl 8) Or Buffer[GroupPos];
        Inc(GroupPos);
       End;
      SegIndex:=MapSegIndexLocal(SegIndex);

       If GroupPos+3>=GroupLimit Then Continue;
       DataOfs32:=LongInt(Buffer[GroupPos])
         + LongInt(Buffer[GroupPos+1]) * 256
         + LongInt(Buffer[GroupPos+2]) * 65536
         + LongInt(Buffer[GroupPos+3]) * 16777216;
       Inc(GroupPos,4);

       IterLen:=0;
       TmpPos:=GroupPos;
       ParseOK:=True;
       While TmpPos<GroupLimit do Begin
        BlockLen:=0;
        If Not SkipIterBlockEx(Buffer,TmpPos,GroupLimit,True,BlockLen) Then Begin
         ParseOK:=False;
         Break;
        End;
        If IterLen>High(LongInt)-BlockLen Then IterLen:=High(LongInt)
            Else Inc(IterLen,BlockLen);
       End;

      If Not(ParseOK And (TmpPos=GroupLimit)) Then Begin
        IterLen:=0;
        TmpPos:=GroupPos;
        ParseOK:=True;
        While TmpPos<GroupLimit do Begin
         BlockLen:=0;
         If Not SkipIterBlockEx(Buffer,TmpPos,GroupLimit,False,BlockLen) Then Begin
          ParseOK:=False;
          Break;
         End;
         If IterLen>High(LongInt)-BlockLen Then IterLen:=High(LongInt)
             Else Inc(IterLen,BlockLen);
        End;
        If Not(ParseOK And (TmpPos=GroupLimit)) Then IterLen:=GroupLimit-GroupPos;
       End;

       If (SegIndex>0)And(SegIndex<=SegmentCount) Then Begin
        SegPtr:=GetSegmentPtr(SegIndex);
        If SegPtr<>Nil Then Begin
         EndPos:=DataOfs32+IterLen;
         If (DataOfs32<0)Or(EndPos<0)Or(EndPos>$FFFF) Then EndPos:=$FFFF;
         If EndPos>SegPtr^.Size Then SegPtr^.Size:=EndPos;
         LastDataSeg:=SegIndex;
         If DataOfs32<0 Then LastDataOfs:=0
         Else If DataOfs32>$FFFF Then LastDataOfs:=$FFFF
         Else LastDataOfs:=DataOfs32;
         HasDataContext:=True;
        End;
       End;
      End;
      $A2, $A3:Begin
             { LIDATA / LIDATA32 : donnees iterees }
             GroupPos:=0;
             GroupLimit:=RecLen-1; { sans checksum }
             If GroupLimit<=0 Then Continue;

             SegIndex:=Buffer[GroupPos];
             Inc(GroupPos);
             If (SegIndex And $80)<>0 Then Begin
        If GroupPos>=GroupLimit Then Continue;
        SegIndex:=((SegIndex And $7F) Shl 8) Or Buffer[GroupPos];
        Inc(GroupPos);
             End;
               SegIndex:=MapSegIndexLocal(SegIndex);

             If RecType=$A3 Then Begin
        If GroupPos+3>=GroupLimit Then Continue;
        DataOfs32:=LongInt(Buffer[GroupPos])
          + LongInt(Buffer[GroupPos+1]) * 256
          + LongInt(Buffer[GroupPos+2]) * 65536
          + LongInt(Buffer[GroupPos+3]) * 16777216;
        Inc(GroupPos,4);
             End Else Begin
        If GroupPos+1>=GroupLimit Then Continue;
        DataOfs32:=Buffer[GroupPos]+LongInt(Buffer[GroupPos+1])*256;
        Inc(GroupPos,2);
             End;

             IterLen:=0;
             If RecType=$A3 Then Begin
        TmpPos:=GroupPos;
        ParseOK:=True;
        While TmpPos<GroupLimit do Begin
         BlockLen:=0;
         If Not SkipIterBlockEx(Buffer,TmpPos,GroupLimit,True,BlockLen) Then Begin
          ParseOK:=False;
          Break;
         End;
         If IterLen>High(LongInt)-BlockLen Then IterLen:=High(LongInt)
                 Else Inc(IterLen,BlockLen);
        End;

        If Not ParseOK Then Begin
         IterLen:=0;
         TmpPos:=GroupPos;
         While TmpPos<GroupLimit do Begin
          BlockLen:=0;
          If Not SkipIterBlockEx(Buffer,TmpPos,GroupLimit,False,BlockLen) Then Break;
          If IterLen>High(LongInt)-BlockLen Then IterLen:=High(LongInt)
                  Else Inc(IterLen,BlockLen);
         End;
        End;
             End Else Begin
        TmpPos:=GroupPos;
        While TmpPos<GroupLimit do Begin
         BlockLen:=0;
         If Not SkipIterBlockEx(Buffer,TmpPos,GroupLimit,False,BlockLen) Then Break;
         If IterLen>High(LongInt)-BlockLen Then IterLen:=High(LongInt)
                 Else Inc(IterLen,BlockLen);
        End;
             End;

             If (SegIndex>0)And(SegIndex<=SegmentCount) Then Begin
        SegPtr:=GetSegmentPtr(SegIndex);
        If SegPtr<>Nil Then Begin
         EndPos:=DataOfs32+IterLen;
         If (DataOfs32<0)Or(EndPos<0)Or(EndPos>$FFFF) Then EndPos:=$FFFF;
         If EndPos>SegPtr^.Size Then SegPtr^.Size:=EndPos;
         LastDataSeg:=SegIndex;
         If DataOfs32<0 Then LastDataOfs:=0
         Else If DataOfs32>$FFFF Then LastDataOfs:=$FFFF
         Else LastDataOfs:=DataOfs32;
         HasDataContext:=True;
        End;
             End;
      End;
      $A4, $A5, $B2, $B3:Begin
        { BAKPAT / BAKPAT32 : enregistre les correctifs a appliquer }
        GroupPos:=0;
        GroupLimit:=RecLen-1; { sans checksum }
        If GroupLimit<=0 Then Continue;

        If Not ReadOmfIndex(GroupPos,GroupLimit,SegIndex) Then Continue;
        SegIndex:=MapSegIndexLocal(SegIndex);
        If GroupPos>=GroupLimit Then Continue;
        BakLocType:=Buffer[GroupPos];
        Inc(GroupPos);

        While GroupPos<GroupLimit do Begin
         If (RecType=$A5)Or(RecType=$B3) Then Begin
          If GroupPos+7>=GroupLimit Then Break;
          BakPatchOfs:=LongInt(Buffer[GroupPos])
               + LongInt(Buffer[GroupPos+1]) * 256
               + LongInt(Buffer[GroupPos+2]) * 65536
               + LongInt(Buffer[GroupPos+3]) * 16777216;
          BakPatchVal:=LongInt(Buffer[GroupPos+4])
               + LongInt(Buffer[GroupPos+5]) * 256
               + LongInt(Buffer[GroupPos+6]) * 65536
               + LongInt(Buffer[GroupPos+7]) * 16777216;
          Inc(GroupPos,8);
         End Else Begin
          If GroupPos+3>=GroupLimit Then Break;
          BakPatchOfs:=Buffer[GroupPos]+LongInt(Buffer[GroupPos+1])*256;
          BakPatchVal:=Buffer[GroupPos+2]+LongInt(Buffer[GroupPos+3])*256;
          Inc(GroupPos,4);
         End;

         AddBackPatch(SegIndex,BakLocType,BakPatchOfs,BakPatchVal,(RecType=$A5)Or(RecType=$B3));
        End;
      End;
      $A6, $A7, $C4, $C5:Begin
       { LINSYM / LINSYM32 : infos lignes associees a un symbole }
       GroupPos:=0;
       GroupLimit:=RecLen-1; { sans checksum }
       If GroupLimit<=0 Then Continue;

       If GroupPos>=GroupLimit Then Continue;
       LSymFlags:=Buffer[GroupPos];
       Inc(GroupPos);
       LSymContinue:=(LSymFlags And $01)<>0;

       If GroupPos>=GroupLimit Then Continue;
       ParsedNameLen:=Buffer[GroupPos];
       Inc(GroupPos);
       If ParsedNameLen>64 Then ParsedNameLen:=64;
       If GroupPos+ParsedNameLen>GroupLimit Then ParsedNameLen:=GroupLimit-GroupPos;

       LSymName:='';
       For k:=1 to ParsedNameLen do Begin
        LSymName:=LSymName+Chr(Buffer[GroupPos]);
        Inc(GroupPos);
       End;

       LSymSeg:=0;
       LSymBaseOfs:=0;
       If LSymName<>'' Then Begin
        If FindSymbolByName(LSymName,LSymSeg,LSymBaseOfs) Then Begin
         HasLastLSym:=True;
         LastLSymName:=LSymName;
         LastLSymSeg:=LSymSeg;
         LastLSymBaseOfs:=LSymBaseOfs;
        End Else HasLastLSym:=False;
       End Else If LSymContinue And HasLastLSym Then Begin
        LSymName:=LastLSymName;
        LSymSeg:=LastLSymSeg;
        LSymBaseOfs:=LastLSymBaseOfs;
       End;

       While GroupPos<GroupLimit do Begin
        If GroupPos+1>=GroupLimit Then Break;
        LineNum:=Buffer[GroupPos]+LongInt(Buffer[GroupPos+1])*256;
        Inc(GroupPos,2);

        If (RecType=$A7)Or(RecType=$C5) Then Begin
         If GroupPos+3>=GroupLimit Then Break;
         LineOfs:=LongInt(Buffer[GroupPos])
           + LongInt(Buffer[GroupPos+1]) * 256
           + LongInt(Buffer[GroupPos+2]) * 65536
           + LongInt(Buffer[GroupPos+3]) * 16777216;
         Inc(GroupPos,4);
        End Else Begin
         If GroupPos+1>=GroupLimit Then Break;
         LineOfs:=Buffer[GroupPos]+LongInt(Buffer[GroupPos+1])*256;
         Inc(GroupPos,2);
        End;

        AddLineInfo(0,LSymSeg,LineNum,LSymBaseOfs+LineOfs,(RecType=$A7)Or(RecType=$C5));
       End;
      End;
      $C2, $C3:Begin
       { COMDAT / COMDAT32 : donnees communales initialisees }
       GroupPos:=0;
       GroupLimit:=RecLen-1; { sans checksum }
       If GroupLimit<=0 Then Continue;
       If GroupPos+2>=GroupLimit Then Continue;

       ComdatFlags:=Buffer[GroupPos];
       Inc(GroupPos);
       ComdatAttr:=Buffer[GroupPos];
       Inc(GroupPos);
       ComdatAllocType:=ComdatAttr And $0F;

       Inc(GroupPos); { Align }
       If GroupPos>GroupLimit Then Continue;

       If RecType=$C3 Then Begin
        If GroupPos+3>=GroupLimit Then Continue;
        ComdatEnumOfs:=LongInt(Buffer[GroupPos])
             + LongInt(Buffer[GroupPos+1]) * 256
             + LongInt(Buffer[GroupPos+2]) * 65536
             + LongInt(Buffer[GroupPos+3]) * 16777216;
        Inc(GroupPos,4);
       End Else Begin
        If GroupPos+1>=GroupLimit Then Continue;
        ComdatEnumOfs:=Buffer[GroupPos]+LongInt(Buffer[GroupPos+1])*256;
        Inc(GroupPos,2);
       End;

       If Not ReadOmfIndex(GroupPos,GroupLimit,PubTypeIdx) Then Continue;

       LSymSeg:=0;
       LSymBaseOfs:=0;
       If ComdatAllocType=0 Then Begin
        If Not ReadOmfIndex(GroupPos,GroupLimit,BaseGroupIdx) Then Continue;
        If Not ReadOmfIndex(GroupPos,GroupLimit,BaseSegIdx) Then Continue;
        BaseSegIdx:=MapSegIndexLocal(BaseSegIdx);
        If BaseSegIdx=0 Then Begin
         If RecType=$C3 Then Begin
          If GroupPos+3<GroupLimit Then Inc(GroupPos,4)
              Else Continue;
         End Else Begin
          If GroupPos+1<GroupLimit Then Inc(GroupPos,2)
              Else Continue;
         End;
        End Else Begin
         LSymSeg:=BaseSegIdx;
         LSymBaseOfs:=0;
        End;
       End;

       If GroupPos>=GroupLimit Then Continue;
       ParsedNameLen:=Buffer[GroupPos];
       Inc(GroupPos);
       If ParsedNameLen>64 Then ParsedNameLen:=64;
       If GroupPos+ParsedNameLen>GroupLimit Then ParsedNameLen:=GroupLimit-GroupPos;

       ParsedName:='';
       For k:=1 to ParsedNameLen do Begin
        ParsedName:=ParsedName+Chr(Buffer[GroupPos]);
        Inc(GroupPos);
       End;

       If (LSymSeg=0)And(ParsedName<>'') Then
        FindSymbolByName(ParsedName,LSymSeg,LSymBaseOfs);

       IterLen:=0;
       If (ComdatFlags And $02)<>0 Then Begin
        If RecType=$C3 Then Begin
         TmpPos:=GroupPos;
         ParseOK:=True;
         While TmpPos<GroupLimit do Begin
          BlockLen:=0;
          If Not SkipIterBlockEx(Buffer,TmpPos,GroupLimit,True,BlockLen) Then Begin
           ParseOK:=False;
           Break;
          End;
          If IterLen>High(LongInt)-BlockLen Then IterLen:=High(LongInt)
               Else Inc(IterLen,BlockLen);
         End;
         If Not(ParseOK And (TmpPos=GroupLimit)) Then Begin
          IterLen:=0;
          TmpPos:=GroupPos;
          While TmpPos<GroupLimit do Begin
           BlockLen:=0;
           If Not SkipIterBlockEx(Buffer,TmpPos,GroupLimit,False,BlockLen) Then Break;
           If IterLen>High(LongInt)-BlockLen Then IterLen:=High(LongInt)
            Else Inc(IterLen,BlockLen);
          End;
         End;
        End Else Begin
         TmpPos:=GroupPos;
         While TmpPos<GroupLimit do Begin
          BlockLen:=0;
          If Not SkipIterBlockEx(Buffer,TmpPos,GroupLimit,False,BlockLen) Then Break;
          If IterLen>High(LongInt)-BlockLen Then IterLen:=High(LongInt)
               Else Inc(IterLen,BlockLen);
         End;
        End;
       End Else Begin
        IterLen:=GroupLimit-GroupPos;
       End;

       If (LSymSeg>0)And(LSymSeg<=SegmentCount) Then Begin
        SegPtr:=GetSegmentPtr(LSymSeg);
        If SegPtr<>Nil Then Begin
         EndPos:=LSymBaseOfs+ComdatEnumOfs+IterLen;
         If (ComdatEnumOfs<0)Or(EndPos<0)Or(EndPos>$FFFF) Then EndPos:=$FFFF;
         If EndPos>SegPtr^.Size Then SegPtr^.Size:=EndPos;
         LastDataSeg:=LSymSeg;
         PubOfs:=LSymBaseOfs+ComdatEnumOfs;
         If PubOfs<0 Then LastDataOfs:=0
         Else If PubOfs>$FFFF Then LastDataOfs:=$FFFF
         Else LastDataOfs:=PubOfs;
         HasDataContext:=True;
        End;
       End;
      End;
      $C8, $C9:Begin
       { NBKPAT / NBKPAT32 : backpatch nomme (COMDAT/public) }
       GroupPos:=0;
       GroupLimit:=RecLen-1; { sans checksum }
       If GroupLimit<=0 Then Continue;

       If GroupPos>=GroupLimit Then Continue;
       BakLocType:=Buffer[GroupPos] And $7F;
       Inc(GroupPos);

       If GroupPos>=GroupLimit Then Continue;
       ParsedNameLen:=Buffer[GroupPos];
       Inc(GroupPos);
       If ParsedNameLen>64 Then ParsedNameLen:=64;
       If GroupPos+ParsedNameLen>GroupLimit Then ParsedNameLen:=GroupLimit-GroupPos;

       ParsedName:='';
       For k:=1 to ParsedNameLen do Begin
        ParsedName:=ParsedName+Chr(Buffer[GroupPos]);
        Inc(GroupPos);
       End;

       LSymSeg:=0;
       LSymBaseOfs:=0;
       If Not FindSymbolByName(ParsedName,LSymSeg,LSymBaseOfs) Then Continue;

       While GroupPos<GroupLimit do Begin
        If RecType=$C9 Then Begin
         If GroupPos+7>=GroupLimit Then Break;
         BakPatchOfs:=LongInt(Buffer[GroupPos])
                   + LongInt(Buffer[GroupPos+1]) * 256
                   + LongInt(Buffer[GroupPos+2]) * 65536
                   + LongInt(Buffer[GroupPos+3]) * 16777216;
         BakPatchVal:=LongInt(Buffer[GroupPos+4])
                   + LongInt(Buffer[GroupPos+5]) * 256
                   + LongInt(Buffer[GroupPos+6]) * 65536
                   + LongInt(Buffer[GroupPos+7]) * 16777216;
         Inc(GroupPos,8);
        End Else Begin
         If GroupPos+3>=GroupLimit Then Break;
         BakPatchOfs:=Buffer[GroupPos]+LongInt(Buffer[GroupPos+1])*256;
         BakPatchVal:=Buffer[GroupPos+2]+LongInt(Buffer[GroupPos+3])*256;
         Inc(GroupPos,4);
        End;

        AddBackPatch(LSymSeg,BakLocType,LSymBaseOfs+BakPatchOfs,BakPatchVal,RecType=$C9);
       End;
      End;
      $C6, $C7:Begin
       { ALIAS / ALIAS32 : paires <alias><substitut> }
       GroupPos:=0;
       GroupLimit:=RecLen-1; { sans checksum }
       If GroupLimit<=0 Then Continue;

       While GroupPos<GroupLimit do Begin
        ParsedNameLen:=Buffer[GroupPos];
        Inc(GroupPos);
        If (ParsedNameLen=0)Or(GroupPos>GroupLimit) Then Break;
        If GroupPos+ParsedNameLen>GroupLimit Then Break;

        ParsedName:='';
        For k:=1 to ParsedNameLen do Begin
         ParsedName:=ParsedName+Chr(Buffer[GroupPos]);
         Inc(GroupPos);
        End;

        If GroupPos>=GroupLimit Then Break;
        ParsedNameLen:=Buffer[GroupPos];
        Inc(GroupPos);
        If (ParsedNameLen=0)Or(GroupPos>GroupLimit) Then Break;
        If GroupPos+ParsedNameLen>GroupLimit Then Break;

        ParsedClass:='';
        For k:=1 to ParsedNameLen do Begin
         ParsedClass:=ParsedClass+Chr(Buffer[GroupPos]);
         Inc(GroupPos);
        End;

        If (ParsedName<>'')And(ParsedClass<>'') Then AddAlias(ParsedName,ParsedClass);
       End;
      End;
      $CE:Begin
       { VENDEXT : extension OMF specifique vendeur (TIS 1.1) }
       { Format: VendorNumber(2 octets) + Extension Bytes (opaques) }
       GroupPos:=0;
       GroupLimit:=RecLen-1; { sans checksum }
       If GroupLimit<=0 Then Continue;
       If GroupPos+1>=GroupLimit Then Continue;

       { VendorNumber (little-endian), volontairement non exploite }
       BaseGroupIdx:=Buffer[GroupPos]+Word(Buffer[GroupPos+1])*256;
       Inc(GroupPos,2);

       { Le reste du record est opaque et ignore pour compatibilite }
      End;
      $CF..$FF:Begin
       { CFh..FFh : extensions/reserves OMF (format non standardise) }
       { Strategie prudente : charge utile opaque, ignoree en compatibilite }
       GroupPos:=0;
       GroupLimit:=RecLen-1; { sans checksum }
       If GroupLimit<=0 Then Continue;

       { Eventuel sous-type octet en tete (si present), non exploite }
       If GroupPos<GroupLimit Then Begin
        BakLocType:=Buffer[GroupPos];
        Inc(GroupPos);
       End;

       { Le reste est considere opaque }
      End;
        $A8..$AF, $B1, $B9..$BF, $C0, $C1:Begin
       { Codes OMF etendus/reserves non pris en charge : ignorer }
      End;
  End;
 End;
 Close(ObjFile);
 ReadObjFile:=True;
End;

Function ReadRecordHeaderAt(Var InF:File; Const Pos,Limit:LongInt;
                            Var RecType:Byte; Var RecLen:Word):Boolean;
Begin
 ReadRecordHeaderAt:=False;
 If (Pos<0)Or(Pos+3>Limit) Then Exit;
 Seek(InF,Pos);
 BlockRead(InF,RecType,1);
 BlockRead(InF,RecLen,2);
 If RecType<$80 Then RecType:=RecType Or $80;
 If (RecLen=0)Or(Pos+3+LongInt(RecLen)>Limit) Then Exit;
 ReadRecordHeaderAt:=True;
End;

Function ReadOmfRecordAt(Var InF:File; Const Pos,Limit:LongInt;
                         Var RecType:Byte; Var RecLen:Word;
                         Var RecBuf:TObjRecBuffer):Boolean;
Begin
 ReadOmfRecordAt:=False;
 If Not ReadRecordHeaderAt(InF,Pos,Limit,RecType,RecLen) Then Exit;
 If RecLen>SizeOf(RecBuf) Then Exit;
 Seek(InF,Pos+3);
 BlockRead(InF,RecBuf,RecLen);
 ReadOmfRecordAt:=True;
End;

Function ReadOmfIndexFromBuf(Var RecBuf:TObjRecBuffer; Var Pos:Integer;
                             Limit:Integer; Var Idx:Word):Boolean;
Var
 b:Byte;
Begin
 ReadOmfIndexFromBuf:=False;
 If Pos>=Limit Then Exit;
 b:=RecBuf[Pos];
 Inc(Pos);
 If (b And $80)<>0 Then Begin
  If Pos>=Limit Then Exit;
  Idx:=((Word(b And $7F) Shl 8) Or RecBuf[Pos]);
  Inc(Pos);
 End Else Idx:=b;
 ReadOmfIndexFromBuf:=True;
End;

Function PublicRecordDefinesNeededSymbol(Const RecType:Byte;
                                         Var RecBuf:TObjRecBuffer;
                                         Const RecLen:Word;
                                         Const LibName,ModuleName:String;
                                         Const DoTrace:Boolean;
                                         Var PublicCount,NeededCount:Integer):Boolean;
Var
 PubPos,PubLimit:Integer;
 ParsedName:String[64];
 ParsedNameLen:Byte;
 BaseGroupIdx,BaseSegIdx,PubTypeIdx:Word;
 k:Integer;
 Is32Rec:Boolean;
 SymbolNeeded:Boolean;
 DisplayModuleName:String[64];
Begin
 PublicRecordDefinesNeededSymbol:=False;
 PubPos:=0;
 PubLimit:=RecLen-1; { sans checksum }
 If PubLimit<=0 Then Exit;
 If ModuleName='' Then DisplayModuleName:='(sans_nom)'
                 Else DisplayModuleName:=ModuleName;

 If Not ReadOmfIndexFromBuf(RecBuf,PubPos,PubLimit,BaseGroupIdx) Then Exit;
 If Not ReadOmfIndexFromBuf(RecBuf,PubPos,PubLimit,BaseSegIdx) Then Exit;

 Is32Rec:=RecType In [$8F,$91,$93,$B7];
 If BaseSegIdx=0 Then Begin
  If Is32Rec Then Begin
   If PubPos+3<PubLimit Then Inc(PubPos,4)
                      Else Exit;
  End Else Begin
   If PubPos+1<PubLimit Then Inc(PubPos,2)
                      Else Exit;
  End;
 End;

 While PubPos<PubLimit do Begin
  ParsedNameLen:=RecBuf[PubPos];
  Inc(PubPos);
  If (ParsedNameLen=0)Or(PubPos>PubLimit) Then Break;
  If PubPos+ParsedNameLen>PubLimit Then ParsedNameLen:=PubLimit-PubPos;

  ParsedName:='';
  For k:=1 to ParsedNameLen do Begin
   ParsedName:=ParsedName+Chr(RecBuf[PubPos]);
   Inc(PubPos);
  End;

  If Is32Rec Then Begin
   If PubPos+3>=PubLimit Then Break;
   Inc(PubPos,4);
  End Else Begin
   If PubPos+1>=PubLimit Then Break;
   Inc(PubPos,2);
  End;

  If Not ReadOmfIndexFromBuf(RecBuf,PubPos,PubLimit,PubTypeIdx) Then Break;

  SymbolNeeded:=IsExternalNameUnresolved(ParsedName);
  Inc(PublicCount);
  If SymbolNeeded Then Begin
   Inc(NeededCount);
   PublicRecordDefinesNeededSymbol:=True;
  End;

  If DoTrace And TraceLibSymbolsRequested And TraceSymbolMatches(ParsedName) Then Begin
   If SymbolNeeded Then
    WriteLn('TRACE LIB:   symbole ',LibName,'::',DisplayModuleName,' -> ',ParsedName,' [utile]')
   Else
    WriteLn('TRACE LIB:   symbole ',LibName,'::',DisplayModuleName,' -> ',ParsedName,' [ignore]');
  End;
 End;
End;

Function ModuleDefinesNeededSymbol(Var LibF:File;
                                   Const ModStart,ModEnd:LongInt;
                                   Const LibName,ModuleName:String;
                                   Const DoTrace:Boolean;
                                   Var PublicCount,NeededCount:Integer):Boolean;
Var
 Pos:LongInt;
 RecType:Byte;
 RecLen:Word;
 RecBuf:TObjRecBuffer;
Begin
 ModuleDefinesNeededSymbol:=False;
 PublicCount:=0;
 NeededCount:=0;
 Pos:=ModStart;
 While Pos<ModEnd do Begin
  If Not ReadOmfRecordAt(LibF,Pos,ModEnd,RecType,RecLen,RecBuf) Then Exit;
  If RecType In [$8E,$8F,$90,$91,$92,$93,$B6,$B7] Then
   If PublicRecordDefinesNeededSymbol(RecType,RecBuf,RecLen,
                                      LibName,ModuleName,DoTrace,
                                      PublicCount,NeededCount) Then
    ModuleDefinesNeededSymbol:=True;
  Inc(Pos,3+RecLen);
 End;
End;

Function TryParseOmfModuleRange(Var LibF:File; Const FileLimit,StartPos:LongInt;
                                Var ModEnd:LongInt; Var ModName:TStr64):Boolean;
Var
 Pos,NextPos:LongInt;
 RecType:Byte;
 RecLen:Word;
 RecBuf:TObjRecBuffer;
 NameLen:Byte;
 k:Integer;
Begin
 TryParseOmfModuleRange:=False;
 ModEnd:=0;
 ModName:='';

 If Not ReadOmfRecordAt(LibF,StartPos,FileLimit,RecType,RecLen,RecBuf) Then Exit;
 If Not (RecType In [$80,$82]) Then Exit;

 If RecLen>=2 Then Begin
  NameLen:=RecBuf[0];
  If NameLen>(RecLen-2) Then NameLen:=RecLen-2;
  If NameLen>64 Then NameLen:=64;
  For k:=1 to NameLen do ModName:=ModName+Chr(RecBuf[k]);
 End;

 Pos:=StartPos;
 While Pos<FileLimit do Begin
  If Not ReadRecordHeaderAt(LibF,Pos,FileLimit,RecType,RecLen) Then Exit;
  NextPos:=Pos+3+RecLen;
  If NextPos>FileLimit Then Exit;
  If RecType In [$8A,$8B] Then Begin
   ModEnd:=NextPos;
   TryParseOmfModuleRange:=True;
   Exit;
  End;
  Pos:=NextPos;
 End;
End;

Function FindNextOmfModuleInLib(Var LibF:File; Const FileLimit:LongInt;
                                Var ScanPos:LongInt;
                                Var ModStart,ModEnd:LongInt;
                                Var ModName:TStr64):Boolean;
Var
 Pos:LongInt;
 RecType:Byte;
 RecLen:Word;
Begin
 FindNextOmfModuleInLib:=False;
 ModStart:=0;
 ModEnd:=0;
 ModName:='';
 Pos:=ScanPos;

 While Pos+3<=FileLimit do Begin
  If ReadRecordHeaderAt(LibF,Pos,FileLimit,RecType,RecLen) Then
   If RecType In [$80,$82] Then
    If TryParseOmfModuleRange(LibF,FileLimit,Pos,ModEnd,ModName) Then Begin
     ModStart:=Pos;
     ScanPos:=ModEnd;
     FindNextOmfModuleInLib:=True;
     Exit;
    End;
  Inc(Pos);
 End;

 ScanPos:=FileLimit;
End;

Function FileExistsSimple(Const FileName:String):Boolean;
Var
 f:File;
 err:Integer;
Begin
 {$I-}
 Assign(f,FileName);
 Reset(f,1);
 err:=IOResult;
 {$I+}
 If err=0 Then Begin
  Close(f);
  FileExistsSimple:=True;
 End Else FileExistsSimple:=False;
End;

Function ExtractLibModuleToTempObj(Var LibF:File;
                                   Const ModStart,ModEnd:LongInt;
                                   Var TempObjName:TStr128):Boolean;
Var
 OutF:File;
 CopyBuf:Array[0..1023] of Byte;
 Remaining,CurPos:LongInt;
 ChunkSize:Word;
 numText:String;
 candidate:String[128];
 n:Integer;
Begin
 ExtractLibModuleToTempObj:=False;
 TempObjName:='';
 If ModEnd<=ModStart Then Exit;

 n:=TempLibObjCount+1;
 Repeat
  Str(n:0,numText);
  candidate:='~LNKLIB'+numText+'.OBJ';
  Inc(n);
 Until Not FileExistsSimple(candidate);

 {$I-}
 Assign(OutF,candidate);
 Rewrite(OutF,1);
 If IOResult<>0 Then Begin
  {$I+}
  Exit;
 End;
 {$I+}

 CurPos:=ModStart;
 Remaining:=ModEnd-ModStart;
 While Remaining>0 do Begin
  If Remaining>SizeOf(CopyBuf) Then ChunkSize:=SizeOf(CopyBuf)
                              Else ChunkSize:=Remaining;
  Seek(LibF,CurPos);
  BlockRead(LibF,CopyBuf,ChunkSize);
  BlockWrite(OutF,CopyBuf,ChunkSize);
  Inc(CurPos,ChunkSize);
  Dec(Remaining,ChunkSize);
 End;
 Close(OutF);

 TempObjName:=candidate;
 ExtractLibModuleToTempObj:=True;
End;

Function ResolveNeededModulesFromLibrary(Const LibIdx:Integer):Integer;
Var
 LibF:File;
 fileLimit:LongInt;
 scanPos,modStart,modEnd:LongInt;
 moduleName:TStr64;
 tempObjName:TStr128;
 addedCount:Integer;
 err:Integer;
 modulePublicCount,moduleNeededCount:Integer;
 moduleNeeded:Boolean;
 unresolvedNow:Integer;
 traceThisLib:Boolean;
Begin
 ResolveNeededModulesFromLibrary:=0;
 addedCount:=0;

 {$I-}
 Assign(LibF,LibInputList^[LibIdx]);
 Reset(LibF,1);
 err:=IOResult;
 {$I+}
 If err<>0 Then Begin
  WriteLn('Avertissement : impossible de lire la bibliotheque : ',LibInputList^[LibIdx]);
  Exit;
 End;

 traceThisLib:=TraceLibRequested And TraceLibraryMatches(LibInputList^[LibIdx]);

 If traceThisLib Then
  WriteLn('TRACE LIB: bibliotheque #',LibIdx,' -> ',LibInputList^[LibIdx]);

 fileLimit:=FileSize(LibF);
 scanPos:=0;
 While FindNextOmfModuleInLib(LibF,fileLimit,scanPos,modStart,modEnd,moduleName) do Begin
  If traceThisLib Then
  WriteLn('TRACE LIB: module detecte ',LibInputList^[LibIdx],'::',moduleName,
        ' [start=',modStart,' end=',modEnd,']');

  If IsLibModuleAlreadyLoaded(LibIdx,modStart) Then Begin
  If traceThisLib Then
   WriteLn('TRACE LIB:   module deja charge, ignore');
  Continue;
  End;
  Inc(LibModulesScannedCount);

  unresolvedNow:=CountUnresolvedExternalNames;
  If unresolvedNow=0 Then Begin
  If traceThisLib Then
   WriteLn('TRACE LIB:   aucun externe non resolu restant, arret du scan de la bibliotheque');
  Break;
  End;

  moduleNeeded:=ModuleDefinesNeededSymbol(LibF,modStart,modEnd,
                            LibInputList^[LibIdx],moduleName,
                            traceThisLib,
                            modulePublicCount,moduleNeededCount);
    If traceThisLib Then Begin
     If moduleNeeded Then
      WriteLn('TRACE LIB:   publics=',modulePublicCount,
        ' utiles=',moduleNeededCount,' -> charge')
     Else
      WriteLn('TRACE LIB:   publics=',modulePublicCount,
        ' utiles=',moduleNeededCount,' -> ignore');
    End;

  If moduleNeeded Then Begin
   If ObjInputCount>=MAX_CMD_OBJS Then Begin
    WriteLn('Erreur : Trop de modules OBJ apres extraction des bibliotheques');
    Close(LibF);
    Halt(31);
   End;

   If ExtractLibModuleToTempObj(LibF,modStart,modEnd,tempObjName) Then Begin
  If traceThisLib Then
    WriteLn('TRACE LIB:   extraction module vers ',tempObjName);
    ObjSegBaseList[ObjInputCount+1]:=SegmentCount;
    If ReadObjFile(tempObjName) Then Begin
     Inc(ObjInputCount);
      ObjInputList^[ObjInputCount]:=tempObjName;
     AddTempLibObjFile(tempObjName);
     MarkLibModuleLoaded(LibIdx,modStart,moduleName);
     Inc(LibModulesLoadedCount);
     Inc(addedCount);
     ApplyAliasToExternalSymbols;
     If traceThisLib Then
     WriteLn('TRACE LIB:   module charge avec succes');
    End Else Begin
     WriteLn('Avertissement : module LIB ignore (lecture impossible) : ',tempObjName);
     MarkLibModuleLoaded(LibIdx,modStart,moduleName);
     If traceThisLib Then
     WriteLn('TRACE LIB:   echec de lecture du module extrait');
    End;
   End Else Begin
      WriteLn('Avertissement : extraction module LIB impossible : ',LibInputList^[LibIdx]);
    MarkLibModuleLoaded(LibIdx,modStart,moduleName);
    If traceThisLib Then
    WriteLn('TRACE LIB:   echec extraction module');
   End;
  End Else Begin
    If traceThisLib Then
   WriteLn('TRACE LIB:   module ignore (aucun symbole utile)');
  End;
 End;

 Close(LibF);
 ResolveNeededModulesFromLibrary:=addedCount;
End;

Procedure ResolveLibrariesForExternals;
Var
 passIdx:Integer;
 libIdx:Integer;
 unresolvedBefore,unresolvedAfter:Integer;
 addedPass:Integer;
 done:Boolean;
Begin
 LibResolutionPasses:=0;
 If LibInputCount=0 Then Exit;

 If TraceLibRequested Then
  WriteLn('TRACE LIB: debut resolution bibliotheques (',LibInputCount,' bibliotheque(s))');

 passIdx:=0;
 done:=False;
 While Not done do Begin
  Inc(passIdx);
  LibResolutionPasses:=passIdx;
  ApplyAliasToExternalSymbols;
  unresolvedBefore:=CountUnresolvedExternalNames;

  If TraceLibRequested Then Begin
   WriteLn('TRACE LIB: ---- passe #',passIdx,' ----');
   TraceUnresolvedExternalNames('avant passe',20);
  End;

  If unresolvedBefore=0 Then Begin
   done:=True;
   If TraceLibRequested Then
    WriteLn('TRACE LIB: plus aucun externe non resolu, fin des passes');
  End Else Begin
   addedPass:=0;
   For libIdx:=1 to LibInputCount do Begin
    Inc(addedPass,ResolveNeededModulesFromLibrary(libIdx));
    If CountUnresolvedExternalNames=0 Then Break;
   End;

   ApplyAliasToExternalSymbols;
   unresolvedAfter:=CountUnresolvedExternalNames;
   If TraceLibRequested Then Begin
    WriteLn('TRACE LIB: fin passe #',passIdx,' -> modules charges=',addedPass,
            ' externes restants=',unresolvedAfter);
    TraceUnresolvedExternalNames('apres passe',20);
   End;
   If (addedPass=0)Or(unresolvedAfter=0)Or(passIdx>=32) Then done:=True;
  End;
 End;

 unresolvedAfter:=CountUnresolvedExternalNames;
 If unresolvedAfter>0 Then
  WriteLn('Avertissement : externes non resolus apres recherche LIB : ',unresolvedAfter);
 If TraceLibRequested Then
  WriteLn('TRACE LIB: fin resolution bibliotheques');
End;

Procedure GenerateExe(Const FileName:String);
Var
 i:Integer;
 CodeSize,HeaderBytes,DataStart:LongInt;
 Remaining,ChunkSize:Word;
 PatchPos:LongInt;
 OldByte,NewByte:Byte;
 OldWord,NewWord:Word;
 OldLong,NewLong,IncLong:LongInt;
 IncWord:Word;
 PatchItem:POffsetPatchItem;
 BackItem:PBackPatchItem;
 RelocItem:PRelocationItem;
 RecType:Byte;
 RecLen:Word;
 ObjBuf:TObjRecBuffer;
 SegIndex:Word;
 SegOffset:Word;
 DataLen:Word;
 IdxSize:Integer;
 WritePos:LongInt;
 EntryLinear:LongInt;
 GroupPos,GroupLimit:Integer;
 MaxWrite,Produced:LongInt;
 DataOfs32:LongInt;
 BlockLen:LongInt;
 ParseOK:Boolean;
 LidataUse32:Boolean;
 A1IsIter:Boolean;
 ComdatFlags:Byte;
 ComdatAttr:Byte;
 ComdatAllocType:Byte;
 ComdatTypeIdx:Word;
 ComdatBaseGroupIdx,ComdatBaseSegIdx:Word;
 ComdatEnumOfs:LongInt;
 ComdatTargetSeg:Word;
 ComdatBaseOfs:LongInt;
 ComdatName:String[64];
 ComdatNameLen:Byte;
 TmpPos:Integer;
 IterPos:Integer;
 SegPtr:PSegment;
 ObjIdx:Integer;
 CurObjName:String;
 ModuleSegBase:Integer;
 LocalSegCount:Integer;

 Function ReadOmfIndexObj(Var Pos:Integer; Limit:Integer; Var Idx:Word):Boolean;
 Var b:Byte;
 Begin
  ReadOmfIndexObj:=False;
  If Pos>=Limit Then Exit;
  b:=ObjBuf[Pos];
  Inc(Pos);
  If (b And $80)<>0 Then Begin
   If Pos>=Limit Then Exit;
   Idx:=((Word(b And $7F) Shl 8) Or ObjBuf[Pos]);
   Inc(Pos);
  End Else Idx:=b;
  ReadOmfIndexObj:=True;
 End;

   Function MapSegIndexObj(Const LocalIdx:Word):Word;
   Begin
    If (LocalIdx=0)Or(LocalIdx>LocalSegCount) Then MapSegIndexObj:=0
    Else MapSegIndexObj:=ModuleSegBase+LocalIdx;
   End;

 Function FindSymbolByNameObj(Const Nm:String; Var SegIdx:Word; Var OfsVal:LongInt):Boolean;
 Var
  symItem:PSymbolItem;
  lookupName:String[64];
 Begin
  FindSymbolByNameObj:=False;
  SegIdx:=0;
  OfsVal:=0;
  lookupName:=ResolveAliasName(Nm);
  symItem:=SymbolHead;
  While symItem<>Nil do Begin
  If (Not symItem^.Value.IsExternal)
    And((symItem^.Value.Name=Nm)Or(symItem^.Value.Name=lookupName)) Then Begin
    SegIdx:=symItem^.Value.Segment;
    OfsVal:=symItem^.Value.Offset;
    FindSymbolByNameObj:=True;
    Exit;
   End;
   symItem:=symItem^.Next;
  End;
 End;

Begin
  { Initialise l'entï¿½te EXE }
 FillChar(ExeHeader, SizeOf(ExeHeader), 0);
 With ExeHeader do Begin
  Signature:=$5A4D;  { 'MZ' }
  MinAlloc:=0;
    MaxAlloc:=MaxAllocParagraphs;
  InitSS:=0;
  InitSP:=StackSize;
  InitCS:=0;
  InitIP:=0;
  RelocOffset:=SizeOf(TExeHeader);
 End;

 { Point d'entree issu de MODEND/MODEND32, si disponible }
 If HasEntryPoint And (EntrySegIndex>0)And(EntrySegIndex<=SegmentCount) Then Begin
  SegPtr:=GetSegmentPtr(EntrySegIndex);
  If SegPtr<>Nil Then Begin
   EntryLinear:=SegPtr^.Address+EntryOffset;
   If EntryLinear<0 Then EntryLinear:=0;
   If EntryLinear>(LongInt($FFFF)*16+15) Then EntryLinear:=LongInt($FFFF)*16+15;
   ExeHeader.InitCS:=EntryLinear Div 16;
   ExeHeader.InitIP:=EntryLinear Mod 16;
  End;
 End;

  { Calcul du taille du code }
 CodeSize:=0;
 For i:=1 to SegmentCount do Begin
  SegPtr:=GetSegmentPtr(i);
  If SegPtr<>Nil Then Inc(CodeSize,SegPtr^.Size);
 End;
 ExeHeader.RelocCount:=RelocationCount;

 HeaderBytes:=SizeOf(TExeHeader)+LongInt(RelocationCount)*4;
 ExeHeader.HeaderSize:=(HeaderBytes+15) div 16;   { en paragraphes }
 If ExeHeader.HeaderSize<2 Then ExeHeader.HeaderSize:=2;
 DataStart:=LongInt(ExeHeader.HeaderSize)*16;
 ExeHeader.LastPageBytes:=(DataStart+CodeSize) mod 512;
 ExeHeader.PageCount:=(DataStart+CodeSize+511) div 512;

  { Ecrit un fichier EXE }
 Assign(ExeFile,FileName);
 Rewrite(ExeFile,1);
 BlockWrite(ExeFile,ExeHeader,SizeOf(ExeHeader));

  { crire la relocations }
 RelocItem:=RelocationHead;
 While RelocItem<>Nil do Begin
  BlockWrite(ExeFile,RelocItem^.Value,4);
  RelocItem:=RelocItem^.Next;
 End;

    { Remplit le padding d'entˆte jusqu'… DataStart }
   FillChar(Buffer,SizeOf(Buffer),0);
   While FilePos(ExeFile)<DataStart do Begin
    ChunkSize:=SizeOf(Buffer);
    If FilePos(ExeFile)+ChunkSize>DataStart Then ChunkSize:=DataStart-FilePos(ExeFile);
    BlockWrite(ExeFile,Buffer,ChunkSize);
   End;

    { R‚serve les segments de code (z‚ro) }
 For i:=1 to SegmentCount do Begin
   SegPtr:=GetSegmentPtr(i);
   If SegPtr=Nil Then Continue;
   Remaining:=SegPtr^.Size;
    While Remaining>0 do Begin
     If Remaining>SizeOf(Buffer) Then ChunkSize:=SizeOf(Buffer)
                               Else ChunkSize:=Remaining;
     BlockWrite(ExeFile,Buffer,ChunkSize);
     Dec(Remaining,ChunkSize);
    End;
 End;

    { Copie les octets r‚els depuis LEDATA des fichiers OBJ }
   For ObjIdx:=1 to ObjInputCount do Begin
      CurObjName:=ObjInputList^[ObjIdx];
    ModuleSegBase:=ObjSegBaseList[ObjIdx];
    LocalSegCount:=0;

    {$I-}
    Assign(ObjFile,CurObjName);
    Reset(ObjFile,1);
    If IOResult<>0 Then Begin
     WriteLn('Erreur : impossible de relire l''objet : ',CurObjName);
     Close(ExeFile);
     Exit;
    End;
    {$I+}

    While Not Eof(ObjFile) do Begin
     BlockRead(ObjFile,RecType,1);
     If Eof(ObjFile) Then Break;
     If RecType<$80 Then RecType:=RecType Or $80;
     BlockRead(ObjFile,RecLen,2);
     If RecLen>SizeOf(ObjBuf) Then Begin
      WriteLn('Erreur : RecLen sup‚rieur … la taille du tampon LEDATA');
      Close(ObjFile);
      Close(ExeFile);
      Exit;
     End;
     BlockRead(ObjFile,ObjBuf,RecLen);

     If (RecType=$98)Or(RecType=$99) Then Begin
      Inc(LocalSegCount);
      Continue;
     End;

     If (RecType=$A0)Or(RecType=$84) Then Begin
      If RecLen<5 Then Continue;
      IdxSize:=1;
      SegIndex:=ObjBuf[0];
      If (SegIndex And $80)<>0 Then Begin
       If RecLen<6 Then Continue;
       SegIndex:=((SegIndex And $7F) Shl 8) Or ObjBuf[1];
       IdxSize:=2;
      End;
      SegIndex:=MapSegIndexObj(SegIndex);
      Move(ObjBuf[IdxSize],SegOffset,2);
      DataLen:=RecLen-IdxSize-2-1; { -index -offset -checksum }
      If (DataLen>0)And(SegIndex>0)And(SegIndex<=SegmentCount) Then Begin
       SegPtr:=GetSegmentPtr(SegIndex);
       If SegPtr<>Nil Then Begin
        WritePos:=DataStart+SegPtr^.Address+SegOffset;
        Seek(ExeFile,WritePos);
        BlockWrite(ExeFile,ObjBuf[IdxSize+2],DataLen);
       End;
      End;
     End Else If RecType=$86 Then Begin
      GroupPos:=0;
      GroupLimit:=RecLen-1; { sans checksum }
      If GroupLimit<=0 Then Continue;

      SegIndex:=ObjBuf[GroupPos];
      Inc(GroupPos);
      If (SegIndex And $80)<>0 Then Begin
       If GroupPos>=GroupLimit Then Continue;
       SegIndex:=((SegIndex And $7F) Shl 8) Or ObjBuf[GroupPos];
       Inc(GroupPos);
      End;
      SegIndex:=MapSegIndexObj(SegIndex);

      If GroupPos+1>=GroupLimit Then Continue;
      SegOffset:=ObjBuf[GroupPos]+Word(ObjBuf[GroupPos+1])*256;
      Inc(GroupPos,2);

      If (SegIndex>0)And(SegIndex<=SegmentCount) Then Begin
       SegPtr:=GetSegmentPtr(SegIndex);
       If SegPtr<>Nil Then Begin
        WritePos:=DataStart+SegPtr^.Address+SegOffset;
        MaxWrite:=LongInt(SegPtr^.Size)-LongInt(SegOffset);
        If MaxWrite<0 Then MaxWrite:=0;
        Produced:=0;
        IterPos:=GroupPos;
        While IterPos<GroupLimit do
         If Not EmitIterBlock16(ExeFile,ObjBuf,IterPos,GroupLimit,WritePos,Produced,MaxWrite) Then Break;
       End;
      End;
     End Else If RecType=$A1 Then Begin
      GroupPos:=0;
      GroupLimit:=RecLen-1; { sans checksum }
      If GroupLimit<=0 Then Continue;

      SegIndex:=ObjBuf[GroupPos];
      Inc(GroupPos);
      If (SegIndex And $80)<>0 Then Begin
       If GroupPos>=GroupLimit Then Continue;
       SegIndex:=((SegIndex And $7F) Shl 8) Or ObjBuf[GroupPos];
       Inc(GroupPos);
      End;
      SegIndex:=MapSegIndexObj(SegIndex);

      If GroupPos+3>=GroupLimit Then Continue;
      DataOfs32:=LongInt(ObjBuf[GroupPos])
        + LongInt(ObjBuf[GroupPos+1]) * 256
        + LongInt(ObjBuf[GroupPos+2]) * 65536
        + LongInt(ObjBuf[GroupPos+3]) * 16777216;
      Inc(GroupPos,4);

      If (SegIndex>0)And(SegIndex<=SegmentCount) Then Begin
       SegPtr:=GetSegmentPtr(SegIndex);
       If (SegPtr<>Nil)And(DataOfs32>=0) Then Begin
        WritePos:=DataStart+SegPtr^.Address+DataOfs32;
        MaxWrite:=LongInt(SegPtr^.Size)-DataOfs32;
        If MaxWrite<0 Then MaxWrite:=0;

        A1IsIter:=False;
        LidataUse32:=True;
        TmpPos:=GroupPos;
        ParseOK:=True;
        While TmpPos<GroupLimit do
         If Not SkipIterBlockEx(ObjBuf,TmpPos,GroupLimit,True,BlockLen) Then Begin
          ParseOK:=False;
          Break;
         End;

        If ParseOK And (TmpPos=GroupLimit) Then Begin
         A1IsIter:=True;
         LidataUse32:=True;
        End Else Begin
         TmpPos:=GroupPos;
         ParseOK:=True;
         While TmpPos<GroupLimit do
          If Not SkipIterBlockEx(ObjBuf,TmpPos,GroupLimit,False,BlockLen) Then Begin
           ParseOK:=False;
           Break;
          End;
         If ParseOK And (TmpPos=GroupLimit) Then Begin
          A1IsIter:=True;
          LidataUse32:=False;
         End;
        End;

        If A1IsIter Then Begin
         Produced:=0;
         IterPos:=GroupPos;
         While IterPos<GroupLimit do
          If Not EmitIterBlockEx(ExeFile,ObjBuf,IterPos,GroupLimit,WritePos,Produced,MaxWrite,LidataUse32) Then Break;
        End Else Begin
         If GroupPos<GroupLimit Then DataLen:=GroupLimit-GroupPos
                             Else DataLen:=0;
         If MaxWrite<=0 Then DataLen:=0
         Else If LongInt(DataLen)>MaxWrite Then DataLen:=MaxWrite;
         If DataLen>0 Then Begin
          Seek(ExeFile,WritePos);
          BlockWrite(ExeFile,ObjBuf[GroupPos],DataLen);
         End;
        End;
       End;
      End;
     End Else If (RecType=$A2)Or(RecType=$A3) Then Begin
      GroupPos:=0;
      GroupLimit:=RecLen-1; { sans checksum }
      If GroupLimit<=0 Then Continue;

      SegIndex:=ObjBuf[GroupPos];
      Inc(GroupPos);
      If (SegIndex And $80)<>0 Then Begin
       If GroupPos>=GroupLimit Then Continue;
       SegIndex:=((SegIndex And $7F) Shl 8) Or ObjBuf[GroupPos];
       Inc(GroupPos);
      End;
      SegIndex:=MapSegIndexObj(SegIndex);

      If RecType=$A3 Then Begin
       If GroupPos+3>=GroupLimit Then Continue;
       DataOfs32:=LongInt(ObjBuf[GroupPos])
               + LongInt(ObjBuf[GroupPos+1]) * 256
               + LongInt(ObjBuf[GroupPos+2]) * 65536
               + LongInt(ObjBuf[GroupPos+3]) * 16777216;
       Inc(GroupPos,4);
      End Else Begin
       If GroupPos+1>=GroupLimit Then Continue;
       DataOfs32:=ObjBuf[GroupPos]+LongInt(ObjBuf[GroupPos+1])*256;
       Inc(GroupPos,2);
      End;

      If (SegIndex>0)And(SegIndex<=SegmentCount) Then Begin
       SegPtr:=GetSegmentPtr(SegIndex);
       If (SegPtr<>Nil)And(DataOfs32>=0) Then Begin
        WritePos:=DataStart+SegPtr^.Address+DataOfs32;
        MaxWrite:=LongInt(SegPtr^.Size)-DataOfs32;
        If MaxWrite<0 Then MaxWrite:=0;

        LidataUse32:=(RecType=$A3);
        If LidataUse32 Then Begin
         TmpPos:=GroupPos;
         ParseOK:=True;
         While TmpPos<GroupLimit do
          If Not SkipIterBlockEx(ObjBuf,TmpPos,GroupLimit,True,BlockLen) Then Begin
           ParseOK:=False;
           Break;
          End;
         If Not ParseOK Then LidataUse32:=False;
        End;

        Produced:=0;
        IterPos:=GroupPos;
        While IterPos<GroupLimit do
         If Not EmitIterBlockEx(ExeFile,ObjBuf,IterPos,GroupLimit,WritePos,Produced,MaxWrite,LidataUse32) Then Break;
       End;
      End;
     End Else If (RecType=$C2)Or(RecType=$C3) Then Begin
      GroupPos:=0;
      GroupLimit:=RecLen-1; { sans checksum }
      If GroupLimit<=0 Then Continue;
      If GroupPos+2>=GroupLimit Then Continue;

      ComdatFlags:=ObjBuf[GroupPos];
      Inc(GroupPos);
      ComdatAttr:=ObjBuf[GroupPos];
      Inc(GroupPos);
      ComdatAllocType:=ComdatAttr And $0F;

      Inc(GroupPos); { Align }
      If GroupPos>GroupLimit Then Continue;

      If RecType=$C3 Then Begin
       If GroupPos+3>=GroupLimit Then Continue;
       ComdatEnumOfs:=LongInt(ObjBuf[GroupPos])
                + LongInt(ObjBuf[GroupPos+1]) * 256
                + LongInt(ObjBuf[GroupPos+2]) * 65536
                + LongInt(ObjBuf[GroupPos+3]) * 16777216;
       Inc(GroupPos,4);
      End Else Begin
       If GroupPos+1>=GroupLimit Then Continue;
       ComdatEnumOfs:=ObjBuf[GroupPos]+LongInt(ObjBuf[GroupPos+1])*256;
       Inc(GroupPos,2);
      End;

      If Not ReadOmfIndexObj(GroupPos,GroupLimit,ComdatTypeIdx) Then Continue;

      ComdatTargetSeg:=0;
      ComdatBaseOfs:=0;
      If ComdatAllocType=0 Then Begin
       If Not ReadOmfIndexObj(GroupPos,GroupLimit,ComdatBaseGroupIdx) Then Continue;
       If Not ReadOmfIndexObj(GroupPos,GroupLimit,ComdatBaseSegIdx) Then Continue;
       ComdatBaseSegIdx:=MapSegIndexObj(ComdatBaseSegIdx);
       If ComdatBaseSegIdx=0 Then Begin
        If RecType=$C3 Then Begin
         If GroupPos+3<GroupLimit Then Inc(GroupPos,4)
                             Else Continue;
        End Else Begin
         If GroupPos+1<GroupLimit Then Inc(GroupPos,2)
                             Else Continue;
        End;
       End Else Begin
        ComdatTargetSeg:=ComdatBaseSegIdx;
        ComdatBaseOfs:=0;
       End;
      End;

      If GroupPos>=GroupLimit Then Continue;
      ComdatNameLen:=ObjBuf[GroupPos];
      Inc(GroupPos);
      If ComdatNameLen>64 Then ComdatNameLen:=64;
      If GroupPos+ComdatNameLen>GroupLimit Then ComdatNameLen:=GroupLimit-GroupPos;

      ComdatName:='';
      For i:=1 to ComdatNameLen do Begin
       ComdatName:=ComdatName+Chr(ObjBuf[GroupPos]);
       Inc(GroupPos);
      End;

      If (ComdatTargetSeg=0)And(ComdatName<>'') Then
       FindSymbolByNameObj(ComdatName,ComdatTargetSeg,ComdatBaseOfs);

      DataOfs32:=ComdatBaseOfs+ComdatEnumOfs;
      If (ComdatTargetSeg>0)And(ComdatTargetSeg<=SegmentCount)And(DataOfs32>=0) Then Begin
       SegPtr:=GetSegmentPtr(ComdatTargetSeg);
       If SegPtr<>Nil Then Begin
        WritePos:=DataStart+SegPtr^.Address+DataOfs32;
        MaxWrite:=LongInt(SegPtr^.Size)-DataOfs32;
        If MaxWrite<0 Then MaxWrite:=0;

        If (ComdatFlags And $02)<>0 Then Begin
         LidataUse32:=(RecType=$C3);
         If LidataUse32 Then Begin
          TmpPos:=GroupPos;
          ParseOK:=True;
          While TmpPos<GroupLimit do
           If Not SkipIterBlockEx(ObjBuf,TmpPos,GroupLimit,True,BlockLen) Then Begin
            ParseOK:=False;
            Break;
           End;
          If Not ParseOK Then LidataUse32:=False;
         End;

         Produced:=0;
         IterPos:=GroupPos;
         While IterPos<GroupLimit do
          If Not EmitIterBlockEx(ExeFile,ObjBuf,IterPos,GroupLimit,WritePos,Produced,MaxWrite,LidataUse32) Then Break;
        End Else Begin
         If GroupPos<GroupLimit Then DataLen:=GroupLimit-GroupPos
                              Else DataLen:=0;
         If MaxWrite<=0 Then DataLen:=0
         Else If LongInt(DataLen)>MaxWrite Then DataLen:=MaxWrite;
         If DataLen>0 Then Begin
          Seek(ExeFile,WritePos);
          BlockWrite(ExeFile,ObjBuf[GroupPos],DataLen);
         End;
        End;
       End;
      End;
     End;
    End;
    Close(ObjFile);
   End;

      { Applique les enregistrements BAKPAT/BAKPAT32 }
    BackItem:=BackPatchHead;
    While BackItem<>Nil do Begin
     If (BackItem^.SegIndex>0)And(BackItem^.SegIndex<=SegmentCount) Then Begin
      SegPtr:=GetSegmentPtr(BackItem^.SegIndex);
      If (SegPtr<>Nil)And(BackItem^.PatchOffset>=0) Then Begin
       PatchPos:=DataStart+SegPtr^.Address+BackItem^.PatchOffset;

       Case BackItem^.LocType of
        0:Begin { BYTE }
         If (PatchPos>=0)And(PatchPos<FileSize(ExeFile)) Then Begin
          Seek(ExeFile,PatchPos);
          BlockRead(ExeFile,OldByte,1);
          NewByte:=Byte((LongInt(OldByte)+(BackItem^.PatchValue And $FF)) And $FF);
          Seek(ExeFile,PatchPos);
          BlockWrite(ExeFile,NewByte,1);
         End;
        End;
        1:Begin { WORD }
         If (PatchPos>=0)And(PatchPos+1<FileSize(ExeFile)) Then Begin
          Seek(ExeFile,PatchPos);
          BlockRead(ExeFile,OldWord,2);
          IncWord:=BackItem^.PatchValue And $FFFF;
          NewWord:=OldWord+IncWord;
          Seek(ExeFile,PatchPos);
          BlockWrite(ExeFile,NewWord,2);
         End;
        End;
        2,9:Begin { DWORD }
         If (PatchPos>=0)And(PatchPos+3<FileSize(ExeFile)) Then Begin
          Seek(ExeFile,PatchPos);
          BlockRead(ExeFile,OldLong,4);
          IncLong:=BackItem^.PatchValue;
          NewLong:=OldLong+IncLong;
          Seek(ExeFile,PatchPos);
          BlockWrite(ExeFile,NewLong,4);
         End;
        End;
       End;
      End;
     End;
     BackItem:=BackItem^.Next;
    End;

    { Applique les corrections OFFSET segment-relatives }
  PatchItem:=OffsetPatchHead;
  While PatchItem<>Nil do Begin
   PatchPos:=DataStart+PatchItem^.Pos;
    If (PatchPos>=0)And(PatchPos+1<FileSize(ExeFile)) Then Begin
     Seek(ExeFile,PatchPos);
     BlockRead(ExeFile,OldWord,2);
    NewWord:=OldWord+PatchItem^.Delta;
     Seek(ExeFile,PatchPos);
     BlockWrite(ExeFile,NewWord,2);
    End;
   PatchItem:=PatchItem^.Next;
   End;
 Close(ExeFile);
End;

Function HexDigit(Const N:Byte):Char;
Begin
 If N<10 Then HexDigit:=Chr(Ord('0')+N)
   Else HexDigit:=Chr(Ord('A')+(N-10));
End;

Function HexN(Const V:LongInt; Digits:Integer):String;
Var
 i:Integer;
 x:LongInt;
 s:String;
Begin
 If Digits<1 Then Digits:=1;
 If Digits>16 Then Digits:=16;
 s:=Copy('0000000000000000',1,Digits);
 x:=V;
 For i:=Digits downto 1 do Begin
  s[i]:=HexDigit(Byte(x And $0F));
  x:=x Shr 4;
 End;
 HexN:=s;
End;

Function PadRight(Const S:String; Width:Integer):String;
Var
 r:String;
Begin
 r:=Copy(S,1,Width);
 While Length(r)<Width do r:=r+' ';
 PadRight:=r;
End;

Procedure GenerateMapFile(Const FileName:String);
Type
 TSegMapEntry=Record
  Index:Integer;
  Base:LongInt;
  Size:Word;
  Name:String[16];
  ClassName:String[8];
 End;
 TSymMapEntry=Record
  SegIndex:Word;
  Ofs:Word;
  Linear:LongInt;
  Name:String[32];
 End;
 TLineMapEntry=Record
  SegIndex:Word;
  LineNo:LongInt;
  Ofs:LongInt;
 End;
 TSegMapArray=Array[1..MAX_SEGMENTS] of TSegMapEntry;
 PSegMapArray=^TSegMapArray;
 TSymMapArray=Array[1..MAX_SYMBOLS] of TSymMapEntry;
 PSymMapArray=^TSymMapArray;
 TLineMapArray=Array[1..MAX_LINENUMS] of TLineMapEntry;
 PLineMapArray=^TLineMapArray;
 TUnresolvedMapArray=Array[1..MAX_SYMBOLS] of String[32];
 PUnresolvedMapArray=^TUnresolvedMapArray;
Var
 f:Text;
 segItem:PSegmentItem;
 symItem:PSymbolItem;
 lineItem:PLineInfoItem;
 segPtr:PSegment;
 mapName:String;
 k,a,b:Integer;
 segNo,symNo,lineNo,unresNo:Integer;
 totalImage:LongInt;
 unresolvedName:String[32];
 found:Boolean;
 extCount,pubCount,resolvedCount:LongInt;
 segArr:PSegMapArray;
 symArr:PSymMapArray;
 lineArr:PLineMapArray;
 unresolvedArr:PUnresolvedMapArray;
 tmpSeg:TSegMapEntry;
 tmpSym:TSymMapEntry;
 tmpLine:TLineMapEntry;
 tmpName:String[32];
Begin
 If Not MapRequested Then Exit;
 mapName:=FileName;
 For k:=1 to Length(mapName) do mapName[k]:=UpCase(mapName[k]);
 If mapName='NUL' Then Exit;

 {$I-}
 Assign(f,FileName);
 Rewrite(f);
 If IOResult<>0 Then Begin
  WriteLn('Avertissement : impossible de generer le fichier MAP : ',FileName);
  Exit;
 End;
 {$I+}

   segArr:=Nil;
   symArr:=Nil;
   lineArr:=Nil;
   unresolvedArr:=Nil;

   GetMem(segArr,SizeOf(TSegMapArray));
   GetMem(symArr,SizeOf(TSymMapArray));
   GetMem(lineArr,SizeOf(TLineMapArray));
   GetMem(unresolvedArr,SizeOf(TUnresolvedMapArray));

   FillChar(segArr^,SizeOf(TSegMapArray),0);
   FillChar(symArr^,SizeOf(TSymMapArray),0);
   FillChar(lineArr^,SizeOf(TLineMapArray),0);
   FillChar(unresolvedArr^,SizeOf(TUnresolvedMapArray),0);

 WriteLn(f,' Microsoft (R) Overlay Linker - MAP');
 WriteLn(f,' Executable : ',ExeFileName);
 WriteLn(f,' Objets     : ',ObjInputCount,' (CLI=',PrimaryObjInputCount,')');
 WriteLn(f,' Bibliotheques : ',LibInputCount,'  Modules charges : ',LibModulesLoadedCount);
 WriteLn(f);
 WriteLn(f,' Start         Length     Name                   Class');

 segNo:=0;
 totalImage:=0;
 segItem:=SegmentHead;
 While segItem<>Nil do Begin
  If segNo<MAX_SEGMENTS Then Begin
   Inc(segNo);
   segArr^[segNo].Index:=segNo;
   segArr^[segNo].Base:=segItem^.Value.Address;
   segArr^[segNo].Size:=segItem^.Value.Size;
   segArr^[segNo].Name:=Copy(segItem^.Value.Name,1,16);
   segArr^[segNo].ClassName:=Copy(segItem^.Value.Class,1,8);
   Inc(totalImage,segItem^.Value.Size);
  End;
  segItem:=segItem^.Next;
 End;

 For a:=1 to segNo-1 do
  For b:=a+1 to segNo do
   If (segArr^[a].Base>segArr^[b].Base)
      Or((segArr^[a].Base=segArr^[b].Base)And(segArr^[a].Name>segArr^[b].Name)) Then Begin
    tmpSeg:=segArr^[a];
    segArr^[a]:=segArr^[b];
    segArr^[b]:=tmpSeg;
   End;

 For a:=1 to segNo do
  WriteLn(f,' ',HexN(segArr^[a].Base Div 16,4),':',HexN(segArr^[a].Base Mod 16,8),'H ',
            HexN(segArr^[a].Size,8),'H ',PadRight(segArr^[a].Name,22),' ',segArr^[a].ClassName);

 If PublicsMapRequested Then Begin
  symNo:=0;
  symItem:=SymbolHead;
  While symItem<>Nil do Begin
   If (Not symItem^.Value.IsExternal)And(symItem^.Value.Segment>0) Then Begin
    segPtr:=GetSegmentPtr(symItem^.Value.Segment);
    If (segPtr<>Nil)And(symNo<MAX_SYMBOLS) Then Begin
     Inc(symNo);
     symArr^[symNo].SegIndex:=symItem^.Value.Segment;
     symArr^[symNo].Ofs:=symItem^.Value.Offset;
     symArr^[symNo].Linear:=segPtr^.Address+symItem^.Value.Offset;
     symArr^[symNo].Name:=Copy(symItem^.Value.Name,1,32);
    End;
   End;
   symItem:=symItem^.Next;
  End;

  For a:=1 to symNo-1 do
   For b:=a+1 to symNo do
    If (symArr^[a].Linear>symArr^[b].Linear)
       Or((symArr^[a].Linear=symArr^[b].Linear)And(symArr^[a].Name>symArr^[b].Name)) Then Begin
     tmpSym:=symArr^[a];
     symArr^[a]:=symArr^[b];
     symArr^[b]:=tmpSym;
    End;

  WriteLn(f);
  WriteLn(f,'  Address         Publics by Value');
  For a:=1 to symNo do
   WriteLn(f,' ',HexN(symArr^[a].Linear Div 16,4),':',HexN(symArr^[a].Linear Mod 16,8),'H     ',symArr^[a].Name);
 End;

 If LineNumbersRequested Then Begin
  lineNo:=0;
  lineItem:=LineInfoHead;
  While lineItem<>Nil do Begin
   If (lineItem^.SegIndex>0)And(lineNo<MAX_LINENUMS) Then Begin
    Inc(lineNo);
    lineArr^[lineNo].SegIndex:=lineItem^.SegIndex;
    lineArr^[lineNo].LineNo:=lineItem^.LineNo;
    lineArr^[lineNo].Ofs:=lineItem^.CodeOffset;
   End;
   lineItem:=lineItem^.Next;
  End;

  For a:=1 to lineNo-1 do
   For b:=a+1 to lineNo do
    If (lineArr^[a].SegIndex>lineArr^[b].SegIndex)
      Or((lineArr^[a].SegIndex=lineArr^[b].SegIndex)And(lineArr^[a].LineNo>lineArr^[b].LineNo))
      Or((lineArr^[a].SegIndex=lineArr^[b].SegIndex)
         And(lineArr^[a].LineNo=lineArr^[b].LineNo)
         And(lineArr^[a].Ofs>lineArr^[b].Ofs)) Then Begin
     tmpLine:=lineArr^[a];
     lineArr^[a]:=lineArr^[b];
     lineArr^[b]:=tmpLine;
    End;

  WriteLn(f);
  WriteLn(f,'  Line numbers');
  WriteLn(f,'  Segment  Ligne    Offset');
  For a:=1 to lineNo do
   WriteLn(f,'  ',lineArr^[a].SegIndex:5,'   ',lineArr^[a].LineNo:7,'  ',lineArr^[a].Ofs:8);
 End;

 unresNo:=0;
 symItem:=SymbolHead;
 While symItem<>Nil do Begin
  If symItem^.Value.IsExternal Then Begin
   unresolvedName:=NormalizeSymbolName(symItem^.Value.Name);
   If (unresolvedName<>'')And IsExternalNameUnresolved(unresolvedName) Then Begin
    found:=False;
    For k:=1 to unresNo do
     If unresolvedArr^[k]=unresolvedName Then Begin
      found:=True;
      Break;
     End;
    If (Not found)And(unresNo<MAX_SYMBOLS) Then Begin
     Inc(unresNo);
     unresolvedArr^[unresNo]:=unresolvedName;
    End;
   End;
  End;
  symItem:=symItem^.Next;
 End;

 For a:=1 to unresNo-1 do
  For b:=a+1 to unresNo do
   If unresolvedArr^[a]>unresolvedArr^[b] Then Begin
    tmpName:=unresolvedArr^[a];
    unresolvedArr^[a]:=unresolvedArr^[b];
    unresolvedArr^[b]:=tmpName;
   End;

 If unresNo>0 Then Begin
  WriteLn(f);
  WriteLn(f,'  Unresolved externals');
  For a:=1 to unresNo do
   WriteLn(f,'   ',unresolvedArr^[a]);
 End;

 extCount:=CountExternalReferences;
 pubCount:=CountPublicDefinitions;
 resolvedCount:=extCount-unresNo;
 If resolvedCount<0 Then resolvedCount:=0;

 WriteLn(f);
 WriteLn(f,'  Summary');
 WriteLn(f,'   Segments              : ',segNo);
 WriteLn(f,'   Taille image (octets) : ',totalImage);
 WriteLn(f,'   Publics definis       : ',pubCount);
 WriteLn(f,'   References externes   : ',extCount);
 WriteLn(f,'   Externes resolus      : ',resolvedCount);
 WriteLn(f,'   Externes non resolus  : ',unresNo);
 WriteLn(f,'   Relocations MZ        : ',RelocationCount);
 WriteLn(f,'   Infos lignes          : ',LineInfoCount);
 WriteLn(f,'   Modules LIB analyses  : ',LibModulesScannedCount);
 WriteLn(f,'   Modules LIB charges   : ',LibModulesLoadedCount);
 WriteLn(f,'   Passes resolution LIB : ',LibResolutionPasses);

 Close(f);

 FreeMem(unresolvedArr,SizeOf(TUnresolvedMapArray));
 FreeMem(lineArr,SizeOf(TLineMapArray));
 FreeMem(symArr,SizeOf(TSymMapArray));
 FreeMem(segArr,SizeOf(TSegMapArray));
End;

Function ChangeFileExt(Const FileName:String;Const NewExt:String):String;
Var
 i:Integer;
 BaseName:String;
Begin
 BaseName:=FileName;
 i:=Length(BaseName);
 While(i>0)and(BaseName[i]<>'.')and(BaseName[i]<>'\')and(BaseName[i]<>':')do Dec(i);
 If(i>0)and(BaseName[i]='.')Then BaseName:=Copy(BaseName, 1, i-1);
 ChangeFileExt:=BaseName+NewExt;
End;

Function StrToInt(Const S:String):Integer;
Var
 i:Integer;
 Negative:Boolean;
 Value:Integer;
Begin
 Value:=0;
 i:=1;
 Negative:=False;
  { Saute les espaces blancs }
 While(i<=Length(S))and(S[i] = ' ')do Inc(i);
  { Vï¿½rifie pour les signes }
 If(i<=Length(S))Then Begin
  If S[i]='-'Then Begin
   Negative:=True;
   Inc(i);
  End
  Else If S[i]='+'Then Inc(i);
 End;

  { Convertie en chiffres }
 While(i<=Length(S))and(S[i]>='0')and(S[i]<='9')do Begin
  Value:=Value*10+(Ord(S[i])-Ord('0'));
  Inc(i);
 End;
 If(Negative)Then StrToInt:=-Value
             Else StrToInt:=Value;
End;

Function TrimStr(Const S:String):String;
Var
 i,j:Integer;
Begin
 i:=1;
 j:=Length(S);
 While (i<=j)And((S[i]=' ')Or(S[i]=#9)Or(S[i]=#13)Or(S[i]=#10)) do Inc(i);
 While (j>=i)And((S[j]=' ')Or(S[j]=#9)Or(S[j]=#13)Or(S[j]=#10)) do Dec(j);
 If j<i Then TrimStr:=''
        Else TrimStr:=Copy(S,i,j-i+1);
End;

Function UpperStr(Const S:String):String;
Var
 k:Integer;
 u:String;
Begin
 u:=S;
 For k:=1 to Length(u) do u[k]:=UpCase(u[k]);
 UpperStr:=u;
End;

Function EnsureDefaultExt(Const Nm,DefExt:String):String;
Var
 base:String;
 k,lastSep,lastDot:Integer;
Begin
 base:=TrimStr(Nm);
 If base='' Then Begin
  EnsureDefaultExt:='';
  Exit;
 End;

 lastSep:=0;
 lastDot:=0;
 For k:=1 to Length(base) do Begin
  If (base[k]='\')Or(base[k]='/')Or(base[k]=':') Then Begin
   lastSep:=k;
   lastDot:=0;
  End Else If base[k]='.' Then lastDot:=k;
 End;

 If lastDot<=lastSep Then EnsureDefaultExt:=base+DefExt
                    Else EnsureDefaultExt:=base;
End;

Function HasExtension(Const Nm:String):Boolean;
Var
 s:String;
 k,lastSep,lastDot:Integer;
Begin
 s:=TrimStr(Nm);
 lastSep:=0;
 lastDot:=0;
 For k:=1 to Length(s) do Begin
  If (s[k]='\')Or(s[k]='/')Or(s[k]=':') Then Begin
   lastSep:=k;
   lastDot:=0;
  End Else If s[k]='.' Then lastDot:=k;
 End;
 HasExtension:=lastDot>lastSep;
End;

Procedure ShowLinkHelp;
Begin
 WriteLn('LINK : Cette commander permet de lancer le fabricant de liaison.');
 WriteLn;
 WriteLn('Syntaxe :');
 WriteLn('  LINK obj_file[+obj_file...][,[exe_file]][,[map_file]][,[library[+library...]]] [options] [;]');
 WriteLn('  LINK @response_file');
 WriteLn;
 WriteLn('Options reconnues (alias inclus) :');
 WriteLn('  /CP:n  ou /CPARMAXALLOC:n');
 WriteLn('     Definit MaxAlloc (paragraphes) dans l''en-tete EXE MZ, 0..65535.');
 WriteLn('  /ST:n  ou /STACK:n');
 WriteLn('     Definit la taille initiale de pile (SP), 1..65535 octets.');
 WriteLn('  /MAP[:fichier]  ou /M[:fichier]');
 WriteLn('     Genere un MAP (segments + publics). Si :NUL, desactive la sortie fichier MAP.');
 WriteLn('  /LINENUMBERS  ou /LI');
 WriteLn('     Ajoute les infos de lignes dans le MAP (active MAP automatiquement).');
 WriteLn('  /TRACE[:directives]  ou /TR[:directives]');
 WriteLn('     Active la trace de resolution LIB. Directives: LIB, SYM, ALL, combinaisons par virgules.');
 WriteLn('     Exemples: /TRACE:LIB  /TRACE:SYM=PRINTF  /TRACE:LIB=CLIB,SYM=STR');
 WriteLn('  /SE:n  ou /SEGMENTS:n');
 WriteLn('     Limite le nombre maximal de segments a l''edition de liens (plafond interne: ',MAX_SEGMENTS,').');
 WriteLn('  /OVERLAYINTERRUPT:n  ou /O:n');
 WriteLn('     Parametre accepte (0..255) mais actuellement non applique.');
 WriteLn('  /DOSSEG /DO, /DSALLOCATE /DS, /EXEPACK /E, /HIGH /HI, /PAUSE /P');
 WriteLn('     /DOSSEG active un ordre DOS des segments (CODE, DATA/BSS, autres, STACK).');
 WriteLn('     /DSALLOCATE place DATA/BSS en haut (avant STACK) et active aussi /DOSSEG.');
 WriteLn('     /PAUSE attend Entree en fin d''execution; EXEPACK/HIGH restent sans effet.');
 WriteLn('  /NODEFAULTLIBRARYSEARCH /NOD, /NOGROUPASSOCIATION /NOG, /NOIGNORECASE /NOI');
 WriteLn('     /NODEFAULTLIBRARYSEARCH ignore les DEFAULTLIB detectees dans les COMENT OMF.');
 WriteLn('     /NOGROUPASSOCIATION ignore GRPDEF et neutralise les index de groupe des lignes.');
 WriteLn('     /NOIGNORECASE active la sensibilite a la casse des symboles.');
 WriteLn('  /HELP /HE /H /?');
 WriteLn('     Affiche cette aide.');
End;

Procedure AddObjInput(Const Nm:String);
Begin
 If Nm='' Then Exit;
 If ObjInputCount>=MAX_CMD_OBJS Then Begin
  WriteLn('Erreur : Trop de fichiers OBJ en entree');
  Halt(21);
 End;
 Inc(ObjInputCount);
 ObjInputList^[ObjInputCount]:=Copy(Nm,1,128);
End;

Procedure AddLibInput(Const Nm:String);
Begin
 If Nm='' Then Exit;
 If LibInputCount>=MAX_CMD_LIBS Then Begin
  WriteLn('Erreur : Trop de bibliotheques en entree');
  Halt(22);
 End;
 Inc(LibInputCount);
 LibInputList^[LibInputCount]:=Copy(Nm,1,128);
End;

Procedure InitCommandInputStorage;
Begin
 If ObjInputList=Nil Then GetMem(ObjInputList,SizeOf(TCmdObjNameArray));
 If LibInputList=Nil Then GetMem(LibInputList,SizeOf(TCmdLibNameArray));
 If TempLibObjList=Nil Then GetMem(TempLibObjList,SizeOf(TCmdObjNameArray));

 FillChar(ObjInputList^,SizeOf(TCmdObjNameArray),0);
 FillChar(LibInputList^,SizeOf(TCmdLibNameArray),0);
 FillChar(TempLibObjList^,SizeOf(TCmdObjNameArray),0);
End;

Procedure FreeCommandInputStorage;
Begin
 If ObjInputList<>Nil Then Begin
  FreeMem(ObjInputList,SizeOf(TCmdObjNameArray));
  ObjInputList:=Nil;
 End;
 If LibInputList<>Nil Then Begin
  FreeMem(LibInputList,SizeOf(TCmdLibNameArray));
  LibInputList:=Nil;
 End;
 If TempLibObjList<>Nil Then Begin
  FreeMem(TempLibObjList,SizeOf(TCmdObjNameArray));
  TempLibObjList:=Nil;
 End;
End;

Function ParseUInt(Const S:String; Var V:LongInt):Boolean;
Var
 k:Integer;
Begin
 V:=0;
 ParseUInt:=False;
 If S='' Then Exit;
 For k:=1 to Length(S) do Begin
  If (S[k]<'0')Or(S[k]>'9') Then Exit;
  If V>214748364 Then Exit;
  V:=V*10+Ord(S[k])-Ord('0');
 End;
 ParseUInt:=True;
End;

Procedure FlushSpecItem;
Var
 item,itemUpper:String;
Begin
 item:=TrimStr(SpecCurrentItem);
 SpecCurrentItem:='';
 If item='' Then Exit;

 Case SpecField of
  0:AddObjInput(EnsureDefaultExt(item,'.OBJ'));
  1:If ExeFileName='' Then ExeFileName:=EnsureDefaultExt(item,'.EXE');
  2:Begin
    itemUpper:=UpperStr(item);
    If itemUpper='NUL' Then MapFileName:='NUL'
                       Else MapFileName:=EnsureDefaultExt(item,'.MAP');
    MapRequested:=True;
   End;
 Else
  AddLibInput(EnsureDefaultExt(item,'.LIB'));
 End;
End;

Procedure FeedSpecToken(Const Tok:String);
Var
 k:Integer;
 ch:Char;
Begin
 If Tok='' Then Exit;
 For k:=1 to Length(Tok) do Begin
  If SpecTerminated Then Break;
  ch:=Tok[k];
  Case ch of
   ';':Begin
    FlushSpecItem;
    SpecTerminated:=True;
   End;
   ',':Begin
    FlushSpecItem;
    If SpecField<3 Then Inc(SpecField);
   End;
   '+':Begin
    If SpecField In [0,3] Then FlushSpecItem
                         Else SpecCurrentItem:=SpecCurrentItem+ch;
   End;
  Else
   SpecCurrentItem:=SpecCurrentItem+ch;
  End;
 End;
End;

  Procedure ApplyTraceDirective(Const RawItem:String; Var HadError:Boolean);
  Var
   item,keyPart,valPart:String;
   eqPos:Integer;
  Begin
   item:=UpperStr(TrimStr(RawItem));
   If item='' Then Exit;

   eqPos:=Pos('=',item);
   If eqPos>0 Then Begin
    keyPart:=TrimStr(Copy(item,1,eqPos-1));
    valPart:=TrimStr(Copy(item,eqPos+1,255));
   End Else Begin
    keyPart:=item;
    valPart:='';
   End;

   If (keyPart='')Or(keyPart='ALL') Then Begin
    TraceLibSymbolsRequested:=True;
    If eqPos>0 Then Begin
     TraceLibNameFilter:=Copy(valPart,1,128);
     TraceSymNameFilter:=Copy(valPart,1,32);
    End;
   End Else If (keyPart='LIB')Or(keyPart='MODULE')Or(keyPart='MOD')Or(keyPart='NOSYM') Then Begin
    TraceLibSymbolsRequested:=False;
    If eqPos>0 Then TraceLibNameFilter:=Copy(valPart,1,128);
   End Else If (keyPart='SYM')Or(keyPart='SYMBOL')Or(keyPart='SYMBOLS') Then Begin
    TraceLibSymbolsRequested:=True;
    If eqPos>0 Then TraceSymNameFilter:=Copy(valPart,1,32);
   End Else Begin
    HadError:=True;
   End;
  End;

  Procedure ParseTraceOptionValue(Const TraceValue:String);
  Var
   rest,item:String;
   commaPos:Integer;
   hadError:Boolean;
  Begin
   rest:=TrimStr(TraceValue);
   If rest='' Then Begin
    TraceLibSymbolsRequested:=True;
    Exit;
   End;

   hadError:=False;
   Repeat
    commaPos:=Pos(',',rest);
    If commaPos>0 Then Begin
     item:=Copy(rest,1,commaPos-1);
     Delete(rest,1,commaPos);
    End Else Begin
     item:=rest;
     rest:='';
    End;
    ApplyTraceDirective(item,hadError);
   Until rest='';

   If hadError Then
    WriteLn('Avertissement : /TRACE:',TraceValue,
      ' invalide, utiliser LIB, SYM, ALL et variantes =filtre (combinaison via virgules).');
  End;

Procedure ParseOptionToken(Const RawTok:String);
Var
   work,opt,val,valUpper:String;
   p:Integer;
 num:LongInt;
Begin
 work:=TrimStr(RawTok);
 If work='' Then Exit;

 If (work[1]='/')Or(work[1]='-') Then Delete(work,1,1);
 work:=UpperStr(work);

 If (work='?')Or(work='H')Or(work='HE')Or(work='HELP') Then Begin
  ShowLinkHelp;
  Halt;
 End;

 p:=Pos(':',work);
 If p>0 Then Begin
  opt:=Copy(work,1,p-1);
  val:=Copy(work,p+1,255);
 End Else Begin
  opt:=work;
  val:='';
 End;

 If (opt='CP')Or(opt='CPARMAXALLOC') Then Begin
   If Not ParseUInt(val,num) Then Begin
    WriteLn('Erreur : valeur invalide pour /',opt,' : ',val);
    Halt(23);
   End;
   If num>65535 Then num:=65535;
   MaxAllocParagraphs:=num;
 End Else If (opt='DS')Or(opt='DSALLOCATE') Then Begin
   DsAllocateTop:=True;
   DosSegOrdering:=True;
 End
 Else If (opt='DO')Or(opt='DOSSEG') Then DosSegOrdering:=True
 Else If (opt='E')Or(opt='EXEPACK') Then ExePackRequested:=True
 Else If (opt='HI')Or(opt='HIGH') Then HighLoadRequested:=True
 Else If (opt='LI')Or(opt='LINENUMBERS') Then Begin
   LineNumbersRequested:=True;
   MapRequested:=True;
 End Else If (opt='M')Or(opt='MAP') Then Begin
   PublicsMapRequested:=True;
   MapRequested:=True;
   If val<>'' Then Begin
    valUpper:=UpperStr(val);
    If valUpper='NUL' Then MapFileName:='NUL'
                      Else MapFileName:=EnsureDefaultExt(val,'.MAP');
   End;
 End Else If (opt='NOD')Or(opt='NODEFAULTLIBRARYSEARCH') Then NoDefaultLibrarySearch:=True
 Else If (opt='NOG')Or(opt='NOGROUPASSOCIATION') Then NoGroupAssociation:=True
 Else If (opt='NOI')Or(opt='NOIGNORECASE') Then NoIgnoreCase:=True
 Else If (opt='O')Or(opt='OVERLAYINTERRUPT') Then Begin
   If Not ParseUInt(val,num) Then Begin
    WriteLn('Erreur : valeur invalide pour /',opt,' : ',val);
    Halt(24);
   End;
   If num>255 Then Begin
    WriteLn('Erreur : /',opt,' doit etre entre 0 et 255');
    Halt(24);
   End;
   OverlayInterruptSet:=True;
   OverlayInterruptValue:=num;
 End Else If (opt='P')Or(opt='PAUSE') Then PauseRequested:=True
 Else If (opt='SE')Or(opt='SEGMENTS') Then Begin
   If Not ParseUInt(val,num) Then Begin
    WriteLn('Erreur : valeur invalide pour /',opt,' : ',val);
    Halt(25);
   End;
   If num<1 Then num:=1;
   If num>MAX_SEGMENTS Then Begin
    WriteLn('Avertissement : /SEGMENTS limite a ',MAX_SEGMENTS,' dans cette version.');
    num:=MAX_SEGMENTS;
   End;
   MaxSegmentsOption:=num;
 End Else If (opt='ST')Or(opt='STACK') Then Begin
   If Not ParseUInt(val,num) Then Begin
    WriteLn('Erreur : valeur invalide pour /',opt,' : ',val);
    Halt(26);
   End;
   If num<1 Then num:=1;
   If num>65535 Then num:=65535;
   StackSize:=num;
 End Else If (opt='TR')Or(opt='TRACE') Then Begin
   TraceLibRequested:=True;
   ParseTraceOptionValue(val);
 End Else
  WriteLn('Avertissement : option LINK non reconnue en phase 1 : /',opt);
End;

Procedure ProcessInputToken(Const Tok:String); Forward;
Procedure ProcessResponseFile(Const RespFile:String); Forward;

Procedure TokenizeAndProcessLine(Const Line:String);
Var
 k:Integer;
 inQuote:Boolean;
 ch:Char;
 tok:String;
Begin
 inQuote:=False;
 tok:='';
 For k:=1 to Length(Line) do Begin
  ch:=Line[k];
  If ch='"' Then Begin
   inQuote:=Not inQuote;
   Continue;
  End;

  If (Not inQuote)And((ch=' ')Or(ch=#9)) Then Begin
   If tok<>'' Then Begin
    ProcessInputToken(tok);
    tok:='';
    If SpecTerminated Then Exit;
   End;
  End Else tok:=tok+ch;
 End;

 If tok<>'' Then ProcessInputToken(tok);
End;

Procedure ProcessResponseFile(Const RespFile:String);
Var
 f:Text;
 line:String;
 fName:String;
 err:Integer;
Begin
 fName:=TrimStr(RespFile);
 If fName='' Then Exit;

 If ResponseDepth>=8 Then Begin
  WriteLn('Erreur : profondeur maximale de @response atteinte');
  Halt(27);
 End;

 {$I-}
 Assign(f,fName);
 Reset(f);
 err:=IOResult;
 {$I+}

 If err<>0 Then Begin
  If Not HasExtension(fName) Then Begin
   fName:=fName+'.LNK';
   {$I-}
   Assign(f,fName);
   Reset(f);
   err:=IOResult;
   {$I+}
  End;
 End;

 If err<>0 Then Begin
  WriteLn('Erreur : impossible de lire le fichier response : ',RespFile);
  Halt(28);
 End;

 Inc(ResponseDepth);
 While Not Eof(f) do Begin
  ReadLn(f,line);
  TokenizeAndProcessLine(line);
  If SpecTerminated Then Break;
 End;
 Close(f);
 Dec(ResponseDepth);
End;

Procedure ProcessInputToken(Const Tok:String);
Begin
 If Tok='' Then Exit;
 If Tok[1]='@' Then ProcessResponseFile(Copy(Tok,2,255))
 Else If (Tok[1]='/')Or(Tok[1]='-') Then ParseOptionToken(Tok)
 Else FeedSpecToken(Tok);
End;

Procedure ParseLinkCommandLinePhase1;
Var
 argIdx:Integer;
 tok:String;
Begin
 InitCommandInputStorage;

 ObjInputCount:=0;
 LibInputCount:=0;
 PrimaryObjInputCount:=0;
 TempLibObjCount:=0;
 LoadedLibModuleCount:=0;
 LibModulesScannedCount:=0;
 LibModulesLoadedCount:=0;
 LibResolutionPasses:=0;
 TraceLibRequested:=False;
 TraceLibSymbolsRequested:=False;
 TraceLibNameFilter:='';
 TraceSymNameFilter:='';
 ObjFileName:='';
 ExeFileName:='';
 MapFileName:='';
 MapRequested:=False;
 LineNumbersRequested:=False;
 PublicsMapRequested:=False;
 NoDefaultLibrarySearch:=False;
 NoGroupAssociation:=False;
 NoIgnoreCase:=False;
 DosSegOrdering:=False;
 DsAllocateTop:=False;
 ExePackRequested:=False;
 HighLoadRequested:=False;
 PauseRequested:=False;
 OverlayInterruptSet:=False;
 OverlayInterruptValue:=$3F;
 MaxSegmentsOption:=MAX_SEGMENTS;
 SpecField:=0;
 SpecTerminated:=False;
 SpecCurrentItem:='';
 ResponseDepth:=0;

 If ParamCount=0 Then Begin
  ShowLinkHelp;
  Halt;
 End;

 For argIdx:=1 to ParamCount do Begin
  tok:=ParamStr(argIdx);
  If tok='' Then Continue;
  ProcessInputToken(tok);
  If SpecTerminated Then Break;
 End;
 FlushSpecItem;

 If ObjInputCount=0 Then Begin
  WriteLn('Erreur : Aucun fichier objet indique.');
  Halt(29);
 End;

 ObjFileName:=ObjInputList^[1];
 PrimaryObjInputCount:=ObjInputCount;
 If ExeFileName='' Then ExeFileName:=ChangeFileExt(ObjFileName,'.EXE');

 If MapRequested And (MapFileName='') Then MapFileName:=ChangeFileExt(ExeFileName,'.MAP')
                                      Else If MapFileName='' Then MapFileName:='NUL';

 If LibInputCount>0 Then
  WriteLn('Info : recherche des externes non resolus dans les LIB activee.');
 If TraceLibRequested Then Begin
  If TraceLibSymbolsRequested Then
   WriteLn('Info : mode trace LIB active (modules + symboles).')
  Else
   WriteLn('Info : mode trace LIB active (modules).');
  If TraceLibNameFilter<>'' Then
   WriteLn('Info : filtre trace bibliotheque = ',TraceLibNameFilter);
  If TraceSymNameFilter<>'' Then
   WriteLn('Info : filtre trace symbole = ',TraceSymNameFilter);
 End;
   If DosSegOrdering Then
    WriteLn('Info : /DOSSEG actif (ordre DOS des segments applique).');
   If DsAllocateTop Then
    WriteLn('Info : /DSALLOCATE actif (DATA/BSS places en haut avant STACK).');
   If NoDefaultLibrarySearch Then
    WriteLn('Info : /NODEFAULTLIBRARYSEARCH actif (DEFAULTLIB OMF ignorees).');
   If NoGroupAssociation Then
    WriteLn('Info : /NOGROUPASSOCIATION actif (GRPDEF et groupes ignores).');
 If OverlayInterruptSet Then
  WriteLn('Avertissement : /OVERLAYINTERRUPT parse mais non applique dans cette version.');
   If ExePackRequested Or HighLoadRequested
      Then
  WriteLn('Avertissement : certaines options sont analysees mais sans effet d''edition de liens.');
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  ShowLinkHelp;
  Halt(0);
 End;
 { Initialise }
 InitMainLists;
 InitOffsetPatchList;
 StackSize:=2048;          { Taille de la pile par defaut }
 MaxAllocParagraphs:=$FFFF;{ /CP ou /CPARMAXALLOC }
 HasEntryPoint:=False;
 EntrySegIndex:=0;
 EntryOffset:=0;
  { Analyseur compatible syntaxe LINK }
 ParseLinkCommandLinePhase1;
  { Processus de liaison }
 For i:=1 to ObjInputCount do Begin
  ObjSegBaseList[i]:=SegmentCount;
    If Not ReadObjFile(ObjInputList^[i]) Then Begin
     WriteLn('Erreur de lecture de fichier objet : ',ObjInputList^[i]);
   CleanupTempLibObjFiles;
     FreeCommandInputStorage;
   FreeOffsetPatchList;
   FreeMainLists;
   Halt(30);
  End;
 End;
 ApplyAliasToExternalSymbols;
 ResolveLibrariesForExternals;
 ApplyAliasToExternalSymbols;
 RecomputeSegmentAddresses;
 GenerateExe(ExeFileName);
 GenerateMapFile(MapFileName);
 WriteLn('Liaison compl‚t‚');
 If PauseRequested Then Begin
  Write('Pause demandee (/PAUSE). Appuyez sur Entree pour continuer...');
  ReadLn;
 End;
 CleanupTempLibObjFiles;
 FreeCommandInputStorage;
 FreeOffsetPatchList;
 FreeMainLists;
END.
