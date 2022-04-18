/*
 * Copyright (c) 2014, Aleksander Osman
 * Copyright (C) 2020, Alexey Melnikov
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

module pic (
    input  logic                clk,
    input  logic                resetn,

    input  logic                io_req_s_tvalid,
    output logic                io_req_s_tready,
    input  logic [39:0]         io_req_s_tdata,

    output logic                io_rd_m_tvalid,
    input  logic                io_rd_m_tready,
    output logic [15:0]         io_rd_m_tdata,

    //interrupt input
    input  logic [15:0]         interrupt_input,

    //interrupt output
    output logic                interrupt_valid,
    output logic [7:0]          interrupt_data,
    input  logic                interrupt_ack
);

    // Signals
    logic [7:0]                 mas_readdata;
    logic [7:0]                 mas_vector;
    logic                       sla_active;

    logic [7:0]                 sla_readdata;
    logic                       sla_int;
    logic [7:0]                 sla_vector;
    logic                       sla_select;

    logic                       io_address;
    logic                       io_read;
    logic [7:0]                 io_readdata;
    logic                       io_write;
    logic [7:0]                 io_writedata;
    logic                       io_master_cs;
    logic                       io_slave_cs;


    // Assigns
    assign sla_select           = (sla_active == 1'b1 && (mas_vector[2:0] == 3'd2)) ? 1'b1 : 1'b0;
    assign interrupt_data       = (sla_select == 1'b1) ? sla_vector : mas_vector;

    assign io_read              = (io_req_s_tvalid == 1'b1 && io_req_s_tready == 1'b1 && io_req_s_tdata[32] == 1'b0) ? 1'b1 : 1'b0;
    assign io_write             = (io_req_s_tvalid == 1'b1 && io_req_s_tready == 1'b1 && io_req_s_tdata[32] == 1'b1) ? 1'b1 : 1'b0;
    assign io_address           = io_req_s_tdata[16];
    assign io_writedata         = io_req_s_tdata[7:0];

    assign io_master_cs         = ({io_req_s_tdata[31:17], 1'd0} == 16'h0020) ? 1'b1 : 1'b0;
	assign io_slave_cs          = ({io_req_s_tdata[31:17], 1'd0} == 16'h00A0) ? 1'b1 : 1'b0;

    assign io_req_s_tready      = (io_rd_m_tvalid == 1'b0) ? 1'b1 : 1'b0;

    assign io_rd_m_tdata        = {8'd0, io_readdata};


    // Module pic_8259 instantiation
    pic_8259 pic_8259_master_inst (
        .clk                    (clk),
        .resetn                 (resetn),

        .io_address             (io_address),
        .io_read                (io_read & io_master_cs),
        .io_readdata            (mas_readdata),
        .io_write               (io_write & io_master_cs),
        .io_writedata           (io_writedata),

        .interrupt_input        ({interrupt_input[7:3], sla_int, interrupt_input[1:0]}),

        .slave_active           (sla_active),

        .interrupt_valid        (interrupt_valid),
        .interrupt_data         (mas_vector),
        .interrupt_ack          (interrupt_ack)
    );


    // Module pic_8259 instantiation
    pic_8259 pic_8259_slave_inst (
        .clk                    (clk),
        .resetn                 (resetn),

        .io_address             (io_address),
        .io_read                (io_read & io_slave_cs),
        .io_readdata            (sla_readdata),
        .io_write               (io_write & io_slave_cs),
        .io_writedata           (io_writedata),

        .interrupt_input        (interrupt_input[15:8]),

        .slave_active           (),

        .interrupt_valid        (sla_int),
        .interrupt_data         (sla_vector),
        .interrupt_ack          (sla_select & interrupt_ack)
    );


    // Latching results
    always_ff @(posedge clk) begin
        // Resettable
        if (resetn == 1'b0) begin
            io_rd_m_tvalid <= 1'b0;
        end else begin
            if ((io_master_cs == 1'b1 || io_slave_cs == 1'b1) && io_read == 1'b1) begin
                io_rd_m_tvalid <= 1'b1;
            end else if (io_rd_m_tready == 1'b1) begin
                io_rd_m_tvalid <= 1'b0;
            end
        end
        // Without reset
        begin
            if ((io_master_cs == 1'b1 || io_slave_cs == 1'b1) && io_read == 1'b1) begin
                if (io_master_cs == 1'b1) begin
                    io_readdata <= mas_readdata;
                end else begin
                    io_readdata <= sla_readdata;
                end
            end
        end
    end

endmodule
