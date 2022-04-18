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

module soc_io_seg_7_ff (
    input               clk,
    input      [3:0]    digit,
    output reg [6:0]    segment
);

    always @(posedge clk) begin
        case (digit)
            4'h1: segment <= 7'b1111001;    // ---t----
            4'h2: segment <= 7'b0100100;    // |      |
            4'h3: segment <= 7'b0110000;    // lt     rt
            4'h4: segment <= 7'b0011001;    // |      |
            4'h5: segment <= 7'b0010010;    // ---m----
            4'h6: segment <= 7'b0000010;    // |      |
            4'h7: segment <= 7'b1111000;    // lb     rb
            4'h8: segment <= 7'b0000000;    // |      |
            4'h9: segment <= 7'b0011000;    // ---b----
            4'ha: segment <= 7'b0001000;
            4'hb: segment <= 7'b0000011;
            4'hc: segment <= 7'b1000110;
            4'hd: segment <= 7'b0100001;
            4'he: segment <= 7'b0000110;
            4'hf: segment <= 7'b0001110;
            4'h0: segment <= 7'b1000000;
        endcase
    end

endmodule
