library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity axis_fifo_er is
    generic (
        FIFO_DEPTH          : natural := 2**8;
        FIFO_WIDTH          : natural := 128
    );
    port (
        clk                 : in std_logic;
        resetn              : in std_logic;

        s_axis_fifo_tvalid  : in std_logic;
        s_axis_fifo_tready  : out std_logic;
        s_axis_fifo_tdata   : in std_logic_vector(FIFO_WIDTH-1 downto 0);

        m_axis_fifo_tvalid  : out std_logic;
        m_axis_fifo_tready  : in std_logic;
        m_axis_fifo_tdata   : out std_logic_vector(FIFO_WIDTH-1 downto 0)
    );
end entity axis_fifo_er;

architecture rtl of axis_fifo_er is

    type ram_t is array (FIFO_DEPTH-1 downto 0) of std_logic_vector(FIFO_WIDTH-1 downto 0);

    signal wr_addr          : integer range 0 to FIFO_DEPTH-1;
    signal wr_addr_next     : integer range 0 to FIFO_DEPTH-1;
    signal rd_addr          : integer range 0 to FIFO_DEPTH-1;
    signal rd_addr_next     : integer range 0 to FIFO_DEPTH-1;
    signal fifo_ram         : ram_t := (others => (others => '0'));

    attribute ramstyle : string;
    attribute ramstyle of fifo_ram : signal is "no_rw_check";

    signal wr_data_tvalid   : std_logic;
    signal wr_data_tready   : std_logic;
    signal wr_data_tdata    : std_logic_vector(FIFO_WIDTH-1 downto 0);

    signal rd_data_tvalid   : std_logic;
    signal rd_data_tready   : std_logic;
    signal rd_data_tdata    : std_logic_vector(FIFO_WIDTH-1 downto 0);

    signal q_tvalid         : std_logic;
    signal q_tready         : std_logic;
    signal q_tdata          : std_logic_vector(FIFO_WIDTH-1 downto 0);

    signal out_tvalid       : std_logic;
    signal out_tready       : std_logic;
    signal out_tdata        : std_logic_vector(FIFO_WIDTH-1 downto 0);

    signal fifo_cnt         : integer range 0 to FIFO_DEPTH-1;

begin

    wr_data_tvalid      <= s_axis_fifo_tvalid;
    s_axis_fifo_tready  <= wr_data_tready;
    wr_data_tdata       <= s_axis_fifo_tdata;

    m_axis_fifo_tvalid  <= out_tvalid;
    out_tready          <= m_axis_fifo_tready;
    m_axis_fifo_tdata   <= out_tdata;

    rd_data_tready      <= '1' when q_tvalid = '0' or (q_tvalid = '1' and q_tready = '1') else '0';
    q_tready            <= '1' when out_tvalid = '0' or (out_tvalid = '1' and out_tready = '1') else '0';

    fifo_throughput_proc : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                fifo_cnt <= 0;
                wr_data_tready <= '1';
                rd_data_tvalid <= '0';
            else
                if (wr_data_tvalid = '1' and wr_data_tready = '1' and rd_data_tvalid = '1' and rd_data_tready = '1') then
                    fifo_cnt <= fifo_cnt;
                elsif (wr_data_tvalid = '1' and wr_data_tready = '1') then
                    fifo_cnt <= fifo_cnt + 1;
                elsif (rd_data_tvalid = '1' and rd_data_tready = '1') then
                    fifo_cnt <= fifo_cnt - 1;
                end if;

                if (wr_data_tvalid = '1' and wr_data_tready = '1' and rd_data_tvalid = '1' and rd_data_tready = '1') then
                    wr_data_tready <= wr_data_tready;
                elsif (wr_data_tvalid = '1' and wr_data_tready = '1') then
                    if (fifo_cnt + 1) = FIFO_DEPTH-1 then
                        wr_data_tready <= '0';
                    end if;
                elsif (rd_data_tvalid = '1' and rd_data_tready = '1') then
                    wr_data_tready <= '1';
                end if;

                if (wr_data_tvalid = '1' and wr_data_tready = '1' and rd_data_tvalid = '1' and rd_data_tready = '1') then
                    rd_data_tvalid <= rd_data_tvalid;
                elsif (wr_data_tvalid = '1' and wr_data_tready = '1') then
                    rd_data_tvalid <= '1';
                elsif (rd_data_tvalid = '1' and rd_data_tready = '1') then
                    if (fifo_cnt - 1) = 0 then
                        rd_data_tvalid <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;

    write_proc_next: process (wr_data_tvalid, wr_data_tready, wr_addr) begin
        if (wr_data_tvalid = '1' and wr_data_tready = '1') then
            wr_addr_next <= (wr_addr + 1) mod FIFO_DEPTH;
        else
            wr_addr_next <= wr_addr;
        end if;
    end process;

    write_proc: process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                wr_addr <= 0;
            else
                wr_addr <= wr_addr_next;
            end if;

            if wr_data_tvalid = '1' and wr_data_tready = '1' then
                fifo_ram(wr_addr) <= wr_data_tdata;
            end if;

        end if;
    end process;

    read_proc_next : process (rd_data_tvalid, rd_data_tready, rd_addr) begin
        if rd_data_tvalid = '1' and rd_data_tready = '1' then
            rd_addr_next <= (rd_addr + 1) mod FIFO_DEPTH;
        else
            rd_addr_next <= rd_addr;
        end if;
    end process;

    read_proc : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                rd_addr <= 0;
            else
                rd_addr <= rd_addr_next;
            end if;
        end if;
    end process;

    register_q_proc: process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                q_tvalid <= '0';
            else
                if rd_data_tvalid = '1' and rd_data_tready = '1' then
                    q_tvalid <= '1';
                elsif q_tready = '1' then
                    q_tvalid <= '0';
                end if;
            end if;

            if rd_data_tready = '1' then
                q_tdata <= fifo_ram(rd_addr);
            end if;

        end if;
    end process;

    register_output_proc: process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                out_tvalid <= '0';
            else
                if q_tvalid = '1' and q_tready = '1' then
                    out_tvalid <= '1';
                elsif out_tready = '1' then
                    out_tvalid <= '0';
                end if;
            end if;

            if q_tready = '1' then
                out_tdata <= q_tdata;
            end if;

        end if;
    end process;

end architecture;
