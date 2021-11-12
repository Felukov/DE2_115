library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.cpu86_types.all;

entity mexec_shf is
    generic (
        DATA_WIDTH      : natural := 16
    );
    port (
        clk             : in std_logic;
        resetn          : in std_logic;

        req_s_tvalid    : in std_logic;
        req_s_tdata     : in shf_req_t;
        req_s_tuser     : in std_logic_vector(15 downto 0);

        res_m_tvalid    : out std_logic;
        res_m_tdata     : out shf_res_t;
        res_m_tuser     : out std_logic_vector(15 downto 0)
    );
end entity mexec_shf;

architecture rtl of mexec_shf is
    signal rval         : std_logic_vector(16 downto 0);
    signal rval_next    : std_logic_vector(16 downto 0);
    signal flags_of     : std_logic;
    signal flags_pf     : std_logic;
    signal flags_zf     : std_logic;
    signal flags_sf     : std_logic;
    signal flags_cf     : std_logic;
    signal ival         : natural range 0 to 32;
begin

    res_m_tuser(FLAG_15) <= '0';
    res_m_tuser(FLAG_14) <= '0';
    res_m_tuser(FLAG_13) <= '0';
    res_m_tuser(FLAG_12) <= '0';
    res_m_tuser(FLAG_OF) <= flags_of;
    res_m_tuser(FLAG_DF) <= '0';
    res_m_tuser(FLAG_IF) <= '0';
    res_m_tuser(FLAG_TF) <= '0';
    res_m_tuser(FLAG_SF) <= flags_sf;
    res_m_tuser(FLAG_ZF) <= flags_zf;
    res_m_tuser(FLAG_05) <= '0';
    res_m_tuser(FLAG_AF) <= '0';
    res_m_tuser(FLAG_03) <= '0';
    res_m_tuser(FLAG_PF) <= flags_pf;
    res_m_tuser(FLAG_01) <= '0';
    res_m_tuser(FLAG_CF) <= flags_cf;

    -- filler_gen: if DATA_WIDTH < 16 generate

    --     res_m_tdata.dval(15 downto DATA_WIDTH) <= (others => '0');

    -- end generate ;

    process (all) begin
        rval_next <= rval;
        case res_m_tdata.code is
            when SHF_OP_ROL =>
                rval_next(DATA_WIDTH downto 0) <= rval(DATA_WIDTH-1 downto 0) & rval(DATA_WIDTH);
            when SHF_OP_ROR =>
                rval_next(DATA_WIDTH downto 0) <= rval(0) & rval(DATA_WIDTH downto 1);
            when SHF_OP_SHL =>
                rval_next(DATA_WIDTH downto 0) <= rval(DATA_WIDTH-1 downto 0) & '0';
            when SHF_OP_SAR =>
                rval_next(DATA_WIDTH downto 0) <= rval(0) & rval(DATA_WIDTH-1) & rval(DATA_WIDTH-1 downto 1);
            when others => -- SHF_OP_SHR
                rval_next(DATA_WIDTH downto 0) <= rval(0) & '0' & rval(DATA_WIDTH-1 downto 1);
        end case;
    end process;

    shf_proc : process (clk) begin

        if rising_edge(clk) then
            if resetn = '0' then
                res_m_tvalid <= '0';
                ival <= 0;
            else

                if (req_s_tvalid = '1') then
                    ival <= to_integer(unsigned(req_s_tdata.ival));
                elsif (ival > 0) then
                    ival <= ival - 1;
                end if;

                if (req_s_tvalid = '1') then
                    if to_integer(unsigned(req_s_tdata.ival)) = 0 then
                        res_m_tvalid <= '1';
                    end if;
                elsif (ival > 0) then
                    if (ival = 1) then
                        res_m_tvalid <= '1';
                    else
                        res_m_tvalid <= '0';
                    end if;
                else
                    res_m_tvalid <= '0';
                end if;

            end if;

            if (req_s_tvalid = '1') then
                res_m_tdata.code <= req_s_tdata.code;
                res_m_tdata.w <= req_s_tdata.w;
                res_m_tdata.wb <= req_s_tdata.wb;
                res_m_tdata.dreg <= req_s_tdata.dreg;
                res_m_tdata.dmask <= req_s_tdata.dmask;
                res_m_tdata.dval <= req_s_tdata.sval;

                for i in 16 downto DATA_WIDTH loop
                    rval(i) <= req_s_tuser(FLAG_CF);
                end loop;

                rval(DATA_WIDTH-1 downto 0) <= req_s_tdata.sval(DATA_WIDTH-1 downto 0);

            elsif (ival > 0) then

                rval <= rval_next;

                flags_pf <= not (rval_next(7) xor rval_next(6) xor rval_next(5) xor rval_next(4) xor
                    rval_next(3) xor rval_next(2) xor rval_next(1) xor rval_next(0));

                if (unsigned(rval_next(DATA_WIDTH-1 downto 0)) = to_unsigned(0, DATA_WIDTH)) then
                    flags_zf <= '1';
                else
                    flags_zf <= '0';
                end if;

                flags_sf <= rval_next(DATA_WIDTH-1);
                flags_cf <= rval_next(DATA_WIDTH);
                res_m_tdata.dval(DATA_WIDTH-1 downto 0) <= rval_next(DATA_WIDTH-1 downto 0);

                case res_m_tdata.code is
                    when SHF_OP_ROL =>
                        if (unsigned(req_s_tdata.ival) = to_unsigned(1, 5)) then
                            if (rval_next(DATA_WIDTH) /= req_s_tuser(FLAG_CF)) then
                                flags_of <= '1';
                            else
                                flags_of <= '0';
                            end if;
                        else
                            flags_of <= req_s_tuser(FLAG_OF);
                        end if;
                    when SHF_OP_ROR =>
                        if (unsigned(req_s_tdata.ival) = to_unsigned(1, 5)) then
                            if (rval_next(DATA_WIDTH-1) /= rval_next(0)) then
                                flags_of <= '1';
                            else
                                flags_of <= '0';
                            end if;
                        else
                            flags_of <= req_s_tuser(FLAG_OF);
                        end if;
                    when SHF_OP_SHL =>
                        if (unsigned(req_s_tdata.ival) = to_unsigned(1, 5)) then
                            if (rval_next(DATA_WIDTH) /= req_s_tuser(FLAG_CF)) then
                                flags_of <= '1';
                            else
                                flags_of <= '0';
                            end if;
                        else
                            flags_of <= req_s_tuser(FLAG_OF);
                        end if;
                    when SHF_OP_SAR =>
                        flags_of <= '0';
                    when SHF_OP_SHR =>
                        if (unsigned(req_s_tdata.ival) = to_unsigned(1, 5)) then
                            if (rval_next(DATA_WIDTH) /= req_s_tuser(FLAG_CF)) then
                                flags_of <= '1';
                            else
                                flags_of <= '0';
                            end if;
                        else
                            flags_of <= req_s_tuser(FLAG_OF);
                        end if;
                    when others => null;
                end case;

            end if;

        end if;

    end process;

end architecture;
