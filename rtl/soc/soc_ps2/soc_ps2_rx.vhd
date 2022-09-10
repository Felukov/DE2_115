-- Copyright (C) 2022, Konstantin Felukov
-- All rights reserved.
--
-- Copyright 2011, Kevin Lindsey
-- See LICENSE file for licensing information
--
-- Based on code from P. P. Chu, "FPGA Prototyping by VHDL Examples: Xilinx Spartan-3 Version", 2008
-- Chapters 8
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity soc_ps2_rx is
    port(
        clk          : in std_logic;
        resetn       : in std_logic;
        ps2d, ps2c   : in std_logic;
        rx_en        : in std_logic;
        rx_done_tick : out std_logic;
        dout         : out std_logic_vector(7 downto 0)
    );
end soc_ps2_rx;

architecture rtl of soc_ps2_rx is
    component signal_tap is
        port (
            acq_data_in    : in std_logic_vector(31 downto 0) := (others => 'X'); -- acq_data_in
            acq_trigger_in : in std_logic_vector(0 downto 0)  := (others => 'X'); -- acq_trigger_in
            acq_clk        : in std_logic                     := 'X';             -- clk
            storage_enable : in std_logic                     := 'X'              -- storage_enable
        );
    end component signal_tap;

    type state_t is (ST_IDLE, ST_DPS, ST_LOAD);
    signal state_reg, state_next: state_t;
    signal filter_reg, filter_next: std_logic_vector(7 downto 0);
    signal f_ps2c_reg, f_ps2c_next: std_logic;
    signal b_reg, b_next: std_logic_vector(10 downto 0);
    signal n_reg, n_next: unsigned(3 downto 0);
    signal fall_edge: std_logic;
begin
    -- filter and falling edge tick generation for ps2c
    process(clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                filter_reg <= (others => '0');
                f_ps2c_reg <= '0';
            else
                filter_reg <= filter_next;
                f_ps2c_reg <= f_ps2c_next;
            end if;
        end if;
    end process;

    filter_next <= ps2c & filter_reg(7 downto 1);

    f_ps2c_next <=
        '1' when filter_reg = "11111111" else
        '0' when filter_reg = "00000000" else
        f_ps2c_reg;

    fall_edge <= f_ps2c_reg and (not f_ps2c_next);

    -- fsmd to extract the 8-bit data

    -- registers
    process(clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                state_reg <= ST_IDLE;
                n_reg <= (others => '0');
                b_reg <= (others => '0');
            elsif clk'event and clk = '1' then
                state_reg <= state_next;
                n_reg <= n_next;
                b_reg <= b_next;
            end if;
        end if;
    end process;


    u0 : component signal_tap port map (
        acq_clk                     => clk,             -- acq_clk
        acq_data_in(31 downto 16)   => (others => '0'), -- acq_data_in
        acq_data_in(15 downto 12)   => std_logic_vector(n_reg),
        acq_data_in(11)             => ps2d,
        acq_data_in(10 downto 0)    => b_reg,
        acq_trigger_in(0)           => fall_edge,    -- acq_trigger_in
        storage_enable              => fall_edge     -- storage_enable
    );


    -- next-state logic
    process(state_reg, n_reg, b_reg, fall_edge, rx_en, ps2d) begin
        rx_done_tick <= '0';
        state_next <= state_reg;
        n_next <= n_reg;
        b_next <= b_reg;
        case state_reg is
            when ST_IDLE =>
                if fall_edge = '1' and rx_en = '1' then
                    -- shift in start bit
                    b_next <= ps2d & b_reg(10 downto 1);
                    n_next <= "1001";
                    state_next <= ST_DPS;
                end if;
            when ST_DPS =>
                -- 8 data + 1 parity + 1 stop
                if fall_edge = '1' then
                    b_next <= ps2d & b_reg(10 downto 1);
                    if n_reg = 0 then
                        state_next <= ST_LOAD;
                    else
                        n_next <= n_reg - 1;
                    end if;
                end if;
            when ST_LOAD =>
                -- 1 extra clock to complete the last shift
                state_next <= ST_IDLE;
                rx_done_tick <= '1';
        end case;
    end process;

    -- output
    dout <= b_reg(8 downto 1); -- data bits
end rtl;
