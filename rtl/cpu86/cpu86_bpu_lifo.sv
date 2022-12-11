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

module cpu86_bpu_lifo #(
    parameter integer DEPTH = 16,
    parameter integer DW = 16
) (
    input  logic            clk,
    input  logic            resetn,

    input  logic            push_vld,
    input  logic  [DW-1:0]  push_data,

    output logic            pop_vld,
    input  logic            pop_ack,
    output logic [DW-1:0]   pop_data
);

    logic [DEPTH-1:0]         vec_vld;
    logic [DEPTH-1:0][DW-1:0] vec_data;

    assign pop_vld  = vec_vld[0];
    assign pop_data = vec_data[0];

    always_ff @(posedge clk) begin
        // Control path
        if (resetn == 1'b0) begin
            vec_vld <= '0;
        end else begin
            if (push_vld == 1'b1) begin
                vec_vld <= {vec_vld[DEPTH-2:0], 1'b1};
            end else if (pop_vld == 1'b1 && pop_ack == 1'b1) begin
                vec_vld <= {1'b0, vec_vld[DEPTH-1:1]};
            end
        end
        // Data path
        begin
            if (push_vld == 1'b1) begin
                vec_data <= {vec_data[DEPTH-2:0], push_data};
            end else if (pop_vld == 1'b1 && pop_ack == 1'b1) begin
                vec_data <= {{DW{1'b0}}, vec_data[DEPTH-1:1]};
            end
        end
    end

endmodule
