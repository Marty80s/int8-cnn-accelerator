# 07 — Integrated accelerator: identity test

## Purpose
Connect the existing operand memory, operand reader, and configurable-K matrix engine in accel_top. This is a first integration check, not a complete accelerator regression.

## Connections
Memory read data and valid feed the reader. The reader supplies a 64-bit word and valid to the compute path; compute in_ready returns to reader out_ready. A transfer occurs on a rising edge with both valid and ready high.

Word layout: {B3, B2, B1, B0, A3, A2, A1, A0}. Each operand is signed INT8. Bits [7:0] hold A0; bits [31:24] hold A3; bits [39:32] hold B0; bits [63:56] hold B3. Unpacking is wiring, not an additional pipeline stage.

Both controllers accept the same start when idle and K is nonzero. Start must be pulsed for one cycle. Busy is the OR of controller busy signals; done comes from the compute engine. Writes while busy are ignored; a valid start takes priority over a simultaneous write. Reset is shared and synchronous.

## Test
A rows:
- 1, 2, 3, 4
- 5, 6, 7, 8
- -1, -2, -3, -4
- -5, -6, -7, -8

B is the 4x4 identity matrix, so the expected result is A. The test loads four words, starts K=4, waits with a timeout, checks 16 results, and checks done deassertion and result retention for three idle cycles.

## Observed result
User-run Cadence Xcelium 23.09-s012, September 24, 2026:
- All seven compiled modules reported zero errors and zero warnings.
- PASS: accel_top identity test, 16 result checks.
- Simulation finished at 266 ns.
- The 10 ns testbench clock is simulation stimulus, not demonstrated physical timing closure.
- Simulator register counts are not synthesized flip-flop counts or area estimates.

## Reproduce
Run in the university tcsh environment with the existing xrun container alias:

```tcsh
cd ~/int8-cnn-accelerator
mkdir -p runs/top
cd runs/top
xrun -64bit -sv ../../rtl/mac_int8.sv ../../rtl/mac_array_4x4.sv ../../rtl/matmul_4x4_k.sv ../../rtl/operand_memory.sv ../../rtl/operand_reader.sv ../../rtl/accel_top.sv ../../tb/tb_accel_top.sv -top tb_accel_top -l top_sim.log
```

## Limits and next test
Identity multiplication does not exercise multiple nonzero contributions to each result. Next use non-identity matrices with an independent row-by-column reference. Integrated K boundaries, zero-length requests, busy-time starts/writes, reset during work, and repeated jobs remain to be tested. Separate block tests do not substitute for these integration checks.

No synthesis, area, timing, or power result is claimed.

## Evidence
Imported exact source bytes from accel_top_identity_verified.tar.gz together with its user-generated log. The simulation was not rerun during import. Hashes identify the uploaded files; they do not independently prove which source bytes generated the log.

| File | SHA-256 |
|---|---|
| rtl/accel_top.sv | b2f2efe76172b3f73a32c4e11ad77d042fe2079d49c094ed86557835cc8a2a6b |
| tb/tb_accel_top.sv | 18b58bdd59cbaefe548fa0d2a394683b0f16ea25371a195c9dabe98e43c7b942 |
| runs/top/top_sim.log | 41fbf3d6bed61642022b074271a2ebecbd41926731cb888b413b5a6f3e92656b |
