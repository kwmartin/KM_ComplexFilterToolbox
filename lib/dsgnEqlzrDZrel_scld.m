function [eq, info] = dsgnEqlzrDZrel_scld(H, wp, N, marginFrac, N_grid)
%   [_scld copy of dsgnEqlzrD.m - control for dsgnEqlzrDX_scld: the same
%   z-domain (r, theta) parametrization, but the radius bounds and
%   starting radii are fixed in band units instead of absolute. They are
%   dsgnEqlzrDX_scld's sigma bounds and starts mapped to r at the band
%   centre with r = (1 - t*sigma)/(1 + t*sigma), t = tan(pi*bw/2), so the
%   two differ only in the optimization variables. At a 0.05-cycle band
%   they are close to dsgnEqlzrD's own bounds [0, 0.995] and starts.]
%   [eq, info] = dsgnEqlzrD(H, wp, N, marginFrac, N_grid) designs an
%   initial N-section discrete all-pass group-delay equalizer (an
%   eqlzrDClass object) for filter H, targeting flat group delay across
%   passband wp. This is a first-pass placement meant as a starting point
%   to iterate an actual equalizer design from, not a finished result.
%
%   H is a (possibly complex) zpk system. wp = [wp1 wp2] is the passband,
%   in the normalized cyclic frequency (Fs=1, f in [-0.5,0.5]) used
%   throughout this toolbox. N is the number of all-pass sections
%   (typically from estAllPassOrder.m). marginFrac and N_grid are passed
%   straight through to estAllPassOrder.m (defaults 0.10 and 5000) to
%   build the analysis grid.
%
%   Method: a section's own group delay is the exact closed form (a
%   Poisson kernel centered at the pole's angle theta=angle(wi),
%   r=abs(wi)):
%     gd(w) = (1-r^2) / (1 - 2*r*cos(w-theta) + r^2)
%   and group delay adds under cascade, so the combined delay is
%   gdH0(f) + sum_i gd_i(f). The N pole locations (r_i, theta_i) AND a
%   free flat-target level D are fit jointly with fminimax (Optimization
%   Toolbox) to minimize the worst-case deviation
%     max_f | gdH0(f) + sum_i gd_i(f) - D |
%   i.e. an equi-ripple (minimax) fit, the same criterion classical
%   equi-ripple/elliptic filter design uses -- NOT a least-squares fit:
%   least-squares was tried first and, despite reducing the sum of
%   squared error by 95%, left the peak-to-peak ripple WORSE than doing
%   nothing (L2 doesn't control worst-case deviation, so it's happy to
%   overshoot in places to average out an undershoot elsewhere).
%   Least-squares closed-form heuristics that avoided fminimax entirely
%   (equal-area slices sized by width, greedy matching pursuit, equal-
%   width slices sized by average local deficit) were also tried and
%   also made the ripple worse -- ignoring cross-section overlap causes
%   each section, sized in isolation to hit a local target, to overshoot
%   once its neighbors' contributions are added on top. All of this was
%   verified empirically against examples/csc_fltr_1_6_0.m before
%   settling on the joint minimax fit.
%
%   fminimax's cost surface has multiple local minima (confirmed: a
%   shared starting radius of 0.5 or 0.95 converges to a mediocre point
%   ~8% better than unequalized, while 0.75-0.85 finds one ~14% better,
%   and 0.8 alone lands in a much WORSE one) so this function multi-
%   starts fminimax from a small set of shared initial radii and keeps
%   whichever run achieves the smallest worst-case residual. Each pole's
%   starting angle is evenly spaced across the sub-band strictly between
%   H's own two largest group-delay peaks (found via islocalmax),
%   avoiding starting a pole exactly where gdH0 already equals D and
%   needs no correction.
%
%   One additional candidate start is included: the staged constructive
%   heuristic (evenly-spaced angles, then a 1-D shared-radius fminbnd
%   search, then a per-angle coordinate-descent refinement -- see
%   examples/dsgnEqlzrD_staged.m for the standalone version and its own
%   exploration notes) is run first and its result added as one more
%   fminimax starting point alongside the shared-radius candidates above.
%   This is additive, not a replacement: the staged result was found (see
%   examples/dsgnEqlzrD_staged.m and friends) to be a decent standalone
%   result on its own but not reliably a better SEED for fminimax than
%   the existing candidates -- per-section refinement of it and blind
%   multi-start from it were both tried and neither consistently beat
%   just keeping it in the pool as one more option alongside the rest.
%
%   This is not cheap: expect on the order of 10-30 seconds wall time
%   for a handful of multi-starts at N~5 (reported in info.wallTime).
%   Given the local-minima behavior above, treat the result as a
%   starting point for further iteration, not a converged final design.
%
%   info is a struct with fields: D_target, p2p_before, p2p_after,
%   worstResidual, wallTime, nStarts.
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

  f_lo = stats.wp_expanded(1);
  f_hi = stats.wp_expanded(2);
  D_target0 = max(gdH0);

  [SIGMA_MIN, SIGMA_MAX, SIGMA0] = eqlzrSigmaSpecs_scld();
  t = tan(pi*(wp(2) - wp(1))/2);
  sig2r = @(sg) max(0, (1 - t*sg)./(1 + t*sg));
  rMin = sig2r(SIGMA_MAX);
  rMax = sig2r(SIGMA_MIN);
  % Group delays are scaled by D_target0 so the level variable is of order 1
  % (it grows as 1/bandwidth otherwise), as in dsgnEqlzrDX_scld.
  gN = gdH0/D_target0;
  lb = [rMin*ones(1,N), 2*pi*f_lo*ones(1,N), 0.8];
  ub = [rMax*ones(1,N), 2*pi*f_hi*ones(1,N), 1.5];

  opts = optimoptions('fminimax', 'Display', 'off', ...
      'MaxIterations', 200, 'MaxFunctionEvaluations', 20000);

  r0Candidates = sig2r(SIGMA0);
  bestWorst = Inf;
  xBest = [];
  for r0val = r0Candidates
    theta0 = 2*pi*linspace(f_safe_lo, f_safe_hi, N);
    r0 = r0val*ones(1,N);
    x0 = [r0, theta0, 1];
    [xsol, fval] = fminimax(@(x) eqlzrMinimaxCost(x, w, gN, D_target0), ...
        x0, [],[],[],[],lb,ub,[],opts);
    worst = max(fval);
    if worst < bestWorst
      bestWorst = worst;
      xBest = xsol;
    end
  end

  % One more candidate start: the staged heuristic's own result
  [r_staged, theta_staged] = stagedStartCandidate(gdH0, D_target0, w, N, f_safe_lo, f_safe_hi, rMin, rMax);
  x0_staged = [r_staged, theta_staged, 1];
  [xsol, fval] = fminimax(@(x) eqlzrMinimaxCost(x, w, gN, D_target0), ...
      x0_staged, [],[],[],[],lb,ub,[],opts);
  worst = max(fval);
  if worst < bestWorst
    bestWorst = worst;
    xBest = xsol;
  end
  nStarts = length(r0Candidates) + 1;

  Nsec = (length(xBest)-1)/2;
  r = xBest(1:Nsec);
  theta = xBest(Nsec+1:2*Nsec);
  D_target = xBest(end)*D_target0;
  wiVec = r(:).*exp(1j*theta(:));

  eq = eqlzrDClass(wiVec, 1);

  bumpSum = zeros(size(w));
  for i = 1:Nsec
    bumpSum = bumpSum + (1-r(i)^2) ./ (1 - 2*r(i)*cos(w-theta(i)) + r(i)^2);
  end
  gdH1 = gdH0 + bumpSum;

  info.D_target = D_target;
  info.p2p_before = p2p_before;
  info.p2p_after = max(gdH1) - min(gdH1);
  info.worstResidual = bestWorst*D_target0;
  info.wallTime = toc(tStart);
  info.nStarts = nStarts;
end

function res = eqlzrMinimaxCost(x, w, gN, D0)
  N = (length(x)-1)/2;
  r = x(1:N);
  theta = x(N+1:2*N);
  D = x(end);
  bumpSum = zeros(size(w));
  for i = 1:N
    bumpSum = bumpSum + (1-r(i)^2) ./ (1 - 2*r(i)*cos(w-theta(i)) + r(i)^2);
  end
  res = abs(gN + bumpSum/D0 - D);
end

function [r, theta] = stagedStartCandidate(gdH0, D_target, w, N, f_safe_lo, f_safe_hi, rMin, rMax)
% Staged heuristic (evenly-spaced angles, 1-D shared-radius fminbnd
% search, per-angle coordinate-descent refinement), used to generate one
% additional fminimax starting point -- see examples/dsgnEqlzrD_staged.m
% for the standalone version this mirrors.
  theta = 2*pi*linspace(f_safe_lo, f_safe_hi, N);
  theta_lo = 2*pi*f_safe_lo;
  theta_hi = 2*pi*f_safe_hi;

  worstCost = @(rr) max(abs(gdH0 + bumpSumLocal(rr*ones(1,N), theta, w) - D_target));
  r_shared = fminbnd(worstCost, max(rMin, 0.01), rMax, optimset('TolX', 1e-4*(1 - rMax)/0.005));
  r = r_shared * ones(1, N);

  optsTh = optimset('TolX', 1e-5*(theta_hi - theta_lo)/(2*pi*0.05)); % band-relative
  for sweep = 1:3
    for i = 1:N
      idx = true(1, N);
      idx(i) = false;
      otherBump = bumpSumLocal(r(idx), theta(idx), w);
      residualBase = gdH0 + otherBump - D_target;
      costTheta_i = @(th) max(abs(residualBase + (1-r(i)^2)./(1 - 2*r(i)*cos(w-th) + r(i)^2)));
      theta(i) = fminbnd(costTheta_i, theta_lo, theta_hi, optsTh);
    end
  end
end

function s = bumpSumLocal(r, theta, w)
  s = zeros(size(w));
  for i = 1:length(r)
    s = s + (1-r(i)^2) ./ (1 - 2*r(i)*cos(w-theta(i)) + r(i)^2);
  end
end
