library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity sdram_ctrl_tb is
end entity sdram_ctrl_tb;

architecture rtl of sdram_ctrl_tb is

    -- Clock period definitions
    constant CLK_PERIOD     : time := 10 ns;

    component sdram_ctrl is
        port (
            clk             : in std_logic;
            reset_n         : in std_logic;

            az_addr         : in std_logic_vector(24 downto 0);
            az_be_n         : in std_logic_vector( 3 downto 0);
            az_cs           : in std_logic;
            az_data         : in std_logic_vector(31 downto 0);
            az_rd_n         : in std_logic;
            az_wr_n         : in std_logic;

            za_waitrequest  : out std_logic;
            za_valid        : out std_logic;
            za_data         : out std_logic_vector(31 downto 0);
            zs_addr         : out std_logic_vector(12 downto 0);
            zs_ba           : out std_logic_vector( 1 downto 0);
            zs_cas_n        : out std_logic;
            zs_cke          : out std_logic;
            zs_cs_n         : out std_logic;
            zs_dq           : inout std_logic_vector(31 downto 0);
            zs_dqm          : out std_logic_vector(3 downto 0);
            zs_ras_n        : out std_logic;
            zs_we_n         : out std_logic
        );
    end component;

    component sdram_test_model is
        port (
            clk             : in std_logic;

            zs_addr         : in std_logic_vector(12 downto 0);
            zs_ba           : in std_logic_vector( 1 downto 0);
            zs_cas_n        : in std_logic;
            zs_cke          : in std_logic;
            zs_cs_n         : in std_logic;
            zs_dq           : inout std_logic_vector(31 downto 0);
            zs_dqm          : in std_logic_vector(3 downto 0);
            zs_ras_n        : in std_logic;
            zs_we_n         : in std_logic
        );
    end component;


    signal CLK              : std_logic := '0';
    signal RESETN           : std_logic := '0';

    signal az_addr          : std_logic_vector(24 downto 0);
    signal az_be_n          : std_logic_vector( 3 downto 0);
    signal az_cs            : std_logic;
    signal az_data          : std_logic_vector(31 downto 0);
    signal az_rd_n          : std_logic;
    signal az_wr_n          : std_logic;

    signal za_waitrequest   : std_logic;
    signal za_valid         : std_logic;
    signal za_data          : std_logic_vector(31 downto 0);
    signal zs_addr          : std_logic_vector(12 downto 0);
    signal zs_ba            : std_logic_vector( 1 downto 0);
    signal zs_cas_n         : std_logic;
    signal zs_cke           : std_logic;
    signal zs_cs_n          : std_logic;
    signal zs_dq            : std_logic_vector(31 downto 0);
    signal zs_dqm           : std_logic_vector(3 downto 0);
    signal zs_ras_n         : std_logic;
    signal zs_we_n          : std_logic;

begin

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
        wait for 200 ns;
        RESETN <= '1';
        wait;
    end process;

    sdram_ctrl_inst : sdram_ctrl port map (
        clk             => CLK,
        reset_n         => RESETN,

        az_addr         => az_addr,
        az_be_n         => az_be_n,
        az_cs           => az_cs,
        az_data         => az_data,
        az_rd_n         => az_rd_n,
        az_wr_n         => az_wr_n,

        za_waitrequest  => za_waitrequest,
        za_valid        => za_valid,
        za_data         => za_data,

        zs_addr         => zs_addr,
        zs_ba           => zs_ba,
        zs_cas_n        => zs_cas_n,
        zs_cke          => zs_cke,
        zs_cs_n         => zs_cs_n,
        zs_dq           => zs_dq,
        zs_dqm          => zs_dqm,
        zs_ras_n        => zs_ras_n,
        zs_we_n         => zs_we_n
    );

    sdram_test_model_inst : sdram_test_model port map (
        clk             => CLK,

        zs_addr         => zs_addr,
        zs_ba           => zs_ba,
        zs_cas_n        => zs_cas_n,
        zs_cke          => zs_cke,
        zs_cs_n         => zs_cs_n,
        zs_dq           => zs_dq,
        zs_dqm          => zs_dqm,
        zs_ras_n        => zs_ras_n,
        zs_we_n         => zs_we_n
    );


    process begin

        wait until resetn = '1';
        wait until rising_edge(clk);

        az_cs <= '0';
        az_wr_n <= '1';
        az_rd_n <= '1';
        az_be_n <= (others => '0');

        wait until rising_edge(clk) and za_waitrequest = '0';
        az_cs <= '1';
        az_addr <= '0' & x"000001";
        az_data <= (others => '1');
        az_wr_n <= '0';

        wait until rising_edge(clk) and za_waitrequest = '0';
        az_cs <= '1';
        az_addr <= (others => '0');
        az_data <= (others => '1');
        az_wr_n <= '0';

        wait until rising_edge(clk) and za_waitrequest = '0';
        az_cs <= '0';
        az_wr_n <= '1';

        wait until rising_edge(clk) and za_waitrequest = '0';
        az_cs <= '1';
        az_rd_n <= '0';
        az_addr <= (others => '0');
        wait until rising_edge(clk) and za_waitrequest = '0';
        az_cs <= '1';
        az_rd_n <= '0';
        az_addr <= '0' & x"000001";
        wait until rising_edge(clk) and za_waitrequest = '0';
        az_cs <= '1';
        az_rd_n <= '0';
        az_addr <= '0' & x"000002";
        wait until rising_edge(clk) and za_waitrequest = '0';
        az_cs <= '1';
        az_rd_n <= '0';
        az_addr <= '0' & x"000003";
        wait until rising_edge(clk) and za_waitrequest = '0';
        az_cs <= '1';
        az_rd_n <= '0';
        az_addr <= '0' & x"000004";
        wait until rising_edge(clk) and za_waitrequest = '0';
        az_cs <= '1';
        az_rd_n <= '0';
        az_addr <= '0' & x"F00002";
        wait until rising_edge(clk) and za_waitrequest = '0';
        az_cs <= '1';
        az_rd_n <= '0';
        az_addr <= '0' & x"F00003";
        wait until rising_edge(clk) and za_waitrequest = '0';
        az_cs <= '0';
        az_rd_n <= '1';

    end process;


end architecture;