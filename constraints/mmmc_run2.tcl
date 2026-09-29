# Version:1.0 MMMC View Definition File
# Do Not Remove Above Line
create_rc_corner -name rc_125 -T {125} -preRoute_res {1.0} -preRoute_cap {1.0} -preRoute_clkres {0.0} -preRoute_clkcap {0.0} -postRoute_res {1.0} -postRoute_cap {1.0} -postRoute_xcap {1.0} -postRoute_clkres {0.0} -postRoute_clkcap {0.0} -qx_tech_file {/opt/eda/cadence/local/gsclib045_all/lan/flow/t1u1/reference_libs/GPDK045/gsclib045_all_v4.4/gsclib045/qrc/qx/gpdk045.tch}
create_rc_corner -name rc_0 -T {0} -preRoute_res {1.0} -preRoute_cap {1.0} -preRoute_clkres {0.0} -preRoute_clkcap {0.0} -postRoute_res {1.0} -postRoute_cap {1.0} -postRoute_xcap {1.0} -postRoute_clkres {0.0} -postRoute_clkcap {0.0} -qx_tech_file {/opt/eda/cadence/local/gsclib045_all/lan/flow/t1u1/reference_libs/GPDK045/gsclib045_all_v4.4/gsclib045/qrc/qx/gpdk045.tch}
create_library_set -name libs_slow -timing {/opt/eda/cadence/local/gsclib045_all/lan/flow/t1u1/reference_libs/GPDK045/gsclib045_all_v4.4/gsclib045/timing/slow_vdd1v0_basicCells.lib}
create_library_set -name libs_fast -timing {/opt/eda/cadence/local/gsclib045_all/lan/flow/t1u1/reference_libs/GPDK045/gsclib045_all_v4.4/gsclib045/timing/fast_vdd1v0_basicCells.lib}
create_constraint_mode -name functional -sdc_files {../synthesis_cg/accel_top_mapped.sdc}
create_delay_corner -name delay_slow -library_set {libs_slow} -rc_corner {rc_125}
create_delay_corner -name delay_fast -library_set {libs_fast} -rc_corner {rc_0}
create_analysis_view -name setup_view -constraint_mode {functional} -delay_corner {delay_slow}
create_analysis_view -name hold_view -constraint_mode {functional} -delay_corner {delay_fast}
set_analysis_view -setup {setup_view} -hold {hold_view}
