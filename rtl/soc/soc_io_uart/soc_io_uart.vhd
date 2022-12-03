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
use ieee.numeric_std.all;
use ieee.math_real.all;

entity soc_io_uart is
    generic (
        FREQ                    : integer := 100_000_000;
        RATE                    : integer := 115_200;
        RX_FIFO_SIZE            : integer := 16;
        TX_FIFO_SIZE            : integer := 16
    );
    port (
        clk                     : in std_logic;
        resetn                  : in std_logic;

        io_req_s_tvalid         : in std_logic;
        io_req_s_tready         : out std_logic;
        io_req_s_tdata          : in std_logic_vector(39 downto 0);

        io_rd_m_tvalid          : out std_logic;
        io_rd_m_tready          : in std_logic;
        io_rd_m_tdata           : out std_logic_vector(15 downto 0);

        rx                      : in std_logic;
        tx                      : out std_logic
    );
end entity soc_io_uart;

architecture rtl of soc_io_uart is

    component soc_io_uart_tx is
        generic (
            FREQ                : integer := 100_000_000;
            RATE                : integer := 115_200
        );
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            tx_s_tvalid         : in std_logic;
            tx_s_tready         : out std_logic;
            tx_s_tdata          : in std_logic_vector(7 downto 0);

            tx                  : out std_logic
        );
    end component soc_io_uart_tx;

    component soc_io_uart_rx is
        generic (
            FREQ                : integer := 100_000_000;
            RATE                : integer := 115_200
        );
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            rx_m_tvalid         : out std_logic;
            rx_m_tdata          : out std_logic_vector(7 downto 0);

            rx                  : in std_logic
        );
    end component soc_io_uart_rx;

    -- component signal_tap is
    --     port (
    --         acq_data_in    : in std_logic_vector(15 downto 0) := (others => 'X'); -- acq_data_in
    --         acq_trigger_in : in std_logic_vector(0 downto 0)  := (others => 'X'); -- acq_trigger_in
    --         acq_clk        : in std_logic                     := 'X';             -- clk
    --         storage_enable : in std_logic                     := 'X'              -- storage_enable
    --     );
    -- end component signal_tap;

    signal rx_tvalid            : std_logic;
    signal rx_tdata             : std_logic_vector(7 downto 0);

    signal rx_ff                : std_logic_vector(2 downto 0);

    signal io_read              : std_logic;
    signal io_address           : std_logic_vector(15 downto 0);
    signal io_write             : std_logic;

    signal io_read_rd_fifo_ready: std_logic;
    signal io_read_wr_fifo_ready: std_logic;
    signal io_read_rd_fifo_data : std_logic;

    signal rx_fifo_m_tvalid     : std_logic;
    signal rx_fifo_m_tready     : std_logic;
    signal rx_fifo_m_tdata      : std_logic_vector(7 downto 0);

    signal tx_fifo_s_tvalid     : std_logic;
    signal tx_fifo_s_tready     : std_logic;
    signal tx_fifo_s_tdata      : std_logic_vector(7 downto 0);

    signal tx_fifo_m_tvalid     : std_logic;
    signal tx_fifo_m_tready     : std_logic;
    signal tx_fifo_m_tdata      : std_logic_vector(7 downto 0);

    -- signal acq_data_in          : std_logic_vector(15 downto 0);
    -- signal acq_trigger_in       : std_logic_vector(0 downto 0);
    -- signal storage_enable       : std_logic;

begin

    -- module soc_io_uart_rx instantiation
    uart_rx_inst : soc_io_uart_rx generic map (
        FREQ                => FREQ,
        RATE                => RATE
    ) port map (
        clk                 => clk,
        resetn              => resetn,

        rx                  => rx_ff(2),

        rx_m_tvalid         => rx_tvalid,
        rx_m_tdata          => rx_tdata
    );

    -- module axis_fifo instantiation
    axis_fifo_inst_0 : entity work.axis_fifo_er generic map (
        FIFO_DEPTH          => RX_FIFO_SIZE,
        FIFO_WIDTH          => 8
    ) port map (
        clk                 => clk,
        resetn              => resetn,

        s_axis_fifo_tvalid  => rx_tvalid,
        s_axis_fifo_tready  => open,
        s_axis_fifo_tdata   => rx_tdata,

        m_axis_fifo_tvalid  => rx_fifo_m_tvalid,
        m_axis_fifo_tready  => rx_fifo_m_tready,
        m_axis_fifo_tdata   => rx_fifo_m_tdata
    );

    -- acq_data_in(15 downto 10) <= (others => '0');
    -- acq_data_in( 9 downto  9) <= (others => rx_fifo_m_tvalid);
    -- acq_data_in( 8 downto  8) <= (others => rx_fifo_m_tready);
    -- acq_data_in( 7 downto  0) <= rx_fifo_m_tdata;

    -- acq_trigger_in(0) <= '1' when rx_fifo_m_tvalid = '1' and rx_fifo_m_tready = '1' else '0';
    -- storage_enable    <= '1' when rx_fifo_m_tvalid = '1' and rx_fifo_m_tready = '1' else '0';

    -- u0 : component signal_tap port map (
    --     acq_clk         => clk,            -- acq_clk
    --     acq_data_in     => acq_data_in,    -- acq_data_in
    --     acq_trigger_in  => acq_trigger_in, -- acq_trigger_in
    --     storage_enable  => storage_enable  -- storage_enable
    -- );

    -- module axis_fifo instantiation
    axis_fifo_inst_1 : entity work.axis_fifo_er generic map (
        FIFO_DEPTH          => TX_FIFO_SIZE,
        FIFO_WIDTH          => 8
    ) port map (
        clk                 => clk,
        resetn              => resetn,

        s_axis_fifo_tvalid  => tx_fifo_s_tvalid,
        s_axis_fifo_tready  => tx_fifo_s_tready,
        s_axis_fifo_tdata   => tx_fifo_s_tdata,

        m_axis_fifo_tvalid  => tx_fifo_m_tvalid,
        m_axis_fifo_tready  => tx_fifo_m_tready,
        m_axis_fifo_tdata   => tx_fifo_m_tdata
    );

    -- module soc_io_uart_tx instantiation
    uart_tx_inst : soc_io_uart_tx generic map (
        FREQ                => FREQ,
        RATE                => RATE
    ) port map (
        clk                 => clk,
        resetn              => resetn,

        tx_s_tvalid         => tx_fifo_m_tvalid,
        tx_s_tready         => tx_fifo_m_tready,
        tx_s_tdata          => tx_fifo_m_tdata,

        tx                  => tx
    );

    -- assigns
    rx_fifo_m_tready <= '1' when io_req_s_tvalid = '1' and io_req_s_tready = '1' and
        io_read = '1' and io_read_rd_fifo_data = '1' else '0';

    io_read    <= '1' when io_req_s_tvalid = '1' and io_req_s_tready = '1' and io_req_s_tdata(32) = '0' else '0';
    io_write   <= '1' when io_req_s_tvalid = '1' and io_req_s_tready = '1' and io_req_s_tdata(32) = '1' else '0';
    io_address <= io_req_s_tdata(31 downto 16);

    io_read_rd_fifo_data  <= '1' when io_address(3 downto 0) = x"0" else '0';
    io_read_rd_fifo_ready <= '1' when io_address(3 downto 0) = x"1" else '0';
    io_read_wr_fifo_ready <= '1' when io_address(3 downto 0) = x"2" else '0';

    io_req_s_tready <= '1';


    process (clk) begin
        if rising_edge(clk) then
            rx_ff(0) <= rx;
            rx_ff(1) <= rx_ff(0);
            rx_ff(2) <= rx_ff(1);
        end if;
    end process;

    read_proc : process (clk) begin
        if rising_edge(clk) then
            -- resettable
            if resetn = '0' then
                io_rd_m_tvalid <= '0';
            else
                if (io_req_s_tvalid = '1' and io_req_s_tready = '1' and io_read = '1') then
                    io_rd_m_tvalid <= '1';
                elsif (io_rd_m_tready = '1') then
                    io_rd_m_tvalid <= '0';
                end if;
            end if;

            --without reset
            if (io_req_s_tvalid = '1' and io_req_s_tready = '1' and io_read = '1') then
                -- forming hi
                io_rd_m_tdata(15 downto 9) <= (others => '0');

                if (rx_fifo_m_tvalid = '1' and rx_fifo_m_tready = '1') then
                    io_rd_m_tdata(8) <= '1';
                else
                    io_rd_m_tdata(8) <= '0';
                end if;

                -- forming lo
                if (io_read_rd_fifo_data = '1') then
                    io_rd_m_tdata(7 downto 0) <= rx_fifo_m_tdata;
                elsif (io_read_rd_fifo_ready = '1') then
                    io_rd_m_tdata(7 downto 1) <= (others => '0');
                    io_rd_m_tdata(0) <= rx_fifo_m_tvalid;
                elsif (io_read_wr_fifo_ready = '1') then
                    io_rd_m_tdata(7 downto 1) <= (others => '0');
                    io_rd_m_tdata(0) <= tx_fifo_s_tready;
                end if;

            end if;
        end if;
    end process;

    write_proc : process (clk) begin
        if rising_edge(clk) then
            -- resettable
            if resetn = '0' then
                tx_fifo_s_tvalid <= '0';
            else
                if (io_req_s_tvalid = '1' and io_req_s_tready = '1' and io_write = '1') then
                    tx_fifo_s_tvalid <= '1';
                elsif (tx_fifo_s_tready = '1') then
                    tx_fifo_s_tvalid <= '0';
                end if;
            end if;

            --without reset
            if (io_req_s_tvalid = '1' and io_req_s_tready = '1' and io_write = '1') then
                tx_fifo_s_tdata <= io_req_s_tdata(7 downto 0);
            end if;

        end if;
    end process;

end architecture;
