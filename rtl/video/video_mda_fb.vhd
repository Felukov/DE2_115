
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

---
-- #Short Description
--
-- MDA produces an 80x25 text screen.
-- The memory storage scheme is that two bytes of video RAM are used for each character (80*25*2 = 4000, neatly fitting in the 4k RAM on the card).
-- The first byte is the character code, and the second gives the attribute.

-- The attribute bytes mostly behave like a bitmap:

-- Bits 0-2: 1 => underline, other values => no underline.
-- Bit 3: High intensity.
-- Bit 7: Blink
-- but there are eight exceptions:

-- Attributes 00h, 08h, 80h and 88h display as black space.
-- Attribute 70h displays as black on green.
-- Attribute 78h displays as dark green on green.
-- Attribute F0h displays as a blinking version of 70h (if blinking is enabled); as black on bright green otherwise.
-- Attribute F8h displays as a blinking version of 78h (if blinking is enabled); as dark green on bright green otherwise.

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity video_mda_fb is
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
        m_axis_vid_dout_tuser           : out std_logic_vector(31 downto 0);

        event_blink_switch              : in std_logic
    );
end entity video_mda_fb;

architecture rtl of video_mda_fb is

    component video_mda_fb_frame_gen is
        port (
            -- clock, reset
            vid_clk                     : in std_logic;
            vid_resetn                  : in std_logic;
            -- data req
            m_axis_vid_mem_req_tvalid   : out std_logic;
            m_axis_vid_mem_req_tdata    : out std_logic_vector(31 downto 0);
            -- data resp
            s_axis_vid_mem_res_tvalid   : in std_logic;
            s_axis_vid_mem_res_tdata    : in std_logic_vector(15 downto 0);
            -- video frame
            m_axis_frame_tvalid         : out std_logic;
            m_axis_frame_tready         : in std_logic;
            m_axis_frame_tdata          : out std_logic_vector(31 downto 0);
            m_axis_frame_tuser          : out std_logic_vector(7 downto 0)
        );
    end component video_mda_fb_frame_gen;

    component video_mda_fb_scaler is
        port (
            vid_clk                     : in std_logic;
            vid_resetn                  : in std_logic;

            s_axis_frame_tvalid         : in std_logic;
            s_axis_frame_tready         : out std_logic;
            s_axis_frame_tdata          : in std_logic_vector(31 downto 0);
            s_axis_frame_tuser          : in std_logic_vector(7 downto 0);

            m_axis_frame_tvalid         : out std_logic;
            m_axis_frame_tready         : in std_logic;
            m_axis_frame_tdata          : out std_logic_vector(31 downto 0);
            m_axis_frame_tuser          : out std_logic_vector(7 downto 0)
        );
    end component video_mda_fb_scaler;

    component video_mda_sdram_ctrl is
        port (
            vid_clk                     : in std_logic;
            vid_resetn                  : in std_logic;

            sdram_clk                   : in std_logic;
            sdram_resetn                : in std_logic;

            s_axis_vid_mem_req_tvalid   : in std_logic;
            s_axis_vid_mem_req_tdata    : in std_logic_vector(31 downto 0);

            s_axis_sdram_res_tvalid     : in std_logic;
            s_axis_sdram_res_tdata      : in std_logic_vector(31 downto 0);

            m_axis_sdram_req_tvalid     : out std_logic;
            m_axis_sdram_req_tready     : in std_logic;
            m_axis_sdram_req_tdata      : out std_logic_vector(63 downto 0);

            m_axis_vid_mem_res_tvalid   : out std_logic;
            m_axis_vid_mem_res_tdata    : out std_logic_vector(15 downto 0)
        );
    end component video_mda_sdram_ctrl;

    component axis_reg is
        generic (
            DATA_WIDTH                  : natural := 32
        );
        port (
            clk                         : in std_logic;
            resetn                      : in std_logic;
            in_s_tvalid                 : in std_logic;
            in_s_tready                 : out std_logic;
            in_s_tdata                  : in std_logic_vector (DATA_WIDTH-1 downto 0);
            out_m_tvalid                : out std_logic;
            out_m_tready                : in std_logic;
            out_m_tdata                 : out std_logic_vector (DATA_WIDTH-1 downto 0)
        );
    end component axis_reg;

    signal vid_mem_req_tvalid           : std_logic;
    signal vid_mem_req_tdata            : std_logic_vector(31 downto 0);
    signal vid_mem_res_tvalid           : std_logic;
    signal vid_mem_res_tdata            : std_logic_vector(15 downto 0);

    signal din_tvalid                   : std_logic;
    signal din_x                        : std_logic_vector(11 downto 0);
    signal din_y                        : std_logic_vector(11 downto 0);
    signal dout_tvalid                  : std_logic;
    signal dout_tdata                   : std_logic_vector(31 downto 0);
    signal dout_tuser                   : std_logic_vector(31 downto 0);
    signal dout_r                       : std_logic_vector(7 downto 0);
    signal dout_g                       : std_logic_vector(7 downto 0);
    signal dout_b                       : std_logic_vector(7 downto 0);
    signal blank_mask                   : std_logic_vector(7 downto 0);

    signal src_frame_tvalid             : std_logic;
    signal src_frame_tready             : std_logic;
    signal src_frame_tdata              : std_logic_vector(31 downto 0);
    signal src_frame_tuser              : std_logic_vector(7 downto 0);

    signal buf_frame_s_tdata            : std_logic_vector(39 downto 0);

    signal buf_frame_m_tvalid           : std_logic;
    signal buf_frame_m_tready           : std_logic;
    signal buf_frame_m_tdata            : std_logic_vector(39 downto 0);

    signal frame_2x_tvalid              : std_logic;
    signal frame_2x_tready              : std_logic;
    signal frame_2x_tdata               : std_logic_vector(31 downto 0);
    signal frame_2x_tuser               : std_logic_vector(7 downto 0);
    signal frame_2x_tready_mask         : std_logic;

    signal dark_filler                  : std_logic_vector(7 downto 0);
    signal dark_filler_inv              : std_logic_vector(7 downto 0);
    signal bright_filler                : std_logic_vector(7 downto 0);
    signal bright_filler_inv            : std_logic_vector(7 downto 0);

    signal blink_on                     : std_logic;

    function comb_and (a, b : std_logic_vector) return std_logic_vector is
        variable o : std_logic_vector(a'range);
    begin
        for i in o'range loop
            o := a and b;
        end loop;
        return o;
    end function;

    function comb_not (a : std_logic_vector) return std_logic_vector is
        variable o : std_logic_vector(a'range);
    begin
        for i in o'range loop
            o := not a;
        end loop;
        return o;
    end function;

begin
    -- i/o assigns
    din_tvalid                      <= s_axis_vid_sync_tvalid;
    din_x                           <= s_axis_vid_sync_tdata(11 downto 0);
    din_y                           <= s_axis_vid_sync_tdata(27 downto 16);

    m_axis_vid_dout_tvalid          <= dout_tvalid;
    m_axis_vid_dout_tdata           <= dout_tdata;
    m_axis_vid_dout_tuser           <= dout_tuser;

    -- module video_mda_fb_frame_gen instantiation
    video_mda_fb_frame_gen_inst : video_mda_fb_frame_gen port map (
        vid_clk                     => vid_clk,
        vid_resetn                  => vid_resetn,

        m_axis_vid_mem_req_tvalid   => vid_mem_req_tvalid,
        m_axis_vid_mem_req_tdata    => vid_mem_req_tdata,

        s_axis_vid_mem_res_tvalid   => vid_mem_res_tvalid,
        s_axis_vid_mem_res_tdata    => vid_mem_res_tdata,

        m_axis_frame_tvalid         => src_frame_tvalid,
        m_axis_frame_tready         => src_frame_tready,
        m_axis_frame_tdata          => src_frame_tdata,
        m_axis_frame_tuser          => src_frame_tuser
    );

    -- module video_mda_sdram_ctrl instantiation
    video_mda_sdram_ctrl_inst : video_mda_sdram_ctrl port map (
        vid_clk                     => vid_clk,
        vid_resetn                  => vid_resetn,

        sdram_clk                   => sdram_clk,
        sdram_resetn                => sdram_resetn,

        s_axis_vid_mem_req_tvalid   => vid_mem_req_tvalid,
        s_axis_vid_mem_req_tdata    => vid_mem_req_tdata,

        m_axis_sdram_req_tvalid     => m_axis_sdram_req_tvalid,
        m_axis_sdram_req_tready     => m_axis_sdram_req_tready,
        m_axis_sdram_req_tdata      => m_axis_sdram_req_tdata,

        s_axis_sdram_res_tvalid     => s_axis_sdram_res_tvalid,
        s_axis_sdram_res_tdata      => s_axis_sdram_res_tdata,

        m_axis_vid_mem_res_tvalid   => vid_mem_res_tvalid,
        m_axis_vid_mem_res_tdata    => vid_mem_res_tdata
    );

    -- module axis_reg instantiation
    axis_reg_data_inst : axis_reg generic map (
        DATA_WIDTH                  => 40
    ) port map (
        clk                         => vid_clk,
        resetn                      => vid_resetn,

        in_s_tvalid                 => src_frame_tvalid,
        in_s_tready                 => src_frame_tready,
        in_s_tdata                  => buf_frame_s_tdata,

        out_m_tvalid                => buf_frame_m_tvalid,
        out_m_tready                => buf_frame_m_tready,
        out_m_tdata                 => buf_frame_m_tdata
    );

    -- module video_mda_fb_scaler instantiation
    video_mda_fb_scaler_inst : video_mda_fb_scaler port map (
        vid_clk                     => vid_clk,
        vid_resetn                  => vid_resetn,

        s_axis_frame_tvalid         => buf_frame_m_tvalid,
        s_axis_frame_tready         => buf_frame_m_tready,
        s_axis_frame_tdata          => buf_frame_m_tdata(31 downto  0),
        s_axis_frame_tuser          => buf_frame_m_tdata(39 downto 32),

        m_axis_frame_tvalid         => frame_2x_tvalid,
        m_axis_frame_tready         => frame_2x_tready,
        m_axis_frame_tdata          => frame_2x_tdata,
        m_axis_frame_tuser          => frame_2x_tuser
    );

    -- assigns
    buf_frame_s_tdata <= src_frame_tuser & src_frame_tdata;

    dout_tdata(31 downto 24) <= (others => '0');
    dout_tdata(23 downto 16) <= dout_r;
    dout_tdata(15 downto  8) <= dout_g;
    dout_tdata( 7 downto  0) <= dout_b;

    frame_2x_tready <= '1' when dout_tvalid = '1' and frame_2x_tready_mask = '1' else '0';

    bright_filler(7 downto 0)       <= (others => frame_2x_tdata(8));
    bright_filler_inv(7 downto 0)   <= (others => not frame_2x_tdata(8));

    dark_filler(7)                  <= '0';
    dark_filler(6 downto 0)         <= (others => frame_2x_tdata(8));

    dark_filler_inv(7)              <= '0';
    dark_filler_inv(6 downto 0)     <= (others => not frame_2x_tdata(8));


    process (vid_clk) begin
        if rising_edge(vid_clk) then
            if vid_resetn = '0' then
                blink_on <= '0';
            else
                if (event_blink_switch = '1') then
                    blink_on <= not blink_on;
                end if;
            end if;
        end if;
    end process;

    process (vid_clk) begin
        if rising_edge(vid_clk) then
            if vid_resetn = '0' then
                frame_2x_tready_mask <= '0';
            else
                if (din_tvalid = '1') then
                    if (din_y = x"070") then
                        frame_2x_tready_mask <= '1';
                    elsif (din_y = x"390") then
                        frame_2x_tready_mask <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;

    process (vid_clk) begin
        if rising_edge(vid_clk) then
            if vid_resetn = '0' then
                dout_tvalid <= '0';
                dout_r <= (others => '0');
                dout_g <= (others => '0');
                dout_b <= (others => '0');
                blank_mask <= (others => '0') ;
            else
                dout_tvalid <= din_tvalid;

                if (din_tvalid = '0') then
                    if (din_y = x"070") then
                        blank_mask <= (others => '1');
                    elsif (din_y = x"390") then
                        blank_mask <= (others => '0');
                    end if;
                end if;

                if (din_tvalid = '1') then
                    if ((din_x = x"000" and din_y = x"000") or (din_x = x"4FF" and din_y = x"000") or
                        (din_x = x"000" and din_y = x"3FF") or (din_x = x"4FF" and din_y = x"3FF"))
                    then
                        -- calibration points
                        dout_r <= x"FF";
                        dout_g <= x"FF";
                        dout_b <= x"FF";
                    -- elsif (din_x = x"000" or din_x = x"4FF" or din_y = x"070" or din_y=x"38F") then
                    --     -- border
                    --     dout_r <= comb_and(x"FF", blank_mask);
                    --     dout_g <= comb_and(x"FF", blank_mask);
                    --     dout_b <= comb_and(x"FF", blank_mask);
                    else
                        -- main
                        dout_r <= comb_and(x"00", blank_mask);

                        case(frame_2x_tdata(7 downto 0)) is
                            when x"00" | x"08" | x"80" | x"88" =>
                                dout_g <= comb_and(x"00", blank_mask);
                            when x"78" =>
                                -- dark green on green
                                dout_g <= comb_and(comb_not(dark_filler), blank_mask);
                            when x"70" =>
                                --black on green
                                dout_g <= comb_and(comb_not(bright_filler), blank_mask);
                            when x"F8" =>
                                -- dark green on green blinking
                                if (blink_on = '0') then
                                    dout_g <= comb_and(comb_not(dark_filler), blank_mask);
                                else
                                    dout_g <= comb_and(dark_filler, blank_mask);
                                end if;
                            when x"F0" =>
                                --black on green blinking
                                if (blink_on = '0') then
                                    dout_g <= comb_and(comb_not(bright_filler), blank_mask);
                                else
                                    dout_g <= comb_and(bright_filler, blank_mask);
                                end if;
                            when others =>
                                if (blink_on = '1' and frame_2x_tdata(7) = '1') then
                                    if (frame_2x_tdata(3) = '0') then
                                        -- dark green on black
                                        dout_g <= comb_and(dark_filler_inv, blank_mask);
                                    else
                                        -- bright green on black
                                        dout_g <= comb_and(bright_filler_inv, blank_mask);
                                    end if;
                                else
                                    if (frame_2x_tdata(3) = '0') then
                                        -- dark green on black
                                        dout_g <= comb_and(dark_filler, blank_mask);
                                    else
                                        -- bright green on black
                                        dout_g <= comb_and(bright_filler, blank_mask);
                                    end if;
                                end if;
                        end case;

                        dout_b <= comb_and(x"00", blank_mask);
                    end if;
                else
                    -- dark area
                    dout_r <= (others => '0');
                    dout_g <= (others => '0');
                    dout_b <= (others => '0');
                end if;

            end if;

            dout_tuser <= x"0" & din_y & x"0" & din_x;
        end if;
    end process;

end architecture;
