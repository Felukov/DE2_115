----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:    18:52:59 04/04/2021
-- Design Name:
-- Module Name:    axis_reg - Behavioral
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity axis_reg is
    generic (
        DATA_WIDTH          : natural := 32
    );
    port (
        clk                 : in std_logic;
        resetn              : in std_logic;
        in_s_tvalid         : in std_logic;
        in_s_tready         : out std_logic;
        in_s_tdata          : in std_logic_vector (DATA_WIDTH-1 downto 0);
        out_m_tvalid        : out std_logic;
        out_m_tready        : in std_logic;
        out_m_tdata         : out std_logic_vector (DATA_WIDTH-1 downto 0)
    );
end axis_reg;

architecture rtl of axis_reg is

    signal in_tvalid        : std_logic;
    signal in_tready        : std_logic;
    signal in_tdata         : std_logic_vector (DATA_WIDTH-1 downto 0);

    signal tmp_tvalid       : std_logic;
    signal tmp_tready       : std_logic;
    signal tmp_tdata        : std_logic_vector(DATA_WIDTH-1 downto 0);

    signal out_tvalid       : std_logic;
    signal out_tready       : std_logic;
    signal out_tdata        : std_logic_vector(DATA_WIDTH-1 downto 0);

begin
    in_tvalid <= in_s_tvalid;
    in_s_tready <= in_tready;
    in_tdata <= in_s_tdata;

    out_m_tvalid <= out_tvalid;
    out_tready <= out_m_tready;
    out_m_tdata <= out_tdata;

    in_tready <= '1' when tmp_tvalid = '0' else '0';
    tmp_tready <= '1' when out_tvalid = '0' or (out_tvalid = '1' and out_tready = '1') else '0';

    tmp_buffer_process : process(clk) begin
        if (rising_edge(clk)) then

            if (resetn = '0') then
                tmp_tvalid <= '0';
            else
                if in_tvalid = '1' and out_tvalid = '1' and out_tready = '0' then
                    tmp_tvalid <= '1';
                elsif (tmp_tready = '1') then
                    tmp_tvalid <= '0';
                end if;
            end if;

            if in_tvalid = '1' and tmp_tvalid = '0' then
                tmp_tdata <= in_tdata;
            end if;

        end if;
    end process;

    out_process : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                out_tvalid <= '0';
            else
                if (in_tvalid = '1' or tmp_tvalid = '1') then
                    out_tvalid <= '1';
                elsif (out_tready = '1') then
                    out_tvalid <= '0';
                end if;
            end if;

            if (out_tvalid = '0' or (out_tvalid = '1' and out_tready = '1')) then

                if (tmp_tvalid = '1') then
                    out_tdata <= tmp_tdata;
                elsif (in_tvalid = '1') then
                    out_tdata <= in_tdata;
                end if;

            end if;

        end if;
    end process;

end rtl;
