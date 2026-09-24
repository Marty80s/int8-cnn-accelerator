# Import the tested baseline

The source of truth is the saved project on the university machine, not a reconstructed copy from chat.

Required source files:
- rtl/mac_int8.sv
- rtl/mac_array_4x4.sv
- rtl/matmul_4x4.sv
- tb/tb_mac_int8.sv
- tb/tb_mac_array_4x4.sv
- tb/tb_matmul_4x4.sv

From the remote terminal, package only these files:

```tcsh
cd ~/ai_accel_pd
tar -czf ~/ai_accel_pd_verified_sources.tar.gz rtl/mac_int8.sv rtl/mac_array_4x4.sv rtl/matmul_4x4.sv tb/tb_mac_int8.sv tb/tb_mac_array_4x4.sv tb/tb_matmul_4x4.sv
```

The six files were imported unchanged into https://github.com/Marty80s/int8-cnn-accelerator on September 24, 2026. See [the import report](../reports/00-baseline-import.md) for provenance and hashes.

The repository now contains both RTL and testbenches. Keep these originals as the baseline for future changes.

## Ongoing commits
Keep one meaningful change per commit. Run the appropriate simulation first, record the source commit SHA and results in a milestone report, then commit the report. Example commit subjects:
- baseline: import verified MAC array and controller
- feat: support configurable accumulation length
- test: verify K boundaries and stalls
- docs: record configurable compute verification

Do not use git add . until checking git status and the intended file list. Curate logs: prefer PASS summaries and relevant diagnostics; remove private machine paths and license-server details from public reports.
