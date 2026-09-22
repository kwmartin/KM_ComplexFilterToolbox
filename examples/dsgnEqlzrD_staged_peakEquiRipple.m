function [eq, info] = dsgnEqlzrD_staged_peakEquiRipple(H, wp, N, marginFrac, N_grid, nSweeps)
%   [eq, info] = dsgnEqlzrD_staged_peakEquiRipple(H, wp, N, marginFrac,
%   N_grid, nSweeps) designs an N-section discrete all-pass group-delay
%   equalizer using dsgnEqlzrD_staged.m's search machinery (evenly-spaced
%   initial pole angles, 1-D shared-radius fminbnd search, per-angle
%   coordinate-descent refinement), but with a DIFFERENT objective,
%   entirely replacing dsgnEqlzrD_staged.m's "match a flat target level D"
%   criterion:
%
%     1. Fix the analysis WINDOW once, from H's own unequalized group
%        delay: the two outermost local-maximum peaks (islocalmax,
%        MinProminence=5), i.e. the pre-existing "edge peaks". Frequencies
%        outside this window (past either edge peak) are never considered
%        by the objective, no matter how the equalized response looks
%        there.
%     2. Fix an ANCHOR once too: the unweighted mean of H's own
%        (unequalized) peak values within that window.
%     3. At each trial pole configuration, find the local-maximum peaks
%        of the CURRENT equalized group delay within the fixed window
%        (the peak SET can change between trials -- see the note below),
%        and for each peak compute
%          |peak_value - anchor| * |H(f_peak)|
%        (the gain-weighting term; equalization is exactly gain-
%        preserving by construction, so H and Heq agree here -- see
%        allPassDClass.m's docstring). The objective is the MAX of this
%        quantity over all peaks in the window (equi-ripple/minimax
%        style, matching the rest of this exploration).
%
%   Earlier version of this file compared each trial's peaks against
%   their OWN floating mean instead of a fixed anchor -- this let the
%   optimizer satisfy "peaks match each other" by inventing brand-new
%   peaks anywhere and driving them to an arbitrary common height with no
%   constraint on absolute level (confirmed empirically: it did exactly
%   this, converging to two new mid-band peaks at a mutually-matched but
%   much-too-high level while the true worst-case group delay got much
%   worse). The fixed anchor closes that gap.
%
%   This is explicitly an "equalize the peaks toward a fixed level"
%   criterion. It is being tried as a possible objective for a planned
%   follow-on Newton-based peak-frequency adaptation scheme; see
%   examples/dsgnEqlzrD_manual.m and this session's exploration notes for
%   context. This file is intentionally a clean copy-then-modify of
%   dsgnEqlzrD_staged.m rather than a parameterized option on it, so the
%   old objective remains available unchanged for comparison/revert.
%
%   NOTE on peak-set discontinuity: since which frequencies count as
%   local-maxima can change abruptly as pole positions move (peaks can
%   appear, disappear, or merge), this objective's landscape may be less
%   smooth than dsgnEqlzrD_staged.m's fixed-target one. That is part of
%   what this file exists to evaluate empirically.
%
%   info is a struct with fields: D_target (unused, NaN, kept for
%   structural parity with dsgnEqlzrD_staged.m), p2p_before, p2p_after,
%   worstResidual (the final objective value), wallTime, r_shared,
%   windowFreqs ([f_pk1 f_pk2], the fixed analysis window).
%
%   Toolbox for the Design of Complex Filters
%   Copyright (C) 2026  Kenneth Martin
%
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
%
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.
%

  if nargin < 4 || isempty(marginFrac)
    marginFrac = 0.10;
  end
  if nargin < 5 || isempty(N_grid)
    N_grid = 5000;
  end
  if nargin < 6 || isempty(nSweeps)
    nSweeps = 3;
  end

  tStart = tic;

  [~, stats] = estAllPassOrder(H, wp, marginFrac, N_grid);
  f = stats.f(:);
  w = 2*pi*f;
  gdH0 = stats.gdH(:);
  p2p_before = max(gdH0) - min(gdH0);

  gainH = abs(freqresp(H, w));
  gainH = gainH(:);

  % Fixed analysis window: H's own two outermost group-delay peaks.
  pkMask0 = islocalmax(gdH0, 'MinProminence', 5);
  f_peaks0 = f(pkMask0);
  if length(f_peaks0) >= 2
    f_pk1 = min(f_peaks0);
    f_pk2 = max(f_peaks0);
  else
    f_pk1 = stats.wp_expanded(1);
    f_pk2 = stats.wp_expanded(2);
  end
  winMask = f >= f_pk1 & f <= f_pk2;

  % Fixed ANCHOR: the unweighted mean of H's own (unequalized) peak
  % values within the window. Compared against the trial's OWN floating
  % mean (the original approach), this prevents the optimizer from
  % satisfying "peaks match each other" by inventing brand-new peaks
  % anywhere and driving them to some arbitrary common height -- every
  % trial's peaks are now compared against this fixed external
  % reference instead of against each other's average.
  %
  % Reuse pkMask0 (detected on the FULL gdH0, not a windowed subset): by
  % construction f_pk1/f_pk2 are the min/max of f(pkMask0), so all of
  % those peaks already fall within the window. Re-running islocalmax on
  % a truncated gdH0(winMask) instead would put f_pk1/f_pk2 exactly at
  % the truncated array's endpoints, which islocalmax can never flag as
  % local maxima (it requires neighbors on both sides) -- confirmed this
  % gave anchor=NaN and broke the search entirely.
  anchor = mean(gdH0(pkMask0));

  % Stage 1: evenly-spaced initial angles across the safe sub-band
  % (strictly inside the edge peaks, same as dsgnEqlzrD_staged.m).
  gap = f_pk2 - f_pk1;
  f_safe_lo = f_pk1 + 0.10*gap;
  f_safe_hi = f_pk2 - 0.10*gap;
  theta = 2*pi*linspace(f_safe_lo, f_safe_hi, N);
  theta_lo = 2*pi*f_safe_lo;
  theta_hi = 2*pi*f_safe_hi;

  % Stage 2: 1-D search over a single shared radius
  worstCost = @(r) peakEquiRippleCost(gdH0 + bumpSum(r*ones(1,N), theta, w), gainH, winMask, anchor);
  r_shared = fminbnd(worstCost, 0.01, 0.995, optimset('TolX', 1e-4));
  r = r_shared * ones(1, N);

  % Stage 3: coordinate-descent sweeps over individual theta_i
  for sweep = 1:nSweeps
    for i = 1:N
      idx = true(1, N);
      idx(i) = false;
      otherBump = bumpSum(r(idx), theta(idx), w);
      costTheta_i = @(th) peakEquiRippleCost( ...
          gdH0 + otherBump + (1-r(i)^2)./(1 - 2*r(i)*cos(w-th) + r(i)^2), gainH, winMask, anchor);
      theta(i) = fminbnd(costTheta_i, theta_lo, theta_hi, optimset('TolX', 1e-5));
    end
  end

  wiVec = r(:).*exp(1j*theta(:));
  eq = eqlzrDClass(wiVec, 1);

  gdH1 = gdH0 + bumpSum(r, theta, w);

  info.D_target = anchor;
  info.p2p_before = p2p_before;
  info.p2p_after = max(gdH1) - min(gdH1);
  info.worstResidual = peakEquiRippleCost(gdH1, gainH, winMask, anchor);
  info.wallTime = toc(tStart);
  info.r_shared = r_shared;
  info.windowFreqs = [f_pk1, f_pk2];
end

function s = bumpSum(r, theta, w)
  s = zeros(size(w));
  for i = 1:length(r)
    s = s + (1-r(i)^2) ./ (1 - 2*r(i)*cos(w-theta(i)) + r(i)^2);
  end
end

function obj = peakEquiRippleCost(gd, gainH, winMask, anchor)
  gdWin = gd(winMask);
  gainWin = gainH(winMask);
  pkMask = islocalmax(gdWin, 'MinProminence', 5);
  peakVals = gdWin(pkMask);
  peakGains = gainWin(pkMask);
  if isempty(peakVals)
    % No detected local maxima at all (e.g. a monotonic or fully flat
    % trial within the window): fall back to the window's own extreme
    % values, still compared against the fixed anchor, so a badly-shaped
    % trial is still penalized rather than passed for free.
    [gdMax, iMax] = max(gdWin);
    [gdMin, iMin] = min(gdWin);
    peakVals = [gdMax; gdMin];
    peakGains = [gainWin(iMax); gainWin(iMin)];
  end
  obj = max(abs(peakVals - anchor) .* peakGains);
end
