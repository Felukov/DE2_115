library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity vga_ctrl is
    port (
        clk         : in std_logic;
        resetn      : in std_logic;

        VGA_CLK     : out std_logic;
        VGA_BLANK_N : out std_logic;
        VGA_SYNC_N  : out std_logic;
        VGA_HS      : out std_logic;
        VGA_VS      : out std_logic
    );
end entity vga_ctrl;

architecture rtl of vga_ctrl is
    constant FRAME_WIDTH    : natural := 640;
    constant FRAME_HEIGHT   : natural := 480;

    constant H_FP           : natural := 16; --H front porch width (pixels)
    constant H_PW           : natural := 96; --H sync pulse width (pixels)
    constant H_MAX          : natural := 800; --H total period (pixels)

    constant V_FP           : natural := 10; --V front porch width (lines)
    constant V_PW           : natural := 2; --V sync pulse width (lines)
    constant V_MAX          : natural := 525; --V total period (lines)

    constant H_POL          : std_logic := '0';
    constant V_POL          : std_logic := '0';
    -- constant FRAME_WIDTH : natural := 1280;
    -- constant FRAME_HEIGHT : natural := 800;

    -- constant H_FP : natural := 64; --H front porch width (pixels)
    -- constant H_PW : natural := 136; --H sync pulse width (pixels)
    -- constant H_MAX : natural := 1680; --H total period (pixels)

    -- constant V_FP : natural := 1; --V front porch width (lines)
    -- constant V_PW : natural := 3; --V sync pulse width (lines)
    -- constant V_MAX : natural := 828; --V total period (lines)

    -- constant H_POL : std_logic := '0';
    -- constant V_POL : std_logic := '0';

    signal active           : std_logic;
    -- Horizontal and Vertical counters
    signal h_cntr_reg       : std_logic_vector(11 downto 0) := (others =>'0');
    signal v_cntr_reg       : std_logic_vector(11 downto 0) := (others =>'0');
    -- Horizontal and Vertical Sync
    signal h_sync_reg       : std_logic := not(H_POL);
    signal v_sync_reg       : std_logic := not(V_POL);

begin

    VGA_BLANK_N <= '1' when v_sync_reg = '1' and h_sync_reg = '1' else '0';
    VGA_SYNC_N <= '0';
    VGA_HS <= h_sync_reg;
    VGA_VS <= v_sync_reg;

    process (clk) begin
        if (rising_edge(clk)) then
            if (resetn = '0') then
                VGA_CLK <= '0';
            else
                VGA_CLK <= not VGA_CLK;
            end if;
        end if;
    end process;

    -- Horizontal counter
    process (clk) begin
        if (rising_edge(clk)) then
            if (VGA_CLK = '1') then
                if (h_cntr_reg = (H_MAX - 1)) then
                    h_cntr_reg <= (others =>'0');
                else
                    h_cntr_reg <= h_cntr_reg + 1;
                end if;
            end if;
        end if;
    end process;

    -- Vertical counter
    process (clk) begin
        if (rising_edge(clk)) then
            if (VGA_CLK = '1') then
                if ((h_cntr_reg = (H_MAX - 1)) and (v_cntr_reg = (V_MAX - 1))) then
                    v_cntr_reg <= (others =>'0');
                elsif (h_cntr_reg = (H_MAX - 1)) then
                    v_cntr_reg <= v_cntr_reg + 1;
                end if;
            end if;
        end if;
    end process;

    -- Horizontal sync
    process (clk) begin
        if (rising_edge(clk)) then
            if (VGA_CLK = '1') then
                if (h_cntr_reg >= (H_FP + FRAME_WIDTH - 1)) and (h_cntr_reg < (H_FP + FRAME_WIDTH + H_PW - 1)) then
                    h_sync_reg <= H_POL;
                else
                    h_sync_reg <= not(H_POL);
                end if;
            end if;
        end if;
    end process;

    -- Vertical sync
    process (clk) begin
        if (rising_edge(clk)) then
            if (VGA_CLK = '1') then
                if (v_cntr_reg >= (V_FP + FRAME_HEIGHT - 1)) and (v_cntr_reg < (V_FP + FRAME_HEIGHT + V_PW - 1)) then
                    v_sync_reg <= V_POL;
                else
                    v_sync_reg <= not(V_POL);
                end if;
            end if;
        end if;
    end process;

end architecture;
