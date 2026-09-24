# Fixing adaptP3 / fndZeroCrs3 for EqualFltr_1_6_0.m

## Problem

`EqualFltr_1_6_0.m` failed with `adaptP3: only found 1 group-delay
extrema for 7 free pole(s)`. Call chain: `EqualFltr_1_6_0.m` ->
`dsgnCscdFltr(..., 'equiGDLsPls')` -> `dsgnDigitalFltr` ->
`dsgnEquiRplGD` -> `adaptP3`.

Note: this is a *different* thread from the `dig_linPh_1_6_0.m`/`_1_8_0.m`
fix already documented in `TestFilters.md` (dual starting heuristics,
proactive collision/proximity checks, damped steps, non-finite guards -
that work is done, `1_6_0` fully fixed, `1_8_0` improved but short by 1
stop-band minimum, left as-is). This file covers the separate
`EqualFltr_1_6_0.m` investigation, which turned up a real, independent
bug along the way.

## What's been tried, in order

### 1. `fndZeroCrs3.m`'s search window - first attempt (wrong)

`fndZeroCrs3.m` (used by both `adaptP2`/`adaptP3` to find group-delay
extrema) originally used a hardcoded search range,
`wrng = 2*pi*[-0.45 0.45]`, spanning nearly the whole spectrum regardless
of the actual passband. For `EqualFltr_1_6_0.m`'s extremely narrow,
near-DC passband (`wp = [-1/2048, 1/2048]`), this swamped the real
passband extrema with irrelevant stop-band structure.

First fix: search `wp` extended by a margin = 0.1x the passband width by
default, auto-shrinking (floor 0.02x) if the group delay at the
candidate edge looked anomalously large (a check for the window being
*too wide*, picking up unrelated stop-band resonance).

This let `EqualFltr_1_6_0.m` run, but `adaptP3` still couldn't find
enough starting extrema (5 of 13 needed) and had to revert. Investigating
why led to the real problem:

### 2. The real bug: the margin was far too *narrow*, not too wide

Traced precisely (see conversation, not reproduced here in full): a tiny
perturbation to the pole angles (`adaptP3`'s own `tan(1.05*angle(p))`
starting-heuristic, a ~5% angle stretch) appeared to make 2 of 5 extrema
"disappear." They hadn't - searching a much wider window found the exact
same 13 extrema for both the original and the tan-warped pole
configuration; the perturbation only nudged their positions slightly,
enough to cross the (too-narrow) window boundary. This filter's genuine
equiripple group-delay structure extends to ~3.5x the passband width
past each edge - `0.1x` was nowhere close.

This should have been caught immediately: the 5 extrema originally found
sat almost exactly at the search window's own edge (±0.000564 cycles vs
a window edge at ±0.000586) - a textbook truncation signature. The
`edgeTooLarge` check that was built only tests for the window being too
*wide* (picking up stop-band resonance); nothing checked whether found
extrema cluster near the boundary, which is the signature of the window
being too *narrow*. That gap should have been caught during
implementation, not several turns later.

### 3. Fixed: locate-then-size the margin from actual data

Rewrote `fndZeroCrs3.m` to determine the margin empirically instead of
guessing a fraction:
- Scan progressively wider windows (starting at 1x the passband width,
  doubling, capped at 64x) at a coarser grid resolution, until no
  extremum sits near the current window's edge.
- Set the real, fine-resolution search margin to the outermost extremum
  actually found, plus a 20% buffer.

Verified directly against the probed `H3` (the pre-`adaptP3` filter):
both the original and tan-warped pole configurations now correctly find
all 13 extrema. Confirmed via `EqualFltr_1_6_0.m`: `adaptP3`'s starting
heuristics now reach 13/13 (previously 5/5 at best), for both `tan-warp`
and `even-spacing`.

### 4. `dsgnEquiRplGD.m`: don't call `adaptP3` blindly

Separately (raised directly, not something I'd caught myself): nothing
ever checked whether the pre-`adaptP3` filter actually needed correction,
or whether `adaptP3` made things better or worse. Added, in both
`lib/dsgnEquiRplGD.m` and `examples/dsgnEquiRplGD.m` (two independently-
maintained copies - see "Open items" below):

1. **Before calling `adaptP3`**: find the real group-delay extrema in the
   passband (`fndZeroCrs3(H3, wp3)`), and compute the ripple
   `(max-min)/mean` across them.
   - If fewer than 2 extrema are found (can't even assess ripple), raise
     a clear error rather than proceed blind.
   - If ripple is already under 10% (user-specified threshold), skip
     `adaptP3` entirely - it's already close enough to equiripple.
2. **After calling `adaptP3`** (wrapped in try/catch, since `adaptP3` can
   itself fail): if it failed, or its output has too few extrema to
   assess, or its ripple is *worse* than before, revert to the
   pre-`adaptP3` poles.

Also fixed a related crash inside `adaptP3.m` itself: when it couldn't
reach its target starting extrema count, it used to print a warning and
"proceed anyway," which then crashed a few lines later (`gd1 = Tz(Np)`
indexing past the end of a too-short array) with an opaque "Array
indices must be positive integers" instead of a clear diagnostic. Now
raises a real error there instead, matching this file's own existing
collision-halt convention - and letting `dsgnEquiRplGD.m`'s new
try/catch actually work.

## Where we are now

`EqualFltr_1_6_0.m` passes the test harness. Specifically:

- `adaptP3` now starts with the *correct* 13/13 extrema (both starting
  heuristics) - the search-window bug is genuinely fixed.
- It then proceeds into its main Newton refinement loop, but **loses
  extrema during iteration** (down to 1, after exhausting the existing
  5-attempt collision-freeze allowance) and raises a clean error.
- `dsgnEquiRplGD.m`'s new revert logic catches this and falls back to
  the pre-`adaptP3` poles, which are already close to equiripple
  (p2p/mean ≈ 10.3-10.4%).
- Final result: stable (`max|pole| = 0.998`), passband group delay
  reasonable, **but stop-band attenuation badly misses spec: 11.76 dB
  achieved vs 50 dB target**, right at the inner stop-band edge.

Regression check in progress when this session ended: `dig_linPh_1_*.m`
(all 5) ran OK. `dig_equiGd_*.m` was still running - `dig_equiGd_1_15_0.m`
hit a 120s TIMEOUT, which is new and not yet explained (could be the new
locate-pass's iterative doubling being slow for some pole configuration,
or could be unrelated). Check `tools/reports/20260924_085821/summary.txt`
for the full results once available.

## Open items for next session

1. **ROOT-CAUSED (g22 session, 2026-09-24), fix prototyped but not yet
   integrated**: `adaptP3`'s 14x14 Newton system (13 group-delay-extrema
   rows via `plSens`/`setY2`, `EqualFltr_1_6_0.m`'s 13/13 case) is
   structurally near-singular (`rcond ~ 3.7e-15`) - the 13 rows alone are
   mathematically guaranteed rank-deficient by 1 (13 rows < 14 unknowns),
   and `plSens`'s single ad hoc mirror-constraint row only weakly
   resolves that null direction. A tiny (~0.001) step along the
   resulting near-null "rotate all poles' angles together" direction
   collapsed the extrema count 13->1.
   - A SEPARATE, independent bug compounded this: the starting poles'
     radius (`|p|~0.9998`) already exceeded `adaptP3`'s hardcoded
     `R_MAX=0.995` safety clamp *before any Newton step*, so the clamp
     fired unconditionally on iteration 1, forcibly shrinking every
     pole's radius by ~0.005 - 5x larger than the actual Newton
     correction. Fixing `R_MAX` alone stops the crash but the original
     14x14 system still fails to converge (ripple grows instead of
     shrinking) due to the conditioning issue above - both bugs are real
     and independent.
   - Prototyped and empirically validated (scratch scripts, not yet in
     `lib/`) a reformulation: reduce to the poles' true independent real
     parameters (conjugate-pair symmetry, guaranteed by construction for
     every current `adaptP3` caller via `dsgnEquiRplGD`'s re-centering -
     7 real unknowns for `EqualFltr_1_6_0.m`'s 7 poles), and instead of
     `plSens`/`setY2`'s alternating-target system, solve for each local
     MAXIMUM to move toward `mean(minima) + deltaT` (deltaT = the
     caller-supplied target ripple width, `adaptP3`'s own `deltT` arg),
     explicitly accounting for the sensitivity of `mean(minima)` to the
     same pole changes (not a stale/fixed reference). An earlier,
     simpler "maxima-only equalized to a fixed anchor" variant only
     closed the true overall peak-to-peak group delay by ~13%; this
     coupled max/min-sensitivity version closed it by >99.99% over 600
     iterations (`EqualFltr_1_6_0.m`: overall p2p `5745 -> 0.35`,
     `meanMax-meanMin` gap `4981 -> 0.16` vs `deltT=0.1` target), with
     zero extrema-count collapse throughout.
   - **DONE (g22 session, 2026-09-24), Phase 3 integrated**: wired into
     `lib/adaptP3.m` as `adaptP3Reduced`, used automatically whenever
     poles are conjugate-paired (`checkConjugatePairing`) and the found
     extrema split into exactly `Np` maxima (`classifyExtrema`), with a
     runtime fallback to the original system (renamed `adaptP3Standard`)
     otherwise - both at the top level and mid-run if the maxima/minima
     structure changes and doesn't recover (commit `b4b2393`).
   - Along the way, found and fixed two more issues surfaced by getting
     this working end-to-end: (a) the reduced system's `A` matrix is
     EXACTLY (not just numerically) rank-deficient whenever two maxima
     land at bit-identical mirror frequencies +w/-w - true for any
     conjugate-paired filter, since `T(w)=T(-w)` identically, so their
     reduced sensitivity rows are mathematically guaranteed equal, not
     just numerically close (confirmed on `dig_linPh_1_6_0.m`'s
     even-spacing candidate: `rcond(A)=4e-18`). Fixed by solving via
     `pinv` instead of a strict backslash, matching
     `examples/eqlzrD_peakNewtonStep.m`'s own established pattern for
     rank-deficient systems. (b) The starting-candidate selection (now 3
     candidates: original/tan-warp/even-spacing, picked by lowest ripple
     among those meeting the extrema-count threshold, not highest raw
     count) had a bug where the shared magnitude boost `m=abs(p).^0.1`
     was silently applied to the new "original" candidate too, inflating
     its group delay ~6-7x before it was ever compared - fixed by giving
     the "original" candidate the true, unmodified magnitude.
   - **Result** (16-example regression sweep): 2 genuine new successes -
     `EqualFltr_1_6_0.m` (true overall p2p ripple `10.31%` -> well under
     `1%`) and `dig_linPh_1_2_0b.m` (previously silently-degenerate
     5-pole cluster now resolves cleanly) - and zero new regressions.
     The 6 examples still reverted by `dsgnEquiRplGD.m`'s existing safety
     net (`dig_linPh_0_2_0/1_2_0/1_4_0/1_6_0/1_8_0`) were confirmed, by
     temporarily swapping in the pre-Phase-3 `adaptP3.m` against the
     current (already-fixed) `fndZeroCrs3.m`, to already exhibit the
     identical revert behavior before any of this integration's changes
     - a pre-existing consequence of item 3's `+-pi` fix revealing a
     harder true extrema landscape for those filters, not something
     Phase 3 introduced. `dig_linPh_1_8_0.m`'s heterogeneous two-cluster
     pole structure (5-pole near-DC + 4-pole near-Nyquist, set aside
     earlier this session) remains a separate open item - see new item 6.
2. **Stop-band attenuation shortfall** (11.76dB vs 50dB target,
   `EqualFltr_1_6_0.m`) - likely pre-existing (the script never completed
   before, so there's no earlier baseline to compare against) and
   probably unrelated to anything in this file - lives in
   `place_polesdLP3`'s territory, not `adaptP3`'s. Not investigated.
3. **DONE (g22 session, 2026-09-24)**: root-caused and fixed the
   `dig_equiGd_1_15_0.m` timeout. `fndZeroCrs3.m`'s margin-locate loop
   could overshoot the +-pi periodic boundary of `z=e^{jw}` once a
   filter's genuine equiripple extent needed close to the full 64x
   margin cap - confirmed directly on `dig_linPh_1_8_0.m`
   (`Np=9`, `wp=[-0.005 0.005]`), whose unclamped window reached
   `[-4.05,4.05]` rad, well past +-pi, producing aliased/spurious
   "extrema" (`wz` as far out as `-3.516`/`2.767` with no mirrored
   counterpart). Fixed by clamping both the coarse locate-pass window
   and the final fine-search window to `[-pi,pi]` (commit `70746d2`).
   `dig_equiGd_1_15_0.m` now completes in ~33s (was a 120s timeout).
   Verified via a 13-example regression sweep (all `dig_linPh_*.m`,
   `dig_equiGd_*.m`, `EqualFltr_1_6_0.m`) - no regressions.
4. **DONE (g22 session, 2026-09-24)**: `lib/dsgnEquiRplGD.m` vs
   `examples/dsgnEquiRplGD.m` duplicate-file fragility. Confirmed the two
   copies were byte-identical, then removed `examples/dsgnEquiRplGD.m`
   outright (commit `ae9f966`) - `lib/dsgnEquiRplGD.m` is now the only
   copy. All callers (`dsgnDigitalFltr`/`1`/`2.m`) resolve it by name via
   the path, so this was a no-op for behavior; verified by re-running
   `EqualFltr_1_6_0.m` and `dig_equiGd_1_6_0.m` with only the `lib/` copy
   present.
5. Once (1)-(3) are settled, re-run the full suite
   (`tools/run_all_examples.sh &`) for a clean end-to-end picture, per
   `Progress.md`'s standing suggestion.
6. **NEW (g22 session, 2026-09-24)**: `dig_linPh_0_2_0.m`, `1_2_0.m`,
   `1_4_0.m`, `1_6_0.m` all get their group-delay stage silently reverted
   by `dsgnEquiRplGD.m`'s safety net (adaptP3 - either system - makes
   ripple worse, not better). Not a regression from anything this session
   changed (see item 1's last bullet) - it's the true extrema landscape
   `fndZeroCrs3.m`'s `+-pi` fix (item 3) revealed for these filters,
   previously masked by the aliasing bug. `dig_linPh_1_6_0.m` specifically
   was a celebrated earlier-session success (dual-heuristic/proactive-
   collision fixes, all 6 poles stable) that no longer holds post-fix -
   worth understanding whether these filters are genuinely infeasible at
   their current `wp`/`deltT`/pole-count, or whether the same kind of
   reformulation that fixed `EqualFltr_1_6_0.m` (or something else) could
   help once their now-more-complex extrema structure is understood, the
   way `dig_linPh_1_8_0.m`'s two-cluster structure was diagnosed. Not
   investigated - functionally safe for now (clean revert, no crash or
   corrupted output), just missing group-delay correction these filters
   used to get.
