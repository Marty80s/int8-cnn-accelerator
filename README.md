# INT8 CNN Accelerator

SystemVerilog compute engine progressing toward CNN inference and ASIC physical implementation. No FPGA board or fabricated silicon is required by this project.

## Current status
The current design is a **4x4 broadcast, output-stationary matrix-multiplication engine**, not yet a complete CNN accelerator. It uses 16 signed INT8 MACs, 32-bit accumulators, and a controller supporting 1–255 operand sets per job. The original fixed-four controller is retained as a baseline.

| Milestone | Recorded result |
|---|---|
| Single MAC | 132,084 checks passed |
| MAC array | 103 matrix tests; 1,648 final output comparisons passed |
| Controlled compute engine | 23 completed jobs; controller checks passed |
| Configurable-K engine | 11 completed jobs; 18,752 output checks passed |
| Standalone operand memory | 526 cycle checks passed |

The first three results were observed in user-supplied Xcelium 23.09-s012 transcripts on September 22, 2026. The six original source files were imported unchanged on September 24, 2026. See [baseline provenance and hashes](reports/00-baseline-import.md). Simulations were not rerun during import.

The configurable-K result comes from the uploaded September 23, 2026 Xcelium log. See [the configurable-K report](reports/04-configurable-k.md) for the contract, coverage, provenance, and limitations. No simulations were rerun during this import.

A standalone 256x64-bit synchronous operand memory has also passed directed simulation in the uploaded September 23, 2026 Xcelium log. See [the memory report](reports/05-operand-memory.md). It is not yet connected to the compute engine.

No synthesis area, post-route frequency, power, FPGA speedup, or CNN accuracy is claimed yet.

## Architecture
At each accepted step k, the array receives A[0:3][k] and B[k][0:3]. Each MAC updates C[i][j] with A[i][k]*B[k][j]. All 16 partial sums stay in their own registers.

The controller sequence is IDLE -> CLEAR -> COMPUTE -> IDLE. An operand set is accepted on a rising edge when in_valid && in_ready. In `matmul_4x4_k`, the Kth accepted set completes the job and asserts done for one clock. K is captured on an idle start; K=0 requests are ignored. Input gaps stall computation. start must be pulsed while idle; requests while busy are ignored. Reset is synchronous active-low. Arithmetic overflow wraps rather than saturates.

## Repository organization
- rtl/: original synthesizable design files imported from the university machine
- tb/: original self-checking testbenches
- docs/: architecture decisions, learning notes, roadmap
- reports/: milestone reports and curated evidence
- scripts/: reproducible run commands
- constraints/: timing constraints, to be developed
- runs/: generated local output, excluded from Git

## Reproduce
Load the university-supported Cadence environment first. See scripts/run_commands.tcsh for commands to run in that configured tcsh session. The source files listed in docs/import-and-git.md are required.

## Planned work
1. Preserve the verified baseline (source import complete).
2. Generalize accumulation length K (implemented; directed simulation passed).
3. Integrate synchronous operand memory and a reader (standalone memory tested; integration pending).
4. Add convolution scheduling and integer postprocessing.
5. Validate a small CNN against an independent integer reference.
6. Synthesize, implement, and analyze the design in Cadence.
7. Compare controlled physical-design experiments.

Compatible physical SRAM macros are not confirmed. Behavioral memory does not establish a physical SRAM implementation. Memory-placement experiments remain conditional on compatible macro views.

## Reporting policy
Every milestone records the problem, algorithm, interface, design decisions, verification, commands, tool version, result provenance, bugs, limitations, and interview questions. Record a source commit SHA for each new run. Keep measured results separate from targets and estimates.

Do not commit proprietary PDK/library files, university environment scripts or license settings, tool executables, generated databases, or unreviewed terminal histories. No redistribution license is selected in this starter package.
