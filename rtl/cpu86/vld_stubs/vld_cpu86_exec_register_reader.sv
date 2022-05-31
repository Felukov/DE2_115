module vld_cpu86_exec_register_reader (
    input logic             clk,
    input logic             resetn,

    input logic             vld_valid,
    input logic [4:0]       vld_op,
    input logic [3:0]       vld_code,
    input logic [15:0]      vld_cs,
    input logic [15:0]      vld_ip,
    input logic [15:0]      vld_ax,
    input logic [15:0]      vld_bx,
    input logic [15:0]      vld_cx,
    input logic [15:0]      vld_dx,
    input logic [15:0]      vld_bp,
    input logic [15:0]      vld_sp,
    input logic [15:0]      vld_si,
    input logic [15:0]      vld_di,
    input logic [15:0]      vld_fl,
    input logic [3:0]       vld_sreg,
    input logic [3:0]       vld_dreg
);

    // stub for synthesis

endmodule
