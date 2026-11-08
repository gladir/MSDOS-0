{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/msdos-0)
  @abstract(Target: Turbo Pascal 7, Free Pascal)
}

Program MAKEDISK;

{ Cree des images disque amorcables de MSDOS-0 : disquette(s), disque dur ou
  CD-ROM (.ISO).

  MAKEDISK orchestre les commandes existantes :
    FORMAT.EXE   cree et formate le fichier d'image (FAT12 / FAT16),
    SYS.EXE      installe IO.SYS, MSDOS.SYS, COMMAND.COM et le secteur de
                 boot MS-DOS (et, pour un disque dur, le MBR et la partition
                 active),
    DISKPC.EXE   copie les commandes et autres fichiers dans l'image,
    UNDISKPC.EXE extrait le contenu de l'image (option /EXTRACT).

  Quand les fichiers ne tiennent pas sur une disquette, ils sont repartis sur
  plusieurs disquettes : DOS144A.IMG (amorcable, avec le systeme),
  DOS144B.IMG, DOS144C.IMG...

  L'option /ISO produit une image CD-ROM ISO 9660 amorcable (El Torito, avec
  emulation de disquette : la premiere disquette sert d'image de boot) qui
  contient tous les fichiers. L'ISO est ecrite directement par MAKEDISK. }

{$M 16384,0,65536}

Uses DOS;

Const
 MaxAdd=16;
 MaxFiles=200;
 MaxDisks=26;
 IsoSec=2048;

Type
 TFileRec=Record
  Path:String[100];
  Name:String[12];
  Size:LongInt;
  Disk:Integer;  { >=0 disquette, -1 noyau, -2 image, -3 a placer, -4 ignore }
  LBA:LongInt;
 End;
 TBuf=Array[0..65519]of Byte;
 PBuf=^TBuf;
 TSec=Array[0..IsoSec-1]of Byte;

Var
 ImgName,FullImg,KernelDir,CmdDir,ToolDir,Masks,ExtractDir,StartDir:String;
 FSName,FormatPath,SysPath,DiskPcPath,UnDiskPcPath,IsoName,VolLabel:String;
 AddList:Array[1..MaxAdd]of String;
 AddCount:Integer;
 Files:Array[1..MaxFiles+8]of TFileRec;
 FileCount:Integer;
 FloppySize,HardMB:Word;
 IsHard,NoBuild,Verbose:Boolean;
 DiskCount:Integer;
 Sec:TSec;
 DirBuf:PBuf;
 Yr,Mo,Dy,Dw,Hr,Mi,Sc,Hs:Word;

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

Function NumStr(N:LongInt):String;
Var
 S:String;
Begin
 Str(N,S);
 NumStr:=S;
End;

Function ZeroPad(N:Word;Len:Integer):String;
Var
 S:String;
Begin
 S:=NumStr(N);
 While Length(S)<Len do S:='0'+S;
 ZeroPad:=S;
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
 {$IFDEF FPC}
 FindClose(SR);
 {$ENDIF}
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
 WriteLn('MAKEDISK : Cette commande permet de creer des images disque ',
         'amorcables de MSDOS-0.');
 WriteLn;
 WriteLn('Syntaxe : MAKEDISK image.img [/FLOPPY[:taille]] [/HD[:Mo]] ',
         '[/FS:FAT12|FAT16]');
 WriteLn('                   [/KERNEL:dossier] [/CMDS:dossier] ',
         '[/MASK:masque,...]');
 WriteLn('                   [/ADD:fichier] [/TOOLS:dossier] ',
         '[/EXTRACT:dossier]');
 WriteLn('                   [/ISO:fichier.iso] [/LABEL:nom] [/NOBUILD] [/V]');
 WriteLn;
 WriteLn(' image.img        Fichier d''image a creer (ecrase s''il existe).');
 WriteLn(' /FLOPPY[:taille] Disquette : 160, 180, 320, 360, 720, 1200, 1440 ',
         '(defaut)');
 WriteLn('                  ou 2880 Ko. Si les fichiers ne tiennent pas sur ',
         'une');
 WriteLn('                  disquette, ils sont repartis sur plusieurs : ',
         'DOS144A.IMG');
 WriteLn('                  (amorcable), DOS144B.IMG, DOS144C.IMG...');
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
 WriteLn(' /ISO:fichier     Cree aussi une image CD-ROM ISO 9660 amorcable ',
         '(El Torito)');
 WriteLn('                  contenant tous les fichiers ; la premiere ',
         'disquette sert');
 WriteLn('                  d''image de boot (disquette 1200, 1440 ou 2880 ',
         'Ko).');
 WriteLn(' /LABEL:nom       Nom de volume du CD-ROM (defaut : MSDOS0).');
 WriteLn(' /EXTRACT:dossier Extrait ensuite le contenu des disquettes ',
         '(UNDISKPC).');
 WriteLn(' /NOBUILD         Ne cree pas d''image ; seulement /EXTRACT.');
 WriteLn(' /V               Affiche chaque commande lancee.');
 WriteLn;
 WriteLn('Exemples :');
 WriteLn('  MAKEDISK DOS144A.IMG /KERNEL:KERNEL /CMDS:BIN16');
 WriteLn('  MAKEDISK DOS144A.IMG /KERNEL:KERNEL /CMDS:BIN16 ',
         '/ISO:DOSCD.ISO');
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
 Masks:='*.EXE,*.COM,*.BAT,*.SYS';FSName:='';IsoName:='';VolLabel:='MSDOS0';
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
  Else If Copy(U,1,5)='/ISO:' Then IsoName:=Copy(S,6,255)
  Else If Copy(U,1,7)='/LABEL:' Then VolLabel:=UpStr(Copy(S,8,255))
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
 If NoBuild and(IsoName<>'')Then Begin
  WriteLn('/ISO est incompatible avec /NOBUILD.');Exit;
 End;
 If(IsoName<>'')and IsHard Then Begin
  WriteLn('/ISO exige une image de disquette (amorce El Torito).');Exit;
 End;
 If(IsoName<>'')and(FloppySize<>1200)and(FloppySize<>1440)and
   (FloppySize<>2880)Then Begin
  WriteLn('/ISO exige une disquette de 1200, 1440 ou 2880 Ko.');Exit;
 End;
 ParseArgs:=True;
End;

{ Geometrie FAT d'une disquette (identique a FORMAT) }
Function FloppyGeom(KB:Word;Var Total,Spc,Root,Spf:Word):Boolean;
Begin
 FloppyGeom:=True;
 Case KB of
  160:Begin Total:=320;Spc:=1;Root:=64;Spf:=1;End;
  180:Begin Total:=360;Spc:=1;Root:=64;Spf:=2;End;
  320:Begin Total:=640;Spc:=2;Root:=112;Spf:=1;End;
  360:Begin Total:=720;Spc:=2;Root:=112;Spf:=2;End;
  720:Begin Total:=1440;Spc:=2;Root:=112;Spf:=3;End;
  1200:Begin Total:=2400;Spc:=1;Root:=224;Spf:=7;End;
  1440:Begin Total:=2880;Spc:=1;Root:=224;Spf:=9;End;
  2880:Begin Total:=5760;Spc:=2;Root:=240;Spf:=9;End;
 Else
  FloppyGeom:=False;
 End;
End;

{ Verifie que les outils et les fichiers du noyau sont presents }
Function CheckInputs:Boolean;
Const
 KFiles:Array[1..3]of String[11]=('IO.SYS','MSDOS.SYS','COMMAND.COM');
Var
 I:Integer;
 Ok:Boolean;
 T1,T2,T3,T4:Word;
Begin
 Ok:=True;
 If Not NoBuild Then Begin
  If(Not IsHard)and(Not FloppyGeom(FloppySize,T1,T2,T3,T4))Then Begin
   WriteLn('Taille de disquette non prise en charge : ',FloppySize);
   Ok:=False;
  End;
  FormatPath:=FindTool('FORMAT.EXE');
  SysPath:=FindTool('SYS.EXE');
  DiskPcPath:=FindTool('DISKPC.EXE');
  If FormatPath='' Then Begin WriteLn('FORMAT.EXE introuvable.');Ok:=False;End;
  If SysPath='' Then Begin WriteLn('SYS.EXE introuvable.');Ok:=False;End;
  If DiskPcPath='' Then Begin WriteLn('DISKPC.EXE introuvable.');Ok:=False;End;
  For I:=1 to 3 do
   If Not FileFound(WithSlash(KernelDir)+KFiles[I])Then Begin
    WriteLn(KFiles[I],' introuvable dans ',KernelDir);Ok:=False;
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

{ ---- Liste des fichiers ---- }

Function NameKnown(Const Nm:String):Boolean;
Var
 I:Integer;
Begin
 NameKnown:=False;
 For I:=1 to FileCount do
  If Files[I].Name=Nm Then NameKnown:=True;
End;

Procedure AddFile(Const Path,Nm:String;Size:LongInt;Disk:Integer);
Begin
 If NameKnown(Nm)Then Exit;
 If FileCount>=MaxFiles+8 Then Begin
  WriteLn('Trop de fichiers (maximum ',MaxFiles,') : ',Nm,' ignore.');
  Exit;
 End;
 Inc(FileCount);
 Files[FileCount].Path:=Path;
 Files[FileCount].Name:=Nm;
 Files[FileCount].Size:=Size;
 Files[FileCount].Disk:=Disk;
 Files[FileCount].LBA:=0;
End;

{ Ajoute les fichiers correspondant au masque (Disk = etat initial) ;
  retourne le nombre de fichiers trouves }
Function ScanMask(Const Spec:String;Disk:Integer):Integer;
Var
 SR:SearchRec;
 D:DirStr;
 N:NameStr;
 E:ExtStr;
 Cnt:Integer;
Begin
 Cnt:=0;
 FSplit(Spec,D,N,E);
 FindFirst(Spec,AnyFile,SR);
 While DosError=0 do Begin
  If(SR.Attr and(Directory or VolumeID))=0 Then Begin
   AddFile(D+SR.Name,SR.Name,SR.Size,Disk);
   Inc(Cnt);
  End;
  FindNext(SR);
 End;
 {$IFDEF FPC}
 FindClose(SR);
 {$ENDIF}
 ScanMask:=Cnt;
End;

Procedure BuildList;
Const
 KFiles:Array[1..3]of String[11]=('IO.SYS','MSDOS.SYS','COMMAND.COM');
Var
 I,P,Cnt:Integer;
 M,List:String;
Begin
 FileCount:=0;
 For I:=1 to 3 do
  Cnt:=ScanMask(WithSlash(KernelDir)+KFiles[I],-1);
 If CmdDir<>'' Then Begin
  List:=Masks;
  While List<>'' do Begin
   P:=Pos(',',List);
   If P=0 Then Begin M:=List;List:='';End
   Else Begin M:=Copy(List,1,P-1);List:=Copy(List,P+1,255);End;
   If M<>'' Then Cnt:=ScanMask(WithSlash(CmdDir)+M,-3);
  End;
 End;
 For I:=1 to AddCount do
  If ScanMask(AddList[I],-3)=0 Then
   WriteLn('Avertissement : aucun fichier pour ',AddList[I]);
End;

{ Nombre maximal de disquettes pour le nom demande (la lettre finale est
  incrementee : DOS144A -> DOS144B, jusqu'a Z) }
Function DiskLimit:Integer;
Var
 D:DirStr;
 Nm:NameStr;
 E:ExtStr;
 C:Char;
Begin
 DiskLimit:=MaxDisks;
 FSplit(FullImg,D,Nm,E);
 C:=#0;
 If Nm<>'' Then C:=UpCase(Nm[Length(Nm)]);
 If(C>='A')and(C<='Z')Then DiskLimit:=Ord('Z')-Ord(C)+1;
End;

{ Nom du fichier image de la disquette N (0 = image demandee ; ensuite la
  lettre finale est incrementee, sinon une lettre est ajoutee au nom) }
Function DiskName(N:Integer):String;
Var
 D:DirStr;
 Nm:NameStr;
 E:ExtStr;
 C:Char;
Begin
 If N=0 Then Begin DiskName:=FullImg;Exit;End;
 FSplit(FullImg,D,Nm,E);
 C:=#0;
 If Nm<>'' Then C:=UpCase(Nm[Length(Nm)]);
 If(C>='A')and(C<='Z')Then Nm[Length(Nm)]:=Chr(Ord(C)+N)
 Else Nm:=Nm+Chr(65+N);
 DiskName:=D+Nm+E;
End;

{ Repartit les fichiers sur les disquettes (premier ajustement) ; la
  disquette 0 contient deja les fichiers du noyau }
Procedure Pack;
Var
 Total,Spc,Root,Spf:Word;
 CB,DataCl,I,D:Integer;
 FreeCl,FreeEnt:Array[0..MaxDisks-1]of LongInt;
 Need:LongInt;
 Placed:Boolean;
Begin
 DiskCount:=1;
 If IsHard Then Begin
  For I:=1 to FileCount do
   If Files[I].Disk=-3 Then Files[I].Disk:=0;
  Exit;
 End;
 If Not FloppyGeom(FloppySize,Total,Spc,Root,Spf)Then Halt(1);
 CB:=Spc*512;
 DataCl:=(Total-1-2*Spf-(Root*32+511)div 512)div Spc;
 FreeCl[0]:=DataCl;FreeEnt[0]:=Root;
 For I:=1 to FileCount do
  If Files[I].Disk=-1 Then Begin
   FreeCl[0]:=FreeCl[0]-(Files[I].Size+CB-1)div CB;
   FreeEnt[0]:=FreeEnt[0]-1;
  End;
 For I:=1 to FileCount do
  If Files[I].Disk=-3 Then Begin
   Need:=(Files[I].Size+CB-1)div CB;
   If Need>DataCl Then Begin
    WriteLn('Avertissement : ',Files[I].Name,' est trop gros pour une ',
            'disquette de ',FloppySize,' Ko, ignore.');
    Files[I].Disk:=-4;
   End
   Else Begin
    Placed:=False;
    For D:=0 to DiskCount-1 do
     If(Not Placed)and(FreeCl[D]>=Need)and(FreeEnt[D]>=1)Then Begin
      FreeCl[D]:=FreeCl[D]-Need;FreeEnt[D]:=FreeEnt[D]-1;
      Files[I].Disk:=D;Placed:=True;
     End;
    If Not Placed Then Begin
     If DiskCount>=DiskLimit Then Begin
      WriteLn('Trop de disquettes (maximum ',DiskLimit,').');Halt(1);
     End;
     FreeCl[DiskCount]:=DataCl-Need;FreeEnt[DiskCount]:=Root-1;
     Files[I].Disk:=DiskCount;
     Inc(DiskCount);
    End;
   End;
  End;
End;

{ Creation et formatage de l'image N (sans /V : IO.SYS et MSDOS.SYS doivent
  rester les deux premieres entrees de la racine) }
Function StepFormat(N:Integer):Boolean;
Var
 F:File;
 Args,Img:String;
 Err:Integer;
 Unit_:Word;
Begin
 StepFormat:=False;
 Img:=DiskName(N);
 Assign(F,Img);
 {$I-}Erase(F);{$I+}
 Err:=IOResult;
 If IsHard Then Begin
  Args:=Img+' /CREATE:'+NumStr(HardMB);
  If FSName='' Then Args:=Args+' /FS:FAT16' Else Args:=Args+' /FS:'+FSName;
  { SYS ne traite que des FAT d'au plus 64 Ko : unite d'allocation assez
    grande pour rester sous 32000 unites }
  Unit_:=512;
  While(LongInt(HardMB)*2048 div(Unit_ div 512))>32000 do Unit_:=Unit_*2;
  If Unit_>512 Then Args:=Args+' /A:'+NumStr(Unit_);
 End
 Else Begin
  Args:=Img+' '+NumStr(FloppySize)+' /CREATE';
 End;
 WriteLn('== Formatage de ',Img);
 If Not RunTool(FormatPath,Args)Then Begin
  WriteLn('Echec de FORMAT.');Exit;
 End;
 StepFormat:=True;
End;

{ Transfert du systeme sur l'image 0 (SYS lit les fichiers dans le dossier
  courant) et secteur de boot ; MBR et partition active pour un disque dur }
Function StepSystem:Boolean;
Var
 Args:String;
 Ok:Boolean;
 Err:Integer;
Begin
 StepSystem:=False;
 WriteLn('== Installation du systeme depuis ',KernelDir);
 {$I-}ChDir(KernelDir);{$I+}
 Err:=IOResult;
 If Err<>0 Then Begin
  WriteLn('Dossier inaccessible : ',KernelDir);Exit;
 End;
 Args:='/IMG:'+DiskName(0);
 If IsHard Then Args:=Args+' /ACTIVE';
 Ok:=RunTool(SysPath,Args);
 ChDir(StartDir);
 If Not Ok Then Begin
  WriteLn('Echec de SYS.');Exit;
 End;
 StepSystem:=True;
End;

{ Copie dans l'image N les fichiers qui lui sont affectes }
Procedure StepFiles(N:Integer);
Var
 I,Cnt:Integer;
Begin
 Cnt:=0;
 For I:=1 to FileCount do
  If Files[I].Disk=N Then Inc(Cnt);
 If Cnt=0 Then Exit;
 WriteLn('== Copie de ',Cnt,' fichier(s) dans ',DiskName(N));
 For I:=1 to FileCount do
  If Files[I].Disk=N Then
   If Not RunTool(DiskPcPath,DiskName(N)+' '+Files[I].Path)Then
    WriteLn('Avertissement : copie de ',Files[I].Path,' echouee.');
End;

{ ---- Image CD-ROM ISO 9660 + El Torito ---- }

Procedure PutLE32(B:PBuf;Ofs:Word;V:LongInt);
Var
 Lo,Hi:Word;
Begin
 Lo:=Word(V and $FFFF);Hi:=Word(V shr 16);
 B^[Ofs]:=Byte(Lo and $FF);B^[Ofs+1]:=Byte(Lo shr 8);
 B^[Ofs+2]:=Byte(Hi and $FF);B^[Ofs+3]:=Byte(Hi shr 8);
End;

Procedure PutBE32(B:PBuf;Ofs:Word;V:LongInt);
Var
 Lo,Hi:Word;
Begin
 Lo:=Word(V and $FFFF);Hi:=Word(V shr 16);
 B^[Ofs]:=Byte(Hi shr 8);B^[Ofs+1]:=Byte(Hi and $FF);
 B^[Ofs+2]:=Byte(Lo shr 8);B^[Ofs+3]:=Byte(Lo and $FF);
End;

Procedure PutBoth32(B:PBuf;Ofs:Word;V:LongInt);Begin
 PutLE32(B,Ofs,V);PutBE32(B,Ofs+4,V);
End;

Procedure PutBoth16(B:PBuf;Ofs:Word;V:Word);Begin
 B^[Ofs]:=Byte(V and $FF);B^[Ofs+1]:=Byte(V shr 8);
 B^[Ofs+2]:=Byte(V shr 8);B^[Ofs+3]:=Byte(V and $FF);
End;

Procedure PutText(B:PBuf;Ofs:Word;Const S:String;Len:Word);
Var
 I:Word;
Begin
 For I:=0 to Len-1 do
  If I<Length(S)Then B^[Ofs+I]:=Ord(S[I+1])Else B^[Ofs+I]:=32;
End;

{ Longueur d'un enregistrement de repertoire pour un identifiant donne }
Function RecLen(Const Id:String):Word;
Var
 Len:Word;
Begin
 Len:=33+Length(Id);
 If Len and 1<>0 Then Inc(Len);
 RecLen:=Len;
End;

{ Enregistrement de repertoire ISO 9660 ; retourne sa longueur }
Function PutDirRec(B:PBuf;Ofs:Word;Extent,Size:LongInt;Flags:Byte;
                   Const Id:String):Word;
Var
 Len,I:Word;
Begin
 Len:=RecLen(Id);
 For I:=0 to Len-1 do B^[Ofs+I]:=0;
 B^[Ofs]:=Byte(Len);
 PutBoth32(B,Ofs+2,Extent);
 PutBoth32(B,Ofs+10,Size);
 B^[Ofs+18]:=Byte(Yr-1900);B^[Ofs+19]:=Byte(Mo);B^[Ofs+20]:=Byte(Dy);
 B^[Ofs+21]:=Byte(Hr);B^[Ofs+22]:=Byte(Mi);B^[Ofs+23]:=Byte(Sc);
 B^[Ofs+25]:=Flags;
 PutBoth16(B,Ofs+28,1);
 B^[Ofs+32]:=Length(Id);
 For I:=1 to Length(Id)do B^[Ofs+32+I]:=Ord(Id[I]);
 PutDirRec:=Len;
End;

{ Identifiant ISO 9660 niveau 1 : NOM.EXT;1 }
Function IsoId(Const Nm:String):String;
Var
 S:String;
 I:Integer;
Begin
 S:=UpStr(Nm);
 For I:=1 to Length(S)do
  If Not(S[I] in['A'..'Z','0'..'9','_','.'])Then S[I]:='_';
 If Pos('.',S)=0 Then S:=S+'.';
 IsoId:=S+';1';
End;

{ Cle de tri : nom (8) puis extension (3) }
Function SortKey(Const Id:String):String;
Var
 P:Integer;
 N,E:String;
Begin
 P:=Pos('.',Id);
 N:=Copy(Id,1,P-1);
 E:=Copy(Id,P+1,Pos(';',Id)-P-1);
 While Length(N)<8 do N:=N+' ';
 While Length(E)<3 do E:=E+' ';
 SortKey:=N+E;
End;

Procedure PutDate(B:PBuf;Ofs:Word);
Var
 S:String;
 I:Integer;
Begin
 S:=ZeroPad(Yr,4)+ZeroPad(Mo,2)+ZeroPad(Dy,2)+ZeroPad(Hr,2)+ZeroPad(Mi,2)+
    ZeroPad(Sc,2)+'00';
 For I:=1 to 16 do B^[Ofs+I-1]:=Ord(S[I]);
 B^[Ofs+16]:=0;
End;

Procedure WriteSec(Var F:File);
Var
 W:Word;
Begin
 BlockWrite(F,Sec,IsoSec,W);
End;

Function BuildISO:Boolean;
Var
 F,G:File;
 Order:Array[1..MaxFiles+8]of Integer;
 Cnt,I,J,T,BootIdx:Integer;
 DirBytes,Pos2,Sum,Pad,Done:LongInt;
 DirSectors,CatLBA,Next,Total:LongInt;
 Len:Word;
 Buf,SB:PBuf;
 Got,W:Word;
 Media:Byte;
 D:DirStr;
 Nm:NameStr;
 E:ExtStr;
Begin
 BuildISO:=False;
 GetDate(Yr,Mo,Dy,Dw);GetTime(Hr,Mi,Sc,Hs);
 { image de boot = disquette 0 }
 BootIdx:=FileCount+1;
 FSplit(DiskName(0),D,Nm,E);
 AddFile(DiskName(0),Nm+E,0,-2);
 If FileCount<>BootIdx Then Begin
  WriteLn('Nom d''image de boot deja utilise dans le CD-ROM : ',Nm+E);Exit;
 End;
 Assign(G,DiskName(0));
 {$I-}Reset(G,1);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Image de boot introuvable : ',DiskName(0));Exit;
 End;
 Files[BootIdx].Size:=FileSize(G);
 Close(G);
 { ordre des fichiers dans le repertoire racine }
 Cnt:=0;
 For I:=1 to FileCount do
  If Files[I].Disk<>-4 Then Begin
   Inc(Cnt);Order[Cnt]:=I;
  End;
 For I:=2 to Cnt do Begin
  T:=Order[I];J:=I-1;
  While(J>=1)and(SortKey(IsoId(Files[Order[J]].Name))>
        SortKey(IsoId(Files[T].Name)))do Begin
   Order[J+1]:=Order[J];Dec(J);
  End;
  Order[J+1]:=T;
 End;
 { taille du repertoire racine ('.' et '..' : 34 octets chacun) }
 Pos2:=68;
 For I:=1 to Cnt do Begin
  Len:=RecLen(IsoId(Files[Order[I]].Name));
  If(Pos2 mod IsoSec)+Len>IsoSec Then Pos2:=(Pos2 div IsoSec+1)*IsoSec;
  Pos2:=Pos2+Len;
 End;
 DirSectors:=(Pos2+IsoSec-1)div IsoSec;
 DirBytes:=DirSectors*IsoSec;
 If DirBytes>65000 Then Begin
  WriteLn('Repertoire racine ISO trop grand.');Exit;
 End;
 CatLBA:=21+DirSectors;
 Next:=CatLBA+1;
 For I:=1 to Cnt do Begin
  Files[Order[I]].LBA:=Next;
  Next:=Next+(Files[Order[I]].Size+IsoSec-1)div IsoSec;
 End;
 Total:=Next;
 GetMem(DirBuf,Word(DirBytes));
 FillChar(DirBuf^,Word(DirBytes),0);
 Pos2:=0;
 Pos2:=Pos2+PutDirRec(DirBuf,0,21,DirBytes,2,#0);
 Pos2:=Pos2+PutDirRec(DirBuf,Word(Pos2),21,DirBytes,2,#1);
 For I:=1 to Cnt do Begin
  Len:=RecLen(IsoId(Files[Order[I]].Name));
  If(Pos2 mod IsoSec)+Len>IsoSec Then Pos2:=(Pos2 div IsoSec+1)*IsoSec;
  Pos2:=Pos2+PutDirRec(DirBuf,Word(Pos2),Files[Order[I]].LBA,
                       Files[Order[I]].Size,0,IsoId(Files[Order[I]].Name));
 End;
 SB:=PBuf(@Sec);
 Assign(F,IsoName);
 {$I-}Rewrite(F,1);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Creation impossible : ',IsoName);
  FreeMem(DirBuf,Word(DirBytes));Exit;
 End;
 { secteurs 0..15 : zone systeme }
 FillChar(Sec,IsoSec,0);
 For I:=0 to 15 do WriteSec(F);
 { 16 : descripteur de volume primaire }
 FillChar(Sec,IsoSec,0);
 Sec[0]:=1;PutText(SB,1,'CD001',5);Sec[6]:=1;
 PutText(SB,8,'MSDOS-0',32);
 PutText(SB,40,VolLabel,32);
 PutBoth32(SB,80,Total);
 PutBoth16(SB,120,1);PutBoth16(SB,124,1);PutBoth16(SB,128,IsoSec);
 PutBoth32(SB,132,10);
 PutLE32(SB,140,19);PutBE32(SB,148,20);
 Len:=PutDirRec(SB,156,21,DirBytes,2,#0);
 PutText(SB,190,'',128);PutText(SB,318,'',128);PutText(SB,446,'',128);
 PutText(SB,574,'MAKEDISK MSDOS-0',128);
 PutText(SB,702,'',37);PutText(SB,739,'',37);PutText(SB,776,'',37);
 PutDate(SB,813);PutDate(SB,830);
 For I:=0 to 15 do Sec[847+I]:=Ord('0');
 For I:=0 to 15 do Sec[864+I]:=Ord('0');
 Sec[881]:=1;
 WriteSec(F);
 { 17 : enregistrement de boot El Torito }
 FillChar(Sec,IsoSec,0);
 PutText(SB,1,'CD001',5);Sec[6]:=1;
 PutText(SB,7,'EL TORITO SPECIFICATION',23);
 PutLE32(SB,71,CatLBA);
 WriteSec(F);
 { 18 : fin des descripteurs }
 FillChar(Sec,IsoSec,0);
 Sec[0]:=255;PutText(SB,1,'CD001',5);Sec[6]:=1;
 WriteSec(F);
 { 19, 20 : tables de chemins (racine seule) }
 FillChar(Sec,IsoSec,0);
 Sec[0]:=1;PutLE32(SB,2,21);Sec[6]:=1;
 WriteSec(F);
 FillChar(Sec,IsoSec,0);
 Sec[0]:=1;PutBE32(SB,2,21);Sec[7]:=1;
 WriteSec(F);
 { repertoire racine }
 BlockWrite(F,DirBuf^,Word(DirBytes),W);
 FreeMem(DirBuf,Word(DirBytes));
 { catalogue de boot : entree de validation puis entree initiale }
 FillChar(Sec,IsoSec,0);
 Sec[0]:=1;Sec[1]:=0;
 PutText(SB,4,'MSDOS-0',7);
 Sec[30]:=$55;Sec[31]:=$AA;
 Sum:=0;
 For I:=0 to 15 do Sum:=Sum+Sec[I*2]+LongInt(Sec[I*2+1])*256;
 Sum:=(65536-(Sum mod 65536))mod 65536;
 Sec[28]:=Byte(Sum and $FF);Sec[29]:=Byte(Sum shr 8);
 Case FloppySize of
  1200:Media:=1;
  2880:Media:=3;
 Else Media:=2;
 End;
 Sec[32]:=$88;Sec[33]:=Media;
 Sec[38]:=1;
 PutLE32(SB,40,Files[BootIdx].LBA);
 WriteSec(F);
 { donnees des fichiers }
 GetMem(Buf,8192);
 For I:=1 to Cnt do Begin
  Assign(G,Files[Order[I]].Path);
  {$I-}Reset(G,1);{$I+}
  If IOResult<>0 Then Begin
   WriteLn('Lecture impossible : ',Files[Order[I]].Path);
   Close(F);FreeMem(Buf,8192);Exit;
  End;
  Done:=0;
  Repeat
   BlockRead(G,Buf^,8192,Got);
   If Got>0 Then BlockWrite(F,Buf^,Got,W);
   Done:=Done+Got;
  Until Got=0;
  Close(G);
  Pad:=(IsoSec-(Done mod IsoSec))mod IsoSec;
  If Pad>0 Then Begin
   FillChar(Buf^,Word(Pad),0);
   BlockWrite(F,Buf^,Word(Pad),W);
  End;
 End;
 FreeMem(Buf,8192);
 Close(F);
 BuildISO:=True;
End;

{ ---- Programme principal ---- }

Var
 Ok:Boolean;
 Err,N:Integer;
 F:File;
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
 If IsoName<>'' Then IsoName:=FExpand(IsoName);
 If Not CheckInputs Then Halt(1);
 If Not NoBuild Then Begin
  BuildList;
  Pack;
  For N:=0 to DiskCount-1 do Begin
   If Not StepFormat(N)Then Halt(1);
   If N=0 Then
    If Not StepSystem Then Halt(1);
   StepFiles(N);
  End;
  { supprime d'anciennes disquettes d'une construction precedente }
  N:=DiskCount;
  While(N<DiskLimit)and FileFound(DiskName(N))do Begin
   Assign(F,DiskName(N));
   {$I-}Erase(F);{$I+}
   Err:=IOResult;
   Inc(N);
  End;
  If DiskCount=1 Then WriteLn('Image creee : ',DiskName(0))
  Else Begin
   WriteLn(DiskCount,' disquettes creees :');
   For N:=0 to DiskCount-1 do WriteLn('  ',DiskName(N));
  End;
  If IsoName<>'' Then Begin
   WriteLn('== Creation du CD-ROM ',IsoName);
   If Not BuildISO Then Halt(1);
   WriteLn('CD-ROM cree : ',IsoName);
  End;
 End;
 If ExtractDir<>'' Then Begin
  WriteLn('== Extraction vers ',ExtractDir);
  {$I-}MkDir(ExtractDir);{$I+}
  Err:=IOResult;
  N:=0;
  While(N<DiskLimit)and FileFound(DiskName(N))do Begin
   Ok:=RunTool(UnDiskPcPath,DiskName(N)+' '+ExtractDir);
   If Not Ok Then Begin
    WriteLn('Echec de UNDISKPC.');Halt(1);
   End;
   Inc(N);
  End;
 End;
END.
