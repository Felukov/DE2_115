#include "kbd.h"

uint8_t kbd_buf[16];
uint8_t kbd_buf_wr_ptr = 0;
uint8_t kbd_buf_rd_ptr = 0;
uint8_t kbd_buf_cnt = 0;


void kbd_isr(){
    // get keyboard byte
    uint8_t b = _inline_inp(KBD_DATA);
    // write data to buffer
    kbd_buf[kbd_buf_wr_ptr] = b;
    kbd_buf_cnt++;
    kbd_buf_wr_ptr++;
    if (kbd_buf_wr_ptr == 16) {
        kbd_buf_wr_ptr = 0;
    }
    _inline_outpw(0x306, 0x2222);
}

uint8_t kbd_has_data(){
    uint8_t b;
    __asm
    {
        pushf
        cli
    }
     b = kbd_buf_cnt != 0;
    __asm
    {
        popf
    }
    return b;
}

uint8_t kbd_read_char(){
    uint8_t ch;
    __asm
    {
        pushf
        cli
    }
    ch = kbd_buf[kbd_buf_rd_ptr];
    kbd_buf_cnt--;
    kbd_buf_rd_ptr++;
    if (kbd_buf_rd_ptr == 16) {
        kbd_buf_rd_ptr = 0;
    }
    __asm
    {
        popf
    }
    return ch;
}
