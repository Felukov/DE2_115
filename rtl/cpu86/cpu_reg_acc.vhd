library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity cpu_reg_acc is
    generic (
        DATA_WIDTH          : integer := 16
    );
    port (
        clk                 : in std_logic;
        resetn              : in std_logic;

        wr_s_tvalid         : in std_logic;
        wr_s_tdata          : in std_logic_vector(DATA_WIDTH-1 downto 0);
        wr_s_tmask          : in std_logic_vector(1 downto 0);

        inc_s_tvalid        : in std_logic;
        inc_s_tdata         : in std_logic_vector(15 downto 0);
        inc_s_tkeep_lock    : in std_logic;

        lock_s_tvalid       : in std_logic;
        unlk_s_tvalid       : in std_logic;

        reg_m_tvalid        : out std_logic;
        reg_m_tdata         : out std_logic_vector(DATA_WIDTH-1 downto 0);
        reg_m_tdata_next    : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity cpu_reg_acc;

architecture rtl of cpu_reg_acc is

    signal reg_tvalid       : std_logic;
    signal reg_tdata_next   : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal reg_tdata        : std_logic_vector(DATA_WIDTH-1 downto 0);

begin

    reg_m_tvalid <= reg_tvalid;
    reg_m_tdata <= reg_tdata;
    reg_m_tdata_next <= reg_tdata_next;

    update_reg_next_proc : process (all) begin
        reg_tdata_next <= reg_tdata;
        if (inc_s_tvalid = '1') then
            reg_tdata_next <= std_logic_vector(unsigned(reg_tdata) + unsigned(inc_s_tdata));
        elsif (wr_s_tvalid = '1') then
            case wr_s_tmask is
                when "11" => reg_tdata_next <= wr_s_tdata;
                when "01" => reg_tdata_next(DATA_WIDTH/2-1 downto 0) <= wr_s_tdata(DATA_WIDTH/2-1 downto 0);
                when "10" => reg_tdata_next(DATA_WIDTH-1 downto DATA_WIDTH/2) <= wr_s_tdata(DATA_WIDTH/2-1 downto 0);
                when others => null;
            end case;
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
                elsif (wr_s_tvalid = '1' or unlk_s_tvalid = '1' or (inc_s_tvalid = '1' and inc_s_tkeep_lock = '0')) then
                    reg_tvalid <= '1';
                end if;

                reg_tdata <= reg_tdata_next;

            end if;
        end if;
    end process;

end architecture;
