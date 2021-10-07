onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/clk
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/resetn
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/lsu_req_s_tvalid
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/lsu_req_s_tready
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/lsu_req_s_tcmd
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/lsu_req_s_taddr
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/lsu_req_s_twidth
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/lsu_req_s_tdata
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/dcache_s_tvalid
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/dcache_s_tdata
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/mem_req_m_tvalid
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/mem_req_m_tready
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/mem_req_m_tdata
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/mem_rd_s_tvalid
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/mem_rd_s_tdata
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/lsu_rd_m_tvalid
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/lsu_rd_m_tready
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/lsu_rd_m_tdata
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/lsu_req_tvalid
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/lsu_req_tready
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/req_buf_tvalid
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/req_buf_tready
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/req_buf_tcmd
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/req_buf_twidth
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/req_buf_taddr
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/req_buf_tdata
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/req_buf_tupd_addr
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/mem_req_tvalid
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/mem_req_tready
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/mem_req_tlast
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/mem_req_tcmd
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/mem_req_taddr
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/mem_req_tmask
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/mem_req_tdata
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/add_s_tvalid
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/add_s_tready
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/add_s_taddr
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/add_s_tdata
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/fifo_0_s_tvalid
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/fifo_0_s_tready
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/fifo_0_s_tdata
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/fifo_0_m_tvalid
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/fifo_0_m_tready
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/fifo_0_m_tdata
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/upd_s_tvalid
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/upd_s_tdata
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/upd_s_taddr
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/fifo_1_m_tvalid
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/fifo_1_m_tready
add wave -noupdate -height 19 -group lsu /exec_bin/uut/lsu_inst/fifo_1_m_tdata
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/clk
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/resetn
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/jmp_lock_s_tvalid
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/rr_s_tvalid
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/rr_s_tready
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/rr_s_tdata
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/rr_s_tuser
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/micro_m_tvalid
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/micro_m_tready
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/micro_m_tdata
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/bx_s_tdata
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/cx_s_tdata
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/dx_s_tdata
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/bp_s_tdata
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/sp_s_tdata
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/di_s_tdata
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/si_s_tdata
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/flags_s_tdata
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/ax_m_wr_tvalid
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/ax_m_wr_tdata
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/ax_m_wr_tmask
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/bx_m_wr_tvalid
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/bx_m_wr_tdata
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/bx_m_wr_tmask
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/cx_m_wr_tvalid
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/cx_m_wr_tdata
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/cx_m_wr_tmask
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/cx_m_wr_tkeep_lock
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/dx_m_wr_tvalid
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/dx_m_wr_tdata
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/dx_m_wr_tmask
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/bp_m_wr_tvalid
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/bp_m_wr_tdata
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/sp_m_wr_tvalid
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/sp_m_wr_tdata
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/di_m_wr_tvalid
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/di_m_wr_tdata
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/si_m_wr_tvalid
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/si_m_wr_tdata
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/ds_m_wr_tvalid
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/ds_m_wr_tdata
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/ss_m_wr_tvalid
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/ss_m_wr_tdata
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/es_m_wr_tvalid
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/es_m_wr_tdata
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/jmp_lock_m_lock_tvalid
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/rr_tvalid
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/rr_tready
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/rr_tdata
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/rr_tuser
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/micro_tvalid
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/micro_tready
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/micro_cnt
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/micro_tdata
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/rr_tdata_buf
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/rr_tuser_buf
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/rr_tuser_buf_ip_next
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/fast_instruction_fl
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/ea_val_plus_disp_next
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/ea_val_plus_disp
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/rep_mode
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/rep_lock
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/rep_code
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/rep_cx_cnt
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/rep_upd_cx_tvalid
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/FLAG_DF
add wave -noupdate -height 19 -group ifeu /exec_bin/uut/ifeu_inst/FLAG_ZF
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/clk
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/resetn
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/instr_s_tvalid
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/instr_s_tready
add wave -noupdate -height 19 -group rr -radix decimal /exec_bin/uut/register_reader_inst/dbg_instr_hs_cnt
add wave -noupdate -height 19 -group rr -expand /exec_bin/uut/register_reader_inst/instr_s_tdata
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/instr_s_tuser
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/ds_s_tvalid
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/ds_s_tdata
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/ds_m_lock_tvalid
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/ss_s_tvalid
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/ss_s_tdata
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/ss_m_lock_tvalid
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/es_s_tvalid
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/es_s_tdata
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/es_m_lock_tvalid
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/ax_s_tvalid
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/ax_s_tdata
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/ax_m_lock_tvalid
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/bx_s_tvalid
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/bx_s_tdata
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/bx_m_lock_tvalid
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/cx_s_tvalid
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/cx_s_tdata
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/cx_m_lock_tvalid
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/dx_s_tvalid
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/dx_s_tdata
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/dx_m_lock_tvalid
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/sp_s_tvalid
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/sp_s_tdata
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/sp_m_lock_tvalid
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/bp_s_tvalid
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/bp_s_tdata
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/bp_m_lock_tvalid
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/si_s_tvalid
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/si_s_tdata
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/si_m_lock_tvalid
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/di_s_tvalid
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/di_s_tdata
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/di_m_lock_tvalid
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/flags_s_tvalid
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/flags_s_tdata
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/flags_m_lock_tvalid
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/rr_m_tvalid
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/rr_m_tready
add wave -noupdate -height 19 -group rr -expand /exec_bin/uut/register_reader_inst/rr_m_tdata
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/rr_m_tuser
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/instr_tvalid
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/instr_tready
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/instr_tdata
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/instr_tuser
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/rr_tvalid
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/rr_tready
add wave -noupdate -height 19 -group rr -expand /exec_bin/uut/register_reader_inst/rr_tdata
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/rr_tuser
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/sreg_tvalid
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/sreg_tdata
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/dreg_tvalid
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/dreg_tdata
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/ea_tvalid
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/ea_tdata
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/intr_mask
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/seg_tvalid
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/seg_tdata
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/seg_override_tvalid
add wave -noupdate -height 19 -group rr /exec_bin/uut/register_reader_inst/seg_override_tdata
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/clk
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/resetn
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/micro_s_tvalid
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/micro_s_tready
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/micro_s_tdata
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/lsu_rd_s_tvalid
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/lsu_rd_s_tready
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/lsu_rd_s_tdata
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/flags_s_tdata
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/ax_m_wr_tvalid
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/ax_m_wr_tdata
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/ax_m_wr_tmask
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/bx_m_wr_tvalid
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/bx_m_wr_tdata
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/bx_m_wr_tmask
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/cx_m_wr_tvalid
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/cx_m_wr_tdata
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/cx_m_wr_tmask
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/dx_m_wr_tvalid
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/dx_m_wr_tdata
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/dx_m_wr_tmask
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/bp_m_wr_tvalid
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/bp_m_wr_tdata
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/sp_m_wr_tvalid
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/sp_m_wr_tdata
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/di_m_wr_tvalid
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/di_m_wr_tdata
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/si_m_wr_tvalid
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/si_m_wr_tdata
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/ds_m_wr_tvalid
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/ds_m_wr_tdata
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/es_m_wr_tvalid
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/es_m_wr_tdata
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/ss_m_wr_tvalid
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/ss_m_wr_tdata
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/si_m_wr_tkeep_lock
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/di_m_wr_tkeep_lock
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/flags_m_wr_tvalid
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/flags_m_wr_tdata
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/jump_m_tvalid
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/jump_m_tdata
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/jmp_lock_m_wr_tvalid
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/lsu_req_m_tvalid
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/lsu_req_m_tready
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/lsu_req_m_tcmd
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/lsu_req_m_twidth
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/lsu_req_m_taddr
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/lsu_req_m_tdata
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/micro_tvalid
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/micro_tready
add wave -noupdate -height 19 -group mexec -expand /exec_bin/uut/mexec_inst/micro_tdata
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/alu_tvalid
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/alu_tdata
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/lsu_req_tvalid
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/lsu_req_tready
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/lsu_req_tcmd
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/lsu_req_taddr
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/lsu_req_twidth
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/lsu_req_tdata
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/a_next
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/b_next
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/carry
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/add_next
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/adc_next
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/and_next
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/or_next
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/xor_next
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/flags_wr_be
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/flags_wr_new_val
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/flags_src
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/flags_wr_vector
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/flags_cf
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/flags_pf
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/flags_zf
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/flags_of
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/flags_sf
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/flags_af
add wave -noupdate -height 19 -group mexec /exec_bin/uut/mexec_inst/d_flags_m_wr_tvalid
add wave -noupdate -height 19 -group dcache /exec_bin/uut/dcache_inst/clk
add wave -noupdate -height 19 -group dcache /exec_bin/uut/dcache_inst/resetn
add wave -noupdate -height 19 -group dcache /exec_bin/uut/dcache_inst/lsu_req_s_tvalid
add wave -noupdate -height 19 -group dcache /exec_bin/uut/dcache_inst/lsu_req_s_tready
add wave -noupdate -height 19 -group dcache /exec_bin/uut/dcache_inst/lsu_req_s_tcmd
add wave -noupdate -height 19 -group dcache /exec_bin/uut/dcache_inst/lsu_req_s_taddr
add wave -noupdate -height 19 -group dcache /exec_bin/uut/dcache_inst/lsu_req_s_twidth
add wave -noupdate -height 19 -group dcache /exec_bin/uut/dcache_inst/lsu_req_s_tdata
add wave -noupdate -height 19 -group dcache /exec_bin/uut/dcache_inst/dcache_m_tvalid
add wave -noupdate -height 19 -group dcache /exec_bin/uut/dcache_inst/dcache_m_tdata
add wave -noupdate -height 19 -group dcache /exec_bin/uut/dcache_inst/d_valid
add wave -noupdate -height 19 -group dcache /exec_bin/uut/dcache_inst/d_tags
add wave -noupdate -height 19 -group dcache /exec_bin/uut/dcache_inst/d_data
add wave -noupdate -height 19 -group dcache /exec_bin/uut/dcache_inst/index
add wave -noupdate -height 19 -group dcache /exec_bin/uut/dcache_inst/tag
add wave -noupdate -height 19 -group dcache /exec_bin/uut/dcache_inst/CACHE_LINE_SIZE
add wave -noupdate -height 19 -group dcache /exec_bin/uut/dcache_inst/CACHE_LINE_WIDTH
add wave -noupdate -height 19 -group dram /exec_bin/sdram_test_model_inst/sdram_test_model_mem_inst/rdclken
add wave -noupdate -height 19 -group dram /exec_bin/sdram_test_model_inst/sdram_test_model_mem_inst/wrclock
add wave -noupdate -height 19 -group dram /exec_bin/sdram_test_model_inst/sdram_test_model_mem_inst/q
add wave -noupdate -height 19 -group dram /exec_bin/sdram_test_model_inst/sdram_test_model_mem_inst/wren
add wave -noupdate -height 19 -group dram /exec_bin/sdram_test_model_inst/sdram_test_model_mem_inst/read_address
add wave -noupdate -height 19 -group dram /exec_bin/sdram_test_model_inst/sdram_test_model_mem_inst/wraddress
add wave -noupdate -height 19 -group dram /exec_bin/sdram_test_model_inst/sdram_test_model_mem_inst/data
add wave -noupdate -height 19 -expand -group decoder /exec_bin/decoder_inst/clk
add wave -noupdate -height 19 -expand -group decoder /exec_bin/decoder_inst/resetn
add wave -noupdate -height 19 -expand -group decoder /exec_bin/decoder_inst/u8_s_tvalid
add wave -noupdate -height 19 -expand -group decoder /exec_bin/decoder_inst/u8_s_tready
add wave -noupdate -height 19 -expand -group decoder /exec_bin/decoder_inst/u8_s_tdata
add wave -noupdate -height 19 -expand -group decoder /exec_bin/decoder_inst/u8_s_tuser
add wave -noupdate -height 19 -expand -group decoder /exec_bin/decoder_inst/instr_m_tvalid
add wave -noupdate -height 19 -expand -group decoder /exec_bin/decoder_inst/instr_m_tready
add wave -noupdate -height 19 -expand -group decoder /exec_bin/decoder_inst/instr_m_tdata
add wave -noupdate -height 19 -expand -group decoder /exec_bin/decoder_inst/instr_m_tuser
add wave -noupdate -height 19 -expand -group decoder /exec_bin/decoder_inst/u8_tvalid
add wave -noupdate -height 19 -expand -group decoder /exec_bin/decoder_inst/u8_tready
add wave -noupdate -height 19 -expand -group decoder /exec_bin/decoder_inst/u8_tdata
add wave -noupdate -height 19 -expand -group decoder /exec_bin/decoder_inst/u8_tdata_rm
add wave -noupdate -height 19 -expand -group decoder /exec_bin/decoder_inst/u8_tdata_reg
add wave -noupdate -height 19 -expand -group decoder /exec_bin/decoder_inst/byte_pos_chain
add wave -noupdate -height 19 -expand -group decoder /exec_bin/decoder_inst/dbg_instr_hs_cnt
add wave -noupdate -height 19 -expand -group decoder /exec_bin/decoder_inst/instr_tvalid
add wave -noupdate -height 19 -expand -group decoder /exec_bin/decoder_inst/instr_tready
add wave -noupdate -height 19 -expand -group decoder /exec_bin/decoder_inst/instr_tdata
add wave -noupdate -height 19 -expand -group decoder /exec_bin/decoder_inst/instr_tuser
add wave -noupdate -height 19 -expand -group decoder /exec_bin/decoder_inst/byte0
add wave -noupdate -height 19 -expand -group decoder /exec_bin/decoder_inst/byte1
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {119096887 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 232
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
WaveRestoreZoom {0 ps} {126 us}
