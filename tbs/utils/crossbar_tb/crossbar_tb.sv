`timescale 1ns/1ns

module crossbar_tb;

    parameter int                           M_QTY = 4;
    parameter int                           S_QTY = 4;
    parameter int                           TDATA_WIDTH = 32;
    parameter int                           TADDR_WIDTH = 32;
    parameter int                           PKT_QTY = 100;
    parameter int                           S_CH_WIDTH = $clog2(S_QTY);
    parameter int                           M_CH_WIDTH = $clog2(S_QTY);

    typedef struct packed {
        logic [M_CH_WIDTH-1:0]  m_ch;
        logic                   cmd;
        logic [TADDR_WIDTH-1:0] addr;
        logic [TDATA_WIDTH-1:0] data;
    } req_message_t;

    logic [$bits(req_message_t)-1:0]        req_queue[S_QTY][$];
    logic [TDATA_WIDTH-1:0]                 resp_queue[M_QTY][$];

    interface req_ack_m_intf(input logic aclk, input logic aresetn);
        // signals
        logic                       req;
        logic                       ack;
        logic                       cmd;
        logic [TADDR_WIDTH-1:0]     addr;
        logic [TDATA_WIDTH-1:0]     wdata;

        logic                       resp;
        logic [TDATA_WIDTH-1:0]     rdata;

        task send_req(
            input                   p_cmd,
            input [TADDR_WIDTH-1:0] p_addr,
            input [TDATA_WIDTH-1:0] p_wdata
        );
            // local declarations
            int rnd_delay;

            // sending data
            begin
                req = 1;
                cmd = p_cmd;
                addr = p_addr;
                wdata = p_wdata;
                @(posedge aclk);
            end
            // wait handshake
            while (ack == 0) begin
                @(posedge aclk);
            end

            // delay
            rnd_delay = $urandom_range(2, 0);
            begin
                req = 0;
                if (rnd_delay > 0) begin
                    repeat (rnd_delay) @(posedge aclk);
                end
            end
        endtask

        task wait_resp(
            output [TDATA_WIDTH-1:0]    p_rdata
        );
            // wait resp
            while (resp == 0) begin
                @(posedge aclk);
            end
            p_rdata = rdata;
            @(posedge aclk);
        endtask

    endinterface

    interface req_ack_s_intf(input logic aclk, input logic aresetn);
        // signals
        logic                           req;
        logic                           ack;
        logic                           cmd;
        logic [TADDR_WIDTH-1:0]         addr;
        logic [TDATA_WIDTH-1:0]         wdata;

        logic                           resp;
        logic [TDATA_WIDTH-1:0]         rdata;

        task wait_data(
            output                      p_cmd,
            output [TADDR_WIDTH-1:0]    p_addr,
            output [TDATA_WIDTH-1:0]    p_wdata
        );
            // wait req
            while (req == 0) begin
                @(posedge aclk);
            end
            ack = 1;
            @(posedge aclk);
            p_cmd = cmd;
            p_addr = addr;
            p_wdata = wdata;
            ack = 0;
            @(posedge aclk);
        endtask

        task send_resp(
            input [TDATA_WIDTH-1:0]    p_rdata
        );
            resp = 1;
            rdata = p_rdata;
            @(posedge aclk);
            resp = 0;
        endtask

    endinterface

    // Driver
    class data_driver_c;
        virtual req_ack_m_intf  m_intf;
        int                     m_init_delay;
        int                     m_m_ch;

        function new(virtual req_ack_m_intf intf, int ch, int seed);
            int rnd_val;

            m_intf = intf;
            m_m_ch = ch;

            rnd_val = $urandom(seed);
            m_init_delay = $urandom_range(10, 0);

            m_intf.req = 0;
            m_intf.cmd = 0;
        endfunction

        task wait_after_reset();
            wait (m_intf.aresetn == 1);
            repeat(m_init_delay) @(posedge m_intf.aclk);
        endtask

        task send_req();
            send_req_to_ch($urandom_range(S_QTY-1, 0));
        endtask

        task send_req_to_ch(input int s_ch);
            // task variables
            req_message_t msg;

            // task logic
            msg.cmd   = $urandom_range(1, 0);
            msg.addr  = {s_ch[S_CH_WIDTH-1:0], (TADDR_WIDTH-S_CH_WIDTH)'($urandom_range(2**30-1, 0))};
            msg.data  = $urandom_range(2**TDATA_WIDTH-1, 0);

            m_intf.send_req(msg.cmd, msg.addr, msg.data);
            req_queue[s_ch].push_back(msg);

            if (msg.cmd == 1) begin
                resp_queue[m_m_ch].push_back(msg.data);
            end
        endtask

        task wait_resp();
            // task variables
            logic [TDATA_WIDTH-1:0] expected_rdata;
            logic [TDATA_WIDTH-1:0] hw_data;

            // task logic
            m_intf.wait_resp(hw_data);
            expected_rdata = resp_queue[m_m_ch].pop_front();

            if (expected_rdata != hw_data) begin
                $error("Resp data mismatch. Expected: %h, Received: %h", expected_rdata, hw_data);
            end else begin
                $display("%h", hw_data);
            end
        endtask

    endclass

    // Receiver
    class data_recv_c;
        virtual req_ack_s_intf  m_intf;
        int                     m_ch;
        logic                   m_cmd;
        logic [TADDR_WIDTH-1:0] m_addr;
        logic [TDATA_WIDTH-1:0] m_wdata;

        function new(virtual req_ack_s_intf intf, int ch, int seed);
            int rnd_val;
            m_intf = intf;

            rnd_val = $urandom(seed);

            m_intf.ack = 0;
            m_intf.resp = 0;
            m_intf.rdata = 0;
        endfunction

        task wait_after_reset();
            wait (m_intf.aresetn == 1);
        endtask

        task wait_data();
            // task variables
            logic                       hw_cmd;
            logic [TADDR_WIDTH-1:0]     hw_addr;
            logic [TDATA_WIDTH-1:0]     hw_wdata;
            logic [S_CH_WIDTH-1:0]      hw_ch;
            int                         idx;
            req_message_t               expected_req;

            // task logic
            m_intf.wait_data(hw_cmd, hw_addr, hw_wdata);
            hw_ch = hw_addr[TADDR_WIDTH-1:TADDR_WIDTH-S_CH_WIDTH];

            idx = -1;
            for (int i = 0; i < req_queue[hw_ch].size(); i++) begin
                expected_req = req_message_t'(req_queue[hw_ch][i]);
                if (expected_req.data == hw_wdata && expected_req.addr == hw_addr) begin
                    idx = i;
                    break;
                end
            end

            if (idx == -1) begin
                $error("Request data error: cmd = %h, addr = %h, wdata = %h", hw_cmd, hw_addr, hw_wdata);
            end else begin
                req_queue[hw_ch].delete(idx);
            end

            if (hw_cmd == 1'b1) begin
                m_intf.send_resp(hw_wdata);
            end
        endtask

    endclass


    // local signals
    logic                               clk;
    logic                               resetn;

    logic [M_QTY-1:0]                   m_req;
    logic [M_QTY-1:0]                   m_ack;
    logic [M_QTY-1:0]                   m_cmd;
    logic [M_QTY-1:0][TADDR_WIDTH-1:0]  m_addr;
    logic [M_QTY-1:0][TDATA_WIDTH-1:0]  m_wdata;
    logic [M_QTY-1:0]                   m_resp;
    logic [M_QTY-1:0][TDATA_WIDTH-1:0]  m_rdata;

    logic [S_QTY-1:0]                   s_req;
    logic [S_QTY-1:0]                   s_ack;
    logic [S_QTY-1:0]                   s_cmd;
    logic [S_QTY-1:0][TADDR_WIDTH-1:0]  s_addr;
    logic [S_QTY-1:0][TDATA_WIDTH-1:0]  s_wdata;
    logic [S_QTY-1:0]                   s_resp;
    logic [S_QTY-1:0][TDATA_WIDTH-1:0]  s_rdata;

    bit [M_QTY-1:0]                     sync_st_0 = '{default:'0};
    bit [M_QTY-1:0]                     sync_st_1 = '{default:'0};

    // dut
    crossbar crossbar_inst (
        // clock and reset
        .clk                            (clk),
        .resetn                         (resetn),
        // master
        .master_0_req                   (m_req[0]),
        .master_0_addr                  (m_addr[0]),
        .master_0_cmd                   (m_cmd[0]),
        .master_0_wdata                 (m_wdata[0]),
        .master_0_ack                   (m_ack[0]),
        .master_0_resp                  (m_resp[0]),
        .master_0_rdata                 (m_rdata[0]),
        .master_1_req                   (m_req[1]),
        .master_1_addr                  (m_addr[1]),
        .master_1_cmd                   (m_cmd[1]),
        .master_1_wdata                 (m_wdata[1]),
        .master_1_ack                   (m_ack[1]),
        .master_1_resp                  (m_resp[1]),
        .master_1_rdata                 (m_rdata[1]),
        .master_2_req                   (m_req[2]),
        .master_2_addr                  (m_addr[2]),
        .master_2_cmd                   (m_cmd[2]),
        .master_2_wdata                 (m_wdata[2]),
        .master_2_ack                   (m_ack[2]),
        .master_2_resp                  (m_resp[2]),
        .master_2_rdata                 (m_rdata[2]),
        .master_3_req                   (m_req[3]),
        .master_3_addr                  (m_addr[3]),
        .master_3_cmd                   (m_cmd[3]),
        .master_3_wdata                 (m_wdata[3]),
        .master_3_ack                   (m_ack[3]),
        .master_3_resp                  (m_resp[3]),
        .master_3_rdata                 (m_rdata[3]),
        // slave
        .slave_0_req                    (s_req[0]),
        .slave_0_addr                   (s_addr[0]),
        .slave_0_cmd                    (s_cmd[0]),
        .slave_0_wdata                  (s_wdata[0]),
        .slave_0_ack                    (s_ack[0]),
        .slave_0_resp                   (s_resp[0]),
        .slave_0_rdata                  (s_rdata[0]),
        .slave_1_req                    (s_req[1]),
        .slave_1_addr                   (s_addr[1]),
        .slave_1_cmd                    (s_cmd[1]),
        .slave_1_wdata                  (s_wdata[1]),
        .slave_1_ack                    (s_ack[1]),
        .slave_1_resp                   (s_resp[1]),
        .slave_1_rdata                  (s_rdata[1]),
        .slave_2_req                    (s_req[2]),
        .slave_2_addr                   (s_addr[2]),
        .slave_2_cmd                    (s_cmd[2]),
        .slave_2_wdata                  (s_wdata[2]),
        .slave_2_ack                    (s_ack[2]),
        .slave_2_resp                   (s_resp[2]),
        .slave_2_rdata                  (s_rdata[2]),
        .slave_3_req                    (s_req[3]),
        .slave_3_addr                   (s_addr[3]),
        .slave_3_cmd                    (s_cmd[3]),
        .slave_3_wdata                  (s_wdata[3]),
        .slave_3_ack                    (s_ack[3]),
        .slave_3_resp                   (s_resp[3]),
        .slave_3_rdata                  (s_rdata[3])
    );


    initial begin
        clk = 0;
        forever #5 clk = !clk;
    end

    initial begin
        resetn = 0;
        repeat (40) @(posedge clk);
        resetn = 1;
    end

    // Master processes
    generate
        for (genvar i = 0; i < M_QTY; i++) begin: data_gen
            req_ack_m_intf  m_intf(clk, resetn);
            data_driver_c   data_driver = new(m_intf, i, 100 + i);

            assign m_req[i] = m_intf.req;
            assign m_intf.ack = m_ack[i];
            assign m_cmd[i] = m_intf.cmd;
            assign m_addr[i] = m_intf.addr;
            assign m_wdata[i] = m_intf.wdata;

            assign m_intf.resp = m_resp[i];
            assign m_intf.rdata = m_rdata[i];

            // master request process
            initial begin
                data_driver.wait_after_reset();

                for (int p = 0; p < PKT_QTY; p++) begin
                    data_driver.send_req();
                end
                repeat(100) @(posedge clk);

                sync_st_0[i] = 1;
                @(posedge clk);
                while (sync_st_0 != {M_QTY{1'b1}}) @(posedge clk);

                for (int ch = 0; ch < S_QTY; ch++) begin
                    for (int p = 0; p < PKT_QTY; p++) begin
                        data_driver.send_req_to_ch(ch);
                    end
                    repeat(100) @(posedge clk);
                end

                sync_st_1[i] = 1;
                @(posedge clk);
                while (sync_st_1 != {M_QTY{1'b1}}) @(posedge clk);

                repeat(100 * i + 100) @(posedge clk);
                for (int p = 0; p < PKT_QTY; p++) begin
                    data_driver.send_req();
                end

            end

            // master resp handler
            initial begin
                data_driver.wait_after_reset();

                forever begin
                    data_driver.wait_resp();
                end
            end

        end

    endgenerate

    // Receiving processes
    generate
        for (genvar i = 0; i < M_QTY; i++) begin: data_recv
            req_ack_s_intf s_intf(clk, resetn);

            assign s_intf.req = s_req[i];
            assign s_ack[i] = s_intf.ack;
            assign s_intf.cmd = s_cmd[i];
            assign s_intf.addr = s_addr[i];
            assign s_intf.wdata = s_wdata[i];

            assign s_resp[i] = s_intf.resp;
            assign s_rdata[i] = s_intf.rdata;

            initial begin
                // local variables
                automatic data_recv_c   data_recv = null;

                // behaviour
                data_recv = new(s_intf, i, 1000 + i);

                data_recv.wait_after_reset();

                forever begin
                    data_recv.wait_data();
                end
            end

        end
    endgenerate

endmodule
