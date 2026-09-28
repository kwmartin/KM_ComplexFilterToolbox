function [rm, r] = combinedMagGdFig(Hmag, Hgd, wp, ws, Ap, names, file, beforeStyle)
%   [rm, r] = combinedMagGdFig(Hmag, Hgd, wp, ws, Ap, names, file, beforeStyle)
%   makes one combined paper figure: magnitude (left, via plotMgTwo) and
%   group delay (right, via plotGdTwo -- one curve, or two filters x two
%   views (zoom, full) = four overlaid and colour/style-coded curves when
%   Hgd is a 2-element cell) side by side, each panel about a third of a
%   column wide. See ReductionPlan.md's "Figure strategy for Section VI".
%
%   Hmag   a single zpk. Magnitude is unaffected by the all-pass
%          equalizer, so there is never a before/after pair to show for
%          it -- pass whichever of the before/after filters is convenient
%          (they give identical magnitude).
%   Hgd    a zpk, or a 2-element cell {Hbefore, Hafter} to overlay both on
%          the same axes, each in both its zoom and full-band views: four
%          curves total, no two the same colour. "After" is solid,
%          heavier -- more emphatic, the figure's main point -- blue in
%          the passband zoom, red in the full band. "Before" is thin --
%          visually secondary throughout -- light green in the passband
%          zoom (beforeStyle.zoomColor), grey in the full band
%          (beforeStyle.color). Zoom is blue/green, full is red/grey;
%          before/after is thin/heavy -- colour and weight together, not
%          shape/x-extent, now tell all four apart. The "before" traces are
%          re-stacked on TOP of the "after" traces (uistack, below), so the
%          pre-equalization peaks are not hidden where the flat "after"
%          trace crosses the bathtub.
%   wp, ws, Ap   as in plotMgTwo/plotGdTwo.
%   names  unused for now (no legend is drawn -- it tended to obscure the
%          curves at this panel size; color alone tells the two curves
%          apart). Kept as an argument in case a legend is wanted again.
%   file   passed to savePaperFig (no extension).
%   beforeStyle   struct overriding the "before" curves' .color (full-band
%          colour, default grey), .zoomColor (passband colour, default
%          light green), .lineStyle, .lineWidth (default: thin solid,
%          width 0.75, so neither competes with the "after" curves). Every
%          combined figure with a before/after pair uses this same default
%          unless a caller overrides it -- don't override it per-caller
%          just to get the standard look; that's how Fig 2 and Fig 3
%          drifted apart the first time.
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

  if nargin < 8 || isempty(beforeStyle), beforeStyle = struct(); end
  beforeStyle = setOpt(beforeStyle, 'color', [0.5 0.5 0.5]);
  beforeStyle = setOpt(beforeStyle, 'zoomColor', [0.56 0.83 0.56]);
  beforeStyle = setOpt(beforeStyle, 'lineStyle', '-');
  beforeStyle = setOpt(beforeStyle, 'lineWidth', 0.75);

  widthIn = 3.5;   % must match the savePaperFig call below
  fig = figure('Position', [800 100 900 460]);
  posL = [0.14 0.22 0.25 0.60];
  posR = [0.65 0.22 0.25 0.60];
  [~, ~, rm] = plotMgTwo(Hmag, wp, ws, struct('Ap', Ap, 'markEdges', false, ...
      'newFig', false, 'fig', fig, 'pos', posL, 'linkTag', 'mgLink'));
  if ~iscell(Hgd), Hgd = {Hgd}; end
  gdOpts = struct('markEdges', false, 'newFig', false, 'fig', fig, ...
      'pos', posR, 'linkTag', 'gdLink', 'legend', false);
  if numel(Hgd) > 1
    % four traces on screen, four colours: passband zoom is blue (after)
    % / light green (before), full band is red (after) / grey (before) --
    % matching the zoom axis's own blue and the full axis's own red (see
    % .zoomAxisColor/.fullAxisColor below). The "after" pair stays solid
    % and heavier -- more emphatic, the figure's main point; "before" stays
    % thin -- visually secondary throughout. No legend (it tended to
    % obscure the curves); the caption text says which is which.
    gdOpts.zoomColor = {beforeStyle.zoomColor, 'b'};
    gdOpts.fullColor = {beforeStyle.color, 'r'};
    gdOpts.lineStyle = {beforeStyle.lineStyle, '-'};
    gdOpts.lineWidth = {beforeStyle.lineWidth, 1.5};
  end
  [ax1, ax2, r] = plotGdTwo(Hgd, wp, ws, gdOpts);
  if numel(Hgd) > 1
    % re-stack: the "after" curves were plotted last (plotTwo draws columns
    % in order), which buries the "before" curves wherever the flat "after"
    % trace crosses the bathtub. Put "before" on top so its peak values
    % stay visible in both views.
    for a = ax1(:).'
      above = findall(a, 'Type', 'line', 'Color', beforeStyle.zoomColor);
      if ~isempty(above), uistack(above, 'top'); end
    end
    for a = ax2(:).'
      above = findall(a, 'Type', 'line', 'Color', beforeStyle.color);
      if ~isempty(above), uistack(above, 'top'); end
    end
  end
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
  savePaperFig(fig, file, widthIn, 2.3, 7, false);
end

function s = setOpt(s, name, val)
  if ~isfield(s, name) || isempty(s.(name))
    s.(name) = val;
  end
end
