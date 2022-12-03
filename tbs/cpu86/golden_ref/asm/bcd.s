start:

    ; initialization
    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0

    XOR AX, AX
    MOV AX, 5
    ADD AX, 7
    AAA
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    MOV AX, 0x409
    AAD
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    MOV CX, 3
    DIV CX

    MOV BL, AH
    AAM
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    MOV AX, 0x103
    SUB AL, 0x5
    AAS
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    MOV AL, 0x08
    SBB AL, 0x11
    DAS
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    MOV AL, 0x17
    SBB AL, 0x30
    DAS
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    MOV AL, 0x24
    SBB AL, 0x19
    DAS
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    MOV AL, 0x08
    ADC AL, 0x11
    DAA
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    MOV AL, 0x17
    ADC AL, 0x30
    DAA
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    MOV AL, 0x24
    ADC AL, 0x19
    DAA
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    HLT

