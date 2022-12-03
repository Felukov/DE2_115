library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity decoder_tb is
end entity decoder_tb;

architecture rtl of decoder_tb is

    -- Clock period definitions
    constant CLK_PERIOD         : time := 10 ns;
    constant MAX_BUF_SIZE       : integer := 1000;

    type test_cases_t is array (natural range<>) of string;
    type input_tdata_t is array (natural range<>) of std_logic_vector(7 downto 0);
    type input_tuser_t is array (natural range<>) of std_logic_vector(31 downto 0);
    type output_tuser_t is array (natural range<>) of std_logic_vector(31 downto 0);

    type line_parser_result_t is record
        input_bytes : input_tdata_t(0 to 5);
        len : natural;
    end record;

    type tb_data_t is record
        input_len : natural;
        input_tdata : input_tdata_t(0 to MAX_BUF_SIZE-1);
        input_tuser : input_tuser_t(0 to MAX_BUF_SIZE-1);

        output_len : natural;
        output_tuser : output_tuser_t(0 to MAX_BUF_SIZE-1);
    end record;

    constant test_cases : test_cases_t := (
        "03 C3                          ;     add AX, BX                                       ",
        "02 27                          ;     add AH, [BX]                                     ",
        "01 07                          ;     add [BX], AX                                     ",
        "03 D8                          ;     add BX, AX                                       ",
        "02 E7                          ;     add AH, BH                                       ",
        "02 FC                          ;     add BH, AH                                       ",
        "1E                             ; 10  push    ds                                       ",
        "1F                             ;     POP     DS      ;                                ",
        "3B D9                          ; 68  cmp     bx, cx                                   ",
        "50                             ; 12  push    ax                                       ",
        "50                             ; 63  push    ax                                       ",
        "50                             ; 74  PUSH    AX                                       ",
        "52                             ; 73  PUSH    DX                                       ",
        "58                             ;     POP     AX      ;                                ",
        "58                             ; 66  pop     ax                                       ",
        "59                             ;     POP     CX      ;                                ",
        "5B                             ;     POP     BX      ;                                ",
        "5F                             ;     POP     DI      ; re-store registers...          ",
        "7D 02                          ; 69  jge     compared                                 ",
        "87 D9                          ; 71  xchg    bx, cx                                   ",
        "89 0E C1 00                    ; 20  mov     num1, cx                                 ",
        "89 0E C3 00                    ; 24  mov     num2, cx                                 ",
        "89 0E C3 00                    ; 33  mov     num2, cx                                 ",
        "89 0E C3 00                    ; 43  mov     num2, cx                                 ",
        "89 0E C5 00                    ; 28  mov     num3, cx                                 ",
        "89 0E C5 00                    ; 38  mov     num3, cx                                 ",
        "89 1E C1 00                    ; 32  mov     num1, bx                                 ",
        "89 1E C1 00                    ; 42  mov     num1, bx                                 ",
        "89 1E C3 00                    ; 37  mov     num2, bx                                 ",
        "8B 0E C3 00                    ; 30  mov     cx, num2                                 ",
        "8B 0E C3 00                    ; 40  mov     cx, num2                                 ",
        "8B 0E C5 00                    ; 35  mov     cx, num3                                 ",
        "8B 1E C1 00                    ; 29  mov     bx, num1                                 ",
        "8B 1E C1 00                    ; 39  mov     bx, num1                                 ",
        "8B 1E C3 00                    ; 34  mov     bx, num2                                 ",
        "8E C0                          ; 15  mov     es, ax                                   ",
        "8E D8                          ; 07  mov     ds, ax                                   ",
        "8E D8                          ; 14  mov     ds, ax                                   ",
        "A1 C1 00                       ; 48  mov     ax, num1                                 ",
        "A1 C3 00                       ; 52  mov     ax, num2                                 ",
        "A1 C5 00                       ; 56  mov     ax, num3                                 ",
        "B4 00                          ; 03  mov     ah, 0                                    ",
        "B4 00                          ; 60  mov     ah, 0                                    ",
        "B4 09                          ; 64  mov     ah, 09h                                  ",
        "B8 00 00                       ; 11  mov     ax, 0                                    ",
        "B8 00 00                       ; 13  mov     ax, data                                 ",
        "B8 40 00                       ; 06  mov     ax, 0040h                                ",
        "BA 00 00                       ; 58  lea     dx, new_line                             ",
        "BA 02 01                       ; 01  mov     dx, msg                                  ",
        "BA 03 00                       ; 17  lea     dx, msg1                                 ",
        "BA 28 00                       ; 21  lea     dx, msg2                                 ",
        "BA 50 00                       ; 25  lea     dx, msg3                                 ",
        "BA 77 00                       ; 44  lea     dx, msg4                                 ",
        "BA A3 00                       ; 46  lea     dx, msg5                                 ",
        "BA AD 00                       ; 50  lea     dx, msg6                                 ",
        "BA B7 00                       ; 54  lea     dx, msg7                                 ",
        "C3                             ; 05  ret                                              ",
        "C3                             ; 67  ret                                              ",
        "C3                             ; 72  ret                                              ",
        "C7 06 72 00 00 00              ; 08  mov     w.[0072h], 0000h                         ",
        "CB                             ; 62  retf                                             ",
        "CD 16                          ; 04  int     16h                                      ",
        "CD 16                          ; 61  int     16h                                      ",
        "CD 21                          ; 02  int     21h                                      ",
        "CD 21                          ; 65  int     21h                                      ",
        "E8 05 00                       ; 59  call    puts                                     ",
        "E8 11 00                       ; 55  call    puts                                     ",
        "E8 1D 00                       ; 51  call    puts                                     ",
        "E8 29 00                       ; 47  call    puts                                     ",
        "E8 2F 00                       ; 45  call    puts                                     ",
        "E8 44 00                       ; 41  call    sort       ; exchange if bx<cx           ",
        "E8 57 00                       ; 36  call    sort       ; exchange if bx<cx           ",
        "E8 6A 00                       ; 31  call    sort       ; exchange if bx<cx           ",
        "E8 75 00                       ; 26  call    puts       ; display the message.        ",
        "E8 80 00                       ; 27  call    scan_num   ; input the number into cx.   ",
        "E8 82 00                       ; 22  call    puts       ; display the message.        ",
        "E8 8D 00                       ; 23  call    scan_num   ; input the number into cx.   ",
        "E8 8F 00                       ; 18  call    puts       ; display the message.        ",
        "E8 9A 00                       ; 19  call    scan_num   ; input the number into cx.   ",
        "E8 DA 00                       ; 57  call    print_num ; print ax.                    ",
        "E8 E6 00                       ; 53  call    print_num ; print ax.                    ",
        "E8 EA 01                       ; 16  call    clear_screen                             ",
        "E8 F2 00                       ; 49  call    print_num ; print ax.                    ",
        "EA 00 00 FF FF                 ; 09  jmp     0ffffh:0000h                             ",
        "EB 10                          ; 00  jmp start                                        ",
        "56                             ; 75  PUSH    SI                                       "
    );

    function parse_line(s : string) return line_parser_result_t is
        variable res : line_parser_result_t;
        variable char_cnt : natural;
        variable nibble : std_logic_vector(3 downto 0);
        variable is_digit : boolean;
    begin
        res.len := 0;
        char_cnt := 0;

        for i in s'range loop
            is_digit := true;

            case s(i) is
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

                when ';' => exit;
                when others => is_digit := false;
            end case;

            if (is_digit) then
                char_cnt := char_cnt + 1;

                if (char_cnt mod 2 = 0) then
                    res.input_bytes(res.len)(3 downto 0) := nibble;
                else
                    res.input_bytes(res.len)(7 downto 4) := nibble;
                end if;

                if (char_cnt mod 2 = 0) then
                    res.len := res.len + 1;
                end if;

            end if;

        end loop;

        return res;
    end function;

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
            instr_m_tdata       : out std_logic_vector(79 downto 0);
            instr_m_tuser       : out std_logic_vector(31 downto 0)

        );
    end component;

    signal tb_data              : tb_data_t;

    signal CLK                  : std_logic := '0';
    signal RESETN               : std_logic := '0';

    signal EVENT_DATA_READY     : std_logic := '0';

    signal u8_s_tvalid          : std_logic;
    signal u8_s_tready          : std_logic := '1';
    signal u8_s_tdata           : std_logic_vector(7 downto 0);
    signal u8_s_tuser           : std_logic_vector(31 downto 0);

    signal instr_m_tvalid       : std_logic;
    signal instr_m_tready       : std_logic;
    signal instr_m_tdata        : std_logic_vector(79 downto 0);
    signal instr_m_tuser        : std_logic_vector(31 downto 0);
    signal instr_m_tuser_tb     : std_logic_vector(31 downto 0);

begin

    uut : decoder port map (
        clk                 => clk,
        resetn              => resetn,

        u8_s_tvalid         => u8_s_tvalid,
        u8_s_tready         => u8_s_tready,
        u8_s_tdata          => u8_s_tdata,
        u8_s_tuser          => u8_s_tuser,

        instr_m_tvalid      => instr_m_tvalid,
        instr_m_tready      => instr_m_tready,
        instr_m_tdata       => instr_m_tdata,
        instr_m_tuser       => instr_m_tuser
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
        wait for 200 ns;
        RESETN <= '1';
        wait;
    end process;


    testbench_generation : process
        variable parser_res : line_parser_result_t;
        variable input_cnt : natural;
        variable output_cnt : natural;
    begin
        input_cnt := 0;
        output_cnt := 0;

        for i in test_cases'range loop
            parser_res := parse_line(test_cases(i));
            if (parser_res.len > 0) then
                for j in 0 to parser_res.len - 1 loop
                    tb_data.input_tdata(input_cnt) <= parser_res.input_bytes(j);
                    tb_data.input_tuser(input_cnt) <= std_logic_vector(to_unsigned(i, 32));
                    input_cnt := input_cnt + 1;
                end loop;
                tb_data.output_tuser(output_cnt) <= std_logic_vector(to_unsigned(i, 32));
                output_cnt := output_cnt + 1;
            end if;
        end loop;
        tb_data.input_len <= input_cnt;
        tb_data.output_len <= output_cnt;

        EVENT_DATA_READY <= '1';
        wait;
    end process;

    send_data: process
        variable seed1, seed2   : integer := 999;

        variable delay0, delay1 : integer := 0;
        variable u8_s_hs        : integer := 0;

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
            u8_s_tdata <= tb_data.input_tdata(u8_s_hs);
            u8_s_tuser <= tb_data.input_tuser(u8_s_hs);
            wait until rising_edge(CLK) and u8_s_tready = '1';
            if (u8_s_hs = tb_data.input_len-1) then
                exit;
            end if;
            u8_s_hs := u8_s_hs + 1;
        end loop;
        u8_s_tvalid <= '0';
        wait;

    end process;

    recieve_data : process
        variable u32_m_hs        : integer := 0;
    begin
        wait until rising_edge(CLK) and RESETN = '1';

        instr_m_tready <= '1';

        loop
            instr_m_tuser_tb <= tb_data.output_tuser(u32_m_hs);
            wait until rising_edge(CLK) and instr_m_tvalid = '1' and instr_m_tready = '1';
            if (instr_m_tuser /= instr_m_tuser_tb) then
                report "Output mismatch " & to_hstring(instr_m_tuser) severity error;
            end if;
            u32_m_hs := u32_m_hs + 1;
        end loop;

        wait;
    end process;

end architecture;
