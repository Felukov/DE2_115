library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity sdram_tester is
    port (
        clk             : in std_logic;
        resetn          : in std_logic;

        cmd_s_tvalid    : in std_logic;
        cmd_s_tdata     : in std_logic;

        cmd_m_tvalid    : out std_logic;
        cmd_m_tready    : in std_logic;
        cmd_m_tdata     : out std_logic_vector(63 downto 0)
    );
end entity sdram_tester;

architecture rtl of sdram_tester is

    signal cmd_tvalid   : std_logic;
    signal cmd_tready   : std_logic;
    signal cmd_tdata    : std_logic_vector(63 downto 0);

    signal cnt          : natural range 0 to 127;
    signal addr         : natural range 0 to 63;

begin

    cmd_m_tvalid <= cmd_tvalid;
    cmd_tready <= cmd_m_tready;
    cmd_m_tdata <= cmd_tdata;

    cmd_tdata(63 downto 58) <= (others => '0');
    cmd_tdata(57) <= '1' when cnt <= 63 else '0';
    cmd_tdata(56 downto 32) <= std_logic_vector(to_unsigned(addr, 25));
    cmd_tdata(31 downto 0) <= std_logic_vector(to_unsigned(cnt, 32));

    process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                cnt <= 0;
                cmd_tvalid <= '0';
            else

                if (cmd_s_tvalid = '1' and cmd_s_tdata = '1') then
                    cmd_tvalid <= '1';
                elsif (cmd_tvalid = '1' and cmd_tready = '1' and cnt = 127) then
                    cmd_tvalid <= '0';
                end if;

                if (cmd_tvalid = '1' and cmd_tready = '1') then
                    cnt <= cnt + 1;
                    addr <= (addr + 1) mod 64;
                end if;

            end if;

        end if;
    end process;

end architecture;
