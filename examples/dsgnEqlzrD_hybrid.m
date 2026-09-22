function [eq, info] = dsgnEqlzrD_hybrid(H, wp, N, marginFrac, N_grid, nSweeps)
%   [eq, info] = dsgnEqlzrD_hybrid(H, wp, N, marginFrac, N_grid, nSweeps)
%   designs an initial N-section discrete all-pass group-delay equalizer,
%   using dsgnEqlzrD_staged.m's cheap staged construction as the initial
%   guess for a SINGLE dsgnEqlzrD.m-style joint fminimax polish (instead
%   of dsgnEqlzrD.m's own blind multi-start over several shared starting
%   radii). See dsgnEqlzrD_staged.m and dsgnEqlzrD.m for the individual
%   methods being combined here.
%
%   info is a struct with fields: D_target, p2p_before, p2p_staged,
%   p2p_after, worstResidual_staged, worstResidual, wallTime_staged,
%   wallTime_polish, wallTime.
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

  [eqStaged, infoStaged] = dsgnEqlzrD_staged(H, wp, N, marginFrac, N_grid, nSweeps);
  wStaged = [eqStaged.sctns.wi];
  r0 = abs(wStaged);
  theta0 = angle(wStaged);

  [~, stats] = estAllPassOrder(H, wp, marginFrac, N_grid);
  f = stats.f(:);
  w = 2*pi*f;
  gdH0 = stats.gdH(:);
  D_target0 = stats.D_target;

  f_lo = stats.wp_expanded(1);
  f_hi = stats.wp_expanded(2);
  lb = [zeros(1,N), 2*pi*f_lo*ones(1,N), D_target0*0.8];
  ub = [0.995*ones(1,N), 2*pi*f_hi*ones(1,N), D_target0*1.5];

  opts = optimoptions('fminimax', 'Display', 'off', ...
      'MaxIterations', 200, 'MaxFunctionEvaluations', 20000);

  tPolishStart = tic;
  x0 = [r0(:).', theta0(:).', D_target0];
  [xsol, fval] = fminimax(@(x) eqlzrMinimaxCostHybrid(x, w, gdH0), ...
      x0, [],[],[],[],lb,ub,[],opts);
  wallTime_polish = toc(tPolishStart);

  r = xsol(1:N);
  theta = xsol(N+1:2*N);
  D_target = xsol(end);
  wiVec = r(:).*exp(1j*theta(:));
  eq = eqlzrDClass(wiVec, 1);

  bumpSum = zeros(size(w));
  for i = 1:N
    bumpSum = bumpSum + (1-r(i)^2) ./ (1 - 2*r(i)*cos(w-theta(i)) + r(i)^2);
  end
  gdH1 = gdH0 + bumpSum;

  info.D_target = D_target;
  info.p2p_before = infoStaged.p2p_before;
  info.p2p_staged = infoStaged.p2p_after;
  info.p2p_after = max(gdH1) - min(gdH1);
  info.worstResidual_staged = infoStaged.worstResidual;
  info.worstResidual = max(fval);
  info.wallTime_staged = infoStaged.wallTime;
  info.wallTime_polish = wallTime_polish;
  info.wallTime = toc(tStart);
end

function res = eqlzrMinimaxCostHybrid(x, w, gdH0)
  N = (length(x)-1)/2;
  r = x(1:N);
  theta = x(N+1:2*N);
  D = x(end);
  bumpSum = zeros(size(w));
  for i = 1:N
    bumpSum = bumpSum + (1-r(i)^2) ./ (1 - 2*r(i)*cos(w-theta(i)) + r(i)^2);
  end
  res = abs(gdH0 + bumpSum - D);
end
