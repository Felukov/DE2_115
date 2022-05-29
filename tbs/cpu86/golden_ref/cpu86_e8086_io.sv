module cpu86_e8086_io (
    input  logic                clk,
    input  logic                resetn,

    input  logic                s_axis_req_tvalid,
    output logic                s_axis_req_tready,
    input  logic [39:0]         s_axis_req_tdata,

    output logic                m_axis_res_tvalid,
    output logic [15:0]         m_axis_res_tdata
);

    // Local signals
    logic [15:0]                wdata;
    logic [15:0]                rdata;

    logic                       q_tvalid;
    logic [15:0]                q_tdata;

    logic                       req_tvalid;
    logic [15:0]                req_tdata;
    logic [15:0]                req_taddr;
    logic                       req_tcmd;

    // Assigns
    assign s_axis_req_tready    = 1'b1;

    assign req_tvalid           = s_axis_req_tvalid;
    assign req_tdata            = s_axis_req_tdata[15:0];
    assign req_taddr            = s_axis_req_tdata[31:16];
    assign req_tcmd             = s_axis_req_tdata[32];
    assign wdata                = req_tdata;

    // Write process
    always_ff @(posedge clk) begin
        if (req_tvalid == 1'b1 && req_tcmd == 1'b1) begin
            c_io_write(req_taddr, wdata);
        end
    end

    // Read process
    always_ff @(posedge clk) begin
        if (req_tvalid == 1'b1 && req_tcmd == 1'b0) begin
            c_io_read(req_taddr, rdata);
            q_tdata <= rdata;
        end
    end

    // Latching output
    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            q_tvalid          <= 1'b0;
            m_axis_res_tvalid <= 1'b0;
        end else begin
            q_tvalid          <= req_tvalid & ~req_tcmd; // only read requests
            m_axis_res_tvalid <= q_tvalid;
            m_axis_res_tdata  <= q_tdata;
        end
    end

    import "DPI-C" function void c_io_write(input int addr, input int val);
    import "DPI-C" function void c_io_read(input int addr, output int val);


endmodule
