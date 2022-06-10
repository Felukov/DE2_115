
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

entity video_mda_fb_frame_gen is
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
end entity video_mda_fb_frame_gen;

architecture rtl of video_mda_fb_frame_gen is

    component video_mda_fb_frame_gen_ram is
        generic (
            ADDR_WIDTH              : natural := 6;
            DATA_WIDTH              : natural := 4
        );
        port (
            clk                     : in std_logic;
            we                      : in std_logic;
            waddr                   : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
            wdata                   : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            re                      : in std_logic;
            raddr                   : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
            q                       : out std_logic_vector(DATA_WIDTH - 1 downto 0)
        );
    end component;

    component video_mda_fb_font_rom is
        generic (
            ADDR_WIDTH              : natural := 6;
            DATA_WIDTH              : natural := 4
        );
        port (
            clk                     : in std_logic;
            re                      : in std_logic;
            raddr                   : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
            q                       : out std_logic_vector(DATA_WIDTH - 1 downto 0)
        );
    end component;

    constant BYTES_PER_LINE         : natural := 80 * 2; -- one byte for char, one byte for attr
    constant MEM_WORDS_PER_LINE     : natural := BYTES_PER_LINE/4; -- each word in memory contains 4 bytes

    signal wakeup                   : std_logic;

    signal data_req_tvalid          : std_logic;
    signal data_req_line            : natural range 0 to 24;
    signal data_req_address         : std_logic_vector(24 downto 0);

    signal data_res_tvalid          : std_logic;
    signal data_res_tdata           : std_logic_vector(15 downto 0);
    signal data_res_taddr           : std_logic_vector(7 downto 0);
    signal data_res_addr_lo         : natural range 0 to 79;
    signal data_res_addr_hi         : std_logic;

    signal data_rd_tvalid           : std_logic;
    signal data_rd_tready           : std_logic;
    signal data_rd_re               : std_logic;
    signal data_rd_taddr            : std_logic_vector(7 downto 0);
    signal data_rd_addr_lo          : natural range 0 to 79;
    signal data_rd_addr_hi          : std_logic;
    signal data_rd_iter             : natural range 0 to 15;

    signal char_tvalid              : std_logic;
    signal char_tready              : std_logic;
    signal char_tlast               : std_logic;
    signal char_tdata               : std_logic_vector(15 downto 0);
    signal char_col                 : natural range 0 to 79;
    signal char_line                : natural range 0 to 15;

    signal font_re                  : std_logic;
    signal font_addr                : std_logic_vector(11 downto 0);

    signal font_line_tvalid         : std_logic;
    signal font_line_tready         : std_logic;
    signal font_line_tlast          : std_logic;
    signal font_line_tdata          : std_logic_vector(7 downto 0);
    signal font_line_col            : natural range 0 to 7;
    signal font_line_char_col       : natural range 0 to 79;
    signal font_line_row            : natural range 0 to 15;
    signal font_line_attr           : std_logic_vector(7 downto 0);

    signal pixel_tvalid             : std_logic;
    signal pixel_tready             : std_logic;
    signal pixel_tdata              : std_logic_vector(31 downto 0);
    signal pixel_attr               : std_logic_vector(7 downto 0);
    signal pixel_fill               : std_logic;
    signal pixel_tlast              : std_logic;
    signal pixel_end_of_frame       : std_logic;

    signal buffer_ready             : std_logic;
    signal generator_ready          : std_logic;
    signal event_read_next          : std_logic;

begin

    -- i/o assigns
    m_axis_frame_tvalid                     <= pixel_tvalid;
    pixel_tready                            <= m_axis_frame_tready;
    m_axis_frame_tdata                      <= pixel_tdata;
    m_axis_frame_tuser(7 downto 2)          <= (others => '0') ;
    m_axis_frame_tuser(1)                   <= pixel_end_of_frame;
    m_axis_frame_tuser(0)                   <= pixel_tlast;

    m_axis_vid_mem_req_tvalid               <= data_req_tvalid;
    m_axis_vid_mem_req_tdata(31 downto 25)  <= (others => '0');
    m_axis_vid_mem_req_tdata(24 downto 0)   <= data_req_address;

    data_res_tvalid                         <= s_axis_vid_mem_res_tvalid;
    data_res_tdata                          <= s_axis_vid_mem_res_tdata;


    -- module video_mda_fb_frame_gen_ram instantiation
    video_mda_fb_frame_gen_ram_inst : video_mda_fb_frame_gen_ram generic map (
        ADDR_WIDTH      => 8,
        DATA_WIDTH      => 16
    ) port map (
        clk             => vid_clk,
        we              => data_res_tvalid,
        waddr           => data_res_taddr,
        wdata           => data_res_tdata,
        re              => data_rd_re,
        raddr           => data_rd_taddr,
        q               => char_tdata
    );

    -- module video_mda_fb_font_rom instantiation
    video_mda_fb_font_rom_inst : video_mda_fb_font_rom generic map (
        ADDR_WIDTH      => 12,
        DATA_WIDTH      => 8
    ) port map (
        clk             => vid_clk,
        re              => font_re,
        raddr           => font_addr,
        q               => font_line_tdata
    );


    -- Assigns
    data_res_taddr   <= data_res_addr_hi & std_logic_vector(to_unsigned(data_res_addr_lo, 7));
    data_rd_taddr    <= data_rd_addr_hi & std_logic_vector(to_unsigned(data_rd_addr_lo, 7));

    data_rd_re       <= '1' when data_rd_tvalid = '1' and data_rd_tready = '1' else '0';
    data_rd_tready   <= '1' when char_tvalid = '0' or char_tready = '1' else '0';
    char_tready      <= '1' when font_line_tvalid = '0' or (font_line_tvalid = '1' and font_line_tready = '1' and font_line_col = 7) else '0';
    font_line_tready <= '1' when pixel_tvalid = '0' or pixel_tready = '1' else '0';

    font_re          <= '1' when char_tvalid = '1' and char_tready = '1' else '0';
    font_addr        <= char_tdata(15 downto 8) & std_logic_vector(to_unsigned(char_line, 4));

    pixel_tdata(31 downto 9) <= (others => '0');
    pixel_tdata(8)           <= pixel_fill;
    pixel_tdata(7 downto 0)  <= pixel_attr;


    -- requesting data from an external storage
    process (vid_clk)
        function slv (a : integer) return std_logic_vector is begin
            return std_logic_vector(to_unsigned(a, 25));
        end function;
    begin
        if rising_edge(vid_clk) then
            -- control
            if vid_resetn = '0' then
                wakeup <= '1';
                data_req_tvalid <= '0';
                data_req_line <= 0;
            else
                wakeup <= '0';

                if (wakeup = '1' or event_read_next = '1') then
                    data_req_tvalid <= '1';
                else
                    data_req_tvalid <= '0';
                end if;

                if (wakeup = '1' or event_read_next = '1') then
                    if (data_req_line = 24) then
                        data_req_line <= 0;
                    else
                        data_req_line <= data_req_line + 1;
                    end if;
                end if;

            end if;
            -- datapath
            if (wakeup = '1' or event_read_next = '1') then
                if (data_req_line = 0) then
                    data_req_address <= slv(16#2C000#); -- 0xB0000 >> 2
                else
                    data_req_address <= std_logic_vector(unsigned(data_req_address) + to_unsigned(MEM_WORDS_PER_LINE, 25));
                end if;
            end if;
        end if;
    end process;

    -- storing data from an external storage into the internal buffer
    process (vid_clk) begin
        if rising_edge(vid_clk) then
            -- control
            if vid_resetn = '0' then
                data_res_addr_lo <= 0;
                data_res_addr_hi <= '0';
                buffer_ready     <= '0';
            else
                if (data_res_tvalid = '1') then
                    if (data_res_addr_lo = 79) then
                        data_res_addr_lo <= 0;
                    else
                        data_res_addr_lo <= data_res_addr_lo + 1;
                    end if;
                end if;

                if (data_res_tvalid = '1' and data_res_addr_lo = 79) then
                    data_res_addr_hi <= not data_res_addr_hi;
                end if;

                if (data_res_tvalid = '1' and data_res_addr_lo = 79) then
                    buffer_ready <= '1';
                elsif (generator_ready = '1') then
                    buffer_ready <= '0';
                end if;
            end if;
        end if;
    end process;

    -- reading data from the internal buffer
    process (vid_clk) begin
        if rising_edge(vid_clk) then
            if vid_resetn = '0' then
                data_rd_tvalid <= '0';
                data_rd_addr_hi <= '0';
                data_rd_addr_lo <= 0;
                data_rd_iter <= 0;
                event_read_next <= '0';
                generator_ready <= '1';
            else
                if (buffer_ready = '1' and generator_ready = '1') then
                    generator_ready <= '0';
                elsif (data_rd_tvalid = '1' and data_rd_tready = '1' and data_rd_addr_lo = 79 and data_rd_iter = 15) then
                    generator_ready <= '1';
                end if;

                if (buffer_ready = '1' and generator_ready = '1') then
                    data_rd_tvalid <= '1';
                elsif (data_rd_tvalid = '1' and data_rd_tready = '1' and data_rd_addr_lo = 79 and data_rd_iter = 15) then
                    data_rd_tvalid <= '0';
                end if;

                if (buffer_ready = '1' and generator_ready = '1') then
                    data_rd_iter <= 0;
                elsif (data_rd_tvalid = '1' and data_rd_tready = '1' and data_rd_addr_lo = 79) then
                    data_rd_iter <= (data_rd_iter + 1) mod 16;
                end if;

                if (data_rd_tvalid = '1' and data_rd_tready = '1' and data_rd_addr_lo = 79 and data_rd_iter = 15) then
                    data_rd_addr_hi <= not data_rd_addr_hi;
                end if;

                if (data_rd_tvalid = '1' and data_rd_tready = '1' and data_rd_addr_lo = 79 and data_rd_iter = 1) then
                    event_read_next <= '1';
                else
                    event_read_next <= '0';
                end if;

                if (buffer_ready = '1' and generator_ready = '1') then
                    data_rd_addr_lo <= 0;
                elsif (data_rd_tvalid = '1' and data_rd_tready = '1') then
                    if (data_rd_addr_lo = 79) then
                        data_rd_addr_lo <= 0;
                    else
                        data_rd_addr_lo <= data_rd_addr_lo + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- reading an ascii character from the internal buffer
    process (vid_clk) begin
        if rising_edge(vid_clk) then
            -- control
            if (vid_resetn = '0') then
                char_tvalid <= '0';
                char_tlast <= '0';
            else
                if (data_rd_tvalid = '1') then
                    char_tvalid <= '1';
                elsif (char_tready = '1') then
                    char_tvalid <= '0';
                end if;

                if (data_rd_tvalid = '1' and data_rd_tready = '1') then
                    if (data_rd_addr_lo = 79) then
                        char_tlast <= '1';
                    else
                        char_tlast <= '0';
                    end if;
                end if;
            end if;
            -- data
            if (data_rd_tvalid = '1' and data_rd_tready = '1') then
                char_line <= data_rd_iter;
                char_col <= data_rd_addr_lo;
            end if;
        end if;
    end process;

    -- requesting font line for the ascii character
    process (vid_clk) begin
        if rising_edge(vid_clk) then
            -- control
            if (vid_resetn = '0') then
                font_line_tvalid <= '0';
                font_line_tlast <= '0';
                font_line_col <= 0;
            else
                if (char_tvalid = '1' and char_tready = '1') then
                    font_line_tvalid <= '1';
                elsif (font_line_tvalid = '1' and font_line_tready = '1' and font_line_col = 7) then
                    font_line_tvalid <= '0';
                end if;

                if (char_tvalid = '1' and char_tready = '1') then
                    font_line_col <= 0;
                elsif (font_line_tvalid = '1' and font_line_tready = '1') then
                    font_line_col <= (font_line_col + 1) mod 8;
                end if;

                if (char_tvalid = '1' and char_tready = '1') then
                    font_line_tlast <= char_tlast;
                end if;
            end if;
            -- data
            if (char_tvalid = '1' and char_tready = '1') then
                font_line_char_col <= char_col;
                font_line_row <= char_line;
                font_line_attr <= char_tdata(7 downto 0);
            end if;
        end if;
    end process;

    -- forming the pixel value
    process (vid_clk) begin
        if rising_edge(vid_clk) then
            -- control
            if (vid_resetn = '0') then
                pixel_tvalid <= '0';
                pixel_tlast <= '0';
                pixel_end_of_frame <= '0';
            else
                if (font_line_tvalid = '1' and font_line_tready = '1') then
                    pixel_tvalid <= '1';
                elsif (pixel_tready = '1') then
                    pixel_tvalid <= '0';
                end if;

                if (font_line_tvalid = '1' and font_line_tready = '1') then
                    if (font_line_char_col = 79 and font_line_col = 7) then
                        pixel_tlast <= '1';
                    else
                        pixel_tlast <= '0';
                    end if;
                end if;

                if (font_line_tvalid = '1' and font_line_tready = '1') then
                    pixel_end_of_frame <= font_line_tlast;
                end if;
            end if;
            -- data
            if (font_line_tvalid = '1' and font_line_tready = '1') then
                if (font_line_attr(1) = '1' and font_line_row = 15) then
                    -- underline
                    pixel_fill <= not font_line_tdata(7 - font_line_col);
                else
                    pixel_fill <= font_line_tdata(7 - font_line_col);
                end if;
            end if;
            if (font_line_tvalid = '1' and font_line_tready = '1') then
                pixel_attr <= font_line_attr;
            end if;
        end if;
    end process;

end architecture;
