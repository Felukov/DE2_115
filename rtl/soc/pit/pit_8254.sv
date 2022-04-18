/*
 * Copyright (c) 2014, Aleksander Osman
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

module pit_8254 (

    input  logic                clk,
    input  logic                resetn,

    input  logic                io_req_s_tvalid,
    output logic                io_req_s_tready,
    input  logic [39:0]         io_req_s_tdata,

    output logic                io_rd_m_tvalid,
    input  logic                io_rd_m_tready,
    output logic [15:0]         io_rd_m_tdata,

    output logic                event_irq,
    output logic                event_timer

);

    // Constants
    // 2^32-1 / 100 MHz * 1193181,8181 Hz
    localparam integer          FREQ_OFFSET = 51246769;

    // Local signals
    logic [31:0]                freq_counter;
    logic                       timer_clk;

    logic                       io_write;
    logic                       io_read;
    logic [15:0]                io_address;
    logic [15:0]                io_data;

    logic                       cs;
    logic [2:0]                 set_control_mode;
    logic [2:0]                 latch_count;
    logic [2:0]                 latch_status;
    logic                       write_ctrl;
    logic [2:0]                 write;
    logic [2:0]                 read;

    logic [2:0][7:0]            readdata;


    // Assigns
    assign io_read              = (io_req_s_tvalid == 1'b1 && io_req_s_tready == 1'b1 && io_req_s_tdata[32] == 1'b0) ? 1'b1 : 1'b0;
    assign io_write             = (io_req_s_tvalid == 1'b1 && io_req_s_tready == 1'b1 && io_req_s_tdata[32] == 1'b1) ? 1'b1 : 1'b0;
    assign io_address           = io_req_s_tdata[31:16];
    assign io_data              = io_req_s_tdata[15:0];

    assign timer_clk            = freq_counter[31];

    assign cs                   = (io_address[15:4] == 12'h004) ? 1'b1 : 1'b0;

    assign write_ctrl           = (io_write == 1'b1 && io_address[2:0] == 3'd3) ? 1'b1 : 1'b0;

    assign write[0]             = (io_write == 1'b1 && io_address[2:0] == 3'd0) ? 1'b1 : 1'b0;
    assign write[1]             = (io_write == 1'b1 && io_address[2:0] == 3'd1) ? 1'b1 : 1'b0;
    assign write[2]             = (io_write == 1'b1 && io_address[2:0] == 3'd2) ? 1'b1 : 1'b0;

    assign read[0]              = (io_read == 1'b1 && io_address[2:0] == 3'd0) ? 1'b1 : 1'b0;
    assign read[1]              = (io_read == 1'b1 && io_address[2:0] == 3'd1) ? 1'b1 : 1'b0;
    assign read[2]              = (io_read == 1'b1 && io_address[2:0] == 3'd2) ? 1'b1 : 1'b0;

    assign set_control_mode[0]  = (io_data[7:6] == 2'b00 && io_data[5:4] != 2'b00) ? 1'b1 : 1'b0;
    assign set_control_mode[1]  = (io_data[7:6] == 2'b01 && io_data[5:4] != 2'b00) ? 1'b1 : 1'b0;
    assign set_control_mode[2]  = (io_data[7:6] == 2'b10 && io_data[5:4] != 2'b00) ? 1'b1 : 1'b0;

    assign latch_count[0]       = ((io_data[7:6] == 2'b00 && io_data[5:4] == 2'b00) || (io_data[7:5] == 3'b110 && io_data[1] == 1'b1)) ? 1'b1 : 1'b0;
    assign latch_count[1]       = ((io_data[7:6] == 2'b01 && io_data[5:4] == 2'b00) || (io_data[7:5] == 3'b110 && io_data[2] == 1'b1)) ? 1'b1 : 1'b0;
    assign latch_count[2]       = ((io_data[7:6] == 2'b10 && io_data[5:4] == 2'b00) || (io_data[7:5] == 3'b110 && io_data[3] == 1'b1)) ? 1'b1 : 1'b0;

    assign latch_status[0]      = (io_data[7:6] == 2'b11 && io_data[4] == 1'b0 && io_data[1] == 1'b1) ? 1'b1 : 1'b0;
    assign latch_status[1]      = (io_data[7:6] == 2'b11 && io_data[4] == 1'b0 && io_data[2] == 1'b1) ? 1'b1 : 1'b0;
    assign latch_status[2]      = (io_data[7:6] == 2'b11 && io_data[4] == 1'b0 && io_data[3] == 1'b1) ? 1'b1 : 1'b0;

    assign io_req_s_tready      = (io_rd_m_tvalid == 1'b0) ? 1'b1 : 1'b0;


    // Module pit_8254_counter instantiation
    pit_8254_counter pit_counter_0_inst (
        .clk                (clk),
        .resetn             (resetn),

        .clock              (timer_clk),
        .gate               (1'b1),

        .data_in            (io_data[7:0]),
        .set_control_mode   (cs & write_ctrl & set_control_mode[0]),
        .latch_count        (cs & write_ctrl & latch_count[0]),
        .latch_status       (cs & write_ctrl & latch_status[0]),
        .write              (cs & write[0]),
        .read               (cs & read[0]),

        .data_out           (readdata[0]),
        .counter_out        (event_irq)
    );

    // Module pit_8254_counter instantiation
    pit_8254_counter pit_counter_1_inst (
        .clk                (clk),
        .resetn             (resetn),

        .clock              (timer_clk),
        .gate               (1'b1),

        .data_in            (io_data[7:0]),
        .set_control_mode   (cs & write_ctrl & set_control_mode[1]),
        .latch_count        (cs & write_ctrl & latch_count[1]),
        .latch_status       (cs & write_ctrl & latch_status[1]),
        .write              (cs & write[1]),
        .read               (cs & read[1]),

        .data_out           (readdata[1]),
        .counter_out        (event_timer)
    );

    // Timer clock generator process
    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            freq_counter <= '{default:'0};
        end else begin
            freq_counter <= freq_counter + FREQ_OFFSET;
        end
    end

    // Forming output data process
    always_ff @(posedge clk) begin
        // Resettable
        if (resetn == 1'b0) begin
            io_rd_m_tvalid <= 1'b0;
        end else begin
            if (cs == 1'b1 && io_read == 1'b1) begin
                io_rd_m_tvalid <= 1'b1;
            end else if (io_rd_m_tready == 1'b1) begin
                io_rd_m_tvalid <= 1'b0;
            end
        end
        // Without reset
        begin
            case (1'b1)
                read[0] : io_rd_m_tdata <= readdata[0];
                read[1] : io_rd_m_tdata <= readdata[1];
                read[2] : io_rd_m_tdata <= readdata[2];
				default : io_rd_m_tdata <= readdata[0]; // illegal
            endcase
        end
    end

endmodule
