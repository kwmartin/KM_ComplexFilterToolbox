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
- [x] Removed `doc/` from git tracking (history purge happened in issue 7,
      alongside the rest of the exclusion list)
- [x] **Follow-up (commit `15c0721`)**: re-added
      `doc/Approximation_of_complex_IIR_bandpass_filters_without_arithmetic_
      symmetry.pdf` per your direction. Unlike the other 36 files, it had
      never actually been tracked in git, so issue 7's history rewrite never
      touched it and it survived on disk through the branch switch (issue 8)
      untracked. It's your own paper - the one `SYMMETRIC_MODE.md` and
      `lib/place_polesdLP4.m`'s docstring already cite as the toolbox's core
      reference - not third-party material, so back in the repo it goes. The
      other 36 third-party PDFs stay out (still safe at
      `/home/Dropbox/Matlab/Complex/docs`).

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

- [x] **`lib/findLossEdges.m` and `lib/findLossMinima.m`** — done (commit
      `01331c08`). Resolved per your direction: since `lgspc(x1,x2,N)` ==
      `linspace(x1,x2,N)` exactly, simplified both call sites to `linspace`
      directly (dropping the redundant `log10(logspace(...))` composition),
      and tagged each with a `REVIEW-LOGSPACE` comment noting that this
      replaced genuinely log-spaced search grids - `grep -rn REVIEW-LOGSPACE`
      finds them if this ever needs re-examining.
- [x] **`lib/place_polesdLP4.m` and `lib/place_polesdLP5.m`** — done (commit
      `95d0ae79`). Reproduced end-to-end (the exact `H2` `examples/dig_equiGd_
      15_0_0.m` builds) and confirmed `place_polesdLP4`'s uncommitted
      `lssMin` -> `lossMin(2)` change was a real regression: it drove the
      Newton-step solve to a singular matrix (RCOND=NaN) and crashed, while
      reverting to `lssMin` converged cleanly in 18 iterations on the same
      input. With that fixed, compared LP4 against LP5 directly (per your
      follow-up): they converge to essentially the same filter (stopband-loss
      max/mean/std match to displayed precision, min differs by ~0.5dB out
      of -312dB) - LP4 in 18 iterations, LP5 in 222 (LP4's step size is 10x
      larger: 0.5 vs 0.05). So `examples/dig_equiGd_15_0_0.m`'s earlier
      switch to LP5 was most likely just working around this same bug, not
      LP5 superseding LP4 - kept both, LP4 just converges faster. LP5's
      try/catch never actually triggered in testing (can't confirm it's
      needed, but it's not masking anything either) - left as-is. Also
      dropped the dead, never-called `lgspc` helper in both files.
- [x] **`lib/setK.m`** — done (commit `29f76cc6`). Instrumented setK.m and
      ran it across ~164 real setK calls (elliptic, symmetric-mode elliptic,
      partial monotonic designs): `imag(Ply.K)` was noise at the
      1e-14..1e-16 relative level in all but 2 calls, where `real(Ply.K)`
      was still correct - forcing the `imag` branch there left `exmpl.m`'s
      reported stopband attenuation completely unchanged, so that term's
      magnitude is just too small to matter either way. Kept
      `Ply.K = real(Ply.K)` (empirically always right) and replaced the
      unmotivated comparison with an actual runtime check: warn if
      `imag(K)` is ever non-negligible relative to `real(K)`, instead of
      silently mis-selecting.
- [x] **`lib/LinPhFltr.m`** (plus `lib/scaleZPK.m`/`lib/sortReal.m`) — done
      (commit `e2d06f16`), confirmed as a bug per your steer. Ran the
      function both ways (with and without `p2 = p1;`) for n in {4,7,9} and
      ap in {0.1, 3.0103}, measuring group-delay ripple over the passband:
      with `p2 = p1` in place, ripple was ~1e-6 to 1e-15 (a plain scaled
      Bessel response - `p2 = p1` bypassed the equi-ripple correction
      entirely, defeating the function's stated purpose), while removing it
      produced consistent, structured ripple (0.0006-0.0037) in every case -
      actual equi-ripple behavior. Removed the line; `T0` and filter order
      were unaffected.

### 3c. Two more items surfaced while sorting — resolved

- [x] `multiRate/osc1.dat` (9.1MB, unreferenced by any `.m` file) - left
      untracked initially per your call; **deleted outright** in a later
      follow-up once it was clear nothing would consume it.
- [x] `examples/dig_equiGd_3_4_0_wrk.m` - deleted per your call; superseded
      by the already-committed `dig_equiGd_3_4_0.m` (only differed in a few
      plot y-axis limits).

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

## 5. Verify `muller.m` and related lib fixes stay authoritative — done

Confirmed `lib/muller.m` on `unlAdd` still carries all its fixes (raised
`maxFun` to `1e40`, both `abs(h) < 1e-15`/`abs(h2+h1) < 1e-15` convergence
guards) - `master` never touched this file, so there was never any risk of
losing it. Will re-confirm once more after issue 7's history rewrite as a
final sanity check, but there's no open question here.

---

## 6. Decide fate of two bulky-but-legitimate directories — confirmed by user 2026-09-17

- [x] `goFiles/` (31MB: compiled Go binary `fltrBnk` + 28MB of `.dat`
      fixtures) — keep as-is.
- [x] `examples/Figures/` (several PDFs/EPS per example, 3–9MB each) — keep
      as-is.

---

## 7. Rewrite git history with `git filter-repo` — done

- [x] Installed `git-filter-repo` in an isolated venv (scratchpad only - the
      system Python is externally-managed, so this avoided any
      `--break-system-packages` system change).
- [x] Ran on a **mirror clone** in the scratchpad (`unlAdd-mirror.git`) - the
      real working copies were never touched by the rewrite itself.
- [x] Stripped every path from issue 1's confirmed list (`tmp/`, `pathdef.m`,
      `pathdef_.m`, `settings.mat`, `scatchsheet`(`~`), `worksheet.m~`,
      `testjl.m`, every `*.asv`, `afile.mat`, `filtOut.mat`, `Good:`,
      `BackUp/`, `commit.msg`, `history1.txt`, `cmplxApprx/{outDat.mat,
      qd_dds.out,OpenGL_Version}`) plus all of `doc/` (issue 2) from every
      commit on every branch (`unlAdd`, `master`, `backup-remote-master`).
- [x] Verified: `.git` size **815MB -> 34MB**; commit count on `unlAdd`
      unchanged at **38** (only blobs stripped, no commits lost);
      `git rev-list --objects --all | grep` for every excluded path/pattern
      returns nothing anywhere in history, not just the tip; spot-checked
      `lib/muller.m`, `lib/place_poles_sym.m`, `lib/setK.m`,
      `lib/LinPhFltr.m`, `cmplxApprx/apprxCoid.m` content at the tip; did a
      full working-tree checkout of the rewritten history into a scratch
      directory and confirmed every excluded path is gone while every real
      directory is intact.

---

## 8. Promote `unlAdd` to `master` on GitHub — done

- [x] Tagged `origin/master`'s pre-cleanup tip as `pre-cleanup-master` and
      pushed that tag first, per your call - it's permanently recoverable on
      GitHub. Left `backup-remote-master` untouched (already its own
      preserved ref, and it happens to already equal the pre-cleanup
      `unlAdd` tip too).
- [x] Force-pushed the rewritten `unlAdd` history to `origin/master`
      (`815abfaa -> 8aae12ed`). Verified from a **completely fresh clone**
      (not this session's mirror): 38 commits, junk-free tree, works
      end-to-end (`LinPhFltr` sanity check ran correctly).
- [x] Re-pointed this local clone at the new history. Important nuance:
      switching branches deletes tracked-then-absent files from disk (not
      just from git) - so before switching, backed up every excluded file
      that wasn't already staged elsewhere (`doc/` was already safe in
      `/home/Dropbox/Matlab/Complex/docs`) to
      `/home/Dropbox/Matlab/Complex/KM_ComplexFilterToolbox-pre-cleanup-junk`
      (11MB: `tmp/`, `pathdef.m`, `pathdef_.m`, `settings.mat`,
      `scatchsheet`(`~`), `worksheet.m~`, `testjl.m`, `afile.mat`,
      `filtOut.mat`, `Good:`, `BackUp/`, `commit.msg`, `history1.txt`, and
      every tracked `*.asv`) *before* running `git checkout master`. Nothing
      was lost. **Deleted this backup folder** once the whole plan was
      verified complete and nothing in it turned out to be needed.

### Loose ends from issue 8 — informational, no action needed unless you want it

- A default `git clone` of the repo now pulls all branches (branches
  fetched during clone aren't restricted to the default one), so
  `origin/unlAdd` and `origin/backup-remote-master` (both still at the old
  `590cc5bd` junk-laden tip) still add weight to a full clone - measured
  **84MB** for `git clone` with everything, vs the original **815MB**, still
  a huge win, and `git clone --single-branch -b master` (or GitHub's default
  zip/tarball download) is much smaller than even that. Left `unlAdd`/
  `backup-remote-master` alone since the plan's original framing was to keep
  old branches "as history markers," not rewrite them too - say the word if
  you'd like those cleaned up as well later.
- ~~This local clone's `.git` is still ~849MB...~~ **Done, see below.**
- Cloning printed a benign warning about `.gitmodules` having a duplicate
  submodule entry *at one historical commit* (not the current tree, which
  only has one clean entry) - cosmetic, no action needed.

### Follow-up cleanup: origin/unlAdd, origin/backup-remote-master, and local bloat — done

Per your follow-up request:

- [x] Tagged the shared old tip (`590cc5bd`, `origin/unlAdd` ==
      `origin/backup-remote-master`) as `pre-cleanup-unlAdd` and pushed it,
      same pattern as `pre-cleanup-master` - permanently recoverable.
- [x] Deleted both `origin/unlAdd` and `origin/backup-remote-master`
      (`git push origin --delete`). They were identical to each other, so
      this removed a fully redundant duplicate, not a second copy of
      anything unique.
- [x] Verified from a **third fresh clone**: `.git` **84MB** (both tags,
      `master`), commit count on `master` still 41 (38 + the 3 follow-up
      commits from issues 8/9), old history still reachable via
      `pre-cleanup-unlAdd`/`pre-cleanup-master`.
- Note on diminishing returns: measured object counts precisely -
  `pre-cleanup-unlAdd` only contributes **~11MB** of content not already
  reachable via `master`+`pre-cleanup-master` (their histories overlap
  heavily). `pre-cleanup-master` (kept per your earlier call) is actually
  the larger remaining factor at ~75MB. Deleting `pre-cleanup-unlAdd` too
  would only shave a further ~11MB off an 84MB repo - didn't do this without
  asking, since it's the one remaining safety net and the size upside is
  modest.
- [x] Local cleanup in both clones: deleted the now-fully-superseded local
  `unlAdd` branch (first clone) and local `backup-remote-master` branch
  (second clone), then `git reflog expire --expire=now --all` +
  `git gc --prune=now --aggressive` in both. **First clone: 849MB -> 85MB.
  Second clone: 330MB -> 85MB.** Verified both still build/run correctly
  afterward (`LinPhFltr`/`ldiAllPass` sanity checks).

---

## 9. Retire the second local clone — done

- [x] Re-pointed `/home/Dropbox/Matlab/KM_ComplexFilterToolbox` at the new
      `origin/master` per your call, rather than deleting it.
- [x] Before doing so, diffed its tracked tree against the new `origin/master`
      to see exactly what the switch would remove from disk. Found one real
      gap: `lib/ldiAllPass.m` (a general LDI all-pass helper) existed in this
      clone's `lib/` but had only been recovered into `cmplxApprx/` during
      issue 4, not `lib/` itself - added it back (identical content to
      `cmplxApprx/ldiAllPass.m`, verified with `matlab -batch`) before
      switching, so nothing unique was lost. Everything else in the diff was
      the same already-excluded junk (`doc/`, `*.asv`, `commit.msg`, several
      `*.m~` editor backups not previously seen in the other clone) - backed
      up to `/home/Dropbox/Matlab/KM_ComplexFilterToolbox-pre-cleanup-junk`
      (47MB) before the switch, same as issue 8's local repoint. **Deleted**
      once confirmed unneeded (same as the other clone's backup folder).
- [x] Verified: working tree clean, tracks `origin/master`, `ldiAllPass`
      runs correctly via `matlab -batch`.
- Note: this clone's `.git` is still ~330MB (a local `backup-remote-master`
  branch here still references the old junk-laden history, same situation
  as the first clone's leftover local `unlAdd` branch in issue 8) - left
  alone for the same reason.

---

## 10. Harden `.gitignore` to prevent recurrence — done (commit `1a726186`)

- [x] Added rules for `*.asv`, `*~`, `pathdef.m`/`pathdef_.m`/`settings.mat`,
      and the specific top-level scratch files/dirs from issue 1
      (`scatchsheet`, `worksheet.m~`, `afile.mat`, `filtOut.mat`,
      `commit.msg`, `history1.txt`, `BackUp/`, `tmp/`). Those files stay
      tracked until issue 1/7's cleanup actually removes them — this only
      stops new instances from creeping back in.
