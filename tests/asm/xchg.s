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

    XCHG AX, AX
    XCHG AX, BX
    XCHG AX, CX
    XCHG AX, DX
    XCHG AX, SI
    XCHG AX, BP
    XCHG AX, DI
    XCHG AX, SP
    db 0x0F
    NOP

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0

    MOV word [BP], 0x1122
    MOV AX, 0x1234
    XCHG word AX, [BP]
    db 0x0F
    NOP

    XCHG byte AL, [BP]
    db 0x0F
    NOP

    HLT
