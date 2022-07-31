`timescale 1ns/1ns

module axis_interconnect_tb;
    // parameters
    parameter int                           PORTS_QTY = 4;
    parameter int                           TDATA_WIDTH = 32;
    parameter int                           TUSER_WIDTH = 16;
    parameter int                           PKT_QTY = 100;

    // local signals
    logic                                   clk;
    logic                                   resetn;

    logic [PORTS_QTY-1:0]                   s_axis_tvalid;
    logic [PORTS_QTY-1:0]                   s_axis_tready;
    logic [PORTS_QTY-1:0]                   s_axis_tlast;
    logic [PORTS_QTY-1:0][TDATA_WIDTH-1:0]  s_axis_tdata;
    logic [PORTS_QTY-1:0][TUSER_WIDTH-1:0]  s_axis_tuser;
    logic                                   m_axis_tvalid;
    logic                                   m_axis_tready;
    logic                                   m_axis_tlast;
    logic [TDATA_WIDTH-1:0]                 m_axis_tdata;
    logic [TUSER_WIDTH-1:0]                 m_axis_tuser;


    interface axis_intf;
        // signals
        logic                   tvalid;
        logic                   tready;
        logic                   tlast;
        logic [TDATA_WIDTH-1:0] tdata;
        logic [TUSER_WIDTH-1:0] tuser;

        //modport delcaration
        modport driver   (input tready, output tvalid, tlast, tdata, tuser);
        modport receiver (input tvalid, tlast, tdata, tuser, output tready);

        task send_data(
            input [TDATA_WIDTH-1:0] data_tdata,
            input [TUSER_WIDTH-1:0] data_tuser
        );
            // local delcarations
            int rnd_delay;

            // sending data
            begin
                tvalid = 1;
                tdata = data_tdata;
                tuser = data_tuser;
                tlast = (d == pkt_len - 1) ? 1 : 0;
                @(posedge clk);
            end

            // wait handshake
            while (tready == 0) begin
                @(posedge clk);
            end

            // delay
            rnd_delay = $urandom_range(2, 0);
            begin
                tvalid = 0;
                if (rnd_delay > 0) begin
                    repeat (rnd_delay) @(posedge clk);
                end
            end
        endtask

    endinterface

    // dut
    axis_round_robin_interconnect #(
        .PORTS_QTY                          (PORTS_QTY),
        .TDATA_WIDTH                        (TDATA_WIDTH),
        .TUSER_WIDTH                        (TUSER_WIDTH)
    ) axis_round_robin_interconnect_inst (
        .clk                                (clk),
        .resetn                             (resetn),
        .s_axis_data_tvalid                 (s_axis_tvalid),
        .s_axis_data_tready                 (s_axis_tready),
        .s_axis_data_tlast                  (s_axis_tlast),
        .s_axis_data_tdata                  (s_axis_tdata),
        .s_axis_data_tuser                  (s_axis_tuser),
        .m_axis_data_tvalid                 (m_axis_tvalid),
        .m_axis_data_tready                 (m_axis_tready),
        .m_axis_data_tlast                  (m_axis_tlast),
        .m_axis_data_tdata                  (m_axis_tdata),
        .m_axis_data_tuser                  (m_axis_tuser)
    );

    assign m_axis_tready = 1;

    initial begin
        clk = 0;
        forever #5 clk = !clk;
    end

    initial begin
        resetn = 0;
        repeat (40) @(posedge clk);
        resetn = 1;
    end

    // s_axis_data interface
    generate
        for (genvar i = 0; i < PORTS_QTY; i++) begin: data_gen

            initial begin
                int init_delay;
                int pkt_len;
                int pkt_data;
                int rnd_delay;

                $urandom(100 + i);
                init_delay = $urandom_range(10, 0);

                s_axis_tvalid[i] = 0;
                s_axis_tlast[i] = 0;

                wait (resetn == 1);
                repeat(init_delay) @(posedge clk);

                for (int p = 0; p < PKT_QTY; p++) begin
                    pkt_len = $urandom_range(1000, 1);

                    for (int d = 0; d < pkt_len; d++) begin
                        rnd_delay = $urandom_range(2, 0);
                        // sending data
                        begin
                            s_axis_tvalid[i] = 1;
                            s_axis_tdata[i] = d;
                            s_axis_tuser[i] = p;
                            s_axis_tlast[i] = (d == pkt_len - 1) ? 1 : 0;
                            @(posedge clk);
                        end

                        // wait handshake
                        while (s_axis_tready[i] == 0) begin
                            @(posedge clk);
                        end

                        // delay
                        begin
                            s_axis_tvalid[i] = 0;
                            if (rnd_delay > 0) begin
                                repeat (rnd_delay) @(posedge clk);
                            end
                        end
                    end

                    if (p == 10 && i == 1) begin
                        repeat (50000) @(posedge clk);
                    end

                end

            end

        end
    endgenerate

endmodule
