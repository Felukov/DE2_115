start:
    ; initialization
    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0

    ; SET SS register somewhere
    MOV AX, 0x330A
    MOV SS, AX

    ; TEST 1: -2 + 1, CARRY = 0
    CLC                     ; CLEAR CARRY
    MOV AX, 0xFFFE          ; AX = -2
    MOV BP, 0               ; [BP] = 1
    MOV word [BP], 0x0001
    ADC [BP], AL            ; [BP] = AL + [BP] + CARRY
    MOV AX, [BP]            ; AX = [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    ; TEST 2: -2 + 1, CARRY = 1
    STC                     ; SET CARRY
    MOV AX, 0xFFFE          ; AX = -2
    MOV BP, 0               ; [BP] = 1
    MOV word [BP], 0x0001
    ADC [BP], AL            ; [BP] = AL + [BP] + CARRY
    MOV AX, [BP]            ; AX = [BP]
    XCHG AX, AX             ; FORCE CHECK AX CONTENT
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    ; TEST 3: SEQUENT ADCs, CARRY = 0
    CLC                     ; CLEAR CARRY
    MOV AX, 0xFFFE          ; AX = -2
    MOV BP, 0               ; [BP] = 1
    MOV word [BP], 0x0001
    ADC [BP], AL            ; [BP] = AL + [BP] + CARRY
    MOV AX, [BP]            ; AX = [BP]
    ADC AX, 0x0001          ; AX = AX + 1 + CARRY
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX

    ; TEST 4: SEQUENT ADCs, CARRY = 0
    STC                     ; SET CARRY
    MOV AX, 0xFFFE          ; AX = -2
    MOV BP, 0               ; [BP] = 1
    MOV word [BP], 0x0001
    ADC [BP], AL            ;
    ADC [BP], AL            ; [BP] = AL + [BP] + CARRY
    MOV AX, [BP]            ; AX = [BP]
    ADC AX, 0x0001          ; AX = AX + 1 + CARRY
    PUSHF                   ; FORCE CHECK FLAGS
    POP AX
    XCHG AX, AX


    HLT
