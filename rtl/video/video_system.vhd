library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity video_system is
    port (
        vid_clk                     : in std_logic;
        vid_resetn                  : in std_logic;

        VGA_CLK                     : out std_logic;
        VGA_BLANK_N                 : out std_logic;
        VGA_SYNC_N                  : out std_logic;
        VGA_HS                      : out std_logic;
        VGA_VS                      : out std_logic;

        VGA_B                       : out std_logic_vector(7 downto 0);
        VGA_G                       : out std_logic_vector(7 downto 0);
        VGA_R                       : out std_logic_vector(7 downto 0)
    );
end entity video_system;

architecture rtl of video_system is

    constant H_MAX          : natural := 1280; --H total period (pixels)
    constant V_MAX          : natural := 1024; --V total period (lines)

    component video_vga_ctrl is
        port (
            vid_clk                 : in std_logic;
            vid_resetn              : in std_logic;

            m_axis_vid_tvalid       : out std_logic;
            m_axis_vid_tdata        : out std_logic_vector(7 downto 0);

            VGA_CLK                 : out std_logic;
            VGA_BLANK_N             : out std_logic;
            VGA_SYNC_N              : out std_logic;
            VGA_HS                  : out std_logic;
            VGA_VS                  : out std_logic
        );
    end component video_vga_ctrl;

    component video_mda_fb is
        port (
            vid_clk             : in std_logic;
            vid_resetn          : in std_logic;

            s_axis_vid_tvalid   : in std_logic;
            s_axis_vid_tdata    : in std_logic_vector(31 downto 0);
            s_axis_vid_tuser    : in std_logic_vector(7 downto 0);

            m_axis_vid_tvalid   : out std_logic;
            m_axis_vid_tdata    : out std_logic_vector(31 downto 0);
            m_axis_vid_tuser    : out std_logic_vector(31 downto 0)
        );
    end component video_mda_fb;

    signal vid_ctrl_tvalid      : std_logic;
    signal vid_ctrl_tdata       : std_logic_vector(7 downto 0);

    signal vid_ctrl_clk         : std_logic;
    signal vid_ctrl_blank_n     : std_logic;
    signal vid_ctrl_sync_n      : std_logic;
    signal vid_ctrl_hs          : std_logic;
    signal vid_ctrl_vs          : std_logic;

    signal d_vid_ctrl_clk       : std_logic;
    signal d_vid_ctrl_blank_n   : std_logic;
    signal d_vid_ctrl_sync_n    : std_logic;
    signal d_vid_ctrl_hs        : std_logic;
    signal d_vid_ctrl_vs        : std_logic;

    signal mda_fb_s_tdata       : std_logic_vector(31 downto 0);
    signal mda_fb_m_tvalid      : std_logic;
    signal mda_fb_m_tdata       : std_logic_vector(31 downto 0);

    signal x_cnt                : std_logic_vector(11 downto 0);
    signal y_cnt                : std_logic_vector(11 downto 0);

begin

    -- i/o assigns
    VGA_CLK                 <= d_vid_ctrl_clk;
    VGA_BLANK_N             <= d_vid_ctrl_blank_n;
    VGA_SYNC_N              <= d_vid_ctrl_sync_n;
    VGA_HS                  <= d_vid_ctrl_hs;
    VGA_VS                  <= d_vid_ctrl_vs;
    -- VGA_R                   <= x"00";
    -- VGA_G                   <= x"00";
    -- VGA_B                   <= x"FF";
    VGA_R                   <= mda_fb_m_tdata(23 downto 16);
    VGA_G                   <= mda_fb_m_tdata(15 downto  8);
    VGA_B                   <= mda_fb_m_tdata( 7 downto  0);

    video_vga_ctrl_inst : video_vga_ctrl port map (
        vid_clk             => vid_clk,
        vid_resetn          => vid_resetn,

        m_axis_vid_tvalid   => vid_ctrl_tvalid,
        m_axis_vid_tdata    => vid_ctrl_tdata,

        VGA_CLK             => vid_ctrl_clk,
        VGA_BLANK_N         => vid_ctrl_blank_n,
        VGA_SYNC_N          => vid_ctrl_sync_n,
        VGA_HS              => vid_ctrl_hs,
        VGA_VS              => vid_ctrl_vs
    );

    video_mda_fb_inst : video_mda_fb port map (
        vid_clk             => vid_clk,
        vid_resetn          => vid_resetn,

        s_axis_vid_tvalid   => vid_ctrl_tvalid,
        s_axis_vid_tdata    => mda_fb_s_tdata,
        s_axis_vid_tuser    => vid_ctrl_tdata,

        m_axis_vid_tvalid   => mda_fb_m_tvalid,
        m_axis_vid_tdata    => mda_fb_m_tdata,
        m_axis_vid_tuser    => open
    );

    -- assigns
    mda_fb_s_tdata <= x"0" & y_cnt & x"0" & x_cnt;

    process (vid_clk) begin
        if rising_edge(vid_clk) then
            if vid_resetn = '0' then
                d_vid_ctrl_clk     <= '0';
                d_vid_ctrl_blank_n <= '0';
                d_vid_ctrl_sync_n  <= '0';
                d_vid_ctrl_hs      <= '0';
                d_vid_ctrl_vs      <= '0';
            else
                d_vid_ctrl_clk     <= vid_ctrl_clk;
                d_vid_ctrl_blank_n <= vid_ctrl_blank_n;
                d_vid_ctrl_sync_n  <= vid_ctrl_sync_n;
                d_vid_ctrl_hs      <= vid_ctrl_hs;
                d_vid_ctrl_vs      <= vid_ctrl_vs;
            end if;
        end if;
    end process;

    -- Horizontal counter
    process (vid_clk) begin
        if (rising_edge(vid_clk)) then
            if (vid_resetn = '0') then
                x_cnt <= (others =>'0');
            else
                if (vid_ctrl_tvalid = '1' and vid_ctrl_tdata(0) = '0') then
                    if (x_cnt = (H_MAX - 1)) then
                        x_cnt <= (others =>'0');
                    else
                        x_cnt <= x_cnt + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Vertical counter
    process (vid_clk) begin
        if (rising_edge(vid_clk)) then
            if (vid_resetn = '0') then
                y_cnt <= (others =>'0');
            else
                if (vid_ctrl_tvalid = '1' and vid_ctrl_tdata(0) = '0') then
                    if ((x_cnt = (H_MAX - 1)) and (y_cnt = (V_MAX - 1))) then
                        y_cnt <= (others =>'0');
                    elsif (x_cnt = (H_MAX - 1)) then
                        y_cnt <= y_cnt + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

end architecture;
