`timescale 1ns/1ns

module cpu86_e8086_tb ();

    localparam int  TEST_IN_PROGRESS = 0;
    localparam int  TEST_DONE = 1;

    logic           clk = 0;
    logic           resetn;
    int             global_v;
    int             test_cnt;
    int             test_status;
    logic           mem_req_tvalid;
    logic           mem_req_tready;
    logic [63:0]    mem_req_tdata;
    logic           mem_res_tvalid;
    logic [31:0]    mem_res_tdata;
    logic           io_req_tvalid;
    logic           io_req_tready;
    logic [39:0]    io_req_tdata;
    logic           io_res_tvalid;
    logic           io_res_tready;
    logic [15:0]    io_res_tdata;

    logic           interrupt_valid;
    logic [7:0]     interrupt_data;
    logic           interrupt_ack;

    logic           dbg_out_rr_valid;
    logic [4:0]     dbg_out_rr_op;
    logic [3:0]     dbg_out_rr_code;
    logic [2:0]     dbg_out_rr_dir;
    logic [15:0]    dbg_out_rr_cs;
    logic [15:0]    dbg_out_rr_ip;
    logic [15:0]    dbg_out_rr_ax;
    logic [15:0]    dbg_out_rr_bx;
    logic [15:0]    dbg_out_rr_cx;
    logic [15:0]    dbg_out_rr_dx;
    logic [15:0]    dbg_out_rr_bp;
    logic [15:0]    dbg_out_rr_sp;
    logic [15:0]    dbg_out_rr_si;
    logic [15:0]    dbg_out_rr_di;
    logic [15:0]    dbg_out_rr_fl;
    logic [3:0]     dbg_out_rr_sreg;
    logic [3:0]     dbg_out_rr_dreg;


    // module cpu86_e8086_mem instantiation
    cpu86_e8086_mem cpu86_e8086_mem_inst(
        // clk & reset
        .clk                        (clk),
        .resetn                     (resetn),
        // s_axis_req
        .s_axis_req_tvalid          (mem_req_tvalid),
        .s_axis_req_tready          (mem_req_tready),
        .s_axis_req_tdata           (mem_req_tdata),
        // m_axis_res
        .m_axis_res_tvalid          (mem_res_tvalid),
        .m_axis_res_tdata           (mem_res_tdata)
    );

    // module cpu86_e8086_io instantiation
    cpu86_e8086_io cpu86_e8086_io_inst(
        // clk & reset
        .clk                        (clk),
        .resetn                     (resetn),
        // s_axis_req
        .s_axis_req_tvalid          (io_req_tvalid),
        .s_axis_req_tready          (io_req_tready),
        .s_axis_req_tdata           (io_req_tdata),
        // m_axis_res
        .m_axis_res_tvalid          (io_res_tvalid),
        .m_axis_res_tdata           (io_res_tdata)
    );


    // module cpu86 instantiation
    cpu86 cpu86_inst (
        // clk & reset
        .clk                        (clk),
        .resetn                     (resetn),
        // m_axis_mem_req
        .m_axis_mem_req_tvalid      (mem_req_tvalid),
        .m_axis_mem_req_tready      (mem_req_tready),
        .m_axis_mem_req_tdata       (mem_req_tdata),
        // s_axis_mem_res
        .s_axis_mem_res_tvalid      (mem_res_tvalid),
        .s_axis_mem_res_tdata       (mem_res_tdata),
        // m_axis_io_req
        .m_axis_io_req_tvalid       (io_req_tvalid),
        .m_axis_io_req_tready       (io_req_tready),
        .m_axis_io_req_tdata        (io_req_tdata),
        // s_axis_io_res
        .s_axis_io_res_tvalid       (io_res_tvalid),
        .s_axis_io_res_tready       (io_res_tready),
        .s_axis_io_res_tdata        (io_res_tdata),
        // interrupt
        .interrupt_valid            (interrupt_valid),
        .interrupt_data             (interrupt_data),
        .interrupt_ack              (interrupt_ack),
        // dbg register reader interface
        .dbg_out_rr_valid           (dbg_out_rr_valid),
        .dbg_out_rr_cs              (dbg_out_rr_cs),
        .dbg_out_rr_ip              (dbg_out_rr_ip),
        .dbg_out_rr_op              (dbg_out_rr_op),
        .dbg_out_rr_code            (dbg_out_rr_code),
        .dbg_out_rr_dir             (dbg_out_rr_dir),
        .dbg_out_rr_sreg            (dbg_out_rr_sreg),
        .dbg_out_rr_dreg            (dbg_out_rr_dreg),
        .dbg_out_rr_ax              (dbg_out_rr_ax),
        .dbg_out_rr_bx              (dbg_out_rr_bx),
        .dbg_out_rr_cx              (dbg_out_rr_cx),
        .dbg_out_rr_dx              (dbg_out_rr_dx),
        .dbg_out_rr_bp              (dbg_out_rr_bp),
        .dbg_out_rr_sp              (dbg_out_rr_sp),
        .dbg_out_rr_di              (dbg_out_rr_di),
        .dbg_out_rr_si              (dbg_out_rr_si),
        .dbg_out_rr_fl              (dbg_out_rr_fl)
    );

    vld_cpu86_exec_register_reader vld_cpu86_exec_register_reader_inst(
        // clk & reset
        .clk                        (clk),
        .resetn                     (resetn),
        // dbg register reader interface
        .vld_valid                  (dbg_out_rr_valid),
        .vld_cs                     (dbg_out_rr_cs),
        .vld_ip                     (dbg_out_rr_ip),
        .vld_op                     (dbg_out_rr_op),
        .vld_dir                    (dbg_out_rr_dir),
        .vld_code                   (dbg_out_rr_code),
        .vld_sreg                   (dbg_out_rr_sreg),
        .vld_dreg                   (dbg_out_rr_dreg),
        .vld_ax                     (dbg_out_rr_ax),
        .vld_bx                     (dbg_out_rr_bx),
        .vld_cx                     (dbg_out_rr_cx),
        .vld_dx                     (dbg_out_rr_dx),
        .vld_bp                     (dbg_out_rr_bp),
        .vld_sp                     (dbg_out_rr_sp),
        .vld_di                     (dbg_out_rr_di),
        .vld_si                     (dbg_out_rr_si),
        .vld_fl                     (dbg_out_rr_fl)
    );


    assign interrupt_valid = 1'b0;


    // clk
    initial begin
        clk = 0;
        forever begin
            #5 clk = ~clk;
        end
    end

    // resetn
    initial begin
        reset_tb();

        c_tb_init("C:\\Projects\\DE2_115\\tbs\\cpu86\\golden_ref\\bin", test_cnt);

        @(posedge clk);
        wait (resetn == 1);

        $display("Before calling C Method");
        c_method();
        $display("After calling C Method");

        for (int i = 0; i < test_cnt; i++) begin
            // test initilization
            c_tb_set_test(i);
            c_tb_get_test_status(test_status);

            // looping until the current test is done
            while (test_status == TEST_IN_PROGRESS) begin
                @(posedge clk);
                c_tb_get_test_status(test_status);
            end

            // reset dut
            if (test_status == TEST_DONE) begin
                $display("%t :: Test %0d completed", $time, i);
                if (i < test_cnt -1) begin
                    reset_tb();
                end
            end
        end
        $display("%t :: All tests completed", $time);

        @(posedge clk);
        resetn = 0;
        for (int i = 0; i < 100; i++) begin
            @(posedge clk);
        end
        $finish(0);
    end


    task reset_tb;
        @(posedge clk);
        resetn = 0;
        repeat (40) @(posedge clk);
        resetn <= 1;
    endtask;

    export "DPI-C" function dpi_print;
    import "DPI-C" function void c_tb_init(input string dir, output int test_cnt);
    import "DPI-C" function void c_tb_set_test(input int test_idx);
    import "DPI-C" function void c_tb_get_test_status(output int ret_val);
    import "DPI-C" function void c_method();
    import "DPI-C" function void c_counter(output int c);

    function void dpi_print(input string msg);
        $display("%t :: %s", $time, msg);
    endfunction : dpi_print

endmodule
