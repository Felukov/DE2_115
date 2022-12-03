module pit_lite #(
    parameter integer               TIMER_CNT = 3
) (
    input  logic  clk,
    input  logic  resetn,

    input  logic                    io_req_s_tvalid,
    output logic                    io_req_s_tready,
    input  logic [39:0]             io_req_s_tdata,

    output logic                    io_rd_m_tvalid,
    input  logic                    io_rd_m_tready,
    output logic [15:0]             io_rd_m_tdata,

    output logic [TIMER_CNT-1:0]    timer_out
);


    // Constants
    localparam integer          TIMER_CNT_DW = $clog2(TIMER_CNT);

    // 2^32-1 / 100 MHz * 1193181,8181 Hz
    localparam integer          FREQ_OFFSET = 51246769;

    // Addresses
    localparam logic [1:0]      SELECT_REG = 2'h0;
    localparam logic [1:0]      ENABLE_REG = 2'h1;
    localparam logic [1:0]      MAXVAL_REG = 2'h2;
    localparam logic [1:0]      CURVAL_REG = 2'h3;

    // Local signals
    logic                       io_write;
    logic                       io_read;
    logic [1:0]                 io_address;
    logic [15:0]                io_data;

    logic [31:0]                freq_counter;
    logic                       timer_clk;
    logic                       d_timer_clk;
    logic                       timer_en;

    logic [TIMER_CNT_DW-1:0]    sel_r;
    logic [TIMER_CNT-1:0]       en_r;
    logic [TIMER_CNT-1:0][15:0] maxval_r;
    logic [TIMER_CNT-1:0][15:0] curval_r;

    // Assigns

    assign io_read              = (io_req_s_tvalid == 1'b1 && io_req_s_tready == 1'b1 && io_req_s_tdata[32] == 1'b0) ? 1'b1 : 1'b0;
    assign io_write             = (io_req_s_tvalid == 1'b1 && io_req_s_tready == 1'b1 && io_req_s_tdata[32] == 1'b1) ? 1'b1 : 1'b0;
    assign io_address           = io_req_s_tdata[17:16];
    assign io_data              = io_req_s_tdata[15:0];

    assign io_req_s_tready      = (io_rd_m_tvalid == 1'b0 || (io_rd_m_tvalid == 1'b1 && io_rd_m_tready == 1'b1)) ? 1'b1 : 1'b0;

    assign timer_clk            = freq_counter[31];
    assign timer_en             = (timer_clk == 1'b1 && d_timer_clk == 1'b0) ? 1'b1 : 1'b0;

    always_ff @(posedge clk) begin : proc_d_timer_clk
        if(~resetn) begin
            d_timer_clk <= 1'b0;
        end else begin
            d_timer_clk <= timer_clk;
        end
    end

    // writing ser_r
    always_ff @(posedge clk) begin : proc_sel_r
        if (resetn == 1'b0) begin
            sel_r <= '{default:'0};
        end else begin
            if (io_write == 1'b1 && io_address == SELECT_REG) begin
                sel_r <= io_data[TIMER_CNT_DW-1:0];
            end
        end
    end

    always_ff @(posedge clk) begin : proc_en_r
        if (resetn == 1'b0) begin
            en_r <= '{default:'0};
        end else begin
            if (io_write == 1'b1 && io_address == ENABLE_REG) begin
                en_r[sel_r] <= io_data[0];
            end
        end
    end

    always_ff @(posedge clk) begin : proc_maxval_r
        if (resetn == 1'b0) begin
            maxval_r <= '{default:'0};
        end else begin
            for (int i = 0; i < TIMER_CNT; i++) begin
                if (io_write == 1'b1 && io_address == MAXVAL_REG && i[TIMER_CNT_DW-1:0] == sel_r) begin
                    maxval_r[i] <= io_data;
                end
            end
        end
    end

    always_ff @(posedge clk) begin : proc_curval_r
        if (resetn == 1'b0) begin
            curval_r <= '{default:'0};
        end else begin
            for (int i = 0; i < TIMER_CNT; i++) begin
                if (io_write == 1'b1 && io_address == MAXVAL_REG && i[TIMER_CNT_DW-1:0] == sel_r) begin
                    curval_r[i] <= io_data;
                end else if (en_r[i] == 1'b1 && timer_en == 1'b1) begin
                    if (curval_r[i] == 16'd0) begin
                        curval_r[i] <= maxval_r[i] - 16'd1;
                    end else begin
                        curval_r[i] <= curval_r[i] - 16'd1;
                    end
                end
            end
        end
    end

    always_ff @(posedge clk) begin : proc_out
        if (resetn == 1'b0) begin
            timer_out <= '{default:'1};
        end else begin
            for (int i = 0; i < TIMER_CNT; i++) begin
                if (timer_en == 1'b1) begin
                    if (curval_r[i] == 1'b1) begin
                        timer_out[i] <= 1'b0;
                    end else begin
                        timer_out[i] <= 1'b1;
                    end
                end
            end
        end
    end

    always_ff @(posedge clk) begin : proc_read
        // control path
        if (resetn == 1'b0) begin
            io_rd_m_tvalid <= 1'b0;
        end else begin
            if (io_read == 1'b1) begin
                io_rd_m_tvalid <= 1'b1;
            end else if (io_rd_m_tready == 1'b1) begin
                io_rd_m_tvalid <= 1'b0;
            end
        end
        // data path
        begin
            if (io_read == 1'b1) begin
                case (io_address)
                    SELECT_REG : io_rd_m_tdata <= sel_r;
                    ENABLE_REG : io_rd_m_tdata <= en_r[sel_r];
                    MAXVAL_REG : io_rd_m_tdata <= maxval_r[sel_r];
                    CURVAL_REG : io_rd_m_tdata <= curval_r[sel_r];
                    default : /* default */;
                endcase
            end
        end
    end

    // Timer clock generator process
    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            freq_counter <= '{default:'0};
        end else begin
            freq_counter <= freq_counter + FREQ_OFFSET;
        end
    end

endmodule : pit_lite
