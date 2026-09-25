function [H, info] = equiGdDigitalAp_scld(p, px, ni, wp, ws, as, Ap, deltGD, useWs, maxIters)
%   [H, info] = equiGdDigitalAp_scld(p, px, ni, wp, ws, as, Ap, deltGD, useWs, maxIters)
%   designs the same equi-ripple group-delay filter as equiGdDigital_scld,
%   but with the passband edge held at wp: the loss at the wp edges equals
%   Ap. See Eqlzr_scld_results.md and ScldGD.md section 12.
%
%   equiGdDigital_scld sets the Ap edge only on its continuous prototype.
%   adaptP2 (group-delay equalization) and place_polesdLP5 (stopband zero
%   placement) then narrow the band within Ap of the peak to about 0.25-0.6
%   of wp. This wrapper runs equiGdDigital_scld on a design band widened
%   about the centre of wp by a factor k, measures the final Ap band b (the
%   half-width within Ap of the peak, relative to wp's half-width) and
%   adjusts k until b = 1:
%     - iteration 1 uses k = 1, iteration 2 uses k = 1/b;
%     - later iterations take a secant step on log(b) against log(k); the
%       step is halved (in log k) if the secant step is not usable or b
%       overshoots 1 again after an overshoot.
%   It stops when |b - 1| < AP_TOL or after maxIters (default 8) designs,
%   and returns the design with b closest to 1. The widened design band
%   must stay inside the stopband edges and clear of the loss poles; if a
%   step would violate that, k is limited to KEEP_OUT of the allowed range.
%
%   Meeting Ap at wp needs enough transition band: with ws only 2x wp at
%   orders 7-11 the stopband collapses to 4-12 dB. ws of 4-6x wp works.
%
%   The k -> b map is not smooth: adaptP2_scld/place_polesdLP5 occasionally
%   converge to a numerically broken design at some k (group-delay p2p in
%   the hundreds of percent) sitting right next to well-behaved designs at
%   nearby k. b alone does not flag this -- a broken design can have b very
%   close to 1. So the final choice, and the secant slope used to pick the
%   next k, both ignore designs whose gdP2pPct exceeds SANE_GD_MULT times
%   the k=1 baseline's gdP2pPct (floored at SANE_GD_FLOOR%); if a step lands
%   on such a design, the next k backs off halfway (in log k) toward the
%   last sane k instead of extrapolating from the bad point. See
%   Eqlzr_scld_results.md ("5_0_0 and 5_10_0").
%
%   info has fields k (the final design-band factor), apBand (b), edgeLoss
%   (dB at the wp edges), gdP2pPct (group-delay p2p over wp, % of mean),
%   stopLoss (minimum stopband loss relative to the passband peak, dB),
%   iters, sane (true if the returned design passed the gdP2pPct check),
%   and history (one row per design: k, b, edgeLoss, gdP2pPct, stopLoss).
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

  if nargin < 10 || isempty(maxIters)
    maxIters = 8;
  end
  AP_TOL = 0.005;
  KEEP_OUT = 0.95;
  SANE_GD_MULT = 5;
  SANE_GD_FLOOR = 10;

  fc = mean(wp);
  hw = diff(wp)/2;
  ws1 = max(ws(ws < wp(1)));
  ws2 = min(ws(ws > wp(2)));
  % largest allowed widening: the design band must stay inside the
  % stopband edges and clear of every loss pole
  room = min([fc - ws1, ws2 - fc, abs([p(:); px(:)] - fc).']);
  kMax = KEEP_OUT*room/hw;

  history = zeros(0, 5);
  sane = false(0, 1);
  designs = {};
  logkSane = [];
  logbSane = [];
  k = 1;
  overshot = false;
  gd0 = [];
  for it = 1:maxIters
    wpk = fc + [-1 1]*hw*k;
    [~, Hk] = evalc('equiGdDigital_scld(p, px, ni, wpk, ws, as, Ap, deltGD, useWs)');
    Hk.k = Hk.k/abs(freqresp(Hk, 2*pi*fc));
    r = measureAp(Hk, wp, ws1, ws2, Ap);
    history(end+1, :) = [k, r.apBand, r.edgeLoss, r.gdP2pPct, r.stopLoss]; %#ok<AGROW>
    designs{end+1} = Hk; %#ok<AGROW>
    if it == 1
      gd0 = r.gdP2pPct;
    end
    saneThresh = max(SANE_GD_FLOOR, SANE_GD_MULT*gd0);
    isSane = isfinite(r.gdP2pPct) && r.gdP2pPct <= saneThresh;
    sane(end+1, 1) = isSane; %#ok<AGROW>
    if isSane && abs(r.apBand - 1) < AP_TOL
      break
    end
    if isSane
      logkSane(end+1) = log(k); %#ok<AGROW>
      logbSane(end+1) = log(r.apBand); %#ok<AGROW>
      if numel(logkSane) == 1
        logkNew = logkSane(end) - logbSane(end);
      else
        slope = (logbSane(end) - logbSane(end-1))/(logkSane(end) - logkSane(end-1));
        if isfinite(slope) && slope > 0.1
          logkNew = logkSane(end) - logbSane(end)/slope;
        else
          logkNew = logkSane(end) - logbSane(end);
        end
        crossed = sign(logbSane(end)) ~= sign(logbSane(end-1));
        if crossed && overshot
          logkNew = logkSane(end) + 0.5*(logkNew - logkSane(end));
        end
        overshot = overshot || crossed;
      end
    else
      % this k produced a numerically broken design (large gdP2pPct) even
      % though b can look close to 1 -- don't trust it for the secant
      % slope; back off halfway (in log k) toward the last sane k instead
      logkNew = 0.5*(log(k) + logkSane(end));
    end
    k = min(exp(logkNew), kMax);
  end
  saneHist = history(sane, :);
  if isempty(saneHist)
    [~, best] = min(abs(history(:, 2) - 1));
    info.sane = false;
  else
    [~, bestSane] = min(abs(saneHist(:, 2) - 1));
    saneIdx = find(sane);
    best = saneIdx(bestSane);
    info.sane = true;
  end
  H = designs{best};
  info.k = history(best, 1);
  info.apBand = history(best, 2);
  info.edgeLoss = history(best, 3);
  info.gdP2pPct = history(best, 4);
  info.stopLoss = history(best, 5);
  info.iters = size(history, 1);
  info.history = history;
end

function r = measureAp(H, wp, ws1, ws2, Ap)
  toDb = 20/log(10);
  f = linspace(wp(1), wp(2), 4001);
  [lg, ~, gd] = AnlzDH(H, 2*pi*f);
  fw = linspace(wp(1) - diff(wp), wp(2) + diff(wp), 12001);
  lw = toDb*(AnlzDH(H, 2*pi*fw) - max(lg));
  inAp = fw(lw >= -Ap);
  r.apBand = max(abs(inAp - mean(wp)))/(diff(wp)/2);
  r.edgeLoss = -toDb*(min(lg([1 end])) - max(lg));
  r.gdP2pPct = 100*(max(gd) - min(gd))/mean(gd);
  fs = [linspace(-0.5, ws1, 4000) linspace(ws2, 0.5, 4000)];
  r.stopLoss = -toDb*max(AnlzDH(H, 2*pi*fs) - max(lg));
end
