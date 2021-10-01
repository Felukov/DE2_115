onerror {resume}
quietly virtual signal -install /exec_tb/uut/lsu_inst { /exec_tb/uut/lsu_inst/fifo_0_m_tdata(5 downto 4)} t_addr
quietly virtual function -install /exec_tb/uut/lsu_inst/lsu_fifo_inst -env /exec_tb { sim:/exec_tb/uut/lsu_inst/lsu_fifo_inst/add_s_tvalid AND sim:/exec_tb/uut/lsu_inst/lsu_fifo_inst/add_s_tready} lsu_fifo_add_s_hs
quietly virtual function -install /exec_tb/decoder_inst -env /exec_tb { /exec_tb/decoder_inst/instr_tvalid 'rising} expr_test_99
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group tb /exec_tb/tb_data
add wave -noupdate -expand -group tb /exec_tb/CLK
add wave -noupdate -expand -group tb /exec_tb/RESETN
add wave -noupdate -expand -group tb /exec_tb/EVENT_DATA_READY
add wave -noupdate -expand -group tb /exec_tb/u8_s_tvalid
add wave -noupdate -expand -group tb /exec_tb/u8_s_tready
add wave -noupdate -expand -group tb /exec_tb/u8_s_tdata
add wave -noupdate -expand -group tb /exec_tb/u8_s_tuser
add wave -noupdate -expand -group tb /exec_tb/instr_tvalid
add wave -noupdate -expand -group tb /exec_tb/instr_tready
add wave -noupdate -expand -group tb /exec_tb/instr_tdata
add wave -noupdate -expand -group tb /exec_tb/instr_tuser
add wave -noupdate -expand -group tb /exec_tb/decoder_resetn
add wave -noupdate -expand -group tb /exec_tb/mem_req_m_tvalid
add wave -noupdate -expand -group tb /exec_tb/mem_req_m_tready
add wave -noupdate -expand -group tb /exec_tb/mem_req_m_tdata
add wave -noupdate -expand -group tb /exec_tb/mem_rd_s_tvalid
add wave -noupdate -expand -group tb /exec_tb/mem_rd_s_tdata
add wave -noupdate -expand -group tb /exec_tb/req_tvalid
add wave -noupdate -expand -group tb /exec_tb/req_tdata
add wave -noupdate -height 19 -group uut /exec_tb/uut/clk
add wave -noupdate -height 19 -group uut /exec_tb/uut/resetn
add wave -noupdate -height 19 -group uut /exec_tb/uut/instr_s_tvalid
add wave -noupdate -height 19 -group uut /exec_tb/uut/instr_s_tready
add wave -noupdate -height 19 -group uut -radix hexadecimal /exec_tb/uut/instr_s_tdata
add wave -noupdate -height 19 -group uut -radix hexadecimal /exec_tb/uut/instr_s_tuser
add wave -noupdate -height 19 -group uut /exec_tb/uut/fifo_instr_m_tvalid
add wave -noupdate -height 19 -group uut /exec_tb/uut/fifo_instr_m_tready
add wave -noupdate -height 19 -group uut /exec_tb/uut/jmp_lock_tvalid
add wave -noupdate -height 19 -group uut /exec_tb/uut/jmp_lock_lock_tvalid
add wave -noupdate -height 19 -group uut /exec_tb/uut/jmp_lock_wr_tvalid
add wave -noupdate -height 19 -group uut /exec_tb/uut/ax_tvalid
add wave -noupdate -height 19 -group uut -radix hexadecimal /exec_tb/uut/ax_tdata
add wave -noupdate -height 19 -group uut /exec_tb/uut/ax_lock_tvalid
add wave -noupdate -height 19 -group uut /exec_tb/uut/ax_wr_tvalid
add wave -noupdate -height 19 -group uut -radix hexadecimal /exec_tb/uut/ax_wr_tdata
add wave -noupdate -height 19 -group uut /exec_tb/uut/bx_tvalid
add wave -noupdate -height 19 -group uut /exec_tb/uut/bx_tdata
add wave -noupdate -height 19 -group uut /exec_tb/uut/bx_lock_tvalid
add wave -noupdate -height 19 -group uut /exec_tb/uut/bx_wr_tvalid
add wave -noupdate -height 19 -group uut -radix hexadecimal /exec_tb/uut/bx_wr_tdata
add wave -noupdate -height 19 -group uut /exec_tb/uut/cx_tvalid
add wave -noupdate -height 19 -group uut -radix hexadecimal /exec_tb/uut/cx_tdata
add wave -noupdate -height 19 -group uut /exec_tb/uut/cx_lock_tvalid
add wave -noupdate -height 19 -group uut /exec_tb/uut/cx_wr_tvalid
add wave -noupdate -height 19 -group uut -radix hexadecimal /exec_tb/uut/cx_wr_tdata
add wave -noupdate -height 19 -group uut /exec_tb/uut/dx_tvalid
add wave -noupdate -height 19 -group uut /exec_tb/uut/dx_tdata
add wave -noupdate -height 19 -group uut /exec_tb/uut/dx_lock_tvalid
add wave -noupdate -height 19 -group uut /exec_tb/uut/dx_wr_tvalid
add wave -noupdate -height 19 -group uut -radix hexadecimal /exec_tb/uut/dx_wr_tdata
add wave -noupdate -height 19 -group uut /exec_tb/uut/sp_tvalid
add wave -noupdate -height 19 -group uut -radix hexadecimal /exec_tb/uut/sp_tdata
add wave -noupdate -height 19 -group uut /exec_tb/uut/sp_lock_tvalid
add wave -noupdate -height 19 -group uut /exec_tb/uut/sp_wr_tvalid
add wave -noupdate -height 19 -group uut -radix hexadecimal /exec_tb/uut/sp_wr_tdata
add wave -noupdate -height 19 -group uut /exec_tb/uut/bp_tvalid
add wave -noupdate -height 19 -group uut /exec_tb/uut/bp_tdata
add wave -noupdate -height 19 -group uut /exec_tb/uut/bp_lock_tvalid
add wave -noupdate -height 19 -group uut /exec_tb/uut/bp_wr_tvalid
add wave -noupdate -height 19 -group uut -radix hexadecimal /exec_tb/uut/bp_wr_tdata
add wave -noupdate -height 19 -group uut /exec_tb/uut/si_tvalid
add wave -noupdate -height 19 -group uut /exec_tb/uut/si_tdata
add wave -noupdate -height 19 -group uut /exec_tb/uut/si_lock_tvalid
add wave -noupdate -height 19 -group uut /exec_tb/uut/si_wr_tvalid
add wave -noupdate -height 19 -group uut -radix hexadecimal /exec_tb/uut/si_wr_tdata
add wave -noupdate -height 19 -group uut /exec_tb/uut/di_tvalid
add wave -noupdate -height 19 -group uut /exec_tb/uut/di_tdata
add wave -noupdate -height 19 -group uut /exec_tb/uut/di_lock_tvalid
add wave -noupdate -height 19 -group uut /exec_tb/uut/di_wr_tvalid
add wave -noupdate -height 19 -group uut -radix hexadecimal /exec_tb/uut/di_wr_tdata
add wave -noupdate -height 19 -group uut /exec_tb/uut/ds_tvalid
add wave -noupdate -height 19 -group uut /exec_tb/uut/ds_tdata
add wave -noupdate -height 19 -group uut /exec_tb/uut/ds_lock_tvalid
add wave -noupdate -height 19 -group uut /exec_tb/uut/ds_wr_tvalid
add wave -noupdate -height 19 -group uut /exec_tb/uut/ds_wr_tdata
add wave -noupdate -height 19 -group uut /exec_tb/uut/ss_tvalid
add wave -noupdate -height 19 -group uut /exec_tb/uut/ss_tdata
add wave -noupdate -height 19 -group uut /exec_tb/uut/ss_lock_tvalid
add wave -noupdate -height 19 -group uut /exec_tb/uut/ss_wr_tvalid
add wave -noupdate -height 19 -group uut /exec_tb/uut/ss_wr_tdata
add wave -noupdate -height 19 -group uut /exec_tb/uut/es_tvalid
add wave -noupdate -height 19 -group uut /exec_tb/uut/es_tdata
add wave -noupdate -height 19 -group uut /exec_tb/uut/es_lock_tvalid
add wave -noupdate -height 19 -group uut /exec_tb/uut/es_wr_tvalid
add wave -noupdate -height 19 -group uut /exec_tb/uut/es_wr_tdata
add wave -noupdate -height 19 -group uut /exec_tb/uut/flags_tvalid
add wave -noupdate -height 19 -group uut /exec_tb/uut/flags_tdata
add wave -noupdate -height 19 -group uut /exec_tb/uut/flags_lock_tvalid
add wave -noupdate -height 19 -group uut /exec_tb/uut/flags_wr_tvalid
add wave -noupdate -height 19 -group uut /exec_tb/uut/flags_wr_tdata
add wave -noupdate -height 19 -group uut /exec_tb/uut/mexec_inst/jump_m_tvalid
add wave -noupdate -height 19 -group uut -radix hexadecimal /exec_tb/uut/mexec_inst/jump_m_tdata
add wave -noupdate -height 19 -group uut /exec_tb/uut/rr_tvalid
add wave -noupdate -height 19 -group uut /exec_tb/uut/rr_tready
add wave -noupdate -height 19 -group uut /exec_tb/uut/rr_tdata
add wave -noupdate -height 19 -group uut /exec_tb/uut/rr_tuser
add wave -noupdate -height 19 -group decoder /exec_tb/decoder_inst/clk
add wave -noupdate -height 19 -group decoder /exec_tb/decoder_inst/resetn
add wave -noupdate -height 19 -group decoder /exec_tb/decoder_inst/u8_s_tvalid
add wave -noupdate -height 19 -group decoder /exec_tb/decoder_inst/u8_s_tready
add wave -noupdate -height 19 -group decoder /exec_tb/decoder_inst/u8_s_tdata
add wave -noupdate -height 19 -group decoder /exec_tb/decoder_inst/u8_s_tuser
add wave -noupdate -height 19 -group decoder /exec_tb/decoder_inst/instr_m_tvalid
add wave -noupdate -height 19 -group decoder /exec_tb/decoder_inst/instr_m_tready
add wave -noupdate -height 19 -group decoder /exec_tb/decoder_inst/instr_m_tdata
add wave -noupdate -height 19 -group decoder /exec_tb/decoder_inst/instr_m_tuser
add wave -noupdate -height 19 -group decoder /exec_tb/decoder_inst/u8_tvalid
add wave -noupdate -height 19 -group decoder /exec_tb/decoder_inst/u8_tready
add wave -noupdate -height 19 -group decoder /exec_tb/decoder_inst/u8_tdata
add wave -noupdate -height 19 -group decoder /exec_tb/decoder_inst/u8_tdata_rm
add wave -noupdate -height 19 -group decoder /exec_tb/decoder_inst/u8_tdata_reg
add wave -noupdate -height 19 -group decoder /exec_tb/decoder_inst/byte_pos_chain
add wave -noupdate -height 19 -group decoder /exec_tb/decoder_inst/instr_tvalid
add wave -noupdate -height 19 -group decoder /exec_tb/decoder_inst/instr_tready
add wave -noupdate -height 19 -group decoder -expand /exec_tb/decoder_inst/instr_tdata
add wave -noupdate -height 19 -group decoder /exec_tb/decoder_inst/instr_tuser
add wave -noupdate -height 19 -group decoder /exec_tb/decoder_inst/byte0
add wave -noupdate -height 19 -group decoder /exec_tb/decoder_inst/byte1
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/clk
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/resetn
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/instr_s_tvalid
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/instr_s_tready
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/instr_s_tdata
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/instr_s_tuser
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/ax_s_tvalid
add wave -noupdate -height 19 -group rr -radix hexadecimal /exec_tb/uut/register_reader_inst/ax_s_tdata
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/ax_m_lock_tvalid
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/bx_s_tvalid
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/bx_s_tdata
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/bx_m_lock_tvalid
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/cx_s_tvalid
add wave -noupdate -height 19 -group rr -radix hexadecimal /exec_tb/uut/register_reader_inst/cx_s_tdata
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/cx_m_lock_tvalid
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/dx_s_tvalid
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/dx_s_tdata
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/dx_m_lock_tvalid
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/sp_s_tvalid
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/sp_s_tdata
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/sp_m_lock_tvalid
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/bp_s_tvalid
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/bp_s_tdata
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/bp_m_lock_tvalid
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/si_s_tvalid
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/si_s_tdata
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/si_m_lock_tvalid
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/di_s_tvalid
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/di_s_tdata
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/di_m_lock_tvalid
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/rr_m_tvalid
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/rr_m_tready
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/rr_m_tdata
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/rr_m_tuser
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/instr_tvalid
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/instr_tready
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/instr_tdata
add wave -noupdate -height 19 -group rr -radix hexadecimal /exec_tb/uut/register_reader_inst/instr_tuser
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/rr_tvalid
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/rr_tready
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/rr_tdata
add wave -noupdate -height 19 -group rr -radix hexadecimal /exec_tb/uut/register_reader_inst/rr_tuser
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/sreg_tvalid
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/sreg_tdata
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/dreg_tvalid
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/ea_tvalid
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/seg_override_tvalid
add wave -noupdate -height 19 -group rr /exec_tb/uut/register_reader_inst/seg_override_tdata
add wave -noupdate -height 19 -expand -group ifeu /exec_tb/uut/ifeu_inst/clk
add wave -noupdate -height 19 -expand -group ifeu /exec_tb/uut/ifeu_inst/resetn
add wave -noupdate -height 19 -expand -group ifeu /exec_tb/uut/ifeu_inst/jmp_lock_s_tvalid
add wave -noupdate -height 19 -expand -group ifeu /exec_tb/uut/ifeu_inst/rr_s_tvalid
add wave -noupdate -height 19 -expand -group ifeu /exec_tb/uut/ifeu_inst/rr_s_tready
add wave -noupdate -height 19 -expand -group ifeu -radix hexadecimal /exec_tb/uut/ifeu_inst/rr_s_tdata
add wave -noupdate -height 19 -expand -group ifeu -radix hexadecimal /exec_tb/uut/ifeu_inst/rr_s_tuser
add wave -noupdate -height 19 -expand -group ifeu -height 19 -group {write regs} /exec_tb/uut/ifeu_inst/ax_m_wr_tvalid
add wave -noupdate -height 19 -expand -group ifeu -height 19 -group {write regs} -radix hexadecimal /exec_tb/uut/ifeu_inst/ax_m_wr_tdata
add wave -noupdate -height 19 -expand -group ifeu -height 19 -group {write regs} /exec_tb/uut/ifeu_inst/bx_m_wr_tvalid
add wave -noupdate -height 19 -expand -group ifeu -height 19 -group {write regs} -radix hexadecimal /exec_tb/uut/ifeu_inst/bx_m_wr_tdata
add wave -noupdate -height 19 -expand -group ifeu -height 19 -group {write regs} /exec_tb/uut/ifeu_inst/cx_m_wr_tvalid
add wave -noupdate -height 19 -expand -group ifeu -height 19 -group {write regs} -radix hexadecimal /exec_tb/uut/ifeu_inst/cx_m_wr_tdata
add wave -noupdate -height 19 -expand -group ifeu -height 19 -group {write regs} /exec_tb/uut/ifeu_inst/dx_m_wr_tvalid
add wave -noupdate -height 19 -expand -group ifeu -height 19 -group {write regs} -radix hexadecimal /exec_tb/uut/ifeu_inst/dx_m_wr_tdata
add wave -noupdate -height 19 -expand -group ifeu -height 19 -group {write regs} /exec_tb/uut/ifeu_inst/bp_m_wr_tvalid
add wave -noupdate -height 19 -expand -group ifeu -height 19 -group {write regs} -radix hexadecimal /exec_tb/uut/ifeu_inst/bp_m_wr_tdata
add wave -noupdate -height 19 -expand -group ifeu -height 19 -group {write regs} /exec_tb/uut/ifeu_inst/sp_m_wr_tvalid
add wave -noupdate -height 19 -expand -group ifeu -height 19 -group {write regs} -radix hexadecimal /exec_tb/uut/ifeu_inst/sp_m_wr_tdata
add wave -noupdate -height 19 -expand -group ifeu -height 19 -group {write regs} /exec_tb/uut/ifeu_inst/di_m_wr_tvalid
add wave -noupdate -height 19 -expand -group ifeu -height 19 -group {write regs} -radix hexadecimal /exec_tb/uut/ifeu_inst/di_m_wr_tdata
add wave -noupdate -height 19 -expand -group ifeu -height 19 -group {write regs} /exec_tb/uut/ifeu_inst/si_m_wr_tvalid
add wave -noupdate -height 19 -expand -group ifeu -height 19 -group {write regs} -radix hexadecimal /exec_tb/uut/ifeu_inst/si_m_wr_tdata
add wave -noupdate -height 19 -expand -group ifeu /exec_tb/uut/ifeu_inst/rr_tvalid
add wave -noupdate -height 19 -expand -group ifeu /exec_tb/uut/ifeu_inst/rr_tready
add wave -noupdate -height 19 -expand -group ifeu -childformat {{/exec_tb/uut/ifeu_inst/rr_tdata.dreg_val -radix hexadecimal} {/exec_tb/uut/ifeu_inst/rr_tdata.sreg_val -radix hexadecimal} {/exec_tb/uut/ifeu_inst/rr_tdata.data -radix hexadecimal} {/exec_tb/uut/ifeu_inst/rr_tdata.disp -radix decimal}} -subitemconfig {/exec_tb/uut/ifeu_inst/rr_tdata.dreg_val {-height 19 -radix hexadecimal} /exec_tb/uut/ifeu_inst/rr_tdata.sreg_val {-height 19 -radix hexadecimal} /exec_tb/uut/ifeu_inst/rr_tdata.data {-height 19 -radix hexadecimal} /exec_tb/uut/ifeu_inst/rr_tdata.disp {-height 19 -radix decimal}} /exec_tb/uut/ifeu_inst/rr_tdata
add wave -noupdate -height 19 -expand -group ifeu -radix hexadecimal /exec_tb/uut/ifeu_inst/rr_tuser
add wave -noupdate -height 19 -expand -group ifeu -childformat {{/exec_tb/uut/ifeu_inst/rr_tdata_buf.seg_val -radix hexadecimal} {/exec_tb/uut/ifeu_inst/rr_tdata_buf.ea_val -radix hexadecimal} {/exec_tb/uut/ifeu_inst/rr_tdata_buf.dreg_val -radix hexadecimal} {/exec_tb/uut/ifeu_inst/rr_tdata_buf.sreg_val -radix hexadecimal} {/exec_tb/uut/ifeu_inst/rr_tdata_buf.data -radix hexadecimal} {/exec_tb/uut/ifeu_inst/rr_tdata_buf.disp -radix hexadecimal}} -subitemconfig {/exec_tb/uut/ifeu_inst/rr_tdata_buf.seg_val {-height 19 -radix hexadecimal} /exec_tb/uut/ifeu_inst/rr_tdata_buf.ea_val {-height 19 -radix hexadecimal} /exec_tb/uut/ifeu_inst/rr_tdata_buf.dreg_val {-height 19 -radix hexadecimal} /exec_tb/uut/ifeu_inst/rr_tdata_buf.sreg_val {-height 19 -radix hexadecimal} /exec_tb/uut/ifeu_inst/rr_tdata_buf.data {-height 19 -radix hexadecimal} /exec_tb/uut/ifeu_inst/rr_tdata_buf.disp {-height 19 -radix hexadecimal}} /exec_tb/uut/ifeu_inst/rr_tdata_buf
add wave -noupdate -height 19 -expand -group ifeu /exec_tb/uut/ifeu_inst/micro_tvalid
add wave -noupdate -height 19 -expand -group ifeu /exec_tb/uut/ifeu_inst/micro_tready
add wave -noupdate -height 19 -expand -group ifeu /exec_tb/uut/ifeu_inst/micro_cnt
add wave -noupdate -height 19 -expand -group ifeu -childformat {{/exec_tb/uut/ifeu_inst/micro_tdata.jump_cs -radix hexadecimal} {/exec_tb/uut/ifeu_inst/micro_tdata.jump_ip -radix hexadecimal}} -subitemconfig {/exec_tb/uut/ifeu_inst/micro_tdata.cmd -expand /exec_tb/uut/ifeu_inst/micro_tdata.jump_cs {-height 19 -radix hexadecimal} /exec_tb/uut/ifeu_inst/micro_tdata.jump_ip {-height 19 -radix hexadecimal}} /exec_tb/uut/ifeu_inst/micro_tdata
add wave -noupdate -height 19 -expand -group ifeu /exec_tb/uut/ifeu_inst/rep_mode
add wave -noupdate -height 19 -expand -group ifeu /exec_tb/uut/ifeu_inst/rep_code
add wave -noupdate -height 19 -expand -group ifeu /exec_tb/uut/ifeu_inst/rep_lock
add wave -noupdate -height 19 -expand -group ifeu /exec_tb/uut/ifeu_inst/rep_cx_cnt
add wave -noupdate -height 19 -expand -group ifeu /exec_tb/uut/ifeu_inst/rep_burst_len
add wave -noupdate -height 19 -expand -group ifeu /exec_tb/uut/ifeu_inst/rep_upd_cx_tvalid
add wave -noupdate -height 19 -expand -group ifeu /exec_tb/uut/ifeu_inst/fast_instruction_fl
add wave -noupdate -group mexec /exec_tb/uut/mexec_inst/clk
add wave -noupdate -group mexec /exec_tb/uut/mexec_inst/resetn
add wave -noupdate -group mexec /exec_tb/uut/mexec_inst/micro_s_tvalid
add wave -noupdate -group mexec /exec_tb/uut/mexec_inst/micro_s_tready
add wave -noupdate -group mexec /exec_tb/uut/mexec_inst/micro_s_tdata
add wave -noupdate -group mexec /exec_tb/uut/mexec_inst/lsu_rd_s_tvalid
add wave -noupdate -group mexec /exec_tb/uut/mexec_inst/lsu_rd_s_tdata
add wave -noupdate -group mexec -height 19 -group write_regs /exec_tb/uut/mexec_inst/ax_m_wr_tvalid
add wave -noupdate -group mexec -height 19 -group write_regs /exec_tb/uut/mexec_inst/ax_m_wr_tdata
add wave -noupdate -group mexec -height 19 -group write_regs /exec_tb/uut/mexec_inst/bx_m_wr_tvalid
add wave -noupdate -group mexec -height 19 -group write_regs /exec_tb/uut/mexec_inst/bx_m_wr_tdata
add wave -noupdate -group mexec -height 19 -group write_regs /exec_tb/uut/mexec_inst/cx_m_wr_tvalid
add wave -noupdate -group mexec -height 19 -group write_regs /exec_tb/uut/mexec_inst/cx_m_wr_tdata
add wave -noupdate -group mexec -height 19 -group write_regs /exec_tb/uut/mexec_inst/dx_m_wr_tvalid
add wave -noupdate -group mexec -height 19 -group write_regs /exec_tb/uut/mexec_inst/dx_m_wr_tdata
add wave -noupdate -group mexec -height 19 -group write_regs /exec_tb/uut/mexec_inst/bp_m_wr_tvalid
add wave -noupdate -group mexec -height 19 -group write_regs /exec_tb/uut/mexec_inst/bp_m_wr_tdata
add wave -noupdate -group mexec -height 19 -group write_regs /exec_tb/uut/mexec_inst/sp_m_wr_tvalid
add wave -noupdate -group mexec -height 19 -group write_regs /exec_tb/uut/mexec_inst/sp_m_wr_tdata
add wave -noupdate -group mexec -height 19 -group write_regs /exec_tb/uut/mexec_inst/di_m_wr_tvalid
add wave -noupdate -group mexec -height 19 -group write_regs /exec_tb/uut/mexec_inst/di_m_wr_tdata
add wave -noupdate -group mexec -height 19 -group write_regs /exec_tb/uut/mexec_inst/si_m_wr_tvalid
add wave -noupdate -group mexec -height 19 -group write_regs /exec_tb/uut/mexec_inst/si_m_wr_tdata
add wave -noupdate -group mexec /exec_tb/uut/mexec_inst/lsu_req_m_tvalid
add wave -noupdate -group mexec /exec_tb/uut/mexec_inst/lsu_req_m_tready
add wave -noupdate -group mexec /exec_tb/uut/mexec_inst/lsu_req_m_taddr
add wave -noupdate -group mexec /exec_tb/uut/mexec_inst/jump_m_tvalid
add wave -noupdate -group mexec /exec_tb/uut/mexec_inst/jump_m_tdata
add wave -noupdate -group mexec /exec_tb/uut/mexec_inst/jmp_lock_m_wr_tvalid
add wave -noupdate -group mexec /exec_tb/uut/mexec_inst/micro_tvalid
add wave -noupdate -group mexec /exec_tb/uut/mexec_inst/micro_tready
add wave -noupdate -group mexec -childformat {{/exec_tb/uut/mexec_inst/micro_tdata.jump_cs -radix hexadecimal} {/exec_tb/uut/mexec_inst/micro_tdata.jump_ip -radix hexadecimal}} -expand -subitemconfig {/exec_tb/uut/mexec_inst/micro_tdata.cmd -expand /exec_tb/uut/mexec_inst/micro_tdata.jump_cs {-height 19 -radix hexadecimal} /exec_tb/uut/mexec_inst/micro_tdata.jump_ip {-height 19 -radix hexadecimal}} /exec_tb/uut/mexec_inst/micro_tdata
add wave -noupdate -group mexec -radix binary /exec_tb/uut/mexec_inst/flags_s_tdata
add wave -noupdate -group mexec /exec_tb/uut/mexec_inst/flags_m_wr_tvalid
add wave -noupdate -group mexec -radix binary /exec_tb/uut/mexec_inst/flags_m_wr_tdata
add wave -noupdate -group mexec -radix binary /exec_tb/uut/mexec_inst/flags_wr_be
add wave -noupdate -group mexec -radix binary /exec_tb/uut/mexec_inst/flags_wr_vector
add wave -noupdate -group mexec /exec_tb/uut/mexec_inst/alu_tvalid
add wave -noupdate -group mexec -childformat {{/exec_tb/uut/mexec_inst/alu_tdata.dval -radix hexadecimal}} -expand -subitemconfig {/exec_tb/uut/mexec_inst/alu_tdata.dval {-height 19 -radix hexadecimal}} /exec_tb/uut/mexec_inst/alu_tdata
add wave -noupdate -group mexec /exec_tb/uut/mexec_inst/lsu_req_tvalid
add wave -noupdate -group mexec /exec_tb/uut/mexec_inst/lsu_req_tready
add wave -noupdate -group mexec /exec_tb/uut/mexec_inst/lsu_req_tcmd
add wave -noupdate -group mexec /exec_tb/uut/mexec_inst/lsu_req_taddr
add wave -noupdate -group mexec /exec_tb/uut/mexec_inst/lsu_req_twidth
add wave -noupdate -group mexec /exec_tb/uut/mexec_inst/lsu_req_tdata
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/clk
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/resetn
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/lsu_req_s_tvalid
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/lsu_req_s_tready
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/lsu_req_s_tcmd
add wave -noupdate -group lsu -radix hexadecimal /exec_tb/uut/lsu_inst/lsu_req_s_taddr
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/lsu_req_s_twidth
add wave -noupdate -group lsu -radix hexadecimal /exec_tb/uut/lsu_inst/lsu_req_s_tdata
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/mem_req_m_tvalid
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/mem_req_m_tready
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/mem_req_m_tdata
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/mem_rd_s_tvalid
add wave -noupdate -group lsu -radix hexadecimal /exec_tb/uut/lsu_inst/mem_rd_s_tdata
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/lsu_rd_m_tvalid
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/lsu_rd_m_tready
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/lsu_rd_m_tdata
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/lsu_req_tvalid
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/lsu_req_tready
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/req_buf_tvalid
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/req_buf_tready
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/req_buf_tcmd
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/req_buf_twidth
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/req_buf_taddr
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/req_buf_tdata
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/mem_req_tvalid
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/mem_req_tready
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/mem_req_tlast
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/mem_req_tcmd
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/mem_req_taddr
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/mem_req_tmask
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/mem_req_tdata
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/fifo_0_s_tvalid
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/fifo_0_s_tready
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/fifo_0_s_tdata
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/fifo_0_m_tvalid
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/fifo_0_m_tready
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/fifo_0_m_tdata
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/upd_s_tvalid
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/t_addr
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/upd_s_tdata
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/upd_s_taddr
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/fifo_1_m_tvalid
add wave -noupdate -group lsu /exec_tb/uut/lsu_inst/fifo_1_m_tready
add wave -noupdate -group lsu -radix hexadecimal /exec_tb/uut/lsu_inst/fifo_1_m_tdata
add wave -noupdate -height 19 -group dcache /exec_tb/uut/dcache_inst/clk
add wave -noupdate -height 19 -group dcache /exec_tb/uut/dcache_inst/resetn
add wave -noupdate -height 19 -group dcache /exec_tb/uut/dcache_inst/lsu_req_s_tvalid
add wave -noupdate -height 19 -group dcache /exec_tb/uut/dcache_inst/lsu_req_s_tready
add wave -noupdate -height 19 -group dcache /exec_tb/uut/dcache_inst/lsu_req_s_tcmd
add wave -noupdate -height 19 -group dcache /exec_tb/uut/dcache_inst/lsu_req_s_taddr
add wave -noupdate -height 19 -group dcache /exec_tb/uut/dcache_inst/lsu_req_s_twidth
add wave -noupdate -height 19 -group dcache /exec_tb/uut/dcache_inst/lsu_req_s_tdata
add wave -noupdate -height 19 -group dcache /exec_tb/uut/dcache_inst/dcache_m_tvalid
add wave -noupdate -height 19 -group dcache /exec_tb/uut/dcache_inst/dcache_m_tdata
add wave -noupdate -height 19 -group dcache /exec_tb/uut/dcache_inst/d_valid
add wave -noupdate -height 19 -group dcache /exec_tb/uut/dcache_inst/index
add wave -noupdate -height 19 -group dcache /exec_tb/uut/dcache_inst/tag
add wave -noupdate -height 19 -group lsu_fifo /exec_tb/uut/lsu_inst/lsu_fifo_inst/clk
add wave -noupdate -height 19 -group lsu_fifo /exec_tb/uut/lsu_inst/lsu_fifo_inst/resetn
add wave -noupdate -height 19 -group lsu_fifo /exec_tb/uut/lsu_inst/lsu_fifo_inst/add_s_tvalid
add wave -noupdate -height 19 -group lsu_fifo /exec_tb/uut/lsu_inst/lsu_fifo_inst/add_s_tready
add wave -noupdate -height 19 -group lsu_fifo /exec_tb/uut/lsu_inst/lsu_fifo_inst/lsu_fifo_add_s_hs
add wave -noupdate -height 19 -group lsu_fifo /exec_tb/uut/lsu_inst/lsu_fifo_inst/add_s_thit
add wave -noupdate -height 19 -group lsu_fifo /exec_tb/uut/lsu_inst/lsu_fifo_inst/add_s_tdata
add wave -noupdate -height 19 -group lsu_fifo /exec_tb/uut/lsu_inst/lsu_fifo_inst/add_s_taddr
add wave -noupdate -height 19 -group lsu_fifo /exec_tb/uut/lsu_inst/lsu_fifo_inst/upd_s_tvalid
add wave -noupdate -height 19 -group lsu_fifo /exec_tb/uut/lsu_inst/lsu_fifo_inst/upd_s_taddr
add wave -noupdate -height 19 -group lsu_fifo /exec_tb/uut/lsu_inst/lsu_fifo_inst/upd_s_tdata
add wave -noupdate -height 19 -group lsu_fifo /exec_tb/uut/lsu_inst/lsu_fifo_inst/fifo_m_tvalid
add wave -noupdate -height 19 -group lsu_fifo /exec_tb/uut/lsu_inst/lsu_fifo_inst/fifo_m_tready
add wave -noupdate -height 19 -group lsu_fifo /exec_tb/uut/lsu_inst/lsu_fifo_inst/fifo_m_tdata
add wave -noupdate -height 19 -group lsu_fifo /exec_tb/uut/lsu_inst/lsu_fifo_inst/wr_addr
add wave -noupdate -height 19 -group lsu_fifo /exec_tb/uut/lsu_inst/lsu_fifo_inst/wr_addr_next
add wave -noupdate -height 19 -group lsu_fifo /exec_tb/uut/lsu_inst/lsu_fifo_inst/rd_addr
add wave -noupdate -height 19 -group lsu_fifo /exec_tb/uut/lsu_inst/lsu_fifo_inst/rd_addr_next
add wave -noupdate -height 19 -group lsu_fifo /exec_tb/uut/lsu_inst/lsu_fifo_inst/fifo_ram_valid
add wave -noupdate -height 19 -group lsu_fifo /exec_tb/uut/lsu_inst/lsu_fifo_inst/fifo_ram_data
add wave -noupdate -height 19 -group lsu_fifo /exec_tb/uut/lsu_inst/lsu_fifo_inst/q_thit
add wave -noupdate -height 19 -group lsu_fifo /exec_tb/uut/lsu_inst/lsu_fifo_inst/q_tdata
add wave -noupdate -height 19 -group lsu_fifo /exec_tb/uut/lsu_inst/lsu_fifo_inst/wr_data_tvalid
add wave -noupdate -height 19 -group lsu_fifo /exec_tb/uut/lsu_inst/lsu_fifo_inst/wr_data_tready
add wave -noupdate -height 19 -group lsu_fifo /exec_tb/uut/lsu_inst/lsu_fifo_inst/wr_data_tdata
add wave -noupdate -height 19 -group lsu_fifo /exec_tb/uut/lsu_inst/lsu_fifo_inst/wr_data_thit
add wave -noupdate -height 19 -group lsu_fifo /exec_tb/uut/lsu_inst/lsu_fifo_inst/data_tvalid
add wave -noupdate -height 19 -group lsu_fifo /exec_tb/uut/lsu_inst/lsu_fifo_inst/data_tready
add wave -noupdate -height 19 -group lsu_fifo /exec_tb/uut/lsu_inst/lsu_fifo_inst/out_tvalid
add wave -noupdate -height 19 -group lsu_fifo /exec_tb/uut/lsu_inst/lsu_fifo_inst/out_tready
add wave -noupdate -height 19 -group lsu_fifo /exec_tb/uut/lsu_inst/lsu_fifo_inst/out_tdata
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {455000 ps} 0}
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
WaveRestoreZoom {11415 ps} {1323919 ps}
