TERMINAL_BASE_ADDR     EQU      0B000h

.186
.model tiny

_TEXT   segment word public 'CODE'

x_pos word 0
y_pos word 0

terminal_clean proc near c uses es di
    mov     ax, TERMINAL_BASE_ADDR
    mov     es, ax
    mov     di, 0

    .while (di != 80*25*2)
        mov     word ptr es:[di], 3020h
        inc     di
    .endw

    ret
terminal_clean endp

terminal_shift proc near c uses es ax cx si di
    ; shift screen
    push    ds
    mov     ax, TERMINAL_BASE_ADDR
    mov     es, ax
    mov     ds, ax
    mov     si, 80*2
    mov     di, 0
    mov     cx, 80*25
    cld
    rep     movsw

    ; clean last line
    mov     di, 24*80*2

    .while (di < 25*80*2)
        mov     word ptr es:[di], 3020h
        inc     di
        mov     word ptr es:[di], 3020h
        inc     di
    .endw

    ; set position
    pop     ds
    mov     x_pos, 0
    mov     y_pos, 24
    ;return
    ret
terminal_shift endp

terminal_print proc near c uses es dx si di, str_ptr : word
    mov     si, [str_ptr]
    mov     ax, TERMINAL_BASE_ADDR
    mov     es, ax
    mov     ax, 80*2
    mul     y_pos
    add     ax, x_pos
    add     ax, x_pos
    mov     di, ax

    ; set screen attr
    mov     ah, 20

    ; load ascii symbol
    mov     al, [si]

    .while (al != 0)

        .if y_pos == 25
            invoke terminal_shift
            mov     di, 24*80*2
        .endif

        .if al >= 32
            ; printable character
            mov     es:[di], ax
            add     di, 2
            inc     x_pos
        .endif

        .if al == 10
            ;db      0fh

            ; handling return
            mov     x_pos, 0
            inc     y_pos
            ; recalculate dest index
            mov     ax, 80*2
            mul     y_pos
            mov     di, ax

            ; set screen attr
            mov     ah, 20
        .endif

        .if x_pos == 80
            ; new line
            mov     x_pos, 0
            inc     y_pos
        .endif

        inc     si
        mov     al, [si]
    .endw

    ret
terminal_print endp

end
