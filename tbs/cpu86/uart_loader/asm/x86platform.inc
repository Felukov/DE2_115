IO_UART_DATA           EQU      0310H
IO_UART_RX_HAS_DATA    EQU      0311H
IO_UART_TX_IS_EMPTY    EQU      0312H

IO_MMU_CONTROL         EQU      0320h

TERMINAL_BASE_ADDR     EQU      0B000h

SLOT_00000_07FFF       EQU      0
SLOT_08000_0FFFF       EQU      1
SLOT_10000_17FFF       EQU      2
SLOT_18000_1FFFF       EQU      3
SLOT_20000_27FFF       EQU      4
SLOT_28000_2FFFF       EQU      5
SLOT_30000_37FFF       EQU      6
SLOT_38000_3FFFF       EQU      7
SLOT_40000_47FFF       EQU      8
SLOT_48000_4FFFF       EQU      9
SLOT_50000_57FFF       EQU      10
SLOT_58000_5FFFF       EQU      11
SLOT_60000_67FFF       EQU      12
SLOT_68000_6FFFF       EQU      13
SLOT_70000_77FFF       EQU      14
SLOT_78000_7FFFF       EQU      15
SLOT_80000_87FFF       EQU      16
SLOT_88000_8FFFF       EQU      17
SLOT_90000_97FFF       EQU      18
SLOT_98000_9FFFF       EQU      19
SLOT_A0000_A7FFF       EQU      20
SLOT_A8000_AFFFF       EQU      21
SLOT_B0000_B7FFF       EQU      22
SLOT_B8000_BFFFF       EQU      23
SLOT_C0000_C7FFF       EQU      24
SLOT_C8000_CFFFF       EQU      25
SLOT_D0000_D7FFF       EQU      26
SLOT_D8000_DFFFF       EQU      27
SLOT_E0000_E7FFF       EQU      28
SLOT_E8000_EFFFF       EQU      29
SLOT_F0000_F7FFF       EQU      30
SLOT_F8000_FFFFF       EQU      31

far_jump macro cs_val : req, ip_val : req

    db      0EAh
    dw      ip_val
    dw      cs_val

endm

dbg_trap macro

    db      0Fh

endm
