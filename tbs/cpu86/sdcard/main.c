#include "x86.h"
#include "terminal.h"
#include "kernel.h"

// get the device status. 0 - no card, 1 - a card is present
#define SDCARD_GET_STATUS 0x0330
// set the low part of address.
#define SDCARD_SET_ADDR_LO 0x0331
// set the high part of address
#define SDCARD_SET_ADDR_HI 0x0332
// write byte to the write queue
#define SDCARD_WRITE_TO_QUEUE 0x0333
// write a block to the SD card with contents of the write FIFO
#define SDCARD_WRITE_TO_CARD 0x0334
// read a block from the SD card to the read FIFO
#define SDCARD_READ_FROM_CARD 0x0335
// check if the read FIFO has data
#define SDCARD_RD_QUEUE_HAS_DATA 0x0336
// read a byte from the read FIFO
#define SDCARD_RD_QUEUE_READ 0x0337
// get block size (low bits)
#define SDCARD_GET_BLOCK_SIZE_LO 0x0338
// get block size (high bits)
#define SDCARD_GET_BLOCK_SIZE_HI 0x0339

#define SDCARD_WR_QUEUE_HAS_DATA 0x033A

const char map[16] = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'};

uint8_t buffer0[512];
uint8_t buffer1[512];
uint8_t buffer2[512];

typedef struct bytes {
    uint8_t b0;
    uint8_t b1;
    uint8_t b2;
    uint8_t b3;
} u32_bytes_t;

typedef union u32_u8_t {
    u32_bytes_t bytes;
    uint32_t    lword;
} u32_u8_t;


int init_timer(){
    // configure timer 0
    // toggle each 18.2 Hz
    _inline_outp(PIT_CONTROL, 0x36);
    _inline_outp(PIT_TIMER_0, 0);
    _inline_outp(PIT_TIMER_0, 0x00);

    // configure timer 1
    // toggle each 66.278 Hz (15.085 us)
    _inline_outp(PIT_CONTROL, 0x54);
    _inline_outp(PIT_TIMER_1, 18);

    return 0;
}

void uint8_to_hex(uint8_t a, char* str){
    uint8_t h;
    uint8_t l;

    h = a >> 4;
    l = a & 0xF;

    str[0] = map[h];
    str[1] = map[l];
    str[2] = 0;
}

uint32_t checksum_calc(uint8_t* addr){
    /* Compute Internet Checksum for "count" bytes
     * beginning at location "addr".
     */
    uint32_t sum = 0;
    uint16_t count = 512;
    uint32_t checksum;

    while( count > 1 )  {
        /* This is the inner loop */
        sum += * (uint16_t *) addr++;
        count -= 2;
    }

    /*  Add left-over byte, if any */
    if ( count > 0 )
        sum += * (uint8_t *) addr;

    /*  Fold 32-bit sum to 16 bits */
    while (sum>>16)
        sum = (sum & 0xffff) + (sum >> 16);

    checksum = ~sum;
    return checksum;
}

void bare_main(){
    char        str[3];
    uint16_t    cnt;
    uint16_t    i;
    uint8_t     b;
    u32_u8_t    checksum;

    init_timer();
    terminal_clean();
    terminal_print(0, 0, "SDCard Tester", 20);
    terminal_print(0, 1, "========================", 20);

    if (_inline_inpw(SDCARD_GET_STATUS)) {
        terminal_print(4, 2, "Card is present", 20);
    } else {
        terminal_print(4, 2, "Card does not present", 20);
        for(;;);
    }

    // Reading 0x0 block
    terminal_print(4, 3, "Set address", 20);
    _inline_outpw(SDCARD_SET_ADDR_LO, 0x0);
    _inline_outpw(SDCARD_SET_ADDR_HI, 0x0);

    terminal_print(4, 4, "Read data", 20);
    _inline_outpw(SDCARD_READ_FROM_CARD, 0x0);

    terminal_print(4, 5, "Get size", 20);
    _inline_outpw(0x305, _inline_inpw(SDCARD_GET_BLOCK_SIZE_LO));
    _inline_outpw(0x306, _inline_inpw(SDCARD_GET_BLOCK_SIZE_HI));

    terminal_print(4, 6, "Waiting for data", 20);

    for (i = 0; i < 512; i++) {
        buffer0[i] =  _inline_inp(SDCARD_RD_QUEUE_READ);
    }

    checksum.lword = checksum_calc(&buffer0);

    terminal_print(4, 7, "Checksum at 0x0:", 20);

    uint8_to_hex(checksum.bytes.b3, str);
    terminal_print(6, 8, str, 20);

    uint8_to_hex(checksum.bytes.b2, str);
    terminal_print(6+2+1, 8, str, 20);

    uint8_to_hex(checksum.bytes.b1, str);
    terminal_print(6+2+1+2+1, 8, str, 20);

    uint8_to_hex(checksum.bytes.b0, str);
    terminal_print(6+2+1+2+1+2+1, 8, str, 20);

    // Reading 0x1 block
    _inline_outpw(SDCARD_SET_ADDR_LO, 0x1);
    _inline_outpw(SDCARD_SET_ADDR_HI, 0x0);
    _inline_outpw(SDCARD_READ_FROM_CARD, 0x0);
    for (i = 0; i < 512; i++) {
        buffer1[i] =  _inline_inp(SDCARD_RD_QUEUE_READ);
    }
    checksum.lword = checksum_calc(&buffer1);
    terminal_print(4, 9, "Checksum at 0x1:", 20);

    uint8_to_hex(checksum.bytes.b3, str);
    terminal_print(6, 10, str, 20);

    uint8_to_hex(checksum.bytes.b2, str);
    terminal_print(6+2+1, 10, str, 20);

    uint8_to_hex(checksum.bytes.b1, str);
    terminal_print(6+2+1+2+1, 10, str, 20);

    uint8_to_hex(checksum.bytes.b0, str);
    terminal_print(6+2+1+2+1+2+1, 10, str, 20);

    // Write buffer0 to 0x1
    for (i = 0; i < 512; i++) {
        _inline_outp(SDCARD_WRITE_TO_QUEUE, buffer0[i]);
    }

    _inline_outpw(SDCARD_WRITE_TO_CARD, 0x0);

    while(_inline_inpw(SDCARD_WR_QUEUE_HAS_DATA) == 1);
    terminal_print(4, 11, "Done writing BUFFER0 to 0x1", 20);

    // Reading 0x1 block
    _inline_outpw(SDCARD_SET_ADDR_LO, 0x1);
    _inline_outpw(SDCARD_SET_ADDR_HI, 0x0);
    _inline_outpw(SDCARD_READ_FROM_CARD, 0x0);
    for (i = 0; i < 512; i++) {
        buffer2[i] =  _inline_inp(SDCARD_RD_QUEUE_READ);
    }
    checksum.lword = checksum_calc(&buffer2);
    terminal_print(4, 12, "Checksum at 0x1:", 20);

    uint8_to_hex(checksum.bytes.b3, str);
    terminal_print(6, 13, str, 20);

    uint8_to_hex(checksum.bytes.b2, str);
    terminal_print(6+2+1, 13, str, 20);

    uint8_to_hex(checksum.bytes.b1, str);
    terminal_print(6+2+1+2+1, 13, str, 20);

    uint8_to_hex(checksum.bytes.b0, str);
    terminal_print(6+2+1+2+1+2+1, 13, str, 20);

    // Write buffer1 to 0x1
    for (i = 0; i < 512; i++) {
        _inline_outp(SDCARD_WRITE_TO_QUEUE, buffer1[i]);
    }

    _inline_outpw(SDCARD_WRITE_TO_CARD, 0x0);

    while(_inline_inpw(SDCARD_WR_QUEUE_HAS_DATA) == 1);
    terminal_print(4, 14, "Done writing BUFFER1 to 0x1", 20);

    // Reading 0x1 block
    _inline_outpw(SDCARD_SET_ADDR_LO, 0x1);
    _inline_outpw(SDCARD_SET_ADDR_HI, 0x0);
    _inline_outpw(SDCARD_READ_FROM_CARD, 0x0);
    for (i = 0; i < 512; i++) {
        buffer2[i] =  _inline_inp(SDCARD_RD_QUEUE_READ);
    }
    checksum.lword = checksum_calc(&buffer2);
    terminal_print(4, 15, "Checksum at 0x1:", 20);

    uint8_to_hex(checksum.bytes.b3, str);
    terminal_print(6, 16, str, 20);

    uint8_to_hex(checksum.bytes.b2, str);
    terminal_print(6+2+1, 16, str, 20);

    uint8_to_hex(checksum.bytes.b1, str);
    terminal_print(6+2+1+2+1, 16, str, 20);

    uint8_to_hex(checksum.bytes.b0, str);
    terminal_print(6+2+1+2+1+2+1, 16, str, 20);


    for(;;);
}
