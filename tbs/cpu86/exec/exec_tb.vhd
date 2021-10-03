library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.cpu86_types.all;

entity exec_tb is
end entity exec_tb;

architecture rtl of exec_tb is

    -- Clock period definitions
    constant CLK_PERIOD         : time := 10 ns;
    constant MAX_BUF_SIZE       : integer := 2000;

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
        "F8                              ;      CLC                                            ",
        "F9                              ;      STC                                            ",
        "F8                              ;      CLC                                            ",

        "FA                              ;      CLI                                            ",
        "FB                              ;      STI                                            ",
        "FA                              ;      CLI                                            ",

        "FC                              ;      CLD                                            ",
        "FD                              ;      STD                                            ",
        "FC                              ;      CLD                                            ",

        "B8 00 10                        ;      MOV AX, 0x1000                                 ",
        "8E D8                           ;      MOV DS, AX                                     ",
        "B8 00 20                        ;      MOV AX, 0x2000                                 ",
        "8E C0                           ;      MOV ES, AX                                     ",
        "BF 00 00                        ;      MOV DI, 0                                      ",
        "BE 00 00                        ;      MOV SI, 0                                      ",
        "B9 04 00                        ;      MOV CX, 4                                      ",
        "FC                              ;      CLD                                            ",
        "F3 A5                           ;      REP MOVSW                                      ",
        "B9 00 00                        ;      MOV CX, 0                                      ",
        "F3 A5                           ;      REP MOVSW                                      ",
        "B9 01 00                        ;      MOV CX, 1                                      ",
        "F3 A5                           ;      REP MOVSW                                      ",
        "B9 01 00                        ;      MOV CX, 1                                      ",
        "A5                              ;      REP MOVSW                                      ",
        "BF 00 00                        ;      MOV DI, 0                                      ",
        "BE 00 00                        ;      MOV SI, 0                                      ",
        -- "B9 FF FF                        ;      MOV CX, 0xFFFF                                 ",
        -- "F3 A5                           ;      REP MOVSW                                      ",
        "B8 00 00                        ;      MOV AX, 0                                      ",
        "BB 00 00                        ;      MOV BX, 0                                      ",
        "B9 00 00                        ;      MOV CX, 0                                      ",
        "BA 00 00                        ;      MOV DX, 0                                      ",
        "BE 00 00                        ;      MOV SI, 0                                      ",
        "BD 00 00                        ;      MOV BP, 0                                      ",
        "BC FE FF                        ;      MOV SP, 0xFFFE                                 ",

        "B8 F1 FF                        ;      MOV AX, 0xFFF1                                 ",
        "8A CB                           ;      MOV CL, BL                                     " ,
        "8E D0                           ;      MOV SS, AX                                     ",
        "8C DB                           ;      MOV BX, DS                                     ",
        "B8 F2 FF                        ;      MOV AX, 0xFFF2                                 ",
        "8E D0                           ;      MOV SS, AX                                     ",
        "8C D3                           ;      MOV BX, SS                                     ",
        "B8 F2 FF                        ;      MOV AX, 0xFFF2                                 ",
        "8E C0                           ;      MOV ES, AX                                     ",
        "8C C1                           ;      MOV CX, ES                                     ",

        "B0 01                           ;      MOV AL, 1                                      ",
        "B4 01                           ;      MOV AH, 1                                      ",
        "B3 02                           ;      MOV BL, 2                                      ",
        "B7 02                           ;      MOV BH, 2                                      ",
        "B1 03                           ;      MOV CL, 3                                      ",
        "B5 03                           ;      MOV CH, 3                                      ",
        "B2 04                           ;      MOV DL, 4                                      ",
        "B6 04                           ;      MOV DH, 4                                      ",

        "8B C4                           ;     MOV AX, SP                                      ",
        "8B DC                           ;     MOV BX, SP                                      ",
        "8B CC                           ;     MOV CX, SP                                      ",
        "8B D4                           ;     MOV DX, SP                                      ",
        "8B F4                           ;     MOV SI, SP                                      ",
        "8B FE                           ;     MOV DI, SI                                      ",

        "B8 00 10                        ;      MOV AX, 0x1000                                 ",
        "8E D8                           ;      MOV DS, AX                                     ",
        "8E D0                           ;      MOV SS, AX                                     ",
        "BD 00 00                        ;      MOV BP, 0                                      ",

        "B8 01 FF                        ;      MOV AX, 0xFF01                                 ",
        "89 46 02                        ;      MOV [BP+2], AX                                 ",
        "8B 5E 02                        ;      MOV BX, [BP+2]                                 ",
        "BB 02 FF                        ;      MOV BX, 0xFF02                                 ",
        "89 5E 04                        ;      MOV [BP+4], BX                                 ",
        "8B 46 04                        ;      MOV AX, [BP+4]                                 ",
        "B9 03 FF                        ;      MOV CX, 0xFF03                                 ",
        "89 4E 07                        ;      MOV [BP+7], CX                                 ",
        "8B 56 07                        ;      MOV DX, [BP+7]                                 ",

        "B8 01 FF                        ;      MOV AX, 0xFF01                                 ",
        "89 46 02                        ;      MOV [BP+2], AX                                 ",
        "89 86 02 FF                     ;      MOV [BP+0xFF02], AX                            ",
        "89 86 F2 00                     ;      MOV [BP+0xF2], AX                              ",
        "8E 86 02 FF                     ;      MOV ES, [BP+0xFF02]                            ",
        "8E 86 F2 00                     ;      MOV ES, [BP+0xF2]                              ",
        "8E 46 02                        ;      MOV ES, [BP+2]                                 ",

        "B8 34 12                       ;       MOV AX, 0x1234                                 ",
        "A3 00 FF                       ;       MOV [0xFF00], AX                               ",
        "B8 00 00                       ;       MOV AX, 0                                      ",
        "A1 00 FF                       ;       MOV AX, [0xFF00]                               ",
        "B8 00 00                       ;       MOV AX, 0                                      ",
        "A0 00 FF                       ;       MOV AL, [0xFF00]                               ",
        "A0 01 FF                       ;       MOV AL, [0xFF01]                               ",

        "C6 46 02 01                    ;       MOV [BP+2], 0x1                                ",
        "C7 46 02 F1 1F                 ;       MOV [BP+2], 0x1ff1                             ",

        "B8 00 00                       ;       MOV AX, 0                                      ",
        "8E D0                          ;       MOV SS, AX                                     ",
        "BC FE FF                       ;       MOV SP, 0xFFFE                                 ",
        "B8 AA AA                       ;       MOV AX, 0xAAAA                                 ",
        "8E C0                          ;       MOV ES, AX                                     ",
        "06                             ;       PUSH ES                                        ",
        "B8 0A A0                       ;       MOV AX, 0xA00A                                 ",
        "8E C0                          ;       MOV ES, AX                                     ",
        "07                             ;       POP ES                                         ",
        "B8 AA AA                       ;       MOV AX, 0xAAAA                                 ",
        "8E D8                          ;       MOV DS, AX                                     ",
        "1E                             ;       PUSH DS                                        ",
        "B8 0A A0                       ;       MOV AX, 0xA00A                                 ",
        "8E D8                          ;       MOV DS, AX                                     ",
        "1F                             ;       POP DS                                         ",
        "0E                             ;       PUSH CS                                        ",
        "58                             ;       POP AX                                         ",
        "16                             ;       PUSH SS                                        ",
        "B8 DD DD                       ;       MOV AX, 0xDDDD                                 ",
        "8E D0                          ;       MOV SS, AX                                     ",
        "17                             ;       POP SS                                         ",

        "B8 00 00                       ;       MOV AX, 0                                      ",
        "8E D0                          ;       MOV SS, AX                                     ",
        "BC FE FF                       ;       MOV SP, 0xFFFE                                 ",
        "B8 33 33                       ;       MOV AX, 0x3333                                 ",
        "50                             ;       PUSH AX                                        ",
        "B8 00 00                       ;       MOV AX, 0                                      ",
        "5B                             ;       POP BX                                         ",
        "53                             ;       PUSH BX                                        ",
        "59                             ;       POP CX                                         ",
        "51                             ;       PUSH CX                                        ",
        "5A                             ;       POP DX                                         ",
        "52                             ;       PUSH DX                                        ",
        "5D                             ;       POP BP                                         ",
        "55                             ;       PUSH BP                                        ",
        "5F                             ;       POP DI                                         ",
        "57                             ;       PUSH DI                                        ",
        "5E                             ;       POP SI                                         ",
        "56                             ;       PUSH SI                                        ",
        "58                             ;       POP AX                                         ",

        "B8 11 11                       ;       MOV AX, 0x1111                                 ",
        "B9 22 22                       ;       MOV CX, 0x2222                                 ",
        "BA 33 33                       ;       MOV DX, 0x3333                                 ",
        "BB 44 44                       ;       MOV BX, 0x4444                                 ",
        "BD 55 55                       ;       MOV BP, 0x5555                                 ",
        "BE 66 66                       ;       MOV SI, 0x6666                                 ",
        "BF 77 77                       ;       MOV DI, 0x7777                                 ",

        "60                             ;       PUSHA                                          ",
        "61                             ;       POPA                                           ",

        "BC FF FF                       ;       MOV SP, 0xFFFF                                 ",
        "60                             ;       PUSHA                                          ",
        "61                             ;       POPA                                           ",

        "BC FE FF                       ;       MOV SP, 0xFFFE                                 ",
        "68 11 11                       ;       PUSH 0x1111                                    ",
        "58                             ;       POP AX                                         ",
        "6A F0                          ;       PUSH 0xF0                                      ",
        "5B                             ;       POP BX                                         ",

        "BC FE FF                       ;       MOV SP, 0xFFFE                                 ",
        "B8 00 10                       ;       MOV AX, 0x1000                                 ",
        "8E D8                          ;       MOV DS, AX                                     ",
        "BD 00 00                       ;       MOV BP, 0                                      ",
        "C7 46 02 CD AB                 ;       MOV [BP+2], 0xABCD                             ",
        "FF 76 02                       ;       PUSH [BP+2]                                    ",
        "8F 46 04                       ;       POP [BP+4]                                     ",
        "8B 46 04                       ;       MOV AX, [BP+4]                                 ",

        "F9                              ;      STC                                            ",
        "FB                              ;      STI                                            ",
        "9C                             ;       PUSHF                                          ",
        "9D                             ;       POPF                                           ",

        "B8 AA AA                        ;      MOV AX, 0xAAAA                                 ",
        "BB BB BB                        ;      MOV BX, 0xBBBB                                 ",
        "B9 CC CC                        ;      MOV CX, 0xCCCC                                 ",
        "BA DD DD                        ;      MOV DX, 0xDDDD                                 ",
        "BE EE EE                        ;      MOV SI, 0xEEEE                                 ",
        "BD FF FF                        ;      MOV BP, 0xFFFF                                 ",
        "BF 88 88                        ;      MOV DI, 0x8888                                 ",
        "BC FE FF                        ;      MOV SP, 0xFFFE                                 ",
        "40                              ;      INC AX                                         ",
        "43                              ;      INC BX                                         ",
        "41                              ;      INC CX                                         ",
        "42                              ;      INC DX                                         ",
        "45                              ;      INC BP                                         ",
        "44                              ;      INC SP                                         ",
        "46                              ;      INC SI                                         ",
        "47                              ;      INC DI                                         ",
        "48                              ;      DEC AX                                         ",
        "4B                              ;      DEC BX                                         ",
        "49                              ;      DEC CX                                         ",
        "4A                              ;      DEC DX                                         ",
        "4D                              ;      DEC BP                                         ",
        "4C                              ;      DEC SP                                         ",
        "4E                              ;      DEC SI                                         ",
        "4F                              ;      DEC DI                                         ",
        "FE C0                           ;      INC AL                                         ",
        "FE C4                           ;      INC AH                                         ",
        "FE C3                           ;      INC BL                                         ",
        "FE C7                           ;      INC BH                                         ",
        "FE C1                           ;      INC CL                                         ",
        "FE C5                           ;      INC CH                                         ",
        "FE C8                           ;      DEC AL                                         ",
        "FE CC                           ;      DEC AH                                         ",
        "FE CB                           ;      DEC BL                                         ",
        "FE CF                           ;      DEC BH                                         ",
        "FE C9                           ;      DEC CL                                         ",
        "FE CD                           ;      DEC CH                                         ",
        "B8 00 20                        ;      MOV AX, 0x2000                                 ",
        "8E D8                           ;      MOV DS, AX                                     ",
        "BD 00 00                        ;      MOV BP, 0                                      ",
        "B8 FF 00                        ;      MOV AX, 0xFF                                   ",
        "89 46 00                        ;      MOV [BP], AX                                   ",
        "FF 46 00                        ;      INC word [BP]                                  ",
        "FF 4E 00                        ;      DEC word [BP]                                  ",
        "8B 46 00                        ;      MOV AX, [BP]                                   ",
        "FE 46 00                        ;      INC [BP]                                       ",
        "FE 4E 00                        ;      DEC [BP]                                       ",
        "8B 46 00                        ;      MOV AX, [BP]                                   ",

        "B8 00 30                        ;      MOV AX, 0x3000                                 ",
        "8E D0                           ;      MOV SS, AX                                     ",
        "BD 00 00                        ;      MOV BP, 0                                      ",
        "B8 44 44                        ;      MOV AX, 0x4444                                 ",
        "C7 46 00 01 00                  ;      MOV word [BP], 0x0001                          ",
        "00 46 00                        ;      ADD [BP], AL                                   ",
        "8A 66 00                        ;      MOV AH, [BP]                                   ",

        "B8 55 55                        ;      MOV AX, 0x5555                                 ",
        "C7 46 00 01 00                  ;      MOV word [BP], 0x0001                          ",
        "01 46 00                        ;      ADD [BP], AX                                   ",
        "8B 5E 00                        ;      MOV BX, [BP]                                   ",

        "B8 55 55                        ;      MOV AX, 0x5555                                 ",
        "03 C0                           ;      ADD AX, AX                                     ",

        "B8 66 66                        ;      MOV AX, 0x6666                                 ",
        "C7 46 00 01 00                  ;      MOV word [BP], 0x0001                          ",
        "03 46 00                        ;      ADD AX, [BP]                                   ",
        "B8 77 77                        ;      MOV AX, 0x7777                                 ",
        "C7 46 00 01 00                  ;      MOV word [BP], 0x0001                          ",
        "02 46 00                        ;      ADD AL, [BP]                                   ",
        "B8 88 88                        ;      MOV AX, 0x8888                                 ",
        "05 02 00                        ;      ADD AX, 0x0002                                 ",
        "B8 99 99                        ;      MOV AX, 0x9999                                 ",
        "04 01                           ;      ADD AL, 0x01                                   ",

        "B8 FF 00                        ;      MOV AX, 0x00FF                                 ",
        "04 01                           ;      ADD AL, 1                                      ",

        "B8 0A 30                        ;      MOV AX, 0x300A                                 ",
        "8E D0                           ;      MOV SS, AX                                     ",
        "BD 00 00                        ;      MOV BP, 0                                      ",
        "B8 FF FF                        ;      MOV AX, 0xFFFF                                 ",
        "C7 46 00 AA 00                  ;      MOV word [BP], 0x00AA                          ",
        "20 46 00                        ;      AND [BP], AL                                   ",
        "8A 66 00                        ;      MOV AH, [BP]                                   ",
        "B8 A0 0A                        ;      MOV AX, 0x0AA0                                 ",
        "C7 46 00 BA AB                  ;      MOV word [BP], 0xABBA                          ",
        "21 46 00                        ;      AND [BP], AX                                   ",
        "8B 5E 00                        ;      MOV BX, [BP]                                   ",
        "B8 0A A0                        ;      MOV AX, 0xA00A                                 ",
        "C7 46 00 BA AB                  ;      MOV word [BP], 0xABBA                          ",
        "23 46 00                        ;      AND AX, [BP]                                   ",
        "B8 0C C0                        ;      MOV AX, 0xC00C                                 ",
        "C7 46 00 CA AC                  ;      MOV word [BP], 0xACCA                          ",
        "22 46 00                        ;      AND AL, [BP]                                   ",
        "B8 0B B0                        ;      MOV AX, 0xB00B                                 ",
        "BB AD BE                        ;      MOV BX, 0xBEAD                                 ",
        "23 C3                           ;      AND AX, BX                                     ",
        "B8 AD 0D                        ;      MOV AX, 0x0DAD                                 ",
        "25 AD 00                        ;      AND AX, 0x00AD                                 ",
        "B8 AD 0D                        ;      MOV AX, 0x0DAD                                 ",
        "24 00                           ;      AND AL, 0x00                                   ",

        "B8 0A 31                        ;      MOV AX, 0x310A                                 ",
        "8E D0                           ;      MOV SS, AX                                     ",
        "BD 00 00                        ;      MOV BP, 0                                      ",
        "B8 FF FF                        ;      MOV AX, 0xFFFF                                 ",
        "C7 46 00 AA 00                  ;      MOV word [BP], 0x00AA                          ",
        "08 46 00                        ;      OR [BP], AL                                    ",
        "8A 66 00                        ;      MOV AH, [BP]                                   ",
        "B8 A0 0A                        ;      MOV AX, 0x0AA0                                 ",
        "C7 46 00 BA AB                  ;      MOV word [BP], 0xABBA                          ",
        "09 46 00                        ;      OR [BP], AX                                    ",
        "8B 5E 00                        ;      MOV BX, [BP]                                   ",
        "B8 0A A0                        ;      MOV AX, 0xA00A                                 ",
        "C7 46 00 BA AB                  ;      MOV word [BP], 0xABBA                          ",
        "0B 46 00                        ;      OR AX, [BP]                                    ",
        "B8 0C C0                        ;      MOV AX, 0xC00C                                 ",
        "C7 46 00 CA AC                  ;      MOV word [BP], 0xACCA                          ",
        "0A 46 00                        ;      OR AL, [BP]                                    ",
        "B8 0B B0                        ;      MOV AX, 0xB00B                                 ",
        "BB AD BE                        ;      MOV BX, 0xBEAD                                 ",
        "0B C3                           ;      OR AX, BX                                      ",
        "B8 AD 0D                        ;      MOV AX, 0x0DAD                                 ",
        "0D AD 00                        ;      OR AX, 0x00AD                                  ",
        "B8 AD 0D                        ;      MOV AX, 0x0DAD                                 ",
        "0C 00                           ;      OR AL, 0x00                                    ",

        "B8 0A 32                        ;      MOV AX, 0x320A                                 ",
        "8E D0                           ;      MOV SS, AX                                     ",
        "BD 00 00                        ;      MOV BP, 0                                      ",
        "B8 FF FF                        ;      MOV AX, 0xFFFF                                 ",
        "C7 46 00 AA 00                  ;      MOV word [BP], 0x00AA                          ",
        "30 46 00                        ;      XOR [BP], AL                                   ",
        "8A 66 00                        ;      MOV AH, [BP]                                   ",
        "B8 A0 0A                        ;      MOV AX, 0x0AA0                                 ",
        "C7 46 00 BA AB                  ;      MOV word [BP], 0xABBA                          ",
        "31 46 00                        ;      XOR [BP], AX                                   ",
        "8B 5E 00                        ;      MOV BX, [BP]                                   ",
        "B8 0A A0                        ;      MOV AX, 0xA00A                                 ",
        "C7 46 00 BA AB                  ;      MOV word [BP], 0xABBA                          ",
        "33 46 00                        ;      XOR AX, [BP]                                   ",
        "B8 0C C0                        ;      MOV AX, 0xC00C                                 ",
        "C7 46 00 CA AC                  ;      MOV word [BP], 0xACCA                          ",
        "32 46 00                        ;      XOR AL, [BP]                                   ",
        "B8 0B B0                        ;      MOV AX, 0xB00B                                 ",
        "BB AD BE                        ;      MOV BX, 0xBEAD                                 ",
        "33 C3                           ;      XOR AX, BX                                     ",
        "B8 AD 0D                        ;      MOV AX, 0x0DAD                                 ",
        "35 AD 00                        ;      XOR AX, 0x00AD                                 ",
        "B8 AD 0D                        ;      MOV AX, 0x0DAD                                 ",
        "34 00                           ;      XOR AL, 0x00                                   ",

        "B8 0A 33                        ;      MOV AX, 0x330A                                 ",
        "8E D0                           ;      MOV SS, AX                                     ",
        "BD 00 00                        ;      MOV BP, 0                                      ",
        "B8 FE FF                        ;      MOV AX, 0xFFFE                                 ",
        "C7 46 00 01 00                  ;      MOV word [BP], 0x0001                          ",
        "10 46 00                        ;      ADC [BP], AL                                   ",
        "F9                              ;      STC                                            ",
        "BD 00 00                        ;      MOV BP, 0                                      ",
        "B8 FE FF                        ;      MOV AX, 0xFFFE                                 ",
        "C7 46 00 01 00                  ;      MOV word [BP], 0x0001                          ",
        "10 46 00                        ;      ADC [BP], AL                                   ",
        "15 01 00                        ;      ADC AX, 0x0001                                 ",
        "8A 66 00                        ;      MOV AH, [BP]                                   ",
        "B8 55 55                        ;      MOV AX, 0x5555                                 ",
        "C7 46 00 01 00                  ;      MOV word [BP], 0x0001                          ",
        "11 46 00                        ;      ADC [BP], AX                                   ",
        "8B 5E 00                        ;      MOV BX, [BP]                                   ",
        "B8 59 55                        ;      MOV AX, 0x5559                                 ",
        "13 C0                           ;      ADC AX, AX                                     ",
        "B8 66 66                        ;      MOV AX, 0x6666                                 ",
        "C7 46 00 01 00                  ;      MOV word [BP], 0x0001                          ",
        "13 46 00                        ;      ADC AX, [BP]                                   ",
        "B8 77 77                        ;      MOV AX, 0x7777                                 ",
        "C7 46 00 01 00                  ;      MOV word [BP], 0x0001                          ",
        "12 46 00                        ;      ADC AL, [BP]                                   ",
        "B8 88 88                        ;      MOV AX, 0x8888                                 ",
        "15 02 00                        ;      ADC AX, 0x0002                                 ",
        "B8 99 99                        ;      MOV AX, 0x9999                                 ",
        "14 01                           ;      ADC AL, 0x01                                   ",
        "B8 FF 00                        ;      MOV AX, 0x00FF                                 ",
        "14 01                           ;      ADC AL, 1                                      ",

        "B9 04 00                       ;       mov CX, 4                                      ",
        "B8 07 00                       ;       mov AX, 7                                      ",
        "40                             ;cycle: inc AX                                         ",
        "8B D8                          ;       mov BX, AX                                     ",
        "E2 FB                          ;       loop cycle                                     ",
        "8B C3                          ;       mov AX, BX                                     ",
        "8B D8                          ;       mov BX, AX                                     ",
        "8B C8                          ;       mov CX, AX                                     ",
        "26 89 07                       ;      mov ES:[BX], AX                                 ",
        "03 C3                          ;     add AX, BX                                       ",
        "02 27                          ;     add AH, [BX]                                     ",
        "01 07                          ;     add [BX], AX                                     ",
        "03 D8                          ;     add BX, AX                                       ",
        "02 E7                          ;     add AH, BH                                       ",
        "02 FC                          ;     add BH, AH                                       ",
        "1E                             ; 10  push    ds                                       ",
        "1F                             ;     POP     DS      ;                                ",
        --"3B D9                          ; 68  cmp     bx, cx                                   ",
        "50                             ; 12  push    ax                                       ",
        "53                             ; 63  push    bx                                       ",
        "51                             ; 74  PUSH    CX                                       ",
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

    signal tb_data              : tb_data_t;

    signal CLK                  : std_logic := '0';
    signal RESETN               : std_logic := '0';

    signal EVENT_DATA_READY     : std_logic := '0';

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

    decoder_resetn <= '0' when RESETN = '0' or req_tvalid = '1' else '1';


    testbench_generation : process
        variable parser_res : line_parser_result_t;
        variable input_cnt : natural;
        variable output_cnt : natural;
        variable bytes_offset : natural;
    begin
        input_cnt := 0;
        output_cnt := 0;
        bytes_offset := 0;
        for i in test_cases'range loop
            parser_res := parse_line(test_cases(i));
            if (parser_res.len > 0) then
                for j in 0 to parser_res.len - 1 loop
                    tb_data.input_tdata(input_cnt) <= parser_res.input_bytes(j);
                    tb_data.input_tuser(input_cnt) <= std_logic_vector(to_unsigned(bytes_offset, 32));
                    input_cnt := input_cnt + 1;
                end loop;
                bytes_offset := bytes_offset + parser_res.len;
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
            wait until rising_edge(CLK);
            if (req_tvalid = '1') then
                u8_s_hs := 0;
                loop
                    if (req_tdata = tb_data.input_tuser(u8_s_hs)) then
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
                if (u8_s_hs = tb_data.input_len-1) then
                    exit;
                end if;
                u8_s_hs := u8_s_hs + 1;
            end if;
        end loop;
        u8_s_tvalid <= '0';
        wait;

    end process;

    mem_req_handler : process  begin
        mem_req_m_tready <= '0';
        mem_rd_s_tvalid <= '0';
        wait until rising_edge(EVENT_DATA_READY);
        wait until rising_edge(CLK) and RESETN = '1';
        mem_req_m_tready <= '1';
        loop
            wait until rising_edge(CLK);
            if (mem_req_m_tvalid = '1' and mem_req_m_tdata(57) = '0') then
                mem_req_m_tready <= '0';

                wait until rising_edge(CLK);
                mem_rd_s_tvalid <= '1';
                mem_rd_s_tdata <= x"04030201";
                wait until rising_edge(CLK);
                mem_rd_s_tvalid <= '0';
                mem_req_m_tready <= '1';
            end if;
        end loop;

        wait;
    end process;

end architecture;
