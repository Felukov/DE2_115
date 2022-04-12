#include "stdint.h"
#include "x86platform.h"

#define ICW1_ICW4          0x01        /* ICW4 (not) needed */
#define ICW1_SINGLE        0x02        /* Single (cascade) mode */
#define ICW1_INTERVAL4     0x04        /* Call address interval 4 (8) */
#define ICW1_LEVEL         0x08        /* Level triggered (edge) mode */
#define ICW1_INIT          0x10        /* Initialization - required! */

#define ICW4_8086          0x01        /* 8086/88 (MCS-80/85) mode */
#define ICW4_AUTO          0x02        /* Auto (normal) EOI */
#define ICW4_BUF_SLAVE     0x08        /* Buffered mode/slave */
#define ICW4_BUF_MASTER    0x0C        /* Buffered mode/master */
#define ICW4_SFNM          0x10        /* Special fully nested (not) */

void timer_interrupt_handler(){
    // ICW2: EOI
    push_ax();
    push_dx();
    outb(PIC1_COMMAND, 0x20);
    pop_dx();
    pop_ax();
    iret();
}

int init_timer(){
    // configure timer 0
    outb(PIT_CONTROL, 0x36);
    outb(PIT_TIMER_0, 0x00);
    outb(PIT_TIMER_0, 0x00);

    // configure timer 1
    outb(PIT_CONTROL, 0x54);
    outb(PIT_TIMER_1, 18);

    return 0;
}

int init_pic_1(){
    // starts the initialization sequence (in cascade mode)
    outb(PIC1_COMMAND, ICW1_INIT | ICW1_ICW4);
    // ICW2: Master PIC vector offset
    outb(PIC1_DATA, 0x08);
    // ICW3: tell Master PIC that there is a slave PIC at IRQ2 (0000 0100)
    outb(PIC1_DATA, 4);
    outb(PIC1_DATA, ICW4_8086);

    return 0;
}

int init_pic_2(){
    // starts the initialization sequence (in cascade mode)
    outb(PIC2_COMMAND, ICW1_INIT | ICW1_ICW4);
    // ICW2: Master PIC vector offset
    outb(PIC2_DATA, 0x08);
    // ICW3: tell Slave PIC its cascade identity (0000 0010)
    outb(PIC2_DATA, 2);
    outb(PIC2_DATA, ICW4_8086);

    return 0;
}

int init_isr(){
    static uint32_t* const INTERRUPT_TABLE = (uint32_t*)0x0000;

    INTERRUPT_TABLE[8] = (uint32_t)((uint16_t)&timer_interrupt_handler);

    return 0;
}

int main(){
    // Initialization
    init_timer();
    init_pic_1();
    init_pic_2();
    init_isr();

    uint8_t volatile a1;
    for (;;){
        a1 = inb(0x43);
        *VGA_MEMORY = a1;
    }

    return 0;
}
