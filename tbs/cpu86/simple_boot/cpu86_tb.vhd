library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use ieee.std_logic_1164.all;
use work.cpu86_types.all;

entity cpu86_tb is
end entity cpu86_tb;

architecture rtl of cpu86_tb is
    -- Clock period definitions
    constant CLK_PERIOD         : time := 10 ns;
    constant MAX_BUF_SIZE       : integer := 1000;

    constant ADDR_WIDTH          : natural := 12;
    constant DATA_WIDTH          : natural := 32;
    constant USER_WIDTH          : natural := 32;
    constant BYTES               : natural := 4;

    component on_chip_ram is
        generic (
            ADDR_WIDTH          : natural := 12;
            DATA_WIDTH          : natural := 32;
            USER_WIDTH          : natural := 32;
            BYTES               : natural := 4
        );
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            wr_s_tvalid         : in std_logic;
            wr_s_taddr          : in std_logic_vector(ADDR_WIDTH-1 downto 0);
            wr_s_tmask          : in std_logic_vector(BYTES-1 downto 0);
            wr_s_tdata          : in std_logic_vector(DATA_WIDTH-1 downto 0);

            rd_s_tvalid         : in std_logic;
            rd_s_taddr          : in std_logic_vector(ADDR_WIDTH-1 downto 0);
            rd_s_tuser          : in std_logic_vector(USER_WIDTH-1 downto 0);

            rd_m_tvalid         : out std_logic;
            rd_m_tdata          : out std_logic_vector(DATA_WIDTH-1 downto 0);
            rd_m_tuser          : out std_logic_vector(USER_WIDTH-1 downto 0)

        );
    end component on_chip_ram;

    component cpu86 is
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            mem_req_m_tvalid    : out std_logic;
            mem_req_m_tready    : in std_logic;
            mem_req_m_tdata     : out std_logic_vector(63 downto 0);

            mem_rd_s_tvalid     : in std_logic;
            mem_rd_s_tdata      : in std_logic_vector(31 downto 0);

            io_req_m_tvalid     : out std_logic;
            io_req_m_tready     : in std_logic;
            io_req_m_tdata      : out std_logic_vector(39 downto 0);

            io_rd_s_tvalid      : in std_logic;
            io_rd_s_tready      : out std_logic;
            io_rd_s_tdata       : in std_logic_vector(15 downto 0);

            interrupt_valid     : in std_logic;
            interrupt_data      : in std_logic_vector(7 downto 0);
            interrupt_ack       : out std_logic
        );
    end component cpu86;

    component soc_io_interconnect is
        port (
            -- global singals
            clk                 : in std_logic;
            resetn              : in std_logic;
            -- cpu io
            io_req_s_tvalid     : in std_logic;
            io_req_s_tready     : out std_logic;
            io_req_s_tdata      : in std_logic_vector(39 downto 0);
            io_rd_m_tvalid      : out std_logic;
            io_rd_m_tready      : in std_logic;
            io_rd_m_tdata       : out std_logic_vector(15 downto 0);
            -- pit
            pit_req_m_tvalid    : out std_logic;
            pit_req_m_tready    : in std_logic;
            pit_req_m_tdata     : out std_logic_vector(39 downto 0);
            pit_rd_s_tvalid     : in std_logic;
            pit_rd_s_tready     : out std_logic;
            pit_rd_s_tdata      : in std_logic_vector(15 downto 0);
            -- pic
            pic_req_m_tvalid    : out std_logic;
            pic_req_m_tready    : in std_logic;
            pic_req_m_tdata     : out std_logic_vector(39 downto 0);
            pic_rd_s_tvalid     : in std_logic;
            pic_rd_s_tready     : out std_logic;
            pic_rd_s_tdata      : in std_logic_vector(15 downto 0)

        );
    end component soc_io_interconnect;

    component pit_8254 is
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            io_req_s_tvalid     : in std_logic;
            io_req_s_tready     : out std_logic;
            io_req_s_tdata      : in std_logic_vector(39 downto 0);

            io_rd_m_tvalid      : out std_logic;
            io_rd_m_tready      : in std_logic;
            io_rd_m_tdata       : out std_logic_vector(15 downto 0);

            event_irq           : out std_logic;
            event_timer         : out std_logic
        );
    end component;

    component pic is
        port(
            clk                 : in std_logic;
            resetn              : in std_logic;

            io_req_s_tvalid     : in std_logic;
            io_req_s_tready     : out std_logic;
            io_req_s_tdata      : in std_logic_vector(39 downto 0);

            io_rd_m_tvalid      : out std_logic;
            io_rd_m_tready      : in std_logic;
            io_rd_m_tdata       : out std_logic_vector(15 downto 0);

            interrupt_input     : in std_logic_vector(15 downto 0);

            interrupt_valid     : out std_logic;
            interrupt_data      : out std_logic_vector(7 downto 0);
            interrupt_ack       : in std_logic
        );
    end component;


    signal CLK                  : std_logic := '0';
    signal RESETN               : std_logic := '0';

    signal mem_req_m_tvalid     : std_logic;
    signal mem_req_m_tready     : std_logic;
    signal mem_req_m_tdata      : std_logic_vector(63 downto 0);
    signal mem_rd_s_tvalid      : std_logic;
    signal mem_rd_s_tdata       : std_logic_vector(31 downto 0);

    signal io_req_tvalid        : std_logic;
    signal io_req_tready        : std_logic;
    signal io_req_tdata         : std_logic_vector(39 downto 0);
    signal io_rd_tvalid         : std_logic;
    signal io_rd_tready         : std_logic;
    signal io_rd_tdata          : std_logic_vector(15 downto 0);

    signal pit_req_tvalid        : std_logic;
    signal pit_req_tready        : std_logic;
    signal pit_req_tdata         : std_logic_vector(39 downto 0);
    signal pit_rd_tvalid         : std_logic;
    signal pit_rd_tready         : std_logic;
    signal pit_rd_tdata          : std_logic_vector(15 downto 0);

    signal pic_req_tvalid        : std_logic;
    signal pic_req_tready        : std_logic;
    signal pic_req_tdata         : std_logic_vector(39 downto 0);
    signal pic_rd_tvalid         : std_logic;
    signal pic_rd_tready         : std_logic;
    signal pic_rd_tdata          : std_logic_vector(15 downto 0);

    signal wr_s_tvalid          : std_logic;
    signal wr_s_taddr           : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal wr_s_tmask           : std_logic_vector(BYTES-1 downto 0);
    signal wr_s_tdata           : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal rd_s_tvalid          : std_logic;
    signal rd_s_taddr           : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal rd_m_tvalid          : std_logic;
    signal rd_m_tdata           : std_logic_vector(DATA_WIDTH-1 downto 0);

    signal event_timer          : std_logic;
    signal event_irq            : std_logic;

    signal d_event_timer        : std_logic;
    signal timer_ff             : std_logic;

    signal interrupt_vector     : std_logic_vector(15 downto 0);

    signal interrupt_valid      : std_logic;
    signal interrupt_data       : std_logic_vector(7 downto 0);
    signal interrupt_ack        : std_logic;

begin

    -- Module on_chip_ram instantiation
    on_chip_ram_inst : on_chip_ram port map (
        clk                     => clk,
        resetn                  => resetn,

        wr_s_tvalid             => wr_s_tvalid,
        wr_s_taddr              => wr_s_taddr,
        wr_s_tmask              => wr_s_tmask,
        wr_s_tdata              => wr_s_tdata,

        rd_s_tvalid             => rd_s_tvalid,
        rd_s_taddr              => rd_s_taddr,
        rd_s_tuser              => x"00000000",

        rd_m_tvalid             => rd_m_tvalid,
        rd_m_tdata              => rd_m_tdata,
        rd_m_tuser              => open
    );

    -- Module cpu86 instantiation
    cpu86_inst : cpu86 port map(
        clk                     => clk,
        resetn                  => resetn,

        mem_req_m_tvalid        => mem_req_m_tvalid,
        mem_req_m_tready        => mem_req_m_tready,
        mem_req_m_tdata         => mem_req_m_tdata,

        mem_rd_s_tvalid         => mem_rd_s_tvalid,
        mem_rd_s_tdata          => mem_rd_s_tdata,

        io_req_m_tvalid         => io_req_tvalid,
        io_req_m_tready         => io_req_tready,
        io_req_m_tdata          => io_req_tdata,

        io_rd_s_tvalid          => io_rd_tvalid,
        io_rd_s_tready          => io_rd_tready,
        io_rd_s_tdata           => io_rd_tdata,

        interrupt_valid         => interrupt_valid,
        interrupt_data          => interrupt_data,
        interrupt_ack           => interrupt_ack
    );

    -- Module soc_io_interconnect instantiation
    soc_io_interconnect_inst : soc_io_interconnect port map (
        -- global singals
        clk                     => clk,
        resetn                  => resetn,
        -- cpu io
        io_req_s_tvalid         => io_req_tvalid,
        io_req_s_tready         => io_req_tready,
        io_req_s_tdata          => io_req_tdata,
        io_rd_m_tvalid          => io_rd_tvalid,
        io_rd_m_tready          => io_rd_tready,
        io_rd_m_tdata           => io_rd_tdata,
        -- pit
        pit_req_m_tvalid        => pit_req_tvalid,
        pit_req_m_tready        => pit_req_tready,
        pit_req_m_tdata         => pit_req_tdata,
        pit_rd_s_tvalid         => pit_rd_tvalid,
        pit_rd_s_tready         => pit_rd_tready,
        pit_rd_s_tdata          => pit_rd_tdata,
        -- pic
        pic_req_m_tvalid        => pic_req_tvalid,
        pic_req_m_tready        => pic_req_tready,
        pic_req_m_tdata         => pic_req_tdata,
        pic_rd_s_tvalid         => pic_rd_tvalid,
        pic_rd_s_tready         => pic_rd_tready,
        pic_rd_s_tdata          => pic_rd_tdata
    );

    -- Module pit_8254 instantiation
    pit_8254_inst : pit_8254 port map(
        clk                     => clk,
        resetn                  => resetn,

        io_req_s_tvalid         => pit_req_tvalid,
        io_req_s_tready         => pit_req_tready,
        io_req_s_tdata          => pit_req_tdata,

        io_rd_m_tvalid          => pit_rd_tvalid,
        io_rd_m_tready          => pit_rd_tready,
        io_rd_m_tdata           => pit_rd_tdata,

        event_irq               => event_irq,
        event_timer             => event_timer
    );

    -- Module pic instantiation
    pic_inst : pic port map(
        clk                     => clk,
        resetn                  => resetn,

        io_req_s_tvalid         => pic_req_tvalid,
        io_req_s_tready         => pic_req_tready,
        io_req_s_tdata          => pic_req_tdata,

        io_rd_m_tvalid          => pic_rd_tvalid,
        io_rd_m_tready          => pic_rd_tready,
        io_rd_m_tdata           => pic_rd_tdata,

        interrupt_input         => interrupt_vector,

        interrupt_valid         => interrupt_valid,
        interrupt_data          => interrupt_data,
        interrupt_ack           => interrupt_ack
    );

    -- Assigns
    mem_req_m_tready             <= '1';

    wr_s_tvalid                  <= '1' when mem_req_m_tvalid = '1' and mem_req_m_tdata(57) = '1' else '0';
    wr_s_taddr                   <= mem_req_m_tdata(ADDR_WIDTH - 1 + 32 downto 32);
    wr_s_tmask                   <= mem_req_m_tdata(61 downto 58);
    wr_s_tdata                   <= mem_req_m_tdata(31 downto 0);

    rd_s_tvalid                  <= '1' when mem_req_m_tvalid = '1' and mem_req_m_tdata(57) = '0' else '0';
    rd_s_taddr                   <= mem_req_m_tdata(ADDR_WIDTH - 1 + 32 downto 32);

    mem_rd_s_tvalid              <= rd_m_tvalid;
    mem_rd_s_tdata               <= rd_m_tdata;

    interrupt_vector(15 downto 1)<= (others => '0');
    interrupt_vector(0)          <= event_irq;


    latching_timer_ff_proc: process (clk) begin
        if rising_edge(clk) then
            if (resetn = '0') then
                d_event_timer <= '0';
                timer_ff <= '0';
            else
                d_event_timer <= event_timer;
                if (event_timer = '1' and d_event_timer = '0') then
                    timer_ff <= not timer_ff;
                end if;
            end if;
        end if;
    end process;

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
        wait for 100 ns;
        RESETN <= '1';
        wait;
    end process;

end architecture;
