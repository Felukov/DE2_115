
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
        clk                         : in std_logic;
        resetn                      : in std_logic;
        -- cpu io
        s_axis_io_req_tvalid        : in std_logic;
        s_axis_io_req_tready        : out std_logic;
        s_axis_io_req_tdata         : in std_logic_vector(39 downto 0);
        m_axis_io_res_tvalid        : out std_logic;
        m_axis_io_res_tready        : in std_logic;
        m_axis_io_res_tdata         : out std_logic_vector(15 downto 0);
        -- pit
        m_axis_pit_req_tvalid       : out std_logic;
        m_axis_pit_req_tready       : in std_logic;
        m_axis_pit_req_tdata        : out std_logic_vector(39 downto 0);
        s_axis_pit_res_tvalid       : in std_logic;
        s_axis_pit_res_tready       : out std_logic;
        s_axis_pit_res_tdata        : in std_logic_vector(15 downto 0);
        -- pic
        m_axis_pic_req_tvalid       : out std_logic;
        m_axis_pic_req_tready       : in std_logic;
        m_axis_pic_req_tdata        : out std_logic_vector(39 downto 0);
        s_axis_pic_res_tvalid       : in std_logic;
        s_axis_pic_res_tready       : out std_logic;
        s_axis_pic_res_tdata        : in std_logic_vector(15 downto 0);
        -- led green
        m_axis_led_0_req_tvalid     : out std_logic;
        m_axis_led_0_req_tready     : in std_logic;
        m_axis_led_0_req_tdata      : out std_logic_vector(39 downto 0);
        s_axis_led_0_res_tvalid     : in std_logic;
        s_axis_led_0_res_tready     : out std_logic;
        s_axis_led_0_res_tdata      : in std_logic_vector(15 downto 0);
        -- led red (15 downto 0)
        m_axis_led_1_req_tvalid     : out std_logic;
        m_axis_led_1_req_tready     : in std_logic;
        m_axis_led_1_req_tdata      : out std_logic_vector(39 downto 0);
        s_axis_led_1_res_tvalid     : in std_logic;
        s_axis_led_1_res_tready     : out std_logic;
        s_axis_led_1_res_tdata      : in std_logic_vector(15 downto 0);
        -- led red (17 downto 16)
        m_axis_led_2_req_tvalid     : out std_logic;
        m_axis_led_2_req_tready     : in std_logic;
        m_axis_led_2_req_tdata      : out std_logic_vector(39 downto 0);
        s_axis_led_2_res_tvalid     : in std_logic;
        s_axis_led_2_res_tready     : out std_logic;
        s_axis_led_2_res_tdata      : in std_logic_vector(15 downto 0);
        -- sw (17 downto 16)
        m_axis_sw_0_req_tvalid      : out std_logic;
        m_axis_sw_0_req_tready      : in std_logic;
        m_axis_sw_0_req_tdata       : out std_logic_vector(39 downto 0);
        s_axis_sw_0_res_tvalid      : in std_logic;
        s_axis_sw_0_res_tready      : out std_logic;
        s_axis_sw_0_res_tdata       : in std_logic_vector(15 downto 0);
        -- sw (15 downto 0)
        m_axis_sw_1_req_tvalid      : out std_logic;
        m_axis_sw_1_req_tready      : in std_logic;
        m_axis_sw_1_req_tdata       : out std_logic_vector(39 downto 0);
        s_axis_sw_1_res_tvalid      : in std_logic;
        s_axis_sw_1_res_tready      : out std_logic;
        s_axis_sw_1_res_tdata       : in std_logic_vector(15 downto 0);
        -- hex_group_0
        m_axis_hex_0_req_tvalid     : out std_logic;
        m_axis_hex_0_req_tready     : in std_logic;
        m_axis_hex_0_req_tdata      : out std_logic_vector(39 downto 0);
        s_axis_hex_0_res_tvalid     : in std_logic;
        s_axis_hex_0_res_tready     : out std_logic;
        s_axis_hex_0_res_tdata      : in std_logic_vector(15 downto 0);
        -- hex_group_1
        m_axis_hex_1_req_tvalid     : out std_logic;
        m_axis_hex_1_req_tready     : in std_logic;
        m_axis_hex_1_req_tdata      : out std_logic_vector(39 downto 0);
        s_axis_hex_1_res_tvalid     : in std_logic;
        s_axis_hex_1_res_tready     : out std_logic;
        s_axis_hex_1_res_tdata      : in std_logic_vector(15 downto 0);
        -- uart
        m_axis_uart_req_tvalid      : out std_logic;
        m_axis_uart_req_tready      : in std_logic;
        m_axis_uart_req_tdata       : out std_logic_vector(39 downto 0);
        s_axis_uart_res_tvalid      : in std_logic;
        s_axis_uart_res_tready      : out std_logic;
        s_axis_uart_res_tdata       : in std_logic_vector(15 downto 0);
        -- kbd (port 60)
        m_axis_kbd_req_tvalid       : out std_logic;
        m_axis_kbd_req_tready       : in std_logic;
        m_axis_kbd_req_tdata        : out std_logic_vector(39 downto 0);
        s_axis_kbd_res_tvalid       : in std_logic;
        s_axis_kbd_res_tready       : out std_logic;
        s_axis_kbd_res_tdata        : in std_logic_vector(15 downto 0);
        -- port 61
        m_axis_port_61_req_tvalid   : out std_logic;
        m_axis_port_61_req_tready   : in std_logic;
        m_axis_port_61_req_tdata    : out std_logic_vector(39 downto 0);
        s_axis_port_61_res_tvalid   : in std_logic;
        s_axis_port_61_res_tready   : out std_logic;
        s_axis_port_61_res_tdata    : in std_logic_vector(15 downto 0);
        -- mmu
        m_axis_mmu_req_tvalid       : out std_logic;
        m_axis_mmu_req_tready       : in std_logic;
        m_axis_mmu_req_tdata        : out std_logic_vector(39 downto 0);
        s_axis_mmu_res_tvalid       : in std_logic;
        s_axis_mmu_res_tready       : out std_logic;
        s_axis_mmu_res_tdata        : in std_logic_vector(15 downto 0)
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

    signal io_req_s_tvalid      : std_logic;
    signal io_req_s_tready      : std_logic;
    signal io_req_s_tdata       : std_logic_vector(39 downto 0);
    signal io_rd_m_tvalid       : std_logic;
    signal io_rd_m_tready       : std_logic;
    signal io_rd_m_tdata        : std_logic_vector(15 downto 0);
        -- pit
    signal pit_req_m_tvalid     : std_logic;
    signal pit_req_m_tready     : std_logic;
    signal pit_req_m_tdata      : std_logic_vector(39 downto 0);
    signal pit_rd_s_tvalid      : std_logic;
    signal pit_rd_s_tready      : std_logic;
    signal pit_rd_s_tdata       : std_logic_vector(15 downto 0);
        -- pic
    signal pic_req_m_tvalid     : std_logic;
    signal pic_req_m_tready     : std_logic;
    signal pic_req_m_tdata      : std_logic_vector(39 downto 0);
    signal pic_rd_s_tvalid      : std_logic;
    signal pic_rd_s_tready      : std_logic;
    signal pic_rd_s_tdata       : std_logic_vector(15 downto 0);
        -- led green
    signal led_0_req_m_tvalid   : std_logic;
    signal led_0_req_m_tready   : std_logic;
    signal led_0_req_m_tdata    : std_logic_vector(39 downto 0);
    signal led_0_rd_s_tvalid    : std_logic;
    signal led_0_rd_s_tready    : std_logic;
    signal led_0_rd_s_tdata     : std_logic_vector(15 downto 0);
        -- led red (15 downto 0)
    signal led_1_req_m_tvalid   : std_logic;
    signal led_1_req_m_tready   : std_logic;
    signal led_1_req_m_tdata    : std_logic_vector(39 downto 0);
    signal led_1_rd_s_tvalid    : std_logic;
    signal led_1_rd_s_tready    : std_logic;
    signal led_1_rd_s_tdata     : std_logic_vector(15 downto 0);
        -- led red (17 downto 16)
    signal led_2_req_m_tvalid   : std_logic;
    signal led_2_req_m_tready   : std_logic;
    signal led_2_req_m_tdata    : std_logic_vector(39 downto 0);
    signal led_2_rd_s_tvalid    : std_logic;
    signal led_2_rd_s_tready    : std_logic;
    signal led_2_rd_s_tdata     : std_logic_vector(15 downto 0);
        -- sw (17 downto 16)
    signal sw_0_req_m_tvalid    : std_logic;
    signal sw_0_req_m_tready    : std_logic;
    signal sw_0_req_m_tdata     : std_logic_vector(39 downto 0);
    signal sw_0_rd_s_tvalid     : std_logic;
    signal sw_0_rd_s_tready     : std_logic;
    signal sw_0_rd_s_tdata      : std_logic_vector(15 downto 0);
        -- sw (15 downto 0)
    signal sw_1_req_m_tvalid    : std_logic;
    signal sw_1_req_m_tready    : std_logic;
    signal sw_1_req_m_tdata     : std_logic_vector(39 downto 0);
    signal sw_1_rd_s_tvalid     : std_logic;
    signal sw_1_rd_s_tready     : std_logic;
    signal sw_1_rd_s_tdata      : std_logic_vector(15 downto 0);
        -- hex_group_0
    signal hex_0_req_m_tvalid   : std_logic;
    signal hex_0_req_m_tready   : std_logic;
    signal hex_0_req_m_tdata    : std_logic_vector(39 downto 0);
    signal hex_0_rd_s_tvalid    : std_logic;
    signal hex_0_rd_s_tready    : std_logic;
    signal hex_0_rd_s_tdata     : std_logic_vector(15 downto 0);
        -- hex_group_1
    signal hex_1_req_m_tvalid   : std_logic;
    signal hex_1_req_m_tready   : std_logic;
    signal hex_1_req_m_tdata    : std_logic_vector(39 downto 0);
    signal hex_1_rd_s_tvalid    : std_logic;
    signal hex_1_rd_s_tready    : std_logic;
    signal hex_1_rd_s_tdata     : std_logic_vector(15 downto 0);
        -- uart
    signal uart_req_m_tvalid    : std_logic;
    signal uart_req_m_tready    : std_logic;
    signal uart_req_m_tdata     : std_logic_vector(39 downto 0);
    signal uart_rd_s_tvalid     : std_logic;
    signal uart_rd_s_tready     : std_logic;
    signal uart_rd_s_tdata      : std_logic_vector(15 downto 0);
        -- kbd (port 60)
    signal kbd_req_m_tvalid     : std_logic;
    signal kbd_req_m_tready     : std_logic;
    signal kbd_req_m_tdata      : std_logic_vector(39 downto 0);
    signal kbd_rd_s_tvalid      : std_logic;
    signal kbd_rd_s_tready      : std_logic;
    signal kbd_rd_s_tdata       : std_logic_vector(15 downto 0);
        -- port 61
    signal port_61_req_m_tvalid : std_logic;
    signal port_61_req_m_tready : std_logic;
    signal port_61_req_m_tdata  : std_logic_vector(39 downto 0);
    signal port_61_rd_s_tvalid  : std_logic;
    signal port_61_rd_s_tready  : std_logic;
    signal port_61_rd_s_tdata   : std_logic_vector(15 downto 0);
        -- mmu
    signal mmu_req_m_tvalid     : std_logic;
    signal mmu_req_m_tready     : std_logic;
    signal mmu_req_m_tdata      : std_logic_vector(39 downto 0);
    signal mmu_rd_s_tvalid      : std_logic;
    signal mmu_rd_s_tready      : std_logic;
    signal mmu_rd_s_tdata       : std_logic_vector(15 downto 0);

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
    signal mmu_req_cs           : std_logic;
    signal kbd_req_cs           : std_logic;

    signal fifo_io_s_tvalid     : std_logic;
    signal fifo_io_s_tready     : std_logic;
    signal fifo_io_s_tdata      : std_logic_vector(3 downto 0);
    signal fifo_io_s_selector   : std_logic_vector(12 downto 0);
    signal fifo_io_m_tvalid     : std_logic;
    signal fifo_io_m_tready     : std_logic;
    signal fifo_io_m_tdata      : std_logic_vector(3 downto 0);

    signal rd_selector          : std_logic_vector(12 downto 0);

begin
    -- i/o assigns
    io_req_s_tvalid             <= s_axis_io_req_tvalid;
    s_axis_io_req_tready        <= io_req_s_tready;
    io_req_s_tdata              <= s_axis_io_req_tdata;
    m_axis_io_res_tvalid        <= io_rd_m_tvalid;
    io_rd_m_tready              <= m_axis_io_res_tready;
    m_axis_io_res_tdata         <= io_rd_m_tdata;

    -- pit
    m_axis_pit_req_tvalid       <= pit_req_m_tvalid;
    pit_req_m_tready            <= m_axis_pit_req_tready;
    m_axis_pit_req_tdata        <= pit_req_m_tdata;
    pit_rd_s_tvalid             <= s_axis_pit_res_tvalid;
    s_axis_pit_res_tready       <= pit_rd_s_tready;
    pit_rd_s_tdata              <= s_axis_pit_res_tdata;
    -- pic
    m_axis_pic_req_tvalid       <= pic_req_m_tvalid;
    pic_req_m_tready            <= m_axis_pic_req_tready;
    m_axis_pic_req_tdata        <= pic_req_m_tdata;
    pic_rd_s_tvalid             <= s_axis_pic_res_tvalid;
    s_axis_pic_res_tready       <= pic_rd_s_tready;
    pic_rd_s_tdata              <= s_axis_pic_res_tdata;
    -- led green
    m_axis_led_0_req_tvalid     <= led_0_req_m_tvalid;
    led_0_req_m_tready          <= m_axis_led_0_req_tready;
    m_axis_led_0_req_tdata      <= led_0_req_m_tdata;
    led_0_rd_s_tvalid           <= s_axis_led_0_res_tvalid;
    s_axis_led_0_res_tready     <= led_0_rd_s_tready;
    led_0_rd_s_tdata            <= s_axis_led_0_res_tdata;
    -- led red (15 downto 0)
    m_axis_led_1_req_tvalid     <= led_1_req_m_tvalid;
    led_1_req_m_tready          <= m_axis_led_1_req_tready;
    m_axis_led_1_req_tdata      <= led_1_req_m_tdata;
    led_1_rd_s_tvalid           <= s_axis_led_1_res_tvalid;
    s_axis_led_1_res_tready     <= led_1_rd_s_tready;
    led_1_rd_s_tdata            <= s_axis_led_1_res_tdata;
    -- led red (17 downto 16)
    m_axis_led_2_req_tvalid     <= led_2_req_m_tvalid;
    led_2_req_m_tready          <= m_axis_led_2_req_tready;
    m_axis_led_2_req_tdata      <= led_2_req_m_tdata;
    led_2_rd_s_tvalid           <= s_axis_led_2_res_tvalid;
    s_axis_led_2_res_tready     <= led_2_rd_s_tready;
    led_2_rd_s_tdata            <= s_axis_led_2_res_tdata;
    -- sw (17 downto 16)
    m_axis_sw_0_req_tvalid      <= sw_0_req_m_tvalid;
    sw_0_req_m_tready           <= m_axis_sw_0_req_tready;
    m_axis_sw_0_req_tdata       <= sw_0_req_m_tdata;
    sw_0_rd_s_tvalid            <= s_axis_sw_0_res_tvalid;
    s_axis_sw_0_res_tready      <= sw_0_rd_s_tready;
    sw_0_rd_s_tdata             <= s_axis_sw_0_res_tdata;
    -- sw (15 downto 0)
    m_axis_sw_1_req_tvalid      <= sw_1_req_m_tvalid;
    sw_1_req_m_tready           <= m_axis_sw_1_req_tready;
    m_axis_sw_1_req_tdata       <= sw_1_req_m_tdata;
    sw_1_rd_s_tvalid            <= s_axis_sw_1_res_tvalid;
    s_axis_sw_1_res_tready      <= sw_1_rd_s_tready;
    sw_1_rd_s_tdata             <= s_axis_sw_1_res_tdata;
    -- hex_group_0
    m_axis_hex_0_req_tvalid     <= hex_0_req_m_tvalid;
    hex_0_req_m_tready          <= m_axis_hex_0_req_tready;
    m_axis_hex_0_req_tdata      <= hex_0_req_m_tdata;
    hex_0_rd_s_tvalid           <= s_axis_hex_0_res_tvalid;
    s_axis_hex_0_res_tready     <= hex_0_rd_s_tready;
    hex_0_rd_s_tdata            <= s_axis_hex_0_res_tdata;
    -- hex_group_1
    m_axis_hex_1_req_tvalid     <= hex_1_req_m_tvalid;
    hex_1_req_m_tready          <= m_axis_hex_1_req_tready;
    m_axis_hex_1_req_tdata      <= hex_1_req_m_tdata;
    hex_1_rd_s_tvalid           <= s_axis_hex_1_res_tvalid;
    s_axis_hex_1_res_tready     <= hex_1_rd_s_tready;
    hex_1_rd_s_tdata            <= s_axis_hex_1_res_tdata;
    -- uart
    m_axis_uart_req_tvalid      <= uart_req_m_tvalid;
    uart_req_m_tready           <= m_axis_uart_req_tready;
    m_axis_uart_req_tdata       <= uart_req_m_tdata;
    uart_rd_s_tvalid            <= s_axis_uart_res_tvalid;
    s_axis_uart_res_tready      <= uart_rd_s_tready;
    uart_rd_s_tdata             <= s_axis_uart_res_tdata;
    -- port 60
    m_axis_kbd_req_tvalid       <= kbd_req_m_tvalid;
    kbd_req_m_tready            <= m_axis_kbd_req_tready;
    m_axis_kbd_req_tdata        <= kbd_req_m_tdata;
    kbd_rd_s_tvalid             <= s_axis_kbd_res_tvalid;
    s_axis_kbd_res_tready       <= kbd_rd_s_tready;
    kbd_rd_s_tdata              <= s_axis_kbd_res_tdata;
    -- port 61
    m_axis_port_61_req_tvalid   <= port_61_req_m_tvalid;
    port_61_req_m_tready        <= m_axis_port_61_req_tready;
    m_axis_port_61_req_tdata    <= port_61_req_m_tdata;
    port_61_rd_s_tvalid         <= s_axis_port_61_res_tvalid;
    s_axis_port_61_res_tready   <= port_61_rd_s_tready;
    port_61_rd_s_tdata          <= s_axis_port_61_res_tdata;
    -- mmu
    m_axis_mmu_req_tvalid       <= mmu_req_m_tvalid;
    mmu_req_m_tready            <= m_axis_mmu_req_tready;
    m_axis_mmu_req_tdata        <= mmu_req_m_tdata;
    mmu_rd_s_tvalid             <= s_axis_mmu_res_tvalid;
    s_axis_mmu_res_tready       <= mmu_rd_s_tready;
    mmu_rd_s_tdata              <= s_axis_mmu_res_tdata;


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
        (kbd_req_m_tvalid = '0' or (kbd_req_m_tvalid = '1' and kbd_req_m_tready = '1')) and
        (port_61_req_m_tvalid = '0' or (port_61_req_m_tvalid = '1' and port_61_req_m_tready = '1')) and
        (uart_req_m_tvalid = '0' or (uart_req_m_tvalid = '1' and uart_req_m_tready = '1')) and
        (mmu_req_m_tvalid = '0' or (mmu_req_m_tvalid = '1' and mmu_req_m_tready = '1')) and
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
    mmu_rd_s_tready     <= '1' when (io_rd_m_tvalid = '0' or (io_rd_m_tvalid = '1' and io_rd_m_tready = '1')) and fifo_io_m_tvalid = '1' and fifo_io_m_tdata = x"B" else '0';
    kbd_rd_s_tready     <= '1' when (io_rd_m_tvalid = '0' or (io_rd_m_tvalid = '1' and io_rd_m_tready = '1')) and fifo_io_m_tvalid = '1' and fifo_io_m_tdata = x"C" else '0';

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
    fifo_io_s_selector(11) <= mmu_req_cs;
    fifo_io_s_selector(12) <= kbd_req_cs;

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

    mmu_req_cs <= '1' when (
        io_req_s_tdata(31 downto 16) = x"0320"
    ) else '0';

    port_61_req_cs <= '1' when (
        io_req_s_tdata(31 downto 16) = x"0061"
    ) else '0';

    kbd_req_cs <= '1' when (
        io_req_s_tdata(31 downto 16) = x"0060" or
        io_req_s_tdata(31 downto 16) = x"0062" or
        io_req_s_tdata(31 downto 16) = x"0063"
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

    -- latching kbd request
    latch_kbd_req_proc: process (clk) begin
        if rising_edge(clk) then
            -- Resettable
            if resetn = '0' then
                kbd_req_m_tvalid <= '0';
            else
                if (io_req_s_tvalid = '1' and io_req_s_tready = '1' and kbd_req_cs = '1') then
                    kbd_req_m_tvalid <= '1';
                elsif (kbd_req_m_tready = '1') then
                    kbd_req_m_tvalid <= '0';
                end if;
            end if;
            -- Without reset
            if (io_req_s_tvalid = '1' and io_req_s_tready = '1') then
                kbd_req_m_tdata <= io_req_s_tdata;
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

    -- latching mmu request
    latch_mmu_req_proc: process (clk) begin
        if rising_edge(clk) then
            -- Resettable
            if resetn = '0' then
                mmu_req_m_tvalid <= '0';
            else
                if (io_req_s_tvalid = '1' and io_req_s_tready = '1' and mmu_req_cs = '1') then
                    mmu_req_m_tvalid <= '1';
                elsif (mmu_req_m_tready = '1') then
                    mmu_req_m_tvalid <= '0';
                end if;
            end if;
            -- Without reset
            if (io_req_s_tvalid = '1' and io_req_s_tready = '1') then
                mmu_req_m_tdata <= io_req_s_tdata;
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
    rd_selector(11) <= '1' when (mmu_rd_s_tvalid = '1' and mmu_rd_s_tready = '1')  else '0';
    rd_selector(12) <= '1' when (kbd_rd_s_tvalid = '1' and kbd_rd_s_tready = '1')  else '0';

    latch_resp_proc : process (clk) begin
        if rising_edge(clk) then
            -- Resettable
            if resetn = '0' then
                io_rd_m_tvalid <= '0';
            else
                if (rd_selector /= "0000000000000") then
                    io_rd_m_tvalid <= '1';
                elsif (io_rd_m_tready = '1') then
                    io_rd_m_tvalid <= '0';
                end if;
            end if;
            -- Without reset
            case rd_selector is
                when "0000000000001" => io_rd_m_tdata <= pit_rd_s_tdata;
                when "0000000000010" => io_rd_m_tdata <= pic_rd_s_tdata;
                when "0000000000100" => io_rd_m_tdata <= led_0_rd_s_tdata;
                when "0000000001000" => io_rd_m_tdata <= led_1_rd_s_tdata;
                when "0000000010000" => io_rd_m_tdata <= led_2_rd_s_tdata;
                when "0000000100000" => io_rd_m_tdata <= sw_0_rd_s_tdata;
                when "0000001000000" => io_rd_m_tdata <= sw_0_rd_s_tdata;
                when "0000010000000" => io_rd_m_tdata <= port_61_rd_s_tdata;
                when "0000100000000" => io_rd_m_tdata <= hex_0_rd_s_tdata;
                when "0001000000000" => io_rd_m_tdata <= hex_1_rd_s_tdata;
                when "0010000000000" => io_rd_m_tdata <= uart_rd_s_tdata;
                when "0100000000000" => io_rd_m_tdata <= mmu_rd_s_tdata;
                when "1000000000000" => io_rd_m_tdata <= kbd_rd_s_tdata;
                when others         => io_rd_m_tdata <= led_0_rd_s_tdata;
            end case;
        end if;
    end process;

end architecture;
