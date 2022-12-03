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


module video_mda_fb_font_rom #(
    parameter integer                           ADDR_WIDTH = 11,
    parameter integer                           DATA_WIDTH = 8
)(
    input  logic                                clk,
    input  logic                                re,
    input  logic [ADDR_WIDTH-1:0]               raddr,
    output logic [DATA_WIDTH-1:0]               q
);
    localparam integer                          WORDS = 1 << ADDR_WIDTH;

    logic [DATA_WIDTH-1:0]                      mem[0:WORDS-1] /* synthesis ramstyle = "no_rw_check" */;

    always_ff @(posedge clk) begin
        if (re == 1'b1) begin
            q <= mem[raddr];
        end
    end

    initial begin
        $readmemh("/home/fila/work/DE2_115/rtl/video/vgafont.vmem", mem, 0, WORDS-1);
    end

endmodule
