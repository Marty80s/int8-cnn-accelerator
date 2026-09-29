# Physical design and clock sweep (September 2026)

This note summarizes the reviewed `int8_lab.zip` archive. The original generated
tool reports and databases remain on the university machine; `runs/` is excluded
from this repository. Values below describe specific runs, not silicon measurements.

## Flow and scope

- `accel_top` is a 4x4 INT8 matrix multiplication engine with 16 signed MACs,
  behavioral operand memory, and a configurable accumulation length. It is not
  yet a complete CNN accelerator or an SRAM-macro-based implementation.
- The `PIPE` build option registers the 16-bit product before accumulation.
- `scripts/sweep/run_sweep.tcsh` varies the clock period and invokes Genus;
  `synth_sweep.tcl` records synthesis timing, cell area, cell count, a power
  estimate, and runtime. The original and pipelined sweeps both have clock
  gating enabled in the supplied summaries.
- Selected variants were implemented in Innovus with floorplanning, power
  grid, placement, CTS, route, RC extraction, and checks. Tempus analyzes the
  routed netlist with SPEF, propagated clocks, OCV, CPPR, and SI-aware delay.
  The scripts reference university-specific absolute paths and a Run 2 MMMC
  file that was not included in the archive; adapt these paths to reproduce.

## Synthesis sweep

| Variant | Clock target | Genus WNS | Cell area | Cells |
|---|---:|---:|---:|---:|
| Original MAC | 2.50 ns (400 MHz) | 0.0 ps | 136,034.399 um2 | 37,838 |
| Original MAC | 2.22 ns (450.5 MHz) | 0.0 ps | 136,950.600 um2 | 38,952 |
| Original MAC | 2.00 ns (500 MHz) | -217.7 ps | 137,834.208 um2 | 39,988 |
| Pipelined MAC | 2.00 ns (500 MHz) | 0.0 ps | 137,049.660 um2 | 39,433 |
| Pipelined MAC | 1.82 ns (549.5 MHz) | -49.5 ps | 135,409.086 um2 | 39,501 |

The supplied original summary covers targets from 7.0 to 1.33 ns; the
pipelined summary covers 2.5 to 1.43 ns. These numbers come from Genus
summaries, not routed signoff. The original `sweep_summary.csv` has no header
and `sweep_all.csv` has a header after its data, so import those files with
care. Power values have not been normalized or validated for comparison.

## Routed checks and limitations

The latest supplied 2.00 ns pipelined Innovus run (`p2.0_pipe_v3`) reports no
DRC, connectivity, or process-antenna violations. Its Tempus analysis summary
reports setup WNS/TNS **-0.002/-0.002 ns** (one violating path), and hold
WNS/TNS **-0.007/-0.092 ns** (31 violating paths). This run therefore does
not demonstrate timing closure at 500 MHz.

`check_timing -verbose` additionally reports 168 `no_drive` warnings and 556
`uncons_endpoint` warnings. Investigate the clock-gating enable pins, model
input drive, and rerun constraint coverage and setup/hold analysis before
making a signoff or achieved-frequency claim. An empty analysis summary in
some other variants must not be treated as timing closure.

The archive includes RTL testbenches and scripts for LEC and gate-level
simulation, but the reviewed package does not contain pass transcripts for
those final checks. Do not claim these runs passed on this evidence alone.
