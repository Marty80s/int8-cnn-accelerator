# Milestones and acceptance criteria

| Stage | Work | Acceptance evidence |
|---|---|---|
| 00 | Environment and baseline import | Exact saved source files, documented tool versions, baseline run |
| 01 | Single MAC | Signed products, reset/clear priority, hold, randomized arithmetic, overflow |
| 02 | 4x4 array | All output elements match independent matrix reference |
| 03 | Controller | Input stalls, completion pulse, ignored busy start, repeated jobs, reset recovery |
| 04 | Configurable K | Capture K on start, define K=0 behavior, K=1 and maximum, stall handling |
| 05 | Memory-fed compute | Defined packing, synchronous latency, addresses, stale-data prevention |
| 06 | Convolution and quantization | Independent software reference; documented rounding and saturation |
| 07 | Small CNN | Layer-by-layer exact integer checks and held-out classification accuracy |
| 08 | Synthesis | Reviewed constraints, mapped netlist, area and timing; no unexplained latches |
| 09 | Physical implementation | Legal placement, clock tree, routing, extracted STA, documented remaining violations |
| 10 | Experiments | Common baseline/settings; comparable measurements and justified conclusions |

No board deployment is planned. Full physical SRAM integration depends on obtaining compatible Liberty, LEF, functional models and required physical views. Extraction data and layer-stack compatibility also need validation.

Study each milestone before expanding it: arithmetic example -> cycle trace -> RTL -> test -> report -> interview explanation.
