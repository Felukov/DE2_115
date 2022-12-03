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

module pit_8254_counter (
    input  logic        clk,
    input  logic        resetn,

    input  logic        clock,
    input  logic        gate,

    input  logic [7:0]  data_in,
    input  logic        set_control_mode,
    input  logic        latch_count,
    input  logic        latch_status,
    input  logic        write,
    input  logic        read,

    output logic [7:0]  data_out,
    output logic        counter_out
);

    // Local signals
    logic [2:0]         mode;
    logic               bcd;
    logic [1:0]         rw_mode;
    logic [7:0]         counter_l;
    logic [7:0]         counter_m;
    logic [7:0]         output_l;
    logic [7:0]         output_m;
    logic               output_latched;
    logic               null_counter;
    logic               msb_write;
    logic               msb_read;
    logic [7:0]         status;
    logic               status_latched;
    logic               d_clock;
    logic               clock_pulse;
    logic               gate_last;
    logic               gate_sampled;
    logic               trigger;
    logic               trigger_sampled;
    logic               written;
    logic               loaded;
    logic               load;
    logic               load_even;
    logic               enable;
    logic               enable_double;
    logic [3:0]         bcd_3;
    logic [3:0]         bcd_2;
    logic [3:0]         bcd_1;
    logic [15:0]        counter_minus_1;
    logic [15:0]        counter_minus_2;
    logic [15:0]        counter;


    // Assigns
    assign data_out =
        (status_latched == 1'b1) ?              status :
        (rw_mode == 2'd3 && msb_read == 1'b0) ? output_l :
        (rw_mode == 2'd3 && msb_read == 1'b1) ? output_m :
        (rw_mode == 2'd1) ?                     output_l :
                                                output_m;

    assign load = (clock_pulse == 1'b1 && (
        (mode == 3'd0 && written == 1'b1) ||
        (mode == 3'd1 && written == 1'b1 && trigger_sampled == 1'b1) ||
        (mode[1:0] == 2'd2 && (written == 1'b1 || trigger_sampled == 1'b1 || (loaded == 1'b1 && gate_sampled == 1'b1 && counter == 16'd1))) ||
        (mode[1:0] == 2'd3 && (written == 1'b1 || trigger_sampled == 1'b1 || (loaded == 1'b1 && gate_sampled == 1'b1 &&
         ((counter == 16'd2 && (~(counter_l[0]) || ~(counter_out))) || (counter == 16'd0 && counter_l[0] && counter_out))))) ||
        (mode == 3'd4 && written == 1'b1) ||
        (mode == 3'd5 && (written == 1'b1 || loaded == 1'b1) && trigger_sampled == 1'b1)
    )) ? 1'b1 : 1'b0;

    assign load_even = (load == 1'b1 && mode[1:0] == 2'd3) ? 1'b1 : 1'b0;

    assign enable = (load == 1'b0 && loaded == 1'b1 && clock_pulse == 1'b1 && (
        (mode == 3'd0 && gate_sampled == 1'b1 && msb_write == 1'b0) ||
        (mode == 3'd1) ||
        (mode[1:0] == 2'd2 && gate_sampled == 1'b1) ||
        (mode == 3'd4 && gate_sampled == 1'b1) ||
        (mode == 3'd5)
    )) ? 1'b1: 1'b0;

    assign enable_double = ~(load) && loaded && clock_pulse && mode[1:0] == 2'd3 && gate_sampled == 1'b1;

    assign bcd_3 = counter[15:12] - 4'd1;
    assign bcd_2 = counter[11:8] - 4'd1;
    assign bcd_1 = counter[7:4] - 4'd1;

    assign counter_minus_1 =
        (bcd == 1'b1 && counter[15:0] == 16'd0)?    16'h9999 :
        (bcd == 1'b1 && counter[11:0] == 12'd0)?    { bcd_3, 12'h999 } :
        (bcd == 1'b1 && counter[7:0] == 8'd0)?      { counter[15:12], bcd_2, 8'h99 } :
        (bcd == 1'b1 && counter[3:0] == 4'd0)?      { counter[15:8], bcd_1, 4'h9 } :
                                                    counter - 16'd1;

    assign counter_minus_2 =
        (bcd == 1'b1 && counter[15:0] == 16'd0)?    16'h9998 :
        (bcd == 1'b1 && counter[11:0] == 12'd0)?    { bcd_3, 12'h998 } :
        (bcd == 1'b1 && counter[7:0] == 8'd0)?      { counter[15:12], bcd_2, 8'h98 } :
        (bcd == 1'b1 && counter[3:0] == 4'd0)?      { counter[15:8], bcd_1, 4'h8 } :
                                                    counter - 16'd2;

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            d_clock <= 1'b0;
            clock_pulse <= 1'b0;
        end else begin
            d_clock <= clock;

            if (d_clock == 1'b1 && clock == 1'b0) begin
                clock_pulse <= 1'b1;
            end else begin
                clock_pulse <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            mode <= 3'd2;
        end else begin
            if (set_control_mode == 1'b1) begin
                mode <= data_in[3:1];
            end
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            bcd <= 1'd0;
        end else begin
            if (set_control_mode == 1'b1) begin
                bcd <= data_in[0];
            end
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            rw_mode <= 2'd1;
        end else begin
            if (set_control_mode == 1'b1) begin
                rw_mode <= data_in[5:4];
            end
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            counter_l <= 8'd0;
            counter_m <= 8'd0;
        end else begin
            if (set_control_mode == 1'b1) begin
                counter_l <= 8'd0;
            end else if (write == 1'b1 && rw_mode == 2'd3 && msb_write == 1'b0) begin
                counter_l <= data_in;
            end else if (write == 1'b1 && rw_mode == 2'd1) begin
                counter_l <= data_in;
            end

            if (set_control_mode == 1'b1) begin
                counter_m <= 8'd0;
            end else if (write == 1'b1 && rw_mode == 2'd3 && msb_write == 1'b1) begin
                counter_m <= data_in;
            end else if (write == 1'b1 && rw_mode == 2'd2) begin
                counter_m <= data_in;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            output_l <= 8'd0;
            output_m <= 8'd0;
        end else begin
            if (latch_count == 1'b1 && ~(output_latched)) begin
                output_l <= counter[7:0];
            end else if (~(output_latched)) begin
                output_l <= counter[7:0];
            end

            if (latch_count == 1'b1 && ~(output_latched))  begin
                output_m <= counter[15:8];
            end else if (~(output_latched)) begin
                output_m <= counter[15:8];
            end
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            output_latched <= 1'b0;
        end else begin
            if (set_control_mode == 1'b1) begin
                output_latched <= 1'b0;
            end else if (latch_count == 1'b1) begin
                output_latched <= 1'b1;
            end else if (read == 1'b1 && (rw_mode != 2'd3 || msb_read == 1'b1)) begin
                output_latched <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            null_counter <= 1'b0;
        end else begin
            if (set_control_mode == 1'b1) begin
                null_counter <= 1'b1;
            end else if (write == 1'b1 && (rw_mode != 2'd3 || msb_write == 1'b1)) begin
                null_counter <= 1'b1;
            end else if (load == 1'b1) begin
                null_counter <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            msb_write <= 1'b0;
        end else begin
            if (set_control_mode == 1'b1) begin
                msb_write <= 1'b0;
            end else if (write == 1'b1 && rw_mode == 2'd3) begin
                msb_write <= ~(msb_write);
            end
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            msb_read <= 1'b0;
        end else begin
            if (set_control_mode == 1'b1) begin
                msb_read <= 1'b0;
            end else if (read == 1'b1 && rw_mode == 2'd3) begin
                msb_read <= ~(msb_read);
            end
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            status <= 8'd0;
            status_latched <= 1'b0;
        end else begin
            if (latch_status == 1'b1 && status_latched == 1'b0) begin
                status <= { counter_out, null_counter, rw_mode, mode, bcd };
            end

            if (set_control_mode == 1'b1) begin
                status_latched <= 1'b0;
            end else if (latch_status == 1'b1) begin
                status_latched <= 1'b1;
            end else if (read == 1'b1) begin
                status_latched <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            gate_last <= 1'b1;
            gate_sampled <= 1'b0;
        end else begin
            gate_last <= gate;

            if (d_clock == 1'b0 && clock == 1'b1) begin
                gate_sampled <= gate;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            trigger <= 1'b0;
            trigger_sampled <= 1'b0;
        end else begin
            if (gate_last == 1'b0 && gate == 1'b1) begin
                trigger <= 1'b1;
            end else if (d_clock == 1'b0 && clock == 1'b1) begin
                trigger <= 1'b0;
            end

            if (d_clock == 1'b0 && clock == 1'b1) begin
                trigger_sampled <= trigger;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            counter_out <= 1'b1;
        end else begin
            if (set_control_mode == 1'b1 && data_in[3:1] == 3'd0)                        counter_out <= 1'b0;
            else if (set_control_mode == 1'b1 && data_in[3:1] == 3'd1)                   counter_out <= 1'b1;
            else if (set_control_mode == 1'b1 && data_in[2:1] == 2'd2)                   counter_out <= 1'b1;
            else if (set_control_mode == 1'b1 && data_in[2:1] == 2'd3)                   counter_out <= 1'b1;
            else if (set_control_mode == 1'b1 && data_in[3:1] == 3'd4)                   counter_out <= 1'b1;
            else if (set_control_mode == 1'b1 && data_in[3:1] == 3'd5)                   counter_out <= 1'b1;

            else if (mode == 3'd0 && write && rw_mode == 2'd3 && msb_write == 1'b0)     counter_out <= 1'b0;
            else if (mode == 3'd0 && written)                                           counter_out <= 1'b0;
            else if (mode == 3'd0 && counter == 16'd1 && enable)                        counter_out <= 1'b1;

            else if (mode == 3'd1 && load)                                              counter_out <= 1'b0;
            else if (mode == 3'd1 && counter == 16'd1 && enable)                        counter_out <= 1'b1;

            else if (mode[1:0] == 2'd2 && gate == 1'b0)                                 counter_out <= 1'b1;
            else if (mode[1:0] == 2'd2 && counter == 16'd2 && enable)                   counter_out <= 1'b0;
            else if (mode[1:0] == 2'd2 && load)                                         counter_out <= 1'b1;

            else if (mode[1:0] == 2'd3 && gate == 1'b0)                                                 counter_out <= 1'b1;
            else if (mode[1:0] == 2'd3 && load && counter == 16'd2 && counter_out && ~(counter_l[0]))   counter_out <= 1'b0;
            else if (mode[1:0] == 2'd3 && load && counter == 16'd0 && counter_out && counter_l[0])      counter_out <= 1'b0;
            else if (mode[1:0] == 2'd3 && load)                                                         counter_out <= 1'b1;

            else if (mode == 3'd4 && load)                                              counter_out <= 1'b1;
            else if (mode == 3'd4 && counter == 16'd2 && enable)                        counter_out <= 1'b0;
            else if (mode == 3'd4 && counter == 16'd1 && enable)                        counter_out <= 1'b1;

            else if (mode == 3'd5 && counter == 16'd2 && enable)                        counter_out <= 1'b0;
            else if (mode == 3'd5 && counter == 16'd1 && enable)                        counter_out <= 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            written <= 1'b0;
        end else begin
            if (set_control_mode == 1'b1) begin
                written <= 1'b0;
            end else if (write == 1'b1 && rw_mode != 2'd3) begin
                written <= 1'b1;
            end else if (write == 1'b1 && rw_mode == 2'd3 && msb_write == 1'b1) begin
                written <= 1'b1;
            end else if (load == 1'b1) begin
                written <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            loaded <= 1'b0;
        end else begin
            if (set_control_mode == 1'b1)
                loaded <= 1'b0;
            else if (load == 1'b1) begin
                loaded <= 1'b1;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (resetn == 1'b0) begin
            counter <= 16'd0;
        end else begin
            if (load_even == 1'b1) begin
                counter <= { counter_m, counter_l[7:1], 1'b0 };
            end else if (load == 1'b1) begin
                counter <= { counter_m, counter_l };
            end else if (enable_double == 1'b1) begin
                counter <= counter_minus_2;
            end else if (enable == 1'b1) begin
                counter <= counter_minus_1;
            end
        end
    end

endmodule
