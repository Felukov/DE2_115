library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

entity axis_bram is
    generic (
        ADDR_WIDTH          : natural := 24;
        DATA_WIDTH          : natural := 32;
        USER_WIDTH          : natural := 32;
        REGISTER_OUTPUT     : std_logic := '1'
    );
    port (
        clk                 : in std_logic;
        resetn              : in std_logic;

        s_axis_wr_tvalid    : in std_logic;
        s_axis_wr_taddr     : in std_logic_vector(ADDR_WIDTH-1 downto 0);
        s_axis_wr_tdata     : in std_logic_vector(DATA_WIDTH-1 downto 0);

        s_axis_rd_tvalid    : in std_logic;
        s_axis_rd_tready    : out std_logic;
        s_axis_rd_taddr     : in std_logic_vector(ADDR_WIDTH-1 downto 0);
        s_axis_rd_tuser     : in std_logic_vector(USER_WIDTH-1 downto 0);

        m_axis_res_tvalid   : out std_logic;
        m_axis_res_tready   : in std_logic;
        m_axis_res_tdata    : out std_logic_vector(DATA_WIDTH-1 downto 0);
        m_axis_res_tuser    : out std_logic_vector(USER_WIDTH-1 downto 0)
    );
end entity axis_bram;

architecture rtl of axis_bram is
    signal wr_tvalid        : std_logic;
    signal wr_taddr         : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal wr_tdata         : std_logic_vector(DATA_WIDTH-1 downto 0);

    signal rd_tvalid        : std_logic;
    signal rd_tready        : std_logic;
    signal rd_taddr         : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal rd_tuser         : std_logic_vector(USER_WIDTH-1 downto 0);

    signal res_tvalid       : std_logic;
    signal res_tready       : std_logic;
    signal res_tdata        : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal res_tuser        : std_logic_vector(USER_WIDTH-1 downto 0);

    signal bram_tvalid      : std_logic;
    signal bram_tready      : std_logic;
    signal bram_tdata       : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal bram_tuser       : std_logic_vector(USER_WIDTH-1 downto 0);
    signal bram_bypass_en   : std_logic;
    signal bram_bypass_data : std_logic_vector(DATA_WIDTH-1 downto 0);

    signal addressstall_b   : std_logic;
begin

    wr_tvalid         <= s_axis_wr_tvalid;
    wr_taddr          <= s_axis_wr_taddr;
    wr_tdata          <= s_axis_wr_tdata;

    rd_tvalid         <= s_axis_rd_tvalid;
    s_axis_rd_tready  <= rd_tready;
    rd_taddr          <= s_axis_rd_taddr;
    rd_tuser          <= s_axis_rd_tuser;

    m_axis_res_tvalid <= res_tvalid;
    res_tready        <= m_axis_res_tready;
    m_axis_res_tdata  <= res_tdata;
    m_axis_res_tuser  <= res_tuser;

    addressstall_b <= '1' when bram_tvalid = '1' and bram_tready = '0' else '0';

    altsyncram_inst : altsyncram generic map (
        -- GLOBAL PARAMETERS
        OPERATION_MODE                     => "DUAL_PORT",
        READ_DURING_WRITE_MODE_MIXED_PORTS => "OLD_DATA",
        INTENDED_DEVICE_FAMILY             => "Cyclone IV E",
        RAM_BLOCK_TYPE                     => "M9K",
        POWER_UP_UNINITIALIZED             => "FALSE",
        BYTE_SIZE                          => 8,
        -- PORT A PARAMETERS
        WIDTH_A                            => DATA_WIDTH,
        WIDTHAD_A                          => ADDR_WIDTH,
        NUMWORDS_A                         => 2**ADDR_WIDTH,
        OUTDATA_REG_A                      => "UNREGISTERED",
        ADDRESS_ACLR_A                     => "NONE",
        OUTDATA_ACLR_A                     => "NONE",
        INDATA_ACLR_A                      => "NONE",
        WRCONTROL_ACLR_A                   => "NONE",
        BYTEENA_ACLR_A                     => "NONE",
        WIDTH_BYTEENA_A                    => 1,
        -- PORT B PARAMETERS
        WIDTH_B                            => DATA_WIDTH,
        WIDTHAD_B                          => ADDR_WIDTH,
        NUMWORDS_B                         => 2**ADDR_WIDTH,
        RDCONTROL_REG_B                    => "CLOCK0",
        ADDRESS_REG_B                      => "CLOCK0",
        OUTDATA_REG_B                      => "UNREGISTERED",
        OUTDATA_ACLR_B                     => "NONE",
        RDCONTROL_ACLR_B                   => "NONE",
        INDATA_REG_B                       => "CLOCK0",
        WRCONTROL_WRADDRESS_REG_B          => "CLOCK0",
        BYTEENA_REG_B                      => "CLOCK0",
        INDATA_ACLR_B                      => "NONE",
        WRCONTROL_ACLR_B                   => "NONE",
        ADDRESS_ACLR_B                     => "NONE",
        BYTEENA_ACLR_B                     => "NONE",
        WIDTH_BYTEENA_B                    => 1
    ) port map (
        clock0          => clk,
        clock1          => '1',
        clocken0        => '1',
        clocken1        => '1',
        clocken2        => '1',
        clocken3        => '1',
        aclr0           => '0',
        aclr1           => '0',
        address_a       => wr_taddr,
        addressstall_a  => '0',
        rden_a          => '0',
        wren_a          => wr_tvalid,
        byteena_a       => (others => '1'),
        data_a          => wr_tdata,
        q_a             => open,
        address_b       => rd_taddr,
        addressstall_b  => addressstall_b,
        rden_b          => rd_tvalid,
        wren_b          => '0',
        byteena_b       => (others => '1'),
        data_b          => (others => '0'),
        q_b             => bram_tdata,
        eccstatus       => open
    );


    rd_tready <= '1' when bram_tvalid = '0' or (bram_tvalid = '1' and bram_tready = '1') else '0';

    process (clk) begin
        if rising_edge(clk) then
            -- control
            if resetn = '0' then
                bram_tvalid <= '0';
                bram_bypass_en <= '0';
            else
                if (rd_tvalid = '1' and rd_tready = '1') then
                    bram_tvalid <= '1';
                elsif (bram_tready = '1') then
                    bram_tvalid <= '0';
                end if;

                if (rd_tvalid = '1' and rd_tready = '1') then
                    if (wr_tvalid = '1' and wr_taddr = rd_taddr) then
                        bram_bypass_en <= '1';
                    else
                        bram_bypass_en <= '0';
                    end if;
                end if;
            end if;
            -- datapath
            if (rd_tvalid = '1' and rd_tready = '1') then
                bram_bypass_data <= wr_tdata;
            end if;
            if (rd_tvalid = '1' and rd_tready = '1') then
                bram_tuser <= rd_tuser;
            end if;
        end if;
    end process;

    register_output_gen : if (REGISTER_OUTPUT = '1') generate
        bram_tready <= '1' when res_tvalid = '0' or (res_tvalid = '1' and res_tready = '1') else '0';

        process (clk) begin
            if rising_edge(clk) then
                if resetn = '0' then
                    res_tvalid <= '0';
                else
                    if (bram_tvalid = '1' and bram_tready = '1') then
                        res_tvalid <= '1';
                    elsif (res_tready = '1') then
                        res_tvalid <= '0';
                    end if;
                end if;

                if (bram_tvalid = '1' and bram_tready = '1') then
                    if (bram_bypass_en = '1') then
                        res_tdata <= bram_bypass_data;
                    else
                        res_tdata <= bram_tdata;
                    end if;
                    res_tuser <= bram_tuser;
                end if;
            end if;
        end process;

    end generate;

    async_output_gen: if (REGISTER_OUTPUT = '0') generate

        res_tvalid <= bram_tvalid;
        bram_tready <= res_tready;
        res_tdata <= bram_bypass_data when bram_bypass_en = '1' else bram_tdata;
        res_tuser <= bram_tuser;

    end generate;

end architecture;
