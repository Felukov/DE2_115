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

        si_m_wr_tkeep_lock      : out std_logic;
        di_m_wr_tkeep_lock      : out std_logic;

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
        lsu_req_m_tdata         : out std_logic_vector(15 downto 0)

    );
end entity mexec;

architecture rtl of mexec is

    type flag_src_t is (ALU, CMD);

    type alu_t is record
        code                    : std_logic_vector(3 downto 0);
        w                       : std_logic;
        dreg                    : reg_t;
        dmask                   : std_logic_vector(1 downto 0);
        aval                    : std_logic_vector(15 downto 0);
        bval                    : std_logic_vector(15 downto 0);
        dval                    : std_logic_vector(16 downto 0);
    end record;

    signal micro_tvalid         : std_logic;
    signal micro_tready         : std_logic;
    signal micro_tdata          : micro_op_t;

    signal alu_tvalid           : std_logic;
    signal alu_tdata            : alu_t;

    signal lsu_req_tvalid       : std_logic;
    signal lsu_req_tready       : std_logic;
    signal lsu_req_tcmd         : std_logic;
    signal lsu_req_taddr        : std_logic_vector(19 downto 0);
    signal lsu_req_twidth       : std_logic;
    signal lsu_req_tdata        : std_logic_vector(15 downto 0);

    signal a_next               : std_logic_vector(15 downto 0);
    signal b_next               : std_logic_vector(15 downto 0);

    signal add_next             : std_logic_vector(16 downto 0);
    signal and_next             : std_logic_vector(15 downto 0);
    signal or_next              : std_logic_vector(15 downto 0);
    signal xor_next             : std_logic_vector(15 downto 0);

    signal flags_wr_be          : std_logic_vector(15 downto 0);
    signal flags_wr_new_val     : std_logic;
    signal flags_src            : flag_src_t;
    signal flags_wr_vector      : std_logic_vector(15 downto 0);

    signal flags_cf             : std_logic;
    signal flags_pf             : std_logic;
    signal flags_zf             : std_logic;
    signal flags_of             : std_logic;
    signal flags_sf             : std_logic;
    signal flags_af             : std_logic;

    signal d_flags_m_wr_tvalid  : std_logic;

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

    ax_m_wr_tdata <= alu_tdata.dval(15 downto 0);
    bx_m_wr_tdata <= alu_tdata.dval(15 downto 0);
    cx_m_wr_tdata <= alu_tdata.dval(15 downto 0);
    dx_m_wr_tdata <= alu_tdata.dval(15 downto 0);

    ax_m_wr_tmask <= alu_tdata.dmask;
    bx_m_wr_tmask <= alu_tdata.dmask;
    cx_m_wr_tmask <= alu_tdata.dmask;
    dx_m_wr_tmask <= alu_tdata.dmask;

    bp_m_wr_tdata <= alu_tdata.dval(15 downto 0);
    sp_m_wr_tdata <= alu_tdata.dval(15 downto 0);
    di_m_wr_tdata <= alu_tdata.dval(15 downto 0);
    si_m_wr_tdata <= alu_tdata.dval(15 downto 0);
    ds_m_wr_tdata <= alu_tdata.dval(15 downto 0);
    es_m_wr_tdata <= alu_tdata.dval(15 downto 0);
    ss_m_wr_tdata <= alu_tdata.dval(15 downto 0);

    micro_tready <= '1' when (micro_tvalid = '1' and
        (micro_tdata.read_fifo = '0' or (micro_tdata.read_fifo = '1' and lsu_rd_s_tvalid = '1'))) and
        (lsu_req_tvalid = '0' or (lsu_req_tvalid = '1' and lsu_req_tready = '1')) else '0';

    lsu_rd_s_tready <= '1' when micro_tvalid = '1' and micro_tready = '1' and micro_tdata.read_fifo = '1' else '0';

    flags_m_wr_tdata <= (not flags_wr_be and flags_s_tdata) or (flags_wr_be and flags_wr_vector);

    -- alu
    a_next_proc : process (all) begin

        a_next <= micro_tdata.alu_a_val;

        if (micro_tdata.alu_a_mem = '1') then
            a_next <= lsu_rd_s_tdata;
        end if;

        if (micro_tdata.alu_a_acc = '1') then
            a_next <= alu_tdata.dval(15 downto 0);
        end if;

    end process;

    b_next_proc : process (all) begin

        b_next <= micro_tdata.alu_b_val;

        if (micro_tdata.alu_b_mem = '1') then
            b_next <= lsu_rd_s_tdata;
        end if;

    end process;

    add_next <= std_logic_vector(unsigned('0' & a_next) + unsigned('0' & b_next));

    and_next <= a_next and b_next;
    or_next  <= a_next or  b_next;
    xor_next <= a_next xor b_next;

    alu_proc : process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                alu_tvalid <= '0';
            else
                alu_tvalid <= '1' when (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_ALU) = '1') else '0';
            end if;

            if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_ALU) = '1') then
                alu_tdata.code <= micro_tdata.alu_code;
                alu_tdata.w <= micro_tdata.alu_w;
                alu_tdata.aval <= a_next;
                alu_tdata.bval <= b_next;
                alu_tdata.dreg <= micro_tdata.alu_dreg;
                alu_tdata.dmask <= micro_tdata.alu_dmask;

                case (micro_tdata.alu_code) is
                    when ALU_OP_AND =>
                        alu_tdata.dval(15 downto 0) <= and_next;
                        alu_tdata.dval(16) <= '0';
                    when ALU_OP_OR =>
                        alu_tdata.dval(15 downto 0) <= or_next;
                        alu_tdata.dval(16) <= '0';
                    when ALU_OP_XOR =>
                        alu_tdata.dval(15 downto 0) <= xor_next;
                        alu_tdata.dval(16) <= '0';
                    when others =>
                        alu_tdata.dval <= add_next;
                end case;
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
                si_m_wr_tkeep_lock <= '0';
                di_m_wr_tkeep_lock <= '0';
            else
                ax_m_wr_tvalid <= '1' when (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.alu_wb = '1' and micro_tdata.alu_dreg = AX) else '0';
                bx_m_wr_tvalid <= '1' when (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.alu_wb = '1' and micro_tdata.alu_dreg = BX) else '0';
                cx_m_wr_tvalid <= '1' when (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.alu_wb = '1' and micro_tdata.alu_dreg = CX) else '0';
                dx_m_wr_tvalid <= '1' when (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.alu_wb = '1' and micro_tdata.alu_dreg = DX) else '0';
                bp_m_wr_tvalid <= '1' when (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.alu_wb = '1' and micro_tdata.alu_dreg = BP) else '0';
                sp_m_wr_tvalid <= '1' when (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.alu_wb = '1' and micro_tdata.alu_dreg = SP) else '0';
                di_m_wr_tvalid <= '1' when (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.alu_wb = '1' and micro_tdata.alu_dreg = DI) else '0';
                si_m_wr_tvalid <= '1' when (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.alu_wb = '1' and micro_tdata.alu_dreg = SI) else '0';

                ds_m_wr_tvalid <= '1' when (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.alu_wb = '1' and micro_tdata.alu_dreg = DS) else '0';
                es_m_wr_tvalid <= '1' when (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.alu_wb = '1' and micro_tdata.alu_dreg = ES) else '0';
                ss_m_wr_tvalid <= '1' when (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.alu_wb = '1' and micro_tdata.alu_dreg = SS) else '0';

                si_m_wr_tkeep_lock <= '1' when (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.alu_wb = '1' and micro_tdata.alu_keep_lock = '1' and micro_tdata.alu_dreg = SI) else '0';
                di_m_wr_tkeep_lock <= '1' when (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.alu_wb = '1' and micro_tdata.alu_keep_lock = '1' and micro_tdata.alu_dreg = DI) else '0';
            end if;

        end if;
    end process;

    flags_upd_proc : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                flags_m_wr_tvalid <= '0';
                d_flags_m_wr_tvalid <= '0';
                flags_wr_be <= (others => '0');
            else

                if (micro_tvalid = '1' and micro_tready = '1') then
                    if micro_tdata.cmd(MICRO_OP_CMD_FLG) = '1' or (micro_tdata.cmd(MICRO_OP_CMD_ALU) = '1' and micro_tdata.alu_code /= ALU_SF_ADD) then
                        flags_m_wr_tvalid <= '1';
                    else
                        flags_m_wr_tvalid <= '0';
                    end if;
                else
                    flags_m_wr_tvalid <= '0';
                end if;

                d_flags_m_wr_tvalid <= flags_m_wr_tvalid;

                if (micro_tvalid = '1' and micro_tready = '1') then
                    if (micro_tdata.cmd(MICRO_OP_CMD_FLG)) = '1' then

                        for i in 0 to 15 loop
                            if (micro_tdata.flg_no = std_logic_vector(to_unsigned(i, 4))) then
                                flags_wr_be(i) <= '1';
                            else
                                flags_wr_be(i) <= '0';
                            end if;
                        end loop;

                    elsif (micro_tdata.cmd(MICRO_OP_CMD_ALU) = '1') then

                        case (micro_tdata.alu_code) is
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
                            when ALU_OP_INC =>
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

            if (micro_tvalid = '1' and micro_tready = '1') then
                if micro_tdata.cmd(MICRO_OP_CMD_FLG) = '1' then
                    flags_src <= CMD;
                elsif (micro_tdata.cmd(MICRO_OP_CMD_ALU) = '1' and micro_tdata.alu_code /= ALU_SF_ADD) then
                    flags_src <= ALU;
                end if;
            end if;

            if (micro_tvalid = '1' and micro_tready = '1') then
                flags_wr_new_val <= micro_tdata.flg_val;
            end if;

        end if;
    end process;

    flag_calc_proc : process (all) begin

        flags_pf <= not (xor alu_tdata.dval(7 downto 0));
        flags_af <= alu_tdata.aval(4) xor alu_tdata.bval(4) xor alu_tdata.dval(4);

        if alu_tdata.w = '0' then
            flags_zf <= '1' when alu_tdata.dval(7 downto 0) = x"00" else '0';
        else
            flags_zf <= '1' when alu_tdata.dval = x"0000" else '0';
        end if;

        if alu_tdata.w = '0' then
            flags_sf <= alu_tdata.dval(7);
        else
            flags_sf <= alu_tdata.dval(15);
        end if;

        case alu_tdata.code is
            when ALU_OP_AND | ALU_OP_OR | ALU_OP_XOR =>
                flags_cf <= '0';
            when others =>
                --ALU_OP_ADD | ALU_OP_SUB
                if alu_tdata.w = '0' then
                    flags_cf <= alu_tdata.aval(8) xor alu_tdata.bval(8) xor alu_tdata.dval(8);
                else
                    flags_cf <= alu_tdata.dval(16);
                end if;
        end case;

        case alu_tdata.code is
            when ALU_OP_AND | ALU_OP_OR | ALU_OP_XOR =>
                flags_of <= '0';

            when ALU_OP_SUB =>
                if alu_tdata.w = '0' then
                    flags_of <= (alu_tdata.aval(7) xor alu_tdata.bval(7)) and (alu_tdata.dval(7) xor alu_tdata.aval(7));
                else
                    flags_of <= (alu_tdata.aval(15) xor alu_tdata.bval(15)) and (alu_tdata.dval(15) xor alu_tdata.bval(15));
                end if;

            when others => --ALU_OP_ADD
                if alu_tdata.w = '0' then
                    flags_of <= not (alu_tdata.aval(7) xor alu_tdata.bval(7)) and (alu_tdata.dval(7) xor alu_tdata.bval(7));
                else
                    flags_of <= not (alu_tdata.aval(15) xor alu_tdata.bval(15)) and (alu_tdata.dval(15) xor alu_tdata.bval(15));
                end if;

        end case;

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
        if (flags_src = ALU) then
            flags_wr_vector(FLAG_CF) <= flags_cf;
        else
            flags_wr_vector(FLAG_CF) <= flags_wr_new_val;
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
            else
                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_JMP) = '1') then

                    case micro_tdata.jump_cond is
                        when cx_ne_0 =>
                            if (alu_tdata.dval(15 downto 0) /= x"00") then
                                jump_m_tvalid <= '1';
                            else
                                jump_m_tvalid <= '0';
                            end if;
                        when others =>
                            jump_m_tvalid <= '0';
                    end case; --jump cond

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
            else

                if (micro_tvalid = '1' and micro_tready = '1' and micro_tdata.cmd(MICRO_OP_CMD_MEM) = '1') then
                    lsu_req_tvalid <= '1';
                elsif (lsu_req_tready = '1') then
                    lsu_req_tvalid <= '0';
                end if;

            end if;

            if (micro_tvalid = '1' and micro_tready = '1') then

                if (micro_tdata.mem_addr_src = MEM_ADDR_SRC_EA) then
                    lsu_req_taddr <= std_logic_vector(unsigned(micro_tdata.mem_seg & x"0") + unsigned(x"0" & micro_tdata.mem_addr));
                else
                    lsu_req_taddr <= std_logic_vector(unsigned(micro_tdata.mem_seg & x"0") + unsigned(x"0" & alu_tdata.dval(15 downto 0)));
                end if;

                lsu_req_tcmd <= micro_tdata.mem_cmd;
                lsu_req_twidth <= micro_tdata.mem_width;

                case (micro_tdata.mem_data_src) is
                    when MEM_DATA_SRC_IMM => lsu_req_tdata <= micro_tdata.mem_data;
                    when MEM_DATA_SRC_FIFO => lsu_req_tdata <= lsu_rd_s_tdata;
                    when others => lsu_req_tdata <= alu_tdata.dval(15 downto 0);
                end case;

            end if;

        end if;
    end process;


end architecture;
