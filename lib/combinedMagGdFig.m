function [rm, r] = combinedMagGdFig(Hmag, Hgd, wp, ws, Ap, names, file)
%   [rm, r] = combinedMagGdFig(Hmag, Hgd, wp, ws, Ap, names, file) makes
%   one combined paper figure: magnitude (left, via plotMgTwo) and group
%   delay (right, via plotGdTwo -- one curve, or two overlaid and
%   colour-coded when Hgd is a 2-element cell) side by side, each panel
%   about a third of a column wide. See ReductionPlan.md's "Figure
%   strategy for Section VI".
%
%   Hmag   a single zpk. Magnitude is unaffected by the all-pass
%          equalizer, so there is never a before/after pair to show for
%          it -- pass whichever of the before/after filters is convenient
%          (they give identical magnitude).
%   Hgd    a zpk, or a 2-element cell {Hbefore, Hafter} to overlay both
%          on the same axes, colour-coded: solid blue for the first curve,
%          solid red for the second, in both the zoom and full-band views.
%   wp, ws, Ap   as in plotMgTwo/plotGdTwo.
%   names  unused for now (no legend is drawn -- it tended to obscure the
%          curves at this panel size; color alone tells the two curves
%          apart). Kept as an argument in case a legend is wanted again.
%   file   passed to savePaperFig (no extension).
%
%   rm, r  the plotMgTwo/plotGdTwo return structs (r.p2pPct(k) is the k-th
%          curve's group-delay peak-to-peak, in % of its mean).
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

  fig = figure('Position', [800 100 900 460]);
  posL = [0.14 0.22 0.25 0.60];
  posR = [0.65 0.22 0.25 0.60];
  [~, ~, rm] = plotMgTwo(Hmag, wp, ws, struct('Ap', Ap, 'markEdges', false, ...
      'newFig', false, 'fig', fig, 'pos', posL, 'linkTag', 'mgLink'));
  if ~iscell(Hgd), Hgd = {Hgd}; end
  gdOpts = struct('markEdges', false, 'newFig', false, 'fig', fig, ...
      'pos', posR, 'linkTag', 'gdLink', 'legend', false);
  if numel(Hgd) > 1
    % solid blue for the first curve, solid red for the second, in both
    % views -- no legend (it tended to obscure the curves); the caption
    % text says which curve is before/after
    gdOpts.zoomColor = {'b', 'r'};
    gdOpts.fullColor = {'b', 'r'};
    gdOpts.lineStyle = {'-', '-'};
  end
  [~, ~, r] = plotGdTwo(Hgd, wp, ws, gdOpts);
  % a narrow passband makes MATLAB auto-scale the bottom (zoom) x-tick
  % labels with a "x10^-3"-style exponent, which overlaps the axis label
  % at this small panel size. Turning the exponent off alone just leaves
  % one tick (the ruler's auto tick count drops once labels are longer
  % without it); fix both the count and the format explicitly.
  ax = findall(fig, 'Type', 'axes');
  for a = ax(:).'
    if max(abs(a.XLim)) < 0.02
      ticks = linspace(a.XLim(1), a.XLim(2), 3);
      a.XAxis.Exponent = 0;
      set(a, 'XTick', ticks, ...
          'XTickLabel', arrayfun(@(v) sprintf('%.4f', v), ticks, 'UniformOutput', false));
    end
  end
  savePaperFig(fig, file, 3.5, 2.3, 7, false);
end
