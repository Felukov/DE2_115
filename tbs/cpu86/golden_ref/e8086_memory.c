#include <stdio.h>

#include "e8086_memory.h"

// Global variabls
#define RAM_SIZE 1024*1024

unsigned char mem[RAM_SIZE];

unsigned char mem_get_uint8(void* _this, unsigned long addr) {
    unsigned char ret;

    ret = mem[addr];

    return (ret);
}

unsigned short mem_get_uint16_le(void* _this, unsigned long addr) {
    unsigned short ret;

    ret = mem_get_uint8 (mem, addr);
    ret |= (unsigned short) mem_get_uint8 (mem, addr + 1) << 8;

    return (ret);
}

void mem_set_uint8(void* _this, unsigned long addr, unsigned char val) {
    mem[addr] = val;
}

void mem_set_uint16_le(void* _this, unsigned long addr, unsigned short val) {
    mem_set_uint8(mem, addr, val & 0xff);
    mem_set_uint8(mem, addr + 1, (val >> 8) & 0xff);
}

void e8086_mem_clear(){
    int i;
    // clear interrupts
    for (i = 0; i < 256*4; i++) {
        mem[i] = 0;
    }
    // set everything else to HLT instruction
    for (i = 1024; i < RAM_SIZE; i++){
        mem[i] = (unsigned char)0xF4;
    }
}

void e8086_mem_load_from_file(const char* fileName) {
    FILE* file;

    file = fopen(fileName, "rb");

    if (file != NULL) {
        size_t bytes_cnt = fread((void*)&mem[0x400], sizeof(unsigned char), 4096, file);
        fclose(file);
    }
}

void* get_mem_ptr() {
    return (void*)mem;
}
