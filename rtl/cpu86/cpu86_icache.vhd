
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

entity cpu86_icache is
    port (
        clk                       : in std_logic;
        resetn                    : in std_logic;

        s_axis_mem_req_tvalid     : in std_logic;
        s_axis_mem_req_tready     : out std_logic;
        s_axis_mem_req_tdata      : in std_logic_vector(19 downto 0);

        m_axis_mem_data_tvalid    : out std_logic;
        m_axis_mem_data_tdata     : out std_logic_vector(31 downto 0);

        m_axis_mem_req_tvalid     : out std_logic;
        m_axis_mem_req_tready     : in std_logic;
        m_axis_mem_req_tdata      : out std_logic_vector(19 downto 0);

        s_axis_mem_data_tvalid    : in std_logic;
        s_axis_mem_data_tdata     : in std_logic_vector(31 downto 0)
    );
end entity cpu86_icache;

architecture rtl of cpu86_icache is

    constant ROB_IDX_W          : natural := 4;
    constant CACHE_DATA_AW      : natural := 8;
    constant CACHE_TAG_AW       : natural := 12;

    subtype ROB_IDX_RANGE       is natural range ROB_IDX_W + CACHE_TAG_AW + CACHE_DATA_AW - 1 downto CACHE_TAG_AW + CACHE_DATA_AW;
    subtype CACHE_TAG_RANGE     is natural range CACHE_TAG_AW + CACHE_DATA_AW - 1 downto CACHE_DATA_AW;
    subtype CACHE_DATA_RANGE    is natural range CACHE_DATA_AW - 1 downto 0;

    component cpu86_icache_rob is
        generic (
            S_QTY                   : natural := 2;
            TDATA_WIDTH             : natural := 32;
            TUSER_WIDTH             : natural := 8
        );
        port (
            clk                     : in std_logic;
            resetn                  : in std_logic;
            m_axis_tag_tvalid       : out std_logic;
            m_axis_tag_tready       : in std_logic;
            m_axis_tag_tdata        : out std_logic_vector(TUSER_WIDTH-1 downto 0);

            s_axis_data_tvalid      : in std_logic_vector(S_QTY-1 downto 0);
            s_axis_data_tdata       : in std_logic_vector(S_QTY*TDATA_WIDTH-1 downto 0);
            s_axis_data_tuser       : in std_logic_vector(S_QTY*TDATA_WIDTH-1 downto 0);

            m_axis_data_tvalid      : out std_logic;
            m_axis_data_tready      : in std_logic;
            m_axis_data_tdata       : out std_logic_vector(TDATA_WIDTH-1 downto 0)
        );
    end component;

    signal cpu_req_tvalid       : std_logic;
    signal cpu_req_tready       : std_logic;
    signal cpu_req_tdata        : std_logic_vector(19 downto 0);

    signal cpu_res_tvalid       : std_logic;
    signal cpu_res_tdata        : std_logic_vector(31 downto 0);

    signal mem_req_tvalid       : std_logic;
    signal mem_req_tready       : std_logic;
    signal mem_req_tdata        : std_logic_vector(19 downto 0);
    signal mem_req_rob_idx      : std_logic_vector(ROB_IDX_W-1 downto 0);

    signal mem_res_tvalid       : std_logic;
    signal mem_res_tdata        : std_logic_vector(31 downto 0);

    signal cache_tvalid         : std_logic;
    signal cache_tready         : std_logic;
    signal cache_tag            : std_logic_vector(CACHE_TAG_AW-1 downto 0);
    signal cache_vld            : std_logic;
    signal cache_tdata          : std_logic_vector(31 downto 0);
    signal cache_taddr          : std_logic_vector(19 downto 0);
    signal fifo_0_s_tvalid      : std_logic;
    signal fifo_0_s_tready      : std_logic;
    signal fifo_0_m_tvalid      : std_logic;
    signal fifo_0_m_tag         : std_logic_vector(CACHE_TAG_AW-1 downto 0);
    signal fifo_0_m_addr        : std_logic_vector(CACHE_DATA_AW-1 downto 0);
    signal fifo_0_m_rob_idx     : std_logic_vector(ROB_IDX_W-1 downto 0);
    signal cache_line_vld       : std_logic_vector(255 downto 0);

    signal cache_hit            : std_logic;
    signal cache_rob_idx        : std_logic_vector(ROB_IDX_W-1 downto 0);

    signal rob_idx_tvalid       : std_logic;
    signal rob_idx_tready       : std_logic;
    signal rob_idx_tdata        : std_logic_vector(ROB_IDX_W-1 downto 0);

begin

    cpu_req_tvalid <= s_axis_mem_req_tvalid;
    s_axis_mem_req_tready <= cpu_req_tready;
    cpu_req_tdata <= s_axis_mem_req_tdata;

    m_axis_mem_data_tvalid <= cpu_res_tvalid;
    m_axis_mem_data_tdata <= cpu_res_tdata;

    mem_res_tvalid <= s_axis_mem_data_tvalid;
    mem_res_tdata <= s_axis_mem_data_tdata;


    -- module axis_reg instantiation
    axis_reg_mem_req_inst : entity work.axis_reg generic map (
        DATA_WIDTH      => 20
    ) port map (
        clk             => clk,
        resetn          => resetn,

        in_s_tvalid     => mem_req_tvalid,
        in_s_tready     => mem_req_tready,
        in_s_tdata      => mem_req_tdata,

        out_m_tvalid    => m_axis_mem_req_tvalid,
        out_m_tready    => m_axis_mem_req_tready,
        out_m_tdata     => m_axis_mem_req_tdata
    );


    axis_bram_inst : entity work.axis_bram generic map (
        ADDR_WIDTH                                    => 8,
        DATA_WIDTH                                    => CACHE_TAG_AW + 32,
        USER_WIDTH                                    => ROB_IDX_W + 1 + 20,
        REGISTER_OUTPUT                               => '1'
    ) port map (
        clk                                           => clk,
        resetn                                        => resetn,

        s_axis_wr_tvalid                              => mem_res_tvalid,
        s_axis_wr_taddr                               => fifo_0_m_addr,
        s_axis_wr_tdata(32+CACHE_TAG_AW-1 downto 32)  => fifo_0_m_tag,
        s_axis_wr_tdata(31 downto 0)                  => mem_res_tdata,

        s_axis_rd_tvalid                              => cpu_req_tvalid,
        s_axis_rd_tready                              => cpu_req_tready,
        s_axis_rd_taddr                               => cpu_req_tdata(7 downto 0),
        s_axis_rd_tuser(24 downto 21)                 => rob_idx_tdata,
        s_axis_rd_tuser(20)                           => cache_line_vld(to_integer(unsigned(cpu_req_tdata(7 downto 0)))),
        s_axis_rd_tuser(19 downto 0)                  => cpu_req_tdata,

        m_axis_res_tvalid                             => cache_tvalid,
        m_axis_res_tready                             => cache_tready,
        m_axis_res_tdata(32+CACHE_TAG_AW-1 downto 32) => cache_tag,
        m_axis_res_tdata(31 downto 0)                 => cache_tdata,
        m_axis_res_tuser(24 downto 21)                => cache_rob_idx,
        m_axis_res_tuser(20)                          => cache_vld,
        m_axis_res_tuser(19 downto 0)                 => cache_taddr
    );

    rob_idx_tready <= '1' when cpu_req_tvalid = '1' and cpu_req_tready = '1' else '0';
    cache_hit <= '1' when cache_tvalid = '1' and cache_tready = '1' and cache_vld = '1' and cache_tag = cache_taddr(19 downto 8) else '0';

    cpu86_icache_rob_inst : cpu86_icache_rob generic map(
        S_QTY                           => 2,
        TDATA_WIDTH                     => 32,
        TUSER_WIDTH                     => ROB_IDX_W
    ) port map (
        clk                             => clk,
        resetn                          => resetn,

        m_axis_tag_tvalid               => rob_idx_tvalid,
        m_axis_tag_tready               => rob_idx_tready,
        m_axis_tag_tdata                => rob_idx_tdata,

        s_axis_data_tvalid(0)           => cache_hit,
        s_axis_data_tvalid(1)           => mem_res_tvalid,

        s_axis_data_tdata(31 downto  0) => cache_tdata,
        s_axis_data_tdata(63 downto 32) => mem_res_tdata,

        s_axis_data_tuser( 3 downto  0) => cache_rob_idx,
        s_axis_data_tuser( 7 downto  4) => fifo_0_m_rob_idx,

        m_axis_data_tvalid              => cpu_res_tvalid,
        m_axis_data_tready              => '1',
        m_axis_data_tdata               => cpu_res_tdata
    );

    fifo_0_s_tvalid <= '1' when mem_req_tvalid = '1' and mem_req_tready = '1' else '0';

    -- module axis_fifo instantiation
    axis_fifo_inst_0 : entity work.axis_fifo_fwft generic map (
        FIFO_DEPTH                          => 16,
        FIFO_WIDTH                          => ROB_IDX_W + CACHE_TAG_AW + CACHE_DATA_AW,
        REGISTER_OUTPUT                     => '1'
    ) port map (
        clk                                 => clk,
        resetn                              => resetn,

        s_axis_fifo_tvalid                  => fifo_0_s_tvalid,
        s_axis_fifo_tready                  => fifo_0_s_tready,
        s_axis_fifo_tdata(ROB_IDX_RANGE)    => mem_req_rob_idx,
        s_axis_fifo_tdata(CACHE_TAG_RANGE)  => mem_req_tdata(19 downto 8),
        s_axis_fifo_tdata(CACHE_DATA_RANGE) => mem_req_tdata( 7 downto 0),

        m_axis_fifo_tvalid                  => fifo_0_m_tvalid,
        m_axis_fifo_tready                  => mem_res_tvalid,
        m_axis_fifo_tdata(ROB_IDX_RANGE)    => fifo_0_m_rob_idx,
        m_axis_fifo_tdata(CACHE_TAG_RANGE)  => fifo_0_m_tag,
        m_axis_fifo_tdata(CACHE_DATA_RANGE) => fifo_0_m_addr
    );

    cache_tready <= '1' when mem_req_tvalid = '0' or (mem_req_tvalid = '1' and mem_req_tready = '1') else '0';

    process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                cache_line_vld <= (others => '0');
            else
                if (mem_res_tvalid = '1') then
                    cache_line_vld(to_integer(unsigned(fifo_0_m_addr))) <= '1';
                end if;
            end if;
        end if;
    end process;

    process (clk) begin
        if rising_edge(clk) then
            -- control path
            if resetn = '0' then
                mem_req_tvalid <= '0';
            else
                if (cache_tvalid = '1' and cache_tready = '1') then
                    if (cache_vld = '0' or cache_tag /= cache_taddr(19 downto 8)) then
                        mem_req_tvalid <= '1';
                    else
                        mem_req_tvalid <= '0';
                    end if;
                elsif (mem_req_tready = '1') then
                    mem_req_tvalid <= '0';
                end if;
            end if;
            -- data path
            if (cache_tvalid = '1' and cache_tready = '1') then
                mem_req_tdata <= cache_taddr;
                mem_req_rob_idx <= cache_rob_idx;
            end if;
        end if;
    end process;

end architecture;
