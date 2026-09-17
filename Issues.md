# Integration Issues — unlAdd ↔ master ↔ GitHub

Working list for merging `/home/Dropbox/Matlab/Complex/KM_ComplexFilterToolbox`
(branch `unlAdd`, this repo) with `/home/Dropbox/Matlab/KM_ComplexFilterToolbox`
(branch `master`, in sync with `origin`) into one clean, public-cloneable repo.
Ordered by priority = the order to work through them; later issues depend on
earlier ones being resolved. See `~/.claude/plans/i-have-this-project-temporal-lynx.md`
for the full background/investigation this list was built from.

Status legend: `[ ]` open · `[x]` done · `[~]` in progress

---

## 1. Confirm the junk/exclusion list — confirmed by user 2026-09-17

Before any history rewrite, sign off on exactly what gets deleted (strike
anything you want kept, add anything missed). Everything below is currently
tracked in git on `unlAdd` and/or `master`. Actual removal happens in issue 7
(history rewrite) — nothing has been deleted yet.

- [x] `tmp/` — ECG/physiobank test data (~3.7MB, incl. 1.8MB binary `100_256.dat`)
- [x] `pathdef.m`, `pathdef_.m` — MATLAB path caches, hardcode a different
      machine's paths (e.g. `/home/martin/...` vs this machine's
      `/home/Dropbox/...`)
- [x] `settings.mat`, `scatchsheet`, `scatchsheet~`, `worksheet.m~`,
      `testjl.m` (empty file)
- [x] every `*.asv` (MATLAB editor autosave) anywhere in the tree
- [x] top-level `afile.mat`, `filtOut.mat` (7.4MB)
- [x] the file literally named `Good:` — an accidentally pasted MATLAB
      console dump, not source
- [x] `BackUp/` — accidental Julia REPL garbage (one filename is literally a
      `julia>` command)
- [x] `commit.msg`, `history1.txt` — personal scratch notes
- [x] `cmplxApprx/`'s own junk that came along with issue 4's merge (already
      excluded when copying, never re-added): `*.asv`, `outDat.mat` (328KB),
      `qd_dds.out` (650KB), `OpenGL_Version`

**Not on this list:** `doc/` — handled separately in issue 1b, since it's
reference material to keep (staged outside git), not junk to delete.
**Also not on this list (yet):** `goFiles/` and `examples/Figures/` — see
issue 5, a separate size/scope call rather than clear-cut junk.

---

## 2. Stage `doc/` outside the repo — autonomous

Copy `doc/`'s full contents (47MB of third-party PDFs/PS/odt — textbook
chapters, IEEE papers, a PhD thesis) to `/home/Dropbox/Matlab/Complex/docs`,
a staging area outside both git working trees, before removing `doc/` from
git tracking. You'll later hand-pick which staged files belong in the
unified repo's own `docs/` directory.

- [x] Copy `doc/` → `/home/Dropbox/Matlab/Complex/docs` (37 files, verified
      byte-identical via `diff -rq`; this clone's `doc/` was the more
      complete of the two — it had 2 extra PDFs the other clone's `doc/`
      lacked, incl. `Approximation_of_complex_IIR_bandpass_filters_without_
      arithmetic_symmetry.pdf`, the paper `SYMMETRIC_MODE.md` cites)
- [x] Confirm nothing in the other clone's `doc/` is missing from the copy
- [ ] Remove `doc/` from git tracking (actual history purge happens in
      issue 7, alongside the rest of the exclusion list)

---

## 3. Sort and commit the uncommitted work in `unlAdd` — mostly done, 3b needs your decision

125 modified + 41 untracked files were sitting uncommitted. Sorted and
committed in stages, each verified with `checkcode` and/or `matlab -batch`
runs rather than just read from the diff:

- [x] **Feature commit** (`a79d89c7`): `lib/SYMMETRIC_MODE.md` +
      `place_poles_sym.m`, `get_poles_sym.m`, `make_Kz_sym.m`,
      `find_minima_sym.m`, `dlogKK_dp_sym.m`, plus the `design_ctm_filt.m`/
      `dsgnAnalogFltr.m` wiring. Independently re-verified against
      `SYMMETRIC_MODE.md`'s own example: 4.4e-16 max mirror-pole-pair error
      in symmetric mode vs 0.10 for the non-symmetric baseline on the
      identical spec — matches the doc's claim.
- [x] **lib/ fix commit** (`b13d8f12`): 21 files - real bugs (`chckEqlOrdr.m`
      missing `abs()`, `polyClass.m`'s one-sided `mtimes`, `rmvl4.m`'s
      uncancelled pole/zero pair, `trnsfrm.m` being a dead script despite
      every caller invoking it as a function), tuning changes, and cosmetic
      fixes. Full list and rationale in the commit message.
- [x] **multiRate/ commit** (`2e7e7bbe`): new resonator-simulation drivers
      and a `cmplxRsntrClass` constructor cleanup - each new function called
      directly via `matlab -batch` and checked against `testCmplxRsntrs.m`'s
      actual (non-obvious) argument order.
- [x] **examples/ commit** (`1d302e10`): 78 files - mostly call sites
      catching up to already-committed lib signature changes (e.g.
      `cascadeClass.plotGn` dropped its `ws` param back in 2020; many
      examples still called the old 4-arg form and would have errored).
      Caught and fixed one real bug in the process: `exmpl1.m` was capturing
      only 6 of `nrmlzSpecsA`'s 7 outputs, silently shifting `sclFctr`/
      `shftFctr` by one position - verified the fix end-to-end with
      `matlab -batch`.
- [x] **Figures commit** (`46d32419`): regenerated PNG/PDF output matching
      the examples/ changes.
- [x] **Remaining new files commit** (`d576106d`): `circFnDefs.yml`,
      `examples/Fbnk_1_12_0.yml`, `examples/QuadDDFS.png`,
      `examples/dig_equiGd_5_10_0.m`, `lib/goDbg.m`.
- [x] **Discarded** (deleted, not committed): `examples/debug.txt` (a pasted
      MATLAB console transcript) and `lib/trnsfrm_scratch.m` (a saved-off
      copy of `trnsfrm.m`'s old, dead content, superseded by the rewrite in
      `b13d8f12`). All `*.asv` files are now gitignored (issue 10) rather
      than needing individual handling.

### 3b. Six `lib/` files held back — need your call on each

These didn't get the benefit of the doubt during sorting because something
about the diff looked like it could be an unintentional bug rather than a
deliberate change, and guessing wrong on filter-design math seemed worse than
asking. None are committed yet.

- [ ] **`lib/findLossEdges.m` and `lib/findLossMinima.m`** — both add a
      helper `lgspc = @(x1,x2,N) log10(logspace(x1,x2,N))`. Verified in
      MATLAB: `log10(logspace(a,b,N))` is *exactly* `linspace(a,b,N)` (the
      `log10`/`logspace` cancel). `findLossMinima.m` then uses it as
      `w = lgspc(0,100,10001)` in place of the old `logspace(-2,2,1000)` -
      i.e. it switched from a **log-spaced** search grid (0.01 to 100) to a
      **linear** one (0 to 100, including 0). Given the function's job is
      finding stopband loss minima across frequency, a log grid seems like
      the intended behavior and this looks like an accidental composition
      bug rather than a deliberate switch to linear spacing. Does this match
      what you intended, or should `lgspc(...)` calls just be `logspace(...)`
      calls (dropping the redundant `log10`)?
- [ ] **`lib/place_polesdLP4.m` and `lib/place_polesdLP5.m`** — both define
      that same `lgspc` helper but never actually call it (dead code either
      way, harmless, but worth dropping either way once 3b is resolved).
      Separately, `place_polesdLP4.m` changes
      `findLossEdges(Hy1,lssMin,wy1)` to
      `findLossEdges(Hy1,lossMin(2),wy1)` - from "the minimum of all loss
      minima" to specifically the *second* one. Note: `examples/dig_equiGd_
      15_0_0.m` (already committed) independently switched from calling
      `place_polesdLP4` to `place_polesdLP5` in this same area, which might
      mean `place_polesdLP4.m`'s in-progress edit here was abandoned in
      favor of LP5 rather than finished - do you still need this change, or
      is `place_polesdLP4.m` effectively superseded by LP5 now?
      `place_polesdLP5.m` also wraps its core Newton-step linear solve in a
      `try/catch` that just `fprintf`s on failure and continues the loop
      with the previous iteration's `X` - intentional robustness against
      occasional singular systems, or should a failure here actually stop
      the search?
- [ ] **`lib/setK.m`** — changes the unconditional `Ply.K = real(Ply.K)`
      (itself flagged with a pre-existing "this might be incorrect; needs to
      be verified" comment) to `if real(Ply.K) > imag(Ply.K) ... else
      Ply.K = imag(Ply.K); end`. That comparison isn't magnitude-aware
      (e.g. real=-5, imag=1 takes the `imag` branch, even though `|real|` is
      the bigger component) - is the intent `abs(real(Ply.K)) >
      abs(imag(Ply.K))`, or something else entirely?
- [ ] **`lib/LinPhFltr.m`** (plus its two new, otherwise-unused support
      files `lib/scaleZPK.m` and `lib/sortReal.m`, currently untracked
      pending this) — two adjacent lines:
      `p2 = z2s(rts(1:end-1)).';` immediately followed by `p2 = p1;`. The
      fsolve-refined pole positions computed on the first line are
      discarded on the very next line in favor of the unrefined prototype
      poles `p1` - `T0 = rts(end)` still uses the fsolve result, but the
      pole placement itself doesn't. This looks like a debug leftover (a
      "what if I skip the correction step" experiment) rather than an
      intended simplification, especially paired with the block below it
      being commented out with the note "I don't remember what the purpose
      of the following is" - but if the equi-ripple group-delay correction
      genuinely turned out to be unnecessary for this filter class, `p2 =
      p1;` might be exactly right. Keep, revert to using the fsolve result,
      or something else?

### 3c. Two more items surfaced while sorting — need your call

- [ ] `multiRate/osc1.dat` (untracked, 9.1MB ASCII time/voltage data) - no
      `.m` file anywhere in the repo reads it (grepped the whole tree).
      Looks like it might be oscillator-simulation data meant to pair with
      `dc_osc.m`/`sin_approx.m` but not wired up yet. Keep as a to-be-used
      fixture, or hold off on committing something this large with no
      current consumer?
- [ ] `examples/dig_equiGd_3_4_0_wrk.m` (untracked) - a "_wrk" variant of
      the already-committed `dig_equiGd_3_4_0.m`, differing only in a few
      plot y-axis limits (e.g. `-40` vs `-200`, `-300` vs `-320`). Looks like
      an earlier/alternate-parameter draft superseded by the committed
      version rather than something distinct - discard, or is it worth
      keeping as its own example?

---

## 4. Pull `master`'s unique content into `unlAdd` — done (commit `ac27ec94`)

- [x] Copied `cmplxApprx/`'s real files (`apprxCoid.m`, `bilinearAllPass.m`,
      `cmplxApprx1.m`, `filterAllPass.m`, `filterPN.m`, `filterPN2.m`,
      `freqDetect.m`, `ldiAllPass.m`, `matchCoid.m`, `tstAllPass.m`,
      `startup.m`, `QuadDDFS.png`) from `815abfa` into `unlAdd`, dropping the
      junk from issue 1.
- [x] Committed `lib/dsgnEquiRplGD.m` (was untracked but byte-identical in
      both clones already — no conflict).
- [x] Re-verified `681016a1..815abfa`/`e452182` in full: beyond `cmplxApprx/`,
      the only other unique change was a one-word comment typo fix
      (`desing`→`design`) in `lib/design_dtm_filt.m`, now applied. Every other
      file master touched (`AnlzDH.m`, `LinPhFltr.m`, `dsgnDigitalFltr.m`,
      `plot_am_ph_gd.m`, `plot_dam_ph_gd.m`, `plot_drsps.m`,
      `examples/EqualFltr_1_6_0.m`) turned out to be a **parallel independent
      line** from the same `681016a1` starting point — `unlAdd`'s current
      working tree already contains every one of those fixes and has taken
      each further (e.g. `dsgnDigitalFltr.m` gained a whole new filter-design
      branch `unlAdd` never lost). Nothing else needed pulling in.

### 4b. `cmplxApprx/startup.m` hardcodes stale/external paths — done (commit `7aff3881`)

Was pointing at `/home/Dropbox/Matlab/KM_ComplexFilterToolbox/` (the other
clone) as its default `CMPLXROOT`, and `addpath`-ing an external, non-repo
personal utility library (`/home/Dropbox/Matlab/lib/`). Grepped every
`cmplxApprx/*.m` for calls to that library's function names (`afft`, `cfft`,
`dbi`, `db`, `firFlt2`, `gfft`, `sin_approx`, `slct_end`, `solveTriDiag`,
`nfft`) — no hits, so the `addpath` was vestigial and dropped. `CMPLXROOT`'s
default now derives from the script's own location (matching the portable
pattern the top-level `startup.m` already uses); verified with `matlab
-batch` that it resolves correctly and `cd`s into `examples/`.

---

## 5. Verify `muller.m` and related lib fixes stay authoritative — verification only, autonomous

Falls out naturally once `unlAdd` becomes the base branch — just confirm
after issue 7's rewrite that `lib/muller.m` and the other fixed files still
hold the `unlAdd` versions, not master's older ones.

---

## 6. Decide fate of two bulky-but-legitimate directories — needs your preference

- [ ] `goFiles/` (31MB: compiled Go binary `fltrBnk` + 28MB of `.dat`
      fixtures) — keep as-is, or exclude the binary/data and document how to
      regenerate them?
- [ ] `examples/Figures/` (several PDFs/EPS per example, 3–9MB each) — keep
      all tracked, or thin to one representative figure per example?

---

## 7. Rewrite git history with `git filter-repo` — mostly autonomous, force-push needs your go-ahead

- [ ] Run on a fresh mirror clone (never the only working copy)
- [ ] Strip every path from issue 1 (and `doc/`, per issue 2) from all commits
- [ ] Verify resulting `.git` size and spot-check `muller.m`/
      `place_poles_sym.m` content survived intact
- [ ] **Stop and get explicit approval before force-pushing** to `origin`

---

## 8. Promote `unlAdd` to `master` on GitHub — needs your approval

- [ ] Force-push cleaned `unlAdd` history to `origin/master`
- [ ] Decide fate of old `master` / `backup-remote-master` refs (retire vs.
      archive as a tag)

---

## 9. Retire the second local clone — needs your decision

- [ ] Once issue 4 is done, decide: delete
      `/home/Dropbox/Matlab/KM_ComplexFilterToolbox`, or re-point it to track
      the new cleaned `master` as an ordinary second checkout?

---

## 10. Harden `.gitignore` to prevent recurrence — done (commit `1a726186`)

- [x] Added rules for `*.asv`, `*~`, `pathdef.m`/`pathdef_.m`/`settings.mat`,
      and the specific top-level scratch files/dirs from issue 1
      (`scatchsheet`, `worksheet.m~`, `afile.mat`, `filtOut.mat`,
      `commit.msg`, `history1.txt`, `BackUp/`, `tmp/`). Those files stay
      tracked until issue 1/7's cleanup actually removes them — this only
      stops new instances from creeping back in.
