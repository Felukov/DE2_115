-- Copyright (C) 2022, Konstantin Felukov
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- * Redistributions of source code must retain the above copyright notice, this
--   list of conditions and the following disclaimer.
--
-- * Redistributions in binary form must reproduce the above copyright notice,
--   this list of conditions and the following disclaimer in the documentation
--   and/or other materials provided with the distribution.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
-- FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
-- DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
-- SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
-- CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
-- OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
-- OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity soc_io_uart_rx is
    generic (
        FREQ        : integer := 100_000_000;
        RATE        : integer := 115_200
    );
    port (
        clk         : in std_logic;
        resetn      : in std_logic;

        rx_m_tvalid : out std_logic;
        rx_m_tdata  : out std_logic_vector(7 downto 0);

        rx          : in std_logic
    );

end entity soc_io_uart_rx;

architecture rtl of soc_io_uart_rx is
    constant COUNTER_MAX : positive := positive(ceil(real(FREQ/RATE)));

    type rx_state_t is (RX_IDLE, RX_START, RX_RECEIVE, RX_STOP);

    signal rx_state     : rx_state_t;
    signal rx_cnt       : natural range 0 to COUNTER_MAX-1;
    signal rx_bit_cnt   : natural range 0 to 7;
    signal rx_tdata     : std_logic_vector(7 downto 0);
    signal rx_tvalid    : std_logic;
begin

    rx_m_tvalid <= rx_tvalid;
    rx_m_tdata <= rx_tdata;

    rx_handling_process: process (clk) begin

        if rising_edge(clk) then
            if resetn = '0' then
                rx_state <= RX_IDLE;
                rx_cnt <= 0;
                rx_bit_cnt <= 0;
                rx_tvalid <= '0';
                rx_tdata <= (others => '0');
            else
                case rx_state is
                    when RX_START =>
                        if rx = '0' and rx_cnt = COUNTER_MAX/2-1 then
                            rx_cnt <= 0;
                        elsif rx = '0' then
                            rx_cnt <= rx_cnt + 1;
                        else
                            rx_cnt <= 0;
                        end if;

                        if rx = '0' and rx_cnt = COUNTER_MAX/2-1 then
                            rx_state <= RX_RECEIVE;
                        elsif (rx = '1') then
                            rx_state <= RX_IDLE;
                        end if;

                        if rx = '0' and rx_cnt = COUNTER_MAX/2-1 then
                            rx_tdata <= (others => '0');
                        end if;

                    when RX_RECEIVE =>
                        if (rx_cnt = COUNTER_MAX-1) then
                            rx_cnt <= 0;
                        else
                            rx_cnt <= rx_cnt + 1;
                        end if;

                        if (rx_cnt = COUNTER_MAX-1) then
                            rx_bit_cnt <= (rx_bit_cnt + 1) mod 8;
                        end if;

                        if (rx_cnt = COUNTER_MAX-1) then
                            rx_tdata <= rx & rx_tdata(7 downto 1);
                        end if;

                        if (rx_cnt = COUNTER_MAX-1 and rx_bit_cnt = 7) then
                            rx_state <= RX_STOP;
                        end if;

                    when RX_STOP =>
                        if (rx_cnt = COUNTER_MAX-1) then
                            rx_cnt <= 0;
                        else
                            rx_cnt <= rx_cnt + 1;
                        end if;

                        if (rx_cnt = COUNTER_MAX-1) then
                            rx_tvalid <= '1';
                        end if;

                        if (rx_cnt = COUNTER_MAX-1) then
                            rx_state <= RX_IDLE;
                        end if;

                    when others =>
                        rx_tvalid <= '0';
                        if (rx = '0') then
                            rx_state <= RX_START;
                        end if;

                end case;
            end if;
        end if;

    end process;

end architecture;
