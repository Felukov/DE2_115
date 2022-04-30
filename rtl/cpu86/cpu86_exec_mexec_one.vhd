
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

entity cpu86_exec_mexec_one is
    port (
        clk             : in std_logic;
        resetn          : in std_logic;

        req_s_tvalid    : in std_logic;
        req_s_tdata     : in one_req_t;

        res_m_tvalid    : out std_logic;
        res_m_tdata     : out one_res_t;
        res_m_tuser     : out std_logic_vector(15 downto 0)
    );
end entity cpu86_exec_mexec_one;

architecture rtl of cpu86_exec_mexec_one is
    signal rval         : std_logic_vector(16 downto 0);
    signal rval_next    : std_logic_vector(16 downto 0);
    signal sval         : std_logic_vector(15 downto 0);
    signal flags_of     : std_logic;
    signal flags_af     : std_logic;
    signal flags_pf     : std_logic;
    signal flags_zf     : std_logic;
    signal flags_sf     : std_logic;
    signal flags_cf     : std_logic;
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
    res_m_tuser(FLAG_AF) <= flags_af;
    res_m_tuser(FLAG_03) <= '0';
    res_m_tuser(FLAG_PF) <= flags_pf;
    res_m_tuser(FLAG_01) <= '0';
    res_m_tuser(FLAG_CF) <= flags_cf;


    process (all) begin
        case req_s_tdata.code is
            when ONE_OP_NOT =>
                rval_next(16) <= '0';
                for i in 15 downto 0 loop
                    rval_next(i) <= not req_s_tdata.sval(i);
                end loop;
            when others =>
                rval_next <= std_logic_vector(unsigned(not req_s_tdata.sval) + to_unsigned(1, 17));
        end case;
    end process;

    process (all) begin

        flags_pf <= not (rval(7) xor rval(6) xor rval(5) xor rval(4) xor
                         rval(3) xor rval(2) xor rval(1) xor rval(0));

        flags_af <= '0' xor sval(4) xor rval(4);

        if res_m_tdata.w = '0' then
            flags_sf <= rval(7);
        else
            flags_sf <= rval(15);
        end if;

        if res_m_tdata.w = '0' then
            if (rval(7 downto 0) = x"00") then
                flags_zf <= '1';
            else
                flags_zf <= '0';
            end if;
        else
            if (rval(15 downto 0) = x"0000") then
                flags_zf <= '1';
            else
                flags_zf <= '0';
            end if;
        end if;

        if res_m_tdata.w = '0' then
            if (rval(7 downto 0) = x"00") then
                flags_cf <= '0';
            else
                flags_cf <= '1';
            end if;
        else
            if (rval(15 downto 0) = x"0000") then
                flags_cf <= '0';
            else
                flags_cf <= '1';
            end if;
        end if;

        if res_m_tdata.w = '0' then
            flags_of <= not rval(8);
        else
            flags_of <= not rval(16);
        end if;

        if res_m_tdata.w = '0' then
            flags_of <= ('0' xor sval(7)) and (rval(7) xor '0');
        else
            flags_of <= ('0' xor sval(15)) and (rval(15) xor '0');
        end if;

    end process;

    one_proc : process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                res_m_tvalid <= '0';
            else
                res_m_tvalid <= req_s_tvalid;
            end if;

            res_m_tdata.code <= req_s_tdata.code;
            res_m_tdata.w <= req_s_tdata.w;
            res_m_tdata.wb <= req_s_tdata.wb;
            res_m_tdata.dreg <= req_s_tdata.dreg;
            res_m_tdata.dmask <= req_s_tdata.dmask;
            res_m_tdata.dval <= rval_next(15 downto 0);

            rval <= rval_next;
            sval <= req_s_tdata.sval;
        end if;
    end process;

end architecture;