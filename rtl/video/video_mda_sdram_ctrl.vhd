
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

entity video_mda_sdram_ctrl is
    port (
        vid_clk                         : in std_logic;
        vid_resetn                      : in std_logic;

        sdram_clk                       : in std_logic;
        sdram_resetn                    : in std_logic;

        s_axis_vid_mem_req_tvalid       : in std_logic;
        s_axis_vid_mem_req_tdata        : in std_logic_vector(31 downto 0);

        s_axis_sdram_res_tvalid         : in std_logic;
        s_axis_sdram_res_tdata          : in std_logic_vector(31 downto 0);

        m_axis_sdram_req_tvalid         : out std_logic;
        m_axis_sdram_req_tready         : in std_logic;
        m_axis_sdram_req_tdata          : out std_logic_vector(63 downto 0);

        m_axis_vid_mem_res_tvalid       : out std_logic;
        m_axis_vid_mem_res_tdata        : out std_logic_vector(15 downto 0)
    );
end entity video_mda_sdram_ctrl;

architecture rtl of video_mda_sdram_ctrl is

    constant BYTES_PER_LINE             : natural := 80 * 2; -- one byte for char, one byte for attr
    constant MEM_WORDS_PER_LINE         : natural := BYTES_PER_LINE/4; -- each word in memory contains 4 bytes

    component async_axis_fifo is
        generic (
            FIFO_DEPTH                  : natural := 8;
            FIFO_WIDTH                  : natural := 128
        );
        port (
            s_axis_aclk                 : in std_logic;
            s_axis_aresetn              : in std_logic;
            s_axis_tvalid               : in std_logic;
            s_axis_tready               : out std_logic;
            s_axis_tdata                : in std_logic_vector(FIFO_WIDTH-1 downto 0);

            m_axis_aclk                 : in std_logic;
            m_axis_aresetn              : in std_logic;
            m_axis_tvalid               : out std_logic;
            m_axis_tready               : in std_logic;
            m_axis_tdata                : out std_logic_vector(FIFO_WIDTH-1 downto 0)
        );
    end component;

    signal sdram_vid_req_tvalid         : std_logic;
    signal sdram_vid_req_tdata          : std_logic_vector(31 downto 0);

    signal sdram_burst_req_tvalid       : std_logic;
    signal sdram_burst_req_tready       : std_logic;
    signal sdram_burst_req_tlast        : std_logic;
    signal sdram_burst_req_tdata        : std_logic_vector(63 downto 0);
    signal sdram_burst_req_addr         : std_logic_vector(24 downto 0);
    signal sdram_burst_req_addr_base    : natural range 0 to 2**25-1;
    signal sdram_burst_req_addr_offset  : natural range 0 to 2**25-1;

    signal vid_sdram_res_tvalid         : std_logic;
    signal vid_sdram_res_tready         : std_logic;
    signal vid_sdram_res_tdata          : std_logic_vector(31 downto 0);
    signal vid_sdram_tik_tok            : std_logic;

    signal vid_mem_res_tvalid           : std_logic;
    signal vid_mem_res_tdata            : std_logic_vector(15 downto 0);
begin

    -- i/o assigns
    m_axis_vid_mem_res_tvalid <= vid_mem_res_tvalid;
    m_axis_vid_mem_res_tdata  <= vid_mem_res_tdata;

    m_axis_sdram_req_tvalid     <= sdram_burst_req_tvalid;
    sdram_burst_req_tready      <= m_axis_sdram_req_tready;
    m_axis_sdram_req_tdata      <= sdram_burst_req_tdata;

    -- Module async_axis_fifo instantiation
    async_axis_fifo_req_inst : async_axis_fifo generic map (
        FIFO_DEPTH      => 8,
        FIFO_WIDTH      => 32
    ) port map (
        s_axis_aclk     => vid_clk,
        s_axis_aresetn  => vid_resetn,
        s_axis_tvalid   => s_axis_vid_mem_req_tvalid,
        s_axis_tready   => open,
        s_axis_tdata    => s_axis_vid_mem_req_tdata,
        m_axis_aclk     => sdram_clk,
        m_axis_aresetn  => sdram_resetn,
        m_axis_tvalid   => sdram_vid_req_tvalid,
        m_axis_tready   => '1',
        m_axis_tdata    => sdram_vid_req_tdata
    );

    -- Module async_axis_fifo instantiation
    async_axis_fifo_res_inst : async_axis_fifo generic map (
        FIFO_DEPTH      => MEM_WORDS_PER_LINE,
        FIFO_WIDTH      => 32
    ) port map (
        s_axis_aclk     => sdram_clk,
        s_axis_aresetn  => sdram_resetn,
        s_axis_tvalid   => s_axis_sdram_res_tvalid,
        s_axis_tready   => open,
        s_axis_tdata    => s_axis_sdram_res_tdata,
        m_axis_aclk     => vid_clk,
        m_axis_aresetn  => vid_resetn,
        m_axis_tvalid   => vid_sdram_res_tvalid,
        m_axis_tready   => vid_sdram_res_tready,
        m_axis_tdata    => vid_sdram_res_tdata
    );

    -- assigns
    sdram_burst_req_tdata(63 downto 58) <= (others => '0');
    sdram_burst_req_tdata(57)           <= '0';  -- read
    sdram_burst_req_tdata(56 downto 32) <= sdram_burst_req_addr;
    sdram_burst_req_tdata(31 downto  0) <= (others => '0');

    sdram_burst_req_addr <= std_logic_vector(to_unsigned(sdram_burst_req_addr_base  + sdram_burst_req_addr_offset, 25));
    vid_sdram_res_tready <= vid_sdram_tik_tok;

    -- sdram_clk domain
    process (sdram_clk) begin
        if rising_edge(sdram_clk) then
            -- control signals
            if sdram_resetn = '0' then
                sdram_burst_req_tvalid <= '0';
                sdram_burst_req_tlast <= '0';
                sdram_burst_req_addr_offset <= 0;
            else
                if (sdram_vid_req_tvalid = '1') then
                    sdram_burst_req_tvalid <= '1';
                elsif (sdram_burst_req_tvalid = '1' and sdram_burst_req_tready = '1' and sdram_burst_req_tlast = '1') then
                    sdram_burst_req_tvalid <= '0';
                end if;

                if (sdram_vid_req_tvalid = '1') then
                    sdram_burst_req_tlast <= '0';
                elsif (sdram_burst_req_tvalid = '1' and sdram_burst_req_tready = '1' and sdram_burst_req_addr_offset = MEM_WORDS_PER_LINE-2) then
                    sdram_burst_req_tlast <= '1';
                end if;

                if (sdram_vid_req_tvalid = '1') then
                    sdram_burst_req_addr_offset <= 0;
                elsif (sdram_burst_req_tvalid = '1' and sdram_burst_req_tready = '1') then
                    sdram_burst_req_addr_offset <= sdram_burst_req_addr_offset + 1;
                end if;
            end if;

            -- datapath
            if (sdram_vid_req_tvalid = '1') then
                sdram_burst_req_addr_base <= to_integer(unsigned(sdram_vid_req_tdata(24 downto 0)));
            end if;
        end if;
    end process;

    -- vid_clk
    process (vid_clk) begin
        if rising_edge(vid_clk) then
            -- control signals
            if vid_resetn = '0' then
                vid_sdram_tik_tok <= '0';
                vid_mem_res_tvalid <= '0';
            else
                if (vid_sdram_res_tvalid = '1' and vid_sdram_res_tready = '0') then
                    vid_sdram_tik_tok <= '1';
                elsif (vid_sdram_res_tvalid = '1' and vid_sdram_res_tready = '1') then
                    vid_sdram_tik_tok <= '0';
                end if;

                vid_mem_res_tvalid <= vid_sdram_res_tvalid;
            end if;

            -- datapath
            if (vid_sdram_tik_tok = '0') then
                vid_mem_res_tdata <= vid_sdram_res_tdata(31 downto 16);
            else
                vid_mem_res_tdata <= vid_sdram_res_tdata(15 downto  0);
            end if;
        end if;
    end process;

end architecture;
