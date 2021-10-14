start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0
    db 0x0F
    NOP

    MOV AX, 0xAAAA
    MOV BX, 0xBBBB
    MOV CX, 0xCCCC
    MOV DX, 0xDDDD
    MOV SI, 0xEEEE
    MOV BP, 0xFFFF
    MOV DI, 0x8888
    MOV SP, 0xFFFE

    INC AX
    INC BX
    INC CX
    INC DX
    INC BP
    INC SP
    INC SI
    INC DI
    db 0x0F
    NOP
    DEC AX
    db 0x0F
    NOP
    DEC BX
    db 0x0F
    NOP
    DEC CX
    db 0x0F
    NOP
    DEC DX
    db 0x0F
    NOP
    DEC BP
    db 0x0F
    NOP
    DEC SP
    db 0x0F
    NOP
    DEC SI
    db 0x0F
    NOP
    DEC DI
    db 0x0F
    NOP

    INC AL
    INC AH
    INC BL
    INC BH
    INC CL
    INC CH
    db 0x0F
    NOP

    DEC AL
    DEC AH
    DEC BL
    DEC BH
    DEC CL
    DEC CH
    db 0x0F
    NOP

    MOV AX, 0x2000
    MOV DS, AX
    MOV SS, AX
    MOV BP, 0
    MOV AX, 0xFF
    MOV [BP], AX
    INC word [BP]
    DEC word [BP]
    MOV AX, [BP]
    db 0x0F
    NOP

    INC byte [BP]
    DEC byte [BP]
    MOV AX, [BP]
    db 0x0F
    NOP

    HLT
