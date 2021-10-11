start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0
    db 0x0F
    NOP

    MOV AX, 0x3000
    MOV SS, AX
    MOV BP, 0
    MOV AX, 0x4444
    MOV word [BP], 0x0001
    ADD [BP], AL
    MOV AH, [BP]
    db 0x0F
    NOP

    MOV AX, 0x5555
    MOV word [BP], 0x0001
    ADD [BP], AX
    MOV BX, [BP]
    db 0x0F
    NOP

    MOV AX, 0x5555
    ADD AX, AX
    MOV AX, 0x6666
    MOV word [BP], 0x0001
    ADD AX, [BP]
    db 0x0F
    NOP

    MOV AX, 0x7777
    MOV word [BP], 0x0001
    ADD AL, [BP]
    db 0x0F
    NOP

    MOV AX, 0x8888
    ADD AX, 0x0002
    db 0x0F
    NOP

    MOV AX, 0x9999
    ADD AL, 0x01
    db 0x0F
    NOP

    MOV AX, 0x00FF
    ADD AL, 1
    db 0x0F
    NOP

    HLT
