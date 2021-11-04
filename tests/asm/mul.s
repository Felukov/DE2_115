start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0
    db 0x0F
    NOP
    mov word [BP], 0
    mov AX, [BP]

    MOV AL, 0x2
    IMUL AL
    db 0x0F
    NOP

    MOV DX, 0xFEEF

    IMUL AX
    db 0x0F
    NOP

    MOV BX, 0x3
    IMUL BX
    db 0x0F
    NOP

    MOV CX, 0x4
    IMUL CX
    db 0x0F
    NOP

    MOV DX, 0x2

    IMUL BX, DX, 0x2
    db 0x0F
    NOP

    IMUL AX, BX, 0xF000
    db 0x0F
    NOP

    MOV AX, 0xF000
    MOV BX, 0x2
    IMUL BX
    db 0x0F
    NOP

    MOV word [BP], 0x1234
    IMUL word [BP]
    IMUL byte [BP]
    db 0x0F
    NOP

    MOV DX, 0x2
    IMUL DX, 0x2
    db 0x0F
    NOP

    IMUL AX, DX, 0xFFF
    db 0x0F
    NOP

    IMUL CX, 0xFFF
    db 0x0F
    NOP

    IMUL CX, [BP], 0x2
    db 0x0F
    NOP

    IMUL SI, [BP], 0x2AA
    db 0x0F
    NOP


    hlt