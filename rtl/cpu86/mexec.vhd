library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.cpu86_types.all;

entity mexec is
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

        sp_m_inc_tvalid         : out std_logic;
        sp_m_inc_tdata          : out std_logic_vector(15 downto 0);
        sp_m_inc_tkeep_lock     : out std_logic;

        bp_m_inc_tvalid         : out std_logic;

        flags_m_wr_tvalid       : out std_logic;
        flags_m_wr_tdata        : out std_logic_vector(15 downto 0);

        jump_m_tvalid           : out std_logic;
        jump_m_tdata            : out std_logic_vector(31 downto 0);

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

        dbg_m_tvalid            : out std_logic;
        dbg_m_tdata             : out std_logic_vector(31 downto 0);

        div_intr_m_tvalid       : out std_logic;
        div_intr_m_tdata        : out div_intr_t;

        bnd_intr_m_tvalid       : out std_logic;
        bnd_intr_m_tdata        : out div_intr_t
    );
end entity mexec;

architecture rtl of mexec is

    type flag_src_t is (RES_USER, RES_DATA, CMD_FLG);

    type res_t is record
        code                    : std_logic_vector(3 downto 0);
        dmask                   : std_logic_vector(1 downto 0);
        dval_hi                 : std_logic_vector(15 downto 0);
        dval_lo                 : std_logic_vector(15 downto 0); --dest
    end record;

    component mexec_alu is
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
    end component mexec_alu;

    component mexec_mul is
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            req_s_tvalid        : in std_logic;
            req_s_tdata         : in mul_req_t;

            res_m_tvalid        : out std_logic;
            res_m_tdata         : out mul_res_t;
            res_m_tuser         : out std_logic_vector(15 downto 0)
        );
    end component mexec_mul;

    component mexec_div is
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            req_s_tvalid        : in std_logic;
            req_s_tdata         : in div_req_t;

            res_m_tvalid        : out std_logic;
            res_m_tdata         : out div_res_t;
            res_m_tuser         : out std_logic_vector(15 downto 0)
        );
    end component mexec_div;

    component mexec_one is
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            req_s_tvalid        : in std_logic;
            req_s_tdata         : in one_req_t;

            res_m_tvalid        : out std_logic;
            res_m_tdata         : out one_res_t;
            res_m_tuser         : out std_logic_vector(15 downto 0)
        );
    end component mexec_one;

    component mexec_bcd is
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
    end component mexec_bcd;

    component mexec_shf is
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
    end component mexec_shf;

    component mexec_str is
        port (
            clk                     : in std_logic;
            resetn                  : in std_logic;

            req_s_tvalid            : in std_logic;
            req_s_tdata             : in str_req_t;

            res_m_tvalid            : out std_logic;
            res_m_tdata             : out str_res_t;
            res_m_tuser             : out std_logic_vector(15 downto 0);

            lsu_req_m_tvalid        : out std_logic;
            lsu_req_m_tready        : in std_logic;
            lsu_req_m_tcmd          : out std_logic;
            lsu_req_m_twidth        : out std_logic;
            lsu_req_m_taddr         : out std_logic_vector(19 downto 0);
            lsu_req_m_tdata         : out std_logic_vector(15 downto 0);

            lsu_rd_s_tvalid         : in std_logic;
            lsu_rd_s_tready         : out std_logic;
            lsu_rd_s_tdata          : in std_logic_vector(15 downto 0);

            io_req_m_tvalid         : out std_logic;
            io_req_m_tready         : in std_logic;
            io_req_m_tdata          : out std_logic_vector(39 downto 0);

            io_rd_s_tvalid          : in std_logic;
            io_rd_s_tready          : out std_logic;
            io_rd_s_tdata           : in std_logic_vector(15 downto 0);

            event_interrupt         : in std_logic
        );
    end component;

    signal micro_tvalid         : std_logic;
    signal micro_tready         : std_logic;
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
        dmask       => "00",
        aval        => (others => '0'),
        bval        => (others => '0')
    );
    signal mul_res_tvalid       : std_logic;
    signal mul_res_tdata        : mul_res_t;
    signal mul_res_tuser        : std_logic_vector(15 downto 0);

    signal div_req_tvalid       : std_logic;
    signal div_req_tdata        : div_req_t := (
        code        => (others => '0'),
        w           => '0',
        wb          => '0',
        dreg        => AX,
        nval        => (others => '0'),
        dval        => (others => '0'),
        ss_val      => (others => '0'),
        cs_val      => (others => '0'),
        ip_val      => (others => '0'),
        ip_next_val => (others => '0')
    );
    signal div_res_tvalid       : std_logic;
    signal div_res_tdata        : div_res_t;
    signal div_res_tuser        : std_logic_vector(15 downto 0);

    signal one_req_tvalid       : std_logic;
    signal one_req_tdata        : one_req_t := (
        code        => (others => '0'),
        w           => '0',
        wb          => '0',
        dreg        => AX,
        dmask       => "00",
        sval        => (others => '0'),
        ival        => (others => '0')
    );
    signal one_res_tvalid       : std_logic;
    signal one_res_tdata        : one_res_t;
    signal one_res_tuser        : std_logic_vector(15 downto 0);

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

    signal flags_wr_be          : std_logic_vector(15 downto 0);
    signal flags_wr_new_val     : std_logic;
    signal flags_toggle_cf      : std_logic;
    signal flags_src            : flag_src_t;
    signal flags_wr_vector      : std_logic_vector(15 downto 0);

    signal mem_buf_tdata        : std_logic_vector(15 downto 0);
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
    signal bnd_wait_fifo        : std_logic;
    signal bnd_val              : std_logic_vector(15 downto 0);

    signal mem_wait_one         : std_logic;
    signal mem_wait_alu         : std_logic;
    signal mem_wait_shf         : std_logic;
    signal mem_wait_fifo        : std_logic;

    signal jmp_busy             : std_logic;
    signal jmp_wait_alu         : std_logic;
    signal jmp_wait_mem_cs      : std_logic;
    signal jmp_wait_mem_ip      : std_logic;
    signal jmp_cond             : micro_op_jmp_cond_t;

    signal jmp_tvalid           : std_logic;
    signal jmp_tdata            : std_logic;

    signal dbg_0_tvalid         : std_logic;
    signal dbg_1_tvalid         : std_logic;

    signal res_tdata_selector   : std_logic_vector(7 downto 0);
    signal flags_wr_selector    : std_logic_vector(8 downto 0);

    signal io_cmd_w             : std_logic;
    signal io_cmd_wb            : std_logic;

begin

    mexec_alu_inst : mexec_alu port map (
        clk                     => clk,
        resetn                  => resetn,

        req_s_tvalid            => alu_req_tvalid,
        req_s_tdata             => alu_req_tdata,
        req_s_tuser             => flags_s_tdata(FLAG_CF),

        res_m_tvalid            => alu_res_tvalid,
        res_m_tdata             => alu_res_tdata,
        res_m_tuser             => alu_res_tuser
    );

    mexec_mul_inst : mexec_mul port map (
        clk                     => clk,
        resetn                  => resetn,

        req_s_tvalid            => mul_req_tvalid,
        req_s_tdata             => mul_req_tdata,

        res_m_tvalid            => mul_res_tvalid,
        res_m_tdata             => mul_res_tdata,
        res_m_tuser             => mul_res_tuser
    );

    mexec_div_inst : mexec_div port map (
        clk                     => clk,
        resetn                  => resetn,

        req_s_tvalid            => div_req_tvalid,
        req_s_tdata             => div_req_tdata,

        res_m_tvalid            => div_res_tvalid,
        res_m_tdata             => div_res_tdata,
        res_m_tuser             => div_res_tuser
    );

    mexec_one_inst : mexec_one port map (
        clk                     => clk,
        resetn                  => resetn,

        req_s_tvalid            => one_req_tvalid,
        req_s_tdata             => one_req_tdata,

        res_m_tvalid            => one_res_tvalid,
        res_m_tdata             => one_res_tdata,
        res_m_tuser             => one_res_tuser
    );

    mexec_bcd_inst : mexec_bcd port map (
        clk                     => clk,
        resetn                  => resetn,

        req_s_tvalid            => bcd_req_tvalid,
        req_s_tdata             => bcd_req_tdata,
        req_s_tuser             => flags_s_tdata,

        res_m_tvalid            => bcd_res_tvalid,
        res_m_tdata             => bcd_res_tdata,
        res_m_tuser             => bcd_res_tuser
    );

    mexec_shf8_inst : mexec_shf generic map (
        DATA_WIDTH              => 8
    ) port map (
        clk                     => clk,
        resetn                  => resetn,

        req_s_tvalid            => shf8_req_tvalid,
        req_s_tdata             => shf8_req_tdata,
        req_s_tuser             => flags_s_tdata,

        res_m_tvalid            => shf8_res_tvalid,
        res_m_tdata             => shf8_res_tdata,
        res_m_tuser             => shf8_res_tuser
    );

    mexec_shf16_inst : mexec_shf generic map (
        DATA_WIDTH              => 16
    ) port map (
        clk                     => clk,
        resetn                  => resetn,

        req_s_tvalid            => shf16_req_tvalid,
        req_s_tdata             => shf16_req_tdata,
        req_s_tuser             => flags_s_tdata,

        res_m_tvalid            => shf16_res_tvalid,
        res_m_tdata             => shf16_res_tdata,
        res_m_tuser             => shf16_res_tuser
    );

    mexec_str_inst : mexec_str port map (
        clk                     => CLK,
        resetn                  => RESETN,

        req_s_tvalid            => str_req_tvalid,
        req_s_tdata             => str_req_tdata,

        res_m_tvalid            => str_res_tvalid,
        res_m_tdata             => str_res_tdata,
        res_m_tuser             => str_res_tuser,

        lsu_req_m_tvalid        => str_lsu_req_tvalid,
        lsu_req_m_tready        => str_lsu_req_tready,
        lsu_req_m_tcmd          => str_lsu_req_tcmd,
        lsu_req_m_twidth        => str_lsu_req_twidth,
        lsu_req_m_taddr         => str_lsu_req_taddr,
        lsu_req_m_tdata         => str_lsu_req_tdata,

        lsu_rd_s_tvalid         => str_lsu_rd_tvalid,
        lsu_rd_s_tready         => str_lsu_rd_tready,
        lsu_rd_s_tdata          => str_lsu_rd_tdata,

        io_req_m_tvalid         => io_req_m_tvalid,
        io_req_m_tready         => io_req_m_tready,
        io_req_m_tdata          => io_req_m_tdata,

        io_rd_s_tvalid          => io_rd_s_tvalid,
        io_rd_s_tready          => io_rd_s_tready,
        io_rd_s_tdata           => io_rd_s_tdata,

        event_interrupt         => '0'
    );

    micro_tvalid <= micro_s_tvalid;
    micro_s_tready <= micro_tready;
    micro_tdata <= micro_s_tdata;

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
        mem_wait_one = '0' and
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

    flags_m_wr_tdata <= ((not flags_wr_be) and flags_s_tdata) or (flags_wr_be and flags_wr_vector);

    -- sp increment
    sp_m_inc_tvalid <= '1' when micro_tvalid = '1' and micro_tready = '1' and micro_tdata.sp_inc = '1' else '0';
    sp_m_inc_tdata <= micro_tdata.sp_inc_data;
    sp_m_inc_tkeep_lock <= micro_tdata.sp_keep_lock;

    -- bp increment
    bp_m_inc_tvalid <= '1' when micro_tvalid = '1' and micro_tready = '1' and micro_tdata.bp_inc = '1' else '0';

    div_intr_m_tvalid <= '1' when div_res_tvalid = '1' and div_res_tdata.overflow = '1' else '0';
    div_intr_m_tdata(DIV_INTR_T_SS) <= div_res_tdata.ss_val;
    div_intr_m_tdata(DIV_INTR_T_IP) <= div_res_tdata.ip_val;
    div_intr_m_tdata(DIV_INTR_T_CS) <= div_res_tdata.cs_val;
    div_intr_m_tdata(DIV_INTR_T_IP_NEXT) <= div_res_tdata.ip_next_val;

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

                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_MRD) = '1') or
                    (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_DIV) = '1') or
                    (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_MUL) = '1') or
                    (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_BCD) = '1') or
                    (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_SHF) = '1') or
                    (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_JMP) = '1') or
                    (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_STR) = '1')
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
                    mexec_wait_jmp <= '1';
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
                mul_req_tdata.dmask <= micro_tdata.mul_dmask;
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
                div_req_tdata.w <= micro_tdata.div_w;
                div_req_tdata.nval <= micro_tdata.div_a_val;
                div_req_tdata.dval <= micro_tdata.div_b_val;
                div_req_tdata.dreg <= micro_tdata.div_dreg;
                div_req_tdata.ss_val <= micro_tdata.div_ss_val;
                div_req_tdata.cs_val <= micro_tdata.div_cs_val;
                div_req_tdata.ip_val <= micro_tdata.div_ip_val;
                div_req_tdata.ip_next_val <= micro_tdata.div_ip_next_val;
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

    one_proc : process (clk) begin

        if rising_edge(clk) then

            if resetn = '0' then
                one_req_tvalid <= '0';
                one_wait_fifo <= '0';
            else

                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_ONE) = '1' and micro_tdata.cmd(MICRO_OP_CMD_MRD) = '0') then
                    one_req_tvalid <= '1';
                elsif (one_wait_fifo = '1' and lsu_rd_s_tvalid = '1') then
                    one_req_tvalid <= '1';
                else
                    one_req_tvalid <= '0';
                end if;

                if (micro_tvalid = '1' and micro_tready = '1') then
                    if (micro_tdata.cmd(MICRO_OP_CMD_ONE) = '1' AND micro_tdata.cmd(MICRO_OP_CMD_MRD) = '1') then
                        one_wait_fifo <= '1';
                    else
                        one_wait_fifo <= '0';
                    end if;
                elsif (one_wait_fifo = '1' and lsu_rd_s_tvalid = '1') then
                    one_wait_fifo <= '0';
                end if;

            end if;

            if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_ONE) = '1') then
                one_req_tdata.code <= micro_tdata.one_code;
                one_req_tdata.w <= micro_tdata.one_w;
                one_req_tdata.wb <= micro_tdata.one_wb;
                one_req_tdata.sval <= micro_tdata.one_sval;
                one_req_tdata.ival <= micro_tdata.one_ival;
                one_req_tdata.dreg <= micro_tdata.one_dreg;
                one_req_tdata.dmask <= micro_tdata.one_dmask;
            elsif (one_wait_fifo = '1' and lsu_rd_s_tvalid = '1') then
                one_req_tdata.sval <= lsu_rd_s_tdata;
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
                shf8_req_tdata.code <= micro_tdata.shf_code;
                shf8_req_tdata.w <= micro_tdata.shf_w;
                shf8_req_tdata.wb <= micro_tdata.shf_wb;
                shf8_req_tdata.sval <= micro_tdata.shf_sval;
                shf8_req_tdata.ival <= micro_tdata.shf_ival;
                shf8_req_tdata.dreg <= micro_tdata.shf_dreg;
                shf8_req_tdata.dmask <= micro_tdata.shf_dmask;
            elsif (shf8_wait_fifo = '1' and lsu_rd_s_tvalid = '1') then
                shf8_req_tdata.sval <= lsu_rd_s_tdata;
            end if;

            if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_SHF) = '1' and micro_tdata.shf_w  = '1') then
                shf16_req_tdata.code <= micro_tdata.shf_code;
                shf16_req_tdata.w <= micro_tdata.shf_w;
                shf16_req_tdata.wb <= micro_tdata.shf_wb;
                shf16_req_tdata.sval <= micro_tdata.shf_sval;
                shf16_req_tdata.ival <= micro_tdata.shf_ival;
                shf16_req_tdata.dreg <= micro_tdata.shf_dreg;
                shf16_req_tdata.dmask <= micro_tdata.shf_dmask;
            elsif (shf16_wait_fifo = '1' and lsu_rd_s_tvalid = '1') then
                shf16_req_tdata.sval <= lsu_rd_s_tdata;
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
                    alu_req_tdata.aval <= mem_buf_tdata;
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
    res_tdata_selector(1) <= one_res_tvalid;
    res_tdata_selector(2) <= bcd_res_tvalid;
    res_tdata_selector(3) <= shf8_res_tvalid;
    res_tdata_selector(4) <= shf16_res_tvalid;
    res_tdata_selector(5) <= mul_res_tvalid;
    res_tdata_selector(6) <= div_res_tvalid;
    res_tdata_selector(7) <= str_res_tvalid;

    res_proc : process (clk) begin
        if rising_edge(clk) then

            case res_tdata_selector is
                when "00000010" =>
                    res_tdata.code <= one_res_tdata.code;
                    res_tdata.dmask <= one_res_tdata.dmask;
                    res_tdata.dval_lo <= one_res_tdata.dval(15 downto 0);
                    res_tdata.dval_hi <= one_res_tdata.dval(15 downto 0);
                    res_tuser <= one_res_tuser;
                when "00000100" =>
                    res_tdata.code <= bcd_res_tdata.code;
                    res_tdata.dmask <= bcd_res_tdata.dmask;
                    res_tdata.dval_lo <= bcd_res_tdata.dval(15 downto 0);
                    res_tdata.dval_hi <= bcd_res_tdata.dval(15 downto 0);
                    res_tuser <= bcd_res_tuser;
                when "00001000" =>
                    res_tdata.code <= shf8_res_tdata.code;
                    res_tdata.dmask <= shf8_res_tdata.dmask;
                    res_tdata.dval_lo(7 downto 0) <= shf8_res_tdata.dval(7 downto 0);
                    res_tdata.dval_hi(7 downto 0) <= shf8_res_tdata.dval(7 downto 0);
                    res_tuser <= shf8_res_tuser;
                when "00010000" =>
                    res_tdata.code <= shf16_res_tdata.code;
                    res_tdata.dmask <= shf16_res_tdata.dmask;
                    res_tdata.dval_lo <= shf16_res_tdata.dval(15 downto 0);
                    res_tdata.dval_hi <= shf16_res_tdata.dval(15 downto 0);
                    res_tuser <= shf16_res_tuser;
                when "00100000" =>
                    res_tdata.code <= mul_res_tdata.code;
                    res_tdata.dmask <= mul_res_tdata.dmask;
                    res_tdata.dval_lo <= mul_res_tdata.dval(15 downto 0);
                    if ((mul_res_tdata.code = IMUL_AXDX and mul_res_tdata.w = '1' and mul_res_tdata.dreg = DX)) then
                        res_tdata.dval_hi <= mul_res_tdata.dval(31 downto 16);
                    else
                        res_tdata.dval_hi <= mul_res_tdata.dval(15 downto 0);
                    end if;
                    res_tuser <= mul_res_tuser;
                when "01000000" =>
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
                when "10000000" =>
                    res_tuser <= str_res_tuser;
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
                if ((alu_res_tvalid = '1' and alu_res_tdata.wb = '1' and alu_res_tdata.dreg = AX) or
                    (mul_res_tvalid = '1' and (mul_res_tdata.dreg = AX or
                        (mul_res_tdata.code = IMUL_AXDX and mul_res_tdata.w = '1' and mul_res_tdata.dreg = DX))) or
                    (div_res_tvalid = '1' and div_res_tdata.overflow = '0') or
                    (one_res_tvalid = '1' and one_res_tdata.wb = '1' and one_res_tdata.dreg = AX) or
                    (shf8_res_tvalid = '1' and shf8_res_tdata.wb = '1' and shf8_res_tdata.dreg = AX) or
                    (shf16_res_tvalid = '1' and shf16_res_tdata.wb = '1' and shf16_res_tdata.dreg = AX) or
                    (str_res_tvalid = '1' and str_res_tdata.ax_upd_fl = '1') or
                    (bcd_res_tvalid = '1')) then
                    ax_m_wr_tvalid <= '1';
                else
                    ax_m_wr_tvalid <= '0';
                end if;

                if ((alu_res_tvalid = '1' and alu_res_tdata.wb = '1' and alu_res_tdata.dreg = BX) or
                    (mul_res_tvalid = '1' and mul_res_tdata.dreg = BX) or
                    (one_res_tvalid = '1' and one_res_tdata.wb = '1' and one_res_tdata.dreg = BX) or
                    (shf8_res_tvalid = '1' and shf8_res_tdata.wb = '1' and shf8_res_tdata.dreg = BX) or
                    (shf16_res_tvalid = '1' and shf16_res_tdata.wb = '1' and shf16_res_tdata.dreg = BX)) then
                    bx_m_wr_tvalid <= '1';
                else
                    bx_m_wr_tvalid <= '0';
                end if;

                if ((alu_res_tvalid = '1' and alu_res_tdata.wb = '1' and alu_res_tdata.dreg = CX) or
                    (mul_res_tvalid = '1' and mul_res_tdata.dreg = CX) or
                    (one_res_tvalid = '1' and one_res_tdata.wb = '1' and one_res_tdata.dreg = CX) or
                    (shf8_res_tvalid = '1' and shf8_res_tdata.wb = '1' and shf8_res_tdata.dreg = CX) or
                    (shf16_res_tvalid = '1' and shf16_res_tdata.wb = '1' and shf16_res_tdata.dreg = CX) or
                    (str_res_tvalid = '1' and str_res_tdata.rep = '1')) then
                    cx_m_wr_tvalid <= '1';
                else
                    cx_m_wr_tvalid <= '0';
                end if;

                if ((alu_res_tvalid = '1' and alu_res_tdata.wb = '1' and alu_res_tdata.dreg = DX) or
                    (mul_res_tvalid = '1' and mul_res_tdata.dreg = DX) or
                    (div_res_tvalid = '1' and (div_res_tdata.code = DIVU_DIV or div_res_tdata.code = DIVU_IDIV) and
                        div_res_tdata.w = '1' and div_res_tdata.overflow = '0') or
                    (one_res_tvalid = '1' and one_res_tdata.wb = '1' and one_res_tdata.dreg = DX) or
                    (shf8_res_tvalid = '1' and shf8_res_tdata.wb = '1' and shf8_res_tdata.dreg = DX) or
                    (shf16_res_tvalid = '1' and shf16_res_tdata.wb = '1' and shf16_res_tdata.dreg = DX)) then
                    dx_m_wr_tvalid <= '1';
                else
                    dx_m_wr_tvalid <= '0';
                end if;

                if ((alu_res_tvalid = '1' and alu_res_tdata.wb = '1' and alu_res_tdata.dreg = BP) or
                    (mul_res_tvalid = '1' and mul_res_tdata.dreg = BP) or
                    (one_res_tvalid = '1' and one_res_tdata.wb = '1' and one_res_tdata.dreg = BP) or
                    (shf8_res_tvalid = '1' and shf8_res_tdata.wb = '1' and shf8_res_tdata.dreg = BP) or
                    (shf16_res_tvalid = '1' and shf16_res_tdata.wb = '1' and shf16_res_tdata.dreg = BP)) then
                    bp_m_wr_tvalid <= '1';
                else
                    bp_m_wr_tvalid <= '0';
                end if;

                if ((alu_res_tvalid = '1' and alu_res_tdata.wb = '1' and alu_res_tdata.dreg = SP) or
                    (mul_res_tvalid = '1' and mul_res_tdata.dreg = SP) or
                    (one_res_tvalid = '1' and one_res_tdata.wb = '1' and one_res_tdata.dreg = SP) or
                    (shf8_res_tvalid = '1' and shf8_res_tdata.wb = '1' and shf8_res_tdata.dreg = SP) or
                    (shf16_res_tvalid = '1' and shf16_res_tdata.wb = '1' and shf16_res_tdata.dreg = SP)) then
                    sp_m_wr_tvalid <= '1';
                else
                    sp_m_wr_tvalid <= '0';
                end if;

                if ((alu_res_tvalid = '1' and alu_res_tdata.wb = '1' and alu_res_tdata.dreg = DI) or
                    (mul_res_tvalid = '1' and mul_res_tdata.dreg = DI) or
                    (one_res_tvalid = '1' and one_res_tdata.wb = '1' and one_res_tdata.dreg = DI) or
                    (shf8_res_tvalid = '1' and shf8_res_tdata.wb = '1' and shf8_res_tdata.dreg = DI) or
                    (shf16_res_tvalid = '1' and shf16_res_tdata.wb = '1' and shf16_res_tdata.dreg = DI) or
                    (str_res_tvalid = '1' and str_res_tdata.di_upd_fl = '1')) then
                    di_m_wr_tvalid <= '1';
                else
                    di_m_wr_tvalid <= '0';
                end if;

                if ((alu_res_tvalid = '1' and alu_res_tdata.wb = '1' and alu_res_tdata.dreg = SI) or
                    (mul_res_tvalid = '1' and mul_res_tdata.dreg = SI) or
                    (one_res_tvalid = '1' and one_res_tdata.wb = '1' and one_res_tdata.dreg = SI) or
                    (shf8_res_tvalid = '1' and shf8_res_tdata.wb = '1' and shf8_res_tdata.dreg = SI) or
                    (shf16_res_tvalid = '1' and shf16_res_tdata.wb = '1' and shf16_res_tdata.dreg = SI) or
                    (str_res_tvalid = '1' and str_res_tdata.si_upd_fl = '1')) then
                    si_m_wr_tvalid <= '1';
                else
                    si_m_wr_tvalid <= '0';
                end if;

                if ((alu_res_tvalid = '1' and alu_res_tdata.wb = '1' and alu_res_tdata.dreg = DS)) then
                    ds_m_wr_tvalid <= '1';
                else
                    ds_m_wr_tvalid <= '0';
                end if;

                if ((alu_res_tvalid = '1' and alu_res_tdata.wb = '1' and alu_res_tdata.dreg = ES)) then
                    es_m_wr_tvalid <= '1';
                else
                    es_m_wr_tvalid <= '0';
                end if;

                if ((alu_res_tvalid = '1' and alu_res_tdata.wb = '1' and alu_res_tdata.dreg = SS)) then
                    ss_m_wr_tvalid <= '1';
                else
                    ss_m_wr_tvalid <= '0';
                end if;

            end if;

            if (alu_res_tvalid = '1' and alu_res_tdata.wb = '1' and alu_res_tdata.dreg = AX) then
                ax_m_wr_tdata <= alu_res_tdata.dval(15 downto 0);
                ax_m_wr_tmask <= alu_res_tdata.dmask;
            elsif (mul_res_tvalid = '1' and mul_res_tdata.dreg = AX) or
                  (mul_res_tvalid = '1' and mul_res_tdata.code = IMUL_AXDX and mul_res_tdata.w = '1' and mul_res_tdata.dreg = DX) then
                ax_m_wr_tdata <= mul_res_tdata.dval(15 downto 0);
                ax_m_wr_tmask <= mul_res_tdata.dmask;
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
            elsif (one_res_tvalid = '1' and one_res_tdata.wb = '1' and one_res_tdata.dreg = AX) then
                ax_m_wr_tdata <= one_res_tdata.dval(15 downto 0);
                ax_m_wr_tmask <= one_res_tdata.dmask;
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

            if (alu_res_tvalid = '1' and alu_res_tdata.wb = '1' and alu_res_tdata.dreg = CX) then
                cx_m_wr_tdata <= alu_res_tdata.dval(15 downto 0);
                cx_m_wr_tmask <= alu_res_tdata.dmask;
            elsif (mul_res_tvalid = '1' and mul_res_tdata.dreg = CX) then
                cx_m_wr_tdata <= mul_res_tdata.dval(15 downto 0);
                cx_m_wr_tmask <= mul_res_tdata.dmask;
            elsif (one_res_tvalid = '1' and one_res_tdata.wb = '1' and one_res_tdata.dreg = CX) then
                cx_m_wr_tdata <= one_res_tdata.dval(15 downto 0);
                cx_m_wr_tmask <= one_res_tdata.dmask;
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

            if (alu_res_tvalid = '1' and alu_res_tdata.wb = '1' and alu_res_tdata.dreg = DI) then
                di_m_wr_tdata <= alu_res_tdata.dval(15 downto 0);
            elsif (mul_res_tvalid = '1' and mul_res_tdata.dreg = DI) then
                di_m_wr_tdata <= mul_res_tdata.dval(15 downto 0);
            elsif (one_res_tvalid = '1' and one_res_tdata.wb = '1' and one_res_tdata.dreg = DI) then
                di_m_wr_tdata <= one_res_tdata.dval(15 downto 0);
            elsif (shf8_res_tvalid = '1' and shf8_res_tdata.wb = '1' and shf8_res_tdata.dreg = DI) then
                di_m_wr_tdata(7 downto 0) <= shf8_res_tdata.dval(7 downto 0);
            elsif (shf16_res_tvalid = '1' and shf16_res_tdata.wb = '1' and shf16_res_tdata.dreg = DI) then
                di_m_wr_tdata <= shf16_res_tdata.dval;
            elsif (str_res_tvalid = '1') then
                di_m_wr_tdata <= str_res_tdata.di_val;
            end if;

            if (alu_res_tvalid = '1' and alu_res_tdata.wb = '1' and alu_res_tdata.dreg = SI) then
                si_m_wr_tdata <= alu_res_tdata.dval(15 downto 0);
            elsif (mul_res_tvalid = '1' and mul_res_tdata.dreg = SI) then
                si_m_wr_tdata <= mul_res_tdata.dval(15 downto 0);
            elsif (one_res_tvalid = '1' and one_res_tdata.wb = '1' and one_res_tdata.dreg = SI) then
                si_m_wr_tdata <= one_res_tdata.dval(15 downto 0);
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
    flags_wr_selector(2) <= one_res_tvalid;
    flags_wr_selector(3) <= div_res_tvalid;
    flags_wr_selector(4) <= bcd_res_tvalid;
    flags_wr_selector(5) <= shf8_res_tvalid;
    flags_wr_selector(6) <= shf16_res_tvalid;
    flags_wr_selector(7) <= mul_res_tvalid;
    flags_wr_selector(8) <= str_res_tvalid;

    flags_upd_proc : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                flags_m_wr_tvalid <= '0';
                flags_wr_be <= (others => '0');
            else

                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_FLG) = '1') then
                    flags_m_wr_tvalid <= '1';
                elsif ((alu_res_tvalid = '1' and alu_res_tdata.upd_fl = '1') or
                       mul_res_tvalid = '1' or one_res_tvalid = '1' or bcd_res_tvalid = '1' or
                       shf8_res_tvalid = '1' or shf16_res_tvalid = '1' or
                       (div_res_tvalid = '1' and div_res_tdata.code = DIVU_AAM) or
                       (str_res_tvalid = '1')) then
                    flags_m_wr_tvalid <= '1';
                else
                    flags_m_wr_tvalid <= '0';
                end if;

                case flags_wr_selector is
                    when "000000001" =>
                        for i in 0 to 15 loop
                            if (micro_tdata.flg_no = std_logic_vector(to_unsigned(i, 4))) then
                                flags_wr_be(i) <= '1';
                            else
                                flags_wr_be(i) <= '0';
                            end if;
                        end loop;
                    when "000000010" =>
                        if (alu_res_tdata.dreg = FL) then

                            for i in 15 downto 8 loop
                                flags_wr_be(i) <= alu_res_tdata.dmask(1);
                            end loop;

                            flags_wr_be(FLAG_ZF) <= alu_res_tdata.dmask(0);
                            flags_wr_be(FLAG_05) <= '0';
                            flags_wr_be(FLAG_AF) <= '0';
                            flags_wr_be(FLAG_03) <= '0';
                            flags_wr_be(FLAG_PF) <= alu_res_tdata.dmask(0);
                            flags_wr_be(FLAG_01) <= '0';
                            flags_wr_be(FLAG_CF) <= alu_res_tdata.dmask(0);

                        else
                            case (alu_res_tdata.code) is
                                when ALU_OP_AND | ALU_OP_OR | ALU_OP_XOR | ALU_OP_TST =>
                                    flags_wr_be(FLAG_15) <= '0';
                                    flags_wr_be(FLAG_14) <= '0';
                                    flags_wr_be(FLAG_13) <= '0';
                                    flags_wr_be(FLAG_12) <= '0';
                                    flags_wr_be(FLAG_OF) <= '1';
                                    flags_wr_be(FLAG_DF) <= '0';
                                    flags_wr_be(FLAG_IF) <= '0';
                                    flags_wr_be(FLAG_TF) <= '0';
                                    flags_wr_be(FLAG_SF) <= '1';
                                    flags_wr_be(FLAG_ZF) <= '1';
                                    flags_wr_be(FLAG_05) <= '0';
                                    flags_wr_be(FLAG_AF) <= '1';
                                    flags_wr_be(FLAG_03) <= '0';
                                    flags_wr_be(FLAG_PF) <= '1';
                                    flags_wr_be(FLAG_01) <= '0';
                                    flags_wr_be(FLAG_CF) <= '1';
                                when ALU_OP_INC | ALU_OP_DEC =>
                                    flags_wr_be(FLAG_15) <= '0';
                                    flags_wr_be(FLAG_14) <= '0';
                                    flags_wr_be(FLAG_13) <= '0';
                                    flags_wr_be(FLAG_12) <= '0';
                                    flags_wr_be(FLAG_OF) <= '1';
                                    flags_wr_be(FLAG_DF) <= '0';
                                    flags_wr_be(FLAG_IF) <= '0';
                                    flags_wr_be(FLAG_TF) <= '0';
                                    flags_wr_be(FLAG_SF) <= '1';
                                    flags_wr_be(FLAG_ZF) <= '1';
                                    flags_wr_be(FLAG_05) <= '0';
                                    flags_wr_be(FLAG_AF) <= '1';
                                    flags_wr_be(FLAG_03) <= '0';
                                    flags_wr_be(FLAG_PF) <= '1';
                                    flags_wr_be(FLAG_01) <= '0';
                                    flags_wr_be(FLAG_CF) <= '0';
                                when others =>
                                    -- ALU_OP_ADD | ALU_OP_SUB
                                    flags_wr_be(FLAG_15) <= '0';
                                    flags_wr_be(FLAG_14) <= '0';
                                    flags_wr_be(FLAG_13) <= '0';
                                    flags_wr_be(FLAG_12) <= '0';
                                    flags_wr_be(FLAG_OF) <= '1';
                                    flags_wr_be(FLAG_DF) <= '0';
                                    flags_wr_be(FLAG_IF) <= '0';
                                    flags_wr_be(FLAG_TF) <= '0';
                                    flags_wr_be(FLAG_SF) <= '1';
                                    flags_wr_be(FLAG_ZF) <= '1';
                                    flags_wr_be(FLAG_05) <= '0';
                                    flags_wr_be(FLAG_AF) <= '1';
                                    flags_wr_be(FLAG_03) <= '0';
                                    flags_wr_be(FLAG_PF) <= '1';
                                    flags_wr_be(FLAG_01) <= '0';
                                    flags_wr_be(FLAG_CF) <= '1';
                            end case;
                        end if;
                    when "000000100" =>
                        case (one_res_tdata.code) is
                            when ONE_OP_NEG =>
                                flags_wr_be(FLAG_15) <= '0';
                                flags_wr_be(FLAG_14) <= '0';
                                flags_wr_be(FLAG_13) <= '0';
                                flags_wr_be(FLAG_12) <= '0';
                                flags_wr_be(FLAG_OF) <= '1';
                                flags_wr_be(FLAG_DF) <= '0';
                                flags_wr_be(FLAG_IF) <= '0';
                                flags_wr_be(FLAG_TF) <= '0';
                                flags_wr_be(FLAG_SF) <= '1';
                                flags_wr_be(FLAG_ZF) <= '1';
                                flags_wr_be(FLAG_05) <= '0';
                                flags_wr_be(FLAG_AF) <= '1';
                                flags_wr_be(FLAG_03) <= '0';
                                flags_wr_be(FLAG_PF) <= '1';
                                flags_wr_be(FLAG_01) <= '0';
                                flags_wr_be(FLAG_CF) <= '1';
                            when others =>
                                flags_wr_be <= (others => '0');
                        end case;
                    when "000001000" =>
                        if (div_res_tdata.code = DIVU_AAM) then
                                flags_wr_be(FLAG_15) <= '0';
                                flags_wr_be(FLAG_14) <= '0';
                                flags_wr_be(FLAG_13) <= '0';
                                flags_wr_be(FLAG_12) <= '0';
                                flags_wr_be(FLAG_OF) <= '0';
                                flags_wr_be(FLAG_DF) <= '0';
                                flags_wr_be(FLAG_IF) <= '0';
                                flags_wr_be(FLAG_TF) <= '0';
                                flags_wr_be(FLAG_SF) <= '1';
                                flags_wr_be(FLAG_ZF) <= '1';
                                flags_wr_be(FLAG_05) <= '0';
                                flags_wr_be(FLAG_AF) <= '0';
                                flags_wr_be(FLAG_03) <= '0';
                                flags_wr_be(FLAG_PF) <= '1';
                                flags_wr_be(FLAG_01) <= '0';
                                flags_wr_be(FLAG_CF) <= '0';
                        end if;
                    when "000010000" =>
                        case (bcd_res_tdata.code) is
                            when BCDU_AAA | BCDU_AAS =>
                                flags_wr_be(FLAG_15) <= '0';
                                flags_wr_be(FLAG_14) <= '0';
                                flags_wr_be(FLAG_13) <= '0';
                                flags_wr_be(FLAG_12) <= '0';
                                flags_wr_be(FLAG_OF) <= '0';
                                flags_wr_be(FLAG_DF) <= '0';
                                flags_wr_be(FLAG_IF) <= '0';
                                flags_wr_be(FLAG_TF) <= '0';
                                flags_wr_be(FLAG_SF) <= '0';
                                flags_wr_be(FLAG_ZF) <= '0';
                                flags_wr_be(FLAG_05) <= '0';
                                flags_wr_be(FLAG_AF) <= '1';
                                flags_wr_be(FLAG_03) <= '0';
                                flags_wr_be(FLAG_PF) <= '0';
                                flags_wr_be(FLAG_01) <= '0';
                                flags_wr_be(FLAG_CF) <= '1';
                            when BCDU_AAD =>
                                flags_wr_be(FLAG_15) <= '0';
                                flags_wr_be(FLAG_14) <= '0';
                                flags_wr_be(FLAG_13) <= '0';
                                flags_wr_be(FLAG_12) <= '0';
                                flags_wr_be(FLAG_OF) <= '0';
                                flags_wr_be(FLAG_DF) <= '0';
                                flags_wr_be(FLAG_IF) <= '0';
                                flags_wr_be(FLAG_TF) <= '0';
                                flags_wr_be(FLAG_SF) <= '1';
                                flags_wr_be(FLAG_ZF) <= '1';
                                flags_wr_be(FLAG_05) <= '0';
                                flags_wr_be(FLAG_AF) <= '0';
                                flags_wr_be(FLAG_03) <= '0';
                                flags_wr_be(FLAG_PF) <= '1';
                                flags_wr_be(FLAG_01) <= '0';
                                flags_wr_be(FLAG_CF) <= '0';
                            when BCDU_DAA | BCDU_DAS =>
                                flags_wr_be(FLAG_15) <= '0';
                                flags_wr_be(FLAG_14) <= '0';
                                flags_wr_be(FLAG_13) <= '0';
                                flags_wr_be(FLAG_12) <= '0';
                                flags_wr_be(FLAG_OF) <= '0';
                                flags_wr_be(FLAG_DF) <= '0';
                                flags_wr_be(FLAG_IF) <= '0';
                                flags_wr_be(FLAG_TF) <= '0';
                                flags_wr_be(FLAG_SF) <= '1';
                                flags_wr_be(FLAG_ZF) <= '1';
                                flags_wr_be(FLAG_05) <= '0';
                                flags_wr_be(FLAG_AF) <= '1';
                                flags_wr_be(FLAG_03) <= '0';
                                flags_wr_be(FLAG_PF) <= '1';
                                flags_wr_be(FLAG_01) <= '0';
                                flags_wr_be(FLAG_CF) <= '1';
                            when others =>
                                flags_wr_be <= (others => '0');
                        end case;
                    when "000100000" =>
                        case (shf8_res_tdata.code) is
                            when SHF_OP_ROL | SHF_OP_ROR | SHF_OP_RCL | SHF_OP_RCR =>
                                flags_wr_be(FLAG_15) <= '0';
                                flags_wr_be(FLAG_14) <= '0';
                                flags_wr_be(FLAG_13) <= '0';
                                flags_wr_be(FLAG_12) <= '0';
                                flags_wr_be(FLAG_OF) <= '1';
                                flags_wr_be(FLAG_DF) <= '0';
                                flags_wr_be(FLAG_IF) <= '0';
                                flags_wr_be(FLAG_TF) <= '0';
                                flags_wr_be(FLAG_SF) <= '0';
                                flags_wr_be(FLAG_ZF) <= '0';
                                flags_wr_be(FLAG_05) <= '0';
                                flags_wr_be(FLAG_AF) <= '0';
                                flags_wr_be(FLAG_03) <= '0';
                                flags_wr_be(FLAG_PF) <= '0';
                                flags_wr_be(FLAG_01) <= '0';
                                flags_wr_be(FLAG_CF) <= '1';
                            when SHF_OP_SHL | SHF_OP_SAR | SHF_OP_SHR =>
                                flags_wr_be(FLAG_15) <= '0';
                                flags_wr_be(FLAG_14) <= '0';
                                flags_wr_be(FLAG_13) <= '0';
                                flags_wr_be(FLAG_12) <= '0';
                                flags_wr_be(FLAG_OF) <= '1';
                                flags_wr_be(FLAG_DF) <= '0';
                                flags_wr_be(FLAG_IF) <= '0';
                                flags_wr_be(FLAG_TF) <= '0';
                                flags_wr_be(FLAG_SF) <= '1';
                                flags_wr_be(FLAG_ZF) <= '1';
                                flags_wr_be(FLAG_05) <= '0';
                                flags_wr_be(FLAG_AF) <= '0';
                                flags_wr_be(FLAG_03) <= '0';
                                flags_wr_be(FLAG_PF) <= '1';
                                flags_wr_be(FLAG_01) <= '0';
                                flags_wr_be(FLAG_CF) <= '1';
                            when others =>
                                flags_wr_be <= (others => '0');
                        end case;
                    when "001000000" =>
                        case (shf16_res_tdata.code) is
                            when SHF_OP_ROL | SHF_OP_ROR | SHF_OP_RCL | SHF_OP_RCR =>
                                flags_wr_be(FLAG_15) <= '0';
                                flags_wr_be(FLAG_14) <= '0';
                                flags_wr_be(FLAG_13) <= '0';
                                flags_wr_be(FLAG_12) <= '0';
                                flags_wr_be(FLAG_OF) <= '1';
                                flags_wr_be(FLAG_DF) <= '0';
                                flags_wr_be(FLAG_IF) <= '0';
                                flags_wr_be(FLAG_TF) <= '0';
                                flags_wr_be(FLAG_SF) <= '0';
                                flags_wr_be(FLAG_ZF) <= '0';
                                flags_wr_be(FLAG_05) <= '0';
                                flags_wr_be(FLAG_AF) <= '0';
                                flags_wr_be(FLAG_03) <= '0';
                                flags_wr_be(FLAG_PF) <= '0';
                                flags_wr_be(FLAG_01) <= '0';
                                flags_wr_be(FLAG_CF) <= '1';
                            when SHF_OP_SHL | SHF_OP_SAR | SHF_OP_SHR =>
                                flags_wr_be(FLAG_15) <= '0';
                                flags_wr_be(FLAG_14) <= '0';
                                flags_wr_be(FLAG_13) <= '0';
                                flags_wr_be(FLAG_12) <= '0';
                                flags_wr_be(FLAG_OF) <= '1';
                                flags_wr_be(FLAG_DF) <= '0';
                                flags_wr_be(FLAG_IF) <= '0';
                                flags_wr_be(FLAG_TF) <= '0';
                                flags_wr_be(FLAG_SF) <= '1';
                                flags_wr_be(FLAG_ZF) <= '1';
                                flags_wr_be(FLAG_05) <= '0';
                                flags_wr_be(FLAG_AF) <= '0';
                                flags_wr_be(FLAG_03) <= '0';
                                flags_wr_be(FLAG_PF) <= '1';
                                flags_wr_be(FLAG_01) <= '0';
                                flags_wr_be(FLAG_CF) <= '1';
                            when others =>
                                flags_wr_be <= (others => '0');
                        end case;
                    when "010000000" =>
                        flags_wr_be(FLAG_15) <= '0';
                        flags_wr_be(FLAG_14) <= '0';
                        flags_wr_be(FLAG_13) <= '0';
                        flags_wr_be(FLAG_12) <= '0';
                        flags_wr_be(FLAG_OF) <= '1';
                        flags_wr_be(FLAG_DF) <= '0';
                        flags_wr_be(FLAG_IF) <= '0';
                        flags_wr_be(FLAG_TF) <= '0';
                        flags_wr_be(FLAG_SF) <= '1';
                        flags_wr_be(FLAG_ZF) <= '0';
                        flags_wr_be(FLAG_05) <= '0';
                        flags_wr_be(FLAG_AF) <= '0';
                        flags_wr_be(FLAG_03) <= '0';
                        flags_wr_be(FLAG_PF) <= '1';
                        flags_wr_be(FLAG_01) <= '0';
                        flags_wr_be(FLAG_CF) <= '1';
                    when "100000000" =>
                        case (str_res_tdata.code) is
                            when SCAS_OP | CMPS_OP =>
                                flags_wr_be(FLAG_15) <= '0';
                                flags_wr_be(FLAG_14) <= '0';
                                flags_wr_be(FLAG_13) <= '0';
                                flags_wr_be(FLAG_12) <= '0';
                                flags_wr_be(FLAG_OF) <= '1';
                                flags_wr_be(FLAG_DF) <= '0';
                                flags_wr_be(FLAG_IF) <= '0';
                                flags_wr_be(FLAG_TF) <= '0';
                                flags_wr_be(FLAG_SF) <= '1';
                                flags_wr_be(FLAG_ZF) <= '1';
                                flags_wr_be(FLAG_05) <= '0';
                                flags_wr_be(FLAG_AF) <= '1';
                                flags_wr_be(FLAG_03) <= '0';
                                flags_wr_be(FLAG_PF) <= '1';
                                flags_wr_be(FLAG_01) <= '0';
                                flags_wr_be(FLAG_CF) <= '1';
                            when others =>
                                flags_wr_be <= (others => '0');
                        end case;
                    when others =>
                        null;
                end case;

            end if;

            if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_FLG) = '1') then
                flags_src <= CMD_FLG;
            elsif (alu_res_tvalid = '1' and alu_res_tdata.upd_fl = '1') then
                if (alu_res_tdata.dreg = FL) then
                    flags_src <= RES_DATA;
                else
                    flags_src <= RES_USER;
                end if;
            elsif (mul_res_tvalid = '1' or one_res_tvalid = '1' or
                   bcd_res_tvalid = '1' or shf8_res_tvalid = '1' or
                   div_req_tvalid = '1' or shf16_res_tvalid = '1' or
                   str_res_tvalid = '1')
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

        if (flags_src = RES_DATA) then
            flags_wr_vector(15 downto 11) <= res_tdata.dval_lo(15 downto 11);
            flags_wr_vector(8 downto 1) <= res_tdata.dval_lo(8 downto 1);
        else
            flags_wr_vector(15 downto 11) <= res_tuser(15 downto 11);
            flags_wr_vector(8 downto 1) <= res_tuser(8 downto 1);
        end if;

        case flags_src is
            when RES_DATA =>
                flags_wr_vector(FLAG_CF) <= res_tdata.dval_lo(FLAG_CF);
                flags_wr_vector(FLAG_DF) <= res_tdata.dval_lo(FLAG_DF);
                flags_wr_vector(FLAG_IF) <= res_tdata.dval_lo(FLAG_IF);
            when RES_USER =>
                flags_wr_vector(FLAG_CF) <= res_tuser(FLAG_CF);
                flags_wr_vector(FLAG_DF) <= res_tuser(FLAG_DF);
                flags_wr_vector(FLAG_IF) <= res_tuser(FLAG_IF);
            when others =>
                if (flags_toggle_cf = '1') then
                    flags_wr_vector(FLAG_CF) <= not flags_s_tdata(FLAG_CF);
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
                mem_buf_tdata <= lsu_rd_s_tdata;
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

    jump_control_proc: process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                jmp_tvalid <= '0';
                jmp_tdata <= '0';
                jmp_wait_alu <= '0';
                jmp_busy <= '0';
                jmp_wait_mem_cs <= '0';
                jmp_wait_mem_ip <= '0';
                jmp_cond <= j_never;
                jump_m_tvalid <= '0';
            else

                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_JMP) = '1') then
                    jmp_cond <= micro_tdata.jump_cond;
                end if;

                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_JMP) = '1') then
                    if (micro_tdata.jump_cond = cx_ne_0) then
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
                    (micro_tdata.jump_cs_mem = '1' or micro_tdata.jump_ip_mem = '1' or
                     micro_tdata.jump_cond = cx_ne_0 or micro_tdata.jump_cond = cx_ne_0_and_zf or
                     micro_tdata.jump_cond = cx_ne_0_and_nzf))
                then
                    jmp_busy <= '1';
                elsif (jmp_busy = '1') then
                    if not ((jmp_wait_mem_cs = '1' or jmp_wait_mem_ip = '1') xor lsu_rd_s_tvalid = '1') and
                        not (jmp_wait_alu = '1' xor alu_res_tvalid = '1')
                    then
                        jmp_busy <= '0';
                    end if;
                end if;

                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_JMP) = '1') then
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
                    if not ((jmp_wait_mem_cs = '1' or jmp_wait_mem_ip = '1') xor lsu_rd_s_tvalid = '1') and
                        not (jmp_wait_alu = '1' xor alu_res_tvalid = '1')
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
                        when j_always =>
                            jmp_tdata <= '1';

                        when j_ja =>
                            if (flags_s_tdata(FLAG_ZF) = '0' and flags_s_tdata(FLAG_CF) = '0') then
                                jmp_tdata <= '1';
                            else
                                jmp_tdata <= '0';
                            end if;

                        when j_jae =>
                            if (flags_s_tdata(FLAG_CF) = '0') then
                                jmp_tdata <= '1';
                            else
                                jmp_tdata <= '0';
                            end if;

                        when j_jb =>
                            if (flags_s_tdata(FLAG_CF) = '1') then
                                jmp_tdata <= '1';
                            else
                                jmp_tdata <= '0';
                            end if;

                        when j_jbe =>
                            if (flags_s_tdata(FLAG_ZF) = '1' or flags_s_tdata(FLAG_CF) = '1') then
                                jmp_tdata <= '1';
                            else
                                jmp_tdata <= '0';
                            end if;

                        when j_je =>
                            if (flags_s_tdata(FLAG_ZF) = '1') then
                                jmp_tdata <= '1';
                            else
                                jmp_tdata <= '0';
                            end if;

                        when j_jne =>
                            if (flags_s_tdata(FLAG_ZF) = '0') then
                                jmp_tdata <= '1';
                            else
                                jmp_tdata <= '0';
                            end if;

                        when j_jg =>
                            if (flags_s_tdata(FLAG_ZF) = '0' and flags_s_tdata(FLAG_SF) = flags_s_tdata(FLAG_OF)) then
                                jmp_tdata <= '1';
                            else
                                jmp_tdata <= '0';
                            end if;

                        when j_jge =>
                            if (flags_s_tdata(FLAG_SF) = flags_s_tdata(FLAG_OF)) then
                                jmp_tdata <= '1';
                            else
                                jmp_tdata <= '0';
                            end if;

                        when j_jl =>
                            if (flags_s_tdata(FLAG_SF) /= flags_s_tdata(FLAG_OF)) then
                                jmp_tdata <= '1';
                            else
                                jmp_tdata <= '0';
                            end if;

                        when j_jle =>
                            if (flags_s_tdata(FLAG_ZF) = '1' or flags_s_tdata(FLAG_SF) /= flags_s_tdata(FLAG_OF)) then
                                jmp_tdata <= '1';
                            else
                                jmp_tdata <= '0';
                            end if;

                        when j_jno =>
                            if (flags_s_tdata(FLAG_OF) = '0') then
                                jmp_tdata <= '1';
                            else
                                jmp_tdata <= '0';
                            end if;

                        when j_jo =>
                            if (flags_s_tdata(FLAG_OF) = '1') then
                                jmp_tdata <= '1';
                            else
                                jmp_tdata <= '0';
                            end if;

                        when j_jnp =>
                            if (flags_s_tdata(FLAG_PF) = '0') then
                                jmp_tdata <= '1';
                            else
                                jmp_tdata <= '0';
                            end if;

                        when j_jp =>
                            if (flags_s_tdata(FLAG_PF) = '1') then
                                jmp_tdata <= '1';
                            else
                                jmp_tdata <= '0';
                            end if;

                        when j_jns =>
                            if (flags_s_tdata(FLAG_SF) = '0') then
                                jmp_tdata <= '1';
                            else
                                jmp_tdata <= '0';
                            end if;

                        when j_js =>
                            if (flags_s_tdata(FLAG_SF) = '1') then
                                jmp_tdata <= '1';
                            else
                                jmp_tdata <= '0';
                            end if;
                        when cx_eq_0 =>
                            if micro_tdata.jump_cx = x"0000" then
                                jmp_tdata <= '1';
                            else
                                jmp_tdata <= '0';
                            end if;
                        when others =>
                            jmp_tdata <= '0';
                    end case;

                elsif (jmp_busy = '1') then
                    if not ((jmp_wait_mem_cs = '1' or jmp_wait_mem_ip = '1') xor lsu_rd_s_tvalid = '1') and
                        not (jmp_wait_alu = '1' xor alu_res_tvalid = '1')
                    then
                        case jmp_cond is
                            when j_always =>
                                jmp_tdata <= '1';
                            when cx_ne_0 =>
                                if alu_res_tdata.dval(15 downto 0) /= x"0000" then
                                    jmp_tdata <= '1';
                                else
                                    jmp_tdata <= '0';
                                end if;

                            when others =>
                                jmp_tdata <= '0';
                        end case;
                    end if;
                end if;

                if (jmp_tvalid = '1') then
                    jump_m_tvalid <= jmp_tdata;
                end if;

            end if;

            if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.jump_imm = '1') then
                jump_m_tdata(31 downto 16) <= micro_tdata.jump_cs;
            elsif (jmp_wait_mem_cs = '1' and lsu_rd_s_tvalid = '1') then
                jump_m_tdata(31 downto 16) <= lsu_rd_s_tdata;
            end if;

            if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.jump_imm = '1') then
                jump_m_tdata(15 downto 0) <= micro_tdata.jump_ip;
            elsif (jmp_wait_mem_ip = '1' and lsu_rd_s_tvalid = '1') then
                jump_m_tdata(15 downto 0) <= lsu_rd_s_tdata;
            end if;

        end if;
    end process;

    lsu_request_forming_proc: process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                lsu_req_tvalid <= '0';
                mem_wait_alu <= '0';
                mem_wait_one <= '0';
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
                    if (micro_tdata.mem_cmd = '1' and micro_tdata.mem_data_src = MEM_DATA_SRC_ONE) then
                        mem_wait_one <= '1';
                    else
                        mem_wait_one <= '0';
                    end if;
                elsif (mem_wait_one = '1' and one_res_tvalid = '1') then
                    mem_wait_one <= '0';
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
                elsif (mem_wait_alu = '1' or mem_wait_fifo = '1' or mem_wait_one = '1' or mem_wait_shf = '1') and
                    not (alu_res_tvalid = '1' xor mem_wait_alu = '1') and
                    not (one_res_tvalid = '1' xor mem_wait_one = '1') and
                    not (lsu_rd_s_tvalid = '1' xor mem_wait_fifo = '1') and
                    not ((shf8_res_tvalid = '1' or shf16_res_tvalid = '1') xor mem_wait_shf = '1') then
                    lsu_req_tvalid <= '1';
                elsif (lsu_req_tready = '1') then
                    lsu_req_tvalid <= '0';
                end if;

            end if;

            if (micro_tvalid = '1' and micro_tready = '1') then
                lsu_req_tcmd <= micro_tdata.mem_cmd;
                lsu_req_twidth <= micro_tdata.mem_width;
                lsu_req_taddr <= std_logic_vector(unsigned(micro_tdata.mem_seg & x"0") + unsigned(x"0" & micro_tdata.mem_addr));
            elsif (str_lsu_req_tvalid = '1' and str_lsu_req_tready = '1') then
                lsu_req_tcmd <= str_lsu_req_tcmd;
                lsu_req_twidth <= str_lsu_req_twidth;
                lsu_req_taddr <= str_lsu_req_taddr;
            end if;

            if (micro_tvalid = '1' and micro_tready = '1') then
                lsu_req_tdata <= micro_tdata.mem_data;
            elsif (str_lsu_req_tvalid = '1' and str_lsu_req_tready = '1') then
                lsu_req_tdata <= str_lsu_req_tdata;
            elsif (mem_wait_alu = '1' and alu_res_tvalid = '1') then
                lsu_req_tdata <= alu_res_tdata.dval(15 downto 0);
            elsif (mem_wait_one = '1' and one_res_tvalid = '1') then
                lsu_req_tdata <= one_res_tdata.dval;
            elsif (mem_wait_shf = '1' and shf8_res_tvalid = '1') then
                lsu_req_tdata <= shf8_res_tdata.dval;
            elsif (mem_wait_shf = '1' and shf16_res_tvalid = '1') then
                lsu_req_tdata <= shf16_res_tdata.dval;
            elsif (mem_wait_fifo = '1' and lsu_rd_s_tvalid = '1') then
                lsu_req_tdata <= lsu_rd_s_tdata;
            end if;

        end if;
    end process;

    bound_check_process : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                bnd_intr_m_tvalid <= '0';
                bnd_wait_fifo <= '0';
            else

                if (micro_tvalid = '1' and micro_tready = '1') then
                    if (micro_tdata.cmd(MICRO_OP_CMD_BND) = '1' AND micro_tdata.cmd(MICRO_OP_CMD_MRD) = '1') then
                        bnd_wait_fifo <= '1';
                    else
                        bnd_wait_fifo <= '0';
                    end if;
                elsif (bnd_wait_fifo = '1' and lsu_rd_s_tvalid = '1') then
                    bnd_wait_fifo <= '0';
                end if;

                if (bnd_wait_fifo = '1' and lsu_rd_s_tvalid = '1') then
                    if (bnd_val < mem_buf_tdata or bnd_val > lsu_rd_s_tdata) then
                        bnd_intr_m_tvalid <= '1';
                    else
                        bnd_intr_m_tvalid <= '0';
                    end if;
                else
                    bnd_intr_m_tvalid <= '0';
                end if;

            end if;

            if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_BND) = '1') then
                bnd_val <= micro_tdata.bnd_val;
            end if;

            if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_BND) = '1') then
                bnd_intr_m_tdata(DIV_INTR_T_SS) <= micro_tdata.bnd_ss_val;
                bnd_intr_m_tdata(DIV_INTR_T_CS) <= micro_tdata.bnd_cs_val;
                bnd_intr_m_tdata(DIV_INTR_T_IP) <= micro_tdata.bnd_ip_val;
                bnd_intr_m_tdata(DIV_INTR_T_IP_NEXT) <= micro_tdata.bnd_ip_val;
            end if;

        end if;
    end process;

    dbg_proc : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                dbg_m_tvalid <= '0';
                dbg_0_tvalid <= '0';
                dbg_1_tvalid <= '0';
            else
                if (micro_tvalid = '1' and micro_tready = '1') then
                    dbg_0_tvalid <= micro_tdata.cmd(MICRO_OP_CMD_DBG);
                else
                    dbg_0_tvalid <= '0';
                end if;
                dbg_1_tvalid <= dbg_0_tvalid;

                dbg_m_tvalid <= dbg_1_tvalid;
            end if;

            if (micro_tvalid = '1' and micro_tready = '1') then
                dbg_m_tdata <= micro_tdata.dbg_cs & micro_tdata.dbg_ip;
            end if;

        end if;
    end process;

end architecture;
