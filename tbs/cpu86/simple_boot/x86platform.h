#ifndef _X86_PLATFORM_H
#define _X86_PLATFORM_H

#include "stdint.h"

#define PIT_CONTROL         0x43
#define PIT_TIMER_0         0x40
#define PIT_TIMER_1         0x41
#define PIT_TIMER_2         0x42

#define PIC1                0x20        /* IO base address for master PIC */
#define PIC2                0xA0        /* IO base address for slave PIC */
#define PIC1_COMMAND        PIC1
#define PIC1_DATA           (PIC1+1)
#define PIC2_COMMAND        PIC2
#define PIC2_DATA           (PIC2+1)

#define UART_DATA           0x0310
#define UART_RX_HAS_DATA    0x0311
#define UART_TX_IS_EMPTY    0x0312

static uint8_t* const VGA_MEMORY = (uint8_t*)0x3000;

inline uint8_t inb (uint16_t _port) {
    uint8_t rv;
    // __asm__ __volatile__ ("inb %1, %0" : "=a" (rv) : "dN" (_port));
    __asm__ __volatile__ (
        "mov %1, %%dx   \n\t"
        "inb (%%dx), %0 \n\t"
        : "=a" (rv) : "g" (_port) : "dx"
    );
    return rv;
}

inline uint16_t inw (uint16_t _port) {
    uint16_t rv;
    //__asm__ __volatile__ ("inw %1, %0" : "=a" (rv) : "dN" (_port));
    __asm__ __volatile__ (
        //"push %%dx      \n\t"
        "mov %1, %%dx   \n\t"
        "inw (%%dx), %0 \n\t"
        //"pop %%dx       \n\t"
        : "=a" (rv) : "g" (_port) : "dx"
    );
    return rv;
}

void inline outb (uint16_t _port, uint8_t _data) {
    __asm__ __volatile__ ("outb %1, %0" : :  "dN" (_port), "a" (_data));
}

void inline outw (uint16_t _port, uint16_t _data) {
    __asm__ __volatile__ ("outw %1, %0" : :  "dN" (_port), "a" (_data));
}

void inline iret() {
    __asm__ __volatile__ ("iret");
}

void inline leave() {
    __asm__ __volatile__ ("leave");
}

void inline pusha(){
    __asm__ __volatile__ ("pusha");
}

void inline pushf(){
    __asm__ __volatile__ ("pushf");
}

void inline push_ax(){
    __asm__ __volatile__ ("push   %ax");
}

void inline push_dx(){
    __asm__ __volatile__ ("push   %dx");
}

void inline popa(){
    __asm__ __volatile__ ("popa");
}

void inline popf(){
    __asm__ __volatile__ ("popf");
}

void inline pop_ax(){
    __asm__ __volatile__ ("pop    %ax");
}

void inline pop_dx(){
    __asm__ __volatile__ ("pop    %dx");
}


#endif //_X86_PLATFORM_H
