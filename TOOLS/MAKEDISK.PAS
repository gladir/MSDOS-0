{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/msdos-0)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program MAKEDISK;

{ Cree une image disque amorcable de MSDOS-0 (disquette ou disque dur).

  MAKEDISK orchestre les commandes existantes :
    FORMAT.EXE   cree et formate le fichier d'image (FAT12 / FAT16),
    SYS.EXE      installe IO.SYS, MSDOS.SYS, COMMAND.COM et le secteur de
                 boot MS-DOS (et, pour un disque dur, le MBR et la partition
                 active),
    DISKPC.EXE   copie les commandes et autres fichiers dans l'image,
    UNDISKPC.EXE extrait le contenu de l'image (option /EXTRACT). }

{$M 16384,0,32768}

Uses DOS;

Const
 MaxAdd=16;

Var
 ImgName,FullImg,KernelDir,CmdDir,ToolDir,Masks,ExtractDir,StartDir:String;
 FSName,FormatPath,SysPath,DiskPcPath,UnDiskPcPath:String;
 AddList:Array[1..MaxAdd]of String;
 AddCount:Integer;
 FloppySize,HardMB:Word;
 IsHard,NoBuild,Verbose:Boolean;

Function UpStr(S:String):String;
Var
 I:Integer;
Begin
 For I:=1 to Length(S)do
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 UpStr:=S;
End;

Function StrToWord(S:String;Var V:Word):Boolean;
Var
 Code:Integer;
 L:LongInt;
Begin
 Val(S,L,Code);
 StrToWord:=(Code=0)and(L>=0)and(L<=65535);
 If Code=0 Then V:=Word(L);
End;

Function WithSlash(S:String):String;
Begin
 If(S<>'')and(S[Length(S)]<>'\')and(S[Length(S)]<>':')Then S:=S+'\';
 WithSlash:=S;
End;

Function FileFound(Const Name:String):Boolean;
Var
 SR:SearchRec;
Begin
 FindFirst(Name,AnyFile,SR);
 FileFound:=DosError=0;
End;

{ Cherche un outil : /TOOLS:dossier, dossier de MAKEDISK, dossier courant,
  puis PATH }
Function FindTool(Const Name:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
 P:String;
Begin
 FindTool:='';
 If ToolDir<>'' Then Begin
  P:=WithSlash(ToolDir)+Name;
  If FileFound(P)Then Begin FindTool:=FExpand(P);Exit;End;
 End;
 FSplit(FExpand(ParamStr(0)),D,N,E);
 P:=D+Name;
 If FileFound(P)Then Begin FindTool:=P;Exit;End;
 P:=FSearch(Name,'.;'+GetEnv('PATH'));
 If P<>'' Then FindTool:=FExpand(P);
End;

Function RunTool(Const Path,Args:String):Boolean;
Begin
 If Verbose Then WriteLn('> ',Path,' ',Args);
 SwapVectors;
 Exec(Path,Args);
 SwapVectors;
 RunTool:=(DosError=0)and(DosExitCode=0);
End;

Procedure Help;Begin
 WriteLn('MAKEDISK : Cette commande permet de creer une image disque ',
         'amorcable de MSDOS-0.');
 WriteLn;
 WriteLn('Syntaxe : MAKEDISK image.img [/FLOPPY[:taille]] [/HD[:Mo]] ',
         '[/FS:FAT12|FAT16]');
 WriteLn('                   [/KERNEL:dossier] [/CMDS:dossier] ',
         '[/MASK:masque,...]');
 WriteLn('                   [/ADD:fichier] [/TOOLS:dossier] ',
         '[/EXTRACT:dossier]');
 WriteLn('                   [/NOBUILD] [/V]');
 WriteLn;
 WriteLn(' image.img        Fichier d''image a creer (ecrase s''il existe).');
 WriteLn(' /FLOPPY[:taille] Disquette : 160, 180, 320, 360, 720, 1200, 1440 ',
         '(defaut)');
 WriteLn('                  ou 2880 Ko. Image brute de la taille de la ',
         'disquette.');
 WriteLn(' /HD[:Mo]         Image de disque dur (MBR + une partition ',
         'active, defaut');
 WriteLn('                  32 Mo, 1 a 1000 Mo), formatee en FAT16.');
 WriteLn(' /FS:systeme      Systeme de fichiers force (FAT12 ou FAT16).');
 WriteLn(' /KERNEL:dossier  Dossier contenant IO.SYS, MSDOS.SYS et ',
         'COMMAND.COM');
 WriteLn('                  (defaut : dossier courant).');
 WriteLn(' /CMDS:dossier    Dossier des commandes a copier dans la racine ',
         'de l''image.');
 WriteLn(' /MASK:masques    Masques des commandes, separes par des virgules ',
         '(defaut :');
 WriteLn('                  *.EXE,*.COM,*.BAT,*.SYS).');
 WriteLn(' /ADD:fichier     Ajoute un fichier ou un masque (repetable, ',
         '16 maximum).');
 WriteLn(' /TOOLS:dossier   Dossier de FORMAT.EXE, SYS.EXE, DISKPC.EXE et ',
         'UNDISKPC.EXE');
 WriteLn('                  (defaut : dossier de MAKEDISK, courant, PATH).');
 WriteLn(' /EXTRACT:dossier Extrait ensuite le contenu de l''image ',
         '(UNDISKPC).');
 WriteLn(' /NOBUILD         Ne cree pas l''image ; seulement /EXTRACT.');
 WriteLn(' /V               Affiche chaque commande lancee.');
 WriteLn;
 WriteLn('Exemples :');
 WriteLn('  MAKEDISK DOS144A.IMG /KERNEL:KERNEL /CMDS:BIN16');
 WriteLn('  MAKEDISK DISQUE.IMG /HD:64 /KERNEL:KERNEL /CMDS:BIN16');
End;

{ Analyse la ligne de commande ; retourne False en cas d'erreur }
Function ParseArgs:Boolean;
Var
 I:Integer;
 S,U:String;
Begin
 ParseArgs:=False;
 ImgName:='';KernelDir:='.';CmdDir:='';ToolDir:='';ExtractDir:='';
 Masks:='*.EXE,*.COM,*.BAT,*.SYS';FSName:='';
 AddCount:=0;FloppySize:=1440;HardMB:=32;
 IsHard:=False;NoBuild:=False;Verbose:=False;
 For I:=1 to ParamCount do Begin
  S:=ParamStr(I);
  U:=UpStr(S);
  If(U='/FLOPPY')Then IsHard:=False
  Else If Copy(U,1,8)='/FLOPPY:' Then Begin
   IsHard:=False;
   If Not StrToWord(Copy(U,9,255),FloppySize)Then Begin
    WriteLn('Taille de disquette invalide : ',Copy(S,9,255));Exit;
   End;
  End
  Else If U='/HD' Then IsHard:=True
  Else If Copy(U,1,4)='/HD:' Then Begin
   IsHard:=True;
   If(Not StrToWord(Copy(U,5,255),HardMB))or(HardMB<1)or(HardMB>1000)Then Begin
    WriteLn('Taille de disque dur invalide (1 a 1000 Mo) : ',Copy(S,5,255));
    Exit;
   End;
  End
  Else If Copy(U,1,4)='/FS:' Then FSName:=Copy(U,5,255)
  Else If Copy(U,1,8)='/KERNEL:' Then KernelDir:=Copy(S,9,255)
  Else If Copy(U,1,6)='/CMDS:' Then CmdDir:=Copy(S,7,255)
  Else If Copy(U,1,6)='/MASK:' Then Masks:=Copy(S,7,255)
  Else If Copy(U,1,5)='/ADD:' Then Begin
   If AddCount>=MaxAdd Then Begin
    WriteLn('Trop de parametres /ADD: (maximum ',MaxAdd,').');Exit;
   End;
   Inc(AddCount);
   AddList[AddCount]:=Copy(S,6,255);
  End
  Else If Copy(U,1,7)='/TOOLS:' Then ToolDir:=Copy(S,8,255)
  Else If Copy(U,1,9)='/EXTRACT:' Then ExtractDir:=Copy(S,10,255)
  Else If U='/NOBUILD' Then NoBuild:=True
  Else If U='/V' Then Verbose:=True
  Else If(S<>'')and(S[1]<>'/')and(ImgName='')Then ImgName:=S
  Else Begin
   WriteLn('Parametre inconnu : ',S);Exit;
  End;
 End;
 If ImgName='' Then Begin
  WriteLn('Nom du fichier image manquant.');Exit;
 End;
 If(FSName<>'')and(FSName<>'FAT12')and(FSName<>'FAT16')Then Begin
  WriteLn('Systeme de fichiers non pris en charge : ',FSName);Exit;
 End;
 If NoBuild and(ExtractDir='')Then Begin
  WriteLn('/NOBUILD n''a de sens qu''avec /EXTRACT:dossier.');Exit;
 End;
 ParseArgs:=True;
End;

{ Verifie que les outils et les fichiers du noyau sont presents }
Function CheckInputs:Boolean;
Const
 KFiles:Array[1..3]of String[11]=('IO.SYS','MSDOS.SYS','COMMAND.COM');
Var
 I:Integer;
 Ok:Boolean;
Begin
 Ok:=True;
 If Not NoBuild Then Begin
  FormatPath:=FindTool('FORMAT.EXE');
  SysPath:=FindTool('SYS.EXE');
  If FormatPath='' Then Begin WriteLn('FORMAT.EXE introuvable.');Ok:=False;End;
  If SysPath='' Then Begin WriteLn('SYS.EXE introuvable.');Ok:=False;End;
  For I:=1 to 3 do
   If Not FileFound(WithSlash(KernelDir)+KFiles[I])Then Begin
    WriteLn(KFiles[I],' introuvable dans ',KernelDir);Ok:=False;
   End;
  If(CmdDir<>'')or(AddCount>0)Then Begin
   DiskPcPath:=FindTool('DISKPC.EXE');
   If DiskPcPath='' Then Begin WriteLn('DISKPC.EXE introuvable.');Ok:=False;End;
  End;
 End;
 If ExtractDir<>'' Then Begin
  UnDiskPcPath:=FindTool('UNDISKPC.EXE');
  If UnDiskPcPath='' Then Begin
   WriteLn('UNDISKPC.EXE introuvable.');Ok:=False;
  End;
 End;
 CheckInputs:=Ok;
End;

Function NumStr(N:Word):String;
Var
 S:String;
Begin
 Str(N,S);
 NumStr:=S;
End;

{ Etape 1 : creation et formatage de l'image (sans /V : IO.SYS et MSDOS.SYS
  doivent rester les deux premieres entrees de la racine) }
Function StepFormat:Boolean;
Var
 F:File;
 Args:String;
 Err:Integer;
 Unit_:Word;
Begin
 StepFormat:=False;
 Assign(F,FullImg);
 {$I-}Erase(F);{$I+}
 Err:=IOResult;
 If IsHard Then Begin
  Args:=FullImg+' /CREATE:'+NumStr(HardMB);
  If FSName='' Then Args:=Args+' /FS:FAT16' Else Args:=Args+' /FS:'+FSName;
  { SYS ne traite que des FAT d'au plus 64 Ko : unite d'allocation assez
    grande pour rester sous 32000 unites }
  Unit_:=512;
  While(LongInt(HardMB)*2048 div(Unit_ div 512))>32000 do Unit_:=Unit_*2;
  If Unit_>512 Then Args:=Args+' /A:'+NumStr(Unit_);
 End
 Else Begin
  Args:=FullImg+' '+NumStr(FloppySize)+' /CREATE';
 End;
 WriteLn('== Formatage de ',ImgName);
 If Not RunTool(FormatPath,Args)Then Begin
  WriteLn('Echec de FORMAT.');Exit;
 End;
 StepFormat:=True;
End;

{ Etape 2 : transfert du systeme (SYS lit les fichiers dans le dossier
  courant) et secteur de boot ; MBR et partition active pour un disque dur }
Function StepSystem:Boolean;
Var
 Args:String;
 Ok:Boolean;
Begin
 StepSystem:=False;
 WriteLn('== Installation du systeme depuis ',KernelDir);
 {$I-}ChDir(KernelDir);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Dossier inaccessible : ',KernelDir);Exit;
 End;
 Args:='/IMG:'+FullImg;
 If IsHard Then Args:=Args+' /ACTIVE';
 Ok:=RunTool(SysPath,Args);
 ChDir(StartDir);
 If Not Ok Then Begin
  WriteLn('Echec de SYS.');Exit;
 End;
 StepSystem:=True;
End;

Procedure CopyMask(Const Mask:String);
Begin
 If Not RunTool(DiskPcPath,FullImg+' '+Mask)Then
  WriteLn('Avertissement : aucun fichier copie pour ',Mask);
End;

{ Etape 3 : commandes et fichiers supplementaires }
Procedure StepFiles;
Var
 I,P:Integer;
 M,List:String;
Begin
 If CmdDir<>'' Then Begin
  WriteLn('== Copie des commandes depuis ',CmdDir);
  List:=Masks;
  While List<>'' do Begin
   P:=Pos(',',List);
   If P=0 Then Begin M:=List;List:='';End
   Else Begin M:=Copy(List,1,P-1);List:=Copy(List,P+1,255);End;
   If M<>'' Then CopyMask(WithSlash(CmdDir)+M);
  End;
 End;
 If AddCount>0 Then WriteLn('== Copie des fichiers supplementaires');
 For I:=1 to AddCount do CopyMask(AddList[I]);
End;

Var
 Ok:Boolean;
 Err:Integer;
BEGIN
 If(ParamCount=0)or(ParamStr(1)='/?')or(ParamStr(1)='-h')or
   (ParamStr(1)='--help')Then Begin
  Help;
  Halt;
 End;
 If Not ParseArgs Then Halt(1);
 GetDir(0,StartDir);
 FullImg:=FExpand(ImgName);
 If ExtractDir<>'' Then ExtractDir:=FExpand(ExtractDir);
 If Not CheckInputs Then Halt(1);
 If Not NoBuild Then Begin
  If Not StepFormat Then Halt(1);
  If Not StepSystem Then Halt(1);
  StepFiles;
  WriteLn('Image creee : ',FullImg);
 End;
 If ExtractDir<>'' Then Begin
  WriteLn('== Extraction vers ',ExtractDir);
  {$I-}MkDir(ExtractDir);{$I+}
  Err:=IOResult;
  Ok:=RunTool(UnDiskPcPath,FullImg+' '+ExtractDir);
  If Not Ok Then Begin
   WriteLn('Echec de UNDISKPC.');Halt(1);
  End;
 End;
END.
