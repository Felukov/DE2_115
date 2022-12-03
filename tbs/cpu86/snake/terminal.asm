TERMINAL_BASE_ADDR     EQU      0B000h

.186
.model tiny

_TEXT   segment word public 'CODE'

g_x_pos word 0
g_y_pos word 0

terminal_clean proc near c uses es ax di
    mov     ax, TERMINAL_BASE_ADDR
    mov     es, ax
    mov     di, 0

    .while (di != 80*25*2)
        mov     word ptr es:[di], 3020h
        inc     di
    .endw

    ; set position
    mov     g_x_pos, 0
    mov     g_y_pos, 0
    ; return
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
    mov     g_x_pos, 0
    mov     g_y_pos, 24
    ;return
    ret
terminal_shift endp

terminal_print proc near c uses es ax dx si di, str_ptr : word
    mov     si, [str_ptr]
    mov     ax, TERMINAL_BASE_ADDR
    mov     es, ax
    mov     ax, 80*2
    mul     g_y_pos
    add     ax, g_x_pos
    add     ax, g_x_pos
    mov     di, ax

    ; set screen attr
    mov     ah, 20

    ; load ascii symbol
    mov     al, [si]

    .while (al != 0)

        .if g_y_pos == 25
            invoke terminal_shift
            mov     di, 24*80*2
        .endif

        .if al >= 32
            ; printable character
            mov     es:[di], ax
            add     di, 2
            inc     g_x_pos
        .endif

        .if al == 10
            ;db      0fh

            ; handling return
            mov     g_x_pos, 0
            inc     g_y_pos
            ; recalculate dest index
            mov     ax, 80*2
            mul     g_y_pos
            mov     di, ax

            ; set screen attr
            mov     ah, 20
        .endif

        .if g_x_pos == 80
            ; new line
            mov     g_x_pos, 0
            inc     g_y_pos
        .endif

        inc     si
        mov     al, [si]
    .endw

    ret
terminal_print endp

terminal_print_h proc near c uses es ax dx si di, x_pos, y_pos, attr : byte, str_ptr : word
    mov     si, [str_ptr]
    mov     ax, TERMINAL_BASE_ADDR
    mov     es, ax
    mov     ax, 80*2
    mul     y_pos
    add     ax, x_pos
    add     ax, x_pos
    mov     di, ax

    ; set screen attr
    mov     ah, attr

    ; load ascii symbol
    mov     al, [si]

    .while (al != 0)
        ; print
        mov     es:[di], ax
        add     di, 2
        inc     x_pos

        inc     si
        mov     al, [si]
    .endw

    mov ax, y_pos
    mov dx, x_pos
    mov g_y_pos, ax
    mov g_x_pos, dx

    ret
terminal_print_h endp

terminal_print_v proc near c uses es ax dx si di, x_pos, y_pos, attr : byte, str_ptr : word
    mov     si, [str_ptr]
    mov     ax, TERMINAL_BASE_ADDR
    mov     es, ax
    mov     ax, 80*2
    mul     y_pos
    add     ax, x_pos
    add     ax, x_pos
    mov     di, ax

    ; set screen attr
    mov     ah, attr

    ; load ascii symbol
    mov     al, [si]

    .while (al != 0)
        ; print
        mov     es:[di], ax
        add     di, 80*2
        inc     y_pos

        inc     si
        mov     al, [si]
    .endw

    mov ax, y_pos
    mov dx, x_pos
    mov g_y_pos, ax
    mov g_x_pos, dx

    ret
terminal_print_v endp

terminal_set_pos proc near c uses ax, x_pos, y_pos : word
    mov ax, x_pos
    mov g_x_pos, ax
    mov ax, y_pos
    mov g_y_pos, ax
    ret
terminal_set_pos endp

end
