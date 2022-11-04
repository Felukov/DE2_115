
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
    generic (
        FREQ                    : integer := 100_000_000;
        UART_RATE               : integer := 115_200;
        RX_FIFO_SIZE            : integer := 16;
        TX_FIFO_SIZE            : integer := 16
    );
    port (
        clk                         : in std_logic;
        resetn                      : in std_logic;

        m_axis_sdram_req_tvalid     : out std_logic;
        m_axis_sdram_req_tready     : in std_logic;
        m_axis_sdram_req_tdata      : out std_logic_vector(63 downto 0);

        s_axis_sdram_res_tvalid     : in std_logic;
        s_axis_sdram_res_tdata      : in std_logic_vector(31 downto 0);

        sd_error                    : in std_logic;
        sd_disk_mounted             : in std_logic;
        sd_blocks                   : in std_logic_vector(21 downto 0);
        sd_io_lba                   : out std_logic_vector(31 downto 0);
        sd_io_rd                    : out std_logic;
        sd_io_wr                    : out std_logic;
        sd_io_ack                   : in std_logic;
        sd_io_din                   : in std_logic_vector(7 downto 0);
        sd_io_din_strobe            : in std_logic;
        sd_io_dout                  : out std_logic_vector(7 downto 0);
        sd_io_dout_strobe           : in std_logic;

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
        BT_UART_TX                  : out std_logic;

        PS2_CLK                     : inout std_logic;
        PS2_DAT                     : inout std_logic
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

            m_axis_mem_req_tvalid   : out std_logic;
            m_axis_mem_req_tready   : in std_logic;
            m_axis_mem_req_tdata    : out std_logic_vector(63 downto 0);

            s_axis_mem_res_tvalid   : in std_logic;
            s_axis_mem_res_tdata    : in std_logic_vector(31 downto 0);

            m_axis_io_req_tvalid    : out std_logic;
            m_axis_io_req_tready    : in std_logic;
            m_axis_io_req_tdata     : out std_logic_vector(39 downto 0);

            s_axis_io_res_tvalid    : in std_logic;
            s_axis_io_res_tready    : out std_logic;
            s_axis_io_res_tdata     : in std_logic_vector(15 downto 0);

            interrupt_valid         : in std_logic;
            interrupt_data          : in std_logic_vector(7 downto 0);
            interrupt_ack           : out std_logic;

            dbg_out_rr_valid        : out std_logic;
            dbg_out_rr_cs           : out std_logic_vector(15 downto 0);
            dbg_out_rr_ip           : out std_logic_vector(15 downto 0);
            dbg_out_rr_op           : out std_logic_vector(4 downto 0);
            dbg_out_rr_code         : out std_logic_vector(3 downto 0);
            dbg_out_rr_sreg         : out std_logic_vector(3 downto 0);
            dbg_out_rr_dreg         : out std_logic_vector(3 downto 0);
            dbg_out_rr_ax           : out std_logic_vector(15 downto 0);
            dbg_out_rr_bx           : out std_logic_vector(15 downto 0);
            dbg_out_rr_cx           : out std_logic_vector(15 downto 0);
            dbg_out_rr_dx           : out std_logic_vector(15 downto 0);
            dbg_out_rr_bp           : out std_logic_vector(15 downto 0);
            dbg_out_rr_sp           : out std_logic_vector(15 downto 0);
            dbg_out_rr_di           : out std_logic_vector(15 downto 0);
            dbg_out_rr_si           : out std_logic_vector(15 downto 0);
            dbg_out_rr_fl           : out std_logic_vector(15 downto 0)
        );
    end component cpu86;

    component soc_mmu is
        port (
            clk                     : in std_logic;
            resetn                  : in std_logic;

            s_axis_io_req_tvalid    : in std_logic;
            s_axis_io_req_tready    : out std_logic;
            s_axis_io_req_tdata     : in std_logic_vector(39 downto 0);

            m_axis_io_res_tvalid    : out std_logic;
            m_axis_io_res_tready    : in std_logic;
            m_axis_io_res_tdata     : out std_logic_vector(15 downto 0);

            s_axis_mem_req_tvalid   : in std_logic;
            s_axis_mem_req_tready   : out std_logic;
            s_axis_mem_req_tdata    : in std_logic_vector(63 downto 0);

            m_axis_mem_res_tvalid   : out std_logic;
            m_axis_mem_res_tdata    : out std_logic_vector(31 downto 0);

            m_axis_sdram_req_tvalid : out std_logic;
            m_axis_sdram_req_tready : in std_logic;
            m_axis_sdram_req_tdata  : out std_logic_vector(63 downto 0);

            s_axis_sdram_res_tvalid : in std_logic;
            s_axis_sdram_res_tdata  : in std_logic_vector(31 downto 0);

            m_axis_bram_req_tvalid  : out std_logic;
            m_axis_bram_req_tready  : in std_logic;
            m_axis_bram_req_tdata   : out std_logic_vector(63 downto 0);

            s_axis_bram_res_tvalid  : in std_logic;
            s_axis_bram_res_tdata   : in std_logic_vector(31 downto 0)
        );
    end component soc_mmu;

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

    component pic_lite is
        port (
            clk                     : in std_logic;
            resetn                  : in std_logic;

            -- cpu io
            s_axis_io_req_tvalid    : in std_logic;
            s_axis_io_req_tready    : out std_logic;
            s_axis_io_req_tdata     : in std_logic_vector(39 downto 0);
            m_axis_io_res_tvalid    : out std_logic;
            m_axis_io_res_tready    : in std_logic;
            m_axis_io_res_tdata     : out std_logic_vector(15 downto 0);

            -- interrutps
            interrupt_input         : in std_logic_vector(4 downto 0);

            interrupt_valid         : out std_logic;
            interrupt_data          : out std_logic_vector(7 downto 0);
            interrupt_ack           : in std_logic
        );
    end component pic_lite;

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
        generic (
            FREQ                    : integer := 100_000_000;
            RATE                    : integer := 115_200;
            RX_FIFO_SIZE            : integer := 16;
            TX_FIFO_SIZE            : integer := 16
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

            rx                      : in std_logic;
            tx                      : out std_logic
        );
    end component soc_io_uart;

    component soc_ps2 is
        port(
            clk                     : in std_logic;
            resetn                  : in std_logic;

            -- cpu io
            s_axis_io_req_tvalid    : in std_logic;
            s_axis_io_req_tready    : out std_logic;
            s_axis_io_req_tdata     : in std_logic_vector(39 downto 0);
            m_axis_io_res_tvalid    : out std_logic;
            m_axis_io_res_tready    : in std_logic;
            m_axis_io_res_tdata     : out std_logic_vector(15 downto 0);

            -- interrupt request
            event_kb_int_req        : out std_logic;

            -- PS2
            ps2d                    : inout std_logic;
            ps2c                    : inout std_logic
        );
    end component soc_ps2;

    component signal_tap is
        port (
            acq_data_in    : in std_logic_vector(63 downto 0) := (others => 'X'); -- acq_data_in
            acq_trigger_in : in std_logic_vector( 0 downto 0) := (others => 'X'); -- acq_trigger_in
            acq_clk        : in std_logic                     := 'X';             -- clk
            storage_enable : in std_logic                     := 'X'              -- storage_enable
        );
    end component signal_tap;

    attribute keep: boolean;
    attribute maxfan : integer;
    signal cpu_resetn               : std_logic;
    attribute keep of cpu_resetn    : signal is true;
    attribute maxfan of cpu_resetn  : signal is 200;
    signal dev_resetn               : std_logic;
    attribute keep of dev_resetn    : signal is true;
    signal con_resetn               : std_logic;
    attribute keep of con_resetn    : signal is true;

    signal mem_req_tvalid           : std_logic;
    signal mem_req_tready           : std_logic;
    signal mem_req_tdata            : std_logic_vector(63 downto 0);
    signal mem_res_tvalid           : std_logic;
    signal mem_res_tdata            : std_logic_vector(31 downto 0);

    signal sdram_req_tvalid         : std_logic;
    signal sdram_req_tready         : std_logic;
    signal sdram_req_tdata          : std_logic_vector(63 downto 0);
    signal sdram_res_tvalid         : std_logic;
    signal sdram_res_tdata          : std_logic_vector(31 downto 0);

    signal bram_req_tvalid          : std_logic;
    signal bram_req_tready          : std_logic;
    signal bram_req_tdata           : std_logic_vector(63 downto 0);
    signal bram_res_tvalid          : std_logic;
    signal bram_res_tdata           : std_logic_vector(31 downto 0);

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
    -- signal rd_m_tvalid              : std_logic;
    -- signal rd_m_tdata               : std_logic_vector(DATA_WIDTH-1 downto 0);

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

    signal kbd_req_tvalid           : std_logic;
    signal kbd_req_tready           : std_logic;
    signal kbd_req_tdata            : std_logic_vector(39 downto 0);
    signal kbd_rd_tvalid            : std_logic;
    signal kbd_rd_tready            : std_logic;
    signal kbd_rd_tdata             : std_logic_vector(15 downto 0);

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

    signal mmu_req_tvalid           : std_logic;
    signal mmu_req_tready           : std_logic;
    signal mmu_req_tdata            : std_logic_vector(39 downto 0);
    signal mmu_rd_tvalid            : std_logic;
    signal mmu_rd_tready            : std_logic;
    signal mmu_rd_tdata             : std_logic_vector(15 downto 0);

    signal sdcard_req_tvalid        : std_logic;
    signal sdcard_req_tready        : std_logic;
    signal sdcard_req_tdata         : std_logic_vector(39 downto 0);
    signal sdcard_rd_tvalid         : std_logic;
    signal sdcard_rd_tready         : std_logic;
    signal sdcard_rd_tdata          : std_logic_vector(15 downto 0);

    signal led_reg                  : std_logic_vector(7 downto 0);

    signal event_timer              : std_logic;
    signal event_irq                : std_logic;
    signal event_kb_int_req         : std_logic;

    signal interrupt_vector         : std_logic_vector(15 downto 0);

    signal interrupt_valid          : std_logic;
    signal interrupt_data           : std_logic_vector(7 downto 0);
    signal interrupt_ack            : std_logic;

    signal ledg_out                 : std_logic_vector(15 downto 0);

    -- signal acq_data_in              : std_logic_vector(63 downto 0);
    -- signal acq_trigger_in           : std_logic_vector(0 downto 0);
    -- signal storage_enable           : std_logic;

    -- signal test_1_mask              : std_logic;
    -- signal test_0_cnt               : std_logic_vector(15 downto 0);
    -- signal test_1_cnt               : std_logic_vector(15 downto 0);
    -- signal test_buf                 : std_logic_vector(7 downto 0);

begin
    -- acq_data_in(63 downto 11) <= (others => '0');
    -- acq_data_in(10) <= event_kb_int_req;
    -- acq_data_in(9) <= interrupt_valid;
    -- acq_data_in(8) <= interrupt_ack;
    -- acq_data_in(7 downto  0) <= interrupt_data;


    -- acq_trigger_in(0) <= '1';
    -- storage_enable    <= '1';

    -- u0 : component signal_tap port map (
    --     acq_clk         => clk,            -- acq_clk
    --     acq_data_in     => acq_data_in,    -- acq_data_in
    --     acq_trigger_in  => acq_trigger_in, -- acq_trigger_in
    --     storage_enable  => storage_enable  -- storage_enable
    -- );

    -- process (clk) begin
    --     if rising_edge(clk) then
    --         if resetn = '0' then
    --             test_0_cnt <= (others => '0');
    --             test_1_cnt <= (others => '0');
    --             test_1_mask <= '1';
    --             test_buf <= (others => '0');
    --         else
    --             if (interrupt_valid = '1' and interrupt_ack = '1') then
    --                 test_buf <= interrupt_data;
    --             end if;

    --             if (interrupt_valid = '1' and interrupt_ack = '1' and interrupt_data = x"09") then
    --                 test_0_cnt <= test_0_cnt + 1;
    --                 test_1_mask <= '0';
    --             end if;

    --             if (pic_req_tvalid = '1' and pic_req_tready = '1' and test_buf = x"09" and test_1_mask = '0') then
    --                 test_1_cnt <= test_1_cnt + 1;
    --             end if;
    --         end if;
    --     end if;
    -- end process;

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

        rd_m_tvalid             => bram_res_tvalid,
        rd_m_tdata              => bram_res_tdata,
        rd_m_tuser              => open
    );

    -- Module cpu86 instantiation
    cpu86_inst : cpu86 port map(
        clk                     => clk,
        resetn                  => cpu_resetn,

        m_axis_mem_req_tvalid   => mem_req_tvalid,
        m_axis_mem_req_tready   => mem_req_tready,
        m_axis_mem_req_tdata    => mem_req_tdata,

        s_axis_mem_res_tvalid   => mem_res_tvalid,
        s_axis_mem_res_tdata    => mem_res_tdata,

        m_axis_io_req_tvalid    => io_req_tvalid,
        m_axis_io_req_tready    => io_req_tready,
        m_axis_io_req_tdata     => io_req_tdata,

        s_axis_io_res_tvalid    => io_rd_tvalid,
        s_axis_io_res_tready    => io_rd_tready,
        s_axis_io_res_tdata     => io_rd_tdata,

        interrupt_valid         => interrupt_valid,
        interrupt_data          => interrupt_data,
        interrupt_ack           => interrupt_ack,

        dbg_out_rr_valid        => open,
        dbg_out_rr_cs           => open,
        dbg_out_rr_ip           => open,
        dbg_out_rr_op           => open,
        dbg_out_rr_code         => open,
        dbg_out_rr_sreg         => open,
        dbg_out_rr_dreg         => open,
        dbg_out_rr_ax           => open,
        dbg_out_rr_bx           => open,
        dbg_out_rr_cx           => open,
        dbg_out_rr_dx           => open,
        dbg_out_rr_bp           => open,
        dbg_out_rr_sp           => open,
        dbg_out_rr_di           => open,
        dbg_out_rr_si           => open,
        dbg_out_rr_fl           => open
    );

    -- Module soc_mmu instantiation
    soc_mmu_inst : soc_mmu port map (
        clk                     => clk,
        resetn                  => resetn,

        s_axis_io_req_tvalid    => mmu_req_tvalid,
        s_axis_io_req_tready    => mmu_req_tready,
        s_axis_io_req_tdata     => mmu_req_tdata,

        m_axis_io_res_tvalid    => mmu_rd_tvalid,
        m_axis_io_res_tready    => mmu_rd_tready,
        m_axis_io_res_tdata     => mmu_rd_tdata,

        s_axis_mem_req_tvalid   => mem_req_tvalid,
        s_axis_mem_req_tready   => mem_req_tready,
        s_axis_mem_req_tdata    => mem_req_tdata,

        m_axis_mem_res_tvalid   => mem_res_tvalid,
        m_axis_mem_res_tdata    => mem_res_tdata,

        m_axis_sdram_req_tvalid => sdram_req_tvalid,
        m_axis_sdram_req_tready => sdram_req_tready,
        m_axis_sdram_req_tdata  => sdram_req_tdata,

        s_axis_sdram_res_tvalid => sdram_res_tvalid,
        s_axis_sdram_res_tdata  => sdram_res_tdata,

        m_axis_bram_req_tvalid  => bram_req_tvalid,
        m_axis_bram_req_tready  => bram_req_tready,
        m_axis_bram_req_tdata   => bram_req_tdata,

        s_axis_bram_res_tvalid  => bram_res_tvalid,
        s_axis_bram_res_tdata   => bram_res_tdata
    );

    -- Module soc_io_interconnect instantiation
    soc_io_interconnect_inst : entity work.soc_io_interconnect port map (
        -- global singals
        clk                         => clk,
        resetn                      => resetn,
        -- cpu io
        s_axis_io_req_tvalid        => io_req_tvalid,
        s_axis_io_req_tready        => io_req_tready,
        s_axis_io_req_tdata         => io_req_tdata,
        m_axis_io_res_tvalid        => io_rd_tvalid,
        m_axis_io_res_tready        => io_rd_tready,
        m_axis_io_res_tdata         => io_rd_tdata,
        -- pit
        m_axis_pit_req_tvalid       => pit_req_tvalid,
        m_axis_pit_req_tready       => pit_req_tready,
        m_axis_pit_req_tdata        => pit_req_tdata,
        s_axis_pit_res_tvalid       => pit_rd_tvalid,
        s_axis_pit_res_tready       => pit_rd_tready,
        s_axis_pit_res_tdata        => pit_rd_tdata,
        -- pic
        m_axis_pic_req_tvalid       => pic_req_tvalid,
        m_axis_pic_req_tready       => pic_req_tready,
        m_axis_pic_req_tdata        => pic_req_tdata,
        s_axis_pic_res_tvalid       => pic_rd_tvalid,
        s_axis_pic_res_tready       => pic_rd_tready,
        s_axis_pic_res_tdata        => pic_rd_tdata,
        -- led_0
        m_axis_led_0_req_tvalid     => leds_0_req_tvalid,
        m_axis_led_0_req_tready     => leds_0_req_tready,
        m_axis_led_0_req_tdata      => leds_0_req_tdata,
        s_axis_led_0_res_tvalid     => leds_0_rd_tvalid,
        s_axis_led_0_res_tready     => leds_0_rd_tready,
        s_axis_led_0_res_tdata      => leds_0_rd_tdata,
        -- led_1
        m_axis_led_1_req_tvalid     => open,
        m_axis_led_1_req_tready     => '1',
        m_axis_led_1_req_tdata      => open,
        s_axis_led_1_res_tvalid     => '0',
        s_axis_led_1_res_tready     => open,
        s_axis_led_1_res_tdata      => x"0000",
        -- led_2
        m_axis_led_2_req_tvalid     => open,
        m_axis_led_2_req_tready     => '1',
        m_axis_led_2_req_tdata      => open,
        s_axis_led_2_res_tvalid     => '0',
        s_axis_led_2_res_tready     => open,
        s_axis_led_2_res_tdata      => x"0000",
        -- sw_0
        m_axis_sw_0_req_tvalid      => sw_0_req_tvalid,
        m_axis_sw_0_req_tready      => sw_0_req_tready,
        m_axis_sw_0_req_tdata       => sw_0_req_tdata,
        s_axis_sw_0_res_tvalid      => sw_0_rd_tvalid,
        s_axis_sw_0_res_tready      => sw_0_rd_tready,
        s_axis_sw_0_res_tdata       => sw_0_rd_tdata,
        -- sw_1
        m_axis_sw_1_req_tvalid      => open,
        m_axis_sw_1_req_tready      => '1',
        m_axis_sw_1_req_tdata       => open,
        s_axis_sw_1_res_tvalid      => '0',
        s_axis_sw_1_res_tready      => open,
        s_axis_sw_1_res_tdata       => x"0000",
        -- hex_0
        m_axis_hex_0_req_tvalid     => hex_0_req_tvalid,
        m_axis_hex_0_req_tready     => hex_0_req_tready,
        m_axis_hex_0_req_tdata      => hex_0_req_tdata,
        s_axis_hex_0_res_tvalid     => hex_0_rd_tvalid,
        s_axis_hex_0_res_tready     => hex_0_rd_tready,
        s_axis_hex_0_res_tdata      => hex_0_rd_tdata,
        -- hex_1
        m_axis_hex_1_req_tvalid     => hex_1_req_tvalid,
        m_axis_hex_1_req_tready     => hex_1_req_tready,
        m_axis_hex_1_req_tdata      => hex_1_req_tdata,
        s_axis_hex_1_res_tvalid     => hex_1_rd_tvalid,
        s_axis_hex_1_res_tready     => hex_1_rd_tready,
        s_axis_hex_1_res_tdata      => hex_1_rd_tdata,
        -- uart
        m_axis_uart_req_tvalid      => uart_req_tvalid,
        m_axis_uart_req_tready      => uart_req_tready,
        m_axis_uart_req_tdata       => uart_req_tdata,
        s_axis_uart_res_tvalid      => uart_rd_tvalid,
        s_axis_uart_res_tready      => uart_rd_tready,
        s_axis_uart_res_tdata       => uart_rd_tdata,
        -- mmu
        m_axis_mmu_req_tvalid       => mmu_req_tvalid,
        m_axis_mmu_req_tready       => mmu_req_tready,
        m_axis_mmu_req_tdata        => mmu_req_tdata,
        s_axis_mmu_res_tvalid       => mmu_rd_tvalid,
        s_axis_mmu_res_tready       => mmu_rd_tready,
        s_axis_mmu_res_tdata        => mmu_rd_tdata,
        -- kbd
        m_axis_kbd_req_tvalid       => kbd_req_tvalid,
        m_axis_kbd_req_tready       => kbd_req_tready,
        m_axis_kbd_req_tdata        => kbd_req_tdata,
        s_axis_kbd_res_tvalid       => kbd_rd_tvalid,
        s_axis_kbd_res_tready       => kbd_rd_tready,
        s_axis_kbd_res_tdata        => kbd_rd_tdata,
        -- port_61
        m_axis_port_61_req_tvalid   => port_61_req_tvalid,
        m_axis_port_61_req_tready   => port_61_req_tready,
        m_axis_port_61_req_tdata    => port_61_req_tdata,
        s_axis_port_61_res_tvalid   => port_61_rd_tvalid,
        s_axis_port_61_res_tready   => port_61_rd_tready,
        s_axis_port_61_res_tdata    => port_61_rd_tdata,
        -- sdcard
        m_axis_sdcard_req_tvalid    => sdcard_req_tvalid,
        m_axis_sdcard_req_tready    => sdcard_req_tready,
        m_axis_sdcard_req_tdata     => sdcard_req_tdata,
        s_axis_sdcard_res_tvalid    => sdcard_rd_tvalid,
        s_axis_sdcard_res_tready    => sdcard_rd_tready,
        s_axis_sdcard_res_tdata     => sdcard_rd_tdata
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
    -- pic_inst : pic port map(
    --     clk                     => clk,
    --     resetn                  => dev_resetn,

    --     io_req_s_tvalid         => pic_req_tvalid,
    --     io_req_s_tready         => pic_req_tready,
    --     io_req_s_tdata          => pic_req_tdata,

    --     io_rd_m_tvalid          => pic_rd_tvalid,
    --     io_rd_m_tready          => pic_rd_tready,
    --     io_rd_m_tdata           => pic_rd_tdata,

    --     interrupt_input         => interrupt_vector,

    --     interrupt_valid         => open,
    --     interrupt_data          => open,
    --     interrupt_ack           => interrupt_ack
    -- );

    -- Module pic instantiation
    pic_lite_inst : pic_lite port map(
        clk                     => clk,
        resetn                  => resetn,

        s_axis_io_req_tvalid    => pic_req_tvalid,
        s_axis_io_req_tready    => pic_req_tready,
        s_axis_io_req_tdata     => pic_req_tdata,

        m_axis_io_res_tvalid    => pic_rd_tvalid,
        m_axis_io_res_tready    => pic_rd_tready,
        m_axis_io_res_tdata     => pic_rd_tdata,

        interrupt_input         => interrupt_vector(4 downto 0),

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
    soc_io_uart_inst : soc_io_uart generic map (
        FREQ                    => FREQ,
        RATE                    => UART_RATE,
        RX_FIFO_SIZE            => RX_FIFO_SIZE,
        TX_FIFO_SIZE            => TX_FIFO_SIZE
    ) port map(
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

    -- Module soc_ps2 instantiation
    soc_io_kbd_inst : soc_ps2 port map(
        clk                     => clk,
        resetn                  => dev_resetn,

        s_axis_io_req_tvalid    => kbd_req_tvalid,
        s_axis_io_req_tready    => kbd_req_tready,
        s_axis_io_req_tdata     => kbd_req_tdata,

        m_axis_io_res_tvalid    => kbd_rd_tvalid,
        m_axis_io_res_tready    => kbd_rd_tready,
        m_axis_io_res_tdata     => kbd_rd_tdata,

        event_kb_int_req        => event_kb_int_req,

        ps2c                    => PS2_CLK,
        ps2d                    => PS2_DAT
    );

    -- Module soc_ps2 instantiation
    ps_io_sdcard_inst : entity work.ps_io_sdcard port map(
        clk                     => clk,
        resetn                  => dev_resetn,

        s_axis_io_req_tvalid    => sdcard_req_tvalid,
        s_axis_io_req_tready    => sdcard_req_tready,
        s_axis_io_req_tdata     => sdcard_req_tdata,

        m_axis_io_res_tvalid    => sdcard_rd_tvalid,
        m_axis_io_res_tready    => sdcard_rd_tready,
        m_axis_io_res_tdata     => sdcard_rd_tdata,

        sd_error                => sd_error,
        sd_disk_mounted         => sd_disk_mounted,
        sd_blocks               => sd_blocks,
        sd_io_lba               => sd_io_lba,
        sd_io_rd                => sd_io_rd,
        sd_io_wr                => sd_io_wr,
        sd_io_ack               => sd_io_ack,
        sd_io_din               => sd_io_din,
        sd_io_din_strobe        => sd_io_din_strobe,
        sd_io_dout              => sd_io_dout,
        sd_io_dout_strobe       => sd_io_dout_strobe
    );

    -- Assigns
    LEDG <= ledg_out(8 downto 0);

    -- bram wiring
    wr_s_tvalid                     <= '1' when bram_req_tvalid = '1' and bram_req_tdata(57) = '1' else '0';
    bram_req_tready                 <= '1';
    wr_s_taddr                      <= bram_req_tdata(ADDR_WIDTH - 1 + 32 downto 32);
    wr_s_tmask                      <= bram_req_tdata(61 downto 58);
    wr_s_tdata                      <= bram_req_tdata(31 downto 0);

    rd_s_tvalid                     <= '1' when bram_req_tvalid = '1' and bram_req_tdata(57) = '0' else '0';
    rd_s_taddr                      <= bram_req_tdata(ADDR_WIDTH - 1 + 32 downto 32);

    -- sdram wiring
    m_axis_sdram_req_tvalid         <= sdram_req_tvalid;
    sdram_req_tready                <= m_axis_sdram_req_tready;
    m_axis_sdram_req_tdata          <= sdram_req_tdata;
    sdram_res_tvalid                <= s_axis_sdram_res_tvalid;
    sdram_res_tdata                 <= s_axis_sdram_res_tdata;

    -- mem_res_tvalid <= rd_m_tvalid;
    -- mem_res_tdata <= rd_m_tdata;

    interrupt_vector(15 downto 2)   <= (others => '0');
    interrupt_vector(1)             <= event_kb_int_req;
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
