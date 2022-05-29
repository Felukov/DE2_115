
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

entity cpu86_exec_mexec_mul is
    port (
        clk             : in std_logic;
        resetn          : in std_logic;

        req_s_tvalid    : in std_logic;
        req_s_tdata     : in mul_req_t;

        res_m_tvalid    : out std_logic;
        res_m_tdata     : out mul_res_t;
        res_m_tuser     : out std_logic_vector(15 downto 0)
    );
end entity cpu86_exec_mexec_mul;

architecture rtl of cpu86_exec_mexec_mul is
    signal mul_0_tvalid         : std_logic;
    signal mul_0_tdata          : mul_req_t;
    signal mul_res_0_tvalid     : std_logic;
    signal mul_res_1_tvalid     : std_logic;
    signal mul_res_2_tvalid     : std_logic;
    signal mul_res_0_tdata      : mul_res_t;
    signal mul_res_1_tdata      : mul_res_t;
    signal mul_res_2_tdata      : mul_res_t;

    signal flags_cf_of          : std_logic;
    signal flags_pf             : std_logic;
    signal flags_sf             : std_logic;
begin

    res_m_tvalid <= mul_res_2_tvalid;
    res_m_tdata <= mul_res_2_tdata;

    res_m_tuser(FLAG_15) <= '0';
    res_m_tuser(FLAG_14) <= '0';
    res_m_tuser(FLAG_13) <= '0';
    res_m_tuser(FLAG_12) <= '0';
    res_m_tuser(FLAG_OF) <= flags_cf_of;
    res_m_tuser(FLAG_DF) <= '0';
    res_m_tuser(FLAG_IF) <= '0';
    res_m_tuser(FLAG_TF) <= '0';
    res_m_tuser(FLAG_SF) <= flags_sf;
    res_m_tuser(FLAG_ZF) <= '0';
    res_m_tuser(FLAG_05) <= '0';
    res_m_tuser(FLAG_AF) <= '0';
    res_m_tuser(FLAG_03) <= '0';
    res_m_tuser(FLAG_PF) <= flags_pf;
    res_m_tuser(FLAG_01) <= '0';
    res_m_tuser(FLAG_CF) <= flags_cf_of;

    process (all) begin

        if (mul_res_2_tdata.w = '1') then
            if (mul_res_2_tdata.dval(31 downto 16) = x"FFFF" and mul_res_2_tdata.dval(15) = '1') or
                (mul_res_2_tdata.dval(31 downto 16) = x"0000" and mul_res_2_tdata.dval(15) = '0') then
                flags_cf_of <= '0';
            else
                flags_cf_of <= '1';
            end if;
        else
            if (mul_res_2_tdata.dval(15 downto 8) = x"FF" and mul_res_2_tdata.dval(7) = '1') or
                (mul_res_2_tdata.dval(15 downto 8) = x"00" and mul_res_2_tdata.dval(7) = '0') then
                flags_cf_of <= '0';
            else
                flags_cf_of <= '1';
            end if;
        end if;

        flags_pf <= not (mul_res_2_tdata.dval(7) xor mul_res_2_tdata.dval(6) xor mul_res_2_tdata.dval(5) xor mul_res_2_tdata.dval(4) xor
                         mul_res_2_tdata.dval(3) xor mul_res_2_tdata.dval(2) xor mul_res_2_tdata.dval(1) xor mul_res_2_tdata.dval(0));

        if res_m_tdata.w = '0' then
            flags_sf <= mul_res_2_tdata.dval(7);
        else
            flags_sf <= mul_res_2_tdata.dval(15);
        end if;

    end process;

    mul_proc : process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                mul_0_tvalid <= '0';
                mul_res_0_tvalid <= '0';
                mul_res_1_tvalid <= '0';
                mul_res_2_tvalid <= '0';
            else
                mul_0_tvalid <= req_s_tvalid;
                mul_res_0_tvalid <= mul_0_tvalid;
                mul_res_1_tvalid <= mul_res_0_tvalid;
                mul_res_2_tvalid <= mul_res_1_tvalid;
            end if;

            mul_0_tdata <= req_s_tdata;

            mul_res_0_tdata.code <= mul_0_tdata.code;
            mul_res_0_tdata.w <= mul_0_tdata.w;
            mul_res_0_tdata.dreg <= mul_0_tdata.dreg;
            mul_res_0_tdata.aval <= mul_0_tdata.aval;
            mul_res_0_tdata.bval <= mul_0_tdata.bval;

            if (mul_0_tdata.code = IMUL_RR or mul_0_tdata.code = IMUL_AXDX) then
                mul_res_0_tdata.dval <= std_logic_vector(signed(mul_0_tdata.aval) * signed(mul_0_tdata.bval));
            else
                mul_res_0_tdata.dval <= std_logic_vector(unsigned(mul_0_tdata.aval) * unsigned(mul_0_tdata.bval));
            end if;

            mul_res_1_tdata <= mul_res_0_tdata;
            mul_res_2_tdata <= mul_res_1_tdata;
        end if;
    end process;


end architecture;
