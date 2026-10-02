# Clock-gating implementation comparison

This compares the earlier 100 MHz `innovus_sitefix` baseline with `innovus_run2`. It is separate from the later 500 MHz pipelined sweep. Results are report-based estimates from the supplied archive, not silicon measurements.

## Measured comparison

| Metric | `innovus_sitefix` | `innovus_run2` | Change |
|---|---:|---:|---:|
| Die area (um2) | 399,050.008 | 237,543.966 | **40.47% smaller** |
| Estimated total power (mW) | 6.07484896 | 2.25225380 | **62.92% lower** |
| Hold-fix cell insertions summed over logged passes | 16,416 | 362 | **97.79% fewer insertions** |

Area is die area, not standard-cell area. The baseline [area excerpt](evidence/physical/innovus_sitefix/area-excerpt.txt) reports 399,050.008 um2. The optimized [implementation excerpt](evidence/physical/innovus_run2/implementation-excerpts.txt) records a 487.8 x 486.97 um die, giving 237,543.966 um2. The original approximately 41% description should be stated more precisely as approximately 40.5%.

The [baseline power report](evidence/physical/innovus_sitefix/rpt/09_power.rpt) and [optimized power report](evidence/physical/innovus_run2/rpt/09_power.rpt) both use setup_view, 0.9 V, default sequential/input activity 0.2, and no activity file. The [baseline](evidence/physical/innovus_sitefix/implementation-excerpts.txt) and [optimized](evidence/physical/innovus_run2/implementation-excerpts.txt) logs record a 10 ns clock period. This is a comparable reported default-activity estimate, not a workload-annotated power measurement. Floorplan utilization also changed (0.45 to 0.60), so attribute the difference to the implementation changes collectively, not clock gating alone.

The baseline log records hold-fix insertion passes of 16,158 + 196 + 30 + 32 = 16,416. The optimized log records 64 + 281 + 17 = 362. These are summed insertion events, not an independently counted final population of unique hold cells. The [Genus report](evidence/physical/synthesis_cg/clock_gating.rpt) records **262 clock-gating instances** and **17,048 gated flip-flops**.

## Equivalence

Conformal 23.10 logs establish 17,568 equivalent points (514 outputs + 17,054 DFF points) in both [RTL-to-synthesis](evidence/physical/lec_run2/lec_rtl2syn.txt) and [synthesis-to-PnR](evidence/physical/lec_run2/lec_syn2pnr.txt) comparisons. Unreachable/unmapped points and tool warnings remain visible in the logs. The referenced designs are the earlier clock-gated baseline; these results must not be presented as final pipelined equivalence.

## Static rail result

The [EIV summary](evidence/physical/innovus_run2/rail/PD_125C_avg_1/Reports/EIVDB/eivdb-summary.json) reports:

- Nominal VDD approximately 0.9 V; minimum instance VDD 0.899629712 V: approximately **0.370 mV VDD drop**.
- Maximum VSS approximately 0.000375403 V: approximately **0.375 mV ground rise**.
- Minimum effective VDD-VSS approximately 0.899254309 V: approximately **0.746 mV combined supply loss** relative to 0.9 V.

The rounded [VDD main report](evidence/physical/innovus_run2/rail/PD_125C_avg_1/Reports/VDD/VDD.main.rpt) alone does not resolve sub-millivolt differences; use the EIV data. The [VSS report](evidence/physical/innovus_run2/rail/PD_125C_avg_1/Reports/VSS/VSS.main.rpt) records a 0.375 mV maximum. These are static earlier-run estimates, not dynamic IR signoff for the 500 MHz variant.

## Provenance

Source paths, hashes, and excerpt rules are in the [October 2 manifest](evidence/physical/manifest-2026-10-02.json). Complete reports are copied verbatim; selected long implementation logs are represented by explicitly line-numbered excerpts. Licensed technology views, generated netlists/databases, and license configuration are not included.
