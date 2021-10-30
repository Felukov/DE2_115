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

        di_m_inc_tvalid         : out std_logic;
        di_m_inc_tdata          : out std_logic_vector(15 downto 0);
        di_m_inc_tkeep_lock     : out std_logic;

        si_m_inc_tvalid         : out std_logic;
        si_m_inc_tdata          : out std_logic_vector(15 downto 0);
        si_m_inc_tkeep_lock     : out std_logic;

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

        dbg_m_tvalid            : out std_logic;
        dbg_m_tdata             : out std_logic_vector(31 downto 0)
    );
end entity mexec;

architecture rtl of mexec is

    type flag_src_t is (ALU_FLAGS, CMD, ALU_DATA);

    type alu_t is record
        code                    : std_logic_vector(3 downto 0);
        w                       : std_logic;
        wb                      : std_logic;
        dreg                    : reg_t;
        dmask                   : std_logic_vector(1 downto 0);
        upd_fl                  : std_logic;
        aval                    : std_logic_vector(15 downto 0);
        bval                    : std_logic_vector(15 downto 0);
    end record;

    type res_t is record
        code                    : std_logic_vector(3 downto 0);
        w                       : std_logic;
        dmask                   : std_logic_vector(1 downto 0);
        aval                    : std_logic_vector(15 downto 0);
        bval                    : std_logic_vector(15 downto 0);
        dval                    : std_logic_vector(16 downto 0); --dest
        rval                    : std_logic_vector(16 downto 0); --result
    end record;

    type mul_res_t is record
        code                    : std_logic_vector(3 downto 0);
        w                       : std_logic;
        dreg                    : reg_t;
        dmask                   : std_logic_vector(1 downto 0);
        aval                    : std_logic_vector(15 downto 0);
        bval                    : std_logic_vector(15 downto 0);
        dval                    : std_logic_vector(31 downto 0); --dest
    end record;

    signal micro_tvalid         : std_logic;
    signal micro_tready         : std_logic;
    signal micro_tdata          : micro_op_t;

    signal alu_tvalid           : std_logic;
    signal alu_res_tvalid       : std_logic;
    signal alu_a_wait_fifo      : std_logic;
    signal alu_b_wait_fifo      : std_logic;

    signal alu_tdata            : alu_t := (
        code => (others=>'0'), w => '0',
        wb => '0', dreg => AX, dmask => "00",
        upd_fl => '0',
        aval => (others=>'0'),
        bval => (others=>'0')
    );

    signal mul_0_tvalid         : std_logic;
    signal mul_1_tvalid         : std_logic;
    signal mul_0_tdata          : alu_t;
    signal mul_1_tdata          : alu_t;

    signal res_tvalid           : std_logic;
    signal alu_res_tdata_next   : res_t;

    signal mul_res_0_tvalid     : std_logic;
    signal mul_res_1_tvalid     : std_logic;
    signal mul_res_2_tvalid     : std_logic;
    signal mul_res_0_tdata      : mul_res_t;
    signal mul_res_1_tdata      : mul_res_t;
    signal mul_res_2_tdata      : mul_res_t;

    signal res_tdata            : res_t := (
        code => (others=>'0'),
        w => '0', dmask => "00",
        aval => (others=>'0'),
        bval => (others=>'0'),
        dval => (others=>'0'),
        rval => (others=>'0')
    );

    signal lsu_req_tvalid       : std_logic;
    signal lsu_req_tready       : std_logic;
    signal lsu_req_tcmd         : std_logic;
    signal lsu_req_taddr        : std_logic_vector(19 downto 0);
    signal lsu_req_twidth       : std_logic;
    signal lsu_req_tdata        : std_logic_vector(15 downto 0);

    signal carry                : std_logic_vector(16 downto 0);
    signal add_next             : std_logic_vector(16 downto 0);
    signal sub_next             : std_logic_vector(16 downto 0);
    signal adc_next             : std_logic_vector(16 downto 0);
    signal sbb_next             : std_logic_vector(16 downto 0);
    signal and_next             : std_logic_vector(15 downto 0);
    signal or_next              : std_logic_vector(15 downto 0);
    signal xor_next             : std_logic_vector(15 downto 0);

    signal flags_wr_be          : std_logic_vector(15 downto 0);
    signal flags_wr_new_val     : std_logic;
    signal flags_toggle_cf      : std_logic;
    signal flags_src            : flag_src_t;
    signal flags_wr_vector      : std_logic_vector(15 downto 0);

    signal flags_cf             : std_logic;
    signal flags_pf             : std_logic;
    signal flags_zf             : std_logic;
    signal flags_of             : std_logic;
    signal flags_sf             : std_logic;
    signal flags_af             : std_logic;

    signal mem_buf_tdata        : std_logic_vector(15 downto 0);
    signal mexec_busy           : std_logic;
    signal mexec_wait_fifo      : std_logic;
    signal mexec_wait_mul       : std_logic;

    signal alu_wait_fifo        : std_logic;
    signal mul_wait_fifo        : std_logic;
    signal mem_wait_alu         : std_logic;
    signal mem_wait_fifo        : std_logic;
    signal mem_addr_wait_alu    : std_logic;
    signal mem_data_wait_alu    : std_logic;

    signal jmp_wait_alu         : std_logic;

    signal dbg_alu_tvalid       : std_logic;
    signal dbg_alu_res_tvalid   : std_logic;

begin

    micro_tvalid <= micro_s_tvalid;
    micro_s_tready <= micro_tready;
    micro_tdata <= micro_s_tdata;

    lsu_req_m_tvalid <= lsu_req_tvalid;
    lsu_req_tready <= lsu_req_m_tready;
    lsu_req_m_tcmd <= lsu_req_tcmd;
    lsu_req_m_taddr <= lsu_req_taddr;
    lsu_req_m_twidth <= lsu_req_twidth;
    lsu_req_m_tdata <= lsu_req_tdata;

    ax_m_wr_tdata <= res_tdata.dval(15 downto 0);
    bx_m_wr_tdata <= res_tdata.dval(15 downto 0);
    cx_m_wr_tdata <= res_tdata.dval(15 downto 0);
    dx_m_wr_tdata <= res_tdata.dval(15 downto 0);

    ax_m_wr_tmask <= res_tdata.dmask;
    bx_m_wr_tmask <= res_tdata.dmask;
    cx_m_wr_tmask <= res_tdata.dmask;
    dx_m_wr_tmask <= res_tdata.dmask;

    bp_m_wr_tdata <= res_tdata.dval(15 downto 0);
    sp_m_wr_tdata <= res_tdata.dval(15 downto 0);
    di_m_wr_tdata <= res_tdata.dval(15 downto 0);
    si_m_wr_tdata <= res_tdata.dval(15 downto 0);
    ds_m_wr_tdata <= res_tdata.dval(15 downto 0);
    es_m_wr_tdata <= res_tdata.dval(15 downto 0);
    ss_m_wr_tdata <= res_tdata.dval(15 downto 0);

    micro_tready <= '1' when mexec_busy = '0' and mem_wait_alu = '0' and
        (lsu_req_tvalid = '0' or (lsu_req_tvalid = '1' and lsu_req_tready = '1')) else '0';

    lsu_rd_s_tready <= mexec_wait_fifo;-- '1' when micro_tvalid = '1' and micro_tready = '1' and micro_tdata.read_fifo = '1' else '0';

    flags_m_wr_tdata <= ((not flags_wr_be) and flags_s_tdata) or (flags_wr_be and flags_wr_vector);

    -- sp increment
    sp_m_inc_tvalid <= '1' when micro_tvalid = '1' and micro_tready = '1' and micro_tdata.sp_inc = '1' else '0';
    sp_m_inc_tdata <= micro_tdata.sp_inc_data;
    sp_m_inc_tkeep_lock <= micro_tdata.sp_keep_lock;

    -- di increment
    di_m_inc_tvalid <= '1' when micro_tvalid = '1' and micro_tready = '1' and micro_tdata.di_inc = '1' else '0';
    di_m_inc_tdata <= micro_tdata.di_inc_data;
    di_m_inc_tkeep_lock <= micro_tdata.di_keep_lock;

    -- si increment
    si_m_inc_tvalid <= '1' when micro_tvalid = '1' and micro_tready = '1' and micro_tdata.si_inc = '1' else '0';
    si_m_inc_tdata <= micro_tdata.si_inc_data;
    si_m_inc_tkeep_lock <= micro_tdata.si_keep_lock;

    add_next <= std_logic_vector(unsigned('0' & alu_tdata.aval) + unsigned('0' & alu_tdata.bval));
    sub_next <= std_logic_vector(unsigned('0' & alu_tdata.aval) - unsigned('0' & alu_tdata.bval));
    carry(16 downto 1) <= (others => '0');
    carry(0) <= flags_s_tdata(FLAG_CF);
    adc_next <= std_logic_vector(unsigned(add_next) + unsigned(carry));
    sbb_next <= std_logic_vector(unsigned(sub_next) - unsigned(carry));
    and_next <= alu_tdata.aval and alu_tdata.bval;
    or_next  <= alu_tdata.aval or  alu_tdata.bval;
    xor_next <= alu_tdata.aval xor alu_tdata.bval;

    mexec_busy_proc : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                mexec_busy <= '0';
                mexec_wait_fifo <= '0';
                mexec_wait_mul <= '0';
            else

                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.read_fifo = '1') then --or
                --    (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_MUL) = '1') then
                    mexec_busy <= '1';
                elsif (mexec_busy = '1') then
                    if not (mexec_wait_fifo = '1' xor lsu_rd_s_tvalid = '1') and
                        not (mexec_wait_mul = '1' xor mul_res_1_tvalid = '1') then
                        mexec_busy <= '0';
                    end if;
                end if;

                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.read_fifo = '1') then
                    mexec_wait_fifo <= '1';
                elsif (mexec_busy = '1') then
                    if (lsu_rd_s_tvalid = '1') then
                        mexec_wait_fifo <= '0';
                    end if;
                end if;

                -- if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_MUL) = '1') then
                    -- mexec_wait_mul <= '1';
                -- elsif (mul_res_1_tvalid = '1') then
                    -- mexec_wait_mul <= '0';
                -- end if;

            end if;
        end if;
    end process;

    mul_proc : process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                mul_0_tvalid <= '0';
                mul_1_tvalid <= '0';
                mul_res_0_tvalid <= '0';
                mul_res_1_tvalid <= '0';
                mul_res_2_tvalid <= '0';
                mul_wait_fifo <= '0';
            else
                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_MUL) = '1' and micro_tdata.read_fifo = '0') then
                    mul_0_tvalid <= '1';
                elsif (mul_wait_fifo = '1' and mexec_busy = '1' and not(mexec_wait_fifo = '1' xor lsu_rd_s_tvalid = '1')) then
                    mul_0_tvalid <= '1';
                else
                    mul_0_tvalid <= '0';
                end if;

                mul_1_tvalid <= mul_0_tvalid;
                mul_res_0_tvalid <= mul_1_tvalid;
                mul_res_1_tvalid <= mul_res_0_tvalid;
                mul_res_2_tvalid <= mul_res_1_tvalid;

                if (micro_tvalid = '1' and micro_tready = '1') then
                    if (micro_tdata.cmd(MICRO_OP_CMD_MUL) = '1' AND micro_tdata.read_fifo = '1') then
                        mul_wait_fifo <= '1';
                    else
                        mul_wait_fifo <= '0';
                    end if;
                end if;
            end if;

            if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_MUL) = '1') then
                mul_0_tdata.code <= micro_tdata.alu_code;
                mul_0_tdata.w <= micro_tdata.alu_w;
                mul_0_tdata.wb <= micro_tdata.alu_wb;
                mul_0_tdata.aval <= micro_tdata.alu_a_val;
                mul_0_tdata.bval <= micro_tdata.alu_b_val;
                mul_0_tdata.dreg <= micro_tdata.alu_dreg;
                mul_0_tdata.dmask <= micro_tdata.alu_dmask;
                mul_0_tdata.upd_fl <= '1';

            elsif (mexec_busy = '1' and not(mexec_wait_fifo = '1' xor lsu_rd_s_tvalid = '1')) then
                mul_0_tdata.aval <= lsu_rd_s_tdata;
            end if;

            mul_1_tdata <= mul_0_tdata;

            mul_res_0_tdata.code <= mul_1_tdata.code;
            mul_res_0_tdata.w <= mul_1_tdata.w;
            mul_res_0_tdata.dreg <= mul_1_tdata.dreg;
            mul_res_0_tdata.dmask <= mul_1_tdata.dmask;
            mul_res_0_tdata.aval <= mul_1_tdata.aval;
            mul_res_0_tdata.bval <= mul_1_tdata.bval;
            mul_res_0_tdata.dval <= mul_1_tdata.aval * mul_1_tdata.bval;

            mul_res_1_tdata <= mul_res_0_tdata;
            mul_res_2_tdata <= mul_res_1_tdata;
        end if;
    end process;

    alu_proc : process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                alu_tvalid <= '0';
                alu_wait_fifo <= '0';
            else
                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_ALU) = '1' and micro_tdata.read_fifo = '0') then
                    alu_tvalid <= '1';
                elsif (alu_wait_fifo = '1' and mexec_busy = '1' and not(mexec_wait_fifo = '1' xor lsu_rd_s_tvalid = '1')) then
                    alu_tvalid <= '1';
                else
                    alu_tvalid <= '0';
                end if;

                if (micro_tvalid = '1' and micro_tready = '1') then
                    if (micro_tdata.cmd(MICRO_OP_CMD_ALU) = '1' AND micro_tdata.read_fifo = '1') then
                        alu_wait_fifo <= '1';
                    else
                        alu_wait_fifo <= '0';
                    end if;
                end if;
            end if;

            if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_ALU) = '1') then
                alu_tdata.code <= micro_tdata.alu_code;
                alu_tdata.w <= micro_tdata.alu_w;
                alu_tdata.wb <= micro_tdata.alu_wb;

                if micro_tdata.alu_a_buf = '1' then
                    alu_tdata.aval <= mem_buf_tdata;
                else
                    alu_tdata.aval <= micro_tdata.alu_a_val;
                end if;

                alu_tdata.bval <= micro_tdata.alu_b_val;
                alu_tdata.dreg <= micro_tdata.alu_dreg;
                alu_tdata.dmask <= micro_tdata.alu_dmask;

                if (micro_tdata.alu_code = ALU_SF_ADD and micro_tdata.alu_dreg = FL) or (micro_tdata.alu_code /= ALU_SF_ADD) then
                    alu_tdata.upd_fl <= '1';
                else
                    alu_tdata.upd_fl <= '0';
                end if;

                alu_a_wait_fifo <= micro_tdata.alu_a_mem;
                alu_b_wait_fifo <= micro_tdata.alu_b_mem;

            elsif (mexec_busy = '1' and not(mexec_wait_fifo = '1' xor lsu_rd_s_tvalid = '1')) then
                if (alu_a_wait_fifo = '1') then
                    alu_tdata.aval <= lsu_rd_s_tdata;
                end if;

                if (alu_b_wait_fifo = '1') then
                    alu_tdata.bval <= lsu_rd_s_tdata;
                end if;

            end if;

        end if;
    end process;

    alu_res_next_proc: process (all) begin
        alu_res_tdata_next.code <= alu_tdata.code;
        alu_res_tdata_next.w <= alu_tdata.w;
        alu_res_tdata_next.dmask <= alu_tdata.dmask;
        alu_res_tdata_next.aval <= alu_tdata.aval;
        alu_res_tdata_next.bval <= alu_tdata.bval;
        case (micro_tdata.alu_code) is
            when ALU_OP_ADC =>
                alu_res_tdata_next.dval <= adc_next;
                alu_res_tdata_next.rval <= adc_next;
            when ALU_OP_AND =>
                alu_res_tdata_next.dval(15 downto 0) <= and_next;
                alu_res_tdata_next.dval(16) <= '0';
                alu_res_tdata_next.rval(15 downto 0) <= and_next;
                alu_res_tdata_next.rval(16) <= '0';
            when ALU_OP_OR =>
                alu_res_tdata_next.dval(15 downto 0) <= or_next;
                alu_res_tdata_next.dval(16) <= '0';
                alu_res_tdata_next.rval(15 downto 0) <= or_next;
                alu_res_tdata_next.rval(16) <= '0';
            when ALU_OP_XOR =>
                alu_res_tdata_next.dval(15 downto 0) <= xor_next;
                alu_res_tdata_next.dval(16) <= '0';
                alu_res_tdata_next.rval(15 downto 0) <= xor_next;
                alu_res_tdata_next.rval(16) <= '0';
            when ALU_OP_SUB | ALU_OP_DEC =>
                alu_res_tdata_next.dval <= sub_next;
                alu_res_tdata_next.rval <= sub_next;
            when ALU_OP_SBB =>
                alu_res_tdata_next.dval <= sbb_next;
                alu_res_tdata_next.rval <= sbb_next;
            when ALU_OP_CMP =>
                alu_res_tdata_next.dval <= '0' & alu_tdata.aval;
                alu_res_tdata_next.rval <= sub_next;
            when others =>
                alu_res_tdata_next.dval <= add_next;
                alu_res_tdata_next.rval <= add_next;
        end case;
    end process;

    alu_res_proc : process (clk) begin
        if rising_edge(clk) then

            if (alu_tvalid = '1') then
                alu_res_tvalid <= '1';
            else
                alu_res_tvalid <= '0';
            end if;

            if (alu_tvalid = '1') then
                res_tdata <= alu_res_tdata_next;
            elsif (mul_res_2_tvalid = '1') then
                res_tdata.code <= mul_res_2_tdata.code;
                res_tdata.w <= mul_res_2_tdata.w;
                res_tdata.dmask <= mul_res_2_tdata.dmask;
                res_tdata.aval <= mul_res_2_tdata.aval;
                res_tdata.bval <= mul_res_2_tdata.bval;
                res_tdata.dval <= mul_res_2_tdata.dval(16 downto 0);
            end if;

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
                if ((alu_tvalid = '1' and alu_tdata.wb = '1' and alu_tdata.dreg = AX) or (mul_res_1_tvalid = '1' and mul_res_1_tdata.dreg = AX)) then
                    ax_m_wr_tvalid <= '1';
                else
                    ax_m_wr_tvalid <= '0';
                end if;
                if ((alu_tvalid = '1' and alu_tdata.wb = '1' and alu_tdata.dreg = BX)) then
                    bx_m_wr_tvalid <= '1';
                else
                    bx_m_wr_tvalid <= '0';
                end if;
                if ((alu_tvalid = '1' and alu_tdata.wb = '1' and alu_tdata.dreg = CX)) then
                    cx_m_wr_tvalid <= '1';
                else
                    cx_m_wr_tvalid <= '0';
                end if;
                if ((alu_tvalid = '1' and alu_tdata.wb = '1' and alu_tdata.dreg = DX) or (mul_res_1_tvalid = '1' and mul_res_1_tdata.dreg = DX)) then
                    dx_m_wr_tvalid <= '1';
                else
                    dx_m_wr_tvalid <= '0';
                end if;
                if ((alu_tvalid = '1' and alu_tdata.wb = '1' and alu_tdata.dreg = BP)) then
                    bp_m_wr_tvalid <= '1';
                else
                    bp_m_wr_tvalid <= '0';
                end if;
                if ((alu_tvalid = '1' and alu_tdata.wb = '1' and alu_tdata.dreg = SP)) then
                    sp_m_wr_tvalid <= '1';
                else
                    sp_m_wr_tvalid <= '0';
                end if;
                if ((alu_tvalid = '1' and alu_tdata.wb = '1' and alu_tdata.dreg = DI)) then
                    di_m_wr_tvalid <= '1';
                else
                    di_m_wr_tvalid <= '0';
                end if;
                if ((alu_tvalid = '1' and alu_tdata.wb = '1' and alu_tdata.dreg = SI)) then
                    si_m_wr_tvalid <= '1';
                else
                    si_m_wr_tvalid <= '0';
                end if;

                if ((alu_tvalid = '1' and alu_tdata.wb = '1' and alu_tdata.dreg = DS)) then
                    ds_m_wr_tvalid <= '1';
                else
                    ds_m_wr_tvalid <= '0';
                end if;
                if ((alu_tvalid = '1' and alu_tdata.wb = '1' and alu_tdata.dreg = ES)) then
                    es_m_wr_tvalid <= '1';
                else
                    es_m_wr_tvalid <= '0';
                end if;
                if ((alu_tvalid = '1' and alu_tdata.wb = '1' and alu_tdata.dreg = SS)) then
                    ss_m_wr_tvalid <= '1';
                else
                    ss_m_wr_tvalid <= '0';
                end if;

            end if;

        end if;
    end process;

    flags_upd_proc : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                flags_m_wr_tvalid <= '0';
                flags_wr_be <= (others => '0');
            else

                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_FLG) = '1') then
                    flags_m_wr_tvalid <= '1';
                elsif (alu_tvalid = '1' and alu_tdata.upd_fl = '1') then
                    flags_m_wr_tvalid <= '1';
                else
                    flags_m_wr_tvalid <= '0';
                end if;

                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_FLG) = '1') then
                    for i in 0 to 15 loop
                        if (micro_tdata.flg_no = std_logic_vector(to_unsigned(i, 4))) then
                            flags_wr_be(i) <= '1';
                        else
                            flags_wr_be(i) <= '0';
                        end if;
                    end loop;
                elsif (alu_tvalid = '1' and alu_tdata.upd_fl = '1') then

                    if (alu_tdata.dreg = FL) then
                        for i in 15 downto 8 loop
                            flags_wr_be(i) <= micro_tdata.alu_dmask(1);
                        end loop;

                        flags_wr_be(FLAG_ZF) <= micro_tdata.alu_dmask(0);
                        flags_wr_be(FLAG_05) <= '0';
                        flags_wr_be(FLAG_AF) <= '0';
                        flags_wr_be(FLAG_03) <= '0';
                        flags_wr_be(FLAG_PF) <= micro_tdata.alu_dmask(0);
                        flags_wr_be(FLAG_01) <= '0';
                        flags_wr_be(FLAG_CF) <= micro_tdata.alu_dmask(0);
                    else
                        case (alu_tdata.code) is
                            when ALU_OP_AND | ALU_OP_OR | ALU_OP_XOR =>
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

                end if;

            end if;

            if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_FLG) = '1') then
                flags_src <= CMD;
            elsif (alu_tvalid = '1' and alu_tdata.upd_fl = '1') then
                if (alu_tdata.dreg = FL) then
                    flags_src <= ALU_DATA;
                else
                    flags_src <= ALU_FLAGS;
                end if;
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

        flags_pf <= not (res_tdata.rval(7) xor res_tdata.rval(6) xor res_tdata.rval(5) xor res_tdata.rval(4) xor
                         res_tdata.rval(3) xor res_tdata.rval(2) xor res_tdata.rval(1) xor res_tdata.rval(0));
        flags_af <= res_tdata.aval(4) xor res_tdata.bval(4) xor res_tdata.rval(4);

        if res_tdata.w = '0' then
            if (res_tdata.rval(7 downto 0) = x"00") then
                flags_zf <= '1';
            else
                flags_zf <= '0';
            end if;
        else
            if (res_tdata.rval(15 downto 0) = x"0000") then
                flags_zf <= '1';
            else
                flags_zf <= '0';
            end if;
        end if;

        if res_tdata.w = '0' then
            flags_sf <= res_tdata.rval(7);
        else
            flags_sf <= res_tdata.rval(15);
        end if;

        case res_tdata.code is
            when ALU_OP_AND | ALU_OP_OR | ALU_OP_XOR =>
                flags_cf <= '0';
            when others =>
                --ALU_OP_ADD | ALU_OP_SUB
                if res_tdata.w = '0' then
                    flags_cf <= res_tdata.aval(8) xor res_tdata.bval(8) xor res_tdata.rval(8);
                else
                    flags_cf <= res_tdata.rval(16);
                end if;
        end case;

        case res_tdata.code is
            when ALU_OP_AND | ALU_OP_OR | ALU_OP_XOR =>
                flags_of <= '0';

            when ALU_OP_SUB | ALU_OP_DEC | ALU_OP_SBB | ALU_OP_CMP =>
                if res_tdata.w = '0' then
                    flags_of <= (res_tdata.aval(7) xor res_tdata.bval(7)) and (res_tdata.rval(7) xor res_tdata.aval(7));
                else
                    flags_of <= (res_tdata.aval(15) xor res_tdata.bval(15)) and (res_tdata.rval(15) xor res_tdata.aval(15));
                end if;

            when others => --ALU_OP_ADD
                if res_tdata.w = '0' then
                    flags_of <= not (res_tdata.aval(7) xor res_tdata.bval(7)) and (res_tdata.rval(7) xor res_tdata.aval(7));
                else
                    flags_of <= not (res_tdata.aval(15) xor res_tdata.bval(15)) and (res_tdata.rval(15) xor res_tdata.aval(15));
                end if;

        end case;

        if (flags_src = ALU_DATA) then
            flags_wr_vector(15 downto 1) <= res_tdata.dval(15 downto 1);
        else
            flags_wr_vector(FLAG_15) <= '0';
            flags_wr_vector(FLAG_14) <= '0';
            flags_wr_vector(FLAG_13) <= '0';
            flags_wr_vector(FLAG_12) <= '0';
            flags_wr_vector(FLAG_OF) <= flags_of;
            flags_wr_vector(FLAG_DF) <= flags_wr_new_val;
            flags_wr_vector(FLAG_IF) <= flags_wr_new_val;
            flags_wr_vector(FLAG_TF) <= '0';
            flags_wr_vector(FLAG_SF) <= flags_sf;
            flags_wr_vector(FLAG_ZF) <= flags_zf;
            flags_wr_vector(FLAG_05) <= '0';
            flags_wr_vector(FLAG_AF) <= flags_af;
            flags_wr_vector(FLAG_03) <= '0';
            flags_wr_vector(FLAG_PF) <= flags_pf;
            flags_wr_vector(FLAG_01) <= '0';
        end if;

        case flags_src is
            when ALU_DATA =>
                flags_wr_vector(FLAG_CF) <= res_tdata.dval(0);
            when ALU_FLAGS =>
                flags_wr_vector(FLAG_CF) <= flags_cf;
            when others =>
                if (flags_toggle_cf = '1') then
                    flags_wr_vector(FLAG_CF) <= not flags_s_tdata(FLAG_CF);
                else
                    flags_wr_vector(FLAG_CF) <= flags_wr_new_val;
                end if;
        end case;

    end process;

    mem_buf_proc : process (clk) begin
        if rising_edge(clk) then
            if (lsu_rd_s_tvalid = '1') then
                mem_buf_tdata <= lsu_rd_s_tdata;
            end if;
        end if;
    end process;

    unlock_proc : process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                jmp_lock_m_wr_tvalid <= '0';
            else
                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.unlk_fl = '1') then
                    jmp_lock_m_wr_tvalid <= '1';
                else
                    jmp_lock_m_wr_tvalid <= '0';
                end if;
            end if;

        end if;
    end process;

    jump_control_proc: process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                jump_m_tvalid <= '0';
                jmp_wait_alu <= '0';
            else

                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_JMP) = '1') then
                    if (micro_tdata.jump_cond = cx_ne_0) then
                        jmp_wait_alu <= '1';
                    else
                        jmp_wait_alu <= '0';
                    end if;
                elsif (jmp_wait_alu = '1' and alu_res_tvalid = '1') then
                    jmp_wait_alu <= '0';
                end if;

                if (jmp_wait_alu = '1' and alu_res_tvalid = '1') then
                    if (res_tdata.dval(15 downto 0) /= x"00") then
                        jump_m_tvalid <= '1';
                    else
                        jump_m_tvalid <= '0';
                    end if;
                else
                    jump_m_tvalid <= '0';
                end if;

            end if;

            if (micro_tvalid = '1' and micro_tready = '1') then
                jump_m_tdata <= micro_tdata.jump_cs & micro_tdata.jump_ip;
            end if;

        end if;
    end process;

    lsu_request_forming_proc: process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                lsu_req_tvalid <= '0';
                mem_wait_alu <= '0';
                mem_wait_fifo <= '0';
            else

                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_MEM) = '1') then
                    if (micro_tdata.mem_addr_src = MEM_ADDR_SRC_ALU or (micro_tdata.mem_cmd = '1' and micro_tdata.mem_data_src = MEM_DATA_SRC_ALU)) then
                        mem_wait_alu <= '1';
                    else
                        mem_wait_alu <= '0';
                    end if;
                elsif (mem_wait_alu = '1' and alu_res_tvalid = '1') then
                    mem_wait_alu <= '0';
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
                    if (micro_tdata.mem_addr_src = MEM_ADDR_SRC_EA and (micro_tdata.mem_cmd = '0' or (micro_tdata.mem_cmd = '1' and micro_tdata.mem_data_src = MEM_DATA_SRC_IMM))) then
                        lsu_req_tvalid <= '1';
                    else
                        lsu_req_tvalid <= '0';
                    end if;
                elsif (mem_wait_alu = '1' or mem_wait_fifo = '1') and not (alu_res_tvalid = '1' xor mem_wait_alu = '1') and not(lsu_rd_s_tvalid = '1' xor mem_wait_fifo = '1') then
                    lsu_req_tvalid <= '1';
                elsif (lsu_req_tready = '1') then
                    lsu_req_tvalid <= '0';
                end if;

            end if;

            if (micro_tvalid = '1' and micro_tready = '1') then
                lsu_req_tcmd <= micro_tdata.mem_cmd;
                lsu_req_twidth <= micro_tdata.mem_width;
                lsu_req_taddr <= std_logic_vector(unsigned(micro_tdata.mem_seg & x"0") + unsigned(x"0" & micro_tdata.mem_addr));
                lsu_req_tdata <= micro_tdata.mem_data;

                if (micro_tdata.mem_addr_src = MEM_ADDR_SRC_ALU) then
                    mem_addr_wait_alu <= '1';
                else
                    mem_addr_wait_alu <= '0';
                end if;

                if (micro_tdata.mem_data_src = MEM_DATA_SRC_ALU) then
                    mem_data_wait_alu <= '1';
                else
                    mem_data_wait_alu <= '0';
                end if;

            elsif (mem_wait_alu = '1' and alu_res_tvalid = '1') then
                if (mem_addr_wait_alu = '1') then
                    lsu_req_taddr <= std_logic_vector(unsigned(micro_tdata.mem_seg & x"0") + unsigned(x"0" & res_tdata.dval(15 downto 0)));
                end if;
                if (mem_data_wait_alu = '1') then
                    lsu_req_tdata <= res_tdata.dval(15 downto 0);
                end if;
            elsif (mem_wait_fifo = '1' and lsu_rd_s_tvalid = '1') then
                lsu_req_tdata <= lsu_rd_s_tdata;
            end if;

        end if;
    end process;

    dbg_proc : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                dbg_m_tvalid <= '0';
                dbg_alu_tvalid <= '0';
            else
                if (micro_tvalid = '1' and micro_tready = '1') then
                    dbg_alu_tvalid <= micro_tdata.cmd(MICRO_OP_CMD_DBG);
                else
                    dbg_alu_tvalid <= '0';
                end if;

                dbg_m_tvalid <= dbg_alu_tvalid;
            end if;

            if (dbg_alu_tvalid = '1') then
                dbg_m_tdata <= micro_tdata.dbg_cs & micro_tdata.dbg_ip;
            end if;

        end if;
    end process;

end architecture;
