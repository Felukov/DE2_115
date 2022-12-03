#include "kernel.h"

void __cdecl interrupt_handler (
    uint16_t int_no,
    uint16_t r_ds,
    uint16_t r_es,
    uint16_t r_di,
    uint16_t r_si,
    uint16_t r_bp,
    uint16_t r_bx,
    uint16_t r_dx,
    uint16_t r_cx,
    uint16_t r_ax,
    uint16_t r_ip,
    uint16_t r_cs,
    uint16_t r_flags
)
{

    switch (int_no) {
    case 0x08:
        //_inline_outpw(0x305, 0x8);
        int8_handler();
        break;

    case 0x09:
        //_inline_outpw(0x305, 0x9);
        int9_handler();
        break;
    default:
        break;
    }
}

void int8_handler(){
}

void int9_handler(){
}
