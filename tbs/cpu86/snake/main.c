#include "kernel.h"
#include "x86.h"

int cmain (){
    unsigned int cnt_0 = 1;
    _inline_outpw(0x305, cnt_0);

    kernel_init();
    cnt_0++;
    _inline_outpw(0x305, cnt_0);

    uart_log("kernel initialization completed\n");
    cnt_0++;
    _inline_outpw(0x305, cnt_0);

    for (;;) {
        kernel_wait(33144);
        kernel_wait(33144);
        //uart_log("!");
        cnt_0++;
        _inline_outpw(0x305, cnt_0);
    }

    return 0;
}
