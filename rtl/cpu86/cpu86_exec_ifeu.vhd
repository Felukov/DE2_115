
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
use std.textio.all;

entity cpu86_exec_ifeu is
    port (
        clk                     : in std_logic;
        resetn                  : in std_logic;

        jmp_lock_s_tvalid       : in std_logic;

        rr_s_tvalid             : in std_logic;
        rr_s_tready             : out std_logic;
        rr_s_tdata              : in rr_instr_t;
        rr_s_tuser              : in user_t;

        ext_intr_s_tvalid       : in std_logic;
        ext_intr_s_tready       : out std_logic;
        ext_intr_s_tdata        : in std_logic_vector(7 downto 0);

        s_axis_trap_tvalid      : in std_logic;
        s_axis_trap_tready      : out std_logic;
        s_axis_trap_tdata       : in intr_t;
        s_axis_trap_tuser       : in std_logic_vector;

        s_axis_ss_tvalid        : in std_logic;
        s_axis_ss_tdata         : in std_logic_vector(15 downto 0);
        s_axis_sp_tvalid        : in std_logic;
        s_axis_sp_tdata         : in std_logic_vector(15 downto 0);

        m_axis_micro_tvalid     : out std_logic;
        m_axis_micro_tready     : in std_logic;
        m_axis_micro_tlast      : out std_logic;
        m_axis_micro_tdata      : out micro_op_t;

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
end entity cpu86_exec_ifeu;

architecture rtl of cpu86_exec_ifeu is

    -- component signal_tap is
    --     port (
    --         acq_data_in    : in std_logic_vector(31 downto 0) := (others => 'X'); -- acq_data_in
    --         acq_trigger_in : in std_logic_vector(0 downto 0)  := (others => 'X'); -- acq_trigger_in
    --         acq_clk        : in std_logic                     := 'X';             -- clk
    --         storage_enable : in std_logic                     := 'X'              -- storage_enable
    --     );
    -- end component signal_tap;

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
    signal micro_tlast          : std_logic;
    signal micro_cnt_next       : natural range 0 to 63;
    signal micro_cnt            : natural range 0 to 63;
    signal micro_busy           : std_logic;
    signal micro_tdata          : micro_op_t;
    signal micro_op             : op_t;
    signal micro_code           : std_logic_vector(3 downto 0);
    signal rr_tdata_buf         : rr_instr_t;
    signal rr_tuser_buf         : user_t;

    signal ea_val_plus_disp_next: std_logic_vector(15 downto 0);
    signal ea_val_plus_disp     : std_logic_vector(15 downto 0);
    signal ea_val_plus_disp_p_2 : std_logic_vector(15 downto 0);

    signal ip_val_plus_disp_next: std_logic_vector(15 downto 0);

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
    signal sp_offset            : std_logic_vector(15 downto 0);
    signal bp_val               : std_logic_vector(15 downto 0);

    signal ss_tvalid            : std_logic;
    signal ss_tdata             : std_logic_vector(15 downto 0);
    signal sp_tvalid            : std_logic;
    signal sp_tdata             : std_logic_vector(15 downto 0);

    signal interrupt_no         : std_logic_vector(15 downto 0);
    signal interrupt_ss_seg_val : std_logic_vector(15 downto 0);
    signal interrupt_flags      : std_logic_vector(15 downto 0);
    signal interrupt_next_cs    : std_logic_vector(15 downto 0);
    signal interrupt_next_ip    : std_logic_vector(15 downto 0);

    signal trap_tvalid          : std_logic;
    signal trap_tready          : std_logic;
    signal trap_tdata           : intr_t;
    signal trap_tuser           : std_logic_vector(7 downto 0);

    signal cmd_mask             : std_logic_vector(MICRO_OP_CMD_WIDTH-1 downto 0);

    -- signal acq_data_in          : std_logic_vector(31 downto 0);
    -- signal acq_trigger_in       : std_logic_vector(0 downto 0);
    -- signal storage_enable       : std_logic;

begin
    -- i/o assigns
    rr_tvalid           <= rr_s_tvalid;
    rr_s_tready         <= rr_tready;
    rr_tdata            <= rr_s_tdata;
    rr_tuser            <= rr_s_tuser;

    m_axis_micro_tvalid <= micro_tvalid;
    micro_tready        <= m_axis_micro_tready;
    m_axis_micro_tlast  <= micro_tlast;
    m_axis_micro_tdata  <= micro_tdata;

    trap_tvalid         <= s_axis_trap_tvalid;
    s_axis_trap_tready  <= trap_tready;
    trap_tdata          <= s_axis_trap_tdata;
    trap_tuser          <= s_axis_trap_tuser;

    ss_tvalid           <= s_axis_ss_tvalid;
    ss_tdata            <= s_axis_ss_tdata;
    sp_tvalid           <= s_axis_sp_tvalid;
    sp_tdata            <= s_axis_sp_tdata;

    -- acq_data_in( 31 downto 16) <= rr_tuser(USER_T_CS);
    -- acq_data_in( 15 downto  0) <= rr_tuser(USER_T_IP);

    -- acq_trigger_in(0) <= '1'; --'1' when rr_tvalid = '1' and rr_tready = '1' else '0';
    -- storage_enable    <= '1'; --'1' when rr_tvalid = '1' and rr_tready = '1' else '0';

    -- u0 : component signal_tap port map (
    --     acq_clk         => clk,            -- acq_clk
    --     acq_data_in     => acq_data_in,    -- acq_data_in
    --     acq_trigger_in  => acq_trigger_in, -- acq_trigger_in
    --     storage_enable  => storage_enable  -- storage_enable
    -- );

    -- assigns
    rr_tready <= '1' when trap_tvalid = '0' and halt_mode = '0' and jmp_lock_s_tvalid = '1' and
        (micro_tvalid = '0' or (micro_tvalid = '1' and micro_tready = '1' and micro_busy = '0')) else '0';

    trap_tready <= '1' when ((rr_tvalid = '1' and trap_tuser = x"01" and rr_tdata.fl_tdata(FLAG_TF) = '1') or (trap_tuser /= x"01")) and
        jmp_lock_s_tvalid = '1' and sp_tvalid = '1' and ss_tvalid = '1' and
        (micro_tvalid = '0' or (micro_tvalid = '1' and micro_tready = '1' and micro_busy = '0')) else '0';

    jmp_lock_m_lock_tvalid <= '1' when rr_tvalid = '1' and rr_tready = '1' and
        ((rr_tdata.op = LOOPU) or
         (rr_tdata.op = BRANCH) or
         (rr_tdata.op = RET) or
         (rr_tdata.op = DIVU) or
         (rr_tdata.op = IO) or
         (rr_tdata.op = JCALL and rr_tdata.code(3) = '1') or
         (rr_tdata.op = JMPU and rr_tdata.code(3) = '1') or
         (rr_tdata.op = LFP and rr_tdata.code = MISC_BOUND) or
         (rr_tdata.op = SYS and rr_tdata.code /= SYS_HLT_OP))
    else '0';

    ea_val_plus_disp_next <= std_logic_vector(unsigned(rr_tdata.ea_val) + unsigned(rr_tdata.disp));
    ea_val_plus_disp_p_2 <= std_logic_vector(unsigned(ea_val_plus_disp) + to_unsigned(2, 16));

    ip_val_plus_disp_next <= std_logic_vector(unsigned(rr_tuser(15 downto 0)) + unsigned(rr_tdata.disp));

    cmd_mask <= (others => '0') when rr_tdata.fast_instr = '1' else (others => '1');

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
                if ((rr_tvalid = '1' and rr_tready = '1' and rr_tdata.fl_tdata(FLAG_TF) = '1') or
                    (trap_tvalid = '1' and trap_tready = '1'))
                then
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

                if (rr_tvalid = '1' and rr_tready = '1' and rr_tdata.op = PREFIX) then
                    rep_mode <= '1';
                elsif rep_mode = '1' and (rr_tvalid = '1' and rr_tready = '1') then
                    rep_mode <= '0';
                end if;

                if (rr_tvalid = '1' and rr_tready = '1' and rr_tdata.op = PREFIX) then
                    rep_cx_cnt <= rr_tdata.sreg_val;
                elsif rep_mode = '1' and (rr_tvalid = '1' and rr_tready = '1') then
                    rep_cx_cnt <= x"0001";
                end if;

                if (rr_tvalid = '1' and rr_tready = '1' and rr_tdata.op = PREFIX) then
                    if (rr_tdata.code = PREFIX_REPNZ) then
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
                case rr_tdata.code is
                    when MISC_XLAT      => micro_cnt_next <= 1;
                    when MISC_BOUND     => micro_cnt_next <= 3;
                    when others         => micro_cnt_next <= 2;
                end case;

            when SYS =>
                case rr_tdata.code is
                    when SYS_INT_INT_OP => micro_cnt_next <= 5;
                    when SYS_EXT_INT_OP => micro_cnt_next <= 5;
                    when SYS_IRET_OP    => micro_cnt_next <= 4;
                    when others         => micro_cnt_next <= 0;
                end case;

            when SHFU =>
                case rr_tdata.dir is
                    when I2M            => micro_cnt_next <= 1;
                    when R2M            => micro_cnt_next <= 1;
                    when others         => micro_cnt_next <= 0;
                end case;

            when MULU =>
                case rr_tdata.dir is
                    when M2R            => micro_cnt_next <= 1;
                    when others         => micro_cnt_next <= 0;
                end case;

            when DIVU =>
                case rr_tdata.dir is
                    when M2R            => micro_cnt_next <= 1;
                    when others         => micro_cnt_next <= 0;
                end case;

            when JMPU =>
                case rr_tdata.code is
                    when JMP_RM16       => micro_cnt_next <= 1;
                    when JMP_M16_16     => micro_cnt_next <= 2;
                    when others         => micro_cnt_next <= 0;
                end case;

            when JCALL =>
                case rr_tdata.code is
                    when CALL_REL16     => micro_cnt_next <= 0;
                    when CALL_PTR16_16  => micro_cnt_next <= 1;
                    when CALL_RM16      => micro_cnt_next <= 2;
                    when others         => micro_cnt_next <= 4;
                end case;

            when RET =>
                case rr_tdata.code is
                    when RET_NEAR       => micro_cnt_next <= 1;
                    when RET_NEAR_IMM16 => micro_cnt_next <= 2;
                    when RET_FAR        => micro_cnt_next <= 2;
                    when RET_FAR_IMM16  => micro_cnt_next <= 3;
                    when others         => micro_cnt_next <= 1;
                end case;

            when STACKU =>
                case rr_tdata.code is
                    when STACKU_ENTER   => micro_cnt_next <= rr_tdata.level;
                    when STACKU_LEAVE   => micro_cnt_next <= 1;
                    when STACKU_PUSHA   => micro_cnt_next <= 7;
                    when STACKU_PUSHM   => micro_cnt_next <= 1;
                    when STACKU_POPA    => micro_cnt_next <= 15;
                    when STACKU_POPR    => micro_cnt_next <= 1;
                    when STACKU_POPM    => micro_cnt_next <= 1;
                    when others         => micro_cnt_next <= 0;
                end case;

            when MOVU =>
                case rr_tdata.dir is
                    when M2R            => micro_cnt_next <= 1;
                    when others         => micro_cnt_next <= 0;
                end case;

            when ALU =>
                case rr_tdata.dir is
                    when M2R            => micro_cnt_next <= 1;
                    when R2M            => micro_cnt_next <= 1;
                    when M2M            => micro_cnt_next <= 1;
                    when I2M            => micro_cnt_next <= 1;
                    when others         => micro_cnt_next <= 0;
                end case;

            when LOOPU                  => micro_cnt_next <= 1;
            when XCHG                   => micro_cnt_next <= 1;
            when others                 => micro_cnt_next <= 0;

        end case;
    end process;

    micro_cmd_gen_proc : process (clk)

        procedure set_undefined is begin
            micro_tdata.cmd             <= (others => 'U');
            micro_tdata.trap            <= 'U';
            micro_tdata.alu_code        <= (others => 'U');
            micro_tdata.alu_w           <= 'U';
            micro_tdata.alu_dreg        <= ZERO;
            micro_tdata.alu_dmask       <= (others => 'U');
            micro_tdata.alu_a_buf       <= 'U';
            micro_tdata.alu_a_mem       <= 'U';
            micro_tdata.alu_a_val       <= (others => 'U');
            micro_tdata.alu_b_mem       <= 'U';
            micro_tdata.alu_b_val       <= (others => 'U');
            micro_tdata.alu_wb          <= 'U';
            micro_tdata.alu_upd_fl      <= 'U';
            micro_tdata.mul_code        <= (others => 'U');
            micro_tdata.mul_w           <= 'U';
            micro_tdata.mul_dreg        <= ZERO;
            micro_tdata.mul_a_val       <= (others => 'U');
            micro_tdata.mul_b_val       <= (others => 'U');
            micro_tdata.div_code        <= (others => 'U');
            micro_tdata.div_w           <= 'U';
            micro_tdata.div_dreg        <= ZERO;
            micro_tdata.div_a_val       <= (others => 'U');
            micro_tdata.div_b_val       <= (others => 'U');
            micro_tdata.bnd_val         <= (others => 'U');
            micro_tdata.shf_code        <= (others => 'U');
            micro_tdata.shf_code_ex     <= (others => 'U');
            micro_tdata.shf_w           <= 'U';
            micro_tdata.shf_dreg        <= ZERO;
            micro_tdata.shf_dmask       <= (others => 'U');
            micro_tdata.shf_sval        <= (others => 'U');
            micro_tdata.shf_ival        <= (others => 'U');
            micro_tdata.shf_wb          <= 'U';
            micro_tdata.bcd_code        <= (others => 'U');
            micro_tdata.bcd_sval        <= (others => 'U');
            micro_tdata.str_code        <= (others => 'U');
            micro_tdata.str_rep         <= 'U';
            micro_tdata.str_rep_nz      <= 'U';
            micro_tdata.str_direction   <= 'U';
            micro_tdata.str_w           <= 'U';
            micro_tdata.str_port        <= (others => 'U');
            micro_tdata.str_ax_val      <= (others => 'U');
            micro_tdata.str_cx_val      <= (others => 'U');
            micro_tdata.str_es_val      <= (others => 'U');
            micro_tdata.str_di_val      <= (others => 'U');
            micro_tdata.str_ds_val      <= (others => 'U');
            micro_tdata.str_si_val      <= (others => 'U');
            micro_tdata.jump_cond       <= j_never;
            micro_tdata.jump_imm        <= 'U';
            micro_tdata.jump_cs_mem     <= 'U';
            micro_tdata.jump_cs         <= (others => 'U');
            micro_tdata.jump_ip_mem     <= 'U';
            micro_tdata.jump_ip         <= (others => 'U');
            micro_tdata.jump_cx         <= (others => 'U');
            micro_tdata.jump_is_ret     <= 'U';
            micro_tdata.mem_cmd         <= 'U';
            micro_tdata.mem_width       <= 'U';
            micro_tdata.mem_seg         <= (others => 'U');
            micro_tdata.mem_addr        <= (others => 'U');
            micro_tdata.mem_data_src    <= MEM_DATA_SRC_ONE;
            micro_tdata.mem_data        <= (others => 'U');
            micro_tdata.flg_no          <= (others => 'U');
            micro_tdata.fl              <= TOGGLE;
            micro_tdata.inst_ss         <= (others => 'U');
            micro_tdata.inst_cs         <= (others => 'U');
            micro_tdata.inst_ip         <= (others => 'U');
            micro_tdata.inst_ip_next    <= (others => 'U');
            micro_tdata.bpu_first       <= 'U';
            micro_tdata.bpu_taken       <= 'U';
            micro_tdata.bpu_bypass      <= 'U';
            micro_tdata.bpu_taken_cs    <= (others => 'U');
            micro_tdata.bpu_taken_ip    <= (others => 'U');
        end procedure;

        procedure set_cmd_0(cmd : std_logic_vector) is begin
            micro_tdata.cmd <= cmd and cmd_mask;
        end;

        procedure set_cmd_1(cmd : std_logic_vector) is begin
            micro_tdata.cmd <= cmd;
        end;

        procedure flag_update (flag : std_logic_vector; val : fl_action_t) is begin
            micro_tdata.flg_no <= flag;
            micro_tdata.fl     <= val;
        end procedure;

        procedure flag_update (flag : natural; val : fl_action_t) is begin
            flag_update(std_logic_vector(to_unsigned(flag, 4)), val);
        end procedure;

        procedure alu_command_imm(cmd, aval, bval: std_logic_vector; dreg : reg_t; dmask : std_logic_vector; upd_fl : std_logic) is begin
            micro_tdata.alu_code   <= cmd;
            micro_tdata.alu_a_val  <= aval;
            micro_tdata.alu_b_val  <= bval;
            micro_tdata.alu_dreg   <= dreg;
            micro_tdata.alu_dmask  <= dmask;
            micro_tdata.alu_wb     <= '1';
            micro_tdata.alu_upd_fl <= upd_fl;
        end procedure;

        procedure update_sp(upd_when : boolean; sp_val, offset: std_logic_vector) is begin
            micro_tdata.alu_code   <= ALU_OP_ADD;
            micro_tdata.alu_a_val  <= sp_val;
            micro_tdata.alu_b_val  <= offset;
            micro_tdata.alu_dreg   <= SP;
            micro_tdata.alu_dmask  <= "11";
            if (upd_when) then
                micro_tdata.alu_wb <= '1';
            else
                micro_tdata.alu_wb <= '0';
            end if;
            micro_tdata.alu_upd_fl <= '0';
        end procedure;

        procedure update_sp(sp_val: std_logic_vector; sp_offset : std_logic_vector) is begin
            micro_tdata.alu_code   <= ALU_OP_ADD;
            micro_tdata.alu_a_val  <= sp_val;
            micro_tdata.alu_b_val  <= sp_offset;
            micro_tdata.alu_dreg   <= SP;
            micro_tdata.alu_dmask  <= "11";
            micro_tdata.alu_wb     <= '1';
            micro_tdata.alu_upd_fl <= '0';
        end procedure;

        procedure update_sp(sp_val: std_logic_vector) is begin
            update_sp(sp_val, x"0000");
        end procedure;

        procedure alu_put_in_b(bval : std_logic_vector) is begin
            micro_tdata.alu_wb     <= '0';
            micro_tdata.alu_upd_fl <= '0';
            micro_tdata.alu_code   <= ALU_OP_ADD;
            micro_tdata.alu_a_val  <= x"0000";
            micro_tdata.alu_b_val  <= bval;
        end procedure;

        procedure mem_read_word(seg, addr : std_logic_vector) is begin
            micro_tdata.mem_cmd      <= '0';
            micro_tdata.mem_width    <= '1';
            micro_tdata.mem_seg      <= seg;
            micro_tdata.mem_addr     <= addr;
        end procedure;

        procedure mem_read(seg, addr : std_logic_vector; w : std_logic) is begin
            micro_tdata.mem_cmd      <= '0';
            micro_tdata.mem_width    <= w;
            micro_tdata.mem_seg      <= seg;
            micro_tdata.mem_addr     <= addr;
        end procedure;

        procedure mem_write_alu(seg, addr : std_logic_vector; w : std_logic) is begin
            micro_tdata.mem_cmd      <= '1';
            micro_tdata.mem_width    <= w;
            micro_tdata.mem_seg      <= seg;
            micro_tdata.mem_addr     <= addr;
            micro_tdata.mem_data_src <= MEM_DATA_SRC_ALU;
        end procedure;

        procedure mem_write_one(seg, addr : std_logic_vector; w : std_logic) is begin
            micro_tdata.mem_cmd      <= '1';
            micro_tdata.mem_width    <= w;
            micro_tdata.mem_seg      <= seg;
            micro_tdata.mem_addr     <= addr;
            micro_tdata.mem_data_src <= MEM_DATA_SRC_ONE;
        end procedure;

        procedure mem_write_shf(seg, addr : std_logic_vector; w : std_logic) is begin
            micro_tdata.mem_cmd      <= '1';
            micro_tdata.mem_width    <= w;
            micro_tdata.mem_seg      <= seg;
            micro_tdata.mem_addr     <= addr;
            micro_tdata.mem_data_src <= MEM_DATA_SRC_SHF;
        end procedure;

        procedure mem_write_imm(seg, addr, val : std_logic_vector; w : std_logic) is begin
            micro_tdata.mem_cmd      <= '1';
            micro_tdata.mem_width    <= w;
            micro_tdata.mem_seg      <= seg;
            micro_tdata.mem_addr     <= addr;
            micro_tdata.mem_data_src <= MEM_DATA_SRC_IMM;
            micro_tdata.mem_data     <= val;
        end procedure;

        procedure do_io_cmd is begin
            set_cmd_0(MICRO_STR_OP or MICRO_UNLK_OP);

            case rr_tdata.code is
                when IO_IN_IMM   => micro_tdata.str_code <= IN_OP;
                when IO_IN_DX    => micro_tdata.str_code <= IN_OP;
                when IO_INS_IMM  => micro_tdata.str_code <= INS_OP;
                when IO_INS_DX   => micro_tdata.str_code <= INS_OP;
                when IO_OUT_IMM  => micro_tdata.str_code <= OUT_OP;
                when IO_OUT_DX   => micro_tdata.str_code <= OUT_OP;
                when IO_OUTS_IMM => micro_tdata.str_code <= OUTS_OP;
                when IO_OUTS_DX  => micro_tdata.str_code <= OUTS_OP;
                when others      => null;
            end case;

            case rr_tdata.code is
                when IO_IN_IMM   => micro_tdata.str_port <= x"00" & rr_tdata.data(7 downto 0);
                when IO_IN_DX    => micro_tdata.str_port <= rr_tdata.dx_tdata;
                when IO_INS_IMM  => micro_tdata.str_port <= x"00" & rr_tdata.data(7 downto 0);
                when IO_INS_DX   => micro_tdata.str_port <= rr_tdata.dx_tdata;
                when IO_OUT_IMM  => micro_tdata.str_port <= x"00" & rr_tdata.data(7 downto 0);
                when IO_OUT_DX   => micro_tdata.str_port <= rr_tdata.dx_tdata;
                when IO_OUTS_IMM => micro_tdata.str_port <= x"00" & rr_tdata.data(7 downto 0);
                when IO_OUTS_DX  => micro_tdata.str_port <= rr_tdata.dx_tdata;
                when others      => null;
            end case;

            micro_tdata.str_rep       <= rep_mode;
            micro_tdata.str_rep_nz    <= rep_nz;
            micro_tdata.str_direction <= rr_tdata.fl_tdata(FLAG_DF);
            micro_tdata.str_w         <= rr_tdata.w;
            micro_tdata.str_ax_val    <= rr_tdata.sreg_val;
            micro_tdata.str_cx_val    <= rep_cx_cnt;
            micro_tdata.str_es_val    <= rr_tdata.es_seg_val;
            micro_tdata.str_di_val    <= rr_tdata.di_tdata;
            micro_tdata.str_ds_val    <= rr_tdata.seg_val;
            micro_tdata.str_si_val    <= rr_tdata.si_tdata;
        end procedure;

        procedure do_mul_cmd_0 is begin
            micro_tdata.mul_code  <= rr_tdata.code;
            micro_tdata.mul_w     <= rr_tdata.w;
            micro_tdata.mul_dreg  <= rr_tdata.dreg;
            micro_tdata.mul_a_val <= rr_tdata.sreg_val;

            case rr_tdata.dir is
                when M2R =>
                    set_cmd_0(MICRO_MEM_OP);
                    mem_read(seg => rr_tdata.seg_val, addr => ea_val_plus_disp_next, w => rr_tdata.w);

                when others =>
                    set_cmd_0(MICRO_MUL_OP);
            end case;

            case rr_tdata.code is
                when MUL_AXDX =>
                    if (rr_tdata.w = '0') then
                        micro_tdata.mul_b_val(15 downto 8) <= (others => '0');
                        micro_tdata.mul_b_val( 7 downto 0) <= rr_tdata.ax_tdata(7 downto 0);
                    else
                        micro_tdata.mul_b_val <= rr_tdata.ax_tdata;
                    end if;
                when IMUL_AXDX =>
                    if (rr_tdata.w = '0') then
                        micro_tdata.mul_b_val(15 downto 8) <= (others => rr_tdata.ax_tdata(7));
                        micro_tdata.mul_b_val( 7 downto 0) <= rr_tdata.ax_tdata(7 downto 0);
                    else
                        micro_tdata.mul_b_val <= rr_tdata.ax_tdata;
                    end if;
                when others =>
                    micro_tdata.mul_b_val <= rr_tdata.data;
            end case;

        end procedure;

        procedure do_mul_cmd_1 is begin
            set_cmd_1(MICRO_MUL_OP or MICRO_MRD_OP);
        end procedure;

        procedure do_div_cmd_0 is begin
            micro_tdata.div_code <= rr_tdata.code;
            micro_tdata.div_w <= rr_tdata.w;
            micro_tdata.div_dreg <= rr_tdata.dreg;

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
                    set_cmd_0(MICRO_MEM_OP);
                    mem_read_word(seg => rr_tdata.seg_val, addr => ea_val_plus_disp_next);
                when others =>
                    set_cmd_0(MICRO_DIV_OP or MICRO_UNLK_OP);
            end case;
        end procedure;

        procedure do_div_cmd_1 is begin
            set_cmd_1(MICRO_DIV_OP or MICRO_MRD_OP or MICRO_UNLK_OP);
        end procedure;

        procedure do_bcd_cmd is begin
            set_cmd_0(MICRO_BCD_OP);
            micro_tdata.bcd_code <= rr_tdata.code;
            micro_tdata.bcd_sval <= rr_tdata.sreg_val;
        end procedure;

        procedure do_nop_cmd_0 is begin
            set_cmd_0(MICRO_NOP_OP);
        end procedure;

        procedure do_alu_cmd_0 is begin
            case rr_tdata.dir is
                when M2M =>
                    set_cmd_0(MICRO_MEM_OP);
                    mem_read(seg => rr_tdata.seg_val, addr => ea_val_plus_disp_next, w => rr_tdata.w);

                when M2R =>
                    set_cmd_0(MICRO_MEM_OP);
                    mem_read(seg => rr_tdata.seg_val, addr => ea_val_plus_disp_next, w => rr_tdata.w);

                when R2M =>
                    set_cmd_0(MICRO_MEM_OP);
                    mem_read(seg => rr_tdata.seg_val, addr => ea_val_plus_disp_next, w => rr_tdata.w);

                when I2M =>
                    set_cmd_0(MICRO_MEM_OP);
                    mem_read(seg => rr_tdata.seg_val, addr => ea_val_plus_disp_next, w => rr_tdata.w);

                when I2R =>
                    set_cmd_0(MICRO_ALU_OP);

                    micro_tdata.alu_code <= rr_tdata.code;
                    micro_tdata.alu_wb <= '1';
                    micro_tdata.alu_upd_fl <= '1';
                    micro_tdata.alu_a_val <= rr_tdata.dreg_val;
                    micro_tdata.alu_b_val <= rr_tdata.data;
                    micro_tdata.alu_dreg <= rr_tdata.dreg;
                    micro_tdata.alu_dmask <= rr_tdata.dmask;

                when others =>
                    set_cmd_0(MICRO_ALU_OP);

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
                    set_cmd_1(MICRO_MEM_OP or MICRO_ALU_OP or MICRO_MRD_OP);

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
                    set_cmd_1(MICRO_ALU_OP or MICRO_MRD_OP);

                    micro_tdata.alu_code <= rr_tdata_buf.code;
                    micro_tdata.alu_wb <= '1';
                    micro_tdata.alu_upd_fl <= '1';
                    micro_tdata.alu_a_val <= rr_tdata_buf.dreg_val;
                    micro_tdata.alu_b_mem <= '1';
                    micro_tdata.alu_dreg <= rr_tdata_buf.dreg;
                    micro_tdata.alu_dmask <= rr_tdata_buf.dmask;

                when R2M =>
                    if (rr_tdata_buf.code = ALU_OP_CMP or rr_tdata_buf.code = ALU_OP_TST) then
                        set_cmd_1(MICRO_ALU_OP or MICRO_MRD_OP);
                    else
                        set_cmd_1(MICRO_MEM_OP or MICRO_ALU_OP or MICRO_MRD_OP);
                    end if;

                    micro_tdata.alu_code <= rr_tdata_buf.code;
                    micro_tdata.alu_wb <= '0';
                    micro_tdata.alu_upd_fl <= '1';
                    micro_tdata.alu_a_mem <= '1';
                    micro_tdata.alu_b_val <= rr_tdata_buf.sreg_val;
                    micro_tdata.alu_dreg <= rr_tdata_buf.dreg;

                    micro_tdata.mem_cmd <= '1';
                    micro_tdata.mem_width <= rr_tdata_buf.w;
                    micro_tdata.mem_seg <= rr_tdata_buf.seg_val;
                    micro_tdata.mem_addr <= ea_val_plus_disp;
                    micro_tdata.mem_data_src <= MEM_DATA_SRC_ALU;

                when I2M =>
                    if (rr_tdata_buf.code = ALU_OP_CMP or rr_tdata_buf.code = ALU_OP_TST) then
                        set_cmd_1(MICRO_ALU_OP or MICRO_MRD_OP);
                    else
                        set_cmd_1(MICRO_MEM_OP or MICRO_ALU_OP or MICRO_MRD_OP);
                    end if;

                    micro_tdata.alu_code <= rr_tdata_buf.code;
                    micro_tdata.alu_wb <= '0';
                    micro_tdata.alu_upd_fl <= '1';
                    micro_tdata.alu_a_mem <= '1';
                    micro_tdata.alu_b_val <= rr_tdata_buf.data;
                    micro_tdata.alu_dreg <= rr_tdata_buf.dreg;

                    micro_tdata.mem_cmd <= '1';
                    micro_tdata.mem_width <= rr_tdata_buf.w;
                    micro_tdata.mem_seg <= rr_tdata_buf.seg_val;
                    micro_tdata.mem_addr <= ea_val_plus_disp;
                    micro_tdata.mem_data_src <= MEM_DATA_SRC_ALU;

                when others => null;
            end case;
        end procedure;

        procedure do_lfp_cmd_0 is begin
            set_cmd_0(MICRO_MEM_OP);
            mem_read(seg => rr_tdata.seg_val, addr => ea_val_plus_disp_next, w => rr_tdata.w);
        end procedure;

        procedure do_lfp_cmd_1 is begin
            case micro_cnt is
                when 2 =>
                    set_cmd_1(MICRO_MEM_OP or MICRO_ALU_OP or MICRO_MRD_OP);

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

                when others =>
                    set_cmd_1(MICRO_ALU_OP or MICRO_MRD_OP);
                    if (rr_tdata_buf.code = LFP_LDS) then
                        micro_tdata.alu_dreg <= DS;
                    else
                        micro_tdata.alu_dreg <= ES;
                    end if;

            end case;
        end procedure;

        procedure do_misc_bound_0 is begin
            set_cmd_0(MICRO_ALU_OP or MICRO_MEM_OP);

            mem_read(seg => rr_tdata.seg_val, addr => ea_val_plus_disp_next, w => rr_tdata.w);
            micro_tdata.bnd_val <= rr_tdata.dreg_val;

            --release dest register
            alu_command_imm(cmd => ALU_OP_ADD,
                aval   => rr_tdata.dreg_val,
                bval   => x"0000",
                dreg   => rr_tdata.dreg,
                dmask  => rr_tdata.dmask,
                upd_fl => '0');
        end procedure;

        procedure do_misc_bound_1 is begin
            case micro_cnt is
                when 3 =>
                    set_cmd_1(MICRO_MEM_OP or MICRO_MRD_OP);
                    micro_tdata.mem_addr <= ea_val_plus_disp_p_2;
                when 2 =>
                    set_cmd_1(MICRO_MRD_OP);
                when others =>
                    set_cmd_1(MICRO_BND_OP or MICRO_UNLK_OP);
            end case;
        end procedure;

        procedure do_shf_cmd_0 is begin
            micro_tdata.shf_code    <= rr_tdata.code;
            micro_tdata.shf_code_ex <= rr_tdata.data_ex(2 downto 0);
            micro_tdata.shf_w       <= rr_tdata.w;
            micro_tdata.shf_dreg    <= rr_tdata.dreg;
            micro_tdata.shf_dmask   <= rr_tdata.dmask;
            micro_tdata.shf_sval    <= rr_tdata.sreg_val;

            case rr_tdata.dir is
                when I2M =>
                    set_cmd_0(MICRO_MEM_OP);
                    micro_tdata.shf_wb   <= '0';
                    micro_tdata.shf_ival <= rr_tdata.data;

                    mem_read(seg => rr_tdata.seg_val, addr => ea_val_plus_disp_next, w => rr_tdata.w);

                when I2R =>
                    set_cmd_0(MICRO_SHF_OP);
                    micro_tdata.shf_wb   <= '1';
                    micro_tdata.shf_ival <= rr_tdata.data;

                when R2M =>
                    set_cmd_0(MICRO_MEM_OP);
                    micro_tdata.shf_wb   <= '0';
                    micro_tdata.shf_ival <= x"00" & rr_tdata.cx_tdata(7 downto 0);

                    mem_read(seg => rr_tdata.seg_val, addr => ea_val_plus_disp_next, w => rr_tdata.w);

                when R2R =>
                    set_cmd_0(MICRO_SHF_OP);
                    micro_tdata.shf_wb   <= '1';
                    micro_tdata.shf_ival <= x"00" & rr_tdata.cx_tdata(7 downto 0);

                when others => null;
            end case;

        end procedure;

        procedure do_shf_cmd_1 is begin
            set_cmd_1(MICRO_SHF_OP or MICRO_MEM_OP or MICRO_MRD_OP);
            mem_write_shf(seg => rr_tdata_buf.seg_val, addr => ea_val_plus_disp, w => rr_tdata_buf.w);
        end procedure;

        procedure do_sys_cmd_int_0 is begin
            set_cmd_0(MICRO_MEM_OP);

            micro_tdata.jump_cond   <= j_never;
            micro_tdata.jump_imm    <= '0';
            micro_tdata.jump_cs_mem <= '0';
            micro_tdata.jump_ip_mem <= '0';

            -- push FLAGS
            mem_write_imm(seg => rr_tdata.ss_seg_val, addr => rr_tdata.sp_val, val => rr_tdata.fl_tdata, w => rr_tdata.w);

        end;

        procedure do_sys_cmd_int_1 is begin

            case micro_cnt is
                --when 6 =>
                when 5 =>
                    set_cmd_1(MICRO_MEM_OP or MICRO_FLG_OP);
                    -- TF = 0
                    flag_update(FLAG_TF, CLR);
                    -- push CS
                    mem_write_imm(seg => rr_tdata_buf.ss_seg_val, addr => sp_val, val => interrupt_next_cs, w => rr_tdata_buf.w);

                when 4 =>
                    set_cmd_1(MICRO_MEM_OP or MICRO_FLG_OP or MICRO_ALU_OP);
                    flag_update(FLAG_IF, CLR);
                    -- push IP
                    mem_write_imm(seg => rr_tdata_buf.ss_seg_val, addr => sp_val, val => interrupt_next_ip, w => rr_tdata_buf.w);
                    -- upd SP
                    update_sp(sp_val);

                when 3 =>
                    -- read CS interrupt handler
                    set_cmd_1(MICRO_MEM_OP);
                    mem_read_word(seg => x"0000", addr => interrupt_no(13 downto 0) & "00");
                when 2 =>
                    set_cmd_1(MICRO_JMP_OP or MICRO_MRD_OP or MICRO_MEM_OP);
                    -- update jump_cs
                    micro_tdata.jump_cs_mem <= '0';
                    micro_tdata.jump_ip_mem <= '1';
                    -- read IP interrupt handler
                    mem_read_word(seg => x"0000", addr => interrupt_no(13 downto 0) & "10");
                when 1 =>
                    set_cmd_1(MICRO_JMP_OP or MICRO_MRD_OP or MICRO_UNLK_OP);
                    -- upd jump_ip
                    micro_tdata.jump_cs_mem <= '1';
                    micro_tdata.jump_ip_mem <= '0';

                    -- jump
                    micro_tdata.jump_cond <= j_always;

                when others => null;
            end case;
        end;

        procedure do_trap_0 is begin
            set_cmd_0(MICRO_NOP_OP);

            micro_tdata.jump_cond   <= j_never;
            micro_tdata.jump_imm    <= '0';
            micro_tdata.jump_cs_mem <= '0';
            micro_tdata.jump_ip_mem <= '0';
            micro_tdata.jump_is_ret <= '0';
        end;

        procedure do_trap_1 is begin
            case micro_cnt is
                when 6 =>
                    -- push FLAGS
                    set_cmd_1(MICRO_MEM_OP);
                    mem_write_imm(seg => interrupt_ss_seg_val, addr => sp_val, val => interrupt_flags, w => '1');
                when 5 =>
                    set_cmd_1(MICRO_MEM_OP or MICRO_FLG_OP);
                    -- TF = 0
                    flag_update(FLAG_TF, CLR);
                    -- push CS
                    mem_write_imm(seg => interrupt_ss_seg_val, addr => sp_val, val => interrupt_next_cs, w => '1');
                when 4 =>
                    set_cmd_1(MICRO_MEM_OP or MICRO_FLG_OP or MICRO_ALU_OP);
                    flag_update(FLAG_IF, CLR);
                    -- push IP
                    mem_write_imm(seg => interrupt_ss_seg_val, addr => sp_val, val => interrupt_next_ip, w => '1');

                    -- alu cmd
                    update_sp(sp_val);

                when 3 =>
                    set_cmd_1(MICRO_MEM_OP);
                    -- read CS interrupt handler
                    mem_read_word(seg => x"0000", addr => interrupt_no(13 downto 0) & "00");
                when 2 =>
                    set_cmd_1(MICRO_JMP_OP or MICRO_MRD_OP or MICRO_MEM_OP);
                    -- update jump_cs
                    micro_tdata.jump_cs_mem <= '0';
                    micro_tdata.jump_ip_mem <= '1';
                    -- read IP interrupt handler
                    mem_read_word(seg => x"0000", addr => interrupt_no(13 downto 0) & "10");
                when 1 =>
                    set_cmd_1(MICRO_JMP_OP or MICRO_MRD_OP or MICRO_UNLK_OP);
                    -- upd jump_ip
                    micro_tdata.jump_cs_mem <= '1';
                    micro_tdata.jump_ip_mem <= '0';

                    -- jump
                    micro_tdata.jump_cond <= j_always;

                when others => null;
            end case;
        end;

        procedure do_sys_cmd_iret_0 is begin
            set_cmd_0(MICRO_MEM_OP);

            -- read IP
            mem_read_word(seg => rr_tdata.ss_seg_val, addr => rr_tdata.sp_val);

            -- jump
            micro_tdata.jump_cond <= j_never;
            micro_tdata.jump_imm <= '0';
            micro_tdata.jump_cs_mem <= '0';
            micro_tdata.jump_ip_mem <= '0';

        end procedure;

        procedure do_sys_cmd_iret_1 is begin
            case micro_cnt is
                when 4 =>
                    set_cmd_1(MICRO_JMP_OP or MICRO_MEM_OP or MICRO_MRD_OP);
                    -- read CS
                    mem_read_word(seg => rr_tdata_buf.ss_seg_val, addr => sp_val);

                    -- write IP
                    micro_tdata.jump_cs_mem <= '0';
                    micro_tdata.jump_ip_mem <= '1';

                when 3 =>
                    set_cmd_1(MICRO_MEM_OP or MICRO_JMP_OP or MICRO_MRD_OP or MICRO_ALU_OP);
                    -- read FLAGS
                    mem_read_word(seg => rr_tdata_buf.ss_seg_val, addr => sp_val);

                    -- write CS
                    micro_tdata.jump_cs_mem <= '1';
                    micro_tdata.jump_ip_mem <= '0';

                    -- upd SP
                    update_sp(sp_val, sp_offset);

                when 2 =>
                    set_cmd_1(MICRO_MRD_OP);

                    micro_tdata.jump_cs_mem <= '0';
                    micro_tdata.jump_ip_mem <= '0';

                    -- write FLAGS
                    micro_tdata.mem_dreg  <= FL;
                    micro_tdata.mem_dmask <= "11";

                when others =>
                    set_cmd_1(MICRO_JMP_OP or MICRO_UNLK_OP);
                    micro_tdata.jump_cond <= j_always;

            end case;
        end procedure;

        procedure do_xchg_cmd_0 is begin
            set_cmd_0(MICRO_MEM_OP or MICRO_ALU_OP);
            -- read value from memory
            mem_read(seg => rr_tdata.seg_val, addr => ea_val_plus_disp_next, w => rr_tdata.w);
            -- put value from register into alu
            alu_put_in_b(rr_tdata.dreg_val);
        end procedure;

        procedure do_xchg_cmd_1 is begin
            set_cmd_1(MICRO_MEM_OP or MICRO_ALU_OP or MICRO_MRD_OP);
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

        procedure do_set_flg_cmd_0 is begin
            set_cmd_0(MICRO_FLG_OP);
            flag_update(rr_tdata.code, rr_tdata.fl);
        end procedure;

        procedure do_str_cmd is begin
            set_cmd_0(MICRO_STR_OP);
            -- str cmd
            micro_tdata.str_code      <= rr_tdata.code;
            micro_tdata.str_rep       <= rep_mode;
            micro_tdata.str_rep_nz    <= rep_nz;
            micro_tdata.str_direction <= rr_tdata.fl_tdata(FLAG_DF);
            micro_tdata.str_w         <= rr_tdata.w;
            micro_tdata.str_ax_val    <= rr_tdata.sreg_val;
            micro_tdata.str_cx_val    <= rep_cx_cnt;
            micro_tdata.str_es_val    <= rr_tdata.es_seg_val;
            micro_tdata.str_di_val    <= rr_tdata.di_tdata;
            micro_tdata.str_ds_val    <= rr_tdata.seg_val;
            micro_tdata.str_si_val    <= rr_tdata.si_tdata;
        end procedure;

        procedure do_stack_popr_0 is begin
            set_cmd_0(MICRO_MEM_OP or MICRO_ALU_OP);

            -- memory cmd
            mem_read_word(seg => rr_tdata.ss_seg_val, addr => rr_tdata.sp_val);

            -- alu cmd
            update_sp(upd_when => rr_tdata.dreg /= SP,
                sp_val => rr_tdata.sp_val,
                offset => rr_tdata.sp_offset
            );
        end procedure;

        procedure do_stack_popr_1 is begin
            set_cmd_1(MICRO_MRD_OP);
            micro_tdata.mem_dreg  <= rr_tdata_buf.dreg;
            micro_tdata.mem_dmask <= rr_tdata_buf.dmask;
        end procedure;

        procedure do_stack_popm_0 is begin
            set_cmd_0(MICRO_MEM_OP or MICRO_ALU_OP);

            -- memory cmd
            mem_read_word(seg => rr_tdata.ss_seg_val, addr => rr_tdata.sp_val);

            -- alu cmd
            update_sp(upd_when => rr_tdata.dreg /= SP,
                sp_val => rr_tdata.sp_val,
                offset => rr_tdata.sp_offset
            );
        end procedure;

        procedure do_stack_popm_1 is begin
            set_cmd_1(MICRO_MRD_OP or MICRO_MEM_OP);

            micro_tdata.mem_cmd      <= '1';
            micro_tdata.mem_width    <= rr_tdata_buf.w;
            micro_tdata.mem_seg      <= rr_tdata_buf.seg_val;
            micro_tdata.mem_addr     <= ea_val_plus_disp;
            micro_tdata.mem_data_src <= MEM_DATA_SRC_FIFO;
        end procedure;

        procedure do_stack_popa_0 is begin
            set_cmd_0(MICRO_MEM_OP);

            -- memory cmd
            mem_read_word(seg => rr_tdata.ss_seg_val, addr => rr_tdata.sp_val);
        end procedure;

        procedure do_stack_popa_1 is begin
            micro_tdata.mem_addr <= sp_val;

            case micro_cnt is
                when 15 =>
                    set_cmd_1(MICRO_MEM_OP);
                    -- READ MEM FROM SP
                    micro_tdata.mem_cmd <= '0';
                    micro_tdata.mem_width <= '1';
                    micro_tdata.mem_seg <= rr_tdata_buf.ss_seg_val;
                when 9 =>
                    set_cmd_1(MICRO_ALU_OP or MICRO_MEM_OP);
                    -- alu cmd
                    update_sp(sp_val => sp_val, sp_offset => sp_offset);

                when 8 =>
                    set_cmd_1(MICRO_MRD_OP);
                    micro_tdata.mem_dreg  <= DI;
                    micro_tdata.mem_dmask <= rr_tdata_buf.dmask;
                when 7 =>
                    micro_tdata.mem_dreg  <= SI;
                when 6 =>
                    micro_tdata.mem_dreg  <= BP;
                when 5 =>
                    --skip SP;
                    micro_tdata.mem_dreg  <= ZERO;
                when 4 =>
                    micro_tdata.mem_dreg  <= BX;
                when 3 =>
                    micro_tdata.mem_dreg  <= DX;
                when 2 =>
                    micro_tdata.mem_dreg  <= CX;
                when 1 =>
                    micro_tdata.mem_dreg  <= AX;
                when others => null;
            end case;
        end procedure;

        procedure do_stack_pushm_0 is begin
            set_cmd_0(MICRO_MEM_OP);

            -- memory cmd
            mem_read_word(seg => rr_tdata.seg_val, addr => ea_val_plus_disp_next);
        end procedure;

        procedure do_stack_pushm_1 is begin
            set_cmd_1(MICRO_MEM_OP or MICRO_MRD_OP or MICRO_ALU_OP);

            -- mem cmd
            micro_tdata.mem_cmd <= '1';
            micro_tdata.mem_seg <= rr_tdata_buf.ss_seg_val;
            micro_tdata.mem_addr <= rr_tdata_buf.sp_val;
            micro_tdata.mem_data_src <= MEM_DATA_SRC_FIFO;

            -- alu cmd
            update_sp(sp_val => rr_tdata_buf.sp_val);
        end procedure;

        procedure do_stack_pushr_0 is begin
            set_cmd_0(MICRO_MEM_OP or MICRO_ALU_OP);

            -- memory cmd
            mem_write_imm(seg => rr_tdata.ss_seg_val, addr => rr_tdata.sp_val, val => rr_tdata.sreg_val, w => rr_tdata.w);

            -- alu cmd
            update_sp(sp_val => rr_tdata.sp_val);
        end procedure;

        procedure do_stack_pushi_0 is begin
            set_cmd_0(MICRO_MEM_OP or MICRO_ALU_OP);

            -- memory cmd
            mem_write_imm(seg => rr_tdata.ss_seg_val, addr => rr_tdata.sp_val, val => rr_tdata.data, w => rr_tdata.w);

            -- alu cmd
            update_sp(sp_val => rr_tdata.sp_val);
        end procedure;

        procedure do_stack_pusha_0 is begin
            set_cmd_0(MICRO_MEM_OP);

            -- memory cmd
            micro_tdata.mem_cmd      <= '1';
            micro_tdata.mem_width    <= rr_tdata.w;
            micro_tdata.mem_seg      <= rr_tdata.ss_seg_val;
            micro_tdata.mem_addr     <= rr_tdata.sp_val;
            micro_tdata.mem_data_src <= MEM_DATA_SRC_IMM;
            micro_tdata.mem_data     <= rr_tdata.ax_tdata;
        end procedure;

        procedure do_stack_pusha_1 is begin
            if (micro_cnt = 1) then
                set_cmd_1(MICRO_MEM_OP or MICRO_UNLK_OP or MICRO_ALU_OP);
            end if;

            -- alu cmd
            update_sp(sp_val => sp_val);

            -- mem cmd
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

        end procedure;

        procedure do_stack_enter_0 is begin
            set_cmd_0(MICRO_MEM_OP);

            -- push bp
            mem_write_imm(
                seg  => rr_tdata.ss_seg_val,
                addr => rr_tdata.sp_val,
                val  => rr_tdata.bp_tdata,
                w    => rr_tdata.w);

        end procedure;

        procedure do_stack_enter_1 is begin
            case micro_cnt is
                when 3 =>
                    set_cmd_1(MICRO_MEM_OP);

                    -- push frame_pointer
                    mem_write_imm(
                        seg     => rr_tdata_buf.ss_seg_val,
                        addr    => sp_val,
                        val     => frame_pointer,
                        w       => rr_tdata_buf.w);

                when 2 =>
                    set_cmd_1(MICRO_ALU_OP);
                    -- BP = frame_pointer
                    alu_command_imm(
                        cmd     => ALU_OP_ADD,
                        aval    => frame_pointer,
                        bval    => x"0000",
                        dreg    => BP,
                        dmask   => "11",
                        upd_fl  => '0');

                when 1 =>
                    set_cmd_1(MICRO_ALU_OP);
                    -- SP = SP - bytes
                    alu_command_imm(
                        cmd     => ALU_OP_SUB,
                        aval    => frame_pointer,
                        bval    => rr_tdata_buf.data,
                        dreg    => SP,
                        dmask   => "11",
                        upd_fl  => '0');

                when others =>
                    set_cmd_1(MICRO_MEM_OP);

                    -- push BP
                    mem_write_imm(
                        seg     => rr_tdata_buf.ss_seg_val,
                        addr    => sp_val,
                        val     => bp_val,
                        w       => rr_tdata_buf.w);

            end case;

        end procedure;

        procedure do_stack_leave_0 is begin
            set_cmd_0(MICRO_MEM_OP or MICRO_ALU_OP);

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
            set_cmd_1(MICRO_MRD_OP);
            micro_tdata.mem_dreg  <= rr_tdata_buf.dreg;
            micro_tdata.mem_dmask <= rr_tdata_buf.dmask;
        end procedure;

        procedure do_movu_cmd_0 is begin
            micro_tdata.alu_wb <= '0';

            case rr_tdata.dir is
                when I2M =>
                    set_cmd_0(MICRO_MEM_OP);

                    micro_tdata.mem_cmd <= '1';
                    micro_tdata.mem_width <= rr_tdata.w;
                    micro_tdata.mem_seg <= rr_tdata.seg_val;
                    micro_tdata.mem_addr <= ea_val_plus_disp_next;
                    micro_tdata.mem_data_src <= MEM_DATA_SRC_IMM;
                    micro_tdata.mem_data <= rr_tdata.data;

                when R2M =>
                    set_cmd_0(MICRO_MEM_OP);

                    micro_tdata.mem_cmd <= '1';
                    micro_tdata.mem_width <= rr_tdata.w;
                    micro_tdata.mem_seg <= rr_tdata.seg_val;
                    micro_tdata.mem_addr <= ea_val_plus_disp_next;
                    micro_tdata.mem_data_src <= MEM_DATA_SRC_IMM;
                    micro_tdata.mem_data <= rr_tdata.sreg_val;

                when M2R =>
                    set_cmd_0(MICRO_MEM_OP);

                    micro_tdata.mem_cmd <= '0';
                    micro_tdata.mem_width <= rr_tdata.w;
                    micro_tdata.mem_seg <= rr_tdata.seg_val;
                    micro_tdata.mem_addr <= ea_val_plus_disp_next;

                when R2F =>
                    set_cmd_0(MICRO_ALU_OP);

                    micro_tdata.alu_wb <= '1';
                    micro_tdata.alu_code <= ALU_OP_ADD;
                    micro_tdata.alu_upd_fl <= '0';
                    micro_tdata.alu_a_val <= (rr_tdata.sreg_val and x"00D5") or (x"0002");
                    micro_tdata.alu_b_val <= x"0000";
                    micro_tdata.alu_dreg <= rr_tdata.dreg;
                    micro_tdata.alu_dmask <= rr_tdata.dmask;

                when others =>
                    set_cmd_0(MICRO_NOP_OP);

            end case;
        end procedure;

        procedure do_movu_cmd_1 is begin
            set_cmd_1(MICRO_MRD_OP);
            micro_tdata.mem_dreg  <= rr_tdata_buf.dreg;
            micro_tdata.mem_dmask <= rr_tdata_buf.dmask;
        end procedure;

        procedure do_loop_cmd_0 is begin
            set_cmd_0(MICRO_ALU_OP);

            micro_tdata.jump_cond   <= j_never;
            micro_tdata.jump_imm    <= '0';
            micro_tdata.jump_cs_mem <= '0';
            micro_tdata.jump_ip_mem <= '0';
            micro_tdata.jump_cs     <= rr_tuser(31 downto 16);
            micro_tdata.jump_ip     <= ip_val_plus_disp_next;
            micro_tdata.jump_cx     <= rr_tdata.sreg_val;

            alu_command_imm(cmd => ALU_OP_ADD,
                aval   => rr_tdata.sreg_val,
                bval   => rr_tdata.data,
                dreg   => rr_tdata.dreg,
                dmask  => rr_tdata.dmask,
                upd_fl => '0');

        end procedure;

        procedure do_loop_cmd_1 is begin
            set_cmd_1(MICRO_JMP_OP or MICRO_UNLK_OP);

            micro_tdata.jump_imm <= '1';

            case (rr_tdata_buf.code(1 downto 0)) is
                when LOOP_OP(1 downto 0)    => micro_tdata.jump_cond <= cx_ne_0;
                when LOOP_OP_E(1 downto 0)  => micro_tdata.jump_cond <= cx_ne_0_and_zf;
                when LOOP_OP_NE(1 downto 0) => micro_tdata.jump_cond <= cx_ne_0_and_nzf;
                when LOOP_JCXZ(1 downto 0)  => micro_tdata.jump_cond <= cx_eq_0;
                when others                 => null;
            end case;

        end procedure;

        procedure do_bra_cmd_0 is begin
            set_cmd_0(MICRO_JMP_OP or MICRO_UNLK_OP);

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
                when others  => null;
            end case;

            micro_tdata.jump_imm <= '1';
            micro_tdata.jump_cs_mem <= '0';
            micro_tdata.jump_ip_mem <= '0';
            micro_tdata.jump_cs <= rr_tuser(31 downto 16);
            micro_tdata.jump_ip <= ip_val_plus_disp_next;
        end procedure;

        procedure do_jmp_0 is begin
            case rr_tdata.dir is
                when M2M =>
                    -- JMP_RM16 (memory) or JMP_M16_16
                    set_cmd_0(MICRO_MEM_OP);

                    -- configure mem cmd
                    mem_read(seg => rr_tdata.seg_val, addr => ea_val_plus_disp_next, w => rr_tdata.w);

                    -- configure jump
                    micro_tdata.jump_cond   <= j_never;
                    micro_tdata.jump_imm    <= '0';
                    micro_tdata.jump_cs_mem <= '0';
                    micro_tdata.jump_ip_mem <= '0';

                when others =>
                    -- JMP_RM16 (register)
                    set_cmd_0(MICRO_JMP_OP or MICRO_UNLK_OP);

                    micro_tdata.jump_imm    <= '1';
                    micro_tdata.jump_cs_mem <= '0';
                    micro_tdata.jump_ip_mem <= '0';
                    micro_tdata.jump_cond   <= j_always;

                    case (rr_tdata.code) is
                        when JMP_PTR16_16 =>
                            micro_tdata.jump_cs <= rr_tdata.data;
                            micro_tdata.jump_ip <= rr_tdata.disp;
                        when others =>
                            micro_tdata.jump_cs <= rr_tuser(31 downto 16);
                            micro_tdata.jump_ip <= rr_tdata.sreg_val;
                    end case;

            end case;
        end procedure;

        procedure do_jmp_1 is begin

            case rr_tdata_buf.code is
                when JMP_RM16 =>
                    set_cmd_1(MICRO_JMP_OP or MICRO_MRD_OP or MICRO_UNLK_OP);

                    -- update jump cmd
                    micro_tdata.jump_cs_mem <= '0';
                    micro_tdata.jump_ip_mem <= '1';
                    micro_tdata.jump_cond <= j_always;

                when others =>
                    -- JMP_M16_16
                    case micro_cnt is
                        when 2 =>
                            set_cmd_1(MICRO_JMP_OP or MICRO_MRD_OP or MICRO_MEM_OP);
                            -- update mem cmd
                            micro_tdata.mem_addr <= ea_val_plus_disp_p_2;
                            -- upd jump_ip
                            micro_tdata.jump_cs_mem <= '0';
                            micro_tdata.jump_ip_mem <= '1';

                        when others =>
                            set_cmd_1(MICRO_JMP_OP or MICRO_UNLK_OP);

                            -- update jump cmd
                            micro_tdata.jump_cs_mem <= '1';
                            micro_tdata.jump_ip_mem <= '0';
                            micro_tdata.jump_cond <= j_always;

                    end case;

            end case;

        end procedure;

        procedure do_call_ptr16_16_cmd_0 is begin
            set_cmd_0(MICRO_MEM_OP or MICRO_ALU_OP);

            -- push CS
            mem_write_imm(seg => rr_tdata.ss_seg_val, addr => rr_tdata.sp_val, val => rr_tuser(31 downto 16), w => rr_tdata.w);

            -- upd SP
            alu_command_imm(
                cmd     => ALU_OP_ADD,
                aval    => rr_tdata.sp_val,
                bval    => rr_tdata.sp_offset,
                dreg    => SP,
                dmask   => "11",
                upd_fl  => '0');

        end procedure;

        procedure do_call_ptr16_16_cmd_1 is begin

                set_cmd_1(MICRO_MEM_OP);
                -- push IP
                mem_write_imm(seg => rr_tdata_buf.ss_seg_val, addr => sp_val, val => rr_tuser_buf(15 downto 0), w => rr_tdata_buf.w);

        end procedure;

        procedure do_call_rel16_cmd_0 is begin
            set_cmd_0(MICRO_MEM_OP or MICRO_ALU_OP);

            -- push IP
            mem_write_imm(seg => rr_tdata.ss_seg_val, addr => rr_tdata.sp_val, val => rr_tuser(15 downto 0), w => rr_tdata.w);

            -- upd SP
            update_sp(sp_val => rr_tdata.sp_val);

        end procedure;

        procedure do_call_rm16_cmd_0 is begin
            set_cmd_0(MICRO_MEM_OP or MICRO_ALU_OP);

            -- push IP
            mem_write_imm(seg => rr_tdata.ss_seg_val, addr => rr_tdata.sp_val, val => rr_tuser(15 downto 0), w => rr_tdata.w);

            -- upd SP
            update_sp(sp_val => rr_tdata.sp_val);

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
                        set_cmd_1(MICRO_NOP_OP);
                    else
                        set_cmd_1(MICRO_MEM_OP);
                    end if;

                    -- configure mem cmd
                    mem_read(seg => rr_tdata_buf.seg_val, addr => ea_val_plus_disp, w => rr_tdata_buf.w);
                when others =>
                    if (rr_tdata_buf.dir = R2R) then
                        set_cmd_1(MICRO_JMP_OP or MICRO_UNLK_OP);
                    else
                        set_cmd_1(MICRO_JMP_OP or MICRO_MRD_OP or MICRO_UNLK_OP);
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

            end case;

        end procedure;

        procedure do_call_mem16_16_0 is begin
            set_cmd_0(MICRO_MEM_OP);

            -- push CS
            mem_write_imm(seg => rr_tdata.ss_seg_val, addr => rr_tdata.sp_val, val => rr_tuser(31 downto 16), w => rr_tdata.w);

            -- jump cmd
            micro_tdata.jump_cond   <= j_never;
            micro_tdata.jump_imm    <= '0';
            micro_tdata.jump_cs_mem <= '0';
            micro_tdata.jump_ip_mem <= '0';
        end procedure;

        procedure do_call_mem16_16_1 is begin
            case micro_cnt is
                when 4 =>
                    set_cmd_1(MICRO_MEM_OP or MICRO_ALU_OP);
                    -- push IP
                    mem_write_imm(seg => rr_tdata_buf.ss_seg_val, addr => sp_val, val => rr_tuser_buf(15 downto 0), w => rr_tdata_buf.w);

                    -- upd SP
                    update_sp(sp_val => sp_val);

                when 3 =>
                    set_cmd_1(MICRO_MEM_OP);
                    -- configure mem cmd
                    mem_read(seg => rr_tdata_buf.seg_val, addr => ea_val_plus_disp, w => rr_tdata_buf.w);
                when 2 =>
                    set_cmd_1(MICRO_JMP_OP or MICRO_MRD_OP or MICRO_MEM_OP);
                    -- update mem cmd
                    micro_tdata.mem_addr <= ea_val_plus_disp_p_2;
                    -- upd jump_ip
                    micro_tdata.jump_cs_mem <= '0';
                    micro_tdata.jump_ip_mem <= '1';
                when others =>
                    set_cmd_1(MICRO_JMP_OP or MICRO_MRD_OP or MICRO_UNLK_OP);

                    -- update jump cmd
                    micro_tdata.jump_cs_mem <= '1';
                    micro_tdata.jump_ip_mem <= '0';
                    micro_tdata.jump_cond <= j_always;
            end case;
        end procedure;

        procedure do_ret_near_cmd_0 is begin
            set_cmd_0(MICRO_MEM_OP or MICRO_ALU_OP);

            -- pop IP
            mem_read(seg => rr_tdata.seg_val, addr => rr_tdata.sp_val, w => rr_tdata.w);

            -- upd SP
            update_sp(rr_tdata.sp_val, rr_tdata.sp_offset);

            -- jump cmd
            micro_tdata.jump_cond   <= j_never;
            micro_tdata.jump_imm    <= '1';
            micro_tdata.jump_cs_mem <= '0';
            micro_tdata.jump_ip_mem <= '0';
            micro_tdata.jump_cs     <= rr_tuser(31 downto 16);
        end procedure;

        procedure do_ret_near_cmd_1 is begin
            set_cmd_1(MICRO_JMP_OP or MICRO_MRD_OP or MICRO_UNLK_OP);

            -- update jump cmd
            micro_tdata.jump_cond   <= j_always;
            micro_tdata.jump_imm    <= '0';
            micro_tdata.jump_cs_mem <= '0';
            micro_tdata.jump_ip_mem <= '1';
            micro_tdata.jump_is_ret <= '1';
        end procedure;

        procedure do_ret_near_imm16_cmd_0 is begin
            set_cmd_0(MICRO_NOP_OP);
            -- empty command to catch sp_val - 2

            -- jump cmd
            micro_tdata.jump_cond   <= j_never;
            micro_tdata.jump_imm    <= '0';
            micro_tdata.jump_cs_mem <= '0';
            micro_tdata.jump_ip_mem <= '0';
            micro_tdata.jump_cs     <= rr_tuser(31 downto 16);
        end procedure;

        procedure do_ret_near_imm16_cmd_1 is begin
            case micro_cnt is
                when 2 =>
                    set_cmd_1(MICRO_MEM_OP or MICRO_ALU_OP);

                    -- pop IP
                    mem_read(seg => rr_tdata_buf.seg_val, addr => rr_tdata_buf.sp_val, w => rr_tdata_buf.w);

                    -- upd SP
                    update_sp(sp_val, rr_tdata_buf.data);

                when others =>
                    set_cmd_1(MICRO_JMP_OP or MICRO_MRD_OP or MICRO_UNLK_OP);

                    -- update jump cmd
                    micro_tdata.jump_cond   <= j_always;
                    micro_tdata.jump_cs_mem <= '0';
                    micro_tdata.jump_ip_mem <= '1';
                    micro_tdata.jump_is_ret <= '1';

            end case;
        end procedure;

        procedure do_ret_far_cmd_0 is begin
            set_cmd_0(MICRO_MEM_OP);

            -- pop IP
            mem_read(seg => rr_tdata.seg_val, addr => rr_tdata.sp_val, w => rr_tdata.w);

            -- jump cmd
            micro_tdata.jump_cond   <= j_never;
            micro_tdata.jump_imm    <= '0';
            micro_tdata.jump_cs_mem <= '0';
            micro_tdata.jump_ip_mem <= '0';
        end procedure;

        procedure do_ret_far_cmd_1 is begin
            case micro_cnt is
                when 2 =>
                    set_cmd_1(MICRO_MEM_OP or MICRO_MRD_OP or MICRO_ALU_OP or MICRO_JMP_OP);

                    -- pop CS
                    mem_read(seg => rr_tdata_buf.seg_val, addr => sp_val, w => rr_tdata_buf.w);

                    -- upd SP
                    update_sp(sp_val, sp_offset);

                    -- update jump cmd
                    micro_tdata.jump_cs_mem <= '0';
                    micro_tdata.jump_ip_mem <= '1';

                when others =>
                    set_cmd_1(MICRO_JMP_OP or MICRO_MRD_OP or MICRO_UNLK_OP);

                    -- update jump cmd
                    micro_tdata.jump_cond   <= j_always;
                    micro_tdata.jump_cs_mem <= '1';
                    micro_tdata.jump_ip_mem <= '0';
                    micro_tdata.jump_is_ret <= '1';

            end case;
        end procedure;

        procedure do_ret_far_imm16_cmd_0 is begin
            set_cmd_0(MICRO_MEM_OP);

            -- pop IP
            mem_read(seg => rr_tdata.seg_val, addr => rr_tdata.sp_val, w => rr_tdata.w);

            -- jump cmd
            micro_tdata.jump_cond   <= j_never;
            micro_tdata.jump_imm    <= '0';
            micro_tdata.jump_cs_mem <= '0';
            micro_tdata.jump_ip_mem <= '0';
        end procedure;

        procedure do_ret_far_imm16_cmd_1 is begin
            case micro_cnt is
                when 3 =>
                    set_cmd_1(MICRO_MEM_OP or MICRO_MRD_OP or MICRO_JMP_OP);

                    -- pop CS
                    mem_read(seg => rr_tdata_buf.seg_val, addr => sp_val, w => rr_tdata_buf.w);

                    -- update jump cmd
                    micro_tdata.jump_cs_mem <= '0';
                    micro_tdata.jump_ip_mem <= '1';

                when 2 =>
                    set_cmd_1(MICRO_JMP_OP or MICRO_MRD_OP or MICRO_ALU_OP);

                    -- upd SP
                    update_sp(sp_val, rr_tdata_buf.data);

                    -- update jump cmd
                    micro_tdata.jump_cs_mem <= '1';
                    micro_tdata.jump_ip_mem <= '0';

                when others =>
                    set_cmd_1(MICRO_UNLK_OP or MICRO_JMP_OP);
                    micro_tdata.jump_cond   <= j_always;
                    micro_tdata.jump_cs_mem <= '0';
                    micro_tdata.jump_ip_mem <= '0';
                    micro_tdata.jump_is_ret <= '1';

            end case;
        end procedure;

        procedure do_xlat_0 is begin
            set_cmd_0(MICRO_MEM_OP);
            -- mem cmd
            mem_read(seg => rr_tdata_buf.seg_val, addr => ea_val_plus_disp_next, w => rr_tdata_buf.w);
        end procedure;

        procedure do_xlat_1 is begin
            set_cmd_1(MICRO_MRD_OP);
            micro_tdata.mem_dreg  <= rr_tdata_buf.dreg;
            micro_tdata.mem_dmask <= rr_tdata_buf.dmask;
        end procedure;

        procedure initialize_signals is begin
            micro_tdata.trap      <= rr_tdata.fl_tdata(FLAG_TF);
            micro_tdata.alu_a_buf <= '0';
            micro_tdata.alu_a_mem <= '0';
            micro_tdata.alu_b_mem <= '0';
            micro_tdata.alu_w     <= rr_tdata.w;
            micro_tdata.mem_dreg  <= ZERO;

            -- no jumps by default
            micro_tdata.jump_cond   <= j_never;
            micro_tdata.jump_imm    <= '0';
            micro_tdata.jump_cs_mem <= '0';
            micro_tdata.jump_ip_mem <= '0';
            micro_tdata.jump_is_ret <= '0';
        end procedure;

    begin
        if rising_edge(clk) then
            if (resetn = '0') then
                micro_tvalid <= '0';
                micro_tlast  <= '0';
                micro_cnt    <= 0;
                micro_busy   <= '0';
            else
                -- valid
                if (trap_tvalid = '1' and trap_tready = '1') then
                    micro_tvalid <= '1';
                elsif (rr_tvalid = '1' and rr_tready = '1') then
                    micro_tvalid <= '1';
                elsif (micro_tready = '1' and micro_cnt = 0) then
                    micro_tvalid <= '0';
                end if;

                -- last
                if (trap_tvalid = '1' and trap_tready = '1') then
                    micro_tlast <= '0';
                elsif (rr_tvalid = '1' and rr_tready = '1') then
                    if (rr_tdata.fast_instr = '1' or micro_cnt_next = 0) then
                        micro_tlast <= '1';
                    elsif (micro_cnt_next /= 0) then
                        micro_tlast <= '0';
                    end if;
                elsif (micro_tvalid = '1' and micro_tready = '1') then
                    if (micro_cnt = 1) then
                        micro_tlast <= '1';
                    else
                        micro_tlast <= '0';
                    end if;
                end if;

                if (trap_tvalid = '1' and trap_tready = '1') then
                    micro_cnt <= 6;
                elsif (rr_tvalid = '1' and rr_tready = '1' and rr_tdata.fast_instr = '0') then
                    micro_cnt <= micro_cnt_next;
                elsif (micro_tvalid = '1' and micro_tready = '1') then
                    if micro_cnt /= 0 then
                        micro_cnt <= micro_cnt - 1;
                    end if;
                end if;

                if (trap_tvalid = '1' and trap_tready = '1') then
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

            if (trap_tvalid = '1' and trap_tready = '1') then
                micro_op    <= SYS;
                micro_code  <= SYS_TRAP_INT_OP;
            elsif (rr_tvalid = '1' and rr_tready = '1') then
                micro_op    <= rr_tdata.op;
                micro_code  <= rr_tdata.code;
            end if;

            if (rr_tvalid = '1' and rr_tready = '1') then
                rr_tdata_buf <= rr_tdata;
            end if;

            if (rr_tvalid = '1' and rr_tready = '1') then
                rr_tuser_buf <= rr_tuser;
            end if;

            if (rr_tvalid = '1' and rr_tready = '1') then
                ea_val_plus_disp <= ea_val_plus_disp_next;
            end if;

            if (trap_tvalid = '1' and trap_tready = '1') then
                initialize_signals;
                do_trap_0;

                micro_tdata.bpu_first <= '1';
                micro_tdata.bpu_taken <= '0';
                micro_tdata.bpu_bypass <= '1';
            elsif (rr_tvalid = '1' and rr_tready = '1') then
                set_undefined;
                initialize_signals;

                micro_tdata.inst_ss      <= rr_tdata.ss_seg_val;
                micro_tdata.inst_cs      <= rr_tuser(USER_T_CS);
                micro_tdata.inst_ip      <= rr_tuser(USER_T_IP);
                micro_tdata.inst_ip_next <= rr_tuser(USER_T_IP_NEXT);

                micro_tdata.bpu_taken_cs <= rr_tdata.bpu_taken_cs;
                micro_tdata.bpu_taken_ip <= rr_tdata.bpu_taken_ip;

                micro_tdata.bpu_first <= rr_tdata.bpu_first;
                micro_tdata.bpu_taken <= rr_tdata.bpu_taken;
                if rr_tdata.op = SYS then
                    micro_tdata.bpu_bypass <= '1';
                else
                    micro_tdata.bpu_bypass <= rr_tdata.bpu_bypass;
                end if;

                case (rr_tdata.op) is
                    when FEU        => do_nop_cmd_0;
                    when ALU        => do_alu_cmd_0;
                    when MULU       => do_mul_cmd_0;
                    when DIVU       => do_div_cmd_0;
                    when BCDU       => do_bcd_cmd;
                    when SHFU       => do_shf_cmd_0;
                    when XCHG       => do_xchg_cmd_0;
                    when MOVU       => do_movu_cmd_0;
                    when STR        => do_str_cmd;
                    when IO         => do_io_cmd;
                    when SET_FLAG   => do_set_flg_cmd_0;
                    when LOOPU      => do_loop_cmd_0;
                    when JMPU       => do_jmp_0;
                    when BRANCH     => do_bra_cmd_0;
                    when LFP =>
                        case rr_tdata.code is
                            when MISC_BOUND     => do_misc_bound_0;
                            when MISC_XLAT      => do_xlat_0;
                            when others         => do_lfp_cmd_0;
                        end case;
                    when STACKU =>
                        case rr_tdata.code is
                            when STACKU_POPR    => do_stack_popr_0;
                            when STACKU_POPM    => do_stack_popm_0;
                            when STACKU_POPA    => do_stack_popa_0;
                            when STACKU_PUSHM   => do_stack_pushm_0;
                            when STACKU_PUSHA   => do_stack_pusha_0;
                            when STACKU_ENTER   => do_stack_enter_0;
                            when STACKU_LEAVE   => do_stack_leave_0;
                            when STACKU_PUSHR   => do_stack_pushr_0;
                            when others         => do_stack_pushi_0;
                        end case;
                    when JCALL =>
                        case rr_tdata.code is
                            when CALL_REL16     => do_call_rel16_cmd_0;
                            when CALL_RM16      => do_call_rm16_cmd_0;
                            when CALL_PTR16_16  => do_call_ptr16_16_cmd_0;
                            when others         => do_call_mem16_16_0;
                        end case;
                    when RET =>
                        case rr_tdata.code is
                            when RET_NEAR       => do_ret_near_cmd_0;
                            when RET_NEAR_IMM16 => do_ret_near_imm16_cmd_0;
                            when RET_FAR        => do_ret_far_cmd_0;
                            when others         => do_ret_far_imm16_cmd_0;
                        end case;
                    when SYS =>
                        case rr_tdata.code is
                            when SYS_INT_INT_OP => do_sys_cmd_int_0;
                            when SYS_EXT_INT_OP => do_sys_cmd_int_0;
                            when SYS_IRET_OP    => do_sys_cmd_iret_0;
                            when others         => do_nop_cmd_0;
                        end case;
                    when others =>  do_nop_cmd_0;
                end case;

            elsif (micro_tvalid = '1' and micro_tready = '1') then
                case micro_op is
                    when ALU    => do_alu_cmd_1;
                    when MULU   => do_mul_cmd_1;
                    when DIVU   => do_div_cmd_1;
                    when SHFU   => do_shf_cmd_1;
                    when XCHG   => do_xchg_cmd_1;
                    when MOVU   => do_movu_cmd_1;
                    when LOOPU  => do_loop_cmd_1;
                    when JMPU   => do_jmp_1;
                    when LFP =>
                        case micro_code is
                            when MISC_BOUND     => do_misc_bound_1;
                            when MISC_XLAT      => do_xlat_1;
                            when others         => do_lfp_cmd_1;
                        end case;
                    when STACKU =>
                        case micro_code is
                            when STACKU_POPR    => do_stack_popr_1;
                            when STACKU_POPM    => do_stack_popm_1;
                            when STACKU_POPA    => do_stack_popa_1;
                            when STACKU_PUSHM   => do_stack_pushm_1;
                            when STACKU_ENTER   => do_stack_enter_1;
                            when STACKU_LEAVE   => do_stack_leave_1;
                            when others         => do_stack_pusha_1;
                        end case;
                    when JCALL =>
                        case micro_code is
                            when CALL_RM16      => do_call_rm16_cmd_1;
                            when CALL_PTR16_16  => do_call_ptr16_16_cmd_1;
                            when others         => do_call_mem16_16_1;
                        end case;
                    when RET =>
                        case micro_code is
                            when RET_NEAR       => do_ret_near_cmd_1;
                            when RET_NEAR_IMM16 => do_ret_near_imm16_cmd_1;
                            when RET_FAR        => do_ret_far_cmd_1;
                            when others         => do_ret_far_imm16_cmd_1;
                        end case;
                    when SYS =>
                        case micro_code is
                            when SYS_INT_INT_OP => do_sys_cmd_int_1;
                            when SYS_IRET_OP    => do_sys_cmd_iret_1;
                            when SYS_EXT_INT_OP => do_sys_cmd_int_1;
                            when SYS_TRAP_INT_OP=> do_trap_1;
                            when others         => null;
                        end case;

                    when others => null;
                end case;
            end if;

        end if;
    end process;

    stack_handler : process (clk) begin
        if rising_edge(clk) then
            -- datapath
            if (rr_tvalid = '1' and rr_tready = '1') then
                frame_pointer <= rr_tdata.sp_val;
            end if;

            if (trap_tvalid = '1' and trap_tready = '1') then
                sp_offset <= x"FFFE";
            elsif (rr_tvalid = '1' and rr_tready = '1') then
                sp_offset <= rr_tdata.sp_offset;
            end if;

            if (trap_tvalid = '1' and trap_tready = '1') then
                sp_val <= std_logic_vector(unsigned(sp_tdata) - to_unsigned(2, 16));
            elsif (rr_tvalid = '1' and rr_tready = '1') then
                sp_val <= rr_tdata.sp_val + rr_tdata.sp_offset;
            elsif (micro_tvalid = '1' and micro_tready = '1') then
                sp_val <= sp_val + sp_offset;
            end if;

            if (rr_tvalid = '1' and rr_tready = '1') then
                bp_val <= std_logic_vector(unsigned(rr_tdata.bp_tdata) - to_unsigned(2, 16));
            elsif (micro_tvalid = '1' and micro_tready = '1') then
                bp_val <= std_logic_vector(unsigned(bp_val) - to_unsigned(2, 16));
            end if;
        end if;
    end process;

    interrupts_handler : process (clk) begin
        if rising_edge(clk) then
            -- datapath
            if (trap_tvalid = '1' and trap_tready = '1') then
                interrupt_no <= x"00" & trap_tuser;
            elsif (rr_tvalid = '1' and rr_tready = '1') then
                interrupt_no <= rr_tdata.data;
            end if;

            if (trap_tvalid = '1' and trap_tready = '1') then
                if (trap_tuser = x"01") then
                    -- trap caused by TF always points to current instruction
                    -- in the queue whatever it is
                    interrupt_next_cs <= rr_tuser(USER_T_CS);
                    interrupt_next_ip <= rr_tuser(USER_T_IP);
                elsif (trap_tuser = x"05") then
                    -- bound instruction trap always points to itself
                    interrupt_next_cs <= trap_tdata(INTR_T_CS);
                    interrupt_next_ip <= trap_tdata(INTR_T_IP);
                else
                    -- div instruction points to the next instruction
                    -- after itself in 8086
                    interrupt_next_cs <= trap_tdata(INTR_T_CS);
                    interrupt_next_ip <= trap_tdata(INTR_T_IP);
                end if;
            elsif (rr_tvalid = '1' and rr_tready = '1') then
                interrupt_next_cs <= rr_tuser(USER_T_CS);
                if (rr_tdata.op = SYS and rr_tdata.code = SYS_EXT_INT_OP) then
                    interrupt_next_ip <= rr_tuser(USER_T_IP);
                else
                    interrupt_next_ip <= rr_tuser(USER_T_IP_NEXT);
                end if;
            end if;

            if (rr_tvalid = '1' and rr_tready = '1') then
                interrupt_flags <= rr_tdata.fl_tdata;
            end if;

            if (trap_tvalid = '1' and trap_tready = '1') then
                interrupt_ss_seg_val <= ss_tdata;
            elsif (rr_tvalid = '1' and rr_tready = '1') then
                interrupt_ss_seg_val <= rr_tdata.ss_seg_val;
            end if;
        end if;
    end process;

    ack_ext_interrupt_proc : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                ext_intr_s_tready <= '0';
            else

                if (rr_tvalid = '1' and rr_tready = '1') then
                    if (ext_intr_s_tvalid = '1' and rr_tdata.op = SYS and rr_tdata.code = SYS_EXT_INT_OP) then
                        ext_intr_s_tready <= '1';
                    else
                        ext_intr_s_tready <= '0';
                    end if;
                end if;

            end if;
        end if;
    end process;

end architecture;
