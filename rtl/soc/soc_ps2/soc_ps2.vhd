-- Copyright (C) 2022, Konstantin Felukov
-- All rights reserved.
--
-- Copyright 2011, Kevin Lindsey
-- See LICENSE file for licensing information
--
-- Based on code from P. P. Chu, "FPGA Prototyping by VHDL Examples: Xilinx Spartan-3 Version", 2008
-- Chapters 9
--
library ieee;
use ieee.std_logic_1164.all;

entity soc_ps2 is
    port(
        clk                     : in std_logic;
        resetn                  : in std_logic;

        -- cpu io
        s_axis_io_req_tvalid    : in std_logic;
        s_axis_io_req_tready    : out std_logic;
        s_axis_io_req_tdata     : in std_logic_vector(39 downto 0);
        m_axis_io_res_tvalid    : out std_logic;
        m_axis_io_res_tready    : in std_logic;
        m_axis_io_res_tdata     : out std_logic_vector(15 downto 0);

        -- interrupt request
        event_kb_int_req        : out std_logic;

        -- PS2
        ps2d                    : inout std_logic;
        ps2c                    : inout std_logic
    );
end soc_ps2;

architecture rtl of soc_ps2 is

    component signal_tap is
        port (
            acq_data_in    : in std_logic_vector(31 downto 0) := (others => 'X'); -- acq_data_in
            acq_trigger_in : in std_logic_vector(0 downto 0)  := (others => 'X'); -- acq_trigger_in
            acq_clk        : in std_logic                     := 'X';             -- clk
            storage_enable : in std_logic                     := 'X'              -- storage_enable
        );
    end component signal_tap;

    signal tx_idle              : std_logic;
    signal wr_ps2               : std_logic;
    signal din                  : std_logic_vector(7 downto 0);
    signal dout                 : std_logic_vector(7 downto 0);
    signal rx_done_tick         : std_logic;
    signal tx_done_tick         : std_logic;

    signal io_req_tvalid        : std_logic;
    signal io_req_tready        : std_logic;
    signal io_req_tdata         : std_logic_vector(39 downto 0);

    signal io_rd_tvalid         : std_logic;
    signal io_rd_tready         : std_logic;
    signal io_rd_tdata          : std_logic_vector(15 downto 0);

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

    signal ps2d_ff_0            : std_logic;
    signal ps2d_ff_1            : std_logic;
    signal ps2c_ff_0            : std_logic;
    signal ps2c_ff_1            : std_logic;
    signal rx_en_ff_0           : std_logic;
    signal rx_en_ff_1           : std_logic;
begin

    -- i/o assigns
    io_req_tvalid           <= s_axis_io_req_tvalid;
    s_axis_io_req_tready    <= io_req_tready;
    io_req_tdata            <= s_axis_io_req_tdata;

    m_axis_io_res_tvalid    <= io_rd_tvalid;
    io_rd_tready            <= m_axis_io_res_tready;
    m_axis_io_res_tdata     <= io_rd_tdata;

    -- module axis_fifo instantiation
    axis_fifo_tx_inst : entity work.axis_fifo_er generic map (
        FIFO_DEPTH          => 16,
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

    -- module soc_ps2_tx instantiation
    ps2_tx_unit: entity work.soc_ps2_tx port map(
        clk                 => clk,
        resetn              => resetn,
        wr_ps2              => wr_ps2,
        din                 => din,
        ps2c                => ps2c,
        ps2d                => ps2d,
        tx_idle             => tx_idle,
        tx_done_tick        => tx_done_tick
    );

    -- module soc_ps2_rx instantiation
    ps2_rx_unit: entity work.soc_ps2_rx port map(
        clk                 => clk,
        resetn              => resetn,
        rx_en               => rx_en_ff_1,
        ps2c                => ps2c_ff_1,
        ps2d                => ps2d_ff_1,
        rx_done_tick        => rx_done_tick,
        dout                => dout
    );

    -- u0 : component signal_tap port map (
    --     acq_clk                     => clk,             -- acq_clk
    --     acq_data_in(31 downto 8)    => (others => '0'), -- acq_data_in
    --     acq_data_in(7 downto 0)     => dout,
    --     acq_trigger_in(0)           => rx_done_tick,    -- acq_trigger_in
    --     storage_enable              => rx_done_tick     -- storage_enable
    -- );

    -- module axis_fifo instantiation
    axis_fifo_rx_inst : entity work.axis_fifo_er generic map (
        FIFO_DEPTH          => 16,
        FIFO_WIDTH          => 8
    ) port map (
        clk                 => clk,
        resetn              => resetn,

        s_axis_fifo_tvalid  => rx_done_tick,
        s_axis_fifo_tready  => open,
        s_axis_fifo_tdata   => dout,

        m_axis_fifo_tvalid  => rx_fifo_m_tvalid,
        m_axis_fifo_tready  => rx_fifo_m_tready,
        m_axis_fifo_tdata   => rx_fifo_m_tdata
    );

    -- assigns
    wr_ps2           <= tx_fifo_m_tvalid;
    tx_fifo_m_tready <= tx_done_tick;
    din              <= tx_fifo_m_tdata;

    rx_fifo_m_tready <= '1' when io_req_tvalid = '1' and io_req_tready = '1' and
        io_read = '1' and io_read_rd_fifo_data = '1' else '0';

    io_read    <= '1' when io_req_tvalid = '1' and io_req_tready = '1' and io_req_tdata(32) = '0' else '0';
    io_write   <= '1' when io_req_tvalid = '1' and io_req_tready = '1' and io_req_tdata(32) = '1' else '0';
    io_address <= io_req_tdata(31 downto 16);

    io_read_rd_fifo_data  <= '1' when io_address(3 downto 0) = x"0" else '0';
    io_read_rd_fifo_ready <= '1' when io_address(3 downto 0) = x"2" else '0';
    io_read_wr_fifo_ready <= '1' when io_address(3 downto 0) = x"3" else '0';

    io_req_tready <= '1';

    process (clk) begin
        if rising_edge(clk) then
            ps2c_ff_0 <= ps2c;
            ps2c_ff_1 <= ps2c_ff_0;
            ps2d_ff_0 <= ps2d;
            ps2d_ff_1 <= ps2d_ff_0;
        end if;
    end process;

    process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                rx_en_ff_0 <= '0';
                rx_en_ff_1 <= '0';
            else
                rx_en_ff_0 <= tx_idle;
                rx_en_ff_1 <= rx_en_ff_0;
            end if;
        end if;
    end process;

    event_kb_int_req <= rx_done_tick;

    -- read process
    read_proc : process (clk) begin
        if rising_edge(clk) then
            -- resettable
            if resetn = '0' then
                io_rd_tvalid <= '0';
            else
                if (io_req_tvalid = '1' and io_req_tready = '1' and io_read = '1') then
                    io_rd_tvalid <= '1';
                elsif (io_rd_tready = '1') then
                    io_rd_tvalid <= '0';
                end if;
            end if;

            --without reset
            if (io_req_tvalid = '1' and io_req_tready = '1' and io_read = '1') then
                -- forming hi
                io_rd_tdata(15 downto 9) <= (others => '0');

                if (rx_fifo_m_tvalid = '1' and rx_fifo_m_tready = '1') then
                    io_rd_tdata(8) <= '1';
                else
                    io_rd_tdata(8) <= '0';
                end if;

                -- forming lo
                if (io_read_rd_fifo_data = '1') then
                    io_rd_tdata(7 downto 0) <= rx_fifo_m_tdata;
                elsif (io_read_rd_fifo_ready = '1') then
                    io_rd_tdata(7 downto 1) <= (others => '0');
                    io_rd_tdata(0) <= rx_fifo_m_tvalid;
                elsif (io_read_wr_fifo_ready = '1') then
                    io_rd_tdata(7 downto 1) <= (others => '0');
                    io_rd_tdata(0) <= tx_fifo_s_tready;
                end if;

            end if;
        end if;
    end process;

    -- write process
    write_proc : process (clk) begin
        if rising_edge(clk) then
            -- resettable
            if resetn = '0' then
                tx_fifo_s_tvalid <= '0';
            else
                if (io_req_tvalid = '1' and io_req_tready = '1' and io_write = '1') then
                    tx_fifo_s_tvalid <= '1';
                elsif (tx_fifo_s_tready = '1') then
                    tx_fifo_s_tvalid <= '0';
                end if;
            end if;

            --without reset
            if (io_req_tvalid = '1' and io_req_tready = '1' and io_write = '1') then
                tx_fifo_s_tdata <= io_req_tdata(7 downto 0);
            end if;

        end if;
    end process;

end rtl;
