# Milestone 4: configurable accumulation length

## Goal and result

Extend the 4x4 matrix compute engine to multiply A[4][K] by B[K][4] for a runtime K of 1–255, using the same 16 MACs.

User-run Xcelium 23.09-s012 simulation on September 23, 2026 passed 11 completed jobs and 18,752 scalar output comparisons. Compilation reported zero errors and warnings for all four source files. Simulation ended at 11,990 ns; the recorded wall time was two seconds. Neither number is a measured chip frequency or job latency.

## Algorithm and hardware

For each accepted operand set k, all 16 accumulators update:
C[i][j] = C[i][j] + A[i][k] * B[k][j].

Four A values are broadcast across rows and four B values across columns. This is an output-stationary broadcast array, not a systolic array. Inputs are signed INT8, products are signed 16-bit, and accumulators are signed 32-bit. The new controller is a separate module; the original fixed-four controller and shared MAC RTL are unchanged.

The remaining counter captures K at start. Each accepted input decrements it; when its pre-edge value is one, that same edge adds the final product and asserts done. Counting accepted inputs rather than elapsed clocks prevents stalls from shortening the calculation.

## Interface contract

| Signal/event | Behavior |
|---|---|
| rst_n | Synchronous active-low reset clears state, counter, done, and accumulators on a rising edge. busy and in_ready are also combinationally gated by rst_n. |
| start and k_length | Sampled in IDLE; nonzero K starts a job. Pulse start for one cycle. |
| K=0 | Request ignored, no done pulse, previous results retained. No error output. |
| CLEAR | Clears accumulators on the next rising edge; operands are not accepted. |
| in_valid and in_ready | An operand set is accepted only when both are high at a rising edge. |
| busy | High in CLEAR and COMPUTE while reset is deasserted. |
| done | One-cycle pulse after the final accumulation edge; results are updated on that edge. |
| Busy start/length changes | Ignored by the state machine. |
| Results | Held through pauses and idle until reset or the next CLEAR edge. |

There is no output-ready handshake. The consumer must capture the results before the next job clears them. Holding start high with a nonzero K can launch another job once IDLE is reached.

With continuous valid input, completion occurs K+1 clock periods after the start-acceptance edge: one CLEAR edge, then K computation edges. This is an RTL schedule, not post-layout timing.

## Verification

The testbench drives on falling edges and checks one nanosecond after rising edges to observe sequential updates. Its integer reference calculates expected products from deterministic signed operand formulas, independently of DUT outputs.

| Cases | Coverage |
|---|---|
| K=1 | With and without stalls |
| K=2, 3, 8, 16 | With stalls |
| K=4 and 255 | With and without stalls |
| Idle K=0 | Before work and after nonzero results |
| Mid-job reset | Abort after one update, verify zeros, then complete a K=3 recovery job |
| Control | Completion timing, one-cycle done, idle hold, partial sums during pauses |

The 18,752 comparisons include intermediate sums, clear/reset values, stalls, and idle hold; they are not 18,752 independent matrix jobs. The aborted job is not included in the 11 completed jobs.

Busy-start checks assert start with K=0 during COMPUTE. This covers that combination, but does not independently prove rejection of a nonzero busy-start request or a request during CLEAR. These are useful future directed cases. Only the listed K values were exercised, not all 255 lengths. There is no formal proof or coverage closure claim.

## Reproduce

In a university tcsh session with the approved Cadence aliases loaded, start at the repository root:

```tcsh
git rev-parse HEAD
mkdir -p runs/configurable_k
cd runs/configurable_k
xrun -64bit -sv ../../rtl/mac_int8.sv ../../rtl/mac_array_4x4.sv ../../rtl/matmul_4x4_k.sv ../../tb/tb_matmul_4x4_k.sv -top tb_matmul_4x4_k -l configurable_k_sim.log
```

Expected final line:

```text
PASS: 11 completed jobs, 18752 output checks; zero-length and reset checks passed
```

## Provenance

The uploaded configurable_k_verified.tar.gz contains the two source files and the original simulation log. Sources were imported byte-for-byte. The public evidence excerpt contains PASS lines and completion time only; the full log is not published.

The recorded run preceded this import commit, so its log does not identify a source Git commit. The table records the uploaded file hashes; the log alone cannot establish a cryptographic connection between source bytes and the run. The dependency baseline is dd7a55d5a664c7c4bab1f3e69520cdef3c6ae3a8. No simulation or baseline regression was rerun during import.

| Uploaded file | SHA-256 |
|---|---|
| `rtl/matmul_4x4_k.sv` | `284581f0652411d87fdc39bb0657c099e4b82409a664222b1cf1f5a18c6d7502` |
| `tb/tb_matmul_4x4_k.sv` | `a347a712bb75218900da6f96cbe887024f01fcf21c3e754121d9d55ecf883702` |
| `runs/configurable_k/configurable_k_sim.log` | `768dd0d7b2a4f3123eb2fac4f289f98a969acfc2d300cae683a39c4833a0bc1a` |

## Limitations and next step

The current testbench supplies operands directly. Memory, address generation, CNN scheduling, bias, activation, and requantization are not implemented. No synthesis area, power, or physical timing has been measured. With K at most 255 and each job cleared, INT8 products cannot overflow the 32-bit accumulator, although the underlying MAC uses wrapping arithmetic.

Next, implement synchronous operand storage and a reader that respects the compute handshake and memory read latency.

## Interview preparation

- Why can K change without adding MACs? The same 16 MACs are reused over more accepted cycles; output dimensions stay 4x4.
- Why capture K at start? External configuration changes must not alter an active job.
- Why count handshakes? A stalled clock cycle contributes no product.
- Why use a remaining counter? Testing for one identifies the final accepted set directly.
- Does a simulation clock prove achievable frequency? No; synthesis and physical timing analysis are required.
