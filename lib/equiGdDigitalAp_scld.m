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
%   info has fields k (the final design-band factor), apBand (b), edgeLoss
%   (dB at the wp edges), gdP2pPct (group-delay p2p over wp, % of mean),
%   stopLoss (minimum stopband loss relative to the passband peak, dB),
%   iters, and history (one row per design: k, b, edgeLoss, gdP2pPct,
%   stopLoss).
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

  fc = mean(wp);
  hw = diff(wp)/2;
  ws1 = max(ws(ws < wp(1)));
  ws2 = min(ws(ws > wp(2)));
  % largest allowed widening: the design band must stay inside the
  % stopband edges and clear of every loss pole
  room = min([fc - ws1, ws2 - fc, abs([p(:); px(:)] - fc).']);
  kMax = KEEP_OUT*room/hw;

  history = zeros(0, 5);
  designs = {};
  logk = [];
  logb = [];
  k = 1;
  overshot = false;
  for it = 1:maxIters
    wpk = fc + [-1 1]*hw*k;
    [~, Hk] = evalc('equiGdDigital_scld(p, px, ni, wpk, ws, as, Ap, deltGD, useWs)');
    Hk.k = Hk.k/abs(freqresp(Hk, 2*pi*fc));
    r = measureAp(Hk, wp, ws1, ws2, Ap);
    history(end+1, :) = [k, r.apBand, r.edgeLoss, r.gdP2pPct, r.stopLoss]; %#ok<AGROW>
    designs{end+1} = Hk; %#ok<AGROW>
    logk(end+1) = log(k); %#ok<AGROW>
    logb(end+1) = log(r.apBand); %#ok<AGROW>
    if abs(r.apBand - 1) < AP_TOL
      break
    end
    if it == 1
      logkNew = logk(end) - logb(end);
    else
      slope = (logb(end) - logb(end-1))/(logk(end) - logk(end-1));
      if isfinite(slope) && slope > 0.1
        logkNew = logk(end) - logb(end)/slope;
      else
        logkNew = logk(end) - logb(end);
      end
      crossed = sign(logb(end)) ~= sign(logb(end-1));
      if crossed && overshot
        logkNew = logk(end) + 0.5*(logkNew - logk(end));
      end
      overshot = overshot || crossed;
    end
    k = min(exp(logkNew), kMax);
  end
  [~, best] = min(abs(history(:, 2) - 1));
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
