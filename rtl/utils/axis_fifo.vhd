library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

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

    type ram_t is array (FIFO_DEPTH-1 downto 0) of std_logic_vector(FIFO_WIDTH-1 downto 0);

    signal wr_addr          : integer range 0 to FIFO_DEPTH-1;
    signal wr_addr_next     : integer range 0 to FIFO_DEPTH-1;
    signal rd_addr          : integer range 0 to FIFO_DEPTH-1;
    signal rd_addr_next     : integer range 0 to FIFO_DEPTH-1;
    signal fifo_ram         : ram_t := (others => (others => '0'));
    signal q_tdata          : std_logic_vector(FIFO_WIDTH-1 downto 0);

    signal wr_data_tvalid   : std_logic;
    signal wr_data_tready   : std_logic;
    signal wr_data_tdata    : std_logic_vector(FIFO_WIDTH-1 downto 0);

    signal data_tvalid      : std_logic;
    signal data_tready      : std_logic;

    signal out_tvalid       : std_logic;
    signal out_tready       : std_logic;
    signal out_tdata        : std_logic_vector(FIFO_WIDTH-1 downto 0);

begin

    wr_data_tvalid  <= fifo_s_tvalid;
    fifo_s_tready   <= wr_data_tready;
    wr_data_tdata   <= fifo_s_tdata;

    --wr_data_tready  <= '1' when wr_addr_next /= rd_addr else '0';

    fifo_m_tvalid   <= out_tvalid;
    out_tready      <= fifo_m_tready;
    fifo_m_tdata    <= out_tdata;

    --data_tvalid     <= '1' when wr_addr /= rd_addr else '0';
    data_tready     <= '1' when out_tvalid = '0' or (out_tvalid = '1' and out_tready = '1') else '0';

    --wr_addr_next    <= (wr_addr + 1) mod FIFO_DEPTH;
    --rd_addr_next    <= (rd_addr + 1) mod FIFO_DEPTH;

    q_tdata         <= fifo_ram(rd_addr);

    wr_data_tready_proc : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                wr_data_tready <= '1';
            else
                if (wr_addr_next + 1) mod FIFO_DEPTH /= rd_addr_next then
                    wr_data_tready <= '1';
                else
                    wr_data_tready <= '0';
                end if;
            end if;

        end if;
    end process;

    data_tvalid_proc : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                data_tvalid <= '0';
            else
                if wr_addr_next /= rd_addr_next then
                    data_tvalid <= '1';
                else
                    data_tvalid <= '0';
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
                --if wr_data_tvalid = '1' and wr_data_tready = '1' then
                --end if;
            end if;

            if wr_data_tvalid = '1' and wr_data_tready = '1' then
                fifo_ram(wr_addr) <= wr_data_tdata;
            end if;

        end if;
    end process;

    read_proc_next : process (all) begin
        if data_tvalid = '1' and data_tready = '1' then
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
                -- if data_tvalid = '1' and data_tready = '1' then
                --     rd_addr <= rd_addr_next;
                -- end if;
            end if;
        end if;
    end process;

    register_output_gen : if (REGISTER_OUTPUT = '1') generate
        register_output_proc: process (clk) begin
            if rising_edge(clk) then
                if resetn = '0' then
                    out_tvalid <= '0';
                else

                    if data_tvalid = '1' and data_tready = '1' then
                        out_tvalid <= '1';
                    elsif out_tready = '1' then
                        out_tvalid <= '0';
                    end if;

                end if;

                if data_tready = '1' then
                    out_tdata <= q_tdata;
                end if;

            end if;
        end process;
    end generate;

    async_output_gen: if (REGISTER_OUTPUT = '0') generate

        out_tvalid <= data_tvalid;
        --data_tready <= out_tready;
        out_tdata <= q_tdata;

    end generate;

end architecture;
