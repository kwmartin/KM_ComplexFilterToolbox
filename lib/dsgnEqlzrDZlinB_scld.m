function [eq, info] = dsgnEqlzrDZlinB_scld(H, wp, N, marginFrac, N_grid)
%   [_scld copy of dsgnEqlzrDZlin_scld.m - identical except that the
%   section group delay is evaluated without cancellation: with
%   1 - r = 2*t*rho kept exact and d = w - theta,
%       (1-r^2)/(1 - 2r cos d + r^2) = (1-r)(1+r)/((1-r)^2 + 4r sin^2(d/2))
%   The original form subtracts numbers near 1 to get about (1-r)^2, which
%   for 1 - r ~ 3e-5 keeps only ~7 digits, so fminimax's finite-difference
%   gradients become noise; see ScldGD.md section 8.]
%
%   Description of dsgnEqlzrDZlin_scld, which this copies:
%   [_scld copy of dsgnEqlzrDX_scld.m - control: the same design, but each
%   section is parametrized by a LINEAR band scaling of z-domain (r, theta)
%   instead of by the transformed variable:
%       r = 1 - 2*t*rho,   theta = w0 + 2*t*phi
%   with w0 = pi*(wp(1) + wp(2)) and t = tan(pi*(wp(2) - wp(1))/2). This is
%   the first-order (near-band) approximation of the z2xc map, where
%   x = -sigma + j*Wp gives 1 - r ~ 2*t*sigma and theta - w0 ~ 2*t*Wp. rho
%   and phi use exactly dsgnEqlzrDX_scld's bounds, starts, level
%   normalization and tolerances, and the group delay is dsgnEqlzrD's exact
%   z-domain Poisson kernel. rho is also capped at 1/(2t) so r >= 0.]
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
  P.w = w; P.t = t; P.w0 = w0;
  lb = [SIGMA_MIN*ones(1,N), W_lo*ones(1,N), 0.8];
  ub = [min(SIGMA_MAX, 1/(2*t))*ones(1,N), W_hi*ones(1,N), 1.5];

  opts = optimoptions('fminimax', 'Display', 'off', ...
      'MaxIterations', 200, 'MaxFunctionEvaluations', 20000);

  bestWorst = Inf;
  xBest = [];
  for sg0 = SIGMA0
    Wp0 = linspace(W_safe_lo, W_safe_hi, N);
    x0 = [sg0*ones(1,N), Wp0, 1];
    [xsol, fval] = fminimax(@(x) eqlzrMinimaxCostL(x, P, 1/D_target0, gN), ...
        x0, [],[],[],[],lb,ub,[],opts);
    worst = max(fval);
    if worst < bestWorst
      bestWorst = worst;
      xBest = xsol;
    end
  end

  % One more candidate start: the staged heuristic, in x
  [sg_staged, Wp_staged] = stagedStartCandidateL(gN, 1, P, 1/D_target0, N, ...
      W_safe_lo, W_safe_hi, SIGMA_MIN, min(SIGMA_MAX, 1/(2*t)));
  x0_staged = [sg_staged, Wp_staged, 1];
  [xsol, fval] = fminimax(@(x) eqlzrMinimaxCostL(x, P, 1/D_target0, gN), ...
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
  wiVec = (1 - 2*t*sg(:)).*exp(1j*(w0 + 2*t*Wp(:)));

  eq = eqlzrDClass(wiVec, 1);

  gdH1 = gdH0 + bumpSumL(sg, Wp, P, 1);

  info.D_target = D_target;
  info.p2p_before = p2p_before;
  info.p2p_after = max(gdH1) - min(gdH1);
  info.worstResidual = bestWorst*D_target0;
  info.wallTime = toc(tStart);
  info.nStarts = nStarts;
end

function res = eqlzrMinimaxCostL(x, P, scale, gN)
  N = (length(x)-1)/2;
  res = abs(gN + bumpSumL(x(1:N), x(N+1:2*N), P, scale) - x(end));
end

function s = bumpSumL(rho, phi, P, scale)
%   dsgnEqlzrD's exact z-domain section group delay, times scale, with
%   r = 1 - 2*t*rho and theta = w0 + 2*t*phi
  s = zeros(size(P.w));
  for i = 1:length(rho)
    omr = 2*P.t*rho(i); % 1 - r, kept exact
    r = 1 - omr;
    d = P.w - P.w0 - 2*P.t*phi(i);
    s = s + omr*(1+r) ./ (omr^2 + 4*r*sin(d/2).^2);
  end
  s = scale*s;
end

function [sg, Wp] = stagedStartCandidateL(gdH0, D_target, P, scale, N, W_lo, W_hi, sgMin, sgMax)
% dsgnEqlzrDX_scld's staged heuristic with the linear parametrization.
  Wp = linspace(W_lo, W_hi, N);
  worstCost = @(ss) max(abs(gdH0 + bumpSumL(ss*ones(1,N), Wp, P, scale) - D_target));
  sg_shared = fminbnd(worstCost, sgMin, sgMax, optimset('TolX', 1e-4));
  sg = sg_shared * ones(1, N);

  optsW = optimset('TolX', 1e-5);
  for sweep = 1:3
    for i = 1:N
      idx = true(1, N);
      idx(i) = false;
      residualBase = gdH0 + bumpSumL(sg(idx), Wp(idx), P, scale) - D_target;
      cost_i = @(wp_) max(abs(residualBase + bumpSumL(sg(i), wp_, P, scale)));
      Wp(i) = fminbnd(cost_i, W_lo, W_hi, optsW);
    end
  end
end
