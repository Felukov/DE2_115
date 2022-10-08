#include "rnd.h"

uint8_t rnd_val = 0x1;
uint8_t rnd_init_val = 0xFF;
uint8_t rnd_cnt = 0x0;

void rnd_init(){
    // Request the reading of the status and the value of the 0 counter
    _inline_outp(PIT_CONTROL, 0xC2);
    // Read the status low
    _inline_inp(PIT_TIMER_0);
    // Read the status hi
    rnd_init_val = _inline_inp(PIT_TIMER_0);
    if (rnd_init_val == 0){
        rnd_init_val = 0xFF;
    }
    rnd_val = rnd_init_val;
    // Read the value
    //_inline_outpw(0x306, rnd_init_val);
}

uint8_t get_rnd(){
    int newbit;
    if (rnd_cnt == 0xFF){
        rnd_init();
    }
    rnd_cnt++;
    newbit = (((rnd_val >> 6) ^ (rnd_val >> 5)) & 1);
    rnd_val = ((rnd_val << 1) | newbit) & 0x7f;
    return rnd_val;
}

uint8_t get_rnd_range(uint8_t min, uint8_t max){
    uint8_t v;
    for(;;){
        v = get_rnd();
        if (v >= min && v <= max){
            return v;
        }
    }
}
