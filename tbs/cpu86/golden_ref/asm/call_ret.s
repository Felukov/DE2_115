ORG 400h
start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0
    XCHG AX, AX             ; FORCE CHECK AX

test_call_near_ret_near_proc:
    PUSH BP
    PUSH 4
    PUSH 10
    CALL sum_proc
    ADD SP, 4
    POP BP
    MOV [BP], AX

test_call_near_ret_near_imm16_proc:
    PUSH BP
    PUSH 3
    PUSH 2
    CALL sum_proc_ret_imm16
    POP BP
    MOV [BP], AX

test_call_near_indirect_reg_ret_near_imm16_proc:
    PUSH BP
    PUSH 33
    PUSH 24
    MOV AX, sum_proc_ret_imm16
    CALL AX
    POP BP
    MOV [BP], AX

test_call_near_indirect_mem_ret_near_imm16_proc:
    PUSH BP
    PUSH 31
    PUSH 21
    MOV AX, sum_proc_ret_imm16
    MOV DI, 0
    MOV [DI], AX
    CALL [DI]
    POP BP
    MOV [BP], AX

test_call_far_direct_ret_imm16_proc:
    PUSH BP
    PUSH 44
    PUSH 33
    CALL 0x000:sum_far_proc_retf
    ADD SP, 4
    POP BP
    MOV [BP], AX

test_call_far_direct_ret_far_imm16_proc:
    PUSH BP
    PUSH 44
    PUSH 33
    CALL 0x000:sum_far_proc_retf_imm16
    POP BP
    MOV [BP], AX

test_call_far_indirect_ret_far_imm16_proc:
    PUSH BP
    PUSH 431
    PUSH 421
    MOV AX, sum_far_proc_retf_imm16
    MOV DI, 0
    MOV [DI], AX
    MOV word [DI+2], 0
    CALL far [DI]
    POP BP
    MOV [BP], AX

    jmp test_end


sum_proc:
    ; FRAME POINTER
    MOV BP, SP
    ; PROCEDURE BODY
    MOV AX, [BP+4]
    MOV BX, [BP+2]
    XCHG AX, AX             ; FORCE CHECK AX
    ADD AX, BX
    ; RETURN
    RET

sum_proc_ret_imm16:
    ; FRAME POINTER
    MOV BP, SP
    ; ALLOCATE 4 BYTES
    SUB SP, 4
    ; PROCEDURE BODY
    MOV word [BP-2], 25
    MOV word [BP-4], 15
    XOR AX, AX
    ADD word AX, [BP-4]
    ADD word AX, [BP-2]
    ADD word AX, [BP+4]
    ADD word AX, [BP+2]
    XCHG AX, AX             ; FORCE CHECK AX
    ; CLEAR LOCAL STACK AND RETURN
    ADD SP, 4
    RET 4

sum_far_proc_retf_imm16:
    ; FRAME POINTER
    MOV BP, SP
    ; ALLOCATE 4 BYTES
    SUB SP, 4
    ; PROCEDURE BODY
    MOV word [BP-2], 11
    MOV word [BP-4], 16
    XOR AX, AX
    ADD word AX, [BP-4]
    ADD word AX, [BP-2]
    ADD word AX, [BP+6]
    ADD word AX, [BP+4]
    XCHG AX, AX             ; FORCE CHECK AX
    ; CLEAR LOCAL STACK AND RETURN
    ADD SP, 4
    RETF 4

sum_far_proc_retf:
    ; FRAME POINTER
    MOV BP, SP
    ; ALLOCATE 4 BYTES
    SUB SP, 4
    ; PROCEDURE BODY
    MOV word [BP-2], 11
    MOV word [BP-4], 16
    XOR AX, AX
    ADD word AX, [BP-4]
    ADD word AX, [BP-2]
    ADD word AX, [BP+6]
    ADD word AX, [BP+4]
    XCHG AX, AX             ; FORCE CHECK AX
    ; CLEAR LOCAL STACK AND RETURN
    ADD SP, 4
    RETF

test_end:
    MOV AX, 5555
    XCHG AX, AX             ; FORCE CHECK AX

    HLT

