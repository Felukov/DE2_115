start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0


test_loop_10_times:
    MOV CX, 10
    MOV AX, 0x0
    MOV BX, 0xFFFF
    MOV word [BP], 0x0
.loop1:
    INC AX
    DEC BX
    INC word [BP]
    LOOP .loop1
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV BX, AX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, [BP]            ; AX = [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    LAHF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

test_loop_1_time:
    MOV CX, 1
    MOV AX, 0x0
    MOV BX, 0xFFFF
    MOV word [BP], 0x0
.loop2:
    INC AX
    DEC BX
    INC word [BP]
    LOOP .loop2
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV BX, AX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, [BP]            ; AX = [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    LAHF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

test_jcxz_proc:
    MOV CX, 10

.loop_cx:
    MOV word [BP], CX
    DEC CX
    MOV AX, CX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    JCXZ .loop_exit
    JMP .loop_cx

.loop_exit:
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV BX, AX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, [BP]            ; AX = [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    LAHF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

test_loop_ne_proc:
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

    MOV AX, 0x1000
    MOV SI, -1
    MOV CX, 255

.search:
    INC SI
    CMP byte [SI], 0
    LAHF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    LOOPNE .search

    LAHF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

test_loop_e_proc:
    cld
    MOV AX, 0x1000
    MOV DI, 0
    MOV ES, AX
    MOV DS, AX

    MOV CX, 10
.loop_cx:
    MOV AX, 0
    STOSW
    LOOP .loop_cx

    MOV AX, 0xF
    STOSW

    MOV AX, 0x1000
    MOV SI, -1
    MOV CX, 255

.search:
    INC SI
    CMP byte [SI], 0
    LAHF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    LOOPE .search

    LAHF
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    HLT
