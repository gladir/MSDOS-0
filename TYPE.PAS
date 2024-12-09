{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal, Free Pascal)
}

Program _TYPE;

{$N+}

Uses DOS;

Var
 Options:Set Of (IsGWBASIC);
 Err:Word;
 CurrParam,CurrLine:String;
 I:Integer;
 Info:SearchRec;

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

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function IsWildCard(Path:String):Boolean;Begin
 IsWildCard:=(Pos('*',Path)>0)or(Pos('?',Path)>0)
End;

Procedure TypeBASIC(SourceName:String);
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
 {$I-}Assign(Source,SourceName);
 Reset(Source,1);{$I+}
 If IoResult<>0Then Begin
  WriteLn('Fichier source introuvable');
  Halt;
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
   BlockRead(Source,Buffer,1,ByteReaded);
   Pos:=Buffer[0];
   BlockRead(Source,Buffer,1,ByteReaded);
   Pos:=Pos+Buffer[0]*256;
   Write(Pos,' ');
   NewLine:=True;
   LastB:=0;
   Repeat
    BlockRead(Source,Buffer,1,ByteReaded);
    B:=Buffer[0];
RFGW:
    Case B of
     0:Begin
      WriteLn;
      BlockRead(Source,Buffer,1,ByteReaded);
      Pos:=Buffer[0];
      BlockRead(Source,Buffer,1,ByteReaded);
      Pos:=Pos+Buffer[0]*256;
      BlockRead(Source,Buffer,1,ByteReaded);
      If(Pos=0)and(Buffer[0]=26)Then Break;
      Pos:=Buffer[0];
      BlockRead(Source,Buffer,1,ByteReaded);
      Pos:=Pos+Buffer[0]*256;
      Write(Pos,' ');
      NewLine:=True;
     End;
     $0C:Write('&H');
     $0F:Begin
      BlockRead(Source,Buffer,1,ByteReaded);
      Write(Buffer[0]);
     End;
     $11..$1A:Begin
      Write(Char(Buffer[0]+31));
     End;
     $1C:Begin
      BlockRead(Source,Buffer,2,ByteReaded);
      Write(Buffer[0]+Buffer[1]*256);
     End;
     $1D:Begin
      BlockRead(Source,BufSingle,4,ByteReaded);
      Write(BufSingle);
     End;
     $1F:Begin
      BlockRead(Source,BufDouble,4,ByteReaded);
      Write(BufDouble);
     End;
     $3A:Begin
      BlockRead(Source,Buffer,1,ByteReaded);
      Case Buffer[0]of
       $20:Begin
        BlockRead(Source,Buffer,1,ByteReaded);
        If Buffer[0]=32Then Write('GOSUB')
                       Else Write(#$3A,#32,Buffer[0]);
       End;
       $8F:Begin
        LastB:=B;
        B:=Buffer[0];
        Goto RFGW;
       ENd;
       $A1:Write('ELSE');
       Else Begin
        Write(Char(B));
        LastB:=B;
        B:=Buffer[0];
        Goto RFGW;
       End;
      End;
     End;
     $81:Write('END');
     $82:Write('FOR');
     $83:Write('NEXT');
     $84:Write('DATA');
     $85:Write('INPUT');
     $86:Write('DIM');
     $87:Write('READ');
     $88:Write('LET');
     $89:Write('GOTO');
     $8A:Write('RUN');
     $8B:Write('IF');
     $8C:Write('RESTORE');
     $8D:Write('GOSUB');
     $8E:Write('RETURN');
     $8F:Begin
      BlockRead(Source,Buffer,1,ByteReaded);
      Case Buffer[0]of
       $D9:Begin
        Write('''');
        While Not EOF(Source)do Begin
         BlockRead(Source,Buffer,1,ByteReaded);
         If Buffer[0]=0Then Begin
          B:=Buffer[0];
          Goto RFGW;
         End;
         Write(Char(Buffer[0]));
        End;
       End;
       Else Begin
        Write('REM');
        While Not EOF(Source)do Begin
         BlockRead(Source,Buffer,1,ByteReaded);
         If Buffer[0]=0Then Begin
         B:=Buffer[0];
          Goto RFGW;
         End;
         Write(Char(Buffer[0]));
        End;
       End;
      End;
     End;
     $90:Write('STOP');
     $91:Write('PRINT');
     $92:Write('CLEAR');
     $93:Write('LIST');
     $94:Write('NEW');
     $95:Write('ON');
     $96:Write('WAIT');
     $97:Write('DEF');
     $98:Write('POKE');
     $99:Write('CONT');
     $9C:Write('OUT');
     $9D:Write('LPRINT');
     $9E:Write('LLIST');
     $A0:Write('WIDTH');
     $A1:Write('ELSE');
     $A2:Write('TRON');
     $A3:Write('TROFF');
     $A4:Write('SWAP');
     $A5:Write('ERASE');
     $A6:Write('EDIT');
     $A7:Write('ERROR');
     $A8:Write('RESUME');
     $A9:Write('DELETE');
     $AA:Write('AUTO');
     $AB:Write('RENUM');
     $AC:Write('DEFSTR');
     $AD:Write('DEFINT');
     $AE:Write('DEFSNG');
     $AF:Write('DEFDBL');
     $B0:Write('LINE');
     $B1:Write('WHILE');
     $B2:Write('WEND');
     $B3:Write('CALL');
     $B7:Write('WRITE');
     $B8:Write('OPTION');
     $B9:Write('RANDOMIZE');
     $BA:Write('OPEN');
     $BB:Write('CLOSE');
     $BC:Write('LOAD');
     $BD:Write('MERGE');
     $BE:Write('SAVE');
     $BF:Write('COLOR');
     $C0:Write('CLS');
     $C1:Write('MOTOR');
     $C2:Write('BSAVE');
     $C3:Write('BLOAD');
     $C4:Write('SOUND');
     $C5:Write('BEEP');
     $C6:Write('PSET');
     $C7:Write('PRESET');
     $C8:Write('SCREEN');
     $C9:Write('KEY');
     $CA:Write('LOCATE');
     $CC:Write('TO');
     $CD:Write('THEN');
     $CE:Write('TAB(');
     $CF:Write('STEP');
     $D0:Write('USR');
     $D1:Write('FN');
     $D2:Write('SPC(');
     $D3:Write('NOT');
     $D4:Write('ERL');
     $D5:Write('ERR');
     $D6:Write('STRING$');
     $D7:Write('USING');
     $D8:Write('INSTR');
     $D9:Write('''');
     $DA:Write('VARPTR');
     $DB:Write('CSRLIN');
     $DC:Write('POINT');
     $DD:Write('OFF');
     $DE:Write('INKEY$');
     $E6:Write('>');
     $E7:Write('=');
     $E8:Write('<');
     $E9:Write('+');
     $EA:Write('-');
     $EB:Write('*');
     $EC:Write('/');
     $EE:Write('AND');
     $EF:Write('OR');
     $F0:Write('XOR');
     $F1:Write('EQV');
     $F2:Write('IMP');
     $F3:Write('MOD');
     $F4:Write('\');
     $FD:Begin
      BlockRead(Source,Buffer,1,ByteReaded);
      Case Buffer[0]of
       $81:Write('CVI');
       $82:Write('CVS');
       $83:Write('CVD');
       $84:Write('MKI$');
       $85:Write('MKS$');
       $86:Write('MKD$');
       $87..$8A:Write('---');
       $8B:Write('EXTERR');
       Else Write(Char(Buffer[0]));
      End;
     End;
     $FE:Begin
      BlockRead(Source,Buffer,1,ByteReaded);
      Case Buffer[0]of
       $81:Write('FILES');
       $82:Write('FIELD');
       $83:Write('SYSTEM');
       $84:Write('NAME');
       $85:Write('LSET');
       $86:Write('RSET');
       $87:Write('KILL');
       $88:Write('PUT');
       $89:Write('GET');
       $8A:Write('RESET');
       $8B:Write('COMMON');
       $8C:Write('CHAIN');
       $8D:Write('DATE$');
       $8E:Write('TIME$');
       $8F:Write('PAINT');
       $90:Write('COM');
       $91:Write('CIRCLE');
       $92:Write('DRAW');
       $93:Write('PLAY');
       $94:Write('TIMER');
       $95:Write('ERDEV');
       $96:Write('IOCTL');
       $97:Write('CHDIR');
       $98:Write('MKDIR');
       $99:Write('RMDIR');
       $9A:Write('SHELL');
       $9B:Write('ENVIRON');
       $9C:Write('VIEW');
       $9D:Write('WINDOW');
       $9E:Write('PMAP');
       $9F:Write('PALETTE');
       $A0:Write('LCOPY');
       $A1:Write('CALLS');
       $A2,$A3,$A4,$A6:Write('---');
       $A5:Write('PCOPY');
       $A7:Write('LOCK');
       $A8:Write('UNLOCK');
       Else Write(Char(Buffer[0]));
      End;
     End;
     $FF:Begin
      BlockRead(Source,Buffer,1,ByteReaded);
      Case Buffer[0]of
       $81:Write('LEFT$');
       $82:Write('RIGHT$');
       $83:Write('MID$');
       $84:Write('SGN');
       $85:Write('INT');
       $86:Write('ABS');
       $87:Write('SQR');
       $88:Write('RND');
       $89:Write('SIN');
       $8A:Write('LOG');
       $8B:Write('EXP');
       $8C:Write('COS');
       $8D:Write('TAN');
       $8E:Write('ATN');
       $8F:Write('FRE');
       $90:Write('INP');
       $91:Write('POS');
       $92:Write('LEN');
       $93:Write('STR$');
       $94:Write('VAL');
       $95:Write('ASC');
       $96:Write('CHR$');
       $97:Write('PEEK');
       $98:Write('SPACE$');
       $99:Write('OCT$');
       $9A:Write('HEX$');
       $9B:Write('LPOS');
       $9C:Write('CINT');
       $9D:Write('CSNG');
       $9E:Write('CDBL');
       $9F:Write('FIX');
       $A0:Write('PEN');
       $A1:Write('STICK');
       $A2:Write('STRIG');
       $A3:Write('EOF');
       $A4:Write('LOC');
       $A5:Write('LOF');
       Else Write(Char(Buffer[0]));
      End;
     End;
     Else Write(Char(Buffer[0]));
    End;
    If B<>0Then NewLine:=False;
    LastB:=B;
   Until EOF(Source);
   Close(Source);
  End;
  Coco1FileBAS:Begin
   BlockRead(Source,Buffer,1,ByteReaded);
   BlockRead(Source,Buffer,1,ByteReaded);
   BlockRead(Source,Buffer,1,ByteReaded);
   Pos:=Buffer[0]*256;
   BlockRead(Source,Buffer,1,ByteReaded);
   Pos:=Pos+Buffer[0];
   Write(Pos,' ');
   NewLine:=True;
   LastB:=0;
   Repeat
    BlockRead(Source,Buffer,1,ByteReaded);
    B:=Buffer[0];
RF0:
    Case B of
     0:Begin
      WriteLn;
      BlockRead(Source,Buffer,1,ByteReaded);
      BlockRead(Source,Buffer,1,ByteReaded);
      BlockRead(Source,Buffer,1,ByteReaded);
      Pos:=Buffer[0]*256;
      BlockRead(Source,Buffer,1,ByteReaded);
      Pos:=Pos+Buffer[0];
      Write(Pos,' ');
      NewLine:=True;
     End;
     $3A:Begin
      BlockRead(Source,Buffer,1,ByteReaded);
      Case Buffer[0]of
       $83:Write('''');
       $84:Write('ELSE');
       $92:Write('POKE');
       Else Begin
        Write(':');
        LastB:=B;B:=Buffer[0];
        Goto RF0;
       End;
      End;
     End;
     $80:Write('FOR');
     $81:Write('GO');
     $82:Write('REM');
     $83:Write('''');
     $84:Write('ELSE');
     $85:Write('IF');
     $86:Write('DATA');
     $87:Write('PRINT');
     $88:Write('ON');
     $89:Write('INPUT');
     $8A:Write('END');
     $8B:Write('NEXT');
     $8C:Write('DIM');
     $8D:Write('READ');
     $8E:Write('RUN');
     $8F:Write('RESTORE');
     $90:Write('RETURN');
     $91:Write('STOP');
     $92:Write('POKE');
     $93:Write('CONT');
     $94:Write('LIST');
     $95:Write('CLEAR');
     $96:Write('NEW');
     $97:Write('CLOAD');
     $98:Write('CSAVE');
     $99:Write('OPEN');
     $9A:Write('CLOSE');
     $9B:Write('LLIST');
     $9C:Write('SET');
     $9D:Write('RESET');
     $9E:Write('CLS');
     $9F:Write('MOTOR');
     $A0:Write('SOUND');
     $A1:Write('AUDIO');
     $A2:Write('EXEC');
     $A3:Write('SKIPF');
     $A4:Write('TAB(');
     $A5:Write('TO');
     $A6:Write('SUB');
     $A7:Write('THEN');
     $A8:Write('NOT');
     $A9:Write('STEP');
     $AA:Write('OFF');
     $AB:Write('+');
     $AC:Write('-');
     $AD:Write('*');
     $AE:Write('/');
     $AF:Write('^');
     $B0:Write('AND');
     $B1:Write('OR');
     $B2:Write('>');
     $B3:Write('=');
     $B4:Write('<');
     $B5:Write('DEL');
     $B6:Write('EDIT');
     $B7:Write('TRON');
     $B8:Write('TROFF');
     $B9:Write('DEF');
     $BA:Write('LET');
     $BB:Write('LINE');
     $BC:Write('PCLS');
     $BD:Write('PSET');
     $BE:Write('PRESET');
     $BF:Write('SCREEN');
     $C0:Write('PCLEAR');
     $C1:Write('COLOR');
     $C2:Write('CIRCLE');
     $C3:Write('PAINT');
     $C4:Write('GET');
     $C5:Write('PUT');
     $C6:Write('DRAW');
     $C7:Write('PCOPY');
     $C8:Write('PMODE');
     $C9:Write('PLAY');
     $CA:Write('DLOAD');
     $CB:Write('RENUM');
     $CC:Write('FN');
     $CD:Write('USING');
     $CE:Write('DIR');
     $CF:Write('DRIVE');
     $D0:Write('FIELD');
     $D1:Write('FILES');
     $D2:Write('KILL');
     $D3:Write('LOAD');
     $D4:Write('LSET');
     $D5:Write('MERGE');
     $D6:Write('RENAME');
     $D7:Write('RSET');
     $D8:Write('SAVE');
     $D9:Write('WRITE');
     $DA:Write('VERIFY');
     $DB:Write('UNLOAD');
     $DC:Write('DSKINI');
     $DD:Write('BACKUP');
     $DE:Write('COPY');
     $DF:Write('DSKI$');
     $E0:Write('DSKO$');
     $E3:Write('PALETTE');
     $E4:Write('HSCREEN');
     $E6:Write('HCLS');
     $E7:Write('HCOLOR');
     $E9:Write('HCIRCLE');
     $EA:Write('HLINE');
     $EB:Write('HGET');
     $EC:Write('HPUT');
     $ED:Write('HBUFF');
     $EE:Write('HPRINT');
     $F0:Write('BRK');
     $F1:Write('LOCATE');
     $F7:Write('RGB');
     $FF:Begin
      BlockRead(Source,Buffer,1,ByteReaded);
      Case Buffer[0]of
       $80:Write('SGN');
       $81:Write('INT');
       $82:Write('ABS');
       $83:Write('USR');
       $84:Write('RND');
       $85:Write('SIN');
       $86:Write('PEEK');
       $87:Write('LEN');
       $88:Write('STR$');
       $89:Write('VAL');
       $8A:Write('ASC');
       $8B:Write('CHR$');
       $8C:Write('EOF');
       $8D:Write('JOYSTK');
       $8E:Write('LEFT$');
       $8F:Write('RIGHT$');
       $90:Write('MID$');
       $91:Write('POINT');
       $92:Write('INKEY$');
       $93:Write('MEM');
       $94:Write('ATN');
       $95:Write('COS');
       $96:Write('TAN');
       $97:Write('EXP');
       $98:Write('FIX');
       $99:Write('LOG');
       $9A:Write('POS');
       $9B:Write('SQR');
       $9C:Write('HEX$');
       $9D:Write('VARPTR');
       $9E:Write('INSTR');
       $9F:Write('TIMER');
       $A0:Write('PPOINT');
       $A1:Write('STRING$');
       $A2:Write('CVN');
       $A3:Write('FREE');
       $A4:Write('LOC');
       $A5:Write('LOF');
       $A6:Write('MKN$');
       Else Write(Char(Buffer[0]));
      End;
     End;
     Else Write(Char(Buffer[0]));
    End;
    If B<>0Then NewLine:=False;
    LastB:=B;
   Until EOF(Source);
   Close(Source);
  End;
  CocoFileBAS:Begin
   BlockRead(Source,Buffer,1,ByteReaded);
   BlockRead(Source,Buffer,1,ByteReaded);
   BlockRead(Source,Buffer,1,ByteReaded);
   Pos:=Buffer[0]*256;
   BlockRead(Source,Buffer,1,ByteReaded);
   Pos:=Pos+Buffer[0];
   Write(Pos,' ');
   NewLine:=True;
   LastB:=0;
   Repeat
    BlockRead(Source,Buffer,1,ByteReaded);
    B:=Buffer[0];
RF1:
    Case B of
     0:Begin
      WriteLn;
      BlockRead(Source,Buffer,1,ByteReaded);
      BlockRead(Source,Buffer,1,ByteReaded);
      BlockRead(Source,Buffer,1,ByteReaded);
      Pos:=Buffer[0]*256;
      BlockRead(Source,Buffer,1,ByteReaded);
      Pos:=Pos+Buffer[0];
      Write(Pos,' ');
      NewLine:=True;
     End;
     $0E,$1C:Begin
      BlockRead(Source,Buffer,1,ByteReaded);
      Pos:=Buffer[0]*256;
      BlockRead(Source,Buffer,1,ByteReaded);
      Pos:=Pos+Buffer[0];
      Write(Pos,' ');
     End;
     $0F:Begin
      BlockRead(Source,Buffer,1,ByteReaded);
      Write(Buffer[0]);
     End;
     $11..$1A:Begin
      Write(Char(Buffer[0]+31));
     End;
     $3A:Begin
      BlockRead(Source,Buffer,1,ByteReaded);
      Case Buffer[0]of
       $C9: Write('''');
       $D1:Write('ELSE');
       Else Begin
        Write(':');
        LastB:=B;B:=Buffer[0];
        Goto RF1;
       End;
      End;
     End;
     $80:Write('TO');
     $81:Write('X81');
     $82:Write('*');
     $83:Write('AND');
     $84:If LastB<>$3AThen Write('=')
                      Else Write('FOR');
     $85:Write('X85');
     $86:Write('X86');
     $87:Write('PSET');
     $88:Write('X88');
     $89:Write('X89');
     $8A:Write('PLAY');
     $8B:Write('X8B');
     $8C:Write('X8C');
     $8D:Write('X8D');
     $8E:Write('X8E');
     $8F:Write('X8F');
     $90:Write('X90');
     $91:Write('X91');
     $92:Write('WIDTH');
     $93:Write('PALETTE');
     $94:Write('HSCREEN');
     $95:Write('BRK');
     $96:Write('X96');
     $97:Write('RGB');
     $98:Write('X98');
     $99:Write('X99');
     $9A:Write('X9A');
     $9B:Write('X9B');
     $9C:Write('X9C');
     $9D:Begin
      BlockRead(Source,Buffer,1,ByteReaded);
      Case Buffer[0]of
       $B0:Write('STRING$');
       $D1:Write('RND');
       $E3:Write('CHR$');
       $E4:Write('ASC');
       $E9:Write('LEFT$');
       $ED:Write('INKEY$');
       Else Write(Char(Buffer[0]));
      End;
     End;
     $9E:Write('X9E');
     $9F:Write('X9F');
     $A0:Write('XA0');
     $A1:Write('XA1');
     $A2:Write('XA2');
     $A3:Write('XA3');
     $A4:Write('XA4');
     $A5:Write('<');
     $A6:Write('XA6');
     $A7:Write('XA7');
     $A8:Write('-');
     $A9:Write('XA9');
     $AA:Write('LINE');
     $AB:Write('XAB');
     $AC:Write('XAC');
     $AD:Write('XAD');
     $AE:Write('XAE');
     $AF:Write('ATTR');
     $B0:Write('XB0');
     $B1:Write('OR');
     $B2:Write('XB2');
     $B3:Write('XB3');
     $B4:Write('+');
     $B5:Write('XB5');
     $B6:Write('SUB');
     $B7:Write('XB7');
     $B8:Write('XB8');
     $B9:Write('XB9');
     $BA:Write('XBA');
     $BB:Write('XBB');
     $BC:Write('XBC');
     $BD:Write('XBD');
     $BE:Write('>');
     $BF:Write('PCLEAR');
     $C0:Write('XC0');
     $C1:Write('HCOLOR');
     $C2:Write('XC2');
     $C3:Write('XC3');
     $C4:Write('FOR');
     $C5:Write('GO');
     $C6:Write('XC6');
     $C7:Write('REM');
     $C8:Write('HCIRCLE');
     $C9:Write('''');
     $CA:Write('HCLS');
     $CB:Write('HCIRCLE');
     $CC:Write('HBUFF');
     $CD:Write('HLINE');
     $CE:Write('HGET');
     $CF:Write('HPUT');
     $D0:Write('XD0');
     $D1:Write('ELSE');
     $D2:Write('LOCATE');
     $D3:Write('HPRINT');
     $D4:Write('XD4');
     $D5:Write('XD5');
     $D6:Write('IF');
     $D7:Write('XD7');
     $D8:Write('XD8');
     $D9:Write('XD9');
     $DA:Write('XDA');
     $DB:Write('XDB');
     $DC:Write('DATA');
     $DD:Write('SOUND');
     $DE:Write('XDE');
     $DF:Write('THEN');
     $E0:Write('ON');
     $E1:Write('PRINT');
     $E2:Write('INPUT');
     $E3:Write('NEXT');
     $E4:Write('XE4');
     $E5:Write('DIM');
     $E6:Write('PRESET');
     $E7:Write('READ');
     $E8:Write('XE8');
     $E9:Write('XE9');
     $EA:Write('RETURN');
     $EB:Write('XEB');
     $EC:Write('XEC');
     $ED:Write('POKE');
     $EE:Write('XEE');
     $EF:Write('XEF');
     $F0:Write('XF0');
     $F1:Write('XF1');
     $F2:Write('XF2');
     $F3:Write('XF3');
     $F4:Write('XF4');
     $F5:Write('XF5');
     $F6:Write('XF6');
     $F7:Write('XF7');
     $F8:Write('XF8');
     $F9:Write('XF9');
     $FA:Write('XFA');
     $FB:Write('CLS');
     $FC:Write('XFC');
     $FD:Write('XFD');
     $FE:Write('XFE');
     $FF:Write('XFF');
     Else Write(Char(Buffer[0]));
    End;
    If B<>0Then NewLine:=False;
    LastB:=B;
   Until EOF(Source);
   Close(Source);
  End;
  Else Write('Signature d''encodage non reconnu');
 End;
End;

Procedure TypeRaw(SourceName:String);
Var
 Handle:Text;
Begin
 Assign(Handle,SourceName);
 {$I-}Reset(Handle);{$I+}
 Err:=IOResult;
 If Err<>0Then Begin
  WriteLn('Nom du fichier : "',SourceName,'"');
  WriteLn(GetErrorMessage(Err));
  Halt;
 End;
 While NOT EOF(Handle)do Begin
  ReadLn(Handle,CurrLine);
  WriteLn(CurrLine);
 End;
 Close(Handle);
End;

BEGIN
 If ParamStr(1)='/?'Then Begin
  WriteLn('TYPE   Cette commande permet d''afficher le contenu d''un fichier');
  WriteLn;
  WriteLn('Syntaxe:');
  WriteLn;
  WriteLn('TYPE [/?] [fichier]');
  WriteLn;
  WriteLn('  /?     Ce parametre permet d''afficher l''aide sur cette commande');
  WriteLn('/GWBASIC Ce paramŠtre permet d''indiquer un format GWBASIC compress‚.');
  WriteLn('fichier  Ce parametre permet d''indiquer le nom du fichier a afficher');
  Exit;
 End
  Else
 If ParamStr(1)='--version'Then Begin
  WriteLn('TYPE 1.1 - Clone Pascal de corail, MS-DOS-0');
  WriteLn('Licence MIT');
  WriteLn;
  WriteLn('crit par Sylvain Maltais');
 End
  Else
 If ParamCount>0Then Begin
  Options:=[];
  For I:=1 to ParamCount do Begin
   If StrToUpper(ParamStr(I))='/GWBASIC'Then Include(Options,IsGWBASIC);
  End;
  For I:=1 to ParamCount do Begin
   CurrParam:=ParamStr(I);
   If StrToUpper(CurrParam)='/GWBASIC'Then Begin
   End
    Else
   If CurrParam<>''Then Begin
    If(IsWildCard(CurrParam))Then Begin
     FindFirst(CurrParam,AnyFile,Info);
     While DOSError=0 do Begin
      If(IsGWBASIC)in(Options)Then TypeBASIC(Info.Name)
                              Else TypeRAW(Info.Name);

      FindNext(Info);
     End;
    End
     Else
    Begin
     If(IsGWBASIC)in(Options)Then TypeBASIC(CurrParam)
                             Else TypeRAW(CurrParam);
    End;
   End;
  End;
 End;
END.
