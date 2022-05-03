#include "x86platform.h"
#include "x86uart.h"

int uart_rx_has_data() {
   return inb(UART_RX_HAS_DATA) & 0x01;
}

int uart_tx_is_empty() {
   return inb(UART_TX_IS_EMPTY) & 0x01;
}

void uart_transmit(){
    while (uart_rx_has_data() && uart_tx_is_empty()) {
        outb(UART_DATA, inb(UART_DATA));
    }
}

void uart_log(const char* s){
    while (*s != 0){
        while (uart_tx_is_empty() == 0);
        outb(UART_DATA, (uint8_t)*s);
        s++;
    }
}
