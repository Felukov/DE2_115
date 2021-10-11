start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0
    db 0x0F
    NOP

    MOV AX, 0x310A
    MOV SS, AX
    MOV BP, 0
    MOV AX, 0xFFFF
    MOV word [BP], 0x00AA
    OR [BP], AL
    MOV AH, [BP]
    db 0x0F
    NOP

    MOV AX, 0x0AA0
    MOV word [BP], 0xABBA
    OR [BP], AX
    MOV BX, [BP]
    db 0x0F
    NOP

    MOV AX, 0xA00A
    MOV word [BP], 0xABBA
    OR AX, [BP]
    db 0x0F
    NOP

    MOV AX, 0xC00C
    MOV word [BP], 0xACCA
    OR AL, [BP]
    db 0x0F
    NOP

    MOV AX, 0xB00B
    MOV BX, 0xBEAD
    OR AX, BX
    db 0x0F
    NOP

    MOV AX, 0x0DAD
    OR AX, 0x00AD
    db 0x0F
    NOP

    MOV AX, 0x0DAD
    OR AL, 0x00
    db 0x0F
    NOP

    hlt
