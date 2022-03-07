library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.cpu86_types.all;

entity ifeu is
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
        div_intr_s_tdata        : in div_intr_t;

        bnd_intr_s_tvalid       : in std_logic;
        bnd_intr_s_tready       : out std_logic;
        bnd_intr_s_tdata        : in div_intr_t;

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

        jmp_lock_m_lock_tvalid  : out std_logic
    );
end entity ifeu;

architecture rtl of ifeu is

    constant FLAG_DF            : natural := 10;
    constant FLAG_ZF            : natural := 6;

    constant SP_DIR_INC         : std_logic := '0';
    constant SP_DIR_DEC         : std_logic := '1';

    signal rr_tvalid            : std_logic;
    signal rr_tready            : std_logic;
    signal rr_tdata             : rr_instr_t;
    signal rr_tuser             : user_t;

    signal micro_tvalid         : std_logic;
    signal micro_tready         : std_logic;
    signal micro_cnt_next       : natural range 0 to 63;
    signal micro_cnt            : natural range 0 to 63;
    signal micro_busy           : std_logic;
    signal micro_tdata          : micro_op_t;
    signal rr_tdata_buf         : rr_instr_t;
    signal rr_tuser_buf         : user_t;
    signal rr_tuser_buf_ip_next : std_logic_vector(15 downto 0);

    signal ea_val_plus_disp_next: std_logic_vector(15 downto 0);
    signal ea_val_plus_disp     : std_logic_vector(15 downto 0);
    signal ea_val_plus_disp_p_2 : std_logic_vector(15 downto 0);

    signal frame_pointer        : std_logic_vector(15 downto 0);

    signal rep_mode             : std_logic;
    signal rep_code             : std_logic_vector(1 downto 0);
    signal rep_cx_cnt           : std_logic_vector(15 downto 0);
    signal rep_nz               : std_logic;

    signal halt_mode            : std_logic;

    signal ax_tdata_selector    : std_logic_vector(2 downto 0);
    signal bx_tdata_selector    : std_logic_vector(2 downto 0);
    signal cx_tdata_selector    : std_logic_vector(2 downto 0);
    signal dx_tdata_selector    : std_logic_vector(3 downto 0);
    signal bp_tdata_selector    : std_logic_vector(2 downto 0);
    signal di_tdata_selector    : std_logic_vector(2 downto 0);
    signal si_tdata_selector    : std_logic_vector(2 downto 0);
    signal sp_tdata_selector    : std_logic_vector(2 downto 0);

    signal sp_val               : std_logic_vector(15 downto 0);
    signal bp_val               : std_logic_vector(15 downto 0);

begin
    rr_tvalid <= rr_s_tvalid;
    rr_s_tready <= rr_tready;
    rr_tdata <= rr_s_tdata;
    rr_tuser <= rr_s_tuser;

    micro_m_tvalid <= micro_tvalid;
    micro_tready <= micro_m_tready;
    micro_m_tdata <= micro_tdata;

    rr_tready <= '1' when div_intr_s_tvalid = '0' and bnd_intr_s_tvalid = '0' and
        jmp_lock_s_tvalid = '1' and halt_mode = '0' and
        (micro_tvalid = '0' or (micro_tvalid = '1' and micro_tready = '1' and micro_busy = '0')) else '0';

    div_intr_s_tready <= '1' when jmp_lock_s_tvalid = '1' and halt_mode = '0' and (micro_tvalid = '0' or
        (micro_tvalid = '1' and micro_tready = '1' and micro_busy = '0')) else '0';

    bnd_intr_s_tready <= '1' when jmp_lock_s_tvalid = '1' and halt_mode = '0' and (micro_tvalid = '0' or
        (micro_tvalid = '1' and micro_tready = '1' and micro_busy = '0')) else '0';

    jmp_lock_m_lock_tvalid <= '1' when rr_tvalid = '1' and rr_tready = '1' and
        ((rr_tdata.op = LOOPU) or
         (rr_tdata.op = JMPU) or
         (rr_tdata.op = BRANCH) or
         (rr_tdata.op = JCALL) or
         (rr_tdata.op = RET) or
         (rr_tdata.op = DIVU) or
         (rr_tdata.op = DBG) or
         (rr_tdata.op = IO) or
         (rr_tdata.op = LFP and rr_tdata.code = MISC_BOUND) or
         (rr_tdata.op = SYS and (rr_tdata.code = SYS_INT_OP))) else '0';

    ea_val_plus_disp_next <= std_logic_vector(unsigned(rr_tdata.ea_val) + unsigned(rr_tdata.disp));
    ea_val_plus_disp_p_2 <= std_logic_vector(unsigned(ea_val_plus_disp) + to_unsigned(2, 16));

    update_regs_proc : process (all) begin

        ax_m_wr_tvalid <= '0';
        bx_m_wr_tvalid <= '0';
        cx_m_wr_tvalid <= '0';
        dx_m_wr_tvalid <= '0';
        bp_m_wr_tvalid <= '0';
        sp_m_wr_tvalid <= '0';
        di_m_wr_tvalid <= '0';
        si_m_wr_tvalid <= '0';
        ds_m_wr_tvalid <= '0';
        ss_m_wr_tvalid <= '0';
        es_m_wr_tvalid <= '0';

        if (rr_tvalid = '1' and rr_tready = '1') then

            if ((rr_tdata.op = MOVU or rr_tdata.op = XCHG) and (rr_tdata.dir = R2R or rr_tdata.dir = I2R)) or (rr_tdata.op = FEU) then
                case rr_tdata.dreg is
                    when AX => ax_m_wr_tvalid <= '1';
                    when BX => bx_m_wr_tvalid <= '1';
                    when CX => cx_m_wr_tvalid <= '1';
                    when DX => dx_m_wr_tvalid <= '1';
                    when BP => bp_m_wr_tvalid <= '1';
                    when SP => sp_m_wr_tvalid <= '1';
                    when DI => di_m_wr_tvalid <= '1';
                    when SI => si_m_wr_tvalid <= '1';
                    when DS => ds_m_wr_tvalid <= '1';
                    when ES => es_m_wr_tvalid <= '1';
                    when SS => ss_m_wr_tvalid <= '1';
                    when others => null;
                end case;
            end if;

            if (rr_tdata.op = XCHG and rr_tdata.dir = R2R) then
                case rr_tdata.sreg is
                    when AX => ax_m_wr_tvalid <= '1';
                    when BX => bx_m_wr_tvalid <= '1';
                    when CX => cx_m_wr_tvalid <= '1';
                    when DX => dx_m_wr_tvalid <= '1';
                    when BP => bp_m_wr_tvalid <= '1';
                    when SP => sp_m_wr_tvalid <= '1';
                    when DI => di_m_wr_tvalid <= '1';
                    when SI => si_m_wr_tvalid <= '1';
                    when others => null;
                end case;
            end if;

        end if;

        ax_m_wr_tmask <= rr_tdata.dmask;
        bx_m_wr_tmask <= rr_tdata.dmask;
        cx_m_wr_tmask <= rr_tdata.dmask;
        dx_m_wr_tmask <= rr_tdata.dmask;

    end process;

    ax_tdata_selector(0) <= '1' when rr_tdata.op = MOVU and rr_tdata.dir = I2R else '0';
    ax_tdata_selector(1) <= '1' when rr_tdata.op = FEU and rr_tdata.code = FEU_LEA else '0';
    ax_tdata_selector(2) <= '1' when rr_tdata.op = FEU and rr_tdata.code = FEU_CBW else '0';

    bx_tdata_selector(0) <= '1' when rr_tdata.op = MOVU and rr_tdata.dir = I2R else '0';
    bx_tdata_selector(1) <= '1' when rr_tdata.op = FEU and rr_tdata.code = FEU_LEA else '0';
    bx_tdata_selector(2) <= '1' when rr_tdata.op = XCHG and rr_tdata.dir = R2R else '0';

    cx_tdata_selector(0) <= '1' when rr_tdata.op = MOVU and rr_tdata.dir = I2R else '0';
    cx_tdata_selector(1) <= '1' when rr_tdata.op = FEU and rr_tdata.code = FEU_LEA else '0';
    cx_tdata_selector(2) <= '1' when rr_tdata.op = XCHG and rr_tdata.dir = R2R else '0';

    dx_tdata_selector(0) <= '1' when rr_tdata.op = MOVU and rr_tdata.dir = I2R else '0';
    dx_tdata_selector(1) <= '1' when rr_tdata.op = FEU and rr_tdata.code = FEU_LEA else '0';
    dx_tdata_selector(2) <= '1' when rr_tdata.op = XCHG and rr_tdata.dir = R2R else '0';
    dx_tdata_selector(3) <= '1' when rr_tdata.op = FEU and rr_tdata.code = FEU_CWD else '0';

    bp_tdata_selector(0) <= '1' when rr_tdata.op = MOVU and rr_tdata.dir = I2R else '0';
    bp_tdata_selector(1) <= '1' when rr_tdata.op = FEU and rr_tdata.code = FEU_LEA else '0';
    bp_tdata_selector(2) <= '1' when rr_tdata.op = XCHG and rr_tdata.dir = R2R else '0';

    di_tdata_selector(0) <= '1' when rr_tdata.op = MOVU and rr_tdata.dir = I2R else '0';
    di_tdata_selector(1) <= '1' when rr_tdata.op = FEU and rr_tdata.code = FEU_LEA else '0';
    di_tdata_selector(2) <= '1' when rr_tdata.op = XCHG and rr_tdata.dir = R2R else '0';

    si_tdata_selector(0) <= '1' when rr_tdata.op = MOVU and rr_tdata.dir = I2R else '0';
    si_tdata_selector(1) <= '1' when rr_tdata.op = FEU and rr_tdata.code = FEU_LEA else '0';
    si_tdata_selector(2) <= '1' when rr_tdata.op = XCHG and rr_tdata.dir = R2R else '0';

    sp_tdata_selector(0) <= '1' when rr_tdata.op = MOVU and rr_tdata.dir = I2R else '0';
    sp_tdata_selector(1) <= '1' when rr_tdata.op = FEU and rr_tdata.code = FEU_LEA else '0';
    sp_tdata_selector(2) <= '1' when rr_tdata.op = XCHG and rr_tdata.dir = R2R else '0';

    update_regs_data_proc : process (all) begin

        case ax_tdata_selector is
            when "001" => ax_m_wr_tdata <= rr_tdata.data;
            when "010" => ax_m_wr_tdata <= ea_val_plus_disp_next;
            when "100" =>
                for i in 15 downto 8 loop
                    ax_m_wr_tdata(i) <= rr_tdata.sreg_val(7);
                end loop;
                ax_m_wr_tdata(7 downto 0) <= rr_tdata.sreg_val(7 downto 0);
            when others => ax_m_wr_tdata <= rr_tdata.sreg_val;
        end case;

        case bx_tdata_selector is
            when "001" => bx_m_wr_tdata <= rr_tdata.data;
            when "010" => bx_m_wr_tdata <= ea_val_plus_disp_next;
            when "100" => bx_m_wr_tdata <= rr_tdata.dreg_val;
            when others => bx_m_wr_tdata <= rr_tdata.sreg_val;
        end case;

        case cx_tdata_selector is
            when "001" => cx_m_wr_tdata <= rr_tdata.data;
            when "010" => cx_m_wr_tdata <= ea_val_plus_disp_next;
            when "100" => cx_m_wr_tdata <= rr_tdata.dreg_val;
            when others => cx_m_wr_tdata <= rr_tdata.sreg_val;
        end case;

        case dx_tdata_selector is
            when "0001" => dx_m_wr_tdata <= rr_tdata.data;
            when "0010" => dx_m_wr_tdata <= ea_val_plus_disp_next;
            when "0100" => dx_m_wr_tdata <= rr_tdata.dreg_val;
            when "1000" =>
                for i in 15 downto 0 loop
                    dx_m_wr_tdata(i) <= rr_tdata.sreg_val(15);
                end loop;
            when others => dx_m_wr_tdata <= rr_tdata.sreg_val;
        end case;

        case bp_tdata_selector is
            when "001" => bp_m_wr_tdata <= rr_tdata.data;
            when "010" => bp_m_wr_tdata <= ea_val_plus_disp_next;
            when "100" => bp_m_wr_tdata <= rr_tdata.dreg_val;
            when others => bp_m_wr_tdata <= rr_tdata.sreg_val;
        end case;

        case sp_tdata_selector is
            when "001" => sp_m_wr_tdata <= rr_tdata.data;
            when "010" => sp_m_wr_tdata <= ea_val_plus_disp_next;
            when "100" => sp_m_wr_tdata <= rr_tdata.dreg_val;
            when others => sp_m_wr_tdata <= rr_tdata.sreg_val;
        end case;

        case di_tdata_selector is
            when "001" => di_m_wr_tdata <= rr_tdata.data;
            when "010" => di_m_wr_tdata <= ea_val_plus_disp_next;
            when "100" => di_m_wr_tdata <= rr_tdata.dreg_val;
            when others => di_m_wr_tdata <= rr_tdata.sreg_val;
        end case;

        case si_tdata_selector is
            when "001" => si_m_wr_tdata <= rr_tdata.data;
            when "010" => si_m_wr_tdata <= ea_val_plus_disp_next;
            when "100" => si_m_wr_tdata <= rr_tdata.dreg_val;
            when others => si_m_wr_tdata <= rr_tdata.sreg_val;
        end case;

        ds_m_wr_tdata <= rr_tdata.sreg_val;
        es_m_wr_tdata <= rr_tdata.sreg_val;
        ss_m_wr_tdata <= rr_tdata.sreg_val;

    end process;

    halt_mode_proc : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                halt_mode <= '0';
            else
                if (rr_tvalid = '1' and rr_tready = '1' and rr_tdata.op = SYS and rr_tdata.code = SYS_HLT_OP) then
                    halt_mode <= '1';
                end if;
            end if;
        end if;
    end process;

    rep_handler_proc : process (clk) begin

        if (rising_edge(clk)) then
            if (resetn = '0') then
                rep_mode <= '0';
                rep_cx_cnt <= x"0001";
                rep_nz <= '0';
            else

                if (rr_tvalid = '1' and rr_tready = '1' and rr_tdata.op = REP) then
                    rep_mode <= '1';
                elsif rep_mode = '1' and (rr_tvalid = '1' and rr_tready = '1') then
                    rep_mode <= '0';
                end if;

                if (rr_tvalid = '1' and rr_tready = '1' and rr_tdata.op = REP) then
                    rep_cx_cnt <= rr_tdata.sreg_val;
                elsif rep_mode = '1' and (rr_tvalid = '1' and rr_tready = '1') then
                    rep_cx_cnt <= x"0001";
                end if;

                if (rr_tvalid = '1' and rr_tready = '1' and rr_tdata.op = REP) then
                    if (rr_tdata.code = REPNZ_OP) then
                        rep_nz <= '1';
                    else
                        rep_nz <= '0';
                    end if;
                end if;

            end if;

        end if;

    end process;

    micro_cnt_next_proc : process (all) begin
        case (rr_tdata.op) is
            when LFP =>
                micro_cnt_next <= 2;

            when SYS =>
                case rr_tdata.code is
                    when SYS_INT_OP => micro_cnt_next <= 5;
                    when SYS_IRET_OP => micro_cnt_next <= 6;
                    when others => micro_cnt_next <= 0;
                end case;

            when XCHG =>
                micro_cnt_next <= 1;

            when ONEU =>
                case rr_tdata.dir is
                    when M2M => micro_cnt_next <= 1;
                    when others => micro_cnt_next <= 0;
                end case;

            when SHFU =>
                case rr_tdata.dir is
                    when I2M => micro_cnt_next <= 1;
                    when R2M => micro_cnt_next <= 1;
                    when others => micro_cnt_next <= 0;
                end case;

            when MULU =>
                case rr_tdata.dir is
                    when M2R => micro_cnt_next <= 1;
                    when others => micro_cnt_next <= 0;
                end case;

            when DIVU =>
                case rr_tdata.dir is
                    when M2R => micro_cnt_next <= 1;
                    when others => micro_cnt_next <= 0;
                end case;

            when LOOPU =>
                micro_cnt_next <= 1;

            when JMPU =>
                case rr_tdata.code is
                    when JMP_RM16 => micro_cnt_next <= 1;
                    when JMP_M16_16 => micro_cnt_next <= 2;
                    when others => micro_cnt_next <= 0;
                end case;

            when JCALL =>
                case rr_tdata.code is
                    when CALL_REL16 => micro_cnt_next <= 2;
                    when CALL_RM16 => micro_cnt_next <= 2;
                    when CALL_PTR16_16 => micro_cnt_next <= 2;
                    when others => micro_cnt_next <= 4;
                end case;

            when RET =>
                case rr_tdata.code is
                    when RET_NEAR => micro_cnt_next <= 1;
                    when RET_NEAR_IMM16 => micro_cnt_next <= 2;
                    when RET_FAR => micro_cnt_next <= 2;
                    when RET_FAR_IMM16 => micro_cnt_next <= 3;
                    when others => micro_cnt_next <= 1;
                end case;

            when STACKU =>
                case rr_tdata.code is
                    when STACKU_ENTER =>
                        if (rr_tdata.level = 0) then
                            micro_cnt_next <= 4;
                        else
                            micro_cnt_next <= rr_tdata.level + 3;
                        end if;
                    when STACKU_LEAVE => micro_cnt_next <= 1;
                    when STACKU_PUSHA => micro_cnt_next <= 7;
                    when STACKU_PUSHM => micro_cnt_next <= 1;
                    when STACKU_POPA => micro_cnt_next <= 15;
                    when STACKU_POPR => micro_cnt_next <= 1;
                    when STACKU_POPM => micro_cnt_next <= 1;
                    when others => micro_cnt_next <= 0;
                end case;

            when MOVU =>
                case rr_tdata.dir is
                    when M2R => micro_cnt_next <= 1;
                    when others => micro_cnt_next <= 0;
                end case;

            when ALU =>
                case rr_tdata.dir is
                    when M2R => micro_cnt_next <= 1;
                    when R2M => micro_cnt_next <= 1;
                    when M2M => micro_cnt_next <= 1;
                    when I2M => micro_cnt_next <= 1;
                    when others => micro_cnt_next <= 0;
                end case;

            when others =>
                micro_cnt_next <= 0;
        end case;
    end process;

    micro_cmd_gen_proc : process (clk)

        procedure flag_update (flag : std_logic_vector; val : fl_action_t) is begin
            micro_tdata.flg_no <= flag;
            micro_tdata.fl <= val;
        end procedure;

        procedure flag_update (flag : natural; val : fl_action_t) is begin
            flag_update(std_logic_vector(to_unsigned(flag, 4)), val);
        end procedure;

        procedure alu_command_imm(cmd, aval, bval: std_logic_vector; dreg : reg_t; dmask : std_logic_vector; upd_fl : std_logic) is begin
            micro_tdata.alu_code <= cmd;
            micro_tdata.alu_a_val <= aval;
            micro_tdata.alu_b_val <= bval;
            micro_tdata.alu_dreg <= dreg;
            micro_tdata.alu_dmask <= dmask;
            micro_tdata.alu_wb <= '1';
            micro_tdata.alu_upd_fl <= upd_fl;
        end procedure;

        procedure alu_put_in_b(bval : std_logic_vector) is begin
            micro_tdata.alu_wb <= '0';
            micro_tdata.alu_upd_fl <= '0';
            micro_tdata.alu_code <= ALU_OP_ADD;
            micro_tdata.alu_a_val <= x"0000";
            micro_tdata.alu_b_val <= bval;
        end procedure;

        procedure mem_read_word(seg, addr : std_logic_vector) is begin
            micro_tdata.mem_cmd <= '0';
            micro_tdata.mem_width <= '1';
            micro_tdata.mem_seg <= seg;
            micro_tdata.mem_addr <= addr;
        end procedure;

        procedure mem_read(seg, addr : std_logic_vector; w : std_logic) is begin
            micro_tdata.mem_cmd <= '0';
            micro_tdata.mem_width <= w;
            micro_tdata.mem_seg <= seg;
            micro_tdata.mem_addr <= addr;
        end procedure;

        procedure mem_write_alu(seg, addr : std_logic_vector; w : std_logic) is begin
            micro_tdata.mem_cmd <= '1';
            micro_tdata.mem_width <= w;
            micro_tdata.mem_seg <= seg;
            micro_tdata.mem_addr <= addr;
            micro_tdata.mem_data_src <= MEM_DATA_SRC_ALU;
        end procedure;

        procedure mem_write_one(seg, addr : std_logic_vector; w : std_logic) is begin
            micro_tdata.mem_cmd <= '1';
            micro_tdata.mem_width <= w;
            micro_tdata.mem_seg <= seg;
            micro_tdata.mem_addr <= addr;
            micro_tdata.mem_data_src <= MEM_DATA_SRC_ONE;
        end procedure;

        procedure mem_write_shf(seg, addr : std_logic_vector; w : std_logic) is begin
            micro_tdata.mem_cmd <= '1';
            micro_tdata.mem_width <= w;
            micro_tdata.mem_seg <= seg;
            micro_tdata.mem_addr <= addr;
            micro_tdata.mem_data_src <= MEM_DATA_SRC_SHF;
        end procedure;

        procedure mem_write_imm(seg, addr, val : std_logic_vector; w : std_logic) is begin
            micro_tdata.mem_cmd <= '1';
            micro_tdata.mem_width <= w;
            micro_tdata.mem_seg <= seg;
            micro_tdata.mem_addr <= addr;
            micro_tdata.mem_data_src <= MEM_DATA_SRC_IMM;
            micro_tdata.mem_data <= val;
        end procedure;

        procedure do_io_cmd is begin
            micro_tdata.cmd <= MICRO_STR_OP or MICRO_UNLK_OP;

            case rr_tdata.code is
                when IO_IN_IMM => micro_tdata.str_code <= IN_OP;
                when IO_IN_DX =>  micro_tdata.str_code <= IN_OP;
                when IO_INS_IMM => micro_tdata.str_code <= INS_OP;
                when IO_INS_DX => micro_tdata.str_code <= INS_OP;
                when IO_OUT_IMM => micro_tdata.str_code <= OUT_OP;
                when IO_OUT_DX => micro_tdata.str_code <= OUT_OP;
                when IO_OUTS_IMM => micro_tdata.str_code <= OUTS_OP;
                when IO_OUTS_DX => micro_tdata.str_code <= OUTS_OP;
                when others => null;
            end case;

            case rr_tdata.code is
                when IO_IN_IMM => micro_tdata.str_port <= x"00" & rr_tdata.data(7 downto 0);
                when IO_IN_DX =>  micro_tdata.str_port <= rr_tdata.dx_tdata;
                when IO_INS_IMM => micro_tdata.str_port <= x"00" & rr_tdata.data(7 downto 0);
                when IO_INS_DX => micro_tdata.str_port <= rr_tdata.dx_tdata;
                when IO_OUT_IMM => micro_tdata.str_port <= x"00" & rr_tdata.data(7 downto 0);
                when IO_OUT_DX => micro_tdata.str_port <= rr_tdata.dx_tdata;
                when IO_OUTS_IMM => micro_tdata.str_port <= x"00" & rr_tdata.data(7 downto 0);
                when IO_OUTS_DX => micro_tdata.str_port <= rr_tdata.dx_tdata;
                when others => null;
            end case;

            micro_tdata.str_rep <= rep_mode;
            micro_tdata.str_rep_nz <= rep_nz;
            micro_tdata.str_direction <= rr_tdata.fl_tdata(FLAG_DF);
            micro_tdata.str_w <= rr_tdata.w;
            micro_tdata.str_ax_val <= rr_tdata.sreg_val;
            micro_tdata.str_cx_val <= rep_cx_cnt;
            micro_tdata.str_es_val <= rr_tdata.es_seg_val;
            micro_tdata.str_di_val <= rr_tdata.di_tdata;
            micro_tdata.str_ds_val <= rr_tdata.seg_val;
            micro_tdata.str_si_val <= rr_tdata.si_tdata;
        end procedure;

        procedure do_mul_cmd_0 is begin
            micro_tdata.mul_code <= rr_tdata.code;
            micro_tdata.mul_w <= rr_tdata.w;
            micro_tdata.mul_dreg <= rr_tdata.dreg;
            micro_tdata.mul_dmask <= rr_tdata.dmask;
            micro_tdata.mul_a_val <= rr_tdata.sreg_val;

            case rr_tdata.dir is
                when M2R =>
                    micro_tdata.cmd <= MICRO_MEM_OP;
                    mem_read_word(seg => rr_tdata.seg_val, addr => ea_val_plus_disp_next);

                when others =>
                    micro_tdata.cmd <= MICRO_MUL_OP;
            end case;

            case rr_tdata.code is
                when IMUL_RR =>
                    micro_tdata.mul_b_val <= rr_tdata.data;
                when IMUL_AXDX =>
                    if (rr_tdata.w = '0') then
                        for i in 15 downto 8 loop
                            micro_tdata.mul_b_val(i) <= rr_tdata.ax_tdata(7);
                        end loop;
                        micro_tdata.mul_b_val(7 downto 0) <= rr_tdata.ax_tdata(7 downto 0);
                    else
                        micro_tdata.mul_b_val <= rr_tdata.ax_tdata;
                    end if;
                when others => null;
            end case;

        end procedure;

        procedure do_mul_cmd_1 is begin
            micro_tdata.cmd <= MICRO_MUL_OP or MICRO_MRD_OP;
        end procedure;

        procedure do_div_cmd_0 is begin
            micro_tdata.div_code <= rr_tdata.code;
            micro_tdata.div_w <= rr_tdata.w;
            micro_tdata.div_dreg <= rr_tdata.dreg;

            micro_tdata.div_ss_val <= rr_tdata.ss_seg_val;
            micro_tdata.div_ip_val <= rr_tuser(47 downto 32);
            micro_tdata.div_cs_val <= rr_tuser(31 downto 16);
            micro_tdata.div_ip_next_val <= rr_tuser(15 downto 0);

            micro_tdata.div_a_val(15 downto 0) <= rr_tdata.ax_tdata;
            if (rr_tdata.w = '1') then
                micro_tdata.div_a_val(31 downto 16) <= rr_tdata.dx_tdata;
            else
                case rr_tdata.code is
                    when DIVU_IDIV =>
                        micro_tdata.div_a_val(31 downto 16) <= (others => rr_tdata.ax_tdata(15));
                    when others =>
                        micro_tdata.div_a_val(31 downto 16) <= (others => '0');
                end case;
            end if;

            case rr_tdata.code is
                when DIVU_IDIV =>
                    if (rr_tdata.w = '1') then
                        micro_tdata.div_b_val <= rr_tdata.sreg_val;
                    else
                        micro_tdata.div_b_val(15 downto 8) <= (others => rr_tdata.sreg_val(7));
                        micro_tdata.div_b_val(7 downto 0) <= rr_tdata.sreg_val(7 downto 0);
                    end if;
                when DIVU_AAM =>
                    micro_tdata.div_b_val <= rr_tdata.data;
                when others =>
                    micro_tdata.div_b_val <= rr_tdata.sreg_val;
            end case;

            case rr_tdata.dir is
                when M2R =>
                    micro_tdata.cmd <= MICRO_MEM_OP;
                    mem_read_word(seg => rr_tdata.seg_val, addr => ea_val_plus_disp_next);
                when others =>
                    micro_tdata.cmd <= MICRO_DIV_OP or MICRO_UNLK_OP;
            end case;
        end procedure;

        procedure do_div_cmd_1 is begin
            micro_tdata.cmd <= MICRO_DIV_OP or MICRO_MRD_OP or MICRO_UNLK_OP;
        end procedure;

        procedure do_one_cmd_0 is begin
            micro_tdata.one_code <= rr_tdata.code;
            micro_tdata.one_w <= rr_tdata.w;
            micro_tdata.one_dreg <= rr_tdata.dreg;
            micro_tdata.one_dmask <= rr_tdata.dmask;
            micro_tdata.one_ival <= rr_tdata.data;
            micro_tdata.one_sval <= rr_tdata.sreg_val;

            case rr_tdata.dir is
                when M2M =>
                    micro_tdata.cmd <= MICRO_MEM_OP;
                    mem_read(seg => rr_tdata.seg_val, addr => ea_val_plus_disp_next, w => rr_tdata.w);
                    micro_tdata.one_wb <= '0';

                when others =>
                    micro_tdata.cmd <= MICRO_ONE_OP;
                    micro_tdata.one_wb <= '1';
            end case;

        end procedure;

        procedure do_one_cmd_1 is begin
            micro_tdata.cmd <= MICRO_MEM_OP or MICRO_ONE_OP or MICRO_MRD_OP;
            mem_write_one(seg => rr_tdata_buf.seg_val, addr => ea_val_plus_disp, w => rr_tdata_buf.w);
        end procedure;

        procedure do_bcd_cmd is begin
            micro_tdata.cmd <= MICRO_BCD_OP;
            micro_tdata.bcd_code <= rr_tdata.code;
            micro_tdata.bcd_sval <= rr_tdata.sreg_val;
        end procedure;

        procedure do_alu_cmd_0 is begin
            case rr_tdata.dir is
                when M2M =>
                    micro_tdata.cmd <= MICRO_MEM_OP;
                    mem_read(seg => rr_tdata.seg_val, addr => ea_val_plus_disp_next, w => rr_tdata.w);

                when M2R =>
                    micro_tdata.cmd <= MICRO_MEM_OP;
                    mem_read(seg => rr_tdata.seg_val, addr => ea_val_plus_disp_next, w => rr_tdata.w);

                when R2M =>
                    micro_tdata.cmd <= MICRO_MEM_OP;
                    mem_read(seg => rr_tdata.seg_val, addr => ea_val_plus_disp_next, w => rr_tdata.w);

                when I2M =>
                    micro_tdata.cmd <= MICRO_MEM_OP;
                    mem_read(seg => rr_tdata.seg_val, addr => ea_val_plus_disp_next, w => rr_tdata.w);

                when I2R =>
                    micro_tdata.cmd <= MICRO_ALU_OP;

                    micro_tdata.alu_code <= rr_tdata.code;
                    micro_tdata.alu_wb <= '1';
                    micro_tdata.alu_upd_fl <= '1';
                    micro_tdata.alu_a_val <= rr_tdata.dreg_val;
                    micro_tdata.alu_b_val <= rr_tdata.data;
                    micro_tdata.alu_dreg <= rr_tdata.dreg;
                    micro_tdata.alu_dmask <= rr_tdata.dmask;

                when others =>
                    micro_tdata.cmd <= MICRO_ALU_OP;

                    case rr_tdata.code is
                        when ALU_OP_INC | ALU_OP_DEC =>
                            alu_command_imm(cmd => rr_tdata.code,
                                aval => rr_tdata.sreg_val,
                                bval => rr_tdata.data,
                                dreg => rr_tdata.dreg,
                                dmask => rr_tdata.dmask,
                                upd_fl => '1');

                        when others =>
                            alu_command_imm(cmd => rr_tdata.code,
                                aval => rr_tdata.dreg_val,
                                bval => rr_tdata.sreg_val,
                                dreg => rr_tdata.dreg,
                                dmask => rr_tdata.dmask,
                                upd_fl => '1');

                    end case;
            end case;
        end procedure;

        procedure do_alu_cmd_1 is begin
            case rr_tdata_buf.dir is
                when M2M =>
                    micro_tdata.cmd <= MICRO_MEM_OP or MICRO_ALU_OP or MICRO_MRD_OP;

                    micro_tdata.alu_code <= rr_tdata_buf.code;
                    micro_tdata.alu_wb <= '0';
                    micro_tdata.alu_upd_fl <= '1';
                    micro_tdata.alu_a_mem <= '1';
                    micro_tdata.alu_b_val <= rr_tdata_buf.data;
                    micro_tdata.alu_dreg <= rr_tdata_buf.dreg;
                    micro_tdata.alu_dmask <= rr_tdata_buf.dmask;

                    micro_tdata.mem_cmd <= '1';
                    micro_tdata.mem_width <= rr_tdata_buf.w;
                    micro_tdata.mem_seg <= rr_tdata_buf.seg_val;
                    micro_tdata.mem_addr <= ea_val_plus_disp;
                    micro_tdata.mem_data_src <= MEM_DATA_SRC_ALU;

                when M2R =>
                    micro_tdata.cmd <= MICRO_ALU_OP or MICRO_MRD_OP;

                    micro_tdata.alu_code <= rr_tdata_buf.code;
                    micro_tdata.alu_wb <= '1';
                    micro_tdata.alu_upd_fl <= '1';
                    micro_tdata.alu_a_val <= rr_tdata_buf.dreg_val;
                    micro_tdata.alu_b_mem <= '1';
                    micro_tdata.alu_dreg <= rr_tdata_buf.dreg;
                    micro_tdata.alu_dmask <= rr_tdata_buf.dmask;

                when R2M =>
                    if (rr_tdata_buf.code = ALU_OP_CMP or rr_tdata_buf.code = ALU_OP_TST) then
                        micro_tdata.cmd <= MICRO_ALU_OP or MICRO_MRD_OP;
                    else
                        micro_tdata.cmd <= MICRO_MEM_OP or MICRO_ALU_OP or MICRO_MRD_OP;
                    end if;

                    micro_tdata.alu_code <= rr_tdata_buf.code;
                    micro_tdata.alu_wb <= '0';
                    micro_tdata.alu_upd_fl <= '1';
                    micro_tdata.alu_a_mem <= '1';
                    micro_tdata.alu_b_val <= rr_tdata_buf.sreg_val;

                    micro_tdata.mem_cmd <= '1';
                    micro_tdata.mem_width <= rr_tdata_buf.w;
                    micro_tdata.mem_seg <= rr_tdata_buf.seg_val;
                    micro_tdata.mem_addr <= ea_val_plus_disp;
                    micro_tdata.mem_data_src <= MEM_DATA_SRC_ALU;

                when I2M =>
                    if (rr_tdata_buf.code = ALU_OP_CMP or rr_tdata_buf.code = ALU_OP_TST) then
                        micro_tdata.cmd <= MICRO_ALU_OP or MICRO_MRD_OP;
                    else
                        micro_tdata.cmd <= MICRO_MEM_OP or MICRO_ALU_OP or MICRO_MRD_OP;
                    end if;

                    micro_tdata.alu_code <= rr_tdata_buf.code;
                    micro_tdata.alu_wb <= '0';
                    micro_tdata.alu_upd_fl <= '1';
                    micro_tdata.alu_a_mem <= '1';
                    micro_tdata.alu_b_val <= rr_tdata_buf.data;

                    micro_tdata.mem_cmd <= '1';
                    micro_tdata.mem_width <= rr_tdata_buf.w;
                    micro_tdata.mem_seg <= rr_tdata_buf.seg_val;
                    micro_tdata.mem_addr <= ea_val_plus_disp;
                    micro_tdata.mem_data_src <= MEM_DATA_SRC_ALU;

                when others => null;
            end case;
        end procedure;

        procedure do_lfp_cmd_0 is begin
            micro_tdata.cmd <= MICRO_MEM_OP;
            mem_read(seg => rr_tdata.seg_val, addr => ea_val_plus_disp_next, w => rr_tdata.w);
        end procedure;

        procedure do_lfp_cmd_1 is begin
            case micro_cnt is
                when 2 =>
                    micro_tdata.cmd <= MICRO_MEM_OP or MICRO_ALU_OP or MICRO_MRD_OP;

                    micro_tdata.alu_code <= ALU_OP_ADD;
                    micro_tdata.alu_wb <= '1';
                    micro_tdata.alu_upd_fl <= '0';
                    micro_tdata.alu_a_val <= x"0000";
                    micro_tdata.alu_b_mem <= '1';
                    micro_tdata.alu_dreg <= rr_tdata_buf.dreg;
                    micro_tdata.alu_dmask <= rr_tdata_buf.dmask;

                    micro_tdata.mem_cmd <= '0';
                    micro_tdata.mem_seg <= rr_tdata_buf.seg_val;
                    micro_tdata.mem_addr <= ea_val_plus_disp_p_2;

                when 1 =>
                    micro_tdata.cmd <= MICRO_ALU_OP or MICRO_MRD_OP;
                    if (rr_tdata_buf.code = LFP_LDS) then
                        micro_tdata.alu_dreg <= DS;
                    else
                        micro_tdata.alu_dreg <= ES;
                    end if;

                when others => null;
            end case;
        end procedure;

        procedure do_misc_bound_0 is begin
            micro_tdata.cmd <= MICRO_ALU_OP or MICRO_MEM_OP;

            mem_read(seg => rr_tdata.seg_val, addr => ea_val_plus_disp_next, w => rr_tdata.w);
            micro_tdata.bnd_val <= rr_tdata.dreg_val;
            micro_tdata.bnd_ss_val <= rr_tdata.ss_seg_val;
            micro_tdata.bnd_ip_val <= rr_tuser(47 downto 32);
            micro_tdata.bnd_cs_val <= rr_tuser(31 downto 16);
            micro_tdata.bnd_ip_next_val <= rr_tuser(15 downto 0);

            --release dest register
            alu_command_imm(cmd => ALU_OP_ADD,
                aval => rr_tdata.dreg_val,
                bval => x"0000",
                dreg => rr_tdata.dreg,
                dmask => rr_tdata.dmask,
                upd_fl => '0');
        end procedure;

        procedure do_misc_bound_1 is begin
            case micro_cnt is
                when 2 =>
                    micro_tdata.cmd <= MICRO_MEM_OP or MICRO_MRD_OP;
                    micro_tdata.mem_addr <= ea_val_plus_disp_p_2;
                when 1 =>
                    micro_tdata.cmd <= MICRO_BND_OP or MICRO_MRD_OP or MICRO_UNLK_OP;

                when others => null;
            end case;
        end procedure;

        procedure do_shf_cmd_0 is begin
            micro_tdata.shf_code <= rr_tdata.code;
            micro_tdata.shf_w <= rr_tdata.w;
            micro_tdata.shf_dreg <= rr_tdata.dreg;
            micro_tdata.shf_dmask <= rr_tdata.dmask;
            micro_tdata.shf_sval <= rr_tdata.sreg_val;

            case rr_tdata.dir is
                when I2M =>
                    micro_tdata.cmd <= MICRO_MEM_OP;
                    micro_tdata.shf_wb <= '0';
                    mem_read(seg => rr_tdata.seg_val, addr => ea_val_plus_disp_next, w => rr_tdata.w);
                    micro_tdata.shf_ival <= rr_tdata.data;

                when I2R =>
                    micro_tdata.cmd <= MICRO_SHF_OP;
                    micro_tdata.shf_wb <= '1';
                    micro_tdata.shf_ival <= rr_tdata.data;

                when R2R =>
                    micro_tdata.cmd <= MICRO_SHF_OP;
                    micro_tdata.shf_wb <= '1';
                    micro_tdata.shf_ival <= x"00" & rr_tdata.cx_tdata(7 downto 0);

                when others => null;
            end case;

        end procedure;

        procedure do_shf_cmd_1 is begin
            micro_tdata.cmd <= MICRO_SHF_OP or MICRO_MEM_OP or MICRO_MRD_OP;
            mem_write_shf(seg => rr_tdata_buf.seg_val, addr => ea_val_plus_disp, w => rr_tdata_buf.w);
        end procedure;

        procedure do_sys_cmd_int_0 is begin
            micro_tdata.cmd <= MICRO_MEM_OP;
            micro_tdata.jump_cond <= j_never;
            micro_tdata.jump_imm <= '0';
            micro_tdata.jump_cs_mem <= '0';
            micro_tdata.jump_ip_mem <= '0';

            -- push FLAGS
            mem_write_imm(seg => rr_tdata_buf.ss_seg_val, addr => rr_tdata.sp_val, val => rr_tdata.fl_tdata, w => rr_tdata_buf.w);

            sp_val <= rr_tdata.sp_val + rr_tdata.sp_offset;
        end;

        procedure do_sys_cmd_int_1 is begin
            sp_val <= sp_val + rr_tdata_buf.sp_offset;

            case micro_cnt is
                --when 6 =>
                when 5 =>
                    micro_tdata.cmd <= MICRO_MEM_OP or MICRO_FLG_OP;
                    -- TF = 0
                    flag_update(FLAG_TF, CLR);
                    -- push CS
                    mem_write_imm(seg => rr_tdata_buf.ss_seg_val, addr => sp_val, val => rr_tuser_buf(31 downto 16), w => rr_tdata_buf.w);

                when 4 =>
                    micro_tdata.cmd <= MICRO_MEM_OP or MICRO_FLG_OP or MICRO_ALU_OP;
                    flag_update(FLAG_IF, CLR);
                    -- push IP
                    mem_write_imm(seg => rr_tdata_buf.ss_seg_val, addr => sp_val, val => rr_tuser_buf(15 downto 0), w => rr_tdata_buf.w);
                    -- upd SP
                    alu_command_imm(
                        cmd => ALU_OP_ADD,
                        aval => sp_val,
                        bval => x"0000",
                        dreg => SP,
                        dmask => "11",
                        upd_fl => '0');

                when 3 =>
                    -- read CS interrupt handler
                    micro_tdata.cmd <= MICRO_MEM_OP;
                    mem_read_word(seg => x"0000", addr => rr_tdata_buf.data(13 downto 0) & "00");
                when 2 =>
                    micro_tdata.cmd <= MICRO_JMP_OP or MICRO_MRD_OP or MICRO_MEM_OP;
                    -- update jump_cs
                    micro_tdata.jump_cs_mem <= '1';
                    micro_tdata.jump_ip_mem <= '0';
                    -- read IP interrupt handler
                    mem_read_word(seg => x"0000", addr => rr_tdata_buf.data(13 downto 0) & "10");
                when 1 =>
                    micro_tdata.cmd <= MICRO_JMP_OP or MICRO_MRD_OP or MICRO_UNLK_OP;
                    -- upd jump_ip
                    micro_tdata.jump_cs_mem <= '0';
                    micro_tdata.jump_ip_mem <= '1';

                    -- jump
                    micro_tdata.jump_cond <= j_always;

                when others => null;
            end case;
        end;

        procedure do_div_intr_0 is begin
            micro_tdata.cmd <= MICRO_NOP_OP;

            micro_tdata.jump_cond <= j_never;
            micro_tdata.jump_imm <= '0';
            micro_tdata.jump_cs_mem <= '0';
            micro_tdata.jump_ip_mem <= '0';

            sp_val <= rr_tdata_buf.sp_val;
        end;

        procedure do_div_intr_1 is begin
            sp_val <= sp_val + rr_tdata_buf.sp_offset;

            case micro_cnt is
                when 6 =>
                    -- push FLAGS
                    micro_tdata.cmd <= MICRO_MEM_OP;
                    mem_write_imm(seg => rr_tdata_buf.ss_seg_val, addr => sp_val, val => rr_tdata.fl_tdata, w => '1');
                when 5 =>
                    micro_tdata.cmd <= MICRO_MEM_OP or MICRO_FLG_OP;
                    -- TF = 0
                    flag_update(FLAG_TF, CLR);
                    -- push CS
                    mem_write_imm(seg => rr_tdata_buf.ss_seg_val, addr => sp_val, val => rr_tuser_buf(31 downto 16), w => '1');
                when 4 =>
                    micro_tdata.cmd <= MICRO_MEM_OP or MICRO_FLG_OP or MICRO_ALU_OP;
                    flag_update(FLAG_IF, CLR);
                    -- push IP
                    mem_write_imm(seg => rr_tdata_buf.ss_seg_val, addr => sp_val, val => rr_tuser_buf(15 downto 0), w => '1');

                    alu_command_imm(
                        cmd => ALU_OP_ADD,
                        aval => sp_val,
                        bval => x"0000",
                        dreg => SP,
                        dmask => "11",
                        upd_fl => '0');

                when 3 =>
                    micro_tdata.cmd <= MICRO_MEM_OP;
                    -- read CS interrupt handler
                    mem_read_word(seg => x"0000", addr => x"0000");
                when 2 =>
                    micro_tdata.cmd <= MICRO_JMP_OP or MICRO_MRD_OP or MICRO_MEM_OP;
                    -- update jump_cs
                    micro_tdata.jump_cs_mem <= '1';
                    micro_tdata.jump_ip_mem <= '0';
                    -- read IP interrupt handler
                    mem_read_word(seg => x"0000", addr => x"0002");
                when 1 =>
                    micro_tdata.cmd <= MICRO_JMP_OP or MICRO_MRD_OP or MICRO_UNLK_OP;
                    -- upd jump_ip
                    micro_tdata.jump_cs_mem <= '0';
                    micro_tdata.jump_ip_mem <= '1';

                    -- jump
                    micro_tdata.jump_cond <= j_always;

                when others => null;
            end case;
        end;

        procedure do_bnd_intr_0 is begin
            micro_tdata.cmd <= MICRO_NOP_OP;

            micro_tdata.jump_cond <= j_never;
            micro_tdata.jump_imm <= '0';
            micro_tdata.jump_cs_mem <= '0';
            micro_tdata.jump_ip_mem <= '0';

            sp_val <= rr_tdata_buf.sp_val;
        end;

        procedure do_bnd_intr_1 is begin
            sp_val <= sp_val + rr_tdata_buf.sp_offset;

            case micro_cnt is
                when 6 =>
                    micro_tdata.cmd <= MICRO_MEM_OP;
                    -- push FLAGS
                    mem_write_imm(seg => rr_tdata_buf.ss_seg_val, addr => sp_val, val => rr_tdata.fl_tdata, w => '1');
                when 5 =>
                    micro_tdata.cmd <= MICRO_MEM_OP or MICRO_FLG_OP;
                    -- TF = 0
                    flag_update(FLAG_TF, CLR);
                    -- push CS
                    mem_write_imm(seg => rr_tdata_buf.ss_seg_val, addr => sp_val, val => rr_tuser_buf(31 downto 16), w => '1');
                when 4 =>
                    micro_tdata.cmd <= MICRO_MEM_OP or MICRO_FLG_OP or MICRO_ALU_OP;
                    flag_update(FLAG_IF, CLR);
                    -- push IP
                    mem_write_imm(seg => rr_tdata_buf.ss_seg_val, addr => sp_val, val => rr_tuser_buf(15 downto 0), w => '1');

                    alu_command_imm(
                        cmd => ALU_OP_ADD,
                        aval => sp_val,
                        bval => x"0000",
                        dreg => SP,
                        dmask => "11",
                        upd_fl => '0');

                when 3 =>
                    micro_tdata.cmd <= MICRO_MEM_OP;
                    -- read CS interrupt handler
                    mem_read_word(seg => x"0000", addr => x"0014");
                when 2 =>
                    micro_tdata.cmd <= MICRO_JMP_OP or MICRO_MRD_OP or MICRO_MEM_OP;
                    -- update jump_cs
                    micro_tdata.jump_cs_mem <= '1';
                    micro_tdata.jump_ip_mem <= '0';
                    -- read IP interrupt handler
                    mem_read_word(seg => x"0000", addr => x"0016");
                when 1 =>
                    micro_tdata.cmd <= MICRO_JMP_OP or MICRO_MRD_OP or MICRO_UNLK_OP;
                    -- upd jump_ip
                    micro_tdata.jump_cs_mem <= '0';
                    micro_tdata.jump_ip_mem <= '1';

                    -- jump
                    micro_tdata.jump_cond <= j_always;

                when others => null;
            end case;
        end;

        procedure do_sys_cmd_iret_0 is begin
            micro_tdata.cmd <= MICRO_MEM_OP;

            -- jump
            micro_tdata.jump_cond <= j_never;
            micro_tdata.jump_imm <= '0';
            micro_tdata.jump_cs_mem <= '0';
            micro_tdata.jump_ip_mem <= '0';

            mem_read_word(seg => rr_tdata.ss_seg_val, addr => rr_tdata.sp_val);

            sp_val <= rr_tdata.sp_val + rr_tdata.sp_offset;
        end procedure;

        procedure do_sys_cmd_iret_1 is begin
            sp_val <= sp_val + rr_tdata_buf.sp_offset;

            micro_tdata.mem_addr <= sp_val;
            case micro_cnt is
                when 4 =>
                    micro_tdata.cmd <= MICRO_JMP_OP or MICRO_MRD_OP or MICRO_ALU_OP;

                    -- upd SP
                    alu_command_imm(
                        cmd => ALU_OP_ADD,
                        aval => sp_val,
                        bval => x"0000",
                        dreg => SP,
                        dmask => "11",
                        upd_fl => '0');

                    micro_tdata.jump_ip_mem <= '1';
                when 3 =>
                    micro_tdata.cmd <= MICRO_JMP_OP or MICRO_MRD_OP;
                    micro_tdata.jump_ip_mem <= '0';
                    micro_tdata.jump_cs_mem <= '1';
                when 2 =>
                    micro_tdata.cmd <= MICRO_ALU_OP or MICRO_MRD_OP;

                    micro_tdata.jump_cs_mem <= '0';

                    micro_tdata.alu_code <= ALU_OP_ADD;
                    micro_tdata.alu_wb <= '1';
                    micro_tdata.alu_upd_fl <= '1';
                    micro_tdata.alu_a_val <= x"0000";
                    micro_tdata.alu_b_mem <= '1';
                    micro_tdata.alu_dreg <= FL;
                    micro_tdata.alu_dmask <= "11";
                when 1 =>
                    micro_tdata.cmd <= MICRO_JMP_OP or MICRO_UNLK_OP;

                    micro_tdata.jump_cond <= j_always;
                when others => null;
            end case;
        end procedure;

        procedure do_xchg_cmd_0 is begin
            micro_tdata.cmd <= MICRO_MEM_OP or MICRO_ALU_OP;
            -- read value from memory
            mem_read(seg => rr_tdata.seg_val, addr => ea_val_plus_disp_next, w => rr_tdata.w);
            -- put value from register into alu
            alu_put_in_b(rr_tdata.dreg_val);
        end procedure;

        procedure do_xchg_cmd_1 is begin
            micro_tdata.cmd <= MICRO_MEM_OP or MICRO_ALU_OP or MICRO_MRD_OP;
            -- put value from memory into alu and write it to register
            micro_tdata.alu_wb <= '1';
            micro_tdata.alu_upd_fl <= '0';
            micro_tdata.alu_code <= ALU_OP_ADD;
            micro_tdata.alu_a_val <= x"0000";
            micro_tdata.alu_b_mem <= '1';
            micro_tdata.alu_dreg <= rr_tdata_buf.dreg;
            micro_tdata.alu_dmask <= rr_tdata_buf.dmask;
            -- write alu to memory
            mem_write_alu(seg => rr_tdata_buf.seg_val, addr => ea_val_plus_disp, w => rr_tdata_buf.w);
        end procedure;

        procedure do_dbg_cmd_0 is begin
            micro_tdata.cmd <= MICRO_DBG_OP or MICRO_UNLK_OP;
        end procedure;

        procedure do_set_flg_cmd_0 is begin
            micro_tdata.cmd <= MICRO_FLG_OP;
            flag_update(rr_tdata.code, rr_tdata.fl);
        end procedure;

        procedure do_str_cmd is begin
            micro_tdata.cmd <= MICRO_STR_OP;

            micro_tdata.str_code <= rr_tdata.code;
            micro_tdata.str_rep <= rep_mode;
            micro_tdata.str_rep_nz <= rep_nz;
            micro_tdata.str_direction <= rr_tdata.fl_tdata(FLAG_DF);
            micro_tdata.str_w <= rr_tdata.w;
            micro_tdata.str_ax_val <= rr_tdata.sreg_val;
            micro_tdata.str_cx_val <= rep_cx_cnt;
            micro_tdata.str_es_val <= rr_tdata.es_seg_val;
            micro_tdata.str_di_val <= rr_tdata.di_tdata;
            micro_tdata.str_ds_val <= rr_tdata.seg_val;
            micro_tdata.str_si_val <= rr_tdata.si_tdata;
        end procedure;

        procedure do_stack_cmd_0 is begin
            sp_val <= rr_tdata.sp_val + rr_tdata.sp_offset;

            case rr_tdata.code is
                when STACKU_POPR =>
                    micro_tdata.cmd <= MICRO_MEM_OP or MICRO_ALU_OP;

                    -- memory cmd
                    mem_read_word(seg => rr_tdata.ss_seg_val, addr => rr_tdata.sp_val);

                    -- alu cmd
                    alu_command_imm(
                        cmd => ALU_OP_ADD,
                        aval => rr_tdata.sp_val,
                        bval => rr_tdata.sp_offset,
                        dreg => SP,
                        dmask => "11",
                        upd_fl => '0');

                when STACKU_POPM =>
                    micro_tdata.cmd <= MICRO_MEM_OP or MICRO_ALU_OP;

                    -- memory cmd
                    mem_read_word(seg => rr_tdata.ss_seg_val, addr => rr_tdata.sp_val);

                    -- alu cmd
                    alu_command_imm(
                        cmd => ALU_OP_ADD,
                        aval => rr_tdata.sp_val,
                        bval => rr_tdata.sp_offset,
                        dreg => SP,
                        dmask => "11",
                        upd_fl => '0');

                when STACKU_POPA =>
                    micro_tdata.cmd <= MICRO_MEM_OP;

                    -- memory cmd
                    mem_read_word(seg => rr_tdata.ss_seg_val, addr => rr_tdata.sp_val);

                when STACKU_PUSHR =>
                    micro_tdata.cmd <= MICRO_MEM_OP or MICRO_ALU_OP;

                    -- memory cmd
                    mem_write_imm(seg => rr_tdata.ss_seg_val, addr => rr_tdata.sp_val, val => rr_tdata.sreg_val, w => rr_tdata.w);

                    -- alu cmd
                    alu_command_imm(
                        cmd => ALU_OP_ADD,
                        aval => rr_tdata.sp_val,
                        bval => x"0000",
                        dreg => SP,
                        dmask => "11",
                        upd_fl => '0');

                when STACKU_PUSHM =>
                    micro_tdata.cmd <= MICRO_MEM_OP;
                    mem_read_word(seg => rr_tdata.seg_val, addr => ea_val_plus_disp_next);

                when STACKU_PUSHI =>
                    micro_tdata.cmd <= MICRO_MEM_OP or MICRO_ALU_OP;

                    -- memory cmd
                    mem_write_imm(seg => rr_tdata.ss_seg_val, addr => rr_tdata.sp_val, val => rr_tdata.data, w => rr_tdata.w);

                    -- alu cmd
                    alu_command_imm(
                        cmd => ALU_OP_ADD,
                        aval => rr_tdata.sp_val,
                        bval => x"0000",
                        dreg => SP,
                        dmask => "11",
                        upd_fl => '0');

                when STACKU_PUSHA =>
                    micro_tdata.cmd <= MICRO_MEM_OP;

                    micro_tdata.mem_cmd <= '1';
                    micro_tdata.mem_width <= rr_tdata.w;
                    micro_tdata.mem_seg <= rr_tdata.ss_seg_val;
                    micro_tdata.mem_addr <= rr_tdata.sp_val;
                    micro_tdata.mem_data_src <= MEM_DATA_SRC_IMM;
                    micro_tdata.mem_data <= rr_tdata_buf.sreg_val;

                when others => null;
            end case;

        end procedure;

        procedure do_stack_cmd_1 is begin
            sp_val <= sp_val + rr_tdata_buf.sp_offset;

            case rr_tdata_buf.code is
                when STACKU_PUSHM =>
                    micro_tdata.cmd <= MICRO_MEM_OP or MICRO_MRD_OP or MICRO_ALU_OP;

                    -- mem cmd
                    micro_tdata.mem_cmd <= '1';
                    micro_tdata.mem_seg <= rr_tdata_buf.ss_seg_val;
                    micro_tdata.mem_addr <= rr_tdata_buf.sp_val;
                    micro_tdata.mem_data_src <= MEM_DATA_SRC_FIFO;

                    -- alu cmd
                    alu_command_imm(
                        cmd => ALU_OP_ADD,
                        aval => rr_tdata.sp_val,
                        bval => x"0000",
                        dreg => SP,
                        dmask => "11",
                        upd_fl => '0');

                when STACKU_PUSHA =>
                    if (micro_cnt = 1) then
                        micro_tdata.cmd <= MICRO_MEM_OP or MICRO_UNLK_OP or MICRO_ALU_OP;
                    end if;

                    -- alu cmd
                    alu_command_imm(
                        cmd => ALU_OP_ADD,
                        aval => sp_val,
                        bval => x"0000",
                        dreg => SP,
                        dmask => "11",
                        upd_fl => '0');

                    micro_tdata.mem_addr <= sp_val;

                    case micro_cnt is
                        when 7 => micro_tdata.mem_data <= rr_tdata_buf.cx_tdata;
                        when 6 => micro_tdata.mem_data <= rr_tdata_buf.dx_tdata;
                        when 5 => micro_tdata.mem_data <= rr_tdata_buf.bx_tdata;
                        when 4 => micro_tdata.mem_data <= rr_tdata_buf.dreg_val;
                        when 3 => micro_tdata.mem_data <= rr_tdata_buf.bp_tdata;
                        when 2 => micro_tdata.mem_data <= rr_tdata_buf.si_tdata;
                        when 1 => micro_tdata.mem_data <= rr_tdata_buf.di_tdata;
                        when others => null;
                    end case;

                when STACKU_POPR =>
                    micro_tdata.cmd <= MICRO_ALU_OP or MICRO_MRD_OP;

                    micro_tdata.alu_code <= ALU_OP_ADD;
                    micro_tdata.alu_wb <= '1';
                    micro_tdata.alu_upd_fl <= '0';
                    micro_tdata.alu_a_val <= x"0000";
                    micro_tdata.alu_b_mem <= '1';
                    micro_tdata.alu_dreg <= rr_tdata_buf.dreg;
                    micro_tdata.alu_dmask <= rr_tdata_buf.dmask;

                when STACKU_POPM =>
                    micro_tdata.cmd <= MICRO_MRD_OP or MICRO_MEM_OP;

                    micro_tdata.mem_cmd <= '1';
                    micro_tdata.mem_width <= rr_tdata_buf.w;
                    micro_tdata.mem_seg <= rr_tdata_buf.seg_val;
                    micro_tdata.mem_addr <= ea_val_plus_disp;
                    micro_tdata.mem_data_src <= MEM_DATA_SRC_FIFO;

                when STACKU_POPA =>
                    micro_tdata.mem_addr <= sp_val;

                    case micro_cnt is
                        when 15 =>
                            micro_tdata.cmd <= MICRO_MEM_OP;
                            -- READ MEM FROM SP
                            micro_tdata.mem_cmd <= '0';
                            micro_tdata.mem_width <= '1';
                            micro_tdata.mem_seg <= rr_tdata_buf.ss_seg_val;
                        when 9 =>
                            micro_tdata.cmd <= MICRO_ALU_OP or MICRO_MEM_OP;
                            -- alu cmd
                            alu_command_imm(
                                cmd => ALU_OP_ADD,
                                aval => sp_val,
                                bval => rr_tdata_buf.sp_offset,
                                dreg => SP,
                                dmask => "11",
                                upd_fl => '0');

                        when 8 =>
                            micro_tdata.cmd <= MICRO_ALU_OP or MICRO_MRD_OP;

                            micro_tdata.alu_code <= ALU_OP_ADD;
                            micro_tdata.alu_upd_fl <= '0';
                            micro_tdata.alu_wb <= '1';
                            micro_tdata.alu_a_val <= x"0000";
                            micro_tdata.alu_b_mem <= '1';

                            micro_tdata.alu_dreg <= DI;
                            micro_tdata.alu_dmask <= rr_tdata_buf.dmask;
                        when 7 =>
                            micro_tdata.alu_dreg <= SI;
                        when 6 =>
                            micro_tdata.alu_dreg <= BP;
                        when 5 =>
                            micro_tdata.alu_wb <= '0';
                            --micro_tdata.alu_dreg <= SP;
                        when 4 =>
                            micro_tdata.alu_wb <= '1';
                            micro_tdata.alu_dreg <= BX;
                        when 3 =>
                            micro_tdata.alu_dreg <= DX;
                        when 2 =>
                            micro_tdata.alu_dreg <= CX;
                        when 1 =>
                            micro_tdata.alu_dreg <= AX;
                        when others => null;
                    end case;

                when others => null;
            end case;
        end procedure;

        procedure do_stack_enter_0 is begin
            micro_tdata.cmd <= MICRO_NOP_OP;
            sp_val <= rr_tdata.sp_val;
            bp_val <= rr_tdata.bp_tdata;
        end procedure;

        procedure do_stack_enter_1 is begin

            case micro_cnt is
                when 3 =>
                    -- push frame pointer
                    if (rr_tdata_buf.level > 0) then
                        -- push frame_pointer
                        micro_tdata.cmd <= MICRO_MEM_OP;
                        mem_write_imm(seg => rr_tdata_buf.ss_seg_val, addr => sp_val, val => frame_pointer, w => rr_tdata_buf.w);
                    else
                        micro_tdata.cmd <= MICRO_NOP_OP;
                    end if;

                when 2 =>
                    micro_tdata.cmd <= MICRO_ALU_OP;
                    -- BP = frame_pointer
                    alu_command_imm(cmd => ALU_OP_ADD,
                        aval => frame_pointer,
                        bval => x"0000",
                        dreg => BP,
                        dmask => "11",
                        upd_fl => '0');

                when 1 =>
                    -- SP = SP - bytes
                    micro_tdata.cmd <= MICRO_ALU_OP;
                    alu_command_imm(cmd => ALU_OP_SUB,
                        aval => sp_val,
                        bval => rr_tdata_buf.data,
                        dreg => SP,
                        dmask => "11",
                        upd_fl => '0');

                when others =>
                    -- push BP
                    micro_tdata.cmd <= MICRO_MEM_OP;
                    mem_write_imm(seg => rr_tdata_buf.ss_seg_val, addr => sp_val, val => bp_val, w => rr_tdata_buf.w);

                    if not (micro_cnt = 4 and rr_tdata_buf.level = 0) then
                        sp_val <= sp_val + rr_tdata_buf.sp_offset;
                    end if;

                    -- BP = BP - 2
                    if micro_cnt /= 4 then
                        bp_val <= std_logic_vector(unsigned(bp_val) - to_unsigned(2, 16));
                    end if;
                end case;

        end procedure;

        procedure do_stack_leave_0 is begin
            micro_tdata.cmd <= MICRO_MEM_OP or MICRO_ALU_OP;

            mem_read_word(seg => rr_tdata.ss_seg_val, addr => rr_tdata.bp_tdata);
            -- SP = BP;
            micro_tdata.alu_code <= ALU_OP_ADD;
            micro_tdata.alu_wb <= '1';
            micro_tdata.alu_a_val <= x"0002";
            micro_tdata.alu_b_val <= rr_tdata.bp_tdata;
            micro_tdata.alu_upd_fl <= '0';
            micro_tdata.alu_dreg <= SP;
            micro_tdata.alu_dmask <= "11";
        end procedure;

        procedure do_stack_leave_1 is begin
            micro_tdata.cmd <= MICRO_ALU_OP or MICRO_MRD_OP;

            micro_tdata.alu_code <= ALU_OP_ADD;
            micro_tdata.alu_wb <= '1';
            micro_tdata.alu_upd_fl <= '0';
            micro_tdata.alu_a_val <= x"0000";
            micro_tdata.alu_b_mem <= '1';
            micro_tdata.alu_dreg <= rr_tdata_buf.dreg;
            micro_tdata.alu_dmask <= rr_tdata_buf.dmask;
        end procedure;

        procedure do_movu_cmd_0 is begin
            micro_tdata.alu_wb <= '0';

            case rr_tdata.dir is
                when I2M =>
                    micro_tdata.cmd <= MICRO_MEM_OP;

                    micro_tdata.mem_cmd <= '1';
                    micro_tdata.mem_width <= rr_tdata.w;
                    micro_tdata.mem_seg <= rr_tdata.seg_val;
                    micro_tdata.mem_addr <= ea_val_plus_disp_next;
                    micro_tdata.mem_data_src <= MEM_DATA_SRC_IMM;
                    micro_tdata.mem_data <= rr_tdata.data;

                when R2M =>
                    micro_tdata.cmd <= MICRO_MEM_OP;

                    micro_tdata.mem_cmd <= '1';
                    micro_tdata.mem_width <= rr_tdata.w;
                    micro_tdata.mem_seg <= rr_tdata.seg_val;
                    micro_tdata.mem_addr <= ea_val_plus_disp_next;
                    micro_tdata.mem_data_src <= MEM_DATA_SRC_IMM;
                    micro_tdata.mem_data <= rr_tdata.sreg_val;

                when M2R =>
                    micro_tdata.cmd <= MICRO_MEM_OP;

                    micro_tdata.mem_cmd <= '0';
                    micro_tdata.mem_width <= rr_tdata.w;
                    micro_tdata.mem_seg <= rr_tdata.seg_val;
                    micro_tdata.mem_addr <= ea_val_plus_disp_next;

                when R2F =>
                    micro_tdata.cmd <= MICRO_ALU_OP;

                    micro_tdata.alu_wb <= '1';
                    micro_tdata.alu_code <= ALU_OP_ADD;
                    micro_tdata.alu_upd_fl <= '0';
                    micro_tdata.alu_a_val <= rr_tdata.sreg_val;
                    micro_tdata.alu_b_val <= x"0000";
                    micro_tdata.alu_dreg <= rr_tdata.dreg;
                    micro_tdata.alu_dmask <= rr_tdata.dmask;

                when others =>
                    null;
            end case;
        end procedure;

        procedure do_movu_cmd_1 is begin
            micro_tdata.cmd <= MICRO_ALU_OP or MICRO_MRD_OP;

            micro_tdata.alu_code <= ALU_OP_ADD;
            micro_tdata.alu_upd_fl <= '0';
            micro_tdata.alu_wb <= '1';

            micro_tdata.alu_a_val <= x"0000";
            micro_tdata.alu_b_mem <= '1';
            micro_tdata.alu_dreg <= rr_tdata_buf.dreg;
            micro_tdata.alu_dmask <= rr_tdata_buf.dmask;
        end procedure;

        procedure do_loop_cmd_0 is begin
            micro_tdata.cmd <= MICRO_ALU_OP;

            micro_tdata.jump_cond <= j_never;
            micro_tdata.jump_imm <= '0';
            micro_tdata.jump_cs_mem <= '0';
            micro_tdata.jump_ip_mem <= '0';
            micro_tdata.jump_cs <= rr_tuser(31 downto 16);
            micro_tdata.jump_ip <= std_logic_vector(unsigned(rr_tuser(15 downto 0)) + unsigned(rr_tdata.disp));
            micro_tdata.jump_cx <= rr_tdata.sreg_val;

            if (rr_tdata.code = LOOP_OP or rr_tdata.code = LOOP_OP_E or rr_tdata.code = LOOP_OP_NE) then
                -- CX = CX - 1
                alu_command_imm(cmd => ALU_OP_ADD,
                    aval => rr_tdata.sreg_val,
                    bval => rr_tdata.data,
                    dreg => rr_tdata.dreg,
                    dmask => rr_tdata.dmask,
                    upd_fl => '0');

            end if;

        end procedure;

        procedure do_loop_cmd_1 is begin
            micro_tdata.cmd <= MICRO_JMP_OP or MICRO_UNLK_OP;

            micro_tdata.jump_imm <= '1';

            case (rr_tdata_buf.code(1 downto 0)) is
                when LOOP_OP(1 downto 0) =>
                    micro_tdata.jump_cond <= cx_ne_0;
                when LOOP_OP_E(1 downto 0) =>
                    micro_tdata.jump_cond <= cx_ne_0_and_zf;
                when LOOP_OP_NE(1 downto 0) =>
                    micro_tdata.jump_cond <= cx_ne_0_and_nzf;
                when LOOP_JCXZ(1 downto 0) =>
                    micro_tdata.jump_cond <= cx_eq_0;
                when others => null;
            end case;

        end procedure;

        procedure do_bra_cmd is begin
            micro_tdata.cmd <= MICRO_JMP_OP or MICRO_UNLK_OP;

            -- configure jump
            case rr_tdata.code is
                when BRA_JO  => micro_tdata.jump_cond <= j_jo;
                when BRA_JNO => micro_tdata.jump_cond <= j_jno;
                when BRA_JB  => micro_tdata.jump_cond <= j_jb;
                when BRA_JAE => micro_tdata.jump_cond <= j_jae;
                when BRA_JE  => micro_tdata.jump_cond <= j_je;
                when BRA_JNE => micro_tdata.jump_cond <= j_jne;
                when BRA_JBE => micro_tdata.jump_cond <= j_jbe;
                when BRA_JA  => micro_tdata.jump_cond <= j_ja;
                when BRA_JS  => micro_tdata.jump_cond <= j_js;
                when BRA_JNS => micro_tdata.jump_cond <= j_jns;
                when BRA_JP  => micro_tdata.jump_cond <= j_jp;
                when BRA_JNP => micro_tdata.jump_cond <= j_jnp;
                when BRA_JL  => micro_tdata.jump_cond <= j_jl;
                when BRA_JGE => micro_tdata.jump_cond <= j_jge;
                when BRA_JLE => micro_tdata.jump_cond <= j_jle;
                when BRA_JG  => micro_tdata.jump_cond <= j_jg;
                when others => null;
            end case;

            micro_tdata.jump_imm <= '1';
            micro_tdata.jump_cs_mem <= '0';
            micro_tdata.jump_ip_mem <= '0';
            micro_tdata.jump_cs <= rr_tuser(31 downto 16);
            micro_tdata.jump_ip <= std_logic_vector(unsigned(rr_tuser(15 downto 0)) + unsigned(rr_tdata.disp));
        end procedure;

        procedure do_jmp_0 is begin
            case rr_tdata.dir is
                when M2M =>
                    micro_tdata.cmd <= MICRO_MEM_OP;

                    -- configure mem cmd
                    mem_read(seg => rr_tdata.seg_val, addr => ea_val_plus_disp_next, w => rr_tdata.w);

                    -- configure jump
                    micro_tdata.jump_cond <= j_never;
                    micro_tdata.jump_imm <= '0';
                    micro_tdata.jump_cs_mem <= '0';
                    micro_tdata.jump_ip_mem <= '0';

                when others =>
                    micro_tdata.cmd <= MICRO_JMP_OP or MICRO_UNLK_OP;

                    -- configure jump
                    micro_tdata.jump_cond <= j_always;
                    micro_tdata.jump_imm <= '1';
                    micro_tdata.jump_cs_mem <= '0';
                    micro_tdata.jump_ip_mem <= '0';

            end case;

            case rr_tdata.code is
                when JMP_PTR16_16 =>
                    micro_tdata.jump_cs <= rr_tdata.data;
                    micro_tdata.jump_ip <= rr_tdata.disp;
                when JMP_RM16 =>
                    micro_tdata.jump_cs <= rr_tuser(31 downto 16);
                    micro_tdata.jump_ip <= rr_tdata.sreg_val;
                when others =>
                    micro_tdata.jump_cs <= rr_tuser(31 downto 16);
                    micro_tdata.jump_ip <= std_logic_vector(unsigned(rr_tuser(15 downto 0)) + unsigned(rr_tdata.disp));
            end case;

        end procedure;

        procedure do_jmp_1 is begin

            case rr_tdata.code is
                when JMP_RM16 =>
                    micro_tdata.cmd <= MICRO_JMP_OP or MICRO_MRD_OP or MICRO_UNLK_OP;

                    -- update jump cmd
                    micro_tdata.jump_cs_mem <= '0';
                    micro_tdata.jump_ip_mem <= '1';
                    micro_tdata.jump_cond <= j_always;

                when others =>
                    case micro_cnt is
                        when 2 =>
                            micro_tdata.cmd <= MICRO_JMP_OP or MICRO_MRD_OP or MICRO_MEM_OP;
                            -- update mem cmd
                            micro_tdata.mem_addr <= ea_val_plus_disp_p_2;
                            -- upd jump_ip
                            micro_tdata.jump_cs_mem <= '0';
                            micro_tdata.jump_ip_mem <= '1';

                        when 1 =>
                            micro_tdata.cmd <= MICRO_JMP_OP or MICRO_UNLK_OP;

                            -- update jump cmd
                            micro_tdata.jump_cs_mem <= '1';
                            micro_tdata.jump_ip_mem <= '0';
                            micro_tdata.jump_cond <= j_always;

                        when others =>
                            null;
                    end case;

            end case;

        end procedure;

        procedure do_call_ptr16_16_cmd_0 is begin
            sp_val <= rr_tdata.sp_val + rr_tdata.sp_offset;
            micro_tdata.cmd <= MICRO_MEM_OP or MICRO_ALU_OP;

            -- push CS
            mem_write_imm(seg => rr_tdata.ss_seg_val, addr => rr_tdata.sp_val, val => rr_tuser(31 downto 16), w => rr_tdata.w);

            -- upd SP
            alu_command_imm(
                cmd => ALU_OP_ADD,
                aval => rr_tdata.sp_val,
                bval => rr_tdata.sp_offset,
                dreg => SP,
                dmask => "11",
                upd_fl => '0');

            -- jump cmd
            micro_tdata.jump_cond <= j_never;
            micro_tdata.jump_imm <= '0';
            micro_tdata.jump_cs_mem <= '0';
            micro_tdata.jump_ip_mem <= '0';
        end procedure;

        procedure do_call_ptr16_16_cmd_1 is begin
            case micro_cnt is
                when 2 =>
                    micro_tdata.cmd <= MICRO_MEM_OP;
                    -- push IP
                    mem_write_imm(seg => rr_tdata_buf.ss_seg_val, addr => sp_val, val => rr_tuser_buf(15 downto 0), w => rr_tdata_buf.w);

                when 1 =>
                    micro_tdata.cmd <= MICRO_JMP_OP or MICRO_UNLK_OP;
                    micro_tdata.jump_cond <= j_always;
                    micro_tdata.jump_imm <= '1';
                    micro_tdata.jump_cs <= rr_tdata_buf.data;
                    micro_tdata.jump_ip <= rr_tdata_buf.disp;
                when others => null;
            end case;
        end procedure;

        procedure do_call_rel16_cmd_0 is begin
            micro_tdata.cmd <= MICRO_MEM_OP or MICRO_ALU_OP;

            -- push IP
            mem_write_imm(seg => rr_tdata.ss_seg_val, addr => rr_tdata.sp_val, val => rr_tuser(15 downto 0), w => rr_tdata.w);

            -- upd SP
            alu_command_imm(
                cmd => ALU_OP_ADD,
                aval => rr_tdata.sp_val,
                bval => x"0000",
                dreg => SP,
                dmask => "11",
                upd_fl => '0');

            -- jump cmd
            micro_tdata.jump_cond <= j_never;
            micro_tdata.jump_imm <= '0';
            micro_tdata.jump_cs_mem <= '0';
            micro_tdata.jump_ip_mem <= '0';
        end procedure;

        procedure do_call_rel16_cmd_1 is begin
            -- jump cmd
            micro_tdata.jump_cond <= j_always;
            micro_tdata.jump_imm <= '1';
            micro_tdata.jump_cs <= rr_tuser_buf(31 downto 16);
            micro_tdata.jump_ip <= std_logic_vector(unsigned(rr_tuser_buf(15 downto 0)) + unsigned(rr_tdata_buf.disp));

            case micro_cnt is
                when 2 => micro_tdata.cmd <= MICRO_NOP_OP;
                when 1 => micro_tdata.cmd <= MICRO_JMP_OP or MICRO_UNLK_OP;
                when others => null;
            end case;

        end procedure;

        procedure do_call_rm16_cmd_0 is begin
            micro_tdata.cmd <= MICRO_MEM_OP or MICRO_ALU_OP;

            -- push IP
            mem_write_imm(seg => rr_tdata.ss_seg_val, addr => rr_tdata.sp_val, val => rr_tuser(15 downto 0), w => rr_tdata.w);

            -- upd SP
            alu_command_imm(
                cmd => ALU_OP_ADD,
                aval => rr_tdata.sp_val,
                bval => x"0000",
                dreg => SP,
                dmask => "11",
                upd_fl => '0');

            -- jump cmd
            micro_tdata.jump_cond <= j_never;
            micro_tdata.jump_imm <= '0';
            micro_tdata.jump_cs_mem <= '0';
            micro_tdata.jump_ip_mem <= '0';

            micro_tdata.jump_cs <= rr_tuser(31 downto 16);
            micro_tdata.jump_ip <= rr_tdata.sreg_val;
        end procedure;

        procedure do_call_rm16_cmd_1 is begin

            case micro_cnt is
                when 2 =>
                    if (rr_tdata_buf.dir = R2R) then
                        micro_tdata.cmd <= MICRO_NOP_OP;
                    else
                        micro_tdata.cmd <= MICRO_MEM_OP;
                    end if;

                    -- configure mem cmd
                    mem_read(seg => rr_tdata_buf.seg_val, addr => ea_val_plus_disp, w => rr_tdata_buf.w);
                when 1 =>
                    if (rr_tdata_buf.dir = R2R) then
                        micro_tdata.cmd <= MICRO_JMP_OP or MICRO_UNLK_OP;
                    else
                        micro_tdata.cmd <= MICRO_JMP_OP or MICRO_MRD_OP or MICRO_UNLK_OP;
                    end if;

                    -- update jump cmd
                    if (rr_tdata_buf.dir = R2R) then
                        micro_tdata.jump_cond <= j_always;
                        micro_tdata.jump_imm <= '1';
                    else
                        micro_tdata.jump_cs_mem <= '0';
                        micro_tdata.jump_ip_mem <= '1';
                        micro_tdata.jump_cond <= j_always;
                    end if;
                when others =>
                    null;

            end case;

        end procedure;

        procedure do_call_mem16_16_0 is begin
            sp_val <= rr_tdata.sp_val + rr_tdata.sp_offset;
            micro_tdata.cmd <= MICRO_MEM_OP;

            -- push CS
            mem_write_imm(seg => rr_tdata.ss_seg_val, addr => rr_tdata.sp_val, val => rr_tuser(31 downto 16), w => rr_tdata.w);

            -- jump cmd
            micro_tdata.jump_cond <= j_never;
            micro_tdata.jump_imm <= '0';
            micro_tdata.jump_cs_mem <= '0';
            micro_tdata.jump_ip_mem <= '0';
        end procedure;

        procedure do_call_mem16_16_1 is begin
            case micro_cnt is
                when 4 =>
                    micro_tdata.cmd <= MICRO_MEM_OP or MICRO_ALU_OP;
                    -- push IP
                    mem_write_imm(seg => rr_tdata_buf.ss_seg_val, addr => sp_val, val => rr_tuser_buf(15 downto 0), w => rr_tdata_buf.w);

                    -- upd SP
                    alu_command_imm(
                        cmd => ALU_OP_ADD,
                        aval => sp_val,
                        bval => x"0000",
                        dreg => SP,
                        dmask => "11",
                        upd_fl => '0');

                when 3 =>
                    micro_tdata.cmd <= MICRO_MEM_OP;
                    -- configure mem cmd
                    mem_read(seg => rr_tdata_buf.seg_val, addr => ea_val_plus_disp, w => rr_tdata_buf.w);
                when 2 =>
                    micro_tdata.cmd <= MICRO_JMP_OP or MICRO_MRD_OP or MICRO_MEM_OP;
                    -- update mem cmd
                    micro_tdata.mem_addr <= ea_val_plus_disp_p_2;
                    -- upd jump_ip
                    micro_tdata.jump_cs_mem <= '0';
                    micro_tdata.jump_ip_mem <= '1';
                when 1 =>
                    micro_tdata.cmd <= MICRO_JMP_OP or MICRO_MRD_OP or MICRO_UNLK_OP;

                    -- update jump cmd
                    micro_tdata.jump_cs_mem <= '1';
                    micro_tdata.jump_ip_mem <= '0';
                    micro_tdata.jump_cond <= j_always;
                when others => null;
            end case;
        end procedure;

        procedure do_ret_near_cmd_0 is begin
            micro_tdata.cmd <= MICRO_MEM_OP or MICRO_ALU_OP;

            -- pop IP
            mem_read(seg => rr_tdata.seg_val, addr => rr_tdata.sp_val, w => rr_tdata.w);

            -- upd SP
            alu_command_imm(
                cmd => ALU_OP_ADD,
                aval => rr_tdata.sp_val,
                bval => rr_tdata.sp_offset,
                dreg => SP,
                dmask => "11",
                upd_fl => '0');

            -- jump cmd
            micro_tdata.jump_cond <= j_never;
            micro_tdata.jump_imm <= '0';
            micro_tdata.jump_cs_mem <= '0';
            micro_tdata.jump_ip_mem <= '0';
            micro_tdata.jump_cs <= rr_tuser(31 downto 16);
        end procedure;

        procedure do_ret_near_cmd_1 is begin
            micro_tdata.cmd <= MICRO_JMP_OP or MICRO_MRD_OP or MICRO_UNLK_OP;

            -- update jump cmd
            micro_tdata.jump_cs_mem <= '0';
            micro_tdata.jump_ip_mem <= '1';
            micro_tdata.jump_cond <= j_always;
        end procedure;

        procedure do_ret_near_imm16_cmd_0 is begin
            sp_val <= rr_tdata.sp_val + rr_tdata.sp_offset;
            micro_tdata.cmd <= MICRO_NOP_OP;

            -- jump cmd
            micro_tdata.jump_cond <= j_never;
            micro_tdata.jump_imm <= '0';
            micro_tdata.jump_cs_mem <= '0';
            micro_tdata.jump_ip_mem <= '0';
            micro_tdata.jump_cs <= rr_tuser(31 downto 16);
        end procedure;

        procedure do_ret_near_imm16_cmd_1 is begin
            case micro_cnt is
                when 2 =>
                    micro_tdata.cmd <= MICRO_MEM_OP or MICRO_ALU_OP;

                    -- pop IP
                    mem_read(seg => rr_tdata_buf.seg_val, addr => rr_tdata_buf.sp_val, w => rr_tdata_buf.w);

                    -- upd SP
                    alu_command_imm(
                        cmd => ALU_OP_ADD,
                        aval => sp_val,
                        bval => rr_tdata_buf.data,
                        dreg => SP,
                        dmask => "11",
                        upd_fl => '0');

                when 1 =>
                    micro_tdata.cmd <= MICRO_JMP_OP or MICRO_MRD_OP or MICRO_UNLK_OP;

                    -- update jump cmd
                    micro_tdata.jump_cs_mem <= '0';
                    micro_tdata.jump_ip_mem <= '1';
                    micro_tdata.jump_cond <= j_always;

                when others =>
                    null;
            end case;
        end procedure;

        procedure do_ret_far_cmd_0 is begin
            micro_tdata.cmd <= MICRO_MEM_OP;
            sp_val <= rr_tdata.sp_val + rr_tdata.sp_offset;

            -- pop IP
            mem_read(seg => rr_tdata.seg_val, addr => rr_tdata.sp_val, w => rr_tdata.w);

            -- jump cmd
            micro_tdata.jump_cond <= j_never;
            micro_tdata.jump_imm <= '0';
            micro_tdata.jump_cs_mem <= '0';
            micro_tdata.jump_ip_mem <= '0';
        end procedure;

        procedure do_ret_far_cmd_1 is begin
            case micro_cnt is
                when 2 =>
                    micro_tdata.cmd <= MICRO_MEM_OP or MICRO_MRD_OP or MICRO_ALU_OP or MICRO_JMP_OP;

                    -- pop CS
                    mem_read(seg => rr_tdata_buf.seg_val, addr => sp_val, w => rr_tdata_buf.w);

                    -- upd SP
                    alu_command_imm(
                        cmd => ALU_OP_ADD,
                        aval => sp_val,
                        bval => rr_tdata_buf.sp_offset,
                        dreg => SP,
                        dmask => "11",
                        upd_fl => '0');

                    -- update jump cmd
                    micro_tdata.jump_cs_mem <= '0';
                    micro_tdata.jump_ip_mem <= '1';

                when 1 =>
                    micro_tdata.cmd <= MICRO_JMP_OP or MICRO_MRD_OP or MICRO_UNLK_OP;

                    -- update jump cmd
                    micro_tdata.jump_cs_mem <= '1';
                    micro_tdata.jump_ip_mem <= '0';
                    micro_tdata.jump_cond <= j_always;

                when others =>
                    null;
            end case;
        end procedure;

        procedure do_ret_far_imm16_cmd_0 is begin
            micro_tdata.cmd <= MICRO_MEM_OP;
            sp_val <= rr_tdata.sp_val + rr_tdata.sp_offset;

            -- pop IP
            mem_read(seg => rr_tdata.seg_val, addr => rr_tdata.sp_val, w => rr_tdata.w);

            -- jump cmd
            micro_tdata.jump_cond <= j_never;
            micro_tdata.jump_imm <= '0';
            micro_tdata.jump_cs_mem <= '0';
            micro_tdata.jump_ip_mem <= '0';
        end procedure;

        procedure do_ret_far_imm16_cmd_1 is begin
            sp_val <= sp_val + rr_tdata_buf.sp_offset;

            case micro_cnt is
                when 3 =>
                    micro_tdata.cmd <= MICRO_MEM_OP or MICRO_MRD_OP or MICRO_JMP_OP;

                    -- pop CS
                    mem_read(seg => rr_tdata_buf.seg_val, addr => sp_val, w => rr_tdata_buf.w);

                    -- update jump cmd
                    micro_tdata.jump_cs_mem <= '0';
                    micro_tdata.jump_ip_mem <= '1';

                when 2 =>
                    micro_tdata.cmd <= MICRO_JMP_OP or MICRO_MRD_OP or MICRO_ALU_OP;

                    -- upd SP
                    alu_command_imm(
                        cmd => ALU_OP_ADD,
                        aval => sp_val,
                        bval => rr_tdata_buf.data,
                        dreg => SP,
                        dmask => "11",
                        upd_fl => '0');

                    -- update jump cmd
                    micro_tdata.jump_cs_mem <= '1';
                    micro_tdata.jump_ip_mem <= '0';

                when 1 =>
                    micro_tdata.cmd <= MICRO_UNLK_OP or MICRO_JMP_OP;
                    micro_tdata.jump_cond <= j_always;
                    micro_tdata.jump_cs_mem <= '0';
                    micro_tdata.jump_ip_mem <= '0';

                when others =>
                    null;
            end case;
        end procedure;

        procedure initialize_signals is begin
            micro_tdata.alu_a_buf <= '0';
            micro_tdata.alu_a_mem <= '0';
            micro_tdata.alu_b_mem <= '0';
            micro_tdata.alu_w <= rr_tdata.w;
        end procedure;

    begin
        if rising_edge(clk) then
            if (resetn = '0') then
                micro_tvalid <= '0';
                micro_cnt <= 0;
                micro_busy <= '0';
            else

                if (div_intr_s_tvalid = '1' and div_intr_s_tready = '1') or
                   (bnd_intr_s_tvalid = '1' and bnd_intr_s_tready = '1') then
                    micro_tvalid <= '1';
                elsif (rr_tvalid = '1' and rr_tready = '1') then
                    if (rr_tdata.fast_instr = '0' and (rep_mode = '0' or (rep_mode = '1' and rep_cx_cnt /= x"0000"))) then
                        micro_tvalid <= '1';
                    else
                        micro_tvalid <= '0';
                    end if;
                elsif (micro_tready = '1' and micro_cnt = 0) then
                    micro_tvalid <= '0';
                end if;

                if (div_intr_s_tvalid = '1' and div_intr_s_tready = '1') or
                   (bnd_intr_s_tvalid = '1' and bnd_intr_s_tready = '1') then
                    micro_cnt <= 6;
                elsif (rr_tvalid = '1' and rr_tready = '1' and rr_tdata.fast_instr = '0') then
                    micro_cnt <= micro_cnt_next;
                elsif (micro_tvalid = '1' and micro_tready = '1') then
                    if micro_cnt /= 0 then
                        micro_cnt <= micro_cnt - 1;
                    end if;
                end if;

                if (div_intr_s_tvalid = '1' and div_intr_s_tready = '1') or
                   (bnd_intr_s_tvalid = '1' and bnd_intr_s_tready = '1') then
                    micro_busy <= '1';
                elsif (rr_tvalid = '1' and rr_tready = '1') then
                    if (micro_cnt_next = 0) then
                        micro_busy <= '0';
                    else
                        micro_busy <= '1';
                    end if;
                elsif (micro_tvalid = '1' and micro_tready = '1') then
                    if (micro_cnt = 1) then
                        micro_busy <= '0';
                    else
                        micro_busy <= '1';
                    end if;
                end if;

            end if;

            if (rr_tvalid = '1' and rr_tready = '1') then
                frame_pointer <= rr_tdata.sp_val;
            end if;

            if (div_intr_s_tvalid = '1' and div_intr_s_tready = '1') then
                rr_tdata_buf.ss_seg_val <= div_intr_s_tdata(DIV_INTR_T_SS);
                rr_tdata_buf.op <= SYS;
                rr_tdata_buf.code <= SYS_DIV_INT_OP;

                rr_tuser_buf(USER_T_IP) <= div_intr_s_tdata(DIV_INTR_T_IP);
                rr_tuser_buf(USER_T_CS) <= div_intr_s_tdata(DIV_INTR_T_CS);
                rr_tuser_buf(USER_T_IP_NEXT) <= div_intr_s_tdata(DIV_INTR_T_IP_NEXT);
            elsif (bnd_intr_s_tvalid = '1' and bnd_intr_s_tready = '1') then
                rr_tdata_buf.ss_seg_val <= bnd_intr_s_tdata(DIV_INTR_T_SS);
                rr_tdata_buf.op <= SYS;
                rr_tdata_buf.code <= SYS_BND_INT_OP;

                rr_tuser_buf(USER_T_IP) <= bnd_intr_s_tdata(DIV_INTR_T_IP);
                rr_tuser_buf(USER_T_CS) <= bnd_intr_s_tdata(DIV_INTR_T_CS);
                rr_tuser_buf(USER_T_IP_NEXT) <= bnd_intr_s_tdata(DIV_INTR_T_IP_NEXT);
            elsif (rr_tvalid = '1' and rr_tready = '1') then
                rr_tdata_buf <= rr_tdata;
                rr_tuser_buf <= rr_tuser;
            end if;

            if (rr_tvalid = '1' and rr_tready = '1') then
                rr_tuser_buf_ip_next <= std_logic_vector(unsigned(rr_tuser(15 downto 0)) + to_unsigned(1, 16));
                ea_val_plus_disp <= ea_val_plus_disp_next;
            end if;

            if (div_intr_s_tvalid = '1' and div_intr_s_tready = '1') then
                initialize_signals;
                do_div_intr_0;
            elsif (bnd_intr_s_tvalid = '1' and bnd_intr_s_tready = '1') then
                initialize_signals;
                do_bnd_intr_0;
            elsif (rr_tvalid = '1' and rr_tready = '1') then
                initialize_signals;
                micro_tdata.dbg_cs <= rr_tuser(31 downto 16);
                micro_tdata.dbg_ip <= rr_tuser(15 downto 0);

                case (rr_tdata.op) is
                    when ALU => do_alu_cmd_0;
                    when ONEU => do_one_cmd_0;
                    when MULU => do_mul_cmd_0;
                    when DIVU => do_div_cmd_0;
                    when BCDU => do_bcd_cmd;
                    when SHFU => do_shf_cmd_0;
                    when XCHG => do_xchg_cmd_0;
                    when MOVU => do_movu_cmd_0;
                    when DBG => do_dbg_cmd_0;
                    when STR => do_str_cmd;
                    when IO => do_io_cmd;
                    when SET_FLAG => do_set_flg_cmd_0;
                    when LOOPU => do_loop_cmd_0;
                    when JMPU => do_jmp_0;
                    when BRANCH => do_bra_cmd;
                    when LFP =>
                        case rr_tdata.code is
                            when MISC_BOUND => do_misc_bound_0;
                            when others => do_lfp_cmd_0;
                        end case;
                    when STACKU =>
                        case rr_tdata.code is
                            when STACKU_ENTER => do_stack_enter_0;
                            when STACKU_LEAVE => do_stack_leave_0;
                            when others => do_stack_cmd_0;
                        end case;
                    when JCALL =>
                        case rr_tdata.code is
                            when CALL_REL16 => do_call_rel16_cmd_0;
                            when CALL_RM16 => do_call_rm16_cmd_0;
                            when CALL_PTR16_16 => do_call_ptr16_16_cmd_0;
                            when others => do_call_mem16_16_0;
                        end case;
                    when RET =>
                        case rr_tdata.code is
                            when RET_NEAR => do_ret_near_cmd_0;
                            when RET_NEAR_IMM16 => do_ret_near_imm16_cmd_0;
                            when RET_FAR => do_ret_far_cmd_0;
                            when others => do_ret_far_imm16_cmd_0;
                        end case;
                    when SYS =>
                        case rr_tdata.code is
                            when SYS_INT_OP => do_sys_cmd_int_0;
                            when SYS_IRET_OP => do_sys_cmd_iret_0;
                            when others => null;
                        end case;
                    when others => null;
                end case;

            elsif (micro_tvalid = '1' and micro_tready = '1') then
                case rr_tdata_buf.op is
                    when ALU => do_alu_cmd_1;
                    when ONEU => do_one_cmd_1;
                    when MULU => do_mul_cmd_1;
                    when DIVU => do_div_cmd_1;
                    when SHFU => do_shf_cmd_1;
                    when XCHG => do_xchg_cmd_1;
                    when MOVU => do_movu_cmd_1;
                    when LOOPU => do_loop_cmd_1;
                    when JMPU => do_jmp_1;
                    when LFP =>
                        case rr_tdata_buf.code is
                            when MISC_BOUND => do_misc_bound_1;
                            when others => do_lfp_cmd_1;
                        end case;
                    when STACKU =>
                        case rr_tdata_buf.code is
                            when STACKU_ENTER => do_stack_enter_1;
                            when STACKU_LEAVE => do_stack_leave_1;
                            when others => do_stack_cmd_1;
                        end case;
                    when JCALL =>
                        case rr_tdata_buf.code is
                            when CALL_REL16 => do_call_rel16_cmd_1;
                            when CALL_RM16 => do_call_rm16_cmd_1;
                            when CALL_PTR16_16 => do_call_ptr16_16_cmd_1;
                            when others => do_call_mem16_16_1;
                        end case;
                    when RET =>
                        case rr_tdata_buf.code is
                            when RET_NEAR => do_ret_near_cmd_1;
                            when RET_NEAR_IMM16 => do_ret_near_imm16_cmd_1;
                            when RET_FAR => do_ret_far_cmd_1;
                            when others => do_ret_far_imm16_cmd_1;
                        end case;
                    when SYS =>
                        case rr_tdata_buf.code is
                            when SYS_INT_OP => do_sys_cmd_int_1;
                            when SYS_IRET_OP => do_sys_cmd_iret_1;
                            when SYS_BND_INT_OP => do_bnd_intr_1;
                            when SYS_DIV_INT_OP => do_div_intr_1;
                            when others => null;
                        end case;

                    when others => null;
                end case;
            end if;

        end if;
    end process;

end architecture;
