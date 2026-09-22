function [eq, info] = dsgnEqlzrD_staged_peakWeighted(H, wp, N, peakWeight, peakBandFrac, marginFrac, N_grid, nSweeps)
%   [eq, info] = dsgnEqlzrD_staged_peakWeighted(H, wp, N, peakWeight,
%   peakBandFrac, marginFrac, N_grid, nSweeps) is dsgnEqlzrD_staged.m's
%   shared-radius staged heuristic, but with the worst-case cost function
%   WEIGHTED to penalize increases at H's own pre-existing group-delay
%   peaks specifically, rather than treating every frequency in the
%   worst-case criterion equally.
%
%   Motivation: dsgnEqlzrD_staged.m already evaluates its cost over the
%   full analysis grid (peaks included -- see the exploration notes
%   there), so the peaks were never literally invisible to the search.
%   The actual problem is that every all-pass section's group-delay
%   contribution is provably positive everywhere (it can only ADD delay,
%   never subtract), so bumps placed away from the peaks (to avoid
%   directly boosting locations that are already at target) still leak
%   positive delay into the peaks via their tails, and an unweighted
%   worst-case criterion trades that leakage off equally against
%   flattening the middle. Upweighting the peak frequencies in the cost
%   makes the search much more reluctant to let ANY residual grow there
%   -- since the peaks already sit at ~D_target (deficit ~0), the only
%   direction residual can grow at those points is an increase (leakage),
%   so discouraging deviation there in general is, in practice,
%   discouraging exactly the overshoot this is meant to fix.
%
%   peakWeight (default 20) multiplies the cost within peakBandFrac
%   (default 0.15, a fraction of the safe-zone gap) of each of H's
%   detected group-delay peaks (islocalmax, same MinProminence=5
%   criterion as dsgnEqlzrD_staged.m, but applied to ALL local maxima in
%   the expanded band, not just the two used for safe-zone placement).
%
%   info is a struct with fields: D_target, p2p_before, p2p_after,
%   worstResidual (unweighted), wallTime, r_shared, peakWeight,
%   peakBandFrac.
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

  if nargin < 4 || isempty(peakWeight)
    peakWeight = 20;
  end
  if nargin < 5 || isempty(peakBandFrac)
    peakBandFrac = 0.15;
  end
  if nargin < 6 || isempty(marginFrac)
    marginFrac = 0.10;
  end
  if nargin < 7 || isempty(N_grid)
    N_grid = 5000;
  end
  if nargin < 8 || isempty(nSweeps)
    nSweeps = 3;
  end

  tStart = tic;

  [~, stats] = estAllPassOrder(H, wp, marginFrac, N_grid);
  f = stats.f(:);
  w = 2*pi*f;
  gdH0 = stats.gdH(:);
  D_target = stats.D_target;
  p2p_before = max(gdH0) - min(gdH0);

  pkMask = islocalmax(gdH0, 'MinProminence', 5);
  f_peaks = f(pkMask);
  if length(f_peaks) >= 2
    f_pk1 = min(f_peaks);
    f_pk2 = max(f_peaks);
  else
    f_pk1 = stats.wp_expanded(1);
    f_pk2 = stats.wp_expanded(2);
  end
  gap = f_pk2 - f_pk1;
  f_safe_lo = f_pk1 + 0.10*gap;
  f_safe_hi = f_pk2 - 0.10*gap;
  theta = 2*pi*linspace(f_safe_lo, f_safe_hi, N);
  theta_lo = 2*pi*f_safe_lo;
  theta_hi = 2*pi*f_safe_hi;

  % Build the peak-weighted cost weighting vector: elevated near every
  % detected peak in the expanded band (not just the two used above).
  peakBand = peakBandFrac * gap;
  wt = ones(size(f));
  for fp = f_peaks(:).'
    wt(abs(f - fp) < peakBand) = peakWeight;
  end

  % Stage 2: 1-D search over a single shared radius, weighted cost
  worstCost = @(r) max(wt .* abs(gdH0 + bumpSum(r*ones(1,N), theta, w) - D_target));
  r_shared = fminbnd(worstCost, 0.01, 0.995, optimset('TolX', 1e-4));
  r = r_shared * ones(1, N);

  % Stage 3: coordinate-descent sweeps over individual theta_i, weighted cost
  for sweep = 1:nSweeps
    for i = 1:N
      idx = true(1, N);
      idx(i) = false;
      otherBump = bumpSum(r(idx), theta(idx), w);
      residualBase = gdH0 + otherBump - D_target;
      costTheta_i = @(th) max(wt .* abs(residualBase + (1-r(i)^2)./(1 - 2*r(i)*cos(w-th) + r(i)^2)));
      theta(i) = fminbnd(costTheta_i, theta_lo, theta_hi, optimset('TolX', 1e-5));
    end
  end

  wiVec = r(:).*exp(1j*theta(:));
  eq = eqlzrDClass(wiVec, 1);

  gdH1 = gdH0 + bumpSum(r, theta, w);

  info.D_target = D_target;
  info.p2p_before = p2p_before;
  info.p2p_after = max(gdH1) - min(gdH1);
  info.worstResidual = max(abs(gdH1 - D_target));
  info.wallTime = toc(tStart);
  info.r_shared = r_shared;
  info.peakWeight = peakWeight;
  info.peakBandFrac = peakBandFrac;
end

function s = bumpSum(r, theta, w)
  s = zeros(size(w));
  for i = 1:length(r)
    s = s + (1-r(i)^2) ./ (1 - 2*r(i)*cos(w-theta(i)) + r(i)^2);
  end
end
