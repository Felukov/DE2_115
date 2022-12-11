`timescale 1ns/1ns

module snake_tb;

    `define SEEK_SET 0
    `define SEEK_CUR 1
    `define SEEK_END 2

    logic                           clk = 0;
    logic                           resetn;

    logic [7:0]                     com_file[];
    logic                           tx_s_tvalid;
    logic                           tx_s_tready;
    logic [7:0]                     tx_s_tdata;
    logic                           tx_rx;

    logic [12:0]                    DRAM_ADDR;
    logic [1:0]                     DRAM_BA;
    logic                           DRAM_CAS_N;
    logic                           DRAM_CKE;
    logic                           DRAM_CS_N;
    wire  [31:0]                    DRAM_DQ;
    logic [3:0]                     DRAM_DQM;
    logic                           DRAM_RAS_N;
    logic                           DRAM_WE_N;
    logic [8:0]                     LEDG;
    logic [17:0]                    SW;
    logic [6:0]                     HEX0;
    logic [6:0]                     HEX1;
    logic [6:0]                     HEX2;
    logic [6:0]                     HEX3;
    logic [6:0]                     HEX4;
    logic [6:0]                     HEX5;
    logic [6:0]                     HEX6;
    logic [6:0]                     HEX7;

    logic                           ps_sdram_req_tvalid;
    logic                           ps_sdram_req_tready;
    logic [63:0]                    ps_sdram_req_tdata;
    logic                           ps_sdram_res_tvalid;
    logic [31:0]                    ps_sdram_res_tdata;

    wire                            ps2_clk_io;
    wire                            ps2_dat_io;
    reg                             ps2_wr  = 1'b0;
	reg                             ps2_clk = 1'b0;
	reg                             ps2_dat = 1'b0;

    assign ps2_clk_io = ps2_wr == 1 ? ps2_clk : 1'bz;
    assign ps2_dat_io = ps2_wr == 1 ? ps2_dat : 1'bz;

    soc_io_uart_tx #(
        .FREQ                       (100_000_000),
        .RATE                       (100_000_00)
    ) soc_io_uart_tx_inst (
        .clk                        (clk),
        .resetn                     (resetn),
        .tx_s_tvalid                (tx_s_tvalid),
        .tx_s_tready                (tx_s_tready),
        .tx_s_tdata                 (tx_s_tdata),
        .tx                         (tx_rx)
    );


    soc #(
        .FREQ                       (100_000_000),
        .UART_RATE                  (100_000_00),
        .RX_FIFO_SIZE               (4*1024),
        .TX_FIFO_SIZE               (4*1024)
    ) soc_inst(
        .clk                        (clk),
        .resetn                     (resetn),
        .m_axis_sdram_req_tvalid    (ps_sdram_req_tvalid),
        .m_axis_sdram_req_tready    (ps_sdram_req_tready),
        .m_axis_sdram_req_tdata     (ps_sdram_req_tdata),
        .s_axis_sdram_res_tvalid    (ps_sdram_res_tvalid),
        .s_axis_sdram_res_tdata     (ps_sdram_res_tdata),
        .sd_error                   (),
        .sd_disk_mounted            (),
        .sd_blocks                  (),
        .sd_io_lba                  (),
        .sd_io_rd                   (),
        .sd_io_wr                   (),
        .sd_io_ack                  (),
        .sd_io_din_tvalid           (),
        .sd_io_din_tdata            (),
        .sd_io_dout_tvalid          (),
        .sd_io_dout_tready          (),
        .sd_io_dout_tdata           (),
        .LEDG                       (LEDG),
        .SW                         (SW),
        .HEX0                       (HEX0),
        .HEX1                       (HEX1),
        .HEX2                       (HEX2),
        .HEX3                       (HEX3),
        .HEX4                       (HEX4),
        .HEX5                       (HEX5),
        .HEX6                       (HEX6),
        .HEX7                       (HEX7),
        .BT_UART_RX                 (tx_rx),
        .BT_UART_TX                 (),
		.PS2_CLK					(ps2_clk_io),
		.PS2_DAT					(ps2_dat_io)
    );


    sdram_system sdram_system_inst (
        .clk                        (clk),
        .resetn                     (resetn),
        .s_axis_req_tvalid          (ps_sdram_req_tvalid),
        .s_axis_req_tready          (ps_sdram_req_tready),
        .s_axis_req_tdata           (ps_sdram_req_tdata),
        .m_axis_res_tvalid          (ps_sdram_res_tvalid),
        .m_axis_res_tdata           (ps_sdram_res_tdata),
        .DRAM_ADDR                  (DRAM_ADDR),
        .DRAM_BA                    (DRAM_BA),
        .DRAM_CAS_N                 (DRAM_CAS_N),
        .DRAM_CKE                   (DRAM_CKE),
        .DRAM_CS_N                  (DRAM_CS_N),
        .DRAM_DQ                    (DRAM_DQ),
        .DRAM_DQM                   (DRAM_DQM),
        .DRAM_RAS_N                 (DRAM_RAS_N),
        .DRAM_WE_N                  (DRAM_WE_N)
    );


    sdram_test_model sdram_test_model_inst (
        .clk                        (clk),
        .zs_addr                    (DRAM_ADDR),
        .zs_ba                      (DRAM_BA),
        .zs_cas_n                   (DRAM_CAS_N),
        .zs_cke                     (DRAM_CKE),
        .zs_cs_n                    (DRAM_CS_N),
        .zs_dq                      (DRAM_DQ),
        .zs_dqm                     (DRAM_DQM),
        .zs_ras_n                   (DRAM_RAS_N),
        .zs_we_n                    (DRAM_WE_N)
    );


    // Assigns
    assign SW = '{default:'0};

    // clk
    initial begin
        clk = 0;
        forever begin
            #5   clk = ~clk;
        end
    end

    initial begin
        resetn = 0;
        repeat(40) @(posedge clk);
        resetn = 1;
    end

    // com file loader
    initial begin
        integer file, res, f_size;
        byte b8;
        file = $fopen("/home/fila/work/DE2_115/tbs/cpu86/snake/cstart.com", "rb");
        res = $fseek(file, 0, `SEEK_END);  /* End of file */
        f_size = $ftell(file);
        res = $fseek(file, 0, `SEEK_SET); /* Beginning */

        com_file = new[f_size + 4];

        com_file[0] = 8'h11;
        com_file[1] = 8'h55;
        com_file[2] = f_size[15:8];
        com_file[3] = f_size[7:0];

        for(int w = 4; w < f_size + 4; w++) begin
            res = $fread(b8, file);
            com_file[w] = b8;
        end

        $fclose(file);
    end

    // com file tx loader
    initial begin
		// Initialize Inputs
		ps2_clk    = 1'bz;
		ps2_dat    = 1'bz;
        ps2_wr     = 1'b0;

        tx_s_tvalid = 0;
        wait (resetn == 1);
        @(posedge clk);

        // enough time shoud pass for initial bootstrap code
        // to be ready to handle input data without delays
        // otherwise, if we start to send data to UART too early, there is
        // a risk to overflow uart rx queue
        repeat (500000) @(posedge clk);

        foreach(com_file[w]) begin
            tx_s_tvalid = 1;
            tx_s_tdata = com_file[w];
            @(posedge clk);
            while (tx_s_tready == 0) begin
                @(posedge clk);
            end
        end
        tx_s_tvalid = 0;
        @(posedge clk);

        repeat (1000000) @(posedge clk);

        ps2_wr = 1'b1;
        #100 ;

        #95  ps2_dat = 0; //START 0
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 1; //1
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 0; //2
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 1; //3
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 0; //4
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 1; //5
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 1; //6
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 1; //7
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 0; //8
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 0; //PARITY 9
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 1;// STOP 10
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 0; //START 0
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 0; //1
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 0; //2
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 0; //3
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 0; //4
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 1; //5
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 1; //6
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 1; //7
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 1; //8
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 1; //PARITY 9
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 1;// STOP 10
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;
        //BRAKE CODE
        #95  ps2_dat = 0; //START 0
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 1; //1
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 0; //2
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 1; //3
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 0; //4
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 1; //5
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 1; //6
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 1; //7
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 0; //8
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 0; //PARITY 9
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 1;// STOP 10
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 0; //START 0
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 1; //1
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 0; //2
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 1; //3
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 0; //4
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 1; //5
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 1; //6
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 1; //7
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 0; //8
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 0; //PARITY 9
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 1;// STOP 10
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 0; //START 0
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 0; //1
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 0; //2
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 0; //3
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 0; //4
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 1; //5
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 1; //6
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 1; //7
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 1; //8
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 1; //PARITY 9
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 1;// STOP 10
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;
        //BRAKE CODE
        #95  ps2_dat = 0; //START 0
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 1; //1
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 0; //2
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 1; //3
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 0; //4
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 1; //5
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 1; //6
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 1; //7
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 0; //8
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 0; //PARITY 9
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        #95  ps2_dat = 1;// STOP 10
        #5   ps2_clk = 0;
        #100 ps2_clk = 1;

        ps2_wr = 1'b0;

    end

endmodule
