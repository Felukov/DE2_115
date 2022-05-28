#include <stdint.h>

void* get_mem_ptr();
unsigned char mem_get_uint8(void* _this, unsigned long addr);
unsigned short mem_get_uint16_le(void* _this, unsigned long addr);
void mem_set_uint8(void* _this, unsigned long addr, unsigned char val);
void mem_set_uint16_le(void* _this, unsigned long addr, unsigned short val);

void e8086_mem_clear();
void e8086_mem_load_from_file(const char* fileName);
