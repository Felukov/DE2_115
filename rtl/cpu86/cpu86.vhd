
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

entity cpu86 is
    port (
        clk                             : in std_logic;
        resetn                          : in std_logic;

        mem_req_m_tvalid                : out std_logic;
        mem_req_m_tready                : in std_logic;
        mem_req_m_tdata                 : out std_logic_vector(63 downto 0);

        mem_rd_s_tvalid                 : in std_logic;
        mem_rd_s_tdata                  : in std_logic_vector(31 downto 0);

        io_req_m_tvalid                 : out std_logic;
        io_req_m_tready                 : in std_logic;
        io_req_m_tdata                  : out std_logic_vector(39 downto 0);

        io_rd_s_tvalid                  : in std_logic;
        io_rd_s_tready                  : out std_logic;
        io_rd_s_tdata                   : in std_logic_vector(15 downto 0);

        interrupt_valid                 : in std_logic;
        interrupt_data                  : in std_logic_vector(7 downto 0);
        interrupt_ack                   : out std_logic
    );
end entity;

architecture rtl of cpu86 is

    component cpu86_fetcher is
        port (
            clk                         : in std_logic;
            resetn                      : in std_logic;

            req_s_tvalid                : in std_logic;
            req_s_tdata                 : in std_logic_vector(31 downto 0);

            rd_s_tvalid                 : in std_logic;
            rd_s_tdata                  : in std_logic_vector(31 downto 0);

            cmd_m_tvalid                : out std_logic;
            cmd_m_tready                : in std_logic;
            cmd_m_tdata                 : out std_logic_vector(19 downto 0);

            buf_m_tvalid                : out std_logic;
            buf_m_tready                : in std_logic;
            buf_m_tdata                 : out std_logic_vector(31 downto 0);
            buf_m_tuser                 : out std_logic_vector(31 downto 0)
        );
    end component cpu86_fetcher;

    component cpu86_fetcher_buf is
        port (
            clk                         : in std_logic;
            resetn                      : in std_logic;

            u32_s_tvalid                : in std_logic;
            u32_s_tready                : out std_logic;
            u32_s_tdata                 : in std_logic_vector(31 downto 0);
            u32_s_tuser                 : in std_logic_vector(31 downto 0);

            u8_m_tvalid                 : out std_logic;
            u8_m_tready                 : in std_logic;
            u8_m_tdata                  : out std_logic_vector(7 downto 0);
            u8_m_tuser                  : out std_logic_vector(31 downto 0)
        );
    end component cpu86_fetcher_buf;

    component cpu86_decoder is
        port (
            clk                         : in std_logic;
            resetn                      : in std_logic;

            u8_s_tvalid                 : in std_logic;
            u8_s_tready                 : out std_logic;
            u8_s_tdata                  : in std_logic_vector(7 downto 0);
            u8_s_tuser                  : in std_logic_vector(31 downto 0);

            instr_m_tvalid              : out std_logic;
            instr_m_tready              : in std_logic;
            instr_m_tdata               : out decoded_instr_t;
            instr_m_tuser               : out user_t
        );
    end component cpu86_decoder;

    component cpu86_exec is
        port (
            clk                         : in std_logic;
            resetn                      : in std_logic;

            instr_s_tvalid              : in std_logic;
            instr_s_tready              : out std_logic;
            instr_s_tdata               : in decoded_instr_t;
            instr_s_tuser               : in user_t;

            req_m_tvalid                : out std_logic;
            req_m_tdata                 : out std_logic_vector(31 downto 0);

            mem_req_m_tvalid            : out std_logic;
            mem_req_m_tready            : in std_logic;
            mem_req_m_tdata             : out std_logic_vector(63 downto 0);

            mem_rd_s_tvalid             : in std_logic;
            mem_rd_s_tdata              : in std_logic_vector(31 downto 0);

            io_req_m_tvalid             : out std_logic;
            io_req_m_tready             : in std_logic;
            io_req_m_tdata              : out std_logic_vector(39 downto 0);

            io_rd_s_tvalid              : in std_logic;
            io_rd_s_tready              : out std_logic;
            io_rd_s_tdata               : in std_logic_vector(15 downto 0);

            interrupt_valid             : in std_logic;
            interrupt_data              : in std_logic_vector(7 downto 0);
            interrupt_ack               : out std_logic;

            dbg_m_tvalid                : out std_logic;
            dbg_m_tdata                 : out std_logic_vector(14*16-1 downto 0)

        );
    end component cpu86_exec;

    component cpu86_mem_interconnect is
        port (
            clk                         : in std_logic;
            resetn                      : in std_logic;

            mem_req_m_tvalid            : out std_logic;
            mem_req_m_tready            : in std_logic;
            mem_req_m_tdata             : out std_logic_vector(63 downto 0);

            mem_rd_s_tvalid             : in std_logic;
            mem_rd_s_tdata              : in std_logic_vector(31 downto 0);

            fetcher_mem_req_tvalid      : in std_logic;
            fetcher_mem_req_tready      : out std_logic;
            fetcher_mem_req_tdata       : in std_logic_vector(19 downto 0);

            fetcher_mem_res_tvalid      : out std_logic;
            fetcher_mem_res_tdata       : out std_logic_vector(31 downto 0);

            exec_mem_req_tvalid         : in std_logic;
            exec_mem_req_tready         : out std_logic;
            exec_mem_req_tdata          : in std_logic_vector(63 downto 0);

            exec_mem_res_tvalid         : out std_logic;
            exec_mem_res_tdata          : out std_logic_vector(31 downto 0)
        );
    end component cpu86_mem_interconnect;

    signal jump_req_tvalid              : std_logic;
    signal jump_req_tdata               : std_logic_vector(31 downto 0);

    signal fetcher_mem_req_tvalid       : std_logic;
    signal fetcher_mem_req_tready       : std_logic;
    signal fetcher_mem_req_tdata        : std_logic_vector(19 downto 0);

    signal fetcher_mem_res_tvalid       : std_logic;
    signal fetcher_mem_res_tdata        : std_logic_vector(31 downto 0);

    signal exec_mem_req_tvalid          : std_logic;
    signal exec_mem_req_tready          : std_logic;
    signal exec_mem_req_tdata           : std_logic_vector(63 downto 0);

    signal exec_mem_res_tvalid          : std_logic;
    signal exec_mem_res_tdata           : std_logic_vector(31 downto 0);

    signal u32_tvalid                   : std_logic;
    signal u32_tready                   : std_logic;
    signal u32_tdata                    : std_logic_vector(31 downto 0);
    signal u32_tuser                    : std_logic_vector(31 downto 0);

    signal u8_tvalid                    : std_logic;
    signal u8_tready                    : std_logic;
    signal u8_tdata                     : std_logic_vector(7 downto 0);
    signal u8_tuser                     : std_logic_vector(31 downto 0);

    signal instr_tvalid                 : std_logic;
    signal instr_tready                 : std_logic;
    signal instr_tdata                  : decoded_instr_t;
    signal instr_tuser                  : user_t;

    signal front_resetn                 : std_logic;

begin

    -- module cpu86_mem_interconnect instantiation
    cpu86_mem_interconnect_inst : cpu86_mem_interconnect port map(
        clk                     => clk,
        resetn                  => resetn,

        mem_req_m_tvalid        => mem_req_m_tvalid,
        mem_req_m_tready        => mem_req_m_tready,
        mem_req_m_tdata         => mem_req_m_tdata,

        mem_rd_s_tvalid         => mem_rd_s_tvalid,
        mem_rd_s_tdata          => mem_rd_s_tdata,

        fetcher_mem_req_tvalid  => fetcher_mem_req_tvalid,
        fetcher_mem_req_tready  => fetcher_mem_req_tready,
        fetcher_mem_req_tdata   => fetcher_mem_req_tdata,

        fetcher_mem_res_tvalid  => fetcher_mem_res_tvalid,
        fetcher_mem_res_tdata   => fetcher_mem_res_tdata,

        exec_mem_req_tvalid     => exec_mem_req_tvalid,
        exec_mem_req_tready     => exec_mem_req_tready,
        exec_mem_req_tdata      => exec_mem_req_tdata,

        exec_mem_res_tvalid     => exec_mem_res_tvalid,
        exec_mem_res_tdata      => exec_mem_res_tdata
    );

    -- module cpu86_fetcher instantiation
    cpu86_fetcher_inst : cpu86_fetcher port map(
        clk                     => clk,
        resetn                  => resetn,

        req_s_tvalid            => jump_req_tvalid,
        req_s_tdata             => jump_req_tdata,

        rd_s_tvalid             => fetcher_mem_res_tvalid,
        rd_s_tdata              => fetcher_mem_res_tdata,

        cmd_m_tvalid            => fetcher_mem_req_tvalid,
        cmd_m_tready            => fetcher_mem_req_tready,
        cmd_m_tdata             => fetcher_mem_req_tdata,

        buf_m_tvalid            => u32_tvalid,
        buf_m_tready            => u32_tready,
        buf_m_tdata             => u32_tdata,
        buf_m_tuser             => u32_tuser
    );

    -- module cpu86_fetcher_buf instantiation
    cpu86_fetcher_buf_inst : cpu86_fetcher_buf port map(
        clk                     => clk,
        resetn                  => front_resetn,

        u32_s_tvalid            => u32_tvalid,
        u32_s_tready            => u32_tready,
        u32_s_tdata             => u32_tdata,
        u32_s_tuser             => u32_tuser,

        u8_m_tvalid             => u8_tvalid,
        u8_m_tready             => u8_tready,
        u8_m_tdata              => u8_tdata,
        u8_m_tuser              => u8_tuser
    );

    -- module cpu86_decoder instantiation
    cpu86_decoder_inst : cpu86_decoder port map (
        clk                     => clk,
        resetn                  => front_resetn,

        u8_s_tvalid             => u8_tvalid,
        u8_s_tready             => u8_tready,
        u8_s_tdata              => u8_tdata,
        u8_s_tuser              => u8_tuser,

        instr_m_tvalid          => instr_tvalid,
        instr_m_tready          => instr_tready,
        instr_m_tdata           => instr_tdata,
        instr_m_tuser           => instr_tuser
    );

    -- module cpu86_exec instantiation
    cpu86_exec_inst : cpu86_exec port map (
        clk                     => clk,
        resetn                  => resetn,

        instr_s_tvalid          => instr_tvalid,
        instr_s_tready          => instr_tready,
        instr_s_tdata           => instr_tdata,
        instr_s_tuser           => instr_tuser,

        req_m_tvalid            => jump_req_tvalid,
        req_m_tdata             => jump_req_tdata,

        mem_req_m_tvalid        => exec_mem_req_tvalid,
        mem_req_m_tready        => exec_mem_req_tready,
        mem_req_m_tdata         => exec_mem_req_tdata,

        mem_rd_s_tvalid         => exec_mem_res_tvalid,
        mem_rd_s_tdata          => exec_mem_res_tdata,

        io_req_m_tvalid         => io_req_m_tvalid,
        io_req_m_tready         => io_req_m_tready,
        io_req_m_tdata          => io_req_m_tdata,

        io_rd_s_tvalid          => io_rd_s_tvalid,
        io_rd_s_tready          => io_rd_s_tready,
        io_rd_s_tdata           => io_rd_s_tdata,

        interrupt_valid         => '0',
        interrupt_data          => (others => '0'),
        interrupt_ack           => open,

        dbg_m_tvalid            => open,
        dbg_m_tdata             => open

    );

    -- Assigns
    front_resetn <= '0' when resetn = '0' or jump_req_tvalid = '1' else '1';
    interrupt_ack <= '0';

end architecture;
