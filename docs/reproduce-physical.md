# Reproducing the recorded flow

The scripts are university-environment snapshots, not a standalone EDA distribution. This update imports source and evidence; it does not claim a fresh simulation or implementation run.

## Dependencies and setup

Use your licensed Cadence environment (recorded tools include Xcelium 23.09, Genus/Innovus/Tempus 21.19, and Conformal 23.10). Obtain the GSCLIB045 timing, LEF, and extraction views through your authorized installation.

Before running:

1. Adjust the project-root and technology paths in the scripts and `constraints/mmmc_run2.tcl` for your environment.
2. Provide the locally prepared `physical/lef/gsclib045_macro_bufx2_sitefix.lef` referenced by the PnR scripts. This library-derived view is intentionally not distributed here. Review compatibility against your installed library; the repository cannot reproduce its preparation from these scripts alone.
3. Place an adapted copy of `constraints/mmmc_run2.tcl` at `runs/innovus_run2/mmmc_run2.tcl`, the location currently read by the sweep script. The original template's baseline SDC path is relative to its run directory; the sweep replaces it with the selected period's SDC.
4. Keep generated outputs in `runs/`. Record the source commit, build flags, tool versions, and full commands for each new run.

## RTL

Use `scripts/run_commands.tcsh` for baseline block tests. `tb/tb_accel_top.sv` and `tb/tb_accel_top_accum.sv` cover identity and non-identity integration cases. The supplied accumulation PASS log is in `reports/evidence/accel-top-accumulation-pass.txt`.

The default `MAC_PIPE=0` selects the original MAC; the pipeline build selects `MAC_PIPE=1`. Synthesis uses `rtl/cfg_mac_pipe.svh` when `PIPE=1`. Verify both arithmetic and controller drain/completion behavior for the pipeline. Historical baseline passes do not establish a pipelined regression pass.

## Physical flow

- `scripts/sweep/run_sweep.tcsh` invokes Genus across clock periods.
- `scripts/sweep/synth_sweep.tcl` selects `PERIOD`, `PIPE`, `CG`, and synthesis effort and writes timing/area/power summaries.
- `scripts/sweep/pnr_full.tcl` reads the matching synthesis output. It supports `UTIL`, `MARGIN`, and `HOLD_MARGIN`; CTS I/O latency updating is disabled in the supplied snapshot.
- `scripts/sweep/sta_sweep_tempus.tcl` uses `PERIOD` and `TAG` to select the routed netlist, SPEF, and generated MMMC file.

Do not overwrite historical run directories. For example, a new attempt at the v5 operating point should use a new tag. The v5 reports record a 2 ns clock and `PIPE=1`, but the archive does not establish every original invocation/environment value; do not assume the current default optimization margins reproduce v5 bit-for-bit.

The LEC scripts currently reference `runs/synthesis_cg` and the earlier routed baseline. Adapt the golden/revised paths and pipeline configuration together before validating a new pipelined implementation.

## Acceptance checks

Inspect actual setup/hold path reports, all-violator reports, constraint coverage, and SPEF annotation warnings. Resolve or justify unconstrained endpoints rather than treating a positive CSV value or an empty summary as complete signoff. Record functional regression and LEC evidence for the same variant. For PPA comparisons, retain clock frequency, library/corner, activity assumptions, floorplan utilization, and whether area means die, core, or cell area.
