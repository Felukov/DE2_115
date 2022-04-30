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
        BX_SI_DISP, BX_DI_DISP, BP_SI_DISP, BP_DI_DISP, SI_DISP, DI_DISP, BP_DISP, BX_DISP, DIRECT, XLAT
    );

    attribute enum_encoding of ea_t : type is "0000 0001 0010 0011 0100 0101 0110 0111 1001 1010";

    type direction_t is (
        R2R, M2R, R2M, I2R, I2M, R2F, M2M
    );

    attribute enum_encoding of direction_t : type is "000 001 010 011 100 101 110";

    type op_t is (
        MOVU,     -- 00000
        ALU,      -- 00001
        DIVU,     -- 00010
        MULU,     -- 00011
        FEU,      -- 00100
        STACKU,   -- 00101
        LOOPU,    -- 00110
        JMPU,     -- 00111
        BRANCH,   -- 01000
        JCALL,    -- 01001
        RET,      -- 01010
        SET_SEG,  -- 01011
        REP,      -- 01100
        STR,      -- 01101
        SET_FLAG, -- 01110
        DBG,      -- 01111
        XCHG,     -- 10000
        SYS,      -- 10001
        LFP,      -- 10010
        ONEU,     -- 10011
        SHFU,     -- 10100
        BCDU,     -- 10101
        IO        -- 10110
    );

    attribute enum_encoding of op_t : type is "00000 00001 00010 00011 00100 00101 00110 00111 01000 01001 01010 01011 01100 01101 01110 01111 10000 10001 10010 10011 10100 10101 10110";

    type mem_data_src_t is (
        MEM_DATA_SRC_IMM, MEM_DATA_SRC_ALU, MEM_DATA_SRC_ONE, MEM_DATA_SRC_SHF, MEM_DATA_SRC_FIFO, MEM_DATA_SRC_IO
    );

    type io_data_src_t is (
        IO_DATA_SRC_IMM, IO_DATA_SRC_FIFO
    );

    type fl_action_t is (
        SET, CLR, TOGGLE
    );
    attribute enum_encoding of fl_action_t : type is "00 01 10";

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
    constant STACKU_ENTER   : std_logic_vector (3 downto 0) := "1101";
    constant STACKU_LEAVE   : std_logic_vector (3 downto 0) := "1110";

    constant LOOP_OP        : std_logic_vector (3 downto 0) := "0000";
    constant LOOP_OP_E      : std_logic_vector (3 downto 0) := "0001";
    constant LOOP_OP_NE     : std_logic_vector (3 downto 0) := "0010";
    constant LOOP_JCXZ      : std_logic_vector (3 downto 0) := "0011";

    constant REPZ_OP        : std_logic_vector (3 downto 0) := "0000";
    constant REPNZ_OP       : std_logic_vector (3 downto 0) := "0001";

    constant LFP_LDS        : std_logic_vector (3 downto 0) := "0000";
    constant LFP_LES        : std_logic_vector (3 downto 0) := "0001";
    constant MISC_BOUND     : std_logic_vector (3 downto 0) := "0010";
    constant MISC_XLAT      : std_logic_vector (3 downto 0) := "0011";

    constant MOVS_OP        : std_logic_vector (3 downto 0) := "0000";
    constant STOS_OP        : std_logic_vector (3 downto 0) := "0001";
    constant LODS_OP        : std_logic_vector (3 downto 0) := "0010";
    constant CMPS_OP        : std_logic_vector (3 downto 0) := "0011";
    constant SCAS_OP        : std_logic_vector (3 downto 0) := "0100";
    constant OUTS_OP        : std_logic_vector (3 downto 0) := "1000";
    constant OUT_OP         : std_logic_vector (3 downto 0) := "1001";
    constant INS_OP         : std_logic_vector (3 downto 0) := "1010";
    constant IN_OP          : std_logic_vector (3 downto 0) := "1011";

    constant IMUL_AXDX      : std_logic_vector (3 downto 0) := "0000";
    constant IMUL_RR        : std_logic_vector (3 downto 0) := "0001";
    constant MUL_AXDX       : std_logic_vector (3 downto 0) := "0010";
    constant MUL_RR         : std_logic_vector (3 downto 0) := "0011";

    constant SYS_HLT_OP     : std_logic_vector (3 downto 0) := "0000";
    constant SYS_ESC_OP     : std_logic_vector (3 downto 0) := "0001";
    constant SYS_DBG_OP     : std_logic_vector (3 downto 0) := "0010";
    constant SYS_IRET_OP    : std_logic_vector (3 downto 0) := "0101";
    constant SYS_INT_INT_OP : std_logic_vector (3 downto 0) := "1000";
    constant SYS_EXT_INT_OP : std_logic_vector (3 downto 0) := "1001";
    constant SYS_BND_INT_OP : std_logic_vector (3 downto 0) := "1110";
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

    constant BRA_JO         : std_logic_vector (3 downto 0) := x"0";
    constant BRA_JNO        : std_logic_vector (3 downto 0) := x"1";
    constant BRA_JB         : std_logic_vector (3 downto 0) := x"2";
    constant BRA_JAE        : std_logic_vector (3 downto 0) := x"3";
    constant BRA_JE         : std_logic_vector (3 downto 0) := x"4";
    constant BRA_JNE        : std_logic_vector (3 downto 0) := x"5";
    constant BRA_JBE        : std_logic_vector (3 downto 0) := x"6";
    constant BRA_JA         : std_logic_vector (3 downto 0) := x"7";
    constant BRA_JS         : std_logic_vector (3 downto 0) := x"8";
    constant BRA_JNS        : std_logic_vector (3 downto 0) := x"9";
    constant BRA_JP         : std_logic_vector (3 downto 0) := x"A";
    constant BRA_JNP        : std_logic_vector (3 downto 0) := x"B";
    constant BRA_JL         : std_logic_vector (3 downto 0) := x"C";
    constant BRA_JGE        : std_logic_vector (3 downto 0) := x"D";
    constant BRA_JLE        : std_logic_vector (3 downto 0) := x"E";
    constant BRA_JG         : std_logic_vector (3 downto 0) := x"F";

    -- JMP bits encoding
    -- 3          - '0' : fast instruction, '1' : slow instruction
    -- 2 downto 0 - instruction code
    constant JMP_REL8       : std_logic_vector (3 downto 0) := "0001";
    constant JMP_REL16      : std_logic_vector (3 downto 0) := "0010";
    constant JMP_PTR16_16   : std_logic_vector (3 downto 0) := "0100";
    constant JMP_RM16       : std_logic_vector (3 downto 0) := "1000";
    constant JMP_M16_16     : std_logic_vector (3 downto 0) := "1001";

    -- CALL bits encoding
    -- 3          - '0' : fast instruction, '1' : slow instruction
    -- 2 downto 0 - instruction code
    constant CALL_REL16     : std_logic_vector (3 downto 0) := "0000";
    constant CALL_PTR16_16  : std_logic_vector (3 downto 0) := "0100";
    constant CALL_RM16      : std_logic_vector (3 downto 0) := "1010";
    constant CALL_M16_16    : std_logic_vector (3 downto 0) := "1100";

    constant RET_NEAR       : std_logic_vector (3 downto 0) := x"0";
    constant RET_FAR        : std_logic_vector (3 downto 0) := x"1";
    constant RET_NEAR_IMM16 : std_logic_vector (3 downto 0) := x"2";
    constant RET_FAR_IMM16  : std_logic_vector (3 downto 0) := x"3";

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

    constant DECODED_INSTR_T_WIDTH  : integer := 128;
    constant USER_T_WIDTH           : integer := 48;

    subtype slv_decoded_instr_t is std_logic_vector(DECODED_INSTR_T_WIDTH - 1 downto 0);

    type decoded_instr_t is record
        op              : op_t;
        code            : std_logic_vector(3 downto 0);
        w               : std_logic;
        dir             : direction_t;
        ea              : ea_t;
        dreg            : reg_t;
        dmask           : std_logic_vector(1 downto 0);
        sreg            : reg_t;
        smask           : std_logic_vector(1 downto 0);
        data            : std_logic_vector(15 downto 0);
        disp            : std_logic_vector(15 downto 0);
        fl              : fl_action_t;
        imm8            : std_logic_vector(7 downto 0);
        bpu_taken       : std_logic;
        bpu_first       : std_logic;
        bpu_taken_cs    : std_logic_vector(15 downto 0);
        bpu_taken_ip    : std_logic_vector(15 downto 0);
        wait_ax         : std_logic;
        wait_bx         : std_logic;
        wait_cx         : std_logic;
        wait_dx         : std_logic;
        wait_bp         : std_logic;
        wait_si         : std_logic;
        wait_di         : std_logic;
        wait_sp         : std_logic;
        wait_ds         : std_logic;
        wait_es         : std_logic;
        wait_ss         : std_logic;
        wait_fl         : std_logic;
        lock_fl         : std_logic;
        lock_sreg       : std_logic;
        lock_dreg       : std_logic;
        lock_ax         : std_logic;
        lock_sp         : std_logic;
        lock_si         : std_logic;
        lock_di         : std_logic;
        lock_ds         : std_logic;
        lock_es         : std_logic;
        lock_all        : std_logic;
    end record;

    subtype user_t         is std_logic_vector(47 downto 0);
    subtype USER_T_IP      is natural range 47 downto 32;
    subtype USER_T_CS      is natural range 31 downto 16;
    subtype USER_T_IP_NEXT is natural range 15 downto 0;

    subtype intr_t         is std_logic_vector(63 downto 0);
    subtype INTR_T_SS      is natural range 63 downto 48;
    subtype INTR_T_IP      is natural range 47 downto 32;
    subtype INTR_T_CS      is natural range 31 downto 16;
    subtype INTR_T_IP_NEXT is natural range 15 downto 0;

    type rr_instr_t is record
        op              : op_t;
        code            : std_logic_vector(3 downto 0);
        w               : std_logic;
        fl              : fl_action_t;
        dir             : direction_t;
        ea              : ea_t;
        dreg            : reg_t;
        dmask           : std_logic_vector(1 downto 0);
        sreg            : reg_t;
        data            : std_logic_vector(15 downto 0);
        disp            : std_logic_vector(15 downto 0);
        level           : natural range 0 to 63;
        fast_instr      : std_logic;

        bpu_first       : std_logic;
        bpu_taken       : std_logic;
        bpu_bypass      : std_logic;
        bpu_taken_cs    : std_logic_vector(15 downto 0);
        bpu_taken_ip    : std_logic_vector(15 downto 0);

        ax_tdata        : std_logic_vector(15 downto 0);
        bx_tdata        : std_logic_vector(15 downto 0);
        cx_tdata        : std_logic_vector(15 downto 0);
        dx_tdata        : std_logic_vector(15 downto 0);
        bp_tdata        : std_logic_vector(15 downto 0);
        di_tdata        : std_logic_vector(15 downto 0);
        si_tdata        : std_logic_vector(15 downto 0);
        fl_tdata        : std_logic_vector(15 downto 0);

        es_seg_val      : std_logic_vector(15 downto 0);
        ss_seg_val      : std_logic_vector(15 downto 0);
        seg_val         : std_logic_vector(15 downto 0);
        dreg_val        : std_logic_vector(15 downto 0);
        sreg_val        : std_logic_vector(15 downto 0);
        sp_val          : std_logic_vector(15 downto 0);
        sp_offset       : std_logic_vector(15 downto 0);
        ea_val          : std_logic_vector(15 downto 0);
    end record;

    constant MICRO_OP_CMD_WIDTH : natural := 14;
    constant MICRO_OP_CMD_MEM   : natural := 0;
    constant MICRO_OP_CMD_ALU   : natural := 1;
    constant MICRO_OP_CMD_JMP   : natural := 2;
    constant MICRO_OP_CMD_FLG   : natural := 3;
    constant MICRO_OP_CMD_MUL   : natural := 4;
    constant MICRO_OP_CMD_DBG   : natural := 5;
    constant MICRO_OP_CMD_ONE   : natural := 6;
    constant MICRO_OP_CMD_BCD   : natural := 7;
    constant MICRO_OP_CMD_SHF   : natural := 8;
    constant MICRO_OP_CMD_DIV   : natural := 9;
    constant MICRO_OP_CMD_BND   : natural := 10;
    constant MICRO_OP_CMD_STR   : natural := 11;
    constant MICRO_OP_CMD_MRD   : natural := 12;
    constant MICRO_OP_CMD_UNLK  : natural := 13;

    constant MICRO_UNLK_OP      : std_logic_vector(MICRO_OP_CMD_WIDTH-1 downto 0) := "10000000000000";
    constant MICRO_MRD_OP       : std_logic_vector(MICRO_OP_CMD_WIDTH-1 downto 0) := "01000000000000";
    constant MICRO_STR_OP       : std_logic_vector(MICRO_OP_CMD_WIDTH-1 downto 0) := "00100000000000";
    constant MICRO_BND_OP       : std_logic_vector(MICRO_OP_CMD_WIDTH-1 downto 0) := "00010000000000";
    constant MICRO_DIV_OP       : std_logic_vector(MICRO_OP_CMD_WIDTH-1 downto 0) := "00001000000000";
    constant MICRO_SHF_OP       : std_logic_vector(MICRO_OP_CMD_WIDTH-1 downto 0) := "00000100000000";
    constant MICRO_BCD_OP       : std_logic_vector(MICRO_OP_CMD_WIDTH-1 downto 0) := "00000010000000";
    constant MICRO_ONE_OP       : std_logic_vector(MICRO_OP_CMD_WIDTH-1 downto 0) := "00000001000000";
    constant MICRO_DBG_OP       : std_logic_vector(MICRO_OP_CMD_WIDTH-1 downto 0) := "00000000100000";
    constant MICRO_MUL_OP       : std_logic_vector(MICRO_OP_CMD_WIDTH-1 downto 0) := "00000000010000";
    constant MICRO_FLG_OP       : std_logic_vector(MICRO_OP_CMD_WIDTH-1 downto 0) := "00000000001000";
    constant MICRO_JMP_OP       : std_logic_vector(MICRO_OP_CMD_WIDTH-1 downto 0) := "00000000000100";
    constant MICRO_ALU_OP       : std_logic_vector(MICRO_OP_CMD_WIDTH-1 downto 0) := "00000000000010";
    constant MICRO_MEM_OP       : std_logic_vector(MICRO_OP_CMD_WIDTH-1 downto 0) := "00000000000001";
    constant MICRO_NOP_OP       : std_logic_vector(MICRO_OP_CMD_WIDTH-1 downto 0) := "00000000000000";


    type micro_op_src_a_t is (sreg_val, dreg_val, mem_val, ea_val, imm);
    type micro_op_src_b_t is (sreg_val, dreg_val, mem_val, ea_val, imm);
    type micro_op_jmp_cond_t is (
        j_always,
        j_never,
        cx_ne_0,
        cx_eq_0,
        cx_ne_0_and_zf,
        cx_ne_0_and_nzf,
        j_jo,
        j_jno,
        j_jb,
        j_jae,
        j_je,
        j_jne,
        j_jbe,
        j_ja,
        j_js,
        j_jns,
        j_jp,
        j_jnp,
        j_jl,
        j_jge,
        j_jle,
        j_jg);

    type micro_op_t is record
        cmd             : std_logic_vector(MICRO_OP_CMD_WIDTH-1 downto 0);
        --unlk_fl         : std_logic;
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
        alu_upd_fl      : std_logic;

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

        bnd_val         : std_logic_vector(15 downto 0);
        bnd_ss_val      : std_logic_vector(15 downto 0);
        bnd_cs_val      : std_logic_vector(15 downto 0);
        bnd_ip_val      : std_logic_vector(15 downto 0);
        bnd_ip_next_val : std_logic_vector(15 downto 0);

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

        str_code        : std_logic_vector(3 downto 0);
        str_rep         : std_logic;
        str_rep_nz      : std_logic;
        str_direction   : std_logic;
        str_w           : std_logic;
        str_port        : std_logic_vector(15 downto 0);
        str_ax_val      : std_logic_vector(15 downto 0);
        str_cx_val      : std_logic_vector(15 downto 0);
        str_es_val      : std_logic_vector(15 downto 0);
        str_di_val      : std_logic_vector(15 downto 0);
        str_ds_val      : std_logic_vector(15 downto 0);
        str_si_val      : std_logic_vector(15 downto 0);

        jump_cond       : micro_op_jmp_cond_t;
        jump_imm        : std_logic;
        jump_cs_mem     : std_logic;
        jump_cs         : std_logic_vector(15 downto 0);
        jump_ip_mem     : std_logic;
        jump_ip         : std_logic_vector(15 downto 0);
        jump_cx         : std_logic_vector(15 downto 0);

        mem_cmd         : std_logic;
        mem_width       : std_logic;
        mem_seg         : std_logic_vector(15 downto 0);
        mem_addr        : std_logic_vector(15 downto 0);
        mem_data_src    : mem_data_src_t;
        mem_data        : std_logic_vector(15 downto 0);

        flg_no          : std_logic_vector(3 downto 0);
        fl              : fl_action_t;

        inst_cs         : std_logic_vector(15 downto 0);
        inst_ip         : std_logic_vector(15 downto 0);
        inst_ip_next    : std_logic_vector(15 downto 0);

        bpu_first       : std_logic;
        bpu_taken       : std_logic;
        bpu_bypass      : std_logic;
        bpu_taken_cs    : std_logic_vector(15 downto 0);
        bpu_taken_ip    : std_logic_vector(15 downto 0);

    end record;

    type str_req_t is record
        code            : std_logic_vector(3 downto 0);
        rep             : std_logic;
        rep_nz          : std_logic;
        direction       : std_logic;
        w               : std_logic;
        io_port         : std_logic_vector(15 downto 0);
        ax_val          : std_logic_vector(15 downto 0);
        cx_val          : std_logic_vector(15 downto 0);
        es_val          : std_logic_vector(15 downto 0);
        di_val          : std_logic_vector(15 downto 0);
        ds_val          : std_logic_vector(15 downto 0);
        si_val          : std_logic_vector(15 downto 0);
    end record;

    type str_res_t is record
        code            : std_logic_vector(3 downto 0);
        rep             : std_logic;
        w               : std_logic;
        ax_upd_fl       : std_logic;
        ax_val          : std_logic_vector(15 downto 0);
        cx_val          : std_logic_vector(15 downto 0);
        di_upd_fl       : std_logic;
        di_val          : std_logic_vector(15 downto 0);
        si_upd_fl       : std_logic;
        si_val          : std_logic_vector(15 downto 0);
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

    type cpu86_jump_t is record
        first               : std_logic;
        mismatch            : std_logic;
        taken               : std_logic;
        bypass              : std_logic;
        inst_cs             : std_logic_vector(15 downto 0);
        inst_ip             : std_logic_vector(15 downto 0);
        jump_cs             : std_logic_vector(15 downto 0);
        jump_ip             : std_logic_vector(15 downto 0);
    end record;

    function decoded_instr_t_to_slv (d : decoded_instr_t) return std_logic_vector;
    function slv_to_decoded_instr_t (v : std_logic_vector) return decoded_instr_t;

end package;

package body cpu86_types is

    subtype  DECODED_INSTR_T_BPU_TAKEN_CS   is natural range 127 downto 112;
    subtype  DECODED_INSTR_T_BPU_TAKEN_IP   is natural range 111 downto 96;
    constant DECODED_INSTR_T_BPU_TAKEN      :  natural := 95;
    constant DECODED_INSTR_T_BPU_FIRST      :  natural := 94;
    subtype  DECODED_INSTR_T_IMM8           is natural range 93 downto 86;
    constant DECODED_INSTR_T_WAIT_AX        :  natural := 85;
    constant DECODED_INSTR_T_WAIT_BX        :  natural := 84;
    constant DECODED_INSTR_T_WAIT_CX        :  natural := 83;
    constant DECODED_INSTR_T_WAIT_DX        :  natural := 82;
    constant DECODED_INSTR_T_WAIT_BP        :  natural := 81;
    constant DECODED_INSTR_T_WAIT_SI        :  natural := 80;
    constant DECODED_INSTR_T_WAIT_DI        :  natural := 79;
    constant DECODED_INSTR_T_WAIT_SP        :  natural := 78;
    constant DECODED_INSTR_T_WAIT_DS        :  natural := 77;
    constant DECODED_INSTR_T_WAIT_ES        :  natural := 76;
    constant DECODED_INSTR_T_WAIT_SS        :  natural := 75;
    constant DECODED_INSTR_T_WAIT_FL        :  natural := 74;
    constant DECODED_INSTR_T_LOCK_FL        :  natural := 73;
    constant DECODED_INSTR_T_LOCK_SP        :  natural := 72;
    constant DECODED_INSTR_T_LOCK_SREG      :  natural := 71;
    constant DECODED_INSTR_T_LOCK_DREG      :  natural := 70;
    constant DECODED_INSTR_T_LOCK_AX        :  natural := 69;
    constant DECODED_INSTR_T_LOCK_SI        :  natural := 68;
    constant DECODED_INSTR_T_LOCK_DI        :  natural := 67;
    constant DECODED_INSTR_T_LOCK_DS        :  natural := 66;
    constant DECODED_INSTR_T_LOCK_ES        :  natural := 65;
    constant DECODED_INSTR_T_LOCK_ALL       :  natural := 64;
    subtype  DECODED_INSTR_T_FL             is natural range 63 downto 62;
    subtype  DECODED_INSTR_T_OP             is natural range 61 downto 57;
    subtype  DECODED_INSTR_T_CODE           is natural range 56 downto 53;
    constant DECODED_INSTR_T_W              : natural  := 52;
    subtype  DECODED_INSTR_T_DIR            is natural range 51 downto 48;
    subtype  DECODED_INSTR_T_EA             is natural range 47 downto 44;
    subtype  DECODED_INSTR_T_DREG           is natural range 43 downto 40;
    subtype  DECODED_INSTR_T_DMASK          is natural range 39 downto 38;
    subtype  DECODED_INSTR_T_SREG           is natural range 37 downto 34;
    subtype  DECODED_INSTR_T_SMASK          is natural range 33 downto 32;
    subtype  DECODED_INSTR_T_DATA           is natural range 31 downto 16;
    subtype  DECODED_INSTR_T_DISP           is natural range 15 downto 0;

    function decoded_instr_t_to_slv (d : decoded_instr_t) return std_logic_vector is
        variable v : std_logic_vector(DECODED_INSTR_T_WIDTH-1 downto 0);
    begin

        v(DECODED_INSTR_T_BPU_TAKEN_CS) := d.bpu_taken_cs;
        v(DECODED_INSTR_T_BPU_TAKEN_IP) := d.bpu_taken_ip;

        v(DECODED_INSTR_T_BPU_TAKEN)    := d.bpu_taken;
        v(DECODED_INSTR_T_BPU_FIRST)    := d.bpu_first;

        v(DECODED_INSTR_T_IMM8)         := d.imm8;
        v(DECODED_INSTR_T_WAIT_AX)      := d.wait_ax;
        v(DECODED_INSTR_T_WAIT_BX)      := d.wait_bx;
        v(DECODED_INSTR_T_WAIT_CX)      := d.wait_cx;
        v(DECODED_INSTR_T_WAIT_DX)      := d.wait_dx;
        v(DECODED_INSTR_T_WAIT_BP)      := d.wait_bp;
        v(DECODED_INSTR_T_WAIT_SI)      := d.wait_si;
        v(DECODED_INSTR_T_WAIT_DI)      := d.wait_di;
        v(DECODED_INSTR_T_WAIT_SP)      := d.wait_sp;
        v(DECODED_INSTR_T_WAIT_DS)      := d.wait_ds;
        v(DECODED_INSTR_T_WAIT_ES)      := d.wait_es;
        v(DECODED_INSTR_T_WAIT_SS)      := d.wait_ss;
        v(DECODED_INSTR_T_WAIT_FL)      := d.wait_fl;

        v(DECODED_INSTR_T_LOCK_FL)      := d.lock_fl;
        v(DECODED_INSTR_T_LOCK_SP)      := d.lock_sp;
        v(DECODED_INSTR_T_LOCK_SREG)    := d.lock_sreg;
        v(DECODED_INSTR_T_LOCK_DREG)    := d.lock_dreg;
        v(DECODED_INSTR_T_LOCK_AX)      := d.lock_ax;
        v(DECODED_INSTR_T_LOCK_SI)      := d.lock_si;
        v(DECODED_INSTR_T_LOCK_DI)      := d.lock_di;
        v(DECODED_INSTR_T_LOCK_DS)      := d.lock_ds;
        v(DECODED_INSTR_T_LOCK_ES)      := d.lock_es;
        v(DECODED_INSTR_T_LOCK_ALL)     := d.lock_all;

        v(DECODED_INSTR_T_FL)           := std_logic_vector(to_unsigned(fl_action_t'pos(d.fl), 2));
        v(DECODED_INSTR_T_OP)           := std_logic_vector(to_unsigned(op_t'pos(d.op), 5));
        v(DECODED_INSTR_T_CODE)         := d.code;
        v(DECODED_INSTR_T_W)            := d.w;
        v(DECODED_INSTR_T_DIR)          := std_logic_vector(to_unsigned(direction_t'pos(d.dir), 4));
        v(DECODED_INSTR_T_EA)           := std_logic_vector(to_unsigned(ea_t'pos(d.ea), 4));
        v(DECODED_INSTR_T_DREG)         := std_logic_vector(to_unsigned(reg_t'pos(d.dreg), 4));
        v(DECODED_INSTR_T_DMASK)        := d.dmask;
        v(DECODED_INSTR_T_SREG)         := std_logic_vector(to_unsigned(reg_t'pos(d.sreg), 4));
        v(DECODED_INSTR_T_SMASK)        := d.smask;
        v(DECODED_INSTR_T_DATA)         := d.data;
        v(DECODED_INSTR_T_DISP)         := d.disp;

        return v;

    end function;

    function slv_to_decoded_instr_t (v : std_logic_vector) return decoded_instr_t is
        variable t : std_logic_vector(DECODED_INSTR_T_WIDTH-1 downto 0);
        variable d : decoded_instr_t;
    begin
        t := v;

        d.bpu_taken_cs  := t(DECODED_INSTR_T_BPU_TAKEN_CS);
        d.bpu_taken_ip  := t(DECODED_INSTR_T_BPU_TAKEN_IP);

        d.bpu_taken     := t(DECODED_INSTR_T_BPU_TAKEN);
        d.bpu_first     := t(DECODED_INSTR_T_BPU_FIRST);

        d.imm8          := t(DECODED_INSTR_T_IMM8);
        d.wait_ax       := t(DECODED_INSTR_T_WAIT_AX);
        d.wait_bx       := t(DECODED_INSTR_T_WAIT_BX);
        d.wait_cx       := t(DECODED_INSTR_T_WAIT_CX);
        d.wait_dx       := t(DECODED_INSTR_T_WAIT_DX);
        d.wait_bp       := t(DECODED_INSTR_T_WAIT_BP);
        d.wait_si       := t(DECODED_INSTR_T_WAIT_SI);
        d.wait_di       := t(DECODED_INSTR_T_WAIT_DI);
        d.wait_sp       := t(DECODED_INSTR_T_WAIT_SP);
        d.wait_ds       := t(DECODED_INSTR_T_WAIT_DS);
        d.wait_es       := t(DECODED_INSTR_T_WAIT_ES);
        d.wait_ss       := t(DECODED_INSTR_T_WAIT_SS);
        d.wait_fl       := t(DECODED_INSTR_T_WAIT_FL);

        d.lock_fl       := t(DECODED_INSTR_T_LOCK_FL);
        d.lock_sp       := t(DECODED_INSTR_T_LOCK_SP);
        d.lock_sreg     := t(DECODED_INSTR_T_LOCK_SREG);
        d.lock_dreg     := t(DECODED_INSTR_T_LOCK_DREG);
        d.lock_ax       := t(DECODED_INSTR_T_LOCK_AX);
        d.lock_si       := t(DECODED_INSTR_T_LOCK_SI);
        d.lock_di       := t(DECODED_INSTR_T_LOCK_DI);
        d.lock_ds       := t(DECODED_INSTR_T_LOCK_DS);
        d.lock_es       := t(DECODED_INSTR_T_LOCK_ES);
        d.lock_all      := t(DECODED_INSTR_T_LOCK_ALL);

        d.fl            := fl_action_t'val(to_integer(unsigned(t(DECODED_INSTR_T_FL))));
        d.op            := op_t'val(to_integer(unsigned(t(DECODED_INSTR_T_OP))));
        d.code          := t(DECODED_INSTR_T_CODE);
        d.w             := t(DECODED_INSTR_T_W);
        d.dir           := direction_t'val(to_integer(unsigned(t(DECODED_INSTR_T_DIR))));
        d.ea            := ea_t'val(to_integer(unsigned(t(DECODED_INSTR_T_EA))));
        d.dreg          := reg_t'val(to_integer(unsigned(t(DECODED_INSTR_T_DREG))));
        d.dmask         := t(DECODED_INSTR_T_DMASK);
        d.sreg          := reg_t'val(to_integer(unsigned(t(DECODED_INSTR_T_SREG))));
        d.smask         := t(DECODED_INSTR_T_SMASK);
        d.data          := t(DECODED_INSTR_T_DATA);
        d.disp          := t(DECODED_INSTR_T_DISP);

        return d;

    end;

end package body;
