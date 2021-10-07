library ieee;

use std.env.finish;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use ieee.std_logic_1164.all;
use std.textio.all;
use work.cpu86_types.all;

entity exec_bin is
end entity exec_bin;

architecture rtl of exec_bin is
    -- Clock period definitions
    constant CLK_PERIOD         : time := 10 ns;
    constant MAX_BUF_SIZE       : integer := 500;

    type input_tdata_t is array (natural range<>) of std_logic_vector(7 downto 0);
    type input_tuser_t is array (natural range<>) of std_logic_vector(31 downto 0);

    type input_stream_t is record
        len     : natural;
        data    : input_tdata_t(0 to MAX_BUF_SIZE-1);
        user    : input_tuser_t(0 to MAX_BUF_SIZE-1);
    end record;

    type dump_rec_t is record
        cs : std_logic_vector(15 downto 0);
        ip : std_logic_vector(15 downto 0);
        ds : std_logic_vector(15 downto 0);
        es : std_logic_vector(15 downto 0);
        ss : std_logic_vector(15 downto 0);
        ax : std_logic_vector(15 downto 0);
        bx : std_logic_vector(15 downto 0);
        cx : std_logic_vector(15 downto 0);
        dx : std_logic_vector(15 downto 0);
        bp : std_logic_vector(15 downto 0);
        di : std_logic_vector(15 downto 0);
        si : std_logic_vector(15 downto 0);
        sp : std_logic_vector(15 downto 0);
        fl : std_logic_vector(15 downto 0);
    end record;

    type dump_array_t is array (natural range<>) of dump_rec_t;

    type dump_stream_t is record
        len     : natural;
        data    : dump_array_t(0 to MAX_BUF_SIZE-1);
    end record;

    type memw_rec_t is record
        segm : std_logic_vector(15 downto 0);
        addr : std_logic_vector(15 downto 0);
        data : std_logic_vector(7 downto 0);
    end record;

    type memw_array_t is array (natural range<>) of memw_rec_t;

    type memw_stream_t is record
        len     : natural;
        data    : memw_array_t(0 to MAX_BUF_SIZE-1);
    end record;

    type test_rec_t is record
        name : string(1 to 255);
        input_stream : input_stream_t;
        dump_stream : dump_stream_t;
        memw_stream : memw_stream_t;
    end record;

    type test_array_t is array (natural range<>) of test_rec_t;

    signal tb_data              : test_array_t(0 to 50);

    component decoder is
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            u8_s_tvalid         : in std_logic;
            u8_s_tready         : out std_logic;
            u8_s_tdata          : in std_logic_vector(7 downto 0);
            u8_s_tuser          : in std_logic_vector(31 downto 0);

            instr_m_tvalid      : out std_logic;
            instr_m_tready      : in std_logic;
            instr_m_tdata       : out decoded_instr_t;
            instr_m_tuser       : out std_logic_vector(31 downto 0)
        );
    end component;

    component exec is
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            instr_s_tvalid      : in std_logic;
            instr_s_tready      : out std_logic;
            instr_s_tdata       : in decoded_instr_t;
            instr_s_tuser       : in std_logic_vector(31 downto 0);

            req_m_tvalid        : out std_logic;
            req_m_tdata         : out std_logic_vector(31 downto 0);

            mem_req_m_tvalid    : out std_logic;
            mem_req_m_tready    : in std_logic;
            mem_req_m_tdata     : out std_logic_vector(63 downto 0);

            mem_rd_s_tvalid     : in std_logic;
            mem_rd_s_tdata      : in std_logic_vector(31 downto 0)
        );
    end component exec;

    component sdram_ctrl is
        port (
            clk                 : in std_logic;
            reset_n             : in std_logic;

            az_addr             : in std_logic_vector(24 downto 0);
            az_be_n             : in std_logic_vector( 3 downto 0);
            az_cs               : in std_logic;
            az_data             : in std_logic_vector(31 downto 0);
            az_rd_n             : in std_logic;
            az_wr_n             : in std_logic;

            za_waitrequest      : out std_logic;
            za_valid            : out std_logic;
            za_data             : out std_logic_vector(31 downto 0);
            zs_addr             : out std_logic_vector(12 downto 0);
            zs_ba               : out std_logic_vector( 1 downto 0);
            zs_cas_n            : out std_logic;
            zs_cke              : out std_logic;
            zs_cs_n             : out std_logic;
            zs_dq               : inout std_logic_vector(31 downto 0);
            zs_dqm              : out std_logic_vector(3 downto 0);
            zs_ras_n            : out std_logic;
            zs_we_n             : out std_logic
        );
    end component;

    component sdram_test_model is
        port (
            clk                 : in std_logic;

            zs_addr             : in std_logic_vector(12 downto 0);
            zs_ba               : in std_logic_vector( 1 downto 0);
            zs_cas_n            : in std_logic;
            zs_cke              : in std_logic;
            zs_cs_n             : in std_logic;
            zs_dq               : inout std_logic_vector(31 downto 0);
            zs_dqm              : in std_logic_vector(3 downto 0);
            zs_ras_n            : in std_logic;
            zs_we_n             : in std_logic
        );
    end component;

    component axis_sdram is
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            cmd_s_tvalid        : in std_logic;
            cmd_s_tready        : out std_logic;
            cmd_s_tdata         : in std_logic_vector (63 downto 0);

            rd_m_tvalid         : out std_logic;
            rd_m_tdata          : out std_logic_vector(31 downto 0);

            DRAM_ADDR           : out std_logic_vector(12 downto 0);
            DRAM_BA             : out std_logic_vector(1 downto 0);
            DRAM_CAS_N          : out std_logic;
            DRAM_CKE            : out std_logic;
            DRAM_CS_N           : out std_logic;
            DRAM_DQ             : inout std_logic_vector(31 downto 0);
            DRAM_DQM            : out std_logic_vector(3 downto 0);
            DRAM_RAS_N          : out std_logic;
            DRAM_WE_N           : out std_logic
        );
    end component;

    signal CLK                  : std_logic := '0';
    signal RESETN               : std_logic := '0';
    signal EVENT_DATA_READY     : std_logic := '0';
    signal EVENT_TEST_DONE      : std_logic := '0';

    signal u8_s_tvalid          : std_logic;
    signal u8_s_tready          : std_logic := '1';
    signal u8_s_tdata           : std_logic_vector(7 downto 0);
    signal u8_s_tuser           : std_logic_vector(31 downto 0);

    signal instr_tvalid         : std_logic;
    signal instr_tready         : std_logic;
    signal instr_tdata          : decoded_instr_t;
    signal instr_tuser          : std_logic_vector(31 downto 0);

    signal decoder_resetn       : std_logic;

    signal req_tvalid           : std_logic;
    signal req_tdata            : std_logic_vector(31 downto 0);

    signal mem_req_m_tvalid     : std_logic;
    signal mem_req_m_tready     : std_logic;
    signal mem_req_m_tdata      : std_logic_vector(63 downto 0);

    signal mem_rd_s_tvalid      : std_logic;
    signal mem_rd_s_tdata       : std_logic_vector(31 downto 0);

    signal za_waitrequest       : std_logic;
    signal za_valid             : std_logic;
    signal za_data              : std_logic_vector(31 downto 0);
    signal zs_addr              : std_logic_vector(12 downto 0);
    signal zs_ba                : std_logic_vector( 1 downto 0);
    signal zs_cas_n             : std_logic;
    signal zs_cke               : std_logic;
    signal zs_cs_n              : std_logic;
    signal zs_dq                : std_logic_vector(31 downto 0);
    signal zs_dqm               : std_logic_vector(3 downto 0);
    signal zs_ras_n             : std_logic;
    signal zs_we_n              : std_logic;

begin

    decoder_inst : decoder port map (
        clk                 => clk,
        resetn              => decoder_resetn,

        u8_s_tvalid         => u8_s_tvalid,
        u8_s_tready         => u8_s_tready,
        u8_s_tdata          => u8_s_tdata,
        u8_s_tuser          => u8_s_tuser,

        instr_m_tvalid      => instr_tvalid,
        instr_m_tready      => instr_tready,
        instr_m_tdata       => instr_tdata,
        instr_m_tuser       => instr_tuser
    );

    uut : exec port map (
        clk                 => clk,
        resetn              => resetn,

        instr_s_tvalid      => instr_tvalid,
        instr_s_tready      => instr_tready,
        instr_s_tdata       => instr_tdata,
        instr_s_tuser       => instr_tuser,

        req_m_tvalid        => req_tvalid,
        req_m_tdata         => req_tdata,

        mem_req_m_tvalid    => mem_req_m_tvalid,
        mem_req_m_tready    => mem_req_m_tready,
        mem_req_m_tdata     => mem_req_m_tdata,

        mem_rd_s_tvalid     => mem_rd_s_tvalid,
        mem_rd_s_tdata      => mem_rd_s_tdata

    );

    axis_sdram_inst : axis_sdram port map (
        clk             => clk,
        resetn          => resetn,

        cmd_s_tvalid    => mem_req_m_tvalid,
        cmd_s_tready    => mem_req_m_tready,
        cmd_s_tdata     => mem_req_m_tdata,

        rd_m_tvalid     => mem_rd_s_tvalid,
        rd_m_tdata      => mem_rd_s_tdata,

        DRAM_ADDR       => zs_addr,
        DRAM_BA         => zs_ba,
        DRAM_CAS_N      => zs_cas_n,
        DRAM_CKE        => zs_cke,
        DRAM_CS_N       => zs_cs_n,
        DRAM_DQ         => zs_dq,
        DRAM_DQM        => zs_dqm,
        DRAM_RAS_N      => zs_ras_n,
        DRAM_WE_N       => zs_we_n
    );

    sdram_test_model_inst : sdram_test_model port map (
        clk             => CLK,

        zs_addr         => zs_addr,
        zs_ba           => zs_ba,
        zs_cas_n        => zs_cas_n,
        zs_cke          => zs_cke,
        zs_cs_n         => zs_cs_n,
        zs_dq           => zs_dq,
        zs_dqm          => zs_dqm,
        zs_ras_n        => zs_ras_n,
        zs_we_n         => zs_we_n
    );

    -- Clock process
    clk_process : process begin
    	CLK <= '0';
    	wait for CLK_PERIOD/2;
    	CLK <= '1';
    	wait for CLK_PERIOD/2;
    end process;

    -- Reset process
    reset_process : process begin
        RESETN <= '0';
        wait for 100 ns;
        RESETN <= '1';
        wait;
    end process;

    decoder_resetn <= '0' when RESETN = '0' or req_tvalid = '1' else '1';

    termination_proc : process
    begin

        -- Replace this line with your testbench logic
        wait for 1000 ns;

        --report "Timeout";
        --finish;

    end process;

    read_test_list_proc: process is
        type chfile_t is file of character;
        variable test_id : natural;

        function chr(ch:character) return std_logic_vector is
            variable nibble : std_logic_vector(3 downto 0);
        begin
            case ch is
                when '0' => nibble := x"0";
                when '1' => nibble := x"1";
                when '2' => nibble := x"2";
                when '3' => nibble := x"3";
                when '4' => nibble := x"4";
                when '5' => nibble := x"5";
                when '6' => nibble := x"6";
                when '7' => nibble := x"7";
                when '8' => nibble := x"8";
                when '9' => nibble := x"9";
                when 'A' => nibble := x"A";
                when 'B' => nibble := x"B";
                when 'C' => nibble := x"C";
                when 'D' => nibble := x"D";
                when 'E' => nibble := x"E";
                when 'F' => nibble := x"F";
                when others => nibble := "UUUU";
            end case;
            return nibble;
        end function;

        procedure read_opcodes(filename : string) is
            file fd : chfile_t;
            variable b : character;
            variable i : integer;
        begin
            file_open(fd, filename, read_mode);

            i := 0;

            while not endfile(fd) loop
                read(fd, b);
                tb_data(test_id).input_stream.data(i) <= std_logic_vector(to_unsigned(character'pos(b), 8));
                tb_data(test_id).input_stream.user(i) <= std_logic_vector(to_unsigned(i, 32));
                i := i + 1;
            end loop;
            tb_data(test_id).input_stream.len <= i;

            file_close(fd);
        end procedure;

        procedure read_memw(filename : string) is
            file fd : chfile_t;
            variable b0, b1, b2, b3, eol : character;
            variable i : integer;
        begin
            file_open(fd, filename, read_mode);

            i := 0;
            while not endfile(fd) loop
                read(fd, b0); read(fd, b1); read(fd, b2); read(fd, b3);
                tb_data(test_id).memw_stream.data(i).segm <= chr(b0) & chr(b1) & chr(b2) & chr(b3);
                read(fd, b0); read(fd, b1); read(fd, b2); read(fd, b3);
                tb_data(test_id).memw_stream.data(i).addr <= chr(b0) & chr(b1) & chr(b2) & chr(b3);
                read(fd, b0); read(fd, b1);
                tb_data(test_id).memw_stream.data(i).data <= chr(b0) & chr(b1);
                read(fd, eol); --#10
                i := i + 1;
            end loop;
            tb_data(test_id).memw_stream.len <= i;

            file_close(fd);
        end procedure;

        procedure read_dump(filename : string) is
            file fd : chfile_t;
            variable b0, b1, b2, b3, eol : character;
            variable i : integer;
        begin
            file_open(fd, filename, read_mode);

            i := 0;
            while not endfile(fd) loop
                read(fd, b0); read(fd, b1); read(fd, b2); read(fd, b3);
                tb_data(test_id).dump_stream.data(i).cs <= chr(b0) & chr(b1) & chr(b2) & chr(b3);
                read(fd, b0); read(fd, b1); read(fd, b2); read(fd, b3);
                tb_data(test_id).dump_stream.data(i).ip <= chr(b0) & chr(b1) & chr(b2) & chr(b3);
                read(fd, b0); read(fd, b1); read(fd, b2); read(fd, b3);
                tb_data(test_id).dump_stream.data(i).ds <= chr(b0) & chr(b1) & chr(b2) & chr(b3);
                read(fd, b0); read(fd, b1); read(fd, b2); read(fd, b3);
                tb_data(test_id).dump_stream.data(i).es <= chr(b0) & chr(b1) & chr(b2) & chr(b3);
                read(fd, b0); read(fd, b1); read(fd, b2); read(fd, b3);
                tb_data(test_id).dump_stream.data(i).ss <= chr(b0) & chr(b1) & chr(b2) & chr(b3);
                read(fd, b0); read(fd, b1); read(fd, b2); read(fd, b3);
                tb_data(test_id).dump_stream.data(i).ax <= chr(b0) & chr(b1) & chr(b2) & chr(b3);
                read(fd, b0); read(fd, b1); read(fd, b2); read(fd, b3);
                tb_data(test_id).dump_stream.data(i).bx <= chr(b0) & chr(b1) & chr(b2) & chr(b3);
                read(fd, b0); read(fd, b1); read(fd, b2); read(fd, b3);
                tb_data(test_id).dump_stream.data(i).dx <= chr(b0) & chr(b1) & chr(b2) & chr(b3);
                read(fd, b0); read(fd, b1); read(fd, b2); read(fd, b3);
                tb_data(test_id).dump_stream.data(i).cx <= chr(b0) & chr(b1) & chr(b2) & chr(b3);
                read(fd, b0); read(fd, b1); read(fd, b2); read(fd, b3);
                tb_data(test_id).dump_stream.data(i).bp <= chr(b0) & chr(b1) & chr(b2) & chr(b3);
                read(fd, b0); read(fd, b1); read(fd, b2); read(fd, b3);
                tb_data(test_id).dump_stream.data(i).di <= chr(b0) & chr(b1) & chr(b2) & chr(b3);
                read(fd, b0); read(fd, b1); read(fd, b2); read(fd, b3);
                tb_data(test_id).dump_stream.data(i).si <= chr(b0) & chr(b1) & chr(b2) & chr(b3);
                read(fd, b0); read(fd, b1); read(fd, b2); read(fd, b3);
                tb_data(test_id).dump_stream.data(i).sp <= chr(b0) & chr(b1) & chr(b2) & chr(b3);
                read(fd, b0); read(fd, b1); read(fd, b2); read(fd, b3);
                tb_data(test_id).dump_stream.data(i).fl <= chr(b0) & chr(b1) & chr(b2) & chr(b3);

                read(fd, eol); --#10
                i := i + 1;
            end loop;
            tb_data(test_id).dump_stream.len <= i;

            file_close(fd);
        end procedure;

        function change_filename (filename : string; d : string) return string is
            variable s : string(1 to 255);
            variable di : integer := 1;
        begin
            s := (others => ' ');
            for i in s'range loop
                if (filename(i) = '.') then
                    exit;
                end if;
                s(i) := filename(i);
                di := di + 1;
            end loop;

            for i in d'range loop
                s(di) := d(i);
                di := di + 1;
            end loop;

            return s;
        end function;

        procedure read_test_list is
            file fd : chfile_t;
            variable filename : string(1 to 255);
            variable ch : character;
            variable i : integer;
            variable j : integer;
        begin
            test_id := 0;

            file_open(fd, "./sim_data/test_list.txt", read_mode);
            filename := (others => ' ');
            i := 0; j := 1;
            while not endfile(fd) loop
                read(fd, ch);
                if (character'pos(ch) = 10) then
                    j := 1;
                    i := i + 1;

                    tb_data(test_id).name <= filename;

                    report "Loading " & filename;
                    read_opcodes(filename);

                    report "Loading " & change_filename(filename, "_memw.txt");
                    read_memw(change_filename(filename, "_memw.txt"));

                    report "Loading " & change_filename(filename, "_dump.txt");
                    read_dump(change_filename(filename, "_dump.txt"));

                    test_id := test_id + 1;
                    filename := (others => ' ');
                elsif (character'pos(ch) = 13) then
                    null;
                else
                    filename(j) := ch;
                    j := j + 1;
                end if;
            end loop;
            file_close(fd);

        end procedure;

    begin
        read_test_list;

        EVENT_DATA_READY <= '1';

        wait;
    end process;

    send_data: process
        variable seed1, seed2   : integer := 999;

        variable delay0, delay1 : integer := 0;
        variable u8_s_hs        : integer := 0;

        variable active_test_id : integer := 0;

        impure function rand_int(min_val, max_val : integer) return integer is
            variable r : real;
        begin
            uniform(seed1, seed2, r);
            return integer(
            round(r * real(max_val - min_val + 1) + real(min_val) - 0.5));
        end function;

    begin
        u8_s_hs := 0;
        u8_s_tvalid <= '0';
        wait until rising_edge(EVENT_DATA_READY);
        wait until rising_edge(CLK) and RESETN = '1';

        loop
            --delay0 := rand_int(0, 5);
            --delay1 := rand_int(0, 1);
            if (delay0 > 0 and delay1 > 0) then
                u8_s_tvalid <= '0';
                for i in 0 to delay0-1 loop
                    wait until rising_edge(CLK);
                end loop;
            end if;
            u8_s_tvalid <= '1';
            u8_s_tdata <= tb_data(active_test_id).input_stream.data(u8_s_hs);
            u8_s_tuser <= tb_data(active_test_id).input_stream.user(u8_s_hs);
            wait until rising_edge(CLK);
            if (req_tvalid = '1') then
                u8_s_hs := 0;
                loop
                    if (req_tdata = tb_data(active_test_id).input_stream.user(u8_s_hs)) then
                        exit;
                    else
                        u8_s_hs := u8_s_hs + 1;
                    end if;
                end loop;
                u8_s_tvalid <= '0';
                for i in 0 to 5 loop
                    wait until rising_edge(CLK);
                end loop;
            elsif (u8_s_tready = '1') then
                if (u8_s_hs = tb_data(active_test_id).input_stream.len-1) then
                    wait until rising_edge(CLK) and EVENT_TEST_DONE = '1';
                    exit;
                end if;
                u8_s_hs := u8_s_hs + 1;
            end if;
        end loop;
        u8_s_tvalid <= '0';
        wait;

    end process;

    snoop_memw_proc : process
        type word_t is array (0 to 3) of std_logic_vector(7 downto 0);
        variable active_test_id : integer := 0;
        variable memw_hs_cnt : integer := 0;
        variable hw_req_taddr   : std_logic_vector(24 downto 0);
        variable hw_req_tcmd    : std_logic;
        variable hw_req_tmask   : std_logic_vector(3 downto 0);
        variable hw_req_tdata   : std_logic_vector(31 downto 0);

        variable hw_data_bytes  : word_t;

        variable tb_req_taddr   : std_logic_vector(24 downto 0);
        variable tb_req_tdata   : std_logic_vector(7 downto 0);

        variable tb_req_segm    : integer;
        variable tb_req_addr    : integer;
        variable tb_req_data    : std_logic_vector(7 downto 0);
    begin
        wait until rising_edge(CLK) and mem_req_m_tvalid = '1' and mem_req_m_tready = '1';

        hw_req_tdata := mem_req_m_tdata(31 downto 0);
        hw_req_taddr := mem_req_m_tdata(56 downto 32);
        hw_req_tcmd := mem_req_m_tdata(57);
        hw_req_tmask := mem_req_m_tdata(61 downto 58);

        hw_data_bytes(0) := hw_req_tdata(31 downto 24);
        hw_data_bytes(1) := hw_req_tdata(23 downto 16);
        hw_data_bytes(2) := hw_req_tdata(15 downto 8);
        hw_data_bytes(3) := hw_req_tdata(7 downto 0);

        if (hw_req_tcmd = '1') then
            for i in 0 to 3 loop
                tb_req_segm := to_integer(unsigned(tb_data(active_test_id).memw_stream.data(memw_hs_cnt).segm));
                tb_req_addr := to_integer(unsigned(tb_data(active_test_id).memw_stream.data(memw_hs_cnt).addr));
                tb_req_data := tb_data(active_test_id).memw_stream.data(memw_hs_cnt).data;

                tb_req_taddr := std_logic_vector(to_unsigned((tb_req_segm * 16 + tb_req_addr)/4 , 25));
                if (hw_req_tmask(3-i) = '0') then
                    if (hw_req_taddr /= tb_req_taddr) then
                        report "Test: " & to_string(active_test_id) & "; HS: " & to_string(memw_hs_cnt) &
                            "; Incorrect memory address. Expected: " & to_hstring(tb_req_taddr) & " / " & to_hstring(tb_req_data) &
                            ". Recieved: " & to_hstring(hw_req_taddr) & " / " & to_hstring(hw_req_tdata) & "|" & to_string(hw_req_tmask);
                    end if;

                    if (hw_data_bytes(i) /= tb_req_data) then
                        report "Test: " & to_string(active_test_id) & "; HS: " & to_string(memw_hs_cnt) &
                            "; Incorrect data. Expected: " & to_hstring(tb_req_taddr) & " / " & to_hstring(tb_req_data) &
                            ". Recieved: " & to_hstring(hw_req_taddr) & " / " & to_hstring(hw_req_tdata) & "|" & to_string(hw_req_tmask) & " / " & to_hstring(hw_data_bytes(i));
                    end if;

                    memw_hs_cnt := memw_hs_cnt + 1;
                end if;
            end loop;

            if (memw_hs_cnt >= tb_data(active_test_id).memw_stream.len) then
                report "Unexpected memory write request. Test: " & to_string(active_test_id);
            end if;
        end if;

    end process;

end architecture;
