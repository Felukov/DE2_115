
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

entity cpu86_exec_reg is
    generic (
        DATA_WIDTH      : integer := 16;
        INIT_VALUE      : std_logic_vector
    );
    port (
        clk             : in std_logic;
        resetn          : in std_logic;

        wr_s_tvalid     : in std_logic;
        wr_s_tdata      : in std_logic_vector(DATA_WIDTH-1 downto 0);
        wr_s_tmask      : in std_logic_vector(1 downto 0);

        lock_s_tvalid   : in std_logic;
        unlk_s_tvalid   : in std_logic;

        reg_m_tvalid    : out std_logic;
        reg_m_tdata     : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity cpu86_exec_reg;

architecture rtl of cpu86_exec_reg is

    signal reg_tvalid   : std_logic;
    signal reg_tdata    : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal hs_cnt       : natural range 0 to 7;

begin
    -- Assigns
    reg_m_tvalid <= reg_tvalid;
    reg_m_tdata <= reg_tdata;

    update_reg_proc: process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                reg_tvalid <= '1';
                reg_tdata <= INIT_VALUE;
                hs_cnt <= 0;
            else
                if (unlk_s_tvalid = '1') then
                    reg_tvalid <= '1';
                elsif (wr_s_tvalid = '1') then
                    if (lock_s_tvalid = '0' and (hs_cnt = 1 or hs_cnt = 0)) then
                        reg_tvalid <= '1';
                    end if;
                elsif (lock_s_tvalid = '1') then
                    reg_tvalid <= '0';
                end if;

                if (unlk_s_tvalid = '1') then
                    hs_cnt <= 0;
                elsif (wr_s_tvalid = '1' and lock_s_tvalid = '0') then
                    if (hs_cnt > 0) then
                        hs_cnt <= hs_cnt - 1;
                    -- else
                    --     report "hs_cnt error: " & to_hstring(wr_s_tdata) severity error;
                    end if;
                elsif (wr_s_tvalid = '0' and lock_s_tvalid = '1') then
                    hs_cnt <= hs_cnt + 1;
                else
                    hs_cnt <= hs_cnt;
                end if;

                if (wr_s_tvalid = '1') then
                    case wr_s_tmask is
                        when "11"   => reg_tdata <= wr_s_tdata;
                        when "01"   => reg_tdata(DATA_WIDTH/2-1 downto 0) <= wr_s_tdata(DATA_WIDTH/2-1 downto 0);
                        when "10"   => reg_tdata(DATA_WIDTH-1 downto DATA_WIDTH/2) <= wr_s_tdata(DATA_WIDTH/2-1 downto 0);
                        when others => null;
                    end case;
                end if;
            end if;
        end if;
    end process;

end architecture;
