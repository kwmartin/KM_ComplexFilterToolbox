# Scaled-variable group-delay work (`_scld` files)

Started 2026-09-24. **Every change for this work is in new files.** No existing
file in `lib/` or `examples/` was modified. Where an existing function needed a
change, it was copied under a new name ending in `_scld`, and each of its callers
up to the example scripts was copied too.

## 1. Background: the transform in the paper vs. `z2y` in `lib/`

In `doc/ComplexFilters_TrnsfrmdVariables.pdf`, eq. (8) is

    y^2 = R(z),   R(z) = [2(z-1) - j w2 (z+1)] / [2(z-1) - j w1 (z+1)]

and eq. (9) is its inverse. Here wi = 2 tan(wpi/2) are the prewarped passband
edges. Eq. (8) is eq. (6) of the 2005 TCAS-I paper, s'^2 = (s - j w2)/(s - j w1),
with the bilinear substitution s = 2(z-1)/(z+1) applied.

The `z2y` anonymous functions in `lib/` compute **x = ±j R(z)**. That is linear in
the paper's y^2, so there is no square root and no order doubling. The factor j
rotates the unit circle onto the imaginary axis. There are two sign conventions,
and each has a matching inverse:
- **+j** (`make_initHyLP`, `place_polesdLP*`, `z2xSb`/`y2zSb`) maps |z| < 1 to the
  left half-plane.
- **-j** (`z2x`/`y2z`, used by `z2yTrnsfrm*`) maps |z| < 1 to the right half-plane.

**Group delay in `AnlzDH`.** `derivSum` = z H'(z)/H(z) on z = e^{jw}. The group
delay can be written in three equivalent ways:

    gd = -Re(derivSum)
       = -1/2 [D(z) + Dbar(1/z)]      z domain
       = -1/2 [G(s) + Gbar(-s)]       s domain, G = H'/H

Dbar and Gbar are D and G with every coefficient conjugated.

## 2. Band-centred Möbius transform (`lib/z2xc.m`, `lib/xc2z.m`)

The band of interest is fb = [f1 f2] in cycles, with w0 = pi(f1 + f2) and
t = tan(pi(f2 - f1)/2).

    x = (1/t)(z e^{-jw0} - 1)/(z e^{-jw0} + 1)      (z2xc)
    z = e^{jw0}(1 + t x)/(1 - t x)                  (xc2z)

Where points land:
- The unit circle maps to x = jW, with W = tan((w - w0)/2)/t. The band maps to
  W in [-1, 1].
- z = -e^{jw0} maps to x = infinity, and z = infinity maps to x = 1/t.
- |z| < 1 maps to the left half-plane, so stability is preserved.
- Reflection in the unit circle becomes reflection in the imaginary axis, so an
  all-pass in z stays an all-pass in x with the same order.

**Group delay is not equal at corresponding points.** The chain rule gives

    gd_z(w) = gd_x(W) * J,   J = dW/dw = (1 + t^2 W^2)/(2t)

`gd_x` comes from `AnlzH(Hx, W)`. No stretching map preserves group delay point
by point; only magnitude and phase are preserved. J does not depend on the
poles, so the sensitivities satisfy d gd_z/d x_p = J * d gd_x/d x_p.

**Exact gain, with no fitting against `rspsd`.**
- Forward: each factor (z - a) becomes -(e^{jw0} + a)(x - x_a)/(x - 1/t).
- Inverse: each factor (x - b) becomes (1 - t b)(z - z_b)/(t(z + e^{jw0})).

**Edge cases handled in the code:**
- More poles than zeros. The excess zeros at z = infinity become zeros at
  x = 1/t, and the inverse drops them again.
- More zeros than poles. These become poles at x = 1/t, and correspondingly at
  -e^{jw0} on the way back.
- A root at exactly z = -e^{jw0}, within a tolerance of 1e-12. It maps to
  x = infinity: the root is dropped and its constant -2e^{jw0}/t is folded into
  the gain.
- A root at exactly x = 1/t. It maps to z = infinity and is handled the same
  way.

**Checks.**
- `examples/chk_z2xc_edges.m`:

  | case | roots/gain | round trip | H(z)=H(x) | GD identity |
  |---|---|---|---|---|
  | np > nz | 4.7e-16 | 7.1e-15 | 7.7e-15 | 4.4e-15 |
  | nz > np | 3.5e-16 | 5.8e-15 | 1.3e-14 | 3.9e-15 |
  | zero at -e^{jw0} | 2.2e-16 | 5.8e-15 | 3.6e-14 | 7.1e-13 |
  | pole at -e^{jw0} | 1.7e-16 | 5.6e-15 | 2.5e-14 | 3.8e-13 |
  | all-pass | 4.7e-16 | 1.7e-14 | 1.8e-14 | 2.8e-15 |

  The all-pass section stays all-pass in x: the zeros equal -conj(poles) to
  3.8e-15, and max Re(pole) = -0.969.
  The pole-at-infinity case skips frequencies within 1e-6 of the unit-circle
  pole, because H is infinite there. Roots are compared by nearest-neighbour
  matching, which needs no ordering. MATLAB's `sort()` orders complex values
  by magnitude first, so roots whose designed magnitudes are equal are
  ordered by rounding noise after a round trip. Where an ordered list is
  needed, use the toolbox helpers instead:
  - `sortRootsD` (by angle) for z-domain roots. A root on the negative real
    axis, such as z = -1, can come out at +pi or -pi, so it may land at either
    end of the list.
  - `sortRoots` or `sortImag` (by imaginary part) for x-domain roots, where
    the imaginary part plays the role of frequency.
- `examples/chk_z2xc_1_6_0.m` uses the real `dig_linPh_1_6_0` filter at the input
  to `adaptP3` (H3, wp3 = [-0.005 0.005]). The round trip is 7.4e-12 and the GD
  identity 1.3e-15. This filter has a zero at z = -1 = -e^{jw0}, so the
  x = infinity path is exercised on real data.

**Conditioning result (negative).** The check compares the Newton sensitivity
matrix (`plSens` layout) at the 9 group-delay extrema in z and in x:
- Minimum pole spacing grows about 1000x (0.0009 to 0.945).
- `cond` does not improve enough to justify an x-domain Newton loop:
  - raw: 2.0e5 in z, 5.4e6 in x;
  - columns normalized, without the constraint row: 2.2e4 in z, 7.7e3 in x,
    only about 3x better.
- `plSens`'s mirror-constraint row is a z-domain assumption and does not carry
  over to x.
- Near the band the map is almost a uniform scaling and rotation, so the
  conditioning of the equiripple fit is essentially unchanged. An x-domain
  `adaptP3` was therefore **not** built.

## 3. Why the GD stage was reverted in `dig_linPh_*` (FixadaptP3.md Open Item 6)

There are two independent causes.

### 3a. `fndZeroCrs3` returns the Nyquist extremum

After the ±pi fix, the search window keeps widening until it reaches ±pi. It then
also returns the group-delay extremum at w = ±pi, which is opposite the passband.
That point is reported twice (once at each end of the window) and its group delay
is tiny (0.05–0.19, against 5–57 in the band). Consequences:
- `dsgnEquiRplGD`'s ripple measure reads 140–184%.
- `adaptP3` receives more than the 2Np-1 extrema its Newton system expects, so
  both the reduced and the standard system fail with "only found N extrema".

Without the Nyquist entries, the counts are exactly 2Np-1 in every case.

**Fix, in `lib/fndZeroCrs3_scld.m`:** drop extrema with |w| >= pi - 1e-3. A
tolerance of 1e-6 is too tight, because wz is interpolated between grid points.

### 3b. `LinPh_LssPls` returns a collapsed prototype for order ≥ 7

The loop rescales the `LinPhFltr` ripple request by deltT/deltT1. These are two
different quantities: `LinPhFltr`'s deltT, and the peak-to-peak ripple
`fnd_gd_ripple` measures on the scaled prototype. With deltGD = 0.25:

| n | iteration: deltT0 → measured ripple, max \|p\| |
|---|---|
| 3 | 0.25 → 0.122, 2.1; 0.51 → 0.201, 2.4; 0.63 → 0.223, 2.5 |
| 5 | 0.25 → 0.082, 3.1; 0.77 → 0.202, 3.6; 0.95 → 0.232, 3.8 |
| 7 | 0.25 → 0.061, 4.2; 1.03 → 0.207, 4.8; **1.24 → collapsed, 300.7** |
| 9 | 0.25 → 0.048, 5.3; **1.30 → collapsed, 283.6** |

Above a request of about 1.2, `fsolve` returns a solution with four poles near
s = -300. It passes the residual check, but its group delay is monotonic rather
than equiripple. The loop keeps the last iteration. This is also what made
`dig_linPh_1_8_0` look like a "two-cluster" pole structure.

**Fix, in `lib/LinPh_LssPls_scld.m`:**
- Reject a prototype whose largest pole magnitude exceeds 5x that of the first
  iteration, and stop the loop.
- Return the valid iteration whose measured ripple is closest to deltT.

## 4. The `_scld` call chain

| New file | Copied from | Change |
|---|---|---|
| `lib/fndZeroCrs3_scld.m` | `fndZeroCrs3.m` | drop the Nyquist extremum (3a) |
| `lib/adaptP3_scld.m` | `adaptP3.m` | calls `fndZeroCrs3_scld` |
| `lib/LinPh_LssPls_scld.m` | `LinPh_LssPls.m` | collapse guard, keeps best iteration (3b) |
| `lib/dsgnEquiRplGD_scld.m` | `dsgnEquiRplGD.m` | calls the three copies above |
| `lib/dsgnDigitalFltr_scld.m` | `dsgnDigitalFltr.m` | calls `dsgnEquiRplGD_scld` |
| `lib/dsgnDigitalFltr2_scld.m` | `dsgnDigitalFltr2.m` | calls `dsgnEquiRplGD_scld` |
| `examples/dig_linPh_{0_2_0,1_2_0,1_4_0,1_6_0,1_8_0}_scld.m` | the originals | call the `_scld` design functions |

## 5. Results

All 11 `dig_linPh_*` scripts (originals and copies) run cleanly with
`tools/run_all_examples.sh 300 'dig_linPh_*.m'`.

The table measures the final H over the passband with 2001 points, and over the
stopbands with 8000 points. `examples/cmp_linPh_scld.m` reproduces it; it takes
about 3 minutes, so the default per-example timeout of
`tools/run_all_examples.sh` was raised from 120 s to 300 s.

| Example | GD ripple orig → `_scld` | passband loss dB | min stopband loss dB |
|---|---|---|---|
| 0_2_0 | 13.49% → **2.14%** | 3.01 → 3.31 | 14.5 → 15.6 |
| 1_2_0 | 16.18% → **2.46%** | 2.00 → 1.55 | 5.6 → 5.9 |
| 1_4_0 | 16.18% → **2.46%** | 2.00 → 1.55 | 5.9 → 6.2 |
| 1_6_0 | 26.92% → **0.47%** | 2.00 → 1.62 | 22.2 → 65.9 |
| 1_8_0 | 20.40% → **2.40%** | 2.00 → 2.00 | 45.1 → 75.0 |

How each example got there:
- **0_2_0, 1_2_0, 1_4_0:** the fix in 3a alone is enough, and `adaptP3_scld`'s
  reduced Newton system succeeds.
- **1_6_0:** the collapse is caught at iteration 3 and iteration 2 is kept. The
  reduced system still fails, but the standard system converges.
- **1_8_0:** the collapse is caught at iteration 2. With a valid prototype the
  ripple before `adaptP3` is 3.01%, below the 10% skip threshold, so `adaptP3` is
  not run.

## 6. Open items

1. **Passband loss drifts from the spec** when `adaptP3_scld` moves the poles:
   1.55–1.62 dB against Ap = 2.0 dB, and 3.31 dB against 3.01 dB.
   - **This was already the case with the original code**; the `_scld` changes
     only made it visible. `dig_linPh_1_2_0b` runs the unchanged path and
     `adaptP3`'s reduced system succeeds there. Its passband-edge loss is
     3.31 dB against Ap = 3.0103 dB (measured over `wp` with 4001 points,
     relative to the in-band peak).
   - The other `dig_linPh` originals hit Ap exactly only because their
     `adaptP3` step was being reverted, which kept the prototype poles.
   - Likely cause, not yet traced line by line: the Ap edge is set only on
     the continuous-time prototype (`fndApFrq` and `scaleFltr` in
     `LinPh_LssPls`). After `adaptP3`, `dsgnEquiRplGD` only renormalizes the
     gain at DC (`H2.k = H2.k/abs(freqresp(H2,0))`). Nothing puts the Ap edge
     back at `wp`.
   - Also recorded in `Progress.md` (open item 7).
2. **Stopband loss on 1_2_0 and 1_4_0 is about 6 dB against the 20 dB spec**,
   before and after this change. This belongs to `place_polesdLP3` and was not
   investigated.
3. **`dsgnEquiRplGD`'s 10% skip threshold compares the absolute ripple level**
   with a threshold. It does not measure how far the response is from
   equiripple, so a correctly equiripple design with 12% ripple still goes
   through `adaptP3`.
4. **The collapse guard avoids the infeasible request instead of fixing it.**
   deltGD = 0.25 is hard-coded in `dsgnDigitalFltr` and cannot be reached at
   n ≥ 7. The real fix would be to make the `LinPhFltr` deltT and the
   `fnd_gd_ripple` measure consistent.
5. **The `adaptP3_scld` reduced Newton system still fails on 1_6_0** ("structure
   changed, found 5 maxima, need 7"). The standard system covers it.
6. **The other callers of the unchanged originals are not covered by `_scld`
   copies:** `adaptP2`, which is used by the `equiGD` type and `equiGdDigital`,
   and `dsgnCascadeFltr`, which calls `LinPh_LssPls` directly.

## 7. Does the transformed variable help? Narrow-band test

**Question.** Is there a design where using the transformed variable works
and the unscaled z-domain code fails, or where it at least improves the result?

**Chain.** New files only:

| New file | Copied from | Change |
|---|---|---|
| `lib/fndZeroCrsX_scld.m` | new | finds group-delay extrema in x (see below) |
| `lib/adaptP3X_scld.m` | `adaptP3_scld.m` | calls `fndZeroCrsX_scld` |
| `lib/dsgnEquiRplGDX_scld.m` | `dsgnEquiRplGD_scld.m` | calls `fndZeroCrsX_scld` and `adaptP3X_scld` |
| `lib/dsgnDigitalFltrX_scld.m` | `dsgnDigitalFltr_scld.m` | calls `dsgnEquiRplGDX_scld` |
| `examples/shrink_band_scld.m` | new | the test below |

**How `fndZeroCrsX_scld` works.**
- It maps H to x with `z2xc` over wp. The z-domain group delay is J·gd_x, and
  W increases with w, so the extrema in w are the zeros of
  d(J·gd_x)/dW = t·W·gd_x + J·dgd_x/dW. Both gd_x and dgd_x/dW come from
  `AnlzH`.
- It finds sign changes on a grid of 40001 points uniform in W, refines them by
  linear interpolation, and maps back with w = w0 + 2·atan(t·W).
- The search window is the same as `fndZeroCrs3`'s: the passband widened by
  marginMult passband widths on each side, doubled while an extremum lies near
  the edge. It stops 1e-3 rad short of Nyquist.
- **It snaps transmission zeros onto the axis.** Zeros with
  |Re(x)| < 1e-8·max(1, |x|) are set to Re = 0. Rounding in z leaves the
  stopband transmission zeros off the unit circle, by about eps/t in x
  (1e-14 to 1e-11 for bands 1e-3 to 1e-5 cycles wide). That puts spikes in the
  group delay and gives spurious extrema; the ±3.78 and ±5.82 half-width
  entries appeared at widths of 1e-5 and below before this was added.

**Two bugs found while writing it:**
- `W(indc)` is a row and `dT(indc)` a column, so implicit expansion made the
  interpolation an n×n matrix (49 "extrema" instead of 7).
- A first window rule ("widen until the outermost extremum is inside the inner
  half") found extra outer extrema that `fndZeroCrs3` does not include.
  `adaptP3` needs exactly 2Np-1 extrema, so the window rule was changed to
  match `fndZeroCrs3`'s.

**Finder check.** On H3 (order 5, the `0_2_0` specs, passband width scaled by
s):
- For s = 1 and 1e-2, both finders return the same 9 extrema, within 3e-5 of
  the band width.
- For s = 1e-3, both return 9. The fixed-grid finder is off by 0.27% of the
  band width (0.589 against 0.591 half-widths).
- For s = 1e-4, the fixed grid finds 1 extremum and the x-grid finds 9.
- For s = 1e-5, the fixed grid finds 0 and the x-grid finds 9.
- At every s the x-grid finds the same 9 extrema, in half-widths.

**Design results** (`examples/shrink_band_scld.m`). The `0_2_0` specs have
wp = ±0.05·s, ws edges ±0.1·s, loss poles at ±0.3 and Ap = 3.0103 dB. The
table gives passband GD ripple; "fail" means only 0–1 extrema were found.

| n | passband width | fixed z grid | x grid | control: z grid scaled to band |
|---|---|---|---|---|
| 3 | 1e-1 | 2.14% | 2.14% | 2.14% |
| 3 | 1e-3 | 0.48% | 2.71% | 2.71% |
| 3 | 1e-4 | 14.7% (not corrected) | **2.80%** | 2.80% |
| 3 | 1e-5 | fail | **2.81%** | 2.81% |
| 3 | 1e-6 | fail | 14.7% (reverted) | 14.7% (reverted) |
| 5 | 1e-1 | 2.58% | 2.58% | 2.58% |
| 5 | 1e-3 | 0.43% | 0.47% | 0.47% |
| 5 | 1e-4 | 11.2% (reverted) | **0.45%** | 0.45% |
| 5 | 1e-5 | fail | **0.45%** | 0.45% |
| 5 | 1e-6 | fail | 11.2% | 8.8% |

For n = 7, both chains skip `adaptP3` (9.84% ripple, under the 10% threshold)
at widths from 1e-3 to 1e-6. The fixed grid fails at 1e-5 and 1e-6, and the
x grid does not.

- **The control** was a scratchpad copy of `fndZeroCrs3_scld` with
  deltW = min(1e-5, width/2000)·2π and a coarse step of 10·deltW. It is not in
  the repo. Its results are identical to the x grid down to width 1e-5, and it
  is 2–3x slower (7–10 s against 3 s per design).
- **At width 1e-3 for n = 3,** the fixed grid's in-band ripple is lower. The
  finer grids place the extrema more accurately, and `adaptP3` then converges
  differently. Its objective also includes extrema just outside the band.

**Conclusion.**
- The x-grid chain designs bands about 100x narrower than the fixed-grid chain
  (down to 1e-5 cycles against 1e-3).
- The gain comes from a frequency grid scaled to the band. A z grid scaled the
  same way gives identical results, so this does **not** by itself justify the
  transformed variable.
- The x-specific advantage seen so far is that on-axis transmission zeros can be
  placed exactly at Re = 0. It did not change any result here. In z, a zero on
  the unit circle could simply be counted as a constant 1/2 of group delay.
- Both chains fail at width 1e-6. **Next step:** find out what fails there. If
  it is precision lost in storing z-poles close to 1, a design that keeps the
  poles in x and runs its Newton steps in x is the remaining case where the
  transformed variable could be justified.

## 8. All-pass group-delay equalizers (`dsgnEqlzrD` family): narrow-band test

**Question.** Does the transformed variable help the `dsgnEqlzrD_*` all-pass
equalizer designs, e.g. `examples/dsgnEqlzrD_peakNewton_manual.m`?

**Summary: where the x version (B) is better depends on the comparison.**

| Compared with | x is better at | Why |
|---|---|---|
| A, the existing `dsgnEqlzrD` | 5e-3 and narrower (70.6% → 167.3% against 51.1%) | fixed r ≤ 0.995 limit |
| C, z with band-relative limits | 5e-2, 5e-4, 5e-5 | (r, θ) are badly scaled for fminimax |
| D, z with linear band scaling | 5e-5 only (102.0% against 51.1%) | cancellation in the z kernel |
| E, D with a cancellation-free kernel | never | E has both properties, added by hand |

- **Nothing here is unreachable in z.** The value of x is that it gives both
  properties automatically and exactly: parameters of order 1 at any width,
  and a group-delay expression with no cancellation. A z-domain design needs
  both added by hand (E); either one alone fails (C, D).
- **The practical gain is over the existing code,** which uses fixed limits.
  Section 9 shows the same for `eqlzrD_peakNewtonStep` (80.8% → 175.8%
  against 4.39%, from 5e-3 down). E-style controls were only tested for
  `dsgnEqlzrD`; section 9 compares x with the original only.
- **Relevant widths:** `EqualFltr_1_6_0`'s passband is 1/1024 ≈ 1e-3 cycles,
  so the existing code's fixed limits already matter there.
- **Not comparable:** the 51.1% here is a 5-section minimax design, and
  section 9's 4.39% is 25 stages in 5 clusters tuned by Newton steps.

**What the transformed variable could not improve there.**
- These designs already use band-relative grids: `estAllPassOrder`, and
  `eqlzrD_peakNewtonStep`'s `linspace` over wp ± 10%. The section 7 grid
  problem therefore does not occur.
- The existing examples use wide bands (0.05 and 0.45 cycles).

**What it could improve.** Each section is parametrized as (r, θ) with fixed
absolute limits:
- `dsgnEqlzrD` has r ≤ 0.995;
- `eqlzrD_peakNewtonStep` has R_MIN/R_MAX = [0.3, 0.995].

A section's group-delay peak is about 2(1-r) wide, so narrow bands need r
closer to 1 than those limits allow.

**Five designs** (new files only apart from A; test `examples/shrink_eqlzr_scld.m`,
about 4 minutes):

| | File | Section parameters |
|---|---|---|
| A | `lib/dsgnEqlzrD.m` (unchanged) | (r, θ) in z, r in [0, 0.995], r0 in {0.5, 0.75, 0.85, 0.95} |
| B | `lib/dsgnEqlzrDX_scld.m` | x-domain pole -σ + jΩp |
| C | `lib/dsgnEqlzrDZrel_scld.m` | (r, θ) in z, with B's limits and starts mapped to r |
| D | `lib/dsgnEqlzrDZlin_scld.m` | linear band scaling in z: r = 1 - 2tρ, θ = w0 + 2tφ |
| E | `lib/dsgnEqlzrDZlinB_scld.m` | D, with the group delay evaluated without cancellation |

**Design B in detail.**
- An x-domain pole -σ + jΩp with zero σ + jΩp contributes a z-domain group
  delay of J(Ω)·2σ/(σ² + (Ω - Ωp)²). This equals `dsgnEqlzrD`'s Poisson kernel
  for the corresponding z pole.
- Stability is σ > 0.
- Poles are converted with a = e^{jw0}(1 + t x)/(1 - t x).

**Settings shared by B, C, D and E.**
- The limits and starting values come from `lib/eqlzrSigmaSpecs_scld.m`: A's
  r limits [0, 0.995] and starting radii converted to σ at the reference
  0.05-cycle band, so all the designs start alike at that width.
- The group delay is scaled by the unequalized peak, so fminimax's level
  variable is of order 1.
  - Without this scaling, B slipped at 5e-5 (76% ripple, and D = 1.219e5
    instead of 1.296e5), because D grew to about 1e5 next to σ and Ωp values
    of about 1.
- Everything else is as in `dsgnEqlzrD`: the grid, the fminimax multi-start
  plus the staged start, and the limits on D.

**Results** for the `dsgnEqlzrD_manual` filter (elliptic cascade, shifted by
0.05), with wp = ±0.025·s, ws edges ±0.049·s and 5 sections. The table gives
peak-to-peak group delay over the nominal passband, relative to its mean; the
unequalized value is 176% at every width.

| band width | A | B (x) | C (z, relative limits) | D (z, linear) | E (D, no cancellation) |
|---|---|---|---|---|---|
| 5e-2 | 51.2% | 51.1% | 91.7% | 50.9% | 50.9% |
| 5e-3 | 70.6% | **51.1%** | 51.1% | 51.1% | 51.1% |
| 5e-4 | 118.6% | **51.1%** | 83.0% | 51.1% | 51.1% |
| 5e-5 | 167.3% | **51.1%** | 67.6% | 102.0% | **51.1%** |

- **B is exactly the same at every width.** D scales 10x per step
  (129.7 → 1.296e5), and 1 - max|pole| scales 10x per step (0.0255 → 2.59e-5).
  Each design takes 4–6 s, against 7–21 s for A.
- **A is limited by r ≤ 0.995:** 1 - max|pole| stays at 0.005 from 5e-3
  downward.
- **C has the same limits and starts as B** but keeps (r, θ). It reaches the
  good optimum only once in four widths. In z, θ varies over about 2π·bw and
  1 - r over a similar range, while r stays near 1. That is a badly scaled
  problem for fminimax.
- **D (linear scaling) matches B down to 5e-4 but fails at 5e-5.**
  - The cause is cancellation in the z-domain kernel
    (1 - r²)/(1 - 2r cos Δ + r²). Its denominator subtracts numbers near 1 to
    get about (1-r)² ≈ 1e-9, so only about 7 digits are left.
  - fminimax's finite-difference steps (about 1e-8 in ρ) then change the
    delay by less than the rounding noise, so its gradients are noise.
  - E evaluates (1-r)(1+r)/((1-r)² + 4r sin²(Δ/2)) with 1 - r = 2tρ kept
    exact. It matches B at every width, which confirms the cause.

**Conclusion.**
- The transformed variable is useful for all-pass equalizer design on narrow
  bands. It gives, automatically and exactly:
  1. parameters of order 1 at any band width, with limits and starting values
     in band units;
  2. a group-delay expression, 2σ/(σ² + (Ω - Ωp)²), that has no
     cancellation.
- A z-domain design can match it only by doing both by hand: the linear band
  scaling (D), plus a rewritten kernel with 1 - r kept exact (E). Either one
  alone fails (C, D).
- **Existing code, found but not changed:**
  - `dsgnEqlzrD`'s kernel has this cancellation. It is currently masked by the
    r ≤ 0.995 limit, which fails first.
  - `eqlzrD_peakNewtonStep` uses the same (r, θ) parameters with the fixed
    [0.3, 0.995] clamp.
  - Both are addressed with new files in section 9; the originals are
    unchanged.
- At the existing examples' 0.05-cycle width, B matches A (51%), so the gain
  is for narrower bands.
- `AnlzDH` is much less affected, because e^{jw} - p is not squared. Its
  relative error is about eps/(1-r) ≈ 1e-11 at 1 - r = 2.6e-5.

## 9. Fixes for the two existing-code problems in section 8

Both fixes use new files only; `dsgnEqlzrD.m` and `eqlzrD_peakNewtonStep.m`
are unchanged.

**1. `dsgnEqlzrD` (cancellation in the kernel, r ≤ 0.995 limit).** Use
`lib/dsgnEqlzrDX_scld.m` from section 8. It takes the same inputs and returns
the same outputs as `dsgnEqlzrD`. Its section group delay
J·2σ/(σ² + (Ω - Ωp)²) has no cancellation, and its limits are in band units.
It matches `dsgnEqlzrD` at 0.05 cycles and stays at 51.1% down to 5e-5, where
`dsgnEqlzrD` reaches 167%.

If a z-domain version is wanted instead, `lib/dsgnEqlzrDZlinB_scld.m` gives
the same results. It needs both parts of the fix:
- the linear band scaling r = 1 - 2tρ, θ = w0 + 2tφ;
- the kernel written as (1-r)(1+r)/((1-r)² + 4r sin²(Δ/2)), with 1 - r kept
  exact.

**2. `eqlzrD_peakNewtonStep` (fixed [0.3, 0.995] radius clamp; its Jacobian
uses D = 1 - 2r cos Δ + r²).** The fix is
`examples/eqlzrD_peakNewtonStepX_scld.m`, the same Newton step with each
cluster parametrized as an x-domain pole -σ + jΩp.
- **Jacobian** (count = number of stacked stages, J = (1 + t²Ω²)/(2t)):

      d gd/d Ωp = count·J·4σ(Ω - Ωp)/(σ² + (Ω - Ωp)²)²
      d gd/d σ  = count·J·2((Ω - Ωp)² - σ²)/(σ² + (Ω - Ωp)²)²

  It agrees with a central finite difference of `AnlzDH` group delay to
  4.6e-10.
- **Clamp:** σ is limited to [0.0318, 6.84] in band units. These are the
  original [0.995, 0.3] radius limits converted at the reference 0.05-cycle
  band, so at that width the two clamps coincide.
- **Unchanged:** the extremum detection (a d2TdW bracket scan on wp ± 10%). It
  already scales with the band, and `AnlzDH` is not affected by the
  cancellation.
- **Interface:** the same as the original, with clusterTheta → clusterWp,
  clusterR → clusterSigma and freeR → freeSigma. `info.dtheta` and `info.dr`
  hold the raw steps on Ωp and σ, and `info.rClamped` flags σ clamping.

**Test** (`examples/shrink_peakNewton_scld.m`, non-interactive, a few minutes).
- It runs `dsgnEqlzrD_peakNewton_manual`'s two phases:
  - angle-only: step 0.2, up to 100 steps, stopping when the spread changes
    by less than 1e-4 of the anchor;
  - joint: step 0.1, up to 50 steps, keeping the best result, patience 5.
- It starts from 5 clusters of 5 stages at 10/30/50/70/90% of the band, with
  r = 0.925.
- The x version starts from those poles mapped exactly at 0.05 cycles, then
  from the same (Ωp, σ) in band units at every width.
- The filter is the manual's, with its band scaled by s.

| band width | version | p2p nominal | p2p expanded | 1 - max\|pole\| | clamped |
|---|---|---|---|---|---|
| 5e-2 | z (θ, r) | 4.39% | 44.22% | 0.0682 | no |
| 5e-2 | x (Ωp, σ) | 4.38% | 44.25% | 0.0681 | no |
| 5e-3 | z (θ, r) | 80.79% | 101.68% | 0.0205 | yes |
| 5e-3 | x (Ωp, σ) | **4.39%** | 44.22% | 0.00705 | no |
| 5e-4 | z (θ, r) | 175.59% | 203.40% | 0.005 | yes |
| 5e-4 | x (Ωp, σ) | **4.39%** | 44.22% | 0.000707 | no |
| 5e-5 | z (θ, r) | 175.81% | 203.62% | 0.005 | yes |
| 5e-5 | x (Ωp, σ) | **4.39%** | 44.22% | 7.07e-05 | no |

- **The x version gives the same equalizer at every width.** The poles'
  distance from the unit circle scales exactly 10x per step, and no clamp is
  hit.
- **The z version equals it at 0.05 cycles** but hits its r clamp from 5e-3
  down. At 5e-4 and narrower it ends no better than the unequalized filter
  (176%).
- **A test-script detail:** the design path turns warnings back on, so the
  script silences the two clamp warning IDs after designing each filter;
  clamping is reported in the table instead.

## 10. What failed at a 1e-6-cycle band, and fixes down to 1e-12

Section 7 found both filter-design chains failing at a passband width of
1e-6 cycles. **The cause was three hard-coded absolute tolerances in the
z-domain code**, each suited to ordinary band widths. It was not the
transformed variable or the Newton method.

1. **`adaptP3`'s pole clamp `R_MAX = 0.99999`**, which forces 1 - |p| >= 1e-5.
   This fails first, at 1e-6 cycles.
   - The prototype's poles already start at 1 - |p| ≈ 2.2e-6.
   - The first clamp pushes them all out to 1e-5, about 5x too far from the
     circle.
   - The group-delay shape collapses ("1 maxima, need 3"), `adaptP3` gives up,
     and the design is reverted.
2. **`simpl` in `cont2Digital`**, whose default tolerance is an absolute 1e-6.
   It makes roots with a smaller imaginary part real, so it fails at 1e-7
   cycles. The complex pole pair's imaginary parts are about 4e-7 there
   (angle ±0.69 band widths), so the filter becomes wrong right after the
   bilinear transform, before any design step. The x-domain and z-domain
   group delays still agreed, so the extrema finder was not at fault.
3. **`simpl` in `y2zSbTrnsf1`**, which `place_polesdLP3` uses to convert back to
   z. It uses the same absolute 1e-6 and also fails at 1e-7 cycles.
   - The group-delay stage alone still gave 2.805% at 1e-7.
   - After `place_polesdLP3`, the pole pair had moved by 1.17 × (1 - |p|), and
     the ripple was 67% with 10 dB of passband loss.

**Fixes** (new files, or `_scld` files from this work):

| File | Change |
|---|---|
| `lib/adaptP3X_scld.m` | R_MAX = 1 - min(1e-5, 0.01·2π·width) |
| `lib/cont2Digital_scld.m` (copy of `cont2Digital.m`) | `simpl` tolerance min(1e-6, 1e-3·2π·width) |
| `lib/y2zSbTrnsf1_scld.m` (copy of `y2zSbTrnsf1.m`) | the same, for the conversion back to z |
| `lib/place_polesdLP3_scld.m` (copy of `place_polesdLP3.m`) | calls `y2zSbTrnsf1_scld` |
| `lib/dsgnEquiRplGDX_scld.m` | calls `cont2Digital_scld` and `place_polesdLP3_scld` |

Both limits equal the old values for bands wider than about 1.6e-4 cycles.
Designs at those widths are unchanged; every section 7 result was reproduced
exactly.

**Results** (`examples/shrink_band_scld.m`, now run down to a width of 1e-12
cycles; the `0_2_0` specs as in section 7):

| width (cycles) | n = 3 GD ripple | n = 5 GD ripple | n = 7 |
|---|---|---|---|
| 1e-4 to 1e-11 | 2.80–2.81% | 0.449–0.451% | 9.837%, `adaptP3` skipped |
| 1e-12 | 2.807% | 0.449% | 9.835% |

- Passband and stopband loss are also unchanged down to 1e-12.
- The fixed-grid chain (`dsgnDigitalFltr_scld`) still fails below 1e-4,
  because its extrema grid is not scaled to the band (section 7).

**The floor.** A separate run (scratchpad copies with the same three changes)
at a width of 1e-13 gave 2.793% and 0.499%. The poles are then about 2e-13
from the unit circle, roughly 1000·eps, so z-domain pole positions keep only
about 3 digits. That is the limit for any design that ends with z-domain poles.

**For the scaled-variable question.** These failures came from absolute
tolerances written for ordinary band widths, not from where group delay is
evaluated. Scaling the tolerances to the band fixes them in z; no transformed
variable was needed. The transformed-variable chain was used here only because
its extrema grid already scales with the band (section 7).

**Still present in the originals** (`adaptP3`, `cont2Digital`, `y2zSbTrnsf1`,
and `simpl`'s default): the same absolute limits. Other callers of `simpl` with
its default tolerance could hit the same problem on very narrow bands.
