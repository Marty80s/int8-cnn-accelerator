# Physical design and clock sweep

Updated from `int8_review_20261002_010807.zip`, captured October 2, 2026. Report timestamps identify the actual September runs. This supersedes the earlier status based on the v3 run; historical results remain below. No EDA analysis was rerun during import.

## Flow

`accel_top` is a 4x4 INT8 matrix engine with behavioral operand memory. The optional pipeline registers the product before accumulation. Genus performs synthesis and clock gating; Innovus performs floorplanning, power planning, placement, CTS, routing, and extraction; Tempus reads the routed netlist and SPEF.

The [STA script](../scripts/sweep/sta_sweep_tempus.tcl) and [recorded analysis settings](evidence/physical/tempus_sweep/p2.0_pipe_v5/analysis-settings.txt) enable propagated clocks, on-chip variation, CPPR, and SI-aware delay. The [v5 MMMC file](evidence/physical/pnr_sweep/p2.0_pipe_v5/mmmc_p2.0.tcl) defines slow/125 C setup and fast/0 C hold views. This is the recorded academic analysis scope, not exhaustive foundry signoff.

## Synthesis sweep

| Variant | Target | Reported Genus WNS | Cell area (um2) | Cells |
|---|---:|---:|---:|---:|
| Original MAC | 2.50 ns / 400 MHz | 0.0 ps | 136,034.399 | 37,838 |
| Original MAC | 2.22 ns / 450.5 MHz | 0.0 ps | 136,950.600 | 38,952 |
| Original MAC | 2.00 ns / 500 MHz | -217.7 ps | 137,834.208 | 39,988 |
| Pipelined MAC | 2.00 ns / 500 MHz | 0.0 ps | 137,049.660 | 39,433 |
| Pipelined MAC | 1.82 ns / 549.5 MHz | -49.5 ps | 135,409.086 | 39,501 |

The [original](evidence/physical/sweep/sweep_summary.csv) and [pipelined](evidence/physical/sweep/sweep_summary_pipe.csv) CSVs preserve the tool output. These are synthesis values, not post-route results. Both sweeps have clock gating enabled. CSV formatting is preserved, including missing or unusually located headers.

## Routed 500 MHz progression

| Run | Worst setup slack | Worst hold slack | Evidence |
|---|---:|---:|---|
| `p2.0_pipe_v3` | -0.002 ns | -0.007 ns | [Analysis summary](evidence/physical/tempus_sweep/p2.0_pipe_v3/rpt/analysis_summary.rpt): 1 setup / 31 hold violations |
| `p2.0_pipe_v4` | -0.006 ns | See run CSV | [Analysis summary](evidence/physical/tempus_sweep/p2.0_pipe_v4/rpt/analysis_summary.rpt), [CSV](evidence/physical/tempus_sweep/p2.0_pipe_v4/tempus_result.csv) |
| `p2.0_pipe_v5` | **+0.001 ns** | **+0.004 ns** | [Setup paths](evidence/physical/tempus_sweep/p2.0_pipe_v5/rpt/setup_paths.rpt), [hold paths](evidence/physical/tempus_sweep/p2.0_pipe_v5/rpt/hold_paths.rpt), [CSV](evidence/physical/tempus_sweep/p2.0_pipe_v5/tempus_result.csv) |

The v5 reports are dated September 29 at 17:00. Setup Path 1 has a 2.000 ns phase shift, 0.100 ns uncertainty, propagated clock latency, and +0.001 ns slack. Hold Path 1 has a 0.200 ns input delay, 0.100 ns uncertainty, and +0.004 ns slack. The [actual SDC](evidence/physical/sweep/p2.0_pipe/accel_top_p2.0.sdc) preserves the interface assumptions. The sweep scales maximum I/O delays with clock period while retaining minimum delays and uncertainty.

The v5 [analysis summary](evidence/physical/tempus_sweep/p2.0_pipe_v5/rpt/analysis_summary.rpt) contains view headings without populated tables. That file alone is insufficient evidence of closure; the positive-slack claim is established by the explicit path reports and CSV, with the [all-violators report](evidence/physical/tempus_sweep/p2.0_pipe_v5/rpt/all_violators.rpt) reporting no listed violations.

The same run has clean Innovus [DRC](evidence/physical/pnr_sweep/p2.0_pipe_v5/rpt/07_drc.rpt), [connectivity](evidence/physical/pnr_sweep/p2.0_pipe_v5/rpt/07_conn.rpt), and [process-antenna](evidence/physical/pnr_sweep/p2.0_pipe_v5/rpt/07_antenna.rpt) reports. These checks do not establish separate foundry DRC/LVS signoff.

## Remaining verification scope

- [Constraint coverage](evidence/physical/tempus_sweep/p2.0_pipe_v5/rpt/check_timing.rpt) still reports **168 no-drive and 556 unconstrained-endpoint warnings**. Review and resolve or justify these before claiming complete timing coverage.
- SPEF missing-net reports for [rc_0](evidence/physical/tempus_sweep/p2.0_pipe_v5/rc_0.missing_nets.rpt) and [rc_125](evidence/physical/tempus_sweep/p2.0_pipe_v5/rc_125.missing_nets.rpt) are preserved for review.
- The supplied LEC pass logs concern the earlier clock-gated baseline, not the v5 pipeline. Final pipelined regression and equivalence results are not established by this archive.
- The 38,575-instance count, 0.370 mV VDD drop, and PPA reductions belong to the earlier 100 MHz implementation. Do not attribute them to the v5 run.
- The scripts and constraints are supplied snapshots with environment-specific dependencies; historical run-to-source identity is not independently proven.

A supported description is: **"Achieved +1 ps setup and +4 ps hold slack at a 500 MHz target in the recorded post-route Tempus views, with remaining constraint-coverage warnings documented."**
