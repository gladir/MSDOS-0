{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2021
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Free Pascal, Turbo Pascal)
}

Program MORE(Input,Output);

Uses Crt,DOS;

Var
 I:Byte;
 S:String;
 FileRead:Text;
 Regs:Registers;

BEGIN
 If ParamStr(1)='/?'Then Begin
  WriteLn('MORE : Cette commande permet de recevoir l''entree puis ',
          'l''affiche sur un peripherique de sortie un ecran a la fois.');
  WriteLn;
  WriteLn('Syntaxe : MORE source');
 End
  Else
 If ParamCount>0Then Begin
  Assign(FileRead,ParamStr(1));
  Reset(FileRead);
  I:=0;
  While Not(EOF(FileRead))do Begin
   Inc(I);
   ReadLn(FileRead,S);
   WriteLn(S);
   If I=Hi(WindMax)Then Begin
    WriteLn(Output,'Presse une touche pour continuer...');
    ReadKey;
    I:=0;
   End;
  End;
  Close(FileRead);
 End
  Else
 Begin
  I:=0;
  Repeat
   Inc(I);
   ReadLn(Input,S);
   WriteLn(Output,S);
   If I=Hi(WindMax)Then Begin
    WriteLn(Output,'Presse une touche pour continuer...');
    Regs.AH := $0C;
    Regs.AL := $07;
    MsDos(Regs);
    I:=0;
   End;
  Until Eof;
 End;
END.
