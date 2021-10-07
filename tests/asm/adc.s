start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV BP, 0
    db 0x0F

    MOV CX, 0xBBAA
    MOV [BP], CX
    MOV CX, 0xFF03
    MOV [BP+7], CX
    MOV DX, [BP+7]
    MOV AX, 0xFF01
    MOV [BP+2], AX
    MOV BX, [BP+2]
    MOV BX, 0xFF02
    MOV [BP+4], BX
    MOV AX, [BP+4]
    db 0x0F

    MOV AX, 0x330A
    MOV SS, AX
    MOV BP, 0
    MOV AX, 0xFFFE
    MOV word [BP], 0x0001
    ADC [BP], AL
    STC
    MOV BP, 0
    MOV AX, 0xFFFE
    MOV word [BP], 0x0001
    ADC [BP], AL
    ADC AX, 0x0001
    MOV AH, [BP]
    MOV AX, 0x5555
    MOV word [BP], 0x0001
    ADC [BP], AX
    MOV BX, [BP]
    MOV AX, 0x5559
    ADC AX, AX
    MOV AX, 0x6666
    MOV word [BP], 0x0001
    ADC AX, [BP]
    MOV AX, 0x7777
    MOV word [BP], 0x0001
    ADC AL, [BP]
    MOV AX, 0x8888
    ADC AX, 0x0002
    MOV AX, 0x9999
    ADC AL, 0x01
    MOV AX, 0x00FF
    ADC AL, 1
    db 0x0F
    ; db 0x0F
    HLT
