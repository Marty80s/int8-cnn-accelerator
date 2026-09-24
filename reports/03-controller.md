# 03 — Controlled matrix engine

## Interface and behavior
Inputs: clk, rst_n, start, in_valid, four signed A bytes, four signed B bytes. Outputs: in_ready, busy, done, sixteen signed 32-bit results. The FSM contains IDLE, CLEAR, COMPUTE. start is a pulse accepted in IDLE. CLEAR zeros the array. COMPUTE increments a two-bit counter only on in_valid && in_ready. The fourth accepted set updates the final sums, returns to IDLE and pulses done for one clock. Results remain until reset or the next clear. Busy start requests are ignored; a continuously asserted start can request another job once idle, so the interface requires a pulse.

## Verification evidence
User-provided transcript `Pasted text(20260922-230158).txt`, September 22, 2026, Xcelium 23.09-s012: all four compiled modules showed zero errors/warnings. Result: `PASS: 23 completed jobs; controller checks passed`, simulation time 4010 ns.

The 23 completed jobs were identity without stalls, identity with stalls, 20 random jobs with stalls, and a recovery job after reset. A separate partially computed job was deliberately aborted by reset and is not included in the 23. Tests checked intermediate sums, changes to invalid inputs, busy start requests, completion timing, done pulse width, valid inputs while idle, clear between jobs and reset recovery. Consecutive jobs did not require a reset; this does not establish zero-gap maximum launch throughput.

## Limitations and next change
K is fixed at four; no memory interface is integrated. Generalize K next, capture configuration on start, define invalid configuration behavior and verify counter boundaries. Do not change the verified baseline until it is committed.

## Interview preparation
Explain why the counter follows accepted operands rather than elapsed cycles. Trace a stall and the final MAC edge. Explain why done and the updated result become visible together after the edge.
