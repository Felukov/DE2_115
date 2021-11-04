start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0
    db 0x0F
    NOP

    PUSHF

    LAHF
    db 0x0F
    NOP

    MOV AX, 0x6789
    SAHF
    db 0x0F
    NOP

    POPF
    PUSHF
    POPF

    db 0x0F
    NOP

    HLT
