ORG 400h
start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0

test_short_jmp_proc:
    JMP .test_short_jmp

    MOV AX, 0x5555

.test_short_jmp:
    MOV [BP], AX
    MOV AX, [BP]            ; AX = [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

test_short_jmp16_proc:
    JMP word .test_short_jmp

    MOV AX, 04444

.test_short_jmp:
    MOV [BP], AX
    MOV AX, [BP]            ; AX = [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

test_far_jmp_proc:
    JMP 0000h:.test_far_jmp

    MOV AX, 0x6666

.test_far_jmp:
    MOV [BP], AX
    MOV AX, [BP]            ; AX = [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

test_reg_jmp_proc:
    MOV AX, .test_reg_jmp

    JMP AX
    MOV AX, 0x7777

.test_reg_jmp:
    MOV [BP], AX
    MOV AX, [BP]            ; AX = [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

test_mem_jmp_proc:
    MOV AX, .test_mem_jmp
    MOV [BP], AX

    JMP near [BP]

    MOV AX, 0x8888

.test_mem_jmp:
    MOV [BP], AX
    MOV AX, [BP]            ; AX = [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

test_mem_jmp_far_proc:
    MOV AX, .test_mem_far_jmp
    MOV [BP], AX
    MOV AX, CS
    MOV [BP+2], AX

    JMP far [BP]
    MOV AX, 0x9888

.test_mem_far_jmp:
    MOV [BP], AX
    MOV AX, [BP]            ; AX = [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    HLT

