`timescale 1ns/1ns

module sdcard_tb ();

    logic           clk = 0;
    logic           resetn;

    logic           sd_clk;
    wire            sd_cmd;
    wire [3:0]      sd_dat;
    logic           sd_active;
    logic           sd_error;
    logic           sd_mounted;
    logic           d_sd_mounted;
    logic [21:0]    blocks;

    logic [31:0]    io_lba;
    logic           io_rd;
    logic           io_wr;
    logic           io_ack;
    logic [7:0]     io_din;
    logic           io_din_tvalid;
    logic [7:0]     io_dout;
    logic           io_dout_tvalid;

    assign          io_lba = 1'b0;
    //assign          io_rd = 1'b0;
    //assign          io_wr = 1'b0;
    //assign          io_dout = '{default:'0};

    sdcard_subsystem sdcard_subsystem_inst (
        .clk            (clk),
        .resetn         (resetn),
        .sd_clk         (sd_clk),
        .sd_cmd         (sd_cmd),
        .sd_dat         (sd_dat),
        .sd_active      (sd_active),
        .sd_read        (),
        .sd_write       (),
        .event_error    (sd_error),
        .disk_mounted   (sd_mounted),
        .blocks         (blocks),
        .io_lba         (io_lba),
        .io_rd          (io_rd),
        .io_wr          (io_wr),
        .io_ack         (io_ack),
        .io_din         (io_din),
        .io_din_tvalid  (io_din_tvalid),
        .io_dout        (io_dout),
        .io_dout_tvalid (io_dout_tvalid)
    );

    sd_model #(
        .log_file       ("C:/Projects/DE2_115/tbs/sdcard/log.txt")
    ) sd_model(
        .sd_clk         (sd_clk),
        .cmd            (sd_cmd),
        .dat            (sd_dat)
    );

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            d_sd_mounted <= 1'b0;
        end else begin
            d_sd_mounted <= sd_mounted;
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            io_rd <= 1'b0;
            io_wr <= 1'b0;
        end else begin
            if (d_sd_mounted == 1'b0 && sd_mounted == 1'b1) begin
                //io_rd <= 1'b1;
                io_wr <= 1'b1;
            end else if (io_wr == 1'b1 && io_ack == 1'b1) begin
                //io_rd <= 1'b0;
                io_wr <= 1'b0;
            end
        end
    end

    initial begin
        @(posedge clk);
        wait (resetn == 1);

        io_dout <= 16'hFA;

        while (io_dout_tvalid == 1'b0) begin
            @(posedge clk);
        end
        io_dout <= 16'h33;
        @(posedge clk);

        while (io_dout_tvalid == 1'b0) begin
            @(posedge clk);
        end
        io_dout <= 16'hC0;
        @(posedge clk);
    end

    // sd_controller sd_controller_inst(
    //     .clk    (clk),
    //     .resetn (resetn),

    //     .cs     (cs),
    //     .mosi   (mosi),
    //     .miso   (miso),
    //     .sclk   (sclk),

    //     .rd     (sdcard_rd),
    //     .wr     (sdcard_wr),
    //     .dm_in  (sdcard_dm_in),
    //     .din    (sdcard_din),
    //     .dout   (sdcard_dout)
    // );

    // sdcard_model_spi_slave sdcard_model_spi_slave_inst(
    //     .clk    (clk),
    //     .resetn (resetn),
    //     .ss     (cs),
    //     .mosi   (mosi),
    //     .miso   (miso),
    //     .sck    (sclk),
    //     .done   (spi_slave_done),
    //     .din    (spi_slave_din),
    //     .dout   (spi_slave_dout)
    // );

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

        @(posedge clk);
        wait (resetn == 1);

        // repeat (10000) @(posedge clk);

        // $display("%t :: All tests completed", $time);

        // @(posedge clk);
        // resetn = 0;
        // for (int i = 0; i < 100; i++) begin
        //     @(posedge clk);
        // end
        // $finish(0);
    end


    task reset_tb;
        @(posedge clk);
        resetn = 0;
        repeat (40) @(posedge clk);
        resetn = 1;
    endtask;

endmodule
