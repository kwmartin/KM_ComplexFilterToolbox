#!/bin/bash
# Runs every runnable script in examples/ in its own fresh MATLAB process,
# to exercise as much of lib/ as possible and surface crashes/errors that
# wouldn't show up from reading the code alone.
#
# Usage: tools/run_all_examples.sh [timeout_seconds] [glob]
#   timeout_seconds: per-example timeout (default 300)
#   glob:            optional shell glob (relative to examples/), e.g.
#                     'Fbnk_*.m', to run a subset instead of everything.
#
# Each example is skipped automatically if its first non-comment,
# non-blank line starts with "function" (i.e. it's a function file, not a
# runnable script - examples/ has a couple of these).
#
# Output: a log per example under tools/reports/<timestamp>/, plus a
# summary table printed to stdout and saved as tools/reports/<timestamp>/summary.txt.
# The reports/ directory is gitignored - these are point-in-time run
# results, not source.

set -u
cd "$(dirname "$0")/.." || exit 1
REPO="$(pwd)"

TIMEOUT="${1:-300}"
GLOB="${2:-*.m}"

STAMP="$(date +%Y%m%d_%H%M%S)"
OUTDIR="tools/reports/$STAMP"
mkdir -p "$OUTDIR"

SUMMARY="$OUTDIR/summary.txt"
: > "$SUMMARY"

echo "Running examples/$GLOB with ${TIMEOUT}s timeout each. Logs/summary in $OUTDIR" | tee -a "$SUMMARY"

n_ok=0
n_failed=0
n_timeout=0
n_skipped=0
total_start=$(date +%s)

for f in examples/$GLOB; do
    [ -e "$f" ] || continue
    base="$(basename "$f" .m)"

    firstcode="$(grep -m1 -vE '^\s*%|^\s*$' "$f")"
    if [[ "$firstcode" == function* ]]; then
        echo "SKIP (function file)  $f" | tee -a "$SUMMARY"
        n_skipped=$((n_skipped + 1))
        continue
    fi

    log="$OUTDIR/$base.log"
    start=$(date +%s)
    timeout "$TIMEOUT" matlab -nodisplay -nosplash -batch \
        "cd('$REPO'); addpath('lib'); addpath('examples'); close all; try; run('$f'); fprintf('###EXAMPLE_RESULT:OK###\n'); catch ME; fprintf('###EXAMPLE_RESULT:FAILED### %s\n', ME.message); end" \
        > "$log" 2>&1
    rc=$?
    elapsed=$(( $(date +%s) - start ))

    if [ $rc -eq 124 ] || [ $rc -eq 137 ]; then
        echo "TIMEOUT (${elapsed}s)     $f" | tee -a "$SUMMARY"
        n_timeout=$((n_timeout + 1))
    elif grep -q "###EXAMPLE_RESULT:OK###" "$log"; then
        echo "OK      (${elapsed}s)     $f" | tee -a "$SUMMARY"
        n_ok=$((n_ok + 1))
    elif grep -q "###EXAMPLE_RESULT:FAILED###" "$log"; then
        msg="$(grep "###EXAMPLE_RESULT:FAILED###" "$log" | sed 's/.*###EXAMPLE_RESULT:FAILED### //')"
        echo "FAILED  (${elapsed}s)     $f -- $msg" | tee -a "$SUMMARY"
        n_failed=$((n_failed + 1))
    else
        # MATLAB itself crashed/errored before our try/catch could report
        # (e.g. a parse error, or it never reached the run() call).
        msg="$(tail -3 "$log" | tr '\n' ' ')"
        echo "FAILED  (${elapsed}s)     $f -- [no result marker] $msg" | tee -a "$SUMMARY"
        n_failed=$((n_failed + 1))
    fi
done

total_elapsed=$(( $(date +%s) - total_start ))
{
    echo ""
    echo "=== Summary ==="
    echo "OK:      $n_ok"
    echo "FAILED:  $n_failed"
    echo "TIMEOUT: $n_timeout"
    echo "SKIPPED: $n_skipped"
    echo "Total wall time: ${total_elapsed}s"
} | tee -a "$SUMMARY"
