start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0


    MOV AX, 0x0000
    MOV AL, 0xF0
    CBW
    XCHG AX, AX             ; FORCE CHECK AX CONTENT


    CWD
    XCHG AX, AX             ; FORCE CHECK AX CONTENT


    MOV word [BP], 0x0000
    LEA AX, [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV BP, 0x100
    LEA AX, [BP+100]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV SI, 0x99
    LEA AX, [SI+100]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV DI, 0x99
    LEA AX, [DI+100]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV SI, 0x88
    LEA AX, [BP+SI+100]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV DI, 0x77
    LEA AX, [BX+DI+100]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT


    LEA AX, [0x0000]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT


    MOV word [BP], 0x0000
    LEA AX, [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV BP, 0x55
    LEA DX, [BP+100]
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV SI, 0x4455
    LEA DX, [SI+100]
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV DI, 0x33DD
    LEA DX, [DI+100]
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV SI, 0x11DD
    MOV BP, 0x1122
    LEA DX, [BP+SI+100]
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV BX, 0xFFFF
    MOV DI, 0x1
    LEA DX, [BX+DI+100]
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT


    LEA DX, [0x0000]
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT


    HLT
