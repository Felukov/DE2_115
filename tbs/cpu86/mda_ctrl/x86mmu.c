#include "x86platform.h"
#include "x86mmu.h"

void mmu_map(uint8_t slot, uint32_t start_addr) {
    uint32_t offset = start_addr >> 15;
    // disable interrupts
    cli();
    // set slot
    outw(MMU_CONTROL, slot);
    // set address
    outw(MMU_CONTROL, (uint16_t)offset);
    // set target as sdram
    outw(MMU_CONTROL, 1);
    // enable interrupts
    sti();
}
