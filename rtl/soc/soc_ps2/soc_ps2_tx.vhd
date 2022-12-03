-- Copyright (C) 2022, Konstantin Felukov
-- All rights reserved.
--
-- Copyright 2011, Kevin Lindsey
-- See LICENSE file for licensing information
--
-- Based on code from P. P. Chu, "FPGA Prototyping by VHDL Examples: Xilinx Spartan-3 Version", 2008
-- Chapters 9
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity soc_ps2_tx is
    port(
        clk          : in std_logic;
        resetn       : in std_logic;
        din          : in std_logic_vector(7 downto 0);
        wr_ps2       : in std_logic;
        ps2d, ps2c   : inout std_logic;
        tx_idle      : out std_logic;
        tx_done_tick : out std_logic
    );
end soc_ps2_tx;

architecture rtl of soc_ps2_tx is
    type state_t is (ST_IDLE, ST_RTS, ST_START, ST_DATA, ST_STOP);
    signal state_reg, state_next: state_t;
    signal filter_reg, filter_next: std_logic_vector(7 downto 0);
    signal f_ps2c_reg, f_ps2c_next: std_logic;
    signal fall_edge: std_logic;
    signal b_reg, b_next: std_logic_vector(8 downto 0);
    signal c_reg, c_next: unsigned(13 downto 0);
    signal n_reg, n_next: unsigned(3 downto 0);
    signal par: std_logic;
    signal ps2c_out, ps2d_out: std_logic;
    signal tri_c, tri_d: std_logic;
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

    -- fsmd
    -- registers
    process(clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                state_reg <= ST_IDLE;
                c_reg <= (others => '0');
                n_reg <= (others => '0');
                b_reg <= (others => '0');
            else
                state_reg <= state_next;
                c_reg <= c_next;
                n_reg <= n_next;
                b_reg <= b_next;
            end if;
        end if;
    end process;

    -- odd parity bit
    par <= not (din(7) xor din(6) xor din(5) xor din(4) xor din(3) xor din(2) xor din(1) xor din(0));

    -- fsmd next-state logic and data path logic
    process(state_reg, n_reg, b_reg, c_reg, wr_ps2, din, par, fall_edge) begin
        state_next <= state_reg;
        c_next <= c_reg;
        n_next <= n_reg;
        b_next <= b_reg;
        tx_done_tick <= '0';
        ps2c_out <= '1';
        ps2d_out <= '1';
        tri_c <= '0';
        tri_d <= '0';
        tx_idle <= '0';
        case state_reg is
            when ST_IDLE =>
                tx_idle <= '1';
                if wr_ps2 = '1' then
                    b_next <= par & din;
                    c_next <= (others => '1'); -- 2^13 - 1
                    state_next <= ST_RTS;
                end if;
            when ST_RTS =>
                ps2c_out <= '0';
                tri_c <= '1';
                c_next <= c_reg - 1;
                if c_reg = 0 then
                    state_next <= ST_START;
                end if;
            when ST_START =>
                -- assert start bit
                ps2d_out <= '0';
                tri_d <= '1';
                if fall_edge = '1' then
                    n_next <= "1000";
                    state_next <= ST_DATA;
                end if;
            when ST_DATA =>
                ps2d_out <= b_reg(0);
                tri_d <= '1';
                if fall_edge = '1' then
                    b_next <= '0' & b_reg(8 downto 1);
                    if n_reg = 0 then
                        state_next <= ST_STOP;
                    else
                        n_next <= n_reg - 1;
                    end if;
                end if;
            when ST_STOP =>
                if fall_edge = '1' then
                    state_next <= ST_IDLE;
                    tx_done_tick <= '1';
                end if;
            end case;
    end process;

    -- tri-state buffers
    ps2c <= ps2c_out when tri_c = '1' else 'Z';
    ps2d <= ps2d_out when tri_d = '1' else 'Z';
end rtl;
