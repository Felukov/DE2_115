#ifndef _X86UART_H
#define _X86UART_H

#include "x86platform.h"

int uart_rx_has_data();
int uart_tx_is_empty();
void uart_transmit();
void uart_log(const char* s);

#endif