library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity pit is
    port (
        clk             : in std_logic;
        resetn          : in std_logic;

        pit_s_tvalid    : in std_logic;
        pit_s_tdata     : in std_logic_vector(15 downto 0)

    );
end entity pit;

architecture rtl of pit is
    -- 2^32-1 / 100 MHz * 1193181,8181 Hz
    constant FREQ_OFFSET        : integer := 51246769;

    signal pit_s_a              : std_logic_vector(1 downto 0);
    signal pit_s_d              : std_logic_vector(7 downto 0);

    signal freq_counter         : std_logic_vector(31 downto 0) := (others => '0') ;
    signal timer_clk            : std_logic;
    signal d_timer_clk          : std_logic;
    signal timer_en             : std_logic;
begin

    timer_clk <= freq_counter(31);
    timer_en <= '1' when d_timer_clk = '0' and timer_clk = '1' else '0';

    process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                freq_counter <= (others => '0');
                d_timer_clk <= '0';
            else
                freq_counter <= std_logic_vector(unsigned(freq_counter) + to_unsigned(FREQ_OFFSET, 32));

                d_timer_clk <= timer_clk;
            end if;
        end if;
    end process;

end architecture;
