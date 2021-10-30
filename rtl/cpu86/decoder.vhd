library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.cpu86_types.all;

entity decoder is
    port (
        clk                 : in std_logic;
        resetn              : in std_logic;

        u8_s_tvalid         : in std_logic;
        u8_s_tready         : out std_logic;
        u8_s_tdata          : in std_logic_vector(7 downto 0);
        u8_s_tuser          : in std_logic_vector(31 downto 0);

        instr_m_tvalid      : out std_logic;
        instr_m_tready      : in std_logic;
        instr_m_tdata       : out decoded_instr_t;
        instr_m_tuser       : out std_logic_vector(31 downto 0)
    );
end entity decoder;

architecture rtl of decoder is

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
        disp_high       --1011
    );

    attribute enum_encoding : string;
    attribute enum_encoding of byte_pos_t : type is "0000 0001 0010 0011 0100 0101 0110 0111 1001 1010 1011";

    type bytes_chain_t is array (natural range 0 to 5) of byte_pos_t;

    signal u8_tvalid            : std_logic;
    signal u8_tready            : std_logic;
    signal u8_tdata             : std_logic_vector(7 downto 0);
    signal u8_tdata_rm          : std_logic_vector(2 downto 0);
    signal u8_tdata_reg         : std_logic_vector(2 downto 0);
    signal byte_pos_chain       : bytes_chain_t;
    signal instr_tvalid         : std_logic;
    signal instr_tready         : std_logic;
    signal instr_tdata          : decoded_instr_t;
    signal instr_tuser          : std_logic_vector(31 downto 0);

    signal byte0                : std_logic_vector(7 downto 0);
    signal byte1                : std_logic_vector(7 downto 0);
    signal reg_rm_direction     : std_logic;
    signal dbg_instr_hs_cnt     : integer := 0;

begin

    instr_m_tvalid <= instr_tvalid;
    instr_tready <= instr_m_tready;
    instr_m_tdata <= instr_tdata;
    instr_m_tuser <= instr_tuser;

    u8_tvalid <= u8_s_tvalid;
    u8_s_tready <= u8_tready;
    u8_tdata <= u8_s_tdata;

    u8_tdata_rm <= u8_tdata(2 downto 0);
    u8_tdata_reg <= u8_tdata(5 downto 3);

    u8_tready <= '1' when instr_tvalid = '0' or (instr_tvalid = '1' and instr_tready = '1') else '0';

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

                                when x"C0" | x"C1" | x"D0" | x"D1" | x"D2" | x"D3" | x"D8" | x"D9" | x"DA" | x"DB" |
                                     x"DC" | x"DD" | x"DE" | x"DF" | x"FE" | x"FF" | x"8F" | x"C4" | x"C5" =>
                                    decode_chain(mod_aux_rm, disp_low, disp_high, first_byte);
                                    instr_tvalid <= '0';

                                when x"C6" =>
                                    decode_chain(mod_aux_rm, disp_low, disp_high, data8, first_byte);
                                    instr_tvalid <= '0';

                                when x"F6" =>
                                    decode_chain(mod_aux_rm, disp_low, disp_high, first_byte, first_byte);
                                    instr_tvalid <= '0';

                                when x"6B" =>
                                    decode_chain(mod_reg_rm, disp_low, disp_high, data8, first_byte);
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

                                when x"06" | x"07" | x"0E" | x"0F" | x"16" | x"17" | x"1E" | x"1F" | x"26" | x"2E" | x"2F" | x"C3" |
                                     x"36" | x"37" | x"3E" | x"3F" | x"41" | x"42" | x"43" | x"44" | x"45" | x"46" | x"47" | x"48" |
                                     x"49" | x"4A" | x"4B" | x"4C" | x"4D" | x"4E" | x"4F" | x"50" | x"51" | x"52" | x"53" | x"54" |
                                     x"55" | x"56" | x"57" | x"58" | x"59" | x"5A" | x"5B" | x"5C" | x"5D" | x"5E" | x"5F" | x"60" |
                                     x"61" | x"63" | x"64" | x"65" | x"66" | x"67" | x"6C" | x"6D" | x"6E" | x"6F" | x"90" | x"91" |
                                     x"92" | x"93" | x"94" | x"95" | x"96" | x"97" | x"98" | x"99" | x"9B" | x"9C" | x"9D" | x"9E" |
                                     x"9F" | x"A4" | x"A5" | x"A6" | x"A7" | x"AA" | x"AB" | x"AC" | x"AD" | x"AE" | x"AF" | x"CB" |
                                     x"C9" | x"CC" | x"CE" | x"CF" | x"F8" | x"F9" | x"FA" | x"FB" | x"FC" | x"FD" | x"F5" | x"F4" |
                                     x"40" =>
                                    byte_pos_chain(0) <= first_byte;
                                    instr_tvalid <= '1';

                                when x"04" | x"0C" | x"14" | x"1C" | x"24" | x"2C" | x"34" | x"3C" | x"6A" | x"A8" | x"B0" | x"B1" |
                                     x"B2" | x"B3" | x"B4" | x"B5" | x"B6" | x"B7" | x"CD" | x"E4" | x"E5" | x"E6" | x"E7" =>
                                    byte_pos_chain(0) <= data8;
                                    byte_pos_chain(1) <= first_byte;
                                    instr_tvalid <= '0';

                                when x"05" | x"0D" | x"15" | x"1D" | x"25" | x"2D" | x"35" | x"3D" | x"68" | x"B8" | x"B9" | x"BA" |
                                     x"BB" | x"BC" | x"BD" | x"BE" | x"BF" | x"C2" | x"CA" =>
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
                                    decode_chain(data_low, data_high, data8, first_byte);
                                    instr_tvalid <= '0';

                                when x"EA" =>
                                    decode_chain(disp_low, disp_high, data_low, data_high, first_byte);
                                    instr_tvalid <= '0';

                                when x"A0" | x"A1" | x"A2" | x"A3" | x"E8" | x"E9" =>
                                    byte_pos_chain(0) <= disp_low;
                                    byte_pos_chain(1) <= disp_high;
                                    byte_pos_chain(2) <= first_byte;
                                    instr_tvalid <= '0';

                                when others =>
                                    null;
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
                        when others     => null;

                    end case;

                elsif instr_tready = '1' then
                    instr_tvalid <= '0';
                end if;

            end if;

            if (u8_tvalid = '1' and u8_tready = '1' and byte_pos_chain(0) = first_byte) then
                byte0 <= u8_tdata;
            end if;

            if (u8_tvalid = '1' and u8_tready = '1' and byte_pos_chain(0) = mod_reg_rm) then
                byte1 <= u8_tdata;
            end if;

            if (u8_tvalid = '1' and u8_tready = '1' and byte_pos_chain(0) = first_byte) then
                instr_tuser(31 downto 16) <= u8_s_tuser(31 downto 16);
            end if;

            if (u8_tvalid = '1' and u8_tready = '1' and byte_pos_chain(0) = first_byte) then
                instr_tuser(15 downto 0) <= std_logic_vector(unsigned(u8_s_tuser(15 downto 0)) + to_unsigned(1, 16));
            elsif (u8_tvalid = '1' and u8_tready = '1') then
                instr_tuser(15 downto 0) <= std_logic_vector(unsigned(instr_tuser(15 downto 0)) + to_unsigned(1, 16));
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
                             x"88" | x"89" | x"8A" | x"8B" | x"8C" =>
                            reg_rm_direction <= TO_RM;
                        when others =>
                            reg_rm_direction <= TO_REG;
                    end case;

                end if;
            end if;
        end if;
    end process;

    process (clk)
        procedure set_op (op : op_t) is begin
            instr_tdata.op <= op;
        end procedure;

        procedure set_op (op : op_t; code : std_logic_vector; w : std_logic) is begin
            instr_tdata.op <= op;
            instr_tdata.code <= code;
            instr_tdata.w <= w;
        end procedure;

        procedure set_stack_op(code : std_logic_vector) is begin
            instr_tdata.op <= STACKU;
            instr_tdata.code <= code;
            instr_tdata.w <= '1';
        end procedure;

        procedure set_flag_op(flag : integer; action : fl_action_t) is begin
            instr_tdata.op <= SET_FLAG;
            instr_tdata.code <= std_logic_vector(to_unsigned(flag, 4));
            instr_tdata.fl <= action;
        end procedure;

        procedure no_lock is begin
            instr_tdata.lock_sreg <= '0';
            instr_tdata.lock_dreg <= '0';
            instr_tdata.lock_ax <= '0';
            instr_tdata.lock_si <= '0';
            instr_tdata.lock_di <= '0';
            instr_tdata.lock_all <= '0';
        end;

        procedure lock_ax_only is begin
            instr_tdata.lock_sreg <= '0';
            instr_tdata.lock_dreg <= '0';
            instr_tdata.lock_ax <= '1';
            instr_tdata.lock_si <= '0';
            instr_tdata.lock_di <= '0';
            instr_tdata.lock_all <= '0';
        end;

        procedure lock_dreg_only is begin
            instr_tdata.lock_sreg <= '0';
            instr_tdata.lock_dreg <= '1';
            instr_tdata.lock_ax <= '0';
            instr_tdata.lock_si <= '0';
            instr_tdata.lock_di <= '0';
            instr_tdata.lock_all <= '0';
        end;

        procedure lock_sreg_dreg is begin
            instr_tdata.lock_sreg <= '1';
            instr_tdata.lock_dreg <= '1';
            instr_tdata.lock_ax <= '0';
            instr_tdata.lock_si <= '0';
            instr_tdata.lock_di <= '0';
            instr_tdata.lock_all <= '0';
        end;

        procedure lock_stack_pop is begin
            instr_tdata.lock_sreg <= '1';
            instr_tdata.lock_dreg <= '1';
            instr_tdata.lock_ax <= '0';
            instr_tdata.lock_si <= '0';
            instr_tdata.lock_di <= '0';
            instr_tdata.lock_all <= '0';
        end;

        procedure lock_stack_default is begin
            instr_tdata.lock_sreg <= '1';
            instr_tdata.lock_dreg <= '0';
            instr_tdata.lock_ax <= '0';
            instr_tdata.lock_si <= '0';
            instr_tdata.lock_di <= '0';
            instr_tdata.lock_all <= '0';
        end;

        procedure lock_stack_popa is begin
            instr_tdata.lock_sreg <= '0';
            instr_tdata.lock_dreg <= '0';
            instr_tdata.lock_ax <= '0';
            instr_tdata.lock_si <= '0';
            instr_tdata.lock_di <= '0';
            instr_tdata.lock_all <= '1';
        end;

        procedure lock_stack_pusha is begin
            instr_tdata.lock_sreg <= '1';
            instr_tdata.lock_dreg <= '1';
            instr_tdata.lock_ax <= '0';
            instr_tdata.lock_si <= '0';
            instr_tdata.lock_di <= '0';
            instr_tdata.lock_all <= '0';
        end;

        procedure lock_movs is begin
            instr_tdata.lock_sreg <= '0';
            instr_tdata.lock_dreg <= '0';
            instr_tdata.lock_ax <= '0';
            instr_tdata.lock_si <= '1';
            instr_tdata.lock_di <= '1';
            instr_tdata.lock_all <= '0';
        end;

        procedure lock_cmps is begin
            instr_tdata.lock_sreg <= '0';
            instr_tdata.lock_dreg <= '0';
            instr_tdata.lock_ax <= '0';
            instr_tdata.lock_si <= '1';
            instr_tdata.lock_di <= '1';
            instr_tdata.lock_all <= '0';
        end;

        procedure lock_stos is begin
            instr_tdata.lock_sreg <= '0';
            instr_tdata.lock_dreg <= '0';
            instr_tdata.lock_ax <= '0';
            instr_tdata.lock_si <= '0';
            instr_tdata.lock_di <= '1';
            instr_tdata.lock_all <= '0';
        end;

        procedure lock_scas is begin
            instr_tdata.lock_sreg <= '0';
            instr_tdata.lock_dreg <= '0';
            instr_tdata.lock_ax <= '0';
            instr_tdata.lock_si <= '0';
            instr_tdata.lock_di <= '1';
            instr_tdata.lock_all <= '0';
        end;

        procedure lock_lods is begin
            instr_tdata.lock_sreg <= '0';
            instr_tdata.lock_dreg <= '0';
            instr_tdata.lock_ax <= '1';
            instr_tdata.lock_si <= '1';
            instr_tdata.lock_di <= '0';
            instr_tdata.lock_all <= '0';
        end;

        procedure decode_op_first_byte is begin
            case u8_tdata is
                when x"00" => set_op(ALU, ALU_OP_ADD, '0'); no_lock;
                when x"01" => set_op(ALU, ALU_OP_ADD, '1'); no_lock;
                when x"02" => set_op(ALU, ALU_OP_ADD, '0'); no_lock;
                when x"03" => set_op(ALU, ALU_OP_ADD, '1'); no_lock;
                when x"04" => set_op(ALU, ALU_OP_ADD, '0'); lock_ax_only;
                when x"05" => set_op(ALU, ALU_OP_ADD, '1'); lock_ax_only;

                when x"06" => set_stack_op(STACKU_PUSHR); lock_stack_default;
                when x"07" => set_stack_op(STACKU_POPR); lock_stack_pop;

                when x"08" => set_op(ALU, ALU_OP_OR,  '0'); no_lock;
                when x"09" => set_op(ALU, ALU_OP_OR,  '1'); no_lock;
                when x"0A" => set_op(ALU, ALU_OP_OR,  '0'); no_lock;
                when x"0B" => set_op(ALU, ALU_OP_OR,  '1'); no_lock;
                when x"0C" => set_op(ALU, ALU_OP_OR,  '0'); lock_ax_only;
                when x"0D" => set_op(ALU, ALU_OP_OR,  '1'); lock_ax_only;

                when x"0E" => set_stack_op(STACKU_PUSHR); lock_stack_default;
                when x"0F" => set_op(DBG); no_lock;

                when x"10" => set_op(ALU, ALU_OP_ADC, '0'); no_lock;
                when x"11" => set_op(ALU, ALU_OP_ADC, '1'); no_lock;
                when x"12" => set_op(ALU, ALU_OP_ADC, '0'); no_lock;
                when x"13" => set_op(ALU, ALU_OP_ADC, '1'); no_lock;
                when x"14" => set_op(ALU, ALU_OP_ADC, '0'); lock_ax_only;
                when x"15" => set_op(ALU, ALU_OP_ADC, '1'); lock_ax_only;

                when x"16" => set_stack_op(STACKU_PUSHR); lock_stack_default;
                when x"17" => set_stack_op(STACKU_POPR); lock_stack_pop;

                when x"18" => set_op(ALU, ALU_OP_SBB, '0'); no_lock;
                when x"19" => set_op(ALU, ALU_OP_SBB, '1'); no_lock;
                when x"1A" => set_op(ALU, ALU_OP_SBB, '0'); no_lock;
                when x"1B" => set_op(ALU, ALU_OP_SBB, '1'); no_lock;
                when x"1C" => set_op(ALU, ALU_OP_SBB, '0'); lock_ax_only;
                when x"1D" => set_op(ALU, ALU_OP_SBB, '1'); lock_ax_only;

                when x"1E" => set_stack_op(STACKU_PUSHR); lock_stack_default;
                when x"1F" => set_stack_op(STACKU_POPR); lock_stack_pop;

                when x"20" => set_op(ALU, ALU_OP_AND, '0'); no_lock;
                when x"21" => set_op(ALU, ALU_OP_AND, '1'); no_lock;
                when x"22" => set_op(ALU, ALU_OP_AND, '0'); no_lock;
                when x"23" => set_op(ALU, ALU_OP_AND, '1'); no_lock;
                when x"24" => set_op(ALU, ALU_OP_AND, '0'); lock_ax_only;
                when x"25" => set_op(ALU, ALU_OP_AND, '1'); lock_ax_only;

                when x"28" => set_op(ALU, ALU_OP_SUB, '0'); no_lock;
                when x"29" => set_op(ALU, ALU_OP_SUB, '1'); no_lock;
                when x"2A" => set_op(ALU, ALU_OP_SUB, '0'); no_lock;
                when x"2B" => set_op(ALU, ALU_OP_SUB, '1'); no_lock;
                when x"2C" => set_op(ALU, ALU_OP_SUB, '0'); lock_ax_only;
                when x"2D" => set_op(ALU, ALU_OP_SUB, '1'); lock_ax_only;

                when x"30" => set_op(ALU, ALU_OP_XOR, '0'); no_lock;
                when x"31" => set_op(ALU, ALU_OP_XOR, '1'); no_lock;
                when x"32" => set_op(ALU, ALU_OP_XOR, '0'); no_lock;
                when x"33" => set_op(ALU, ALU_OP_XOR, '1'); no_lock;
                when x"34" => set_op(ALU, ALU_OP_XOR, '0'); lock_ax_only;
                when x"35" => set_op(ALU, ALU_OP_XOR, '1'); lock_ax_only;

                when x"38" => set_op(ALU, ALU_OP_CMP, '0'); no_lock;
                when x"39" => set_op(ALU, ALU_OP_CMP, '1'); no_lock;
                when x"3A" => set_op(ALU, ALU_OP_CMP, '0'); no_lock;
                when x"3B" => set_op(ALU, ALU_OP_CMP, '1'); no_lock;
                when x"3C" => set_op(ALU, ALU_OP_CMP, '0'); lock_ax_only;
                when x"3D" => set_op(ALU, ALU_OP_CMP, '1'); lock_ax_only;

                when x"26" | x"2E" | x"36" | x"3E" => set_op(SET_SEG); no_lock;

                when x"40" | x"41" | x"42" | x"43" | x"44" | x"45" | x"46" | x"47" => set_op(ALU, ALU_OP_INC, '1'); lock_dreg_only;
                when x"48" | x"49" | x"4A" | x"4B" | x"4C" | x"4D" | x"4E" | x"4F" => set_op(ALU, ALU_OP_DEC, '1'); lock_dreg_only;
                when x"50" | x"51" | x"52" | x"53" | x"54" | x"55" | x"56" | x"57" => set_stack_op(STACKU_PUSHR); lock_stack_default;
                when x"58" | x"59" | x"5A" | x"5B" | x"5C" | x"5D" | x"5E" | x"5F" => set_stack_op(STACKU_POPR); lock_stack_pop;

                when x"60" => set_stack_op(STACKU_PUSHA); lock_stack_pusha;
                when x"61" => set_stack_op(STACKU_POPA); lock_stack_popa;
                when x"68" => set_stack_op(STACKU_PUSHI); lock_dreg_only;
                when x"69" => set_op(MULU, IMUL_RR, '1'); no_lock;
                when x"6A" => set_stack_op(STACKU_PUSHI); lock_stack_default;
                when x"6B" => set_op(MULU, IMUL_RR, '0'); no_lock;

                when x"80" => no_lock;
                when x"81" => no_lock;
                when x"82" => no_lock;
                when x"83" => no_lock;
                when x"86" => set_op(XCHG, "0000", '0'); no_lock;
                when x"87" => set_op(XCHG, "0000", '1'); no_lock;
                when x"88" => set_op(MOVU, "0000", '0'); no_lock;
                when x"89" => set_op(MOVU, "0000", '1'); no_lock;
                when x"8A" => set_op(MOVU, "0000", '0'); no_lock;
                when x"8B" => set_op(MOVU, "0000", '1'); no_lock;
                when x"8C" => set_op(MOVU, "0000", '1'); no_lock;
                when x"8D" => set_op(FEU,  FEU_LEA, '1'); no_lock;
                when x"8E" => set_op(MOVU, "0000", '1'); no_lock;
                when x"8F" => no_lock;

                when x"90" | x"91" | x"92" | x"93" | x"94" | x"95" | x"96" | x"97" => set_op(XCHG, "0000", '1'); lock_sreg_dreg;
                when x"98" => set_op(FEU,  FEU_CBW, '0'); lock_dreg_only;
                when x"99" => set_op(FEU,  FEU_CWD, '1'); lock_dreg_only;

                when x"9C" => set_stack_op(STACKU_PUSHR); lock_stack_default;
                when x"9D" => set_stack_op(STACKU_POPR); lock_stack_pop;

                when x"9E" => set_op(MOVU, "0000", '0'); lock_dreg_only;
                when x"9F" => set_op(MOVU, "0000", '0'); lock_dreg_only;

                when x"A0" => set_op(MOVU, "0000", '0'); lock_dreg_only;
                when x"A1" => set_op(MOVU, "0000", '1'); lock_dreg_only;
                when x"A2" => set_op(MOVU, "0000", '0'); lock_dreg_only;
                when x"A3" => set_op(MOVU, "0000", '1'); lock_dreg_only;

                when x"A4" => set_op(STR, MOVS_OP, '0'); lock_movs;
                when x"A5" => set_op(STR, MOVS_OP, '1'); lock_movs;
                when x"A6" => set_op(STR, CMPS_OP, '0'); lock_cmps;
                when x"A7" => set_op(STR, CMPS_OP, '1'); lock_cmps;
                when x"AA" => set_op(STR, STOS_OP, '0'); lock_stos;
                when x"AB" => set_op(STR, STOS_OP, '1'); lock_stos;
                when x"AC" => set_op(STR, LODS_OP, '0'); lock_lods;
                when x"AD" => set_op(STR, LODS_OP, '1'); lock_lods;
                when x"AE" => set_op(STR, SCAS_OP, '0'); lock_scas;
                when x"AF" => set_op(STR, SCAS_OP, '1'); lock_scas;

                when x"B0" | x"B1" | x"B2" | x"B3" | x"B4" | x"B5" | x"B6" | x"B7" => set_op(MOVU, "0000", '0'); lock_dreg_only;
                when x"B8" | x"B9" | x"BA" | x"BB" | x"BC" | x"BD" | x"BE" | x"BF" => set_op(MOVU, "0000", '1'); lock_dreg_only;

                when x"C4" => set_op(LFP, LFP_LES, '1'); lock_dreg_only;
                when x"C5" => set_op(LFP, LFP_LDS, '1'); lock_dreg_only;
                when x"C6" => set_op(MOVU, "0000", '0'); no_lock;
                when x"C7" => set_op(MOVU, "0000", '1'); no_lock;
                when x"E2" => set_op(LOOPU, LOOP_OP, '1'); lock_dreg_only;

                when x"F2" => set_op(REP, REPNZ_OP, '1'); lock_dreg_only;
                when x"F3" => set_op(REP, REPZ_OP, '1'); lock_dreg_only;
                when x"F4" => set_op(SYS, SYS_HLT_OP, '1'); no_lock;

                when x"F5" => set_flag_op(FLAG_CF, TOGGLE); lock_dreg_only;
                when x"F8" => set_flag_op(FLAG_CF, CLR); lock_dreg_only;
                when x"F9" => set_flag_op(FLAG_CF, SET); lock_dreg_only;
                when x"FA" => set_flag_op(FLAG_IF, CLR); lock_dreg_only;
                when x"FB" => set_flag_op(FLAG_IF, SET); lock_dreg_only;
                when x"FC" => set_flag_op(FLAG_DF, CLR); lock_dreg_only;
                when x"FD" => set_flag_op(FLAG_DF, SET); lock_dreg_only;

                when others =>
                    instr_tdata.code <= "0000";
            end case;
        end;

        procedure decode_f6_f7(w : std_logic) is begin
            instr_tdata.w <= w;

            case u8_tdata(5 downto 3) is
                when "000" => null;
                when "001" => null;
                when "010" => null;
                when "011" => null;

                when "100" => null;
                when "101" => instr_tdata.op <= MULU; instr_tdata.code <= IMUL_AX; lock_sreg_dreg;
                when "110" => null;
                when "111" => null;
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
        end;

        procedure decode_op_mod_aux_rm is begin
            case byte0 is
                when x"F6" => decode_f6_f7('0');
                when x"F7" => decode_f6_f7('1');
                when x"80" => decode_80_81_83('0');
                when x"81" => decode_80_81_83('1');
                when x"83" => decode_80_81_83('1');
                when x"8F" => set_stack_op(STACKU_POPM); lock_stack_pop;
                when x"FE" =>
                    instr_tdata.op <= ALU;
                    instr_tdata.w <= '0';
                    case u8_tdata(5 downto 3) is
                        when "000" => instr_tdata.code <= ALU_OP_INC;
                        when "001" => instr_tdata.code <= ALU_OP_DEC;
                        when others => null;
                    end case;
                when x"FF" =>
                    instr_tdata.w <= '1';
                    case u8_tdata(5 downto 3) is
                        when "000" => set_op(ALU, ALU_OP_INC, '1');
                        when "001" => set_op(ALU, ALU_OP_DEC, '1');
                        when "110" => set_stack_op(STACKU_PUSHM); lock_stack_default;
                        when others => null;
                    end case;

                when others =>
                    instr_tdata.code <= "0000";
            end case;
        end;

        procedure decode_op_mod_reg_rm is begin
            if (u8_tdata(7 downto 6) = "11" or (u8_tdata(7 downto 6) /= "11" and reg_rm_direction = TO_REG)) then
                lock_dreg_only;
            end if;
        end;

        procedure decode_dir_first_byte is begin
            case u8_tdata is
                when x"B0" | x"B1" | x"B2" | x"B3" | x"B4" | x"B5" | x"B6" | x"B7" =>
                    instr_tdata.dir <= I2R;

                when x"04" | x"0C" | x"14" | x"1C" | x"24" | x"2C" | x"34" | x"3C" |
                     x"05" | x"0D" | x"15" | x"1D" | x"25" | x"2D" | x"35" | x"3D" |
                     x"3F" | x"48" | x"B8" | x"40" | x"49" | x"B9" |
                     x"41" | x"4A" | x"BA" | x"42" | x"4B" | x"BB" |
                     x"43" | x"4C" | x"BC" | x"45" | x"4D" | x"BD" |
                     x"46" | x"4E" | x"BE" | x"47" | x"4F" | x"BF" =>
                    instr_tdata.dir <= I2R;

                when x"90" | x"91" | x"92" | x"93" | x"94" | x"95" | x"96" | x"97" =>
                    instr_tdata.dir <= R2R;

                -- push reg
                when x"50" | x"51" | x"52" | x"53" | x"54" | x"55" | x"56" | x"57" =>
                    instr_tdata.dir <= STK;
                -- pop reg
                when x"58" | x"59" | x"5A" | x"5B" | x"5C" | x"5D" | x"5E" | x"5F" =>
                    instr_tdata.dir <= STK;
                -- push sreg
                when x"0E" | x"1E" | x"16" | x"06" =>
                    instr_tdata.dir <= STK;
                -- pop sreg
                when x"1F" | x"17" | x"07" =>
                    instr_tdata.dir <= STK;
                -- pusha, popa
                when x"60" | x"61" =>
                    instr_tdata.dir <= STK;
                -- push imm
                when x"68" | x"6A" =>
                    instr_tdata.dir <= STK;
                -- pushf
                when x"9C" =>
                    instr_tdata.dir <= STK;
                -- popf
                when x"9D" =>
                    instr_tdata.dir <= STK;

                when x"9E" =>
                    instr_tdata.dir <= R2F;

                when x"9F" =>
                    instr_tdata.dir <= R2F;

                when x"A0" | x"A1" =>
                    instr_tdata.dir <= M2R;

                when x"C6" | x"C7" =>
                    instr_tdata.dir <= I2M;

                when x"A2" | x"A3" =>
                    instr_tdata.dir <= R2M;

                when x"A4" | x"A5" | x"A6" | x"A7" | x"AA" | x"AB" | x"AC" | x"AD" | x"AE" | x"AF" =>
                    instr_tdata.dir <= STR;

                when x"F2" | x"F3" =>
                    instr_tdata.dir <= I2R;

                when x"26" | x"2E" | x"36" | x"3E" =>
                    instr_tdata.dir <= SSEG;

                when x"F4" =>
                    instr_tdata.dir <= SFLG;

                when x"F5" | x"F8" | x"F9" | x"FA" | x"FB" | x"FC" | x"FD" =>
                    instr_tdata.dir <= SFLG;

                when x"0F" =>
                    instr_tdata.dir <= SFLG;

                when others => null;
            end case;
        end;

        procedure decode_dir_mod_reg_rm is begin
            if (u8_tdata(7 downto 6) = "11") then
                instr_tdata.dir <= R2R;
            else
                if byte0(WIDTH_BIT) = TO_RM then
                    instr_tdata.dir <= R2M;
                else
                    instr_tdata.dir <= M2R;
                end if;
            end if;
        end;

        procedure decode_dir_mod_aux_rm is begin
            case byte0 is
                -- alu r/m, imm
                when x"C4" | x"C5" =>
                    instr_tdata.dir <= LFP;

                when x"F6" =>
                    if (u8_tdata(7 downto 6) = "11") then
                        instr_tdata.dir <= R2R;
                    else
                        instr_tdata.dir <= M2R;
                    end if;

                when x"F7" =>
                    if (u8_tdata(7 downto 6) = "11") then
                        instr_tdata.dir <= R2R;
                    else
                        instr_tdata.dir <= M2R;
                    end if;

                when x"80" | x"81" | x"83" =>
                    if (u8_tdata(7 downto 6) = "11") then
                        instr_tdata.dir <= I2R;
                    else
                        instr_tdata.dir <= I2M;
                    end if;

                when x"8F" =>
                    if (u8_tdata(5 downto 3) = "000") then
                        instr_tdata.dir <= STKM;
                    end if;

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

                        when "110" =>
                            instr_tdata.dir <= STKM;

                        when others =>
                            null;

                    end case;

                when others =>
                    null;
            end case;
        end;

    begin
        if rising_edge(clk) then

            if (u8_tvalid = '1' and u8_tready = '1') then

                case byte_pos_chain(0) is
                    when first_byte => decode_op_first_byte;
                    when mod_reg_rm => decode_op_mod_reg_rm;
                    when mod_seg_rm => decode_op_mod_reg_rm;
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

                case u8_s_tdata is
                    when x"A0" | x"A1" | x"A2" | x"A3" => instr_tdata.ea <= DIRECT;
                    when x"A4" | x"A5" | x"A6" | x"A7" => instr_tdata.ea <= SI_DISP;
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

                    when x"B0" =>
                        instr_tdata.dreg <= AX;
                        instr_tdata.dmask <= "01";

                    when x"B1" =>
                        instr_tdata.dreg <= CX;
                        instr_tdata.dmask <= "01";

                    when x"B2" =>
                        instr_tdata.dreg <= DX;
                        instr_tdata.dmask <= "01";

                    when x"B3" =>
                        instr_tdata.dreg <= BX;
                        instr_tdata.dmask <= "01";

                    when x"B4" =>
                        instr_tdata.dreg <= AX;
                        instr_tdata.dmask <= "10";

                    when x"B5" =>
                        instr_tdata.dreg <= CX;
                        instr_tdata.dmask <= "10";

                    when x"B6" =>
                        instr_tdata.dreg <= DX;
                        instr_tdata.dmask <= "10";

                    when x"B7" =>
                        instr_tdata.dreg <= BX;
                        instr_tdata.dmask <= "10";

                    when x"40" | x"48" | x"B8" =>
                        instr_tdata.dreg <= AX;
                        instr_tdata.dmask <= "11";

                    when x"41" | x"49" | x"B9" =>
                        instr_tdata.dreg <= CX;
                        instr_tdata.dmask <= "11";

                    when x"42" | x"4A" | x"BA" =>
                        instr_tdata.dreg <= DX;
                        instr_tdata.dmask <= "11";

                    when x"43" | x"4B" | x"BB" =>
                        instr_tdata.dreg <= BX;
                        instr_tdata.dmask <= "11";

                    when x"44" | x"4C" | x"BC" =>
                        instr_tdata.dreg <= SP;
                        instr_tdata.dmask <= "11";

                    when x"45" | x"4D" | x"BD" =>
                        instr_tdata.dreg <= BP;
                        instr_tdata.dmask <= "11";

                    when x"46" | x"4E" | x"BE" =>
                        instr_tdata.dreg <= SI;
                        instr_tdata.dmask <= "11";

                    when x"47" | x"4F" | x"BF" =>
                        instr_tdata.dreg <= DI;
                        instr_tdata.dmask <= "11";

                    when x"90" | x"91" | x"92" | x"93" |
                         x"94" | x"95" | x"96" | x"97" =>
                        instr_tdata.dreg <= AX;
                        instr_tdata.dmask <= "11";

                    when x"E2" =>
                        instr_tdata.dreg <= CX;
                        instr_tdata.dmask <= "11";

                    when x"0E" | x"1E" | x"16" | x"06" =>
                        instr_tdata.dreg <= SP;
                        instr_tdata.dmask <= "11";

                    when x"1F" | x"17" | x"07" =>
                        instr_tdata.dreg <= SP;
                        instr_tdata.dmask <= "11";

                    when x"50" | x"51" | x"52" | x"53" | x"54" | x"55" | x"56" | x"57" =>
                        instr_tdata.dreg <= SP;
                        instr_tdata.dmask <= "11";

                    when x"58" | x"59" | x"5A" | x"5B" | x"5C" | x"5D" | x"5E" | x"5F" =>
                        instr_tdata.dreg <= SP;
                        instr_tdata.dmask <= "11";

                    when x"60" | x"61" | x"68" | x"6A" =>
                        instr_tdata.dreg <= SP;
                        instr_tdata.dmask <= "11";

                    when x"98" =>
                        instr_tdata.dreg <= AX;
                        instr_tdata.dmask <= "11";

                    when x"99" =>
                        instr_tdata.dreg <= DX;
                        instr_tdata.dmask <= "11";

                    when x"9D" | x"9C" =>
                        instr_tdata.dreg <= SP;
                        instr_tdata.dmask <= "11";

                    when x"9E" =>
                        instr_tdata.dreg <= FL;
                        instr_tdata.dmask <= "01";

                    when x"9F" =>
                        instr_tdata.dreg <= AX;
                        instr_tdata.dmask <= "10";

                    when x"A0" =>
                        instr_tdata.dreg <= AX;
                        instr_tdata.dmask <= "01";

                    when x"A1" =>
                        instr_tdata.dreg <= AX;
                        instr_tdata.dmask <= "11";

                    when x"A4" | x"A5" | x"A6" | x"A7" | x"AA" | x"AB" | x"AE" | x"AF" =>
                        instr_tdata.dreg <= DI;
                        instr_tdata.dmask <= "11";

                    when x"AC" =>
                        instr_tdata.dreg <= AX;
                        instr_tdata.dmask <= "01";

                    when x"AD" =>
                        instr_tdata.dreg <= AX;
                        instr_tdata.dmask <= "11";

                    when x"F2" | x"F3" =>
                        instr_tdata.dreg <= CX;
                        instr_tdata.dmask <= "11";

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

                    if (byte0(WIDTH_BIT) = TO_RM) then

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

                    if (byte0(WIDTH_BIT) = TO_RM) then

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
                        case u8_tdata(5 downto 3) is
                            when "000" => null;
                            when "001" => null;
                            when "010" => null;
                            when "011" => null;

                            when "100" => null;
                            when "101" =>
                                instr_tdata.dreg <= AX;
                            when "110" => null;
                            when "111" => null;
                            when others => null;
                        end case;
                        instr_tdata.dmask <= "11";

                    when x"F7" =>
                        case u8_tdata(5 downto 3) is
                            when "000" => null;
                            when "001" => null;
                            when "010" => null;
                            when "011" => null;

                            when "100" => null;
                            when "101" =>
                                instr_tdata.dreg <= DX;
                            when "110" => null;
                            when "111" => null;
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

                    when x"80" =>
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

                    when x"81" | x"83" =>
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

                    when x"8F" =>
                        if (u8_tdata(5 downto 3) = "000") then
                            instr_tdata.dreg <= SP;
                            instr_tdata.dmask <= "11";
                        end if;

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

                    when x"17" => instr_tdata.sreg <= SS; instr_tdata.smask <= "11";
                    when x"1F" => instr_tdata.sreg <= DS; instr_tdata.smask <= "11";
                    when x"07" => instr_tdata.sreg <= ES; instr_tdata.smask <= "11";

                    when x"26" => instr_tdata.sreg <= ES; instr_tdata.smask <= "11";
                    when x"2E" => instr_tdata.sreg <= CS; instr_tdata.smask <= "11";
                    when x"36" => instr_tdata.sreg <= SS; instr_tdata.smask <= "11";
                    when x"3E" => instr_tdata.sreg <= DS; instr_tdata.smask <= "11";

                    when x"40" | x"48" | x"50" | x"58" | x"90" => instr_tdata.sreg <= AX; instr_tdata.smask <= "11";
                    when x"41" | x"49" | x"51" | x"59" | x"91" => instr_tdata.sreg <= CX; instr_tdata.smask <= "11";
                    when x"42" | x"4A" | x"52" | x"5A" | x"92" => instr_tdata.sreg <= DX; instr_tdata.smask <= "11";
                    when x"43" | x"4B" | x"53" | x"5B" | x"93" => instr_tdata.sreg <= BX; instr_tdata.smask <= "11";
                    when x"44" | x"4C" | x"54" | x"5C" | x"94" => instr_tdata.sreg <= SP; instr_tdata.smask <= "11";
                    when x"45" | x"4D" | x"55" | x"5D" | x"95" => instr_tdata.sreg <= BP; instr_tdata.smask <= "11";
                    when x"46" | x"4E" | x"56" | x"5E" | x"96" => instr_tdata.sreg <= SI; instr_tdata.smask <= "11";
                    when x"47" | x"4F" | x"57" | x"5F" | x"97" => instr_tdata.sreg <= DI; instr_tdata.smask <= "11";

                    when x"60" | x"61" => instr_tdata.sreg <= AX; instr_tdata.smask <= "11";
                    when x"68" | x"6A" => instr_tdata.sreg <= SP; instr_tdata.smask <= "11";

                    when x"E2" => instr_tdata.sreg <= CX; instr_tdata.smask <= "11";

                    when x"98" => instr_tdata.sreg <= AX; instr_tdata.smask <= "01";
                    when x"99" => instr_tdata.sreg <= AX; instr_tdata.smask <= "11";

                    when x"9C" | x"9D" => instr_tdata.sreg <= FL; instr_tdata.smask <= "11";

                    when x"9E" => instr_tdata.sreg <= AX; instr_tdata.smask <= "10";
                    when x"9F" => instr_tdata.sreg <= FL; instr_tdata.smask <= "01";

                    when x"A2" => instr_tdata.sreg <= AX; instr_tdata.smask <= "01";
                    when x"A3" => instr_tdata.sreg <= AX; instr_tdata.smask <= "11";

                    when x"A4" | x"A5" | x"A6" | x"A7" => instr_tdata.sreg <= SI; instr_tdata.smask <= "11";

                    when x"AA" | x"AE" => instr_tdata.sreg <= AX; instr_tdata.smask <= "01";
                    when x"AB" | x"AF" => instr_tdata.sreg <= AX; instr_tdata.smask <= "11";

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
                        if (byte0(WIDTH_BIT) = TO_REG) then

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

                        if (byte0(WIDTH_BIT) = TO_REG) then

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
                            when "000" | "001" =>
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
                            when x"E2" =>
                                instr_tdata.data <= x"FFFF";
                            when x"0E" | x"1E" | x"16" | x"06" =>
                                instr_tdata.data <= x"FFFE";
                            when x"1F" | x"17" | x"07" =>
                                instr_tdata.data <= x"0002";
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
                            -- when x"8F" =>
                            --     if (u8_tdata(5 downto 3) = "000") then
                            --         instr_tdata.data <= x"0002";
                            --     end if;

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
                                    -- when "110" => instr_tdata.data <= x"FFFE";
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
