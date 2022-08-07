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


module async_axis_fifo_bram #(
    parameter integer                     DATA_WIDTH = 16,
    parameter integer                     ADDRESS_WIDTH = 5
)(
    input  logic                          clka,
    input  logic                          wea,
    input  logic [(ADDRESS_WIDTH-1):0]    addra,
    input  logic [(DATA_WIDTH-1):0]       dina,

    input  logic                          clkb,
    input  logic                          reb,
    input  logic [(ADDRESS_WIDTH-1):0]    addrb,
    output logic [(DATA_WIDTH-1):0]       doutb
);

    logic [DATA_WIDTH-1:0]                m_ram[0:((2**ADDRESS_WIDTH)-1)] /* synthesis ramstyle = "no_rw_check, M9K" */;

    always_ff @(posedge clka) begin
        if (wea == 1'b1) begin
            m_ram[addra] <= dina;
        end
    end

    always_ff @(posedge clkb) begin
        if (reb == 1'b1) begin
            doutb <= m_ram[addrb];
        end
    end

endmodule

