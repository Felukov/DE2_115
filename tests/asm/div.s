ORG 100h
start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0
    db 0x0F
    NOP

    MOV AX, 12
    MOV DX, -1
    MOV CX, -5
    IDIV CL
    db 0x0F
    NOP

    MOV AX, 12
    MOV DX, 0
    MOV CX, -5
    IDIV CL
    db 0x0F
    NOP

    MOV AX, -12
    MOV DX, 0
    MOV CX, 5
    IDIV CL
    db 0x0F
    NOP

    MOV AX, -12
    MOV DX, 0
    MOV CX, -5
    IDIV CL
    db 0x0F
    NOP

    ;
    MOV AX, 12
    MOV DX, 0
    MOV CX, -5
    IDIV CX
    db 0x0F
    NOP

    MOV AX, -12
    MOV DX, 0
    MOV CX, 5
    IDIV CX
    db 0x0F
    NOP

    MOV AX, -12
    MOV DX, 0
    MOV CX, -5
    IDIV CX
    db 0x0F
    NOP

    ;
    MOV AX, 12
    MOV DX, 0
    MOV CX, 4
    DIV CL
    db 0x0F
    NOP

    MOV AX, 12
    MOV DX, 0
    MOV CX, 4
    DIV CX
    db 0x0F
    NOP

    MOV word [BP], 4
    DIV word [BP]
    db 0x0F
    NOP

    MOV AX, [BP]
    db 0x0F
    NOP

    MOV AX, 0
    MOV DS, AX
    MOV word [0x0000], div_zero_handler
    MOV word [0x0002], AX

    MOV AX, 0xFF
    MOV DX, 0x00
    MOV CX, 0x00
    DIV CX

    db 0x0F
    NOP

    HLT

div_zero_handler:
    MOV CX, 1
    iret


    hlt



; Data

