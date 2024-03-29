
-- Copyright (C) 2022, Konstantin Felukov
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- * Redistributions of source code must retain the above copyright notice, this
--   list of conditions and the following disclaimer.
--
-- * Redistributions in binary form must reproduce the above copyright notice,
--   this list of conditions and the following disclaimer in the documentation
--   and/or other materials provided with the distribution.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
-- FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
-- DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
-- SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
-- CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
-- OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
-- OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
--use std.env.stop;

use work.cpu86_types.all;

entity cpu86_decoder is
    port (
        clk                         : in std_logic;
        resetn                      : in std_logic;

        s_axis_u8_tvalid            : in std_logic;
        s_axis_u8_tready            : out std_logic;
        s_axis_u8_tdata             : in std_logic_vector(7 downto 0);
        s_axis_u8_tuser             : in std_logic_vector(31 downto 0);

        m_axis_instr_tvalid         : out std_logic;
        m_axis_instr_tready         : in std_logic;
        m_axis_instr_tdata          : out slv_decoded_instr_t;
        m_axis_instr_tuser          : out user_t
    );
end entity cpu86_decoder;

architecture rtl of cpu86_decoder is

    constant WIDTH_BIT      : integer := 1;
    constant TO_RM          : std_logic := '0';
    constant TO_REG         : std_logic := '1';

    type byte_pos_t is (
        first_byte,     --0000
        mod_reg_rm,     --0001
        mod_seg_rm,     --0010
        mod_aux_rm,     --0011
        data8,          --0100
        data_s8,        --0101
        data_low,       --0110
        data_high,      --0111
        disp8,          --1001
        disp_low,       --1010
        disp_high,      --1011
        data_ext        --1100
    );

    attribute enum_encoding : string;
    attribute enum_encoding of byte_pos_t : type is "sequential";

    type bytes_chain_t is array (natural range 0 to 5) of byte_pos_t;

    signal u8_tvalid            : std_logic;
    signal u8_tready            : std_logic;
    signal u8_tdata             : std_logic_vector(7 downto 0);
    signal u8_tuser             : std_logic_vector(31 downto 0);
    signal u8_tdata_rm          : std_logic_vector(2 downto 0);
    signal u8_tdata_reg         : std_logic_vector(2 downto 0);

    signal byte_pos_chain       : bytes_chain_t;
    signal instr_tvalid         : std_logic;
    signal instr_tready         : std_logic;
    signal instr_tdata          : decoded_instr_t;
    signal instr_tuser          : user_t;

    signal byte0                : std_logic_vector(7 downto 0);
    signal reg_rm_direction     : std_logic;
    signal dbg_instr_hs_cnt     : integer := 0;

    -- 9 - lock_fl
    -- 8 - lock_sreg
    -- 7 - lock_dreg
    -- 6 - lock_ax
    -- 5 - lock_si
    -- 4 - lock_di
    -- 3 - lock_all
    -- 2 - lock_ds
    -- 1 - lock_es
    -- 0 - lock_sp
    constant    LOCK_NO_LOCK    : std_logic_vector(9 downto 0) := "0000000000";
    constant    LOCK_FL         : std_logic_vector(9 downto 0) := "1000000000";
    constant    LOCK_SREG       : std_logic_vector(9 downto 0) := "0100000000";
    constant    LOCK_DREG       : std_logic_vector(9 downto 0) := "0010000000";
    constant    LOCK_AX         : std_logic_vector(9 downto 0) := "0001000000";
    constant    LOCK_SI         : std_logic_vector(9 downto 0) := "0000100000";
    constant    LOCK_DI         : std_logic_vector(9 downto 0) := "0000010000";
    constant    LOCK_ALL        : std_logic_vector(9 downto 0) := "0000001000";
    constant    LOCK_DS         : std_logic_vector(9 downto 0) := "0000000100";
    constant    LOCK_ES         : std_logic_vector(9 downto 0) := "0000000010";
    constant    LOCK_SP         : std_logic_vector(9 downto 0) := "0000000001";

    -- 11 - wait_ax ;
    -- 10 - wait_bx ;
    --  9 - wait_cx ;
    --  8 - wait_dx ;
    --  7 - wait_bp ;
    --  6 - wait_si ;
    --  5 - wait_di ;
    --  4 - wait_sp ;
    --  3 - wait_ds ;
    --  2 - wait_es ;
    --  1 - wait_ss ;
    --  0 - wait_fl ;

    constant    WAIT_NO_WAIT    : std_logic_vector(11 downto 0) := "000000000000";
    constant    WAIT_PUSHA      : std_logic_vector(11 downto 0) := "111111110000";
    constant    WAIT_AX         : std_logic_vector(11 downto 0) := "100000000000";
    constant    WAIT_BX         : std_logic_vector(11 downto 0) := "010000000000";
    constant    WAIT_CX         : std_logic_vector(11 downto 0) := "001000000000";
    constant    WAIT_DX         : std_logic_vector(11 downto 0) := "000100000000";
    constant    WAIT_BP         : std_logic_vector(11 downto 0) := "000010000000";
    constant    WAIT_SI         : std_logic_vector(11 downto 0) := "000001000000";
    constant    WAIT_DI         : std_logic_vector(11 downto 0) := "000000100000";
    constant    WAIT_SP         : std_logic_vector(11 downto 0) := "000000010000";
    constant    WAIT_DS         : std_logic_vector(11 downto 0) := "000000001000";
    constant    WAIT_ES         : std_logic_vector(11 downto 0) := "000000000100";
    constant    WAIT_SS         : std_logic_vector(11 downto 0) := "000000000010";
    constant    WAIT_FL         : std_logic_vector(11 downto 0) := "000000000001";

begin

    -- i/o assigns
    m_axis_instr_tvalid <= instr_tvalid;
    instr_tready        <= m_axis_instr_tready;
    m_axis_instr_tdata  <= decoded_instr_t_to_slv(instr_tdata);
    m_axis_instr_tuser  <= instr_tuser;

    u8_tvalid           <= s_axis_u8_tvalid;
    s_axis_u8_tready    <= u8_tready;
    u8_tdata            <= s_axis_u8_tdata;
    u8_tuser            <= s_axis_u8_tuser;

    -- assigns
    u8_tdata_rm  <= u8_tdata(2 downto 0);
    u8_tdata_reg <= u8_tdata(5 downto 3);

    u8_tready    <= '1' when instr_tvalid = '0' or (instr_tvalid = '1' and instr_tready = '1') else '0';

    decode_chain_proc : process (clk)
        procedure decode_chain(p0, p1, p2, p3 : byte_pos_t) is begin
            byte_pos_chain(0) <= p0;
            byte_pos_chain(1) <= p1;
            byte_pos_chain(2) <= p2;
            byte_pos_chain(3) <= p3;
        end;

        procedure decode_chain(p0, p1, p2, p3, p4 : byte_pos_t) is begin
            byte_pos_chain(0) <= p0;
            byte_pos_chain(1) <= p1;
            byte_pos_chain(2) <= p2;
            byte_pos_chain(3) <= p3;
            byte_pos_chain(4) <= p4;
        end;

        procedure decode_chain(p0, p1, p2, p3, p4, p5 : byte_pos_t) is begin
            byte_pos_chain(0) <= p0;
            byte_pos_chain(1) <= p1;
            byte_pos_chain(2) <= p2;
            byte_pos_chain(3) <= p3;
            byte_pos_chain(4) <= p4;
            byte_pos_chain(5) <= p5;
        end;

        procedure shift_chain is begin
            byte_pos_chain(0) <= byte_pos_chain(1);
            byte_pos_chain(1) <= byte_pos_chain(2);
            byte_pos_chain(2) <= byte_pos_chain(3);
            byte_pos_chain(3) <= byte_pos_chain(4);
            byte_pos_chain(4) <= byte_pos_chain(5);
        end;

        procedure next_is_new_instruction is begin
            if (byte_pos_chain(1) = first_byte) then
                instr_tvalid <= '1';
            else
                instr_tvalid <= '0';
            end if;
        end;

    begin
        if rising_edge(clk) then
            if resetn = '0' then
                byte_pos_chain(0) <= first_byte;
                instr_tvalid <= '0';
            else

                if (u8_tvalid = '1' and u8_tready = '1') then

                    case byte_pos_chain(0) is
                        when first_byte =>
                            case u8_tdata is

                                when x"00" | x"01" | x"02" | x"03" | x"08" | x"09" | x"0A" | x"0B" | x"10" | x"11" | x"12" | x"13" |
                                     x"18" | x"19" | x"1A" | x"1B" | x"20" | x"21" | x"22" | x"23" | x"28" | x"29" | x"2A" | x"2B" |
                                     x"30" | x"31" | x"32" | x"33" | x"38" | x"39" | x"3A" | x"3B" | x"62" | x"84" | x"85" | x"86" |
                                     x"87" | x"88" | x"89" | x"8A" | x"8B" | x"8D" =>
                                    decode_chain(mod_reg_rm, disp_low, disp_high, first_byte);
                                    instr_tvalid <= '0';

                                when x"D0" | x"D1" | x"D2" | x"D3" | x"D8" | x"D9" | x"DA" | x"DB" |
                                     x"DC" | x"DD" | x"DE" | x"DF" | x"FE" | x"FF" | x"8F" | x"C4" | x"C5" =>
                                    decode_chain(mod_aux_rm, disp_low, disp_high, first_byte);
                                    instr_tvalid <= '0';

                                when x"C0" | x"C1" | x"C6" =>
                                    decode_chain(mod_aux_rm, disp_low, disp_high, data8, first_byte);
                                    instr_tvalid <= '0';

                                when x"F6" =>
                                    decode_chain(mod_aux_rm, disp_low, disp_high, first_byte, first_byte);
                                    instr_tvalid <= '0';

                                when x"6B" =>
                                    decode_chain(mod_reg_rm, disp_low, disp_high, data_s8, first_byte);
                                    instr_tvalid <= '0';

                                when x"C7" =>
                                    decode_chain(mod_aux_rm, disp_low, disp_high, data_low, data_high, first_byte);
                                    instr_tvalid <= '0';

                                when x"F7" =>
                                    decode_chain(mod_aux_rm, disp_low, disp_high, first_byte, first_byte, first_byte);
                                    instr_tvalid <= '0';

                                when x"69" =>
                                    decode_chain(mod_reg_rm, disp_low, disp_high, data_low, data_high, first_byte);
                                    instr_tvalid <= '0';

                                when x"8C" | x"8E" =>
                                    decode_chain(mod_seg_rm, disp_low, disp_high, first_byte);
                                    instr_tvalid <= '0';

                                when x"06" | x"07" | x"0E" | x"16" | x"17" | x"1E" | x"1F" | x"26" | x"2E" | x"2F" | x"C3" |
                                     x"36" | x"37" | x"3E" | x"3F" | x"41" | x"42" | x"43" | x"44" | x"45" | x"46" | x"47" | x"48" |
                                     x"49" | x"4A" | x"4B" | x"4C" | x"4D" | x"4E" | x"4F" | x"50" | x"51" | x"52" | x"53" | x"54" |
                                     x"55" | x"56" | x"57" | x"58" | x"59" | x"5A" | x"5B" | x"5C" | x"5D" | x"5E" | x"5F" | x"60" |
                                     x"61" | x"6C" | x"6D" | x"6E" | x"6F" | x"90" | x"91" | x"F3" | x"F2" |
                                     x"92" | x"93" | x"94" | x"95" | x"96" | x"97" | x"98" | x"99" | x"9B" | x"9C" | x"9D" | x"9E" |
                                     x"9F" | x"A4" | x"A5" | x"A6" | x"A7" | x"AA" | x"AB" | x"AC" | x"AD" | x"AE" | x"AF" | x"CB" |
                                     x"C9" | x"CC" | x"CE" | x"CF" | x"F8" | x"F9" | x"FA" | x"FB" | x"FC" | x"FD" | x"F5" | x"F4" |
                                     x"40" | x"27" | x"D7" | x"EC" | x"ED" | x"F0" | x"EF" | x"EE" =>
                                    byte_pos_chain(0) <= first_byte;
                                    instr_tvalid <= '1';

                                when x"04" | x"0C" | x"14" | x"1C" | x"24" | x"2C" | x"34" | x"3C" | x"6A" | x"A8" | x"B0" | x"B1" |
                                     x"B2" | x"B3" | x"B4" | x"B5" | x"B6" | x"B7" | x"CD" | x"E4" | x"E5" | x"E6" | x"E7" =>
                                    byte_pos_chain(0) <= data8;
                                    byte_pos_chain(1) <= first_byte;
                                    instr_tvalid <= '0';

                                when x"05" | x"0D" | x"15" | x"1D" | x"25" | x"2D" | x"35" | x"3D" | x"68" | x"B8" | x"B9" | x"BA" |
                                     x"BB" | x"BC" | x"BD" | x"BE" | x"BF" | x"C2" | x"CA" | x"A9" =>
                                    byte_pos_chain(0) <= data_low;
                                    byte_pos_chain(1) <= data_high;
                                    byte_pos_chain(2) <= first_byte;
                                    instr_tvalid <= '0';

                                when x"70" | x"71" | x"72" | x"73" | x"74" | x"75" | x"76" | x"77" | x"78" | x"79" | x"7A" | x"7B" |
                                     x"7C" | x"7D" | x"7E" | x"7F" | x"E0" | x"E1" | x"E2" | x"E3" | x"EB" =>
                                    byte_pos_chain(0) <= disp8;
                                    byte_pos_chain(1) <= first_byte;
                                    instr_tvalid <= '0';

                                when x"80" =>
                                    decode_chain(mod_aux_rm, disp_low, disp_high, data8, first_byte);
                                    instr_tvalid <= '0';

                                when x"81" =>
                                    decode_chain(mod_aux_rm, disp_low, disp_high, data_low, data_high, first_byte);
                                    instr_tvalid <= '0';

                                when x"83" =>
                                    decode_chain(mod_aux_rm, disp_low, disp_high, data_s8, first_byte);
                                    instr_tvalid <= '0';

                                when x"C8" =>
                                    decode_chain(data_low, data_high, data_ext, first_byte);
                                    instr_tvalid <= '0';

                                when x"9A" | x"EA" =>
                                    decode_chain(disp_low, disp_high, data_low, data_high, first_byte);
                                    instr_tvalid <= '0';

                                when x"A0" | x"A1" | x"A2" | x"A3" | x"E8" | x"E9" =>
                                    byte_pos_chain(0) <= disp_low;
                                    byte_pos_chain(1) <= disp_high;
                                    byte_pos_chain(2) <= first_byte;
                                    instr_tvalid <= '0';

                                when x"D4" | x"D5" =>
                                    byte_pos_chain(0) <= data8;
                                    byte_pos_chain(1) <= first_byte;
                                    instr_tvalid <= '0';

                                -- invalid opcodes
                                when x"0F" | x"63" | x"64" | x"65" | x"66" | x"67" | x"82" | x"D6" | x"F1" =>
                                    byte_pos_chain(0) <= first_byte;
                                    instr_tvalid <= '1';

                                when others =>
                                    instr_tvalid <= '0';
                                    report "Cannot be here";
                                    --stop;
                            end case;

                        when mod_aux_rm | mod_reg_rm | mod_seg_rm =>

                            case u8_tdata(7 downto 6) is
                                when "11" =>
                                    -- disp_lo and disp_hi are absent
                                    if byte0 = x"F6" and u8_tdata(5 downto 3) = "000" then
                                        byte_pos_chain(0) <= data8;
                                        byte_pos_chain(1) <= first_byte;
                                    elsif byte0 = x"F7" and u8_tdata(5 downto 3) = "000" then
                                        byte_pos_chain(0) <= data_low;
                                        byte_pos_chain(1) <= data_high;
                                        byte_pos_chain(2) <= first_byte;
                                    else
                                        byte_pos_chain(0) <= byte_pos_chain(3);
                                        byte_pos_chain(1) <= byte_pos_chain(4);
                                        byte_pos_chain(2) <= byte_pos_chain(5);
                                        if (byte_pos_chain(3) = first_byte) then
                                            instr_tvalid <= '1';
                                        end if;
                                    end if;

                                when "00" =>
                                    -- DISP = 0
                                    if (u8_tdata(2 downto 0) = "110") then
                                        -- load direct
                                        if byte0 = x"F6" and u8_tdata(5 downto 3) = "000" then
                                            byte_pos_chain(0) <= disp_low;
                                            byte_pos_chain(1) <= disp_high;
                                            byte_pos_chain(2) <= data8;
                                            byte_pos_chain(3) <= first_byte;
                                        elsif byte0 = x"F7" and u8_tdata(5 downto 3) = "000" then
                                            byte_pos_chain(0) <= disp_low;
                                            byte_pos_chain(1) <= disp_high;
                                            byte_pos_chain(2) <= data_low;
                                            byte_pos_chain(3) <= data_high;
                                            byte_pos_chain(4) <= first_byte;
                                        else
                                            byte_pos_chain(0) <= byte_pos_chain(1);
                                            byte_pos_chain(1) <= byte_pos_chain(2);
                                            byte_pos_chain(2) <= byte_pos_chain(3);
                                            byte_pos_chain(3) <= byte_pos_chain(4);
                                            byte_pos_chain(4) <= byte_pos_chain(5);
                                        end if;

                                        instr_tvalid <= '0';
                                    else
                                        -- skip disp
                                        if byte0 = x"F6" and u8_tdata(5 downto 3) = "000" then
                                            byte_pos_chain(0) <= data8;
                                            byte_pos_chain(1) <= first_byte;
                                        elsif byte0 = x"F7" and u8_tdata(5 downto 3) = "000" then
                                            byte_pos_chain(0) <= data_low;
                                            byte_pos_chain(1) <= data_high;
                                            byte_pos_chain(2) <= first_byte;
                                        else
                                            byte_pos_chain(0) <= byte_pos_chain(3);
                                            byte_pos_chain(1) <= byte_pos_chain(4);
                                            byte_pos_chain(2) <= byte_pos_chain(5);
                                            if (byte_pos_chain(3) = first_byte) then
                                                instr_tvalid <= '1';
                                            end if;
                                        end if;
                                    end if;
                                when "01" =>
                                    if byte0 = x"F6" and u8_tdata(5 downto 3) = "000" then
                                        byte_pos_chain(0) <= disp_low;
                                        byte_pos_chain(1) <= data8;
                                        byte_pos_chain(2) <= first_byte;
                                    elsif byte0 = x"F7" and u8_tdata(5 downto 3) = "000" then
                                        byte_pos_chain(0) <= disp_low;
                                        byte_pos_chain(1) <= data_low;
                                        byte_pos_chain(2) <= data_high;
                                        byte_pos_chain(3) <= first_byte;
                                    else
                                        -- load disp_lo
                                        byte_pos_chain(0) <= byte_pos_chain(1);
                                        -- and skip disp_high
                                        byte_pos_chain(1) <= byte_pos_chain(3);
                                        byte_pos_chain(2) <= byte_pos_chain(4);
                                        byte_pos_chain(3) <= byte_pos_chain(5);
                                    end if;

                                    instr_tvalid <= '0';

                                when "10" =>
                                    if byte0 = x"F6" and u8_tdata(5 downto 3) = "000" then
                                        byte_pos_chain(0) <= disp_low;
                                        byte_pos_chain(1) <= disp_high;
                                        byte_pos_chain(2) <= data8;
                                        byte_pos_chain(3) <= first_byte;
                                    elsif byte0 = x"F7" and u8_tdata(5 downto 3) = "000" then
                                        byte_pos_chain(0) <= disp_low;
                                        byte_pos_chain(1) <= disp_high;
                                        byte_pos_chain(2) <= data_low;
                                        byte_pos_chain(3) <= data_high;
                                        byte_pos_chain(4) <= first_byte;
                                    else
                                        -- load disp_lo, disp_hi
                                        shift_chain;
                                    end if;

                                    instr_tvalid <= '0';
                                when others =>
                                    null;

                            end case;

                        when data8      => shift_chain; next_is_new_instruction;
                        when data_s8    => shift_chain; next_is_new_instruction;
                        when data_low   => shift_chain; next_is_new_instruction;
                        when data_high  => shift_chain; next_is_new_instruction;
                        when disp8      => shift_chain; next_is_new_instruction;
                        when disp_low   => shift_chain; next_is_new_instruction;
                        when disp_high  => shift_chain; next_is_new_instruction;
                        when data_ext   => shift_chain; next_is_new_instruction;
                        when others     =>
                            instr_tvalid <= '0';
                            report "Cannot be here";
                            --stop;

                    end case;

                elsif instr_tready = '1' then
                    instr_tvalid <= '0';
                end if;

            end if;

            if (u8_tvalid = '1' and u8_tready = '1' and byte_pos_chain(0) = first_byte) then
                byte0 <= u8_tdata;
            end if;

            if (u8_tvalid = '1' and u8_tready = '1' and byte_pos_chain(0) = first_byte) then
                instr_tuser(USER_T_IP) <= u8_tuser(15 downto 0);
            end if;

            if (u8_tvalid = '1' and u8_tready = '1' and byte_pos_chain(0) = first_byte) then
                instr_tuser(USER_T_CS) <= u8_tuser(31 downto 16);
            end if;

            if (u8_tvalid = '1' and u8_tready = '1' and byte_pos_chain(0) = first_byte) then
                instr_tuser(USER_T_IP_NEXT) <= std_logic_vector(unsigned(u8_tuser(15 downto 0)) + to_unsigned(1, 16));
            elsif (u8_tvalid = '1' and u8_tready = '1') then
                instr_tuser(USER_T_IP_NEXT) <= std_logic_vector(unsigned(instr_tuser(15 downto 0)) + to_unsigned(1, 16));
            end if;

        end if;
    end process;

    direction_proc : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                reg_rm_direction <= TO_REG;
            else
                if (u8_tvalid = '1' and u8_tready = '1' and byte_pos_chain(0) = first_byte) then

                    case u8_tdata is
                        when x"00" | x"01" | x"08" | x"09" | x"10" | x"11" | x"18" | x"19" |
                             x"20" | x"21" | x"28" | x"29" | x"30" | x"31" | x"38" | x"39" |
                             x"88" | x"89" | x"8C" =>
                            reg_rm_direction <= TO_RM;
                        when others =>
                            reg_rm_direction <= TO_REG;
                    end case;

                end if;
            end if;
        end if;
    end process;

    process (clk)
        procedure set_undefined is
        begin
            instr_tdata.op           <= BCDU;
            instr_tdata.code         <= (others => 'U');
            instr_tdata.w            <= 'U';
            instr_tdata.dir          <= M2M;
            instr_tdata.ea           <= XLAT;
            instr_tdata.dreg         <= ZERO;
            instr_tdata.dmask        <= (others => 'U');
            instr_tdata.sreg         <= ZERO;
            instr_tdata.smask        <= (others => 'U');
            instr_tdata.data         <= (others => 'U');
            instr_tdata.disp         <= (others => 'U');
            instr_tdata.fl           <= TOGGLE;
            instr_tdata.data_ex      <= (others => 'U');
            instr_tdata.bpu_taken    <= 'U';
            instr_tdata.bpu_first    <= 'U';
            instr_tdata.bpu_taken_cs <= (others => 'U');
            instr_tdata.bpu_taken_ip <= (others => 'U');
            instr_tdata.wait_ax      <= 'U';
            instr_tdata.wait_bx      <= 'U';
            instr_tdata.wait_cx      <= 'U';
            instr_tdata.wait_dx      <= 'U';
            instr_tdata.wait_bp      <= 'U';
            instr_tdata.wait_si      <= 'U';
            instr_tdata.wait_di      <= 'U';
            instr_tdata.wait_sp      <= 'U';
            instr_tdata.wait_ds      <= 'U';
            instr_tdata.wait_es      <= 'U';
            instr_tdata.wait_ss      <= 'U';
            instr_tdata.wait_fl      <= 'U';
            instr_tdata.lock_fl      <= 'U';
            instr_tdata.lock_sreg    <= 'U';
            instr_tdata.lock_dreg    <= 'U';
            instr_tdata.lock_ax      <= 'U';
            instr_tdata.lock_sp      <= 'U';
            instr_tdata.lock_si      <= 'U';
            instr_tdata.lock_di      <= 'U';
            instr_tdata.lock_ds      <= 'U';
            instr_tdata.lock_es      <= 'U';
            instr_tdata.lock_all     <= 'U';
        end procedure;

        procedure set_lock (val : std_logic_vector(9 downto 0)) is begin
            instr_tdata.lock_fl   <= val(9);
            instr_tdata.lock_sreg <= val(8);
            instr_tdata.lock_dreg <= val(7);
            instr_tdata.lock_ax   <= val(6);
            instr_tdata.lock_si   <= val(5);
            instr_tdata.lock_di   <= val(4);
            instr_tdata.lock_all  <= val(3);
            instr_tdata.lock_ds   <= val(2);
            instr_tdata.lock_es   <= val(1);
            instr_tdata.lock_sp   <= val(0);
        end;

        procedure upd_lock (val : std_logic_vector(9 downto 0)) is begin
            instr_tdata.lock_fl   <= instr_tdata.lock_fl   or val(9);
            instr_tdata.lock_sreg <= instr_tdata.lock_sreg or val(8);
            instr_tdata.lock_dreg <= instr_tdata.lock_dreg or val(7);
            instr_tdata.lock_ax   <= instr_tdata.lock_ax   or val(6);
            instr_tdata.lock_si   <= instr_tdata.lock_si   or val(5);
            instr_tdata.lock_di   <= instr_tdata.lock_di   or val(4);
            instr_tdata.lock_all  <= instr_tdata.lock_all  or val(3);
            instr_tdata.lock_ds   <= instr_tdata.lock_ds   or val(2);
            instr_tdata.lock_es   <= instr_tdata.lock_es   or val(1);
            instr_tdata.lock_sp   <= instr_tdata.lock_sp   or val(0);
        end;

        procedure set_wait (val : std_logic_vector(11 downto 0)) is begin
            instr_tdata.wait_ax <= val(11);
            instr_tdata.wait_bx <= val(10);
            instr_tdata.wait_cx <= val(9);
            instr_tdata.wait_dx <= val(8);
            instr_tdata.wait_bp <= val(7);
            instr_tdata.wait_si <= val(6);
            instr_tdata.wait_di <= val(5);
            instr_tdata.wait_sp <= val(4);
            instr_tdata.wait_ds <= val(3);
            instr_tdata.wait_es <= val(2);
            instr_tdata.wait_ss <= val(1);
            instr_tdata.wait_fl <= val(0);
        end;

        procedure set_op (op : op_t) is begin
            instr_tdata.op <= op;
        end procedure;

        procedure set_op (op : op_t; code : std_logic_vector) is begin
            instr_tdata.op <= op;
            instr_tdata.code <= code;
        end procedure;

        procedure set_op (op : op_t; code : std_logic_vector; w : std_logic) is begin
            instr_tdata.op <= op;
            instr_tdata.code <= code;
            instr_tdata.w <= w;
        end procedure;

        procedure set_op (op : op_t; code : std_logic_vector; w : std_logic; lock_vector : std_logic_vector(9 downto 0)) is begin
            instr_tdata.op <= op;
            instr_tdata.code <= code;
            instr_tdata.w <= w;
            set_lock(lock_vector);
        end procedure;

        procedure set_op (op : op_t; code : std_logic_vector; w : std_logic;
            lock_vector : std_logic_vector(9 downto 0); wait_vector : std_logic_vector(11 downto 0)) is
        begin
            instr_tdata.op <= op;
            instr_tdata.code <= code;
            instr_tdata.w <= w;
            set_lock(lock_vector);
            set_wait(wait_vector);
        end procedure;

        procedure set_stack_op(code : std_logic_vector; lock_vector : std_logic_vector(9 downto 0)) is begin
            instr_tdata.op <= STACKU;
            instr_tdata.code <= code;
            instr_tdata.w <= '1';
            set_lock(lock_vector);
        end procedure;

        procedure set_stack_op(code : std_logic_vector; lock_vector : std_logic_vector(9 downto 0);
            wait_vector : std_logic_vector(11 downto 0)) is
        begin
            instr_tdata.op <= STACKU;
            instr_tdata.code <= code;
            instr_tdata.w <= '1';
            set_lock(lock_vector);
            set_wait(wait_vector);
        end procedure;

        procedure set_flag_op(flag : integer; action : fl_action_t;
            lock_vector : std_logic_vector(9 downto 0); wait_vector : std_logic_vector(11 downto 0)) is
        begin
            instr_tdata.op <= SET_FLAG;
            instr_tdata.code <= std_logic_vector(to_unsigned(flag, 4));
            instr_tdata.fl <= action;
            set_lock(lock_vector);
            set_wait(wait_vector);
        end procedure;

        procedure no_lock is begin
            instr_tdata.lock_fl <= '0';
            instr_tdata.lock_sreg <= '0';
            instr_tdata.lock_dreg <= '0';
            instr_tdata.lock_ax <= '0';
            instr_tdata.lock_si <= '0';
            instr_tdata.lock_di <= '0';
            instr_tdata.lock_all <= '0';
            instr_tdata.lock_ds <= '0';
            instr_tdata.lock_es <= '0';
            instr_tdata.lock_sp <= '0';
        end;

        procedure no_wait is begin
            instr_tdata.wait_ax <= '0';
            instr_tdata.wait_bx <= '0';
            instr_tdata.wait_cx <= '0';
            instr_tdata.wait_dx <= '0';
            instr_tdata.wait_bp <= '0';
            instr_tdata.wait_si <= '0';
            instr_tdata.wait_di <= '0';
            instr_tdata.wait_sp <= '0';
            instr_tdata.wait_ds <= '0';
            instr_tdata.wait_es <= '0';
            instr_tdata.wait_ss <= '0';
            instr_tdata.wait_fl <= '0';
        end;

        procedure wait_rm is begin
            if (u8_tdata(7 downto 6) = "11") then
                if (instr_tdata.w = '0') then
                    case u8_tdata_rm is
                        when "000" => instr_tdata.wait_ax <= '1';
                        when "001" => instr_tdata.wait_cx <= '1';
                        when "010" => instr_tdata.wait_dx <= '1';
                        when "011" => instr_tdata.wait_bx <= '1';
                        when "100" => instr_tdata.wait_ax <= '1';
                        when "101" => instr_tdata.wait_cx <= '1';
                        when "110" => instr_tdata.wait_dx <= '1';
                        when "111" => instr_tdata.wait_bx <= '1';
                        when others => null;
                    end case;
                else
                    case u8_tdata_rm is
                        when "000" => instr_tdata.wait_ax <= '1';
                        when "001" => instr_tdata.wait_cx <= '1';
                        when "010" => instr_tdata.wait_dx <= '1';
                        when "011" => instr_tdata.wait_bx <= '1';
                        when "100" => instr_tdata.wait_sp <= '1';
                        when "101" => instr_tdata.wait_bp <= '1';
                        when "110" => instr_tdata.wait_si <= '1';
                        when "111" => instr_tdata.wait_di <= '1';
                        when others => null;
                    end case;
                end if;
            else
                case u8_tdata_rm is
                    when "000" => instr_tdata.wait_bx <= '1'; instr_tdata.wait_si <= '1'; instr_tdata.wait_ds <= '1';
                    when "001" => instr_tdata.wait_bx <= '1'; instr_tdata.wait_di <= '1'; instr_tdata.wait_ds <= '1';
                    when "010" => instr_tdata.wait_bp <= '1'; instr_tdata.wait_si <= '1'; instr_tdata.wait_ss <= '1';
                    when "011" => instr_tdata.wait_bp <= '1'; instr_tdata.wait_di <= '1'; instr_tdata.wait_ss <= '1';
                    when "100" => instr_tdata.wait_si <= '1'; instr_tdata.wait_ds <= '1';
                    when "101" => instr_tdata.wait_di <= '1'; instr_tdata.wait_ds <= '1';
                    when "110" =>
                        if (u8_tdata(7 downto 6) /= "00") then
                            instr_tdata.wait_bp <= '1';
                            instr_tdata.wait_ss <= '1';
                        else
                            instr_tdata.wait_ds <= '1';
                        end if;
                    when "111" => instr_tdata.wait_bx <= '1'; instr_tdata.wait_ds <= '1';
                    when others => null;
                end case;
            end if;
        end;

        procedure decode_op_first_byte is begin
            case u8_tdata is
                -- ALU
                when x"00" => set_op(ALU, ALU_OP_ADD, '0', LOCK_FL,            WAIT_NO_WAIT);
                when x"01" => set_op(ALU, ALU_OP_ADD, '1', LOCK_FL,            WAIT_NO_WAIT);
                when x"02" => set_op(ALU, ALU_OP_ADD, '0', LOCK_FL,            WAIT_NO_WAIT);
                when x"03" => set_op(ALU, ALU_OP_ADD, '1', LOCK_FL,            WAIT_NO_WAIT);
                when x"04" => set_op(ALU, ALU_OP_ADD, '0', LOCK_AX or LOCK_FL, WAIT_AX);
                when x"05" => set_op(ALU, ALU_OP_ADD, '1', LOCK_AX or LOCK_FL, WAIT_AX);

                when x"08" => set_op(ALU, ALU_OP_OR,  '0', LOCK_FL,            WAIT_NO_WAIT);
                when x"09" => set_op(ALU, ALU_OP_OR,  '1', LOCK_FL,            WAIT_NO_WAIT);
                when x"0A" => set_op(ALU, ALU_OP_OR,  '0', LOCK_FL,            WAIT_NO_WAIT);
                when x"0B" => set_op(ALU, ALU_OP_OR,  '1', LOCK_FL,            WAIT_NO_WAIT);
                when x"0C" => set_op(ALU, ALU_OP_OR,  '0', LOCK_AX or LOCK_FL, WAIT_AX);
                when x"0D" => set_op(ALU, ALU_OP_OR,  '1', LOCK_AX or LOCK_FL, WAIT_AX);

                when x"10" => set_op(ALU, ALU_OP_ADC, '0', LOCK_FL,            WAIT_FL);
                when x"11" => set_op(ALU, ALU_OP_ADC, '1', LOCK_FL,            WAIT_FL);
                when x"12" => set_op(ALU, ALU_OP_ADC, '0', LOCK_FL,            WAIT_FL);
                when x"13" => set_op(ALU, ALU_OP_ADC, '1', LOCK_FL,            WAIT_FL);
                when x"14" => set_op(ALU, ALU_OP_ADC, '0', LOCK_AX or LOCK_FL, WAIT_FL or WAIT_AX);
                when x"15" => set_op(ALU, ALU_OP_ADC, '1', LOCK_AX or LOCK_FL, WAIT_FL or WAIT_AX);

                when x"18" => set_op(ALU, ALU_OP_SBB, '0', LOCK_FL,            WAIT_FL);
                when x"19" => set_op(ALU, ALU_OP_SBB, '1', LOCK_FL,            WAIT_FL);
                when x"1A" => set_op(ALU, ALU_OP_SBB, '0', LOCK_FL,            WAIT_FL);
                when x"1B" => set_op(ALU, ALU_OP_SBB, '1', LOCK_FL,            WAIT_FL);
                when x"1C" => set_op(ALU, ALU_OP_SBB, '0', LOCK_AX or LOCK_FL, WAIT_FL or WAIT_AX);
                when x"1D" => set_op(ALU, ALU_OP_SBB, '1', LOCK_AX or LOCK_FL, WAIT_FL or WAIT_AX);

                when x"20" => set_op(ALU, ALU_OP_AND, '0', LOCK_FL,            WAIT_NO_WAIT);
                when x"21" => set_op(ALU, ALU_OP_AND, '1', LOCK_FL,            WAIT_NO_WAIT);
                when x"22" => set_op(ALU, ALU_OP_AND, '0', LOCK_FL,            WAIT_NO_WAIT);
                when x"23" => set_op(ALU, ALU_OP_AND, '1', LOCK_FL,            WAIT_NO_WAIT);
                when x"24" => set_op(ALU, ALU_OP_AND, '0', LOCK_AX or LOCK_FL, WAIT_AX);
                when x"25" => set_op(ALU, ALU_OP_AND, '1', LOCK_AX or LOCK_FL, WAIT_AX);

                when x"28" => set_op(ALU, ALU_OP_SUB, '0', LOCK_FL,            WAIT_NO_WAIT);
                when x"29" => set_op(ALU, ALU_OP_SUB, '1', LOCK_FL,            WAIT_NO_WAIT);
                when x"2A" => set_op(ALU, ALU_OP_SUB, '0', LOCK_FL,            WAIT_NO_WAIT);
                when x"2B" => set_op(ALU, ALU_OP_SUB, '1', LOCK_FL,            WAIT_NO_WAIT);
                when x"2C" => set_op(ALU, ALU_OP_SUB, '0', LOCK_AX or LOCK_FL, WAIT_AX);
                when x"2D" => set_op(ALU, ALU_OP_SUB, '1', LOCK_AX or LOCK_FL, WAIT_AX);

                when x"30" => set_op(ALU, ALU_OP_XOR, '0', LOCK_FL,            WAIT_NO_WAIT);
                when x"31" => set_op(ALU, ALU_OP_XOR, '1', LOCK_FL,            WAIT_NO_WAIT);
                when x"32" => set_op(ALU, ALU_OP_XOR, '0', LOCK_FL,            WAIT_NO_WAIT);
                when x"33" => set_op(ALU, ALU_OP_XOR, '1', LOCK_FL,            WAIT_NO_WAIT);
                when x"34" => set_op(ALU, ALU_OP_XOR, '0', LOCK_AX or LOCK_FL, WAIT_AX);
                when x"35" => set_op(ALU, ALU_OP_XOR, '1', LOCK_AX or LOCK_FL, WAIT_AX);

                when x"38" => set_op(ALU, ALU_OP_CMP, '0', LOCK_FL,            WAIT_NO_WAIT);
                when x"39" => set_op(ALU, ALU_OP_CMP, '1', LOCK_FL,            WAIT_NO_WAIT);
                when x"3A" => set_op(ALU, ALU_OP_CMP, '0', LOCK_FL,            WAIT_NO_WAIT);
                when x"3B" => set_op(ALU, ALU_OP_CMP, '1', LOCK_FL,            WAIT_NO_WAIT);
                when x"3C" => set_op(ALU, ALU_OP_CMP, '0', LOCK_AX or LOCK_FL, WAIT_AX);
                when x"3D" => set_op(ALU, ALU_OP_CMP, '1', LOCK_AX or LOCK_FL, WAIT_AX);

                when x"40" => set_op(ALU, ALU_OP_INC, '1', LOCK_DREG or LOCK_FL, WAIT_AX);
                when x"41" => set_op(ALU, ALU_OP_INC, '1', LOCK_DREG or LOCK_FL, WAIT_CX);
                when x"42" => set_op(ALU, ALU_OP_INC, '1', LOCK_DREG or LOCK_FL, WAIT_DX);
                when x"43" => set_op(ALU, ALU_OP_INC, '1', LOCK_DREG or LOCK_FL, WAIT_BX);
                when x"44" => set_op(ALU, ALU_OP_INC, '1', LOCK_DREG or LOCK_FL, WAIT_SP);
                when x"45" => set_op(ALU, ALU_OP_INC, '1', LOCK_DREG or LOCK_FL, WAIT_BP);
                when x"46" => set_op(ALU, ALU_OP_INC, '1', LOCK_DREG or LOCK_FL, WAIT_SI);
                when x"47" => set_op(ALU, ALU_OP_INC, '1', LOCK_DREG or LOCK_FL, WAIT_DI);

                when x"48" => set_op(ALU, ALU_OP_DEC, '1', LOCK_DREG or LOCK_FL, WAIT_AX);
                when x"49" => set_op(ALU, ALU_OP_DEC, '1', LOCK_DREG or LOCK_FL, WAIT_CX);
                when x"4A" => set_op(ALU, ALU_OP_DEC, '1', LOCK_DREG or LOCK_FL, WAIT_DX);
                when x"4B" => set_op(ALU, ALU_OP_DEC, '1', LOCK_DREG or LOCK_FL, WAIT_BX);
                when x"4C" => set_op(ALU, ALU_OP_DEC, '1', LOCK_DREG or LOCK_FL, WAIT_SP);
                when x"4D" => set_op(ALU, ALU_OP_DEC, '1', LOCK_DREG or LOCK_FL, WAIT_BP);
                when x"4E" => set_op(ALU, ALU_OP_DEC, '1', LOCK_DREG or LOCK_FL, WAIT_SI);
                when x"4F" => set_op(ALU, ALU_OP_DEC, '1', LOCK_DREG or LOCK_FL, WAIT_DI);

                when x"84" => set_op(ALU, ALU_OP_TST, '0', LOCK_FL, WAIT_NO_WAIT);
                when x"85" => set_op(ALU, ALU_OP_TST, '1', LOCK_FL, WAIT_NO_WAIT);

                when x"A8" => set_op(ALU, ALU_OP_TST, '0', LOCK_AX or LOCK_FL, WAIT_AX);
                when x"A9" => set_op(ALU, ALU_OP_TST, '1', LOCK_AX or LOCK_FL, WAIT_AX);

                -- MUL
                when x"69" => set_op(MULU, IMUL_RR,   '1', LOCK_FL, WAIT_NO_WAIT);
                when x"6B" => set_op(MULU, IMUL_RR,   '1', LOCK_FL, WAIT_NO_WAIT);

                -- BCD
                when x"27" => set_op(BCDU, BCDU_DAA,  '0', LOCK_AX or LOCK_FL, WAIT_AX or WAIT_FL);
                when x"2F" => set_op(BCDU, BCDU_DAS,  '0', LOCK_AX or LOCK_FL, WAIT_AX or WAIT_FL);
                when x"37" => set_op(BCDU, BCDU_AAA,  '0', LOCK_AX or LOCK_FL, WAIT_AX or WAIT_FL);
                when x"3F" => set_op(BCDU, BCDU_AAS,  '0', LOCK_AX or LOCK_FL, WAIT_AX or WAIT_FL);
                when x"D4" => set_op(DIVU, DIVU_AAM,  '0', LOCK_AX or LOCK_FL, WAIT_AX);
                when x"D5" => set_op(BCDU, BCDU_AAD,  '0', LOCK_AX or LOCK_FL, WAIT_AX);

                -- STACK
                when x"06" => set_stack_op(STACKU_PUSHR,   LOCK_SP,              WAIT_SS or WAIT_SP or WAIT_ES);
                when x"07" => set_stack_op(STACKU_POPR,    LOCK_DREG or LOCK_SP, WAIT_SS or WAIT_SP or WAIT_ES);
                when x"0E" => set_stack_op(STACKU_PUSHR,   LOCK_SP,              WAIT_SS or WAIT_SP);
                when x"16" => set_stack_op(STACKU_PUSHR,   LOCK_SP,              WAIT_SS or WAIT_SP);
                when x"17" => set_stack_op(STACKU_POPR,    LOCK_DREG or LOCK_SP, WAIT_SS or WAIT_SP);
                when x"1E" => set_stack_op(STACKU_PUSHR,   LOCK_SP,              WAIT_SS or WAIT_SP or WAIT_DS);
                when x"1F" => set_stack_op(STACKU_POPR,    LOCK_DREG or LOCK_SP, WAIT_SS or WAIT_SP or WAIT_DS);

                when x"50" => set_stack_op(STACKU_PUSHR,   LOCK_SP,              WAIT_SS or WAIT_SP or WAIT_AX);
                when x"51" => set_stack_op(STACKU_PUSHR,   LOCK_SP,              WAIT_SS or WAIT_SP or WAIT_CX);
                when x"52" => set_stack_op(STACKU_PUSHR,   LOCK_SP,              WAIT_SS or WAIT_SP or WAIT_DX);
                when x"53" => set_stack_op(STACKU_PUSHR,   LOCK_SP,              WAIT_SS or WAIT_SP or WAIT_BX);
                when x"54" => set_stack_op(STACKU_PUSHR,   LOCK_SP,              WAIT_SS or WAIT_SP or WAIT_SP);
                when x"55" => set_stack_op(STACKU_PUSHR,   LOCK_SP,              WAIT_SS or WAIT_SP or WAIT_BP);
                when x"56" => set_stack_op(STACKU_PUSHR,   LOCK_SP,              WAIT_SS or WAIT_SP or WAIT_SI);
                when x"57" => set_stack_op(STACKU_PUSHR,   LOCK_SP,              WAIT_SS or WAIT_SP or WAIT_DI);

                when x"58" => set_stack_op(STACKU_POPR,    LOCK_SP or LOCK_DREG, WAIT_SS or WAIT_SP or WAIT_AX);
                when x"59" => set_stack_op(STACKU_POPR,    LOCK_SP or LOCK_DREG, WAIT_SS or WAIT_SP or WAIT_CX);
                when x"5A" => set_stack_op(STACKU_POPR,    LOCK_SP or LOCK_DREG, WAIT_SS or WAIT_SP or WAIT_DX);
                when x"5B" => set_stack_op(STACKU_POPR,    LOCK_SP or LOCK_DREG, WAIT_SS or WAIT_SP or WAIT_BX);
                when x"5C" => set_stack_op(STACKU_POPR,    LOCK_SP or LOCK_DREG, WAIT_SS or WAIT_SP or WAIT_SP);
                when x"5D" => set_stack_op(STACKU_POPR,    LOCK_SP or LOCK_DREG, WAIT_SS or WAIT_SP or WAIT_BP);
                when x"5E" => set_stack_op(STACKU_POPR,    LOCK_SP or LOCK_DREG, WAIT_SS or WAIT_SP or WAIT_SI);
                when x"5F" => set_stack_op(STACKU_POPR,    LOCK_SP or LOCK_DREG, WAIT_SS or WAIT_SP or WAIT_DI);

                when x"60" => set_stack_op(STACKU_PUSHA,   LOCK_SP,              WAIT_SS or WAIT_SP or WAIT_PUSHA);
                when x"61" => set_stack_op(STACKU_POPA,    LOCK_ALL,             WAIT_SS or WAIT_SP);
                when x"68" => set_stack_op(STACKU_PUSHI,   LOCK_SP,              WAIT_SS or WAIT_SP);
                when x"6A" => set_stack_op(STACKU_PUSHI,   LOCK_SP,              WAIT_SS or WAIT_SP);

                when x"9C" => set_stack_op(STACKU_PUSHR,   LOCK_SP,              WAIT_SS or WAIT_SP or WAIT_FL);
                when x"9D" => set_stack_op(STACKU_POPR,    LOCK_SP or LOCK_DREG, WAIT_SS or WAIT_SP or WAIT_FL);

                when x"C8" => set_stack_op(STACKU_ENTER,   LOCK_SP or LOCK_DREG, WAIT_SS or WAIT_SP or WAIT_BP);
                when x"C9" => set_stack_op(STACKU_LEAVE,   LOCK_SP or LOCK_DREG, WAIT_SS or WAIT_SP or WAIT_BP);

                -- CALL
                when x"9A" => set_op(JCALL, CALL_PTR16_16, '1', LOCK_SP, WAIT_SS or WAIT_SP);
                when x"E8" => set_op(JCALL, CALL_REL16,    '1', LOCK_SP, WAIT_SS or WAIT_SP);

                -- RET
                when x"C2" => set_op(RET, RET_NEAR_IMM16, '1', LOCK_SP, WAIT_SS or WAIT_SP);
                when x"C3" => set_op(RET, RET_NEAR,       '1', LOCK_SP, WAIT_SS or WAIT_SP);
                when x"CA" => set_op(RET, RET_FAR_IMM16,  '1', LOCK_SP, WAIT_SS or WAIT_SP);
                when x"CB" => set_op(RET, RET_FAR,        '1', LOCK_SP, WAIT_SS or WAIT_SP);

                --XCHG
                when x"86" => set_op(XCHG, "0000",    '0', LOCK_NO_LOCK,           WAIT_NO_WAIT);
                when x"87" => set_op(XCHG, "0000",    '1', LOCK_NO_LOCK,           WAIT_NO_WAIT);
                when x"90" => set_op(XCHG, "0000",    '1', LOCK_SREG or LOCK_DREG, WAIT_AX);
                when x"91" => set_op(XCHG, "0000",    '1', LOCK_SREG or LOCK_DREG, WAIT_AX or WAIT_CX);
                when x"92" => set_op(XCHG, "0000",    '1', LOCK_SREG or LOCK_DREG, WAIT_AX or WAIT_DX);
                when x"93" => set_op(XCHG, "0000",    '1', LOCK_SREG or LOCK_DREG, WAIT_AX or WAIT_BX);
                when x"94" => set_op(XCHG, "0000",    '1', LOCK_SREG or LOCK_DREG, WAIT_AX or WAIT_SP);
                when x"95" => set_op(XCHG, "0000",    '1', LOCK_SREG or LOCK_DREG, WAIT_AX or WAIT_BP);
                when x"96" => set_op(XCHG, "0000",    '1', LOCK_SREG or LOCK_DREG, WAIT_AX or WAIT_SI);
                when x"97" => set_op(XCHG, "0000",    '1', LOCK_SREG or LOCK_DREG, WAIT_AX or WAIT_DI);

                --MOV
                when x"88" => set_op(MOVU, "0000",    '0', LOCK_NO_LOCK, WAIT_NO_WAIT);
                when x"89" => set_op(MOVU, "0000",    '1', LOCK_NO_LOCK, WAIT_NO_WAIT);
                when x"8A" => set_op(MOVU, "0000",    '0', LOCK_NO_LOCK, WAIT_NO_WAIT);
                when x"8B" => set_op(MOVU, "0000",    '1', LOCK_NO_LOCK, WAIT_NO_WAIT);
                when x"8C" => set_op(MOVU, "0000",    '1', LOCK_NO_LOCK, WAIT_NO_WAIT);
                when x"8E" => set_op(MOVU, "0000",    '1', LOCK_NO_LOCK, WAIT_NO_WAIT);

                when x"9E" => set_op(MOVU, "0000",    '0', LOCK_DREG,    WAIT_AX or WAIT_FL);
                when x"9F" => set_op(MOVU, "0000",    '0', LOCK_DREG,    WAIT_AX or WAIT_FL);

                when x"A0" => set_op(MOVU, "0000",    '0', LOCK_DREG,    WAIT_AX or WAIT_DS);
                when x"A1" => set_op(MOVU, "0000",    '1', LOCK_DREG,    WAIT_AX or WAIT_DS);
                when x"A2" => set_op(MOVU, "0000",    '0', LOCK_NO_LOCK, WAIT_AX or WAIT_DS);
                when x"A3" => set_op(MOVU, "0000",    '1', LOCK_NO_LOCK, WAIT_AX or WAIT_DS);

                when x"B0" => set_op(MOVU, "0000",    '0', LOCK_DREG,    WAIT_AX);
                when x"B1" => set_op(MOVU, "0000",    '0', LOCK_DREG,    WAIT_CX);
                when x"B2" => set_op(MOVU, "0000",    '0', LOCK_DREG,    WAIT_DX);
                when x"B3" => set_op(MOVU, "0000",    '0', LOCK_DREG,    WAIT_BX);
                when x"B4" => set_op(MOVU, "0000",    '0', LOCK_DREG,    WAIT_AX);
                when x"B5" => set_op(MOVU, "0000",    '0', LOCK_DREG,    WAIT_CX);
                when x"B6" => set_op(MOVU, "0000",    '0', LOCK_DREG,    WAIT_DX);
                when x"B7" => set_op(MOVU, "0000",    '0', LOCK_DREG,    WAIT_BX);
                when x"B8" => set_op(MOVU, "0000",    '1', LOCK_DREG,    WAIT_AX);
                when x"B9" => set_op(MOVU, "0000",    '1', LOCK_DREG,    WAIT_CX);
                when x"BA" => set_op(MOVU, "0000",    '1', LOCK_DREG,    WAIT_DX);
                when x"BB" => set_op(MOVU, "0000",    '1', LOCK_DREG,    WAIT_BX);
                when x"BC" => set_op(MOVU, "0000",    '1', LOCK_DREG,    WAIT_SP);
                when x"BD" => set_op(MOVU, "0000",    '1', LOCK_DREG,    WAIT_BP);
                when x"BE" => set_op(MOVU, "0000",    '1', LOCK_DREG,    WAIT_SI);
                when x"BF" => set_op(MOVU, "0000",    '1', LOCK_DREG,    WAIT_DI);

                when x"C6" => set_op(MOVU, "0000",    '0', LOCK_NO_LOCK, WAIT_NO_WAIT);
                when x"C7" => set_op(MOVU, "0000",    '1', LOCK_NO_LOCK, WAIT_NO_WAIT);

                --
                when x"80" => no_lock; no_wait; instr_tdata.w <= '0';
                when x"81" => no_lock; no_wait; instr_tdata.w <= '1';
                when x"83" => no_lock; no_wait; instr_tdata.w <= '1';
                when x"8F" => no_lock; no_wait; instr_tdata.w <= '1';
                when x"C0" => no_lock; no_wait; instr_tdata.w <= '0';
                when x"C1" => no_lock; no_wait; instr_tdata.w <= '1';
                when x"D0" => no_lock; no_wait; instr_tdata.w <= '0';
                when x"D1" => no_lock; no_wait; instr_tdata.w <= '1';
                when x"D2" => no_lock; no_wait; instr_tdata.w <= '0';
                when x"D3" => no_lock; no_wait; instr_tdata.w <= '1';
                when x"F6" => no_lock; no_wait; instr_tdata.w <= '0';
                when x"F7" => no_lock; no_wait; instr_tdata.w <= '1';
                when x"FE" => no_lock; no_wait; instr_tdata.w <= '0';
                when x"FF" => no_lock; no_wait; instr_tdata.w <= '1';

                -- FEU
                when x"8D" => set_op(FEU, FEU_LEA,       '1', LOCK_NO_LOCK, WAIT_NO_WAIT);
                when x"98" => set_op(FEU, FEU_CBW,       '0', LOCK_DREG,    WAIT_AX);
                when x"99" => set_op(FEU, FEU_CWD,       '1', LOCK_DREG,    WAIT_AX or WAIT_DX);

                -- STR
                when x"A4" => set_op(STR, MOVS_OP,       '0', LOCK_SI or LOCK_DI,            WAIT_SI or WAIT_DI or WAIT_ES or WAIT_DS or WAIT_FL);
                when x"A5" => set_op(STR, MOVS_OP,       '1', LOCK_SI or LOCK_DI,            WAIT_SI or WAIT_DI or WAIT_ES or WAIT_DS or WAIT_FL);
                when x"A6" => set_op(STR, CMPS_OP,       '0', LOCK_SI or LOCK_DI or LOCK_FL, WAIT_SI or WAIT_DI or WAIT_ES or WAIT_DS or WAIT_FL);
                when x"A7" => set_op(STR, CMPS_OP,       '1', LOCK_SI or LOCK_DI or LOCK_FL, WAIT_SI or WAIT_DI or WAIT_ES or WAIT_DS or WAIT_FL);
                when x"AA" => set_op(STR, STOS_OP,       '0', LOCK_DI,                       WAIT_AX or WAIT_DI or WAIT_ES or WAIT_FL);
                when x"AB" => set_op(STR, STOS_OP,       '1', LOCK_DI,                       WAIT_AX or WAIT_DI or WAIT_ES or WAIT_FL);
                when x"AC" => set_op(STR, LODS_OP,       '0', LOCK_AX or LOCK_SI,            WAIT_AX or WAIT_SI or WAIT_DS or WAIT_FL);
                when x"AD" => set_op(STR, LODS_OP,       '1', LOCK_AX or LOCK_SI,            WAIT_AX or WAIT_SI or WAIT_DS or WAIT_FL);
                when x"AE" => set_op(STR, SCAS_OP,       '0', LOCK_DI or LOCK_FL,            WAIT_AX or WAIT_DI or WAIT_ES or WAIT_FL);
                when x"AF" => set_op(STR, SCAS_OP,       '1', LOCK_DI or LOCK_FL,            WAIT_AX or WAIT_DI or WAIT_ES or WAIT_FL);

                -- MISC
                when x"62" => set_op(LFP, MISC_BOUND,    '1', LOCK_NO_LOCK,         WAIT_SS or WAIT_SP);
                when x"C4" => set_op(LFP, LFP_LES,       '1', LOCK_ES or LOCK_DREG, WAIT_ES);
                when x"C5" => set_op(LFP, LFP_LDS,       '1', LOCK_DS or LOCK_DREG, WAIT_DS);
                when x"D7" => set_op(LFP, MISC_XLAT,     '0', LOCK_AX,              WAIT_DS or WAIT_AX or WAIT_BX);

                -- SYS
                when x"9B" => set_op(SYS, SYS_WAIT_OP,   '1', LOCK_NO_LOCK,         WAIT_NO_WAIT);
                when x"CC" => set_op(SYS, SYS_INT_INT_OP,'1', LOCK_SP or LOCK_FL,   WAIT_FL or WAIT_SS or WAIT_SP);
                when x"CD" => set_op(SYS, SYS_INT_INT_OP,'1', LOCK_SP or LOCK_FL,   WAIT_FL or WAIT_SS or WAIT_SP);
                when x"CE" => set_op(SYS, SYS_INT_INT_OP,'1', LOCK_SP or LOCK_FL,   WAIT_FL or WAIT_SS or WAIT_SP);
                when x"CF" => set_op(SYS, SYS_IRET_OP,   '1', LOCK_SP or LOCK_FL,   WAIT_FL or WAIT_SS or WAIT_SP);
                when x"F4" => set_op(SYS, SYS_HLT_OP,    '1', LOCK_NO_LOCK,         WAIT_NO_WAIT);

                -- ESC
                when x"D8" => set_op(SYS, SYS_INT_INT_OP,'1', LOCK_SP or LOCK_FL,   WAIT_FL or WAIT_SS or WAIT_SP);
                when x"D9" => set_op(SYS, SYS_INT_INT_OP,'1', LOCK_SP or LOCK_FL,   WAIT_FL or WAIT_SS or WAIT_SP);
                when x"DA" => set_op(SYS, SYS_INT_INT_OP,'1', LOCK_SP or LOCK_FL,   WAIT_FL or WAIT_SS or WAIT_SP);
                when x"DB" => set_op(SYS, SYS_INT_INT_OP,'1', LOCK_SP or LOCK_FL,   WAIT_FL or WAIT_SS or WAIT_SP);
                when x"DC" => set_op(SYS, SYS_INT_INT_OP,'1', LOCK_SP or LOCK_FL,   WAIT_FL or WAIT_SS or WAIT_SP);
                when x"DD" => set_op(SYS, SYS_INT_INT_OP,'1', LOCK_SP or LOCK_FL,   WAIT_FL or WAIT_SS or WAIT_SP);
                when x"DE" => set_op(SYS, SYS_INT_INT_OP,'1', LOCK_SP or LOCK_FL,   WAIT_FL or WAIT_SS or WAIT_SP);
                when x"DF" => set_op(SYS, SYS_INT_INT_OP,'1', LOCK_SP or LOCK_FL,   WAIT_FL or WAIT_SS or WAIT_SP);

                -- LOOP
                when x"E0" => set_op(LOOPU, LOOP_OP_NE,  '1', LOCK_DREG,    WAIT_CX or WAIT_FL);
                when x"E1" => set_op(LOOPU, LOOP_OP_E,   '1', LOCK_DREG,    WAIT_CX or WAIT_FL);
                when x"E2" => set_op(LOOPU, LOOP_OP,     '1', LOCK_DREG,    WAIT_CX);
                when x"E3" => set_op(LOOPU, LOOP_JCXZ,   '1', LOCK_NO_LOCK, WAIT_CX);

                -- JMP
                when x"E9" => set_op(JMPU, JMP_REL16,    '1', LOCK_NO_LOCK, WAIT_NO_WAIT);
                when x"EA" => set_op(JMPU, JMP_PTR16_16, '1', LOCK_NO_LOCK, WAIT_NO_WAIT);
                when x"EB" => set_op(JMPU, JMP_REL8,     '0', LOCK_NO_LOCK, WAIT_NO_WAIT);

                -- BRANCH
                when x"70" => set_op(BRANCH, BRA_JO,     '1', LOCK_NO_LOCK, WAIT_FL);
                when x"71" => set_op(BRANCH, BRA_JNO,    '1', LOCK_NO_LOCK, WAIT_FL);
                when x"72" => set_op(BRANCH, BRA_JB,     '1', LOCK_NO_LOCK, WAIT_FL);
                when x"73" => set_op(BRANCH, BRA_JAE,    '1', LOCK_NO_LOCK, WAIT_FL);
                when x"74" => set_op(BRANCH, BRA_JE,     '1', LOCK_NO_LOCK, WAIT_FL);
                when x"75" => set_op(BRANCH, BRA_JNE,    '1', LOCK_NO_LOCK, WAIT_FL);
                when x"76" => set_op(BRANCH, BRA_JBE,    '1', LOCK_NO_LOCK, WAIT_FL);
                when x"77" => set_op(BRANCH, BRA_JA,     '1', LOCK_NO_LOCK, WAIT_FL);
                when x"78" => set_op(BRANCH, BRA_JS,     '1', LOCK_NO_LOCK, WAIT_FL);
                when x"79" => set_op(BRANCH, BRA_JNS,    '1', LOCK_NO_LOCK, WAIT_FL);
                when x"7A" => set_op(BRANCH, BRA_JP,     '1', LOCK_NO_LOCK, WAIT_FL);
                when x"7B" => set_op(BRANCH, BRA_JNP,    '1', LOCK_NO_LOCK, WAIT_FL);
                when x"7C" => set_op(BRANCH, BRA_JL,     '1', LOCK_NO_LOCK, WAIT_FL);
                when x"7D" => set_op(BRANCH, BRA_JGE,    '1', LOCK_NO_LOCK, WAIT_FL);
                when x"7E" => set_op(BRANCH, BRA_JLE,    '1', LOCK_NO_LOCK, WAIT_FL);
                when x"7F" => set_op(BRANCH, BRA_JG,     '1', LOCK_NO_LOCK, WAIT_FL);

                -- IO
                when x"E4" => set_op(IO, IO_IN_IMM,      '0', LOCK_AX,      WAIT_NO_WAIT);
                when x"E5" => set_op(IO, IO_IN_IMM,      '1', LOCK_AX,      WAIT_NO_WAIT);
                when x"E6" => set_op(IO, IO_OUT_IMM,     '0', LOCK_NO_LOCK, WAIT_AX);
                when x"E7" => set_op(IO, IO_OUT_IMM,     '1', LOCK_NO_LOCK, WAIT_AX);
                when x"EC" => set_op(IO, IO_IN_DX,       '0', LOCK_AX,      WAIT_DX);
                when x"ED" => set_op(IO, IO_IN_DX,       '1', LOCK_AX,      WAIT_DX);
                when x"EE" => set_op(IO, IO_OUT_DX,      '0', LOCK_NO_LOCK, WAIT_AX or WAIT_DX);
                when x"EF" => set_op(IO, IO_OUT_DX,      '1', LOCK_NO_LOCK, WAIT_AX or WAIT_DX);

                when x"6C" => set_op(IO, IO_INS_DX,      '0', LOCK_NO_LOCK, WAIT_DX or WAIT_SI or WAIT_DS or WAIT_FL);
                when x"6D" => set_op(IO, IO_INS_DX,      '1', LOCK_NO_LOCK, WAIT_DX or WAIT_SI or WAIT_DS or WAIT_FL);
                when x"6E" => set_op(IO, IO_OUTS_DX,     '0', LOCK_NO_LOCK, WAIT_DX or WAIT_DI or WAIT_ES or WAIT_FL);
                when x"6F" => set_op(IO, IO_OUTS_DX,     '1', LOCK_NO_LOCK, WAIT_DX or WAIT_DI or WAIT_ES or WAIT_FL);

                -- PREFIXES
                when x"26" => set_op(PREFIX, PREFIX_SEGM,   '1', LOCK_NO_LOCK, WAIT_ES);
                when x"2E" => set_op(PREFIX, PREFIX_SEGM,   '1', LOCK_NO_LOCK, WAIT_NO_WAIT);
                when x"36" => set_op(PREFIX, PREFIX_SEGM,   '1', LOCK_NO_LOCK, WAIT_SS);
                when x"3E" => set_op(PREFIX, PREFIX_SEGM,   '1', LOCK_NO_LOCK, WAIT_DS);
                when x"F0" => set_op(PREFIX, PREFIX_LOCK,   '1', LOCK_NO_LOCK, WAIT_NO_WAIT);
                when x"F2" => set_op(PREFIX, PREFIX_REPNZ,  '1', LOCK_DREG,    WAIT_CX);
                when x"F3" => set_op(PREFIX, PREFIX_REPZ,   '1', LOCK_DREG,    WAIT_CX);

                -- FLG
                when x"F5" => set_flag_op(FLAG_CF, TOGGLE, LOCK_DREG or LOCK_FL, WAIT_FL);
                when x"F8" => set_flag_op(FLAG_CF, CLR,    LOCK_DREG or LOCK_FL, WAIT_FL);
                when x"F9" => set_flag_op(FLAG_CF, SET,    LOCK_DREG or LOCK_FL, WAIT_FL);
                when x"FA" => set_flag_op(FLAG_IF, CLR,    LOCK_DREG or LOCK_FL, WAIT_FL);
                when x"FB" => set_flag_op(FLAG_IF, SET,    LOCK_DREG or LOCK_FL, WAIT_FL);
                when x"FC" => set_flag_op(FLAG_DF, CLR,    LOCK_DREG or LOCK_FL, WAIT_FL);
                when x"FD" => set_flag_op(FLAG_DF, SET,    LOCK_DREG or LOCK_FL, WAIT_FL);

                -- invalid opcodes
                when x"0F"  => set_op(SYS, SYS_INT_INT_OP, '1', LOCK_SP or LOCK_FL,   WAIT_FL or WAIT_SS or WAIT_SP);
                when x"63"  => set_op(SYS, SYS_INT_INT_OP, '1', LOCK_SP or LOCK_FL,   WAIT_FL or WAIT_SS or WAIT_SP);
                when x"64"  => set_op(SYS, SYS_INT_INT_OP, '1', LOCK_SP or LOCK_FL,   WAIT_FL or WAIT_SS or WAIT_SP);
                when x"65"  => set_op(SYS, SYS_INT_INT_OP, '1', LOCK_SP or LOCK_FL,   WAIT_FL or WAIT_SS or WAIT_SP);
                when x"66"  => set_op(SYS, SYS_INT_INT_OP, '1', LOCK_SP or LOCK_FL,   WAIT_FL or WAIT_SS or WAIT_SP);
                when x"67"  => set_op(SYS, SYS_INT_INT_OP, '1', LOCK_SP or LOCK_FL,   WAIT_FL or WAIT_SS or WAIT_SP);
                when x"D6"  => set_op(SYS, SYS_INT_INT_OP, '1', LOCK_SP or LOCK_FL,   WAIT_FL or WAIT_SS or WAIT_SP);
                when x"F1"  => set_op(SYS, SYS_INT_INT_OP, '1', LOCK_SP or LOCK_FL,   WAIT_FL or WAIT_SS or WAIT_SP);
                when others => set_op(SYS, SYS_INT_INT_OP, '1', LOCK_SP or LOCK_FL,   WAIT_FL or WAIT_SS or WAIT_SP);
            end case;
        end;

        procedure decode_c0_d0 is begin
            instr_tdata.op <= SHFU;
            instr_tdata.w <= '0';
            case u8_tdata_reg is
                when "000" => instr_tdata.code <= SHF_OP_ROL;
                when "001" => instr_tdata.code <= SHF_OP_ROR;
                when "010" => instr_tdata.code <= SHF_OP_RCL; instr_tdata.wait_fl <= '1';
                when "011" => instr_tdata.code <= SHF_OP_RCR; instr_tdata.wait_fl <= '1';
                when "100" => instr_tdata.code <= SHF_OP_SHL;
                when "101" => instr_tdata.code <= SHF_OP_SHR;
                when "110" => null;
                when "111" => instr_tdata.code <= SHF_OP_SAR;
                when others => null;
            end case;

            if (u8_tdata(7 downto 6) = "11") then
                case u8_tdata_rm is
                    when "000" => instr_tdata.wait_ax <= '1';
                    when "001" => instr_tdata.wait_cx <= '1';
                    when "010" => instr_tdata.wait_dx <= '1';
                    when "011" => instr_tdata.wait_bx <= '1';
                    when "100" => instr_tdata.wait_ax <= '1';
                    when "101" => instr_tdata.wait_cx <= '1';
                    when "110" => instr_tdata.wait_dx <= '1';
                    when "111" => instr_tdata.wait_bx <= '1';
                    when others => null;
                end case;
            end if;

            if (u8_tdata(7 downto 6) = "11") then
                upd_lock(LOCK_DREG or LOCK_FL);
            else
                upd_lock(LOCK_FL);
            end if;

        end procedure;

        procedure decode_c1_d1 is begin
            instr_tdata.op <= SHFU;
            instr_tdata.w <= '1';
            case u8_tdata_reg is
                when "000" => instr_tdata.code <= SHF_OP_ROL;
                when "001" => instr_tdata.code <= SHF_OP_ROR;
                when "010" => instr_tdata.code <= SHF_OP_RCL; instr_tdata.wait_fl <= '1';
                when "011" => instr_tdata.code <= SHF_OP_RCR; instr_tdata.wait_fl <= '1';
                when "100" => instr_tdata.code <= SHF_OP_SHL;
                when "101" => instr_tdata.code <= SHF_OP_SHR;
                when "110" => null;
                when "111" => instr_tdata.code <= SHF_OP_SAR;
                when others => null;
            end case;

            if (u8_tdata(7 downto 6) = "11") then
                case u8_tdata_rm is
                    when "000" => instr_tdata.wait_ax <= '1';
                    when "001" => instr_tdata.wait_cx <= '1';
                    when "010" => instr_tdata.wait_dx <= '1';
                    when "011" => instr_tdata.wait_bx <= '1';
                    when "100" => instr_tdata.wait_sp <= '1';
                    when "101" => instr_tdata.wait_bp <= '1';
                    when "110" => instr_tdata.wait_si <= '1';
                    when "111" => instr_tdata.wait_di <= '1';
                    when others => null;
                end case;
            end if;

            if (u8_tdata(7 downto 6) = "11") then
                upd_lock(LOCK_DREG or LOCK_FL);
            else
                upd_lock(LOCK_FL);
            end if;
        end procedure;

        procedure decode_d2 is begin
            instr_tdata.op <= SHFU;
            instr_tdata.w <= '0';
            case u8_tdata_reg is
                when "000" => instr_tdata.code <= SHF_OP_ROL;
                when "001" => instr_tdata.code <= SHF_OP_ROR;
                when "010" => instr_tdata.code <= SHF_OP_RCL; instr_tdata.wait_fl <= '1';
                when "011" => instr_tdata.code <= SHF_OP_RCR; instr_tdata.wait_fl <= '1';
                when "100" => instr_tdata.code <= SHF_OP_SHL;
                when "101" => instr_tdata.code <= SHF_OP_SHR;
                when "110" => null;
                when "111" => instr_tdata.code <= SHF_OP_SAR;
                when others => null;
            end case;

            instr_tdata.wait_cx <= '1';
            if (u8_tdata(7 downto 6) = "11") then
                case u8_tdata_rm is
                    when "000" => instr_tdata.wait_ax <= '1';
                    when "010" => instr_tdata.wait_dx <= '1';
                    when "011" => instr_tdata.wait_bx <= '1';
                    when "100" => instr_tdata.wait_ax <= '1';
                    when "110" => instr_tdata.wait_dx <= '1';
                    when "111" => instr_tdata.wait_bx <= '1';
                    when others => null;
                end case;
            end if;

            if (u8_tdata(7 downto 6) = "11") then
                upd_lock(LOCK_DREG or LOCK_FL);
            else
                upd_lock(LOCK_FL);
            end if;
        end procedure;

        procedure decode_d3 is begin
            instr_tdata.op <= SHFU;
            instr_tdata.w <= '1';
            case u8_tdata_reg is
                when "000" => instr_tdata.code <= SHF_OP_ROL;
                when "001" => instr_tdata.code <= SHF_OP_ROR;
                when "010" => instr_tdata.code <= SHF_OP_RCL; instr_tdata.wait_fl <= '1';
                when "011" => instr_tdata.code <= SHF_OP_RCR; instr_tdata.wait_fl <= '1';
                when "100" => instr_tdata.code <= SHF_OP_SHL;
                when "101" => instr_tdata.code <= SHF_OP_SHR;
                when "110" => null;
                when "111" => instr_tdata.code <= SHF_OP_SAR;
                when others => null;
            end case;

            instr_tdata.wait_cx <= '1';
            if (u8_tdata(7 downto 6) = "11") then
                case u8_tdata_rm is
                    when "000" => instr_tdata.wait_ax <= '1';
                    when "010" => instr_tdata.wait_dx <= '1';
                    when "011" => instr_tdata.wait_bx <= '1';
                    when "100" => instr_tdata.wait_sp <= '1';
                    when "101" => instr_tdata.wait_bp <= '1';
                    when "110" => instr_tdata.wait_si <= '1';
                    when "111" => instr_tdata.wait_di <= '1';
                    when others => null;
                end case;
            end if;

            if (u8_tdata(7 downto 6) = "11") then
                upd_lock(LOCK_DREG or LOCK_FL);
            else
                upd_lock(LOCK_FL);
            end if;
        end procedure;

        procedure decode_f6_one_op(op : op_t; code : std_logic_vector) is begin
            instr_tdata.op <= op;
            instr_tdata.code <= code;

            if (u8_tdata(7 downto 6) = "11") then
                case u8_tdata_rm is
                    when "000" => instr_tdata.wait_ax <= '1';
                    when "001" => instr_tdata.wait_cx <= '1';
                    when "010" => instr_tdata.wait_dx <= '1';
                    when "011" => instr_tdata.wait_bx <= '1';
                    when "100" => instr_tdata.wait_ax <= '1';
                    when "101" => instr_tdata.wait_cx <= '1';
                    when "110" => instr_tdata.wait_dx <= '1';
                    when "111" => instr_tdata.wait_bx <= '1';
                    when others => null;
                end case;
            end if;

            if (u8_tdata(7 downto 6) = "11") then
                upd_lock(LOCK_DREG or LOCK_FL);
            else
                upd_lock(LOCK_FL);
            end if;
        end procedure;

        procedure decode_f7_one_op(op : op_t; code : std_logic_vector) is begin
            instr_tdata.op <= op;
            instr_tdata.code <= code;

            if (u8_tdata(7 downto 6) = "11") then
                case u8_tdata_rm is
                    when "000" => instr_tdata.wait_ax <= '1';
                    when "001" => instr_tdata.wait_cx <= '1';
                    when "010" => instr_tdata.wait_dx <= '1';
                    when "011" => instr_tdata.wait_bx <= '1';
                    when "100" => instr_tdata.wait_sp <= '1';
                    when "101" => instr_tdata.wait_bp <= '1';
                    when "110" => instr_tdata.wait_si <= '1';
                    when "111" => instr_tdata.wait_di <= '1';
                    when others => null;
                end case;
            end if;

            if (u8_tdata(7 downto 6) = "11") then
                upd_lock(LOCK_DREG or LOCK_FL);
            else
                upd_lock(LOCK_FL);
            end if;
        end procedure;

        procedure decode_f6_f7_mul_op(code : std_logic_vector; w: std_logic) is begin
            instr_tdata.op <= MULU;
            instr_tdata.code <= code;
            instr_tdata.wait_ax <= '1';
            instr_tdata.wait_dx <= w;

            if (w = '1') then
                upd_lock(LOCK_AX or LOCK_DREG or LOCK_FL);
            else
                upd_lock(LOCK_DREG or LOCK_FL);
            end if;
        end procedure;

        procedure decode_f6_f7_div_op(code : std_logic_vector; w: std_logic) is begin
            instr_tdata.op <= DIVU;
            instr_tdata.code <= code;
            instr_tdata.wait_ax <= '1';
            instr_tdata.wait_dx <= w;
            instr_tdata.wait_ss <= '1';
            instr_tdata.wait_sp <= '1';

            if (w = '1') then
                upd_lock(LOCK_AX or LOCK_DREG);
            else
                upd_lock(LOCK_DREG);
            end if;
        end procedure;

        procedure decode_f6(w : std_logic) is begin
            instr_tdata.w <= w;
            case u8_tdata(5 downto 3) is
                when "000" => decode_f6_one_op(ALU, ALU_OP_TST);
                when "001" => null;
                when "010" => decode_f6_one_op(ALU, ALU_OP_NOT);
                when "011" => decode_f6_one_op(ALU, ALU_OP_NEG);
                when "100" => decode_f6_f7_mul_op(MUL_AXDX, w);
                when "101" => decode_f6_f7_mul_op(IMUL_AXDX, w);
                when "110" => decode_f6_f7_div_op(DIVU_DIV, w);
                when "111" => decode_f6_f7_div_op(DIVU_IDIV, w);
                when others => null;
            end case;
        end;

        procedure decode_f7(w : std_logic) is begin
            instr_tdata.w <= w;
            case u8_tdata(5 downto 3) is
                when "000" => decode_f7_one_op(ALU, ALU_OP_TST);
                when "001" => null;
                when "010" => decode_f7_one_op(ALU, ALU_OP_NOT);
                when "011" => decode_f7_one_op(ALU, ALU_OP_NEG);
                when "100" => decode_f6_f7_mul_op(MUL_AXDX, w);
                when "101" => decode_f6_f7_mul_op(IMUL_AXDX, w);
                when "110" => decode_f6_f7_div_op(DIVU_DIV, w);
                when "111" => decode_f6_f7_div_op(DIVU_IDIV, w);
                when others => null;
            end case;
        end;

        procedure decode_80_81_83(w : std_logic) is begin
            instr_tdata.op <= ALU;
            instr_tdata.w <= w;

            case u8_tdata(5 downto 3) is
                when "000" => instr_tdata.code <= ALU_OP_ADD;
                when "001" => instr_tdata.code <= ALU_OP_OR;
                when "010" => instr_tdata.code <= ALU_OP_ADC;
                when "011" => instr_tdata.code <= ALU_OP_SBB;

                when "100" => instr_tdata.code <= ALU_OP_AND;
                when "101" => instr_tdata.code <= ALU_OP_SUB;
                when "110" => instr_tdata.code <= ALU_OP_XOR;
                when "111" => instr_tdata.code <= ALU_OP_CMP;
                when others => null;
            end case;

            case u8_tdata(5 downto 3) is
                when "010" => instr_tdata.wait_fl <= '1';
                when "011" => instr_tdata.wait_fl <= '1';
                when others => null;
            end case;

            if (u8_tdata(7 downto 6) = "11") then
                if (w = '0') then
                    case u8_tdata_rm is
                        when "000"  => instr_tdata.wait_ax <= '1';
                        when "001"  => instr_tdata.wait_cx <= '1';
                        when "010"  => instr_tdata.wait_dx <= '1';
                        when "011"  => instr_tdata.wait_bx <= '1';
                        when "100"  => instr_tdata.wait_ax <= '1';
                        when "101"  => instr_tdata.wait_cx <= '1';
                        when "110"  => instr_tdata.wait_dx <= '1';
                        when "111"  => instr_tdata.wait_bx <= '1';
                        when others => null;
                    end case;
                else
                    case u8_tdata_rm is
                        when "000"  => instr_tdata.wait_ax <= '1';
                        when "001"  => instr_tdata.wait_cx <= '1';
                        when "010"  => instr_tdata.wait_dx <= '1';
                        when "011"  => instr_tdata.wait_bx <= '1';
                        when "100"  => instr_tdata.wait_sp <= '1';
                        when "101"  => instr_tdata.wait_bp <= '1';
                        when "110"  => instr_tdata.wait_si <= '1';
                        when "111"  => instr_tdata.wait_di <= '1';
                        when others => null;
                    end case;
                end if;
            end if;

            if (u8_tdata(7 downto 6) = "11") then
                upd_lock(LOCK_DREG or LOCK_FL);
            else
                upd_lock(LOCK_FL);
            end if;
        end;

        procedure mod_aux_rm_upd_lock is begin
            if (u8_tdata(7 downto 6) = "11") then
                upd_lock(LOCK_DREG or LOCK_FL);
            else
                upd_lock(LOCK_FL);
            end if;
        end;

        procedure decode_op_mod_aux_rm is begin
            wait_rm;

            case byte0 is
                when x"80" => decode_80_81_83('0');
                when x"81" => decode_80_81_83('1');
                when x"83" => decode_80_81_83('1');
                when x"8F" => set_stack_op(STACKU_POPM, LOCK_DREG or LOCK_SP); instr_tdata.wait_ss <= '1'; instr_tdata.wait_sp <= '1';
                when x"C0" => decode_c0_d0;
                when x"C1" => decode_c1_d1;
                when x"D0" => decode_c0_d0;
                when x"D1" => decode_c1_d1;
                when x"D2" => decode_d2;
                when x"D3" => decode_d3;
                when x"F6" => decode_f6('0');
                when x"F7" => decode_f7('1');
                when x"FE" =>
                    instr_tdata.op <= ALU;
                    instr_tdata.w <= '0';
                    case u8_tdata(5 downto 3) is
                        when "000" => instr_tdata.code <= ALU_OP_INC;
                        when "001" => instr_tdata.code <= ALU_OP_DEC;
                        when others => null;
                    end case;
                    if (u8_tdata(7 downto 6) = "11") then
                        upd_lock(LOCK_DREG or LOCK_FL);
                    else
                        upd_lock(LOCK_FL);
                    end if;
                when x"FF" =>
                    instr_tdata.w <= '1';
                    case u8_tdata(5 downto 3) is
                        when "000" => set_op(ALU, ALU_OP_INC, '1'); mod_aux_rm_upd_lock;
                        when "001" => set_op(ALU, ALU_OP_DEC, '1'); mod_aux_rm_upd_lock;
                        when "010" => set_op(JCALL, CALL_RM16,   '1'); upd_lock(LOCK_SP); instr_tdata.wait_ss <= '1'; instr_tdata.wait_sp <= '1';
                        when "011" => set_op(JCALL, CALL_M16_16, '1'); upd_lock(LOCK_SP); instr_tdata.wait_ss <= '1'; instr_tdata.wait_sp <= '1';
                        when "110" => set_stack_op(STACKU_PUSHM, LOCK_SP); instr_tdata.wait_ss <= '1'; instr_tdata.wait_sp <= '1';
                        when "100" => set_op(JMPU, JMP_RM16,   '1');
                        when "101" => set_op(JMPU, JMP_M16_16, '1');
                        when others => null;
                    end case;
                when x"C4" => null; -- everything already done
                when x"C5" => null; -- everything already done
                when others =>
                    instr_tdata.code <= "0000";
            end case;
        end;

        procedure decode_op_mod_reg_rm is begin
            if (u8_tdata(7 downto 6) = "11" or (u8_tdata(7 downto 6) /= "11" and reg_rm_direction = TO_REG)) then
                upd_lock(LOCK_DREG);
            end if;

            wait_rm;

            if (instr_tdata.w = '0') then
                case u8_tdata_reg is
                    when "000" => instr_tdata.wait_ax <= '1';
                    when "001" => instr_tdata.wait_cx <= '1';
                    when "010" => instr_tdata.wait_dx <= '1';
                    when "011" => instr_tdata.wait_bx <= '1';
                    when "100" => instr_tdata.wait_ax <= '1';
                    when "101" => instr_tdata.wait_cx <= '1';
                    when "110" => instr_tdata.wait_dx <= '1';
                    when "111" => instr_tdata.wait_bx <= '1';
                    when others => null;
                end case;
            else
                case u8_tdata_reg is
                    when "000" => instr_tdata.wait_ax <= '1';
                    when "001" => instr_tdata.wait_cx <= '1';
                    when "010" => instr_tdata.wait_dx <= '1';
                    when "011" => instr_tdata.wait_bx <= '1';
                    when "100" => instr_tdata.wait_sp <= '1';
                    when "101" => instr_tdata.wait_bp <= '1';
                    when "110" => instr_tdata.wait_si <= '1';
                    when "111" => instr_tdata.wait_di <= '1';
                    when others => null;
                end case;
            end if;

        end;

        procedure decode_op_mod_seg_rm is begin
            if (u8_tdata(7 downto 6) = "11" or (u8_tdata(7 downto 6) /= "11" and reg_rm_direction = TO_REG)) then
                upd_lock(LOCK_DREG);
            end if;

            case u8_tdata_rm is
                when "000" => instr_tdata.wait_ax <= '1';
                when "001" => instr_tdata.wait_cx <= '1';
                when "010" => instr_tdata.wait_dx <= '1';
                when "011" => instr_tdata.wait_bx <= '1';
                when "100" => instr_tdata.wait_sp <= '1';
                when "101" => instr_tdata.wait_bp <= '1';
                when "110" => instr_tdata.wait_si <= '1';
                when "111" => instr_tdata.wait_di <= '1';
                when others => null;
            end case;

            case u8_tdata_reg(1 downto 0) is
                when "00" => instr_tdata.wait_es <= '1';
                when "10" => instr_tdata.wait_ss <= '1';
                when "11" => instr_tdata.wait_ds <= '1';
                when others => null;
            end case;

        end;

        procedure decode_dir_first_byte is begin
            case u8_tdata is
                when x"B0" | x"B1" | x"B2" | x"B3" | x"B4" | x"B5" | x"B6" | x"B7" =>
                    instr_tdata.dir <= I2R;

                when x"04" | x"0C" | x"14" | x"1C" | x"24" | x"2C" | x"34" | x"3C" |
                     x"05" | x"0D" | x"15" | x"1D" | x"25" | x"2D" | x"35" | x"3D" |
                     x"3F" | x"48" | x"B8" | x"40" | x"49" | x"B9" | x"44" |
                     x"41" | x"4A" | x"BA" | x"42" | x"4B" | x"BB" |
                     x"43" | x"4C" | x"BC" | x"45" | x"4D" | x"BD" |
                     x"46" | x"4E" | x"BE" | x"47" | x"4F" | x"BF" =>
                    instr_tdata.dir <= I2R;

                when x"90" | x"91" | x"92" | x"93" | x"94" | x"95" | x"96" | x"97" =>
                    instr_tdata.dir <= R2R;

                when x"9E" =>
                    instr_tdata.dir <= R2F;

                when x"9F" =>
                    instr_tdata.dir <= R2F;

                when x"C6" | x"C7" =>
                    instr_tdata.dir <= I2M;

                when x"A0" | x"A1" =>
                    instr_tdata.dir <= M2R;

                when x"A2" | x"A3" =>
                    instr_tdata.dir <= R2M;

                when x"A8" | x"A9" =>
                    instr_tdata.dir <= I2R;

                when x"E9" | x"EA" | x"EB" =>
                    instr_tdata.dir <= I2R;

                when x"F2" | x"F3" =>
                    instr_tdata.dir <= I2R;

                when others => null;
            end case;
        end;

        procedure decode_dir_mod_reg_rm is begin
            if (u8_tdata(7 downto 6) = "11") then
                instr_tdata.dir <= R2R;
            else
                if reg_rm_direction = TO_RM then
                    instr_tdata.dir <= R2M;
                else
                    instr_tdata.dir <= M2R;
                end if;
            end if;
        end;

        procedure decode_dir_f6_f7 is begin
            case u8_tdata(5 downto 3) is
                when "000" =>
                    if (u8_tdata(7 downto 6) = "11") then
                        instr_tdata.dir <= I2R;
                    else
                        instr_tdata.dir <= I2M;
                    end if;
                when "001" | "010" | "011" =>
                    if (u8_tdata(7 downto 6) = "11") then
                        instr_tdata.dir <= R2R;
                    else
                        instr_tdata.dir <= M2M;
                    end if;
                when others =>
                    if (u8_tdata(7 downto 6) = "11") then
                        instr_tdata.dir <= R2R;
                    else
                        instr_tdata.dir <= M2R;
                    end if;
            end case;
        end procedure;

        procedure decode_dir_mod_aux_rm is begin
            case byte0 is
                when x"C0" | x"C1" | x"D0" | x"D1" =>
                    if (u8_tdata(7 downto 6) = "11") then
                        instr_tdata.dir <= I2R;
                    else
                        instr_tdata.dir <= I2M;
                    end if;

                when x"D2" | x"D3" =>
                    if (u8_tdata(7 downto 6) = "11") then
                        instr_tdata.dir <= R2R;
                    else
                        instr_tdata.dir <= R2M;
                    end if;

                when x"80" | x"81" | x"83" =>
                    if (u8_tdata(7 downto 6) = "11") then
                        instr_tdata.dir <= I2R;
                    else
                        instr_tdata.dir <= I2M;
                    end if;

                when x"F6" => decode_dir_f6_f7;
                when x"F7" => decode_dir_f6_f7;
                when x"FE" =>
                    if (u8_tdata(7 downto 6) = "11") then
                        instr_tdata.dir <= R2R;
                    else
                        instr_tdata.dir <= M2M;
                    end if;

                when x"FF" =>
                    case u8_tdata(5 downto 3) is
                        when "000" | "001" =>
                            if (u8_tdata(7 downto 6) = "11") then
                                instr_tdata.dir <= R2R;
                            else
                                instr_tdata.dir <= M2M;
                            end if;
                        when "010" | "100" =>
                            if (u8_tdata(7 downto 6) = "11") then
                                instr_tdata.dir <= R2R;
                            else
                                instr_tdata.dir <= M2M;
                            end if;
                        when "011" | "101" =>
                            instr_tdata.dir <= M2M;
                        when others =>
                            null;

                    end case;

                when others =>
                    null;
            end case;
        end;

    begin
        if rising_edge(clk) then

            if (u8_tvalid = '1' and u8_tready = '1' and byte_pos_chain(0) = first_byte) then
                set_undefined;
            end if;

            if (u8_tvalid = '1' and u8_tready = '1') then

                case byte_pos_chain(0) is
                    when first_byte => decode_op_first_byte;
                    when mod_reg_rm => decode_op_mod_reg_rm;
                    when mod_seg_rm => decode_op_mod_seg_rm;
                    when mod_aux_rm => decode_op_mod_aux_rm;
                    when others => null;
                end case;

                case byte_pos_chain(0) is
                    when first_byte => decode_dir_first_byte;
                    when mod_reg_rm => decode_dir_mod_reg_rm;
                    when mod_seg_rm => decode_dir_mod_reg_rm;
                    when mod_aux_rm => decode_dir_mod_aux_rm;
                    when others => null;
                end case;

            end if;

            if (u8_tvalid = '1' and u8_tready = '1' and byte_pos_chain(0) = first_byte) then

                case u8_tdata is
                    when x"A0" | x"A1" | x"A2" | x"A3" => instr_tdata.ea <= DIRECT;
                    when x"A4" | x"A5" | x"A6" | x"A7" => instr_tdata.ea <= SI_DISP;
                    when x"D7" => instr_tdata.ea <= XLAT;
                    when others => null;
                end case;

            elsif (u8_tvalid = '1' and u8_tready = '1' and (byte_pos_chain(0) = mod_reg_rm or byte_pos_chain(0) = mod_seg_rm or byte_pos_chain(0) = mod_aux_rm)) then

                case u8_tdata_rm is
                    when "000" => instr_tdata.ea <= BX_SI_DISP;
                    when "001" => instr_tdata.ea <= BX_DI_DISP;
                    when "010" => instr_tdata.ea <= BP_SI_DISP;
                    when "011" => instr_tdata.ea <= BP_DI_DISP;
                    when "100" => instr_tdata.ea <= SI_DISP;
                    when "101" => instr_tdata.ea <= DI_DISP;
                    when "110" =>
                        if (u8_tdata(7 downto 6) = "00") then
                            instr_tdata.ea <= DIRECT;
                        else
                            instr_tdata.ea <= BP_DISP;
                        end if;
                    when "111" => instr_tdata.ea <= BX_DISP;
                    when others => null;
                end case;

            end if;

            if (u8_tvalid = '1' and u8_tready = '1' and byte_pos_chain(0) = first_byte) then

                case u8_tdata is
                    when x"04" | x"0C" | x"14" | x"1C" | x"24" | x"2C" | x"34" | x"3C" =>
                        instr_tdata.dreg <= AX;
                        instr_tdata.dmask <= "01";

                    when x"05" | x"0D" | x"15" | x"1D" | x"25" | x"2D" | x"35" | x"3D" =>
                        instr_tdata.dreg <= AX;
                        instr_tdata.dmask <= "11";

                    when x"B0" => instr_tdata.dreg <= AX; instr_tdata.dmask <= "01";
                    when x"B1" => instr_tdata.dreg <= CX; instr_tdata.dmask <= "01";
                    when x"B2" => instr_tdata.dreg <= DX; instr_tdata.dmask <= "01";
                    when x"B3" => instr_tdata.dreg <= BX; instr_tdata.dmask <= "01";
                    when x"B4" => instr_tdata.dreg <= AX; instr_tdata.dmask <= "10";
                    when x"B5" => instr_tdata.dreg <= CX; instr_tdata.dmask <= "10";
                    when x"B6" => instr_tdata.dreg <= DX; instr_tdata.dmask <= "10";
                    when x"B7" => instr_tdata.dreg <= BX; instr_tdata.dmask <= "10";

                    when x"27" => instr_tdata.dreg <= AX; instr_tdata.dmask <= "11";
                    when x"2F" => instr_tdata.dreg <= AX; instr_tdata.dmask <= "11";
                    when x"37" => instr_tdata.dreg <= AX; instr_tdata.dmask <= "11";
                    when x"3F" => instr_tdata.dreg <= AX; instr_tdata.dmask <= "11";
                    when x"D4" => instr_tdata.dreg <= AX; instr_tdata.dmask <= "11";
                    when x"D5" => instr_tdata.dreg <= AX; instr_tdata.dmask <= "11";

                    when x"40" | x"48" | x"B8" => instr_tdata.dreg <= AX; instr_tdata.dmask <= "11";
                    when x"41" | x"49" | x"B9" => instr_tdata.dreg <= CX; instr_tdata.dmask <= "11";
                    when x"42" | x"4A" | x"BA" => instr_tdata.dreg <= DX; instr_tdata.dmask <= "11";
                    when x"43" | x"4B" | x"BB" => instr_tdata.dreg <= BX; instr_tdata.dmask <= "11";
                    when x"44" | x"4C" | x"BC" => instr_tdata.dreg <= SP; instr_tdata.dmask <= "11";
                    when x"45" | x"4D" | x"BD" => instr_tdata.dreg <= BP; instr_tdata.dmask <= "11";
                    when x"46" | x"4E" | x"BE" => instr_tdata.dreg <= SI; instr_tdata.dmask <= "11";
                    when x"47" | x"4F" | x"BF" => instr_tdata.dreg <= DI; instr_tdata.dmask <= "11";

                    when x"90" | x"91" | x"92" | x"93" | x"94" | x"95" | x"96" | x"97" =>
                        instr_tdata.dreg <= AX;
                        instr_tdata.dmask <= "11";

                    when x"E0" => instr_tdata.dreg <= CX; instr_tdata.dmask <= "11";
                    when x"E1" => instr_tdata.dreg <= CX; instr_tdata.dmask <= "11";
                    when x"E2" => instr_tdata.dreg <= CX; instr_tdata.dmask <= "11";
                    when x"E3" => instr_tdata.dreg <= ZERO; instr_tdata.dmask <= "11";

                    when x"07" => instr_tdata.dreg <= ES; instr_tdata.dmask <= "11";
                    when x"17" => instr_tdata.dreg <= SS; instr_tdata.dmask <= "11";
                    when x"1F" => instr_tdata.dreg <= DS; instr_tdata.dmask <= "11";

                    when x"58" => instr_tdata.dreg <= AX; instr_tdata.dmask <= "11";
                    when x"59" => instr_tdata.dreg <= CX; instr_tdata.dmask <= "11";
                    when x"5A" => instr_tdata.dreg <= DX; instr_tdata.dmask <= "11";
                    when x"5B" => instr_tdata.dreg <= BX; instr_tdata.dmask <= "11";
                    when x"5C" => instr_tdata.dreg <= SP; instr_tdata.dmask <= "11";
                    when x"5D" => instr_tdata.dreg <= BP; instr_tdata.dmask <= "11";
                    when x"5E" => instr_tdata.dreg <= SI; instr_tdata.dmask <= "11";
                    when x"5F" => instr_tdata.dreg <= DI; instr_tdata.dmask <= "11";

                    when x"60" | x"61" | x"68" | x"6A" =>
                        instr_tdata.dreg <= SP;
                        instr_tdata.dmask <= "11";

                    when x"98" => instr_tdata.dreg <= AX; instr_tdata.dmask <= "11";
                    when x"99" => instr_tdata.dreg <= DX; instr_tdata.dmask <= "11";
                    when x"9D" => instr_tdata.dreg <= FL; instr_tdata.dmask <= "11";
                    when x"9E" => instr_tdata.dreg <= FL; instr_tdata.dmask <= "01";
                    when x"9F" => instr_tdata.dreg <= AX; instr_tdata.dmask <= "10";

                    when x"A0" => instr_tdata.dreg <= AX; instr_tdata.dmask <= "01";
                    when x"A1" => instr_tdata.dreg <= AX; instr_tdata.dmask <= "11";

                    when x"A4" | x"A5" | x"A6" | x"A7" | x"AA" | x"AB" | x"AE" | x"AF" =>
                        instr_tdata.dreg <= DI;
                        instr_tdata.dmask <= "11";

                    when x"A8" => instr_tdata.dreg <= AX; instr_tdata.dmask <= "01";
                    when x"A9" => instr_tdata.dreg <= AX; instr_tdata.dmask <= "11";
                    when x"AC" => instr_tdata.dreg <= AX; instr_tdata.dmask <= "01";
                    when x"AD" => instr_tdata.dreg <= AX; instr_tdata.dmask <= "11";
                    when x"C8" => instr_tdata.dreg <= BP; instr_tdata.dmask <= "11";
                    when x"C9" => instr_tdata.dreg <= BP; instr_tdata.dmask <= "11";
                    when x"D7" => instr_tdata.dreg <= AX; instr_tdata.dmask <= "01";

                    when x"F2" => instr_tdata.dreg <= CX; instr_tdata.dmask <= "11";
                    when x"F3" => instr_tdata.dreg <= CX; instr_tdata.dmask <= "11";
                    when x"F5" => instr_tdata.dreg <= FL; instr_tdata.dmask <= "11";
                    when x"F8" => instr_tdata.dreg <= FL; instr_tdata.dmask <= "11";
                    when x"F9" => instr_tdata.dreg <= FL; instr_tdata.dmask <= "11";
                    when x"FA" => instr_tdata.dreg <= FL; instr_tdata.dmask <= "11";
                    when x"FB" => instr_tdata.dreg <= FL; instr_tdata.dmask <= "11";
                    when x"FC" => instr_tdata.dreg <= FL; instr_tdata.dmask <= "11";
                    when x"FD" => instr_tdata.dreg <= FL; instr_tdata.dmask <= "11";

                    when others => null;

                end case;

            elsif (u8_tvalid = '1' and u8_tready = '1' and byte_pos_chain(0) = mod_seg_rm) then

                if (byte0(1) = '1') then
                    --x"8E"
                    case u8_tdata_reg(1 downto 0) is
                        when "00" => instr_tdata.dreg <= ES;
                        when "01" => instr_tdata.dreg <= CS;
                        when "10" => instr_tdata.dreg <= SS;
                        when "11" => instr_tdata.dreg <= DS;
                        when others => null;
                    end case;

                else
                    --x"8C"
                    case u8_tdata_rm is
                        when "000" => instr_tdata.dreg <= AX;
                        when "001" => instr_tdata.dreg <= CX;
                        when "010" => instr_tdata.dreg <= DX;
                        when "011" => instr_tdata.dreg <= BX;
                        when "100" => instr_tdata.dreg <= SP;
                        when "101" => instr_tdata.dreg <= BP;
                        when "110" => instr_tdata.dreg <= SI;
                        when "111" => instr_tdata.dreg <= DI;
                        when others => null;
                    end case;

                end if;

                instr_tdata.dmask <= "11";

            elsif (u8_tvalid = '1' and u8_tready = '1' and byte_pos_chain(0) = mod_reg_rm) then

                if (instr_tdata.w = '0') then

                    if (reg_rm_direction = TO_RM) then

                        case u8_tdata_rm is
                            when "000" => instr_tdata.dreg <= AX;
                            when "001" => instr_tdata.dreg <= CX;
                            when "010" => instr_tdata.dreg <= DX;
                            when "011" => instr_tdata.dreg <= BX;
                            when "100" => instr_tdata.dreg <= AX;
                            when "101" => instr_tdata.dreg <= CX;
                            when "110" => instr_tdata.dreg <= DX;
                            when "111" => instr_tdata.dreg <= BX;
                            when others => null;
                        end case;

                        if (u8_tdata_rm(2) = '0') then
                            instr_tdata.dmask <= "01";
                        else
                            instr_tdata.dmask <= "10";
                        end if;

                    else

                        case u8_tdata_reg is
                            when "000" => instr_tdata.dreg <= AX;
                            when "001" => instr_tdata.dreg <= CX;
                            when "010" => instr_tdata.dreg <= DX;
                            when "011" => instr_tdata.dreg <= BX;
                            when "100" => instr_tdata.dreg <= AX;
                            when "101" => instr_tdata.dreg <= CX;
                            when "110" => instr_tdata.dreg <= DX;
                            when "111" => instr_tdata.dreg <= BX;
                            when others => null;
                        end case;

                        if (u8_tdata_reg(2) = '0') then
                            instr_tdata.dmask <= "01";
                        else
                            instr_tdata.dmask <= "10";
                        end if;

                    end if;

                elsif (instr_tdata.w = '1') then

                    if (reg_rm_direction = TO_RM) then

                        case u8_tdata_rm is
                            when "000" => instr_tdata.dreg <= AX;
                            when "001" => instr_tdata.dreg <= CX;
                            when "010" => instr_tdata.dreg <= DX;
                            when "011" => instr_tdata.dreg <= BX;
                            when "100" => instr_tdata.dreg <= SP;
                            when "101" => instr_tdata.dreg <= BP;
                            when "110" => instr_tdata.dreg <= SI;
                            when "111" => instr_tdata.dreg <= DI;
                            when others => null;
                        end case;

                    else

                        case u8_tdata_reg is
                            when "000" => instr_tdata.dreg <= AX;
                            when "001" => instr_tdata.dreg <= CX;
                            when "010" => instr_tdata.dreg <= DX;
                            when "011" => instr_tdata.dreg <= BX;
                            when "100" => instr_tdata.dreg <= SP;
                            when "101" => instr_tdata.dreg <= BP;
                            when "110" => instr_tdata.dreg <= SI;
                            when "111" => instr_tdata.dreg <= DI;
                            when others => null;
                        end case;

                    end if;

                    instr_tdata.dmask <= "11";

                end if;
            elsif (u8_tvalid = '1' and u8_tready = '1' and byte_pos_chain(0) = mod_aux_rm) then

                case byte0 is
                    when x"F6" =>
                        case u8_tdata_reg is
                            when "000" | "001" | "010" | "011" =>
                                case u8_tdata_rm is
                                    when "000" => instr_tdata.dreg <= AX;
                                    when "001" => instr_tdata.dreg <= CX;
                                    when "010" => instr_tdata.dreg <= DX;
                                    when "011" => instr_tdata.dreg <= BX;
                                    when "100" => instr_tdata.dreg <= AX;
                                    when "101" => instr_tdata.dreg <= CX;
                                    when "110" => instr_tdata.dreg <= DX;
                                    when "111" => instr_tdata.dreg <= BX;
                                    when others => null;
                                end case;

                            when "100" => instr_tdata.dreg <= AX;
                            when "101" => instr_tdata.dreg <= AX;
                            when "110" => instr_tdata.dreg <= AX;
                            when "111" => instr_tdata.dreg <= AX;
                            when others => null;
                        end case;

                        if (u8_tdata_rm(2) = '0') then
                            instr_tdata.dmask <= "01";
                        else
                            instr_tdata.dmask <= "10";
                        end if;

                    when x"F7" =>
                        case u8_tdata_reg is
                            when "000" | "001" | "010" | "011" =>
                                case u8_tdata_rm is
                                    when "000" => instr_tdata.dreg <= AX;
                                    when "001" => instr_tdata.dreg <= CX;
                                    when "010" => instr_tdata.dreg <= DX;
                                    when "011" => instr_tdata.dreg <= BX;
                                    when "100" => instr_tdata.dreg <= SP;
                                    when "101" => instr_tdata.dreg <= BP;
                                    when "110" => instr_tdata.dreg <= SI;
                                    when "111" => instr_tdata.dreg <= DI;
                                    when others => null;
                                end case;

                            when "100" => instr_tdata.dreg <= DX;
                            when "101" => instr_tdata.dreg <= DX;
                            when "110" => instr_tdata.dreg <= DX;
                            when "111" => instr_tdata.dreg <= DX;
                            when others => null;
                        end case;
                        instr_tdata.dmask <= "11";

                    when x"C4" | x"C5" =>
                        case u8_tdata_reg is
                            when "000" => instr_tdata.dreg <= AX;
                            when "001" => instr_tdata.dreg <= CX;
                            when "010" => instr_tdata.dreg <= DX;
                            when "011" => instr_tdata.dreg <= BX;
                            when "100" => instr_tdata.dreg <= SP;
                            when "101" => instr_tdata.dreg <= BP;
                            when "110" => instr_tdata.dreg <= SI;
                            when "111" => instr_tdata.dreg <= DI;
                            when others => null;
                        end case;
                        instr_tdata.dmask <= "11";

                    when x"C0" | x"D0" | x"D2" | x"80" =>
                        case u8_tdata_rm is
                            when "000" => instr_tdata.dreg <= AX;
                            when "001" => instr_tdata.dreg <= CX;
                            when "010" => instr_tdata.dreg <= DX;
                            when "011" => instr_tdata.dreg <= BX;
                            when "100" => instr_tdata.dreg <= AX;
                            when "101" => instr_tdata.dreg <= CX;
                            when "110" => instr_tdata.dreg <= DX;
                            when "111" => instr_tdata.dreg <= BX;
                            when others => null;
                        end case;

                        if (u8_tdata_rm(2) = '0') then
                            instr_tdata.dmask <= "01";
                        else
                            instr_tdata.dmask <= "10";
                        end if;

                    when x"C1" | x"D1" | x"D3" | x"81" | x"83" =>
                        case u8_tdata_rm is
                            when "000" => instr_tdata.dreg <= AX;
                            when "001" => instr_tdata.dreg <= CX;
                            when "010" => instr_tdata.dreg <= DX;
                            when "011" => instr_tdata.dreg <= BX;
                            when "100" => instr_tdata.dreg <= SP;
                            when "101" => instr_tdata.dreg <= BP;
                            when "110" => instr_tdata.dreg <= SI;
                            when "111" => instr_tdata.dreg <= DI;
                            when others => null;
                        end case;
                        instr_tdata.dmask <= "11";

                    when x"FE" =>
                        case u8_tdata_rm is
                            when "000" => instr_tdata.dreg <= AX;
                            when "001" => instr_tdata.dreg <= CX;
                            when "010" => instr_tdata.dreg <= DX;
                            when "011" => instr_tdata.dreg <= BX;
                            when "100" => instr_tdata.dreg <= AX;
                            when "101" => instr_tdata.dreg <= CX;
                            when "110" => instr_tdata.dreg <= DX;
                            when "111" => instr_tdata.dreg <= BX;
                            when others => null;
                        end case;

                        if (u8_tdata_rm(2) = '0') then
                            instr_tdata.dmask <= "01";
                        else
                            instr_tdata.dmask <= "10";
                        end if;

                    when x"FF" =>
                        case u8_tdata(5 downto 3) is
                            when "000" | "001" =>
                                case u8_tdata_rm is
                                    when "000" => instr_tdata.dreg <= AX;
                                    when "001" => instr_tdata.dreg <= CX;
                                    when "010" => instr_tdata.dreg <= DX;
                                    when "011" => instr_tdata.dreg <= BX;
                                    when "100" => instr_tdata.dreg <= SP;
                                    when "101" => instr_tdata.dreg <= BP;
                                    when "110" => instr_tdata.dreg <= SI;
                                    when "111" => instr_tdata.dreg <= DI;
                                    when others => null;
                                end case;

                                instr_tdata.dmask <= "11";
                            when "110" =>
                                instr_tdata.dreg <= SP;
                                instr_tdata.dmask <= "11";
                            when others =>
                                null;
                        end case;

                    when others =>
                        null;
                end case;

            end if;

            if (u8_tvalid = '1' and u8_tready = '1' and byte_pos_chain(0) = first_byte) then

                case u8_tdata is
                    when x"0E" => instr_tdata.sreg <= CS; instr_tdata.smask <= "11";
                    when x"16" => instr_tdata.sreg <= SS; instr_tdata.smask <= "11";
                    when x"1E" => instr_tdata.sreg <= DS; instr_tdata.smask <= "11";
                    when x"06" => instr_tdata.sreg <= ES; instr_tdata.smask <= "11";

                    when x"26" => instr_tdata.sreg <= ES; instr_tdata.smask <= "11";
                    when x"2E" => instr_tdata.sreg <= CS; instr_tdata.smask <= "11";
                    when x"36" => instr_tdata.sreg <= SS; instr_tdata.smask <= "11";
                    when x"3E" => instr_tdata.sreg <= DS; instr_tdata.smask <= "11";

                    when x"27" => instr_tdata.sreg <= AX; instr_tdata.smask <= "11";
                    when x"2F" => instr_tdata.sreg <= AX; instr_tdata.smask <= "11";
                    when x"37" => instr_tdata.sreg <= AX; instr_tdata.smask <= "11";
                    when x"3F" => instr_tdata.sreg <= AX; instr_tdata.smask <= "11";
                    when x"D4" => instr_tdata.sreg <= AX; instr_tdata.smask <= "11";
                    when x"D5" => instr_tdata.sreg <= AX; instr_tdata.smask <= "11";

                    when x"40" | x"48" | x"50" | x"90" => instr_tdata.sreg <= AX; instr_tdata.smask <= "11";
                    when x"41" | x"49" | x"51" | x"91" => instr_tdata.sreg <= CX; instr_tdata.smask <= "11";
                    when x"42" | x"4A" | x"52" | x"92" => instr_tdata.sreg <= DX; instr_tdata.smask <= "11";
                    when x"43" | x"4B" | x"53" | x"93" => instr_tdata.sreg <= BX; instr_tdata.smask <= "11";
                    when x"44" | x"4C" | x"54" | x"94" => instr_tdata.sreg <= SP; instr_tdata.smask <= "11";
                    when x"45" | x"4D" | x"55" | x"95" => instr_tdata.sreg <= BP; instr_tdata.smask <= "11";
                    when x"46" | x"4E" | x"56" | x"96" => instr_tdata.sreg <= SI; instr_tdata.smask <= "11";
                    when x"47" | x"4F" | x"57" | x"97" => instr_tdata.sreg <= DI; instr_tdata.smask <= "11";

                    when x"60" | x"61" => instr_tdata.sreg <= AX; instr_tdata.smask <= "11";
                    when x"68" | x"6A" => instr_tdata.sreg <= SP; instr_tdata.smask <= "11";
                    when x"6E" | x"6F" => instr_tdata.sreg <= AX; instr_tdata.smask <= "11";

                    when x"E0" => instr_tdata.sreg <= CX; instr_tdata.smask <= "11";
                    when x"E1" => instr_tdata.sreg <= CX; instr_tdata.smask <= "11";
                    when x"E2" => instr_tdata.sreg <= CX; instr_tdata.smask <= "11";
                    when x"E3" => instr_tdata.sreg <= CX; instr_tdata.smask <= "11";

                    when x"98" => instr_tdata.sreg <= AX; instr_tdata.smask <= "01";
                    when x"99" => instr_tdata.sreg <= AX; instr_tdata.smask <= "11";

                    when x"9C" | x"9D" => instr_tdata.sreg <= FL; instr_tdata.smask <= "11";

                    when x"9E" => instr_tdata.sreg <= AX; instr_tdata.smask <= "10";
                    when x"9F" => instr_tdata.sreg <= FL; instr_tdata.smask <= "01";

                    when x"A2" => instr_tdata.sreg <= AX; instr_tdata.smask <= "01";
                    when x"A3" => instr_tdata.sreg <= AX; instr_tdata.smask <= "11";

                    when x"A4" | x"A5" | x"A6" | x"A7" => instr_tdata.sreg <= SI; instr_tdata.smask <= "11";
                    when x"A8" => instr_tdata.sreg <= AX; instr_tdata.smask <= "01";
                    when x"A9" => instr_tdata.sreg <= AX; instr_tdata.smask <= "11";
                    when x"AA" | x"AE" => instr_tdata.sreg <= AX; instr_tdata.smask <= "01";
                    when x"AB" | x"AF" => instr_tdata.sreg <= AX; instr_tdata.smask <= "11";
                    when x"D2" | x"D3" => instr_tdata.sreg <= CX; instr_tdata.smask <= "01";
                    when x"E6" | x"EE" => instr_tdata.sreg <= AX; instr_tdata.smask <= "01";
                    when x"E7" | x"EF" => instr_tdata.sreg <= AX; instr_tdata.smask <= "11";
                    when x"F2" | x"F3" => instr_tdata.sreg <= CX; instr_tdata.smask <= "11";

                    when others => null;
                end case;


            elsif (u8_tvalid = '1' and u8_tready = '1' and byte_pos_chain(0) = mod_seg_rm) then

                if (byte0(1) = '1') then
                    --x"8E"
                    case u8_tdata_rm is
                        when "000" => instr_tdata.sreg <= AX;
                        when "001" => instr_tdata.sreg <= CX;
                        when "010" => instr_tdata.sreg <= DX;
                        when "011" => instr_tdata.sreg <= BX;
                        when "100" => instr_tdata.sreg <= SP;
                        when "101" => instr_tdata.sreg <= BP;
                        when "110" => instr_tdata.sreg <= SI;
                        when "111" => instr_tdata.sreg <= DI;
                        when others => null;
                    end case;

                else
                    --x"8C"
                    case u8_tdata_reg(1 downto 0) is
                        when "00" => instr_tdata.sreg <= ES;
                        when "01" => instr_tdata.sreg <= CS;
                        when "10" => instr_tdata.sreg <= SS;
                        when "11" => instr_tdata.sreg <= DS;
                        when others => null;
                    end case;

                end if;
                instr_tdata.smask <= "11";

            elsif (u8_tvalid = '1' and u8_tready = '1' and byte_pos_chain(0) = mod_reg_rm) then

                if (byte0 = x"8C") then

                    case u8_tdata_reg(1 downto 0) is
                        when "00" => instr_tdata.sreg <= ES;
                        when "01" => instr_tdata.sreg <= CS;
                        when "10" => instr_tdata.sreg <= SS;
                        when "11" => instr_tdata.sreg <= DS;
                        when others => null;
                    end case;

                    instr_tdata.smask <= "11";

                else
                    if (instr_tdata.w = '0') then
                        if (reg_rm_direction = TO_REG) then

                            case u8_tdata_rm is
                                when "000" => instr_tdata.sreg <= AX;
                                when "001" => instr_tdata.sreg <= CX;
                                when "010" => instr_tdata.sreg <= DX;
                                when "011" => instr_tdata.sreg <= BX;
                                when "100" => instr_tdata.sreg <= AX;
                                when "101" => instr_tdata.sreg <= CX;
                                when "110" => instr_tdata.sreg <= DX;
                                when "111" => instr_tdata.sreg <= BX;
                                when others => null;
                            end case;

                            if (u8_tdata_rm(2) = '0') then
                                instr_tdata.smask <= "01";
                            else
                                instr_tdata.smask <= "10";
                            end if;

                        else

                            case u8_tdata_reg is
                                when "000" => instr_tdata.sreg <= AX;
                                when "001" => instr_tdata.sreg <= CX;
                                when "010" => instr_tdata.sreg <= DX;
                                when "011" => instr_tdata.sreg <= BX;
                                when "100" => instr_tdata.sreg <= AX;
                                when "101" => instr_tdata.sreg <= CX;
                                when "110" => instr_tdata.sreg <= DX;
                                when "111" => instr_tdata.sreg <= BX;
                                when others => null;
                            end case;

                            if (u8_tdata_reg(2) = '0') then
                                instr_tdata.smask <= "01";
                            else
                                instr_tdata.smask <= "10";
                            end if;

                        end if;

                    elsif (instr_tdata.w = '1') then

                        if (reg_rm_direction = TO_REG) then

                            case u8_tdata_rm is
                                when "000" => instr_tdata.sreg <= AX;
                                when "001" => instr_tdata.sreg <= CX;
                                when "010" => instr_tdata.sreg <= DX;
                                when "011" => instr_tdata.sreg <= BX;
                                when "100" => instr_tdata.sreg <= SP;
                                when "101" => instr_tdata.sreg <= BP;
                                when "110" => instr_tdata.sreg <= SI;
                                when "111" => instr_tdata.sreg <= DI;
                                when others => null;
                            end case;

                        else

                            case u8_tdata_reg is
                                when "000" => instr_tdata.sreg <= AX;
                                when "001" => instr_tdata.sreg <= CX;
                                when "010" => instr_tdata.sreg <= DX;
                                when "011" => instr_tdata.sreg <= BX;
                                when "100" => instr_tdata.sreg <= SP;
                                when "101" => instr_tdata.sreg <= BP;
                                when "110" => instr_tdata.sreg <= SI;
                                when "111" => instr_tdata.sreg <= DI;
                                when others => null;
                            end case;

                        end if;

                        instr_tdata.smask <= "11";

                    end if;
                end if;
            elsif (u8_tvalid = '1' and u8_tready = '1' and byte_pos_chain(0) = mod_aux_rm) then

                case byte0 is

                    when x"C0" | x"D0" | x"D2" | x"80" =>
                        case u8_tdata_rm is
                            when "000" => instr_tdata.sreg <= AX;
                            when "001" => instr_tdata.sreg <= CX;
                            when "010" => instr_tdata.sreg <= DX;
                            when "011" => instr_tdata.sreg <= BX;
                            when "100" => instr_tdata.sreg <= AX;
                            when "101" => instr_tdata.sreg <= CX;
                            when "110" => instr_tdata.sreg <= DX;
                            when "111" => instr_tdata.sreg <= BX;
                            when others => null;
                        end case;

                        if (u8_tdata_rm(2) = '0') then
                            instr_tdata.smask <= "01";
                        else
                            instr_tdata.smask <= "10";
                        end if;

                    when x"C1" | x"D1" | x"D3" | x"81" | x"83"  =>
                        case u8_tdata_rm is
                            when "000" => instr_tdata.sreg <= AX;
                            when "001" => instr_tdata.sreg <= CX;
                            when "010" => instr_tdata.sreg <= DX;
                            when "011" => instr_tdata.sreg <= BX;
                            when "100" => instr_tdata.sreg <= SP;
                            when "101" => instr_tdata.sreg <= BP;
                            when "110" => instr_tdata.sreg <= SI;
                            when "111" => instr_tdata.sreg <= DI;
                            when others => null;
                        end case;
                        instr_tdata.smask <= "11";

                    when x"F6" =>
                        case u8_tdata_rm is
                            when "000" => instr_tdata.sreg <= AX;
                            when "001" => instr_tdata.sreg <= CX;
                            when "010" => instr_tdata.sreg <= DX;
                            when "011" => instr_tdata.sreg <= BX;
                            when "100" => instr_tdata.sreg <= AX;
                            when "101" => instr_tdata.sreg <= CX;
                            when "110" => instr_tdata.sreg <= DX;
                            when "111" => instr_tdata.sreg <= BX;
                            when others => null;
                        end case;

                        if (u8_tdata_rm(2) = '0') then
                            instr_tdata.smask <= "01";
                        else
                            instr_tdata.smask <= "10";
                        end if;

                    when x"F7" =>
                        case u8_tdata_rm is
                            when "000" => instr_tdata.sreg <= AX;
                            when "001" => instr_tdata.sreg <= CX;
                            when "010" => instr_tdata.sreg <= DX;
                            when "011" => instr_tdata.sreg <= BX;
                            when "100" => instr_tdata.sreg <= SP;
                            when "101" => instr_tdata.sreg <= BP;
                            when "110" => instr_tdata.sreg <= SI;
                            when "111" => instr_tdata.sreg <= DI;
                            when others => null;
                        end case;

                        instr_tdata.smask <= "11";

                    when x"FE" =>
                        case u8_tdata_rm is
                            when "000" => instr_tdata.sreg <= AX;
                            when "001" => instr_tdata.sreg <= CX;
                            when "010" => instr_tdata.sreg <= DX;
                            when "011" => instr_tdata.sreg <= BX;
                            when "100" => instr_tdata.sreg <= AX;
                            when "101" => instr_tdata.sreg <= CX;
                            when "110" => instr_tdata.sreg <= DX;
                            when "111" => instr_tdata.sreg <= BX;
                            when others => null;
                        end case;

                        if (u8_tdata_rm(2) = '0') then
                            instr_tdata.smask <= "01";
                        else
                            instr_tdata.smask <= "10";
                        end if;

                    when x"FF" =>
                        case u8_tdata(5 downto 3) is
                            when "000" | "001" | "010" | "011" | "100" =>
                                case u8_tdata_rm is
                                    when "000" => instr_tdata.sreg <= AX;
                                    when "001" => instr_tdata.sreg <= CX;
                                    when "010" => instr_tdata.sreg <= DX;
                                    when "011" => instr_tdata.sreg <= BX;
                                    when "100" => instr_tdata.sreg <= SP;
                                    when "101" => instr_tdata.sreg <= BP;
                                    when "110" => instr_tdata.sreg <= SI;
                                    when "111" => instr_tdata.sreg <= DI;
                                    when others => null;
                                end case;

                                instr_tdata.smask <= "11";

                            when others =>
                                null;
                        end case;

                    when others =>
                        null;
                end case;

            end if;

            if (u8_tvalid = '1' and u8_tready = '1') then

                case byte_pos_chain(0) is
                    when first_byte =>
                        case (u8_tdata) is
                            when x"40" | x"41" | x"42" | x"43" | x"44" | x"45" | x"46" | x"47" |
                                 x"48" | x"49" | x"4A" | x"4B" | x"4C" | x"4D" | x"4E" | x"4F" =>
                                instr_tdata.data <= x"0001";
                            when x"E0" | x"E1" | x"E2" =>
                                instr_tdata.data <= x"FFFF";
                            when x"D0" | x"D1" =>
                                instr_tdata.data <= x"0001";
                            when x"0F" | x"63" | x"64" | x"65" | x"66" | x"67" | x"82" | x"D6" | x"F1" =>
                                instr_tdata.data <= x"0006"; -- invalid opcodes. trap 6
                            when x"D8" | x"D9" | x"DA" | x"DB" | x"DC" | x"DD" | x"DE" | x"DF" =>
                                instr_tdata.data <= x"0007"; -- esc instructions. trap 7
                            when x"CC" =>
                                instr_tdata.data <= x"0003"; -- int 3
                            when x"CE" =>
                                instr_tdata.data <= x"0004"; -- into
                            when others =>
                                null;
                        end case;
                    when data_s8 =>
                        for i in 15 downto 8 loop
                            instr_tdata.data(i) <= u8_tdata(7);
                        end loop;
                        instr_tdata.data(7 downto 0) <= u8_tdata;
                    when data8 =>
                        for i in 15 downto 8 loop
                            instr_tdata.data(i) <= '0';
                        end loop;
                        instr_tdata.data(7 downto 0) <= u8_tdata;

                    when data_low =>
                        for i in 15 downto 8 loop
                            instr_tdata.data(i) <= u8_tdata(7);
                        end loop;
                        instr_tdata.data(7 downto 0) <= u8_tdata;
                    when data_high =>
                        instr_tdata.data(15 downto 8) <= u8_tdata;
                    when mod_aux_rm =>
                        case byte0 is

                            when x"FE" =>
                                case u8_tdata(5 downto 3) is
                                    when "000" => instr_tdata.data <= x"0001";
                                    when "001" => instr_tdata.data <= x"0001";
                                    when others => null;
                                end case;

                            when x"FF" =>
                                case u8_tdata(5 downto 3) is
                                    when "000" => instr_tdata.data <= x"0001";
                                    when "001" => instr_tdata.data <= x"0001";
                                    when others => null;
                                end case;

                            when others =>
                                null;

                        end case;
                    when others =>
                        null;

                end case;
            end if;

            if (u8_tvalid = '1' and u8_tready = '1' and byte_pos_chain(0) = first_byte) then
                instr_tdata.disp <= (others => '0');
            elsif (u8_tvalid = '1' and u8_tready = '1' and byte_pos_chain(0) = disp8) then
                for i in 15 downto 8 loop
                    instr_tdata.disp(i) <= u8_tdata(7);
                end loop;
                instr_tdata.disp(7 downto 0) <= u8_tdata;
            elsif (u8_tvalid = '1' and u8_tready = '1' and byte_pos_chain(0) = disp_low) then
                for i in 15 downto 8 loop
                    instr_tdata.disp(i) <= u8_tdata(7);
                end loop;
                instr_tdata.disp(7 downto 0) <= u8_tdata;
            elsif (u8_tvalid = '1' and u8_tready = '1' and byte_pos_chain(0) = disp_high) then
                instr_tdata.disp(15 downto 8) <= u8_tdata;
            end if;

            if (u8_tvalid = '1' and u8_tready = '1') then
                if (byte_pos_chain(0) = first_byte) then
                    case u8_tdata is
                        when x"C0"  => instr_tdata.data_ex <= SHF_BY_IMM8; -- shift by imm8
                        when x"C1"  => instr_tdata.data_ex <= SHF_BY_IMM8; -- shift by imm8
                        when x"D0"  => instr_tdata.data_ex <= SHF_BY_1; -- shift by 1
                        when x"D1"  => instr_tdata.data_ex <= SHF_BY_1; -- shift by 1
                        when x"D2"  => instr_tdata.data_ex <= SHF_BY_CL; -- shift by CL
                        when x"D3"  => instr_tdata.data_ex <= SHF_BY_CL; -- shift by CL
                        when others => instr_tdata.data_ex <= x"00";
                    end case;
                elsif (byte_pos_chain(0) = data_ext) then
                    instr_tdata.data_ex <= u8_tdata;
                end if;
            end if;

            instr_tdata.bpu_taken <= '0';
            instr_tdata.bpu_taken_cs <= (others => '0');
            instr_tdata.bpu_taken_ip <= (others => '0');
            instr_tdata.bpu_first <= '0';

        end if;
    end process;

    dbg_instr_hs_cnt_proc : process (clk) begin

        if (rising_edge(clk)) then
            if resetn = '0' then
                dbg_instr_hs_cnt <= 0;
            else
                if (instr_tvalid = '1' and instr_tready = '1') then
                    dbg_instr_hs_cnt <= dbg_instr_hs_cnt + 1;
                end if;
            end if;
        end if;

    end process;

end architecture;
