#include <stdio.h>
#include <stdlib.h>
#include "cpu86_e8086_tb.h"
#include "hdl_mem_model.h"

#define MEM_SIZE 1024*1024

unsigned char hdl_mem[MEM_SIZE];

void c_mem_write_b(int addr, int val) {
    if (addr >= 0 && addr < MEM_SIZE) {
        hdl_mem[addr] = (unsigned char)val;
    } else {
        dpi_print ("c_mem_write_b: invalid address");
    }
}

void c_mem_read_b(int addr, int *value) {
    if (addr >= 0 && addr < MEM_SIZE) {
        *(value) = (unsigned int)hdl_mem[addr];
    } else {
        *(value) = 0x0;
        dpi_print ("c_mem_read_b: invalid address");
    }
}

void hdl_mem_clear(){
    int i;
    // clear interrupts
    for (i = 0; i < 256*4; i++) {
        hdl_mem[i] = 0;
    }
    // set everything else to HLT instruction
    for (i = 1024; i < MEM_SIZE; i++){
        hdl_mem[i] = (unsigned char)0xF4;
    }
}

void hdl_mem_load_from_file(const char* fileName) {
    FILE* file;

    file = fopen(fileName, "rb");

    if (file != NULL) {
        size_t bytes_cnt = fread((void*)&hdl_mem[0x400], sizeof(unsigned char), 4096, file);
        fclose(file);
    } else {
        dpi_print("Cannot initialize memory with ROM contents");
    }
}
