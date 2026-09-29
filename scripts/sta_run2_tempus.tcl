# Run 2 signoff STA in Tempus
# Run from ~/int8-cnn-accelerator/runs/tempus_run2 :
#   tempus -files ../../scripts/sta_run2_tempus.tcl
set root /home/tumberpl/int8-cnn-accelerator
set pnr  $root/runs/innovus_run2/out
file mkdir rpt

# Same libraries, RC corners, SDC and views as the Innovus run
read_view_definition $root/runs/innovus_run2/mmmc_run2.tcl
read_verilog $pnr/accel_top_run2.v
set_top_module accel_top
set_analysis_view -setup {setup_view} -hold {hold_view}

# Routed parasitics extracted by Innovus, one file per corner
read_spef -rc_corner rc_125 $pnr/accel_top_run2_rc125.spef
read_spef -rc_corner rc_0   $pnr/accel_top_run2_rc0.spef

# Same analysis settings as Innovus post-route: OCV + CPPR, SI on
set_analysis_mode -analysisType onChipVariation -cppr both
set_delay_cal_mode -siAware true

check_timing -verbose              > rpt/check_timing.rpt
update_timing -full
report_analysis_summary            > rpt/analysis_summary.rpt
report_timing -late  -max_paths 20 > rpt/setup_paths.rpt
report_timing -early -max_paths 20 > rpt/hold_paths.rpt
report_constraint -all_violators   > rpt/all_violators.rpt

puts "=================== TEMPUS RUN 2 ==================="
foreach {lbl opt} {SETUP -late HOLD -early} {
  if {[catch {puts "$lbl worst slack: [get_property [report_timing $opt -collection -max_paths 1] slack] ns"}]} {
    puts "$lbl: see rpt/analysis_summary.rpt"
  }
}
puts "===================================================="
