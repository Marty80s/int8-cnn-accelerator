set log file lec_rtl2syn.log -replace
read library -liberty -both /opt/eda/cadence/local/gsclib045_all/lan/flow/t1u1/reference_libs/GPDK045/gsclib045_all_v4.4/gsclib045/timing/slow_vdd1v0_basicCells.lib
read design -systemverilog -golden -root accel_top ../../rtl/mac_int8.sv ../../rtl/mac_array_4x4.sv ../../rtl/matmul_4x4_k.sv ../../rtl/operand_memory.sv ../../rtl/operand_reader.sv ../../rtl/accel_top.sv
read design -verilog -revised -root accel_top ../synthesis_cg/accel_top_mapped.v
set undefined cell black_box -noascend -both
set flatten model -seq_constant -gated_clock
set system mode lec
analyze datapath -merge -verbose
add compared points -all
compare
report statistics
report compare data -summary
report unmapped points -summary
exit -force
