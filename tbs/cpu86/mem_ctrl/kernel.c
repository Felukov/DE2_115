#include "stdint.h"
#include "x86platform.h"
#include "x86uart.h"
#include "x86mmu.h"

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

int init_mmu(){
    uint32_t offset = 0x8000;
    for (uint8_t i = 1; i < 32; i++) {
        mmu_map(i, offset);
        offset += 0x8000;
    }
    return 0;
}

int mem_test1(){
    mmu_map(SLOT_50000_57FFF, 0xA0000);
    mmu_map(SLOT_A0000_A7FFF, 0xA0000);

    writew(0x5000, 0x0, 0x55);

    uart_log("T1 ");
    if (readw(0xA000, 0x0) == 0x55) {
        uart_log("ok\n");
    } else {
        uart_log("fail\n");
    }
    return 0;
}

int mem_test2(){
    uart_log("T2 ");
    stosw(0xA000, 0x0000, 0x5555, 10);
    movsw(0xA000, 0x0000, 0xB000, 0x1000, 10);
    // compare between
    uint8_t err_cnt = 0;
    uint16_t addr = 0x1000;
    for (uint8_t i = 0; i < 10; i++) {
        if (readw(0xB000, addr) != 0x5555) {
            err_cnt++;
        }
        addr += 2;
    }
    if (err_cnt == 0) {
        uart_log("ok\n");
    } else {
        uart_log("fail\n");
    }
    return 0;
}

int mem_test3(){
    uart_log("T3 ");

    uint8_t ch = 0;
    for (uint16_t i = 0; i < 80*25*2; i += 2) {
        /* code */
        writew(0xB000, i, ch);
        ch++;
    }

    uart_log("ok\n");
    return 0;
}

int main(){
    const char *str = "Memory testbench\n";

    // Initialization
    init_timer();
    init_pic_1();
    init_pic_2();
    init_isr();
    init_mmu();
    uart_log(str);

    // Memory test 1
    // check that memory mapping is working
    mem_test1();

    // Memory test 2
    // load memory with filler
    mem_test2();

    // Memory test 3
    // fill mda memory with characters
    mem_test3();

    // Memory test 4
    // load itself to sdram
    // switch lower segment to sdram
    // jump to function via far call to force flush of instruction queue
    // if ok then test passed. maybe also set some memory location in sdram
    // with a particular value

    for (;;){

        uart_transmit();
    }

    return 0;
}
