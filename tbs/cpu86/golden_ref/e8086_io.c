#include "e8086_io.h"

#define IO_MEM_SIZE 0x10000
unsigned short io_port[IO_MEM_SIZE];

void e8086_io_clear(){
    unsigned int i;
    for (i = 0; i < IO_MEM_SIZE; i++) {
        io_port[i] = 0x0;
    }
}

unsigned char io_get_uint8(void* _this, unsigned long addr){
    return (unsigned char)io_port[(unsigned short)addr];
}

unsigned short io_get_uint16(void* _this, unsigned long addr){
    return io_port[(unsigned short)addr];
}

void io_set_uint8(void* _this, unsigned long addr, unsigned char val){
    io_port[(unsigned short)addr] = (unsigned short)val;
}

void io_set_uint16(void* _this, unsigned long addr, unsigned short val){
    io_port[(unsigned short)addr] = val;
}

