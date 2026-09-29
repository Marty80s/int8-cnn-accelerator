# ---------------------------------------------------------------------------
# synth_sweep.tcl - one Genus synthesis of accel_top at clock period $PERIOD.
# Same flow as scripts/synth_run2.tcl (clock gating on, BUFX2 dont_use);
# only the SDC period (and I/O max delays) change.
#
# Called by run_sweep.tcsh, one Genus process per period:
#   env PERIOD=2.5 genus -files scripts/sweep/synth_sweep.tcl
# Optional env (defaults reproduce Run 2):
#   SYN_EFFORT  medium | high
#   CG          1 = clock gating on (default), 0 = off      (experiment E2)
#   PIPE        0 = original MAC (default), 1 = pipelined MAC (experiment E4)
# ---------------------------------------------------------------------------
set root   /home/tumberpl/int8-cnn-accelerator
set P      $::env(PERIOD)
set effort [expr {[info exists ::env(SYN_EFFORT)] ? $::env(SYN_EFFORT) : "medium"}]
set cg     [expr {[info exists ::env(CG)]   ? $::env(CG)   : 1}]
set pipe   [expr {[info exists ::env(PIPE)] ? $::env(PIPE) : 0}]
# Folder name: p<period>[_pipe][_nocg], e.g. p2.5, p2.5_pipe, p10.0_nocg
set tag    p$P[expr {$pipe ? "_pipe" : ""}][expr {$cg ? "" : "_nocg"}]
set out    $root/runs/sweep/$tag
file mkdir $out

source $root/scripts/sweep/sdc_scale.tcl
sdc_scale $root/constraints/accel_top.sdc $out/accel_top_p$P.sdc $P

set lib /opt/eda/cadence/local/gsclib045_all/lan/flow/t1u1/reference_libs/GPDK045/gsclib045_all_v4.4/gsclib045/timing/slow_vdd1v0_basicCells.lib
set_db library $lib
set_db [get_db lib_cells */BUFX2] .dont_use true
set_db lp_insert_clock_gating [expr {$cg ? true : false}]

set cfg [expr {$pipe ? [list $root/rtl/cfg_mac_pipe.svh] : {}}]
read_hdl -sv [list {*}$cfg \
    $root/rtl/mac_int8.sv \
    $root/rtl/mac_array_4x4.sv \
    $root/rtl/matmul_4x4_k.sv \
    $root/rtl/operand_memory.sv \
    $root/rtl/operand_reader.sv \
    $root/rtl/accel_top.sv]
elaborate accel_top
read_sdc $out/accel_top_p$P.sdc

set_db syn_generic_effort $effort
set_db syn_map_effort     $effort
set_db syn_opt_effort     $effort

set t0 [clock seconds]
syn_generic
syn_map
syn_opt
set runtime [expr {[clock seconds] - $t0}]

report_timing -max_paths 5 > $out/timing.rpt
report_area                > $out/area.rpt
report_gates               > $out/gates.rpt
report_power               > $out/power.rpt
report_clock_gating        > $out/clock_gating.rpt
report_qor                 > $out/qor.rpt
write_hdl > $out/accel_top_mapped.v
write_sdc > $out/accel_top_mapped.sdc

# ---- one CSV line for the sweep summary (best effort; NA if a field is not found)
proc grab {file re} {
  if {[catch {set fh [open $file r]; set txt [read $fh]; close $fh}]} { return NA }
  if {[regexp -line -- $re $txt -> v]} { return $v }
  return NA
}
set wns NA
catch {set wns [get_db current_design .slack]}
if {$wns eq "" || $wns eq "NA"} { set wns [grab $out/timing.rpt {[Ss]lack\s*:?=?\s*(-?[0-9.]+)}] }
set area  [grab $out/area.rpt  {^\s*accel_top\s+\S*\s*([0-9.]+)\s+[0-9.]+\s+[0-9.]+}]
set cells [grab $out/gates.rpt {^\s*total\s+([0-9]+)}]
set pwr   [grab $out/power.rpt {^\s*Subtotal\s+\S+\s+\S+\s+\S+\s+(\S+)}]
set freq  [format %.1f [expr {1000.0 / $P}]]
set fh [open $out/result.csv w]
puts $fh "$P,$freq,$wns,$area,$cells,$pwr,$runtime,$pipe,$cg"
close $fh
puts "SWEEP RESULT $tag period=$P ns ($freq MHz) wns=$wns area=$area cells=$cells power=$pwr runtime=${runtime}s"
exit
