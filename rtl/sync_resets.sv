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

module sync_resets (
    input logic     clk_a,
    input logic     clk_b,
    input logic     resetn_a,
    input logic     resetn_b,
    output logic    sync_resetn_a,
    output logic    sync_resetn_b
);

    (* keep = "true" *) logic [2:0]     cdc_resetn_b = '{default:'0};
    (* keep = "true" *) logic [2:0]     cdc_resetn_a = '{default:'0};

    (* keep = "true" *) logic           sync_resetn_a_ff = 1'b0;
    (* keep = "true" *) logic           sync_resetn_b_ff = 1'b0;

    assign sync_resetn_a = sync_resetn_a_ff;
    assign sync_resetn_b = sync_resetn_b_ff;

    always_ff @(posedge clk_a) begin
        // resettable
        if (resetn_a == 1'b0) begin
            sync_resetn_a_ff  <= 1'b0;
        end else begin
            sync_resetn_a_ff  <= cdc_resetn_b[2];
        end
        // without reset
        begin
            cdc_resetn_b[0]   <= resetn_b;
            cdc_resetn_b[2:1] <= cdc_resetn_b[1:0];
        end
    end

    always_ff @(posedge clk_b) begin
        // resettable
        if (resetn_b == 1'b0) begin
            cdc_resetn_a      <= '{default:'0};
            sync_resetn_b_ff  <= 1'b0;
        end else begin
            sync_resetn_b_ff  <= cdc_resetn_a[2];
        end
        // without reset
        begin
            cdc_resetn_a[0]   <= resetn_a;
            cdc_resetn_a[2:1] <= cdc_resetn_a[1:0];
        end
    end

endmodule
