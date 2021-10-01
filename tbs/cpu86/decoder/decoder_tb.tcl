#Maximize window
wm state . zoom

#Show all as hex
radix -hexadecimal

#
# Create work library
#
vlib work

vcom -explicit  -93 "./src/cpu86/types.vhd"
vcom -explicit  -93 "./src/cpu86/decoder.vhd"
vcom -explicit  -2008 "./tbs/cpu86/decoder/decoder_tb.vhd"

vsim -novopt -t ps work.decoder_tb

do ./tbs/cpu86/decoder/wave.do

run 20us
