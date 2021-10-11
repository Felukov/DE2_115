start:
    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0
    db 0x0F
    NOP

    MOV AX, 0
    MOV BX, 0
    MOV CX, 0
    MOV DX, 0
    MOV SI, 0
    MOV BP, 0
    MOV SP, 0xFFFE

    db 0x0F
    NOP

    MOV CL, BL
    db 0x0F
    NOP

    MOV AX, 0xFFF1
    MOV DS, AX
    MOV BX, DS
    db 0x0F
    NOP

    MOV AX, 0xFFF2
    MOV SS, AX
    MOV BX, SS
    db 0x0F
    NOP

    MOV AX, 0xFFF2
    MOV ES, AX
    MOV CX, ES
    db 0x0F
    NOP

    MOV AL, 1
    MOV AH, 1
    MOV BL, 2
    MOV BH, 2
    MOV CL, 3
    MOV CH, 3
    MOV DL, 4
    MOV DH, 4
    db 0x0F
    NOP

    MOV AX, SP
    MOV BX, SP
    MOV CX, SP
    MOV DX, SP
    MOV SI, SP
    MOV DI, SI
    db 0x0F
    NOP

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
    db 0x0F
    NOP

    MOV AX, 0xFF01
    MOV [BP+2], AX
    MOV [BP+0xFF02], AX
    MOV [BP+0xF2], AX
    MOV ES, [BP+0xFF02]
    db 0x0F
    NOP
    MOV ES, [BP+0xF2]
    db 0x0F
    NOP
    MOV ES, [BP+2]
    db 0x0F
    NOP

    MOV AX, 0x1234
    MOV [0xFF00], AX
    MOV AX, 0
    MOV AX, [0xFF00]
    db 0x0F
    NOP

    MOV AX, 0
    MOV AL, [0xFF00]
    db 0x0F
    NOP

    MOV AL, [0xFF01]
    db 0x0F
    NOP

    MOV byte [BP+2], 0x1
    MOV word [BP+2], 0x1ff1

    hlt
