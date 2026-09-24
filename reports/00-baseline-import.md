# Baseline source import

Date: September 24, 2026

Imported the six files from the user-provided `ai_accel_pd_verified_sources.tar.gz` without modifying their contents. The archive was packaged from the university project.

Archive SHA-256: `886e8becd912f82c2792bef74424c96531dfa9a4d55589f7b1f154c18230e21b`

## Verification and provenance

Static review confirmed the MAC, broadcast array, four-step controller, and corresponding testbenches are present. No local simulator was available; no simulation was rerun during import. Prior user-provided Xcelium 23.09-s012 transcripts dated September 22, 2026 report 132,084 MAC checks, 103 array tests (1,648 output checks), and 23 completed controller jobs passing. These historical results are not a fresh run tied to this Git commit. Re-run the commands in `scripts/run_commands.tcsh` and record the source commit for new evidence.

The controller accepts exactly four operand sets per job. This baseline is a matrix compute engine, not a complete CNN. No synthesis, physical implementation, power, or accuracy result is asserted.

## Source SHA-256 hashes

| File | SHA-256 |
|---|---|
| `rtl/mac_int8.sv` | `124a351d7e498a4d23f8c78f96c92eb9fec3e96acbc0c6239077ebf38fd84e1a` |
| `rtl/mac_array_4x4.sv` | `9dffc16661059c5126457f3560c28f5162e895fabb18a5333aa86fb953a04c60` |
| `rtl/matmul_4x4.sv` | `26c8158f96c38aba7a73967989f81b01b3f9f6ec5d07488b51164033e67bba94` |
| `tb/tb_mac_int8.sv` | `678ffda67d0292bdf0b7cfc8262be7f7a17a3e15ac6807487ad263a0e83915b5` |
| `tb/tb_mac_array_4x4.sv` | `deb11362b78a93e308d9aff6ef115a9d15dc6014cdc3802afab433a7e08b1b2d` |
| `tb/tb_matmul_4x4.sv` | `3feeeef2989dc6d252b86a674a07cc1d3943384d448e171622a2fe4c04660627` |
