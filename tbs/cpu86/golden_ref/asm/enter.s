ORG 400h
start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0x10


    MOV byte [BP], AL
    MOV AL, [BP]

    ENTER 4, 5
    JMP JUMP_TEST
JUMP_TEST:
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    ENTER 4, 1
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    ENTER 4, 0
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    ENTER 4, 31
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    MOV AX, [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    LEAVE
    MOV AX, [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    HLT

