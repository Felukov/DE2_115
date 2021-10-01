onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /fetcher_tb/fetcher_inst/clk
add wave -noupdate /fetcher_tb/fetcher_inst/resetn
add wave -noupdate /fetcher_tb/fetcher_inst/req_s_tvalid
add wave -noupdate /fetcher_tb/fetcher_inst/req_s_tdata
add wave -noupdate /fetcher_tb/fetcher_inst/rd_s_tvalid
add wave -noupdate /fetcher_tb/fetcher_inst/rd_s_tdata
add wave -noupdate /fetcher_tb/fetcher_inst/cmd_m_tvalid
add wave -noupdate /fetcher_tb/fetcher_inst/cmd_m_tready
add wave -noupdate /fetcher_tb/fetcher_inst/cmd_m_tdata
add wave -noupdate /fetcher_tb/fetcher_inst/buf_m_tvalid
add wave -noupdate /fetcher_tb/fetcher_inst/buf_m_tready
add wave -noupdate /fetcher_tb/fetcher_inst/buf_m_tdata
add wave -noupdate /fetcher_tb/fetcher_inst/buf_m_tuser
add wave -noupdate /fetcher_tb/fetcher_inst/cmd_tvalid
add wave -noupdate /fetcher_tb/fetcher_inst/cmd_tready
add wave -noupdate /fetcher_tb/fetcher_inst/cmd_tdata
add wave -noupdate /fetcher_tb/fetcher_inst/max_hs_cnt
add wave -noupdate /fetcher_tb/fetcher_inst/mem_hs_cnt
add wave -noupdate /fetcher_tb/fetcher_inst/skip_hs_cnt
add wave -noupdate /fetcher_tb/fetcher_inst/req_tvalid
add wave -noupdate /fetcher_tb/fetcher_inst/req_tdata
add wave -noupdate /fetcher_tb/fetcher_inst/rd_tvalid
add wave -noupdate /fetcher_tb/fetcher_inst/rd_tdata
add wave -noupdate /fetcher_tb/fetcher_inst/max_inc_hs
add wave -noupdate /fetcher_tb/fetcher_inst/max_dec_hs
add wave -noupdate /fetcher_tb/fetcher_inst/mem_inc_hs
add wave -noupdate /fetcher_tb/fetcher_inst/mem_dec_hs
add wave -noupdate /fetcher_tb/fetcher_inst/cs_tdata
add wave -noupdate /fetcher_tb/fetcher_inst/ip_tdata
add wave -noupdate /fetcher_tb/fetcher_inst/fifo_0_s_tvalid
add wave -noupdate /fetcher_tb/fetcher_inst/fifo_0_s_tready
add wave -noupdate /fetcher_tb/fetcher_inst/fifo_0_s_tdata
add wave -noupdate /fetcher_tb/fetcher_inst/fifo_0_m_tvalid
add wave -noupdate /fetcher_tb/fetcher_inst/fifo_0_m_tready
add wave -noupdate /fetcher_tb/fetcher_inst/fifo_0_m_tdata
add wave -noupdate /fetcher_tb/fetcher_inst/fifo_resetn
add wave -noupdate /fetcher_tb/fetcher_inst/fifo_1_s_tvalid
add wave -noupdate /fetcher_tb/fetcher_inst/fifo_1_s_tready
add wave -noupdate /fetcher_tb/fetcher_inst/fifo_1_s_tdata
add wave -noupdate /fetcher_tb/fetcher_inst/fifo_1_m_tvalid
add wave -noupdate /fetcher_tb/fetcher_inst/fifo_1_m_tready
add wave -noupdate /fetcher_tb/fetcher_inst/fifo_1_m_tdata
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {269662 ps} 0}
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
WaveRestoreZoom {135955 ps} {549869 ps}
