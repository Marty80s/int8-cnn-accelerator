# INT8 Matrix Engine: RTL to Physical Design

A 4x4 output-stationary INT8 matrix-multiplication engine implemented in SystemVerilog, with a Cadence synthesis and physical-design study using GSCLIB045 45 nm. The repository name reflects a longer-term CNN goal; convolution scheduling, requantization, and complete CNN inference remain future work.

## Architecture

`accel_top` connects a 256x64-bit behavioral operand memory, a valid/ready memory reader, and 16 signed INT8 MACs with 32-bit accumulators. Each input word packs `{B3, B2, B1, B0, A3, A2, A1, A0}`. The configurable controller accumulates K=1-255 operand sets. Memory is implemented in standard cells, not an SRAM macro. An optional pipelined MAC registers the product before accumulation.

## Recorded results

Results below belong to distinct runs. Reports were produced on the university Cadence installation and imported from the October 2 archive; no EDA tools were rerun during this update.

| Implementation / check | Recorded result |
|---|---|
| Baseline RTL | MAC: 132,084 checks; array: 103 matrix tests; configurable K: 11 completed jobs |
| Integrated baseline | Identity and non-identity accumulation tests: 16 result checks each |
| Earlier clock-gated 100 MHz implementation | 38,575 instances reported by power analysis; 262 inserted clock-gating instances |
| Earlier implementation, Conformal | RTL-to-synthesis and synthesis-to-PnR: 17,568 equivalent compare points each |
| Earlier baseline to clock-gated implementation | Estimated power 6.075 -> 2.252 mW; die area 399,050.008 -> 237,543.966 um2 |
| Earlier implementation, static rail analysis | Approximately 0.370 mV VDD drop at nominal 0.9 V; VSS rise approximately 0.375 mV |
| Pipelined synthesis, 2.00 ns target | Reported synthesis WNS 0.0 ps |
| Pipelined routed run `p2.0_pipe_v5`, 500 MHz | Tempus worst reported setup **+0.001 ns**, hold **+0.004 ns** |
| Same v5 run, Innovus checks | Zero reported DRC, connectivity, and process-antenna violations |

The v5 result supersedes the earlier v3 result (-2 ps setup / -7 ps hold). Its path reports show positive slack with propagated clocks and SI/OCV/CPPR enabled. **Constraint coverage still reports 168 no-drive and 556 unconstrained-endpoint warnings.** These require review before claiming complete timing signoff. The earlier LEC and rail results are not proof of equivalence or rail integrity for the final pipelined variant.

See the [physical-design report](reports/08-physical-design-clock-sweep.md) for run-by-run evidence, [PPA comparison](reports/09-clock-gating-ppa.md) for measurement assumptions, and [evidence index](reports/evidence/physical/README.md) for source files.

## Engineering work

- Built the signed MAC array, configurable accumulation controller, operand memory, and reader; added self-checking block and integration tests.
- Inserted clock gating and evaluated the resulting hold-repair, area, and estimated-power changes.
- Automated clock-period sweeps and added a product pipeline stage to explore the timing/area tradeoff.
- Implemented selected designs through placement, CTS, routing, extraction, and Tempus analysis.
- Preserved failing and improved timing results rather than mixing metrics from different variants.

## Repository map

- `rtl/`, `tb/`: supplied RTL and self-checking testbenches.
- `scripts/`: simulation commands, synthesis, PnR, STA, LEC, and sweep scripts.
- `constraints/`: initial SDC and the earlier implementation's MMMC template.
- `reports/`: milestone reports, physical-design analysis, and curated tool evidence.
- `docs/`: reproduction guidance and roadmap.
- `runs/`: generated local output, excluded from Git.

## Reproduction and scope

Start with [reproduction notes](docs/reproduce-physical.md). Cadence tools and licensed library views must be available separately. The imported scripts contain university-specific paths and require a locally prepared LEF; they are not a portable turnkey flow.

The archive includes uncommitted source changes. The [import manifest](reports/evidence/physical/manifest-2026-10-02.json) records source and evidence hashes, but hashes alone do not establish which RTL revision generated a historical report. Final pipelined functional-regression and LEC evidence remain to be added. No fabricated-silicon, FPGA speedup, or CNN-accuracy result is claimed.
