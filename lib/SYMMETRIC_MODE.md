# Symmetric-mode pole placement

## The problem this solves

`place_poles.m` (the core Newton/modified-Remez pole-placement solver described in
Martin's paper, `doc/Approximation_of_complex_IIR_bandpass_filters_without_arithmetic
_symmetry.pdf`) treats every movable loss pole as a fully independent unknown. When
a filter spec (`p`, `px`, `wp`, `ws`, `as`) happens to be exactly mirror-symmetric
about dc — i.e. you actually want a conventional "real" filter, designed via this
complex-filter machinery as a special case — the solver still only converges to
*approximate* symmetry. For example, `examples/exmpl.m`'s spec converges to loss
poles at (physical frequencies) `-3.3334` and `+3.4349` — a ~3% mismatch, not
floating-point noise.

This happens because the solver's internal convergence tolerance (`1e-7`) is a fixed
absolute value in a transformed variable whose relationship to physical frequency is
highly non-uniform (very sensitive near the passband, very insensitive far from it).

The approximate symmetry then breaks downstream ladder-synthesis routines
(`rmv2XPoles.m`, `rmvl4.m`) that assume exact mirror pole pairs — they either fail
outright or silently rely on their own crude tolerance snaps.

**Symmetric mode fixes this at the root**: it guarantees exact (to floating-point
precision) mirror symmetry in the solved pole set, by construction, rather than
hoping the general-purpose solver happens to land close enough.

## How it works

The solver's real, transformed pole variable is `p' = sqrt((p-ω2)/(p-ω1))` (paper
eq. 12), where `ω1`/`ω2` are the lower/upper passband edges. For a mirror-symmetric
passband (`ω2 = -ω1`), a physical mirror pair `p ↔ -p` maps to a **reciprocal** pair
in this variable: `p'(-p) = 1/p'(p)` — not a sign flip. Since `Δ(1/x) = -Δx/x²`,
that reciprocal relationship is still linear in the Newton step's differentials, so
it folds cleanly into the existing linear solve with no new derivative math.

Symmetric mode exploits this by tracking only the "master" half of the movable
poles (those with `p' ∈ (0,1)`) as free variables. Every iteration, the "mirror"
half is reconstructed as the exact `1./p_master` — bit-exact, not
Newton-approximate — which is why the final result is symmetric to machine
precision rather than approximately.

## New files

All are additive; nothing about the existing (non-symmetric) solver was changed.

| File | Role |
|---|---|
| `place_poles_sym.m` | The reduced-size Newton solver — the symmetric-mode counterpart of `place_poles.m` |
| `get_poles_sym.m` | Extracts the master-half poles, validating the full set is reciprocal-paired |
| `make_Kz_sym.m` | Rebuilds the characteristic function from `[p_master, 1./p_master]` |
| `find_minima_sym.m` | Finds stopband minima, keeping only the master half |
| `dlogKK_dp_sym.m` | Builds the reduced Jacobian by folding each mirror pole's column into its master pole's column (chain rule) |

Each is a thin wrapper around the corresponding unchanged function
(`get_poles.m`/`make_Kz.m`/`find_minima.m`/`dlogKK_dp.m`) — no pole-placement math
was reimplemented from scratch.

## How to use it

Pass `true` as the new, optional 9th argument to `design_ctm_filt`:

```matlab
p = [-5 -3 -2 -1.6 1.6 2 3 5];
ni = 1;
wp = [-1 1];
ws = [-15 -1.2 1.2 15];
as = [60 40 40 60];
Ap = 0.025;
px = [];

% symmetric = true  ->  uses place_poles_sym instead of place_poles
[H, E, F, P] = design_ctm_filt(p, px, ni, wp, ws, as, Ap, 'elliptic', true);
```

Omitting the 9th argument (or passing `false`) is identical to calling
`design_ctm_filt` today — fully backward compatible.

`P` (and `E`, `F`, `H`) will now be exactly mirror-symmetric, which downstream
ladder synthesis (`rmv2XPoles`, `rmvl4`, etc.) requires for exact-pole-pair
extraction. See `examples/exmpl.m` for a full worked example of feeding the result
into ladder synthesis.

### Requirements for the spec

Symmetric mode validates its inputs up front and errors immediately (before any
iteration) if they aren't actually symmetric:

- `wp(2)` must equal `-wp(1)` (mirror-symmetric passband).
- `ws`/`as`, once sorted, must be palindromic about dc (`ws(i) == -ws(n+1-i)`,
  `as(i) == as(n+1-i)`).
- The initial guess `p` (and any fixed poles `px`, aside from poles at infinity
  specified via `ni`) must already be (at least approximately) mirror-paired.

A deliberately mismatched spec fails fast with a clear, descriptive error, e.g.:

```
place_poles_sym:asymmetricStopbandSpec
place_poles_sym requires as to be symmetric about dc (as(1)=60 ~= as(6)=61)
```

### A note on warnings

You may occasionally see a warning like:

```
find_minima_sym: minima 2 (0.434) and its mirror 7 (2.270) look grossly
non-reciprocal (product=0.986, expected 1). This may indicate the filter
spec is not exactly symmetric.
```

This is a **diagnostic, not a failure** — `find_minima`'s own numerical search
(fixed grid + limited Newton refinement) introduces real, sometimes several-percent
noise between independently-located master/mirror minima, even when the underlying
characteristic function is exactly symmetric by construction. It's normal to see
this during ordinary convergence and does not affect the correctness of the final
(exactly symmetric) result. The real protection against a genuinely mis-specified
(non-symmetric) spec is the up-front `wp`/`ws`/`as` and initial-pole-pairing checks
described above, which run before any iteration.

## Verification

Checked against `examples/exmpl.m`'s spec:

- Converges in a similar number of iterations to the non-symmetric solver (~40-50).
- Final symmetry error: ~`1e-16` (machine precision), vs. ~`0.10` for the
  non-symmetric solver on the same spec.
- Matches the non-symmetric solver's own result, averaged across its mirror pairs,
  to within its own inherent asymmetry error.
- Downstream ladder synthesis (`rmv2XPoles`/`rmvSCmplx`) succeeds and produces
  exactly symmetric ladder elements (identical capacitances with opposite-signed
  reactances in each mirror pair; exactly-zero, not residual, shunt susceptances).
- Existing non-symmetric examples are unaffected (all changes are additive).
