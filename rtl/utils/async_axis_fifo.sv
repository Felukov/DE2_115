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

module async_axis_fifo #(
    parameter integer                   FIFO_WIDTH = 64,
    parameter integer                   FIFO_DEPTH = 8
)(
    input  logic                        s_axis_aclk,
    input  logic                        s_axis_aresetn,
    input  logic                        s_axis_tvalid,
    output logic                        s_axis_tready,
    input  logic [FIFO_WIDTH-1:0]       s_axis_tdata,

    input  logic                        m_axis_aclk,
    input  logic                        m_axis_aresetn,
    output logic                        m_axis_tvalid,
    input  logic                        m_axis_tready,
    output logic [FIFO_WIDTH-1:0]       m_axis_tdata
);

    localparam integer                  ADDRESS_WIDTH          = $clog2(FIFO_DEPTH);
    localparam integer                  ALMOST_EMPTY_THRESHOLD = 2;
    localparam integer                  ALMOST_FULL_THRESHOLD  = FIFO_DEPTH - 2;

    logic                               mem_we;
    logic [ADDRESS_WIDTH-1:0]           mem_waddr;

    logic                               buf_tvalid;
    logic                               buf_tready;
    logic [ADDRESS_WIDTH-1:0]           buf_raddr;

    logic                               buf_re;


    // Module async_axis_fifo_addr_gen instantiation
    async_axis_fifo_addr_gen #(
        .ADDRESS_WIDTH          (ADDRESS_WIDTH),
        .ALMOST_EMPTY_THRESHOLD (ALMOST_EMPTY_THRESHOLD),
        .ALMOST_FULL_THRESHOLD  (ALMOST_FULL_THRESHOLD)
    ) async_axis_fifo_addr_gen_inst (
        // sink
        .s_axis_aclk            (s_axis_aclk),
        .s_axis_aresetn         (s_axis_aresetn),
        .s_axis_valid           (s_axis_tvalid),
        .s_axis_ready           (s_axis_tready),
        .s_axis_full            (),
        .s_axis_almost_full     (),
        .s_axis_waddr           (mem_waddr),
        .s_axis_room            (),
        // source
        .m_axis_aclk            (m_axis_aclk),
        .m_axis_aresetn         (m_axis_aresetn),
        .m_axis_valid           (buf_tvalid),
        .m_axis_ready           (buf_tready),
        .m_axis_raddr           (buf_raddr),
        .m_axis_level           (),
        .m_axis_empty           (),
        .m_axis_almost_empty    ()
    );


    // When the clocks are asynchronous instantiate a block RAM
    // regardless of the requested size to make sure we threat the
    // clock crossing correctly
    async_axis_fifo_bram #(
        .DATA_WIDTH             (FIFO_WIDTH),
        .ADDRESS_WIDTH          (ADDRESS_WIDTH))
    async_axis_fifo_bram_inst (
        .clka                   (s_axis_aclk),
        .wea                    (mem_we),
        .addra                  (mem_waddr),
        .dina                   (s_axis_tdata),
        .clkb                   (m_axis_aclk),
        .reb                    (buf_re),
        .addrb                  (buf_raddr),
        .doutb                  (m_axis_tdata)
    );

    // Assigns
    assign buf_tready = ~m_axis_tvalid | m_axis_tready;

    assign mem_we = s_axis_tready & s_axis_tvalid;
    assign buf_re = buf_tvalid & buf_tready;

    // Forming output process
    always_ff @(posedge m_axis_aclk) begin
        if (m_axis_aresetn == 1'b0) begin
            m_axis_tvalid <= 1'b0;
        end else begin
            if (buf_tvalid == 1'b1) begin
                m_axis_tvalid <= 1'b1;
            end else if (m_axis_tready == 1'b1) begin
                m_axis_tvalid <= 1'b0;
            end
        end
    end

endmodule
