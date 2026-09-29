# Reproducing the recorded flow

## Requirements

Use an installed, licensed Cadence environment with Xcelium, Genus, Innovus, Tempus, and the GSCLIB045 views referenced by the scripts. The scripts retain the university installation paths and `/home/tumberpl/int8-cnn-accelerator` project root; adapt these paths on another machine. No technology library is included.

The supplied reports are historical results. The documentation and missing configuration were assembled after those runs; Cadence was not rerun as part of this repository update. Scripts do not capture every interactive change between the v2 and v3 experiments.

## Integrated simulation

From the repository root in a configured tcsh session:

```tcsh
setenv PIPE 0
source scripts/run_top.tcsh
```

For the pipelined variant, set `PIPE` to `1` and source the same script. Logs and compiled simulation files use separate variant directories. A pipeline regression PASS is not established by the supplied archive; check the logs and investigate any failures before using the variant as a verified baseline.

## Local LEF correction

The inspected GSCLIB045 macro LEF declares BUFX2 as 1 × 1.71 µm but assigns `CoreSiteDouble` (site height 3.42 µm). The project-local correction assigns that macro to `CoreSite` (height 1.71 µm). It changes only the BUFX2 SITE declaration and leaves the installed library untouched. This is a documented academic-flow workaround, not a vendor-certified library release.

From the repository root:

```sh
python3 scripts/prepare_lef.py /opt/eda/cadence/local/gsclib045_all/lan/flow/t1u1/reference_libs/GPDK045/gsclib045_all_v4.4/gsclib045/lef/gsclib045_macro.lef physical/lef/gsclib045_macro_bufx2_sitefix.lef
```

The script checks the expected macro dimensions and declaration and refuses to overwrite an existing output. Review other library versions before applying it. The generated LEF stays local.

## Synthesis sweep

In the configured tcsh environment, from the project root:

```tcsh
setenv PIPE 1
setenv CG 1
tcsh scripts/sweep/run_sweep.tcsh 2.5 2.22 2.0 1.82
```

Use `PIPE=0` for the original MAC. `CG=1` enables clock-gating insertion. The sweep scales the period and I/O maximum delays through `sdc_scale.tcl`; these are not experiments with identical absolute I/O budgets. The synthesis launcher requires the approved Genus launcher to be available in its child tcsh environment.

## Innovus and Tempus

`scripts/sweep/pnr_full.tcl` now reads the committed `constraints/mmmc_run2.tcl` template and replaces its historical SDC path with the selected sweep SDC. Do not source the template by itself from an arbitrary directory. It preserves the recorded slow/fast libraries, RC corners, and setup/hold views.

Example for a new 2.0 ns pipelined run, after its synthesis has completed:

```tcsh
setenv PERIOD 2.0
setenv PIPE 1
setenv CG 1
mkdir -p runs/pnr_sweep/p2.0_pipe_reproduce
cd runs/pnr_sweep/p2.0_pipe_reproduce
innovus -no_gui -files ../../../scripts/sweep/pnr_full.tcl -log pnr
```

After successful routing and SPEF export, return to the repository root and run Tempus in a separate output directory:

```tcsh
setenv PERIOD 2.0
setenv TAG p2.0_pipe_reproduce
mkdir -p runs/tempus_sweep/p2.0_pipe_reproduce
cd runs/tempus_sweep/p2.0_pipe_reproduce
tempus -files ../../../scripts/sweep/sta_sweep_tempus.tcl
```

Use the university-approved Tempus launcher if it is not on PATH. Review tool errors, SPEF annotation, `check_timing`, setup/hold, DRC, connectivity, and antenna reports. A completed tool process or a synthesis zero-WNS entry does not establish routed timing closure. LEC scripts are provided, but no final LEC pass transcript was included in the uploaded evidence.
