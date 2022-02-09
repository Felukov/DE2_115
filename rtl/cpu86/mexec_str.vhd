library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.cpu86_types.all;

entity mexec_str is
    port (
        clk                     : in std_logic;
        resetn                  : in std_logic;

        req_s_tvalid            : in std_logic;
        req_s_tdata             : in str_req_t;

        res_m_tvalid            : out std_logic;
        res_m_tdata             : out str_res_t;
        res_m_tuser             : out std_logic_vector(15 downto 0);

        lsu_req_m_tvalid        : out std_logic;
        lsu_req_m_tready        : in std_logic;
        lsu_req_m_tcmd          : out std_logic;
        lsu_req_m_twidth        : out std_logic;
        lsu_req_m_taddr         : out std_logic_vector(19 downto 0);
        lsu_req_m_tdata         : out std_logic_vector(15 downto 0);

        lsu_rd_s_tvalid         : in std_logic;
        lsu_rd_s_tready         : out std_logic;
        lsu_rd_s_tdata          : in std_logic_vector(15 downto 0);

        io_req_m_tvalid         : out std_logic;
        io_req_m_tready         : in std_logic;
        io_req_m_tdata          : out std_logic_vector(39 downto 0);

        io_rd_s_tvalid          : in std_logic;
        io_rd_s_tready          : out std_logic;
        io_rd_s_tdata           : in std_logic_vector(15 downto 0);

        event_interrupt         : in std_logic
    );
end entity;

architecture rtl of mexec_str is

    component axis_fifo is
        generic (
            FIFO_DEPTH          : natural := 16;
            FIFO_WIDTH          : natural := 16;
            REGISTER_OUTPUT     : std_logic := '1'
        );
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            fifo_s_tvalid       : in std_logic;
            fifo_s_tready       : out std_logic;
            fifo_s_tdata        : in std_logic_vector(FIFO_WIDTH-1 downto 0);

            fifo_m_tvalid       : out std_logic;
            fifo_m_tready       : in std_logic;
            fifo_m_tdata        : out std_logic_vector(FIFO_WIDTH-1 downto 0)
        );
    end component;

    type cmps_iter_t is (st_first, st_second);

    signal instr_movs           : std_logic;
    signal instr_scas           : std_logic;
    signal instr_cmps           : std_logic;
    signal instr_lods           : std_logic;
    signal instr_stos           : std_logic;
    signal instr_ins            : std_logic;
    signal instr_in             : std_logic;
    signal instr_outs           : std_logic;
    signal instr_out            : std_logic;

    signal cmps_req_iter        : cmps_iter_t;
    signal cmps_res_iter        : cmps_iter_t;

    signal rd_req_tvalid        : std_logic;
    signal rd_req_tready        : std_logic;
    signal ds_si_addr           : std_logic_vector(19 downto 0);
    signal rd_req_cnt           : natural range 0 to 2**16-1;

    signal wr_req_tvalid        : std_logic;
    signal wr_req_tready        : std_logic;
    signal wr_req_tlast         : std_logic;
    signal es_di_addr           : std_logic_vector(19 downto 0);
    signal wr_req_tdata         : std_logic_vector(15 downto 0);

    signal io_rd_req_tvalid     : std_logic;
    signal io_rd_req_tready     : std_logic;
    signal io_rd_req_cnt        : natural range 0 to 2**16-1;

    signal io_wr_req_tvalid     : std_logic;
    signal io_wr_req_tready     : std_logic;
    signal io_wr_req_tlast      : std_logic;
    signal io_wr_req_tdata      : std_logic_vector(15 downto 0);

    signal reg_wr_tvalid        : std_logic;
    signal reg_wr_tready        : std_logic;
    signal reg_wr_taddr         : std_logic_vector(19 downto 0);
    signal reg_wr_cnt           : natural range 0 to 2**16-1;

    signal rep_cnt_m1           : natural range 0 to 2**16-1;
    signal increment            : std_logic_vector(15 downto 0);

    signal lsu_rd_s_tlast       : std_logic;
    signal lsu_rd_s_tready_mask : std_logic;
    signal io_rd_s_tready_mask  : std_logic;

    signal work_done_fl         : std_logic;
    signal stop_fl              : std_logic;

    signal fifo_s_tvalid        : std_logic;
    signal fifo_s_tready        : std_logic;
    signal fifo_s_tdata         : std_logic_vector(15 downto 0);
    signal fifo_m_tvalid        : std_logic;
    signal fifo_m_tready        : std_logic;
    signal fifo_m_tdata         : std_logic_vector(15 downto 0);

    signal cmp_tvalid           : std_logic;
    signal cmp_tvalid_mask      : std_logic;
    signal cmp_tready           : std_logic;
    signal cmp_tdata            : std_logic_vector(16 downto 0);
    signal cmp_tlast            : std_logic;
    signal cmp_a_val            : std_logic_vector(15 downto 0);
    signal cmp_b_val            : std_logic_vector(15 downto 0);

    signal cmp_res_tvalid       : std_logic;
    signal cmp_res_tlast        : std_logic;

    signal flags_cf             : std_logic;
    signal flags_pf             : std_logic;
    signal flags_zf_next        : std_logic;
    signal flags_zf             : std_logic;
    signal flags_of             : std_logic;
    signal flags_sf             : std_logic;
    signal flags_af             : std_logic;

    signal event_movs_rd_start  : std_logic;
    signal event_movs_rd_next   : std_logic;
    signal event_movs_req_last  : std_logic;
    signal event_movs_res_last  : std_logic;
    signal event_movs_finish    : std_logic;

    signal event_stos_finish    : std_logic;

    signal event_lods_rd_start  : std_logic;
    signal event_lods_finish    : std_logic;

    signal event_scas_rd_start  : std_logic;
    signal event_scas_finish    : std_logic;

    signal event_cmps_rd_start  : std_logic;
    signal event_cmps_rd_next   : std_logic;
    signal event_cmps_finish    : std_logic;

    signal event_in_finish      : std_logic;
    signal event_ins_finish     : std_logic;
    signal event_out_finish     : std_logic;
    signal event_outs_rd_start  : std_logic;
    signal event_outs_finish    : std_logic;

    signal event_stop           : std_logic;

    signal mem_trans_cnt        : natural range 0 to 31;
    signal io_trans_cnt         : natural range 0 to 31;

    signal di_addr_val          : std_logic_vector(15 downto 0);
    signal si_addr_val          : std_logic_vector(15 downto 0);

    signal cmp_finish_vector   : std_logic_vector(1 downto 0);

begin

    axis_fifo_inst : axis_fifo generic map (
        FIFO_DEPTH              => 16,
        FIFO_WIDTH              => 16,
        REGISTER_OUTPUT         => '1'
    ) port map (
        clk                     => clk,
        resetn                  => resetn,

        fifo_s_tvalid           => fifo_s_tvalid,
        fifo_s_tready           => fifo_s_tready,
        fifo_s_tdata            => fifo_s_tdata,

        fifo_m_tvalid           => fifo_m_tvalid,
        fifo_m_tready           => fifo_m_tready,
        fifo_m_tdata            => fifo_m_tdata
    );


    lsu_req_m_tvalid <= '1' when wr_req_tvalid = '1' or rd_req_tvalid = '1' else '0';

    rd_req_tready <= lsu_req_m_tready;
    wr_req_tready <= lsu_req_m_tready;

    lsu_req_m_twidth <= req_s_tdata.w;
    lsu_req_m_tdata <= wr_req_tdata;

    lsu_req_m_tcmd <= '1' when wr_req_tvalid = '1' else '0';
    lsu_req_m_taddr <= es_di_addr when wr_req_tvalid = '1' or (rd_req_tvalid = '1' and (instr_scas = '1' or (instr_cmps = '1' and cmps_res_iter = st_second))) else ds_si_addr;

    reg_wr_tready <= '1' when (wr_req_tvalid = '0' or (wr_req_tvalid = '1' and wr_req_tready = '1')) else '0';

    es_di_addr <= std_logic_vector(unsigned(req_s_tdata.es_val & x"0") + unsigned(x"0" & di_addr_val));
    ds_si_addr <= std_logic_vector(unsigned(req_s_tdata.ds_val & x"0") + unsigned(x"0" & si_addr_val));

    lsu_rd_s_tready <= '1' when lsu_rd_s_tready_mask = '0' and
        (wr_req_tvalid = '0' or (wr_req_tvalid = '1' and wr_req_tready = '1')) and
        (io_wr_req_tvalid = '0' or (io_wr_req_tvalid = '1' and io_wr_req_tready = '1')) else '0';

    lsu_rd_s_tlast <= '1' when mem_trans_cnt = 1 and rd_req_tvalid = '0' else '0';

    io_rd_s_tready <= '1' when io_rd_s_tready_mask = '0' and
        (wr_req_tvalid = '0' or (wr_req_tvalid = '1' and wr_req_tready = '1')) else '0';

    io_req_m_tvalid <= '1' when io_rd_req_tvalid = '1' or io_wr_req_tvalid = '1' else '0';
    io_rd_req_tready <= io_req_m_tready;
    io_wr_req_tready <= io_req_m_tready;

    io_req_m_tdata(39 downto 34) <= (others => '0');
    io_req_m_tdata(33) <= req_s_tdata.w;
    io_req_m_tdata(32) <= '1' when io_wr_req_tvalid = '1' else '0';
    io_req_m_tdata(31 downto 16) <= req_s_tdata.io_port;
    io_req_m_tdata(15 downto 0) <= io_wr_req_tdata;

    fifo_m_tready <= '1' when lsu_rd_s_tvalid = '1' and lsu_rd_s_tready = '1' and (instr_scas = '1' or (instr_cmps = '1' and cmps_res_iter = st_second)) else '0';
    cmp_tready <= '1' when instr_scas = '1' or instr_cmps = '1' else '0';

    event_stop <= '1' when cmp_tvalid = '1' and cmp_tready = '1' and req_s_tdata.rep = '1' and
        ((req_s_tdata.rep_nz = '1' and flags_zf_next = '1') or (req_s_tdata.rep_nz = '0' and flags_zf_next = '0')) else '0';

    common_proc : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                work_done_fl <= '0';
                stop_fl <= '0';
                rep_cnt_m1 <= 0;
                instr_movs <= '0';
                instr_scas <= '0';
                instr_cmps <= '0';
                instr_lods <= '0';
                instr_stos <= '0';
                instr_ins <= '0';
                instr_in <= '0';
                instr_outs <= '0';
                instr_out <= '0';
                mem_trans_cnt <= 0;
                io_trans_cnt <= 0;
                cmp_finish_vector <= "00";
            else

                if (req_s_tvalid = '1') then
                    work_done_fl <= '0';
                elsif (rd_req_tvalid = '1' and rd_req_tready = '1') then
                    if (rd_req_cnt = rep_cnt_m1 and (instr_movs = '1' or instr_lods = '1' or (instr_cmps = '1' and cmps_req_iter = st_second))) then
                        work_done_fl <= '1';
                    end if;
                elsif (reg_wr_tvalid = '1' and reg_wr_tready = '1') then
                    if (reg_wr_cnt = rep_cnt_m1) then
                        work_done_fl <= '1';
                    end if;
                end if;

                if (req_s_tvalid = '1') then
                    stop_fl <= '0';
                elsif (event_stop = '1') then
                    stop_fl <= '1';
                end if;

                if (req_s_tvalid = '1') then
                    rep_cnt_m1 <= to_integer(unsigned(req_s_tdata.cx_val)) - 1;
                elsif (rd_req_tvalid = '1' and rd_req_tready = '1') then
                    if rd_req_cnt = rep_cnt_m1 and ((instr_cmps = '1' and cmps_req_iter = st_second) or
                        instr_movs = '1' or instr_scas = '1' or instr_lods = '1') then
                        rep_cnt_m1 <= 0;
                    elsif ((instr_movs = '1' or (instr_cmps = '1' and cmps_req_iter = st_second)) and rd_req_cnt = 15) then
                        rep_cnt_m1 <= rep_cnt_m1 - 16;
                    end if;
                end if;

                if req_s_tvalid = '1' then
                    if req_s_tdata.code = MOVS_OP then
                        instr_movs <= '1';
                    else
                        instr_movs <= '0';
                    end if;

                    if req_s_tdata.code = SCAS_OP then
                        instr_scas <= '1';
                    else
                        instr_scas <= '0';
                    end if;

                    if req_s_tdata.code = LODS_OP then
                        instr_lods <= '1';
                    else
                        instr_lods <= '0';
                    end if;

                    if req_s_tdata.code = STOS_OP then
                        instr_stos <= '1';
                    else
                        instr_stos <= '0';
                    end if;

                    if req_s_tdata.code = CMPS_OP then
                        instr_cmps <= '1';
                    else
                        instr_cmps <= '0';
                    end if;

                    if req_s_tdata.code = INS_OP then
                        instr_ins <= '1';
                    else
                        instr_ins <= '0';
                    end if;

                    if req_s_tdata.code = IN_OP then
                        instr_in <= '1';
                    else
                        instr_in <= '0';
                    end if;

                    if req_s_tdata.code = OUTS_OP then
                        instr_outs <= '1';
                    else
                        instr_outs <= '0';
                    end if;

                    if req_s_tdata.code = OUT_OP then
                        instr_out <= '1';
                    else
                        instr_out <= '0';
                    end if;
                end if;

                if (rd_req_tvalid = '1' and rd_req_tready = '1' and lsu_rd_s_tvalid = '1' and lsu_rd_s_tready = '1') then
                    mem_trans_cnt <= mem_trans_cnt;
                elsif (rd_req_tvalid = '1' and rd_req_tready = '1') then
                    mem_trans_cnt <= mem_trans_cnt + 1;
                elsif (lsu_rd_s_tvalid = '1' and lsu_rd_s_tready = '1') then
                    mem_trans_cnt <= mem_trans_cnt - 1;
                end if;

                if (io_rd_req_tvalid = '1' and io_rd_req_tready = '1' and io_rd_s_tvalid = '1' and io_rd_s_tready = '1') then
                    io_trans_cnt <= io_trans_cnt;
                elsif (io_rd_req_tvalid = '1' and io_rd_req_tready = '1') then
                    io_trans_cnt <= io_trans_cnt + 1;
                elsif (io_rd_s_tvalid = '1' and io_rd_s_tready = '1') then
                    io_trans_cnt <= io_trans_cnt - 1;
                end if;

                if (cmp_finish_vector = "11") then
                    cmp_finish_vector(0) <= '0';
                elsif (cmp_tvalid = '1' and cmp_tready = '1' and cmp_tlast = '1') then
                    cmp_finish_vector(0) <= '1';
                end if;

                if (cmp_finish_vector = "11") then
                    cmp_finish_vector(1) <= '0';
                elsif (cmp_res_tvalid = '1' and cmp_res_tlast = '1') then
                    cmp_finish_vector(1) <= '1';
                end if;

            end if;

            if (req_s_tvalid = '1') then
                if (req_s_tdata.w = '0') then
                    if (req_s_tdata.direction = '0') then
                        increment <= x"0001";
                    else
                        increment <= x"FFFF";
                    end if;
                else
                    if (req_s_tdata.direction = '0') then
                        increment <= x"0002";
                    else
                        increment <= x"FFFE";
                    end if;
                end if;
            end if;

            if (req_s_tvalid = '1') then
                res_m_tdata.code <= req_s_tdata.code;
                res_m_tdata.rep <= req_s_tdata.rep;
                res_m_tdata.w <= req_s_tdata.w;

                if req_s_tdata.code = MOVS_OP or req_s_tdata.code = STOS_OP or
                    req_s_tdata.code = SCAS_OP or req_s_tdata.code = CMPS_OP or
                    req_s_tdata.code = INS_OP
                then
                    res_m_tdata.di_upd_fl <= '1';
                else
                    res_m_tdata.di_upd_fl <= '0';
                end if;

                if req_s_tdata.code = MOVS_OP or req_s_tdata.code = LODS_OP or
                    req_s_tdata.code = CMPS_OP or req_s_tdata.code = OUTS_OP
                then
                    res_m_tdata.si_upd_fl <= '1';
                else
                    res_m_tdata.si_upd_fl <= '0';
                end if;

                if req_s_tdata.code = LODS_OP or req_s_tdata.code = IN_OP then
                    res_m_tdata.ax_upd_fl <= '1';
                else
                    res_m_tdata.ax_upd_fl <= '0';
                end if;
            end if;

            if (req_s_tvalid = '1') then
                if req_s_tdata.code = STOS_OP or req_s_tdata.code = LODS_OP or
                    req_s_tdata.code = INS_OP or req_s_tdata.code = OUTS_OP
                then
                    res_m_tdata.cx_val <= x"0000";
                else
                    res_m_tdata.cx_val <= req_s_tdata.cx_val;
                end if;
            elsif (cmp_res_tvalid = '1') then
                res_m_tdata.cx_val <= std_logic_vector(unsigned(res_m_tdata.cx_val) - 1);
            elsif (instr_movs = '1' and rd_req_tvalid = '1' and rd_req_tready = '1') then
                if (rd_req_cnt = 15) then
                    res_m_tdata.cx_val <= std_logic_vector(unsigned(res_m_tdata.cx_val) - 16);
                elsif (rd_req_cnt = rep_cnt_m1) then
                    res_m_tdata.cx_val <= x"0000";
                end if;
            end if;

            if (req_s_tvalid = '1') then
                res_m_tdata.si_val <= req_s_tdata.si_val;
            elsif (rd_req_tvalid = '1' and rd_req_tready = '1' and (instr_movs = '1' or instr_lods = '1' or instr_outs = '1')) or (cmp_res_tvalid = '1') then
                res_m_tdata.si_val <= std_logic_vector(unsigned(res_m_tdata.si_val) + unsigned(increment));
            end if;

            if (req_s_tvalid = '1') then
                si_addr_val <= req_s_tdata.si_val;
            elsif (rd_req_tvalid = '1' and rd_req_tready = '1' and (instr_movs = '1' or instr_lods = '1' or instr_outs = '1' or
                (instr_cmps = '1' and cmps_res_iter = st_first))) then
                si_addr_val <= std_logic_vector(unsigned(si_addr_val) + unsigned(increment));
            end if;

            if (req_s_tvalid = '1') then
                res_m_tdata.di_val <= req_s_tdata.di_val;
            elsif (wr_req_tvalid = '1' and wr_req_tready = '1') or (cmp_res_tvalid = '1') then
                res_m_tdata.di_val <= std_logic_vector(unsigned(res_m_tdata.di_val) + unsigned(increment));
            end if;

            if (req_s_tvalid = '1') then
                di_addr_val <= req_s_tdata.di_val;
            elsif (wr_req_tvalid = '1' and wr_req_tready = '1') or (rd_req_tvalid = '1' and rd_req_tready = '1' and
                (instr_scas = '1' or (instr_cmps = '1' and cmps_res_iter = st_second))) then
                di_addr_val <= std_logic_vector(unsigned(di_addr_val) + unsigned(increment));
            end if;

            if (lsu_rd_s_tvalid = '1' and lsu_rd_s_tready = '1')  then
                res_m_tdata.ax_val <= lsu_rd_s_tdata;
            elsif (io_rd_s_tvalid = '1' and io_rd_s_tready = '1') then
                res_m_tdata.ax_val <= io_rd_s_tdata;
            end if;

        end if;
    end process;

    event_movs_rd_start <= '1' when req_s_tvalid = '1' and req_s_tdata.code = MOVS_OP else '0';
    event_movs_rd_next <= '1' when instr_movs = '1' and wr_req_tvalid = '1' and
        wr_req_tready = '1' and wr_req_tlast = '1' and work_done_fl = '0' else '0';

    event_lods_rd_start <= '1' when req_s_tvalid = '1' and req_s_tdata.code = LODS_OP else '0';
    event_outs_rd_start <= '1' when req_s_tvalid = '1' and req_s_tdata.code = OUTS_OP else '0';
    event_scas_rd_start <= '1' when req_s_tvalid = '1' and req_s_tdata.code = SCAS_OP else '0';

    event_cmps_rd_start <= '1' when req_s_tvalid = '1' and req_s_tdata.code = CMPS_OP else '0';
    event_cmps_rd_next <= '1' when lsu_rd_s_tvalid = '1' and lsu_rd_s_tready = '1' and lsu_rd_s_tlast = '1' and
        (work_done_fl = '0') and (instr_cmps = '1') else '0';

    mem_rd_proc: process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                rd_req_tvalid <= '0';
                rd_req_cnt <= 0;
            else

                if event_movs_rd_start = '1' or event_movs_rd_next = '1' or
                    event_lods_rd_start = '1' or event_scas_rd_start = '1' or
                    event_cmps_rd_start = '1' or event_cmps_rd_next = '1' or
                    event_outs_rd_start = '1'
                then
                    rd_req_tvalid <= '1';
                elsif rd_req_tvalid = '1' and rd_req_tready = '1' and
                    ((instr_movs = '1' and (rd_req_cnt = 15 or rd_req_cnt = rep_cnt_m1)) or
                     (instr_cmps = '1' and (rd_req_cnt = 15 or rd_req_cnt = rep_cnt_m1 or stop_fl = '1')) or
                     (instr_scas = '1' and (rd_req_cnt = 15 or rd_req_cnt = rep_cnt_m1 or stop_fl = '1')) or
                     (instr_lods = '1' and (rd_req_cnt = rep_cnt_m1)) or
                     (instr_outs = '1' and (rd_req_cnt = rep_cnt_m1)))
                then
                    rd_req_tvalid <= '0';
                end if;

                if rd_req_tvalid = '1' and rd_req_tready = '1' then
                    if (instr_movs = '1' and (rd_req_cnt = 15 or rd_req_cnt = rep_cnt_m1)) or
                        (instr_cmps = '1' and (rd_req_cnt = 15 or rd_req_cnt = rep_cnt_m1 or stop_fl = '1')) or
                        (instr_scas = '1' and (rd_req_cnt = 15 or rd_req_cnt = rep_cnt_m1 or stop_fl = '1')) or
                        (instr_lods = '1' and (rd_req_cnt = rep_cnt_m1)) or
                        (instr_outs = '1' and (rd_req_cnt = rep_cnt_m1))
                    then
                        rd_req_cnt <= 0;
                    else
                        rd_req_cnt <= rd_req_cnt + 1;
                    end if;
                end if;

            end if;

        end if;
    end process;

    reg_rd_proc : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                reg_wr_tvalid <= '0';
                reg_wr_cnt <= 0;
            else

                if (req_s_tvalid = '1' and req_s_tdata.code = STOS_OP) then
                    reg_wr_tvalid <= '1';
                elsif (reg_wr_tvalid = '1' and reg_wr_tready = '1' and reg_wr_cnt = rep_cnt_m1) then
                    reg_wr_tvalid <= '0';
                end if;

                if (reg_wr_tvalid = '1' and reg_wr_tready = '1') then
                    if (reg_wr_cnt = rep_cnt_m1) then
                        reg_wr_cnt <= 0;
                    else
                        reg_wr_cnt <= reg_wr_cnt + 1;
                    end if;
                end if;

            end if;
        end if;
    end process;

    cmps_proc : process (clk) begin

        if rising_edge(clk) then
            if resetn = '0' then
                cmps_req_iter <= st_first;
                cmps_res_iter <= st_first;
            else

                if (instr_cmps = '1' and rd_req_tvalid = '1' and rd_req_tready = '1' and (rd_req_cnt = 15 or rd_req_cnt = rep_cnt_m1)) then
                    if cmps_req_iter = st_first then
                        cmps_req_iter <= st_second;
                    elsif cmps_req_iter = st_second then
                        cmps_req_iter <= st_first;
                    end if;
                end if;


                if (instr_cmps = '1' and lsu_rd_s_tvalid = '1' and lsu_rd_s_tready = '1' and lsu_rd_s_tlast = '1') then
                    if cmps_res_iter = st_first then
                        cmps_res_iter <= st_second;
                    elsif cmps_res_iter = st_second then
                        cmps_res_iter <= st_first;
                    end if;
                end if;

            end if;
        end if;

    end process;

    cmp_proc : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                fifo_s_tvalid <= '0';
                cmp_tvalid <= '0';
                cmp_tvalid_mask <= '0';
                cmp_tlast <= '0';
                cmp_res_tvalid <= '0';
                cmp_res_tlast <= '0';
            else

                if (rd_req_tvalid = '1' and rd_req_tready = '1' and instr_scas = '1') then
                    fifo_s_tvalid <= '1';
                elsif (lsu_rd_s_tvalid = '1' and lsu_rd_s_tready = '1' and instr_cmps = '1' and cmps_res_iter = st_first) then
                    fifo_s_tvalid <= '1';
                else
                    fifo_s_tvalid <= '0';
                end if;

                if (fifo_m_tvalid = '1' and fifo_m_tready = '1') then
                    cmp_tvalid <= '1';
                elsif (cmp_tready = '1') then
                    cmp_tvalid <= '0';
                end if;

                if (fifo_m_tvalid = '1' and fifo_m_tready = '1') then
                    if (lsu_rd_s_tlast = '1' and (rep_cnt_m1 = 0 or stop_fl = '1')) then
                        cmp_tlast <= '1';
                    else
                        cmp_tlast <= '0';
                    end if;
                end if;

                if (req_s_tvalid = '1') then
                    cmp_tvalid_mask <= '0';
                elsif (cmp_tvalid = '1' and cmp_tready = '1') then
                    if (req_s_tdata.rep = '1' and ((req_s_tdata.rep_nz = '1' and flags_zf_next = '1') or (req_s_tdata.rep_nz = '0' and flags_zf_next = '0'))) then
                        cmp_tvalid_mask <= '1';
                    end if;
                end if;

                if (cmp_tvalid = '1' and cmp_tready = '1' and cmp_tvalid_mask = '0') then
                    cmp_res_tvalid <= '1';
                else
                    cmp_res_tvalid <= '0';
                end if;

                if (cmp_tvalid = '1' and cmp_tready = '1' and cmp_tvalid_mask = '0') then
                    if (req_s_tdata.rep = '1' and ((req_s_tdata.rep_nz = '1' and flags_zf_next = '1') or (req_s_tdata.rep_nz = '0' and flags_zf_next = '0'))) or
                       (cmp_tlast = '1')
                    then
                        cmp_res_tlast <= '1';
                    else
                        cmp_res_tlast <= '0';
                    end if;
                end if;

            end if;

            if (req_s_tvalid = '1' and req_s_tdata.code = SCAS_OP) then
                fifo_s_tdata <= req_s_tdata.ax_val;
            elsif (lsu_rd_s_tvalid = '1' and lsu_rd_s_tready = '1' and instr_cmps = '1' and cmps_res_iter = st_first) then
                fifo_s_tdata <= lsu_rd_s_tdata;
            end if;

            if (fifo_m_tvalid = '1' and fifo_m_tready = '1') then
                cmp_tdata <= std_logic_vector(unsigned('0' & fifo_m_tdata) - unsigned('0' & lsu_rd_s_tdata));
                cmp_a_val <= fifo_m_tdata;
                cmp_b_val <= lsu_rd_s_tdata;
            end if;

        end if;
    end process;

    mem_wr_proc : process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                wr_req_tvalid <= '0';
                wr_req_tlast <= '0';
            else

                if (lsu_rd_s_tvalid = '1' and lsu_rd_s_tready = '1' and instr_movs = '1') or
                    (io_rd_s_tvalid = '1' and io_rd_s_tready = '1' and instr_ins = '1') or
                    (reg_wr_tvalid = '1' and reg_wr_tready = '1') then
                    wr_req_tvalid <= '1';
                elsif (wr_req_tready = '1') then
                    wr_req_tvalid <= '0';
                end if;

                if (lsu_rd_s_tvalid = '1' and lsu_rd_s_tready = '1' and instr_movs = '1') then
                    if (lsu_rd_s_tlast = '1') then
                        wr_req_tlast <= '1';
                    else
                        wr_req_tlast <= '0';
                    end if;

                elsif (io_rd_s_tvalid = '1' and io_rd_s_tready = '1' and instr_ins = '1') then
                    if (io_rd_req_tvalid = '0' and io_trans_cnt = 1) then
                        wr_req_tlast <= '1';
                    else
                        wr_req_tlast <= '0';
                    end if;

                elsif (reg_wr_tvalid = '1' and reg_wr_tready = '1') then
                    if (reg_wr_cnt = rep_cnt_m1) then
                        wr_req_tlast <= '1';
                    else
                        wr_req_tlast <= '0';
                    end if;
                end if;

            end if;

            if (req_s_tvalid = '1' and req_s_tdata.code = STOS_OP) then
                wr_req_tdata <= req_s_tdata.ax_val;
            elsif (lsu_rd_s_tvalid = '1' and lsu_rd_s_tready = '1' and instr_movs = '1') then
                wr_req_tdata <= lsu_rd_s_tdata;
            elsif (io_rd_s_tvalid = '1' and io_rd_s_tready = '1' and instr_ins = '1') then
                wr_req_tdata <= io_rd_s_tdata;
            end if;

        end if;
    end process;

    event_movs_req_last <= '1' when instr_movs = '1' and rd_req_tvalid = '1' and rd_req_tready = '1' and
        (rd_req_cnt = 15 or rd_req_cnt = rep_cnt_m1) else '0';
    event_movs_res_last <= '1' when instr_movs = '1' and lsu_rd_s_tvalid = '1' and lsu_rd_s_tready = '1' and lsu_rd_s_tlast = '1' else '0';

    mem_troughput_controller : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                lsu_rd_s_tready_mask <= '1';
            else

                if (req_s_tvalid = '1') then
                    if (req_s_tdata.code = MOVS_OP) then
                        lsu_rd_s_tready_mask <= '1';
                    else
                        lsu_rd_s_tready_mask <= '0';
                    end if;
                elsif (event_movs_req_last = '1') then
                    lsu_rd_s_tready_mask <= '0';
                elsif (event_movs_res_last = '1' or res_m_tvalid = '1') then
                    lsu_rd_s_tready_mask <= '1';
                end if;

            end if;
        end if;
    end process;

    io_rd_proc : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                io_rd_req_tvalid <= '0';
                io_rd_req_cnt <= 0;
            else

                if (req_s_tvalid = '1' and (req_s_tdata.code = IN_OP or req_s_tdata.code = INS_OP)) then
                    io_rd_req_tvalid <= '1';
                elsif (io_rd_req_tvalid = '1' and io_rd_req_tready = '1' and io_rd_req_cnt = rep_cnt_m1) then
                    io_rd_req_tvalid <= '0';
                end if;

                if io_rd_req_tvalid = '1' and io_rd_req_tready = '1' then
                    if io_rd_req_cnt = rep_cnt_m1 and (instr_in = '1' or instr_ins = '1') then
                        io_rd_req_cnt <= 0;
                    else
                        io_rd_req_cnt <= io_rd_req_cnt + 1;
                    end if;
                end if;

            end if;

        end if;
    end process;

    io_wr_proc : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                io_wr_req_tvalid <= '0';
                io_wr_req_tlast <= '0';
            else

                if (req_s_tvalid = '1' and (req_s_tdata.code = OUT_OP)) or
                    (lsu_rd_s_tvalid = '1' and lsu_rd_s_tready = '1' and instr_outs = '1')
                then
                    io_wr_req_tvalid <= '1';
                elsif (io_wr_req_tready = '1') then
                    io_wr_req_tvalid <= '0';
                end if;

                if (lsu_rd_s_tvalid = '1' and lsu_rd_s_tready = '1' and instr_outs = '1') then
                    if (lsu_rd_s_tlast = '1') then
                        io_wr_req_tlast <= '1';
                    else
                        io_wr_req_tlast <= '0';
                    end if;
                end if;

            end if;

            if (req_s_tvalid = '1' and (req_s_tdata.code = OUT_OP)) then
                io_wr_req_tdata <= req_s_tdata.ax_val;
            elsif (lsu_rd_s_tvalid = '1' and lsu_rd_s_tready = '1' and instr_outs = '1')  then
                io_wr_req_tdata <= lsu_rd_s_tdata;
            end if;

        end if;
    end process;

    io_troughput_controller : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                io_rd_s_tready_mask <= '1';
            else

                if (req_s_tvalid = '1') then
                    if (req_s_tdata.code = IN_OP or req_s_tdata.code = INS_OP) then
                        io_rd_s_tready_mask <= '0';
                    end if;
                elsif (res_m_tvalid = '1') then
                    io_rd_s_tready_mask <= '1';
                end if;

            end if;
        end if;
    end process;

    pending_interrupt_handler : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then

            else

            end if;
        end if;
    end process;

    event_movs_finish <= '1' when instr_movs = '1' and wr_req_tvalid = '1' and wr_req_tready = '1' and wr_req_tlast = '1' and work_done_fl = '1' else '0';
    event_stos_finish <= '1' when instr_stos = '1' and wr_req_tvalid = '1' and wr_req_tready = '1' and wr_req_tlast = '1' and work_done_fl = '1' else '0';
    event_lods_finish <= '1' when instr_lods = '1' and lsu_rd_s_tvalid = '1' and lsu_rd_s_tready = '1' and lsu_rd_s_tlast = '1' and work_done_fl = '1' else '0';
    event_scas_finish <= '1' when instr_scas = '1' and (cmp_finish_vector = "11") else '0';
    event_cmps_finish <= '1' when instr_cmps = '1' and (cmp_finish_vector = "11") else '0';

    event_in_finish <= '1' when instr_in = '1' and io_rd_s_tvalid = '1' and io_rd_s_tready = '1' else '0';
    event_ins_finish <= '1' when instr_ins = '1' and wr_req_tvalid = '1' and wr_req_tready = '1' and wr_req_tlast = '1' else '0';
    event_out_finish <= '1' when instr_out = '1' and io_wr_req_tvalid = '1' and io_wr_req_tready = '1' else '0';
    event_outs_finish <= '1' when instr_outs = '1' and io_wr_req_tvalid = '1' and io_wr_req_tready = '1' and io_wr_req_tlast = '1' else '0';

    foriming_output : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                res_m_tvalid <= '0';
            else
                if event_movs_finish = '1' or event_lods_finish = '1' or
                   event_scas_finish = '1' or event_stos_finish = '1' or
                   event_cmps_finish = '1' or event_out_finish = '1' or
                   event_outs_finish = '1' or event_in_finish = '1' or
                   event_ins_finish = '1'
                then
                    res_m_tvalid <= '1';
                else
                    res_m_tvalid <= '0';
                end if;
            end if;
        end if;
    end process;

    flag_calc_next_proc : process (all) begin
        if req_s_tdata.w = '0' then
            if (cmp_tdata(7 downto 0) = x"00") then
                flags_zf_next <= '1';
            else
                flags_zf_next <= '0';
            end if;
        else
            if (cmp_tdata(15 downto 0) = x"0000") then
                flags_zf_next <= '1';
            else
                flags_zf_next <= '0';
            end if;
        end if;
    end process;

    flag_calc_proc : process (clk) begin
        if rising_edge(clk) then

            if (cmp_tvalid = '1' and cmp_tready = '1') then
                flags_pf <= not (cmp_tdata(7) xor cmp_tdata(6) xor cmp_tdata(5) xor cmp_tdata(4) xor
                                cmp_tdata(3) xor cmp_tdata(2) xor cmp_tdata(1) xor cmp_tdata(0));
                flags_af <= cmp_a_val(4) xor cmp_b_val(4) xor cmp_tdata(4);

                flags_zf <= flags_zf_next;

                if req_s_tdata.w = '0' then
                    flags_sf <= cmp_tdata(7);
                else
                    flags_sf <= cmp_tdata(15);
                end if;

                if req_s_tdata.w = '0' then
                    flags_cf <= cmp_a_val(8) xor cmp_b_val(8) xor cmp_tdata(8);
                else
                    flags_cf <= cmp_tdata(16);
                end if;

                if req_s_tdata.w = '0' then
                    flags_of <= (cmp_a_val(7) xor cmp_b_val(7)) and (cmp_tdata(7) xor cmp_a_val(7));
                else
                    flags_of <= (cmp_a_val(15) xor cmp_b_val(15)) and (cmp_tdata(15) xor cmp_a_val(15));
                end if;
            end if;

            if (cmp_res_tvalid = '1') then
                res_m_tuser(FLAG_15) <= '0';
                res_m_tuser(FLAG_14) <= '0';
                res_m_tuser(FLAG_13) <= '0';
                res_m_tuser(FLAG_12) <= '0';
                res_m_tuser(FLAG_OF) <= flags_of;
                res_m_tuser(FLAG_DF) <= '0';
                res_m_tuser(FLAG_IF) <= '0';
                res_m_tuser(FLAG_TF) <= '0';
                res_m_tuser(FLAG_SF) <= flags_sf;
                res_m_tuser(FLAG_ZF) <= flags_zf;
                res_m_tuser(FLAG_05) <= '0';
                res_m_tuser(FLAG_AF) <= flags_af;
                res_m_tuser(FLAG_03) <= '0';
                res_m_tuser(FLAG_PF) <= flags_pf;
                res_m_tuser(FLAG_01) <= '0';
                res_m_tuser(FLAG_CF) <= flags_cf;
            end if;

        end if;
    end process;

end architecture;
