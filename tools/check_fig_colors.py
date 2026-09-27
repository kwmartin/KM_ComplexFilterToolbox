#!/usr/bin/env python3
"""check_fig_colors.py -- verify the ACTUAL colours present in a rendered
paper-figure PDF, on disk, pixel by pixel. This is deliberately independent
of MATLAB: it does not trust that the code that generated a figure did what
it was supposed to, or that a stale file wasn't left behind from an earlier
run -- it rasterizes the real .pdf file and counts pixels.

Run after regenerating doc/figures/*.pdf (examples/paper_figs_scld.m) and
before telling anyone a figure is fixed:

    python3 tools/check_fig_colors.py

Exits non-zero and prints every failure if any figure is missing an
expected colour or has one it shouldn't. Requires `pdftoppm` (poppler-utils,
already used elsewhere in this repo's build) and Pillow.

Expected colours: lib/combinedMagGdFig.m's default "before" style is thin
grey (full band) / light green (passband zoom), and "after" is always
solid red, for EVERY combined figure with a before/after pair -- so every
such figure must show grey, green and red. (Blue still shows up too, but
only as the zoom-view axis ticks/labels -- .zoomAxisColor in
lib/plotTwo.m, independent of curve colour -- so it is not asserted here
one way or the other.)
"""
import argparse
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np
from PIL import Image

COLOR_DEFS = {
    'black': lambda r, g, b: (r < 60) & (g < 60) & (b < 60),
    'cyan':  lambda r, g, b: (r < 150) & (g > 150) & (b > 150),
    'blue':  lambda r, g, b: (r < 100) & (g < 100) & (b > 150),
    'red':   lambda r, g, b: (r > 150) & (g < 100) & (b < 100),
    'gray':  lambda r, g, b: (abs(r.astype(int) - g.astype(int)) < 15) &
                              (abs(g.astype(int) - b.astype(int)) < 15) &
                              (r >= 60) & (r < 200),
    'green': lambda r, g, b: (g.astype(int) > r.astype(int) + 20) &
                              (g.astype(int) > b.astype(int) + 20) &
                              (abs(r.astype(int) - b.astype(int)) < 30) & (g > 120),
}

# figure (no extension) -> {colour: (min_px, max_px_or_None)}
# max_px_or_None means "must be absent (0)"
EXPECTATIONS = {
    'fig_m2_combined': {'gray': (100, None), 'green': (100, None), 'red': (500, None)},
    'fig_m2w_combined': {'gray': (100, None), 'green': (100, None), 'red': (500, None)},
}


def count_colors(png_path):
    im = np.array(Image.open(png_path).convert('RGB'))
    r, g, b = im[:, :, 0], im[:, :, 1], im[:, :, 2]
    return {name: int(fn(r, g, b).sum()) for name, fn in COLOR_DEFS.items()}


def check_one(fig_dir, name, out_dir):
    pdf = fig_dir / f'{name}.pdf'
    if not pdf.exists():
        return [f'{name}: {pdf} does not exist']
    prefix = out_dir / name
    subprocess.run(
        ['pdftoppm', '-f', '1', '-l', '1', '-r', '150', '-png', str(pdf), str(prefix)],
        check=True, capture_output=True)
    pages = sorted(out_dir.glob(f'{name}-*.png'))
    if not pages:
        return [f'{name}: pdftoppm produced no page']
    counts = count_colors(pages[0])
    failures = []
    for color, (lo, hi) in EXPECTATIONS.get(name, {}).items():
        n = counts.get(color, 0)
        if n < lo:
            failures.append(f'{name}: expected >= {lo} {color} px, found {n}')
        if hi is not None and n > hi:
            failures.append(f'{name}: expected <= {hi} {color} px, found {n}')
    print(f'{name}: {counts}  (rendered: {pages[0]})')
    return failures


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--fig-dir', default='doc/figures')
    ap.add_argument('names', nargs='*', default=list(EXPECTATIONS))
    args = ap.parse_args()

    fig_dir = Path(args.fig_dir)
    all_failures = []
    with tempfile.TemporaryDirectory() as tmp:
        out_dir = Path(tmp)
        for name in args.names:
            all_failures += check_one(fig_dir, name, out_dir)

    if all_failures:
        print('\nFAILED:')
        for f in all_failures:
            print(' -', f)
        sys.exit(1)
    print('\ncheck_fig_colors: ALL PASSED')


if __name__ == '__main__':
    main()
