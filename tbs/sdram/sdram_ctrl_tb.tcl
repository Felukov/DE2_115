#Maximize window
wm state . zoom

#Show all as hex
radix -hexadecimal

#
# Create work library
#
vlib work

vlog "./src/sdram_input_efifo_module.v"
vlog "./src/sdram_ctrl.v"

vlog "./tbs/sdram/sdram_test_model_mem.v"
vlog "./tbs/sdram/sdram_test_model.v"
vcom -explicit  -93 "./tbs/sdram/sdram_ctrl_tb.vhd"

vsim -novopt -t ps work.sdram_ctrl_tb

do ./tbs/sdram/wave.do

run 20us
