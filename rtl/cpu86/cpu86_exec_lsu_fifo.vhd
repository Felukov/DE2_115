
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
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;

entity cpu86_exec_lsu_fifo is
    generic (
        FIFO_DEPTH          : natural := 4;
        FIFO_WIDTH          : natural := 16;
        ADDR_WIDTH          : natural := 2;
        REGISTER_OUTPUT     : std_logic := '1'
    );
    port (
        clk                 : in std_logic;
        resetn              : in std_logic;

        s_axis_add_tvalid   : in std_logic;
        s_axis_add_tready   : out std_logic;
        s_axis_add_tdata    : in std_logic_vector(FIFO_WIDTH-1 downto 0);
        s_axis_add_tuser    : in std_logic;

        m_axis_tag_tvalid   : out std_logic;
        m_axis_tag_tdata    : out std_logic_vector(ADDR_WIDTH-1 downto 0);

        s_axis_upd_tvalid   : in std_logic;
        s_axis_upd_tdata    : in std_logic_vector(FIFO_WIDTH-1 downto 0);
        s_axis_upd_tuser    : in std_logic_vector(ADDR_WIDTH-1 downto 0);

        m_axis_dout_tvalid  : out std_logic;
        m_axis_dout_tready  : in std_logic;
        m_axis_dout_tdata   : out std_logic_vector(FIFO_WIDTH-1 downto 0)
    );
end entity cpu86_exec_lsu_fifo;

architecture rtl of cpu86_exec_lsu_fifo is

    type ram_t is array (FIFO_DEPTH-1 downto 0) of std_logic_vector(FIFO_WIDTH-1 downto 0);

    signal wr_addr          : integer range 0 to FIFO_DEPTH-1;
    signal wr_addr_next     : integer range 0 to FIFO_DEPTH-1;
    signal rd_addr          : integer range 0 to FIFO_DEPTH-1;
    signal rd_addr_next     : integer range 0 to FIFO_DEPTH-1;
    signal fifo_ram_valid   : std_logic_vector(FIFO_DEPTH-1 downto 0);
    signal fifo_ram_data    : ram_t := (others => (others => '0'));

    signal q_thit           : std_logic;
    signal q_tdata          : std_logic_vector(FIFO_WIDTH-1 downto 0);

    signal wr_data_tvalid   : std_logic;
    signal wr_data_tready   : std_logic;
    signal wr_data_tdata    : std_logic_vector(FIFO_WIDTH-1 downto 0);
    signal wr_data_hit      : std_logic;

    signal upd_tvalid       : std_logic;
    signal upd_tdata        : std_logic_vector(FIFO_WIDTH-1 downto 0);
    signal upd_tag          : std_logic_vector(ADDR_WIDTH-1 downto 0);

    signal rd_data_tvalid   : std_logic;
    signal rd_data_tready   : std_logic;

    signal out_tvalid       : std_logic;
    signal out_tready       : std_logic;
    signal out_tdata        : std_logic_vector(FIFO_WIDTH-1 downto 0);

    signal fifo_cnt         : integer range 0 to FIFO_DEPTH-1;

begin

    -- io assigns
    wr_data_tvalid      <= s_axis_add_tvalid;
    s_axis_add_tready   <= wr_data_tready;
    wr_data_tdata       <= s_axis_add_tdata;
    wr_data_hit         <= s_axis_add_tuser;

    m_axis_tag_tvalid   <= '1' when wr_data_tvalid = '1' and wr_data_tready = '1' else '0';
    m_axis_tag_tdata    <= std_logic_vector(to_unsigned(wr_addr, ADDR_WIDTH));

    m_axis_dout_tvalid  <= out_tvalid;
    out_tready          <= m_axis_dout_tready;
    m_axis_dout_tdata   <= out_tdata;

    upd_tvalid          <= s_axis_upd_tvalid;
    upd_tdata           <= s_axis_upd_tdata;
    upd_tag             <= s_axis_upd_tuser;

    -- assigns
    register_output_ready_gen : if (REGISTER_OUTPUT = '1') generate
        rd_data_tready <= '1' when out_tvalid = '0' or (out_tvalid = '1' and out_tready = '1') else '0';
    end generate;

    async_output_ready_gen: if (REGISTER_OUTPUT = '0') generate
        rd_data_tready <= out_tready;
    end generate;

    q_thit          <= fifo_ram_valid(rd_addr);
    q_tdata         <= fifo_ram_data(rd_addr);

    fifo_throughput_proc : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                fifo_cnt <= 0;
                wr_data_tready <= '1';
                rd_data_tvalid <= '0';
            else
                if (wr_data_tvalid = '1' and wr_data_tready = '1' and rd_data_tvalid = '1' and rd_data_tready = '1' and q_thit = '1') then
                    fifo_cnt <= fifo_cnt;
                elsif (wr_data_tvalid = '1' and wr_data_tready = '1') then
                    fifo_cnt <= fifo_cnt + 1;
                elsif (rd_data_tvalid = '1' and rd_data_tready = '1' and q_thit = '1') then
                    fifo_cnt <= fifo_cnt - 1;
                end if;

                if (wr_data_tvalid = '1' and wr_data_tready = '1' and rd_data_tvalid = '1' and rd_data_tready = '1' and q_thit = '1') then
                    wr_data_tready <= wr_data_tready;
                elsif (wr_data_tvalid = '1' and wr_data_tready = '1') then
                    if (fifo_cnt + 1) = FIFO_DEPTH-1 then
                        wr_data_tready <= '0';
                    end if;
                elsif (rd_data_tvalid = '1' and rd_data_tready = '1' and q_thit = '1') then
                    wr_data_tready <= '1';
                end if;

                if (wr_data_tvalid = '1' and wr_data_tready = '1' and rd_data_tvalid = '1' and rd_data_tready = '1' and q_thit = '1') then
                    rd_data_tvalid <= rd_data_tvalid;
                elsif (wr_data_tvalid = '1' and wr_data_tready = '1') then
                    rd_data_tvalid <= '1';
                elsif (rd_data_tvalid = '1' and rd_data_tready = '1' and q_thit = '1') then
                    if (fifo_cnt - 1) = 0 then
                        rd_data_tvalid <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;

    write_proc_next: process (all) begin
        if (wr_data_tvalid = '1' and wr_data_tready = '1') then
            wr_addr_next <= (wr_addr + 1) mod FIFO_DEPTH;
        else
            wr_addr_next <= wr_addr;
        end if;
    end process;

    write_proc: process (clk) begin
        if rising_edge(clk) then
            -- Control
            if resetn = '0' then
                wr_addr <= 0;
                fifo_ram_valid <= (others => '0');
            else
                wr_addr <= wr_addr_next;

                for i in 0 to FIFO_DEPTH-1 loop
                    if (wr_data_tvalid = '1' and wr_data_tready = '1' and i = wr_addr) then
                        fifo_ram_valid(i) <= wr_data_hit;
                    elsif (upd_tvalid = '1' and i = to_integer(unsigned(upd_tag))) then
                        fifo_ram_valid(i) <= '1';
                    end if;
                end loop;
            end if;
            -- Data
            for i in 0 to FIFO_DEPTH-1 loop
                if (wr_data_tvalid = '1' and wr_data_tready = '1' and i = wr_addr) then
                    fifo_ram_data(i) <= wr_data_tdata;
                elsif (upd_tvalid = '1' and i = to_integer(unsigned(upd_tag))) then
                    fifo_ram_data(i) <= upd_tdata;
                end if;
            end loop;
        end if;
    end process;

    read_proc_next : process (all) begin
        if rd_data_tvalid = '1' and rd_data_tready = '1' and q_thit = '1' then
            rd_addr_next <= (rd_addr + 1) mod FIFO_DEPTH;
        else
            rd_addr_next <= rd_addr;
        end if;
    end process;

    read_proc : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                rd_addr <= 0;
            else
                rd_addr <= rd_addr_next;
            end if;
        end if;
    end process;

    register_output_gen : if (REGISTER_OUTPUT = '1') generate
        register_output_proc: process (clk) begin
            if rising_edge(clk) then
                -- Resettable
                if resetn = '0' then
                    out_tvalid <= '0';
                else
                    if rd_data_tvalid = '1' and rd_data_tready = '1' and q_thit = '1' then
                        out_tvalid <= '1';
                    elsif out_tready = '1' then
                        out_tvalid <= '0';
                    end if;
                end if;
                -- Without reset
                if rd_data_tready = '1' then
                    out_tdata <= q_tdata(FIFO_WIDTH-1 downto 0);
                end if;
            end if;
        end process;
    end generate;

    async_output_gen: if (REGISTER_OUTPUT = '0') generate

        out_tvalid <= '1' when rd_data_tvalid = '1' and q_thit = '1' else '0';
        out_tdata <= q_tdata;

    end generate;

end architecture;
