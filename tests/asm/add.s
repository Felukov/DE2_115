start:
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

    HLT
