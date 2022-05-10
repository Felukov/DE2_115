library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity top is
    port (
        CLOCK_50                    : in std_logic;
        CLOCK2_50                   : in std_logic;
        LEDG                        : out std_logic_vector(8 downto 0);
        LEDR                        : out std_logic_vector(17 downto 0);
        SW                          : in std_logic_vector(17 downto 0);
        --SDRAM
        DRAM_ADDR                   : out std_logic_vector(12 downto 0);
        DRAM_BA                     : out std_logic_vector(1 downto 0);
        DRAM_CAS_N                  : out std_logic;
        DRAM_CLK                    : out std_logic;
        DRAM_CKE                    : out std_logic;
        DRAM_CS_N                   : out std_logic;
        DRAM_DQ                     : inout std_logic_vector(31 downto 0);
        DRAM_DQM                    : out std_logic_vector(3 downto 0);
        DRAM_RAS_N                  : out std_logic;
        DRAM_WE_N                   : out std_logic;

        VGA_CLK                     : out std_logic;
        VGA_BLANK_N                 : out std_logic;
        VGA_SYNC_N                  : out std_logic;
        VGA_B                       : out std_logic_vector(7 downto 0);
        VGA_G                       : out std_logic_vector(7 downto 0);
        VGA_R                       : out std_logic_vector(7 downto 0);
        VGA_HS                      : out std_logic;
        VGA_VS                      : out std_logic;

        KEY                         : in std_logic_vector(3 downto 0);

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
end entity top;

architecture rtl of top is

    component clock_manager is
        port (
            inclk0                  : in std_logic := '0';
            c0                      : out std_logic;
            c1                      : out std_logic;
            locked                  : out std_logic
        );
    end component;

    component vga_pll is
        port (
            inclk0                  : in std_logic := '0';
            c0                      : out std_logic;
            locked                  : out std_logic
        );
    end component;

    component sync_resets is
        port (
            clk_a                   : in std_logic;
            clk_b                   : in std_logic;
            resetn_a                : in std_logic;
            resetn_b                : in std_logic;
            sync_resetn_a           : out std_logic;
            sync_resetn_b           : out std_logic
        );
    end component sync_resets;

    component sdram_tester is
        port (
            clk                     : in std_logic;
            resetn                  : in std_logic;

            cmd_s_tvalid            : in std_logic;
            cmd_s_tdata             : in std_logic;

            cmd_m_tvalid            : out std_logic;
            cmd_m_tready            : in std_logic;
            cmd_m_tdata             : out std_logic_vector(63 downto 0)
        );
    end component;

    component axis_sdram is
        port (
            clk                     : in std_logic;
            resetn                  : in std_logic;

            s_axis_req_tvalid       : in std_logic;
            s_axis_req_tready       : out std_logic;
            s_axis_req_tdata        : in std_logic_vector (63 downto 0);

            m_axis_res_tvalid       : out std_logic;
            m_axis_res_tdata        : out std_logic_vector(31 downto 0);

            DRAM_ADDR               : out std_logic_vector(12 downto 0);
            DRAM_BA                 : out std_logic_vector(1 downto 0);
            DRAM_CAS_N              : out std_logic;
            DRAM_CKE                : out std_logic;
            DRAM_CS_N               : out std_logic;
            DRAM_DQ                 : inout std_logic_vector(31 downto 0);
            DRAM_DQM                : out std_logic_vector(3 downto 0);
            DRAM_RAS_N              : out std_logic;
            DRAM_WE_N               : out std_logic
        );
    end component;

    component video_system is
        port (
            vid_clk                     : in std_logic;
            vid_resetn                  : in std_logic;

            VGA_CLK                     : out std_logic;
            VGA_BLANK_N                 : out std_logic;
            VGA_SYNC_N                  : out std_logic;
            VGA_HS                      : out std_logic;
            VGA_VS                      : out std_logic;

            VGA_R                       : out std_logic_vector(7 downto 0);
            VGA_G                       : out std_logic_vector(7 downto 0);
            VGA_B                       : out std_logic_vector(7 downto 0)
        );
    end component video_system;

    component altddio_core is
        port
        (
            outclock                    : in std_logic;
            datain_h                    : in std_logic_vector (0 downto 0);
            datain_l                    : in std_logic_vector (0 downto 0);
            dataout                     : out std_logic_vector (0 downto 0)
        );
    end component altddio_core;

    component timer is
        port (
            clk_100                 : in std_logic;
            resetn_100              : in std_logic;
            timer_m_tvalid          : out std_logic
        );
    end component timer;

    component debouncer is
        port (
            clk                     : in std_logic;
            resetn                  : in std_logic;

            signal_s_tvalid         : in std_logic;
            signal_s_tdata          : in std_logic;

            detection_m_tvalid      : out std_logic;
            detection_m_tdata       : out std_logic
        );
    end component debouncer;

    component soc is
        port (
            clk                     : in std_logic;
            resetn                  : in std_logic;

            SW                      : in std_logic_vector(17 downto 0);
            LEDG                    : out std_logic_vector(8 downto 0);

            HEX0                    : out std_logic_vector(6 downto 0);
            HEX1                    : out std_logic_vector(6 downto 0);
            HEX2                    : out std_logic_vector(6 downto 0);
            HEX3                    : out std_logic_vector(6 downto 0);
            HEX4                    : out std_logic_vector(6 downto 0);
            HEX5                    : out std_logic_vector(6 downto 0);
            HEX6                    : out std_logic_vector(6 downto 0);
            HEX7                    : out std_logic_vector(6 downto 0);

            BT_UART_RX              : in std_logic;
            BT_UART_TX              : out std_logic
        );
    end component soc;


    signal clk_100                  : std_logic;
    signal clk_100_locked           : std_logic;
    signal clk_100_resetn           : std_logic := '0';

    signal vga_pll_clk              : std_logic;
    signal vga_pll_locked           : std_logic;
    signal vga_pll_resetn           : std_logic := '0';

    signal led_ff                   : std_logic_vector(17 downto 0);

    signal cmd_tvalid               : std_logic;
    signal cmd_tready               : std_logic;
    signal cmd_tdata                : std_logic_vector(63 downto 0);

    signal rd_tvalid                : std_logic;
    signal rd_tdata                 : std_logic_vector(31 downto 0);

    signal timer_tvalid             : std_logic;

    signal btn_0_n                  : std_logic_vector(1 downto 0);

    signal btn0_tvalid              : std_logic;
    signal btn0_tdata               : std_logic;

    signal oddr_dout                : std_logic_vector(0 downto 0);

begin
    --VGA_CLK <= not vga_pll_clk;

    clock_manager_inst : clock_manager port map (
        inclk0              => CLOCK_50,
        c0                  => clk_100,
        c1                  => DRAM_CLK,
        locked              => clk_100_locked
    );

     vga_pll_inst : vga_pll port map (
        inclk0              => CLOCK2_50,
        c0                  => vga_pll_clk,
        locked              => vga_pll_locked
    );

    sync_resets_inst : sync_resets port map (
        clk_a               => clk_100,
        resetn_a            => clk_100_locked,
        clk_b               => vga_pll_clk,
        resetn_b            => vga_pll_locked,
        sync_resetn_a       => clk_100_resetn,
        sync_resetn_b       => vga_pll_resetn
    );

    timer_1ms_inst : timer port map (
        clk_100             => clk_100,
        resetn_100          => clk_100_resetn,
        timer_m_tvalid      => timer_tvalid
    );

    debouncer_btn_0_inst : debouncer port map (
        clk                 => clk_100,
        resetn              => clk_100_resetn,

        signal_s_tvalid     => timer_tvalid,
        signal_s_tdata      => not btn_0_n(1),

        detection_m_tvalid  => btn0_tvalid,
        detection_m_tdata   => btn0_tdata
    );

    sdram_tester_inst : sdram_tester port map (
        clk                 => clk_100,
        resetn              => clk_100_resetn,

        cmd_s_tvalid        => btn0_tvalid,
        cmd_s_tdata         => btn0_tdata,

        cmd_m_tvalid        => cmd_tvalid,
        cmd_m_tready        => cmd_tready,
        cmd_m_tdata         => cmd_tdata
    );

    axis_sdram_inst : axis_sdram port map (
        clk                 => clk_100,
        resetn              => clk_100_resetn,

        s_axis_req_tvalid   => cmd_tvalid,
        s_axis_req_tready   => cmd_tready,
        s_axis_req_tdata    => cmd_tdata,

        m_axis_res_tvalid   => rd_tvalid,
        m_axis_res_tdata    => rd_tdata,

        DRAM_ADDR           => DRAM_ADDR,
        DRAM_BA             => DRAM_BA,
        DRAM_CAS_N          => DRAM_CAS_N,
        DRAM_CKE            => DRAM_CKE,
        DRAM_CS_N           => DRAM_CS_N,
        DRAM_DQ             => DRAM_DQ,
        DRAM_DQM            => DRAM_DQM,
        DRAM_RAS_N          => DRAM_RAS_N,
        DRAM_WE_N           => DRAM_WE_N
    );

    video_system_inst : video_system port map (
        vid_clk             => vga_pll_clk,
        vid_resetn          => vga_pll_resetn,
        VGA_CLK             => open,
        VGA_BLANK_N         => VGA_BLANK_N,
        VGA_SYNC_N          => VGA_SYNC_N,
        VGA_HS              => VGA_HS,
        VGA_VS              => VGA_VS,
        VGA_R               => VGA_R,
        VGA_G               => VGA_G,
        VGA_B               => VGA_B
    );

    altddio_core_inst : altddio_core PORT MAP (
        outclock            => vga_pll_clk,
        datain_h            => (others => '1'),
        datain_l            => (others => '0'),
        dataout             => oddr_dout
    );

    VGA_CLK <= oddr_dout(0);

    -- soc_inst : soc port map (
    --     clk                 => clk_100,
    --     resetn              => clk_100_resetn,

    --     LEDG                => LEDG,
    --     SW                  => SW,

    --     HEX0                => HEX0,
    --     HEX1                => HEX1,
    --     HEX2                => HEX2,
    --     HEX3                => HEX3,
    --     HEX4                => HEX4,
    --     HEX5                => HEX5,
    --     HEX6                => HEX6,
    --     HEX7                => HEX7,

    --     BT_UART_RX          => BT_UART_RX,
    --     BT_UART_TX          => BT_UART_TX
    -- );

    HEX0 <= (others => '0');
    HEX1 <= (others => '0');
    HEX2 <= (others => '0');
    HEX3 <= (others => '0');
    HEX4 <= (others => '0');
    HEX5 <= (others => '0');
    HEX6 <= (others => '0');
    HEX7 <= (others => '0');
    LEDG <= (others => '0');
    BT_UART_TX <= '1';

    LEDR(17)          <= not BT_UART_TX;
    LEDR(16)          <= not BT_UART_RX;
    LEDR(15 downto 0) <= led_ff(15 downto 0);

    process (clk_100) begin
        if rising_edge(clk_100) then

            if (rd_tvalid = '1') then
                led_ff <= rd_tdata(17 downto 0) or rd_tdata(31 downto 14);
            end if;

        end if;
    end process;

    process (clk_100) begin

        if (rising_edge(clk_100)) then

            if (clk_100_resetn = '0') then
                btn_0_n <= (others => '1');
            else
                btn_0_n <= btn_0_n(0) & KEY(0);
            end if;

        end if;

    end process;

end architecture;
