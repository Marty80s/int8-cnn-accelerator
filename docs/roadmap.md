# Project status and next steps

## Implemented and recorded

- Signed INT8 MAC, 4×4 array, fixed-four and configurable-K controllers.
- Synchronous operand memory, stalled reader, and integrated `accel_top`.
- Baseline directed simulation including integrated identity and accumulation tests.
- Optional product pipeline and clock-gated synthesis experiments.
- Genus clock sweeps; selected Innovus placement, CTS, routing, and Tempus analyses.
- Recorded 2.0 ns pipelined run with clean Innovus DRC, connectivity, and antenna checks.

## Remaining validation

- Complete and preserve simulation evidence for the final pipeline variant.
- Run and preserve RTL-to-synthesis and synthesis-to-route equivalence results.
- Resolve Tempus drive/constraint-coverage warnings and remaining setup/hold violations.
- Record exact source/configuration revisions and run-specific interactive changes for each experiment.
- Establish comparable activity assumptions before comparing power across variants.

## Future functionality

- Convolution scheduling or host-side im2col.
- Integer requantization, ReLU, and INT8 saturation.
- A small CNN checked against an independent integer reference model.

The current scope is a matrix engine with an academic physical-design study. Full CNN inference and timing-closed 500 MHz operation are not demonstrated by the supplied evidence.
