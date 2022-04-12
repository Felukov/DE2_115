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

static uint8_t* const VGA_MEMORY = (uint8_t*)0x3000;

static uint8_t inb (uint16_t _port) {
    uint8_t rv;
    __asm__ __volatile__ ("inb %1, %0" : "=a" (rv) : "dN" (_port));
    return rv;
}


void outb (uint16_t _port, uint8_t _data) {
    __asm__ __volatile__ ("outb %1, %0" : :  "dN" (_port), "a" (_data));
}

void iret() {
    __asm__ __volatile__ ("iret");
}


void push_ax(){
    __asm__ __volatile__ ("push   %ax");
}

void push_dx(){
    __asm__ __volatile__ ("push   %dx");
}

void pop_ax(){
    __asm__ __volatile__ ("pop    %ax");
}

void pop_dx(){
    __asm__ __volatile__ ("pop    %dx");
}

#endif //_X86_PLATFORM_H
