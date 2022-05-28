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


    cpu86_exec_ifeu_validator cpu86_exec_ifeu_validator_inst(
        .clk        (clk),
        .resetn     (resetn)
    );

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
        .interrupt_ack              (interrupt_ack)
    );


    assign io_req_tready = 1'b0;
    assign io_res_tvalid = 1'b0;
    assign io_res_tdata = '{default:'0};
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
        resetn = 1;
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
