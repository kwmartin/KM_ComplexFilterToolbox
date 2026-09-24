# Group-delay work with `_scld` files: results and restart notes

Written 2026-09-24 at the end of a session, as a handoff for the next one.
Full details are in `ScldGD.md` (sections 1–11). **All work uses new files**
(`*_scld.m`, plus a few new helpers); no original `lib/` or `examples/` file
was changed.

## Where things stand

| Topic | Status | Where |
|---|---|---|
| Band-centred transform `z2xc`/`xc2z` | done, checked | ScldGD.md section 2 |
| `dig_linPh` group-delay stage (was silently reverted) | fixed: Nyquist extremum + collapsed prototype | sections 3–5 |
| Transformed-variable extrema grid (`fndZeroCrsX_scld`) | works to 1e-12-cycle bands; a z grid scaled to the band does as well | sections 7, 10 |
| All-pass equalizers (`dsgnEqlzrD`, `eqlzrD_peakNewtonStep`) | x-parametrized copies are identical at every width 5e-2 to 5e-5; the originals degrade to 167–176% | sections 8, 9 |
| Absolute tolerances (`R_MAX`, `simpl`) | scaled to the band in `_scld` copies | section 10 |
| `dig_equiGd` series broken (poles pinned at 0.995, stopband gain) | fixed with `adaptP2_scld` | section 11 |
| `dig_equiGd` passband only 0.25–0.37 of wp | **new today:** `equiGdDigitalAp_scld` holds Ap at wp, with ws at 4–6x wp | below |
| Paper numbers in one run | `examples/paper_examples_scld.m` (about 20 minutes) | section 11 |

## Today: holding the passband edge at wp in the `dig_equiGd` designs

### The problem

In every `dig_equiGd_*_scld` design, the band within Ap of the passband peak is
only 0.25–0.37 of wp, and the loss at the wp edge is 9–36 dB. The worst case
is `dig_equiGd_1_10_0`: 36.3 dB at the wp edge against Ap = 3.01 dB.

### Where the band narrows

`dig_equiGd_1_10_0`, traced stage by stage:

| after | Ap band / wp | loss at wp edge | GD p2p |
|---|---|---|---|
| prototype → z (`cont2Digital`) | 1.00 | 3.01 dB | 0.11% |
| `adaptP2_scld` | 0.34 | 30.3 dB | 1.36% |
| zeros set to the loss poles | 0.34 | 30.4 dB | 1.36% |
| `place_polesdLP5` | 0.31 | 36.3 dB | 1.36% |

- `adaptP2` narrows the band about 3x. It seems to squeeze the prototype's
  wider equal-ripple region into wp (not verified in the code).
- `place_polesdLP5` narrows it further when it moves zeros toward the band.
- The Ap edge is set only on the prototype; nothing afterwards restores it.

### What was tried (scratchpad scripts, not in the repo)

1. **Skip `adaptP2`, or rescale after it in x** (exact frequency scaling of
   the x-domain roots). The Ap band only reaches 0.50–0.59, because
   `place_polesdLP5` narrows it again.
2. **Outer loop over the whole design**, widening the design band until the
   final Ap edge is at wp.
   - With the original ws = 2x wp it converges, but the stopband collapses to
     4 dB (`1_6_0`) and 12 dB (`1_10_0`) against the 20 dB spec.
   - Without `adaptP2` it oscillates.

**Conclusion:** at these orders a flat-group-delay filter cannot meet Ap at wp
and 20 dB at 2x wp. The original designs met the stopband by narrowing the
passband.

### Implemented

- **`lib/equiGdDigitalAp_scld.m`** is an outer loop around
  `equiGdDigital_scld`.
  - It widens the design band about the centre of wp by a factor k and
    measures the final Ap band b.
  - Step rule: k = 1, then k = 1/b, then secant steps on log b against
    log k, with the step halved after repeated overshoots.
  - It stops when |b - 1| < 0.005, or after 8 designs, and keeps the best
    design.
  - k is capped so the design band stays inside the stopband edges and clear
    of the loss poles (0.95 of the room).
- **`examples/equiGd_Ap_scld.m`** re-runs all 9 `dig_equiGd` specs as they are
  (base), then with the Ap loop at ws = 4x and 6x wp's half-width.
  - Loss poles that would fall inside the new transition band are moved just
    outside it, keeping their order. These rows are marked * in the table.
  - The run takes about 12 minutes.

### Results (`examples/equiGd_Ap_scld.m`)

Ap band = half-width within Ap of the peak / wp half-width (1 means the Ap edge
is at wp). k = design-band factor. "Stop" is the minimum stopband loss
relative to the passband peak.

| spec | variant | k | Ap band | wp-edge loss | GD p2p | stop | designs |
|---|---|---|---|---|---|---|---|
| 1_6_0 (Ap 1) | base | 1 | 0.253 | 17.35 | 0.20% | 92.1 | 1 |
| | ws 4x | 3.80 (cap) | 0.741 | 1.81 | 0.76% | 50.3 | 8 |
| | **ws 6x** | 4.62 | **1.000** | **1.00** | 0.93% | 63.0 | 5 |
| 1_10_0 (Ap 3.01) | base | 1 | 0.309 | 36.33 | 1.36% | 150.3 | 1 |
| | ws 4x | 3.80 (cap) | 0.966 | 3.26 | 0.40% | 77.6 | 8 |
| | **ws 6x** | 3.25 | **1.001** | **3.02** | 0.34% | 140.1 | 4 |
| 1_12_0 (Ap 3.01) | base | 1 | 0.318 | 33.57 | 0.71% | 148.1 | 1 |
| | ws 4x* | 3.25 | 0.943 | 3.40 | 2.79% | 85.1 | 8 |
| | **ws 6x*** | 2.98 | **0.998** | **3.04** | 2.36% | 173.9 | 3 |
| 1_15_0 (Ap 3.01) | base | 1 | 0.327 | 30.67 | 0.68% | 153.3 | 1 |
| | ws 4x* | 3.77 | 1.003 | 2.99 | 3.13% | 88.0 | 4 |
| | **ws 6x*** | 3.05 | **1.017** | **2.92** | 2.31% | 170.8 | 8 |
| 15_0_0 (Ap 3.01) | base | 1 | 0.340 | 29.04 | 0.71% | 113.9 | 1 |
| | ws 4x | 3.00 | 0.937 | 3.45 | 2.37% | 91.3 | 8 |
| | **ws 6x*** | 2.91 | **1.000** | **3.01** | 2.28% | 152.9 | 2 |
| 3_4_0 (Ap 1) | base | 1 | 0.340 | 8.98 | 0.18% | 254.2 | 1 |
| | ws 4x | 3.00 | 0.999 | 1.00 | 0.54% | **17.0** | 3 |
| | **ws 6x** | 3.00 | **0.999** | **1.00** | 0.54% | 45.1 | 3 |
| 3_10_0 (Ap 3.01) | base | 1 | 0.319 | 32.78 | 0.10% | 158.5 | 1 |
| | ws 4x | 3.80 (cap) | 0.964 | 3.32 | 0.38% | 77.5 | 8 |
| | **ws 6x** | 3.13 | **1.000** | **3.06** | 0.31% | 150.7 | 4 |
| 5_0_0 (Ap 3.01) | base | 1 | 0.371 | 23.06 | 0.65% | 116.8 | 1 |
| | ws 4x / 6x | 3.11 | 0.920 | 23.48 | **1135%** | 27 / 75 | 8 |
| 5_10_0 (Ap 3.01) | base | 1 | 0.333 | 29.11 | 0.65% | 157.4 | 1 |
| | ws 4x* | 3.80 | 0.629 | 163.3 | **469%** | 296.9 | 8 |
| | ws 6x* | 1.87 | 1.137 | 233.7 | **465%** | 447.4 | 8 |

### Reading the results

- **ws = 6x wp works for 6 of the 9 specs:** `1_6_0`, `1_10_0`, `1_12_0`,
  `1_15_0`, `15_0_0` and `3_10_0`.
  - The Ap edge is at wp to within 2% (loss at the wp edge within 0.1 dB of
    Ap).
  - GD p2p is 0.3–2.4%, and the stopband loss is 63–174 dB, far above the
    20 dB spec.
  - The GD ripple is higher than in the base designs (for example 0.7% →
    2.4% for the wide-band `1_12_0`). The group delay is now equalized over
    a band about 3x wider, where the base designs only met Ap on about a
    third of wp.
- **ws = 4x wp is marginal.**
  - For `1_6_0`, `1_10_0` and `3_10_0`, k hits its cap (0.95 x 4 = 3.8), so the
    design band cannot widen enough: Ap band 0.74–0.97.
  - `3_4_0` holds Ap but its stopband is 17.0 dB, below the 20 dB spec.
- **`3_4_0` at 6x:** Ap is held, GD p2p is 0.54%, but its stopband is only
  45 dB.
- **`5_0_0` and `5_10_0` fail.** The loop produces broken designs: GD p2p of
  465–1135%, and for `5_10_0` 163–234 dB of loss at the wp edge. These have
  many loss poles at infinity (ni = 15 and 5). Not investigated.
- Rows marked * had their loss poles moved out of the new transition band,
  so they are not the same loss-pole guesses as the original examples.

## Suggested next steps

1. **Investigate `5_0_0` and `5_10_0` under the Ap loop.** The failure is
   probably in `place_polesdLP5` or `adaptP2_scld` with a widened band and
   many zeros at infinity. Look at the per-iteration `info.history`.
2. **Try an in-loop fix instead of the outer loop.** Restrict `adaptP2`'s
   equalization to the extrema inside the design band, so it stops squeezing
   the prototype's equal-ripple region into wp. This might keep the Ap edge
   without the loop. Untested.
3. **Try relaxing the group-delay target.** `equiGdDigital` asks
   `LinPhFltr(Ordr, 0.01, Ap)` for 0.01 ripple. A larger value gives a
   sharper magnitude roll-off and may allow ws closer to wp. Untested.
4. **For the paper, decide which specs to present.** The Ap-held designs at
   ws = 6x wp are the defensible ones; the original 2x specs cannot hold Ap at
   wp. The `dig_equiGd` rows in `paper_examples_scld.m` still use the original
   specs (base designs), so they would need updating to use
   `equiGdDigitalAp_scld`.
5. **Other open items** (see ScldGD.md section 6):
   - passband loss drifts from Ap after `adaptP3` (`Progress.md` item 7);
   - `EqualFltr_1_6_0`'s stopband is 9.3 dB against 50 dB;
   - `eqlz_csc_1_8_0`, `eqlz_csc_newton_1_8_0` and `dsgnEqlzrD_staged_demo`
     have not been measured.

## How to re-run

```matlab
cd /home/Dropbox/Matlab/Complex/KM_ComplexFilterToolbox
addpath('lib'); addpath('examples');
equiGd_Ap_scld          % this table, about 12 minutes
paper_examples_scld     % all paper numbers, about 20 minutes (flags at the top)
```
