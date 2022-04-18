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

entity soc_io_uart_tx is
    generic (
        FREQ        : integer := 100_000_000;
        RATE        : integer := 115_200
    );
    port (
        clk         : in std_logic;
        resetn      : in std_logic;

        tx_s_tvalid : in std_logic;
        tx_s_tready : out std_logic;
        tx_s_tdata  : in std_logic_vector(7 downto 0);

        tx          : out std_logic
    );
end entity soc_io_uart_tx;

architecture rtl of soc_io_uart_tx is
    constant COUNTER_MAX : positive := positive(ceil(real(FREQ/RATE)));

    type tx_state_t is (TX_IDLE, TX_START, TX_SEND, TX_STOP);

    signal tx_state     : tx_state_t;
    signal tx_cnt       : natural range 0 to COUNTER_MAX-1;
    signal tx_bit_cnt   : natural range 0 to 7;

    signal tx_tdata     : std_logic_vector(7 downto 0);
begin

    tx_handling_process: process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                tx <= '1';
                tx_state <= TX_IDLE;
                tx_cnt <= 0;
                tx_bit_cnt <= 0;
                tx_s_tready <= '1';
            else

                case tx_state is
                    when TX_IDLE =>
                        if (tx_s_tvalid = '1') then
                            tx_state <= TX_START;
                            tx_tdata <= tx_s_tdata;
                            tx_s_tready <= '0';
                            tx <= '0';
                        end if;

                    when TX_START =>
                        if (tx_cnt = COUNTER_MAX-1) then
                            tx_cnt <= 0;
                        else
                            tx_cnt <= tx_cnt + 1;
                        end if;

                        if tx_cnt = COUNTER_MAX-1 then
                            tx_state <= TX_SEND;
                            tx_tdata <= '0' & tx_tdata(7 downto 1);
                            tx <= tx_tdata(0);
                        end if;

                    when TX_SEND =>
                        if (tx_cnt = COUNTER_MAX-1) then
                            tx_cnt <= 0;
                        else
                            tx_cnt <= tx_cnt + 1;
                        end if;

                        if (tx_cnt = COUNTER_MAX-1) then
                            tx_bit_cnt <= (tx_bit_cnt + 1) mod 8;
                        end if;

                        if (tx_cnt = COUNTER_MAX-1 and tx_bit_cnt = 7) then
                            tx <= '1';
                        elsif (tx_cnt = COUNTER_MAX-1) then
                            tx <= tx_tdata(0);
                        end if;

                        if (tx_cnt = COUNTER_MAX-1) then
                            tx_tdata <= '0' & tx_tdata(7 downto 1);
                        end if;

                        if (tx_cnt = COUNTER_MAX-1 and tx_bit_cnt = 7) then
                            tx_state <= TX_STOP;
                        end if;

                    when TX_STOP =>
                        if (tx_cnt = COUNTER_MAX-1) then
                            tx_cnt <= 0;
                        else
                            tx_cnt <= tx_cnt + 1;
                        end if;

                        if (tx_cnt = COUNTER_MAX-1) then
                            tx_state <= TX_IDLE;
                            tx_s_tready <= '1';
                            tx <= '1';
                        end if;

                end case;

            end if;
        end if;
    end process;

end architecture;
