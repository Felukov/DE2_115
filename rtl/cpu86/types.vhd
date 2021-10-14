library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

package cpu86_types is

    type reg_t is (
        AX, DX, CX, BX, BP, SI, DI, SP, ES, CS, SS, DS, FL
    );

    type ea_t is (
        BX_SI_DISP, BX_DI_DISP, BP_SI_DISP, BP_DI_DISP, SI_DISP, DI_DISP, BP_DISP, BX_DISP, DIRECT
    );

    type direction_t is (
        R2R, M2R, R2M, I2R, I2M, R2F, STK, STKM, M2M, STR, SSEG, SFLG
    );

    type op_t is (
        MOVU, ALU, DIVU, MULU, FEU, STACKU, LOOPU, SET_SEG, REP, STR, SET_FLAG, DBG, XCHG, SYS
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
    constant ALU_SF_ADD     : std_logic_vector (3 downto 0) := "1111";

    constant STACKU_POPR    : std_logic_vector (3 downto 0) := "0000";
    constant STACKU_PUSHR   : std_logic_vector (3 downto 0) := "0001";
    constant STACKU_POPA    : std_logic_vector (3 downto 0) := "0010";
    constant STACKU_PUSHA   : std_logic_vector (3 downto 0) := "0011";
    constant STACKU_POPF    : std_logic_vector (3 downto 0) := "0100";
    constant STACKU_PUSHF   : std_logic_vector (3 downto 0) := "0101";
    constant STACKU_PUSHI   : std_logic_vector (3 downto 0) := "0110";
    constant STACKU_PUSHM   : std_logic_vector (3 downto 0) := "0111";
    constant STACKU_POPM    : std_logic_vector (3 downto 0) := "1000";

    constant LOOP_OP        : std_logic_vector (3 downto 0) := "0000";
    constant LOOP_OP_E      : std_logic_vector (3 downto 0) := "0001";
    constant LOOP_OP_NE     : std_logic_vector (3 downto 0) := "0010";

    constant REPZ_OP        : std_logic_vector (3 downto 0) := "0000";
    constant REPNZ_OP       : std_logic_vector (3 downto 0) := "0001";

    constant MOVS_OP        : std_logic_vector (3 downto 0) := "0000";
    constant STOS_OP        : std_logic_vector (3 downto 0) := "0001";

    constant SYS_HLT_OP     : std_logic_vector (3 downto 0) := "0000";
    constant SYS_ESC_OP     : std_logic_vector (3 downto 0) := "0001";
    constant SYS_DBG_OP     : std_logic_vector (3 downto 0) := "0010";

    constant FEU_CBW        : std_logic_vector (3 downto 0) := "0000";
    constant FEU_CWD        : std_logic_vector (3 downto 0) := "0001";
    constant FEU_LEA        : std_logic_vector (3 downto 0) := "0010";

    constant MEM_ADDR_SRC_ALU  : std_logic := '1';
    constant MEM_ADDR_SRC_EA   : std_logic := '0';

    constant MEM_DATA_SRC_ALU  : std_logic_vector(1 downto 0) := "01";
    constant MEM_DATA_SRC_IMM  : std_logic_vector(1 downto 0) := "00";
    constant MEM_DATA_SRC_FIFO : std_logic_vector(1 downto 0) := "10";

    constant FLAG_15            : natural := 15;
    constant FLAG_14            : natural := 14;
    constant FLAG_13            : natural := 13;
    constant FLAG_12            : natural := 12;
    constant FLAG_OF            : natural := 11;
    constant FLAG_DF            : natural := 10;
    constant FLAG_IF            : natural := 9;
    constant FLAG_TF            : natural := 8;
    constant FLAG_SF            : natural := 7;
    constant FLAG_ZF            : natural := 6;
    constant FLAG_05            : natural := 5;
    constant FLAG_AF            : natural := 4;
    constant FLAG_03            : natural := 3;
    constant FLAG_PF            : natural := 2;
    constant FLAG_01            : natural := 1;
    constant FLAG_CF            : natural := 0;

    constant DECODED_INSTR_T_WIDTH : integer := 62;

    type packed_decoded_instr_t is record
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
        dir         : direction_t;
        ea          : ea_t;
        dreg        : reg_t;
        dmask       : std_logic_vector(1 downto 0);
        sreg        : reg_t;
        data        : std_logic_vector(15 downto 0);
        disp        : std_logic_vector(15 downto 0);
    end record;

    constant MICRO_OP_CMD_WIDTH : natural := 5;
    constant MICRO_OP_CMD_MEM : natural := 0;
    constant MICRO_OP_CMD_ALU : natural := 1;
    constant MICRO_OP_CMD_JMP : natural := 2;
    constant MICRO_OP_CMD_FLG : natural := 3;
    constant MICRO_OP_CMD_DBG : natural := 4;

    type micro_op_src_a_t is (sreg_val, dreg_val, mem_val, ea_val, imm);
    type micro_op_src_b_t is (sreg_val, dreg_val, mem_val, ea_val, imm);
    type micro_op_jmp_cond_t is (cx_ne_0, cx_ne_0_and_zf, cx_ne_0_and_nzf);

    type micro_op_t is record
        cmd             : std_logic_vector(MICRO_OP_CMD_WIDTH-1 downto 0);
        unlk_fl         : std_logic;
        read_fifo       : std_logic;
        --wr              : std_logic;
        alu_code        : std_logic_vector(3 downto 0);
        alu_w           : std_logic;
        alu_dreg        : reg_t;
        alu_dmask       : std_logic_vector(1 downto 0);
        alu_a_acc       : std_logic;
        alu_a_mem       : std_logic;
        alu_a_val       : std_logic_vector(15 downto 0);
        alu_b_mem       : std_logic;
        alu_b_val       : std_logic_vector(15 downto 0);
        alu_wb          : std_logic;
        alu_keep_lock   : std_logic;
        jump_cond       : micro_op_jmp_cond_t;
        jump_cs         : std_logic_vector(15 downto 0);
        jump_ip         : std_logic_vector(15 downto 0);
        mem_cmd         : std_logic;
        mem_width       : std_logic;
        mem_seg         : std_logic_vector(15 downto 0);
        mem_addr_src    : std_logic;
        mem_addr        : std_logic_vector(15 downto 0);
        mem_data_src    : std_logic_vector(1 downto 0);
        mem_data        : std_logic_vector(15 downto 0);
        flg_no          : std_logic_vector(3 downto 0);
        flg_val         : std_logic;
        dbg_cs          : std_logic_vector(15 downto 0);
        dbg_ip          : std_logic_vector(15 downto 0);
    end record;

    function decoded_instr_t_to_slv (decoded_instr : decoded_instr_t) return std_logic_vector;
    function slv_to_decoded_instr_t (v : std_logic_vector) return decoded_instr_t;

end package;

package body cpu86_types is

    function decoded_instr_t_to_slv (decoded_instr : decoded_instr_t) return std_logic_vector is
        variable p : packed_decoded_instr_t;
        variable v : std_logic_vector(DECODED_INSTR_T_WIDTH-1 downto 0);
    begin

        p.op := std_logic_vector(to_unsigned(op_t'pos(decoded_instr.op), p.op'length));
        p.code := decoded_instr.code;
        p.w := (52 => decoded_instr.w);
        p.dir := std_logic_vector(to_unsigned(direction_t'pos(decoded_instr.dir), p.dir'length));
        p.ea := std_logic_vector(to_unsigned(ea_t'pos(decoded_instr.ea), p.ea'length));
        p.dreg := std_logic_vector(to_unsigned(reg_t'pos(decoded_instr.dreg), p.dreg'length));
        p.dmask := decoded_instr.dmask;
        p.sreg := std_logic_vector(to_unsigned(reg_t'pos(decoded_instr.sreg), p.sreg'length));
        p.smask := decoded_instr.smask;
        p.data := decoded_instr.data;
        p.disp := decoded_instr.disp;

        v := p.op & p.code & p.w & p.dir & p.ea & p.dreg & p.dmask & p.sreg & p.smask & p.data & p.disp;

        return v;

    end function;

    function slv_to_decoded_instr_t (v : std_logic_vector) return decoded_instr_t is
        variable t : std_logic_vector(DECODED_INSTR_T_WIDTH-1 downto 0);
        variable p : packed_decoded_instr_t;
        variable d : decoded_instr_t;
    begin
        t := v;
        --(p.op,  p.code, p.w, p.dir, p.ea, p.dreg, p.dmask, p.sreg, p.smask, p.data, p.disp) := v;

        p.op := t(p.op'range);
        p.code := t(p.code'range);
        p.w := t(p.w'range);
        p.dir := t(p.dir'range);
        p.ea := t(p.ea'range);
        p.dreg := t(p.dreg'range);
        p.dmask := t(p.dmask'range);
        p.sreg := t(p.sreg'range);
        p.smask := t(p.smask'range);
        p.data := t(p.data'range);
        p.disp := t(p.disp'range);

        d.op := op_t'val(to_integer(unsigned(p.op)));
        d.code := p.code;
        d.w := p.w(52);
        d.dir := direction_t'val(to_integer(unsigned(p.dir)));
        d.ea := ea_t'val(to_integer(unsigned(p.ea)));
        d.dreg := reg_t'val(to_integer(unsigned(p.dreg)));
        d.dmask := p.dmask;
        d.sreg := reg_t'val(to_integer(unsigned(p.sreg)));
        d.smask := p.smask;
        d.data := p.data;
        d.disp := p.disp;

        return d;

    end;

end package body;
