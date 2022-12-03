
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

entity video_vga_ctrl is
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
end entity video_vga_ctrl;

architecture rtl of video_vga_ctrl is
    -- constant FRAME_WIDTH    : natural := 640;
    -- constant FRAME_HEIGHT   : natural := 480;

    -- constant H_FP           : natural := 16; --H front porch width (pixels)
    -- constant H_PW           : natural := 96; --H sync pulse width (pixels)
    -- constant H_MAX          : natural := 800; --H total period (pixels)

    -- constant V_FP           : natural := 10; --V front porch width (lines)
    -- constant V_PW           : natural := 2; --V sync pulse width (lines)
    -- constant V_MAX          : natural := 525; --V total period (lines)

    -- constant H_POL          : std_logic := '0';
    -- constant V_POL          : std_logic := '0';

    constant FRAME_WIDTH    : natural := 1280;
    constant FRAME_HEIGHT   : natural := 1024;

    constant H_FP           : natural := 48; --H front porch width (pixels)
    constant H_PW           : natural := 112; --H sync pulse width (pixels)
    constant H_BP           : natural := 248;
    constant H_MAX          : natural := 1688; --H total period (pixels)

    constant V_FP           : natural := 1; --V front porch width (lines)
    constant V_PW           : natural := 3; --V sync pulse width (lines)
    constant V_BP           : natural := 38; -- V back porch width
    constant V_MAX          : natural := 1066; --V total period (lines)

	signal hcnt				: integer range 0 to 1687;
	signal vcnt				: integer range 0 to 1065;
	signal display_en		: std_logic;
	signal hsync            : std_logic;
	signal vsync            : std_logic;

begin
    -- i/o assigns
    VGA_HS                       <= hsync;
    VGA_VS                       <= vsync;

    VGA_SYNC_N                   <= '0';
    VGA_BLANK_N                  <= display_en;

    m_axis_vid_tvalid            <= display_en;
    m_axis_vid_tdata(7 downto 0) <= (others => '0');

    -- forming sync pulses and display area
	process(vid_clk) begin
		if rising_edge(vid_clk) then
            if vid_resetn = '0' then
                hcnt <= 0;
                vcnt <= 0;
                hsync <= '0';
                vsync <= '0';
                display_en <= '0';
            else
                -- counters
                if (hcnt = 1687) then
                    hcnt <= 0;
                    if (vcnt = 1065) then
                        vcnt <= 0;
                    else
                        vcnt <= vcnt+1;
                    end if;
                else
                    hcnt <= hcnt+1;
                end if;

                --sync pulses
                if (hcnt > 47 and hcnt < 160) then
                    hsync <= '1';
                else
                    hsync <= '0';
                end if;

                if (vcnt > 1025 and vcnt < 1028) then
                    vsync <= '1';
                else
                    vsync <= '0';
                end if;

                --display enable
                if (hcnt > 407 and vcnt < 1024) then
                    display_en <= '1';
                else
                    display_en <= '0';
                end if;

            end if;
		end if;
	end process;

end architecture;
