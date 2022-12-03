#include "terminal.h"

void terminal_clean(){
    uint16_t i;
    for (i = 0; i < 80*25*2; i++){
        write_word(TERMINAL_BASE_ADDR, i, 0x3020);
    }
}

void terminal_print(uint16_t x, uint16_t y, char* str, char attr){
    uint16_t pos;
    uint16_t val;
    pos = y * 80 * 2 + x*2;
    while (*str) {
        val = attr << 8;
        val = val | *str;
        write_word(TERMINAL_BASE_ADDR, pos, val);
        str++;
        pos += 2;
    }
}
