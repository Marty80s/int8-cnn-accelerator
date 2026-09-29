# ---------------------------------------------------------------------------
# pnr_full.tcl - full Innovus flow for accel_top at clock period $PERIOD,
# in one batch run. Same steps and settings as Run 2, plus setup optimization
# after CTS and after routing (Run 2 had 2.8 ns of slack and did not need it).
#
# Needs the synthesis from the sweep first (runs/sweep/p$PERIOD/).
# Run from anywhere in your Cadence tcsh:
#   mkdir -p ~/int8-cnn-accelerator/runs/pnr_sweep/p2.86
#   cd ~/int8-cnn-accelerator/runs/pnr_sweep/p2.86
#   setenv PERIOD 2.86
#   innovus -no_gui -files ../../../scripts/sweep/pnr_full.tcl -log pnr_p2.86
# ---------------------------------------------------------------------------
set root /home/tumberpl/int8-cnn-accelerator
set P    $::env(PERIOD)
# Optional env (defaults reproduce Run 2): UTIL (0.60, experiment E3),
# PIPE and CG (pick the matching synthesis from the sweep, E4 / E2)
set util [expr {[info exists ::env(UTIL)] ? $::env(UTIL) : 0.60}]
set pipe [expr {[info exists ::env(PIPE)] ? $::env(PIPE) : 0}]
set cg   [expr {[info exists ::env(CG)]   ? $::env(CG)   : 1}]
set margin [expr {[info exists ::env(MARGIN)] ? $::env(MARGIN) : 0.03}]
set syn  $root/runs/sweep/p$P[expr {$pipe ? "_pipe" : ""}][expr {$cg ? "" : "_nocg"}]
set out  [pwd]
file mkdir rpt out
setMultiCpuUsage -localCpu 4

# MMMC: copy of the Run 2 file with the SDC swapped for the scaled one
set fh [open $root/constraints/mmmc_run2.tcl r]; set mm [read $fh]; close $fh
set n [regsub -all {[^\s\{\}\"]+\.sdc} $mm $syn/accel_top_p$P.sdc mm]
if {$n == 0} { error "pnr_full: no .sdc path found in mmmc_run2.tcl" }
set fh [open $out/mmmc_p$P.tcl w]; puts $fh $mm; close $fh

# ---- init (as Run 2)
set init_verilog       $syn/accel_top_mapped.v
set init_top_cell      accel_top
set init_design_settop 1
set init_lef_file      [list /opt/eda/cadence/local/gsclib045_all/lan/flow/t1u1/reference_libs/GPDK045/gsclib045_all_v4.4/gsclib045/lef/gsclib045_tech.lef $root/physical/lef/gsclib045_macro_bufx2_sitefix.lef]
set init_mmmc_file     $out/mmmc_p$P.tcl
set init_pwr_net       VDD
set init_gnd_net       VSS
init_design
setDesignMode -process 45

# ---- floorplan and power grid (as Run 2)
floorPlan -site CoreSite -r 1.0 $util 10 10 10 10
globalNetConnect VDD -type pgpin -pin VDD -all -override
globalNetConnect VSS -type pgpin -pin VSS -all -override
addRing -nets {VDD VSS} -type core_rings -follow core -layer {top Metal11 bottom Metal11 left Metal10 right Metal10} -width {top 2 bottom 2 left 2 right 2} -spacing {top 1.5 bottom 1.5 left 1.5 right 1.5} -offset {top 1 bottom 1 left 1 right 1}
addStripe -nets {VDD VSS} -layer Metal10 -direction vertical -width 1 -spacing 1.5 -set_to_set_distance 40 -start_from left -start_offset 10
sroute -connect {corePin} -nets {VDD VSS} -allowJogging 1 -allowLayerChange 1 -layerChangeRange {Metal1 Metal11}

# ---- I/O pins: inputs left, outputs right, Metal3 (placed before placement this time)
set ins  [dbGet [dbGet -p top.terms.isInput 1].name]
set outs [dbGet [dbGet -p top.terms.isOutput 1].name]
setPinAssignMode -pinEditInBatch true
editPin -side Left  -layer Metal3 -spreadType side -fixOverlap 1 -pin $ins
editPin -side Right -layer Metal3 -spreadType side -fixOverlap 1 -pin $outs
setPinAssignMode -pinEditInBatch false
saveDesign $out/01_floorplan.enc

# ---- placement
place_opt_design -out_dir rpt/02_place
checkPlace rpt/02_checkPlace.rpt
timeDesign -preCTS -outDir rpt/02_preCTS
saveDesign $out/02_place.enc

# ---- CTS (clock buffers and inverters only, as Run 2)
set_ccopt_property buffer_cells   [dbGet -u head.libCells.name CLKBUF*]
set_ccopt_property inverter_cells [dbGet -u head.libCells.name CLKINV*]
set_ccopt_property update_io_latency false
create_ccopt_clock_tree_spec
ccopt_design -cts
timeDesign -postCTS -outDir rpt/03_postCTS

# ---- post-CTS: setup, then hold with DLY cells only (setup may not degrade), then DRV
setOptMode -setupTargetSlack $margin
optDesign -postCTS -outDir rpt/04_postCTS_setup
setOptMode -holdFixingCells [dbGet -u head.libCells.name DLY*] -fixHoldAllowSetupTnsDegrade false
optDesign -postCTS -hold -outDir rpt/04_postCTS_hold
optDesign -postCTS -drv  -outDir rpt/04_postCTS_drv
saveDesign $out/04_cts.enc

# ---- routing
setNanoRouteMode -routeWithTimingDriven true -routeWithSiDriven true
routeDesign -globalDetail
saveDesign $out/05_route.enc

# ---- post-route with SI, OCV and CPPR (as Run 2) + setup pass
setExtractRCMode -engine postRoute
setAnalysisMode -analysisType onChipVariation -cppr both
setDelayCalMode -SIAware true
optDesign -postRoute        -outDir rpt/06_postRoute_setup
optDesign -postRoute -hold  -outDir rpt/06_postRoute_hold
optDesign -postRoute -drv   -outDir rpt/06_postRoute_drv
timeDesign -postRoute       -outDir rpt/06_final_setup
timeDesign -postRoute -hold -outDir rpt/06_final_hold
saveDesign $out/06_postroute.enc

# ---- fillers, power nets, verification (as Run 2)
addFiller -cell [dbGet -u head.libCells.name FILL*] -prefix FILLER
globalNetConnect VDD -type pgpin -pin VDD -all -override
globalNetConnect VSS -type pgpin -pin VSS -all -override
applyGlobalNets
verify_drc -limit 100000 -report rpt/07_drc.rpt
verifyConnectivity -type all -error 100000 -report rpt/07_conn.rpt
verifyProcessAntenna -report rpt/07_antenna.rpt
report_power -outfile rpt/07_power.rpt
saveDesign $out/07_final.enc

# ---- outputs for Tempus / LEC / gate-level sim
saveNetlist out/accel_top_p$P.v
extractRC
rcOut -spef out/accel_top_p${P}_rc125.spef -rc_corner rc_125
rcOut -spef out/accel_top_p${P}_rc0.spef   -rc_corner rc_0
write_sdf -recompute_delay_calc out/accel_top_p$P.sdf

# ---- summary
proc worst {opt} {
  if {[catch {set s [get_property [report_timing $opt -collection -max_paths 1] slack]}]} { return NA }
  return $s
}
set setup [worst -late]
set hold  [worst -early]
set fh [open out/pnr_result.csv w]
puts $fh "$P,[format %.1f [expr {1000.0 / $P}]],$setup,$hold,[llength [dbGet top.insts]],$util,$pipe,$cg"
close $fh
puts "=================== PNR p$P ==================="
puts "Variant      : util $util  pipe $pipe  cg $cg"
puts "Clock        : $P ns ([format %.1f [expr {1000.0 / $P}]] MHz)"
puts "Setup WNS    : $setup ns   (post-route, SI + OCV + CPPR)"
puts "Hold WNS     : $hold ns"
puts "Die box      : [dbGet top.fPlan.box]"
puts "Instances    : [llength [dbGet top.insts]] (incl. fillers)"
puts "DRC / conn / antenna : see rpt/07_*.rpt"
puts "==============================================="
exit
