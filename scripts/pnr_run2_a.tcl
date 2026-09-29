set root /home/tumberpl/int8-cnn-accelerator
setMultiCpuUsage -localCpu 4
file mkdir rpt
set init_verilog      $root/runs/synthesis_cg/accel_top_mapped.v
set init_top_cell     accel_top
set init_design_settop 1
set init_lef_file     [list /opt/eda/cadence/local/gsclib045_all/lan/flow/t1u1/reference_libs/GPDK045/gsclib045_all_v4.4/gsclib045/lef/gsclib045_tech.lef $root/physical/lef/gsclib045_macro_bufx2_sitefix.lef]
set init_mmmc_file    $root/runs/innovus_run2/mmmc_run2.tcl
set init_pwr_net      VDD
set init_gnd_net      VSS
init_design
setDesignMode -process 45
saveDesign 00_init.enc
floorPlan -site CoreSite -r 1.0 0.60 10 10 10 10
globalNetConnect VDD -type pgpin -pin VDD -all -override
globalNetConnect VSS -type pgpin -pin VSS -all -override
addRing -nets {VDD VSS} -type core_rings -follow core -layer {top Metal11 bottom Metal11 left Metal10 right Metal10} -width {top 2 bottom 2 left 2 right 2} -spacing {top 1.5 bottom 1.5 left 1.5 right 1.5} -offset {top 1 bottom 1 left 1 right 1}
addStripe -nets {VDD VSS} -layer Metal10 -direction vertical -width 1 -spacing 1.5 -set_to_set_distance 40 -start_from left -start_offset 10
sroute -connect {corePin} -nets {VDD VSS} -allowJogging 1 -allowLayerChange 1 -layerChangeRange {Metal1 Metal11}
verifyConnectivity -net {VDD VSS} -type special -error 100000 -report rpt/02_pg_conn.rpt
saveDesign 02_power.enc
place_opt_design -out_dir rpt/03_place
checkPlace rpt/03_checkPlace.rpt
timeDesign -preCTS -outDir rpt/03_preCTS
saveDesign 03_place.enc
puts "=================== STAGE A SUMMARY ==================="
puts "Die box           : [dbGet top.fPlan.box]"
puts "Std cells (insts) : [llength [dbGet top.insts]]"
puts "ICG cells         : [llength [dbGet -e -p2 top.insts.cell.name TLAT*]]"
puts "CoreSiteDouble    : [llength [dbGet -e -p2 top.insts.cell.site.name CoreSiteDouble]]"
puts "======================================================="
