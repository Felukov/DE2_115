ORG 400h
start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0
    MOV [BP], AX

; TEST 1 - LOOP
loop_proc:
    MOV AX, 0

.loop_back:
    INC AX
    CMP AX, 10
    XCHG AX, AX             ; FORCE CHECK AX

    JNE .loop_back
    XCHG AX, AX             ; FORCE CHECK AX


; TEST 2 - JE
test_je_proc:
    MOV AX, 10
    MOV BX, 10
    CMP AX, BX

    JE .test_je
    MOV AX, 0x1111
    XCHG AX, AX             ; FORCE CHECK AX
.test_je:
    MOV AX, 0x1212
    XCHG AX, AX             ; FORCE CHECK AX


; TEST 3 - JNE
test_jne_proc:
    MOV AX, 10
    MOV BX, 11
    CMP AX, BX

    JNE .test_jne
    MOV AX, 0x2222
    XCHG AX, AX             ; FORCE CHECK AX
.test_jne:
    MOV AX, 0x2323
    XCHG AX, AX             ; FORCE CHECK AX


; TEST 4 - JG
test_jg_proc:
    MOV AX, 11
    MOV BX, 10
    CMP AX, BX

    JG .test_jg
    MOV AX, 0x3333
    XCHG AX, AX             ; FORCE CHECK AX
.test_jg:
    MOV AX, 0x3434
    XCHG AX, AX             ; FORCE CHECK AX


; TEST 5 - JGE
test_jge_proc:
    MOV AX, 11
    MOV BX, 10
    CMP AX, BX

    JGE .test_jge
    MOV AX, 0x4444
    XCHG AX, AX             ; FORCE CHECK AX
.test_jge:
    MOV AX, 0x4545
    XCHG AX, AX             ; FORCE CHECK AX


; TEST 6 - JL
test_jl_proc:
    MOV AX, -11
    MOV BX, 11
    CMP AX, BX

    JL .test_jl
    MOV AX, 0x5555
    XCHG AX, AX             ; FORCE CHECK AX
.test_jl:
    MOV AX, 0x5656
    XCHG AX, AX             ; FORCE CHECK AX


; TEST 7 - JLE
test_jle_proc:
    MOV AX, 12
    MOV BX, 12
    CMP AX, BX

    JLE .test_jle
    MOV AX, 0x6666
    XCHG AX, AX             ; FORCE CHECK AX
.test_jle:
    MOV AX, 0x6767
    XCHG AX, AX             ; FORCE CHECK AX


; TEST 8 - JA
test_ja_proc:
    MOV AX, 12
    MOV BX, 11
    CMP AX, BX

    JA .test_ja
    MOV AX, 0x7777
    XCHG AX, AX             ; FORCE CHECK AX
.test_ja:
    MOV AX, 0x7878
    XCHG AX, AX             ; FORCE CHECK AX


; TEST 9 - JA
test_jae_proc:
    MOV AX, 12
    MOV BX, 12
    CMP AX, BX

    JAE .test_jae
    MOV AX, 0x8888
    XCHG AX, AX             ; FORCE CHECK AX
.test_jae:
    MOV AX, 0x8989
    XCHG AX, AX             ; FORCE CHECK AX


; TEST 10 - JB
test_jb_proc:
    MOV AX, 12
    MOV BX, 14
    CMP AX, BX

    JB .test_jb
    MOV AX, 0x9999
    XCHG AX, AX             ; FORCE CHECK AX
.test_jb:
    MOV AX, 0x9a9a
    XCHG AX, AX             ; FORCE CHECK AX


; TEST 11 - JBE
test_jbe_proc:
    MOV AX, 12
    MOV BX, 14
    CMP AX, BX

    JBE .test_jbe
    MOV AX, 0xaaaa
    XCHG AX, AX             ; FORCE CHECK AX
.test_jbe:
    MOV AX, 0xabab
    XCHG AX, AX             ; FORCE CHECK AX


; TEST 12 - JO
test_jo_proc:
    MOV AX, 0x7FFF
    MOV BX, 0x7FFF
    ADD AX, BX

    JO .test_jo
    MOV AX, 0xBBBB
    XCHG AX, AX             ; FORCE CHECK AX
.test_jo:
    MOV AX, 0xBCBC
    XCHG AX, AX             ; FORCE CHECK AX


; TEST 13 - JNO
test_jno_proc:
    MOV AX, 0x7F
    MOV BX, 0x7F
    ADD AX, BX

    JNO .test_jno
    MOV AX, 0xCCCC
    XCHG AX, AX             ; FORCE CHECK AX
.test_jno:
    MOV AX, 0xCDCD
    XCHG AX, AX             ; FORCE CHECK AX


; TEST 14 - JS
test_js_proc:
    MOV AX, 0xFFFF
    CMP AX, 0

    JS .test_js
    MOV AX, 0xDDDD
    XCHG AX, AX             ; FORCE CHECK AX
.test_js:
    MOV AX, 0xDEDE
    XCHG AX, AX             ; FORCE CHECK AX


; TEST 15 - JNS
test_jns_proc:
    MOV AX, 0x7FFF
    CMP AX, 0

    JNS .test_jns
    MOV AX, 0xEEEE
    XCHG AX, AX             ; FORCE CHECK AX
.test_jns:
    MOV AX, 0xEFEF
    MOV [BP], AX
    XCHG AX, AX             ; FORCE CHECK AX


; TEST 16 - JP
test_jp_proc:
    MOV AX, 0x6
    CMP AX, 0
    JP .test_jp
    MOV AX, 0x1111
    XCHG AX, AX             ; FORCE CHECK AX
.test_jp:
    MOV AX, 0x1212
    MOV [BP], AX
    XCHG AX, AX             ; FORCE CHECK AX


; TEST 17 - JP
test_jnp_proc:
    MOV AX, 0x4
    CMP AX, 0
    JNP .test_jnp
    MOV AX, 0x2222
    XCHG AX, AX             ; FORCE CHECK AX
.test_jnp:
    MOV AX, 0x2323
    MOV [BP], AX
    XCHG AX, AX             ; FORCE CHECK AX

    HLT

