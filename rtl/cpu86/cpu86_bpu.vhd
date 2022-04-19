
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

entity cpu86_bpu is
    port (
        clk                 : in std_logic;
        resetn              : in std_logic;

        instr_s_tvalid      : in std_logic;
        instr_s_tready      : out std_logic;
        instr_s_tdata       : in decoded_instr_t;
        instr_s_tuser       : in user_t;

        instr_m_tvalid      : out std_logic;
        instr_m_tready      : in std_logic;
        instr_m_tdata       : out decoded_instr_t;
        instr_m_tuser       : out user_t;

        jump_s_tvalid       : in std_logic;
        jump_s_tdata        : in std_logic_vector(31 downto 0);

        jump_m_tvalid       : out std_logic;
        jump_m_tdata        : out std_logic_vector(31 downto 0)
    );
end entity cpu86_bpu;

architecture rtl of cpu86_bpu is

    type bpu_item_t is record
        inst_op             : op_t;
        inst_code           : std_logic_vector(3 downto 0);
        inst_cs             : std_logic_vector(15 downto 0);
        inst_ip             : std_logic_vector(15 downto 0);
        jump_cs             : std_logic_vector(15 downto 0);
        jump_ip             : std_logic_vector(15 downto 0);
    end record;

begin

    instr_s_tready <= '1' when jump_s_tvalid = '0' and jump_m_tvalid = '0' and (instr_m_tvalid = '0' or (instr_m_tvalid = '1' and instr_m_tready = '1')) else '0';

    process (clk) begin
        if rising_edge(clk) then
            -- resettable logic
            if resetn = '0' then
                instr_m_tvalid <= '0';
            else
                if (jump_s_tvalid = '1') then
                    instr_m_tvalid <= '0';
                elsif (instr_s_tvalid = '1' and instr_s_tready = '1') then
                    instr_m_tvalid <= '1';
                elsif (instr_m_tready = '1') then
                    instr_m_tvalid <= '0';
                end if;
            end if;
            --without reset
            if (instr_s_tvalid = '1' and instr_s_tready = '1') then
                instr_m_tdata <= instr_s_tdata;
                instr_m_tuser <= instr_s_tuser;
            end if;
        end if;
    end process;

    process (clk) begin
        if rising_edge(clk) then
            -- resettable logic
            if resetn = '0' then
                jump_m_tvalid <= '0';
            else
                if ((jump_s_tvalid = '1') or
                    (instr_s_tvalid = '1' and instr_s_tready = '1' and instr_s_tdata.op = JMPU  and instr_s_tdata.code(3) = '0') or
                    (instr_s_tvalid = '1' and instr_s_tready = '1' and instr_s_tdata.op = JCALL and instr_s_tdata.code(3) = '0'))
                then
                    jump_m_tvalid <= '1';
                else
                    jump_m_tvalid <= '0';
                end if;
            end if;
            -- without reset
            if (jump_s_tvalid = '1') then
                jump_m_tdata <= jump_s_tdata;
            elsif (instr_s_tvalid = '1' and instr_s_tready = '1' and (instr_s_tdata.op = JMPU or instr_s_tdata.op = JCALL)) then
                if (instr_s_tdata.code = JMP_PTR16_16 or instr_s_tdata.code = CALL_PTR16_16) then
                    jump_m_tdata(31 downto 16) <= instr_s_tdata.data;
                    jump_m_tdata(15 downto 0)  <= instr_s_tdata.disp;
                else
                    jump_m_tdata(31 downto 16) <= instr_s_tuser(31 downto 16);
                    jump_m_tdata(15 downto 0)  <= std_logic_vector(unsigned(instr_s_tuser(15 downto 0)) + unsigned(instr_s_tdata.disp));
                end if;
            end if;
        end if;
    end process;

end architecture;
