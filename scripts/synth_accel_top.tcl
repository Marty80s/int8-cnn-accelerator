# Locate the repository from this script's location.
set root [file normalize [file join [file dirname [info script]] ..]]
set out  [file join $root runs synthesis]

file mkdir $out

# Previously identified university standard-cell library:
# slow process, 0.9 V, 125 C.
set lib /opt/eda/cadence/local/gsclib045_all/lan/flow/t1u1/reference_libs/GPDK045/gsclib045_all_v4.4/gsclib045/timing/slow_vdd1v0_basicCells.lib

if {![file readable $lib]} {
    error "Cannot read standard-cell library: $lib"
}

set_db library $lib

set_db syn_generic_effort medium
set_db syn_map_effort medium
set_db syn_opt_effort medium

# Read only synthesizable RTL, not testbenches.
set rtl_files [list \
    [file join $root rtl mac_int8.sv] \
    [file join $root rtl mac_array_4x4.sv] \
    [file join $root rtl matmul_4x4_k.sv] \
    [file join $root rtl operand_memory.sv] \
    [file join $root rtl operand_reader.sv] \
    [file join $root rtl accel_top.sv] \
]

foreach rtl_file $rtl_files {
    if {![file readable $rtl_file]} {
        error "Cannot read RTL file: $rtl_file"
    }
    read_hdl -sv $rtl_file
}

elaborate accel_top

check_design -unresolved > $out/elaboration_check.rpt

read_sdc [file join $root constraints accel_top.sdc]
check_timing_intent > $out/timing_intent.rpt

# Synthesize and map to the selected standard cells.
syn_generic
syn_map
syn_opt

# Save the mapped design and its timing constraints.
write_hdl > $out/accel_top_mapped.v
write_sdc > $out/accel_top_mapped.sdc

# Baseline reports.
report_area > $out/area.rpt
report_gates > $out/gates.rpt
report_timing > $out/timing.rpt
report_power > $out/power_estimate.rpt
report_messages > $out/messages.rpt

puts "BASELINE SYNTHESIS SCRIPT FINISHED"
puts "Reports and netlist: $out"

exit
