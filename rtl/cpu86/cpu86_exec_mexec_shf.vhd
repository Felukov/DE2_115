
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
use work.cpu86_types.all;

entity cpu86_exec_mexec_shf is
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
end entity cpu86_exec_mexec_shf;

architecture rtl of cpu86_exec_mexec_shf is
    signal sval         : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal rval         : std_logic_vector(16 downto 0);
    signal rval_next    : std_logic_vector(16 downto 0);
    signal use_of_1     : std_logic;
    signal flags_of_1   : std_logic;
    signal flags_of_n   : std_logic;
    signal flags_of     : std_logic;
    signal flags_pf     : std_logic;
    signal flags_zf     : std_logic;
    signal flags_sf     : std_logic;
    signal flags_cf     : std_logic;
    signal shf_cnt      : natural range 0 to 32;
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

    process (all) begin
        rval_next <= rval;
        case res_m_tdata.code is
            when SHF_OP_ROL =>
                rval_next(DATA_WIDTH downto 0) <= rval(DATA_WIDTH-1 downto 0) & rval(DATA_WIDTH-1);
            when SHF_OP_RCL =>
                rval_next(DATA_WIDTH downto 0) <= rval(DATA_WIDTH-1 downto 0) & rval(DATA_WIDTH);
            when SHF_OP_ROR =>
                rval_next(DATA_WIDTH downto 0) <= rval(0) & rval(0) & rval(DATA_WIDTH-1 downto 1);
            when SHF_OP_RCR =>
                rval_next(DATA_WIDTH downto 0) <= rval(0) & rval(DATA_WIDTH downto 1);
            when SHF_OP_SHL =>
                rval_next(DATA_WIDTH downto 0) <= rval(DATA_WIDTH-1 downto 0) & '0';
            when SHF_OP_SAR =>
                rval_next(DATA_WIDTH downto 0) <= rval(0) & rval(DATA_WIDTH-1) & rval(DATA_WIDTH-1 downto 1);
            when others => -- SHF_OP_SHR
                rval_next(DATA_WIDTH downto 0) <= rval(0) & '0' & rval(DATA_WIDTH-1 downto 1);
        end case;
    end process;

    flags_proc : process (all) begin

        flags_pf <= not (rval(7) xor rval(6) xor rval(5) xor rval(4) xor
            rval(3) xor rval(2) xor rval(1) xor rval(0));

        if (unsigned(rval(DATA_WIDTH-1 downto 0)) = to_unsigned(0, DATA_WIDTH)) then
            flags_zf <= '1';
        else
            flags_zf <= '0';
        end if;

        flags_sf <= rval(DATA_WIDTH-1);
        flags_cf <= rval(DATA_WIDTH);

        flags_of_1 <= rval(DATA_WIDTH-1) xor sval(DATA_WIDTH-1);

        if (use_of_1 = '1') then
            flags_of <= flags_of_1;
        else
            flags_of <= flags_of_n;
        end if;

    end process;

    shf_proc : process (clk) begin

        if rising_edge(clk) then
            if resetn = '0' then
                res_m_tvalid <= '0';
                shf_cnt <= 0;
                use_of_1 <= '0';
                flags_of_n <= '0';
            else

                if (req_s_tvalid = '1') then
                    shf_cnt <= to_integer(unsigned(req_s_tdata.ival(4 downto 0)));
                elsif (shf_cnt > 0) then
                    shf_cnt <= shf_cnt - 1;
                end if;

                if (req_s_tvalid = '1') then
                    case res_m_tdata.code is
                        when SHF_OP_ROL | SHF_OP_ROR | SHF_OP_RCR | SHF_OP_RCL =>
                            if (req_s_tdata.ival(4 downto 0) = "0001") then
                                use_of_1 <= '1';
                            else
                                use_of_1 <= '0';
                            end if;
                        when others =>
                            use_of_1 <= '1';
                    end case;
                end if;

                if (req_s_tvalid = '1') then
                    case res_m_tdata.code is
                        when SHF_OP_ROR =>
                            flags_of_n <= req_s_tdata.sval(DATA_WIDTH-1) xor req_s_tdata.sval(0);
                        when SHF_OP_RCR =>
                            if req_s_tdata.sval(DATA_WIDTH-1) = '0' then
                                flags_of_n <= req_s_tuser(FLAG_OF);
                            else
                                flags_of_n <= not req_s_tuser(FLAG_OF);
                            end if;
                        when SHF_OP_ROL | SHF_OP_RCL =>
                            flags_of_n <= req_s_tdata.sval(DATA_WIDTH-2) xor req_s_tdata.sval(DATA_WIDTH-1);
                        when others => null;
                    end case;
                end if;

                if (req_s_tvalid = '1') then
                    sval <= req_s_tdata.sval(DATA_WIDTH-1 downto 0);
                end if;

                if (req_s_tvalid = '1') then
                    if to_integer(unsigned(req_s_tdata.ival(4 downto 0))) = 0 then
                        res_m_tvalid <= '1';
                    end if;
                elsif (shf_cnt > 0) then
                    if (shf_cnt = 1) then
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

            elsif (shf_cnt > 0) then

                rval <= rval_next;

                res_m_tdata.dval(DATA_WIDTH-1 downto 0) <= rval_next(DATA_WIDTH-1 downto 0);

            end if;

        end if;

    end process;

end architecture;
