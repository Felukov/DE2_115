library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity cpu_flags is
    generic (
        DATA_WIDTH      : integer := 16
    );
    port (
        clk             : in std_logic;
        resetn          : in std_logic;

        wr_s_tvalid     : in std_logic;
        wr_s_tdata      : in std_logic_vector(DATA_WIDTH-1 downto 0);
        wr_s_tmask      : in std_logic_vector(1 downto 0);

        lock_s_tvalid   : in std_logic;
        unlk_s_tvalid   : in std_logic;

        reg_m_tvalid    : out std_logic;
        reg_m_tdata     : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity cpu_flags;

architecture rtl of cpu_flags is

    signal reg_tvalid   : std_logic;
    signal reg_tdata    : std_logic_vector(DATA_WIDTH-1 downto 0);

begin

    reg_m_tvalid <= '1' when reg_tvalid = '1' else '0';

    reg_m_tdata <= reg_tdata;

    update_reg_proc: process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                reg_tvalid <= '1';
                reg_tdata <= x"0202";
            else

                if (wr_s_tvalid = '1' or unlk_s_tvalid = '1') then
                    reg_tvalid <= '1';
                elsif (lock_s_tvalid = '1') then
                    reg_tvalid <= '0';
                end if;

                if (wr_s_tvalid = '1') then
                    case wr_s_tmask is
                        when "11" => reg_tdata <= wr_s_tdata;
                        when "01" => reg_tdata(DATA_WIDTH/2-1 downto 0) <= wr_s_tdata(DATA_WIDTH/2-1 downto 0);
                        when "10" => reg_tdata(DATA_WIDTH-1 downto DATA_WIDTH/2) <= wr_s_tdata(DATA_WIDTH/2-1 downto 0);
                        when others => null;
                    end case;
                end if;

            end if;
        end if;
    end process;

end architecture;