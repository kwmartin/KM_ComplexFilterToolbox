# Progress — test-suite triage (pick up here at work)

This picks up the ongoing effort to run every script in `examples/` via
`tools/run_all_examples.sh` and fix (or correctly document) every failure.
**`TestFilters.md`'s "Known issues" section is the source of truth for
current status** — always check it first, not this file's snapshot below.
This file exists only to summarize how we got here and what's left.

**Correction, same day (g22 session):** this file's diagnosis below for
`dig_linPh_1_6_0.m`/`_1_8_0.m` (genuine pole-count/passband-width
infeasibility, item 2 under "Known issues still open") was wrong - see
`TestFilters.md`'s current "Known issues" section for the actual root
cause (an `nrmlzSpecsD.m` range bug plus missing collision/drift
monitoring in `adaptP3.m`/`place_polesdLP3.m`) and current status
(`1_6_0` fixed, 6 poles unchanged; `1_8_0` improved but not fully
resolved). Don't re-trust the "too many poles for too narrow a band"
framing below without re-reading `TestFilters.md` first.

## What's been fixed this session

1. **`lib/place_polesdLP5.m`** — the Newton step that adapts pole
   positions could go finite-but-enormous (not `Inf`/`NaN`, so it slipped
   past the existing safety check) when a pole landed very close to a
   stop-band probe frequency. RCOND for the underlying solve was within an
   order of magnitude of machine epsilon, so the exact result was
   sensitive to floating-point round-off order — meaning *identical
   inputs could converge to different final designs* across separate
   calls. Fixed by rejecting any step where `max(abs(X)) > 50` (same
   treatment as the existing non-finite check). Fixed `dig_equiGd_1_15_0.m`
   and `dig_equiGd_5_10_0.m`; verified reproducible across repeated calls
   and no regressions across the full `dig_equiGd_*` family.

2. **`lib/simLddrMC.m`** — used `normrnd(0, std, 1)`, which needs the
   Statistics and Machine Learning Toolbox (not installed here). Replaced
   with `std*randn(1)`, matching `lib/rndmMtrx.m`'s own convention. Fixed
   all 4 `DLddrFltr_*.m` examples.

3. **`examples/exmpl_1_5_1.m` / `exmpl_5_1_1.m`** — referenced an
   undefined `X2o` (copy-paste from an unrelated sibling script family).
   Removed the whole dead block (the real ladder was already complete one
   line earlier); confirmed `lddr2`/`X5`/`elem14`/`elem15` were never used
   again in either script.

4. **`examples/shortDat.m`** — removed outright. Orphaned script from a
   different project; nothing referenced it and its free variables
   (`win`/`k`/`G`) were never defined anywhere in this repo.

5. **`examples/mkFltr_exmpl.m`** + **`lib/rmvl4.m`** — three layered bugs,
   found by fixing each and re-running until it actually passed:
   - Stale `rmv2PolesS`/`rmvSCmplx` calling convention (pre-dates a
     refactor that added a required `lddr` argument and made those
     functions add elements to it internally).
   - `w_shift` referenced but never defined (only ever set in a
     commented-out line in `exmpl.m`, which no longer uses it itself).
     Defined `w_shift = 0.0j` locally, matching the majority convention.
   - A genuine sign bug in `lib/rmvl4.m`: it filtered poles by comparing
     `abs(p2)` (always >= 0) against a raw `wp` that can be negative,
     so a negative `wp` never matched its intended resonance pole pair.
     Fixed by normalizing `wp = abs(wp)` at the top of the function
     (proven sign-invariant everywhere else `wp` is used there). Checked
     the only other 2 callers of this chain for regressions — none.

6. **Corrected a miscount**: `dig_linPh_1_6_0.m` had been counted among
   the examples fixed by item 1 above, based only on it no longer
   throwing an error. It actually produces a degenerate result (a 6-fold
   repeated pole, `max|pole|=0.995`, and -66 dB "attenuation" — i.e.
   massive gain, not suppression). Moved back into known issues.

## Known issues still open (see `TestFilters.md` for full detail)

- **`dig_linPh_1_6_0.m` / `dig_linPh_1_8_0.m`** — too many finite-loss
  poles (6 / 8) for a passband that's both very narrow (0.01) and sitting
  entirely off to one side (not centered near DC), which overconstrains
  `place_polesdLP3`'s pole placement. Confirmed this is a spec problem,
  not a code bug: tried `dsgnDigitalFltr2` (produces the *identical*
  degenerate result/error — shares the same `equiGDLsPls` code path) and
  `equiGdDigital` (fails differently, its own zero-count assumption
  doesn't hold for this `p`/`ni`) as drop-in replacements for the exact
  same specs. Neither helps. A real fix would mean reducing the pole
  count or widening/recentering the passband in these two scripts -
  **not yet done, and not attempted without your input since it changes
  what the examples actually demonstrate.**
- **`exmpl_r1b.m`** — `Pole Removals Failed`. **Not yet traced this
  session** — `tstTFops.m` (same error message) was traced to
  `rmvCmplx`→`rmv_pole2` and confirmed unrelated to the `rmvl4.m` fix, but
  `exmpl_r1b.m`'s own failure point hasn't been individually confirmed to
  be the same call chain or a different one. Worth checking whether it's
  the same root cause before assuming so.
- **`tstTFops.m`** — `Pole Removals Failed`, confirmed at
  `rmvCmplx`→`rmv_pole2`, not yet root-caused further.
- **`ECG1.m` / `ECGrial1.m`** — archived to `examples/archive/`, dropped
  from the runnable suite. Need real ECG/PhysioBank `.mat` data that was
  deliberately excluded from this repo; not fixable from any machine
  without that data.

## Suggested next steps

1. Trace `exmpl_r1b.m`'s actual failure point the same way `tstTFops.m`
   was traced (wrap in a debug script, catch `ME`, print `ME.stack`) to
   confirm whether it's the same `rmvCmplx`/`rmv_pole2` issue or something
   else.
2. Decide whether `dig_linPh_1_6_0.m`/`dig_linPh_1_8_0.m` are worth
   actually fixing (reduce pole count and/or widen/recenter the passband)
   versus leaving as documented known limitations of the design
   methodology for that kind of spec.
3. Once `exmpl_r1b.m`/`tstTFops.m` are resolved (fixed or fully
   root-caused as a documented limitation), run the full suite fresh
   (`tools/run_all_examples.sh &`) to get a clean end-to-end confirmation
   — most fixes this session were verified individually via a targeted
   glob rather than a full run since the two full runs done earlier
   (2026-09-21, 2026-09-22).

## Tools / workflow reminders

- `tools/run_all_examples.sh [timeout_seconds] [glob]` — the test harness.
  Runs each `examples/*.m` in a fresh MATLAB `-batch` process; results to
  `tools/reports/<timestamp>/summary.txt` (gitignored).
- `tools/monitor_progress.sh` — polls a report dir once a minute if
  watching a long run.
- For a single-file stack trace (the harness only captures `ME.message`,
  not the stack), use a small wrapper: `run('examples/foo.m')` inside a
  `try`/`catch`, print `ME.stack(k).name`/`.line` in a loop.
- Git: this machine (home) has its own local commit history, never pushed
  directly (global rule: never `git push` from home). g22 holds the
  shared history and does the actual push to origin. Workflow for each
  fix: commit on home → `git show --name-only --pretty=format: HEAD` to
  get the exact changed-file list → `rsync -avR --files-from=<that list>`
  to g22 → commit the same message on g22 → `git push origin master` on
  g22.
