
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

entity cpu86_exec_register_reader is
    port (
        clk                     : in std_logic;
        resetn                  : in std_logic;

        s_axis_instr_tvalid     : in std_logic;
        s_axis_instr_tready     : out std_logic;
        s_axis_instr_tdata      : in decoded_instr_t;
        s_axis_instr_tuser      : in user_t;

        s_axis_ext_intr_tvalid  : in std_logic;
        s_axis_ext_intr_tdata   : in std_logic_vector(7 downto 0);

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

        m_axis_rr_tvalid        : out std_logic;
        m_axis_rr_tready        : in std_logic;
        m_axis_rr_tdata         : out rr_instr_t;
        m_axis_rr_tuser         : out user_t;

        dbg_out_valid           : out std_logic;
        dbg_out_cs              : out std_logic_vector(15 downto 0);
        dbg_out_ip              : out std_logic_vector(15 downto 0);
        dbg_out_op              : out std_logic_vector(4 downto 0);
        dbg_out_dir             : out std_logic_vector(2 downto 0);
        dbg_out_code            : out std_logic_vector(3 downto 0);
        dbg_out_sreg            : out std_logic_vector(3 downto 0);
        dbg_out_dreg            : out std_logic_vector(3 downto 0);
        dbg_out_ax              : out std_logic_vector(15 downto 0);
        dbg_out_bx              : out std_logic_vector(15 downto 0);
        dbg_out_cx              : out std_logic_vector(15 downto 0);
        dbg_out_dx              : out std_logic_vector(15 downto 0);
        dbg_out_bp              : out std_logic_vector(15 downto 0);
        dbg_out_sp              : out std_logic_vector(15 downto 0);
        dbg_out_di              : out std_logic_vector(15 downto 0);
        dbg_out_si              : out std_logic_vector(15 downto 0);
        dbg_out_fl              : out std_logic_vector(15 downto 0)
    );
end entity cpu86_exec_register_reader;

architecture rtl of cpu86_exec_register_reader is

    component signal_tap is
        port (
            acq_data_in    : in std_logic_vector(63 downto 0) := (others => 'X'); -- acq_data_in
            acq_trigger_in : in std_logic_vector( 0 downto 0) := (others => 'X'); -- acq_trigger_in
            acq_clk        : in std_logic                     := 'X';             -- clk
            storage_enable : in std_logic                     := 'X'              -- storage_enable
        );
    end component signal_tap;

    type ext_intr_mode_t is (ST_IDLE, ST_ACK, ST_DONE);

    signal instr_tvalid             : std_logic;
    signal instr_tready             : std_logic;
    signal instr_tdata              : decoded_instr_t;
    signal instr_tuser              : user_t;
    signal instr_hazards_resolved   : std_logic;
    signal instr_tready_mask        : std_logic;
    signal instr_wait_fl_valid      : std_logic;

    signal rr_tvalid                : std_logic;
    signal rr_tready                : std_logic;
    signal rr_tdata                 : rr_instr_t;
    signal rr_tuser                 : user_t;

    signal seg_tdata                : std_logic_vector(15 downto 0);
    signal sreg_tdata               : std_logic_vector(15 downto 0);
    signal dreg_tdata               : std_logic_vector(15 downto 0);
    signal ea_tdata                 : std_logic_vector(15 downto 0);

    signal intr_mask                : std_logic;

    signal seg_override_tvalid      : std_logic;
    signal seg_override_tdata       : std_logic_vector(15 downto 0);

    signal combined_instr           : std_logic;
    signal skip_next                : std_logic;

    signal ext_intr_tvalid          : std_logic;
    signal ext_intr_mode            : ext_intr_mode_t;
    signal ext_intr_tdata           : std_logic_vector(7 downto 0);

    signal vld_valid                : std_logic;
    signal vld_skip_next            : std_logic;
    signal vld_cs                   : std_logic_vector(15 downto 0);
    signal vld_ip                   : std_logic_vector(15 downto 0);
    signal vld_op                   : std_logic_vector(4 downto 0);
    signal vld_dir                  : std_logic_vector(2 downto 0);
    signal vld_code                 : std_logic_vector(3 downto 0);
    signal vld_sreg                 : std_logic_vector(3 downto 0);
    signal vld_dreg                 : std_logic_vector(3 downto 0);
    signal vld_ax                   : std_logic_vector(15 downto 0);
    signal vld_bx                   : std_logic_vector(15 downto 0);
    signal vld_cx                   : std_logic_vector(15 downto 0);
    signal vld_dx                   : std_logic_vector(15 downto 0);
    signal vld_bp                   : std_logic_vector(15 downto 0);
    signal vld_sp                   : std_logic_vector(15 downto 0);
    signal vld_di                   : std_logic_vector(15 downto 0);
    signal vld_si                   : std_logic_vector(15 downto 0);
    signal vld_fl                   : std_logic_vector(15 downto 0);

    -- signal acq_data_in              : std_logic_vector(63 downto 0);
    -- signal acq_trigger_in           : std_logic_vector(0 downto 0);
    -- signal storage_enable           : std_logic;

    -- signal test_0_cnt               : std_logic_vector(15 downto 0) := (others => '0') ;
    -- signal test_1_cnt               : std_logic_vector(15 downto 0) := (others => '0') ;

begin

    -- i/o assigns
    instr_tvalid            <= s_axis_instr_tvalid;
    s_axis_instr_tready     <= instr_tready;
    instr_tdata             <= s_axis_instr_tdata;
    instr_tuser             <= s_axis_instr_tuser;

    m_axis_rr_tvalid        <= rr_tvalid;
    rr_tready               <= m_axis_rr_tready;
    m_axis_rr_tdata         <= rr_tdata;
    m_axis_rr_tuser         <= rr_tuser;

    ext_intr_tvalid         <= s_axis_ext_intr_tvalid;
    ext_intr_tdata          <= s_axis_ext_intr_tdata;

    dbg_out_valid           <= vld_valid;
    dbg_out_cs              <= vld_cs;
    dbg_out_ip              <= vld_ip;
    dbg_out_op              <= vld_op;
    dbg_out_dir             <= vld_dir;
    dbg_out_code            <= vld_code;
    dbg_out_sreg            <= vld_sreg;
    dbg_out_dreg            <= vld_dreg;
    dbg_out_ax              <= vld_ax;
    dbg_out_bx              <= vld_bx;
    dbg_out_cx              <= vld_cx;
    dbg_out_dx              <= vld_dx;
    dbg_out_bp              <= vld_bp;
    dbg_out_sp              <= vld_sp;
    dbg_out_di              <= vld_di;
    dbg_out_si              <= vld_si;
    dbg_out_fl              <= vld_fl;

    -- acq_data_in(63 downto 60) <= (others => '0');
    -- acq_data_in(59) <= flags_s_tdata(FLAG_IF);
    -- acq_data_in(58) <= ext_intr_tvalid;
    -- acq_data_in(57) <= rr_tvalid;
    -- acq_data_in(56) <= rr_tready;

    -- acq_data_in(55) <= ax_s_tvalid;
    -- acq_data_in(54) <= bx_s_tvalid;
    -- acq_data_in(53) <= cx_s_tvalid;
    -- acq_data_in(52) <= dx_s_tvalid;
    -- acq_data_in(51) <= bp_s_tvalid;
    -- acq_data_in(50) <= si_s_tvalid;
    -- acq_data_in(49) <= di_s_tvalid;
    -- acq_data_in(48) <= sp_s_tvalid;
    -- acq_data_in(47) <= ds_s_tvalid;
    -- acq_data_in(46) <= es_s_tvalid;
    -- acq_data_in(45) <= ss_s_tvalid;
    -- acq_data_in(44) <= flags_s_tvalid;

    -- acq_data_in(43) <= instr_tdata.wait_ax;
    -- acq_data_in(42) <= instr_tdata.wait_bx;
    -- acq_data_in(41) <= instr_tdata.wait_cx;
    -- acq_data_in(40) <= instr_tdata.wait_dx;
    -- acq_data_in(39) <= instr_tdata.wait_bp;
    -- acq_data_in(38) <= instr_tdata.wait_si;
    -- acq_data_in(37) <= instr_tdata.wait_di;
    -- acq_data_in(36) <= instr_tdata.wait_sp;
    -- acq_data_in(35) <= instr_tdata.wait_ds;
    -- acq_data_in(34) <= instr_tdata.wait_es;
    -- acq_data_in(33) <= instr_tdata.wait_ss;
    -- acq_data_in(32) <= instr_tdata.wait_fl;

    -- acq_data_in( 31 downto 16) <= test_1_cnt; --rr_tuser(USER_T_CS);
    -- acq_data_in( 15 downto  0) <= test_0_cnt; --rr_tuser(USER_T_IP);

    -- acq_trigger_in(0) <= '1'; --when ext_intr_tvalid = '1' and ext_intr_mode = ST_ACK else '0';
    -- storage_enable    <= '1'; --when ext_intr_tvalid = '1' and ext_intr_mode = ST_ACK else '0';

    -- u0 : component signal_tap port map (
    --     acq_clk         => clk,            -- acq_clk
    --     acq_data_in     => acq_data_in,    -- acq_data_in
    --     acq_trigger_in  => acq_trigger_in, -- acq_trigger_in
    --     storage_enable  => storage_enable  -- storage_enable
    -- );


    process (all) begin

        case instr_tdata.smask is
            when "01" =>
                sreg_tdata(15 downto 8) <= (others => '0');
                case instr_tdata.sreg is
                    when AX     => sreg_tdata(7 downto 0) <= ax_s_tdata(7 downto 0);
                    when BX     => sreg_tdata(7 downto 0) <= bx_s_tdata(7 downto 0);
                    when CX     => sreg_tdata(7 downto 0) <= cx_s_tdata(7 downto 0);
                    when DX     => sreg_tdata(7 downto 0) <= dx_s_tdata(7 downto 0);
                    when FL     => sreg_tdata(7 downto 0) <= flags_s_tdata(7 downto 0);
                    when others => sreg_tdata(7 downto 0) <= ax_s_tdata(7 downto 0);
                end case;

            when "10" =>
                sreg_tdata(15 downto 8) <= (others => '0');
                case instr_tdata.sreg is
                    when AX     => sreg_tdata(7 downto 0) <= ax_s_tdata(15 downto 8);
                    when BX     => sreg_tdata(7 downto 0) <= bx_s_tdata(15 downto 8);
                    when CX     => sreg_tdata(7 downto 0) <= cx_s_tdata(15 downto 8);
                    when DX     => sreg_tdata(7 downto 0) <= dx_s_tdata(15 downto 8);
                    when others => sreg_tdata(7 downto 0) <= ax_s_tdata(15 downto 8);
                end case;

            when others =>
                case instr_tdata.sreg is
                    when AX     => sreg_tdata <= ax_s_tdata;
                    when BX     => sreg_tdata <= bx_s_tdata;
                    when CX     => sreg_tdata <= cx_s_tdata;
                    when DX     => sreg_tdata <= dx_s_tdata;
                    when BP     => sreg_tdata <= bp_s_tdata;
                    when SI     => sreg_tdata <= si_s_tdata;
                    when DI     => sreg_tdata <= di_s_tdata;
                    when SP     => sreg_tdata <= sp_s_tdata;
                    when CS     => sreg_tdata <= instr_tuser(31 downto 16);
                    when SS     => sreg_tdata <= ss_s_tdata;
                    when DS     => sreg_tdata <= ds_s_tdata;
                    when ES     => sreg_tdata <= es_s_tdata;
                    when FL     => sreg_tdata <= flags_s_tdata;
                    when others => sreg_tdata <= ax_s_tdata;
                end case;
        end case;

        if (seg_override_tvalid = '1') then
            seg_tdata <= seg_override_tdata;
        else
            case instr_tdata.ea is
                when BP_SI_DISP | BP_DI_DISP | BP_DISP =>
                    seg_tdata <= ss_s_tdata;
                when others =>
                    seg_tdata <= ds_s_tdata;
            end case;
        end if;

        case instr_tdata.dmask is
            when "01" =>
                dreg_tdata(15 downto 8) <= (others => '0');
                case instr_tdata.dreg is
                    when AX     => dreg_tdata(7 downto 0) <= ax_s_tdata(7 downto 0);
                    when BX     => dreg_tdata(7 downto 0) <= bx_s_tdata(7 downto 0);
                    when CX     => dreg_tdata(7 downto 0) <= cx_s_tdata(7 downto 0);
                    when DX     => dreg_tdata(7 downto 0) <= dx_s_tdata(7 downto 0);
                    when FL     => dreg_tdata(7 downto 0) <= flags_s_tdata(7 downto 0);
                    when others => dreg_tdata(7 downto 0) <= ax_s_tdata(7 downto 0);
                end case;

            when "10" =>
                dreg_tdata(15 downto 8) <= (others => '0');
                case instr_tdata.dreg is
                    when AX     => dreg_tdata(7 downto 0) <= ax_s_tdata(15 downto 8);
                    when BX     => dreg_tdata(7 downto 0) <= bx_s_tdata(15 downto 8);
                    when CX     => dreg_tdata(7 downto 0) <= cx_s_tdata(15 downto 8);
                    when DX     => dreg_tdata(7 downto 0) <= dx_s_tdata(15 downto 8);
                    when others => dreg_tdata(7 downto 0) <= ax_s_tdata(15 downto 8);
                end case;

            when others =>
                case instr_tdata.dreg is
                    when AX     => dreg_tdata <= ax_s_tdata;
                    when BX     => dreg_tdata <= bx_s_tdata;
                    when CX     => dreg_tdata <= cx_s_tdata;
                    when DX     => dreg_tdata <= dx_s_tdata;
                    when BP     => dreg_tdata <= bp_s_tdata;
                    when SI     => dreg_tdata <= si_s_tdata;
                    when DI     => dreg_tdata <= di_s_tdata;
                    when SP     => dreg_tdata <= sp_s_tdata;
                    when FL     => dreg_tdata <= flags_s_tdata;
                    when others => dreg_tdata <= ax_s_tdata;
                end case;
        end case;

        case instr_tdata.ea is
            when BX_SI_DISP => ea_tdata <= std_logic_vector(unsigned(bx_s_tdata) + unsigned(si_s_tdata));
            when BX_DI_DISP => ea_tdata <= std_logic_vector(unsigned(bx_s_tdata) + unsigned(di_s_tdata));
            when BP_SI_DISP => ea_tdata <= std_logic_vector(unsigned(bp_s_tdata) + unsigned(si_s_tdata));
            when BP_DI_DISP => ea_tdata <= std_logic_vector(unsigned(bp_s_tdata) + unsigned(di_s_tdata));
            when XLAT       => ea_tdata <= std_logic_vector(unsigned(bx_s_tdata) + unsigned(x"00" & ax_s_tdata(7 downto 0)));
            when SI_DISP    => ea_tdata <= si_s_tdata;
            when DI_DISP    => ea_tdata <= di_s_tdata;
            when BP_DISP    => ea_tdata <= bp_s_tdata;
            when BX_DISP    => ea_tdata <= bx_s_tdata;
            when others     => ea_tdata <= (others => '0');
        end case;

    end process;

    instr_hazards_resolved <= '1' when
        (instr_tdata.wait_ax = '0' or (instr_tdata.wait_ax = '1' and ax_s_tvalid = '1' and ax_m_lock_tvalid = '0')) and
        (instr_tdata.wait_bx = '0' or (instr_tdata.wait_bx = '1' and bx_s_tvalid = '1' and bx_m_lock_tvalid = '0')) and
        (instr_tdata.wait_cx = '0' or (instr_tdata.wait_cx = '1' and cx_s_tvalid = '1' and cx_m_lock_tvalid = '0')) and
        (instr_tdata.wait_dx = '0' or (instr_tdata.wait_dx = '1' and dx_s_tvalid = '1' and dx_m_lock_tvalid = '0')) and
        (instr_tdata.wait_bp = '0' or (instr_tdata.wait_bp = '1' and bp_s_tvalid = '1' and bp_m_lock_tvalid = '0')) and
        (instr_tdata.wait_si = '0' or (instr_tdata.wait_si = '1' and si_s_tvalid = '1' and si_m_lock_tvalid = '0')) and
        (instr_tdata.wait_di = '0' or (instr_tdata.wait_di = '1' and di_s_tvalid = '1' and di_m_lock_tvalid = '0')) and
        (instr_tdata.wait_sp = '0' or (instr_tdata.wait_sp = '1' and sp_s_tvalid = '1' and sp_m_lock_tvalid = '0')) and
        (instr_tdata.wait_ds = '0' or (instr_tdata.wait_ds = '1' and ds_s_tvalid = '1' and ds_m_lock_tvalid = '0')) and
        (instr_tdata.wait_es = '0' or (instr_tdata.wait_es = '1' and es_s_tvalid = '1' and es_m_lock_tvalid = '0')) and
        (instr_tdata.wait_ss = '0' or (instr_tdata.wait_ss = '1' and ss_s_tvalid = '1' and ss_m_lock_tvalid = '0')) and
        (instr_tdata.wait_fl = '0' or (instr_tdata.wait_fl = '1' and flags_s_tvalid = '1' and flags_m_lock_tvalid = '0'))
    else '0';

    instr_tready <= '1' when instr_tready_mask = '0' and instr_wait_fl_valid = '0' and
        ((instr_tvalid = '1' and instr_hazards_resolved = '1')) and
        (rr_tvalid = '0' or (rr_tvalid = '1' and rr_tready = '1')) else '0';

    -- controlling instruction queue
    instr_flow_controller : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                instr_tready_mask <= '0';
            else
                if  (instr_tvalid = '1' and instr_tready = '1' and instr_tdata.op = SYS and instr_tdata.code = SYS_HLT_OP)
                    or
                    (
                        (instr_tvalid = '0' or (instr_tvalid = '1' and instr_tdata.op /= PREFIX and instr_tdata.op /= SYS)) and
                        (ext_intr_tvalid = '1' and ext_intr_mode = ST_IDLE and combined_instr = '0')
                    )
                then
                    instr_tready_mask <= '1';
                end if;
            end if;
        end if;
    end process;

    -- forcing instruction queue to stall till flag is valid after POPF and IRET instructions.
    -- it's necessary since we can change TF and IF bits and they affect execution of the next instructions
    instr_wait_fl_valid_proc : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                instr_wait_fl_valid <= '0';
            else
                if (instr_tvalid = '1' and instr_tready = '1') then
                    if ((instr_tdata.op = STACKU and instr_tdata.code = STACKU_POPR and instr_tdata.dreg = FL) or
                        (instr_tdata.op = SYS and instr_tdata.code = SYS_IRET_OP)) then
                        instr_wait_fl_valid <= '1';
                    end if;
                elsif (instr_wait_fl_valid = '1' and flags_s_tvalid = '1' and flags_m_lock_tvalid = '0') then
                    instr_wait_fl_valid <= '0';
                end if;
            end if;
        end if;
    end process;

    -- handling external interrupt process
    ext_interrupt_process : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                ext_intr_mode <= ST_IDLE;
            else

                -- there is a waiting external interrupt and we locked the instruction queue
                if (ext_intr_tvalid = '1' and instr_tready_mask = '1' and ext_intr_mode = ST_IDLE) then
                    -- if there is an external interrupt then we wait till we have the next instruction
                    -- from the instruction queue and we have passed the current instruction next
                    -- then we can acknowledge the interrupt request
                    if (instr_tvalid = '1' and rr_tvalid = '0' and combined_instr = '0' and
                        ss_s_tvalid = '1' and sp_s_tvalid = '1' and flags_s_tvalid = '1')
                    then
                        ext_intr_mode <= ST_ACK;
                    end if;
                elsif (ext_intr_tvalid = '1' and ext_intr_mode = ST_ACK) then
                    ext_intr_mode <= ST_DONE;
                end if;

            end if;
        end if;
    end process;

    -- locking registers to update process
    reg_lock_proc: process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                ax_m_lock_tvalid <= '0';
                bx_m_lock_tvalid <= '0';
                cx_m_lock_tvalid <= '0';
                dx_m_lock_tvalid <= '0';
                bp_m_lock_tvalid <= '0';
                sp_m_lock_tvalid <= '0';
                si_m_lock_tvalid <= '0';
                di_m_lock_tvalid <= '0';

                ds_m_lock_tvalid <= '0';
                es_m_lock_tvalid <= '0';
                ss_m_lock_tvalid <= '0';

                flags_m_lock_tvalid <= '0';
            else

                if (instr_tvalid = '1' and instr_tready = '1') then
                    if (instr_tdata.lock_ax = '1') or
                        (instr_tdata.lock_all = '1') or
                        (instr_tdata.lock_dreg = '1' and instr_tdata.dreg = AX) or
                        (instr_tdata.lock_sreg = '1' and instr_tdata.sreg = AX)
                    then
                        ax_m_lock_tvalid <= '1';
                    else
                        ax_m_lock_tvalid <= '0';
                    end if;
                else
                    ax_m_lock_tvalid <= '0';
                end if;

                if (instr_tvalid = '1' and instr_tready = '1') then
                    if (instr_tdata.lock_all = '1') or
                        (instr_tdata.lock_dreg = '1' and instr_tdata.dreg = BX) or
                        (instr_tdata.lock_sreg = '1' and instr_tdata.sreg = BX)
                    then
                        bx_m_lock_tvalid <= '1';
                    else
                        bx_m_lock_tvalid <= '0';
                    end if;
                else
                    bx_m_lock_tvalid <= '0';
                end if;

                if (instr_tvalid = '1' and instr_tready = '1') then
                    if (instr_tdata.lock_all = '1') or
                        (instr_tdata.lock_dreg = '1' and instr_tdata.dreg = CX) or
                        (instr_tdata.lock_sreg = '1' and instr_tdata.sreg = CX)
                    then
                        if (instr_tdata.op = PREFIX and (instr_tdata.code = PREFIX_REPZ or instr_tdata.code = PREFIX_REPNZ) and cx_s_tdata = x"0000") then
                            cx_m_lock_tvalid <= '0';
                        else
                            cx_m_lock_tvalid <= '1';
                        end if;
                    else
                        cx_m_lock_tvalid <= '0';
                    end if;
                else
                    cx_m_lock_tvalid <= '0';
                end if;

                if (instr_tvalid = '1' and instr_tready = '1') then
                    if (instr_tdata.lock_all = '1') or
                        (instr_tdata.lock_dreg = '1' and instr_tdata.dreg = DX) or
                        (instr_tdata.lock_sreg = '1' and instr_tdata.sreg = DX)
                    then
                        dx_m_lock_tvalid <= '1';
                    else
                        dx_m_lock_tvalid <= '0';
                    end if;
                else
                    dx_m_lock_tvalid <= '0';
                end if;

                if (instr_tvalid = '1' and instr_tready = '1') then
                    if (instr_tdata.lock_all = '1') or
                        (instr_tdata.lock_dreg = '1' and instr_tdata.dreg = BP) or
                        (instr_tdata.lock_sreg = '1' and instr_tdata.sreg = BP)
                    then
                        bp_m_lock_tvalid <= '1';
                    else
                        bp_m_lock_tvalid <= '0';
                    end if;
                else
                    bp_m_lock_tvalid <= '0';
                end if;

                if (instr_tvalid = '1' and instr_tready = '1') then
                    if (instr_tdata.lock_sp = '1') or
                        (instr_tdata.lock_all = '1') or
                        (instr_tdata.lock_dreg = '1' and instr_tdata.dreg = SP) or
                        (instr_tdata.lock_sreg = '1' and instr_tdata.sreg = SP)
                    then
                        sp_m_lock_tvalid <= '1';
                    else
                        sp_m_lock_tvalid <= '0';
                    end if;
                elsif (ext_intr_tvalid = '1' and ext_intr_mode = ST_ACK) then
                    sp_m_lock_tvalid <= '1';
                else
                    sp_m_lock_tvalid <= '0';
                end if;

                if (instr_tvalid = '1' and instr_tready = '1') then
                    if (instr_tdata.lock_di = '1' and skip_next = '0') or
                        (instr_tdata.lock_all = '1') or
                        (instr_tdata.lock_dreg = '1' and instr_tdata.dreg = DI) or
                        (instr_tdata.lock_sreg = '1' and instr_tdata.sreg = DI)
                    then
                        di_m_lock_tvalid <= '1';
                    else
                        di_m_lock_tvalid <= '0';
                    end if;
                else
                    di_m_lock_tvalid <= '0';
                end if;

                if (instr_tvalid = '1' and instr_tready = '1') then
                    if (instr_tdata.lock_si = '1' and skip_next = '0') or
                        (instr_tdata.lock_all = '1') or
                        (instr_tdata.lock_dreg = '1' and instr_tdata.dreg = SI) or
                        (instr_tdata.lock_sreg = '1' and instr_tdata.sreg = SI)
                    then
                        si_m_lock_tvalid <= '1';
                    else
                        si_m_lock_tvalid <= '0';
                    end if;
                else
                    si_m_lock_tvalid <= '0';
                end if;

                if (instr_tvalid = '1' and instr_tready = '1') then
                    if (instr_tdata.lock_ds = '1') or
                        (instr_tdata.lock_dreg = '1' and instr_tdata.dreg = DS) or
                        (instr_tdata.lock_sreg = '1' and instr_tdata.sreg = DS)
                    then
                        ds_m_lock_tvalid <= '1';
                    else
                        ds_m_lock_tvalid <= '0';
                    end if;
                else
                    ds_m_lock_tvalid <= '0';
                end if;

                if (instr_tvalid = '1' and instr_tready = '1') then
                    if (instr_tdata.lock_es = '1') or
                        (instr_tdata.lock_dreg = '1' and instr_tdata.dreg = ES) or
                        (instr_tdata.lock_sreg = '1' and instr_tdata.sreg = ES)
                    then
                        es_m_lock_tvalid <= '1';
                    else
                        es_m_lock_tvalid <= '0';
                    end if;
                else
                    es_m_lock_tvalid <= '0';
                end if;

                if (instr_tvalid = '1' and instr_tready = '1') then
                    if (instr_tdata.lock_dreg = '1' and instr_tdata.dreg = SS) or
                        (instr_tdata.lock_sreg = '1' and instr_tdata.sreg = SS)
                    then
                        ss_m_lock_tvalid <= '1';
                    else
                        ss_m_lock_tvalid <= '0';
                    end if;
                else
                    ss_m_lock_tvalid <= '0';
                end if;

                if (instr_tvalid = '1' and instr_tready = '1') then
                    if (instr_tdata.lock_fl = '1') or
                        (instr_tdata.lock_dreg = '1' and instr_tdata.dreg = FL) or
                        (instr_tdata.lock_sreg = '1' and instr_tdata.sreg = FL)
                    then
                        flags_m_lock_tvalid <= '1';
                    else
                        flags_m_lock_tvalid <= '0';
                    end if;
                elsif (ext_intr_tvalid = '1' and ext_intr_mode = ST_ACK) then
                    flags_m_lock_tvalid <= '1';
                else
                    flags_m_lock_tvalid <= '0';
                end if;

            end if;
        end if;

    end process;

    skip_next_proc : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                skip_next <= '0';
            else
                if (instr_tvalid = '1' and instr_tready = '1') then
                    if (instr_tdata.op = PREFIX and (instr_tdata.code = PREFIX_REPZ or instr_tdata.code = PREFIX_REPNZ) and cx_s_tdata = x"0000") then
                        skip_next <= '1';
                    else
                        skip_next <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- forming output
    forming_output_proc: process (clk) begin
        if rising_edge(clk) then
            -- Resettable
            if resetn = '0' then
                rr_tvalid <= '0';
            else
                if (instr_tvalid = '1' and instr_tready = '1') then
                    if ((instr_tdata.op = PREFIX and instr_tdata.code = PREFIX_SEGM) or
                        (instr_tdata.op = PREFIX and instr_tdata.code = PREFIX_LOCK) or
                        (instr_tdata.op = PREFIX and instr_tdata.code = PREFIX_REPZ  and cx_s_tdata = x"0000") or
                        (instr_tdata.op = PREFIX and instr_tdata.code = PREFIX_REPNZ and cx_s_tdata = x"0000") or
                        (skip_next = '1'))
                    then
                        rr_tvalid <= '0';
                    else
                        rr_tvalid <= '1';
                    end if;
                elsif (ext_intr_tvalid = '1' and ext_intr_mode = ST_ACK) then
                    rr_tvalid <= '1';
                elsif rr_tready = '1' then
                    rr_tvalid <= '0';
                end if;
            end if;

            -- Without reset
            if (instr_tvalid = '1' and instr_tready = '1') then
                rr_tdata.op         <= instr_tdata.op;
                rr_tdata.code       <= instr_tdata.code;
                rr_tdata.data       <= instr_tdata.data;
                rr_tdata.w          <= instr_tdata.w;

                if ((instr_tdata.op = MOVU and instr_tdata.dir = R2R) or
                    (instr_tdata.op = MOVU and instr_tdata.dir = I2R) or
                    (instr_tdata.op = XCHG and instr_tdata.dir = R2R) or
                    (instr_tdata.op = XCHG and instr_tdata.dir = I2R) or
                    (instr_tdata.op = JMPU and instr_tdata.code(3) = '0') or
                    (instr_tdata.op = PREFIX and instr_tdata.code = PREFIX_REPZ) or
                    (instr_tdata.op = PREFIX and instr_tdata.code = PREFIX_REPNZ) or
                    (instr_tdata.op = FEU))
                then
                    rr_tdata.fast_instr <= '1';
                else
                    rr_tdata.fast_instr <= '0';
                end if;
            elsif (ext_intr_tvalid = '1' and ext_intr_mode = ST_ACK) then
                rr_tdata.op         <= SYS;
                rr_tdata.code       <= SYS_EXT_INT_OP;
                rr_tdata.fast_instr <= '0';
                rr_tdata.data       <= x"00" & ext_intr_tdata;
                rr_tdata.w          <= '1';
            end if;

            if (instr_tvalid = '1' and instr_tready = '1') then
                rr_tdata.bpu_first  <= instr_tdata.bpu_first;
                rr_tdata.bpu_taken  <= instr_tdata.bpu_taken;
                rr_tdata.bpu_bypass <= '0';
            elsif (ext_intr_tvalid = '1' and ext_intr_mode = ST_ACK) then
                rr_tdata.bpu_first  <= '1';
                rr_tdata.bpu_taken  <= '0';
                rr_tdata.bpu_bypass <= '1';
            end if;

            if (instr_tvalid = '1' and instr_tready = '1') then
                rr_tdata.bpu_taken_cs <= instr_tdata.bpu_taken_cs;
                rr_tdata.bpu_taken_ip <= instr_tdata.bpu_taken_ip;
            end if;

            if (instr_tvalid = '1' and instr_tready = '1') or (ext_intr_tvalid = '1' and ext_intr_mode = ST_ACK) then
                rr_tdata.fl         <= instr_tdata.fl;
                rr_tdata.dir        <= instr_tdata.dir;
                rr_tdata.ea         <= instr_tdata.ea;
                rr_tdata.dreg       <= instr_tdata.dreg;
                rr_tdata.dmask      <= instr_tdata.dmask;
                rr_tdata.sreg       <= instr_tdata.sreg;

                rr_tdata.disp       <= instr_tdata.disp;
                rr_tdata.level      <= to_integer(unsigned(instr_tdata.data_ex(4 downto 0))) + 2;
                rr_tdata.data_ex    <= instr_tdata.data_ex;

                rr_tdata.sreg_val   <= sreg_tdata;
                rr_tdata.dreg_val   <= dreg_tdata;
                rr_tdata.ea_val     <= ea_tdata;
                rr_tdata.seg_val    <= seg_tdata;
                rr_tdata.ss_seg_val <= ss_s_tdata;
                rr_tdata.es_seg_val <= es_s_tdata;
            end if;

            if (instr_tvalid = '1' and instr_tready = '1') then
                if ((instr_tdata.op = SYS and instr_tdata.code = SYS_INT_INT_OP) or
                    (instr_tdata.op = STACKU and (
                        instr_tdata.code = STACKU_PUSHR or instr_tdata.code = STACKU_PUSHM or
                        instr_tdata.code = STACKU_PUSHI or instr_tdata.code = STACKU_PUSHA or
                        instr_tdata.code = STACKU_ENTER)) or
                    (instr_tdata.op = LFP and instr_tdata.code = MISC_BOUND) or
                    (instr_tdata.op = DIVU) or
                    (instr_tdata.op = JCALL))
                then
                    rr_tdata.sp_val <= std_logic_vector(unsigned(sp_s_tdata) - to_unsigned(2, 16));
                    rr_tdata.sp_offset <= x"FFFE";
                else
                    rr_tdata.sp_offset <= x"0002";
                    rr_tdata.sp_val <= sp_s_tdata;
                end if;
            elsif (ext_intr_tvalid = '1' and ext_intr_mode = ST_ACK) then
                rr_tdata.sp_val <= std_logic_vector(unsigned(sp_s_tdata) - to_unsigned(2, 16));
                rr_tdata.sp_offset <= x"FFFE";
            end if;

            if (instr_tvalid = '1' and instr_tready = '1') or (ext_intr_tvalid = '1' and ext_intr_mode = ST_ACK) then
                rr_tdata.ax_tdata <= ax_s_tdata;
                rr_tdata.bx_tdata <= bx_s_tdata;
                rr_tdata.cx_tdata <= cx_s_tdata;
                rr_tdata.dx_tdata <= dx_s_tdata;
                rr_tdata.bp_tdata <= bp_s_tdata;
                rr_tdata.di_tdata <= di_s_tdata;
                rr_tdata.si_tdata <= si_s_tdata;
                rr_tdata.fl_tdata <= flags_s_tdata;
            end if;

            if (instr_tvalid = '1' and instr_tready = '1') or (ext_intr_tvalid = '1' and ext_intr_mode = ST_ACK) then
                rr_tuser <= instr_tuser;
            end if;

        end if;
    end process;

    seg_override_proc: process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                seg_override_tvalid <= '0';
            else

                if (instr_tvalid = '1' and instr_tready = '1') then
                    if (instr_tdata.op = PREFIX and instr_tdata.code = PREFIX_SEGM) then
                        seg_override_tvalid <= '1';
                    else
                        seg_override_tvalid <= '0';
                    end if;
                end if;

            end if;

            if (instr_tvalid = '1' and instr_tready = '1') then
                case instr_tdata.sreg is
                    when DS     => seg_override_tdata <= ds_s_tdata;
                    when SS     => seg_override_tdata <= ss_s_tdata;
                    when ES     => seg_override_tdata <= es_s_tdata;
                    when others => seg_override_tdata <= instr_tuser(31 downto 16);
                end case;
            end if;

        end if;
    end process;

    combined_instr_proc : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                combined_instr <= '0';
            else
                if (instr_tvalid = '1' and instr_tready = '1') then
                    if (instr_tdata.op = PREFIX) then
                        combined_instr <= '1';
                    else
                        combined_instr <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;

    validator_proc : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                vld_valid <= '0';
                vld_skip_next <= '0';
            else
                if (instr_tvalid = '1' and instr_tready = '1') or (ext_intr_tvalid = '1' and ext_intr_mode = ST_ACK) then
                    if (vld_skip_next = '0') then
                        vld_valid <= '1';
                    else
                        vld_valid <= '0';
                    end if;
                else
                    vld_valid <= '0';
                end if;

                if (instr_tvalid = '1' and instr_tready = '1') then
                    if (instr_tdata.op = PREFIX) then
                        vld_skip_next <= '1';
                    else
                        vld_skip_next <= '0';
                    end if;
                end if;
            end if;

            if (instr_tvalid = '1' and instr_tready = '1') or (ext_intr_tvalid = '1' and ext_intr_mode = ST_ACK) then
                vld_cs      <= instr_tuser(USER_T_CS);
                vld_ip      <= instr_tuser(USER_T_IP);
                vld_op      <= std_logic_vector(to_unsigned(op_t'pos(instr_tdata.op), 5));
                vld_dir     <= std_logic_vector(to_unsigned(direction_t'pos(instr_tdata.dir), 3));
                vld_code    <= instr_tdata.code;
                vld_ax      <= ax_s_tdata;
                vld_bx      <= bx_s_tdata;
                vld_cx      <= cx_s_tdata;
                vld_dx      <= dx_s_tdata;
                vld_bp      <= bp_s_tdata;
                vld_sp      <= sp_s_tdata;
                vld_di      <= di_s_tdata;
                vld_si      <= si_s_tdata;
                vld_sreg    <= std_logic_vector(to_unsigned(reg_t'pos(instr_tdata.sreg), 4));
                vld_dreg    <= std_logic_vector(to_unsigned(reg_t'pos(instr_tdata.dreg), 4));
                vld_fl      <= flags_s_tdata;
            end if;
        end if;
    end process;

end architecture;
