start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0

    MOV AX, 0x310A
    MOV SS, AX
    MOV BP, 0
    MOV AX, 0xFFFF
    MOV word [BP], 0x00AA
    OR [BP], AL
    MOV AH, [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    MOV AX, 0x0AA0
    MOV word [BP], 0xABBA
    OR [BP], AX
    MOV BX, [BP]
    MOV BX, AX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    MOV AX, 0xA00A
    MOV word [BP], 0xABBA
    OR AX, [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    MOV AX, 0xC00C
    MOV word [BP], 0xACCA
    OR AL, [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    MOV AX, 0xB00B
    MOV BX, 0xBEAD
    OR AX, BX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    MOV AX, 0x0DAD
    OR AX, 0x00AD
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    MOV AX, 0x0DAD
    OR AL, 0x00
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    hlt
