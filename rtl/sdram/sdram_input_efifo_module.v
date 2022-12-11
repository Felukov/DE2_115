// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

// turn off superfluous verilog processor warnings
// altera message_level Level1
// altera message_off 10034 10035 10036 10037 10230 10240 10030

module sdram_input_efifo_module (
    // inputs:
    clk,
    rd,
    reset_n,
    wr,
    wr_data,

    // outputs:
    almost_empty,
    almost_full,
    empty,
    full,
    rd_data
);

    output           almost_empty;
    output           almost_full;
    output           empty;
    output           full;
    output  [ 61: 0] rd_data;
    input            clk;
    input            rd;
    input            reset_n;
    input            wr;
    input   [ 61: 0] wr_data;

    wire             almost_empty;
    wire             almost_full;
    wire             empty;
    reg     [  1: 0] entries;
    reg     [ 61: 0] entry_0;
    reg     [ 61: 0] entry_1;
    wire             full;
    reg              rd_address;
    reg     [ 61: 0] rd_data;
    wire    [  1: 0] rdwr;
    reg              wr_address;

    assign rdwr = {rd, wr};
    assign full = entries == 2;
    assign almost_full = entries >= 1;
    assign empty = entries == 0;
    assign almost_empty = entries <= 1;

    always @(entry_0 or entry_1 or rd_address) begin
        case (rd_address) // synthesis parallel_case full_case

            1'd0: begin
                rd_data = entry_0;
            end // 1'd0

            1'd1: begin
                rd_data = entry_1;
            end // 1'd1

            default: begin
            end // default

        endcase // rd_address
    end


    always @(posedge clk) begin
        if (reset_n == 0) begin
            wr_address <= 0;
            rd_address <= 0;
            entries <= 0;
        end else begin

            case (rdwr) // synthesis parallel_case full_case

                2'd1: begin
                    // Write data
                    if (!full) begin
                        entries <= entries + 1;
                        wr_address <= (wr_address == 1) ? 0 : (wr_address + 1);
                    end
                end // 2'd1

                2'd2: begin
                    // Read data
                    if (!empty) begin
                        entries <= entries - 1;
                        rd_address <= (rd_address == 1) ? 0 : (rd_address + 1);
                    end
                end // 2'd2

                2'd3: begin
                    wr_address <= (wr_address == 1) ? 0 : (wr_address + 1);
                    rd_address <= (rd_address == 1) ? 0 : (rd_address + 1);
                end // 2'd3

                default: begin
                end // default

            endcase // rdwr

        end
    end


    always @(posedge clk) begin
        //Write data
        if (wr & !full) begin
            case (wr_address) // synthesis parallel_case full_case

                1'd0: begin
                    entry_0 <= wr_data;
                end // 1'd0

                1'd1: begin
                    entry_1 <= wr_data;
                end // 1'd1

                default: begin
                end // default

            endcase // wr_address
        end
    end

endmodule