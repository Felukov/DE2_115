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

    constant WIDTH_BIT : integer := 1;
    constant TO_RM : std_logic := '0';
    constant TO_REG : std_logic := '1';

    type byte_pos_t is (
        first_byte,     --0000
        mod_reg_rm,     --0001
        mod_sreg_rm,    --0010
        mod_aux_rm,     --0011
        data8,          --0100
        data_low,       --0101
        data_high,      --0110
        disp8,          --1000
        disp_low,       --1001
        disp_high       --1010
    );

    attribute enum_encoding : string;
    attribute enum_encoding of byte_pos_t : type is "0000 0001 0010 0011 0100 0101 0110 1000 1001 1010";

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

    process (clk) begin
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
                                     x"87" | x"89" | x"8A" | x"8B" | x"8D" | x"C4" | x"C5" =>
                                    byte_pos_chain(0) <= mod_reg_rm;
                                    byte_pos_chain(1) <= disp_low;
                                    byte_pos_chain(2) <= disp_high;
                                    byte_pos_chain(3) <= first_byte;
                                    instr_tvalid <= '0';

                                when x"C0" | x"C1" | x"D0" | x"D1" | x"D2" | x"D3" | x"D8" | x"D9" | x"DA" | x"DB" |
                                     x"DC" | x"DD" | x"DE" | x"DF" | x"FE" | x"FF" | x"8F" =>
                                    byte_pos_chain(0) <= mod_aux_rm;
                                    byte_pos_chain(1) <= disp_low;
                                    byte_pos_chain(2) <= disp_high;
                                    byte_pos_chain(3) <= first_byte;
                                    instr_tvalid <= '0';

                                when x"F6" | x"C6" =>
                                    byte_pos_chain(0) <= mod_aux_rm;
                                    byte_pos_chain(1) <= disp_low;
                                    byte_pos_chain(2) <= disp_high;
                                    byte_pos_chain(3) <= data8;
                                    byte_pos_chain(4) <= first_byte;
                                    instr_tvalid <= '0';

                                when x"6B" =>
                                    byte_pos_chain(0) <= mod_reg_rm;
                                    byte_pos_chain(1) <= disp_low;
                                    byte_pos_chain(2) <= disp_high;
                                    byte_pos_chain(3) <= data8;
                                    byte_pos_chain(4) <= first_byte;
                                    instr_tvalid <= '0';

                                when x"F7" | x"C7" =>
                                    byte_pos_chain(0) <= mod_aux_rm;
                                    byte_pos_chain(1) <= disp_low;
                                    byte_pos_chain(2) <= disp_high;
                                    byte_pos_chain(3) <= data_low;
                                    byte_pos_chain(4) <= data_high;
                                    byte_pos_chain(5) <= first_byte;
                                    instr_tvalid <= '0';

                                when x"69" =>
                                    byte_pos_chain(0) <= mod_reg_rm;
                                    byte_pos_chain(1) <= disp_low;
                                    byte_pos_chain(2) <= disp_high;
                                    byte_pos_chain(3) <= data_low;
                                    byte_pos_chain(4) <= data_high;
                                    byte_pos_chain(5) <= first_byte;
                                    instr_tvalid <= '0';

                                when x"8C" | x"8E" =>
                                    byte_pos_chain(0) <= mod_sreg_rm;
                                    byte_pos_chain(1) <= disp_low;
                                    byte_pos_chain(2) <= disp_high;
                                    byte_pos_chain(3) <= first_byte;
                                    instr_tvalid <= '0';

                                when x"06" | x"07" | x"0E" | x"0F" | x"16" | x"17" | x"1E" | x"1F" | x"26" | x"2E" | x"2F" | x"C3" |
                                     x"36" | x"37" | x"3E" | x"3F" | x"41" | x"42" | x"43" | x"44" | x"45" | x"46" | x"47" | x"48" |
                                     x"49" | x"4A" | x"4B" | x"4C" | x"4D" | x"4E" | x"4F" | x"50" | x"51" | x"52" | x"53" | x"54" |
                                     x"55" | x"56" | x"57" | x"58" | x"59" | x"5A" | x"5B" | x"5C" | x"5D" | x"5E" | x"5F" | x"60" |
                                     x"61" | x"63" | x"64" | x"65" | x"66" | x"67" | x"6C" | x"6D" | x"6E" | x"6F" | x"90" | x"91" |
                                     x"92" | x"93" | x"94" | x"95" | x"96" | x"97" | x"98" | x"99" | x"9B" | x"9C" | x"9D" | x"9E" |
                                     x"9F" | x"A4" | x"A5" | x"A6" | x"A7" | x"AA" | x"AB" | x"AC" | x"AD" | x"AE" | x"AF" | x"CB" |
                                     x"C9" | x"CC" | x"CE" | x"CF" | x"F8" | x"F9" | x"FA" | x"FB" | x"FC" | x"FD" =>
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

                                when x"C8" =>
                                    byte_pos_chain(0) <= data_low;
                                    byte_pos_chain(1) <= data_high;
                                    byte_pos_chain(2) <= data8;
                                    byte_pos_chain(3) <= first_byte;
                                    instr_tvalid <= '0';

                                when x"EA" =>
                                    byte_pos_chain(0) <= disp_low;
                                    byte_pos_chain(1) <= disp_high;
                                    byte_pos_chain(2) <= data_low;
                                    byte_pos_chain(3) <= data_high;
                                    byte_pos_chain(4) <= first_byte;
                                    instr_tvalid <= '0';

                                when x"A0" | x"A1" | x"A2" | x"A3" | x"E8" | x"E9" =>
                                    byte_pos_chain(0) <= disp_low;
                                    byte_pos_chain(1) <= disp_high;
                                    byte_pos_chain(2) <= first_byte;
                                    instr_tvalid <= '0';

                                when others =>
                                    null;
                            end case;

                        when mod_aux_rm | mod_reg_rm | mod_sreg_rm =>

                            case u8_tdata(7 downto 6) is
                                when "11" =>
                                    byte_pos_chain(0) <= first_byte;
                                    instr_tvalid <= '1';
                                when "00" =>
                                    if (u8_tdata(2 downto 0) = "110") then
                                        byte_pos_chain(0) <= byte_pos_chain(1);
                                        byte_pos_chain(1) <= byte_pos_chain(2);
                                        byte_pos_chain(2) <= byte_pos_chain(3);
                                        byte_pos_chain(3) <= byte_pos_chain(4);
                                        byte_pos_chain(4) <= byte_pos_chain(5);
                                        instr_tvalid <= '0';
                                    else
                                        byte_pos_chain(0) <= first_byte;
                                        instr_tvalid <= '1';
                                    end if;
                                when "01" =>
                                    -- load disp_low
                                    byte_pos_chain(0) <= byte_pos_chain(1);
                                    -- and skip disp_high
                                    byte_pos_chain(1) <= byte_pos_chain(3);
                                    byte_pos_chain(2) <= byte_pos_chain(4);
                                    byte_pos_chain(3) <= byte_pos_chain(5);
                                    instr_tvalid <= '0';

                                when "10" =>
                                    byte_pos_chain(0) <= byte_pos_chain(1);
                                    byte_pos_chain(1) <= byte_pos_chain(2);
                                    byte_pos_chain(2) <= byte_pos_chain(3);
                                    byte_pos_chain(3) <= byte_pos_chain(4);
                                    byte_pos_chain(4) <= byte_pos_chain(5);
                                    instr_tvalid <= '0';
                                when others =>
                                    null;

                            end case;

                        when data8 =>
                            byte_pos_chain(0) <= byte_pos_chain(1);
                            byte_pos_chain(1) <= byte_pos_chain(2);
                            byte_pos_chain(2) <= byte_pos_chain(3);
                            byte_pos_chain(3) <= byte_pos_chain(4);
                            byte_pos_chain(4) <= byte_pos_chain(5);

                            if (byte_pos_chain(1) = first_byte) then
                                instr_tvalid <= '1';
                            else
                                instr_tvalid <= '0';
                            end if;

                        when data_low =>
                            byte_pos_chain(0) <= byte_pos_chain(1);
                            byte_pos_chain(1) <= byte_pos_chain(2);
                            byte_pos_chain(2) <= byte_pos_chain(3);
                            byte_pos_chain(3) <= byte_pos_chain(4);
                            byte_pos_chain(4) <= byte_pos_chain(5);

                            if (byte_pos_chain(1) = first_byte) then
                                instr_tvalid <= '1';
                            else
                                instr_tvalid <= '0';
                            end if;

                        when data_high =>
                            byte_pos_chain(0) <= byte_pos_chain(1);
                            byte_pos_chain(1) <= byte_pos_chain(2);
                            byte_pos_chain(2) <= byte_pos_chain(3);
                            byte_pos_chain(3) <= byte_pos_chain(4);
                            byte_pos_chain(4) <= byte_pos_chain(5);

                            if (byte_pos_chain(1) = first_byte) then
                                instr_tvalid <= '1';
                            else
                                instr_tvalid <= '0';
                            end if;

                        when disp8 =>
                            byte_pos_chain(0) <= byte_pos_chain(1);
                            byte_pos_chain(1) <= byte_pos_chain(2);
                            byte_pos_chain(2) <= byte_pos_chain(3);
                            byte_pos_chain(3) <= byte_pos_chain(4);
                            byte_pos_chain(4) <= byte_pos_chain(5);

                            if (byte_pos_chain(1) = first_byte) then
                                instr_tvalid <= '1';
                            else
                                instr_tvalid <= '0';
                            end if;

                        when disp_low =>
                            byte_pos_chain(0) <= byte_pos_chain(1);
                            byte_pos_chain(1) <= byte_pos_chain(2);
                            byte_pos_chain(2) <= byte_pos_chain(3);
                            byte_pos_chain(3) <= byte_pos_chain(4);
                            byte_pos_chain(4) <= byte_pos_chain(5);

                            if (byte_pos_chain(1) = first_byte) then
                                instr_tvalid <= '1';
                            else
                                instr_tvalid <= '0';
                            end if;

                        when disp_high =>
                            if ((byte0 = x"F6" or byte0 = x"F7") and byte1(5 downto 3) /= "000") then
                                byte_pos_chain(0) <= first_byte;
                                instr_tvalid <= '1';
                            else
                                byte_pos_chain(0) <= byte_pos_chain(1);
                                byte_pos_chain(1) <= byte_pos_chain(2);
                                byte_pos_chain(2) <= byte_pos_chain(3);
                                byte_pos_chain(3) <= byte_pos_chain(4);
                                byte_pos_chain(4) <= byte_pos_chain(5);

                                if (byte_pos_chain(1) = first_byte) then
                                    instr_tvalid <= '1';
                                else
                                    instr_tvalid <= '0';
                                end if;
                            end if;

                        when others =>

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

    process (clk) begin
        if rising_edge(clk) then

            if (u8_tvalid = '1' and u8_tready = '1' and byte_pos_chain(0) = first_byte) then

                case u8_tdata is
                    when x"00" =>
                        instr_tdata.op <= ALU;
                        instr_tdata.code <= ALU_OP_ADD;
                        instr_tdata.w <= '0';
                    when x"01" =>
                        instr_tdata.op <= ALU;
                        instr_tdata.code <= ALU_OP_ADD;
                        instr_tdata.w <= '1';
                    when x"02" =>
                        instr_tdata.op <= ALU;
                        instr_tdata.code <= ALU_OP_ADD;
                        instr_tdata.w <= '0';
                    when x"03" =>
                        instr_tdata.op <= ALU;
                        instr_tdata.code <= ALU_OP_ADD;
                        instr_tdata.w <= '1';
                    when x"04" =>
                        instr_tdata.op <= ALU;
                        instr_tdata.code <= ALU_OP_ADD;
                        instr_tdata.w <= '0';
                    when x"05" =>
                        instr_tdata.op <= ALU;
                        instr_tdata.code <= ALU_OP_ADD;
                        instr_tdata.w <= '1';

                    when x"08" =>
                        instr_tdata.op <= ALU;
                        instr_tdata.code <= ALU_OP_OR;
                        instr_tdata.w <= '0';
                    when x"09" =>
                        instr_tdata.op <= ALU;
                        instr_tdata.code <= ALU_OP_OR;
                        instr_tdata.w <= '1';
                    when x"0A" =>
                        instr_tdata.op <= ALU;
                        instr_tdata.code <= ALU_OP_OR;
                        instr_tdata.w <= '0';
                    when x"0B" =>
                        instr_tdata.op <= ALU;
                        instr_tdata.code <= ALU_OP_OR;
                        instr_tdata.w <= '1';
                    when x"0C" =>
                        instr_tdata.op <= ALU;
                        instr_tdata.code <= ALU_OP_OR;
                        instr_tdata.w <= '0';
                    when x"0D" =>
                        instr_tdata.op <= ALU;
                        instr_tdata.code <= ALU_OP_OR;
                        instr_tdata.w <= '1';

                    when x"10" =>
                        instr_tdata.op <= ALU;
                        instr_tdata.code <= ALU_OP_ADC;
                        instr_tdata.w <= '0';
                    when x"11" =>
                        instr_tdata.op <= ALU;
                        instr_tdata.code <= ALU_OP_ADC;
                        instr_tdata.w <= '1';
                    when x"12" =>
                        instr_tdata.op <= ALU;
                        instr_tdata.code <= ALU_OP_ADC;
                        instr_tdata.w <= '0';
                    when x"13" =>
                        instr_tdata.op <= ALU;
                        instr_tdata.code <= ALU_OP_ADC;
                        instr_tdata.w <= '1';
                    when x"14" =>
                        instr_tdata.op <= ALU;
                        instr_tdata.code <= ALU_OP_ADC;
                        instr_tdata.w <= '0';
                    when x"15" =>
                        instr_tdata.op <= ALU;
                        instr_tdata.code <= ALU_OP_ADC;
                        instr_tdata.w <= '1';

                    when x"20" =>
                        instr_tdata.op <= ALU;
                        instr_tdata.code <= ALU_OP_AND;
                        instr_tdata.w <= '0';
                    when x"21" =>
                        instr_tdata.op <= ALU;
                        instr_tdata.code <= ALU_OP_AND;
                        instr_tdata.w <= '1';
                    when x"22" =>
                        instr_tdata.op <= ALU;
                        instr_tdata.code <= ALU_OP_AND;
                        instr_tdata.w <= '0';
                    when x"23" =>
                        instr_tdata.op <= ALU;
                        instr_tdata.code <= ALU_OP_AND;
                        instr_tdata.w <= '1';
                    when x"24" =>
                        instr_tdata.op <= ALU;
                        instr_tdata.code <= ALU_OP_AND;
                        instr_tdata.w <= '0';
                    when x"25" =>
                        instr_tdata.op <= ALU;
                        instr_tdata.code <= ALU_OP_AND;
                        instr_tdata.w <= '1';

                    when x"30" =>
                        instr_tdata.op <= ALU;
                        instr_tdata.code <= ALU_OP_XOR;
                        instr_tdata.w <= '0';
                    when x"31" =>
                        instr_tdata.op <= ALU;
                        instr_tdata.code <= ALU_OP_XOR;
                        instr_tdata.w <= '1';
                    when x"32" =>
                        instr_tdata.op <= ALU;
                        instr_tdata.code <= ALU_OP_XOR;
                        instr_tdata.w <= '0';
                    when x"33" =>
                        instr_tdata.op <= ALU;
                        instr_tdata.code <= ALU_OP_XOR;
                        instr_tdata.w <= '1';
                    when x"34" =>
                        instr_tdata.op <= ALU;
                        instr_tdata.code <= ALU_OP_XOR;
                        instr_tdata.w <= '0';
                    when x"35" =>
                        instr_tdata.op <= ALU;
                        instr_tdata.code <= ALU_OP_XOR;
                        instr_tdata.w <= '1';

                    when x"0E" | x"1E" | x"16" | x"06" =>
                        instr_tdata.op <= STACKU;
                        instr_tdata.code <= STACKU_PUSHR;
                        instr_tdata.w <= '1';

                    when x"1F" | x"17" | x"07" =>
                        instr_tdata.op <= STACKU;
                        instr_tdata.code <= STACKU_POPR;
                        instr_tdata.w <= '1';

                    when x"26" | x"2E" | x"36" | x"3E" =>
                        instr_tdata.op <= SET_SEG;

                    when x"40" | x"41" | x"42" | x"43" | x"44" | x"45" | x"46" | x"47" |
                         x"48" | x"49" | x"4A" | x"4B" | x"4C" | x"4D" | x"4E" | x"4F" =>
                        instr_tdata.op <= ALU;
                        instr_tdata.code <= ALU_OP_INC;

                    when x"50" | x"51" | x"52" | x"53" | x"54" | x"55" | x"56" | x"57" =>
                        instr_tdata.op <= STACKU;
                        instr_tdata.code <= STACKU_PUSHR;
                        instr_tdata.w <= '1';

                    when x"58" | x"59" | x"5A" | x"5B" | x"5C" | x"5D" | x"5E" | x"5F" =>
                        instr_tdata.op <= STACKU;
                        instr_tdata.code <= STACKU_POPR;
                        instr_tdata.w <= '1';

                    when x"60" =>
                        instr_tdata.op <= STACKU;
                        instr_tdata.code <= STACKU_PUSHA;
                        instr_tdata.w <= '1';

                    when x"61" =>
                        instr_tdata.op <= STACKU;
                        instr_tdata.code <= STACKU_POPA;
                        instr_tdata.w <= '1';

                    when x"68" | x"6A" =>
                        instr_tdata.op <= STACKU;
                        instr_tdata.code <= STACKU_PUSHI;
                        instr_tdata.w <= '1';

                    when x"9C" =>
                        instr_tdata.op <= STACKU;
                        instr_tdata.code <= STACKU_PUSHR;
                        instr_tdata.w <= '1';

                    when x"9D" =>
                        instr_tdata.op <= STACKU;
                        instr_tdata.code <= STACKU_POPR;
                        instr_tdata.w <= '1';

                    when x"A0" | x"A2" =>
                        instr_tdata.op <= MOVU;
                        instr_tdata.code <= "0000";
                        instr_tdata.w <= '0';

                    when x"A1" | x"A3" =>
                        instr_tdata.op <= MOVU;
                        instr_tdata.code <= "0000";
                        instr_tdata.w <= '1';

                    when x"89" | x"8B" =>
                        instr_tdata.op <= MOVU;
                        instr_tdata.code <= "0000";
                        instr_tdata.w <= '1';

                    when x"8C" | x"8E" =>
                        instr_tdata.op <= MOVU;
                        instr_tdata.code <= "0000";
                        instr_tdata.w <= '1';

                    when x"88" | x"8A" =>
                        instr_tdata.op <= MOVU;
                        instr_tdata.code <= "0000";
                        instr_tdata.w <= '0';

                    when x"B0" | x"B1" | x"B2" | x"B3" | x"B4" | x"B5" | x"B6" | x"B7" =>
                        instr_tdata.op <= MOVU;
                        instr_tdata.code <= "0000";
                        instr_tdata.w <= '0';

                    when x"B8" | x"B9" | x"BA" | x"BB" | x"BC" | x"BD" | x"BE" | x"BF" =>
                        instr_tdata.op <= MOVU;
                        instr_tdata.code <= "0000";
                        instr_tdata.w <= '1';

                    when x"E2" =>
                        instr_tdata.op <= LOOPU;
                        instr_tdata.code <= LOOP_OP;
                        instr_tdata.w <= '1';

                    when x"F2" =>
                        instr_tdata.op <= REP;
                        instr_tdata.code <= REPNZ_OP;
                        instr_tdata.w <= '1';

                    when x"F3" =>
                        instr_tdata.op <= REP;
                        instr_tdata.code <= REPZ_OP;
                        instr_tdata.w <= '1';

                    when x"A4" =>
                        instr_tdata.op <= STR;
                        instr_tdata.code <= MOVS_OP;
                        instr_tdata.w <= '0';

                    when x"A5" =>
                        instr_tdata.op <= STR;
                        instr_tdata.code <= MOVS_OP;
                        instr_tdata.w <= '1';

                    when x"F8" =>
                        instr_tdata.op <= SET_FLAG;
                        instr_tdata.code <= std_logic_vector(to_unsigned(FLAG_CF, 4));
                        instr_tdata.w <= '0'; --clear flag
                    when x"F9" =>
                        instr_tdata.op <= SET_FLAG;
                        instr_tdata.code <= std_logic_vector(to_unsigned(FLAG_CF, 4));
                        instr_tdata.w <= '1'; --set flag

                    when x"FA" =>
                        instr_tdata.op <= SET_FLAG;
                        instr_tdata.code <= std_logic_vector(to_unsigned(FLAG_IF, 4));
                        instr_tdata.w <= '0'; --clear flag
                    when x"FB" =>
                        instr_tdata.op <= SET_FLAG;
                        instr_tdata.code <= std_logic_vector(to_unsigned(FLAG_IF, 4));
                        instr_tdata.w <= '1'; --set flag

                    when x"FC" =>
                        instr_tdata.op <= SET_FLAG;
                        instr_tdata.code <= std_logic_vector(to_unsigned(FLAG_DF, 4));
                        instr_tdata.w <= '0'; --clear flag
                    when x"FD" =>
                        instr_tdata.op <= SET_FLAG;
                        instr_tdata.code <= std_logic_vector(to_unsigned(FLAG_DF, 4));
                        instr_tdata.w <= '1'; --set flag

                    when others =>
                        instr_tdata.code <= "0000";
                end case;

            elsif (u8_tvalid = '1' and u8_tready = '1' and byte_pos_chain(0) = mod_aux_rm) then

                case byte0 is
                    when x"8F" =>
                        if (u8_tdata(5 downto 3) = "000") then
                            instr_tdata.op <= STACKU;
                            instr_tdata.code <= STACKU_POPM;

                        end if;

                    when x"FE" =>
                        instr_tdata.op <= ALU;
                        instr_tdata.code <= ALU_OP_INC;
                        instr_tdata.w <= '0';

                    when x"FF" =>
                        case u8_tdata(5 downto 3) is
                            when "000" | "001" =>
                                instr_tdata.op <= ALU;
                                instr_tdata.code <= ALU_OP_INC;
                                instr_tdata.w <= '1';
                            when "110" =>
                                instr_tdata.op <= STACKU;
                                instr_tdata.code <= STACKU_PUSHM;
                            when others =>
                                instr_tdata.code <= "0000";
                        end case;

                    when others =>
                        instr_tdata.code <= "0000";
                end case;

            end if;

            if (u8_tvalid = '1' and u8_tready = '1' and byte_pos_chain(0) = first_byte) then

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

                    when x"A0" | x"A1" =>
                        instr_tdata.dir <= M2R;

                    when x"C6" | x"C7" =>
                        instr_tdata.dir <= I2M;

                    when x"A2" | x"A3" =>
                        instr_tdata.dir <= R2M;

                    when x"A4" | x"A5" =>
                        instr_tdata.dir <= STR;

                    when x"F2" | x"F3" =>
                        instr_tdata.dir <= I2R;

                    when x"26" | x"2E" | x"36" | x"3E" =>
                        instr_tdata.dir <= SSEG;

                    when x"F8" | x"F9" | x"FA" | x"FB" | x"FC" | x"FD" =>
                        instr_tdata.dir <= SFLG;

                    when others => null;
                end case;

            elsif (u8_tvalid = '1' and u8_tready = '1' and (byte_pos_chain(0) = mod_reg_rm or byte_pos_chain(0) = mod_sreg_rm)) then

                if (u8_tdata(7 downto 6) = "11") then
                    instr_tdata.dir <= R2R;
                else
                    if byte0(WIDTH_BIT) = TO_RM then
                        instr_tdata.dir <= R2M;
                    else
                        instr_tdata.dir <= M2R;
                    end if;
                end if;

            elsif (u8_tvalid = '1' and u8_tready = '1' and (byte_pos_chain(0) = mod_aux_rm)) then

                case byte0 is
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

            end if;

            if (u8_tvalid = '1' and u8_tready = '1' and byte_pos_chain(0) = first_byte) then

                case u8_s_tdata is
                    when x"A0" | x"A1" | x"A2" | x"A3" => instr_tdata.ea <= DIRECT;
                    when x"A4" | x"A5" => instr_tdata.ea <= SI_DISP;
                    when others => null;
                end case;

            elsif (u8_tvalid = '1' and u8_tready = '1' and (byte_pos_chain(0) = mod_reg_rm or byte_pos_chain(0) = mod_sreg_rm or byte_pos_chain(0) = mod_aux_rm)) then

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

                    when x"9D" | x"9C" =>
                        instr_tdata.dreg <= SP;
                        instr_tdata.dmask <= "11";

                    when x"A0" =>
                        instr_tdata.dreg <= AX;
                        instr_tdata.dmask <= "01";

                    when x"A1" =>
                        instr_tdata.dreg <= AX;
                        instr_tdata.dmask <= "11";

                    when x"A4" | x"A5" =>
                        instr_tdata.dreg <= DI;
                        instr_tdata.dmask <= "11";

                    when x"F2" | x"F3" =>
                        instr_tdata.dreg <= CX;
                        instr_tdata.dmask <= "11";

                    when others => null;

                end case;

            elsif (u8_tvalid = '1' and u8_tready = '1' and byte_pos_chain(0) = mod_sreg_rm) then

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

                    when x"9C" => instr_tdata.sreg <= FL; instr_tdata.smask <= "11";

                    when x"A2" => instr_tdata.sreg <= AX; instr_tdata.smask <= "01";
                    when x"A3" => instr_tdata.sreg <= AX; instr_tdata.smask <= "11";
                    when x"A4" | x"A5" => instr_tdata.sreg <= SI; instr_tdata.smask <= "11";
                    when x"F2" | x"F3" => instr_tdata.sreg <= CX; instr_tdata.smask <= "11";

                    when others => null;
                end case;


            elsif (u8_tvalid = '1' and u8_tready = '1' and byte_pos_chain(0) = mod_sreg_rm) then


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

            if (u8_tvalid = '1' and u8_tready = '1' and byte_pos_chain(0) = first_byte) then
                case (u8_tdata) is
                    when x"40" | x"41" | x"42" | x"43" | x"44" | x"45" | x"46" | x"47" =>
                        instr_tdata.data <= x"0001";
                    when x"48" | x"49" | x"4A" | x"4B" | x"4C" | x"4D" | x"4E" | x"4F" =>
                        instr_tdata.data <= x"FFFF";
                    when x"E2" =>
                        instr_tdata.data <= x"FFFF";
                    when x"0E" | x"1E" | x"16" | x"06" =>
                        instr_tdata.data <= x"FFFE";
                    when x"50" | x"51" | x"52" | x"53" | x"54" | x"55" | x"56" | x"57" =>
                        instr_tdata.data <= x"FFFE";
                    when x"1F" | x"17" | x"07" =>
                        instr_tdata.data <= x"0002";
                    when x"58" | x"59" | x"5A" | x"5B" | x"5C" | x"5D" | x"5E" | x"5F" =>
                        instr_tdata.data <= x"0002";
                    when x"60" =>
                        instr_tdata.data <= x"FFFE";
                    when x"61" =>
                        instr_tdata.data <= x"0002";
                    when others =>
                        null;
                end case;
            elsif (u8_tvalid = '1' and u8_tready = '1' and byte_pos_chain(0) = data8) then
                for i in 15 downto 8 loop
                    instr_tdata.data(i) <= u8_tdata(7);
                end loop;
                instr_tdata.data(7 downto 0) <= u8_tdata;
            elsif (u8_tvalid = '1' and u8_tready = '1' and byte_pos_chain(0) = data_low) then
                for i in 15 downto 8 loop
                    instr_tdata.data(i) <= u8_tdata(7);
                end loop;
                instr_tdata.data(7 downto 0) <= u8_tdata;
            elsif (u8_tvalid = '1' and u8_tready = '1' and byte_pos_chain(0) = data_high) then
                instr_tdata.data(15 downto 8) <= u8_tdata;
            elsif (u8_tvalid = '1' and u8_tready = '1' and byte_pos_chain(0) = mod_aux_rm) then

                case byte0 is
                    when x"8F" =>
                        if (u8_tdata(5 downto 3) = "000") then
                            instr_tdata.data <= x"0002";
                        end if;

                    when x"FE" =>
                        case u8_tdata(5 downto 3) is
                            when "000" => instr_tdata.data <= x"0001";
                            when "001" => instr_tdata.data <= x"FFFF";
                            when others => null;
                        end case;

                    when x"FF" =>
                        case u8_tdata(5 downto 3) is
                            when "000" => instr_tdata.data <= x"0001";
                            when "001" => instr_tdata.data <= x"FFFF";
                            when "110" => instr_tdata.data <= x"FFFE";
                            when others => null;
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

end architecture;
