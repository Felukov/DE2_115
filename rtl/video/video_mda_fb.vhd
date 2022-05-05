library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity video_mda_fb is
    port (
        vid_clk             : in std_logic;
        vid_resetn          : in std_logic;

        s_axis_vid_tvalid   : in std_logic;
        s_axis_vid_tdata    : in std_logic_vector(31 downto 0);
        s_axis_vid_tuser    : in std_logic_vector(7 downto 0);

        m_axis_vid_tvalid   : out std_logic;
        m_axis_vid_tdata    : out std_logic_vector(31 downto 0);
        m_axis_vid_tuser    : out std_logic_vector(31 downto 0)
    );
end entity video_mda_fb;

architecture rtl of video_mda_fb is
    signal din_tvalid       : std_logic;
    signal din_en           : std_logic;
    signal din_x            : std_logic_vector(11 downto 0);
    signal din_y            : std_logic_vector(11 downto 0);
    signal dout_tvalid      : std_logic;
    signal dout_tdata       : std_logic_vector(31 downto 0);
    signal dout_tuser       : std_logic_vector(31 downto 0);
    signal dout_r           : std_logic_vector(7 downto 0);
    signal dout_g           : std_logic_vector(7 downto 0);
    signal dout_b           : std_logic_vector(7 downto 0);
    signal blank_mask       : std_logic_vector(7 downto 0);
    signal border           : std_logic;
begin
    -- i/o assigns
    din_tvalid          <= s_axis_vid_tvalid;
    din_en              <= s_axis_vid_tuser(0);
    din_x               <= s_axis_vid_tdata(11 downto 0);
    din_y               <= s_axis_vid_tdata(27 downto 16);

    m_axis_vid_tvalid   <= dout_tvalid;
    m_axis_vid_tdata    <= dout_tdata;
    m_axis_vid_tuser    <= dout_tuser;

    -- assigns
    dout_tdata(31 downto 24) <= (others => '0');
    dout_tdata(23 downto 16) <= dout_r;
    dout_tdata(15 downto  8) <= dout_g;
    dout_tdata( 7 downto  0) <= dout_b;

    process (vid_clk)
        function comb_and (a, b : std_logic_vector) return std_logic_vector is
            variable o : std_logic_vector(a'range);
        begin
            for i in o'range loop
                o := a and b;
            end loop;
            return o;
        end function;
    begin
        if rising_edge(vid_clk) then
            if vid_resetn = '0' then
                dout_tvalid <= '0';
                dout_r <= (others => '0');
                dout_g <= (others => '0');
                dout_b <= (others => '0');
                blank_mask <= (others => '0') ;
            else
                dout_tvalid <= din_tvalid;

                if (din_tvalid = '1' and din_en = '0') then
                    if (din_y = x"069") then
                        blank_mask <= (others => '1');
                    elsif (din_y = x"38F") then
                        blank_mask <= (others => '0');
                    end if;
                end if;

                if (din_tvalid = '1') then
                    if (din_x = x"000" or din_x = x"4FF" or din_y = x"070" or din_y=x"38F") then
                        dout_r <= x"FF";
                        dout_g <= x"FF";
                        dout_b <= x"FF";
                    else
                        dout_r <= x"00";
                        dout_g <= x"00";
                        dout_b <= x"FF";
                    end if;
                else
                    dout_r <= (others => '0');
                    dout_g <= (others => '0');
                    dout_b <= (others => '0');
                end if;

            end if;

            dout_tuser <= x"0" & din_y & x"0" & din_x;
        end if;
    end process;

end architecture;
