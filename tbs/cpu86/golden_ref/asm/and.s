start:
    ; initialization
    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0

    ; SET SS register somewhere
    MOV AX, 0x300A
    MOV SS, AX

    ; TEST 1
    MOV BP, 0
    MOV AX, 0xFFFF
    MOV word [BP], 0x00AA
    AND [BP], AL
    MOV AH, [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    ; TEST 2
    MOV AX, 0x0AA0
    MOV word [BP], 0xABBA
    AND [BP], AX
    MOV BX, [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    ; TEST 3
    MOV AX, 0xA00A
    MOV word [BP], 0xABBA
    AND AX, [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    ; TEST 4
    MOV AX, 0xC00C
    MOV word [BP], 0xACCA
    AND AL, [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    ; TEST 5
    MOV AX, 0xB00B
    MOV BX, 0xBEAD
    AND AX, BX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    ; TEST 6
    MOV AX, 0x0DAD
    AND AX, 0x00AD
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    ; TEST 6
    MOV AX, 0x0DAD
    AND AL, 0x00
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    HLT
