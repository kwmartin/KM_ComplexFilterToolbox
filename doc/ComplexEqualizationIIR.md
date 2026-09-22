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

## Design Procedure

*This section states the complete equalizer design procedure on its own,
independent of the exploration that produced it, in a form intended to be
reusable close to verbatim in a paper. The sections that follow
("Initial approaches and how they failed" onward) document the
exploratory work, failed alternatives, bugs, and empirical findings that
led to it, and are retained as supporting material and implementation
history.*

### A. Filter model and all-pass building block

Let $H(z)$ be a (possibly complex, non-conjugate-symmetric) discrete-time
IIR filter with passband $[f_{p1}, f_{p2}]$ in normalized cyclic
frequency ($F_s = 1$), and let $\tau_H(f)$ denote its group delay.
Complex IIR filters designed without an arithmetic-symmetry constraint
typically exhibit a markedly non-flat, "bathtub"-shaped group delay: two
peaks near the passband edges bridged by a lower floor across the
interior. The goal is a cascaded all-pass equalizer that flattens
$\tau_H$ across the passband without altering $|H(e^{j\omega})|$.

The equalizer is a cascade of $N$ first-order discrete all-pass
sections. Each section is parameterized by a single complex pole
$p_i = r_i e^{j\theta_i}$, $0 < r_i < 1$:

$$
A_i(z) \;=\; \frac{z^{-1} - \overline{p_i}}{1 - p_i\, z^{-1}}. \tag{1}
$$

This construction is magnitude-preserving for any complex $p_i$:
$|A_i(e^{j\omega})| = 1$ for all real $\omega$, so cascading $A_i$ onto
$H$ leaves $|H(e^{j\omega})|$ unchanged and only modifies phase/group
delay. The group-delay contribution of a single section is the Poisson
kernel

$$
\tau_i(\omega) \;=\; \frac{1 - r_i^2}{1 - 2 r_i \cos(\omega - \theta_i) + r_i^2},
\qquad \tau_i(\omega) > 0 \ \ \forall\, \omega. \tag{2}
$$

Because $\tau_i(\omega) > 0$ everywhere, an all-pass cascade can only
*add* delay: it can raise a low floor toward the level of existing
peaks, but it cannot directly lower a peak, and a section placed too
close to an existing peak only adds to it.

For implementation convenience, sections are grouped into $M$
*clusters*: cluster $i$ consists of $c_i$ identical stacked sections
sharing one pole $(r_i, \theta_i)$, so $N = \sum_i c_i$, and the total
equalizer delay is

$$
\tau_{eq}(\omega; \boldsymbol\theta, \mathbf r) \;=\; \sum_{i=1}^{M} c_i\, \tau_i(\omega; r_i, \theta_i),
\qquad
\tau(\omega) \;=\; \tau_H(\omega) + \tau_{eq}(\omega). \tag{3}
$$

### B. Design objective: anchored, gain-weighted equi-ripple balance

Fix an **anchor** level once, from the *unequalized* filter alone:

$$
D_0 \;=\; \operatorname{mean}\Big(\tau_H(f) : f \text{ a local extremum of } \tau_H\Big), \tag{4}
$$

in practice the mean of the filter's own two edge-of-passband peaks.
$D_0$ is never recomputed once fixed, which keeps the objective anchored
to an external, fixed target rather than to the equalizer's own
(evolving) output — an unanchored objective was found in practice to let
the optimizer invent new peaks and match them to each other at an
arbitrarily poor common level (§Objective, below).

For a given $(\boldsymbol\theta, \mathbf r)$, let $\{f_k\}_{k=1}^K$ be the
frequencies of *every* local extremum (maxima and minima) of
$\tau(\cdot)$ over the passband expanded by a margin fraction $\mu$ on
each side (default $\mu=0.10$), redetected from scratch at every
iteration (§C). Define the gain-weighted deviation from the anchor at
each extremum:

$$
w_k \;=\; \big|\tau(f_k) - D_0\big| \cdot |H(f_k)|, \qquad k = 1, \dots, K. \tag{5}
$$

The design goal is the classical Chebyshev equi-ripple condition: choose
$(\boldsymbol\theta, \mathbf r)$ so that all $w_k$ are equal. Weighting
by the filter's own gain $|H(f_k)|$ allows an extremum sitting where
$|H|$ has already rolled off to carry a proportionally larger raw delay
deviation without violating equality of the weighted terms — the
deviation that matters is the one seen at the filter's output, not the
raw group-delay number.

### C. One Newton/least-squares iteration

Given a current configuration $(\boldsymbol\theta, \mathbf r)$, one
iteration proceeds in two steps.

**Step 1 — extremum detection and refinement.** Evaluate $\tau''(\omega)$
on a uniform grid over the expanded band and locate its zero crossings
(each pair of consecutive crossings, plus the two boundary segments,
brackets at most one true extremum of $\tau$, since $\tau'$ is monotonic
wherever $\tau''$ keeps one sign). Within each occupied bracket, confirm
the extremum type from the sign of $\tau'$ at the bracket's endpoints,
then refine its location with one Newton step:

$$
f_k \;\leftarrow\; f_k \;-\; \frac{\tau'(f_k)}{\tau''(f_k)}. \tag{6}
$$

**Step 2 — parameter update.** Because cluster $i$'s contribution
depends only on its own $(r_i,\theta_i)$, the Jacobian of $\tau$ with
respect to each cluster parameter is available in closed form:

$$
\frac{\partial \tau(\omega)}{\partial \theta_i} \;=\; c_i\,\frac{2 r_i (1-r_i^2)\sin(\omega-\theta_i)}{D_i(\omega)^2}, \tag{7}
$$

$$
\frac{\partial \tau(\omega)}{\partial r_i} \;=\; c_i\left(\frac{-2 r_i}{D_i(\omega)} \;-\; \frac{2(1-r_i^2)\big(r_i - \cos(\omega-\theta_i)\big)}{D_i(\omega)^2}\right), \tag{8}
$$

$$
D_i(\omega) \;=\; 1 - 2 r_i \cos(\omega-\theta_i) + r_i^2. \tag{9}
$$

Assemble the Jacobian $J \in \mathbb{R}^{K \times M}$ (angle-only) or
$J \in \mathbb{R}^{K \times 2M}$ (joint angle+radius) of the weighted
deviations, row $k$ given by
$J_{k,i} = \operatorname{sign}\big(\tau(f_k)-D_0\big)\,|H(f_k)|\,\partial\tau(f_k)/\partial\theta_i$
(and analogously for $\partial/\partial r_i$). Solve, via the
Moore-Penrose pseudoinverse (the system is neither reliably square nor
consistently over/under-determined, since $K$ changes call to call),

$$
\Delta \;=\; J^{+}\big(\bar w \,\mathbf 1 - \mathbf w\big), \qquad \bar w = \frac1K \sum_{k=1}^K w_k, \tag{10}
$$

the least-squares parameter step that drives every $w_k$ toward their
common mean, then apply a damped update

$$
\boldsymbol\theta \leftarrow \boldsymbol\theta + \alpha\, \Delta_\theta, \qquad
\mathbf r \leftarrow \mathbf r + \alpha\, \Delta_r \ \ (\text{if radii are free}), \tag{11}
$$

with damping factor $\alpha \in (0,1]$, and radii clamped to
$[r_{\min}, r_{\max}] = [0.3, 0.995]$ after the update.

### D. Two-phase iteration schedule

**Phase 1 (angle-only).** Radii held fixed; repeat §C with damping
$\alpha = \alpha_1$ until the ripple spread $S = \max_k w_k - \min_k w_k$
changes by less than a tolerance $\epsilon$ between consecutive
iterations, or a maximum iteration budget is reached. This phase
converges monotonically in practice.

**Phase 2 (joint angle + radius).** Continuing from the Phase 1 result,
free the radii and repeat §C with damping $\alpha = \alpha_2$, now
updating $J$'s $r$-columns as well. This phase does *not* converge
monotonically: $S$ reaches a minimum after a small number of steps, then
drifts upward again while flatness just outside the nominal passband
continues to improve — a genuine trade-off, not simple convergence to a
fixed point. Accordingly, Phase 2 tracks the best (smallest) $S$ seen so
far and stops after $P$ consecutive non-improving iterations,
**returning the best configuration found**, not the final iterate.

### E. Starting configuration and step-size selection

The iteration is initialized with $M$ clusters of $c$ stacked sections
each, pole angles spread across the passband (evenly, or symmetrically
if the filter's own specification is symmetric), and a common starting
radius $r_0$. Two empirical rules govern the free parameters:

- **Damping must shrink as $M$ grows relative to $K$.** With more free
  angle/radius parameters against roughly the same number of tracked
  extrema, the pseudoinverse step becomes more aggressive per unit
  residual; the default $\alpha=0.5$, stable at $M=3$, produces outright
  divergence at $M=5$ (oscillating extremum count, radii pinned at their
  clamp bounds) unless $\alpha_1,\alpha_2$ are reduced (e.g. to
  $0.2/0.1$, or smaller still when perturbing a starting point that is
  already known to be reasonable).
- **Lower $r_0$ suits wider passbands.** A single section's own peak
  height $(1+r_i)/(1-r_i)$ grows far faster with $r_i$ than its
  fractional leakage to distant frequencies shrinks; for a passband
  spanning a large fraction of the full cycle, a lower, broader starting
  radius blends clusters into a smooth correction rather than a sequence
  of narrow, high-$Q$ bumps.

### Algorithm summary

> **Given:** $H(z)$, passband $[f_{p1},f_{p2}]$, expansion margin $\mu$,
> cluster count $M$, stages per cluster $c_i$, starting angles
> $\boldsymbol\theta^{(0)}$ and radius $r_0$, damping $\alpha_1,\alpha_2$,
> tolerance $\epsilon$, patience $P$.
>
> 1. Compute $\tau_H$ over the expanded band; set the anchor $D_0$ from
>    $\tau_H$'s own extrema (Eq. 4).
> 2. Initialize $\boldsymbol\theta \leftarrow \boldsymbol\theta^{(0)}$,
>    $\mathbf r \leftarrow r_0\mathbf 1$.
> 3. **Phase 1:** repeat the update of §C with radii fixed and damping
>    $\alpha_1$ until $|S^{(t)}-S^{(t-1)}| < \epsilon$.
> 4. **Phase 2:** repeat the update of §C with radii free and damping
>    $\alpha_2$; track the best $S$ seen; stop after $P$ non-improving
>    steps; keep the best $(\boldsymbol\theta,\mathbf r)$.
> 5. Return the equalizer $\big\{(r_i,\theta_i,c_i)\big\}_{i=1}^M$ and the
>    resulting $\tau(\omega) = \tau_H(\omega)+\tau_{eq}(\omega)$.

Implementation: Step C is `examples/eqlzrD_peakNewtonStep.m`; the
two-phase schedule of §D is driven by
`dsgnEqlzrD_peakNewton_manual.m`/`eqlz_csc_newton_1_8_0.m` (one per
reference filter). See "How to evaluate this, exactly, in MATLAB" below
to reproduce a result end to end.

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
frequency `theta_i` and radius `r_i`), track **every current local
extremum** (not just the original two edge peaks — see "Multi-extremum
tracking" below) and drive

```
w_k = |gd(f_peak_k) - anchor| * |H(f_peak_k)|      (k = 1..K)
```

toward equality via a damped Newton/least-squares iteration on the
cluster angles (and, now, optionally also the radii — see "Joint
angle+radius" below).

### One iteration (`examples/eqlzrD_peakNewtonStep.m`)

**Step A — refine peak locations.** For each detected extremum, search
*within its own detected bracket* (not a fixed-width window — see
"Multi-extremum tracking" below for why that distinction matters), call
`AnlzDH` on the *current* equalized system to get `dTdW`/`d2TdW`, bracket
where `dTdW` crosses (`+` to `-` for a max, `-` to `+` for a min), then
take one Newton step: `f_peak <- f_peak - dTdW(f_peak)/d2TdW(f_peak)`.

**Step B — update the cluster angles (and, if `freeR`, radii).** With the
refined peak frequencies/values, compute the *exact closed-form* Jacobian
(no numerical differentiation needed, since only cluster `i`'s own bump
depends on its own `theta_i`/`r_i`):

```
d(gd(w))/d(theta_i) = count_i * 2*r_i*(1-r_i^2)*sin(w-theta_i)
                        / (1 - 2*r_i*cos(w-theta_i) + r_i^2)^2
d(gd(w))/d(r_i)     = count_i * ( -2*r_i/D
                       - 2*(1-r_i^2)*(r_i-cos(w-theta_i))/D^2 ),
                       D = 1-2*r_i*cos(w-theta_i)+r_i^2
```

(the `r` derivative verified against a central finite difference,
relative error ~3e-11). Assemble the `K x nClusters` (or `K x
2*nClusters` with `freeR`) Jacobian of the weighted deviations `w_k` with
respect to each free parameter, and solve via pseudoinverse (`K` and
`nClusters` relate differently call to call as the extremum count
changes; `pinv` handles over- and under-determined alike) for the
parameter step that drives every `w_k` toward their mean. Apply a
**damped** fraction of this step (function default 0.5; see "Cluster
count and step-size stability" below for why the driver script now uses
smaller values) rather than a full Newton step. Updated radii are clamped
to `[0.3, 0.995]`.

### Multi-extremum tracking (replaces the original fixed-2-peak version)

The version above (`w_j`, `j=1,2`) hardcoded exactly two tracked peaks —
the filter's own original two edge peaks — refined iteration to
iteration but never rediscovered. This was wrong: once the free clusters
reshape the interior of the curve, new local extrema appear that the
2-peak version never saw. Confirmed empirically: 10 iterations from the
3-cluster start grew 5 maxima + 4 minima (values 208-240), while the
2-peak version's tracked pair sat at 118.5/118.5 and reported
`spread=0.003` — a false convergence.

Fixed by re-detecting the *entire* current extremum set every call
(the same way a Remez-exchange algorithm re-derives its extremal set
each pass): scan `d2TdW` (group delay's second derivative, median-
filtered — `medfilt1`, window 5, `'truncate'` padding) for zero
crossings on a uniform grid (`nGridPts`, default 2000, raised from an
original 500 after a shallow interior extremum was found to be missed
at that resolution) over `wp` expanded 10% each side. Between two
consecutive inflection points, `dTdW` is monotonic (since `d2TdW`
doesn't change sign there), so it crosses zero *at most once* — every
bracket (including the two boundary segments, which is what catches the
edge peaks) contains at most one genuine extremum. No tunable
prominence threshold. Re-detecting the set fresh each call is safe
against the *earlier*, different bug (unanchored, self-referential peak
matching, described above) because the anchor is fixed once, outside
this function, from the unequalized filter — growing the tracked set
only ever adds constraints against that fixed external target, never
something to game.

A **second, more serious bug** was found while re-confirming a
40-iteration run with the above changes: Step A's refinement used to
search a *fixed* +/-0.01 cycle window around each bracket's midpoint
guess rather than the bracket itself. Once real extrema sit closer
together than 0.01 apart (confirmed: adjacent brackets only ~0.003-0.007
apart after the equalizer reshaped the curve), that fixed window reached
past the intended bracket into a neighboring one and locked onto the
wrong crossing — silently "refining" to the wrong extremum's location,
which then collided with, and was discarded by, a de-duplication pass
(added to handle a separate, legitimate issue: very sharp near-singular
peaks making the coarse scan flag two adjacent brackets for what's
really one extremum) as an apparent duplicate. This — not scan
resolution — is what caused a 40-iteration run to report only 7 of 9
true extrema, missing the second edge peak entirely. Fixed by having
detection return each extremum's own bracket bounds and confining
refinement to those bounds, guaranteed (by the same inflection-point
argument) to contain at most one extremum regardless of how close
neighboring brackets are. Re-verified: finds all 9 true extrema exactly,
cross-checked against an 8000-point `findpeaks` scan with every value
matching.

### Joint angle+radius (`freeR` option)

With only cluster angles free, the least-squares step can only *best
fit* the tracked extrema to equal deviation, not force exact equality —
there are typically ~9-11 extrema against only 3-5 free angle
parameters, an overdetermined system. This shows up as visibly unequal
peaks even after full angle-only convergence.

The obvious fix — after angle convergence, shrink the tallest cluster's
radius to lower its peak — was tried standalone first and made things
**worse**, not better: nominal p2p went 22.9 -> 25.1 at r=0.90 (-> 40-42
at r=0.85/0.80) even with the angles **fully re-optimized** around the
new radius each time. Same lesson as the "leaky tails" problem
throughout this exploration: a cluster's bump doesn't just support its
own peak, it also props up its neighboring valleys, so changing one
cluster in isolation — even with re-optimization — doesn't correctly
explore the joint trade-off.

Solving jointly (both angle and radius Jacobian columns in the same
least-squares step, `freeR=true`) does help, substantially: from the
same angle-converged 3-cluster starting point, spread dropped from 23.11
to a low of 17.40 within 3 steps (nominal p2p 22.9 -> 16.7, ~27%
better). It does **not** converge cleanly to a fixed point the way
angle-only does: spread bottoms out early then *slowly drifts back up*
over further iterations, while p2p on the wider expanded band keeps
improving throughout — a real nominal-vs-expanded trade-off, not simple
convergence. `dsgnEqlzrD_peakNewton_manual.m` now tracks the best spread
seen so far and stops after 5 consecutive non-improving steps,
**reverting to that best configuration**, not whatever the last step
landed on.

### Cluster count and step-size stability

Increasing from 3 to 5 clusters (more angle DOF against the ~9-11
tracked extrema — the direct lever on the overdetermined-system problem
above) was tried next. At the function's default step size (0.5, tuned
for 3 clusters), **5 clusters is unstable**: angle-only phase 1 showed
the tracked extremum count itself oscillating wildly (3 to 11) and
spread swinging between 13 and 300 for ~35 of 50 steps before finally
settling; joint phase 2 was far worse, diverging outright by step 3 —
radii pinned to their `[0.3, 0.995]` clamp bounds, spread exploding past
1900 (p2p_nominal in the *thousands*). More free parameters against
roughly the same extremum count makes the pinv least-squares step more
aggressive per unit computed magnitude; smaller step sizes compensate.
At `STEP1_SIZE=0.2` / `STEP2_SIZE=0.1`, both phases are smooth and
well-behaved with no clamping.

### Result (current best)

Running the full pipeline — 5 clusters (evenly spaced 10-90% of the
passband), phase 1 angle-only to convergence, phase 2 joint angle+radius
with best-so-far tracking — via `dsgnEqlzrD_peakNewton_manual.m`:

- `p2p_nominal = 13.94` — the best result of the entire exploration
  (previous best, 3 clusters angle-only+joint-radius: 16.73; before that,
  the original fixed-2-peak 8-step hand run: 27.6).
- `p2p_expanded = 139.26` — the persistent expanded-band trade-off, now
  *more* pronounced than with 3 clusters (117.6) — more free parameters
  makes the nominal-vs-expanded trade-off worse, not just the nominal
  result better. See "Suggested next steps" #4.
- Visually, the equalized curve is now flat and genuinely equi-ripple
  across the entire nominal passband `[0.025, 0.075]` (screenshot
  reviewed directly during this session) — a clear qualitative jump from
  the visibly-humped 3-cluster result. The steep excursions are confined
  to the expanded-band margin outside the actual spec'd passband.

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

### 2. Run the current Newton procedure

```matlab
cd examples
dsgnEqlzrD_peakNewton_manual
```

This builds `H`, sets up the anchor and the starting 5-cluster
configuration, plots the initial state, then runs automatically:
**phase 1** (angle-only, `STEP1_SIZE=0.2`) to small-delta convergence
(up to `PHASE1_MAX_ITERS=100` steps, prints one line per step), then
**phase 2** (joint angle+radius, `STEP2_SIZE=0.1`, `freeR=true`)
tracking the best weighted-deviation spread seen and stopping after 5
consecutive non-improving steps, reverting to that best configuration.
Plots the final result, prints `info` for that best state, then drops
into a `keyboard` breakpoint. From there, take additional steps by hand
(shown at the breakpoint):

```matlab
[clusterTheta, clusterR, info] = eqlzrD_peakNewtonStep(H, clusterTheta, clusterR, clusterCount, anchor, wp_, [], [], true);
plotCurrent(H, clusterTheta, clusterR, clusterCount, wp_, anchor);
```

(drop the trailing `true` for an angle-only step). Repeat as many times
as desired, inspecting `info.weightedDev` and the plot after each call.
`dbcont` to finish, `dbquit` to abandon. `eqlzrD_peakNewtonStep` re-
detects the full extremum set from scratch every call from `wp_` alone
— it takes no peak-location guess to thread between calls (see
"Multi-extremum tracking" above for why) — and always returns
`clusterR` as a second output now, unchanged when `freeR` is omitted or
false, so old 2-output call sites need updating to the 3-output form
above.

### 3. Compute the figures of merit directly

```matlab
bw = wp_(2) - wp_(1);
f = linspace(wp_(1)-0.10*bw, wp_(2)+0.10*bw, 2000);
w = 2*pi*f;
idx_nom = f >= wp_(1) & f <= wp_(2);

wiVec = repelem(clusterR, clusterCount) .* exp(1j*repelem(clusterTheta, clusterCount));
eq = eqlzrDClass(wiVec(:), 1);
Heq = eq.applyTo(H);

[~,~,gdH0] = AnlzDH(H, w(:));
[~,~,gdH1] = AnlzDH(Heq, w(:));

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

1. **Robustness to starting point.** *Partially answered.* Tested one
   dimension of this directly: cluster *count* (3 -> 5) is NOT robust to
   reusing the same step size — see "Cluster count and step-size
   stability" above, where the 3-cluster-tuned default (0.5) diverges
   outright at 5 clusters and needed hand-tuned smaller values
   (0.2/0.1). Still untested: different starting *angles* or *radii* at a
   fixed cluster count, and whether an even higher cluster count (7? 10?)
   continues the same nominal-improves/expanded-worsens trend or breaks
   down differently.
2. **Sensitivity to step size.** *Partially answered, and reframed.* Not
   just a speed question — step size is now known to be a *stability*
   question that changes with cluster count (see above). The current
   fix is hand-tuned constants (`STEP1_SIZE`/`STEP2_SIZE` in
   `dsgnEqlzrD_peakNewton_manual.m`) chosen per configuration by trial.
   A more principled fix (adaptive step size / backtracking line search:
   halve the step and retry if a step increases spread, rather than a
   fixed constant chosen up front) would remove the need to re-tune by
   hand every time cluster count or the reference filter changes.
3. **Generalization to a different filter.** *Partially answered.* The
   procedure was applied to a second reference filter,
   `examples/csc_fltr_1_8_0.m` — passband `[0.025, 0.475]`, ~9x wider
   than the original `[0.025, 0.075]` case and spanning almost all
   positive frequencies (`examples/eqlz_csc_1_8_0.m`,
   `examples/eqlz_csc_newton_1_8_0.m`). The same anchor definition and
   Newton update carried over unchanged; the only refit needed was the
   starting radius (a much lower $r_0 \approx 0.82$, vs. $0.925$ for the
   narrow-band filter — consistent with §E's rule that wider passbands
   need broader starting bumps) and correspondingly smaller step sizes
   ($\alpha_1=0.1$, $\alpha_2=0.05$). With that adjustment, 5 clusters
   took nominal p2p from 35.90 (unequalized) to 23.80, and 7 clusters
   (r=0.78) reached 12.54 — both phases converged cleanly with no
   clamping or oscillation, at the cost of a larger expanded-band
   penalty (66.34 at 7 clusters) than the narrow-band case ever showed.
   So the procedure itself generalizes without modification; only the
   starting-point hyperparameters ($r_0$, $\alpha_1$, $\alpha_2$) need
   re-tuning per filter. Still open: whether that re-tuning can be made
   automatic (e.g. $r_0$ set from passband width directly), and whether
   a filter with a different *shape* of asymmetry (not just a wider
   version of the same bathtub) behaves the same way.
4. **The expanded-band trade-off.** Still open, and now has a sharper
   data point: going from 3 to 5 clusters made the *nominal* result
   better (16.73 -> 13.94) but the *expanded*-band result worse (117.6
   -> 139.26) — more free parameters doesn't just improve the nominal
   fit, it actively trades away expanded-band flatness for it. Is this
   an acceptable, inherent cost of equalizing strictly within the
   specified passband (in which case the expanded-band metric may simply
   be the wrong thing to optimize), or is there a real fix — e.g.
   including a few expanded-band points in the tracked extremum set, or
   a weighted objective that penalizes expanded-band excursions too?
5. ~~**Beyond two tracked peaks.**~~ **Done** — see "Multi-extremum
   tracking" above (includes two real bugs found and fixed along the
   way: a false-convergence bug from only ever tracking 2 of 9 extrema,
   and a fixed-width refinement window locking onto the wrong nearby
   extremum once real extrema sat closer together than that window).
6. **Stopping criterion.** *Done, in two different forms because
   angle-only and joint angle+radius behave differently.* Phase 1
   (angle-only) converges monotonically, so a small-delta check
   (`SPREAD_TOL=1e-4`) is correct and sufficient. Phase 2 (joint) does
   NOT converge monotonically (see "Joint angle+radius" above — spread
   bottoms out early then drifts back up), so a small-delta check would
   silently run past the best point; phase 2 instead tracks the best
   spread seen and stops after a patience window (5 non-improving
   steps), reverting to that best configuration. Both are implemented in
   `dsgnEqlzrD_peakNewton_manual.m` and run automatically now (no manual
   single-stepping needed to reach a good result) with a `keyboard`
   breakpoint only at the very end for further manual exploration.
7. **Joint angle+radius (`freeR`).** **Done** — see "Joint angle+radius"
   above. Kept after confirming it clears the "improve or revert" bar
   (27% better nominal p2p on the 3-cluster case). Not yet explored:
   whether letting `clusterCount` itself vary (currently fixed integers,
   chosen by hand) as a further free "parameter" — e.g. via a relaxed
   continuous formulation, or a discrete search — could help further,
   and whether a bigger patience window or different `STEP2_SIZE` finds
   an even better point than the current best (~13.94).
8. **More clusters.** **Done for 5** — see "Cluster count and step-size
   stability" and "Result (current best)" above (13.94 nominal, up from
   16.73 at 3 clusters, at the cost of a worse 139.26 expanded metric).
   Not yet tried: 7 or more clusters, or a principled way to choose
   cluster count (e.g. tied to `estAllPassOrder`'s own order estimate,
   or increased adaptively until nominal p2p stops improving).
