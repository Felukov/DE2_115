
int kernel_init();
void kernel_wait(unsigned int times);

int uart_rx_has_data();
int uart_tx_is_empty();
void uart_transmit();
void uart_log(const char* s);
