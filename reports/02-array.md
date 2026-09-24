# 02 — Broadcast 4x4 MAC array

## Architecture
Sixteen MAC instances calculate C[i][j] = sum_k A[i][k]*B[k][j]. At each step k, a row input A[i][k] is broadcast across four MACs, while B[k][j] is broadcast down four MACs. This is output-stationary broadcast computation, not a systolic array. Four accepted steps calculate a 4x4 by 4x4 product, excluding clear and control overhead. Each step consumes four A bytes and four B bytes.

## Verification evidence
User Xcelium 23.09-s012 transcript, September 22, 2026: `PASS: 103 matrix tests, 1648 output checks`. Tests included identity, zero, signed extremes and 100 random matrix pairs. Accumulators were checked for clear and hold behavior. 1648 counts final output comparisons; additional clear checks are not included in that number.

## Debugging and unresolved cause
The first identity test initially reported expected 0 versus actual -8 at output [0][0]. -8 was the correct reference value. Replacing direct compound accumulation into the expected array with an explicit scalar reference sum and then assigning that sum to each output produced passing results. The original root cause was not established; do not label this a proven simulator defect. A subsequent editing error placed code outside the module; restoring the full testbench fixed parsing.

## Limitations
Array verification used K=4. No memories, convolution mapping, power or routed timing are established.

## Interview preparation
Trace a 2x2 example first. Explain one-output-per-MAC, operand reuse, local partial sums, why MAC count does not alone determine throughput, and the distinction from systolic transport.
