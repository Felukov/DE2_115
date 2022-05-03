library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity on_chip_ram is
    generic (
        ADDR_WIDTH      : natural := 12;
        DATA_WIDTH      : natural := 32;
        USER_WIDTH      : natural := 32;
        BYTES           : natural := 4
    );
    port (
        clk             : in std_logic;
        resetn          : in std_logic;

        wr_s_tvalid     : in std_logic;
        wr_s_taddr      : in std_logic_vector(ADDR_WIDTH-1 downto 0);
        wr_s_tmask      : in std_logic_vector(BYTES-1 downto 0);
        wr_s_tdata      : in std_logic_vector(DATA_WIDTH-1 downto 0);

        rd_s_tvalid     : in std_logic;
        rd_s_taddr      : in std_logic_vector(ADDR_WIDTH-1 downto 0);
        rd_s_tuser      : in std_logic_vector(USER_WIDTH-1 downto 0);

        rd_m_tvalid     : out std_logic;
        rd_m_tdata      : out std_logic_vector(DATA_WIDTH-1 downto 0);
        rd_m_tuser      : out std_logic_vector(USER_WIDTH-1 downto 0)
    );
end entity on_chip_ram;

architecture rtl of on_chip_ram is

    constant BYTE_WIDTH : natural := 8;

    component on_chip_ram_core is
        generic (
            ADDR_WIDTH  : natural := 6;
            BYTE_WIDTH  : natural := 8;
            BYTES       : natural := 4
        );
        port (
            clk         : in std_logic;
            we          : in std_logic;
            be          : in std_logic_vector(BYTES - 1 downto 0);
            wdata       : in std_logic_vector(BYTES * BYTE_WIDTH - 1 downto 0);
            waddr       : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
            raddr       : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
            q           : out std_logic_vector(BYTES*BYTE_WIDTH-1 downto 0)
        );
    end component;

    -- bram output
    signal q_tvalid     : std_logic;
    signal q_tdata      : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal q_tuser      : std_logic_vector(USER_WIDTH-1 downto 0);
    -- bram embedded register
    signal bram_tvalid  : std_logic;
    signal bram_tdata   : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal bram_tuser   : std_logic_vector(USER_WIDTH-1 downto 0);

begin

    on_chip_ram_core_inst : on_chip_ram_core generic map (
        ADDR_WIDTH      => ADDR_WIDTH,
        BYTE_WIDTH      => 8,
        BYTES           => DATA_WIDTH / BYTE_WIDTH
    ) port map (
        clk             => clk,
        we              => wr_s_tvalid,
        be              => wr_s_tmask,
        wdata           => wr_s_tdata,
        waddr           => wr_s_taddr,
        raddr           => rd_s_taddr,
        q               => q_tdata
    );

    read_proc : process (clk) begin
        if rising_edge(clk) then
            -- resettable
            if resetn = '0' then
                q_tvalid <= '0';
                bram_tvalid <= '0';
            else
                q_tvalid <= rd_s_tvalid;
                bram_tvalid <= q_tvalid;
            end if;
            -- without reset
            q_tuser <= rd_s_tuser;
            bram_tdata <= q_tdata;
            bram_tuser <= q_tuser;
        end if;
    end process;

    register_bram_out_proc : process (clk) begin
        if rising_edge(clk) then
            -- resettable
            if resetn = '0' then
                rd_m_tvalid <= '0';
            else
                rd_m_tvalid <= bram_tvalid;
            end if;
            -- without reset
            rd_m_tdata <= bram_tdata;
            rd_m_tuser <= bram_tuser;
        end if;
    end process;

end architecture;
