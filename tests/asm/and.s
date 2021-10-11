start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0
    db 0x0F
    NOP

    MOV AX, 0x300A
    MOV SS, AX
    MOV BP, 0
    MOV AX, 0xFFFF
    MOV word [BP], 0x00AA
    AND [BP], AL
    db 0x0F
    NOP

    MOV AH, [BP]
    MOV AX, 0x0AA0
    MOV word [BP], 0xABBA
    AND [BP], AX
    MOV BX, [BP]
    db 0x0F
    NOP

    MOV AX, 0xA00A
    MOV word [BP], 0xABBA
    AND AX, [BP]
    db 0x0F
    NOP

    MOV AX, 0xC00C
    MOV word [BP], 0xACCA
    AND AL, [BP]
    db 0x0F
    NOP

    MOV AX, 0xB00B
    MOV BX, 0xBEAD
    AND AX, BX
    db 0x0F
    NOP

    MOV AX, 0x0DAD
    AND AX, 0x00AD
    db 0x0F
    NOP

    MOV AX, 0x0DAD
    AND AL, 0x00
    db 0x0F
    NOP

    HLT