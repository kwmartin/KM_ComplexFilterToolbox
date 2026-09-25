#!/usr/bin/env python3
"""md2ieee_yaml.py - convert a Markdown paper draft (as written for
tools/render_paper.py) into a first version of the content YAML read by
tools/make_ieee_tex.py (see doc/make_tex_flow.md).

It is a one-time starting point: after conversion the YAML is the source
and is edited by hand (abstract, keywords, references, table captions,
anything the conversion got wrong).

What it converts:
  "# Title"                      -> title
  "## 2. Name" / "### 2.1 Name"  -> section / subsctn, labelled sec:s2 / sec:s2_1
  $$ ... \\tag{n} $$              -> equation, labelled eq:en (inside a list
                                    item: an inline equation environment)
  pipe tables                    -> table (caption left as TODO)
  ![caption](figures/name)       -> figure, labelled fig:name
  "1. ..." / "- ..." lists       -> enums / list
  other paragraphs               -> text
and, inline, IEEE style:
  "Eq. 3", "Eqs. 9/11"           -> zze3yy, zze9yy and zze11yy   (prints "(3)")
  "§4.2"                         -> Section~xxsec:s4_2yy
  "Figure 5", "Figures 1 and 2"  -> Fig.~xxfig:...yy, Figs.~...
  `code`, **bold**, *italic*, "quotes", %, &, #, _, em/en dashes -> LaTeX

Usage:
    tools/md2ieee_yaml.py draft.md out.yaml [--value NAME]
"""
import argparse
import re
from pathlib import Path

import yaml

HEAD = re.compile(r"^(#{1,3})\s+(?:(\d+(?:\.\d+)*)\.?\s+)?(.*\S)\s*$")
IMAGE_START = re.compile(r"^!\[")
IMAGE_FULL = re.compile(r"^!\[(.*)\]\(([^)]*)\)\s*$", re.S)
NUM_ITEM = re.compile(r"^(\d+)\.\s+(.*)$")
BULLET = re.compile(r"^-\s+(.*)$")
TAG = re.compile(r"\\tag\{(\d+)\}")


def escText(s):
    """Escape LaTeX specials in plain (non-math, non-code) text and apply
    the Markdown quote and dash conventions."""
    s = s.replace("\\", r"\textbackslash{}")
    for a, b in (("%", r"\%"), ("&", r"\&"), ("#", r"\#"), ("_", r"\_")):
        s = s.replace(a, b)
    s = s.replace("—", "---").replace("–", "--")
    s = re.sub(r'"([^"]*)"', r"``\1''", s)
    return s


def escCode(s):
    rep = {"\\": r"\textbackslash{}", "_": r"\_", "%": r"\%", "&": r"\&",
           "#": r"\#", "$": r"\$", "{": r"\{", "}": r"\}",
           "~": r"\textasciitilde{}", "^": r"\textasciicircum{}"}
    return r"\texttt{" + "".join(rep.get(c, c) for c in s) + "}"


class Converter:
    def __init__(self, lines):
        self.lines = lines
        self.figOrder = []          # figure labels in order of appearance

    def inline(self, s):
        """Markdown inline text -> LaTeX: code and maths are kept apart
        from the plain-text escaping."""
        # bold/italic may contain code or maths, so mark them before splitting
        s = re.sub(r"\*\*(.+?)\*\*", "\x01\\1\x02", s, flags=re.S)
        s = re.sub(r"(?<![*\w])\*(?!\s)(.+?)(?<!\s)\*(?![*\w])", "\x03\\1\x04", s, flags=re.S)
        parts = re.split(r"(`[^`]*`|\$[^$]+\$)", s)
        out = []
        for p in parts:
            if p.startswith("`") and p.endswith("`") and len(p) > 1:
                out.append(escCode(p[1:-1]))
            elif p.startswith("$") and p.endswith("$") and len(p) > 1:
                out.append(p)
            else:
                out.append(escText(p))
        s = "".join(out)
        for a, b in (("\x01", r"\textbf{"), ("\x02", "}"), ("\x03", r"\textit{"), ("\x04", "}")):
            s = s.replace(a, b)
        return self.refs(s)

    def refs(self, s):
        s = re.sub(r"Eqs\. (\d+)/(\d+)", r"zze\1yy and zze\2yy", s)
        s = re.sub(r"Eq\. (\d+)", r"zze\1yy", s)
        s = re.sub(r"§(\d+)\.(\d+)", r"Section~xxsec:s\1_\2yy", s)
        s = re.sub(r"§(\d+)", r"Section~xxsec:s\1yy", s)
        return s

    def figRefs(self, s):
        """Figure numbers -> labels; run after all figures are known."""
        lab = lambda n: f"xx{self.figOrder[int(n) - 1]}yy"
        s = re.sub(r"Figures (\d+) and (\d+)",
                   lambda m: f"Figs.~{lab(m[1])} and {lab(m[2])}", s)
        s = re.sub(r"Figures (\d+) to (\d+)",
                   lambda m: f"Figs.~{lab(m[1])} to {lab(m[2])}", s)
        s = re.sub(r"Figures (\d+)--(\d+)",
                   lambda m: f"Figs.~{lab(m[1])}--{lab(m[2])}", s)
        s = re.sub(r"Figure (\d+)", lambda m: f"Fig.~{lab(m[1])}", s)
        return s

    def equation(self, body_lines):
        body = "\n".join(l.strip() for l in body_lines).strip()
        m = TAG.search(body)
        ref = f"e{m.group(1)}" if m else None
        body = TAG.sub("", body).rstrip()
        return ref, body

    def run(self):
        doc = {"title": None, "items": []}
        stack = [(0, doc["items"])]         # (heading level, list to append to)
        L = self.lines
        i = 0
        while i < len(L):
            line = L[i]
            if not line.strip():
                i += 1
                continue
            m = HEAD.match(line)
            if m:
                level = len(m.group(1))
                num, name = m.group(2), self.inline(m.group(3))
                if level == 1:
                    doc["title"] = m.group(3)
                    i += 1
                    continue
                while stack[-1][0] >= level:
                    stack.pop()
                item = {"type": "section" if level == 2 else "subsctn",
                        "value": name, "items": []}
                if num:
                    item["reference"] = "s" + num.replace(".", "_")
                stack[-1][1].append(item)
                stack.append((level, item["items"]))
                i += 1
                continue
            target = stack[-1][1]
            if line.strip() == "$$":
                j = i + 1
                while L[j].strip() != "$$":
                    j += 1
                ref, body = self.equation(L[i + 1:j])
                eq = {"type": "equation", "items": body.split("\n")}
                if ref:
                    eq["reference"] = ref
                target.append(eq)
                i = j + 1
                continue
            if line.startswith("|"):
                rows = []
                while i < len(L) and L[i].startswith("|"):
                    rows.append([self.inline(c.strip()) for c in L[i].strip().strip("|").split("|")])
                    i += 1
                header, body = rows[0], [r for r in rows[2:]]
                target.append({"type": "table", "value": "TODO caption",
                               "reference": f"tab:t{sum(1 for x in self.allItems(doc) if x['type'] == 'table') + 1}",
                               "columns": " ".join(["l"] + ["c"] * (len(header) - 1)),
                               "header": header, "rows": body})
                continue
            if IMAGE_START.match(line):
                buf = [line]
                while not IMAGE_FULL.match(" ".join(buf)):
                    i += 1
                    buf.append(L[i])
                m = IMAGE_FULL.match(" ".join(buf))
                name = Path(m.group(2)).name
                label = f"fig:{name}"
                self.figOrder.append(label)
                target.append({"type": "figure", "value": self.inline(" ".join(m.group(1).split())),
                               "file": name, "reference": label})
                i += 1
                continue
            if NUM_ITEM.match(line) or BULLET.match(line):
                typ = "enums" if NUM_ITEM.match(line) else "list"
                items, i = self.listItems(i, typ)
                target.append({"type": typ, "items": items})
                continue
            buf = []
            while i < len(L) and L[i].strip() and not HEAD.match(L[i]) \
                    and L[i].strip() != "$$" and not L[i].startswith("|") \
                    and not IMAGE_START.match(L[i]):
                buf.append(L[i])
                i += 1
            target.append({"type": "text", "value": self.inline("\n".join(buf)) + "\n"})
        for itm in self.allItems(doc):
            for k in ("value",):
                if isinstance(itm.get(k), str):
                    itm[k] = self.figRefs(itm[k])
            if itm["type"] in ("enums", "list"):
                itm["items"] = [self.figRefs(t) for t in itm["items"]]
            if itm["type"] == "table":
                itm["rows"] = [[self.figRefs(c) for c in r] for r in itm["rows"]]
        return doc

    def listItems(self, i, typ):
        """One list: each item runs until the next item marker at column 0
        or a non-indented line after a blank line. Display maths inside an
        item becomes an inline equation environment."""
        L = self.lines
        pat = NUM_ITEM if typ == "enums" else BULLET
        items = []
        while i < len(L) and pat.match(L[i]):
            first = pat.match(L[i]).groups()[-1]
            chunks, para = [], [first]
            i += 1
            while i < len(L):
                ln = L[i]
                if pat.match(ln):
                    break
                if not ln.strip():
                    if i + 1 < len(L) and L[i + 1].startswith(" ") and L[i + 1].strip():
                        i += 1
                        continue
                    break
                if not ln.startswith(" "):
                    break
                if ln.strip() == "$$":
                    j = i + 1
                    while L[j].strip() != "$$":
                        j += 1
                    chunks.append(self.inline("\n".join(para)))
                    para = []
                    ref, body = self.equation(L[i + 1:j])
                    lab = f"\\label{{eq:{ref}}}" if ref else ""
                    chunks.append(f"\\begin{{equation}}{lab}\n{body}\n\\end{{equation}}")
                    i = j + 1
                    continue
                para.append(ln.strip())
                i += 1
            if para:
                chunks.append(self.inline("\n".join(para)))
            items.append("\n".join(c for c in chunks if c) + "\n")
            while i < len(L) and not L[i].strip() and i + 1 < len(L) and pat.match(L[i + 1]):
                i += 1
        return items, i

    def allItems(self, doc):
        def walk(itms):
            for it in itms:
                yield it
                if it.get("type") in ("section", "subsctn", "subsubsctn"):
                    yield from walk(it.get("items", []))
        return list(walk(doc["items"]))


def strRepr(dumper, s):
    style = "|" if "\n" in s else None
    return dumper.represent_scalar("tag:yaml.org,2002:str", s, style=style)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("markdown")
    ap.add_argument("out")
    ap.add_argument("--value", default=None, help="output name for the generated paper")
    args = ap.parse_args()
    md = Path(args.markdown)
    conv = Converter(md.read_text(encoding="utf-8").splitlines())
    body = conv.run()
    doc = {
        "type": "doc",
        "value": args.value or md.stem,
        "class_options": "conference",
        "figures_dir": "../../figures/",
        "title": body["title"],
        "authors": [{"name": "Kenneth Martin",
                     "affiliation": [r"\textit{Granite SemiCom Inc.}", "Toronto ON, Canada"],
                     "email": "martin@granitesemi.com"}],
        "abstract": "TODO abstract (plain text: no maths, symbols or citations)\n",
        "keywords": ["TODO"],
        "items": body["items"],
        "references": [],
    }
    yaml.add_representer(str, strRepr, Dumper=yaml.SafeDumper)
    text = yaml.safe_dump(doc, sort_keys=False, allow_unicode=True, width=10**6)
    Path(args.out).write_text(f"# Converted from {md} by tools/md2ieee_yaml.py; "
                              "edit this file from now on.\n" + text, encoding="utf-8")
    print(f"wrote {args.out}: {len(conv.allItems(body))} items, "
          f"{len(conv.figOrder)} figures")


if __name__ == "__main__":
    main()
