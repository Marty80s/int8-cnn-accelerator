# Milestone 5: synchronous operand memory

## Goal and recorded result

Provide operand storage for the future reader and matrix engine. The standalone operand_memory module stores 256 words of 64 bits: 16,384 bits, or 2 KiB. A future word will carry four INT8 A values and four INT8 B values; byte-lane packing is not yet defined by this storage-only module.

The uploaded Xcelium 23.09-s012 log records PASS: operand memory, 526 cycle checks on September 23, 2026. Both source files compiled with zero errors and warnings. Simulation ended at 5,266 ns, with two seconds of wall time. These are simulation measurements, not physical timing or frequency results.

## Design and interface

| Interface | Contract |
|---|---|
| clk | All read and write operations occur at rising edges. |
| rst_n | Synchronous active-low reset clears rd_data and rd_valid and disables writes. Array contents are preserved. |
| wr_en, wr_addr, wr_data | If reset is deasserted and wr_en is high, write the 64-bit word at the 8-bit address. |
| rd_en, rd_addr | Request a synchronous read of an 8-bit address. |
| rd_data | Updates after the request's sampling edge; holds its prior value when rd_en is low. |
| rd_valid | Registered rd_en while out of reset; tells downstream logic whether the output word is valid. |

Reads and writes have separate address inputs and may occur simultaneously. For the same address, this RTL returns the old contents on the collision edge; a following read returns the new word. A future SRAM macro must have compatible behavior or the wrapper must prevent collisions.

Memory locations are uninitialized until written. Reading an unwritten address is outside the tested contract. Reset does not initialize the array.

A downstream sequential consumer sees the registered read response at a subsequent rising edge. The future reader must account for this timing and hold a response if the compute engine cannot accept it. This module has no response-ready input or queue.

## Why this design

A 64-bit word can deliver all eight operands needed for one 16-MAC update. An 8-bit address supports 256 locations; the current compute controller accepts up to 255 operand sets per job. Storage capacity and maximum job length are separate limits.

Keeping reset on the read interface rather than clearing all storage preserves loaded operands across reset and avoids specifying a bulk array clear. This does not establish SRAM inference or macro availability.

## Verification

The testbench drives at falling edges. It checks output stability before the next rising edge, then checks rd_data and rd_valid after sequential updates have settled. A separate reference array predicts values. Reads are modeled before writes to verify old-data collision semantics.

| Test | Cycle checks |
|---|---:|
| Initial reset | 1 |
| Write distinct patterns to every address | 256 |
| Read every address consecutively | 256 |
| Disabled reads and output hold | 2 |
| Overwrite and readback | 2 |
| Simultaneous different-address access and readback | 2 |
| Same-address collision and new-data readback | 2 |
| Reset with write/read requested, then read preserved data | 4 |
| Final idle cycle | 1 |
| Total | 526 |

Write correctness is observed through later readbacks; the 526 count is a cycle-check count, not 526 independent test scenarios. This is directed simulation, not exhaustive bit-fault testing, formal proof, or coverage closure.

## Reproduce

Run from the repository root in the approved university tcsh environment with xrun configured:

```tcsh
git rev-parse HEAD
mkdir -p runs/memory
cd runs/memory
xrun -64bit -sv ../../rtl/operand_memory.sv ../../tb/tb_operand_memory.sv -top tb_operand_memory -l memory_sim.log
```

Expected summary:

```text
PASS: operand memory, 526 cycle checks
```

## Provenance

Imported the two source files byte-for-byte from operand_memory_verified.tar.gz. The same archive included the original memory_sim.log. A curated PASS excerpt is in evidence/operand-memory-pass.txt; private paths from the original log are omitted.

The user ran the simulation before this import commit. The log contains no source Git SHA, so hashes identify the uploaded artifacts rather than cryptographically proving the run used those bytes. No simulation or prior-milestone regression was rerun during import.

| Uploaded file | SHA-256 |
|---|---|
| `rtl/operand_memory.sv` | `787953a26fce928a189d46601c9feed0917b65605d6fec4b9db9ad025f8f184d` |
| `tb/tb_operand_memory.sv` | `52156d983307b853b063667594db2f9e9ebdfac9ab96c410983c19c625dc0952` |
| `runs/memory/memory_sim.log` | `35a88e870bb7ab79d5c5974aa7abcb0188cc96a07e17ed15075cdb30b783a6e6` |

## Limitations and next step

Memory is tested in isolation. No reader, packing/unpacking logic, or compute integration is implemented in this milestone. No physical SRAM macro is selected and no synthesis area, power, or post-route timing is claimed. A synthesis tool may implement behavioral storage using registers unless a suitable memory mapping flow is provided.

Next, define operand lane packing and build a reader that requests addresses in order, waits for valid read data, and delivers each word exactly once to the compute handshake. Integration tests must cover reset, stalls, and first/last-word handling.

## Interview preparation

- Why 64 bits per word? Four A and four B operands, each eight bits, feed one array update.
- What makes the read synchronous? The address is sampled at a clock edge, and the output is registered.
- Why rd_valid? Held data is not necessarily a new response.
- Why preserve memory during reset? Control can restart without erasing already loaded operands.
- Is this a physical SRAM? No. The storage behavior is verified; physical implementation remains to be established.
