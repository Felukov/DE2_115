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
        SHFU      = 5'b10011,
        BCDU      = 5'b10100,
        IO        = 5'b10101,
        ILLEGAL   = 5'b10110
    } opcode_t;

    typedef enum logic[3:0] {
        AX = 4'd0,
        DX = 4'd1,
        CX = 4'd2,
        BX = 4'd3,
        BP = 4'd4,
        SI = 4'd5,
        DI = 4'd6,
        SP = 4'd7,
        ES = 4'd8,
        CS = 4'd9,
        SS = 4'd10,
        DS = 4'd11,
        FL = 4'd12
    } reg_t;

    localparam logic [3:0] STACKU_POPM    = 4'b0000;
    localparam logic [3:0] STACKU_POPR    = 4'b0001;
    localparam logic [3:0] STACKU_POPA    = 4'b0100;

    localparam logic [3:0] STACKU_PUSHR   = 4'b1000;
    localparam logic [3:0] STACKU_PUSHI   = 4'b1010;
    localparam logic [3:0] STACKU_PUSHM   = 4'b1011;
    localparam logic [3:0] STACKU_PUSHA   = 4'b1100;
    localparam logic [3:0] STACKU_ENTER   = 4'b1101;
    localparam logic [3:0] STACKU_LEAVE   = 4'b1110;

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
    reg_t           dut_sreg;
    reg_t           dut_dreg;

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
            dut_sreg    <= AX;
            dut_dreg    <= AX;
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
                dut_sreg <= reg_t'(vld_sreg);
                dut_dreg <= reg_t'(vld_dreg);
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

                check_pusha();
                check_push_reg();
                check_xchg();
                check_rep();
                if (error_cnt > 100) begin
                    $display("too many errors");
                    $stop();
                end
            end
        end
    end

    task check_xchg;
        if (dut_op == XCHG) begin
            check_ax();
        end
    endtask

    task check_rep;
        if (dut_op == REP) begin
            check_cx();
        end
    endtask

    task check_pusha;
        if (dut_op == STACKU && (dut_code == STACKU_POPA || dut_code == STACKU_PUSHA)) begin
            check_ax();
            check_bx();
            check_cx();
            check_dx();
            check_bp();
            check_sp();
            check_si();
            check_di();
        end
    endtask

    task check_push_reg;
        if (dut_op == STACKU && (dut_code == STACKU_PUSHR)) begin
            check_sreg();
        end
    endtask

    task check_sreg;
        case (dut_sreg)
            AX : check_ax();
            DX : check_dx();
            CX : check_cx();
            BX : check_bx();
            BP : check_bp();
            SI : check_si();
            DI : check_di();
            SP : check_sp();
            ES : ;
            CS : ;
            SS : ;
            DS : ;
            FL : check_fl();
        endcase
    endtask

    task check_dreg;
        case (dut_dreg)
            AX : check_ax();
            DX : check_dx();
            CX : check_cx();
            BX : check_bx();
            BP : check_bp();
            SI : check_si();
            DI : check_di();
            SP : check_sp();
            ES : ;
            CS : ;
            SS : ;
            DS : ;
            FL : check_fl();
        endcase
    endtask

    task check_ax;
        if (dut_ax != sim_ax) begin
            $error("AX mismatch");
            error_cnt++;
        end
    endtask

    task check_bx;
        if (dut_bx != sim_bx) begin
            $error("BX mismatch");
            error_cnt++;
        end
    endtask

    task check_cx;
        if (dut_cx != sim_cx) begin
            $error("CX mismatch");
            error_cnt++;
        end
    endtask

    task check_dx;
        if (dut_dx != sim_dx) begin
            $error("DX mismatch");
            error_cnt++;
        end
    endtask

    task check_bp;
        if (dut_bp != sim_bp) begin
            $error("BP mismatch");
            error_cnt++;
        end
    endtask

    task check_sp;
        if (dut_sp != sim_sp) begin
            $error("SP mismatch");
            error_cnt++;
        end
    endtask

    task check_si;
        if (dut_si != sim_si) begin
            $error("SI mismatch");
            error_cnt++;
        end
    endtask

    task check_di;
        if (dut_di != sim_di) begin
            $error("DI mismatch");
            error_cnt++;
        end
    endtask

    task check_fl;
        if (dut_fl != sim_fl) begin
            $error("FL mismatch");
            error_cnt++;
        end
    endtask

    import "DPI-C" function void c_tb_cpu_exec(
        output string str,
        output int cs, output int ip,
        output int ax, output int bx, output int cx, output int dx,
        output int bp, output int sp, output int si, output int di,
        output int fl,
        output int jumped, output int new_cs, output int new_js
    );

endmodule
