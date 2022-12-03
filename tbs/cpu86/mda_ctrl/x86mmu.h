#ifndef _X86MMU_H
#define _X86MMU_H

#include "x86platform.h"

#define SLOT_00000_07FFF 0
#define SLOT_08000_0FFFF 1
#define SLOT_10000_17FFF 2
#define SLOT_18000_1FFFF 3
#define SLOT_20000_27FFF 4
#define SLOT_28000_2FFFF 5
#define SLOT_30000_37FFF 6
#define SLOT_38000_3FFFF 7
#define SLOT_40000_47FFF 8
#define SLOT_48000_4FFFF 9
#define SLOT_50000_57FFF 10
#define SLOT_58000_5FFFF 11
#define SLOT_60000_67FFF 12
#define SLOT_68000_6FFFF 13
#define SLOT_70000_77FFF 14
#define SLOT_78000_7FFFF 15
#define SLOT_80000_87FFF 16
#define SLOT_88000_8FFFF 17
#define SLOT_90000_97FFF 18
#define SLOT_98000_9FFFF 19
#define SLOT_A0000_A7FFF 20
#define SLOT_A8000_AFFFF 21
#define SLOT_B0000_B7FFF 22
#define SLOT_B8000_BFFFF 23
#define SLOT_C0000_C7FFF 24
#define SLOT_C8000_CFFFF 25
#define SLOT_D0000_D7FFF 26
#define SLOT_D8000_DFFFF 27
#define SLOT_E0000_E7FFF 28
#define SLOT_E8000_EFFFF 29
#define SLOT_F0000_F7FFF 30
#define SLOT_F8000_FFFFF 31

void mmu_map(uint8_t slot, uint32_t start_addr);

#endif