ORG 400h
start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0
    MOV BX, 0

    mov dx, 0x333
L$4:
    in          al,dx
    sub         ah,ah
    inc         bx
    cmp         bx,0x000a
    jb          L$4


    MOV AX, 0x5000
    MOV ES, AX
    MOV word [ES:0x0], 0

    ; setting div zero handler
    MOV AX, 0
    MOV DS, AX
    MOV word [0x0000], div_zero_handler
    MOV word [0x0002], AX
    ; setting bound handler
    MOV AX, 0
    MOV DS, AX
    MOV word [0x0014], bound_exception_handler
    MOV word [0x0016], AX
    ; setting trap handler
    MOV AX, 0
    MOV DS, AX
    MOV AX, 0
    MOV word [0x0004], trap_handler
    MOV word [0x0006], AX
    ; setting trap
    PUSHF                           ; Push flags on stack
    MOV BP,SP                       ; Copy SP to BP for use as index
    OR WORD [BP+0], 0x0100          ; Set TF flag
    POPF                            ; Restore flag register

    ; after the instruction there should be a trap
    MOV AL, [0x015]
    NOP
    NOP
    JMP .test_jump
    NOP
    NOP
    NOP
.test_jump:
    MOV CX, 0x00
    DIV CX
    ; PREPARE MEMORY FOR BOUND
    MOV AX, 100
    MOV [BX], AX
    MOV AX, 200
    MOV [BX+2], AX
    ; BOUND - SHOULD FAIL
    MOV AX, 50
    BOUND AX, [BX]
    NOP
    NOP
    NOP
    NOP
    HLT

trap_handler:
    PUSHA                   ; Stack: Ret, Flags, AX, CX, DX, BX, SP, BP, SI, DI
    PUSH DS
    PUSH ES                 ; Stack: Ret, Flags, AX, CX, DX, BX, SP, BP, SI, DI, DS, ES

    INC word [ES:0x0]
    MOV AX, [ES:0x0]
    NOP
    MOV BP,SP               ; Stack: Ret, Flags, AX, CX, DX, BX, SP, BP, SI, DI, DS, ES
    MOV BP,[BP+10]          ; Stored SP

    CMP AX, 15

    .if_ax_eq_15:
        JNE .if_ax_not_eq_15
        AND WORD [BP+4], 0xFEFF ; Clear TF flag in the stored Flag register
        JMP .end_if
    .if_ax_not_eq_15:
        OR WORD [BP+4],  0x0100 ; Set TF flag in the stored Flag register
    .end_if:

    POP ES
    POP DS
    POPA
    IRET                    ; continue execution for ONE instruction, then calling ISR again.

div_zero_handler:
    MOV CX, 1
    iret

bound_exception_handler:
    MOV AX, 150
    IRET
