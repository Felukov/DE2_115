ORG 100h
start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0
    db 0x0F
    NOP

    MOV AX, 100
    MOV [BP], AX
    MOV AX, 200
    MOV [BP+2], AX

    MOV AX, 150
    BOUND AX, [BP]

    db 0x0F
    NOP

    MOV AX, 0
    MOV DS, AX
    MOV word [0x0014], AX
    MOV word [0x0016], bound_exception_handler

    MOV AX, 50
    BOUND AX, [BP]

    db 0x0F
    NOP

bound_exception_handler:
    db 0x0F
    NOP

    HLT

