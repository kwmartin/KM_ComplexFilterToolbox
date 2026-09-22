# Group-Delay Equalization for Complex IIR Filters — Session Summary

## Problem statement

Complex (not-necessarily-conjugate-symmetric) IIR filters designed by this
toolbox can have highly non-flat group delay across the passband, typically
with two large peaks near the passband edges and a much lower floor in the
middle (a "bathtub" shape). The goal of this work is to design a cascaded
**all-pass equalizer** — additional first-order all-pass sections cascaded
onto the filter — that flattens the group delay within the passband without
altering the magnitude response.

Two mathematical facts anchor everything below:

1. **All-pass sections used here are exactly magnitude-preserving for any
   complex pole**, via the classical conjugate-mirrored zero/pole
   construction (`lib/allPassClass.m` continuous, `lib/allPassDClass.m`
   discrete): `H(s) = (s+conj(wi))/(s-wi)` and
   `H(z) = (z^-1-conj(wi))/(1-wi*z^-1)`, where `wi` IS the pole location
   directly. This was verified algebraically and numerically earlier this
   session (`|H(jw)|=1` / `|H(e^jw)|=1` exactly, for any complex `wi`).
2. **A first-order all-pass's group-delay contribution (a Poisson kernel,
   `gd(w) = (1-r^2)/(1-2r*cos(w-theta)+r^2)` for pole radius `r`, angle
   `theta`) is provably positive at every frequency.** An equalizer can
   only *add* delay, never subtract it. This single fact explains most of
   the difficulty below: poles placed anywhere still leak positive delay
   into the pre-existing peaks, and poles placed *at* a peak only make
   that peak worse, never better.

## Initial approaches and how they failed

### Automated joint optimization — `lib/dsgnEqlzrD.m`

Jointly fits all `N` pole locations `(r_i, theta_i)` plus a free flat
target level `D`, via `fminimax` (Optimization Toolbox), minimizing
`max_f |gdH0(f) + sum_i gd_i(f) - D|`. The cost surface has multiple local
minima (documented in the file itself: a shared starting radius of 0.5 or
0.95 lands in a mediocre basin, 0.8 alone lands in a *worse* one than doing
nothing), so the function multi-starts from several shared radii and keeps
the best. Works reasonably — roughly 52.1 nominal-passband peak-to-peak
group delay from an unequalized 69.0 — but costs ~20 seconds per call and
needed the multi-start safety net to avoid bad basins.

### Cheap staged heuristic — `examples/dsgnEqlzrD_staged.m` and variants

A ~55x faster alternative avoiding the Optimization Toolbox entirely:
place `N` pole angles evenly across the sub-band between the filter's own
two largest peaks, do a 1-D `fminbnd` search over a single **shared**
radius, then coordinate-descend over each angle individually. Several
variants were tried and all failed in informative ways:

- **Shared radius, N=5**: gets close to `dsgnEqlzrD.m`'s nominal-passband
  result (55.0) at a fraction of the cost, but is *worse than doing
  nothing* on a wider "expanded" analysis band that includes some margin
  around the nominal passband (96.2 vs. 92.5 unequalized). The poles,
  confined away from the peaks, still leak enough delay via their tails to
  push the pre-existing peaks higher.
- **Increasing N with a shared radius**: does not fix this. The 1-D search
  trades a fixed total "boost" across more, individually weaker (lower
  `r`, hence *wider*, more leaky) bumps rather than narrower ones — the
  opposite of what's needed.
- **Per-section radius** (`dsgnEqlzrD_staged_perR.m`, `..._perR_seeded.m`):
  letting each pole have its own `r`, from scratch or seeded from the good
  shared-`r` result, did not reliably improve on it — a smaller-scale
  echo of the same rugged-landscape/local-minima problem that motivates
  `dsgnEqlzrD.m`'s own multi-start.
- **Peak-weighted cost** (`dsgnEqlzrD_staged_peakWeighted.m`): tried
  upweighting the cost near the filter's own peaks specifically. Had
  **zero effect at any weight from 1 to 500** — diagnosis showed the
  peaks were never actually the binding (worst-case) constraint; the
  analysis window's own edges were, so amplifying the peaks' weight never
  had anything to act on.
- **Unanchored peak-equi-ripple objective**
  (`dsgnEqlzrD_staged_peakEquiRipple.m`, early version): objective
  redefined as `max over peaks of |peak - mean(peaks)| * gain(f_peak)` —
  i.e. make the peaks match *each other*, gain-weighted. This had a
  critical flaw: with no anchor on absolute level, the optimizer
  discovered it could **invent brand-new peaks anywhere** (not the
  original ones) and drive them to match each other at an arbitrary
  (much too high) common height, satisfying the letter of the objective
  while making the true worst-case group delay catastrophically worse
  (p2p up to ~580, vs. 92.5 unequalized). A related bug (`fewer than 2
  peaks detected → free pass, cost 0`) let the optimizer collapse the two
  real peaks into a degenerate mess and score it as perfect.

### Manual/interactive exploration — `examples/dsgnEqlzrD_manual.m`

A hand-driven script: place clusters of identical first-order stages
(same `r`, same angle, several stacked) at chosen frequencies, plot group
delay, hit a `keyboard` breakpoint, adjust by hand, replot. This is where
the productive direction was actually found:

- Three clusters of 5 stages each, at the passband center, 25%, and 75%
  points, all at `r=0.85`: nominal-passband p2p **39.95** (better than the
  fminimax baseline's 52.1) but expanded-band p2p **101.2** (worse than
  unequalized) — the same leakage trade-off, but a better nominal result
  than anything automated had found.
- **Raising `r` for the edge-adjacent clusters, to try to narrow their
  bumps and reduce leakage, backfired badly.** At `r=0.95` it created two
  brand-new, enormous peaks (~300) *at the clusters' own location* — not
  more leakage at the edges, a new local blow-up. The reason: a single
  section's own peak height `(1+r)/(1-r)` grows far faster with `r` than
  the *fractional* leakage to distant points shrinks, and with 5 identical
  stages stacked at one angle this compounds multiplicatively. `r=0.90`
  was less catastrophic but still worse than the uniform `r=0.85` case on
  both metrics.
- Retuning to three clusters at 15%/54%/90% of the passband, `r=0.925`,
  5 stages each: nominal p2p **29.16** — the best result found by hand —
  with expanded-band p2p 117.4, the same persistent trade-off.

## Current approach: Newton-based iterative peak equalization

Given the above, two principles were established as constraints going
forward (explicitly, from direct user correction of an earlier wrong
suggestion):

- **Never place a pole at/near a peak** — it can only make that peak
  worse. Poles stay in the interior "safe zone" they always occupied.
- **The target is not zero deviation from a flat level** — it is a proper
  **equi-ripple balance**: the *gain-weighted* deviation from a fixed
  anchor should be equalized across the tracked peaks. A peak sitting
  where the filter's own gain has already rolled off (`|H(f)|<1`) is
  allowed a larger raw deviation than a full-gain peak, as long as the
  weighted products come out equal — the classical minimax
  equioscillation condition.

### Objective (final, anchored form)

Fix an **anchor** once: the unweighted mean of the *unequalized* filter's
two edge-peak group-delay values. For a set of pole "clusters" (each
cluster = `count_i` identical first-order all-pass stages stacked at one
frequency `theta_i` and radius `r_i`), track the *same two* peaks
iteration to iteration (never rediscovering an unconstrained peak set —
that was the earlier bug) and drive

```
w_j = |gd(f_peak_j) - anchor| * |H(f_peak_j)|      (j = 1, 2)
```

toward equality via a damped Newton/least-squares iteration on the
cluster angles, with **all radii held fixed**.

### One iteration (`examples/eqlzrD_peakNewtonStep.m`)

**Step A — refine peak locations.** On a small coarse grid around each
tracked peak's previous location, call `AnlzDH` on the *current* equalized
system to get `dTdW`/`d2TdW`. Bracket where `dTdW` crosses from `+` to `-`
(a group-delay local max), then take one Newton step:
`f_peak <- f_peak - dTdW(f_peak)/d2TdW(f_peak)`.

**Step B — update the cluster angles.** With the refined peak
frequencies/values, compute the *exact closed-form* Jacobian (no numerical
differentiation needed, since only cluster `i`'s own bump depends on
`theta_i`):

```
d(gd(w))/d(theta_i) = count_i * 2*r_i*(1-r_i^2)*sin(w-theta_i)
                        / (1 - 2*r_i*cos(w-theta_i) + r_i^2)^2
```

Assemble the `2 x nClusters` Jacobian of the weighted deviations `w_j`
with respect to each cluster's angle, and solve via pseudoinverse (there
are generally more free clusters than the 2 tracked peaks, an
underdetermined system) for the angle step that drives both `w_j` toward
their mean. Apply a **damped** fraction of this step (default 0.5) rather
than a full Newton step.

### Result

Run interactively, one step at a time
(`examples/dsgnEqlzrD_peakNewton_manual.m`), starting from the hand-tuned
3-cluster configuration above (15%/54%/90%, `r=0.925`, 5 stages each).
Convergence was clean: the weighted-deviation spread **halved every single
step** (1.73 → 0.74 → 0.37 → 0.19 → 0.09 → 0.047 → 0.023 → 0.012 over 8
steps), landing at:

- `p2p_nominal = 27.6` — the best result of the entire exploration.
- `p2p_expanded = 117.6` — the same persistent expanded-band trade-off
  seen throughout (this metric has never been better than "unequalized"
  in any approach that also achieves a good nominal-passband result).

## How to evaluate this, exactly, in MATLAB

Requires MATLAB with `lib/` and `examples/` on the path. The Newton
procedure itself needs **no Optimization Toolbox** (only `fminbnd`, base
MATLAB); the toolbox is only needed to reproduce the `dsgnEqlzrD.m`
baseline for comparison.

### 1. Build the reference test filter used throughout this exploration

```matlab
addpath('lib');
p = [-0.35 -0.25 -0.1 -0.08 0.25 0.35];
ni = 1;
wp = []; ws = [];
wp(1) = -0.025; wp(2) = 0.025;
ws = [-0.49 -0.049 0.049 0.49];
as = [70 50 50 70];
Ap = 0.05;
px = [];
[p_, px_, wp_, ws_] = shiftSpecs(p, px, wp, ws, 0.05);
cscdFltr1 = dsgnCscdFltr(p_, px_, ni, wp_, ws_, as, Ap, 'elliptic');
H = cscdFltr1.getSystem();
% wp_ = [0.025 0.075] (normalized cyclic frequency, Fs=1)
```

### 2. Run the current Newton procedure interactively

```matlab
cd examples
dsgnEqlzrD_peakNewton_manual
```

This builds `H`, sets up the anchor and the starting 3-cluster
configuration, plots the initial state, takes the **first** Newton step,
plots again, prints `info` (peak locations/values, gain at each peak, the
weighted deviations, the Jacobian, the raw step), then drops into a
`keyboard` breakpoint. From there, take additional steps by hand:

```matlab
[clusterTheta, info] = eqlzrD_peakNewtonStep(H, clusterTheta, clusterR, clusterCount, anchor, wp_);
plotCurrent(H, clusterTheta, clusterR, clusterCount, wp_, anchor);
```

Repeat as many times as desired, inspecting `info.weightedDev` and the
plot after each call. `dbcont` to finish, `dbquit` to abandon. (Note:
`eqlzrD_peakNewtonStep` now re-detects the full extremum set from scratch
every call from `wp_` alone -- it no longer takes or needs a peak-location
guess to thread between calls; see item 5 under "Suggested next steps"
below for why.)

### 3. Compute the figures of merit directly

```matlab
[~, stats] = estAllPassOrder(H, wp_);
f = stats.f(:); w = 2*pi*f;
idx_nom = f >= wp_(1) & f <= wp_(2);

wiVec = repelem(clusterR, clusterCount) .* exp(1j*repelem(clusterTheta, clusterCount));
eq = eqlzrDClass(wiVec(:), 1);
Heq = eq.applyTo(H);

[~,~,gdH0] = AnlzDH(H, w);
[~,~,gdH1] = AnlzDH(Heq, w);

p2p_nominal = max(gdH1(idx_nom)) - min(gdH1(idx_nom));
p2p_expanded = max(gdH1) - min(gdH1);
```

### 4. Compare against the baselines

```matlab
[eqBaseline, infoBaseline] = dsgnEqlzrD(H, wp_, 5);          % fminimax multi-start (~20s, needs Optimization Toolbox)
[eqStaged, infoStaged]     = dsgnEqlzrD_staged(H, wp_, 5);   % cheap shared-radius heuristic (~0.2s)
```

Both return `eq` (an `eqlzrDClass`) and an `info` struct with
`p2p_before`/`p2p_after` computed the same way.

## Suggested next steps

1. **Robustness to starting point.** Does the Newton procedure converge
   this cleanly from a different initial cluster configuration (different
   angles, radii, or number of clusters), or was the hand-tuned starting
   point already unusually favorable? Worth testing several starting
   configurations and checking convergence behavior, not just the final
   result.
2. **Sensitivity to step size.** The damping factor (default 0.5) was
   chosen per the "slowly adjust" instruction, not tuned. Does a larger
   step (closer to a full Newton step) converge faster without
   overshooting, given the clean halving-every-step behavior observed
   suggests the local landscape may already be near-linear?
3. **Generalization to a different filter.** Every result in this
   document uses the same one reference filter. Does this same procedure
   — same anchor definition, same two-peak tracking, same closed-form
   Jacobian approach — work comparably well on a different passband or
   filter order, or is it implicitly tuned to this specific filter's
   shape?
4. **The expanded-band trade-off.** Every approach that achieves a good
   nominal-passband result is worse than doing nothing on the wider
   expanded-band metric. Is this an acceptable, inherent cost of
   equalizing strictly within the specified passband (in which case the
   expanded-band metric may simply be the wrong thing to optimize), or is
   there a real fix available?
5. ~~**Beyond two tracked peaks.**~~ **Done.** Confirmed by hand (10
   iterations from the 3-cluster start grew 5 maxima + 4 minima, values
   208-240, while the 2-peak version's tracked pair sat at 118.5/118.5
   and reported spread=0.003 -- a false convergence). `eqlzrD_peakNewtonStep.m`
   now re-detects the *entire* current extremum set every call: scan
   d2TdW (group delay's second derivative) for zero crossings on a
   500-point grid over wp expanded 10% each side; between two consecutive
   inflection points d2TdW keeps one sign, so dTdW is monotonic there and
   crosses zero at most once, giving every bracket at most one genuine
   extremum (checked via a dTdW sign test at each bracket's endpoints,
   including the two boundary segments, which is what catches the edge
   peaks). No tunable prominence threshold. Re-detecting the set fresh
   each call is safe against the *earlier* bug (unanchored, self-
   referential peak matching) because the anchor here is fixed once,
   outside this function, from the unequalized filter -- growing the
   tracked set only ever adds constraints against that fixed external
   target, never something to game.

   One real limitation found while verifying this: the 500-point scan can
   miss a genuine but *shallow* interior extremum. Checked directly for
   the reference filter -- a real local max at f≈0.034 (gd≈222, only
   ~10-15 samples above its neighbors) was invisible to the 500-point
   scan (confirmed present via `findpeaks` on a 2000-point local grid)
   and caused two adjacent detected minima with no maximum between them
   in the reported list, which is not possible for a smooth curve. Also
   found (same investigation): very sharp, near-singular peaks made the
   coarse scan flag two adjacent brackets for what was really one
   extremum, refining to nearly the same frequency.

   Per direct instruction, both were addressed: `nGridPts` default raised
   500 -> 2000, and d2TdW is now median-filtered (`medfilt1`, window 5,
   `'truncate'` padding so the two boundary segments -- how the edge
   peaks get caught -- aren't distorted by the default zero-padding)
   before the zero-crossing scan, on top of the de-duplication pass
   already in place. Tested across three scenarios (the original
   3-cluster start; that configuration after 15 and 40 Newton steps; a
   deliberately sharper r=0.97 edge-cluster stress case) and all four
   combinations of {500,2000} x {filtered,unfiltered}: every combination
   gave identical results matching a 5000-8000 point `findpeaks` ground
   truth, so no deleterious effect was found -- but also no case where
   either change visibly mattered on *this* reference filter, since
   de-duplication already covered the specific failure mode both were
   meant to address further. Kept anyway as defensive robustness; a
   design sharper or noisier than this one could still need them.

   **A second, more serious bug was found re-confirming the 40-iteration
   run with these changes**, and it explains what actually looked like a
   missing-peak problem: Step A's refinement searched a fixed +/-0.01
   cycle window around each bracket's midpoint guess rather than the
   bracket itself. Once real extrema sit closer together than 0.01 apart
   (confirmed: two adjacent brackets only ~0.003-0.007 apart after the
   equalizer reshaped the curve), that fixed window reached past the
   intended bracket into a neighboring one and locked onto the wrong
   crossing -- silently "refining" to a nearby extremum's location, which
   then collided with, and was discarded by, de-duplication as an
   apparent duplicate. This -- not scan resolution -- is what caused the
   40-iteration run to report only 7 of 9 true extrema, missing the
   second edge peak (f≈0.076) entirely. Fixed by having the detection
   step return each extremum's own bracket bounds and confining
   refinement to those bounds, which are guaranteed (by the same
   inflection-point argument) to contain at most one extremum regardless
   of how close neighboring brackets are. Re-verified: the 40-iteration
   run now finds all 9 true extrema exactly, cross-checked against an
   8000-point `findpeaks` scan with every value matching. Convergence
   behavior unaffected -- still 0.53s total for all 40 steps, spread
   still plateaus (now at 23.1061, essentially the same as the 23.1747
   seen before this fix) by roughly step 16.
6. **Stopping criterion.** Iterations were run a fixed number of times by
   hand. A principled stopping rule (e.g. weighted-deviation spread below
   some tolerance, or step size below a threshold) would make the
   procedure usable non-interactively once trusted.
