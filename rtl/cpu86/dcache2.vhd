library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.cpu86_types.all;

entity dcache2 is
    port (
        clk                     : in std_logic;
        resetn                  : in std_logic;

        dcache_s_tvalid         : in std_logic;
        dcache_s_tready         : out std_logic;
        dcache_s_tcmd           : in std_logic;
        dcache_s_taddr          : in std_logic_vector(19 downto 0);
        dcache_s_twidth         : in std_logic;
        dcache_s_tdata          : in std_logic_vector(15 downto 0);

        dcache_m_tvalid         : out std_logic;
        dcache_m_tready         : in std_logic;
        dcache_m_tcmd           : out std_logic;
        dcache_m_taddr          : out std_logic_vector(19 downto 0);
        dcache_m_twidth         : out std_logic;
        dcache_m_tdata          : out std_logic_vector(15 downto 0);
        dcache_m_thit           : out std_logic;
        dcache_m_tcache         : out std_logic_vector(15 downto 0)
    );
end entity dcache2;

architecture rtl of dcache2 is

    constant CACHE_LINE_SIZE : natural := 512;
    constant CACHE_LINE_WIDTH : natural := 9;

    type tags_t is array (CACHE_LINE_SIZE-1 downto 0) of std_logic_vector(19 downto CACHE_LINE_WIDTH-1);
    type data_t is array (CACHE_LINE_SIZE-1 downto 0) of std_logic_vector(15 downto 0);

    signal d_valid              : std_logic_vector(CACHE_LINE_SIZE-1 downto 0);
    signal d_tags               : tags_t;
    signal d_data               : data_t;
    signal s_index              : natural range 0 to CACHE_LINE_SIZE-1;
    signal s_tag                : std_logic_vector(19 downto CACHE_LINE_WIDTH-1);

    signal m_index              : natural range 0 to CACHE_LINE_SIZE-1;
    signal m_tag                : std_logic_vector(19 downto CACHE_LINE_WIDTH-1);

    signal dcache_tag           : std_logic_vector(19 downto CACHE_LINE_WIDTH-1);
    signal dcache_valid         : std_logic;
begin

    dcache_s_tready <= '1' when dcache_m_tvalid = '0' or (dcache_m_tvalid = '1' and dcache_m_tready = '1') else '0';

    dcache_m_thit <= '1' when dcache_valid = '1' and dcache_tag = m_tag and dcache_m_taddr(0) = '0' else '0';

    s_index <= to_integer(unsigned(dcache_s_taddr(CACHE_LINE_WIDTH downto 1)));
    s_tag <= dcache_s_taddr(19 downto CACHE_LINE_WIDTH-1);

    m_index <= to_integer(unsigned(dcache_m_taddr(CACHE_LINE_WIDTH downto 1)));
    m_tag <= dcache_m_taddr(19 downto CACHE_LINE_WIDTH-1);

    write_cache_proc: process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                d_valid <= (others => '0');
            else

                if (dcache_s_tvalid = '1' and dcache_s_tready = '1' and dcache_s_tcmd = '1') then
                    if (dcache_s_twidth = '1' and dcache_s_taddr(0) = '0') then
                        d_valid(s_index) <= '1';
                    else
                        d_valid(s_index) <= '0';
                    end if;
                end if;

            end if;

            if (dcache_s_tvalid = '1' and dcache_s_tready = '1' and dcache_s_tcmd = '1' and dcache_s_twidth = '1' and dcache_s_taddr(0) = '0') then

                d_tags(s_index) <= s_tag;
                d_data(s_index) <= dcache_s_tdata;

            end if;

        end if;
    end process;

    redirect_request_proc: process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                dcache_m_tvalid <= '0';
            else

                if (dcache_s_tvalid = '1' and dcache_s_tready = '1') then
                    dcache_m_tvalid <= '1';
                elsif (dcache_m_tready = '1') then
                    dcache_m_tvalid <= '0';
                end if;

            end if;

            if (dcache_s_tvalid = '1' and dcache_s_tready = '1') then
                dcache_tag <= d_tags(s_index);
                dcache_valid <= d_valid(s_index);
            end if;

            if (dcache_s_tvalid = '1' and dcache_s_tready = '1') then
                dcache_m_tcmd <= dcache_s_tcmd;
                dcache_m_taddr <= dcache_s_taddr;
                dcache_m_twidth <= dcache_s_twidth;
                dcache_m_tdata <= dcache_s_tdata;
                dcache_m_tcache <= d_data(s_index);
            end if;

        end if;
    end process;

end architecture;
