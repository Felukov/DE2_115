
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

entity cpu86_exec_lsu is
    port (
        clk                     : in std_logic;
        resetn                  : in std_logic;

        s_axis_lsu_req_tvalid   : in std_logic;
        s_axis_lsu_req_tready   : out std_logic;
        s_axis_lsu_req_tcmd     : in std_logic;
        s_axis_lsu_req_taddr    : in std_logic_vector(19 downto 0);
        s_axis_lsu_req_twidth   : in std_logic;
        s_axis_lsu_req_tdata    : in std_logic_vector(15 downto 0);
        s_axis_lsu_req_thit     : in std_logic;
        s_axis_lsu_req_tcache   : in std_logic_vector(15 downto 0);

        m_axis_mem_req_tvalid   : out std_logic;
        m_axis_mem_req_tready   : in std_logic;
        m_axis_mem_req_tdata    : out std_logic_vector(63 downto 0);

        s_axis_mem_rd_tvalid    : in std_logic;
        s_axis_mem_rd_tdata     : in std_logic_vector(31 downto 0);

        m_axis_lsu_rd_tvalid    : out std_logic;
        m_axis_lsu_rd_tready    : in std_logic;
        m_axis_lsu_rd_tdata     : out std_logic_vector(15 downto 0)
    );
end entity cpu86_exec_lsu;

architecture rtl of cpu86_exec_lsu is

    component axis_reg is
        generic (
            DATA_WIDTH          : natural := 32
        );
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;
            in_s_tvalid         : in std_logic;
            in_s_tready         : out std_logic;
            in_s_tdata          : in std_logic_vector (DATA_WIDTH-1 downto 0);
            out_m_tvalid        : out std_logic;
            out_m_tready        : in std_logic;
            out_m_tdata         : out std_logic_vector (DATA_WIDTH-1 downto 0)
        );
    end component;

    component axis_fifo_er is
        generic (
            FIFO_DEPTH          : natural := 2**8;
            FIFO_WIDTH          : natural := 128
        );
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            s_axis_fifo_tvalid  : in std_logic;
            s_axis_fifo_tready  : out std_logic;
            s_axis_fifo_tdata   : in std_logic_vector(FIFO_WIDTH-1 downto 0);

            m_axis_fifo_tvalid  : out std_logic;
            m_axis_fifo_tready  : in std_logic;
            m_axis_fifo_tdata   : out std_logic_vector(FIFO_WIDTH-1 downto 0)
        );
    end component axis_fifo_er;

    component cpu86_exec_lsu_fifo is
        generic (
            FIFO_DEPTH          : natural := 4;
            FIFO_WIDTH          : natural := 16;
            ADDR_WIDTH          : natural := 2;
            REGISTER_OUTPUT     : std_logic := '1'
        );
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            s_axis_add_tvalid   : in std_logic;
            s_axis_add_tready   : out std_logic;
            s_axis_add_tdata    : in std_logic_vector(FIFO_WIDTH-1 downto 0);
            s_axis_add_tuser    : in std_logic;

            m_axis_tag_tvalid   : out std_logic;
            m_axis_tag_tdata    : out std_logic_vector(ADDR_WIDTH-1 downto 0);

            s_axis_upd_tvalid   : in std_logic;
            s_axis_upd_tdata    : in std_logic_vector(FIFO_WIDTH-1 downto 0);
            s_axis_upd_tuser    : in std_logic_vector(ADDR_WIDTH-1 downto 0);

            m_axis_dout_tvalid  : out std_logic;
            m_axis_dout_tready  : in std_logic;
            m_axis_dout_tdata   : out std_logic_vector(FIFO_WIDTH-1 downto 0)
        );
    end component cpu86_exec_lsu_fifo;

    signal lsu_req_tvalid       : std_logic;
    signal lsu_req_tready       : std_logic;
    signal lsu_req_tcmd         : std_logic;
    signal lsu_req_taddr        : std_logic_vector(19 downto 0);
    signal lsu_req_twidth       : std_logic;
    signal lsu_req_tdata        : std_logic_vector(15 downto 0);
    signal lsu_req_thit         : std_logic;
    signal lsu_req_tcache       : std_logic_vector(15 downto 0);

    signal mem_rd_tvalid        : std_logic;
    signal mem_rd_tdata         : std_logic_vector(31 downto 0);

    signal req_buf_tvalid       : std_logic;
    signal req_buf_tready       : std_logic;
    signal req_buf_tcmd         : std_logic;
    signal req_buf_twidth       : std_logic;
    signal req_buf_taddr        : std_logic_vector(17 downto 0);
    signal req_buf_tdata        : std_logic_vector(7 downto 0);
    signal req_buf_tag          : std_logic_vector(3 downto 0);

    signal mem_req_tvalid       : std_logic;
    signal mem_req_tready       : std_logic;
    signal mem_req_tdata        : std_logic_vector(63 downto 0);
    signal mem_req_last         : std_logic;
    signal mem_req_cmd          : std_logic;
    signal mem_req_addr         : std_logic_vector(17 downto 0);
    signal mem_req_mask         : std_logic_vector(3 downto 0);
    signal mem_req_wdata        : std_logic_vector(31 downto 0) := (others => '0');

    signal add_tvalid           : std_logic;
    signal add_tready           : std_logic;

    signal tag_tdata            : std_logic_vector(3 downto 0);

    signal fifo_0_s_tvalid      : std_logic;
    signal fifo_0_s_tready      : std_logic;
    signal fifo_0_s_tdata       : std_logic_vector(7 downto 0);
    signal fifo_0_m_tvalid      : std_logic;
    signal fifo_0_m_tready      : std_logic;
    signal fifo_0_m_tdata       : std_logic_vector(7 downto 0);

    signal upd_tvalid           : std_logic;
    signal upd_tdata            : std_logic_vector(15 downto 0);
    signal upd_tag              : std_logic_vector(3 downto 0);

    signal fifo_1_m_tvalid      : std_logic;
    signal fifo_1_m_tready      : std_logic;
    signal fifo_1_m_tdata       : std_logic_vector(15 downto 0);

begin

    -- important note:
    -- we can use a fifo with an output latency of 2 cycles
    -- if we do not expect data from memory on the next clock
    -- after the read request

    -- module axis_fifo instantiation
    axis_fifo_inst : axis_fifo_er generic map (
        FIFO_DEPTH              => 16,
        FIFO_WIDTH              => 8
    ) port map (
        clk                     => clk,
        resetn                  => resetn,

        s_axis_fifo_tvalid      => fifo_0_s_tvalid,
        s_axis_fifo_tready      => fifo_0_s_tready,
        s_axis_fifo_tdata       => fifo_0_s_tdata,

        m_axis_fifo_tvalid      => fifo_0_m_tvalid,
        m_axis_fifo_tready      => fifo_0_m_tready,
        m_axis_fifo_tdata       => fifo_0_m_tdata
    );

    -- module cpu86_exec_lsu_fifo instantiation
    lsu_fifo_inst : cpu86_exec_lsu_fifo generic map (
        FIFO_DEPTH              => 16,
        FIFO_WIDTH              => 16,
        ADDR_WIDTH              => 4,
        REGISTER_OUTPUT         => '0'
    ) port map (
        clk                     => clk,
        resetn                  => resetn,

        s_axis_add_tvalid       => add_tvalid,
        s_axis_add_tready       => add_tready,
        s_axis_add_tdata        => lsu_req_tcache,
        s_axis_add_tuser        => lsu_req_thit,

        m_axis_tag_tvalid       => open,
        m_axis_tag_tdata        => tag_tdata,

        s_axis_upd_tvalid       => upd_tvalid,
        s_axis_upd_tdata        => upd_tdata,
        s_axis_upd_tuser        => upd_tag,

        m_axis_dout_tvalid      => fifo_1_m_tvalid,
        m_axis_dout_tready      => fifo_1_m_tready,
        m_axis_dout_tdata       => fifo_1_m_tdata
    );

    -- module axis_reg instantiation
    axis_reg_mem_req_inst : axis_reg generic map (
        DATA_WIDTH              => 64
    ) port map (
        clk                     => clk,
        resetn                  => resetn,

        in_s_tvalid             => mem_req_tvalid,
        in_s_tready             => mem_req_tready,
        in_s_tdata              => mem_req_tdata,

        out_m_tvalid            => m_axis_mem_req_tvalid,
        out_m_tready            => m_axis_mem_req_tready,
        out_m_tdata             => m_axis_mem_req_tdata
    );

    -- i/o assigns
    m_axis_lsu_rd_tvalid    <= fifo_1_m_tvalid;
    fifo_1_m_tready         <= m_axis_lsu_rd_tready;
    m_axis_lsu_rd_tdata     <= fifo_1_m_tdata;

    lsu_req_tvalid          <= s_axis_lsu_req_tvalid;
    s_axis_lsu_req_tready   <= lsu_req_tready;
    lsu_req_tcmd            <= s_axis_lsu_req_tcmd;
    lsu_req_taddr           <= s_axis_lsu_req_taddr;
    lsu_req_twidth          <= s_axis_lsu_req_twidth;
    lsu_req_tdata           <= s_axis_lsu_req_tdata;
    lsu_req_thit            <= s_axis_lsu_req_thit;
    lsu_req_tcache          <= s_axis_lsu_req_tcache;

    mem_req_tdata(31 downto 0)  <= mem_req_wdata;
    mem_req_tdata(56 downto 32) <= "0000000" & mem_req_addr;
    mem_req_tdata(57)           <= mem_req_cmd;
    mem_req_tdata(61 downto 58) <= mem_req_mask;
    mem_req_tdata(63 downto 62) <= "00";

    mem_rd_tvalid <= s_axis_mem_rd_tvalid;
    mem_rd_tdata <= s_axis_mem_rd_tdata;

    -- assigns
    add_tvalid      <= '1' when lsu_req_tvalid = '1' and lsu_req_tready = '1' and lsu_req_tcmd = '0' else '0';

    lsu_req_tready  <= '1' when req_buf_tvalid = '0' and (mem_req_tvalid = '0' or (mem_req_tvalid = '1' and mem_req_tready = '1')) and add_tready = '1' else '0';
    req_buf_tready  <= '1' when (mem_req_tvalid = '0' or (mem_req_tvalid = '1' and mem_req_tready = '1')) else '0';
    fifo_0_m_tready <= mem_rd_tvalid;

    fifo_0_s_tvalid <= '1' when (req_buf_tvalid = '1' and req_buf_tready = '1' and req_buf_tcmd = '0') or
        (lsu_req_tvalid = '1' and lsu_req_tready = '1' and lsu_req_tcmd = '0' and lsu_req_thit = '0') else '0';

    fifo_0_s_tdata <= req_buf_tag & '1' & req_buf_twidth & req_buf_taddr(1 downto 0) when req_buf_tvalid = '1'
        else tag_tdata & '0' & lsu_req_twidth & lsu_req_taddr(1 downto 0);

    buffering_req_proc: process (clk) begin
        if rising_edge(clk) then
            -- Resettable
            if resetn = '0' then
                req_buf_tvalid <= '0';
            else
                if (lsu_req_tvalid = '1' and lsu_req_tready = '1') then
                    if (lsu_req_taddr(1 downto 0) = "11" and lsu_req_twidth = '1') then
                        req_buf_tvalid <= '1';
                    else
                        req_buf_tvalid <= '0';
                    end if;
                elsif req_buf_tready = '1' then
                    req_buf_tvalid <= '0';
                end if;
            end if;
            -- Without reset
            if (lsu_req_tvalid = '1' and lsu_req_tready = '1') then
                req_buf_tcmd    <= lsu_req_tcmd;
                req_buf_twidth  <= lsu_req_twidth;
                req_buf_taddr   <= std_logic_vector(unsigned(lsu_req_taddr(19 downto 2)) + to_unsigned(1,18));
                req_buf_tdata   <= lsu_req_tdata(15 downto 8);
                req_buf_tag     <= tag_tdata;
            end if;
        end if;
    end process;

    forming_mem_req_proc: process (clk) begin
        if rising_edge(clk) then
            -- Resettable
            if resetn = '0' then
                mem_req_tvalid <= '0';
                mem_req_last <= '0';
            else
                if (req_buf_tvalid = '1' and req_buf_tready = '1') then
                    mem_req_tvalid <= '1';
                elsif (lsu_req_tvalid = '1' and lsu_req_tready = '1') then
                    if (lsu_req_thit = '0' or lsu_req_tcmd = '1') then
                        mem_req_tvalid <= '1';
                    else
                        mem_req_tvalid <= '0';
                    end if;
                elsif (mem_req_tready = '1') then
                    mem_req_tvalid <= '0';
                end if;

                if (req_buf_tvalid = '1' and req_buf_tready = '1') then
                    mem_req_last <= '1';
                elsif (lsu_req_tvalid = '1' and lsu_req_tready = '1') then
                    if (lsu_req_taddr(1 downto 0) = "11" and lsu_req_twidth = '1') then
                        mem_req_last <= '0';
                    else
                        mem_req_last <= '1';
                    end if;
                end if;
            end if;
            -- Without reset
            if (req_buf_tvalid = '1' and req_buf_tready = '1') then
                mem_req_cmd <= req_buf_tcmd;
                mem_req_addr <= req_buf_taddr;
                mem_req_mask <= "0111";
                mem_req_wdata(31 downto 24) <= req_buf_tdata;
            elsif (lsu_req_tvalid = '1' and lsu_req_tready = '1') then
                mem_req_cmd <= lsu_req_tcmd;
                mem_req_addr <= lsu_req_taddr(19 downto 2);

                if (lsu_req_twidth = '0') then
                    case lsu_req_taddr(1 downto 0) is
                        when "00" => mem_req_mask <= "0111";
                        when "01" => mem_req_mask <= "1011";
                        when "10" => mem_req_mask <= "1101";
                        when "11" => mem_req_mask <= "1110";
                        when others => null;
                    end case;
                else
                    case lsu_req_taddr(1 downto 0) is
                        when "00" => mem_req_mask <= "0011";
                        when "01" => mem_req_mask <= "1001";
                        when "10" => mem_req_mask <= "1100";
                        when "11" => mem_req_mask <= "1110";
                        when others => null;
                    end case;
                end if;

                if (lsu_req_twidth = '0') then
                    case lsu_req_taddr(1 downto 0) is
                        when "00" => mem_req_wdata(31 downto 24) <= lsu_req_tdata(7 downto 0);
                        when "01" => mem_req_wdata(23 downto 16) <= lsu_req_tdata(7 downto 0);
                        when "10" => mem_req_wdata(15 downto  8) <= lsu_req_tdata(7 downto 0);
                        when "11" => mem_req_wdata( 7 downto  0) <= lsu_req_tdata(7 downto 0);
                        when others => null;
                    end case;
                else
                    case lsu_req_taddr(1 downto 0) is
                        when "00" => mem_req_wdata(31 downto 16) <= lsu_req_tdata(7 downto 0) & lsu_req_tdata(15 downto 8);
                        when "01" => mem_req_wdata(23 downto  8) <= lsu_req_tdata(7 downto 0) & lsu_req_tdata(15 downto 8);
                        when "10" => mem_req_wdata(15 downto  0) <= lsu_req_tdata(7 downto 0) & lsu_req_tdata(15 downto 8);
                        when "11" => mem_req_wdata( 7 downto  0) <= lsu_req_tdata(7 downto 0);
                        when others => null;
                    end case;
                end if;

            end if;
        end if;
    end process;

    parsing_results_to_fifo_proc: process (clk) begin
        if rising_edge(clk) then
            -- Resettable
            if resetn = '0' then
                upd_tvalid <= '0';
            else
                if (mem_rd_tvalid = '1') then
                    if (fifo_0_m_tdata(3) = '0' and (fifo_0_m_tdata(2) = '0' or (fifo_0_m_tdata(2) = '1' and fifo_0_m_tdata(1 downto 0) /= "11"))) then
                        upd_tvalid <= '1';
                    elsif (fifo_0_m_tdata(3) = '1') then
                        upd_tvalid <= '1';
                    else
                        upd_tvalid <= '0';
                    end if;
                else
                    upd_tvalid <= '0';
                end if;
            end if;
            -- Without reset
            if (mem_rd_tvalid = '1') then
                if (fifo_0_m_tdata(3) = '0') then
                    if (fifo_0_m_tdata(2) = '0') then
                        -- load byte
                        case fifo_0_m_tdata(1 downto 0) is
                            when "00" => upd_tdata <= x"00" & mem_rd_tdata(31 downto 24);
                            when "01" => upd_tdata <= x"00" & mem_rd_tdata(23 downto 16);
                            when "10" => upd_tdata <= x"00" & mem_rd_tdata(15 downto  8);
                            when "11" => upd_tdata <= x"00" & mem_rd_tdata( 7 downto  0);
                            when others => null;
                        end case;
                    else
                        -- load word
                        case fifo_0_m_tdata(1 downto 0) is
                            when "00" => upd_tdata <= mem_rd_tdata(23 downto 16) & mem_rd_tdata(31 downto 24);
                            when "01" => upd_tdata <= mem_rd_tdata(15 downto  8) & mem_rd_tdata(23 downto 16);
                            when "10" => upd_tdata <= mem_rd_tdata( 7 downto  0) & mem_rd_tdata(15 downto  8);
                            when "11" => upd_tdata(7 downto 0) <= mem_rd_tdata( 7 downto  0);
                            when others => null;
                        end case;
                    end if;
                elsif (fifo_0_m_tdata(3) = '1') then
                    -- load tail of the word
                    upd_tdata(15 downto 8) <= mem_rd_tdata(31 downto 24);
                end if;

                upd_tag <= fifo_0_m_tdata(7 downto 4);
            end if;
        end if;
    end process;

end architecture;
