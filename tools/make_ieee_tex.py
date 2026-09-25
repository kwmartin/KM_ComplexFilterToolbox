#!/usr/bin/env python3
"""make_ieee_tex.py - generate an IEEE conference paper (.tex and .pdf)
from a content YAML file and the string.Template layouts in
tools/ieee_templates.yaml.

The flow (explained in doc/make_tex_flow.md):
  1. load the content YAML and the templates YAML
  2. build the front matter: author blocks, keywords, bibliography
  3. addItms() walks the content's item tree; each item becomes
     setTmplt(templates[type], dct)
  4. assemble the whole file from the "document" template
  5. replace the inline markers in the body (xx/zz/aa/bb/cc ... yy)
  6. write <out-dir>/<value>.tex and run pdflatex until references settle
  7. report pages against page_limit, undefined references and
     citations, overfull boxes, and citation/bibliography mismatches

The design follows gnrtDoc.py / pyLatexLib.py (remoteker_ca1): the same
YAML item tree and markers, but string.Template instead of PyLaTeX.

Usage:
    tools/make_ieee_tex.py content.yaml [--templates T] [--out-dir D] [--no-pdf]

Needs only the standard library and PyYAML; IEEEtran comes from the
texlive-publishers package.
"""
import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path
from string import Template

import yaml

setTmplt = lambda tmpl, dct : Template(tmpl).substitute(dct)

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_TEMPLATES = REPO_ROOT / "tools" / "ieee_templates.yaml"

SECTION_CMDS = {"section": "section", "subsctn": "subsection",
                "subsubsctn": "subsubsection"}
LIST_ENVS = {"list": "itemize", "enums": "enumerate", "dscrpts": "description"}

# Inline markers, as in ~/bin/fixRef, plus cc...yy for \cite. A marker must
# not follow a letter, so words such as "accuracy" or "abbreviation" are
# never taken as markers. Labels, equation names and citation keys contain
# no spaces; emphasis may.
MARKERS = [
    (re.compile(r"(?<![A-Za-z])xx([^\s{}]+?)yy"), r"\\ref{\1}"),
    (re.compile(r"(?<![A-Za-z])zz([^\s{}]+?)yy"), r"\\eqref{eq:\1}"),
    (re.compile(r"(?<![A-Za-z])cc([^\s{}]+?)yy"), r"\\cite{\1}"),
    (re.compile(r"(?<![A-Za-z])aa(.+?)yy"), r"\\textit{\1}"),
    (re.compile(r"(?<![A-Za-z])bb(.+?)yy"), r"\\textbf{\1}"),
]


class DocError(Exception):
    """A problem in the content or templates YAML, reported by location."""


def fill(tmpls, name, dct, where):
    """setTmplt with an error that names the template, the missing field
    and the item being built."""
    if name not in tmpls:
        raise DocError(f"{where}: no template '{name}' in the templates YAML")
    try:
        return setTmplt(tmpls[name], dct)
    except KeyError as e:
        raise DocError(f"{where}: template '{name}' needs field {e}") from None
    except ValueError as e:
        raise DocError(f"{where}: template '{name}': {e} "
                       f"(a literal $ in a template must be written $$)") from None


def need(itm, key, where):
    if key not in itm or itm[key] is None:
        raise DocError(f"{where} ({itm.get('type')}): missing '{key}'")
    return itm[key]


def mkLabel(tmpls, prefix, itm, where):
    ref = itm.get("reference")
    if not ref:
        return ""
    return fill(tmpls, "label", {"label": prefix + str(ref)}, where)


def addItms(itms, tmpls, where="items"):
    """Turn a list of content items into LaTeX, recursing into sections.
    Returns the items' LaTeX joined by blank lines."""
    out = []
    for i, itm in enumerate(itms or []):
        at = f"{where}[{i}]"
        if not isinstance(itm, dict) or "type" not in itm:
            raise DocError(f"{at}: every item needs a 'type'")
        typ = itm["type"]
        if typ in SECTION_CMDS:
            out.append(fill(tmpls, "section", {
                "cmd": SECTION_CMDS[typ],
                "title": need(itm, "value", at),
                "label": mkLabel(tmpls, "sec:", itm, at),
                "body": addItms(itm.get("items"), tmpls, at + ".items"),
            }, at))
        elif typ == "text":
            out.append(fill(tmpls, "text", {"value": str(need(itm, "value", at)).strip()}, at))
        elif typ == "equation":
            lines = "\n".join(str(l) for l in need(itm, "items", at))
            if itm.get("align"):
                lines = fill(tmpls, "equation_lines", {"lines": lines}, at)
            out.append(fill(tmpls, "equation", {
                "label": mkLabel(tmpls, "eq:", itm, at),
                "body": lines,
            }, at))
        elif typ == "figure":
            wide = itm.get("span", 1) == 2
            out.append(fill(tmpls, "figure", {
                "star": "*" if wide else "",
                "position": itm.get("position", "!t"),
                "width": itm.get("width", 1.0),
                "widthref": r"\textwidth" if wide else r"\columnwidth",
                "file": need(itm, "file", at),
                "caption": str(need(itm, "value", at)).strip(),
                "label": mkLabel(tmpls, "", itm, at),
            }, at))
        elif typ == "table":
            rows = need(itm, "rows", at)
            out.append(fill(tmpls, "table", {
                "star": "*" if itm.get("span", 1) == 2 else "",
                "position": itm.get("position", "!t"),
                "caption": str(need(itm, "value", at)).strip(),
                "label": mkLabel(tmpls, "", itm, at),
                "columns": need(itm, "columns", at),
                "header": " & ".join(str(c) for c in need(itm, "header", at)),
                "rows": "\n".join(fill(tmpls, "table_row",
                                       {"cells": " & ".join(str(c) for c in row)},
                                       f"{at}.rows[{j}]")
                                  for j, row in enumerate(rows)),
            }, at))
        elif typ in LIST_ENVS:
            entries = need(itm, "items", at)
            if typ == "dscrpts":
                body = [fill(tmpls, "dscrpt_item", {"title": need(e, "title", at),
                                                     "text": str(need(e, "text", at)).strip()}, at)
                        for e in entries]
                widest = max((str(e["title"]) for e in entries), key=len)
                out.append(fill(tmpls, "dscrpt_list", {"widest": widest,
                                                        "items": "\n".join(body)}, at))
            else:
                body = [fill(tmpls, "list_item", {"value": str(e).strip()}, at)
                        for e in entries]
                out.append(fill(tmpls, "list", {"env": LIST_ENVS[typ],
                                                 "items": "\n".join(body)}, at))
        elif typ == "raw":
            out.append(fill(tmpls, "raw", {"value": str(need(itm, "value", at)).strip()}, at))
        else:
            raise DocError(f"{at}: unknown item type '{typ}'")
    return "\n\n".join(out)


def applyMarkers(tex):
    for pat, rep in MARKERS:
        tex = pat.sub(rep, tex)
    return tex


def buildTex(doc, tmpls):
    """Everything up to the finished .tex string."""
    authors = []
    for k, a in enumerate(need(doc, "authors", "doc")):
        at = f"authors[{k}]"
        lines = list(a.get("affiliation", []))
        if a.get("email"):
            lines.append(a["email"])
        authors.append(fill(tmpls, "author_block", {
            "name": need(a, "name", at),
            "affiliation": " \\\\\n".join(lines),
        }, at))
    refs = doc.get("references") or []
    bib = ""
    if refs:
        items = "\n".join(fill(tmpls, "bibitem", {"key": need(r, "key", f"references[{k}]"),
                                                  "text": str(need(r, "text", f"references[{k}]")).strip()},
                               f"references[{k}]")
                          for k, r in enumerate(refs))
        bib = fill(tmpls, "bibliography", {"widest": "0" * len(str(len(refs))),
                                           "items": items}, "references")
    body = applyMarkers(addItms(need(doc, "items", "doc"), tmpls))
    bib = applyMarkers(bib)
    preamble = fill(tmpls, "preamble",
                    {"figures_dir": doc.get("figures_dir", "../../figures/")}, "preamble")
    return fill(tmpls, "document", {
        "class_options": doc.get("class_options", "conference"),
        "preamble": preamble.rstrip(),
        "title": need(doc, "title", "doc"),
        "authors": "\n\\and\n".join(authors),
        "abstract": str(need(doc, "abstract", "doc")).strip(),
        "keywords": ", ".join(need(doc, "keywords", "doc")),
        "body": body,
        "bibliography": bib,
    }, "document")


def runLatex(tex_path, max_passes=4):
    """pdflatex until the "Rerun" warnings stop. Returns the log text."""
    if shutil.which("pdflatex") is None:
        sys.exit("error: pdflatex not found on PATH")
    log = ""
    for _ in range(max_passes):
        r = subprocess.run(["pdflatex", "-interaction=nonstopmode", "-halt-on-error",
                            tex_path.name], cwd=tex_path.parent,
                           capture_output=True, text=True, errors="replace")
        log = tex_path.with_suffix(".log").read_text(errors="replace")
        if r.returncode != 0:
            err = [l for l in log.splitlines() if l.startswith("!")]
            tail = "\n".join(log.splitlines()[-25:])
            sys.exit(f"error: pdflatex failed on {tex_path}\n"
                     + ("\n".join(err[:5]) + "\n" if err else "") + tail)
        if "Rerun to get" not in log and "Label(s) may have changed" not in log:
            break
    return log


def report(doc, tex, log):
    """Print the build checks; returns the number of problems found."""
    problems = 0
    m = re.search(r"Output written on .*?\((\d+) pages?", log)
    pages = int(m.group(1)) if m else None
    limit = doc.get("page_limit")
    status = ""
    if pages is not None and limit:
        status = "  OK" if pages <= limit else f"  OVER the limit of {limit}"
        problems += pages > limit
    print(f"pages: {pages}{'' if limit else ' (no page_limit set)'}{status}")
    undef_ref = sorted(set(re.findall(r"Reference `([^']+)' on page", log)))
    undef_cit = sorted(set(re.findall(r"Citation `([^']+)' on page", log)))
    for kind, names in (("undefined references", undef_ref),
                        ("undefined citations", undef_cit)):
        if names:
            print(f"{kind}: {', '.join(names)}")
            problems += len(names)
    overfull = log.count("Overfull \\hbox")
    print(f"overfull hboxes: {overfull}")
    cited = set()
    for grp in re.findall(r"\\cite\{([^}]*)\}", tex):
        cited.update(k.strip() for k in grp.split(","))
    keys = {r["key"] for r in doc.get("references") or []}
    if keys - cited:
        print(f"references never cited: {', '.join(sorted(keys - cited))}")
        problems += len(keys - cited)
    if cited - keys:
        print(f"citations with no reference: {', '.join(sorted(cited - keys))}")
    return problems


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("content", help="content YAML file")
    ap.add_argument("--templates", default=str(DEFAULT_TEMPLATES),
                    help="templates YAML (default: tools/ieee_templates.yaml)")
    ap.add_argument("--out-dir", default=None,
                    help="where the .tex/.pdf go (default: build/ next to the content YAML)")
    ap.add_argument("--no-pdf", action="store_true", help="write the .tex only")
    args = ap.parse_args()

    content = Path(args.content).resolve()
    doc = yaml.safe_load(content.read_text(encoding="utf-8"))
    tmpls = yaml.safe_load(Path(args.templates).read_text(encoding="utf-8"))
    try:
        tex = buildTex(doc, tmpls)
    except DocError as e:
        sys.exit(f"error: {e}")

    out_dir = Path(args.out_dir).resolve() if args.out_dir else content.parent / "build"
    out_dir.mkdir(parents=True, exist_ok=True)
    tex_path = out_dir / f"{doc.get('value', content.stem)}.tex"
    tex_path.write_text(tex, encoding="utf-8")
    print(f"tex:  {tex_path}")
    if args.no_pdf:
        return
    log = runLatex(tex_path)
    print(f"pdf:  {tex_path.with_suffix('.pdf')}")
    report(doc, tex, log)


if __name__ == "__main__":
    main()
