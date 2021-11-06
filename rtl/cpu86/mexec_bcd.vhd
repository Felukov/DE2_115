library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.cpu86_types.all;

entity mexec_bcd is
    port (
        clk             : in std_logic;
        resetn          : in std_logic;

        req_s_tvalid    : in std_logic;
        req_s_tdata     : in bcd_req_t;
        req_s_tuser     : in std_logic_vector(15 downto 0);

        res_m_tvalid    : out std_logic;
        res_m_tdata     : out bcd_res_t;
        res_m_tuser     : out std_logic_vector(15 downto 0)
    );
end entity mexec_bcd;

architecture rtl of mexec_bcd is

    signal calc_0_tvalid    : std_logic;
    signal calc_0_tdata     : std_logic_vector(15 downto 0);
    signal calc_0_tuser     : std_logic_vector(15 downto 0);
    signal calc_0_code      : std_logic_vector(3 downto 0);
    signal calc_0_fl_af     : std_logic;
    signal calc_0_fl_cf     : std_logic;
    signal calc_0_al        : std_logic_vector(7 downto 0);

    signal calc_1_tvalid    : std_logic;
    signal calc_1_tdata     : std_logic_vector(15 downto 0);
    signal calc_1_code      : std_logic_vector(3 downto 0);
    signal calc_1_fl_af     : std_logic;
    signal calc_1_fl_cf     : std_logic;

    signal flags_cf         : std_logic;
    signal flags_pf         : std_logic;
    signal flags_zf         : std_logic;
    signal flags_sf         : std_logic;
    signal flags_af         : std_logic;

begin

    calc_proc : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                calc_0_tvalid <= '0';
                calc_1_tvalid <= '0';
            else
                calc_0_tvalid <= req_s_tvalid;
                calc_1_tvalid <= calc_0_tvalid;
            end if;

            calc_0_tuser <= req_s_tuser;
            calc_0_code <= req_s_tdata.code;
            calc_0_al <= req_s_tdata.sval(7 downto 0);
            case req_s_tdata.code is
                when BCDU_AAA =>
                    if (unsigned(req_s_tdata.sval(7 downto 0) and x"0F") > to_unsigned(9, 8)) or
                        (req_s_tuser(FLAG_AF) = '1') then
                        calc_0_tdata <= std_logic_vector(unsigned(req_s_tdata.sval) + to_unsigned(262, 8)) and x"FF0F";
                        calc_0_fl_af <= '1';
                        calc_0_fl_cf <= '1';
                    else
                        calc_0_tdata <= req_s_tdata.sval and x"FF0F";
                        calc_0_fl_af <= '0';
                        calc_0_fl_cf <= '0';
                    end if;

                when BCDU_AAD =>
                    -- AH * 10
                    calc_0_tdata <= std_logic_vector(unsigned("00000" & req_s_tdata.sval(15 downto 8) & "000") + unsigned("0000000" & req_s_tdata.sval(15 downto 8) & "0"));

                when BCDU_AAS =>
                    if (unsigned(req_s_tdata.sval(7 downto 0) and x"0F") > to_unsigned(9, 8)) or
                        (req_s_tuser(FLAG_AF) = '1') then
                        calc_0_tdata(7 downto 0) <= std_logic_vector(unsigned(req_s_tdata.sval(7 downto 0)) - to_unsigned(6, 8)) and x"0F";
                        calc_0_tdata(15 downto 8) <= std_logic_vector(unsigned(req_s_tdata.sval(15 downto 8)) - to_unsigned(1, 8));
                        calc_0_fl_af <= '1';
                        calc_0_fl_cf <= '1';
                    else
                        calc_0_tdata <= req_s_tdata.sval;
                        calc_0_fl_af <= '0';
                        calc_0_fl_cf <= '0';
                    end if;

                when BCDU_DAA =>
                    calc_0_tdata(15 downto 8) <= req_s_tdata.sval(15 downto 8);

                    if (unsigned(req_s_tdata.sval(7 downto 0) and x"0F") > to_unsigned(9, 8)) or
                        (req_s_tuser(FLAG_AF) = '1') then
                        calc_0_tdata(7 downto 0) <= std_logic_vector(unsigned(req_s_tdata.sval(7 downto 0)) + to_unsigned(6, 8));
                        calc_0_fl_af <= '1';
                    else
                        calc_0_tdata(7 downto 0) <= req_s_tdata.sval(7 downto 0);
                        calc_0_fl_af <= '0';
                    end if;

                when BCDU_DAS =>
                    calc_0_tdata(15 downto 8) <= req_s_tdata.sval(15 downto 8);

                    if (unsigned(req_s_tdata.sval(7 downto 0) and x"0F") > to_unsigned(9, 8)) or
                        (req_s_tuser(FLAG_AF) = '1') then
                        calc_0_tdata(7 downto 0) <= std_logic_vector(unsigned(req_s_tdata.sval(7 downto 0)) - to_unsigned(6, 8));
                        calc_0_fl_af <= '1';
                    else
                        calc_0_tdata(7 downto 0) <= req_s_tdata.sval(7 downto 0);
                        calc_0_fl_af <= '0';
                    end if;
                when others =>
                    null;
            end case;

            calc_1_code <= calc_0_code;
            case calc_0_code is
                when BCDU_AAD =>
                    -- AH * 10 + AL
                    calc_1_tdata <= std_logic_vector(unsigned(calc_0_al) + unsigned(calc_0_tdata));
                when BCDU_DAA =>
                    calc_1_tdata(15 downto 8) <= calc_0_tdata(15 downto 8);
                    calc_1_fl_af <= calc_0_fl_af;
                    if unsigned(calc_0_tdata(7 downto 0)) > to_unsigned(159, 8) or
                        (req_s_tuser(FLAG_AF) = '1') then
                        calc_1_tdata(7 downto 0) <= std_logic_vector(unsigned(calc_0_tdata(7 downto 0)) + to_unsigned(96, 8));
                        calc_1_fl_cf <= '1';
                    else
                        calc_1_tdata(7 downto 0) <= calc_0_tdata(7 downto 0);
                        calc_1_fl_cf <= '0';
                    end if;
                when BCDU_DAS =>
                    calc_1_tdata(15 downto 8) <= calc_0_tdata(15 downto 8);
                    calc_1_fl_af <= calc_0_fl_af;
                    if unsigned(calc_0_tdata(7 downto 0)) > to_unsigned(159, 8) or
                        (req_s_tuser(FLAG_AF) = '1') then
                        calc_1_tdata(7 downto 0) <= std_logic_vector(unsigned(calc_0_tdata(7 downto 0)) - to_unsigned(96, 8));
                        calc_1_fl_cf <= '1';
                    else
                        calc_1_tdata(7 downto 0) <= calc_0_tdata(7 downto 0);
                        calc_1_fl_cf <= '0';
                    end if;
                when others =>
                    calc_1_fl_af <= calc_0_fl_af;
                    calc_1_fl_cf <= calc_0_fl_cf;
                    calc_1_tdata <= calc_0_tdata;
            end case;

        end if;
    end process;

    res_forming_proc : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                res_m_tvalid <= '0';
            else
                res_m_tvalid <= calc_1_tvalid;
            end if;

            res_m_tdata.dval <= calc_1_tdata;
            res_m_tdata.dmask <= "11";

            flags_pf <= not (calc_1_tdata(7) xor calc_1_tdata(6) xor calc_1_tdata(5) xor calc_1_tdata(4) xor
                calc_1_tdata(3) xor calc_1_tdata(2) xor calc_1_tdata(1) xor calc_1_tdata(0));

            flags_cf <= calc_1_fl_cf;
            flags_af <= calc_1_fl_af;
            flags_sf <= calc_1_tdata(7);

            if (calc_1_tdata(7 downto 0) = x"00") then
                flags_zf <= '1';
            else
                flags_zf <= '0';
            end if;

        end if;
    end process;

    res_m_tuser(FLAG_15) <= '0';
    res_m_tuser(FLAG_14) <= '0';
    res_m_tuser(FLAG_13) <= '0';
    res_m_tuser(FLAG_12) <= '0';
    res_m_tuser(FLAG_OF) <= '0';
    res_m_tuser(FLAG_DF) <= '0';
    res_m_tuser(FLAG_IF) <= '0';
    res_m_tuser(FLAG_TF) <= '0';
    res_m_tuser(FLAG_SF) <= flags_sf;
    res_m_tuser(FLAG_ZF) <= flags_zf;
    res_m_tuser(FLAG_05) <= '0';
    res_m_tuser(FLAG_AF) <= flags_af;
    res_m_tuser(FLAG_03) <= '0';
    res_m_tuser(FLAG_PF) <= flags_pf;
    res_m_tuser(FLAG_01) <= '0';
    res_m_tuser(FLAG_CF) <= flags_cf;

end architecture;
