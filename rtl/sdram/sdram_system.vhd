
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

entity sdram_system is
    port (
        clk                 : in std_logic;
        resetn              : in std_logic;

        s_axis_req_tvalid   : in std_logic;
        s_axis_req_tready   : out std_logic;
        s_axis_req_tdata    : in std_logic_vector (63 downto 0);

        m_axis_res_tvalid   : out std_logic;
        m_axis_res_tdata    : out std_logic_vector(31 downto 0);

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
end entity sdram_system;

architecture rtl of sdram_system is

    component sdram_ctrl is
        port (
            clk             : in std_logic;
            reset_n         : in std_logic;

            az_addr         : in std_logic_vector(24 downto 0);
            az_be_n         : in std_logic_vector( 3 downto 0);
            az_cs           : in std_logic;
            az_data         : in std_logic_vector(31 downto 0);
            az_rd_n         : in std_logic;
            az_wr_n         : in std_logic;

            za_waitrequest  : out std_logic;
            za_valid        : out std_logic;
            za_data         : out std_logic_vector(31 downto 0);
            zs_addr         : out std_logic_vector(12 downto 0);
            zs_ba           : out std_logic_vector( 1 downto 0);
            zs_cas_n        : out std_logic;
            zs_cke          : out std_logic;
            zs_cs_n         : out std_logic;
            zs_dq           : inout std_logic_vector(31 downto 0);
            zs_dqm          : out std_logic_vector(3 downto 0);
            zs_ras_n        : out std_logic;
            zs_we_n         : out std_logic
        );
    end component;

    signal req_tvalid       : std_logic;
    signal req_tready       : std_logic;
    signal req_taddr        : std_logic_vector(24 downto 0);
    signal req_tcmd         : std_logic;
    signal req_tmask        : std_logic_vector(3 downto 0);
    signal req_tdata        : std_logic_vector(31 downto 0);

    signal az_addr          : std_logic_vector(24 downto 0);
    signal az_be_n          : std_logic_vector( 3 downto 0);
    signal az_cs            : std_logic;
    signal az_data          : std_logic_vector(31 downto 0);
    signal az_rd_n          : std_logic;
    signal az_wr_n          : std_logic;

    signal za_waitrequest   : std_logic;
    signal za_valid         : std_logic;
    signal za_data          : std_logic_vector(31 downto 0);

begin

    -- sd ram controller instantiation
    sdram_ctrl_inst : sdram_ctrl port map (
        clk             => clk,
        reset_n         => resetn,

        az_addr         => az_addr,
        az_be_n         => az_be_n,
        az_cs           => az_cs,
        az_data         => az_data,
        az_rd_n         => az_rd_n,
        az_wr_n         => az_wr_n,

        za_waitrequest  => za_waitrequest,
        za_valid        => za_valid,
        za_data         => za_data,

        zs_addr         => DRAM_ADDR,
        zs_ba           => DRAM_BA,
        zs_cas_n        => DRAM_CAS_N,
        zs_cke          => DRAM_CKE,
        zs_cs_n         => DRAM_CS_N,
        zs_dq           => DRAM_DQ,
        zs_dqm          => DRAM_DQM,
        zs_ras_n        => DRAM_RAS_N,
        zs_we_n         => DRAM_WE_N
    );

    -- i/o assigns
    req_tvalid          <= s_axis_req_tvalid;
    s_axis_req_tready   <= req_tready;
    req_tdata           <= s_axis_req_tdata(31 downto 0);
    req_taddr           <= s_axis_req_tdata(56 downto 32);
    req_tcmd            <= s_axis_req_tdata(57);
    req_tmask           <= s_axis_req_tdata(61 downto 58);

    m_axis_res_tvalid   <= za_valid;
    m_axis_res_tdata    <= za_data;

    -- assigns
    req_tready          <= '1' when za_waitrequest = '0' else '0';

    az_cs               <= '1';
    az_wr_n             <= '0' when req_tvalid = '1' and req_tcmd = '1' else '1';
    az_rd_n             <= '0' when req_tvalid = '1' and req_tcmd = '0' else '1';
    az_be_n             <= req_tmask;
    az_addr             <= req_taddr;
    az_data             <= req_tdata;

end architecture;
