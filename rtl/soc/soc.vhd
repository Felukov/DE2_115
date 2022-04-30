
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

entity soc is
    port (
        clk                         : in std_logic;
        resetn                      : in std_logic;

        LEDG                        : out std_logic_vector(8 downto 0);
        SW                          : in std_logic_vector(17 downto 0);

        HEX0                        : out std_logic_vector(6 downto 0);
        HEX1                        : out std_logic_vector(6 downto 0);
        HEX2                        : out std_logic_vector(6 downto 0);
        HEX3                        : out std_logic_vector(6 downto 0);
        HEX4                        : out std_logic_vector(6 downto 0);
        HEX5                        : out std_logic_vector(6 downto 0);
        HEX6                        : out std_logic_vector(6 downto 0);
        HEX7                        : out std_logic_vector(6 downto 0);

        BT_UART_RX                  : in std_logic;
        BT_UART_TX                  : out std_logic
    );
end entity soc;

architecture rtl of soc is

    constant ADDR_WIDTH             : natural := 12;
    constant DATA_WIDTH             : natural := 32;
    constant USER_WIDTH             : natural := 32;
    constant BYTES                  : natural := 4;

    component on_chip_ram is
        generic (
            ADDR_WIDTH              : natural := 12;
            DATA_WIDTH              : natural := 32;
            USER_WIDTH              : natural := 32;
            BYTES                   : natural := 4
        );
        port (
            clk                     : in std_logic;
            resetn                  : in std_logic;

            wr_s_tvalid             : in std_logic;
            wr_s_taddr              : in std_logic_vector(ADDR_WIDTH-1 downto 0);
            wr_s_tmask              : in std_logic_vector(BYTES-1 downto 0);
            wr_s_tdata              : in std_logic_vector(DATA_WIDTH-1 downto 0);

            rd_s_tvalid             : in std_logic;
            rd_s_taddr              : in std_logic_vector(ADDR_WIDTH-1 downto 0);
            rd_s_tuser              : in std_logic_vector(USER_WIDTH-1 downto 0);

            rd_m_tvalid             : out std_logic;
            rd_m_tdata              : out std_logic_vector(DATA_WIDTH-1 downto 0);
            rd_m_tuser              : out std_logic_vector(USER_WIDTH-1 downto 0)

        );
    end component on_chip_ram;

    component cpu86 is
        port (
            clk                     : in std_logic;
            resetn                  : in std_logic;

            mem_req_m_tvalid        : out std_logic;
            mem_req_m_tready        : in std_logic;
            mem_req_m_tdata         : out std_logic_vector(63 downto 0);

            mem_rd_s_tvalid         : in std_logic;
            mem_rd_s_tdata          : in std_logic_vector(31 downto 0);

            io_req_m_tvalid         : out std_logic;
            io_req_m_tready         : in std_logic;
            io_req_m_tdata          : out std_logic_vector(39 downto 0);

            io_rd_s_tvalid          : in std_logic;
            io_rd_s_tready          : out std_logic;
            io_rd_s_tdata           : in std_logic_vector(15 downto 0);

            interrupt_valid         : in std_logic;
            interrupt_data          : in std_logic_vector(7 downto 0);
            interrupt_ack           : out std_logic
        );
    end component cpu86;

    component soc_io_interconnect is
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
            hex_0_req_m_tvalid      : out std_logic;
            hex_0_req_m_tready      : in std_logic;
            hex_0_req_m_tdata       : out std_logic_vector(39 downto 0);
            hex_0_rd_s_tvalid       : in std_logic;
            hex_0_rd_s_tready       : out std_logic;
            hex_0_rd_s_tdata        : in std_logic_vector(15 downto 0);
            -- hex_group_1
            hex_1_req_m_tvalid      : out std_logic;
            hex_1_req_m_tready      : in std_logic;
            hex_1_req_m_tdata       : out std_logic_vector(39 downto 0);
            hex_1_rd_s_tvalid       : in std_logic;
            hex_1_rd_s_tready       : out std_logic;
            hex_1_rd_s_tdata        : in std_logic_vector(15 downto 0);
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
    end component soc_io_interconnect;

    component pit_8254 is
        port (
            clk                     : in std_logic;
            resetn                  : in std_logic;

            io_req_s_tvalid         : in std_logic;
            io_req_s_tready         : out std_logic;
            io_req_s_tdata          : in std_logic_vector(39 downto 0);

            io_rd_m_tvalid          : out std_logic;
            io_rd_m_tready          : in std_logic;
            io_rd_m_tdata           : out std_logic_vector(15 downto 0);

            event_irq               : out std_logic;
            event_timer             : out std_logic
        );
    end component pit_8254;

    component pic is
        port(
            clk                     : in std_logic;
            resetn                  : in std_logic;

            io_req_s_tvalid         : in std_logic;
            io_req_s_tready         : out std_logic;
            io_req_s_tdata          : in std_logic_vector(39 downto 0);

            io_rd_m_tvalid          : out std_logic;
            io_rd_m_tready          : in std_logic;
            io_rd_m_tdata           : out std_logic_vector(15 downto 0);

            interrupt_input         : in std_logic_vector(15 downto 0);

            interrupt_valid         : out std_logic;
            interrupt_data          : out std_logic_vector(7 downto 0);
            interrupt_ack           : in std_logic
        );
    end component pic;

    component soc_io_switches is
        port (
            clk                     : in std_logic;
            resetn                  : in std_logic;

            io_req_s_tvalid         : in std_logic;
            io_req_s_tready         : out std_logic;
            io_req_s_tdata          : in std_logic_vector(39 downto 0);
            io_rd_m_tvalid          : out std_logic;
            io_rd_m_tready          : in std_logic;
            io_rd_m_tdata           : out std_logic_vector(15 downto 0);

            switches                : in std_logic_vector(15 downto 0)
        );
    end component soc_io_switches;

    component soc_io_leds is
        generic (
            INIT_VALUE              : std_logic_vector
        );
        port (
            clk                     : in std_logic;
            resetn                  : in std_logic;

            io_req_s_tvalid         : in std_logic;
            io_req_s_tready         : out std_logic;
            io_req_s_tdata          : in std_logic_vector(39 downto 0);
            io_rd_m_tvalid          : out std_logic;
            io_rd_m_tready          : in std_logic;
            io_rd_m_tdata           : out std_logic_vector(15 downto 0);

            leds                    : out std_logic_vector(15 downto 0)
        );
    end component soc_io_leds;

    component soc_io_port_61 is
        generic (
            INIT_VALUE              : std_logic_vector
        );
        port (
            clk                     : in std_logic;
            resetn                  : in std_logic;

            io_req_s_tvalid         : in std_logic;
            io_req_s_tready         : out std_logic;
            io_req_s_tdata          : in std_logic_vector(39 downto 0);
            io_rd_m_tvalid          : out std_logic;
            io_rd_m_tready          : in std_logic;
            io_rd_m_tdata           : out std_logic_vector(15 downto 0);

            event_timer             : in std_logic
        );
    end component soc_io_port_61;

    component soc_io_seg_7 is
        generic (
            INIT_VALUE              : std_logic_vector
        );
        port (
            clk                     : in std_logic;
            resetn                  : in std_logic;

            io_req_s_tvalid         : in std_logic;
            io_req_s_tready         : out std_logic;
            io_req_s_tdata          : in std_logic_vector(39 downto 0);
            io_rd_m_tvalid          : out std_logic;
            io_rd_m_tready          : in std_logic;
            io_rd_m_tdata           : out std_logic_vector(15 downto 0);

            HEX0                    : out std_logic_vector(6 downto 0);
            HEX1                    : out std_logic_vector(6 downto 0);
            HEX2                    : out std_logic_vector(6 downto 0);
            HEX3                    : out std_logic_vector(6 downto 0)
        );
    end component soc_io_seg_7;

    component soc_io_uart is
        port (
            clk                     : in std_logic;
            resetn                  : in std_logic;

            io_req_s_tvalid         : in std_logic;
            io_req_s_tready         : out std_logic;
            io_req_s_tdata          : in std_logic_vector(39 downto 0);

            io_rd_m_tvalid          : out std_logic;
            io_rd_m_tready          : in std_logic;
            io_rd_m_tdata           : out std_logic_vector(15 downto 0);

            rx                      : in std_logic;
            tx                      : out std_logic
        );
    end component soc_io_uart;

    attribute keep: boolean;
    signal cpu_resetn               : std_logic;
    attribute keep of cpu_resetn    : signal is true;
    signal dev_resetn               : std_logic;
    attribute keep of dev_resetn    : signal is true;
    signal con_resetn               : std_logic;
    attribute keep of con_resetn    : signal is true;

    signal mem_req_m_tvalid         : std_logic;
    signal mem_req_m_tready         : std_logic;
    signal mem_req_m_tdata          : std_logic_vector(63 downto 0);
    signal mem_rd_s_tvalid          : std_logic;
    signal mem_rd_s_tdata           : std_logic_vector(31 downto 0);

    signal io_req_tvalid            : std_logic;
    signal io_req_tready            : std_logic;
    signal io_req_tdata             : std_logic_vector(39 downto 0);
    signal io_rd_tvalid             : std_logic;
    signal io_rd_tready             : std_logic;
    signal io_rd_tdata              : std_logic_vector(15 downto 0);

    signal pit_req_tvalid           : std_logic;
    signal pit_req_tready           : std_logic;
    signal pit_req_tdata            : std_logic_vector(39 downto 0);
    signal pit_rd_tvalid            : std_logic;
    signal pit_rd_tready            : std_logic;
    signal pit_rd_tdata             : std_logic_vector(15 downto 0);

    signal pic_req_tvalid           : std_logic;
    signal pic_req_tready           : std_logic;
    signal pic_req_tdata            : std_logic_vector(39 downto 0);
    signal pic_rd_tvalid            : std_logic;
    signal pic_rd_tready            : std_logic;
    signal pic_rd_tdata             : std_logic_vector(15 downto 0);

    signal wr_s_tvalid              : std_logic;
    signal wr_s_taddr               : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal wr_s_tmask               : std_logic_vector(BYTES-1 downto 0);
    signal wr_s_tdata               : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal rd_s_tvalid              : std_logic;
    signal rd_s_taddr               : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal rd_m_tvalid              : std_logic;
    signal rd_m_tdata               : std_logic_vector(DATA_WIDTH-1 downto 0);

    signal sw_0_req_tvalid          : std_logic;
    signal sw_0_req_tready          : std_logic;
    signal sw_0_req_tdata           : std_logic_vector(39 downto 0);
    signal sw_0_rd_tvalid           : std_logic;
    signal sw_0_rd_tready           : std_logic;
    signal sw_0_rd_tdata            : std_logic_vector(15 downto 0);

    signal leds_0_req_tvalid        : std_logic;
    signal leds_0_req_tready        : std_logic;
    signal leds_0_req_tdata         : std_logic_vector(39 downto 0);
    signal leds_0_rd_tvalid         : std_logic;
    signal leds_0_rd_tready         : std_logic;
    signal leds_0_rd_tdata          : std_logic_vector(15 downto 0);

    signal port_61_req_tvalid       : std_logic;
    signal port_61_req_tready       : std_logic;
    signal port_61_req_tdata        : std_logic_vector(39 downto 0);
    signal port_61_rd_tvalid        : std_logic;
    signal port_61_rd_tready        : std_logic;
    signal port_61_rd_tdata         : std_logic_vector(15 downto 0);

    signal hex_0_req_tvalid         : std_logic;
    signal hex_0_req_tready         : std_logic;
    signal hex_0_req_tdata          : std_logic_vector(39 downto 0);
    signal hex_0_rd_tvalid          : std_logic;
    signal hex_0_rd_tready          : std_logic;
    signal hex_0_rd_tdata           : std_logic_vector(15 downto 0);

    signal hex_1_req_tvalid         : std_logic;
    signal hex_1_req_tready         : std_logic;
    signal hex_1_req_tdata          : std_logic_vector(39 downto 0);
    signal hex_1_rd_tvalid          : std_logic;
    signal hex_1_rd_tready          : std_logic;
    signal hex_1_rd_tdata           : std_logic_vector(15 downto 0);

    signal uart_req_tvalid          : std_logic;
    signal uart_req_tready          : std_logic;
    signal uart_req_tdata           : std_logic_vector(39 downto 0);
    signal uart_rd_tvalid           : std_logic;
    signal uart_rd_tready           : std_logic;
    signal uart_rd_tdata            : std_logic_vector(15 downto 0);

    signal led_reg                  : std_logic_vector(7 downto 0);

    signal event_timer              : std_logic;
    signal event_irq                : std_logic;

    signal interrupt_vector         : std_logic_vector(15 downto 0);

    signal interrupt_valid          : std_logic;
    signal interrupt_data           : std_logic_vector(7 downto 0);
    signal interrupt_ack            : std_logic;

    signal ledg_out                 : std_logic_vector(15 downto 0);

begin

    on_chip_ram_inst : on_chip_ram port map (
        clk                     => clk,
        resetn                  => con_resetn,

        wr_s_tvalid             => wr_s_tvalid,
        wr_s_taddr              => wr_s_taddr,
        wr_s_tmask              => wr_s_tmask,
        wr_s_tdata              => wr_s_tdata,

        rd_s_tvalid             => rd_s_tvalid,
        rd_s_taddr              => rd_s_taddr,
        rd_s_tuser              => x"00000000",

        rd_m_tvalid             => rd_m_tvalid,
        rd_m_tdata              => rd_m_tdata,
        rd_m_tuser              => open
    );

    -- Module cpu86 instantiation
    cpu86_inst : cpu86 port map(
        clk                     => clk,
        resetn                  => cpu_resetn,

        mem_req_m_tvalid        => mem_req_m_tvalid,
        mem_req_m_tready        => mem_req_m_tready,
        mem_req_m_tdata         => mem_req_m_tdata,

        mem_rd_s_tvalid         => mem_rd_s_tvalid,
        mem_rd_s_tdata          => mem_rd_s_tdata,

        io_req_m_tvalid         => io_req_tvalid,
        io_req_m_tready         => io_req_tready,
        io_req_m_tdata          => io_req_tdata,

        io_rd_s_tvalid          => io_rd_tvalid,
        io_rd_s_tready          => io_rd_tready,
        io_rd_s_tdata           => io_rd_tdata,

        interrupt_valid         => interrupt_valid,
        interrupt_data          => interrupt_data,
        interrupt_ack           => interrupt_ack
    );

    -- Module soc_io_interconnect instantiation
    soc_io_interconnect_inst : soc_io_interconnect port map (
        -- global singals
        clk                     => clk,
        resetn                  => con_resetn,
        -- cpu io
        io_req_s_tvalid         => io_req_tvalid,
        io_req_s_tready         => io_req_tready,
        io_req_s_tdata          => io_req_tdata,
        io_rd_m_tvalid          => io_rd_tvalid,
        io_rd_m_tready          => io_rd_tready,
        io_rd_m_tdata           => io_rd_tdata,
        -- pit
        pit_req_m_tvalid        => pit_req_tvalid,
        pit_req_m_tready        => pit_req_tready,
        pit_req_m_tdata         => pit_req_tdata,
        pit_rd_s_tvalid         => pit_rd_tvalid,
        pit_rd_s_tready         => pit_rd_tready,
        pit_rd_s_tdata          => pit_rd_tdata,
        -- pic
        pic_req_m_tvalid        => pic_req_tvalid,
        pic_req_m_tready        => pic_req_tready,
        pic_req_m_tdata         => pic_req_tdata,
        pic_rd_s_tvalid         => pic_rd_tvalid,
        pic_rd_s_tready         => pic_rd_tready,
        pic_rd_s_tdata          => pic_rd_tdata,
        -- led_0
        led_0_req_m_tvalid      => leds_0_req_tvalid,
        led_0_req_m_tready      => leds_0_req_tready,
        led_0_req_m_tdata       => leds_0_req_tdata,
        led_0_rd_s_tvalid       => leds_0_rd_tvalid,
        led_0_rd_s_tready       => leds_0_rd_tready,
        led_0_rd_s_tdata        => leds_0_rd_tdata,
        -- led_1
        led_1_req_m_tvalid      => open,
        led_1_req_m_tready      => '1',
        led_1_req_m_tdata       => open,
        led_1_rd_s_tvalid       => '0',
        led_1_rd_s_tready       => open,
        led_1_rd_s_tdata        => x"0000",
        -- led_2
        led_2_req_m_tvalid      => open,
        led_2_req_m_tready      => '1',
        led_2_req_m_tdata       => open,
        led_2_rd_s_tvalid       => '0',
        led_2_rd_s_tready       => open,
        led_2_rd_s_tdata        => x"0000",
        -- sw_0
        sw_0_req_m_tvalid       => sw_0_req_tvalid,
        sw_0_req_m_tready       => sw_0_req_tready,
        sw_0_req_m_tdata        => sw_0_req_tdata,
        sw_0_rd_s_tvalid        => sw_0_rd_tvalid,
        sw_0_rd_s_tready        => sw_0_rd_tready,
        sw_0_rd_s_tdata         => sw_0_rd_tdata,
        -- sw_1
        sw_1_req_m_tvalid       => open,
        sw_1_req_m_tready       => '1',
        sw_1_req_m_tdata        => open,
        sw_1_rd_s_tvalid        => '0',
        sw_1_rd_s_tready        => open,
        sw_1_rd_s_tdata         => x"0000",
        -- hex_0
        hex_0_req_m_tvalid      => hex_0_req_tvalid,
        hex_0_req_m_tready      => hex_0_req_tready,
        hex_0_req_m_tdata       => hex_0_req_tdata,
        hex_0_rd_s_tvalid       => hex_0_rd_tvalid,
        hex_0_rd_s_tready       => hex_0_rd_tready,
        hex_0_rd_s_tdata        => hex_0_rd_tdata,
        -- hex_1
        hex_1_req_m_tvalid      => hex_1_req_tvalid,
        hex_1_req_m_tready      => hex_1_req_tready,
        hex_1_req_m_tdata       => hex_1_req_tdata,
        hex_1_rd_s_tvalid       => hex_1_rd_tvalid,
        hex_1_rd_s_tready       => hex_1_rd_tready,
        hex_1_rd_s_tdata        => hex_1_rd_tdata,
        -- uart
        uart_req_m_tvalid       => uart_req_tvalid,
        uart_req_m_tready       => uart_req_tready,
        uart_req_m_tdata        => uart_req_tdata,
        uart_rd_s_tvalid        => uart_rd_tvalid,
        uart_rd_s_tready        => uart_rd_tready,
        uart_rd_s_tdata         => uart_rd_tdata,
        -- port_61
        port_61_req_m_tvalid    => port_61_req_tvalid,
        port_61_req_m_tready    => port_61_req_tready,
        port_61_req_m_tdata     => port_61_req_tdata,
        port_61_rd_s_tvalid     => port_61_rd_tvalid,
        port_61_rd_s_tready     => port_61_rd_tready,
        port_61_rd_s_tdata      => port_61_rd_tdata
    );

    -- Module pit_8254 instantiation
    pit_8254_inst : pit_8254 port map(
        clk                     => clk,
        resetn                  => dev_resetn,

        io_req_s_tvalid         => pit_req_tvalid,
        io_req_s_tready         => pit_req_tready,
        io_req_s_tdata          => pit_req_tdata,

        io_rd_m_tvalid          => pit_rd_tvalid,
        io_rd_m_tready          => pit_rd_tready,
        io_rd_m_tdata           => pit_rd_tdata,

        event_irq               => event_irq,
        event_timer             => event_timer
    );

    -- Module pic instantiation
    pic_inst : pic port map(
        clk                     => clk,
        resetn                  => dev_resetn,

        io_req_s_tvalid         => pic_req_tvalid,
        io_req_s_tready         => pic_req_tready,
        io_req_s_tdata          => pic_req_tdata,

        io_rd_m_tvalid          => pic_rd_tvalid,
        io_rd_m_tready          => pic_rd_tready,
        io_rd_m_tdata           => pic_rd_tdata,

        interrupt_input         => interrupt_vector,

        interrupt_valid         => interrupt_valid,
        interrupt_data          => interrupt_data,
        interrupt_ack           => interrupt_ack
    );

    -- Module soc_io_switches instantiation
    soc_io_switches_0_inst : soc_io_switches port map(
        clk                     => clk,
        resetn                  => dev_resetn,

        io_req_s_tvalid         => sw_0_req_tvalid,
        io_req_s_tready         => sw_0_req_tready,
        io_req_s_tdata          => sw_0_req_tdata,

        io_rd_m_tvalid          => sw_0_rd_tvalid,
        io_rd_m_tready          => sw_0_rd_tready,
        io_rd_m_tdata           => sw_0_rd_tdata,

        switches                => SW(15 downto 0)
    );

    -- Module soc_io_leds instantiation
    soc_io_leds_0_inst : soc_io_leds generic map (
        INIT_VALUE              => x"0000"
    ) port map(
        clk                     => clk,
        resetn                  => dev_resetn,

        io_req_s_tvalid         => leds_0_req_tvalid,
        io_req_s_tready         => leds_0_req_tready,
        io_req_s_tdata          => leds_0_req_tdata,

        io_rd_m_tvalid          => leds_0_rd_tvalid,
        io_rd_m_tready          => leds_0_rd_tready,
        io_rd_m_tdata           => leds_0_rd_tdata,

        leds                    => ledg_out
    );

    -- Module soc_io_port_61 instantiation
    soc_io_port_61_inst : soc_io_port_61 generic map (
        INIT_VALUE              => x"0000"
    ) port map(
        clk                     => clk,
        resetn                  => dev_resetn,

        io_req_s_tvalid         => port_61_req_tvalid,
        io_req_s_tready         => port_61_req_tready,
        io_req_s_tdata          => port_61_req_tdata,

        io_rd_m_tvalid          => port_61_rd_tvalid,
        io_rd_m_tready          => port_61_rd_tready,
        io_rd_m_tdata           => port_61_rd_tdata,

        event_timer             => event_timer
    );

    -- Module soc_io_seg_7 instantiation
    soc_io_seg_7_0_inst : soc_io_seg_7 generic map (
        INIT_VALUE              => x"0000"
    ) port map(
        clk                     => clk,
        resetn                  => dev_resetn,

        io_req_s_tvalid         => hex_0_req_tvalid,
        io_req_s_tready         => hex_0_req_tready,
        io_req_s_tdata          => hex_0_req_tdata,

        io_rd_m_tvalid          => hex_0_rd_tvalid,
        io_rd_m_tready          => hex_0_rd_tready,
        io_rd_m_tdata           => hex_0_rd_tdata,

        HEX0                    => HEX0,
        HEX1                    => HEX1,
        HEX2                    => HEX2,
        HEX3                    => HEX3
    );

    -- Module soc_io_seg_7 instantiation
    soc_io_seg_7_1_inst : soc_io_seg_7 generic map (
        INIT_VALUE              => x"0000"
    ) port map(
        clk                     => clk,
        resetn                  => dev_resetn,

        io_req_s_tvalid         => hex_1_req_tvalid,
        io_req_s_tready         => hex_1_req_tready,
        io_req_s_tdata          => hex_1_req_tdata,

        io_rd_m_tvalid          => hex_1_rd_tvalid,
        io_rd_m_tready          => hex_1_rd_tready,
        io_rd_m_tdata           => hex_1_rd_tdata,

        HEX0                    => HEX4,
        HEX1                    => HEX5,
        HEX2                    => HEX6,
        HEX3                    => HEX7
    );

    -- Module soc_io_uart instantiation
    soc_io_uart_inst : soc_io_uart port map(
        clk                     => clk,
        resetn                  => dev_resetn,

        io_req_s_tvalid         => uart_req_tvalid,
        io_req_s_tready         => uart_req_tready,
        io_req_s_tdata          => uart_req_tdata,

        io_rd_m_tvalid          => uart_rd_tvalid,
        io_rd_m_tready          => uart_rd_tready,
        io_rd_m_tdata           => uart_rd_tdata,

        rx                      => BT_UART_RX,
        tx                      => BT_UART_TX
    );

    -- Assigns
    LEDG <= ledg_out(8 downto 0);

    mem_req_m_tready <= '1';

    wr_s_tvalid <= '1' when mem_req_m_tvalid = '1' and mem_req_m_tdata(57) = '1' else '0';
    wr_s_taddr <= mem_req_m_tdata(ADDR_WIDTH - 1 + 32 downto 32);
    wr_s_tmask <= mem_req_m_tdata(61 downto 58);
    wr_s_tdata <= mem_req_m_tdata(31 downto 0);

    rd_s_tvalid <= '1' when mem_req_m_tvalid = '1' and mem_req_m_tdata(57) = '0' else '0';
    rd_s_taddr <= mem_req_m_tdata(ADDR_WIDTH - 1 + 32 downto 32);

    mem_rd_s_tvalid <= rd_m_tvalid;
    mem_rd_s_tdata <= rd_m_tdata;

    interrupt_vector(15 downto 1)   <= (others => '0');
    interrupt_vector(0)             <= event_irq;

    process (clk) begin
        if rising_edge(clk) then

            if (io_req_tvalid = '1' and io_req_tready = '1' and io_req_tdata(32) = '1') then
                if (io_req_tdata(31 downto 16) = x"0043") then
                    led_reg  <= io_req_tdata(7 downto 0);
                end if;
            end if;

        end if;
    end process;

    process (clk) begin
        if rising_edge(clk) then
            cpu_resetn <= resetn;
            dev_resetn <= resetn;
            con_resetn <= resetn;
        end if;
    end process;

end architecture;