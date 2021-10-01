#Maximize window
wm state . zoom

#Show all as hex
radix -hexadecimal

#
# Create work library
#
vlib work

vcom -explicit  -93 "./rtl/utils/axis_fifo.vhd"
vcom -explicit  -93 "./rtl/cpu86/fetcher_buf.vhd"
vcom -explicit  -93 "./rtl/cpu86/fetcher.vhd"
vcom -explicit  -93 "./tbs/cpu86/fetcher/fetcher_tb.vhd"

vsim -novopt -t ps work.fetcher_tb

do ./tbs/cpu86/fetcher/wave.do

run 20us
