start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0
    db 0x0F
    NOP

    XOR AX, AX
    MOV AX, 5
    ADD AX, 7
    AAA
    db 0x0F
    NOP

    MOV AX, 0x409
    AAD
    db 0x0F
    NOP
    MOV CX, 3
    DIV CX

    MOV BL, AH
    AAM
    db 0x0F
    NOP

    MOV AX, 0x103
    SUB AL, 0x5
    AAS
    db 0x0F
    NOP

    MOV AL, 0x08
    SBB AL, 0x11
    DAS
    db 0x0F
    NOP

    MOV AL, 0x17
    SBB AL, 0x30
    DAS
    db 0x0F
    NOP

    MOV AL, 0x24
    SBB AL, 0x19
    DAS
    db 0x0F
    NOP

    MOV AL, 0x08
    ADC AL, 0x11
    DAA
    db 0x0F
    NOP

    MOV AL, 0x17
    ADC AL, 0x30
    DAA
    db 0x0F
    NOP

    MOV AL, 0x24
    ADC AL, 0x19
    DAA
    db 0x0F
    NOP

    MOV [BP], AX
    db 0x0F
    NOP
    HLT

