module vld_cpu86_exec_register_reader (
    input logic             clk,
    input logic             resetn,

    input logic             vld_valid,
    input logic [4:0]       vld_op,
    input logic [2:0]       vld_dir,
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
        MOVU,
        ALU,
        DIVU,
        MULU,
        FEU,
        STACKU,
        LOOPU,
        JMPU,
        BRANCH,
        JCALL,
        RET,
        PREFIX,
        STR,
        SET_FLAG,
        XCHG,
        SYS,
        LFP,
        SHFU,
        BCDU,
        IO,
        ILLEGAL
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

    typedef enum logic[2:0] {
        R2R = 3'd0,
        M2R = 3'd1,
        R2M = 3'd2,
        I2R = 3'd3,
        I2M = 3'd4,
        R2F = 3'd5,
        M2M = 3'd6
    } dir_t;

    localparam logic [3:0] STACKU_POPM    = 4'b0000;
    localparam logic [3:0] STACKU_POPR    = 4'b0001;
    localparam logic [3:0] STACKU_POPA    = 4'b0100;

    localparam logic [3:0] STACKU_PUSHR   = 4'b1000;
    localparam logic [3:0] STACKU_PUSHI   = 4'b1010;
    localparam logic [3:0] STACKU_PUSHM   = 4'b1011;
    localparam logic [3:0] STACKU_PUSHA   = 4'b1100;
    localparam logic [3:0] STACKU_ENTER   = 4'b1101;
    localparam logic [3:0] STACKU_LEAVE   = 4'b1110;

    localparam logic [3:0] MOVS_OP        = 4'b0000;
    localparam logic [3:0] STOS_OP        = 4'b0001;
    localparam logic [3:0] LODS_OP        = 4'b0010;
    localparam logic [3:0] CMPS_OP        = 4'b0011;
    localparam logic [3:0] SCAS_OP        = 4'b0100;
    localparam logic [3:0] OUTS_OP        = 4'b1000;
    localparam logic [3:0] OUT_OP         = 4'b1001;
    localparam logic [3:0] INS_OP         = 4'b1010;
    localparam logic [3:0] IN_OP          = 4'b1011;

    localparam logic [3:0] PREFIX_REPZ    = 4'b0000;
    localparam logic [3:0] PREFIX_REPNZ   = 4'b0001;
    localparam logic [3:0] PREFIX_LOCK    = 4'b0010;
    localparam logic [3:0] PREFIX_SEGM    = 4'b0011;

    localparam integer     CF             = 0;
    localparam integer     PF             = 2;
    localparam integer     AF             = 4;
    localparam integer     ZF             = 6;
    localparam integer     SF             = 7;
    localparam integer     TF             = 8;
    localparam integer     IF             = 9;
    localparam integer     DF             = 10;
    localparam integer     OF             = 11;

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
    bit             sim_completed = 0;
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
    dir_t           dut_dir;
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
            dut_dir     <= R2R;
            sim_completed  <= 0;
        end else begin
            check_event <= vld_valid;

            if (vld_valid == 1'b1 && (
                (sim_completed == 1'b0) || (sim_completed == 1'b1 && sim_new_cs == vld_cs && sim_new_ip == vld_ip)))
            begin

                c_tb_cpu_exec(
                    instr_str,
                    sim_cs, sim_ip,
                    sim_ax, sim_bx, sim_cx, sim_dx,
                    sim_bp, sim_sp, sim_si, sim_di,
                    sim_fl,
                    sim_completed, sim_new_cs, sim_new_ip
                );

                dut_cs           <= vld_cs;
                dut_ip           <= vld_ip;
                dut_op           <= opcode_t'(vld_op);
                dut_code         <= vld_code;
                dut_ax           <= vld_ax;
                dut_bx           <= vld_bx;
                dut_cx           <= vld_cx;
                dut_dx           <= vld_dx;
                dut_bp           <= vld_bp;
                dut_sp           <= vld_sp;
                dut_si           <= vld_si;
                dut_di           <= vld_di;
                dut_fl           <= vld_fl;
                dut_sreg         <= reg_t'(vld_sreg);
                dut_dreg         <= reg_t'(vld_dreg);
                dut_dir          <= dir_t'(vld_dir);
            end
        end
    end

    initial begin
        // try_next_csip = 0;
        forever begin
            @(negedge clk);
            if (resetn == 1'b1 && check_event == 1'b1) begin

                // if (dut_op == BRANCH) begin
                //     // it could be misprediction
                //     try_next_csip = 1;
                // end else if (try_next_csip == 1) begin
                //     if (sim_ip == dut_ip && sim_cs == dut_cs) begin
                //         try_next_csip = 0;
                //     end else begin
                //         $error("CS:IP mismatch after jump");
                //     end
                // end

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
                check_movs();
                check_stos();
                check_scas();
                check_cmps();
                check_lods();
                check_ins();
                check_outs();
                check_lahf();

                check_mov();
                if (error_cnt > 100) begin
                    $display("too many errors");
                    $stop();
                end
            end
        end
    end

    task check_mov;
        if (dut_op == MOVU && dut_dir == R2R) begin
            check_sreg;
        end
    endtask

    task check_lahf;
        if (dut_op == MOVU && dut_dir == R2F && dut_sreg == FL) begin
            check_fl;
        end
    endtask

    task check_ins;
        if (dut_op == STR && dut_code == INS_OP) begin
            check_di();
            check_fl();
        end
    endtask

    task check_outs;
        if (dut_op == STR && dut_code == INS_OP) begin
            check_si();
            check_fl();
        end
    endtask

    task check_lods;
        if (dut_op == STR && dut_code == LODS_OP) begin
            check_si();
            check_fl();
        end
    endtask

    task check_cmps;
        if (dut_op == STR && dut_code == CMPS_OP) begin
            check_di();
            check_si();
            check_fl();
        end
    endtask

    task check_scas;
        if (dut_op == STR && dut_code == SCAS_OP) begin
            check_ax();
            check_di();
            check_fl();
        end
    endtask

    task check_stos;
        if (dut_op == STR && dut_code == STOS_OP) begin
            check_ax();
            check_di();
            check_fl();
        end
    endtask

    task check_movs;
        if (dut_op == STR && dut_code == MOVS_OP) begin
            check_di();
            check_si();
            check_fl();
        end
    endtask

    task check_xchg;
        if (dut_op == XCHG) begin
            check_ax();
        end
    endtask

    task check_rep;
        if ((dut_op == PREFIX && dut_code == PREFIX_REPZ) ||
            (dut_op == PREFIX && dut_code == PREFIX_REPNZ)) begin
            check_cx();
        end
    endtask

    task check_pusha;
        if (dut_op == STACKU && (dut_code == STACKU_PUSHA)) begin
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
            check_sp();
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

    task check_fl_bit(int bit_idx);
        if (dut_fl[bit_idx] != sim_fl[bit_idx]) begin
            $error("FL(%0d) mismatch", bit_idx);
            error_cnt++;
        end
    endtask

    task check_fl;
        check_fl_bit(CF);
        check_fl_bit(PF);
        check_fl_bit(AF);
        check_fl_bit(ZF);
        check_fl_bit(SF);
        check_fl_bit(TF);
        check_fl_bit(IF);
        check_fl_bit(DF);
        check_fl_bit(OF);
    endtask

    import "DPI-C" function void c_tb_cpu_exec(
        output string str,
        output int cs, output int ip,
        output int ax, output int bx, output int cx, output int dx,
        output int bp, output int sp, output int si, output int di,
        output int fl,
        output int completed, output int new_cs, output int new_js
    );

endmodule
