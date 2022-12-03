start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0

    mov word [BP], 0
    mov AX, [BP]

    MOV AL, 0x2
    IMUL AL
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV DX, 0xFEEF

    IMUL AX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV BX, 0x3
    IMUL BX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV CX, 0x4
    IMUL CX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV DX, 0x2

    IMUL BX, DX, 0x2
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    IMUL AX, BX, 0xF000
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV AX, 0xF000
    MOV BX, 0x2
    IMUL BX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV word [BP], 0x1234
    IMUL word [BP]
    IMUL byte [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV DX, 0x2
    IMUL DX, 0x2
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    IMUL AX, DX, 0xFFF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    IMUL CX, 0xFFF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    IMUL CX, [BP], 0x2
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    IMUL SI, [BP], 0x2AA
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT


    hlt