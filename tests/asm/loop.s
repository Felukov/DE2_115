start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0
    db 0x0F
    NOP

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

    db 0x0F
    NOP

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

    INC word [BP]
    MOV AX, [BP]
    db 0x0F
    NOP

test_jcxz_proc:
    MOV CX, 10

.loop_cx:
    MOV word [BP], CX
    DEC CX
    db 0x0F
    NOP
    JCXZ .loop_exit
    JMP .loop_cx

.loop_exit:
    MOV DX, [BP]
    db 0x0F
    NOP

    HLT
