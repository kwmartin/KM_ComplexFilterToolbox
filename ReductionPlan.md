# Reducing CmplxFltrGrpDly from 11 pages to a 4-page conference version

Revised after first-round feedback (see "Revision notes" at the end for
exactly what changed and why).

## Context

`doc/ieee/CmplxFltrGrpDly_full.yaml` builds an 11-page IEEE paper. The
conference target, `doc/ieee/CmplxFltrGrpDly_conf.yaml` (not yet created),
has `page_limit: 4`. That is a 64% cut. The initial goal is 4.5 pages,
leaving a further, later round to reach 4.0 exactly.

This plan: (1) proposes a mechanism for doing the cuts that makes repeated
iteration cheap, (2) proposes not writing a brand-new companion document
but reusing the already-existing long version for that role, and (3) lists
concrete removal/compression candidates, each with a measured current size,
an estimated size reduction, and an assessment of how much the paper's
cohesion or explanatory power suffers — ordered from the best size/cohesion
trade to the worst.

## Measured current size

Word counts, and figure/table/equation counts, per subsection (from
`doc/ieee/CmplxFltrGrpDly_full.yaml`; a rough page-location cross-check
came from `pdftotext -layout` on the built PDF):

| Section | Words | Fig | Tab | Eq | ~PDF location |
|---|---|---|---|---|---|
| I.A Two Approaches (intro) | 586 | 0 | 0 | 0 | p.1 |
| I.B Prior Work | 712 | 0 | 0 | 0 | p.1–2 |
| II.A Method 1, Algorithm | 576 | 0 | 0 | 0 | p.2–3 |
| II.B Method 1, Alternatives | 497 | 0 | 0 | 0 | p.3 |
| III.A Method 2, Algorithm | 445 | 0 | 0 | 0 | p.3–4 |
| III.B Method 2, Alternatives | 662 | 0 | 0 | 0 | p.4 |
| IV.A Transform Details | 636 | 0 | 0 | 4 | p.4–5 |
| IV.B Where It Helps | 963 | 0 | 0 | 1 | p.5–6 |
| V.A Step-by-Step, Method 1 | 587 | 0 | 0 | 0 | p.6 |
| V.B Step-by-Step, Method 2 | 553 | 0 | 0 | 1 | p.6–7 |
| VI.A Best Examples, Method 1 | 571 | 2 | 1 | 0 | p.7–8 |
| VI.B Best Examples, Method 2 | 1517 | **6** | **2** | 0 | p.8–11 |

VI.B, with 6 figures and 2 tables, is by far the largest single block —
figures and tables cost fixed vertical space regardless of word count, so
this section's true page cost is understated by its word count alone.
References (15 entries) take under half a column and are not a cut target.

**A page count is a build result, not something to compute in advance.**
The estimates below are rough (calibrated against the page map above, not
exact), and are only a guide to sequencing. The real number comes from
running the build after each cut — see the mechanism below, which is
designed around exactly that loop.

## Mechanism for iterating

1. `cp doc/ieee/CmplxFltrGrpDly_full.yaml doc/ieee/CmplxFltrGrpDly_conf.yaml`,
   then in the copy: set `value: CmplxFltrGrpDly_conf`, add
   `page_limit: 4`. This is the working copy; `_full.yaml` is untouched
   and keeps building the 11-page version throughout.
2. Each cut is a deletion (or edit) of one or more YAML item blocks —
   `type: text`, `type: figure`, `type: table`, or a whole `type: subsctn`.
   The item-tree format makes this precise and mechanical: no prose
   rewriting is needed to remove a block, only to shorten what
   surrounds it.
3. After each cut: `tools/make_ieee_tex.py doc/ieee/CmplxFltrGrpDly_conf.yaml`.
   Its existing checks do most of the iteration work for free:
   - the page count, checked against `page_limit`;
   - **undefined references** — if a cut section is still referenced
     elsewhere (`Section~xxsec:...yy`, `Fig.~xx...yy`), the build reports
     it by location instead of silently producing a broken PDF;
   - references/citations that no longer match anything.
   This means a cut's ripple effects (a stray cross-reference, a figure
   pointer left dangling) surface immediately, not after eyeballing a
   rendered PDF.
4. Because `_conf.yaml` is a full copy rather than a diff or a generated
   artifact, an iteration that goes too far is trivial to walk back: keep
   the previous copy (`git diff`/a scratch backup) and restore a block
   rather than retyping it.
5. For the figure-layout change (below), keep the current per-panel
   MATLAB plotting calls easy to restore (e.g. commented out, not
   deleted) while the combined layout is tried, since that specific
   change is explicitly experimental and may need to be reverted.
6. Do the cuts in the order below, checking the page count after each,
   and stop as soon as the paper is at or under 4.5 pages. If the earlier,
   larger cuts overshoot (land well under 4.5), stop early and keep more
   material; if they undershoot, continue down the list.

## Where cut material goes: reuse the existing long version, don't write a new document

The instruction was to write a new companion document for material cut
from Sections II and III. **Recommendation: don't create a new document.**
`doc/CmplxFltrGrpDly.md` / `doc/ieee/CmplxFltrGrpDly_full.yaml` already
*is* a complete, maintained, 11-page version with every detail this plan
proposes cutting. Every planned cut is a subset of the full version's
content, verbatim. A new companion document would duplicate that content
in a third place — and given "we will be iterating on this paper a number
of times," a duplicate is something that has to be kept in sync by hand at
every future edit, which is exactly the kind of bookkeeping tax the
iteration mechanism above is trying to avoid.

Instead, word the conference paper's cut points as pointers to the
extended version, worded to match how it will actually be available at
each point in time:

- **Now (pre-conference):** "an extended version, including further
  alternatives investigated and a full step-by-step derivation, is
  available on request from the author."
- **After the conference:** "...is available at [library/publisher site]."

Both of these are just the wording of a footnote or parenthetical; no
placeholder URL is needed now, and the wording only needs to change once,
after acceptance.

**If a real standalone document is still wanted** — e.g. because a
technical-report-style write-up, distinct in tone from the long draft, is
useful on its own — the alternative is a new `doc/CmplxFltrGrpDlySupplement.md`
assembled from the cut sections, rendered with the existing
`tools/render_paper.py`. This is more work up front and creates the
duplication problem above, so it is listed as the fallback, not the
recommendation.

## Figure strategy for Section VI: one combined figure per example

This is the single biggest lever, and replaces separately deleting or
shrinking individual figures.

**The idea.** Every example in Section VI currently gets 2–3 separate,
full-column-width figures (magnitude; group delay before; group delay
after). Two changes combine to cut this down to **one combined figure per
example, at roughly the vertical cost of one of today's figures**:

1. **Overlay before/after group delay in one plot**, instead of two
   separate figures. `plotGdTwo`'s underlying engine (`plotTwo.m`) already
   supports multiple curves per axes set (`.y` as a matrix, one column per
   curve) — built for exactly this. Right now it distinguishes curves by
   **line style** (`.lineStyle`, default `{'-','--',':'}`); per your
   instruction, distinguish the before/after curves by **a different
   color** instead. If a secondary distinction is still wanted alongside
   color, a dash pattern is fine only if it reads as nearly solid — short
   dashes, little gap — not the current default long-dash/dot styles. This
   needs a small change to `plotTwo`/`plotGdTwo` (a per-curve color list
   next to the existing per-curve line-style list; the color list should
   probably default to keeping the existing red/blue zoom/full-band
   colors for the first curve and a clearly distinct color, e.g. a
   contrasting orange or green, for the second).
2. **Place the magnitude panel and the (now single) group-delay panel
   side by side in one figure**, each sized to roughly half of one
   column's width, rather than as two stacked full-width figures. This
   needs one new combined-layout helper (e.g. a `tiledlayout(1,2)`
   figure that reuses `plotMgTwo`'s and `plotGdTwo`'s axes-drawing logic
   for the two tiles) and a `savePaperFig` call sized for the combined
   figure (full column width, same height as one current panel, instead
   of each panel individually at full width).

Applied to every example in Section VI:

| Example | Today | After |
|---|---|---|
| Method 1 (`1_10_0`) | 2 figures (mag, gd) + Table I | 1 combined figure + Table I |
| Method 2, primary filter | 3 figures (mag, gd0, gd) + Table II | 1 combined figure (gd panel overlays before/after) + Table II (or a sentence, see below) |
| Method 2, wide-band filter | 3 figures (mag, gd0, gd) | 1 combined figure, made as small as reasonable (see below) |

- **Size:** the 8 figures currently in Section VI (2+3+3) collapse to 3,
  each costing about as much vertical space as one of today's figures.
  This is the largest single reduction in the plan — plausibly 2+ pages —
  while keeping every example and every curve that's on the page today.
- **Cohesion loss: low, if the combined layout reads well at the smaller
  size.** This is explicitly the experimental item: two panels at
  roughly half-column width each mean smaller axes, tick labels and
  legends than today's single-column figures. If it doesn't read clearly
  once built, the fallback is to keep the combined group-delay overlay
  (item 1 above, which has no size problem — it's the same width as
  today, just one plot instead of two) but drop back to full-width,
  separately-stacked mag/gd figures instead of the side-by-side layout.
- **The wide-band (second) example stays, per instruction, but as small
  as possible.** Beyond the combined-figure treatment above, the
  cluster-count table (Table II) or the wide-band example's own
  supporting prose are the places to cut further if it still needs to
  shrink — not the figure itself, which should stay since it's the
  concrete evidence for the generalization claim.

## Other removal candidates, ordered by size reduction vs. cohesion loss

### 1. Drop the Step-by-Step Reference (Section V) entirely

Both `V.A` and `V.B` restate, with full equations and library file
names, exactly the same six-step algorithms already given in prose in
`II.A`/`III.A`.

- **Size:** the biggest remaining lever after the figure work above.
  ~1140 words across two subsections with almost no figures; expect on
  the order of 1.3–1.5 pages back.
- **Cohesion loss: low, provided one or two equations move back.**
  `II.A`/`III.A` currently have zero equations between them — all of
  `V`'s four equations (the alternating-target deviation, the secant
  step, the anchor/weighted-deviation objective, the two Jacobian
  columns) are its only mathematical content in the whole paper outside
  Section IV. Folding the single most load-bearing equation from each of
  `V.A`/`V.B` (candidates: the least-squares Newton step, and the
  anchor-based objective, Eq. 18) into `II.A`/`III.A` keeps the paper from
  reading as equation-free in its own core sections, at a much smaller
  cost than keeping all of `V`. Without that backfill, a reader wanting
  to reproduce the method loses real precision — this is the risk to
  watch, not the section count.

### 2. Drop the "Alternatives Investigated" subsections (II.B, III.B)

The original example given for this exercise. Replace each with one or
two sentences noting that alternatives were tried and why the current
approach was chosen, pointing to the extended version.

- **Size:** ~1.2 pages combined (1159 words, no figures/tables — this
  section's word count is a reasonably direct proxy for its page cost,
  unlike the figure-heavy sections above).
- **Cohesion loss: low–moderate.** This is the "journey" — what was
  tried and rejected, and why. It is not needed to understand or
  reproduce the final method, and cutting it is completely standard for
  a conference page budget. The soft cost is that it currently
  demonstrates engineering rigor (dead ends explored, not just the
  answer); a reviewer who cares about that will find it in the extended
  version, but won't see it in the main text. A single sentence per
  subsection ("shrinking parameters directly and adjusting only the
  radius were both tried and found worse; see the extended version")
  keeps a trace of this without the detail.

### 3. Cut Section IV.B's scaling/cancellation discussion much further than a normal compress

Originally this plan proposed compressing `IV.B` to a short paragraph.
**Revised: cut it harder than that.** Since the paper's own recommended,
actually-used approach is the $x$-domain parametrization throughout (§III
and §V describe nothing else), a detailed *justification* of why the
$z$-domain parametrization fails — the badly-scaled-parameters problem
and the kernel-cancellation problem, currently a derivation with its own
equation (Eq. 15) and a digit-loss estimate — is arguably more than a
4-page paper needs to *use* the $x$-domain form; it only needs to explain
*why* to use it, briefly. Cut both discussions to one or two sentences
each, state the conclusion (the $z$-domain version collapses at narrow
bands; the $x$-domain form is exact and unaffected at any width), and
point to Table III (already in the results section) for the numbers, so
the numbers aren't given twice.

- **Size:** larger than the original "compress" estimate — expect
  963 words down to perhaps 100–150, close to a full page back.
- **Cohesion loss: moderate.** This removes the paper's one from-first-
  principles derivation (why cancellation happens, why the $x$-domain
  kernel structurally can't have it) — a genuinely nice piece of rigor,
  and the clearest "here is exactly the mechanism" content in the paper.
  What survives is the conclusion and its empirical support (via Table
  III), so the paper still tells the reader *what* to do and *that* it
  works; a reader wanting *why*, in full mathematical detail, needs the
  extended version. This is a bigger cohesion cost than the original
  plan took on for this item, in exchange for a bigger size win —
  appropriate given the paper's own emphasis is squarely on the
  $x$-domain result, not on refuting the $z$-domain one.

### 4. Compress Section I.B (Prior Work), don't remove it

- **Size:** small, maybe 0.2–0.3 page (tighten prose; the
  "Reproducibility" paragraph pointing at the toolbox's public
  availability is the easiest single paragraph to cut here).
- **Cohesion loss: low if trimmed carefully, high if removed outright.**
  A related-work section is expected by reviewers; a conference paper
  with none of it invites a rejection on "insufficient literature
  review" grounds unrelated to the actual technical content. Compress,
  do not delete.

### 5. Trim inline implementation file names from II.A/III.A

`MakePaper.md`'s own conventions already flag this: "implementation file
names... belong in one 'Implementation' paragraph or a footnote... not in
the running text." Several `lib/foo.m`-style mentions currently sit in
the main prose of `II.A`/`III.A`.

- **Size:** small (~100–150 words), not a major lever on its own.
- **Cohesion loss: none — this is a pure quality improvement.** A
  conference reader doesn't need MATLAB file names inline; collapsing
  them to one "Implementation" footnote or dropping them (with a pointer
  to the repository) reads better *and* saves a little space. Worth
  doing regardless of whether more page budget is needed.

## If the above isn't enough: reserve cuts for a later round

The estimates above are rough; if they don't add up to reaching 4.5 pages,
or if a later round is needed to reach the hard 4.0 limit, these are the
next candidates, roughly in order of increasing cost:

- Cut Table I (Method 1's 9-filter table) to 3–4 representative filters
  instead of all nine, with "results for all nine are in the extended
  version." Moderate size win, moderate-to-high cohesion loss — Table I
  is one of the paper's concrete headline results (the fix generalizes
  across order and spec), so this should be a later resort, not an early
  one.
- Compress Table II (Method 2 cluster-count table) to a single sentence
  with the final numbers, if not already done as part of shrinking the
  primary Method 2 example above.
- Tighten I.A (the two-approaches overview) prose itself. Small-to-moderate
  win, moderate risk — this is the paper's "elevator pitch"; cutting it
  too hard weakens the framing that makes II and III legible as a pair.

## Suggested order of execution

1. Create `CmplxFltrGrpDly_conf.yaml`, set `page_limit: 4`.
2. Build the combined-figure MATLAB helper and regenerate Section VI's
   figures (one combined figure per example, 3 total) — do this first
   since it's independent of the YAML cuts and is the largest, and most
   experimental, lever. Look at the PNGs before wiring them into the
   YAML; if the side-by-side layout doesn't read well at half-column
   width, fall back to the overlay-only version (full width, no
   side-by-side) before going further.
3. Update Section VI's YAML to the combined figures; compress Table II
   if the primary/wide-band examples still need to shrink. Build, check
   pages.
4. Item 1 (drop Section V, backfill 1–2 equations into II.A/III.A) —
   build, check pages.
5. Item 2 (drop II.B/III.B) — build, check pages.
6. Stop and reassess against 4.5 pages. Apply item 3 (cut IV.B hard),
   then items 4–5, only as needed to close the remaining gap.

Each step ends with a build-and-check, per the mechanism above, so the
order can be adjusted mid-stream if an early cut turns out to save more
(or less) than estimated.

## Revision notes

Changes made after review of the first draft of this plan:

1. **Figure overlays distinguish filters by color, not line style/dashes**
   (or, if a dash is still wanted alongside color, a short, tight dash —
   not the previous default of long dashes/dots).
2. **The wide-band (second) Method 2 example is kept**, not cut — reduced
   to the same minimal combined-figure form as the other examples instead
   of removed.
3. **New figure strategy**: every Section VI example gets exactly two
   plots — magnitude, and a single group-delay plot with before/after
   overlaid where applicable — sized to sit side by side within one
   column. This supersedes the original plan's separate "trim VI.B
   figures" and "combine before/after" items, folding both into one
   larger, explicitly experimental change (see the mechanism section for
   how to revert it if the smaller size doesn't read well).
4. **Section IV.B's scaling/cancellation discussion is cut much further**
   than a simple compress, since the paper's own used approach is the
   $x$-domain form throughout — only the conclusion and a pointer to
   Table III's numbers are kept, not the derivation.
5. **Extended-version wording changed**: "available on request from the
   author" now, "available at [library/publisher site]" after the
   conference — not a repository path.
