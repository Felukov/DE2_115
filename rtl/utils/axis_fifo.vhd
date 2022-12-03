library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;

entity axis_fifo is
    generic (
        FIFO_DEPTH      : natural := 2**8;
        FIFO_WIDTH      : natural := 128;
        REGISTER_OUTPUT : std_logic := '1'
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
end entity axis_fifo;

architecture rtl of axis_fifo is

    constant BRAM_AW        : natural := integer(ceil(log2(real(FIFO_DEPTH))));

    signal wr_addr          : integer range 0 to FIFO_DEPTH-1;
    signal wr_addr_next     : integer range 0 to FIFO_DEPTH-1;
    signal rd_addr          : integer range 0 to FIFO_DEPTH-1;
    signal rd_addr_next     : integer range 0 to FIFO_DEPTH-1;

    signal bram_wr_tvalid   : std_logic;
    signal bram_wr_taddr    : std_logic_vector(BRAM_AW-1 downto 0);

    signal wr_data_tvalid   : std_logic;
    signal wr_data_tready   : std_logic;
    signal wr_data_tdata    : std_logic_vector(FIFO_WIDTH-1 downto 0);

    signal rd_data_tvalid   : std_logic;
    signal rd_data_tready   : std_logic;
    signal rd_data_taddr    : std_logic_vector(BRAM_AW-1 downto 0);

    signal fifo_cnt         : integer range 0 to FIFO_DEPTH-1;

begin

    bram_wr_tvalid <= '1' when wr_data_tvalid = '1' and wr_data_tready = '1' else '0';
    bram_wr_taddr <= std_logic_vector(to_unsigned(wr_addr, BRAM_AW));

    rd_data_taddr <= std_logic_vector(to_unsigned(rd_addr, BRAM_AW));

    axis_fifo_bram_inst : entity work.axis_fifo_bram generic map (
        ADDR_WIDTH          => BRAM_AW,
        DATA_WIDTH          => FIFO_WIDTH,
        REGISTER_OUTPUT     => REGISTER_OUTPUT
    ) port map (
        clk                 => clk,
        resetn              => resetn,

        s_axis_wr_tvalid    => bram_wr_tvalid,
        s_axis_wr_taddr     => bram_wr_taddr,
        s_axis_wr_tdata     => wr_data_tdata,

        s_axis_rd_tvalid    => rd_data_tvalid,
        s_axis_rd_tready    => rd_data_tready,
        s_axis_rd_taddr     => rd_data_taddr,
        s_axis_rd_tuser     => (others => '0'),

        m_axis_res_tvalid   => fifo_m_tvalid,
        m_axis_res_tready   => fifo_m_tready,
        m_axis_res_tdata    => fifo_m_tdata
    );

    wr_data_tvalid  <= fifo_s_tvalid;
    fifo_s_tready   <= wr_data_tready;
    wr_data_tdata   <= fifo_s_tdata;


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

    write_proc_next: process (all) begin
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

        end if;
    end process;

    read_proc_next : process (all) begin
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

end architecture;
