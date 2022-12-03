module cpu86_e8086_mem (
    input  logic                clk,
    input  logic                resetn,

    input  logic                s_axis_req_tvalid,
    output logic                s_axis_req_tready,
    input  logic [63:0]         s_axis_req_tdata,

    output logic                m_axis_res_tvalid,
    output logic [31:0]         m_axis_res_tdata
);

    // Local signals
    logic                       q_tvalid;
    logic [31:0]                q_tdata;

    logic                       req_tvalid;
    logic [31:0]                req_tdata;
    logic [24:0]                req_taddr;
    logic                       req_tcmd;
    logic [3:0]                 req_tmask;

    // Assigns
    assign s_axis_req_tready    = 1'b1;

    assign req_tvalid           = s_axis_req_tvalid;
    assign req_tdata            = s_axis_req_tdata[31:0];
    assign req_taddr            = s_axis_req_tdata[56:32];
    assign req_tcmd             = s_axis_req_tdata[57];
    assign req_tmask            = s_axis_req_tdata[61:58];


    // module cpu86_e8086_mem_core instantiation
    cpu86_e8086_mem_core cpu86_e8086_mem_core_inst(
        .clk                    (clk),
        .we                     (req_tvalid & req_tcmd),
        .wmask                  (req_tmask),
        .waddr                  (req_taddr),
        .wdata                  (req_tdata),
        .raddr                  (req_taddr),
        .q                      (q_tdata)
    );

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

endmodule
