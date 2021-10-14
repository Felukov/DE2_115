start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0
    db 0x0F
    NOP

    cld
    MOV AX, 0x1000
    MOV ES, AX
    MOV DI, 0
    MOV CX, 0x10
    MOV AX, 0x5555
    REP STOSW
    db 0x0F
    NOP

    cld
    MOV AX, 0x1000
    MOV DS, AX
    MOV AX, 0x2000
    MOV ES, AX
    MOV DI, 0
    MOV SI, 0
    MOV CX, 2
    REP MOVSW
    db 0x0F
    NOP

    cld
    MOV AX, 0x1000
    MOV DS, AX
    MOV AX, 0x2000
    MOV ES, AX
    MOV DI, 0
    MOV SI, 0
    MOV CX, 4
    REP MOVSW
    db 0x0F
    NOP

    MOV CX, 0
    REP MOVSW
    db 0x0F
    NOP

    MOV CX, 1
    REP MOVSW
    db 0x0F
    NOP

    MOV DI, 0
    MOV SI, 0
    MOV CX, 0xF
    REP MOVSW
    db 0x0F
    NOP

    ;; backward
    std
    MOV AX, 0x1000
    MOV ES, AX
    MOV DI, 0
    MOV CX, 0x10
    MOV AX, 0x5555
    REP STOSW
    db 0x0F
    NOP
    ;; backward
    std
    MOV AX, 0x1000
    MOV DS, AX
    MOV AX, 0x2000
    MOV ES, AX
    MOV DI, 0
    MOV SI, 0
    MOV CX, 2
    REP MOVSW
    db 0x0F
    NOP

    ;; byte
    cld
    MOV AX, 0x1500
    MOV ES, AX
    MOV DI, 0
    MOV CX, 0x10
    MOV AX, 0x66
    REP STOSB
    db 0x0F
    NOP
    ;;
    cld
    MOV AX, 0x1500
    MOV DS, AX
    MOV AX, 0x2000
    MOV ES, AX
    MOV DI, 0
    MOV SI, 0
    MOV CX, 0x10
    REP MOVSB
    db 0x0F
    NOP

    hlt
