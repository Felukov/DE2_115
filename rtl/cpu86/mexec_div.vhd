library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.cpu86_types.all;

entity mexec_div is
    port (
        clk             : in std_logic;
        resetn          : in std_logic;

        req_s_tvalid    : in std_logic;
        req_s_tdata     : in div_req_t;

        res_m_tvalid    : out std_logic;
        res_m_tdata     : out div_res_t;
        res_m_tuser     : out std_logic_vector(15 downto 0)
    );
end entity mexec_div;

architecture rtl of mexec_div is

    constant USER_WIDTH         : natural := 91;

    constant DIV_USER_T_SIGN_D  : natural  := 90;
    constant DIV_USER_T_SIGN_N  : natural  := 89;
    constant DIV_USER_T_W       : natural  := 88;
    subtype DIV_USER_T_DVAL     is natural range 87 downto 72;
    subtype DIV_USER_T_CODE     is natural range 71 downto 68;
    subtype DIV_USER_T_DREG     is natural range 67 downto 64;
    subtype DIV_USER_T_SS       is natural range 63 downto 48;
    subtype DIV_USER_T_IP       is natural range 47 downto 32;
    subtype DIV_USER_T_CS       is natural range 31 downto 16;
    subtype DIV_USER_T_IP_NEXT  is natural range 15 downto 0;

    component axis_div_u is
        generic (
            MAX_WIDTH           : natural := 32;
            USER_WIDTH          : natural := 32
        );
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            div_s_tvalid        : in std_logic;
            div_s_tready        : out std_logic;
            div_s_tdata         : in std_logic_vector(2*MAX_WIDTH-1 downto 0);
            div_s_tuser         : in std_logic_vector(USER_WIDTH-1 downto 0);
            div_s_tsize         : in std_logic_vector(7 downto 0);

            div_m_tvalid        : out std_logic;
            div_m_tready        : in std_logic;
            div_m_tdata         : out std_logic_vector(2*MAX_WIDTH-1 downto 0);
            div_m_tuser         : out std_logic_vector(USER_WIDTH-1 downto 0)
        );
    end component;

    signal div_s_tvalid         : std_logic;
    signal div_s_tready         : std_logic;
    signal div_s_tdata          : std_logic_vector(63 downto 0);
    signal div_s_tuser          : std_logic_vector(USER_WIDTH-1 downto 0);
    signal div_s_tsize          : std_logic_vector(7 downto 0);

    signal div_m_tvalid         : std_logic;
    signal div_m_tdata          : std_logic_vector(63 downto 0);
    signal div_m_tuser          : std_logic_vector(USER_WIDTH-1 downto 0);

    signal div_m_tuser_dval     : std_logic_vector(15 downto 0);

    signal flags_zf             : std_logic;
    signal flags_pf             : std_logic;
    signal flags_sf             : std_logic;

begin

    div_m_tuser_dval <= div_m_tuser(DIV_USER_T_DVAL);

    res_m_tuser(FLAG_15) <= '0';
    res_m_tuser(FLAG_14) <= '0';
    res_m_tuser(FLAG_13) <= '0';
    res_m_tuser(FLAG_12) <= '0';
    res_m_tuser(FLAG_OF) <= '0';
    res_m_tuser(FLAG_DF) <= '0';
    res_m_tuser(FLAG_IF) <= '0';
    res_m_tuser(FLAG_TF) <= '0';
    res_m_tuser(FLAG_SF) <= flags_sf;
    res_m_tuser(FLAG_ZF) <= flags_zf;
    res_m_tuser(FLAG_05) <= '0';
    res_m_tuser(FLAG_AF) <= '0';
    res_m_tuser(FLAG_03) <= '0';
    res_m_tuser(FLAG_PF) <= flags_pf;
    res_m_tuser(FLAG_01) <= '0';
    res_m_tuser(FLAG_CF) <= '0';

    process (all) begin
        -- only for AAM instruction

        if res_m_tdata.rval(7 downto 0) = x"00" then
            flags_zf <= '1';
        else
            flags_zf <= '0';
        end if;

        flags_pf <= not (res_m_tdata.rval(7) xor res_m_tdata.rval(6) xor res_m_tdata.rval(5) xor res_m_tdata.rval(4) xor
                         res_m_tdata.rval(3) xor res_m_tdata.rval(2) xor res_m_tdata.rval(1) xor res_m_tdata.rval(0));

        flags_sf <= res_m_tdata.rval(7);

    end process;

    axis_div_u_inst: axis_div_u generic map (
        MAX_WIDTH       => 32,
        USER_WIDTH      => USER_WIDTH
    ) port map (
        clk             => clk,
        resetn          => resetn,

        div_s_tvalid    => div_s_tvalid,
        div_s_tready    => div_s_tready,
        div_s_tdata     => div_s_tdata,
        div_s_tuser     => div_s_tuser,
        div_s_tsize     => div_s_tsize,

        div_m_tvalid    => div_m_tvalid,
        div_m_tready    => '1',
        div_m_tdata     => div_m_tdata,
        div_m_tuser     => div_m_tuser
    );

    div_proc : process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                div_s_tvalid <= '0';
            else
                div_s_tvalid <= req_s_tvalid;
            end if;

            if req_s_tdata.w = '1' then
                div_s_tsize <= std_logic_vector(to_unsigned(32, 8));
            else
                div_s_tsize <= std_logic_vector(to_unsigned(16, 8));
            end if;

            if (req_s_tdata.code = DIVU_IDIV) then
                div_s_tdata(63 downto 32) <= std_logic_vector(abs(signed(req_s_tdata.nval)));
                div_s_tdata(31 downto 0) <= x"0000" & std_logic_vector(abs(signed(req_s_tdata.dval)));
            else
                div_s_tdata(63 downto 32) <= req_s_tdata.nval;
                div_s_tdata(31 downto 0) <= x"0000" & req_s_tdata.dval;
            end if;

            div_s_tuser(DIV_USER_T_DVAL) <= req_s_tdata.dval;
            div_s_tuser(DIV_USER_T_CODE) <= req_s_tdata.code;
            div_s_tuser(DIV_USER_T_W) <= req_s_tdata.w;
            div_s_tuser(DIV_USER_T_DREG) <= std_logic_vector(to_unsigned(reg_t'pos(req_s_tdata.dreg), 4));
            div_s_tuser(DIV_USER_T_SS) <= req_s_tdata.ss_val;
            div_s_tuser(DIV_USER_T_IP) <= req_s_tdata.cs_val;
            div_s_tuser(DIV_USER_T_CS) <= req_s_tdata.ip_val;
            div_s_tuser(DIV_USER_T_IP_NEXT) <= req_s_tdata.ip_next_val;

            if (req_s_tdata.code = DIVU_IDIV) then
                if (req_s_tdata.w = '1') then
                    div_s_tuser(DIV_USER_T_SIGN_N) <= req_s_tdata.nval(31);
                    div_s_tuser(DIV_USER_T_SIGN_D) <= req_s_tdata.dval(15);
                else
                    div_s_tuser(DIV_USER_T_SIGN_N) <= req_s_tdata.nval(15);
                    div_s_tuser(DIV_USER_T_SIGN_D) <= req_s_tdata.dval(7);
                end if;
            else
                div_s_tuser(DIV_USER_T_SIGN_D) <= '0';
                div_s_tuser(DIV_USER_T_SIGN_N) <= '0';
            end if;

        end if;
    end process;

    div_out_proc : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                res_m_tvalid <= '0';
            else
                res_m_tvalid <= div_m_tvalid;
            end if;

            if (div_m_tvalid = '1') then

                res_m_tdata.code <= div_m_tuser(DIV_USER_T_CODE);
                res_m_tdata.w <= div_m_tuser(DIV_USER_T_W);
                res_m_tdata.dreg <= reg_t'val(to_integer(unsigned(div_m_tuser(DIV_USER_T_DREG))));

                if (div_m_tuser(DIV_USER_T_SIGN_D) = '1' xor div_m_tuser(DIV_USER_T_SIGN_N) = '1') then
                    res_m_tdata.qval <= std_logic_vector(unsigned(-signed(div_m_tdata(47 downto 32))));
                else
                    res_m_tdata.qval <= div_m_tdata(47 downto 32);
                end if;

                if (div_m_tuser(DIV_USER_T_SIGN_N) = '1') then
                    res_m_tdata.rval <= std_logic_vector(unsigned(-signed(div_m_tdata(15 downto 0))));
                else
                    res_m_tdata.rval <= div_m_tdata(15 downto 0);
                end if;
                res_m_tdata.ss_val <= div_m_tuser(DIV_USER_T_SS);
                res_m_tdata.cs_val <= div_m_tuser(DIV_USER_T_IP);
                res_m_tdata.ip_val <= div_m_tuser(DIV_USER_T_CS);
                res_m_tdata.ip_next_val <= div_m_tuser(DIV_USER_T_IP_NEXT);

                if (div_m_tuser(DIV_USER_T_W) = '0') then

                    if (res_m_tdata.code = DIVU_IDIV) then

                        if div_m_tdata(43 downto 32) > x"07F" or div_m_tuser_dval(7 downto 0) = x"00" then
                            res_m_tdata.overflow <= '1';
                        else
                            res_m_tdata.overflow <= '0';
                        end if;

                    else

                        if div_m_tdata(43 downto 32) > x"0FF" or div_m_tuser_dval(7 downto 0) = x"00" then
                            res_m_tdata.overflow <= '1';
                        else
                            res_m_tdata.overflow <= '0';
                        end if;

                    end if;

                else

                    if (res_m_tdata.code = DIVU_IDIV) then

                        if div_m_tdata(51 downto 32) > x"07FFF" or div_m_tuser_dval(15 downto 0) = x"0000" then
                            res_m_tdata.overflow <= '1';
                        else
                            res_m_tdata.overflow <= '0';
                        end if;

                    else

                        if div_m_tdata(51 downto 32) > x"0FFFF" or div_m_tuser_dval(15 downto 0) = x"0000" then
                            res_m_tdata.overflow <= '1';
                        else
                            res_m_tdata.overflow <= '0';
                        end if;

                    end if;

                end if;

            end if;

        end if;
    end process;

end architecture;
