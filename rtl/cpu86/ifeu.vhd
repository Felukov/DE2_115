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
end entity ifeu;

architecture rtl of ifeu is

    constant FLAG_DF            : natural := 10;
    constant FLAG_ZF            : natural := 6;

    signal rr_tvalid            : std_logic;
    signal rr_tready            : std_logic;
    signal rr_tdata             : rr_instr_t;
    signal rr_tuser             : std_logic_vector(31 downto 0);

    signal micro_tvalid         : std_logic;
    signal micro_tready         : std_logic;
    signal micro_cnt            : natural range 0 to 31;
    signal micro_tdata          : micro_op_t;
    signal rr_tdata_buf         : rr_instr_t;
    signal rr_tuser_buf         : std_logic_vector(31 downto 0);
    signal rr_tuser_buf_ip_next : std_logic_vector(15 downto 0);
    signal fast_instruction_fl  : std_logic;

    signal ea_val_plus_disp_next: std_logic_vector(15 downto 0);
    signal ea_val_plus_disp     : std_logic_vector(15 downto 0);

    signal rep_mode             : std_logic;
    signal rep_lock             : std_logic;
    signal rep_code             : std_logic_vector(1 downto 0);
    signal rep_cx_cnt           : std_logic_vector(15 downto 0);

    signal halt_mode            : std_logic;

    signal rep_upd_cx_tvalid    : std_logic;

begin
    rr_tvalid <= rr_s_tvalid;
    rr_s_tready <= rr_tready;
    rr_tdata <= rr_s_tdata;
    rr_tuser <= rr_s_tuser;

    micro_m_tvalid <= micro_tvalid;
    micro_tready <= micro_m_tready;
    micro_m_tdata <= micro_tdata;

    rr_tready <= '1' when jmp_lock_s_tvalid = '1' and rep_lock = '0' and halt_mode = '0' and (micro_tvalid = '0' or
        (micro_tvalid = '1' and micro_tready = '1' and micro_cnt = 0)) else '0';

    fast_instruction_fl <= '1' when (((rr_tdata.op = MOVU or rr_tdata.op = XCHG) and (rr_tdata.dir = R2R or rr_tdata.dir = I2R)) or rr_tdata.op = SYS or rr_tdata.op = REP) else '0';

    jmp_lock_m_lock_tvalid <= '1' when (rr_tvalid = '1' and rr_tready = '1' and (rr_tdata.op = LOOPU or
        (rr_tdata.op = STACKU and rr_tdata.code = STACKU_PUSHA) or rr_tdata.op = DBG)) else '0';

    ea_val_plus_disp_next <= std_logic_vector(unsigned(rr_tdata.ea_val) + unsigned(rr_tdata.disp));

    update_regs_proc : process (all) begin

        ax_m_wr_tvalid <= '0';
        bx_m_wr_tvalid <= '0';
        cx_m_wr_tvalid <= rep_upd_cx_tvalid;
        if rep_upd_cx_tvalid = '1' and rep_mode = '1' then
            cx_m_wr_tkeep_lock <= '1';
        else
            cx_m_wr_tkeep_lock <= '0';
        end if;
        dx_m_wr_tvalid <= '0';
        bp_m_wr_tvalid <= '0';
        sp_m_wr_tvalid <= '0';
        di_m_wr_tvalid <= '0';
        si_m_wr_tvalid <= '0';
        ds_m_wr_tvalid <= '0';
        ss_m_wr_tvalid <= '0';
        es_m_wr_tvalid <= '0';

        if (rr_tvalid = '1' and rr_tready = '1') then

            if ((rr_tdata.op = MOVU or rr_tdata.op = XCHG) and (rr_tdata.dir = R2R or rr_tdata.dir = I2R)) then
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

    update_regs_data_proc : process (all) begin

        ax_m_wr_tdata <= rr_tdata.sreg_val;
        bx_m_wr_tdata <= rr_tdata.sreg_val;
        dx_m_wr_tdata <= rr_tdata.sreg_val;
        bp_m_wr_tdata <= rr_tdata.sreg_val;
        sp_m_wr_tdata <= rr_tdata.sreg_val;
        di_m_wr_tdata <= rr_tdata.sreg_val;
        si_m_wr_tdata <= rr_tdata.sreg_val;
        cx_m_wr_tdata <= rr_tdata.sreg_val;

        if (rr_tdata.op = MOVU and rr_tdata.dir = I2R) then
            ax_m_wr_tdata <= rr_tdata.data;
            bx_m_wr_tdata <= rr_tdata.data;
            dx_m_wr_tdata <= rr_tdata.data;
            bp_m_wr_tdata <= rr_tdata.data;
            sp_m_wr_tdata <= rr_tdata.data;
            di_m_wr_tdata <= rr_tdata.data;
            si_m_wr_tdata <= rr_tdata.data;
            cx_m_wr_tdata <= rr_tdata.data;
        end if;

        if (rr_tdata.op = XCHG and rr_tdata.dir = R2R) then

            case rr_tdata.sreg is
                when AX => ax_m_wr_tdata <= rr_tdata.dreg_val;
                when BX => bx_m_wr_tdata <= rr_tdata.dreg_val;
                when CX => cx_m_wr_tdata <= rr_tdata.dreg_val;
                when DX => dx_m_wr_tdata <= rr_tdata.dreg_val;
                when BP => bp_m_wr_tdata <= rr_tdata.dreg_val;
                when SP => sp_m_wr_tdata <= rr_tdata.dreg_val;
                when DI => di_m_wr_tdata <= rr_tdata.dreg_val;
                when SI => si_m_wr_tdata <= rr_tdata.dreg_val;
                when others => null;
            end case;

        end if;

        if (rep_upd_cx_tvalid = '1') then
            cx_m_wr_tdata <= rep_cx_cnt;
        end if;

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
                rep_upd_cx_tvalid <= '0';
                rep_cx_cnt <= x"0000";
                rep_lock <= '0';
            else
                if (rr_tvalid = '1' and rr_tready = '1' and rr_tdata.op = REP) then
                    rep_mode <= '1';
                elsif rep_mode = '1' and ((rr_tvalid = '1' and rr_tready = '1') or (micro_tvalid = '1' and micro_tready = '1' and micro_cnt = 0)) then
                    if (rep_cx_cnt = x"0001" or rep_cx_cnt = x"0000") then
                        rep_mode <= '0';
                    end if;
                end if;

                if rep_mode = '1' and ((rr_tvalid = '1' and rr_tready = '1') or (micro_tvalid = '1' and micro_tready = '1' and micro_cnt = 0)) then
                    rep_upd_cx_tvalid <= '1';
                else
                    rep_upd_cx_tvalid <= '0';
                end if;

                if (rr_tvalid = '1' and rr_tready = '1' and rr_tdata.op = REP) then
                    rep_cx_cnt <= rr_tdata.sreg_val;
                elsif rep_mode = '1' and rep_cx_cnt /= x"0000" and ((rr_tvalid = '1' and rr_tready = '1') or (micro_tvalid = '1' and micro_tready = '1' and micro_cnt = 0)) then
                    rep_cx_cnt <= std_logic_vector(unsigned(rep_cx_cnt) - to_unsigned(1, 16));
                end if;

                if (rr_tvalid = '1' and rr_tready = '1' and rep_mode = '1' and rep_lock = '0') then
                    if (rep_cx_cnt /= x"0001" and rep_cx_cnt /= x"0000") then
                        rep_lock <= '1';
                    end if;
                elsif rep_mode = '1' and ((rr_tvalid = '1' and rr_tready = '1') or (micro_tvalid = '1' and micro_tready = '1' and micro_cnt = 0)) then
                    if (rep_cx_cnt = x"0001" or rep_cx_cnt = x"0000") then
                        rep_lock <= '0';
                    end if;
                end if;

            end if;
        end if;

    end process;

    micro_cmd_gen_proc : process (clk)
        procedure flag_dont_update is begin
            micro_tdata.cmd(MICRO_OP_CMD_FLG) <= '0';
        end procedure;

        procedure flag_update (flag : std_logic_vector; val : std_logic) is begin
            micro_tdata.cmd(MICRO_OP_CMD_FLG) <= '1';
            micro_tdata.flg_no <= flag;
            micro_tdata.flg_val <= val;
        end procedure;

        procedure alu_command_imm(cmd, aval, bval: std_logic_vector; dreg : reg_t; dmask : std_logic_vector) is begin
            micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '1';
            micro_tdata.alu_code <= cmd;
            micro_tdata.alu_a_val <= aval;
            micro_tdata.alu_b_val <= bval;
            micro_tdata.alu_dreg <= dreg;
            micro_tdata.alu_dmask <= dmask;
            micro_tdata.alu_wb <= '1';
            micro_tdata.alu_keep_lock <= '0';
        end procedure;

        procedure mem_read_word(seg, addr : std_logic_vector) is begin
            micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '1';
            micro_tdata.mem_cmd <= '0';
            micro_tdata.mem_width <= '1';
            micro_tdata.mem_seg <= seg;
            micro_tdata.mem_addr_src <= MEM_ADDR_SRC_EA;
            micro_tdata.mem_addr <= addr;
        end procedure;

    begin
        if rising_edge(clk) then
            if (resetn = '0') then
                micro_tvalid <= '0';
                micro_cnt <= 0;
            else

                if (rr_tvalid = '1' and rr_tready = '1') then
                    if (fast_instruction_fl = '0' and (rep_mode = '0' or (rep_mode = '1' and rep_cx_cnt /= x"0000"))) then
                        micro_tvalid <= '1';
                    else
                        micro_tvalid <= '0';
                    end if;
                elsif (micro_tready = '1' and rep_mode = '0' and micro_cnt = 0) then
                    micro_tvalid <= '0';
                end if;

                if (rr_tvalid = '1' and rr_tready = '1') then
                    case (rr_tdata.op) is
                        when STR =>
                            micro_cnt <= 1;

                        when LOOPU =>
                            micro_cnt <= 1;

                        when STACKU =>
                            case rr_tdata.code is
                                when STACKU_PUSHA => micro_cnt <= 8;
                                when STACKU_POPA => micro_cnt <= 15;
                                when others => micro_cnt <= 1;
                            end case;

                        when MOVU =>
                            case rr_tdata.dir is
                                when M2R => micro_cnt <= 1;
                                when others => micro_cnt <= 0;
                            end case;

                        when ALU =>
                            case rr_tdata.dir is
                                when M2R => micro_cnt <= 1;
                                when R2M => micro_cnt <= 2;
                                when M2M => micro_cnt <= 2;
                                when others => micro_cnt <= 0;
                            end case;

                        when others =>
                            micro_cnt <= 0;
                    end case;

                elsif (micro_tvalid = '1' and micro_tready = '1') then
                    if (micro_cnt = 0 and rep_mode = '1' and rep_cx_cnt >= x"0001") then
                        micro_cnt <= 1;
                    elsif micro_cnt > 0 then
                        micro_cnt <= micro_cnt - 1;
                    end if;
                end if;

            end if;

            if (rr_tvalid = '1' and rr_tready = '1') then
                rr_tdata_buf <= rr_tdata;
                rr_tuser_buf <= rr_tuser;
                rr_tuser_buf_ip_next <= std_logic_vector(unsigned(rr_tuser(15 downto 0)) + to_unsigned(1, 16));
                ea_val_plus_disp <= ea_val_plus_disp_next;
            end if;

            if (rr_tvalid = '1' and rr_tready = '1') then

                micro_tdata.alu_a_acc <= '0';
                micro_tdata.alu_a_mem <= '0';
                micro_tdata.alu_b_mem <= '0';
                micro_tdata.alu_w <= rr_tdata.w;
                micro_tdata.read_fifo <= '0';

                micro_tdata.dbg_cs <= rr_tuser(31 downto 16);
                micro_tdata.dbg_ip <= rr_tuser(15 downto 0);

                case (rr_tdata.op) is
                    when DBG =>
                        micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '0';
                        micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '0';
                        micro_tdata.cmd(MICRO_OP_CMD_JMP) <= '0';
                        micro_tdata.cmd(MICRO_OP_CMD_DBG) <= '1';
                        micro_tdata.alu_wb <= '0';
                        micro_tdata.unlk_fl <= '1';

                    when SET_FLAG =>
                        micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '0';
                        micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '0';
                        micro_tdata.cmd(MICRO_OP_CMD_JMP) <= '0';
                        micro_tdata.cmd(MICRO_OP_CMD_DBG) <= '0';

                        micro_tdata.alu_wb <= '0';
                        micro_tdata.unlk_fl <= '0';

                        flag_update(rr_tdata.code, rr_tdata.w);

                    when STR =>
                        flag_dont_update;
                        micro_tdata.cmd(MICRO_OP_CMD_JMP) <= '0';
                        micro_tdata.cmd(MICRO_OP_CMD_DBG) <= '0';
                        micro_tdata.unlk_fl <= '0';

                        case rr_tdata.code is
                            when MOVS_OP =>
                                micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '1';
                                micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '1';

                                micro_tdata.alu_wb <= '1';
                                if rep_mode = '1' and rep_cx_cnt /= x"0001" then
                                    micro_tdata.alu_keep_lock <= '1';
                                else
                                    micro_tdata.alu_keep_lock <= '0';
                                end if;
                                micro_tdata.alu_code <= ALU_SF_ADD;
                                micro_tdata.alu_a_val <= si_s_tdata;

                                if (flags_s_tdata(FLAG_DF) = '0') then
                                    if (rr_tdata.w = '1') then
                                        micro_tdata.alu_b_val <= x"0002";
                                    else
                                        micro_tdata.alu_b_val <= x"0001";
                                    end if;
                                else
                                    if (rr_tdata.w = '1') then
                                        micro_tdata.alu_b_val <= x"FFFE";
                                    else
                                        micro_tdata.alu_b_val <= x"FFFF";
                                    end if;
                                end if;

                                micro_tdata.alu_dreg <= rr_tdata.sreg;
                                micro_tdata.alu_dmask <= rr_tdata.dmask;

                                -- READ MEM FROM DS:SI
                                micro_tdata.mem_cmd <= '0';
                                micro_tdata.mem_width <= rr_tdata.w;
                                micro_tdata.mem_seg <= rr_tdata.seg_val;
                                micro_tdata.mem_addr_src <= MEM_ADDR_SRC_EA;
                                micro_tdata.mem_addr <= si_s_tdata;
                            when others =>
                                null;
                        end case;
                    when STACKU =>
                        flag_dont_update;
                        micro_tdata.cmd(MICRO_OP_CMD_JMP) <= '0';
                        micro_tdata.cmd(MICRO_OP_CMD_DBG) <= '0';
                        micro_tdata.unlk_fl <= '0';

                        case rr_tdata.code is
                            when STACKU_POPR =>
                                -- SP = SP + 2
                                alu_command_imm(cmd => ALU_SF_ADD,
                                    aval => rr_tdata.dreg_val,
                                    bval => rr_tdata.data,
                                    dreg => rr_tdata.dreg,
                                    dmask => rr_tdata.dmask);

                                -- READ MEM FROM SP
                                mem_read_word(seg =>rr_tdata.ss_seg_val, addr => rr_tdata.dreg_val);

                            when STACKU_POPM =>
                                -- SP = SP + 2
                                alu_command_imm(cmd => ALU_SF_ADD,
                                    aval => rr_tdata.dreg_val,
                                    bval => rr_tdata.data,
                                    dreg => rr_tdata.dreg,
                                    dmask => rr_tdata.dmask);

                                -- READ MEM FROM SP
                                mem_read_word(seg =>rr_tdata.ss_seg_val, addr => rr_tdata.dreg_val);

                            when STACKU_POPA =>
                                micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '1';
                                micro_tdata.alu_wb <= '0';
                                -- SP = SP + 2
                                micro_tdata.alu_code <= ALU_SF_ADD;
                                micro_tdata.alu_a_val <= rr_tdata.dreg_val;
                                micro_tdata.alu_b_val <= rr_tdata.data;
                                micro_tdata.alu_dreg <= rr_tdata.dreg;
                                micro_tdata.alu_dmask <= rr_tdata.dmask;
                                -- READ MEM FROM SP
                                mem_read_word(seg =>rr_tdata.ss_seg_val, addr => rr_tdata.dreg_val);

                            when STACKU_PUSHR =>
                                micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '0';

                                -- SP = SP - 2
                                alu_command_imm(cmd => ALU_SF_ADD,
                                    aval => rr_tdata.dreg_val,
                                    bval => rr_tdata.data,
                                    dreg => rr_tdata.dreg,
                                    dmask => rr_tdata.dmask);

                            when STACKU_PUSHM =>
                                -- SP = SP - 2
                                alu_command_imm(cmd => ALU_SF_ADD,
                                    aval => rr_tdata.dreg_val,
                                    bval => rr_tdata.data,
                                    dreg => rr_tdata.dreg,
                                    dmask => rr_tdata.dmask);

                                -- Read m16 from EA
                                mem_read_word(seg =>rr_tdata.seg_val, addr => ea_val_plus_disp_next);

                            when STACKU_PUSHI =>
                                micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '0';

                                -- SP = SP - 2
                                alu_command_imm(cmd => ALU_SF_ADD,
                                    aval => rr_tdata.dreg_val,
                                    bval =>  x"FFFE",
                                    dreg => rr_tdata.dreg,
                                    dmask => rr_tdata.dmask);

                            when STACKU_PUSHA =>
                                -- SP = SP - 2
                                micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '1';
                                micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '0';
                                micro_tdata.alu_code <= ALU_SF_ADD;
                                micro_tdata.alu_wb <= '0';
                                micro_tdata.alu_a_val <= rr_tdata.dreg_val;
                                micro_tdata.alu_b_val <= rr_tdata.data;
                                micro_tdata.alu_dreg <= rr_tdata.dreg;
                                micro_tdata.alu_dmask <= rr_tdata.dmask;

                            when others => null;
                        end case;

                    when MOVU =>
                        flag_dont_update;
                        micro_tdata.cmd(MICRO_OP_CMD_JMP) <= '0';
                        micro_tdata.cmd(MICRO_OP_CMD_DBG) <= '0';
                        micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '0';
                        micro_tdata.alu_wb <= '0';
                        micro_tdata.unlk_fl <= '0';

                        case rr_tdata.dir is
                            when I2M =>
                                micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '1';

                                micro_tdata.mem_cmd <= '1';
                                micro_tdata.mem_width <= '1';
                                micro_tdata.mem_seg <= rr_tdata.seg_val;
                                micro_tdata.mem_addr_src <= MEM_ADDR_SRC_EA;
                                micro_tdata.mem_addr <= ea_val_plus_disp_next;
                                micro_tdata.mem_data_src <= MEM_DATA_SRC_IMM;
                                micro_tdata.mem_data <= rr_tdata.data;

                            when R2M =>
                                micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '1';

                                micro_tdata.mem_cmd <= '1';
                                micro_tdata.mem_width <= rr_tdata.w;
                                micro_tdata.mem_seg <= rr_tdata.seg_val;
                                micro_tdata.mem_addr_src <= MEM_ADDR_SRC_EA;
                                micro_tdata.mem_addr <= ea_val_plus_disp_next;
                                micro_tdata.mem_data_src <= MEM_DATA_SRC_IMM;
                                micro_tdata.mem_data <= rr_tdata.sreg_val;

                            when M2R =>
                                micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '1';

                                micro_tdata.mem_cmd <= '0';
                                micro_tdata.mem_width <= rr_tdata.w;
                                micro_tdata.mem_seg <= rr_tdata.seg_val;
                                micro_tdata.mem_addr_src <= MEM_ADDR_SRC_EA;
                                micro_tdata.mem_addr <= ea_val_plus_disp_next;

                            when others =>
                                null;
                        end case;

                    when ALU =>
                        flag_dont_update;
                        micro_tdata.cmd(MICRO_OP_CMD_JMP) <= '0';
                        micro_tdata.cmd(MICRO_OP_CMD_DBG) <= '0';
                        micro_tdata.unlk_fl <= '0';

                        case rr_tdata.dir is
                            when M2M =>
                                -- read from memory
                                micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '0';
                                micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '1';
                                micro_tdata.alu_wb <= '0';

                                micro_tdata.mem_cmd <= '0';
                                micro_tdata.mem_width <= rr_tdata.w;
                                micro_tdata.mem_seg <= rr_tdata.seg_val;
                                micro_tdata.mem_addr_src <= MEM_ADDR_SRC_EA;
                                micro_tdata.mem_addr <= ea_val_plus_disp_next;
                            when M2R =>
                                -- read from memory
                                micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '0';
                                micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '1';
                                micro_tdata.alu_wb <= '0';

                                micro_tdata.mem_cmd <= '0';
                                micro_tdata.mem_width <= rr_tdata.w;
                                micro_tdata.mem_seg <= rr_tdata.seg_val;
                                micro_tdata.mem_addr_src <= MEM_ADDR_SRC_EA;
                                micro_tdata.mem_addr <= ea_val_plus_disp_next;

                            when R2M =>
                                -- read from memory
                                micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '0';
                                micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '1';
                                micro_tdata.alu_wb <= '0';

                                micro_tdata.mem_cmd <= '0';
                                micro_tdata.mem_width <= rr_tdata.w;
                                micro_tdata.mem_seg <= rr_tdata.seg_val;
                                micro_tdata.mem_addr_src <= MEM_ADDR_SRC_EA;
                                micro_tdata.mem_addr <= ea_val_plus_disp_next;

                            when I2R =>
                                micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '1';
                                micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '0';

                                micro_tdata.read_fifo <= '0';

                                micro_tdata.alu_code <= rr_tdata.code;
                                micro_tdata.alu_wb <= '1';
                                micro_tdata.alu_keep_lock <= '0';
                                micro_tdata.alu_a_val <= rr_tdata.dreg_val;
                                micro_tdata.alu_b_val <= rr_tdata.data;
                                micro_tdata.alu_dreg <= rr_tdata.dreg;
                                micro_tdata.alu_dmask <= rr_tdata.dmask;

                            when others =>
                                micro_tdata.alu_code <= rr_tdata.code;

                                case rr_tdata.code is
                                    when ALU_OP_INC =>
                                        micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '0';

                                        alu_command_imm(cmd => ALU_SF_ADD,
                                            aval => rr_tdata.sreg_val,
                                            bval => rr_tdata.data,
                                            dreg => rr_tdata.dreg,
                                            dmask => rr_tdata.dmask);

                                    when others =>
                                        micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '0';

                                        alu_command_imm(cmd => ALU_SF_ADD,
                                            aval => rr_tdata.sreg_val,
                                            bval => rr_tdata.dreg_val,
                                            dreg => rr_tdata.dreg,
                                            dmask => rr_tdata.dmask);

                                end case;
                        end case;

                    when LOOPU =>
                        micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '0';
                        micro_tdata.cmd(MICRO_OP_CMD_JMP) <= '0';
                        micro_tdata.cmd(MICRO_OP_CMD_DBG) <= '0';
                        micro_tdata.unlk_fl <= '0';

                        -- CX = CX - 1
                        alu_command_imm(cmd => ALU_SF_ADD,
                            aval => rr_tdata.sreg_val,
                            bval => rr_tdata.data,
                            dreg => rr_tdata.dreg,
                            dmask => rr_tdata.dmask);

                    when others => null;
                end case;

            elsif (micro_tvalid = '1' and micro_tready = '1') then
                --micro_tdata.alu_w <= rr_tdata_buf.w;

                case rr_tdata_buf.op is
                    when STR =>
                        case micro_cnt is
                            when 1 =>
                                micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '1';
                                micro_tdata.read_fifo <= '1';

                                micro_tdata.alu_wb <= '1';
                                if rep_mode = '1' then
                                    micro_tdata.alu_keep_lock <= '1';
                                else
                                    micro_tdata.alu_keep_lock <= '0';
                                end if;
                                micro_tdata.alu_a_val <= di_s_tdata;
                                micro_tdata.alu_dreg <= rr_tdata_buf.dreg;

                                micro_tdata.mem_cmd <= '1';
                                micro_tdata.mem_seg <= rr_tdata_buf.es_seg_val;
                                micro_tdata.mem_addr_src <= MEM_ADDR_SRC_EA;
                                micro_tdata.mem_addr <= di_s_tdata;
                                micro_tdata.mem_data_src <= MEM_DATA_SRC_FIFO;

                            when 0 =>
                                micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '1';
                                micro_tdata.read_fifo <= '0';

                                micro_tdata.alu_wb <= '1';
                                if rep_mode = '1' and rep_cx_cnt /= x"0001" then
                                    micro_tdata.alu_keep_lock <= '1';
                                else
                                    micro_tdata.alu_keep_lock <= '0';
                                end if;
                                micro_tdata.alu_a_val <= si_s_tdata;
                                micro_tdata.alu_dreg <= rr_tdata_buf.sreg;

                                micro_tdata.mem_cmd <= '0';
                                micro_tdata.mem_seg <= rr_tdata_buf.seg_val;
                                micro_tdata.mem_addr_src <= MEM_ADDR_SRC_EA;
                                micro_tdata.mem_addr <= si_s_tdata;

                            when others =>
                                null;
                        end case;

                    when STACKU =>
                        micro_tdata.cmd(MICRO_OP_CMD_JMP) <= '0';
                        case rr_tdata_buf.code is
                            when STACKU_PUSHR =>
                                micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '0';
                                micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '1';
                                micro_tdata.read_fifo <= '0';
                                micro_tdata.alu_wb <= '0';
                                micro_tdata.unlk_fl <= '0';

                                micro_tdata.mem_cmd <= '1';
                                micro_tdata.mem_width <= '1';
                                micro_tdata.mem_seg <= rr_tdata_buf.ss_seg_val;
                                micro_tdata.mem_addr_src <= MEM_ADDR_SRC_ALU;
                                micro_tdata.mem_data_src <= MEM_DATA_SRC_IMM;
                                micro_tdata.mem_data <= rr_tdata_buf.sreg_val;

                            when STACKU_PUSHM =>
                                micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '0';
                                micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '1';
                                micro_tdata.read_fifo <= '1';
                                micro_tdata.alu_wb <= '0';
                                micro_tdata.unlk_fl <= '0';

                                micro_tdata.mem_cmd <= '1';
                                micro_tdata.mem_width <= '1';
                                micro_tdata.mem_seg <= rr_tdata_buf.ss_seg_val;
                                micro_tdata.mem_addr_src <= MEM_ADDR_SRC_ALU;
                                micro_tdata.mem_data_src <= MEM_DATA_SRC_FIFO;

                            when STACKU_PUSHI =>
                                micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '0';
                                micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '1';
                                micro_tdata.read_fifo <= '0';
                                micro_tdata.alu_wb <= '0';
                                micro_tdata.unlk_fl <= '0';

                                micro_tdata.mem_cmd <= '1';
                                micro_tdata.mem_width <= '1';
                                micro_tdata.mem_seg <= rr_tdata_buf.ss_seg_val;
                                micro_tdata.mem_addr_src <= MEM_ADDR_SRC_ALU;
                                micro_tdata.mem_data_src <= MEM_DATA_SRC_IMM;
                                micro_tdata.mem_data <= rr_tdata_buf.data;

                            when STACKU_PUSHA =>
                                micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '1';
                                micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '1';

                                micro_tdata.read_fifo <= '0';

                                micro_tdata.alu_a_acc <= '1';
                                if (micro_cnt = 2) then
                                    micro_tdata.alu_wb <= '1';
                                    micro_tdata.alu_keep_lock <= '0';
                                else
                                    micro_tdata.alu_wb <= '0';
                                end if;

                                if (micro_cnt = 2) then
                                    micro_tdata.unlk_fl <= '1';
                                else
                                    micro_tdata.unlk_fl <= '0';
                                end if;

                                micro_tdata.mem_cmd <= '1';
                                micro_tdata.mem_width <= '1';
                                micro_tdata.mem_seg <= rr_tdata_buf.ss_seg_val;
                                micro_tdata.mem_addr_src <= MEM_ADDR_SRC_ALU;
                                micro_tdata.mem_data_src <= MEM_DATA_SRC_IMM;

                                case micro_cnt is
                                    when 7 => micro_tdata.mem_data <= cx_s_tdata;
                                    when 6 => micro_tdata.mem_data <= dx_s_tdata;
                                    when 5 => micro_tdata.mem_data <= bx_s_tdata;
                                    when 4 => micro_tdata.mem_data <= sp_s_tdata;
                                    when 3 => micro_tdata.mem_data <= bp_s_tdata;
                                    when 2 => micro_tdata.mem_data <= si_s_tdata;
                                    when 1 => micro_tdata.mem_data <= di_s_tdata;
                                    when others => micro_tdata.mem_data <= rr_tdata_buf.sreg_val;
                                end case;

                            when STACKU_POPR =>
                                micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '1';
                                micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '0';

                                micro_tdata.unlk_fl <= '0';
                                micro_tdata.read_fifo <= '1';

                                micro_tdata.alu_code <= ALU_SF_ADD;
                                micro_tdata.alu_wb <= '1';
                                micro_tdata.alu_keep_lock <= '0';
                                micro_tdata.alu_a_val <= x"0000";
                                micro_tdata.alu_b_mem <= '1';
                                micro_tdata.alu_dreg <= rr_tdata_buf.sreg;
                                micro_tdata.alu_dmask <= rr_tdata_buf.dmask;

                            when STACKU_POPM =>
                                micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '0';
                                micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '1';

                                micro_tdata.read_fifo <= '1';
                                micro_tdata.unlk_fl <= '0';

                                micro_tdata.alu_wb <= '0';

                                micro_tdata.mem_cmd <= '1';
                                micro_tdata.mem_width <= rr_tdata_buf.w;
                                micro_tdata.mem_seg <= rr_tdata_buf.seg_val;
                                micro_tdata.mem_addr_src <= MEM_ADDR_SRC_EA;
                                micro_tdata.mem_addr <= ea_val_plus_disp;
                                micro_tdata.mem_data_src <= MEM_DATA_SRC_FIFO;

                            when STACKU_POPA =>
                                micro_tdata.unlk_fl <= '0';

                                case micro_cnt is
                                    when 15 =>
                                        micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '1';
                                        micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '1';

                                        micro_tdata.alu_wb <= '0';
                                        -- SP = SP + 2
                                        micro_tdata.alu_a_acc <= '1';
                                        -- READ MEM FROM SP
                                        micro_tdata.mem_cmd <= '0';
                                        micro_tdata.mem_width <= '1';
                                        micro_tdata.mem_seg <= rr_tdata_buf.ss_seg_val;
                                        micro_tdata.mem_addr_src <= MEM_ADDR_SRC_ALU;
                                    when 9 =>
                                        micro_tdata.alu_wb <= '1';
                                        micro_tdata.alu_keep_lock <= '0';
                                    when 8 =>
                                        micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '1';
                                        micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '0';

                                        micro_tdata.read_fifo <= '1';
                                        micro_tdata.unlk_fl <= '0';

                                        micro_tdata.alu_a_val <= x"0000";
                                        micro_tdata.alu_b_mem <= '1';
                                        micro_tdata.alu_dreg <= DI;
                                        micro_tdata.alu_dmask <= rr_tdata_buf.dmask;
                                        micro_tdata.alu_a_acc <= '0';
                                        micro_tdata.alu_wb <= '1';
                                        micro_tdata.alu_keep_lock <= '0';
                                    when 7 =>
                                        micro_tdata.alu_dreg <= SI;
                                    when 6 =>
                                        micro_tdata.alu_dreg <= BP;
                                    when 5 =>
                                        micro_tdata.alu_wb <= '0';
                                        --micro_tdata.alu_dreg <= SP;
                                    when 4 =>
                                        micro_tdata.alu_wb <= '1';
                                        micro_tdata.alu_keep_lock <= '0';
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


                    when MOVU =>
                        micro_tdata.unlk_fl <= '0';

                        case rr_tdata_buf.dir is
                            when M2R =>
                                micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '1';
                                micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '0';
                                micro_tdata.cmd(MICRO_OP_CMD_JMP) <= '0';

                                micro_tdata.alu_code <= ALU_SF_ADD;
                                micro_tdata.alu_wb <= '1';
                                micro_tdata.alu_keep_lock <= '0';
                                micro_tdata.read_fifo <= '1';

                                micro_tdata.alu_a_val <= x"0000";
                                micro_tdata.alu_b_mem <= '1';
                                micro_tdata.alu_dreg <= rr_tdata_buf.dreg;
                                micro_tdata.alu_dmask <= rr_tdata_buf.dmask;

                            when others => null;
                        end case;

                    when ALU =>
                        micro_tdata.unlk_fl <= '0';

                        case rr_tdata_buf.dir is
                            when M2M =>
                                if (micro_cnt = 2) then
                                    micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '1';
                                    micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '0';
                                    micro_tdata.cmd(MICRO_OP_CMD_JMP) <= '0';

                                    micro_tdata.read_fifo <= '1';

                                    micro_tdata.alu_code <= rr_tdata_buf.code;
                                    micro_tdata.alu_wb <= '0';
                                    micro_tdata.alu_a_mem <= '1';
                                    micro_tdata.alu_b_val <= rr_tdata_buf.data;
                                    micro_tdata.alu_dreg <= rr_tdata_buf.dreg;
                                    micro_tdata.alu_dmask <= rr_tdata_buf.dmask;
                                else
                                    micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '0';
                                    micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '1';
                                    micro_tdata.cmd(MICRO_OP_CMD_JMP) <= '0';

                                    micro_tdata.read_fifo <= '0';

                                    micro_tdata.alu_wb <= '0';
                                    micro_tdata.alu_a_mem <= '0';

                                    micro_tdata.mem_cmd <= '1';
                                    micro_tdata.mem_width <= rr_tdata_buf.w;
                                    micro_tdata.mem_seg <= rr_tdata_buf.seg_val;
                                    micro_tdata.mem_addr_src <= MEM_ADDR_SRC_EA;
                                    micro_tdata.mem_addr <= ea_val_plus_disp;
                                    micro_tdata.mem_data_src <= MEM_DATA_SRC_ALU;
                                    micro_tdata.mem_data <= rr_tdata_buf.sreg_val;
                                end if;
                            when M2R =>
                                micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '1';
                                micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '0';
                                micro_tdata.cmd(MICRO_OP_CMD_JMP) <= '0';

                                micro_tdata.read_fifo <= '1';

                                micro_tdata.alu_code <= rr_tdata_buf.code;
                                micro_tdata.alu_wb <= '1';
                                micro_tdata.alu_keep_lock <= '0';
                                micro_tdata.alu_a_val <= rr_tdata_buf.dreg_val;
                                micro_tdata.alu_b_mem <= '1';
                                micro_tdata.alu_dreg <= rr_tdata_buf.dreg;
                                micro_tdata.alu_dmask <= rr_tdata_buf.dmask;

                            when R2M =>
                                if (micro_cnt = 2) then
                                    micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '1';
                                    micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '0';
                                    micro_tdata.cmd(MICRO_OP_CMD_JMP) <= '0';

                                    micro_tdata.read_fifo <= '1';

                                    micro_tdata.alu_code <= rr_tdata_buf.code;
                                    micro_tdata.alu_wb <= '0';
                                    micro_tdata.alu_a_mem <= '1';
                                    micro_tdata.alu_b_val <= rr_tdata_buf.sreg_val;
                                    micro_tdata.alu_dreg <= rr_tdata_buf.dreg;
                                    micro_tdata.alu_dmask <= rr_tdata_buf.dmask;
                                else
                                    micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '0';
                                    micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '1';
                                    micro_tdata.cmd(MICRO_OP_CMD_JMP) <= '0';
                                    micro_tdata.read_fifo <= '0';
                                    micro_tdata.alu_wb <= '0';

                                    micro_tdata.mem_cmd <= '1';
                                    micro_tdata.mem_width <= rr_tdata_buf.w;
                                    micro_tdata.mem_seg <= rr_tdata_buf.seg_val;
                                    micro_tdata.mem_addr_src <= MEM_ADDR_SRC_EA;
                                    micro_tdata.mem_addr <= ea_val_plus_disp;
                                    micro_tdata.mem_data_src <= MEM_DATA_SRC_ALU;
                                end if;

                            when others => null;
                        end case;

                    when LOOPU =>
                        micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '1';
                        micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '0';
                        micro_tdata.cmd(MICRO_OP_CMD_JMP) <= '1';
                        micro_tdata.alu_wb <= '0';
                        micro_tdata.read_fifo <= '0';

                        micro_tdata.jump_cs <= rr_tuser_buf(31 downto 16);
                        micro_tdata.jump_ip <= std_logic_vector(unsigned(rr_tuser_buf_ip_next) + unsigned(rr_tdata_buf.disp));
                        micro_tdata.unlk_fl <= '1';

                        case (rr_tdata_buf.code(1 downto 0)) is
                            when LOOP_OP(1 downto 0) =>
                                micro_tdata.jump_cond <= cx_ne_0;
                            when LOOP_OP_E(1 downto 0) =>
                                micro_tdata.jump_cond <= cx_ne_0_and_zf;
                            when LOOP_OP_NE(1 downto 0) =>
                                micro_tdata.jump_cond <= cx_ne_0_and_nzf;
                            when others => null;
                        end case;

                    when others => null;
                end case;
            end if;

        end if;
    end process;

end architecture;
