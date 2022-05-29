#include "cpu86_e8086_tb.h"
#include "hdl_io_model.h"

#define IO_MEM_SIZE 0x10000

unsigned short hdl_io_port[IO_MEM_SIZE];

void hdl_io_clear(){
    unsigned int i;
    for (i = 0; i < IO_MEM_SIZE; i++) {
        hdl_io_port[i] = 0x0;
    }
}

void c_io_write(int addr, int val) {
    if (addr >= 0 && addr < IO_MEM_SIZE) {
        hdl_io_port[addr] = (unsigned short)val;
    } else {
        dpi_print ("c_io_write: invalid address");
    }
}

void c_io_read(int addr, int *value) {
    if (addr >= 0 && addr < IO_MEM_SIZE) {
        *(value) = (unsigned int)hdl_io_port[addr];
    } else {
        *(value) = 0x0;
        dpi_print ("c_io_read: invalid address");
    }
}
