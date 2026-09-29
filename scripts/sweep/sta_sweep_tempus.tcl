# ---------------------------------------------------------------------------
# sta_sweep_tempus.tcl - Tempus signoff STA for one pnr_full.tcl run.
# Same settings as scripts/sta_run2_tempus.tcl (OCV + CPPR, SI, propagated
# clock, 45 nm), pointed at runs/pnr_sweep/<tag>.
#
#   env PERIOD : clock period of that run, e.g. 2.22
#   env TAG    : run folder name (default p$PERIOD), e.g. p2.0_pipe
# Run from a fresh folder, e.g. runs/tempus_sweep/p2.22 :
#   snps_container /opt/eda/cadence/SSV211/bin/tempus -files ../../../scripts/sweep/sta_sweep_tempus.tcl
# ---------------------------------------------------------------------------
set root /home/tumberpl/int8-cnn-accelerator
set P    $::env(PERIOD)
set tag  [expr {[info exists ::env(TAG)] ? $::env(TAG) : "p$P"}]
set pnr  $root/runs/pnr_sweep/$tag
file mkdir rpt

# MMMC file written by pnr_full.tcl (points at the scaled SDC for this period)
read_view_definition $pnr/mmmc_p$P.tcl
read_verilog $pnr/out/accel_top_p$P.v
set_top_module accel_top
set_analysis_view -setup {setup_view} -hold {hold_view}
read_spef -rc_corner rc_125 $pnr/out/accel_top_p${P}_rc125.spef
read_spef -rc_corner rc_0   $pnr/out/accel_top_p${P}_rc0.spef

set_design_mode -process 45
set_interactive_constraint_modes [all_constraint_modes]
set_propagated_clock [all_clocks]
set_interactive_constraint_modes {}

set_analysis_mode -analysisType onChipVariation -cppr both
set_delay_cal_mode -siAware true

check_timing -verbose              > rpt/check_timing.rpt
update_timing -full
report_analysis_summary            > rpt/analysis_summary.rpt
report_timing -late  -max_paths 20 > rpt/setup_paths.rpt
report_timing -early -max_paths 20 > rpt/hold_paths.rpt
report_constraint -all_violators   > rpt/all_violators.rpt

proc worst {opt} {
  if {[catch {set s [get_property [report_timing $opt -collection -max_paths 1] slack]}]} { return NA }
  return $s
}
set setup [worst -late]
set hold  [worst -early]
set fh [open tempus_result.csv w]
puts $fh "$tag,$P,[format %.1f [expr {1000.0 / $P}]],$setup,$hold"
close $fh
puts "=================== TEMPUS $tag ==================="
puts "Clock      : $P ns ([format %.1f [expr {1000.0 / $P}]] MHz)"
puts "Setup WNS  : $setup ns   (signoff: SI + OCV + CPPR, propagated clock)"
puts "Hold WNS   : $hold ns"
puts "==================================================="
exit
