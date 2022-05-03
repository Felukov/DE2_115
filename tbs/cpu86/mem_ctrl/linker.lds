OUTPUT_FORMAT(binary)
ENTRY (_start)
SECTIONS {
    . = 0x0;
    .interrupts : {
        *(.interrupts)
    }
    .text       : {
        *(.text)
    }
    .rodata       : {
        *(.rodata)
    }
    .data       : {
        *(.data)
    }
    /*.empty_bytes :
    {
        . = 0x0;
        LONG(0xDEADBEEF)
        KEEP(*(.empty_bytes))
        FILL(0x0000)
        . = 0x100;
        LONG(0xDEADBEEF)
    }*/
    .bss        : {
        *(.bss)
    }
    .empty_bytes :
    {
        KEEP(*(.empty_bytes))
        LONG(0xDEADBEEF)
    }
}
