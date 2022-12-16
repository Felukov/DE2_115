
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

entity cpu86_exec_mexec is
    port (
        clk                     : in std_logic;
        resetn                  : in std_logic;

        s_axis_micro_tvalid     : in std_logic;
        s_axis_micro_tready     : out std_logic;
        s_axis_micro_tlast      : in std_logic;
        s_axis_micro_tdata      : in micro_op_t;

        lsu_rd_s_tvalid         : in std_logic;
        lsu_rd_s_tready         : out std_logic;
        lsu_rd_s_tdata          : in std_logic_vector(15 downto 0);

        s_axis_fl_tdata         : in std_logic_vector(15 downto 0);

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

        m_axis_fl_wr_tvalid     : out std_logic;
        m_axis_fl_wr_tdata      : out std_logic_vector(15 downto 0);

        m_axis_jump_tvalid      : out std_logic;
        m_axis_jump_tdata       : out cpu86_jump_t;

        jmp_lock_m_wr_tvalid    : out std_logic;

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

        m_axis_intr_tvalid      : out std_logic;
        m_axis_intr_tdata       : out intr_t;
        m_axis_intr_tuser       : out std_logic_vector(7 downto 0);

        event_jump              : out std_logic
    );
end entity cpu86_exec_mexec;

architecture rtl of cpu86_exec_mexec is
    attribute enum_encoding : string;

    type flag_src_t is (RES_USER, RES_DATA, RES_MEM, CMD_FLG);
    attribute enum_encoding of flag_src_t : type is "sequential";

    type res_t is record
        code                    : std_logic_vector(3 downto 0);
        dmask                   : std_logic_vector(1 downto 0);
        dval_hi                 : std_logic_vector(15 downto 0);
        dval_lo                 : std_logic_vector(15 downto 0); --dest
    end record;

    component cpu86_exec_mexec_alu is
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            req_s_tvalid        : in std_logic;
            req_s_tdata         : in alu_req_t;
            req_s_tuser         : in std_logic;

            res_m_tvalid        : out std_logic;
            res_m_tdata         : out alu_res_t;
            res_m_tuser         : out std_logic_vector(15 downto 0)
        );
    end component cpu86_exec_mexec_alu;

    component cpu86_exec_mexec_mul is
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            req_s_tvalid        : in std_logic;
            req_s_tdata         : in mul_req_t;

            res_m_tvalid        : out std_logic;
            res_m_tdata         : out mul_res_t;
            res_m_tuser         : out std_logic_vector(15 downto 0)
        );
    end component cpu86_exec_mexec_mul;

    component cpu86_exec_mexec_div is
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            req_s_tvalid        : in std_logic;
            req_s_tdata         : in div_req_t;

            res_m_tvalid        : out std_logic;
            res_m_tdata         : out div_res_t;
            res_m_tuser         : out std_logic_vector(15 downto 0)
        );
    end component cpu86_exec_mexec_div;

    component cpu86_exec_mexec_bcd is
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            req_s_tvalid        : in std_logic;
            req_s_tdata         : in bcd_req_t;
            req_s_tuser         : in std_logic_vector(15 downto 0);

            res_m_tvalid        : out std_logic;
            res_m_tdata         : out bcd_res_t;
            res_m_tuser         : out std_logic_vector(15 downto 0)
        );
    end component cpu86_exec_mexec_bcd;

    component cpu86_exec_mexec_shf is
        generic (
            DATA_WIDTH          : natural := 16
        );
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            req_s_tvalid        : in std_logic;
            req_s_tdata         : in shf_req_t;
            req_s_tuser         : in std_logic_vector(15 downto 0);

            res_m_tvalid        : out std_logic;
            res_m_tdata         : out shf_res_t;
            res_m_tuser         : out std_logic_vector(15 downto 0)
        );
    end component cpu86_exec_mexec_shf;

    component cpu86_exec_mexec_str is
        port (
            clk                     : in std_logic;
            resetn                  : in std_logic;

            s_axis_req_tvalid       : in std_logic;
            s_axis_req_tdata        : in str_req_t;

            m_axis_res_tvalid       : out std_logic;
            m_axis_res_tdata        : out str_res_t;
            m_axis_res_tuser        : out std_logic_vector(15 downto 0);

            m_axis_lsu_req_tvalid   : out std_logic;
            m_axis_lsu_req_tready   : in std_logic;
            m_axis_lsu_req_tcmd     : out std_logic;
            m_axis_lsu_req_twidth   : out std_logic;
            m_axis_lsu_req_taddr    : out std_logic_vector(19 downto 0);
            m_axis_lsu_req_tdata    : out std_logic_vector(15 downto 0);

            s_axis_lsu_rd_tvalid    : in std_logic;
            s_axis_lsu_rd_tready    : out std_logic;
            s_axis_lsu_rd_tdata     : in std_logic_vector(15 downto 0);

            m_axis_io_req_tvalid    : out std_logic;
            m_axis_io_req_tready    : in std_logic;
            m_axis_io_req_tdata     : out std_logic_vector(39 downto 0);

            s_axis_io_rd_tvalid     : in std_logic;
            s_axis_io_rd_tready     : out std_logic;
            s_axis_io_rd_tdata      : in std_logic_vector(15 downto 0);

            event_interrupt         : in std_logic
        );
    end component;

    signal micro_tvalid         : std_logic;
    signal micro_tready         : std_logic;
    signal micro_tlast          : std_logic;
    signal micro_tdata          : micro_op_t;

    signal alu_a_wait_fifo      : std_logic;
    signal alu_b_wait_fifo      : std_logic;

    signal alu_req_tvalid       : std_logic;
    signal alu_req_tdata        : alu_req_t := (
        code        => (others =>'0'),
        w           => '0',
        wb          => '0',
        dreg        => AX,
        dmask       => "00",
        upd_fl      => '0',
        aval        => (others =>'0'),
        bval        => (others =>'0')
    );

    signal alu_res_tvalid       : std_logic;
    signal alu_res_tdata        : alu_res_t;
    signal alu_res_tuser        : std_logic_vector(15 downto 0);

    signal mul_req_tvalid       : std_logic;
    signal mul_req_tdata        : mul_req_t := (
        code        => (others => '0'),
        w           => '0',
        wb          => '0',
        dreg        => AX,
        aval        => (others => '0'),
        bval        => (others => '0')
    );
    signal mul_res_tvalid       : std_logic;
    signal mul_res_tdata        : mul_res_t;
    signal mul_res_tuser        : std_logic_vector(15 downto 0);

    signal div_req_tvalid       : std_logic;
    signal div_req_tdata        : div_req_t;
    signal div_res_tvalid       : std_logic;
    signal div_res_tdata        : div_res_t;
    signal div_res_tuser        : std_logic_vector(15 downto 0);

    signal bcd_req_tvalid       : std_logic;
    signal bcd_req_tdata        : bcd_req_t := (
        code        => (others => '0'),
        sval        => (others => '0')
    );
    signal bcd_res_tvalid       : std_logic;
    signal bcd_res_tdata        : bcd_res_t;
    signal bcd_res_tuser        : std_logic_vector(15 downto 0);

    signal shf8_req_tvalid      : std_logic;
    signal shf8_req_tdata       : shf_req_t;
    signal shf8_res_tvalid      : std_logic;
    signal shf8_res_tdata       : shf_res_t;
    signal shf8_res_tuser       : std_logic_vector(15 downto 0);

    signal shf16_req_tvalid     : std_logic;
    signal shf16_req_tdata      : shf_req_t;
    signal shf16_res_tvalid     : std_logic;
    signal shf16_res_tdata      : shf_res_t;
    signal shf16_res_tuser      : std_logic_vector(15 downto 0);

    signal str_req_tvalid       : std_logic;
    signal str_req_tdata        : str_req_t;

    signal str_res_tvalid       : std_logic;
    signal str_res_tdata        : str_res_t;
    signal str_res_tuser        : std_logic_vector(15 downto 0);

    signal str_lsu_req_tvalid   : std_logic;
    signal str_lsu_req_tready   : std_logic;
    signal str_lsu_req_tcmd     : std_logic;
    signal str_lsu_req_twidth   : std_logic;
    signal str_lsu_req_taddr    : std_logic_vector(19 downto 0);
    signal str_lsu_req_tdata    : std_logic_vector(15 downto 0);

    signal str_lsu_rd_tvalid    : std_logic;
    signal str_lsu_rd_tready    : std_logic;
    signal str_lsu_rd_tdata     : std_logic_vector(15 downto 0);

    signal res_tvalid           : std_logic;
    signal res_tdata            : res_t := (
        code        => (others=>'0'),
        dmask       => (others=>'0'),
        dval_lo     => (others=>'0'),
        dval_hi     => (others=>'0')
    );
    signal res_tuser            : std_logic_vector(15 downto 0);

    signal lsu_req_tvalid       : std_logic;
    signal lsu_req_tready       : std_logic;
    signal lsu_req_tcmd         : std_logic;
    signal lsu_req_taddr        : std_logic_vector(19 downto 0);
    signal lsu_req_twidth       : std_logic;
    signal lsu_req_tdata        : std_logic_vector(15 downto 0);

    signal flags_tdata          : std_logic_vector(11 downto 0);
    signal flags_wr_tvalid      : std_logic;
    signal flags_wr_tdata       : std_logic_vector(11 downto 0);
    signal flags_wr_be          : std_logic_vector(11 downto 0);
    signal flags_wr_new_val     : std_logic;
    signal flags_toggle_cf      : std_logic;
    signal flags_src            : flag_src_t;
    signal flags_wr_vector      : std_logic_vector(11 downto 0);

    signal mem_buf_0_tdata      : std_logic_vector(15 downto 0);
    signal mem_buf_1_tdata      : std_logic_vector(15 downto 0);
    signal mexec_busy           : std_logic;
    signal mexec_wait_fifo      : std_logic;
    signal mexec_wait_mul       : std_logic;
    signal mexec_wait_div       : std_logic;
    signal mexec_wait_bcd       : std_logic;
    signal mexec_wait_shf       : std_logic;
    signal mexec_wait_jmp       : std_logic;
    signal mexec_wait_str       : std_logic;

    signal mexec_unlk_fl        : std_logic;

    signal alu_wait_fifo        : std_logic;
    signal mul_wait_fifo        : std_logic;
    signal div_wait_fifo        : std_logic;
    signal one_wait_fifo        : std_logic;
    signal io_wait_fifo         : std_logic;
    signal shf8_wait_fifo       : std_logic;
    signal shf16_wait_fifo      : std_logic;

    signal mem_wait_alu         : std_logic;
    signal mem_wait_shf         : std_logic;
    signal mem_wait_fifo        : std_logic;

    signal jmp_busy             : std_logic;
    signal jmp_wait_alu         : std_logic;
    signal jmp_wait_mem_cs      : std_logic;
    signal jmp_wait_mem_ip      : std_logic;
    signal jmp_cond             : micro_op_jmp_cond_t;

    signal jmp_tvalid           : std_logic;
    signal jmp_inst_cs          : std_logic_vector(15 downto 0);
    signal jmp_inst_ip          : std_logic_vector(15 downto 0);
    signal jmp_jump_cs          : std_logic_vector(15 downto 0);
    signal jmp_jump_ip          : std_logic_vector(15 downto 0);
    signal jmp_take             : std_logic;
    signal jmp_bpu_first        : std_logic;
    signal jmp_bpu_taken        : std_logic;
    signal jmp_bpu_taken_cs     : std_logic_vector(15 downto 0);
    signal jmp_bpu_taken_ip     : std_logic_vector(15 downto 0);

    signal jmp_dout_tvalid      : std_logic;
    signal jmp_dout_tdata       : cpu86_jump_t;

    signal res_tdata_selector   : std_logic_vector(7 downto 0);
    signal flags_wr_selector    : std_logic_vector(8 downto 0);

    signal io_cmd_w             : std_logic;
    signal io_cmd_wb            : std_logic;

    signal lsu_req_a_selector   : std_logic_vector(1 downto 0);

    signal op_cnt               : natural range 0 to 3;
    signal op_inc_hs            : std_logic;
    signal op_dec_hs            : std_logic;

    signal div_intr_tvalid      : std_logic;
    signal bnd_intr_tvalid      : std_logic;
    signal trap_intr_tvalid     : std_logic;
    signal trap_intr_tvalid_mask: std_logic;

    signal trap_check_tf_tvalid : std_logic;

    signal dout_intr_tdata      : intr_t;
    signal dout_intr_tuser      : std_logic_vector(7 downto 0);

    signal mem_dreg             : reg_t;
    signal mem_dmask            : std_logic_vector(1 downto 0);

begin

    -- i/o assigns
    flags_tdata         <= s_axis_fl_tdata(11 downto 0);

    micro_tvalid        <= s_axis_micro_tvalid;
    s_axis_micro_tready <= micro_tready;
    micro_tlast         <= s_axis_micro_tlast;
    micro_tdata         <= s_axis_micro_tdata;

    m_axis_fl_wr_tvalid <= flags_wr_tvalid;
    m_axis_fl_wr_tdata  <= "1111" & flags_wr_tdata;
    m_axis_jump_tvalid  <= jmp_dout_tvalid;
    m_axis_jump_tdata   <= jmp_dout_tdata;

    m_axis_intr_tvalid  <= '1' when div_intr_tvalid = '1' or bnd_intr_tvalid = '1' or (trap_intr_tvalid = '1' and trap_intr_tvalid_mask = '0') else '0';
    m_axis_intr_tdata   <= dout_intr_tdata;
    m_axis_intr_tuser   <= dout_intr_tuser;

    -- module cpu86_exec_mexec_alu instantiation
    mexec_alu_inst : cpu86_exec_mexec_alu port map (
        clk                     => clk,
        resetn                  => resetn,

        req_s_tvalid            => alu_req_tvalid,
        req_s_tdata             => alu_req_tdata,
        req_s_tuser             => flags_tdata(FLAG_CF),

        res_m_tvalid            => alu_res_tvalid,
        res_m_tdata             => alu_res_tdata,
        res_m_tuser             => alu_res_tuser
    );

    mexec_mul_inst : cpu86_exec_mexec_mul port map (
        clk                     => clk,
        resetn                  => resetn,

        req_s_tvalid            => mul_req_tvalid,
        req_s_tdata             => mul_req_tdata,

        res_m_tvalid            => mul_res_tvalid,
        res_m_tdata             => mul_res_tdata,
        res_m_tuser             => mul_res_tuser
    );

    mexec_div_inst : cpu86_exec_mexec_div port map (
        clk                     => clk,
        resetn                  => resetn,

        req_s_tvalid            => div_req_tvalid,
        req_s_tdata             => div_req_tdata,

        res_m_tvalid            => div_res_tvalid,
        res_m_tdata             => div_res_tdata,
        res_m_tuser             => div_res_tuser
    );

    mexec_bcd_inst : cpu86_exec_mexec_bcd port map (
        clk                     => clk,
        resetn                  => resetn,

        req_s_tvalid            => bcd_req_tvalid,
        req_s_tdata             => bcd_req_tdata,
        req_s_tuser             => "1111" & flags_tdata,

        res_m_tvalid            => bcd_res_tvalid,
        res_m_tdata             => bcd_res_tdata,
        res_m_tuser             => bcd_res_tuser
    );

    mexec_shf8_inst : cpu86_exec_mexec_shf generic map (
        DATA_WIDTH              => 8
    ) port map (
        clk                     => clk,
        resetn                  => resetn,

        req_s_tvalid            => shf8_req_tvalid,
        req_s_tdata             => shf8_req_tdata,
        req_s_tuser             => "1111" & flags_tdata,

        res_m_tvalid            => shf8_res_tvalid,
        res_m_tdata             => shf8_res_tdata,
        res_m_tuser             => shf8_res_tuser
    );

    mexec_shf16_inst : cpu86_exec_mexec_shf generic map (
        DATA_WIDTH              => 16
    ) port map (
        clk                     => clk,
        resetn                  => resetn,

        req_s_tvalid            => shf16_req_tvalid,
        req_s_tdata             => shf16_req_tdata,
        req_s_tuser             => "1111" & flags_tdata,

        res_m_tvalid            => shf16_res_tvalid,
        res_m_tdata             => shf16_res_tdata,
        res_m_tuser             => shf16_res_tuser
    );

    mexec_str_inst : cpu86_exec_mexec_str port map (
        clk                     => CLK,
        resetn                  => RESETN,

        s_axis_req_tvalid       => str_req_tvalid,
        s_axis_req_tdata        => str_req_tdata,

        m_axis_res_tvalid       => str_res_tvalid,
        m_axis_res_tdata        => str_res_tdata,
        m_axis_res_tuser        => str_res_tuser,

        m_axis_lsu_req_tvalid   => str_lsu_req_tvalid,
        m_axis_lsu_req_tready   => str_lsu_req_tready,
        m_axis_lsu_req_tcmd     => str_lsu_req_tcmd,
        m_axis_lsu_req_twidth   => str_lsu_req_twidth,
        m_axis_lsu_req_taddr    => str_lsu_req_taddr,
        m_axis_lsu_req_tdata    => str_lsu_req_tdata,

        s_axis_lsu_rd_tvalid    => str_lsu_rd_tvalid,
        s_axis_lsu_rd_tready    => str_lsu_rd_tready,
        s_axis_lsu_rd_tdata     => str_lsu_rd_tdata,

        m_axis_io_req_tvalid    => io_req_m_tvalid,
        m_axis_io_req_tready    => io_req_m_tready,
        m_axis_io_req_tdata     => io_req_m_tdata,

        s_axis_io_rd_tvalid     => io_rd_s_tvalid,
        s_axis_io_rd_tready     => io_rd_s_tready,
        s_axis_io_rd_tdata      => io_rd_s_tdata,

        event_interrupt         => '0'
    );

    lsu_req_m_tvalid <= lsu_req_tvalid;
    lsu_req_tready <= lsu_req_m_tready;
    lsu_req_m_tcmd <= lsu_req_tcmd;
    lsu_req_m_taddr <= lsu_req_taddr;
    lsu_req_m_twidth <= lsu_req_twidth;
    lsu_req_m_tdata <= lsu_req_tdata;

    bx_m_wr_tdata <= res_tdata.dval_lo;
    dx_m_wr_tdata <= res_tdata.dval_hi;

    bx_m_wr_tmask <= res_tdata.dmask;
    dx_m_wr_tmask <= res_tdata.dmask;

    bp_m_wr_tdata <= res_tdata.dval_lo;
    sp_m_wr_tdata <= res_tdata.dval_lo;
    ds_m_wr_tdata <= res_tdata.dval_lo;
    es_m_wr_tdata <= res_tdata.dval_lo;
    ss_m_wr_tdata <= res_tdata.dval_lo;

    micro_tready <= '1' when mexec_busy = '0' and
        mem_wait_alu = '0' and
        mem_wait_shf = '0' and
        --mem_wait_io = '0' and
        --mexec_wait_bcd = '0' and
        --mexec_wait_shf = '0' and
        --mexec_wait_jmp = '0' and
        (lsu_req_tvalid = '0' or (lsu_req_tvalid = '1' and lsu_req_tready = '1')) and
        (io_req_m_tvalid = '0' or (io_req_m_tvalid = '1' and io_req_m_tready = '1')) else '0';

    str_lsu_req_tready <= '1' when (lsu_req_tvalid = '0' or (lsu_req_tvalid = '1' and lsu_req_tready = '1')) else '0';

    lsu_rd_s_tready <= '1' when (mexec_wait_fifo = '1' or str_lsu_rd_tready = '1') else '0';
    str_lsu_rd_tvalid <= lsu_rd_s_tvalid;
    str_lsu_rd_tdata <= lsu_rd_s_tdata;

    flags_wr_tdata <= ((not flags_wr_be) and flags_tdata) or (flags_wr_be and flags_wr_vector);

    op_inc_hs <= alu_req_tvalid or div_req_tvalid or mul_req_tvalid or bcd_req_tvalid or shf8_req_tvalid or shf16_req_tvalid or str_req_tvalid;
    op_dec_hs <= alu_res_tvalid or div_res_tvalid or mul_res_tvalid or bcd_res_tvalid or shf8_res_tvalid or shf16_res_tvalid or str_res_tvalid;

    mexec_busy_proc : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                mexec_busy <= '0';
                mexec_wait_fifo <= '0';
                mexec_wait_mul <= '0';
                mexec_wait_div <= '0';
                mexec_wait_bcd <= '0';
                mexec_wait_shf <= '0';
                mexec_wait_jmp <= '0';
                mexec_wait_str <= '0';
            else

                if ((micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_MRD) = '1') or
                    (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_DIV) = '1') or
                    (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_MUL) = '1') or
                    (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_BCD) = '1') or
                    (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_SHF) = '1') or
                    (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_JMP) = '1') or
                    (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_STR) = '1'))
                then
                    mexec_busy <= '1';
                elsif (mexec_busy = '1') then
                    if not (mexec_wait_fifo = '1' xor (lsu_rd_s_tvalid = '1' and mexec_wait_fifo = '1')) and
                        not (mexec_wait_div = '1' xor div_res_tvalid = '1') and
                        not (mexec_wait_mul = '1' xor mul_res_tvalid = '1') and
                        not (mexec_wait_bcd = '1' xor bcd_res_tvalid = '1') and
                        not (mexec_wait_shf = '1' xor (shf8_res_tvalid = '1' or shf16_res_tvalid = '1')) and
                        not (mexec_wait_jmp = '1' xor jmp_tvalid = '1') and
                        not (mexec_wait_str = '1' xor str_res_tvalid = '1')
                    then
                        mexec_busy <= '0';
                    end if;
                end if;

                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_MRD) = '1') then
                    mexec_wait_fifo <= '1';
                elsif (mexec_busy = '1') then
                    if (lsu_rd_s_tvalid = '1') then
                        mexec_wait_fifo <= '0';
                    end if;
                end if;

                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_MUL) = '1') then
                    mexec_wait_mul <= '1';
                elsif (mul_res_tvalid = '1') then
                    mexec_wait_mul <= '0';
                end if;

                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_DIV) = '1') then
                    mexec_wait_div <= '1';
                elsif (div_res_tvalid = '1') then
                    mexec_wait_div <= '0';
                end if;

                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_BCD) = '1') then
                    mexec_wait_bcd <= '1';
                elsif (bcd_res_tvalid = '1') then
                    mexec_wait_bcd <= '0';
                end if;

                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_SHF) = '1') then
                    mexec_wait_shf <= '1';
                elsif (shf8_res_tvalid = '1' or shf16_res_tvalid = '1') then
                    mexec_wait_shf <= '0';
                end if;

                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_JMP) = '1') then
                    if ((micro_tdata.jump_cond = j_always and (micro_tdata.jump_cs_mem = '1' or micro_tdata.jump_ip_mem = '1')) or
                        (micro_tdata.jump_cond = cx_ne_0 or micro_tdata.jump_cond = cx_ne_0_and_zf or micro_tdata.jump_cond = cx_ne_0_and_nzf) or
                        (op_cnt /= 0 or op_inc_hs = '1'))
                    then
                        mexec_wait_jmp <= '1';
                    else
                        mexec_wait_jmp <= '0';
                    end if;
                elsif (jmp_tvalid = '1') then
                    mexec_wait_jmp <= '0';
                end if;

                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_STR) = '1') then
                    mexec_wait_str <= '1';
                elsif (str_res_tvalid = '1') then
                    mexec_wait_str <= '0';
                end if;

            end if;
        end if;
    end process;

    op_cnt_proc : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                op_cnt <= 0;
            else
                if (op_inc_hs = '1' and op_dec_hs = '1') then
                    op_cnt <= op_cnt;
                elsif (op_inc_hs = '1') then
                    op_cnt <= op_cnt + 1;
                elsif (op_dec_hs = '1') then
                    op_cnt <= op_cnt - 1;
                end if;
            end if;
        end if;
    end process;

    mul_proc : process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                mul_req_tvalid <= '0';
                mul_wait_fifo <= '0';
            else
                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_MUL) = '1' and micro_tdata.cmd(MICRO_OP_CMD_MRD) = '0') then
                    mul_req_tvalid <= '1';
                elsif (mul_wait_fifo = '1' and lsu_rd_s_tvalid = '1') then
                    mul_req_tvalid <= '1';
                else
                    mul_req_tvalid <= '0';
                end if;

                if (micro_tvalid = '1' and micro_tready = '1') then
                    if (micro_tdata.cmd(MICRO_OP_CMD_MUL) = '1' AND micro_tdata.cmd(MICRO_OP_CMD_MRD) = '1') then
                        mul_wait_fifo <= '1';
                    else
                        mul_wait_fifo <= '0';
                    end if;
                elsif (mul_wait_fifo = '1' and lsu_rd_s_tvalid = '1') then
                    mul_wait_fifo <= '0';
                end if;
            end if;

            if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_MUL) = '1') then
                mul_req_tdata.code <= micro_tdata.mul_code;
                mul_req_tdata.w <= micro_tdata.mul_w;
                mul_req_tdata.aval <= micro_tdata.mul_a_val;
                mul_req_tdata.bval <= micro_tdata.mul_b_val;
                mul_req_tdata.dreg <= micro_tdata.mul_dreg;
            elsif (mul_wait_fifo = '1' and lsu_rd_s_tvalid = '1') then
                mul_req_tdata.aval <= lsu_rd_s_tdata;
            end if;

        end if;
    end process;

    div_proc : process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                div_req_tvalid <= '0';
                div_wait_fifo <= '0';
            else
                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_DIV) = '1' and micro_tdata.cmd(MICRO_OP_CMD_MRD) = '0') then
                    div_req_tvalid <= '1';
                elsif (div_wait_fifo = '1' and lsu_rd_s_tvalid = '1') then
                    div_req_tvalid <= '1';
                else
                    div_req_tvalid <= '0';
                end if;

                if (micro_tvalid = '1' and micro_tready = '1') then
                    if (micro_tdata.cmd(MICRO_OP_CMD_DIV) = '1' AND micro_tdata.cmd(MICRO_OP_CMD_MRD) = '1') then
                        div_wait_fifo <= '1';
                    else
                        div_wait_fifo <= '0';
                    end if;
                elsif (div_wait_fifo = '1' and lsu_rd_s_tvalid = '1') then
                    div_wait_fifo <= '0';
                end if;
            end if;

            if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_DIV) = '1') then
                div_req_tdata.code <= micro_tdata.div_code;
                div_req_tdata.w    <= micro_tdata.div_w;
                div_req_tdata.nval <= micro_tdata.div_a_val;
                div_req_tdata.dval <= micro_tdata.div_b_val;
                div_req_tdata.dreg <= micro_tdata.div_dreg;
            elsif (div_wait_fifo = '1' and lsu_rd_s_tvalid = '1') then
                div_req_tdata.dval <= lsu_rd_s_tdata;
            end if;

        end if;
    end process;

    bcd_proc : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                bcd_req_tvalid <= '0';
            else
                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_BCD) = '1') then
                    bcd_req_tvalid <= '1';
                else
                    bcd_req_tvalid <= '0';
                end if;
            end if;

            if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_BCD) = '1') then
                bcd_req_tdata.code <= micro_tdata.bcd_code;
                bcd_req_tdata.sval <= micro_tdata.bcd_sval;
            end if;

        end if;
    end process;

    shf_proc : process (clk) begin

        if rising_edge(clk) then
            if resetn = '0' then
                shf8_req_tvalid <= '0';
                shf16_req_tvalid <= '0';
                shf8_wait_fifo <= '0';
                shf16_wait_fifo <= '0';
            else

                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_SHF) = '1' and
                    micro_tdata.cmd(MICRO_OP_CMD_MRD) = '0' and micro_tdata.shf_w = '0')
                then
                    shf8_req_tvalid <= '1';
                elsif (shf8_wait_fifo = '1' and lsu_rd_s_tvalid = '1') then
                    shf8_req_tvalid <= '1';
                else
                    shf8_req_tvalid <= '0';
                end if;

                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_SHF) = '1' and
                    micro_tdata.cmd(MICRO_OP_CMD_MRD) = '0' and micro_tdata.shf_w = '1')
                then
                    shf16_req_tvalid <= '1';
                elsif (shf16_wait_fifo = '1' and lsu_rd_s_tvalid = '1') then
                    shf16_req_tvalid <= '1';
                else
                    shf16_req_tvalid <= '0';
                end if;

                if (micro_tvalid = '1' and micro_tready = '1') then
                    if (micro_tdata.cmd(MICRO_OP_CMD_SHF) = '1'  and micro_tdata.shf_w = '0' and micro_tdata.cmd(MICRO_OP_CMD_MRD) = '1') then
                        shf8_wait_fifo <= '1';
                    else
                        shf8_wait_fifo <= '0';
                    end if;
                elsif (shf8_wait_fifo = '1' and lsu_rd_s_tvalid = '1') then
                    shf8_wait_fifo <= '0';
                end if;

                if (micro_tvalid = '1' and micro_tready = '1') then
                    if (micro_tdata.cmd(MICRO_OP_CMD_SHF) = '1'  and micro_tdata.shf_w = '1' and micro_tdata.cmd(MICRO_OP_CMD_MRD) = '1') then
                        shf16_wait_fifo <= '1';
                    else
                        shf16_wait_fifo <= '0';
                    end if;
                elsif (shf16_wait_fifo = '1' and lsu_rd_s_tvalid = '1') then
                    shf16_wait_fifo <= '0';
                end if;

            end if;

            if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_SHF) = '1' and micro_tdata.shf_w  = '0') then
                shf8_req_tdata.code     <= micro_tdata.shf_code;
                shf8_req_tdata.code_ex  <= micro_tdata.shf_code_ex;
                shf8_req_tdata.w        <= micro_tdata.shf_w;
                shf8_req_tdata.wb       <= micro_tdata.shf_wb;
                shf8_req_tdata.sval     <= micro_tdata.shf_sval;
                shf8_req_tdata.ival     <= micro_tdata.shf_ival;
                shf8_req_tdata.dreg     <= micro_tdata.shf_dreg;
                shf8_req_tdata.dmask    <= micro_tdata.shf_dmask;
            elsif (shf8_wait_fifo = '1' and lsu_rd_s_tvalid = '1') then
                shf8_req_tdata.sval     <= lsu_rd_s_tdata;
            end if;

            if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_SHF) = '1' and micro_tdata.shf_w  = '1') then
                shf16_req_tdata.code    <= micro_tdata.shf_code;
                shf16_req_tdata.code_ex <= micro_tdata.shf_code_ex;
                shf16_req_tdata.w       <= micro_tdata.shf_w;
                shf16_req_tdata.wb      <= micro_tdata.shf_wb;
                shf16_req_tdata.sval    <= micro_tdata.shf_sval;
                shf16_req_tdata.ival    <= micro_tdata.shf_ival;
                shf16_req_tdata.dreg    <= micro_tdata.shf_dreg;
                shf16_req_tdata.dmask   <= micro_tdata.shf_dmask;
            elsif (shf16_wait_fifo = '1' and lsu_rd_s_tvalid = '1') then
                shf16_req_tdata.sval    <= lsu_rd_s_tdata;
            end if;

        end if;

    end process;

    alu_proc : process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                alu_req_tvalid <= '0';
                alu_wait_fifo <= '0';
            else
                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_ALU) = '1' and micro_tdata.cmd(MICRO_OP_CMD_MRD) = '0') then
                    alu_req_tvalid <= '1';
                elsif (alu_wait_fifo = '1' and lsu_rd_s_tvalid = '1') then
                    alu_req_tvalid <= '1';
                else
                    alu_req_tvalid <= '0';
                end if;

                if (micro_tvalid = '1' and micro_tready = '1') then
                    if (micro_tdata.cmd(MICRO_OP_CMD_ALU) = '1' AND micro_tdata.cmd(MICRO_OP_CMD_MRD) = '1') then
                        alu_wait_fifo <= '1';
                    else
                        alu_wait_fifo <= '0';
                    end if;
                elsif (alu_wait_fifo = '1' and lsu_rd_s_tvalid = '1') then
                    alu_wait_fifo <= '0';
                end if;
            end if;

            if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_ALU) = '1') then
                alu_req_tdata.code <= micro_tdata.alu_code;
                alu_req_tdata.w <= micro_tdata.alu_w;
                alu_req_tdata.wb <= micro_tdata.alu_wb;

                if micro_tdata.alu_a_buf = '1' then
                    alu_req_tdata.aval <= mem_buf_0_tdata;
                else
                    alu_req_tdata.aval <= micro_tdata.alu_a_val;
                end if;

                alu_req_tdata.bval <= micro_tdata.alu_b_val;
                alu_req_tdata.dreg <= micro_tdata.alu_dreg;
                alu_req_tdata.dmask <= micro_tdata.alu_dmask;

                if (micro_tdata.alu_dreg = FL or micro_tdata.alu_upd_fl = '1') then
                    alu_req_tdata.upd_fl <= '1';
                else
                    alu_req_tdata.upd_fl <= '0';
                end if;

                alu_a_wait_fifo <= micro_tdata.alu_a_mem;
                alu_b_wait_fifo <= micro_tdata.alu_b_mem;

            elsif (alu_wait_fifo = '1' and lsu_rd_s_tvalid = '1') then
                if (alu_a_wait_fifo = '1') then
                    alu_req_tdata.aval <= lsu_rd_s_tdata;
                end if;

                if (alu_b_wait_fifo = '1') then
                    alu_req_tdata.bval <= lsu_rd_s_tdata;
                end if;

            end if;

        end if;
    end process;

    str_proc : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                str_req_tvalid <= '0';
            else
                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_STR) = '1') then
                    str_req_tvalid <= '1';
                else
                    str_req_tvalid <= '0';
                end if;
            end if;

            if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_STR) = '1') then
                str_req_tdata.code <= micro_tdata.str_code;
                str_req_tdata.rep <= micro_tdata.str_rep;
                str_req_tdata.rep_nz <= micro_tdata.str_rep_nz;
                str_req_tdata.direction <= micro_tdata.str_direction;
                str_req_tdata.w <= micro_tdata.str_w;
                str_req_tdata.io_port <= micro_tdata.str_port;
                str_req_tdata.ax_val <= micro_tdata.str_ax_val;
                str_req_tdata.cx_val <= micro_tdata.str_cx_val;
                str_req_tdata.es_val <= micro_tdata.str_es_val;
                str_req_tdata.di_val <= micro_tdata.str_di_val;
                str_req_tdata.ds_val <= micro_tdata.str_ds_val;
                str_req_tdata.si_val <= micro_tdata.str_si_val;
            end if;

        end if;
    end process;

    res_tdata_selector(0) <= alu_res_tvalid;
    res_tdata_selector(1) <= bcd_res_tvalid;
    res_tdata_selector(2) <= shf8_res_tvalid;
    res_tdata_selector(3) <= shf16_res_tvalid;
    res_tdata_selector(4) <= mul_res_tvalid;
    res_tdata_selector(5) <= div_res_tvalid;
    res_tdata_selector(6) <= str_res_tvalid;
    res_tdata_selector(7) <= '1' when lsu_rd_s_tvalid = '1' and lsu_rd_s_tready = '1' else '0';

    res_proc : process (clk) begin
        if rising_edge(clk) then

            case res_tdata_selector is
                when "00000010" =>
                    res_tdata.code <= bcd_res_tdata.code;
                    res_tdata.dmask <= bcd_res_tdata.dmask;
                    res_tdata.dval_lo <= bcd_res_tdata.dval(15 downto 0);
                    res_tdata.dval_hi <= bcd_res_tdata.dval(15 downto 0);
                    res_tuser <= bcd_res_tuser;
                when "00000100" =>
                    res_tdata.code <= shf8_res_tdata.code;
                    res_tdata.dmask <= shf8_res_tdata.dmask;
                    res_tdata.dval_lo(7 downto 0) <= shf8_res_tdata.dval(7 downto 0);
                    res_tdata.dval_hi(7 downto 0) <= shf8_res_tdata.dval(7 downto 0);
                    res_tuser <= shf8_res_tuser;
                when "00001000" =>
                    res_tdata.code <= shf16_res_tdata.code;
                    res_tdata.dmask <= shf16_res_tdata.dmask;
                    res_tdata.dval_lo <= shf16_res_tdata.dval(15 downto 0);
                    res_tdata.dval_hi <= shf16_res_tdata.dval(15 downto 0);
                    res_tuser <= shf16_res_tuser;
                when "00010000" =>
                    res_tdata.code <= mul_res_tdata.code;
                    res_tdata.dmask <= "11";
                    res_tdata.dval_lo <= mul_res_tdata.dval(15 downto 0);
                    if ((mul_res_tdata.code = IMUL_AXDX or mul_res_tdata.code = MUL_AXDX) and mul_res_tdata.w = '1' and mul_res_tdata.dreg = DX) then
                        res_tdata.dval_hi <= mul_res_tdata.dval(31 downto 16);
                    else
                        res_tdata.dval_hi <= mul_res_tdata.dval(15 downto 0);
                    end if;
                    res_tuser <= mul_res_tuser;
                when "00100000" =>
                    res_tdata.code <= div_res_tdata.code;
                    res_tdata.dmask <= "11";
                    if (div_res_tdata.code = DIVU_AAM) then
                        res_tdata.dval_lo <= div_res_tdata.qval(7 downto 0) & div_res_tdata.rval(7 downto 0);
                    else
                        if (div_res_tdata.w = '0') then
                            res_tdata.dval_lo <= div_res_tdata.rval(7 downto 0) & div_res_tdata.qval(7 downto 0);
                        else
                            res_tdata.dval_lo <= div_res_tdata.qval;
                        end if;
                    end if;
                    res_tdata.dval_hi <= div_res_tdata.rval;
                    res_tuser <= div_res_tuser;
                when "01000000" =>
                    res_tuser <= str_res_tuser;
                when "10000000" =>
                    res_tdata.dval_hi <= lsu_rd_s_tdata;
                    res_tdata.dval_lo <= lsu_rd_s_tdata;
                    res_tdata.dmask   <= mem_dmask;
                when others =>
                    res_tdata.code <= alu_res_tdata.code;
                    res_tdata.dmask <= alu_res_tdata.dmask;
                    res_tdata.dval_lo <= alu_res_tdata.dval(15 downto 0);
                    res_tdata.dval_hi <= alu_res_tdata.dval(15 downto 0);
                    res_tuser <= alu_res_tuser;
            end case;

        end if;
    end process;

    write_regs_proc : process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                ax_m_wr_tvalid <= '0';
                bx_m_wr_tvalid <= '0';
                cx_m_wr_tvalid <= '0';
                dx_m_wr_tvalid <= '0';
                bp_m_wr_tvalid <= '0';
                sp_m_wr_tvalid <= '0';
                di_m_wr_tvalid <= '0';
                si_m_wr_tvalid <= '0';
                ds_m_wr_tvalid <= '0';
                es_m_wr_tvalid <= '0';
                ss_m_wr_tvalid <= '0';
            else
                if ((lsu_rd_s_tvalid = '1' and lsu_rd_s_tready = '1' and mem_dreg = AX) or
                    (alu_res_tvalid = '1' and alu_res_tdata.wb = '1' and alu_res_tdata.dreg = AX) or
                    (mul_res_tvalid = '1' and (mul_res_tdata.dreg = AX or
                        ((mul_res_tdata.code = IMUL_AXDX or mul_res_tdata.code = MUL_AXDX) and mul_res_tdata.w = '1' and mul_res_tdata.dreg = DX))) or
                    (div_res_tvalid = '1' and div_res_tdata.overflow = '0') or
                    (shf8_res_tvalid = '1' and shf8_res_tdata.wb = '1' and shf8_res_tdata.dreg = AX) or
                    (shf16_res_tvalid = '1' and shf16_res_tdata.wb = '1' and shf16_res_tdata.dreg = AX) or
                    (str_res_tvalid = '1' and str_res_tdata.ax_upd_fl = '1') or
                    (bcd_res_tvalid = '1')) then
                    ax_m_wr_tvalid <= '1';
                else
                    ax_m_wr_tvalid <= '0';
                end if;

                if ((lsu_rd_s_tvalid = '1' and lsu_rd_s_tready = '1' and mem_dreg = BX) or
                    (alu_res_tvalid = '1' and alu_res_tdata.wb = '1' and alu_res_tdata.dreg = BX) or
                    (mul_res_tvalid = '1' and mul_res_tdata.dreg = BX) or
                    (shf8_res_tvalid = '1' and shf8_res_tdata.wb = '1' and shf8_res_tdata.dreg = BX) or
                    (shf16_res_tvalid = '1' and shf16_res_tdata.wb = '1' and shf16_res_tdata.dreg = BX)) then
                    bx_m_wr_tvalid <= '1';
                else
                    bx_m_wr_tvalid <= '0';
                end if;

                if ((lsu_rd_s_tvalid = '1' and lsu_rd_s_tready = '1' and mem_dreg = CX) or
                    (alu_res_tvalid = '1' and alu_res_tdata.wb = '1' and alu_res_tdata.dreg = CX) or
                    (mul_res_tvalid = '1' and mul_res_tdata.dreg = CX) or
                    (shf8_res_tvalid = '1' and shf8_res_tdata.wb = '1' and shf8_res_tdata.dreg = CX) or
                    (shf16_res_tvalid = '1' and shf16_res_tdata.wb = '1' and shf16_res_tdata.dreg = CX) or
                    (str_res_tvalid = '1' and str_res_tdata.rep = '1')) then
                    cx_m_wr_tvalid <= '1';
                else
                    cx_m_wr_tvalid <= '0';
                end if;

                if ((lsu_rd_s_tvalid = '1' and lsu_rd_s_tready = '1' and mem_dreg = DX) or
                    (alu_res_tvalid = '1' and alu_res_tdata.wb = '1' and alu_res_tdata.dreg = DX) or
                    (mul_res_tvalid = '1' and mul_res_tdata.dreg = DX) or
                    (div_res_tvalid = '1' and (div_res_tdata.code = DIVU_DIV or div_res_tdata.code = DIVU_IDIV) and
                        div_res_tdata.w = '1' and div_res_tdata.overflow = '0') or
                    (shf8_res_tvalid = '1' and shf8_res_tdata.wb = '1' and shf8_res_tdata.dreg = DX) or
                    (shf16_res_tvalid = '1' and shf16_res_tdata.wb = '1' and shf16_res_tdata.dreg = DX)) then
                    dx_m_wr_tvalid <= '1';
                else
                    dx_m_wr_tvalid <= '0';
                end if;

                if ((lsu_rd_s_tvalid = '1' and lsu_rd_s_tready = '1' and mem_dreg = BP) or
                    (alu_res_tvalid = '1' and alu_res_tdata.wb = '1' and alu_res_tdata.dreg = BP) or
                    (mul_res_tvalid = '1' and mul_res_tdata.dreg = BP) or
                    (shf8_res_tvalid = '1' and shf8_res_tdata.wb = '1' and shf8_res_tdata.dreg = BP) or
                    (shf16_res_tvalid = '1' and shf16_res_tdata.wb = '1' and shf16_res_tdata.dreg = BP)) then
                    bp_m_wr_tvalid <= '1';
                else
                    bp_m_wr_tvalid <= '0';
                end if;

                if ((lsu_rd_s_tvalid = '1' and lsu_rd_s_tready = '1' and mem_dreg = SP) or
                    (alu_res_tvalid = '1' and alu_res_tdata.wb = '1' and alu_res_tdata.dreg = SP) or
                    (mul_res_tvalid = '1' and mul_res_tdata.dreg = SP) or
                    (shf8_res_tvalid = '1' and shf8_res_tdata.wb = '1' and shf8_res_tdata.dreg = SP) or
                    (shf16_res_tvalid = '1' and shf16_res_tdata.wb = '1' and shf16_res_tdata.dreg = SP)) then
                    sp_m_wr_tvalid <= '1';
                else
                    sp_m_wr_tvalid <= '0';
                end if;

                if ((lsu_rd_s_tvalid = '1' and lsu_rd_s_tready = '1' and mem_dreg = DI) or
                    (alu_res_tvalid = '1' and alu_res_tdata.wb = '1' and alu_res_tdata.dreg = DI) or
                    (mul_res_tvalid = '1' and mul_res_tdata.dreg = DI) or
                    (shf8_res_tvalid = '1' and shf8_res_tdata.wb = '1' and shf8_res_tdata.dreg = DI) or
                    (shf16_res_tvalid = '1' and shf16_res_tdata.wb = '1' and shf16_res_tdata.dreg = DI) or
                    (str_res_tvalid = '1' and str_res_tdata.di_upd_fl = '1')) then
                    di_m_wr_tvalid <= '1';
                else
                    di_m_wr_tvalid <= '0';
                end if;

                if ((lsu_rd_s_tvalid = '1' and lsu_rd_s_tready = '1' and mem_dreg = SI) or
                    (alu_res_tvalid = '1' and alu_res_tdata.wb = '1' and alu_res_tdata.dreg = SI) or
                    (mul_res_tvalid = '1' and mul_res_tdata.dreg = SI) or
                    (shf8_res_tvalid = '1' and shf8_res_tdata.wb = '1' and shf8_res_tdata.dreg = SI) or
                    (shf16_res_tvalid = '1' and shf16_res_tdata.wb = '1' and shf16_res_tdata.dreg = SI) or
                    (str_res_tvalid = '1' and str_res_tdata.si_upd_fl = '1')) then
                    si_m_wr_tvalid <= '1';
                else
                    si_m_wr_tvalid <= '0';
                end if;

                if ((lsu_rd_s_tvalid = '1' and lsu_rd_s_tready = '1' and mem_dreg = DS) or
                    (alu_res_tvalid = '1' and alu_res_tdata.wb = '1' and alu_res_tdata.dreg = DS)) then
                    ds_m_wr_tvalid <= '1';
                else
                    ds_m_wr_tvalid <= '0';
                end if;

                if ((lsu_rd_s_tvalid = '1' and lsu_rd_s_tready = '1' and mem_dreg = ES) or
                    (alu_res_tvalid = '1' and alu_res_tdata.wb = '1' and alu_res_tdata.dreg = ES)) then
                    es_m_wr_tvalid <= '1';
                else
                    es_m_wr_tvalid <= '0';
                end if;

                if ((lsu_rd_s_tvalid = '1' and lsu_rd_s_tready = '1' and mem_dreg = SS) or
                    (alu_res_tvalid = '1' and alu_res_tdata.wb = '1' and alu_res_tdata.dreg = SS)) then
                    ss_m_wr_tvalid <= '1';
                else
                    ss_m_wr_tvalid <= '0';
                end if;

            end if;

            if (lsu_rd_s_tvalid = '1' and lsu_rd_s_tready = '1' and  mem_dreg = AX) then
                ax_m_wr_tdata <= lsu_rd_s_tdata;
                ax_m_wr_tmask <= mem_dmask;
            elsif (alu_res_tvalid = '1' and alu_res_tdata.wb = '1' and alu_res_tdata.dreg = AX) then
                ax_m_wr_tdata <= alu_res_tdata.dval(15 downto 0);
                ax_m_wr_tmask <= alu_res_tdata.dmask;
            elsif (mul_res_tvalid = '1' and mul_res_tdata.dreg = AX) or
                  (mul_res_tvalid = '1' and (mul_res_tdata.code = IMUL_AXDX or mul_res_tdata.code = MUL_AXDX) and mul_res_tdata.w = '1' and mul_res_tdata.dreg = DX) then
                ax_m_wr_tdata <= mul_res_tdata.dval(15 downto 0);
                ax_m_wr_tmask <= "11";
            elsif (div_res_tvalid = '1' and div_res_tdata.overflow = '0') then
                ax_m_wr_tmask <= "11";
                if (div_res_tdata.code = DIVU_AAM) then
                    ax_m_wr_tdata <= div_res_tdata.qval(7 downto 0) & div_res_tdata.rval(7 downto 0);
                else
                    if (div_res_tdata.w = '0') then
                        ax_m_wr_tdata <= div_res_tdata.rval(7 downto 0) & div_res_tdata.qval(7 downto 0);
                    else
                        ax_m_wr_tdata <= div_res_tdata.qval;
                    end if;
                end if;
            elsif (shf8_res_tvalid = '1' and shf8_res_tdata.wb = '1' and shf8_res_tdata.dreg = AX) then
                ax_m_wr_tdata(7 downto 0) <= shf8_res_tdata.dval(7 downto 0);
                ax_m_wr_tmask <= shf8_res_tdata.dmask;
            elsif (shf16_res_tvalid = '1' and shf16_res_tdata.wb = '1' and shf16_res_tdata.dreg = AX) then
                ax_m_wr_tdata <= shf16_res_tdata.dval;
                ax_m_wr_tmask <= shf16_res_tdata.dmask;
            elsif (bcd_res_tvalid = '1') then
                ax_m_wr_tmask <= bcd_res_tdata.dmask;
                ax_m_wr_tdata <= bcd_res_tdata.dval(15 downto 0);
            elsif (str_res_tvalid = '1' and str_res_tdata.ax_upd_fl = '1') then
                ax_m_wr_tdata <= str_res_tdata.ax_val;
                if (str_res_tdata.w = '1') then
                    ax_m_wr_tmask <= "11";
                else
                    ax_m_wr_tmask <= "01";
                end if;
            end if;

            if (lsu_rd_s_tvalid = '1' and lsu_rd_s_tready = '1' and mem_dreg = CX) then
                cx_m_wr_tdata <= lsu_rd_s_tdata;
                cx_m_wr_tmask <= mem_dmask;
            elsif (alu_res_tvalid = '1' and alu_res_tdata.wb = '1' and alu_res_tdata.dreg = CX) then
                cx_m_wr_tdata <= alu_res_tdata.dval(15 downto 0);
                cx_m_wr_tmask <= alu_res_tdata.dmask;
            elsif (mul_res_tvalid = '1' and mul_res_tdata.dreg = CX) then
                cx_m_wr_tdata <= mul_res_tdata.dval(15 downto 0);
                cx_m_wr_tmask <= "11";
            elsif (shf8_res_tvalid = '1' and shf8_res_tdata.wb = '1' and shf8_res_tdata.dreg = CX) then
                cx_m_wr_tdata(7 downto 0) <= shf8_res_tdata.dval(7 downto 0);
                cx_m_wr_tmask <= shf8_res_tdata.dmask;
            elsif (shf16_res_tvalid = '1' and shf16_res_tdata.wb = '1' and shf16_res_tdata.dreg = CX) then
                cx_m_wr_tdata <= shf16_res_tdata.dval;
                cx_m_wr_tmask <= shf16_res_tdata.dmask;
            elsif (str_res_tvalid = '1' and str_res_tdata.rep = '1') then
                cx_m_wr_tdata <= str_res_tdata.cx_val;
                cx_m_wr_tmask <= "11";
            end if;

            if (lsu_rd_s_tvalid = '1' and lsu_rd_s_tready = '1' and mem_dreg = DI) then
                di_m_wr_tdata <= lsu_rd_s_tdata;
            elsif (alu_res_tvalid = '1' and alu_res_tdata.wb = '1' and alu_res_tdata.dreg = DI) then
                di_m_wr_tdata <= alu_res_tdata.dval(15 downto 0);
            elsif (mul_res_tvalid = '1' and mul_res_tdata.dreg = DI) then
                di_m_wr_tdata <= mul_res_tdata.dval(15 downto 0);
            elsif (shf8_res_tvalid = '1' and shf8_res_tdata.wb = '1' and shf8_res_tdata.dreg = DI) then
                di_m_wr_tdata(7 downto 0) <= shf8_res_tdata.dval(7 downto 0);
            elsif (shf16_res_tvalid = '1' and shf16_res_tdata.wb = '1' and shf16_res_tdata.dreg = DI) then
                di_m_wr_tdata <= shf16_res_tdata.dval;
            elsif (str_res_tvalid = '1') then
                di_m_wr_tdata <= str_res_tdata.di_val;
            end if;

            if (lsu_rd_s_tvalid = '1' and lsu_rd_s_tready = '1' and mem_dreg = SI) then
                si_m_wr_tdata <= lsu_rd_s_tdata;
            elsif (alu_res_tvalid = '1' and alu_res_tdata.wb = '1' and alu_res_tdata.dreg = SI) then
                si_m_wr_tdata <= alu_res_tdata.dval(15 downto 0);
            elsif (mul_res_tvalid = '1' and mul_res_tdata.dreg = SI) then
                si_m_wr_tdata <= mul_res_tdata.dval(15 downto 0);
            elsif (shf8_res_tvalid = '1' and shf8_res_tdata.wb = '1' and shf8_res_tdata.dreg = SI) then
                si_m_wr_tdata(7 downto 0) <= shf8_res_tdata.dval(7 downto 0);
            elsif (shf16_res_tvalid = '1' and shf16_res_tdata.wb = '1' and shf16_res_tdata.dreg = SI) then
                si_m_wr_tdata <= shf16_res_tdata.dval;
            elsif (str_res_tvalid = '1') then
                si_m_wr_tdata <= str_res_tdata.si_val;
            end if;

        end if;
    end process;

    flags_wr_selector(0) <= '1' when micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_FLG) = '1' else '0';
    flags_wr_selector(1) <= '1' when alu_res_tvalid = '1' and alu_res_tdata.upd_fl = '1' else '0';
    flags_wr_selector(2) <= div_res_tvalid;
    flags_wr_selector(3) <= bcd_res_tvalid;
    flags_wr_selector(4) <= shf8_res_tvalid;
    flags_wr_selector(5) <= shf16_res_tvalid;
    flags_wr_selector(6) <= mul_res_tvalid;
    flags_wr_selector(7) <= str_res_tvalid;
    flags_wr_selector(8) <= '1' when micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_MRD) = '1' and micro_tdata.mem_dreg = FL else '0';

    flags_upd_proc : process (clk)
        constant UPD_OF : std_logic_vector(11 downto 0) := "1000" & "0000" & "0000";
        constant UPD_DF : std_logic_vector(11 downto 0) := "0100" & "0000" & "0000";
        constant UPD_IF : std_logic_vector(11 downto 0) := "0010" & "0000" & "0000";
        constant UPD_TF : std_logic_vector(11 downto 0) := "0001" & "0000" & "0000";
        constant UPD_SF : std_logic_vector(11 downto 0) := "0000" & "1000" & "0000";
        constant UPD_ZF : std_logic_vector(11 downto 0) := "0000" & "0100" & "0000";
        constant UPD_AF : std_logic_vector(11 downto 0) := "0000" & "0001" & "0000";
        constant UPD_PF : std_logic_vector(11 downto 0) := "0000" & "0000" & "0100";
        constant UPD_CF : std_logic_vector(11 downto 0) := "0000" & "0000" & "0001";
    begin
        if rising_edge(clk) then
            if resetn = '0' then
                flags_wr_tvalid <= '0';
                flags_wr_be <= (others => '0');
            else

                if (lsu_rd_s_tvalid = '1' and mexec_wait_fifo = '1'and  mem_dreg = FL) then
                    flags_wr_tvalid <= '1';
                elsif (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_FLG) = '1') then
                    flags_wr_tvalid <= '1';
                elsif ((alu_res_tvalid = '1' and alu_res_tdata.upd_fl = '1') or
                       mul_res_tvalid = '1' or bcd_res_tvalid = '1' or
                       shf8_res_tvalid = '1' or shf16_res_tvalid = '1' or
                       (div_res_tvalid = '1' and div_res_tdata.code = DIVU_AAM) or
                       (str_res_tvalid = '1' and (str_res_tdata.code = CMPS_OP or str_res_tdata.code = SCAS_OP))) then
                    flags_wr_tvalid <= '1';
                else
                    flags_wr_tvalid <= '0';
                end if;

                case flags_wr_selector is
                    when "000000001" =>
                        for i in 0 to 11 loop
                            if (micro_tdata.flg_no = std_logic_vector(to_unsigned(i, 4))) then
                                flags_wr_be(i) <= '1';
                            else
                                flags_wr_be(i) <= '0';
                            end if;
                        end loop;
                    when "000000010" =>
                        if (alu_res_tdata.dreg = FL) then

                            for i in 11 downto 8 loop
                                flags_wr_be(i) <= alu_res_tdata.dmask(1);
                            end loop;
                            flags_wr_be(FLAG_SF) <= alu_res_tdata.dmask(0);
                            flags_wr_be(FLAG_ZF) <= alu_res_tdata.dmask(0);
                            flags_wr_be(FLAG_05) <= '0';
                            flags_wr_be(FLAG_AF) <= alu_res_tdata.dmask(0);
                            flags_wr_be(FLAG_03) <= '0';
                            flags_wr_be(FLAG_PF) <= alu_res_tdata.dmask(0);
                            flags_wr_be(FLAG_01) <= '0';
                            flags_wr_be(FLAG_CF) <= alu_res_tdata.dmask(0);

                        else
                            case (alu_res_tdata.code) is
                                when ALU_OP_INC => flags_wr_be <= UPD_OF or UPD_SF or UPD_ZF or UPD_AF or UPD_PF;
                                when ALU_OP_DEC => flags_wr_be <= UPD_OF or UPD_SF or UPD_ZF or UPD_AF or UPD_PF;
                                when ALU_OP_AND => flags_wr_be <= UPD_OF or UPD_SF or UPD_ZF or UPD_PF or UPD_CF;
                                when ALU_OP_OR  => flags_wr_be <= UPD_OF or UPD_SF or UPD_ZF or UPD_PF or UPD_CF;
                                when ALU_OP_XOR => flags_wr_be <= UPD_OF or UPD_SF or UPD_ZF or UPD_PF or UPD_CF;
                                when ALU_OP_TST => flags_wr_be <= UPD_OF or UPD_SF or UPD_ZF or UPD_PF or UPD_CF;
                                when ALU_OP_NOT => flags_wr_be <= (others => '0');
                                when others     => flags_wr_be <= UPD_OF or UPD_SF or UPD_ZF or UPD_AF or UPD_PF or UPD_CF;
                            end case;
                        end if;
                    when "000000100" =>
                        if (div_res_tdata.code = DIVU_AAM) then
                            flags_wr_be <= UPD_SF or UPD_ZF or UPD_PF;
                        end if;
                    when "000001000" =>
                        case (bcd_res_tdata.code) is
                            when BCDU_AAA => flags_wr_be <= UPD_OF or UPD_AF or UPD_CF;
                            when BCDU_AAS => flags_wr_be <= UPD_OF or UPD_AF or UPD_CF;
                            when BCDU_AAD => flags_wr_be <= UPD_SF or UPD_ZF or UPD_PF;
                            when BCDU_DAA => flags_wr_be <= UPD_OF or UPD_SF or UPD_ZF or UPD_AF or UPD_PF or UPD_CF;
                            when BCDU_DAS => flags_wr_be <= UPD_OF or UPD_SF or UPD_ZF or UPD_AF or UPD_PF or UPD_CF;
                            when others   => flags_wr_be <= (others => '0');
                        end case;
                    when "000010000" =>
                        case (shf8_res_tdata.code) is
                            when SHF_OP_ROL => flags_wr_be <= UPD_OF or UPD_CF;
                            when SHF_OP_ROR => flags_wr_be <= UPD_OF or UPD_CF;
                            when SHF_OP_RCL => flags_wr_be <= UPD_OF or UPD_CF;
                            when SHF_OP_RCR => flags_wr_be <= UPD_OF or UPD_CF;
                            when SHF_OP_SHL => flags_wr_be <= UPD_OF or UPD_SF or UPD_ZF or UPD_PF or UPD_CF;
                            when SHF_OP_SAR => flags_wr_be <= UPD_OF or UPD_SF or UPD_ZF or UPD_PF or UPD_CF;
                            when SHF_OP_SHR => flags_wr_be <= UPD_OF or UPD_SF or UPD_ZF or UPD_PF or UPD_CF;
                            when others     => flags_wr_be <= (others => '0');
                        end case;
                    when "000100000" =>
                        case (shf16_res_tdata.code) is
                            when SHF_OP_ROL => flags_wr_be <= UPD_OF or UPD_CF;
                            when SHF_OP_ROR => flags_wr_be <= UPD_OF or UPD_CF;
                            when SHF_OP_RCL => flags_wr_be <= UPD_OF or UPD_CF;
                            when SHF_OP_RCR => flags_wr_be <= UPD_OF or UPD_CF;
                            when SHF_OP_SHL => flags_wr_be <= UPD_OF or UPD_SF or UPD_ZF or UPD_PF or UPD_CF;
                            when SHF_OP_SAR => flags_wr_be <= UPD_OF or UPD_SF or UPD_ZF or UPD_PF or UPD_CF;
                            when SHF_OP_SHR => flags_wr_be <= UPD_OF or UPD_SF or UPD_ZF or UPD_PF or UPD_CF;
                            when others     => flags_wr_be <= (others => '0');
                        end case;
                    when "001000000" =>
                        flags_wr_be <= UPD_OF or UPD_SF or UPD_PF or UPD_CF;
                    when "010000000" =>
                        case (str_res_tdata.code) is
                            when SCAS_OP => flags_wr_be <= UPD_OF or UPD_SF or UPD_ZF or UPD_AF or UPD_PF or UPD_CF;
                            when CMPS_OP => flags_wr_be <= UPD_OF or UPD_SF or UPD_ZF or UPD_AF or UPD_PF or UPD_CF;
                            when others  => flags_wr_be <= (others => '0');
                        end case;
                    when "100000000" =>
                        for i in 11 downto 8 loop
                            flags_wr_be(i) <= micro_tdata.mem_dmask(1);
                        end loop;
                        flags_wr_be(FLAG_SF) <= micro_tdata.mem_dmask(0);
                        flags_wr_be(FLAG_ZF) <= micro_tdata.mem_dmask(0);
                        flags_wr_be(FLAG_05) <= '0';
                        flags_wr_be(FLAG_AF) <= micro_tdata.mem_dmask(0);
                        flags_wr_be(FLAG_03) <= '0';
                        flags_wr_be(FLAG_PF) <= micro_tdata.mem_dmask(0);
                        flags_wr_be(FLAG_01) <= '0';
                        flags_wr_be(FLAG_CF) <= micro_tdata.mem_dmask(0);
                    when others =>
                        null;
                end case;

            end if;

            if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_FLG) = '1') then
                flags_src <= CMD_FLG;
            elsif (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_MRD) = '1' and micro_tdata.mem_dreg = FL) then
                flags_src <= RES_MEM;
            elsif (alu_res_tvalid = '1' and alu_res_tdata.upd_fl = '1') then
                if (alu_res_tdata.dreg = FL) then
                    flags_src <= RES_DATA;
                else
                    flags_src <= RES_USER;
                end if;
            elsif (mul_res_tvalid = '1' or str_res_tvalid = '1' or
                   bcd_res_tvalid = '1' or shf8_res_tvalid = '1' or
                   div_req_tvalid = '1' or shf16_res_tvalid = '1')
            then
                flags_src <= RES_USER;
            end if;

            if (micro_tvalid = '1' and micro_tready = '1') then
                case (micro_tdata.fl) is
                    when SET => flags_wr_new_val <= '1';
                    when CLR => flags_wr_new_val <= '0';
                    when others => null;
                end case;

                if (micro_tdata.fl = TOGGLE) then
                    flags_toggle_cf <= '1';
                else
                    flags_toggle_cf <= '0';
                end if;
            end if;

        end if;
    end process;

    flag_calc_proc : process (all) begin

        case flags_src is
            when RES_MEM =>
                flags_wr_vector(FLAG_OF)    <= mem_buf_0_tdata(FLAG_OF);
                flags_wr_vector(8 downto 1) <= mem_buf_0_tdata(8 downto 1);
            when RES_DATA =>
                flags_wr_vector(FLAG_OF)    <= res_tdata.dval_lo(FLAG_OF);
                flags_wr_vector(8 downto 1) <= res_tdata.dval_lo(8 downto 1);
            when others =>
                flags_wr_vector(FLAG_OF)    <= res_tuser(FLAG_OF);
                flags_wr_vector(8 downto 1) <= res_tuser(8 downto 1);
        end case;

        case flags_src is
            when RES_MEM =>
                flags_wr_vector(FLAG_CF) <= mem_buf_0_tdata(FLAG_CF);
                flags_wr_vector(FLAG_DF) <= mem_buf_0_tdata(FLAG_DF);
                flags_wr_vector(FLAG_IF) <= mem_buf_0_tdata(FLAG_IF);
                flags_wr_vector(FLAG_AF) <= mem_buf_0_tdata(FLAG_AF);
                flags_wr_vector(FLAG_SF) <= mem_buf_0_tdata(FLAG_SF);
            when RES_DATA =>
                flags_wr_vector(FLAG_CF) <= res_tdata.dval_lo(FLAG_CF);
                flags_wr_vector(FLAG_DF) <= res_tdata.dval_lo(FLAG_DF);
                flags_wr_vector(FLAG_IF) <= res_tdata.dval_lo(FLAG_IF);
                flags_wr_vector(FLAG_AF) <= res_tdata.dval_lo(FLAG_AF);
                flags_wr_vector(FLAG_SF) <= res_tdata.dval_lo(FLAG_SF);
            when RES_USER =>
                flags_wr_vector(FLAG_CF) <= res_tuser(FLAG_CF);
                flags_wr_vector(FLAG_DF) <= res_tuser(FLAG_DF);
                flags_wr_vector(FLAG_IF) <= res_tuser(FLAG_IF);
                flags_wr_vector(FLAG_AF) <= res_tuser(FLAG_AF);
                flags_wr_vector(FLAG_SF) <= res_tuser(FLAG_SF);
            when others =>
                if (flags_toggle_cf = '1') then
                    flags_wr_vector(FLAG_CF) <= not flags_tdata(FLAG_CF);
                else
                    flags_wr_vector(FLAG_CF) <= flags_wr_new_val;
                end if;
                flags_wr_vector(FLAG_DF) <= flags_wr_new_val;
                flags_wr_vector(FLAG_IF) <= flags_wr_new_val;
        end case;

    end process;

    mem_buf_proc : process (clk) begin
        if rising_edge(clk) then
            if (lsu_rd_s_tvalid = '1' and mexec_wait_fifo = '1') then
                mem_buf_0_tdata <= lsu_rd_s_tdata;
                mem_buf_1_tdata <= mem_buf_0_tdata;
            end if;
        end if;
    end process;

    unlock_proc : process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                mexec_unlk_fl <= '0';
                jmp_lock_m_wr_tvalid <= '0';
            else

                if (micro_tvalid = '1' and micro_tready = '1') then
                    mexec_unlk_fl <= micro_tdata.cmd(MICRO_OP_CMD_UNLK);
                end if;

                if (micro_tvalid = '1' and micro_tready = '1') then
                    if micro_tdata.cmd(MICRO_OP_CMD_MRD) = '1' or micro_tdata.cmd(MICRO_OP_CMD_DIV) = '1' or
                        micro_tdata.cmd(MICRO_OP_CMD_MUL) = '1' or micro_tdata.cmd(MICRO_OP_CMD_BCD) = '1' or
                        micro_tdata.cmd(MICRO_OP_CMD_SHF) = '1' or micro_tdata.cmd(MICRO_OP_CMD_JMP) = '1' or
                        micro_tdata.cmd(MICRO_OP_CMD_STR) = '1'
                    then
                       jmp_lock_m_wr_tvalid <= '0';
                    else
                        if (micro_tdata.cmd(MICRO_OP_CMD_UNLK) = '1') then
                            jmp_lock_m_wr_tvalid <= '1';
                        else
                            jmp_lock_m_wr_tvalid <= '0';
                        end if;
                    end if;
                elsif (mexec_busy = '1') then
                    if not (mexec_wait_fifo = '1' xor (lsu_rd_s_tvalid = '1' and mexec_wait_fifo = '1')) and
                        not (mexec_wait_div = '1' xor div_res_tvalid = '1') and
                        not (mexec_wait_mul = '1' xor mul_res_tvalid = '1') and
                        not (mexec_wait_bcd = '1' xor bcd_res_tvalid = '1') and
                        not (mexec_wait_shf = '1' xor (shf8_res_tvalid = '1' or shf16_res_tvalid = '1')) and
                        not (mexec_wait_str = '1' xor (str_res_tvalid = '1')) and
                        not (mexec_wait_jmp = '1' xor jmp_tvalid = '1')
                    then
                        if (mexec_unlk_fl = '1') then
                            jmp_lock_m_wr_tvalid <= '1';
                        else
                            jmp_lock_m_wr_tvalid <= '0';
                        end if;
                    end if;
                else
                    jmp_lock_m_wr_tvalid <= '0';
                end if;

            end if;

        end if;
    end process;

    jump_control_proc: process (clk)
        procedure jump_if (expr : boolean) is begin
            if (expr) then
                jmp_take <= '1';
            else
                jmp_take <= '0';
            end if;
        end procedure;
    begin
        if rising_edge(clk) then
            if resetn = '0' then
                jmp_cond        <= j_never;
                jmp_wait_mem_cs <= '0';
                jmp_wait_mem_ip <= '0';
                jmp_bpu_first   <= '0';
                jmp_bpu_taken   <= '0';
                jmp_tvalid      <= '0';
                jmp_take        <= '0';
                jmp_wait_alu    <= '0';
                jmp_busy        <= '0';
            else
                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_JMP) = '1') then
                    jmp_cond <= micro_tdata.jump_cond;
                end if;

                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_JMP) = '1') then
                    jmp_bpu_first <= micro_tdata.bpu_first;
                    jmp_bpu_taken <= micro_tdata.bpu_taken;
                end if;

                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_JMP) = '1') then
                    if (micro_tdata.jump_cond = cx_ne_0 or micro_tdata.jump_cond = cx_ne_0_and_zf or
                        micro_tdata.jump_cond = cx_ne_0_and_nzf)
                    then
                        jmp_wait_alu <= '1';
                    else
                        jmp_wait_alu <= '0';
                    end if;
                elsif (jmp_wait_alu = '1' and alu_res_tvalid = '1') then
                    jmp_wait_alu <= '0';
                end if;

                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_JMP) = '1' and micro_tdata.jump_cs_mem = '1') then
                    jmp_wait_mem_cs <= '1';
                elsif (jmp_wait_mem_cs = '1' and lsu_rd_s_tvalid = '1') then
                    jmp_wait_mem_cs <= '0';
                end if;

                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_JMP) = '1' and micro_tdata.jump_ip_mem = '1') then
                    jmp_wait_mem_ip <= '1';
                elsif (jmp_wait_mem_ip = '1' and lsu_rd_s_tvalid = '1') then
                    jmp_wait_mem_ip <= '0';
                end if;

                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_JMP) = '1' and
                    ((micro_tdata.jump_cond = j_always and (micro_tdata.jump_cs_mem = '1' or micro_tdata.jump_ip_mem = '1')) or
                     (micro_tdata.jump_cond = cx_ne_0 or micro_tdata.jump_cond = cx_ne_0_and_zf or micro_tdata.jump_cond = cx_ne_0_and_nzf) or
                     (op_cnt /= 0 or op_inc_hs = '1')))
                then
                    jmp_busy <= '1';
                elsif (jmp_busy = '1') then
                    if (not ((jmp_wait_mem_cs = '1' or jmp_wait_mem_ip = '1') xor lsu_rd_s_tvalid = '1') and
                        not (jmp_wait_alu = '1' xor alu_res_tvalid = '1') and (op_cnt = 0))
                    then
                        jmp_busy <= '0';
                    end if;
                end if;

                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_JMP) = '1' and op_cnt = 0 and op_inc_hs = '0') then
                    case micro_tdata.jump_cond is
                        when j_always =>
                            if (micro_tdata.jump_cs_mem = '0' and micro_tdata.jump_ip_mem = '0') then
                                jmp_tvalid <= '1';
                            else
                                jmp_tvalid <= '0';
                            end if;

                        when j_ja | j_jae | j_jb | j_jbe | j_je | j_jne | j_jg | j_jge |
                             j_jl | j_jle | j_jno | j_jo | j_jnp | j_jp | j_jns | j_js =>
                            jmp_tvalid <= '1';

                        when cx_eq_0 =>
                            jmp_tvalid <= '1';

                        when others =>
                            jmp_tvalid <= '0';
                    end case;

                elsif (jmp_busy = '1') then
                    if (not ((jmp_wait_mem_cs = '1' or jmp_wait_mem_ip = '1') xor lsu_rd_s_tvalid = '1') and
                        not (jmp_wait_alu = '1' xor alu_res_tvalid = '1') and (op_cnt = 0))
                    then
                        jmp_tvalid <= '1';
                    else
                        jmp_tvalid <= '0';
                    end if;
                else
                    jmp_tvalid <= '0';
                end if;

                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_JMP) = '1') then
                    case micro_tdata.jump_cond is
                        when j_always   => jmp_take <= '1';
                        when j_ja       => jump_if(flags_tdata(FLAG_ZF) = '0' and flags_tdata(FLAG_CF) = '0');
                        when j_jae      => jump_if(flags_tdata(FLAG_CF) = '0');
                        when j_jb       => jump_if(flags_tdata(FLAG_CF) = '1');
                        when j_jbe      => jump_if(flags_tdata(FLAG_ZF) = '1' or flags_tdata(FLAG_CF) = '1');
                        when j_je       => jump_if(flags_tdata(FLAG_ZF) = '1');
                        when j_jne      => jump_if(flags_tdata(FLAG_ZF) = '0');
                        when j_jg       => jump_if(flags_tdata(FLAG_ZF) = '0' and flags_tdata(FLAG_SF) = flags_tdata(FLAG_OF));
                        when j_jge      => jump_if(flags_tdata(FLAG_SF) = flags_tdata(FLAG_OF));
                        when j_jl       => jump_if(flags_tdata(FLAG_SF) /= flags_tdata(FLAG_OF));
                        when j_jle      => jump_if(flags_tdata(FLAG_ZF) = '1' or flags_tdata(FLAG_SF) /= flags_tdata(FLAG_OF));
                        when j_jno      => jump_if(flags_tdata(FLAG_OF) = '0');
                        when j_jo       => jump_if(flags_tdata(FLAG_OF) = '1');
                        when j_jnp      => jump_if(flags_tdata(FLAG_PF) = '0');
                        when j_jp       => jump_if(flags_tdata(FLAG_PF) = '1');
                        when j_jns      => jump_if(flags_tdata(FLAG_SF) = '0');
                        when j_js       => jump_if(flags_tdata(FLAG_SF) = '1');
                        when cx_eq_0    => jump_if(micro_tdata.jump_cx = x"0000");
                        when others     => jmp_take <= '0';
                    end case;

                elsif (jmp_busy = '1') then
                    if ((jmp_wait_mem_cs = '1' or jmp_wait_mem_ip = '1') and lsu_rd_s_tvalid = '1') then
                        if (jmp_cond = j_always) then
                            jmp_take <= '1';
                        else
                            jmp_take <= '0';
                        end if;
                    elsif (jmp_wait_alu = '1' and alu_res_tvalid = '1') then
                        case jmp_cond is
                            when j_always        => jmp_take <= '1';
                            when cx_ne_0         => jump_if(alu_res_tdata.dval(15 downto 0) /= x"0000");
                            when cx_ne_0_and_zf  => jump_if(alu_res_tdata.dval(15 downto 0) /= x"0000" and flags_tdata(FLAG_ZF) = '1');
                            when cx_ne_0_and_nzf => jump_if(alu_res_tdata.dval(15 downto 0) /= x"0000" and flags_tdata(FLAG_ZF) = '0');
                            when others          => jmp_take <= '0';
                        end case;
                    end if;
                end if;

            end if;

            if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.jump_imm = '1') then
                jmp_jump_cs <= micro_tdata.jump_cs;
            elsif (jmp_wait_mem_cs = '1' and lsu_rd_s_tvalid = '1') then
                jmp_jump_cs <= lsu_rd_s_tdata;
            end if;

            if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.jump_imm = '1') then
                jmp_jump_ip <= micro_tdata.jump_ip;
            elsif (jmp_wait_mem_ip = '1' and lsu_rd_s_tvalid = '1') then
                jmp_jump_ip <= lsu_rd_s_tdata;
            end if;

            if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_JMP) = '1') then
                jmp_bpu_taken_cs <= micro_tdata.bpu_taken_cs;
                jmp_bpu_taken_ip <= micro_tdata.bpu_taken_ip;
            end if;

        end if;
    end process;

    jump_dout_forming_proc : process (clk) begin
        if rising_edge(clk) then
            -- resettable
            if resetn = '0' then
                jmp_dout_tvalid <= '0';
                jmp_dout_tdata.first <= '0';
                jmp_dout_tdata.mismatch <= '0';
                jmp_dout_tdata.taken <= '0';
                jmp_dout_tdata.bypass <= '1';
                event_jump <= '0';
            else
                jmp_dout_tvalid <= jmp_tvalid;

                if (jmp_tvalid = '1') then
                    jmp_dout_tdata.first <= jmp_bpu_first;
                    jmp_dout_tdata.taken <= jmp_take;
                end if;

                if (jmp_tvalid = '1') then
                    if (jmp_bpu_taken /= jmp_take) or
                       (jmp_bpu_taken = '1' and jmp_take = '1' and (jmp_jump_cs /= jmp_bpu_taken_cs or jmp_jump_ip /= jmp_bpu_taken_ip))
                    then
                        jmp_dout_tdata.mismatch <= '1';
                    else
                        jmp_dout_tdata.mismatch <= '0';
                    end if;
                end if;

                if (jmp_tvalid = '1') then
                    if (jmp_bpu_taken /= jmp_take) or
                       (jmp_bpu_taken = '1' and jmp_take = '1' and (jmp_jump_cs /= jmp_bpu_taken_cs or jmp_jump_ip /= jmp_bpu_taken_ip))
                    then
                        event_jump <= '1';
                    else
                        event_jump <= '0';
                    end if;
                end if;
            end if;

            -- without reset
            if (jmp_tvalid = '1') then
                if jmp_bpu_taken = '1' and jmp_take = '0' then
                    jmp_dout_tdata.jump_cs <= micro_tdata.inst_cs;
                    jmp_dout_tdata.jump_ip <= micro_tdata.inst_ip_next;
                else
                    jmp_dout_tdata.jump_cs <= jmp_jump_cs;
                    jmp_dout_tdata.jump_ip <= jmp_jump_ip;
                end if;
            end if;

            if (micro_tvalid = '1' and micro_tready = '1') then
                jmp_dout_tdata.bypass  <= micro_tdata.bpu_bypass;
                jmp_dout_tdata.is_ret  <= micro_tdata.jump_is_ret;
                jmp_dout_tdata.inst_cs <= micro_tdata.inst_cs;
                jmp_dout_tdata.inst_ip <= micro_tdata.inst_ip;
            end if;

        end if;
    end process;

    lsu_req_a_selector(0) <= '1' when micro_tvalid = '1' and micro_tready = '1' else '0';
    lsu_req_a_selector(1) <= '1' when str_lsu_req_tvalid = '1' and str_lsu_req_tready = '1' else '0';

    lsu_request_forming_proc: process (clk) begin
        if rising_edge(clk) then
            -- control
            if resetn = '0' then
                lsu_req_tvalid <= '0';
                mem_wait_alu <= '0';
                mem_wait_fifo <= '0';
                mem_wait_shf <= '0';
            else

                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_MEM) = '1') then
                    if (micro_tdata.mem_cmd = '1' and micro_tdata.mem_data_src = MEM_DATA_SRC_ALU) then
                        mem_wait_alu <= '1';
                    else
                        mem_wait_alu <= '0';
                    end if;
                elsif (mem_wait_alu = '1' and alu_res_tvalid = '1') then
                    mem_wait_alu <= '0';
                end if;

                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_MEM) = '1') then
                    if (micro_tdata.mem_cmd = '1' and micro_tdata.mem_data_src = MEM_DATA_SRC_SHF) then
                        mem_wait_shf <= '1';
                    else
                        mem_wait_shf <= '0';
                    end if;
                elsif (mem_wait_shf = '1' and (shf16_res_tvalid = '1' or shf8_res_tvalid = '1')) then
                    mem_wait_shf <= '0';
                end if;

                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_MEM) = '1') then
                    if (micro_tdata.mem_cmd = '1' and micro_tdata.mem_data_src = MEM_DATA_SRC_FIFO) then
                        mem_wait_fifo <= '1';
                    else
                        mem_wait_fifo <= '0';
                    end if;
                elsif (mem_wait_fifo = '1' and lsu_rd_s_tvalid = '1') then
                    mem_wait_fifo <= '0';
                end if;

                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_MEM) = '1') then
                    if (micro_tdata.mem_cmd = '1' and
                        (micro_tdata.mem_data_src = MEM_DATA_SRC_ALU or
                         micro_tdata.mem_data_src = MEM_DATA_SRC_ONE or
                         micro_tdata.mem_data_src = MEM_DATA_SRC_SHF or
                         micro_tdata.mem_data_src = MEM_DATA_SRC_IO or
                         micro_tdata.mem_data_src = MEM_DATA_SRC_FIFO))
                    then
                        lsu_req_tvalid <= '0';
                    else
                        lsu_req_tvalid <= '1';
                    end if;
                elsif (str_lsu_req_tvalid = '1' and str_lsu_req_tready = '1') then
                    lsu_req_tvalid <= '1';
                elsif (mem_wait_alu = '1' or mem_wait_fifo = '1' or mem_wait_shf = '1') and
                    not (alu_res_tvalid = '1' xor mem_wait_alu = '1') and
                    not (lsu_rd_s_tvalid = '1' xor mem_wait_fifo = '1') and
                    not ((shf8_res_tvalid = '1' or shf16_res_tvalid = '1') xor mem_wait_shf = '1') then
                    lsu_req_tvalid <= '1';
                elsif (lsu_req_tready = '1') then
                    lsu_req_tvalid <= '0';
                end if;

            end if;
            -- data path
            case lsu_req_a_selector is
                when "01" =>
                    lsu_req_tcmd <= micro_tdata.mem_cmd;
                    lsu_req_twidth <= micro_tdata.mem_width;
                    lsu_req_taddr <= std_logic_vector(unsigned(micro_tdata.mem_seg & x"0") + unsigned(x"0" & micro_tdata.mem_addr));
                when "10" =>
                    lsu_req_tcmd <= str_lsu_req_tcmd;
                    lsu_req_twidth <= str_lsu_req_twidth;
                    lsu_req_taddr <= str_lsu_req_taddr;
                when others => null;
            end case;

            if (micro_tvalid = '1' and micro_tready = '1') then
                lsu_req_tdata <= micro_tdata.mem_data;
            elsif (str_lsu_req_tvalid = '1' and str_lsu_req_tready = '1') then
                lsu_req_tdata <= str_lsu_req_tdata;
            elsif (mem_wait_alu = '1' and alu_res_tvalid = '1') then
                lsu_req_tdata <= alu_res_tdata.dval(15 downto 0);
            elsif (mem_wait_shf = '1' and shf8_res_tvalid = '1') then
                lsu_req_tdata <= shf8_res_tdata.dval;
            elsif (mem_wait_shf = '1' and shf16_res_tvalid = '1') then
                lsu_req_tdata <= shf16_res_tdata.dval;
            elsif (mem_wait_fifo = '1' and lsu_rd_s_tvalid = '1') then
                lsu_req_tdata <= lsu_rd_s_tdata;
            end if;

            if (micro_tvalid = '1' and micro_tready = '1') then
                mem_dreg  <= micro_tdata.mem_dreg;
                mem_dmask <= micro_tdata.mem_dmask;
            end if;

        end if;
    end process;

    bound_check_process : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                bnd_intr_tvalid <= '0';
            else
                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_BND) = '1') then
                    if (signed(micro_tdata.bnd_val) < signed(mem_buf_1_tdata) or signed(micro_tdata.bnd_val) > signed(mem_buf_0_tdata + 2)) then
                        bnd_intr_tvalid <= '1';
                    else
                        bnd_intr_tvalid <= '0';
                    end if;
                else
                    bnd_intr_tvalid <= '0';
                end if;
            end if;
        end if;
    end process;

    trap_check_process : process (clk) begin
        if rising_edge(clk) then
            -- control
            if resetn = '0' then
                trap_check_tf_tvalid <= '0';
                trap_intr_tvalid     <= '0';
                trap_intr_tvalid_mask <= '0';
            else
                if (micro_tvalid = '1' and micro_tready = '1' and micro_tlast = '1' and micro_tdata.trap = '1') then
                    trap_check_tf_tvalid <= '1';
                elsif (trap_check_tf_tvalid = '1' and op_inc_hs = '0' and op_cnt = 0 and mexec_busy = '0') then
                    trap_check_tf_tvalid <= '0';
                end if;

                if (trap_check_tf_tvalid = '1' and op_inc_hs = '0' and op_cnt = 0 and mexec_busy = '0') then
                    trap_intr_tvalid <= '1';
                else
                    trap_intr_tvalid <= '0';
                end if;

                if (div_intr_tvalid = '1') or (bnd_intr_tvalid = '1') then
                    trap_intr_tvalid_mask <= '1';
                end if;
            end if;
        end if;
    end process;

    div_exception_proc : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                div_intr_tvalid <= '0';
            else
                if (div_res_tvalid = '1' and div_res_tdata.overflow = '1') then
                    div_intr_tvalid <= '1';
                else
                    div_intr_tvalid <= '0';
                end if;
            end if;
        end if;
    end process;

    intr_tdata_process : process (clk) begin
        if rising_edge(clk) then
            -- data
            if (micro_tvalid = '1' and micro_tready = '1') then
                dout_intr_tdata(INTR_T_SS)      <= micro_tdata.inst_ss;
                dout_intr_tdata(INTR_T_CS)      <= micro_tdata.inst_cs;
                dout_intr_tdata(INTR_T_IP)      <= micro_tdata.inst_ip;
                dout_intr_tdata(INTR_T_IP_NEXT) <= micro_tdata.inst_ip_next;
            end if;

        end if;
    end process;

    process (all) begin
        if (bnd_intr_tvalid = '1') then
            dout_intr_tuser <= x"05";
        elsif (div_intr_tvalid = '1') then
            dout_intr_tuser <= x"00";
        else
            dout_intr_tuser <= x"01";
        end if;
    end process;

end architecture;
