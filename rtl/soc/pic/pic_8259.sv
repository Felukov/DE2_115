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

module pic_8259
(
	input  logic        clk,
	input  logic        resetn,

	input  logic        io_address,
	input  logic        io_read,
	output logic [7:0]  io_readdata,
	input  logic        io_write,
	input  logic [7:0]  io_writedata,

	//interrupt input
	input  logic [7:0]  interrupt_input,
	output logic        slave_active,

	//interrupt output
	output logic        interrupt_valid,
	output logic [7:0]  interrupt_data,
	input               interrupt_ack
);

    // Local signals
    logic               io_read_valid;
    logic               init_icw1;
    logic               init_icw2;
    logic               init_icw3;
    logic               init_icw4;
    logic               ocw1;
    logic               ocw2;
    logic               ocw3;
    logic [7:0]         edge_detect;
    logic [7:0]         writedata_mask;

    logic [7:0]         d_interrupt_input;

    logic               init_mode;
    logic               init_requires_4;
    logic [2:0]         init_byte_expected;

    logic               polled_mode;
    logic               special_mask_mode;
    logic               read_reg_select;
    logic               level_trigger_mode;                   // level trigger mode

    logic [2:0]         lowest_priority;
    logic [7:0]         IMR;
    logic [7:0]         ISR;
    logic [7:0]         IRR;
    logic [4:0]         interrupt_offset;
    logic               auto_eoi;
    logic [7:0]         irr_slave;
    logic               rotate_on_aeoi;
    logic               spurious_start;
    logic               spurious;
    logic               isr_clear;

    logic [7:0]         irx_vec;
    logic [15:0]        irx_vec_priority;
    logic [2:0]         irx_idx;

    logic [15:0]        isr_vec_priority;
    logic [2:0]         isr_idx;
    logic [2:0]         isr_value;
    logic [7:0]         isr_idx_bits;

    logic               irq;
    logic [2:0]         irq_value;
    logic               acknowledge_not_spurious;
    logic               acknowledge;

    logic [7:0]         interrupt_mask;


    // Assigns
    assign init_icw1        = (io_write == 1'b1 && io_address == 1'b0 && io_writedata[4] == 1'b1) ? 1'b1 : 1'b0;
    assign init_icw2        = (io_write == 1'b1 && io_address == 1'b1 && init_mode == 1'b1 && init_byte_expected == 3'd2) ? 1'b1 : 1'b0;
    assign init_icw3        = (io_write == 1'b1 && io_address == 1'b1 && init_mode == 1'b1 && init_byte_expected == 3'd3) ? 1'b1 : 1'b0;
    assign init_icw4        = (io_write == 1'b1 && io_address == 1'b1 && init_mode == 1'b1 && init_byte_expected == 3'd4) ? 1'b1 : 1'b0;

    assign ocw1             = (init_mode == 1'b0 && io_write == 1'b1 && io_address == 1'b1) ? 1'b1 : 1'b0;
    assign ocw2             = (io_write == 1'b1 && io_address == 1'b0 && io_writedata[4:3] == 2'b00) ? 1'b1 : 1'b0;
    assign ocw3             = (io_write == 1'b1 && io_address == 1'b0 && io_writedata[4:3] == 2'b01) ? 1'b1 : 1'b0;

    assign edge_detect      = interrupt_input & ~d_interrupt_input;

    assign writedata_mask   = 8'h01 << io_writedata[2:0];

    assign isr_clear        = (
        (polled_mode == 1'b1 && io_read_valid == 1'b1) || //polling
        (ocw2 == 1'b1 && (io_writedata == 8'h20 || io_writedata == 8'hA0)) //non-specific EOI or rotate on non-specific EOF
    ) ? 1'b1 : 1'b0;

    assign io_readdata =
        (polled_mode == 1'b1)                           ? { interrupt_valid, 4'd0, irq_value } :
        (io_address == 1'b0 && read_reg_select == 1'b0) ? IRR :
        (io_address == 1'b0 && read_reg_select == 1'b1) ? ISR :
                                                        IMR;

    assign irx_vec = IRR & ~IMR & ~ISR;

    assign irx_vec_priority = {irx_vec[0], irx_vec, irx_vec[7:1]} >> lowest_priority;
    assign isr_vec_priority = {ISR[0], ISR, ISR[7:1]} >> lowest_priority;

    assign isr_idx =
        (isr_vec_priority[0]) ? 3'd0 :
        (isr_vec_priority[1]) ? 3'd1 :
        (isr_vec_priority[2]) ? 3'd2 :
        (isr_vec_priority[3]) ? 3'd3 :
        (isr_vec_priority[4]) ? 3'd4 :
        (isr_vec_priority[5]) ? 3'd5 :
        (isr_vec_priority[6]) ? 3'd6 :
                                3'd7;

    assign isr_value = lowest_priority + isr_idx + 3'd1;
    assign isr_idx_bits = 8'h01 << isr_value;

    assign irx_idx =
        (irx_vec_priority[0]) ? 3'd0 :
        (irx_vec_priority[1]) ? 3'd1 :
        (irx_vec_priority[2]) ? 3'd2 :
        (irx_vec_priority[3]) ? 3'd3 :
        (irx_vec_priority[4]) ? 3'd4 :
        (irx_vec_priority[5]) ? 3'd5 :
        (irx_vec_priority[6]) ? 3'd6 :
                                3'd7;

    assign irq = irx_vec != 8'd0 && (special_mask_mode == 1'b1 || irx_idx <= isr_idx);

    assign irq_value = lowest_priority + irx_idx + 3'd1;

    assign acknowledge_not_spurious = (polled_mode && io_read_valid) || (interrupt_ack && ~spurious);
    assign acknowledge              = (polled_mode && io_read_valid) || interrupt_ack;

    assign spurious_start = interrupt_valid && ~interrupt_ack && ~irq;

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            io_read_valid <= 1'b0;
        end else begin
            if (io_read_valid == 1'b1) begin
                io_read_valid <= 1'b0;
            end else begin
                io_read_valid <= io_read;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            d_interrupt_input <= 8'd0;
        end else begin
            d_interrupt_input <= interrupt_input;
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            polled_mode <= 1'b0;
        end else begin
            if (polled_mode == 1'b1 && io_read_valid == 1'b1) begin
                polled_mode <= 1'b0;
            end else if (ocw3 == 1'b1) begin
                polled_mode <= io_writedata[2];
            end
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            read_reg_select <= 1'b0;
        end else begin
            if (init_icw1 == 1'b1) begin
                read_reg_select <= 1'b0;
            end else if (ocw3 == 1'b1 && io_writedata[2] == 1'b0 && io_writedata[1] == 1'b1) begin
                read_reg_select <= io_writedata[0];
            end
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            special_mask_mode <= 1'd0;
        end else begin
            if (init_icw1 == 1'b1) begin
                special_mask_mode <= 1'd0;
            end else if (ocw3 == 1'b1 && io_writedata[2] == 1'b0 && io_writedata[6] == 1'b1) begin
                special_mask_mode <= io_writedata[5];
            end
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            init_mode <= 1'b0;
        end else begin
            if (init_icw1 == 1'b1) begin
                init_mode <= 1'b1;
            end else if (init_icw3 == 1'b1 && init_requires_4 == 1'b0) begin
                init_mode <= 1'b0;
            end else if (init_icw4 == 1'b1) begin
                init_mode <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            init_requires_4 <= 1'b0;
        end else if (init_icw1 == 1'b1) begin
            init_requires_4 <= io_writedata[0];
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            level_trigger_mode <= 1'b0;
        end else begin
            if (init_icw1 == 1'b1) begin
                level_trigger_mode <= io_writedata[3];
            end
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            init_byte_expected <= 3'd0;
        end else begin
            if (init_icw1 == 1'b1) begin
                init_byte_expected <= 3'd2;
            end else if (init_icw2 == 1'b1) begin
                init_byte_expected <= 3'd3;
            end else if (init_icw3 == 1'b1 && init_requires_4 == 1'b1) begin
                init_byte_expected <= 3'd4;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            lowest_priority <= 3'd7;
        end else begin
            if (init_icw1 == 1'b1) begin
                lowest_priority <= 3'd7;
            end else if (ocw2 == 1'b1 && io_writedata == 8'hA0) begin
                lowest_priority <= lowest_priority + 3'd1;  //rotate on non-specific EOI
            end else if (ocw2 == 1'b1 && { io_writedata[7:3], 3'b000 } == 8'hC0) begin
                lowest_priority <= io_writedata[2:0];       //set priority
            end else if (ocw2 == 1'b1 && { io_writedata[7:3], 3'b000 } == 8'hE0) begin
                lowest_priority <= io_writedata[2:0];       //rotate on specific EOI
            end else if (acknowledge_not_spurious == 1'b1 && auto_eoi == 1'b1 && rotate_on_aeoi == 1'b1) begin
                lowest_priority <= lowest_priority + 3'd1;  //rotate on AEOI
            end
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            IMR <= 8'hFF;
        end else begin
            if (init_icw1 == 1'b1) begin
                IMR <= 8'h00;
            end else if (ocw1 == 1'b1) begin
                IMR <= io_writedata;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            IRR <= 8'h00;
        end else begin
            if (init_icw1 == 1'b1) begin
                IRR <= 8'h00;
            end else if (acknowledge_not_spurious == 1'b1) begin
                IRR <= (IRR & interrupt_input & ~interrupt_mask) | ((~level_trigger_mode) ? edge_detect : interrupt_input);
            end else begin
                IRR <= (IRR & interrupt_input) | ((~level_trigger_mode) ? edge_detect : interrupt_input);
            end
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            ISR <= 8'h00;
        end else begin
            if (init_icw1 == 1'b1) begin
                ISR <= 8'h00;
            end else if (ocw2 == 1'b1 && { io_writedata[7:3], 3'b000 } == 8'h60) begin
                //clear on specific EOI
                ISR <= ISR & ~writedata_mask;
            end else if (ocw2 == 1'b1 && { io_writedata[7:3], 3'b000 } == 8'hE0) begin
                //clear on rotate on specific EOI
                ISR <= ISR & ~writedata_mask;
            end else if (isr_clear == 1'b1) begin
                //clear on polling or non-specific EOI (with or without rotate)
                ISR <= ISR & ~isr_idx_bits;
            end else if (acknowledge_not_spurious == 1'b1 && auto_eoi == 1'b0) begin
                //set
                ISR <= ISR | interrupt_mask;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            interrupt_offset <= 5'h0E;
        end else begin
            if (init_icw2 == 1'b1) begin
                interrupt_offset <= io_writedata[7:3];
            end
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            auto_eoi <= 1'b0;
        end else begin
            if (init_icw1 == 1'b1) begin
                auto_eoi <= 1'b0;
            end else if (init_icw4 == 1'b1) begin
                auto_eoi <= io_writedata[1];
            end
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            irr_slave <= 8'h00;
        end else begin
            if (init_icw3 == 1'b1) begin
                irr_slave <= io_writedata;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            rotate_on_aeoi <= 1'b0;
        end else begin
            if (init_icw1 == 1'b1) begin
                rotate_on_aeoi <= 1'b0;
            end else if(ocw2 == 1'b1 && io_writedata[6:0] == 7'd0) begin
                rotate_on_aeoi <= io_writedata[7];
            end
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            interrupt_valid <= 1'b0;
        end else begin
            if (init_icw1 == 1'b1) begin
                interrupt_valid <= 1'b0;
            end else if (acknowledge == 1'b1) begin
                interrupt_valid <= 1'b0;
            end else if (irq == 1'b1) begin
                interrupt_valid <= 1'b1;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            spurious <= 1'd0;
        end else begin
            if (init_icw1 == 1'b1) begin
                spurious <= 1'b0;
            end else if (spurious_start == 1'b1) begin
                spurious <= 1'b1;
            end else if (acknowledge == 1'b1 || irq == 1'b1) begin
                spurious <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            slave_active <= 1'b0;
        end else begin
            if (init_icw1 == 1'b1) begin
                slave_active <= 1'b0;
            end else if (acknowledge == 1'b1) begin
                slave_active <= 1'b0;
            end else if (irq == 1'b1 || interrupt_valid == 1'b1) begin
                slave_active <= irr_slave[irq_value];
            end
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            interrupt_data <= 8'd0;
        end else begin
            if (init_icw1 == 1'b1) begin
                interrupt_data <= 8'd0;
            end else if (irq == 1'b1 || interrupt_valid == 1'b1) begin
                interrupt_data <= { interrupt_offset, irq_value };
            end
        end
    end

    // Forming interrupt mask process
    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            interrupt_mask <= 8'h01;
        end else begin
            if (init_icw1 == 1'b1) begin
                interrupt_mask <= 8'h01;
            end else if (irq == 1'b1 || interrupt_valid == 1'b1) begin
                interrupt_mask <= 8'h01 << irq_value;
            end
        end
    end

endmodule
