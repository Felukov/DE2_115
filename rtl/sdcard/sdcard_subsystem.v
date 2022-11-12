/***************************************************************************************************
*  sd.v
*
*  Copyright (c) 2015, Magnus Karlsson
*  All rights reserved.
*
*  Redistribution and use in source and binary forms, with or without modification, are permitted
*  provided that the following conditions are met:
*
*  1. Redistributions of source code must retain the above copyright notice, this list of conditions
*     and the following disclaimer.
*  2. Redistributions in binary form must reproduce the above copyright notice, this list of
*     conditions and the following disclaimer in the documentation and/or other materials provided
*     with the distribution.
*
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
*  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
*  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
*  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
*  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
*  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
*  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
*  WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*
***************************************************************************************************/


`timescale 1ns/100ps

module sdcard_subsystem(
    clk,
    resetn,
    sd_clk,
    sd_cmd,
    sd_dat,
    sd_active,
    sd_read,
    sd_write,
    event_error,
    disk_mounted,
    blocks,
    io_lba,
    io_rd,
    io_wr,
    io_ack,
    io_din_tvalid,
    io_din_tdata,
    io_dout_tvalid,
    io_dout_tready,
    io_dout_tdata
);

    input           clk;
    input           resetn;

    // sd card interface
    output          sd_clk;
    inout           sd_cmd;
    inout [3:0]     sd_dat;
    output          sd_active;
    output          sd_read;
    output          sd_write;
    output          disk_mounted;
    output [21:0]   blocks;
    output          event_error;

    input [31:0]    io_lba;
    input           io_rd;
    input           io_wr;
    output          io_ack;

    output          io_din_tvalid;
    output [7:0]    io_din_tdata;

    input           io_dout_tvalid;
    output          io_dout_tready;
    input [7:0]     io_dout_tdata;


    // local signals
    wire [119:0]    response;
    wire [39:0]     command;
    wire [8:0]      control;

    wire [3:0]      sd_dat_out;
    wire [3:0]      sd_dat_in;
    wire            sd_cmd_in;
    wire            sd_cmd_oe;
    wire            sd_dat_oe;
    wire            sd_cmd_out;

    wire            sd_busy;

    wire            switch_pending;
    wire            clk_stopped;
    wire            timeout;
    wire            command_valid;
    wire            command_busy;
    wire            resp_valid;
    wire            cmd_crc_ok;
    wire            sd_write_enable;
    wire            sd_read_enable;
    wire            wide_width_data;
    wire            send_busy;
    wire            rec_busy;
    wire            dat_crc_ok;
    wire            startup;

    // module sd_phy instantiation
	sd_phy sd_phy_inst (
        .clk                (clk),
        .resetn             (resetn),
        .control            (control),
        .switch_pending     (switch_pending),
        .clk_stopped        (clk_stopped),
        .sd_clk             (sd_clk),
        .sd_cmd_in          (sd_cmd_in),
        .sd_cmd_out         (sd_cmd_out),
        .sd_cmd_oe          (sd_cmd_oe),
        .sd_dat_in          (sd_dat_in),
        .sd_dat_out         (sd_dat_out),
        .sd_dat_oe          (sd_dat_oe),
        .fifo_rd            (io_dout_tready),
        .fifo_din           (io_dout_tdata),
        .fifo_wr            (io_din_tvalid),
        .fifo_dout          (io_din_tdata),
        .timeout            (timeout),
        .command_valid      (command_valid),
        .command            (command),
        .command_busy       (command_busy),
        .resp_valid         (resp_valid),
        .response           (response),
        .cmd_crc_ok         (cmd_crc_ok),
        .sd_write_enable    (sd_write_enable),
        .sd_read_enable     (sd_read_enable),
        .wide_width_data    (wide_width_data),
        .send_busy          (send_busy),
        .rec_busy           (rec_busy),
        .sd_busy            (sd_busy),
        .dat_crc_ok         (dat_crc_ok),
        .startup            (startup)
	);

    // module sd_fsm instantiation
    sd_fsm sd_fsm_inst (
        .clk                (clk),
        .resetn             (resetn),
        .control            (control),
        .switch_pending     (switch_pending),
        .clk_stopped        (clk_stopped),
        .command_valid      (command_valid),
        .command            (command),
        .command_busy       (command_busy),
        .cmd_crc_ok         (cmd_crc_ok),
        .timeout            (timeout),
        .response           (response),
        .resp_valid         (resp_valid),
        .sd_write_enable    (sd_write_enable),
        .sd_read_enable     (sd_read_enable),
        .wide_width_data    (wide_width_data),
        .send_busy          (send_busy),
        .rec_busy           (rec_busy),
        .sd_busy            (sd_busy),
        .dat_crc_ok         (dat_crc_ok),
        .error              (event_error),
        .disk_mounted       (disk_mounted),
        .blocks             (blocks),
        .sd_active          (sd_active),
        .sd_read            (sd_read),
        .sd_write           (sd_write),
        .startup            (startup),
        .io_rd              (io_rd),
        .io_wr              (io_wr),
        .io_ack             (io_ack),
        .io_lba             (io_lba)
    );

    // Assigns
    assign sd_cmd    = sd_cmd_oe ? 1'bZ : sd_cmd_out;
    assign sd_cmd_in = sd_cmd;
    assign sd_dat    = sd_dat_oe ? 4'bZZZZ : sd_dat_out;
    assign sd_dat_in = sd_dat;

endmodule
