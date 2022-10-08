#ifndef TERMINAL_H_INCLUDED
#define TERMINAL_H_INCLUDED

#include "x86.h"

extern void terminal_clean();

extern void terminal_print(char* msg);
extern void terminal_print_h(uint8_t x_pos, uint8_t y_pos, uint8_t attr, char* vector);
extern void terminal_print_v(uint8_t x_pos, uint8_t y_pos, uint8_t attr, char* vector);
extern void terminal_set_pos(unsigned int x_pos, unsigned int y_pos);
#endif
