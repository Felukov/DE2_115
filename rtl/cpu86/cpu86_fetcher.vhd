
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

entity cpu86_fetcher is
    port (
        clk                     : in std_logic;
        resetn                  : in std_logic;

        s_axis_jump_tvalid      : in std_logic;
        s_axis_jump_tdata       : in std_logic_vector(31 downto 0);

        s_axis_mem_data_tvalid  : in std_logic;
        s_axis_mem_data_tdata   : in std_logic_vector(31 downto 0);

        m_axis_mem_req_tvalid   : out std_logic;
        m_axis_mem_req_tready   : in std_logic;
        m_axis_mem_req_tdata    : out std_logic_vector(19 downto 0);

        m_axis_data_tvalid      : out std_logic;
        m_axis_data_tready      : in std_logic;
        m_axis_data_tdata       : out std_logic_vector(31 downto 0);
        m_axis_data_tuser       : out std_logic_vector(31 downto 0)
    );
end entity cpu86_fetcher;

architecture rtl of cpu86_fetcher is

    component axis_fifo is
        generic (
            FIFO_DEPTH          : natural := 2**8;
            FIFO_WIDTH          : natural := 128
        );
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            fifo_s_tvalid       : in std_logic;
            fifo_s_tready       : out std_logic;
            fifo_s_tdata        : in std_logic_vector(FIFO_WIDTH-1 downto 0);

            fifo_m_tvalid       : out std_logic;
            fifo_m_tready       : in std_logic;
            fifo_m_tdata        : out std_logic_vector(FIFO_WIDTH-1 downto 0)
        );
    end component;

    signal cmd_tvalid           : std_logic;
    signal cmd_tready           : std_logic;
    signal cmd_tdata            : std_logic_vector(19 downto 0);

    signal max_hs_cnt           : natural range 0 to 32;
    signal mem_hs_cnt           : natural range 0 to 32;
    signal skip_hs_cnt          : natural range 0 to 32;

    signal jmp_req_tvalid       : std_logic;
    signal jmp_req_tdata        : std_logic_vector(31 downto 0);

    signal mem_rd_tvalid        : std_logic;
    signal mem_rd_tdata         : std_logic_vector(31 downto 0);

    signal max_inc_hs           : std_logic;
    signal max_dec_hs           : std_logic;

    signal mem_inc_hs           : std_logic;
    signal mem_dec_hs           : std_logic;

    signal cs_tdata             : std_logic_vector(15 downto 0);
    signal ip_tdata             : std_logic_vector(15 downto 0);

    signal fifo_0_s_tvalid      : std_logic;
    signal fifo_0_s_tready      : std_logic;
    signal fifo_0_s_tdata       : std_logic_vector(31 downto 0);

    signal fifo_0_m_tvalid      : std_logic;
    signal fifo_0_m_tready      : std_logic;
    signal fifo_0_m_tdata       : std_logic_vector(31 downto 0);

    signal fifo_resetn          : std_logic;
    signal fifo_1_s_tvalid      : std_logic;
    signal fifo_1_s_tready      : std_logic;
    signal fifo_1_s_tdata       : std_logic_vector(63 downto 0);

    signal fifo_1_m_tvalid      : std_logic;
    signal fifo_1_m_tready      : std_logic;
    signal fifo_1_m_tdata       : std_logic_vector(63 downto 0);

begin
    -- i/o assigns
    jmp_req_tvalid          <= s_axis_jump_tvalid;
    jmp_req_tdata           <= s_axis_jump_tdata;

    mem_rd_tvalid           <= s_axis_mem_data_tvalid;
    mem_rd_tdata            <= s_axis_mem_data_tdata;

    m_axis_mem_req_tvalid   <= cmd_tvalid;
    cmd_tready              <= m_axis_mem_req_tready;
    m_axis_mem_req_tdata    <= cmd_tdata;

    m_axis_data_tvalid      <= fifo_1_m_tvalid;
    fifo_1_m_tready         <= m_axis_data_tready;
    m_axis_data_tdata       <= fifo_1_m_tdata(31 downto 0);
    m_axis_data_tuser       <= fifo_1_m_tdata(63 downto 32);


    -- module axis_fifo instantiation
    axis_fifo_inst_0 : axis_fifo generic map (
        FIFO_DEPTH      => 16,
        FIFO_WIDTH      => 32
    ) port map (
        clk             => clk,
        resetn          => fifo_resetn,
        fifo_s_tvalid   => fifo_0_s_tvalid,
        fifo_s_tready   => fifo_0_s_tready,
        fifo_s_tdata    => fifo_0_s_tdata,
        fifo_m_tvalid   => fifo_0_m_tvalid,
        fifo_m_tready   => fifo_0_m_tready,
        fifo_m_tdata    => fifo_0_m_tdata
    );

    -- module axis_fifo instantiation
    axis_fifo_inst_1 : axis_fifo generic map (
        FIFO_DEPTH      => 32,
        FIFO_WIDTH      => 64
    ) port map (
        clk             => clk,
        resetn          => fifo_resetn,
        fifo_s_tvalid   => fifo_1_s_tvalid,
        fifo_s_tready   => fifo_1_s_tready,
        fifo_s_tdata    => fifo_1_s_tdata,
        fifo_m_tvalid   => fifo_1_m_tvalid,
        fifo_m_tready   => fifo_1_m_tready,
        fifo_m_tdata    => fifo_1_m_tdata
    );

    -- assigns
    fifo_resetn     <= '0' when resetn = '0' or jmp_req_tvalid = '1' else '1';

    fifo_0_s_tvalid <= '1' when cmd_tvalid = '1' and cmd_tready = '1' else '0';
    fifo_0_s_tdata  <= cs_tdata & ip_tdata;
    fifo_0_m_tready <= '1' when mem_rd_tvalid = '1' and skip_hs_cnt = 0 else '0';

    fifo_1_s_tvalid <= '1' when mem_rd_tvalid = '1' and skip_hs_cnt = 0 else '0';
    fifo_1_s_tdata  <= fifo_0_m_tdata & mem_rd_tdata;

    max_inc_hs      <= '1' when (cmd_tvalid = '1' and cmd_tready = '1') else '0';
    max_dec_hs      <= '1' when (fifo_1_m_tvalid = '1' and fifo_1_m_tready = '1') else '0';

    mem_inc_hs      <= '1' when (cmd_tvalid = '1' and cmd_tready = '1') else '0';
    mem_dec_hs      <= '1' when (mem_rd_tvalid = '1') else '0';

    cmd_tdata       <= std_logic_vector(unsigned(cs_tdata & x"0") + unsigned(x"0" & ip_tdata(15 downto 2)));

    -- requesting commands from memory and requests housekeeping
    process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                cmd_tvalid <= '0';
                max_hs_cnt <= 0;
                mem_hs_cnt <= 0;
                skip_hs_cnt <= 0;
            else

                if (max_hs_cnt < 16) then
                    cmd_tvalid <= '1';
                elsif cmd_tready = '1' then
                    cmd_tvalid <= '0';
                end if;

                if (mem_inc_hs = '1' and mem_dec_hs = '0') then
                    mem_hs_cnt <= (mem_hs_cnt + 1) mod 32;
                elsif (mem_inc_hs = '0' and mem_dec_hs = '1') then
                    mem_hs_cnt <= (mem_hs_cnt - 1) mod 32;
                end if;

                if (jmp_req_tvalid = '1') then
                    max_hs_cnt <= 0;
                elsif (max_inc_hs = '1' and max_dec_hs = '0') then
                    max_hs_cnt <= (max_hs_cnt + 1) mod 32;
                elsif (max_inc_hs = '0' and max_dec_hs = '1') then
                    max_hs_cnt <= (max_hs_cnt - 1) mod 32;
                end if;

                if (jmp_req_tvalid = '1') then
                    if (mem_inc_hs = '1' and mem_dec_hs = '0') then
                        skip_hs_cnt <= (mem_hs_cnt + 1) mod 32;
                    elsif (mem_inc_hs = '0' and mem_dec_hs = '1') then
                        skip_hs_cnt <= (mem_hs_cnt - 1) mod 32;
                    else
                        skip_hs_cnt <= mem_hs_cnt;
                    end if;
                elsif (mem_rd_tvalid = '1' and skip_hs_cnt /= 0) then
                    skip_hs_cnt <= skip_hs_cnt - 1;
                end if;

            end if;
        end if;
    end process;

    -- CS:IP registers
    process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                cs_tdata <= x"0000";
                ip_tdata <= x"0400";
            else
                if (jmp_req_tvalid = '1') then
                    cs_tdata <= jmp_req_tdata(31 downto 16);
                end if;

                if (jmp_req_tvalid = '1') then
                    ip_tdata <= jmp_req_tdata(15 downto 0);
                elsif (cmd_tvalid = '1' and cmd_tready = '1') then
                    ip_tdata <= std_logic_vector(unsigned(ip_tdata(15 downto 2) & "00") + to_unsigned(4, 3));
                end if;
            end if;

        end if;
    end process;

end architecture;
