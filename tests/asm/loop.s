start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0
    db 0x0F
    NOP

    MOV CX, 10
    MOV AX, 0x0
    MOV BX, 0xFFFF
    MOV word [BP], 0x0
loop1:
    INC AX
    DEC BX
    INC word [BP]
    LOOP loop1

    INC word [BP]
    MOV AX, [BP]
    db 0x0F
    NOP

    HLT
