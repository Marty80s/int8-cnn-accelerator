# Milestone 6: operand reader with synchronous memory

## Goal and result

Deliver K stored 64-bit words in address order to a consumer using valid/ready flow control. The reader was tested with the actual operand_memory RTL, not a mocked memory response.

The user-supplied Xcelium 23.09-s012 log dated September 23, 2026 records five completed jobs and 267 delivered words passing. All three source files compiled with zero errors and warnings. Simulation ended at 16,186 ns; wall time was two seconds. No simulation was rerun during import.

## Algorithm and states

| State | Operation | Transition |
|---|---|---|
| IDLE | Accept start with nonzero K; capture length and set address to zero | REQUEST |
| REQUEST | Assert mem_rd_en for the current address | WAIT_DATA at the sampling edge |
| WAIT_DATA | Wait for mem_rd_valid; capture mem_rd_data into out_data | SEND |
| SEND | Assert out_valid and retain the word until out_ready | REQUEST for another word, or IDLE with done for the last word |

Addresses advance only after output acceptance. A remaining counter determines whether the accepted word is the final one. Only one read is outstanding; the 64-bit output register buffers its response. No new read is issued while waiting for consumer acceptance.

## Interface contract

- Pulse start while idle with K in 1–255. Addresses 0 through K-1 must already contain valid data.
- K=0 requests are ignored, without a done pulse.
- Busy start requests and external K changes do not affect the active job.
- A delivery occurs at a rising edge when out_valid and out_ready are both high.
- If out_ready is low, out_valid and out_data remain stable until acceptance or reset.
- done pulses for one clock on the final delivery. It indicates data delivery, not completion of a downstream calculation.
- Synchronous active-low reset aborts the job and clears the reader's output register. busy, mem_rd_en, and out_valid are also combinationally gated by rst_n.
- Reset both reader and memory together, as this testbench does, to discard pending responses consistently.
- There is no memory request-ready handshake. The attached memory must accept requests whenever mem_rd_en is asserted and return one valid response for each.
- A start held high with nonzero K can trigger a new job when idle is reached. The normal contract is a start pulse.

## Timing and tradeoff

With this registered memory and an always-ready consumer, a start accepted at edge E0 is followed by a memory request at E1, response capture at E2, and output acceptance at E3. Subsequent acceptances are three clocks apart. Completion is 3K clock periods after the start edge without stalls.

This schedule is derived from RTL, not a measured physical timing result. It favors a simple, verifiable sequence; it does not sustain one operand word per clock. Prefetching and buffering could improve throughput in a later measured optimization.

## Verification

The testbench fills all 256 addresses with distinct deterministic 64-bit patterns. It checks sequential request addresses, word contents, exact request/delivery counts, stable blocked outputs, busy status, completion timing, and idle behavior.

| Job | K | Consumer pauses |
|---|---:|---|
| 1 | 1 | None |
| 2 | 3 | Two blocked cycles per word |
| 3 | 4 | None |
| 4 | 255 | Two blocked cycles per word |
| 5 | 4 | Two blocked cycles per word; recovery after reset |

The completed jobs total 267 words. An additional K=8 job is aborted after a memory request and before delivery; it is excluded from that total. Zero-length requests are exercised before and after normal jobs. During active jobs, the testbench asserts start with a different nonzero K to check that busy requests are ignored.

Transfer checks sample pre-update values at rising edges; post-edge checks observe state and done after nonblocking updates. There is a global timeout and a per-job cycle bound.

Coverage limits: only the listed K values and deterministic data were tested. The test uses the actual fixed-latency memory, not arbitrary response delays. Reset while holding a blocked SEND word and reset at every other state are not covered. No formal proof, randomized coverage closure, or compute-engine integration is claimed.

## Reproduce

From the repository root in the configured university tcsh environment:

```tcsh
git rev-parse HEAD
mkdir -p runs/reader
cd runs/reader
xrun -64bit -sv ../../rtl/operand_memory.sv ../../rtl/operand_reader.sv ../../tb/tb_operand_reader.sv -top tb_operand_reader -l reader_sim.log
```

Expected final summary:

```text
PASS: operand reader, 5 completed jobs, 267 delivered words
```

## Provenance

The uploaded operand_reader_verified.tar.gz contained the two new sources and reader_sim.log. Source bytes were preserved exactly. The dependency operand_memory.sv was previously committed in 70589c0f9ade156fd3b1b78ff115d507cf251a2a; this upload does not contain a fresh dependency copy.

The run preceded this import commit and its log contains no source Git SHA. These hashes identify the uploaded artifacts; they do not independently establish which bytes the simulator used. Prior milestone regressions were not rerun during this import. Public evidence contains only PASS lines and completion time, omitting private machine paths.

| Uploaded artifact | SHA-256 |
|---|---|
| `rtl/operand_reader.sv` | `671d1488f774a5bb450a3d2fba3f0a5f7f92364e2ebc81bb48e42efcdd0102df` |
| `tb/tb_operand_reader.sv` | `b40cc95f2efe71de5099c25923945f759771e2b29296d2dc4b0e1f9acdc9721b` |
| `runs/reader/reader_sim.log` | `8a93f2f42954edfc1bb726b8933518ce9653436110bd57289bbf72348f14631e` |

## Integration still to do

Define the eight INT8 byte lanes, unpack each delivered word into four A and four B values, and connect the output handshake to matmul_4x4_k. Start both components consistently, guard memory writes during computation, and verify complete matrix results from stored operands.

No synthesis, physical memory mapping, area, power, clock closure, or CNN accuracy result exists for this milestone.

## Interview preparation

- Why buffer the word? Memory response validity can end before the consumer is ready.
- Why advance on acceptance? Advancing during a stall could drop or duplicate operands.
- Why a separate WAIT_DATA state? The memory read is synchronous and the response must be captured after it becomes valid.
- What does reader done mean? All K words have been accepted by the consumer.
- What is the throughput limitation? The request, response capture, and delivery use separate cycles.
