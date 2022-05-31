start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0


    cld
    MOV AX, 0x1000
    MOV ES, AX
    MOV DI, 0
    MOV CX, 0x1
    MOV AX, 0x7777
    REP STOSW
    XCHG AX, AX
    MOV AX, ES
    XCHG AX, AX
    MOV AX, DI
    XCHG AX, AX
    MOV AX, CX
    XCHG AX, AX

    cld
    MOV AX, 0x1000
    MOV ES, AX
    MOV DI, 0
    MOV CX, 0x0
    MOV AX, 0x8888
    REP STOSW
    XCHG AX, AX
    MOV AX, ES
    XCHG AX, AX
    MOV AX, DI
    XCHG AX, AX
    MOV AX, CX
    XCHG AX, AX

    cld
    MOV AX, 0x1000
    MOV ES, AX
    MOV DI, 0
    MOV CX, 0x10
    MOV AX, 0x5555
    REP STOSW
    XCHG AX, AX
    MOV AX, ES
    XCHG AX, AX
    MOV AX, DI
    XCHG AX, AX
    MOV AX, CX
    XCHG AX, AX

    cld
    MOV AX, 0x1000
    MOV DS, AX
    MOV AX, 0x2000
    MOV ES, AX
    MOV DI, 0
    MOV SI, 0
    MOV CX, 2
    REP MOVSW
    XCHG AX, AX
    MOV AX, ES
    XCHG AX, AX
    MOV AX, DI
    XCHG AX, AX
    MOV AX, CX
    XCHG AX, AX

    cld
    MOV AX, 0x1000
    MOV DS, AX
    MOV AX, 0x2000
    MOV ES, AX
    MOV DI, 0
    MOV SI, 0
    MOV CX, 4
    REP MOVSW
    XCHG AX, AX
    MOV AX, ES
    XCHG AX, AX
    MOV AX, DI
    XCHG AX, AX
    MOV AX, DS
    XCHG AX, AX
    MOV AX, SI
    XCHG AX, AX
    MOV AX, CX
    XCHG AX, AX

    MOV CX, 0
    REP MOVSW
    XCHG AX, AX
    MOV AX, ES
    XCHG AX, AX
    MOV AX, DI
    XCHG AX, AX
    MOV AX, DS
    XCHG AX, AX
    MOV AX, SI
    XCHG AX, AX
    MOV AX, CX
    XCHG AX, AX

    MOV CX, 1
    REP MOVSW
    XCHG AX, AX
    MOV AX, ES
    XCHG AX, AX
    MOV AX, DI
    XCHG AX, AX
    MOV AX, DS
    XCHG AX, AX
    MOV AX, SI
    XCHG AX, AX
    MOV AX, CX
    XCHG AX, AX

    MOV DI, 0
    MOV SI, 0
    MOV CX, 0xF
    REP MOVSW
    XCHG AX, AX
    MOV AX, ES
    XCHG AX, AX
    MOV AX, DI
    XCHG AX, AX
    MOV AX, DS
    XCHG AX, AX
    MOV AX, SI
    XCHG AX, AX
    MOV AX, CX
    XCHG AX, AX

    ;; backward
    std
    MOV AX, 0x1000
    MOV ES, AX
    MOV DI, 0
    MOV CX, 0x10
    MOV AX, 0x5551
    REP STOSW
    XCHG AX, AX
    MOV AX, ES
    XCHG AX, AX
    MOV AX, DI
    XCHG AX, AX
    MOV AX, DS
    XCHG AX, AX
    MOV AX, SI
    XCHG AX, AX
    MOV AX, CX
    XCHG AX, AX
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
    XCHG AX, AX
    MOV AX, ES
    XCHG AX, AX
    MOV AX, DI
    XCHG AX, AX
    MOV AX, DS
    XCHG AX, AX
    MOV AX, SI
    XCHG AX, AX
    MOV AX, CX
    XCHG AX, AX

    ;; byte
    cld
    MOV AX, 0x1500
    MOV ES, AX
    MOV DI, 0
    MOV CX, 0x10
    MOV AX, 0x66
    REP STOSB
    XCHG AX, AX
    MOV AX, ES
    XCHG AX, AX
    MOV AX, DI
    XCHG AX, AX
    MOV AX, DS
    XCHG AX, AX
    MOV AX, SI
    XCHG AX, AX
    MOV AX, CX
    XCHG AX, AX
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
    XCHG AX, AX
    MOV AX, ES
    XCHG AX, AX
    MOV AX, DI
    XCHG AX, AX
    MOV AX, DS
    XCHG AX, AX
    MOV AX, SI
    XCHG AX, AX
    MOV AX, CX
    XCHG AX, AX

    MOV BX, 0x7000
    MOV DS, BX
    MOV BX, 0x0000
    MOV word [BX], 0x4455
    MOV word [BX+2], 0x7788
    LDS DI, [BX]
    MOV AX, 0x8000
    MOV DS, AX
    MOV word [BX], 0x3366
    MOV word [BX+2], 0x1122
    LDS SI, [BX]
    XCHG AX, AX
    MOV AX, ES
    XCHG AX, AX
    MOV AX, DI
    XCHG AX, AX
    MOV AX, DS
    XCHG AX, AX
    MOV AX, SI
    XCHG AX, AX
    MOV AX, CX
    XCHG AX, AX

    cld
    MOV AX, 0x1000
    MOV ES, AX
    MOV DI, 0
    MOV CX, 0x9
    MOV AX, 0x7777
    REP STOSW
    XCHG AX, AX
    MOV AX, ES
    XCHG AX, AX
    MOV AX, DI
    XCHG AX, AX
    MOV AX, DS
    XCHG AX, AX
    MOV AX, SI
    XCHG AX, AX
    MOV AX, CX
    XCHG AX, AX
    MOV AX, 0x8989
    STOSW
    XCHG AX, AX
    MOV AX, ES
    XCHG AX, AX
    MOV AX, DI
    XCHG AX, AX
    MOV AX, DS
    XCHG AX, AX
    MOV AX, SI
    XCHG AX, AX
    MOV AX, CX
    XCHG AX, AX

    cld
    MOV AX, 0x2000
    MOV ES, AX
    MOV DI, 0
    MOV CX, 0xA
    MOV AX, 0x7777
    REP STOSW
    XCHG AX, AX
    MOV AX, ES
    XCHG AX, AX
    MOV AX, DI
    XCHG AX, AX
    MOV AX, DS
    XCHG AX, AX
    MOV AX, SI
    XCHG AX, AX
    MOV AX, CX
    XCHG AX, AX

    MOV AX, 0x1000
    MOV DS, AX
    MOV DI, 0
    MOV AX, 0x2000
    MOV ES, AX
    MOV SI, 0
    MOV CX, 0xD
    REP CMPSW
    XCHG AX, AX
    MOV AX, ES
    XCHG AX, AX
    MOV AX, DI
    XCHG AX, AX
    MOV AX, DS
    XCHG AX, AX
    MOV AX, SI
    XCHG AX, AX
    MOV AX, CX
    XCHG AX, AX

    ; bytes
    cld
    MOV AX, 0x1000
    MOV ES, AX
    MOV DI, 0
    MOV CX, 0x9
    MOV AX, 0x7777
    REP STOSB
    XCHG AX, AX
    MOV AX, ES
    XCHG AX, AX
    MOV AX, DI
    XCHG AX, AX
    MOV AX, DS
    XCHG AX, AX
    MOV AX, SI
    XCHG AX, AX
    MOV AX, CX
    XCHG AX, AX

    MOV AL, 0x19
    STOSB
    STOSB
    MOV AL, 0x18
    STOSB
    MOV AL, 0x17
    STOSB
    XCHG AX, AX
    MOV AX, ES
    XCHG AX, AX
    MOV AX, DI
    XCHG AX, AX
    MOV AX, DS
    XCHG AX, AX
    MOV AX, SI
    XCHG AX, AX
    MOV AX, CX
    XCHG AX, AX

    cld
    MOV AX, 0x2000
    MOV ES, AX
    MOV DI, 0
    MOV CX, 0xA
    MOV AX, 0x7777
    REP STOSB
    XCHG AX, AX
    MOV AX, ES
    XCHG AX, AX
    MOV AX, DI
    XCHG AX, AX
    MOV AX, DS
    XCHG AX, AX
    MOV AX, SI
    XCHG AX, AX
    MOV AX, CX
    XCHG AX, AX

    MOV AX, 0x1000
    MOV DS, AX
    MOV DI, 0
    MOV AX, 0x2000
    MOV ES, AX
    MOV SI, 0
    MOV CX, 0xD
    REP CMPSB
    XCHG AX, AX
    MOV AX, ES
    XCHG AX, AX
    MOV AX, DI
    XCHG AX, AX
    MOV AX, DS
    XCHG AX, AX
    MOV AX, SI
    XCHG AX, AX
    MOV AX, CX
    XCHG AX, AX

    ; scasb
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

    MOV DI, 0
    MOV CX, 100
    MOV AL, 0x0
    REPNZ SCASB

    XCHG AX, AX
    MOV AX, ES
    XCHG AX, AX
    MOV AX, DI
    XCHG AX, AX
    MOV AX, DS
    XCHG AX, AX
    MOV AX, SI
    XCHG AX, AX
    MOV AX, CX
    XCHG AX, AX

    ; LODS CHECKS
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
    REP LODSB

    XCHG AX, AX
    MOV AX, ES
    XCHG AX, AX
    MOV AX, DI
    XCHG AX, AX
    MOV AX, DS
    XCHG AX, AX
    MOV AX, SI
    XCHG AX, AX
    MOV AX, CX
    XCHG AX, AX

    LODSB
    XCHG AX, AX
    MOV AX, ES
    XCHG AX, AX
    MOV AX, DI
    XCHG AX, AX
    MOV AX, DS
    XCHG AX, AX
    MOV AX, SI
    XCHG AX, AX
    MOV AX, CX
    XCHG AX, AX

    LODSW
    XCHG AX, AX
    MOV AX, ES
    XCHG AX, AX
    MOV AX, DI
    XCHG AX, AX
    MOV AX, DS
    XCHG AX, AX
    MOV AX, SI
    XCHG AX, AX
    MOV AX, CX
    XCHG AX, AX

    ;mov dx, hello1
    ;PUSH CS
    ;POP DS
    ;LDS DI, hello1
    ;LES SI, hello2
    ;db 0x0F
    ;NOP
;
    ;cld
    ;mov   cx, 100
    ;rep   cmpsb
    ;db 0x0F
    ;NOP

;    MOV AX, 0x0000      ; load one segment into DS
;    MOV DS,AX           ; DS points to SEG_D
;    MOV AX, 0x2000      ; load another segment into ES
;    MOV ES,AX           ; ES points to SEG_E
;
;    MOV CX, 12
;    MOVSB
;
    hlt



; Data

