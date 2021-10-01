library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.cpu86_types.all;
use ieee.math_real.all;

entity lsu is
    port (
        clk                     : in std_logic;
        resetn                  : in std_logic;

        lsu_req_s_tvalid        : in std_logic;
        lsu_req_s_tready        : out std_logic;
        lsu_req_s_tcmd          : in std_logic;
        lsu_req_s_taddr         : in std_logic_vector(19 downto 0);
        lsu_req_s_twidth        : in std_logic;
        lsu_req_s_tdata         : in std_logic_vector(15 downto 0);

        dcache_s_tvalid         : in std_logic;
        dcache_s_tdata          : in std_logic_vector(15 downto 0);

        mem_req_m_tvalid        : out std_logic;
        mem_req_m_tready        : in std_logic;
        mem_req_m_tdata         : out std_logic_vector(63 downto 0);

        mem_rd_s_tvalid         : in std_logic;
        mem_rd_s_tdata          : in std_logic_vector(31 downto 0);

        lsu_rd_m_tvalid         : out std_logic;
        lsu_rd_m_tready         : in std_logic;
        lsu_rd_m_tdata          : out std_logic_vector(15 downto 0)
    );
end entity lsu;

architecture rtl of lsu is

    component axis_fifo is
        generic (
            FIFO_DEPTH          : natural := 2**8;
            FIFO_WIDTH          : natural := 128;
            REGISTER_OUTPUT     : std_logic := '1'
        );
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            fifo_s_tvalid       : in std_logic;
            fifo_s_tready       : out std_logic;
            fifo_s_tdata        : in std_logic_vector(FIFO_WIDTH-1 downto 0);

            fifo_m_tvalid       : out std_logic;
            fifo_m_tready       : in std_logic;
            fifo_m_tdata        : out std_logic_vector(FIFO_WIDTH-1 downto 0)
        );
    end component;

    component lsu_fifo is
        generic (
            FIFO_DEPTH          : natural := 2**8;
            FIFO_WIDTH          : natural := 128;
            ADDR_WIDTH          : natural := 2;
            REGISTER_OUTPUT     : std_logic := '1'
        );
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            add_s_tvalid        : in std_logic;
            add_s_tready        : out std_logic;
            add_s_thit          : in std_logic;
            add_s_tdata         : in std_logic_vector(FIFO_WIDTH-1 downto 0);
            add_s_taddr         : out std_logic_vector(ADDR_WIDTH-1 downto 0);

            upd_s_tvalid        : in std_logic;
            upd_s_taddr         : in std_logic_vector(ADDR_WIDTH-1 downto 0);
            upd_s_tdata         : in std_logic_vector(FIFO_WIDTH-1 downto 0);

            fifo_m_tvalid       : out std_logic;
            fifo_m_tready       : in std_logic;
            fifo_m_tdata        : out std_logic_vector(FIFO_WIDTH-1 downto 0)
        );
    end component lsu_fifo;

    signal lsu_req_tvalid       : std_logic;
    signal lsu_req_tready       : std_logic;

    signal req_buf_tvalid       : std_logic;
    signal req_buf_tready       : std_logic;
    signal req_buf_tcmd         : std_logic;
    signal req_buf_twidth       : std_logic;
    signal req_buf_taddr        : std_logic_vector(17 downto 0);
    signal req_buf_tdata        : std_logic_vector(7 downto 0);
    signal req_buf_tupd_addr    : std_logic_vector(3 downto 0);

    signal mem_req_tvalid       : std_logic;
    signal mem_req_tready       : std_logic;
    signal mem_req_tlast        : std_logic;
    signal mem_req_tcmd         : std_logic;
    signal mem_req_taddr        : std_logic_vector(17 downto 0);
    signal mem_req_tmask        : std_logic_vector(3 downto 0);
    signal mem_req_tdata        : std_logic_vector(31 downto 0) := (others => '0');

    signal add_s_tvalid         : std_logic;
    signal add_s_tready         : std_logic;
    signal add_s_taddr          : std_logic_vector(3 downto 0);
    signal add_s_tdata          : std_logic_vector(3 downto 0);

    signal fifo_0_s_tvalid      : std_logic;
    signal fifo_0_s_tready      : std_logic;
    signal fifo_0_s_tdata       : std_logic_vector(7 downto 0);
    signal fifo_0_m_tvalid      : std_logic;
    signal fifo_0_m_tready      : std_logic;
    signal fifo_0_m_tdata       : std_logic_vector(7 downto 0);

    signal upd_s_tvalid         : std_logic;
    signal upd_s_tdata          : std_logic_vector(15 downto 0);
    signal upd_s_taddr          : std_logic_vector(3 downto 0);

    signal fifo_1_m_tvalid      : std_logic;
    signal fifo_1_m_tready      : std_logic;
    signal fifo_1_m_tdata       : std_logic_vector(15 downto 0);

begin

    axis_fifo_inst : axis_fifo generic map (
        FIFO_DEPTH              => 4,
        FIFO_WIDTH              => 8,
        REGISTER_OUTPUT         => '0'
    ) port map (
        clk                     => clk,
        resetn                  => resetn,

        fifo_s_tvalid           => fifo_0_s_tvalid,
        fifo_s_tready           => fifo_0_s_tready,
        fifo_s_tdata            => fifo_0_s_tdata,

        fifo_m_tvalid           => fifo_0_m_tvalid,
        fifo_m_tready           => fifo_0_m_tready,
        fifo_m_tdata            => fifo_0_m_tdata
    );

    lsu_fifo_inst : lsu_fifo generic map (
        FIFO_DEPTH              => 16,
        FIFO_WIDTH              => 16,
        ADDR_WIDTH              => 4,
        REGISTER_OUTPUT         => '1'
    ) port map (
        clk                     => clk,
        resetn                  => resetn,

        add_s_tvalid            => add_s_tvalid,
        add_s_tready            => add_s_tready,
        add_s_thit              => dcache_s_tvalid,
        add_s_tdata             => dcache_s_tdata,
        add_s_taddr             => add_s_taddr,

        upd_s_tvalid            => upd_s_tvalid,
        upd_s_tdata             => upd_s_tdata,
        upd_s_taddr             => upd_s_taddr,

        fifo_m_tvalid           => fifo_1_m_tvalid,
        fifo_m_tready           => fifo_1_m_tready,
        fifo_m_tdata            => fifo_1_m_tdata
    );

    lsu_rd_m_tvalid <= fifo_1_m_tvalid;
    fifo_1_m_tready <= lsu_rd_m_tready;
    lsu_rd_m_tdata <= fifo_1_m_tdata;

    lsu_req_tvalid <= lsu_req_s_tvalid;
    lsu_req_s_tready <= lsu_req_tready;

    mem_req_m_tvalid <= mem_req_tvalid;
    mem_req_tready <= mem_req_m_tready;

    mem_req_m_tdata(31 downto 0) <= mem_req_tdata;
    mem_req_m_tdata(56 downto 32) <= "0000000" & mem_req_taddr;
    mem_req_m_tdata(57) <= mem_req_tcmd;
    mem_req_m_tdata(61 downto 58) <= mem_req_tmask;
    mem_req_m_tdata(63 downto 62) <= "00";

    add_s_tvalid <= '1' when lsu_req_s_tvalid = '1' and lsu_req_s_tready = '1' and lsu_req_s_tcmd = '0' else '0';

    lsu_req_tready <= '1' when req_buf_tvalid = '0' and (mem_req_tvalid = '0' or (mem_req_tvalid = '1' and mem_req_tready = '1')) and add_s_tready = '1' else '0';
    req_buf_tready <= '1' when (mem_req_tvalid = '0' or (mem_req_tvalid = '1' and mem_req_tready = '1')) else '0';
    fifo_0_m_tready <= mem_rd_s_tvalid;

    buffering_req_proc: process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                req_buf_tvalid <= '0';
            else

                if (lsu_req_tvalid = '1' and lsu_req_tready = '1' and (dcache_s_tvalid = '0' or lsu_req_s_tcmd = '1')) then
                    if (lsu_req_s_taddr(1 downto 0) = "11" and lsu_req_s_twidth = '1') then
                        req_buf_tvalid <= '1';
                    else
                        req_buf_tvalid <= '0';
                    end if;
                elsif req_buf_tready = '1' then
                    req_buf_tvalid <= '0';
                end if;

            end if;

            if (lsu_req_tvalid = '1' and lsu_req_tready = '1') then
                req_buf_tcmd <= lsu_req_s_tcmd;
                req_buf_twidth <= lsu_req_s_twidth;
                req_buf_taddr <= std_logic_vector(unsigned(lsu_req_s_taddr(19 downto 3)) + to_unsigned(1,18));
                req_buf_tdata <= lsu_req_s_tdata(7 downto 0);
                req_buf_tupd_addr <= add_s_taddr;
            end if;

        end if;
    end process;

    forming_mem_req_proc: process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                mem_req_tvalid <= '0';
                mem_req_tlast <= '0';
            else

                if (req_buf_tvalid = '1' and req_buf_tready = '1') or (lsu_req_tvalid = '1' and lsu_req_tready = '1' and (dcache_s_tvalid = '0' or lsu_req_s_tcmd = '1')) then
                    mem_req_tvalid <= '1';
                elsif (mem_req_tready = '1') then
                    mem_req_tvalid <= '0';
                end if;

                if (req_buf_tvalid = '1' and req_buf_tready = '1') then
                    mem_req_tlast <= '1';
                elsif (lsu_req_tvalid = '1' and lsu_req_tready = '1') then
                    if (lsu_req_s_taddr(1 downto 0) = "11" and lsu_req_s_twidth = '1') then
                        mem_req_tlast <= '0';
                    else
                        mem_req_tlast <= '1';
                    end if;
                end if;

            end if;

            if (req_buf_tvalid = '1' and req_buf_tready = '1') then
                mem_req_tcmd <= req_buf_tcmd;
                mem_req_taddr <= req_buf_taddr;
                mem_req_tmask <= "0111";
                mem_req_tdata(31 downto 24) <= req_buf_tdata;
            elsif (lsu_req_tvalid = '1' and lsu_req_tready = '1') then
                mem_req_tcmd <= lsu_req_s_tcmd;
                mem_req_taddr <= lsu_req_s_taddr(19 downto 2);

                if (lsu_req_s_twidth = '0') then
                    case lsu_req_s_taddr(1 downto 0) is
                        when "00" => mem_req_tmask <= "0111";
                        when "01" => mem_req_tmask <= "1011";
                        when "10" => mem_req_tmask <= "1101";
                        when "11" => mem_req_tmask <= "1110";
                        when others => null;
                    end case;
                else
                    case lsu_req_s_taddr(1 downto 0) is
                        when "00" => mem_req_tmask <= "0011";
                        when "01" => mem_req_tmask <= "1001";
                        when "10" => mem_req_tmask <= "1100";
                        when "11" => mem_req_tmask <= "1110";
                        when others => null;
                    end case;
                end if;

                if (lsu_req_s_twidth = '0') then
                    case lsu_req_s_taddr(1 downto 0) is
                        when "00" => mem_req_tdata(31 downto 24) <= lsu_req_s_tdata(7 downto 0);
                        when "01" => mem_req_tdata(23 downto 16) <= lsu_req_s_tdata(7 downto 0);
                        when "10" => mem_req_tdata(15 downto  8) <= lsu_req_s_tdata(7 downto 0);
                        when "11" => mem_req_tdata( 7 downto  0) <= lsu_req_s_tdata(7 downto 0);
                        when others => null;
                    end case;
                else
                    case lsu_req_s_taddr(1 downto 0) is
                        when "00" => mem_req_tdata(31 downto 16) <= lsu_req_s_tdata;
                        when "01" => mem_req_tdata(23 downto  8) <= lsu_req_s_tdata;
                        when "10" => mem_req_tdata(15 downto  0) <= lsu_req_s_tdata;
                        when "11" => mem_req_tdata( 7 downto  0) <= lsu_req_s_tdata(15 downto 8);
                        when others => null;
                    end case;
                end if;

            end if;

        end if;

    end process;

    loading_wait_response_fifo_proc: process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                fifo_0_s_tvalid <= '0';
            else

                if (req_buf_tvalid = '1' and req_buf_tready = '1') then
                    if (req_buf_tcmd = '0') then
                        fifo_0_s_tvalid <= '1';
                    else
                        fifo_0_s_tvalid <= '0';
                    end if;
                elsif (lsu_req_tvalid = '1' and lsu_req_tready = '1' and dcache_s_tvalid = '0') then
                    if (lsu_req_s_tcmd = '0') then
                        fifo_0_s_tvalid <= '1';
                    else
                        fifo_0_s_tvalid <= '0';
                    end if;
                elsif (fifo_0_s_tready = '1') then
                    fifo_0_s_tvalid <= '0';
                end if;

            end if;

            if (req_buf_tvalid = '1' and req_buf_tready = '1') then
                if (req_buf_tcmd = '0') then
                    fifo_0_s_tdata <= req_buf_tupd_addr & '1' & req_buf_twidth & req_buf_taddr(1 downto 0);
                end if;
            elsif (lsu_req_tvalid = '1' and lsu_req_tready = '1') then
                if (lsu_req_s_tcmd = '0') then
                    fifo_0_s_tdata <= add_s_taddr & '0' & lsu_req_s_twidth & lsu_req_s_taddr(1 downto 0);
                end if;
            end if;

        end if;
    end process;

    parsing_results_to_fifo_proc: process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                upd_s_tvalid <= '0';
            else

                if (mem_rd_s_tvalid = '1') then
                    if (fifo_0_m_tdata(3) = '0' and (fifo_0_m_tdata(2) = '0' or (fifo_0_m_tdata(2) = '1' and fifo_0_m_tdata(1 downto 0) /= "11"))) then
                        upd_s_tvalid <= '1';
                    elsif (fifo_0_m_tdata(3) = '1') then
                        upd_s_tvalid <= '1';
                    else
                        upd_s_tvalid <= '0';
                    end if;
                else
                    upd_s_tvalid <= '0';
                end if;

            end if;

            if (mem_rd_s_tvalid = '1') then
                if (fifo_0_m_tdata(3) = '0') then
                    if (fifo_0_m_tdata(2) = '0') then
                        -- load byte
                        case fifo_0_m_tdata(1 downto 0) is
                            when "00" => upd_s_tdata <= x"00" & mem_rd_s_tdata(31 downto 24);
                            when "01" => upd_s_tdata <= x"00" & mem_rd_s_tdata(23 downto 16);
                            when "10" => upd_s_tdata <= x"00" & mem_rd_s_tdata(15 downto  8);
                            when "11" => upd_s_tdata <= x"00" & mem_rd_s_tdata( 7 downto  0);
                            when others => null;
                        end case;
                    else
                        -- load word
                        case fifo_0_m_tdata(1 downto 0) is
                            when "00" => upd_s_tdata <= mem_rd_s_tdata(31 downto 16);
                            when "01" => upd_s_tdata <= mem_rd_s_tdata(23 downto  8);
                            when "10" => upd_s_tdata <= mem_rd_s_tdata(15 downto  0);
                            when "11" => upd_s_tdata(15 downto 8) <= mem_rd_s_tdata( 7 downto  0);
                            when others => null;
                        end case;
                    end if;
                elsif (fifo_0_m_tdata(3) = '1') then
                    -- load tail of the word
                    upd_s_tdata(7 downto 0) <= mem_rd_s_tdata(15 downto 8);
                end if;

                upd_s_taddr <= fifo_0_m_tdata(7 downto 4);

            end if;


        end if;
    end process;

end architecture;
