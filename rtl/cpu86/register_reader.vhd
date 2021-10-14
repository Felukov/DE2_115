library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.cpu86_types.all;

entity register_reader is
    port (
        clk                     : in std_logic;
        resetn                  : in std_logic;

        instr_s_tvalid          : in std_logic;
        instr_s_tready          : out std_logic;
        instr_s_tdata           : in decoded_instr_t;
        instr_s_tuser           : in std_logic_vector(31 downto 0);

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

        rr_m_tvalid             : out std_logic;
        rr_m_tready             : in std_logic;
        rr_m_tdata              : out rr_instr_t;
        rr_m_tuser              : out std_logic_vector(31 downto 0)
    );
end entity register_reader;

architecture rtl of register_reader is

    signal instr_tvalid         : std_logic;
    signal instr_tready         : std_logic;
    signal instr_tdata          : decoded_instr_t;
    signal instr_tuser          : std_logic_vector(31 downto 0);

    signal rr_tvalid            : std_logic;
    signal rr_tready            : std_logic;
    signal rr_tdata             : rr_instr_t;
    signal rr_tuser             : std_logic_vector(31 downto 0);

    signal sreg_tvalid          : std_logic;
    signal sreg_tdata           : std_logic_vector(15 downto 0);

    signal dreg_tvalid          : std_logic;
    signal dreg_tdata           : std_logic_vector(15 downto 0);

    signal ea_tvalid            : std_logic;
    signal ea_tdata             : std_logic_vector(15 downto 0);

    signal intr_mask            : std_logic;

    signal seg_tvalid           : std_logic;
    signal seg_tdata            : std_logic_vector(15 downto 0);

    signal seg_override_tvalid  : std_logic;
    signal seg_override_tdata   : std_logic_vector(15 downto 0);

    signal dbg_instr_hs_cnt     : integer := 0;

begin

    instr_tvalid <= instr_s_tvalid;
    instr_s_tready <= instr_tready;
    instr_tdata <= instr_s_tdata;
    instr_tuser <= instr_s_tuser;

    rr_m_tvalid <= rr_tvalid;
    rr_tready <= rr_m_tready;
    rr_m_tdata <= rr_tdata;
    rr_m_tuser <= rr_tuser;

    process (all) begin

        case instr_tdata.sreg is
            when AX => sreg_tvalid <= ax_s_tvalid;
            when BX => sreg_tvalid <= bx_s_tvalid;
            when CX => sreg_tvalid <= cx_s_tvalid;
            when DX => sreg_tvalid <= dx_s_tvalid;
            when BP => sreg_tvalid <= bp_s_tvalid;
            when SI => sreg_tvalid <= si_s_tvalid;
            when DI => sreg_tvalid <= di_s_tvalid;
            when SP => sreg_tvalid <= sp_s_tvalid;
            when CS => sreg_tvalid <= '1';
            when DS => sreg_tvalid <= ds_s_tvalid;
            when SS => sreg_tvalid <= ss_s_tvalid;
            when ES => sreg_tvalid <= es_s_tvalid;
            when FL => sreg_tvalid <= flags_s_tvalid;
            when others => sreg_tvalid <= '0';
        end case;

        case instr_tdata.smask is
            when "01" =>
                sreg_tdata(15 downto 8) <= (others => '0');
                case instr_tdata.sreg is
                    when AX => sreg_tdata(7 downto 0) <= ax_s_tdata(7 downto 0);
                    when BX => sreg_tdata(7 downto 0) <= bx_s_tdata(7 downto 0);
                    when CX => sreg_tdata(7 downto 0) <= cx_s_tdata(7 downto 0);
                    when DX => sreg_tdata(7 downto 0) <= dx_s_tdata(7 downto 0);
                    when others => sreg_tdata(7 downto 0) <= ax_s_tdata(7 downto 0);
                end case;

            when "10" =>
                sreg_tdata(15 downto 8) <= (others => '0');
                case instr_tdata.sreg is
                    when AX => sreg_tdata(7 downto 0) <= ax_s_tdata(15 downto 8);
                    when BX => sreg_tdata(7 downto 0) <= bx_s_tdata(15 downto 8);
                    when CX => sreg_tdata(7 downto 0) <= cx_s_tdata(15 downto 8);
                    when DX => sreg_tdata(7 downto 0) <= dx_s_tdata(15 downto 8);
                    when others => sreg_tdata(7 downto 0) <= ax_s_tdata(15 downto 8);
                end case;

            when others =>
                case instr_tdata.sreg is
                    when AX => sreg_tdata <= ax_s_tdata;
                    when BX => sreg_tdata <= bx_s_tdata;
                    when CX => sreg_tdata <= cx_s_tdata;
                    when DX => sreg_tdata <= dx_s_tdata;
                    when BP => sreg_tdata <= bp_s_tdata;
                    when SI => sreg_tdata <= si_s_tdata;
                    when DI => sreg_tdata <= di_s_tdata;
                    when SP => sreg_tdata <= sp_s_tdata;
                    when CS => sreg_tdata <= instr_tuser(31 downto 16);
                    when SS => sreg_tdata <= ss_s_tdata;
                    when DS => sreg_tdata <= ds_s_tdata;
                    when ES => sreg_tdata <= es_s_tdata;
                    when others => sreg_tdata <= ax_s_tdata;
                end case;
        end case;

        if (seg_override_tvalid = '1') then
            seg_tvalid <= '1';
        else
            case instr_tdata.ea is
                when BP_SI_DISP | BP_DI_DISP | BP_DISP =>
                    seg_tvalid <= ss_s_tvalid;
                when others =>
                    seg_tvalid <= ds_s_tvalid;
            end case;
        end if;

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

        case instr_tdata.dreg is
            when AX => dreg_tvalid <= ax_s_tvalid;
            when BX => dreg_tvalid <= bx_s_tvalid;
            when CX => dreg_tvalid <= cx_s_tvalid;
            when DX => dreg_tvalid <= dx_s_tvalid;
            when BP => dreg_tvalid <= bp_s_tvalid;
            when SI => dreg_tvalid <= si_s_tvalid;
            when DI => dreg_tvalid <= di_s_tvalid;
            when SP => dreg_tvalid <= sp_s_tvalid;
            when DS => dreg_tvalid <= ds_s_tvalid;
            when ES => dreg_tvalid <= es_s_tvalid;
            when SS => dreg_tvalid <= ss_s_tvalid;
            when others => dreg_tvalid <= '0';
        end case;

        case instr_tdata.dreg is
            when AX => dreg_tdata <= ax_s_tdata;
            when BX => dreg_tdata <= bx_s_tdata;
            when CX => dreg_tdata <= cx_s_tdata;
            when DX => dreg_tdata <= dx_s_tdata;
            when BP => dreg_tdata <= bp_s_tdata;
            when SI => dreg_tdata <= si_s_tdata;
            when DI => dreg_tdata <= di_s_tdata;
            when SP => dreg_tdata <= sp_s_tdata;
            when others => dreg_tdata <= ax_s_tdata;
        end case;

        case instr_tdata.ea is
            when BX_SI_DISP =>
                if bx_s_tvalid = '1' and si_s_tvalid = '1' then
                    ea_tvalid <= '1';
                else
                    ea_tvalid <= '0';
                end if;
            when BX_DI_DISP =>
                if bx_s_tvalid = '1' and di_s_tvalid = '1' then
                    ea_tvalid <= '1';
                else
                    ea_tvalid <= '0';
                end if;
            when BP_SI_DISP =>
                if bp_s_tvalid = '1' and si_s_tvalid = '1' then
                    ea_tvalid <= '1';
                else
                    ea_tvalid <= '0';
                end if;
            when BP_DI_DISP =>
                if bp_s_tvalid = '1' and di_s_tvalid = '1' then
                    ea_tvalid <= '1';
                else
                    ea_tvalid <= '0';
                end if;
            when SI_DISP =>
                if si_s_tvalid = '1' then
                    ea_tvalid <= '1';
                else
                    ea_tvalid <= '0';
                end if;
            when DI_DISP =>
                if di_s_tvalid = '1' then
                    ea_tvalid <= '1';
                else
                    ea_tvalid <= '0';
                end if;
            when BP_DISP =>
                if bp_s_tvalid = '1' then
                    ea_tvalid <= '1';
                else
                    ea_tvalid <= '0';
                end if;
            when BX_DISP =>
                if bx_s_tvalid = '1' then
                    ea_tvalid <= '1';
                else
                    ea_tvalid <= '0';
                end if;
            when DIRECT =>
                ea_tvalid <= '1';

            when others =>
                ea_tvalid <= '0';
        end case;

        case instr_tdata.ea is
            when BX_SI_DISP => ea_tdata <= std_logic_vector(unsigned(bx_s_tdata) + unsigned(si_s_tdata));
            when BX_DI_DISP => ea_tdata <= std_logic_vector(unsigned(bx_s_tdata) + unsigned(di_s_tdata));
            when BP_SI_DISP => ea_tdata <= std_logic_vector(unsigned(bp_s_tdata) + unsigned(si_s_tdata));
            when BP_DI_DISP => ea_tdata <= std_logic_vector(unsigned(bp_s_tdata) + unsigned(di_s_tdata));
            when SI_DISP => ea_tdata <= si_s_tdata;
            when DI_DISP => ea_tdata <= di_s_tdata;
            when BP_DISP => ea_tdata <= bp_s_tdata;
            when BX_DISP => ea_tdata <= bx_s_tdata;
            when others => ea_tdata <= (others => '0');
        end case;

    end process;


    instr_tready_forming_proc: process (all) begin
        instr_tready <= '0';

        case instr_tdata.dir is
            when R2R =>
                if sreg_tvalid = '1' and dreg_tvalid = '1' and (rr_tvalid ='0' or (rr_tvalid = '1' and rr_tready = '1')) then
                    instr_tready <= '1';
                end if;
            when R2F =>
                if sreg_tvalid = '1' and (rr_tvalid ='0' or (rr_tvalid = '1' and rr_tready = '1')) then
                    instr_tready <= '1';
                end if;
            when R2M =>
                if sreg_tvalid = '1' and seg_tvalid = '1' and ea_tvalid = '1' and (rr_tvalid ='0' or (rr_tvalid = '1' and rr_tready = '1')) then
                    instr_tready <= '1';
                end if;
            when M2R =>
                if dreg_tvalid = '1' and seg_tvalid = '1' and ea_tvalid = '1' and (rr_tvalid ='0' or (rr_tvalid = '1' and rr_tready = '1')) then
                    instr_tready <= '1';
                end if;
            when SFLG =>
                if (rr_tvalid ='0' or (rr_tvalid = '1' and rr_tready = '1')) then
                    instr_tready <= '1';
                end if;
            when I2R | SSEG =>
                if dreg_tvalid = '1' and (rr_tvalid ='0' or (rr_tvalid = '1' and rr_tready = '1')) then
                    instr_tready <= '1';
                end if;
            when I2M =>
                if seg_tvalid = '1' and ea_tvalid = '1' and (rr_tvalid ='0' or (rr_tvalid = '1' and rr_tready = '1')) then
                    instr_tready <= '1';
                end if;
            when STK =>
                if dreg_tvalid = '1' and ss_s_tvalid = '1' and sreg_tvalid = '1' and (rr_tvalid ='0' or (rr_tvalid = '1' and rr_tready = '1')) then
                    instr_tready <= '1';
                end if;
            when STKM =>
                if dreg_tvalid = '1' and seg_tvalid = '1' and ea_tvalid = '1' and ss_s_tvalid = '1' and (rr_tvalid ='0' or (rr_tvalid = '1' and rr_tready = '1')) then
                    instr_tready <= '1';
                end if;
            when M2M =>
                if seg_tvalid = '1' and ea_tvalid = '1' and (rr_tvalid ='0' or (rr_tvalid = '1' and rr_tready = '1')) then
                    instr_tready <= '1';
                end if;
            when STR =>
                if seg_tvalid = '1' and ea_tvalid = '1' and es_s_tvalid = '1' and di_s_tvalid = '1' and ax_s_tvalid = '1' and flags_s_tvalid = '1' and
                    (rr_tvalid ='0' or (rr_tvalid = '1' and rr_tready = '1')) then
                    instr_tready <= '1';
                end if;
        end case;

    end process;

    reg_lock_proc: process (all) begin

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

        if (instr_tvalid = '1' and instr_tready = '1' and resetn = '1') then

            case instr_tdata.dir is
                when R2R | I2R | M2R =>
                    case instr_tdata.dreg is
                        when AX => ax_m_lock_tvalid <= '1';
                        when BX => bx_m_lock_tvalid <= '1';
                        when CX => cx_m_lock_tvalid <= '1';
                        when DX => dx_m_lock_tvalid <= '1';
                        when BP => bp_m_lock_tvalid <= '1';
                        when SP => sp_m_lock_tvalid <= '1';
                        when SI => si_m_lock_tvalid <= '1';
                        when DI => di_m_lock_tvalid <= '1';
                        when DS => ds_m_lock_tvalid <= '1';
                        when ES => es_m_lock_tvalid <= '1';
                        when SS => ss_m_lock_tvalid <= '1';
                        when others => null;
                    end case;

                when STK | STKM =>
                    sp_m_lock_tvalid <= '1';

                    if (instr_tdata.code = STACKU_POPR) then

                        case instr_tdata.sreg is
                            when AX => ax_m_lock_tvalid <= '1';
                            when BX => bx_m_lock_tvalid <= '1';
                            when CX => cx_m_lock_tvalid <= '1';
                            when DX => dx_m_lock_tvalid <= '1';
                            when BP => bp_m_lock_tvalid <= '1';
                            when SI => si_m_lock_tvalid <= '1';
                            when DI => di_m_lock_tvalid <= '1';
                            when DS => ds_m_lock_tvalid <= '1';
                            when ES => es_m_lock_tvalid <= '1';
                            when SS => ss_m_lock_tvalid <= '1';
                            when others => null;
                        end case;

                    elsif (instr_tdata.code = STACKU_POPA) then
                        ax_m_lock_tvalid <= '1';
                        bx_m_lock_tvalid <= '1';
                        cx_m_lock_tvalid <= '1';
                        dx_m_lock_tvalid <= '1';
                        bp_m_lock_tvalid <= '1';
                        sp_m_lock_tvalid <= '1';
                        si_m_lock_tvalid <= '1';
                        di_m_lock_tvalid <= '1';
                    end if;

                when STR =>
                    if (cx_s_tdata /= x"0000") then
                        case (instr_tdata.code) is
                            when STOS_OP =>
                                di_m_lock_tvalid <= '1';

                            when MOVS_OP =>
                                di_m_lock_tvalid <= '1';
                                si_m_lock_tvalid <= '1';

                            when others => null;
                        end case;
                    end if;
                when others =>
                    null;
            end case;

        end if;

    end process;

    flags_lock_proc : process (all) begin
        flags_m_lock_tvalid <= '0';

        if (instr_tvalid = '1' and instr_tready = '1') then
            if instr_tdata.op = SET_FLAG or (instr_tdata.op = ALU and instr_tdata.code /= ALU_SF_ADD) then
                flags_m_lock_tvalid <= '1';
            end if;
        end if;

    end process;

    forming_output_proc: process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                rr_tvalid <= '0';
            else

                if (instr_tvalid = '1' and instr_tready = '1') then
                    if (instr_tdata.op = SET_SEG) then
                        rr_tvalid <= '0';
                    else
                        rr_tvalid <= '1';
                    end if;
                elsif rr_tready = '1' then
                    rr_tvalid <= '0';
                end if;

            end if;

            if (instr_tvalid = '1' and instr_tready = '1') then

                rr_tdata.op <= instr_tdata.op;
                rr_tdata.w <= instr_tdata.w;
                rr_tdata.fl <= instr_tdata.fl;
                rr_tdata.code <= instr_tdata.code;
                rr_tdata.dir <= instr_tdata.dir;
                rr_tdata.ea <= instr_tdata.ea;
                rr_tdata.dreg <= instr_tdata.dreg;
                rr_tdata.dmask <= instr_tdata.dmask;
                rr_tdata.sreg <= instr_tdata.sreg;
                rr_tdata.data <= instr_tdata.data;
                rr_tdata.disp <= instr_tdata.disp;
                rr_tdata.sreg_val <= sreg_tdata;
                rr_tdata.dreg_val <= dreg_tdata;
                rr_tdata.ea_val <= ea_tdata;
                rr_tdata.seg_val <= seg_tdata;
                rr_tdata.ss_seg_val <= ss_s_tdata;
                rr_tdata.es_seg_val <= es_s_tdata;
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
                    if (instr_tdata.op = SET_SEG) then
                        seg_override_tvalid <= '1';
                    else
                        seg_override_tvalid <= '0';
                    end if;
                end if;

            end if;

            if (instr_tvalid = '1' and instr_tready = '1') then
                case instr_tdata.sreg is
                    when DS => seg_override_tdata <= ds_s_tdata;
                    when SS => seg_override_tdata <= ss_s_tdata;
                    when ES => seg_override_tdata <= es_s_tdata;
                    when others => seg_override_tdata <= instr_tuser(31 downto 16);
                end case;
            end if;

        end if;
    end process;

    dbg_instr_hs_cnt_proc : process (clk) begin

        if (rising_edge(clk)) then
            if resetn = '0' then
                dbg_instr_hs_cnt <= 0;
            else
                if (instr_tvalid = '1' and instr_tready = '1') then
                    dbg_instr_hs_cnt <= dbg_instr_hs_cnt + 1;
                end if;
            end if;
        end if;

    end process;

end architecture;
