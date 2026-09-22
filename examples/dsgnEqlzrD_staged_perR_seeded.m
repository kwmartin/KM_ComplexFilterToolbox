function [eq, info] = dsgnEqlzrD_staged_perR_seeded(H, wp, N, marginFrac, N_grid, nSweeps)
%   [eq, info] = dsgnEqlzrD_staged_perR_seeded(H, wp, N, marginFrac, N_grid, nSweeps)
%   is dsgnEqlzrD_staged_perR.m's per-section-radius coordinate descent,
%   but SEEDED from dsgnEqlzrD_staged.m's shared-r result instead of a
%   fresh uniform r0=0.95 start. Motivation: dsgnEqlzrD_staged_perR.m
%   from a naive start converges almost immediately (more sweeps doesn't
%   change it) to a worse local optimum than the shared-r result -- the
%   same rugged-landscape problem that makes dsgnEqlzrD.m's joint
%   fminimax need multi-starting, showing up at smaller scale in this
%   coordinate descent. This variant starts the per-section refinement
%   from an already-decent configuration instead of from scratch.
%
%   info is a struct with fields: D_target, p2p_before, p2p_shared,
%   p2p_after, worstResidual_shared, worstResidual, wallTime_shared,
%   wallTime_refine, wallTime.
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

  [eqShared, infoShared] = dsgnEqlzrD_staged(H, wp, N, marginFrac, N_grid);
  wShared = [eqShared.sctns.wi];
  r = abs(wShared);
  theta = angle(wShared);

  [~, stats] = estAllPassOrder(H, wp, marginFrac, N_grid);
  f = stats.f(:);
  w = 2*pi*f;
  gdH0 = stats.gdH(:);
  D_target = stats.D_target;

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
  theta_lo = 2*pi*(f_pk1 + 0.10*gap);
  theta_hi = 2*pi*(f_pk2 - 0.10*gap);

  tRefineStart = tic;
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
  wallTime_refine = toc(tRefineStart);

  wiVec = r(:).*exp(1j*theta(:));
  eq = eqlzrDClass(wiVec, 1);

  gdH1 = gdH0 + bumpSum(r, theta, w);

  info.D_target = D_target;
  info.p2p_before = infoShared.p2p_before;
  info.p2p_shared = infoShared.p2p_after;
  info.p2p_after = max(gdH1) - min(gdH1);
  info.worstResidual_shared = infoShared.worstResidual;
  info.worstResidual = max(abs(gdH1 - D_target));
  info.wallTime_shared = infoShared.wallTime;
  info.wallTime_refine = wallTime_refine;
  info.wallTime = toc(tStart);
end

function s = bumpSum(r, theta, w)
  s = zeros(size(w));
  for i = 1:length(r)
    s = s + (1-r(i)^2) ./ (1 - 2*r(i)*cos(w-theta(i)) + r(i)^2);
  end
end
