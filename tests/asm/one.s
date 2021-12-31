start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0
    db 0x0F
    NOP

    ; NEG REG WORD

    MOV AX, 0x0001
    NEG AX
    db 0x0F
    NOP

    MOV BX, 0x0002
    NEG BX
    db 0x0F
    NOP

    MOV CX, 0x3333
    NEG CX
    db 0x0F
    NOP

    MOV DX, 0x4444
    NEG DX
    db 0x0F
    NOP

    MOV BP, 0x5555
    NEG BP
    db 0x0F
    NOP

    MOV SP, 0xFFFE
    NEG SP
    db 0x0F
    NOP
    NEG SP
    db 0x0F
    NOP

    MOV DI, 0x0000
    NEG DI
    db 0x0F
    NOP

    MOV SI, 0xFFFF
    NEG SI
    db 0x0F
    NOP

    MOV CX, 0xFFFF
    NEG CL
    db 0x0F
    NOP

    MOV CX, 0xAAFF
    NEG CH
    db 0x0F
    NOP

    MOV BP, 0
    MOV word [BP], 0x0001
    NEG word [BP]
    MOV AX, [BP]
    db 0x0F
    NOP

    NEG byte [BP]
    MOV AX, [BP]
    db 0x0F
    NOP

    ; not tests
    MOV AX, 0x0101
    NOT AX
    db 0x0F
    NOP

    MOV DX, 0x0101
    NOT DL
    db 0x0F
    NOP
    NOT DH
    db 0x0F
    NOP

    MOV BP, 0
    MOV word [BP], 0xFAFA
    NOT word [BP]
    NOT word [BP]
    NOT byte [BP]
    MOV AX, [BP]
    db 0x0F
    NOP

    ; test
    MOV AX, 0x0101
    TEST AX, 0x0001
    db 0x0F
    NOP

    TEST AL, 0x01
    db 0x0F
    NOP

    TEST AH, 0x01
    db 0x0F
    NOP

    MOV BX, 0x0011
    TEST BX, 0x0011
    db 0x0F
    NOP

    MOV BX, 0x0011
    TEST BH, 0x0011
    db 0x0F
    NOP

    MOV BP, 0
    MOV word [BP], 0xFFFF
    TEST byte [BP], 0xFF
    db 0x0F
    NOP
    TEST word [BP], 0xFFFF
    db 0x0F
    NOP
    TEST word [BP], 0x12
    db 0x0F
    NOP

    MOV AX, 0x0202
    MOV BX, 0x0303
    TEST AL, BL
    db 0x0F
    NOP

    TEST AX, BX
    db 0x0F
    NOP

    hlt
