start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0
    db 0x0F
    NOP

    MOV AX, 0x0000
    MOV AL, 0xF0
    CBW
    db 0x0F
    NOP

    CWD
    db 0x0F
    NOP

    MOV word [BP], 0x0000
    LEA AX, [BP]
    db 0x0F
    NOP

    LEA AX, [BP+100]
    db 0x0F
    NOP

    LEA AX, [SI+100]
    db 0x0F
    NOP

    LEA AX, [DI+100]
    db 0x0F
    NOP

    LEA AX, [BP+SI+100]
    db 0x0F
    NOP

    LEA AX, [BX+DI+100]
    db 0x0F
    NOP

    LEA AX, [0x0000]
    db 0x0F
    NOP

    MOV word [BP], 0x0000
    LEA AX, [BP]
    db 0x0F
    NOP

    LEA DX, [BP+100]
    db 0x0F
    NOP

    LEA DX, [SI+100]
    db 0x0F
    NOP

    LEA DX, [DI+100]
    db 0x0F
    NOP

    LEA DX, [BP+SI+100]
    db 0x0F
    NOP

    LEA DX, [BX+DI+100]
    db 0x0F
    NOP

    LEA DX, [0x0000]
    db 0x0F
    NOP

    HLT
