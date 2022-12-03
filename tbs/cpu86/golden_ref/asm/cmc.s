start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0
    XCHG AX, AX             ; FORCE CHECK AX

    clc
    PUSHF
    POP AX
    XCHG AX, AX             ; FORCE CHECK AX

    stc
    PUSHF
    POP AX
    XCHG AX, AX             ; FORCE CHECK AX

    cmc
    PUSHF
    POP AX
    XCHG AX, AX             ; FORCE CHECK AX

    clc
    cmc
    cmc
    PUSHF
    POP AX
    XCHG AX, AX             ; FORCE CHECK AX

    clc
    cmc
    PUSHF
    POP AX
    XCHG AX, AX             ; FORCE CHECK AX

    hlt
