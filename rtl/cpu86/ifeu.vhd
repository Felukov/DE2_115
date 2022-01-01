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

        micro_m_tvalid          : out std_logic;
        micro_m_tready          : in std_logic;
        micro_m_tdata           : out micro_op_t;

        ax_s_tdata              : in std_logic_vector(15 downto 0);
        bx_s_tdata              : in std_logic_vector(15 downto 0);
        cx_s_tdata              : in std_logic_vector(15 downto 0);
        dx_s_tdata              : in std_logic_vector(15 downto 0);
        bp_s_tdata              : in std_logic_vector(15 downto 0);
        sp_s_tdata              : in std_logic_vector(15 downto 0);
        sp_s_tdata_next         : in std_logic_vector(15 downto 0);
        di_s_tdata              : in std_logic_vector(15 downto 0);
        di_s_tdata_next         : in std_logic_vector(15 downto 0);
        si_s_tdata              : in std_logic_vector(15 downto 0);
        si_s_tdata_next         : in std_logic_vector(15 downto 0);

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
    signal rr_tuser             : user_t;

    signal micro_tvalid         : std_logic;
    signal micro_tready         : std_logic;
    signal micro_cnt_next       : natural range 0 to 31;
    signal micro_cnt            : natural range 0 to 31;
    signal micro_busy           : std_logic;
    signal micro_cnt_max        : natural range 0 to 31;
    signal micro_tdata          : micro_op_t;
    signal rr_tdata_buf         : rr_instr_t;
    signal rr_tuser_buf         : user_t;
    signal rr_tuser_buf_ip_next : std_logic_vector(15 downto 0);
    signal fast_instruction_fl  : std_logic;

    signal ea_val_plus_disp_next: std_logic_vector(15 downto 0);
    signal ea_val_plus_disp     : std_logic_vector(15 downto 0);
    signal ea_val_plus_disp_p_2 : std_logic_vector(15 downto 0);

    signal sp_value_next        : std_logic_vector(15 downto 0);

    signal rep_mode             : std_logic;
    signal rep_lock             : std_logic;
    signal rep_code             : std_logic_vector(1 downto 0);
    signal rep_cx_cnt           : natural range 0 to 2**16-1;
    signal rep_nz               : std_logic;
    signal rep_cancel           : std_logic;

    signal halt_mode            : std_logic;

    signal rep_upd_cx_tvalid    : std_logic;
    signal rep_upd_cx_keep_lock : std_logic;

    signal ax_tdata_selector    : std_logic_vector(2 downto 0);
    signal bx_tdata_selector    : std_logic_vector(2 downto 0);
    signal cx_tdata_selector    : std_logic_vector(3 downto 0);
    signal dx_tdata_selector    : std_logic_vector(3 downto 0);
    signal bp_tdata_selector    : std_logic_vector(2 downto 0);
    signal di_tdata_selector    : std_logic_vector(2 downto 0);
    signal si_tdata_selector    : std_logic_vector(2 downto 0);
    signal sp_tdata_selector    : std_logic_vector(2 downto 0);

begin
    rr_tvalid <= rr_s_tvalid;
    rr_s_tready <= rr_tready;
    rr_tdata <= rr_s_tdata;
    rr_tuser <= rr_s_tuser;

    micro_m_tvalid <= micro_tvalid;
    micro_tready <= micro_m_tready;
    micro_m_tdata <= micro_tdata;

    rr_tready <= '1' when div_intr_s_tvalid = '0' and jmp_lock_s_tvalid = '1' and rep_lock = '0' and halt_mode = '0' and (micro_tvalid = '0' or
        (micro_tvalid = '1' and micro_tready = '1' and micro_busy = '0')) else '0';

    div_intr_s_tready <= '1' when jmp_lock_s_tvalid = '1' and rep_lock = '0' and halt_mode = '0' and (micro_tvalid = '0' or
        (micro_tvalid = '1' and micro_tready = '1' and micro_busy = '0')) else '0';

    fast_instruction_fl <= '1' when
        (rr_tdata.op = SYS and rr_tdata.code = SYS_HLT_OP) or
        ((rr_tdata.op = MOVU or rr_tdata.op = XCHG) and (rr_tdata.dir = R2R or rr_tdata.dir = I2R)) or
        (rr_tdata.op = REP) or
        (rr_tdata.op = FEU) else '0';

    jmp_lock_m_lock_tvalid <= '1' when rr_tvalid = '1' and rr_tready = '1' and
        ((rr_tdata.op = LOOPU) or
         (rr_tdata.op = DIVU) or
         (rr_tdata.op = DBG) or
         (rr_tdata.op = STACKU and rr_tdata.code = STACKU_PUSHA) or
         (rr_tdata.op = SYS and (rr_tdata.code = SYS_INT_OP))) else '0';

    ea_val_plus_disp_next <= std_logic_vector(unsigned(rr_tdata.ea_val) + unsigned(rr_tdata.disp));
    ea_val_plus_disp_p_2 <= std_logic_vector(unsigned(ea_val_plus_disp) + unsigned(to_unsigned(2, 16)));

    sp_value_next <= std_logic_vector(unsigned(sp_s_tdata) - unsigned(to_unsigned(2, 16)));

    rep_cancel <= '1' when rr_tdata_buf.code(3) = '1' and ((rep_nz = '0' and flags_s_tdata(FLAG_ZF) = '0') or
        (rep_nz = '1' and flags_s_tdata(FLAG_ZF) = '1')) else '0';

    update_regs_proc : process (all) begin

        ax_m_wr_tvalid <= '0';
        bx_m_wr_tvalid <= '0';
        cx_m_wr_tvalid <= rep_upd_cx_tvalid;
        cx_m_wr_tkeep_lock <= rep_upd_cx_keep_lock;
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
    cx_tdata_selector(3) <= '1' when rep_upd_cx_tvalid = '1' else '0';

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
            when "0001" => cx_m_wr_tdata <= rr_tdata.data;
            when "0010" => cx_m_wr_tdata <= ea_val_plus_disp_next;
            when "0100" => cx_m_wr_tdata <= rr_tdata.dreg_val;
            when "1000" => cx_m_wr_tdata <= std_logic_vector(to_unsigned(rep_cx_cnt, 16));
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
                rep_upd_cx_tvalid <= '0';
                rep_upd_cx_keep_lock <= '0';
                rep_cx_cnt <= 0;
                rep_lock <= '0';
                rep_nz <= '0';
            else

                if (rr_tvalid = '1' and rr_tready = '1' and rr_tdata.op = REP) then
                    rep_mode <= '1';
                elsif rep_mode = '1' and (rr_tvalid = '1' and rr_tready = '1') then
                    if (rep_cx_cnt = 1 or rep_cx_cnt = 0) then
                        rep_mode <= '0';
                    end if;
                elsif rep_mode = '1' and (micro_tvalid = '1' and micro_tready = '1' and micro_cnt = 0) then
                    if (rep_cx_cnt = 1 or rep_cx_cnt = 0 or rep_cancel = '1') then
                        rep_mode <= '0';
                    end if;
                end if;

                if rep_mode = '1' and rr_tvalid = '1' and rr_tready = '1' then
                    rep_upd_cx_tvalid <= '1';
                elsif rep_mode = '1' and micro_tvalid = '1' and micro_tready = '1' and micro_cnt = 0 then
                    rep_upd_cx_tvalid <= '1';
                else
                    rep_upd_cx_tvalid <= '0';
                end if;

                if rep_mode = '1' and rr_tvalid = '1' and rr_tready = '1' then
                    if (rep_cx_cnt /= 1 and rep_cx_cnt /= 0) then
                        rep_upd_cx_keep_lock <= '1';
                    end if;
                elsif rep_mode = '1' and micro_tvalid = '1' and micro_tready = '1' and micro_cnt = 0 then
                    if rep_cx_cnt /= 1 and rep_cx_cnt /= 0 and rep_cancel = '0' then
                        rep_upd_cx_keep_lock <= '1';
                    else
                        rep_upd_cx_keep_lock <= '0';
                    end if;
                else
                    rep_upd_cx_keep_lock <= '0';
                end if;

                if (rr_tvalid = '1' and rr_tready = '1' and rr_tdata.op = REP) then
                    rep_cx_cnt <= to_integer(unsigned(rr_tdata.sreg_val));
                elsif rep_mode = '1' and rep_cx_cnt /= 0 and (rr_tvalid = '1' and rr_tready = '1') then
                    rep_cx_cnt <= rep_cx_cnt - 1;
                elsif rep_mode = '1' and rep_cx_cnt /= 0 and rep_cancel = '0' and (micro_tvalid = '1' and micro_tready = '1' and micro_cnt = 0) then
                    rep_cx_cnt <= rep_cx_cnt - 1;
                end if;

                if (rr_tvalid = '1' and rr_tready = '1' and rep_mode = '1' and rep_lock = '0') then
                    if (rep_cx_cnt /= 1 and rep_cx_cnt /= 0) then
                        rep_lock <= '1';
                    end if;
                elsif rep_mode = '1' and rr_tvalid = '1' and rr_tready = '1' then
                    if (rep_cx_cnt = 1 or rep_cx_cnt = 0) then
                        rep_lock <= '0';
                    end if;
                elsif rep_mode = '1' and (micro_tvalid = '1' and micro_tready = '1' and micro_cnt = 0) then
                    if (rep_cx_cnt = 1 or rep_cx_cnt = 0 or rep_cancel = '1') then
                        rep_lock <= '0';
                    end if;
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
                    when SYS_INT_OP => micro_cnt_next <= 6;
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
                case rr_tdata.DIR is
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

            when STR =>
                case rr_tdata.code is
                    when CMPS_OP => micro_cnt_next <= 6;
                    when SCAS_OP => micro_cnt_next <= 5;
                    when LODS_OP => micro_cnt_next <= 1;
                    when MOVS_OP => micro_cnt_next <= 1;
                    when others => micro_cnt_next <= 0;
                end case;

            when LOOPU =>
                micro_cnt_next <= 1;

            when STACKU =>
                case rr_tdata.code is
                    when STACKU_PUSHA => micro_cnt_next <= 8;
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
                    when others => micro_cnt_next <= 0;
                end case;

            when others =>
                micro_cnt_next <= 0;
        end case;
    end process;

    micro_cmd_gen_proc : process (clk)

        procedure alu_off is begin
            micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '0';
        end procedure;

        procedure one_off is begin
            micro_tdata.cmd(MICRO_OP_CMD_ONE) <= '0';
        end procedure;

        procedure dbg_off is begin
            micro_tdata.cmd(MICRO_OP_CMD_DBG) <= '0';
        end procedure;

        procedure mem_off is begin
            micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '0';
        end procedure;

        procedure jmp_off is begin
            micro_tdata.cmd(MICRO_OP_CMD_JMP) <= '0';
        end procedure;

        procedure fl_off is begin
            micro_tdata.cmd(MICRO_OP_CMD_FLG) <= '0';
        end procedure;

        procedure mul_off is begin
            micro_tdata.cmd(MICRO_OP_CMD_MUL) <= '0';
        end procedure;

        procedure div_off is begin
            micro_tdata.cmd(MICRO_OP_CMD_DIV) <= '0';
        end procedure;

        procedure bcd_off is begin
            micro_tdata.cmd(MICRO_OP_CMD_BCD) <= '0';
        end procedure;

        procedure shf_off is begin
            micro_tdata.cmd(MICRO_OP_CMD_SHF) <= '0';
        end procedure;

        procedure sp_inc_off is begin
            micro_tdata.sp_inc <= '0';
            micro_tdata.sp_keep_lock <= '0';
        end procedure;

        procedure di_inc_off is begin
            micro_tdata.di_inc <= '0';
            micro_tdata.di_keep_lock <= '0';
        end procedure;

        procedure si_inc_off is begin
            micro_tdata.si_inc <= '0';
            micro_tdata.si_keep_lock <= '0';
        end procedure;

        procedure sp_inc_on is begin
            micro_tdata.sp_inc <= '1';
        end procedure;

        procedure di_inc_on is begin
            micro_tdata.di_inc <= '1';
        end procedure;

        procedure si_inc_on is begin
            micro_tdata.si_inc <= '1';
        end procedure;

        procedure flag_update (flag : std_logic_vector; val : fl_action_t) is begin
            micro_tdata.cmd(MICRO_OP_CMD_FLG) <= '1';
            micro_tdata.flg_no <= flag;
            micro_tdata.fl <= val;
        end procedure;

        procedure alu_command_imm(cmd, aval, bval: std_logic_vector; dreg : reg_t; dmask : std_logic_vector) is begin
            micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '1';
            micro_tdata.alu_code <= cmd;
            micro_tdata.alu_a_val <= aval;
            micro_tdata.alu_b_val <= bval;
            micro_tdata.alu_dreg <= dreg;
            micro_tdata.alu_dmask <= dmask;
            micro_tdata.alu_wb <= '1';
        end procedure;

        procedure alu_put_in_b(bval : std_logic_vector) is begin
            micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '1';
            micro_tdata.alu_wb <= '0';
            micro_tdata.alu_code <= ALU_SF_ADD;
            micro_tdata.alu_a_val <= x"0000";
            micro_tdata.alu_b_val <= bval;
        end procedure;

        procedure alu_load_reg_from_mem(dreg : reg_t; dmask : std_logic_vector) is begin
            micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '1';
            micro_tdata.alu_wb <= '1';
            micro_tdata.alu_code <= ALU_SF_ADD;
            micro_tdata.alu_a_val <= x"0000";
            micro_tdata.alu_b_mem <= '1';
            micro_tdata.alu_dreg <= dreg;
            micro_tdata.alu_dmask <= dmask;
        end procedure;

        procedure mem_read_word(seg, addr : std_logic_vector) is begin
            micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '1';
            micro_tdata.mem_cmd <= '0';
            micro_tdata.mem_width <= '1';
            micro_tdata.mem_seg <= seg;
            micro_tdata.mem_addr <= addr;
        end procedure;

        procedure mem_read(seg, addr : std_logic_vector; w : std_logic) is begin
            micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '1';
            micro_tdata.mem_cmd <= '0';
            micro_tdata.mem_width <= w;
            micro_tdata.mem_seg <= seg;
            micro_tdata.mem_addr <= addr;
        end procedure;

        procedure mem_write_alu(seg, addr : std_logic_vector; w : std_logic) is begin
            micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '1';
            micro_tdata.mem_cmd <= '1';
            micro_tdata.mem_width <= w;
            micro_tdata.mem_seg <= seg;
            micro_tdata.mem_addr <= addr;
            micro_tdata.mem_data_src <= MEM_DATA_SRC_ALU;
        end procedure;

        procedure mem_write_one(seg, addr : std_logic_vector; w : std_logic) is begin
            micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '1';
            micro_tdata.mem_cmd <= '1';
            micro_tdata.mem_width <= w;
            micro_tdata.mem_seg <= seg;
            micro_tdata.mem_addr <= addr;
            micro_tdata.mem_data_src <= MEM_DATA_SRC_ONE;
        end procedure;

        procedure mem_write_shf(seg, addr : std_logic_vector; w : std_logic) is begin
            micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '1';
            micro_tdata.mem_cmd <= '1';
            micro_tdata.mem_width <= w;
            micro_tdata.mem_seg <= seg;
            micro_tdata.mem_addr <= addr;
            micro_tdata.mem_data_src <= MEM_DATA_SRC_SHF;
        end procedure;

        procedure mem_write_imm(seg, addr, val : std_logic_vector; w : std_logic) is begin
            micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '1';
            micro_tdata.mem_cmd <= '1';
            micro_tdata.mem_width <= w;
            micro_tdata.mem_seg <= seg;
            micro_tdata.mem_addr <= addr;
            micro_tdata.mem_data_src <= MEM_DATA_SRC_IMM;
            micro_tdata.mem_data <= val;
        end procedure;

        procedure update_si_keep_lock is begin
            if rep_mode = '1' and rep_cx_cnt /= 1 then
                micro_tdata.si_keep_lock <= '1';
            else
                micro_tdata.si_keep_lock <= '0';
            end if;
        end;

        procedure update_di_keep_lock is begin
            if rep_mode = '1' and rep_cx_cnt /= 1 then
                micro_tdata.di_keep_lock <= '1';
            else
                micro_tdata.di_keep_lock <= '0';
            end if;
        end;

        procedure do_mul_cmd_0 is begin
            fl_off; jmp_off; dbg_off; alu_off; one_off; bcd_off; shf_off; div_off;
            sp_inc_off; di_inc_off; si_inc_off;

            micro_tdata.mul_code <= rr_tdata.code;
            micro_tdata.mul_w <= rr_tdata.w;
            micro_tdata.mul_dreg <= rr_tdata.dreg;
            micro_tdata.mul_dmask <= rr_tdata.dmask;

            case rr_tdata.dir is
                when M2R =>
                    mul_off;
                    mem_read_word(seg =>rr_tdata.seg_val, addr => ea_val_plus_disp_next);

                when R2R =>
                    mem_off;
                    micro_tdata.cmd(MICRO_OP_CMD_MUL) <= '1';
                    micro_tdata.mul_a_val <= rr_tdata.sreg_val;

                when others => null;
            end case;

            case rr_tdata.code is
                when IMUL_RR =>
                    micro_tdata.mul_b_val <= rr_tdata.data;
                when IMUL_AXDX =>
                    if (rr_tdata.w = '0') then
                        for i in 15 downto 8 loop
                            micro_tdata.mul_b_val(i) <= ax_s_tdata(7);
                        end loop;
                        micro_tdata.mul_b_val(7 downto 0) <= ax_s_tdata(7 downto 0);
                    else
                        micro_tdata.mul_b_val <= ax_s_tdata;
                    end if;
                when others => null;
            end case;

        end procedure;

        procedure do_mul_cmd_1 is begin
            mem_off;
            micro_tdata.read_fifo <= '1';
            micro_tdata.cmd(MICRO_OP_CMD_MUL) <= '1';
        end procedure;

        procedure do_div_cmd_0 is begin
            fl_off; jmp_off; dbg_off; alu_off; one_off; bcd_off; shf_off; mul_off;
            sp_inc_off; di_inc_off; si_inc_off;

            micro_tdata.div_code <= rr_tdata.code;
            micro_tdata.div_w <= rr_tdata.w;
            micro_tdata.div_dreg <= rr_tdata.dreg;

            micro_tdata.div_ss_val <= rr_tdata.ss_seg_val;
            micro_tdata.div_ip_val <= rr_tuser(47 downto 32);
            micro_tdata.div_cs_val <= rr_tuser(31 downto 16);
            micro_tdata.div_ip_next_val <= rr_tuser(15 downto 0);

            micro_tdata.div_a_val(15 downto 0) <= ax_s_tdata;
            if (rr_tdata.w = '1') then
                micro_tdata.div_a_val(31 downto 16) <= dx_s_tdata;
            else
                case rr_tdata.code is
                    when DIVU_IDIV =>
                        micro_tdata.div_a_val(31 downto 16) <= (others => ax_s_tdata(15));
                    when others =>
                        micro_tdata.div_a_val(31 downto 16) <= (others => '0');
                end case;
            end if;

            case rr_tdata.dir is
                when M2R =>
                    div_off;
                    mem_read_word(seg =>rr_tdata.seg_val, addr => ea_val_plus_disp_next);

                when R2R =>
                    mem_off;
                    micro_tdata.unlk_fl <= '1';
                    micro_tdata.cmd(MICRO_OP_CMD_DIV) <= '1';

                    if (rr_tdata.code = DIVU_IDIV) then
                        if (rr_tdata.w = '1') then
                            micro_tdata.div_b_val <= rr_tdata.sreg_val;
                        else
                            micro_tdata.div_b_val(15 downto 8) <= (others => rr_tdata.sreg_val(7));
                            micro_tdata.div_b_val(7 downto 0) <= rr_tdata.sreg_val(7 downto 0);
                        end if;
                    elsif rr_tdata.code = DIVU_AAM then
                        micro_tdata.div_b_val <= rr_tdata.data;
                    else
                        micro_tdata.div_b_val <= rr_tdata.sreg_val;
                    end if;

                when others => null;
            end case;
        end procedure;

        procedure do_div_cmd_1 is begin
            mem_off;
            micro_tdata.read_fifo <= '1';
            micro_tdata.cmd(MICRO_OP_CMD_DIV) <= '1';
            micro_tdata.unlk_fl <= '1';
        end procedure;

        procedure do_one_cmd_0 is begin
            fl_off; jmp_off; dbg_off; alu_off; mul_off; bcd_off; shf_off; div_off;
            sp_inc_off; di_inc_off; si_inc_off;
            micro_tdata.unlk_fl <= '0';

            micro_tdata.one_code <= rr_tdata.code;
            micro_tdata.one_w <= rr_tdata.w;
            micro_tdata.one_dreg <= rr_tdata.dreg;
            micro_tdata.one_dmask <= rr_tdata.dmask;
            micro_tdata.one_ival <= rr_tdata.data;
            micro_tdata.one_sval <= rr_tdata.sreg_val;

            case rr_tdata.dir is
                when M2M =>
                    one_off;
                    mem_read(seg =>rr_tdata.seg_val, addr => ea_val_plus_disp_next, w => rr_tdata.w);
                    micro_tdata.one_wb <= '0';

                when I2R =>
                    mem_off;
                    micro_tdata.cmd(MICRO_OP_CMD_ONE) <= '1';
                    micro_tdata.one_wb <= '1';

                when R2R =>
                    mem_off;
                    micro_tdata.cmd(MICRO_OP_CMD_ONE) <= '1';
                    micro_tdata.one_wb <= '1';

                when others => null;
            end case;

        end procedure;

        procedure do_one_cmd_1 is begin
            mem_off;
            micro_tdata.read_fifo <= '1';
            micro_tdata.cmd(MICRO_OP_CMD_ONE) <= '1';
            mem_write_one(seg => rr_tdata_buf.seg_val, addr => ea_val_plus_disp, w => rr_tdata_buf.w);
        end procedure;

        procedure do_bcd_cmd is begin
            fl_off; jmp_off; dbg_off; alu_off; mul_off; one_off; shf_off; div_off;
            sp_inc_off; di_inc_off; si_inc_off;
            micro_tdata.unlk_fl <= '0';

            micro_tdata.cmd(MICRO_OP_CMD_BCD) <= '1';
            micro_tdata.bcd_code <= rr_tdata.code;
            micro_tdata.bcd_sval <= rr_tdata.sreg_val;
        end procedure;

        procedure do_alu_cmd_0 is begin
            fl_off; jmp_off; dbg_off; mul_off; one_off; bcd_off; shf_off; div_off;
            sp_inc_off; di_inc_off; si_inc_off;
            micro_tdata.unlk_fl <= '0';

            case rr_tdata.dir is
                when M2M =>
                    alu_off;
                    micro_tdata.alu_wb <= '0';
                    mem_read(seg =>rr_tdata.seg_val, addr => ea_val_plus_disp_next, w => rr_tdata.w);

                when M2R =>
                    alu_off;
                    micro_tdata.alu_wb <= '0';
                    mem_read(seg =>rr_tdata.seg_val, addr => ea_val_plus_disp_next, w => rr_tdata.w);

                when R2M =>
                    alu_off;
                    micro_tdata.alu_wb <= '0';
                    mem_read(seg =>rr_tdata.seg_val, addr => ea_val_plus_disp_next, w => rr_tdata.w);

                when I2R =>
                    micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '1';
                    mem_off;

                    micro_tdata.read_fifo <= '0';

                    micro_tdata.alu_code <= rr_tdata.code;
                    micro_tdata.alu_wb <= '1';
                    micro_tdata.alu_a_val <= rr_tdata.dreg_val;
                    micro_tdata.alu_b_val <= rr_tdata.data;
                    micro_tdata.alu_dreg <= rr_tdata.dreg;
                    micro_tdata.alu_dmask <= rr_tdata.dmask;

                when others =>
                    case rr_tdata.code is
                        when ALU_OP_INC | ALU_OP_DEC =>
                            mem_off;

                            alu_command_imm(cmd => rr_tdata.code,
                                aval => rr_tdata.sreg_val,
                                bval => rr_tdata.data,
                                dreg => rr_tdata.dreg,
                                dmask => rr_tdata.dmask);

                        when others =>
                            mem_off;

                            alu_command_imm(cmd => rr_tdata.code,
                                aval => rr_tdata.dreg_val,
                                bval => rr_tdata.sreg_val,
                                dreg => rr_tdata.dreg,
                                dmask => rr_tdata.dmask);

                    end case;
            end case;
        end procedure;

        procedure do_alu_cmd_1 is begin

            case rr_tdata_buf.dir is
                when M2M =>
                    micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '1';
                    micro_tdata.read_fifo <= '1';
                    micro_tdata.alu_code <= rr_tdata_buf.code;
                    micro_tdata.alu_wb <= '0';
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
                    micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '1';
                    mem_off;

                    micro_tdata.read_fifo <= '1';

                    micro_tdata.alu_code <= rr_tdata_buf.code;
                    micro_tdata.alu_wb <= '1';
                    micro_tdata.alu_a_val <= rr_tdata_buf.dreg_val;
                    micro_tdata.alu_b_mem <= '1';
                    micro_tdata.alu_dreg <= rr_tdata_buf.dreg;
                    micro_tdata.alu_dmask <= rr_tdata_buf.dmask;

                when R2M =>
                    micro_tdata.read_fifo <= '1';

                    micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '1';
                    micro_tdata.alu_code <= rr_tdata_buf.code;
                    micro_tdata.alu_wb <= '0';
                    micro_tdata.alu_a_mem <= '1';
                    micro_tdata.alu_b_val <= rr_tdata_buf.sreg_val;
                    micro_tdata.alu_dreg <= rr_tdata_buf.dreg;
                    micro_tdata.alu_dmask <= rr_tdata_buf.dmask;

                    if (rr_tdata_buf.code = ALU_OP_CMP or rr_tdata_buf.code = ALU_OP_TST) then
                        mem_off;
                    else
                        micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '1';
                    end if;

                    micro_tdata.mem_cmd <= '1';
                    micro_tdata.mem_width <= rr_tdata_buf.w;
                    micro_tdata.mem_seg <= rr_tdata_buf.seg_val;
                    micro_tdata.mem_addr <= ea_val_plus_disp;
                    micro_tdata.mem_data_src <= MEM_DATA_SRC_ALU;

                when others => null;
            end case;
        end procedure;

        procedure do_lfp_cmd_0 is begin
            fl_off; dbg_off; jmp_off; mul_off; one_off; bcd_off; shf_off; alu_off; div_off;
            sp_inc_off; di_inc_off; si_inc_off;
            micro_tdata.unlk_fl <= '0';

            mem_read(seg => rr_tdata.seg_val, addr => ea_val_plus_disp_next, w => rr_tdata.w);
        end procedure;

        procedure do_lfp_cmd_1 is begin
            case micro_cnt is
                when 2 =>
                    micro_tdata.read_fifo <= '1';

                    micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '1';
                    micro_tdata.alu_wb <= '1';
                    micro_tdata.alu_a_val <= x"0000";
                    micro_tdata.alu_b_mem <= '1';
                    micro_tdata.alu_dreg <= rr_tdata_buf.dreg;
                    micro_tdata.alu_dmask <= rr_tdata_buf.dmask;

                    micro_tdata.mem_cmd <= '0';
                    micro_tdata.mem_seg <= rr_tdata_buf.seg_val;
                    micro_tdata.mem_addr <= ea_val_plus_disp_p_2;

                when 1 =>
                    mem_off;

                    if (rr_tdata_buf.code = LFP_LDS) then
                        micro_tdata.alu_dreg <= DS;
                    else
                        micro_tdata.alu_dreg <= ES;
                    end if;
                when others => null;
            end case;
        end procedure;

        procedure do_shf_cmd_0 is begin
            fl_off; dbg_off; jmp_off; mul_off; one_off; bcd_off; alu_off; div_off;
            sp_inc_off; di_inc_off; si_inc_off;
            micro_tdata.unlk_fl <= '0';

            micro_tdata.shf_code <= rr_tdata.code;
            micro_tdata.shf_w <= rr_tdata.w;
            micro_tdata.shf_dreg <= rr_tdata.dreg;
            micro_tdata.shf_dmask <= rr_tdata.dmask;
            micro_tdata.shf_sval <= rr_tdata.sreg_val;

            case rr_tdata.dir is
                when I2M =>
                    shf_off;
                    micro_tdata.shf_wb <= '0';
                    mem_read(seg =>rr_tdata.seg_val, addr => ea_val_plus_disp_next, w => rr_tdata.w);
                    micro_tdata.shf_ival <= rr_tdata.data;

                when I2R =>
                    mem_off;
                    micro_tdata.cmd(MICRO_OP_CMD_SHF) <= '1';
                    micro_tdata.shf_wb <= '1';
                    micro_tdata.shf_ival <= rr_tdata.data;

                when R2R =>
                    mem_off;
                    micro_tdata.cmd(MICRO_OP_CMD_SHF) <= '1';
                    micro_tdata.shf_wb <= '1';
                    micro_tdata.shf_ival <= x"00" & cx_s_tdata(7 downto 0);

                when others => null;
            end case;

        end procedure;

        procedure do_shf_cmd_1 is begin
            micro_tdata.read_fifo <= '1';
            micro_tdata.cmd(MICRO_OP_CMD_SHF) <= '1';
            mem_write_shf(seg => rr_tdata_buf.seg_val, addr => ea_val_plus_disp, w => rr_tdata_buf.w);
        end procedure;

        procedure do_sys_cmd_int_0 is begin
            fl_off; alu_off; jmp_off; dbg_off; mul_off; one_off; bcd_off; shf_off; mem_off; div_off;
            si_inc_off; di_inc_off; sp_inc_on;
            micro_tdata.unlk_fl <= '0';
            micro_tdata.sp_keep_lock <= '1';
        end;

        procedure do_sys_cmd_int_1 is begin
            case micro_cnt is
                when 6 =>
                    -- push FLAGS
                    mem_write_imm(seg => rr_tdata_buf.ss_seg_val, addr => sp_s_tdata_next, val => flags_s_tdata, w => rr_tdata_buf.w);
                when 5 =>
                    -- TF = 0
                    flag_update(std_logic_vector(to_unsigned(FLAG_TF, 4)), CLR);
                    -- push CS
                    mem_write_imm(seg => rr_tdata_buf.ss_seg_val, addr => sp_s_tdata_next, val => rr_tuser_buf(31 downto 16), w => rr_tdata_buf.w);
                when 4 =>
                    flag_update(std_logic_vector(to_unsigned(FLAG_IF, 4)), CLR);
                    -- push IP
                    mem_write_imm(seg => rr_tdata_buf.ss_seg_val, addr => sp_s_tdata_next, val => rr_tuser_buf(15 downto 0), w => rr_tdata_buf.w);
                    sp_inc_off;
                when 3 =>
                    -- read CS interrupt handler
                    mem_read_word(seg => x"0000", addr => rr_tdata_buf.data(13 downto 0) & "00");
                when 2 =>
                    -- update jump_cs
                    micro_tdata.cmd(MICRO_OP_CMD_JMP) <= '1';
                    micro_tdata.read_fifo <= '1';
                    micro_tdata.jump_cs_mem <= '0';
                    micro_tdata.jump_ip_mem <= '1';
                    -- read IP interrupt handler
                    mem_read_word(seg => x"0000", addr => rr_tdata_buf.data(13 downto 0) & "10");
                when 1 =>
                    mem_off;
                    micro_tdata.cmd(MICRO_OP_CMD_JMP) <= '1';
                    -- upd jump_ip
                    micro_tdata.read_fifo <= '1';
                    micro_tdata.jump_cs_mem <= '1';
                    micro_tdata.jump_ip_mem <= '0';
                    micro_tdata.unlk_fl <= '1';
                    -- jump
                    micro_tdata.jump_cond <= j_always;

                when others => null;
            end case;
        end;

        procedure do_div_intr_0 is begin
            fl_off; alu_off; jmp_off; dbg_off; mul_off; one_off; bcd_off; shf_off; mem_off; div_off;
            si_inc_off; di_inc_off;
            sp_inc_on;
            micro_tdata.sp_inc_data <= x"FFFE";

            micro_tdata.unlk_fl <= '0';
            micro_tdata.sp_keep_lock <= '1';
        end;

        procedure do_div_intr_1 is begin
            case micro_cnt is
                when 6 =>
                    -- push FLAGS
                    mem_write_imm(seg => rr_tdata_buf.ss_seg_val, addr => sp_s_tdata_next, val => flags_s_tdata, w => '1');
                when 5 =>
                    -- TF = 0
                    flag_update(std_logic_vector(to_unsigned(FLAG_TF, 4)), CLR);
                    -- push CS
                    mem_write_imm(seg => rr_tdata_buf.ss_seg_val, addr => sp_s_tdata_next, val => rr_tuser_buf(31 downto 16), w => '1');
                when 4 =>
                    flag_update(std_logic_vector(to_unsigned(FLAG_IF, 4)), CLR);
                    -- push IP
                    mem_write_imm(seg => rr_tdata_buf.ss_seg_val, addr => sp_s_tdata_next, val => rr_tuser_buf(15 downto 0), w => '1');
                    sp_inc_off;
                when 3 =>
                    -- read CS interrupt handler
                    mem_read_word(seg => x"0000", addr => x"0000");
                when 2 =>
                    -- update jump_cs
                    micro_tdata.cmd(MICRO_OP_CMD_JMP) <= '1';
                    micro_tdata.read_fifo <= '1';
                    micro_tdata.jump_cs_mem <= '0';
                    micro_tdata.jump_ip_mem <= '1';
                    -- read IP interrupt handler
                    mem_read_word(seg => x"0000", addr => x"0002");
                when 1 =>
                    mem_off;
                    micro_tdata.cmd(MICRO_OP_CMD_JMP) <= '1';
                    -- upd jump_ip
                    micro_tdata.read_fifo <= '1';
                    micro_tdata.jump_cs_mem <= '1';
                    micro_tdata.jump_ip_mem <= '0';
                    micro_tdata.unlk_fl <= '1';
                    -- jump
                    micro_tdata.jump_cond <= j_always;

                when others => null;
            end case;
        end;

        procedure do_sys_cmd_iret_0 is begin
            fl_off; alu_off; jmp_off; dbg_off; mul_off; one_off; bcd_off; shf_off; mem_off; div_off;
            si_inc_off; di_inc_off; sp_inc_on;
            micro_tdata.sp_keep_lock <= '1';
            micro_tdata.unlk_fl <= '0';

            mem_read_word(seg =>rr_tdata.ss_seg_val, addr => sp_s_tdata);
        end procedure;

        procedure do_sys_cmd_iret_1 is begin
            micro_tdata.mem_addr <= sp_s_tdata_next;
            case micro_cnt is
                when 4 =>
                    micro_tdata.sp_keep_lock <= '0';
                    mem_off;
                    sp_inc_off;
                    micro_tdata.read_fifo <= '1';
                    micro_tdata.cmd(MICRO_OP_CMD_JMP) <= '1';
                    micro_tdata.jump_ip_mem <= '1';
                when 3 =>
                    micro_tdata.jump_ip_mem <= '0';
                    micro_tdata.jump_cs_mem <= '1';
                when 2 =>
                    micro_tdata.cmd(MICRO_OP_CMD_JMP) <= '0';
                    micro_tdata.jump_cs_mem <= '0';
                    micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '1';
                    micro_tdata.alu_code <= ALU_SF_ADD;
                    micro_tdata.alu_wb <= '1';
                    micro_tdata.alu_a_val <= x"0000";
                    micro_tdata.alu_b_mem <= '1';
                    micro_tdata.alu_dreg <= FL;
                    micro_tdata.alu_dmask <= "11";
                when 1 =>
                    micro_tdata.read_fifo <= '0';
                    micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '0';
                    micro_tdata.cmd(MICRO_OP_CMD_JMP) <= '1';
                    micro_tdata.unlk_fl <= '1';
                    micro_tdata.jump_cond <= j_always;
                when others => null;
            end case;
        end procedure;

        procedure do_xchg_cmd_0 is begin
            fl_off; dbg_off; jmp_off; mul_off; one_off; bcd_off; shf_off; div_off;
            sp_inc_off; di_inc_off; si_inc_off;
            micro_tdata.unlk_fl <= '0';

            -- read value from memory
            mem_read(seg => rr_tdata.seg_val, addr => ea_val_plus_disp_next, w => rr_tdata.w);
            -- put value from register into alu
            alu_put_in_b(rr_tdata.dreg_val);
        end procedure;

        procedure do_xchg_cmd_1 is begin
            micro_tdata.read_fifo <= '1';

            -- put value from memory into alu and write it to register
            micro_tdata.alu_wb <= '1';
            micro_tdata.alu_code <= ALU_SF_ADD;
            micro_tdata.alu_a_val <= x"0000";
            micro_tdata.alu_b_mem <= '1';
            micro_tdata.alu_dreg <= rr_tdata_buf.dreg;
            micro_tdata.alu_dmask <= rr_tdata_buf.dmask;
            -- write alu to memory
            mem_write_alu(seg => rr_tdata_buf.seg_val, addr => ea_val_plus_disp, w => rr_tdata_buf.w);
        end procedure;

        procedure do_dbg_cmd_0 is begin
            fl_off; alu_off; jmp_off; mem_off; mul_off; one_off; bcd_off; shf_off; div_off;
            sp_inc_off; di_inc_off; si_inc_off;
            micro_tdata.cmd(MICRO_OP_CMD_DBG) <= '1';
            micro_tdata.unlk_fl <= '1';
            micro_tdata.alu_wb <= '0';
        end procedure;

        procedure do_set_flg_cmd_0 is begin
            alu_off; jmp_off; dbg_off; mem_off; mul_off; one_off; bcd_off; shf_off; div_off;
            sp_inc_off; di_inc_off; si_inc_off;
            micro_tdata.unlk_fl <= '0';

            micro_tdata.alu_wb <= '0';

            flag_update(rr_tdata.code, rr_tdata.fl);
        end procedure;

        procedure do_str_cmd_0 is begin
            fl_off; alu_off; jmp_off; dbg_off; mul_off; one_off; bcd_off; shf_off; div_off; sp_inc_off;
            micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '1';
            micro_tdata.alu_wb <= '0';
            micro_tdata.unlk_fl <= '0';

            case rr_tdata.code is
                when LODS_OP =>
                    di_inc_off; si_inc_on;
                    update_si_keep_lock;
                    mem_read(seg => rr_tdata.seg_val, addr => si_s_tdata, w =>  rr_tdata.w);

                when CMPS_OP =>
                    di_inc_off; si_inc_on;
                    update_si_keep_lock;
                    mem_read(seg => rr_tdata.seg_val, addr => si_s_tdata, w =>  rr_tdata.w);

                when MOVS_OP =>
                    di_inc_off; si_inc_on;
                    update_si_keep_lock;
                    mem_read(seg => rr_tdata.seg_val, addr => si_s_tdata, w =>  rr_tdata.w);

                when SCAS_OP =>
                    si_inc_off; di_inc_on;
                    update_di_keep_lock;
                    mem_read(seg => rr_tdata.es_seg_val, addr => di_s_tdata, w =>  rr_tdata.w);

                when STOS_OP =>
                    si_inc_off; di_inc_on;
                    update_di_keep_lock;
                    mem_write_imm(seg => rr_tdata.es_seg_val, addr => di_s_tdata, val => rr_tdata.sreg_val, w =>  rr_tdata.w);

                when others =>
                    null;
            end case;
        end procedure;

        procedure do_str_cmd_1_lods is begin
            case micro_cnt is
                when 1 =>
                    mem_off; si_inc_off;
                    micro_tdata.read_fifo <= '1';
                    if rep_mode = '0' then
                        alu_load_reg_from_mem(rr_tdata_buf.dreg, rr_tdata_buf.dmask);
                    end if;

                when 0 =>
                    micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '1';
                    si_inc_on;
                    micro_tdata.read_fifo <= '0';
                    micro_tdata.mem_addr <= si_s_tdata;
                    update_si_keep_lock;

                when others => null;
            end case;
        end procedure;

        procedure do_str_cmd_1_stos is begin
            micro_tdata.mem_addr <= di_s_tdata_next;
            update_di_keep_lock;
        end procedure;

        procedure do_str_cmd_1_cmps is begin
            case micro_cnt is
                when 6 =>
                    di_inc_on; si_inc_off;
                    micro_tdata.read_fifo <= '1';
                    if rep_mode = '1' then
                        micro_tdata.di_keep_lock <= '1';
                    else
                        micro_tdata.di_keep_lock <= '0';
                    end if;

                    micro_tdata.mem_cmd <= '0';
                    micro_tdata.mem_seg <= rr_tdata_buf.es_seg_val;
                    micro_tdata.mem_addr <= di_s_tdata;
                    micro_tdata.mem_data_src <= MEM_DATA_SRC_FIFO;
                when 5 =>
                    mem_off; di_inc_off; si_inc_off;
                    micro_tdata.read_fifo <= '1';

                    micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '1';
                    micro_tdata.alu_code <= ALU_OP_CMP;
                    micro_tdata.alu_wb <= '0';
                    micro_tdata.alu_a_buf <= '1';
                    micro_tdata.alu_b_mem <= '1';
                when 4 =>
                    alu_off;
                    micro_tdata.read_fifo <= '0';

                when 0 =>
                    if (rep_mode = '1' and ((rep_nz = '0' and flags_s_tdata(FLAG_ZF) = '0') or (rep_nz = '1' and flags_s_tdata(FLAG_ZF) = '1'))) then
                        di_inc_on;
                        micro_tdata.di_keep_lock <= '0';
                        micro_tdata.di_inc_data <= x"0000";

                        si_inc_on;
                        micro_tdata.si_keep_lock <= '0';
                        micro_tdata.si_inc_data <= x"0000";
                    else
                        alu_off; di_inc_off; si_inc_on;
                        update_si_keep_lock;
                        mem_read(seg => rr_tdata_buf.seg_val, addr => si_s_tdata, w => rr_tdata_buf.w);
                        micro_tdata.read_fifo <= '0';

                    end if;
                when others => null;
            end case;
        end procedure;

        procedure do_str_cmd_1_movs is begin
            case micro_cnt is
                when 1 =>
                    micro_tdata.read_fifo <= '1';
                    di_inc_on;
                    si_inc_off;

                    if rep_mode = '1' then
                        micro_tdata.di_keep_lock <= '1';
                    else
                        micro_tdata.di_keep_lock <= '0';
                    end if;

                    micro_tdata.mem_cmd <= '1';
                    micro_tdata.mem_seg <= rr_tdata_buf.es_seg_val;
                    micro_tdata.mem_addr <= di_s_tdata;
                    micro_tdata.mem_data_src <= MEM_DATA_SRC_FIFO;

                when 0 =>
                    micro_tdata.read_fifo <= '0';
                    di_inc_off; si_inc_on;
                    update_si_keep_lock;

                    micro_tdata.alu_a_val <= si_s_tdata;
                    micro_tdata.alu_dreg <= rr_tdata_buf.sreg;

                    micro_tdata.mem_cmd <= '0';
                    micro_tdata.mem_seg <= rr_tdata_buf.seg_val;
                    micro_tdata.mem_addr <= si_s_tdata;

                when others => null;
            end case;
        end procedure;

        procedure do_str_cmd_1_scas is begin
            case micro_cnt is
                when 5 =>
                    mem_off; di_inc_off;
                    micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '1';
                    micro_tdata.read_fifo <= '1';

                    micro_tdata.alu_code <= ALU_OP_CMP;
                    micro_tdata.alu_wb <= '0';
                    micro_tdata.alu_a_val <= rr_tdata_buf.sreg_val;
                    micro_tdata.alu_b_mem <= '1';
                when 4 =>
                    alu_off;
                    micro_tdata.read_fifo <= '0';
                when 0 =>
                    di_inc_on;
                    if (rep_mode = '1' and ((rep_nz = '0' and flags_s_tdata(FLAG_ZF) = '0') or (rep_nz = '1' and flags_s_tdata(FLAG_ZF) = '1'))) then
                        micro_tdata.di_keep_lock <= '0';
                        micro_tdata.di_inc_data <= x"0000";
                    else
                        update_di_keep_lock;
                        mem_read(seg => rr_tdata_buf.es_seg_val, addr => di_s_tdata, w => rr_tdata_buf.w);
                    end if;
                when others => null;
            end case;
        end procedure;

        procedure do_stack_cmd_0 is begin
            fl_off; alu_off; jmp_off; dbg_off; mul_off; one_off; bcd_off; shf_off; div_off;
            di_inc_off; si_inc_off; sp_inc_on;
            micro_tdata.unlk_fl <= '0';

            case rr_tdata.code is
                when STACKU_POPR =>
                    mem_read_word(seg =>rr_tdata.ss_seg_val, addr => sp_s_tdata);
                    micro_tdata.sp_keep_lock <= '0';
                when STACKU_POPM =>
                    mem_read_word(seg =>rr_tdata.ss_seg_val, addr => sp_s_tdata);
                    micro_tdata.sp_keep_lock <= '0';
                when STACKU_POPA =>
                    mem_read_word(seg =>rr_tdata.ss_seg_val, addr => sp_s_tdata);
                    micro_tdata.sp_keep_lock <= '1';
                when STACKU_PUSHR =>
                    mem_write_imm(seg =>rr_tdata.ss_seg_val, addr => sp_value_next, val => rr_tdata.sreg_val, w => rr_tdata.w);
                    micro_tdata.sp_keep_lock <= '0';
                when STACKU_PUSHM =>
                    mem_read_word(seg =>rr_tdata.seg_val, addr => ea_val_plus_disp_next);
                    micro_tdata.sp_keep_lock <= '0';
                when STACKU_PUSHI =>
                    mem_write_imm(seg =>rr_tdata.ss_seg_val, addr => sp_value_next, val => rr_tdata.data, w => rr_tdata.w);
                    micro_tdata.sp_keep_lock <= '0';
                when STACKU_PUSHA =>
                    mem_off;
                    micro_tdata.sp_keep_lock <= '1';
                when others => null;
            end case;

        end procedure;

        procedure do_stack_cmd_1 is begin
            case rr_tdata_buf.code is
                when STACKU_PUSHM =>
                    sp_inc_off;
                    micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '1';
                    micro_tdata.read_fifo <= '1';

                    micro_tdata.mem_cmd <= '1';
                    micro_tdata.mem_seg <= rr_tdata_buf.ss_seg_val;
                    micro_tdata.mem_addr <= sp_s_tdata_next;
                    micro_tdata.mem_data_src <= MEM_DATA_SRC_FIFO;

                when STACKU_PUSHA =>

                    micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '1';

                    if (micro_cnt = 1) then
                        sp_inc_off;
                    end if;

                    if (micro_cnt = 2) then
                        micro_tdata.sp_keep_lock <= '0';
                    end if;

                    if (micro_cnt = 2) then
                        micro_tdata.unlk_fl <= '1';
                    else
                        micro_tdata.unlk_fl <= '0';
                    end if;

                    micro_tdata.mem_cmd <= '1';
                    micro_tdata.mem_seg <= rr_tdata_buf.ss_seg_val;
                    micro_tdata.mem_addr <= sp_s_tdata_next;
                    micro_tdata.mem_data_src <= MEM_DATA_SRC_IMM;

                    case micro_cnt is
                        when 7 => micro_tdata.mem_data <= cx_s_tdata;
                        when 6 => micro_tdata.mem_data <= dx_s_tdata;
                        when 5 => micro_tdata.mem_data <= bx_s_tdata;
                        when 4 => micro_tdata.mem_data <= rr_tdata_buf.dreg_val;
                        when 3 => micro_tdata.mem_data <= bp_s_tdata;
                        when 2 => micro_tdata.mem_data <= si_s_tdata;
                        when 1 => micro_tdata.mem_data <= di_s_tdata;
                        when others => micro_tdata.mem_data <= rr_tdata_buf.sreg_val;
                    end case;

                when STACKU_POPR =>
                    micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '1';
                    mem_off;
                    sp_inc_off;

                    micro_tdata.read_fifo <= '1';

                    micro_tdata.alu_code <= ALU_SF_ADD;
                    micro_tdata.alu_wb <= '1';
                    micro_tdata.alu_a_val <= x"0000";
                    micro_tdata.alu_b_mem <= '1';
                    micro_tdata.alu_dreg <= rr_tdata_buf.dreg;
                    micro_tdata.alu_dmask <= rr_tdata_buf.dmask;

                when STACKU_POPM =>
                    alu_off;
                    micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '1';
                    sp_inc_off;

                    micro_tdata.read_fifo <= '1';

                    micro_tdata.mem_cmd <= '1';
                    micro_tdata.mem_width <= rr_tdata_buf.w;
                    micro_tdata.mem_seg <= rr_tdata_buf.seg_val;
                    micro_tdata.mem_addr <= ea_val_plus_disp;
                    micro_tdata.mem_data_src <= MEM_DATA_SRC_FIFO;

                when STACKU_POPA =>
                    micro_tdata.mem_addr <= sp_s_tdata_next;

                    case micro_cnt is
                        when 15 =>
                            micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '1';
                            micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '1';
                            -- READ MEM FROM SP
                            micro_tdata.mem_cmd <= '0';
                            micro_tdata.mem_width <= '1';
                            micro_tdata.mem_seg <= rr_tdata_buf.ss_seg_val;
                        when 9 =>
                            micro_tdata.sp_keep_lock <= '0';

                        when 8 =>
                            micro_tdata.alu_wb <= '1';
                            micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '1';
                            mem_off;
                            sp_inc_off;

                            micro_tdata.read_fifo <= '1';

                            micro_tdata.alu_a_val <= x"0000";
                            micro_tdata.alu_b_mem <= '1';
                            micro_tdata.alu_dreg <= DI;
                            micro_tdata.alu_dmask <= rr_tdata_buf.dmask;
                            micro_tdata.alu_wb <= '1';
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

        procedure do_movu_cmd_0 is begin
            fl_off; jmp_off; dbg_off; mul_off; one_off; bcd_off; shf_off; div_off;
            sp_inc_off; di_inc_off; si_inc_off;
            micro_tdata.alu_wb <= '0';
            micro_tdata.unlk_fl <= '0';

            case rr_tdata.dir is
                when I2M =>
                    micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '1';
                    alu_off;

                    micro_tdata.mem_cmd <= '1';
                    micro_tdata.mem_width <= rr_tdata.w;
                    micro_tdata.mem_seg <= rr_tdata.seg_val;
                    micro_tdata.mem_addr <= ea_val_plus_disp_next;
                    micro_tdata.mem_data_src <= MEM_DATA_SRC_IMM;
                    micro_tdata.mem_data <= rr_tdata.data;

                when R2M =>
                    micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '1';
                    alu_off;

                    micro_tdata.mem_cmd <= '1';
                    micro_tdata.mem_width <= rr_tdata.w;
                    micro_tdata.mem_seg <= rr_tdata.seg_val;
                    micro_tdata.mem_addr <= ea_val_plus_disp_next;
                    micro_tdata.mem_data_src <= MEM_DATA_SRC_IMM;
                    micro_tdata.mem_data <= rr_tdata.sreg_val;

                when M2R =>
                    micro_tdata.cmd(MICRO_OP_CMD_MEM) <= '1';
                    alu_off;

                    micro_tdata.mem_cmd <= '0';
                    micro_tdata.mem_width <= rr_tdata.w;
                    micro_tdata.mem_seg <= rr_tdata.seg_val;
                    micro_tdata.mem_addr <= ea_val_plus_disp_next;

                when R2F =>
                    mem_off;
                    micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '1';

                    micro_tdata.alu_wb <= '1';
                    micro_tdata.alu_code <= ALU_SF_ADD;
                    micro_tdata.alu_a_val <= rr_tdata.sreg_val;
                    micro_tdata.alu_b_val <= x"0000";
                    micro_tdata.alu_dreg <= rr_tdata.dreg;
                    micro_tdata.alu_dmask <= rr_tdata.dmask;

                when others =>
                    null;
            end case;
        end procedure;

        procedure do_loop_cmd_0 is begin
            mem_off; jmp_off; dbg_off; mul_off; one_off; bcd_off; shf_off; div_off;
            sp_inc_off; di_inc_off; si_inc_off;
            micro_tdata.unlk_fl <= '0';

            -- CX = CX - 1
            alu_command_imm(cmd => ALU_SF_ADD,
                aval => rr_tdata.sreg_val,
                bval => rr_tdata.data,
                dreg => rr_tdata.dreg,
                dmask => rr_tdata.dmask);

        end procedure;

        procedure do_loop_cmd_1 is begin
            micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '1';

            micro_tdata.cmd(MICRO_OP_CMD_JMP) <= '1';
            micro_tdata.alu_wb <= '0';
            micro_tdata.read_fifo <= '0';
            micro_tdata.jump_imm <= '1';
            micro_tdata.jump_cs <= rr_tuser_buf(31 downto 16);
            micro_tdata.jump_ip <= std_logic_vector(unsigned(rr_tuser_buf(15 downto 0)) + unsigned(rr_tdata_buf.disp));
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

        end procedure;

        procedure initialize_signals is begin
            micro_tdata.alu_a_buf <= '0';
            micro_tdata.alu_a_mem <= '0';
            micro_tdata.alu_b_mem <= '0';
            micro_tdata.alu_w <= rr_tdata.w;
            micro_tdata.read_fifo <= '0';

            micro_tdata.jump_cond <= j_never;
            micro_tdata.jump_imm <= '0';
            micro_tdata.jump_cs_mem <= '0';
            micro_tdata.jump_ip_mem <= '0';
        end procedure;

        procedure si_inc_direction is begin
            if (flags_s_tdata(FLAG_DF) = '0') then
                if (rr_tdata.w = '1') then
                    micro_tdata.si_inc_data <= x"0002";
                else
                    micro_tdata.si_inc_data <= x"0001";
                end if;
            else
                if (rr_tdata.w = '1') then
                    micro_tdata.si_inc_data <= x"FFFE";
                else
                    micro_tdata.si_inc_data <= x"FFFF";
                end if;
            end if;
        end procedure;

        procedure di_inc_direction is begin
            if (flags_s_tdata(FLAG_DF) = '0') then
                if (rr_tdata.w = '1') then
                    micro_tdata.di_inc_data <= x"0002";
                else
                    micro_tdata.di_inc_data <= x"0001";
                end if;
            else
                if (rr_tdata.w = '1') then
                    micro_tdata.di_inc_data <= x"FFFE";
                else
                    micro_tdata.di_inc_data <= x"FFFF";
                end if;
            end if;
        end procedure;

        procedure sp_inc_direction is begin
            if (rr_tdata.code(3) = '0') then
                -- pop instructions
                micro_tdata.sp_inc_data <= x"0002";
            else
                -- push instructions
                micro_tdata.sp_inc_data <= x"FFFE";
            end if;
        end;

    begin
        if rising_edge(clk) then
            if (resetn = '0') then
                micro_tvalid <= '0';
                micro_cnt <= 0;
                micro_busy <= '0';
            else

                if (div_intr_s_tvalid = '1' and div_intr_s_tready = '1') then
                    micro_tvalid <= '1';
                elsif (rr_tvalid = '1' and rr_tready = '1') then
                    if (fast_instruction_fl = '0' and (rep_mode = '0' or (rep_mode = '1' and rep_cx_cnt /= 0))) then
                        micro_tvalid <= '1';
                    else
                        micro_tvalid <= '0';
                    end if;
                elsif (micro_tready = '1' and rep_mode = '0' and micro_cnt = 0) then
                    micro_tvalid <= '0';
                end if;

                if (div_intr_s_tvalid = '1' and div_intr_s_tready = '1') then
                    micro_cnt <= 6;
                    micro_cnt_max <= 6;
                elsif (rr_tvalid = '1' and rr_tready = '1') then
                    micro_cnt <= micro_cnt_next;
                    micro_cnt_max <= micro_cnt_next;
                elsif (micro_tvalid = '1' and micro_tready = '1') then
                    if (micro_cnt = 0 and rep_mode = '1' and rep_cx_cnt >= 1 and rep_cancel = '0') then
                        micro_cnt <= micro_cnt_max;
                    elsif micro_cnt > 0 then
                        micro_cnt <= micro_cnt - 1;
                    end if;
                end if;

                if (div_intr_s_tvalid = '1' and div_intr_s_tready = '1') then
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

            if (div_intr_s_tvalid = '1' and div_intr_s_tready = '1') then
                rr_tdata_buf.ss_seg_val <= div_intr_s_tdata(DIV_INTR_T_SS);
                rr_tdata_buf.op <= SYS;
                rr_tdata_buf.code <= SYS_DIV_INT_OP;

                rr_tuser_buf(USER_T_IP) <= div_intr_s_tdata(DIV_INTR_T_IP);
                rr_tuser_buf(USER_T_CS) <= div_intr_s_tdata(DIV_INTR_T_CS);
                rr_tuser_buf(USER_T_IP_NEXT) <= div_intr_s_tdata(DIV_INTR_T_IP_NEXT);
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
            elsif (rr_tvalid = '1' and rr_tready = '1') then
                initialize_signals;
                si_inc_direction;
                di_inc_direction;
                sp_inc_direction;

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
                    when LFP => do_lfp_cmd_0;
                    when DBG => do_dbg_cmd_0;
                    when STR => do_str_cmd_0;
                    when STACKU => do_stack_cmd_0;
                    when SET_FLAG => do_set_flg_cmd_0;
                    when LOOPU => do_loop_cmd_0;
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
                    when LFP => do_lfp_cmd_1;
                    when STACKU => do_stack_cmd_1;
                    when LOOPU => do_loop_cmd_1;
                    when SYS =>
                        case rr_tdata_buf.code is
                            when SYS_INT_OP => do_sys_cmd_int_1;
                            when SYS_IRET_OP => do_sys_cmd_iret_1;
                            when SYS_DIV_INT_OP => do_div_intr_1;
                            when others => null;
                        end case;
                    when STR =>
                        case rr_tdata_buf.code is
                            when CMPS_OP => do_str_cmd_1_cmps;
                            when LODS_OP => do_str_cmd_1_lods;
                            when STOS_OP => do_str_cmd_1_stos;
                            when SCAS_OP => do_str_cmd_1_scas;
                            when MOVS_OP => do_str_cmd_1_movs;
                            when others => null;
                        end case;

                    when MOVU =>
                        micro_tdata.unlk_fl <= '0';

                        case rr_tdata_buf.dir is
                            when M2R =>
                                micro_tdata.cmd(MICRO_OP_CMD_ALU) <= '1';
                                mem_off;
                                micro_tdata.cmd(MICRO_OP_CMD_JMP) <= '0';

                                micro_tdata.alu_code <= ALU_SF_ADD;
                                micro_tdata.alu_wb <= '1';
                                micro_tdata.read_fifo <= '1';

                                micro_tdata.alu_a_val <= x"0000";
                                micro_tdata.alu_b_mem <= '1';
                                micro_tdata.alu_dreg <= rr_tdata_buf.dreg;
                                micro_tdata.alu_dmask <= rr_tdata_buf.dmask;

                            when others => null;
                        end case;

                    when others => null;
                end case;
            end if;

        end if;
    end process;

end architecture;
