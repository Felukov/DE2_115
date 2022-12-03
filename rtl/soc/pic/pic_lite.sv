//////////////////////////////////////////////////////////////////////////////////
//
// This file is part of the Next186 Soc PC project
// http://opencores.org/project,next186
//
// Filename: PIC_8259.v
// Description: Part of the Next186 SoC PC project, PIC controller
//     8259 simplified interrupt controller (only interrupt mask can be read, not irr or ISR, no EOI required)
// Version 1.0
// Creation date: May2012
//
// Author: Nicolae Dumitrache
// e-mail: ndumitrache@opencores.org
//
/////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2012 Nicolae Dumitrache
//
// This source file may be used and distributed without
// restriction provided that this copyright statement is not
// removed from the file and that any derivative work contains
// the original copyright notice and the associated disclaimer.
//
// This source file is free software; you can redistribute it
// and/or modify it under the terms of the GNU Lesser General
// Public License as published by the Free Software Foundation;
// either version 2.1 of the License, or (at your option) any
// later version.
//
// This source is distributed in the hope that it will be
// useful, but WITHOUT ANY WARRANTY; without even the implied
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
// PURPOSE. See the GNU Lesser General Public License for more
// details.
//
// You should have received a copy of the GNU Lesser General
// Public License along with this source; if not, download it
// from http://www.opencores.org/lgpl.shtml
//
///////////////////////////////////////////////////////////////////////////////////
// Additional Comments:
// http://wiki.osdev.org/8259_PIC
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module pic_lite (
    input  logic            clk,        // cpu CLK
    input  logic            resetn,

    input  logic            s_axis_io_req_tvalid,
    output logic            s_axis_io_req_tready,
    input  logic [39:0]     s_axis_io_req_tdata,
    output logic            m_axis_io_res_tvalid,
    input  logic            m_axis_io_res_tready,
    output logic [15:0]     m_axis_io_res_tdata,

    output logic [7:0]      interrupt_data,
    output logic            interrupt_valid,
    input                   interrupt_ack,
    input  logic [4:0]      interrupt_input    // 0:timer, 1:keyboard, 2:RTC, 3:mouse, 4:COM1
);


    localparam integer      INTR_QTY = 5;
    localparam integer      INTR_QTY_W = $clog2(INTR_QTY);

    logic [INTR_QTY-1:0]    d_interrupt_input;
    logic [INTR_QTY-1:0]    imr;
    logic [INTR_QTY-1:0]    irr;
    logic [INTR_QTY_W-1:0]  irr_idx;

    logic                   io_address;
    logic                   io_read;
    logic [7:0]             io_readdata;
    logic                   io_write;
    logic [7:0]             io_writedata;
    logic                   io_imr_cs;
    logic                   io_irr_cs;


    // Assigns

    assign s_axis_io_req_tready = 1'b1;

    assign io_read              = (s_axis_io_req_tvalid == 1'b1 && s_axis_io_req_tready == 1'b1 && s_axis_io_req_tdata[32] == 1'b0) ? 1'b1 : 1'b0;
    assign io_write             = (s_axis_io_req_tvalid == 1'b1 && s_axis_io_req_tready == 1'b1 && s_axis_io_req_tdata[32] == 1'b1) ? 1'b1 : 1'b0;
    assign io_writedata         = s_axis_io_req_tdata[7:0];

    assign io_imr_cs            = ({s_axis_io_req_tdata[31:17], 1'd0} == 16'h0020) ? 1'b1 : 1'b0;
	assign io_irr_cs            = ({s_axis_io_req_tdata[31:17], 1'd0} == 16'h00A0) ? 1'b1 : 1'b0;

    assign m_axis_io_res_tdata  = {8'd0, io_readdata};


    // Latching results
    always_ff @(posedge clk) begin
        // Resettable
        if (resetn == 1'b0) begin
            m_axis_io_res_tvalid <= 1'b0;
        end else begin
            if ((io_imr_cs == 1'b1 || io_irr_cs == 1'b1) && io_read == 1'b1) begin
                m_axis_io_res_tvalid <= 1'b1;
            end else if (m_axis_io_res_tready == 1'b1) begin
                m_axis_io_res_tvalid <= 1'b0;
            end
        end
        // Without reset
        begin
            if ((io_imr_cs == 1'b1 || io_irr_cs == 1'b1) && io_read == 1'b1) begin
                if (io_imr_cs == 1'b1) begin
                    io_readdata <= 8'($unsigned(imr));
                end else begin
                    io_readdata <= 8'($unsigned(irr));
                end
            end
        end
    end

    //
    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            imr <= '{default:'0};
        end else begin
            if (io_imr_cs == 1'b1 && io_write == 1'b1) begin
                imr <= io_writedata[INTR_QTY-1:0];
            end
        end
    end

    //
    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            irr <= '{default:'0};
        end else begin
            for (int i=0; i < INTR_QTY; i++) begin
                if (interrupt_input[i] == 1'b1 && d_interrupt_input[i] == 1'b0 && imr[i] == 1'b0) begin
                    irr[i] <= 1'b1;
                end else if (interrupt_valid == 1'b1 && interrupt_ack == 1'b1 && irr_idx == i[INTR_QTY_W-1:0]) begin
                    irr[i] <= 1'b0;
                end
            end
        end
        begin
            d_interrupt_input <= interrupt_input;
        end
    end

    always_ff @ (posedge clk) begin
        if (resetn == 1'b0) begin
            interrupt_valid <= 1'b0;
            interrupt_data <= 8'h00;
            irr_idx <= 0;
        end else begin
            if (interrupt_valid == 1'b0) begin
                if(irr[0]) begin //timer
                    interrupt_valid <= 1'b1;
                    interrupt_data <= 8'h08;
                    irr_idx <= 0;
                end else if(irr[1]) begin  // keyboard
                    interrupt_valid <= 1'b1;
                    interrupt_data <= 8'h09;
                    irr_idx <= 1;
                end else if(irr[2]) begin  // RTC
                    interrupt_valid <= 1'b1;
                    interrupt_data <= 8'h70;
                    irr_idx <= 2;
                end else if(irr[3]) begin // mouse
                    interrupt_valid <= 1'b1;
                    interrupt_data <= 8'h74;
                    irr_idx <= 3;
                end else if(irr[4]) begin // COM1
                    interrupt_valid <= 1'b1;
                    interrupt_data <= 8'h0c;
                    irr_idx <= 4;
                end
            end else if (interrupt_ack == 1'b1) begin
                interrupt_valid <= 1'b0;    // also act as Auto EOI
            end
        end
    end


endmodule
