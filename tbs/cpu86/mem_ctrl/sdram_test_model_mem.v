// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

// turn off superfluous verilog processor warnings
// altera message_level Level1
// altera message_off 10034 10035 10036 10037 10230 10240 10030

module sdram_test_model_mem (
    // inputs:
    data,
    rdaddress,
    rdclken,
    wraddress,
    wrclock,
    wren,

    // outputs:
    q
);

    output  [ 31: 0] q;
    input   [ 31: 0] data;
    input   [ 24: 0] rdaddress;
    input            rdclken;
    input   [ 24: 0] wraddress;
    input            wrclock;
    input            wren;

    reg     [ 31: 0] mem_array [33554431: 0];
    wire    [ 31: 0] q;
    reg     [ 24: 0] read_address;

    always @(rdaddress) begin
        read_address = rdaddress;
    end

    // Data read is asynchronous.
    assign q = mem_array[read_address];

    always @(posedge wrclock) begin
      // Write data
      if (wren)
          mem_array[wraddress] <= data;
    end

endmodule
