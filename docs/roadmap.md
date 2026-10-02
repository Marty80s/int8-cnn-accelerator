# Remaining work

The integrated memory-fed matrix engine and initial physical-design study are implemented. The latest archived pipeline run reports +1 ps setup and +4 ps hold at a 500 MHz target in its configured Tempus views.

1. Review and resolve or justify all timing-coverage and SPEF-annotation warnings for that run.
2. Save a functional regression and LEC results for the final pipelined variant, tied to an exact source commit and build configuration.
3. Make the environment-specific flow easier to reproduce, with explicit dependency preparation and run parameters.
4. Repeat controlled PPA experiments with common utilization and workload-derived activity, separating clock gating, pipelining, and floorplan effects.
5. Add convolution scheduling, quantization/requantization, and an independent integer reference before claiming complete CNN inference.
6. Evaluate SRAM integration only if compatible macro timing, physical, and functional views become available.

Existing results concern an academic 45 nm standard-cell implementation. No board deployment or fabricated-silicon result is claimed.
