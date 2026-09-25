#!/usr/bin/env python3
"""make_references.py - build doc/References.pdf from doc/References.yaml.

References.pdf lists documents used in developing the toolbox that cannot be
redistributed in the repository (copyright), grouped by topic, each with its
full reference, an optional DOI or URL, and a note on why it matters. It is
public (see .gitignore) and is extended by editing the YAML.

The flow is the same as tools/make_ieee_tex.py (doc/make_tex_flow.md,
section 12): load the content YAML and the string.Template layouts in
tools/references_templates.yaml, fill one template per entry and per group,
assemble the document, run pdflatex, copy the PDF next to the YAML.

Usage:
    tools/make_references.py [doc/References.yaml] [--out-dir D] [--no-pdf]
"""
import argparse
import datetime
import shutil
import sys
from pathlib import Path

import yaml

sys.path.insert(0, str(Path(__file__).resolve().parent))
from make_ieee_tex import DocError, fill, need, runLatex, warnControlChars  # noqa: E402

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_CONTENT = REPO_ROOT / "doc" / "References.yaml"
DEFAULT_TEMPLATES = REPO_ROOT / "tools" / "references_templates.yaml"
DEFAULT_OUT = REPO_ROOT / "tools" / "build" / "references"


def link(tmpls, e, where):
    out = ""
    if e.get("doi"):
        out += fill(tmpls, "doi_link", {"doi": e["doi"]}, where)
    if e.get("url"):
        out += fill(tmpls, "url_link", {"url": e["url"]}, where)
    return out


def buildTex(doc, tmpls):
    num = 0
    groups = []
    keys = set()
    for g, grp in enumerate(need(doc, "groups", "doc")):
        entries = []
        for k, e in enumerate(need(grp, "entries", f"groups[{g}]")):
            at = f"groups[{g}].entries[{k}]"
            key = need(e, "key", at)
            if key in keys:
                raise DocError(f"{at}: duplicate key '{key}'")
            keys.add(key)
            num += 1
            entries.append(fill(tmpls, "entry", {
                "num": num,
                "cite": str(need(e, "cite", at)).strip(),
                "link": link(tmpls, e, at),
                "note": str(need(e, "note", at)).strip(),
            }, at))
        groups.append(fill(tmpls, "group", {"title": need(grp, "title", f"groups[{g}]"),
                                             "entries": "\n\n".join(entries)}, f"groups[{g}]"))
    repo = doc.get("in_repository") or []
    if repo:
        entries = []
        for k, e in enumerate(repo):
            at = f"in_repository[{k}]"
            num += 1
            entries.append(fill(tmpls, "repo_entry", {
                "num": num,
                "cite": str(need(e, "cite", at)).strip(),
                "link": link(tmpls, e, at),
                "file": str(need(e, "file", at)).replace("_", r"\_"),
                "note": str(need(e, "note", at)).strip(),
            }, at))
        groups.append(fill(tmpls, "group", {"title": "Documents Included in the Repository",
                                             "entries": "\n\n".join(entries)}, "in_repository"))
    return fill(tmpls, "document", {
        "title": need(doc, "title", "doc"),
        "author": need(doc, "author", "doc"),
        "date": doc.get("date", datetime.date.today().strftime("%B %-d, %Y")),
        "intro": str(need(doc, "intro", "doc")).strip(),
        "groups": "\n\n".join(groups),
    }, "document"), num


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("content", nargs="?", default=str(DEFAULT_CONTENT))
    ap.add_argument("--templates", default=str(DEFAULT_TEMPLATES))
    ap.add_argument("--out-dir", default=str(DEFAULT_OUT),
                    help="build folder (default tools/build/references, not committed)")
    ap.add_argument("--no-pdf", action="store_true", help="write the .tex only")
    args = ap.parse_args()

    content = Path(args.content).resolve()
    text = content.read_text(encoding="utf-8")
    warnControlChars(text, content.name)
    doc = yaml.safe_load(text)
    tmpls = yaml.safe_load(Path(args.templates).read_text(encoding="utf-8"))
    try:
        tex, n = buildTex(doc, tmpls)
    except DocError as e:
        sys.exit(f"error: {e}")
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    tex_path = out_dir / f"{content.stem}.tex"
    tex_path.write_text(tex, encoding="utf-8")
    print(f"tex:  {tex_path} ({n} references)")
    if args.no_pdf:
        return
    log = runLatex(tex_path)
    pdf = content.with_suffix(".pdf")
    shutil.copy2(tex_path.with_suffix(".pdf"), pdf)
    print(f"pdf:  {pdf}")
    print(f"overfull hboxes: {log.count('Overfull \\\\hbox')}")


if __name__ == "__main__":
    main()
