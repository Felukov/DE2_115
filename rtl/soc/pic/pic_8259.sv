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
    //logic               io_read_last;
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
    logic [7:0]         interrupt_mask_register;
    logic [7:0]         in_service_register;
    logic [7:0]         interrupt_request_register;
    logic [4:0]         interrupt_offset;
    logic               auto_eoi;
    logic [7:0]         irr_slave;
    logic               rotate_on_aeoi;
    logic               spurious_start;
    logic               spurious;
    logic               isr_clear;

    logic [7:0]         selectected_prepare;
    logic [15:0]        selectected_shifted;
    logic [15:0]        selectected_shifted_isr;

    logic [2:0]         selectected_shifted_isr_first;
    logic [2:0]         selectected_shifted_isr_first_norm;
    logic [7:0]         selectected_shifted_isr_first_bits;
    logic [2:0]         selectected_index;

    logic               irq;
    logic [2:0]         irq_value;
    logic               acknowledge_not_spurious;
    logic               acknowledge;

    logic [7:0]         interrupt_mask;


    // Assigns
    //assign io_read_valid    = (io_read == 1'b1 && io_read_last == 1'b0) ? 1'b1 : 1'b0;

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
        (io_address == 1'b0 && read_reg_select == 1'b0) ? interrupt_request_register :
        (io_address == 1'b0 && read_reg_select == 1'b1) ? in_service_register :
                                                        interrupt_mask_register;

    assign selectected_prepare = interrupt_request_register & ~interrupt_mask_register & ~in_service_register;

    assign selectected_shifted = {selectected_prepare[0],selectected_prepare,selectected_prepare[7:1]} >> lowest_priority;
    assign selectected_shifted_isr = {in_service_register[0],in_service_register,in_service_register[7:1]} >> lowest_priority;

    assign selectected_shifted_isr_first =
        (selectected_shifted_isr[0]) ? 3'd0 :
        (selectected_shifted_isr[1]) ? 3'd1 :
        (selectected_shifted_isr[2]) ? 3'd2 :
        (selectected_shifted_isr[3]) ? 3'd3 :
        (selectected_shifted_isr[4]) ? 3'd4 :
        (selectected_shifted_isr[5]) ? 3'd5 :
        (selectected_shifted_isr[6]) ? 3'd6 :
                                    3'd7;

    assign selectected_shifted_isr_first_norm = lowest_priority + selectected_shifted_isr_first + 3'd1;
    assign selectected_shifted_isr_first_bits = 8'h01 << selectected_shifted_isr_first_norm;

    assign selectected_index =
        (selectected_shifted[0]) ? 3'd0 :
        (selectected_shifted[1]) ? 3'd1 :
        (selectected_shifted[2]) ? 3'd2 :
        (selectected_shifted[3]) ? 3'd3 :
        (selectected_shifted[4]) ? 3'd4 :
        (selectected_shifted[5]) ? 3'd5 :
        (selectected_shifted[6]) ? 3'd6 :
                                3'd7;

    assign irq = selectected_prepare != 8'd0 && (special_mask_mode || selectected_index <= selectected_shifted_isr_first);

    assign irq_value = lowest_priority + selectected_index + 3'd1;

    assign acknowledge_not_spurious = (polled_mode && io_read_valid) || (interrupt_ack && ~spurious);
    assign acknowledge              = (polled_mode && io_read_valid) || interrupt_ack;

    assign spurious_start = interrupt_valid && ~interrupt_ack && ~irq;

    // always_ff @(posedge clk) begin
    //     if (resetn == 1'b0) begin
    //         io_read_last <= 1'b0;
    //     end else begin
    //         if (io_read_last == 1'b1) begin
    //             io_read_last <= 1'b0;
    //         end else begin
    //             io_read_last <= io_read;
    //         end
    //     end
    // end

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
            interrupt_mask_register <= 8'hFF;
        end else begin
            if (init_icw1 == 1'b1) begin
                interrupt_mask_register <= 8'h00;
            end else if (ocw1 == 1'b1) begin
                interrupt_mask_register <= io_writedata;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            interrupt_request_register <= 8'h00;
        end else begin
            if (init_icw1 == 1'b1) begin
                interrupt_request_register <= 8'h00;
            end else if (acknowledge_not_spurious == 1'b1) begin
                interrupt_request_register <= (interrupt_request_register & interrupt_input & ~interrupt_mask) | ((~level_trigger_mode) ? edge_detect : interrupt_input);
            end else begin
                interrupt_request_register <= (interrupt_request_register & interrupt_input) | ((~level_trigger_mode) ? edge_detect : interrupt_input);
            end
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            in_service_register <= 8'h00;
        end else begin
            if (init_icw1 == 1'b1) begin
                in_service_register <= 8'h00;
            end else if (ocw2 == 1'b1 && { io_writedata[7:3], 3'b000 } == 8'h60) begin
                //clear on specific EOI
                in_service_register <= in_service_register & ~writedata_mask;
            end else if (ocw2 == 1'b1 && { io_writedata[7:3], 3'b000 } == 8'hE0) begin
                //clear on rotate on specific EOI
                in_service_register <= in_service_register & ~writedata_mask;
            end else if (isr_clear == 1'b1) begin
                //clear on polling or non-specific EOI (with or without rotate)
                in_service_register <= in_service_register & ~selectected_shifted_isr_first_bits;
            end else if (acknowledge_not_spurious == 1'b1 && auto_eoi == 1'b0) begin
                //set
                in_service_register <= in_service_register | interrupt_mask;
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

    //assign interrupt_mask = 8'h01 << interrupt_data[2:0];

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
