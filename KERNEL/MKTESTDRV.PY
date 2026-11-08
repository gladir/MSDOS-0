#!/usr/bin/env python3
# Genere TESTDRV.SYS : pilote de peripherique caractere minimal pour tester DEVICE= (CONFIG.SYS) et DEVLOAD.EXE.
# Son INIT affiche un message (INT 21h/09h) et laisse tout le fichier residant.
import struct, sys
hdr = struct.pack('<HHHHH', 0xFFFF, 0xFFFF, 0x8000, 0x12, 0x1D) + b'TESTDRV '
R1, R2, MSG = 0x52, 0x54, 0x56
msg = b'Pilote TESTDRV charge$'
end = MSG + len(msg)
b = bytearray()
b += bytes([0x2E,0x89,0x1E]) + struct.pack('<H', R1)      # strategie : mov cs:[R1],bx
b += bytes([0x2E,0x8C,0x06]) + struct.pack('<H', R2)      #             mov cs:[R2],es
b += bytes([0xCB])                                          #             retf
b += bytes([0x1E,0x06,0x53,0x52,0x50])                      # interruption : push ds,es,bx,dx,ax
b += bytes([0x2E,0x8B,0x1E]) + struct.pack('<H', R1)      # mov bx,cs:[R1]
b += bytes([0x2E,0x8E,0x06]) + struct.pack('<H', R2)      # mov es,cs:[R2]
b += bytes([0x26,0x80,0x7F,0x02,0x00])                      # cmp byte es:[bx+2],0   (commande INIT ?)
b += bytes([0x75,0x13])                                     # jne fin
b += bytes([0x0E,0x1F,0xBA]) + struct.pack('<H', MSG)     # push cs ; pop ds ; mov dx,msg
b += bytes([0xB4,0x09,0xCD,0x21])                           # mov ah,9 ; int 21h
b += bytes([0x26,0xC7,0x47,0x0E]) + struct.pack('<H', end) # adresse de rupture : fin du pilote
b += bytes([0x26,0x8C,0x4F,0x10])
b += bytes([0x26,0xC7,0x47,0x03,0x00,0x01])                 # fin : statut = 0100h (termine)
b += bytes([0x58,0x5A,0x5B,0x07,0x1F,0xCB])                 # pop ax,dx,bx,es,ds ; retf
b += b'\0\0\0\0' + msg
open(sys.argv[1] if len(sys.argv) > 1 else 'TESTDRV.SYS', 'wb').write(hdr + b)
