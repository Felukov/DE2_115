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
        VGA_VS                      : out std_logic
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

    component sdram_tester is
        port (
            clk                     : in std_logic;
            resetn                  : in std_logic;
            cmd_m_tvalid            : out std_logic;
            cmd_m_tready            : in std_logic;
            cmd_m_tdata             : out std_logic_vector(63 downto 0)
        );
    end component;

    component axis_sdram is
        port (
            clk                     : in std_logic;
            resetn                  : in std_logic;

            cmd_s_tvalid            : in std_logic;
            cmd_s_tready            : out std_logic;
            cmd_s_tdata             : in std_logic_vector (63 downto 0);

            rd_m_tvalid             : out std_logic;
            rd_m_tdata              : out std_logic_vector(31 downto 0);

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

    component vga_ctrl is
        port (
            clk                     : in std_logic;
            resetn                  : in std_logic;
            VGA_CLK                 : out std_logic;
            VGA_BLANK_N             : out std_logic;
            VGA_SYNC_N              : out std_logic;
            VGA_HS                  : out std_logic;
            VGA_VS                  : out std_logic
        );
    end component vga_ctrl;

    signal clk_100                  : std_logic;
    signal clk_100_locked           : std_logic;
    signal resetn                   : std_logic := '0';
    signal led_ff                   : std_logic_vector(17 downto 0);

	signal vga_pll_clk              : std_logic;
	signal vga_pll_locked           : std_logic;

    signal cmd_tvalid               : std_logic;
    signal cmd_tready               : std_logic;
    signal cmd_tdata                : std_logic_vector(63 downto 0);

    signal rd_tvalid                : std_logic;
    signal rd_tdata                 : std_logic_vector(31 downto 0);

begin
    --VGA_CLK <= not vga_pll_clk;

    clock_manager_inst : clock_manager port map (
        inclk0          => CLOCK_50,
        c0              => clk_100,
        c1              => DRAM_CLK,
        locked          => clk_100_locked
    );

	 vga_pll_inst : vga_pll port map (
        inclk0          => CLOCK2_50,
        c0              => vga_pll_clk,
        locked          => vga_pll_locked
    );

    sdram_tester_inst : sdram_tester port map (
        clk             => clk_100,
        resetn          => resetn,

        cmd_m_tvalid    => cmd_tvalid,
        cmd_m_tready    => cmd_tready,
        cmd_m_tdata     => cmd_tdata
    );

    axis_sdram_inst : axis_sdram port map (
        clk             => clk_100,
        resetn          => resetn,

        cmd_s_tvalid    => cmd_tvalid,
        cmd_s_tready    => cmd_tready,
        cmd_s_tdata     => cmd_tdata,

        rd_m_tvalid     => rd_tvalid,
        rd_m_tdata      => rd_tdata,

        DRAM_ADDR       => DRAM_ADDR,
        DRAM_BA         => DRAM_BA,
        DRAM_CAS_N      => DRAM_CAS_N,
        DRAM_CKE        => DRAM_CKE,
        DRAM_CS_N       => DRAM_CS_N,
        DRAM_DQ         => DRAM_DQ,
        DRAM_DQM        => DRAM_DQM,
        DRAM_RAS_N      => DRAM_RAS_N,
        DRAM_WE_N       => DRAM_WE_N
    );

    vga_ctrl_inst : vga_ctrl port map (
        clk             => vga_pll_clk,
        resetn          => vga_pll_locked,
        VGA_CLK         => VGA_CLK,
        VGA_BLANK_N     => VGA_BLANK_N,
        VGA_SYNC_N      => VGA_SYNC_N,
        VGA_HS          => VGA_HS,
        VGA_VS          => VGA_VS
    );

    LEDR <= led_ff;
    LEDG <= (others => '0');

    VGA_B <= (others => '0');
    VGA_G <= (others => '1');
    VGA_R <= (others => '1');

    process (clk_100) begin
        if (rising_edge(clk_100)) then
            resetn <= clk_100_locked;
        end if;
    end process;

    process (clk_100) begin
        if rising_edge(clk_100) then

            if (rd_tvalid = '1') then
                led_ff <= rd_tdata(17 downto 0) or rd_tdata(31 downto 14);
            end if;

        end if;
    end process;


end architecture;
