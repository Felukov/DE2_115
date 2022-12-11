export WATCOM=/home/fila/watcom

$WATCOM/binl/jwasm -1 cstart.asm
$WATCOM/binl/jwasm -1 terminal.asm
$WATCOM/binl/wcc -1 -s -wx -d0 -ms -zl -ecc kernel.c
$WATCOM/binl/wcc -1 -s -wx -d0 -ms -zl -ecc kbd.c
$WATCOM/binl/wcc -1 -s -wx -d0 -ms -zl -ecc rnd.c
$WATCOM/binl/wcc -1 -s -wx -d0 -ms -zl -ecc main.c
$WATCOM/binl/wdis -s -l main.o
$WATCOM/binl/wdis -s -l kernel.o
$WATCOM/binl/wdis -s -l kbd.o
$WATCOM/binl/wdis -s -l rnd.o
$WATCOM/binl/wdis -s -l cstart.o
$WATCOM/binl/wdis -s -l terminal.o

$WATCOM/binl/wlink "@params.lnk"

mv *.lst ./dumps
mv *.o   ./objs

