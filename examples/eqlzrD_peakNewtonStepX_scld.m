function [clusterWp, clusterSigma, info] = eqlzrD_peakNewtonStepX_scld(H, clusterWp, clusterSigma, clusterCount, anchor, wp, stepSize, nGridPts, freeSigma)
%   [_scld copy of eqlzrD_peakNewtonStep.m - the same Newton step, with each
%   cluster parametrized in the band-centred transformed variable of z2xc
%   instead of by (theta, r). See ScldGD.md section 9.]
%
%   With w0 = pi*(wp(1) + wp(2)), t = tan(pi*(wp(2) - wp(1))/2) and
%   W = tan((w - w0)/2)/t (the passband maps to W in [-1 1]), cluster i is
%   clusterCount(i) stacked all-pass stages with x-domain pole
%   -clusterSigma(i) + j*clusterWp(i), i.e. z-domain pole
%   exp(j*w0)*(1 + t*x)/(1 - t*x). Its z-domain group delay is
%       gd(w) = count * J(W) * 2*sigma/(sigma^2 + (W - Wp)^2),
%       J = (1 + t^2 W^2)/(2t)
%   so the Jacobian columns are
%       d gd/d Wp    = count * J * 4*sigma*(W - Wp)/(sigma^2 + (W - Wp)^2)^2
%       d gd/d sigma = count * J * 2*((W - Wp)^2 - sigma^2)/(sigma^2 + (W - Wp)^2)^2
%   Every term is of order 1 in band units however narrow the band is, and
%   nothing subtracts nearly equal numbers. The original's (theta, r)
%   Jacobian uses D = 1 - 2r cos(w - theta) + r^2, which subtracts numbers
%   near 1 to get about (1-r)^2 and loses precision as r -> 1.
%
%   The original clamps r to the absolute range [0.3, 0.995], which stops
%   poles getting close enough to the unit circle for narrow bands. Here
%   sigma is clamped to [SIGMA_MIN, SIGMA_MAX] in band units: the same
%   [0.995, 0.3] radius limits converted to sigma = (1 - r)/((1 + r)*tRef)
%   at the reference 0.05-cycle band of dsgnEqlzrD_peakNewton_manual, so
%   at that width the two clamps coincide.
%
%   Extremum detection (findAllExtrema/refineExtremum, on a grid spanning
%   wp +- 10% with nGridPts points) is unchanged: that grid already scales
%   with the band, and AnlzDH's per-root terms exp(jw) - p lose only about
%   eps/(1 - |p|) of relative precision.
%
%   Inputs and outputs follow eqlzrD_peakNewtonStep with clusterTheta ->
%   clusterWp, clusterR -> clusterSigma and freeR -> freeSigma.
%   info.dtheta and info.dr hold the raw steps on Wp and sigma, and
%   info.rClamped is true if any sigma was clamped.
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
  if nargin < 9 || isempty(freeSigma)
    freeSigma = false;
  end
  BW_REF = 0.05;
  tRef = tan(pi*BW_REF/2);
  SIGMA_MIN = (1 - 0.995)/((1 + 0.995)*tRef); % r = 0.995 at the reference band
  SIGMA_MAX = (1 - 0.3)/((1 + 0.3)*tRef);     % r = 0.3 at the reference band

  w0 = pi*(wp(1) + wp(2));
  t = tan(pi*(wp(2) - wp(1))/2);

  bw = wp(2) - wp(1);
  fScan = linspace(wp(1) - 0.10*bw, wp(2) + 0.10*bw, nGridPts).';

  xVec = -repelem(clusterSigma, clusterCount) + 1j*repelem(clusterWp, clusterCount);
  wiVec = exp(1j*w0)*(1 + t*xVec)./(1 - t*xVec);
  eq = eqlzrDClass(wiVec(:), 1);
  Heq = eq.applyTo(H);

  [f_guess, isMax, fBrackets] = findAllExtrema(Heq, fScan);
  K = length(f_guess);

  if K == 0
    error('eqlzrD_peakNewtonStepX_scld:noExtrema', ...
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

  % Step B: closed-form Jacobian in x (see header), Newton/least-squares
  % update.
  nClusters = length(clusterWp);
  if freeSigma
    nParams = 2*nClusters;
  else
    nParams = nClusters;
  end
  J = zeros(K, nParams);
  for k = 1:K
    Wk = tan((2*pi*f_peaks(k) - w0)/2)/t;
    Jk = (1 + t^2*Wk^2)/(2*t);
    for i = 1:nClusters
      sg = clusterSigma(i);
      dW = Wk - clusterWp(i);
      Q = sg^2 + dW^2;
      dgd_dWp = clusterCount(i) * Jk * 4*sg*dW / Q^2;
      J(k,i) = sign(dev(k)) * gainAtPeaks(k) * dgd_dWp;
      if freeSigma
        dgd_dsg = clusterCount(i) * Jk * 2*(dW^2 - sg^2) / Q^2;
        J(k,nClusters+i) = sign(dev(k)) * gainAtPeaks(k) * dgd_dsg;
      end
    end
  end

  target = mean(weightedDev) - weightedDev; % desired change in each w_k
  dparam = (pinv(J) * target).';
  dtheta = dparam(1:nClusters);
  clusterWp = clusterWp + stepSize*dtheta;

  rClamped = false;
  if freeSigma
    dr = dparam(nClusters+1:end);
    clusterSigma = clusterSigma + stepSize*dr;
    tooLow = clusterSigma < SIGMA_MIN;
    tooHigh = clusterSigma > SIGMA_MAX;
    if any(tooLow) || any(tooHigh)
      rClamped = true;
      clusterSigma(tooLow) = SIGMA_MIN;
      clusterSigma(tooHigh) = SIGMA_MAX;
      warning('eqlzrD_peakNewtonStepX_scld:sigmaClamped', ...
          'clusterSigma clamped to [%.3g, %.3g] for %d cluster(s).', ...
          SIGMA_MIN, SIGMA_MAX, sum(tooLow)+sum(tooHigh));
    end
  else
    dr = zeros(1, nClusters);
  end

  info.f_peaks = f_peaks.';
  info.gd_peaks = gd_peaks.';
  info.isMax = isMax.';
  info.gainAtPeaks = gainAtPeaks.';
  info.weightedDev = weightedDev.';
  info.spreadBefore = max(weightedDev) - min(weightedDev);
  predictedWeightedDev = weightedDev + stepSize*(J*dparam.');
  info.spreadAfter = max(predictedWeightedDev) - min(predictedWeightedDev);
  info.J = J;
  info.dtheta = dtheta;
  info.dr = dr;
  info.rClamped = rClamped;
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
