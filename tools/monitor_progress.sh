#!/bin/bash
# Polls a tools/run_all_examples.sh report directory once a minute and
# appends a progress line to <report_dir>/progress.log, until the run
# completes (summary.txt shows the "=== Summary ===" block) or this
# monitor is stopped (Ctrl-C / kill).
#
# Usage: tools/monitor_progress.sh [report_dir]
#   report_dir: a tools/reports/<timestamp> directory. If omitted, uses
#               the most recently created one under tools/reports/.
#
# Meant to be run alongside (not instead of) run_all_examples.sh, e.g.:
#   tools/run_all_examples.sh &
#   tools/monitor_progress.sh &

set -u
cd "$(dirname "$0")/.." || exit 1

REPORT_DIR="${1:-}"
if [ -z "$REPORT_DIR" ]; then
    REPORT_DIR="$(ls -dt tools/reports/*/ 2>/dev/null | head -1)"
    REPORT_DIR="${REPORT_DIR%/}"
fi
if [ -z "$REPORT_DIR" ] || [ ! -d "$REPORT_DIR" ]; then
    echo "No report directory found/specified." >&2
    exit 1
fi

TOTAL="$(ls examples/*.m 2>/dev/null | wc -l)"
SUMMARY="$REPORT_DIR/summary.txt"
LOGFILE="$REPORT_DIR/progress.log"

echo "$(date '+%Y-%m-%d %H:%M:%S') monitor started for $REPORT_DIR (total examples: $TOTAL)" >> "$LOGFILE"

while true; do
    if [ -f "$SUMMARY" ] && grep -q "^=== Summary ===" "$SUMMARY"; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') run complete" >> "$LOGFILE"
        tail -6 "$SUMMARY" >> "$LOGFILE"
        break
    fi

    done_count=0
    last_line=""
    if [ -f "$SUMMARY" ]; then
        done_count=$(grep -cE '^(OK|FAILED|TIMEOUT|SKIP)' "$SUMMARY")
        last_line=$(grep -E '^(OK|FAILED|TIMEOUT|SKIP)' "$SUMMARY" | tail -1)
    fi
    pct=0
    if [ "$TOTAL" -gt 0 ]; then
        pct=$(( done_count * 100 / TOTAL ))
    fi
    echo "$(date '+%Y-%m-%d %H:%M:%S') progress: $done_count/$TOTAL (${pct}%) - last: $last_line" >> "$LOGFILE"

    sleep 60
done
