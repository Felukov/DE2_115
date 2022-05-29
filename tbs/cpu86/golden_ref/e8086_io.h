void e8086_io_clear();

unsigned char io_get_uint8(void* _this, unsigned long addr);
unsigned short io_get_uint16(void* _this, unsigned long addr);
void io_set_uint8(void* _this, unsigned long addr, unsigned char val);
void io_set_uint16(void* _this, unsigned long addr, unsigned short val);
