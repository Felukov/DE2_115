library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity fetcher_tb is
end entity fetcher_tb;

architecture rtl of fetcher_tb is

    -- Clock period definitions
    constant CLK_PERIOD         : time := 10 ns;

    component fetcher is
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            req_s_tvalid        : in std_logic;
            req_s_tdata         : in std_logic_vector(31 downto 0);

            rd_s_tvalid         : in std_logic;
            rd_s_tdata          : in std_logic_vector(31 downto 0);

            cmd_m_tvalid        : out std_logic;
            cmd_m_tready        : in std_logic;
            cmd_m_tdata         : out std_logic_vector(19 downto 0);

            buf_m_tvalid        : out std_logic;
            buf_m_tready        : in std_logic;
            buf_m_tdata         : out std_logic_vector(31 downto 0);
            buf_m_tuser         : out std_logic_vector(31 downto 0)

        );
    end component fetcher;


    signal CLK              : std_logic := '0';
    signal RESETN           : std_logic := '0';

    signal req_s_tvalid     : std_logic;
    signal req_s_tdata      : std_logic_vector(31 downto 0);
    signal rd_s_tvalid      : std_logic_vector(5 downto 0);
    signal rd_s_tdata0      : std_logic_vector(31 downto 0);
    signal rd_s_tdata1      : std_logic_vector(31 downto 0);
    signal rd_s_tdata2      : std_logic_vector(31 downto 0);
    signal rd_s_tdata3      : std_logic_vector(31 downto 0);
    signal rd_s_tdata4      : std_logic_vector(31 downto 0);
    signal rd_s_tdata5      : std_logic_vector(31 downto 0);
    signal cmd_m_tvalid     : std_logic;
    signal cmd_m_tready     : std_logic;
    signal cmd_m_tdata      : std_logic_vector(19 downto 0);
    signal buf_m_tvalid     : std_logic;
    signal buf_m_tready     : std_logic;
    signal buf_m_tdata      : std_logic_vector(31 downto 0);
    signal buf_m_tuser      : std_logic_vector(31 downto 0);

    signal cnt              : integer := 0;

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

    fetcher_inst : fetcher port map(
        clk                 => clk,
        resetn              => resetn,

        req_s_tvalid        => req_s_tvalid,
        req_s_tdata         => req_s_tdata,

        rd_s_tvalid         => rd_s_tvalid(5),
        rd_s_tdata          => rd_s_tdata5,

        cmd_m_tvalid        => cmd_m_tvalid,
        cmd_m_tready        => cmd_m_tready,
        cmd_m_tdata         => cmd_m_tdata,

        buf_m_tvalid        => buf_m_tvalid,
        buf_m_tready        => buf_m_tready,
        buf_m_tdata         => buf_m_tdata,
        buf_m_tuser         => buf_m_tuser
    );

    process begin
        req_s_tvalid <= '0';

        wait until resetn = '1';
        wait for 200 ns;
        loop
            wait until rising_edge(clk);
            cnt <= cnt + 1;
            req_s_tvalid <= '1';
            req_s_tdata <= (others => '0');
            wait until rising_edge(clk);
            req_s_tvalid <= '0';
            wait for 300 ns;
        end loop;

    end process;

    process begin
        cmd_m_tready <= '1';
        wait until resetn = '1';
        wait until rising_edge(clk);

        loop
            wait until rising_edge(clk) and cmd_m_tvalid = '1' and cmd_m_tready = '1';

            cmd_m_tready <= '0';
            for i in 0 to 0 loop
                wait until rising_edge(clk);
            end loop;
            cmd_m_tready <= '1';
        end loop;

    end process;

    process (clk) begin
        if rising_edge(clk) then
            if RESETN = '0' then
                rd_s_tvalid <= (others => '0');
            else
                if (cmd_m_tvalid = '1' and cmd_m_tready = '1') then
                    rd_s_tvalid(0) <= '1';
                else
                    rd_s_tvalid(0) <= '0';
                end if;
                rd_s_tvalid(5 downto 1) <= rd_s_tvalid(4 downto 0);

                if (cmd_m_tvalid = '1' and cmd_m_tready = '1') then
                rd_s_tdata0 <= x"000" & cmd_m_tdata;
                end if;
                rd_s_tdata1 <= rd_s_tdata0;
                rd_s_tdata2 <= rd_s_tdata1;
                rd_s_tdata3 <= rd_s_tdata2;
                rd_s_tdata4 <= rd_s_tdata3;
                rd_s_tdata5 <= rd_s_tdata4;
            end if;
        end if;
    end process;

    process begin
        buf_m_tready <= '1';
        wait until resetn = '1';
        wait until rising_edge(clk);

        loop
            wait until rising_edge(clk) and buf_m_tvalid = '1' and buf_m_tready = '1';

            buf_m_tready <= '0';
            for i in 0 to 3 loop
                wait until rising_edge(clk);
            end loop;
            buf_m_tready <= '1';
        end loop;

    end process;

end architecture;
