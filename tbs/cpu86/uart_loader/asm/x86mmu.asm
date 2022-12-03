include x86platform.inc

.186
.model tiny

.code

mmu_map proc near stdcall uses dx, slot : word, start_addr : word
    pushf
    ; disable interrupts
    cli

    mov     dx, IO_MMU_CONTROL
    ; set slot
    mov     ax, [slot]
    out     dx, ax

    ;set address
    mov     ax, [start_addr]
    shr     ax, 11
    out     dx, ax

    ;set target as sdram
    mov     ax, 1
    out     dx, ax

    ; restore flags
    popf

    ret
mmu_map endp

end
