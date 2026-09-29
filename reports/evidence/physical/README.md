# Physical-design evidence

These files were copied byte-for-byte from `int8_github_update.tar.gz`, uploaded on September 29, 2026. [manifest.json](manifest.json) records the archive checksum, original paths, file sizes, and SHA-256 hashes. No EDA analysis was rerun to produce this evidence directory.

## Synthesis sweep

`sweep/` preserves the original summary CSVs and per-period `result.csv` files for the baseline and pipelined variants. Preserve the original formatting when interpreting these files: `sweep_summary.csv` has no header, and `sweep_all.csv` has a header after data. The existing physical-design report interprets synthesis WNS in ps; Tempus report slack is in ns. Power entries are unnormalized tool estimates.

## Selected routed run: p2.0_pipe_v3

- [DRC](pnr_sweep/p2.0_pipe_v3/rpt/07_drc.rpt): no violations reported.
- [Connectivity](pnr_sweep/p2.0_pipe_v3/rpt/07_conn.rpt): no problems or warnings reported.
- [Process antenna](pnr_sweep/p2.0_pipe_v3/rpt/07_antenna.rpt): no violations reported.
- [Power](pnr_sweep/p2.0_pipe_v3/rpt/07_power.rpt): original estimate, including its units and activity assumptions.
- [Tempus analysis summary](tempus_sweep/p2.0_pipe_v3/rpt/analysis_summary.rpt): setup WNS −0.002 ns / 1 violating path; hold WNS −0.007 ns / 31 violating paths.
- [Constraint coverage](tempus_sweep/p2.0_pipe_v3/rpt/check_timing.rpt): 168 no-drive and 556 unconstrained-endpoint warnings.
- Setup/hold path details, all-violator reports, and missing-net reports are preserved alongside the summary for inspection.

The selected run is not timing closed. Clean Innovus physical checks do not replace complete timing constraints, equivalence checks, or foundry signoff. Older run reports remain in the uploaded archive; this directory highlights the latest supplied 2.0 ns pipeline result rather than mixing variants.

The baseline identity PASS excerpt remains in `reports/evidence/accel-top-identity-pass.txt`. The baseline accumulation PASS was shared as a development transcript; a standalone saved log and final pipeline/LEC PASS logs were not included in these archives.
