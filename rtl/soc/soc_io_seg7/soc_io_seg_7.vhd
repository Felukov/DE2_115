
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

entity soc_io_seg_7 is
    generic (
        INIT_VALUE          : std_logic_vector
    );
    port (
        clk                 : in std_logic;
        resetn              : in std_logic;

        io_req_s_tvalid     : in std_logic;
        io_req_s_tready     : out std_logic;
        io_req_s_tdata      : in std_logic_vector(39 downto 0);
        io_rd_m_tvalid      : out std_logic;
        io_rd_m_tready      : in std_logic;
        io_rd_m_tdata       : out std_logic_vector(15 downto 0);

        HEX0                : out std_logic_vector(6 downto 0);
        HEX1                : out std_logic_vector(6 downto 0);
        HEX2                : out std_logic_vector(6 downto 0);
        HEX3                : out std_logic_vector(6 downto 0)
    );
end entity soc_io_seg_7;

architecture rtl of soc_io_seg_7 is

    component soc_io_seg_7_ff is
        port (
            clk             : in std_logic;
            digit           : in std_logic_vector(3 downto 0);
            segment         : out std_logic_vector(6 downto 0)
        );
    end component;

    signal io_read          : std_logic;
    signal io_write         : std_logic;
    signal hex_data_ff      : std_logic_vector(15 downto 0);
begin

    -- module soc_io_seg_7_ff instantiation
    soc_io_seg_7_ff_hex_0_inst : soc_io_seg_7_ff port map (
        clk         => clk,
        digit       => hex_data_ff(3 downto 0),
        segment     => HEX0
    );

    -- module soc_io_seg_7_ff instantiation
    soc_io_seg_7_ff_hex_1_inst : soc_io_seg_7_ff port map (
        clk         => clk,
        digit       => hex_data_ff(7 downto 4),
        segment     => HEX1
    );

    -- module soc_io_seg_7_ff instantiation
    soc_io_seg_7_ff_hex_2_inst : soc_io_seg_7_ff port map (
        clk         => clk,
        digit       => hex_data_ff(11 downto 8),
        segment     => HEX2
    );

    -- module soc_io_seg_7_ff instantiation
    soc_io_seg_7_ff_hex_3_inst : soc_io_seg_7_ff port map (
        clk         => clk,
        digit       => hex_data_ff(15 downto 12),
        segment     => HEX3
    );

    -- assigns
    io_read         <= '1' when io_req_s_tvalid = '1' and io_req_s_tready = '1' and io_req_s_tdata(32) = '0' else '0';
    io_write        <= '1' when io_req_s_tvalid = '1' and io_req_s_tready = '1' and io_req_s_tdata(32) = '1' else '0';

    io_req_s_tready <= '1';

    -- write process
    write_proc: process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                hex_data_ff <= INIT_VALUE;
            else
                if (io_write = '1') then
                    hex_data_ff <= io_req_s_tdata(15 downto 0);
                end if;
            end if;
        end if;
    end process;

    -- read process
    read_proc: process (clk) begin
        if rising_edge(clk) then
            -- Resettable
            if resetn = '0' then
                io_rd_m_tvalid <= '0';
            else
                if (io_req_s_tvalid = '1' and io_req_s_tready = '1' and io_read = '1') then
                    io_rd_m_tvalid <= '1';
                elsif io_rd_m_tready = '1' then
                    io_rd_m_tvalid <= '0';
                end if;
            end if;
            -- Without reset
            if (io_req_s_tvalid = '1' and io_req_s_tready = '1' and io_read = '1') then
                io_rd_m_tdata <= hex_data_ff;
            end if;
        end if;
    end process;

end architecture;
