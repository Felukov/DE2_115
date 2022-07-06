## Generated SDC file "DE2_115.sdc"

## Copyright (C) 2018  Intel Corporation. All rights reserved.
## Your use of Intel Corporation's design tools, logic functions
## and other software and tools, and its AMPP partner logic
## functions, and any output files from any of the foregoing
## (including device programming or simulation files), and any
## associated documentation or information are expressly subject
## to the terms and conditions of the Intel Program License
## Subscription Agreement, the Intel Quartus Prime License Agreement,
## the Intel FPGA IP License Agreement, or other applicable license
## agreement, including, without limitation, that your use is for
## the sole purpose of programming logic devices manufactured by
## Intel and sold by Intel or its authorized distributors.  Please
## refer to the applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 18.0.0 Build 614 04/24/2018 SJ Lite Edition"

## DATE    "Sat Nov 06 19:58:51 2021"

##
## DEVICE  "EP4CE115F29C7"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {CLOCK_50} -period 20.000 -waveform { 0.000 10.000 } [get_ports {CLOCK_50}]
create_clock -name {CLOCK2_50} -period 20.000 -waveform { 0.000 10.000 } [get_ports {CLOCK2_50}]
#create_clock -name {CLK} -period 10.000 -waveform { 0.000 5.000 } [get_ports {clk}]

set_clock_groups -asynchronous -group [get_clocks {CLOCK_50}]
set_clock_groups -asynchronous -group [get_clocks {CLOCK2_50}]

#**************************************************************
# Create Generated Clock
#**************************************************************
derive_pll_clocks

create_generated_clock -name vga_clk -source [get_nets {vga_pll_inst|altpll_component|auto_generated|wire_pll1_clk[0]}] [get_ports {VGA_CLK}]


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************
derive_clock_uncertainty


#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************
set_output_delay -clock [get_clocks {vga_clk}] -max 0.8 [get_ports {VGA_BLANK_N VGA_SYNC_N VGA_B[*] VGA_G[*] VGA_R[*] VGA_HS VGA_VS}]
set_output_delay -clock [get_clocks {vga_clk}] -min -1.7 [get_ports {VGA_BLANK_N VGA_SYNC_N VGA_B[*] VGA_G[*] VGA_R[*] VGA_HS VGA_VS}]


#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************

set_false_path -to [get_ports LEDR*]
set_false_path -to [get_ports LEDG*]
set_false_path -to [get_ports HEX*]

set_false_path -from [get_ports {SW[0]}] -to [get_registers {soc:soc_inst|soc_io_switches:soc_io_switches_0_inst|switches_ff_0[0]}]
set_false_path -from [get_ports {SW[1]}] -to [get_registers {soc:soc_inst|soc_io_switches:soc_io_switches_0_inst|switches_ff_0[1]}]
set_false_path -from [get_ports {SW[2]}] -to [get_registers {soc:soc_inst|soc_io_switches:soc_io_switches_0_inst|switches_ff_0[2]}]
set_false_path -from [get_ports {SW[3]}] -to [get_registers {soc:soc_inst|soc_io_switches:soc_io_switches_0_inst|switches_ff_0[3]}]
set_false_path -from [get_ports {SW[4]}] -to [get_registers {soc:soc_inst|soc_io_switches:soc_io_switches_0_inst|switches_ff_0[4]}]
set_false_path -from [get_ports {SW[5]}] -to [get_registers {soc:soc_inst|soc_io_switches:soc_io_switches_0_inst|switches_ff_0[5]}]
set_false_path -from [get_ports {SW[6]}] -to [get_registers {soc:soc_inst|soc_io_switches:soc_io_switches_0_inst|switches_ff_0[6]}]
set_false_path -from [get_ports {SW[7]}] -to [get_registers {soc:soc_inst|soc_io_switches:soc_io_switches_0_inst|switches_ff_0[7]}]
set_false_path -from [get_ports {SW[8]}] -to [get_registers {soc:soc_inst|soc_io_switches:soc_io_switches_0_inst|switches_ff_0[8]}]
set_false_path -from [get_ports {SW[9]}] -to [get_registers {soc:soc_inst|soc_io_switches:soc_io_switches_0_inst|switches_ff_0[9]}]
set_false_path -from [get_ports {SW[10]}] -to [get_registers {soc:soc_inst|soc_io_switches:soc_io_switches_0_inst|switches_ff_0[10]}]
set_false_path -from [get_ports {SW[11]}] -to [get_registers {soc:soc_inst|soc_io_switches:soc_io_switches_0_inst|switches_ff_0[11]}]
set_false_path -from [get_ports {SW[12]}] -to [get_registers {soc:soc_inst|soc_io_switches:soc_io_switches_0_inst|switches_ff_0[12]}]
set_false_path -from [get_ports {SW[13]}] -to [get_registers {soc:soc_inst|soc_io_switches:soc_io_switches_0_inst|switches_ff_0[13]}]
set_false_path -from [get_ports {SW[14]}] -to [get_registers {soc:soc_inst|soc_io_switches:soc_io_switches_0_inst|switches_ff_0[14]}]
set_false_path -from [get_ports {SW[15]}] -to [get_registers {soc:soc_inst|soc_io_switches:soc_io_switches_0_inst|switches_ff_0[15]}]

set_false_path -from [all_clocks] -to [get_ports {BT_UART_TX}]
set_false_path -from [get_ports {BT_UART_RX}] -to [all_clocks]

set_false_path -from [get_clocks {clock_manager_inst|altpll_component|auto_generated|pll1|clk[0]}] -to [get_clocks {vga_pll_inst|altpll_component|auto_generated|pll1|clk[0]}]
set_false_path -from [get_clocks {vga_pll_inst|altpll_component|auto_generated|pll1|clk[0]}] -to [get_clocks {clock_manager_inst|altpll_component|auto_generated|pll1|clk[0]}]

#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

