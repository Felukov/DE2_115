#include <stdbool.h>

char instr_str[256];
unsigned short instr_cs;
unsigned short instr_ip;

unsigned short ax_val;
unsigned short bx_val;
unsigned short cx_val;
unsigned short dx_val;
unsigned short bp_val;
unsigned short sp_val;
unsigned short si_val;
unsigned short di_val;
unsigned short fl_val;

bool cpu_halted;
unsigned short cpu_new_cs;
unsigned short cpu_new_ip;

void e8086_cpu_create();
void e8086_cpu_reset();
void e8086_cpu_exec();
