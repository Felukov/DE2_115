start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0
    XCHG AX, AX             ; FORCE CHECK AX CONTENT


    MOV AX, 0xAAAA
    MOV BX, 0xBBBB
    MOV CX, 0xCCCC
    MOV DX, 0xDDDD
    MOV SI, 0xEEEE
    MOV BP, 0xFFFF
    MOV DI, 0x8888
    MOV SP, 0xFFFE

    INC AX
    INC BX
    INC CX
    INC DX
    INC BP
    INC SP
    INC SI
    INC DI
    DEC AX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    DEC BX
    MOV AX, BX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    DEC CX
    MOV AX, CX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    DEC DX
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    DEC BP
    MOV AX, BP
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    DEC SP
    MOV AX, SP
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    DEC SI
    MOV AX, SI
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    DEC DI
    MOV AX, DI
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    INC AL
    INC AH
    INC BL
    INC BH
    INC CL
    INC CH
    INC DL
    INC DH
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, BX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, CX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    DEC AL
    DEC AH
    DEC BL
    DEC BH
    DEC CL
    DEC CH
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, BX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, CX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT


    MOV AX, 0x2000
    MOV DS, AX
    MOV SS, AX
    MOV BP, 0
    MOV AX, 0xFF
    MOV [BP], AX
    INC word [BP]
    DEC word [BP]
    MOV AX, [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    INC byte [BP]
    DEC byte [BP]
    MOV AX, [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT


    HLT
