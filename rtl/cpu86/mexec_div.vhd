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
        res_m_tdata     : out div_res_t
    );
end entity mexec_div;

architecture rtl of mexec_div is

    constant USER_WIDTH         : natural := 91;

    constant DIV_USER_T_W       : natural  := 90;
    subtype DIV_USER_T_DVAL     is natural range 89 downto 74;
    subtype DIV_USER_T_CODE     is natural range 73 downto 70;
    subtype DIV_USER_T_DREG     is natural range 69 downto 66;
    subtype DIV_USER_T_DMASK    is natural range 65 downto 64;
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

    signal div_m_tvalid         : std_logic;
    signal div_m_tdata          : std_logic_vector(63 downto 0);
    signal div_m_tuser          : std_logic_vector(USER_WIDTH-1 downto 0);

begin

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

            div_s_tdata(63 downto 32) <= req_s_tdata.nval;
            div_s_tdata(31 downto 0) <= x"0000" & req_s_tdata.dval;

            div_s_tuser(DIV_USER_T_DVAL) <= req_s_tdata.dval;
            div_s_tuser(DIV_USER_T_CODE) <= req_s_tdata.code;
            div_s_tuser(DIV_USER_T_W) <= req_s_tdata.w;
            div_s_tuser(DIV_USER_T_DREG) <= std_logic_vector(to_unsigned(reg_t'pos(req_s_tdata.dreg), 4));
            div_s_tuser(DIV_USER_T_DMASK) <= req_s_tdata.dmask;
            div_s_tuser(DIV_USER_T_SS) <= req_s_tdata.ss_val;
            div_s_tuser(DIV_USER_T_IP) <= req_s_tdata.cs_val;
            div_s_tuser(DIV_USER_T_CS) <= req_s_tdata.ip_val;
            div_s_tuser(DIV_USER_T_IP_NEXT) <= req_s_tdata.ip_next_val;

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
                res_m_tdata.dreg <= reg_t'val(to_integer(unsigned(div_m_tuser(5 downto 2))));
                res_m_tdata.dmask <= div_m_tuser(DIV_USER_T_DMASK);
                res_m_tdata.qval <= div_m_tdata(47 downto 32);
                res_m_tdata.rval <= div_m_tdata(15 downto 0);
                res_m_tdata.ss_val <= div_m_tuser(DIV_USER_T_SS);
                res_m_tdata.cs_val <= div_m_tuser(DIV_USER_T_IP);
                res_m_tdata.ip_val <= div_m_tuser(DIV_USER_T_CS);
                res_m_tdata.ip_next_val <= div_m_tuser(DIV_USER_T_IP_NEXT);

                if (div_m_tuser(DIV_USER_T_W) = '0') then
                    res_m_tdata.overflow <= '0';
                else

                    if (div_m_tdata(63 downto 32) > x"0000" & req_s_tdata.dval) then
                        res_m_tdata.overflow <= '1';
                    else
                        res_m_tdata.overflow <= '0';
                    end if;

                end if;

            end if;

        end if;
    end process;

end architecture;
