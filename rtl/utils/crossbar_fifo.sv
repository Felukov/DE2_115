module crossbar_fifo #(
    parameter integer                           FIFO_DEPTH = 4,
    parameter integer                           FIFO_WIDTH = 32
)(
    input  logic                                clk,
    input  logic                                resetn,

    input  logic                                s_axis_data_tvalid,
    input  logic                                s_axis_data_tready,
    input  logic [TDATA_WIDTH-1:0]              s_axis_data_tdata,

    output logic                                m_axis_data_tvalid,
    input  logic                                m_axis_data_tready,
    output logic [TDATA_WIDTH-1:0]              m_axis_data_tdata
);

    // Local signals
    logic                                       wr_data_tvalid;
    logic                                       wr_data_tready;
    logic [FIFO_DEPTH-1:0]                      wr_addr;
    logic [FIFO_DEPTH-1:0]                      wr_addr_next;

    logic                                       rd_data_tvalid;
    logic                                       rd_data_tready;
    logic [TUSER_WIDTH-1:0]                     rd_addr;
    logic [TUSER_WIDTH-1:0]                     rd_addr_next;

    logic [FIFO_WIDTH-1:0]                      fifo_data[FIFO_DEPTH];


    // Assigns
    assign rd_data_tready = ~m_axis_data_tvalid | m_axis_data_tready;

    // Controlling ready
    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            wr_data_tready <= 1'b1;
        end else begin
            if ((wr_addr_next + 'd1) != rd_addr_next) begin
                wr_data_tready <= 1'b1;
            end else begin
                wr_data_tready <= 1'b0;
            end
        end
    end

    // Next write address logic
    always_comb begin
        if (wr_data_tvalid == 1'b1 && wr_data_tready == 1'b1) begin
            wr_addr_next = wr_addr + 'd1;
        end else begin
            wr_addr_next = wr_addr;
        end
    end

    // Reading
    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            rd_data_tvalid <= 1'b0;
        end else begin
            if (wr_addr_next != rd_addr_next) begin
                rd_data_tvalid <= 1'b1;
            end else begin
                rd_data_tvalid <= 1'b0;
            end
        end
    end

    // Next read address
    always_comb begin
        if (rd_data_tvalid == 1'b1 && rd_data_tready == 1'b1 && fifo_valid[rd_addr] == 1'b1) begin
            rd_addr_next = rd_addr + 'd1;
        end else begin
            rd_addr_next = rd_addr;
        end
    end

    // Latching read address
    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            rd_addr <= '{default:'0};
        end else begin
            rd_addr <= rd_addr_next;
        end
    end

    // Forming output
    always_ff @(posedge clk) begin
        // Control
        if (resetn == 1'b0) begin
            m_axis_data_tvalid <= 1'b0;
        end else begin
            if (rd_data_tvalid == 1'b1 && rd_data_tready == 1'b1) begin
                m_axis_data_tvalid <= 1'b1;
            end else if (m_axis_data_tready == 1'b1) begin
                m_axis_data_tvalid <= 1'b0;
            end
        end
        // Data
        begin
            if (rd_data_tready == 1'b1) begin
                m_axis_data_tdata <= fifo_data[rd_addr];
            end
        end
    end

endmodule