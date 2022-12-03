start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0

    OUT 0, AX
    MOV AX, 0xF
    IN AX, 0
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV AX, 0xFABA
    MOV DX, 0xF0F0
    OUT DX, AX
    MOV AX, 0xF
    IN AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV AX, 0xFABB
    MOV DX, 0xF0F0
    OUT DX, AL
    MOV AX, 0xF
    IN AL, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    cld
    MOV AX, 0x1000
    MOV DI, 0
    MOV ES, AX
    MOV DS, AX

    MOV AX, 'He'
    STOSW
    MOV AX, 'll'
    STOSW
    MOV AL, 'o'
    STOSB
    MOV AL, 0x0
    STOSB
    MOV AX, 'Wo'
    STOSW
    MOV AX, 'rl'
    STOSW
    MOV AL, 'd'
    STOSB
    MOV AL, 0x0
    STOSB

    MOV SI, 0
    MOV CX, 3
    REP OUTSW

    IN AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    OUTSW
    IN AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT


    MOV DX, 0xFFFF
    IN AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV DX, 0xFFFF
    IN AX, DX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    cld
    MOV AX, 0x1000
    MOV DI, 0
    MOV ES, AX
    MOV DS, AX
    MOV CX, 4
    REP INSW
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    INSW
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    HLT

