# Progress — session handoff (pick up here)

**`TestFilters.md`'s "Known issues" section is the source of truth for
current pass/fail status** — always check it first. `FixadaptP3.md` is
the detailed technical record for the `adaptP3`/group-delay-equalization
work specifically. This file is just a summary of how we got here and
what's left, refreshed at the end of each session.

This session (g22, 2026-09-24) picked up from an earlier home-machine
session (see git log before `e1e614b` for that history) and did four
mostly-independent things, in order:

## 1. Fixed a copy-paste bug: `csc_fltr_1_*.m` examples all saved to the same file

Six examples (`csc_fltr_1_6_0`, `1_6_1`, `1_8_0b`, `1_8_0c`, `1_10_0`,
`1_12_0`) all hardcoded their `print()` call to `csc_fltr_1_8_0` — none
of them ever produced their own output file. Fixed all six, verified
each now runs cleanly and writes its own correctly-named PNG. Commit
`e1e614b`.

## 2. Removed a duplicate file: `examples/dsgnEquiRplGD.m`

`lib/dsgnEquiRplGD.m` and `examples/dsgnEquiRplGD.m` were byte-identical
duplicates; `examples/` is added to the MATLAB path after `lib/`, so it
silently shadowed the `lib/` copy for every call (a debug probe added
only to `lib/` never ran — how this was noticed). Removed the
`examples/` copy; `lib/` is now the only one. No behavior change
(verified). Commits `ae9f966`, `da0a81a`.

## 3. Root-caused and fixed `adaptP3`'s core instability (`FixadaptP3.md` Open Item 1)

The big one this session. `EqualFltr_1_6_0.m` (and others) failed inside
`adaptP3`'s group-delay-equalization Newton loop with "only found 1
group-delay extrema for 7 free pole(s)" — previously misdiagnosed (an
earlier session) as genuine pole-count infeasibility.

**Root cause, precisely traced**: `adaptP3`'s Newton system (`plSens` +
`setY2`) is *structurally* near-singular whenever it's exactly at the
minimum-required extrema count (confirmed `rcond ~ 3.7e-15` on
`EqualFltr_1_6_0.m`'s 13-extrema/7-pole case) — the group-delay rows
alone are mathematically guaranteed rank-deficient by 1, and `plSens`'s
single ad hoc "make it square" constraint row only weakly resolves that.
A tiny (~0.001) Newton step along the resulting near-null "rotate all
poles together" direction collapsed the extrema count from 13 to 1 in a
single iteration.

**Fix, developed and validated interactively with the user** (their
proposed reformulation, not something I designed alone): reduce to the
poles' true independent real parameters (conjugate-pair symmetry —
always holds for `adaptP3`'s actual callers), and instead of the
original alternating-target system, drive each local group-delay MAXIMUM
toward `mean(minima) + deltaT`, explicitly accounting for the
sensitivity of `mean(minima)` to the same pole changes (not a stale
reference — an unanchored "maxima toward their own floating mean"
version was tried first and is *exactly* singular, matching a documented
precedent in `examples/eqlzrD_peakNewtonStep.m`).

**Integrated into production** (`lib/adaptP3.m`, new `adaptP3Reduced`,
used automatically when preconditions hold — conjugate-paired poles,
extrema splitting into exactly `Np` maxima — falling back to the
original system, renamed `adaptP3Standard`, otherwise). Two more real
bugs found and fixed while getting this to actually work end-to-end:
- The reduced system's matrix is *exactly* rank-deficient whenever two
  maxima land at bit-identical mirror frequencies (mathematically
  guaranteed for any conjugate-paired filter) — fixed via `pinv` instead
  of a strict solve, matching `eqlzrD_peakNewtonStep.m`'s own existing
  pattern.
- `R_MAX=0.995` (a pole-magnitude safety clamp) was too tight for
  legitimate high-Q narrow-passband designs — `EqualFltr_1_6_0.m`'s
  starting poles already exceeded it before any Newton step ran. Raised
  to `0.99999`.
- The starting-candidate selection (which of several initial pole
  configurations to refine) picked by raw extrema *count*, which
  couldn't distinguish a clean, already-good configuration from a
  badly-warped one that happened to hit the same count. Added the
  *unwarped original* poles as a third candidate and switched to
  picking by ripple quality among candidates meeting the threshold.

**A separate, independent bug found along the way**: `fndZeroCrs3.m`'s
search-window could overshoot the `+-pi` periodic boundary of
`z=e^{jw}` and alias, producing spurious "extrema." Fixed by clamping to
`[-pi,pi]`; this also explained and fixed a previously-unexplained
120s timeout on `dig_equiGd_1_15_0.m` (now ~33s). Commit `70746d2`.

**Net result** (16-example regression sweep): 2 genuine new successes —
`EqualFltr_1_6_0.m` (true group-delay ripple `10.31% -> <1%`) and
`dig_linPh_1_2_0b.m` (a previously silently-degenerate 5-pole cluster
now resolves cleanly) — and confirmed zero new regressions. Commits
`b4b2393`, `9d2997e`. Full technical detail, including the numerical
traces behind each finding, is in `FixadaptP3.md`.

**Important side effect discovered while regression-testing**: the
`+-pi` fix (independently correct and verified) revealed a genuinely
harder true extrema landscape for `dig_linPh_0_2_0.m`/`1_2_0.m`/
`1_4_0.m`/`1_6_0.m` than the old, partially-aliased search saw —
including `dig_linPh_1_6_0.m`, a celebrated fix from an earlier session
that no longer holds. All four now get safely reverted to their
pre-`adaptP3` poles by `dsgnEquiRplGD.m`'s existing safety net (no
crash, no corrupted output — just no group-delay correction applied).
Confirmed via a controlled test (swapping in the pre-integration
`adaptP3.m` against the current `fndZeroCrs3.m`) that this is *not*
caused by this session's Phase 3 integration. See `FixadaptP3.md` Open
Item 6.

## 4. `TestFilters.md` corrections

Several claims there (`dig_linPh_1_6_0.m` "now passes reliably",
`dig_linPh_1_8_0.m`'s "group-delay stage now passes cleanly") were
stale/now-wrong per items 3 above; corrected with dated notes rather
than rewritten, matching this file's own established convention.

## Open items (see `FixadaptP3.md` for full detail on 1-2 and 6)

1. **`dig_linPh_1_8_0.m`** — heterogeneous two-cluster pole structure
   (5-pole near-DC group + 4-pole near-Nyquist group with much lower Q)
   means the reduced system's "maxima count == Np" precondition never
   holds; falls back to the standard system, which also can't resolve
   it (169.52% -> 313.31% ripple, reverted safely). Set aside per
   direct instruction this session — not investigated further.
2. **`dig_linPh_0_2_0.m`/`1_2_0.m`/`1_4_0.m`/`1_6_0.m`** — new item this
   session (`FixadaptP3.md` Open Item 6). All four now silently reverted
   post-`+-pi`-fix; not yet understood whether genuinely infeasible at
   current specs or fixable with more work (possibly the same kind of
   reformulation that fixed `EqualFltr_1_6_0.m`, once their now-more-
   complex extrema structure — similar to `dig_linPh_1_8_0.m`'s — is
   diagnosed).
3. **Stop-band attenuation shortfall** on `EqualFltr_1_6_0.m` (11.76dB
   vs 50dB target) — lives in `place_polesdLP3`'s territory, not
   `adaptP3`'s. Not investigated.
4. **`exmpl_r1b.m`** — `Pole Removals Failed`. Not traced this session;
   `tstTFops.m` (same error message) was traced to `rmvCmplx`→
   `rmv_pole2` in an earlier session, but `exmpl_r1b.m`'s own failure
   point hasn't been individually confirmed to be the same call chain.
5. **`tstTFops.m`** — `Pole Removals Failed`, confirmed at
   `rmvCmplx`→`rmv_pole2` (earlier session), not yet root-caused further.
6. Once the above are settled, run the full suite fresh
   (`tools/run_all_examples.sh &`) for a clean end-to-end picture —
   this session's fixes were verified via targeted globs/individual
   `matlab -batch` runs, not a full sweep.
7. **Passband loss drifts from Ap whenever `adaptP3` succeeds** (found
   2026-09-24). This is already the case in the original code:
   `dig_linPh_1_2_0b.m` (reduced system succeeds) ends at 3.31dB
   passband-edge loss against Ap = 3.0103dB. The other `dig_linPh`
   originals only hit Ap because `adaptP3` is reverted for them. Likely
   cause: the Ap edge is set only on the continuous prototype
   (`fndApFrq`/`scaleFltr` in `LinPh_LssPls`), and after `adaptP3`,
   `dsgnEquiRplGD` only renormalizes DC gain. Not yet traced or fixed.
   See `ScldGD.md` open item 1; the `_scld` examples show it too
   (1.55-1.62dB against 2.0dB, and 3.31dB against 3.01dB).

## Tools / workflow reminders

- `tools/run_all_examples.sh [timeout_seconds] [glob]` — the test
  harness. Runs each `examples/*.m` in a fresh MATLAB `-batch` process;
  results to `tools/reports/<timestamp>/summary.txt` (gitignored).
- `tools/monitor_progress.sh` — polls a report dir once a minute if
  watching a long run.
- For a single-file stack trace (the harness only captures
  `ME.message`, not the stack), use a small wrapper: `run('examples/foo.m')`
  inside a `try`/`catch`, print `ME.stack(k).name`/`.line` in a loop.
- This session ran directly on g22 (no home-machine rsync/sync step
  needed) — commits here are pushed straight to `origin master`.
