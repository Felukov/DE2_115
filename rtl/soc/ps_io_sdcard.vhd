
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

entity ps_io_sdcard is
    port (
        clk                     : in std_logic;
        resetn                  : in std_logic;

        -- cpu io
        s_axis_io_req_tvalid    : in std_logic;
        s_axis_io_req_tready    : out std_logic;
        s_axis_io_req_tdata     : in std_logic_vector(39 downto 0);
        m_axis_io_res_tvalid    : out std_logic;
        m_axis_io_res_tready    : in std_logic;
        m_axis_io_res_tdata     : out std_logic_vector(15 downto 0);

        -- sdcard signals
        sd_error                : in std_logic;
        sd_disk_mounted         : in std_logic;
        sd_blocks               : in std_logic_vector(21 downto 0);

        sd_io_lba               : out std_logic_vector(31 downto 0);
        sd_io_rd                : out std_logic;
        sd_io_wr                : out std_logic;
        sd_io_ack               : in std_logic;

        sd_io_din_tvalid        : in std_logic;
        sd_io_din_tdata         : in std_logic_vector(7 downto 0);

        sd_io_dout_tvalid       : out std_logic;
        sd_io_dout_tready       : in std_logic;
        sd_io_dout_tdata        : out std_logic_vector(7 downto 0)
    );
end entity ps_io_sdcard;

architecture rtl of ps_io_sdcard is

    constant CMD_GET_STATUS     : std_logic_vector(15 downto 0) := x"0330";
    constant CMD_WR_ADDR_LO     : std_logic_vector(15 downto 0) := x"0331";
    constant CMD_WR_ADDR_HI     : std_logic_vector(15 downto 0) := x"0332";
    constant CMD_WR_FIFO        : std_logic_vector(15 downto 0) := x"0333";
    constant CMD_WR_SDCARD      : std_logic_vector(15 downto 0) := x"0334";
    constant CMD_RD_SDCARD      : std_logic_vector(15 downto 0) := x"0335";
    constant CMD_HAS_DATA       : std_logic_vector(15 downto 0) := x"0336";
    constant CMD_RD_FIFO        : std_logic_vector(15 downto 0) := x"0337";
    constant CMD_GET_SIZE_LO    : std_logic_vector(15 downto 0) := x"0338";
    constant CMD_GET_SIZE_HI    : std_logic_vector(15 downto 0) := x"0339";
    constant CMD_IS_EMPTY       : std_logic_vector(15 downto 0) := x"033A";

    signal io_req_tvalid        : std_logic;
    signal io_req_tready        : std_logic;
    signal io_req_tready_mask   : std_logic;
    signal io_req_tdata         : std_logic_vector(39 downto 0);

    signal io_rd_tvalid         : std_logic;
    signal io_rd_tready         : std_logic;
    signal io_rd_tdata          : std_logic_vector(15 downto 0);

    signal io_read              : std_logic;
    signal io_address           : std_logic_vector(15 downto 0);
    signal io_write             : std_logic;

    signal rd_fifo_m_tvalid     : std_logic;
    signal rd_fifo_m_tready     : std_logic;
    signal rd_fifo_m_tdata      : std_logic_vector(7 downto 0);

    signal wr_fifo_s_tvalid     : std_logic;
    signal wr_fifo_s_tready     : std_logic;
    signal wr_fifo_s_tdata      : std_logic_vector(7 downto 0);

    signal wr_fifo_m_tvalid     : std_logic;

    signal sd_rd_cmd            : std_logic;

	component signal_tap is
		port (
			acq_clk        : in std_logic                    := 'X';             -- clk
			storage_enable : in std_logic                    := 'X';             -- storage_enable
			acq_data_in    : in std_logic_vector(8 downto 0) := (others => 'X'); -- acq_data_in
			acq_trigger_in : in std_logic_vector(0 downto 0) := (others => 'X')  -- acq_trigger_in
		);
	end component signal_tap;
begin

    -- i/o assigns
    io_req_tvalid           <= s_axis_io_req_tvalid;
    s_axis_io_req_tready    <= io_req_tready;
    io_req_tdata            <= s_axis_io_req_tdata;

    m_axis_io_res_tvalid    <= io_rd_tvalid;
    io_rd_tready            <= m_axis_io_res_tready;
    m_axis_io_res_tdata     <= io_rd_tdata;

    sd_io_rd                <= sd_rd_cmd;

    sd_io_dout_tvalid       <= wr_fifo_m_tvalid;

    -- u0 : component signal_tap
    --     port map (
    --         acq_clk             => clk,
    --         storage_enable      => sd_io_dout_strobe,
    --         acq_data_in         => wr_fifo_m_tvalid & sd_io_dout,
    --         acq_trigger_in(0)   => sd_io_dout_strobe
    -- );

    axis_fifo_inst_rd : entity work.axis_fifo_er generic map (
        FIFO_DEPTH          => 512,
        FIFO_WIDTH          => 8
    ) port map (
        clk                 => clk,
        resetn              => resetn,

        s_axis_fifo_tvalid  => sd_io_din_tvalid,
        s_axis_fifo_tready  => open,
        s_axis_fifo_tdata   => sd_io_din_tdata,

        m_axis_fifo_tvalid  => rd_fifo_m_tvalid,
        m_axis_fifo_tready  => rd_fifo_m_tready,
        m_axis_fifo_tdata   => rd_fifo_m_tdata
    );


    axis_fifo_inst_wr : entity work.axis_fifo_er generic map (
        FIFO_DEPTH          => 512,
        FIFO_WIDTH          => 8
    ) port map (
        clk                 => clk,
        resetn              => resetn,

        s_axis_fifo_tvalid  => wr_fifo_s_tvalid,
        s_axis_fifo_tready  => wr_fifo_s_tready,
        s_axis_fifo_tdata   => wr_fifo_s_tdata,

        m_axis_fifo_tvalid  => wr_fifo_m_tvalid,
        m_axis_fifo_tready  => sd_io_dout_tready,
        m_axis_fifo_tdata   => sd_io_dout_tdata
    );

    io_read          <= '1' when io_req_tvalid = '1' and io_req_tready = '1' and io_req_tdata(32) = '0' else '0';
    io_write         <= '1' when io_req_tvalid = '1' and io_req_tready = '1' and io_req_tdata(32) = '1' else '0';
    io_req_tready    <= '1' when io_req_tready_mask = '1' and (io_rd_tvalid = '0' or (io_rd_tvalid = '1' and io_rd_tready = '1')) else '0';

    io_address       <= io_req_tdata(31 downto 16);
    rd_fifo_m_tready <= '1' when io_read = '1' and io_address = CMD_RD_FIFO else '0';

    rdy_ctrl_proc : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                io_req_tready_mask <= '1';
            else
                if (io_write = '1' and (io_address = CMD_WR_SDCARD or io_address = CMD_RD_SDCARD)) then
                    io_req_tready_mask <= '0';
                elsif (sd_io_ack = '1') then
                    io_req_tready_mask <= '1';
                end if;
            end if;
        end if;
    end process;

    read_proc : process (clk) begin
        if rising_edge(clk) then
            -- control
            if resetn = '0' then
                io_rd_tvalid <= '0';
            else
                if (io_req_tvalid = '1' and io_req_tready = '1' and io_read = '1') then
                    io_rd_tvalid <= '1';
                elsif (io_rd_tready = '1') then
                    io_rd_tvalid <= '0';
                end if;
            end if;

            -- datapath
            if (io_req_tvalid = '1' and io_req_tready = '1' and io_read = '1') then

                case io_address is
                    when CMD_GET_STATUS =>
                        io_rd_tdata(15 downto 1) <= (others => '0');
                        io_rd_tdata(0) <= sd_disk_mounted;
                    when CMD_HAS_DATA =>
                        io_rd_tdata(15 downto 1) <= (others => '0');
                        io_rd_tdata(0) <= rd_fifo_m_tvalid;
                    when CMD_RD_FIFO =>
                        io_rd_tdata(15 downto 8) <= (others => '0');
                        io_rd_tdata( 7 downto 0) <= rd_fifo_m_tdata;
                    when CMD_GET_SIZE_HI =>
                        io_rd_tdata(15 downto 6) <= (others => '0');
                        io_rd_tdata(5 downto 0) <= sd_blocks(21 downto 16);
                    when CMD_GET_SIZE_LO =>
                        io_rd_tdata <= sd_blocks(15 downto 0);
                    when CMD_IS_EMPTY =>
                        io_rd_tdata(15 downto 1) <= (others => '0');
                        io_rd_tdata(0) <= wr_fifo_m_tvalid;
                    when others =>
                        null;
                end case;

            end if;
        end if;
    end process;

    -- read command
    write_rd_cmd : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                sd_rd_cmd <= '0';
            else
                if (io_write = '1' and io_address = CMD_RD_SDCARD) then
                    sd_rd_cmd <= '1';
                elsif (sd_io_ack = '1') then
                    sd_rd_cmd <= '0';
                end if;
            end if;
        end if;
    end process;

    -- write command
    write_wr_cmd : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                sd_io_wr <= '0';
            else
                if (io_write = '1' and io_address = CMD_WR_SDCARD) then
                    sd_io_wr <= '1';
                elsif (sd_io_ack = '1') then
                    sd_io_wr <= '0';
                end if;
            end if;
        end if;
    end process;

    -- write LBA
    write_addr_proc: process (clk) begin
        if rising_edge(clk) then

            if (io_write = '1' and io_address = CMD_WR_ADDR_HI) then
                sd_io_lba(31 downto 16) <= io_req_tdata(15 downto 0);
            end if;

            if (io_write = '1' and io_address = CMD_WR_ADDR_LO) then
                sd_io_lba(15 downto 0) <= io_req_tdata(15 downto 0);
            end if;

        end if;
    end process;

    -- write to FIFO process
    write_proc : process (clk) begin
        if rising_edge(clk) then
            -- resettable
            if resetn = '0' then
                wr_fifo_s_tvalid <= '0';
            else
                if (io_req_tvalid = '1' and io_req_tready = '1' and io_write = '1' and io_address = CMD_WR_FIFO) then
                    wr_fifo_s_tvalid <= '1';
                elsif (wr_fifo_s_tready = '1') then
                    wr_fifo_s_tvalid <= '0';
                end if;
            end if;

            --without reset
            if (io_req_tvalid = '1' and io_req_tready = '1' and io_write = '1') then
                wr_fifo_s_tdata <= io_req_tdata(7 downto 0);
            end if;

        end if;
    end process;


end architecture;
