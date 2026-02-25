{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/msdos0)
  @abstract(Target: Turbo Pascal 7)
  @desciption: Fabrique le MSDOS.SYS avec un unit� automne Pascal.
}

Program MAKER;

Uses MSDOS;

Var
 SourceKernel:Pointer;
 KernelFile:File;
 ByteWrited:Word;

BEGIN
 SourceKernel:=@BEGIN_KERNEL;
 {$I-}Assign(KernelFile,'MSDOS.SYS');
 Rewrite(KernelFile);{$I+}
 If IOResult<>0 Then Begin
  Write('Impossible d''�crire MSDOS.SYS');
  Halt(1);
 End;
 BlockWrite(KernelFile,SourceKernel^,Ofs(END_KERNEL)+1,ByteWrited);
 Close(KernelFile);
END.