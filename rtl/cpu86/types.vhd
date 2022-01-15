library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

package cpu86_types is

    type reg_t is (
        AX, DX, CX, BX, BP, SI, DI, SP, ES, CS, SS, DS, FL
    );

    attribute enum_encoding : string;
    attribute enum_encoding of reg_t : type is "0000 0001 0010 0011 0100 0101 0110 0111 1001 1010 1011 1100 1101";

    type ea_t is (
        BX_SI_DISP, BX_DI_DISP, BP_SI_DISP, BP_DI_DISP, SI_DISP, DI_DISP, BP_DISP, BX_DISP, DIRECT
    );

    type direction_t is (
        R2R, M2R, R2M, I2R, I2M, R2F, M2M
    );

    type op_t is (
        MOVU, ALU, DIVU, MULU, FEU, STACKU, LOOPU, SET_SEG, REP, STR, SET_FLAG, DBG, XCHG, SYS, LFP, ONEU, SHFU, BCDU, IO
    );

    type mem_data_src_t is (
        MEM_DATA_SRC_IMM, MEM_DATA_SRC_ALU, MEM_DATA_SRC_ONE, MEM_DATA_SRC_SHF, MEM_DATA_SRC_FIFO, MEM_DATA_SRC_IO
    );

    type io_data_src_t is (
        IO_DATA_SRC_IMM, IO_DATA_SRC_FIFO
    );

    type fl_action_t is (
        SET, CLR, TOGGLE
    );

    constant ALU_OP_ADD     : std_logic_vector (3 downto 0) := "0000";
    constant ALU_OP_SUB     : std_logic_vector (3 downto 0) := "0001";
    constant ALU_OP_OR      : std_logic_vector (3 downto 0) := "0010";
    constant ALU_OP_AND     : std_logic_vector (3 downto 0) := "0011";
    constant ALU_OP_ADC     : std_logic_vector (3 downto 0) := "0100";
    constant ALU_OP_SBB     : std_logic_vector (3 downto 0) := "0101";
    constant ALU_OP_XOR     : std_logic_vector (3 downto 0) := "0110";
    constant ALU_OP_CMP     : std_logic_vector (3 downto 0) := "0111";
    constant ALU_OP_INC     : std_logic_vector (3 downto 0) := "1000";
    constant ALU_OP_DEC     : std_logic_vector (3 downto 0) := "1001";
    constant ALU_OP_TST     : std_logic_vector (3 downto 0) := "1010";
    constant ALU_SF_ADD     : std_logic_vector (3 downto 0) := "1111";

    constant ONE_OP_NOT     : std_logic_vector (3 downto 0) := "0000";
    constant ONE_OP_NEG     : std_logic_vector (3 downto 0) := "0001";

    constant SHF_OP_ROL     : std_logic_vector (3 downto 0) := "0000";
    constant SHF_OP_ROR     : std_logic_vector (3 downto 0) := "0001";
    constant SHF_OP_RCL     : std_logic_vector (3 downto 0) := "0010";
    constant SHF_OP_RCR     : std_logic_vector (3 downto 0) := "0011";
    constant SHF_OP_SHL     : std_logic_vector (3 downto 0) := "0100";
    constant SHF_OP_SHR     : std_logic_vector (3 downto 0) := "0101";
    constant SHF_OP_SAR     : std_logic_vector (3 downto 0) := "0110";

    constant STACKU_POPM    : std_logic_vector (3 downto 0) := "0000";
    constant STACKU_POPR    : std_logic_vector (3 downto 0) := "0001";
    constant STACKU_POPA    : std_logic_vector (3 downto 0) := "0100";

    constant STACKU_PUSHR   : std_logic_vector (3 downto 0) := "1000";
    constant STACKU_PUSHI   : std_logic_vector (3 downto 0) := "1010";
    constant STACKU_PUSHM   : std_logic_vector (3 downto 0) := "1011";
    constant STACKU_PUSHA   : std_logic_vector (3 downto 0) := "1100";

    constant LOOP_OP        : std_logic_vector (3 downto 0) := "0000";
    constant LOOP_OP_E      : std_logic_vector (3 downto 0) := "0001";
    constant LOOP_OP_NE     : std_logic_vector (3 downto 0) := "0010";

    constant REPZ_OP        : std_logic_vector (3 downto 0) := "0000";
    constant REPNZ_OP       : std_logic_vector (3 downto 0) := "0001";

    constant LFP_LDS        : std_logic_vector (3 downto 0) := "0000";
    constant LFP_LES        : std_logic_vector (3 downto 0) := "0001";

    constant MOVS_OP        : std_logic_vector (3 downto 0) := "0000";
    constant STOS_OP        : std_logic_vector (3 downto 0) := "0001";
    constant LODS_OP        : std_logic_vector (3 downto 0) := "0010";
    constant CMPS_OP        : std_logic_vector (3 downto 0) := "1000";
    constant SCAS_OP        : std_logic_vector (3 downto 0) := "1001";

    constant IMUL_AXDX      : std_logic_vector (3 downto 0) := "0000";
    constant IMUL_RR        : std_logic_vector (3 downto 0) := "0001";
    constant MUL_AXDX       : std_logic_vector (3 downto 0) := "0010";
    constant MUL_RR         : std_logic_vector (3 downto 0) := "0011";

    constant SYS_HLT_OP     : std_logic_vector (3 downto 0) := "0000";
    constant SYS_ESC_OP     : std_logic_vector (3 downto 0) := "0001";
    constant SYS_DBG_OP     : std_logic_vector (3 downto 0) := "0010";
    constant SYS_IRET_OP    : std_logic_vector (3 downto 0) := "0101";
    constant SYS_INT_OP     : std_logic_vector (3 downto 0) := "1000";
    constant SYS_INTO_OP    : std_logic_vector (3 downto 0) := "1001";
    constant SYS_INT3_OP    : std_logic_vector (3 downto 0) := "1010";
    constant SYS_DIV_INT_OP : std_logic_vector (3 downto 0) := "1111";

    constant FEU_CBW        : std_logic_vector (3 downto 0) := "0000";
    constant FEU_CWD        : std_logic_vector (3 downto 0) := "0001";
    constant FEU_LEA        : std_logic_vector (3 downto 0) := "0010";

    constant BCDU_AAA       : std_logic_vector (3 downto 0) := "0000";
    constant BCDU_AAD       : std_logic_vector (3 downto 0) := "0001";
    constant BCDU_AAS       : std_logic_vector (3 downto 0) := "0011";
    constant BCDU_DAA       : std_logic_vector (3 downto 0) := "0100";
    constant BCDU_DAS       : std_logic_vector (3 downto 0) := "0101";

    constant DIVU_AAM       : std_logic_vector (3 downto 0) := "0000";
    constant DIVU_DIV       : std_logic_vector (3 downto 0) := "0001";
    constant DIVU_IDIV      : std_logic_vector (3 downto 0) := "0010";

    constant IO_IN_IMM      : std_logic_vector (3 downto 0) := "0000";
    constant IO_IN_DX       : std_logic_vector (3 downto 0) := "0001";
    constant IO_OUT_IMM     : std_logic_vector (3 downto 0) := "1000";
    constant IO_OUT_DX      : std_logic_vector (3 downto 0) := "1001";

    constant IO_INS_IMM     : std_logic_vector (3 downto 0) := "0100";
    constant IO_INS_DX      : std_logic_vector (3 downto 0) := "0101";
    constant IO_OUTS_IMM    : std_logic_vector (3 downto 0) := "1100";
    constant IO_OUTS_DX     : std_logic_vector (3 downto 0) := "1101";

    constant FLAG_15        : natural := 15;
    constant FLAG_14        : natural := 14;
    constant FLAG_13        : natural := 13;
    constant FLAG_12        : natural := 12;
    constant FLAG_OF        : natural := 11;
    constant FLAG_DF        : natural := 10;
    constant FLAG_IF        : natural := 9;
    constant FLAG_TF        : natural := 8;
    constant FLAG_SF        : natural := 7;
    constant FLAG_ZF        : natural := 6;
    constant FLAG_05        : natural := 5;
    constant FLAG_AF        : natural := 4;
    constant FLAG_03        : natural := 3;
    constant FLAG_PF        : natural := 2;
    constant FLAG_01        : natural := 1;
    constant FLAG_CF        : natural := 0;

    constant DECODED_INSTR_T_WIDTH : integer := 86;

    type packed_decoded_instr_t is record
        wait_ax     : std_logic_vector(85 downto 85);
        wait_bx     : std_logic_vector(84 downto 84);
        wait_cx     : std_logic_vector(83 downto 83);
        wait_dx     : std_logic_vector(82 downto 82);
        wait_bp     : std_logic_vector(81 downto 81);
        wait_si     : std_logic_vector(80 downto 80);
        wait_di     : std_logic_vector(79 downto 79);
        wait_sp     : std_logic_vector(78 downto 78);
        wait_ds     : std_logic_vector(77 downto 77);
        wait_es     : std_logic_vector(76 downto 76);
        wait_ss     : std_logic_vector(75 downto 75);
        wait_fl     : std_logic_vector(74 downto 74);
        lock_fl     : std_logic_vector(73 downto 73);
        lock_sp     : std_logic_vector(72 downto 72);
        lock_sreg   : std_logic_vector(71 downto 71);
        lock_dreg   : std_logic_vector(70 downto 70);
        lock_ax     : std_logic_vector(69 downto 69);
        lock_si     : std_logic_vector(68 downto 68);
        lock_di     : std_logic_vector(67 downto 67);
        lock_ds     : std_logic_vector(66 downto 66);
        lock_es     : std_logic_vector(65 downto 65);
        lock_all    : std_logic_vector(64 downto 64);
        fl          : std_logic_vector(63 downto 62);
        op          : std_logic_vector(61 downto 57);
        code        : std_logic_vector(56 downto 53);
        w           : std_logic_vector(52 downto 52);
        dir         : std_logic_vector(51 downto 48);
        ea          : std_logic_vector(47 downto 44);
        dreg        : std_logic_vector(43 downto 40);
        dmask       : std_logic_vector(39 downto 38);
        sreg        : std_logic_vector(37 downto 34);
        smask       : std_logic_vector(33 downto 32);
        data        : std_logic_vector(31 downto 16);
        disp        : std_logic_vector(15 downto 0);
    end record;

    type decoded_instr_t is record
        wait_ax     : std_logic;
        wait_bx     : std_logic;
        wait_cx     : std_logic;
        wait_dx     : std_logic;
        wait_bp     : std_logic;
        wait_si     : std_logic;
        wait_di     : std_logic;
        wait_sp     : std_logic;
        wait_ds     : std_logic;
        wait_es     : std_logic;
        wait_ss     : std_logic;
        wait_fl     : std_logic;
        lock_fl     : std_logic;
        lock_sreg   : std_logic;
        lock_dreg   : std_logic;
        lock_ax     : std_logic;
        lock_sp     : std_logic;
        lock_si     : std_logic;
        lock_di     : std_logic;
        lock_ds     : std_logic;
        lock_es     : std_logic;
        lock_all    : std_logic;
        fl          : fl_action_t;
        op          : op_t;
        code        : std_logic_vector(3 downto 0);
        w           : std_logic;
        dir         : direction_t;
        ea          : ea_t;
        dreg        : reg_t;
        dmask       : std_logic_vector(1 downto 0);
        sreg        : reg_t;
        smask       : std_logic_vector(1 downto 0);
        data        : std_logic_vector(15 downto 0);
        disp        : std_logic_vector(15 downto 0);
    end record;

    subtype user_t is std_logic_vector(47 downto 0);
    subtype USER_T_IP is natural range 47 downto 32;
    subtype USER_T_CS is natural range 31 downto 16;
    subtype USER_T_IP_NEXT is natural range 15 downto 0;

    subtype div_intr_t is std_logic_vector(63 downto 0);
    subtype DIV_INTR_T_SS is natural range 63 downto 48;
    subtype DIV_INTR_T_IP is natural range 47 downto 32;
    subtype DIV_INTR_T_CS is natural range 31 downto 16;
    subtype DIV_INTR_T_IP_NEXT is natural range 15 downto 0;

    type rr_instr_t is record
        es_seg_val  : std_logic_vector(15 downto 0);
        seg_val     : std_logic_vector(15 downto 0);
        ss_seg_val  : std_logic_vector(15 downto 0);
        ea_val      : std_logic_vector(15 downto 0);
        dreg_val    : std_logic_vector(15 downto 0);
        sreg_val    : std_logic_vector(15 downto 0);
        op          : op_t;
        code        : std_logic_vector(3 downto 0);
        w           : std_logic;
        fl          : fl_action_t;
        dir         : direction_t;
        ea          : ea_t;
        dreg        : reg_t;
        dmask       : std_logic_vector(1 downto 0);
        sreg        : reg_t;
        data        : std_logic_vector(15 downto 0);
        disp        : std_logic_vector(15 downto 0);
    end record;

    constant MICRO_OP_CMD_WIDTH : natural := 11;
    constant MICRO_OP_CMD_MEM : natural := 0;
    constant MICRO_OP_CMD_ALU : natural := 1;
    constant MICRO_OP_CMD_JMP : natural := 2;
    constant MICRO_OP_CMD_FLG : natural := 3;
    constant MICRO_OP_CMD_MUL : natural := 4;
    constant MICRO_OP_CMD_DBG : natural := 5;
    constant MICRO_OP_CMD_ONE : natural := 6;
    constant MICRO_OP_CMD_BCD : natural := 7;
    constant MICRO_OP_CMD_SHF : natural := 8;
    constant MICRO_OP_CMD_DIV : natural := 9;
    constant MICRO_OP_CMD_IO  : natural := 10;

    type micro_op_src_a_t is (sreg_val, dreg_val, mem_val, ea_val, imm);
    type micro_op_src_b_t is (sreg_val, dreg_val, mem_val, ea_val, imm);
    type micro_op_jmp_cond_t is (j_always, j_never, cx_ne_0, cx_ne_0_and_zf, cx_ne_0_and_nzf);

    type micro_op_t is record
        cmd             : std_logic_vector(MICRO_OP_CMD_WIDTH-1 downto 0);
        unlk_fl         : std_logic;
        read_fifo       : std_logic;
        --wr              : std_logic;
        alu_code        : std_logic_vector(3 downto 0);
        alu_w           : std_logic;
        alu_dreg        : reg_t;
        alu_dmask       : std_logic_vector(1 downto 0);
        alu_a_buf       : std_logic;
        alu_a_mem       : std_logic;
        alu_a_val       : std_logic_vector(15 downto 0);
        alu_b_mem       : std_logic;
        alu_b_val       : std_logic_vector(15 downto 0);
        alu_wb          : std_logic;

        mul_code        : std_logic_vector(3 downto 0);
        mul_w           : std_logic;
        mul_dreg        : reg_t;
        mul_dmask       : std_logic_vector(1 downto 0);
        mul_a_val       : std_logic_vector(15 downto 0);
        mul_b_val       : std_logic_vector(15 downto 0);

        div_code        : std_logic_vector(3 downto 0);
        div_w           : std_logic;
        div_dreg        : reg_t;
        div_a_val       : std_logic_vector(31 downto 0);
        div_b_val       : std_logic_vector(15 downto 0);
        div_ss_val      : std_logic_vector(15 downto 0);
        div_cs_val      : std_logic_vector(15 downto 0);
        div_ip_val      : std_logic_vector(15 downto 0);
        div_ip_next_val : std_logic_vector(15 downto 0);

        one_code        : std_logic_vector(3 downto 0);
        one_w           : std_logic;
        one_dreg        : reg_t;
        one_dmask       : std_logic_vector(1 downto 0);
        one_sval        : std_logic_vector(15 downto 0);
        one_ival        : std_logic_vector(15 downto 0);
        one_wb          : std_logic;

        shf_code        : std_logic_vector(3 downto 0);
        shf_w           : std_logic;
        shf_dreg        : reg_t;
        shf_dmask       : std_logic_vector(1 downto 0);
        shf_sval        : std_logic_vector(15 downto 0);
        shf_ival        : std_logic_vector(15 downto 0);
        shf_wb          : std_logic;

        bcd_code        : std_logic_vector(3 downto 0);
        bcd_sval        : std_logic_vector(15 downto 0);

        jump_cond       : micro_op_jmp_cond_t;
        jump_imm        : std_logic;
        jump_cs_mem     : std_logic;
        jump_cs         : std_logic_vector(15 downto 0);
        jump_ip_mem     : std_logic;
        jump_ip         : std_logic_vector(15 downto 0);

        mem_cmd         : std_logic;
        mem_width       : std_logic;
        mem_seg         : std_logic_vector(15 downto 0);
        mem_addr        : std_logic_vector(15 downto 0);
        mem_data_src    : mem_data_src_t;
        mem_data        : std_logic_vector(15 downto 0);

        io_cmd          : std_logic;
        io_w            : std_logic;
        io_port         : std_logic_vector(15 downto 0);
        io_data         : std_logic_vector(15 downto 0);
        io_data_src     : io_data_src_t;
        io_wb           : std_logic;

        flg_no          : std_logic_vector(3 downto 0);
        fl              : fl_action_t;
        sp_inc          : std_logic;
        sp_inc_data     : std_logic_vector(15 downto 0);
        sp_keep_lock    : std_logic;
        si_inc          : std_logic;
        si_inc_data     : std_logic_vector(15 downto 0);
        si_keep_lock    : std_logic;
        di_inc          : std_logic;
        di_inc_data     : std_logic_vector(15 downto 0);
        di_keep_lock    : std_logic;
        dbg_cs          : std_logic_vector(15 downto 0);
        dbg_ip          : std_logic_vector(15 downto 0);
    end record;

    type alu_req_t is record
        code            : std_logic_vector(3 downto 0);
        w               : std_logic;
        wb              : std_logic;
        dreg            : reg_t;
        dmask           : std_logic_vector(1 downto 0);
        upd_fl          : std_logic;
        aval            : std_logic_vector(15 downto 0);
        bval            : std_logic_vector(15 downto 0);
    end record;

    type alu_res_t is record
        code            : std_logic_vector(3 downto 0);
        w               : std_logic;
        wb              : std_logic;
        dreg            : reg_t;
        dmask           : std_logic_vector(1 downto 0);
        upd_fl          : std_logic;
        aval            : std_logic_vector(15 downto 0);
        bval            : std_logic_vector(15 downto 0);
        dval            : std_logic_vector(15 downto 0); --dest
        rval            : std_logic_vector(16 downto 0); --result
    end record;

    type alu_flg_t is record
        code            : std_logic_vector(3 downto 0);
        dreg            : reg_t;
        dmask           : std_logic_vector(1 downto 0);
    end record;

    type mul_req_t is record
        code            : std_logic_vector(3 downto 0);
        w               : std_logic;
        wb              : std_logic;
        dreg            : reg_t;
        dmask           : std_logic_vector(1 downto 0);
        aval            : std_logic_vector(15 downto 0);
        bval            : std_logic_vector(15 downto 0);
    end record;

    type mul_res_t is record
        code            : std_logic_vector(3 downto 0);
        w               : std_logic;
        dreg            : reg_t;
        dmask           : std_logic_vector(1 downto 0);
        aval            : std_logic_vector(15 downto 0);
        bval            : std_logic_vector(15 downto 0);
        dval            : std_logic_vector(31 downto 0); --dest
    end record;

    type div_req_t is record
        code            : std_logic_vector(3 downto 0);
        w               : std_logic;
        wb              : std_logic;
        dreg            : reg_t;
        nval            : std_logic_vector(31 downto 0);
        dval            : std_logic_vector(15 downto 0);
        ss_val          : std_logic_vector(15 downto 0);
        cs_val          : std_logic_vector(15 downto 0);
        ip_val          : std_logic_vector(15 downto 0);
        ip_next_val     : std_logic_vector(15 downto 0);
    end record;

    type div_res_t is record
        code            : std_logic_vector(3 downto 0);
        w               : std_logic;
        dreg            : reg_t;
        qval            : std_logic_vector(15 downto 0); --quotient
        rval            : std_logic_vector(15 downto 0); --remainder
        overflow        : std_logic;
        ss_val          : std_logic_vector(15 downto 0);
        cs_val          : std_logic_vector(15 downto 0);
        ip_val          : std_logic_vector(15 downto 0);
        ip_next_val     : std_logic_vector(15 downto 0);
    end record;

    type one_req_t is record
        code            : std_logic_vector(3 downto 0);
        w               : std_logic;
        wb              : std_logic;
        dreg            : reg_t;
        dmask           : std_logic_vector(1 downto 0);
        sval            : std_logic_vector(15 downto 0);
        ival            : std_logic_vector(15 downto 0);
    end record;

    type one_res_t is record
        code            : std_logic_vector(3 downto 0);
        wb              : std_logic;
        w               : std_logic;
        dreg            : reg_t;
        dmask           : std_logic_vector(1 downto 0);
        dval            : std_logic_vector(15 downto 0);
    end record;

    type shf_req_t is record
        code            : std_logic_vector(3 downto 0);
        w               : std_logic;
        wb              : std_logic;
        dreg            : reg_t;
        dmask           : std_logic_vector(1 downto 0);
        sval            : std_logic_vector(15 downto 0);
        ival            : std_logic_vector(15 downto 0);
    end record;

    type shf_res_t is record
        code            : std_logic_vector(3 downto 0);
        wb              : std_logic;
        w               : std_logic;
        dreg            : reg_t;
        dmask           : std_logic_vector(1 downto 0);
        dval            : std_logic_vector(15 downto 0);
    end record;

    type bcd_req_t is record
        code            : std_logic_vector(3 downto 0);
        sval            : std_logic_vector(15 downto 0);
    end record;

    type bcd_res_t is record
        code            : std_logic_vector(3 downto 0);
        dmask           : std_logic_vector(1 downto 0);
        dval            : std_logic_vector(15 downto 0);
    end record;

    function decoded_instr_t_to_slv (decoded_instr : decoded_instr_t) return std_logic_vector;
    function slv_to_decoded_instr_t (v : std_logic_vector) return decoded_instr_t;

end package;

package body cpu86_types is

    function decoded_instr_t_to_slv (decoded_instr : decoded_instr_t) return std_logic_vector is
        variable p : packed_decoded_instr_t;
        variable v : std_logic_vector(DECODED_INSTR_T_WIDTH-1 downto 0);
    begin

        p.wait_ax   := (85 => decoded_instr.wait_ax);
        p.wait_bx   := (84 => decoded_instr.wait_bx);
        p.wait_cx   := (83 => decoded_instr.wait_cx);
        p.wait_dx   := (82 => decoded_instr.wait_dx);
        p.wait_bp   := (81 => decoded_instr.wait_bp);
        p.wait_si   := (80 => decoded_instr.wait_si);
        p.wait_di   := (79 => decoded_instr.wait_di);
        p.wait_sp   := (78 => decoded_instr.wait_sp);
        p.wait_ds   := (77 => decoded_instr.wait_ds);
        p.wait_es   := (76 => decoded_instr.wait_es);
        p.wait_ss   := (75 => decoded_instr.wait_ss);
        p.wait_fl   := (74 => decoded_instr.wait_fl);

        p.lock_fl   := (73 => decoded_instr.lock_fl);
        p.lock_sp   := (72 => decoded_instr.lock_sp);
        p.lock_sreg := (71 => decoded_instr.lock_sreg);
        p.lock_dreg := (70 => decoded_instr.lock_dreg);
        p.lock_ax   := (69 => decoded_instr.lock_ax);
        p.lock_si   := (68 => decoded_instr.lock_si);
        p.lock_di   := (67 => decoded_instr.lock_di);
        p.lock_ds   := (66 => decoded_instr.lock_ds);
        p.lock_es   := (65 => decoded_instr.lock_es);
        p.lock_all  := (64 => decoded_instr.lock_all);
        p.fl        := std_logic_vector(to_unsigned(fl_action_t'pos(decoded_instr.fl), p.fl'length));
        p.op        := std_logic_vector(to_unsigned(op_t'pos(decoded_instr.op), p.op'length));
        p.code      := decoded_instr.code;
        p.w         := (52 => decoded_instr.w);
        p.dir       := std_logic_vector(to_unsigned(direction_t'pos(decoded_instr.dir), p.dir'length));
        p.ea        := std_logic_vector(to_unsigned(ea_t'pos(decoded_instr.ea), p.ea'length));
        p.dreg      := std_logic_vector(to_unsigned(reg_t'pos(decoded_instr.dreg), p.dreg'length));
        p.dmask     := decoded_instr.dmask;
        p.sreg      := std_logic_vector(to_unsigned(reg_t'pos(decoded_instr.sreg), p.sreg'length));
        p.smask     := decoded_instr.smask;
        p.data      := decoded_instr.data;
        p.disp      := decoded_instr.disp;

        v := p.wait_ax & p.wait_bx & p.wait_cx & p.wait_dx & p.wait_bp & p.wait_si & p.wait_di & p.wait_sp & p.wait_ds & p.wait_es & p.wait_ss & p.wait_fl &
            p.lock_fl & p.lock_sp & p.lock_sreg & p.lock_dreg & p.lock_ax & p.lock_si & p.lock_di & p.lock_ds & p.lock_es & p.lock_all &
            p.fl & p.op & p.code & p.w & p.dir & p.ea & p.dreg & p.dmask & p.sreg & p.smask & p.data & p.disp;

        return v;

    end function;

    function slv_to_decoded_instr_t (v : std_logic_vector) return decoded_instr_t is
        variable t : std_logic_vector(DECODED_INSTR_T_WIDTH-1 downto 0);
        variable p : packed_decoded_instr_t;
        variable d : decoded_instr_t;
    begin
        t := v;
        --(p.op,  p.code, p.w, p.dir, p.ea, p.dreg, p.dmask, p.sreg, p.smask, p.data, p.disp) := v;

        p.wait_ax   := t(p.wait_ax'range);
        p.wait_bx   := t(p.wait_bx'range);
        p.wait_cx   := t(p.wait_cx'range);
        p.wait_dx   := t(p.wait_dx'range);
        p.wait_bp   := t(p.wait_bp'range);
        p.wait_si   := t(p.wait_si'range);
        p.wait_di   := t(p.wait_di'range);
        p.wait_sp   := t(p.wait_sp'range);
        p.wait_ds   := t(p.wait_ds'range);
        p.wait_es   := t(p.wait_es'range);
        p.wait_ss   := t(p.wait_ss'range);
        p.wait_fl   := t(p.wait_fl'range);

        p.lock_fl   := t(p.lock_fl'range);
        p.lock_sp   := t(p.lock_sp'range);
        p.lock_sreg := t(p.lock_sreg'range);
        p.lock_dreg := t(p.lock_dreg'range);
        p.lock_ax   := t(p.lock_ax'range);
        p.lock_si   := t(p.lock_si'range);
        p.lock_di   := t(p.lock_di'range);
        p.lock_ds   := t(p.lock_ds'range);
        p.lock_es   := t(p.lock_es'range);
        p.lock_all  := t(p.lock_all'range);
        p.fl        := t(p.fl'range);
        p.op        := t(p.op'range);
        p.code      := t(p.code'range);
        p.w         := t(p.w'range);
        p.dir       := t(p.dir'range);
        p.ea        := t(p.ea'range);
        p.dreg      := t(p.dreg'range);
        p.dmask     := t(p.dmask'range);
        p.sreg      := t(p.sreg'range);
        p.smask     := t(p.smask'range);
        p.data      := t(p.data'range);
        p.disp      := t(p.disp'range);

        d.wait_ax   := p.wait_ax(85);
        d.wait_bx   := p.wait_bx(84);
        d.wait_cx   := p.wait_cx(83);
        d.wait_dx   := p.wait_dx(82);
        d.wait_bp   := p.wait_bp(81);
        d.wait_si   := p.wait_si(80);
        d.wait_di   := p.wait_di(79);
        d.wait_sp   := p.wait_sp(78);
        d.wait_ds   := p.wait_ds(77);
        d.wait_es   := p.wait_es(76);
        d.wait_ss   := p.wait_ss(75);
        d.wait_fl   := p.wait_fl(74);

        d.lock_fl   := p.lock_fl(73);
        d.lock_sp   := p.lock_sp(72);
        d.lock_sreg := p.lock_sreg(71);
        d.lock_dreg := p.lock_dreg(70);
        d.lock_ax   := p.lock_ax(69);
        d.lock_si   := p.lock_si(68);
        d.lock_di   := p.lock_di(67);
        d.lock_ds   := p.lock_ds(66);
        d.lock_es   := p.lock_es(65);
        d.lock_all  := p.lock_all(64);
        d.fl        := fl_action_t'val(to_integer(unsigned(p.fl)));
        d.op        := op_t'val(to_integer(unsigned(p.op)));
        d.code      := p.code;
        d.w         := p.w(52);
        d.dir       := direction_t'val(to_integer(unsigned(p.dir)));
        d.ea        := ea_t'val(to_integer(unsigned(p.ea)));
        d.dreg      := reg_t'val(to_integer(unsigned(p.dreg)));
        d.dmask     := p.dmask;
        d.sreg      := reg_t'val(to_integer(unsigned(p.sreg)));
        d.smask     := p.smask;
        d.data      := p.data;
        d.disp      := p.disp;

        return d;

    end;

end package body;
