start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0
    db 0x0F
    NOP

    clc
    db 0x0F
    NOP

    stc
    db 0x0F
    NOP

    cmc
    db 0x0F
    NOP

    clc
    cmc
    cmc
    db 0x0F
    NOP

    clc
    cmc
    db 0x0F
    NOP

    mov word [BP], 0
    inc word [BP]

    hlt
