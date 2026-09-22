function [clusterTheta, info] = eqlzrD_peakNewtonStep(H, clusterTheta, clusterR, clusterCount, anchor, wp, stepSize, nGridPts)
%   [clusterTheta, info] = eqlzrD_peakNewtonStep(H, clusterTheta,
%   clusterR, clusterCount, anchor, wp, stepSize, nGridPts) performs ONE
%   Newton iteration adjusting the free interior cluster angles
%   (clusterTheta) to drive ALL of the CURRENT equalized group delay's
%   local extrema (maxima and minima, gain-weighted, re-detected fresh
%   from scratch every call) toward an equal deviation from a fixed
%   anchor. clusterR is held fixed throughout (only frequencies move,
%   per this session's exploration: r stays fixed).
%
%   THIS REPLACES an earlier version of this file that hardcoded exactly
%   two tracked peaks (the filter's own original two edge peaks), passed
%   in as a fixed f_peak_guess and refined iteration to iteration. That
%   was wrong: once the free clusters reshape the interior of the curve,
%   new local extrema appear that the 2-peak version never saw, so it
%   could report a perfectly "converged" (near-zero spread) result while
%   several other, much larger, completely untracked ripples sat right
%   next to the two it was watching -- confirmed empirically (10 steps
%   from the 3-cluster r=0.925 starting point grew 5 maxima + 4 minima,
%   values 208-240 samples, while that version's tracked pair sat at
%   118.5/118.5 and reported spread=0.003). This version re-detects the
%   full extremum set every call instead of tracking a fixed list, the
%   same way a Remez-exchange algorithm re-derives its extremal set each
%   pass rather than trusting the previous iteration's set to still be
%   complete.
%
%   This re-detection is safe against the EARLIER (different) bug this
%   session hit -- an unanchored peak-equi-ripple objective that let the
%   optimizer invent brand-new peaks and match them to each other's
%   floating mean, satisfying the letter of the objective while making
%   the real worst-case delay far worse. The anchor here is fixed
%   (computed once, outside this function, from the UNEQUALIZED filter's
%   own peaks -- never recomputed from the evolving curve), so growing
%   the tracked extremum set only ever adds more constraints against a
%   fixed external target; there is no self-referential target left to
%   game by rearranging which points get tracked.
%
%   Extremum detection (this version): a first attempt used islocalmax/
%   islocalmin with a MinProminence threshold, which needs a hand-tuned
%   threshold (too low picks up grid noise, too high misses real ripple).
%   This version instead scans d2TdW (the second derivative of group
%   delay w.r.t. w, from AnlzDH) on a uniform grid of nGridPts points
%   (default 500) across the passband wp expanded by 10% on each side,
%   and finds its zero crossings -- the group delay curve's INFLECTION
%   points. Between two consecutive inflection points, d2TdW keeps one
%   sign, so dTdW (the first derivative) is monotonic there and crosses
%   zero AT MOST ONCE -- i.e. each such bracket contains at most one
%   genuine local extremum of the group delay, found (if present) by a
%   dTdW sign check at the bracket's own endpoints. The two boundary
%   segments (grid start to the first inflection point, and the last
%   inflection point to grid end) are checked the same way, which is what
%   catches the two original edge peaks even though the grid margin
%   means they are not exactly at the scanned window's own edges. This
%   needs no tunable prominence threshold at all.
%
%   clusterTheta, clusterR, clusterCount: row vectors, one entry per free
%   interior cluster (theta in radians; r in (0,1); count = number of
%   identical stacked first-order stages at that theta/r).
%
%   anchor: the fixed flat-delay target (a scalar), established once
%   outside this function from the unequalized filter's own peaks and
%   never recomputed here.
%
%   wp: [wp1 wp2], the nominal passband (cycles, Fs=1) -- the scan grid
%   is wp expanded by 10% on each side, matching estAllPassOrder.m's own
%   default margin convention.
%
%   stepSize (default 0.5): damping factor on the Newton step.
%
%   nGridPts (default 2000, raised from an original 500 -- see below):
%   number of points in the uniform scan grid used to find d2TdW's zero
%   crossings. Independent of, and deliberately not reusing,
%   estAllPassOrder.m's own grid (which serves a different purpose and
%   clamps to [1000,10000]) so this function's grid size is exactly
%   what's requested here.
%
%   d2TdW is median-filtered (medfilt1, window 5, 'truncate' padding)
%   before the zero-crossing scan, to suppress spurious sign changes from
%   d2TdW's own local wobble very close to a sharp (near-singular) peak --
%   'truncate' padding (not medfilt1's default 'zeropad') avoids
%   distorting the two boundary segments, which is how the outermost
%   peaks get caught. Both this and the nGridPts increase from 500 to
%   2000 were tried, per direct instruction, specifically to reduce
%   reliance on the cruder de-duplication pass below. Tested against
%   three scenarios (the original hand-tuned 3-cluster start; that same
%   configuration after 15 and 40 Newton steps; and a deliberately
%   sharper r=0.97 edge-cluster stress case) across all four combinations
%   of {500,2000} x {filtered,unfiltered}: every combination gave
%   identical results, matching ground truth (a 5000-8000 point
%   findpeaks scan) in every case, so no deleterious effect was found --
%   but also no case where either change visibly mattered on THIS
%   reference filter, since the de-duplication pass already covered the
%   spurious-adjacent-bracket failure mode this was meant to address.
%   Kept anyway as defensive robustness for filters sharper or noisier
%   than this one, where 500-point/unfiltered detection might not be
%   enough (the original discovery of both problems -- a missed shallow
%   interior extremum, and duplicate detections at a sharp peak -- came
%   from an earlier, different Newton trajectory than the ones covered
%   in this specific comparison, so absence of an effect here should not
%   be read as proof neither change ever matters).
%
%   A second, more serious bug was found and fixed while re-confirming
%   the 40-iteration run with the above changes: Step A's refinement used
%   to search a FIXED +/-0.01 cycle window around each bracket's midpoint
%   guess, rather than the bracket itself. Once real extrema sit closer
%   together than 0.01 apart (confirmed: two adjacent brackets only
%   ~0.003-0.007 apart after the equalizer reshaped the curve), that
%   fixed window reached past the intended bracket into a NEIGHBORING
%   one, and find(...,1) locked onto that neighbor's crossing instead --
%   silently "refining" to the wrong extremum's location, which then
%   collided with -- and was discarded by -- the de-duplication pass as
%   an apparent duplicate of that neighbor. This is what was actually
%   causing the "missed" second edge peak (f=0.076) in the 40-iteration
%   confirmation run, not an nGridPts/medfilt1 resolution issue. Fixed by
%   having findAllExtrema return each extremum's own bracket bounds and
%   searching only within those bounds, which is guaranteed (by
%   construction, from the d2TdW inflection-point argument above) to
%   contain at most one extremum regardless of how close neighboring
%   brackets are. Verified: the 40-iteration run now finds all 9 true
%   extrema exactly (cross-checked against an 8000-point findpeaks scan,
%   every value matching), where it previously found only 7.
%
%   Method per call:
%     1. Detect the CURRENT extremum set via the d2TdW-bracket scan
%        described above (however many extrema are found, not a fixed
%        count).
%     2. Step A -- refine each detected extremum's exact location: on a
%        local grid spanning its own bracket (not a fixed-width window --
%        see above), get dTdW/d2TdW from AnlzDH, bracket the dTdW sign
%        change appropriate to a max (+ to -) or min (- to +), then take
%        one Newton step f <- f - dTdW(f)/d2TdW(f).
%     3. Step B -- Newton/least-squares update on cluster angles: with
%        the refined extremum frequencies/values, compute the
%        gain-weighted deviations w_k = |gd(f_k)-anchor|*gain(f_k) for
%        every k, and the closed-form Jacobian
%          d(gd(w))/d(theta_i) = count_i * 2*r_i*(1-r_i^2)*sin(w-theta_i)
%                                 / (1-2*r_i*cos(w-theta_i)+r_i^2)^2
%        (exact, from the Poisson-kernel formula). Solve, via
%        pseudoinverse (the K-extrema-by-nClusters system is generally
%        neither square nor consistently over/under-determined as K
%        changes call to call; pinv handles both), for the cluster-angle
%        step that drives every w_k toward their mean, then apply
%        stepSize*step.
%
%   info is a struct with fields: f_peaks (refined, K-elem, sorted by
%   frequency), gd_peaks, isMax (logical, K-elem), gainAtPeaks,
%   weightedDev (w_k before the step), spreadBefore, spreadAfter
%   (estimated, linearized), J (the Jacobian used), dtheta (the raw,
%   undamped Newton step), nExtrema (=K).
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
  if nargin < 8 || isempty(nGridPts)
    nGridPts = 2000;
  end

  bw = wp(2) - wp(1);
  fScan = linspace(wp(1) - 0.10*bw, wp(2) + 0.10*bw, nGridPts).';

  wiVec = repelem(clusterR, clusterCount) .* exp(1j*repelem(clusterTheta, clusterCount));
  eq = eqlzrDClass(wiVec(:), 1);
  Heq = eq.applyTo(H);

  [f_guess, isMax, fBrackets] = findAllExtrema(Heq, fScan);
  K = length(f_guess);

  if K == 0
    error('eqlzrD_peakNewtonStep:noExtrema', ...
        'No local extrema found scanning wp=[%g %g] (expanded 10%% each side, %d points).', ...
        wp(1), wp(2), nGridPts);
  end

  % Step A: refine each extremum's exact location, searching WITHIN its
  % own detected bracket only (never a fixed-width window) -- see
  % findAllExtrema/refineExtremum's own comments for why a fixed window
  % is unsafe once real extrema sit closer together than that width.
  f_peaks = zeros(K,1);
  for k = 1:K
    f_peaks(k) = refineExtremum(Heq, fBrackets(k,1), fBrackets(k,2), isMax(k));
  end

  % Very sharp (near-singular) peaks can make the coarse d2TdW scan flag
  % two adjacent brackets for what is really the same extremum, which
  % then refine to nearly the same frequency. Merge same-type extrema
  % closer together than 5x the scan spacing -- anything that close is
  % the same feature, not two genuine nearby ripples.
  [f_peaks, sortIdx] = sort(f_peaks);
  isMax = isMax(sortIdx);
  scanSpacing = (fScan(end)-fScan(1)) / (length(fScan)-1);
  dupTol = 5*scanSpacing;
  keep = true(size(f_peaks));
  lastKept = 1;
  for k = 2:length(f_peaks)
    if isMax(k) == isMax(lastKept) && (f_peaks(k)-f_peaks(lastKept)) < dupTol
      keep(k) = false;
    else
      lastKept = k;
    end
  end
  f_peaks = f_peaks(keep);
  isMax = isMax(keep);
  K = length(f_peaks);

  [~, ~, gd_peaks] = AnlzDH(Heq, 2*pi*f_peaks);
  gainAtPeaks = abs(freqresp(H, 2*pi*f_peaks));
  gainAtPeaks = gainAtPeaks(:);
  gd_peaks = gd_peaks(:);

  dev = gd_peaks - anchor;
  weightedDev = abs(dev) .* gainAtPeaks;

  % Step B: closed-form Jacobian d(w_k)/d(theta_i), Newton/least-squares update.
  nClusters = length(clusterTheta);
  J = zeros(K, nClusters);
  for k = 1:K
    wk = 2*pi*f_peaks(k);
    for i = 1:nClusters
      r_i = clusterR(i);
      th_i = clusterTheta(i);
      dgd_dtheta = clusterCount(i) * 2*r_i*(1-r_i^2)*sin(wk-th_i) / (1 - 2*r_i*cos(wk-th_i) + r_i^2)^2;
      J(k,i) = sign(dev(k)) * gainAtPeaks(k) * dgd_dtheta;
    end
  end

  target = mean(weightedDev) - weightedDev; % desired change in each w_k
  dtheta = (pinv(J) * target).';
  clusterTheta = clusterTheta + stepSize*dtheta;

  info.f_peaks = f_peaks.';
  info.gd_peaks = gd_peaks.';
  info.isMax = isMax.';
  info.gainAtPeaks = gainAtPeaks.';
  info.weightedDev = weightedDev.';
  info.spreadBefore = max(weightedDev) - min(weightedDev);
  predictedWeightedDev = weightedDev + stepSize*(J*dtheta.');
  info.spreadAfter = max(predictedWeightedDev) - min(predictedWeightedDev);
  info.J = J;
  info.dtheta = dtheta;
  info.nExtrema = K;
end

function [f_ext, isMax, fBrackets] = findAllExtrema(Heq, fScan)
  w = 2*pi*fScan;
  [~, ~, ~, ~, dTdW, ~, d2TdW] = AnlzDH(Heq, w);
  d2TdW = medfilt1(d2TdW, 5, 'omitnan', 'truncate'); % suppress spurious
  % zero crossings from d2TdW's own local wobble very close to a sharp
  % (near-singular) peak, which otherwise produced two adjacent brackets
  % for what was really one extremum -- 'truncate' (not the default
  % 'zeropad') padding avoids distorting the two boundary segments, which
  % is how the outermost peaks get caught.

  infIdx = find(d2TdW(1:end-1).*d2TdW(2:end) < 0);
  boundaryIdx = [1; infIdx; length(fScan)];

  f_ext = [];
  isMax = logical([]);
  fBrackets = [];
  for s = 1:length(boundaryIdx)-1
    iLo = boundaryIdx(s);
    iHi = boundaryIdx(s+1);
    dLo = dTdW(iLo);
    dHi = dTdW(iHi);
    if dLo > 0 && dHi <= 0
      f_ext(end+1,1) = 0.5*(fScan(iLo)+fScan(iHi)); %#ok<AGROW>
      isMax(end+1,1) = true; %#ok<AGROW>
      fBrackets(end+1,:) = [fScan(iLo) fScan(iHi)]; %#ok<AGROW>
    elseif dLo < 0 && dHi >= 0
      f_ext(end+1,1) = 0.5*(fScan(iLo)+fScan(iHi)); %#ok<AGROW>
      isMax(end+1,1) = false; %#ok<AGROW>
      fBrackets(end+1,:) = [fScan(iLo) fScan(iHi)]; %#ok<AGROW>
    end
  end
end

function f_refined = refineExtremum(Heq, f_lo, f_hi, isMax)
  % Search WITHIN the exact bracket [f_lo, f_hi] found by findAllExtrema,
  % never a fixed-width window: findAllExtrema guarantees at most one
  % extremum per bracket, but adjacent brackets can be much closer
  % together than any fixed window (confirmed: a fixed +/-0.01 window
  % reached past a bracket only ~0.003 away and locked onto that
  % neighbor's crossing instead via find(...,1), which then collided
  % with -- and silently discarded, via the de-duplication pass below --
  % the genuine extremum this call was meant to refine).
  fLocal = linspace(f_lo, f_hi, 41);
  [~, ~, gdLocal, ~, dTdWLocal] = AnlzDH(Heq, 2*pi*fLocal(:));
  if isMax
    signChange = find(dTdWLocal(1:end-1) > 0 & dTdWLocal(2:end) <= 0, 1);
  else
    signChange = find(dTdWLocal(1:end-1) < 0 & dTdWLocal(2:end) >= 0, 1);
  end
  if isempty(signChange)
    if isMax
      [~, iExt] = max(gdLocal);
    else
      [~, iExt] = min(gdLocal);
    end
    fBracket = fLocal(iExt);
  else
    fBracket = fLocal(signChange);
  end
  [~, ~, ~, ~, dTdW_b, ~, d2TdW_b] = AnlzDH(Heq, 2*pi*fBracket);
  f_refined = fBracket - dTdW_b/d2TdW_b/(2*pi); % Newton step (dTdW is d/dw, w=2*pi*f)
end
