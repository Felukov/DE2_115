
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

entity video_mda_fb_scaler is
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
end entity video_mda_fb_scaler;

architecture rtl of video_mda_fb_scaler is
    component axis_fifo_er is
        generic (
            FIFO_DEPTH          : natural := 2**8;
            FIFO_WIDTH          : natural := 128
        );
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            s_axis_fifo_tvalid  : in std_logic;
            s_axis_fifo_tready  : out std_logic;
            s_axis_fifo_tdata   : in std_logic_vector(FIFO_WIDTH-1 downto 0);

            m_axis_fifo_tvalid  : out std_logic;
            m_axis_fifo_tready  : in std_logic;
            m_axis_fifo_tdata   : out std_logic_vector(FIFO_WIDTH-1 downto 0)
        );
    end component axis_fifo_er;

    signal frame_src_tvalid     : std_logic;
    signal frame_src_tready     : std_logic;
    signal frame_src_tdata      : std_logic_vector(31 downto 0);
    signal frame_src_tuser      : std_logic_vector(7 downto 0);

    signal fifo_s_tvalid        : std_logic;
    signal fifo_s_tdata         : std_logic_vector(39 downto 0);
    signal fifo_m_tdata         : std_logic_vector(39 downto 0);

    signal frame_buf_tvalid     : std_logic;
    signal frame_buf_tready     : std_logic;
    signal frame_buf_tdata      : std_logic_vector(31 downto 0);
    signal frame_buf_tuser      : std_logic_vector(7 downto 0);

    signal frame_out_tvalid     : std_logic;
    signal frame_out_tready     : std_logic;
    signal frame_out_tdata      : std_logic_vector(31 downto 0);
    signal frame_out_tuser      : std_logic_vector(7 downto 0);

    signal frame_out_2x_tvalid  : std_logic;
    signal frame_out_2x_tready  : std_logic;
    signal frame_out_2x_tdata   : std_logic_vector(31 downto 0);
    signal frame_out_2x_tuser   : std_logic_vector(7 downto 0);
    signal frame_out_2x_user_buf: std_logic_vector(7 downto 0);

    signal use_buffer           : std_logic;
    signal frame_out_2x_sample  : std_logic;

begin
    -- i/o assign
    frame_src_tvalid    <= s_axis_frame_tvalid;
    s_axis_frame_tready <= frame_src_tready;
    frame_src_tdata     <= s_axis_frame_tdata;
    frame_src_tuser     <= s_axis_frame_tuser;

    m_axis_frame_tvalid <= frame_out_2x_tvalid;
    frame_out_2x_tready <= m_axis_frame_tready;
    m_axis_frame_tdata  <= frame_out_2x_tdata;
    m_axis_frame_tuser  <= frame_out_2x_tuser;

    -- module axis_fifo instantiation
    axis_fifo_inst : axis_fifo_er generic map (
        FIFO_DEPTH              => 1024,
        FIFO_WIDTH              => 40
    ) port map (
        clk                     => vid_clk,
        resetn                  => vid_resetn,

        s_axis_fifo_tvalid      => fifo_s_tvalid,
        s_axis_fifo_tready      => open,
        s_axis_fifo_tdata       => fifo_s_tdata,

        m_axis_fifo_tvalid      => frame_buf_tvalid,
        m_axis_fifo_tready      => frame_buf_tready,
        m_axis_fifo_tdata       => fifo_m_tdata
    );

    -- assigns
    frame_src_tready <= '1' when use_buffer = '0' and (frame_out_tvalid = '0' or frame_out_tready = '1') else '0';

    fifo_s_tvalid    <= '1' when frame_src_tvalid = '1' and frame_src_tready = '1' else '0';
    fifo_s_tdata     <= frame_src_tuser & frame_src_tdata;

    frame_buf_tready <= '1' when use_buffer = '1' and (frame_out_tvalid = '0' or frame_out_tready = '1') else '0';
    frame_buf_tuser  <= fifo_m_tdata(39 downto 32);
    frame_buf_tdata  <= fifo_m_tdata(31 downto  0);

    frame_out_tready <= '1' when frame_out_2x_tvalid = '0' or (frame_out_2x_tvalid = '1' and frame_out_2x_tready = '1' and frame_out_2x_sample = '1') else '0';

    -- controlling source
    process (vid_clk) begin
        if rising_edge(vid_clk) then
            -- resettable logic
            if vid_resetn = '0' then
                use_buffer <= '0';
            else
                if (frame_src_tvalid = '1' and frame_src_tready = '1' and frame_src_tuser(0) = '1') then
                    use_buffer <= '1';
                elsif (frame_buf_tvalid = '1' and frame_buf_tready = '1' and frame_buf_tuser(0) = '1') then
                    use_buffer <= '0';
                end if;
            end if;
        end if;
    end process;

    -- forming double lines
    process (vid_clk) begin
        if rising_edge(vid_clk) then
            -- resettable logic
            if vid_resetn = '0' then
                frame_out_tvalid <= '0';
                frame_out_tuser <= (others => '0');
            else
                if (frame_src_tvalid = '1' or frame_buf_tvalid = '1') then
                    frame_out_tvalid <= '1';
                elsif (frame_out_tready = '1') then
                    frame_out_tvalid <= '0';
                end if;

                if (frame_src_tvalid = '1' and frame_src_tready = '1') then
                    frame_out_tuser <= (others => '0');
                elsif (frame_buf_tvalid = '1' and frame_buf_tready = '1') then
                    frame_out_tuser <= frame_buf_tuser;
                end if;

            end if;
            -- without reset
            if (frame_src_tvalid = '1' and frame_src_tready = '1') then
                frame_out_tdata <= frame_src_tdata;
            elsif (frame_buf_tvalid = '1' and frame_buf_tready = '1') then
                frame_out_tdata <= frame_buf_tdata;
            end if;
        end if;
    end process;

    -- forming double pixels
    process (vid_clk) begin
        if rising_edge(vid_clk) then
            -- resettable logic
            if vid_resetn = '0' then
                frame_out_2x_tvalid <= '0';
                frame_out_2x_sample <= '0';
                frame_out_2x_tuser <= (others => '0');
            else
                if (frame_out_tvalid = '1' and frame_out_tready = '1') then
                    frame_out_2x_tvalid <= '1';
                elsif (frame_out_2x_tvalid = '1' and frame_out_2x_tready = '1' and frame_out_2x_sample = '1') then
                    frame_out_2x_tvalid <= '0';
                end if;

                if (frame_out_tvalid = '1' and frame_out_tready = '1') then
                    frame_out_2x_sample <= '0';
                elsif (frame_out_2x_tvalid = '1' and frame_out_2x_tready = '1') then
                    frame_out_2x_sample <= '1';
                end if;

                if (frame_out_tvalid = '1' and frame_out_tready = '1') then
                    frame_out_2x_user_buf <= frame_out_tuser;
                end if;

                if (frame_out_tvalid = '1' and frame_out_tready = '1') then
                    frame_out_2x_tuser <= (others => '0');
                elsif (frame_out_2x_tvalid = '1' and frame_out_2x_tready = '1') then
                    frame_out_2x_tuser <= frame_out_2x_user_buf;
                end if;
            end if;
            --without reset
            if (frame_out_tvalid = '1' and frame_out_tready = '1') then
                frame_out_2x_tdata <= frame_out_tdata;
            end if;
        end if;
    end process;

end architecture;
