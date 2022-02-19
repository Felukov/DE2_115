ORG 100h
start:

    MOV AX, 0x1000
    MOV DS, AX
    MOV SS, AX
    MOV SP, 0xFFFE
    MOV BP, 0
    MOV [BP], AX

    db 0x0F
    NOP

loop_proc:
    MOV AX, 0

.loop_back:
    INC AX
    CMP AX, 10
    db 0x0F
    NOP

    JNE .loop_back

test_je_proc:
    MOV AX, 10
    MOV BX, 10
    CMP AX, BX

    JE .test_je
    MOV AX, 0x1111
.test_je:
    db 0x0F
    NOP
    MOV AX, 0x1212
    MOV [BP], AX
    db 0x0F
    NOP

test_jne_proc:
    MOV AX, 10
    MOV BX, 11
    CMP AX, BX

    JNE .test_jne
    MOV AX, 0x2222
.test_jne:
    db 0x0F
    NOP
    MOV AX, 0x2323
    MOV [BP], AX
    db 0x0F
    NOP

test_jg_proc:
    MOV AX, 11
    MOV BX, 10
    CMP AX, BX

    JG .test_jg
    MOV AX, 0x3333
.test_jg:
    db 0x0F
    NOP
    MOV AX, 0x3434
    MOV [BP], AX
    db 0x0F
    NOP

test_jge_proc:
    MOV AX, 11
    MOV BX, 10
    CMP AX, BX

    JGE .test_jge
    MOV AX, 0x4444
.test_jge:
    db 0x0F
    NOP
    MOV AX, 0x4545
    MOV [BP], AX
    db 0x0F
    NOP

test_jl_proc:
    MOV AX, -11
    MOV BX, 11
    CMP AX, BX
    JL .test_jl
    MOV AX, 0x5555
.test_jl:
    db 0x0F
    NOP
    MOV AX, 0x5656
    MOV [BP], AX
    db 0x0F
    NOP

test_jle_proc:
    MOV AX, 12
    MOV BX, 12
    CMP AX, BX

    JLE .test_jle
    MOV AX, 0x6666
.test_jle:
    db 0x0F
    NOP
    MOV AX, 0x6767
    MOV [BP], AX
    db 0x0F
    NOP

test_ja_proc:
    MOV AX, 12
    MOV BX, 11
    CMP AX, BX

    JA .test_ja
    MOV AX, 0x7777
.test_ja:
    db 0x0F
    NOP
    MOV AX, 0x7878
    MOV [BP], AX
    db 0x0F
    NOP

test_jae_proc:
    MOV AX, 12
    MOV BX, 12
    CMP AX, BX

    JAE .test_jae
    MOV AX, 0x8888
.test_jae:
    db 0x0F
    NOP
    MOV AX, 0x8989
    MOV [BP], AX
    db 0x0F
    NOP

test_jb_proc:
    MOV AX, 12
    MOV BX, 14
    CMP AX, BX

    JB .test_jb
    MOV AX, 0x9999
.test_jb:
    db 0x0F
    NOP
    MOV AX, 0x9a9a
    MOV [BP], AX
    db 0x0F
    NOP

test_jbe_proc:
    MOV AX, 12
    MOV BX, 14
    CMP AX, BX

    JBE .test_jbe
    MOV AX, 0xaaaa
.test_jbe:
    db 0x0F
    NOP
    MOV AX, 0xabab
    MOV [BP], AX
    db 0x0F
    NOP

test_jo_proc:
    MOV AX, 0x7FFF
    MOV BX, 0x7FFF
    ADD AX, BX
    JO .test_jo
    MOV AX, 0xBBBB
.test_jo:
    db 0x0F
    NOP
    MOV AX, 0xBCBC
    MOV [BP], AX
    db 0x0F
    NOP

test_jno_proc:
    MOV AX, 0x7F
    MOV BX, 0x7F
    ADD AX, BX
    JNO .test_jno
    MOV AX, 0xCCCC
.test_jno:
    db 0x0F
    NOP
    MOV AX, 0xCDCD
    MOV [BP], AX
    db 0x0F
    NOP

test_js_proc:
    MOV AX, 0xFFFF
    CMP AX, 0
    JS .test_js
    MOV AX, 0xDDDD
.test_js:
    db 0x0F
    NOP
    MOV AX, 0xDEDE
    MOV [BP], AX
    db 0x0F
    NOP

test_jns_proc:
    MOV AX, 0x7FFF
    CMP AX, 0
    JNS .test_jns
    MOV AX, 0xEEEE
.test_jns:
    db 0x0F
    NOP
    MOV AX, 0xEFEF
    MOV [BP], AX
    db 0x0F
    NOP

test_jp_proc:
    MOV AX, 0x6
    CMP AX, 0
    JP .test_jp
    MOV AX, 0x1111
.test_jp:
    db 0x0F
    NOP
    MOV AX, 0x1212
    MOV [BP], AX
    db 0x0F
    NOP

test_jnp_proc:
    MOV AX, 0x4
    CMP AX, 0
    JNP .test_jnp
    MOV AX, 0x2222
.test_jnp:
    db 0x0F
    NOP
    MOV AX, 0x2323
    MOV [BP], AX
    db 0x0F
    NOP

    HLT

