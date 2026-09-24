function [eq, info] = dsgnEqlzrDX_scld(H, wp, N, marginFrac, N_grid)
%   [_scld copy of dsgnEqlzrD.m - the same minimax all-pass equalizer
%   design, but with each section parametrized in the band-centred
%   transformed variable of z2xc instead of by (r, theta) in z.]
%
%   With w0 = pi*(wp(1) + wp(2)), t = tan(pi*(wp(2) - wp(1))/2) and
%   W = tan((w - w0)/2)/t, the passband maps to W in [-1 1]. An all-pass
%   section with x-domain pole -sigma + j*Wp (and zero sigma + j*Wp) has
%   x-domain group delay 2*sigma/(sigma^2 + (W - Wp)^2), so its z-domain
%   group delay is
%       gd(w) = J(W) * 2*sigma/(sigma^2 + (W - Wp)^2),  J = (1 + t^2 W^2)/(2t)
%   which equals dsgnEqlzrD's Poisson kernel for the corresponding z pole.
%   Stability is simply sigma > 0, and sigma and Wp are of order 1 in band
%   units however narrow the band is. The bounds and starting sigmas come
%   from eqlzrSigmaSpecs_scld and are fixed in band units. Everything
%   else (grid, fminimax multi-start, staged start, D bounds) follows
%   dsgnEqlzrD. The result is converted back to z poles
%   a = exp(j*w0)*(1 + t*x)/(1 - t*x) for the eqlzrDClass object.
%
%   info has the same fields as dsgnEqlzrD's.
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

  tStart = tic;

  [~, stats] = estAllPassOrder(H, wp, marginFrac, N_grid);
  f = stats.f(:);
  w = 2*pi*f;
  gdH0 = stats.gdH(:);
  p2p_before = max(gdH0) - min(gdH0);

  w0 = pi*(wp(1) + wp(2));
  t = tan(pi*(wp(2) - wp(1))/2);
  f2W = @(ff) tan((2*pi*ff - w0)/2)/t;
  W = f2W(f);
  J = (1 + t^2*W.^2)/(2*t);

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
  W_safe_lo = f2W(f_pk1 + 0.10*gap);
  W_safe_hi = f2W(f_pk2 - 0.10*gap);

  W_lo = f2W(stats.wp_expanded(1));
  W_hi = f2W(stats.wp_expanded(2));
  D_target0 = max(gdH0);

  [SIGMA_MIN, SIGMA_MAX, SIGMA0] = eqlzrSigmaSpecs_scld();
  % Group delays are scaled by D_target0 so the level variable is of order 1
  % like sigma and Wp (it grows as 1/bandwidth otherwise).
  gN = gdH0/D_target0;
  JN = J/D_target0;
  lb = [SIGMA_MIN*ones(1,N), W_lo*ones(1,N), 0.8];
  ub = [SIGMA_MAX*ones(1,N), W_hi*ones(1,N), 1.5];

  opts = optimoptions('fminimax', 'Display', 'off', ...
      'MaxIterations', 200, 'MaxFunctionEvaluations', 20000);

  bestWorst = Inf;
  xBest = [];
  for sg0 = SIGMA0
    Wp0 = linspace(W_safe_lo, W_safe_hi, N);
    x0 = [sg0*ones(1,N), Wp0, 1];
    [xsol, fval] = fminimax(@(x) eqlzrMinimaxCostX(x, W, JN, gN), ...
        x0, [],[],[],[],lb,ub,[],opts);
    worst = max(fval);
    if worst < bestWorst
      bestWorst = worst;
      xBest = xsol;
    end
  end

  % One more candidate start: the staged heuristic, in x
  [sg_staged, Wp_staged] = stagedStartCandidateX(gN, 1, W, JN, N, ...
      W_safe_lo, W_safe_hi, SIGMA_MIN, SIGMA_MAX);
  x0_staged = [sg_staged, Wp_staged, 1];
  [xsol, fval] = fminimax(@(x) eqlzrMinimaxCostX(x, W, JN, gN), ...
      x0_staged, [],[],[],[],lb,ub,[],opts);
  worst = max(fval);
  if worst < bestWorst
    bestWorst = worst;
    xBest = xsol;
  end
  nStarts = length(SIGMA0) + 1;

  Nsec = (length(xBest)-1)/2;
  sg = xBest(1:Nsec);
  Wp = xBest(Nsec+1:2*Nsec);
  D_target = xBest(end)*D_target0;
  xp = -sg(:) + 1j*Wp(:);
  wiVec = exp(1j*w0)*(1 + t*xp)./(1 - t*xp);

  eq = eqlzrDClass(wiVec, 1);

  gdH1 = gdH0 + bumpSumX(sg, Wp, W, J);

  info.D_target = D_target;
  info.p2p_before = p2p_before;
  info.p2p_after = max(gdH1) - min(gdH1);
  info.worstResidual = bestWorst*D_target0;
  info.wallTime = toc(tStart);
  info.nStarts = nStarts;
end

function res = eqlzrMinimaxCostX(x, W, J, gdH0)
  N = (length(x)-1)/2;
  res = abs(gdH0 + bumpSumX(x(1:N), x(N+1:2*N), W, J) - x(end));
end

function s = bumpSumX(sg, Wp, W, J)
%   z-domain group delay of the sections, evaluated through x
  s = zeros(size(W));
  for i = 1:length(sg)
    s = s + 2*sg(i)./(sg(i)^2 + (W - Wp(i)).^2);
  end
  s = J.*s;
end

function [sg, Wp] = stagedStartCandidateX(gdH0, D_target, W, J, N, W_lo, W_hi, sgMin, sgMax)
% dsgnEqlzrD's staged heuristic (evenly-spaced positions, 1-D shared-sigma
% fminbnd search, per-position coordinate-descent refinement), in x.
% Tolerances are in band units.
  Wp = linspace(W_lo, W_hi, N);
  worstCost = @(ss) max(abs(gdH0 + bumpSumX(ss*ones(1,N), Wp, W, J) - D_target));
  sg_shared = fminbnd(worstCost, sgMin, sgMax, optimset('TolX', 1e-4));
  sg = sg_shared * ones(1, N);

  optsW = optimset('TolX', 1e-5);
  for sweep = 1:3
    for i = 1:N
      idx = true(1, N);
      idx(i) = false;
      residualBase = gdH0 + bumpSumX(sg(idx), Wp(idx), W, J) - D_target;
      cost_i = @(wp_) max(abs(residualBase + bumpSumX(sg(i), wp_, W, J)));
      Wp(i) = fminbnd(cost_i, W_lo, W_hi, optsW);
    end
  end
end
