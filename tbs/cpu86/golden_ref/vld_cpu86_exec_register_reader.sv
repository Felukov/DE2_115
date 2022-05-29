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
    input logic [15:0]      vld_fl
);
    // instruction execution starts here

    typedef enum logic[4:0] {
        MOVU      = 5'b00000,
        ALU       = 5'b00001,
        DIVU      = 5'b00010,
        MULU      = 5'b00011,
        FEU       = 5'b00100,
        STACKU    = 5'b00101,
        LOOPU     = 5'b00110,
        JMPU      = 5'b00111,
        BRANCH    = 5'b01000,
        JCALL     = 5'b01001,
        RET       = 5'b01010,
        SET_SEG   = 5'b01011,
        REP       = 5'b01100,
        STR       = 5'b01101,
        SET_FLAG  = 5'b01110,
        DBG       = 5'b01111,
        XCHG      = 5'b10000,
        SYS       = 5'b10001,
        LFP       = 5'b10010,
        ONEU      = 5'b10011,
        SHFU      = 5'b10100,
        BCDU      = 5'b10101,
        IO        = 5'b10110,
        ILLEGAL   = 5'b10111
    } opcode_t;

    bit             check_event;
    bit [15:0]      sim_cs;
    bit [15:0]      sim_ip;
    bit [15:0]      sim_ax;
    bit [15:0]      sim_bx;
    bit [15:0]      sim_cx;
    bit [15:0]      sim_dx;
    bit [15:0]      sim_bp;
    bit [15:0]      sim_sp;
    bit [15:0]      sim_si;
    bit [15:0]      sim_di;
    bit [15:0]      sim_fl;
    bit             sim_jumped = 0;
    bit [15:0]      sim_new_cs;
    bit [15:0]      sim_new_ip;

    opcode_t        dut_op;
    bit [3:0]       dut_code;
    bit [15:0]      dut_cs;
    bit [15:0]      dut_ip;
    bit [15:0]      dut_ax;
    bit [15:0]      dut_bx;
    bit [15:0]      dut_cx;
    bit [15:0]      dut_dx;
    bit [15:0]      dut_bp;
    bit [15:0]      dut_sp;
    bit [15:0]      dut_si;
    bit [15:0]      dut_di;
    bit [15:0]      dut_fl;
    string          instr_str;

    int             error_cnt = 0;

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            check_event <= 1'b0;
            sim_cs      <= -1;
            sim_ip      <= -1;
            dut_cs      <= '{default:'0};
            dut_ip      <= '{default:'0};
            dut_ax      <= '{default:'0};
            dut_bx      <= '{default:'0};
            dut_cx      <= '{default:'0};
            dut_dx      <= '{default:'0};
            dut_bp      <= '{default:'0};
            dut_sp      <= '{default:'0};
            dut_si      <= '{default:'0};
            dut_di      <= '{default:'0};
            dut_fl      <= '{default:'0};
            instr_str   <= "invalid";
        end else begin
            check_event <= vld_valid;

            if (vld_valid == 1'b1 && (
                (sim_jumped == 1'b0) ||
                (sim_jumped == 1'b1 && sim_new_cs == vld_cs && sim_new_ip == vld_ip)))
            begin

                c_tb_cpu_exec(
                    instr_str,
                    sim_cs, sim_ip,
                    sim_ax, sim_bx, sim_cx, sim_dx,
                    sim_bp, sim_sp, sim_si, sim_di,
                    sim_fl,
                    sim_jumped, sim_new_cs, sim_new_ip
                );

                dut_cs   <= vld_cs;
                dut_ip   <= vld_ip;
                dut_op   <= opcode_t'(vld_op);
                dut_code <= vld_code;
                dut_ax   <= vld_ax;
                dut_bx   <= vld_bx;
                dut_cx   <= vld_cx;
                dut_dx   <= vld_dx;
                dut_bp   <= vld_bp;
                dut_sp   <= vld_sp;
                dut_si   <= vld_si;
                dut_di   <= vld_di;
                dut_fl   <= vld_fl;
            end
        end
    end

    initial begin
        forever begin
            @(negedge clk);
            if (resetn == 1'b1 && check_event == 1'b1) begin
                if (sim_ip != dut_ip) begin
                    $error("IP mismatch");
                    error_cnt++;
                end

                if (sim_cs != dut_cs) begin
                    $error("CS mismatch");
                    error_cnt++;
                end

                check_xchg();

                if (error_cnt > 100) begin
                    $display("too many errors");
                    $stop();
                end
            end
        end
    end

    task check_xchg;
        if (dut_op == XCHG) begin
            if (dut_ax != sim_ax) begin
                $error("AX mismatch");
                error_cnt++;
            end
        end
    endtask;

    import "DPI-C" function void c_tb_cpu_exec(
        output string str,
        output int cs, output int ip,
        output int ax, output int bx, output int cx, output int dx,
        output int bp, output int sp, output int si, output int di,
        output int fl,
        output int jumped, output int new_cs, output int new_js
    );

endmodule
