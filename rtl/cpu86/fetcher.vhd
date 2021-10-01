library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity fetcher is
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
end entity fetcher;

architecture rtl of fetcher is

    component axis_fifo is
        generic (
            FIFO_DEPTH      : natural := 2**8;
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

    signal cmd_tvalid       : std_logic;
    signal cmd_tready       : std_logic;
    signal cmd_tdata        : std_logic_vector(19 downto 0);

    signal max_hs_cnt       : natural range 0 to 32;
    signal mem_hs_cnt       : natural range 0 to 32;
    signal skip_hs_cnt      : natural range 0 to 32;

    signal req_tvalid       : std_logic;
    signal req_tdata        : std_logic_vector(31 downto 0);

    signal rd_tvalid        : std_logic;
    signal rd_tdata         : std_logic_vector(31 downto 0);

    signal max_inc_hs       : std_logic;
    signal max_dec_hs       : std_logic;

    signal mem_inc_hs       : std_logic;
    signal mem_dec_hs       : std_logic;

    signal cs_tdata         : std_logic_vector(15 downto 0);
    signal ip_tdata         : std_logic_vector(15 downto 0);

    signal fifo_0_s_tvalid  : std_logic;
    signal fifo_0_s_tready  : std_logic;
    signal fifo_0_s_tdata   : std_logic_vector(31 downto 0);

    signal fifo_0_m_tvalid  : std_logic;
    signal fifo_0_m_tready  : std_logic;
    signal fifo_0_m_tdata   : std_logic_vector(31 downto 0);

    signal fifo_resetn      : std_logic;
    signal fifo_1_s_tvalid  : std_logic;
    signal fifo_1_s_tready  : std_logic;
    signal fifo_1_s_tdata   : std_logic_vector(63 downto 0);

    signal fifo_1_m_tvalid  : std_logic;
    signal fifo_1_m_tready  : std_logic;
    signal fifo_1_m_tdata   : std_logic_vector(63 downto 0);

begin

    req_tvalid <= req_s_tvalid;
    req_tdata <= req_s_tdata;

    rd_tvalid <= rd_s_tvalid;
    rd_tdata <= rd_s_tdata;

    cmd_m_tvalid <= cmd_tvalid;
    cmd_tready <= cmd_m_tready;
    cmd_m_tdata <= cmd_tdata;

    axis_fifo_inst_0 : axis_fifo generic map (
        FIFO_DEPTH      => 16,
        FIFO_WIDTH      => 32
    ) port map (
        clk             => clk,
        resetn          => fifo_resetn,
        fifo_s_tvalid   => fifo_0_s_tvalid,
        fifo_s_tready   => fifo_0_s_tready,
        fifo_s_tdata    => fifo_0_s_tdata,
        fifo_m_tvalid   => fifo_0_m_tvalid,
        fifo_m_tready   => fifo_0_m_tready,
        fifo_m_tdata    => fifo_0_m_tdata
    );

    axis_fifo_inst_1 : axis_fifo generic map (
        FIFO_DEPTH      => 32,
        FIFO_WIDTH      => 64
    ) port map (
        clk             => clk,
        resetn          => fifo_resetn,
        fifo_s_tvalid   => fifo_1_s_tvalid,
        fifo_s_tready   => fifo_1_s_tready,
        fifo_s_tdata    => fifo_1_s_tdata,
        fifo_m_tvalid   => fifo_1_m_tvalid,
        fifo_m_tready   => fifo_1_m_tready,
        fifo_m_tdata    => fifo_1_m_tdata
    );

    fifo_resetn <= '0' when resetn = '0' or req_tvalid = '1' else '1';

    fifo_0_s_tvalid <= '1' when cmd_tvalid = '1' and cmd_tready = '1' else '0';
    fifo_0_s_tdata <= cs_tdata & ip_tdata;
    fifo_0_m_tready <= '1' when rd_tvalid = '1' and skip_hs_cnt = 0 else '0';

    fifo_1_s_tvalid <= '1' when rd_tvalid = '1' and skip_hs_cnt = 0 else '0';
    fifo_1_s_tdata <= fifo_0_m_tdata & rd_tdata;

    buf_m_tvalid <= fifo_1_m_tvalid;
    fifo_1_m_tready <= buf_m_tready;
    buf_m_tdata <= fifo_1_m_tdata(31 downto 0);
    buf_m_tuser <= fifo_1_m_tdata(63 downto 32);

    max_inc_hs <= '1' when (cmd_tvalid = '1' and cmd_tready = '1') and not (fifo_1_m_tvalid = '1' and fifo_1_m_tready = '1') else '0';
    max_dec_hs <= '1' when not (cmd_tvalid = '1' and cmd_tready = '1') and (fifo_1_m_tvalid = '1' and fifo_1_m_tready = '1') else '0';

    mem_inc_hs <= '1' when (cmd_tvalid = '1' and cmd_tready = '1') and not (rd_tvalid = '1' and skip_hs_cnt = 0) else '0';
    mem_dec_hs <= '1' when not (cmd_tvalid = '1' and cmd_tready = '1') and (rd_tvalid = '1' and skip_hs_cnt = 0) else '0';

    cmd_tdata <= std_logic_vector(unsigned(cs_tdata & x"0") + unsigned(ip_tdata(15 downto 2) & x"0"));

    process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                max_hs_cnt <= 0;
                mem_hs_cnt <= 0;
                skip_hs_cnt <= 0;
                cmd_tvalid <= '0';
            else

                if (max_hs_cnt < 16) then
                    cmd_tvalid <= '1';
                elsif cmd_tready = '1' then
                    cmd_tvalid <= '0';
                end if;

                if (req_tvalid = '1') then
                    mem_hs_cnt <= 0;
                elsif (mem_inc_hs = '1') then
                    mem_hs_cnt <= (mem_hs_cnt + 1) mod 32;
                elsif (mem_dec_hs = '1') then
                    mem_hs_cnt <= (mem_hs_cnt - 1) mod 32;
                end if;

                if (req_tvalid = '1') then
                    max_hs_cnt <= 0;
                elsif (max_inc_hs = '1') then
                    max_hs_cnt <= (max_hs_cnt + 1) mod 32;
                elsif (max_dec_hs = '1') then
                    max_hs_cnt <= (max_hs_cnt - 1) mod 32;
                end if;

                if (req_tvalid = '1') then
                    if (mem_inc_hs = '1') then
                        skip_hs_cnt <= (mem_hs_cnt + 1) mod 32;
                    elsif (mem_dec_hs = '1') then
                        skip_hs_cnt <= (mem_hs_cnt - 1) mod 32;
                    else
                        skip_hs_cnt <= mem_hs_cnt;
                    end if;
                elsif (rd_tvalid = '1' and skip_hs_cnt /= 0) then
                    skip_hs_cnt <= skip_hs_cnt - 1;
                end if;

            end if;

        end if;
    end process;

    -- CS:IP registers
    process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                cs_tdata <= x"0000";
                ip_tdata <= x"0400";
            else
                if (req_tvalid = '1') then
                    cs_tdata <= req_tdata(31 downto 16);
                end if;

                if (req_tvalid = '1') then
                    ip_tdata <= req_tdata(15 downto 0);
                elsif (cmd_tvalid = '1' and cmd_tready = '1') then
                    ip_tdata <= std_logic_vector(unsigned(ip_tdata(15 downto 2) & "00") + to_unsigned(4, 3));
                end if;
            end if;

        end if;
    end process;

end architecture;
