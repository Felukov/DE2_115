include x86platform.inc

.186
.model tiny

.code

uart_rx_has_data proc near stdcall uses dx
    mov     dx, IO_UART_RX_HAS_DATA
    in      ax, dx
    and     ax, 1
    ret
uart_rx_has_data endp

uart_rx_get_data proc near stdcall uses dx
    mov     dx, IO_UART_DATA
    in      ax, dx
    ret
uart_rx_get_data endp

uart_tx_is_empty proc near stdcall uses dx
    mov     dx, IO_UART_TX_IS_EMPTY
    in      ax, dx
    and     ax, 1
    ret
uart_tx_is_empty endp

uart_transmit proc near stdcall uses dx cx
    mov     dx, IO_UART_RX_HAS_DATA
    in      al, dx
    mov     dx, ax

    mov     dx, IO_UART_TX_IS_EMPTY
    in      al, dx
    and     dx, ax

    and     ax, 1
    ret
uart_transmit endp

uart_log proc near stdcall uses dx si, str_ptr : word
    mov     si, [str_ptr]

    .while (byte ptr [si] != 0)
        mov     dx, IO_UART_TX_IS_EMPTY

        .repeat
            in      al, dx
            and     ax, 1
        .until (ax == 1)

        mov     dx, IO_UART_DATA
        mov     al, [si]
        out     dx, al
        inc     si
    .endw

    ret
uart_log endp

end
