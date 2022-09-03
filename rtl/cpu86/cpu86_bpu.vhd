
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
use ieee.math_real.all;


entity cpu86_bpu is
    port (
        clk                         : in std_logic;
        resetn                      : in std_logic;

        s_axis_instr_tvalid         : in std_logic;
        s_axis_instr_tready         : out std_logic;
        s_axis_instr_tdata          : in slv_decoded_instr_t;
        s_axis_instr_tuser          : in user_t;

        m_axis_instr_tvalid         : out std_logic;
        m_axis_instr_tready         : in std_logic;
        m_axis_instr_tdata          : out slv_decoded_instr_t;
        m_axis_instr_tuser          : out user_t;

        s_axis_jump_tvalid          : in std_logic;
        s_axis_jump_tdata           : in cpu86_jump_t;

        m_axis_jump_tvalid          : out std_logic;
        m_axis_jump_tdata           : out std_logic_vector(31 downto 0)
    );
end entity cpu86_bpu;

architecture rtl of cpu86_bpu is

    constant BPU_ITEM_CNT           : natural := 8;
    constant BPU_ITEM_IDX_WIDTH     : integer := integer(ceil(log2(real(BPU_ITEM_CNT))));

    component axis_reg is
        generic (
            DATA_WIDTH              : natural := 32
        );
        port (
            clk                     : in std_logic;
            resetn                  : in std_logic;
            in_s_tvalid             : in std_logic;
            in_s_tready             : out std_logic;
            in_s_tdata              : in std_logic_vector (DATA_WIDTH-1 downto 0);
            out_m_tvalid            : out std_logic;
            out_m_tready            : in std_logic;
            out_m_tdata             : out std_logic_vector (DATA_WIDTH-1 downto 0)
        );
    end component;

    type bpu_item_t is record
        valid                       : std_logic;
        saturated_cnt               : natural range 0 to 3;
        inst_cs                     : std_logic_vector(15 downto 0);
        inst_ip                     : std_logic_vector(15 downto 0);
        jump_cs                     : std_logic_vector(15 downto 0);
        jump_ip                     : std_logic_vector(15 downto 0);
    end record;

    type bpu_items_t is array (natural range 0 to BPU_ITEM_CNT-1) of bpu_item_t;

    type items_pos_t is array (natural range 0 to BPU_ITEM_CNT-1) of std_logic_vector(BPU_ITEM_IDX_WIDTH-1 downto 0);

    signal local_resetn             : std_logic;
    signal s_axis_instr_payload     : std_logic_vector(DECODED_INSTR_T_WIDTH + USER_T_WIDTH - 1 downto 0);

    signal instr_s_tvalid           : std_logic;
    signal instr_s_tready           : std_logic;
    signal instr_s_payload          : std_logic_vector(DECODED_INSTR_T_WIDTH + USER_T_WIDTH - 1 downto 0);
    signal instr_s_tdata            : decoded_instr_t;
    signal instr_s_tuser            : user_t;

    signal instr_m_tvalid           : std_logic;
    signal instr_m_tready           : std_logic;
    signal instr_m_tdata            : decoded_instr_t;
    signal instr_m_tuser            : user_t;

    signal jump_s_tvalid            : std_logic;
    signal jump_s_tdata             : cpu86_jump_t;

    signal jump_m_tvalid            : std_logic;
    signal jump_m_tdata             : std_logic_vector(31 downto 0);

    signal bpu_items                : bpu_items_t;
    signal bpu_wr_valid             : std_logic;
    signal bpu_wr_idx               : natural range 0 to BPU_ITEM_CNT-1;
    signal bpu_rd_idx               : natural range 0 to BPU_ITEM_CNT-1;
    signal bpu_item_wr_hit          : std_logic_vector(BPU_ITEM_CNT-1 downto 0);
    signal bpu_item_wr_hit_any      : std_logic;

    signal d_jump_s_tvalid          : std_logic;
    signal d_jump_s_tdata           : cpu86_jump_t;
    signal d_bpu_item_wr_hit        : std_logic_vector(BPU_ITEM_CNT-1 downto 0);
    signal d_bpu_item_wr_hit_any    : std_logic;

    signal bpu_item_rd_hit          : std_logic_vector(BPU_ITEM_CNT-1 downto 0);
    signal bpu_item_rd_hit_idx      : std_logic_vector(BPU_ITEM_IDX_WIDTH-1 downto 0);  --natural range 0 to BPU_ITEM_CNT-1;
    signal bpu_item_rd_hit_pos      : items_pos_t;

    signal read_ahead_tvalid        : std_logic;
    signal read_ahead_tdata         : std_logic_vector(31 downto 0);

    signal bpu_item_rd_tdata        : std_logic_vector(BPU_ITEM_CNT+BPU_ITEM_IDX_WIDTH-1 downto 0);

    signal d_bpu_item_rd_tvalid     : std_logic;
    signal d_bpu_item_rd_tdata      : std_logic_vector(BPU_ITEM_CNT+BPU_ITEM_IDX_WIDTH-1 downto 0);
    signal d_bpu_item_rd_hit        : std_logic_vector(BPU_ITEM_CNT-1 downto 0);
    signal d_bpu_item_rd_hit_idx    : natural range 0 to BPU_ITEM_CNT-1;
    signal d_bpu_item_rd_hit_any    : std_logic;

    signal next_free_bpu_item_idx   : natural range 0 to BPU_ITEM_CNT-1;

    signal jump_pass                : std_logic;

begin
    -- i/o assigns
    m_axis_instr_tvalid <= instr_m_tvalid;
    instr_m_tready      <= m_axis_instr_tready;
    m_axis_instr_tdata  <= decoded_instr_t_to_slv(instr_m_tdata);
    m_axis_instr_tuser  <= instr_m_tuser;

    jump_s_tvalid       <= s_axis_jump_tvalid;
    jump_s_tdata        <= s_axis_jump_tdata;

    m_axis_jump_tvalid  <= jump_m_tvalid;
    m_axis_jump_tdata   <= jump_m_tdata;

    read_ahead_tvalid   <= '1' when s_axis_instr_tvalid = '1' and s_axis_instr_tready = '1' else '0';
    read_ahead_tdata    <= s_axis_instr_tuser(31 downto 16) & s_axis_instr_tuser(47 downto 32);


    -- module axis_reg instantiation
    delayed_instr_data_reg_inst : axis_reg generic map (
        DATA_WIDTH              => DECODED_INSTR_T_WIDTH + USER_T_WIDTH
    ) port map (
        clk                     => clk,
        resetn                  => local_resetn,

        in_s_tvalid             => s_axis_instr_tvalid,
        in_s_tready             => s_axis_instr_tready,
        in_s_tdata              => s_axis_instr_payload,

        out_m_tvalid            => instr_s_tvalid,
        out_m_tready            => instr_s_tready,
        out_m_tdata             => instr_s_payload
    );

    -- module axis_reg instantiation
    bpu_item_reg_inst : axis_reg generic map (
        DATA_WIDTH              => BPU_ITEM_IDX_WIDTH + BPU_ITEM_CNT
    ) port map (
        clk                     => clk,
        resetn                  => local_resetn,

        in_s_tvalid             => read_ahead_tvalid,
        in_s_tready             => open,
        in_s_tdata              => bpu_item_rd_tdata,

        out_m_tvalid            => d_bpu_item_rd_tvalid,
        out_m_tready            => instr_s_tvalid and instr_s_tready,
        out_m_tdata             => d_bpu_item_rd_tdata
    );


    -- assigns
    local_resetn            <= '0' when resetn = '0' or jump_m_tvalid = '1' else '1';

    s_axis_instr_payload    <= s_axis_instr_tdata & s_axis_instr_tuser;
    instr_s_tdata           <= slv_to_decoded_instr_t(instr_s_payload(DECODED_INSTR_T_WIDTH+USER_T_WIDTH-1 downto USER_T_WIDTH));
    instr_s_tuser           <= instr_s_payload(USER_T_WIDTH-1 downto 0);

    bpu_item_rd_tdata       <= bpu_item_rd_hit & bpu_item_rd_hit_idx;
    d_bpu_item_rd_hit       <= d_bpu_item_rd_tdata(BPU_ITEM_CNT+BPU_ITEM_IDX_WIDTH-1 downto BPU_ITEM_IDX_WIDTH);
    d_bpu_item_rd_hit_idx   <= to_integer(unsigned(d_bpu_item_rd_tdata(BPU_ITEM_IDX_WIDTH-1 downto 0)));

    instr_s_tready          <= '1' when jump_s_tvalid = '0' and jump_m_tvalid = '0' and (instr_m_tvalid = '0' or (instr_m_tvalid = '1' and instr_m_tready = '1')) else '0';

    jump_pass               <= '1' when instr_s_tdata.op = BRANCH or instr_s_tdata.op = RET else '0';

    -- forwarding instruction
    process (clk) begin
        if rising_edge(clk) then
            -- resettable logic
            if resetn = '0' then
                instr_m_tvalid <= '0';
            else
                if (jump_s_tvalid = '1' and jump_s_tdata.mismatch = '1') then
                    instr_m_tvalid <= '0';
                elsif (instr_s_tvalid = '1' and instr_s_tready = '1') then
                    instr_m_tvalid <= '1';
                elsif (instr_m_tready = '1') then
                    instr_m_tvalid <= '0';
                end if;
            end if;

            --without reset
            if (instr_s_tvalid = '1' and instr_s_tready = '1') then
                if (d_bpu_item_rd_hit_any = '1' and
                    bpu_items(d_bpu_item_rd_hit_idx).saturated_cnt > 1 and
                    jump_pass = '1') then
                    instr_m_tdata.bpu_taken <= '1';
                else
                    instr_m_tdata.bpu_taken <= '0';
                end if;

                if (d_bpu_item_rd_hit_any = '1') then
                    instr_m_tdata.bpu_first <= '0';
                else
                    instr_m_tdata.bpu_first <= '1';
                end if;

                instr_m_tdata.bpu_taken_cs  <= bpu_items(d_bpu_item_rd_hit_idx).jump_cs;
                instr_m_tdata.bpu_taken_ip  <= bpu_items(d_bpu_item_rd_hit_idx).jump_ip;

                instr_m_tdata.op            <= instr_s_tdata.op;
                instr_m_tdata.code          <= instr_s_tdata.code;
                instr_m_tdata.w             <= instr_s_tdata.w;
                instr_m_tdata.dir           <= instr_s_tdata.dir;
                instr_m_tdata.ea            <= instr_s_tdata.ea;
                instr_m_tdata.dreg          <= instr_s_tdata.dreg;
                instr_m_tdata.dmask         <= instr_s_tdata.dmask;
                instr_m_tdata.sreg          <= instr_s_tdata.sreg;
                instr_m_tdata.smask         <= instr_s_tdata.smask;
                instr_m_tdata.data          <= instr_s_tdata.data;
                instr_m_tdata.disp          <= instr_s_tdata.disp;
                instr_m_tdata.fl            <= instr_s_tdata.fl;
                instr_m_tdata.data_ex       <= instr_s_tdata.data_ex;
                instr_m_tdata.wait_ax       <= instr_s_tdata.wait_ax;
                instr_m_tdata.wait_bx       <= instr_s_tdata.wait_bx;
                instr_m_tdata.wait_cx       <= instr_s_tdata.wait_cx;
                instr_m_tdata.wait_dx       <= instr_s_tdata.wait_dx;
                instr_m_tdata.wait_bp       <= instr_s_tdata.wait_bp;
                instr_m_tdata.wait_si       <= instr_s_tdata.wait_si;
                instr_m_tdata.wait_di       <= instr_s_tdata.wait_di;
                instr_m_tdata.wait_sp       <= instr_s_tdata.wait_sp;
                instr_m_tdata.wait_ds       <= instr_s_tdata.wait_ds;
                instr_m_tdata.wait_es       <= instr_s_tdata.wait_es;
                instr_m_tdata.wait_ss       <= instr_s_tdata.wait_ss;
                instr_m_tdata.wait_fl       <= instr_s_tdata.wait_fl;
                instr_m_tdata.lock_fl       <= instr_s_tdata.lock_fl;
                instr_m_tdata.lock_sreg     <= instr_s_tdata.lock_sreg;
                instr_m_tdata.lock_dreg     <= instr_s_tdata.lock_dreg;
                instr_m_tdata.lock_ax       <= instr_s_tdata.lock_ax;
                instr_m_tdata.lock_sp       <= instr_s_tdata.lock_sp;
                instr_m_tdata.lock_si       <= instr_s_tdata.lock_si;
                instr_m_tdata.lock_di       <= instr_s_tdata.lock_di;
                instr_m_tdata.lock_ds       <= instr_s_tdata.lock_ds;
                instr_m_tdata.lock_es       <= instr_s_tdata.lock_es;
                instr_m_tdata.lock_all      <= instr_s_tdata.lock_all;

                instr_m_tuser               <= instr_s_tuser;
            end if;
        end if;
    end process;

    -- driving jump
    jump_proc: process (clk) begin
        if rising_edge(clk) then
            -- resettable logic
            if resetn = '0' then
                jump_m_tvalid <= '0';
            else
                if ((jump_s_tvalid = '1' and jump_s_tdata.mismatch = '1') or
                    (instr_s_tvalid = '1' and instr_s_tready = '1' and instr_s_tdata.op = JMPU  and instr_s_tdata.code(3) = '0') or
                    (instr_s_tvalid = '1' and instr_s_tready = '1' and instr_s_tdata.op = JCALL and instr_s_tdata.code(3) = '0') or
                    (instr_s_tvalid = '1' and instr_s_tready = '1' and d_bpu_item_rd_hit_any = '1' and bpu_items(d_bpu_item_rd_hit_idx).saturated_cnt > 1 and jump_pass = '1'))
                then
                    jump_m_tvalid <= '1';
                else
                    jump_m_tvalid <= '0';
                end if;
            end if;

            -- without reset
            if (jump_s_tvalid = '1' and jump_s_tdata.mismatch = '1') then
                jump_m_tdata(31 downto 16) <= jump_s_tdata.jump_cs;
                jump_m_tdata(15 downto 0)  <= jump_s_tdata.jump_ip;
            elsif (instr_s_tvalid = '1' and instr_s_tready = '1' and (instr_s_tdata.op = JMPU or instr_s_tdata.op = JCALL)) then
                if (instr_s_tdata.code = CALL_PTR16_16) then
                    jump_m_tdata(31 downto 16) <= instr_s_tdata.data;
                    jump_m_tdata(15 downto 0)  <= instr_s_tdata.disp;
                else
                    jump_m_tdata(31 downto 16) <= instr_s_tuser(31 downto 16);
                    jump_m_tdata(15 downto 0)  <= std_logic_vector(unsigned(instr_s_tuser(15 downto 0)) + unsigned(instr_s_tdata.disp));
                end if;
            elsif (instr_s_tvalid = '1' and instr_s_tready = '1') then
                jump_m_tdata(31 downto 16) <= bpu_items(d_bpu_item_rd_hit_idx).jump_cs;
                jump_m_tdata(15 downto 0)  <= bpu_items(d_bpu_item_rd_hit_idx).jump_ip;
            end if;
        end if;
    end process;

    bpu_item_wr_hit_gen : for i in 0 to BPU_ITEM_CNT-1 generate

        bpu_item_wr_hit(i) <= '1' when (bpu_items(i).valid = '1' and
            bpu_items(i).inst_cs = jump_s_tdata.inst_cs and
            bpu_items(i).inst_ip = jump_s_tdata.inst_ip)
        else '0';

    end generate;

    bpu_item_rd_hit_gen : for i in 0 to BPU_ITEM_CNT-1 generate

        bpu_item_rd_hit(i) <= '1' when (bpu_items(i).valid = '1' and
            bpu_items(i).inst_cs = read_ahead_tdata(31 downto 16) and
            bpu_items(i).inst_ip = read_ahead_tdata(15 downto 0))
        else '0';

    end generate;

    bpu_item_rd_hit_pos(0) <= std_logic_vector(to_unsigned(0, BPU_ITEM_IDX_WIDTH));
    bpu_item_rd_hit_pos_gen : for i in 1 to BPU_ITEM_CNT-1 generate

        bpu_item_rd_hit_pos(i) <= std_logic_vector(to_unsigned(i, BPU_ITEM_IDX_WIDTH)) when bpu_item_rd_hit(i) = '1'
            else std_logic_vector(to_unsigned(0, BPU_ITEM_IDX_WIDTH));

    end generate;

    bpu_item_rd_hit_idx <= bpu_item_rd_hit_pos(0) or bpu_item_rd_hit_pos(1) or
        bpu_item_rd_hit_pos(2) or bpu_item_rd_hit_pos(3) or
        bpu_item_rd_hit_pos(4) or bpu_item_rd_hit_pos(5) or
        bpu_item_rd_hit_pos(6) or bpu_item_rd_hit_pos(7);

    bpu_item_wr_hit_any <= '1' when bpu_item_wr_hit /= "00000000" else '0';

    d_bpu_item_rd_hit_any <= '1' when d_bpu_item_rd_hit /= "00000000" else '0';

    process (clk) begin
        if rising_edge(clk) then
            -- Resettable logic
            if (resetn = '0') then
                d_jump_s_tvalid       <= '0';
                d_bpu_item_wr_hit     <= (others => '0');
                d_bpu_item_wr_hit_any <= '0';
            else
                d_jump_s_tvalid       <= jump_s_tvalid;
                d_bpu_item_wr_hit     <= bpu_item_wr_hit;
                d_bpu_item_wr_hit_any <= bpu_item_wr_hit_any;
            end if;
            -- Without reset
            d_jump_s_tdata <= jump_s_tdata;
        end if;
    end process;

    process (clk) begin
        if rising_edge(clk) then
            -- Resettable logic
            if resetn = '0' then
                for i in 0 to BPU_ITEM_CNT-1 loop
                    bpu_items(i).valid <= '0';
                end loop;
            else

                for i in 0 to BPU_ITEM_CNT-1 loop
                    if (d_jump_s_tvalid = '1' and d_jump_s_tdata.bypass = '0' and ((d_bpu_item_wr_hit(i) = '1') or (d_bpu_item_wr_hit_any = '0' and i = next_free_bpu_item_idx))) then
                        bpu_items(i).valid <= '1';
                    end if;
                end loop;

            end if;

            -- Without reset
            for i in 0 to BPU_ITEM_CNT-1 loop
                if (d_jump_s_tvalid = '1' and d_jump_s_tdata.bypass = '0' and ((d_bpu_item_wr_hit(i) = '1') or (d_bpu_item_wr_hit_any = '0' and i = next_free_bpu_item_idx))) then
                    bpu_items(i).inst_cs <= d_jump_s_tdata.inst_cs;
                    bpu_items(i).inst_ip <= d_jump_s_tdata.inst_ip;

                    if (d_jump_s_tdata.taken = '1') then
                        bpu_items(i).jump_cs <= d_jump_s_tdata.jump_cs;
                        bpu_items(i).jump_ip <= d_jump_s_tdata.jump_ip;
                    end if;

                    if (d_jump_s_tdata.first = '1') then
                        if (d_jump_s_tdata.taken = '1') then
                            bpu_items(i).saturated_cnt <= 1;
                        else
                            bpu_items(i).saturated_cnt <= 0;
                        end if;
                    else
                        if (d_jump_s_tdata.taken = '1' and bpu_items(i).saturated_cnt < 3) then
                            bpu_items(i).saturated_cnt <= bpu_items(i).saturated_cnt + 1;
                        elsif (d_jump_s_tdata.taken = '0' and bpu_items(i).saturated_cnt > 0) then
                            bpu_items(i).saturated_cnt <= bpu_items(i).saturated_cnt - 1;
                        end if;
                    end if;

                end if;
            end loop;

        end if;

    end process;

    process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                next_free_bpu_item_idx <= 0;
            else
                if (d_jump_s_tvalid = '1' and d_jump_s_tdata.bypass = '0' and d_bpu_item_wr_hit_any = '0') then
                    next_free_bpu_item_idx <= (next_free_bpu_item_idx + 1) mod BPU_ITEM_CNT;
                end if;
            end if;
        end if;
    end process;

end architecture;
