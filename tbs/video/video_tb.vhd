library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use ieee.std_logic_1164.all;

entity video_tb is
end entity video_tb;

architecture rtl of video_tb is
    -- Clock period definitions
    constant CLK_PERIOD             : time := 4.629 ns;

    component video_system is
        port (
            vid_clk                     : in std_logic;
            vid_resetn                  : in std_logic;

            VGA_BLANK_N                 : out std_logic;
            VGA_SYNC_N                  : out std_logic;
            VGA_HS                      : out std_logic;
            VGA_VS                      : out std_logic;

            VGA_B                       : out std_logic_vector(7 downto 0);
            VGA_G                       : out std_logic_vector(7 downto 0);
            VGA_R                       : out std_logic_vector(7 downto 0)
        );
    end component video_system;

    component video_mda_fb_frame_gen is
        port (
            vid_clk                     : in std_logic;
            vid_resetn                  : in std_logic;

            m_axis_frame_tvalid         : out std_logic;
            m_axis_frame_tready         : in std_logic;
            m_axis_frame_tdata          : out std_logic_vector(31 downto 0);
            m_axis_frame_tuser          : out std_logic_vector(7 downto 0)
        );
    end component video_mda_fb_frame_gen;

    component video_mda_fb_scaler is
        port (
            vid_clk                 : in std_logic;
            vid_resetn              : in std_logic;

            s_axis_frame_tvalid     : in std_logic;
            s_axis_frame_tready     : out std_logic;
            s_axis_frame_tdata      : in std_logic_vector(31 downto 0);
            s_axis_frame_tuser      : in std_logic_vector(7 downto 0);

            m_axis_frame_tvalid     : out std_logic;
            m_axis_frame_tready     : in std_logic;
            m_axis_frame_tdata      : out std_logic_vector(31 downto 0);
            m_axis_frame_tuser      : out std_logic_vector(7 downto 0)
        );
    end component video_mda_fb_scaler;

    -- Clock period definitions

    signal VID_CLK                      : std_logic := '0';
    signal VID_RESETN                   : std_logic := '0';

    signal VGA_BLANK_N                  : std_logic;
    signal VGA_SYNC_N                   : std_logic;
    signal VGA_HS                       : std_logic;
    signal VGA_VS                       : std_logic;

    signal VGA_B                        : std_logic_vector(7 downto 0);
    signal VGA_G                        : std_logic_vector(7 downto 0);
    signal VGA_R                        : std_logic_vector(7 downto 0);

    -- signal src_frame_tvalid             : std_logic;
    -- signal src_frame_tready             : std_logic;
    -- signal src_frame_tdata              : std_logic_vector(31 downto 0);
    -- signal src_frame_tuser              : std_logic_vector(7 downto 0);

    -- signal frame_2x_tvalid              : std_logic;
    -- signal frame_2x_tready              : std_logic;
    -- signal frame_2x_tdata               : std_logic_vector(31 downto 0);
    -- signal frame_2x_tuser               : std_logic_vector(7 downto 0);

begin

    video_system_inst : video_system port map (
        vid_clk             => VID_CLK,
        vid_resetn          => VID_RESETN,
        VGA_BLANK_N         => VGA_BLANK_N,
        VGA_SYNC_N          => VGA_SYNC_N,
        VGA_HS              => VGA_HS,
        VGA_VS              => VGA_VS,
        VGA_R               => VGA_R,
        VGA_G               => VGA_G,
        VGA_B               => VGA_B
    );

    -- video_mda_fb_frame_gen_inst : video_mda_fb_frame_gen port map (
    --     vid_clk             => VID_CLK,
    --     vid_resetn          => VID_RESETN,

    --     m_axis_frame_tvalid => src_frame_tvalid,
    --     m_axis_frame_tready => src_frame_tready,
    --     m_axis_frame_tdata  => src_frame_tdata,
    --     m_axis_frame_tuser  => src_frame_tuser
    -- );

    -- video_mda_fb_scaler_inst : video_mda_fb_scaler port map (
    --     vid_clk             => VID_CLK,
    --     vid_resetn          => VID_RESETN,

    --     s_axis_frame_tvalid => src_frame_tvalid,
    --     s_axis_frame_tready => src_frame_tready,
    --     s_axis_frame_tdata  => src_frame_tdata,
    --     s_axis_frame_tuser  => src_frame_tuser,

    --     m_axis_frame_tvalid => frame_2x_tvalid,
    --     m_axis_frame_tready => frame_2x_tready,
    --     m_axis_frame_tdata  => frame_2x_tdata,
    --     m_axis_frame_tuser  => frame_2x_tuser
    -- );

    -- frame_2x_tready <= '1';

    -- Clock process
    clk_process : process begin
    	VID_CLK <= '0';
    	wait for CLK_PERIOD/2;
    	VID_CLK <= '1';
    	wait for CLK_PERIOD/2;
    end process;

    -- Reset process
    reset_process : process begin
        VID_RESETN <= '0';
        wait for 10 * CLK_PERIOD;
        VID_RESETN <= '1';
        wait;
    end process;


end architecture;