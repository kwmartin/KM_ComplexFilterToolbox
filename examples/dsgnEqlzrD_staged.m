function [eq, info] = dsgnEqlzrD_staged(H, wp, N, marginFrac, N_grid, nSweeps)
%   [eq, info] = dsgnEqlzrD_staged(H, wp, N, marginFrac, N_grid, nSweeps)
%   designs an initial N-section discrete all-pass group-delay equalizer
%   (an eqlzrDClass object) for filter H, targeting flat group delay
%   across passband wp, using a staged constructive heuristic instead of
%   dsgnEqlzrD.m's joint fminimax fit.
%
%   Method (three stages, each a cheap 1-D or per-coordinate search, no
%   joint N-dimensional nonlinear fit):
%     1. Place N pole angles theta_i evenly across the "deficit region"
%        (the dip between H's own two largest group-delay peaks, same
%        sub-band dsgnEqlzrD.m starts from), all at a shared radius r
%        close to 1 (narrow, tall bumps).
%     2. Shrink the single SHARED radius r (a 1-D search via fminbnd) so
%        the worst-case deviation of the combined group delay from the
%        flat target D is minimized, with theta_i still fixed. This is
%        cheap and has no local-minima concerns since it is 1-D.
%     3. With r fixed, sweep each theta_i in turn (coordinate descent,
%        nSweeps full passes, default 3), each step a 1-D fminbnd search
%        re-minimizing the same worst-case criterion with all other
%        sections held fixed. Unlike dsgnEqlzrD.m's one-shot closed-form
%        heuristics (which sized each section in isolation against a
%        local target and were found to overshoot once neighboring
%        sections' contributions were added), this stage explicitly
%        re-evaluates the actual composite response at each step.
%
%   No Optimization Toolbox fminimax call anywhere; only fminbnd (base
%   MATLAB). Intended to be compared against dsgnEqlzrD.m on peak-to-peak
%   group delay in the passband, and optionally used as an initial guess
%   fed into dsgnEqlzrD.m's fminimax polish (pass eq.sctns(:).wi through
%   as x0 there) rather than its blind multi-start.
%
%   info is a struct with fields: D_target, p2p_before, p2p_after,
%   worstResidual, wallTime, r_shared.
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

  % Stage 2: 1-D search over a single shared radius
  worstCost = @(r) max(abs(gdH0 + bumpSum(r*ones(1,N), theta, w) - D_target));
  r_shared = fminbnd(worstCost, 0.01, 0.995, optimset('TolX', 1e-4));
  r = r_shared * ones(1, N);

  % Stage 3: coordinate-descent sweeps over individual theta_i, r fixed
  for sweep = 1:nSweeps
    for i = 1:N
      idx = true(1, N);
      idx(i) = false;
      otherBump = bumpSum(r(idx), theta(idx), w);
      residualBase = gdH0 + otherBump - D_target;
      costTheta_i = @(th) max(abs(residualBase + (1-r(i)^2)./(1 - 2*r(i)*cos(w-th) + r(i)^2)));
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
end

function s = bumpSum(r, theta, w)
  s = zeros(size(w));
  for i = 1:length(r)
    s = s + (1-r(i)^2) ./ (1 - 2*r(i)*cos(w-theta(i)) + r(i)^2);
  end
end
