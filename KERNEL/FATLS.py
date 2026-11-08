# Liste les fichiers (et sous-repertoires) d une image disquette FAT12 : python3 FATLS.py image.img [FICHIER1 FICHIER2]
# (compare le contenu de deux fichiers). Sert a verifier les ecritures du noyau dans /tmp/kerneltest.img.
import sys,struct
img=open(sys.argv[1],'rb').read()
bps,spc,res,nfat,rootent,tot16,media,spf=struct.unpack_from('<HBHBHHBH',img,11)
first_root=res+nfat*spf
rootsecs=(rootent*32+511)//512
first_data=first_root+rootsecs
def fat(c):
    o=c*3//2
    v=img[res*512+o]|(img[res*512+o+1]<<8)
    return (v&0xFFF) if c%2==0 else v>>4
def chain(c):
    out=[]
    while 2<=c<0xFF8:
        out.append(c); c=fat(c)
        if len(out)>5000: break
    return out
def lsdir(sectors,indent=''):
    for s in sectors:
        for i in range(16):
            e=img[s*512+i*32:s*512+i*32+32]
            if e[0]==0: return
            if e[0]==0xE5 or e[11]&8: continue
            name=e[:8].decode('cp437').rstrip()+('.'+e[8:11].decode('cp437').rstrip() if e[8:11].strip() else '')
            cl=e[26]|(e[27]<<8); size=struct.unpack_from('<I',e,28)[0]
            print(indent+'%-12s attr=%02x cl=%d size=%d chain=%d'%(name,e[11],cl,size,len(chain(cl))))
            if e[11]&0x10 and not name.startswith('.'):
                lsdir([first_data+(c-2)*spc+k for c in chain(cl) for k in range(spc)],indent+'   ')
lsdir(range(first_root,first_root+rootsecs))
def data(name):
    for s in range(first_root,first_root+rootsecs):
        for i in range(16):
            e=img[s*512+i*32:s*512+i*32+32]
            if e[0] in (0,0xE5): continue
            n=e[:8].decode('cp437').rstrip()+('.'+e[8:11].decode('cp437').rstrip() if e[8:11].strip() else '')
            if n==name:
                cl=e[26]|(e[27]<<8); size=struct.unpack_from('<I',e,28)[0]
                d=b''.join(img[first_data*512+(c-2)*spc*512:first_data*512+(c-1)*spc*512] for c in chain(cl))
                return d[:size]
if len(sys.argv)>2:
    a=data(sys.argv[2]); b=data(sys.argv[3]); print('compare',sys.argv[2],sys.argv[3],a==b, len(a or b''), len(b or b''))
