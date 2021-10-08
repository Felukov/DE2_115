library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.cpu86_types.all;

entity exec is
    port (
        clk                         : in std_logic;
        resetn                      : in std_logic;

        instr_s_tvalid              : in std_logic;
        instr_s_tready              : out std_logic;
        instr_s_tdata               : in decoded_instr_t;
        instr_s_tuser               : in std_logic_vector(31 downto 0);

        req_m_tvalid                : out std_logic;
        req_m_tdata                 : out std_logic_vector(31 downto 0);

        mem_req_m_tvalid            : out std_logic;
        mem_req_m_tready            : in std_logic;
        mem_req_m_tdata             : out std_logic_vector(63 downto 0);

        mem_rd_s_tvalid             : in std_logic;
        mem_rd_s_tdata              : in std_logic_vector(31 downto 0);

        dbg_m_tvalid                : out std_logic;
        dbg_m_tdata                 : out std_logic_vector(14*16-1 downto 0)
    );
end entity exec;

architecture rtl of exec is

    component cpu_reg is
        generic (
            DATA_WIDTH              : integer := 16
        );
        port (
            clk                     : in std_logic;
            resetn                  : in std_logic;

            wr_s_tvalid             : in std_logic;
            wr_s_tdata              : in std_logic_vector(DATA_WIDTH-1 downto 0);
            wr_s_tmask              : in std_logic_vector(1 downto 0);
            wr_s_tkeep_lock         : in std_logic;

            lock_s_tvalid           : in std_logic;
            unlk_s_tvalid           : in std_logic;

            reg_m_tvalid            : out std_logic;
            reg_m_tdata             : out std_logic_vector(DATA_WIDTH-1 downto 0)
        );
    end component cpu_reg;

    component cpu_flags is
        generic (
            DATA_WIDTH              : integer := 16
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
    end component cpu_flags;

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

    component register_reader is
        port (
            clk                     : in std_logic;
            resetn                  : in std_logic;

            instr_s_tvalid          : in std_logic;
            instr_s_tready          : out std_logic;
            instr_s_tdata           : in decoded_instr_t;
            instr_s_tuser           : in std_logic_vector(31 downto 0);

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
            rr_m_tuser              : out std_logic_vector(31 downto 0)
        );
    end component register_reader;

    component ifeu is
        port (
            clk                     : in std_logic;
            resetn                  : in std_logic;

            jmp_lock_s_tvalid       : in std_logic;

            rr_s_tvalid             : in std_logic;
            rr_s_tready             : out std_logic;
            rr_s_tdata              : in rr_instr_t;
            rr_s_tuser              : in std_logic_vector(31 downto 0);

            micro_m_tvalid          : out std_logic;
            micro_m_tready          : in std_logic;
            micro_m_tdata           : out micro_op_t;

            bx_s_tdata              : in std_logic_vector(15 downto 0);
            cx_s_tdata              : in std_logic_vector(15 downto 0);
            dx_s_tdata              : in std_logic_vector(15 downto 0);
            bp_s_tdata              : in std_logic_vector(15 downto 0);
            sp_s_tdata              : in std_logic_vector(15 downto 0);
            di_s_tdata              : in std_logic_vector(15 downto 0);
            si_s_tdata              : in std_logic_vector(15 downto 0);
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
            cx_m_wr_tkeep_lock      : out std_logic;
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

            jmp_lock_m_lock_tvalid  : out std_logic
        );
    end component ifeu;

    component mexec is
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

            si_m_wr_tkeep_lock      : out std_logic;
            di_m_wr_tkeep_lock      : out std_logic;

            jump_m_tvalid           : out std_logic;
            jump_m_tdata            : out std_logic_vector(31 downto 0);

            jmp_lock_m_wr_tvalid    : out std_logic;

            lsu_req_m_tvalid        : out std_logic;
            lsu_req_m_tready        : in std_logic;
            lsu_req_m_tcmd          : out std_logic;
            lsu_req_m_twidth        : out std_logic;
            lsu_req_m_taddr         : out std_logic_vector(19 downto 0);
            lsu_req_m_tdata         : out std_logic_vector(15 downto 0);

            dbg_m_tvalid            : out std_logic;
            dbg_m_tdata             : out std_logic_vector(31 downto 0)
        );
    end component mexec;

    component lsu is
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

            mem_req_m_tvalid        : out std_logic;
            mem_req_m_tready        : in std_logic;
            mem_req_m_tdata         : out std_logic_vector(63 downto 0);

            mem_rd_s_tvalid         : in std_logic;
            mem_rd_s_tdata          : in std_logic_vector(31 downto 0);

            lsu_rd_m_tvalid         : out std_logic;
            lsu_rd_m_tready         : in std_logic;
            lsu_rd_m_tdata          : out std_logic_vector(15 downto 0)
        );
    end component lsu;

    component dcache is
        port (
            clk                     : in std_logic;
            resetn                  : in std_logic;

            lsu_req_s_tvalid        : in std_logic;
            lsu_req_s_tready        : in std_logic;
            lsu_req_s_tcmd          : in std_logic;
            lsu_req_s_taddr         : in std_logic_vector(19 downto 0);
            lsu_req_s_twidth        : in std_logic;
            lsu_req_s_tdata         : in std_logic_vector(15 downto 0);

            dcache_m_tvalid         : out std_logic;
            dcache_m_tdata          : out std_logic_vector(15 downto 0)
        );
    end component dcache;


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
    signal si_wr_tkeep_lock         : std_logic;

    signal di_tvalid                : std_logic;
    signal di_tdata                 : std_logic_vector(15 downto 0);
    signal di_lock_tvalid           : std_logic;
    signal di_wr_tvalid             : std_logic;
    signal di_wr_tdata              : std_logic_vector(15 downto 0);
    signal di_wr_tkeep_lock         : std_logic;

    signal flags_tvalid             : std_logic;
    signal flags_tdata              : std_logic_vector(15 downto 0);
    signal flags_lock_tvalid        : std_logic;
    signal flags_wr_tvalid          : std_logic;
    signal flags_wr_tdata           : std_logic_vector(15 downto 0);

    signal rr_tvalid                : std_logic;
    signal rr_tready                : std_logic;
    signal rr_tdata                 : rr_instr_t;
    signal rr_tuser                 : std_logic_vector(31 downto 0);

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
    signal ifeu_cx_wr_tkeep_lock    : std_logic;
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
    signal mexec_di_wr_tkeep_lock   : std_logic;
    signal mexec_si_wr_tvalid       : std_logic;
    signal mexec_si_wr_tdata        : std_logic_vector(15 downto 0);
    signal mexec_si_wr_tkeep_lock   : std_logic;

    signal mexec_ds_wr_tvalid       : std_logic;
    signal mexec_ds_wr_tdata        : std_logic_vector(15 downto 0);
    signal mexec_es_wr_tvalid       : std_logic;
    signal mexec_es_wr_tdata        : std_logic_vector(15 downto 0);
    signal mexec_ss_wr_tvalid       : std_logic;
    signal mexec_ss_wr_tdata        : std_logic_vector(15 downto 0);

    signal jump_tvalid              : std_logic;
    signal jump_tdata               : std_logic_vector(31 downto 0);

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
    signal dcache_tdata             : std_logic_vector(15 downto 0);

    signal fifo_instr_s_tvalid      : std_logic;
    signal fifo_instr_s_tready      : std_logic;
    signal fifo_instr_s_tdata       : std_logic_vector(DECODED_INSTR_T_WIDTH+32-1 downto 0);

    signal fifo_instr_m_tvalid      : std_logic;
    signal fifo_instr_m_tready      : std_logic;
    signal fifo_instr_m_tdata       : std_logic_vector(DECODED_INSTR_T_WIDTH+32-1 downto 0);

    signal instr_tvalid             : std_logic;
    signal instr_tready             : std_logic;
    signal instr_tdata              : decoded_instr_t;
    signal instr_tuser              : std_logic_vector(31 downto 0);

    signal mexec_dbg_tvalid         : std_logic;
    signal mexec_dbg_tdata          : std_logic_vector(31 downto 0);

begin

    exec_resetn <= '0' when resetn = '0' or jump_tvalid = '1' else '1';


    cpu_reg_jmp_lock : cpu_reg generic map (
        DATA_WIDTH              => 1
    ) port map (
        clk                     => clk,
        resetn                  => resetn,

        wr_s_tvalid             => jmp_lock_wr_tvalid,
        wr_s_tdata              => (others => '0') ,
        wr_s_tmask              => "11",
        wr_s_tkeep_lock         => '0',

        lock_s_tvalid           => jmp_lock_lock_tvalid,
        unlk_s_tvalid           => '0',

        reg_m_tvalid            => jmp_lock_tvalid,
        reg_m_tdata             => open
    );


    cpu_reg_ds : cpu_reg generic map (
        DATA_WIDTH              => 16
    ) port map (
        clk                     => clk,
        resetn                  => resetn,

        wr_s_tvalid             => ds_wr_tvalid,
        wr_s_tdata              => ds_wr_tdata,
        wr_s_tmask              => "11",
        wr_s_tkeep_lock         => '0',

        lock_s_tvalid           => ds_lock_tvalid,
        unlk_s_tvalid           => jump_tvalid,

        reg_m_tvalid            => ds_tvalid,
        reg_m_tdata             => ds_tdata
    );


    cpu_reg_ss : cpu_reg generic map (
        DATA_WIDTH              => 16
    ) port map (
        clk                     => clk,
        resetn                  => resetn,

        wr_s_tvalid             => ss_wr_tvalid,
        wr_s_tdata              => ss_wr_tdata,
        wr_s_tmask              => "11",
        wr_s_tkeep_lock         => '0',

        lock_s_tvalid           => ss_lock_tvalid,
        unlk_s_tvalid           => jump_tvalid,

        reg_m_tvalid            => ss_tvalid,
        reg_m_tdata             => ss_tdata
    );


    cpu_reg_es : cpu_reg generic map (
        DATA_WIDTH              => 16
    ) port map (
        clk                     => clk,
        resetn                  => resetn,

        wr_s_tvalid             => es_wr_tvalid,
        wr_s_tdata              => es_wr_tdata,
        wr_s_tmask              => "11",
        wr_s_tkeep_lock         => '0',

        lock_s_tvalid           => es_lock_tvalid,
        unlk_s_tvalid           => jump_tvalid,

        reg_m_tvalid            => es_tvalid,
        reg_m_tdata             => es_tdata
    );


    cpu_reg_ax : cpu_reg generic map (
        DATA_WIDTH              => 16
    ) port map (
        clk                     => clk,
        resetn                  => resetn,

        wr_s_tvalid             => ax_wr_tvalid,
        wr_s_tdata              => ax_wr_tdata,
        wr_s_tmask              => ax_wr_tmask,
        wr_s_tkeep_lock         => '0',

        lock_s_tvalid           => ax_lock_tvalid,
        unlk_s_tvalid           => jump_tvalid,

        reg_m_tvalid            => ax_tvalid,
        reg_m_tdata             => ax_tdata
    );


    cpu_reg_bx : cpu_reg generic map (
        DATA_WIDTH              => 16
    ) port map (
        clk                      => clk,
        resetn                  => resetn,

        wr_s_tvalid             => bx_wr_tvalid,
        wr_s_tdata              => bx_wr_tdata,
        wr_s_tmask              => bx_wr_tmask,
        wr_s_tkeep_lock         => '0',

        lock_s_tvalid           => bx_lock_tvalid,
        unlk_s_tvalid           => jump_tvalid,

        reg_m_tvalid            => bx_tvalid,
        reg_m_tdata             => bx_tdata
    );


    cpu_reg_cx : cpu_reg generic map (
        DATA_WIDTH              => 16
    ) port map (
        clk                     => clk,
        resetn                  => resetn,

        wr_s_tvalid             => cx_wr_tvalid,
        wr_s_tdata              => cx_wr_tdata,
        wr_s_tmask              => cx_wr_tmask,
        wr_s_tkeep_lock         => cx_wr_tkeep_lock,

        lock_s_tvalid           => cx_lock_tvalid,
        unlk_s_tvalid           => jump_tvalid,

        reg_m_tvalid            => cx_tvalid,
        reg_m_tdata             => cx_tdata
    );


    cpu_reg_dx : cpu_reg generic map (
        DATA_WIDTH              => 16
    ) port map (
        clk                     => clk,
        resetn                  => resetn,

        wr_s_tvalid             => dx_wr_tvalid,
        wr_s_tdata              => dx_wr_tdata,
        wr_s_tmask              => dx_wr_tmask,
        wr_s_tkeep_lock         => '0',

        lock_s_tvalid           => dx_lock_tvalid,
        unlk_s_tvalid           => jump_tvalid,

        reg_m_tvalid            => dx_tvalid,
        reg_m_tdata             => dx_tdata
    );


    cpu_reg_bp : cpu_reg generic map (
        DATA_WIDTH              => 16
    ) port map (
        clk                     => clk,
        resetn                  => resetn,

        wr_s_tvalid             => bp_wr_tvalid,
        wr_s_tdata              => bp_wr_tdata,
        wr_s_tmask              => "11",
        wr_s_tkeep_lock         => '0',

        lock_s_tvalid           => bp_lock_tvalid,
        unlk_s_tvalid           => jump_tvalid,

        reg_m_tvalid            => bp_tvalid,
        reg_m_tdata             => bp_tdata
    );


    cpu_reg_sp : cpu_reg generic map (
        DATA_WIDTH              => 16
    ) port map (
        clk                     => clk,
        resetn                  => resetn,

        wr_s_tvalid             => sp_wr_tvalid,
        wr_s_tdata              => sp_wr_tdata,
        wr_s_tmask              => "11",
        wr_s_tkeep_lock         => '0',

        lock_s_tvalid           => sp_lock_tvalid,
        unlk_s_tvalid           => jump_tvalid,

        reg_m_tvalid            => sp_tvalid,
        reg_m_tdata             => sp_tdata
    );


    cpu_reg_di : cpu_reg generic map (
        DATA_WIDTH              => 16
    ) port map (
        clk                     => clk,
        resetn                  => resetn,

        wr_s_tvalid             => di_wr_tvalid,
        wr_s_tdata              => di_wr_tdata,
        wr_s_tmask              => "11",
        wr_s_tkeep_lock         => di_wr_tkeep_lock,

        lock_s_tvalid           => di_lock_tvalid,
        unlk_s_tvalid           => jump_tvalid,

        reg_m_tvalid            => di_tvalid,
        reg_m_tdata             => di_tdata
    );


    cpu_reg_si : cpu_reg generic map (
        DATA_WIDTH              => 16
    ) port map (
        clk                     => clk,
        resetn                  => resetn,

        wr_s_tvalid             => si_wr_tvalid,
        wr_s_tdata              => si_wr_tdata,
        wr_s_tmask              => "11",
        wr_s_tkeep_lock         => si_wr_tkeep_lock,

        lock_s_tvalid           => si_lock_tvalid,
        unlk_s_tvalid           => jump_tvalid,

        reg_m_tvalid            => si_tvalid,
        reg_m_tdata             => si_tdata
    );


    cpu_flags_inst : cpu_flags generic map (
        DATA_WIDTH              => 16
    ) port map (
        clk                     => clk,
        resetn                  => resetn,

        wr_s_tvalid             => flags_wr_tvalid,
        wr_s_tdata              => flags_wr_tdata,
        wr_s_tmask              => "11",

        lock_s_tvalid           => flags_lock_tvalid,
        unlk_s_tvalid           => jump_tvalid,

        reg_m_tvalid            => flags_tvalid,
        reg_m_tdata             => flags_tdata
    );


    fifo_instr_s_tvalid <= instr_s_tvalid;
    instr_s_tready <= fifo_instr_s_tready;
    fifo_instr_s_tdata(DECODED_INSTR_T_WIDTH+32-1 downto 32) <= decoded_instr_t_to_slv(instr_s_tdata);
    fifo_instr_s_tdata(31 downto 0) <= instr_s_tuser;

    axis_fifo_inst_0 : axis_fifo generic map (
        FIFO_DEPTH              => 16,
        FIFO_WIDTH              => DECODED_INSTR_T_WIDTH + 32,
        REGISTER_OUTPUT         => '1'
    ) port map (
        clk                     => clk,
        resetn                  => exec_resetn,

        fifo_s_tvalid           => fifo_instr_s_tvalid,
        fifo_s_tready           => fifo_instr_s_tready,
        fifo_s_tdata            => fifo_instr_s_tdata,

        fifo_m_tvalid           => fifo_instr_m_tvalid,
        fifo_m_tready           => fifo_instr_m_tready,
        fifo_m_tdata            => fifo_instr_m_tdata
    );


    instr_tvalid <= fifo_instr_m_tvalid;
    fifo_instr_m_tready <= instr_tready;
    instr_tdata <= slv_to_decoded_instr_t(fifo_instr_m_tdata(DECODED_INSTR_T_WIDTH+32-1 downto 32));
    instr_tuser <= fifo_instr_m_tdata(31 downto 0);

    register_reader_inst : register_reader port map (
        clk                     => clk,
        resetn                  => exec_resetn,

        instr_s_tvalid          => instr_tvalid,
        instr_s_tready          => instr_tready,
        instr_s_tdata           => instr_tdata,
        instr_s_tuser           => instr_tuser,

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


    ifeu_inst : ifeu port map (
        clk                     => clk,
        resetn                  => exec_resetn,

        jmp_lock_s_tvalid       => jmp_lock_tvalid,

        rr_s_tvalid             => rr_tvalid,
        rr_s_tready             => rr_tready,
        rr_s_tdata              => rr_tdata,
        rr_s_tuser              => rr_tuser,

        micro_m_tvalid          => micro_tvalid,
        micro_m_tready          => micro_tready,
        micro_m_tdata           => micro_tdata,

        bx_s_tdata              => bx_tdata,
        cx_s_tdata              => cx_tdata,
        dx_s_tdata              => dx_tdata,
        bp_s_tdata              => bp_tdata,
        sp_s_tdata              => sp_tdata,
        di_s_tdata              => di_tdata,
        si_s_tdata              => si_tdata,

        flags_s_tdata           => flags_tdata,

        ax_m_wr_tvalid          => ifeu_ax_wr_tvalid,
        ax_m_wr_tdata           => ifeu_ax_wr_tdata,
        ax_m_wr_tmask           => ifeu_ax_wr_tmask,
        bx_m_wr_tvalid          => ifeu_bx_wr_tvalid,
        bx_m_wr_tdata           => ifeu_bx_wr_tdata,
        bx_m_wr_tmask           => ifeu_bx_wr_tmask,
        cx_m_wr_tvalid          => ifeu_cx_wr_tvalid,
        cx_m_wr_tdata           => ifeu_cx_wr_tdata,
        cx_m_wr_tmask           => ifeu_cx_wr_tmask,
        cx_m_wr_tkeep_lock      => ifeu_cx_wr_tkeep_lock,
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

        jmp_lock_m_lock_tvalid  => jmp_lock_lock_tvalid
    );


    mexec_inst : mexec port map (
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

        si_m_wr_tkeep_lock      => mexec_si_wr_tkeep_lock,
        di_m_wr_tkeep_lock      => mexec_di_wr_tkeep_lock,

        jump_m_tvalid           => jump_tvalid,
        jump_m_tdata            => jump_tdata,

        jmp_lock_m_wr_tvalid    => jmp_lock_wr_tvalid,

        flags_m_wr_tvalid       => flags_wr_tvalid,
        flags_m_wr_tdata        => flags_wr_tdata,

        lsu_req_m_tvalid        => lsu_req_tvalid,
        lsu_req_m_tready        => lsu_req_tready,
        lsu_req_m_tcmd          => lsu_req_tcmd,
        lsu_req_m_twidth        => lsu_req_twidth,
        lsu_req_m_taddr         => lsu_req_taddr,
        lsu_req_m_tdata         => lsu_req_tdata,

        dbg_m_tvalid            => mexec_dbg_tvalid,
        dbg_m_tdata             => mexec_dbg_tdata
    );

    lsu_inst : lsu port map (
        clk                     => clk,
        resetn                  => resetn,

        lsu_req_s_tvalid        => lsu_req_tvalid,
        lsu_req_s_tready        => lsu_req_tready,
        lsu_req_s_tcmd          => lsu_req_tcmd,
        lsu_req_s_taddr         => lsu_req_taddr,
        lsu_req_s_twidth        => lsu_req_twidth,
        lsu_req_s_tdata         => lsu_req_tdata,

        dcache_s_tvalid         => dcache_tvalid,
        dcache_s_tdata          => dcache_tdata,

        mem_req_m_tvalid        => mem_req_m_tvalid,
        mem_req_m_tready        => mem_req_m_tready,
        mem_req_m_tdata         => mem_req_m_tdata,

        mem_rd_s_tvalid         => mem_rd_s_tvalid,
        mem_rd_s_tdata          => mem_rd_s_tdata,

        lsu_rd_m_tvalid         => lsu_rd_tvalid,
        lsu_rd_m_tready         => lsu_rd_tready,
        lsu_rd_m_tdata          => lsu_rd_tdata
    );

    dcache_inst : dcache port map (
        clk                     => clk,
        resetn                  => resetn,

        lsu_req_s_tvalid        => lsu_req_tvalid,
        lsu_req_s_tready        => lsu_req_tready,
        lsu_req_s_tcmd          => lsu_req_tcmd,
        lsu_req_s_taddr         => lsu_req_taddr,
        lsu_req_s_twidth        => lsu_req_twidth,
        lsu_req_s_tdata         => lsu_req_tdata,

        dcache_m_tvalid         => dcache_tvalid,
        dcache_m_tdata          => dcache_tdata
    );

    ax_wr_tvalid <= '1' when jump_tvalid = '0' and (ifeu_ax_wr_tvalid = '1' or mexec_ax_wr_tvalid = '1') else '0';
    bx_wr_tvalid <= '1' when jump_tvalid = '0' and (ifeu_bx_wr_tvalid = '1' or mexec_bx_wr_tvalid = '1') else '0';
    cx_wr_tvalid <= '1' when jump_tvalid = '0' and (ifeu_cx_wr_tvalid = '1' or mexec_cx_wr_tvalid = '1') else '0';
    dx_wr_tvalid <= '1' when jump_tvalid = '0' and (ifeu_dx_wr_tvalid = '1' or mexec_dx_wr_tvalid = '1') else '0';
    bp_wr_tvalid <= '1' when jump_tvalid = '0' and (ifeu_bp_wr_tvalid = '1' or mexec_bp_wr_tvalid = '1') else '0';
    sp_wr_tvalid <= '1' when jump_tvalid = '0' and (ifeu_sp_wr_tvalid = '1' or mexec_sp_wr_tvalid = '1') else '0';
    di_wr_tvalid <= '1' when jump_tvalid = '0' and (ifeu_di_wr_tvalid = '1' or mexec_di_wr_tvalid = '1') else '0';
    si_wr_tvalid <= '1' when jump_tvalid = '0' and (ifeu_si_wr_tvalid = '1' or mexec_si_wr_tvalid = '1') else '0';

    ds_wr_tvalid <= '1' when jump_tvalid = '0' and (ifeu_ds_wr_tvalid = '1' or mexec_ds_wr_tvalid = '1') else '0';
    ss_wr_tvalid <= '1' when jump_tvalid = '0' and (ifeu_ss_wr_tvalid = '1' or mexec_ss_wr_tvalid = '1') else '0';
    es_wr_tvalid <= '1' when jump_tvalid = '0' and (ifeu_es_wr_tvalid = '1' or mexec_es_wr_tvalid = '1') else '0';

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

    cx_wr_tkeep_lock <= '1' when ifeu_cx_wr_tkeep_lock = '1' else '0';
    di_wr_tkeep_lock <= '1' when mexec_di_wr_tkeep_lock = '1' else '0';
    si_wr_tkeep_lock <= '1' when mexec_si_wr_tkeep_lock = '1' else '0';

    req_m_tvalid <= jump_tvalid;
    req_m_tdata <= jump_tdata;

    --cs, ip, ds, es, ss, ax, bx, dx, cx, bp, di, si, sp, Flags8
    dbg_m_tvalid <= mexec_dbg_tvalid;
    dbg_m_tdata(14*16-1 downto 13*16) <= mexec_dbg_tdata(31 downto 16);
    dbg_m_tdata(13*16-1 downto 12*16) <= mexec_dbg_tdata(15 downto 0);
    dbg_m_tdata(12*16-1 downto 11*16) <= ds_tdata;
    dbg_m_tdata(11*16-1 downto 10*16) <= es_tdata;
    dbg_m_tdata(10*16-1 downto  9*16) <= ss_tdata;
    dbg_m_tdata( 9*16-1 downto  8*16) <= ax_tdata;
    dbg_m_tdata( 8*16-1 downto  7*16) <= bx_tdata;
    dbg_m_tdata( 7*16-1 downto  6*16) <= dx_tdata;
    dbg_m_tdata( 6*16-1 downto  5*16) <= cx_tdata;
    dbg_m_tdata( 5*16-1 downto  4*16) <= bp_tdata;
    dbg_m_tdata( 4*16-1 downto  3*16) <= di_tdata;
    dbg_m_tdata( 3*16-1 downto  2*16) <= si_tdata;
    dbg_m_tdata( 2*16-1 downto  1*16) <= sp_tdata;
    dbg_m_tdata( 1*16-1 downto  0*16) <= flags_tdata;

end architecture;
