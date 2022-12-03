library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity video_system_timer is
    port (
        clk_108         : in std_logic;
        resetn_108      : in std_logic;
        timer_pulse     : out std_logic
    );
end entity video_system_timer;

architecture rtl of video_system_timer is
    signal pulse_counter : natural range 0 to 108_000;
begin

    process (clk_108) begin
        if rising_edge(clk_108) then

            if resetn_108 = '0' then
                timer_pulse <= '0';
                pulse_counter <= 0;
            else
                if (pulse_counter = 108_000) then
                    pulse_counter <= 0;
                else
                    pulse_counter <= pulse_counter + 1;
                end if;

                if (pulse_counter = 108_000) then
                    timer_pulse <= '1';
                else
                    timer_pulse <= '0';
                end if;
            end if;

        end if;
    end process;

end architecture;
