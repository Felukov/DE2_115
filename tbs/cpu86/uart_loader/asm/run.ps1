C:\JWasm211bw\JWASM.EXE ./uart.asm
C:\JWasm211bw\JWASM.EXE ./terminal.asm
C:\JWasm211bw\JWASM.EXE ./bootstrap.asm
C:\JWasm211bw\JWASM.EXE ./x86mmu.asm

#Set-Variable WLINK_LNK=wlink.lnk
C:\WATCOM\binnt\wlink.exe "@params.lnk"
C:\WATCOM\binnt\wdis.exe .\bootstrap.obj > .\bootstrap.s
C:\WATCOM\binnt\wdis.exe .\terminal.obj > .\terminal.s
C:\WATCOM\binnt\wdis.exe .\x86mmu.obj > .\x86mmu.s
C:\WATCOM\binnt\wdis.exe .\uart.obj > .\uart.s

&'C:\Program Files\NASM\ndisasm.exe' -b 16 .\bootstrap.bin > .\full.s


C:\Projects\srecord-1.63-win32\srec_cat.exe  .\bootstrap.bin -binary -fill 0x00 -within .\bootstrap.bin -binary -range-pad 4 -o .\bootstrap.vmem -vmem
Copy-Item .\bootstrap.vmem C:\Projects\DE2_115\rtl\soc\onchip_ram\altera\bootstrap.vmem

