#include <stdio.h>
#include <stdlib.h>
#include <windows.h>

#include "cpu86_e8086_tb.h"
#include "hdl_mem_model.h"
#include "hdl_io_model.h"
#include "e8086/e8086.h"
#include "e8086_memory.h"
#include "e8086_io.h"
#include "e8086_cpu.h"

#define TEST_IN_PROGRESS 0
#define TEST_DONE 1

char bin_dir[MAX_PATH];
char bin_files[256][MAX_PATH];
int bin_files_cnt;

// prototypes
void c_tb_init();
void find_bins(const char* pattern);

// implementation
void c_method() {
    dpi_print ("Hello World...!");
}

int counter = 0;
void c_counter(int* c) {
    counter++;
    *(c) = counter;
}

void c_tb_init(const char* dir, int* test_cnt){
    char buf[MAX_PATH];

    snprintf(bin_dir, sizeof(bin_dir), "%s", dir);
    snprintf(buf, sizeof(buf), "%s%s", dir, "\\*.bin");

    find_bins(buf);

    e8086_cpu_create();

    // output
    *(test_cnt) = bin_files_cnt;
}

void c_tb_set_test(int test_idx){
    char filename[MAX_PATH];
    snprintf(filename, sizeof(filename), "%s%s%s", bin_dir, "\\", bin_files[test_idx]);

    dpi_print(filename);

    // initializing hdl memory model
    hdl_mem_clear();
    hdl_mem_load_from_file(filename);

    hdl_io_clear();

    // initializing e8086 simulator memory
    e8086_mem_clear();
    e8086_mem_load_from_file(filename);
    e8086_io_clear();

    // resetting e8086 simulator cpu
    e8086_cpu_reset();

    dpi_print("memory loading completed");
}

void c_tb_get_test_status(int* ret_val){
    if (cpu_halted) {
        *(ret_val) = TEST_DONE;
    } else {
        *(ret_val) = TEST_IN_PROGRESS;
    }
}

void c_tb_cpu_exec(
    const char** str,
    int* cs, int* ip,
    int* ax, int* bx, int* cx, int *dx,
    int* bp, int* sp, int* si, int *di,
    int* fl,
    int* completed, int* new_cs, int* new_ip
){
    *(ax) = ax_val;
    *(bx) = bx_val;
    *(cx) = cx_val;
    *(dx) = dx_val;
    *(bp) = bp_val;
    *(sp) = sp_val;
    *(si) = si_val;
    *(di) = di_val;
    *(fl) = fl_val;

    e8086_cpu_exec();

    *(cs) = instr_cs;
    *(ip) = instr_ip;

    *(str) = &instr_str[0];

    *(completed) = 1;
    *(new_cs) = cpu_new_cs;
    *(new_ip) = cpu_new_ip;
}

void find_bins(const char* pattern){
    HANDLE hFind;
    WIN32_FIND_DATA FindData;
    int bin_files_idx;

    bin_files_cnt = 0;
    bin_files_idx = 0;

    hFind = FindFirstFile(pattern, &FindData);
    if (INVALID_HANDLE_VALUE == hFind) {
        dpi_print("error: binaries not found");
        return;
    }

    snprintf(bin_files[bin_files_idx], sizeof(bin_files[bin_files_idx]), "%s", FindData.cFileName);
    dpi_print(bin_files[bin_files_idx]);
    bin_files_idx++;

    while (FindNextFile(hFind, &FindData)) {
        if (bin_files_idx == 255) {
            dpi_print("warning: too many binaries. only the first 256 will be used");
            break;
        }
        snprintf(bin_files[bin_files_idx], sizeof(bin_files[bin_files_idx]), "%s", FindData.cFileName);
        dpi_print(bin_files[bin_files_idx]);
        bin_files_idx++;
    }
    // Close the file handle
    FindClose(hFind);
    bin_files_cnt = bin_files_idx;
}
