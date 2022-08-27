#include "kernel.h"
#include "x86.h"
#include "terminal.h"

int cmain (){
    unsigned int cnt_0 = 1;
    unsigned int cnt_1 = 0;
    char str[3];
    _inline_outpw(0x305, cnt_0);

    kernel_init();
    cnt_0++;
    _inline_outpw(0x305, cnt_0);

    uart_log("kernel initialization completed\n");
    cnt_0++;
    _inline_outpw(0x305, cnt_0);

    terminal_clean();
    terminal_print("Hello from the Snake game!\n");
    terminal_print("It finally works as expected!!!\n");

    for (;;) {
        //kernel_wait(33144);
        kernel_wait(33144/10);
        //uart_log("!");
        if (cnt_1 == 11) {
            cnt_1 = 0;
        } else {
            cnt_1++;
        }
        str[0] = (char)(cnt_1 + 0x30);
        str[1] = 0;
        str[2] = 0;
        terminal_print(str);

        cnt_0++;
        _inline_outpw(0x305, cnt_0);
    }

    return 0;
}
