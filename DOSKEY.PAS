{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal )
}

Program DosKey;

{$M $400,0,0}
{$S-}

Uses DOS;

Const
 kbNoKey=0;
 kbEsc=$011B;
 kbAltSpc=$0200;
 kbCtrl2=$0300;
 kbShiftIns=$0500;
 kbCtrlDel=$0600;
 kbShiftDel=$0700;
 kbCtrl6=$071E;
 kbCtrlMinus=$0C1F;
 kbAltBS=$0E00;
 kbBS=$0E08;
 kbCtrlBS=$0E7F;
 kbShiftTab=$0F00;
 kbTab=$0F09;
 kbAltQ=$1000;
 kbCtrlQ=$1011;
 kbAltW=$1100;
 kbCtrlW=$1117;
 kbAltE=$1200;
 kbCtrlE=$1205;
 kbAltR=$1300;
 kbCtrlR=$1312;
 kbAltT=$1400;
 kbCtrlT=$1414;
 kbAltY=$1500;
 kbCtrlY=$1519;
 kbAltU=$1600;
 kbCtrlU=$1615;
 kbAltI=$1700;
 kbCtrlI=$1709;
 kbAltO=$1800;
 kbCtrlO=$180F;
 kbAltP=$1900;
 kbCtrlP=$1910;
 kbCtrlOpenBox=$1A1B;
 kbAltOpenBox=$1AF0;
 kbCtrlCloseBox=$1B1D;
 kbAltCloseBox=$1BF0;
 kbCtrlEnter=$1C0A;
 kbEnter=$1C0D;
 kbAltA=$1E00;
 kbCtrlA=$1E01;
 kbAltS=$1F00;
 kbCtrlS=$1F13;
 kbAltD=$2000;
 kbCtrlD=$2004;
 kbAltF=$2100;
 kbCtrlF=$2106;
 kbAltG=$2200;
 kbCtrlG=$2207;
 kbAltH=$2300;
 kbCtrlH=$2308;
 kbAltJ=$2400;
 kbCtrlJ=$240A;
 kbAltK=$2500;
 kbCtrlK=$250B;
 kbAltL=$2600;
 kbCtrlL=$260C;
 kbAltQuote=$28F0;
 kbAltEnviron=$29F0;
 kbCtrlBkSl=$2B1C;
 kbAltBkSl=$2BF0;
 kbAltZ=$2C00;
 kbCtrlZ=$2C1A;
 kbAltX=$2D00;
 kbCtrlX=$2D18;
 kbAltC=$2E00;
 kbCtrlC=$2E03;
 kbAltV=$2F00;
 kbCtrlV=$2F16;
 kbAltB=$3000;
 kbCtrlB=$3002;
 kbAltN=$3100;
 kbCtrlN=$310E;
 kbAltM=$3200;
 kbCtrlM=$320D;
 kbAltLess=$3300;
 kbAltGreat=$3400;
 kbAltQuestion=$35F0;
 kbAltMult=$3700;
 kbSpc=$3920;
 kbF1=$3B00;
 kbF2=$3C00;
 kbF3=$3D00;
 kbF4=$3E00;
 kbF5=$3F00;
 kbF6=$4000;
 kbF7=$4100;
 kbF8=$4200;
 kbF9=$4300;
 kbF10=$4400;
 kbHome=$4700;
 kbUp=$4800;
 kbPgUp=$4900;
 kbGrayMinus=$4A2D;
 kbAltGrayMinus=$4AF0;
 kbLeft=$4B00;
 kbKeypad5=$4CF0;
 kbRight=$4D00;
 kbGrayPlus=$4E2B;
 kbAltGrayPlus=$4EF0;
 kbEnd=$4F00;
 kbDn=$5000;
 kbPgDn=$5100;
 kbIns=$5200;
 kbDel=$5300;
 kbShiftF1=$5400;
 kbShiftF2=$5500;
 kbShiftF3=$5600;
 kbShiftF4=$5700;
 kbShiftF5=$5800;
 kbShiftF6=$5900;
 kbShiftF7=$5A00;
 kbShiftF8=$5B00;
 kbShiftF9=$5C00;
 kbShiftF10=$5D00;
 kbCtrlF1=$5E00;
 kbCtrlF2=$5F00;
 kbCtrlF3=$6000;
 kbCtrlF4=$6100;
 kbCtrlF5=$6200;
 kbCtrlF6=$6300;
 kbCtrlF7=$6400;
 kbCtrlF8=$6500;
 kbCtrlF9=$6600;
 kbCtrlF10=$6700;
 kbAltF1=$6800;
 kbAltF2=$6900;
 kbAltF3=$6A00;
 kbAltF4=$6B00;
 kbAltF5=$6C00;
 kbAltF6=$6D00;
 kbAltF7=$6E00;
 kbAltF8=$6F00;
 kbAltF9=$7000;
 kbAltF10=$7100;
 kbCtrlPrtSc=$7200;
 kbCtrlLeft=$7300;
 kbCtrlRight=$7400;
 kbCtrlEnd=$7500;
 kbCtrlPgDn=$7600;
 kbCtrlHome=$7700;
 kbAlt1=$7800;
 kbAlt2=$7900;
 kbAlt3=$7A00;
 kbAlt4=$7B00;
 kbAlt5=$7C00;
 kbAlt6=$7D00;
 kbAlt7=$7E00;
 kbAlt8=$7F00;
 kbAlt9=$8000;
 kbAlt0=$8100;
 kbAltMinus=$8200;
 kbAltEqual=$8300;
 kbCtrlPgUp=$8400;
 kbF11=$8500;
 kbF12=$8600;
 kbShiftF11=$8700;
 kbShiftF12=$8800;
 kbCtrlF11=$8900;
 kbCtrlF12=$8A00;
 kbAltF11=$8B00;
 kbAltF12=$8C00;
 kbCtrlUp=$8D00;
 kbCtrlDn=$8E00;
 kbCtrlIns=$9200;
 kbAltGraySlash=$A400;

 kbAltEnter=$1C00;
 kbAltEsc=$9100;
 kbCtrlEsc=$911B;
 kbShiftEsc=$921B;
 kbCtrlAltEsc=$9300;
 kbShiftWindows95=$C100;
 kbShiftWindows95Menu=$C400;
 kbCtrlWindows95=$CE00;
 kbCtrlWindows95Menu=$D000;
 kbAltWindows95=$DA00;
 kbAltWindows95Menu=$DC00;
 kbPrgOutWin=$E600;
 kbPrgLastBar=$E700;
 kbPrgMnuBar=$E800;
 kbPrgTitle=$E900;
 kbPrgClsIcon=$EA00;
 kbDnBar=$EB00;
 kbWindows95Left=$EC00;
 kbDnBarMs=$EC80;
 kbWindows95Right=$ED00;
 kbRBarMsPgUp=$ED80;
 kbWindows95Menu=$EE00;

 DefaultMode=True;

 F1=$3B;
 F2=$3C;
 F3=$3D;
 F4=$3E;
 F5=$3F;
 F6=$40;
 F7=$41;
 F8=$42;
 F9=$43;
 F0=$44;

 HomeKey=$47;
 CtrlHome=$77;
 UpArrow=$48;
 PgUp=$49;
 CtrlPgUp=$84;
 LeftArrow=$4B;
 CtrlLeftArrow=$73;
 RtArrow=$4D;
 CtrlRtArrow=$74;
 EndKey=$4F;
 CtrlEnd=$75;
 DownArrow=$50;
 PgDn=$51;
 CtrlPgDn=$76;
 InsertKey=$52;
 DeleteKey=$53;

 CtrlBkSl{^\}=#$1C;
 BackSpace=#$08;
 CtrlBsp=#$7F;
 Enter=#$0D;
 CtrlEnter=#$0A;
 Escape=#$1B;
 Tab=#$09;

Var
 CurrentLine:String;
 CurrentLineLen:Byte Absolute CurrentLine;
 MaxChars:Byte;
 LinePos,SavePos:Byte;
 InsertMode:Boolean;
 CmdQ:Array[0..$FF]of Byte;
 QTail,Qptr,Tptr:^String;
 QTailLen:^Byte Absolute QTail;
 QptrLen:^Byte Absolute QPtr;
 TptrLen:^Byte Absolute TPtr;
 QTailW:Word Absolute QTail;
 QptrW:Word Absolute QPtr;
 TptrW:Word Absolute TPtr;
 MarkX,MarkY:Byte;
 Mark:Word Absolute MarkX;
 Ch:Char;
 Scan:Byte;
 Key:Word Absolute Ch;
 XCur:Byte Absolute $0:$450;
 YCur:Byte Absolute $0:$451;
 CurrNmXTxts:Word Absolute $0:$44A;
 VideoPort:Word Absolute $0:$463;
 MaxColumn:Byte;
 SegV:Word;
 CtrlMode:Boolean;

Type
 UserRegs=Record Case Integer of
  0:(Ax,Bx,Cx,Dx,Si,Ds,Di,Es,Bp,Ip,Cs,Flags:Word);
  1:(Al,Ah,Bl,Bh,Cl,Ch,Dl,Dh:Byte);
 End;

Var
 PascalCode:Pointer;
 UserSP,UserSS:Word;
 User:^UserRegs Absolute UserSP;

Const
 CommandSig:Word=0;

Procedure SetSpLow;InLine($BC/$80/$01); { Mov Sp,$180 }

Function DefaultDrive:Char;Assembler;ASM
 MOV AH,19h
 INT 21h
 ADD AL,41h
END;

Const
 ActiveFlag:Boolean=False;

Type CsDataRec=Record
 Dos21Vec:LongInt;
 OurDs:Word;
 OurSs:Word;
 OurSp:Word;
 OurBp:Word;
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

Procedure CsData;Assembler;ASM
{  Dos21Vec} Dd 0
{  OurDs} Dw 0
{  OurSs} Dw 0
{  OurSp} Dw 0
{  OurBp} Dw 0
END; {CsData}

PROCEDURE IHook;Near;Assembler;ASM
  Cmp Ah,0Ah
  JE  @1
  Jmp CsData.CsDataRec.Dos21Vec
@1:
  Push Bp;PUSH Es;PUSH Di;PUSH Ds;PUSH Si;PUSH Dx;PUSH Cx;PUSH Bx;PUSH Ax
  Mov Ax,Ds
  Mov Ds,CsData.CsDataRec.OurDs
  Cmp CommandSig,0
  JNZ @2
  Mov CommandSig,Ax
@2:
  Cmp ActiveFlag,0
  jNZ @Chain
  Inc ActiveFlag
  Mov UserSS,Ss
  Mov UserSP,Sp
  Mov Ss,CsData.CsDataRec.OurSs
  Mov Sp,CsData.CsDataRec.OurSp
  Mov Bp,CsData.CsDataRec.OurBp
  Call PascalCode
  Mov Ss,UserSS
  Mov Sp,UserSP
  Mov ActiveFlag,0
@Chain:
  Pop  Ax;POP Bx;POP Cx;POP Dx;POP Si;POP Ds;POP Di;POP Es;POP Bp
  Jmp CsData.CsDataRec.Dos21Vec
END;

PROCEDURE IRestore;Assembler;ASM
 Mov Ax,02521h
 Push Ds
  Lds Dx,CsData.CsDataRec.Dos21Vec
  Int 021h
 Pop Ds
END;

PROCEDURE IReturn;Assembler;ASM
 Mov Ss,UserSS
 Mov Sp,UserSP
 Mov ActiveFlag,0
 Pop Ax;POP Bx;POP Cx;POP Dx;POP Si;POP Ds;POP Di;POP Es;POP Bp
 IRET
END;

Procedure IChain;Assembler;ASM
 Mov Ss,UserSS
 Mov Sp,UserSP
 Mov ActiveFlag,0
 Pop Ax;POP Bx;POP Cx;POP Dx;POP Si;POP Ds;POP Di;POP Es;POP Bp
 Jmp CsData.CsDataRec.Dos21Vec
END;

Procedure WriteSubStr(Var S;Index,Count:Word);Assembler;ASM
 Mov Cx,Count
 jCXZ @Finish
 Push Ds
  Lds Si,S
  Add Si,Index
  Mov Ah,06
  Cld
@L0:
  LodSB
  Mov Dl,Al
  Cmp Dl,255
  JNE @2
  Mov Dl,' '
@2:
  Int 021h
  Loop @L0
 Pop Ds
@Finish:
END;

Procedure WriteChar(Ch0:Char);Assembler;
ASM
 Mov Ah,06
 Mov Dl,Ch0
 Cmp Dl,255
 JNE @1
 Mov Dl,' '
@1:
 Int 021h
END;

Function ReadCursor:Word;Assembler;ASM
 Mov Ah,0Fh
 Int 10h
 Mov MaxColumn,Ah
 Mov Ah,03
 Int 10h
 ADD Dh,Dl
 Mov AX,DX
END;

Function WhereX:Byte;Begin
 WhereX:=Lo(ReadCursor)
End;

Function WhereY:Byte;Begin
 WhereY:=Hi(ReadCursor)
End;

PROCEDURE SetCursor(Posn:Word);Assembler;ASM
 Mov Ah,0Fh
 Int 10h
 Mov Dx,Posn
 SUB Dh,Dl
 Mov Ah,02
 Int 10h
END;

Procedure WideCursor;Assembler;ASM
 Mov Ah,0Fh
 Int 10h
 Mov Cx,0507h
 Cmp Al,07h
 JNE @1
 Mov Cx,080Ch
@1:
 Mov Ah,01
 Int 10h
END;

Procedure ThinCursor;Assembler;ASM
 Mov Ah,0Fh
 Int 10h
 Mov Cx,0707h
 Cmp Al,07h
 JNE @1
 MOV Cx,0B0Ch
@1:
 Mov Ah,01
 Int 10h
END;

Procedure HideCursor;Assembler;ASM
 Mov Ah,0Fh
 Int 10h
 Mov Cx,02000h
 Mov Ah,01
 Int 10h
END;

Function BiosReadKey:Char;Assembler;
Const
 BiosSaveScan:Byte=0;
ASM
 Xor Ax,Ax
 Xchg Al,BiosSaveScan
 Or Al,Al
 jNZ @Return
 Int 016h
 Or Al,Al
 jNZ @Return
 Mov BiosSaveScan,Ah
@Return:
END;

Function Keypress:Boolean;Begin
 Inline($FA); (* CLI *)
 Keypress:=MemW[$0040:$1A]<>MemW[$0040:$1C];
 Inline($FB); (* STI *)
End;

Function ReadKey:Word;Assembler;ASM
 XOR AX,AX
 INT $16
END;

Procedure PutTxtXY(X,Y:Byte;Const S:String);
Var
 I:Byte;
Begin
 For I:=0to Length(S)-1do MemW[SegV:(X+I+Y*CurrNmXTxts)shl 1]:=Byte(S[I+1])+$1B00;
End;

Procedure SetCurPos(X,Y:Byte);Assembler;ASM
 MOV AH,02h
 MOV DL,X
 MOV DH,Y
 INT 10h
END;

Procedure PutTxt(Const S:String);
Var
 B:Word;
 I:Byte;
Begin
 B:=YCur*CurrNmXTxts+XCur;
 For I:=0to Length(S)-1do Mem[SegV:(I+B)shl 1]:=Byte(S[I+1]);
 Inc(XCur,Length(S));
 For I:=Length(S)to CurrNmXTxts-1do Mem[SegV:(I+B)shl 1]:=32;
 SetCurPos(XCur,YCur);
End;

Procedure ShowCursor;Begin
 If(InsertMode)Then WideCursor Else ThinCursor;
End;

Procedure CursorLeft;Begin
 If LinePos>1Then Begin
  Mark:=ReadCursor;
  WriteChar(#8);Dec(LinePos);
  If(WhereX=MarkX)Then Begin
   Dec(MarkY);MarkX:=MaxColumn;SetCursor(Mark);
  End;
 End;
End;

Procedure WordLeft;Begin
 If LinePos>1Then Repeat CursorLeft Until(LinePos=1)or((CurrentLine[LinePos]<>' ')and(CurrentLine[LinePos-1]=' '))
End;

Procedure CursorRight;Begin
 If(LinePos<=CurrentLineLen)Then Begin
  WriteChar(CurrentLine[LinePos]);
  Inc(LinePos);
 End;
End;

Procedure WordRight;Begin
 If(LinePos<=CurrentLineLen)Then
  Repeat CursorRight Until(LinePos>CurrentLineLen)or((CurrentLine[LinePos]<>' ')and(CurrentLine[LinePos-1]=' '));
End;

Procedure CursorHome;Begin
 While LinePos>1do CursorLeft;
End;

Procedure CursorEnd;Begin
 While(LinePos<=CurrentLineLen)do CursorRight;
End;

Procedure ToggleMode;Begin
 InsertMode:=Not InsertMode;
 ShowCursor;
End;

Procedure InsertChar(Ch1:Char);Var Mark2:Word;Begin
 IF CurrentLineLen<MaxChars-1Then Begin
  Insert(Ch1,CurrentLine,LinePos);CursorRight;
  Mark:=ReadCursor;
  WriteSubStr(CurrentLine,LinePos,1+CurrentLineLen-LinePos);
  If(LinePos<=Length(CurrentLine))and(WhereY=MarkY)Then Begin
   Mark2:=ReadCursor; WriteChar(#8);
   If(Mark2=ReadCursor)Then Dec(MarkY)
                       Else MarkY:=WhereY;
  End;
  SetCursor(Mark);
 End;
End;

Procedure OverWrite(Ch1:Char);Begin
 If(LinePos<MaxChars)Then Begin
  If(LinePos>CurrentLineLen)Then Inc(CurrentLineLen);
  WriteChar(Ch1);
  CurrentLine[LinePos]:=Ch1;Inc(LinePos);
 End;
End;

Procedure DeleteChar;Begin
 If LinePos<=CurrentLineLen Then Begin
  Mark:=ReadCursor;
  Delete(CurrentLine,LinePos,1);
  WriteSubStr(CurrentLine,LinePos,1+CurrentLineLen-LinePos);
  WriteChar(' '); SetCursor
  (Mark);
 End;
End;

Procedure DeleteLeft;Begin
 If LinePos>1 Then Begin
  CursorLeft;
  DeleteChar;
 End;
End;

Procedure DisplayNew(Var Cmd:String;OldLen:Byte);
Var
 n:Byte;
 CmdLen:Byte Absolute Cmd;
Begin
 CursorHome;
 If Not(CtrlMode)Then Begin
  PutTxt(Cmd);
  If(OldLen>CmdLen)Then Begin
   Mark:=ReadCursor;
   For n:=CmdLen to OldLen-1do WriteChar(' ');
   SetCursor(Mark);
  End;
 End;
 CurrentLine:=Cmd;LinePos:=CurrentLineLen+1;
End;

Procedure EraseLine;Begin
 SavePos:=CurrentLineLen;
 CurrentLineLen:=0;
 DisplayNew(CurrentLine,SavePos);
End;

Procedure DeleteHome; Begin
 If LinePos>1 Then Begin
  SavePos:=CurrentLineLen;
  Delete(CurrentLine,1,LinePos-1);
  DisplayNew(CurrentLine,SavePos);
  CursorHome;
 End;
End;

Procedure DeleteEnd;Begin
 IF LinePos<=CurrentLineLen Then Begin
  SavePos:=CurrentLineLen;
  CurrentLineLen:=LinePos-1;
  DisplayNew(CurrentLine,SavePos);
 End;
End;

Procedure NextCommand;
Var
 n:Byte;
Begin
 If QTail=@CmdQ Then Exit;
 If QPtr=QTail Then QPtr:=@CmdQ
                 Else Inc(QPtrW,QPtrLen^+2);
 If QPtr=QTail Then QPtr:=@CmdQ;
 DisplayNew(QPtr^,CurrentLineLen);
End;

Procedure PrevCommand;Begin
 If(QTail=@CmdQ)Then Exit;
 If(QPtr=QTail)or(CurrentLineLen<>0)Then Begin
 If(Qptr=@CmdQ)Then QPtr:=QTail;
  Dec(QptrW);
  Dec(QptrW,QPtrLen^+1);
 End;
 DisplayNew(QPtr^,CurrentLineLen);
End;

Procedure ClearCommand;Begin
 If CurrentLine<>QPtr^ Then Begin
  EraseLine;
  Exit;
 End;
 If(QTail=@CmdQ)or(QPtr=QTail)Then Exit;
 Tptr:=Qptr;
 Inc(TPtrW,QPtrLen^+2);
 Move(TPtr^,QPtr^,Ofs(CmdQ)+SizeOf(CmdQ)-TPtrW);
 Dec(QTailW,TPtrW-QPtrW);
 MemW[Dseg:QTailW]:=0;
 If QPtr=QTail Then QPtr:=@CmdQ;
 DisplayNew(QPtr^,CurrentLineLen);
End;

Procedure ClearQueue;Begin
 EraseLine;
 Qtail:=@CmdQ;
 QPtr:=QTail;
 MemW[Dseg:Ofs(CmdQ)]:=0;
End;

Procedure QueueCommand;Begin
 TPtr := @CmdQ;
 While CurrentLineLen+2+QTailW-TPtrW>SizeOf(CmdQ)do Inc(TPtrW,TPtrLen^+2);
 If TPtrW<>Ofs(CmdQ)Then Move(TPtr^,CmdQ,Ofs(CmdQ)+SizeOf(CmdQ)-TPtrW);
 Dec(QTailW,TPtrW-Ofs(CmdQ));

 QTail^:=CurrentLine;
 Inc(QTailW,CurrentLineLen+1);
 QTailLen^:=CurrentLineLen;
 Inc(QTailW);
 QPtr:=QTail;
End;

Procedure ReturnCommand;Begin
 CurrentLine[CurrentLineLen+1]:=#13;
 Move(CurrentLine,Mem[User^.Ds:User^.Dx+1],CurrentLineLen+2);
 CursorEnd;
 ShowCursor;
 IReturn;
End;

Procedure QueueReturn;Begin
 If(CurrentLineLen>2)and(CurrentLine<>QPtr^)Then QueueCommand;
 ReturnCommand;
End;

Procedure MacroReturn;Begin
 SavePos:=CurrentLineLen;
 Case(Scan)of
  F2:CurrentLine:='EXIT';
  F5:CurrentLine:='DIR';
  Else Exit;
 End;
 DisplayNew(CurrentLine,SavePos);
 ReturnCommand;
End;

Procedure DisplayPath;
Var
 Directory:String[67];
Begin
 If(DefaultDrive>='C')and(User^.Ds=CommandSig)and(WhereX=3)Then Begin
  GetDir(0,Directory);
  XCur:=0;
  WriteSubStr(Directory,1,Length(Directory));
  WriteChar('>');
 End;
End;

Const
 Help1:String[40]='ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ Aide ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»';
 Help2:String[40]='º F1        Obtenir cette aide         º';
 Help3:String[40]='º F2        Quitter (EXIT<ÄÙ)          º';
 Help4:String[40]='º /³\       Commande Pr‚c‚dente        º';
 Help5:String[40]='º <ÄÄ       Reculer d''une position     º';
 Help6:String[40]='º Esc       Efface la ligne            º';
 Help7:String[40]='º Insert    Mode insertion/‚craser     º';
 Help8:String[40]='º Ctrl+PgUp Efface la queue            º';
 Help9:String[40]='º Ctrl+B    Lancer le ®Borland Pascal¯ º';
 Help10:String[40]='º Ctrl+C    Lancer le ®Turbo C++¯      º';
 Help11:String[40]='º Ctrl+M    Lancer le ®MonsterBook¯    º';
 Help12:String[40]='º Ctrl+N    Lance ®Norton Commander¯   º';
 Help13:String[40]='º Ctrl+W    Lancer ®Windows¯           º';
 Help14:String[40]='ÈÍÍÍÍÍÍÍÍ Presse une touche... ÍÍÍÍÍÍÍÍ¼';

Procedure Help;
Var
 ScrSize:Word Absolute 0:$44C;
 X:Byte;
Begin
 Move(Mem[SegV:0],Mem[SegV:ScrSize],ScrSize);
 X:=(CurrNmXTxts-40)shr 1;
 PutTxtXY(X,4,Help1);
 PutTxtXY(X,5,Help2);
 PutTxtXY(X,6,Help3);
 PutTxtXY(X,7,Help4);
 PutTxtXY(X,8,Help5);
 PutTxtXY(X,9,Help6);
 PutTxtXY(X,10,Help7);
 PutTxtXY(X,11,Help8);
 PutTxtXY(X,12,Help9);
 PutTxtXY(X,13,Help10);
 PutTxtXY(X,14,Help11);
 PutTxtXY(X,15,Help12);
 PutTxtXY(X,16,Help13);
 PutTxtXY(X,17,Help14);
 Repeat Until KeyPress;
 ReadKey;
 Move(Mem[SegV:ScrSize],Mem[SegV:0],ScrSize);
End;

Procedure ServiceProc;Far;Begin
 If VideoPort=$3D4Then SegV:=$B800
                  Else SegV:=$B000;
 LinePos:=1;
 CurrentLineLen:=0;
 CtrlMode:=False;
 InsertMode:=DefaultMode;
 ShowCursor;
 MaxChars:=Mem[User^.Ds:User^.Dx];
 DisplayPath;
 Repeat
  ShowCursor;
  Repeat Until KeyPress;
  Key:=ReadKey;
  HideCursor;
  Case(Key)of
   kbCtrlBkSl:Begin
    EraseLine;
    ShowCursor;
    IChain;
   End;
   kbCtrlB,kbCtrlC,kbCtrlG,kbCtrlI,kbCtrlM,kbCtrlN,kbCtrlT,kbCtrlW:Begin
    CtrlMode:=True;
    SavePos:=CurrentLineLen;
    Case(Key)of
     kbCtrlB:Begin
      CurrentLine:='BP.EXE';
      PutTxt('Lance le ®Borland Pascal¯...');
     End;
     kbCtrlC:CurrentLine:='TC.EXE';
     kbCtrlG:CurrentLine:='GEOS';
     kbCtrlI:CurrentLine:='SI.EXE';
     kbCtrlM:CurrentLine:='MB.EXE';
     kbCtrlN:CurrentLine:='NC.EXE';
     kbCtrlT:Begin
      PutTxt('Lance le ®TeleMate¯...');
      CurrentLine:='TM';
     End;
     kbCtrlW:Begin
      PutTxt('Lance ®Windows¯...');
      ChDir('C:\WINDOWS');
      CurrentLine:='WIN.EXE';
     End;
    End;
    DisplayNew(CurrentLine,SavePos);
    ReturnCommand;
   End;
   Else Case(Ch)of
    Enter:QueueReturn;
    Escape:EraseLine;
    BackSpace:DeleteLeft;
    #1..#255:If(InsertMode)Then InsertChar(ch)Else OverWrite(ch);
    #0:Case(Scan)of{- Touche ‚tendue -}
     LeftArrow:CursorLeft;
     RtArrow:CursorRight;
     CtrlLeftArrow:WordLeft;
     CtrlRtArrow:WordRight;
     HomeKey:CursorHome;
     EndKey:CursorEnd;
     CtrlHome:DeleteHome;
     CtrlEnd:DeleteEnd;
     DeleteKey:DeleteChar;
     InsertKey:ToggleMode;
     UpArrow:PrevCommand;
     DownArrow:NextCommand;
     CtrlPgDn:ClearCommand;
     CtrlPgUp:ClearQueue;
     F1:Help;
     Else MacroReturn;
    End;
   End;
  End;
 Until False;
End;

Procedure Shell;
Const
 ErrMsg:String[27]='A:\COMMAND.COM Introuvable'#10;
Begin
 SetSpLow;
 Exec(GetEnv('COMSPEC'),'');
 If DosError<>0Then Exec('C:\COMMAND.COM','');
 If DosError<>0Then Exec('A:\COMMAND.COM','');
 If DosError<>0Then WriteSubStr(ErrMsg,1,Length(ErrMsg));
 Irestore;
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('DOSKEY : Cette commande permet de charger le programme DOSKEY.');
  WriteLn;
  WriteLn('Syntaxe : DOSKEY /SHELL');
  WriteLn;
  WriteLn(' /SHELL   Lance l''interpr‚teur de commande');
 End
  Else
 Begin
  ASM
   Mov CsData.CsDataRec.OurDs,Ds
   Mov CsData.CsDataRec.OurSs,Ss
   Mov CsData.CsDataRec.OurSp,Sp
   Mov CsData.CsDataRec.OurBp,Bp

   Mov Ax,03521h
   Int 021h
   Mov Word Ptr CsData.CsDataRec.Dos21Vec,Bx
   Mov Word Ptr CsData.CsDataRec.Dos21Vec+2,Es

   Mov Ax,02521h
   Push Cs
   Pop Ds
   Mov Dx,Offset IHook
   Int 021h
   Mov Ds,CsData.CsDataRec.OurDs
  END;
  Qtail:=@CmdQ;QPtr:=QTail;
  MemW[Dseg:Ofs(CmdQ)]:=0;
  PascalCode:=@ServiceProc;
  ASM
   MOV Es,PrefixSeg
   Mov Es,Es:[$2C]
   Mov Ah,$49
   Int $21
  END;
  If StrToUpper(ParamStr(1))='/SHELL'Then Shell
   Else
  Begin
   WriteLn('DOSKEY est maintenant r‚sident.');
   Keep(0);
  End;
 End;
END.