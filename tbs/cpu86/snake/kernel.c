#include "kernel.h"
#include "x86.h"

void int8_handler();

void interrupt_handler(unsigned char int_no,
    unsigned short* regs_ax,
    unsigned short* regs_bx,
    unsigned short* regs_cx,
    unsigned short* regs_dx) {

    switch (int_no) {
    case 0x08:
        int8_handler();
        break;

    default:
        break;
    }
}

void int8_handler(){
    // acknowledge interrupt request
    _inline_outp(PIC1_COMMAND, 0x20);
}

int init_timer(){
    // configure timer 0
    // toggle each 18.2 Hz
    _inline_outp(PIT_CONTROL, 0x36);
    _inline_outp(PIT_TIMER_0, 0x00);
    _inline_outp(PIT_TIMER_0, 0x00);

    // configure timer 1
    // toggle each 66.278 Hz (15.085 us)
    _inline_outp(PIT_CONTROL, 0x54);
    _inline_outp(PIT_TIMER_1, 18);

    return 0;
}

int init_pic_1(){
    // starts the initialization sequence (in cascade mode)
    _inline_outp(PIC1_COMMAND, ICW1_INIT | ICW1_ICW4);
    // ICW2: Master PIC vector offset
    _inline_outp(PIC1_DATA, 0x08);
    // ICW3: tell Master PIC that there is a slave PIC at IRQ2 (0000 0100)
    _inline_outp(PIC1_DATA, 4);
    _inline_outp(PIC1_DATA, ICW4_8086);

    return 0;
}

int init_pic_2(){
    // starts the initialization sequence (in cascade mode)
    _inline_outp(PIC2_COMMAND, ICW1_INIT | ICW1_ICW4);
    // ICW2: Master PIC vector offset
    _inline_outp(PIC2_DATA, 0x08);
    // ICW3: tell Slave PIC its cascade identity (0000 0010)
    _inline_outp(PIC2_DATA, 2);
    _inline_outp(PIC2_DATA, ICW4_8086);

    return 0;
}

void kernel_wait(unsigned int times){
    unsigned char x1 = 0x0;
    unsigned char x2 = 0x0;
    while (times > 0) {
        x1 = _inline_inp(0x61);
        x1 = x1 & 0x10;
        if (x1 != x2) {
            x2 = x1;
            times--;
        }
    }
}

int kernel_init(){
    init_timer();
    init_pic_1();
    init_pic_2();
    return 0;
}

int uart_rx_has_data() {
   return _inline_inp(UART_RX_HAS_DATA) & 0x01;
}

int uart_tx_is_empty() {
   return _inline_inp(UART_TX_IS_EMPTY) & 0x01;
}

void uart_transmit(){
    while (uart_rx_has_data() && uart_tx_is_empty()) {
        _inline_outp(UART_DATA, _inline_inp(UART_DATA));
    }
}

void uart_log(const char* s){
    while (*s != 0){
        while (uart_tx_is_empty() == 0);
        _inline_outp(UART_DATA, (unsigned char)*s);
        s++;
    }
}

