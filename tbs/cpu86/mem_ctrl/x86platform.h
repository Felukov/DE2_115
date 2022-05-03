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

#define MMU_CONTROL         0x0320

static uint8_t* const VGA_MEMORY = (uint8_t*)0x3000;

inline uint8_t inb (uint16_t _port) {
    uint8_t rv;
    __asm__ __volatile__ (
        "mov %1, %%dx   \n\t"
        "inb (%%dx), %0 \n\t"
        : "=a" (rv) : "g" (_port) : "dx"
    );
    return rv;
}

inline uint16_t inw (uint16_t _port) {
    uint16_t rv;
    __asm__ __volatile__ (
        "mov %1, %%dx   \n\t"
        "inw (%%dx), %0 \n\t"
        : "=a" (rv) : "g" (_port) : "dx"
    );
    return rv;
}

inline void writew(uint16_t segment, uint16_t address, uint16_t val) {
    asm volatile(
        "push %%ds\n"
        "mov %P[segment], %%ds\n"
        "mov %P[address], %%bx\n"
        "movw %P[val], (%%bx)\n"
        "pop %%ds"
        :
        : [segment] "r"(segment), [address] "m"(address), [val] "r"(val)
        : "%bx", "memory");
}

inline uint16_t readw(uint16_t segment, uint16_t address) {
    uint16_t v;

    asm volatile(
        "push %%ds\n"
        "mov %P[segment], %%ds\n"
        "mov %P[address], %%bx\n"
        "movw (%%bx), %P[val]\n"
        "pop %%ds"
        : [val] "=r"(v)
        : [segment] "r"(segment), [address] "m"(address)
        : "%bx", "memory");

    return v;
}

inline void stosw(uint16_t dst_segm, uint16_t dst_addr, uint16_t data, uint16_t word_cnt){
    asm volatile(
        "push %%ax \n"
        "push %%es \n"
        "push %%di \n"
        "push %%cx \n"
        "mov %P[dst_segm], %%es \n"
        "mov %P[dst_addr], %%di \n"
        "mov %P[word_cnt], %%cx \n"
        "mov %P[data],     %%ax \n"
        "cld \n"
        "rep stosw \n"
        "pop %%cx \n"
        "pop %%di \n"
        "pop %%es \n"
        "pop %%ax \n"
        :
        : [dst_segm] "r"(dst_segm), [dst_addr] "m"(dst_addr), [word_cnt] "m"(word_cnt), [data] "m"(data)
        :
    );
}

inline void movsw(uint16_t src_segm, uint16_t src_addr, uint16_t dst_segm, uint16_t dst_addr, uint16_t word_cnt){
    asm volatile(
        "push %%ds \n"
        "push %%es \n"
        "push %%si \n"
        "push %%di \n"
        "push %%cx \n"
        "mov %P[src_segm], %%ds\n"
        "mov %P[src_addr], %%si\n"
        "mov %P[dst_segm], %%es\n"
        "mov %P[dst_addr], %%di\n"
        "mov %P[word_cnt], %%cx\n"
        "cld \n"
        "rep movsw \n"
        "pop %%cx \n"
        "pop %%di \n"
        "pop %%si \n"
        "pop %%es \n"
        "pop %%ds \n"
        :
        : [src_segm] "r"(src_segm), [src_addr] "m"(src_addr), [dst_segm] "r"(dst_segm), [dst_addr] "m"(dst_addr), [word_cnt] "m"(word_cnt)
        :
    );
    return;
}

void inline outb (uint16_t _port, uint8_t _data) {
    asm volatile("outb %1, %0" : : "d"(_port), "a"(_data));
}

void inline outw (uint16_t _port, uint16_t _data) {
    //__asm__ __volatile__ ("outw %1, %0" : :  "dN" (_port), "a" (_data));
    asm volatile("outw %1, %0" : : "d"(_port), "a"(_data));
}

void inline iret() {
    __asm__ __volatile__ ("iret");
}

void inline cli(){
    __asm__ __volatile__ ("cli");
}

void inline sti(){
    __asm__ __volatile__ ("sti");
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
