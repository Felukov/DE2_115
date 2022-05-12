
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

entity cpu86_exec is
    port (
        clk                         : in std_logic;
        resetn                      : in std_logic;

        instr_s_tvalid              : in std_logic;
        instr_s_tready              : out std_logic;
        instr_s_tdata               : in slv_decoded_instr_t;
        instr_s_tuser               : in user_t;

        req_m_tvalid                : out std_logic;
        req_m_tdata                 : out cpu86_jump_t;

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
end entity cpu86_exec;

architecture rtl of cpu86_exec is

    component cpu86_exec_reg is
        generic (
            DATA_WIDTH              : integer := 16;
            INIT_VALUE              : std_logic_vector(15 downto 0)
        );
        port (
            clk                     : in std_logic;
            resetn                  : in std_logic;

            wr_s_tvalid             : in std_logic;
            wr_s_tdata              : in std_logic_vector(DATA_WIDTH-1 downto 0);
            wr_s_tmask              : in std_logic_vector(1 downto 0);

            lock_s_tvalid           : in std_logic;
            unlk_s_tvalid           : in std_logic;

            reg_m_tvalid            : out std_logic;
            reg_m_tdata             : out std_logic_vector(DATA_WIDTH-1 downto 0)
        );
    end component cpu86_exec_reg;

    component axis_fifo is
        generic (
            FIFO_DEPTH              : natural := 2**8;
            FIFO_WIDTH              : natural := 128;
            REGISTER_OUTPUT         : std_logic := '1'
        );
        port (
            clk                     : in std_logic;
            resetn                  : in std_logic;

            fifo_s_tvalid           : in std_logic;
            fifo_s_tready           : out std_logic;
            fifo_s_tdata            : in std_logic_vector(FIFO_WIDTH-1 downto 0);

            fifo_m_tvalid           : out std_logic;
            fifo_m_tready           : in std_logic;
            fifo_m_tdata            : out std_logic_vector(FIFO_WIDTH-1 downto 0)
        );
    end component;

    component axis_fifo_er is
        generic (
            FIFO_DEPTH      : natural := 2**8;
            FIFO_WIDTH      : natural := 128
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

    component axis_reg is
        generic (
            DATA_WIDTH              : natural := 32
        );
        port (
            clk                     : in std_logic;
            resetn                  : in std_logic;
            in_s_tvalid             : in std_logic;
            in_s_tready             : out std_logic;
            in_s_tdata              : in std_logic_vector (DATA_WIDTH-1 downto 0);
            out_m_tvalid            : out std_logic;
            out_m_tready            : in std_logic;
            out_m_tdata             : out std_logic_vector (DATA_WIDTH-1 downto 0)
        );
    end component;

    component cpu86_exec_register_reader is
        port (
            clk                     : in std_logic;
            resetn                  : in std_logic;

            instr_s_tvalid          : in std_logic;
            instr_s_tready          : out std_logic;
            instr_s_tdata           : in decoded_instr_t;
            instr_s_tuser           : in user_t;

            ext_intr_s_tvalid       : in std_logic;
            ext_intr_s_tready       : out std_logic;
            ext_intr_s_tdata        : in std_logic_vector(7 downto 0);

            ds_s_tvalid             : in std_logic;
            ds_s_tdata              : in std_logic_vector(15 downto 0);
            ds_m_lock_tvalid        : out std_logic;

            ss_s_tvalid             : in std_logic;
            ss_s_tdata              : in std_logic_vector(15 downto 0);
            ss_m_lock_tvalid        : out std_logic;

            es_s_tvalid             : in std_logic;
            es_s_tdata              : in std_logic_vector(15 downto 0);
            es_m_lock_tvalid        : out std_logic;

            ax_s_tvalid             : in std_logic;
            ax_s_tdata              : in std_logic_vector(15 downto 0);
            ax_m_lock_tvalid        : out std_logic;

            bx_s_tvalid             : in std_logic;
            bx_s_tdata              : in std_logic_vector(15 downto 0);
            bx_m_lock_tvalid        : out std_logic;

            cx_s_tvalid             : in std_logic;
            cx_s_tdata              : in std_logic_vector(15 downto 0);
            cx_m_lock_tvalid        : out std_logic;

            dx_s_tvalid             : in std_logic;
            dx_s_tdata              : in std_logic_vector(15 downto 0);
            dx_m_lock_tvalid        : out std_logic;

            sp_s_tvalid             : in std_logic;
            sp_s_tdata              : in std_logic_vector(15 downto 0);
            sp_m_lock_tvalid        : out std_logic;

            bp_s_tvalid             : in std_logic;
            bp_s_tdata              : in std_logic_vector(15 downto 0);
            bp_m_lock_tvalid        : out std_logic;

            si_s_tvalid             : in std_logic;
            si_s_tdata              : in std_logic_vector(15 downto 0);
            si_m_lock_tvalid        : out std_logic;

            di_s_tvalid             : in std_logic;
            di_s_tdata              : in std_logic_vector(15 downto 0);
            di_m_lock_tvalid        : out std_logic;

            flags_s_tvalid          : in std_logic;
            flags_s_tdata           : in std_logic_vector(15 downto 0);
            flags_m_lock_tvalid     : out std_logic;

            rr_m_tvalid             : out std_logic;
            rr_m_tready             : in std_logic;
            rr_m_tdata              : out rr_instr_t;
            rr_m_tuser              : out user_t
        );
    end component cpu86_exec_register_reader;

    component cpu86_exec_ifeu is
        port (
            clk                     : in std_logic;
            resetn                  : in std_logic;

            jmp_lock_s_tvalid       : in std_logic;

            rr_s_tvalid             : in std_logic;
            rr_s_tready             : out std_logic;
            rr_s_tdata              : in rr_instr_t;
            rr_s_tuser              : in user_t;

            div_intr_s_tvalid       : in std_logic;
            div_intr_s_tready       : out std_logic;
            div_intr_s_tdata        : in intr_t;

            bnd_intr_s_tvalid       : in std_logic;
            bnd_intr_s_tready       : out std_logic;
            bnd_intr_s_tdata        : in intr_t;

            micro_m_tvalid          : out std_logic;
            micro_m_tready          : in std_logic;
            micro_m_tdata           : out micro_op_t;

            ax_m_wr_tvalid          : out std_logic;
            ax_m_wr_tdata           : out std_logic_vector(15 downto 0);
            ax_m_wr_tmask           : out std_logic_vector(1 downto 0);
            bx_m_wr_tvalid          : out std_logic;
            bx_m_wr_tdata           : out std_logic_vector(15 downto 0);
            bx_m_wr_tmask           : out std_logic_vector(1 downto 0);
            cx_m_wr_tvalid          : out std_logic;
            cx_m_wr_tdata           : out std_logic_vector(15 downto 0);
            cx_m_wr_tmask           : out std_logic_vector(1 downto 0);
            dx_m_wr_tvalid          : out std_logic;
            dx_m_wr_tdata           : out std_logic_vector(15 downto 0);
            dx_m_wr_tmask           : out std_logic_vector(1 downto 0);

            bp_m_wr_tvalid          : out std_logic;
            bp_m_wr_tdata           : out std_logic_vector(15 downto 0);
            sp_m_wr_tvalid          : out std_logic;
            sp_m_wr_tdata           : out std_logic_vector(15 downto 0);
            di_m_wr_tvalid          : out std_logic;
            di_m_wr_tdata           : out std_logic_vector(15 downto 0);
            si_m_wr_tvalid          : out std_logic;
            si_m_wr_tdata           : out std_logic_vector(15 downto 0);

            ds_m_wr_tvalid          : out std_logic;
            ds_m_wr_tdata           : out std_logic_vector(15 downto 0);
            ss_m_wr_tvalid          : out std_logic;
            ss_m_wr_tdata           : out std_logic_vector(15 downto 0);
            es_m_wr_tvalid          : out std_logic;
            es_m_wr_tdata           : out std_logic_vector(15 downto 0);

            ext_intr_s_tvalid       : in std_logic;
            ext_intr_s_tready       : out std_logic;
            ext_intr_s_tdata        : in std_logic_vector(7 downto 0);

            jmp_lock_m_lock_tvalid  : out std_logic
        );
    end component cpu86_exec_ifeu;

    component cpu86_exec_mexec is
        port (
            clk                     : in std_logic;
            resetn                  : in std_logic;

            micro_s_tvalid          : in std_logic;
            micro_s_tready          : out std_logic;
            micro_s_tdata           : in micro_op_t;

            lsu_rd_s_tvalid         : in std_logic;
            lsu_rd_s_tready         : out std_logic;
            lsu_rd_s_tdata          : in std_logic_vector(15 downto 0);

            flags_s_tdata           : in std_logic_vector(15 downto 0);

            ax_m_wr_tvalid          : out std_logic;
            ax_m_wr_tdata           : out std_logic_vector(15 downto 0);
            ax_m_wr_tmask           : out std_logic_vector(1 downto 0);
            bx_m_wr_tvalid          : out std_logic;
            bx_m_wr_tdata           : out std_logic_vector(15 downto 0);
            bx_m_wr_tmask           : out std_logic_vector(1 downto 0);
            cx_m_wr_tvalid          : out std_logic;
            cx_m_wr_tdata           : out std_logic_vector(15 downto 0);
            cx_m_wr_tmask           : out std_logic_vector(1 downto 0);
            dx_m_wr_tvalid          : out std_logic;
            dx_m_wr_tdata           : out std_logic_vector(15 downto 0);
            dx_m_wr_tmask           : out std_logic_vector(1 downto 0);

            bp_m_wr_tvalid          : out std_logic;
            bp_m_wr_tdata           : out std_logic_vector(15 downto 0);

            sp_m_wr_tvalid          : out std_logic;
            sp_m_wr_tdata           : out std_logic_vector(15 downto 0);
            di_m_wr_tvalid          : out std_logic;
            di_m_wr_tdata           : out std_logic_vector(15 downto 0);
            si_m_wr_tvalid          : out std_logic;
            si_m_wr_tdata           : out std_logic_vector(15 downto 0);

            ds_m_wr_tvalid          : out std_logic;
            ds_m_wr_tdata           : out std_logic_vector(15 downto 0);
            es_m_wr_tvalid          : out std_logic;
            es_m_wr_tdata           : out std_logic_vector(15 downto 0);
            ss_m_wr_tvalid          : out std_logic;
            ss_m_wr_tdata           : out std_logic_vector(15 downto 0);

            flags_m_wr_tvalid       : out std_logic;
            flags_m_wr_tdata        : out std_logic_vector(15 downto 0);

            jmp_lock_m_wr_tvalid    : out std_logic;

            m_axis_jump_tvalid      : out std_logic;
            m_axis_jump_tdata       : out cpu86_jump_t;

            lsu_req_m_tvalid        : out std_logic;
            lsu_req_m_tready        : in std_logic;
            lsu_req_m_tcmd          : out std_logic;
            lsu_req_m_twidth        : out std_logic;
            lsu_req_m_taddr         : out std_logic_vector(19 downto 0);
            lsu_req_m_tdata         : out std_logic_vector(15 downto 0);

            io_req_m_tvalid         : out std_logic;
            io_req_m_tready         : in std_logic;
            io_req_m_tdata          : out std_logic_vector(39 downto 0);

            io_rd_s_tvalid          : in std_logic;
            io_rd_s_tready          : out std_logic;
            io_rd_s_tdata           : in std_logic_vector(15 downto 0);

            dbg_m_tvalid            : out std_logic;
            dbg_m_tdata             : out std_logic_vector(31 downto 0);

            div_intr_m_tvalid       : out std_logic;
            div_intr_m_tdata        : out intr_t;

            bnd_intr_m_tvalid       : out std_logic;
            bnd_intr_m_tdata        : out intr_t;

            event_jump              : out std_logic
        );
    end component cpu86_exec_mexec;

    component cpu86_exec_lsu is
        port (
            clk                     : in std_logic;
            resetn                  : in std_logic;

            lsu_req_s_tvalid        : in std_logic;
            lsu_req_s_tready        : out std_logic;
            lsu_req_s_tcmd          : in std_logic;
            lsu_req_s_taddr         : in std_logic_vector(19 downto 0);
            lsu_req_s_twidth        : in std_logic;
            lsu_req_s_tdata         : in std_logic_vector(15 downto 0);

            dcache_s_tvalid         : in std_logic;
            dcache_s_tdata          : in std_logic_vector(15 downto 0);

            m_axis_mem_req_tvalid   : out std_logic;
            m_axis_mem_req_tready   : in std_logic;
            m_axis_mem_req_tdata    : out std_logic_vector(63 downto 0);

            mem_rd_s_tvalid         : in std_logic;
            mem_rd_s_tdata          : in std_logic_vector(31 downto 0);

            lsu_rd_m_tvalid         : out std_logic;
            lsu_rd_m_tready         : in std_logic;
            lsu_rd_m_tdata          : out std_logic_vector(15 downto 0)
        );
    end component cpu86_exec_lsu;

    component cpu86_dcache is
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
    end component cpu86_dcache;

    signal exec_resetn              : std_logic;

    signal jmp_lock_tvalid          : std_logic;
    signal jmp_lock_lock_tvalid     : std_logic;
    signal jmp_lock_wr_tvalid       : std_logic;

    signal ds_tvalid                : std_logic;
    signal ds_tdata                 : std_logic_vector(15 downto 0);
    signal ds_lock_tvalid           : std_logic;
    signal ds_wr_tvalid             : std_logic;
    signal ds_wr_tdata              : std_logic_vector(15 downto 0);

    signal ss_tvalid                : std_logic;
    signal ss_tdata                 : std_logic_vector(15 downto 0);
    signal ss_lock_tvalid           : std_logic;
    signal ss_wr_tvalid             : std_logic;
    signal ss_wr_tdata              : std_logic_vector(15 downto 0);

    signal es_tvalid                : std_logic;
    signal es_tdata                 : std_logic_vector(15 downto 0);
    signal es_lock_tvalid           : std_logic;
    signal es_wr_tvalid             : std_logic;
    signal es_wr_tdata              : std_logic_vector(15 downto 0);

    signal ax_tvalid                : std_logic;
    signal ax_tdata                 : std_logic_vector(15 downto 0);
    signal ax_lock_tvalid           : std_logic;
    signal ax_wr_tvalid             : std_logic;
    signal ax_wr_tdata              : std_logic_vector(15 downto 0);
    signal ax_wr_tmask              : std_logic_vector(1 downto 0);

    signal bx_tvalid                : std_logic;
    signal bx_tdata                 : std_logic_vector(15 downto 0);
    signal bx_lock_tvalid           : std_logic;
    signal bx_wr_tvalid             : std_logic;
    signal bx_wr_tdata              : std_logic_vector(15 downto 0);
    signal bx_wr_tmask              : std_logic_vector(1 downto 0);

    signal cx_tvalid                : std_logic;
    signal cx_tdata                 : std_logic_vector(15 downto 0);
    signal cx_lock_tvalid           : std_logic;
    signal cx_wr_tvalid             : std_logic;
    signal cx_wr_tdata              : std_logic_vector(15 downto 0);
    signal cx_wr_tmask              : std_logic_vector(1 downto 0);
    signal cx_wr_tkeep_lock         : std_logic;

    signal dx_tvalid                : std_logic;
    signal dx_tdata                 : std_logic_vector(15 downto 0);
    signal dx_lock_tvalid           : std_logic;
    signal dx_wr_tvalid             : std_logic;
    signal dx_wr_tdata              : std_logic_vector(15 downto 0);
    signal dx_wr_tmask              : std_logic_vector(1 downto 0);

    signal sp_tvalid                : std_logic;
    signal sp_tdata                 : std_logic_vector(15 downto 0);
    signal sp_lock_tvalid           : std_logic;
    signal sp_wr_tvalid             : std_logic;
    signal sp_wr_tdata              : std_logic_vector(15 downto 0);

    signal bp_tvalid                : std_logic;
    signal bp_tdata                 : std_logic_vector(15 downto 0);
    signal bp_lock_tvalid           : std_logic;
    signal bp_wr_tvalid             : std_logic;
    signal bp_wr_tdata              : std_logic_vector(15 downto 0);

    signal si_tvalid                : std_logic;
    signal si_tdata                 : std_logic_vector(15 downto 0);
    signal si_lock_tvalid           : std_logic;
    signal si_wr_tvalid             : std_logic;
    signal si_wr_tdata              : std_logic_vector(15 downto 0);

    signal di_tvalid                : std_logic;
    signal di_tdata                 : std_logic_vector(15 downto 0);
    signal di_lock_tvalid           : std_logic;
    signal di_wr_tvalid             : std_logic;
    signal di_wr_tdata              : std_logic_vector(15 downto 0);

    signal flags_tvalid             : std_logic;
    signal flags_tdata              : std_logic_vector(15 downto 0);
    signal flags_lock_tvalid        : std_logic;
    signal flags_wr_tvalid          : std_logic;
    signal flags_wr_tdata           : std_logic_vector(15 downto 0);

    signal rr_tvalid                : std_logic;
    signal rr_tready                : std_logic;
    signal rr_tdata                 : rr_instr_t;
    signal rr_tuser                 : user_t;

    signal micro_tvalid             : std_logic;
    signal micro_tready             : std_logic;
    signal micro_tdata              : micro_op_t;

    signal ifeu_ax_wr_tvalid        : std_logic;
    signal ifeu_ax_wr_tdata         : std_logic_vector(15 downto 0);
    signal ifeu_ax_wr_tmask         : std_logic_vector(1 downto 0);
    signal ifeu_bx_wr_tvalid        : std_logic;
    signal ifeu_bx_wr_tdata         : std_logic_vector(15 downto 0);
    signal ifeu_bx_wr_tmask         : std_logic_vector(1 downto 0);
    signal ifeu_cx_wr_tvalid        : std_logic;
    signal ifeu_cx_wr_tdata         : std_logic_vector(15 downto 0);
    signal ifeu_cx_wr_tmask         : std_logic_vector(1 downto 0);
    signal ifeu_dx_wr_tvalid        : std_logic;
    signal ifeu_dx_wr_tdata         : std_logic_vector(15 downto 0);
    signal ifeu_dx_wr_tmask         : std_logic_vector(1 downto 0);

    signal ifeu_bp_wr_tvalid        : std_logic;
    signal ifeu_bp_wr_tdata         : std_logic_vector(15 downto 0);
    signal ifeu_sp_wr_tvalid        : std_logic;
    signal ifeu_sp_wr_tdata         : std_logic_vector(15 downto 0);
    signal ifeu_di_wr_tvalid        : std_logic;
    signal ifeu_di_wr_tdata         : std_logic_vector(15 downto 0);
    signal ifeu_si_wr_tvalid        : std_logic;
    signal ifeu_si_wr_tdata         : std_logic_vector(15 downto 0);

    signal ifeu_ds_wr_tvalid        : std_logic;
    signal ifeu_ds_wr_tdata         : std_logic_vector(15 downto 0);
    signal ifeu_es_wr_tvalid        : std_logic;
    signal ifeu_es_wr_tdata         : std_logic_vector(15 downto 0);
    signal ifeu_ss_wr_tvalid        : std_logic;
    signal ifeu_ss_wr_tdata         : std_logic_vector(15 downto 0);

    signal mexec_ax_wr_tvalid       : std_logic;
    signal mexec_ax_wr_tdata        : std_logic_vector(15 downto 0);
    signal mexec_ax_wr_tmask        : std_logic_vector(1 downto 0);
    signal mexec_bx_wr_tvalid       : std_logic;
    signal mexec_bx_wr_tdata        : std_logic_vector(15 downto 0);
    signal mexec_bx_wr_tmask        : std_logic_vector(1 downto 0);
    signal mexec_cx_wr_tvalid       : std_logic;
    signal mexec_cx_wr_tdata        : std_logic_vector(15 downto 0);
    signal mexec_cx_wr_tmask        : std_logic_vector(1 downto 0);
    signal mexec_dx_wr_tvalid       : std_logic;
    signal mexec_dx_wr_tdata        : std_logic_vector(15 downto 0);
    signal mexec_dx_wr_tmask        : std_logic_vector(1 downto 0);

    signal mexec_bp_wr_tvalid       : std_logic;
    signal mexec_bp_wr_tdata        : std_logic_vector(15 downto 0);

    signal mexec_sp_wr_tvalid       : std_logic;
    signal mexec_sp_wr_tdata        : std_logic_vector(15 downto 0);

    signal mexec_di_wr_tvalid       : std_logic;
    signal mexec_di_wr_tdata        : std_logic_vector(15 downto 0);

    signal mexec_si_wr_tvalid       : std_logic;
    signal mexec_si_wr_tdata        : std_logic_vector(15 downto 0);

    signal mexec_ds_wr_tvalid       : std_logic;
    signal mexec_ds_wr_tdata        : std_logic_vector(15 downto 0);
    signal mexec_es_wr_tvalid       : std_logic;
    signal mexec_es_wr_tdata        : std_logic_vector(15 downto 0);
    signal mexec_ss_wr_tvalid       : std_logic;
    signal mexec_ss_wr_tdata        : std_logic_vector(15 downto 0);

    signal jump_tvalid              : std_logic;
    signal jump_tdata               : cpu86_jump_t;

    signal lsu_req_tvalid           : std_logic;
    signal lsu_req_tready           : std_logic;
    signal lsu_req_tcmd             : std_logic;
    signal lsu_req_twidth           : std_logic;
    signal lsu_req_taddr            : std_logic_vector(19 downto 0);
    signal lsu_req_tdata            : std_logic_vector(15 downto 0);

    signal lsu_rd_tvalid            : std_logic;
    signal lsu_rd_tready            : std_logic;
    signal lsu_rd_tdata             : std_logic_vector(15 downto 0);

    signal dcache_tvalid            : std_logic;
    signal dcache_tready            : std_logic;
    signal dcache_tcmd              : std_logic;
    signal dcache_taddr             : std_logic_vector(19 downto 0);
    signal dcache_twidth            : std_logic;
    signal dcache_tdata             : std_logic_vector(15 downto 0);
    signal dcache_thit              : std_logic;
    signal dcache_tcache            : std_logic_vector(15 downto 0);

    signal fifo_instr_m_tdata       : slv_decoded_instr_t;

    signal instr_m_tvalid           : std_logic;
    signal instr_m_tready           : std_logic;
    signal instr_m_tdata            : decoded_instr_t;
    signal instr_m_tuser            : user_t;

    signal mexec_dbg_tvalid         : std_logic;
    signal mexec_dbg_tdata          : std_logic_vector(31 downto 0);

    signal div_intr_s_tvalid        : std_logic;
    signal div_intr_s_tready        : std_logic;
    signal div_intr_s_tdata         : intr_t;

    signal div_intr_m_tvalid        : std_logic;
    signal div_intr_m_tready        : std_logic;
    signal div_intr_m_tdata         : intr_t;

    signal ext_intr_s_tready        : std_logic;
    signal ext_intr_m_tvalid        : std_logic;
    signal ext_intr_m_tready        : std_logic;
    signal ext_intr_m_tdata         : std_logic_vector(7 downto 0);

    signal bnd_intr_s_tvalid        : std_logic;
    signal bnd_intr_s_tready        : std_logic;
    signal bnd_intr_s_tdata         : intr_t;

    signal bnd_intr_m_tvalid        : std_logic;
    signal bnd_intr_m_tready        : std_logic;
    signal bnd_intr_m_tdata         : intr_t;

    signal masked_interrupt         : std_logic;

    signal event_jump               : std_logic;

begin

    -- module cpu86_exec_reg instantiation
    cpu_reg_jmp_lock : cpu86_exec_reg generic map (
        DATA_WIDTH              => 16,
        INIT_VALUE              => x"0000"
    ) port map (
        clk                     => clk,
        resetn                  => exec_resetn,

        wr_s_tvalid             => jmp_lock_wr_tvalid,
        wr_s_tdata              => (others => '0') ,
        wr_s_tmask              => "11",

        lock_s_tvalid           => jmp_lock_lock_tvalid,
        unlk_s_tvalid           => '0',

        reg_m_tvalid            => jmp_lock_tvalid,
        reg_m_tdata             => open
    );

    -- module cpu86_exec_reg instantiation
    cpu_reg_ds : cpu86_exec_reg generic map (
        DATA_WIDTH              => 16,
        INIT_VALUE              => x"0000"
    ) port map (
        clk                     => clk,
        resetn                  => resetn,

        wr_s_tvalid             => ds_wr_tvalid,
        wr_s_tdata              => ds_wr_tdata,
        wr_s_tmask              => "11",

        lock_s_tvalid           => ds_lock_tvalid,
        unlk_s_tvalid           => event_jump,

        reg_m_tvalid            => ds_tvalid,
        reg_m_tdata             => ds_tdata
    );

    -- module cpu86_exec_reg instantiation
    cpu_reg_ss : cpu86_exec_reg generic map (
        DATA_WIDTH              => 16,
        INIT_VALUE              => x"0000"
    ) port map (
        clk                     => clk,
        resetn                  => resetn,

        wr_s_tvalid             => ss_wr_tvalid,
        wr_s_tdata              => ss_wr_tdata,
        wr_s_tmask              => "11",

        lock_s_tvalid           => ss_lock_tvalid,
        unlk_s_tvalid           => event_jump,

        reg_m_tvalid            => ss_tvalid,
        reg_m_tdata             => ss_tdata
    );

    -- module cpu86_exec_reg instantiation
    cpu_reg_es : cpu86_exec_reg generic map (
        DATA_WIDTH              => 16,
        INIT_VALUE              => x"0000"
    ) port map (
        clk                     => clk,
        resetn                  => resetn,

        wr_s_tvalid             => es_wr_tvalid,
        wr_s_tdata              => es_wr_tdata,
        wr_s_tmask              => "11",

        lock_s_tvalid           => es_lock_tvalid,
        unlk_s_tvalid           => event_jump,

        reg_m_tvalid            => es_tvalid,
        reg_m_tdata             => es_tdata
    );

    -- module cpu86_exec_reg instantiation
    cpu_reg_ax : cpu86_exec_reg generic map (
        DATA_WIDTH              => 16,
        INIT_VALUE              => x"0000"
    ) port map (
        clk                     => clk,
        resetn                  => resetn,

        wr_s_tvalid             => ax_wr_tvalid,
        wr_s_tdata              => ax_wr_tdata,
        wr_s_tmask              => ax_wr_tmask,

        lock_s_tvalid           => ax_lock_tvalid,
        unlk_s_tvalid           => event_jump,

        reg_m_tvalid            => ax_tvalid,
        reg_m_tdata             => ax_tdata
    );

    -- module cpu86_exec_reg instantiation
    cpu_reg_bx : cpu86_exec_reg generic map (
        DATA_WIDTH              => 16,
        INIT_VALUE              => x"0000"
    ) port map (
        clk                     => clk,
        resetn                  => resetn,

        wr_s_tvalid             => bx_wr_tvalid,
        wr_s_tdata              => bx_wr_tdata,
        wr_s_tmask              => bx_wr_tmask,

        lock_s_tvalid           => bx_lock_tvalid,
        unlk_s_tvalid           => event_jump,

        reg_m_tvalid            => bx_tvalid,
        reg_m_tdata             => bx_tdata
    );

    -- module cpu86_exec_reg instantiation
    cpu_reg_cx : cpu86_exec_reg generic map (
        DATA_WIDTH              => 16,
        INIT_VALUE              => x"0000"
    ) port map (
        clk                     => clk,
        resetn                  => resetn,

        wr_s_tvalid             => cx_wr_tvalid,
        wr_s_tdata              => cx_wr_tdata,
        wr_s_tmask              => cx_wr_tmask,

        lock_s_tvalid           => cx_lock_tvalid,
        unlk_s_tvalid           => event_jump,

        reg_m_tvalid            => cx_tvalid,
        reg_m_tdata             => cx_tdata
    );

    -- module cpu86_exec_reg instantiation
    cpu_reg_dx : cpu86_exec_reg generic map (
        DATA_WIDTH              => 16,
        INIT_VALUE              => x"0000"
    ) port map (
        clk                     => clk,
        resetn                  => resetn,

        wr_s_tvalid             => dx_wr_tvalid,
        wr_s_tdata              => dx_wr_tdata,
        wr_s_tmask              => dx_wr_tmask,

        lock_s_tvalid           => dx_lock_tvalid,
        unlk_s_tvalid           => event_jump,

        reg_m_tvalid            => dx_tvalid,
        reg_m_tdata             => dx_tdata
    );

    -- module cpu86_exec_reg instantiation
    cpu_reg_bp : cpu86_exec_reg generic map (
        DATA_WIDTH              => 16,
        INIT_VALUE              => x"0000"
    ) port map (
        clk                     => clk,
        resetn                  => resetn,

        wr_s_tvalid             => bp_wr_tvalid,
        wr_s_tdata              => bp_wr_tdata,
        wr_s_tmask              => "11",

        lock_s_tvalid           => bp_lock_tvalid,
        unlk_s_tvalid           => event_jump,

        reg_m_tvalid            => bp_tvalid,
        reg_m_tdata             => bp_tdata
    );

    -- module cpu86_exec_reg instantiation
    cpu_reg_sp : cpu86_exec_reg generic map (
        DATA_WIDTH              => 16,
        INIT_VALUE              => x"0000"
    ) port map (
        clk                     => clk,
        resetn                  => resetn,

        wr_s_tvalid             => sp_wr_tvalid,
        wr_s_tdata              => sp_wr_tdata,
        wr_s_tmask              => "11",

        lock_s_tvalid           => sp_lock_tvalid,
        unlk_s_tvalid           => event_jump,

        reg_m_tvalid            => sp_tvalid,
        reg_m_tdata             => sp_tdata
    );

    -- module cpu86_exec_reg instantiation
    cpu_reg_di : cpu86_exec_reg generic map (
        DATA_WIDTH              => 16,
        INIT_VALUE              => x"0000"
    ) port map (
        clk                     => clk,
        resetn                  => resetn,

        wr_s_tvalid             => di_wr_tvalid,
        wr_s_tdata              => di_wr_tdata,
        wr_s_tmask              => "11",

        lock_s_tvalid           => di_lock_tvalid,
        unlk_s_tvalid           => event_jump,

        reg_m_tvalid            => di_tvalid,
        reg_m_tdata             => di_tdata
    );

    -- module cpu86_exec_reg instantiation
    cpu_reg_si : cpu86_exec_reg generic map (
        DATA_WIDTH              => 16,
        INIT_VALUE              => x"0000"
    ) port map (
        clk                     => clk,
        resetn                  => resetn,

        wr_s_tvalid             => si_wr_tvalid,
        wr_s_tdata              => si_wr_tdata,
        wr_s_tmask              => "11",

        lock_s_tvalid           => si_lock_tvalid,
        unlk_s_tvalid           => event_jump,

        reg_m_tvalid            => si_tvalid,
        reg_m_tdata             => si_tdata
    );

    -- module cpu86_exec_reg instantiation
    cpu_flags_inst : cpu86_exec_reg generic map (
        DATA_WIDTH              => 16,
        INIT_VALUE              => x"0202"
    ) port map (
        clk                     => clk,
        resetn                  => resetn,

        wr_s_tvalid             => flags_wr_tvalid,
        wr_s_tdata              => flags_wr_tdata,
        wr_s_tmask              => "11",

        lock_s_tvalid           => flags_lock_tvalid,
        unlk_s_tvalid           => event_jump,

        reg_m_tvalid            => flags_tvalid,
        reg_m_tdata             => flags_tdata
    );


    -- module axis_reg instantiation
    div_interrupt_reg_inst : axis_reg generic map (
        DATA_WIDTH              => div_intr_s_tdata'length
    ) port map (
        clk                     => clk,
        resetn                  => resetn,

        in_s_tvalid             => div_intr_s_tvalid,
        in_s_tready             => div_intr_s_tready,
        in_s_tdata              => div_intr_s_tdata,

        out_m_tvalid            => div_intr_m_tvalid,
        out_m_tready            => div_intr_m_tready,
        out_m_tdata             => div_intr_m_tdata
    );


    -- module axis_reg instantiation
    external_interrupt_reg_inst : axis_reg generic map (
        DATA_WIDTH              => 8
    ) port map (
        clk                     => clk,
        resetn                  => resetn,

        in_s_tvalid             => masked_interrupt,
        in_s_tready             => ext_intr_s_tready,
        in_s_tdata              => interrupt_data,

        out_m_tvalid            => ext_intr_m_tvalid,
        out_m_tready            => ext_intr_m_tready,
        out_m_tdata             => ext_intr_m_tdata
    );

    -- module axis_reg instantiation
    bnd_interrupt_reg_inst : axis_reg generic map (
        DATA_WIDTH              => bnd_intr_s_tdata'length
    ) port map (
        clk                     => clk,
        resetn                  => resetn,

        in_s_tvalid             => bnd_intr_s_tvalid,
        in_s_tready             => bnd_intr_s_tready,
        in_s_tdata              => bnd_intr_s_tdata,

        out_m_tvalid            => bnd_intr_m_tvalid,
        out_m_tready            => bnd_intr_m_tready,
        out_m_tdata             => bnd_intr_m_tdata
    );

    -- module axis_fifo instantiation
    axis_fifo_inst_0 : axis_fifo_er generic map (
        FIFO_DEPTH              => 16,
        FIFO_WIDTH              => DECODED_INSTR_T_WIDTH
    ) port map (
        clk                     => clk,
        resetn                  => exec_resetn,

        s_axis_fifo_tvalid      => instr_s_tvalid,
        s_axis_fifo_tready      => instr_s_tready,
        s_axis_fifo_tdata       => instr_s_tdata,

        m_axis_fifo_tvalid      => instr_m_tvalid,
        m_axis_fifo_tready      => instr_m_tready,
        m_axis_fifo_tdata       => fifo_instr_m_tdata
    );

    -- module axis_fifo instantiation
    axis_fifo_inst_1 : axis_fifo_er generic map (
        FIFO_DEPTH              => 16,
        FIFO_WIDTH              => 48
    ) port map (
        clk                     => clk,
        resetn                  => exec_resetn,

        s_axis_fifo_tvalid      => instr_s_tvalid and instr_s_tready,
        s_axis_fifo_tready      => open,
        s_axis_fifo_tdata       => instr_s_tuser,

        m_axis_fifo_tvalid      => open,
        m_axis_fifo_tready      => instr_m_tready,
        m_axis_fifo_tdata       => instr_m_tuser
    );

    instr_m_tdata <= slv_to_decoded_instr_t(fifo_instr_m_tdata);

    -- module cpu86_exec_register_reader instantiation
    cpu86_exec_register_reader_inst : cpu86_exec_register_reader port map (
        clk                     => clk,
        resetn                  => exec_resetn,

        instr_s_tvalid          => instr_m_tvalid,
        instr_s_tready          => instr_m_tready,
        instr_s_tdata           => instr_m_tdata,
        instr_s_tuser           => instr_m_tuser,

        ext_intr_s_tvalid       => ext_intr_m_tvalid,
        ext_intr_s_tready       => open,
        ext_intr_s_tdata        => ext_intr_m_tdata,

        ds_s_tvalid             => ds_tvalid,
        ds_s_tdata              => ds_tdata,
        ds_m_lock_tvalid        => ds_lock_tvalid,

        ss_s_tvalid             => ss_tvalid,
        ss_s_tdata              => ss_tdata,
        ss_m_lock_tvalid        => ss_lock_tvalid,

        es_s_tvalid             => es_tvalid,
        es_s_tdata              => es_tdata,
        es_m_lock_tvalid        => es_lock_tvalid,

        ax_s_tvalid             => ax_tvalid,
        ax_s_tdata              => ax_tdata,
        ax_m_lock_tvalid        => ax_lock_tvalid,

        bx_s_tvalid             => bx_tvalid,
        bx_s_tdata              => bx_tdata,
        bx_m_lock_tvalid        => bx_lock_tvalid,

        cx_s_tvalid             => cx_tvalid,
        cx_s_tdata              => cx_tdata,
        cx_m_lock_tvalid        => cx_lock_tvalid,

        dx_s_tvalid             => dx_tvalid,
        dx_s_tdata              => dx_tdata,
        dx_m_lock_tvalid        => dx_lock_tvalid,

        sp_s_tvalid             => sp_tvalid,
        sp_s_tdata              => sp_tdata,
        sp_m_lock_tvalid        => sp_lock_tvalid,

        bp_s_tvalid             => bp_tvalid,
        bp_s_tdata              => bp_tdata,
        bp_m_lock_tvalid        => bp_lock_tvalid,

        si_s_tvalid             => si_tvalid,
        si_s_tdata              => si_tdata,
        si_m_lock_tvalid        => si_lock_tvalid,

        di_s_tvalid             => di_tvalid,
        di_s_tdata              => di_tdata,
        di_m_lock_tvalid        => di_lock_tvalid,

        flags_s_tvalid          => flags_tvalid,
        flags_s_tdata           => flags_tdata,
        flags_m_lock_tvalid     => flags_lock_tvalid,

        rr_m_tvalid             => rr_tvalid,
        rr_m_tready             => rr_tready,
        rr_m_tdata              => rr_tdata,
        rr_m_tuser              => rr_tuser
    );

    -- module cpu86_exec_ifeu instantiation
    cpu86_exec_ifeu_inst : cpu86_exec_ifeu port map (
        clk                     => clk,
        resetn                  => exec_resetn,

        jmp_lock_s_tvalid       => jmp_lock_tvalid,

        rr_s_tvalid             => rr_tvalid,
        rr_s_tready             => rr_tready,
        rr_s_tdata              => rr_tdata,
        rr_s_tuser              => rr_tuser,

        div_intr_s_tvalid       => div_intr_m_tvalid,
        div_intr_s_tready       => div_intr_m_tready,
        div_intr_s_tdata        => div_intr_m_tdata,

        bnd_intr_s_tvalid       => bnd_intr_m_tvalid,
        bnd_intr_s_tready       => bnd_intr_m_tready,
        bnd_intr_s_tdata        => bnd_intr_m_tdata,

        micro_m_tvalid          => micro_tvalid,
        micro_m_tready          => micro_tready,
        micro_m_tdata           => micro_tdata,

        ax_m_wr_tvalid          => ifeu_ax_wr_tvalid,
        ax_m_wr_tdata           => ifeu_ax_wr_tdata,
        ax_m_wr_tmask           => ifeu_ax_wr_tmask,
        bx_m_wr_tvalid          => ifeu_bx_wr_tvalid,
        bx_m_wr_tdata           => ifeu_bx_wr_tdata,
        bx_m_wr_tmask           => ifeu_bx_wr_tmask,
        cx_m_wr_tvalid          => ifeu_cx_wr_tvalid,
        cx_m_wr_tdata           => ifeu_cx_wr_tdata,
        cx_m_wr_tmask           => ifeu_cx_wr_tmask,
        dx_m_wr_tvalid          => ifeu_dx_wr_tvalid,
        dx_m_wr_tdata           => ifeu_dx_wr_tdata,
        dx_m_wr_tmask           => ifeu_dx_wr_tmask,

        bp_m_wr_tvalid          => ifeu_bp_wr_tvalid,
        bp_m_wr_tdata           => ifeu_bp_wr_tdata,
        sp_m_wr_tvalid          => ifeu_sp_wr_tvalid,
        sp_m_wr_tdata           => ifeu_sp_wr_tdata,
        di_m_wr_tvalid          => ifeu_di_wr_tvalid,
        di_m_wr_tdata           => ifeu_di_wr_tdata,
        si_m_wr_tvalid          => ifeu_si_wr_tvalid,
        si_m_wr_tdata           => ifeu_si_wr_tdata,

        ds_m_wr_tvalid          => ifeu_ds_wr_tvalid,
        ds_m_wr_tdata           => ifeu_ds_wr_tdata,
        es_m_wr_tvalid          => ifeu_es_wr_tvalid,
        es_m_wr_tdata           => ifeu_es_wr_tdata,
        ss_m_wr_tvalid          => ifeu_ss_wr_tvalid,
        ss_m_wr_tdata           => ifeu_ss_wr_tdata,

        ext_intr_s_tvalid       => ext_intr_m_tvalid,
        ext_intr_s_tready       => ext_intr_m_tready,
        ext_intr_s_tdata        => (others => '0') ,

        jmp_lock_m_lock_tvalid  => jmp_lock_lock_tvalid
    );

    -- module cpu86_exec_mexec instantiation
    cpu86_exec_mexec_inst : cpu86_exec_mexec port map (
        clk                     => clk,
        resetn                  => exec_resetn,

        micro_s_tvalid          => micro_tvalid,
        micro_s_tready          => micro_tready,
        micro_s_tdata           => micro_tdata,

        lsu_rd_s_tvalid         => lsu_rd_tvalid,
        lsu_rd_s_tready         => lsu_rd_tready,
        lsu_rd_s_tdata          => lsu_rd_tdata,

        flags_s_tdata           => flags_tdata,

        ax_m_wr_tvalid          => mexec_ax_wr_tvalid,
        ax_m_wr_tdata           => mexec_ax_wr_tdata,
        ax_m_wr_tmask           => mexec_ax_wr_tmask,
        bx_m_wr_tvalid          => mexec_bx_wr_tvalid,
        bx_m_wr_tdata           => mexec_bx_wr_tdata,
        bx_m_wr_tmask           => mexec_bx_wr_tmask,
        cx_m_wr_tvalid          => mexec_cx_wr_tvalid,
        cx_m_wr_tdata           => mexec_cx_wr_tdata,
        cx_m_wr_tmask           => mexec_cx_wr_tmask,
        dx_m_wr_tvalid          => mexec_dx_wr_tvalid,
        dx_m_wr_tdata           => mexec_dx_wr_tdata,
        dx_m_wr_tmask           => mexec_dx_wr_tmask,

        bp_m_wr_tvalid          => mexec_bp_wr_tvalid,
        bp_m_wr_tdata           => mexec_bp_wr_tdata,
        sp_m_wr_tvalid          => mexec_sp_wr_tvalid,
        sp_m_wr_tdata           => mexec_sp_wr_tdata,
        di_m_wr_tvalid          => mexec_di_wr_tvalid,
        di_m_wr_tdata           => mexec_di_wr_tdata,
        si_m_wr_tvalid          => mexec_si_wr_tvalid,
        si_m_wr_tdata           => mexec_si_wr_tdata,

        ds_m_wr_tvalid          => mexec_ds_wr_tvalid,
        ds_m_wr_tdata           => mexec_ds_wr_tdata,
        es_m_wr_tvalid          => mexec_es_wr_tvalid,
        es_m_wr_tdata           => mexec_es_wr_tdata,
        ss_m_wr_tvalid          => mexec_ss_wr_tvalid,
        ss_m_wr_tdata           => mexec_ss_wr_tdata,

        m_axis_jump_tvalid      => jump_tvalid,
        m_axis_jump_tdata       => jump_tdata,

        jmp_lock_m_wr_tvalid    => jmp_lock_wr_tvalid,

        flags_m_wr_tvalid       => flags_wr_tvalid,
        flags_m_wr_tdata        => flags_wr_tdata,

        lsu_req_m_tvalid        => lsu_req_tvalid,
        lsu_req_m_tready        => lsu_req_tready,
        lsu_req_m_tcmd          => lsu_req_tcmd,
        lsu_req_m_twidth        => lsu_req_twidth,
        lsu_req_m_taddr         => lsu_req_taddr,
        lsu_req_m_tdata         => lsu_req_tdata,

        io_req_m_tvalid         => io_req_m_tvalid,
        io_req_m_tready         => io_req_m_tready,
        io_req_m_tdata          => io_req_m_tdata,

        io_rd_s_tvalid          => io_rd_s_tvalid,
        io_rd_s_tready          => io_rd_s_tready,
        io_rd_s_tdata           => io_rd_s_tdata,

        dbg_m_tvalid            => mexec_dbg_tvalid,
        dbg_m_tdata             => mexec_dbg_tdata,

        div_intr_m_tvalid       => div_intr_s_tvalid,
        div_intr_m_tdata        => div_intr_s_tdata,

        bnd_intr_m_tvalid       => bnd_intr_s_tvalid,
        bnd_intr_m_tdata        => bnd_intr_s_tdata,

        event_jump              => event_jump
    );

    -- module cpu86_dcache instantiation
    cpu86_dcache_inst : cpu86_dcache port map (
        clk                     => clk,
        resetn                  => resetn,

        dcache_s_tvalid         => lsu_req_tvalid,
        dcache_s_tready         => lsu_req_tready,
        dcache_s_tcmd           => lsu_req_tcmd,
        dcache_s_taddr          => lsu_req_taddr,
        dcache_s_twidth         => lsu_req_twidth,
        dcache_s_tdata          => lsu_req_tdata,

        dcache_m_tvalid         => dcache_tvalid,
        dcache_m_tready         => dcache_tready,
        dcache_m_tcmd           => dcache_tcmd,
        dcache_m_taddr          => dcache_taddr,
        dcache_m_twidth         => dcache_twidth,
        dcache_m_tdata          => dcache_tdata,
        dcache_m_thit           => dcache_thit,
        dcache_m_tcache         => dcache_tcache
    );

    -- module cpu86_exec_lsu instantiation
    cpu86_exec_lsu_inst : cpu86_exec_lsu port map (
        clk                     => clk,
        resetn                  => resetn,

        lsu_req_s_tvalid        => dcache_tvalid,
        lsu_req_s_tready        => dcache_tready,
        lsu_req_s_tcmd          => dcache_tcmd,
        lsu_req_s_taddr         => dcache_taddr,
        lsu_req_s_twidth        => dcache_twidth,
        lsu_req_s_tdata         => dcache_tdata,

        dcache_s_tvalid         => dcache_thit,
        dcache_s_tdata          => dcache_tcache,

        m_axis_mem_req_tvalid   => mem_req_m_tvalid,
        m_axis_mem_req_tready   => mem_req_m_tready,
        m_axis_mem_req_tdata    => mem_req_m_tdata,

        mem_rd_s_tvalid         => mem_rd_s_tvalid,
        mem_rd_s_tdata          => mem_rd_s_tdata,

        lsu_rd_m_tvalid         => lsu_rd_tvalid,
        lsu_rd_m_tready         => lsu_rd_tready,
        lsu_rd_m_tdata          => lsu_rd_tdata
    );

    -- assigns
    exec_resetn <= '0' when resetn = '0' or (event_jump = '1') else '1';

    ax_wr_tvalid <= '1' when (event_jump = '0') and (ifeu_ax_wr_tvalid = '1' or mexec_ax_wr_tvalid = '1') else '0';
    bx_wr_tvalid <= '1' when (event_jump = '0') and (ifeu_bx_wr_tvalid = '1' or mexec_bx_wr_tvalid = '1') else '0';
    cx_wr_tvalid <= '1' when (event_jump = '0') and (ifeu_cx_wr_tvalid = '1' or mexec_cx_wr_tvalid = '1') else '0';
    dx_wr_tvalid <= '1' when (event_jump = '0') and (ifeu_dx_wr_tvalid = '1' or mexec_dx_wr_tvalid = '1') else '0';
    bp_wr_tvalid <= '1' when (event_jump = '0') and (ifeu_bp_wr_tvalid = '1' or mexec_bp_wr_tvalid = '1') else '0';
    sp_wr_tvalid <= '1' when (event_jump = '0') and (ifeu_sp_wr_tvalid = '1' or mexec_sp_wr_tvalid = '1') else '0';
    di_wr_tvalid <= '1' when (event_jump = '0') and (ifeu_di_wr_tvalid = '1' or mexec_di_wr_tvalid = '1') else '0';
    si_wr_tvalid <= '1' when (event_jump = '0') and (ifeu_si_wr_tvalid = '1' or mexec_si_wr_tvalid = '1') else '0';

    ds_wr_tvalid <= '1' when (event_jump = '0') and (ifeu_ds_wr_tvalid = '1' or mexec_ds_wr_tvalid = '1') else '0';
    ss_wr_tvalid <= '1' when (event_jump = '0') and (ifeu_ss_wr_tvalid = '1' or mexec_ss_wr_tvalid = '1') else '0';
    es_wr_tvalid <= '1' when (event_jump = '0') and (ifeu_es_wr_tvalid = '1' or mexec_es_wr_tvalid = '1') else '0';

    ax_wr_tdata <= mexec_ax_wr_tdata when mexec_ax_wr_tvalid = '1' else ifeu_ax_wr_tdata;
    bx_wr_tdata <= mexec_bx_wr_tdata when mexec_bx_wr_tvalid = '1' else ifeu_bx_wr_tdata;
    cx_wr_tdata <= mexec_cx_wr_tdata when mexec_cx_wr_tvalid = '1' else ifeu_cx_wr_tdata;
    dx_wr_tdata <= mexec_dx_wr_tdata when mexec_dx_wr_tvalid = '1' else ifeu_dx_wr_tdata;
    ax_wr_tmask <= mexec_ax_wr_tmask when mexec_ax_wr_tvalid = '1' else ifeu_ax_wr_tmask;
    bx_wr_tmask <= mexec_bx_wr_tmask when mexec_bx_wr_tvalid = '1' else ifeu_bx_wr_tmask;
    cx_wr_tmask <= mexec_cx_wr_tmask when mexec_cx_wr_tvalid = '1' else ifeu_cx_wr_tmask;
    dx_wr_tmask <= mexec_dx_wr_tmask when mexec_dx_wr_tvalid = '1' else ifeu_dx_wr_tmask;

    bp_wr_tdata <= mexec_bp_wr_tdata when mexec_bp_wr_tvalid = '1' else ifeu_bp_wr_tdata;
    sp_wr_tdata <= mexec_sp_wr_tdata when mexec_sp_wr_tvalid = '1' else ifeu_sp_wr_tdata;
    di_wr_tdata <= mexec_di_wr_tdata when mexec_di_wr_tvalid = '1' else ifeu_di_wr_tdata;
    si_wr_tdata <= mexec_si_wr_tdata when mexec_si_wr_tvalid = '1' else ifeu_si_wr_tdata;

    ds_wr_tdata <= mexec_ds_wr_tdata when mexec_ds_wr_tvalid = '1' else ifeu_ds_wr_tdata;
    ss_wr_tdata <= mexec_ss_wr_tdata when mexec_ss_wr_tvalid = '1' else ifeu_ss_wr_tdata;
    es_wr_tdata <= mexec_es_wr_tdata when mexec_es_wr_tvalid = '1' else ifeu_es_wr_tdata;

    req_m_tvalid <= jump_tvalid;
    req_m_tdata <= jump_tdata;

    masked_interrupt <= '1' when interrupt_valid = '1' and flags_tdata(FLAG_IF) = '1' else '0';
    interrupt_ack <= '1' when masked_interrupt = '1' and ext_intr_s_tready = '1' else '0';

    --cs, ip, ds, es, ss, ax, bx, dx, cx, bp, di, si, sp, Flags8
    dbg_m_tvalid <= mexec_dbg_tvalid;
    dbg_m_tdata(14*16-1 downto 13*16) <= mexec_dbg_tdata(31 downto 16);
    dbg_m_tdata(13*16-1 downto 12*16) <= mexec_dbg_tdata(15 downto 0);
    dbg_m_tdata(12*16-1 downto 11*16) <= ds_tdata;
    dbg_m_tdata(11*16-1 downto 10*16) <= es_tdata;
    dbg_m_tdata(10*16-1 downto  9*16) <= ss_tdata;
    dbg_m_tdata( 9*16-1 downto  8*16) <= ax_tdata;
    dbg_m_tdata( 8*16-1 downto  7*16) <= bx_tdata;
    dbg_m_tdata( 7*16-1 downto  6*16) <= cx_tdata;
    dbg_m_tdata( 6*16-1 downto  5*16) <= dx_tdata;
    dbg_m_tdata( 5*16-1 downto  4*16) <= bp_tdata;
    dbg_m_tdata( 4*16-1 downto  3*16) <= di_tdata;
    dbg_m_tdata( 3*16-1 downto  2*16) <= si_tdata;
    dbg_m_tdata( 2*16-1 downto  1*16) <= sp_tdata;
    dbg_m_tdata( 1*16-1 downto  0*16) <= flags_tdata;

end architecture;
