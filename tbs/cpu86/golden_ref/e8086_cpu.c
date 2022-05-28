#include <string.h>

#include "e8086_cpu.h"
#include "e8086/e8086.h"
#include "e8086_memory.h"
#include "e8086_io.h"

e8086_t* cpu8086;

#define MEM_SIZE 1024*1024

void e8086_cpu_create(){

    cpu8086 = e86_new();

    e86_set_80186(cpu8086);

    // setting prefetch queue intentionally bigger
    // than the max size of instruction (6 bytes)
    // to be able indirectly analyze jumps
    e86_set_pq_size (cpu8086, 8);

    e86_set_mem(cpu8086, NULL,
        (e86_get_uint8_f)&mem_get_uint8,
        (e86_set_uint8_f)&mem_set_uint8,
        (e86_get_uint16_f)&mem_get_uint16_le,
        (e86_set_uint16_f)&mem_set_uint16_le
    );

    e86_set_prt(cpu8086, NULL,
        (e86_get_uint8_f)&io_get_uint8,
        (e86_set_uint8_f)&io_set_uint8,
        (e86_get_uint16_f)&io_get_uint16,
        (e86_set_uint16_f)&io_set_uint16
    );

    e86_set_ram(cpu8086, get_mem_ptr(), MEM_SIZE);

}

void e8086_cpu_reset(){
    cpu_halted = false;

    e86_reset(cpu8086);
    e86_set_cs(cpu8086, 0x0000);
    e86_set_ip(cpu8086, 0x0400);
    e86_set_flags(cpu8086, 0x0202);

}

static void disasm_str(char* dst, e86_disasm_t* op) {
    unsigned     i;
    unsigned     dst_i = 0;

    if ((op->flags & ~(E86_DFLAGS_CALL | E86_DFLAGS_LOOP)) != 0) {
        unsigned flg;

        flg = op->flags;

        dst[dst_i++] = '[';

        if (flg & E86_DFLAGS_186) {
            dst_i += sprintf(dst + dst_i, "186");
            flg &= ~E86_DFLAGS_186;
        }

        if (flg != 0) {
            if (flg != op->flags) {
                dst[dst_i++] = ' ';
            }
            dst_i += sprintf(dst + dst_i, " %04X", flg);
        }
        dst[dst_i++] = ']';
        dst[dst_i++] = ' ';
    }

    strcpy(dst + dst_i, op->op);
    while (dst[dst_i] != 0) {
        dst_i += 1;
    }

    if (op->arg_n > 0) {
        dst[dst_i++] = ' ';
    }

    if (op->arg_n == 1) {
        dst_i += sprintf(dst + dst_i, "%s", op->arg1);
    } else if (op->arg_n == 2) {
        dst_i += sprintf(dst + dst_i, "%s, %s", op->arg1, op->arg2);
    }

    dst[dst_i] = 0;
}

void e8086_cpu_exec() {
    if (cpu_halted) {
        return;
    }

    e86_disasm_t op;

    e86_disasm_cur(cpu8086, &op);

    cpu_jumped = false;
    instr_cs = e86_get_cs(cpu8086);
    instr_ip = e86_get_ip(cpu8086);

    disasm_str(instr_str, &op);

    e86_execute(cpu8086);
    ax_val = (unsigned int)e86_get_ax(cpu8086);
    bx_val = (unsigned int)e86_get_bx(cpu8086);
    cx_val = (unsigned int)e86_get_cx(cpu8086);
    dx_val = (unsigned int)e86_get_dx(cpu8086);
    bp_val = (unsigned int)e86_get_bp(cpu8086);
    sp_val = (unsigned int)e86_get_sp(cpu8086);
    si_val = (unsigned int)e86_get_si(cpu8086);
    di_val = (unsigned int)e86_get_di(cpu8086);
    fl_val = (unsigned int)e86_get_flags(cpu8086);

    if (cpu8086->state == E86_STATE_HALT){
        cpu_halted = true;
        snprintf(instr_str, sizeof(instr_str), "%s", "cpu halted");
    }

    if (cpu8086->pq_cnt == 0){
        // prefetch queue is empty so the cpu jumped somewhere
        cpu_jumped = true;
        cpu_new_cs = e86_get_cs(cpu8086);
        cpu_new_ip = e86_get_ip(cpu8086);
    }
}
