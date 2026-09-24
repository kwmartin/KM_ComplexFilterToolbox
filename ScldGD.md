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
  matching, because `sort()` can pair roots of equal magnitude differently.
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
stopbands with 8000 points:

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
   1.55–1.62 dB against Ap = 2.0 dB, and 3.31 dB against 3.01 dB. Nothing in the
   flow restores the Ap edge after GD correction.
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
