library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity fetcher_buf is
    port (
        clk                 : in std_logic;
        resetn              : in std_logic;

        u32_s_tvalid        : in std_logic;
        u32_s_tready        : out std_logic;
        u32_s_tdata         : in std_logic_vector(31 downto 0);
        u32_s_tuser         : in std_logic_vector(31 downto 0);

        u8_m_tvalid         : out std_logic;
        u8_m_tready         : in std_logic;
        u8_m_tdata          : out std_logic_vector(7 downto 0);
        u8_m_tuser          : out std_logic_vector(31 downto 0)
    );
end entity fetcher_buf;

architecture rtl of fetcher_buf is

    signal u32_tvalid       : std_logic;
    signal u32_tready       : std_logic;
    signal u32_tdata        : std_logic_vector(31 downto 0);
    signal u32_tuser        : std_logic_vector(31 downto 0);
    signal u8_tvalid        : std_logic;
    signal u8_tready        : std_logic;
    signal u8_tdata         : std_logic_vector(7 downto 0);
    signal u8_tuser         : std_logic_vector(31 downto 0);

    signal hs_cnt           : natural range 0 to 3;
    signal u32_buf_tvalid   : std_logic;
    signal u32_buf_tready   : std_logic;
    signal u32_buf_tdata    : std_logic_vector(31 downto 0);
    signal u32_buf_tuser    : std_logic_vector(29 downto 0);

begin

    u32_tvalid <= u32_s_tvalid;
    u32_s_tready <= u32_tready;
    u32_tdata <= u32_s_tdata;
    u32_tuser <= u32_s_tuser;

    u8_m_tvalid <= u8_tvalid;
    u8_tready <= u8_m_tready;
    u8_m_tdata <= u8_tdata;
    u8_m_tuser <= u8_tuser;

    u32_tready <= '1' when u32_buf_tvalid = '0' or (u32_buf_tvalid = '1' and u32_buf_tready = '1' and hs_cnt = 3) else '0';
    u32_buf_tready <= '1' when u8_tvalid = '0' or (u8_tvalid = '1' and u8_tready = '1') else '0';

    process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                u32_buf_tvalid <= '0';
                hs_cnt <= 0;
            else

                if (u32_tvalid = '1' and u32_tready = '1') then
                    u32_buf_tvalid <= '1';
                elsif (u32_buf_tvalid = '1' and u32_buf_tready = '1' and hs_cnt = 3) then
                    u32_buf_tvalid <= '0';
                end if;

                if (u32_tvalid = '1' and u32_tready = '1') then
                    hs_cnt <= to_integer(unsigned(u32_s_tuser(1 downto 0)));
                elsif (u32_buf_tvalid = '1' and u32_buf_tready = '1') then
                    hs_cnt <= (hs_cnt + 1) mod 4;
                end if;

            end if;

            if (u32_tvalid = '1' and u32_tready = '1') then
                u32_buf_tdata <= u32_tdata;
            end if;

            if (u32_tvalid = '1' and u32_tready = '1') then
                u32_buf_tuser <= u32_tuser(31 downto 2);
            end if;

        end if;
    end process;

    process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                u8_tvalid <= '0';
            else

                if (u32_buf_tvalid = '1' and u32_buf_tready = '1') then
                    u8_tvalid <= '1';
                elsif (u8_tready = '1') then
                    u8_tvalid <= '0';
                end if;

            end if;

            if (u32_buf_tvalid = '1' and u32_buf_tready = '1') then
                case hs_cnt is
                    when 0 => u8_tdata <= u32_buf_tdata(31 downto 24);
                    when 1 => u8_tdata <= u32_buf_tdata(23 downto 16);
                    when 2 => u8_tdata <= u32_buf_tdata(15 downto 8);
                    when 3 => u8_tdata <= u32_buf_tdata(7 downto 0);
                end case;
            end if;

            if (u32_buf_tvalid = '1' and u32_buf_tready = '1') then
                u8_tuser <= u32_buf_tuser & std_logic_vector(to_unsigned(hs_cnt, 2));
            end if;

        end if;
    end process;

end architecture;
