function [N_est, stats] = estAllPassOrder(H, wp, marginFrac, N, doPlot)
%   [N_est, stats] = estAllPassOrder(H, wp, marginFrac, N, doPlot)
%   estimates the number of first-order all-pass sections a group-delay
%   equalizer needs to flatten H's group delay across passband wp.
%
%   H is a (possibly complex) zpk system, as produced elsewhere in this
%   toolbox (e.g. cscdFltr.getSystem()). wp = [wp1 wp2] is the passband,
%   in the same normalized cyclic frequency (Fs=1, f in [-0.5,0.5]) used
%   throughout this toolbox (AnlzDH, plot_dGD).
%
%   marginFrac (default 0.10) expands the analysis band by this fraction
%   of the passband width on each side before analyzing, since the worst
%   group delay of a sharp-transition filter often peaks just outside the
%   nominal passband edge rather than strictly inside it.
%
%   N (default 5000, clamped to [1000,10000]) is the number of frequency
%   points used for the analysis grid. AnlzDH is fast (an analytic
%   pole/zero sum, no iteration), so this is generous; wall time is
%   measured and a warning is issued if it exceeds 10 seconds.
%
%   doPlot (default false) plots gdH over the expanded band together with
%   the flat target level D_target used for the estimate.
%
%   The estimate follows from the fact (derived and verified in
%   doc/AllPass_GroupDelay_Area_Identity.pdf) that a single first-order
%   all-pass section has a fixed group-delay "area" of exactly 1 sample,
%   integrated over the full band, regardless of pole location:
%     1. D_target = max(gdH) over the expanded band (an equalizer can
%        only ADD delay, never subtract, so the flat target must be at
%        least the in-band peak)
%     2. deficit(f) = D_target - gdH(f)  (>= 0 everywhere by construction)
%     3. area = trapz(f, deficit)
%     4. N_est = ceil(area / 1)
%
%   This is a first-pass estimate meant as a starting point to iterate an
%   actual equalizer design from, not an exact order.
%
%   stats is a struct with fields: f, gdH, wp_expanded, D_target, gd_min,
%   gd_mean, gd_max, deficit_area, wallTime, N.
%
%   Toolbox for the Design of Complex Filters
%   Copyright (C) 2018  Kenneth Martin
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

  if nargin < 3 || isempty(marginFrac)
    marginFrac = 0.10;
  end
  if nargin < 4 || isempty(N)
    N = 5000;
  end
  if nargin < 5 || isempty(doPlot)
    doPlot = false;
  end

  MAX_WALL_TIME = 10;
  MIN_N = 1000;
  MAX_N = 10000;
  if N < MIN_N || N > MAX_N
    warning('estAllPassOrder:clampN', ...
        'N=%d outside recommended [%d, %d]; clamping.', N, MIN_N, MAX_N);
    N = max(MIN_N, min(MAX_N, N));
  end

  bw = wp(2) - wp(1);
  margin = marginFrac * bw;
  f_lo = wp(1) - margin;
  f_hi = wp(2) + margin;

  f = linspace(f_lo, f_hi, N);
  w = 2*pi*f;

  tic;
  [~, ~, gdH] = AnlzDH(H, w(:));
  wallTime = toc;

  if wallTime > MAX_WALL_TIME
    warning('estAllPassOrder:slow', ...
        ['AnlzDH took %.2fs (> %gs budget) for N=%d points; ' ...
         'consider reducing N.'], wallTime, MAX_WALL_TIME, N);
  end

  D_target = max(gdH);
  deficit = D_target - gdH;
  area = trapz(f, deficit);
  N_est = ceil(area / 1);

  stats.f = f(:);
  stats.gdH = gdH(:);
  stats.wp_expanded = [f_lo f_hi];
  stats.D_target = D_target;
  stats.gd_min = min(gdH);
  stats.gd_mean = mean(gdH);
  stats.gd_max = D_target;
  stats.deficit_area = area;
  stats.wallTime = wallTime;
  stats.N = N;

  if doPlot
    figure;
    plot(f, gdH, 'b'); hold on;
    plot(f, D_target*ones(size(f)), 'r--');
    legend('gdH (expanded passband)', 'D_{target} (peak)');
    xlabel('f'); ylabel('group delay (samples)');
    title(sprintf('Deficit area=%.3f -> N_{est}=%d', area, N_est));
  end
end
