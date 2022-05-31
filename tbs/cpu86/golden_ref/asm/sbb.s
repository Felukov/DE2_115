start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0

    MOV AX, 0x330A
    MOV SS, AX
    ; 0xFE + 0x1 = 0xFF
    CLC
    MOV AX, 0xFFFE
    MOV BP, 0
    MOV word [BP], 0x0001
    SBB [BP], AL
    MOV AX, [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    ; 0xFE + 0x1 + 0x1 = 0x00
    STC
    MOV AX, 0xFFFE
    MOV BP, 0
    MOV word [BP], 0x0001
    SBB [BP], AL
    MOV AX, [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    CLC
    MOV BP, 0
    MOV AX, 0xFFFE
    MOV word [BP], 0x0001
    SBB [BP], AL
    SBB AX, 0x0001
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    STC
    MOV BP, 0
    MOV AX, 0xFFFE
    MOV word [BP], 0x0001
    SBB [BP], AL
    SBB AX, 0x0001
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    STC
    MOV BP, 0
    MOV AX, 0xFFFE
    MOV word [BP], 0x0001
    SBB [BP], AL
    SBB AX, 0x0001
    MOV AH, [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    MOV AX, 0x5555
    MOV word [BP], 0x0001
    SBB [BP], AX
    MOV BX, [BP]
    MOV AX, BX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    MOV AX, 0x5559
    SBB AX, AX
    MOV AX, 0x6666
    MOV word [BP], 0x0001
    SBB AX, [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    MOV AX, 0x7777
    MOV word [BP], 0x0001
    ADC AL, [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    MOV AX, 0x8888
    SBB AX, 0x0002
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    MOV AX, 0x9999
    SBB AL, 0x01
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    MOV AX, 0x00FF
    SBB AL, 1
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    ; db 0x0F
    HLT
