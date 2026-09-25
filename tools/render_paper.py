#!/usr/bin/env python3
"""render_paper.py - render a Markdown paper (with inline LaTeX math) to a
browser-viewable HTML file and a print-quality PDF.

The HTML is meant to be opened in Chrome: it embeds MathJax, which renders
the document's $...$/$$...$$ math client-side. The PDF is compiled from a
LaTeX intermediate by pdflatex, so its equations are typeset by LaTeX
itself, not a browser's print-to-PDF of the MathJax output.

Both conversions are done by pandoc; this script's own job is to drive
pandoc and pdflatex (via subprocess) and manage the resulting files.

Usage:
    tools/render_paper.py [markdown_file] [options]

If markdown_file is omitted, this defaults to doc/CmplxFltrGrpDly.md.

Every run does the actual pandoc/pdflatex build in --build-dir (default
tools/build/) -- that copy is meant to be committed and pushed, so it's
available without needing pandoc/pdflatex/chrome installed elsewhere. The
final .html/.pdf are then also copied into --doc-dir (default doc/) as a
local, throwaway convenience copy for viewing/printing right away; doc/
already holds copyrighted reference material excluded from git (see
Issues.md issue 2), so this copy is not meant to be committed from there.
Use --no-doc-copy to skip it.

Figures: the paper refers to images as figures/<name> with no extension
(written by examples/paper_figs_scld.m into doc/figures/ as both .pdf and
.png). The LaTeX build uses the vector .pdf and the HTML build the .png
(pandoc's --default-image-extension). The figures/ folder next to the
Markdown file is copied into --build-dir, since pdflatex runs there and
the built HTML refers to figures/<name>.png relative to itself; after the
PDF is built only the .png copies are kept there.

Requires `pandoc` and `pdflatex` on PATH. `google-chrome` (or `chromium`/
`chromium-browser`) is only needed if --view is used.

Examples:
    tools/render_paper.py                          # doc/ copy + tools/build/ copy
    tools/render_paper.py --view html               # also open the HTML in Chrome
    tools/render_paper.py --pdf-only --view pdf      # just the PDF, then open it
    tools/render_paper.py --no-doc-copy              # only tools/build/, nothing in doc/
    tools/render_paper.py doc/OtherNotes.md          # a different input file
"""
import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_INPUT = REPO_ROOT / "doc" / "CmplxFltrGrpDly.md"
DEFAULT_BUILD_DIR = REPO_ROOT / "tools" / "build"
DEFAULT_DOC_DIR = REPO_ROOT / "doc"

# pandoc's bare --mathjax defaults to a local Debian package path
# (/usr/share/javascript/mathjax/MathJax.js) that isn't installed on this
# machine, which would silently produce an HTML file with no working math
# at all. Point it at a real MathJax v3 build instead. This means viewing
# the HTML needs internet access; there is no bundled offline fallback.
MATHJAX_URL = "https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"

# amsmath is what makes \tag{...} work in the paper's numbered display
# equations; geometry/hyperref just make the printed PDF nicer to read.
LATEX_HEADER = r"""
\usepackage[margin=1in]{geometry}
\usepackage{amsmath}
\usepackage{amssymb}
\usepackage{hyperref}
\hypersetup{colorlinks=true, linkcolor=blue, urlcolor=blue}
"""


def run(cmd, cwd=None):
    """Run cmd via subprocess, printing it first; on failure, dump the
    captured output (which is otherwise suppressed) and exit."""
    print("+ " + " ".join(str(c) for c in cmd))
    result = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    if result.returncode != 0:
        sys.stderr.write(result.stdout)
        sys.stderr.write(result.stderr)
        sys.exit(f"error: command failed (exit {result.returncode})")
    return result


def which_or_die(tool):
    if shutil.which(tool) is None:
        sys.exit(f"error: '{tool}' not found on PATH -- required for this script")


def find_pagetitle(md_path: Path) -> str:
    """Use the document's first top-level heading as the browser-tab title."""
    for line in md_path.read_text(encoding="utf-8").splitlines():
        m = re.match(r"^#\s+(.*\S)\s*$", line)
        if m:
            return m.group(1)
    return md_path.stem


def build_html(md_path, out_path, pagetitle, toc):
    which_or_die("pandoc")
    cmd = [
        "pandoc", str(md_path), "-o", str(out_path),
        "--standalone", f"--mathjax={MATHJAX_URL}",
        "--metadata", f"pagetitle={pagetitle}",
        "--default-image-extension=png",
        f"--resource-path={md_path.parent}",
    ]
    if toc:
        cmd.append("--toc")
    run(cmd)


def build_tex(md_path, tex_path, header_path, toc):
    which_or_die("pandoc")
    cmd = [
        "pandoc", str(md_path), "-o", str(tex_path),
        "--standalone",
        "--include-in-header", str(header_path),
        "--default-image-extension=pdf",
        f"--resource-path={md_path.parent}",
    ]
    if toc:
        cmd.append("--toc")
    run(cmd)


def compile_pdf(tex_path, outdir, max_passes=5):
    """Run pdflatex repeatedly until its own "Rerun to get cross-references
    right" warning stops appearing (settling the table of contents' page
    numbers), or max_passes is reached. -interaction=nonstopmode and
    -halt-on-error keep a real LaTeX error from hanging the subprocess
    waiting on stdin."""
    which_or_die("pdflatex")
    for i in range(max_passes):
        result = run(
            [
                "pdflatex",
                "-interaction=nonstopmode",
                "-halt-on-error",
                "-output-directory", str(outdir),
                str(tex_path),
            ],
            cwd=outdir,
        )
        if "Rerun to get" not in result.stdout:
            return
    print(f"note: cross-references may still be unstable after {max_passes} passes")


def copy_figures(md_path, build_dir):
    """Copy the figures/ folder next to the Markdown file into build_dir,
    so pdflatex (run in build_dir) finds the .pdf figures and the built
    HTML finds the .png ones. Returns the copied folder, or None."""
    src = md_path.parent / "figures"
    if not src.is_dir():
        return None
    dst = build_dir / "figures"
    if src.resolve() == dst.resolve():
        return dst
    dst.mkdir(parents=True, exist_ok=True)
    for f in src.iterdir():
        if f.suffix in (".pdf", ".png"):
            shutil.copy2(f, dst / f.name)
    return dst


def drop_pdf_figures(fig_dir):
    """After the PDF is built, the .pdf figure copies in the build dir
    are no longer needed (the built HTML only uses the .png ones)."""
    if fig_dir is None:
        return
    for f in fig_dir.glob("*.pdf"):
        f.unlink()


def clean_aux(stem, outdir):
    for ext in (".aux", ".log", ".out", ".toc"):
        f = outdir / f"{stem}{ext}"
        if f.exists():
            f.unlink()


def open_in_chrome(path: Path):
    chrome = (
        shutil.which("google-chrome")
        or shutil.which("chromium")
        or shutil.which("chromium-browser")
    )
    if chrome is None:
        print(f"note: no chrome/chromium found on PATH; open manually: {path}")
        return
    subprocess.Popen([chrome, path.resolve().as_uri()])


def main():
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    ap.add_argument(
        "markdown", nargs="?", default=str(DEFAULT_INPUT),
        help=f"input Markdown file (default: {DEFAULT_INPUT.relative_to(REPO_ROOT)})",
    )
    ap.add_argument(
        "--build-dir", default=str(DEFAULT_BUILD_DIR),
        help=f"where the build happens; meant to be committed "
             f"(default: {DEFAULT_BUILD_DIR.relative_to(REPO_ROOT)})",
    )
    ap.add_argument(
        "--doc-dir", default=str(DEFAULT_DOC_DIR),
        help=f"where the local convenience copy goes; not meant to be "
             f"committed from here (default: {DEFAULT_DOC_DIR.relative_to(REPO_ROOT)})",
    )
    ap.add_argument(
        "--no-doc-copy", action="store_true",
        help="skip copying the result into --doc-dir",
    )
    ap.add_argument("--html-only", action="store_true", help="skip the PDF")
    ap.add_argument("--pdf-only", action="store_true", help="skip the HTML")
    ap.add_argument("--no-toc", action="store_true", help="omit the table of contents")
    ap.add_argument(
        "--keep-aux", action="store_true",
        help="keep pdflatex's .tex/.aux/.log/.out/.toc files (for debugging)",
    )
    ap.add_argument(
        "--view", choices=["html", "pdf", "both", "none"], default="none",
        help="open the result in Chrome when done (default: none)",
    )
    args = ap.parse_args()

    if args.html_only and args.pdf_only:
        sys.exit("error: --html-only and --pdf-only are mutually exclusive")

    md_path = Path(args.markdown).resolve()
    if not md_path.is_file():
        sys.exit(f"error: {md_path} not found")

    build_dir = Path(args.build_dir).resolve()
    build_dir.mkdir(parents=True, exist_ok=True)

    stem = md_path.stem
    html_path = build_dir / f"{stem}.html"
    tex_path = build_dir / f"{stem}.tex"
    pdf_path = build_dir / f"{stem}.pdf"
    header_path = build_dir / "_render_paper_header.tex"

    toc = not args.no_toc
    pagetitle = find_pagetitle(md_path)
    do_html = not args.pdf_only
    do_pdf = not args.html_only

    fig_dir = copy_figures(md_path, build_dir)

    if do_html:
        build_html(md_path, html_path, pagetitle, toc)
        print(f"HTML: {html_path}")

    if do_pdf:
        header_path.write_text(LATEX_HEADER, encoding="utf-8")
        build_tex(md_path, tex_path, header_path, toc)
        compile_pdf(tex_path, build_dir)
        if fig_dir is not None and fig_dir.resolve() != (md_path.parent / "figures").resolve():
            drop_pdf_figures(fig_dir)
        if not args.keep_aux:
            clean_aux(stem, build_dir)
            header_path.unlink(missing_ok=True)
            tex_path.unlink(missing_ok=True)
        print(f"PDF:  {pdf_path}")

    if not args.no_doc_copy:
        doc_dir = Path(args.doc_dir).resolve()
        doc_dir.mkdir(parents=True, exist_ok=True)
        if do_html:
            doc_html = doc_dir / html_path.name
            shutil.copy2(html_path, doc_html)
            print(f"HTML: {doc_html} (copy)")
        if do_pdf:
            doc_pdf = doc_dir / pdf_path.name
            shutil.copy2(pdf_path, doc_pdf)
            print(f"PDF:  {doc_pdf} (copy)")

    if args.view in ("html", "both") and do_html:
        open_in_chrome(html_path)
    if args.view in ("pdf", "both") and do_pdf:
        open_in_chrome(pdf_path)


if __name__ == "__main__":
    main()
