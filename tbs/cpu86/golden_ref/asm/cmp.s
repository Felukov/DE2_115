start:
; initialization
    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0

; SET SS register somewhere
    MOV AX, 0x3000
    MOV SS, AX

; TEST 1
    MOV BP, 0
    MOV AX, 0x4444
    MOV word [BP], 0x0001
    CMP [BP], AL
    MOV AH, [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

; TEST 2
    MOV AX, 0x5555
    MOV word [BP], 0x0001
    CMP [BP], AX
    MOV BX, [BP]
    MOV AX, BX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

; TEST 3
    MOV AX, 0x5555
    ADD AX, AX
    MOV AX, 0x6666
    MOV word [BP], 0x0001
    CMP AX, [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

; TEST 4
    MOV AX, 0x7777
    MOV word [BP], 0x0001
    CMP AL, [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

; TEST 5
    MOV AX, 0x8888
    CMP AX, 0x0002
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

; TEST 6
    MOV AX, 0x9999
    CMP AL, 0x01
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

; TEST 7
    MOV AX, 0x00FF
    CMP AL, 1
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    HLT
