.186
.model tiny

DGROUP group _TEXT,CONST,STRINGS,_DATA,DATA,XIB,XI,XIE,YIB,YI,YIE,_BSS

_TEXT   segment word public 'CODE'

org 0100h

; procedure prototypes
bare_main                proto near c
int0_hook           proto far c
int8_hook           proto far c
int9_hook           proto far c
interrupt_handler   proto near c

_cstart_:
    ; set DS
    mov ax, 0
    mov ds, ax

    ; interrupt handlers
    mov bx, 0
    mov cx, cs
    mov word ptr 00h[bx], offset int0_hook
    mov word ptr 02h[bx], cx
    mov word ptr 20h[bx], offset int8_hook
    mov word ptr 22h[bx], cx
    mov word ptr 24h[bx], offset int9_hook
    mov word ptr 26h[bx], cx

    mov es, cx
    mov ss, cx
    mov ds, cx
    mov sp, -2

    sti

    invoke bare_main
@@: jmp @b

int0_hook proc far c
    push    ax                  ;; This will save them all and pass them to
    push    cx                  ;; the C program
    push    dx                  ;;
    push    bx                  ;;
    push    bp                  ;;
    push    si                  ;;
    push    di                  ;;
    push    es                  ;; The order of parms in C program
    push    ds                  ;; DS, ES, DI, SI, BP, BX, DX, CX, AX, rIP, rCS, FLAGS
    push    0

    push    ss                  ;; Push the stack segment
    pop     ds                  ;; Pop it to the Data segment, now we have DS set for our C call

    invoke  interrupt_handler

    pop     ax
    pop     ds                  ;; Restore all registers
    pop     es                  ;; Back in the reverse order pushed from above
    pop     di                  ;;
    pop     si                  ;;
    pop     bp                  ;;
    pop     bx                  ;;
    pop     dx                  ;;
    pop     cx                  ;;
    pop     ax                  ;;

    iret
int0_hook endp

int8_hook proc far c
    push    ax                  ;; This will save them all and pass them to
    push    cx                  ;; the C program
    push    dx                  ;;
    push    bx                  ;;
    push    bp                  ;;
    push    si                  ;;
    push    di                  ;;
    push    es                  ;; The order of parms in C program
    push    ds                  ;; DS, ES, DI, SI, BP, BX, DX, CX, AX, rIP, rCS, FLAGS
    push    8

    push    ss                  ;; Push the stack segment
    pop     ds                  ;; Pop it to the Data segment, now we have DS set for our C call

    invoke  interrupt_handler

    pop     ax
    pop     ds                  ;; Restore all registers
    pop     es                  ;; Back in the reverse order pushed from above
    pop     di                  ;;
    pop     si                  ;;
    pop     bp                  ;;
    pop     bx                  ;;
    pop     dx                  ;;
    pop     cx                  ;;
    pop     ax                  ;;

    iret
int8_hook endp

int9_hook proc far c
    push    ax                  ;; This will save them all and pass them to
    push    cx                  ;; the C program
    push    dx                  ;;
    push    bx                  ;;
    push    bp                  ;;
    push    si                  ;;
    push    di                  ;;
    push    es                  ;; The order of parms in C program
    push    ds                  ;; DS, ES, DI, SI, BP, BX, DX, CX, AX, rIP, rCS, FLAGS
    push    9

    push    ss                  ;; Push the stack segment
    pop     ds                  ;; Pop it to the Data segment, now we have DS set for our C call

    invoke  interrupt_handler

    pop     ax
    pop     ds                  ;; Restore all registers
    pop     es                  ;; Back in the reverse order pushed from above
    pop     di                  ;;
    pop     si                  ;;
    pop     bp                  ;;
    pop     bx                  ;;
    pop     dx                  ;;
    pop     cx                  ;;
    pop     ax                  ;;

    iret
int9_hook endp

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
