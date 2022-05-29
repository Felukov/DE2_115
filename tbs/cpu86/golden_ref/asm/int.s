ORG 400h
start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0

    MOV AX, 0
    MOV DS, AX
    MOV AX, 207
    MOV word [int_handler], AX
    MOV AX, 0
    MOV word [0x0014], int_handler
    MOV word [0x0016], AX

    MOV AL, [0x015]
    XCHG AX, AX

    INT 5

    MOV AX, 20
    XCHG AX, AX

    HLT

int_handler:
    NOP ; EMPTY SPACE TO BE REPLACED WITH CF
    XCHG AX, AX

    IRET


