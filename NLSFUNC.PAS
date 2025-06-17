{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program NLSFUNC;

Uses DOS;

Const
 NLS_SIGNATURE=$534C4E;  { 'NLS' }
 DEFAULT_COUNTRY=001;    { êtats-Unis }
 MAX_TABLE_SIZE=16384;

Type
 TNLSHeader=Record
  Signature:LongInt;
  Version:Word;
  CodePage:Word;
  Country:Word;
  TableSize:Word;
  Reserved:Array[1..8] of Byte;
 End;

Var
 NLSFile:File;
 NLSHeader:TNLSHeader;
 TableData:Array[0..MAX_TABLE_SIZE-1] of Byte;
 ErrorLevel:Integer;

Function LoadNLSFile(Const FileName:String):Boolean;
Var
 BytesRead:Word;
Begin
 LoadNLSFile:=False;
 {$I-}Assign(NLSFile, FileName);
 Reset(NLSFile, 1);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Erreur: Impossible d''ouvrir le fichier NLS');
  Exit;
 End;
 BlockRead(NLSFile,NLSHeader,SizeOf(NLSHeader),BytesRead);
 If(BytesRead <> SizeOf(NLSHeader))or(NLSHeader.Signature<>NLS_SIGNATURE)Then Begin
  WriteLn('Error: Invalid NLS file format');
  Close(NLSFile);
  Exit;
 End;
 If NLSHeader.TableSize>MAX_TABLE_SIZE Then Begin
  WriteLn('Erreur: Table NLS trop grande');
  Close(NLSFile);
  Exit;
 End;
 BlockRead(NLSFile,TableData,NLSHeader.TableSize,BytesRead);
 Close(NLSFile);
 If BytesRead<>NLSHeader.TableSize Then Begin
  WriteLn('Erreur: Fichier NLS incomplet');
  Exit;
 End;
 LoadNLSFile:= True;
End;

Procedure InstallNLSHandlers;
Var
 Regs:Registers;
Begin
 Regs.AH:=$14;  { DOS - Fixe la fonction de dÇpendances de pays }
 Regs.AL:=$00;  { Installe le gestionnaire }
 Regs.DX:=DEFAULT_COUNTRY;
 Intr($21,Regs);
 If Regs.Flags and FCarry<>0 Then
  WriteLn('Attention: Ne peut pas installer le gestionnaire NLS.')
 Else
  WriteLn('Gestionnaire NLS installÇ avec succäs.');
End;

Procedure UninstallNLSHandlers;
Var
 Regs:Registers;
Begin
 Regs.AH:=$14;
 Regs.AL:=$FF;  { DÇsinstalle le gestionnaire }
 Intr($21,Regs);
 WriteLn('Gestionnaire NLS dÇinstallÇs.');
End;

Var
 i:Integer;
 Param:String;
 FileName:String;
 Install:Boolean;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('NLSFUNC : Cette commande permet d''effectuer la gestion du pays ',
                    'et des conventions internationales du systäme d''exploitation.');
  WriteLn;
  WriteLn('Syntaxe : NLSFUNC [/C[+|-]] [/F filename]');
  WriteLn;
  WriteLn(' /C    Charge ou dÇcharge la table de caractäres');
  WriteLn(' /F    Fichier NLS spÇcifique Ö charger.');
  Halt;
 End;
 ErrorLevel:=0;
 Install:=True;
 FileName:='';
 For i:=1 to ParamCount do Begin
  Param:=ParamStr(i);
  If(Param[1] = '/')or(Param[1] = '-')Then Begin
   Case UpCase(Param[2]) of
    'C':Install:=(Length(Param)<4)or(Param[3]='+');
    'F':If i<ParamCount Then FileName:=ParamStr(i+1);
                        Else WriteLn('Paramätre invalide : ', Param);
    ErrorLevel := 1;
    Exit;
   End;
  End;
 End;
 If(Install)Then Begin
  If FileName=''Then FileName:='COUNTRY.NLS';
  If LoadNLSFile(FileName)Then InstallNLSHandlers
                          Else ErrorLevel:=2;
 End
  Else
 UninstallNLSHandlers;
 Halt(ErrorLevel);
END.