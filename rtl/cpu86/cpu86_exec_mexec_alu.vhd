
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

entity cpu86_exec_mexec_alu is
    port (
        clk                 : in std_logic;
        resetn              : in std_logic;

        req_s_tvalid        : in std_logic;
        req_s_tdata         : in alu_req_t;
        req_s_tuser         : in std_logic;

        res_m_tvalid        : out std_logic;
        res_m_tdata         : out alu_res_t;
        res_m_tuser         : out std_logic_vector(15 downto 0)
    );
end entity cpu86_exec_mexec_alu;

architecture rtl of cpu86_exec_mexec_alu is
    signal carry            : std_logic_vector(16 downto 0);
    signal add_next         : std_logic_vector(16 downto 0);
    signal sub_next         : std_logic_vector(16 downto 0);
    signal adc_next         : std_logic_vector(16 downto 0);
    signal sbb_next         : std_logic_vector(16 downto 0);
    signal and_next         : std_logic_vector(15 downto 0);
    signal or_next          : std_logic_vector(15 downto 0);
    signal xor_next         : std_logic_vector(15 downto 0);
    signal res_tdata_next   : alu_res_t;

    signal flags_cf         : std_logic;
    signal flags_pf         : std_logic;
    signal flags_zf         : std_logic;
    signal flags_of         : std_logic;
    signal flags_sf         : std_logic;
    signal flags_af         : std_logic;
begin

    add_next <= std_logic_vector(unsigned('0' & req_s_tdata.aval) + unsigned('0' & req_s_tdata.bval));
    sub_next <= std_logic_vector(unsigned('0' & req_s_tdata.aval) - unsigned('0' & req_s_tdata.bval));
    carry(16 downto 1) <= (others => '0');
    carry(0) <= req_s_tuser;
    adc_next <= std_logic_vector(unsigned(add_next) + unsigned(carry));
    sbb_next <= std_logic_vector(unsigned(sub_next) - unsigned(carry));
    and_next <= req_s_tdata.aval and req_s_tdata.bval;
    or_next  <= req_s_tdata.aval or  req_s_tdata.bval;
    xor_next <= req_s_tdata.aval xor req_s_tdata.bval;

    alu_res_next_proc: process (all) begin
        res_tdata_next.wb <= req_s_tdata.wb;
        res_tdata_next.code <= req_s_tdata.code;
        res_tdata_next.w <= req_s_tdata.w;
        res_tdata_next.dreg <= req_s_tdata.dreg;
        res_tdata_next.dmask <= req_s_tdata.dmask;
        res_tdata_next.upd_fl <= req_s_tdata.upd_fl;
        res_tdata_next.aval <= req_s_tdata.aval;
        res_tdata_next.bval <= req_s_tdata.bval;
        case (req_s_tdata.code) is
            when ALU_OP_ADC =>
                res_tdata_next.dval <= adc_next(15 downto 0);
                res_tdata_next.rval <= adc_next;
            when ALU_OP_AND =>
                res_tdata_next.dval <= and_next(15 downto 0);
                res_tdata_next.rval(15 downto 0) <= and_next;
                res_tdata_next.rval(16) <= '0';
            when ALU_OP_TST =>
                res_tdata_next.dval <= req_s_tdata.aval;
                res_tdata_next.rval(15 downto 0) <= and_next;
                res_tdata_next.rval(16) <= '0';
            when ALU_OP_OR =>
                res_tdata_next.dval <= or_next(15 downto 0);
                res_tdata_next.rval(15 downto 0) <= or_next;
                res_tdata_next.rval(16) <= '0';
            when ALU_OP_XOR =>
                res_tdata_next.dval <= xor_next;
                res_tdata_next.rval(15 downto 0) <= xor_next;
                res_tdata_next.rval(16) <= '0';
            when ALU_OP_SUB | ALU_OP_DEC =>
                res_tdata_next.dval <= sub_next(15 downto 0);
                res_tdata_next.rval <= sub_next;
            when ALU_OP_SBB =>
                res_tdata_next.dval <= sbb_next(15 downto 0);
                res_tdata_next.rval <= sbb_next;
            when ALU_OP_CMP =>
                res_tdata_next.dval <= req_s_tdata.aval;
                res_tdata_next.rval <= sub_next;
            when others =>
                res_tdata_next.dval <= add_next(15 downto 0);
                res_tdata_next.rval <= add_next;
        end case;
    end process;

    alu_res_proc : process (clk) begin
        if rising_edge(clk) then
            if (resetn = '0') then
                res_m_tvalid <= '0';
            else
                res_m_tvalid <= req_s_tvalid;
            end if;

            res_m_tdata <= res_tdata_next;
        end if;
    end process;

    flag_calc_proc : process (all) begin

        flags_pf <= not (res_m_tdata.rval(7) xor res_m_tdata.rval(6) xor res_m_tdata.rval(5) xor res_m_tdata.rval(4) xor
                         res_m_tdata.rval(3) xor res_m_tdata.rval(2) xor res_m_tdata.rval(1) xor res_m_tdata.rval(0));
        flags_af <= res_m_tdata.aval(4) xor res_m_tdata.bval(4) xor res_m_tdata.rval(4);

        case res_m_tdata.code is
            when ALU_OP_AND | ALU_OP_OR | ALU_OP_XOR | ALU_OP_TST =>
                flags_af <= '0';
            when others =>
                flags_af <= res_m_tdata.aval(4) xor res_m_tdata.bval(4) xor res_m_tdata.rval(4);
        end case;

        if res_m_tdata.w = '0' then
            if (res_m_tdata.rval(7 downto 0) = x"00") then
                flags_zf <= '1';
            else
                flags_zf <= '0';
            end if;
        else
            if (res_m_tdata.rval(15 downto 0) = x"0000") then
                flags_zf <= '1';
            else
                flags_zf <= '0';
            end if;
        end if;

        if res_m_tdata.w = '0' then
            flags_sf <= res_m_tdata.rval(7);
        else
            flags_sf <= res_m_tdata.rval(15);
        end if;

        case res_m_tdata.code is
            when ALU_OP_AND | ALU_OP_OR | ALU_OP_XOR | ALU_OP_TST =>
                flags_cf <= '0';
            when others =>
                --ALU_OP_ADD | ALU_OP_SUB
                if res_m_tdata.w = '0' then
                    flags_cf <= res_m_tdata.aval(8) xor res_m_tdata.bval(8) xor res_m_tdata.rval(8);
                else
                    flags_cf <= res_m_tdata.rval(16);
                end if;
        end case;

        case res_m_tdata.code is
            when ALU_OP_AND | ALU_OP_OR | ALU_OP_XOR | ALU_OP_TST =>
                flags_of <= '0';

            when ALU_OP_SUB | ALU_OP_DEC | ALU_OP_SBB | ALU_OP_CMP =>
                if res_m_tdata.w = '0' then
                    flags_of <= (res_m_tdata.aval(7) xor res_m_tdata.bval(7)) and (res_m_tdata.rval(7) xor res_m_tdata.aval(7));
                else
                    flags_of <= (res_m_tdata.aval(15) xor res_m_tdata.bval(15)) and (res_m_tdata.rval(15) xor res_m_tdata.aval(15));
                end if;

            when others => --ALU_OP_ADD
                if res_m_tdata.w = '0' then
                    flags_of <= not (res_m_tdata.aval(7) xor res_m_tdata.bval(7)) and (res_m_tdata.rval(7) xor res_m_tdata.aval(7));
                else
                    flags_of <= not (res_m_tdata.aval(15) xor res_m_tdata.bval(15)) and (res_m_tdata.rval(15) xor res_m_tdata.aval(15));
                end if;

        end case;

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
    end process;

end architecture;
