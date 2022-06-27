include x86platform.inc

.186
.model tiny

.code
x_pos word 0
y_pos word 0

terminal_clean proc near stdcall uses es di
    mov     ax, TERMINAL_BASE_ADDR
    mov     es, ax
    mov     di, 0

    .while (di != 80*25*2)
        mov     word ptr es:[di], 3020h
        inc     di
    .endw

    ret
terminal_clean endp

terminal_shift proc near stdcall uses es ax cx si di
    push    ds
    mov     ax, TERMINAL_BASE_ADDR
    mov     es, ax
    mov     ds, ax
    mov     si, 80*2
    mov     di, 0
    mov     cx, 80*25
    cld
    rep     movsw
    pop     ds
    mov     x_pos, 0
    mov     y_pos, 24
    ret
terminal_shift endp

terminal_print proc near stdcall uses es dx si di, str_ptr : word
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

terminal_cursor_on proc near stdcall uses es bx dx, a_x_pos : word, a_y_pos : word
    mov     ax, TERMINAL_BASE_ADDR
    mov     es, ax

    ; update current pos
    mov     ax, a_x_pos
    mov     x_pos, ax
    mov     ax, a_y_pos
    mov     y_pos, ax

    ; recalculate address
    mov     ax, 80*2
    mul     y_pos
    add     ax, x_pos

    ; store in bx address of attr
    mov     bx, 1
    add     bx, ax

    ; make it blink
    mov byte ptr es:[bx], 081h
    ;db      0fh

    ret
terminal_cursor_on endp

end
