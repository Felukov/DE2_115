library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.cpu86_types.all;


entity dcache is
    port (
        clk                     : in std_logic;
        resetn                  : in std_logic;

        lsu_req_s_tvalid        : in std_logic;
        lsu_req_s_tready        : in std_logic;
        lsu_req_s_tcmd          : in std_logic;
        lsu_req_s_taddr         : in std_logic_vector(19 downto 0);
        lsu_req_s_twidth        : in std_logic;
        lsu_req_s_tdata         : in std_logic_vector(15 downto 0);

        dcache_m_tvalid         : out std_logic;
        dcache_m_tdata          : out std_logic_vector(15 downto 0)

    );
end entity dcache;

architecture rtl of dcache is

    constant CACHE_LINE_SIZE : natural := 512;
    constant CACHE_LINE_WIDTH : natural := 9;

    type tags_t is array (CACHE_LINE_SIZE-1 downto 0) of std_logic_vector(19 downto CACHE_LINE_WIDTH-1);
    type data_t is array (CACHE_LINE_SIZE-1 downto 0) of std_logic_vector(15 downto 0);

    signal d_valid              : std_logic_vector(CACHE_LINE_SIZE-1 downto 0);
    signal d_tags               : tags_t;
    signal d_data               : data_t;
    signal index                : natural range 0 to CACHE_LINE_SIZE-1;
    signal tag                  : std_logic_vector(19 downto CACHE_LINE_WIDTH-1);
begin

    dcache_m_tvalid <= '1' when lsu_req_s_tvalid = '1' and lsu_req_s_tready = '1' and d_valid(index) = '1' and d_tags(index) = tag and lsu_req_s_taddr(0) = '0' else '0';
    dcache_m_tdata <= d_data(index);

    index <= to_integer(unsigned(lsu_req_s_taddr(CACHE_LINE_WIDTH downto 1)));
    tag <= lsu_req_s_taddr(19 downto CACHE_LINE_WIDTH-1);

    write_cache_proc: process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                d_valid <= (others => '0');
            else

                if (lsu_req_s_tvalid = '1' and lsu_req_s_tready = '1' and lsu_req_s_tcmd = '1') then
                    if (lsu_req_s_twidth = '1' and lsu_req_s_taddr(0) = '0') then
                        d_valid(index) <= '1';
                    else
                        d_valid(index) <= '0';
                    end if;
                end if;

            end if;

            if (lsu_req_s_tvalid = '1' and lsu_req_s_tready = '1' and lsu_req_s_tcmd = '1' and lsu_req_s_twidth = '1' and lsu_req_s_taddr(0) = '0') then

                d_tags(index) <= tag;
                d_data(index) <= lsu_req_s_tdata;

            end if;

        end if;
    end process;

end architecture;
