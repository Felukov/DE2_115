#ifndef TERMINAL_H_INCLUDED
#define TERMINAL_H_INCLUDED

#include "x86.h"

#define TERMINAL_BASE_ADDR 0xB000

void terminal_clean();
void terminal_print(uint16_t x, uint16_t y, char* str, char attr);

#endif
