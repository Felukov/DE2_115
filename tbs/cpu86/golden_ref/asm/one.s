start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0

    ; NEG REG WORD

    MOV AX, 0x0001
    NEG AX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    LAHF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV BX, 0x0002
    NEG BX
    MOV AX, BX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    LAHF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV CX, 0x3333
    NEG CX
    MOV AX, CX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    LAHF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV DX, 0x4444
    NEG DX
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    LAHF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV BP, 0x5555
    NEG BP
    MOV AX, BP
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    LAHF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV SP, 0xFFFE
    NEG SP
    MOV AX, SP
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    LAHF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    NEG SP
    MOV AX, SP
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    LAHF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV DI, 0x0000
    NEG DI
    MOV AX, DI
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    LAHF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV SI, 0xFFFF
    NEG SI
    MOV AX, SI
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    LAHF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV CX, 0xFFFF
    NEG CL
    MOV AX, CX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    LAHF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV CX, 0xAAFF
    NEG CH
    MOV AX, CX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    LAHF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV BP, 0
    MOV word [BP], 0x0001
    NEG word [BP]
    MOV AX, [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    LAHF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    NEG byte [BP]
    MOV AX, [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    LAHF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    ; not tests
    MOV AX, 0x0101
    NOT AX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    LAHF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV DX, 0x0101
    NOT DL
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    LAHF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    NOT DH
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    LAHF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV BP, 0
    MOV word [BP], 0xFAFA
    NOT word [BP]
    NOT word [BP]
    NOT byte [BP]
    MOV AX, [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    LAHF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    ; test
    MOV AX, 0x0101
    TEST AX, 0x0001
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    LAHF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    TEST AL, 0x01
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    LAHF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    TEST AH, 0x01
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    LAHF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV BX, 0x0011
    TEST BX, 0x0011
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    LAHF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV BX, 0x0011
    TEST BH, 0x0011
    MOV AX, BX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    LAHF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV BP, 0
    MOV word [BP], 0xFFFF
    TEST byte [BP], 0xFF
    MOV AL, [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    LAHF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    TEST word [BP], 0xFFFF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    LAHF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    TEST word [BP], 0x12
    MOV AX, [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    LAHF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV AX, 0x0202
    MOV BX, 0x0303
    TEST AL, BL
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    LAHF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    TEST AX, BX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    LAHF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    hlt
