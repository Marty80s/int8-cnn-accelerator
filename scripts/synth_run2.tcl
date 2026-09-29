set root /home/tumberpl/int8-cnn-accelerator
set out  $root/runs/synthesis_cg
file mkdir $out
set lib /opt/eda/cadence/local/gsclib045_all/lan/flow/t1u1/reference_libs/GPDK045/gsclib045_all_v4.4/gsclib045/timing/slow_vdd1v0_basicCells.lib
set_db library $lib
# RUN 2: never map to BUFX2 (double-height site problem in Run 1)
set_db [get_db lib_cells */BUFX2] .dont_use true
# RUN 2: insert integrated clock-gating cells
set_db lp_insert_clock_gating true
read_hdl -sv [list $root/rtl/mac_int8.sv $root/rtl/mac_array_4x4.sv $root/rtl/matmul_4x4_k.sv $root/rtl/operand_memory.sv $root/rtl/operand_reader.sv $root/rtl/accel_top.sv]
elaborate accel_top
check_design -unresolved > $out/design_check_elab.rpt
read_sdc $root/constraints/accel_top.sdc
check_timing_intent > $out/timing_intent.rpt
set_db syn_generic_effort medium
set_db syn_map_effort     medium
set_db syn_opt_effort     medium
syn_generic
syn_map
syn_opt
report_area          > $out/area_opt.rpt
report_gates         > $out/gates_opt.rpt
report_timing        > $out/timing_opt.rpt
report_power         > $out/power_estimate.rpt
report_clock_gating  > $out/clock_gating.rpt
check_design -unresolved > $out/design_check_opt.rpt
check_timing_intent      > $out/timing_intent_opt.rpt
write_hdl > $out/accel_top_mapped.v
write_sdc > $out/accel_top_mapped.sdc
puts "RUN2 DONE: outputs in $out"
exit
