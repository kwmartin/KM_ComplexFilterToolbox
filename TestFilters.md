# Testing the toolbox by running the examples

There's no unit test suite here — the closest thing is `examples/`, a set of
~125 scripts that each design and plot a real filter, exercising most of
`lib/`. `tools/run_all_examples.sh` runs every one of them in a fresh MATLAB
process and records what happened; `tools/monitor_progress.sh` watches a run
in progress. This file explains how to use both, and what to do with the
results.

## Prerequisites

- MATLAB is at `/usr/local/bin/matlab` (a symlink to `/usr/local/MATLAB/R2024b/bin/matlab`),
  and runs non-interactively via `-nodisplay -nosplash -batch`.
- Run from the repo root (both scripts `cd` there themselves via
  `dirname "$0"/..`, so `tools/run_all_examples.sh` works from anywhere).
- Each example runs in its own MATLAB subprocess (not a shared MATLAB
  session), so a crash or hang in one example can't take down the rest of
  the run.

## Running the examples

```bash
tools/run_all_examples.sh                  # every example, 120s timeout each
tools/run_all_examples.sh 300               # every example, 300s timeout each
tools/run_all_examples.sh 120 'Fbnk_*.m'    # only examples matching a glob
```

Arguments (both optional, positional):

| Arg | Default | Meaning |
|---|---|---|
| `timeout_seconds` | `120` | Per-example wall-clock timeout (`timeout(1)`-enforced) |
| `glob` | `*.m` | Shell glob, relative to `examples/`, to run a subset |

What it does for each `examples/*.m` file:

1. **Skips function files.** If the first non-comment, non-blank line
   starts with `function`, the file isn't a runnable script (it's a helper
   a script calls) — logged as `SKIP` and not executed.
2. Otherwise runs it as a fresh subprocess:
   ```bash
   matlab -nodisplay -nosplash -batch \
     "cd('<repo>'); addpath('lib'); addpath('examples'); close all; \
      try; run('<file>'); fprintf('###EXAMPLE_RESULT:OK###\n'); \
      catch ME; fprintf('###EXAMPLE_RESULT:FAILED### %s\n', ME.message); end"
   ```
   under `timeout <timeout_seconds>`, capturing stdout+stderr to a log file.
3. Classifies the result by inspecting the log:
   - **OK** — the `try` block completed and printed the OK marker.
   - **FAILED** — MATLAB caught an error (`ME.message` is shown), or the
     process exited without either marker (e.g. a parse error before
     `run()` was ever reached — in that case the log's last few lines are
     shown instead).
   - **TIMEOUT** — killed by `timeout` (exit code 124/137). Usually means
     the script opened a blocking dialog, is waiting on input, or is
     genuinely just slow — check the log for where it stalled.
   - **SKIP** — function file, not run.

### Output

Everything lands under `tools/reports/<timestamp>/` (gitignored — these are
point-in-time run artifacts, not source):

- `<example_name>.log` — full MATLAB output for that one example (figures
  still get created/saved as normal; only the display is suppressed).
- `summary.txt` — one line per example (`OK`/`FAILED`/`TIMEOUT`/`SKIP`,
  elapsed seconds, and the error message if any), plus a final count block:
  ```
  === Summary ===
  OK:      103
  FAILED:  22
  TIMEOUT: 0
  SKIPPED: 2
  Total wall time: 3821s
  ```

The full run takes on the order of an hour; run it in the background
(`tools/run_all_examples.sh &`, or via a backgrounded shell tool call) rather
than waiting on it interactively.

## Watching progress during a run

```bash
tools/monitor_progress.sh                       # watches the most recent tools/reports/<timestamp>/
tools/monitor_progress.sh tools/reports/20260921_115714
```

Polls the given (or latest) report directory once a minute and appends a
line to `<report_dir>/progress.log`:

```
2026-09-21 11:58:14 progress: 47/125 (37%) - last: OK      (18s)     examples/exmpl9.m
```

until `summary.txt` shows the `=== Summary ===` block (then logs a
"run complete" line with the final counts) or the monitor is killed. Run it
alongside the main run, not instead of it:

```bash
tools/run_all_examples.sh &
tools/monitor_progress.sh &
```

Progress is only ever written to `progress.log` — nothing is printed to the
terminal, so this is meant to be left running unattended and checked with
`tail progress.log` whenever you want a status update.

## Triaging results

After a run, work through `summary.txt`'s `FAILED` and `TIMEOUT` lines one
at a time:

1. Open the matching `<name>.log` and read the full error/stack trace, not
   just the one-line message in `summary.txt`.
2. Classify each failure:
   - **Real bug** (bad path, wrong argument count, stale/renamed variable,
     copy-paste collision between two examples writing the same output
     filename, etc.) — fix the example or the `lib/` function it calls, then
     re-run just that one file (`tools/run_all_examples.sh 120 'name.m'`) to
     confirm.
   - **Numerical/algorithmic limitation** (e.g. a solver failing to converge
     for a specific parameter combination) — needs actual investigation
     (run the failing case standalone, inspect intermediate values) before
     deciding whether it's a real defect or an inherent limit of the design
     being attempted. Don't guess-fix these.
   - **Environmental** (e.g. missing toolbox, a path specific to another
     machine) — note it, may not be fixable from this machine.
   - **Known-broken/WIP** — check if the example itself says so in a
     comment; if so, just note it, no action needed.
3. After fixing something in `lib/` or `examples/`, re-run the full suite
   (or at least everything that touches the changed function) before
   committing, since a fix can change numeric output for other examples
   too (regenerated `.yml`/`.png`/`.pdf` files are expected and should be
   committed alongside the code fix).

### Watch for accidental output bloat

`print(fig, name, '-dpdf')` on a figure with many overlaid data points
(e.g. a Monte-Carlo trace overlay from `runMcCscd`/`runMcCscd2`, which
plots ~100 traces of an 8192-point FFT per figure) can be 100x+ larger than
expected — 7.4MB instead of ~30-50KB, observed in `dig_fltr_2_7_1.m`,
`dig_fltr_2_8_1.m`, and `dig_fltr_2_10_1.m`. Root cause: in a headless
`-nodisplay` session (which this harness always uses), MATLAB has no
OpenGL available for print rasterization, so `-dpdf` silently falls back
to a full vector render regardless of renderer flags — confirmed `-opengl`
and `exportgraphics(...,'ContentType','image')` both hit the same
fallback, with MATLAB warning `cannot use OpenGL for printing when started
with '-nodisplay'`. The small originals were almost certainly produced
interactively, where OpenGL rasterization is available.

Fix: use `lib/printRasterPdf.m` instead of `print(...,'-dpdf')` for any
figure with a lot of overlaid trace data. It rasterizes via an
intermediate PNG (which prints fine headless) and wraps that as the PDF
page, so output size is small and reproducible in any environment. The
three examples above already use it; apply it to any similar
Monte-Carlo-overlay example that develops the same symptom.

More generally: before committing regenerated `examples/Figures/*`
output, check `git status`/`git diff --stat` for surprising size deltas
and investigate anything that jumped by more than roughly 2x rather than
committing it blindly.

## Known issues (as of the 2026-09-22 full-suite run)

Pre-existing failures, triaged and left as-is — not regressions. Compared
against the `20260921_115714` run, every failure below was already failing
there too (or, for `dig_linPh_1_8_0.m`, hitting the same underlying
`place_polesdLP3` issue with different numbers); that run's 22 failures
minus these 13 accounts exactly for the 9 that got fixed in between
(`dig_equiGd_5_10_0`, `dig_linPh_0_2_0`, `dig_linPh_1_2_0`,
`dig_linPh_1_4_0`, `dig_linPh_1_6_0`, `exmpl12`, `exmpl4`, `Fbnk_1_8_0`,
`mkYaml`). Re-check this list after any `lib/` change that touches the
functions involved.

**Environmental (missing toolbox/data, not fixable from this machine):**
- `DLddrFltr_1_2_0.m`, `DLddrFltr_1_4_0.m`, `DLddrFltr_1_6_0.m`,
  `DLddrFltr_1_8_0.m` — `Undefined function 'normrnd'`. Requires the
  Statistics and Machine Learning Toolbox, not installed here.
- `ECG1.m`, `ECGrial1.m` — required real ECG/PhysioBank `.mat` data under
  a personal, machine-specific path (`.../ecg/ECG_mat_data/` or
  `/home/martin/Medical/database/ECG_mat_data/`) that isn't in this repo
  (`Issues.md` §1 notes the ECG data under `tmp/` was deliberately removed
  as junk during the earlier repo cleanup). **Archived** to
  `examples/archive/` and dropped from the runnable suite (the harness's
  `examples/*.m` glob doesn't descend into subdirectories) rather than left
  failing, since there's no way to supply the missing data from this
  machine.

**Numerical/algorithmic limitation (needs real investigation, not a
guess-fix):**
- `dig_linPh_1_8_0.m` — `place_polesdLP3: only found 8 independent
  stop-band loss minima for 9 free pole(s)` — pole collision during
  stop-band placement for this specific order/spec.
- `exmpl_r1b.m`, `tstTFops.m` — `Pole Removals Failed`.

**Real bug (stale/renamed variable or wrong call signature):**
- `exmpl_1_5_1.m`, `exmpl_5_1_1.m` — `Unrecognized function or variable
  'X2o'`.
- `mkFltr_exmpl.m` — `Too many output arguments`.
- `shortDat.m` — `Unrecognized function or variable 'win'`.

## Related files

- `tools/run_all_examples.sh` — the test runner itself.
- `tools/monitor_progress.sh` — the progress watcher.
- `tools/reports/` — gitignored output directory (see `.gitignore`).
- `examples/archive/` — examples pulled out of the runnable suite because
  they depend on something this repo can't provide (e.g. personal data
  files) — see "Known issues" above. Kept for reference, not run by
  `tools/run_all_examples.sh`'s flat `examples/*.m` glob.
- `Issues.md` — tracks the broader repo-integration/cleanup effort this
  harness grew out of, not individual example failures.
