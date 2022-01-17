ORG 100h
start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0
    db 0x0F
    NOP

    MOV AX, 0
    MOV DS, AX
    MOV AX, 207
    MOV word [int_handler], AX
    MOV AX, 0
    MOV word [0x0014], AX
    MOV word [0x0016], int_handler

    MOV AL, [0x015]
    db 0x0F
    NOP

    INT 5
    db 0x0F
    NOP

int_handler:
    IRET

    MOV AL, [0x015]
    hlt
