start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0

    MOV AX, 0x320A
    MOV SS, AX
    MOV BP, 0
    MOV AX, 0xFFFF
    MOV word [BP], 0x00AA
    XOR [BP], AL
    MOV AH, [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV AX, 0x0AA0
    MOV word [BP], 0xABBA
    XOR [BP], AX
    MOV BX, [BP]
    MOV BX, AX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV AX, 0xA00A
    MOV word [BP], 0xABBA
    XOR AX, [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV AX, 0xC00C
    MOV word [BP], 0xACCA
    XOR AL, [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV AX, 0xB00B
    MOV BX, 0xBEAD
    XOR AX, BX
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV AX, 0x0DAD
    XOR AX, 0x00AD
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    MOV AX, 0x0DAD
    XOR AL, 0x00
    XCHG AX, AX             ; FORCE CHECK AX CONTENT

    HLT
