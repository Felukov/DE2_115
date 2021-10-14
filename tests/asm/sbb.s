start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0
    db 0x0F
    NOP

    MOV AX, 0x330A
    MOV SS, AX
    ; 0xFE + 0x1 = 0xFF
    CLC
    MOV AX, 0xFFFE
    MOV BP, 0
    MOV word [BP], 0x0001
    SBB [BP], AL
    MOV AX, [BP]
    db 0x0F
    NOP

    ; 0xFE + 0x1 + 0x1 = 0x00
    STC
    MOV AX, 0xFFFE
    MOV BP, 0
    MOV word [BP], 0x0001
    SBB [BP], AL
    MOV AX, [BP]
    db 0x0F
    NOP

    CLC
    MOV BP, 0
    MOV AX, 0xFFFE
    MOV word [BP], 0x0001
    SBB [BP], AL
    SBB AX, 0x0001
    db 0x0F
    NOP

    STC
    MOV BP, 0
    MOV AX, 0xFFFE
    MOV word [BP], 0x0001
    SBB [BP], AL
    SBB AX, 0x0001
    db 0x0F
    NOP

    STC
    MOV BP, 0
    MOV AX, 0xFFFE
    MOV word [BP], 0x0001
    SBB [BP], AL
    SBB AX, 0x0001
    MOV AH, [BP]
    db 0x0F
    NOP

    MOV AX, 0x5555
    MOV word [BP], 0x0001
    SBB [BP], AX
    MOV BX, [BP]
    db 0x0F
    NOP

    MOV AX, 0x5559
    SBB AX, AX
    MOV AX, 0x6666
    MOV word [BP], 0x0001
    SBB AX, [BP]
    db 0x0F
    NOP

    MOV AX, 0x7777
    MOV word [BP], 0x0001
    ADC AL, [BP]
    db 0x0F
    NOP

    MOV AX, 0x8888
    SBB AX, 0x0002
    db 0x0F
    NOP

    MOV AX, 0x9999
    SBB AL, 0x01
    db 0x0F
    NOP

    MOV AX, 0x00FF
    SBB AL, 1
    db 0x0F
    NOP
    ; db 0x0F
    HLT
