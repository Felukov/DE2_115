
-- Copyright (C) 2022, Konstantin Felukov
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- * Redistributions of source code must retain the above copyright notice, this
--   list of conditions and the following disclaimer.
--
-- * Redistributions in binary form must reproduce the above copyright notice,
--   this list of conditions and the following disclaimer in the documentation
--   and/or other materials provided with the distribution.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
-- FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
-- DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
-- SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
-- CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
-- OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
-- OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity video_system is
    port (
        vid_clk                     : in std_logic;
        vid_resetn                  : in std_logic;

        sdram_clk                   : in std_logic;
        sdram_resetn                : in std_logic;

        m_axis_sdram_req_tvalid     : out std_logic;
        m_axis_sdram_req_tready     : in std_logic;
        m_axis_sdram_req_tdata      : out std_logic_vector(63 downto 0);

        s_axis_sdram_res_tvalid     : in std_logic;
        s_axis_sdram_res_tdata      : in std_logic_vector(31 downto 0);

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

    constant H_MAX                  : natural := 1280; --H total period (pixels)
    constant V_MAX                  : natural := 1024; --V total period (lines)

    component video_vga_ctrl is
        port (
            vid_clk             : in std_logic;
            vid_resetn          : in std_logic;

            m_axis_vid_tvalid   : out std_logic;
            m_axis_vid_tdata    : out std_logic_vector(7 downto 0);

            VGA_BLANK_N         : out std_logic;
            VGA_SYNC_N          : out std_logic;
            VGA_HS              : out std_logic;
            VGA_VS              : out std_logic
        );
    end component video_vga_ctrl;

    component video_mda_fb is
        port (
            -- video clk
            vid_clk                         : in std_logic;
            vid_resetn                      : in std_logic;
            -- sdram clk
            sdram_clk                       : in std_logic;
            sdram_resetn                    : in std_logic;
            -- sdram data req
            m_axis_sdram_req_tvalid         : out std_logic;
            m_axis_sdram_req_tready         : in std_logic;
            m_axis_sdram_req_tdata          : out std_logic_vector(63 downto 0);
            -- data resp
            s_axis_sdram_res_tvalid         : in std_logic;
            s_axis_sdram_res_tdata          : in std_logic_vector(31 downto 0);
            -- sync signals
            s_axis_vid_sync_tvalid          : in std_logic;
            s_axis_vid_sync_tdata           : in std_logic_vector(31 downto 0);
            s_axis_vid_sync_tuser           : in std_logic_vector(7 downto 0);
            -- data out
            m_axis_vid_dout_tvalid          : out std_logic;
            m_axis_vid_dout_tdata           : out std_logic_vector(31 downto 0);
            m_axis_vid_dout_tuser           : out std_logic_vector(31 downto 0)
        );
    end component video_mda_fb;

    signal vid_ctrl_tvalid      : std_logic;
    signal vid_ctrl_tdata       : std_logic_vector(7 downto 0);

    signal vid_ctrl_blank_n     : std_logic;
    signal vid_ctrl_sync_n      : std_logic;
    signal vid_ctrl_hs          : std_logic;
    signal vid_ctrl_vs          : std_logic;

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
    VGA_BLANK_N             <= d_vid_ctrl_blank_n;
    VGA_SYNC_N              <= d_vid_ctrl_sync_n;
    VGA_HS                  <= d_vid_ctrl_hs;
    VGA_VS                  <= d_vid_ctrl_vs;
    VGA_R                   <= mda_fb_m_tdata(23 downto 16);
    VGA_G                   <= mda_fb_m_tdata(15 downto  8);
    VGA_B                   <= mda_fb_m_tdata( 7 downto  0);

    video_vga_ctrl_inst : video_vga_ctrl port map (
        vid_clk             => vid_clk,
        vid_resetn          => vid_resetn,

        m_axis_vid_tvalid   => vid_ctrl_tvalid,
        m_axis_vid_tdata    => vid_ctrl_tdata,

        VGA_BLANK_N         => vid_ctrl_blank_n,
        VGA_SYNC_N          => vid_ctrl_sync_n,
        VGA_HS              => vid_ctrl_hs,
        VGA_VS              => vid_ctrl_vs
    );

    video_mda_fb_inst : video_mda_fb port map (
        vid_clk                 => vid_clk,
        vid_resetn              => vid_resetn,

        sdram_clk               => sdram_clk,
        sdram_resetn            => sdram_resetn,

        m_axis_sdram_req_tvalid => m_axis_sdram_req_tvalid,
        m_axis_sdram_req_tready => m_axis_sdram_req_tready,
        m_axis_sdram_req_tdata  => m_axis_sdram_req_tdata,

        s_axis_sdram_res_tvalid => s_axis_sdram_res_tvalid,
        s_axis_sdram_res_tdata  => s_axis_sdram_res_tdata,

        s_axis_vid_sync_tvalid  => vid_ctrl_tvalid,
        s_axis_vid_sync_tdata   => mda_fb_s_tdata,
        s_axis_vid_sync_tuser   => vid_ctrl_tdata,

        m_axis_vid_dout_tvalid  => mda_fb_m_tvalid,
        m_axis_vid_dout_tdata   => mda_fb_m_tdata,
        m_axis_vid_dout_tuser   => open
    );

    -- assigns
    mda_fb_s_tdata <= x"0" & y_cnt & x"0" & x_cnt;

    process (vid_clk) begin
        if rising_edge(vid_clk) then
            if vid_resetn = '0' then
                d_vid_ctrl_blank_n <= '0';
                d_vid_ctrl_sync_n  <= '0';
                d_vid_ctrl_hs      <= '0';
                d_vid_ctrl_vs      <= '0';
            else
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
                x_cnt <= (others => '0');
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
                y_cnt <= (others => '0');
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
