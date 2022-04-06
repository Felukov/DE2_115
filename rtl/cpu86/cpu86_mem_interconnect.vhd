library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.cpu86_types.all;
use ieee.math_real.all;

entity cpu86_mem_interconnect is
    port (
        clk                             : in std_logic;
        resetn                          : in std_logic;

        mem_req_m_tvalid                : out std_logic;
        mem_req_m_tready                : in std_logic;
        mem_req_m_tdata                 : out std_logic_vector(63 downto 0);

        mem_rd_s_tvalid                 : in std_logic;
        mem_rd_s_tdata                  : in std_logic_vector(31 downto 0);

        fetcher_mem_req_tvalid          : in std_logic;
        fetcher_mem_req_tready          : out std_logic;
        fetcher_mem_req_tdata           : in std_logic_vector(19 downto 0);

        fetcher_mem_res_tvalid          : out std_logic;
        fetcher_mem_res_tdata           : out std_logic_vector(31 downto 0);

        exec_mem_req_tvalid             : in std_logic;
        exec_mem_req_tready             : out std_logic;
        exec_mem_req_tdata              : in std_logic_vector(63 downto 0);

        exec_mem_res_tvalid             : out std_logic;
        exec_mem_res_tdata              : out std_logic_vector(31 downto 0)
    );
end entity cpu86_mem_interconnect;

architecture rtl of cpu86_mem_interconnect is

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

    signal fifo_s_tvalid    : std_logic;
    signal fifo_m_tdata     : std_logic_vector(1 downto 0);

begin

    -- Module axis_fifo instantiation
    axis_fifo_inst : axis_fifo generic map (
        FIFO_DEPTH      => 16,
        FIFO_WIDTH      => 2
    ) port map (
        clk             => clk,
        resetn          => resetn,
        fifo_s_tvalid   => fifo_s_tvalid,
        fifo_s_tready   => open,
        fifo_s_tdata    => fetcher_mem_req_tvalid & exec_mem_req_tvalid,
        fifo_m_tvalid   => open,
        fifo_m_tready   => mem_rd_s_tvalid,
        fifo_m_tdata    => fifo_m_tdata
    );

    -- Assigns
    fetcher_mem_req_tready <= '1' when exec_mem_req_tvalid = '0' and mem_req_m_tready = '1' else '0';
    exec_mem_req_tready    <= '1' when mem_req_m_tready = '1' else '0';

    mem_req_m_tvalid       <= '1' when exec_mem_req_tvalid = '1' or fetcher_mem_req_tvalid = '1' else '0';

    fifo_s_tvalid          <= '1' when (exec_mem_req_tvalid = '1' and exec_mem_req_tdata(57) = '0') or (fetcher_mem_req_tvalid = '1' and exec_mem_req_tvalid = '0') else '0';

    fetcher_mem_res_tvalid <= '1' when mem_rd_s_tvalid = '1' and fifo_m_tdata(1) = '1' else '0';
    fetcher_mem_res_tdata  <= mem_rd_s_tdata;

    exec_mem_res_tvalid    <= '1' when mem_rd_s_tvalid = '1' and fifo_m_tdata(0) = '1' else '0';
    exec_mem_res_tdata     <= mem_rd_s_tdata;

    process (all) begin
        if (exec_mem_req_tvalid = '1') then
            mem_req_m_tdata <= exec_mem_req_tdata;
        else
            mem_req_m_tdata(63 downto 59) <= (others => '0');
            mem_req_m_tdata(61 downto 58) <= "0000";
            mem_req_m_tdata(57)           <= '0';
            mem_req_m_tdata(56 downto 32) <= "00000" & fetcher_mem_req_tdata;
            mem_req_m_tdata(31 downto 0)  <= (others => '0');
        end if;
    end process;

end architecture;
