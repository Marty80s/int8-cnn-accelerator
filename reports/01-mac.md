# 01 — Signed INT8 MAC

## Purpose and algorithm
Compute acc_next = acc + a*b when enabled. a and b are signed 8-bit; product is signed 16-bit; acc is signed 32-bit. Product is sign-extended before addition. Synchronous active-low reset has priority over clear, which has priority over enable. With enable low the register holds. Overflow wraps modulo 2^32.

## Hardware
One multiplier, one adder, a 32-bit accumulator register and control selection in RTL. Actual mapped implementation is not measured yet. The feedback register enables accumulation over several clocks.

## Verification evidence
User transcript, September 22, 2026: Xcelium 23.09-s012 reported `PASS: 132084 MAC checks completed`. Directed signed cases, hold, clear priority, reset priority, 1000 random updates, and a long sequence crossing positive signed overflow were exercised. This is a check count, not a code or functional coverage percentage.

## Debugging
The RTL file was initially missing. After saving it, elaboration detected a missing timescale relative to the testbench. Adding `timescale 1ns/1ps resolved elaboration.

## Limitations
No formal proof, synthesis, power estimate, or maximum operating frequency established. The testbench clock is a stimulus setting, not timing closure.

## Interview preparation
Explain why 8x8 needs 16 product bits, how sign extension works, why accumulation needs more bits, reset versus clear, nonblocking assignment behavior, and why overflow is wraparound.
