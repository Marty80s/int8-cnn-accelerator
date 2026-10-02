# Physical-design evidence

Imported from `int8_review_20261002_010807.zip` on October 2, 2026. The [manifest](manifest-2026-10-02.json) records the archive checksum, original paths, file hashes, and whether each item is verbatim or an excerpt. No EDA analysis was rerun during import.

## Latest pipelined 500 MHz result

- [Tempus CSV](tempus_sweep/p2.0_pipe_v5/tempus_result.csv): +0.001 ns setup, +0.004 ns hold.
- [Setup paths](tempus_sweep/p2.0_pipe_v5/rpt/setup_paths.rpt) and [hold paths](tempus_sweep/p2.0_pipe_v5/rpt/hold_paths.rpt): explicit MET checks and slack.
- [All violators](tempus_sweep/p2.0_pipe_v5/rpt/all_violators.rpt): no listed violations.
- [Constraint coverage](tempus_sweep/p2.0_pipe_v5/rpt/check_timing.rpt): 168 no-drive and 556 unconstrained-endpoint warnings remain.
- [Analysis settings](tempus_sweep/p2.0_pipe_v5/analysis-settings.txt), [MMMC](pnr_sweep/p2.0_pipe_v5/mmmc_p2.0.tcl), and [SDC](sweep/p2.0_pipe/accel_top_p2.0.sdc).
- Innovus [DRC](pnr_sweep/p2.0_pipe_v5/rpt/07_drc.rpt), [connectivity](pnr_sweep/p2.0_pipe_v5/rpt/07_conn.rpt), [antenna](pnr_sweep/p2.0_pipe_v5/rpt/07_antenna.rpt), and [power](pnr_sweep/p2.0_pipe_v5/rpt/07_power.rpt) reports.

The v3 and v4 summaries are preserved as historical runs. An empty summary table is not proof of timing closure; v5 has explicit path evidence. Positive reported slack does not resolve the remaining coverage warnings.

## Earlier 100 MHz implementation

- [Clock gating](synthesis_cg/clock_gating.rpt): 262 ICG instances.
- [RTL-to-synthesis LEC](lec_run2/lec_rtl2syn.txt) and [synthesis-to-PnR LEC](lec_run2/lec_syn2pnr.txt): 17,568 equivalent points each.
- [Baseline power](innovus_sitefix/rpt/09_power.rpt) and [optimized power](innovus_run2/rpt/09_power.rpt).
- [Baseline implementation excerpts](innovus_sitefix/implementation-excerpts.txt), [area excerpt](innovus_sitefix/area-excerpt.txt), and [optimized excerpts](innovus_run2/implementation-excerpts.txt).
- [Static rail EIV summary](innovus_run2/rail/PD_125C_avg_1/Reports/EIVDB/eivdb-summary.json).

See the [PPA analysis](../../09-clock-gating-ppa.md) for calculations and assumptions. These results must not be assigned to the final pipeline variant.
