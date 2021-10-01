#Maximize window
wm state . zoom

#Show all as hex
radix -hexadecimal

#
# Create work library
#

#vmap -del work
vlib work

vcom +cover -explicit -2008 "./rtl/utils/axis_fifo.vhd"
vcom +cover -explicit -2008 "./rtl/cpu86/types.vhd"
vcom +cover -explicit -93 "./rtl/cpu86/decoder.vhd"
vcom +cover -explicit -2008 "./rtl/cpu86/cpu_flags.vhd"
vcom +cover -explicit -2008 "./rtl/cpu86/cpu_reg.vhd"
vcom +cover -explicit -2008 "./rtl/cpu86/register_reader.vhd"
vcom +cover -explicit -2008 "./rtl/cpu86/ifeu.vhd"
vcom +cover -explicit -2008 "./rtl/cpu86/exec.vhd"
vcom +cover -explicit -2008 "./rtl/cpu86/lsu.vhd"
vcom +cover -explicit -2008 "./rtl/cpu86/lsu_fifo.vhd"
vcom +cover -explicit -2008 "./rtl/cpu86/dcache.vhd"
vcom +cover -explicit -2008 "./rtl/cpu86/mexec.vhd"
vcom +cover -explicit -2008 "./tbs/cpu86/exec/exec_tb.vhd"

vsim -novopt -t ps  work.exec_tb

#vsim -novopt -t ps -coverage  work.exec_tb

do ./tbs/cpu86/exec/wave.do

run 20us
