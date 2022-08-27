.186
.model tiny

DGROUP group _TEXT,CONST,STRINGS,_DATA,DATA,XIB,XI,XIE,YIB,YI,YIE,_BSS

_TEXT   segment word public 'CODE'

org 0100h

; procedure prototypes
cmain               proto near c
int0_hook           proto far c
int8_hook           proto far c
interrupt_handler   proto near c, int_no : byte,
    regs_ax : word, regs_bx : word, regs_cx : word, regs_dx : word

_cstart_:
    mov  ax, 01111h
    mov  dx, 00305h
    out  dx, ax

    mov ax, 0
    mov ds, ax
    mov bx, 0
    mov word ptr 00h[bx], offset int0_hook
    mov word ptr 02h[bx], cx
    mov word ptr 20h[bx], offset int8_hook
    mov word ptr 22h[bx], cx

    mov cx, cs
    mov es, cx
    mov ss, cx
    mov ds, cx
    mov sp, -2

    invoke cmain
@@: jmp @b

int0_hook proc far c
    local   regs_ax : word
    local   regs_bx : word
    local   regs_cx : word
    local   regs_dx : word

    pusha
    mov     regs_ax, ax
    mov     regs_bx, bx
    mov     regs_cx, cx
    mov     regs_dx, dx

    invoke  interrupt_handler, 0, addr regs_ax, addr regs_bx, addr regs_cx, addr regs_dx
    popa
    iret
int0_hook endp

int8_hook proc far c
    local   regs_ax : word
    local   regs_bx : word
    local   regs_cx : word
    local   regs_dx : word

    pusha
    mov     regs_ax, ax
    mov     regs_bx, bx
    mov     regs_cx, cx
    mov     regs_dx, dx

    invoke  interrupt_handler, 8, addr regs_ax, addr regs_bx, addr regs_cx, addr regs_dx
    popa
    iret
int8_hook endp

int15_hook proc far c
    local   regs_ax : word
    local   regs_bx : word
    local   regs_cx : word
    local   regs_dx : word
    pusha
    invoke interrupt_handler, 8, addr regs_ax, addr regs_bx, addr regs_cx, addr regs_dx
    popa
    iret
int15_hook endp

_TEXT   ends

CONST   segment word public 'DATA'
CONST   ends

STRINGS segment word public 'DATA'
STRINGS ends

XIB     segment word public 'DATA'
XIB     ends
XI      segment word public 'DATA'
XI      ends
XIE     segment word public 'DATA'
XIE     ends

YIB     segment word public 'DATA'
YIB     ends
YI      segment word public 'DATA'
YI      ends
YIE     segment word public 'DATA'
YIE     ends

_DATA   segment word public 'DATA'
_DATA   ends

DATA    segment word public 'DATA'
DATA    ends

_BSS    segment word public 'BSS'
_BSS    ends

end _cstart_
