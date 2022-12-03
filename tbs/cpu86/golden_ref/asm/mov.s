start:
    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0


    MOV AX, DS
    XCHG AX, AX
    MOV AX, SS
    XCHG AX, AX
    MOV AX, SP
    XCHG AX, AX
    MOV AX, BP
    XCHG AX, AX

    MOV AX, 0
    MOV BX, 0
    MOV CX, 0
    MOV DX, 0
    MOV SI, 0
    MOV BP, 0
    MOV SP, 0xFFFE

    XCHG AX, AX
    MOV AX, BX
    XCHG AX, AX
    MOV AX, CX
    XCHG AX, AX
    MOV AX, DX
    XCHG AX, AX
    MOV AX, SI
    XCHG AX, AX
    MOV AX, BP
    XCHG AX, AX
    MOV AX, SP
    XCHG AX, AX

    MOV CL, BL
    MOV AX, CX
    XCHG AX, AX

    MOV AX, 0xFFF1
    MOV DS, AX
    MOV BX, DS
    MOV AX, BX
    XCHG AX, AX

    MOV AX, 0xFFF2
    MOV SS, AX
    MOV BX, SS
    MOV AX, BX
    XCHG AX, AX

    MOV AX, 0xFFF2
    MOV ES, AX
    MOV CX, ES
    MOV AX, CX
    XCHG AX, AX

    MOV AL, 1
    MOV AH, 1
    MOV BL, 2
    MOV BH, 2
    MOV CL, 3
    MOV CH, 3
    MOV DL, 4
    MOV DH, 4
    XCHG AX, AX
    MOV AX, BX
    XCHG AX, AX
    MOV AX, CX
    XCHG AX, AX
    MOV AX, DX

    MOV AX, SP
    MOV BX, SP
    MOV CX, SP
    MOV DX, SP
    MOV SI, SP
    MOV DI, SI
    XCHG AX, AX
    MOV AX, BX
    XCHG AX, AX
    MOV AX, CX
    XCHG AX, AX
    MOV AX, DX
    XCHG AX, AX
    MOV AX, SI
    XCHG AX, AX
    MOV AX, BP
    XCHG AX, AX
    MOV AX, SP
    XCHG AX, AX

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV BP, 0

    MOV AX, 0xFF01
    MOV [BP+2], AX
    MOV BX, [BP+2]
    MOV BX, 0xFF02
    MOV [BP+4], BX
    MOV AX, [BP+4]
    MOV CX, 0xFF03
    MOV [BP+7], CX
    MOV DX, [BP+7]
    XCHG AX, AX
    MOV AX, BX
    XCHG AX, AX
    MOV AX, CX
    XCHG AX, AX
    MOV AX, DX

    MOV AX, 0xFF01
    MOV [BP+2], AX
    MOV [BP+0xFF02], AX
    MOV [BP+0xF2], AX
    MOV ES, [BP+0xFF02]
    MOV AX, ES
    XCHG AX, AX
    MOV ES, [BP+0xF2]
    MOV AX, ES
    XCHG AX, AX
    MOV ES, [BP+2]
    MOV AX, ES
    XCHG AX, AX

    MOV AX, 0x1234
    MOV [0xFF00], AX
    MOV AX, 0
    MOV AX, [0xFF00]
    XCHG AX, AX


    MOV AX, 0
    MOV AL, [0xFF00]
    XCHG AX, AX


    MOV AL, [0xFF01]
    XCHG AX, AX

    MOV byte [BP+2], 0x1
    MOV word [BP+2], 0x1ff1
    MOV AX, [BP+2]
    XCHG AX, AX

    hlt
