ORG 400h
start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0

    ; PREPARE MEMORY
    MOV AX, 100
    MOV [BP], AX
    MOV AX, 200
    MOV [BP+2], AX

    ; TEST 1 - SHOULD PASS
    MOV AX, 150
    BOUND AX, [BP]
    NOP

    ; PREPARE INTERRUPT HANDLER
    MOV AX, 0
    MOV DS, AX
    MOV word [0x0014], bound_exception_handler
    MOV word [0x0016], AX

    ; TEST 2 - SHOULD FAIL
    MOV AX, 50
    BOUND AX, [BP]

    ; PREPARE MEMORY
    MOV AX, -200
    MOV [BP], AX
    MOV AX, -100
    MOV [BP+2], AX
    ; TEST 2 - SHOULD PASS
    MOV AX,-150
    BOUND AX, [BP]
    NOP
    ; TEST 2 - SHOULD FAIL
    MOV AX,-350
    BOUND AX, [BP]

    MOV AX, 1111
    XCHG AX, AX             ; FORCE CHECK AX

    NOP
    HLT

bound_exception_handler:
    NOP
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX
    PUSH BP
    MOV BP, SP
    ADD word [BP+2], 3      ; START ON THE NEXT INSTRUCTION AFTER RETURN
    POP BP
    IRET


