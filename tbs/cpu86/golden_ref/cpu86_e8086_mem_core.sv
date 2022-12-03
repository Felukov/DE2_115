module cpu86_e8086_mem_core (
    input  logic            clk,
    input  logic            we,
    input  logic [3:0]      wmask,
    input  logic [24:0]     waddr,
    input  logic [31:0]     wdata,
    input  logic [24:0]     raddr,
    output logic [31:0]     q
);

    // Signals
    int                     c_rd_addr;
    int                     c_wr_addr;
    int                     c_q_3;
    int                     c_q_2;
    int                     c_q_1;
    int                     c_q_0;

    logic [0:3][7:0]        wdata_array;
    logic [0:3][7:0]        rdata_array;
    logic [0:3]             wmask_array;

    // Assigns
    assign wdata_array      = wdata;
    assign wmask_array      = wmask;
    assign c_rd_addr        = 32'($unsigned({raddr, 2'b00}));
    assign c_wr_addr        = 32'($unsigned({waddr, 2'b00}));


    // Write process
    always_ff @(posedge clk) begin
        if (we == 1'b1) begin
            if (~wmask_array[0]) c_mem_write_b(c_wr_addr+0, wdata_array[0]);
            if (~wmask_array[1]) c_mem_write_b(c_wr_addr+1, wdata_array[1]);
            if (~wmask_array[2]) c_mem_write_b(c_wr_addr+2, wdata_array[2]);
            if (~wmask_array[3]) c_mem_write_b(c_wr_addr+3, wdata_array[3]);
        end
    end

    // Read process
    always_ff @(posedge clk) begin
        c_mem_read_b(c_rd_addr,   rdata_array[0]);
        c_mem_read_b(c_rd_addr+1, rdata_array[1]);
        c_mem_read_b(c_rd_addr+2, rdata_array[2]);
        c_mem_read_b(c_rd_addr+3, rdata_array[3]);
        q <= rdata_array;
    end

    import "DPI-C" function void c_mem_write_b(input int addr, input int val);
    import "DPI-C" function void c_mem_read_b(input int addr, output int val);

endmodule
