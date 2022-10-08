C:\JWasm211bw\JWASM.EXE ./cstart.asm
C:\JWasm211bw\JWASM.EXE ./terminal.asm
C:\WATCOM\binnt\wcc.exe -s -wx -d0 -ms -zl -ecc .\kernel.c
C:\WATCOM\binnt\wcc.exe -s -wx -d0 -ms -zl -ecc .\kbd.c
C:\WATCOM\binnt\wcc.exe -s -wx -d0 -ms -zl -ecc .\rnd.c
C:\WATCOM\binnt\wcc.exe -s -wx -d0 -ms -zl -ecc .\main.c
C:\WATCOM\binnt\wdis.exe .\main.obj > .\main.s
C:\WATCOM\binnt\wdis.exe .\kernel.obj > .\kernel.s
C:\WATCOM\binnt\wdis.exe .\kbd.obj > .\kbd.s
C:\WATCOM\binnt\wdis.exe .\rnd.obj > .\rnd.s
C:\WATCOM\binnt\wdis.exe .\cstart.obj > .\cstart.s
C:\WATCOM\binnt\wdis.exe .\terminal.obj > .\terminal.s
C:\WATCOM\binnt\wlink.exe "@params.lnk"

&'C:\Program Files\NASM\ndisasm.exe' -b 16 .\cstart.com > .\full.s


if (!(Test-Path -path "objs\")) {
    New-Item -ItemType Directory -Force -Path "objs"
} else {
    Remove-Item 'objs\*' -Recurse -Include *.obj
}
Move-Item -Path .\*.obj -Destination .\objs\

if (!(Test-Path -path "dumps\")) {
    New-Item -ItemType Directory -Force -Path "dumps"
} else {
    Remove-Item 'dumps\*' -Recurse -Include *.s
}
Move-Item -Path .\*.s -Destination .\dumps\

