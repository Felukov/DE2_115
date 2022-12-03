library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity timer is
    port (
        clk_100          : in std_logic;
        resetn_100       : in std_logic;
        timer_m_tvalid   : out std_logic
    );
end entity timer;

architecture rtl of timer is
    signal pulse_counter : natural range 0 to 99_999;
begin

    process (clk_100) begin
        if rising_edge(clk_100) then

            if resetn_100 = '0' then
                timer_m_tvalid <= '0';
                pulse_counter <= 0;
            else
                if (pulse_counter = 99_999) then
                    pulse_counter <= 0;
                else
                    pulse_counter <= pulse_counter + 1;
                end if;

                if (pulse_counter = 99_999) then
                    timer_m_tvalid <= '1';
                else
                    timer_m_tvalid <= '0';
                end if;
            end if;

        end if;
    end process;

end architecture;
