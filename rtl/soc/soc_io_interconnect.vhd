
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

entity soc_io_interconnect is
    port (
        -- global singals
        clk                     : in std_logic;
        resetn                  : in std_logic;
        -- cpu io
        io_req_s_tvalid         : in std_logic;
        io_req_s_tready         : out std_logic;
        io_req_s_tdata          : in std_logic_vector(39 downto 0);
        io_rd_m_tvalid          : out std_logic;
        io_rd_m_tready          : in std_logic;
        io_rd_m_tdata           : out std_logic_vector(15 downto 0);
        -- pit
        pit_req_m_tvalid        : out std_logic;
        pit_req_m_tready        : in std_logic;
        pit_req_m_tdata         : out std_logic_vector(39 downto 0);
        pit_rd_s_tvalid         : in std_logic;
        pit_rd_s_tready         : out std_logic;
        pit_rd_s_tdata          : in std_logic_vector(15 downto 0);
        -- pic
        pic_req_m_tvalid        : out std_logic;
        pic_req_m_tready        : in std_logic;
        pic_req_m_tdata         : out std_logic_vector(39 downto 0);
        pic_rd_s_tvalid         : in std_logic;
        pic_rd_s_tready         : out std_logic;
        pic_rd_s_tdata          : in std_logic_vector(15 downto 0);
        -- led green
        led_0_req_m_tvalid      : out std_logic;
        led_0_req_m_tready      : in std_logic;
        led_0_req_m_tdata       : out std_logic_vector(39 downto 0);
        led_0_rd_s_tvalid       : in std_logic;
        led_0_rd_s_tready       : out std_logic;
        led_0_rd_s_tdata        : in std_logic_vector(15 downto 0);
        -- led red (15 downto 0)
        led_1_req_m_tvalid      : out std_logic;
        led_1_req_m_tready      : in std_logic;
        led_1_req_m_tdata       : out std_logic_vector(39 downto 0);
        led_1_rd_s_tvalid       : in std_logic;
        led_1_rd_s_tready       : out std_logic;
        led_1_rd_s_tdata        : in std_logic_vector(15 downto 0);
        -- led red (17 downto 16)
        led_2_req_m_tvalid      : out std_logic;
        led_2_req_m_tready      : in std_logic;
        led_2_req_m_tdata       : out std_logic_vector(39 downto 0);
        led_2_rd_s_tvalid       : in std_logic;
        led_2_rd_s_tready       : out std_logic;
        led_2_rd_s_tdata        : in std_logic_vector(15 downto 0);
        -- sw (17 downto 16)
        sw_0_req_m_tvalid       : out std_logic;
        sw_0_req_m_tready       : in std_logic;
        sw_0_req_m_tdata        : out std_logic_vector(39 downto 0);
        sw_0_rd_s_tvalid        : in std_logic;
        sw_0_rd_s_tready        : out std_logic;
        sw_0_rd_s_tdata         : in std_logic_vector(15 downto 0);
        -- sw (15 downto 0)
        sw_1_req_m_tvalid       : out std_logic;
        sw_1_req_m_tready       : in std_logic;
        sw_1_req_m_tdata        : out std_logic_vector(39 downto 0);
        sw_1_rd_s_tvalid        : in std_logic;
        sw_1_rd_s_tready        : out std_logic;
        sw_1_rd_s_tdata         : in std_logic_vector(15 downto 0);
        -- hex_group_0
        hex_0_req_m_tvalid       : out std_logic;
        hex_0_req_m_tready       : in std_logic;
        hex_0_req_m_tdata        : out std_logic_vector(39 downto 0);
        hex_0_rd_s_tvalid        : in std_logic;
        hex_0_rd_s_tready        : out std_logic;
        hex_0_rd_s_tdata         : in std_logic_vector(15 downto 0);
        -- hex_group_1
        hex_1_req_m_tvalid       : out std_logic;
        hex_1_req_m_tready       : in std_logic;
        hex_1_req_m_tdata        : out std_logic_vector(39 downto 0);
        hex_1_rd_s_tvalid        : in std_logic;
        hex_1_rd_s_tready        : out std_logic;
        hex_1_rd_s_tdata         : in std_logic_vector(15 downto 0);
        -- uart
        uart_req_m_tvalid       : out std_logic;
        uart_req_m_tready       : in std_logic;
        uart_req_m_tdata        : out std_logic_vector(39 downto 0);
        uart_rd_s_tvalid        : in std_logic;
        uart_rd_s_tready        : out std_logic;
        uart_rd_s_tdata         : in std_logic_vector(15 downto 0);
        -- port 61
        port_61_req_m_tvalid    : out std_logic;
        port_61_req_m_tready    : in std_logic;
        port_61_req_m_tdata     : out std_logic_vector(39 downto 0);
        port_61_rd_s_tvalid     : in std_logic;
        port_61_rd_s_tready     : out std_logic;
        port_61_rd_s_tdata      : in std_logic_vector(15 downto 0)
    );
end entity soc_io_interconnect;

architecture rtl of soc_io_interconnect is

    component axis_fifo is
        generic (
            FIFO_DEPTH      : natural := 8;
            FIFO_WIDTH      : natural := 128
        );
        port (
            clk             : in std_logic;
            resetn          : in std_logic;

            fifo_s_tvalid   : in std_logic;
            fifo_s_tready   : out std_logic;
            fifo_s_tdata    : in std_logic_vector(FIFO_WIDTH-1 downto 0);

            fifo_m_tvalid   : out std_logic;
            fifo_m_tready   : in std_logic;
            fifo_m_tdata    : out std_logic_vector(FIFO_WIDTH-1 downto 0)
        );
    end component;

    signal pit_req_cs           : std_logic;
    signal pic_req_cs           : std_logic;
    signal led_0_req_cs         : std_logic;
    signal led_1_req_cs         : std_logic;
    signal led_2_req_cs         : std_logic;
    signal hex_0_req_cs         : std_logic;
    signal hex_1_req_cs         : std_logic;
    signal sw_0_req_cs          : std_logic;
    signal sw_1_req_cs          : std_logic;
    signal port_61_req_cs       : std_logic;
    signal uart_req_cs          : std_logic;

    signal fifo_io_s_tvalid     : std_logic;
    signal fifo_io_s_tready     : std_logic;
    signal fifo_io_s_tdata      : std_logic_vector(3 downto 0);
    signal fifo_io_s_selector   : std_logic_vector(10 downto 0);
    signal fifo_io_m_tvalid     : std_logic;
    signal fifo_io_m_tready     : std_logic;
    signal fifo_io_m_tdata      : std_logic_vector(3 downto 0);

    signal rd_selector          : std_logic_vector(10 downto 0);

begin

    -- Module axis_fifo instantiation
    axis_fifo_inst : axis_fifo generic map (
        FIFO_DEPTH      => 16,
        FIFO_WIDTH      => 4
    ) port map (
        clk             => clk,
        resetn          => resetn,
        fifo_s_tvalid   => fifo_io_s_tvalid,
        fifo_s_tready   => fifo_io_s_tready,
        fifo_s_tdata    => fifo_io_s_tdata,
        fifo_m_tvalid   => fifo_io_m_tvalid,
        fifo_m_tready   => fifo_io_m_tready,
        fifo_m_tdata    => fifo_io_m_tdata
    );

    -- Assigns
    io_req_s_tready <= '1' when (
        (pit_req_m_tvalid = '0' or (pit_req_m_tvalid = '1' and pit_req_m_tready = '1')) and
        (pic_req_m_tvalid = '0' or (pic_req_m_tvalid = '1' and pic_req_m_tready = '1')) and
        (led_0_req_m_tvalid = '0' or (led_0_req_m_tvalid = '1' and led_0_req_m_tready = '1')) and
        (led_1_req_m_tvalid = '0' or (led_1_req_m_tvalid = '1' and led_1_req_m_tready = '1')) and
        (led_2_req_m_tvalid = '0' or (led_2_req_m_tvalid = '1' and led_2_req_m_tready = '1')) and
        (sw_0_req_m_tvalid = '0' or (sw_0_req_m_tvalid = '1' and sw_0_req_m_tready = '1')) and
        (sw_1_req_m_tvalid = '0' or (sw_1_req_m_tvalid = '1' and sw_1_req_m_tready = '1')) and
        (hex_0_req_m_tvalid = '0' or (hex_0_req_m_tvalid = '1' and hex_0_req_m_tready = '1')) and
        (hex_1_req_m_tvalid = '0' or (hex_1_req_m_tvalid = '1' and hex_1_req_m_tready = '1')) and
        (port_61_req_m_tvalid = '0' or (port_61_req_m_tvalid = '1' and port_61_req_m_tready = '1')) and
        (uart_req_m_tvalid = '0' or (uart_req_m_tvalid = '1' and uart_req_m_tready = '1')) and
        (fifo_io_s_tready = '1')
    ) else '0';

    pit_rd_s_tready     <= '1' when (io_rd_m_tvalid = '0' or (io_rd_m_tvalid = '1' and io_rd_m_tready = '1')) and fifo_io_m_tvalid = '1' and fifo_io_m_tdata = x"0" else '0';
    pic_rd_s_tready     <= '1' when (io_rd_m_tvalid = '0' or (io_rd_m_tvalid = '1' and io_rd_m_tready = '1')) and fifo_io_m_tvalid = '1' and fifo_io_m_tdata = x"1" else '0';
    led_0_rd_s_tready   <= '1' when (io_rd_m_tvalid = '0' or (io_rd_m_tvalid = '1' and io_rd_m_tready = '1')) and fifo_io_m_tvalid = '1' and fifo_io_m_tdata = x"2" else '0';
    led_1_rd_s_tready   <= '1' when (io_rd_m_tvalid = '0' or (io_rd_m_tvalid = '1' and io_rd_m_tready = '1')) and fifo_io_m_tvalid = '1' and fifo_io_m_tdata = x"3" else '0';
    led_2_rd_s_tready   <= '1' when (io_rd_m_tvalid = '0' or (io_rd_m_tvalid = '1' and io_rd_m_tready = '1')) and fifo_io_m_tvalid = '1' and fifo_io_m_tdata = x"4" else '0';
    sw_0_rd_s_tready    <= '1' when (io_rd_m_tvalid = '0' or (io_rd_m_tvalid = '1' and io_rd_m_tready = '1')) and fifo_io_m_tvalid = '1' and fifo_io_m_tdata = x"5" else '0';
    sw_1_rd_s_tready    <= '1' when (io_rd_m_tvalid = '0' or (io_rd_m_tvalid = '1' and io_rd_m_tready = '1')) and fifo_io_m_tvalid = '1' and fifo_io_m_tdata = x"6" else '0';
    port_61_rd_s_tready <= '1' when (io_rd_m_tvalid = '0' or (io_rd_m_tvalid = '1' and io_rd_m_tready = '1')) and fifo_io_m_tvalid = '1' and fifo_io_m_tdata = x"7" else '0';
    hex_0_rd_s_tready   <= '1' when (io_rd_m_tvalid = '0' or (io_rd_m_tvalid = '1' and io_rd_m_tready = '1')) and fifo_io_m_tvalid = '1' and fifo_io_m_tdata = x"8" else '0';
    hex_1_rd_s_tready   <= '1' when (io_rd_m_tvalid = '0' or (io_rd_m_tvalid = '1' and io_rd_m_tready = '1')) and fifo_io_m_tvalid = '1' and fifo_io_m_tdata = x"9" else '0';
    uart_rd_s_tready    <= '1' when (io_rd_m_tvalid = '0' or (io_rd_m_tvalid = '1' and io_rd_m_tready = '1')) and fifo_io_m_tvalid = '1' and fifo_io_m_tdata = x"A" else '0';

    fifo_io_s_tvalid    <= '1' when io_req_s_tvalid = '1' and io_req_s_tready = '1' and io_req_s_tdata(32) = '0' else '0';
    fifo_io_m_tready    <= '1' when io_rd_m_tvalid = '1' and io_rd_m_tready = '1' else '0';

    fifo_io_s_selector(0)  <= pit_req_cs;
    fifo_io_s_selector(1)  <= pic_req_cs;
    fifo_io_s_selector(2)  <= led_0_req_cs;
    fifo_io_s_selector(3)  <= led_1_req_cs;
    fifo_io_s_selector(4)  <= led_2_req_cs;
    fifo_io_s_selector(5)  <= sw_0_req_cs;
    fifo_io_s_selector(6)  <= sw_1_req_cs;
    fifo_io_s_selector(7)  <= port_61_req_cs;
    fifo_io_s_selector(8)  <= hex_0_req_cs;
    fifo_io_s_selector(9)  <= hex_1_req_cs;
    fifo_io_s_selector(10) <= uart_req_cs;

    process (all) begin
        fifo_io_s_tdata <= (others => '0');
        for i in fifo_io_s_selector'range loop
            if (fifo_io_s_selector(i) = '1') then
                fifo_io_s_tdata <= std_logic_vector(to_unsigned(i, 4));
            end if;
	    end loop;
    end process;

    pic_req_cs <= '1' when (
        (io_req_s_tdata(31 downto 17) & '0') = x"0020" or
        (io_req_s_tdata(31 downto 17) & '0') = x"00A0"
    ) else '0';

    pit_req_cs <= '1' when (
        io_req_s_tdata(31 downto 20) = x"004"
    ) else '0';

    led_0_req_cs <= '1' when (
        io_req_s_tdata(31 downto 16) = x"0300"
    ) else '0';

    led_1_req_cs <= '1' when (
        io_req_s_tdata(31 downto 16) = x"0301"
    ) else '0';

    led_2_req_cs <= '1' when (
        io_req_s_tdata(31 downto 16) = x"0302"
    ) else '0';

    sw_0_req_cs <= '1' when (
        io_req_s_tdata(31 downto 16) = x"0303"
    ) else '0';

    sw_1_req_cs <= '1' when (
        io_req_s_tdata(31 downto 16) = x"0304"
    ) else '0';

    hex_0_req_cs <= '1' when (
        io_req_s_tdata(31 downto 16) = x"0305"
    ) else '0';

    hex_1_req_cs <= '1' when (
        io_req_s_tdata(31 downto 16) = x"0306"
    ) else '0';

    -- 0x0310
    -- 0x0311
    -- 0x0312
    uart_req_cs <= '1' when (
        io_req_s_tdata(31 downto 20) = x"031"
    ) else '0';

    port_61_req_cs <= '1' when (
        io_req_s_tdata(31 downto 16) = x"0061"
    ) else '0';

    -- latching pit request
    latch_pit_req_proc: process (clk) begin
        if rising_edge(clk) then
            -- Resettable
            if resetn = '0' then
                pit_req_m_tvalid <= '0';
            else
                if (io_req_s_tvalid = '1' and io_req_s_tready = '1' and pit_req_cs = '1') then
                    pit_req_m_tvalid <= '1';
                elsif (pit_req_m_tready = '1') then
                    pit_req_m_tvalid <= '0';
                end if;
            end if;
            -- Without reset
            if (io_req_s_tvalid = '1' and io_req_s_tready = '1') then
                pit_req_m_tdata <= io_req_s_tdata;
            end if;
        end if;
    end process;

    -- latching pic request
    latch_pic_req_proc: process (clk) begin
        if rising_edge(clk) then
            -- Resettable
            if resetn = '0' then
                pic_req_m_tvalid <= '0';
            else
                if (io_req_s_tvalid = '1' and io_req_s_tready = '1' and pic_req_cs = '1') then
                    pic_req_m_tvalid <= '1';
                elsif (pic_req_m_tready = '1') then
                    pic_req_m_tvalid <= '0';
                end if;
            end if;
            -- Without reset
            if (io_req_s_tvalid = '1' and io_req_s_tready = '1') then
                pic_req_m_tdata <= io_req_s_tdata;
            end if;
        end if;
    end process;

    -- latching led_0 request
    latch_led_0_req_proc: process (clk) begin
        if rising_edge(clk) then
            -- Resettable
            if resetn = '0' then
                led_0_req_m_tvalid <= '0';
            else
                if (io_req_s_tvalid = '1' and io_req_s_tready = '1' and led_0_req_cs = '1') then
                    led_0_req_m_tvalid <= '1';
                elsif (led_0_req_m_tready = '1') then
                    led_0_req_m_tvalid <= '0';
                end if;
            end if;
            -- Without reset
            if (io_req_s_tvalid = '1' and io_req_s_tready = '1') then
                led_0_req_m_tdata <= io_req_s_tdata;
            end if;
        end if;
    end process;

    -- latching led_1 request
    latch_led_1_req_proc: process (clk) begin
        if rising_edge(clk) then
            -- Resettable
            if resetn = '0' then
                led_1_req_m_tvalid <= '0';
            else
                if (io_req_s_tvalid = '1' and io_req_s_tready = '1' and led_1_req_cs = '1') then
                    led_1_req_m_tvalid <= '1';
                elsif (led_1_req_m_tready = '1') then
                    led_1_req_m_tvalid <= '0';
                end if;
            end if;
            -- Without reset
            if (io_req_s_tvalid = '1' and io_req_s_tready = '1') then
                led_1_req_m_tdata <= io_req_s_tdata;
            end if;
        end if;
    end process;

    -- latching led_2 request
    latch_led_2_req_proc: process (clk) begin
        if rising_edge(clk) then
            -- Resettable
            if resetn = '0' then
                led_2_req_m_tvalid <= '0';
            else
                if (io_req_s_tvalid = '1' and io_req_s_tready = '1' and led_2_req_cs = '1') then
                    led_2_req_m_tvalid <= '1';
                elsif (led_2_req_m_tready = '1') then
                    led_2_req_m_tvalid <= '0';
                end if;
            end if;
            -- Without reset
            if (io_req_s_tvalid = '1' and io_req_s_tready = '1') then
                led_2_req_m_tdata <= io_req_s_tdata;
            end if;
        end if;
    end process;

    -- latching sw_0 request
    latch_sw_0_req_proc: process (clk) begin
        if rising_edge(clk) then
            -- Resettable
            if resetn = '0' then
                sw_0_req_m_tvalid <= '0';
            else
                if (io_req_s_tvalid = '1' and io_req_s_tready = '1' and sw_0_req_cs = '1') then
                    sw_0_req_m_tvalid <= '1';
                elsif (sw_0_req_m_tready = '1') then
                    sw_0_req_m_tvalid <= '0';
                end if;
            end if;
            -- Without reset
            if (io_req_s_tvalid = '1' and io_req_s_tready = '1') then
                sw_0_req_m_tdata <= io_req_s_tdata;
            end if;
        end if;
    end process;

    -- latching sw_1 request
    latch_sw_1_req_proc: process (clk) begin
        if rising_edge(clk) then
            -- Resettable
            if resetn = '0' then
                sw_1_req_m_tvalid <= '0';
            else
                if (io_req_s_tvalid = '1' and io_req_s_tready = '1' and sw_1_req_cs = '1') then
                    sw_1_req_m_tvalid <= '1';
                elsif (sw_1_req_m_tready = '1') then
                    sw_1_req_m_tvalid <= '0';
                end if;
            end if;
            -- Without reset
            if (io_req_s_tvalid = '1' and io_req_s_tready = '1') then
                sw_1_req_m_tdata <= io_req_s_tdata;
            end if;
        end if;
    end process;

    -- latching sw_0 request
    latch_hex_0_req_proc: process (clk) begin
        if rising_edge(clk) then
            -- Resettable
            if resetn = '0' then
                hex_0_req_m_tvalid <= '0';
            else
                if (io_req_s_tvalid = '1' and io_req_s_tready = '1' and hex_0_req_cs = '1') then
                    hex_0_req_m_tvalid <= '1';
                elsif (hex_0_req_m_tready = '1') then
                    hex_0_req_m_tvalid <= '0';
                end if;
            end if;
            -- Without reset
            if (io_req_s_tvalid = '1' and io_req_s_tready = '1') then
                hex_0_req_m_tdata <= io_req_s_tdata;
            end if;
        end if;
    end process;

    -- latching hex_1 request
    latch_hex_1_req_proc: process (clk) begin
        if rising_edge(clk) then
            -- Resettable
            if resetn = '0' then
                hex_1_req_m_tvalid <= '0';
            else
                if (io_req_s_tvalid = '1' and io_req_s_tready = '1' and hex_1_req_cs = '1') then
                    hex_1_req_m_tvalid <= '1';
                elsif (hex_1_req_m_tready = '1') then
                    hex_1_req_m_tvalid <= '0';
                end if;
            end if;
            -- Without reset
            if (io_req_s_tvalid = '1' and io_req_s_tready = '1') then
                hex_1_req_m_tdata <= io_req_s_tdata;
            end if;
        end if;
    end process;

    -- latching port_61 request
    latch_port_61_req_proc: process (clk) begin
        if rising_edge(clk) then
            -- Resettable
            if resetn = '0' then
                port_61_req_m_tvalid <= '0';
            else
                if (io_req_s_tvalid = '1' and io_req_s_tready = '1' and port_61_req_cs = '1') then
                    port_61_req_m_tvalid <= '1';
                elsif (port_61_req_m_tready = '1') then
                    port_61_req_m_tvalid <= '0';
                end if;
            end if;
            -- Without reset
            if (io_req_s_tvalid = '1' and io_req_s_tready = '1') then
                port_61_req_m_tdata <= io_req_s_tdata;
            end if;
        end if;
    end process;

    -- latching uart request
    latch_uart_req_proc: process (clk) begin
        if rising_edge(clk) then
            -- Resettable
            if resetn = '0' then
                uart_req_m_tvalid <= '0';
            else
                if (io_req_s_tvalid = '1' and io_req_s_tready = '1' and uart_req_cs = '1') then
                    uart_req_m_tvalid <= '1';
                elsif (uart_req_m_tready = '1') then
                    uart_req_m_tvalid <= '0';
                end if;
            end if;
            -- Without reset
            if (io_req_s_tvalid = '1' and io_req_s_tready = '1') then
                uart_req_m_tdata <= io_req_s_tdata;
            end if;
        end if;
    end process;

    rd_selector(0)  <= '1' when (pit_rd_s_tvalid = '1' and pit_rd_s_tready = '1')  else '0';
    rd_selector(1)  <= '1' when (pic_rd_s_tvalid = '1' and pic_rd_s_tready = '1')  else '0';
    rd_selector(2)  <= '1' when (led_0_rd_s_tvalid = '1' and led_0_rd_s_tready = '1')  else '0';
    rd_selector(3)  <= '1' when (led_1_rd_s_tvalid = '1' and led_1_rd_s_tready = '1')  else '0';
    rd_selector(4)  <= '1' when (led_2_rd_s_tvalid = '1' and led_2_rd_s_tready = '1')  else '0';
    rd_selector(5)  <= '1' when (sw_0_rd_s_tvalid = '1' and sw_0_rd_s_tready = '1')  else '0';
    rd_selector(6)  <= '1' when (sw_1_rd_s_tvalid = '1' and sw_1_rd_s_tready = '1')  else '0';
    rd_selector(7)  <= '1' when (port_61_rd_s_tvalid = '1' and port_61_rd_s_tready = '1') else '0';
    rd_selector(8)  <= '1' when (hex_0_rd_s_tvalid = '1' and hex_0_rd_s_tready = '1')  else '0';
    rd_selector(9)  <= '1' when (hex_1_rd_s_tvalid = '1' and hex_1_rd_s_tready = '1')  else '0';
    rd_selector(10) <= '1' when (uart_rd_s_tvalid = '1' and uart_rd_s_tready = '1')  else '0';

    latch_resp_proc : process (clk) begin
        if rising_edge(clk) then
            -- Resettable
            if resetn = '0' then
                io_rd_m_tvalid <= '0';
            else
                if (rd_selector /= "00000000000") then
                    io_rd_m_tvalid <= '1';
                elsif (io_rd_m_tready = '1') then
                    io_rd_m_tvalid <= '0';
                end if;
            end if;
            -- Without reset
            case rd_selector is
                when "00000000001" => io_rd_m_tdata <= pit_rd_s_tdata;
                when "00000000010" => io_rd_m_tdata <= pic_rd_s_tdata;
                when "00000000100" => io_rd_m_tdata <= led_0_rd_s_tdata;
                when "00000001000" => io_rd_m_tdata <= led_1_rd_s_tdata;
                when "00000010000" => io_rd_m_tdata <= led_2_rd_s_tdata;
                when "00000100000" => io_rd_m_tdata <= sw_0_rd_s_tdata;
                when "00001000000" => io_rd_m_tdata <= sw_0_rd_s_tdata;
                when "00010000000" => io_rd_m_tdata <= port_61_rd_s_tdata;
                when "00100000000" => io_rd_m_tdata <= hex_0_rd_s_tdata;
                when "01000000000" => io_rd_m_tdata <= hex_1_rd_s_tdata;
                when "10000000000" => io_rd_m_tdata <= uart_rd_s_tdata;
                when others        => io_rd_m_tdata <= led_0_rd_s_tdata;
            end case;
        end if;
    end process;

end architecture;
