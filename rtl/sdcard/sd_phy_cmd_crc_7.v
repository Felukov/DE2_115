module sd_phy_cmd_crc_7(data_bit, enable, clk, reset, crc);
    input       data_bit;
    input       enable;
    input       clk;
    input       reset;
    output[6:0] crc;

    reg[6:0] crc;

    wire inv;

    assign inv = data_bit ^ crc[6];

    always @(posedge clk) begin
        if (reset == 1'b1) begin
            crc <= 0;
        end else begin
            if (enable == 1'b1) begin
                crc[6] <= crc[5];
                crc[5] <= crc[4];
                crc[4] <= crc[3];
                crc[3] <= crc[2] ^ inv;
                crc[2] <= crc[1];
                crc[1] <= crc[0];
                crc[0] <= inv;
            end
        end
    end

endmodule
