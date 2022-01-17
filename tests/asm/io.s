start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0
    db 0x0F
    NOP

    OUT 0, AX
    MOV AX, 0xF
    IN AX, 0

    MOV [BP], AX
    db 0x0F
    NOP

    MOV AX, 0xFABA
    MOV DX, 0xF0F0
    OUT DX, AX
    MOV AX, 0xF
    IN AX, DX
    db 0x0F
    NOP

    MOV AX, 0xFABB
    MOV DX, 0xF0F0
    OUT DX, AL
    MOV AX, 0xF
    IN AL, DX
    db 0x0F
    NOP

    cld
    MOV AX, 0x1000
    MOV DI, 0
    MOV ES, AX
    MOV DS, AX

    MOV AX, 'He'
    STOSW
    MOV AX, 'll'
    STOSW
    MOV AL, 'o'
    STOSB
    MOV AL, 0x0
    STOSB
    MOV AX, 'Wo'
    STOSW
    MOV AX, 'rl'
    STOSW
    MOV AL, 'd'
    STOSB
    MOV AL, 0x0
    STOSB

    MOV SI, 0
    MOV CX, 3
    REP OUTSW

    IN AX, DX
    db 0x0F
    NOP

    OUTSW
    IN AX, DX

    db 0x0F
    NOP

    MOV DX, 0xFFFF
    IN AX, DX
    db 0x0F
    NOP

    MOV DX, 0xFFFF
    IN AX, DX
    db 0x0F
    NOP

    cld
    MOV AX, 0x1000
    MOV DI, 0
    MOV ES, AX
    MOV DS, AX
    MOV CX, 4
    REP INSW
    db 0x0F
    NOP

    INSW

    db 0x0F
    NOP

    HLT

