# KM Complex Filter Toolbox

MATLAB routines for designing and realizing **complex filters**: filters
whose poles and zeros need not occur in complex-conjugate pairs, so the
frequency response need not be symmetric about zero. Such filters are used
wherever the signals are complex, for example in low-IF receivers,
image-reject architectures and filter banks. The toolbox covers analog and
digital filters with a single passband and upper and lower stopbands that
need not be symmetric.

## Background

The approach is based on the unpublished report by Martin Snelgrove et al.,
*Complex Analog Filters* (1981), included as
[`doc/snelgrove_cmplx.pdf`](doc/snelgrove_cmplx.pdf) with the author's
permission. It introduced the transformed variable $y^2$ used for the
approximation.

Development began in 2004. The approximation methods are described in
K. W. Martin, "Approximation of complex IIR bandpass filters without
arithmetic symmetry," *IEEE Trans. Circuits Syst. I*, vol. 52, no. 4,
pp. 794–803, Apr. 2005, included as
[`doc/Approximation_of_complex_IIR_bandpass_filters_without_arithmetic_symmetry.pdf`](doc/Approximation_of_complex_IIR_bandpass_filters_without_arithmetic_symmetry.pdf).
The toolbox was released under the GPLv3 in 2016 and has gone through many
iterations since. These added digital filters, cascade and ladder
realizations, filter banks and group-delay design, and substantially
improved numerical conditioning.

## What the toolbox does

**Approximation**
- Analog (`design_ctm_filt`) and digital (`design_dtm_filt`,
  `dsgnDigitalFltr`) transfer functions.
  - Equi-ripple or monotonic passbands, with arbitrary stopband
    specifications.
  - Movable and fixed loss poles (transmission zeros).
- Digital designs use the bilinear transform. The specifications are first
  shifted and scaled so the passband is normalized, which avoids the
  ill-conditioning of narrow passbands.

**Realization**
- Cascade filters of first- and second-order complex sections
  (`dsgnCscdFltr`, `mkCscdFltrD`, `cascadeClass`), with Monte Carlo
  sensitivity analysis (`runMcCscd`).
- Complex ladder filters (`ladderClass`).
- IIR filter banks (the `FltrBnk_*` and `Fbnk_*` examples).

**Group delay**
- Filters with equi-ripple group delay designed from linear-phase analog
  prototypes (`LinPhFltr`; `dig_linPh_*` and `dig_equiGd_*` examples).
  - `equiGdDigitalAp_scld` holds the passband edge at its specification.
- All-pass group-delay equalizers made of first-order complex sections
  (`eqlzrDClass`).
  - A minimax design (`dsgnEqlzrD`).
  - A two-phase Newton design that tunes clusters of identical sections
    (`dsgnEqlzrD_peakNewton_manual`, `eqlz_csc_newton_1_8_0`).
- A band-centred transform (`z2xc`, `xc2z`) that keeps narrow-band
  equalizer design well conditioned.

**Analysis and plotting**
- Magnitude, phase, group delay and their derivatives in closed form
  (`AnlzDH`).
- Paper-quality figures showing the full band and a passband zoom in one
  plot (`plotMgTwo`, `plotGdTwo`, `savePaperFig`).

Files ending in `_scld` are newer, band-scaled versions of existing
library functions. They are kept alongside the originals while the new
approach is evaluated (see [`ScldGD.md`](ScldGD.md)).

## Getting started

Requirements: MATLAB (tested with R2024b), the Control System Toolbox and
the Signal Processing Toolbox. The Optimization Toolbox is needed only for
the `fminimax`-based equalizers (`dsgnEqlzrD*`).

```matlab
cd examples
startup                 % adds ../lib to the path
design_examples         % analog and digital design examples
dig_fltr_2_10_1         % any individual example
```

Example names encode the loss poles: `dig_fltr_2_10_1` has 2 loss poles at
infinity (Nyquist for digital filters), 10 movable loss poles and 1 fixed
loss pole.

## Running all the examples

[`tools/run_all_examples.sh`](tools/run_all_examples.sh) runs every script
in `examples/` in a fresh MATLAB process. This exercises most of `lib/` and
catches errors and regressions that reading the code would not.

```
tools/run_all_examples.sh                 # all examples, 300 s timeout each
tools/run_all_examples.sh 600 'dig_*.m'   # a subset, with a longer timeout
```

Each example's output goes to `tools/reports/<timestamp>/<example>.log`,
with a summary in `tools/reports/<timestamp>/summary.txt`. Function files
are skipped automatically. The two slowest examples, `equiGd_Ap_scld`
(about 12 minutes) and `paper_examples_scld` (about 20 minutes), need a
longer timeout than the default, for example
`tools/run_all_examples.sh 1800 'equiGd_Ap_scld.m'`. `tools/monitor_progress.sh` shows the progress
of a run, and [`TestFilters.md`](TestFilters.md) explains how to use the
results. The most recent full run:

<details>
<summary>28 Sept 2026: 148 OK, 2 failed, 2 timed out, 10 skipped (function files); 53 min</summary>

```
Running examples/*.m with 300s timeout each. Logs/summary in tools/reports/20260928_130044
OK      (12s)     examples/chk_z2xc_1_6_0.m
OK      (7s)     examples/chk_z2xc_edges.m
OK      (77s)     examples/cmp_linPh_scld.m
OK      (14s)     examples/csc_fltr_1_10_0.m
OK      (16s)     examples/csc_fltr_1_12_0.m
OK      (15s)     examples/csc_fltr_1_2_0.m
OK      (13s)     examples/cscFltr_1_2_0.m
OK      (15s)     examples/csc_fltr_1_2_1b.m
OK      (13s)     examples/csc_fltr_1_2_1.m
OK      (14s)     examples/cscFltr_1_2.m
OK      (14s)     examples/csc_fltr_1_6_0.m
OK      (16s)     examples/csc_fltr_1_6_1.m
OK      (12s)     examples/csc_fltr_1_7_0.m
OK      (15s)     examples/csc_fltr_1_8_0b.m
OK      (13s)     examples/csc_fltr_1_8_0c.m
OK      (13s)     examples/csc_fltr_1_8_0.m
OK      (15s)     examples/csc_fltr_1_8_1.m
OK      (8s)     examples/dbg.m
OK      (18s)     examples/design_examples.m
OK      (13s)     examples/dfltr_1_2.m
OK      (10s)     examples/dfltr_1_6_1.m
OK      (17s)     examples/dfltr_1_7_0.m
OK      (11s)     examples/dfltr_1_7_1.m
OK      (12s)     examples/dfltr_1_8_0b.m
OK      (17s)     examples/dfltr_1_8_0c.m
OK      (22s)     examples/dfltr_1_8_0.m
OK      (12s)     examples/dfltr_2_6_2.m
OK      (20s)     examples/dig_equiGd_1_10_0.m
OK      (21s)     examples/dig_equiGd_1_10_0_scld.m
OK      (30s)     examples/dig_equiGd_1_12_0.m
OK      (31s)     examples/dig_equiGd_1_12_0_scld.m
OK      (32s)     examples/dig_equiGd_1_15_0.m
OK      (34s)     examples/dig_equiGd_1_15_0_scld.m
OK      (26s)     examples/dig_equiGd_15_0_0.m
OK      (25s)     examples/dig_equiGd_15_0_0_scld.m
OK      (16s)     examples/dig_equiGd_1_6_0.m
OK      (17s)     examples/dig_equiGd_1_6_0_scld.m
OK      (17s)     examples/dig_equiGd_3_10_0.m
OK      (22s)     examples/dig_equiGd_3_10_0_scld.m
OK      (26s)     examples/dig_equiGd_3_4_0.m
OK      (26s)     examples/dig_equiGd_3_4_0_scld.m
OK      (27s)     examples/dig_equiGd_5_0_0.m
OK      (27s)     examples/dig_equiGd_5_0_0_scld.m
OK      (23s)     examples/dig_equiGd_5_10_0.m
OK      (23s)     examples/dig_equiGd_5_10_0_scld.m
OK      (11s)     examples/dig_fltr_0_2_0.m
OK      (11s)     examples/dig_fltr_1_2_0.m
OK      (10s)     examples/dig_fltr_1_2.m
OK      (12s)     examples/dig_fltr_1_3_1.m
OK      (10s)     examples/dig_fltr_1_4.m
OK      (12s)     examples/dig_fltr_1_5_1.m
OK      (25s)     examples/dig_fltr_2_10_1.m
OK      (11s)     examples/dig_fltr_2_5_1.m
OK      (15s)     examples/dig_fltr_2_6_1.m
OK      (23s)     examples/dig_fltr_2_7_1.m
OK      (24s)     examples/dig_fltr_2_8_1.m
OK      (20s)     examples/dig_fltr_2_9_1.m
OK      (12s)     examples/dig_fltr_3_5_1.m
OK      (12s)     examples/dig_fltr_3_6_1.m
OK      (14s)     examples/dig_linPh_0_2_0.m
OK      (16s)     examples/dig_linPh_0_2_0_scld.m
OK      (17s)     examples/dig_linPh_1_2_0b.m
OK      (15s)     examples/dig_linPh_1_2_0.m
OK      (17s)     examples/dig_linPh_1_2_0_scld.m
OK      (13s)     examples/dig_linPh_1_4_0.m
OK      (14s)     examples/dig_linPh_1_4_0_scld.m
OK      (21s)     examples/dig_linPh_1_6_0.m
OK      (23s)     examples/dig_linPh_1_6_0_scld.m
OK      (23s)     examples/dig_linPh_1_8_0.m
OK      (14s)     examples/dig_linPh_1_8_0_scld.m
OK      (15s)     examples/DLddrFltr_1_2_0.m
OK      (14s)     examples/DLddrFltr_1_4_0.m
OK      (19s)     examples/DLddrFltr_1_6_0.m
OK      (13s)     examples/DLddrFltr_1_8_0.m
SKIP (function file)  examples/dsgnEqlzrD_hybrid.m
OK      (12s)     examples/dsgnEqlzrD_manual.m
OK      (12s)     examples/dsgnEqlzrD_peakNewton_manual.m
OK      (14s)     examples/dsgnEqlzrD_staged_demo.m
SKIP (function file)  examples/dsgnEqlzrD_staged.m
SKIP (function file)  examples/dsgnEqlzrD_staged_peakEquiRipple.m
SKIP (function file)  examples/dsgnEqlzrD_staged_peakWeighted.m
SKIP (function file)  examples/dsgnEqlzrD_staged_perR.m
SKIP (function file)  examples/dsgnEqlzrD_staged_perR_seeded.m
SKIP (function file)  examples/dsgnEquiRplGD.m
OK      (6s)     examples/dsgn_fltr2.m
OK      (12s)     examples/eqlz_csc_1_8_0.m
OK      (16s)     examples/eqlz_csc_newton_1_8_0.m
SKIP (function file)  examples/eqlzrD_peakNewtonStep.m
SKIP (function file)  examples/eqlzrD_peakNewtonStepX_scld.m
OK      (36s)     examples/EqualFltr_1_6_0.m
OK      (20s)     examples/EqualRipple_1_6_0.m
TIMEOUT (300s)     examples/equiGd_Ap_scld.m
OK      (9s)     examples/exmpl0.m
OK      (10s)     examples/exmpl10.m
OK      (10s)     examples/exmpl_1_1_0.m
OK      (11s)     examples/exmpl11.m
OK      (11s)     examples/exmpl12.m
OK      (11s)     examples/exmpl_1_5_0b.m
OK      (11s)     examples/exmpl_1_5_0.m
OK      (11s)     examples/exmpl_1_5_1.m
OK      (13s)     examples/exmpl1.m
OK      (11s)     examples/exmpl_2_1b.m
OK      (11s)     examples/exmpl_2_1c.m
OK      (10s)     examples/exmpl_2_1.m
OK      (11s)     examples/exmpl_2_5_0.m
OK      (11s)     examples/exmpl2.m
OK      (10s)     examples/exmpl3.m
OK      (10s)     examples/exmpl4.m
OK      (12s)     examples/exmpl_5_1_1.m
OK      (10s)     examples/exmpl5.m
OK      (11s)     examples/exmpl6.m
OK      (11s)     examples/exmpl7.m
OK      (11s)     examples/exmpl8.m
OK      (17s)     examples/exmpl9.m
OK      (10s)     examples/exmpl.m
FAILED  (11s)     examples/exmpl_r1b.m -- Pole Removals Failed
OK      (11s)     examples/exmpl_r1.m
OK      (21s)     examples/Fbnk_1_10_0.m
OK      (22s)     examples/Fbnk_1_12_0.m
OK      (23s)     examples/Fbnk_1_14_0.m
OK      (17s)     examples/Fbnk_1_8_0.m
OK      (10s)     examples/fltr_0_5_0.m
OK      (12s)     examples/fltr_1_10_0b.m
OK      (13s)     examples/fltr_1_10_0.m
OK      (11s)     examples/fltr_1_2_0b.m
OK      (12s)     examples/fltr_1_2_0.m
OK      (11s)     examples/fltr_1_5_0.m
OK      (11s)     examples/fltr_1_5_1b.m
OK      (11s)     examples/fltr_1_5_1.m
OK      (11s)     examples/fltr_1_6_0.m
OK      (10s)     examples/fltr_1_8_0.m
OK      (12s)     examples/fltr_1_9_0.m
OK      (9s)     examples/fltr1.m
OK      (11s)     examples/fltr_2_0_0B.m
OK      (12s)     examples/fltr_2_0_0.m
OK      (9s)     examples/fltr_2_2_2.m
OK      (11s)     examples/fltr_2_5_0.m
OK      (10s)     examples/fltr_2_6_0.m
OK      (10s)     examples/fltr_2_7_1.m
OK      (10s)     examples/fltr2.m
OK      (10s)     examples/fltr_3_6_0.m
OK      (11s)     examples/fltr_3_8_1.m
OK      (17s)     examples/FltrBnk_1_4_0.m
OK      (11s)     examples/FltrBnk_1_4_2e.m
OK      (16s)     examples/FltrBnk_1_6_0e.m
OK      (18s)     examples/FltrBnk_1_6_0.m
OK      (12s)     examples/FltrBnk_1_8_0.m
OK      (11s)     examples/FltrBnk_tst2.m
OK      (11s)     examples/FltrBnk_tst.m
OK      (10s)     examples/flt_tmp.m
OK      (10s)     examples/mkFltr_exmpl.m
OK      (8s)     examples/mkYaml.m
TIMEOUT (300s)     examples/paper_examples_scld.m
OK      (53s)     examples/paper_figs_scld.m
OK      (113s)     examples/shrink_band_scld.m
OK      (177s)     examples/shrink_eqlzr_scld.m
OK      (15s)     examples/shrink_peakNewton_scld.m
OK      (7s)     examples/startup.m
SKIP (function file)  examples/test.m
OK      (7s)     examples/tst_digital2Cont.m
OK      (12s)     examples/tst_getEvnOdd.m
FAILED  (11s)     examples/tstTFops.m -- Pole Removals Failed


=== Summary ===
OK:      148
FAILED:  2
TIMEOUT: 2
SKIPPED: 10
Total wall time: 3167s
```

</details>

## Documentation

- [`doc/References.pdf`](doc/References.pdf): the papers, reports and
  books used in developing the toolbox, each with a note on its relevance.
- [`doc/snelgrove_cmplx.pdf`](doc/snelgrove_cmplx.pdf): the Snelgrove et
  al. report the toolbox is based on.
- Working notes on recent development, in the repository root:
  - [`ScldGD.md`](ScldGD.md): the band-scaled (`_scld`) group-delay work;
  - [`Eqlzr_scld_results.md`](Eqlzr_scld_results.md): results for
    holding the passband edge;
  - [`ComplexEqualizationIIR.md`](ComplexEqualizationIIR.md): the
    all-pass cluster equalizers;
  - [`Issues.md`](Issues.md) and [`Progress.md`](Progress.md): open
    issues and progress;
  - [`TestFilters.md`](TestFilters.md): how to run the examples as a
    test suite and use the results.
- [`MakePaper.md`](MakePaper.md) and
  [`doc/make_tex_flow.md`](doc/make_tex_flow.md): how papers and the
  reference list are generated from YAML with `tools/make_ieee_tex.py` and
  `tools/make_references.py`.

## Acknowledgments

The approach rests on the work of Martin Snelgrove and his co-authors on
complex analog filters. Claude, from Anthropic, was used to help find and
remove many bugs, and to help with the recent development and testing.

Bug reports and suggestions are welcome: martin@granitesemi.com.

## License

Toolbox for the Design of Complex Filters, Copyright (C) 2004–2026 Kenneth
Martin.

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option)
any later version. It is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
Public License for more details: <https://www.gnu.org/licenses/>.
