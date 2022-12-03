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


module cpu86_exec_dcache_ram_core #(
    parameter integer                           ADDR_WIDTH = 6,
    parameter integer                           DATA_WIDTH = 16
)(
    input  logic                                clk,
    input  logic [ADDR_WIDTH-1:0]               addr,
    input  logic                                we,
    input  logic [DATA_WIDTH-1:0]               wdata,
    input  logic                                re,
    output logic [DATA_WIDTH-1:0]               q
);
    localparam integer                          WORDS = 1 << ADDR_WIDTH;

    logic [DATA_WIDTH-1:0]                      ram[0:WORDS-1] /* synthesis ramstyle = "no_rw_check" */;

    always_ff @(posedge clk) begin
        if (we == 1'b1) begin
            ram[addr] <= wdata;
        end

        if (re == 1'b1) begin
            q <= ram[addr];
        end
    end

endmodule
