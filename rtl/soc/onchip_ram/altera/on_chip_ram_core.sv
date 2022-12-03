module on_chip_ram_core #(
    parameter integer                           ADDR_WIDTH = 6,
    parameter integer                           BYTE_WIDTH = 8,
    parameter integer                           BYTES = 4,
    parameter integer                           WIDTH = BYTES * BYTE_WIDTH
)(
    input  logic                                clk,
    input  logic                                we,
    input  logic [BYTES-1:0]                    be,
    input  logic [ADDR_WIDTH-1:0]               waddr,
    input  logic [BYTES*BYTE_WIDTH-1:0]         wdata,
    input  logic [ADDR_WIDTH-1:0]               raddr,
    output logic [WIDTH - 1:0]                  q
);
    localparam integer                          WORDS = 1 << ADDR_WIDTH ;

    // use a multi-dimensional packed array to model individual bytes within the word
    logic [BYTES-1:0][BYTE_WIDTH-1:0]           ram[0:WORDS-1];
    logic [BYTES-1:0][BYTE_WIDTH-1:0]           wdata_array;

    assign wdata_array = wdata;

    always_ff @(posedge clk) begin
        if (we == 1'b1) begin
            if (~be[0]) ram[waddr][0] <= wdata_array[0];
            if (~be[1]) ram[waddr][1] <= wdata_array[1];
            if (~be[2]) ram[waddr][2] <= wdata_array[2];
            if (~be[3]) ram[waddr][3] <= wdata_array[3];
        end
        q <= ram[raddr];
    end

    initial begin
        $readmemh("/home/fila/work/DE2_115/rtl/soc/onchip_ram/altera/bootstrap.vmem", ram, 0, WORDS-1); 
    end

endmodule
