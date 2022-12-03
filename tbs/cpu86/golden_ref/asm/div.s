ORG 400h
start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    MOV AX, 12
    MOV DX, -1
    MOV CX, -5
    IDIV CL
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    MOV AX, 12
    MOV DX, 0
    MOV CX, -5
    IDIV CL
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    MOV AX, -12
    MOV DX, 0
    MOV CX, 5
    IDIV CL
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    MOV AX, -12
    MOV DX, 0
    MOV CX, -5
    IDIV CL
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    ;
    MOV AX, 12
    MOV DX, 0
    MOV CX, -5
    IDIV CX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    MOV AX, -12
    MOV DX, 0
    MOV CX, 5
    IDIV CX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    MOV AX, -12
    MOV DX, 0
    MOV CX, -5
    IDIV CX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    ;
    MOV AX, 12
    MOV DX, 0
    MOV CX, 4
    DIV CL
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    MOV AX, 12
    MOV DX, 0
    MOV CX, 4
    DIV CX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    MOV word [BP], 4
    DIV word [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    MOV AX, [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    MOV AX, 0
    MOV DS, AX
    MOV word [0x0000], div_zero_handler
    MOV word [0x0002], AX

    MOV AX, 0xFF
    MOV DX, 0x00
    MOV CX, 0x00
    DIV CX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    HLT

div_zero_handler:
    MOV CX, 1
    iret


    hlt



; Data

