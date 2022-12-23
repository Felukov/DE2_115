
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
use ieee.math_real.all;

entity cpu86_mem_interconnect is
    port (
        clk                             : in std_logic;
        resetn                          : in std_logic;

        mem_req_m_tvalid                : out std_logic;
        mem_req_m_tready                : in std_logic;
        mem_req_m_tdata                 : out std_logic_vector(63 downto 0);

        mem_rd_s_tvalid                 : in std_logic;
        mem_rd_s_tdata                  : in std_logic_vector(31 downto 0);

        fetcher_mem_req_tvalid          : in std_logic;
        fetcher_mem_req_tready          : out std_logic;
        fetcher_mem_req_tdata           : in std_logic_vector(17 downto 0);

        fetcher_mem_res_tvalid          : out std_logic;
        fetcher_mem_res_tdata           : out std_logic_vector(31 downto 0);

        exec_mem_req_tvalid             : in std_logic;
        exec_mem_req_tready             : out std_logic;
        exec_mem_req_tdata              : in std_logic_vector(63 downto 0);

        exec_mem_res_tvalid             : out std_logic;
        exec_mem_res_tdata              : out std_logic_vector(31 downto 0)
    );
end entity cpu86_mem_interconnect;

architecture rtl of cpu86_mem_interconnect is

    signal fifo_s_tvalid        : std_logic;
    signal fifo_s_tready        : std_logic;
    signal fifo_s_tdata         : std_logic_vector(1 downto 0);
    signal fifo_m_tvalid        : std_logic;
    signal fifo_m_tdata         : std_logic_vector(1 downto 0);

    signal exec_mem_req_read    : std_logic;

begin

    -- Module axis_fifo instantiation
    axis_fifo_inst : entity work.axis_fifo_fwft generic map (
        FIFO_DEPTH          => 32,
        FIFO_WIDTH          => 2,
        REGISTER_OUTPUT     => '1'
    ) port map (
        clk                 => clk,
        resetn              => resetn,

        s_axis_fifo_tvalid  => fifo_s_tvalid,
        s_axis_fifo_tready  => fifo_s_tready,
        s_axis_fifo_tdata   => fifo_s_tdata,

        m_axis_fifo_tvalid  => fifo_m_tvalid,
        m_axis_fifo_tready  => mem_rd_s_tvalid,
        m_axis_fifo_tdata   => fifo_m_tdata
    );

    -- Assigns
    exec_mem_req_read       <= '1' when exec_mem_req_tdata(57) = '0' else '0';

    fetcher_mem_req_tready  <= '1' when exec_mem_req_tvalid = '0' and fifo_s_tready = '1' and
        (mem_req_m_tvalid = '0' or mem_req_m_tready = '1') else '0';

    exec_mem_req_tready     <= '1' when fifo_s_tready = '1' and
        (mem_req_m_tvalid = '0' or mem_req_m_tready = '1') else '0';

    fetcher_mem_res_tvalid  <= '1' when mem_rd_s_tvalid = '1' and fifo_m_tdata(1) = '1' else '0';
    fetcher_mem_res_tdata   <= mem_rd_s_tdata;

    exec_mem_res_tvalid     <= '1' when mem_rd_s_tvalid = '1' and fifo_m_tdata(0) = '1' else '0';
    exec_mem_res_tdata      <= mem_rd_s_tdata;

    -- register memory request
    process (clk) begin
        if rising_edge(clk) then
            -- resettable
            if resetn = '0' then
                mem_req_m_tvalid <= '0';
            else
                if (exec_mem_req_tvalid = '1' or fetcher_mem_req_tvalid = '1') and (fifo_s_tready = '1') then
                    mem_req_m_tvalid <= '1';
                elsif (mem_req_m_tready = '1') then
                    mem_req_m_tvalid <= '0';
                end if;
            end if;
            -- not resettable logic
            if (exec_mem_req_tvalid = '1' and exec_mem_req_tready = '1') then
                mem_req_m_tdata <= exec_mem_req_tdata;
            elsif (fetcher_mem_req_tvalid = '1' and fetcher_mem_req_tready = '1') then
                mem_req_m_tdata(63 downto 62) <= (others => '0');
                mem_req_m_tdata(61 downto 58) <= "0000";
                mem_req_m_tdata(57)           <= '0';
                mem_req_m_tdata(56 downto 32) <= "0000000" & fetcher_mem_req_tdata;
                mem_req_m_tdata(31 downto 0)  <= (others => '0');
            end if;
        end if;
    end process;

    -- register where to send response into the queue
    process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                fifo_s_tvalid <= '0';
            else
                if ((exec_mem_req_tvalid = '1' and exec_mem_req_tready = '1' and exec_mem_req_read = '1') or
                    (fetcher_mem_req_tvalid = '1' and fetcher_mem_req_tready = '1')) then
                    fifo_s_tvalid <= '1';
                else
                    fifo_s_tvalid <= '0';
                end if;
            end if;

            if (exec_mem_req_tvalid = '1' and exec_mem_req_tready = '1' and exec_mem_req_read = '1') then
                fifo_s_tdata(1) <= '0';
                fifo_s_tdata(0) <= '1';
            elsif (fetcher_mem_req_tvalid = '1' and fetcher_mem_req_tready = '1') then
                fifo_s_tdata(1) <= '1';
                fifo_s_tdata(0) <= '0';
            end if;
        end if;
    end process;

end architecture;
