onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -height 19 -expand -group tb /decoder_tb/CLK
add wave -noupdate -height 19 -expand -group tb /decoder_tb/RESETN
add wave -noupdate -height 19 -expand -group tb /decoder_tb/u8_s_tvalid
add wave -noupdate -height 19 -expand -group tb /decoder_tb/u8_s_tready
add wave -noupdate -height 19 -expand -group tb /decoder_tb/u8_s_tdata
add wave -noupdate -height 19 -expand -group tb -radix unsigned /decoder_tb/u8_s_tuser
add wave -noupdate -height 19 -expand -group tb /decoder_tb/instr_m_tvalid
add wave -noupdate -height 19 -expand -group tb /decoder_tb/instr_m_tready
add wave -noupdate -height 19 -expand -group tb /decoder_tb/instr_m_tdata
add wave -noupdate -height 19 -expand -group tb -radix unsigned /decoder_tb/instr_m_tuser
add wave -noupdate -height 19 -expand -group tb -radix unsigned /decoder_tb/instr_m_tuser_tb
add wave -noupdate -height 19 -expand -group tb /decoder_tb/EVENT_DATA_READY
add wave -noupdate -height 19 -expand -group uut /decoder_tb/uut/clk
add wave -noupdate -height 19 -expand -group uut /decoder_tb/uut/resetn
add wave -noupdate -height 19 -expand -group uut /decoder_tb/uut/u8_s_tvalid
add wave -noupdate -height 19 -expand -group uut /decoder_tb/uut/u8_s_tready
add wave -noupdate -height 19 -expand -group uut /decoder_tb/uut/u8_s_tdata
add wave -noupdate -height 19 -expand -group uut -radix unsigned /decoder_tb/uut/u8_s_tuser
add wave -noupdate -height 19 -expand -group uut /decoder_tb/uut/instr_m_tvalid
add wave -noupdate -height 19 -expand -group uut /decoder_tb/uut/instr_m_tready
add wave -noupdate -height 19 -expand -group uut /decoder_tb/uut/instr_m_tdata
add wave -noupdate -height 19 -expand -group uut /decoder_tb/uut/instr_m_tuser
add wave -noupdate -height 19 -expand -group uut /decoder_tb/uut/u8_tvalid
add wave -noupdate -height 19 -expand -group uut /decoder_tb/uut/u8_tready
add wave -noupdate -height 19 -expand -group uut /decoder_tb/uut/u8_tdata
add wave -noupdate -height 19 -expand -group uut -expand /decoder_tb/uut/byte_pos_chain
add wave -noupdate -height 19 -expand -group uut /decoder_tb/uut/instr_tvalid
add wave -noupdate -height 19 -expand -group uut /decoder_tb/uut/instr_tready
add wave -noupdate -height 19 -expand -group uut /decoder_tb/uut/instr_tdata
add wave -noupdate -height 19 -expand -group uut /decoder_tb/uut/instr_tuser
add wave -noupdate -height 19 -expand -group uut /decoder_tb/uut/byte0
add wave -noupdate -height 19 -expand -group uut /decoder_tb/uut/byte1
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {4738944 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 205
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 20
configure wave -griddelta 160
configure wave -timeline 1
configure wave -timelineunits ns
update
WaveRestoreZoom {420105 ps} {748231 ps}
