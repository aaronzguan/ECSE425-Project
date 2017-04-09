proc AddWaves {} {

	add wave -position end sim:/testbench/clock
	add wave -position end sim:/testbench/c_wait_request
	add wave -position end sim:/testbench/programend
	add wave -position end sim:/testbench/readfinish
	add wave -position end sim:/testbench/mem_data_stall
	add wave -position end sim:/testbench/reset
	add wave -position end sim:/testbench/insert_stall
	add wave -position end sim:/testbench/branch_addr
	add wave -position end sim:/testbench/branch_taken
	add wave -position end sim:/testbench/s_waitrequest_inst
	add wave -position end sim:/testbench/s_readdata_inst
	add wave -position end sim:/testbench/mem_data_stall
	add wave -position end sim:/testbench/ismiss
	add wave -position end sim:/testbench/inst_addr
	add wave -position end sim:/testbench/inst
	add wave -position end sim:/testbench/writeback_register_address
	add wave -position end sim:/testbench/writeback_data
	add wave -position end sim:/testbench/EX_control_buffer_from_ex
	add wave -position end sim:/testbench/jump_addr
	add wave -position end sim:/testbench/inst_addr_from_id
	add wave -position end sim:/testbench/rs
	add wave -position end sim:/testbench/rt
	add wave -position end sim:/testbench/des_addr_from_id
	add wave -position end sim:/testbench/funct_from_id
	add wave -position end sim:/testbench/signExtImm
	add wave -position end sim:/testbench/opcode_bt_IdnEx
	add wave -position end sim:/testbench/EX_control_buffer_from_id
	add wave -position end sim:/testbench/MEM_control_buffer_from_id
	add wave -position end sim:/testbench/WB_control_buffer_from_id
	add wave -position end sim:/testbench/MEM_control_buffer_from_mem
	add wave -position end sim:/testbench/WB_control_buffer_from_wb
	add wave -position end sim:/testbench/opcode_bt_ExnMem
	add wave -position end sim:/testbench/ALU_result_from_ex
	add wave -position end sim:/testbench/des_addr_from_ex
	add wave -position end sim:/testbench/rt_data_from_ex
	add wave -position end sim:/testbench/bran_taken_from_ex
	add wave -position end sim:/testbench/bran_addr_from_ex
	add wave -position end sim:/testbench/MEM_control_buffer_from_ex
	add wave -position end sim:/testbench/WB_control_buffer_from_ex
	add wave -position end sim:/testbench/dc_readdata_data
	add wave -position end sim:/testbench/dc_s_waitrequest	
	add wave -position end sim:/testbench/opcode_bt_MemnWb
	add wave -position end sim:/testbench/memory_data
	add wave -position end sim:/testbench/alu_result_from_mem
	add wave -position end sim:/testbench/des_addr_from_mem
	add wave -position end sim:/testbench/WB_control_buffer_from_mem
	add wave -position end sim:/testbench/ic_s_addr
	add wave -position end sim:/testbench/ic_s_read
	add wave -position end sim:/testbench/m_readdata
	add wave -position end sim:/testbench/ic_m_waitrequest
	add wave -position end sim:/testbench/dc_s_addr
	add wave -position end sim:/testbench/dc_s_read
	add wave -position end sim:/testbench/dc_s_write
	add wave -position end sim:/testbench/dc_s_writedata
	add wave -position end sim:/testbench/dc_m_waitrequest
	add wave -position end sim:/testbench/writedata_instcache
	add wave -position end sim:/testbench/address_instcache
	add wave -position end sim:/testbench/memwrite_instcache
	add wave -position end sim:/testbench/memread_instcache
	add wave -position end sim:/testbench/writedata_datacache
	add wave -position end sim:/testbench/address_datacache
	add wave -position end sim:/testbench/memwrite_datacache
	add wave -position end sim:/testbench/memread_datacache
}

vlib work

vcom testbench.vhd
vcom IF.vhd
vcom IDnBuffer.vhd
vcom EX.vhd
vcom DataMem.vhd
vcom WB.vhd
vcom InstCache.vhd
vcom DataCache.vhd
vcom memory.vhd

vsim testbench

force -deposit clock 0 0 ns, 1 0.5 ns -repeat 1 ns

AddWaves

run 10000ns
