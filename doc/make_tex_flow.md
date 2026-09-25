# How the IEEE paper `.tex` is generated

This file explains the flow that turns a YAML description of a paper
into an IEEE conference `.tex` and PDF, so the same approach can be used
for future papers.

> **Status (2026-09-25):** implemented and in use.
> - `tools/make_ieee_tex.py` builds `tools/ieee_example.yaml` and the
>   full-length paper `doc/ieee/CmplxFltrGrpDly_full.yaml` (10 pages, with
>   no overfull lines or undefined references).
> - The shorter conference submission will be
>   `doc/ieee/CmplxFltrGrpDly_conf.yaml`, cut down from the full version.
>   Set `page_limit` in it.

## 1. The idea in one picture

```
content YAML ──┐
(what to say)   │   make_ieee_tex.py                         pdflatex
                ├──> load ─> addItms (walk the tree) ─> assemble ─> markers ─> .tex ────────> .pdf
templates YAML ─┘            one Template per item type   document    xx/zz/aa/bb/cc...yy     + checks
(how it looks)
```

- **Content** (words, maths, figures, tables, references) lives in a
  YAML file. It is written by hand and is specific to one paper.
- **Layout** (the IEEEtran preamble and how each kind of item is written
  in LaTeX) lives in a second YAML file of `string.Template` strings. It
  is shared by every paper.
- **Code** only walks the content tree and fills templates. It holds no
  words and no LaTeX layout of its own.

These are the two text-generation principles, in `~/.claude/CLAUDE.md`:

```python
from string import Template
setTmplt = lambda tmpl, dct : Template(tmpl).substitute(dct)
```

and content from YAML.

## 2. Where it came from

The design is the one used in
`/home/Dropbox/programming/Python/FastApi/remoteker_ca1/gnrtDoc.py`
(with `lib/pyLatexLib.py`). The pieces kept are:

- **The YAML item tree.** Each item has a `type`, a `value`, and
  optionally `items`, `reference`, `file` and `width`. It uses the same
  keys as `rhcDoc.yaml`.
- **The recursive `addItms` walk,** which turns each item into LaTeX
  according to its type.
- **The inline markers** `xx…yy`, `zz…yy`, `aa…yy` and `bb…yy` (from
  `~/bin/fixRef`). Here they are done in Python.
- **Two stages:** write the `.tex`, then run LaTeX, keeping the `.tex`.

What changed, and why:

- **PyLaTeX is gone.** Its document class added page geometry, fonts and
  headers that IEEEtran must control itself. Its automatic escaping also
  fights a paper whose text is mostly maths.
- **Each item type is a `string.Template`** in a YAML file, not a
  Python object. This gives exact control of the LaTeX.
- **Text is raw LaTeX.** `$\tau(\omega)$`, `\eqref`, `\cite` and
  `\footnote` can be written directly. The markers are a convenience,
  not a necessity.

## 3. Files

| File | What it holds | Written by | In git |
|---|---|---|---|
| `tools/make_ieee_tex.py` | the generator code | once | yes |
| `tools/ieee_templates.yaml` | preamble, document skeleton, one template per item type | once, rarely changed | yes |
| `tools/ieee_example.yaml` | a small example paper using every item type (builds into `tools/build/`) | once | yes |
| `tools/md2ieee_yaml.py` | one-time converter: Markdown draft to a first content YAML (section 11) | once | yes |
| `doc/ieee/<paper>.yaml` | the paper's content, for example `CmplxFltrGrpDly_full.yaml` (long version) and `CmplxFltrGrpDly_conf.yaml` (submission) | per paper | **no** (private until the conference) |
| `doc/ieee/build/` | generated `.tex`, `.pdf`, `.log` | the generator | no |
| `doc/figures/` | figure PDFs from `examples/paper_figs_scld.m` | MATLAB | no |

## 4. The content YAML

```yaml
type: doc
value: CmplxFltrGrpDly_full        # output name: build/CmplxFltrGrpDly_full.tex/.pdf
class_options: conference
page_limit: 4                      # checked after the build
figures_dir: ../../figures/        # relative to doc/ieee/build/; becomes \graphicspath
title: "Group-Delay Equalization of Complex IIR Filters"
authors:
- name: Kenneth Martin
  affiliation: ['\textit{Granite SemiCom Inc.}', 'Toronto ON, Canada']
  email: martin@granitesemi.com
abstract: |
  Plain text only: no maths, symbols or citations (IEEE rule).
keywords: [complex filters, group delay, all-pass equalizers]
items:                              # the body, in order (section 5)
- type: section
  value: Introduction
  reference: intro                  # -> \label{sec:intro}
  items:
  - type: text
    value: |
      Complex filters ... as shown in Fig.~xxfig_m1_gdyy and zztau_jyy,
      following ccmartin2005yy.
references:                         # the bibliography, in this order
- key: martin2005
  text: 'K. Martin, ``Approximation of complex IIR bandpass filters ...,'''' \textit{IEEE Trans. Circuits Syst. I}, vol. 52, no. 4, pp. 794--803, Apr. 2005.'
```

YAML tips:

- Use `|` block scalars for paragraphs, so backslashes and `$` need no
  escaping.
- Put single-line LaTeX in single quotes (`'\textit{...}'`). Inside
  single quotes a backslash is literal.
- A blank line inside a `text` block starts a new LaTeX paragraph, as
  usual.

## 5. Item types

| `type` | Keys | LaTeX produced |
|---|---|---|
| `section`, `subsctn`, `subsubsctn` | `value` (title), `reference`, `items` | `\section{}` etc., `\label{sec:ref}`, then the nested items |
| `text` | `value` | the paragraph as written (raw LaTeX, markers allowed) |
| `equation` | `reference`, `items` (lines), `align: true` for several lines aligned at `&` | `equation` with `\label{eq:ref}`; with `align: true` the lines go in an `aligned` block, so they share **one** number |
| `figure` | `value` (caption), `file`, `reference`, `width` (fraction of `\columnwidth`, default 1.0), `position` (default `!t`), `span: 2` | `figure` (or `figure*`), `\centering`, `\includegraphics`, caption *below*, `\label{ref}` |
| `table` | `value` (caption), `reference`, `columns` (for example `l c c`), `header`, `rows`, `position` | `table`, caption *above*, `tabular` with rules, `\label{ref}` |
| `list`, `enums`, `dscrpts` | `items` (`dscrpts`: `title`, `text`) | `itemize`, `enumerate`, `description` (label width set to the longest title with `\IEEEsetlabelwidth`, which IEEEtran needs) |
| `raw` | `value` | copied verbatim (for example `\IEEEtriggeratref{8}`, `\vspace{-2pt}`) |

An item with an unknown `type` stops the build with a message that names
the item.

**Adding a new item type:** add a template to `ieee_templates.yaml`, then
add a branch in `addItms` that builds the dictionary for that template.
Nothing else changes.

## 6. Markers

These are applied to the whole `.tex` after assembly, non-greedily:

| Write | Becomes | Use for |
|---|---|---|
| `xxlabelyy` | `\ref{label}` | figures, tables (`Fig.~xxfig_m1_gdyy`), sections (`xxsec:introyy`) |
| `zznameyy` | `\eqref{eq:name}` | equations. IEEE style is "(3)", never "Eq. 3" |
| `aatextyy` | `\textit{text}` | emphasis |
| `bbtextyy` | `\textbf{text}` | bold |
| `cckeyyy` | `\cite{key}` | citations. Several keys: `cca,b,cyy` |

Raw LaTeX works just as well (`\ref{...}`, `\cite{...}`). The markers
only save typing and keep the YAML readable. Two rules keep them from
misfiring:

- **A marker must not follow a letter.** The `cc` in "accuracy" and the
  `bb` in "abbreviation" are left alone. Write `Fig.~xxfig:ayy`, not
  `Figxxfig:ayy`.
- **`xx`, `zz` and `cc` contents have no spaces.** Labels, equation names
  and citation keys never do. `aa` and `bb` may contain spaces.

## 7. The templates YAML

Each entry is a `string.Template`. `$name` and `${name}` are filled from
the dictionary the code builds for that item. For example:

```yaml
figure: |
  \begin{figure${star}}[${position}]
  \centering
  \includegraphics[width=${width}\columnwidth]{${file}}
  \caption{${caption}}
  \label{${reference}}
  \end{figure${star}}
```

Rules:

- **A literal `$` in a template must be written `$$`.** Maths belongs in
  the content YAML, where it needs nothing special, because substituted
  values are not scanned again.
- **Use `substitute`, not `safe_substitute`,** so a template field with
  no value fails loudly instead of leaving `${width}` in the `.tex`.
- **The `preamble` entry is the IEEEtran preamble** copied from
  `/home/Dropbox/doc/Papers/IEEE/TransformedVariables/ComplexFilters_TrnsfrmdVariables.tex`,
  with three additions:
  - `\usepackage{cite}`, which sorts and compresses citations, as the
    IEEEtran HOWTO recommends;
  - `\usepackage{url}`, so long `\url{}`s break across lines;
  - `\graphicspath`, filled from `figures_dir`.
- **Error messages name the location.** A missing template field, a
  missing key or an unknown item type stops the build with the item's
  position, for example `items[2].items[1] (figure): missing 'file'`.

## 8. The code, step by step (`make_ieee_tex.py`)

1. **Load** the content YAML and the templates YAML (`yaml.safe_load`).
2. **Front matter:** build the author blocks (joined with `\and`), the
   keyword line and the `\bibitem` list, each with `setTmplt`.
3. **Body:** `addItms(items)` walks the tree. For each item it builds a
   dictionary and returns `setTmplt(tmpls[type], dct)`. Sections recurse
   into their `items`, and the results are joined with blank lines.
4. **Assemble** the whole file from the `document` template.
5. **Markers:** apply the substitutions in section 6.
6. **Write** `build/<value>.tex`, then run `pdflatex` twice, so
   references and citations resolve.
7. **Check and report:**
   - pages against `page_limit`;
   - undefined references and citations;
   - overfull boxes (lines that stick out into the margin);
   - references never cited, and citations with no reference.

Run it with:

```
tools/make_ieee_tex.py doc/ieee/CmplxFltrGrpDly_full.yaml   # -> doc/ieee/build/CmplxFltrGrpDly_full.pdf
tools/make_ieee_tex.py tools/ieee_example.yaml --no-pdf     # .tex only
evince doc/ieee/build/CmplxFltrGrpDly_full.pdf
```

It needs only the standard library and PyYAML, so it runs from the system
`python3`. IEEEtran comes from the `texlive-publishers` package.

## 9. Starting a new paper

1. Copy `tools/ieee_example.yaml` to `doc/ieee/<new>.yaml`. `doc/` is
   ignored by git, so it stays private.
2. Fill in `value`, `title`, `authors`, `abstract`, `keywords`,
   `page_limit` and `figures_dir`.
3. Write the body as items, and put the references at the end. Reuse
   earlier bibliography entries by copying them. The Transformed
   Variables and ISCAS 2020 papers already hold the common ones.
4. Make the figures one column wide (3.5 in) as vector PDFs. In this
   repo `savePaperFig` does that.
5. Run the generator and read its report. Fix undefined references
   first, then trim to the page limit.
6. Look at the PDF (`evince doc/ieee/build/<new>.pdf`).

## 10. IEEE rules the templates and checks follow

From the IEEEtran HOWTO (`/home/Dropbox/doc/Papers/IEEE/IEEEtran_HOWTO.pdf`):

- **Conference mode:** `\documentclass[conference]{IEEEtran}`. Don't
  change the margins, fonts or line spacing; IEEEtran sets them.
- **Title, abstract and keywords:** no maths, symbols or citations.
- **Equations:** refer to them as "(3)" with `\eqref`, not as "equation
  3" or "Eq. 3".
- **Figures:** "Fig.~3" in the text, `\centering`, caption below, top
  placement `[!t]` preferred, and not in the first column of the first
  page. Use vector PDF.
- **Tables:** caption above the table.
- **Citations:** one `\cite{a,b}` with several keys; `cite` sorts and
  compresses them.
- **Last page:** balance the columns with `\IEEEtriggeratref{n}` (a
  `raw` item placed before the bibliography).

## 11. Starting from a Markdown draft

If the paper was drafted in Markdown (as `doc/CmplxFltrGrpDly.md` was, for
`tools/render_paper.py`), `tools/md2ieee_yaml.py` writes a first content
YAML:

```
tools/md2ieee_yaml.py doc/CmplxFltrGrpDly.md doc/ieee/CmplxFltrGrpDly_full.yaml --value CmplxFltrGrpDly_full
```

**What it converts:**

| Markdown | Becomes |
|---|---|
| headings | sections, labelled `sec:s2`, `sec:s2_1`, ... |
| `$$ ... \tag{n} $$` | equations labelled `eq:en` (inside list items, inline `equation` environments) |
| pipe tables | tables (caption left as `TODO`) |
| images | figures labelled `fig:<file>` |
| numbered and bulleted lists | `enums` and `list` |
| `Eq. 3` | `zze3yy` |
| `§4.2` | `Section~xxsec:s4_2yy` |
| `Figure 5` | `Fig.~xx...yy` |
| `code` | `\texttt{}` |
| `**bold**` and `*italic*` | `\textbf{}` and `\textit{}` |
| `%`, `&`, `#`, `_` | escaped |
| straight quotes | TeX quotes |

**What it cannot know, which you then fill in by hand:**

- the abstract and keywords;
- the references, and citations (`cc...yy`) in the text;
- table captions and meaningful table labels, with `Table~xx...yy` in the
  text;
- display equations too wide for one column. The build reports them as
  overfull hboxes; split them with `align: true` or an `aligned` block.

**After that the YAML is the source.** Don't re-run the converter over it,
or the hand edits are lost.

## 12. The same flow for other documents: `References.pdf`

`doc/References.pdf` is a public list of the documents used in developing
the toolbox that can't be redistributed (they are kept locally in
`../docs`). It is built the same way as the paper, with a smaller
generator:

| File | Role |
|---|---|
| `doc/References.yaml` | the content: topic groups; each entry has `key`, `cite`, optional `doi`/`url`, `file` (the local copy, not printed) and `note`. It also has `in_repository` (documents in `doc/` that can be shared) and `not_listed` (documents deliberately left out, with the reason) |
| `tools/references_templates.yaml` | article-class layouts: `document`, `group`, `entry`, `doi_link`, `url_link`, `repo_entry` |
| `tools/make_references.py` | loads both YAMLs, fills one template per entry and group, runs pdflatex in `tools/build/references/`, and copies the PDF to `doc/References.pdf`. It reuses `fill`, `need` and `runLatex` from `make_ieee_tex.py` |

**To add a reference:**

1. Put the document in `../docs`.
2. Add an entry to the right group in `doc/References.yaml`. Mark anything
   that can't be confirmed from the document itself as *to be confirmed*.
3. Run `tools/make_references.py`.
4. Commit the YAML and the PDF. Both have `.gitignore` exceptions.

An entry's `key` can be reused as the `\cite` key in a paper's YAML, so a
paper's `references:` list can be copied from this file.
