library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity cpu_reg is
    generic (
        DATA_WIDTH      : integer := 16
    );
    port (
        clk             : in std_logic;
        resetn          : in std_logic;

        wr_s_tvalid     : in std_logic;
        wr_s_tdata      : in std_logic_vector(DATA_WIDTH-1 downto 0);
        wr_s_tmask      : in std_logic_vector(1 downto 0);
        wr_s_tkeep_lock : in std_logic;

        lock_s_tvalid   : in std_logic;
        unlk_s_tvalid   : in std_logic;

        reg_m_tvalid    : out std_logic;
        reg_m_tdata     : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity cpu_reg;

architecture rtl of cpu_reg is

    signal reg_tvalid   : std_logic;
    signal reg_tdata    : std_logic_vector(DATA_WIDTH-1 downto 0);

begin

    reg_m_tvalid <= '1' when (wr_s_tvalid = '1' and wr_s_tkeep_lock = '0') or reg_tvalid = '1' else '0';

    forming_reg_data_proc: process (all) begin

        if (wr_s_tvalid = '1') then
            case wr_s_tmask is
                when "11" => reg_m_tdata <= wr_s_tdata;
                when "01" => reg_m_tdata <= reg_tdata(DATA_WIDTH-1 downto DATA_WIDTH/2) & wr_s_tdata(DATA_WIDTH/2-1 downto 0);
                when "10" => reg_m_tdata <= wr_s_tdata(DATA_WIDTH/2-1 downto 0) & reg_tdata(DATA_WIDTH/2-1 downto 0);
                when others => null;
            end case;
        else
            reg_m_tdata <= reg_tdata;
        end if;

    end process;

    update_reg_proc: process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                reg_tvalid <= '1';
                reg_tdata <= (others => '0');
            else

                if (lock_s_tvalid = '1') then
                    reg_tvalid <= '0';
                elsif ((wr_s_tvalid = '1' and wr_s_tkeep_lock = '0') or unlk_s_tvalid = '1') then
                    reg_tvalid <= '1';
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