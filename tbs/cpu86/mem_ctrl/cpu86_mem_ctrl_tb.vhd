library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use ieee.std_logic_1164.all;
use work.cpu86_types.all;

entity cpu86_mem_ctrl_tb is
end entity cpu86_mem_ctrl_tb;

architecture rtl of cpu86_mem_ctrl_tb is
    -- Clock period definitions
    constant CLK_PERIOD         : time := 10 ns;
    constant MAX_BUF_SIZE       : integer := 1000;

    constant ADDR_WIDTH         : natural := 12;
    constant DATA_WIDTH         : natural := 32;
    constant USER_WIDTH         : natural := 32;
    constant BYTES              : natural := 4;

    constant SDRAM_PORT_QTY     : natural := 2;

    component on_chip_ram is
        generic (
            ADDR_WIDTH          : natural := 12;
            DATA_WIDTH          : natural := 32;
            USER_WIDTH          : natural := 32;
            BYTES               : natural := 4
        );
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            wr_s_tvalid         : in std_logic;
            wr_s_taddr          : in std_logic_vector(ADDR_WIDTH-1 downto 0);
            wr_s_tmask          : in std_logic_vector(BYTES-1 downto 0);
            wr_s_tdata          : in std_logic_vector(DATA_WIDTH-1 downto 0);

            rd_s_tvalid         : in std_logic;
            rd_s_taddr          : in std_logic_vector(ADDR_WIDTH-1 downto 0);
            rd_s_tuser          : in std_logic_vector(USER_WIDTH-1 downto 0);

            rd_m_tvalid         : out std_logic;
            rd_m_tdata          : out std_logic_vector(DATA_WIDTH-1 downto 0);
            rd_m_tuser          : out std_logic_vector(USER_WIDTH-1 downto 0)

        );
    end component on_chip_ram;

    component sdram_test_model is
        port (
            clk                 : in std_logic;

            zs_addr             : in std_logic_vector(12 downto 0);
            zs_ba               : in std_logic_vector( 1 downto 0);
            zs_cas_n            : in std_logic;
            zs_cke              : in std_logic;
            zs_cs_n             : in std_logic;
            zs_dq               : inout std_logic_vector(31 downto 0);
            zs_dqm              : in std_logic_vector(3 downto 0);
            zs_ras_n            : in std_logic;
            zs_we_n             : in std_logic
        );
    end component;

    component sdram_system is
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            s_axis_req_tvalid   : in std_logic;
            s_axis_req_tready   : out std_logic;
            s_axis_req_tdata    : in std_logic_vector (63 downto 0);

            m_axis_res_tvalid   : out std_logic;
            m_axis_res_tdata    : out std_logic_vector(31 downto 0);

            DRAM_ADDR           : out std_logic_vector(12 downto 0);
            DRAM_BA             : out std_logic_vector(1 downto 0);
            DRAM_CAS_N          : out std_logic;
            DRAM_CKE            : out std_logic;
            DRAM_CS_N           : out std_logic;
            DRAM_DQ             : inout std_logic_vector(31 downto 0);
            DRAM_DQM            : out std_logic_vector(3 downto 0);
            DRAM_RAS_N          : out std_logic;
            DRAM_WE_N           : out std_logic
        );
    end component sdram_system;

    component sdram_interconnect is
        generic (
            PORT_QTY                : natural := 2
        );
        port (
            clk                     : in std_logic;
            resetn                  : in std_logic;

            s_axis_port_req_tvalid  : in std_logic_vector(PORT_QTY-1 downto 0);
            s_axis_port_req_tready  : out std_logic_vector(PORT_QTY-1 downto 0);
            s_axis_port_req_tdata   : in std_logic_vector(64*PORT_QTY-1 downto 0);

            s_axis_sdram_res_tvalid : out std_logic;
            s_axis_sdram_res_tdata  : out std_logic_vector(31 downto 0);

            m_axis_sdram_req_tvalid : out std_logic;
            m_axis_sdram_req_tready : in std_logic;
            m_axis_sdram_req_tdata  : out std_logic_vector (63 downto 0);

            m_axis_port_res_tvalid  : out std_logic_vector(PORT_QTY-1 downto 0);
            m_axis_port_res_tdata   : out std_logic_vector(32*PORT_QTY-1 downto 0)
        );
    end component sdram_interconnect;

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
            interrupt_ack           : out std_logic
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

    component soc_io_interconnect is
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

    signal CLK                      : std_logic := '0';
    signal RESETN                   : std_logic := '0';

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

    signal ps_sdram_req_tvalid      : std_logic;
    signal ps_sdram_req_tready      : std_logic;
    signal ps_sdram_req_tdata       : std_logic_vector(63 downto 0);
    signal ps_sdram_res_tvalid      : std_logic;
    signal ps_sdram_res_tdata       : std_logic_vector(31 downto 0);

    signal vid_sdram_req_tvalid     : std_logic;
    signal vid_sdram_req_tready     : std_logic;
    signal vid_sdram_req_tdata      : std_logic_vector(63 downto 0);
    signal vid_sdram_res_tvalid     : std_logic;
    signal vid_sdram_res_tdata      : std_logic_vector(31 downto 0);

    signal sdram_port_req_tvalid    : std_logic_vector(SDRAM_PORT_QTY-1 downto 0);
    signal sdram_port_req_tready    : std_logic_vector(SDRAM_PORT_QTY-1 downto 0);
    signal sdram_port_req_tdata     : std_logic_vector(64*SDRAM_PORT_QTY-1 downto 0);
    signal sdram_port_res_tvalid    : std_logic_vector(SDRAM_PORT_QTY-1 downto 0);
    signal sdram_port_res_tdata     : std_logic_vector(32*SDRAM_PORT_QTY-1 downto 0);

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

    signal mmu_req_tvalid           : std_logic;
    signal mmu_req_tready           : std_logic;
    signal mmu_req_tdata            : std_logic_vector(39 downto 0);
    signal mmu_rd_tvalid            : std_logic;
    signal mmu_rd_tready            : std_logic;
    signal mmu_rd_tdata             : std_logic_vector(15 downto 0);

    signal led_reg                  : std_logic_vector(7 downto 0);

    signal event_timer              : std_logic;
    signal event_irq                : std_logic;

    signal d_event_timer            : std_logic;
    signal timer_ff                 : std_logic;

    signal interrupt_vector         : std_logic_vector(15 downto 0);

    signal interrupt_valid          : std_logic;
    signal interrupt_data           : std_logic_vector(7 downto 0);
    signal interrupt_ack            : std_logic;

    signal ledg_out                 : std_logic_vector(15 downto 0);

    signal za_waitrequest           : std_logic;
    signal za_valid                 : std_logic;
    signal za_data                  : std_logic_vector(31 downto 0);
    signal zs_addr                  : std_logic_vector(12 downto 0);
    signal zs_ba                    : std_logic_vector( 1 downto 0);
    signal zs_cas_n                 : std_logic;
    signal zs_cke                   : std_logic;
    signal zs_cs_n                  : std_logic;
    signal zs_dq                    : std_logic_vector(31 downto 0);
    signal zs_dqm                   : std_logic_vector(3 downto 0);
    signal zs_ras_n                 : std_logic;
    signal zs_we_n                  : std_logic;

    signal SW                       : std_logic_vector(15 downto 0) := (others => '0');

begin


    -- Module on_chip_ram instantiation
    on_chip_ram_inst : on_chip_ram port map (
        clk                     => clk,
        resetn                  => resetn,

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


    -- Module sdram_interconnect instantiation
    sdram_interconnect_inst : sdram_interconnect port map (
        clk                     => clk,
        resetn                  => resetn,

        s_axis_port_req_tvalid  => sdram_port_req_tvalid,
        s_axis_port_req_tready  => sdram_port_req_tready,
        s_axis_port_req_tdata   => sdram_port_req_tdata,

        s_axis_sdram_res_tvalid => sdram_res_tvalid,
        s_axis_sdram_res_tdata  => sdram_res_tdata,

        m_axis_sdram_req_tvalid => sdram_req_tvalid,
        m_axis_sdram_req_tready => sdram_req_tready,
        m_axis_sdram_req_tdata  => sdram_req_tdata,

        m_axis_port_res_tvalid  => sdram_port_res_tvalid,
        m_axis_port_res_tdata   => sdram_port_res_tdata
    );

    -- Module sdram instantiation
    sdram_system_inst : sdram_system port map (
        clk                     => clk,
        resetn                  => resetn,

        s_axis_req_tvalid       => sdram_req_tvalid,
        s_axis_req_tready       => sdram_req_tready,
        s_axis_req_tdata        => sdram_req_tdata,

        m_axis_res_tvalid       => sdram_res_tvalid,
        m_axis_res_tdata        => sdram_res_tdata,

        DRAM_ADDR               => zs_addr,
        DRAM_BA                 => zs_ba,
        DRAM_CAS_N              => zs_cas_n,
        DRAM_CKE                => zs_cke,
        DRAM_CS_N               => zs_cs_n,
        DRAM_DQ                 => zs_dq,
        DRAM_DQM                => zs_dqm,
        DRAM_RAS_N              => zs_ras_n,
        DRAM_WE_N               => zs_we_n
    );

    sdram_test_model_inst : sdram_test_model port map (
        clk                 => CLK,

        zs_addr             => zs_addr,
        zs_ba               => zs_ba,
        zs_cas_n            => zs_cas_n,
        zs_cke              => zs_cke,
        zs_cs_n             => zs_cs_n,
        zs_dq               => zs_dq,
        zs_dqm              => zs_dqm,
        zs_ras_n            => zs_ras_n,
        zs_we_n             => zs_we_n
    );

    -- Module cpu86 instantiation
    cpu86_inst : cpu86 port map(
        clk                     => clk,
        resetn                  => resetn,

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
        interrupt_ack           => interrupt_ack
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

        m_axis_sdram_req_tvalid => ps_sdram_req_tvalid,
        m_axis_sdram_req_tready => ps_sdram_req_tready,
        m_axis_sdram_req_tdata  => ps_sdram_req_tdata,

        s_axis_sdram_res_tvalid => ps_sdram_res_tvalid,
        s_axis_sdram_res_tdata  => ps_sdram_res_tdata,

        m_axis_bram_req_tvalid  => bram_req_tvalid,
        m_axis_bram_req_tready  => bram_req_tready,
        m_axis_bram_req_tdata   => bram_req_tdata,

        s_axis_bram_res_tvalid  => bram_res_tvalid,
        s_axis_bram_res_tdata   => bram_res_tdata
    );


    -- Module soc_io_interconnect instantiation
    soc_io_interconnect_inst : soc_io_interconnect port map (
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
        -- port_61
        m_axis_port_61_req_tvalid   => port_61_req_tvalid,
        m_axis_port_61_req_tready   => port_61_req_tready,
        m_axis_port_61_req_tdata    => port_61_req_tdata,
        s_axis_port_61_res_tvalid   => port_61_rd_tvalid,
        s_axis_port_61_res_tready   => port_61_rd_tready,
        s_axis_port_61_res_tdata    => port_61_rd_tdata
    );


    -- Module pit_8254 instantiation
    pit_8254_inst : pit_8254 port map(
        clk                     => clk,
        resetn                  => resetn,

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
        resetn                  => resetn,

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
        resetn                  => resetn,

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
        resetn                  => resetn,

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
        resetn                  => resetn,

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
        resetn                  => resetn,

        io_req_s_tvalid         => hex_0_req_tvalid,
        io_req_s_tready         => hex_0_req_tready,
        io_req_s_tdata          => hex_0_req_tdata,

        io_rd_m_tvalid          => hex_0_rd_tvalid,
        io_rd_m_tready          => hex_0_rd_tready,
        io_rd_m_tdata           => hex_0_rd_tdata,

        HEX0                    => open,
        HEX1                    => open,
        HEX2                    => open,
        HEX3                    => open
    );


    -- Module soc_io_seg_7 instantiation
    soc_io_seg_7_1_inst : soc_io_seg_7 generic map (
        INIT_VALUE              => x"0000"
    ) port map(
        clk                     => clk,
        resetn                  => resetn,

        io_req_s_tvalid         => hex_1_req_tvalid,
        io_req_s_tready         => hex_1_req_tready,
        io_req_s_tdata          => hex_1_req_tdata,

        io_rd_m_tvalid          => hex_1_rd_tvalid,
        io_rd_m_tready          => hex_1_rd_tready,
        io_rd_m_tdata           => hex_1_rd_tdata,

        HEX0                    => open,
        HEX1                    => open,
        HEX2                    => open,
        HEX3                    => open
    );


    -- Module soc_io_uart instantiation
    soc_io_uart_inst : soc_io_uart port map(
        clk                     => clk,
        resetn                  => resetn,

        io_req_s_tvalid         => uart_req_tvalid,
        io_req_s_tready         => uart_req_tready,
        io_req_s_tdata          => uart_req_tdata,

        io_rd_m_tvalid          => uart_rd_tvalid,
        io_rd_m_tready          => uart_rd_tready,
        io_rd_m_tdata           => uart_rd_tdata,

        rx                      => '1',
        tx                      => open
    );


    -- Assigns
    wr_s_tvalid                     <= '1' when bram_req_tvalid = '1' and bram_req_tdata(57) = '1' else '0';
    bram_req_tready                 <= '1';
    wr_s_taddr                      <= bram_req_tdata(ADDR_WIDTH - 1 + 32 downto 32);
    wr_s_tmask                      <= bram_req_tdata(61 downto 58);
    wr_s_tdata                      <= bram_req_tdata(31 downto 0);

    rd_s_tvalid                     <= '1' when bram_req_tvalid = '1' and bram_req_tdata(57) = '0' else '0';
    rd_s_taddr                      <= bram_req_tdata(ADDR_WIDTH - 1 + 32 downto 32);

    interrupt_vector(15 downto 1)   <= (others => '0');
    interrupt_vector(0)             <= timer_ff;

    vid_sdram_req_tvalid                <= '0';

    -- video sdram req
    sdram_port_req_tvalid(0)            <= vid_sdram_req_tvalid;
    vid_sdram_req_tready                <= sdram_port_req_tready(0);
    sdram_port_req_tdata(63 downto 0)   <= vid_sdram_req_tdata;

    vid_sdram_res_tvalid                <= sdram_port_res_tvalid(0);
    vid_sdram_res_tdata                 <= sdram_port_res_tdata(31 downto 0);

    -- processing system sdram req
    sdram_port_req_tvalid(1)            <= ps_sdram_req_tvalid;
    ps_sdram_req_tready                 <= sdram_port_req_tready(1);
    sdram_port_req_tdata(127 downto 64) <= ps_sdram_req_tdata;

    ps_sdram_res_tvalid                <= sdram_port_res_tvalid(1);
    ps_sdram_res_tdata                 <= sdram_port_res_tdata(63 downto 32);


    latching_timer_ff_proc: process (clk) begin
        if rising_edge(clk) then
            if (resetn = '0') then
                d_event_timer <= '0';
                timer_ff <= '0';
            else
                d_event_timer <= event_timer;
                if (event_timer = '1' and d_event_timer = '0') then
                    timer_ff <= not timer_ff;
                end if;
            end if;
        end if;
    end process;

    -- Clock process
    clk_process : process begin
    	CLK <= '0';
    	wait for CLK_PERIOD/2;
    	CLK <= '1';
    	wait for CLK_PERIOD/2;
    end process;

    -- Reset process
    reset_process : process begin
        RESETN <= '0';
        wait for 100 ns;
        RESETN <= '1';
        wait;
    end process;

    sw_process : process (CLK) begin
        if rising_edge(clk) then
            SW <= std_logic_vector(unsigned(SW) + to_unsigned(1, 16));
        end if;
    end process;

end architecture;
