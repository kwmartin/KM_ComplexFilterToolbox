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

1. **Not actually root-caused**: why does `adaptP3`'s main Newton loop
   drive an already-fully-resolved (13/13) pole configuration back into
   collision during iteration? Currently caught-and-reverted via the new
   safety net, not fixed. The revert gives a safe, reasonable result for
   this specific case, but the underlying algorithmic issue is
   unaddressed.
2. **Stop-band attenuation shortfall** (11.76dB vs 50dB target,
   `EqualFltr_1_6_0.m`) - likely pre-existing (the script never completed
   before, so there's no earlier baseline to compare against) and
   probably unrelated to anything in this file - lives in
   `place_polesdLP3`'s territory, not `adaptP3`'s. Not investigated.
3. **Confirm the `dig_equiGd_1_15_0.m` timeout** - new margin-locate
   logic in `fndZeroCrs3.m` runs an iterative widening scan; check whether
   it's the cause of the new timeout (e.g. an unusually slow-to-converge
   widening loop for that specific case) before assuming it's unrelated.
4. **`lib/dsgnEquiRplGD.m` vs `examples/dsgnEquiRplGD.m`** are two
   independently-maintained duplicate files - confirmed this session when
   a temporary debug probe added only to the `lib/` copy silently never
   ran, because `examples/` is added to the MATLAB path after `lib/` and
   shadows it for any duplicate name. Both copies were kept in sync by
   hand for every change in this file; worth considering whether the
   `examples/` copy should just be removed (or replaced with something
   that calls into `lib/`) to remove this fragility permanently.
5. Once (1)-(3) are settled, re-run the full suite
   (`tools/run_all_examples.sh &`) for a clean end-to-end picture, per
   `Progress.md`'s standing suggestion.
