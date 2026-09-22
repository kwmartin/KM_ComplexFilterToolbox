function [eq, info] = dsgnEqlzrD_staged_perR(H, wp, N, marginFrac, N_grid, nSweeps)
%   [eq, info] = dsgnEqlzrD_staged_perR(H, wp, N, marginFrac, N_grid, nSweeps)
%   is dsgnEqlzrD_staged.m's staged heuristic, but with an INDIVIDUAL
%   radius r_i per section instead of one shared r -- see
%   dsgnEqlzrD_staged.m's own docstring for the shared-r version and the
%   reasoning that motivated trying this variant (a shared r forces a
%   single width choice across all sections, which under-serves the
%   sections nearest the safe-zone edges that most need to stay narrow to
%   avoid leaking group delay into H's pre-existing peaks).
%
%   Method:
%     1. Same as dsgnEqlzrD_staged.m: place N pole angles theta_i evenly
%        across the safe sub-band between H's two largest group-delay
%        peaks, all starting at a shared radius r0 (default 0.95).
%     2. Coordinate descent, nSweeps full passes (default 3): for each
%        section i in turn, holding all other sections fixed, first
%        re-optimize r_i (1-D fminbnd) against the actual composite
%        worst-case residual, then re-optimize theta_i (1-D fminbnd) with
%        that updated r_i. Each step sees the true composite response
%        (all other sections' current bumps included), same as
%        dsgnEqlzrD_staged.m's theta-only coordinate descent.
%
%   Still no joint N-dimensional nonlinear fit and no Optimization
%   Toolbox dependency (fminbnd only, base MATLAB) -- just 2N searches
%   per sweep instead of N.
%
%   info is a struct with fields: D_target, p2p_before, p2p_after,
%   worstResidual, wallTime.
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
  D_target = stats.D_target;
  p2p_before = max(gdH0) - min(gdH0);

  % Stage 1: evenly-spaced initial angles across the deficit sub-band
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

  r0 = 0.95;
  r = r0 * ones(1, N);

  % Stage 2: coordinate descent over (r_i, theta_i) pairs, r_i first
  optsR = optimset('TolX', 1e-4);
  optsTh = optimset('TolX', 1e-5);
  for sweep = 1:nSweeps
    for i = 1:N
      idx = true(1, N);
      idx(i) = false;
      otherBump = bumpSum(r(idx), theta(idx), w);
      residualBase = gdH0 + otherBump - D_target;

      costR_i = @(rr) max(abs(residualBase + (1-rr^2)./(1 - 2*rr*cos(w-theta(i)) + rr^2)));
      r(i) = fminbnd(costR_i, 0.01, 0.995, optsR);

      costTheta_i = @(th) max(abs(residualBase + (1-r(i)^2)./(1 - 2*r(i)*cos(w-th) + r(i)^2)));
      theta(i) = fminbnd(costTheta_i, theta_lo, theta_hi, optsTh);
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
end

function s = bumpSum(r, theta, w)
  s = zeros(size(w));
  for i = 1:length(r)
    s = s + (1-r(i)^2) ./ (1 - 2*r(i)*cos(w-theta(i)) + r(i)^2);
  end
end
