start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0
    db 0x0F
    NOP

    MOV AX, 0x0201

    SHL AL, 1
    db 0x0F
    NOP

    SHL AH, 1
    db 0x0F
    NOP

    SHL AX, 1
    db 0x0F
    NOP

    SHL AL, 2
    db 0x0F
    NOP

    SHL AH, 2
    db 0x0F
    NOP

    SHL AX, 3
    db 0x0F
    NOP

    SHL AX, 2
    db 0x0F
    NOP

    SHL AX, 2
    db 0x0F
    NOP

    MOV BX, 0x01FF
    MOV CX, 1
    SHL BX, 1
    db 0x0F
    NOP

    MOV BX, 0x01FF
    SHL BX, 2
    db 0x0F
    NOP

    SHL BX, CL
    db 0x0F
    NOP

    SHL BL, CL
    db 0x0F
    NOP

    SHL BH, CL
    db 0x0F
    NOP

    MOV word [BP], 0x0301
    SHL byte [BP], 1
    SHL word [BP], 1
    SHL byte [BP+1], 3

    db 0x0F
    NOP


    MOV AX, 0xF2F1

    SHR AL, 1
    db 0x0F
    NOP

    SHR AH, 1
    db 0x0F
    NOP

    SHR AX, 1
    db 0x0F
    NOP

    SHR AL, 2
    db 0x0F
    NOP

    SHR AH, 2
    db 0x0F
    NOP

    SHR AX, 3
    db 0x0F
    NOP

    SHR AX, 2
    db 0x0F
    NOP

    SHR AX, 2
    db 0x0F
    NOP

    MOV BX, 0x01FF
    MOV CX, 1
    SHR BX, 1
    db 0x0F
    NOP

    MOV BX, 0x01FF
    SHR BX, 2
    db 0x0F
    NOP

    SHR BX, CL
    db 0x0F
    NOP

    SHR BL, CL
    db 0x0F
    NOP

    SHR BH, CL
    db 0x0F
    NOP

    MOV word [BP], 0x0301
    SHR byte [BP], 1
    SHL word [BP], 1
    SHR byte [BP+1], 3

    db 0x0F
    NOP

    MOV AX, 0xFAF1

    SAR AL, 1
    db 0x0F
    NOP

    SAR AH, 1
    db 0x0F
    NOP

    SAR AX, 1
    db 0x0F
    NOP

    SAR AL, 2
    db 0x0F
    NOP

    SAR AH, 2
    db 0x0F
    NOP

    SAR AX, 3
    db 0x0F
    NOP

    SAR AX, 2
    db 0x0F
    NOP

    SAR AX, 2
    db 0x0F
    NOP

    MOV BX, 0x01FF
    MOV CX, 1
    SAR BX, 1
    db 0x0F
    NOP

    MOV BX, 0x01FF
    SAR BX, 2
    db 0x0F
    NOP

    SAR BX, CL
    db 0x0F
    NOP

    SAR BL, CL
    db 0x0F
    NOP

    SAR BH, CL
    db 0x0F
    NOP

    MOV word [BP], 0x0301
    SAR byte [BP], 1
    SHL word [BP], 1
    SAR byte [BP+1], 3

    db 0x0F
    NOP

    MOV AX, 0xFAF1

    db 0x0F
    NOP

    ROR AL, 1
    db 0x0F
    NOP

    ROR AH, 1
    db 0x0F
    NOP

    ROR AX, 1
    db 0x0F
    NOP

    ROR AL, 2
    db 0x0F
    NOP

    ROR AH, 2
    db 0x0F
    NOP

    ROR AX, 3
    db 0x0F
    NOP

    ROR AX, 2
    db 0x0F
    NOP

    ROR AX, 2
    db 0x0F
    NOP

    MOV BX, 0x01FF
    MOV CX, 1
    ROR BX, 1
    db 0x0F
    NOP

    MOV BX, 0x01FF
    ROR BX, 2
    db 0x0F
    NOP

    ROR BX, CL
    db 0x0F
    NOP

    ROR BL, CL
    db 0x0F
    NOP

    ROR BH, CL
    db 0x0F
    NOP

    MOV word [BP], 0x0301
    ROR byte [BP], 1
    SHL word [BP], 1
    ROR byte [BP+1], 3

    db 0x0F
    NOP

    MOV AX, 0xFAF1

    db 0x0F
    NOP

    RCL AL, 1
    db 0x0F
    NOP

    RCL AH, 1
    db 0x0F
    NOP

    RCL AX, 1
    db 0x0F
    NOP

    RCL AL, 2
    db 0x0F
    NOP

    RCL AH, 2
    db 0x0F
    NOP

    RCL AX, 3
    db 0x0F
    NOP

    RCL AX, 2
    db 0x0F
    NOP

    RCL AX, 2
    db 0x0F
    NOP

    MOV BX, 0x01FF
    MOV CX, 1
    RCL BX, 1
    db 0x0F
    NOP

    MOV BX, 0x01FF
    RCL BX, 2
    db 0x0F
    NOP

    RCL BX, CL
    db 0x0F
    NOP

    RCL BL, CL
    db 0x0F
    NOP

    RCL BH, CL
    db 0x0F
    NOP

    MOV word [BP], 0x0301
    ROL byte [BP], 1
    SHL word [BP], 1
    ROL byte [BP+1], 3

    db 0x0F
    NOP

    MOV AX, 0xFAF1

    db 0x0F
    NOP

    ROL AL, 1
    db 0x0F
    NOP

    ROL AH, 1
    db 0x0F
    NOP

    ROL AX, 1
    db 0x0F
    NOP

    ROL AL, 2
    db 0x0F
    NOP

    ROL AH, 2
    db 0x0F
    NOP

    ROL AX, 3
    db 0x0F
    NOP

    ROL AX, 2
    db 0x0F
    NOP

    ROL AX, 2
    db 0x0F
    NOP

    MOV BX, 0x01FF
    MOV CX, 1
    ROL BX, 1
    db 0x0F
    NOP

    MOV BX, 0x01FF
    ROL BX, 2
    db 0x0F
    NOP

    ROL BX, CL
    db 0x0F
    NOP

    ROL BL, CL
    db 0x0F
    NOP

    ROL BH, CL
    db 0x0F
    NOP

    MOV word [BP], 0x0301
    ROL byte [BP], 1
    SHL word [BP], 1
    ROL byte [BP+1], 3

    MOV AX, 0xFAF1

    db 0x0F
    NOP

    RCR AL, 1
    db 0x0F
    NOP

    RCR AH, 1
    db 0x0F
    NOP

    RCR AX, 1
    db 0x0F
    NOP

    RCR AL, 2
    db 0x0F
    NOP

    RCR AH, 2
    db 0x0F
    NOP

    RCR AX, 3
    db 0x0F
    NOP

    RCR AX, 2
    db 0x0F
    NOP

    RCR AX, 2
    db 0x0F
    NOP

    MOV BX, 0x01FF
    MOV CX, 1
    RCR BX, 1
    db 0x0F
    NOP

    MOV BX, 0x01FF
    RCR BX, 2
    db 0x0F
    NOP

    RCR BX, CL
    db 0x0F
    NOP

    RCR BL, CL
    db 0x0F
    NOP

    RCR BH, CL
    db 0x0F
    NOP

    MOV word [BP], 0x0301
    RCR byte [BP], 1
    SHL word [BP], 1
    RCR byte [BP+1], 3

    hlt
