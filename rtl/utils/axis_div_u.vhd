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

        div_m_tvalid        : out std_logic;
        div_m_tready        : in std_logic;
        div_m_tdata         : out std_logic_vector(2*MAX_WIDTH-1 downto 0);
        div_m_tuser         : out std_logic_vector(USER_WIDTH-1 downto 0)
    );
end entity axis_div_u;

architecture rtl of axis_div_u is
    constant STEPS          : natural := MAX_WIDTH;

    signal input_tvalid     : std_logic;
    signal input_tready     : std_logic;
    signal input_tdata      : std_logic_vector(2*MAX_WIDTH-1 downto 0);
    signal input_tuser      : std_logic_vector(USER_WIDTH-1 downto 0);

    signal output_tvalid    : std_logic;
    signal output_tready    : std_logic;
    signal output_tdata     : std_logic_vector(2*MAX_WIDTH-1 downto 0);
    signal output_tuser     : std_logic_vector(USER_WIDTH-1 downto 0);

    signal n                : unsigned(MAX_WIDTH-1 downto 0);
    signal d                : unsigned(MAX_WIDTH-1 downto 0);
    signal q                : unsigned(MAX_WIDTH-1 downto 0);
    signal r                : unsigned(MAX_WIDTH-1 downto 0);
    signal r2               : unsigned(MAX_WIDTH-1 downto 0);

    signal i                : natural range 0 to STEPS;
    signal idx              : natural range 0 to STEPS-1;

begin

    input_tvalid <= div_s_tvalid;
    div_s_tready <= input_tready;
    input_tdata <= div_s_tdata;
    input_tuser <= div_s_tuser;

    div_m_tvalid <= output_tvalid;
    output_tready <= div_m_tready;
    div_m_tdata <= output_tdata;
    div_m_tuser <= output_tuser;

    output_tvalid <= '1' when input_tready = '0' and i = 0 else '0';
    output_tdata(2*MAX_WIDTH-1 downto MAX_WIDTH) <= std_logic_vector(q);
    output_tdata(MAX_WIDTH-1 downto 0) <= std_logic_vector(r);

    r2 <= r(MAX_WIDTH - 2 downto 0) & n(idx); -- Left-shift R by 1 bit and R(0) := N(i)

    process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                input_tready <= '1';
                i <= 0;
            else
                if input_tvalid = '1' and input_tready = '1' then
                    input_tready <= '0';
                elsif (output_tvalid = '1' and output_tready = '1') then
                    input_tready <= '1';
                end if;

                if input_tvalid = '1' and input_tready = '1' then
                    i <= STEPS;
                elsif (input_tready = '0' and i /= 0) then
                    i <= i - 1;
                end if;

            end if;

            if input_tvalid = '1' and input_tready = '1' then
                n <= unsigned(input_tdata(2*MAX_WIDTH-1 downto MAX_WIDTH));
                d <= unsigned(input_tdata(MAX_WIDTH-1 downto 0));
                r <= (others => '0') ;
                q <= (others => '0');
                idx <= STEPS-1;
            elsif (input_tready = '0' and i /= 0) then
                if (idx > 0) then
                    idx <= idx - 1;
                end if;

                if (r2 >= d) then
                    r <= r2 - d;
                    q(idx) <= '1';
                else
                    r <= r2;
                    q(idx) <= '0';
                end if;
            end if;

            if input_tvalid = '1' and input_tready = '1' then
                output_tuser <= input_tuser;
            end if;

        end if;
    end process;

end architecture;
