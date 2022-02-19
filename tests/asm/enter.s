ORG 100h
start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0
    db 0x0F
    NOP

    MOV byte [BP], AL
    MOV AL, [BP]

    ENTER 4, 5

    db 0x0F
    NOP

    MOV AX, [BP]
    db 0x0F
    NOP

    ENTER 4, 1

    db 0x0F
    NOP

    MOV AX, [BP]
    db 0x0F
    NOP

    ENTER 4, 0

    db 0x0F
    NOP

    MOV AX, [BP]
    db 0x0F
    NOP

    ENTER 4, 31

    db 0x0F
    NOP

    LEAVE

    MOV AX, [BP]
    db 0x0F
    NOP

    HLT

