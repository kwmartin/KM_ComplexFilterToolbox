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

## 3. Sort and commit the uncommitted work in `unlAdd` — needs your spot-check on results

125 modified + 41 untracked files are currently sitting uncommitted. Split
into:

- [ ] **Feature commit**: `lib/SYMMETRIC_MODE.md` + `place_poles_sym.m`,
      `get_poles_sym.m`, `make_Kz_sym.m`, `find_minima_sym.m`,
      `dlogKK_dp_sym.m` — a documented, additive pole-placement feature that
      looks finished but was never committed.
- [ ] **Fix commits**: genuine `lib/*.m` / `examples/*.m` diffs (same style
      as the already-committed `muller.m` fix — tolerance/threshold tweaks,
      convergence guards, plot-label corrections). Grouped logically, not
      one giant commit.
- [ ] **Discard, don't commit**: `*.asv` files, `examples/debug.txt`,
      `lib/trnsfrm_scratch.m`, and similar scratch/dead-end files.
- [ ] **Regenerated binaries**: `examples/Figures/*.png/.pdf` showing as
      modified — commit as-is, expected output from re-running examples.

MATLAB R2024b is available (`matlab -nodisplay -nosplash -batch "..."`). Each
non-trivial algorithmic change will be run against its example before being
proposed for commit, with actual output reported — not just the diff.

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
