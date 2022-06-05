/*
 * Copyright (C) 2022, Konstantin Felukov
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * * Redistributions of source code must retain the above copyright notice, this
 *   list of conditions and the following disclaimer.
 *
 * * Redistributions in binary form must reproduce the above copyright notice,
 *   this list of conditions and the following disclaimer in the documentation
 *   and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * Helper module for synchronizing a counter from one clock domain to another
 * using gray code. To work correctly the counter must not change its value by
 * more than one in one clock cycle in the source domain. I.e. the value may
 * change by either -1, 0 or +1.
 */

module async_axis_fifo_addr_gen_sync_gray #(
    // Bit-width of the counter
    parameter integer               DATA_WIDTH = 1
)(
    input  logic                    in_clk,
    input  logic                    in_resetn,
    input  logic [DATA_WIDTH-1:0]   in_count,
    input  logic                    out_clk,
    input  logic                    out_resetn,
    output logic [DATA_WIDTH-1:0]   out_count
);

    // Local signals
    (* useioff = 0 *)
    (* preserve *)
    logic [DATA_WIDTH-1:0] cdc_sync_stage0 = 'h0;

    (* useioff = 0 *)
    (* preserve *)
    logic [DATA_WIDTH-1:0] cdc_sync_stage1 = 'h0;

    (* useioff = 0 *)
    (* preserve *)
    logic [DATA_WIDTH-1:0] cdc_sync_stage2 = 'h0;

    logic [DATA_WIDTH-1:0] out_count_m = 'h0;


    // Assigns
    assign out_count = out_count_m;

    // Converting binary counter to gray
    always_ff @(posedge in_clk) begin
        if (in_resetn == 1'b0) begin
            cdc_sync_stage0 <= 'h00;
        end else begin
            cdc_sync_stage0 <= b2g(in_count);
        end
    end

    // Latching counter in destination domain
    always_ff @(posedge out_clk) begin
        if (out_resetn == 1'b0) begin
            cdc_sync_stage1 <= 'h00;
            cdc_sync_stage2 <= 'h00;
            out_count_m <= 'h00;
        end else begin
            cdc_sync_stage1 <= cdc_sync_stage0;
            cdc_sync_stage2 <= cdc_sync_stage1;
            out_count_m <= g2b(cdc_sync_stage2);
        end
    end

    // gray 2 binary
    function [DATA_WIDTH-1:0] g2b;
        input [DATA_WIDTH-1:0] g;
        logic   [DATA_WIDTH-1:0] b;
        integer i;
        begin
            b[DATA_WIDTH-1] = g[DATA_WIDTH-1];
            for (i = DATA_WIDTH - 2; i >= 0; i =  i - 1) begin
                b[i] = b[i + 1] ^ g[i];
            end
            g2b = b;
        end
    endfunction

    // binary 2 gray
    function [DATA_WIDTH-1:0] b2g;
        input [DATA_WIDTH-1:0] b;
        logic [DATA_WIDTH-1:0] g;
        integer i;
        begin
            g[DATA_WIDTH-1] = b[DATA_WIDTH-1];
            for (i = DATA_WIDTH - 2; i >= 0; i = i -1) begin
                g[i] = b[i + 1] ^ b[i];
            end
            b2g = g;
        end
    endfunction

endmodule
