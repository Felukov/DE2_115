start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0

    PUSHF
    LAHF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV AX, 0x6789
    SAHF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    POPF
    PUSHF
    POPF
    LAHF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    HLT
