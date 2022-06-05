
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

entity sdram_interconnect is
    generic (
        PORT_QTY                : natural := 2
    );
    port (
        clk                     : in std_logic;
        resetn                  : in std_logic;

        s_axis_port_req_tvalid  : in std_logic_vector(PORT_QTY-1 downto 0);
        s_axis_port_req_tready  : out std_logic_vector(PORT_QTY-1 downto 0);
        s_axis_port_req_tdata   : in std_logic_vector(64*PORT_QTY-1 downto 0);

        s_axis_sdram_res_tvalid : in std_logic;
        s_axis_sdram_res_tdata  : in std_logic_vector(31 downto 0);

        m_axis_sdram_req_tvalid : out std_logic;
        m_axis_sdram_req_tready : in std_logic;
        m_axis_sdram_req_tdata  : out std_logic_vector (63 downto 0);

        m_axis_port_res_tvalid  : out std_logic_vector(PORT_QTY-1 downto 0);
        m_axis_port_res_tdata   : out std_logic_vector(32*PORT_QTY-1 downto 0)
    );
end entity sdram_interconnect;

architecture rtl of sdram_interconnect is
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

    type req_array_t is array (natural range PORT_QTY-1 downto 0) of std_logic_vector(63 downto 0);
    type res_array_t is array (natural range PORT_QTY-1 downto 0) of std_logic_vector(31 downto 0);

    constant ALL_ZEROS : std_logic_vector(PORT_QTY-1 downto 0) := (others => '0') ;

    signal port_req_tvalid      : std_logic_vector(PORT_QTY-1 downto 0);
    signal port_req_tready      : std_logic_vector(PORT_QTY-1 downto 0);
    signal port_req_tdata       : req_array_t;

    signal port_req_sel         : natural range 0 to PORT_QTY-1;

    signal port_req_hs_map      : std_logic_vector(PORT_QTY-1 downto 0);
    signal port_read_rq_hs_map  : std_logic_vector(PORT_QTY-1 downto 0);
    signal fifo_s_tvalid        : std_logic;
    signal fifo_s_tready        : std_logic;
    signal fifo_s_tdata         : std_logic_vector(PORT_QTY-1 downto 0);
    signal fifo_m_tvalid        : std_logic;
    signal fifo_m_tdata         : std_logic_vector(PORT_QTY-1 downto 0);

    signal sdram_req_tvalid     : std_logic;
    signal sdram_req_tready     : std_logic;
    signal sdram_req_tdata      : std_logic_vector (63 downto 0);

    signal sdram_res_tvalid     : std_logic;
    signal sdram_res_tdata      : std_logic_vector(31 downto 0);

    signal port_res_tvalid      : std_logic_vector(PORT_QTY-1 downto 0);
    signal port_res_tdata       : res_array_t;

    function grant (req_vector : std_logic_vector) return integer is
        variable idx : natural range 0 to PORT_QTY-1;
    begin
        idx := PORT_QTY-1;

        for i in PORT_QTY-1 downto 0 loop
            if (req_vector(i) = '1') then
                idx := i;
            end if;
        end loop;
        return idx;
    end function;

begin

    -- io assigns
    port_req_io_gen : for i in 0 to PORT_QTY-1 generate
        port_req_tvalid(i)        <= s_axis_port_req_tvalid(i);
        s_axis_port_req_tready(i) <= port_req_tready(i);
        port_req_tdata(i)         <= s_axis_port_req_tdata((i+1)*64-1 downto i*64);
    end generate;

    sdram_res_tvalid              <= s_axis_sdram_res_tvalid;
    sdram_res_tdata               <= s_axis_sdram_res_tdata;

    m_axis_sdram_req_tvalid       <= sdram_req_tvalid;
    sdram_req_tready              <= m_axis_sdram_req_tready;
    m_axis_sdram_req_tdata        <= sdram_req_tdata;

    port_res_io_gen : for i in 0 to PORT_QTY-1 generate
        m_axis_port_res_tvalid(i) <= port_res_tvalid(i);
        m_axis_port_res_tdata((i+1)*32-1 downto i*32) <= port_res_tdata(i);
    end generate;

    -- Module axis_fifo instantiation
    axis_fifo_inst : axis_fifo generic map (
        FIFO_DEPTH      => 32,
        FIFO_WIDTH      => PORT_QTY
    ) port map (
        clk             => clk,
        resetn          => resetn,
        fifo_s_tvalid   => fifo_s_tvalid,
        fifo_s_tready   => fifo_s_tready,
        fifo_s_tdata    => fifo_s_tdata,
        fifo_m_tvalid   => fifo_m_tvalid,
        fifo_m_tready   => sdram_res_tvalid,
        fifo_m_tdata    => fifo_m_tdata
    );

    -- assigns
    port_req_sel <= grant(port_req_tvalid);

    port_req_ready_gen : for i in 0 to PORT_QTY-1 generate
        port_req_tready(i) <= '1' when port_req_sel = i and (sdram_req_tvalid = '0' or sdram_req_tready = '1') and (fifo_s_tready = '1') else '0';
    end generate;

    fifo_data_gen : for i in 0 to PORT_QTY-1 generate
        port_req_hs_map(i)      <= '1' when port_req_tvalid(i) = '1' and port_req_tready(i) = '1' else '0';
        port_read_rq_hs_map(i)  <= '1' when port_req_tvalid(i) = '1' and port_req_tready(i) = '1' and port_req_tdata(i)(57) = '0' else '0';
    end generate;

    port_res_gen : for i in 0 to PORT_QTY-1 generate
        port_res_tvalid(i)  <= '1' when sdram_res_tvalid = '1' and fifo_m_tdata(i) = '1' else '0';
        port_res_tdata(i)   <= sdram_res_tdata;
    end generate;

    -- register memory request
    process (clk) begin
        if rising_edge(clk) then
            -- resettable
            if resetn = '0' then
                sdram_req_tvalid <= '0';
            else
                if (port_req_hs_map /= ALL_ZEROS) then
                    sdram_req_tvalid <= '1';
                elsif (sdram_req_tready = '1') then
                    sdram_req_tvalid <= '0';
                end if;
            end if;
            -- not resettable logic
            for i in 0 to PORT_QTY-1 loop
                if (port_req_hs_map(i) = '1') then
                    sdram_req_tdata <= port_req_tdata(i);
                end if;
            end loop;
        end if;
    end process;

    -- register where to send response into the queue
    process (clk) begin
        if rising_edge(clk) then
            -- resettable
            if resetn = '0' then
                fifo_s_tvalid <= '0';
            else
                if (port_read_rq_hs_map /= ALL_ZEROS) then
                    fifo_s_tvalid <= '1';
                else
                    fifo_s_tvalid <= '0';
                end if;
            end if;
            -- not resettable logic
            fifo_s_tdata <= port_read_rq_hs_map;
        end if;
    end process;

end;
