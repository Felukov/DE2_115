
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
use work.cpu86_types.all;

entity cpu86_dcache is
    port (
        clk                     : in std_logic;
        resetn                  : in std_logic;

        dcache_s_tvalid         : in std_logic;
        dcache_s_tready         : out std_logic;
        dcache_s_tcmd           : in std_logic;
        dcache_s_taddr          : in std_logic_vector(19 downto 0);
        dcache_s_twidth         : in std_logic;
        dcache_s_tdata          : in std_logic_vector(15 downto 0);

        dcache_m_tvalid         : out std_logic;
        dcache_m_tready         : in std_logic;
        dcache_m_tcmd           : out std_logic;
        dcache_m_taddr          : out std_logic_vector(19 downto 0);
        dcache_m_twidth         : out std_logic;
        dcache_m_tdata          : out std_logic_vector(15 downto 0);
        dcache_m_thit           : out std_logic;
        dcache_m_tcache         : out std_logic_vector(15 downto 0)
    );
end entity cpu86_dcache;

architecture rtl of cpu86_dcache is

    constant CACHE_LINE_SIZE    : natural := 512;
    constant CACHE_LINE_WIDTH   : natural := 9;
    constant CACHE_TAG_WIDTH    : natural := 12;
    constant BRAM_ADDR_WIDTH    : natural := 9;

    component cpu86_exec_dcache_ram_core is
        generic (
            ADDR_WIDTH          : natural := 6;
            DATA_WIDTH          : natural := 4
        );
        port (
            clk                 : in std_logic;
            addr                : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
            we                  : in std_logic;
            wdata               : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            re                  : in std_logic;
            q                   : out std_logic_vector(DATA_WIDTH - 1 downto 0)
        );
    end component;

    signal d_valid              : std_logic_vector(CACHE_LINE_SIZE-1 downto 0);
    signal s_index              : natural range 0 to CACHE_LINE_SIZE-1;

    signal m_tag                : std_logic_vector(19 downto CACHE_LINE_WIDTH-1);

    signal dcache_tag           : std_logic_vector(19 downto CACHE_LINE_WIDTH-1);
    signal dcache_valid         : std_logic;

    signal dcache_tvalid        : std_logic;
    signal dcache_tready        : std_logic;
    signal dcache_tcmd          : std_logic;
    signal dcache_taddr         : std_logic_vector(19 downto 0);
    signal dcache_twidth        : std_logic;
    signal dcache_tdata         : std_logic_vector(15 downto 0);
    signal dcache_thit          : std_logic;
    signal dcache_tcache        : std_logic_vector(15 downto 0);

    signal bram_we              : std_logic;
    signal bram_addr            : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
    signal bram_re              : std_logic;

begin

    cpu86_exec_dcache_ram_core_tag_inst : cpu86_exec_dcache_ram_core generic map (
        ADDR_WIDTH      => BRAM_ADDR_WIDTH,
        DATA_WIDTH      => CACHE_TAG_WIDTH
    ) port map (
        clk             => clk,
        addr            => bram_addr,
        we              => bram_we,
        wdata           => dcache_s_taddr(19 downto CACHE_LINE_WIDTH-1),
        re              => bram_re,
        q               => dcache_tag
    );

    cpu86_exec_dcache_ram_core_data_inst : cpu86_exec_dcache_ram_core generic map (
        ADDR_WIDTH      => BRAM_ADDR_WIDTH,
        DATA_WIDTH      => 16
    ) port map (
        clk             => clk,
        addr            => bram_addr,
        we              => bram_we,
        wdata           => dcache_s_tdata,
        re              => bram_re,
        q               => dcache_tcache
    );

    bram_addr       <= dcache_s_taddr(CACHE_LINE_WIDTH downto 1);
    bram_we         <= '1' when dcache_s_tvalid = '1' and dcache_s_tready = '1' and dcache_s_tcmd = '1' and dcache_s_twidth = '1' and dcache_s_taddr(0) = '0' else '0';
    bram_re         <= '1' when (dcache_s_tvalid = '1' and dcache_s_tready = '1') else '0';

    -- assigns
    dcache_s_tready <= '1' when dcache_tvalid = '0' or (dcache_tvalid = '1' and dcache_tready = '1') else '0';

    dcache_m_tvalid <= dcache_tvalid;
    dcache_tready   <= dcache_m_tready;
    dcache_m_tcmd   <= dcache_tcmd;
    dcache_m_taddr  <= dcache_taddr;
    dcache_m_twidth <= dcache_twidth;
    dcache_m_tdata  <= dcache_tdata;
    dcache_m_thit   <= dcache_thit;
    dcache_m_tcache <= dcache_tcache;

    dcache_thit     <= '1' when dcache_valid = '1' and dcache_tag = m_tag and dcache_taddr(0) = '0' else '0';
    s_index         <= to_integer(unsigned(dcache_s_taddr(CACHE_LINE_WIDTH downto 1)));
    m_tag           <= dcache_taddr(19 downto CACHE_LINE_WIDTH-1);

    -- write cache
    write_cache_proc: process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                d_valid <= (others => '0');
            else
                if (dcache_s_tvalid = '1' and dcache_s_tready = '1' and dcache_s_tcmd = '1') then
                    if (dcache_s_twidth = '1' and dcache_s_taddr(0) = '0') then
                        d_valid(s_index) <= '1';
                    else
                        d_valid(s_index) <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- read from cache
    redirect_request_proc: process (clk) begin
        if rising_edge(clk) then
            -- resettable
            if resetn = '0' then
                dcache_tvalid <= '0';
            else
                if (dcache_s_tvalid = '1' and dcache_s_tready = '1') then
                    dcache_tvalid <= '1';
                elsif (dcache_tready = '1') then
                    dcache_tvalid <= '0';
                end if;
            end if;
            -- without reset
            if (dcache_s_tvalid = '1' and dcache_s_tready = '1') then
                dcache_valid <= d_valid(s_index);
            end if;

            if (dcache_s_tvalid = '1' and dcache_s_tready = '1') then
                dcache_tcmd   <= dcache_s_tcmd;
                dcache_taddr  <= dcache_s_taddr;
                dcache_twidth <= dcache_s_twidth;
                dcache_tdata  <= dcache_s_tdata;
            end if;
        end if;
    end process;

end architecture;
