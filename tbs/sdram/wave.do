onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/za_data
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/za_valid
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/za_waitrequest
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/zs_addr
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/zs_ba
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/zs_cas_n
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/zs_cke
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/zs_cs_n
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/zs_dq
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/zs_dqm
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/zs_ras_n
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/zs_we_n
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/az_addr
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/az_be_n
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/az_cs
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/az_data
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/az_rd_n
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/az_wr_n
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/clk
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/reset_n
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/CODE
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/ack_refresh_request
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/active_addr
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/active_bank
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/active_cs_n
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/active_data
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/active_dqm
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/active_rnw
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/almost_empty
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/almost_full
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/bank_match
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/cas_addr
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/clk_en
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/cmd_all
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/cmd_code
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/cs_n
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/csn_decode
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/csn_match
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/f_addr
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/f_bank
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/f_cs_n
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/f_data
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/f_dqm
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/f_empty
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/f_pop
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/f_rnw
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/f_select
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/fifo_read_data
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/i_addr
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/i_cmd
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/i_count
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/i_next
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/i_refs
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/i_state
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/init_done
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/m_addr
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/m_bank
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/m_cmd
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/m_count
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/m_data
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/m_dqm
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/m_next
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/m_state
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/oe
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/pending
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/rd_strobe
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/rd_valid
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/refresh_counter
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/refresh_request
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/rnw_match
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/row_match
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/txt_code
add wave -noupdate -height 19 -group ctrl /sdram_ctrl_tb/sdram_ctrl_inst/za_cannotrefresh
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/zs_dq
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/clk
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/zs_addr
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/zs_ba
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/zs_cas_n
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/zs_cke
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/zs_cs_n
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/zs_dqm
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/zs_ras_n
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/zs_we_n
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/CODE
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/a
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/addr_col
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/addr_crb
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/ba
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/cas_n
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/cke
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/cmd_code
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/cs_n
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/dqm
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/index
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/latency
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/mask
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/mem_bytes
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/ras_n
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/rd_addr_pipe_0
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/rd_addr_pipe_1
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/rd_addr_pipe_2
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/rd_mask_pipe_0
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/rd_mask_pipe_1
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/rd_mask_pipe_2
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/rd_valid_pipe
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/read_addr
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/read_data
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/read_mask
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/read_temp
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/read_valid
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/rmw_temp
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/test_addr
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/txt_code
add wave -noupdate -height 19 -group model /sdram_ctrl_tb/sdram_test_model_inst/we_n
add wave -noupdate -height 19 -expand -group mem /sdram_ctrl_tb/sdram_test_model_inst/sdram_test_model_mem_inst/q
add wave -noupdate -height 19 -expand -group mem /sdram_ctrl_tb/sdram_test_model_inst/sdram_test_model_mem_inst/data
add wave -noupdate -height 19 -expand -group mem /sdram_ctrl_tb/sdram_test_model_inst/sdram_test_model_mem_inst/rdaddress
add wave -noupdate -height 19 -expand -group mem /sdram_ctrl_tb/sdram_test_model_inst/sdram_test_model_mem_inst/rdclken
add wave -noupdate -height 19 -expand -group mem /sdram_ctrl_tb/sdram_test_model_inst/sdram_test_model_mem_inst/wraddress
add wave -noupdate -height 19 -expand -group mem /sdram_ctrl_tb/sdram_test_model_inst/sdram_test_model_mem_inst/wrclock
add wave -noupdate -height 19 -expand -group mem /sdram_ctrl_tb/sdram_test_model_inst/sdram_test_model_mem_inst/wren
add wave -noupdate -height 19 -expand -group mem /sdram_ctrl_tb/sdram_test_model_inst/sdram_test_model_mem_inst/read_address
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {183698020 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
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
WaveRestoreZoom {0 ps} {220500 ns}
