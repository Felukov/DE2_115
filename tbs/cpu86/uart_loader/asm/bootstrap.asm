include x86platform.inc

.186
.model tiny

pword typedef ptr word

; procedure prototypes
uart_log            proto near stdcall, str_ptr : word
uart_rx_has_data    proto near stdcall
uart_rx_get_data    proto near stdcall

terminal_clean      proto near stdcall
terminal_print      proto near stdcall, str_ptr : word
terminal_cursor_on  proto near stdcall, a_x_pos : word, a_y_pos : word

mmu_map             proto near stdcall, slot : word, start_addr : word

; code
.code
org 400h

start:
    mov sp, -2
    jmp main

; data inside code
init_mode   byte 01h
hello_msg   byte "Hello from bootloader!", 10, "80186 cpu", 10, 0
wait_msg    byte "UART loader is waiting your program to run...", 10, 0
step_msg    byte ".", 0
done_msg    byte "completed", 10, 0
dbg_msg     byte "!", 0

;lines byte "0", 10, "1", 10, "2", 10, "3", 10, "4", 10, "5", 10, "6", 10, "7", 10, "8", 10, "9", 10, 0

relocate_yourself proc near c
    mov     ax, 0
    mov     ds, ax
    mov     ax, 0F000h
    mov     es, ax
    mov     si, 0
    mov     di, 0
    mov     cx, 07FFFh
    cld
    rep     movsw
    mov     ds, ax
    mov     init_mode, 00h
    mov     ss, ax
    mov     sp, -2

    far_jump 0F000h, 00400h
relocate_yourself endp

UART_FSM_IDLE       EQU     0
UART_FSM_WAIT_SIZE  EQU     1
UART_FSM_LOAD_PROG  EQU     2
UART_FSM_PARKING    EQU     3

uart_fsm proc near stdcall uses bx cx dx
    local state      : byte

    mov state, UART_FSM_IDLE
    mov dx, 0

    infinite_loop:
        .if state == UART_FSM_IDLE
            .if dh == 00h
                ; wait for data
                .repeat
                    invoke uart_rx_has_data
                .until (ax == 1)

                ; write data
                invoke uart_rx_get_data
                mov dh, al

                ; logging
                mov dbg_msg[0], '1'
                invoke uart_log, offset dbg_msg
            .endif

            .if dh == 11h
                ; wait for data
                .repeat
                    invoke uart_rx_has_data
                .until (ax == 1)

                ; write data
                invoke uart_rx_get_data
                mov dl, al

                ; logging
                mov dbg_msg[0], '2'
                invoke uart_log, offset dbg_msg

                .if dx == 1155h
                    mov state, UART_FSM_WAIT_SIZE
                    invoke terminal_print, offset step_msg
                    mov dbg_msg[0], '3'
                    invoke uart_log, offset dbg_msg
                .endif
            .endif

        .endif

        .if state == UART_FSM_WAIT_SIZE
            ; get hi byte
            .repeat
                invoke uart_rx_has_data
            .until (ax == 1)
            invoke uart_rx_get_data
            mov ch, al

            ; get lo byte
            .repeat
                invoke uart_rx_has_data
            .until (ax == 1)
            invoke uart_rx_get_data
            mov cl, al

            ; logging
            invoke terminal_print, offset step_msg
            mov dbg_msg[0], '4'
            invoke uart_log, offset dbg_msg
            mov state, UART_FSM_LOAD_PROG
        .endif

        .if state == UART_FSM_LOAD_PROG
            mov ax, 1000h
            mov es, ax
            mov bx, 0100h
            load_prog_bytes_loop:
                .repeat
                    invoke uart_rx_has_data
                .until (ax == 1)

                mov dbg_msg[0], '5'
                invoke uart_log, offset dbg_msg

                invoke uart_rx_get_data
                mov es:[bx], al
                inc bx
            loop load_prog_bytes_loop
            invoke terminal_print, offset step_msg
            mov state, UART_FSM_PARKING
        .endif

        .if state == UART_FSM_PARKING
            invoke terminal_print, offset done_msg
            mov dbg_msg[0], '6'
            invoke uart_log, offset dbg_msg
            ret
        .endif

    jmp infinite_loop

uart_fsm endp

main proc near c
    .if init_mode == 01h
        ; set mda memory map
        invoke mmu_map, SLOT_B0000_B7FFF, 0B000h
        ; set uart loader destination memory map
        invoke mmu_map, SLOT_F0000_F7FFF, 0F000h
        invoke mmu_map, SLOT_F8000_FFFFF, 0F800h
        ; set loaded program destination memory map
        invoke mmu_map, SLOT_10000_17FFF, 01000h
        invoke mmu_map, SLOT_18000_1FFFF, 01800h
        invoke relocate_yourself
    .else
        ; set first pages to sdram
        invoke mmu_map, SLOT_00000_07FFF, 00000h
        invoke mmu_map, SLOT_08000_0FFFF, 00800h
    .endif

    invoke uart_log, offset hello_msg
    invoke terminal_clean
    invoke terminal_print, offset hello_msg
    invoke terminal_print, offset wait_msg
    invoke terminal_cursor_on, 0, 3

    invoke uart_fsm

    ;dbg_trap
    far_jump 01000h, 00100h

@@: nop
    push    cs
    pop     ax
    mov     dx, 00305h
    out     dx, ax
    jmp     @b
    ret
main endp

;uart_moved_segment segment at 0F000h
;org 400h
;uart_new_entry_point label far
;uart_moved_segment ends

    end start

