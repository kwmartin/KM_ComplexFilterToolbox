function [clusterTheta, info] = eqlzrD_peakNewtonStep(H, clusterTheta, clusterR, clusterCount, anchor, f_peak_guess, stepSize)
%   [clusterTheta, info] = eqlzrD_peakNewtonStep(H, clusterTheta,
%   clusterR, clusterCount, anchor, f_peak_guess, stepSize) performs ONE
%   Newton iteration adjusting the free interior cluster angles
%   (clusterTheta) to drive the two tracked peaks' gain-weighted
%   deviations from a fixed anchor toward equality. clusterR is held
%   fixed throughout (only frequencies move, per this session's
%   exploration: r stays fixed, only pole FREQUENCIES are adjusted).
%
%   clusterTheta, clusterR, clusterCount: row vectors, one entry per free
%   interior cluster (theta in radians; r in (0,1); count = number of
%   identical stacked first-order stages at that theta/r -- a "cascade of
%   first-order stages" sharing one angle, matching this session's manual
%   exploration). All entries are free/adjustable; there is no separate
%   "fixed edge cluster" concept here -- edge peaks are never given their
%   own pole (moving a pole onto a peak can only increase it, never
%   decrease it, per this session's finding) and are tracked purely as
%   analysis points, not design variables.
%
%   f_peak_guess: [f_left f_right], the two edge peaks' approximate
%   current frequencies (cycles) to search near -- pass the previous
%   iteration's refined locations (or the unequalized filter's own peak
%   locations for the very first call) so the same two peaks are tracked
%   iteration to iteration, rather than rediscovering an unconstrained
%   peak set each time (the earlier all-peaks objective's failure mode).
%
%   stepSize (default 0.5): damping factor on the Newton step (a plain
%   full Newton step can overshoot badly far from the solution; per this
%   session's "slowly adjust" instruction, this defaults to a damped
%   half-step rather than a full one).
%
%   Method per call:
%     1. Step A -- refine peak locations: on a coarse local grid around
%        each f_peak_guess entry, call AnlzDH on the CURRENT equalized
%        system to get dTdW/d2TdW, bracket the dTdW sign change (+ to -,
%        a group-delay local max), then take one Newton step
%        f_peak <- f_peak - dTdW(f_peak)/d2TdW(f_peak).
%     2. Step B -- Newton/least-squares update on cluster angles: with
%        the refined peak frequencies and values, compute the
%        gain-weighted deviations w_j = |gd(f_peak_j)-anchor|*gain(f_peak_j)
%        for j=1,2, and the closed-form Jacobian
%          d(gd(w))/d(theta_i) = count_i * 2*r_i*(1-r_i^2)*sin(w-theta_i)
%                                 / (1-2*r_i*cos(w-theta_i)+r_i^2)^2
%        (exact, from the Poisson-kernel formula -- only cluster i's own
%        bump depends on theta_i, so no need for numerical AnlzDH
%        differentiation here). Solve, via pseudoinverse (there are
%        generally more free clusters than the 2 peaks being equalized,
%        an underdetermined system), for the cluster-angle step that
%        drives both w_j toward their mean, then apply stepSize*step.
%
%   info is a struct with fields: f_peaks (refined, 2-elem), gd_peaks,
%   gainAtPeaks, weightedDev (w_j before the step), spreadBefore,
%   spreadAfter (estimated, linearized), J (the Jacobian used), dtheta
%   (the raw, undamped Newton step).
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

  if nargin < 7 || isempty(stepSize)
    stepSize = 0.5;
  end

  wiVec = repelem(clusterR, clusterCount) .* exp(1j*repelem(clusterTheta, clusterCount));
  eq = eqlzrDClass(wiVec(:), 1);
  Heq = eq.applyTo(H);

  % Step A: refine each peak location via a coarse local grid + one
  % Newton step on dTdW/d2TdW.
  f_peaks = zeros(1,2);
  for k = 1:2
    fc = f_peak_guess(k);
    fLocal = linspace(fc - 0.01, fc + 0.01, 41);
    [~, ~, ~, ~, dTdWLocal] = AnlzDH(Heq, 2*pi*fLocal(:));
    signChange = find(dTdWLocal(1:end-1) > 0 & dTdWLocal(2:end) <= 0, 1);
    if isempty(signChange)
      [~, iMax] = max(AnlzDH_gd_only(Heq, 2*pi*fLocal(:)));
      fBracket = fLocal(iMax);
    else
      fBracket = fLocal(signChange);
    end
    [~, ~, ~, ~, dTdW_b, ~, d2TdW_b] = AnlzDH(Heq, 2*pi*fBracket);
    f_peaks(k) = fBracket - dTdW_b/d2TdW_b/(2*pi); % Newton step (dTdW is d/dw, w=2*pi*f)
  end

  [~, ~, gd_peaks] = AnlzDH(Heq, 2*pi*f_peaks(:));
  gainAtPeaks = abs(freqresp(H, 2*pi*f_peaks(:)));
  gainAtPeaks = gainAtPeaks(:).';
  gd_peaks = gd_peaks(:).';

  dev = gd_peaks - anchor;
  weightedDev = abs(dev) .* gainAtPeaks;

  % Step B: closed-form Jacobian d(w_j)/d(theta_i), Newton/least-squares update
  nClusters = length(clusterTheta);
  J = zeros(2, nClusters);
  for j = 1:2
    wj = 2*pi*f_peaks(j);
    for i = 1:nClusters
      r_i = clusterR(i);
      th_i = clusterTheta(i);
      dgd_dtheta = clusterCount(i) * 2*r_i*(1-r_i^2)*sin(wj-th_i) / (1 - 2*r_i*cos(wj-th_i) + r_i^2)^2;
      J(j,i) = sign(dev(j)) * gainAtPeaks(j) * dgd_dtheta;
    end
  end

  target = mean(weightedDev) - weightedDev; % desired change in each w_j
  dtheta = (pinv(J) * target(:)).';
  clusterTheta = clusterTheta + stepSize*dtheta;

  info.f_peaks = f_peaks;
  info.gd_peaks = gd_peaks;
  info.gainAtPeaks = gainAtPeaks;
  info.weightedDev = weightedDev;
  info.spreadBefore = max(weightedDev) - min(weightedDev);
  predictedWeightedDev = weightedDev(:) + stepSize*(J*dtheta.');
  info.spreadAfter = max(predictedWeightedDev) - min(predictedWeightedDev);
  info.J = J;
  info.dtheta = dtheta;
end

function gd = AnlzDH_gd_only(H, w)
  [~, ~, gd] = AnlzDH(H, w);
end
