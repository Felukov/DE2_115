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

module async_axis_fifo_addr_gen #(
    parameter integer                   ADDRESS_WIDTH = 4,            // address width, effective FIFO depth
    parameter integer                   ALMOST_EMPTY_THRESHOLD = 16,
    parameter integer                   ALMOST_FULL_THRESHOLD = 16
) (
    // Read interface - Sink side
    input  logic                        m_axis_aclk,
    input  logic                        m_axis_aresetn,
    input  logic                        m_axis_ready,
    output logic                        m_axis_valid,
    output logic                        m_axis_empty,
    output logic                        m_axis_almost_empty,
    output logic [ADDRESS_WIDTH-1:0]    m_axis_raddr,
    output logic [ADDRESS_WIDTH-1:0]    m_axis_level,

    // Write interface - Source side
    input  logic                        s_axis_aclk,
    input  logic                        s_axis_aresetn,
    output logic                        s_axis_ready,
    input  logic                        s_axis_valid,
    output logic                        s_axis_full,
    output logic                        s_axis_almost_full,
    output logic [ADDRESS_WIDTH-1:0]    s_axis_waddr,
    output logic [ADDRESS_WIDTH-1:0]    s_axis_room
);


    // Definition of address counters
    // All the counters are wider with one bit to indicate wraparounds
    logic [ADDRESS_WIDTH:0]     s_axis_waddr_reg = 'h0;
    logic [ADDRESS_WIDTH:0]     m_axis_raddr_reg = 'h0;

    logic [ADDRESS_WIDTH:0]     s_axis_raddr_reg;
    logic [ADDRESS_WIDTH:0]     m_axis_waddr_reg;

    logic [ADDRESS_WIDTH:0]     s_axis_fifo_fill;
    logic [ADDRESS_WIDTH:0]     m_axis_fifo_fill;


    // CDC transfer of the write pointer to the read clock domain
    async_axis_fifo_addr_gen_sync_gray #(
        .DATA_WIDTH             (ADDRESS_WIDTH + 1)
    ) async_axis_fifo_addr_gen_sync_gray_waddr_inst (
        .in_clk                 (s_axis_aclk),
        .in_resetn              (s_axis_aresetn),
        .out_clk                (m_axis_aclk),
        .out_resetn             (m_axis_aresetn),
        .in_count               (s_axis_waddr_reg),
        .out_count              (m_axis_waddr_reg)
    );


    // CDC transfer of the read pointer to the write clock domain
    async_axis_fifo_addr_gen_sync_gray #(
        .DATA_WIDTH             (ADDRESS_WIDTH + 1)
    ) async_axis_fifo_addr_gen_sync_gray_raddr_inst (
        .in_clk                 (m_axis_aclk),
        .in_resetn              (m_axis_aresetn),
        .out_clk                (s_axis_aclk),
        .out_resetn             (s_axis_aresetn),
        .in_count               (m_axis_raddr_reg),
        .out_count              (s_axis_raddr_reg)
    );


    // Assigns
    assign s_axis_waddr = s_axis_waddr_reg[ADDRESS_WIDTH-1:0];
    assign m_axis_raddr = m_axis_raddr_reg[ADDRESS_WIDTH-1:0];

    // FIFO write logic - upstream
    // s_axis_full  - FIFO is full if next write pointer equal to read pointer
    // s_axis_ready - FIFO is always ready, unless it's full
    assign s_axis_fifo_fill    = s_axis_waddr_reg - s_axis_raddr_reg;
    assign s_axis_full         = (s_axis_fifo_fill[ADDRESS_WIDTH-1:0] == {ADDRESS_WIDTH{1'b1}}) ? 1'b1 : 1'b0;
    assign s_axis_almost_full  = (s_axis_fifo_fill > {1'b0, ~ALMOST_FULL_THRESHOLD[ADDRESS_WIDTH-1:0]}) ? 1'b1 : 1'b0;
    assign s_axis_ready        = ~s_axis_full;
    assign s_axis_room         = ~s_axis_fifo_fill[ADDRESS_WIDTH-1:0];

    // FIFO read logic - downstream
    // m_axis_empty - FIFO is empty if read pointer equal to write pointer
    // m_axis_valid - FIFO has a valid output data, if it's not empty
    assign m_axis_fifo_fill    = m_axis_waddr_reg - m_axis_raddr_reg;
    assign m_axis_empty        = (m_axis_fifo_fill == 0) ? 1'b1: 1'b0;
    assign m_axis_almost_empty = (m_axis_fifo_fill < ALMOST_EMPTY_THRESHOLD[ADDRESS_WIDTH:0]) ? 1'b1 : 1'b0;
    assign m_axis_valid        = ~m_axis_empty;
    assign m_axis_level        = m_axis_fifo_fill[ADDRESS_WIDTH-1:0];


    // Write address counter
    always_ff @(posedge s_axis_aclk) begin
        if (s_axis_aresetn == 1'b0) begin
            s_axis_waddr_reg <= 'h0;
        end else begin
            if (s_axis_valid == 1'b1 && s_axis_ready == 1'b1) begin
                s_axis_waddr_reg <= s_axis_waddr_reg + 1'b1;
            end
        end
    end

    // Read address counter
    always_ff @(posedge m_axis_aclk) begin
        if (m_axis_aresetn == 1'b0) begin
            m_axis_raddr_reg <= 'h0;
        end else begin
            if (m_axis_valid == 1'b1 && m_axis_ready == 1'b1) begin
                m_axis_raddr_reg <= m_axis_raddr_reg + 1'b1;
            end
        end
    end

endmodule
