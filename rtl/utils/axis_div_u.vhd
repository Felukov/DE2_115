library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity axis_div_u is
    generic (
        MAX_WIDTH           : natural := 16;
        USER_WIDTH          : natural := 16
    );
    port (
        clk                 : in std_logic;
        resetn              : in std_logic;

        div_s_tvalid        : in std_logic;
        div_s_tready        : out std_logic;
        div_s_tdata         : in std_logic_vector(2*MAX_WIDTH-1 downto 0);
        div_s_tuser         : in std_logic_vector(USER_WIDTH-1 downto 0);
        div_s_tsize         : in std_logic_vector(7 downto 0);

        div_m_tvalid        : out std_logic;
        div_m_tready        : in std_logic;
        div_m_tdata         : out std_logic_vector(2*MAX_WIDTH-1 downto 0);
        div_m_tuser         : out std_logic_vector(USER_WIDTH-1 downto 0)
    );
end entity axis_div_u;

architecture rtl of axis_div_u is
    constant STEPS          : natural := MAX_WIDTH;

    signal n                : unsigned(MAX_WIDTH-1 downto 0);
    signal n_next           : unsigned(MAX_WIDTH-1 downto 0);
    signal n_idx            : unsigned(0 downto 0);
    signal d                : unsigned(MAX_WIDTH-1 downto 0);
    signal q                : unsigned(MAX_WIDTH-1 downto 0);
    signal r                : unsigned(MAX_WIDTH-1 downto 0);
    signal r2               : unsigned(MAX_WIDTH-1 downto 0);

    signal i                : natural range 0 to STEPS;
    signal idx              : natural range 0 to STEPS-1;
    signal idx_next         : natural range 0 to STEPS-1;

begin

    --div_m_tvalid <= '1' when div_s_tready = '0' and i = 0 else '0';
    div_m_tdata(2*MAX_WIDTH-1 downto MAX_WIDTH) <= std_logic_vector(q);
    div_m_tdata(MAX_WIDTH-1 downto 0) <= std_logic_vector(r);

    r2 <= r(MAX_WIDTH - 2 downto 0) & n_idx(0); -- Left-shift R by 1 bit and R(0) := N(i)
    n_next <= unsigned(div_s_tdata(2*MAX_WIDTH-1 downto MAX_WIDTH));

    process (all) begin
        idx_next <= idx;

        if div_s_tvalid = '1' and div_s_tready = '1' then
            idx_next <= to_integer(unsigned(div_s_tsize)) - 1;
        elsif (div_s_tready = '0' and i /= 0) then
            if (idx > 0) then
                idx_next <= idx - 1;
            end if;
        end if;
    end process;

    process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                div_m_tvalid <= '0';
            else
                if div_s_tready = '0' and i = 1 then
                    div_m_tvalid <= '1';
                elsif (div_m_tready = '1') then
                    div_m_tvalid <= '0';
                end if;
            end if;
        end if;
    end process;

    process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                div_s_tready <= '1';
                i <= 0;
                idx <= 0;
            else

                if div_s_tvalid = '1' and div_s_tready = '1' then
                    div_s_tready <= '0';
                elsif (div_m_tvalid = '1' and div_m_tready = '1') then
                    div_s_tready <= '1';
                end if;

                if div_s_tvalid = '1' and div_s_tready = '1' then
                    i <= to_integer(unsigned(div_s_tsize));
                elsif (div_s_tready = '0' and i /= 0) then
                    i <= i - 1;
                end if;

                idx <= idx_next;

            end if;

            if div_s_tvalid = '1' and div_s_tready = '1' then
                n <= n_next;
                d <= unsigned(div_s_tdata(MAX_WIDTH-1 downto 0));
            end if;

            if div_s_tvalid = '1' and div_s_tready = '1' then
                r <= (others => '0') ;
                q <= (others => '0');
                n_idx(0) <= n_next(to_integer(unsigned(div_s_tsize)) - 1);
            elsif (div_s_tready = '0' and i /= 0) then

                if (r2 >= d) then
                    r <= r2 - d;
                    q(idx) <= '1';
                else
                    r <= r2;
                    q(idx) <= '0';
                end if;

                n_idx(0) <= n(idx_next);
            end if;

            if div_s_tvalid = '1' and div_s_tready = '1' then
                div_m_tuser <= div_s_tuser;
            end if;

        end if;
    end process;

end architecture;
