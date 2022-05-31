start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0

    MOV AX, 0xAAAA
    MOV ES, AX
    PUSH ES
    MOV AX, 0xA00A
    MOV ES, AX
    POP ES
    MOV AX, ES
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV AX, 0xABAC
    MOV DS, AX
    PUSH DS
    MOV AX, 0xA00A
    MOV DS, AX
    POP DS
    MOV AX, DS
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    PUSH CS
    POP AX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    PUSH SS
    POP DS
    MOV AX, DS
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV AX, 0
    MOV SS, AX
    MOV SP, 0xFFFE

    MOV AX, 0x3333
    PUSH AX
    MOV AX, 0
    POP BX
    PUSH BX
    POP CX
    PUSH CX
    POP DX
    PUSH DX
    POP BP
    PUSH BP
    POP DI
    PUSH DI
    POP SI
    PUSH SI
    POP AX

    MOV AX, 0x1111
    MOV CX, 0x2222
    MOV DX, 0x3333
    MOV BX, 0x4444
    MOV BP, 0x5555
    MOV SI, 0x6666
    MOV DI, 0x7777
    PUSHA
    POPA

    MOV SP, 0xFFFF
    PUSHA
    POPA

    MOV SP, 0xFFFE
    PUSH 0x1111
    POP AX
    PUSH 0xF0
    POP BX

    MOV SP, 0xFFFE
    MOV AX, 0x1000
    MOV DS, AX
    MOV BP, 0
    MOV word [BP+2], 0xABCD
    PUSH word [BP+2]
    POP word [BP+4]
    MOV AX, [BP+4]

    hlt