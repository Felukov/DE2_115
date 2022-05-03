
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
use ieee.math_real.all;

entity soc_mmu is
    port (
        clk                         : in std_logic;
        resetn                      : in std_logic;

        s_axis_io_req_tvalid        : in std_logic;
        s_axis_io_req_tready        : out std_logic;
        s_axis_io_req_tdata         : in std_logic_vector(39 downto 0);

        m_axis_io_res_tvalid        : out std_logic;
        m_axis_io_res_tready        : in std_logic;
        m_axis_io_res_tdata         : out std_logic_vector(15 downto 0);

        s_axis_mem_req_tvalid       : in std_logic;
        s_axis_mem_req_tready       : out std_logic;
        s_axis_mem_req_tdata        : in std_logic_vector(63 downto 0);

        m_axis_mem_res_tvalid       : out std_logic;
        m_axis_mem_res_tdata        : out std_logic_vector(31 downto 0);

        m_axis_sdram_req_tvalid     : out std_logic;
        m_axis_sdram_req_tready     : in std_logic;
        m_axis_sdram_req_tdata      : out std_logic_vector(63 downto 0);

        s_axis_sdram_res_tvalid     : in std_logic;
        s_axis_sdram_res_tdata      : in std_logic_vector(31 downto 0);

        m_axis_bram_req_tvalid      : out std_logic;
        m_axis_bram_req_tready      : in std_logic;
        m_axis_bram_req_tdata       : out std_logic_vector(63 downto 0);

        s_axis_bram_res_tvalid      : in std_logic;
        s_axis_bram_res_tdata       : in std_logic_vector(31 downto 0)
    );
end entity soc_mmu;

architecture rtl of soc_mmu is

    component axis_fifo is
        generic (
            FIFO_DEPTH          : natural := 8;
            FIFO_WIDTH          : natural := 128
        );
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            fifo_s_tvalid       : in std_logic;
            fifo_s_tready       : out std_logic;
            fifo_s_tdata        : in std_logic_vector(FIFO_WIDTH-1 downto 0);

            fifo_m_tvalid       : out std_logic;
            fifo_m_tready       : in std_logic;
            fifo_m_tdata        : out std_logic_vector(FIFO_WIDTH-1 downto 0)
        );
    end component;


    constant MAP_RECORD_CNT : natural := 32;
    constant MAP_SLOT_WIDTH : integer := integer(ceil(log2(real(MAP_RECORD_CNT))));

    type map_record_t is record
        hi_addr     : std_logic_vector(11 downto 0);
        target      : std_logic;
    end record;

    type map_t is array (natural range 0 to MAP_RECORD_CNT-1) of map_record_t;

    type mem_req_addrs_t is array (natural range 0 to MAP_RECORD_CNT) of std_logic_vector(24 downto 0);

    type config_state_t is (
        ST_IDLE,
        ST_OFFSET,
        ST_TARGET,
        ST_APPLY);

    signal io_req_tvalid        : std_logic;
    signal io_req_tready        : std_logic;
    signal io_req_tdata         : std_logic_vector(39 downto 0);

    signal io_res_tvalid        : std_logic;
    signal io_res_tready        : std_logic;
    signal io_res_tdata         : std_logic_vector(15 downto 0);

    signal mem_req_tvalid       : std_logic;
    signal mem_req_tready       : std_logic;
    signal mem_req_tdata        : std_logic_vector(63 downto 0);
    signal mem_req_addr         : std_logic_vector(24 downto 0);
    signal mem_req_new_addr     : std_logic_vector(24 downto 0);
    signal mem_req_target       : std_logic;
    signal mem_req_slot         : natural range 0 to MAP_RECORD_CNT-1;

    signal mem_res_tvalid       : std_logic;
    signal mem_res_tdata        : std_logic_vector(31 downto 0);

    signal sdram_req_tvalid     : std_logic;
    signal sdram_req_tready     : std_logic;
    signal sdram_req_tdata      : std_logic_vector(63 downto 0);

    signal sdram_res_tvalid     : std_logic;
    signal sdram_res_tdata      : std_logic_vector(31 downto 0);

    signal bram_req_tvalid      : std_logic;
    signal bram_req_tready      : std_logic;
    signal bram_req_tdata       : std_logic_vector(63 downto 0);

    signal bram_res_s_tvalid    : std_logic;
    signal bram_res_s_tready    : std_logic;
    signal bram_res_s_tdata     : std_logic_vector(31 downto 0);

    signal bram_res_m_tvalid    : std_logic;
    signal bram_res_m_tready    : std_logic;
    signal bram_res_m_tdata     : std_logic_vector(31 downto 0);

    signal fifo_s_tvalid        : std_logic;
    signal fifo_s_tready        : std_logic;
    signal fifo_s_tdata         : std_logic_vector(0 downto 0);
    signal fifo_m_tvalid        : std_logic;
    signal fifo_m_tdata         : std_logic_vector(0 downto 0);

    signal config_state         : config_state_t;
    signal config_record        : map_record_t;
    signal config_slot          : natural range 0 to MAP_RECORD_CNT-1;

    signal map_data             : map_t;

    signal io_req_read          : std_logic;
    signal io_req_write         : std_logic;

    signal event_bram_req       : std_logic;
    signal event_bram_res       : std_logic;
    signal bram_trans_cnt       : natural range 0 to 7;

begin

    -- i/o assigns
    io_req_tvalid           <= s_axis_io_req_tvalid;
    s_axis_io_req_tready    <= io_req_tready;
    io_req_tdata            <= s_axis_io_req_tdata;

    m_axis_io_res_tvalid    <= io_res_tvalid;
    io_res_tready           <= m_axis_io_res_tready;
    m_axis_io_res_tdata     <= io_res_tdata;

    mem_req_tvalid          <= s_axis_mem_req_tvalid;
    s_axis_mem_req_tready   <= mem_req_tready;
    mem_req_tdata           <= s_axis_mem_req_tdata;

    m_axis_mem_res_tvalid   <= mem_res_tvalid;
    m_axis_mem_res_tdata    <= mem_res_tdata;

    m_axis_sdram_req_tvalid <= sdram_req_tvalid;
    sdram_req_tready        <= m_axis_sdram_req_tready;
    m_axis_sdram_req_tdata  <= sdram_req_tdata;

    sdram_res_tvalid        <= s_axis_sdram_res_tvalid;
    sdram_res_tdata         <= s_axis_sdram_res_tdata;

    m_axis_bram_req_tvalid  <= '1' when bram_req_tvalid = '1' and bram_req_tready = '1' else '0';
    m_axis_bram_req_tdata   <= bram_req_tdata;

    bram_res_s_tvalid       <= s_axis_bram_res_tvalid;
    bram_res_s_tdata        <= s_axis_bram_res_tdata;


    -- Module axis_fifo instantiation
    axis_fifo_res_target_inst : axis_fifo generic map (
        FIFO_DEPTH          => 32,
        FIFO_WIDTH          => 1
    ) port map (
        clk                 => clk,
        resetn              => resetn,
        fifo_s_tvalid       => fifo_s_tvalid,
        fifo_s_tready       => fifo_s_tready,
        fifo_s_tdata        => fifo_s_tdata,
        fifo_m_tvalid       => fifo_m_tvalid,
        fifo_m_tready       => mem_res_tvalid,
        fifo_m_tdata        => fifo_m_tdata
    );


    -- Module axis_fifo instantiation
    axis_fifo_bram_res_0_inst : axis_fifo generic map (
        FIFO_DEPTH          => 8,
        FIFO_WIDTH          => 32
    ) port map (
        clk                 => clk,
        resetn              => resetn,
        fifo_s_tvalid       => bram_res_s_tvalid,
        fifo_s_tready       => bram_res_s_tready,
        fifo_s_tdata        => bram_res_s_tdata,
        fifo_m_tvalid       => bram_res_m_tvalid,
        fifo_m_tready       => bram_res_m_tready,
        fifo_m_tdata        => bram_res_m_tdata
    );


    -- assigns
    io_req_read             <= '1' when io_req_tvalid = '1' and io_req_tready = '1' and io_req_tdata(32) = '0' else '0';
    io_req_write            <= '1' when io_req_tvalid = '1' and io_req_tready = '1' and io_req_tdata(32) = '1' else '0';
    io_req_tready           <= '1';

    mem_req_tready          <= '1' when
        (mem_req_tvalid = '1' and bram_req_tready = '1' and mem_req_target = '0') or
        (mem_req_tvalid = '1' and sdram_req_tready = '1' and mem_req_target = '1')
    else '0';

    mem_req_addr            <= mem_req_tdata(56 downto 32);
    mem_req_slot            <= to_integer(unsigned(mem_req_addr(17 downto 13)));
    mem_req_new_addr        <= map_data(mem_req_slot).hi_addr & mem_req_addr(12 downto 0);
    mem_req_target          <= map_data(mem_req_slot).target;

    fifo_s_tvalid           <= '1' when mem_req_tvalid = '1' and mem_req_tready = '1' and mem_req_tdata(57) = '0' else '0';
    fifo_s_tdata(0)         <= mem_req_target;

    bram_res_m_tready       <= '1' when (bram_res_m_tvalid = '1' and fifo_m_tvalid = '1' and fifo_m_tdata(0) = '0') else '0';
    mem_res_tvalid          <= '1' when (sdram_res_tvalid = '1' and fifo_m_tdata(0) = '1') or (bram_res_m_tvalid = '1' and fifo_m_tvalid = '1' and fifo_m_tdata(0) = '0') else '0';
    mem_res_tdata           <= sdram_res_tdata when fifo_m_tdata(0) = '1' else bram_res_m_tdata;

    event_bram_req       <= '1' when mem_req_tvalid = '1' and bram_req_tready = '1' and mem_req_target = '0' and mem_req_tdata(57) = '0' else '0';
    event_bram_res       <= '1' when bram_res_m_tvalid = '1' and bram_res_m_tready = '1' else '0';

    -- loading new config into temporary buffer
    loading_cfg_proc: process (clk) begin
        if rising_edge(clk) then
            -- resettable logic
            if resetn = '0' then
                config_state <= ST_IDLE;
            else
                case config_state is
                    when ST_IDLE =>
                        if (io_req_write = '1') then
                            config_state <= ST_OFFSET;
                        end if;

                    when ST_OFFSET =>
                        if (io_req_write = '1') then
                            config_state <= ST_TARGET;
                        end if;

                    when ST_TARGET =>
                        if (io_req_write = '1') then
                            config_state <= ST_APPLY;
                        end if;

                    when ST_APPLY =>
                        config_state <= ST_IDLE;

                end case;
            end if;
            -- without reset
            if (config_state = ST_IDLE and io_req_write = '1') then
                config_slot <= to_integer(unsigned(io_req_tdata(MAP_SLOT_WIDTH-1 downto 0)));
            end if;

            case config_state is
                when ST_OFFSET =>
                    if (io_req_write = '1') then
                        config_record.hi_addr <= io_req_tdata(11 downto 0);
                    end if;

                when ST_TARGET =>
                    if (io_req_write = '1') then
                        config_record.target <= io_req_tdata(0);
                    end if;

                when others =>
                    null;
            end case;

        end if;
    end process;

    -- read process
    read_proc: process (clk) begin
        if rising_edge(clk) then
            -- Resettable
            if resetn = '0' then
                io_res_tvalid <= '0';
            else
                if (io_req_tvalid = '1' and io_req_tready = '1' and io_req_read = '1') then
                    io_res_tvalid <= '1';
                elsif io_res_tready = '1' then
                    io_res_tvalid <= '0';
                end if;
            end if;
            -- Without reset
            if (io_req_tvalid = '1' and io_req_tready = '1' and io_req_read = '1') then
                io_res_tdata <= x"0000";
            end if;
        end if;
    end process;

    -- update memory map
    upd_mem_map_proc: process (clk)
        function slv (a : integer) return std_logic_vector is begin
            return std_logic_vector(to_unsigned(a, 12));
        end function;
    begin
        if rising_edge(clk) then
            -- resettable logic
            if resetn = '0' then
                map_data(0).hi_addr  <= slv(16#000#); --0x00000000
                map_data(1).hi_addr  <= slv(16#001#); --0x00008000
                map_data(2).hi_addr  <= slv(16#002#); --0x00010000
                map_data(3).hi_addr  <= slv(16#003#); --0x00018000
                map_data(4).hi_addr  <= slv(16#004#); --0x00020000
                map_data(5).hi_addr  <= slv(16#005#); --0x00028000
                map_data(6).hi_addr  <= slv(16#006#); --0x00030000
                map_data(7).hi_addr  <= slv(16#007#); --0x00038000
                map_data(8).hi_addr  <= slv(16#008#); --0x00040000
                map_data(9).hi_addr  <= slv(16#009#); --0x00048000
                map_data(10).hi_addr <= slv(16#00a#); --0x00050000 -- VGA seg 1
                map_data(11).hi_addr <= slv(16#00b#); --0x00058000 -- VGA seg 2
                map_data(12).hi_addr <= slv(16#012#); --0x00060000
                map_data(13).hi_addr <= slv(16#013#); --0x00068000
                map_data(14).hi_addr <= slv(16#014#); --0x00070000
                map_data(15).hi_addr <= slv(16#015#); --0x00078000
                map_data(16).hi_addr <= slv(16#016#); --0x00080000 -- HMA
                map_data(17).hi_addr <= slv(16#001#); --0x00088000
                map_data(18).hi_addr <= slv(16#002#); --0x00090000
                map_data(19).hi_addr <= slv(16#003#); --0x00098000
                map_data(20).hi_addr <= slv(16#004#); --0x000A0000 -- VGA seg 1
                map_data(21).hi_addr <= slv(16#005#); --0x000A8000 -- VGA seg 2
                map_data(22).hi_addr <= slv(16#006#); --0x000B0000
                map_data(23).hi_addr <= slv(16#007#); --0x000B8000
                map_data(24).hi_addr <= slv(16#008#); --0x000C0000
                map_data(25).hi_addr <= slv(16#009#); --0x000C8000
                map_data(26).hi_addr <= slv(16#00a#); --0x000D0000 -- VGA seg 2
                map_data(27).hi_addr <= slv(16#00b#); --0x000D8000 -- VGA seg 3
                map_data(28).hi_addr <= slv(16#00c#); --0x000E0000 -- VGA seg 4
                map_data(29).hi_addr <= slv(16#00d#); --0x000E8000 -- VGA seg 5
                map_data(30).hi_addr <= slv(16#00e#); --0x000F0000 -- VGA seg 6
                map_data(31).hi_addr <= slv(16#00f#); --0x000F8000 -- VGA seg 7

                map_data(0).target  <= '0';
                for i in 1 to 31 loop
                    map_data(i).target  <= '0';
                end loop;
            else
                if (config_state = ST_APPLY) then
                    map_data(config_slot) <= config_record;
                end if;
            end if;
            -- without reset
        end if;
    end process;

    bram_req_proc: process (clk) begin
        if rising_edge(clk) then
            -- resettable logic
            if resetn = '0' then
                bram_req_tvalid <= '0';
            else
                if (mem_req_tvalid = '1' and mem_req_tready = '1' and mem_req_target = '0') then
                    bram_req_tvalid <= '1';
                elsif (bram_req_tready = '1') then
                    bram_req_tvalid <= '0';
                end if;
            end if;
            -- without reset
            if (mem_req_tvalid = '1' and mem_req_tready = '1' and mem_req_target = '0') then
                bram_req_tdata(63 downto 62) <= (others => '0');
                bram_req_tdata(61 downto 58) <= mem_req_tdata(61 downto 58);
                bram_req_tdata(57)           <= mem_req_tdata(57);
                bram_req_tdata(56 downto 32) <= mem_req_new_addr;
                bram_req_tdata(31 downto 0)  <= mem_req_tdata(31 downto 0);
            end if;
        end if;
    end process;

    bram_resp_monitor_proc : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                bram_req_tready <= '1';
                bram_trans_cnt <= 0;
            else
                if (event_bram_req = '1' and event_bram_res = '0') then
                    bram_trans_cnt <= bram_trans_cnt + 1;
                elsif (event_bram_req = '0' and event_bram_res = '1') then
                    bram_trans_cnt <= bram_trans_cnt - 1;
                end if;

                if (event_bram_req = '1' and event_bram_res = '0') then
                    if (bram_trans_cnt = 6) then
                        bram_req_tready <= '0';
                    end if;
                elsif (event_bram_req = '0' and event_bram_res = '1') then
                    if (bram_trans_cnt = 6) then
                        bram_req_tready <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;

    sdram_req_proc: process (clk) begin
        if rising_edge(clk) then
            -- resettable logic
            if resetn = '0' then
                sdram_req_tvalid <= '0';
            else
                if (mem_req_tvalid = '1' and mem_req_tready = '1' and mem_req_target = '1') then
                    sdram_req_tvalid <= '1';
                elsif (sdram_req_tready = '1') then
                    sdram_req_tvalid <= '0';
                end if;
            end if;
            -- without reset
            if (mem_req_tvalid = '1' and mem_req_tready = '1' and mem_req_target = '1') then
                sdram_req_tdata(63 downto 62) <= (others => '0');
                sdram_req_tdata(61 downto 58) <= mem_req_tdata(61 downto 58);
                sdram_req_tdata(57)           <= mem_req_tdata(57);
                sdram_req_tdata(56 downto 32) <= mem_req_new_addr;
                sdram_req_tdata(31 downto 0)  <= mem_req_tdata(31 downto 0);
            end if;
        end if;
    end process;

end architecture;
